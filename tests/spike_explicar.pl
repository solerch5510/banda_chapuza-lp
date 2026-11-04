% spike_explicar.pl
% Spike T-03 (decision D-06): el meta-interprete con corte real y los modulos.
% Comprueba con dos modulos de juguete (tests/spike/toy_a.pl y toy_b.pl) que
% solve/2 de src/explicar.pl:
%   - desciende por predicados importados de otro modulo y por dinamicos;
%   - trata un dinamico sin clausulas como definido (mundo cerrado);
%   - implementa el corte de verdad (misma lista de soluciones que la ejecucion directa);
%   - numera las clausulas con nth_clause/3;
%   - rechaza lo que no soporta (corte anidado, variable libre, recursion sin fin).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/spike_explicar -g "run_tests,halt" -t "halt(1)"

:- use_module(library(plunit)).
:- use_module('../src/explicar').
:- use_module('spike/toy_b').
:- use_module('spike/toy_a').

% Registra los modulos de juguete como "modulos del juego" para el meta-interprete.
:- multifile explicar:modulo_juego/1.
explicar:modulo_juego(toy_a).
explicar:modulo_juego(toy_b).

% Todas las soluciones de Plantilla con ejecucion directa y con solve/2.
directo(Plantilla, Meta, L) :- findall(Plantilla, Meta, L).
con_solve(Plantilla, Meta, L) :- findall(Plantilla, solve(Meta, _), L).

% La prueba, como atomo, contiene Texto.
contiene(Prueba, Texto) :-
    term_to_atom(Prueba, A),
    sub_atom(A, _, _, _, Texto), !.

:- begin_tests(spike_explicar).

% --- Equivalencia con la ejecucion directa (V-02) ---

test(corte_tras_condicion) :-
    directo(X, toy_a:cortado(X), D),
    con_solve(X, toy_a:cortado(X), M),
    D == [2],
    D == M.

test(corte_no_poda_la_parte_posterior) :-
    directo(X, toy_a:cortado2(X), D),
    con_solve(X, toy_a:cortado2(X), M),
    D == [1,1],
    D == M.

test(ia_con_corte_enemigo_libre) :-
    directo(E-A, toy_a:accion_enemigo(E, A), D),
    con_solve(E-A, toy_a:accion_enemigo(E, A), M),
    D == [goblin-curarse],
    D == M.

test(ia_con_corte_enemigo_ligado) :-
    forall(member(E, [heroe, orco, goblin, muerto]),
           (   directo(A, toy_a:accion_enemigo(E, A), D),
               con_solve(A, toy_a:accion_enemigo(E, A), M),
               D == M
           )).

test(if_then_else) :-
    forall(member(X, [5, -5]),
           (   directo(Y, toy_a:cond(X, Y), D),
               con_solve(Y, toy_a:cond(X, Y), M),
               D == M
           )).

test(forall_y_recursion) :-
    directo(x, toy_a:todos_vivos([heroe, orco]), D1),
    con_solve(x, toy_a:todos_vivos([heroe, orco]), M1),
    D1 == M1,
    directo(x, toy_a:todos_vivos([heroe, muerto]), D2),
    con_solve(x, toy_a:todos_vivos([heroe, muerto]), M2),
    D2 == M2,
    directo(S, toy_a:suma([1,2,3], S), D3),
    con_solve(S, toy_a:suma([1,2,3], S), M3),
    D3 == [6],
    D3 == M3.

% --- Forma de la prueba ---

test(prueba_marca_el_corte) :-
    solve(toy_a:accion_enemigo(orco, _), P),
    P = regla(accion_enemigo(orco, _), 2, Hijos),
    memberchk(corte, Hijos).

test(un_hecho_se_prueba_como_hecho) :-
    % La clausula 3 es un hecho (cuerpo true): la prueba es hecho(G), sin indice.
    solve(toy_a:accion_enemigo(muerto, A), P),
    A == defender,
    P = hecho(accion_enemigo(muerto, defender)).

test(numera_las_clausulas_con_nth_clause) :-
    % goblin: la clausula 1 (curarse) gana y el corte descarta las demas.
    solve(toy_a:accion_enemigo(goblin, A), P),
    A == curarse,
    P = regla(accion_enemigo(goblin, curarse), 1, Hijos),
    memberchk(corte, Hijos).

test(hecho_dinamico) :-
    solve(toy_b:vida(orco, V), P),
    V == 12,
    P = hecho(vida(orco, 12)).

test(dinamico_sin_clausulas_es_mundo_cerrado) :-
    solve(toy_a:puede_atacar(heroe, orco), P),
    contiene(P, 'no(alterado(heroe').

test(predicado_importado) :-
    % puede_atacar/2 llega a este modulo importado de toy_a.
    solve(puede_atacar(heroe, orco), P),
    P = regla(puede_atacar(heroe, orco), _, _).

test(las_hojas_no_se_abren, [nondet]) :-
    solve(toy_a:member(1, [1,2,3]), P),
    P == builtin(member(1, [1,2,3])).

test(falla_igual_que_la_ejecucion_directa, [fail]) :-
    solve(toy_a:puede_atacar(muerto, orco), _).

% --- Lo que el meta-interprete rechaza ---

test(corte_anidado_no_soportado, [throws(corte_no_soportado)]) :-
    solve(toy_a:anidado(_), _).

test(variable_libre_como_meta, [throws(error(instantiation_error, _))]) :-
    solve(_, _).

test(limite_de_profundidad, [throws(limite_profundidad(_))]) :-
    solve(toy_a:bucle(_), _).

:- end_tests(spike_explicar).
