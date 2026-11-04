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

:- module(juego, [ejecutar/2, validar_comando/2, comandos_disponibles/2, permitido/2,
                  objetivo_de_accion/2]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

% ---------------------------------------------------------------------------
% Parser v1: valida un termino ya leido. comando(Nombre, Aridad) es la tabla.
% ---------------------------------------------------------------------------
comando(ayuda,     0).
comando(mirar,     0).
comando(ir,        1).
comando(descansar, 0).
comando(salir,     0).

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
permitidos(exploracion, [ayuda, mirar, ir, salir]).
permitidos(taberna,     [ayuda, mirar, ir, descansar, salir]).
permitidos(combate,     [ayuda, mirar, salir]).
permitidos(fin,         [ayuda, salir]).

permitido(Fase, Nombre) :-
    permitidos(Fase, Lista),
    memberchk(Nombre, Lista).

comandos_disponibles(Fase, Lista) :- permitidos(Fase, Lista).

% objetivo_de_accion(+Accion, -Meta): la regla que se explicara con por_que_no/explicar.
objetivo_de_accion(ir(Zona),  compania:puede_viajar(Zona)).
objetivo_de_accion(descansar, economia:puede_descansar).

% ---------------------------------------------------------------------------
% ejecutar(+Comando, -Resultado): NUNCA falla ni lanza una excepcion.
% Resultado = resultado(Items); Items puede tener msg(Clave, Args, Uso),
% vista(Tipo, Datos), error(Motivo) y salir.
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
ejecutar_en_fase(ir(Zona), _, Items) :-
    (   compania:puede_viajar(Zona)
    ->  etapa([viajar(Zona)], I1),
        pasar_dia(I2),
        llegada(Zona, I3),
        comprobar_fin(I4),
        append([I1, I2, I3, I4], Items)
    ;   Items = [error(no_puede_viajar(Zona))]
    ).
ejecutar_en_fase(descansar, _, Items) :-
    (   economia:puede_descansar
    ->  economia:efectos_descanso(Efectos),
        etapa(Efectos, I1),
        pasar_dia(I2),
        comprobar_fin(I3),
        append([I1, I2, I3], Items)
    ;   Items = [error(no_puede_descansar)]
    ).

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
% El paso de un dia, en etapas: cada etapa calcula con el estado que dejo la anterior
% y aplica sus efectos (si se calcularan todos a la vez, no verian los cambios previos).
% ---------------------------------------------------------------------------
pasar_dia(Items) :-
    etapa([envejecer_quesos], I1),
    economia:efectos_racion(Efectos),
    etapa(Efectos, I2),
    etapa([avanzar_dia], I3),
    append([I1, I2, I3], Items).

llegada(Zona, Items) :-
    etapa([mensaje(llegada, [Zona])], Items).

% Fin por hambre: sin queso y sin nada por cobrar no se puede alimentar a nadie manana.
comprobar_fin(Items) :-
    (   economia:queso_total(0),
        \+ estado:contrato_por_cobrar(_, _)
    ->  etapa([fin(derrota(derrota_hambre)), mensaje(fin_hambre, [])], Items)
    ;   Items = []
    ).

% etapa(+Efectos, -Mensajes): recoge los mensajes con su contador de uso (antes de
% incrementarlo) y aplica TODO en una transaccion. ui no escribe nada en el estado.
etapa(Efectos, Mensajes) :-
    findall(msg(Clave, Args, Uso),
            ( member(mensaje(Clave, Args), Efectos), uso_de(Clave, Uso) ),
            Mensajes),
    findall(uso_frase(Clave), member(mensaje(Clave, _), Efectos), Usos),
    append(Efectos, Usos, Todos),
    con_transaccion(estado:aplicar_efectos(Todos)).

uso_de(Clave, Uso) :-
    (   estado:usos_frase(Clave, U0) -> Uso = U0 ; Uso = 0 ).
