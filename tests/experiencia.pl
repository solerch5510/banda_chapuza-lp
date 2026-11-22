% experiencia.pl (pruebas)
% Niveles y experiencia (paquete D, docs/13-ampliacion.md §10). Regla de oro: el NIVEL 1 son exactamente las cifras de la
% ficha; solo se crece desde el 2. La experiencia sale de los combates (para los que siguen en pie al ganar) y de resolver
% los eventos de contrato (para quien lo resuelve, mas cuanto antes). Los encuentros de una zona con nivel traen enemigos
% de ese nivel.
%   (1) los datos; (2) el nivel derivado de la experiencia; (3) las cifras con nivel; (4) subir de nivel; (5) la
%   experiencia de un combate; (6) la de un evento; (7) los enemigos con nivel y la zona; (8) lo que se ve.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/experiencia -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/eventos').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

pantalla(Cmd, Texto) :-
    juego:ejecutar(Cmd, R),
    with_output_to(atom(Texto), ui:mostrar(R)).

dar_xp(Id, N) :- estado:aplicar_efectos([ganar_xp(Id, N)]).

:- begin_tests(los_datos).

test(la_curva_es_0_20_50_90_140) :-
    findall(X, ( member(N, [1, 2, 3, 4, 5]), mundo:xp_para(N, X) ), Xs),
    assertion(Xs == [0, 20, 50, 90, 140]).

test(la_curva_llega_al_20_aunque_el_contenido_acabe_en_el_5) :-
    assertion(mundo:xp_para(10, _)), assertion(mundo:xp_para(15, _)), assertion(mundo:xp_para(20, _)),
    assertion(\+ mundo:xp_para(21, _)),
    mundo:parametro(nivel_maximo, M), assertion(M == 5).

test(la_curva_crece_siempre) :-
    forall(( between(2, 20, N), N0 is N - 1 ),
           (   mundo:xp_para(N0, A), mundo:xp_para(N, B), assertion(B > A) )).

test(cada_rol_tiene_crecimiento) :-
    forall(mundo:personaje(_, _, Rol, _, _, _, _),
           assertion(mundo:crecimiento(Rol, vida(_), ataque(_), defensa(_)))).

test(cada_miembro_tiene_una_pasiva_en_el_nivel_3_y_otra_en_el_5) :-
    forall(mundo:personaje(Id, _, _, _, _, _, _),
           (   findall(L, mundo:pasiva(Id, L, _, _), Ls), msort(Ls, S), assertion(S == [3, 5]) )).

test(cada_pasiva_tiene_nombre_y_un_bono_valido) :-
    forall(mundo:pasiva(_, _, P, Bono),
           (   assertion(narrador:nombre(P, _)),
               Bono =.. [A, N], assertion(memberchk(A, [vida, ataque, defensa])), assertion(integer(N)), assertion(N > 0) )).

test(cada_enemigo_vale_experiencia_y_el_jefe_el_que_mas) :-
    forall(mundo:enemigo(T, _, _, _), ( mundo:xp_de(T, X), assertion(X > 0) )),
    mundo:xp_de(gran_roquefort, J),
    forall(( mundo:xp_de(T, X), T \== gran_roquefort ), assertion(X < J)).

test(resolver_antes_vale_mas) :-
    mundo:xp_por_intento(1, A), mundo:xp_por_intento(2, B), mundo:xp_por_intento(3, C),
    assertion(A > B), assertion(B > C), assertion(C > 0).

test(las_zonas_con_nivel_son_las_de_los_encuentros_y_las_cuevas_la_mas_dura) :-
    forall(mundo:nivel_de_zona(Z, N), ( assertion(mundo:probabilidad_de_encuentro(Z, _)), assertion(N >= 2) )),
    mundo:nivel_de_zona(cuevas, C),
    forall(mundo:nivel_de_zona(_, N), assertion(N =< C)).

:- end_tests(los_datos).

:- begin_tests(el_nivel_se_deriva).

test(se_empieza_en_el_nivel_1_con_cero_de_experiencia) :-
    nueva_partida,
    forall(compania:miembro(Id), ( estado:xp(Id, X), assertion(X == 0), estado:nivel_de(Id, N), assertion(N == 1) )).

test(los_umbrales_justos) :-
    forall(member(X-N, [0-1, 19-1, 20-2, 49-2, 50-3, 89-3, 90-4, 139-4, 140-5]),
           (   estado:nivel_por_xp(X, L), assertion(L == N) )).

test(no_se_pasa_del_nivel_maximo) :-
    estado:nivel_por_xp(100000, L), assertion(L == 5).

test(ganar_xp_suma) :-
    nueva_partida, dar_xp(tuerca, 7), dar_xp(tuerca, 8),
    estado:xp(tuerca, X), assertion(X == 15).

test(ganar_xp_negativo_no_es_un_efecto_valido) :-
    nueva_partida,
    assertion(\+ catch(dar_xp(tuerca, -3), _, fail)),
    estado:xp(tuerca, X), assertion(X == 0).

test(un_enemigo_sin_nivel_es_de_nivel_1, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera], _),
    estado:nivel_de(e(rata_quesera, 1), N), assertion(N == 1).

:- end_tests(el_nivel_se_deriva).

:- begin_tests(las_cifras_con_nivel).

test(en_el_nivel_1_las_cifras_son_las_de_la_ficha) :-
    nueva_partida,
    forall(mundo:personaje(Id, _, _, vida(V), ataque(A), defensa(D), _),
           (   estado:vida_maxima(Id, VM), assertion(VM == V),
               combate:ataque_base(Id, AB), assertion(AB == A),
               combate:defensa_base(Id, DB), assertion(DB == D) )).

test(en_el_nivel_2_baldomero_suma_su_crecimiento, [nondet]) :-
    nueva_partida, dar_xp(baldomero, 20),
    estado:vida_maxima(baldomero, V), assertion(V == 33),
    combate:ataque_base(baldomero, A), assertion(A == 12),
    combate:defensa_base(baldomero, D), assertion(D == 3).

test(en_el_nivel_3_entra_la_primera_pasiva, [nondet]) :-
    nueva_partida, dar_xp(baldomero, 50),
    combate:defensa_base(baldomero, D), assertion(D == 4),              % escudo de corteza
    compania:progreso(baldomero, 3, 50, 90, Ps), assertion(Ps == [escudo_de_corteza]).

test(en_el_nivel_5_las_dos_pasivas_y_sin_siguiente, [nondet]) :-
    nueva_partida, dar_xp(pimentina, 140),
    estado:vida_maxima(pimentina, V), assertion(V =:= 18 + 4*2 + 4),
    combate:ataque_base(pimentina, A), assertion(A =:= 6 + 4*1 + 2),
    compania:progreso(pimentina, 5, _, Sig, Ps), assertion(Sig == maximo),
    msort(Ps, S), assertion(S == [cucharon_templado, delantal_ignifugo]).

test(el_dano_usa_el_ataque_con_nivel, [nondet]) :-
    nueva_partida, juego:comenzar_combate([bandido_torpe], _),
    combate:dano(baldomero, e(bandido_torpe, 1), D1), assertion(D1 == 9),
    dar_xp(baldomero, 20),
    combate:dano(baldomero, e(bandido_torpe, 1), D2), assertion(D2 == 10).

test(la_ficha_de_compania_ensena_las_cifras_con_nivel) :-
    nueva_partida, dar_xp(tuerca, 50),
    compania:informe(Fs),
    memberchk(miembro(tuerca, _, _, _, VM, A, D, _, _, _, _, _), Fs),
    assertion(VM == 26), assertion(A == 9), assertion(D == 3).

test(descansar_cura_hasta_la_vida_maxima_con_nivel) :-
    nueva_partida, dar_xp(rufino, 50),
    estado:aplicar_efectos([curar(rufino, 99), dano(rufino, 25)]),                          % 3 de 28: hay que curar mas que la ficha (20)
    economia:efectos_descanso(Efs), estado:aplicar_efectos(Efs),
    estado:vida(rufino, V), estado:vida_maxima(rufino, Max), assertion(V == Max), assertion(Max == 28).

:- end_tests(las_cifras_con_nivel).

:- begin_tests(subir_de_nivel).

test(sin_cambiar_de_nivel_solo_se_gana_experiencia) :-
    nueva_partida,
    compania:efectos_ganar_xp(tuerca, 5, Efs), assertion(Efs == [ganar_xp(tuerca, 5)]).

test(al_subir_se_avisa_y_se_cura_lo_que_crece_la_vida) :-
    nueva_partida,
    compania:efectos_ganar_xp(baldomero, 20, Efs),
    assertion(Efs == [ganar_xp(baldomero, 20), curar(baldomero, 3), mensaje(sube_nivel, [baldomero, 2])]).

test(subir_dos_niveles_de_golpe_da_la_pasiva_del_3) :-
    nueva_partida,
    compania:efectos_ganar_xp(tuerca, 50, Efs),
    assertion(memberchk(mensaje(sube_nivel, [tuerca, 3]), Efs)),
    assertion(memberchk(mensaje(pasiva_nueva, [tuerca, pies_de_gato]), Efs)),
    assertion(memberchk(curar(tuerca, 4), Efs)).

test(un_caido_que_sube_no_se_cura) :-
    nueva_partida, estado:aplicar_efectos([dano(tuerca, 99)]),
    compania:efectos_ganar_xp(tuerca, 20, Efs),
    assertion(\+ memberchk(curar(_, _), Efs)).

test(subir_de_nivel_deja_la_vida_donde_estaba_mas_lo_que_crece) :-
    nueva_partida, estado:aplicar_efectos([dano(baldomero, 10)]),       % 20 de 30
    compania:efectos_ganar_xp(baldomero, 20, Efs), estado:aplicar_efectos(Efs),
    estado:vida(baldomero, V), assertion(V == 23).

:- end_tests(subir_de_nivel).

:- begin_tests(la_experiencia_de_un_combate).

test(al_ganar_lo_que_valen_los_enemigos_se_reparte_entre_los_que_siguen_en_pie, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera, bandido_torpe], _),
    forall(estado:instancia(E, _), estado:aplicar_efectos([dano(E, 99)])),
    combate:efectos_fin(victoria, Efs),
    assertion(memberchk(mensaje(xp_victoria, [8, 2]), Efs)),             % 3 + 5 = 8, entre 4: 2 cada uno
    forall(compania:miembro(Id), assertion(memberchk(ganar_xp(Id, 2), Efs))).

test(quien_ha_caido_no_gana_experiencia, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera], _),
    estado:aplicar_efectos([dano(tuerca, 99), dano(e(rata_quesera, 1), 99)]),
    combate:efectos_fin(victoria, Efs),
    assertion(\+ memberchk(ganar_xp(tuerca, _), Efs)),
    assertion(memberchk(ganar_xp(baldomero, 1), Efs)).                    % 3 entre 3, redondeando hacia arriba

test(un_combate_de_verdad_deja_la_experiencia_apuntada, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera], _),
    orden(atacar(rata_quesera), Items),
    assertion(\+ estado:en_combate(_)),
    assertion(memberchk(msg(xp_victoria, [3, 1], _), Items)),
    forall(compania:miembro(Id), ( estado:xp(Id, X), assertion(X == 1) )).

test(con_menos_en_pie_a_cada_uno_le_toca_mas, [nondet]) :-
    nueva_partida, juego:comenzar_combate([gran_roquefort], _),
    estado:aplicar_efectos([dano(tuerca, 99), dano(rufino, 99), dano(e(gran_roquefort, 1), 99)]),
    combate:efectos_fin(victoria, Efs),
    assertion(memberchk(ganar_xp(baldomero, 20), Efs)),                  % 40 entre 2
    assertion(memberchk(mensaje(sube_nivel, [baldomero, 2]), Efs)).

test(el_reparto_redondea_hacia_arriba, [nondet]) :-
    nueva_partida, juego:comenzar_combate([gran_roquefort, rata_quesera], _),
    forall(estado:instancia(E, _), estado:aplicar_efectos([dano(E, 99)])),
    combate:efectos_fin(victoria, Efs),
    assertion(memberchk(mensaje(xp_victoria, [43, 11]), Efs)).

:- end_tests(la_experiencia_de_un_combate).

:- begin_tests(la_experiencia_de_un_evento).

test(resolverlo_al_primer_intento_da_15_a_quien_lo_resuelve, [nondet]) :-
    nueva_partida,
    eventos:efectos_eleccion(rescate_gato, trepar, Efs),
    assertion(memberchk(mensaje(xp_evento, [tuerca, 15]), Efs)),
    assertion(memberchk(ganar_xp(tuerca, 15), Efs)),
    assertion(\+ memberchk(ganar_xp(baldomero, _), Efs)).

test(tras_un_intento_fallido_vale_10, [nondet]) :-
    nueva_partida, estado:aplicar_efectos([contar(intentos_rescate_gato, 1)]),
    eventos:efectos_eleccion(rescate_gato, trepar, Efs),
    assertion(memberchk(ganar_xp(tuerca, 10), Efs)).

test(tras_dos_fallidos_vale_5, [nondet]) :-
    nueva_partida, estado:aplicar_efectos([contar(intentos_rescate_gato, 2)]),
    eventos:efectos_eleccion(rescate_gato, sacudir_arbol, Efs),
    assertion(memberchk(ganar_xp(baldomero, 5), Efs)).

test(un_intento_fallido_no_da_experiencia) :-
    nueva_partida,
    eventos:efectos_eleccion(rescate_gato, cantar, Efs),
    assertion(\+ memberchk(ganar_xp(_, _), Efs)).

test(el_queso_del_evento_no_cambia_por_la_experiencia, [nondet]) :-
    nueva_partida,
    eventos:efectos_eleccion(rescate_gato, hechizo_de_raclette, Efs),
    assertion(memberchk(gastar_queso(cheddar, 0, 1), Efs)).

:- end_tests(la_experiencia_de_un_evento).

:- begin_tests(los_enemigos_con_nivel).

test(un_enemigo_de_nivel_2_tiene_mas_vida_y_ataque, [nondet]) :-
    nueva_partida, juego:comenzar_combate([bandido_torpe], 2, Items),
    assertion(memberchk(msg(enemigos_de_nivel, [2], _), Items)),
    estado:nivel_de(e(bandido_torpe, 1), N), assertion(N == 2),
    estado:vida_maxima(e(bandido_torpe, 1), VM), assertion(VM == 15),
    combate:ataque_base(e(bandido_torpe, 1), A), assertion(A == 6),
    combate:defensa_base(e(bandido_torpe, 1), D), assertion(D == 2).

test(nace_con_la_vida_llena_de_su_nivel, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera], 3, _),
    estado:vida(e(rata_quesera, 1), V), assertion(V == 14).

test(con_nivel_1_no_cambia_nada_ni_se_avisa, [nondet]) :-
    nueva_partida, juego:comenzar_combate([bandido_torpe], 1, Items),
    assertion(\+ memberchk(msg(enemigos_de_nivel, _, _), Items)),
    estado:vida(e(bandido_torpe, 1), V), assertion(V == 12).

test(al_acabar_el_combate_se_olvida_el_nivel_de_los_enemigos, [nondet]) :-
    nueva_partida, juego:comenzar_combate([rata_quesera], 2, _),
    forall(estado:instancia(E, _), estado:aplicar_efectos([dano(E, 99)])),
    combate:efectos_fin(victoria, Efs), estado:aplicar_efectos(Efs),
    assertion(\+ estado:nivel_enemigo(_, _)).

test(el_encuentro_de_una_zona_con_nivel_sale_con_ese_nivel, [nondet]) :-
    set_prolog_flag(banda_encuentros, true),
    nueva_partida,
    mundo:probabilidad_de_encuentro(camino_real, P),
    once(( between(0, 3000, S), combate:tirar_encuentro(camino_real, S, T, _, _), T < P )),
    estado:aplicar_efectos([fijar_semilla(S)]),
    orden(ir(camino_real), _),
    set_prolog_flag(banda_encuentros, false),
    assertion(estado:en_combate(_)),
    forall(estado:instancia(E, _), ( estado:nivel_de(E, N), assertion(N == 2) )).

test(los_combates_de_contrato_no_suben_de_nivel, [nondet]) :-
    nueva_partida,
    orden(aceptar(peaje_del_ganso), _), orden(ir(camino_real), _),
    assertion(estado:marca(combate_de(peaje_del_ganso))),
    forall(estado:instancia(E, _), ( estado:nivel_de(E, N), assertion(N == 1) )).

:- end_tests(los_enemigos_con_nivel).

:- begin_tests(lo_que_se_ve).

test(al_llegar_a_una_zona_de_mas_nivel_se_avisa) :-
    nueva_partida,
    orden(ir(camino_real), Items),
    assertion(memberchk(msg(aviso_nivel, [camino_real, 2, 1], _), Items)).

test(con_la_banda_a_la_altura_no_se_avisa) :-
    nueva_partida,
    forall(compania:miembro(Id), dar_xp(Id, 20)),
    orden(ir(camino_real), Items),
    assertion(\+ memberchk(msg(aviso_nivel, _, _), Items)).

test(en_una_zona_tranquila_no_se_avisa) :-
    nueva_partida,
    orden(ir(aldea), Items),
    assertion(\+ memberchk(msg(aviso_nivel, _, _), Items)).

test(mirar_dice_el_nivel_de_la_zona) :-
    nueva_partida, orden(ir(camino_real), _),
    pantalla(mirar, T), assertion(contiene(T, 'Nivel de la zona: 2')).

test(compania_ensena_nivel_experiencia_y_pasivas) :-
    nueva_partida, dar_xp(baldomero, 55),
    pantalla(compania, T),
    assertion(contiene(T, 'nivel 3 · experiencia 55/90')),
    assertion(contiene(T, 'Escudo de Corteza')),
    assertion(contiene(T, 'nivel 1 · experiencia 0/20')).

test(los_textos_nuevos_se_dicen_con_nombres) :-
    narrador:texto(sube_nivel, [tuerca, 2], 0, T1), assertion(contiene(T1, 'Tuerca sube al nivel 2')),
    narrador:texto(pasiva_nueva, [baldomero, escudo_de_corteza], 0, T2), assertion(contiene(T2, 'Escudo de Corteza')),
    narrador:texto(aviso_nivel, [cuevas, 3, 1], 0, T3), assertion(contiene(T3, 'nivel 3')).

:- end_tests(lo_que_se_ve).
