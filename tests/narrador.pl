% narrador.pl (pruebas)
% T-17: el narrador minimo. El banco frase/3, la eleccion de la clave mas especifica, la
% rotacion de variantes, los nombres con articulo, las frases genericas y el comentario
% que acompana a explicar. Las pruebas de rotacion y de especificidad usan frases de
% ejemplo propias (frase/3 es multifile) para no depender del texto real del banco.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/narrador -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/narrador').
:- use_module('../src/explicar').
:- use_module('../src/juego').
:- use_module('../src/ui').

% Frases de ejemplo, solo para las pruebas.
narrador:frase(prueba(rotacion), ambos, 'uno').
narrador:frase(prueba(rotacion), ambos, 'dos').
narrador:frase(prueba(rotacion), ambos, 'tres').

narrador:frase(prueba(especifica, _), ambos, 'general').
narrador:frase(prueba(especifica, a), ambos, 'especifica').

narrador:frase(prueba(niveles), resumido,  'solo resumido').
narrador:frase(prueba(niveles), detallado, 'solo detallado').
narrador:frase(prueba(niveles), ambos,     'para los dos').

narrador:frase(prueba(nombres, Z), ambos, 'Voy a ~w.'-[Z]).
narrador:frase(prueba(nombres_de, Z), ambos, 'Vengo de ~w.'-[Z]).
narrador:frase(prueba(personaje, P), ambos, '~w se sienta.'-[P]).
narrador:frase(prueba(minuscula), ambos, 'empieza en minuscula').
narrador:frase(prueba(tipo_enemigo, rata_quesera), ambos, 'es una rata').
narrador:frase(prueba(arbol), ambos, 'frase del hijo').

nueva :- nueva_partida.

cmd(Comando, Items) :- ejecutar(Comando, resultado(Items)).

salida_de(Resultado, Texto) :-
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

:- begin_tests(variantes).

test(las_variantes_rotan_con_el_uso) :-
    findall(T, ( between(0, 6, U), comentario(prueba(rotacion), ambos, U, T) ), Ts),
    Ts == ['Uno', 'Dos', 'Tres', 'Uno', 'Dos', 'Tres', 'Uno'].       % la primera letra sale en mayuscula

test(nunca_se_repite_dos_veces_seguidas_con_dos_o_mas_variantes) :-
    forall(between(0, 20, U),
           (   comentario(prueba(rotacion), ambos, U, A),
               U1 is U + 1,
               comentario(prueba(rotacion), ambos, U1, B),
               A \== B
           )).

test(una_sola_variante_siempre_da_la_misma) :-
    findall(T, ( between(0, 5, U), comentario(prueba(minuscula), ambos, U, T) ), Ts),
    sort(Ts, Unicos),
    length(Unicos, 1).

test(la_misma_entrada_da_la_misma_salida) :-
    comentario(prueba(rotacion), ambos, 4, T1),
    comentario(prueba(rotacion), ambos, 4, T2),
    T1 == T2.

test(una_clave_sin_frase_falla, [fail]) :-
    comentario(prueba(no_existe), ambos, 0, _).

:- end_tests(variantes).

:- begin_tests(clave_mas_especifica).

test(gana_la_clave_con_menos_variables) :-
    comentario(prueba(especifica, a), ambos, 0, T),
    T == 'Especifica'.

test(si_no_hay_especifica_vale_la_general) :-
    comentario(prueba(especifica, b), ambos, 0, T),
    T == 'General'.

test(la_especifica_no_se_mezcla_en_la_rotacion) :-
    % para la clave a solo existe una frase especifica: siempre esa, aunque haya otra general
    findall(T, ( between(0, 4, U), comentario(prueba(especifica, a), ambos, U, T) ), Ts),
    sort(Ts, Unicos),
    Unicos == ['Especifica'].

test(una_clave_con_el_tipo_de_enemigo_casa_con_su_instancia) :-
    comentario(prueba(tipo_enemigo, e(rata_quesera, 3)), ambos, 0, T),
    T == 'Es una rata'.

test(otro_tipo_de_enemigo_no_casa, [fail]) :-
    comentario(prueba(tipo_enemigo, e(bandido_torpe, 1)), ambos, 0, _).

test(las_zonas_del_juego_tienen_su_propia_frase) :-
    forall(mundo:zona(Z, _),
           (   comentario(suceso(llegada(Z)), ambos, 0, T),
               T \== ''
           )).

test(una_zona_desconocida_usa_la_frase_general) :-
    texto(llegada, [luna], 0, T),
    T == 'Llegas a luna.'.

:- end_tests(clave_mas_especifica).

:- begin_tests(niveles).

test(el_nivel_resumido_no_ve_las_frases_detalladas) :-
    findall(T, ( between(0, 5, U), comentario(prueba(niveles), resumido, U, T) ), Ts),
    sort(Ts, Unicos),
    Unicos == ['Para los dos', 'Solo resumido'].

test(el_nivel_detallado_no_ve_las_resumidas) :-
    findall(T, ( between(0, 5, U), comentario(prueba(niveles), detallado, U, T) ), Ts),
    sort(Ts, Unicos),
    Unicos == ['Para los dos', 'Solo detallado'].

test(pedir_ambos_no_filtra_por_nivel_y_no_duplica) :-
    findall(T, ( between(0, 2, U), comentario(prueba(niveles), ambos, U, T) ), Ts),
    Ts == ['Solo resumido', 'Solo detallado', 'Para los dos'].

test(una_generica_detallada_no_sale_en_resumido, [fail]) :-
    comentario(generica(hecho), resumido, 0, _).

:- end_tests(niveles).

:- begin_tests(nombres_y_formato).

test(las_zonas_llevan_articulo) :-
    nombre_visible(taberna, 'la Taberna del Cuajo Torcido'),
    nombre_visible(camino_real, 'el Camino Real'),
    nombre_visible(cuevas, 'las Cuevas del Roquefort'),
    nombre_visible(cheddar, 'el cheddar').

test(los_personajes_no_llevan_articulo) :-
    nombre_visible(baldomero, 'Sir Baldomero'),
    nombre_visible(pimentina, 'Madame Pimentina').

test(una_instancia_de_enemigo_se_muestra_como_su_tipo) :-
    nombre_visible(e(rata_quesera, 2), T),
    nombre_visible(rata_quesera, T).

test(numeros_y_desconocidos_pasan_tal_cual) :-
    nombre_visible(5, 5),
    nombre_visible(algo_raro, algo_raro).

test(a_el_se_contrae_en_al) :-
    comentario(prueba(nombres, camino_real), ambos, 0, T),
    T == 'Voy al Camino Real.'.

test(a_la_no_se_contrae) :-
    comentario(prueba(nombres, aldea), ambos, 0, T),
    T == 'Voy a la Aldea Requesón.'.

test(de_el_se_contrae_en_del) :-
    comentario(prueba(nombres_de, castillo), ambos, 0, T),
    T == 'Vengo del Castillo Camembert.'.

test(la_primera_letra_va_en_mayuscula) :-
    comentario(prueba(minuscula), ambos, 0, T),
    T == 'Empieza en minuscula'.

test(los_personajes_salen_sin_articulo_en_la_frase) :-
    comentario(prueba(personaje, tuerca), ambos, 0, T),
    T == 'Tuerca se sienta.'.

:- end_tests(nombres_y_formato).

:- begin_tests(banco_real).

test(las_nueve_genericas_existen) :-
    forall(member(K, [exito, fallo, hecho, negacion, impide, predefinido, sin_prueba, sin_fallo, regla]),
           comentario(generica(K), ambos, 0, _)).

test(todo_mensaje_que_emite_el_juego_tiene_frase) :-
    forall(( member(Clave-Args,
                    [ llegada-[taberna], llegada-[aldea], llegada-[bosque], llegada-[camino_real],
                      llegada-[castillo], llegada-[cuevas], descanso-[], sin_comida-[baldomero],
                      come_rancio-[tuerca], pago-[5], impago-[], fin_hambre-[] ]) ),
           (   texto(Clave, Args, 0, T)
           ->  atom(T), T \== ''
           ;   format(user_error, "sin frase: ~w~n", [Clave-Args]), fail
           )).

test(el_texto_no_deja_marcas_sin_rellenar) :-
    forall(( member(Clave-Args, [sin_comida-[baldomero], come_rancio-[tuerca], pago-[5], llegada-[luna]]),
             texto(Clave, Args, 0, T) ),
           \+ sub_atom(T, _, _, _, '~w')).

test(el_banco_es_estatico_y_el_narrador_no_escribe) :-
    \+ predicate_property(narrador:frase(_, _, _), dynamic),
    predicate_property(narrador:frase(_, _, _), number_of_clauses(N)),
    N > 20.

test(un_mensaje_desconocido_no_tiene_frase, [fail]) :-
    texto(mensaje_inexistente, [], 0, _).

:- end_tests(banco_real).

:- begin_tests(comentario_de_explicar).

test(la_meta_raiz_da_la_frase, [setup(nueva), nondet]) :-
    solve(compania:puede_viajar(aldea), P),
    comentario_prueba(P, ambos, 0, T),
    T == 'Hay camino hasta la Aldea Requesón, y tan pegajoso que cuesta un día entero. Ley de la Ruta Pegajosa.'.

test(para_cada_accion_explicable, [setup(nueva), nondet]) :-
    solve(economia:puede_descansar, P1),
    comentario_prueba(P1, ambos, 0, T1),
    sub_atom(T1, 0, _, _, 'Las camas del Cuajo Torcido'),
    aplicar_efecto(desmarcar(sueldos_pagados)),
    solve(economia:puede_pagar_sueldos, P2),
    comentario_prueba(P2, ambos, 0, T2),
    sub_atom(T2, 0, _, _, 'Hay queso para todos los sueldos').

test(si_la_raiz_no_tiene_frase_sirve_la_primera_de_sus_hijos, [nondet]) :-
    Prueba = regla(raiz_sin_frase, 1, [hecho(otra_sin_frase), regla(prueba(arbol), 1, [])]),
    comentario_prueba(Prueba, ambos, 0, T),
    T == 'Frase del hijo'.

test(la_raiz_gana_a_sus_hijos, [nondet]) :-
    Prueba = regla(prueba(rotacion), 1, [regla(prueba(arbol), 1, [])]),
    comentario_prueba(Prueba, ambos, 0, T),
    T == 'Uno'.

test(sin_ninguna_frase_sale_la_generica_de_exito, [nondet]) :-
    comentario_prueba(regla(nada(1), 1, [hecho(nada(2))]), ambos, 0, T),
    comentario(generica(exito), ambos, 0, G),
    T == G.

test(siempre_hay_texto, [nondet]) :-
    forall(member(P, [hecho(x), regla(x, 1, []), no(x), verdad, builtin(1 > 0), regla(x, 1, [corte])]),
           (   comentario_prueba(P, ambos, 0, T), atom(T), T \== '' )).

:- end_tests(comentario_de_explicar).

:- begin_tests(integracion_con_el_juego).

test(el_contador_de_uso_es_por_grupo, [setup(nueva), nondet]) :-
    cmd(ir(aldea), _),
    usos_frase(llegada(aldea), 1),
    \+ usos_frase(llegada(taberna), _),
    cmd(ir(taberna), _),
    usos_frase(llegada(taberna), 1),
    usos_frase(llegada(aldea), 1).

test(volver_a_una_zona_sube_su_contador, [setup(nueva)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    aplicar_efecto(ganar_queso(cheddar, 0, 60)),
    cmd(ir(aldea), I1), cmd(ir(taberna), _), cmd(ir(aldea), I2),
    memberchk(msg(llegada, [aldea], 0), I1),
    memberchk(msg(llegada, [aldea], 1), I2).

test(ui_imprime_la_frase_de_llegada, [setup(nueva)]) :-
    cmd(ir(aldea), Items),
    salida_de(resultado(Items), S),
    contiene(S, 'Aldea Requesón: casitas blancas').

test(explicar_acaba_con_el_comentario_del_narrador, [setup(nueva)]) :-
    cmd(ir(aldea), _),
    cmd(explicar, Items),
    salida_de(resultado(Items), S),
    contiene(S, '[ok] puede_viajar(aldea)'),
    contiene(S, 'Narrador: Hay camino hasta la Aldea Requesón').

test(explicar_con_otra_accion_usa_su_comentario, [setup(nueva)]) :-
    cmd(explicar(descansar), Items),
    salida_de(resultado(Items), S),
    contiene(S, 'Narrador: Las camas del Cuajo Torcido aceptan clientes').

test(el_narrador_no_cambia_el_estado, [setup(nueva)]) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Antes0),
    msort(Antes0, Antes),
    texto(llegada, [aldea], 0, _),
    comentario(generica(exito), ambos, 3, _),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Despues0),
    msort(Despues0, Despues),
    Antes == Despues.

:- end_tests(integracion_con_el_juego).
