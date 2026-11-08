% eventos.pl
% Eventos con opciones: el motor minimo que necesita el contrato del gato en el arbol.
%
% Un evento es una escena con opciones (el comando elegir/1). Los eventos y sus opciones son DATOS
% (opcion_evento/6); lo que se puede hacer con ellos son REGLAS puras que consultan el estado y
% devuelven efectos como datos. Nunca modifican nada: eso lo hace estado.pl.
% Estado de un evento abierto: la marca evento_abierto(E) y el contador intentos_E.
% (Los eventos aleatorios del dia llegaran, si hay tiempo, en el nivel Objetivo.)

:- module(eventos, [evento_de_contrato/3, intentos_maximos/2, opcion_evento/6,
                    evento_abierto/1, evento_pendiente/3, opciones_de/2, puede_elegir/2,
                    resolver_opcion/3, intentos_hechos/2, intentos_restantes/2, clave_intentos/2,
                    efectos_apertura/2, efectos_eleccion/3, termina_con/3]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).
:- use_module(contratos).

% ---------------------------------------------------------------------------
% Los datos (docs/04 §3.3).
% intentos_maximos(Evento, N): cuantos intentos fallidos aguanta antes de acabar mal.
% opcion_evento(Evento, Opcion, Quien, Condiciones, Efectos, Final):
%   Quien la hace (tiene que estar en pie); Condiciones: en_pie(Id), queso_min(N);
%   Efectos: marcar(F), perder_queso(N), contar(Clave, N);
%   Final: resuelve (el evento acaba y el contrato se resuelve) o intento (cuenta como intento fallido).
% ---------------------------------------------------------------------------
intentos_maximos(rescate_gato, 3).

opcion_evento(rescate_gato, trepar, tuerca,
              [en_pie(tuerca)],
              [marcar(gato_bajado_con_arte)], resuelve).
opcion_evento(rescate_gato, hechizo_de_raclette, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), marcar(gato_bajado_con_arte)], resuelve).
opcion_evento(rescate_gato, sacudir_arbol, baldomero,
              [en_pie(baldomero)],
              [marcar(gato_bajado_a_golpes)], resuelve).
opcion_evento(rescate_gato, cantar, rufino,
              [en_pie(rufino)],
              [], intento).

% evento_de_contrato(?Contrato, ?Evento, ?Zona): el evento que es el objetivo de un contrato.
evento_de_contrato(C, E, Zona) :-
    contratos:contrato(C, Zona, evento(E), _, _).

% ---------------------------------------------------------------------------
% Cuando esta abierto un evento.
% ---------------------------------------------------------------------------
% evento_abierto(?E): se abrio (marca), su contrato sigue activo y estas en su zona.
evento_abierto(E) :-
    estado:marca(evento_abierto(E)),
    evento_de_contrato(C, E, Zona),
    estado:contrato_activo(C),
    estado:en_zona(Zona).

% evento_pendiente(+Zona, ?C, ?E): contrato activo con un evento en esta zona que aun no se abrio.
evento_pendiente(Zona, C, E) :-
    evento_de_contrato(C, E, Zona),
    estado:contrato_activo(C),
    \+ estado:marca(evento_abierto(E)).

% ---------------------------------------------------------------------------
% Las opciones.
% ---------------------------------------------------------------------------
% opciones_de(+E, -Lista): opcion(N, Opcion, Quien, Disponible) en orden de definicion.
opciones_de(E, Lista) :-
    findall(Opcion-Quien, opcion_evento(E, Opcion, Quien, _, _, _), Pares),
    numerar(Pares, 1, E, Lista).

numerar([], _, _, []).
numerar([Opcion-Quien|Resto], N, E, [opcion(N, Opcion, Quien, Disponible)|Lista]) :-
    (   cumple_opcion(E, Opcion) -> Disponible = si ; Disponible = no ),
    N1 is N + 1,
    numerar(Resto, N1, E, Lista).

% cumple_opcion(+E, +Opcion): quien la hace esta vivo y se cumplen sus condiciones.
cumple_opcion(E, Opcion) :-
    opcion_evento(E, Opcion, Quien, Condiciones, _, _),
    compania:activo(Quien),
    cumple_condiciones(Condiciones).

cumple_condiciones([]).
cumple_condiciones([C|Resto]) :-
    condicion_ok(C),
    cumple_condiciones(Resto).

condicion_ok(en_pie(Id))   :- compania:en_pie(Id).
condicion_ok(queso_min(N)) :- economia:hay_queso_para(N).

% puede_elegir(?E, ?Opcion): la regla que explica `elegir`: hay un evento abierto y la opcion se puede.
puede_elegir(E, Opcion) :-
    evento_abierto(E),
    cumple_opcion(E, Opcion).

% resolver_opcion(+E, +Lo_escrito, -Opcion): un numero (la N-esima de la lista) o el nombre de la opcion.
resolver_opcion(E, Escrito, Opcion) :-
    opciones_de(E, Lista),
    (   integer(Escrito)
    ->  memberchk(opcion(Escrito, Opcion, _, _), Lista)
    ;   atom(Escrito),
        memberchk(opcion(_, Escrito, _, _), Lista),
        Opcion = Escrito
    ).

% ---------------------------------------------------------------------------
% Intentos.
% ---------------------------------------------------------------------------
clave_intentos(E, Clave) :-
    atom_concat(intentos_, E, Clave).

intentos_hechos(E, N) :-
    clave_intentos(E, Clave),
    (   estado:contador(Clave, V) -> N = V ; N = 0 ).

intentos_restantes(E, Quedan) :-
    intentos_maximos(E, Max),
    intentos_hechos(E, Hechos),
    Quedan is Max - Hechos.

% ---------------------------------------------------------------------------
% Efectos.
% ---------------------------------------------------------------------------
% efectos_apertura(+E, -Efectos): el evento se abre con los intentos a cero.
efectos_apertura(E, [borrar_contador(Clave), marcar(evento_abierto(E)), mensaje(evento_abre, [E])]) :-
    clave_intentos(E, Clave).

% efectos_eleccion(+E, +Opcion, -Efectos): lo que pasa al elegir. Si el evento acaba (la opcion lo
% resuelve o se agotan los intentos) se cierra: se quita la marca de abierto.
efectos_eleccion(E, Opcion, Efectos) :-
    opcion_evento(E, Opcion, _, _, Efectos04, Final),
    expandir_todos(Efectos04, Propios),
    efectos_final(E, Opcion, Final, DelFinal),
    append([Propios, [mensaje(evento_elige, [E, Opcion])], DelFinal], Efectos).

efectos_final(E, _, resuelve, [desmarcar(evento_abierto(E))]).
efectos_final(E, _, intento, Efectos) :-
    clave_intentos(E, Clave),
    intentos_restantes(E, Quedan0),
    Quedan is Quedan0 - 1,
    (   Quedan =< 0
    ->  Efectos = [contar(Clave, 1), mensaje(intento_fallido, [E, 0]), desmarcar(evento_abierto(E))]
    ;   Efectos = [contar(Clave, 1), mensaje(intento_fallido, [E, Quedan])]
    ).

% termina_con(+E, +Opcion, -Como): resuelve (acaba bien) o agota (se acaban los intentos); falla si sigue.
termina_con(E, Opcion, Como) :-
    opcion_evento(E, Opcion, _, _, _, Final),
    (   Final == resuelve
    ->  Como = resuelve
    ;   intentos_restantes(E, Quedan),
        Quedan =< 1,
        Como = agota
    ).

expandir_todos([], []).
expandir_todos([E|Es], Efectos) :-
    expandir(E, Efs1),
    expandir_todos(Es, Efs2),
    append(Efs1, Efs2, Efectos).

expandir(marcar(F), [marcar(F)]).
expandir(contar(K, N), [contar(K, N)]).
expandir(perder_queso(N), Efs) :-
    economia:efectos_perdida(N, Efs).
