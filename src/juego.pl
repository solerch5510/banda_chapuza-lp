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
                  objetivo_de_accion/2]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).
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
comando(atacar,     1).
comando(defender,   0).
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
permitidos(exploracion, [ayuda, mirar, ir, compania, inventario, explicar, salir]).
permitidos(taberna,     [ayuda, mirar, ir, descansar, pagar, compania, inventario, explicar, salir]).
permitidos(combate,     [ayuda, mirar, atacar, defender, compania, inventario, explicar, salir]).
permitidos(fin,         [ayuda, explicar, salir]).

permitido(Fase, Nombre) :-
    permitidos(Fase, Lista),
    memberchk(Nombre, Lista).

comandos_disponibles(Fase, Lista) :- permitidos(Fase, Lista).

% objetivo_de_accion(+Accion, -Meta): la regla que se explica con explicar/por_que_no.
objetivo_de_accion(ir(Zona),  compania:puede_viajar(Zona)).
objetivo_de_accion(descansar, economia:puede_descansar).
objetivo_de_accion(pagar,     economia:puede_pagar_sueldos).
% atacar(Objetivo) y atacar(Actor, Objetivo): el Objetivo puede ser un tipo (bandido_torpe) o una
% instancia (e(bandido_torpe, 1)); el actor del primero es a quien le toca el turno.
objetivo_de_accion(atacar(Actor, Objetivo), (combate:puede_atacar(Actor, B), combate:dano(Actor, B, _))) :-
    resolver_objetivo(Objetivo, B).
objetivo_de_accion(atacar(Objetivo), Meta) :-
    actor_del_turno(Actor),
    objetivo_de_accion(atacar(Actor, Objetivo), Meta).
objetivo_de_accion(defender, combate:puede_defender(Actor)) :-
    actor_del_turno(Actor).

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
ejecutar_en_fase(mirar, _, [vista(zona, Datos)]) :-
    datos_de_zona(Datos).
ejecutar_en_fase(compania, _, [vista(compania, Filas)]) :-
    compania:informe(Filas).
ejecutar_en_fase(inventario, _, [vista(inventario, Datos)]) :-
    economia:inventario(Datos).

ejecutar_en_fase(ir(Zona), _, Items) :-
    (   compania:puede_viajar(Zona)
    ->  once(explicar:solve(compania:puede_viajar(Zona), Prueba)),
        salir_de_taberna(I0),
        etapa([guardar_prueba(ir(Zona), Prueba), viajar(Zona)], I1),
        pasar_dia(I2),
        llegada(Zona, I3),
        comprobar_fin(I4),
        append([I0, I1, I2, I3, I4], Items)
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

% explicar. : la prueba de lo ultimo que se hizo. explicar(Accion). : la de esa accion;
% si es la ultima, la guardada (el estado ya cambio); si no, se resuelve ahora, en hipotetico.
ejecutar_en_fase(explicar, _, Items) :-
    (   estado:ultima_prueba(Accion, Prueba)
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

% accion_de_turno(+Clave, +Actor, +Accion, +Meta, -Items): prueba de la Meta, efectos de la
% accion y paso de turno, todo en una etapa.
accion_de_turno(Clave, Actor, Accion, Meta, Items) :-
    once(explicar:solve(Meta, Prueba)),
    once(combate:efectos_accion(Actor, Accion, Efectos)),
    append([guardar_prueba(Clave, Prueba)|Efectos], [siguiente_turno], Todos),
    etapa(Todos, Items).

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
