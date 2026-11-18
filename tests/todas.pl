% todas.pl
% El agregador de pruebas: UNA orden que corre todas las suites y dice si el proyecto esta sano.
%
%   swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl
%
% (con el ejecutable de SWI-Prolog 5.10.4, que no esta en el PATH: "C:\Program Files\pl\bin\swipl.exe").
% Codigo de salida 0 si TODAS las suites pasan y 1 si alguna falla. Tambien vale:
%   run_tests(Nombres).   solo esas suites, p. ej. run_tests([combate, ia]).
%
% Por que un proceso por suite: cada archivo de pruebas define sus propios ayudantes (ordena/2,
% contiene/2, pantalla/2...) y varios usan estado global del juego; cargados juntos se pisarian. En
% procesos separados cada suite parte de cero y un fallo de una no puede contagiar a otra.
% Este archivo no carga plunit: la run_tests/0 de aqui es la suya.

:- use_module(library(process)).
:- use_module(library(readutil)).

:- dynamic raiz_de_pruebas/1.

% La carpeta donde esta este archivo (tests/), sea cual sea el directorio desde el que se lance.
:- prolog_load_context(directory, Dir), assertz(raiz_de_pruebas(Dir)).

% suites(-Nombres): los *.pl de tests/ salvo este agregador, por orden alfabetico.
suites(Nombres) :-
    raiz_de_pruebas(Dir),
    atom_concat(Dir, '/*.pl', Patron),
    expand_file_name(Patron, Archivos),
    findall(N,
            (   member(A, Archivos),
                file_base_name(A, Base),
                file_name_extension(N, pl, Base),
                N \== todas
            ),
            Ns),
    msort(Ns, Nombres).

% pruebas_de(+Nombre, -N): cuantas pruebas declara el archivo (lineas que empiezan por "test(").
pruebas_de(Nombre, N) :-
    raiz_de_pruebas(Dir),
    atomic_list_concat([Dir, '/', Nombre, '.pl'], Archivo),
    read_file_to_codes(Archivo, Codigos, []),
    atom_codes(Texto, Codigos),
    atomic_list_concat(Lineas, '\n', Texto),
    findall(x, ( member(L, Lineas), sub_atom(L, 0, 5, _, 'test(') ), Xs),
    length(Xs, N).

% ejecutar_suite(+Nombre, -Estado, -Salida): corre una suite en un proceso aparte.
% Estado = ok | fallo(Codigo); Salida = lo que escribio (plunit escribe en la salida de errores).
ejecutar_suite(Nombre, Estado, Salida) :-
    raiz_de_pruebas(Dir),
    current_prolog_flag(executable, Exe),
    atomic_list_concat([Dir, '/', Nombre], Ruta),
    file_directory_name(Dir, Raiz),
    process_create(Exe,
                   ['-q', '-s', Ruta, '-g', 'run_tests,halt', '-t', 'halt(1)'],
                   [stdin(null), stdout(null), stderr(pipe(Err)), cwd(Raiz), process(Pid)]),
    read_stream_to_codes(Err, Codigos),
    close(Err),
    process_wait(Pid, Salida0),
    atom_codes(Salida, Codigos),
    (   Salida0 \= exit(0)
    ->  Estado = fallo(Salida0)
    ;   aserto_fallido(Salida)
    ->  Estado = fallo(aserto_fallido)
    ;   Estado = ok
    ).

% Un assertion/1 que falla en el hilo principal NO tumba el proceso: SWI-Prolog 5.10.4 abre el depurador, y con
% la entrada cerrada sale con codigo 0. Por eso no basta el codigo de salida: se mira tambien el mensaje.
aserto_fallido(Salida) :-
    sub_atom(Salida, _, _, _, 'Assertion failed'), !.
aserto_fallido(Salida) :-
    sub_atom(Salida, _, _, _, 'assumption_failed'), !.

run_tests :-
    suites(Nombres),
    run_tests(Nombres).

run_tests(Nombres) :-
    length(Nombres, Total),
    format("Banda Chapuza: ~w suites de pruebas~n", [Total]),
    get_time(T0),
    resultados(Nombres, Resultados),
    get_time(T1),
    Segundos is T1 - T0,
    findall(N, member(res(N, ok, _), Resultados), Bien),
    findall(N, ( member(res(N, E, _), Resultados), E \== ok ), Mal),
    findall(P, member(res(_, _, P), Resultados), Ps),
    sumlist(Ps, Pruebas),
    length(Bien, NB), length(Mal, NM),
    format("~n~w suites en verde, ~w con fallos; ~w pruebas declaradas; ~1f s~n", [NB, NM, Pruebas, Segundos]),
    (   Mal == []
    ->  format("TODO EN VERDE~n", [])
    ;   format("FALLAN: ~w~n", [Mal]),
        fail
    ).

resultados([], []).
resultados([N|Ns], [res(N, Estado, Pruebas)|Rs]) :-
    pruebas_de(N, Pruebas),
    ejecutar_suite(N, Estado, Salida),
    (   Estado == ok
    ->  format("  ok     ~w (~w pruebas)~n", [N, Pruebas])
    ;   format("  FALLA  ~w~n", [N]),
        ultimas_lineas(Salida, 25)
    ),
    resultados(Ns, Rs).

% Si una suite falla, se ensena el final de lo que dijo (los errores de plunit estan al final).
ultimas_lineas(Texto, N) :-
    atomic_list_concat(Ls0, '\n', Texto),
    exclude(vacia, Ls0, Ls),
    length(Ls, L),
    (   L > N -> Saltar is L - N, length(Prefijo, Saltar), append(Prefijo, Finales, Ls) ; Finales = Ls ),
    forall(member(Linea, Finales), format("         ~w~n", [Linea])).

vacia(Linea) :- atom_codes(Linea, Cs), \+ ( member(C, Cs), \+ code_type(C, space), C \== 0'. ).
