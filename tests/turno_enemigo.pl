% turno_enemigo.pl (pruebas)
% T-33: explicar el turno de un enemigo (la demostracion central 3). Tras el turno de un enemigo,
% `explicar` cuenta POR QUE hizo eso (la prueba de la regla de la IA que gano, con su corte,
% guardada ANTES de aplicar los efectos) y POR QUE NO hizo otra cosa (las reglas de mayor
% prioridad que no se aplicaron, diagnosticadas con por_que_no en el momento de decidir). El arbol
% se pliega a lo esencial con plegar_lineas/3 y el narrador comenta con las frases X20.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/turno_enemigo -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/explicar').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

montado(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs).

% Un combate montado a mano contra Tipos y el turno de E ya resuelto.
turno(Tipos, E) :-
    Tipos = [Tipo|_],
    E = e(Tipo, 1),
    montado(Tipos),
    juego:turno_enemigo(E, _).

nombres_de(Descartes, Nombres) :-
    findall(N, member(descarte(_, N, _), Descartes), Nombres).

prioridades_de(Descartes, Ps) :-
    findall(P, member(descarte(P, _, _), Descartes), Ps).

descartes_de_la_decision(Ds) :-
    ordena(explicar, [vista(decision, _, _, Ds)]).

% ---------------------------------------------------------------------------

:- begin_tests(plegar_lineas).

arbol(['raiz', '   hijo a', '      nieto a1', '      nieto a2', '   hijo b', '      nieto b1']).

test(sin_lineas_no_hay_nada) :-
    plegar_lineas([], 1, []).

test(con_profundidad_grande_no_pliega_nada) :-
    arbol(A),
    plegar_lineas(A, 9, A).

test(profundidad_cero_deja_solo_las_raices) :-
    arbol(A),
    plegar_lineas(A, 0, ['raiz   [+5 nodos]']).

test(profundidad_uno_pliega_los_nietos) :-
    arbol(A),
    plegar_lineas(A, 1, ['raiz', '   hijo a   [+2 nodos]', '   hijo b   [+1 nodo]']).

test(un_solo_nodo_plegado_se_escribe_en_singular) :-
    plegar_lineas(['a', '   b', '      c'], 1, ['a', '   b   [+1 nodo]']).

test(los_nodos_sin_hijos_no_llevan_marca) :-
    plegar_lineas(['a', '   b', '   c'], 1, ['a', '   b', '   c']).

test(varias_raices_se_pliegan_cada_una) :-
    plegar_lineas(['a', '   a1', 'b', '   b1', '   b2'], 0, ['a   [+1 nodo]', 'b   [+2 nodos]']).

test(las_lineas_conservadas_van_en_el_mismo_orden) :-
    arbol(A),
    plegar_lineas(A, 2, A).

test(plegar_dos_veces_es_lo_mismo_que_una) :-
    arbol(A),
    plegar_lineas(A, 1, P1),
    plegar_lineas(P1, 1, P2),
    P1 == P2.

test(el_numero_de_lineas_nunca_crece) :-
    arbol(A),
    forall(between(0, 4, P),
           (   plegar_lineas(A, P, R), length(A, N), length(R, M), M =< N )).

test(con_una_prueba_real_el_resultado_es_mas_corto, [nondet]) :-
    montado([bandido_torpe]),
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    prueba_a_lineas(P, Ls),
    plegar_lineas(Ls, 1, Plegado),
    length(Ls, N), length(Plegado, M),
    M < N.

:- end_tests(plegar_lineas).

:- begin_tests(el_efecto_guardar_descartes).

test(guarda_lo_que_se_le_da, [setup(nueva_partida)]) :-
    aplicar_efecto(guardar_descartes(e(rata_quesera, 1), [descarte(1, curarse, x)])),
    estado:ultimos_descartes(e(rata_quesera, 1), [descarte(1, curarse, x)]).

test(el_siguiente_sustituye_al_anterior, [setup(nueva_partida)]) :-
    aplicar_efecto(guardar_descartes(a, [1])),
    aplicar_efecto(guardar_descartes(b, [2])),
    findall(E-D, estado:ultimos_descartes(E, D), [b-[2]]).

test(una_lista_vacia_tambien_se_guarda, [setup(nueva_partida)]) :-
    aplicar_efecto(guardar_descartes(a, [])),
    estado:ultimos_descartes(a, []).

test(lo_que_no_es_una_lista_no_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(guardar_descartes(a, no_lista)).

test(es_un_efecto_conocido) :-
    once(estado:efecto_conocido(guardar_descartes(_, _))).

test(una_partida_nueva_lo_borra, [setup(nueva_partida)]) :-
    aplicar_efecto(guardar_descartes(a, [1])),
    nueva_partida,
    \+ estado:ultimos_descartes(_, _).

:- end_tests(el_efecto_guardar_descartes).

:- begin_tests(los_descartes_de_cada_regla).

test(el_bandido_que_ataca_descarta_las_cuatro_primeras, [nondet]) :-
    turno([bandido_torpe], e(bandido_torpe, 1)),
    descartes_de_la_decision(Ds),
    prioridades_de(Ds, [1, 2, 3, 4]),
    nombres_de(Ds, [curarse, invocar_moho, robar_queso, embestir]).

test(la_rata_que_roba_descarta_dos, [nondet]) :-
    turno([rata_quesera], e(rata_quesera, 1)),
    descartes_de_la_decision(Ds),
    nombres_de(Ds, [curarse, invocar_moho]).

test(el_bandido_montado_que_embiste_descarta_tres, [nondet]) :-
    turno([bandido_montado], e(bandido_montado, 1)),
    descartes_de_la_decision(Ds),
    nombres_de(Ds, [curarse, invocar_moho, robar_queso]).

test(el_jefe_que_invoca_descarta_solo_curarse, [nondet]) :-
    turno([gran_roquefort], e(gran_roquefort, 1)),
    descartes_de_la_decision(Ds),
    nombres_de(Ds, [curarse]).

test(quien_se_cura_no_descarta_nada, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    aplicar_efecto(dano(e(bandido_torpe, 1), 9)),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    descartes_de_la_decision(Ds),
    Ds == [].

test(el_comodin_descarta_las_cinco_anteriores, [nondet]) :-
    montado([bandido_torpe]),
    retractall(estado:combatiente(_, jugador)),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    descartes_de_la_decision(Ds),
    prioridades_de(Ds, [1, 2, 3, 4, 5]),
    nombres_de(Ds, [curarse, invocar_moho, robar_queso, embestir, atacar]).

test(el_golpe_a_clotilde_no_descarta_nada, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(marcar(combate_de(gallina_noble))),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    descartes_de_la_decision(Ds),
    Ds == [].

test(cada_descarte_es_un_diagnostico_de_fallo, [nondet]) :-
    turno([bandido_torpe], e(bandido_torpe, 1)),
    descartes_de_la_decision(Ds),
    forall(member(descarte(_, _, D), Ds), D = fallo(_, _)).

test(ningun_descarte_se_podria_demostrar, [nondet]) :-
    turno([bandido_torpe], e(bandido_torpe, 1)),
    descartes_de_la_decision(Ds),
    forall(member(descarte(J, _, _), Ds),
           \+ ( combate:regla_ia(J, e(bandido_torpe, 1), _) )).

test(las_prioridades_van_en_orden_creciente, [nondet]) :-
    turno([rata_quesera], e(rata_quesera, 1)),
    descartes_de_la_decision(Ds),
    prioridades_de(Ds, Ps),
    msort(Ps, Ps).

test(el_diagnostico_de_curarse_dice_la_cuenta_del_treinta_por_ciento, [nondet]) :-
    turno([bandido_torpe], e(bandido_torpe, 1)),
    descartes_de_la_decision(Ds),
    memberchk(descarte(1, curarse, D), Ds),
    diag_detalle_a_lineas(D, Ls),
    once(( member(L, Ls), contiene(L, '12*100=<12*30 es falso') )).

test(cada_descarte_diagnostica_su_propia_regla, [nondet]) :-
    turno([bandido_torpe], e(bandido_torpe, 1)),
    descartes_de_la_decision(Ds),
    forall(member(descarte(J, _, D), Ds),
           (   nth1(J, [vida_baja, debe_invocar_moho, puede_robar_queso, puede_embestir], Cond),
               diag_detalle_a_lineas(D, Ls),
               once(( member(L, Ls), contiene(L, Cond) ))
           )).

test(los_descartes_se_calcularon_al_decidir_no_al_explicar, [nondet]) :-
    turno([bandido_torpe], E),
    E = e(bandido_torpe, 1),
    aplicar_efecto(dano(E, 9)),                          % ahora le queda 3 de 12: por debajo del 30 %
    pantalla(explicar, T),
    contiene(T, '12*100=<12*30 es falso'),
    \+ contiene(T, '3*100').

test(el_turno_de_un_enemigo_guarda_su_prueba_antes_de_los_efectos, [nondet]) :-
    montado([bandido_torpe]),
    vidas(Antes),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    vidas(Despues),
    Antes \== Despues,                                     % ha hecho daño
    estado:ultima_prueba(accion_enemigo(_), P),
    prueba_a_lineas(P, Ls),
    member(L, Ls), contiene(L, 'vida(tuerca, 22)'), !.

vidas(Vs) :-
    findall(Id-V, ( estado:combatiente(Id, jugador), estado:vida(Id, V) ), Vs).

:- end_tests(los_descartes_de_cada_regla).

:- begin_tests(la_pantalla_de_la_decision).

test(el_item_es_una_decision_con_su_enemigo_su_prueba_y_sus_descartes, [nondet]) :-
    turno([bandido_torpe], E),
    ordena(explicar, [vista(decision, E2, Prueba, Ds)]),
    E2 == E,
    Prueba = regla(accion_enemigo(_, _), 5, _),
    is_list(Ds).

test(dice_quien_decidio_y_la_prioridad, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    contiene(T, 'Por qué el Bandido Torpe hizo eso:'),
    contiene(T, 'Eligió la regla de prioridad 5 de 6 (el corte descartó las demás).').

test(muestra_la_regla_que_gano_con_su_corte, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    contiene(T, '[clausula 5 + corte]'),
    contiene(T, '[corte: se descartaron las clausulas siguientes]').

test(pliega_el_detalle_y_dice_cuantos_nodos, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    contiene(T, 'objetivo_mas_debil'),
    contiene(T, 'nodos]'),
    \+ contiene(T, 'bando_contrario').

test(la_decision_plegada_cabe_en_una_pantalla, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    atomic_list_concat(Ls, '\n', T),
    length(Ls, N),
    N =< 40.

test(enumera_las_reglas_que_no_se_aplicaron, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    contiene(T, 'Las reglas de más prioridad no se aplicaron:'),
    contiene(T, 'prioridad 1 (curarse):'),
    contiene(T, 'prioridad 2 (invocar_moho):'),
    contiene(T, 'prioridad 3 (robar_queso):'),
    contiene(T, 'prioridad 4 (embestir):'),
    \+ contiene(T, 'prioridad 5 (').

test(la_decision_de_curarse_no_enumera_reglas, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    aplicar_efecto(dano(e(bandido_torpe, 1), 9)),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    pantalla(explicar, T),
    contiene(T, 'prioridad 1 de 6'),
    \+ contiene(T, 'no se aplicaron').

test(el_comodin_se_cuenta_como_ultima_regla, [nondet]) :-
    montado([bandido_torpe]),
    retractall(estado:combatiente(_, jugador)),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    pantalla(explicar, T),
    contiene(T, 'Eligió la última regla (prioridad 6 de 6)'),
    contiene(T, 'prioridad 5 (atacar):').

test(la_escolta_dice_que_la_gallina_va_escoltada_y_no_enumera, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(marcar(combate_de(gallina_noble))),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    pantalla(explicar, T),
    contiene(T, 'Lady Clotilde va escoltada'),
    \+ contiene(T, 'no se aplicaron'),
    \+ contiene(T, 'regla de prioridad').

test(sin_ningun_enemigo_la_pantalla_normal_no_cambia, [setup(nueva_partida), nondet]) :-
    ordena(ir(aldea), _),
    ordena(explicar, [vista(prueba, ir(aldea), _)]).

test(tras_una_accion_del_jugador_explicar_cuenta_la_del_jugador, [nondet]) :-
    turno([bandido_torpe], _),
    cola_a([baldomero]),
    ordena(defender, _),
    ordena(explicar, [vista(prueba, defender(baldomero), _)]).

test(explicar_dos_veces_da_lo_mismo_y_no_cambia_el_estado, [nondet]) :-
    turno([bandido_torpe], _),
    foto_estado(A),
    pantalla(explicar, T1),
    pantalla(explicar, T2),
    foto_estado(B),
    T1 == T2,
    A =@= B.

cola_a(Ids) :-
    retractall(estado:cola_turnos(_)),
    assertz(estado:cola_turnos(Ids)).

test(la_pantalla_no_ensena_terminos_crudos, [nondet]) :-
    turno([bandido_torpe], _),
    pantalla(explicar, T),
    \+ contiene(T, 'vista('),
    \+ contiene(T, 'descarte('),
    \+ contiene(T, 'fallo(').

:- end_tests(la_pantalla_de_la_decision).

:- begin_tests(el_narrador_del_turno_enemigo).

comentario_de(Tipos, E, Texto) :-
    turno(Tipos, E),
    ordena(explicar, [vista(decision, _, Prueba, _)]),
    comentario_prueba(Prueba, ambos, 0, Texto).

test(el_bandido_torpe_elige_al_mas_debil, [nondet]) :-
    comentario_de([bandido_torpe], _, T),
    contiene(T, 'elige al más débil').

test(la_rata_roba, [nondet]) :-
    comentario_de([rata_quesera], _, T),
    contiene(T, 'roba queso').

test(el_caballo_embiste, [nondet]) :-
    comentario_de([bandido_montado], _, T),
    contiene(T, 'embiste primero').

test(el_jefe_llama_a_su_moho, [nondet]) :-
    comentario_de([gran_roquefort], _, T),
    contiene(T, 'llama a su moho').

test(quien_se_cura_habla_de_prioridad, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    aplicar_efecto(dano(e(bandido_torpe, 1), 9)),
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    ordena(explicar, [vista(decision, _, Prueba, _)]),
    comentario_prueba(Prueba, ambos, 0, T),
    contiene(T, 'Eso se llama prioridad').

test(la_frase_general_de_la_ia_solo_sale_en_el_nivel_detallado, [nondet]) :-
    comentario(accion_enemigo(e(moho_saltarin, 1), atacar(baldomero)), detallado, 0, T),
    contiene(T, 'cola de Doña Mantecosa'),
    \+ comentario(accion_enemigo(e(moho_saltarin, 1), atacar(baldomero)), resumido, 0, _).

test(la_escolta_tiene_su_frase, [nondet]) :-
    comentario(golpea_a_clotilde(e(bandido_torpe, 1)), ambos, 0, T),
    contiene(T, 'Lady Clotilde').

test(una_decision_con_frase_propia_no_cae_en_la_generica, [nondet]) :-
    comentario_de([bandido_torpe], _, T),
    \+ contiene(T, 'Todo conforme al reglamento').

:- end_tests(el_narrador_del_turno_enemigo).

:- begin_tests(en_el_juego_real).

% El bucle real: tras cada turno enemigo, `explicar` puede decir por que (si hubo turno enemigo).
juega(N) :-
    forall(between(1, N, _),
           (   estado:en_combate(_), \+ estado:fin_partida(_)
           ->  (   member(O, [bandido_torpe, rata_quesera]),
                   ordena(atacar(O), I), \+ I = [error(_)|_]
               ->  true
               ;   ordena(defender, _) ),
               explicar_ahora
           ;   true )).

explicar_ahora :-
    ordena(explicar, Items),
    (   Items = [vista(decision, E, P, Ds)]
    ->  E = e(_, _),
        P \== [],
        is_list(Ds),
        findall(J, member(descarte(J, _, _), Ds), Js),
        msort(Js, Js)
    ;   true
    ).

test(en_un_combate_entero_la_explicacion_siempre_es_coherente, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, rata_quesera], _),
    juega(60).

test(la_prioridad_dicha_coincide_con_los_descartes, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, bandido_montado, rata_quesera], _),
    forall(between(1, 40, _),
           (   estado:en_combate(_), \+ estado:fin_partida(_)
           ->  ordena(defender, _),
               (   ordena(explicar, [vista(decision, _, regla(accion_enemigo(_, _), N, _), Ds)])
               ->  findall(J, member(descarte(J, _, _), Ds), Js),
                   N1 is N - 1,
                   numlist(1, N1, Esperados),
                   (   N1 =:= 0 -> Js == [] ; Js == Esperados )
               ;   true )
           ;   true )).

test(la_partida_es_reproducible_tambien_en_lo_que_se_explica, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe], _),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    pantalla(explicar, T1),
    nueva_partida,
    comenzar_combate([bandido_torpe], _),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    pantalla(explicar, T2),
    T1 == T2.

:- end_tests(en_el_juego_real).
