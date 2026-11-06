% bucle.pl (pruebas)
% T-23: el combate de principio a fin. Fin de combate (victoria y derrota), terminar_combate
% (los caidos se levantan con 1 de vida), el turno enemigo provisional, el bucle de juego
% (comenzar_combate/2 y avanzar_combate/1), el comando provisional pelear(Grupo) y lo que
% ve el jugador (mirar en combate, mensajes, explicar tras un turno enemigo).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/bucle -g "run_tests,halt" -t "halt(1)"

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

% Combate empezado con el bucle real: devuelve lo que paso al empezar.
empieza(Tipos, Items) :-
    nueva_partida,
    comenzar_combate(Tipos, Items).

empieza(Tipos) :-
    empieza(Tipos, _).

% Un combate montado con los efectos (sin el bucle): para probar reglas sueltas.
montado(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]).

moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

% Cae todo el bando de los miembros menos los indicados (que quedan con la vida dada).
solo_en_pie(Id, Vida) :-
    forall(( compania:miembro(M), M \== Id ), aplicar_efecto(dano(M, 99))),
    estado:vida(Id, V0),
    D is V0 - Vida,
    aplicar_efecto(dano(Id, D)).

% En el turno de quien actua, defiende (por si hay que dejar pasar los turnos de los miembros).
defiende_todos([]).
defiende_todos([_|Resto]) :-
    ordena(defender, _),
    defiende_todos(Resto).

:- begin_tests(fin_de_combate).

test(al_empezar_no_hay_fin, [fail]) :-
    montado([bandido_torpe]),
    combate:fin_combate(_).

test(sin_enemigos_en_pie_se_gana, [nondet]) :-
    montado([bandido_torpe, rata_quesera]),
    aplicar_efecto(dano(e(bandido_torpe, 1), 99)),
    aplicar_efecto(dano(e(rata_quesera, 1), 99)),
    combate:fin_combate(victoria).

test(con_un_enemigo_en_pie_no_se_gana, [fail]) :-
    montado([bandido_torpe, rata_quesera]),
    aplicar_efecto(dano(e(bandido_torpe, 1), 99)),
    combate:fin_combate(_).

test(sin_miembros_en_pie_se_pierde, [nondet]) :-
    montado([bandido_torpe]),
    forall(compania:miembro(M), aplicar_efecto(dano(M, 99))),
    combate:fin_combate(derrota).

test(con_un_miembro_en_pie_no_se_pierde, [fail]) :-
    montado([bandido_torpe]),
    solo_en_pie(rufino, 1),
    combate:fin_combate(_).

test(un_huelguista_vivo_cuenta_como_en_pie, [fail]) :-
    montado([bandido_torpe]),
    solo_en_pie(rufino, 5),
    moral_a(rufino, 0),
    combate:fin_combate(_).

test(hay_un_solo_resultado, [nondet]) :-
    montado([bandido_torpe]),
    forall(compania:miembro(M), aplicar_efecto(dano(M, 99))),
    aplicar_efecto(dano(e(bandido_torpe, 1), 99)),
    findall(R, combate:fin_combate(R), Rs),
    Rs == [derrota].

test(fuera_de_combate_no_hay_fin, [setup(nueva_partida), fail]) :-
    combate:fin_combate(_).

:- end_tests(fin_de_combate).

:- begin_tests(efectos_de_fin).

test(la_victoria_da_botin_por_cada_enemigo_que_lleva_queso, [nondet]) :-
    montado([bandido_torpe, bandido_montado, rata_quesera]),
    combate:efectos_fin(victoria, Efs),
    memberchk(ganar_queso(cheddar, 0, 2), Efs),
    memberchk(mensaje(botin, [2]), Efs).

test(sin_enemigos_con_queso_no_hay_botin, [nondet]) :-
    montado([rata_quesera, moho_saltarin]),
    combate:efectos_fin(victoria, Efs),
    \+ memberchk(ganar_queso(_, _, _), Efs),
    \+ memberchk(mensaje(botin, _), Efs).

test(la_victoria_sube_la_moral_de_todos, [nondet]) :-
    montado([rata_quesera]),
    combate:efectos_fin(victoria, Efs),
    mundo:parametro(moral_victoria, Sube),
    forall(member(M, [baldomero, pimentina, rufino, tuerca]),
           memberchk(mod_moral(M, Sube), Efs)).

test(la_victoria_termina_el_combate_al_final, [nondet]) :-
    montado([rata_quesera]),
    combate:efectos_fin(victoria, Efs),
    last(Efs, Ultimo),
    Ultimo == terminar_combate,
    memberchk(mensaje(victoria, []), Efs).

test(la_derrota_acaba_la_partida) :-
    montado([rata_quesera]),
    combate:efectos_fin(derrota, Efs),
    Efs == [fin(derrota(derrota_combate)), mensaje(derrota_combate, [])].

test(los_efectos_de_fin_no_modifican_el_estado) :-
    montado([bandido_torpe]),
    foto_estado(Antes),
    combate:efectos_fin(victoria, _),
    combate:efectos_fin(derrota, _),
    foto_estado(Despues),
    Antes == Despues.

test(un_resultado_desconocido_no_tiene_efectos, [fail]) :-
    montado([bandido_torpe]),
    combate:efectos_fin(empate, _).

:- end_tests(efectos_de_fin).

:- begin_tests(terminar_combate).

test(desaparece_todo_lo_del_combate) :-
    montado([bandido_torpe, rata_quesera]),
    aplicar_efecto(siguiente_ronda([baldomero])),
    aplicar_efecto(alterar(baldomero, defendiendo, 1)),
    aplicar_efecto(terminar_combate),
    \+ estado:en_combate(_),
    \+ estado:combatiente(_, _),
    \+ estado:instancia(_, _),
    \+ estado:cola_turnos(_),
    \+ estado:alterado(_, _, _),
    \+ estado:vida(e(_, _), _),
    \+ estado:fila(e(_, _), _).

test(los_caidos_se_levantan_con_uno, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(dano(tuerca, 99)),
    aplicar_efecto(dano(rufino, 99)),
    aplicar_efecto(terminar_combate),
    estado:vida(tuerca, 1),
    estado:vida(rufino, 1).

test(los_que_siguen_en_pie_no_cambian_de_vida, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 7)),
    aplicar_efecto(terminar_combate),
    estado:vida(baldomero, 23),
    estado:vida(pimentina, 18).

test(las_filas_de_los_miembros_se_conservan) :-
    montado([bandido_torpe]),
    aplicar_efecto(terminar_combate),
    forall(member(Id-F, [baldomero-frente, pimentina-retaguardia, rufino-retaguardia, tuerca-frente]),
           estado:fila(Id, F)).

test(la_moral_y_la_despensa_no_cambian) :-
    montado([bandido_torpe]),
    findall(H, ( member(N/A, [moral/2, queso/3, lleva/3, dia/1, en_compania/1]), functor(H, N, A), call(H) ), Antes),
    aplicar_efecto(terminar_combate),
    findall(H, ( member(N/A, [moral/2, queso/3, lleva/3, dia/1, en_compania/1]), functor(H, N, A), call(H) ), Despues),
    Antes == Despues.

test(sin_combate_no_se_termina, [setup(nueva_partida), fail]) :-
    aplicar_efecto(terminar_combate).

test(la_fase_vuelve_a_la_normal, [nondet]) :-
    montado([bandido_torpe]),
    estado:fase(combate),
    aplicar_efecto(terminar_combate),
    estado:fase(taberna).

test(se_puede_empezar_otro_combate_despues, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(terminar_combate),
    aplicar_efectos([iniciar_combate([rata_quesera])]),
    estado:instancia(e(rata_quesera, 1), rata_quesera).

test(una_transaccion_deshace_terminar_si_falla) :-
    montado([bandido_torpe]),
    foto_estado(Antes),
    \+ con_transaccion(( aplicar_efecto(terminar_combate), fail )),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(terminar_combate).

:- begin_tests(accion_enemigo).

test(ataca_al_mas_debil_de_los_que_alcanza, [nondet]) :-
    montado([bandido_torpe]),
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    Accion == atacar(tuerca).                          % de los de primera fila, la de menos vida

test(si_el_mas_debil_esta_en_la_retaguardia_no_lo_alcanza, [nondet]) :-
    montado([bandido_torpe]),
    combate:accion_enemigo(e(bandido_torpe, 1), atacar(B)),
    B \== pimentina,
    B \== rufino.

test(con_el_frente_caido_alcanza_la_retaguardia, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 99)),
    aplicar_efecto(dano(tuerca, 99)),
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    Accion == atacar(pimentina).                       % 18 de vida contra 20 de Rufino

test(a_igual_vida_manda_el_id, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(dano(baldomero, 99)),
    aplicar_efecto(dano(tuerca, 99)),
    aplicar_efecto(dano(rufino, 2)),                   % Rufino 18 = Pimentina 18
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    Accion == atacar(pimentina).

test(sin_objetivos_se_defiende, [nondet]) :-
    montado([bandido_torpe]),
    retractall(estado:combatiente(_, jugador)),
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    Accion == defender.

test(el_comodin_manda_defender_aunque_no_pueda_el_corte_rojo, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(alterar(e(bandido_torpe, 1), aturdido, 1)),
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    Accion == defender,                                % el comodin no repite condiciones
    \+ combate:efectos_accion(e(bandido_torpe, 1), defender, _).   % ...y aqui no se puede ejecutar

test(siempre_hay_exactamente_una_accion) :-
    forall(member(Tipos, [[bandido_torpe], [rata_quesera, moho_saltarin], [gran_roquefort]]),
           (   montado(Tipos),
               forall(estado:instancia(E, _),
                      (   findall(A, combate:accion_enemigo(E, A), As),
                          As = [_]
                      ))
           )).

test(la_accion_se_puede_aplicar, [nondet]) :-
    montado([bandido_torpe]),
    combate:accion_enemigo(e(bandido_torpe, 1), Accion),
    combate:efectos_accion(e(bandido_torpe, 1), Accion, Efs),
    aplicar_efectos(Efs),
    estado:vida(tuerca, V),
    V == 19.                                           % 22 - (5 - 2)

test(pasar_solo_avisa, [nondet]) :-
    montado([bandido_torpe]),
    combate:efectos_accion(e(bandido_torpe, 1), pasar, Efs),
    Efs == [mensaje(pasa, [e(bandido_torpe, 1)])].

test(solve_da_lo_mismo_que_ejecutar_la_decision) :-
    forall(member(Tipos, [[bandido_torpe], [gran_roquefort, rata_quesera]]),
           (   montado(Tipos),
               forall(estado:instancia(E, _),
                      (   findall(A, combate:accion_enemigo(E, A), Directo),
                          findall(A, solve(combate:accion_enemigo(E, A), _), ConSolve),
                          Directo == ConSolve
                      ))
           )).

test(la_decision_no_modifica_el_estado) :-
    montado([bandido_torpe, rata_quesera]),
    foto_estado(Antes),
    forall(estado:instancia(E, _), ( combate:accion_enemigo(E, _) -> true ; true )),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(accion_enemigo).

:- begin_tests(bucle_de_combate).

test(al_empezar_actua_el_primero_y_se_espera_al_jugador) :-
    empieza([bandido_torpe], Items),
    Items = [msg(aparece, [bandido_torpe], 0)],
    estado:cola_turnos([Primero|_]),
    Primero == baldomero.

test(se_avisa_de_cada_tipo_una_vez) :-
    empieza([rata_quesera, rata_quesera, bandido_torpe], Items),
    findall(T, member(msg(aparece, [T], _), Items), Ts),
    msort(Ts, S),
    S == [bandido_torpe, rata_quesera].

test(al_empezar_la_fase_es_combate, [nondet]) :-
    empieza([bandido_torpe]),
    estado:fase(combate),
    estado:en_combate(R),
    R == 1.

test(un_enemigo_mas_rapido_actua_antes_que_el_jugador, [nondet]) :-
    nueva_partida,
    moral_a(baldomero, 2),                            % en huelga: no actua
    comenzar_combate([gran_roquefort], Items),
    memberchk(msg(invoca_moho, [e(gran_roquefort, 1)], _), Items),   % el jefe invoca antes de pegar
    estado:instancia(e(moho_saltarin, 1), moho_saltarin),
    estado:cola_turnos([Siguiente|_]),
    Siguiente == pimentina.

test(avanzar_sin_combate_no_hace_nada, [setup(nueva_partida)]) :-
    avanzar_combate(Items),
    Items == [].

test(avanzar_con_el_turno_de_un_miembro_espera) :-
    empieza([bandido_torpe]),
    foto_estado(Antes),
    avanzar_combate(Items),
    foto_estado(Despues),
    Items == [],
    Antes =@= Despues.

test(tras_los_miembros_actua_el_enemigo, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _),                              % Baldomero
    ordena(defender, _),                              % Pimentina
    ordena(defender, Items),                          % Tuerca: ahora le toca al bandido
    memberchk(msg(golpe, [e(bandido_torpe, 1), tuerca, 1], _), Items),   % 5 - (2 + 2)
    estado:cola_turnos([Siguiente|_]),
    Siguiente == rufino.

test(el_enemigo_pega_menos_a_quien_se_defiende, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _),
    ordena(defender, _),
    ordena(defender, Items),
    memberchk(msg(golpe, [_, tuerca, D], _), Items),
    D == 1.

test(la_ronda_siguiente_empieza_sola, [nondet]) :-
    empieza([gran_roquefort]),
    defiende_todos([a, b, c, d]),                      % los cuatro miembros; actua el jefe entre medias
    estado:en_combate(R),
    R == 2,
    estado:cola_turnos([Primero|_]),
    Primero == baldomero.

test(defender_dura_hasta_el_siguiente_turno_de_quien_defendio, [nondet]) :-
    empieza([gran_roquefort]),
    ordena(defender, _),                               % Baldomero defiende
    estado:alterado(baldomero, defendiendo, 1),
    defiende_todos([b, c, d]),                         % el resto de la ronda; ahora otra vez Baldomero
    estado:cola_turnos([baldomero|_]),
    \+ estado:alterado(baldomero, defendiendo, _).

test(un_aturdido_pierde_el_turno_con_aviso, [nondet]) :-
    empieza([gran_roquefort]),
    aplicar_efecto(alterar(pimentina, aturdido, 1)),
    ordena(defender, Items),                           % Baldomero; Pimentina pierde el turno
    memberchk(msg(aturdido, [pimentina], _), Items),
    \+ estado:alterado(pimentina, aturdido, _),
    estado:cola_turnos([Siguiente|_]),
    Siguiente == tuerca.

test(un_aturdido_dos_turnos_pierde_dos_rondas, [nondet]) :-
    empieza([gran_roquefort]),
    aplicar_efecto(alterar(pimentina, aturdido, 2)),
    ordena(defender, _),
    estado:alterado(pimentina, aturdido, 1).

test(quien_cae_a_mitad_de_ronda_no_actua_y_no_hay_aviso, [nondet]) :-
    empieza([gran_roquefort]),
    aplicar_efecto(dano(pimentina, 99)),
    ordena(defender, Items),
    \+ memberchk(msg(_, [pimentina|_], _), Items),
    estado:cola_turnos([Siguiente|_]),
    Siguiente == tuerca.

test(el_turno_enemigo_guarda_su_prueba, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    estado:ultima_prueba(Clave, _),
    Clave == accion_enemigo(e(bandido_torpe, 1)).

test(el_bucle_deja_el_estado_consistente, [nondet]) :-
    empieza([gran_roquefort, bandido_torpe]),
    defiende_todos([a, b, c, d, e, f, g, h]),
    estado:en_combate(_),
    findall(F, estado:fase(F), Fs),
    Fs == [combate],
    forall(estado:combatiente(Id, _), ( estado:vida(Id, _), estado:fila(Id, _) )).

:- end_tests(bucle_de_combate).

:- begin_tests(ganar_y_perder).

test(ganar_cierra_el_combate_y_da_el_botin, [nondet]) :-
    empieza([bandido_torpe]),
    economia:queso_total(Antes),
    ordena(atacar(bandido_torpe), _),                  % Baldomero: 9
    ordena(atacar(bandido_torpe), Items),              % Pimentina: 4, cae
    memberchk(msg(victoria, [], _), Items),
    memberchk(msg(botin, [1], _), Items),
    \+ estado:en_combate(_),
    economia:queso_total(Despues),
    Despues =:= Antes + 1.

test(ganar_sube_la_moral_de_todos) :-
    empieza([bandido_torpe]),
    ordena(atacar(bandido_torpe), _),
    ordena(atacar(bandido_torpe), _),
    forall(compania:miembro(M), ( estado:moral(M, V), V == 7 )).

test(el_caido_tambien_celebra_la_victoria, [nondet]) :-
    empieza([bandido_torpe]),
    aplicar_efecto(dano(rufino, 99)),                  % Rufino cae antes de actuar
    ordena(atacar(bandido_torpe), _),
    ordena(atacar(bandido_torpe), _),
    estado:moral(rufino, M),
    M == 7.

test(tras_ganar_la_fase_vuelve_a_la_zona) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(atacar(rata_quesera), _),
    once(estado:fase(F)),
    F == exploracion.

test(los_caidos_se_levantan_con_uno_al_ganar, [nondet]) :-
    empieza([bandido_torpe]),
    aplicar_efecto(dano(rufino, 99)),                  % Rufino cae antes de actuar
    ordena(atacar(bandido_torpe), _),
    ordena(atacar(bandido_torpe), _),
    \+ estado:en_combate(_),
    estado:vida(rufino, 1).

test(una_rata_cae_de_un_golpe_y_se_gana_sin_botin, [nondet]) :-
    empieza([rata_quesera]),
    ordena(atacar(rata_quesera), Items),
    memberchk(msg(victoria, [], _), Items),
    \+ memberchk(msg(botin, _, _), Items),
    \+ estado:en_combate(_).

test(perder_acaba_la_partida, [nondet]) :-
    nueva_partida,
    solo_en_pie(baldomero, 1),
    comenzar_combate([bandido_torpe], _),
    ordena(defender, Items),                           % se defiende, pero 5 - 5 = 0 sube a 1 y le basta
    memberchk(msg(cae, [baldomero], _), Items),
    memberchk(msg(derrota_combate, [], _), Items),
    estado:fin_partida(derrota(derrota_combate)),
    once(estado:fase(F)),
    F == fin.

test(tras_perder_ya_no_se_ataca) :-
    nueva_partida,
    solo_en_pie(baldomero, 1),
    comenzar_combate([bandido_torpe], _),
    ordena(defender, _),
    ordena(atacar(bandido_torpe), Items),
    Items = [error(fuera_de_fase(_, fin))].

test(un_combate_largo_acaba_de_una_forma_u_otra, [nondet]) :-
    empieza([gran_roquefort]),
    jugar_hasta_el_final(200, Final),
    memberchk(Final, [victoria, derrota]).

test(un_combate_contra_ratas_se_gana, [nondet]) :-
    empieza([rata_quesera, rata_quesera, rata_quesera]),
    jugar_hasta_el_final(60, Final),
    Final == victoria.

jugar_hasta_el_final(Pasos, Final) :-
    (   estado:fin_partida(_)
    ->  Final = derrota
    ;   \+ estado:en_combate(_)
    ->  Final = victoria
    ;   Pasos =< 0
    ->  Final = sin_acabar
    ;   (   ordena(atacar(rata_quesera), I), \+ I = [error(_)|_] -> true
        ;   ordena(atacar(bandido_torpe), I2), \+ I2 = [error(_)|_] -> true
        ;   ordena(atacar(gran_roquefort), I3), \+ I3 = [error(_)|_] -> true
        ;   ordena(atacar(moho_saltarin), I4), \+ I4 = [error(_)|_] -> true
        ;   ordena(defender, _)
        ),
        P1 is Pasos - 1,
        jugar_hasta_el_final(P1, Final)
    ).

:- end_tests(ganar_y_perder).

:- begin_tests(comando_pelear).

test(pelear_empieza_un_combate_en_exploracion) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(bandido_torpe), Items),
    memberchk(msg(aparece, [bandido_torpe], _), Items),
    once(estado:fase(F)),
    F == combate.

test(pelear_acepta_una_lista, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear([rata_quesera, rata_quesera]), _),
    estado:instancia(e(rata_quesera, 2), rata_quesera).

test(en_la_taberna_no_se_pelea, [setup(nueva_partida)]) :-
    ordena(pelear(rata_quesera), Items),
    Items == [error(fuera_de_fase(pelear(rata_quesera), taberna))].

test(dentro_de_un_combate_no_se_empieza_otro) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(pelear(bandido_torpe), Items),
    Items == [error(fuera_de_fase(pelear(bandido_torpe), combate))].

test(un_enemigo_desconocido_es_un_error) :-
    nueva_partida,
    ordena(ir(aldea), _),
    foto_estado(Antes),
    ordena(pelear(dragon), Items),
    foto_estado(Despues),
    Items == [error(grupo_desconocido(dragon))],
    Antes =@= Despues.

test(una_lista_con_un_desconocido_no_empieza_nada) :-
    nueva_partida,
    ordena(ir(aldea), _),
    foto_estado(Antes),
    ordena(pelear([rata_quesera, dragon]), Items),
    foto_estado(Despues),
    Items == [error(grupo_desconocido([rata_quesera, dragon]))],
    Antes =@= Despues.

test(una_lista_vacia_no_es_un_combate) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear([]), Items),
    Items == [error(grupo_desconocido([]))].

test(un_miembro_no_es_un_enemigo) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(baldomero), Items),
    Items == [error(grupo_desconocido(baldomero))].

test(pelear_con_variable_falta_argumento) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(_), Items),
    Items = [error(falta_argumento(_))].

test(la_ayuda_de_exploracion_incluye_pelear_y_la_de_taberna_no, [nondet]) :-
    comandos_disponibles(exploracion, E),
    comandos_disponibles(taberna, T),
    memberchk(pelear, E),
    \+ memberchk(pelear, T).

test(pelear_tiene_ayuda, [nondet]) :-
    narrador:ayuda_de(pelear, _).

:- end_tests(comando_pelear).

:- begin_tests(ver_el_combate).

test(mirar_en_combate_ensena_el_combate, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(mirar, Items),
    Items = [vista(zona, _), vista(combate, combate(Ronda, Turno, Enemigos))],
    Ronda == 1,
    Turno == baldomero,
    Enemigos = [enemigo(e(bandido_torpe, 1), 12, 12, frente)].

test(mirar_fuera_de_combate_no_cambia, [setup(nueva_partida)]) :-
    ordena(mirar, Items),
    Items = [vista(zona, _)].

test(mirar_tras_ganar_ya_no_ensena_combate, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(atacar(rata_quesera), _),
    ordena(mirar, Items),
    Items = [vista(zona, _)].

test(se_ve_el_estado_de_los_enemigos, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear([bandido_torpe, rata_quesera]), _),
    pantalla(mirar, Texto),
    sub_atom(Texto, _, _, _, 'Combate · ronda 1 · turno de Sir Baldomero'),
    sub_atom(Texto, _, _, _, 'el Bandido Torpe: vida 12/12 (frente)'),
    sub_atom(Texto, _, _, _, 'la Rata Quesera: vida 8/8 (frente)').

test(un_enemigo_caido_se_ve_como_caido, [nondet]) :-
    empieza([bandido_torpe, rata_quesera]),
    aplicar_efecto(dano(e(rata_quesera, 1), 99)),
    pantalla(mirar, Texto),
    sub_atom(Texto, _, _, _, 'la Rata Quesera: caído').

test(se_cuenta_el_combate_entero_sin_terminos_crudos) :-
    nueva_partida,
    ordena(ir(aldea), _),
    forall(member(Cmd, [pelear([bandido_torpe, bandido_torpe]), mirar, atacar(bandido_torpe), defender,
                        atacar(bandido_torpe), atacar(bandido_torpe), mirar, atacar(bandido_torpe),
                        atacar(bandido_torpe), atacar(bandido_torpe), compania, inventario, explicar]),
           (   pantalla(Cmd, Texto),
               \+ sub_atom(Texto, _, _, _, 'msg('),
               \+ sub_atom(Texto, _, _, _, 'error('),
               \+ sub_atom(Texto, _, _, _, '~w'),
               \+ sub_atom(Texto, _, _, _, '[msg')
           )).

test(se_narra_el_botin_la_victoria_y_la_derrota, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(bandido_torpe), _),
    ordena(atacar(bandido_torpe), _),
    pantalla(atacar(bandido_torpe), Texto),
    sub_atom(Texto, _, _, _, 'Victoria.'),
    sub_atom(Texto, _, _, _, 'Botín: 1 queso fresco').

test(se_narra_el_aviso_de_aturdido, [nondet]) :-
    empieza([gran_roquefort]),
    aplicar_efecto(alterar(pimentina, aturdido, 1)),
    pantalla(defender, Texto),
    sub_atom(Texto, _, _, _, 'Madame Pimentina pierde el turno').

:- end_tests(ver_el_combate).

:- begin_tests(explicar_el_turno_enemigo).

test(explicar_tras_un_turno_enemigo_da_su_decision, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == accion_enemigo(e(bandido_torpe, 1)).

test(la_prueba_de_la_decision_nombra_la_accion_elegida, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    ordena(explicar, [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] accion_enemigo(e(bandido_torpe, 1), atacar(tuerca))   [clausula 5 + corte]', Lineas).

test(la_prueba_ensena_el_objetivo_mas_debil, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    ordena(explicar, [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'objetivo_mas_debil(e(bandido_torpe, 1), tuerca)') )).

test(la_pantalla_dice_quien_decidio, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    pantalla(explicar, Texto),
    sub_atom(Texto, _, _, _, 'Por qué el Bandido Torpe hizo eso:').

test(la_prueba_es_la_de_antes_del_golpe, [nondet]) :-
    empieza([bandido_torpe]),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    ordena(explicar, [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'vida(tuerca, 22)') )).

:- end_tests(explicar_el_turno_enemigo).
