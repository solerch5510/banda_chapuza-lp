% escolta.pl (pruebas)
% T-31: la escolta de Lady Clotilde. Clotilde no es una combatiente sino un CONTADOR de golpes:
% en cada ronda del combate de la escolta el primer enemigo que actua se ceba con ella (anota un
% golpe y no ataca a nadie) y los golpes, junto con resolucion/3, deciden el resultado del contrato
% (exito hasta 2, a medias hasta 4, fracaso con 5 o mas). La regla: se golpea a Clotilde mientras
% los golpes dados sean menos que el numero de ronda.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/escolta -g "run_tests,halt" -t "halt(1)"

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

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

vidas(Vs) :-
    findall(Id-V, ( compania:miembro(Id), estado:vida(Id, V) ), Vs).

% Un combate montado a mano como el de la escolta: ronda 1 abierta y la marca del contrato.
combate_de_escolta(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs),
    aplicar_efecto(marcar(combate_de(gallina_noble))).

% El mismo, pero de otro contrato (las ratas).
combate_de_ratas :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([rata_quesera])]),
    combate:efectos_ronda(Efs),
    aplicar_efectos(Efs),
    aplicar_efecto(marcar(combate_de(ratas_del_granero))).

% La escolta de verdad: venda puesta, en el Camino Real, y se acepta la gallina.
escolta_real(Items) :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    aplicar_efecto(viajar(camino_real)),
    ordena(aceptar(gallina_noble), Items).

% Cada miembro, en su turno, ataca a lo que haya o, si no puede, se defiende.
pelear(Max) :-
    forall(between(1, Max, _),
           (   estado:en_combate(_), \+ estado:fin_partida(_)
           ->  (   member(O, [bandido_montado, bandido_torpe]),
                   ordena(atacar(O), I), \+ I = [error(_)|_]
               ->  true
               ;   ordena(defender, _) )
           ;   true )).

% Se defiende N veces seguidas (o hasta que acabe) antes de pelear.
defender(N) :-
    forall(between(1, N, _),
           (   estado:en_combate(_), \+ estado:fin_partida(_)
           ->  ordena(defender, _)
           ;   true )).

:- begin_tests(la_regla).

test(sin_combate_no_hay_escolta, [setup(nueva_partida), fail]) :-
    escolta_en_curso.

test(en_el_combate_de_la_escolta_hay_escolta, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    escolta_en_curso.

test(en_el_combate_de_las_ratas_no_hay_escolta, [setup(combate_de_ratas), fail]) :-
    escolta_en_curso.

test(sin_marca_de_contrato_no_hay_escolta, [setup(nueva_partida), fail]) :-
    aplicar_efectos([iniciar_combate([bandido_torpe])]),
    escolta_en_curso.

test(sin_contador_los_golpes_son_cero, [setup(nueva_partida)]) :-
    golpes_dados(0).

test(los_golpes_se_leen_del_contador, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 3)),
    golpes_dados(3).

test(en_la_primera_ronda_golpea_el_primer_enemigo, [setup(combate_de_escolta([bandido_torpe, bandido_montado])), nondet]) :-
    golpea_a_clotilde(e(bandido_torpe, 1)),
    golpea_a_clotilde(e(bandido_montado, 1)).

test(con_un_golpe_dado_en_la_ronda_uno_ya_no_golpea_nadie, [setup(combate_de_escolta([bandido_torpe, bandido_montado])), nondet]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 1)),
    \+ golpea_a_clotilde(e(bandido_torpe, 1)),
    \+ golpea_a_clotilde(e(bandido_montado, 1)).

test(en_la_ronda_siguiente_vuelve_a_golpear, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 1)),
    \+ golpea_a_clotilde(e(bandido_torpe, 1)),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    estado:en_combate(2),
    golpea_a_clotilde(e(bandido_torpe, 1)).

test(con_los_golpes_a_la_par_de_la_ronda_no_golpea, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 3)),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    estado:en_combate(3),
    \+ golpea_a_clotilde(e(bandido_torpe, 1)),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    golpea_a_clotilde(e(bandido_torpe, 1)).

test(los_miembros_no_golpean_a_clotilde, [setup(combate_de_escolta([bandido_torpe])), fail]) :-
    golpea_a_clotilde(baldomero).

test(fuera_de_la_escolta_nadie_la_golpea, [setup(combate_de_ratas), fail]) :-
    golpea_a_clotilde(e(rata_quesera, 1)).

test(sin_combate_nadie_la_golpea, [setup(nueva_partida), fail]) :-
    golpea_a_clotilde(e(bandido_torpe, 1)).

test(el_efecto_cuenta_un_golpe_y_avisa_con_el_numero, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    E = e(bandido_torpe, 1),
    efectos_golpe_a_clotilde(E, [contar(golpes_a_clotilde, 1), mensaje(golpea_a_clotilde, [E, 1])]).

test(el_aviso_lleva_la_cuenta_acumulada, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    aplicar_efecto(contar(golpes_a_clotilde, 4)),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    estado:en_combate(5),
    efectos_golpe_a_clotilde(e(bandido_torpe, 1), [_, mensaje(golpea_a_clotilde, [_, 5])]).

test(sin_derecho_no_hay_efecto, [setup(combate_de_ratas), fail]) :-
    efectos_golpe_a_clotilde(e(rata_quesera, 1), _).

test(calcular_el_efecto_no_cambia_el_estado, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    foto_estado(Antes),
    efectos_golpe_a_clotilde(e(bandido_torpe, 1), _),
    foto_estado(Despues),
    Antes =@= Despues.

:- end_tests(la_regla).

:- begin_tests(el_resultado).

resultado_con(Golpes, Res) :-
    nueva_partida,
    (   Golpes > 0 -> aplicar_efecto(contar(golpes_a_clotilde, Golpes)) ; true ),
    contratos:contexto(Ctx),
    contratos:resultado(gallina_noble, Ctx, Res).

test(hasta_dos_golpes_es_exito, [nondet]) :-
    forall(member(G, [0, 1, 2]), ( resultado_con(G, R), R == exito )).

test(tres_o_cuatro_golpes_es_a_medias, [nondet]) :-
    forall(member(G, [3, 4]), ( resultado_con(G, R), R == a_medias )).

test(cinco_o_mas_golpes_es_fracaso, [nondet]) :-
    forall(member(G, [5, 6, 12]), ( resultado_con(G, R), R == fracaso )).

test(para_cada_numero_de_golpes_hay_exactamente_un_resultado, [nondet]) :-
    forall(between(0, 10, G),
           (   nueva_partida,
               (   G > 0 -> aplicar_efecto(contar(golpes_a_clotilde, G)) ; true ),
               contratos:contexto(Ctx),
               findall(R, contratos:resultado(gallina_noble, Ctx, R), [_])
           )).

:- end_tests(el_resultado).

:- begin_tests(el_turno_enemigo).

test(el_primero_se_ceba_con_clotilde_y_no_hace_dano, [setup(combate_de_escolta([bandido_torpe, bandido_montado])), nondet]) :-
    vidas(Antes),
    juego:turno_enemigo(e(bandido_montado, 1), Items),
    vidas(Despues),
    Antes == Despues,
    memberchk(msg(golpea_a_clotilde, [e(bandido_montado, 1), 1], _), Items),
    golpes_dados(1).

test(el_segundo_de_la_ronda_ataca_a_la_compania, [setup(combate_de_escolta([bandido_torpe, bandido_montado])), nondet]) :-
    juego:turno_enemigo(e(bandido_montado, 1), _),
    vidas(Antes),
    juego:turno_enemigo(e(bandido_torpe, 1), Items),
    vidas(Despues),
    Antes \== Despues,
    \+ memberchk(msg(golpea_a_clotilde, _, _), Items),
    golpes_dados(1).

test(en_la_ronda_dos_vuelve_a_cebarse, [setup(combate_de_escolta([bandido_torpe, bandido_montado])), nondet]) :-
    juego:turno_enemigo(e(bandido_montado, 1), _),
    aplicar_efectos([siguiente_ronda([baldomero])]),
    juego:turno_enemigo(e(bandido_torpe, 1), Items),
    memberchk(msg(golpea_a_clotilde, [e(bandido_torpe, 1), 2], _), Items),
    golpes_dados(2).

test(fuera_de_la_escolta_el_enemigo_ataca_como_siempre, [setup(combate_de_ratas), nondet]) :-
    vidas(Antes),
    juego:turno_enemigo(e(rata_quesera, 1), Items),
    vidas(Despues),
    \+ memberchk(msg(golpea_a_clotilde, _, _), Items),
    \+ estado:contador(golpes_a_clotilde, _),
    (   Antes \== Despues -> true ; memberchk(msg(roba_queso, _, _), Items) ).

test(se_guarda_la_prueba_antes_de_aplicar_el_efecto, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    E = e(bandido_torpe, 1),
    juego:turno_enemigo(E, _),
    estado:ultima_prueba(accion_enemigo(E), Prueba),
    prueba_a_lineas(Prueba, Lineas),
    member(L, Lineas), contiene(L, 'golpea_a_clotilde'), !.

test(explicar_dice_que_la_gallina_va_escoltada, [setup(combate_de_escolta([bandido_torpe])), nondet]) :-
    juego:turno_enemigo(e(bandido_torpe, 1), _),
    pantalla(explicar, T),
    contiene(T, 'Lady Clotilde va escoltada'),
    \+ contiene(T, 'regla de prioridad').

test(explicar_un_ataque_normal_sigue_diciendo_su_prioridad, [setup(combate_de_ratas), nondet]) :-
    juego:turno_enemigo(e(rata_quesera, 1), _),
    pantalla(explicar, T),
    contiene(T, 'regla de prioridad'),
    \+ contiene(T, 'Lady Clotilde').

test(el_golpe_se_lee_en_pantalla, [setup(combate_de_escolta([bandido_montado])), nondet]) :-
    juego:turno_enemigo(e(bandido_montado, 1), Items),
    with_output_to(atom(T), ui:mostrar(resultado(Items))),
    contiene(T, 'Lady Clotilde'),
    contiene(T, '(golpe 1)'),
    \+ contiene(T, 'msg('),
    \+ contiene(T, '~w').

:- end_tests(el_turno_enemigo).

:- begin_tests(la_escolta_en_la_partida).

test(aceptar_la_gallina_abre_la_escolta, [nondet]) :-
    escolta_real(Items),
    \+ memberchk(error(_), Items),
    memberchk(msg(objetivo, [gallina_noble], _), Items),
    estado:en_combate(_),
    escolta_en_curso.

test(los_golpes_van_un_paso_por_detras_de_la_ronda, [nondet]) :-
    escolta_real(_),
    forall(between(1, 12, _),
           (   estado:en_combate(R), \+ estado:fin_partida(_)
           ->  golpes_dados(N),
               N >= R - 1, N =< R,
               ordena(defender, _)
           ;   true )).

test(defendiendo_cuatro_rondas_llevan_al_menos_tres_golpes, [nondet]) :-
    escolta_real(_),
    forall(between(1, 40, _),
           (   estado:en_combate(R), R < 4, \+ estado:fin_partida(_)
           ->  ordena(defender, _)
           ;   true )),
    (   estado:en_combate(R), R >= 4
    ->  golpes_dados(N), N >= 3
    ;   true ).

% Peleando a golpes y sin preparacion el combate dura tres rondas: tres golpes, a medias. El exito
% (dos golpes o menos) pide ir mas deprisa: en la campana, con la moral alta, se consigue.
test(peleando_a_golpes_y_sin_preparacion_la_gallina_sale_a_medias, [nondet]) :-
    escolta_real(_),
    pelear(150),
    \+ estado:en_combate(_),
    golpes_dados(3),
    estado:contrato_por_cobrar(gallina_noble, a_medias).

test(el_resultado_es_el_que_toca_por_los_golpes, [nondet]) :-
    forall(member(K, [0, 2, 4, 6, 8]),
           (   escolta_real(_),
               defender(K),
               pelear(150),
               (   estado:fin_partida(_)
               ->  true
               ;   golpes_dados(G),
                   (   G =< 2 -> Esperado = exito ; G =< 4 -> Esperado = a_medias ; Esperado = fracaso ),
                   (   Esperado == fracaso
                   ->  estado:contrato_cerrado(gallina_noble, fracaso)
                   ;   estado:contrato_por_cobrar(gallina_noble, Esperado) )
               )
           )).

test(con_cinco_golpes_fracasa_y_el_contrato_se_puede_reintentar, [nondet]) :-
    escolta_real(_),
    aplicar_efecto(contar(golpes_a_clotilde, 5)),
    pelear(150),
    \+ estado:en_combate(_),
    estado:contrato_cerrado(gallina_noble, fracaso),
    \+ estado:contrato_activo(gallina_noble),
    contratos:puede_aceptar(gallina_noble).

test(al_reintentar_los_golpes_empiezan_de_cero, [nondet]) :-
    escolta_real(_),
    aplicar_efecto(contar(golpes_a_clotilde, 5)),
    pelear(150),
    estado:contrato_cerrado(gallina_noble, fracaso),
    ordena(aceptar(gallina_noble), Items),
    \+ memberchk(error(_), Items),
    estado:en_combate(_),
    golpes_dados(N), N =< 1.

test(a_medias_se_cobra_la_mitad_en_la_taberna_y_la_gallina_recomienda, [nondet]) :-
    escolta_real(_),
    pelear(150),
    estado:contrato_por_cobrar(gallina_noble, a_medias),
    economia:queso_total(Antes),
    aplicar_efecto(viajar(taberna)),
    contratos:efectos_cobro(Efs),
    aplicar_efectos(Efs),
    economia:queso_total(Despues),
    Despues >= Antes + 7,
    Despues < Antes + 14,
    estado:marca(recomendada_por_clotilde).

test(un_fracaso_cuesta_queso_y_moral, [nondet]) :-
    escolta_real(_),
    aplicar_efecto(contar(golpes_a_clotilde, 5)),
    economia:queso_total(Antes),
    estado:moral(rufino, M0),
    pelear(150),
    estado:contrato_cerrado(gallina_noble, fracaso),
    economia:queso_total(Despues),
    estado:moral(rufino, M1),
    Despues =< Antes,
    M1 < M0 + 1.

test(la_partida_es_reproducible, [nondet]) :-
    escolta_real(_), defender(3), pelear(150), foto_estado(F1),
    escolta_real(_), defender(3), pelear(150), foto_estado(F2),
    F1 =@= F2.

:- end_tests(la_escolta_en_la_partida).

:- begin_tests(otros_combates).

test(el_combate_de_las_ratas_no_cuenta_golpes_a_clotilde, [nondet]) :-
    nueva_partida,
    aplicar_efecto(viajar(aldea)),
    ordena(aceptar(ratas_del_granero), _),
    pelear_ratas,
    \+ estado:contador(golpes_a_clotilde, _).

test(un_combate_suelto_no_es_una_escolta, [setup(nueva_partida), nondet]) :-
    comenzar_combate([bandido_torpe, bandido_torpe], _),
    \+ escolta_en_curso,
    \+ estado:contador(golpes_a_clotilde, _).

pelear_ratas :-
    forall(between(1, 60, _),
           (   estado:en_combate(_), \+ estado:fin_partida(_)
           ->  (   ordena(atacar(rata_quesera), I), \+ I = [error(_)|_] -> true ; ordena(defender, _) )
           ;   true )).

:- end_tests(otros_combates).
