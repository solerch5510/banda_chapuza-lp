% acciones.pl (pruebas)
% T-22: las acciones del jugador en combate. El efecto alterar (estados como defendiendo o
% aturdido), efectos_accion/3 (atacar y defender), el paso de los estados alterados y los
% comandos atacar(Objetivo) y defender de juego:ejecutar/2, con su prueba guardada para explicar.
%
% Aun no hay bucle de combate (T-23): los combates se montan con los efectos reales
% iniciar_combate y siguiente_ronda, y los turnos de los enemigos se saltan a mano.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/acciones -g "run_tests,halt" -t "halt(1)"

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

% Un combate contra Tipos con la primera ronda ya abierta (empieza Baldomero).
combate_listo(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs).

% Fija a mano la cola de turnos (para probar el turno de otro actor).
cola_a(Ids) :-
    retractall(estado:cola_turnos(_)),
    assertz(estado:cola_turnos(Ids)).

% Deja a un miembro con la moral M (parte de 6).
moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

% El resultado de un comando.
ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

% Lo que se veria en pantalla.
pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

:- begin_tests(efecto_alterar).

test(alterar_crea_el_estado, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    estado:alterado(baldomero, defendiendo, 1).

test(alterar_de_nuevo_sustituye_no_acumula, [setup(combate_listo([rata_quesera]))]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(alterar(baldomero, defendiendo, 3)),
    findall(T, estado:alterado(baldomero, defendiendo, T), Ts),
    Ts == [3].

test(estados_distintos_conviven, [setup(combate_listo([rata_quesera]))]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(alterar(baldomero, aturdido, 2)),
    findall(E, estado:alterado(baldomero, E, _), Es),
    msort(Es, S),
    S == [aturdido, defendiendo].

test(un_estado_fijo_vale, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(rufino, cantando, fijo)),
    estado:alterado(rufino, cantando, fijo).

test(alterar_a_un_enemigo, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(e(rata_quesera, 1), aturdido, 2)),
    estado:alterado(e(rata_quesera, 1), aturdido, 2).

test(un_aturdido_lo_es_para_las_reglas, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    combate:aturdido(baldomero).

test(cero_turnos_no_vale, [setup(combate_listo([rata_quesera])), fail]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 0)).

test(turnos_negativos_no_valen, [setup(combate_listo([rata_quesera])), fail]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, -1)).

test(turnos_que_no_son_numero_no_valen, [setup(combate_listo([rata_quesera])), fail]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, mucho)).

test(turnos_sin_ligar_no_valen, [setup(combate_listo([rata_quesera])), fail]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, _)).

test(quien_no_combate_no_se_altera, [setup(combate_listo([rata_quesera])), fail]) :-
    aplicar_efecto(alterar(fantasma, defendiendo, 1)).

test(fuera_de_combate_no_se_altera, [setup(nueva_partida), fail]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)).

test(un_fallo_no_toca_el_estado, [setup(combate_listo([rata_quesera]))]) :-
    foto_estado(Antes),
    \+ aplicar_efecto(alterar(baldomero, defendiendo, 0)),
    foto_estado(Despues),
    Antes == Despues.

test(quitar_alteracion_lo_borra, [setup(combate_listo([rata_quesera]))]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(quitar_alteracion(baldomero, defendiendo)),
    \+ estado:alterado(baldomero, defendiendo, _).

test(quitar_alteracion_solo_quita_ese_estado, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    aplicar_efecto(quitar_alteracion(baldomero, defendiendo)),
    estado:alterado(baldomero, aturdido, 1).

test(quitar_alteracion_no_toca_a_los_demas, [setup(combate_listo([rata_quesera])), nondet]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(alterar(pimentina, defendiendo, 1)),
    aplicar_efecto(quitar_alteracion(baldomero, defendiendo)),
    \+ estado:alterado(baldomero, defendiendo, _),
    estado:alterado(pimentina, defendiendo, 1).

test(quitar_lo_que_no_hay_no_falla, [setup(combate_listo([rata_quesera]))]) :-
    aplicar_efecto(quitar_alteracion(baldomero, defendiendo)).

test(nueva_partida_borra_los_estados, [setup(combate_listo([rata_quesera]))]) :-
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    nueva_partida,
    \+ estado:alterado(_, _, _).

:- end_tests(efecto_alterar).

:- begin_tests(efectos_accion).

test(atacar_son_los_efectos_del_golpe, [nondet]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(baldomero, atacar(e(bandido_torpe, 1)), Efs),
    combate:efectos_golpe(baldomero, e(bandido_torpe, 1), Golpe),
    Efs == Golpe.

test(defender_pone_el_estado_y_avisa, [nondet]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(baldomero, defender, Efs),
    once(Efs = [alterar(baldomero, defendiendo, 1), mensaje(defiende, [baldomero])]).

test(las_acciones_no_modifican_el_estado, [nondet]) :-
    combate_listo([bandido_torpe]),
    foto_estado(Antes),
    combate:efectos_accion(baldomero, atacar(e(bandido_torpe, 1)), _),
    combate:efectos_accion(baldomero, defender, _),
    foto_estado(Despues),
    Antes == Despues.

test(un_enemigo_tambien_puede_defender, [nondet]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(e(bandido_torpe, 1), defender, [alterar(e(bandido_torpe, 1), defendiendo, 1)|_]).

test(un_caido_no_defiende, [fail]) :-
    combate_listo([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 99)),
    combate:efectos_accion(baldomero, defender, _).

test(un_huelguista_no_defiende, [fail]) :-
    combate_listo([bandido_torpe]),
    moral_a(rufino, 2),
    combate:efectos_accion(rufino, defender, _).

test(un_aturdido_no_defiende, [fail]) :-
    combate_listo([bandido_torpe]),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    combate:efectos_accion(baldomero, defender, _).

test(fuera_de_combate_nadie_puede_defender, [setup(nueva_partida), fail]) :-
    combate:puede_defender(baldomero).

test(quien_no_combate_no_defiende, [fail]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(fantasma, defender, _).

test(una_accion_desconocida_no_es_legal, [fail]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(baldomero, volar, _).

test(aplicar_defender_sube_la_defensa, [nondet]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(baldomero, defender, Efs),
    aplicar_efectos(Efs),
    once(combate:defensa(baldomero, D)),
    D == 5.

:- end_tests(efectos_accion).

:- begin_tests(paso_de_los_estados).

test(sin_estados_no_hay_nada_que_hacer) :-
    combate_listo([rata_quesera]),
    combate:efectos_inicio_turno(baldomero, Efs),
    Efs == [].

test(lo_que_dura_un_turno_se_quita) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    combate:efectos_inicio_turno(baldomero, Efs),
    Efs == [quitar_alteracion(baldomero, defendiendo)].

test(lo_que_dura_mas_baja_en_uno) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, aturdido, 3)),
    combate:efectos_inicio_turno(baldomero, Efs),
    Efs == [alterar(baldomero, aturdido, 2)].

test(lo_fijo_no_cambia, [nondet]) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(rufino, cantando, fijo)),
    combate:efectos_inicio_turno(rufino, Efs),
    Efs == [].

test(solo_cuenta_el_actor) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(pimentina, defendiendo, 1)),
    combate:efectos_inicio_turno(baldomero, Efs),
    Efs == [].

test(varios_estados_a_la_vez) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(alterar(baldomero, aturdido, 2)),
    combate:efectos_inicio_turno(baldomero, Efs),
    msort(Efs, S),
    S == [quitar_alteracion(baldomero, defendiendo), alterar(baldomero, aturdido, 1)].

test(aplicar_el_paso_quita_la_defensa) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    combate:efectos_inicio_turno(baldomero, Efs),
    aplicar_efectos(Efs),
    \+ estado:alterado(baldomero, defendiendo, _),
    once(combate:defensa(baldomero, D)),
    D == 3.

test(el_paso_no_modifica_el_estado) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, aturdido, 3)),
    foto_estado(Antes),
    combate:efectos_inicio_turno(baldomero, _),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(paso_de_los_estados).

:- begin_tests(comando_atacar).

test(baldomero_golpea_al_bandido_torpe) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), Items),
    Items == [msg(golpe, [baldomero, e(bandido_torpe, 1), 9], 0)],
    estado:vida(e(bandido_torpe, 1), V),
    V == 3.

test(el_turno_pasa_al_siguiente) :-
    combate_listo([bandido_torpe]),
    estado:cola_turnos(Antes),
    ordena(atacar(bandido_torpe), _),
    estado:cola_turnos(Despues),
    Antes = [baldomero|Resto],
    Despues == Resto.

test(el_comando_no_mueve_a_los_enemigos) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    estado:vida(baldomero, V),
    V == 30.

test(un_tipo_es_su_primera_instancia_viva) :-
    combate_listo([rata_quesera, rata_quesera]),
    ordena(atacar(rata_quesera), [msg(golpe, [baldomero, Objetivo, _], _)|_]),
    Objetivo == e(rata_quesera, 1).

test(si_la_primera_ha_caido_se_ataca_la_siguiente) :-
    combate_listo([rata_quesera, rata_quesera]),
    ordena(atacar(rata_quesera), _),                   % 11 contra 8: cae la primera
    cola_a([baldomero]),
    ordena(atacar(rata_quesera), [msg(golpe, [baldomero, Objetivo, _], _)|_]),
    Objetivo == e(rata_quesera, 2).

test(una_instancia_concreta_tambien_vale) :-
    combate_listo([rata_quesera, rata_quesera]),
    ordena(atacar(e(rata_quesera, 2)), [msg(golpe, [baldomero, Objetivo, _], _)|_]),
    Objetivo == e(rata_quesera, 2).

test(el_golpe_que_derriba_avisa, [nondet]) :-
    combate_listo([rata_quesera, bandido_torpe]),
    ordena(atacar(rata_quesera), Items),
    memberchk(msg(cae, [e(rata_quesera, 1)], _), Items),
    estado:vida(e(rata_quesera, 1), V),
    V == 0.

test(no_se_ataca_a_un_enemigo_caido, [nondet]) :-
    combate_listo([rata_quesera, bandido_torpe]),
    aplicar_efecto(dano(e(rata_quesera, 1), 99)),       % cae la rata; el bandido sigue en pie
    ordena(atacar(rata_quesera), Items),
    Items == [error(objetivo_desconocido(rata_quesera))].

test(sin_cola_no_es_tu_turno) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([rata_quesera])]),   % ronda 0, cola vacia
    ordena(atacar(rata_quesera), Items),
    Items == [error(no_es_tu_turno)].

test(si_le_toca_a_un_enemigo_no_es_tu_turno) :-
    combate_listo([rata_quesera]),
    cola_a([e(rata_quesera, 1), baldomero]),
    ordena(atacar(rata_quesera), Items),
    Items == [error(no_es_tu_turno)].

test(un_objetivo_desconocido) :-
    combate_listo([rata_quesera]),
    ordena(atacar(dragon), Items),
    Items == [error(objetivo_desconocido(dragon))].

test(una_instancia_que_no_existe) :-
    combate_listo([rata_quesera]),
    ordena(atacar(e(rata_quesera, 7)), Items),
    Items == [error(objetivo_desconocido(e(rata_quesera, 7)))].

test(no_se_ataca_al_propio_bando) :-
    combate_listo([rata_quesera]),
    ordena(atacar(pimentina), Items),
    Items == [error(no_puede_atacar(baldomero, pimentina))].

test(baldomero_no_puede_atacar_al_bandido_montado) :-
    combate_listo([bandido_montado]),
    ordena(atacar(bandido_montado), Items),
    Items == [error(no_puede_atacar(baldomero, e(bandido_montado, 1)))].

test(con_la_venda_baldomero_si_ataca_al_montado) :-
    combate_listo([bandido_montado]),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(atacar(bandido_montado), Items),
    Items == [msg(golpe, [baldomero, e(bandido_montado, 1), 5], 0)].

test(un_error_no_toca_el_estado) :-
    combate_listo([bandido_montado]),
    foto_estado(Antes),
    ordena(atacar(bandido_montado), _),
    ordena(atacar(dragon), _),
    ordena(atacar(pimentina), _),
    foto_estado(Despues),
    Antes =@= Despues.

test(un_error_no_gasta_el_turno) :-
    combate_listo([bandido_montado]),
    ordena(atacar(bandido_montado), _),
    estado:cola_turnos([Cabeza|_]),
    Cabeza == baldomero.

test(la_retaguardia_esta_protegida) :-
    combate_listo([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)),
    ordena(atacar(rata_quesera), Items),
    Items == [error(no_puede_atacar(baldomero, e(rata_quesera, 1)))].

test(cuando_cae_el_frente_la_retaguardia_se_alcanza, [nondet]) :-
    combate_listo([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)),
    aplicar_efecto(dano(e(bandido_torpe, 1), 99)),
    ordena(atacar(rata_quesera), [msg(golpe, [baldomero, Objetivo, _], _)|_]),
    Objetivo == e(rata_quesera, 1).

test(un_ataque_a_distancia_alcanza_la_retaguardia) :-
    combate_listo([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)),
    cola_a([pimentina, baldomero]),                    % Pimentina ataca a distancia
    ordena(atacar(rata_quesera), [msg(golpe, [pimentina, Objetivo, _], _)|_]),
    Objetivo == e(rata_quesera, 1).

test(ataca_el_miembro_al_que_le_toca) :-
    combate_listo([bandido_torpe]),
    cola_a([tuerca, baldomero]),
    ordena(atacar(bandido_torpe), Items),
    Items == [msg(golpe, [tuerca, e(bandido_torpe, 1), 5], 0)].

test(un_aturdido_no_ataca) :-
    combate_listo([bandido_torpe]),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    ordena(atacar(bandido_torpe), Items),
    Items == [error(no_puede_atacar(baldomero, e(bandido_torpe, 1)))].

test(la_moral_baja_se_nota_en_el_golpe) :-
    combate_listo([bandido_torpe]),
    moral_a(baldomero, 3),                             % baja: -1
    ordena(atacar(bandido_torpe), Items),
    Items == [msg(golpe, [baldomero, e(bandido_torpe, 1), 8], 0)].

test(el_contador_de_uso_de_la_frase_sube) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    estado:usos_frase(golpe(baldomero, e(bandido_torpe, 1), 9), U),
    U == 1.

test(dos_golpes_en_dos_turnos_acaban_con_el_enemigo) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), I1),
    cola_a([baldomero]),
    ordena(atacar(bandido_torpe), I2),
    I1 = [msg(golpe, _, _)],
    memberchk(msg(cae, [e(bandido_torpe, 1)], _), I2),
    \+ compania:vivo(e(bandido_torpe, 1)).

:- end_tests(comando_atacar).

:- begin_tests(comando_defender).

test(defender_pone_el_estado_y_pasa_el_turno) :-
    combate_listo([bandido_torpe]),
    ordena(defender, Items),
    Items == [msg(defiende, [baldomero], 0)],
    estado:alterado(baldomero, defendiendo, 1),
    estado:cola_turnos([Siguiente|_]),
    Siguiente \== baldomero.

test(defender_sube_la_defensa_de_quien_actua) :-
    combate_listo([bandido_torpe]),
    ordena(defender, _),
    once(combate:defensa(baldomero, D)),
    D == 5.

test(defender_reduce_el_dano_que_se_recibe) :-
    combate_listo([gran_roquefort]),
    once(combate:dano(e(gran_roquefort, 1), baldomero, Antes)),
    ordena(defender, _),
    once(combate:dano(e(gran_roquefort, 1), baldomero, Despues)),
    Antes == 8,
    Despues == 6.

test(defiende_el_miembro_al_que_le_toca) :-
    combate_listo([bandido_torpe]),
    cola_a([rufino, baldomero]),
    ordena(defender, [msg(defiende, [rufino], _)]),
    estado:alterado(rufino, defendiendo, 1),
    \+ estado:alterado(baldomero, defendiendo, _).

test(defender_sin_cola_no_es_tu_turno) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([rata_quesera])]),
    ordena(defender, Items),
    Items == [error(no_es_tu_turno)].

test(defender_en_el_turno_enemigo_no_es_tu_turno) :-
    combate_listo([rata_quesera]),
    cola_a([e(rata_quesera, 1)]),
    ordena(defender, Items),
    Items == [error(no_es_tu_turno)].

test(un_aturdido_no_puede_defender) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    ordena(defender, Items),
    Items == [error(no_puede_defender(baldomero))].

test(un_error_al_defender_no_toca_el_estado) :-
    combate_listo([rata_quesera]),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    foto_estado(Antes),
    ordena(defender, _),
    foto_estado(Despues),
    Antes =@= Despues.

test(defender_dos_veces_no_acumula, [nondet]) :-
    combate_listo([bandido_torpe]),
    combate:efectos_accion(baldomero, defender, E1),
    aplicar_efectos(E1),
    combate:efectos_accion(baldomero, defender, E2),
    aplicar_efectos(E2),
    once(combate:defensa(baldomero, D)),
    D == 5.

test(el_estado_expira_al_empezar_el_siguiente_turno_del_que_defendio) :-
    combate_listo([bandido_torpe]),
    ordena(defender, _),
    estado:alterado(baldomero, defendiendo, _),
    combate:efectos_inicio_turno(baldomero, Efs),
    aplicar_efectos(Efs),
    \+ estado:alterado(baldomero, defendiendo, _).

:- end_tests(comando_defender).

:- begin_tests(fases_y_validacion).

test(en_la_taberna_no_se_ataca, [setup(nueva_partida)]) :-
    ordena(atacar(rata_quesera), Items),
    Items == [error(fuera_de_fase(atacar(rata_quesera), taberna))].

test(en_la_taberna_no_se_defiende, [setup(nueva_partida)]) :-
    ordena(defender, Items),
    Items == [error(fuera_de_fase(defender, taberna))].

test(en_exploracion_no_se_ataca) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(atacar(rata_quesera), Items),
    Items == [error(fuera_de_fase(atacar(rata_quesera), exploracion))].

test(los_comandos_de_combate_no_valen_si_la_partida_acabo) :-
    nueva_partida,
    aplicar_efecto(fin(victoria)),
    ordena(atacar(rata_quesera), I1),
    ordena(defender, I2),
    I1 == [error(fuera_de_fase(atacar(rata_quesera), fin))],
    I2 == [error(fuera_de_fase(defender, fin))].

test(la_ayuda_del_combate_incluye_atacar_y_defender, [nondet]) :-
    combate_listo([rata_quesera]),
    ordena(ayuda, [vista(ayuda, Comandos)]),
    memberchk(atacar, Comandos),
    memberchk(defender, Comandos).

test(la_ayuda_de_la_taberna_no_los_incluye, [setup(nueva_partida)]) :-
    ordena(ayuda, [vista(ayuda, Comandos)]),
    \+ memberchk(atacar, Comandos),
    \+ memberchk(defender, Comandos).

test(todos_los_comandos_tienen_ayuda, [nondet]) :-
    forall(( member(Fase, [taberna, exploracion, combate, fin]), comandos_disponibles(Fase, Cs), member(C, Cs) ),
           narrador:ayuda_de(C, _)).

test(atacar_con_una_variable_falta_argumento, [setup(nueva_partida)]) :-
    validar_comando(atacar(_), Res),
    Res = error(falta_argumento(_)).

test(atacar_con_un_objetivo_es_un_comando, [setup(nueva_partida)]) :-
    validar_comando(atacar(rata_quesera), Res),
    Res == ok(atacar(rata_quesera)).

test(atacar_sin_argumento_no_es_un_comando, [setup(nueva_partida)]) :-
    validar_comando(atacar, Res),
    Res == error(no_entiendo(atacar)).

test(defender_con_argumento_no_es_un_comando, [setup(nueva_partida)]) :-
    validar_comando(defender(baldomero), Res),
    Res == error(no_entiendo(defender(baldomero))).

test(ejecutar_atacar_con_variable_no_elige_objetivo) :-
    combate_listo([rata_quesera]),
    foto_estado(Antes),
    ordena(atacar(_), Items),
    foto_estado(Despues),
    Items = [error(falta_argumento(_))],
    Antes =@= Despues.

test(los_comandos_de_combate_nunca_fallan_ni_lanzan) :-
    combate_listo([bandido_montado, rata_quesera]),
    forall(member(Cmd, [atacar(rata_quesera), atacar(bandido_montado), atacar(x), atacar(e(a, b)), atacar(1),
                        atacar("texto"), defender, atacar(baldomero), atacar(e(rata_quesera, 1))]),
           (   ejecutar(Cmd, R), R = resultado(_) )).

:- end_tests(fases_y_validacion).

:- begin_tests(pantalla).

test(se_ve_el_golpe, [nondet]) :-
    combate_listo([bandido_torpe]),
    pantalla(atacar(bandido_torpe), Texto),
    sub_atom(Texto, _, _, _, 'Sir Baldomero golpea al Bandido Torpe y le quita 9 de vida'),
    \+ sub_atom(Texto, _, _, _, 'msg('),
    \+ sub_atom(Texto, _, _, _, '~w').

test(se_ve_el_error_de_no_poder_atacar, [nondet]) :-
    combate_listo([bandido_montado]),
    pantalla(atacar(bandido_montado), Texto),
    sub_atom(Texto, _, _, _, 'Sir Baldomero no puede atacar al Bandido Montado ahora mismo.').

test(se_ve_que_no_es_tu_turno, [nondet]) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([rata_quesera])]),
    pantalla(atacar(rata_quesera), Texto),
    sub_atom(Texto, _, _, _, 'Ahora no te toca a ti').

test(se_ve_el_objetivo_desconocido, [nondet]) :-
    combate_listo([rata_quesera]),
    pantalla(atacar(dragon), Texto),
    sub_atom(Texto, _, _, _, 'No hay nada llamado "dragon"').

test(se_ve_fuera_de_fase, [setup(nueva_partida), nondet]) :-
    pantalla(atacar(rata_quesera), Texto),
    sub_atom(Texto, _, _, _, 'Solo se puede atacar, defender o usar una habilidad en pleno combate.').

test(ningun_error_de_combate_ensena_terminos_crudos) :-
    combate_listo([bandido_montado]),
    forall(member(Cmd, [atacar(bandido_montado), atacar(x), atacar(pimentina), defender, ayuda]),
           (   pantalla(Cmd, Texto),
               \+ sub_atom(Texto, _, _, _, 'error('),
               \+ sub_atom(Texto, _, _, _, 'msg(')
           )),
    aplicar_efecto(alterar(baldomero, aturdido, 1)),
    pantalla(defender, T2),
    \+ sub_atom(T2, _, _, _, 'error(').

:- end_tests(pantalla).

:- begin_tests(explicar_las_acciones).

test(explicar_tras_atacar_muestra_la_prueba_guardada) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    ordena(explicar, Items),
    Items = [vista(prueba, Accion, _)],
    Accion == atacar(baldomero, e(bandido_torpe, 1)).

test(la_prueba_guardada_es_la_de_antes_del_golpe, [nondet]) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),                 % el estado ya cambio: el bandido tiene 3 de vida
    ordena(explicar, [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('      [ok] vida(e(bandido_torpe, 1), 12)   [hecho]', Lineas).

test(explicar_atacar_con_el_nombre_corto_usa_la_guardada, [nondet]) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    ordena(explicar(atacar(bandido_torpe)), Items),
    Items = [vista(prueba, atacar(bandido_torpe), Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('      [ok] vida(e(bandido_torpe, 1), 12)   [hecho]', Lineas).   % la de antes del golpe

test(explicar_atacar_con_el_nombre_corto_antes_de_atacar, [nondet]) :-
    combate_listo([bandido_torpe]),
    ordena(explicar(atacar(bandido_torpe)), Items),
    Items = [vista(prueba, atacar(bandido_torpe), Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] puede_atacar(baldomero, e(bandido_torpe, 1))   [clausula 1]', Lineas).

test(explicar_atacar_con_actor_y_objetivo_usa_la_guardada) :-
    combate_listo([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    ordena(explicar(atacar(baldomero, bandido_torpe)), Items),
    Items = [vista(prueba, _, _)].

test(explicar_antes_de_atacar_resuelve_en_hipotetico, [nondet]) :-
    combate_listo([bandido_torpe]),
    ordena(explicar(atacar(baldomero, bandido_torpe)), Items),
    Items = [vista(prueba, atacar(baldomero, bandido_torpe), Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] dano(baldomero, e(bandido_torpe, 1), 9)   [clausula 1]', Lineas).

test(la_prueba_de_la_demo_muestra_la_cuenta_del_dano, [nondet]) :-
    combate_listo([bandido_torpe]),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), Texto),
    sub_atom(Texto, _, _, _, '9 is max(1, 11-2+0)').

test(explicar_el_ataque_al_montado_no_tiene_prueba) :-
    combate_listo([bandido_montado]),
    ordena(explicar(atacar(baldomero, bandido_montado)), Items),
    Items == [error(no_hay_prueba(atacar(baldomero, bandido_montado)))].

test(con_la_venda_el_ataque_al_montado_si_tiene_prueba) :-
    combate_listo([bandido_montado]),
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(explicar(atacar(baldomero, bandido_montado)), Items),
    Items = [vista(prueba, _, _)].

test(explicar_un_objetivo_inexistente_no_se_explica) :-
    combate_listo([bandido_torpe]),
    ordena(explicar(atacar(baldomero, dragon)), Items),
    Items == [error(no_se_explica(atacar(baldomero, dragon)))].

test(explicar_tras_defender) :-
    combate_listo([bandido_torpe]),
    ordena(defender, _),
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == defender(baldomero),
    ordena(explicar(defender), Items),
    Items = [vista(prueba, defender, Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] puede_defender(baldomero)   [clausula 1]', Lineas).   % la guardada, no la del siguiente

test(explicar_defender_antes_de_actuar) :-
    combate_listo([bandido_torpe]),
    ordena(explicar(defender), Items),
    Items = [vista(prueba, defender, Prueba)],
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] puede_defender(baldomero)   [clausula 1]', Lineas).

test(un_ataque_fallido_no_cambia_la_ultima_prueba) :-
    combate_listo([bandido_torpe, bandido_montado]),
    ordena(atacar(bandido_torpe), _),
    cola_a([baldomero]),
    ordena(atacar(bandido_montado), _),               % error: no pisa la prueba anterior
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == atacar(baldomero, e(bandido_torpe, 1)).

test(solve_da_lo_mismo_que_ejecutar_puede_atacar_y_dano) :-
    combate_listo([bandido_torpe, bandido_montado, rata_quesera]),
    forall(( member(A, [baldomero, pimentina, rufino, tuerca]), member(T, [bandido_torpe, bandido_montado, rata_quesera]) ),
           (   findall(D, ( combate:puede_atacar(A, e(T, 1)), combate:dano(A, e(T, 1), D) ), Directo),
               findall(D, solve((combate:puede_atacar(A, e(T, 1)), combate:dano(A, e(T, 1), D)), _), ConSolve),
               Directo == ConSolve
           )).

:- end_tests(explicar_las_acciones).
