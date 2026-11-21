% objetivo.pl (pruebas)
% El aviso de contrato nuevo y el objetivo actual. Nacen de una partida real: tras caminar por el mapa aparecio
% en el tablon, sin avisar, el contrato del jefe, y el jugador se perdio en los detalles.
%   (1) contratos:faltas_de/2 y objetivo_actual/2: reglas puras sobre lo que ya sabe el juego;
%   (2) el aviso de que un contrato aparece (visitar el castillo) y de que el objetivo cambia, solo cuando cambia;
%   (3) el texto del objetivo (narrador), la consola, la API y la web.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/objetivo -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/contratos').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% orden(+Cmd, -Items): la orden por el motor
orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% hecho(+Cmd): una orden que debe salir bien (sin error)
hecho(Cmd) :- orden(Cmd, Is), \+ memberchk(error(_), Is).

% En su turno cada miembro usa su habilidad si puede y, si no, ataca (la misma via que el playtest).
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

combatir :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_turno(Cmd)), orden(Cmd, _), combatir
    ;   true
    ).

% combatir_ultimo(-Items): juega el combate y devuelve lo que dijo la ultima orden
combatir_ultimo(Ultimos) :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_turno(Cmd)), orden(Cmd, Is),
        (   estado:en_combate(_), \+ estado:fin_partida(_) -> combatir_ultimo(Ultimos) ; Ultimos = Is )
    ;   Ultimos = []
    ).

% jugar(+Ordenes): cada orden debe salir bien y, si abre un combate, se juega entero
jugar(Ordenes) :- forall(member(C, Ordenes), ( hecho(C), combatir )).

% los dos contratos de la aldea, cobrados en la taberna y con los sueldos pagados
la_aldea :-
    nueva_partida,
    jugar([aceptar(ratas_del_granero), aceptar(gato_en_el_arbol), ir(aldea), elegir(trepar), ir(taberna), pagar]).

:- begin_tests(las_faltas).

test(sin_visitar_el_castillo_el_jefe_pide_la_visita_y_contratos) :-
    nueva_partida,
    contratos:faltas_de(despensa_real, Fs),
    assertion(memberchk(visita(castillo), Fs)),
    assertion(memberchk(contratos(3), Fs)).

test(la_visita_no_se_repite_aunque_este_en_dos_listas) :-
    nueva_partida,
    contratos:faltas_de(despensa_real, Fs),
    findall(x, member(visita(castillo), Fs), Xs), length(Xs, N), assertion(N == 1).

test(una_condicion_cumplida_ya_no_falta) :-
    nueva_partida,
    estado:aplicar_efectos([visitar(castillo)]),
    contratos:faltas_de(despensa_real, Fs),
    assertion(\+ memberchk(visita(castillo), Fs)).

test(un_contrato_sin_condiciones_no_tiene_faltas) :-
    nueva_partida, contratos:faltas_de(ratas_del_granero, Fs), assertion(Fs == []).

test(la_gallina_pide_resolver_el_miedo_a_los_caballos) :-
    nueva_partida, contratos:faltas_de(gallina_noble, Fs), assertion(Fs == [rasgo(teme_caballos)]).

test(el_contrato_final_es_el_que_gana_la_partida) :-
    findall(C, contratos:contrato_final(C), Cs), assertion(Cs == [despensa_real]).

:- end_tests(las_faltas).

:- begin_tests(el_objetivo_actual).

test(al_empezar_hay_que_aceptar_un_contrato_y_no_se_adelanta_el_jefe) :-
    nueva_partida, contratos:objetivo_actual(P, Fs), assertion(P == aceptar), assertion(Fs == []).

test(con_un_contrato_activo_toca_cumplirlo_en_su_zona) :-
    nueva_partida, hecho(aceptar(ratas_del_granero)),
    contratos:objetivo_actual(P, _), assertion(P == cumplir(ratas_del_granero, aldea)).

test(con_algo_resuelto_toca_cobrar) :-
    nueva_partida,
    estado:aplicar_efectos([contrato_aceptar(ratas_del_granero), contrato_resolver(ratas_del_granero, exito)]),
    contratos:objetivo_actual(P, _), assertion(P == cobrar).

test(con_tres_contratos_cobrados_pero_otros_por_hacer_toca_aceptar) :-
    la_aldea,
    jugar([ir(camino_real), aceptar(gallina_noble), ir(taberna)]),
    contratos:contratos_cumplidos(N), assertion(N == 3),
    contratos:objetivo_actual(P, _),
    assertion(P == aceptar).

test(con_todos_los_demas_cobrados_y_el_castillo_sin_visitar_toca_explorar) :-
    nueva_partida,
    forall(member(C, [ratas_del_granero, gato_en_el_arbol, gallina_noble, peaje_del_ganso, fantasma_charlatan]),
           estado:aplicar_efectos([contrato_aceptar(C), contrato_resolver(C, exito), contrato_cobrar(C)])),
    contratos:objetivo_actual(P, Fs),
    assertion(P == explorar(castillo)), assertion(Fs == []).

test(con_el_jefe_visible_pero_sin_contratos_se_dice_cuantos_faltan) :-
    la_aldea,
    jugar([ir(camino_real), ir(castillo)]),
    contratos:objetivo_actual(P, Fs),
    assertion(P == aceptar),
    assertion(Fs == [contratos(1), contrato(gallina_noble), contrato(peaje_del_ganso)]).      % un contrato mas y los dos concretos

test(con_los_contratos_exigidos_cumplidos_y_el_castillo_visto_toca_aceptar_el_jefe) :-
    la_aldea,
    jugar([ir(camino_real), aceptar(gallina_noble), aceptar(peaje_del_ganso), ir(castillo), ir(camino_real), ir(taberna)]),
    contratos:objetivo_actual(P0, _), assertion(P0 == aceptar_final(despensa_real, cuevas)),
    contratos:faltas_de(despensa_real, Fs), assertion(Fs == []).

test(con_el_jefe_aceptado_toca_ir_a_las_cuevas_y_ya_no_falta_nada) :-
    nueva_partida, estado:aplicar_efectos([contrato_aceptar(despensa_real)]),
    contratos:objetivo_actual(P, Fs), assertion(P == cumplir(despensa_real, cuevas)), assertion(Fs == []).

:- end_tests(el_objetivo_actual).

:- begin_tests(el_aviso_de_contrato_nuevo).

test(visitar_el_castillo_avisa_del_contrato_del_jefe) :-
    nueva_partida,
    hecho(ir(camino_real)),
    orden(ir(castillo), Is),
    assertion(memberchk(msg(contrato_nuevo, [despensa_real], 0), Is)).

test(el_aviso_sale_una_sola_vez) :-
    nueva_partida, hecho(ir(camino_real)), hecho(ir(castillo)),
    orden(mirar, I1), assertion(\+ memberchk(msg(contrato_nuevo, _, _), I1)),
    hecho(ir(camino_real)), orden(ir(castillo), I2),
    assertion(\+ memberchk(msg(contrato_nuevo, _, _), I2)).

test(una_orden_que_no_revela_nada_no_avisa) :-
    nueva_partida,
    forall(member(Cmd, [mirar, inventario, contratos, compania, ayuda]),
           (   orden(Cmd, Is),
               assertion(\+ memberchk(msg(contrato_nuevo, _, _), Is)),
               assertion(\+ memberchk(vista(objetivo, _, _), Is)) )).

test(una_orden_que_falla_no_avisa) :-
    nueva_partida, orden(ir(cuevas), Is),
    assertion(memberchk(error(_), Is)),
    assertion(\+ memberchk(msg(contrato_nuevo, _, _), Is)),
    assertion(\+ memberchk(vista(objetivo, _, _), Is)).

test(el_texto_del_aviso_nombra_el_contrato_y_dice_que_es_el_final) :-
    narrador:texto(contrato_nuevo, [despensa_real], 0, T),
    assertion(contiene(T, 'La Despensa Real')), assertion(contiene(T, 'final')).

test(un_contrato_nuevo_cualquiera_tiene_frase_generica) :-
    narrador:texto(contrato_nuevo, [gato_en_el_arbol], 0, T), assertion(contiene(T, 'Gato')).

:- end_tests(el_aviso_de_contrato_nuevo).

:- begin_tests(el_aviso_de_objetivo).

test(aceptar_un_contrato_cambia_el_objetivo_y_lo_dice) :-
    nueva_partida, orden(aceptar(ratas_del_granero), Is),
    assertion(memberchk(vista(objetivo, cumplir(ratas_del_granero, aldea), []), Is)).

test(aceptar_otro_contrato_en_la_misma_zona_no_cambia_el_objetivo) :-
    nueva_partida, hecho(aceptar(ratas_del_granero)),
    orden(aceptar(gato_en_el_arbol), Is),
    assertion(\+ memberchk(vista(objetivo, _, _), Is)).

test(en_combate_no_se_interrumpe_con_el_objetivo) :-
    nueva_partida, hecho(aceptar(ratas_del_granero)), hecho(ir(aldea)),
    assertion(estado:en_combate(_)),
    orden(defender, Is), assertion(\+ memberchk(vista(objetivo, _, _), Is)).

test(aceptar_la_escolta_abre_un_combate_y_en_el_no_se_interrumpe) :-
    la_aldea, jugar([ir(camino_real)]),
    orden(aceptar(gallina_noble), Is),
    assertion(estado:en_combate(_)),
    assertion(\+ memberchk(vista(objetivo, _, _), Is)).

test(al_ganar_la_partida_no_se_pinta_un_objetivo) :-
    la_aldea,
    jugar([ir(camino_real), aceptar(gallina_noble), aceptar(peaje_del_ganso), ir(castillo), aceptar(despensa_real), ir(camino_real)]),
    hecho(ir(cuevas)), combatir_ultimo(Is),
    assertion(estado:fin_partida(victoria(_))),
    assertion(\+ memberchk(vista(objetivo, _, _), Is)).

test(al_volver_a_cobrar_el_objetivo_pasa_a_aceptar) :-
    nueva_partida,
    forall(member(C, [aceptar(ratas_del_granero), ir(aldea)]), ( hecho(C), combatir )),
    orden(ir(taberna), Is),
    assertion(memberchk(vista(objetivo, aceptar, _), Is)).

:- end_tests(el_aviso_de_objetivo).

:- begin_tests(el_texto_del_objetivo).

test(cada_paso_tiene_texto) :-
    forall(member(P, [cobrar, cumplir(ratas_del_granero, aldea), aceptar_final(despensa_real, cuevas), aceptar,
                      explorar(castillo), preparar_final(despensa_real)]),
           (   narrador:texto_objetivo(P, [], T), assertion(atom(T)), assertion(contiene(T, 'Objetivo:')) )).

test(el_texto_dice_donde_y_con_nombres_de_juego_no_ids) :-
    narrador:texto_objetivo(cumplir(ratas_del_granero, aldea), [], T),
    assertion(contiene(T, 'Ratas del Granero')), assertion(contiene(T, 'Aldea Requesón')),
    assertion(\+ contiene(T, 'ratas_del_granero')).

test(las_faltas_se_enumeran_con_el_numero_exacto) :-
    narrador:texto_objetivo(aceptar, [contratos(2), moral(4)], T),
    assertion(contiene(T, 'Para el contrato final te falta')),
    assertion(contiene(T, '2 contratos más cumplidos')),
    assertion(contiene(T, 'moral media a 4')).

test(un_solo_contrato_que_falta_va_en_singular) :-
    narrador:texto_objetivo(aceptar, [contratos(1)], T), assertion(contiene(T, 'un contrato más cumplido')).

test(preparar_el_jefe_dice_te_falta_y_visitar_el_castillo) :-
    narrador:texto_objetivo(preparar_final(despensa_real), [visita(castillo)], T),
    assertion(contiene(T, 'Te falta: visitar el Castillo Camembert')).

test(sin_faltas_no_hay_frase_de_faltas) :-
    narrador:texto_objetivo(aceptar, [], T), assertion(\+ contiene(T, 'te falta')).

:- end_tests(el_texto_del_objetivo).

:- begin_tests(consola_api_y_web).

test(mirar_enseña_el_objetivo) :-
    nueva_partida, main:transcribir([mirar, salir], T),
    assertion(contiene(T, 'Objetivo: acepta un contrato')).

test(la_consola_muestra_el_aviso_del_contrato_nuevo) :-
    main:transcribir([ir(camino_real), ir(castillo), salir], T),
    assertion(contiene(T, 'Nuevo contrato final en el tablón')).

test(el_estado_de_la_api_trae_el_objetivo) :-
    nueva_partida, api:estado_json(E), campo(E, objetivo, O),
    campo(O, texto, T), campo(O, paso, P), campo(O, faltas, Fs),
    assertion(contiene(T, 'Objetivo:')), assertion(P == aceptar), assertion(Fs == []).

test(el_item_objetivo_tiene_su_json) :-
    nueva_partida, api:ejecutar_orden('aceptar(ratas_del_granero)', R), campo(R, items, Is),
    member(I, Is), campo(I, tipo, objetivo), !,
    campo(I, paso, P), campo(I, texto, T),
    assertion(P == 'cumplir(ratas_del_granero, aldea)'), assertion(contiene(T, 'Ratas del Granero')).

test(el_aviso_de_contrato_nuevo_llega_a_la_api_como_msg) :-
    nueva_partida, api:ejecutar_orden('ir(camino_real)', _),
    api:ejecutar_orden('ir(castillo)', R), campo(R, items, Is),
    member(I, Is), campo(I, clave, contrato_nuevo), !,
    campo(I, texto, T), assertion(contiene(T, 'La Despensa Real')).

test(la_web_pinta_el_objetivo_y_el_contrato_nuevo) :-
    setup_call_cleanup(open('web/app.js', read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs0) ),
                       close(S)),
    exclude(==(13), Cs0, Cs),
    atom_codes(J, Cs),
    % el `case "objetivo":` de procesar/3 (el que trae `silencioso`) apila la entrada del log
    assertion(( sub_atom(J, B, _, _, 'case "objetivo":'), sub_atom(J, B, 120, _, W),
                contiene(W, 'silencioso'), contiene(W, 't: "objetivo"') )),
    assertion(contiene(J, 'it.clave === "contrato_nuevo" ? "nuevo"')),
    assertion(contiene(J, 'case "nuevo": return')),
    assertion(contiene(J, 'function bloqueObjetivo()')),
    assertion(contiene(J, 'S.estado.objetivo')).

:- end_tests(consola_api_y_web).
