% toy_diag.pl
% Modulo de juguete para probar por_que_no/2 (T-32): un predicado por cada forma de diagnostico.
% Los hechos a/1 son 1 y 2; tiene/1 es cierto; hecho_d/1 es un dinamico SIN clausulas (mundo cerrado).

:- module(toy_diag, [a/1, tiene/1, hecho_d/1,
                     r_builtin/1, r_neg/1, r_dos/1, r_disy/1, r_si/1, r_sino/1, r_solo_si/1,
                     r_findall/0, r_findall_ligado/0, r_forall/0, r_corte/1, r_vacia/1, r_ok/1, r_anidada/1, r_lib/1,
                     r_doble/0, r_triple/0, r_neg_anidada/0]).

:- dynamic hecho_d/1.

a(1).
a(2).
tiene(x).

% a(X) se cumple pero X > 5 no: falla un predefinido tras un hecho.
r_builtin(X) :- a(X), X > 5.

% \+ tiene(x) falla porque tiene(x) es cierto.
r_neg(X) :- a(X), \+ tiene(x).

% Dos clausulas: la segunda llega mas lejos (cumple a(X) antes de fallar).
r_dos(X) :- hecho_d(X).
r_dos(X) :- a(X), X > 5.

% Una disyuncion sin condicion: fallan las dos ramas.
r_disy(X) :- ( a(X), X > 5 ; hecho_d(X) ).

% Un si-entonces-sino: con la condicion cierta falla la rama "entonces"...
r_si(X) :- ( a(X) -> X > 5 ; true ).

% ... y con la condicion falsa falla la rama "si no".
r_sino(X) :- ( X > 5 -> a(X) ; hecho_d(X) ).

% Un si-entonces sin sino.
r_solo_si(X) :- ( a(X) -> X > 5 ).

r_findall :- findall(X, a(X), L), length(L, 5).

% Un findall con la lista ya ligada a otra cosa: el propio findall es lo que falla.
r_findall_ligado :- findall(X, a(X), [1]).

r_forall :- forall(a(X), X > 1).

% El corte no cambia el diagnostico.
r_corte(X) :- a(X), !, X > 5.

% Un predicado sin ninguna clausula que unifique.
r_vacia(X) :- hecho_d(X).

% Un predicado que se cumple (por_que_no tiene que fallar).
r_ok(X) :- a(X).

% Fallo anidado: r_anidada falla por r_builtin.
r_anidada(X) :- tiene(x), r_builtin(X).

% Negaciones anidadas: \+ \+ Y falla porque Y no se cumple; con tres, por una negacion que si falla.
r_doble :- \+ \+ a(9).
r_triple :- \+ \+ \+ a(1).

% Una negacion cuya prueba contiene otra negacion.
r_neg_anidada :- \+ ( a(1), \+ a(9) ).

% Un predicado de libreria (no es del juego): se trata como hoja.
r_lib(X) :- atom_length(X, 99).
