% explicar.pl
% Meta-interprete y modo explicar (explicar/1, por_que_no/1, arbol/1).
%
% solve/2,3 (docs/02-arquitectura-codigo.md, 6.4 y 6.5) construye la prueba de un objetivo
% y trata el corte de forma real; prueba_a_lineas/2 (6.11) la convierte en un arbol de texto
% ASCII que ui escribe. por_que_no y los niveles resumido/detallado llegan mas adelante.

:- module(explicar, [solve/2, solve/3, prueba_a_lineas/2, meta_de_prueba/2]).
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

% ===========================================================================
% Presentacion: la prueba como arbol de texto ASCII (funciones PURAS: devuelven
% una lista de atomos; quien escribe en pantalla es ui.pl). Marcas: [ok], [hecho]...
% ===========================================================================

% meta_de_prueba(+Prueba, -Meta): la meta que demuestra esa prueba.
meta_de_prueba(hecho(G), G).
meta_de_prueba(regla(G, _, _), G).
meta_de_prueba(builtin(G), G).
meta_de_prueba(no(G), (\+ G)).
meta_de_prueba(verdad, true).
meta_de_prueba(si(PC, _), G) :- meta_de_prueba(PC, G).
meta_de_prueba(izq(P), G) :- meta_de_prueba(P, G).
meta_de_prueba(der(P), G) :- meta_de_prueba(P, G).
meta_de_prueba((PA, PB), (GA, GB)) :-            % la condicion de un if-then-else puede ser una conjuncion
    meta_de_prueba(PA, GA),
    meta_de_prueba(PB, GB).

% txt(+Meta, -Atomo): una meta como texto. Las variables salen como A, B...; \+ lleva
% parentesis si niega una conjuncion; lo muy largo se recorta con puntos suspensivos.
txt(Meta, Texto) :-
    quitar_modulos(Meta, SinModulos),
    copy_term(SinModulos, Copia),
    numbervars(Copia, 0, _),
    t(Copia, Largo),
    (   atom_length(Largo, N), N > 72
    ->  sub_atom(Largo, 0, 69, _, Prefijo),
        atom_concat(Prefijo, '...', Texto)
    ;   Texto = Largo
    ).

% quitar_modulos(+Termino, -Termino2): borra los prefijos modulo:Meta en cualquier posicion
% (tambien dentro de findall/3...): el modulo no aporta nada a quien lee la explicacion.
quitar_modulos(T0, T) :-
    (   var(T0)
    ->  T = T0
    ;   T0 = (M:G), atom(M)
    ->  quitar_modulos(G, T)
    ;   compound(T0)
    ->  T0 =.. [F|Args0],
        maplist(quitar_modulos, Args0, Args),
        T =.. [F|Args]
    ;   T = T0
    ).

t(G, Texto) :-
    (   nonvar(G), G = (\+ X)
    ->  t(X, TX),
        (   nonvar(X), X = (_, _)
        ->  format(atom(Texto), '\\+ (~w)', [TX])
        ;   format(atom(Texto), '\\+ ~w', [TX])
        )
    ;   nonvar(G), G = (X, Y)
    ->  t(X, TX), t(Y, TY),
        format(atom(Texto), '~w, ~w', [TX, TY])
    ;   format(atom(Texto), '~W', [G, [numbervars(true), quoted(false), spacing(next_argument)]])
    ).

% prueba_a_lineas(+Prueba, -Lineas): una linea por nodo, con sangria por nivel.
prueba_a_lineas(Prueba, Lineas) :-
    pl(Prueba, '', Lineas, []).

% izq/der solo dicen que rama de una disyuncion se uso: no ocupan linea propia.
% Una conjuncion de pruebas (A, B) son dos pruebas al mismo nivel.
pl(izq(P), S, L0, L) :- pl(P, S, L0, L).
pl(der(P), S, L0, L) :- pl(P, S, L0, L).
pl((A, B), S, L0, L) :- pl(A, S, L0, L1), pl(B, S, L1, L).
pl(P, Sangria, [Linea|Ls0], Ls) :-
    P \= izq(_), P \= der(_), P \= (_, _),
    etiqueta(P, Marca, Meta),
    txt(Meta, Texto),
    format(atom(Linea), '~w[ok] ~w   ~w', [Sangria, Texto, Marca]),
    hijos(P, Hs),
    atom_concat(Sangria, '   ', Sangria2),
    pl_hijos(Hs, Sangria2, Ls0, Ls).

pl_hijos([], _, L, L).
pl_hijos([H|T], S, L0, L) :-
    pl(H, S, L0, L1),
    pl_hijos(T, S, L1, L).

etiqueta(hecho(G), '[hecho]', G).
etiqueta(builtin(G), '[builtin]', G).
etiqueta(no(G), '[no demostrable]', (\+ G)).
etiqueta(corte, '[corte: se descartaron las clausulas siguientes]', corte).
etiqueta(verdad, '', true).
etiqueta(agregado(G, T, _), Marca, G) :- format(atom(Marca), '[findall: ~w solucion(es)]', [T]).
etiqueta(todos(G, Cs), Marca, G) :- length(Cs, N), format(atom(Marca), '[forall: ~w caso(s)]', [N]).
etiqueta(si(PC, _), '[rama then]', G) :- meta_de_prueba(PC, G).
etiqueta(sino(_), '[rama else]', else).
etiqueta(regla(G, I, Hs), Marca, G) :-
    (   memberchk(corte, Hs) -> Corte = ' + corte' ; Corte = '' ),
    format(atom(Marca), '[clausula ~w~w]', [I, Corte]).

hijos(regla(_, _, Hs), Hs).
hijos(hecho(_), []).
hijos(builtin(_), []).
hijos(no(_), []).
hijos(corte, []).
hijos(verdad, []).
hijos(agregado(_, _, M), Hs) :- findall(H, ( member(X, M), aplanar_y(X, L), member(H, L) ), Hs).
hijos(todos(_, Cs), Hs) :- findall(H, ( member(PC-PA, Cs), member(H, [PC, PA]) ), Hs).
hijos(si(_, PT), [PT]).
hijos(sino(PE), [PE]).