% simulador.pl (pruebas)
% El simulador de balance (herramientas/simulador.pl): juega partidas enteras sin persona con el motor de
% verdad. Se prueba que (1) es reproducible, (2) elige solo ordenes que el juego acepta, (3) las rutas de
% referencia acaban como se sabe, (4) un jugador con plan puede ganar (el juego es ganable) y (5) el informe
% sale completo.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/simulador -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/contratos').
:- use_module('../src/juego').
:- use_module('../herramientas/simulador').
% Los jugadores simulados pelean como una persona atenta: atacan sin despistes y descansan si vuelven heridos (herramientas/simulador.pl).
:- fijar_estilo(solo_atacar).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% la primera orden que daria un jugador con plan (con ese % de ruido) desde una partida nueva
episodio_de_una_orden(Eps, Semilla, Cmd) :-
    nueva_partida, simulador:fijar_azar(Semilla), simulador:orden_con_plan(Eps, 2, Cmd).

% la orden del jugador con plan (sin ruido) en el estado actual
fijar_y_ordenar(Semilla, Cmd) :-
    simulador:fijar_azar(Semilla), simulador:orden_con_plan(0, 2, Cmd).

:- begin_tests(las_ordenes_posibles).

test(al_empezar_se_puede_viajar_y_aceptar_pero_no_atacar) :-
    nueva_partida, simulador:candidatas(Cs),
    findall(C, member(_-C, Cs), Cmds),
    assertion(memberchk(ir(aldea), Cmds)),
    assertion(memberchk(aceptar(gato_en_el_arbol), Cmds)),
    assertion(\+ ( member(C, Cmds), C = atacar(_) )),
    assertion(\+ memberchk(ir(cuevas), Cmds)).

test(todas_las_candidatas_son_ordenes_que_el_juego_acepta) :-
    nueva_partida, simulador:candidatas(Cs),
    forall(member(_-C, Cs),
           (   juego:objetivo_de_accion(C, Meta), assertion(once(Meta)) )).

test(en_combate_solo_hay_ordenes_de_combate) :-
    nueva_partida,
    juego:ejecutar(aceptar(ratas_del_granero), _),
    juego:ejecutar(ir(aldea), _),
    assertion(estado:en_combate(_)),
    simulador:candidatas(Cs),
    assertion(Cs \== []),
    forall(member(_-C, Cs), assertion(memberchk(C, [atacar(_), habilidad(_), habilidad(_, _), habilidad, defender]))).

test(con_el_nivel_2_el_simulador_tambien_ofrece_las_aprendidas) :-
    nueva_partida,
    forall(compania:miembro(P), ( compania:efectos_ganar_xp(P, 20, Efs), estado:aplicar_efectos(Efs) )),
    juego:ejecutar(aceptar(ratas_del_granero), _),
    juego:ejecutar(ir(aldea), _),
    juego:actor_del_turno(A), compania:habilidades_aprendidas(A, [H]),
    simulador:candidatas(Cs),
    assertion(( memberchk(_-habilidad(H), Cs) ; memberchk(_-habilidad(H, _), Cs) )), !.

:- end_tests(las_ordenes_posibles).

:- begin_tests(el_camino_y_el_destino).

test(el_camino_mas_corto_a_las_cuevas) :-
    simulador:camino_a(taberna, [cuevas], C), assertion(C == [camino_real, cuevas]).

test(el_camino_a_un_vecino_es_un_paso) :-
    simulador:camino_a(taberna, [aldea], C), assertion(C == [aldea]).

test(sin_contratos_el_destino_es_la_taberna) :-
    nueva_partida, simulador:zonas_objetivo(Zs), assertion(Zs == [taberna]).

test(el_jefe_aceptado_manda_a_las_cuevas) :-
    nueva_partida, estado:aplicar_efectos([contrato_aceptar(despensa_real)]),
    simulador:zonas_objetivo(Zs), assertion(Zs == [cuevas]).

test(con_tres_contratos_cumplidos_sin_visita_se_va_al_castillo) :-
    nueva_partida,
    estado:aplicar_efectos([contrato_aceptar(ratas_del_granero), contrato_resolver(ratas_del_granero, exito),
                            contrato_aceptar(gato_en_el_arbol), contrato_resolver(gato_en_el_arbol, exito),
                            contrato_aceptar(gallina_noble), contrato_resolver(gallina_noble, exito)]),
    simulador:zonas_objetivo(Zs), assertion(Zs == [castillo]).

test(un_destino_inalcanzable_no_cuelga_la_busqueda) :-
    assertion(\+ simulador:camino_a(taberna, [la_luna], _)).

test(con_un_contrato_el_destino_es_su_zona) :-
    nueva_partida, juego:ejecutar(aceptar(ratas_del_granero), _),
    simulador:zonas_objetivo(Zs), assertion(Zs == [aldea]).

:- end_tests(el_camino_y_el_destino).

:- begin_tests(las_rutas_de_referencia).

test(la_campana_de_ejemplo_se_gana) :-
    ruta_de_referencia('examples/campana-comandos.txt', r(Fin, Dia, _Queso, Pasos)),
    assertion(Fin == victoria), assertion(Dia == 7), assertion(Pasos == 50).

test(la_ruta_de_la_partida_perdida_llega_al_dia_6_sin_final_aun) :-
    ruta_separada(Ruta), jugar_ruta(Ruta, r(Fin, Dia, _, Pasos)),
    assertion(Fin == sin_final), assertion(Dia == 6), assertion(Pasos == 9).

test(una_ruta_que_no_come_acaba_en_hambre) :-
    % cada viaje es un dia: de ida y vuelta a las cuevas se agota el queso sin cobrar nada
    jugar_ruta([ir(camino_real), ir(cuevas), ir(camino_real), ir(taberna), ir(aldea), ir(taberna)], r(Fin, _, _, _)),
    assertion(Fin == hambre).

:- end_tests(las_rutas_de_referencia).

:- begin_tests(los_episodios).

test(con_plan_y_sin_ruido_se_empieza_aceptando_y_con_ruido_no) :-
    findall(C, ( between(1, 20, S), episodio_de_una_orden(0, S, C) ), Sin),
    assertion(forall(member(C, Sin), C = aceptar(_))),
    findall(C, ( between(1, 20, S), episodio_de_una_orden(100, S, C) ), Con),
    assertion(\+ forall(member(C, Con), C = aceptar(_))).

test(con_plan_el_sueldo_pendiente_se_paga) :-
    nueva_partida, estado:aplicar_efectos([desmarcar(sueldos_pagados)]),
    fijar_y_ordenar(1, C), assertion(C == pagar).

test(una_ruta_no_sigue_jugando_tras_el_final) :-
    Ruta = [ir(camino_real), ir(cuevas), ir(camino_real), ir(taberna), ir(aldea), ir(taberna)],
    append(Ruta, [ir(aldea), ir(bosque), ir(camino_real)], Larga),
    jugar_ruta(Ruta, r(F1, D1, Q1, _)), jugar_ruta(Larga, r(F2, D2, Q2, _)),
    assertion(F1 == F2), assertion(D1 == D2), assertion(Q1 == Q2).

test(un_episodio_es_reproducible) :-
    episodio(plan(10, 2), 7, 400, R1),
    episodio(plan(10, 2), 7, 400, R2),
    assertion(R1 == R2).

test(semillas_distintas_dan_partidas_distintas) :-
    findall(R, ( member(S, [1, 2, 3, 4, 5, 6]), episodio(azar, S, 400, R) ), Rs),
    sort(Rs, Distintas), length(Distintas, N), assertion(N >= 2).

test(cada_episodio_acaba_con_un_final_conocido) :-
    forall(( member(P, [azar, plan(10, 1), plan(10, 3)]), member(S, [11, 12, 13]) ),
           (   episodio(P, S, 400, r(Fin, Dia, Queso, Pasos)),
               assertion(memberchk(Fin, [victoria, hambre, combate, sin_final])),
               assertion(integer(Dia)), assertion(integer(Queso)),
               assertion(Pasos >= 1), assertion(Pasos =< 400) )).

test(el_limite_de_pasos_corta_el_episodio) :-
    episodio(azar, 3, 2, r(_, _, _, Pasos)), assertion(Pasos =< 2).

test(un_jugador_con_plan_puede_ganar) :-
    findall(x, ( between(1, 12, I), S is 1000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gana),
    length(Gana, N), assertion(N >= 4).

test(el_jugador_sin_plan_pierde_casi_siempre) :-
    findall(x, ( between(1, 12, I), S is 2000 + I, episodio(azar, S, 400, r(victoria, _, _, _)) ), Gana),
    length(Gana, N), assertion(N =< 3).      % con niveles gana alguna mas por suerte, pero sigue perdiendo casi siempre

test(tras_un_episodio_se_puede_empezar_otra_partida_limpia) :-
    episodio(plan(10, 2), 5, 400, _),
    nueva_partida, estado:dia(D), assertion(D == 1), assertion(\+ estado:fin_partida(_)).

:- end_tests(los_episodios).

:- begin_tests(el_informe).

test(el_informe_trae_las_referencias_y_cada_politica) :-
    with_output_to(atom(T), informe(3, 1)),
    assertion(contiene(T, 'REF campana')), assertion(contiene(T, 'REF separada')),
    assertion(contiene(T, 'POLITICA azar')), assertion(contiene(T, 'POLITICA plan(10,2)')),
    assertion(contiene(T, 'con combate solo_atacar')), assertion(contiene(T, 'con combate listo')),
    assertion(contiene(T, 'PARTIDAS 3 victoria=')).

test(resumir_cuenta_y_promedia) :-
    with_output_to(atom(T),
                   resumir([r(victoria, 7, 2, 40), r(victoria, 8, 5, 50), r(hambre, 5, 0, 20), r(combate, 4, 3, 9)], 4)),
    assertion(contiene(T, 'victoria=2 hambre=1 combate=1 sin_final=0')),
    assertion(contiene(T, 'dias min=7 media=7.5 max=8')),
    assertion(contiene(T, 'queso final min=2 media=3.5 max=5')).

test(sin_victorias_el_informe_lo_dice) :-
    with_output_to(atom(T), resumir([r(hambre, 5, 0, 20)], 1)),
    assertion(contiene(T, 'GANADAS ninguna')).

:- end_tests(el_informe).

:- begin_tests(los_estilos_de_combate).

test(el_estilo_por_defecto_es_el_despistado_y_se_puede_cambiar) :-
    fijar_estilo(azar), simulador:estilo_de_combate(E0), assertion(E0 == azar),
    fijar_estilo(listo), simulador:estilo_de_combate(E1), assertion(E1 == listo),
    fijar_estilo(solo_atacar).

test(el_listo_va_primero_a_la_curandera_luego_al_ballestero_y_el_montado) :-
    forall(member(A-B, [seta_curandera-ballestero_oxidado, ballestero_oxidado-bandido_montado, bandido_montado-bandido_torpe]),
           (   simulador:peligro(A, PA), simulador:peligro(B, PB), assertion(PA < PB) )).

test(el_listo_pega_a_la_curandera_con_los_de_distancia, [nondet]) :-
    fijar_estilo(listo),
    nueva_partida, juego:comenzar_combate([bandido_torpe, seta_curandera], _),
    estado:cola_turnos([Actor|_]), assertion(compania:miembro(Actor)),
    simulador:orden_de_combate(Cmd),
    assertion(Cmd \= defender),
    fijar_estilo(solo_atacar).

test(un_jugador_sensato_herido_en_la_taberna_descansa, [nondet]) :-
    fijar_estilo(solo_atacar),
    nueva_partida,
    estado:aplicar_efectos([dano(tuerca, 12)]),                       % 10 de 22: menos de dos tercios
    simulador:orden_planificada(2, Cmd),
    assertion(Cmd == descansar).

test(el_despistado_no_descansa_por_su_cuenta, [nondet]) :-
    fijar_estilo(azar),
    nueva_partida,
    estado:aplicar_efectos([dano(tuerca, 12)]),
    simulador:orden_planificada(2, Cmd),
    assertion(Cmd \== descansar),
    fijar_estilo(solo_atacar).

test(con_la_banda_sana_no_descansa, [nondet]) :-
    fijar_estilo(solo_atacar),
    nueva_partida,
    simulador:orden_planificada(2, Cmd),
    assertion(Cmd \== descansar).

:- end_tests(los_estilos_de_combate).
