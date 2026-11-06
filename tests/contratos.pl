% contratos.pl (pruebas)
% T-25: los contratos como datos (el catalogo de la version minima), las reglas que dicen cuales
% estan a la vista y cuales se pueden aceptar (puede_aceptar/1 y sus condiciones), los efectos
% contrato_aceptar y visitar, y los comandos contratos y aceptar con su prueba para explicar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/contratos -g "run_tests,halt" -t "halt(1)"

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

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

% Marca contratos ya resueltos (no hay aun comando que los cierre: se escribe el estado a mano).
cerrar(C, R) :- assertz(estado:contrato_cerrado(C, R)).

moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

% Deja cumplidas todas las condiciones de despensa_real.
listo_para_el_rey :-
    cerrar(ratas_del_granero, exito),
    cerrar(gato_en_el_arbol, a_medias),
    cerrar(gallina_noble, exito),
    aplicar_efecto(visitar(castillo)).

:- begin_tests(catalogo).

test(hay_cuatro_contratos_de_la_version_minima) :-
    findall(C, contratos:contrato(C, _, _, _, _), Cs),
    Cs == [ratas_del_granero, gato_en_el_arbol, gallina_noble, despensa_real].

test(cada_contrato_tiene_zona_conocida) :-
    forall(contratos:contrato(_, Z, _, _, _), mundo:zona(Z, _)).

test(cada_contrato_tiene_una_recompensa_en_una_lista) :-
    forall(contratos:contrato(_, _, _, R, _), ( R = recompensa(L), L = [_|_] )).

test(las_recompensas_usan_solo_premios_conocidos) :-
    forall(( contratos:contrato(_, _, _, recompensa(L), _), member(P, L) ),
           (   P = quesos(N), integer(N), N > 0
           ;   P = queso(T, E, N), mundo:tipo_queso(T, _), integer(E), integer(N), N > 0
           ;   P = objeto(O), atom(O)
           )).

test(las_recompensas_en_quesos_son_las_acordadas) :-
    contratos:contrato(ratas_del_granero, _, _, recompensa(R1), _),
    contratos:contrato(gato_en_el_arbol, _, _, recompensa(R2), _),
    contratos:contrato(gallina_noble, _, _, recompensa(R3), _),
    contratos:contrato(despensa_real, _, _, recompensa(R4), _),
    memberchk(quesos(9), R1), memberchk(objeto(pocion), R1),
    memberchk(quesos(7), R2), memberchk(objeto(venda_de_caballos), R2),
    memberchk(quesos(14), R3), memberchk(queso(brie, 0, 1), R3),
    R4 == [quesos(40)].

test(los_objetivos_son_del_vocabulario_cerrado) :-
    forall(contratos:contrato(_, _, O, _, _),
           memberchk(O, [eliminar(_), derrotar(_), escoltar(_, _), evento(_)])).

test(cada_contrato_tiene_oferente_en_una_zona_conocida) :-
    forall(contratos:contrato(C, _, _, _, _),
           ( contratos:oferente(C, Npc, Z), atom(Npc), mundo:zona(Z, _) )).

test(cada_contrato_tiene_un_unico_oferente) :-
    forall(contratos:contrato(C, _, _, _, _),
           ( findall(Z, contratos:oferente(C, _, Z), Zs), Zs = [_] )).

test(cada_contrato_tiene_condiciones_de_aparicion) :-
    forall(contratos:contrato(C, _, _, _, _), contratos:aparece(C, _)).

test(cada_contrato_tiene_una_dificultad_de_1_a_5) :-
    forall(contratos:contrato(C, _, _, _, _),
           ( contratos:dificultad(C, D), between(1, 5, D) )).

test(las_condiciones_de_la_despensa_real_son_cuatro_y_en_orden) :-
    contratos:contrato(despensa_real, _, _, _, Cs),
    Cs == [requiere(contratos_cumplidos_min(3)), requiere(visita(castillo)),
           requiere(moral_media_min(4)), requiere(miembros_en_pie_min(3))].

test(la_gallina_exige_que_nadie_tema_a_los_caballos) :-
    contratos:contrato(gallina_noble, _, _, _, Cs),
    Cs == [requiere(rasgo_no(teme_caballos))].

test(ratas_y_gato_no_tienen_condiciones) :-
    contratos:contrato(ratas_del_granero, _, _, _, A),
    contratos:contrato(gato_en_el_arbol, _, _, _, B),
    A == [], B == [].

test(las_condiciones_usan_solo_el_vocabulario_conocido) :-
    forall(( contratos:contrato(_, _, _, _, Cs), member(requiere(X), Cs) ),
           memberchk(X, [rasgo_no(_), contratos_cumplidos_min(_), moral_media_min(_),
                         visita(_), miembros_en_pie_min(_)])).

test(los_enemigos_de_la_escolta_son_tipos_del_bestiario) :-
    contratos:enemigos_de(gallina_noble, G),
    G == [bandido_torpe, bandido_torpe, bandido_montado],
    forall(member(T, G), mundo:enemigo(T, _, _, _)).

test(solo_la_gallina_tiene_enemigos_de, [nondet]) :-
    findall(C, contratos:enemigos_de(C, _), Cs),
    Cs == [gallina_noble].

test(todo_contrato_tiene_resolucion_y_acaba_en_un_resultado_seguro) :-
    forall(contratos:contrato(C, _, _, _, _),
           (   findall(R, contratos:resolucion(C, R, _), Rs),
               Rs = [_|_],
               forall(member(R, Rs), memberchk(R, [exito, a_medias, fracaso]))
           )).

test(la_ultima_resolucion_de_cada_contrato_no_tiene_condiciones) :-
    forall(contratos:contrato(C, _, _, _, _),
           (   findall(Cs, contratos:resolucion(C, _, Cs), Lista),
               last(Lista, Ultima),
               ( Ultima == [] ; C == despensa_real )
           )).

test(el_exito_va_primero_cuando_existe) :-
    forall(contratos:contrato(C, _, _, _, _),
           (   findall(R, contratos:resolucion(C, R, _), [Primero|_]),
               Primero == exito
           )).

test(las_condiciones_de_resolucion_son_del_vocabulario, [nondet]) :-
    forall(( contratos:resolucion(_, _, Cs), member(X, Cs) ),
           memberchk(X, [contador_max(_, _), marca(_)])).

test(los_nombres_visibles_existen_para_los_cuatro) :-
    forall(contratos:contrato(C, _, _, _, _),
           ( narrador:nombre_visible(C, N), N \== C )).

:- end_tests(catalogo).

:- begin_tests(via_del_objetivo).

test(las_ratas_son_un_combate_de_dos, [nondet]) :-
    contratos:via_objetivo(ratas_del_granero, V),
    V == combate([rata_quesera, rata_quesera]).

test(la_despensa_real_es_el_combate_del_jefe, [nondet]) :-
    contratos:via_objetivo(despensa_real, V),
    V == combate([gran_roquefort]).

test(la_escolta_es_un_combate_con_sus_enemigos, [nondet]) :-
    contratos:via_objetivo(gallina_noble, V),
    V == combate([bandido_torpe, bandido_torpe, bandido_montado]).

test(el_gato_es_un_evento, [nondet]) :-
    contratos:via_objetivo(gato_en_el_arbol, V),
    V == evento(rescate_gato).

test(cada_contrato_tiene_exactamente_una_via) :-
    forall(contratos:contrato(C, _, _, _, _),
           ( findall(V, contratos:via_objetivo(C, V), Vs), Vs = [_] )).

test(los_grupos_de_combate_son_tipos_validos) :-
    forall(( contratos:via_objetivo(_, combate(G)), member(T, G) ),
           mundo:enemigo(T, _, _, _)),
    forall(contratos:via_objetivo(_, combate(G)), ( G = [_|_], efectos_inicio_ok(G) )).

efectos_inicio_ok(G) :-
    nueva_partida,
    combate:efectos_inicio(G, _).

test(expandir_un_par) :-
    contratos:expandir_grupo([rata_quesera-3], G),
    G == [rata_quesera, rata_quesera, rata_quesera].

test(expandir_varios_pares_en_orden) :-
    contratos:expandir_grupo([rata_quesera-2, bandido_torpe-1], G),
    G == [rata_quesera, rata_quesera, bandido_torpe].

test(expandir_nada_da_un_grupo_vacio) :-
    contratos:expandir_grupo([], G),
    G == [].

test(expandir_cero_unidades_no_anade_nada) :-
    contratos:expandir_grupo([rata_quesera-0, moho_saltarin-1], G),
    G == [moho_saltarin].

:- end_tests(via_del_objetivo).

:- begin_tests(condiciones).

test(rasgo_no_falla_mientras_baldomero_teme, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(rasgo_no(teme_caballos)).

test(con_la_venda_rasgo_no_se_cumple, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    contratos:condicion_cumple(rasgo_no(teme_caballos)).

test(la_venda_de_otro_no_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(equipar(pimentina, venda_de_caballos)),
    contratos:condicion_cumple(rasgo_no(teme_caballos)).

test(si_baldomero_esta_caido_ya_no_cuenta, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(baldomero, 99)),
    contratos:condicion_cumple(rasgo_no(teme_caballos)).

test(rasgo_no_de_otro_rasgo_mira_a_todos, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(rasgo_no(manos_largas)).

test(un_rasgo_que_nadie_tiene_se_cumple, [setup(nueva_partida)]) :-
    contratos:condicion_cumple(rasgo_no(vuela)).

test(sin_contratos_cumplidos_pide_cero, [setup(nueva_partida)]) :-
    contratos:condicion_cumple(contratos_cumplidos_min(0)).

test(sin_contratos_cumplidos_no_vale_uno, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(un_exito_cuenta, [setup(nueva_partida)]) :-
    cerrar(ratas_del_granero, exito),
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(a_medias_tambien_cuenta, [setup(nueva_partida)]) :-
    cerrar(ratas_del_granero, a_medias),
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(un_fracaso_no_cuenta, [setup(nueva_partida), fail]) :-
    cerrar(ratas_del_granero, fracaso),
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(uno_por_cobrar_cuenta_aunque_no_este_cobrado, [setup(nueva_partida)]) :-
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(un_fracaso_por_cobrar_no_cuenta, [setup(nueva_partida), fail]) :-
    assertz(estado:contrato_por_cobrar(ratas_del_granero, fracaso)),
    contratos:condicion_cumple(contratos_cumplidos_min(1)).

test(tres_cumplidos_dan_tres, [setup(nueva_partida)]) :-
    cerrar(ratas_del_granero, exito),
    cerrar(gato_en_el_arbol, a_medias),
    assertz(estado:contrato_por_cobrar(gallina_noble, exito)),
    contratos:contratos_cumplidos(N),
    N == 3,
    contratos:condicion_cumple(contratos_cumplidos_min(3)),
    \+ contratos:condicion_cumple(contratos_cumplidos_min(4)).

test(la_moral_media_inicial_es_6, [setup(nueva_partida), nondet]) :-
    compania:moral_media(M),
    M =:= 6,
    contratos:condicion_cumple(moral_media_min(6)).

test(la_moral_media_es_exacta_no_entera, [setup(nueva_partida), nondet]) :-
    moral_a(rufino, 3),                                % (6 + 6 + 3 + 6) / 4
    compania:moral_media(M),
    M =:= 5.25.

test(la_moral_media_no_llega_a_7, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(moral_media_min(7)).

test(la_moral_media_baja_con_la_moral, [setup(nueva_partida), fail]) :-
    forall(compania:miembro(Id), moral_a(Id, 3)),
    contratos:condicion_cumple(moral_media_min(4)).

test(la_moral_media_se_calcula_sobre_los_activos, [setup(nueva_partida)]) :-
    moral_a(rufino, 0),
    aplicar_efecto(dano(rufino, 99)),                  % caido: no cuenta en la media
    contratos:condicion_cumple(moral_media_min(6)).

test(sin_activos_no_hay_moral_media, [setup(nueva_partida), fail]) :-
    forall(compania:miembro(Id), aplicar_efecto(dano(Id, 99))),
    compania:moral_media(_).

test(la_moral_media_puede_ser_fraccionaria, [setup(nueva_partida)]) :-
    moral_a(rufino, 3),                                % (6+6+3+6)/4 = 5.25
    contratos:condicion_cumple(moral_media_min(5)),
    \+ contratos:condicion_cumple(moral_media_min(6)).

test(cuatro_en_pie_al_empezar, [setup(nueva_partida)]) :-
    contratos:condicion_cumple(miembros_en_pie_min(4)).

test(no_hay_cinco_en_pie, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(miembros_en_pie_min(5)).

test(un_caido_no_esta_en_pie, [setup(nueva_partida), fail]) :-
    aplicar_efecto(dano(tuerca, 99)),
    contratos:condicion_cumple(miembros_en_pie_min(4)).

test(un_huelguista_no_esta_en_pie, [setup(nueva_partida), fail]) :-
    moral_a(rufino, 2),
    contratos:condicion_cumple(miembros_en_pie_min(4)).

test(con_uno_menos_aun_hay_tres, [setup(nueva_partida)]) :-
    moral_a(rufino, 2),
    contratos:condicion_cumple(miembros_en_pie_min(3)).

test(la_taberna_esta_visitada_desde_el_principio, [setup(nueva_partida)]) :-
    contratos:condicion_cumple(visita(taberna)).

test(la_aldea_no_esta_visitada_al_principio, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(visita(aldea)).

test(viajar_marca_la_zona_como_visitada, [setup(nueva_partida)]) :-
    ordena(ir(aldea), _),
    contratos:condicion_cumple(visita(aldea)).

test(una_condicion_desconocida_no_se_cumple, [setup(nueva_partida), fail]) :-
    contratos:condicion_cumple(vuela(alto)).

:- end_tests(condiciones).

:- begin_tests(efectos_de_contratos).

test(visitar_marca_la_zona, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(visitar(castillo)),
    estado:visitada(castillo).

test(visitar_dos_veces_no_duplica, [setup(nueva_partida)]) :-
    aplicar_efecto(visitar(castillo)),
    aplicar_efecto(visitar(castillo)),
    findall(x, estado:visitada(castillo), L),
    L == [x].

test(visitar_una_zona_desconocida_falla, [setup(nueva_partida), fail]) :-
    aplicar_efecto(visitar(luna)).

test(visitar_algo_que_no_es_un_atomo_falla, [setup(nueva_partida), fail]) :-
    aplicar_efecto(visitar(_)).

test(aceptar_deja_el_contrato_activo, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    estado:contrato_activo(ratas_del_granero).

test(aceptar_dos_veces_el_mismo_falla, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_aceptar(ratas_del_granero)).

test(un_contrato_ya_cumplido_no_se_acepta, [setup(nueva_partida), fail]) :-
    cerrar(ratas_del_granero, exito),
    aplicar_efecto(contrato_aceptar(ratas_del_granero)).

test(uno_por_cobrar_tampoco_se_acepta, [setup(nueva_partida), fail]) :-
    assertz(estado:contrato_por_cobrar(ratas_del_granero, a_medias)),
    aplicar_efecto(contrato_aceptar(ratas_del_granero)).

test(uno_fracasado_se_puede_volver_a_aceptar, [setup(nueva_partida), nondet]) :-
    cerrar(ratas_del_granero, fracaso),
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    estado:contrato_activo(ratas_del_granero).

test(aceptar_lo_que_no_es_un_atomo_falla, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(_)).

test(aceptar_no_toca_otra_cosa, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    foto_estado(Despues),
    subtract(Despues, Antes, Nuevos),
    Nuevos == [contrato_activo(gato_en_el_arbol)].

test(un_fallo_no_cambia_el_estado, [setup(nueva_partida)]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    foto_estado(Antes),
    \+ aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    foto_estado(Despues),
    Antes == Despues.

test(una_transaccion_deshace_aceptar, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    \+ con_transaccion(( aplicar_efecto(contrato_aceptar(ratas_del_granero)), fail )),
    foto_estado(Despues),
    Antes == Despues.

test(nueva_partida_borra_los_contratos, [setup(nueva_partida)]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(visitar(castillo)),
    nueva_partida,
    \+ estado:contrato_activo(_),
    \+ estado:visitada(castillo),
    estado:visitada(taberna).

:- end_tests(efectos_de_contratos).

:- begin_tests(que_se_ve_y_que_se_acepta).

test(al_empezar_se_ven_tres_contratos, [setup(nueva_partida)]) :-
    findall(C, contratos:visible(C), Cs),
    Cs == [ratas_del_granero, gato_en_el_arbol, gallina_noble].

test(la_despensa_real_no_se_ve_hasta_visitar_el_castillo, [setup(nueva_partida)]) :-
    \+ contratos:visible(despensa_real),
    aplicar_efecto(visitar(castillo)),
    contratos:visible(despensa_real).

test(en_la_taberna_estan_disponibles_los_tres_del_tablon, [setup(nueva_partida)]) :-
    findall(C, contratos:disponible(C), Cs),
    Cs == [ratas_del_granero, gato_en_el_arbol, gallina_noble].

test(en_la_aldea_solo_estan_los_de_la_alcaldesa) :-
    nueva_partida,
    ordena(ir(aldea), _),
    findall(C, contratos:disponible(C), Cs),
    Cs == [ratas_del_granero, gato_en_el_arbol].

test(en_el_camino_real_esta_la_gallina) :-
    nueva_partida,
    ordena(ir(camino_real), _),
    findall(C, contratos:disponible(C), Cs),
    Cs == [gallina_noble].

test(en_el_bosque_no_hay_nada_disponible) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(ir(bosque), _),
    findall(C, contratos:disponible(C), Cs),
    Cs == [].

test(se_pueden_aceptar_las_ratas_y_el_gato, [setup(nueva_partida)]) :-
    findall(C, contratos:puede_aceptar(C), Cs),
    Cs == [ratas_del_granero, gato_en_el_arbol].

test(la_gallina_esta_bloqueada_sin_la_venda, [setup(nueva_partida), fail]) :-
    contratos:puede_aceptar(gallina_noble).

test(con_la_venda_se_puede_aceptar_la_gallina, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    contratos:puede_aceptar(gallina_noble).

test(la_despensa_real_no_se_puede_aceptar_al_empezar, [setup(nueva_partida), fail]) :-
    contratos:puede_aceptar(despensa_real).

test(la_despensa_real_se_acepta_con_todo_cumplido, [setup(nueva_partida), nondet]) :-
    listo_para_el_rey,
    contratos:puede_aceptar(despensa_real).

test(a_la_despensa_real_le_falla_un_contrato_cumplido, [setup(nueva_partida), fail]) :-
    listo_para_el_rey,
    retract(estado:contrato_cerrado(gallina_noble, exito)),
    contratos:puede_aceptar(despensa_real).

test(a_la_despensa_real_le_falla_la_visita, [setup(nueva_partida), fail]) :-
    listo_para_el_rey,
    retractall(estado:visitada(castillo)),
    contratos:puede_aceptar(despensa_real).

test(a_la_despensa_real_le_falla_la_moral, [setup(nueva_partida), fail]) :-
    listo_para_el_rey,
    forall(compania:miembro(Id), moral_a(Id, 3)),
    contratos:puede_aceptar(despensa_real).

test(a_la_despensa_real_le_falla_la_gente_en_pie, [setup(nueva_partida), fail]) :-
    listo_para_el_rey,
    aplicar_efecto(dano(tuerca, 99)),
    aplicar_efecto(dano(rufino, 99)),
    contratos:puede_aceptar(despensa_real).

test(con_tres_en_pie_basta, [setup(nueva_partida), nondet]) :-
    listo_para_el_rey,
    aplicar_efecto(dano(tuerca, 99)),
    contratos:puede_aceptar(despensa_real).

test(solo_caben_tres_contratos_activos, [setup(nueva_partida), fail]) :-
    listo_para_el_rey,
    assertz(estado:contrato_activo(a)),
    assertz(estado:contrato_activo(b)),
    assertz(estado:contrato_activo(c)),
    contratos:puede_aceptar(despensa_real).

test(con_dos_activos_aun_cabe_otro, [setup(nueva_partida), nondet]) :-
    listo_para_el_rey,
    assertz(estado:contrato_activo(a)),
    assertz(estado:contrato_activo(b)),
    contratos:puede_aceptar(despensa_real).

test(uno_activo_no_se_acepta_otra_vez, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    contratos:puede_aceptar(ratas_del_granero).

test(uno_cumplido_no_se_acepta_otra_vez, [setup(nueva_partida), fail]) :-
    cerrar(ratas_del_granero, exito),
    contratos:puede_aceptar(ratas_del_granero).

test(uno_fracasado_vuelve_a_poder_aceptarse, [setup(nueva_partida), nondet]) :-
    cerrar(ratas_del_granero, fracaso),
    contratos:puede_aceptar(ratas_del_granero).

test(un_contrato_que_no_existe_no_se_acepta, [setup(nueva_partida), fail]) :-
    contratos:puede_aceptar(dragon_de_la_cueva).

test(desde_la_aldea_no_se_puede_aceptar_la_gallina) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(ir(aldea), _),
    \+ contratos:puede_aceptar(gallina_noble).

test(puede_aceptar_no_modifica_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    forall(contratos:contrato(C, _, _, _, _), ( contratos:puede_aceptar(C) -> true ; true )),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(que_se_ve_y_que_se_acepta).

:- begin_tests(el_tablon).

test(al_empezar_el_tablon_ensena_tres_fichas, [setup(nueva_partida)]) :-
    ordena(contratos, [vista(contratos, Fichas)]),
    findall(Id-Estado, member(contrato(Id, _, _, _, Estado), Fichas), Ps),
    Ps == [ratas_del_granero-disponible, gato_en_el_arbol-disponible, gallina_noble-bloqueado].

test(una_ficha_lleva_zona_dificultad_y_premio, [setup(nueva_partida), nondet]) :-
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(gallina_noble, camino_real, 3, [quesos(14), queso(brie, 0, 1)], bloqueado), Fichas).

test(un_contrato_aceptado_sale_como_activo, [setup(nueva_partida)]) :-
    ordena(aceptar(ratas_del_granero), _),
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(ratas_del_granero, _, _, _, activo), Fichas).

test(un_contrato_cumplido_sale_como_cumplido, [setup(nueva_partida)]) :-
    cerrar(ratas_del_granero, exito),
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(ratas_del_granero, _, _, _, cumplido), Fichas).

test(lejos_si_hay_que_ir_a_donde_esta_el_oferente) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(gallina_noble, _, _, _, lejos), Fichas),
    memberchk(contrato(ratas_del_granero, _, _, _, disponible), Fichas).

test(con_la_venda_la_gallina_pasa_a_disponible, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(gallina_noble, _, _, _, disponible), Fichas).

test(la_despensa_real_aparece_al_visitar_el_castillo, [setup(nueva_partida)]) :-
    aplicar_efecto(visitar(castillo)),
    ordena(contratos, [vista(contratos, Fichas)]),
    memberchk(contrato(despensa_real, _, 5, _, Estado), Fichas),
    Estado == bloqueado.

test(el_tablon_no_modifica_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    ordena(contratos, _),
    foto_estado(Despues),
    Antes == Despues.

test(la_pantalla_del_tablon, [setup(nueva_partida), nondet]) :-
    pantalla(contratos, Texto),
    sub_atom(Texto, _, _, _, 'El tablón de contratos:'),
    sub_atom(Texto, _, _, _, '[disponible] Ratas del Granero (la Aldea Requesón, dificultad 1): 9 quesos, poción'),
    sub_atom(Texto, _, _, _, '[bloqueado] Lady Clotilde Plumífera (el Camino Real, dificultad 3): 14 quesos, 1 brie'),
    \+ sub_atom(Texto, _, _, _, 'contrato(').

test(el_tablon_funciona_tambien_fuera_de_la_taberna) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(contratos, [vista(contratos, _)]).

test(el_tablon_no_vale_en_combate) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(contratos, Items),
    Items = [error(fuera_de_fase(contratos, combate))].

:- end_tests(el_tablon).

:- begin_tests(comando_aceptar).

test(aceptar_las_ratas, [setup(nueva_partida)]) :-
    ordena(aceptar(ratas_del_granero), Items),
    Items == [msg(acepta, [ratas_del_granero], 0)],
    estado:contrato_activo(ratas_del_granero).

test(aceptar_dos_contratos, [setup(nueva_partida)]) :-
    ordena(aceptar(ratas_del_granero), _),
    ordena(aceptar(gato_en_el_arbol), _),
    contratos:contratos_activos(N),
    N == 2.

test(aceptar_otra_vez_el_mismo_es_un_error, [setup(nueva_partida)]) :-
    ordena(aceptar(ratas_del_granero), _),
    ordena(aceptar(ratas_del_granero), Items),
    Items == [error(no_puede_aceptar(ratas_del_granero))].

test(aceptar_la_gallina_sin_venda_es_un_error, [setup(nueva_partida)]) :-
    ordena(aceptar(gallina_noble), Items),
    Items == [error(no_puede_aceptar(gallina_noble))],
    \+ estado:contrato_activo(gallina_noble).

test(aceptar_la_gallina_con_la_venda_en_la_taberna, [setup(nueva_partida)]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(aceptar(gallina_noble), Items),
    Items == [msg(acepta, [gallina_noble], 0)].

test(aceptar_la_despensa_real_al_empezar_es_un_error, [setup(nueva_partida)]) :-
    ordena(aceptar(despensa_real), Items),
    Items == [error(no_puede_aceptar(despensa_real))].

test(aceptar_lo_que_no_existe, [setup(nueva_partida)]) :-
    ordena(aceptar(dragon), Items),
    Items == [error(contrato_desconocido(dragon))].

test(un_error_no_toca_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    ordena(aceptar(gallina_noble), _),
    ordena(aceptar(dragon), _),
    ordena(aceptar(despensa_real), _),
    foto_estado(Despues),
    Antes =@= Despues.

test(se_acepta_desde_la_aldea_lo_de_la_aldea) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(aceptar(gato_en_el_arbol), Items),
    Items == [msg(acepta, [gato_en_el_arbol], 0)].

test(desde_la_aldea_no_se_acepta_lo_del_camino_real) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(ir(aldea), _),
    ordena(aceptar(gallina_noble), Items),
    Items == [error(no_puede_aceptar(gallina_noble))].

test(en_el_camino_real_se_acepta_la_gallina_con_venda) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(ir(camino_real), _),
    ordena(aceptar(gallina_noble), Items),
    Items == [msg(acepta, [gallina_noble], 0)].

test(el_limite_de_tres_se_aplica_al_aceptar) :-
    nueva_partida,
    listo_para_el_rey,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    assertz(estado:contrato_activo(a)),
    assertz(estado:contrato_activo(b)),
    ordena(aceptar(despensa_real), I1),
    I1 == [msg(acepta, [despensa_real], 0)],
    estado:contrato_activo(despensa_real),                % ya hay tres activos
    ordena(aceptar(gato_en_el_arbol), I2),
    I2 == [error(no_puede_aceptar(gato_en_el_arbol))].

test(aceptar_con_variable_falta_argumento, [setup(nueva_partida)]) :-
    ordena(aceptar(_), Items),
    Items = [error(falta_argumento(_))].

test(aceptar_sin_argumento_no_es_comando, [setup(nueva_partida)]) :-
    validar_comando(aceptar, Res),
    Res == error(no_entiendo(aceptar)).

test(aceptar_con_argumento_es_comando, [setup(nueva_partida)]) :-
    validar_comando(aceptar(ratas_del_granero), Res),
    Res == ok(aceptar(ratas_del_granero)).

test(contratos_con_argumento_no_es_comando, [setup(nueva_partida)]) :-
    validar_comando(contratos(1), Res),
    Res == error(no_entiendo(contratos(1))).

test(en_combate_no_se_acepta) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(aceptar(ratas_del_granero), Items),
    Items = [error(fuera_de_fase(aceptar(ratas_del_granero), combate))].

test(con_la_partida_acabada_no_se_acepta, [setup(nueva_partida)]) :-
    aplicar_efecto(fin(victoria)),
    ordena(aceptar(ratas_del_granero), Items),
    Items = [error(fuera_de_fase(_, fin))].

test(las_entradas_raras_nunca_fallan_ni_lanzan, [setup(nueva_partida)]) :-
    forall(member(Cmd, [aceptar(1), aceptar("texto"), aceptar(e(a, b)), aceptar([]), aceptar(f(x)),
                        aceptar(ratas_del_granero), aceptar(ratas_del_granero), contratos]),
           (   ejecutar(Cmd, R), R = resultado(_) )).

test(la_ayuda_incluye_los_comandos_nuevos, [setup(nueva_partida), nondet]) :-
    ordena(ayuda, [vista(ayuda, Comandos)]),
    memberchk(contratos, Comandos),
    memberchk(aceptar, Comandos),
    narrador:ayuda_de(contratos, _),
    narrador:ayuda_de(aceptar, _).

test(la_pantalla_de_aceptar, [setup(nueva_partida), nondet]) :-
    pantalla(aceptar(ratas_del_granero), Texto),
    sub_atom(Texto, _, _, _, 'Contrato aceptado: «Ratas del Granero».'),
    \+ sub_atom(Texto, _, _, _, 'msg(').

test(la_pantalla_del_rechazo, [setup(nueva_partida), nondet]) :-
    pantalla(aceptar(gallina_noble), Texto),
    sub_atom(Texto, _, _, _, 'El contrato «Lady Clotilde Plumífera» os mira, mira a la Banda y decide que no.'),
    \+ sub_atom(Texto, _, _, _, 'error(').

test(la_pantalla_del_contrato_desconocido, [setup(nueva_partida), nondet]) :-
    pantalla(aceptar(dragon), Texto),
    sub_atom(Texto, _, _, _, 'No hay ningún contrato llamado "dragon"').

:- end_tests(comando_aceptar).

:- begin_tests(explicar_contratos).

test(explicar_aceptar_antes_de_aceptar_resuelve_en_hipotetico, [setup(nueva_partida), nondet]) :-
    ordena(explicar(aceptar(ratas_del_granero)), Items),
    Items = [vista(prueba, aceptar(ratas_del_granero), Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] puede_aceptar(ratas_del_granero)   [clausula 1]', Lineas).

test(explicar_tras_aceptar_muestra_la_prueba_guardada, [setup(nueva_partida)]) :-
    ordena(aceptar(ratas_del_granero), _),
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == aceptar(ratas_del_granero).

test(la_prueba_guardada_es_la_de_antes_de_aceptar, [setup(nueva_partida), nondet]) :-
    ordena(aceptar(ratas_del_granero), _),             % ahora ya esta activo...
    ordena(explicar(aceptar(ratas_del_granero)), [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('   [ok] contratos_activos(0)   [clausula 1]', Lineas).   % ...pero la prueba dice 0

test(explicar_el_rechazo_no_tiene_prueba, [setup(nueva_partida)]) :-
    ordena(explicar(aceptar(gallina_noble)), Items),
    Items == [error(no_hay_prueba(aceptar(gallina_noble)))].

test(con_la_venda_la_gallina_tiene_prueba_y_ensena_la_regla_del_rasgo, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(explicar(aceptar(gallina_noble)), [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'condicion_cumple(rasgo_no(teme_caballos))') )),
    once(( member(L2, Lineas), sub_atom(L2, _, _, _, '\\+ (activo(A), rasgo(A, teme_caballos)') )).

test(la_prueba_de_la_despensa_real_ensena_las_cuatro_condiciones, [setup(nueva_partida), nondet]) :-
    listo_para_el_rey,
    ordena(explicar(aceptar(despensa_real)), [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    forall(member(Cond, ['contratos_cumplidos_min(3)', 'visita(castillo)', 'moral_media_min(4)',
                          'miembros_en_pie_min(3)']),
           once(( member(L, Lineas), sub_atom(L, _, _, _, Cond) ))).

test(explicar_un_contrato_que_no_existe, [setup(nueva_partida)]) :-
    ordena(explicar(aceptar(dragon)), Items),
    Items == [error(no_hay_prueba(aceptar(dragon)))].

test(la_pantalla_ensena_el_arbol, [setup(nueva_partida), nondet]) :-
    pantalla(explicar(aceptar(gato_en_el_arbol)), Texto),
    sub_atom(Texto, _, _, _, 'puede_aceptar(gato_en_el_arbol)'),
    sub_atom(Texto, _, _, _, 'parametro(max_contratos, 3)').

test(solve_da_lo_mismo_que_ejecutar_en_varios_estados) :-
    forall(member(Preparar, [nueva_partida,
                             ( nueva_partida, aplicar_efecto(equipar(baldomero, venda_de_caballos)) ),
                             ( nueva_partida, listo_para_el_rey ),
                             ( nueva_partida, aplicar_efecto(contrato_aceptar(ratas_del_granero)) ),
                             ( nueva_partida, cerrar(ratas_del_granero, fracaso) )]),
           (   call(Preparar),
               forall(contratos:contrato(C, _, _, _, _),
                      (   findall(x, contratos:puede_aceptar(C), Directo),
                          findall(x, solve(contratos:puede_aceptar(C), _), ConSolve),
                          Directo == ConSolve
                      )),
               findall(C2, contratos:visible(C2), V1),
               findall(C2, solve(contratos:visible(C2), _), V2),
               V1 == V2,
               findall(C3-E, contratos:estado_de_contrato(C3, E), S1),
               findall(C3-E, solve(contratos:estado_de_contrato(C3, E), _), S2),
               S1 == S2
           )).

test(la_aceptacion_sale_del_mismo_camino_con_explicar_que_con_ejecutar, [setup(nueva_partida)]) :-
    findall(C, contratos:puede_aceptar(C), Reales),
    findall(C, ( contratos:contrato(C, _, _, _, _),
                 ejecutar(explicar(aceptar(C)), resultado([vista(prueba, _, _)])) ), Explicables),
    Reales == Explicables.

:- end_tests(explicar_contratos).
