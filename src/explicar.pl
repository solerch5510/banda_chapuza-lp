% explicar.pl
% Meta-interprete y modo explicar (explicar/1, por_que_no/1, arbol/1).
%
% solve/2,3 (docs/02-arquitectura-codigo.md, 6.4 y 6.5) construye la prueba de un objetivo
% y trata el corte de forma real; prueba_a_lineas/2 (6.11) la convierte en un arbol de texto
% ASCII que ui escribe. por_que_no/2 (6.9) es el segundo meta-interprete: explica por que una meta
% NO tiene solucion, y diag_a_lineas/2 convierte ese diagnostico en texto. Los niveles
% resumido/detallado llegan mas adelante.

:- module(explicar, [solve/2, solve/3, prueba_a_lineas/2, meta_de_prueba/2,
                     por_que_no/2, diag_a_lineas/2, diag_a_lineas/3, diag_detalle_a_lineas/2,
                     plegar_lineas/3, lineas_de_prueba/3]).
:- meta_predicate solve(0, -), solve(0, -, +), por_que_no(0, -).

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
    ;   nonvar(G), G = (X ; Y)
    ->  (   nonvar(X), X = (C -> T)
        ->  t(C, TC), t(T, TT), t(Y, TY),
            format(atom(Texto), '(~w -> ~w ; ~w)', [TC, TT, TY])
        ;   t(X, TX), t(Y, TY),
            format(atom(Texto), '(~w ; ~w)', [TX, TY])
        )
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

% ===========================================================================
% por_que_no: por que una meta NO tiene solucion (docs/02 6.9)
%
% Es un segundo meta-interprete. Recorre las clausulas del predicado y busca el primer
% subobjetivo que falla; si es una negacion (\+ X) da la prueba de X, que es la razon de que
% la negacion falle. El diagnostico es un termino:
%   sin_clausula(G)         ningun hecho ni clausula unifica con G (mundo cerrado)
%   fallo(G, Candidatas)    hay clausulas y todas fallan; la mas cercana primero
%   builtin_falso(G)        un predefinido instanciado resulto falso (3 > 5)
%   neg_viola(X, Prueba)    \+ X falla porque X SI se demuestra (se da su prueba)
%   neg_doble(Y, DiagY)     \+ \+ Y falla porque Y no se cumple (se explica por que)
%   tras(PruebaDeA, DiagB)  (A, B): A tiene solucion pero B falla con ella
%   ninguna(DiagA, DiagB)   (A ; B): las dos ramas fallan
%   limite(G)               se agoto la profundidad de diagnostico
% Candidatas = [cl(I, PruebasPrevias, punto(SubobjetivoFallido, DiagDeEse)), ...]
% Solo lee: nunca modifica el estado.
% ===========================================================================

% por_que_no(:Meta, -Diag): falla si la Meta SI se puede demostrar.
por_que_no(Meta, Diag) :-
    strip_module(Meta, M, G),
    \+ s(G, M, 400, _),
    diag(G, M, 40, Diag).

% Las pruebas de los subobjetivos que SI se cumplen usan siempre el limite normal.
prueba_de(G, M, P) :- s(G, M, 400, P).

diag(G, M, N, Diag) :-
    (   N =< 0
    ->  Diag = limite(G)
    ;   clasifica(G, T),
        diag_(T, G, M, N, Diag)
    ).

% (A, B): si A tiene solucion, falla B con ella; si no, falla A.
diag_(conj, (A, B), M, N, Diag) :-
    (   prueba_de(A, M, PA)
    ->  diag(B, M, N, DB),
        Diag = tras(PA, DB)
    ;   diag(A, M, N, Diag)
    ).
% \+ X solo falla si X se demuestra: esa prueba es la razon.
diag_(neg, (\+ X), M, N, Diag) :-
    (   nonvar(X), X = (\+ Y)                    % \+ \+ Y falla porque Y no se cumple
    ->  diag(Y, M, N, DY),
        Diag = neg_doble(Y, DY)
    ;   prueba_de(X, M, P),
        Diag = neg_viola(X, P)
    ).
diag_(hoja, G, _, _, builtin_falso(G)).
diag_(findall, G, _, _, builtin_falso(G)).
diag_(forall, G, _, _, builtin_falso(G)).
diag_(calificada, (M2 : G), _, N, Diag) :-
    diag(G, M2, N, Diag).
% (C -> T ; E): si la condicion se cumple falla T; si no, falla E. (A ; B) sin condicion: fallan las dos.
diag_(disy, (A ; B), M, N, Diag) :-
    (   nonvar(A), A = (C -> T)
    ->  (   prueba_de(C, M, PC)
        ->  diag(T, M, N, DT),
            Diag = tras(PC, DT)
        ;   diag(B, M, N, Diag)
        )
    ;   diag(A, M, N, DA),
        diag(B, M, N, DB),
        Diag = ninguna(DA, DB)
    ).
diag_(si_solo, (C -> T), M, N, Diag) :-
    (   prueba_de(C, M, PC)
    ->  diag(T, M, N, DT),
        Diag = tras(PC, DT)
    ;   diag(C, M, N, Diag)
    ).
diag_(pred, G, M, N, Diag) :-
    modulo_definicion(M, G, D),
    (   modulo_juego(D), definido(D, G)
    ->  findall(cl(I, Pre, Punto), candidata(D, G, N, I, Pre, Punto), C0),
        (   C0 == []
        ->  Diag = sin_clausula(G)
        ;   ordenar_por_cercania(C0, C),
            Diag = fallo(G, C)
        )
    ;   Diag = builtin_falso(G)
    ).

% candidata(+D, +G, +N, -I, -Pre, -Punto): la clausula I de G (en el modulo D) hasta donde llega
% su cuerpo: Pre son las pruebas de los subobjetivos que se cumplen y Punto el primero que falla.
candidata(D, G, N, I, Pre, punto(Fallido, DiagSub)) :-
    clause(D:G, Cuerpo, Ref),
    nth_clause(_, I, Ref),
    conj_lista(Cuerpo, Metas),
    N1 is N - 1,
    prefijo_y_fallo(Metas, D, N1, Pre, Fallido, DiagSub).

% Los cortes se ignoran: si uno hubiera cortado antes, la meta tendria solucion y no estariamos aqui.
prefijo_y_fallo([Meta|Resto], D, N, Pre, Fallido, DiagSub) :-
    (   Meta == !
    ->  prefijo_y_fallo(Resto, D, N, Pre, Fallido, DiagSub)
    ;   prueba_de(Meta, D, P)
    ->  Pre = [P|Pre1],
        prefijo_y_fallo(Resto, D, N, Pre1, Fallido, DiagSub)
    ;   Pre = [],
        Fallido = Meta,
        diag(Meta, D, N, DiagSub)
    ).

% La clausula mas cercana es la que cumplio mas subobjetivos antes de fallar (la primera si empatan).
ordenar_por_cercania(C0, C) :-
    findall(K-I-Cl, ( nth1(I, C0, Cl), Cl = cl(_, Pre, _), length(Pre, L), K is -L ), Ks),
    msort(Ks, S),
    findall(Cl, member(_-_-Cl, S), C).

% ---------------------------------------------------------------------------
% El diagnostico como arbol de texto ASCII (funciones puras, como prueba_a_lineas/2).
%
% Dos niveles (docs/02 6.8), el mismo diagnostico sirve para los dos:
%   resumido   solo la clausula MAS CERCANA y, si falla una negacion, los hechos que la hacen cierta;
%   detallado  TODAS las clausulas aplicables, cada una hasta donde llega, y la prueba completa de
%              por que es cierto lo que la negacion niega (de donde sale cada hecho).
% diag_a_lineas/2 es el nivel resumido.
% ---------------------------------------------------------------------------
diag_a_lineas(Diag, Lineas) :-
    diag_a_lineas(Diag, resumido, Lineas).

diag_a_lineas(Diag, Nivel, Lineas) :-
    cabecera(Diag, Nivel, Cab),
    detalle(Diag, Nivel, '  ', Resto),
    append(Cab, Resto, Lineas).

% diag_detalle_a_lineas(+Diag, -Lineas): solo el detalle (lo que se cumplia y lo que falla), sin la
% cabecera con la meta: para cuando quien lo muestra ya ha dicho de que va.
diag_detalle_a_lineas(Diag, Lineas) :-
    detalle(Diag, resumido, '  ', Lineas).

cabecera(fallo(G, Cands), Nivel, [L]) :-
    txt(G, T),
    (   Nivel == detallado, Cands = [_, _|_]
    ->  length(Cands, N),
        format(atom(L), '[no] ~w   [~w clausulas aplicables y ninguna se cumple]', [T, N])
    ;   Cands = [cl(I, _, _)|_],
        format(atom(L), '[no] ~w   [clausula ~w]', [T, I])
    ).
cabecera(sin_clausula(G), _, [L]) :-
    txt(G, T),
    format(atom(L), '[no] ~w   [no hay ningun hecho ni clausula]', [T]).
cabecera(builtin_falso(G), _, [L]) :-
    txt(G, T),
    format(atom(L), '[no] ~w   [falso]', [T]).
cabecera(neg_viola(X, _), _, [L]) :-
    txt(\+ X, T),
    format(atom(L), '[no] ~w', [T]).
cabecera(neg_doble(Y, _), _, [L]) :-
    txt(\+ (\+ Y), T),
    format(atom(L), '[no] ~w', [T]).
cabecera(tras(_, D), Nivel, Ls) :-
    cabecera(D, Nivel, Ls).
cabecera(ninguna(_, _), _, ['[no] ninguna de las dos ramas se cumple']).
cabecera(limite(G), _, [L]) :-
    txt(G, T),
    format(atom(L), '[no] ~w   [se agoto la profundidad del diagnostico]', [T]).

% Una clausula candidata hasta donde llega: lo que se cumplia, lo que falla y por que falla.
candidata_a_lineas(cl(_, Pre, punto(F, D)), Nivel, S, Ls) :-
    findall(L,
            (   member(P, Pre),
                meta_de_prueba(P, PG),
                txt(PG, PT),
                format(atom(L), '~w|- [ok] ~w', [S, PT])
            ),
            Oks),
    txt(F, TF),
    format(atom(LF), '~w\\- [no] ~w', [S, TF]),
    atom_concat(S, '      ', S2),
    detalle(D, Nivel, S2, Sub),
    append([Oks, [LF], Sub], Ls).

detalle(fallo(_, Cands), Nivel, S, Ls) :-
    (   Nivel == detallado, Cands = [_, _|_]
    ->  atom_concat(S, '   ', S2),
        candidatas_a_lineas(Cands, 1, Nivel, S, S2, Ls)
    ;   Cands = [C|_],
        candidata_a_lineas(C, Nivel, S, Ls)
    ).
detalle(tras(_, D), Nivel, S, Ls) :-
    detalle(D, Nivel, S, Ls).
detalle(neg_viola(_, P), Nivel, S, Ls) :-
    aplanar_y(P, Ps),
    findall(T, ( member(Q, Ps), meta_de_prueba(Q, QG), txt(QG, T) ), Ts),
    unir_y(Ts, Y),
    (   Ts = [_] -> Verbo = 'es cierto' ; Verbo = 'son ciertos' ),
    format(atom(L), '~wporque ~w ~w.', [S, Y, Verbo]),
    (   Nivel == detallado
    ->  prueba_a_lineas(P, Arbol),
        atom_concat(S, '   ', S2),
        findall(LA, ( member(A, Arbol), atom_concat(S2, A, LA) ), Sangrado),
        Ls = [L|Sangrado]
    ;   Ls = [L]
    ).
% \+ \+ Y falla porque Y no se cumple: se explica por que no.
detalle(neg_doble(_, D), Nivel, S, [L|Ramas]) :-
    format(atom(L), '~wporque lo que niega no se cumple:', [S]),
    ramas([D], Nivel, S, Ramas).
detalle(sin_clausula(G), _, S, [L]) :-
    txt(G, T),
    format(atom(L), '~wno hay ningun hecho ni clausula para ~w', [S, T]).
detalle(builtin_falso(G), _, S, [L]) :-
    txt(G, T),
    format(atom(L), '~w~w es falso', [S, T]).
detalle(ninguna(DA, DB), Nivel, S, Ls) :-
    ramas([DA, DB], Nivel, S, Ls).
detalle(limite(_), _, S, [L]) :-
    format(atom(L), '~wno sigo: demasiado profundo', [S]).

% candidatas_a_lineas(+Cands, +Numero, +Nivel, +S, +S2, -Lineas): cada candidata con su titulo.
candidatas_a_lineas([], _, _, _, _, []).
candidatas_a_lineas([C|Cs], K, Nivel, S, S2, Ls) :-
    C = cl(I, _, _),
    (   K =:= 1
    ->  format(atom(Titulo), '~wclausula ~w (la mas cercana):', [S, I])
    ;   format(atom(Titulo), '~wclausula ~w:', [S, I])
    ),
    candidata_a_lineas(C, Nivel, S2, Cuerpo),
    K1 is K + 1,
    candidatas_a_lineas(Cs, K1, Nivel, S, S2, Resto),
    append([[Titulo], Cuerpo, Resto], Ls).

ramas([], _, _, []).
ramas([D|Ds], Nivel, S, Ls) :-
    cabecera(D, Nivel, Cab),
    atom_concat(S, '   ', S2),
    detalle(D, Nivel, S2, Det),
    findall(L, ( member(C, Cab), format(atom(L), '~w\\- ~w', [S, C]) ), CabS),
    ramas(Ds, Nivel, S, Resto),
    append([CabS, Det, Resto], Ls).

% unir_y(+Textos, -Atomo): "a", "a y b", "a, b y c".
unir_y([X], X).
unir_y([X, Y], R) :-
    format(atom(R), '~w y ~w', [X, Y]).
unir_y([X, Y, Z|T], R) :-
    unir_y([Y, Z|T], R1),
    format(atom(R), '~w, ~w', [X, R1]).

% ---------------------------------------------------------------------------
% Los niveles de una prueba (docs/02 6.8): resumido pliega el arbol a la raiz y sus hijos directos
% (los nodos de debajo salen como "[+N nodos]"); detallado lo enseña entero.
% ---------------------------------------------------------------------------
lineas_de_prueba(Prueba, Nivel, Lineas) :-
    prueba_a_lineas(Prueba, Completas),
    (   Nivel == detallado
    ->  Lineas = Completas
    ;   plegar_lineas(Completas, 1, Lineas)
    ).

% ---------------------------------------------------------------------------
% Plegar un arbol de texto: se conservan las lineas hasta una profundidad y las de debajo se
% sustituyen por "[+N nodos]" en el nodo que las contenia. Funcion pura sobre las lineas que
% devuelve prueba_a_lineas/2 (una linea por nodo, tres espacios de sangria por nivel).
%   Prof = 0 deja solo las raices; Prof grande no pliega nada.
% ---------------------------------------------------------------------------
plegar_lineas([], _, []).
plegar_lineas([L|Ls], Prof, [Salida|Resto]) :-
    profundidad_de_linea(L, D),
    (   D >= Prof
    ->  hijas_mas_hondas(Ls, Prof, N, Siguientes),
        (   N =:= 0
        ->  Salida = L
        ;   N =:= 1
        ->  format(atom(Salida), '~w   [+1 nodo]', [L])
        ;   format(atom(Salida), '~w   [+~w nodos]', [L, N])
        ),
        plegar_lineas(Siguientes, Prof, Resto)
    ;   Salida = L,
        plegar_lineas(Ls, Prof, Resto)
    ).

% hijas_mas_hondas(+Lineas, +Prof, -N, -Resto): las primeras lineas MAS hondas que Prof y cuantas son.
hijas_mas_hondas([], _, 0, []).
hijas_mas_hondas([L|Ls], Prof, N, Resto) :-
    profundidad_de_linea(L, D),
    (   D > Prof
    ->  hijas_mas_hondas(Ls, Prof, N0, Resto),
        N is N0 + 1
    ;   N = 0,
        Resto = [L|Ls]
    ).

% profundidad_de_linea(+Linea, -D): los espacios iniciales entre tres.
profundidad_de_linea(L, D) :-
    atom_codes(L, Cs),
    espacios_iniciales(Cs, 0, E),
    D is E // 3.

espacios_iniciales(Cs, N0, N) :-
    (   Cs = [0' |Resto]
    ->  N1 is N0 + 1,
        espacios_iniciales(Resto, N1, N)
    ;   N = N0
    ).
