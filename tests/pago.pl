% pago.pl (pruebas)
% El pago de los contratos se DERIVA de lo que cuesta hacerlos (docs/11-balance.md): cada dia de viaje cuesta una
% racion entera, asi que
%   pago = max(minimo, base + por_dia * dias_de_ruta + por_enemigo * enemigos)
% (1) la distancia entre zonas; (2) los dias de ruta y los enemigos de cada contrato; (3) la formula sola con
% otros numeros; (4) lo que sale de ella (14 / 12 / 21 y el jefe, que sigue en 40) y que SIEMPRE compensa el viaje;
% (5) que el tablon y el cobro usan el numero ya resuelto; (6) que el juego sigue siendo ganable.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/pago -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/contratos').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../herramientas/simulador').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

:- begin_tests(la_distancia).

test(un_paso_cuesta_un_dia) :-
    mundo:distancia(taberna, aldea, D1), assertion(D1 == 1),
    mundo:distancia(taberna, camino_real, D2), assertion(D2 == 1),
    mundo:distancia(camino_real, castillo, D3), assertion(D3 == 1).

test(el_camino_mas_corto_no_el_primero) :-
    mundo:distancia(taberna, castillo, D1), assertion(D1 == 2),
    mundo:distancia(taberna, cuevas, D2), assertion(D2 == 2),
    mundo:distancia(aldea, camino_real, D3), assertion(D3 == 2).     % por la taberna o por el bosque

test(la_distancia_es_simetrica) :-
    forall(( mundo:zona(A, _), mundo:zona(B, _) ),
           (   mundo:distancia(A, B, D1), mundo:distancia(B, A, D2), assertion(D1 == D2) )).

test(de_una_zona_a_si_misma_es_cero) :-
    mundo:distancia(bosque, bosque, D), assertion(D == 0).

test(una_zona_que_no_existe_no_tiene_distancia) :-
    assertion(\+ mundo:distancia(taberna, la_luna, _)).

test(todas_las_zonas_son_alcanzables_desde_la_taberna) :-
    forall(mundo:zona(Z, _), assertion(mundo:distancia(taberna, Z, _))).

:- end_tests(la_distancia).

:- begin_tests(lo_que_cuesta_cada_contrato).

test(los_dias_de_ruta) :-
    forall(member(C-Esperados, [ratas_del_granero-2, gato_en_el_arbol-2, gallina_noble-4, despensa_real-4]),
           (   contratos:dias_de_ruta(C, D), assertion(D == Esperados) )).

test(la_escolta_cuenta_ir_llevar_y_volver) :-
    % taberna -> camino real (1), camino real -> castillo (1), castillo -> taberna (2)
    contratos:dias_de_ruta(gallina_noble, D), assertion(D == 4).

test(los_enemigos_de_cada_contrato) :-
    forall(member(C-Esperados, [ratas_del_granero-2, gato_en_el_arbol-0, gallina_noble-3, despensa_real-1]),
           (   contratos:enemigos_del_contrato(C, N), assertion(N == Esperados) )).

:- end_tests(lo_que_cuesta_cada_contrato).

:- begin_tests(la_formula).

test(suma_base_dias_y_enemigos) :-
    contratos:formula_de_pago(parametros(6, 3, 1, 0), 2, 2, Q), assertion(Q == 14).

test(cada_termino_cuenta) :-
    contratos:formula_de_pago(parametros(0, 0, 0, 0), 5, 5, Q0), assertion(Q0 == 0),
    contratos:formula_de_pago(parametros(7, 0, 0, 0), 5, 5, Q1), assertion(Q1 == 7),
    contratos:formula_de_pago(parametros(0, 2, 0, 0), 5, 5, Q2), assertion(Q2 == 10),
    contratos:formula_de_pago(parametros(0, 0, 3, 0), 5, 5, Q3), assertion(Q3 == 15).

test(el_minimo_manda_cuando_lo_calculado_es_menos) :-
    contratos:formula_de_pago(parametros(4, 3, 1, 12), 2, 0, Q), assertion(Q == 12).

test(el_minimo_no_recorta_lo_que_ya_es_mas) :-
    contratos:formula_de_pago(parametros(6, 3, 1, 12), 4, 3, Q), assertion(Q == 21).

test(mas_dias_o_mas_enemigos_nunca_pagan_menos) :-
    P = parametros(6, 3, 1, 12),
    forall(( between(0, 6, D), between(0, 5, E), D1 is D + 1, E1 is E + 1 ),
           (   contratos:formula_de_pago(P, D, E, Q), contratos:formula_de_pago(P, D1, E, Qd),
               contratos:formula_de_pago(P, D, E1, Qe),
               assertion(Qd >= Q), assertion(Qe >= Q) )).

:- end_tests(la_formula).

:- begin_tests(lo_que_paga_el_catalogo).

test(los_pagos_de_la_formula) :-
    forall(member(C-Esperado, [ratas_del_granero-14, gato_en_el_arbol-12, gallina_noble-21]),
           (   contratos:pago_de(C, N), assertion(N == Esperado) )).

test(el_jefe_sigue_en_cuarenta_y_no_usa_la_formula) :-
    contratos:recompensa_de(despensa_real, R), assertion(R == [quesos(40)]),
    contratos:pago_de(despensa_real, Formula), assertion(Formula \== 40).

test(ningun_contrato_paga_menos_del_minimo) :-
    mundo:parametro(pago_minimo, Min),
    forall(( contratos:contrato(C, _, _, _, _), \+ contratos:contrato_final(C) ),
           (   contratos:pago_de(C, N), assertion(N >= Min) )).

test(el_minimo_es_doce) :-
    mundo:parametro(pago_minimo, M), assertion(M == 12).

test(cada_contrato_compensa_el_viaje_y_algo_mas) :-
    % cada dia de ruta come toda la Banda: si el pago no cubre eso, el contrato es perder queso
    nueva_partida, economia:racion_diaria(Racion),
    forall(( contratos:contrato(C, _, _, _, _), \+ contratos:contrato_final(C) ),
           (   contratos:pago_de(C, N), contratos:dias_de_ruta(C, D),
               Coste is Racion * D,
               assertion(N > Coste) )).

test(un_contrato_mas_lejano_o_peligroso_paga_mas) :-
    contratos:pago_de(ratas_del_granero, Ratas), contratos:pago_de(gallina_noble, Gallina),
    assertion(Gallina > Ratas).

test(los_dos_contratos_de_la_aldea_juntos_dejan_ganancia_neta) :-
    % ida y vuelta a la aldea = 2 dias = 8 quesos de ración, y los sueldos (5)
    contratos:pago_de(ratas_del_granero, A), contratos:pago_de(gato_en_el_arbol, B),
    assertion(A + B > 8 + 5).

:- end_tests(lo_que_paga_el_catalogo).

:- begin_tests(el_tablon_y_el_cobro).

test(el_catalogo_no_deja_escapar_el_marcador_pago) :-
    forall(contratos:contrato(C, _, _, _, _),
           (   contratos:recompensa_de(C, R), assertion(\+ memberchk(quesos(pago), R)) )).

test(la_ficha_trae_el_numero_ya_resuelto) :-
    nueva_partida,
    forall(( contratos:contrato(C, _, _, _, _), contratos:ficha(C, contrato(_, _, _, R, _)) ),
           assertion(\+ memberchk(quesos(pago), R))).

test(la_pantalla_del_tablon_no_ensena_el_marcador) :-
    nueva_partida, main:transcribir([contratos, salir], T),
    assertion(contiene(T, '14 quesos')), assertion(contiene(T, '12 quesos')),
    assertion(\+ contiene(T, 'quesos(pago)')), assertion(\+ contiene(T, 'quesos(')).

test(el_cobro_da_lo_que_paga_la_formula) :-
    nueva_partida,
    forall(member(C, [ratas_del_granero, gato_en_el_arbol, gallina_noble]),
           (   contratos:pago_de(C, N),
               contratos:efectos_cobro_de(C, exito, Efs),
               assertion(memberchk(ganar_queso(cheddar, 0, N), Efs)) )).

test(a_medias_se_cobra_la_mitad_de_lo_que_paga_la_formula) :-
    nueva_partida,
    forall(member(C, [ratas_del_granero, gato_en_el_arbol, gallina_noble]),
           (   contratos:pago_de(C, N), Mitad is N // 2,
               contratos:efectos_cobro_de(C, a_medias, Efs),
               assertion(memberchk(ganar_queso(cheddar, 0, Mitad), Efs)) )).

:- end_tests(el_tablon_y_el_cobro).

:- begin_tests(el_juego_sigue_siendo_ganable).

test(con_el_pago_nuevo_el_jugador_con_plan_gana_la_mayoria) :-
    findall(x, ( between(1, 20, I), S is 3000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gana),
    length(Gana, N), assertion(N >= 14).

test(sin_errores_se_gana_con_margen) :-
    findall(Q, ( between(1, 10, I), S is 4000 + I, episodio(plan(0, 2), S, 400, r(victoria, _, Q, _)) ), Qs),
    length(Qs, N), assertion(N == 10),
    sumlist(Qs, Total), Media is Total / N, assertion(Media >= 3).

:- end_tests(el_juego_sigue_siendo_ganable).
