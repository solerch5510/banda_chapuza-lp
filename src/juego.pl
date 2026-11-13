% juego.pl
% Orquestacion de comandos: valida el comando (parser) y lo ejecuta con ejecutar/2.
%
% Un comando es un TERMINO (ir(aldea), mirar...), no un predicado que se llama.
% validar_comando/2 comprueba que es un comando conocido y ejecutar/2 hace siempre lo mismo:
%   1. mira si el comando esta permitido en la fase actual;
%   2. comprueba la condicion con una regla pura (compania:puede_viajar/1...);
%   3. calcula los efectos con reglas puras (economia:efectos_racion/1...);
%   4. los aplica dentro de una transaccion (estado:aplicar_efectos/1);
%   5. devuelve resultado(Items) para que ui lo muestre. Nunca escribe nada.
% Antes de aplicar los efectos de ir, descansar y pagar, guarda la PRUEBA de su regla
% (explicar:solve/2): asi `explicar.` puede decir por que se pudo aunque el estado ya cambio.

:- module(juego, [ejecutar/2, validar_comando/2, comandos_disponibles/2, permitido/2,
                  objetivo_de_accion/2, comenzar_combate/2, avanzar_combate/1]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).
:- use_module(combate).
:- use_module(contratos).
:- use_module(eventos).
:- use_module(explicar).

% ---------------------------------------------------------------------------
% Parser v1: valida un termino ya leido. comando(Nombre, Aridad) es la tabla.
% ---------------------------------------------------------------------------
comando(ayuda,      0).
comando(mirar,      0).
comando(ir,         1).
comando(descansar,  0).
comando(pagar,      0).
comando(compania,   0).
comando(inventario, 0).
comando(explicar,   0).
comando(explicar,   1).
comando(por_que_no, 1).
comando(nivel,      1).
comando(atacar,     1).
comando(defender,   0).
comando(habilidad,  0).
comando(habilidad,  1).
comando(contratos,  0).
comando(aceptar,    1).
comando(elegir,     1).
comando(salir,      0).

validar_comando(T, Res) :-
    (   var(T)                 -> Res = error(comando_vacio)
    ;   T == end_of_file       -> Res = ok(salir)
    ;   T == '$error_sintaxis' -> Res = error(sintaxis)
    ;   callable(T), functor(T, N, A), comando(N, A)
    ->  (   ground(T)
        ->  Res = ok(T)
        ;   Res = error(falta_argumento(T))      % p. ej. ir(X): hay que decir a donde
        )
    ;   Res = error(no_entiendo(T))
    ).

% ---------------------------------------------------------------------------
% Que comandos se pueden usar en cada fase (la fase se deriva en estado:fase/1).
% ---------------------------------------------------------------------------
permitidos(exploracion, [ayuda, mirar, ir, contratos, aceptar, elegir, compania, inventario, explicar, por_que_no, nivel, salir]).
permitidos(taberna,     [ayuda, mirar, ir, contratos, aceptar, elegir, descansar, pagar, compania, inventario, explicar, por_que_no, nivel, salir]).
permitidos(combate,     [ayuda, mirar, atacar, defender, habilidad, compania, inventario, explicar, por_que_no, nivel, salir]).
permitidos(fin,         [ayuda, explicar, por_que_no, nivel, salir]).

permitido(Fase, Nombre) :-
    permitidos(Fase, Lista),
    memberchk(Nombre, Lista).

comandos_disponibles(Fase, Lista) :- permitidos(Fase, Lista).

% objetivo_de_accion(+Accion, -Meta): la regla que se explica con explicar/por_que_no.
objetivo_de_accion(ir(Zona),  compania:puede_viajar(Zona)).
objetivo_de_accion(descansar, economia:puede_descansar).
objetivo_de_accion(pagar,     economia:puede_pagar_sueldos).
objetivo_de_accion(aceptar(C), contratos:puede_aceptar(C)).
% elegir(Opcion): el numero de la opcion o su nombre; el evento es el que esta abierto.
objetivo_de_accion(elegir(Escrito), eventos:puede_elegir(E, Opcion)) :-
    eventos:evento_abierto(E),
    eventos:resolver_opcion(E, Escrito, Opcion).
% atacar(Objetivo) y atacar(Actor, Objetivo): el Objetivo puede ser un tipo (bandido_torpe) o una
% instancia (e(bandido_torpe, 1)); el actor del primero es a quien le toca el turno.
objetivo_de_accion(atacar(Actor, Objetivo), (combate:puede_atacar(Actor, B), combate:dano(Actor, B, _))) :-
    resolver_objetivo(Objetivo, B).
objetivo_de_accion(atacar(Objetivo), Meta) :-
    actor_del_turno(Actor),
    objetivo_de_accion(atacar(Actor, Objetivo), Meta).
objetivo_de_accion(defender, combate:puede_defender(Actor)) :-
    actor_del_turno(Actor).
% habilidad (sin objetivo, la de Rufino) y habilidad(Objetivo): la del miembro al que le toca.
objetivo_de_accion(habilidad, combate:puede_habilidad(Actor, Habilidad, ninguno)) :-
    actor_del_turno(Actor),
    mundo:habilidad_de(Actor, Habilidad).
objetivo_de_accion(habilidad(Objetivo), combate:puede_habilidad(Actor, Habilidad, B)) :-
    actor_del_turno(Actor),
    mundo:habilidad_de(Actor, Habilidad),
    resolver_objetivo(Objetivo, B).

% actor_del_turno(-Id): el miembro al que le toca (la cabeza de la cola de turnos).
actor_del_turno(Actor) :-
    estado:cola_turnos([Actor|_]),
    estado:combatiente(Actor, jugador).

% resolver_objetivo(+Nombre, -Id): una instancia e(Tipo, N) o un miembro valen tal cual; un tipo
% (bandido_torpe) es la primera instancia viva de ese tipo. Falla si no hay a quien atacar.
resolver_objetivo(Nombre, Id) :-
    (   nonvar(Nombre), Nombre = e(_, _)
    ->  estado:instancia(Nombre, _),
        Id = Nombre
    ;   atom(Nombre), estado:combatiente(Nombre, _)
    ->  Id = Nombre
    ;   atom(Nombre),
        findall(E, ( estado:instancia(E, Nombre), compania:vivo(E) ), Vivos),
        msort(Vivos, [Id|_])
    ).

% misma_accion(+Pedida, +Guardada): explicar(atacar(bandido_torpe)) vale para la prueba guardada
% de atacar(baldomero, e(bandido_torpe, 1)), aunque el turno ya haya pasado a otro.
misma_accion(Pedida, Guardada) :-
    Pedida == Guardada.
misma_accion(atacar(Objetivo), atacar(_, B)) :-
    atomo_o_instancia(Objetivo, B).
misma_accion(atacar(Actor, Objetivo), atacar(Actor, B)) :-
    atomo_o_instancia(Objetivo, B).
misma_accion(defender, defender(_)).
misma_accion(habilidad, habilidad(_, ninguno)).
misma_accion(habilidad(Objetivo), habilidad(_, B)) :-
    atomo_o_instancia(Objetivo, B).

atomo_o_instancia(Objetivo, B) :-
    (   Objetivo == B -> true ; B = e(Objetivo, _) ).

% ---------------------------------------------------------------------------
% ejecutar(+Comando, -Resultado): NUNCA falla ni lanza una excepcion.
% Resultado = resultado(Items); Items puede tener msg(Clave, Args, Uso),
% vista(Tipo, Datos...), error(Motivo) y salir.
% ---------------------------------------------------------------------------
ejecutar(Cmd, Resultado) :-
    (   catch(ejecutar_(Cmd, R0), E, error_interno(E, R0))
    ->  Resultado = R0
    ;   Resultado = resultado([error(sin_efecto(Cmd))])
    ).

% Un error de programacion se convierte en un item de error y el juego sigue; pero la
% excepcion del limite de tiempo se deja pasar para que quien puso el limite (las pruebas)
% pueda cortar un bucle sin fin en vez de quedarse colgado.
error_interno(E, Resultado) :-
    (   E == time_limit_exceeded
    ->  throw(E)
    ;   Resultado = resultado([error(interno(E))])
    ).

ejecutar_(Cmd, resultado(Items)) :-
    (   callable(Cmd), functor(Cmd, Nombre, Aridad), comando(Nombre, Aridad)
    ->  (   ground(Cmd)
        ->  once(estado:fase(Fase)),
            (   permitido(Fase, Nombre)
            ->  % Sin "estado:" delante: con_transaccion/1 es un meta-predicado y debe
                % resolver ejecutar_en_fase/3 en ESTE modulo, no en estado.
                con_transaccion(ejecutar_en_fase(Cmd, Fase, Items))
            ;   Items = [error(fuera_de_fase(Cmd, Fase))]
            )
        ;   % ir(X) con X sin ligar no es un comando: ejecutarlo elegiria una zona cualquiera.
            Items = [error(falta_argumento(Cmd))]
        )
    ;   Items = [error(no_entiendo(Cmd))]
    ).

ejecutar_en_fase(ayuda, Fase, [vista(ayuda, Comandos)]) :-
    comandos_disponibles(Fase, Comandos).
ejecutar_en_fase(salir, _, [salir]).
ejecutar_en_fase(mirar, Fase, Items) :-
    datos_de_zona(Datos),
    (   Fase == combate
    ->  datos_de_combate(Combate),
        Items = [vista(zona, Datos), vista(combate, Combate)]
    ;   eventos:evento_abierto(E)
    ->  mostrar_evento(E, Evento),
        Items = [vista(zona, Datos)|Evento]
    ;   Items = [vista(zona, Datos)]
    ).
ejecutar_en_fase(compania, _, [vista(compania, Filas)]) :-
    compania:informe(Filas).
ejecutar_en_fase(inventario, _, [vista(inventario, Datos)]) :-
    economia:inventario(Datos).

ejecutar_en_fase(ir(Zona), _, Items) :-
    (   compania:puede_viajar(Zona)
    ->  once(explicar:solve(compania:puede_viajar(Zona), Prueba)),
        salir_de_taberna(I0),
        etapa([guardar_prueba(ir(Zona), Prueba), viajar(Zona), visitar(Zona)], I1),
        pasar_dia(I2),
        llegada(Zona, I3),
        cobrar_contratos(Zona, I3b),
        comprobar_fin(I4),
        iniciar_objetivo(Zona, I5),
        append([I0, I1, I2, I3, I3b, I4, I5], Items)
    ;   Items = [error(no_puede_viajar(Zona))]
    ).
ejecutar_en_fase(descansar, _, Items) :-
    (   economia:puede_descansar
    ->  once(explicar:solve(economia:puede_descansar, Prueba)),
        economia:efectos_descanso(Efectos),
        etapa([guardar_prueba(descansar, Prueba)|Efectos], I1),
        pasar_dia(I2),
        comprobar_fin(I3),
        append([I1, I2, I3], Items)
    ;   Items = [error(no_puede_descansar)]
    ).
ejecutar_en_fase(pagar, _, Items) :-
    (   economia:puede_pagar_sueldos
    ->  once(explicar:solve(economia:puede_pagar_sueldos, Prueba)),
        economia:efectos_sueldos(Efectos),
        etapa([guardar_prueba(pagar, Prueba)|Efectos], Items)
    ;   estado:marca(sueldos_pagados)
    ->  Items = [error(nada_que_pagar)]
    ;   Items = [error(no_puede_pagar)]
    ).

% atacar(Objetivo) y defender: la accion del miembro al que le toca el turno. Se comprueba la
% regla (puede_atacar/2, puede_defender/1), se guarda su prueba ANTES de aplicar los efectos y
% el turno pasa al siguiente. Los turnos de los enemigos los lleva el bucle de combate.
ejecutar_en_fase(atacar(Objetivo), _, Items) :-
    (   actor_del_turno(Actor)
    ->  (   resolver_objetivo(Objetivo, B)
        ->  (   combate:puede_atacar(Actor, B)
            ->  accion_de_turno(atacar(Actor, B), Actor, atacar(B),
                                (combate:puede_atacar(Actor, B), combate:dano(Actor, B, _)), Items)
            ;   Items = [error(no_puede_atacar(Actor, B))]
            )
        ;   Items = [error(objetivo_desconocido(Objetivo))]
        )
    ;   Items = [error(no_es_tu_turno)]
    ).
ejecutar_en_fase(defender, _, Items) :-
    (   actor_del_turno(Actor)
    ->  (   combate:puede_defender(Actor)
        ->  accion_de_turno(defender(Actor), Actor, defender, combate:puede_defender(Actor), Items)
        ;   Items = [error(no_puede_defender(Actor))]
        )
    ;   Items = [error(no_es_tu_turno)]
    ).

% habilidad y habilidad(Objetivo): la habilidad del miembro al que le toca el turno. Las hay con
% enemigo (carga, fondue, rebuscar) y sin el (la balada); la prueba se guarda ANTES de aplicar los efectos.
ejecutar_en_fase(habilidad, _, Items) :-
    usar_habilidad(ninguno, Items).
ejecutar_en_fase(habilidad(Objetivo), _, Items) :-
    (   actor_del_turno(Actor), mundo:habilidad_de(Actor, Habilidad),
        combate:objetivo_de_habilidad(Habilidad, ninguno)
    ->  usar_habilidad(ninguno, Items)               % la balada no necesita a quien apuntar
    ;   usar_habilidad(Objetivo, Items)
    ).

% contratos : el tablon. Cada contrato a la vista con su estado (disponible, bloqueado, lejos...).
ejecutar_en_fase(contratos, _, [vista(contratos, Fichas)]) :-
    findall(F, ( contratos:contrato(C, _, _, _, _), contratos:ficha(C, F) ), Fichas).

% aceptar(Contrato) : se acepta si la regla puede_aceptar/1 lo permite. La prueba se guarda ANTES
% de aplicar el efecto, para que explicar(aceptar(C)) pueda decir por que se pudo.
ejecutar_en_fase(aceptar(C), _, Items) :-
    (   \+ contratos:contrato(C, _, _, _, _)
    ->  Items = [error(contrato_desconocido(C))]
    ;   contratos:puede_aceptar(C)
    ->  once(explicar:solve(contratos:puede_aceptar(C), Prueba)),
        etapa([guardar_prueba(aceptar(C), Prueba), contrato_aceptar(C), mensaje(acepta, [C])], I1),
        siguiente_objetivo(I2),
        append(I1, I2, Items)
    ;   Items = [error(no_puede_aceptar(C))]
    ).

% elegir(Opcion) : una opcion del evento abierto (por su numero o su nombre). Se comprueba con la regla
% eventos:puede_elegir/2, cuya prueba se guarda ANTES de aplicar los efectos. Si la opcion acaba el
% evento, el contrato se resuelve con las marcas que dejo.
ejecutar_en_fase(elegir(Escrito), _, Items) :-
    (   \+ eventos:evento_abierto(_)
    ->  Items = [error(no_hay_evento)]
    ;   once(eventos:evento_abierto(E)),
        (   \+ eventos:resolver_opcion(E, Escrito, _)
        ->  Items = [error(opcion_desconocida(Escrito))]
        ;   eventos:resolver_opcion(E, Escrito, Opcion),
            \+ eventos:puede_elegir(E, Opcion)
        ->  Items = [error(opcion_no_disponible(Opcion))]
        ;   eventos:resolver_opcion(E, Escrito, Opcion),
            elegir_opcion(E, Opcion, Items)
        )
    ).

% explicar. : la prueba de lo ultimo que se hizo. explicar(Accion). : la de esa accion;
% si es la ultima, la guardada (el estado ya cambio); si no, se resuelve ahora, en hipotetico.
ejecutar_en_fase(explicar, _, Items) :-
    (   estado:ultima_prueba(accion_enemigo(E), Prueba)
    ->  (   estado:ultimos_descartes(E, Descartes) -> true ; Descartes = [] ),
        Items = [vista(decision, E, Prueba, Descartes)]            % el turno de un enemigo y por que no hizo otra cosa
    ;   estado:ultima_prueba(Accion, Prueba)
    ->  Items = [vista(prueba, Accion, Prueba)]
    ;   Items = [error(nada_que_explicar)]
    ).
ejecutar_en_fase(explicar(Accion), _, Items) :-
    (   estado:ultima_prueba(Ultima, Guardada), misma_accion(Accion, Ultima)
    ->  Items = [vista(prueba, Accion, Guardada)]
    ;   objetivo_de_accion(Accion, Meta)
    ->  (   once(explicar:solve(Meta, Prueba))
        ->  Items = [vista(prueba, Accion, Prueba)]
        ;   Items = [error(no_hay_prueba(Accion))]
        )
    ;   Items = [error(no_se_explica(Accion))]
    ).

% nivel(Nivel) : cuanto detalle ensenan explicar y por_que_no. Es un ajuste de sesion que ui aplica al mostrar
% (el mismo arbol sirve para los dos niveles).
ejecutar_en_fase(nivel(Nivel), _, Items) :-
    (   memberchk(Nivel, [resumido, detallado])
    ->  etapa([ajustar(nivel_explicacion, Nivel), mensaje(nivel, [Nivel])], Items)
    ;   Items = [error(nivel_desconocido(Nivel))]
    ).

% por_que_no(Accion) : por que la accion NO se puede. Es la misma regla que explica `explicar`, pero
% con el segundo meta-interprete: da el diagnostico (el primer subobjetivo que falla y, si es una
% negacion, lo que la impide). Si la accion si se puede, lo dice. No modifica el estado.
ejecutar_en_fase(por_que_no(Accion), _, Items) :-
    (   once(objetivo_de_accion(Accion, Meta))
    ->  (   once(explicar:por_que_no(Meta, Diag))
        ->  Items = [vista(diag, Accion, Diag)]
        ;   Items = [error(sin_fallo(Accion))]
        )
    ;   Items = [error(no_se_explica(Accion))]
    ).

% accion_de_turno(+Clave, +Actor, +Accion, +Meta, -Items): prueba de la Meta, efectos de la
% accion y paso de turno, todo en una etapa.
accion_de_turno(Clave, Actor, Accion, Meta, Items) :-
    once(explicar:solve(Meta, Prueba)),
    once(combate:efectos_accion(Actor, Accion, Efectos)),
    append([guardar_prueba(Clave, Prueba)|Efectos], [siguiente_turno], Todos),
    etapa(Todos, I1),
    avanzar_combate(I2),
    append(I1, I2, Items).

% usar_habilidad(+Objetivo, -Items): Objetivo es ninguno, un tipo o una instancia.
usar_habilidad(Objetivo, Items) :-
    (   actor_del_turno(Actor)
    ->  mundo:habilidad_de(Actor, Habilidad),
        (   Objetivo == ninguno
        ->  B = ninguno
        ;   resolver_objetivo(Objetivo, B)
        ->  true
        ;   B = desconocido
        ),
        (   B == desconocido
        ->  Items = [error(objetivo_desconocido(Objetivo))]
        ;   combate:puede_habilidad(Actor, Habilidad, B)
        ->  accion_de_turno(habilidad(Actor, B), Actor, habilidad(B),
                            combate:puede_habilidad(Actor, Habilidad, B), Items)
        ;   Objetivo == ninguno, \+ combate:objetivo_de_habilidad(Habilidad, ninguno)
        ->  Items = [error(habilidad_pide_objetivo(Habilidad))]
        ;   Items = [error(no_puede_habilidad(Actor, Habilidad))]
        )
    ;   Items = [error(no_es_tu_turno)]
    ).

% ---------------------------------------------------------------------------
% El combate por turnos. comenzar_combate/2 lo abre y avanzar_combate/1 lo lleva hasta que le
% toca a un miembro (se espera su comando) o hasta que termina (victoria o derrota). Cada paso
% es una etapa: calcula con el estado que dejo la anterior y lo aplica.
% ---------------------------------------------------------------------------
% comenzar_combate(+Tipos, -Items): Tipos es la lista de enemigos (p. ej. [rata_quesera, rata_quesera]).
comenzar_combate(Tipos, Items) :-
    once(combate:efectos_inicio(Tipos, Efectos)),
    sort(Tipos, Distintos),
    findall(mensaje(aparece, [Tipo]), member(Tipo, Distintos), Avisos),
    append(Efectos, Avisos, Todos),
    etapa(Todos, I1),
    avanzar_combate(I2),
    append(I1, I2, Items).

% avanzar_combate(-Items): el limite evita un bucle sin fin si algo falla en el diseno.
avanzar_combate(Items) :-
    avanzar_combate(200, Items).

avanzar_combate(Limite, Items) :-
    (   \+ estado:en_combate(_)
    ->  Items = []
    ;   Limite =< 0
    ->  Items = [error(interno(combate_sin_fin))]
    ;   combate:fin_combate(Resultado)
    ->  once(combate:efectos_fin(Resultado, Efectos)),
        etapa(Efectos, I1),
        cerrar_contrato(Resultado, I2),
        append(I1, I2, Items)
    ;   estado:cola_turnos([])
    ->  once(combate:efectos_ronda(Efectos)),         % nadie por actuar: empieza otra ronda
        etapa(Efectos, I1),
        seguir_combate(I1, Limite, Items)
    ;   estado:cola_turnos([Actor|_])
    ->  turno_de(Actor, Limite, Items)
    ).

% turno_de(+Actor, +Limite, -Items): quien ya no puede actuar pierde el turno sin ruido; un
% aturdido lo pierde con aviso; a un miembro se le espera; un enemigo actua.
turno_de(Actor, Limite, Items) :-
    (   \+ combate:puede_actuar(Actor)
    ->  etapa([siguiente_turno], I1),
        seguir_combate(I1, Limite, Items)
    ;   combate:aturdido(Actor)
    ->  once(combate:efectos_inicio_turno(Actor, Pasos)),
        append([mensaje(aturdido, [Actor])|Pasos], [siguiente_turno], Efectos),
        etapa(Efectos, I1),
        seguir_combate(I1, Limite, Items)
    ;   once(combate:efectos_inicio_turno(Actor, Pasos)),
        etapa(Pasos, I0),
        (   estado:combatiente(Actor, jugador)
        ->  Items = I0                                  % le toca al jugador
        ;   turno_enemigo(Actor, I1),
            append(I0, I1, Previos),
            seguir_combate(Previos, Limite, Items)
        )
    ).

seguir_combate(Previos, Limite, Items) :-
    Menos is Limite - 1,
    avanzar_combate(Menos, Siguientes),
    append(Previos, Siguientes, Items).

% turno_enemigo(+E, -Items): decide con combate:accion_enemigo/2, guarda la prueba de la decision
% ANTES de aplicar los efectos (asi explicar puede contar por que lo hizo) y pasa el turno.
turno_enemigo(E, Items) :-
    (   contratos:golpea_a_clotilde(E)                  % en la escolta, el primero de la ronda se ceba con Clotilde
    ->  once(explicar:solve(contratos:golpea_a_clotilde(E), Prueba)),
        once(contratos:efectos_golpe_a_clotilde(E, Efectos)),
        Descartes = []
    ;   once(explicar:solve(combate:accion_enemigo(E, Accion), Prueba)),
        (   once(combate:efectos_accion(E, Accion, Efectos0))
        ->  Efectos = Efectos0
        ;   Efectos = [mensaje(pasa, [E])]              % el comodin (defender) no siempre se puede: pasa
        ),
        descartes_de(E, Prueba, Descartes)
    ),
    append([guardar_prueba(accion_enemigo(E), Prueba), guardar_descartes(E, Descartes)|Efectos],
           [siguiente_turno], Todos),
    etapa(Todos, Items).

% descartes_de(+E, +Prueba, -Descartes): por que NO se aplico ninguna regla de mayor prioridad que la que
% decidio. Se calcula en el momento de la decision (despues la vida y la fila ya habrian cambiado) con el
% segundo meta-interprete sobre la gemela de datos regla_ia/3, cuyas condiciones son las mismas.
% Descartes = [descarte(Prioridad, NombreDeLaAccion, Diag), ...] de la mas prioritaria a la mas cercana.
descartes_de(E, Prueba, Descartes) :-
    (   prioridad_decidida(Prueba, N)
    ->  findall(descarte(J, Nombre, Diag),
                (   between(1, N, J), J < N,
                    descarte(E, J, Nombre, Diag)
                ),
                Descartes)
    ;   Descartes = []
    ).

prioridad_decidida(regla(accion_enemigo(_, _), N, _), N).
prioridad_decidida(hecho(accion_enemigo(_, _)), N) :-    % el comodin: la ultima clausula
    predicate_property(combate:accion_enemigo(_, _), number_of_clauses(N)).

descarte(E, J, Nombre, Diag) :-
    clause(combate:regla_ia(J, _, Plantilla), _),         % lo que esa prioridad habria elegido
    functor(Plantilla, Nombre, _),
    once(explicar:por_que_no(combate:regla_ia(J, E, _), Diag)).

% datos_de_combate(-Datos): lo que enseña mirar durante un combate.
datos_de_combate(combate(Ronda, Turno, Enemigos)) :-
    once(estado:en_combate(Ronda)),
    (   estado:cola_turnos([Actor|_]) -> Turno = Actor ; Turno = ninguno ),
    findall(enemigo(E, Vida, Max, Fila),
            (   estado:instancia(E, Tipo),
                estado:vida(E, Vida),
                mundo:enemigo(Tipo, vida(Max), _, _),
                estado:fila(E, Fila)
            ),
            Enemigos0),
    msort(Enemigos0, Enemigos).

% ---------------------------------------------------------------------------
% mirar: los datos de la zona donde estas.
% ---------------------------------------------------------------------------
datos_de_zona([nombre(Nombre), descripcion(Texto), salidas(Salidas), dia(Dia), queso(Queso)]) :-
    once(estado:en_zona(Zona)),
    mundo:zona(Zona, Nombre),
    mundo:descripcion_zona(Zona, Texto),
    findall(Vecina-NombreVecina,
            ( mundo:adyacente(Zona, Vecina), mundo:zona(Vecina, NombreVecina) ),
            Salidas0),
    sort(Salidas0, Salidas),
    once(estado:dia(Dia)),
    economia:queso_total(Queso).

% ---------------------------------------------------------------------------
% Salir de la taberna sin haber pagado los sueldos: cada miembro activo pierde moral.
% Solo castiga al SALIR de la taberna; la bandera sueldos_pagados dice que no se debe nada.
% ---------------------------------------------------------------------------
salir_de_taberna(Items) :-
    (   estado:en_zona(taberna), \+ estado:marca(sueldos_pagados)
    ->  mundo:parametro(moral_impago, Perdida),
        Menos is -Perdida,
        findall(mod_moral(Id, Menos), compania:activo(Id), Efectos),
        etapa([mensaje(impago, [])|Efectos], Items)
    ;   Items = []
    ).

% ---------------------------------------------------------------------------
% El paso de un dia, en etapas: cada etapa calcula con el estado que dejo la anterior
% y aplica sus efectos (si se calcularan todos a la vez, no verian los cambios previos).
% ---------------------------------------------------------------------------
pasar_dia(Items) :-
    etapa([envejecer_quesos], I1),
    economia:efectos_racion(Efectos),
    etapa(Efectos, I2),
    etapa([avanzar_dia], I3),
    append([I1, I2, I3], Items).

% Llegar a la taberna trae sueldos pendientes: se quita la bandera sueldos_pagados.
llegada(Zona, Items) :-
    (   Zona == taberna
    ->  etapa([desmarcar(sueldos_pagados), mensaje(llegada, [Zona])], Items)
    ;   etapa([mensaje(llegada, [Zona])], Items)
    ).

% Al llegar a la taberna se cobran solos los contratos resueltos (los sueldos no: eso es `pagar`).
cobrar_contratos(Zona, Items) :-
    (   Zona == taberna,
        contratos:efectos_cobro(Efectos),
        Efectos = [_|_]
    ->  etapa(Efectos, Items)
    ;   Items = []
    ).

% Al llegar a la zona de un contrato activo (o al aceptarlo estando ya en ella) empieza su objetivo:
% un combate (queda marcado como suyo) o un evento con opciones. Primero los combates, en orden de
% catalogo. Si no hay nada nuevo pero hay un evento abierto, se vuelven a enseñar sus opciones.
iniciar_objetivo(Zona, Items) :-
    (   estado:fin_partida(_)
    ->  Items = []
    ;   contratos:objetivo_pendiente(Zona, C, Grupo)
    ->  contratos:efectos_inicio_objetivo(C, Efectos),
        etapa(Efectos, I1),
        comenzar_combate(Grupo, I2),
        append(I1, I2, Items)
    ;   eventos:evento_pendiente(Zona, _, E)
    ->  eventos:efectos_apertura(E, Efectos),
        etapa(Efectos, I1),
        mostrar_evento(E, I2),
        append(I1, I2, Items)
    ;   eventos:evento_abierto(E)
    ->  mostrar_evento(E, Items)
    ;   Items = []
    ).

% siguiente_objetivo(-Items): mira si en la zona donde estas queda algun objetivo por empezar.
siguiente_objetivo(Items) :-
    (   estado:en_zona(Zona)
    ->  iniciar_objetivo(Zona, Items)
    ;   Items = []
    ).

% mostrar_evento(+E, -Items): la vista del evento con sus opciones y los intentos que quedan.
mostrar_evento(E, [vista(evento, E, Quedan, Opciones)]) :-
    eventos:intentos_restantes(E, Quedan),
    eventos:opciones_de(E, Opciones).

elegir_opcion(E, Opcion, Items) :-
    once(explicar:solve(eventos:puede_elegir(E, Opcion), Prueba)),
    once(eventos:efectos_eleccion(E, Opcion, Efectos)),
    (   eventos:termina_con(E, Opcion, _) -> Cierra = si ; Cierra = no ),
    etapa([guardar_prueba(elegir(Opcion), Prueba)|Efectos], I1),
    (   Cierra == si
    ->  once(eventos:evento_de_contrato(C, E, _)),
        resolver_contrato(C, I2)
    ;   mostrar_evento(E, I2)
    ),
    append(I1, I2, Items).

% Si el combate que acaba de ganarse era el objetivo de un contrato, se resuelve: el resultado sale
% de resultado/3 (guardamos su prueba para explicar) y se aplican sus consecuencias inmediatas.
cerrar_contrato(Resultado, Items) :-
    (   Resultado == victoria,
        estado:marca(combate_de(C))
    ->  resolver_contrato(C, Items)
    ;   Items = []
    ).

% resolver_contrato(+C, -Items): el resultado sale de resultado/3 con lo registrado durante el contrato
% (su prueba se guarda para explicar), se aplican las consecuencias inmediatas y se mira si en esta
% zona queda otro objetivo por empezar.
resolver_contrato(C, Items) :-
    contratos:contexto(Ctx),
    once(explicar:solve(contratos:resultado(C, Ctx, Res), Prueba)),
    contratos:efectos_resolucion(C, Res, Efectos),
    etapa([guardar_prueba(resultado(C), Prueba)|Efectos], I1),
    siguiente_objetivo(I2),
    append(I1, I2, Items).

% Fin por hambre: sin queso y sin nada por cobrar no se puede alimentar a nadie manana.
comprobar_fin(Items) :-
    (   economia:queso_total(0),
        \+ estado:contrato_por_cobrar(_, _)
    ->  etapa([fin(derrota(derrota_hambre)), mensaje(fin_hambre, [])], Items)
    ;   Items = []
    ).

% etapa(+Efectos, -Mensajes): recoge los mensajes con su contador de uso (antes de
% incrementarlo) y aplica TODO en una transaccion. ui no escribe nada en el estado.
% El contador es por GRUPO: el mensaje entero con sus argumentos (llegada(aldea) y
% llegada(taberna) cuentan por separado), que es lo que rota las variantes del narrador.
etapa(Efectos, Mensajes) :-
    findall(msg(Clave, Args, Uso),
            (   member(mensaje(Clave, Args), Efectos),
                grupo_de(Clave, Args, Grupo),
                uso_de(Grupo, Uso)
            ),
            Mensajes),
    findall(uso_frase(Grupo),
            (   member(mensaje(Clave, Args), Efectos),
                grupo_de(Clave, Args, Grupo)
            ),
            Usos),
    append(Efectos, Usos, Todos),
    con_transaccion(estado:aplicar_efectos(Todos)).

grupo_de(Clave, Args, Grupo) :-
    Grupo =.. [Clave|Args].

uso_de(Grupo, Uso) :-
    (   estado:usos_frase(Grupo, U0) -> Uso = U0 ; Uso = 0 ).
