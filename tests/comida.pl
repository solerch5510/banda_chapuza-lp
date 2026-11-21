% comida.pl (pruebas)
% La prevision de comida: cuanto come la Banda, para cuantos dias llega la despensa y el aviso cuando esta justa.
% Nace de una partida real que se perdio por hambre al moverse con la despensa justa y sin ningun aviso:
% (1) economia calcula la racion, los dias y el riesgo de un gasto; (2) la consola avisa al llegar y en la
% linea de la zona; (3) la API da la comida, un aviso por accion y el item de aviso; (4) la ayuda y la guia
% aconsejan juntar contratos.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/comida -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% con_queso(+N): una partida nueva con exactamente N quesos
con_queso(N) :-
    nueva_partida,
    economia:queso_total(T0),
    Gasto is T0 - N,
    (   Gasto > 0 -> economia:efectos_perdida(Gasto, Es), estado:aplicar_efectos(Es) ; true ).

leer_utf8(Ruta, Texto) :-
    setup_call_cleanup(open(Ruta, read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs) ),
                       close(S)),
    exclude(==(0'\r), Cs, Sin),
    atom_codes(Texto, Sin).

:- begin_tests(la_economia_de_la_comida).

test(la_racion_es_un_queso_por_miembro_activo) :-
    nueva_partida, economia:racion_diaria(R), assertion(R == 4),
    estado:aplicar_efectos([dano(tuerca, 100)]),
    economia:racion_diaria(R2), assertion(R2 == 3).

test(los_dias_de_comida_son_enteros) :-
    con_queso(12), economia:dias_de_comida(D1), assertion(D1 == 3),
    con_queso(7), economia:dias_de_comida(D2), assertion(D2 == 1),
    con_queso(3), economia:dias_de_comida(D3), assertion(D3 == 0).

test(el_riesgo_de_un_dia_segun_el_queso) :-
    forall(member(Q-Esperado, [12-ninguno, 8-ninguno, 7-escaso, 5-escaso, 4-a_cero, 1-a_cero]),
           (   con_queso(Q), economia:riesgo_de_gasto(0, R), assertion(R == Esperado) )).

test(descansar_gasta_mas_y_el_riesgo_lo_cuenta) :-
    con_queso(8),
    economia:riesgo_de_gasto(0, R0), assertion(R0 == ninguno),
    mundo:parametro(coste_descanso, C),
    economia:riesgo_de_gasto(C, R1), assertion(R1 == escaso).

test(si_hay_algo_por_cobrar_no_es_mortal) :-
    con_queso(4),
    estado:aplicar_efectos([contrato_aceptar(gato_en_el_arbol), contrato_resolver(gato_en_el_arbol, exito)]),
    economia:riesgo_de_gasto(0, R), assertion(R == sin_queso).

test(cada_riesgo_menos_ninguno_tiene_texto) :-
    forall(member(R, [hambre_mortal, a_cero, sin_queso, escaso]),
           ( narrador:texto_riesgo(R, T), assertion(atom(T)) )),
    assertion(\+ narrador:texto_riesgo(ninguno, _)).

:- end_tests(la_economia_de_la_comida).

:- begin_tests(el_aviso_en_la_consola).

test(la_linea_de_la_zona_dice_la_racion_y_los_dias) :-
    nueva_partida,
    main:transcribir([mirar, salir], T),
    assertion(contiene(T, 'Queso en la despensa: 12')),
    assertion(contiene(T, 'ración 4 al día (te alcanza para 3)')).

test(tras_viajar_con_la_despensa_a_cero_se_avisa_del_ayuno) :-
    con_queso(8),
    juego:ejecutar(ir(aldea), resultado(Items)),                 % queda 4: manana se acaba, pero todos comen
    assertion(memberchk(vista(comida, a_cero), Items)),
    with_output_to(atom(T0), ui:mostrar(resultado(Items))),
    assertion(contiene(T0, 'Ojo:')), assertion(contiene(T0, 'os quedáis sin queso')).

test(tras_viajar_con_el_ayuno_a_punto_de_acabar_se_avisa_del_peligro) :-
    con_queso(3),
    juego:ejecutar(ir(aldea), resultado(Items)),                 % alguien ya no ha comido: un dia de ayuno
    assertion(memberchk(vista(comida, hambre_mortal), Items)),
    with_output_to(atom(T), ui:mostrar(resultado(Items))),
    assertion(contiene(T, '¡Peligro!')), assertion(contiene(T, 'perderías por hambre')).

test(tras_viajar_con_la_despensa_justa_se_avisa_tambien_sin_ayuno_previo) :-
    con_queso(8),
    juego:ejecutar(ir(aldea), resultado(Items)),
    assertion(memberchk(vista(comida, a_cero), Items)).

test(tras_pagar_con_la_despensa_justa_tambien_se_avisa) :-
    con_queso(7),
    estado:aplicar_efectos([desmarcar(sueldos_pagados), contar(dias_de_ayuno, 1)]),
    juego:ejecutar(pagar, resultado(Items)),                      % quedan 2: manana pasan hambre y se acaba el ayuno
    assertion(\+ memberchk(error(_), Items)),
    assertion(memberchk(vista(comida, hambre_mortal), Items)).

test(con_margen_no_se_avisa) :-
    nueva_partida,
    juego:ejecutar(ir(aldea), resultado(Items)),
    assertion(\+ memberchk(vista(comida, _), Items)).

test(un_comando_que_falla_no_lleva_aviso) :-
    con_queso(1),
    juego:ejecutar(descansar, resultado(Items)),
    assertion(memberchk(error(_), Items)),
    assertion(\+ memberchk(vista(comida, _), Items)).

test(el_aviso_de_la_linea_de_la_zona_sale_si_va_justo) :-
    con_queso(3),
    estado:aplicar_efectos([contar(dias_de_ayuno, 1)]),
    juego:ejecutar(mirar, R),
    with_output_to(atom(T), ui:mostrar(R)),
    assertion(contiene(T, '¡Peligro!')),
    assertion(contiene(T, 'ración 4 al día (te alcanza para 0)')).

test(con_margen_la_linea_de_la_zona_no_avisa) :-
    nueva_partida,
    juego:ejecutar(mirar, R),
    with_output_to(atom(T), ui:mostrar(R)),
    assertion(\+ contiene(T, 'Peligro')), assertion(\+ contiene(T, 'Ojo:')).

:- end_tests(el_aviso_en_la_consola).

:- begin_tests(el_aviso_en_la_api).

test(el_estado_trae_la_comida) :-
    nueva_partida, api:estado_json(E), campo(E, comida, C),
    campo(C, queso, Q), campo(C, racion, R), campo(C, dias, D), campo(C, riesgo, Rg), campo(C, aviso, A),
    assertion(Q == 12), assertion(R == 4), assertion(D == 3), assertion(Rg == ninguno), assertion(A == @(null)).

test(con_poco_queso_el_estado_avisa) :-
    con_queso(6), api:estado_json(E), campo(E, comida, C),
    campo(C, riesgo, Rg), campo(C, aviso, A), campo(C, dias, D),
    assertion(Rg == escaso), assertion(contiene(A, 'menos de un día')), assertion(D == 1).

test(viajar_avisa_antes_de_hacerlo_cuando_deja_la_despensa_justa) :-
    con_queso(3), estado:aplicar_efectos([contar(dias_de_ayuno, 1)]),
    api:estado_json(E), campo(E, acciones, As),
    member(A, As), campo(A, comando, 'ir(aldea)'), !,
    campo(A, aviso, Aviso),
    assertion(contiene(Aviso, 'perderías por hambre')).

test(viajar_sin_riesgo_no_trae_aviso) :-
    nueva_partida, api:estado_json(E), campo(E, acciones, As),
    forall(( member(A, As), campo(A, familia, ir) ), ( campo(A, aviso, V), assertion(V == @(null)) )).

test(descansar_avisa_con_su_coste_incluido) :-
    con_queso(8), api:estado_json(E), campo(E, acciones, As),
    member(A, As), campo(A, comando, descansar), !,
    campo(A, aviso, Aviso), assertion(contiene(Aviso, 'menos de un día')).

test(el_item_de_aviso_tiene_su_json) :-
    con_queso(3),
    api:ejecutar_orden('ir(aldea)', R), campo(R, items, Is),
    member(I, Is), campo(I, tipo, aviso_comida), !,
    campo(I, riesgo, Rg), campo(I, texto, T),
    assertion(Rg == hambre_mortal), assertion(contiene(T, 'Peligro')).

:- end_tests(el_aviso_en_la_api).

:- begin_tests(el_consejo_de_ahorro).

test(la_ayuda_aconseja_juntar_contratos_en_la_taberna_y_de_viaje) :-
    juego:comandos_disponibles(taberna, Lt), narrador:consejo_de_ayuda(Lt, T),
    assertion(contiene(T, 'junta los contratos')),
    juego:comandos_disponibles(exploracion, Le), narrador:consejo_de_ayuda(Le, E),
    assertion(contiene(E, 'come toda la Banda')).

test(la_guia_explica_el_indicador_y_aconseja_juntar_contratos) :-
    leer_utf8('docs/guia-rapida.md', G),
    assertion(contiene(G, 'Junta los contratos')),
    assertion(contiene(G, '12 · 3 días')),
    atomic_list_concat(Ls, '\n', G), length(Ls, N), assertion(N =< 90).

test(la_cabecera_de_la_web_enseña_los_dias_y_el_riesgo) :-
    leer_utf8('web/app.js', J),
    assertion(contiene(J, 'indicadorComida')), assertion(contiene(J, '" <small>" + c.dias + (c.dias === 1')), assertion(contiene(J, 'aviso_comida')), assertion(contiene(J, 'a.aviso')).

:- end_tests(el_consejo_de_ahorro).
