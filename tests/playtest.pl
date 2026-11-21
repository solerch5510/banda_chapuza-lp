% playtest.pl (pruebas)
% T-36: el primer playtest guiado (PT-1), convertido en pruebas para que no se pierda lo aprendido.
% (1) La partida completa por la via "comoda" (los cuatro contratos, habilidades en cada turno) se
% juega por ejecutar/2 + ui:mostrar/1 como la veria el jugador: se gana, en pocos dias y pocos
% comandos, y NINGUNA pantalla ensena terminos crudos. (2) Las tres rutas degeneradas del plan
% (no pagar nunca, ignorar la comida, probar los contratos sin condiciones) acaban de forma
% razonable. (3) Los ajustes que salieron del playtest: el estado del combate tras cada orden, el
% mensaje del dia con la racion, las variantes que rotan de verdad y las pistas de por_que_no.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/playtest -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

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

% ---------------------------------------------------------------------------
% El jugador "comodo": cada orden se ejecuta y se muestra; se cuentan los comandos y se guarda lo visto.
% ---------------------------------------------------------------------------
:- dynamic visto/1, ordenes/1.

limpiar_playtest :-
    retractall(visto(_)),
    retractall(ordenes(_)),
    assertz(ordenes(0)).

orden(Cmd) :-
    retract(ordenes(N)), N1 is N + 1, assertz(ordenes(N1)),
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)),
    assertz(visto(Cmd-Texto)).

orden_y_combate(Cmd) :-
    orden(Cmd),
    combatir.

% En su turno cada miembro usa su habilidad si puede (contra el enemigo mas fuerte vivo) y, si no, ataca.
objetivo_fuerte(T) :-
    member(T, [gran_roquefort, bandido_montado, ganso_de_peaje, seta_belicosa, bandido_torpe, moho_saltarin, rata_quesera]),
    estado:instancia(E, T), compania:vivo(E), !.

orden_de_turno(Cmd) :-
    estado:cola_turnos([A|_]),
    mundo:habilidad_de(A, H),
    objetivo_fuerte(T),
    (   combate:objetivo_de_habilidad(H, ninguno)
    ->  Cmd = habilidad
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_habilidad(A, H, E)
    ->  Cmd = habilidad(T)
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_atacar(A, E)
    ->  Cmd = atacar(T)
    ;   Cmd = defender
    ).

combatir :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_turno(Cmd)),
        orden(Cmd),
        combatir
    ;   true
    ).

la_via_comoda :-
    nueva_partida,
    limpiar_playtest,
    orden(ayuda), orden(mirar), orden(contratos),
    orden_y_combate(aceptar(ratas_del_granero)),
    orden_y_combate(aceptar(gato_en_el_arbol)),
    orden_y_combate(ir(aldea)),
    orden(elegir(trepar)),
    orden_y_combate(ir(taberna)),
    orden(inventario), orden(pagar), orden(compania),
    orden_y_combate(ir(camino_real)),
    orden_y_combate(aceptar(gallina_noble)),
    orden_y_combate(aceptar(peaje_del_ganso)),
    orden_y_combate(ir(castillo)),
    orden_y_combate(aceptar(despensa_real)),
    orden_y_combate(ir(camino_real)),
    orden_y_combate(ir(cuevas)),
    orden(explicar).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

crudo(Texto) :-
    member(M, ['msg(', 'vista(', 'error(', 'resultado([', '~w', '[msg', '[error', 'fallo(', 'descarte(']),
    contiene(Texto, M), !.

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

% ---------------------------------------------------------------------------

:- begin_tests(la_via_comoda).

test(se_gana_con_el_final_chapuza, [setup(la_via_comoda), nondet]) :-
    estado:fin_partida(victoria(chapuza)).

test(se_gana_en_pocos_dias, [setup(la_via_comoda), nondet]) :-
    estado:dia(D), D =< 8.

test(se_gana_con_pocos_comandos, [setup(la_via_comoda), nondet]) :-
    ordenes(N), N =< 60.

test(no_se_acaba_sin_queso_negativo, [setup(la_via_comoda), nondet]) :-
    economia:queso_total(Q), Q >= 0.

test(los_cinco_contratos_del_camino_al_jefe_quedan_cumplidos, [setup(la_via_comoda), nondet]) :-
    forall(member(C, [ratas_del_granero, gato_en_el_arbol, gallina_noble, peaje_del_ganso, despensa_real]),
           contratos:contrato_cumplido(C)).

test(nadie_se_queda_en_huelga_ni_caido, [setup(la_via_comoda), nondet]) :-
    forall(compania:miembro(Id), ( compania:vivo(Id), \+ compania:esta_en_huelga(Id) )).

test(ninguna_pantalla_ensena_terminos_crudos, [setup(la_via_comoda), nondet]) :-
    forall(visto(Cmd-T), ( \+ crudo(T) -> true ; format("crudo en ~w~n", [Cmd]), fail )).

test(cada_orden_tiene_respuesta, [setup(la_via_comoda), nondet]) :-
    forall(visto(Cmd-T), ( atom_length(T, L), L > 0 -> true ; format("sin respuesta: ~w~n", [Cmd]), fail )).

test(ninguna_orden_de_la_via_comoda_da_error, [setup(la_via_comoda), nondet]) :-
    % los errores del juego tienen frases como "no puede" o "No hay"; la via comoda no pisa ninguno
    forall(visto(Cmd-T),
           (   member(M, ['no puede', 'No puedes', 'ahora mismo no', 'No hay ningún', 'No existe', 'No entiendo', 'Solo se puede']),
               contiene(T, M)
           ->  format("error en ~w: ~w~n", [Cmd, T]), fail
           ;   true
           )).

test(la_ultima_pantalla_es_la_del_final, [setup(la_via_comoda), nondet]) :-
    findall(T, visto(_-T), Ts),
    member(T, Ts), contiene(T, 'Fin de la partida.'), !.

test(la_partida_se_repite_igual, [nondet]) :-
    la_via_comoda, foto_estado(F1), findall(C-T, visto(C-T), V1),
    la_via_comoda, foto_estado(F2), findall(C-T, visto(C-T), V2),
    F1 =@= F2, V1 == V2.

:- end_tests(la_via_comoda).

:- begin_tests(rutas_degeneradas).

% Sin pagar la moral cae (y con ella, a veces, la huelga) y de tanto ir y venir sin ganar nada se acaba el
% queso: la ruta degenerada acaba sola en hambre, sin ningun error ni pantalla rara.
test(no_pagar_nunca_baja_la_moral_y_acaba_sin_romper_nada, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden_y_combate(aceptar(ratas_del_granero)), orden_y_combate(aceptar(gato_en_el_arbol)),
    orden_y_combate(ir(aldea)), orden(elegir(trepar)),
    orden_y_combate(ir(taberna)),
    forall(between(1, 3, _), ( orden(ir(aldea)), orden(ir(taberna)) )),
    estado:moral(baldomero, M), M < 7,
    forall(visto(_-T), \+ crudo(T)).

test(nunca_pagar_se_nota_en_la_pantalla, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden(ir(aldea)), orden(ir(taberna)), orden(ir(aldea)),
    visto(ir(aldea)-T), contiene(T, 'sin pagar los sueldos'), !.

test(ignorar_la_comida_acaba_en_hambre_y_se_cuenta, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden(descansar), orden(descansar), orden(ir(aldea)), orden(ir(taberna)),
    estado:fin_partida(derrota(derrota_hambre)),
    findall(T, visto(_-T), Ts),
    member(T, Ts), contiene(T, 'Sin ración'), !.

test(despues_del_final_todo_se_rechaza_con_buenas_palabras, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden(descansar), orden(descansar), orden(ir(aldea)), orden(ir(taberna)), orden(descansar),
    visto(descansar-T), contiene(T, 'La partida ha terminado'), !.

test(los_contratos_sin_condiciones_se_rechazan_y_se_pregunta_por_que, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden(aceptar(gallina_noble)), orden(aceptar(despensa_real)),
    visto(aceptar(gallina_noble)-T1), contiene(T1, 'por_que_no(aceptar(gallina_noble))'),
    orden(por_que_no(aceptar(gallina_noble))), orden(por_que_no(aceptar(despensa_real))),
    visto(por_que_no(aceptar(gallina_noble))-T2), contiene(T2, 'Lady Clotilde exige escolta'),
    visto(por_que_no(aceptar(despensa_real))-T3), contiene(T3, 'el rey no firma con desconocidos').

test(un_contrato_ya_aceptado_no_se_acepta_dos_veces, [setup(nueva_partida), nondet]) :-
    limpiar_playtest,
    orden(aceptar(ratas_del_granero)), orden(aceptar(ratas_del_granero)),
    findall(C, estado:contrato_activo(C), [ratas_del_granero]).

:- end_tests(rutas_degeneradas).

:- begin_tests(el_estado_del_combate).

en_combate_con(Tipos) :-
    nueva_partida, limpiar_playtest,
    comenzar_combate(Tipos, _).

test(al_empezar_se_ve_de_quien_es_el_turno, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe], Items),
    last(Items, vista(combate, combate(1, Turno, _))),
    Turno == baldomero.

test(cada_orden_deja_el_estado_al_final, [setup(en_combate_con([bandido_torpe, bandido_torpe])), nondet]) :-
    ejecutar(defender, resultado(Items)),
    last(Items, vista(combate, combate(_, _, Enemigos))),
    length(Enemigos, 2).

test(se_ve_la_vida_de_los_enemigos_en_pantalla, [setup(en_combate_con([bandido_torpe, bandido_torpe])), nondet]) :-
    orden(habilidad(bandido_torpe)),
    visto(_-T), contiene(T, 'Combate · ronda'), contiene(T, 'vida'), !.

test(al_ganar_ya_no_se_enseña_el_combate, [setup(en_combate_con([rata_quesera])), nondet]) :-
    combatir,
    \+ estado:en_combate(_),
    findall(T, visto(_-T), Ts),
    last(Ts, Ultima),
    \+ contiene(Ultima, 'Combate · ronda').

test(un_error_de_combate_no_lleva_el_estado, [setup(en_combate_con([bandido_torpe])), nondet]) :-
    ejecutar(atacar(dragon), resultado(Items)),
    Items = [error(_)].

test(el_estado_es_el_de_mirar, [setup(en_combate_con([bandido_torpe, rata_quesera])), nondet]) :-
    ejecutar(defender, resultado(Items)),
    last(Items, vista(combate, Datos)),
    ejecutar(mirar, resultado(Items2)),
    member(vista(combate, Datos2), Items2),
    Datos =@= Datos2.

:- end_tests(el_estado_del_combate).

:- begin_tests(el_dia_y_la_racion).

test(viajar_dice_el_dia_y_la_racion, [setup(nueva_partida), nondet]) :-
    ejecutar(ir(aldea), resultado(Items)),
    memberchk(msg(dia_nuevo, [2, 4], _), Items).

test(descansar_tambien_lo_dice, [setup(nueva_partida), nondet]) :-
    ejecutar(descansar, resultado(Items)),
    memberchk(msg(dia_nuevo, [2, 4], _), Items).

test(el_dia_va_subiendo, [setup(nueva_partida), nondet]) :-
    ejecutar(ir(aldea), resultado(I1)), ejecutar(ir(taberna), resultado(I2)),
    memberchk(msg(dia_nuevo, [2, _], _), I1),
    memberchk(msg(dia_nuevo, [3, _], _), I2).

test(con_menos_queso_la_racion_es_menor, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 10)),           % quedan 2 quesos
    ejecutar(ir(aldea), resultado(Items)),
    memberchk(msg(dia_nuevo, [_, N], _), Items),
    N < 4.

test(la_pantalla_dice_el_dia, [setup(nueva_partida), nondet]) :-
    ejecutar(ir(aldea), R),
    with_output_to(atom(T), ui:mostrar(R)),
    contiene(T, 'Día 2'),
    contiene(T, 'ración'), !.

test(un_error_no_gasta_un_dia, [setup(nueva_partida), nondet]) :-
    ejecutar(ir(castillo), resultado(Items)),
    Items = [error(_)],
    estado:dia(1).

test(un_dia_sin_comida_no_cuenta_raciones_de_mentira, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    ejecutar(ir(aldea), resultado(Items)),
    ( memberchk(msg(dia_nuevo, [_, 0], _), Items) ; memberchk(msg(sin_comida, _, _), Items) ), !.

:- end_tests(el_dia_y_la_racion).

:- begin_tests(las_variantes_rotan_de_verdad).

test(dos_cargas_seguidas_contra_otro_enemigo_no_dicen_lo_mismo, [setup(nueva_partida), nondet]) :-
    aplicar_efectos([iniciar_combate([bandido_torpe, bandido_torpe, bandido_torpe])]),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    ordena_habilidad(e(bandido_torpe, 1), T1),
    retractall(estado:cola_turnos(_)), assertz(estado:cola_turnos([baldomero, rufino])),
    ordena_habilidad(e(bandido_torpe, 2), T2),
    primera_linea(T1, L1), primera_linea(T2, L2),
    L1 \== L2.

primera_linea(Texto, Linea) :-
    atomic_list_concat([Linea|_], '
', Texto).

ordena_habilidad(Objetivo, Texto) :-
    ejecutar(habilidad(Objetivo), R),
    with_output_to(atom(Texto), ui:mostrar(R)).

test(el_contador_de_la_carga_es_uno_solo, [setup(nueva_partida), nondet]) :-
    estado:aplicar_efecto(iniciar_combate([bandido_torpe, bandido_montado])),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    ejecutar(habilidad(bandido_torpe), _),
    estado:usos_frase(carga_heroica, 1).

test(varias_victorias_distintas_rotan_la_frase, [setup(nueva_partida), nondet]) :-
    findall(T, ( between(0, 2, U), comentario(suceso(victoria), ambos, U, T) ), Ts),
    sort(Ts, U2), length(U2, 3).

test(cada_zona_rota_por_su_cuenta, [setup(nueva_partida), nondet]) :-
    ejecutar(ir(aldea), _),
    estado:usos_frase(llegada(aldea), 1),
    \+ estado:usos_frase(llegada(taberna), _).

test(el_grupo_de_un_golpe_no_depende_de_quien_golpea, [setup(nueva_partida), nondet]) :-
    juego:grupo_de(golpe, [baldomero, e(rata_quesera, 1), 3], G1),
    juego:grupo_de(golpe, [tuerca, e(bandido_torpe, 2), 9], G2),
    G1 == G2.

test(la_caida_si_depende_del_tipo_de_enemigo, [nondet]) :-
    juego:grupo_de(cae, [e(rata_quesera, 1)], G1),
    juego:grupo_de(cae, [e(bandido_torpe, 1)], G2),
    juego:grupo_de(cae, [baldomero], G3),
    juego:grupo_de(cae, [tuerca], G4),
    G1 \== G2, G3 == G4, G1 \== G3.

test(la_aparicion_del_jefe_tiene_su_propio_grupo, [nondet]) :-
    juego:grupo_de(aparece, [bandido_torpe], G1),
    juego:grupo_de(aparece, [gran_roquefort], G2),
    juego:grupo_de(aparece, [rata_quesera], G3),
    G1 \== G2, G1 \== G3.

test(las_tres_variantes_del_dia_dicen_el_dia_y_la_racion, [nondet]) :-
    forall(between(0, 2, U),
           (   comentario(suceso(dia_nuevo(5, 3)), ambos, U, T),
               contiene(T, '5'), contiene(T, '3 quesos')
           )).

test(la_llegada_depende_de_la_zona, [nondet]) :-
    juego:grupo_de(llegada, [aldea], G1),
    juego:grupo_de(llegada, [taberna], G2),
    G1 \== G2.

:- end_tests(las_variantes_rotan_de_verdad).

:- begin_tests(las_pistas_de_por_que_no).

pantalla(Cmd, T) :-
    ejecutar(Cmd, R),
    with_output_to(atom(T), ui:mostrar(R)).

test(aceptar_lo_imposible_dice_que_preguntes, [setup(nueva_partida), nondet]) :-
    pantalla(aceptar(gallina_noble), T),
    contiene(T, 'por_que_no(aceptar(gallina_noble))').

test(ir_a_donde_no_hay_camino_dice_que_preguntes, [setup(nueva_partida), nondet]) :-
    pantalla(ir(castillo), T),
    contiene(T, 'por_que_no(ir(castillo))').

test(descansar_sin_queso_dice_que_preguntes, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    ejecutar(descansar, resultado(Items)),
    Items = [error(no_puede_descansar)|_],
    pantalla(descansar, T),
    contiene(T, 'por_que_no(descansar)').

test(pagar_sin_queso_dice_que_preguntes, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    aplicar_efecto(desmarcar(sueldos_pagados)),
    pantalla(pagar, T),
    contiene(T, 'por_que_no(pagar)').

test(la_pista_apunta_a_una_orden_que_funciona, [setup(nueva_partida), nondet]) :-
    ejecutar(por_que_no(aceptar(gallina_noble)), resultado([vista(diag, _, _)])),
    ejecutar(por_que_no(ir(castillo)), resultado([vista(diag, _, _)])).

test(en_combate_un_ataque_imposible_tambien_lo_dice, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_montado], _),
    pantalla(atacar(bandido_montado), T),
    contiene(T, 'por_que_no(atacar').

:- end_tests(las_pistas_de_por_que_no).
