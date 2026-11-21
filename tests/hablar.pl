% hablar.pl (pruebas)
% Hablar con los NPC (docs/12-npcs.md): el comando hablar, las escenas con opciones (elegir), el diario del Gran
% Rancio y quien esta en cada zona segun el dia. Incluye un VALIDADOR DE CONTENIDO: si se anade un personaje, una
% escena o una opcion y falta algo (el texto, la frase, el fragmento del diario), una prueba lo dice.
%   (1) los datos y el contenido; (2) quien esta y cuando; (3) el flujo hablar -> elegir; (4) los efectos de cada
%   opcion; (5) los errores; (6) el diario; (7) consola, API y web; (8) el balance (simulador).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/hablar -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/contratos').
:- use_module('../src/eventos').
:- use_module('../src/charlas', []).
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').
:- use_module('../herramientas/simulador').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% en(+Zona, +Dia): una partida nueva, en esa zona y ese dia
en(Zona, Dia) :-
    nueva_partida,
    Pasos is Dia - 1,
    forall(between(1, Pasos, _), estado:aplicar_efectos([avanzar_dia])),
    retractall(estado:en_zona(_)),
    assertz(estado:en_zona(Zona)).

% con_queso(+N): exactamente N quesos
con_queso(N) :-
    economia:queso_total(T0),
    Gasto is T0 - N,
    (   Gasto > 0 -> economia:efectos_perdida(Gasto, Es), estado:aplicar_efectos(Es) ; true ).

:- begin_tests(los_datos_y_el_contenido).

test(cada_personaje_presente_tiene_escena) :-
    forall(charlas:presente(Npc, _, _, _), assertion(charlas:escena_de(Npc, _))).

test(cada_escena_tiene_al_menos_tres_opciones_con_personajes_distintos) :-
    forall(charlas:escena_de(_, Escena),
           (   findall(Q, charlas:opcion_charla(Escena, _, Q, _, _), Qs),
               length(Qs, N), assertion(N >= 3),
               sort(Qs, Distintos), length(Distintos, ND), assertion(ND == N) )).

test(los_nombres_de_opcion_no_se_repiten_en_una_escena) :-
    forall(charlas:escena_de(_, Escena),
           (   findall(O, charlas:opcion_charla(Escena, O, _, _, _), Os),
               sort(Os, S), length(Os, N), length(S, M), assertion(N == M) )).

test(las_ventanas_de_dias_tienen_sentido) :-
    forall(charlas:presente(_, Zona, Desde, Hasta),
           (   assertion(mundo:zona(Zona, _)), assertion(integer(Desde)), assertion(Desde >= 1), assertion(Hasta >= Desde) )).

test(quien_hace_cada_opcion_es_de_la_compania) :-
    forall(charlas:opcion_charla(_, _, Quien, _, _), assertion(mundo:personaje(Quien, _, _, _, _, _, _))).

test(los_efectos_usan_solo_el_vocabulario_conocido) :-
    forall(( charlas:opcion_charla(_, _, _, _, Efs), member(E, Efs) ),
           assertion(( E = ganar_queso(_) ; E = perder_queso(_) ; E = objeto(_) ; E = moral(_, _) ; E = saber(_) ))).

test(cada_personaje_tiene_nombre_quien_es_y_frase_de_apertura) :-
    forall(charlas:personaje_de_charla(Npc),
           (   narrador:nombre_visible(Npc, N), assertion(N \== Npc),
               assertion(narrador:descripcion_personaje(Npc, _)),
               assertion(narrador:frase(suceso(charla_abre(Npc)), _, _)) )).

test(cada_opcion_tiene_texto_y_frase_de_resultado) :-
    forall(( charlas:escena_de(Npc, Escena), charlas:opcion_charla(Escena, Op, _, _, _) ),
           (   assertion(narrador:descripcion_opcion_charla(Npc, Op, _)),
               assertion(narrador:frase(suceso(charla_elige(Npc, Op)), _, _)) )).

test(cada_fragmento_del_diario_sale_de_una_opcion_y_tiene_texto) :-
    forall(charlas:saber(M),
           (   assertion(( charlas:opcion_charla(_, _, _, _, Efs), memberchk(saber(M), Efs) )),
               narrador:texto_saber(M, T), assertion(atom(T)) )).

test(toda_opcion_que_da_saber_da_uno_que_esta_en_el_diario) :-
    forall(( charlas:opcion_charla(_, _, _, _, Efs), member(saber(M), Efs) ),
           assertion(charlas:saber(M))).

test(el_texto_del_diario_empieza_en_mayuscula_y_sin_el_prefijo) :-
    forall(charlas:saber(M),
           (   narrador:texto_saber(M, T),
               assertion(\+ sub_atom(T, 0, _, _, 'Diario')),
               sub_atom(T, 0, 1, _, P), upcase_atom(P, P), assertion(true) )).

test(ninguna_opcion_da_mas_de_dos_quesos_netos) :-
    forall(( charlas:opcion_charla(_, _, _, _, Efs) ),
           (   findall(G, member(ganar_queso(G), Efs), Gs), sumlist(Gs, Ganado),
               findall(P, member(perder_queso(P), Efs), Ps), sumlist(Ps, Perdido),
               Neto is Ganado - Perdido, assertion(Neto =< 2) )).

test(el_total_de_queso_de_todas_las_charlas_no_pasa_de_ocho) :-
    % la regla de oro del balance (docs/12 §4): hablar no arregla la economia
    findall(Mejor,
            (   charlas:escena_de(_, Escena),
                findall(Neto, ( charlas:opcion_charla(Escena, _, _, _, Efs),
                                findall(G, member(ganar_queso(G), Efs), Gs), sumlist(Gs, Ganado),
                                findall(P, member(perder_queso(P), Efs), Ps), sumlist(Ps, Perdido),
                                Neto is Ganado - Perdido ), Netos),
                max_list(Netos, Mejor)
            ),
            Mejores),
    sumlist(Mejores, Total), assertion(Total =< 8).

:- end_tests(los_datos_y_el_contenido).

:- begin_tests(quien_esta_y_cuando).

test(en_la_taberna_los_primeros_dias_hay_dos) :-
    en(taberna, 1), charlas:presentes(Ps), assertion(Ps == [mantecosa, gruyere]).

test(pasado_el_dia_cinco_se_va_el_viajante) :-
    en(taberna, 5), charlas:presentes(P5), assertion(memberchk(gruyere, P5)),
    en(taberna, 6), charlas:presentes(P6), assertion(P6 == [mantecosa]).

test(en_la_aldea_se_va_el_tendero_el_dia_seis) :-
    en(aldea, 3), charlas:presentes(A), assertion(A == [alcaldesa_nata, ricota]),
    en(aldea, 6), charlas:presentes(B), assertion(B == [alcaldesa_nata]).

test(cada_zona_tiene_alguien_con_quien_hablar_cualquier_dia) :-
    forall(( mundo:zona(Z, _), Z \== taberna ; Z == taberna ),
           forall(member(Dia, [1, 3, 5, 6, 9, 12]),
                  (   en(Z, Dia), charlas:presentes(Ps), assertion(Ps \== []) ))).

test(en_otra_zona_no_se_puede_hablar_con_alguien_que_esta_en_la_taberna) :-
    en(aldea, 1), assertion(\+ charlas:puede_hablar(mantecosa)).

test(en_combate_no_se_puede_hablar) :-
    en(taberna, 1), estado:aplicar_efectos([iniciar_combate([rata_quesera])]),
    assertion(\+ charlas:puede_hablar(mantecosa)),
    assertion(\+ juego:permitido(combate, hablar)).

test(con_la_partida_acabada_no_se_habla) :-
    assertion(\+ juego:permitido(fin, hablar)),
    assertion(juego:permitido(fin, diario)).

:- end_tests(quien_esta_y_cuando).

:- begin_tests(el_flujo).

test(hablar_enseña_quien_hay_y_en_que_estado) :-
    en(taberna, 1), orden(hablar, [vista(presentes, Ps)]),
    assertion(Ps == [presente(mantecosa, nueva), presente(gruyere, nueva)]).

test(hablar_con_alguien_abre_su_escena) :-
    en(taberna, 1), orden(hablar(mantecosa), Items),
    assertion(memberchk(msg(charla_abre, [mantecosa], _), Items)),
    assertion(memberchk(vista(charla, mantecosa, Ops), Items)),
    assertion(length(Ops, 3)),
    assertion(estado:marca(charla_abierta(mantecosa))).

test(hablar_no_cuesta_ni_dia_ni_queso) :-
    en(taberna, 1), estado:dia(D0), economia:queso_total(Q0),
    orden(hablar(mantecosa), _), orden(hablar, _),
    estado:dia(D1), economia:queso_total(Q1),
    assertion(D0 == D1), assertion(Q0 == Q1).

test(volver_a_hablar_con_una_charla_a_medias_la_enseña_otra_vez_sin_repetir_al_personaje) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    orden(hablar(mantecosa), Items),
    assertion(\+ memberchk(msg(charla_abre, _, _), Items)),
    assertion(memberchk(vista(charla, mantecosa, _), Items)).

test(elegir_resuelve_la_charla_y_la_deja_hecha) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(1), Items),
    assertion(memberchk(msg(charla_elige, [mantecosa, jurar_honor], _), Items)),
    assertion(estado:marca(charla_hecha(mantecosa))),
    assertion(\+ estado:marca(charla_abierta(mantecosa))).

test(se_elige_por_numero_o_por_nombre) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    orden(elegir(jurar_honor), Items),
    assertion(memberchk(msg(charla_elige, [mantecosa, jurar_honor], _), Items)).

test(una_charla_hecha_solo_se_repite_con_una_frase_corta) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(1), _),
    orden(hablar(mantecosa), Items),
    assertion(Items = [msg(charla_repite, [mantecosa], _)]),
    orden(hablar, [vista(presentes, Ps)]),
    assertion(memberchk(presente(mantecosa, hecha), Ps)).

test(una_charla_hecha_no_se_puede_volver_a_elegir) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(1), _),
    orden(elegir(1), Items), assertion(Items = [error(no_hay_evento)]).

test(irse_sin_elegir_deja_la_charla_abierta_para_la_proxima) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    orden(ir(aldea), _), assertion(\+ charlas:charla_abierta(mantecosa)),
    orden(ir(taberna), _), assertion(charlas:charla_abierta(mantecosa)),
    orden(elegir(1), Items), assertion(memberchk(msg(charla_elige, _, _), Items)).

test(hablar_guarda_la_prueba_para_explicar) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    orden(explicar, [vista(prueba, hablar(mantecosa), _)]).

test(elegir_tambien_guarda_la_prueba_de_la_opcion) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(1), _),
    orden(explicar, [vista(prueba, elegir(jurar_honor), _)]).

test(un_evento_de_contrato_abierto_manda_sobre_la_charla) :-
    nueva_partida, orden(aceptar(gato_en_el_arbol), _), orden(ir(aldea), _),
    assertion(eventos:evento_abierto(rescate_gato)),
    orden(hablar(alcaldesa_nata), _),
    orden(elegir(trepar), Items),
    assertion(memberchk(msg(evento_elige, [rescate_gato, trepar], _), Items)).

:- end_tests(el_flujo).

:- begin_tests(los_efectos_de_cada_opcion).

test(jurar_honor_sube_la_moral_de_todos) :-
    en(taberna, 1), estado:moral(rufino, M0),
    orden(hablar(mantecosa), _), orden(elegir(jurar_honor), _),
    estado:moral(rufino, M1), assertion(M1 =:= M0 + 1),
    estado:moral(tuerca, T1), assertion(T1 =:= M0 + 1).

test(invitar_al_caldo_cuesta_un_queso_y_da_un_fragmento) :-
    en(taberna, 1), economia:queso_total(Q0),
    orden(hablar(mantecosa), _), orden(elegir(invitar_al_caldo), Items),
    economia:queso_total(Q1), assertion(Q1 =:= Q0 - 1),
    assertion(charlas:sabe(moho_en_la_despensa)),
    assertion(memberchk(msg(saber_nuevo, [moho_en_la_despensa], _), Items)).

test(mirar_los_desagues_da_un_queso_y_le_cuesta_la_moral_a_rufino) :-
    en(taberna, 1), economia:queso_total(Q0), estado:moral(rufino, M0),
    orden(hablar(mantecosa), _), orden(elegir(mirar_los_desagues), _),
    economia:queso_total(Q1), estado:moral(rufino, M1),
    assertion(Q1 =:= Q0 + 1), assertion(M1 =:= M0 - 1).

test(curar_las_vacas_cuesta_uno_y_da_dos) :-
    en(aldea, 1), economia:queso_total(Q0),
    orden(hablar(alcaldesa_nata), _), orden(elegir(curar_las_vacas), _),
    economia:queso_total(Q1), assertion(Q1 =:= Q0 + 1).

test(registrar_al_rey_da_dos_quesos_y_baja_la_moral_de_baldomero) :-
    en(castillo, 1), economia:queso_total(Q0), estado:moral(baldomero, M0),
    orden(hablar(rey_brieto), _), orden(elegir(registrar_los_bolsillos_reales), _),
    economia:queso_total(Q1), estado:moral(baldomero, M1),
    assertion(Q1 =:= Q0 + 2), assertion(M1 =:= M0 - 1).

test(las_opciones_que_solo_dan_informacion_no_tocan_el_queso) :-
    forall(member(Zona-Npc-Op, [bosque-penicilio-hablar_con_el_moho, camino_real-ganso_recaudador-discutir_el_peaje,
                                castillo-rey_brieto-preguntar_por_la_despensa, cuevas-el_eco-susurrar_una_pregunta]),
           (   en(Zona, 1), economia:queso_total(Q0),
               orden(hablar(Npc), _), orden(elegir(Op), _),
               economia:queso_total(Q1), assertion(Q0 == Q1) )).

test(cada_opcion_se_puede_elegir_y_deja_la_charla_hecha) :-
    forall(( charlas:presente(Npc, Zona, _, _), charlas:escena_de(Npc, Escena),
             charlas:opcion_charla(Escena, Op, _, _, _) ),
           (   en(Zona, 1), con_queso(6),
               orden(hablar(Npc), _), orden(elegir(Op), Items),
               assertion(\+ memberchk(error(_), Items)),
               assertion(estado:marca(charla_hecha(Npc))) )).

:- end_tests(los_efectos_de_cada_opcion).

:- begin_tests(los_errores).

test(no_conozco_a_ese_personaje) :-
    en(taberna, 1), orden(hablar(napoleon), Items),
    assertion(Items = [error(personaje_desconocido(napoleon))]).

test(el_personaje_esta_en_otra_zona) :-
    en(taberna, 1), orden(hablar(rey_brieto), Items),
    assertion(Items = [error(no_esta_aqui(rey_brieto))]).

test(el_personaje_ya_se_fue) :-
    en(taberna, 6), orden(hablar(gruyere), Items),
    assertion(Items = [error(no_esta_aqui(gruyere))]).

test(la_frase_de_repeticion_nombra_al_personaje_y_sale_en_pantalla) :-
    narrador:texto(charla_repite, [mantecosa], 0, T), assertion(contiene(T, 'Ya habéis hablado con Doña Mantecosa')),
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(1), _),
    orden(hablar(mantecosa), Is), with_output_to(atom(P), ui:mostrar(resultado(Is))),
    assertion(contiene(P, 'Ya habéis hablado con Doña Mantecosa')).

test(los_errores_tienen_texto_que_nombra_al_personaje) :-
    narrador:texto_error(no_esta_aqui(gruyere), T), assertion(contiene(T, 'Gruyère')),
    narrador:texto_error(personaje_desconocido(napoleon), T2), assertion(contiene(T2, 'napoleon')).

test(una_opcion_de_quien_ha_caido_no_esta_disponible) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    estado:aplicar_efectos([dano(pimentina, 999)]),
    orden(elegir(invitar_al_caldo), Items),
    assertion(Items = [error(opcion_no_disponible(invitar_al_caldo))]),
    assertion(estado:marca(charla_abierta(mantecosa))).

test(una_opcion_de_quien_esta_en_huelga_no_esta_disponible) :-
    % vivo pero en huelga (la moral por los suelos): no actua
    en(aldea, 1), orden(hablar(alcaldesa_nata), _),
    estado:aplicar_efectos([mod_moral(tuerca, -9)]),
    assertion(compania:activo(tuerca)), assertion(\+ compania:en_pie(tuerca)),
    orden(elegir(ojear_el_registro), Items),
    assertion(Items = [error(opcion_no_disponible(ojear_el_registro))]).

test(una_opcion_que_cuesta_queso_no_esta_si_no_hay) :-
    en(taberna, 1), con_queso(0), orden(hablar(mantecosa), _),
    orden(elegir(invitar_al_caldo), Items),
    assertion(Items = [error(opcion_no_disponible(invitar_al_caldo))]).

test(una_opcion_que_no_existe_da_error) :-
    en(taberna, 1), orden(hablar(mantecosa), _),
    orden(elegir(dragon), Items), assertion(Items = [error(opcion_desconocida(dragon))]),
    orden(elegir(9), Items2), assertion(Items2 = [error(opcion_desconocida(9))]).

test(sin_nada_abierto_elegir_da_el_error_de_siempre) :-
    en(taberna, 1), orden(elegir(1), Items), assertion(Items = [error(no_hay_evento)]).

test(por_que_no_explica_que_el_personaje_no_esta) :-
    en(taberna, 6), orden(por_que_no(hablar(gruyere)), Items),
    assertion(Items = [vista(diag, hablar(gruyere), _)]).

test(por_que_no_de_una_opcion_que_no_se_puede) :-
    en(taberna, 1), con_queso(0), orden(hablar(mantecosa), _),
    orden(por_que_no(elegir(2)), Items),
    assertion(Items = [vista(diag, elegir(2), _)]).

:- end_tests(los_errores).

:- begin_tests(el_diario).

test(al_empezar_esta_en_blanco) :-
    nueva_partida, orden(diario, [vista(diario, Ms)]), assertion(Ms == []).

test(un_fragmento_se_apunta_al_averiguarlo) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(invitar_al_caldo), _),
    orden(diario, [vista(diario, Ms)]), assertion(Ms == [moho_en_la_despensa]).

test(las_opciones_que_no_dan_fragmento_no_apuntan_nada) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(jurar_honor), _),
    orden(diario, [vista(diario, Ms)]), assertion(Ms == []).

test(el_diario_sale_en_el_orden_del_reparto_no_en_el_de_averiguarlos) :-
    nueva_partida,
    estado:aplicar_efectos([marcar(sabe(el_eco_habla_solo)), marcar(sabe(moho_en_la_despensa))]),
    orden(diario, [vista(diario, Ms)]),
    assertion(Ms == [moho_en_la_despensa, el_eco_habla_solo]).

test(un_fragmento_ya_sabido_no_se_vuelve_a_anunciar) :-
    nueva_partida, estado:aplicar_efectos([marcar(sabe(moho_con_hambre))]),
    charlas:efectos_eleccion(penicilio, cantarle_al_moho, Efs),
    assertion(\+ memberchk(mensaje(saber_nuevo, _), Efs)).

test(un_fragmento_nuevo_si_se_anuncia) :-
    nueva_partida,
    charlas:efectos_eleccion(penicilio, cantarle_al_moho, Efs),
    assertion(memberchk(mensaje(saber_nuevo, [moho_con_hambre]), Efs)).

test(el_diario_se_puede_leer_al_acabar_la_partida) :-
    nueva_partida, estado:aplicar_efectos([fin(victoria(chapuza))]),
    orden(diario, Items), assertion(Items = [vista(diario, _)]).

test(una_partida_nueva_olvida_el_diario_y_las_charlas) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(invitar_al_caldo), _),
    nueva_partida,
    assertion(\+ charlas:sabe(moho_en_la_despensa)), assertion(\+ charlas:charla_hecha(mantecosa)).

:- end_tests(el_diario).

:- begin_tests(consola_api_y_web).

test(la_consola_lista_a_los_presentes_y_dice_quien_son) :-
    en(taberna, 1), orden(hablar, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'Doña Mantecosa')), assertion(contiene(T, 'Gruyère')),
    assertion(contiene(T, 'cobra todo')).

test(la_consola_enseña_la_charla_con_sus_opciones) :-
    en(taberna, 1), orden(hablar(mantecosa), Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'Doña Mantecosa seca una jarra')),
    assertion(contiene(T, '1. Sir Baldomero jura por su honor')),
    assertion(contiene(T, 'invita a una ronda de caldo')),
    assertion(contiene(T, 'Elige con elegir')).

test(la_consola_marca_las_opciones_no_disponibles) :-
    en(taberna, 1), con_queso(0), orden(hablar(mantecosa), Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, '[no disponible]')).

test(la_consola_anuncia_el_fragmento_y_el_diario_lo_lista) :-
    en(taberna, 1), orden(hablar(mantecosa), _), orden(elegir(invitar_al_caldo), Is),
    with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'Diario: el moho empezó hace tres inviernos')),
    orden(diario, Ds), with_output_to(atom(T2), ui:mostrar(resultado(Ds))),
    assertion(contiene(T2, '- El moho empezó hace tres inviernos')).

test(el_diario_en_blanco_lo_dice) :-
    nueva_partida, orden(diario, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'en blanco')).

test(la_ayuda_incluye_hablar_y_el_diario) :-
    juego:comandos_disponibles(taberna, Cs),
    assertion(memberchk(hablar, Cs)), assertion(memberchk(diario, Cs)),
    narrador:ayuda_de(hablar, A), assertion(contiene(A, 'hablar(Nombre)')),
    narrador:ayuda_de(diario, D), assertion(contiene(D, 'Gran Rancio')).

test(los_comandos_nuevos_se_validan) :-
    juego:validar_comando(hablar, R1), assertion(R1 == ok(hablar)),
    juego:validar_comando(hablar(mantecosa), R2), assertion(R2 == ok(hablar(mantecosa))),
    juego:validar_comando(diario, R3), assertion(R3 == ok(diario)),
    juego:validar_comando(hablar(_), R4), assertion(R4 = error(falta_argumento(_))).

test(la_api_ofrece_un_boton_por_personaje_presente) :-
    en(taberna, 1), api:estado_json(E), campo(E, acciones, As),
    findall(C, ( member(A, As), campo(A, familia, hablar), campo(A, comando, C) ), Cs),
    assertion(Cs == ['hablar(mantecosa)', 'hablar(gruyere)']),
    assertion(( member(A2, As), campo(A2, comando, diario) )).

test(los_botones_de_hablar_estan_habilitados_y_se_nombran) :-
    en(taberna, 1), api:estado_json(E), campo(E, acciones, As),
    member(A, As), campo(A, comando, 'hablar(mantecosa)'), !,
    campo(A, habilitada, H), campo(A, etiqueta, L),
    assertion(H == @(true)), assertion(contiene(L, 'Hablar con Doña Mantecosa')).

test(la_api_trae_los_items_de_hablar) :-
    en(taberna, 1),
    api:ejecutar_orden(hablar, R1), campo(R1, items, I1), member(P, I1), campo(P, tipo, presentes), !,
    campo(P, personajes, Ps), assertion(length(Ps, 2)),
    api:ejecutar_orden('hablar(mantecosa)', R2), campo(R2, items, I2),
    member(Ch, I2), campo(Ch, tipo, charla), !,
    campo(Ch, nombre, N), campo(Ch, opciones, Os),
    assertion(contiene(N, 'Mantecosa')), assertion(length(Os, 3)),
    api:ejecutar_orden('elegir(2)', R3), campo(R3, items, I3),
    assertion(( member(M, I3), campo(M, clave, saber_nuevo) )),
    api:ejecutar_orden(diario, R4), campo(R4, items, I4),
    member(D, I4), campo(D, tipo, diario), !,
    campo(D, saberes, Ss), assertion(length(Ss, 1)).

test(la_web_sabe_pintar_a_la_gente_las_charlas_y_el_diario) :-
    setup_call_cleanup(open('web/app.js', read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs0) ), close(S)),
    exclude(==(13), Cs0, Cs), atom_codes(J, Cs),
    assertion(contiene(J, 'function presentesHTML')), assertion(contiene(J, 'function charlaHTML')),
    assertion(contiene(J, 'function diarioHTML')), assertion(contiene(J, 'case "charla"')),
    assertion(contiene(J, 'case "presentes": return presentesHTML(e);')),
    assertion(contiene(J, 'case "charla": return charlaHTML(e);')),
    assertion(contiene(J, 'case "diario": return diarioHTML(e);')),
    assertion(contiene(J, 'hablar: "Hablar"')), assertion(contiene(J, 'diario: "Diario"')).

:- end_tests(consola_api_y_web).

:- begin_tests(lo_que_mide_el_simulador).

test(el_jugador_que_habla_con_todos_no_gana_menos_que_el_que_no_habla) :-
    findall(x, ( between(1, 30, I), S is 7000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), A),
    findall(x, ( between(1, 30, I), S is 7000 + I, episodio(plan_hablador(10, 2), S, 400, r(victoria, _, _, _)) ), B),
    length(A, NA), length(B, NB), assertion(NB >= NA - 2).

test(hablar_da_queso_pero_con_un_techo) :-
    % sin errores: el hablador acaba con mas queso que el que no habla, pero no se hace rico
    findall(Q, ( between(1, 10, I), S is 7100 + I, episodio(plan(0, 2), S, 400, r(victoria, _, Q, _)) ), Qa),
    findall(Q, ( between(1, 10, I), S is 7100 + I, episodio(plan_hablador(0, 2), S, 400, r(victoria, _, Q, _)) ), Qb),
    sumlist(Qa, Ta), sumlist(Qb, Tb),
    Extra is (Tb - Ta) / 10,
    assertion(Extra > 0), assertion(Extra =< 9).

test(el_hablador_realmente_habla_con_alguien) :-
    episodio(plan_hablador(0, 2), 7101, 400, r(victoria, _, _, _)),
    findall(Npc, estado:marca(charla_hecha(Npc)), Hechas),
    length(Hechas, N), assertion(N >= 4).

:- end_tests(lo_que_mide_el_simulador).
