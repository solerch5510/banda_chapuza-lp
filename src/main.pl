% main.pl
% Punto de entrada y bucle principal del juego.
%
% Solo lee, delega y muestra: todo lo demas lo hace juego:ejecutar/2.
% No hay :- initialization(main) aqui: cargar este archivo (por ejemplo desde las
% pruebas) no arranca el juego. Se arranca con:
%   swipl -q -s src/main -g main -t halt

:- module(main, [main/0, procesar/2, leer_guion/2, transcribir/2]).
:- use_module(ui).
:- use_module(juego).
:- use_module(estado).

main :-
    ui:iniciar,
    estado:nueva_partida,
    ui:bienvenida,
    juego:ejecutar(mirar, Resultado),
    ui:mostrar(Resultado),
    bucle.

% El bucle es recursivo por la cola: sin repeat/fail y sin acumular elecciones.
bucle :-
    ui:leer_termino(Termino, _),
    procesar(Termino, Seguir),
    (   Seguir == salir -> true ; bucle ).

% procesar(+Termino, -Seguir): un comando leido. Los meta-comandos de main (`demo`) se atienden aqui,
% antes de validar: no son comandos del juego sino ayudas para la exposicion.
procesar(Termino, Seguir) :-
    (   escena_pedida(Termino, Escena)
    ->  demo(Escena),
        Seguir = seguir
    ;   juego:validar_comando(Termino, Validacion),
        despachar(Validacion, Seguir)
    ).

% leer_guion(+Archivo, -Terminos): los comandos de un guion (un archivo con un comando por linea, cada uno
% terminado en punto; los comentarios con % se ignoran), como los leeria el bucle.
leer_guion(Archivo, Terminos) :-
    setup_call_cleanup(open(Archivo, read, Flujo, [encoding(utf8)]),
                       leer_terminos(Flujo, Terminos),
                       close(Flujo)).

leer_terminos(Flujo, Terminos) :-
    read_term(Flujo, Termino, []),
    (   Termino == end_of_file
    ->  Terminos = []
    ;   Terminos = [Termino|Resto],
        leer_terminos(Flujo, Resto)
    ).

% transcribir(+Terminos, -Texto): una sesion completa con esos comandos, como se vería en la consola pero con
% cada orden escrita tras "> " (la entrada por tuberia no se ve). Parte de una partida nueva y termina en
% `salir` o al acabar la lista. Lo usan examples/ y las pruebas: la misma sesion da siempre el mismo texto.
transcribir(Terminos, Texto) :-
    with_output_to(atom(Texto), sesion_transcrita(Terminos)).

sesion_transcrita(Terminos) :-
    estado:nueva_partida,
    ui:bienvenida,
    juego:ejecutar(mirar, Resultado),
    ui:mostrar(Resultado),
    ordenes_transcritas(Terminos).

ordenes_transcritas([]).
ordenes_transcritas([Termino|Resto]) :-
    format("~n> ~W~n", [Termino, [quoted(true), spacing(next_argument)]]),
    procesar(Termino, Seguir),
    (   Seguir == salir -> true ; ordenes_transcritas(Resto) ).

% escena_pedida(+Termino, -Escena): `demo.` lista las escenas (Escena = lista); `demo(Nombre).` prepara una.
escena_pedida(Termino, Escena) :-
    nonvar(Termino),
    (   Termino == demo -> Escena = lista
    ;   Termino = demo(E), nonvar(E), atom(E) -> Escena = E
    ).

demo(lista) :-
    juego:escenas_de_demo(Escenas),
    ui:mostrar(resultado([vista(escenas, Escenas)])).
demo(Escena) :-
    Escena \== lista,
    juego:preparar_escena(Escena, Items),
    ui:mostrar(resultado(Items)).

despachar(error(Motivo), seguir) :-
    ui:mostrar(resultado([error(Motivo)])).
despachar(ok(Comando), Seguir) :-
    juego:ejecutar(Comando, Resultado),
    ui:mostrar(Resultado),
    Resultado = resultado(Items),
    % salir (y el fin de la entrada, que valida como salir) termina SIEMPRE, aunque
    % ejecutar devolviera un error: si no, una entrada agotada repetiria el bucle sin fin.
    (   ( Comando == salir ; memberchk(salir, Items) ) -> Seguir = salir ; Seguir = seguir ).
