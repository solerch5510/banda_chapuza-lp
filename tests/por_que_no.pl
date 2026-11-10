% por_que_no.pl (pruebas)
% T-32: por_que_no, el segundo meta-interprete. Explica por que una meta NO tiene solucion:
% recorre las clausulas del predicado, busca el primer subobjetivo que falla y, si es una
% negacion (\+ X), da la prueba de X. Se prueba (1) con un modulo de juguete que tiene un
% predicado por cada forma de diagnostico, (2) con las reglas reales del juego (las dos
% demostraciones centrales: el miedo de Baldomero y la gallina noble), (3) que el diagnostico
% real produce las mismas claves del narrador que los diagnosticos escritos a mano de T-29, y
% (4) el comando por_que_no(Accion) y su pantalla.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/por_que_no -g "run_tests,halt" -t "halt(1)"

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

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

lineas(Diag, Ls) :- diag_a_lineas(Diag, Ls).

% Una linea de las del diagnostico contiene el texto.
alguna_linea(Ls, Texto) :- member(L, Ls), contiene(L, Texto), !.

combate_con(Tipos) :-
    nueva_partida,
    comenzar_combate(Tipos, _).

% Un enemigo en la retaguardia con el frente aun en pie: a Tuerca (cuerpo a cuerpo) no le alcanza.
retaguardia_protegida :-
    combate_con([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)).

moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

% ---------------------------------------------------------------------------

:- begin_tests(las_formas_del_diagnostico).

test(una_meta_cierta_no_tiene_diagnostico, [fail]) :-
    por_que_no(toy_diag:r_ok(1), _).

test(un_hecho_que_no_existe_es_sin_clausula) :-
    por_que_no(toy_diag:a(9), sin_clausula(a(9))).

test(un_dinamico_sin_clausulas_es_sin_clausula_tambien) :-
    por_que_no(toy_diag:hecho_d(1), sin_clausula(hecho_d(1))).

test(un_predefinido_falso_con_su_prefijo, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1),
               fallo(r_builtin(1), [cl(1, [hecho(a(1))], punto(1 > 5, builtin_falso(1 > 5)))])).

test(con_la_meta_sin_ligar_se_explica_la_primera_solucion, [nondet]) :-
    por_que_no(toy_diag:r_builtin(X),
               fallo(_, [cl(1, [hecho(a(1))], punto(1 > 5, builtin_falso(1 > 5)))])),
    var(X).

test(la_negacion_viola_da_la_prueba_del_hecho_que_la_impide, [nondet]) :-
    por_que_no(toy_diag:r_neg(1),
               fallo(_, [cl(1, [hecho(a(1))], punto(\+ tiene(x), neg_viola(tiene(x), hecho(tiene(x)))))])).

test(una_conjuncion_cuyo_segundo_falla_es_tras, [nondet]) :-
    por_que_no((toy_diag:a(1), toy_diag:a(9)), tras(hecho(a(1)), sin_clausula(a(9)))).

test(una_conjuncion_cuyo_primero_falla_es_el_diagnostico_del_primero, [nondet]) :-
    por_que_no((toy_diag:a(9), toy_diag:a(1)), sin_clausula(a(9))).

test(una_negacion_de_algo_cierto_es_neg_viola, [nondet]) :-
    por_que_no(\+ toy_diag:tiene(x), neg_viola(_, hecho(tiene(x)))).

test(las_dos_clausulas_se_listan_la_mas_cercana_primero, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), fallo(_, [cl(2, [hecho(a(1))], _), cl(1, [], _)])).

test(una_disyuncion_sin_condicion_falla_por_las_dos_ramas, [nondet]) :-
    por_que_no(toy_diag:r_disy(1),
               fallo(_, [cl(1, [], punto(_, ninguna(tras(hecho(a(1)), builtin_falso(_)), sin_clausula(hecho_d(1)))))])).

test(si_la_condicion_es_cierta_falla_la_rama_entonces, [nondet]) :-
    por_que_no(toy_diag:r_si(1),
               fallo(_, [cl(1, [], punto(_, tras(hecho(a(1)), builtin_falso(1 > 5))))])).

test(si_la_condicion_es_falsa_falla_la_rama_si_no, [nondet]) :-
    por_que_no(toy_diag:r_sino(1),
               fallo(_, [cl(1, [], punto(_, sin_clausula(hecho_d(1))))])).

test(un_si_entonces_sin_sino_tambien_se_diagnostica, [nondet]) :-
    por_que_no(toy_diag:r_solo_si(1),
               fallo(_, [cl(1, [], punto(_, tras(hecho(a(1)), builtin_falso(1 > 5))))])).

test(un_findall_deja_su_prueba_en_las_previas, [nondet]) :-
    por_que_no(toy_diag:r_findall, fallo(_, [cl(1, [agregado(_, 2, _)], punto(length([1, 2], 5), builtin_falso(_)))])).

test(un_findall_cuya_lista_no_coincide_es_un_predefinido_falso, [nondet]) :-
    por_que_no(toy_diag:r_findall_ligado, fallo(_, [cl(1, [], punto(findall(_, _, [1]), builtin_falso(findall(_, _, [1]))))])).

test(un_forall_que_falla_es_un_predefinido_falso, [nondet]) :-
    por_que_no(toy_diag:r_forall, fallo(_, [cl(1, [], punto(forall(_, _), builtin_falso(forall(_, _))))])).

test(el_corte_no_cambia_el_diagnostico, [nondet]) :-
    por_que_no(toy_diag:r_corte(1), fallo(_, [cl(1, [hecho(a(1))], punto(1 > 5, builtin_falso(_)))])).

test(un_fallo_anidado_baja_hasta_la_causa, [nondet]) :-
    por_que_no(toy_diag:r_anidada(1),
               fallo(_, [cl(1, [hecho(tiene(x))], punto(r_builtin(1), fallo(r_builtin(1), _)))])).

test(un_predicado_de_libreria_es_una_hoja, [nondet]) :-
    por_que_no(toy_diag:r_lib(abc),
               fallo(_, [cl(1, [], punto(atom_length(abc, 99), builtin_falso(atom_length(abc, 99))))])).

test(sin_profundidad_es_limite) :-
    explicar:diag(toy_diag:a(1), user, 0, limite(_)).

test(por_que_no_no_cambia_el_estado, [setup(nueva_partida), nondet]) :-
    foto_estado(Antes),
    por_que_no(compania:puede_viajar(castillo), _),
    por_que_no(economia:puede_pagar_sueldos, _),
    foto_estado(Despues),
    Antes =@= Despues.

:- end_tests(las_formas_del_diagnostico).

:- begin_tests(el_texto_del_diagnostico).

test(la_cabecera_dice_la_regla_y_la_clausula, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1), D),
    lineas(D, [Cab|_]),
    Cab == '[no] r_builtin(1)   [clausula 1]'.

test(los_subobjetivos_que_se_cumplen_salen_como_ok, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1), D),
    lineas(D, Ls),
    alguna_linea(Ls, '|- [ok] a(1)'),
    alguna_linea(Ls, '\\- [no] 1>5').

test(un_predefinido_falso_se_lee_es_falso, [nondet]) :-
    por_que_no(toy_diag:r_builtin(1), D),
    lineas(D, Ls),
    alguna_linea(Ls, '1>5 es falso').

test(una_negacion_dice_porque_con_el_hecho_en_singular, [nondet]) :-
    por_que_no(toy_diag:r_neg(1), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'porque tiene(x) es cierto.').

test(varios_hechos_dicen_son_ciertos_con_y, [nondet]) :-
    por_que_no(\+ (toy_diag:a(1), toy_diag:tiene(x)), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'porque a(1) y tiene(x) son ciertos.').

test(un_hecho_ausente_dice_que_no_hay_ni_hecho_ni_clausula, [nondet]) :-
    por_que_no(toy_diag:a(9), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula').

test(una_disyuncion_muestra_las_dos_ramas, [nondet]) :-
    por_que_no((toy_diag:hecho_d(1) ; toy_diag:hecho_d(2)), D),
    lineas(D, Ls),
    Ls = [Cab|_],
    Cab == '[no] ninguna de las dos ramas se cumple',
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para hecho_d(1)'),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para hecho_d(2)').

test(una_disyuncion_dentro_de_una_regla_se_lee_con_sus_dos_ramas, [nondet]) :-
    por_que_no(toy_diag:r_disy(1), D),
    lineas(D, Ls),
    alguna_linea(Ls, '1>5 es falso'),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para hecho_d(1)').

test(el_limite_se_lee, [nondet]) :-
    lineas(limite(foo), Ls),
    alguna_linea(Ls, 'se agoto la profundidad').

test(solo_se_muestra_la_clausula_mas_cercana, [nondet]) :-
    por_que_no(toy_diag:r_dos(1), D),
    lineas(D, Ls),
    alguna_linea(Ls, '[clausula 2]'),
    \+ alguna_linea(Ls, '[clausula 1]').

test(las_lineas_son_ascii_salvo_el_texto_del_juego, [nondet]) :-
    por_que_no(toy_diag:r_neg(1), D),
    lineas(D, Ls),
    forall(( member(L, Ls), atom_codes(L, Cs), member(C, Cs) ), C < 128).

test(las_variables_salen_como_letras, [nondet]) :-
    por_que_no(toy_diag:r_builtin(_), D),
    lineas(D, [Cab|_]),
    contiene(Cab, 'r_builtin(A)').

:- end_tests(el_texto_del_diagnostico).

:- begin_tests(demostracion_1_el_miedo_de_baldomero).

test(baldomero_no_puede_atacar_al_bandido_montado, [setup(combate_con([bandido_montado])), nondet]) :-
    B = e(bandido_montado, 1),
    por_que_no(combate:puede_atacar(baldomero, B),
               fallo(_, [cl(1, Pre, punto(\+ (compania:teme(baldomero, caballo), _), neg_viola(_, Prueba)))])),
    length(Pre, 5),                                  % vivo, sin huelga, vivo, fila y sin aturdir
    aplanar(Prueba, Ps),
    length(Ps, 2).

aplanar((A, B), L) :- !, aplanar(A, LA), aplanar(B, LB), append(LA, LB, L).
aplanar(P, [P]).

test(la_pantalla_cuenta_la_causa_con_los_hechos, [setup(combate_con([bandido_montado])), nondet]) :-
    B = e(bandido_montado, 1),
    por_que_no(combate:puede_atacar(baldomero, B), D),
    lineas(D, Ls),
    Ls = [Cab|_],
    Cab == '[no] puede_atacar(baldomero, e(bandido_montado, 1))   [clausula 1]',
    alguna_linea(Ls, '|- [ok] vivo(baldomero)'),
    alguna_linea(Ls, '|- [ok] en_fila_alcanzable(baldomero, e(bandido_montado, 1))'),
    alguna_linea(Ls, '|- [ok] \\+ aturdido(baldomero)'),
    alguna_linea(Ls, '\\- [no] \\+ (teme(baldomero, caballo), clase_de(e(bandido_montado, 1), caballo))'),
    alguna_linea(Ls, 'porque teme(baldomero, caballo) y clase_de(e(bandido_montado, 1), caballo) son ciertos.').

test(con_la_venda_si_puede_y_no_hay_diagnostico, [setup(combate_con([bandido_montado])), fail]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    por_que_no(combate:puede_atacar(baldomero, e(bandido_montado, 1)), _).

test(a_un_bandido_torpe_si_puede_y_no_hay_diagnostico, [setup(combate_con([bandido_torpe])), fail]) :-
    por_que_no(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), _).

test(los_demas_si_pueden_atacar_al_montado, [setup(combate_con([bandido_montado])), fail]) :-
    por_que_no(combate:puede_atacar(tuerca, e(bandido_montado, 1)), _).

test(el_comando_la_enseña_con_el_actor_del_turno, [setup(combate_con([bandido_montado])), nondet]) :-
    ordena(por_que_no(atacar(bandido_montado)), [vista(diag, atacar(bandido_montado), D)]),
    lineas(D, [Cab|_]),
    contiene(Cab, 'puede_atacar(baldomero').

test(el_comando_la_enseña_con_el_actor_explicito, [setup(combate_con([bandido_montado])), nondet]) :-
    ordena(por_que_no(atacar(baldomero, bandido_montado)), [vista(diag, atacar(baldomero, bandido_montado), _)]).

test(la_pantalla_dice_por_que_y_cierra_el_narrador, [setup(combate_con([bandido_montado])), nondet]) :-
    pantalla(por_que_no(atacar(bandido_montado)), T),
    contiene(T, 'Por qué no se puede atacar(bandido_montado):'),
    contiene(T, 'porque teme(baldomero, caballo)'),
    contiene(T, 'Narrador: Sir Baldomero ve el caballo, recuerda su infancia').

:- end_tests(demostracion_1_el_miedo_de_baldomero).

:- begin_tests(demostracion_2_la_gallina_noble).

en_el_camino_real :-
    nueva_partida,
    aplicar_efecto(viajar(camino_real)).

test(sin_venda_no_se_puede_aceptar, [setup(en_el_camino_real), nondet]) :-
    por_que_no(contratos:puede_aceptar(gallina_noble), fallo(_, [cl(1, Pre, punto(F, _))])),
    length(Pre, 7),
    F = cumple_todas(_).

test(la_cadena_baja_hasta_la_negacion_de_rasgo_no, [setup(en_el_camino_real), nondet]) :-
    por_que_no(contratos:puede_aceptar(gallina_noble), D),
    lineas(D, Ls),
    Ls = [Cab|_],
    Cab == '[no] puede_aceptar(gallina_noble)   [clausula 1]',
    alguna_linea(Ls, '|- [ok] disponible(gallina_noble)'),
    alguna_linea(Ls, '\\- [no] cumple_todas([requiere(rasgo_no(teme_caballos))])'),
    alguna_linea(Ls, '\\- [no] condicion_cumple(rasgo_no(teme_caballos))'),
    alguna_linea(Ls, 'porque activo(baldomero), rasgo(baldomero, teme_caballos) y \\+ ignora_miedo(baldomero) son ciertos.').

test(con_la_venda_se_puede_y_no_hay_diagnostico, [setup(en_el_camino_real), fail]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    por_que_no(contratos:puede_aceptar(gallina_noble), _).

test(desde_la_taberna_tambien_falla_la_venda, [setup(nueva_partida), nondet]) :-
    % la gallina se ofrece desde el dia 1: lo que la bloquea es el miedo, no el sitio
    por_que_no(contratos:puede_aceptar(gallina_noble), fallo(_, [cl(1, _, punto(cumple_todas(_), _))])).

test(un_contrato_que_no_existe_es_sin_clausula, [setup(nueva_partida), nondet]) :-
    por_que_no(contratos:puede_aceptar(dragon), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para contrato(dragon, A, B, C, D)').

test(el_comando_dice_el_rasgo_y_cierra_el_narrador, [setup(en_el_camino_real), nondet]) :-
    pantalla(por_que_no(aceptar(gallina_noble)), T),
    contiene(T, 'Por qué no se puede aceptar(gallina_noble):'),
    contiene(T, 'rasgo_no(teme_caballos)'),
    contiene(T, 'Narrador: Lady Clotilde exige escolta sin miedo a los caballos').

test(con_la_venda_el_comando_dice_que_no_falla_nada, [setup(en_el_camino_real), nondet]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(por_que_no(aceptar(gallina_noble)), [error(sin_fallo(aceptar(gallina_noble)))]).

:- end_tests(demostracion_2_la_gallina_noble).

:- begin_tests(otras_reglas_del_juego).

test(no_hay_camino_a_una_zona_lejana, [setup(nueva_partida), nondet]) :-
    por_que_no(compania:puede_viajar(castillo), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula para conexion(taberna, castillo)').

test(descansar_sin_queso_falla_por_la_despensa, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    por_que_no(economia:puede_descansar, fallo(_, [cl(1, [hecho(en_zona(taberna))|_], punto(hay_queso_para(_), _))])).

test(descansar_fuera_de_la_taberna_falla_por_la_zona, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(aldea)),
    por_que_no(economia:puede_descansar, fallo(_, [cl(1, [], punto(estado:en_zona(taberna), _))])).

test(pagar_sueldos_ya_pagados_lo_impide_la_marca, [setup(nueva_partida), nondet]) :-
    por_que_no(economia:puede_pagar_sueldos, D),
    lineas(D, Ls),
    alguna_linea(Ls, 'porque marca(sueldos_pagados) es cierto.').

test(un_miembro_en_huelga_no_puede_atacar, [setup(combate_con([bandido_torpe])), nondet]) :-
    moral_a(baldomero, 2),
    por_que_no(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), D),
    lineas(D, Ls),
    alguna_linea(Ls, '\\+ esta_en_huelga(baldomero)'),
    alguna_linea(Ls, 'porque esta_en_huelga(baldomero)').

test(con_moral_tres_no_hay_huelga, [setup(combate_con([bandido_torpe])), fail]) :-
    moral_a(baldomero, 3),
    por_que_no(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), _).

test(un_miembro_aturdido_no_puede_atacar, [setup(combate_con([bandido_torpe])), nondet]) :-
    aplicar_efecto(alterar(baldomero, aturdido, 2)),
    por_que_no(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), D),
    lineas(D, Ls),
    alguna_linea(Ls, 'porque aturdido(baldomero)').

test(la_retaguardia_no_alcanza_si_hay_frente, [setup(retaguardia_protegida), nondet]) :-
    por_que_no(combate:puede_atacar(tuerca, e(rata_quesera, 1)), D),
    lineas(D, Ls),
    alguna_linea(Ls, '[no] en_fila_alcanzable(tuerca, e(rata_quesera, 1))'),
    alguna_linea(Ls, 'no hay ningun hecho ni clausula').

test(pimentina_sin_queso_no_puede_lanzar, [setup(combate_con([bandido_torpe])), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    por_que_no(combate:puede_habilidad(pimentina, fondue_flamigera), D),
    lineas(D, Ls),
    alguna_linea(Ls, '[no] puede_pagar(pimentina, fondue_flamigera)'),
    alguna_linea(Ls, '0>=1 es falso').

:- end_tests(otras_reglas_del_juego).

:- begin_tests(las_claves_del_narrador).

% El diagnostico REAL produce las mismas claves que los diagnosticos escritos a mano en T-29.
clave_real(Meta, Clave) :-
    por_que_no(Meta, D),
    clave_de_diag(D, Clave).

test(f01a_el_miedo_de_baldomero, [setup(combate_con([bandido_montado])), nondet]) :-
    clave_real(combate:puede_atacar(baldomero, e(bandido_montado, 1)), impide(teme(baldomero, caballo))).

test(f02e_la_huelga, [setup(combate_con([bandido_torpe])), nondet]) :-
    moral_a(pimentina, 2),
    clave_real(combate:puede_atacar(pimentina, e(bandido_torpe, 1)), impide(esta_en_huelga(pimentina))).

test(f03a_el_aturdimiento, [setup(combate_con([bandido_torpe])), nondet]) :-
    aplicar_efecto(alterar(baldomero, aturdido, 2)),
    clave_real(combate:puede_atacar(baldomero, e(bandido_torpe, 1)), impide(aturdido(baldomero))).

test(f05a_la_fila, [setup(retaguardia_protegida), nondet]) :-
    clave_real(combate:puede_atacar(tuerca, e(rata_quesera, 1)), falla(en_fila_alcanzable(tuerca, e(rata_quesera, 1)))).

test(f06a_sin_queso_no_hay_hechizo, [setup(combate_con([bandido_torpe])), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    clave_real(combate:puede_habilidad(pimentina, fondue_flamigera), falla(puede_habilidad(pimentina, fondue_flamigera))).

test(f07a_no_hay_camino, [setup(nueva_partida), nondet]) :-
    clave_real(compania:puede_viajar(castillo), falla(puede_viajar(castillo))).

test(f08a_descansar_fuera_de_la_taberna, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(aldea)),
    clave_real(economia:puede_descansar, falla(puede_descansar)).

test(f10b_el_rasgo_de_baldomero, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(camino_real)),
    clave_real(contratos:puede_aceptar(gallina_noble), impide(rasgo(baldomero, teme_caballos))).

test(f10a_otro_requisito_cae_en_la_regla_del_contrato, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(camino_real)),
    aplicar_efecto(viajar(castillo)),
    clave_real(contratos:puede_aceptar(despensa_real), falla(puede_aceptar(despensa_real))).

test(cada_clave_real_tiene_una_frase_propia_y_no_la_generica, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(viajar(camino_real)),
    por_que_no(contratos:puede_aceptar(gallina_noble), D),
    clave_de_diag(D, Clave),
    Clave \= generica(_),
    comentario_diag(D, ambos, 0, T),
    contiene(T, 'Lady Clotilde').

:- end_tests(las_claves_del_narrador).

:- begin_tests(el_comando).

test(es_un_comando_con_un_argumento) :-
    validar_comando(por_que_no(ir(aldea)), ok(por_que_no(ir(aldea)))),
    validar_comando(por_que_no(_), error(falta_argumento(_))),
    validar_comando(por_que_no, error(no_entiendo(_))).

test(vale_en_todas_las_fases) :-
    forall(member(Fase, [exploracion, taberna, combate, fin]), permitido(Fase, por_que_no)).

test(sale_en_la_ayuda_y_tiene_texto) :-
    ayuda_de(por_que_no, T),
    contiene(T, 'por_que_no(Accion)').

test(una_accion_posible_dice_que_no_falla_nada, [setup(nueva_partida), nondet]) :-
    ordena(por_que_no(ir(aldea)), [error(sin_fallo(ir(aldea)))]),
    ordena(por_que_no(descansar), [error(sin_fallo(descansar))]).

test(la_pantalla_de_sin_fallo_sugiere_explicar, [setup(nueva_partida), nondet]) :-
    pantalla(por_que_no(ir(aldea)), T),
    contiene(T, 'No falla nada'),
    contiene(T, 'ir(aldea)').

test(una_accion_que_no_se_sabe_explicar_lo_dice, [setup(nueva_partida), nondet]) :-
    ordena(por_que_no(volar), [error(no_se_explica(volar))]),
    ordena(por_que_no(atacar(rata_quesera)), [error(no_se_explica(atacar(rata_quesera)))]).

test(por_que_no_de_un_comando_de_meta_no_se_explica, [setup(nueva_partida), nondet]) :-
    ordena(por_que_no(mirar), [error(no_se_explica(mirar))]).

test(el_comando_no_cambia_el_estado_ni_la_ultima_prueba, [setup(nueva_partida), nondet]) :-
    ordena(ir(aldea), _),
    foto_estado(Antes),
    ordena(por_que_no(ir(castillo)), [vista(diag, _, _)]),
    ordena(por_que_no(aceptar(gallina_noble)), [vista(diag, _, _)]),
    foto_estado(Despues),
    Antes =@= Despues.

test(tras_por_que_no_explicar_sigue_con_la_ultima_accion, [setup(nueva_partida), nondet]) :-
    ordena(ir(aldea), _),
    ordena(por_que_no(ir(castillo)), _),
    ordena(explicar, [vista(prueba, ir(aldea), _)]).

test(explicar_una_accion_imposible_sugiere_por_que_no, [setup(nueva_partida), nondet]) :-
    pantalla(explicar(ir(castillo)), T),
    contiene(T, 'por_que_no(ir(castillo))').

test(funciona_tambien_tras_acabar_la_partida, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    ordena(por_que_no(ir(aldea)), Items),
    Items \= [error(fuera_de_fase(_, _))].

test(nunca_ensena_terminos_crudos, [setup(nueva_partida), nondet]) :-
    forall(member(Cmd, [por_que_no(ir(castillo)), por_que_no(aceptar(gallina_noble)), por_que_no(pagar),
                        por_que_no(ir(aldea)), por_que_no(volar), por_que_no(aceptar(dragon))]),
           (   pantalla(Cmd, T),
               \+ contiene(T, 'vista('),
               \+ contiene(T, 'error('),
               \+ contiene(T, 'fallo(')
           )).

test(la_misma_pregunta_da_siempre_la_misma_respuesta, [setup(nueva_partida), nondet]) :-
    pantalla(por_que_no(aceptar(gallina_noble)), T1),
    pantalla(por_que_no(aceptar(gallina_noble)), T2),
    T1 == T2.

:- end_tests(el_comando).
