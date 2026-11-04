% mundo_estado.pl
% Pruebas de src/mundo.pl (datos del mundo) y src/estado.pl (estado y efectos).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/mundo_estado -g "run_tests,halt" -t "halt(1)"

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').

% Alcanzables desde Origen siguiendo adyacente/2 (cierre transitivo, sin ciclos).
alcanzables(Origen, Zonas) :- alcanzables_([Origen], [Origen], Zonas).
alcanzables_([], Vistas, Vistas).
alcanzables_([Z|Pend], Vistas, Zonas) :-
    findall(V, ( adyacente(Z, V), \+ memberchk(V, Vistas) ), Nuevas0),
    sort(Nuevas0, Nuevas),
    append(Vistas, Nuevas, Vistas1),
    append(Pend, Nuevas, Pend1),
    alcanzables_(Pend1, Vistas1, Zonas).

% Todos los hechos dinamicos declarados dentro del modulo estado.
dinamicos_de_estado(Lista) :-
    findall(N/A,
            (   current_predicate(estado:N/A),
                functor(H, N, A),
                predicate_property(estado:H, dynamic)
            ),
            L0),
    sort(L0, Lista).

registrado(N/A) :- estado:persistente(N/A).
registrado(N/A) :- estado:transitorio(N/A).

:- begin_tests(mundo).

test(hay_seis_zonas) :-
    findall(Z, zona(Z, _), Zs),
    msort(Zs, Ordenadas),
    Ordenadas == [aldea, bosque, camino_real, castillo, cuevas, taberna].

test(cada_zona_tiene_descripcion) :-
    forall(zona(Z, _), descripcion_zona(Z, _)).

test(las_conexiones_apuntan_a_zonas_que_existen) :-
    forall(conexion(A, B), ( zona(A, _), zona(B, _) )).

test(adyacente_es_simetrica) :-
    forall(adyacente(A, B), adyacente(B, A)).

test(adyacente_no_inventa_conexiones, [fail]) :-
    adyacente(taberna, castillo).

test(el_camino_real_conecta_con_cuatro_zonas) :-
    findall(V, adyacente(camino_real, V), Vs),
    msort(Vs, Ordenadas),
    Ordenadas == [bosque, castillo, cuevas, taberna].

test(todo_el_mapa_es_alcanzable_desde_la_taberna) :-
    alcanzables(taberna, Zs),
    msort(Zs, Ordenadas),
    findall(Z, zona(Z, _), Todas),
    msort(Todas, TodasOrd),
    Ordenadas == TodasOrd.

test(solo_la_taberna_es_pacifica) :-
    findall(Z, zona_pacifica(Z), Zs),
    Zs == [taberna].

test(cuatro_personajes_con_sueldo_total_cinco) :-
    findall(S, personaje(_, _, _, _, _, _, sueldo(S)), Ss),
    length(Ss, 4),
    sumlist(Ss, 5).

test(cada_personaje_tiene_fila_y_rasgo) :-
    forall(personaje(Id, _, _, _, _, _, _),
           ( fila_preferida(Id, _), rasgo(Id, _) )).

test(los_parametros_de_balance_estan_definidos) :-
    forall(member(P, [edad_curado_min, edad_rancio_min, moral_inicial, moral_max,
                      moral_huelga, racion_por_miembro, coste_descanso, moral_impago]),
           parametro(P, _)).

test(la_moral_inicial_esta_dentro_del_rango) :-
    parametro(moral_inicial, M0), parametro(moral_max, Max), parametro(moral_huelga, H),
    M0 =< Max, M0 > H.

test(las_tildes_se_leen_bien) :-
    zona(aldea, Nombre),
    atom_length(Nombre, 14).

:- end_tests(mundo).

:- begin_tests(estado, [setup(nueva_partida)]).

% --- nueva partida ---

test(nueva_partida_deja_el_estado_inicial, [setup(nueva_partida)]) :-
    en_zona(taberna),
    dia(1),
    queso(cheddar, 0, 12),
    semilla(12345),
    marca(sueldos_pagados),
    findall(Id, en_compania(Id), Ids),
    Ids == [baldomero, pimentina, rufino, tuerca].

test(cada_miembro_empieza_con_su_vida_su_moral_y_su_fila, [setup(nueva_partida)]) :-
    forall(en_compania(Id),
           (   mundo:personaje(Id, _, _, vida(V), _, _, _),
               vida(Id, V),
               moral(Id, 6),
               mundo:fila_preferida(Id, F),
               fila(Id, F)
           )).

test(nueva_partida_dos_veces_no_duplica_nada, [setup(nueva_partida)]) :-
    nueva_partida,
    findall(Id, en_compania(Id), Ids), length(Ids, 4),
    findall(x, queso(_, _, _), Qs),    length(Qs, 1).

test(reiniciar_estado_lo_borra_todo, [setup(nueva_partida)]) :-
    reiniciar_estado,
    \+ en_zona(_), \+ dia(_), \+ en_compania(_), \+ vida(_, _), \+ queso(_, _, _).

test(todo_hecho_dinamico_esta_registrado) :-
    dinamicos_de_estado(Dins),
    Dins \== [],
    forall(member(PI, Dins), registrado(PI)).

test(todo_lo_registrado_esta_declarado_dinamico) :-
    dinamicos_de_estado(Dins),
    forall(( estado:persistente(PI) ; estado:transitorio(PI) ), memberchk(PI, Dins)).

% --- efectos sobre la vida y la moral ---

test(dano_baja_la_vida, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(baldomero, 10)),
    vida(baldomero, 20).

test(dano_no_baja_de_cero, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(rufino, 999)),
    vida(rufino, 0).

test(curar_no_pasa_del_maximo_del_catalogo, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(baldomero, 5)),
    aplicar_efecto(curar(baldomero, 100)),
    vida(baldomero, 30).

test(dano_negativo_no_es_valido, [setup(nueva_partida), fail]) :-
    aplicar_efecto(dano(baldomero, -3)).

test(la_moral_se_mantiene_entre_cero_y_diez, [setup(nueva_partida)]) :-
    aplicar_efecto(mod_moral(tuerca, 100)),
    moral(tuerca, 10),
    aplicar_efecto(mod_moral(tuerca, -100)),
    moral(tuerca, 0).

% --- efectos sobre el queso ---

test(ganar_queso_suma_si_ya_existe_el_lote, [setup(nueva_partida)]) :-
    aplicar_efecto(ganar_queso(cheddar, 0, 3)),
    queso(cheddar, 0, 15).

test(ganar_queso_crea_un_lote_nuevo, [setup(nueva_partida)]) :-
    aplicar_efecto(ganar_queso(brie, 0, 1)),
    queso(brie, 0, 1),
    queso(cheddar, 0, 12).

test(gastar_queso_resta, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 2)),
    queso(cheddar, 0, 10).

test(gastar_todo_el_lote_lo_elimina, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    \+ queso(cheddar, 0, _).

test(no_se_puede_gastar_mas_de_lo_que_hay, [setup(nueva_partida), fail]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 13)).

test(la_cantidad_debe_ser_positiva, [setup(nueva_partida), fail]) :-
    aplicar_efecto(ganar_queso(cheddar, 0, 0)).

test(envejecer_sube_la_edad_y_conserva_las_cantidades, [setup(nueva_partida)]) :-
    aplicar_efecto(ganar_queso(brie, 2, 1)),
    aplicar_efecto(envejecer_quesos),
    queso(cheddar, 1, 12),
    queso(brie, 3, 1),
    \+ queso(cheddar, 0, _).

% --- efectos sobre el tiempo, el mapa y las banderas ---

test(avanzar_dia, [setup(nueva_partida)]) :-
    aplicar_efecto(avanzar_dia),
    dia(2),
    findall(x, dia(_), L), length(L, 1).

test(viajar_a_una_zona_adyacente, [setup(nueva_partida)]) :-
    aplicar_efecto(viajar(aldea)),
    en_zona(aldea),
    findall(x, en_zona(_), L), length(L, 1).

test(viajar_a_una_zona_no_adyacente_falla, [setup(nueva_partida), fail]) :-
    aplicar_efecto(viajar(castillo)).

test(una_zona_que_no_existe_tampoco_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(viajar(luna)).

test(marcar_y_desmarcar, [setup(nueva_partida)]) :-
    aplicar_efecto(desmarcar(sueldos_pagados)),
    \+ marca(sueldos_pagados),
    aplicar_efecto(marcar(sueldos_pagados)),
    aplicar_efecto(marcar(sueldos_pagados)),
    findall(x, marca(sueldos_pagados), L), length(L, 1).

test(mensaje_no_toca_el_estado, [setup(nueva_partida)]) :-
    findall(H, ( estado:todo(N/A), functor(H, N, A), call(H) ), Antes),
    aplicar_efecto(mensaje(hola, [])),
    findall(H, ( estado:todo(N/A), functor(H, N, A), call(H) ), Despues),
    Antes == Despues.

test(fijar_semilla_normaliza_el_valor, [setup(nueva_partida)]) :-
    aplicar_efecto(fijar_semilla(65536)),
    semilla(0).

% --- listas de efectos y efectos desconocidos ---

test(aplicar_efectos_en_orden, [setup(nueva_partida)]) :-
    aplicar_efectos([gastar_queso(cheddar, 0, 2), ganar_queso(cheddar, 0, 5), avanzar_dia]),
    queso(cheddar, 0, 15),
    dia(2).

test(un_efecto_desconocido_lanza_efecto_invalido, [setup(nueva_partida), throws(efecto_invalido(volar(1)))]) :-
    aplicar_efecto(volar(1)).

test(un_efecto_desconocido_en_una_lista_tambien, [setup(nueva_partida), throws(efecto_invalido(_))]) :-
    aplicar_efectos([avanzar_dia, bailar]).

% --- transacciones ---

test(transaccion_que_triunfa_conserva_los_cambios, [setup(nueva_partida)]) :-
    con_transaccion(aplicar_efectos([avanzar_dia, gastar_queso(cheddar, 0, 2)])),
    dia(2),
    queso(cheddar, 0, 10).

test(transaccion_que_falla_deja_el_estado_como_estaba, [setup(nueva_partida)]) :-
    \+ con_transaccion(aplicar_efectos([ganar_queso(brie, 0, 4), gastar_queso(cheddar, 0, 99)])),
    \+ queso(brie, _, _),
    queso(cheddar, 0, 12),
    dia(1).

test(transaccion_con_excepcion_restaura_y_relanza, [setup(nueva_partida)]) :-
    catch(con_transaccion(aplicar_efectos([avanzar_dia, volar(2)])), efecto_invalido(_), true),
    dia(1).

% --- generador pseudoaleatorio ---

test(la_semilla_12345_da_la_secuencia_documentada) :-
    tirada(4, 12345, R1, S1), tirada(4, S1, R2, S2),
    tirada(4, S2, R3, S3), tirada(4, S3, R4, _),
    S1 == 8431,
    [R1, R2, R3, R4] == [3, 2, 0, 1].

test(la_tirada_es_reproducible) :-
    tirada(10, 777, R, S), tirada(10, 777, R2, S2),
    R == R2, S == S2.

test(la_tirada_cae_en_el_rango) :-
    forall(between(1, 200, I),
           (   S0 is I * 31,
               tirada(6, S0, R, _),
               R >= 0, R < 6
           )).

:- end_tests(estado).
