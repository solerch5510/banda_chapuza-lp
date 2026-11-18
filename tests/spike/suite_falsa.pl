% suite_falsa.pl
% Una suite que FALLA a proposito, para vigilar al agregador (tests/aggregador.pl): una prueba con una
% aserto que falla y otra que falla sin mas. No la descubre tests/todas.pl (solo mira tests/*.pl).
:- use_module(library(plunit)).
:- begin_tests(la_falsa).
test(aserto_falso) :- assertion(1 == 2).
:- end_tests(la_falsa).
