% usar.pl (pruebas)
% Usar un objeto (usar(Objeto, Miembro)): hasta ahora solo los enemigos gastaban pociones, asi que el objeto que
% daba un contrato o un NPC no valia nada para el jugador. Ahora una pocion cura a un miembro herido:
%   fuera de combate no pasa el tiempo; en combate es la accion del turno (y pasa el turno).
%   (1) la regla pura y sus efectos; (2) fuera de combate; (3) en combate; (4) errores y por_que_no;
%   (5) consola, API y web; (6) de donde salen las pociones.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/usar -g "run_tests,halt" -t "halt(1)" < /dev/null

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
:- use_module('../src/charlas', []).
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% con_pocion(+N): una partida nueva con N pociones en el inventario comun
con_pocion(N) :-
    nueva_partida,
    (   N > 0 -> estado:aplicar_efectos([ganar_objeto(compania, pocion, N)]) ; true ).

herido(Id, Dano) :- estado:aplicar_efectos([dano(Id, Dano)]).

pociones(N) :- ( estado:lleva(compania, pocion, V) -> N = V ; N = 0 ).

vida_de(Id, V) :- estado:vida(Id, V).

:- begin_tests(la_regla).

test(una_pocion_y_un_herido_se_pueden_usar) :-
    con_pocion(1), herido(tuerca, 5), assertion(economia:puede_usar(pocion, tuerca)).

test(un_miembro_sano_no_necesita_pocion) :-
    con_pocion(1), assertion(\+ economia:puede_usar(pocion, tuerca)).

test(sin_pociones_no_se_puede) :-
    con_pocion(0), herido(tuerca, 5), assertion(\+ economia:puede_usar(pocion, tuerca)).

test(un_miembro_caido_no_se_cura_con_pocion) :-
    con_pocion(1), herido(tuerca, 999), assertion(\+ economia:puede_usar(pocion, tuerca)).

test(solo_curan_los_objetos_que_curan) :-
    con_pocion(1), herido(tuerca, 5),
    estado:aplicar_efectos([ganar_objeto(compania, venda_de_caballos, 1)]),
    assertion(\+ economia:puede_usar(venda_de_caballos, tuerca)).

test(solo_cuentan_las_pociones_de_la_compania_no_las_de_un_enemigo) :-
    nueva_partida, herido(tuerca, 5),
    estado:aplicar_efectos([iniciar_combate([gran_roquefort])]),
    assertion(estado:lleva(e(gran_roquefort, 1), esporas, 1)),
    assertion(\+ economia:puede_usar(esporas, tuerca)).

test(se_puede_usar_en_cualquier_miembro_herido) :-
    con_pocion(1), herido(rufino, 3), herido(baldomero, 8),
    findall(M, economia:puede_usar(pocion, M), Ms), msort(Ms, S), assertion(S == [baldomero, rufino]).

test(la_cura_es_lo_que_cura_la_pocion) :-
    con_pocion(1), herido(baldomero, 25),
    economia:efectos_usar(pocion, baldomero, Efs),
    mundo:curacion(pocion, Total),
    assertion(memberchk(curar(baldomero, Total), Efs)),
    assertion(memberchk(gastar_objeto(compania, pocion, 1), Efs)).

test(la_cura_no_pasa_de_la_vida_maxima) :-
    con_pocion(1), herido(baldomero, 3),
    economia:efectos_usar(pocion, baldomero, Efs),
    assertion(memberchk(curar(baldomero, 3), Efs)),
    assertion(memberchk(mensaje(usa_objeto, [pocion, baldomero, 3]), Efs)).

test(los_efectos_son_datos_y_no_tocan_el_estado) :-
    con_pocion(2), herido(tuerca, 6), vida_de(tuerca, V0), pociones(P0),
    economia:efectos_usar(pocion, tuerca, _),
    vida_de(tuerca, V1), pociones(P1), assertion(V0 == V1), assertion(P0 == P1).

:- end_tests(la_regla).

:- begin_tests(fuera_de_combate).

test(usar_cura_y_gasta_la_pocion) :-
    con_pocion(2), herido(tuerca, 12), vida_de(tuerca, V0),
    orden(usar(pocion, tuerca), Items),
    assertion(\+ memberchk(error(_), Items)),
    vida_de(tuerca, V1), mundo:curacion(pocion, Cura), assertion(V1 =:= V0 + Cura),
    pociones(P), assertion(P == 1).

test(la_ultima_pocion_desaparece_del_inventario) :-
    con_pocion(1), herido(tuerca, 5), orden(usar(pocion, tuerca), _),
    assertion(\+ estado:lleva(compania, pocion, _)).

test(no_cuesta_ni_dia_ni_queso) :-
    con_pocion(1), herido(tuerca, 5), estado:dia(D0), economia:queso_total(Q0),
    orden(usar(pocion, tuerca), _),
    estado:dia(D1), economia:queso_total(Q1), assertion(D0 == D1), assertion(Q0 == Q1).

test(el_mensaje_dice_lo_que_se_curo) :-
    con_pocion(1), herido(tuerca, 4), orden(usar(pocion, tuerca), Items),
    assertion(memberchk(msg(usa_objeto, [pocion, tuerca, 4], _), Items)),
    with_output_to(atom(T), ui:mostrar(resultado(Items))),
    assertion(contiene(T, 'poción')), assertion(contiene(T, 'Tuerca')), assertion(contiene(T, '+4 de vida')).

test(se_puede_usar_tambien_de_viaje) :-
    con_pocion(1), herido(tuerca, 5), orden(ir(aldea), _),
    estado:aplicar_efectos([dano(tuerca, 3)]),
    orden(usar(pocion, tuerca), Items), assertion(\+ memberchk(error(_), Items)).

test(usar_guarda_la_prueba_para_explicar) :-
    con_pocion(1), herido(tuerca, 5), orden(usar(pocion, tuerca), _),
    orden(explicar, [vista(prueba, usar(pocion, tuerca), _)]).

:- end_tests(fuera_de_combate).

:- begin_tests(en_combate).

% un combate contra una rata, con Baldomero herido y una pocion; es el turno del primero de la cola
combate_con_pocion :-
    con_pocion(1), herido(pimentina, 8),
    juego:comenzar_combate([rata_quesera, rata_quesera], _).

test(usar_en_combate_cura_y_gasta_la_pocion) :-
    combate_con_pocion, vida_de(pimentina, V0),
    orden(usar(pocion, pimentina), Items),
    assertion(\+ memberchk(error(_), Items)),
    vida_de(pimentina, V1), assertion(V1 > V0),
    pociones(P), assertion(P == 0).

test(usar_en_combate_gasta_el_turno) :-
    combate_con_pocion, estado:cola_turnos([Actor0|_]),
    orden(usar(pocion, pimentina), Items),
    assertion(memberchk(msg(usa_objeto, [pocion, pimentina, _], _), Items)),
    (   estado:en_combate(_), estado:cola_turnos([Actor1|_]) -> assertion(Actor1 \== Actor0) ; true ).

test(en_combate_se_ve_el_estado_despues_de_usar) :-
    combate_con_pocion,
    orden(usar(pocion, pimentina), Items),
    (   estado:en_combate(_) -> assertion(memberchk(vista(combate, _), Items)) ; true ).

test(se_puede_curar_a_otro_miembro_distinto_del_que_actua) :-
    con_pocion(1), herido(rufino, 6),
    juego:comenzar_combate([rata_quesera], _),
    estado:cola_turnos([Actor|_]),
    orden(usar(pocion, rufino), Items),
    assertion(\+ memberchk(error(_), Items)),
    assertion(Actor \== none).

test(usar_esta_permitido_en_combate_y_no_al_final) :-
    assertion(juego:permitido(combate, usar)), assertion(juego:permitido(taberna, usar)),
    assertion(juego:permitido(exploracion, usar)), assertion(\+ juego:permitido(fin, usar)).

:- end_tests(en_combate).

:- begin_tests(errores_y_por_que_no).

test(solo_se_usan_los_objetos_que_curan) :-
    con_pocion(0), estado:aplicar_efectos([ganar_objeto(compania, venda_de_caballos, 1)]),
    orden(usar(venda_de_caballos, tuerca), Items),
    assertion(Items = [error(no_se_usa(venda_de_caballos))]).

test(un_objeto_que_no_existe) :-
    con_pocion(0), orden(usar(dragon, tuerca), Items),
    assertion(Items = [error(no_se_usa(dragon))]).

test(sin_pocion_no_se_puede_usar) :-
    con_pocion(0), herido(tuerca, 5), orden(usar(pocion, tuerca), Items),
    assertion(Items = [error(no_puede_usar(pocion, tuerca))]).

test(un_miembro_sano_da_error_y_no_gasta_la_pocion) :-
    con_pocion(1), orden(usar(pocion, tuerca), Items),
    assertion(Items = [error(no_puede_usar(pocion, tuerca))]), pociones(P), assertion(P == 1).

test(un_miembro_que_no_existe_da_error) :-
    con_pocion(1), orden(usar(pocion, napoleon), Items),
    assertion(Items = [error(no_puede_usar(pocion, napoleon))]).

test(los_errores_se_leen_bien) :-
    narrador:texto_error(no_se_usa(venda_de_caballos), T1), assertion(contiene(T1, 'venda de caballos')),
    narrador:texto_error(no_puede_usar(pocion, tuerca), T2),
    assertion(contiene(T2, 'por_que_no(usar(pocion, tuerca))')).

test(por_que_no_explica_por_que_no_se_puede) :-
    con_pocion(1), orden(por_que_no(usar(pocion, tuerca)), Items),
    assertion(Items = [vista(diag, usar(pocion, tuerca), _)]).

test(por_que_no_de_lo_que_si_se_puede_lo_dice) :-
    con_pocion(1), herido(tuerca, 5), orden(por_que_no(usar(pocion, tuerca)), Items),
    assertion(Items = [error(sin_fallo(usar(pocion, tuerca)))]).

test(los_comandos_de_usar_se_validan) :-
    juego:validar_comando(usar(pocion, tuerca), R1), assertion(R1 == ok(usar(pocion, tuerca))),
    juego:validar_comando(usar(_, _), R2), assertion(R2 = error(falta_argumento(_))),
    juego:validar_comando(usar(pocion), R3), assertion(R3 = error(no_entiendo(_))).

:- end_tests(errores_y_por_que_no).

:- begin_tests(consola_api_y_web).

test(la_ayuda_explica_usar) :-
    narrador:ayuda_de(usar, T), assertion(contiene(T, 'usar(Objeto, Miembro)')), assertion(contiene(T, 'turno')).

test(la_api_ofrece_el_boton_solo_si_hay_pocion_y_herido) :-
    con_pocion(1), api:estado_json(E0), campo(E0, acciones, A0),
    assertion(\+ ( member(A, A0), campo(A, familia, usar) )),
    herido(tuerca, 5), api:estado_json(E1), campo(E1, acciones, A1),
    assertion(( member(A2, A1), campo(A2, familia, usar), campo(A2, comando, 'usar(pocion, tuerca)') )).

test(el_boton_tiene_etiqueta_y_esta_habilitado) :-
    con_pocion(1), herido(tuerca, 5), api:estado_json(E), campo(E, acciones, As),
    member(A, As), campo(A, comando, 'usar(pocion, tuerca)'), !,
    campo(A, etiqueta, L), campo(A, habilitada, H),
    assertion(contiene(L, 'Usar poción en')), assertion(H == @(true)).

test(sin_pociones_no_hay_botones_de_usar) :-
    con_pocion(0), herido(tuerca, 5), api:estado_json(E), campo(E, acciones, As),
    assertion(\+ ( member(A, As), campo(A, familia, usar) )).

test(en_combate_tambien_se_ofrece) :-
    con_pocion(1), herido(tuerca, 5),
    juego:comenzar_combate([rata_quesera], _),
    api:estado_json(E), campo(E, acciones, As),
    assertion(( member(A, As), campo(A, familia, usar) )).

test(al_acabar_la_partida_no_se_ofrece) :-
    con_pocion(1), herido(tuerca, 5), estado:aplicar_efectos([fin(victoria(chapuza))]),
    api:estado_json(E), campo(E, acciones, As),
    assertion(\+ ( member(A, As), campo(A, familia, usar) )).

test(la_orden_por_la_api_cura) :-
    con_pocion(1), herido(tuerca, 5),
    api:ejecutar_orden('usar(pocion, tuerca)', R), campo(R, items, Is),
    assertion(( member(I, Is), campo(I, clave, usa_objeto) )),
    campo(R, estado, Est), campo(Est, banda, B),
    member(M, B), campo(M, id, tuerca), campo(M, vida, V), campo(M, vida_max, VM),
    assertion(V == VM).

test(la_web_sabe_ofrecer_usar_objeto) :-
    setup_call_cleanup(open('web/app.js', read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs0) ), close(S)),
    exclude(==(13), Cs0, Cs), atom_codes(J, Cs),
    assertion(contiene(J, 'usar: "Usar objeto"')),
    assertion(contiene(J, 'usar: ["Usar objeto…", "Elige a quién curar"]')),
    assertion(contiene(J, '"habilidad", "usar"]')),
    assertion(contiene(J, 'Hablar con|Usar')).

:- end_tests(consola_api_y_web).

:- begin_tests(de_donde_salen_las_pociones).

test(el_contrato_de_las_ratas_da_una_pocion_y_ahora_vale_algo) :-
    nueva_partida, contratos:recompensa_de(ratas_del_granero, R),
    assertion(memberchk(objeto(pocion), R)),
    estado:aplicar_efectos([ganar_objeto(compania, pocion, 1)]),
    herido(baldomero, 5), assertion(economia:puede_usar(pocion, baldomero)).

test(cantar_el_anuncio_a_ricota_da_una_pocion) :-
    nueva_partida, retractall(estado:en_zona(_)), assertz(estado:en_zona(aldea)),
    orden(hablar(ricota), _), orden(elegir(cantar_el_anuncio), Items),
    assertion(\+ memberchk(error(_), Items)),
    pociones(P), assertion(P == 1).

test(solo_tres_opciones_dan_pocion_una_cuesta_un_queso_y_otra_pide_saber_algo) :-
    findall(Op, ( charlas:opcion_charla(_, Op, _, _, Efs), memberchk(objeto(_), Efs) ), Ops),
    msort(Ops, S), assertion(S == [cantar_el_anuncio, darle_de_comer, hacerse_pasar_por_el_gremio]),
    once(charlas:opcion_charla(_, darle_de_comer, _, _, Efs2)), assertion(memberchk(perder_queso(1), Efs2)).

:- end_tests(de_donde_salen_las_pociones).
