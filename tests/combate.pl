% combate.pl (pruebas)
% T-19: los rasgos del heroe. El miedo de Baldomero (teme/2, ignora_miedo/1 y la regla
% puede_atacar/2), las reglas de fila de las que depende, y el rasgo hechizos_de_cocina
% de Pimentina (puede_habilidad/2). Tambien comprueba que el meta-interprete explica estas
% reglas igual que se ejecutan.
%
% Aun no existe el comando de combate: para probar las reglas se monta a mano un estado de
% combate (combatiente/2, fila/2, instancia/2, vida/2) escribiendo en estado desde la prueba.
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

% Monta un combate: los cuatro miembros contra una lista de tipos de enemigo (e(Tipo, 1), e(Tipo, 2)...).
% El estado se escribe a mano porque todavia no hay efecto para iniciar un combate.
combate_con(Tipos) :-
    nueva_partida,
    forall(estado:en_compania(Id), assertz(estado:combatiente(Id, jugador))),
    forall(nth1(N, Tipos, Tipo),
           (   E = e(Tipo, N),
               mundo:enemigo(Tipo, vida(V), _, _),
               mundo:fila_preferida(Tipo, F),
               assertz(estado:instancia(E, Tipo)),
               assertz(estado:vida(E, V)),
               assertz(estado:fila(E, F)),
               assertz(estado:combatiente(E, enemigo))
           )),
    assertz(estado:en_combate(1)).

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
             member(N, [1, 2, 3, 4]), nth1(N, [rata_quesera, bandido_torpe, moho_saltarin, gran_roquefort], T) ),
           once(combate:puede_atacar(A, e(T, N)))).

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
    ( combate:puede_atacar(baldomero, e(bandido_montado, 2)) -> true ; true ),
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
    retractall(estado:fila(e(rata_quesera, 2), _)),
    assertz(estado:fila(e(rata_quesera, 2), retaguardia)),
    combate:en_fila_alcanzable(baldomero, e(rata_quesera, 2)).

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
                        nth1(N, Tipos, T) ),
                      igual(x, combate:puede_atacar(A, e(T, N)))),
               aplicar_efecto(equipar(baldomero, venda_de_caballos)),
               forall(( member(A, [baldomero, pimentina]), nth1(N, Tipos, T) ),
                      igual(x, combate:puede_atacar(A, e(T, N))))
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
