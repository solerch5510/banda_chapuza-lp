% niveles.pl (pruebas)
% T-34: los niveles `resumido` y `detallado` (comando nivel/1 y ajuste de sesion) y por_que_no v2:
% varias clausulas aplicables (todas en el nivel detallado, solo la mas cercana en el resumido),
% negaciones anidadas (neg_doble) y la prueba de por que es cierto lo que una negacion niega.
% El mismo arbol/diagnostico sirve para los dos niveles: lo que cambia es COMO se muestra.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/niveles -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/explicar').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('spike/toy_diag').

:- multifile explicar:modulo_juego/1.
explicar:modulo_juego(toy_diag).

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

n_lineas(Texto, N) :-
    atomic_list_concat(Ls, '\n', Texto),
    exclude(==(''), Ls, NoVacias),
    length(NoVacias, N).

alguna_linea(Ls, Texto) :- member(L, Ls), contiene(L, Texto), !.

% La foto del estado sin los contadores de rotacion de frases (decir algo los sube y no cuenta como cambio).
foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), N \== usos_frase,
                 functor(H, N, A), call(H) ), Hs).

combate_con(Tipos) :-
    nueva_partida,
    comenzar_combate(Tipos, _).

en_el_camino_real :-
    nueva_partida,
    aplicar_efecto(viajar(camino_real)).

lineas(Diag, Nivel, Ls) :- diag_a_lineas(Diag, Nivel, Ls).

% ---------------------------------------------------------------------------

:- begin_tests(el_efecto_ajustar).

test(guarda_un_ajuste, [setup(nueva_partida)]) :-
    aplicar_efecto(ajustar(nivel_explicacion, detallado)),
    estado:ajuste(nivel_explicacion, detallado).

test(el_siguiente_sustituye_al_anterior, [setup(nueva_partida)]) :-
    aplicar_efecto(ajustar(nivel_explicacion, detallado)),
    aplicar_efecto(ajustar(nivel_explicacion, resumido)),
    findall(V, estado:ajuste(nivel_explicacion, V), [resumido]).

test(las_claves_son_independientes, [setup(nueva_partida)]) :-
    aplicar_efecto(ajustar(a, 1)),
    aplicar_efecto(ajustar(b, 2)),
    estado:ajuste(a, 1), estado:ajuste(b, 2).

test(una_clave_que_no_es_un_atomo_no_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(ajustar(f(x), 1)).

test(un_valor_sin_ligar_no_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(ajustar(nivel_explicacion, _)).

test(es_un_efecto_conocido) :-
    once(estado:efecto_conocido(ajustar(_, _))).

test(una_partida_nueva_vuelve_al_nivel_por_defecto, [setup(nueva_partida)]) :-
    aplicar_efecto(ajustar(nivel_explicacion, detallado)),
    nueva_partida,
    \+ estado:ajuste(nivel_explicacion, _).

:- end_tests(el_efecto_ajustar).

:- begin_tests(el_comando_nivel).

test(es_un_comando_con_un_argumento) :-
    validar_comando(nivel(resumido), ok(nivel(resumido))),
    validar_comando(nivel(_), error(falta_argumento(_))),
    validar_comando(nivel, error(no_entiendo(_))),
    validar_comando(nivel(a, b), error(no_entiendo(_))).

test(vale_en_todas_las_fases) :-
    forall(member(F, [exploracion, taberna, combate, fin]), permitido(F, nivel)).

test(tiene_texto_de_ayuda) :-
    ayuda_de(nivel, T),
    contiene(T, 'nivel(resumido)'), contiene(T, 'nivel(detallado)').

test(cambia_el_nivel_y_lo_dice, [setup(nueva_partida), nondet]) :-
    ordena(nivel(detallado), [msg(nivel, [detallado], _)]),
    estado:ajuste(nivel_explicacion, detallado),
    ordena(nivel(resumido), [msg(nivel, [resumido], _)]),
    estado:ajuste(nivel_explicacion, resumido).

test(la_pantalla_dice_el_nivel, [setup(nueva_partida), nondet]) :-
    pantalla(nivel(detallado), T1), contiene(T1, 'Nivel detallado'), contiene(T1, 'salen enteras'),
    pantalla(nivel(resumido), T2), contiene(T2, 'Nivel resumido'), contiene(T2, 'plegadas a lo esencial').

test(un_nivel_que_no_existe_es_un_error_y_nada_cambia, [setup(nueva_partida), nondet]) :-
    foto_estado(A),
    ordena(nivel(otro), [error(nivel_desconocido(otro))]),
    ordena(nivel(1), [error(nivel_desconocido(1))]),
    foto_estado(B),
    A =@= B.

test(el_error_se_lee_bien, [setup(nueva_partida), nondet]) :-
    pantalla(nivel(otro), T),
    contiene(T, 'No existe el nivel "otro"'),
    \+ contiene(T, 'error(').

test(repetirlo_no_cambia_nada_mas, [setup(nueva_partida), nondet]) :-
    ordena(nivel(detallado), _),
    foto_estado(A),
    ordena(nivel(detallado), _),
    foto_estado(B),
    A =@= B.

test(solo_cambia_el_ajuste, [setup(nueva_partida), nondet]) :-
    foto_estado(A),
    ordena(nivel(detallado), _),
    foto_estado(B),
    findall(X, ( member(X, B), \+ ( member(Y, A), X =@= Y ) ), Nuevos),
    Nuevos == [ajuste(nivel_explicacion, detallado)],
    findall(X, ( member(X, A), \+ ( member(Y, B), X =@= Y ) ), Perdidos),
    Perdidos == [].

test(el_nivel_se_conserva_entre_comandos, [setup(nueva_partida), nondet]) :-
    ordena(nivel(detallado), _),
    ordena(ir(aldea), _),
    ordena(mirar, _),
    estado:ajuste(nivel_explicacion, detallado).

test(funciona_al_acabar_la_partida, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    ordena(nivel(detallado), [msg(nivel, [detallado], _)]).

:- end_tests(el_comando_nivel).

:- begin_tests(lineas_de_prueba).

test(detallado_es_la_prueba_entera, [setup(combate_con([bandido_torpe])), nondet]) :-
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    prueba_a_lineas(P, Ls),
    lineas_de_prueba(P, detallado, Ls).

test(resumido_es_la_prueba_plegada_a_un_nivel, [setup(combate_con([bandido_torpe])), nondet]) :-
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    prueba_a_lineas(P, Ls),
    plegar_lineas(Ls, 1, Plegadas),
    lineas_de_prueba(P, resumido, Plegadas).

test(resumido_es_mas_corto_que_detallado, [setup(combate_con([bandido_torpe])), nondet]) :-
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    lineas_de_prueba(P, resumido, R), lineas_de_prueba(P, detallado, D),
    length(R, NR), length(D, ND),
    NR < ND.

test(un_nivel_desconocido_se_trata_como_resumido, [setup(combate_con([bandido_torpe])), nondet]) :-
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    lineas_de_prueba(P, otro, L), lineas_de_prueba(P, resumido, L).

test(una_prueba_de_un_solo_nodo_no_cambia, [setup(nueva_partida), nondet]) :-
    solve(estado:en_zona(taberna), P),
    lineas_de_prueba(P, resumido, L1), lineas_de_prueba(P, detallado, L2),
    L1 == L2.

:- end_tests(lineas_de_prueba).

:- begin_tests(la_pantalla_de_explicar).

test(por_defecto_es_resumido_y_cabe_en_quince_lineas, [setup(combate_con([bandido_torpe])), nondet]) :-
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T),
    n_lineas(T, N),
    N =< 15,
    contiene(T, 'dano(baldomero, e(bandido_torpe, 1), 9)'),
    contiene(T, '9 is max(1, 11-2+0)'),
    contiene(T, 'nodos]').

test(el_resumido_no_enseña_los_detalles, [setup(combate_con([bandido_torpe])), nondet]) :-
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T),
    \+ contiene(T, 'bando_contrario'),
    \+ contiene(T, 'nivel_de_moral').

test(el_detallado_lo_enseña_todo, [setup(combate_con([bandido_torpe])), nondet]) :-
    ordena(nivel(detallado), _),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T),
    contiene(T, 'bando_contrario'),
    contiene(T, 'nivel_de_moral'),
    n_lineas(T, N), N > 40,
    \+ contiene(T, 'nodos]').

test(volver_a_resumido_vuelve_a_plegar, [setup(combate_con([bandido_torpe])), nondet]) :-
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T1),
    ordena(nivel(detallado), _),
    ordena(nivel(resumido), _),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T2),
    T1 == T2.

test(ambos_niveles_traen_la_frase_del_narrador, [setup(combate_con([bandido_torpe])), nondet]) :-
    forall(member(Nivel, [resumido, detallado]),
           (   ordena(nivel(Nivel), _),
               pantalla(explicar(atacar(baldomero, bandido_torpe)), T),
               contiene(T, 'Narrador:')
           )).

test(el_nivel_no_cambia_la_prueba_que_se_calcula, [setup(combate_con([bandido_torpe])), nondet]) :-
    ordena(explicar(atacar(baldomero, bandido_torpe)), I1),
    ordena(nivel(detallado), _),
    ordena(explicar(atacar(baldomero, bandido_torpe)), I2),
    I1 =@= I2.

test(el_nivel_no_cambia_el_estado_al_explicar, [setup(combate_con([bandido_torpe])), nondet]) :-
    forall(member(Nivel, [resumido, detallado]),
           (   ordena(nivel(Nivel), _),
               foto_estado(A),
               pantalla(explicar(atacar(baldomero, bandido_torpe)), _),
               foto_estado(B),
               A =@= B
           )).

:- end_tests(la_pantalla_de_explicar).

:- begin_tests(varias_clausulas).

test(el_resumido_solo_enseña_la_mas_cercana, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), D),
    lineas(D, resumido, Ls),
    alguna_linea(Ls, '[clausula 2]'),
    \+ alguna_linea(Ls, 'clausula 1').

test(el_detallado_enseña_todas, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), D),
    lineas(D, detallado, Ls),
    Ls = [Cab|_],
    Cab == '[no] r_dos(1)   [2 clausulas aplicables y ninguna se cumple]',
    alguna_linea(Ls, 'clausula 2 (la mas cercana):'),
    alguna_linea(Ls, 'clausula 1:'),
    alguna_linea(Ls, '|- [ok] a(1)'),
    alguna_linea(Ls, '1>5 es falso'),
    alguna_linea(Ls, 'hecho_d(1)').

test(la_mas_cercana_va_primero_en_el_detallado, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), D),
    lineas(D, detallado, Ls),
    nth0(I2, Ls, L2), contiene(L2, 'clausula 2 (la mas cercana)'),
    nth0(I1, Ls, L1), contiene(L1, 'clausula 1:'),
    I2 < I1, !.

test(con_una_sola_clausula_los_dos_niveles_coinciden_en_la_cabecera, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1), D),
    lineas(D, resumido, [C1|_]), lineas(D, detallado, [C2|_]),
    C1 == C2,
    C1 == '[no] r_builtin(1)   [clausula 1]'.

test(con_una_sola_clausula_no_hay_titulos_de_clausula, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1), D),
    lineas(D, detallado, Ls),
    \+ alguna_linea(Ls, 'la mas cercana').

test(un_caso_real_adyacente_tiene_dos_clausulas, [setup(nueva_partida), nondet]) :-
    por_que_no(compania:puede_viajar(castillo), D),
    lineas(D, resumido, R),
    \+ alguna_linea(R, 'clausula 2'),
    lineas(D, detallado, T),
    alguna_linea(T, 'clausula 1 (la mas cercana):'),
    alguna_linea(T, 'clausula 2:'),
    alguna_linea(T, 'conexion(taberna, castillo)'),
    alguna_linea(T, 'conexion(castillo, taberna)').

test(la_pantalla_real_cambia_con_el_nivel, [setup(nueva_partida), nondet]) :-
    pantalla(por_que_no(ir(castillo)), T1),
    \+ contiene(T1, 'clausula 2'),
    ordena(nivel(detallado), _),
    pantalla(por_que_no(ir(castillo)), T2),
    contiene(T2, 'clausula 2:'),
    contiene(T2, 'conexion(castillo, taberna)').

test(las_lineas_de_cada_clausula_estan_sangradas_bajo_su_titulo, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), D),
    lineas(D, detallado, Ls),
    nth0(I, Ls, T), contiene(T, 'clausula 2 (la mas cercana)'),
    I1 is I + 1, nth0(I1, Ls, Sig),
    atom_concat('     ', _, Sig).

:- end_tests(varias_clausulas).

:- begin_tests(la_negacion_explicada).

test(el_resumido_da_los_hechos_pero_no_la_prueba, [setup(combate_con([bandido_montado])), nondet]) :-
    por_que_no(combate:puede_atacar(baldomero, e(bandido_montado, 1)), D),
    lineas(D, resumido, Ls),
    alguna_linea(Ls, 'porque teme(baldomero, caballo) y clase_de(e(bandido_montado, 1), caballo) son ciertos.'),
    \+ alguna_linea(Ls, 'rasgo(baldomero, teme_caballos)').

test(el_detallado_da_la_prueba_de_donde_sale_el_miedo, [setup(combate_con([bandido_montado])), nondet]) :-
    por_que_no(combate:puede_atacar(baldomero, e(bandido_montado, 1)), D),
    lineas(D, detallado, Ls),
    alguna_linea(Ls, '[ok] teme(baldomero, caballo)   [clausula 1]'),
    alguna_linea(Ls, '[ok] rasgo(baldomero, teme_caballos)   [hecho]'),
    alguna_linea(Ls, '[ok] \\+ ignora_miedo(baldomero)   [no demostrable]'),
    alguna_linea(Ls, '[ok] clase_de(e(bandido_montado, 1), caballo)'),
    alguna_linea(Ls, '[ok] clase(bandido_montado, caballo)   [hecho]').

test(la_prueba_va_despues_del_porque_y_mas_sangrada, [nondet]) :-
    por_que_no(toy_diag:r_neg(1), D),
    lineas(D, detallado, Ls),
    nth0(I, Ls, P), contiene(P, 'porque tiene(x) es cierto.'),
    I1 is I + 1, nth0(I1, Ls, Arbol),
    contiene(Arbol, '[ok] tiene(x)   [hecho]'),
    sub_atom(P, 0, A, _, ' '), sub_atom(Arbol, 0, B, _, ' '), B >= A.

test(demostracion_2_en_detallado_da_los_hechos_de_la_gallina, [setup(en_el_camino_real), nondet]) :-
    por_que_no(contratos:puede_aceptar(gallina_noble), D),
    lineas(D, detallado, Ls),
    alguna_linea(Ls, '[ok] activo(baldomero)'),
    alguna_linea(Ls, '[ok] rasgo(baldomero, teme_caballos)   [hecho]'),
    alguna_linea(Ls, '[ok] \\+ ignora_miedo(baldomero)   [no demostrable]').

test(una_negacion_con_otra_dentro_la_enseña_como_no_demostrable, [nondet]) :-
    por_que_no(toy_diag:r_neg_anidada, D),
    lineas(D, resumido, R),
    alguna_linea(R, 'porque a(1) y \\+ a(9) son ciertos.'),
    lineas(D, detallado, T),
    alguna_linea(T, '[ok] \\+ a(9)   [no demostrable]').

:- end_tests(la_negacion_explicada).

:- begin_tests(negaciones_anidadas).

test(doble_negacion_es_neg_doble_del_interior, [nondet]) :-
    por_que_no(toy_diag:r_doble, fallo(_, [cl(1, [], punto(\+ \+ a(9), neg_doble(a(9), sin_clausula(a(9)))))])).

test(triple_negacion_baja_a_una_negacion_que_si_falla, [nondet]) :-
    por_que_no(toy_diag:r_triple, fallo(_, [cl(1, [], punto(_, neg_doble(\+ a(1), neg_viola(a(1), hecho(a(1))))))])).

test(la_doble_negacion_se_lee, [nondet]) :-
    por_que_no(toy_diag:r_doble, D),
    lineas(D, resumido, Ls),
    alguna_linea(Ls, '[no] \\+ \\+ a(9)'),
    alguna_linea(Ls, 'porque lo que niega no se cumple:'),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para a(9)').

test(la_triple_negacion_llega_a_porque_es_cierto, [nondet]) :-
    por_que_no(toy_diag:r_triple, D),
    lineas(D, resumido, Ls),
    alguna_linea(Ls, '[no] \\+ \\+ \\+ a(1)'),
    alguna_linea(Ls, 'porque a(1) es cierto.').

test(en_el_detallado_la_triple_negacion_trae_la_prueba_del_fondo, [nondet]) :-
    por_que_no(toy_diag:r_triple, D),
    lineas(D, detallado, Ls),
    alguna_linea(Ls, '[ok] a(1)   [hecho]').

test(la_cabecera_de_una_doble_negacion_en_la_meta_raiz, [nondet]) :-
    por_que_no(\+ \+ toy_diag:a(9), D),
    D = neg_doble(_, sin_clausula(a(9))),
    lineas(D, resumido, [Cab|_]),
    Cab == '[no] \\+ \\+ a(9)'.

test(la_clave_de_una_doble_negacion_es_la_del_interior, [nondet]) :-
    por_que_no(toy_diag:r_triple, D),
    claves_de_diag(D, Cs),
    Cs = [impide(a(1))|_].

test(el_narrador_siempre_tiene_frase_para_una_doble_negacion, [nondet]) :-
    por_que_no(toy_diag:r_doble, D),
    forall(member(N, [resumido, detallado]),
           (   comentario_diag(D, N, 0, T), atom(T), T \== '' )).

test(una_negacion_simple_sigue_siendo_neg_viola, [nondet]) :-
    por_que_no(toy_diag:r_neg(1), fallo(_, [cl(1, _, punto(_, neg_viola(tiene(x), _)))])).

:- end_tests(negaciones_anidadas).

:- begin_tests(la_pantalla_de_por_que_no).

test(el_resumido_de_la_demo_2_cabe_en_veinte_lineas, [setup(en_el_camino_real), nondet]) :-
    pantalla(por_que_no(aceptar(gallina_noble)), T),
    n_lineas(T, N), N =< 20.

test(el_detallado_de_la_demo_2_es_mas_largo, [setup(en_el_camino_real), nondet]) :-
    pantalla(por_que_no(aceptar(gallina_noble)), T1),
    ordena(nivel(detallado), _),
    pantalla(por_que_no(aceptar(gallina_noble)), T2),
    n_lineas(T1, N1), n_lineas(T2, N2),
    N1 < N2.

test(el_detallado_enseña_el_rasgo_en_la_demo_1, [setup(combate_con([bandido_montado])), nondet]) :-
    ordena(nivel(detallado), _),
    pantalla(por_que_no(atacar(baldomero, bandido_montado)), T),
    contiene(T, 'rasgo(baldomero, teme_caballos)'),
    contiene(T, 'ignora_miedo(baldomero)'),
    contiene(T, 'Narrador: Sir Baldomero ve el caballo').

test(el_resumido_no_cae_en_el_error_de_una_frase_solo_detallada, [setup(nueva_partida), nondet]) :-
    % la frase generica de "algo lo impide" es solo del nivel detallado: en el resumido sale la general
    pantalla(por_que_no(pagar), T),
    contiene(T, 'Narrador:'),
    \+ contiene(T, 'vista('),
    contiene(T, 'No se cumple').

test(el_detallado_si_usa_la_frase_de_algo_lo_impide, [setup(nueva_partida), nondet]) :-
    ordena(nivel(detallado), _),
    pantalla(por_que_no(pagar), T),
    contiene(T, 'Algo lo impide').

test(los_dos_niveles_nunca_ensenan_terminos_crudos, [setup(nueva_partida), nondet]) :-
    forall(( member(Nivel, [resumido, detallado]),
             member(Cmd, [por_que_no(ir(castillo)), por_que_no(aceptar(gallina_noble)), por_que_no(pagar),
                          por_que_no(aceptar(dragon)), por_que_no(volar), por_que_no(ir(aldea))]) ),
           (   ordena(nivel(Nivel), _),
               pantalla(Cmd, T),
               \+ contiene(T, 'vista('), \+ contiene(T, 'fallo('), \+ contiene(T, 'neg_viola('),
               \+ contiene(T, 'error(')
           )).

test(la_misma_pregunta_da_lo_mismo_en_cada_nivel, [setup(nueva_partida), nondet]) :-
    forall(member(Nivel, [resumido, detallado]),
           (   ordena(nivel(Nivel), _),
               pantalla(por_que_no(aceptar(gallina_noble)), T1),
               pantalla(por_que_no(aceptar(gallina_noble)), T2),
               T1 == T2
           )).

:- end_tests(la_pantalla_de_por_que_no).

:- begin_tests(la_decision_del_enemigo_por_niveles).

turno(Tipos) :-
    Tipos = [Tipo|_],
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    juego:turno_enemigo(e(Tipo, 1), _).

test(el_resumido_pliega_el_arbol_y_el_detallado_lo_da_entero, [nondet]) :-
    turno([bandido_torpe]),
    pantalla(explicar, T1),
    contiene(T1, 'nodos]'),
    \+ contiene(T1, 'bando_contrario'),
    ordena(nivel(detallado), _),
    pantalla(explicar, T2),
    contiene(T2, 'bando_contrario'),
    \+ contiene(T2, 'nodos]'),
    n_lineas(T1, N1), n_lineas(T2, N2), N1 < N2.

test(los_descartes_salen_en_los_dos_niveles, [nondet]) :-
    turno([bandido_torpe]),
    forall(member(Nivel, [resumido, detallado]),
           (   ordena(nivel(Nivel), _),
               pantalla(explicar, T),
               contiene(T, 'prioridad 1 (curarse):')
           )).

test(la_frase_general_de_la_ia_solo_sale_en_el_detallado, [nondet]) :-
    turno([moho_saltarin]),
    pantalla(explicar, T1),
    \+ contiene(T1, 'cola de Doña Mantecosa'),
    ordena(nivel(detallado), _),
    pantalla(explicar, T2),
    contiene(T2, 'cola de Doña Mantecosa').

test(una_frase_especifica_sale_en_los_dos, [nondet]) :-
    turno([bandido_torpe]),
    forall(member(Nivel, [resumido, detallado]),
           (   ordena(nivel(Nivel), _),
               pantalla(explicar, T),
               contiene(T, 'elige al más débil')
           )).

:- end_tests(la_decision_del_enemigo_por_niveles).
