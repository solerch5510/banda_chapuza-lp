% suite_falsa_simple.pl: una prueba que falla sin mas (sin assertion/1).
:- use_module(library(plunit)).
:- begin_tests(la_falsa_simple).
test(falla) :- fail.
:- end_tests(la_falsa_simple).
