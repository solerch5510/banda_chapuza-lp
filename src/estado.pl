% estado.pl
% Estado dinamico del juego: unico modulo que escribe en la base de datos (assert/retract) y aplica efectos.
%
% Las reglas del juego NO modifican el estado: devuelven efectos (terminos como
% ganar_queso(cheddar, 0, 3)) y aqui aplicar_efecto/1 los ejecuta. Asi los cambios
% pasan todos por un unico sitio y las reglas siguen siendo explicables.
% Los demas modulos pueden LEER los hechos dinamicos exportados, nunca escribirlos.

:- module(estado, [
        % hechos dinamicos (solo lectura desde fuera)
        en_zona/1, dia/1, en_compania/1, vida/2, moral/2, queso/3, lleva/3, equipado/2,
        marca/1, contador/2, visitada/1, consejo_dado/1,
        contrato_activo/1, contrato_por_cobrar/2, contrato_cerrado/2,
        evento_visto/2, semilla/1, usos_frase/2, ajuste/2, fin_partida/1,
        en_combate/1, combatiente/2, instancia/2, fila/2, cola_turnos/1,
        alterado/3, zona_previa/1, ultima_prueba/2,
        % operaciones
        nueva_partida/0, reiniciar_estado/0,
        aplicar_efectos/1, aplicar_efecto/1, con_transaccion/1,
        siguiente_semilla/2, tirada/4, fase/1,
        persistente/1, transitorio/1
    ]).
:- use_module(mundo).

% ---------------------------------------------------------------------------
% Hechos dinamicos
% ---------------------------------------------------------------------------
% PERSISTENTES (duran toda la partida)
:- dynamic en_zona/1.             % en_zona(Zona)
:- dynamic dia/1.                 % dia(N), N entero >= 1
:- dynamic en_compania/1.         % en_compania(Id); el orden de insercion es el orden de pago
:- dynamic vida/2.                % vida(Id, V), 0 =< V =< vida maxima
:- dynamic moral/2.               % moral(Id, M), 0 =< M =< 10
:- dynamic queso/3.               % queso(Tipo, Edad, Cantidad), Cantidad > 0, (Tipo, Edad) unico
:- dynamic lleva/3.               % lleva(Id, Objeto, Cantidad); Id = compania para el inventario comun
:- dynamic equipado/2.            % equipado(Id, Objeto)
:- dynamic marca/1.               % marca(Bandera): sueldos_pagados, ...
:- dynamic contador/2.            % contador(Clave, N)
:- dynamic visitada/1.            % visitada(Zona)
:- dynamic consejo_dado/1.        % consejo_dado(Id)
:- dynamic contrato_activo/1.     % contrato_activo(ContratoId)
:- dynamic contrato_por_cobrar/2. % contrato_por_cobrar(ContratoId, Resultado)
:- dynamic contrato_cerrado/2.    % contrato_cerrado(ContratoId, Resultado)
:- dynamic evento_visto/2.        % evento_visto(EventoId, Dia)
:- dynamic semilla/1.             % semilla(S), 0 =< S < 65536
:- dynamic usos_frase/2.          % usos_frase(Grupo, N): rotacion de variantes del narrador
:- dynamic ajuste/2.              % ajuste(Clave, Valor): opciones de sesion
:- dynamic fin_partida/1.         % fin_partida(victoria | derrota(Motivo))

% TRANSITORIOS (solo durante un combate)
:- dynamic en_combate/1.          % en_combate(Ronda)
:- dynamic combatiente/2.         % combatiente(Id, jugador | enemigo)
:- dynamic instancia/2.           % instancia(e(Tipo, N), Tipo)
:- dynamic fila/2.                % fila(Id, frente | retaguardia)
:- dynamic cola_turnos/1.         % cola_turnos([Id, ...]): los que faltan por actuar en la ronda
:- dynamic alterado/3.            % alterado(Id, Estado, TurnosRestantes)
:- dynamic zona_previa/1.         % zona_previa(Zona)
:- dynamic ultima_prueba/2.       % ultima_prueba(Accion, Prueba)

% ---------------------------------------------------------------------------
% Inicializacion y reinicio
% persistente/1 y transitorio/1 son la unica fuente de verdad: reiniciar_estado/0
% borra todo lo que figura aqui, y una prueba comprueba que ningun hecho dinamico
% se haya quedado sin registrar.
% ---------------------------------------------------------------------------
persistente(en_zona/1).      persistente(dia/1).               persistente(en_compania/1).
persistente(vida/2).         persistente(moral/2).             persistente(queso/3).
persistente(lleva/3).        persistente(equipado/2).          persistente(marca/1).
persistente(contador/2).     persistente(visitada/1).          persistente(consejo_dado/1).
persistente(contrato_activo/1). persistente(contrato_por_cobrar/2). persistente(contrato_cerrado/2).
persistente(evento_visto/2). persistente(semilla/1).           persistente(usos_frase/2).
persistente(ajuste/2).       persistente(fin_partida/1).

transitorio(en_combate/1).   transitorio(combatiente/2).       transitorio(instancia/2).
transitorio(fila/2).         transitorio(cola_turnos/1).       transitorio(alterado/3).
transitorio(zona_previa/1).  transitorio(ultima_prueba/2).

todo(N/A) :- persistente(N/A).
todo(N/A) :- transitorio(N/A).

reiniciar_estado :-
    forall(todo(N/A), ( functor(C, N, A), retractall(C) )).

nueva_partida :-
    reiniciar_estado,
    forall(mundo:inicio(D), cargar_inicio(D)),
    assertz(marca(sueldos_pagados)).      % al empezar no se debe nada

cargar_inicio(zona(Z))        :- assertz(en_zona(Z)).
cargar_inicio(dia(N))         :- assertz(dia(N)).
cargar_inicio(semilla(S))     :- assertz(semilla(S)).
cargar_inicio(queso(T, E, C)) :- assertz(queso(T, E, C)).
cargar_inicio(miembro(Id))    :-
    mundo:personaje(Id, _, _, vida(V), _, _, _),
    mundo:parametro(moral_inicial, M),
    mundo:fila_preferida(Id, F),
    assertz(en_compania(Id)),
    assertz(vida(Id, V)),
    assertz(moral(Id, M)),
    assertz(fila(Id, F)).

% ---------------------------------------------------------------------------
% Fase del juego: NO se guarda, se deriva de los hechos. Cuatro clausulas
% excluyentes (sin corte), asi la fase nunca puede contradecir al estado.
% ---------------------------------------------------------------------------
fase(fin)         :- fin_partida(_).
fase(combate)     :- \+ fin_partida(_), en_combate(_).
fase(taberna)     :- \+ fin_partida(_), \+ en_combate(_), en_zona(taberna).
fase(exploracion) :- \+ fin_partida(_), \+ en_combate(_), \+ en_zona(taberna).

% ---------------------------------------------------------------------------
% Generador pseudoaleatorio determinista (no se usa random/1: asi una partida es
% reproducible y las pruebas son exactas). x' = (75*x + 74) mod 65537.
% ---------------------------------------------------------------------------
siguiente_semilla(S0, S1) :- S1 is (S0 * 75 + 74) mod 65537.

% tirada(+N, +S0, -R, -S1): R en 0..N-1
tirada(N, S0, R, S1) :-
    siguiente_semilla(S0, S1),
    R is S1 mod N.

% ---------------------------------------------------------------------------
% Efectos: la unica forma de modificar el estado. Una clausula por efecto.
% ---------------------------------------------------------------------------
aplicar_efectos([]).
aplicar_efectos([E|Es]) :- aplicar_efecto(E), aplicar_efectos(Es).

% Un efecto desconocido es un error de programacion: se avisa en vez de fallar en silencio.
% (Despachar asi, y no con una clausula comodin al final, deja aplicar_efecto/1 determinista.)
aplicar_efecto(E) :-
    (   efecto_conocido(E)
    ->  aplicar_conocido(E)
    ;   throw(efecto_invalido(E))
    ).

aplicar_conocido(mensaje(_, _)).            % no toca el estado: lo recoge la interfaz
aplicar_conocido(dano(Id, N)) :-
    N >= 0, vida(Id, V0),
    V1 is max(0, V0 - N),
    set_vida(Id, V1).
aplicar_conocido(curar(Id, N)) :-
    N >= 0, vida(Id, V0), tope_vida(Id, Max),
    V1 is min(Max, V0 + N),
    set_vida(Id, V1).
aplicar_conocido(mod_moral(Id, D)) :-
    moral(Id, M0), mundo:parametro(moral_max, Max),
    M1 is max(0, min(Max, M0 + D)),
    retractall(moral(Id, _)),
    assertz(moral(Id, M1)).
aplicar_conocido(ganar_queso(T, E, N)) :-
    N > 0,
    (   retract(queso(T, E, C0)) -> C1 is C0 + N ; C1 = N ),
    assertz(queso(T, E, C1)).
aplicar_conocido(gastar_queso(T, E, N)) :-
    N > 0, queso(T, E, C0), C0 >= N,
    retract(queso(T, E, C0)),
    C1 is C0 - N,
    (   C1 > 0 -> assertz(queso(T, E, C1)) ; true ).
aplicar_conocido(envejecer_quesos) :-
    findall(q(T, E, C), retract(queso(T, E, C)), L),
    forall(member(q(T, E, C), L), ( E1 is E + 1, assertz(queso(T, E1, C)) )).
aplicar_conocido(ganar_objeto(Id, Objeto, N)) :-         % Id = compania para el inventario comun
    N > 0,
    (   retract(lleva(Id, Objeto, C0)) -> C1 is C0 + N ; C1 = N ),
    assertz(lleva(Id, Objeto, C1)).
aplicar_conocido(gastar_objeto(Id, Objeto, N)) :-
    N > 0, lleva(Id, Objeto, C0), C0 >= N,
    retract(lleva(Id, Objeto, C0)),
    C1 is C0 - N,
    (   C1 > 0 -> assertz(lleva(Id, Objeto, C1)) ; true ).
aplicar_conocido(equipar(Id, Objeto)) :-                 % lo que lleva puesto (p. ej. la venda de caballos)
    retractall(equipado(Id, Objeto)),
    assertz(equipado(Id, Objeto)).
% Empieza un combate: los miembros pasan al bando jugador y cada enemigo del grupo nace como
% instancia e(Tipo, N) con su vida y su fila. Queda en la ronda 0 con la cola vacia: la ronda 1
% empieza con siguiente_ronda/1. Solo fuera de combate y con un grupo de tipos conocidos.
aplicar_conocido(iniciar_combate(Grupo)) :-
    \+ en_combate(_),
    ground(Grupo), Grupo = [_|_],
    forall(member(Tipo, Grupo), mundo:enemigo(Tipo, _, _, _)),
    mundo:numerar_grupo(Grupo, Ids),
    forall(en_compania(Id), assertz(combatiente(Id, jugador))),
    forall(member(E, Ids), nace_enemigo(E)),
    assertz(cola_turnos([])),
    assertz(en_combate(0)).
aplicar_conocido(siguiente_turno) :-           % el que estaba al frente de la cola ya ha actuado
    retract(cola_turnos([_|Resto])),
    assertz(cola_turnos(Resto)).
aplicar_conocido(siguiente_ronda(Ids)) :-      % ronda + 1 y la cola vuelve a llenarse
    en_combate(R0),
    ground(Ids), is_list(Ids),
    R is R0 + 1,
    retractall(en_combate(_)),
    retractall(cola_turnos(_)),
    assertz(en_combate(R)),
    assertz(cola_turnos(Ids)).
% Termina el combate: desaparecen los enemigos (con su vida y su fila), los bandos, la cola y los
% estados alterados; los miembros caidos se levantan con 1 de vida y conservan su fila.
aplicar_conocido(terminar_combate) :-
    en_combate(_),
    forall(instancia(E, _), ( retractall(vida(E, _)), retractall(fila(E, _)) )),
    forall(( combatiente(Id, jugador), vida(Id, 0) ), set_vida(Id, 1)),
    retractall(instancia(_, _)),
    retractall(combatiente(_, _)),
    retractall(cola_turnos(_)),
    retractall(alterado(_, _, _)),
    retractall(en_combate(_)).
% Estados alterados de un combatiente (aturdido, defendiendo...): duran N turnos o son fijos.
% Alterar de nuevo el mismo estado lo sustituye (no se acumula).
aplicar_conocido(alterar(Id, Estado, Turnos)) :-
    ground(Id), ground(Estado), atom(Estado),
    combatiente(Id, _),
    (   Turnos == fijo ; integer(Turnos), Turnos >= 1 ),
    retractall(alterado(Id, Estado, _)),
    assertz(alterado(Id, Estado, Turnos)).
aplicar_conocido(quitar_alteracion(Id, Estado)) :-
    retractall(alterado(Id, Estado, _)).
aplicar_conocido(marcar(F)) :-
    (   marca(F) -> true ; assertz(marca(F)) ).
aplicar_conocido(desmarcar(F)) :-
    retractall(marca(F)).
aplicar_conocido(avanzar_dia) :-
    retract(dia(N)),
    N1 is N + 1,
    assertz(dia(N1)).
aplicar_conocido(viajar(Z)) :-
    en_zona(A), once(mundo:adyacente(A, Z)),
    retractall(en_zona(_)),
    assertz(en_zona(Z)).
aplicar_conocido(fijar_semilla(S)) :-
    S1 is S mod 65536,
    retractall(semilla(_)),
    assertz(semilla(S1)).
aplicar_conocido(fin(Motivo)) :-         % fin(victoria) o fin(derrota(Motivo)); el primero que llega manda
    (   fin_partida(_) -> true ; assertz(fin_partida(Motivo)) ).
aplicar_conocido(guardar_prueba(Accion, Prueba)) :-   % la ultima prueba, para explicar lo que acaba de pasar
    retractall(ultima_prueba(_, _)),
    assertz(ultima_prueba(Accion, Prueba)).
aplicar_conocido(uso_frase(Grupo)) :-    % cuantas veces se ha usado un grupo de frases (rotacion del narrador)
    (   retract(usos_frase(Grupo, U0)) -> U1 is U0 + 1 ; U1 = 1 ),
    assertz(usos_frase(Grupo, U1)).

efecto_conocido(E) :- nonvar(E), functor(E, N, A), conocido(N/A).
conocido(mensaje/2).      conocido(dano/2).          conocido(curar/2).
conocido(mod_moral/2).    conocido(ganar_queso/3).   conocido(gastar_queso/3).
conocido(envejecer_quesos/0). conocido(marcar/1).    conocido(desmarcar/1).
conocido(avanzar_dia/0).  conocido(viajar/1).        conocido(fijar_semilla/1).
conocido(fin/1).          conocido(uso_frase/1).     conocido(guardar_prueba/2).
conocido(ganar_objeto/3). conocido(gastar_objeto/3). conocido(equipar/2).
conocido(iniciar_combate/1). conocido(siguiente_turno/0). conocido(siguiente_ronda/1).
conocido(alterar/3).      conocido(quitar_alteracion/2).  conocido(terminar_combate/0).

nace_enemigo(E) :-
    E = e(Tipo, _),
    mundo:enemigo(Tipo, vida(V), _, _),
    mundo:fila_preferida(Tipo, F),
    assertz(instancia(E, Tipo)),
    assertz(vida(E, V)),
    assertz(fila(E, F)),
    assertz(combatiente(E, enemigo)).

set_vida(Id, V) :-
    retractall(vida(Id, _)),
    assertz(vida(Id, V)).

% Vida maxima: la del catalogo, de la ficha del personaje o del tipo de la instancia de enemigo.
tope_vida(Id, Max) :-
    (   mundo:personaje(Id, _, _, vida(M), _, _, _)
    ->  Max = M
    ;   instancia(Id, Tipo),
        mundo:enemigo(Tipo, vida(Max), _, _)
    ).

% ---------------------------------------------------------------------------
% Transaccion: si Meta falla o lanza una excepcion, el estado vuelve a como estaba.
% ---------------------------------------------------------------------------
:- meta_predicate con_transaccion(0).
con_transaccion(Meta) :-
    foto(F),
    (   catch(Meta, E, ( restaurar_foto(F), throw(E) ))
    ->  true
    ;   restaurar_foto(F), fail
    ).

foto(Hs) :-
    findall(H, ( todo(N/A), functor(H, N, A), call(H) ), Hs).

restaurar_foto(Hs) :-
    reiniciar_estado,
    forall(member(H, Hs), assertz(H)).
