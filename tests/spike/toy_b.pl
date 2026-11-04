% toy_b.pl
% Modulo de juguete del spike T-03: hace de "estado" (predicados dinamicos).

:- module(toy_b, [vida/2, alterado/3, tiene/2, clase/2]).

:- dynamic vida/2, alterado/3, tiene/2.

vida(heroe, 30).
vida(orco, 12).
vida(goblin, 4).
vida(muerto, 0).

% alterado/3 queda sin clausulas a proposito: un dinamico definido pero vacio.

tiene(goblin, pocion).

clase(heroe, persona).
clase(orco, bestia).
clase(goblin, bestia).
