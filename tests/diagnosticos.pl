% diagnosticos.pl (pruebas)
% T-29: del diagnostico de por_que_no a la frase del narrador. clave_de_diag/2 y claves_de_diag/2
% traducen un diagnostico (sin_clausula, fallo, neg_viola, tras, ninguna, builtin_falso, limite) a
% claves candidatas impide(Hecho) / falla(Meta), de la causa mas profunda a la raiz; se usa la
% primera que tiene frase y, si ninguna, una generica. Los diagnosticos de las pruebas se
% construyen A MANO con el formato de docs/02 6.9 (por_que_no llega en T-32); las pruebas de las
% pruebas reales (neg_viola con una prueba de solve/2) comprueban que la forma coincide.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/diagnosticos -g "run_tests,halt" -t "halt(1)"

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

% ---------------------------------------------------------------------------
% Diagnosticos de ejemplo (a mano)
% ---------------------------------------------------------------------------

% Baldomero no puede atacar al bandido montado: teme a los caballos.
diag_f01(fallo(combate:puede_atacar(baldomero, e(bandido_montado, 1)),
               [cl(1, [], punto((\+ (compania:teme(baldomero, caballo), combate:clase_de(e(bandido_montado, 1), caballo))),
                                neg_viola((compania:teme(baldomero, caballo), combate:clase_de(e(bandido_montado, 1), caballo)),
                                          (regla(teme(baldomero, caballo), 1,
                                                 [hecho(rasgo(baldomero, teme_caballos)), no(ignora_miedo(baldomero))]),
                                           hecho(clase_de(e(bandido_montado, 1), caballo))))))])).

% Pimentina esta en huelga y no puede atacar.
diag_f02(fallo(combate:puede_atacar(pimentina, e(rata_quesera, 1)),
               [cl(1, [], punto((\+ compania:esta_en_huelga(pimentina)),
                                neg_viola(compania:esta_en_huelga(pimentina),
                                          regla(esta_en_huelga(pimentina), 1,
                                                [hecho(moral(pimentina, 0)), hecho(parametro(moral_huelga, 2)), builtin(0 =< 2)]))))])).

% Baldomero esta aturdido.
diag_f03(fallo(combate:puede_atacar(baldomero, e(rata_quesera, 1)),
               [cl(1, [], punto((\+ combate:aturdido(baldomero)),
                                neg_viola(combate:aturdido(baldomero),
                                          regla(aturdido(baldomero), 1, [hecho(alterado(baldomero, aturdido, 2))]))))])).

% Tuerca (retaguardia) no llega al enemigo: falla la regla de la fila, sin mas detalle.
diag_f05(fallo(combate:puede_atacar(tuerca, e(rata_quesera, 1)),
               [cl(1, [], punto(combate:en_fila_alcanzable(tuerca, e(rata_quesera, 1)),
                                fallo(combate:en_fila_alcanzable(tuerca, e(rata_quesera, 1)),
                                      [cl(1, [], punto(estado:fila(tuerca, delantera), sin_clausula(estado:fila(tuerca, delantera))))])))])).

% Pimentina sin queso: la regla puede_habilidad falla en una comparacion (builtin_falso).
diag_f06(fallo(combate:puede_habilidad(pimentina, fondue_flamigera),
               [cl(1, [], punto((0 >= 1),
                                tras(hecho(queso_total(0)), builtin_falso(0 >= 1))))])).

% No hay camino a otra zona.
diag_f07(fallo(compania:puede_viajar(castillo),
               [cl(1, [], punto(mundo:adyacente(taberna, castillo),
                                sin_clausula(mundo:adyacente(taberna, castillo))))])).

% Fuera de la taberna no se descansa.
diag_f08(fallo(economia:puede_descansar,
               [cl(1, [], punto(estado:en_zona(taberna),
                                sin_clausula(estado:en_zona(taberna))))])).

% Un contrato con un requisito de dinero o de rango cualquiera (sin frase propia).
diag_f10a(fallo(contratos:puede_aceptar(despensa_real),
                [cl(1, [], punto(contratos:condicion_cumple(contratos_cumplidos_min(3)),
                                 fallo(contratos:condicion_cumple(contratos_cumplidos_min(3)),
                                       [cl(1, [], punto(0 >= 3, builtin_falso(0 >= 3)))])))])).

% Gallina noble con Baldomero sin venda: la condicion rasgo_no(teme_caballos) se viola.
diag_f10b(fallo(contratos:puede_aceptar(gallina_noble),
                [cl(1, [], punto(contratos:condicion_cumple(rasgo_no(teme_caballos)),
                                 fallo(contratos:condicion_cumple(rasgo_no(teme_caballos)),
                                       [cl(1, [], punto((\+ (compania:activo(baldomero), mundo:rasgo(baldomero, teme_caballos), \+ compania:ignora_miedo(baldomero))),
                                                        neg_viola((compania:activo(baldomero), mundo:rasgo(baldomero, teme_caballos), \+ compania:ignora_miedo(baldomero)),
                                                                  (regla(activo(baldomero), 1, [hecho(vivo(baldomero))]),
                                                                   hecho(rasgo(baldomero, teme_caballos)),
                                                                   no(ignora_miedo(baldomero))))))])))])).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% ---------------------------------------------------------------------------

:- begin_tests(claves_neg_viola).

test(un_hecho_da_una_clave_impide) :-
    claves_de_diag(neg_viola(x, hecho(zzz(1))), [impide(zzz(1))]).

test(una_regla_da_la_raiz_y_luego_sus_hijos_en_preorden) :-
    claves_de_diag(neg_viola(x, regla(a(1), 1, [hecho(b(2)), regla(c(3), 1, [hecho(d(4))])])),
                   [impide(a(1)), impide(b(2)), impide(c(3)), impide(d(4))]).

test(una_conjuncion_se_recorre_de_izquierda_a_derecha) :-
    claves_de_diag(neg_viola(x, (hecho(a), (hecho(b), hecho(c)))),
                   [impide(a), impide(b), impide(c)]).

test(las_ramas_de_un_si_entonces_sino_cuentan) :-
    claves_de_diag(neg_viola(x, regla(a, 1, [si(hecho(c), hecho(t))])),
                   [impide(a), impide(c), impide(t)]).

test(las_metas_que_llegan_con_modulo_se_pelan) :-
    claves_de_diag(neg_viola(x, hecho(mundo:rasgo(baldomero, teme_caballos))),
                   [impide(rasgo(baldomero, teme_caballos))]).

test(una_negacion_o_un_predefinido_dentro_de_la_prueba_no_da_clave) :-
    claves_de_diag(neg_viola(x, (no(g), builtin(1 < 2))), []).

test(con_una_prueba_real_la_raiz_va_primero, [setup(nueva_partida)]) :-
    explicar:solve(compania:teme(baldomero, caballo), Prueba),
    claves_de_diag(neg_viola(x, Prueba),
                   [impide(teme(baldomero, caballo)), impide(rasgo(baldomero, teme_caballos))]).

test(con_la_prueba_real_de_la_huelga, [setup(nueva_partida)]) :-
    aplicar_efecto(mod_moral(pimentina, -10)),
    explicar:solve(compania:esta_en_huelga(pimentina), Prueba),
    claves_de_diag(neg_viola(x, Prueba), [impide(esta_en_huelga(pimentina))|_]),
    clave_de_diag(neg_viola(x, Prueba), impide(esta_en_huelga(pimentina))).

:- end_tests(claves_neg_viola).

:- begin_tests(claves_del_resto).

test(sin_clausula_da_falla_de_la_meta) :-
    claves_de_diag(sin_clausula(compania:puede_viajar(luna)), [falla(puede_viajar(luna))]).

test(sin_clausula_con_una_condicion_de_contrato_prueba_el_envoltorio_y_luego_la_condicion) :-
    claves_de_diag(sin_clausula(condicion_cumple(visita(castillo))),
                   [falla(condicion_cumple(visita(castillo))), falla(visita(castillo))]).

test(un_predefinido_falso_no_da_claves) :-
    claves_de_diag(builtin_falso(1 > 2), []).

test(el_limite_no_da_claves) :-
    claves_de_diag(limite(foo), []).

test(tras_da_las_claves_del_segundo_conjuntivo) :-
    claves_de_diag(tras(hecho(a), sin_clausula(b)), [falla(b)]).

test(tras_anidado_baja_hasta_el_fondo) :-
    claves_de_diag(tras(hecho(a), tras(hecho(b), sin_clausula(c))), [falla(c)]).

test(ninguna_junta_las_dos_ramas_en_orden) :-
    claves_de_diag(ninguna(sin_clausula(a), sin_clausula(b)), [falla(a), falla(b)]).

test(fallo_pone_lo_hondo_luego_el_punto_y_al_final_la_meta) :-
    claves_de_diag(fallo(g(1), [cl(1, [], punto(f(2), sin_clausula(h(3))))]),
                   [falla(h(3)), falla(f(2)), falla(g(1))]).

test(fallo_con_una_negacion_no_repite_el_punto) :-
    claves_de_diag(fallo(g, [cl(1, [], punto((\+ f), neg_viola(f, hecho(f))))]),
                   [impide(f), falla(g)]).

test(fallo_solo_mira_la_primera_candidata) :-
    claves_de_diag(fallo(g, [cl(1, [], punto(f1, sin_clausula(h1))), cl(2, [], punto(f2, sin_clausula(h2)))]),
                   [falla(h1), falla(f1), falla(g)]).

test(fallo_sin_candidatas_da_solo_la_meta) :-
    claves_de_diag(fallo(g, []), [falla(g)]).

test(fallo_con_modulos_los_pela) :-
    claves_de_diag(fallo(a:g, [cl(1, [], punto(b:f, sin_clausula(c:h)))]),
                   [falla(h), falla(f), falla(g)]).

test(una_condicion_de_contrato_en_el_punto_prueba_el_envoltorio_y_luego_la_condicion) :-
    claves_de_diag(fallo(puede_aceptar(c), [cl(1, [], punto(condicion_cumple(moral_media_min(4)), builtin_falso(2 >= 4)))]),
                   [falla(condicion_cumple(moral_media_min(4))), falla(moral_media_min(4)), falla(puede_aceptar(c))]).

test(una_forma_desconocida_da_lista_vacia) :-
    claves_de_diag(patata(1), []).

test(una_variable_da_lista_vacia) :-
    claves_de_diag(_, []).

:- end_tests(claves_del_resto).

:- begin_tests(las_seis_claves_del_nucleo).

test(f01_baldomero_teme_al_caballo) :-
    diag_f01(D),
    clave_de_diag(D, impide(teme(baldomero, caballo))).

test(f02e_huelga) :-
    diag_f02(D),
    clave_de_diag(D, impide(esta_en_huelga(pimentina))).

test(f03a_aturdido) :-
    diag_f03(D),
    clave_de_diag(D, impide(aturdido(baldomero))).

test(f05a_la_retaguardia_no_llega) :-
    diag_f05(D),
    clave_de_diag(D, falla(en_fila_alcanzable(tuerca, e(rata_quesera, 1)))).

test(f06a_sin_queso_no_hay_hechizo) :-
    diag_f06(D),
    clave_de_diag(D, falla(puede_habilidad(pimentina, fondue_flamigera))).

test(f07a_no_hay_camino) :-
    diag_f07(D),
    clave_de_diag(D, falla(puede_viajar(castillo))).

test(f08a_solo_se_descansa_en_la_taberna) :-
    diag_f08(D),
    clave_de_diag(D, falla(puede_descansar)).

test(f10a_un_requisito_sin_frase_cae_en_la_regla_puede_aceptar) :-
    diag_f10a(D),
    clave_de_diag(D, falla(puede_aceptar(despensa_real))).

test(f10b_el_rasgo_de_baldomero_gana_a_la_regla_general) :-
    diag_f10b(D),
    clave_de_diag(D, impide(rasgo(baldomero, teme_caballos))).

test(f10b_esta_por_delante_de_f10a_en_la_lista) :-
    diag_f10b(D),
    claves_de_diag(D, Cs),
    once(nth0(I1, Cs, impide(rasgo(baldomero, teme_caballos)))),
    once(nth0(I2, Cs, falla(puede_aceptar(gallina_noble)))),
    I1 < I2.

test(los_diagnosticos_de_ejemplo_acaban_con_la_meta_que_falla) :-
    forall(member(Gen, [diag_f05, diag_f06, diag_f07, diag_f08, diag_f10a, diag_f10b]),
           (   call(Gen, fallo(G0, _) ),
               strip_module(G0, _, G),
               call(Gen, D),
               claves_de_diag(D, Cs),
               last(Cs, falla(G))
           )).

:- end_tests(las_seis_claves_del_nucleo).

:- begin_tests(las_frases_del_nucleo).

test(f01a_texto) :-
    diag_f01(D), comentario_diag(D, ambos, 0, T),
    T == 'Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.'.

test(f02e_dice_el_nombre_de_quien_esta_en_huelga) :-
    diag_f02(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Madame Pimentina'), contiene(T, 'Huelga Sagrada').

test(f03a_dice_el_nombre_de_quien_esta_aturdido) :-
    diag_f03(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Sir Baldomero le dan vueltas').

test(f05a_dice_quien_no_llega_a_quien) :-
    diag_f05(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Tuerca no llega hasta la Rata Quesera').

test(las_frases_con_nombre_valen_para_cualquiera) :-
    comentario_diag(neg_viola(x, regla(esta_en_huelga(baldomero), 1, [])), ambos, 0, T1),
    contiene(T1, 'Sir Baldomero anda en el sótano'),
    comentario_diag(neg_viola(x, regla(aturdido(rufino), 1, [])), ambos, 0, T2),
    contiene(T2, 'Rufino le dan vueltas'),
    comentario_diag(fallo(combate:puede_atacar(pimentina, e(bandido_torpe, 2)),
                          [cl(1, [], punto(en_fila_alcanzable(pimentina, e(bandido_torpe, 2)), sin_clausula(x)))]),
                    ambos, 0, T3),
    contiene(T3, 'Madame Pimentina no llega hasta el Bandido Torpe').

test(el_hechizo_sin_queso_es_solo_de_pimentina) :-
    clave_de_diag(fallo(puede_habilidad(rufino, silencio), [cl(1, [], punto(x, builtin_falso(1 > 2)))]),
                  generica(fallo)).

test(f06a_sin_queso) :-
    diag_f06(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Sin queso no hay hechizo').

test(f07a_dice_la_zona_con_su_articulo) :-
    comentario_diag(sin_clausula(compania:puede_viajar(aldea)), ambos, 0, T),
    contiene(T, 'No hay camino de aquí a la Aldea Requesón').

test(f07a_con_la_contraccion) :-
    comentario_diag(fallo(compania:puede_viajar(camino_real),
                          [cl(1, [], punto(mundo:adyacente(taberna, camino_real), sin_clausula(x)))]),
                    ambos, 0, T),
    contiene(T, 'de aquí al Camino Real').

test(f08a_descansar_en_la_taberna) :-
    diag_f08(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Descansar se hace en la taberna').

test(f10a_contrato_no_aceptable) :-
    diag_f10a(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'no se puede aceptar todavía').

test(f10b_escolta_sin_miedo_a_los_caballos) :-
    diag_f10b(D), comentario_diag(D, ambos, 0, T),
    contiene(T, 'Lady Clotilde exige escolta').

test(cada_clave_del_nucleo_tiene_texto_en_los_dos_niveles) :-
    forall(( member(Gen, [diag_f01, diag_f02, diag_f03, diag_f05, diag_f06, diag_f07, diag_f08, diag_f10a, diag_f10b]),
             member(Nivel, [resumido, detallado]) ),
           (   call(Gen, D),
               comentario_diag(D, Nivel, 0, T),
               atom(T), T \== ''
           )).

test(el_texto_empieza_en_mayuscula) :-
    forall(member(Gen, [diag_f01, diag_f02, diag_f03, diag_f05, diag_f06, diag_f07, diag_f08, diag_f10a, diag_f10b]),
           (   call(Gen, D),
               comentario_diag(D, ambos, 0, T),
               sub_atom(T, 0, 1, _, P),
               char_type(P, upper)
           )).

test(el_mismo_diagnostico_da_siempre_el_mismo_texto) :-
    diag_f10b(D),
    comentario_diag(D, ambos, 3, T1),
    comentario_diag(D, ambos, 3, T2),
    T1 == T2.

test(las_marcas_de_las_frases_coinciden_con_sus_argumentos) :-
    forall(( narrador:frase(K, _, Plantilla), ( K = impide(_) ; K = falla(_) ) ),
           (   Plantilla = (Formato-Args)
           ->  atomic_list_concat(Partes, '~w', Formato),
               length(Partes, L), N is L - 1,
               length(Args, N)
           ;   atom(Plantilla)
           )).

:- end_tests(las_frases_del_nucleo).

:- begin_tests(reservas).

test(un_hecho_sin_frase_cae_en_generica_impide) :-
    clave_de_diag(neg_viola(x, hecho(zzz(1))), generica(impide)).

test(un_fallo_sin_frase_cae_en_generica_fallo) :-
    clave_de_diag(fallo(zzz, [cl(1, [], punto(yyy, sin_clausula(yyy)))]), generica(fallo)).

test(un_fallo_con_una_negacion_sin_frase_cae_en_generica_impide) :-
    clave_de_diag(fallo(zzz, [cl(1, [], punto((\+ yyy), neg_viola(yyy, hecho(yyy))))]), generica(impide)).

test(un_predefinido_falso_cae_en_generica_fallo) :-
    clave_de_diag(builtin_falso(1 > 2), generica(fallo)).

test(el_limite_cae_en_generica_fallo) :-
    clave_de_diag(limite(foo), generica(fallo)).

test(una_forma_desconocida_cae_en_generica_fallo) :-
    clave_de_diag(patata, generica(fallo)).

test(las_reservas_tienen_texto) :-
    comentario_diag(neg_viola(x, hecho(zzz)), ambos, 0, T1),
    contiene(T1, 'Algo lo impide'),
    comentario_diag(builtin_falso(1 > 2), ambos, 0, T2),
    contiene(T2, 'No se cumple').

test(siempre_hay_texto_para_cualquier_diagnostico) :-
    forall(member(D, [sin_clausula(a), builtin_falso(a), limite(a), tras(hecho(a), limite(b)),
                      ninguna(limite(a), limite(b)), fallo(g, []), neg_viola(x, hecho(a)), patata, _]),
           (   comentario_diag(D, ambos, 0, T), atom(T), T \== '' )).

test(la_clave_de_diag_nunca_deja_variables_sin_resolver_en_la_generica) :-
    clave_de_diag(builtin_falso(1 > 2), K),
    ground(K).

test(una_clave_candidata_con_variable_libre_no_se_liga_a_la_frase) :-
    D = sin_clausula(puede_viajar(_Z)),
    clave_de_diag(D, falla(puede_viajar(Z2))),
    var(Z2).

test(el_diagnostico_no_se_modifica) :-
    diag_f10b(D0),
    copy_term(D0, D1),
    clave_de_diag(D0, _),
    D0 =@= D1.

:- end_tests(reservas).

:- begin_tests(el_narrador_sigue_puro).

test(el_narrador_no_importa_a_explicar) :-
    read_file_to_terms('src/narrador.pl', Terminos, [encoding(utf8)]),
    \+ ( member((:- use_module(M)), Terminos), M == explicar ),
    \+ ( member((:- use_module(M, _)), Terminos), M == explicar ).

test(las_claves_de_por_que_no_no_se_mezclan_con_las_de_explicar) :-
    comentario(puede_descansar, ambos, 0, T1),
    comentario(falla(puede_descansar), ambos, 0, T2),
    T1 \== T2.

:- end_tests(el_narrador_sigue_puro).
