% pagos.pl (pruebas)
% Semana 2: la compania (informe, huelga), el valor del queso, el inventario, los sueldos
% con pagar, el impago al salir de la taberna y el comando explicar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/pagos -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

nueva :- nueva_partida.

cmd(Comando, Items) :- ejecutar(Comando, resultado(Items)).

foto_estado(Hechos) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), L),
    msort(L, Hechos).

% Deja la despensa como una lista de lotes q(Tipo, Edad, Cantidad).
despensa_de(Lotes) :-
    findall(q(T, E, C), estado:queso(T, E, C), Viejos),
    forall(member(q(T, E, C), Viejos), aplicar_efecto(gastar_queso(T, E, C))),
    forall(member(q(T, E, C), Lotes), aplicar_efecto(ganar_queso(T, E, C))).

% Lleva a la compania a la taberna con sueldos pendientes y N quesos (cheddar fresco).
en_taberna_con(N) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),
    despensa_de([q(cheddar, 0, N)]).

salida_de(Resultado, Texto) :-
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% ===========================================================================
:- begin_tests(compania_semana2).

test(todos_en_pie_al_empezar, [setup(nueva)]) :-
    findall(Id, compania:en_pie(Id), Ids),
    Ids == [baldomero, pimentina, rufino, tuerca].

test(un_huelguista_no_esta_en_pie_pero_sigue_activo, [setup(nueva)]) :-
    aplicar_efecto(mod_moral(rufino, -4)),                 % 6 -> 2
    compania:activo(rufino),
    \+ compania:en_pie(rufino),
    findall(Id, compania:en_pie(Id), Ids), length(Ids, 3).

test(un_caido_no_esta_en_pie_ni_activo, [setup(nueva)]) :-
    aplicar_efecto(dano(tuerca, 999)),
    \+ compania:activo(tuerca),
    \+ compania:en_pie(tuerca),
    compania:miembro(tuerca).

test(los_sueldos_del_catalogo, [setup(nueva)]) :-
    compania:sueldo_de(baldomero, 1),
    compania:sueldo_de(pimentina, 2),
    compania:sueldo_de(rufino, 1),
    compania:sueldo_de(tuerca, 1).

test(el_informe_tiene_una_ficha_por_miembro, [setup(nueva)]) :-
    compania:informe(Filas),
    length(Filas, 4),
    Filas = [miembro(baldomero, 'Sir Baldomero', caballero, 30, 30, 11, 3, 6, frente, teme_caballos, 1, en_pie)|_].

test(el_informe_distingue_huelga_y_caidos, [setup(nueva), nondet]) :-
    aplicar_efecto(mod_moral(rufino, -4)),
    aplicar_efecto(dano(tuerca, 999)),
    compania:informe(Filas),
    member(miembro(rufino, _, _, _, _, _, _, 2, _, _, _, huelga), Filas),
    member(miembro(tuerca, _, _, 0, _, _, _, _, _, _, _, caido), Filas),
    member(miembro(baldomero, _, _, _, _, _, _, _, _, _, _, en_pie), Filas).

:- end_tests(compania_semana2).

% ===========================================================================
:- begin_tests(valor_e_inventario).

test(valor_segun_la_categoria, [nondet]) :-
    economia:valor_queso(cheddar, 0, 2),      % fresco: el valor base
    economia:valor_queso(cheddar, 2, 2),
    economia:valor_queso(cheddar, 3, 4),      % curado: base + 2
    economia:valor_queso(cheddar, 9, 4),
    economia:valor_queso(cheddar, 10, 1),     % rancio: 1
    economia:valor_queso(brie, 0, 3),
    economia:valor_queso(brie, 5, 5),
    economia:valor_queso(brie, 12, 1).

test(lo_rancio_nunca_vale_mas_que_lo_fresco) :-
    forall(( mundo:tipo_queso(T, _), between(10, 30, E) ),
           (   economia:valor_queso(T, 0, Fresco),
               economia:valor_queso(T, E, Rancio),
               Rancio =< Fresco
           )).

test(un_tipo_desconocido_no_tiene_valor, [fail]) :-
    economia:valor_queso(queso_inexistente, 0, _).

test(valor_de_la_despensa_inicial, [setup(nueva)]) :-
    economia:valor_despensa(24).                           % 12 cheddar frescos x 2

test(valor_de_una_despensa_mezclada, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 2), q(brie, 4, 1), q(cheddar, 12, 3)]),
    economia:valor_despensa(V),
    V =:= 2*2 + 1*5 + 3*1.

test(inventario_inicial, [setup(nueva)]) :-
    economia:inventario(Datos),
    Datos == [dia(1), total(12), valor(24), lotes([lote(cheddar, 0, 12, fresco)]), objetos([])].

test(inventario_ordena_los_lotes_en_orden_de_racion, [setup(nueva)]) :-
    despensa_de([q(cheddar, 12, 1), q(cheddar, 0, 1), q(brie, 5, 1)]),
    economia:inventario(Datos),
    memberchk(lotes(Lotes), Datos),
    Lotes == [lote(cheddar, 0, 1, fresco), lote(brie, 5, 1, curado), lote(cheddar, 12, 1, rancio)].

test(inventario_muestra_los_objetos, [setup(nueva)]) :-
    aplicar_efecto(ganar_objeto(compania, pocion, 2)),
    economia:inventario(Datos),
    memberchk(objetos(Os), Datos),
    Os == [pocion-2].

test(el_comando_inventario_no_cambia_nada, [setup(nueva)]) :-
    foto_estado(Antes),
    cmd(inventario, [vista(inventario, _)]),
    cmd(compania, [vista(compania, _)]),
    foto_estado(Despues),
    Antes =@= Despues.

:- end_tests(valor_e_inventario).

% ===========================================================================
:- begin_tests(sueldos).

test(el_total_de_sueldos_son_cinco, [setup(nueva)]) :-
    economia:total_sueldos(5).

test(un_caido_no_cobra, [setup(nueva)]) :-
    aplicar_efecto(dano(rufino, 999)),
    economia:total_sueldos(4).

test(al_empezar_no_se_debe_nada, [setup(nueva), fail]) :-
    economia:puede_pagar_sueldos.

test(con_sueldos_pendientes_y_queso_se_puede_pagar, [setup(nueva)]) :-
    en_taberna_con(5),
    economia:puede_pagar_sueldos.

test(sin_queso_suficiente_no_se_paga_a_medias, [setup(nueva), fail]) :-
    en_taberna_con(4),
    economia:puede_pagar_sueldos.

test(los_efectos_marcan_y_gastan_cinco_quesos, [setup(nueva)]) :-
    en_taberna_con(8),
    economia:efectos_sueldos(Es),
    Es = [marcar(sueldos_pagados), mensaje(pago, [5])|Gastos],
    length(Gastos, 5),
    forall(member(G, Gastos), G = gastar_queso(cheddar, 0, 1)).

test(se_paga_con_lo_mas_rancio_primero, [setup(nueva)]) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),
    despensa_de([q(cheddar, 0, 3), q(brie, 4, 2), q(cheddar, 12, 2)]),
    economia:efectos_sueldos([_, _|Gastos]),
    Gastos == [gastar_queso(cheddar, 12, 1), gastar_queso(cheddar, 12, 1),
               gastar_queso(brie, 4, 1), gastar_queso(brie, 4, 1),
               gastar_queso(cheddar, 0, 1)].

test(aplicar_los_efectos_de_pago_deja_la_despensa_correcta, [setup(nueva)]) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),
    despensa_de([q(cheddar, 0, 3), q(brie, 4, 2), q(cheddar, 12, 2)]),
    economia:efectos_sueldos(Es),
    aplicar_efectos(Es),
    findall(T/E/C, estado:queso(T, E, C), Lotes), msort(Lotes, Orden),
    Orden == [cheddar/0/2],                                % se pagaron los 2 rancios, los 2 brie y 1 fresco
    marca(sueldos_pagados).

:- end_tests(sueldos).

% ===========================================================================
:- begin_tests(comando_pagar).

test(pagar_al_empezar_no_hace_falta, [setup(nueva)]) :-
    foto_estado(Antes),
    cmd(pagar, Items),
    Items == [error(nada_que_pagar)],
    foto_estado(Despues),
    Antes =@= Despues.

test(pagar_tras_volver_a_la_taberna, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    \+ marca(sueldos_pagados),                             % llegar trae sueldos pendientes
    economia:queso_total(Antes),
    cmd(pagar, Items),
    marca(sueldos_pagados),
    economia:queso_total(Despues),
    Despues =:= Antes - 5,
    memberchk(msg(pago, [5], 0), Items).

test(no_se_paga_dos_veces, [setup(nueva)]) :-
    en_taberna_con(30),
    cmd(pagar, I1), cmd(pagar, I2),
    \+ memberchk(error(_), I1),
    I2 == [error(nada_que_pagar)],
    economia:queso_total(25).

test(sin_queso_pagar_da_error_y_no_cambia_nada, [setup(nueva)]) :-
    en_taberna_con(4),
    foto_estado(Antes),
    cmd(pagar, Items),
    Items == [error(no_puede_pagar)],
    foto_estado(Despues),
    Antes =@= Despues.

test(pagar_fuera_de_la_taberna_no_esta_permitido, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _),
    cmd(pagar, Items),
    Items == [error(fuera_de_fase(pagar, exploracion))].

test(el_pago_guarda_su_prueba, [setup(nueva)]) :-
    en_taberna_con(8),
    cmd(pagar, _),
    ultima_prueba(pagar, Prueba),
    Prueba = regla(puede_pagar_sueldos, 1, _).

:- end_tests(comando_pagar).

% ===========================================================================
:- begin_tests(impago).

test(salir_al_empezar_no_cuesta_moral, [setup(nueva)]) :-
    cmd(ir(aldea), Items),
    \+ memberchk(msg(impago, _, _), Items),
    forall(moral(_, M), M == 6).

test(salir_sin_pagar_cuesta_dos_de_moral_a_cada_uno, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    cmd(ir(aldea), Items),
    memberchk(msg(impago, [], 0), Items),
    forall(moral(_, M), M == 4).

test(salir_tras_pagar_no_cuesta_nada, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _), cmd(pagar, _),
    cmd(ir(aldea), Items),
    \+ memberchk(msg(impago, _, _), Items),
    forall(moral(_, M), M == 6).

test(el_impago_solo_castiga_a_los_activos, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    aplicar_efecto(dano(tuerca, 999)),
    cmd(ir(aldea), _),
    moral(tuerca, 6),
    moral(baldomero, 4).

test(tres_impagos_llevan_a_la_huelga, [setup(nueva), nondet]) :-
    despensa_de([q(cheddar, 0, 100)]),
    cmd(ir(aldea), _),
    forall(between(1, 2, _), ( cmd(ir(taberna), _), cmd(ir(aldea), _) )),
    moral(baldomero, 2),
    compania:esta_en_huelga(baldomero),
    compania:informe(Filas),
    member(miembro(baldomero, _, _, _, _, _, _, _, _, _, _, huelga), Filas).

test(un_error_de_viaje_no_castiga, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 40)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    cmd(ir(castillo), Items),                              % desde la taberna no hay camino al castillo
    Items == [error(no_puede_viajar(castillo))],
    forall(moral(_, M), M == 6).

:- end_tests(impago).

% ===========================================================================
:- begin_tests(comando_explicar).

test(al_empezar_no_hay_nada_que_explicar, [setup(nueva)]) :-
    cmd(explicar, Items),
    Items == [error(nada_que_explicar)].

test(explicar_muestra_la_prueba_de_lo_ultimo, [setup(nueva)]) :-
    cmd(ir(aldea), _),
    cmd(explicar, [vista(prueba, Accion, Prueba)]),
    Accion == ir(aldea),
    Prueba = regla(puede_viajar(aldea), 1, _).

test(la_prueba_guardada_es_la_de_antes_de_cambiar_el_estado, [setup(nueva)]) :-
    % ya no se esta en la taberna, pero la prueba dice que se salio de ella
    cmd(ir(aldea), _),
    cmd(explicar(ir(aldea)), [vista(prueba, ir(aldea), Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('   [ok] en_zona(taberna)   [hecho]', Lineas).

test(explicar_una_accion_posible_la_resuelve_ahora, [setup(nueva)]) :-
    cmd(explicar(ir(camino_real)), [vista(prueba, ir(camino_real), Prueba)]),
    Prueba = regla(puede_viajar(camino_real), 1, _),
    \+ ultima_prueba(_, _).                                % explicar en hipotetico no guarda nada

test(explicar_descansar_en_la_taberna, [setup(nueva)]) :-
    cmd(explicar(descansar), [vista(prueba, descansar, Prueba)]),
    Prueba = regla(puede_descansar, 1, _).

test(explicar_pagar_con_sueldos_pendientes, [setup(nueva)]) :-
    en_taberna_con(8),
    cmd(explicar(pagar), [vista(prueba, pagar, Prueba)]),
    Prueba = regla(puede_pagar_sueldos, 1, _).

test(una_accion_imposible_no_tiene_prueba, [setup(nueva)]) :-
    cmd(explicar(ir(castillo)), Items),
    Items == [error(no_hay_prueba(ir(castillo)))].

test(una_accion_desconocida_no_se_explica, [setup(nueva)]) :-
    cmd(explicar(volar), Items),
    Items == [error(no_se_explica(volar))].

test(explicar_con_variable_pide_el_argumento, [setup(nueva)]) :-
    cmd(explicar(ir(_)), Items),
    Items = [error(falta_argumento(_))].

test(explicar_no_cambia_el_estado, [setup(nueva)]) :-
    cmd(ir(aldea), _),
    foto_estado(Antes),
    cmd(explicar, _), cmd(explicar(descansar), _), cmd(explicar(ir(taberna)), _),
    foto_estado(Despues),
    Antes =@= Despues.

test(solo_se_guarda_la_ultima_prueba, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 30)]),
    cmd(ir(aldea), _), cmd(ir(taberna), _),
    findall(A, ultima_prueba(A, _), As),
    As == [ir(taberna)].

test(explicar_funciona_con_la_partida_terminada, [setup(nueva)]) :-
    despensa_de([q(cheddar, 0, 4)]),
    cmd(ir(aldea), _),                                     % se acaba el queso: fin por hambre
    once(estado:fase(fin)),
    cmd(explicar, [vista(prueba, ir(aldea), _)]).

test(ui_muestra_el_arbol, [setup(nueva)]) :-
    cmd(ir(aldea), _),
    cmd(explicar, Items),
    salida_de(resultado(Items), Salida),
    contiene(Salida, 'Por qué se pudo ir(aldea)'),
    contiene(Salida, '[ok] puede_viajar(aldea)   [clausula 1]'),
    contiene(Salida, '[ok] adyacente(taberna, aldea)'),
    contiene(Salida, '[no demostrable]').

test(ui_muestra_la_compania_y_el_inventario, [setup(nueva)]) :-
    cmd(compania, C), cmd(inventario, I),
    salida_de(resultado(C), SC), salida_de(resultado(I), SI),
    contiene(SC, 'Sir Baldomero (caballero)'),
    contiene(SC, 'moral 6/10'),
    contiene(SC, '[en_pie]'),
    contiene(SI, 'Despensa (día 1): 12 quesos'),
    contiene(SI, 'cheddar x12   edad 0 (fresco)'),
    contiene(SI, 'Objetos: ninguno').

:- end_tests(comando_explicar).
