% suite_buena.pl: una suite que pasa, para vigilar al agregador (tests/aggregador.pl).
:- use_module(library(plunit)).
:- begin_tests(la_buena).
test(pasa) :- assertion(1 == 1).
:- end_tests(la_buena).
