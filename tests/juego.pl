% juego.pl (pruebas)
% Pruebas de compania, economia, juego (ejecutar/2), ui y main: el esqueleto jugable
% de exploracion (ir, descansar, mirar, ayuda, salir).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/juego -g "run_tests,halt" -t "halt(1)"

% Este archivo tiene tildes (nombres de zonas): se lee como UTF-8.
:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(time)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').

% Los dos primeros argumentos siempre empiezan de una partida nueva.
nueva :- nueva_partida.

% Todo el estado, como lista ordenada de hechos, para comparar "antes" y "despues".
foto_estado(Hechos) :-
    findall(H, ( estado:persistente(N/A), functor(H, N, A), call(H) ), L0),
    findall(H, ( estado:transitorio(N/A), functor(H, N, A), call(H) ), L1),
    append(L0, L1, L),
    msort(L, Hechos).

% Deja solo Cantidad quesos cheddar de edad 0 en la despensa.
despensa_con(Cantidad) :-
    findall(q(T, E, C), estado:queso(T, E, C), Lotes),
    forall(member(q(T, E, C), Lotes), aplicar_efecto(gastar_queso(T, E, C))),
    (   Cantidad > 0 -> aplicar_efecto(ganar_queso(cheddar, 0, Cantidad)) ; true ).

% Ejecuta un comando y devuelve solo sus items.
cmd(Comando, Items) :- ejecutar(Comando, resultado(Items)).

% Lo que imprime ui:mostrar/1 para un resultado.
salida_de(Resultado, Texto) :-
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% Escribe Texto en un archivo temporal y devuelve su ruta.
archivo_con(Texto, Archivo) :-
    tmp_file(entrada, Archivo),
    open(Archivo, write, S),
    format(S, "~w", [Texto]),
    close(S).

% Juega una sesion guionizada por la entrada y devuelve todo lo impreso.
jugar(Guion, Salida) :-
    archivo_con(Guion, Archivo),
    see(Archivo),
    call_with_time_limit(15, with_output_to(atom(Salida), main:main)),
    seen.

% ===========================================================================
:- begin_tests(compania).

test(los_cuatro_miembros_estan_activos, [setup(nueva)]) :-
    findall(Id, compania:activo(Id), Ids),
    Ids == [baldomero, pimentina, rufino, tuerca].

test(un_miembro_sin_vida_no_esta_activo, [setup(nueva)]) :-
    aplicar_efecto(dano(rufino, 999)),
    \+ compania:activo(rufino),
    compania:miembro(rufino),
    findall(Id, compania:activo(Id), Ids), length(Ids, 3).

test(huelga_con_moral_dos_o_menos, [setup(nueva)]) :-
    aplicar_efecto(mod_moral(tuerca, -4)),                  % 6 -> 2
    compania:esta_en_huelga(tuerca),
    \+ compania:esta_en_huelga(rufino).

test(sin_huelga_con_moral_tres, [setup(nueva), fail]) :-
    aplicar_efecto(mod_moral(tuerca, -3)),                  % 6 -> 3
    compania:esta_en_huelga(tuerca).

test(se_puede_viajar_a_una_zona_conectada, [setup(nueva), nondet]) :-
    compania:puede_viajar(aldea),
    compania:puede_viajar(camino_real).

test(no_se_puede_viajar_a_una_zona_lejana, [setup(nueva), fail]) :-
    compania:puede_viajar(castillo).

test(no_se_puede_viajar_a_la_zona_actual, [setup(nueva), fail]) :-
    compania:puede_viajar(taberna).

test(no_se_puede_viajar_si_la_partida_ha_terminado, [setup(nueva), fail]) :-
    aplicar_efecto(fin(victoria)),
    compania:puede_viajar(aldea).

:- end_tests(compania).

% ===========================================================================
:- begin_tests(economia).

test(categorias_en_las_fronteras, [nondet]) :-
    economia:categoria_queso(0, fresco),
    economia:categoria_queso(2, fresco),
    economia:categoria_queso(3, curado),
    economia:categoria_queso(9, curado),
    economia:categoria_queso(10, rancio),
    economia:categoria_queso(40, rancio).

test(cada_edad_cae_en_una_sola_categoria) :-
    forall(between(0, 30, Edad),
           (   findall(C, economia:categoria_queso(Edad, C), Cs),
               length(Cs, 1)
           )).

test(queso_total_suma_unidades, [setup(nueva)]) :-
    economia:queso_total(12),
    aplicar_efecto(ganar_queso(brie, 4, 3)),
    economia:queso_total(15).

test(hay_queso_para, [setup(nueva)]) :-
    economia:hay_queso_para(12),
    \+ economia:hay_queso_para(13).

test(la_despensa_va_en_orden_de_racion, [setup(nueva)]) :-
    despensa_con(0),
    aplicar_efectos([ganar_queso(cheddar, 10, 2), ganar_queso(cheddar, 3, 1),
                     ganar_queso(brie, 5, 1), ganar_queso(cheddar, 0, 1)]),
    economia:despensa(D),
    % fresco; luego curado, el mas viejo primero (brie de 5 antes que cheddar de 3); al final lo rancio
    D == [q(cheddar, 0, 1), q(brie, 5, 1), q(cheddar, 3, 1), q(cheddar, 10, 2)].

test(la_racion_come_en_orden_y_penaliza_lo_rancio, [setup(nueva)]) :-
    despensa_con(0),
    aplicar_efectos([ganar_queso(cheddar, 10, 2), ganar_queso(cheddar, 3, 1),
                     ganar_queso(brie, 5, 1), ganar_queso(cheddar, 0, 1)]),
    economia:efectos_racion(Es),
    Es == [gastar_queso(cheddar, 0, 1),
           gastar_queso(brie, 5, 1),
           gastar_queso(cheddar, 3, 1),
           gastar_queso(cheddar, 10, 1), mod_moral(tuerca, -2), mensaje(come_rancio, [tuerca])].

test(la_racion_gasta_lo_que_hay_y_se_puede_aplicar, [setup(nueva)]) :-
    economia:efectos_racion(Es),
    aplicar_efectos(Es),
    economia:queso_total(8),
    findall(M, moral(_, M), Ms),
    Ms == [6, 6, 6, 6].

test(efectos_racion_es_determinista, [setup(nueva)]) :-
    % Si dejara una eleccion abierta, plunit avisaria; aqui se comprueba de forma explicita.
    findall(Es, economia:efectos_racion(Es), Soluciones),
    length(Soluciones, 1).

test(sin_queso_hay_hambre_pero_nadie_baja_de_uno, [setup(nueva)]) :-
    despensa_con(0),
    aplicar_efecto(dano(rufino, 19)),                       % 20 -> 1
    economia:efectos_racion(Es),
    memberchk(mensaje(sin_comida, [baldomero]), Es),
    memberchk(dano(baldomero, 2), Es),
    memberchk(mod_moral(rufino, -1), Es),
    \+ memberchk(dano(rufino, _), Es),                      % ya tiene 1 de vida: el hambre no la toca
    aplicar_efectos(Es),
    vida(rufino, 1),
    vida(baldomero, 28).

test(con_poco_queso_los_primeros_comen_y_los_ultimos_pasan_hambre, [setup(nueva)]) :-
    despensa_con(2),
    economia:efectos_racion(Es),
    memberchk(gastar_queso(cheddar, 0, 1), Es),
    memberchk(mensaje(sin_comida, [rufino]), Es),
    memberchk(mensaje(sin_comida, [tuerca]), Es),
    \+ memberchk(mensaje(sin_comida, [baldomero]), Es),
    \+ memberchk(mensaje(sin_comida, [pimentina]), Es).

test(puede_descansar_en_la_taberna_con_dos_quesos, [setup(nueva)]) :-
    economia:puede_descansar,
    despensa_con(2),
    economia:puede_descansar.

test(no_puede_descansar_con_un_queso, [setup(nueva), fail]) :-
    despensa_con(1),
    economia:puede_descansar.

test(no_puede_descansar_fuera_de_la_taberna, [setup(nueva), fail]) :-
    aplicar_efecto(viajar(aldea)),
    economia:puede_descansar.

test(efectos_de_descanso, [setup(nueva)]) :-
    economia:efectos_descanso(Es),
    Es = [mensaje(descanso, [])|Resto],
    Resto = [gastar_queso(cheddar, 0, 1), gastar_queso(cheddar, 0, 1)|Cuidados],
    memberchk(curar(baldomero, 30), Cuidados),
    memberchk(curar(tuerca, 22), Cuidados),
    memberchk(mod_moral(pimentina, 1), Cuidados),
    length(Cuidados, 8).

:- end_tests(economia).

% ===========================================================================
:- begin_tests(juego_validar).

test(un_comando_conocido_es_valido) :-
    validar_comando(ir(aldea), ok(ir(aldea))),
    validar_comando(mirar, ok(mirar)),
    validar_comando(descansar, ok(descansar)),
    validar_comando(ayuda, ok(ayuda)),
    validar_comando(salir, ok(salir)).

test(el_fin_de_la_entrada_equivale_a_salir) :-
    validar_comando(end_of_file, ok(salir)).

test(un_error_de_sintaxis_se_reporta) :-
    validar_comando('$error_sintaxis', error(sintaxis)).

test(una_variable_no_es_un_comando) :-
    validar_comando(_, error(comando_vacio)).

test(un_comando_desconocido_no_se_entiende) :-
    validar_comando(bailar, error(no_entiendo(bailar))).

test(la_aridad_importa) :-
    validar_comando(ir, error(no_entiendo(ir))),
    validar_comando(ir(a, b), error(no_entiendo(ir(a, b)))),
    validar_comando(mirar(algo), error(no_entiendo(mirar(algo)))).

test(un_numero_no_es_un_comando) :-
    validar_comando(3, error(no_entiendo(3))).

test(un_comando_con_variable_sin_ligar_pide_el_argumento) :-
    validar_comando(ir(_), error(falta_argumento(ir(_)))).

test(cada_fase_permite_sus_comandos) :-
    comandos_disponibles(exploracion, E), \+ memberchk(descansar, E), memberchk(ir, E),
    comandos_disponibles(taberna, T),     memberchk(descansar, T),    memberchk(ir, T),
    comandos_disponibles(fin, F),         F == [ayuda, explicar, salir].

:- end_tests(juego_validar).

% ===========================================================================
:- begin_tests(fase).

test(la_partida_empieza_en_la_taberna, [setup(nueva)]) :-
    once(estado:fase(taberna)).

test(fuera_de_la_taberna_es_exploracion, [setup(nueva)]) :-
    aplicar_efecto(viajar(aldea)),
    once(estado:fase(exploracion)).

test(con_el_fin_marcado_la_fase_es_fin, [setup(nueva)]) :-
    aplicar_efecto(fin(victoria)),
    once(estado:fase(fin)).

test(la_fase_es_unica, [setup(nueva)]) :-
    findall(F, estado:fase(F), Fs),
    Fs == [taberna].

:- end_tests(fase).

% ===========================================================================
:- begin_tests(juego_ir).

test(ir_a_la_aldea_gasta_un_dia_y_la_racion, [setup(nueva)]) :-
    cmd(ir(aldea), Items),
    en_zona(aldea),
    dia(2),
    economia:queso_total(8),
    queso(cheddar, 1, 8),                                   % el queso ha madurado un dia
    memberchk(msg(llegada, [aldea], 0), Items).

test(ir_dos_veces_hace_madurar_el_queso, [setup(nueva)]) :-
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    en_zona(taberna), dia(3),
    queso(cheddar, 2, 4).

test(se_puede_recorrer_el_mapa, [setup(nueva)]) :-
    despensa_con(40),
    forall(member(Z, [camino_real, castillo, camino_real, cuevas, camino_real, bosque, aldea, taberna]),
           (   cmd(ir(Z), Items),
               \+ memberchk(error(_), Items),
               en_zona(Z)
           )),
    dia(9).

test(ir_a_una_zona_sin_conexion_da_error_y_no_cambia_nada, [setup(nueva)]) :-
    foto_estado(Antes),
    cmd(ir(castillo), Items),
    Items == [error(no_puede_viajar(castillo))],
    foto_estado(Despues),
    Antes =@= Despues.

test(ir_a_una_zona_inexistente_da_error, [setup(nueva)]) :-
    cmd(ir(luna), Items),
    Items == [error(no_puede_viajar(luna))],
    en_zona(taberna), dia(1).

test(ir_a_la_zona_actual_da_error, [setup(nueva)]) :-
    cmd(ir(taberna), Items),
    Items == [error(no_puede_viajar(taberna))].

test(ir_con_un_argumento_raro_no_rompe, [setup(nueva)]) :-
    cmd(ir(1), Items),
    Items == [error(no_puede_viajar(1))],
    % ir(X) con X sin ligar NO debe elegir una zona por su cuenta ni viajar.
    cmd(ir(_), Items2),
    Items2 = [error(falta_argumento(ir(_)))],
    en_zona(taberna), dia(1).

test(se_pasa_hambre_si_el_queso_no_llega, [setup(nueva)]) :-
    despensa_con(3),
    cmd(ir(aldea), Items),
    memberchk(msg(sin_comida, [tuerca], 0), Items),
    memberchk(msg(llegada, [aldea], 0), Items).

test(sin_queso_la_partida_termina_por_hambre, [setup(nueva)]) :-
    despensa_con(4),
    cmd(ir(aldea), Items),
    economia:queso_total(0),
    fin_partida(derrota(derrota_hambre)),
    once(estado:fase(fin)),
    memberchk(msg(fin_hambre, [], 0), Items).

test(con_la_partida_terminada_no_se_puede_ir, [setup(nueva)]) :-
    despensa_con(4),
    cmd(ir(aldea), _),
    cmd(ir(taberna), Items),
    Items == [error(fuera_de_fase(ir(taberna), fin))].

:- end_tests(juego_ir).

% ===========================================================================
:- begin_tests(juego_descansar).

test(descansar_cura_sube_la_moral_y_pasa_un_dia, [setup(nueva)]) :-
    aplicar_efecto(dano(baldomero, 12)),
    cmd(descansar, Items),
    vida(baldomero, 30),
    forall(moral(_, M), M == 7),
    dia(2),
    memberchk(msg(descanso, [], 0), Items),
    en_zona(taberna).

test(descansar_cuesta_dos_quesos_mas_la_racion, [setup(nueva)]) :-
    cmd(descansar, _),
    economia:queso_total(6).                                % 12 - 2 de descanso - 4 de racion

test(descansar_fuera_de_la_taberna_no_esta_permitido, [setup(nueva)]) :-
    cmd(ir(aldea), _),
    foto_estado(Antes),
    cmd(descansar, Items),
    Items == [error(fuera_de_fase(descansar, exploracion))],
    foto_estado(Despues),
    Antes =@= Despues.

test(descansar_sin_quesos_da_error_y_no_cambia_nada, [setup(nueva)]) :-
    despensa_con(1),
    foto_estado(Antes),
    cmd(descansar, Items),
    Items == [error(no_puede_descansar)],
    foto_estado(Despues),
    Antes =@= Despues.

test(el_contador_de_uso_de_un_mensaje_aumenta, [setup(nueva)]) :-
    despensa_con(30),
    cmd(descansar, I1), cmd(descansar, I2),
    memberchk(msg(descanso, [], 0), I1),
    memberchk(msg(descanso, [], 1), I2).

:- end_tests(juego_descansar).

% ===========================================================================
:- begin_tests(juego_mirar_ayuda_salir).

test(mirar_describe_la_zona_sin_cambiar_nada, [setup(nueva)]) :-
    foto_estado(Antes),
    cmd(mirar, Items),
    Items = [vista(zona, Datos)],
    memberchk(nombre('Taberna del Cuajo Torcido'), Datos),
    memberchk(salidas([aldea-'Aldea Requesón', camino_real-'Camino Real']), Datos),
    memberchk(dia(1), Datos),
    memberchk(queso(12), Datos),
    memberchk(descripcion(D), Datos), atom(D),
    foto_estado(Despues),
    Antes =@= Despues.

test(mirar_en_otra_zona, [setup(nueva)]) :-
    cmd(ir(camino_real), _),
    cmd(mirar, [vista(zona, Datos)]),
    memberchk(nombre('Camino Real'), Datos),
    memberchk(salidas(S), Datos),
    findall(Id, member(Id-_, S), Ids),
    Ids == [bosque, castillo, cuevas, taberna].

test(la_ayuda_depende_de_la_fase, [setup(nueva)]) :-
    cmd(ayuda, [vista(ayuda, EnTaberna)]),
    memberchk(descansar, EnTaberna),
    cmd(ir(aldea), _),
    cmd(ayuda, [vista(ayuda, EnAldea)]),
    \+ memberchk(descansar, EnAldea),
    memberchk(ir, EnAldea).

test(salir_devuelve_salir, [setup(nueva)]) :-
    cmd(salir, Items),
    Items == [salir].

test(mirar_no_esta_permitido_al_terminar, [setup(nueva)]) :-
    aplicar_efecto(fin(victoria)),
    cmd(mirar, Items),
    Items == [error(fuera_de_fase(mirar, fin))].

:- end_tests(juego_mirar_ayuda_salir).

% ===========================================================================
:- begin_tests(juego_ejecutar_nunca_falla).

test(un_termino_que_no_es_comando, [setup(nueva)]) :-
    ejecutar(bailar, resultado([error(no_entiendo(bailar))])),
    ejecutar(42, resultado([error(no_entiendo(42))])),
    ejecutar(_, resultado([error(no_entiendo(_))])).

test(un_error_dentro_de_la_ejecucion_no_escapa, [setup(nueva)]) :-
    % Hechos corruptos a proposito: el nombre de la zona actual no existe en el mundo.
    retractall(estado:en_zona(_)),
    assertz(estado:en_zona(zona_rota)),
    ejecutar(mirar, Resultado),
    Resultado = resultado([error(_)]).

:- end_tests(juego_ejecutar_nunca_falla).

% ===========================================================================
:- begin_tests(ui).

test(un_error_se_muestra_como_texto, [setup(nueva)]) :-
    salida_de(resultado([error(no_puede_viajar(castillo))]), Salida),
    contiene(Salida, 'no hay camino directo').

test(una_zona_desconocida_se_dice, [setup(nueva)]) :-
    salida_de(resultado([error(no_puede_viajar(luna))]), Salida),
    contiene(Salida, 'No conozco').

test(mirar_muestra_nombre_salidas_y_queso, [setup(nueva)]) :-
    cmd(mirar, Items),
    salida_de(resultado(Items), Salida),
    contiene(Salida, 'Taberna del Cuajo Torcido'),
    contiene(Salida, 'aldea (Aldea Reques'),
    contiene(Salida, 'Queso en la despensa: 12').

test(la_ayuda_lista_los_comandos, [setup(nueva)]) :-
    cmd(ayuda, Items),
    salida_de(resultado(Items), Salida),
    contiene(Salida, 'ir(Zona).'),
    contiene(Salida, 'descansar.').

test(una_entrada_enorme_no_inunda_la_consola, [setup(nueva)]) :-
    length(Cs, 5000), maplist(=(0'a), Cs), atom_codes(Enorme, Cs),
    salida_de(resultado([error(no_puede_viajar(Enorme))]), S1),
    salida_de(resultado([error(no_entiendo(Enorme))]), S2),
    atom_length(S1, L1), atom_length(S2, L2),
    L1 < 150, L2 < 150,
    contiene(S1, '...'), contiene(S2, '...').

test(una_zona_entre_comillas_dobles_se_muestra_como_texto, [setup(nueva)]) :-
    % Prolog 5.10.4 lee "aldea" como lista de codigos: el jugador debe ver aldea, no [97,108,...]
    salida_de(resultado([error(no_puede_viajar("luna"))]), S),
    contiene(S, 'luna'),
    \+ contiene(S, '[97').

test(un_item_desconocido_se_muestra_sin_fallar) :-
    salida_de(resultado([algo_raro(1)]), Salida),
    contiene(Salida, 'algo_raro').

test(leer_terminos_de_la_entrada) :-
    archivo_con('ir(aldea).\nir(\nsalir.\n', Archivo),
    see(Archivo),
    ui:leer_termino(T1, _),
    ui:leer_termino(T2, _),
    ui:leer_termino(T3, _),
    seen,
    T1 == ir(aldea),
    T2 == '$error_sintaxis',                % "ir(\nsalir." esta mal formado y se descarta hasta el punto
    T3 == end_of_file.

:- end_tests(ui).

% ===========================================================================
:- begin_tests(main).

test(una_sesion_completa_de_principio_a_fin) :-
    jugar('mirar.\nir(aldea).\nir(taberna).\nsalir.\n', Salida),
    contiene(Salida, 'BANDA CHAPUZA'),
    contiene(Salida, 'Aldea Requesón: casitas blancas'),
    contiene(Salida, 'Llegas al Cuajo Torcido'),
    contiene(Salida, 'Hasta la pr').

test(el_juego_termina_al_acabarse_la_entrada) :-
    jugar('mirar.\n', Salida),
    contiene(Salida, 'Hasta la pr').

test(una_entrada_vacia_tampoco_cuelga) :-
    jugar('', Salida),
    contiene(Salida, 'BANDA CHAPUZA').

test(los_errores_no_tumban_la_sesion) :-
    jugar('ir(castillo).\nbailar.\nir(\nmirar.\nir(luna).\nsalir.\n', Salida),
    contiene(Salida, 'no hay camino directo'),
    contiene(Salida, 'No entiendo'),
    contiene(Salida, 'bien escrito'),
    contiene(Salida, 'No conozco'),
    contiene(Salida, 'Hasta la pr').

test(la_partida_acaba_por_hambre_y_la_sesion_sigue_respondiendo) :-
    jugar('ir(aldea).\nir(taberna).\ndescansar.\nir(aldea).\nayuda.\nsalir.\n', Salida),
    contiene(Salida, 'Fin de la partida'),
    contiene(Salida, 'La partida ha terminado'),
    contiene(Salida, 'Comandos disponibles').

:- end_tests(main).
