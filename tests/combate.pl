% combate.pl (pruebas)
% T-19: los rasgos del heroe. El miedo de Baldomero (teme/2, ignora_miedo/1 y la regla
% puede_atacar/2), las reglas de fila de las que depende, y el rasgo hechizos_de_cocina
% de Pimentina (puede_habilidad/2). Tambien comprueba que el meta-interprete explica estas
% reglas igual que se ejecutan.
%
% T-20: la iniciativa, el orden de los turnos y los efectos que abren el combate y cada ronda
% (iniciar_combate, siguiente_ronda, siguiente_turno). Los combates de las pruebas se montan con
% el efecto real iniciar_combate. Aun no hay comandos de combate.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/combate -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/explicar').

% Monta un combate: los cuatro miembros contra una lista de tipos de enemigo (e(Tipo, 1), e(Tipo, 2)...,
% numerados por tipo), con el efecto real iniciar_combate.
combate_con(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]).

% Todas las soluciones de Plantilla con ejecucion directa y con solve/2, en el mismo orden.
igual(Plantilla, Meta) :-
    findall(Plantilla, Meta, Directo),
    findall(Plantilla, solve(Meta, _), ConSolve),
    Directo == ConSolve.

:- begin_tests(rasgo_teme_caballos).

test(baldomero_teme_a_los_caballos, [setup(nueva_partida), nondet]) :-
    compania:teme(baldomero, caballo).

test(solo_baldomero_tiene_miedo, [setup(nueva_partida)]) :-
    findall(Id, compania:teme(Id, _), Ids),
    Ids == [baldomero].

test(teme_solo_a_la_clase_caballo, [setup(nueva_partida)]) :-
    findall(C, compania:teme(baldomero, C), Cs),
    Cs == [caballo].

test(sin_la_venda_no_ignora_el_miedo, [setup(nueva_partida), fail]) :-
    compania:ignora_miedo(baldomero).

test(con_la_venda_ignora_el_miedo_y_deja_de_temer, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    compania:ignora_miedo(baldomero),
    \+ compania:teme(baldomero, _).

test(la_venda_solo_ayuda_a_quien_la_lleva, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(pimentina, venda_de_caballos)),
    compania:teme(baldomero, caballo),
    \+ compania:ignora_miedo(baldomero),
    compania:ignora_miedo(pimentina).

test(otro_objeto_no_vale_como_venda, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(equipar(baldomero, pocion)),
    compania:teme(baldomero, caballo).

test(equipar_dos_veces_no_duplica, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    findall(x, estado:equipado(baldomero, venda_de_caballos), L),
    length(L, 1).

:- end_tests(rasgo_teme_caballos).

:- begin_tests(puede_atacar).

test(baldomero_ataca_a_un_bandido_torpe, [nondet]) :-
    combate_con([bandido_torpe]),
    combate:puede_atacar(baldomero, e(bandido_torpe, 1)).

test(baldomero_no_ataca_a_un_caballo, [fail]) :-
    combate_con([bandido_montado]),
    combate:puede_atacar(baldomero, e(bandido_montado, 1)).

test(con_la_venda_baldomero_si_ataca_al_caballo, [nondet]) :-
    combate_con([bandido_montado]),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    combate:puede_atacar(baldomero, e(bandido_montado, 1)).

test(los_demas_no_temen_a_los_caballos, [nondet]) :-
    combate_con([bandido_montado]),
    forall(member(A, [pimentina, rufino, tuerca]),
           once(combate:puede_atacar(A, e(bandido_montado, 1)))).

test(cada_miembro_ataca_a_cada_enemigo_que_no_es_caballo, [nondet]) :-
    combate_con([rata_quesera, bandido_torpe, moho_saltarin, gran_roquefort]),
    forall(( member(A, [baldomero, pimentina, rufino, tuerca]),
             member(T, [rata_quesera, bandido_torpe, moho_saltarin, gran_roquefort]) ),
           once(combate:puede_atacar(A, e(T, 1)))).

test(un_enemigo_puede_atacar_a_baldomero, [nondet]) :-
    combate_con([bandido_montado]),
    combate:puede_atacar(e(bandido_montado, 1), baldomero).

test(no_se_ataca_al_propio_bando, [fail]) :-
    combate_con([bandido_torpe]),
    combate:puede_atacar(baldomero, pimentina).

test(un_atacante_muerto_no_ataca, [fail]) :-
    combate_con([bandido_torpe]),
    aplicar_efecto(dano(tuerca, 999)),
    combate:puede_atacar(tuerca, e(bandido_torpe, 1)).

test(no_se_ataca_a_un_enemigo_muerto, [fail]) :-
    combate_con([bandido_torpe]),
    retractall(estado:vida(e(bandido_torpe, 1), _)),
    assertz(estado:vida(e(bandido_torpe, 1), 0)),
    combate:puede_atacar(baldomero, e(bandido_torpe, 1)).

test(un_atacante_aturdido_pierde_el_turno, [fail]) :-
    combate_con([bandido_torpe]),
    assertz(estado:alterado(baldomero, aturdido, 1)),
    combate:puede_atacar(baldomero, e(bandido_torpe, 1)).

test(un_estado_distinto_de_aturdido_no_impide_atacar, [nondet]) :-
    combate_con([bandido_torpe]),
    assertz(estado:alterado(baldomero, defendiendo, 1)),
    combate:puede_atacar(baldomero, e(bandido_torpe, 1)).

test(sin_combate_no_hay_ataques, [setup(nueva_partida), fail]) :-
    combate:puede_atacar(baldomero, e(bandido_torpe, 1)).

test(puede_atacar_no_modifica_el_estado, [nondet]) :-
    combate_con([bandido_torpe, bandido_montado]),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Antes),
    ( combate:puede_atacar(baldomero, e(bandido_torpe, 1)) -> true ; true ),
    ( combate:puede_atacar(baldomero, e(bandido_montado, 1)) -> true ; true ),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Despues),
    Antes == Despues.

:- end_tests(puede_atacar).

:- begin_tests(reglas_de_fila).

test(el_frente_siempre_es_alcanzable, [nondet]) :-
    combate_con([bandido_torpe]),
    combate:en_fila_alcanzable(e(bandido_torpe, 1), baldomero),
    combate:en_fila_alcanzable(baldomero, e(bandido_torpe, 1)).

test(la_retaguardia_esta_protegida_mientras_el_frente_resista, [fail]) :-
    combate_con([bandido_torpe]),
    combate:en_fila_alcanzable(e(bandido_torpe, 1), pimentina).

test(cuando_cae_el_frente_la_retaguardia_es_alcanzable, [nondet]) :-
    combate_con([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 999)),
    aplicar_efecto(dano(tuerca, 999)),
    combate:en_fila_alcanzable(e(bandido_torpe, 1), pimentina).

test(basta_un_vivo_en_el_frente_para_proteger, [fail]) :-
    combate_con([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 999)),               % cae uno, pero Tuerca sigue en primera fila
    combate:en_fila_alcanzable(e(bandido_torpe, 1), rufino).

test(un_atacante_a_distancia_alcanza_la_retaguardia, [nondet]) :-
    combate_con([bandido_torpe]),
    retractall(estado:fila(e(bandido_torpe, 1), _)),
    assertz(estado:fila(e(bandido_torpe, 1), retaguardia)),
    combate:en_fila_alcanzable(pimentina, e(bandido_torpe, 1)).

test(un_atacante_cuerpo_a_cuerpo_no_alcanza_la_retaguardia_con_frente_vivo, [fail]) :-
    combate_con([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)),
    combate:en_fila_alcanzable(baldomero, e(rata_quesera, 1)).

test(el_bando_contrario_es_necesario, [fail]) :-
    combate_con([bandido_torpe]),
    combate:en_fila_alcanzable(baldomero, tuerca).

test(la_clase_y_el_tipo_de_una_instancia, [setup(nueva_partida)]) :-
    combate:tipo_de(e(bandido_montado, 3), bandido_montado),
    combate:tipo_de(baldomero, baldomero),
    combate:clase_de(e(bandido_montado, 3), caballo),
    combate:clase_de(bandido_torpe, humano).

:- end_tests(reglas_de_fila).

:- begin_tests(rasgo_hechizos_de_cocina).

test(con_queso_pimentina_puede_lanzar_su_hechizo, [setup(nueva_partida)]) :-
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(sin_queso_no_hay_magia, [setup(nueva_partida), fail]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(un_solo_queso_basta, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 11)),
    economia:queso_total(1),
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(sirve_cualquier_tipo_de_queso, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    aplicar_efecto(ganar_queso(brie, 12, 1)),          % un brie rancio tambien alimenta la magia
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(solo_pimentina_tiene_este_rasgo, [setup(nueva_partida), fail]) :-
    combate:puede_habilidad(baldomero, carga_heroica).

test(pimentina_no_lanza_la_habilidad_de_otro, [setup(nueva_partida), fail]) :-
    combate:puede_habilidad(pimentina, balada_inspiradora).

test(una_pimentina_caida_no_lanza_hechizos, [setup(nueva_partida), fail]) :-
    aplicar_efecto(dano(pimentina, 999)),
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(una_pimentina_aturdida_no_lanza_hechizos, [setup(nueva_partida), fail]) :-
    assertz(estado:alterado(pimentina, aturdido, 1)),
    combate:puede_habilidad(pimentina, fondue_flamigera).

test(cada_miembro_tiene_una_habilidad, [setup(nueva_partida)]) :-
    forall(estado:en_compania(Id),
           (   findall(H, mundo:habilidad_de(Id, H), Hs), length(Hs, 1) )).

test(el_coste_de_la_fondue_es_un_queso) :-
    mundo:coste_queso(fondue_flamigera, 1).

:- end_tests(rasgo_hechizos_de_cocina).

:- begin_tests(explicar_los_rasgos).

test(solve_da_lo_mismo_que_ejecutar_puede_atacar) :-
    forall(member(Tipos, [[bandido_torpe, bandido_montado], [rata_quesera], [gran_roquefort, moho_saltarin]]),
           (   combate_con(Tipos),
               forall(( member(A, [baldomero, pimentina, rufino, tuerca]),
                        member(T, Tipos) ),
                      igual(x, combate:puede_atacar(A, e(T, 1)))),
               aplicar_efecto(equipar(baldomero, venda_de_caballos)),
               forall(( member(A, [baldomero, pimentina]), member(T, Tipos) ),
                      igual(x, combate:puede_atacar(A, e(T, 1))))
           )).

test(solve_da_lo_mismo_que_ejecutar_el_miedo_y_la_magia, [setup(nueva_partida)]) :-
    igual(C, compania:teme(baldomero, C)),
    igual(x, compania:ignora_miedo(baldomero)),
    igual(x, combate:puede_habilidad(pimentina, fondue_flamigera)),
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    igual(x, combate:puede_habilidad(pimentina, fondue_flamigera)),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    igual(C, compania:teme(baldomero, C)),
    igual(x, compania:ignora_miedo(baldomero)).

test(la_prueba_de_atacar_muestra_el_miedo_como_negacion, [nondet]) :-
    % Es el arbol de la primera demostracion: el miedo aparece como una negacion que se cumple.
    combate_con([bandido_torpe]),
    solve(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), P),
    explicar:prueba_a_lineas(P, Lineas),
    memberchk('[ok] puede_atacar(baldomero, e(bandido_torpe, 1))   [clausula 1]', Lineas),
    memberchk('   [ok] en_fila_alcanzable(baldomero, e(bandido_torpe, 1))   [clausula 1]', Lineas),
    memberchk('   [ok] \\+ aturdido(baldomero)   [no demostrable]', Lineas),
    memberchk('   [ok] \\+ (teme(baldomero, A), clase_de(e(bandido_torpe, 1), A))   [no demostrable]', Lineas).
test(el_arbol_dice_por_que_baldomero_puede_atacar_con_la_venda, [nondet]) :-
    combate_con([bandido_montado]),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    solve(combate:puede_atacar(baldomero, e(bandido_montado, 1)), P),
    explicar:prueba_a_lineas(P, Lineas),
    forall(member(L, Lineas), ( atom_codes(L, Cs), forall(member(C, Cs), C < 128) )).

test(sin_la_venda_no_hay_prueba_de_que_baldomero_ataque_al_caballo, [fail]) :-
    combate_con([bandido_montado]),
    solve(combate:puede_atacar(baldomero, e(bandido_montado, 1)), _).

:- end_tests(explicar_los_rasgos).

% ===========================================================================
% T-20: estado de combate, iniciativa y orden de turnos
% ===========================================================================

% Deja a un miembro con la moral M (parte de 6 al empezar la partida).
moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

% Una "foto" de todos los hechos dinamicos, para ver que algo no toca el estado.
foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

ordenada_descendente([]).
ordenada_descendente([_]).
ordenada_descendente([A, B|Resto]) :- A >= B, ordenada_descendente([B|Resto]).

:- begin_tests(numerar_grupo).

test(un_solo_enemigo) :-
    mundo:numerar_grupo([bandido_torpe], Ids),
    Ids == [e(bandido_torpe, 1)].

test(los_repetidos_se_numeran_por_tipo) :-
    mundo:numerar_grupo([rata_quesera, rata_quesera, rata_quesera], Ids),
    Ids == [e(rata_quesera, 1), e(rata_quesera, 2), e(rata_quesera, 3)].

test(cada_tipo_lleva_su_propia_cuenta) :-
    mundo:numerar_grupo([rata_quesera, bandido_torpe, rata_quesera, bandido_torpe, rata_quesera], Ids),
    Ids == [e(rata_quesera, 1), e(bandido_torpe, 1), e(rata_quesera, 2), e(bandido_torpe, 2), e(rata_quesera, 3)].

test(un_grupo_vacio_da_una_lista_vacia) :-
    mundo:numerar_grupo([], Ids),
    Ids == [].

:- end_tests(numerar_grupo).

:- begin_tests(nivel_de_moral).

test(las_fronteras_de_los_niveles, [setup(nueva_partida)]) :-
    forall(member(M-Nivel, [0-critica, 1-critica, 2-baja, 3-baja, 4-normal, 7-normal, 8-alta, 10-alta]),
           (   moral_a(rufino, M),
               once(compania:nivel_moral(rufino, N)),
               N == Nivel
           )).

test(el_modificador_de_cada_nivel, [setup(nueva_partida)]) :-
    forall(member(M-Mod, [0-(-2), 1-(-2), 2-(-1), 3-(-1), 4-0, 7-0, 8-1, 10-1]),
           (   moral_a(rufino, M),
               once(compania:modificador_moral(rufino, X)),
               X == Mod
           )).

test(cada_moral_tiene_exactamente_un_nivel, [setup(nueva_partida)]) :-
    forall(between(0, 10, M),
           (   moral_a(rufino, M),
               findall(N, compania:nivel_moral(rufino, N), Ns),
               length(Ns, 1)
           )).

test(la_moral_inicial_es_normal, [setup(nueva_partida), nondet]) :-
    compania:nivel_moral(baldomero, normal),
    compania:modificador_moral(baldomero, 0).

test(un_enemigo_no_tiene_moral, [setup(nueva_partida), fail]) :-
    compania:modificador_moral(e(rata_quesera, 1), _).

:- end_tests(nivel_de_moral).

:- begin_tests(iniciativa).

test(la_iniciativa_de_los_miembros, [setup(nueva_partida)]) :-
    forall(member(Id-Esperada, [baldomero-18, pimentina-15, rufino-12, tuerca-15]),
           (   once(combate:iniciativa(Id, I)),
               I == Esperada
           )).

test(la_iniciativa_de_los_enemigos, [setup(nueva_partida)]) :-
    forall(member(Tipo-Esperada, [rata_quesera-14, bandido_torpe-13, moho_saltarin-14, bandido_montado-14, gran_roquefort-17]),
           (   once(combate:iniciativa(e(Tipo, 1), I)),
               I == Esperada
           )).

test(la_iniciativa_es_base_mas_ataque_menos_defensa, [setup(nueva_partida)]) :-
    mundo:parametro(base_iniciativa, B),
    forall(member(Id, [baldomero, pimentina, rufino, tuerca]),
           (   once(combate:ataque_base(Id, A)),
               once(combate:defensa_base(Id, D)),
               once(combate:iniciativa(Id, I)),
               I =:= B + A - D
           )).

test(una_moral_alta_suma_uno, [setup(nueva_partida)]) :-
    moral_a(tuerca, 9),
    once(combate:iniciativa(tuerca, I)),
    I == 16.

test(una_moral_baja_resta_uno, [setup(nueva_partida)]) :-
    moral_a(tuerca, 3),
    once(combate:iniciativa(tuerca, I)),
    I == 14.

test(una_moral_critica_resta_dos, [setup(nueva_partida)]) :-
    moral_a(tuerca, 1),
    once(combate:iniciativa(tuerca, I)),
    I == 13.

test(la_moral_no_cuenta_en_los_enemigos, [setup(nueva_partida)]) :-
    combate_con([rata_quesera]),
    once(combate:bono_iniciativa(e(rata_quesera, 1), M)),
    M == 0.

test(dos_instancias_del_mismo_tipo_empatan) :-
    combate_con([rata_quesera, rata_quesera]),
    once(combate:iniciativa(e(rata_quesera, 1), I1)),
    once(combate:iniciativa(e(rata_quesera, 2), I2)),
    I1 == I2.

test(quien_no_existe_no_tiene_iniciativa, [setup(nueva_partida), fail]) :-
    combate:iniciativa(fantasma, _).

:- end_tests(iniciativa).

:- begin_tests(puede_actuar).

test(un_miembro_vivo_y_con_moral_puede_actuar, [setup(nueva_partida), nondet]) :-
    combate:puede_actuar(baldomero).

test(un_miembro_caido_no_actua, [setup(nueva_partida), fail]) :-
    aplicar_efecto(dano(baldomero, 99)),
    combate:puede_actuar(baldomero).

test(un_huelguista_no_actua, [setup(nueva_partida), fail]) :-
    moral_a(rufino, 2),
    combate:puede_actuar(rufino).

test(con_la_moral_justo_encima_de_la_huelga_si_actua, [setup(nueva_partida), nondet]) :-
    moral_a(rufino, 3),
    combate:puede_actuar(rufino).

test(un_enemigo_vivo_siempre_puede_actuar, [nondet]) :-
    combate_con([bandido_torpe]),
    combate:puede_actuar(e(bandido_torpe, 1)).

test(un_enemigo_caido_no_actua, [fail]) :-
    combate_con([bandido_torpe]),
    aplicar_efecto(dano(e(bandido_torpe, 1), 99)),
    combate:puede_actuar(e(bandido_torpe, 1)).

:- end_tests(puede_actuar).

:- begin_tests(orden_de_turnos).

test(el_orden_de_cuatro_miembros_contra_tres_enemigos) :-
    combate_con([rata_quesera, rata_quesera, bandido_torpe]),
    combate:orden_turnos(Ids),
    Ids == [baldomero, pimentina, tuerca, e(rata_quesera, 1), e(rata_quesera, 2), e(bandido_torpe, 1), rufino].

test(a_igual_iniciativa_el_jugador_actua_primero, [nondet]) :-
    combate_con([rata_quesera]),
    moral_a(tuerca, 3),                              % tuerca: 15 - 1 = 14, igual que la rata
    combate:orden_turnos(Ids),
    nth0(PosT, Ids, tuerca),
    nth0(PosR, Ids, e(rata_quesera, 1)),
    PosT < PosR.

test(entre_miembros_iguales_manda_el_orden_de_los_ids, [nondet]) :-
    combate_con([bandido_torpe]),
    combate:orden_turnos(Ids),
    nth0(PosP, Ids, pimentina),                      % pimentina y tuerca empatan a 15
    nth0(PosT, Ids, tuerca),
    PosP < PosT.

test(el_orden_es_siempre_el_mismo) :-
    combate_con([bandido_montado, rata_quesera, moho_saltarin]),
    combate:orden_turnos(A),
    combate:orden_turnos(B),
    A == B.

test(el_orden_es_de_mayor_a_menor_iniciativa) :-
    forall(member(Tipos, [[rata_quesera], [gran_roquefort, moho_saltarin], [bandido_torpe, bandido_montado, rata_quesera]]),
           (   combate_con(Tipos),
               combate:orden_turnos(Ids),
               findall(I, ( member(Id, Ids), once(combate:iniciativa(Id, I)) ), Is),
               ordenada_descendente(Is)
           )).

test(el_orden_incluye_a_todos_los_que_pueden_actuar) :-
    combate_con([rata_quesera, bandido_torpe]),
    combate:orden_turnos(Ids),
    findall(Id, ( estado:combatiente(Id, _), combate:puede_actuar(Id) ), Actuan),
    msort(Ids, A),
    msort(Actuan, B),
    A == B,
    length(Ids, 6).

test(un_huelguista_no_entra_en_el_orden) :-
    combate_con([rata_quesera]),
    moral_a(rufino, 2),
    combate:orden_turnos(Ids),
    \+ memberchk(rufino, Ids),
    length(Ids, 4).

test(un_caido_no_entra_en_el_orden, [nondet]) :-
    combate_con([rata_quesera, rata_quesera]),
    aplicar_efecto(dano(e(rata_quesera, 1), 99)),
    aplicar_efecto(dano(baldomero, 99)),
    combate:orden_turnos(Ids),
    \+ memberchk(e(rata_quesera, 1), Ids),
    \+ memberchk(baldomero, Ids),
    length(Ids, 4).

test(orden_turnos_no_modifica_el_estado) :-
    combate_con([bandido_torpe, rata_quesera]),
    foto_estado(Antes),
    combate:orden_turnos(_),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(orden_de_turnos).

:- begin_tests(efectos_inicio).

test(el_efecto_de_inicio_es_iniciar_combate) :-
    nueva_partida,
    combate:efectos_inicio([rata_quesera, bandido_torpe], Efs),
    Efs == [iniciar_combate([rata_quesera, bandido_torpe])].

test(efectos_inicio_no_modifica_el_estado) :-
    nueva_partida,
    foto_estado(Antes),
    combate:efectos_inicio([rata_quesera], _),
    foto_estado(Despues),
    Antes == Despues.

test(no_se_empieza_un_combate_dentro_de_otro, [fail]) :-
    combate_con([rata_quesera]),
    combate:efectos_inicio([bandido_torpe], _).

test(un_grupo_vacio_no_es_un_combate, [setup(nueva_partida), fail]) :-
    combate:efectos_inicio([], _).

test(un_tipo_desconocido_no_es_un_combate, [setup(nueva_partida), fail]) :-
    combate:efectos_inicio([rata_quesera, dragon], _).

test(un_grupo_a_medias_no_es_un_combate, [setup(nueva_partida), fail]) :-
    combate:efectos_inicio([rata_quesera|_], _).

test(un_miembro_no_es_un_enemigo, [setup(nueva_partida), fail]) :-
    combate:efectos_inicio([baldomero], _).

:- end_tests(efectos_inicio).

:- begin_tests(iniciar_combate).

test(los_miembros_pasan_al_bando_jugador) :-
    combate_con([rata_quesera]),
    findall(Id, estado:combatiente(Id, jugador), Ids),
    msort(Ids, S),
    S == [baldomero, pimentina, rufino, tuerca].

test(cada_enemigo_nace_como_instancia_con_su_vida_y_su_fila, [nondet]) :-
    combate_con([bandido_torpe, rata_quesera, rata_quesera]),
    estado:instancia(e(bandido_torpe, 1), bandido_torpe),
    estado:vida(e(bandido_torpe, 1), 12),
    estado:fila(e(bandido_torpe, 1), frente),
    estado:instancia(e(rata_quesera, 2), rata_quesera),
    estado:vida(e(rata_quesera, 2), 8),
    findall(Id, estado:combatiente(Id, enemigo), Ids),
    length(Ids, 3).

test(el_combate_empieza_en_la_ronda_cero_con_la_cola_vacia) :-
    combate_con([rata_quesera]),
    estado:en_combate(R),
    estado:cola_turnos(C),
    R == 0,
    C == [].

test(con_un_combate_la_fase_es_combate, [nondet]) :-
    combate_con([rata_quesera]),
    estado:fase(combate).

test(los_miembros_conservan_vida_moral_y_fila) :-
    nueva_partida,
    foto_estado(Antes),
    aplicar_efectos([iniciar_combate([rata_quesera])]),
    foto_estado(Despues),
    forall(member(H, Antes), memberchk(H, Despues)).

test(no_se_puede_iniciar_otro_combate_encima, [fail]) :-
    combate_con([rata_quesera]),
    aplicar_efecto(iniciar_combate([bandido_torpe])).

test(un_grupo_vacio_no_inicia_nada, [fail]) :-
    nueva_partida,
    aplicar_efecto(iniciar_combate([])).

test(un_tipo_desconocido_falla_sin_tocar_el_estado) :-
    nueva_partida,
    foto_estado(Antes),
    \+ aplicar_efecto(iniciar_combate([rata_quesera, dragon])),
    foto_estado(Despues),
    Antes == Despues.

test(un_grupo_con_variables_falla_sin_tocar_el_estado) :-
    nueva_partida,
    foto_estado(Antes),
    \+ aplicar_efecto(iniciar_combate([rata_quesera|_])),
    foto_estado(Despues),
    Antes == Despues.

test(una_transaccion_deshace_el_inicio_si_algo_falla) :-
    nueva_partida,
    foto_estado(Antes),
    \+ con_transaccion(( aplicar_efectos([iniciar_combate([rata_quesera])]), fail )),
    foto_estado(Despues),
    Antes == Despues.

test(nueva_partida_borra_el_combate) :-
    combate_con([rata_quesera, bandido_torpe]),
    nueva_partida,
    \+ estado:en_combate(_),
    \+ estado:instancia(_, _),
    \+ estado:cola_turnos(_),
    \+ estado:combatiente(_, _).

test(un_enemigo_herido_no_se_cura_por_encima_de_su_maximo) :-
    combate_con([rata_quesera]),
    aplicar_efecto(dano(e(rata_quesera, 1), 3)),
    aplicar_efecto(curar(e(rata_quesera, 1), 99)),
    estado:vida(e(rata_quesera, 1), V),
    V == 8.

:- end_tests(iniciar_combate).

:- begin_tests(rondas_y_turnos).

test(efectos_ronda_abre_la_primera_ronda_con_el_orden) :-
    combate_con([rata_quesera, bandido_torpe]),
    combate:efectos_ronda(Efs),
    combate:orden_turnos(Orden),
    Efs == [siguiente_ronda(Orden)].

test(efectos_ronda_no_modifica_el_estado) :-
    combate_con([rata_quesera]),
    foto_estado(Antes),
    combate:efectos_ronda(_),
    foto_estado(Despues),
    Antes == Despues.

test(la_primera_ronda_llena_la_cola) :-
    combate_con([rata_quesera, bandido_torpe]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs),
    estado:en_combate(R),
    estado:cola_turnos(C),
    R == 1,
    combate:orden_turnos(Orden),
    C == Orden.

test(sin_combate_no_hay_ronda, [setup(nueva_partida), fail]) :-
    combate:efectos_ronda(_).

test(con_gente_en_la_cola_no_empieza_otra_ronda, [fail]) :-
    combate_con([rata_quesera]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs),
    combate:efectos_ronda(_).

test(siguiente_turno_quita_al_primero_de_la_cola) :-
    combate_con([rata_quesera]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs),
    estado:cola_turnos([Primero|Resto]),
    aplicar_efecto(siguiente_turno),
    estado:cola_turnos(Nueva),
    Nueva == Resto,
    Primero == baldomero.

test(se_gasta_la_cola_entera_y_se_puede_empezar_otra_ronda) :-
    combate_con([rata_quesera]),
    combate:efectos_ronda(E1),
    aplicar_efectos(E1),
    estado:cola_turnos(C),
    forall(member(_, C), aplicar_efecto(siguiente_turno)),
    estado:cola_turnos(Vacia),
    Vacia == [],
    combate:efectos_ronda(E2),
    aplicar_efectos(E2),
    estado:en_combate(R),
    R == 2.

test(con_la_cola_vacia_no_hay_siguiente_turno, [fail]) :-
    combate_con([rata_quesera]),
    aplicar_efecto(siguiente_turno).

test(fuera_de_combate_no_hay_siguiente_ronda, [setup(nueva_partida), fail]) :-
    aplicar_efecto(siguiente_ronda([baldomero])).

test(la_cola_de_una_ronda_tiene_que_ser_una_lista, [fail]) :-
    combate_con([rata_quesera]),
    aplicar_efecto(siguiente_ronda(baldomero)).

test(en_la_ronda_siguiente_no_cuenta_quien_ha_caido, [nondet]) :-
    combate_con([rata_quesera, rata_quesera]),
    combate:efectos_ronda(E1),
    aplicar_efectos(E1),
    estado:cola_turnos(C1),
    forall(member(_, C1), aplicar_efecto(siguiente_turno)),
    aplicar_efecto(dano(e(rata_quesera, 1), 99)),
    aplicar_efecto(dano(tuerca, 99)),
    combate:efectos_ronda(E2),
    aplicar_efectos(E2),
    estado:cola_turnos(C2),
    \+ memberchk(e(rata_quesera, 1), C2),
    \+ memberchk(tuerca, C2),
    length(C2, 4).

:- end_tests(rondas_y_turnos).

:- begin_tests(explicar_el_orden).

test(solve_da_lo_mismo_que_ejecutar_orden_turnos) :-
    forall(member(Tipos, [[rata_quesera], [bandido_torpe, bandido_montado, rata_quesera], [gran_roquefort]]),
           (   combate_con(Tipos),
               igual(Ids, combate:orden_turnos(Ids)),
               moral_a(tuerca, 1),
               igual(Ids, combate:orden_turnos(Ids))
           )).

test(solve_da_lo_mismo_que_ejecutar_la_iniciativa) :-
    combate_con([rata_quesera, bandido_montado]),
    forall(member(Id, [baldomero, pimentina, rufino, tuerca, e(rata_quesera, 1), e(bandido_montado, 1)]),
           igual(I, combate:iniciativa(Id, I))).

test(solve_da_lo_mismo_que_ejecutar_los_efectos) :-
    combate_con([rata_quesera]),
    igual(Efs, combate:efectos_ronda(Efs)),
    nueva_partida,
    igual(Efs, combate:efectos_inicio([rata_quesera, bandido_torpe], Efs)).

test(la_prueba_de_la_iniciativa_muestra_la_cuenta, [nondet]) :-
    nueva_partida,
    solve(combate:iniciativa(baldomero, _), P),
    explicar:prueba_a_lineas(P, Lineas),
    memberchk('[ok] iniciativa(baldomero, 18)   [clausula 1]', Lineas),
    memberchk('   [ok] ataque_base(baldomero, 11)   [clausula 1]', Lineas),
    memberchk('   [ok] defensa_base(baldomero, 3)   [clausula 1]', Lineas),
    memberchk('   [ok] bono_iniciativa(baldomero, 0)   [clausula 1]', Lineas),
    memberchk('   [ok] parametro(base_iniciativa, 10)   [hecho]', Lineas),
    memberchk('   [ok] 18 is 10+11-3+0   [builtin]', Lineas).

test(la_prueba_del_orden_cuenta_los_que_actuan, [nondet]) :-
    combate_con([rata_quesera, bandido_torpe]),
    solve(combate:orden_turnos(_), P),
    explicar:prueba_a_lineas(P, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'findall: 6 solucion(es)') )).

:- end_tests(explicar_el_orden).
