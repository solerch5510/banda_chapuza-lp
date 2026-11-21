% botin.pl (pruebas)
% El botin tras el combate: cada enemigo suelta queso con una probabilidad que es un DATO (mundo:botin/3), y la
% tirada usa la semilla del juego (generador propio, sin random/1), asi que una partida sigue siendo
% reproducible: la misma semilla da el mismo botin. Es el primer azar del juego.
%   (1) la tabla; (2) la regla pura combate:botin_de/5; (3) los efectos al ganar (mensajes y semilla);
%   (4) un combate de verdad; (5) lo que mide el simulador.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/botin -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

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
:- use_module('../herramientas/simulador').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% semilla_con_primera_tirada(+Resultado, -S): una semilla cuya primera tirada de botin (0..99) suelta o no (para una rata)
semilla_con_primera_tirada(hit, S) :-
    mundo:botin(rata_quesera, _, P),
    between(0, 500, S), estado:tirada(100, S, R, _), R < P, !.
semilla_con_primera_tirada(miss, S) :-
    mundo:botin(rata_quesera, _, P),
    between(0, 500, S), estado:tirada(100, S, R, _), R >= P, !.

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% combatir: cada miembro usa su habilidad si puede y, si no, ataca (la misma via que el playtest)
objetivo_fuerte(T) :-
    member(T, [gran_roquefort, bandido_montado, bandido_torpe, moho_saltarin, rata_quesera]),
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

% combatir_juntando(-Items): juega el combate entero y junta todos los items que dijo
combatir_juntando(Todos) :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_turno(Cmd)), orden(Cmd, Is),
        combatir_juntando(Resto), append(Is, Resto, Todos)
    ;   Todos = []
    ).

% las_ratas(+Semilla, -Items): una partida nueva con esa semilla, el contrato de las ratas aceptado y su combate jugado
las_ratas(Semilla, Items) :-
    nueva_partida, estado:aplicar_efectos([fijar_semilla(Semilla)]),
    orden(aceptar(ratas_del_granero), _),
    orden(ir(aldea), I1),
    combatir_juntando(I2),
    append(I1, I2, Items).

:- begin_tests(la_tabla).

test(cada_entrada_tiene_cantidad_positiva_y_probabilidad_valida) :-
    forall(mundo:botin(T, N, P),
           (   assertion(mundo:enemigo(T, _, _, _)), assertion(integer(N)), assertion(N > 0),
               assertion(integer(P)), assertion(P >= 0), assertion(P =< 100) )).

test(los_bandidos_lo_sueltan_siempre) :-
    mundo:botin(bandido_torpe, 1, P1), assertion(P1 == 100),
    mundo:botin(bandido_montado, 1, P2), assertion(P2 == 100).

test(las_ratas_lo_sueltan_a_veces) :-
    mundo:botin(rata_quesera, 1, P), assertion(P > 0), assertion(P < 100).

test(las_ratas_lo_sueltan_el_sesenta_por_ciento_de_las_veces) :-
    % el valor elegido con el simulador (docs/11-balance.md)
    mundo:botin(rata_quesera, 1, P), assertion(P == 60).

test(el_jefe_y_los_mohos_no_tienen_botin) :-
    assertion(\+ mundo:botin(gran_roquefort, _, _)),
    assertion(\+ mundo:botin(moho_saltarin, _, _)).

:- end_tests(la_tabla).

:- begin_tests(la_regla_pura).

test(una_tirada_que_sale_bajo_suelta_el_queso) :-
    semilla_con_primera_tirada(hit, S),
    combate:botin_de([rata_quesera], S, _, Q, T),
    assertion(Q == 1), assertion(T == 1).

test(la_cantidad_manda_cuando_cae) :-
    combate:tirada_de_botin(3, 100, 5, _, Q), assertion(Q == 3),
    combate:tirada_de_botin(3, 0, 5, _, Q0), assertion(Q0 == 0).

test(una_tirada_justo_igual_a_la_probabilidad_no_suelta) :-
    % la tirada va de 0 a 99: con probabilidad 60 sueltan las que dan 0..59, no la que da 60
    between(0, 70000, S), estado:tirada(100, S, 60, _), !,
    combate:tirada_de_botin(1, 60, S, _, Q), assertion(Q == 0),
    between(0, 70000, S2), estado:tirada(100, S2, 59, _), !,
    combate:tirada_de_botin(1, 60, S2, _, Q2), assertion(Q2 == 1).

test(una_tirada_que_sale_alta_no_suelta_nada) :-
    semilla_con_primera_tirada(miss, S),
    combate:botin_de([rata_quesera], S, _, Q, T),
    assertion(Q == 0), assertion(T == 1).

test(la_semilla_avanza_una_vez_por_tirada) :-
    semilla_con_primera_tirada(hit, S),
    combate:botin_de([rata_quesera], S, S1, _, _),
    estado:tirada(100, S, _, Esperada), assertion(S1 == Esperada).

test(dos_ratas_usan_dos_tiradas_seguidas) :-
    combate:botin_de([rata_quesera, rata_quesera], 77, S2, Q, T),
    estado:tirada(100, 77, R1, S1), estado:tirada(100, S1, R2, Esperada),
    mundo:botin(rata_quesera, N, P),
    ( R1 < P -> Hit1 = N ; Hit1 = 0 ), ( R2 < P -> Hit2 = N ; Hit2 = 0 ), QEsperado is Hit1 + Hit2,
    assertion(S2 == Esperada), assertion(T == 2), assertion(Q == QEsperado).

test(un_enemigo_sin_botin_no_tira_ni_toca_la_semilla) :-
    combate:botin_de([moho_saltarin, gran_roquefort], 123, S, Q, T),
    assertion(S == 123), assertion(Q == 0), assertion(T == 0).

test(los_bandidos_dan_siempre_sea_cual_sea_la_semilla) :-
    forall(between(1, 60, S),
           (   combate:botin_de([bandido_torpe, bandido_montado], S, _, Q, T),
               assertion(Q == 2), assertion(T == 2) )).

test(la_frecuencia_de_las_ratas_se_parece_a_su_probabilidad) :-
    % a lo largo de una racha de mil tiradas seguidas (como en una partida larga), no con semillas consecutivas
    mundo:botin(rata_quesera, _, P),
    findall(rata_quesera, between(1, 1000, _), Ratas),
    combate:botin_de(Ratas, 12345, _, N, T),
    assertion(T == 1000),
    Min is (P - 8) * 10, Max is (P + 8) * 10,
    assertion(N >= Min), assertion(N =< Max).

test(la_misma_semilla_da_el_mismo_botin) :-
    combate:botin_de([rata_quesera, rata_quesera, bandido_torpe], 4242, SA, QA, TA),
    combate:botin_de([rata_quesera, rata_quesera, bandido_torpe], 4242, SB, QB, TB),
    assertion(SA-QA-TA == SB-QB-TB).

:- end_tests(la_regla_pura).

:- begin_tests(los_efectos_al_ganar).

test(si_cae_botin_se_anuncia_y_se_guarda_la_semilla) :-
    semilla_con_primera_tirada(hit, S),
    nueva_partida, estado:aplicar_efectos([fijar_semilla(S), iniciar_combate([rata_quesera])]),
    combate:efectos_fin(victoria, Efs),
    assertion(memberchk(ganar_queso(cheddar, 0, 1), Efs)),
    assertion(memberchk(mensaje(botin, [1]), Efs)),
    estado:tirada(100, S, _, Esperada),
    assertion(memberchk(fijar_semilla(Esperada), Efs)).

test(si_no_cae_se_dice_que_no_ha_caido_nada) :-
    semilla_con_primera_tirada(miss, S),
    nueva_partida, estado:aplicar_efectos([fijar_semilla(S), iniciar_combate([rata_quesera])]),
    combate:efectos_fin(victoria, Efs),
    assertion(\+ memberchk(ganar_queso(_, _, _), Efs)),
    assertion(memberchk(mensaje(sin_botin, []), Efs)),
    assertion(memberchk(fijar_semilla(_), Efs)).

test(el_mensaje_de_sin_botin_tiene_texto) :-
    narrador:texto(sin_botin, [], 0, T), assertion(contiene(T, 'ni una corteza')).

test(los_efectos_son_datos_y_no_tocan_el_estado) :-
    nueva_partida, estado:aplicar_efectos([iniciar_combate([rata_quesera, rata_quesera])]),
    estado:semilla(S0), economia:queso_total(Q0),
    combate:efectos_fin(victoria, _),
    estado:semilla(S1), economia:queso_total(Q1),
    assertion(S0 == S1), assertion(Q0 == Q1).

:- end_tests(los_efectos_al_ganar).

:- begin_tests(un_combate_de_verdad).

test(el_botin_de_las_ratas_es_el_que_dicen_las_tiradas) :-
    forall(member(S, [11, 222, 3333, 44444]),
           (   combate:botin_de([rata_quesera, rata_quesera], S, _, Esperado, _),
               las_ratas(S, Items),
               (   Esperado > 0
               ->  assertion(memberchk(msg(botin, [Esperado], _), Items))
               ;   assertion(memberchk(msg(sin_botin, [], _), Items)) ) )).

test(el_queso_del_botin_entra_en_la_despensa) :-
    semilla_con_primera_tirada(hit, S),
    nueva_partida, estado:aplicar_efectos([fijar_semilla(S)]),
    economia:queso_total(Antes),
    orden(aceptar(ratas_del_granero), _), orden(ir(aldea), _),
    economia:queso_total(TrasViaje),
    assertion(TrasViaje =:= Antes - 4),                              % la racion del dia de viaje
    combatir_juntando(Items),
    combate:botin_de([rata_quesera, rata_quesera], S, _, Esperado, _),
    economia:queso_total(Despues),
    findall(x, member(msg(fondue, _, _), Items), Fondues), length(Fondues, NF),   % cada fondue cuesta 1 queso
    assertion(Despues =:= TrasViaje + Esperado - NF),
    assertion(Esperado >= 0),
    assertion(\+ memberchk(error(_), Items)).

test(una_partida_con_la_misma_semilla_se_repite_igual) :-
    las_ratas(31337, I1), economia:queso_total(Q1), estado:semilla(Z1),
    las_ratas(31337, I2), economia:queso_total(Q2), estado:semilla(Z2),
    assertion(I1 == I2), assertion(Q1 == Q2), assertion(Z1 == Z2).

test(semillas_distintas_pueden_dar_botin_distinto) :-
    findall(N, ( between(1, 40, S), combate:botin_de([rata_quesera, rata_quesera], S, _, N, _) ), Ns),
    sort(Ns, Distintos), assertion(length(Distintos, 3)).      % 0, 1 o 2 quesos

:- end_tests(un_combate_de_verdad).

:- begin_tests(lo_que_mide_el_simulador).

test(el_botin_no_rompe_el_equilibrio) :-
    findall(x, ( between(1, 40, I), S is 6000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gs),
    length(Gs, N), assertion(N >= 32).

test(el_simulador_fija_la_semilla_del_juego_en_cada_partida) :-
    episodio(azar, 4321, 0, _), estado:semilla(S1), assertion(S1 == 4321),
    episodio(azar, 99, 0, _), estado:semilla(S2), assertion(S2 == 99).

test(cada_partida_simulada_tira_con_su_propia_semilla) :-
    episodio(plan(0, 2), 11, 400, r(victoria, _, Q1, _)),
    findall(Q, ( between(12, 40, S), episodio(plan(0, 2), S, 400, r(victoria, _, Q, _)) ), Qs),
    sort([Q1|Qs], Distintos), length(Distintos, N), assertion(N >= 2).

:- end_tests(lo_que_mide_el_simulador).
