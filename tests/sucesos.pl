% sucesos.pl (pruebas)
% Los sucesos de zona (docs/13-ampliacion.md §4): escenas unicas de un LUGAR. Se abren solas la primera vez que se
% llega (si no hay combate ni evento de contrato en marcha) o con `explorar`, y se resuelven con elegir/1 igual que
% una charla (es el mismo motor: charlas.pl). Algunas opciones, o el suceso entero, solo existen si ya se sabe algo
% del diario, asi que hablar con la gente cambia lo que se puede hacer en los lugares.
%   (1) los datos y el validador; (2) cuando hay suceso; (3) abrirse solo y explorar; (4) los efectos y lo que exige
%   saber; (5) errores; (6) consola, API y web; (7) balance.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/sucesos -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
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
% Los jugadores simulados pelean como una persona atenta: atacan sin despistes y descansan si vuelven heridos (herramientas/simulador.pl).
:- fijar_estilo(solo_atacar).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% ponerse_en(+Zona): una partida nueva colocada en esa zona (sin llegar, para no abrir nada)
ponerse_en(Zona) :-
    nueva_partida, retractall(estado:en_zona(_)), assertz(estado:en_zona(Zona)).

sabe(M) :- estado:aplicar_efectos([marcar(sabe(M))]).

terminar_combate_y_mirar(T) :-
    terminar_combate, orden(mirar, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))).

% terminar_combate: gana el combate a base de ataques (para pasar al despues)
terminar_combate :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(turno(Cmd)), orden(Cmd, _), terminar_combate
    ;   true
    ).
turno(Cmd) :-
    estado:cola_turnos([A|_]), mundo:habilidad_de(A, H),
    (   combate:objetivo_de_habilidad(H, ninguno) -> Cmd = habilidad
    ;   estado:instancia(E, rata_quesera), compania:vivo(E), combate:puede_habilidad(A, H, E) -> Cmd = habilidad(rata_quesera)
    ;   estado:instancia(E, rata_quesera), compania:vivo(E), combate:puede_atacar(A, E) -> Cmd = atacar(rata_quesera)
    ;   Cmd = defender
    ).

:- begin_tests(los_datos_y_el_validador).

test(cada_suceso_tiene_zona_escena_y_apertura) :-
    forall(charlas:suceso(Id, Zona, _),
           (   assertion(mundo:zona(Zona, _)), assertion(charlas:escena_de(Id, _)),
               assertion(narrador:frase(suceso(charla_abre(Id)), _, _)),
               narrador:nombre_visible(Id, N), assertion(N \== Id) )).

test(un_suceso_no_es_un_personaje_y_no_se_habla_con_el) :-
    forall(charlas:suceso(Id, _, _),
           (   assertion(\+ charlas:presente(Id, _, _, _)), assertion(\+ charlas:personaje_de_charla(Id)) )).

test(cada_suceso_tiene_tres_opciones_de_miembros_distintos) :-
    forall(charlas:suceso(Id, _, _),
           (   charlas:escena_de(Id, Escena),
               findall(Q, charlas:opcion_charla(Escena, _, Q, _, _), Qs),
               length(Qs, N), assertion(N == 3), sort(Qs, S), length(S, M), assertion(M == 3) )).

test(cada_opcion_de_suceso_tiene_texto_y_frase_de_resultado) :-
    forall(( charlas:suceso(Id, _, _), charlas:escena_de(Id, Escena), charlas:opcion_charla(Escena, Op, _, _, _) ),
           (   assertion(narrador:descripcion_opcion_charla(Id, Op, _)),
               assertion(narrador:frase(suceso(charla_elige(Id, Op)), _, _)) )).

test(lo_que_exigen_los_sucesos_existe_en_el_diario) :-
    forall(( charlas:suceso(_, _, Cs), member(sabe(M), Cs) ), assertion(charlas:saber(M))),
    forall(( charlas:suceso(Id, _, _), charlas:escena_de(Id, E), charlas:opcion_charla(E, _, _, Cs2, _), member(sabe(M2), Cs2) ),
           assertion(charlas:saber(M2))).

test(los_fragmentos_que_dan_los_sucesos_estan_en_el_diario_y_tienen_texto) :-
    forall(( charlas:suceso(Id, _, _), charlas:escena_de(Id, E), charlas:opcion_charla(E, _, _, _, Efs), member(saber(M), Efs) ),
           (   assertion(charlas:saber(M)), narrador:texto_saber(M, T), assertion(atom(T)) )).

test(hay_cinco_sucesos_uno_en_cada_zona_menos_la_taberna) :-
    findall(Z, charlas:suceso(_, Z, _), Zs), msort(Zs, S),
    assertion(S == [aldea, bosque, camino_real, castillo, cuevas]).

test(el_queso_de_todos_los_sucesos_no_pasa_de_cuatro) :-
    findall(Mejor,
            (   charlas:suceso(Id, _, _), charlas:escena_de(Id, Escena),
                findall(Neto, ( charlas:opcion_charla(Escena, _, _, _, Efs),
                                findall(G, member(ganar_queso(G), Efs), Gs), sumlist(Gs, Ganado),
                                findall(P, member(perder_queso(P), Efs), Ps), sumlist(Ps, Perdido),
                                Neto is Ganado - Perdido ), Netos),
                max_list(Netos, Mejor) ),
            Mejores),
    sumlist(Mejores, Total), assertion(Total =< 4).

test(ninguna_opcion_de_suceso_da_mas_de_un_queso_neto) :-
    forall(( charlas:suceso(Id, _, _), charlas:escena_de(Id, E), charlas:opcion_charla(E, _, _, _, Efs) ),
           (   findall(G, member(ganar_queso(G), Efs), Gs), sumlist(Gs, Ganado),
               findall(P, member(perder_queso(P), Efs), Ps), sumlist(Ps, Perdido),
               Neto is Ganado - Perdido, assertion(Neto =< 1) )).

test(los_efectos_nuevos_curar_de_grupo_y_sabe_como_condicion_se_entienden) :-
    nueva_partida, estado:aplicar_efectos([dano(tuerca, 6), dano(rufino, 4)]),
    once(charlas:efectos_eleccion(el_pozo_de_los_deseos, sacar_agua_para_todos, Efs)),
    assertion(memberchk(curar(tuerca, 5), Efs)), assertion(memberchk(curar(rufino, 5), Efs)),
    assertion(memberchk(curar(baldomero, 5), Efs)), assertion(memberchk(curar(pimentina, 5), Efs)).

:- end_tests(los_datos_y_el_validador).

:- begin_tests(cuando_hay_suceso).

test(en_su_zona_hay_suceso_y_en_otra_no) :-
    ponerse_en(bosque), assertion(charlas:suceso_aqui(el_puente_de_setas)),
    assertion(\+ charlas:suceso_aqui(el_pozo_de_los_deseos)).

test(la_taberna_no_tiene_suceso) :-
    ponerse_en(taberna), assertion(\+ charlas:suceso_pendiente(_)).

test(el_altar_solo_aparece_si_se_sabe_que_el_moho_tiene_hambre) :-
    ponerse_en(cuevas), assertion(\+ charlas:suceso_aqui(el_altar_del_moho)),
    sabe(moho_con_hambre), assertion(charlas:suceso_aqui(el_altar_del_moho)).

test(un_suceso_resuelto_ya_no_esta_pendiente_pero_sigue_siendo_de_la_zona) :-
    ponerse_en(aldea), orden(explorar, _), orden(elegir(2), _),
    assertion(charlas:suceso_aqui(el_pozo_de_los_deseos)),
    assertion(\+ charlas:suceso_pendiente(el_pozo_de_los_deseos)).

:- end_tests(cuando_hay_suceso).

:- begin_tests(abrirse_solo_y_explorar).

test(al_llegar_a_la_zona_se_abre_solo) :-
    nueva_partida, orden(ir(aldea), Items),
    assertion(memberchk(msg(charla_abre, [el_pozo_de_los_deseos], _), Items)),
    assertion(memberchk(vista(charla, el_pozo_de_los_deseos, Ops), Items)),
    assertion(length(Ops, 3)),
    assertion(estado:marca(charla_abierta(el_pozo_de_los_deseos))).

test(abrirse_no_cuesta_nada_mas_que_el_dia_del_viaje) :-
    nueva_partida, orden(ir(aldea), _),
    estado:dia(D), assertion(D == 2), economia:queso_total(Q), assertion(Q == 8).

test(si_se_resuelve_no_vuelve_a_abrirse_al_regresar) :-
    nueva_partida, orden(ir(aldea), _), orden(elegir(2), _),
    orden(ir(taberna), _), orden(ir(aldea), Items),
    assertion(\+ memberchk(msg(charla_abre, _, _), Items)),
    assertion(\+ memberchk(vista(charla, _, _), Items)).

test(si_se_deja_a_medias_se_vuelve_a_ensenar_sin_repetir_la_apertura) :-
    nueva_partida, orden(ir(aldea), _),
    orden(ir(taberna), _), orden(ir(aldea), Items),
    assertion(\+ memberchk(msg(charla_abre, _, _), Items)),
    assertion(memberchk(vista(charla, el_pozo_de_los_deseos, _), Items)).

test(con_un_combate_de_contrato_al_llegar_el_suceso_espera) :-
    nueva_partida, orden(aceptar(ratas_del_granero), _), orden(ir(aldea), Items),
    assertion(estado:en_combate(_)),
    assertion(\+ memberchk(msg(charla_abre, _, _), Items)),
    assertion(\+ estado:marca(charla_abierta(el_pozo_de_los_deseos))).

test(tras_el_combate_explorar_lo_abre) :-
    nueva_partida, orden(aceptar(ratas_del_granero), _), orden(ir(aldea), _),
    terminar_combate,
    orden(explorar, Items),
    assertion(memberchk(msg(charla_abre, [el_pozo_de_los_deseos], _), Items)).

test(con_un_evento_de_contrato_abierto_el_suceso_espera_y_explorar_lo_dice) :-
    nueva_partida, orden(aceptar(gato_en_el_arbol), _), orden(ir(aldea), Items),
    assertion(eventos:evento_abierto(rescate_gato)),
    assertion(\+ memberchk(msg(charla_abre, [el_pozo_de_los_deseos], _), Items)),
    orden(explorar, I2), assertion(I2 = [error(termina_el_evento)]).

test(explorar_abre_el_suceso_pendiente) :-
    ponerse_en(bosque), orden(explorar, Items),
    assertion(memberchk(msg(charla_abre, [el_puente_de_setas], _), Items)),
    assertion(memberchk(vista(charla, el_puente_de_setas, _), Items)).

test(explorar_con_el_suceso_a_medias_lo_ensena_otra_vez) :-
    ponerse_en(bosque), orden(explorar, _), orden(explorar, Items),
    assertion(\+ memberchk(msg(charla_abre, _, _), Items)),
    assertion(memberchk(vista(charla, el_puente_de_setas, _), Items)).

test(explorar_sin_nada_que_explorar_da_el_error) :-
    ponerse_en(taberna), orden(explorar, Items), assertion(Items = [error(nada_que_explorar)]).

test(explorar_tras_resolverlo_ya_no_hay_nada) :-
    ponerse_en(bosque), orden(explorar, _), orden(elegir(1), _),
    orden(explorar, Items), assertion(Items = [error(nada_que_explorar)]).

test(explorar_no_cuesta_ni_dia_ni_queso) :-
    ponerse_en(bosque), estado:dia(D0), economia:queso_total(Q0),
    orden(explorar, _), estado:dia(D1), economia:queso_total(Q1),
    assertion(D0 == D1), assertion(Q0 == Q1).

test(explorar_esta_permitido_de_viaje_y_en_la_taberna_pero_no_en_combate_ni_al_final) :-
    assertion(juego:permitido(exploracion, explorar)), assertion(juego:permitido(taberna, explorar)),
    assertion(\+ juego:permitido(combate, explorar)), assertion(\+ juego:permitido(fin, explorar)).

:- end_tests(abrirse_solo_y_explorar).

:- begin_tests(los_efectos_y_lo_que_exige_saber).

test(el_pozo_cura_a_toda_la_banda_una_sola_vez) :-
    ponerse_en(aldea), estado:aplicar_efectos([dano(tuerca, 8), dano(baldomero, 12)]),
    estado:vida(tuerca, T0), estado:vida(baldomero, B0),
    orden(explorar, _), orden(elegir(sacar_agua_para_todos), Items),
    assertion(\+ memberchk(error(_), Items)),
    estado:vida(tuerca, T1), estado:vida(baldomero, B1),
    assertion(T1 =:= T0 + 5), assertion(B1 =:= B0 + 5),
    orden(explorar, I2), assertion(I2 = [error(nada_que_explorar)]).

test(el_agua_no_cura_a_un_caido) :-
    ponerse_en(aldea), estado:aplicar_efectos([dano(tuerca, 999)]),
    orden(explorar, _), orden(elegir(sacar_agua_para_todos), _),
    estado:vida(tuerca, V), assertion(V == 0).

test(cruzar_de_puntillas_da_un_queso) :-
    ponerse_en(bosque), economia:queso_total(Q0),
    orden(explorar, _), orden(elegir(cruzar_de_puntillas), _),
    economia:queso_total(Q1), assertion(Q1 =:= Q0 + 1).

test(endurecer_el_puente_cuesta_un_queso_y_anima_a_todos) :-
    ponerse_en(bosque), economia:queso_total(Q0), estado:moral(rufino, M0),
    orden(explorar, _), orden(elegir(endurecer_el_puente), _),
    economia:queso_total(Q1), estado:moral(rufino, M1),
    assertion(Q1 =:= Q0 - 1), assertion(M1 =:= M0 + 1).

test(cruzar_con_la_armadura_baja_la_moral_de_baldomero) :-
    ponerse_en(bosque), estado:moral(baldomero, M0),
    orden(explorar, _), orden(elegir(cruzar_con_la_armadura), _),
    estado:moral(baldomero, M1), assertion(M1 =:= M0 - 1).

test(hacerse_pasar_por_el_gremio_exige_saber_lo_del_sello) :-
    ponerse_en(camino_real), orden(explorar, _),
    orden(elegir(hacerse_pasar_por_el_gremio), Items),
    assertion(Items = [error(opcion_no_disponible(hacerse_pasar_por_el_gremio))]),
    assertion(estado:marca(charla_abierta(la_carreta_del_gremio))).

test(sabiendolo_da_una_pocion) :-
    ponerse_en(camino_real), sabe(gremio_sin_peaje), orden(explorar, _),
    orden(elegir(hacerse_pasar_por_el_gremio), Items),
    assertion(\+ memberchk(error(_), Items)),
    assertion(estado:lleva(compania, pocion, 1)).

test(bajar_a_la_bodega_exige_saber_lo_del_moho_del_rey_y_apunta_el_diario) :-
    ponerse_en(castillo), orden(explorar, _),
    orden(elegir(bajar_a_la_bodega), I0), assertion(I0 = [error(opcion_no_disponible(bajar_a_la_bodega))]),
    sabe(moho_en_la_despensa),
    orden(elegir(bajar_a_la_bodega), I1),
    assertion(memberchk(msg(saber_nuevo, [moho_en_la_bodega], _), I1)),
    assertion(charlas:sabe(moho_en_la_bodega)).

test(el_altar_alimentado_apunta_un_fragmento_y_cuesta_un_queso) :-
    ponerse_en(cuevas), sabe(moho_con_hambre), economia:queso_total(Q0),
    orden(explorar, _), orden(elegir(dejarle_un_queso_al_moho), _),
    economia:queso_total(Q1), assertion(Q1 =:= Q0 - 1), assertion(charlas:sabe(altar_alimentado)).

test(cada_opcion_de_cada_suceso_se_puede_elegir) :-
    forall(( charlas:suceso(Id, Zona, _), charlas:escena_de(Id, Escena), charlas:opcion_charla(Escena, Op, _, _, _) ),
           (   ponerse_en(Zona),
               forall(member(M, [moho_con_hambre, gremio_sin_peaje, moho_en_la_despensa]), sabe(M)),
               orden(explorar, _), orden(elegir(Op), Items),
               assertion(\+ memberchk(error(_), Items)),
               assertion(estado:marca(charla_hecha(Id))) )).

:- end_tests(los_efectos_y_lo_que_exige_saber).

:- begin_tests(errores).

test(no_se_habla_con_un_lugar) :-
    ponerse_en(aldea), orden(hablar(el_pozo_de_los_deseos), Items),
    assertion(Items = [error(personaje_desconocido(el_pozo_de_los_deseos))]).

test(por_que_no_explorar_si_no_hay_nada) :-
    ponerse_en(taberna), orden(por_que_no(explorar), Items), assertion(Items = [vista(diag, explorar, _)]).

test(por_que_no_explorar_si_se_puede_lo_dice) :-
    ponerse_en(bosque), orden(por_que_no(explorar), Items), assertion(Items = [error(sin_fallo(explorar))]).

test(los_errores_tienen_texto) :-
    narrador:texto_error(nada_que_explorar, T1), assertion(contiene(T1, 'nada especial')),
    narrador:texto_error(termina_el_evento, T2), assertion(contiene(T2, 'evento sin resolver')).

test(la_ayuda_explica_explorar) :-
    narrador:ayuda_de(explorar, T), assertion(contiene(T, 'explorar.')).

:- end_tests(errores).

:- begin_tests(consola_api_y_web).

test(mirar_avisa_de_que_hay_algo_que_explorar_cuando_esta_pendiente) :-
    nueva_partida, orden(aceptar(ratas_del_granero), _), orden(ir(aldea), _),
    terminar_combate_y_mirar(T), assertion(contiene(T, 'algo especial que explorar')).

test(mirar_no_dice_nada_si_no_hay_suceso) :-
    nueva_partida, orden(mirar, Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(\+ contiene(T, 'algo especial')).

test(la_consola_enseña_el_suceso_al_llegar) :-
    nueva_partida, orden(ir(aldea), Is), with_output_to(atom(T), ui:mostrar(resultado(Is))),
    assertion(contiene(T, 'Pozo de los deseos')), assertion(contiene(T, 'Elige con elegir')).

test(la_api_ofrece_explorar_solo_si_hay_algo_pendiente_y_nada_en_marcha) :-
    ponerse_en(taberna), api:estado_json(E0), campo(E0, acciones, A0),
    assertion(\+ ( member(A, A0), campo(A, familia, explorar) )),
    ponerse_en(bosque), api:estado_json(E1), campo(E1, acciones, A1),
    assertion(( member(A2, A1), campo(A2, familia, explorar), campo(A2, comando, explorar) )).

test(con_un_evento_abierto_la_api_no_ofrece_explorar) :-
    nueva_partida, orden(aceptar(gato_en_el_arbol), _), orden(ir(aldea), _),
    api:estado_json(E), campo(E, acciones, As),
    assertion(\+ ( member(A, As), campo(A, familia, explorar) )).

test(el_item_de_un_suceso_lo_marca_como_suceso_y_el_de_un_personaje_no) :-
    nueva_partida, api:ejecutar_orden('ir(aldea)', R), campo(R, items, Is),
    member(I, Is), campo(I, tipo, charla), !, campo(I, suceso, S), assertion(S == @(true)),
    ponerse_en(taberna), api:ejecutar_orden('hablar(mantecosa)', R2), campo(R2, items, I2),
    member(J, I2), campo(J, tipo, charla), !, campo(J, suceso, S2), assertion(S2 == @(false)).

test(la_web_sabe_llamarlo_suceso_y_ofrece_explorar) :-
    setup_call_cleanup(open('web/app.js', read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs0) ), close(S)),
    exclude(==(13), Cs0, Cs), atom_codes(J, Cs),
    assertion(contiene(J, 'explorar: "Explorar"')), assertion(contiene(J, 'e.suceso ? "SUCESO" : "CHARLA"')),
    assertion(contiene(J, 'suceso: it.suceso')), assertion(contiene(J, '"usar", "explorar", "inventario"')).

:- end_tests(consola_api_y_web).

:- begin_tests(balance).

test(la_partida_sigue_siendo_ganable_con_los_sucesos) :-
    findall(x, ( between(1, 30, I), S is 9000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gs),
    length(Gs, N), assertion(N >= 24).

test(el_hablador_que_ademas_aprovecha_los_sucesos_no_pierde_mas) :-
    findall(x, ( between(1, 30, I), S is 9000 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), A),
    findall(x, ( between(1, 30, I), S is 9000 + I, episodio(plan_hablador(10, 2), S, 400, r(victoria, _, _, _)) ), B),
    length(A, NA), length(B, NB), assertion(NB >= NA - 3).

:- end_tests(balance).

% Dos escenas abiertas a la vez (un suceso de la zona y la charla de un personaje): elegir/1 va a la ULTIMA que se enseño.
% (Un fallo encontrado jugando: en el Camino Real, tras hablar con el ganso, elegir(3) iba a la carreta del Gremio.)
:- begin_tests(dos_escenas_abiertas).

test(tras_hablar_con_el_ganso_elegir_va_a_su_charla_y_no_al_suceso) :-
    nueva_partida, orden(ir(camino_real), _),
    assertion(charlas:charla_abierta(la_carreta_del_gremio)),
    orden(hablar(ganso_recaudador), _),
    assertion(charlas:charla_elegida(ganso_recaudador)),
    orden(elegir(3), Items),
    assertion(\+ memberchk(error(_), Items)),
    assertion(charlas:charla_hecha(ganso_recaudador)),
    assertion(\+ charlas:charla_hecha(la_carreta_del_gremio)).

test(por_que_no_explica_la_opcion_de_la_charla_en_curso) :-
    nueva_partida, orden(ir(camino_real), _), orden(hablar(ganso_recaudador), _),
    juego:objetivo_de_accion(elegir(3), Meta),
    assertion(Meta = charlas:puede_elegir(ganso_recaudador, esquivar_al_ganso)).

test(cerrada_la_del_ganso_elegir_vuelve_al_suceso_que_seguia_abierto) :-
    nueva_partida, orden(ir(camino_real), _), orden(hablar(ganso_recaudador), _), orden(elegir(3), _),
    assertion(charlas:charla_elegida(la_carreta_del_gremio)),
    orden(elegir(1), Items),
    assertion(\+ memberchk(error(_), Items)),
    assertion(charlas:charla_hecha(la_carreta_del_gremio)).

test(explorar_devuelve_el_suceso_al_primer_plano) :-
    nueva_partida, orden(ir(camino_real), _), orden(hablar(ganso_recaudador), _),
    orden(explorar, _),
    assertion(charlas:charla_elegida(la_carreta_del_gremio)).

:- end_tests(dos_escenas_abiertas).
