% cierre.pl (pruebas)
% T-26: como acaba un contrato. resultado/3 (exito, a medias o fracaso segun contadores y marcas),
% sus consecuencias, el cobro automatico al llegar a la taberna, el combate que empieza al llegar
% a la zona de un contrato activo, y los efectos de estado nuevos (contrato_resolver,
% contrato_cobrar, contar, borrar_contador).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/cierre -g "run_tests,halt" -t "halt(1)"

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

moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

% Pone un contrato como activo y lo resuelve con el resultado dado (aplica sus efectos reales).
resuelve(C, Res) :-
    aplicar_efecto(contrato_aceptar(C)),
    contratos:efectos_resolucion(C, Res, Efs),
    aplicar_efectos(Efs).

% Ataca hasta que el combate acabe (o se acabe la paciencia).
pelea_hasta_el_final(0) :- !.
pelea_hasta_el_final(N) :-
    (   ( \+ estado:en_combate(_) ; estado:fin_partida(_) )
    ->  true
    ;   (   member(Obj, [rata_quesera, bandido_montado, bandido_torpe, moho_saltarin, gran_roquefort]),
            ordena(atacar(Obj), I), \+ I = [error(_)|_]
        ->  true
        ;   ordena(defender, _)
        ),
        N1 is N - 1,
        pelea_hasta_el_final(N1)
    ).

:- begin_tests(efectos_del_ciclo).

test(resolver_con_exito_deja_el_contrato_por_cobrar, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_resolver(ratas_del_granero, exito)),
    \+ estado:contrato_activo(ratas_del_granero),
    estado:contrato_por_cobrar(ratas_del_granero, exito).

test(resolver_a_medias_tambien_queda_por_cobrar, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_resolver(ratas_del_granero, a_medias)),
    estado:contrato_por_cobrar(ratas_del_granero, a_medias).

test(resolver_con_fracaso_lo_cierra_sin_nada_que_cobrar, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    aplicar_efecto(contrato_resolver(gato_en_el_arbol, fracaso)),
    estado:contrato_cerrado(gato_en_el_arbol, fracaso),
    \+ estado:contrato_por_cobrar(gato_en_el_arbol, _),
    \+ estado:contrato_activo(gato_en_el_arbol).

test(solo_se_resuelve_lo_que_esta_activo, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_resolver(ratas_del_granero, exito)).

test(no_se_resuelve_dos_veces, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_resolver(ratas_del_granero, exito)),
    aplicar_efecto(contrato_resolver(ratas_del_granero, exito)).

test(un_resultado_desconocido_no_vale_y_no_toca_nada, [setup(nueva_partida)]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    foto_estado(Antes),
    \+ aplicar_efecto(contrato_resolver(ratas_del_granero, empate)),
    foto_estado(Despues),
    Antes == Despues.

test(cobrar_pasa_de_por_cobrar_a_cerrado, [setup(nueva_partida), nondet]) :-
    assertz(estado:contrato_por_cobrar(ratas_del_granero, a_medias)),
    aplicar_efecto(contrato_cobrar(ratas_del_granero)),
    \+ estado:contrato_por_cobrar(ratas_del_granero, _),
    estado:contrato_cerrado(ratas_del_granero, a_medias).

test(no_se_cobra_lo_que_no_esta_por_cobrar, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_cobrar(ratas_del_granero)).

test(no_se_cobra_dos_veces, [setup(nueva_partida), fail]) :-
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    aplicar_efecto(contrato_cobrar(ratas_del_granero)),
    aplicar_efecto(contrato_cobrar(ratas_del_granero)).

test(contar_crea_y_suma, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contar(quesos_robados, 1)),
    estado:contador(quesos_robados, 1),
    aplicar_efecto(contar(quesos_robados, 2)),
    estado:contador(quesos_robados, 3).

test(contar_deja_un_solo_hecho, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 1)),
    aplicar_efecto(contar(golpes_a_clotilde, 1)),
    findall(V, estado:contador(golpes_a_clotilde, V), Vs),
    Vs == [2].

test(contar_exige_un_numero_positivo, [setup(nueva_partida)]) :-
    \+ aplicar_efecto(contar(x, 0)),
    \+ aplicar_efecto(contar(x, -1)),
    \+ aplicar_efecto(contar(x, mucho)),
    \+ aplicar_efecto(contar(_, 1)),
    \+ estado:contador(x, _).

test(borrar_un_contador, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(quesos_robados, 5)),
    aplicar_efecto(borrar_contador(quesos_robados)),
    \+ estado:contador(quesos_robados, _).

test(borrar_lo_que_no_existe_no_falla, [setup(nueva_partida)]) :-
    aplicar_efecto(borrar_contador(quesos_robados)).

test(borrar_solo_borra_ese_contador, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contar(quesos_robados, 5)),
    aplicar_efecto(contar(golpes_a_clotilde, 2)),
    aplicar_efecto(borrar_contador(quesos_robados)),
    estado:contador(golpes_a_clotilde, 2).

test(una_transaccion_deshace_resolver, [setup(nueva_partida)]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    foto_estado(Antes),
    \+ con_transaccion(( aplicar_efecto(contrato_resolver(ratas_del_granero, exito)), fail )),
    foto_estado(Despues),
    Antes == Despues.

test(nueva_partida_borra_contadores_y_cobros, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(quesos_robados, 5)),
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    nueva_partida,
    \+ estado:contador(_, _),
    \+ estado:contrato_por_cobrar(_, _).

:- end_tests(efectos_del_ciclo).

:- begin_tests(resultado).

test(las_ratas_sin_robos_son_un_exito, [nondet]) :-
    contratos:resultado(ratas_del_granero, [], R),
    R == exito.

test(las_ratas_con_tres_robos_siguen_siendo_exito, [nondet]) :-
    contratos:resultado(ratas_del_granero, [contador(quesos_robados, 3)], R),
    R == exito.

test(las_ratas_con_cuatro_robos_son_a_medias, [nondet]) :-
    contratos:resultado(ratas_del_granero, [contador(quesos_robados, 4)], R),
    R == a_medias.

test(un_contador_ajeno_no_afecta, [nondet]) :-
    contratos:resultado(ratas_del_granero, [contador(golpes_a_clotilde, 9)], R),
    R == exito.

test(la_gallina_con_cero_o_dos_golpes_es_exito, [nondet]) :-
    contratos:resultado(gallina_noble, [contador(golpes_a_clotilde, 0)], R0),
    contratos:resultado(gallina_noble, [contador(golpes_a_clotilde, 2)], R2),
    R0 == exito, R2 == exito.

test(la_gallina_con_tres_o_cuatro_golpes_es_a_medias, [nondet]) :-
    contratos:resultado(gallina_noble, [contador(golpes_a_clotilde, 3)], R3),
    contratos:resultado(gallina_noble, [contador(golpes_a_clotilde, 4)], R4),
    R3 == a_medias, R4 == a_medias.

test(la_gallina_con_cinco_golpes_fracasa, [nondet]) :-
    contratos:resultado(gallina_noble, [contador(golpes_a_clotilde, 5)], R),
    R == fracaso.

test(el_gato_bajado_con_arte_es_exito, [nondet]) :-
    contratos:resultado(gato_en_el_arbol, [marca(gato_bajado_con_arte)], R),
    R == exito.

test(el_gato_bajado_a_golpes_es_a_medias, [nondet]) :-
    contratos:resultado(gato_en_el_arbol, [marca(gato_bajado_a_golpes)], R),
    R == a_medias.

test(si_hay_las_dos_marcas_gana_la_primera_resolucion, [nondet]) :-
    contratos:resultado(gato_en_el_arbol, [marca(gato_bajado_a_golpes), marca(gato_bajado_con_arte)], R),
    R == exito.

test(el_gato_sin_marcas_fracasa, [nondet]) :-
    contratos:resultado(gato_en_el_arbol, [], R),
    R == fracaso.

test(la_despensa_real_siempre_es_exito, [nondet]) :-
    contratos:resultado(despensa_real, [], R),
    R == exito.

test(un_contrato_desconocido_no_tiene_resultado, [fail]) :-
    contratos:resultado(dragon, [], _).

test(cada_contrato_tiene_un_unico_resultado_por_contexto) :-
    forall(( contratos:contrato(C, _, _, _, _),
             member(Ctx, [[], [contador(quesos_robados, 9)], [contador(golpes_a_clotilde, 9)],
                          [marca(gato_bajado_con_arte)], [contador(golpes_a_clotilde, 3)]]) ),
           (   findall(R, contratos:resultado(C, Ctx, R), Rs), Rs = [_] )).

test(el_contexto_recoge_contadores_y_marcas, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(quesos_robados, 2)),
    aplicar_efecto(marcar(gato_bajado_con_arte)),
    contratos:contexto(Ctx),
    memberchk(contador(quesos_robados, 2), Ctx),
    memberchk(marca(gato_bajado_con_arte), Ctx),
    memberchk(marca(sueldos_pagados), Ctx).

test(el_resultado_sale_del_estado_real, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contar(quesos_robados, 4)),
    contratos:contexto(Ctx),
    contratos:resultado(ratas_del_granero, Ctx, R),
    R == a_medias.

test(resultado_no_modifica_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    contratos:contexto(Ctx),
    forall(contratos:contrato(C, _, _, _, _), ( contratos:resultado(C, Ctx, _) -> true ; true )),
    foto_estado(Despues),
    Antes == Despues.

test(solve_da_lo_mismo_que_ejecutar_el_resultado) :-
    forall(( contratos:contrato(C, _, _, _, _),
             member(Ctx, [[], [contador(quesos_robados, 9)], [contador(golpes_a_clotilde, 4)],
                          [contador(golpes_a_clotilde, 7)], [marca(gato_bajado_a_golpes)],
                          [marca(gato_bajado_con_arte)]]) ),
           (   findall(R, contratos:resultado(C, Ctx, R), Directo),
               findall(R, solve(contratos:resultado(C, Ctx, R), _), ConSolve),
               Directo == ConSolve
           )).

test(la_prueba_del_resultado_ensena_el_contador_y_la_comparacion, [nondet]) :-
    solve(contratos:resultado(ratas_del_granero, [contador(quesos_robados, 4)], _), P),
    explicar:prueba_a_lineas(P, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'cumple_resolucion([contador_max(quesos_robados, 3)]') )).

:- end_tests(resultado).

:- begin_tests(consecuencias).

test(cada_resolucion_tiene_su_consecuencia) :-
    forall(contratos:resolucion(C, R, _), contratos:consecuencia(C, R, _)).

test(solo_hay_consecuencias_de_resultados_posibles) :-
    forall(contratos:consecuencia(C, R, _), contratos:resolucion(C, R, _)).

test(los_terminos_de_las_consecuencias_son_del_vocabulario) :-
    forall(( contratos:consecuencia(_, _, Efs), member(E, Efs) ),
           memberchk(E, [cobrar(todo), cobrar(mitad), cobrar(quesos(_)), cobrar(objetos), moral(_, _),
                         marcar(_), perder_queso(_), equipar(_, _)])).

test(un_fracaso_nunca_cobra) :-
    forall(( contratos:consecuencia(_, fracaso, Efs), member(E, Efs) ), \+ E = cobrar(_)).

test(las_cantidades_acordadas, [nondet]) :-
    contratos:consecuencia(ratas_del_granero, a_medias, A),
    A == [cobrar(quesos(5)), cobrar(objetos)],
    contratos:consecuencia(gallina_noble, fracaso, F),
    F == [perder_queso(3), moral(grupo, -2)],
    contratos:consecuencia(gato_en_el_arbol, fracaso, G),
    G == [moral(grupo, -1)].

test(el_gato_entrega_la_venda_en_exito_y_a_medias, [nondet]) :-
    contratos:consecuencia(gato_en_el_arbol, exito, E),
    contratos:consecuencia(gato_en_el_arbol, a_medias, M),
    memberchk(equipar(baldomero, venda_de_caballos), E),
    memberchk(equipar(baldomero, venda_de_caballos), M).

test(solo_la_gallina_recomienda, [nondet]) :-
    findall(C, ( contratos:consecuencia(C, _, Efs), memberchk(marcar(recomendada_por_clotilde), Efs) ), Cs),
    sort(Cs, S),
    S == [gallina_noble].

test(los_contadores_son_de_ratas_y_gallina) :-
    contratos:contadores_de(ratas_del_granero, [quesos_robados]),
    contratos:contadores_de(gallina_noble, [golpes_a_clotilde]),
    \+ contratos:contadores_de(gato_en_el_arbol, _).

:- end_tests(consecuencias).

:- begin_tests(efectos_de_resolucion).

test(empieza_por_resolver_y_limpiar_la_marca_del_combate, [setup(nueva_partida), nondet]) :-
    contratos:efectos_resolucion(ratas_del_granero, exito, Efs),
    Efs = [contrato_resolver(ratas_del_granero, exito), desmarcar(combate_de(ratas_del_granero)),
           mensaje(contrato_resuelto, [ratas_del_granero, exito])|_].

test(el_exito_de_las_ratas_sube_la_moral_de_los_activos, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(dano(tuerca, 99)),
    contratos:efectos_resolucion(ratas_del_granero, exito, Efs),
    memberchk(mod_moral(baldomero, 1), Efs),
    memberchk(mod_moral(pimentina, 1), Efs),
    memberchk(mod_moral(rufino, 1), Efs),
    \+ memberchk(mod_moral(tuerca, _), Efs).

test(no_cobra_ni_equipa_al_resolver, [setup(nueva_partida)]) :-
    forall(( contratos:consecuencia(C, R, _), contratos:efectos_resolucion(C, R, Efs) ),
           (   \+ memberchk(ganar_queso(_, _, _), Efs),
               \+ memberchk(ganar_objeto(_, _, _), Efs),
               \+ memberchk(equipar(_, _), Efs),
               \+ memberchk(contrato_cobrar(_), Efs)
           )).

test(un_fracaso_de_la_gallina_pierde_tres_quesos_y_moral, [setup(nueva_partida), nondet]) :-
    contratos:efectos_resolucion(gallina_noble, fracaso, Efs),
    findall(N, member(gastar_queso(_, _, N), Efs), Ns),
    sumlist(Ns, Total),
    Total == 3,
    memberchk(mod_moral(baldomero, -2), Efs).

test(perder_queso_se_limita_a_lo_que_hay, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 11)),      % queda 1
    contratos:efectos_resolucion(gallina_noble, fracaso, Efs),
    findall(N, member(gastar_queso(_, _, N), Efs), Ns),
    sumlist(Ns, Total),
    Total == 1.

test(perder_queso_empieza_por_lo_mas_rancio, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(ganar_queso(brie, 7, 2)),
    aplicar_efecto(ganar_queso(cheddar, 12, 1)),
    contratos:efectos_resolucion(gallina_noble, fracaso, Efs),
    Efs = [_, _, _|Resto],
    Resto = [gastar_queso(cheddar, 12, 1)|_].

test(el_a_medias_del_gato_pierde_un_queso, [setup(nueva_partida), nondet]) :-
    contratos:efectos_resolucion(gato_en_el_arbol, a_medias, Efs),
    findall(N, member(gastar_queso(_, _, N), Efs), Ns),
    Ns == [1].

test(aplicar_la_resolucion_deja_el_contrato_por_cobrar, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    estado:contrato_por_cobrar(ratas_del_granero, exito),
    \+ estado:contrato_activo(ratas_del_granero).

test(resolver_no_paga_nada_todavia, [setup(nueva_partida), nondet]) :-
    economia:queso_total(Antes),
    resuelve(ratas_del_granero, exito),
    economia:queso_total(Despues),
    Antes == Despues,
    \+ estado:lleva(compania, pocion, _).

test(resolver_sube_la_moral_de_verdad, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    estado:moral(baldomero, 7).

test(la_moral_no_pasa_de_diez, [setup(nueva_partida), nondet]) :-
    forall(compania:miembro(Id), moral_a(Id, 10)),
    resuelve(ratas_del_granero, exito),
    estado:moral(baldomero, 10).

test(el_gato_fracasado_baja_la_moral_y_queda_para_otro_intento, [setup(nueva_partida), nondet]) :-
    resuelve(gato_en_el_arbol, fracaso),
    estado:moral(baldomero, 5),
    contratos:puede_aceptar(gato_en_el_arbol).

test(los_efectos_de_resolucion_no_modifican_el_estado, [setup(nueva_partida)]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    foto_estado(Antes),
    forall(contratos:consecuencia(C, R, _), contratos:efectos_resolucion(C, R, _)),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(efectos_de_resolucion).

:- begin_tests(cobro).

test(sin_nada_por_cobrar_no_hay_cobro, [setup(nueva_partida)]) :-
    contratos:efectos_cobro(Efs),
    Efs == [].

test(cobro_de_las_ratas_con_exito, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(ratas_del_granero, exito, Efs),
    Efs == [ganar_queso(cheddar, 0, 9), ganar_objeto(compania, pocion, 1),
            contrato_cobrar(ratas_del_granero), mensaje(cobra, [ratas_del_granero])].

test(cobro_de_las_ratas_a_medias, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(ratas_del_granero, a_medias, Efs),
    Efs == [ganar_queso(cheddar, 0, 5), ganar_objeto(compania, pocion, 1),
            contrato_cobrar(ratas_del_granero), mensaje(cobra, [ratas_del_granero])].

test(cobro_del_gato_con_exito_equipa_la_venda, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(gato_en_el_arbol, exito, Efs),
    Efs == [ganar_queso(cheddar, 0, 7), ganar_objeto(compania, venda_de_caballos, 1),
            equipar(baldomero, venda_de_caballos),
            contrato_cobrar(gato_en_el_arbol), mensaje(cobra, [gato_en_el_arbol])].

test(cobro_del_gato_a_medias, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(gato_en_el_arbol, a_medias, Efs),
    Efs == [ganar_queso(cheddar, 0, 5), ganar_objeto(compania, venda_de_caballos, 1),
            equipar(baldomero, venda_de_caballos),
            contrato_cobrar(gato_en_el_arbol), mensaje(cobra, [gato_en_el_arbol])].

test(cobro_de_la_gallina_con_exito, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(gallina_noble, exito, Efs),
    Efs == [ganar_queso(cheddar, 0, 14), ganar_queso(brie, 0, 1),
            contrato_cobrar(gallina_noble), mensaje(cobra, [gallina_noble])].

test(cobro_de_la_gallina_a_medias_es_la_mitad_sin_brie, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(gallina_noble, a_medias, Efs),
    Efs == [ganar_queso(cheddar, 0, 7),
            contrato_cobrar(gallina_noble), mensaje(cobra, [gallina_noble])].

test(cobro_de_la_despensa_real, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(despensa_real, exito, Efs),
    Efs == [ganar_queso(cheddar, 0, 40), contrato_cobrar(despensa_real), mensaje(cobra, [despensa_real])].

test(el_cobro_junta_todos_los_pendientes_en_orden_de_catalogo, [setup(nueva_partida)]) :-
    assertz(estado:contrato_por_cobrar(gallina_noble, exito)),
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    contratos:efectos_cobro(Efs),
    findall(C, member(contrato_cobrar(C), Efs), Cs),
    Cs == [ratas_del_granero, gallina_noble].

test(aplicar_el_cobro_paga_y_cierra, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    economia:queso_total(Antes),
    contratos:efectos_cobro(Efs),
    aplicar_efectos(Efs),
    economia:queso_total(Despues),
    Despues =:= Antes + 9,
    estado:lleva(compania, pocion, 1),
    estado:contrato_cerrado(ratas_del_granero, exito),
    \+ estado:contrato_por_cobrar(_, _).

test(despues_de_cobrar_no_hay_nada_mas_que_cobrar, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    contratos:efectos_cobro(Efs),
    aplicar_efectos(Efs),
    contratos:efectos_cobro(Otros),
    Otros == [].

test(el_cobro_del_gato_equipa_la_venda_y_desbloquea_a_la_gallina, [setup(nueva_partida), nondet]) :-
    \+ contratos:puede_aceptar(gallina_noble),
    resuelve(gato_en_el_arbol, exito),
    contratos:efectos_cobro(Efs),
    aplicar_efectos(Efs),
    estado:equipado(baldomero, venda_de_caballos),
    contratos:puede_aceptar(gallina_noble).

test(cobrar_cuenta_para_la_despensa_real, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    resuelve(gato_en_el_arbol, a_medias),
    resuelve(gallina_noble, a_medias),
    contratos:contratos_cumplidos(N),
    N == 3.

test(el_cobro_no_modifica_el_estado, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    foto_estado(Antes),
    contratos:efectos_cobro(_),
    foto_estado(Despues),
    Antes == Despues.

test(un_resultado_sin_consecuencia_no_se_cobra, [setup(nueva_partida), fail]) :-
    contratos:efectos_cobro_de(ratas_del_granero, fracaso, _).

:- end_tests(cobro).

:- begin_tests(empezar_el_objetivo).

test(con_el_contrato_activo_el_combate_de_las_ratas_espera_en_la_aldea, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    contratos:objetivo_pendiente(aldea, C, G),
    C == ratas_del_granero,
    G == [rata_quesera, rata_quesera].

test(sin_aceptar_no_hay_objetivo, [setup(nueva_partida), fail]) :-
    contratos:objetivo_pendiente(aldea, _, _).

test(en_otra_zona_no_hay_objetivo, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    contratos:objetivo_pendiente(bosque, _, _).

test(un_evento_no_es_un_objetivo_de_combate, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    contratos:objetivo_pendiente(aldea, gato_en_el_arbol, _).

test(si_el_combate_ya_empezo_no_vuelve_a_empezar, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(marcar(combate_de(ratas_del_granero))),
    contratos:objetivo_pendiente(aldea, _, _).

test(la_escolta_espera_en_el_camino_real, [setup(nueva_partida), nondet]) :-
    assertz(estado:contrato_activo(gallina_noble)),
    contratos:objetivo_pendiente(camino_real, gallina_noble, G),
    G == [bandido_torpe, bandido_torpe, bandido_montado].

test(los_efectos_de_inicio_ponen_los_contadores_a_cero_y_marcan, [setup(nueva_partida), nondet]) :-
    contratos:efectos_inicio_objetivo(ratas_del_granero, Efs),
    Efs == [borrar_contador(quesos_robados), marcar(combate_de(ratas_del_granero)),
            mensaje(objetivo, [ratas_del_granero])].

test(un_contrato_sin_contadores_solo_se_marca, [setup(nueva_partida), nondet]) :-
    contratos:efectos_inicio_objetivo(despensa_real, Efs),
    Efs == [marcar(combate_de(despensa_real)), mensaje(objetivo, [despensa_real])].

test(los_efectos_de_inicio_no_modifican_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    contratos:efectos_inicio_objetivo(ratas_del_granero, _),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(empezar_el_objetivo).

:- begin_tests(el_ciclo_jugando).

test(llegar_a_la_aldea_con_las_ratas_activas_empieza_el_combate) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), Items),
    memberchk(msg(objetivo, [ratas_del_granero], _), Items),
    memberchk(msg(aparece, [rata_quesera], _), Items),
    once(estado:fase(F)),
    F == combate,
    estado:marca(combate_de(ratas_del_granero)).

test(sin_aceptar_nada_llegar_a_la_aldea_no_empieza_combate) :-
    nueva_partida,
    ordena(ir(aldea), Items),
    \+ memberchk(msg(objetivo, _, _), Items),
    once(estado:fase(F)),
    F == exploracion.

test(llegar_pone_a_cero_los_contadores_viejos) :-
    nueva_partida,
    aplicar_efecto(contar(quesos_robados, 7)),
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    \+ estado:contador(quesos_robados, _).

test(ganar_el_combate_resuelve_el_contrato, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    \+ estado:en_combate(_),
    estado:contrato_por_cobrar(ratas_del_granero, exito),
    \+ estado:contrato_activo(ratas_del_granero),
    \+ estado:marca(combate_de(_)).

test(al_ganar_se_avisa_del_resultado, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pantalla(atacar(rata_quesera), T1),
    pantalla(atacar(rata_quesera), T2),
    pantalla(atacar(rata_quesera), T3),
    atomic_list_concat([T1, T2, T3], Texto),
    sub_atom(Texto, _, _, _, 'Contrato resuelto con éxito: «Ratas del Granero»').

test(las_ratas_que_roban_mucho_dejan_el_contrato_a_medias, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    aplicar_efecto(contar(quesos_robados, 4)),
    pelea_hasta_el_final(30),
    estado:contrato_por_cobrar(ratas_del_granero, a_medias).

test(las_ratas_reales_cuentan_sus_robos, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),     % hasta que actuan las ratas
    estado:contador(quesos_robados, N),
    N >= 1.

test(volver_a_la_taberna_cobra_solo, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    economia:queso_total(Antes),
    ordena(ir(taberna), Items),
    memberchk(msg(cobra, [ratas_del_granero], _), Items),
    estado:contrato_cerrado(ratas_del_granero, exito),
    estado:lleva(compania, pocion, 1),
    economia:queso_total(Despues),
    Despues >= Antes + 9 - 4.                          % +9 de la recompensa, - la racion del viaje

test(no_se_cobra_hasta_llegar_a_la_taberna, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    estado:contrato_por_cobrar(ratas_del_granero, exito),
    \+ estado:lleva(compania, pocion, _),
    ordena(ir(bosque), _),
    estado:contrato_por_cobrar(ratas_del_granero, exito).

test(no_se_cobra_dos_veces, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    ordena(ir(taberna), _),
    ordena(ir(aldea), _),
    ordena(ir(taberna), Items),
    \+ memberchk(msg(cobra, _, _), Items),
    estado:lleva(compania, pocion, 1).

test(el_contrato_cumplido_no_vuelve_a_empezar_el_combate) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    ordena(ir(taberna), _),
    ordena(ir(aldea), Items),
    \+ memberchk(msg(objetivo, _, _), Items),
    once(estado:fase(F)),
    F == exploracion.

test(el_tablon_pasa_de_activo_a_por_cobrar_y_a_cumplido, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(contratos, [vista(contratos, F1)]),
    memberchk(contrato(ratas_del_granero, _, _, _, activo), F1),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    ordena(contratos, [vista(contratos, F2)]),
    memberchk(contrato(ratas_del_granero, _, _, _, por_cobrar), F2),
    ordena(ir(taberna), _),
    ordena(contratos, [vista(contratos, F3)]),
    memberchk(contrato(ratas_del_granero, _, _, _, cumplido), F3).

test(llegar_con_la_despensa_vacia_pero_con_un_cobro_no_acaba_la_partida, [nondet]) :-
    nueva_partida,
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    ordena(ir(aldea), _),
    \+ estado:fin_partida(_),
    ordena(ir(taberna), _),
    \+ estado:fin_partida(_),
    economia:queso_total(N),
    N >= 9 - 4.

test(si_la_partida_acaba_al_llegar_el_objetivo_no_empieza, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),       % sin queso y sin nada que cobrar: hambre
    ordena(ir(aldea), Items),
    memberchk(msg(fin_hambre, [], _), Items),
    \+ memberchk(msg(objetivo, _, _), Items),
    \+ estado:en_combate(_),
    estado:fin_partida(derrota(derrota_hambre)).

test(explicar_tras_resolver_ensena_el_resultado, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(ir(aldea), _),
    pelea_hasta_el_final(30),
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == resultado(ratas_del_granero).

test(perder_el_combate_del_contrato_acaba_la_partida_sin_resolver, [nondet]) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    assertz(estado:contrato_activo(gallina_noble)),
    forall(compania:miembro(M), ( M == baldomero -> true ; aplicar_efecto(dano(M, 99)) )),
    aplicar_efecto(dano(baldomero, 29)),               % solo Baldomero, con 1 de vida
    ordena(ir(camino_real), _),
    pelea_hasta_el_final(30),
    estado:fin_partida(derrota(derrota_combate)),
    estado:contrato_activo(gallina_noble),
    \+ estado:contrato_por_cobrar(_, _).

test(la_escolta_se_juega_como_un_combate_de_contrato, [nondet]) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(aceptar(gallina_noble), _),                  % se acepta en el tablon de la taberna
    ordena(ir(camino_real), Items),
    memberchk(msg(objetivo, [gallina_noble], _), Items),
    estado:instancia(e(bandido_montado, 1), bandido_montado),
    estado:instancia(e(bandido_torpe, 2), bandido_torpe).

:- end_tests(el_ciclo_jugando).

:- begin_tests(las_pantallas_del_cierre).

test(el_tablon_muestra_por_cobrar, [setup(nueva_partida), nondet]) :-
    resuelve(ratas_del_granero, exito),
    pantalla(contratos, Texto),
    sub_atom(Texto, _, _, _, '[por_cobrar] Ratas del Granero').

test(se_narra_el_cobro, [nondet]) :-
    nueva_partida,
    resuelve(ratas_del_granero, exito),
    ordena(ir(aldea), _),
    pantalla(ir(taberna), Texto),
    sub_atom(Texto, _, _, _, 'Cobráis por «Ratas del Granero»').

test(se_narran_los_tres_resultados, [setup(nueva_partida), nondet]) :-
    forall(member(R-Trozo, [exito-'resuelto con éxito', a_medias-'resuelto a medias', fracaso-'fracasado']),
           (   narrador:texto(contrato_resuelto, [ratas_del_granero, R], 0, T),
               sub_atom(T, _, _, _, Trozo)
           )).

test(ninguna_pantalla_del_ciclo_ensena_terminos_crudos, [nondet]) :-
    nueva_partida,
    forall(member(Cmd, [aceptar(ratas_del_granero), contratos, ir(aldea), atacar(rata_quesera),
                        atacar(rata_quesera), atacar(rata_quesera), contratos, explicar, ir(taberna),
                        contratos, inventario, compania]),
           (   pantalla(Cmd, Texto),
               \+ sub_atom(Texto, _, _, _, 'msg('),
               \+ sub_atom(Texto, _, _, _, 'error('),
               \+ sub_atom(Texto, _, _, _, '[msg'),
               \+ sub_atom(Texto, _, _, _, '~w')
           )).

:- end_tests(las_pantallas_del_cierre).
