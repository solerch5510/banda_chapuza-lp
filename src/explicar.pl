% explicar.pl
% Meta-interprete y modo explicar (explicar/1, por_que_no/1, arbol/1).
%
% Version del spike T-03 (docs/02-arquitectura-codigo.md, 6.4 y 6.5): solve/2,3
% construye la prueba de un objetivo y trata el corte de forma real. Las demas
% piezas (por_que_no, presentacion de pruebas) se anaden en tareas posteriores.

:- module(explicar, [solve/2, solve/3]).
:- meta_predicate solve(0, -), solve(0, -, +).

% Modulos por cuyas clausulas SI se desciende; todo lo demas es hoja.
% Es multifile para que las pruebas puedan registrar modulos de juguete.
:- multifile modulo_juego/1.
modulo_juego(estado).    modulo_juego(mundo).     modulo_juego(compania).
modulo_juego(economia).  modulo_juego(contratos). modulo_juego(combate).
modulo_juego(eventos).

solve(Meta, Prueba) :- solve(Meta, Prueba, []).

solve(Meta, Prueba, Opciones) :-
    strip_module(Meta, M, G),
    opcion(limite, Opciones, 400, Limite),
    s(G, M, Limite, Prueba).

opcion(K, Ops, Def, V) :-
    functor(T, K, 1), arg(1, T, V0),
    (   memberchk(T, Ops) -> V = V0 ; V = Def ).

% --- Profundidad de computo: dos clausulas excluyentes, sin corte ---
s(G, _, N, _) :- N =< 0, throw(limite_profundidad(G)).
s(G, M, N, P) :- N > 0, clasifica(G, T), s_(T, G, M, N, P).

clasifica(G, T) :-
    (   var(G)               -> throw(error(instantiation_error, solve/2))
    ;   G == true            -> T = verdad
    ;   G = (_, _)           -> T = conj
    ;   G = (_ ; _)          -> T = disy
    ;   G = (_ -> _)         -> T = si_solo
    ;   G = (\+ _)           -> T = neg
    ;   G == !               -> T = corte
    ;   G = findall(_,_,_)   -> T = findall
    ;   G = forall(_,_)      -> T = forall
    ;   G = (_ : _)          -> T = calificada
    ;   hoja_conocida(G)     -> T = hoja
    ;   T = pred
    ).

hoja_conocida(G) :- functor(G, N, A), hoja(N/A).
hoja(is/2).   hoja((<)/2).   hoja((>)/2).   hoja((=<)/2). hoja((>=)/2).
hoja((=:=)/2). hoja((=\=)/2). hoja((=)/2).  hoja((\=)/2). hoja((==)/2). hoja((\==)/2).
hoja(fail/0).
hoja(member/2). hoja(memberchk/2). hoja(append/3). hoja(length/2).
hoja(msort/2).  hoja(sort/2).      hoja(between/3). hoja(nth0/3). hoja(nth1/3). hoja(last/2).

s_(verdad, _, _, _, verdad).

s_(conj, (A, B), M, N, (PA, PB)) :-
    s(A, M, N, PA),
    s(B, M, N, PB).

s_(disy, (A ; B), M, N, P) :-
    (   nonvar(A), A = (C -> T)
    ->  (   s(C, M, N, PC)
        ->  s(T, M, N, PT), P = si(PC, PT)
        ;   s(B, M, N, PE), P = sino(PE)
        )
    ;   (   s(A, M, N, PA), P = izq(PA)
        ;   s(B, M, N, PB), P = der(PB)
        )
    ).

s_(si_solo, (C -> T), M, N, si(PC, PT)) :-
    (   s(C, M, N, PC) -> s(T, M, N, PT) ).

s_(neg, (\+ G), M, N, no(G)) :-
    \+ s(G, M, N, _).

s_(hoja, G, M, _, builtin(G)) :-
    call(M:G).

s_(calificada, (M2 : G), _, N, P) :-
    s(G, M2, N, P).

s_(corte, !, _, _, _) :-
    throw(corte_no_soportado).

s_(findall, findall(T, G, L), M, N, agregado(findall(T, G, L), Total, Muestra)) :-
    findall(T-P, s(G, M, N, P), Pares),
    separar_pares(Pares, L, Pruebas),
    length(Pruebas, Total),
    primeros(3, Pruebas, Muestra).

s_(forall, forall(C, A), M, N, todos(forall(C, A), Casos)) :-
    \+ ( s(C, M, N, _), \+ s(A, M, N, _) ),
    findall(PC-PA, ( s(C, M, N, PC), s(A, M, N, PA) ), Casos).

s_(pred, G, M, N, P) :-
    modulo_definicion(M, G, D),
    (   modulo_juego(D), definido(D, G)
    ->  N1 is N - 1,
        regla(D, G, N1, P)
    ;   call(M:G), P = builtin(G)
    ).

modulo_definicion(M, G, D) :-
    (   predicate_property(M:G, imported_from(D0)) -> D = D0 ; D = M ).

% En 5.10.4 predicate_property(_, defined) no devuelve exito: se usan estas dos.
definido(D, G) :- predicate_property(D:G, dynamic).
definido(D, G) :- predicate_property(D:G, number_of_clauses(_)).

% --- Resolucion de una regla y corte real ---
% En H :- Pre, !, Post el corte conserva la primera solucion de Pre, descarta
% las demas soluciones de Pre y las clausulas restantes de H, pero no poda Post.
% El ! de regla/4 queda justo despues de clause/3 (clausulas alternativas) y de
% s(Pre, ...) (soluciones alternativas de Pre): corta exactamente eso.
regla(D, G, N, Prueba) :-
    clause(D:G, Cuerpo, Ref),
    nth_clause(_, Indice, Ref),
    (   Cuerpo == true
    ->  Prueba = hecho(G)
    ;   dividir_corte(Cuerpo, Pre, Post)
    ->  s(Pre, D, N, PA),
        !,
        s(Post, D, N, PB),
        aplanar_y((PA, corte, PB), Hijos),
        Prueba = regla(G, Indice, Hijos)
    ;   s(Cuerpo, D, N, PC),
        aplanar_y(PC, Hijos),
        Prueba = regla(G, Indice, Hijos)
    ).

dividir_corte(Cuerpo, Pre, Post) :-
    conj_lista(Cuerpo, Metas),
    append(Antes, [!|Despues], Metas),
    lista_conj(Antes, Pre),
    lista_conj(Despues, Post).

conj_lista(C, L) :-
    (   C == true -> L = []
    ;   nonvar(C), C = (A, B) -> conj_lista(A, LA), conj_lista(B, LB), append(LA, LB, L)
    ;   L = [C]
    ).
lista_conj([], true).
lista_conj([X], X).
lista_conj([X, Y|R], (X, C)) :- lista_conj([Y|R], C).

aplanar_y(P, L) :-
    (   nonvar(P), P = (A, B) -> aplanar_y(A, LA), aplanar_y(B, LB), append(LA, LB, L)
    ;   P == verdad           -> L = []
    ;   L = [P]
    ).

separar_pares([], [], []).
separar_pares([T-P|R], [T|Ts], [P|Ps]) :- separar_pares(R, Ts, Ps).
primeros(K, L, P) :-
    (   K > 0, L = [X|R] -> K1 is K - 1, P = [X|P1], primeros(K1, R, P1)
    ;   P = []
    ).
