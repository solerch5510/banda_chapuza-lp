% aprendidas.pl (pruebas)
% Las habilidades activas que se aprenden al subir de nivel (docs/13 §0): una por miembro en el nivel 2, de
% una vez por combate. Los datos (mundo:habilidad_en/3, una_vez_por_combate/1), la regla conoce_habilidad/2,
% la marca ya_usada/2, el efecto de cada una (golpe de escudo, raclette derramada, nana de requeson y punalada
% trapera, y la combinacion de la primera con la ultima), los comandos habilidad(Nombre) y
% habilidad(Nombre, Objetivo), explicar y por_que_no, la subida de nivel y lo que ensena la API.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/aprendidas -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

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
:- use_module('../src/api').

% ---------------------------------------------------------------------------
% Ayudantes
% ---------------------------------------------------------------------------
% Un combate contra Tipos con la primera ronda ya abierta.
combate_listo(Tipos) :-
    nueva_partida,
    aplicar_una([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs),
    aplicar_una(Efs).

% La Banda entera en el nivel 2 (20 de experiencia basta), sin pasar por la subida de nivel con texto.
todos_al_nivel_2 :-
    forall(compania:miembro(P),
           ( compania:efectos_ganar_xp(P, 20, Efs), aplicar_una(Efs) )).

% Un combate contra Tipos con toda la Banda en el nivel 2.
combate_de_nivel_2(Tipos) :-
    combate_listo(Tipos),
    todos_al_nivel_2.

% Fija a mano la cola de turnos.
cola_a(Ids) :-
    retractall(estado:cola_turnos(_)),
    assertz(estado:cola_turnos(Ids)).

% orden(+Comando, -Items): el comando por juego:ejecutar/2.
orden(Cmd, Items) :-
    juego:ejecutar(Cmd, resultado(Items)).

dejar_queso_en(N) :-
    economia:queso_total(T),
    K is T - N,
    economia:efectos_perdida(K, Efs),
    aplicar_una(Efs).

campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% efectos_de_una(+Id, +Hab, +Objetivo, -Efectos): los efectos de la habilidad, sin dejar puntos de eleccion
% (puede_atacar/2 deja uno abierto, igual que en tests/habilidades).
efectos_de_una(Id, Hab, Objetivo, Efectos) :-
    once(combate:efectos_habilidad(Id, Hab, Objetivo, Efectos)).

% aplicar_una(+Efectos): aplicar_efectos/1 sin dejar el punto de eleccion que deja abierto.
aplicar_una(Efectos) :-
    once(estado:aplicar_efectos(Efectos)).

% ---------------------------------------------------------------------------
:- begin_tests(los_datos).

test(cada_miembro_aprende_una_en_el_nivel_2) :-
    forall(compania:miembro(P), findall(H, mundo:habilidad_en(P, 2, H), [_])),
    findall(P-H, mundo:habilidad_en(P, _, H), Ps),
    msort(Ps, [baldomero-golpe_de_escudo, pimentina-raclette_derramada, rufino-nana_de_requeson, tuerca-punalada_trapera]).

test(las_cuatro_son_de_una_vez_por_combate_y_las_de_siempre_no) :-
    forall(mundo:habilidad_en(_, _, H), mundo:una_vez_por_combate(H)),
    forall(mundo:habilidad_de(_, H), \+ mundo:una_vez_por_combate(H)).

test(los_efectos_son_los_del_diseno) :-
    efecto_habilidad(golpe_de_escudo, golpe_aturdidor),
    efecto_habilidad(raclette_derramada, dano_a_todos(4)),
    efecto_habilidad(nana_de_requeson, curar_grupo(4)),
    efecto_habilidad(punalada_trapera, sin_defensa(2)).

test(solo_la_magia_de_pimentina_cuesta_queso) :-
    mundo:coste_queso(raclette_derramada, 2),
    findall(H, ( mundo:habilidad_en(_, _, H), mundo:coste_queso(H, _) ), [raclette_derramada]).

test(cada_una_tiene_nombre_y_aviso_al_aprenderla) :-
    forall(mundo:habilidad_en(P, _, H),
           (   narrador:nombre(H, _),
               narrador:texto(habilidad_nueva, [P, H], 0, T), atom(T)
           )).

:- end_tests(los_datos).

% ---------------------------------------------------------------------------
:- begin_tests(conocerlas).

test(en_el_nivel_1_solo_se_sabe_la_de_siempre) :-
    nueva_partida,
    forall(compania:miembro(P),
           (   mundo:habilidad_de(P, B), conoce_habilidad(P, B),
               mundo:habilidad_en(P, _, H), \+ conoce_habilidad(P, H)
           )).

test(en_el_nivel_2_se_saben_las_dos) :-
    nueva_partida, todos_al_nivel_2,
    forall(mundo:habilidad_en(P, _, H), conoce_habilidad(P, H)),
    forall(mundo:habilidad_de(P, B), conoce_habilidad(P, B)).

test(una_habilidad_de_otro_no_se_sabe) :-
    nueva_partida, todos_al_nivel_2,
    \+ conoce_habilidad(baldomero, nana_de_requeson),
    \+ conoce_habilidad(rufino, carga_heroica).

test(subir_al_nivel_2_avisa_de_la_habilidad_nueva) :-
    nueva_partida,
    compania:efectos_ganar_xp(rufino, 20, Efs),
    assertion(memberchk(mensaje(habilidad_nueva, [rufino, nana_de_requeson]), Efs)).

test(subir_del_2_al_3_no_vuelve_a_avisar) :-
    nueva_partida,
    compania:efectos_ganar_xp(rufino, 20, E1), aplicar_una(E1),
    compania:efectos_ganar_xp(rufino, 30, E2),
    assertion(\+ memberchk(mensaje(habilidad_nueva, _), E2)).

test(la_compania_las_lista_cuando_ya_se_saben) :-
    nueva_partida,
    compania:habilidades_aprendidas(tuerca, []),
    todos_al_nivel_2,
    compania:habilidades_aprendidas(tuerca, [punalada_trapera]).

:- end_tests(conocerlas).

% ---------------------------------------------------------------------------
:- begin_tests(el_golpe_de_escudo).

test(pega_lo_de_siempre_y_deja_aturdido, [nondet]) :-
    combate_de_nivel_2([bandido_torpe]),
    B = e(bandido_torpe, 1),
    combate:dano(baldomero, B, D),
    efectos_de_una(baldomero, golpe_de_escudo, B, Efs),
    assertion(memberchk(dano(B, D), Efs)),
    assertion(memberchk(alterar(B, aturdido, 1), Efs)),
    assertion(memberchk(alterar(baldomero, golpe_de_escudo, fijo), Efs)).

test(el_aturdido_pierde_su_turno) :-
    combate_de_nivel_2([bandido_torpe]),
    B = e(bandido_torpe, 1),
    efectos_de_una(baldomero, golpe_de_escudo, B, Efs), aplicar_una(Efs),
    assertion(aturdido(B)),
    cola_a([B]),
    juego:turno_de(B, 5, Items),
    assertion(memberchk(msg(aturdido, [B], _), Items)),
    assertion(\+ aturdido(B)).

test(a_quien_tumba_no_lo_aturde) :-
    combate_de_nivel_2([rata_quesera]),
    B = e(rata_quesera, 1),
    aplicar_una([dano(B, 7)]),
    efectos_de_una(baldomero, golpe_de_escudo, B, Efs),
    assertion(memberchk(mensaje(cae, [B]), Efs)),
    assertion(\+ memberchk(alterar(B, aturdido, _), Efs)).

test(no_llega_a_la_retaguardia_si_hay_alguien_delante) :-
    combate_de_nivel_2([bandido_torpe, ballestero_oxidado]),
    \+ puede_habilidad(baldomero, golpe_de_escudo, e(ballestero_oxidado, 1)).

:- end_tests(el_golpe_de_escudo).

% ---------------------------------------------------------------------------
:- begin_tests(una_vez_por_combate).

test(despues_de_usarla_ya_no_se_puede) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    efectos_de_una(baldomero, golpe_de_escudo, e(bandido_torpe, 1), Efs), aplicar_una(Efs),
    assertion(ya_usada(baldomero, golpe_de_escudo)),
    assertion(\+ puede_habilidad(baldomero, golpe_de_escudo, e(bandido_torpe, 2))).

test(la_de_siempre_se_sigue_pudiendo_usar) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    efectos_de_una(baldomero, golpe_de_escudo, e(bandido_torpe, 1), Efs), aplicar_una(Efs),
    assertion(puede_habilidad(baldomero, carga_heroica, e(bandido_torpe, 2))),
    efectos_de_una(baldomero, carga_heroica, e(bandido_torpe, 2), E2),
    assertion(\+ memberchk(alterar(baldomero, carga_heroica, _), E2)).

test(en_el_combate_siguiente_vuelve_a_estar) :-
    combate_de_nivel_2([bandido_torpe]),
    efectos_de_una(baldomero, golpe_de_escudo, e(bandido_torpe, 1), Efs), aplicar_una(Efs),
    aplicar_una([terminar_combate, iniciar_combate([rata_quesera])]),
    combate:efectos_ronda(R), aplicar_una(R),
    assertion(\+ ya_usada(baldomero, golpe_de_escudo)),
    assertion(puede_habilidad(baldomero, golpe_de_escudo, e(rata_quesera, 1))).

:- end_tests(una_vez_por_combate).

% ---------------------------------------------------------------------------
:- begin_tests(la_raclette).

test(da_cuatro_a_cada_enemigo_este_donde_este) :-
    combate_de_nivel_2([bandido_torpe, ballestero_oxidado]),
    efectos_de_una(pimentina, raclette_derramada, ninguno, Efs),
    assertion(memberchk(dano(e(bandido_torpe, 1), 4), Efs)),
    assertion(memberchk(dano(e(ballestero_oxidado, 1), 4), Efs)).

test(no_quema_a_la_banda) :-
    combate_de_nivel_2([bandido_torpe]),
    efectos_de_una(pimentina, raclette_derramada, ninguno, Efs),
    forall(compania:miembro(P), assertion(\+ memberchk(dano(P, _), Efs))).

test(no_toca_a_los_caidos) :-
    combate_de_nivel_2([rata_quesera, rata_quesera]),
    aplicar_una([dano(e(rata_quesera, 1), 99)]),
    efectos_de_una(pimentina, raclette_derramada, ninguno, Efs),
    assertion(\+ memberchk(dano(e(rata_quesera, 1), _), Efs)),
    assertion(memberchk(dano(e(rata_quesera, 2), 4), Efs)).

test(cuesta_dos_quesos) :-
    combate_de_nivel_2([bandido_torpe]),
    economia:queso_total(Antes),
    efectos_de_una(pimentina, raclette_derramada, ninguno, Efs), aplicar_una(Efs),
    economia:queso_total(Despues),
    assertion(Despues =:= Antes - 2).

test(con_un_solo_queso_no_se_puede_y_la_fondue_si) :-
    combate_de_nivel_2([bandido_torpe]),
    dejar_queso_en(1),
    assertion(\+ puede_habilidad(pimentina, raclette_derramada, ninguno)),
    assertion(puede_habilidad(pimentina, fondue_flamigera, e(bandido_torpe, 1))).

test(no_pide_objetivo) :-
    combate_de_nivel_2([bandido_torpe]),
    \+ puede_habilidad(pimentina, raclette_derramada, e(bandido_torpe, 1)),
    puede_habilidad(pimentina, raclette_derramada, ninguno).

:- end_tests(la_raclette).

% ---------------------------------------------------------------------------
:- begin_tests(la_nana).

test(cura_cuatro_a_cada_uno_sin_pasar_del_maximo) :-
    combate_de_nivel_2([bandido_torpe]),
    aplicar_una([dano(baldomero, 10), dano(rufino, 1)]),
    estado:vida(baldomero, B0),
    efectos_de_una(rufino, nana_de_requeson, ninguno, Efs), aplicar_una(Efs),
    estado:vida(baldomero, B1), estado:vida(rufino, R1), estado:vida_maxima(rufino, RM),
    assertion(B1 =:= B0 + 4),
    assertion(R1 =:= RM).

test(a_los_caidos_no_los_levanta) :-
    combate_de_nivel_2([bandido_torpe]),
    aplicar_una([dano(tuerca, 99)]),
    efectos_de_una(rufino, nana_de_requeson, ninguno, Efs),
    assertion(\+ memberchk(curar(tuerca, _), Efs)),
    assertion(memberchk(curar(baldomero, 4), Efs)).

test(no_cura_a_los_enemigos) :-
    combate_de_nivel_2([bandido_torpe]),
    efectos_de_una(rufino, nana_de_requeson, ninguno, Efs),
    assertion(\+ memberchk(curar(e(_, _), _), Efs)).

:- end_tests(la_nana).

% ---------------------------------------------------------------------------
:- begin_tests(la_punalada).

test(no_resta_la_defensa, [nondet]) :-
    combate_de_nivel_2([bandido_torpe]),
    B = e(bandido_torpe, 1),
    combate:ataque(tuerca, A), combate:modificador(tuerca, B, M),
    combate:dano(tuerca, B, Normal),
    efectos_de_una(tuerca, punalada_trapera, B, Efs),
    Esperado is A + M,
    assertion(memberchk(dano(B, Esperado), Efs)),
    assertion(Esperado > Normal).

test(contra_un_aturdido_hace_el_doble, [nondet]) :-
    combate_de_nivel_2([bandido_torpe]),
    B = e(bandido_torpe, 1),
    combate:ataque(tuerca, A), combate:modificador(tuerca, B, M),
    aplicar_una([alterar(B, aturdido, 1)]),
    efectos_de_una(tuerca, punalada_trapera, B, Efs),
    Esperado is (A + M) * 2,
    assertion(memberchk(dano(B, Esperado), Efs)).

test(el_escudo_de_baldomero_y_la_punalada_de_tuerca_se_combinan) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    B = e(bandido_torpe, 2),
    cola_a([baldomero, tuerca]),
    orden(habilidad(golpe_de_escudo, B), _),
    estado:vida(B, V1),
    assertion(aturdido(B)),
    orden(habilidad(punalada_trapera, B), I2),
    assertion(memberchk(msg(punalada, [B], _), I2)),
    assertion(( \+ compania:vivo(B) ; estado:vida(B, V2), V2 < V1 )).

:- end_tests(la_punalada).

% ---------------------------------------------------------------------------
:- begin_tests(los_comandos).

test(con_nombre_y_objetivo) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, bandido_torpe), Items),
    assertion(memberchk(msg(golpe_de_escudo, [e(bandido_torpe, 1)], _), Items)),
    assertion(ya_usada(baldomero, golpe_de_escudo)).

test(solo_con_el_nombre_si_no_pide_enemigo) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([rufino]),
    orden(habilidad(nana_de_requeson), Items),
    assertion(memberchk(msg(nana, [], _), Items)).

test(si_no_pide_enemigo_el_objetivo_sobra) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([rufino]),
    orden(habilidad(nana_de_requeson, bandido_torpe), Items),
    assertion(memberchk(msg(nana, [], _), Items)).

test(si_pide_enemigo_y_no_se_da_se_avisa) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([tuerca]),
    orden(habilidad(punalada_trapera), Items),
    assertion(Items == [error(habilidad_pide_objetivo(punalada_trapera))]).

test(sin_el_nivel_no_se_puede) :-
    combate_listo([bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, bandido_torpe), Items),
    assertion(Items == [error(no_puede_habilidad(baldomero, golpe_de_escudo))]).

test(la_de_otro_no_se_puede) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(nana_de_requeson), Items),
    assertion(Items == [error(no_puede_habilidad(baldomero, nana_de_requeson))]).

test(un_nombre_que_no_existe) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(chorizo, bandido_torpe), Items),
    assertion(Items == [error(habilidad_desconocida(chorizo))]).

test(la_de_siempre_se_sigue_escribiendo_igual) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(bandido_torpe), Items),
    assertion(memberchk(msg(carga_heroica, [e(bandido_torpe, 1)], _), Items)).

test(la_segunda_vez_en_el_mismo_combate_no) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, e(bandido_torpe, 1)), _),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, e(bandido_torpe, 2)), Items),
    assertion(Items == [error(no_puede_habilidad(baldomero, golpe_de_escudo))]).

test(textos_de_los_errores) :-
    narrador:texto_error(habilidad_pide_objetivo(punalada_trapera), T1),
    assertion(sub_atom(T1, 0, _, _, 'La Puñalada Trapera necesita un enemigo')),
    assertion(sub_atom(T1, _, _, _, 'habilidad(punalada_trapera, Objetivo)')),
    narrador:texto_error(habilidad_desconocida(chorizo), T2),
    assertion(sub_atom(T2, _, _, _, chorizo)).

:- end_tests(los_comandos).

% ---------------------------------------------------------------------------
:- begin_tests(explicarlas).

test(explicar_la_ultima_habilidad_por_su_nombre) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([rufino]),
    orden(habilidad(nana_de_requeson), _),
    orden(explicar(habilidad(nana_de_requeson)), Items),
    assertion(\+ memberchk(error(_), Items)).

test(las_acciones_guardadas_se_reconocen) :-
    juego:misma_accion(habilidad(nana_de_requeson), habilidad(rufino, nana_de_requeson, ninguno)),
    juego:misma_accion(habilidad(golpe_de_escudo, bandido_torpe), habilidad(baldomero, golpe_de_escudo, e(bandido_torpe, 1))),
    \+ juego:misma_accion(habilidad(golpe_de_escudo, bandido_torpe), habilidad(baldomero, punalada_trapera, e(bandido_torpe, 1))).

test(por_que_no_sin_el_nivel) :-
    combate_listo([bandido_torpe]),
    cola_a([baldomero]),
    orden(por_que_no(habilidad(golpe_de_escudo, bandido_torpe)), [vista(diag, _, Diag)]),
    narrador:clave_de_diag(Diag, Clave),
    assertion(Clave = falla(conoce_habilidad(baldomero, golpe_de_escudo))).

test(por_que_no_si_ya_se_uso) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, e(bandido_torpe, 1)), _),
    cola_a([baldomero]),
    orden(por_que_no(habilidad(golpe_de_escudo, e(bandido_torpe, 2))), [vista(diag, _, Diag)]),
    narrador:clave_de_diag(Diag, Clave),
    assertion(Clave = impide(ya_usada(baldomero, golpe_de_escudo))).

test(por_que_no_la_raclette_sin_queso) :-
    combate_de_nivel_2([bandido_torpe]),
    dejar_queso_en(1),
    cola_a([pimentina]),
    orden(por_que_no(habilidad(raclette_derramada)), [vista(diag, _, Diag)]),
    narrador:comentario_diag(Diag, resumido, 0, Texto),
    assertion(sub_atom(Texto, _, _, _, queso)).

:- end_tests(explicarlas).

% ---------------------------------------------------------------------------
:- begin_tests(en_la_api).

acciones(Cmds) :-
    api:estado_json(E), campo(E, acciones, As),
    findall(C-H, ( member(A, As), campo(A, comando, C), campo(A, habilitada, H) ), Cmds).

etiqueta_de(Cmd, Etiqueta) :-
    api:estado_json(E), campo(E, acciones, As),
    member(A, As), campo(A, comando, Cmd), campo(A, etiqueta, Etiqueta), !.

test(en_el_nivel_1_no_se_ofrecen) :-
    combate_listo([bandido_torpe]),
    cola_a([baldomero]),
    acciones(As),
    assertion(\+ ( member(C-_, As), sub_atom(C, _, _, _, golpe_de_escudo) )).

test(en_el_nivel_2_se_ofrecen_con_su_nombre) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([baldomero]),
    acciones(As),
    assertion(memberchk('habilidad(golpe_de_escudo, bandido_torpe)'-(@(true)), As)),
    assertion(memberchk('habilidad(bandido_torpe)'-(@(true)), As)),
    etiqueta_de('habilidad(golpe_de_escudo, bandido_torpe)', E1),
    assertion(E1 == 'Golpe de Escudo contra Bandido Torpe'),
    etiqueta_de('habilidad(bandido_torpe)', E2),
    assertion(E2 == 'Carga Heroica contra Bandido Torpe').

test(sin_enemigo_va_solo_el_nombre) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([rufino]),
    acciones(As),
    assertion(memberchk('habilidad(nana_de_requeson)'-(@(true)), As)),
    etiqueta_de('habilidad(nana_de_requeson)', E),
    assertion(E == 'Nana de Requesón').

test(ya_usada_se_ofrece_desactivada) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    cola_a([rufino]),
    orden(habilidad(nana_de_requeson), _),
    cola_a([rufino]),
    acciones(As),
    assertion(memberchk('habilidad(nana_de_requeson)'-(@(false)), As)).

test(la_ficha_trae_la_que_se_aprende_y_como_se_escribe) :-
    api:fichas_json(J), campo(J, miembros, Ms),
    forall(member(M, Ms),
           (   campo(M, aprendidas, [A]),
               campo(A, nivel, 2), campo(A, comando, C), atom(C),
               sub_atom(C, 0, _, _, 'habilidad(')
           )),
    member(M, Ms), campo(M, id, pimentina), !,
    campo(M, aprendidas, [R]),
    assertion(campo(R, comando, 'habilidad(raclette_derramada).')),
    assertion(campo(R, coste, 'Cuesta 2 quesos')).

test(la_banda_dice_cuales_sabe_y_si_ya_las_gasto) :-
    combate_de_nivel_2([bandido_torpe]),
    cola_a([rufino]),
    orden(habilidad(nana_de_requeson), _),
    api:estado_json(E), campo(E, banda, Bs),
    member(B, Bs), campo(B, id, rufino), !,
    campo(B, habilidades, [H]),
    assertion(campo(H, id, nana_de_requeson)),
    assertion(campo(H, usada, @(true))).

test(el_combate_dice_que_enemigo_esta_aturdido) :-
    combate_de_nivel_2([bandido_torpe, bandido_torpe]),
    cola_a([baldomero]),
    orden(habilidad(golpe_de_escudo, e(bandido_torpe, 1)), _),
    api:estado_json(E), campo(E, combate, C), campo(C, enemigos, Es),
    findall(Id-A, ( member(X, Es), campo(X, id, Id), campo(X, aturdido, A) ), Pares),
    assertion(Pares == ['e(bandido_torpe, 1)'-(@(true)), 'e(bandido_torpe, 2)'-(@(false))]).

:- end_tests(en_la_api).
