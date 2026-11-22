% dificultad.pl (pruebas)
% Que atacar no baste siempre: grupos de 3 a 5 enemigos en los encuentros y dos enemigos con truco.
%   * la seta curandera (retaguardia) cura cada turno al aliado mas herido: si no se la mata, la pelea no acaba;
%   * el ballestero oxidado (retaguardia, a distancia) es el unico enemigo que llega a Pimentina y a Rufino.
% (1) el bestiario; (2) la curandera; (3) el ballestero; (4) los grupos; (5) lo que cambia en un combate de verdad:
% el mismo grupo pierde si solo se pulsa «atacar» y se gana si se elige a quien matar primero.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/dificultad -g "run_tests,halt" -t "halt(1)" < /dev/null

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
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% grupo_listo(+Tipos): una partida nueva con un combate contra esos tipos (los de la Banda, en su sitio)
grupo_listo(Tipos) :-
    nueva_partida,
    juego:comenzar_combate(Tipos, _).

caidos_ahora(N) :-
    findall(x, ( estado:combatiente(Id, jugador), \+ compania:vivo(Id) ), L), length(L, N).

% --- los dos estilos: pulsar solo «atacar» (al primero de la lista) y elegir a quien matar primero ---
primer_tipo_vivo(T) :- estado:instancia(E, T), compania:vivo(E), !.

orden_solo_atacar(Cmd) :-
    estado:cola_turnos([A|_]), primer_tipo_vivo(T),
    (   estado:instancia(E, T), compania:vivo(E), combate:puede_atacar(A, E) -> Cmd = atacar(T) ; Cmd = defender ).

peligro(seta_curandera, 0) :- !.
peligro(ballestero_oxidado, 1) :- !.
peligro(bandido_montado, 2) :- !.
peligro(_, 5).

objetivo_listo(A, T) :-
    findall(P-V-T0, ( estado:instancia(E, T0), compania:vivo(E), combate:puede_atacar(A, E), peligro(T0, P), estado:vida(E, V) ), L),
    msort(L, [_-_-T|_]).

orden_lista(Cmd) :-
    estado:cola_turnos([A|_]),
    mundo:habilidad_de(A, H),
    (   objetivo_listo(A, T) -> true ; T = ninguno ),
    (   combate:objetivo_de_habilidad(H, ninguno), combate:puede_habilidad(A, H) -> Cmd = habilidad
    ;   T \== ninguno, estado:instancia(E, T), compania:vivo(E), combate:puede_habilidad(A, H, E) -> Cmd = habilidad(T)
    ;   T \== ninguno -> Cmd = atacar(T)
    ;   Cmd = defender ).

% jugar(+Estilo, +Limite): ordenes hasta que acabe el combate (o el Limite)
jugar(Estilo, Limite) :-
    (   estado:en_combate(_), \+ estado:fin_partida(_), Limite > 0
    ->  (   Estilo == solo_atacar -> once(orden_solo_atacar(Cmd)) ; once(orden_lista(Cmd)) ),
        orden(Cmd, _),
        L1 is Limite - 1, jugar(Estilo, L1)
    ;   true ).

resultado_de(derrota) :- estado:fin_partida(_), !.
resultado_de(victoria) :- \+ estado:en_combate(_), !.
resultado_de(sin_acabar).

:- begin_tests(el_bestiario).

test(la_seta_curandera_cura_desde_atras_y_pega_poco) :-
    mundo:enemigo(seta_curandera, vida(12), ataque(3), defensa(1)),
    mundo:fila_preferida(seta_curandera, retaguardia),
    mundo:alcance(seta_curandera, cuerpo),
    mundo:clase(seta_curandera, hongo).

test(el_ballestero_oxidado_dispara_desde_atras_y_llega_a_la_retaguardia) :-
    mundo:enemigo(ballestero_oxidado, vida(10), ataque(6), defensa(0)),
    mundo:fila_preferida(ballestero_oxidado, retaguardia),
    mundo:alcance(ballestero_oxidado, distancia),
    mundo:clase(ballestero_oxidado, humano).

test(los_dos_sueltan_botin) :-
    mundo:botin(seta_curandera, 1, 50),
    mundo:botin(ballestero_oxidado, 1, 100).

test(la_curacion_de_la_seta_es_un_parametro) :-
    mundo:parametro(cura_de_seta, N), assertion(N == 5).

:- end_tests(el_bestiario).

:- begin_tests(la_curandera).

test(con_un_aliado_herido_lo_cura_en_vez_de_atacar, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 6)]),
    combate:accion_enemigo(e(seta_curandera, 1), A),
    assertion(A == curar_aliado(e(bandido_torpe, 1))).

test(con_todos_enteros_ataca, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    combate:accion_enemigo(e(seta_curandera, 1), A),
    assertion(A = atacar(_)).

test(sola_ataca_porque_a_si_misma_no_se_cura, [nondet]) :-
    grupo_listo([seta_curandera]),
    estado:aplicar_efectos([dano(e(seta_curandera, 1), 6)]),
    combate:accion_enemigo(e(seta_curandera, 1), A),
    assertion(A = atacar(_)).

test(cura_al_mas_herido_de_los_heridos, [nondet]) :-
    grupo_listo([bandido_torpe, rata_quesera, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 3), dano(e(rata_quesera, 1), 6)]),
    combate:accion_enemigo(e(seta_curandera, 1), A),
    assertion(A == curar_aliado(e(rata_quesera, 1))).

test(los_demas_enemigos_nunca_curan_a_nadie, [nondet]) :-
    grupo_listo([bandido_torpe, bandido_torpe]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 6)]),
    assertion(\+ combate:puede_curar_aliado(e(bandido_torpe, 2), _)),
    assertion(\+ combate:puede_curar_aliado(e(bandido_torpe, 1), _)).

test(cura_cinco_de_vida, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 8)]),            % 4 de 12
    combate:efectos_accion(e(seta_curandera, 1), curar_aliado(e(bandido_torpe, 1)), Efs),
    assertion(memberchk(curar(e(bandido_torpe, 1), 5), Efs)),
    estado:aplicar_efectos(Efs),
    estado:vida(e(bandido_torpe, 1), V), assertion(V == 9).

test(no_cura_mas_de_lo_que_falta, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 2)]),
    combate:efectos_accion(e(seta_curandera, 1), curar_aliado(e(bandido_torpe, 1)), Efs),
    assertion(memberchk(curar(e(bandido_torpe, 1), 2), Efs)),
    assertion(memberchk(mensaje(cura_aliado, [e(seta_curandera, 1), e(bandido_torpe, 1), 2]), Efs)),
    estado:aplicar_efectos(Efs),
    estado:vida(e(bandido_torpe, 1), V), assertion(V == 12).

test(su_turno_en_un_combate_de_verdad_cura_y_lo_cuenta, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 6)]),
    juego:turno_enemigo(e(seta_curandera, 1), Items),
    assertion(memberchk(msg(cura_aliado, [e(seta_curandera, 1), e(bandido_torpe, 1), 5], _), Items)),
    estado:vida(e(bandido_torpe, 1), V), assertion(V == 11).

test(explicar_dice_que_curar_es_la_prioridad_cinco, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 6)]),
    juego:turno_enemigo(e(seta_curandera, 1), _),
    orden(explicar, [vista(decision, E, Prueba, _)]),
    assertion(E == e(seta_curandera, 1)),
    assertion(Prueba = regla(accion_enemigo(_, curar_aliado(_)), 5, _)).

test(la_curandera_no_esta_al_alcance_de_los_golpes_de_cuerpo_a_cuerpo, [nondet]) :-
    grupo_listo([bandido_torpe, seta_curandera]),
    assertion(\+ combate:puede_atacar(baldomero, e(seta_curandera, 1))),
    assertion(\+ combate:puede_atacar(tuerca, e(seta_curandera, 1))),
    assertion(combate:puede_atacar(pimentina, e(seta_curandera, 1))),       % los de distancia si llegan
    assertion(combate:puede_atacar(rufino, e(seta_curandera, 1))).

:- end_tests(la_curandera).

:- begin_tests(el_ballestero).

test(el_ballestero_llega_a_la_retaguardia_con_el_frente_en_pie, [nondet]) :-
    grupo_listo([ballestero_oxidado]),
    assertion(combate:puede_atacar(e(ballestero_oxidado, 1), pimentina)),
    assertion(combate:puede_atacar(e(ballestero_oxidado, 1), rufino)).

test(un_bandido_de_cuerpo_a_cuerpo_no_llega, [nondet]) :-
    grupo_listo([bandido_torpe]),
    assertion(\+ combate:puede_atacar(e(bandido_torpe, 1), pimentina)),
    assertion(combate:puede_atacar(e(bandido_torpe, 1), tuerca)).

test(elige_al_mas_debil_de_todos_y_ese_es_pimentina, [nondet]) :-
    grupo_listo([ballestero_oxidado, bandido_torpe]),
    combate:accion_enemigo(e(ballestero_oxidado, 1), A),
    assertion(A == atacar(pimentina)).

test(un_disparo_quita_cinco_a_pimentina, [nondet]) :-
    grupo_listo([ballestero_oxidado]),
    combate:dano(e(ballestero_oxidado, 1), pimentina, D),
    assertion(D == 5).

test(los_golpes_de_cuerpo_a_cuerpo_no_alcanzan_al_ballestero_mientras_haya_frente, [nondet]) :-
    grupo_listo([bandido_torpe, ballestero_oxidado]),
    assertion(\+ combate:puede_atacar(baldomero, e(ballestero_oxidado, 1))),
    assertion(combate:puede_atacar(pimentina, e(ballestero_oxidado, 1))).

test(con_el_frente_caido_ya_se_le_alcanza, [nondet]) :-
    grupo_listo([bandido_torpe, ballestero_oxidado]),
    estado:aplicar_efectos([dano(e(bandido_torpe, 1), 99)]),
    assertion(combate:puede_atacar(baldomero, e(ballestero_oxidado, 1))).

:- end_tests(el_ballestero).

:- begin_tests(los_grupos).

test(todo_encuentro_tiene_de_tres_a_cinco_enemigos) :-
    forall(mundo:encuentro(Z, G),
           (   length(G, N), assertion(N >= 3), assertion(N =< 5), assertion(mundo:zona(Z, _)) )).

test(cada_zona_peligrosa_tiene_un_grupo_de_cuatro_o_cinco) :-
    forall(mundo:probabilidad_de_encuentro(Z, _),
           assertion(( mundo:encuentro(Z, G), length(G, N), N >= 4 ))).

test(en_el_bosque_y_las_cuevas_hay_curanderas_y_en_el_camino_ballesteros) :-
    assertion(( mundo:encuentro(bosque, G1), memberchk(seta_curandera, G1) )),
    assertion(( mundo:encuentro(cuevas, G2), memberchk(seta_curandera, G2) )),
    assertion(( mundo:encuentro(camino_real, G3), memberchk(ballestero_oxidado, G3) )).

test(el_grupo_mas_duro_de_las_cuevas_es_el_que_se_prueba_abajo, [nondet]) :-
    % el mismo grupo de «un combate de verdad»: quien solo pulsa atacar lo pierde
    mundo:encuentro(cuevas, [bandido_montado, bandido_torpe, ballestero_oxidado, seta_curandera]).

test(los_contratos_nuevos_llevan_tambien_los_trucos) :-
    contratos:contrato(peaje_del_ganso, _, eliminar(P1), _, _), assertion(memberchk(ballestero_oxidado-1, P1)),
    contratos:contrato(paz_del_moho, _, eliminar(P2), _, _), assertion(memberchk(seta_curandera-1, P2)).

test(el_pago_de_un_contrato_sigue_la_formula_con_los_enemigos_nuevos) :-
    contratos:pago_de(peaje_del_ganso, A), assertion(A == 15),
    contratos:pago_de(paz_del_moho, B), assertion(B == 22).

:- end_tests(los_grupos).

:- begin_tests(un_combate_de_verdad).

% El grupo mas duro de las cuevas (montado, bandido, ballestero y curandera): quien solo pulsa «atacar» lo pierde
% (el combate es determinista: no hay azar en los golpes) y quien va primero a la curandera y al ballestero lo gana.
test(solo_pulsar_atacar_contra_el_grupo_mas_duro_pierde_la_partida) :-
    grupo_listo([bandido_montado, bandido_torpe, ballestero_oxidado, seta_curandera]),
    jugar(solo_atacar, 300),
    assertion(resultado_de(derrota)).

test(elegir_a_quien_matar_primero_lo_gana) :-
    grupo_listo([bandido_montado, bandido_torpe, ballestero_oxidado, seta_curandera]),
    jugar(lista, 300),
    assertion(resultado_de(victoria)),
    assertion(\+ estado:fin_partida(_)).

test(ganando_cuesta_vida_a_la_retaguardia, [nondet]) :-
    grupo_listo([bandido_torpe, bandido_torpe, ballestero_oxidado]),
    jugar(lista, 300),
    assertion(resultado_de(victoria)),
    estado:vida(pimentina, V), assertion(V < 18).

test(un_grupo_facil_todavia_se_gana_solo_atacando) :-
    grupo_listo([rata_quesera, rata_quesera]),
    jugar(solo_atacar, 300),
    assertion(resultado_de(victoria)),
    caidos_ahora(N), assertion(N == 0).

:- end_tests(un_combate_de_verdad).
