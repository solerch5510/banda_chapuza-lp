% generar.pl
% Regenera las salidas guardadas de examples/ a partir de los guiones de comandos:
%
%   swipl -q -s examples/generar -g generar -t halt
%
% (con "C:\Program Files\pl\bin\swipl.exe" en Windows). Es determinista: la partida arranca siempre con la misma
% semilla y no hay azar en el juego, asi que volver a generar da byte a byte los mismos archivos. Los archivos se
% escriben en UTF-8 y con fin de linea LF; tests/demo.pl comprueba que lo guardado coincide con lo que se genera.
%
% Salidas:
%   demo-salida.txt         la demostracion de la exposicion (guion: demo-comandos.txt)
%   campana-salida.txt      la partida de respaldo, campana entera (guion: campana-comandos.txt)
%   explicaciones/*.txt     las pantallas clave de explicar / por_que_no, una por archivo (ver explicaciones/1)

:- module(generar, [generar/0, generado/2]).
:- encoding(utf8).
:- use_module('../src/main').

:- dynamic carpeta_ejemplos/1.
:- prolog_load_context(directory, Dir), assertz(carpeta_ejemplos(Dir)).

% guion(+Archivo): sesion completa de un guion guardado, con la salida en el archivo gemelo.
salida_de_guion(Guion, Salida) :-
    atom_concat(Base, '-comandos.txt', Guion),
    atom_concat(Base, '-salida.txt', Salida).

guiones([ 'demo-comandos.txt', 'campana-comandos.txt' ]).

% explicacion(+Archivo, +Comandos): una sesion corta que acaba en una de las pantallas clave.
explicacion('explicaciones/01-explicar-un-ataque.txt',
            [demo(combate), explicar(atacar(baldomero, bandido_torpe)), salir]).
explicacion('explicaciones/02-por-que-no-el-montado-resumido.txt',
            [demo(combate), por_que_no(atacar(baldomero, bandido_montado)), salir]).
explicacion('explicaciones/03-por-que-no-el-montado-detallado.txt',
            [demo(combate), nivel(detallado), por_que_no(atacar(baldomero, bandido_montado)), salir]).
explicacion('explicaciones/04-turno-enemigo-resumido.txt',
            [demo(ia), defender, defender, defender, explicar, salir]).
explicacion('explicaciones/05-turno-enemigo-detallado.txt',
            [demo(ia), nivel(detallado), defender, defender, defender, explicar, salir]).
explicacion('explicaciones/06-gallina-resumido.txt',
            [demo(gallina), por_que_no(aceptar(gallina_noble)), salir]).
explicacion('explicaciones/07-gallina-detallado.txt',
            [demo(gallina), nivel(detallado), por_que_no(aceptar(gallina_noble)), salir]).
explicacion('explicaciones/08-gallina-con-la-venda.txt',
            [demo(gallina), demo(venda), por_que_no(aceptar(gallina_noble)), salir]).

% generado(?Archivo, -Texto): cada archivo guardado con el texto que le corresponde.
generado(Salida, Texto) :-
    guiones(Gs),
    member(Guion, Gs),
    salida_de_guion(Guion, Salida),
    ruta(Guion, Ruta),
    main:leer_guion(Ruta, Terminos),
    main:transcribir(Terminos, Texto).
generado(Archivo, Texto) :-
    explicacion(Archivo, Comandos),
    main:transcribir(Comandos, Texto).

ruta(Relativa, Ruta) :-
    carpeta_ejemplos(Dir),
    atomic_list_concat([Dir, '/', Relativa], Ruta).

generar :-
    forall(generado(Archivo, Texto),
           (   ruta(Archivo, Ruta),
               escribir(Ruta, Texto),
               format("  ~w~n", [Archivo])
           )).

% UTF-8 y LF, igual en Windows que en cualquier otro sitio.
escribir(Ruta, Texto) :-
    setup_call_cleanup(open(Ruta, write, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), write(S, Texto) ),
                       close(S)).
