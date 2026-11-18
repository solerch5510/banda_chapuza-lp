% agregador.pl (pruebas)
% Vigila al agregador tests/todas.pl: que una suite que pasa de "en verde" (codigo de salida 0) y que una que falla
% (con una aserto, con un fallo simple) de "FALLAN" y codigo 1, aunque SWI-Prolog 5.10.4 salga con codigo 0 tras
% un assertion/1 fallido en el hilo principal (abre el depurador y, con la entrada cerrada, termina sin error).
% Lanza el agregador como lo lanzaria el usuario, en un proceso aparte, sobre las suites de juguete de tests/spike
% (que el agregador NO descubre por si solo: solo mira tests/*.pl).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/agregador -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
:- use_module(library(plunit)).
:- use_module(library(process)).
:- use_module(library(readutil)).

% agregador(+Suites, -Codigo, -Salida): el agregador sobre esas suites, tal cual se invoca desde la linea de ordenes.
agregador(Suites, Codigo, Salida) :-
    current_prolog_flag(executable, Exe),
    format(atom(Meta), 'run_tests(~q),halt', [Suites]),
    process_create(Exe, ['-q', '-s', 'tests/todas', '-g', Meta, '-t', 'halt(1)'],
                   [stdin(null), stdout(pipe(Out)), stderr(null), process(Pid)]),
    read_stream_to_codes(Out, Cs), close(Out),
    process_wait(Pid, exit(Codigo)),
    atom_codes(Salida, Cs).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

:- begin_tests(el_agregador).

test(una_suite_que_pasa_da_en_verde_y_codigo_0) :-
    agregador(['spike/suite_buena'], Codigo, Salida),
    assertion(Codigo == 0),
    assertion(contiene(Salida, 'TODO EN VERDE')).

test(un_fallo_simple_da_codigo_1) :-
    agregador(['spike/suite_falsa_simple'], Codigo, Salida),
    assertion(Codigo == 1),
    assertion(contiene(Salida, 'FALLAN')).

test(una_aserto_fallida_da_codigo_1_aunque_el_proceso_salga_con_cero) :-
    agregador(['spike/suite_falsa'], Codigo, Salida),
    assertion(Codigo == 1),
    assertion(contiene(Salida, 'FALLA  spike/suite_falsa')),
    assertion(\+ contiene(Salida, 'TODO EN VERDE')).

test(una_buena_y_una_falsa_juntas_dan_codigo_1_y_senalan_la_falsa) :-
    agregador(['spike/suite_buena', 'spike/suite_falsa'], Codigo, Salida),
    assertion(Codigo == 1),
    assertion(contiene(Salida, 'ok     spike/suite_buena')),
    assertion(contiene(Salida, 'FALLAN: [spike/suite_falsa]')).

:- end_tests(el_agregador).
