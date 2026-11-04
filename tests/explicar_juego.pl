% explicar_juego.pl (pruebas)
% El meta-interprete (explicar:solve/2) sobre las reglas REALES del juego, no sobre los
% modulos de juguete del spike: debe dar las mismas respuestas, en el mismo orden, que
% ejecutar las reglas directamente. Y la presentacion de la prueba como arbol de texto.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/explicar_juego -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/explicar').

% Todas las soluciones de Plantilla, con ejecucion directa y con solve/2, y en el mismo orden.
igual(Plantilla, Meta) :-
    findall(Plantilla, Meta, Directo),
    findall(Plantilla, solve(Meta, _), ConSolve),
    Directo == ConSolve.

% nueva partida y, encima, estos efectos.
en_estado(Efectos) :-
    nueva_partida,
    aplicar_efectos(Efectos).

% Estados variados para comprobar las mismas reglas en situaciones distintas.
estado_de_prueba(inicio,            []).
estado_de_prueba(en_la_aldea,       [viajar(aldea)]).
estado_de_prueba(en_el_camino,      [viajar(camino_real)]).
estado_de_prueba(sueldos_pendientes,[desmarcar(sueldos_pagados)]).
estado_de_prueba(sin_queso,         [gastar_queso(cheddar, 0, 12)]).
estado_de_prueba(poco_queso,        [gastar_queso(cheddar, 0, 11)]).
estado_de_prueba(queso_mezclado,    [ganar_queso(brie, 4, 2), ganar_queso(cheddar, 12, 3),
                                     ganar_queso(cheddar, 5, 1), desmarcar(sueldos_pagados)]).
estado_de_prueba(con_un_caido,      [dano(rufino, 999)]).
estado_de_prueba(con_huelga,        [mod_moral(baldomero, -4), mod_moral(tuerca, -5)]).
estado_de_prueba(fin_de_partida,    [fin(victoria)]).

en_cada_estado(Objetivo) :-
    forall(estado_de_prueba(Nombre, Efectos),
           (   en_estado(Efectos),
               (   call(Objetivo)
               ->  true
               ;   format(user_error, "falla en el estado ~w~n", [Nombre]), fail
               )
           )).

% Solo codigos ASCII.
ascii(Atomo) :- atom_codes(Atomo, Cs), forall(member(C, Cs), C < 128).

:- begin_tests(equivalencia_con_las_reglas_reales).

test(puede_viajar_a_cada_zona_en_cada_estado) :-
    en_cada_estado(forall(mundo:zona(Z, _), igual(x, compania:puede_viajar(Z)))).

test(puede_descansar_en_cada_estado) :-
    en_cada_estado(igual(x, economia:puede_descansar)).

test(puede_pagar_sueldos_en_cada_estado) :-
    en_cada_estado(igual(x, economia:puede_pagar_sueldos)).

test(la_despensa_en_orden_de_racion) :-
    en_cada_estado(igual(L, economia:despensa(L))).

test(categoria_queso_en_cada_edad) :-
    nueva_partida,
    forall(between(0, 15, E), igual(C, economia:categoria_queso(E, C))).

test(valor_queso_en_cada_edad) :-
    nueva_partida,
    forall(between(0, 15, E),
           (   igual(V, economia:valor_queso(cheddar, E, V)),
               igual(V, economia:valor_queso(brie, E, V))
           )).

test(cantidades_derivadas_del_estado) :-
    en_cada_estado(( igual(T, economia:queso_total(T)),
                     igual(V, economia:valor_despensa(V)),
                     igual(S, economia:total_sueldos(S)) )).

test(quienes_estan_activos_y_en_pie) :-
    en_cada_estado(( igual(Id, compania:miembro(Id)),
                     igual(Id, compania:activo(Id)),
                     igual(Id, compania:en_pie(Id)),
                     forall(compania:miembro(M), igual(x, compania:esta_en_huelga(M))) )).

test(el_informe_de_la_compania) :-
    en_cada_estado(igual(F, compania:informe(F))).

test(el_inventario) :-
    en_cada_estado(igual(D, economia:inventario(D))).

test(la_racion_diaria_incluidas_ramas_if_then_else) :-
    en_cada_estado(igual(E, economia:efectos_racion(E))).

test(los_efectos_de_descanso_y_de_sueldos) :-
    en_cada_estado(( igual(E, economia:efectos_descanso(E)),
                     igual(E, economia:efectos_sueldos(E)) )).

:- end_tests(equivalencia_con_las_reglas_reales).

:- begin_tests(forma_de_la_prueba).

test(puede_viajar_es_una_regla_con_tres_hijos, [setup(nueva_partida), nondet]) :-
    solve(compania:puede_viajar(aldea), P),
    P = regla(puede_viajar(aldea), 1, Hijos),
    Hijos = [hecho(en_zona(taberna)), regla(adyacente(taberna, aldea), 1, _), no(_)].

test(la_segunda_clausula_de_adyacente_numera_2, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(aldea)),
    solve(compania:puede_viajar(taberna), P),
    P = regla(_, 1, [_, regla(adyacente(aldea, taberna), 2, _), _]).

test(una_meta_imposible_no_tiene_prueba, [setup(nueva_partida), fail]) :-
    solve(compania:puede_viajar(castillo), _).

test(los_dinamicos_salen_como_hechos, [setup(nueva_partida)]) :-
    solve(estado:queso(cheddar, 0, C), P),
    C == 12,
    P == hecho(queso(cheddar, 0, 12)).

test(las_constantes_de_balance_salen_como_hechos, [setup(nueva_partida)]) :-
    solve(economia:puede_descansar, P),
    P = regla(puede_descansar, 1, Hijos),
    memberchk(hecho(parametro(coste_descanso, 2)), Hijos).

test(findall_y_aritmetica_aparecen_como_hojas_y_agregados, [setup(nueva_partida)]) :-
    solve(economia:queso_total(N), P),
    N == 12,
    P = regla(queso_total(12), 1, [agregado(_, 1, _), builtin(sumlist([12], 12))]).

test(la_negacion_no_demostrable_se_marca, [setup(nueva_partida)]) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),
    solve(economia:puede_pagar_sueldos, P),
    P = regla(puede_pagar_sueldos, 1, [no(estado:marca(sueldos_pagados))|_]).

test(las_ramas_if_then_else_se_distinguen, [setup(nueva_partida), nondet]) :-
    solve(economia:efectos_racion(_), Con),
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    solve(economia:efectos_racion(_), Sin),
    explicar:prueba_a_lineas(Con, LCon),
    explicar:prueba_a_lineas(Sin, LSin),
    once(( member(L1, LCon), sub_atom(L1, _, _, _, '[rama then]') )),
    once(( member(L2, LSin), sub_atom(L2, _, _, _, '[rama else]') )).

test(meta_de_prueba_recupera_la_meta, [setup(nueva_partida), nondet]) :-
    solve(compania:puede_viajar(aldea), P),
    explicar:meta_de_prueba(P, G),
    G == puede_viajar(aldea).

:- end_tests(forma_de_la_prueba).

:- begin_tests(arbol_de_texto).

test(puede_viajar_en_ascii, [setup(nueva_partida), nondet]) :-
    solve(compania:puede_viajar(aldea), P),
    explicar:prueba_a_lineas(P, Lineas),
    Lineas == ['[ok] puede_viajar(aldea)   [clausula 1]',
               '   [ok] en_zona(taberna)   [hecho]',
               '   [ok] adyacente(taberna, aldea)   [clausula 1]',
               '      [ok] conexion(taberna, aldea)   [hecho]',
               '   [ok] \\+ fin_partida(A)   [no demostrable]'].

test(las_lineas_son_ascii_y_empiezan_por_ok, [setup(nueva_partida)]) :-
    forall(member(Meta, [compania:puede_viajar(aldea), economia:puede_descansar,
                         economia:inventario(_), economia:efectos_racion(_)]),
           (   solve(Meta, P),
               explicar:prueba_a_lineas(P, Lineas),
               Lineas \== [],
               forall(member(L, Lineas),
                      (   ascii(L),
                          (   sub_atom(L, _, _, _, '[ok] ') -> true ; fail )
                      ))
           )).

test(la_sangria_crece_de_tres_en_tres, [setup(nueva_partida)]) :-
    solve(economia:puede_descansar, P),
    explicar:prueba_a_lineas(P, [Raiz|Resto]),
    sub_atom(Raiz, 0, _, _, '[ok] puede_descansar'),
    forall(member(L, Resto),
           (   atom_codes(L, Cs),
               append(Espacios, [0'[|_], Cs),
               forall(member(C, Espacios), C == 0' ),
               length(Espacios, N),
               N mod 3 =:= 0,
               N >= 3
           )).

test(el_arbol_no_muestra_el_modulo, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),            % con sueldos pendientes la regla se cumple
    solve(economia:puede_pagar_sueldos, P),
    explicar:prueba_a_lineas(P, Lineas),
    forall(member(L, Lineas), \+ sub_atom(L, _, _, _, 'estado:')).

test(las_lineas_largas_se_recortan, [setup(nueva_partida), nondet]) :-
    solve(economia:efectos_racion(_), P),
    explicar:prueba_a_lineas(P, Lineas),
    forall(member(L, Lineas), ( atom_length(L, N), N < 140 )).

test(el_corte_se_marca_en_el_arbol, [setup(nueva_partida)]) :-
    explicar:prueba_a_lineas(regla(f(a), 2, [hecho(g(a)), corte]), Lineas),
    Lineas == ['[ok] f(a)   [clausula 2 + corte]',
               '   [ok] g(a)   [hecho]',
               '   [ok] corte   [corte: se descartaron las clausulas siguientes]'].

:- end_tests(arbol_de_texto).
