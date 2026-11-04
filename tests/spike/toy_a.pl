% toy_a.pl
% Modulo de juguete del spike T-03: hace de "combate". Importa predicados de
% toy_b (como combate importa de estado) y define reglas con y sin corte.

:- module(toy_a, [puede_atacar/2, cortado/1, cortado2/1, accion_enemigo/2,
                  anidado/1, bucle/1, cond/2, todos_vivos/1, suma/2]).
:- use_module(toy_b).

vivo(X) :- vida(X, V), V > 0.

% Regla con negacion sobre un dinamico vacio (alterado/3).
puede_atacar(A, B) :-
    vivo(A), vivo(B),
    A \= B,
    \+ alterado(A, aturdido, _).

% Corte tras una condicion: poda member/2 de la parte previa y la clausula 2.
cortado(X) :- member(X, [1,2,3]), X > 1, !.
cortado(9).

% El corte poda member/2 de la parte previa pero NO la posterior.
cortado2(X) :- member(X, [1,2,3]), !, member(_, [a,b]), X = X.

% IA con corte, como combate:accion_enemigo/2 del canon.
accion_enemigo(E, curarse)     :- vida_baja(E), tiene(E, pocion), !.
accion_enemigo(E, atacar(O))   :- clase(E, bestia), objetivo(E, O), !.
accion_enemigo(_, defender).

vida_baja(E) :- vida(E, V), V < 5.
objetivo(_, heroe).

% Corte anidado dentro de una disyuncion: el meta-interprete no lo soporta.
anidado(X) :- ( X = 1, ! ; X = 2 ).

% Recursion infinita: debe cortarla el limite de profundidad.
bucle(X) :- bucle(X).

cond(X, Y) :- ( X > 0 -> Y = positivo ; Y = no_positivo ).

todos_vivos(L) :- forall(member(X, L), vivo(X)).

suma([], 0).
suma([X|R], S) :- suma(R, S0), S is S0 + X.
