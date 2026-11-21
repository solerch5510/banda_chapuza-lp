% ayuno.pl (pruebas)
% La regla de hambre mas justa (docs/11-balance.md). Antes, quedarse a cero acababa la partida en el acto, al
% llegar y antes de poder aceptar el contrato que habria pagado. Ahora la Banda aguanta unos dias SEGUIDOS sin
% comer (mundo:parametro(dias_de_ayuno_max, N), 2 por ahora): se pierde por hambre cuando, sin queso y sin nada
% por cobrar, ya se han aguantado todos. Un dia en que todos comen pone la cuenta a cero.
%   (1) el contador y los efectos del ayuno; (2) cuando es derrota; (3) el paso de los dias; (4) los avisos
%   (riesgo, consola, API, web); (5) que el simulador mide menos derrotas por hambre.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/ayuno -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/contratos').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').
:- use_module('../herramientas/simulador').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% con_queso(+N): una partida nueva con exactamente N quesos
con_queso(N) :-
    nueva_partida,
    economia:queso_total(T0),
    Gasto is T0 - N,
    (   Gasto > 0 -> economia:efectos_perdida(Gasto, Es), estado:aplicar_efectos(Es) ; true ).

% con_ayuno(+Dias): el contador de dias seguidos sin comer
con_ayuno(Dias) :-
    estado:aplicar_efectos([borrar_contador(dias_de_ayuno)]),
    (   Dias > 0 -> estado:aplicar_efectos([contar(dias_de_ayuno, Dias)]) ; true ).

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).
hambre(Items) :- memberchk(msg(fin_hambre, [], _), Items).

:- begin_tests(el_contador).

test(al_empezar_no_hay_ayuno) :-
    nueva_partida, economia:dias_de_ayuno(D), assertion(D == 0).

test(el_limite_es_un_parametro_positivo) :-
    mundo:parametro(dias_de_ayuno_max, M), assertion(integer(M)), assertion(M >= 1).

test(un_dia_con_hambre_suma_uno) :-
    economia:efectos_ayuno([mensaje(sin_comida, [tuerca]), gastar_queso(cheddar, 0, 1)], Efs),
    assertion(Efs == [contar(dias_de_ayuno, 1)]).

test(un_dia_en_que_todos_comen_pone_la_cuenta_a_cero) :-
    economia:efectos_ayuno([gastar_queso(cheddar, 0, 1), gastar_queso(cheddar, 0, 1)], Efs),
    assertion(Efs == [borrar_contador(dias_de_ayuno)]).

test(el_contador_sube_y_se_borra_en_el_estado) :-
    nueva_partida, con_ayuno(1),
    estado:aplicar_efectos([contar(dias_de_ayuno, 1)]),
    economia:dias_de_ayuno(D), assertion(D == 2),
    estado:aplicar_efectos([borrar_contador(dias_de_ayuno)]),
    economia:dias_de_ayuno(D0), assertion(D0 == 0).

test(una_partida_nueva_olvida_el_ayuno) :-
    nueva_partida, con_ayuno(2), nueva_partida,
    economia:dias_de_ayuno(D), assertion(D == 0).

:- end_tests(el_contador).

:- begin_tests(cuando_es_derrota).

test(a_cero_sin_ayuno_no_es_derrota) :-
    con_queso(0), con_ayuno(0), assertion(\+ economia:derrota_por_hambre).

test(un_dia_de_ayuno_aun_se_aguanta) :-
    con_queso(0), con_ayuno(1), assertion(\+ economia:derrota_por_hambre).

test(con_todos_los_dias_de_ayuno_es_derrota) :-
    con_queso(0), mundo:parametro(dias_de_ayuno_max, M), con_ayuno(M),
    assertion(economia:derrota_por_hambre).

test(pasados_los_dias_tambien) :-
    con_queso(0), con_ayuno(7), assertion(economia:derrota_por_hambre).

test(con_queso_no_es_derrota_por_mucho_ayuno_que_lleve) :-
    con_queso(1), con_ayuno(7), assertion(\+ economia:derrota_por_hambre).

test(con_algo_por_cobrar_no_es_derrota) :-
    con_queso(0), con_ayuno(7),
    estado:aplicar_efectos([contrato_aceptar(ratas_del_granero), contrato_resolver(ratas_del_granero, exito)]),
    assertion(\+ economia:derrota_por_hambre).

:- end_tests(cuando_es_derrota).

:- begin_tests(el_paso_de_los_dias).

test(comerse_el_ultimo_queso_ya_no_acaba_la_partida) :-
    con_queso(4),
    orden(ir(aldea), Items),                 % todos comen: queso a cero, nadie ha pasado hambre
    assertion(\+ hambre(Items)),
    assertion(\+ estado:fin_partida(_)),
    economia:queso_total(Q), assertion(Q == 0),
    economia:dias_de_ayuno(D), assertion(D == 0).

test(el_primer_dia_sin_comer_cuenta_uno_y_sigue_la_partida) :-
    con_queso(0), orden(ir(aldea), Items),
    assertion(\+ hambre(Items)),
    economia:dias_de_ayuno(D), assertion(D == 1),
    assertion(\+ estado:fin_partida(_)).

test(el_segundo_dia_sin_comer_acaba_la_partida) :-
    con_queso(0),
    orden(ir(aldea), _), orden(ir(taberna), Items),
    assertion(hambre(Items)),
    assertion(estado:fin_partida(derrota(derrota_hambre))).

test(un_dia_alimentado_pone_la_cuenta_a_cero) :-
    con_queso(0), orden(ir(aldea), _),
    economia:dias_de_ayuno(D1), assertion(D1 == 1),
    estado:aplicar_efectos([ganar_queso(cheddar, 0, 12)]),
    orden(ir(taberna), _),
    economia:dias_de_ayuno(D2), assertion(D2 == 0).

test(descansar_cuenta_igual_que_viajar) :-
    con_queso(2), con_ayuno(1),
    orden(descansar, Items),                 % se paga el descanso y nadie come
    assertion(hambre(Items)),
    assertion(estado:fin_partida(derrota(derrota_hambre))).

test(se_puede_cobrar_estando_en_ayuno_y_la_partida_sigue) :-
    % el caso de la partida perdida: sin queso, un dia de ayuno, un contrato resuelto y volver a cobrar
    con_queso(8),
    orden(ir(aldea), _),
    economia:efectos_perdida(4, Es), estado:aplicar_efectos(Es),
    con_ayuno(1),
    estado:aplicar_efectos([contrato_aceptar(ratas_del_granero), contrato_resolver(ratas_del_granero, exito)]),
    orden(ir(taberna), Items),               % otro dia sin comer, pero llega y cobra
    assertion(\+ hambre(Items)),
    assertion(\+ estado:fin_partida(_)),
    contratos:pago_de(ratas_del_granero, Pago),
    economia:queso_total(Q), assertion(Q == Pago).

test(sin_cobrar_nada_el_mismo_viaje_si_acaba_en_derrota) :-
    con_queso(8),
    orden(ir(aldea), _),
    economia:efectos_perdida(4, Es), estado:aplicar_efectos(Es),
    con_ayuno(1),
    orden(ir(taberna), Items),
    assertion(hambre(Items)).

:- end_tests(el_paso_de_los_dias).

:- begin_tests(los_avisos).

test(a_cero_pero_con_margen_de_ayuno_es_un_aviso_suave) :-
    con_queso(4), con_ayuno(0),
    economia:riesgo_de_gasto(0, R), assertion(R == a_cero).

test(un_dia_de_ayuno_y_otro_sin_comer_es_mortal) :-
    con_queso(0), con_ayuno(1),
    economia:riesgo_de_gasto(0, R), assertion(R == hambre_mortal).

test(sin_ayuno_previo_un_dia_sin_comer_no_es_mortal) :-
    con_queso(0), con_ayuno(0),
    economia:riesgo_de_gasto(0, R), assertion(R == a_cero).

test(con_ayuno_previo_pero_comida_para_manana_no_es_mortal) :-
    % queda justo una racion: mañana comen todos y la cuenta vuelve a cero
    con_queso(4), con_ayuno(1),
    economia:riesgo_de_gasto(0, R), assertion(R == a_cero).

test(con_algo_por_cobrar_es_sin_queso_y_no_mortal) :-
    con_queso(0), con_ayuno(1),
    estado:aplicar_efectos([contrato_aceptar(ratas_del_granero), contrato_resolver(ratas_del_granero, exito)]),
    economia:riesgo_de_gasto(0, R), assertion(R == sin_queso).

test(la_consola_cuenta_los_dias_de_ayuno) :-
    con_queso(0), con_ayuno(1),
    orden(mirar, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'Ayuno: llevas 1 de 2 días seguidos sin comer')).

test(sin_ayuno_la_consola_no_dice_nada_de_ayuno) :-
    nueva_partida, orden(mirar, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(\+ contiene(T, 'Ayuno')).

test(el_aviso_de_a_cero_tiene_texto_y_no_es_el_del_peligro) :-
    narrador:texto_riesgo(a_cero, T), assertion(contiene(T, 'os quedáis sin queso')),
    assertion(\+ contiene(T, 'Peligro')).

test(la_api_trae_el_ayuno) :-
    con_queso(0), con_ayuno(1),
    api:estado_json(E), campo(E, comida, C),
    campo(C, ayuno, A), campo(C, ayuno_max, M), campo(C, riesgo, R),
    assertion(A == 1), assertion(M == 2), assertion(R == hambre_mortal).

test(la_web_enseña_el_ayuno_y_pinta_el_riesgo_a_cero) :-
    setup_call_cleanup(open('web/app.js', read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs0) ), close(S)),
    exclude(==(13), Cs0, Cs), atom_codes(J, Cs),
    assertion(contiene(J, 'c.ayuno')), assertion(contiene(J, 'c.ayuno_max')),
    setup_call_cleanup(open('web/app.css', read, S2, [type(binary)]),
                       ( set_stream(S2, encoding(utf8)), read_stream_to_codes(S2, Cs2) ), close(S2)),
    atom_codes(Css, Cs2),
    assertion(contiene(Css, '.comida.a_cero { color: var(--cheddar)')).

:- end_tests(los_avisos).

:- begin_tests(lo_que_mide_el_simulador).

test(con_la_regla_nueva_el_jugador_con_plan_pierde_poco_por_hambre) :-
    findall(x, ( between(1, 40, I), S is 5000 + I, episodio(plan(10, 2), S, 400, r(hambre, _, _, _)) ), Hs),
    length(Hs, N), assertion(N =< 6).

test(y_gana_la_gran_mayoria) :-
    findall(x, ( between(1, 40, I), S is 5000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gs),
    length(Gs, N), assertion(N >= 30).

:- end_tests(lo_que_mide_el_simulador).
