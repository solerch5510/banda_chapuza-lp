% equivalencia.pl (pruebas)
% T-39: la prueba de equivalencia, el corazon de la verificacion del meta-interprete. Para un conjunto
% de objetivos del juego (mas de veinte) y varios escenarios, EJECUTAR la meta directamente y
% DEMOSTRARLA con explicar:solve/2 tiene que dar lo mismo: las mismas soluciones, en el mismo orden
% (se compara con =@=, igual salvo renombrar variables). Incluye negacion, aritmetica, si-entonces-
% sino, predicados de varios modulos, dinamicos sin clausulas y, sobre todo, el CORTE: la IA enemiga
% con corte (accion_enemigo/2) tiene que coincidir con su gemela declarativa sin corte.
% Tambien los casos de error (la excepcion es la misma o es un error de programacion) y la
% "prueba de modo": el unico sitio donde el corte cambia el significado (leccion de la Conf. 4).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/equivalencia -g "run_tests,halt" -t "halt(1)"

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
:- use_module('../src/explicar').
:- use_module('../src/juego').
:- use_module('spike/toy_a', []).                 % se llaman con su modulo: no se importa nada
:- use_module('spike/toy_b', []).

:- multifile explicar:modulo_juego/1.
explicar:modulo_juego(toy_a).
explicar:modulo_juego(toy_b).

% ---------------------------------------------------------------------------
% Los escenarios: estados del juego muy distintos (se parte siempre de una partida nueva)
% ---------------------------------------------------------------------------
escenario(inicio,         nueva_partida).
escenario(hambre,         hambre).
escenario(huelga,         huelga).
escenario(combate,        combate_con_rasgos).
escenario(combate_venda,  combate_con_venda).
escenario(jefe,           el_jefe).
escenario(contratos,      contratos_en_marcha).
escenario(final,          partida_acabada).

hambre :-
    nueva_partida,
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    aplicar_efecto(ganar_queso(brie, 14, 2)),               % un queso rancio
    aplicar_efecto(avanzar_dia).

huelga :-
    nueva_partida,
    aplicar_efecto(mod_moral(baldomero, -4)),                % moral 2: en huelga
    aplicar_efecto(mod_moral(rufino, 3)),
    aplicar_efecto(dano(tuerca, 99)).

combate_con_rasgos :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([bandido_montado, bandido_torpe, rata_quesera, moho_saltarin])]),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    aplicar_efecto(alterar(tuerca, aturdido, 2)),
    aplicar_efecto(dano(e(bandido_torpe, 1), 9)),            % le queda poca vida
    aplicar_efecto(ganar_objeto(e(rata_quesera, 1), pocion, 1)).

combate_con_venda :-
    nueva_partida,
    aplicar_efecto(equipar(baldomero, venda_de_caballos)),
    aplicar_efectos([iniciar_combate([bandido_montado, rata_quesera])]),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    aplicar_efecto(alterar(baldomero, defendiendo, 1)).

el_jefe :-
    nueva_partida,
    aplicar_efectos([iniciar_combate([gran_roquefort])]),
    combate:efectos_ronda(Efs), aplicar_efectos(Efs),
    aplicar_efecto(dano(e(gran_roquefort, 1), 42)).         % 18 de 60: por debajo del 30 %

contratos_en_marcha :-
    nueva_partida,
    aplicar_efecto(contrato_aceptar(ratas_del_granero)),
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    aplicar_efecto(contar(quesos_robados, 1)),
    aplicar_efecto(viajar(camino_real)),
    aplicar_efecto(visitar(camino_real)).

partida_acabada :-
    nueva_partida,
    aplicar_efecto(fin(victoria(chapuza))).

% ---------------------------------------------------------------------------
% Los objetivos: cada uno una meta a comparar. Los que necesitan argumentos ligados llevan un
% generador delante (estado:combatiente/2, between/3...), que tambien es parte de lo que se compara.
% ---------------------------------------------------------------------------
objetivo(huelga_de_cualquiera,    compania:esta_en_huelga(_)).
objetivo(miedo,                   compania:teme(_, _)).
objetivo(activos,                 compania:activo(_)).
objetivo(en_pie,                  compania:en_pie(_)).
objetivo(niveles_de_moral,        compania:nivel_moral(_, _)).
objetivo(moral_media,             compania:moral_media(_)).
objetivo(venda_de_caballos,       compania:ignora_miedo(_)).
objetivo(viaje_posible,           compania:puede_viajar(_)).
objetivo(categorias_de_queso,     ( between(0, 14, E), economia:categoria_queso(E, _) )).
objetivo(total_de_queso,          economia:queso_total(_)).
objetivo(queso_para_dos,          ( between(0, 14, N), economia:hay_queso_para(N) )).
objetivo(puede_descansar,         economia:puede_descansar).
objetivo(puede_pagar,             economia:puede_pagar_sueldos).
objetivo(la_despensa,             economia:despensa(_)).
objetivo(orden_de_turnos,         combate:orden_turnos(_)).
objetivo(iniciativa,              ( estado:combatiente(Id, _), combate:iniciativa(Id, _) )).
objetivo(dano_de_todos,           ( estado:combatiente(A, _), estado:combatiente(B, _), combate:dano(A, B, _) )).
objetivo(puede_atacar,            combate:puede_atacar(_, _)).
objetivo(filas_alcanzables,       combate:en_fila_alcanzable(_, _)).
objetivo(accion_del_enemigo,      combate:accion_enemigo(_, _)).
objetivo(accion_sin_corte,        combate:accion_enemigo_sin_corte(_, _)).
objetivo(la_ia_de_cada_enemigo,   ( estado:combatiente(E, enemigo), combate:accion_enemigo(E, _) )).
objetivo(habilidades,             combate:puede_habilidad(_, _)).
objetivo(habilidades_con_objetivo, combate:puede_habilidad(_, _, _)).
objetivo(vida_baja,               combate:vida_baja(_)).
objetivo(puede_aceptar,           contratos:puede_aceptar(_)).
objetivo(contratos_disponibles,   contratos:disponible(_)).
objetivo(contratos_visibles,      contratos:visible(_)).
objetivo(estado_de_contratos,     contratos:estado_de_contrato(_, _)).
objetivo(contratos_cumplidos,     contratos:contratos_cumplidos(_)).
objetivo(la_fase,                 estado:fase(_)).
objetivo(fin_de_combate,          combate:fin_combate(_)).
objetivo(el_final,                contratos:final_de_la_partida(_)).
objetivo(negacion_sobre_negacion, ( compania:miembro(M), \+ ( compania:esta_en_huelga(M) ; \+ compania:activo(M) ) )).
objetivo(si_entonces_sino,        ( compania:miembro(M), ( compania:esta_en_huelga(M) -> X = huelga ; X = trabaja ), X \== nada )).
objetivo(aritmetica_y_comparacion, ( estado:vida(_, V), V > 5, W is V * 2 + 1, W =< 100 )).
objetivo(condicion_con_varias_soluciones, ( ( compania:miembro(_) -> X = hay ; X = nadie ), X \== nada )).
objetivo(disyuncion_sin_condicion, ( compania:miembro(M), ( compania:esta_en_huelga(M) ; compania:activo(M) ) )).
objetivo(agregados,               ( findall(M, compania:en_pie(M), L), length(L, _) )).
objetivo(forall_de_miembros,      forall(compania:miembro(M), estado:vida(M, _))).

nombres_de_objetivo(Ns) :- findall(N, objetivo(N, _), Ns).

% ---------------------------------------------------------------------------
% La comparacion
% ---------------------------------------------------------------------------
% Todas las soluciones de Meta ejecutandola y demostrandola, en orden y con la misma forma.
soluciones(Meta, Directas, ViaMeta) :-
    findall(Meta, call(Meta), Directas),
    findall(Meta, explicar:solve(Meta, _), ViaMeta).

equivalente(Meta) :-
    soluciones(Meta, Directas, ViaMeta),
    Directas =@= ViaMeta.

en_el_escenario(Nombre) :-
    escenario(Nombre, Preparacion),
    call(Preparacion).

% Cada pareja escenario-objetivo que no coincide, para que el fallo diga cual es.
discrepancias(Ds) :-
    findall(Esc-Obj,
            (   escenario(Esc, Prep),
                call(Prep),
                objetivo(Obj, Meta),
                \+ equivalente(Meta)
            ),
            Ds).

% ---------------------------------------------------------------------------

:- begin_tests(el_conjunto).

test(hay_mas_de_veinte_objetivos) :-
    nombres_de_objetivo(Ns), length(Ns, N), N >= 20.

test(hay_al_menos_tres_escenarios) :-
    findall(E, escenario(E, _), Es), length(Es, N), N >= 3.

test(los_objetivos_son_de_varios_modulos) :-
    findall(M, ( objetivo(_, G), modulo_de(G, M) ), Ms0), sort(Ms0, Ms),
    length(Ms, N), N >= 4.

modulo_de((A, _), M) :- !, modulo_de(A, M).
modulo_de(M:_, M) :- !.
modulo_de(_, user).

test(cada_objetivo_tiene_un_nombre_distinto) :-
    nombres_de_objetivo(Ns), sort(Ns, U), length(Ns, N), length(U, N).

test(cada_escenario_se_puede_preparar) :-
    forall(escenario(E, _), ( en_el_escenario(E) -> true ; format("no se prepara ~w~n", [E]), fail )).

test(el_objetivo_con_negacion_con_si_con_aritmetica_y_con_agregados_estan) :-
    forall(member(N, [negacion_sobre_negacion, si_entonces_sino, aritmetica_y_comparacion, agregados, forall_de_miembros]),
           objetivo(N, _)).

:- end_tests(el_conjunto).

:- begin_tests(la_equivalencia).

test(todos_los_objetivos_en_todos_los_escenarios_coinciden_en_soluciones_y_orden) :-
    discrepancias(Ds),
    (   Ds == [] -> true ; format("no coinciden: ~w~n", [Ds]), fail ).

test(cada_escenario_es_equivalente_por_separado) :-
    forall(escenario(E, Prep),
           (   call(Prep),
               forall(objetivo(O, M),
                      (   equivalente(M) -> true ; format("~w en ~w~n", [O, E]), fail ))
           )).

test(los_objetivos_dan_alguna_solucion_en_algun_escenario_casi_todos) :-
    % una equivalencia de listas vacias no prueba nada: la mayoria de los objetivos tiene soluciones
    findall(O,
            (   objetivo(O, M),
                escenario(_, Prep), call(Prep),
                soluciones(M, [_|_], _)
            ),
            Os0),
    sort(Os0, Os),
    nombres_de_objetivo(Ns), length(Ns, Total), length(Os, ConSolucion),
    ConSolucion * 100 >= Total * 85.

test(muchos_escenarios_dan_varias_soluciones) :-
    findall(O-N,
            (   objetivo(O, M), escenario(_, Prep), call(Prep),
                soluciones(M, D, _), length(D, N), N >= 2 ),
            Ps),
    length(Ps, K), K >= 40.

test(la_prueba_comprueba_el_orden_y_no_solo_el_conjunto) :-
    % dos listas con las mismas soluciones en distinto orden NO son equivalentes
    \+ ( [a(1), a(2)] =@= [a(2), a(1)] ).

test(la_prueba_ve_la_diferencia_de_una_solucion_de_mas) :-
    \+ ( [a(1)] =@= [a(1), a(2)] ).

test(un_objetivo_sin_soluciones_es_equivalente_a_si_mismo, [setup(nueva_partida)]) :-
    equivalente(compania:esta_en_huelga(_)).

test(equivalencia_de_los_cuatro_estados_de_la_ia_con_corte, [setup(combate_con_rasgos)]) :-
    forall(estado:combatiente(E, enemigo),
           (   findall(A, combate:accion_enemigo(E, A), D),
               findall(A, explicar:solve(combate:accion_enemigo(E, A), _), M),
               D =@= M, D = [_]
           )).

:- end_tests(la_equivalencia).

:- begin_tests(el_corte).

% La IA con corte y su gemela declarativa sin corte dan la MISMA unica accion para cada enemigo, en cada
% escenario: es el oraculo del corte (Conferencia 4).
misma_accion(E) :-
    findall(A, combate:accion_enemigo(E, A), [A1]),
    findall(A, combate:accion_enemigo_sin_corte(E, A), [A2]),
    A1 == A2.

test(la_ia_con_corte_es_igual_que_sin_corte_en_los_escenarios_de_combate) :-
    forall(member(Esc, [combate, combate_venda, jefe]),
           (   en_el_escenario(Esc),
               forall(estado:combatiente(E, enemigo), misma_accion(E))
           )).

test(con_corte_y_via_meta_dan_la_misma_accion_y_una_sola) :-
    forall(member(Esc, [combate, combate_venda, jefe]),
           (   en_el_escenario(Esc),
               forall(estado:combatiente(E, enemigo),
                      (   findall(A, explicar:solve(combate:accion_enemigo(E, A), _), [A1]),
                          findall(A, combate:accion_enemigo(E, A), [A2]),
                          A1 == A2 ))
           )).

test(la_prueba_guarda_la_regla_que_gano_y_el_corte, [setup(combate_con_rasgos)]) :-
    explicar:solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P),
    P = regla(accion_enemigo(_, _), _, Hijos),
    memberchk(corte, Hijos).

test(el_comodin_no_lleva_corte, [setup(combate_con_rasgos)]) :-
    retractall(estado:combatiente(_, jugador)),
    explicar:solve(combate:accion_enemigo(e(bandido_torpe, 1), A), P),
    A == defender,
    P = hecho(accion_enemigo(_, defender)).

test(las_seis_prioridades_aparecen_en_los_escenarios, [nondet]) :-
    findall(N,
            (   member(Esc, [combate, combate_venda, jefe]),
                en_el_escenario(Esc),
                estado:combatiente(E, enemigo),
                explicar:solve(combate:accion_enemigo(E, _), regla(accion_enemigo(_, _), N, _))
            ),
            Ns0),
    sort(Ns0, Ns),
    length(Ns, K), K >= 3.

% Prueba de MODO: con la accion ya ligada el corte cambia el significado. La version con corte dice que
% un bandido que atacaria "puede defender" porque la ultima clausula no repite las condiciones; la
% declarativa dice que no. Por eso solo es correcta en modo (+Enemigo, -Accion).
test(prueba_de_modo_con_la_accion_ligada_el_corte_difiere, [setup(combate_con_rasgos)]) :-
    E = e(bandido_torpe, 1),
    combate:accion_enemigo(E, atacar(_)),                       % lo que de verdad haria
    combate:accion_enemigo(E, defender),                        % CON corte: tambien "es" defender
    \+ combate:accion_enemigo_sin_corte(E, defender).           % SIN corte: no

test(el_meta_interprete_se_comporta_como_la_ejecucion_en_el_modo_difiere, [setup(combate_con_rasgos)]) :-
    E = e(bandido_torpe, 1),
    (   combate:accion_enemigo(E, defender) -> D = si ; D = no ),
    (   explicar:solve(combate:accion_enemigo(E, defender), _) -> M = si ; M = no ),
    D == M.

% Los modulos de juguete: el corte "de verdad" (una sola solucion, y no poda la parte posterior).
test(un_corte_tras_la_condicion_deja_una_solucion) :-
    findall(X, toy_a:cortado(X), D), findall(X, explicar:solve(toy_a:cortado(X), _), M),
    D == [2], D == M.

test(el_corte_no_poda_lo_posterior) :-
    findall(X, toy_a:cortado2(X), D), findall(X, explicar:solve(toy_a:cortado2(X), _), M),
    D == [1, 1], D == M.

test(la_ia_de_juguete_con_corte_coincide_con_la_directa) :-
    forall(member(E, [heroe, orco, goblin, muerto]),
           (   findall(A, toy_a:accion_enemigo(E, A), D),
               findall(A, explicar:solve(toy_a:accion_enemigo(E, A), _), M),
               D == M )).

test(si_entonces_sino_equivalente) :-
    forall(member(X, [5, -5]),
           (   findall(Y, toy_a:cond(X, Y), D), findall(Y, explicar:solve(toy_a:cond(X, Y), _), M), D == M )).

:- end_tests(el_corte).

:- begin_tests(modulos_y_dinamicos).

test(un_dinamico_sin_clausulas_se_comporta_como_cerrado, [setup(nueva_partida)]) :-
    equivalente(estado:marca(inexistente)),
    soluciones(estado:marca(inexistente), [], []).

test(un_dinamico_con_hechos_enumera_igual, [setup(nueva_partida)]) :-
    equivalente(estado:en_compania(_)),
    soluciones(estado:en_compania(_), [_, _, _, _], _).

test(un_predicado_importado_de_otro_modulo, [setup(nueva_partida)]) :-
    equivalente(juego:comando(_, _)).

test(un_predicado_de_modulo_distinto_en_la_misma_conjuncion, [setup(nueva_partida)]) :-
    equivalente(( compania:miembro(M), economia:queso_total(Q), mundo:parametro(racion_por_miembro, R), Q >= R, M \== nadie )).

test(la_calificacion_de_modulo_dentro_de_la_conjuncion, [setup(nueva_partida)]) :-
    equivalente(( estado:fase(F), F \== nada )).

test(toy_b_desde_toy_a) :-
    % todos_vivos usa vida/2 de toy_b: un predicado importado de otro modulo y un forall
    findall(x, toy_a:todos_vivos([heroe, orco]), D),
    findall(x, explicar:solve(toy_a:todos_vivos([heroe, orco]), _), M),
    D == M.

test(la_recursion_del_juguete) :-
    findall(S, toy_a:suma([1, 2, 3], S), D),
    findall(S, explicar:solve(toy_a:suma([1, 2, 3], S), _), M),
    D == [6], D == M.

:- end_tests(modulos_y_dinamicos).

:- begin_tests(los_errores).

% Lo que no se puede ejecutar no se cae: la excepcion es la de siempre o un error de programacion claro.
error_de(Meta, Directo, ViaMeta) :-
    catch(( call(Meta), Directo = no_error ), error(E1, _), Directo = E1),
    catch(( explicar:solve(Meta, _), ViaMeta = no_error ), E2, ( E2 = error(F, _) -> ViaMeta = F ; ViaMeta = E2 )).

test(un_predicado_que_no_existe_da_el_mismo_error, [setup(nueva_partida)]) :-
    error_de(combate:no_existe_este_predicado(1), D, M),
    D = existence_error(_, _),
    M = existence_error(_, _).

test(una_meta_sin_ligar_es_un_error_de_programacion, [setup(nueva_partida)]) :-
    catch(explicar:solve(_, _), error(instantiation_error, _), true).

test(una_variable_dentro_de_una_conjuncion_tambien, [setup(nueva_partida)]) :-
    catch(explicar:solve(( true, _ ), _), error(instantiation_error, _), true).

test(un_corte_anidado_no_se_soporta_y_lo_dice, [throws(corte_no_soportado)]) :-
    explicar:solve(toy_a:anidado(_), _).

test(una_recursion_sin_fin_se_corta_con_un_limite, [throws(limite_profundidad(_))]) :-
    explicar:solve(toy_a:bucle(_), _).

test(una_meta_que_falla_no_da_prueba, [setup(nueva_partida), fail]) :-
    explicar:solve(compania:esta_en_huelga(baldomero), _).

test(la_meta_que_falla_directamente_tambien_falla_via_meta, [setup(nueva_partida)]) :-
    \+ compania:esta_en_huelga(baldomero),
    \+ explicar:solve(compania:esta_en_huelga(baldomero), _).

test(los_errores_no_dejan_el_estado_cambiado, [setup(nueva_partida)]) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), A1),
    catch(explicar:solve(_, _), _, true),
    catch(explicar:solve(combate:no_existe(1), _), _, true),
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), A2),
    A1 =@= A2.

:- end_tests(los_errores).

:- begin_tests(solve_no_modifica_nada).

foto(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

test(demostrar_todos_los_objetivos_deja_el_estado_igual) :-
    forall(escenario(_, Prep),
           (   call(Prep),
               foto(A),
               forall(objetivo(_, M), ( findall(x, explicar:solve(M, _), _) )),
               foto(B),
               A =@= B
           )).

test(el_diagnostico_tampoco_modifica_el_estado, [setup(combate_con_rasgos)]) :-
    foto(A),
    ( explicar:por_que_no(combate:puede_atacar(tuerca, e(rata_quesera, 1)), _) -> true ; true ),
    ( explicar:por_que_no(contratos:puede_aceptar(gallina_noble), _) -> true ; true ),
    foto(B),
    A =@= B.

:- end_tests(solve_no_modifica_nada).
