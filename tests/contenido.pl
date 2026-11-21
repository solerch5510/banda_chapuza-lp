% contenido.pl (pruebas)
% La ampliacion de contenido (docs/13-ampliacion.md §3): tres contratos nuevos (el peaje del ganso, el fantasma
% charlatan y la paz del moho) y dos enemigos nuevos (el ganso del peaje y la seta belicosa), y un cambio de regla:
% el jefe ya no se abre con CUALQUIER tres contratos sino que exige dos concretos (la escolta de Clotilde y el peaje).
%   (1) un validador de contenido para TODOS los contratos y enemigos (el de manana tambien); (2) los enemigos nuevos;
%   (3) cada contrato nuevo, jugado; (4) lo que exige el jefe; (5) lo que mide el simulador.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/contenido -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

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
:- use_module('../src/main').
:- use_module('../herramientas/simulador').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% la politica de combate del playtest: habilidad si se puede, ataque si no, defensa como ultimo recurso
objetivo_fuerte(T) :-
    member(T, [gran_roquefort, bandido_montado, ganso_de_peaje, seta_belicosa, bandido_torpe, moho_saltarin, rata_quesera]),
    estado:instancia(E, T), compania:vivo(E), !.

orden_de_turno(Cmd) :-
    estado:cola_turnos([A|_]),
    mundo:habilidad_de(A, H),
    objetivo_fuerte(T),
    (   combate:objetivo_de_habilidad(H, ninguno)
    ->  Cmd = habilidad
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_habilidad(A, H, E)
    ->  Cmd = habilidad(T)
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_atacar(A, E)
    ->  Cmd = atacar(T)
    ;   Cmd = defender
    ).

combatir_juntando(Todos) :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_turno(Cmd)), orden(Cmd, Is), combatir_juntando(Resto), append(Is, Resto, Todos)
    ;   Todos = []
    ).

% jugar(+Orden, -Items): la orden y, si abre un combate, el combate entero (todo lo que dijo)
jugar(Cmd, Items) :- orden(Cmd, I0), combatir_juntando(I1), append(I0, I1, Items).

% cerrar(+C, +R): un contrato cumplido y cobrado (para preparar el jefe)
cerrar(C, R) :- estado:aplicar_efectos([contrato_aceptar(C), contrato_resolver(C, R), contrato_cobrar(C)]).

:- begin_tests(el_validador_de_contenido).

test(cada_contrato_tiene_todo_lo_que_necesita) :-
    forall(contratos:contrato(C, Zona, _, _, _),
           (   assertion(mundo:zona(Zona, _)),
               assertion(contratos:oferente(C, _, _)),
               assertion(contratos:aparece(C, _)),
               assertion(contratos:resolucion(C, _, _)),
               assertion(contratos:consecuencia(C, _, _)),
               assertion(contratos:dificultad(C, _)),
               assertion(narrador:descripcion_contrato(C, _)),
               narrador:nombre_visible(C, N), assertion(N \== C) )).

test(cada_resultado_posible_de_un_contrato_tiene_consecuencias) :-
    forall(contratos:resolucion(C, R, _), assertion(contratos:consecuencia(C, R, _))).

test(cada_contrato_acaba_con_un_resultado_siempre_posible) :-
    % la ultima resolucion de cada contrato no pide nada (es la de por defecto) o es la unica
    forall(contratos:contrato(C, _, _, _, _),
           (   findall(Cs, contratos:resolucion(C, _, Cs), L), last(L, Ultima), assertion(Ultima == []) )).

test(todos_los_enemigos_de_los_contratos_existen_en_el_bestiario) :-
    forall(( contratos:contrato(C, _, _, _, _), contratos:via_objetivo(C, combate(G)), member(T, G) ),
           assertion(mundo:enemigo(T, _, _, _))).

test(cada_enemigo_tiene_clase_fila_alcance_nombre_y_se_puede_numerar) :-
    forall(mundo:enemigo(T, _, _, _),
           (   assertion(mundo:clase(T, _)), assertion(mundo:fila_preferida(T, _)), assertion(mundo:alcance(T, _)),
               narrador:nombre_visible(T, N), assertion(N \== T) )).

test(cada_evento_de_contrato_tiene_texto_opciones_y_frases) :-
    forall(eventos:evento_de_contrato(_, E, _),
           (   assertion(narrador:descripcion_evento(E, _)),
               assertion(narrador:frase(suceso(evento_abre(E)), _, _)),
               forall(eventos:opcion_evento(E, Op, _, _, _, _),
                      (   assertion(narrador:descripcion_opcion(E, Op, _)),
                          assertion(narrador:frase(suceso(evento_elige(E, Op)), _, _)) )),
               assertion(narrador:frase(suceso(intento_fallido(E, 0)), _, _)) )).

test(cada_evento_tiene_una_salida_buena_y_un_limite_de_intentos) :-
    forall(eventos:evento_de_contrato(_, E, _),
           (   assertion(eventos:intentos_maximos(E, _)),
               assertion(eventos:opcion_evento(E, _, _, _, _, resuelve)) )).

test(la_paga_de_cada_contrato_cumple_la_formula_y_compensa_el_viaje) :-
    nueva_partida, economia:racion_diaria(Racion),
    forall(( contratos:contrato(C, _, _, _, _), \+ contratos:contrato_final(C) ),
           (   contratos:pago_de(C, N), contratos:dias_de_ruta(C, D), Coste is Racion * D,
               assertion(N >= 12), assertion(N > Coste) )).

test(solo_hay_un_contrato_final) :-
    findall(C, contratos:contrato_final(C), Cs), assertion(Cs == [despensa_real]).

:- end_tests(el_validador_de_contenido).

:- begin_tests(los_enemigos_nuevos).

test(el_ganso_y_la_seta_estan_en_el_bestiario_con_sus_cifras) :-
    mundo:enemigo(ganso_de_peaje, vida(16), ataque(6), defensa(2)),
    mundo:enemigo(seta_belicosa, vida(14), ataque(5), defensa(1)).

test(el_ganso_es_un_ave_y_la_seta_un_hongo) :-
    mundo:clase(ganso_de_peaje, ave), mundo:clase(seta_belicosa, hongo).

test(ninguno_es_un_caballo_asi_que_baldomero_los_pelea_sin_miedo) :-
    nueva_partida, estado:aplicar_efectos([iniciar_combate([ganso_de_peaje, seta_belicosa])]),
    forall(member(T, [ganso_de_peaje, seta_belicosa]),
           ( estado:instancia(E, T), assertion(combate:puede_atacar(baldomero, E)) )).

test(entre_los_comunes_sus_cifras_van_entre_las_del_bandido_y_el_montado) :-
    mundo:enemigo(bandido_torpe, vida(V0), ataque(A0), _),
    mundo:enemigo(bandido_montado, vida(V1), ataque(A1), _),
    forall(member(T, [ganso_de_peaje, seta_belicosa]),
           (   mundo:enemigo(T, vida(V), ataque(A), _),
               assertion(V > V0), assertion(V < V1), assertion(A >= A0), assertion(A =< A1) )).

test(el_ganso_suelta_el_peaje_que_cobraba_y_la_seta_a_veces_un_queso) :-
    mundo:botin(ganso_de_peaje, 1, P1), assertion(P1 == 100),
    mundo:botin(seta_belicosa, 1, P2), assertion(P2 == 50).

test(su_nombre_visible_lleva_articulo) :-
    narrador:nombre_visible(ganso_de_peaje, A), assertion(contiene(A, 'Ganso del Peaje')),
    narrador:nombre_visible(seta_belicosa, B), assertion(contiene(B, 'Seta Belicosa')).

:- end_tests(los_enemigos_nuevos).

:- begin_tests(el_peaje_del_ganso).

test(se_ofrece_desde_el_principio_en_el_camino_real) :-
    nueva_partida, assertion(contratos:visible(peaje_del_ganso)),
    orden(ir(camino_real), _), assertion(contratos:disponible(peaje_del_ganso)),
    assertion(contratos:puede_aceptar(peaje_del_ganso)).

test(se_cumple_derrotando_al_ganso_y_a_un_bandido) :-
    nueva_partida, orden(ir(camino_real), _),
    orden(aceptar(peaje_del_ganso), Items),
    assertion(memberchk(msg(objetivo, [peaje_del_ganso], _), Items)),
    assertion(estado:en_combate(_)),
    findall(T, ( estado:instancia(_, T) ), Ts), msort(Ts, S),
    assertion(S == [bandido_torpe, ganso_de_peaje]).

test(ganar_el_combate_lo_deja_cumplido_con_exito_y_por_cobrar) :-
    nueva_partida, orden(ir(camino_real), _), jugar(aceptar(peaje_del_ganso), _),
    assertion(estado:contrato_por_cobrar(peaje_del_ganso, exito)).

test(se_cobra_en_la_taberna_con_la_paga_de_la_formula) :-
    nueva_partida, orden(ir(camino_real), _), jugar(aceptar(peaje_del_ganso), _),
    contratos:pago_de(peaje_del_ganso, Pago),
    orden(ir(taberna), Items),
    assertion(memberchk(msg(cobra, [peaje_del_ganso], _), Items)),
    economia:queso_total(Q), assertion(Q >= Pago).

test(paga_catorce_quesos) :-
    contratos:pago_de(peaje_del_ganso, N), assertion(N == 14).

:- end_tests(el_peaje_del_ganso).

:- begin_tests(el_fantasma_charlatan).

test(se_ofrece_en_la_aldea_si_la_moral_llega_a_cuatro) :-
    nueva_partida, assertion(contratos:puede_aceptar(fantasma_charlatan)),
    estado:aplicar_efectos([mod_moral(baldomero, -6), mod_moral(pimentina, -6), mod_moral(rufino, -6), mod_moral(tuerca, -6)]),
    assertion(\+ contratos:puede_aceptar(fantasma_charlatan)).

test(al_aceptarlo_en_la_aldea_se_abre_el_evento_con_sus_cuatro_opciones) :-
    nueva_partida, orden(ir(aldea), _),
    orden(aceptar(fantasma_charlatan), Items),
    assertion(memberchk(vista(evento, escuchar_al_fantasma, 3, Ops), Items)),
    assertion(length(Ops, 4)).

test(escuchar_su_historia_lo_resuelve_con_exito) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    orden(elegir(escuchar_la_historia), _),
    assertion(estado:contrato_por_cobrar(fantasma_charlatan, exito)).

test(exorcizarlo_cuesta_un_queso_y_lo_resuelve_a_medias) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    economia:queso_total(Q0),
    orden(elegir(exorcizar_con_fondue), _),
    economia:queso_total(Q1), assertion(Q1 =:= Q0 - 1),
    assertion(estado:contrato_por_cobrar(fantasma_charlatan, a_medias)).

test(exigirle_que_se_vaya_gasta_un_intento_y_no_lo_resuelve) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    orden(elegir(exigirle_que_se_vaya), Items),
    assertion(\+ memberchk(error(_), Items)),
    assertion(estado:contrato_activo(fantasma_charlatan)),
    eventos:intentos_restantes(escuchar_al_fantasma, Q), assertion(Q == 2).

test(agotar_los_intentos_es_un_fracaso_y_baja_la_moral) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    estado:moral(rufino, M0),
    orden(elegir(exigirle_que_se_vaya), _), orden(elegir(fingir_que_se_escucha), _), orden(elegir(exigirle_que_se_vaya), Items),
    assertion(memberchk(msg(contrato_resuelto, [fantasma_charlatan, fracaso], _), Items)),
    estado:moral(rufino, M1), assertion(M1 < M0).

test(el_exito_da_la_paga_la_pocion_y_un_amigo_fantasma) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    orden(elegir(escuchar_la_historia), _),
    orden(ir(taberna), _),
    assertion(estado:lleva(compania, pocion, 1)), assertion(estado:marca(fantasma_amigo)).

test(a_medias_cobra_la_mitad_y_la_pocion_pero_no_el_amigo) :-
    nueva_partida,
    once(contratos:efectos_cobro_de(fantasma_charlatan, a_medias, Efs)),
    contratos:pago_de(fantasma_charlatan, Pago), Mitad is Pago // 2,
    assertion(memberchk(ganar_queso(cheddar, 0, Mitad), Efs)),
    assertion(memberchk(ganar_objeto(compania, pocion, 1), Efs)),
    assertion(\+ memberchk(marcar(fantasma_amigo), Efs)).

test(si_ese_miembro_ha_caido_la_opcion_no_esta) :-
    nueva_partida, orden(ir(aldea), _), orden(aceptar(fantasma_charlatan), _),
    estado:aplicar_efectos([dano(rufino, 999)]),
    orden(elegir(escuchar_la_historia), Items),
    assertion(Items = [error(opcion_no_disponible(escuchar_la_historia))]).

test(los_textos_del_evento_no_hablan_del_gato) :-
    forall(member(Op, [escuchar_la_historia, exorcizar_con_fondue, exigirle_que_se_vaya, fingir_que_se_escucha]),
           (   narrador:texto(evento_elige, [escuchar_al_fantasma, Op], 0, T), assertion(\+ contiene(T, 'gato')) )),
    narrador:texto(intento_fallido, [escuchar_al_fantasma, 0], 0, F), assertion(\+ contiene(F, 'gato')).

:- end_tests(el_fantasma_charlatan).

:- begin_tests(la_paz_del_moho).

test(no_se_ve_hasta_pasar_por_el_bosque) :-
    nueva_partida, assertion(\+ contratos:visible(paz_del_moho)),
    estado:aplicar_efectos([visitar(bosque)]), assertion(contratos:visible(paz_del_moho)).

test(se_ofrece_en_la_aldea_o_en_la_taberna_y_no_en_el_bosque) :-
    nueva_partida, estado:aplicar_efectos([visitar(bosque)]),
    assertion(contratos:disponible(paz_del_moho)),                 % en la taberna
    orden(ir(aldea), _), assertion(contratos:disponible(paz_del_moho)),
    orden(ir(bosque), _), assertion(\+ contratos:disponible(paz_del_moho)).

test(se_cumple_contra_dos_setas_y_un_moho_en_el_bosque) :-
    nueva_partida, estado:aplicar_efectos([visitar(bosque)]),
    orden(aceptar(paz_del_moho), _), orden(ir(aldea), _), orden(ir(bosque), Items),
    assertion(memberchk(msg(objetivo, [paz_del_moho], _), Items)),
    findall(T, estado:instancia(_, T), Ts), msort(Ts, S),
    assertion(S == [moho_saltarin, seta_belicosa, seta_belicosa]).

test(paga_veintiun_quesos_porque_el_bosque_esta_lejos) :-
    contratos:pago_de(paz_del_moho, N), assertion(N == 21),
    contratos:dias_de_ruta(paz_del_moho, D), assertion(D == 4).

:- end_tests(la_paz_del_moho).

:- begin_tests(lo_que_exige_el_jefe).

test(con_tres_contratos_cualesquiera_ya_no_basta) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(gato_en_el_arbol, exito), cerrar(fantasma_charlatan, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    contratos:contratos_cumplidos(N), assertion(N >= 3),
    assertion(\+ contratos:puede_aceptar(despensa_real)).

test(la_escolta_y_el_peaje_en_concreto_lo_abren) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(gallina_noble, exito), cerrar(peaje_del_ganso, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    assertion(contratos:puede_aceptar(despensa_real)).

test(sin_el_peaje_aunque_haya_muchos_cumplidos_no) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(gato_en_el_arbol, exito), cerrar(gallina_noble, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    assertion(\+ contratos:puede_aceptar(despensa_real)),
    contratos:faltas_de(despensa_real, Fs), assertion(Fs == [contrato(peaje_del_ganso)]).

test(sin_la_escolta_tampoco) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(gato_en_el_arbol, exito), cerrar(peaje_del_ganso, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    contratos:faltas_de(despensa_real, Fs), assertion(Fs == [contrato(gallina_noble)]).

test(una_escolta_a_medias_cuenta_como_cumplida) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(gallina_noble, a_medias), cerrar(peaje_del_ganso, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    assertion(contratos:puede_aceptar(despensa_real)).

test(una_escolta_fracasada_no_cuenta) :-
    nueva_partida,
    cerrar(ratas_del_granero, exito), cerrar(peaje_del_ganso, exito), cerrar(gato_en_el_arbol, exito),
    estado:aplicar_efectos([contrato_aceptar(gallina_noble), contrato_resolver(gallina_noble, fracaso),
                            visitar(castillo)]),
    assertion(\+ contratos:puede_aceptar(despensa_real)).

test(el_objetivo_dice_que_contratos_concretos_faltan) :-
    nueva_partida, estado:aplicar_efectos([visitar(castillo)]),
    contratos:faltas_de(despensa_real, Fs),
    assertion(memberchk(contrato(gallina_noble), Fs)), assertion(memberchk(contrato(peaje_del_ganso), Fs)),
    narrador:texto_objetivo(aceptar, Fs, T),
    assertion(contiene(T, 'cumplir «Lady Clotilde Plumífera»')), assertion(contiene(T, 'cumplir «El Peaje del Ganso»')).

test(por_que_no_explica_que_falta_un_contrato_concreto) :-
    nueva_partida, cerrar(ratas_del_granero, exito), cerrar(gato_en_el_arbol, exito), cerrar(gallina_noble, exito),
    estado:aplicar_efectos([visitar(castillo)]),
    orden(por_que_no(aceptar(despensa_real)), Items), assertion(Items = [vista(diag, aceptar(despensa_real), _)]).

test(la_frase_de_que_falta_un_contrato_nombra_cual) :-
    narrador:comentario(falla(cumplido(peaje_del_ganso)), ambos, 0, T), assertion(contiene(T, 'El Peaje del Ganso')).

:- end_tests(lo_que_exige_el_jefe).

:- begin_tests(lo_que_mide_el_simulador).

test(la_campana_de_ejemplo_sigue_ganandose_con_los_cinco_contratos) :-
    ruta_de_referencia('examples/campana-comandos.txt', r(Fin, _, _, _)),
    assertion(Fin == victoria), assertion(estado:contrato_cumplido(peaje_del_ganso)).

test(un_jugador_con_plan_acaba_haciendo_el_peaje_antes_del_jefe) :-
    episodio(plan(0, 2), 5001, 400, r(victoria, _, _, _)),
    assertion(estado:contrato_cumplido(peaje_del_ganso)), assertion(estado:contrato_cumplido(gallina_noble)).

test(el_juego_sigue_siendo_ganable_con_el_contenido_nuevo) :-
    findall(x, ( between(1, 30, I), S is 5100 + I, episodio(plan(10, 2), S, 400, r(victoria, _, _, _)) ), Gs),
    length(Gs, N), assertion(N >= 24).

:- end_tests(lo_que_mide_el_simulador).
