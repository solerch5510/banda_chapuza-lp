% campana.pl (pruebas)
% T-28: la partida minima de principio a fin. Los finales (chapuza, derrota_combate, derrota_hambre),
% la victoria al derrotar al Gran Roquefort, la fase final, y partidas COMPLETAS escritas como una
% lista de comandos: aceptar los contratos, viajar, combatir, cobrar, llegar al jefe y ganar o perder.
% Tambien comprueba que la partida es reproducible (misma lista de comandos, mismo estado final) y
% que el comando provisional pelear ya no existe.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/campana -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/eventos').
:- use_module('../src/explicar').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

% Ataca a lo que haya hasta que acabe el combate (o la partida). Cada miembro, en su turno.
pelea_hasta_el_final(0) :- !.
pelea_hasta_el_final(N) :-
    (   ( \+ estado:en_combate(_) ; estado:fin_partida(_) )
    ->  true
    ;   (   member(Obj, [gran_roquefort, moho_saltarin, bandido_montado, bandido_torpe, rata_quesera]),
            ordena(atacar(Obj), I), \+ I = [error(_)|_]
        ->  true
        ;   ordena(defender, _)
        ),
        N1 is N - 1,
        pelea_hasta_el_final(N1)
    ).

% Un paso de la campana: un comando y, si empezo un combate, se pelea hasta el final.
paso(Cmd) :-
    ordena(Cmd, Items),
    \+ Items = [error(_)|_],
    pelea_hasta_el_final(150).

% La campana entera, la ruta de docs/04: aldea (ratas y gato) -> taberna (cobrar, pagar) ->
% camino real (gallina) -> castillo (el rey) -> cuevas (el jefe).
campana :-
    nueva_partida,
    paso(aceptar(ratas_del_granero)),
    paso(aceptar(gato_en_el_arbol)),
    paso(ir(aldea)),
    paso(elegir(trepar)),
    paso(ir(taberna)),
    paso(pagar),
    paso(ir(camino_real)),
    paso(aceptar(gallina_noble)),
    paso(ir(castillo)),
    paso(aceptar(despensa_real)),
    paso(ir(camino_real)),
    paso(ir(cuevas)).

% Para ver lo que se lee: la campana hasta el jefe y luego cada golpe con su texto.
nueva_partida_en_el_jefe_y_ganar(Texto) :-
    % la misma campana, pero capturando lo que se ve en el ultimo combate
    nueva_partida,
    paso(aceptar(ratas_del_granero)), paso(aceptar(gato_en_el_arbol)), paso(ir(aldea)), paso(elegir(trepar)),
    paso(ir(taberna)), paso(pagar), paso(ir(camino_real)), paso(aceptar(gallina_noble)), paso(ir(castillo)),
    paso(aceptar(despensa_real)), paso(ir(camino_real)),
    ordena(ir(cuevas), _),
    findall(T, ( between(1, 150, _), \+ estado:fin_partida(_), estado:en_combate(_), golpe_con_texto(T) ), Ts),
    atomic_list_concat(Ts, '\n', Texto).

golpe_con_texto(Texto) :-
    (   member(Obj, [gran_roquefort, moho_saltarin, bandido_montado, bandido_torpe, rata_quesera]),
        ejecutar(atacar(Obj), R), R = resultado(I), \+ I = [error(_)|_]
    ->  with_output_to(atom(Texto), ui:mostrar(R))
    ;   pantalla(defender, Texto)
    ).

:- begin_tests(los_finales).

test(la_version_minima_solo_tiene_el_final_chapuza) :-
    contratos:orden_finales(Ids),
    Ids == [chapuza],
    contratos:final(chapuza, Cs),
    Cs == [].

test(el_final_por_defecto_es_chapuza, [setup(nueva_partida), nondet]) :-
    contratos:final_de_la_partida(F),
    F == chapuza.

test(hay_un_unico_final_posible, [setup(nueva_partida)]) :-
    findall(F, contratos:final_de_la_partida(F), Fs),
    Fs == [chapuza].

test(solo_despensa_real_gana_la_partida) :-
    forall(( contratos:consecuencia(C, R, Efs), memberchk(victoria, Efs) ),
           ( C == despensa_real, R == exito )).

test(la_victoria_se_traduce_a_fin_y_mensaje, [setup(nueva_partida), nondet]) :-
    contratos:efectos_resolucion(despensa_real, exito, Efs),
    memberchk(fin(victoria(chapuza)), Efs),
    memberchk(mensaje(final, [chapuza]), Efs).

test(ninguna_otra_resolucion_acaba_la_partida, [setup(nueva_partida)]) :-
    forall(( contratos:consecuencia(C, R, _), \+ ( C == despensa_real, R == exito ),
             contratos:efectos_resolucion(C, R, Efs) ),
           \+ memberchk(fin(_), Efs)).

test(la_recompensa_de_la_despensa_real_sigue_siendo_de_cuarenta, [setup(nueva_partida), nondet]) :-
    contratos:efectos_cobro_de(despensa_real, exito, Efs),
    memberchk(ganar_queso(cheddar, 0, 40), Efs).

test(el_primer_fin_manda, [setup(nueva_partida)]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    aplicar_efecto(fin(derrota(derrota_hambre))),
    findall(F, estado:fin_partida(F), Fs),
    Fs == [victoria(chapuza)].

test(con_la_partida_acabada_la_fase_es_fin, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    estado:fase(fin).

test(los_tres_finales_tienen_texto, [nondet]) :-
    narrador:texto(final, [chapuza], 0, T1),
    narrador:texto(derrota_combate, [], 0, T2),
    narrador:texto(fin_hambre, [], 0, T3),
    sub_atom(T1, _, _, _, 'Chapuza de toda la vida'),
    sub_atom(T2, _, _, _, 'Cuajados'),
    sub_atom(T3, _, _, _, 'Sin ración'),
    forall(member(T, [T1, T2, T3]), sub_atom(T, _, _, _, 'Fin de la partida')).

:- end_tests(los_finales).

:- begin_tests(la_fase_final).

test(en_la_fase_final_solo_valen_ayuda_explicar_y_salir) :-
    comandos_disponibles(fin, Cs),
    msort(Cs, S),
    S == [ayuda, explicar, salir].

test(cualquier_otro_comando_se_rechaza, [setup(nueva_partida)]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    forall(member(Cmd, [mirar, ir(aldea), descansar, pagar, contratos, aceptar(ratas_del_granero),
                        elegir(trepar), atacar(rata_quesera), defender, compania, inventario]),
           (   ordena(Cmd, Items), Items = [error(fuera_de_fase(_, fin))] )).

test(ayuda_y_salir_siguen_funcionando, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(fin(derrota(derrota_hambre))),
    ordena(ayuda, [vista(ayuda, _)]),
    ordena(salir, [salir]).

test(el_mensaje_de_la_fase_final_es_legible, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(fin(victoria(chapuza))),
    pantalla(mirar, Texto),
    sub_atom(Texto, _, _, _, 'La partida ha terminado').

:- end_tests(la_fase_final).

:- begin_tests(pelear_ya_no_existe).

test(no_es_un_comando, [setup(nueva_partida)]) :-
    validar_comando(pelear(rata_quesera), Res),
    Res = error(no_entiendo(pelear(rata_quesera))).

test(ejecutarlo_no_hace_nada, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    ordena(pelear(rata_quesera), Items),
    foto_estado(Despues),
    Items = [error(no_entiendo(_))],
    Antes =@= Despues.

test(no_sale_en_ninguna_ayuda) :-
    forall(member(Fase, [taberna, exploracion, combate, fin]),
           (   comandos_disponibles(Fase, Cs), \+ memberchk(pelear, Cs) )).

test(los_comandos_de_la_version_minima, [setup(nueva_partida)]) :-
    findall(N, ( member(Fase, [taberna, exploracion, combate, fin]), comandos_disponibles(Fase, Cs), member(N, Cs) ), Ns0),
    sort(Ns0, Ns),
    Ns == [aceptar, atacar, ayuda, compania, contratos, defender, descansar, elegir, explicar,
           habilidad, inventario, ir, mirar, pagar, salir].

:- end_tests(pelear_ya_no_existe).

:- begin_tests(la_campana_entera).

test(la_campana_se_gana_con_el_final_chapuza, [nondet]) :-
    campana,
    estado:fin_partida(victoria(chapuza)).

test(la_campana_dura_una_semana_y_deja_queso, [nondet]) :-
    campana,
    estado:dia(D), economia:queso_total(Q),
    D =< 8,
    Q > 0.

test(en_la_campana_se_cumplen_los_cuatro_contratos, [nondet]) :-
    campana,
    forall(contratos:contrato(C, _, _, _, _), contratos:contrato_cumplido(C)).

test(las_ratas_y_el_gato_se_cobran_en_la_taberna_y_los_ultimos_quedan_por_cobrar, [nondet]) :-
    campana,
    estado:contrato_cerrado(ratas_del_granero, _),
    estado:contrato_cerrado(gato_en_el_arbol, _),
    estado:contrato_por_cobrar(gallina_noble, exito),   % la escolta salio con exito (dos golpes a Clotilde); se resolvio despues de volver de la taberna
    estado:contrato_por_cobrar(despensa_real, exito).

test(la_venda_se_gana_por_el_camino, [nondet]) :-
    campana,
    estado:equipado(baldomero, venda_de_caballos).

test(tras_la_victoria_no_hay_combate_ni_evento, [nondet]) :-
    campana,
    \+ estado:en_combate(_),
    \+ estado:marca(evento_abierto(_)).

test(la_fase_es_fin, [nondet]) :-
    campana,
    once(estado:fase(F)),
    F == fin.

test(se_avisa_del_final_en_pantalla, [nondet]) :-
    nueva_partida_en_el_jefe_y_ganar(Texto),
    sub_atom(Texto, _, _, _, 'Chapuza de toda la vida'),
    sub_atom(Texto, _, _, _, 'Fin de la partida').

test(explicar_tras_ganar_da_el_resultado_del_jefe, [nondet]) :-
    campana,
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == resultado(despensa_real).

test(la_campana_es_reproducible, [nondet]) :-
    campana,
    foto_estado(Una),
    campana,
    foto_estado(Otra),
    Una =@= Otra.

test(la_campana_no_rompe_la_regla_de_un_solo_final, [nondet]) :-
    campana,
    findall(F, estado:fin_partida(F), Fs),
    Fs = [_].

test(la_despensa_real_no_se_puede_aceptar_antes_de_tiempo, [setup(nueva_partida)]) :-
    ordena(aceptar(despensa_real), Items),
    Items == [error(no_puede_aceptar(despensa_real))].

test(llegar_a_las_cuevas_sin_el_contrato_no_empieza_el_jefe, [nondet]) :-
    nueva_partida,
    aplicar_efecto(ganar_queso(cheddar, 0, 30)),
    paso(ir(camino_real)),
    paso(ir(cuevas)),
    \+ estado:en_combate(_),
    \+ estado:fin_partida(_).

:- end_tests(la_campana_entera).

:- begin_tests(las_derrotas).

test(perder_contra_el_jefe_es_derrota_combate, [nondet]) :-
    nueva_partida,
    aplicar_efecto(ganar_queso(cheddar, 0, 30)),
    forall(compania:miembro(M), ( M == baldomero -> true ; aplicar_efecto(dano(M, 99)) )),
    aplicar_efecto(dano(baldomero, 29)),                % queda Baldomero con 1 de vida
    assertz(estado:contrato_activo(despensa_real)),
    paso(ir(camino_real)),
    paso(ir(cuevas)),
    estado:fin_partida(derrota(derrota_combate)).

test(la_derrota_en_combate_no_resuelve_el_contrato, [nondet]) :-
    nueva_partida,
    aplicar_efecto(ganar_queso(cheddar, 0, 30)),
    forall(compania:miembro(M), ( M == baldomero -> true ; aplicar_efecto(dano(M, 99)) )),
    aplicar_efecto(dano(baldomero, 29)),
    assertz(estado:contrato_activo(despensa_real)),
    paso(ir(camino_real)),
    paso(ir(cuevas)),
    estado:contrato_activo(despensa_real),
    \+ estado:contrato_por_cobrar(despensa_real, _).

test(la_derrota_en_combate_se_cuenta_en_pantalla, [nondet]) :-
    nueva_partida,
    aplicar_efecto(ganar_queso(cheddar, 0, 30)),
    forall(compania:miembro(M), ( M == baldomero -> true ; aplicar_efecto(dano(M, 99)) )),
    aplicar_efecto(dano(baldomero, 29)),
    assertz(estado:contrato_activo(despensa_real)),
    paso(ir(camino_real)),
    ordena(ir(cuevas), _),
    findall(T, ( between(1, 30, _), \+ estado:fin_partida(_), estado:en_combate(_), golpe_con_texto(T) ), Ts),
    atomic_list_concat(Ts, '\n', Texto),
    sub_atom(Texto, _, _, _, 'Cuajados').

test(vagar_sin_cobrar_es_derrota_por_hambre, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(ir(bosque), _),
    ordena(ir(camino_real), Items),
    memberchk(msg(fin_hambre, [], _), Items),
    estado:fin_partida(derrota(derrota_hambre)).

test(el_hambre_se_cuenta_en_pantalla, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(ir(bosque), _),
    pantalla(ir(camino_real), Texto),
    sub_atom(Texto, _, _, _, 'Sin ración'),
    sub_atom(Texto, _, _, _, 'Fin de la partida').

test(con_un_cobro_pendiente_el_hambre_no_acaba_la_partida, [nondet]) :-
    nueva_partida,
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    assertz(estado:contrato_por_cobrar(ratas_del_granero, exito)),
    ordena(ir(aldea), _),
    \+ estado:fin_partida(_).

test(descansar_sin_comida_tambien_puede_acabar_la_partida, [nondet]) :-
    nueva_partida,
    aplicar_efecto(gastar_queso(cheddar, 0, 10)),       % quedan 2: justo para descansar
    ordena(descansar, Items),
    memberchk(msg(fin_hambre, [], _), Items),
    estado:fin_partida(derrota(derrota_hambre)).

test(tras_la_derrota_no_se_puede_seguir, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _), ordena(ir(bosque), _), ordena(ir(camino_real), _),
    ordena(ir(taberna), Items),
    Items = [error(fuera_de_fase(_, fin))].

:- end_tests(las_derrotas).
