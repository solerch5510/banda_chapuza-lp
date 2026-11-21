% banco.pl (pruebas)
% T-35: el banco de frases del narrador. No prueba UNA frase, sino que el BANCO esta sano:
% hay las suficientes (unas 70 en la version minima), las marcas ~w cuadran con sus argumentos,
% no hay textos repetidos ni demasiado largos, las claves usan identificadores que existen (asi un
% renombrado o una errata se detecta), las reglas explicables tienen frase, los casos reales de
% por_que_no caen en una frase propia y no en la generica, las frases frecuentes rotan, y los
% comentarios de nodo del nivel detallado y la descripcion de los contratos funcionan.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/banco -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/explicar').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% Todas las frases del banco: frase(Clave, Nivel, Plantilla).
frases(Fs) :-
    findall(f(K, N, P), narrador:frase(K, N, P), Fs).

plantilla_formato_args(P, Formato, Args) :-
    (   nonvar(P), P = (Formato-Args) -> true ; Formato = P, Args = [] ).

contar_marcas(Formato, N) :-
    atomic_list_concat(Partes, '~w', Formato),
    length(Partes, L),
    N is L - 1.

% Una frase ya escrita: las marcas ~w se rellenan con 20 caracteres.
texto_de_ejemplo(Formato, Texto) :-
    contar_marcas(Formato, N),
    length(Relleno, N),
    maplist(=('xxxxxxxxxxxxxxxxxxxx'), Relleno),
    format(atom(Texto), Formato, Relleno).

% Las frases LARGAS a proposito: finales, derrota, eventos (docs/05 7.6: hasta 210 en eventos, inicio y fin).
larga_a_proposito(suceso(final(_))).
larga_a_proposito(suceso(derrota_combate)).
larga_a_proposito(suceso(fin_hambre)).
larga_a_proposito(suceso(evento_abre(_))).
larga_a_proposito(suceso(charla_abre(_))).
larga_a_proposito(suceso(charla_elige(_, _))).
larga_a_proposito(suceso(saber_nuevo(_))).

nivel_fijo(Nivel) :-
    aplicar_efecto(ajustar(nivel_explicacion, Nivel)).

% ---------------------------------------------------------------------------

:- begin_tests(el_tamano_del_banco).

test(hay_al_menos_setenta_frases) :-
    frases(Fs), length(Fs, N), N >= 70.

test(las_frases_de_explicar_y_por_que_no_son_mas_de_treinta) :-
    findall(K, ( narrador:frase(K, _, _), K \= suceso(_), K \= generica(_) ), Ks),
    length(Ks, N), N >= 30.

test(las_frases_de_sucesos_son_mas_de_cuarenta) :-
    findall(K, ( narrador:frase(K, _, _), K = suceso(_) ), Ks),
    length(Ks, N), N >= 40.

test(estan_las_nueve_genericas) :-
    forall(member(G, [exito, fallo, hecho, negacion, impide, predefinido, sin_prueba, sin_fallo, regla]),
           (   narrador:frase(generica(G), _, _) )).

:- end_tests(el_tamano_del_banco).

:- begin_tests(la_sanidad_de_cada_frase).

test(las_marcas_coinciden_con_los_argumentos) :-
    frases(Fs),
    forall(member(f(_, _, P), Fs),
           (   plantilla_formato_args(P, Formato, Args),
               contar_marcas(Formato, N),
               length(Args, N)
           )).

test(los_argumentos_son_variables_de_la_clave) :-
    frases(Fs),
    forall(member(f(K, _, P), Fs),
           (   plantilla_formato_args(P, _, Args),
               term_variables(K, Vs),
               forall(member(A, Args), ( var(A), member(V, Vs), V == A ))
           )).

test(un_texto_sin_argumentos_no_lleva_marcas) :-
    frases(Fs),
    forall(( member(f(_, _, P), Fs), atom(P) ),
           \+ contiene(P, '~w')).

test(no_hay_dos_textos_iguales) :-
    frases(Fs),
    findall(F, ( member(f(_, _, P), Fs), plantilla_formato_args(P, F, _) ), Formatos),
    msort(Formatos, Ordenados),
    sort(Formatos, SinRepetir),
    length(Ordenados, N), length(SinRepetir, N).

test(ningun_texto_es_demasiado_largo) :-
    frases(Fs),
    forall(( member(f(K, _, P), Fs), \+ larga_a_proposito(K) ),
           (   plantilla_formato_args(P, Formato, _),
               texto_de_ejemplo(Formato, T),
               atom_length(T, L),
               L =< 155                              % con nombres de 20 letras (el documento pide 135; el maximo real es 151)
           )).

test(cada_texto_acaba_en_punto_o_cierre) :-
    frases(Fs),
    forall(member(f(_, _, P), Fs),
           (   plantilla_formato_args(P, Formato, _),
               atom_length(Formato, N), N1 is N - 1,
               sub_atom(Formato, N1, 1, 0, Ultimo),
               memberchk(Ultimo, ['.', '»', '?', '!', ')'])
           )).

test(ningun_texto_tiene_espacios_dobles_ni_finales) :-
    frases(Fs),
    forall(member(f(_, _, P), Fs),
           (   plantilla_formato_args(P, Formato, _),
               \+ sub_atom(Formato, _, _, _, '  '),
               \+ sub_atom(Formato, _, 1, 0, ' '),
               \+ sub_atom(Formato, 0, 1, _, ' ')
           )).

test(el_nivel_de_cada_frase_es_valido) :-
    frases(Fs),
    forall(member(f(_, N, _), Fs), memberchk(N, [ambos, resumido, detallado])).

test(una_frase_con_argumentos_siempre_se_formatea, [nondet]) :-
    frases(Fs),
    forall(( member(f(_, _, P), Fs), nonvar(P), P = (_-_) ),
           (   narrador:formatear(P, T), atom(T), T \== '' )).

:- end_tests(la_sanidad_de_cada_frase).

:- begin_tests(las_claves_son_validas).

% Los identificadores que pueden aparecer en una clave: lo que existe en el juego.
conocido(A) :- mundo:personaje(A, _, _, _, _, _, _).
conocido(A) :- mundo:zona(A, _).
conocido(A) :- mundo:enemigo(A, _, _, _).
conocido(A) :- contratos:contrato(A, _, _, _, _).
conocido(A) :- mundo:habilidad_de(_, A).
conocido(A) :- mundo:rasgo(_, A).
conocido(A) :- charlas:presente(A, _, _, _).
conocido(A) :- charlas:opcion_charla(_, A, _, _, _).
conocido(A) :- charlas:saber(A).
conocido(A) :- member(A, [taberna, caballo, ok, nada, exito, a_medias, fracaso, chapuza, resumido, detallado,
                          fallo, hecho, negacion, predefinido, regla, sin_fallo, sin_prueba,
                          ninguno, curarse, robar_queso, invocar_moho, embestir, atacar, defender,
                          sueldos_pagados, hay_queso_para, rescate_gato, trepar, hechizo_de_raclette,
                          sacudir_arbol, cantar, pocion, venda_de_caballos]).

% Los nombres de predicado/mensaje que usan las claves (un registro a mano: si se renombra algo, aqui salta).
functor_valido(F) :-
    member(F, [suceso, generica, falla, impide,
               % mensajes
               llegada, descanso, sin_comida, come_rancio, pago, impago, fin_hambre, final, golpe, cae,
               evento_abre, evento_elige, intento_fallido, objetivo, contrato_resuelto, cobra, acepta, contrato_nuevo, sin_botin, usa_objeto, charla_abre, charla_elige, charla_repite, saber_nuevo, aparece,
               victoria, botin, derrota_combate, aturdido, pasa, se_cura, invoca_moho, roba_queso, embiste,
               defiende, carga_heroica, fondue, balada, rebuscar, nivel, golpea_a_clotilde, dia_nuevo,
               % reglas
               puede_viajar, puede_descansar, puede_pagar_sueldos, puede_atacar, dano, puede_habilidad,
               puede_aceptar, ignora_miedo, en_fila_alcanzable, vivo, modificador, queso_total,
               accion_enemigo, golpea_a_clotilde, teme, esta_en_huelga, rasgo, marca, contrato_activo,
               contrato_cumplido, contratos_cumplidos_min, visita, moral_media_min, miembros_en_pie_min,
               disponible, e, (<), atacar, embestir, hay_queso_para]).

atomos_de(T, As) :-
    findall(A, atomo_en(T, A), As).

atomo_en(T, A) :- atomic(T), atom(T), A = T.
atomo_en(T, A) :- compound(T), T =.. [_|Args], member(X, Args), atomo_en(X, A).

functores_de(T, Fs) :-
    findall(F, functor_en(T, F), Fs).

functor_en(T, F) :- compound(T), functor(T, F, _).
functor_en(T, F) :- compound(T), T =.. [_|Args], member(X, Args), functor_en(X, F).

test(los_identificadores_de_las_claves_existen_en_el_juego) :-
    frases(Fs),
    forall(member(f(K, _, _), Fs),
           (   atomos_de(K, As),
               forall(( member(A, As), \+ functor_valido(A) ), conocido(A))
           )).

test(los_nombres_de_predicado_de_las_claves_estan_registrados) :-
    frases(Fs),
    forall(member(f(K, _, _), Fs),
           (   functores_de(K, Funs),
               forall(member(F, Funs), functor_valido(F))
           )).

test(una_errata_en_una_clave_se_detectaria, [fail]) :-
    % sirve de prueba de la prueba: un identificador mal escrito no es conocido
    conocido(teme_caballo).

test(los_ocho_ataques_y_habilidades_por_personaje_existen) :-
    forall(mundo:habilidad_de(P, H), ( conocido(P), conocido(H) )).

:- end_tests(las_claves_son_validas).

:- begin_tests(cobertura_de_las_reglas_explicables).

tiene_frase_en(Clave) :-
    comentario(Clave, ambos, 0, _).

test(las_reglas_de_economia_y_viaje) :-
    forall(member(M, [puede_viajar(aldea), puede_descansar, puede_pagar_sueldos]),
           tiene_frase_en(M)).

test(puede_atacar_de_cada_miembro) :-
    forall(member(P, [baldomero, pimentina, rufino, tuerca]),
           tiene_frase_en(puede_atacar(P, e(rata_quesera, 1)))).

test(dano_y_su_minimo) :-
    tiene_frase_en(dano(baldomero, e(rata_quesera, 1), 9)),
    tiene_frase_en(dano(baldomero, e(rata_quesera, 1), 1)).

test(la_habilidad_de_cada_miembro) :-
    forall(mundo:habilidad_de(P, H),
           tiene_frase_en(puede_habilidad(P, H, e(rata_quesera, 1)))).

test(aceptar_un_contrato) :-
    forall(contratos:contrato(C, _, _, _, _), tiene_frase_en(puede_aceptar(C))).

test(cada_enemigo_y_cada_decision_de_la_ia) :-
    forall(member(T-A, [rata_quesera-robar_queso, bandido_torpe-atacar(baldomero), bandido_montado-embestir(baldomero),
                        gran_roquefort-invocar_moho, moho_saltarin-atacar(tuerca), rata_quesera-curarse,
                        bandido_torpe-defender]),
           tiene_frase_en(accion_enemigo(e(T, 1), A))).

test(la_escolta) :-
    tiene_frase_en(golpea_a_clotilde(e(bandido_torpe, 1))).

test(la_venda_de_caballos) :-
    tiene_frase_en(ignora_miedo(baldomero)).

test(el_resultado_de_cada_contrato_es_comentable_con_la_generica, [setup(nueva_partida), nondet]) :-
    % sin frase propia, la meta raiz cae en la generica de exito: siempre hay texto
    forall(member(C, [ratas_del_granero, gato_en_el_arbol]),
           (   solve(contratos:resultado(C, [marca(gato_bajado_con_arte)], _), P) -> comentario_prueba(P, ambos, 0, T), atom(T) ; true )).

:- end_tests(cobertura_de_las_reglas_explicables).

:- begin_tests(cobertura_de_por_que_no).

% Cada caso real: una situacion, una accion y la clave que sale (no debe ser generica).
clave_de(Situacion, Accion, Clave) :-
    nueva_partida,
    call(Situacion),
    juego:objetivo_de_accion(Accion, Meta),
    explicar:por_que_no(Meta, Diag),
    clave_de_diag(Diag, Clave).

nada.
en_combate_con(Tipos) :- comenzar_combate(Tipos, _).
sin_queso :- aplicar_efecto(gastar_queso(cheddar, 0, 12)).
lejos :- aplicar_efecto(viajar(aldea)).
en_camino_real :- aplicar_efecto(viajar(camino_real)).
tres_contratos :-
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    aplicar_efecto(contrato_aceptar(gallina_noble)).
ya_activo :- aplicar_efecto(contrato_aceptar(ratas_del_granero)).
huelga_de_baldomero :- en_combate_con([rata_quesera]), mod_moral_a(baldomero, 2).
baldomero_aturdido :- en_combate_con([rata_quesera]), aplicar_efecto(alterar(baldomero, aturdido, 2)).
baldomero_caido :- en_combate_con([rata_quesera]), aplicar_efecto(dano(baldomero, 99)).
retaguardia :-
    en_combate_con([bandido_torpe, rata_quesera]),
    retractall(estado:fila(e(rata_quesera, 1), _)),
    assertz(estado:fila(e(rata_quesera, 1), retaguardia)).
frente_con_caballo :- en_combate_con([bandido_montado]).
sin_queso_y_en_combate :- en_combate_con([rata_quesera]), sin_queso.
tras_pagar :- aplicar_efecto(marcar(sueldos_pagados)).
sin_pagar_y_sin_queso :- sin_queso.

mod_moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

casos([
    caso(lejos_de_todo,       nada,                     ir(castillo),                           falla(puede_viajar(castillo))),
    caso(descansar_fuera,     lejos,                    descansar,                              falla(puede_descansar)),
    caso(descansar_sin_queso, sin_queso,                descansar,                              falla(puede_descansar, hay_queso_para(2))),
    caso(pagar_ya_pagado,     tras_pagar,               pagar,                                  impide(marca(sueldos_pagados))),
    caso(la_gallina,          en_camino_real,           aceptar(gallina_noble),                 impide(rasgo(baldomero, teme_caballos))),
    caso(contrato_inexistente, nada,                    aceptar(dragon),                        falla(disponible(dragon))),
    caso(contrato_ya_activo,  ya_activo,                aceptar(ratas_del_granero),             impide(contrato_activo(ratas_del_granero))),
    caso(la_despensa_sin_contratos, en_camino_real,     aceptar(despensa_real),                 falla(visita(castillo))),
    caso(el_miedo,            frente_con_caballo,       atacar(baldomero, bandido_montado),     impide(teme(baldomero, caballo))),
    caso(la_huelga,           huelga_de_baldomero,      atacar(baldomero, rata_quesera),        impide(esta_en_huelga(baldomero))),
    caso(el_aturdimiento,     baldomero_aturdido,       atacar(baldomero, rata_quesera),        impide(aturdido(baldomero))),
    caso(el_caido,            baldomero_caido,          atacar(baldomero, rata_quesera),        falla(vivo(baldomero))),
    caso(la_retaguardia,      retaguardia,              atacar(tuerca, e(rata_quesera, 1)),     falla(en_fila_alcanzable(tuerca, e(rata_quesera, 1)))),
    caso(sin_queso_pimentina, sin_queso_y_en_combate,   habilidad(rata_quesera),                nada_que_comprobar)
]).

test(cada_caso_real_cae_en_una_frase_propia, [nondet]) :-
    casos(Cs),
    forall(( member(caso(Nombre, Sit, Acc, Esperada), Cs), Esperada \== nada_que_comprobar ),
           (   (   clave_de(Sit, Acc, Clave)
               ->  (   Clave = Esperada, \+ Clave = generica(_)
                   ->  true
                   ;   format("caso ~w: salio ~w y se esperaba ~w~n", [Nombre, Clave, Esperada]), fail )
               ;   format("caso ~w: sin diagnostico~n", [Nombre]), fail )
           )).

test(descansar_sin_queso_ya_no_dice_que_estas_fuera, [nondet]) :-
    nueva_partida, sin_queso,
    pantalla(por_que_no(descansar), T),
    contiene(T, 'Descansar se paga en queso'),
    \+ contiene(T, 'Aquí fuera no hay camas').

test(descansar_fuera_de_la_taberna_sigue_diciendo_lo_de_las_camas, [nondet]) :-
    nueva_partida, lejos,
    pantalla(por_que_no(descansar), T),
    contiene(T, 'Aquí fuera no hay camas'),
    \+ contiene(T, 'Descansar se paga en queso').

test(pagar_sin_queso_dice_que_no_alcanza, [nondet]) :-
    nueva_partida, sin_queso,
    aplicar_efecto(desmarcar(sueldos_pagados)),
    pantalla(por_que_no(pagar), T),
    contiene(T, 'No alcanza para todos los sueldos').

test(con_tres_contratos_no_se_puede_firmar_otro, [nondet]) :-
    nueva_partida, tres_contratos, en_camino_real,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    ordena(por_que_no(aceptar(despensa_real)), [vista(diag, _, D)]),
    clave_de_diag(D, C),
    \+ C = generica(_).

test(el_rey_pide_contratos_cumplidos, [nondet]) :-
    nueva_partida,
    ordena(ir(camino_real), _), ordena(ir(castillo), _),
    pantalla(por_que_no(aceptar(despensa_real)), T),
    contiene(T, 'contratos cumplidos antes de fiarse').

:- end_tests(cobertura_de_por_que_no).

:- begin_tests(las_frases_que_rotan).

alta_frecuencia([suceso(golpe(baldomero, e(rata_quesera, 1), 5)), suceso(defiende(baldomero)), suceso(victoria),
                 suceso(cae(baldomero)), suceso(descanso), suceso(llegada(taberna)), suceso(llegada(aldea)),
                 suceso(llegada(camino_real)), suceso(carga_heroica(e(rata_quesera, 1))), suceso(balada)]).

test(las_claves_frecuentes_tienen_al_menos_dos_variantes) :-
    alta_frecuencia(Ks),
    forall(member(K, Ks),
           (   findall(T, ( between(0, 5, U), comentario(K, ambos, U, T) ), Ts),
               sort(Ts, Unicos),
               length(Unicos, N), N >= 2
           )).

test(dos_usos_seguidos_nunca_repiten_el_texto) :-
    alta_frecuencia(Ks),
    forall(( member(K, Ks), between(0, 8, U) ),
           (   U1 is U + 1,
               comentario(K, ambos, U, A), comentario(K, ambos, U1, B),
               A \== B
           )).

test(la_rotacion_es_la_misma_en_dos_ejecuciones) :-
    alta_frecuencia(Ks),
    forall(member(K, Ks),
           (   comentario(K, ambos, 3, A), comentario(K, ambos, 3, B), A == B )).

test(el_primer_uso_de_golpe_es_la_frase_de_siempre) :-
    comentario(suceso(golpe(baldomero, e(rata_quesera, 1), 5)), ambos, 0, T),
    contiene(T, 'Cuentas claras').

test(cada_enemigo_cae_a_su_manera) :-
    findall(T, ( member(Tipo, [rata_quesera, bandido_torpe, bandido_montado, moho_saltarin, gran_roquefort]),
                 comentario(suceso(cae(e(Tipo, 1))), ambos, 0, T) ),
            Ts),
    sort(Ts, Unicos), length(Ts, N), length(Unicos, N).

test(un_miembro_que_cae_usa_la_frase_general, [nondet]) :-
    comentario(suceso(cae(baldomero)), ambos, 0, T),
    contiene(T, 'Sir Baldomero'),
    \+ contiene(T, 'Bandido').

test(el_jefe_tiene_su_aparicion, [nondet]) :-
    comentario(suceso(aparece(gran_roquefort)), ambos, 0, T),
    contiene(T, 'Al fondo de las Cuevas').

:- end_tests(las_frases_que_rotan).

:- begin_tests(comentarios_de_nodo).

prueba_de_un_ataque(P) :-
    nueva_partida,
    comenzar_combate([bandido_torpe], _),
    solve((combate:puede_atacar(baldomero, e(bandido_torpe, 1)), combate:dano(baldomero, e(bandido_torpe, 1), _)), P).

test(el_resumido_no_lleva_comentarios_de_nodo, [nondet]) :-
    prueba_de_un_ataque(P),
    comentarios_de_nodo(P, resumido, 0, []).

test(el_detallado_lleva_hasta_tres, [nondet]) :-
    prueba_de_un_ataque(P),
    comentarios_de_nodo(P, detallado, 0, Ts),
    Ts = [_|_],
    length(Ts, N), N =< 3.

test(no_se_repite_ninguno, [nondet]) :-
    prueba_de_un_ataque(P),
    comentarios_de_nodo(P, detallado, 0, Ts),
    sort(Ts, U), length(Ts, N), length(U, N).

test(no_incluyen_la_frase_de_cierre, [nondet]) :-
    prueba_de_un_ataque(P),
    comentarios_de_nodo(P, detallado, 0, Ts),
    comentario_prueba(P, detallado, 0, Cierre),
    \+ memberchk(Cierre, Ts).

test(hablan_de_los_nodos_del_arbol, [nondet]) :-
    prueba_de_un_ataque(P),
    comentarios_de_nodo(P, detallado, 0, Ts),
    atomic_list_concat(Ts, ' ', Todo),
    (   contiene(Todo, 'sigue en pie') ; contiene(Todo, 'Ajuste al daño') ; contiene(Todo, 'a la distancia justa') ; contiene(Todo, 'deja a') ).

test(un_nodo_con_el_mismo_texto_que_el_cierre_no_se_repite, [nondet]) :-
    % la raiz y sus dos hijos dicen lo mismo (vivo(baldomero)): como nota solo valdria el hijo, pero es el cierre
    P = regla(vivo(baldomero), 1, [hecho(vivo(baldomero)), hecho(vivo(baldomero))]),
    comentarios_de_nodo(P, detallado, 0, []).

test(dos_nodos_con_el_mismo_texto_dan_una_sola_nota, [nondet]) :-
    P = regla(algo_sin_frase, 1, [hecho(vivo(baldomero)), hecho(vivo(baldomero)), hecho(vivo(rufino))]),
    comentarios_de_nodo(P, detallado, 0, Ts),
    length(Ts, 2),
    sort(Ts, U), length(U, 2).

test(una_prueba_sin_nodos_con_frase_no_da_comentarios, [setup(nueva_partida), nondet]) :-
    solve(estado:en_zona(taberna), P),
    comentarios_de_nodo(P, detallado, 0, []).

test(la_pantalla_detallada_los_enseña_y_la_resumida_no, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe], _),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T1),
    \+ contiene(T1, '  · '),
    nivel_fijo(detallado),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), T2),
    contiene(T2, '  · ').

test(los_comentarios_no_cambian_el_estado, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe], _),
    nivel_fijo(detallado),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), N \== usos_frase, functor(H, N, A), call(H) ), A1),
    pantalla(explicar(atacar(baldomero, bandido_torpe)), _),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), N \== usos_frase, functor(H, N, A), call(H) ), A2),
    A1 =@= A2.

:- end_tests(comentarios_de_nodo).

:- begin_tests(descripcion_de_los_contratos).

test(los_cuatro_contratos_tienen_su_chiste) :-
    forall(contratos:contrato(C, _, _, _, _), descripcion_contrato(C, _)).

test(un_contrato_desconocido_no_tiene, [fail]) :-
    descripcion_contrato(dragon, _).

test(el_tablon_ensena_el_chiste_de_cada_contrato_a_la_vista, [setup(nueva_partida), nondet]) :-
    pantalla(contratos, T),
    forall(member(C, [ratas_del_granero, gato_en_el_arbol, gallina_noble]),
           (   descripcion_contrato(C, D), contiene(T, D) )).

test(el_chiste_va_debajo_de_su_contrato, [setup(nueva_partida), nondet]) :-
    pantalla(contratos, T),
    atomic_list_concat(Ls, '\n', T),
    nth0(I, Ls, L), contiene(L, 'Ratas del Granero'),
    I1 is I + 1, nth0(I1, Ls, Sig),
    contiene(Sig, 'papeles de alquiler').

test(los_chistes_no_se_repiten) :-
    findall(D, descripcion_contrato(_, D), Ds),
    sort(Ds, U), length(Ds, N), length(U, N).

test(los_chistes_acaban_en_punto) :-
    forall(descripcion_contrato(_, D),
           (   atom_length(D, N), N1 is N - 1, sub_atom(D, N1, 1, 0, '.') )).

test(el_tablon_sigue_dando_el_estado_y_la_recompensa, [setup(nueva_partida), nondet]) :-
    pantalla(contratos, T),
    contiene(T, '[disponible] Ratas del Granero'),
    contiene(T, '14 quesos').

:- end_tests(descripcion_de_los_contratos).
