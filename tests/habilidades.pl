% habilidades.pl (pruebas)
% T-30: una habilidad por personaje. La tabla de datos efecto_habilidad/2, las reglas
% puede_habilidad/2 (el personaje puede) y /3 (ademas el objetivo vale), los efectos que producen
% (carga heroica, fondue flamigera, balada inspiradora, rebuscar bolsillos) y el comando
% habilidad / habilidad(Objetivo) de juego:ejecutar/2, con su prueba guardada para explicar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/habilidades -g "run_tests,halt" -t "halt(1)"

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

% Un combate contra Tipos con la primera ronda ya abierta.
combate_listo(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs).

% Fija a mano la cola de turnos.
cola_a(Ids) :-
    retractall(estado:cola_turnos(_)),
    assertz(estado:cola_turnos(Ids)).

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

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

sin_queso :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)).

% ---------------------------------------------------------------------------

:- begin_tests(los_datos).

test(cada_habilidad_de_un_personaje_tiene_su_efecto_y_su_objetivo) :-
    forall(mundo:habilidad_de(_, H),
           (   efecto_habilidad(H, _), objetivo_de_habilidad(H, _) )).

test(el_efecto_de_cada_habilidad_es_distinto) :-
    findall(D, ( mundo:habilidad_de(_, H), efecto_habilidad(H, D) ), Ds),
    sort(Ds, Unicos),
    length(Ds, N), length(Unicos, N).

test(los_cuatro_efectos_son_los_del_diseno) :-
    efecto_habilidad(carga_heroica, golpe_extra(4)),
    efecto_habilidad(fondue_flamigera, dano_fijo(8)),
    efecto_habilidad(balada_inspiradora, moral_grupo(1)),
    efecto_habilidad(rebuscar_bolsillos, queso_del_bolsillo(1)).

test(solo_la_balada_no_necesita_enemigo) :-
    findall(H, objetivo_de_habilidad(H, ninguno), [balada_inspiradora]),
    findall(H, objetivo_de_habilidad(H, enemigo), Hs),
    msort(Hs, [carga_heroica, fondue_flamigera, rebuscar_bolsillos]).

test(una_habilidad_inexistente_no_tiene_efecto, [fail]) :-
    efecto_habilidad(volar, _).

:- end_tests(los_datos).

:- begin_tests(puede_habilidad_el_personaje).

test(cada_miembro_en_pie_puede_usar_la_suya, [setup(nueva_partida)]) :-
    forall(mundo:habilidad_de(Id, H), puede_habilidad(Id, H)).

test(nadie_puede_usar_la_de_otro, [setup(nueva_partida)]) :-
    forall(( mundo:habilidad_de(Id, _), mundo:habilidad_de(Otro, H), Id \== Otro ),
           \+ puede_habilidad(Id, H)).

test(un_miembro_caido_no_puede, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(rufino, 999)),
    \+ puede_habilidad(rufino, balada_inspiradora),
    puede_habilidad(baldomero, carga_heroica).

test(un_miembro_aturdido_no_puede, [setup(combate_listo([bandido_torpe]))]) :-
    aplicar_efecto(alterar(tuerca, aturdido, 2)),
    \+ puede_habilidad(tuerca, rebuscar_bolsillos),
    puede_habilidad(rufino, balada_inspiradora).

test(un_miembro_en_huelga_no_puede, [setup(nueva_partida)]) :-
    moral_a(baldomero, 2),
    \+ puede_habilidad(baldomero, carga_heroica),
    puede_habilidad(rufino, balada_inspiradora).

test(solo_la_magia_de_cocina_pide_queso, [setup(nueva_partida)]) :-
    sin_queso,
    \+ puede_habilidad(pimentina, fondue_flamigera),
    puede_habilidad(baldomero, carga_heroica),
    puede_habilidad(rufino, balada_inspiradora),
    puede_habilidad(tuerca, rebuscar_bolsillos).

test(un_queso_basta_para_el_hechizo, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 11)),
    puede_habilidad(pimentina, fondue_flamigera).

:- end_tests(puede_habilidad_el_personaje).

:- begin_tests(puede_habilidad_el_objetivo).

test(los_tres_con_enemigo_valen_contra_un_enemigo_al_alcance, [setup(combate_listo([bandido_torpe])), nondet]) :-
    puede_habilidad(baldomero, carga_heroica, e(bandido_torpe, 1)),
    puede_habilidad(pimentina, fondue_flamigera, e(bandido_torpe, 1)),
    puede_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1)).

test(la_balada_vale_sin_objetivo, [setup(nueva_partida)]) :-
    puede_habilidad(rufino, balada_inspiradora, ninguno).

test(la_balada_no_vale_contra_un_enemigo, [setup(combate_listo([bandido_torpe])), fail]) :-
    puede_habilidad(rufino, balada_inspiradora, e(bandido_torpe, 1)).

test(la_carga_no_vale_sin_objetivo, [setup(combate_listo([bandido_torpe])), fail]) :-
    puede_habilidad(baldomero, carga_heroica, ninguno).

test(no_vale_contra_un_aliado, [setup(combate_listo([bandido_torpe])), fail]) :-
    puede_habilidad(baldomero, carga_heroica, rufino).

test(no_vale_contra_quien_no_existe, [setup(combate_listo([bandido_torpe])), fail]) :-
    puede_habilidad(baldomero, carga_heroica, e(bandido_torpe, 9)).

test(la_carga_respeta_el_miedo_a_los_caballos, [setup(combate_listo([bandido_montado])), fail]) :-
    puede_habilidad(baldomero, carga_heroica, e(bandido_montado, 1)).

test(con_la_venda_baldomero_carga_contra_el_caballo, [setup(combate_listo([bandido_montado])), nondet]) :-
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    puede_habilidad(baldomero, carga_heroica, e(bandido_montado, 1)).

test(la_fila_manda_tambien_con_las_habilidades, [setup(combate_listo([bandido_torpe]))]) :-
    % Un enemigo en la retaguardia no se alcanza con una habilidad de cuerpo a cuerpo
    aplicar_efecto(alterar(tuerca, aturdido, 1)),
    \+ puede_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1)).

test(a_cada_enemigo_se_le_rebuscan_los_bolsillos_una_vez, [setup(combate_listo([bandido_torpe])), nondet]) :-
    puede_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1)),
    aplicar_efecto(alterar(e(bandido_torpe, 1), rebuscado, fijo)),
    \+ puede_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1)).

test(sin_queso_el_hechizo_tampoco_vale_con_objetivo, [setup(combate_listo([bandido_torpe])), fail]) :-
    sin_queso,
    puede_habilidad(pimentina, fondue_flamigera, e(bandido_torpe, 1)).

:- end_tests(puede_habilidad_el_objetivo).

:- begin_tests(los_efectos).

test(la_carga_es_el_golpe_mas_cuatro, [setup(combate_listo([bandido_torpe])), nondet]) :-
    B = e(bandido_torpe, 1),
    dano(baldomero, B, D0),
    D is D0 + 4,
    efectos_habilidad(baldomero, carga_heroica, B, Efs),
    memberchk(dano(B, D), Efs),
    memberchk(mensaje(carga_heroica, [B]), Efs),
    memberchk(mensaje(golpe, [baldomero, B, D]), Efs).

test(la_carga_deja_caer_al_que_ya_no_aguanta, [setup(combate_listo([rata_quesera])), nondet]) :-
    B = e(rata_quesera, 1),
    efectos_habilidad(baldomero, carga_heroica, B, Efs),
    memberchk(mensaje(cae, [B]), Efs).

test(la_fondue_hace_ocho_ignorando_la_defensa, [setup(combate_listo([bandido_montado])), nondet]) :-
    B = e(bandido_montado, 1),
    efectos_habilidad(pimentina, fondue_flamigera, B, Efs),
    memberchk(dano(B, 8), Efs),
    memberchk(mensaje(fondue, [B]), Efs).

test(la_fondue_gasta_un_queso_el_mas_rancio, [setup(combate_listo([bandido_torpe])), nondet]) :-
    aplicar_efecto(ganar_queso(brie, 12, 1)),               % un brie rancio
    efectos_habilidad(pimentina, fondue_flamigera, e(bandido_torpe, 1), Efs),
    findall(G, member(G, Efs), _),
    findall(G, ( member(G, Efs), G = gastar_queso(_, _, _) ), [gastar_queso(brie, 12, 1)]).

test(las_demas_habilidades_no_gastan_queso, [setup(combate_listo([bandido_torpe]))]) :-
    forall(( member(Id-H-O, [baldomero-carga_heroica-e(bandido_torpe, 1),
                              rufino-balada_inspiradora-ninguno,
                              tuerca-rebuscar_bolsillos-e(bandido_torpe, 1)]) ),
           (   efectos_habilidad(Id, H, O, Efs),
               \+ ( member(E, Efs), E = gastar_queso(_, _, _) )
           )).

test(la_fondue_mata_a_la_rata, [setup(combate_listo([rata_quesera])), nondet]) :-
    B = e(rata_quesera, 1),
    efectos_habilidad(pimentina, fondue_flamigera, B, Efs),
    memberchk(mensaje(cae, [B]), Efs).

test(la_balada_sube_un_punto_a_cada_miembro, [setup(nueva_partida)]) :-
    efectos_habilidad(rufino, balada_inspiradora, ninguno, Efs),
    findall(Id, member(mod_moral(Id, 1), Efs), Ids),
    msort(Ids, [baldomero, pimentina, rufino, tuerca]),
    memberchk(mensaje(balada, []), Efs).

test(la_balada_al_aplicarse_sube_la_moral, [setup(nueva_partida)]) :-
    efectos_habilidad(rufino, balada_inspiradora, ninguno, Efs),
    aplicar_efectos(Efs),
    forall(estado:en_compania(Id), estado:moral(Id, 7)).

test(la_balada_llega_tambien_a_quien_esta_en_huelga_y_lo_saca_de_ella, [setup(nueva_partida)]) :-
    moral_a(tuerca, 2),
    esta_en_huelga(tuerca),
    efectos_habilidad(rufino, balada_inspiradora, ninguno, Efs),
    aplicar_efectos(Efs),
    estado:moral(tuerca, 3),
    \+ esta_en_huelga(tuerca).

test(la_balada_llega_tambien_a_un_caido, [setup(combate_listo([bandido_torpe])), nondet]) :-
    aplicar_efecto(dano(tuerca, 999)),
    efectos_habilidad(rufino, balada_inspiradora, ninguno, Efs),
    aplicar_efectos(Efs),
    estado:moral(tuerca, 7).

test(la_balada_no_pasa_del_maximo, [setup(nueva_partida)]) :-
    forall(estado:en_compania(Id), moral_a(Id, 10)),
    efectos_habilidad(rufino, balada_inspiradora, ninguno, Efs),
    aplicar_efectos(Efs),
    forall(estado:en_compania(Id), estado:moral(Id, 10)).

test(rebuscar_a_un_bandido_da_un_queso_fresco, [setup(combate_listo([bandido_torpe])), nondet]) :-
    B = e(bandido_torpe, 1),
    efectos_habilidad(tuerca, rebuscar_bolsillos, B, Efs),
    memberchk(ganar_queso(cheddar, 0, 1), Efs),
    memberchk(alterar(B, rebuscado, fijo), Efs),
    memberchk(mensaje(rebuscar, [B, ok]), Efs).

test(rebuscar_a_quien_no_lleva_queso_no_da_nada_pero_se_marca, [setup(combate_listo([moho_saltarin])), nondet]) :-
    B = e(moho_saltarin, 1),
    efectos_habilidad(tuerca, rebuscar_bolsillos, B, Efs),
    \+ ( member(E, Efs), E = ganar_queso(_, _, _) ),
    memberchk(alterar(B, rebuscado, fijo), Efs),
    memberchk(mensaje(rebuscar, [B, nada]), Efs).

test(rebuscar_sube_la_despensa_en_uno, [setup(combate_listo([bandido_torpe])), nondet]) :-
    economia:queso_total(Antes),
    efectos_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1), Efs),
    aplicar_efectos(Efs),
    economia:queso_total(Despues),
    Despues =:= Antes + 1.

test(rebuscar_dos_veces_al_mismo_no_se_puede, [setup(combate_listo([bandido_torpe])), fail]) :-
    efectos_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1), Efs),
    aplicar_efectos(Efs),
    efectos_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1), _).

test(la_marca_de_rebuscar_se_borra_al_acabar_el_combate, [setup(combate_listo([bandido_torpe])), nondet]) :-
    efectos_habilidad(tuerca, rebuscar_bolsillos, e(bandido_torpe, 1), Efs),
    aplicar_efectos(Efs),
    aplicar_efecto(terminar_combate),
    \+ estado:alterado(_, rebuscado, _).

test(la_fondue_al_aplicarse_gasta_el_queso_y_quita_vida, [setup(combate_listo([bandido_torpe])), nondet]) :-
    B = e(bandido_torpe, 1),
    efectos_habilidad(pimentina, fondue_flamigera, B, Efs),
    aplicar_efectos(Efs),
    economia:queso_total(11),
    estado:vida(B, 4).

test(sin_poder_no_hay_efectos, [setup(nueva_partida), fail]) :-
    efectos_habilidad(baldomero, balada_inspiradora, ninguno, _).

test(efectos_accion_da_lo_mismo_que_efectos_habilidad, [setup(combate_listo([bandido_torpe]))]) :-
    forall(member(Id-H-O, [baldomero-carga_heroica-e(bandido_torpe, 1),
                           pimentina-fondue_flamigera-e(bandido_torpe, 1),
                           rufino-balada_inspiradora-ninguno,
                           tuerca-rebuscar_bolsillos-e(bandido_torpe, 1)]),
           (   efectos_habilidad(Id, H, O, E1),
               efectos_accion(Id, habilidad(O), E2),
               E1 == E2
           )).

test(calcular_los_efectos_no_cambia_el_estado, [setup(combate_listo([bandido_torpe]))]) :-
    foto_estado(Antes),
    forall(member(Id-H-O, [baldomero-carga_heroica-e(bandido_torpe, 1),
                           pimentina-fondue_flamigera-e(bandido_torpe, 1),
                           rufino-balada_inspiradora-ninguno,
                           tuerca-rebuscar_bolsillos-e(bandido_torpe, 1)]),
           efectos_habilidad(Id, H, O, _)),
    foto_estado(Despues),
    Antes =@= Despues.

:- end_tests(los_efectos).

:- begin_tests(comando_habilidad).

test(es_un_comando_valido_con_o_sin_objetivo) :-
    validar_comando(habilidad, ok(habilidad)),
    validar_comando(habilidad(bandido_torpe), ok(habilidad(bandido_torpe))).

test(con_un_objetivo_sin_decir_es_un_error) :-
    validar_comando(habilidad(_), error(falta_argumento(_))).

test(con_dos_argumentos_no_se_entiende) :-
    validar_comando(habilidad(a, b), error(no_entiendo(_))).

test(solo_se_permite_en_combate) :-
    permitido(combate, habilidad),
    forall(member(Fase, [exploracion, taberna, fin]), \+ permitido(Fase, habilidad)).

test(los_comandos_del_combate_son_estos_y_no_otros) :-
    comandos_disponibles(combate, Cs),
    msort(Cs, Ordenados),
    msort([ayuda, mirar, atacar, defender, habilidad, compania, inventario, explicar, salir], Ordenados).

test(en_combate_no_se_descansa) :-
    \+ permitido(combate, descansar),
    \+ permitido(combate, ir).

test(sale_en_la_ayuda_del_combate_y_tiene_texto) :-
    comandos_disponibles(combate, Cs),
    memberchk(habilidad, Cs),
    ayuda_de(habilidad, Texto),
    contiene(Texto, 'habilidad').

test(fuera_de_combate_no_se_puede, [setup(nueva_partida)]) :-
    ordena(habilidad(bandido_torpe), [error(fuera_de_fase(_, _))]),
    ordena(habilidad, [error(fuera_de_fase(_, _))]).

test(la_carga_quita_vida_gasta_el_turno_y_cuenta_la_prueba, [setup(combate_listo([bandido_torpe, bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    ordena(habilidad(bandido_torpe), Items),
    memberchk(msg(carga_heroica, [e(bandido_torpe, 1)], _), Items),
    estado:vida(e(bandido_torpe, 1), V),
    V < 12,
    \+ ( estado:cola_turnos([baldomero|_]) ),
    estado:ultima_prueba(habilidad(baldomero, e(bandido_torpe, 1)), _).

test(la_prueba_guardada_se_hizo_antes_de_aplicar_los_efectos, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([pimentina, rufino]),
    ordena(habilidad(bandido_torpe), _),
    estado:ultima_prueba(habilidad(pimentina, B), Prueba),
    B == e(bandido_torpe, 1),
    Prueba \== [],
    prueba_a_lineas(Prueba, Lineas),
    Lineas = [_|_].

test(pimentina_paga_un_queso, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([pimentina, rufino]),
    ordena(habilidad(bandido_torpe), _),
    economia:queso_total(11),
    estado:vida(e(bandido_torpe, 1), 4).

test(tuerca_gana_un_queso, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([tuerca, rufino]),
    ordena(habilidad(bandido_torpe), Items),
    memberchk(msg(rebuscar, [e(bandido_torpe, 1), ok], _), Items),
    economia:queso_total(13).

test(rufino_canta_sin_decir_a_quien, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([rufino, baldomero]),
    ordena(habilidad, Items),
    memberchk(msg(balada, [], _), Items),
    estado:moral(baldomero, 7).

test(a_rufino_le_da_igual_el_objetivo_que_se_escriba, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([rufino, baldomero]),
    ordena(habilidad(bandido_torpe), Items),
    memberchk(msg(balada, [], _), Items).

test(baldomero_sin_objetivo_recibe_un_error_y_nada_cambia, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    foto_estado(Antes),
    ordena(habilidad, [error(habilidad_pide_objetivo(carga_heroica))]),
    foto_estado(Despues),
    Antes =@= Despues.

test(un_objetivo_que_no_existe_es_un_error_y_nada_cambia, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    foto_estado(Antes),
    ordena(habilidad(dragon), [error(objetivo_desconocido(dragon))]),
    foto_estado(Despues),
    Antes =@= Despues.

test(pimentina_sin_queso_no_puede_y_nada_cambia, [setup(combate_listo([bandido_torpe])), nondet]) :-
    sin_queso,
    cola_a([pimentina, rufino]),
    foto_estado(Antes),
    ordena(habilidad(bandido_torpe), [error(no_puede_habilidad(pimentina, fondue_flamigera))]),
    foto_estado(Despues),
    Antes =@= Despues.

test(aturdido_no_puede_usar_su_habilidad, [setup(combate_listo([bandido_torpe])), nondet]) :-
    aplicar_efecto(alterar(baldomero, aturdido, 2)),
    cola_a([baldomero, rufino]),
    ordena(habilidad(bandido_torpe), [error(no_puede_habilidad(baldomero, carga_heroica))]).

test(si_no_es_tu_turno_no_se_puede, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([e(bandido_torpe, 1), baldomero]),
    ordena(habilidad(bandido_torpe), [error(no_es_tu_turno)]),
    ordena(habilidad, [error(no_es_tu_turno)]).

test(rebuscar_dos_veces_al_mismo_enemigo_da_error, [setup(combate_listo([bandido_torpe, bandido_torpe])), nondet]) :-
    cola_a([tuerca, tuerca, rufino]),
    ordena(habilidad(bandido_torpe), _),
    cola_a([tuerca, rufino]),
    ordena(habilidad(bandido_torpe), Items),
    % el tipo se resuelve a la primera instancia viva: ya rebuscada
    Items = [error(no_puede_habilidad(tuerca, rebuscar_bolsillos))].

test(se_puede_escribir_la_instancia_en_vez_del_tipo, [setup(combate_listo([bandido_torpe, bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    ordena(habilidad(e(bandido_torpe, 2)), Items),
    memberchk(msg(carga_heroica, [e(bandido_torpe, 2)], _), Items).

:- end_tests(comando_habilidad).

:- begin_tests(pantalla_de_habilidades).

test(se_lee_la_carga, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    pantalla(habilidad(bandido_torpe), T),
    contiene(T, 'Por mi honor'), contiene(T, 'Bandido Torpe').

test(se_lee_la_fondue, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([pimentina, rufino]),
    pantalla(habilidad(bandido_torpe), T),
    contiene(T, 'Fondue Flamígera').

test(se_lee_la_balada, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([rufino, baldomero]),
    pantalla(habilidad, T),
    contiene(T, 'Balada Inspiradora').

test(se_lee_el_rebuscar_con_exito_y_sin_el, [setup(combate_listo([bandido_torpe, moho_saltarin])), nondet]) :-
    cola_a([tuerca, tuerca, rufino]),
    pantalla(habilidad(bandido_torpe), T1),
    contiene(T1, 'encuentra un queso'),
    pantalla(habilidad(moho_saltarin), T2),
    contiene(T2, 'no halla nada').

test(se_leen_los_errores, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    pantalla(habilidad, T1),
    contiene(T1, 'necesita un enemigo'),
    sin_queso,
    cola_a([pimentina, rufino]),
    pantalla(habilidad(bandido_torpe), T2),
    contiene(T2, 'Madame Pimentina no puede usar la Fondue Flamígera ahora mismo'),
    pantalla(habilidad(dragon), T3),
    contiene(T3, 'No hay nada llamado "dragon"').

test(fuera_de_combate_se_lee_el_motivo, [setup(nueva_partida), nondet]) :-
    pantalla(habilidad, T),
    contiene(T, 'atacar, defender o usar una habilidad').

test(ningun_error_ensena_terminos_crudos, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    forall(member(Cmd, [habilidad, habilidad(dragon), habilidad(rufino), habilidad(x)]),
           (   pantalla(Cmd, T),
               \+ contiene(T, 'error('),
               \+ contiene(T, 'e(bandido')
           )).

:- end_tests(pantalla_de_habilidades).

:- begin_tests(explicar_las_habilidades).

test(explicar_tras_la_habilidad_cuenta_la_regla, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    ordena(habilidad(bandido_torpe), _),
    ordena(explicar, [vista(prueba, habilidad(baldomero, B), Prueba)]),
    B == e(bandido_torpe, 1),
    prueba_a_lineas(Prueba, Lineas),
    member(L, Lineas), contiene(L, 'puede_habilidad(baldomero, carga_heroica'), !.

test(explicar_la_habilidad_por_su_nombre_usa_la_guardada, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([baldomero, rufino]),
    ordena(habilidad(bandido_torpe), _),
    ordena(explicar(habilidad(bandido_torpe)), [vista(prueba, habilidad(bandido_torpe), _)]).

test(explicar_otra_habilidad_distinta_de_la_guardada_no_usa_la_guardada, [setup(combate_listo([bandido_torpe, bandido_montado])), nondet]) :-
    cola_a([baldomero, tuerca, rufino]),
    ordena(habilidad(bandido_torpe), _),
    cola_a([baldomero, rufino]),
    ordena(explicar(habilidad(dragon)), Items),
    Items = [error(_)].

test(explicar_la_balada_sin_objetivo, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([rufino, baldomero]),
    ordena(habilidad, _),
    ordena(explicar(habilidad), [vista(prueba, habilidad, _)]).

test(explicar_en_hipotetico_la_habilidad_del_turno, [setup(combate_listo([bandido_torpe])), nondet]) :-
    cola_a([pimentina, rufino]),
    ordena(explicar(habilidad(bandido_torpe)), [vista(prueba, habilidad(bandido_torpe), Prueba)]),
    prueba_a_lineas(Prueba, Lineas),
    member(L, Lineas), contiene(L, 'hay_queso_para'), !.

test(sin_queso_explicar_en_hipotetico_no_hay_prueba, [setup(combate_listo([bandido_torpe])), nondet]) :-
    sin_queso,
    cola_a([pimentina, rufino]),
    ordena(explicar(habilidad(bandido_torpe)), [error(no_hay_prueba(habilidad(bandido_torpe)))]).

test(la_prueba_muestra_que_la_magia_pide_queso, [setup(combate_listo([bandido_torpe])), nondet]) :-
    solve(combate:puede_habilidad(pimentina, fondue_flamigera, e(bandido_torpe, 1)), Prueba),
    prueba_a_lineas(Prueba, Lineas),
    member(L, Lineas), contiene(L, 'hechizos_de_cocina'), !.

:- end_tests(explicar_las_habilidades).

:- begin_tests(en_el_bucle_de_combate).

% El bucle real: cada turno del jugador usa su habilidad si puede y, si no, ataca.
turno_de_jugador(Cmd) :-
    estado:cola_turnos([Actor|_]),
    estado:combatiente(Actor, jugador),
    mundo:habilidad_de(Actor, H),
    (   combate:objetivo_de_habilidad(H, ninguno)
    ->  Cmd = habilidad
    ;   estado:instancia(E, T), compania:vivo(E),
        combate:puede_habilidad(Actor, H, E)
    ->  Cmd = habilidad(T)
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_atacar(Actor, E)
    ->  Cmd = atacar(T)
    ;   Cmd = defender
    ).

jugar_hasta_el_final(0) :- !, fail.
jugar_hasta_el_final(N) :-
    (   estado:en_combate(_)
    ->  once(turno_de_jugador(Cmd)),
        ejecutar(Cmd, resultado(Items)),
        \+ memberchk(error(interno(_)), Items),
        N1 is N - 1,
        jugar_hasta_el_final(N1)
    ;   true
    ).

test(un_combate_entero_con_habilidades_acaba_y_se_gana, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, bandido_torpe], _),
    jugar_hasta_el_final(60),
    \+ estado:en_combate(_),
    \+ estado:fin_partida(_).

test(las_habilidades_funcionan_contra_el_jefe_y_su_moho, [setup(nueva_partida), nondet]) :-
    comenzar_combate([gran_roquefort], _),
    jugar_hasta_el_final(80),
    \+ estado:en_combate(_).

test(tras_un_combate_con_habilidades_no_quedan_marcas, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, bandido_montado], _),
    jugar_hasta_el_final(80),
    \+ estado:alterado(_, rebuscado, _).

test(la_misma_partida_da_el_mismo_resultado, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, bandido_torpe], _),
    jugar_hasta_el_final(60),
    foto_estado(F1),
    nueva_partida,
    comenzar_combate([bandido_torpe, bandido_torpe], _),
    jugar_hasta_el_final(60),
    foto_estado(F2),
    F1 =@= F2.

:- end_tests(en_el_bucle_de_combate).
