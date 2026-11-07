% ia.pl (pruebas)
% T-24: la IA enemiga. accion_enemigo/2 (reglas por prioridad con corte), su gemela sin corte
% regla_ia/3 + accion_enemigo_sin_corte/2 (el oraculo), cada acción como efectos (curarse,
% invocar_moho, robar_queso, embestir, atacar, defender) y la IA dentro del bucle de combate.
% Incluye la leccion de la Conferencia 4: el corte "rojo" y el modo (+Enemigo, -Accion).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/ia -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/explicar').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

% Un combate montado con los efectos (sin el bucle): para probar las reglas sueltas.
montado(Tipos) :-
    nueva_partida,
    aplicar_efectos([iniciar_combate(Tipos)]).

% Un combate empezado con el bucle real.
empieza(Tipos, Items) :-
    nueva_partida,
    comenzar_combate(Tipos, Items).

foto_estado(Hs) :-
    findall(H, ( ( estado:persistente(N/A) ; estado:transitorio(N/A) ), functor(H, N, A), call(H) ), Hs).

ordena(Cmd, Items) :-
    ejecutar(Cmd, resultado(Items)).

pantalla(Cmd, Texto) :-
    ejecutar(Cmd, Resultado),
    with_output_to(atom(Texto), ui:mostrar(Resultado)).

% La accion que elige la IA (con corte), una sola vez.
elige(E, A) :-
    findall(X, combate:accion_enemigo(E, X), [A]).

% Deja a E con la vida dada (le baja la diferencia).
vida_de(E, Vida) :-
    estado:vida(E, V0),
    D is V0 - Vida,
    aplicar_efecto(dano(E, D)).

% Se acaba el queso del grupo.
sin_queso :-
    economia:queso_total(N),
    (   N > 0 -> aplicar_efecto(gastar_queso(cheddar, 0, N)) ; true ).

defiende_todos([]).
defiende_todos([_|Resto]) :-
    ordena(defender, _),
    defiende_todos(Resto).

:- begin_tests(prioridades_de_la_ia).

test(un_bandido_torpe_ataca_al_mas_debil, [nondet]) :-
    montado([bandido_torpe]),
    elige(e(bandido_torpe, 1), A),
    A == atacar(tuerca).

test(un_moho_saltarin_ataca, [nondet]) :-
    montado([moho_saltarin]),
    elige(e(moho_saltarin, 1), A),
    A == atacar(tuerca).

test(la_regla_5_es_atacar_y_la_6_es_el_comodin) :-
    predicate_property(combate:accion_enemigo(_, _), number_of_clauses(N)),
    N == 6.

test(sin_nada_que_atacar_se_defiende, [nondet]) :-
    montado([bandido_torpe]),
    retractall(estado:combatiente(_, jugador)),
    elige(e(bandido_torpe, 1), A),
    A == defender.

test(con_poca_vida_y_una_pocion_se_cura, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    vida_de(e(bandido_torpe, 1), 3),                   % 3 de 12: por debajo del 30 %
    elige(e(bandido_torpe, 1), A),
    A == curarse.

test(con_poca_vida_pero_sin_pocion_ataca, [nondet]) :-
    montado([bandido_torpe]),
    vida_de(e(bandido_torpe, 1), 3),
    elige(e(bandido_torpe, 1), A),
    A == atacar(tuerca).

test(con_pocion_pero_sano_ataca, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    elige(e(bandido_torpe, 1), A),
    A == atacar(tuerca).

test(el_umbral_de_vida_baja_es_exacto, [nondet]) :-
    montado([moho_saltarin]),                          % vida maxima 10: el 30 % son 3
    aplicar_efecto(ganar_objeto(e(moho_saltarin, 1), pocion, 1)),
    vida_de(e(moho_saltarin, 1), 3),
    elige(e(moho_saltarin, 1), Baja),
    aplicar_efecto(curar(e(moho_saltarin, 1), 1)),     % 4 de 10: ya no es baja
    elige(e(moho_saltarin, 1), Sana),
    Baja == curarse,
    Sana == atacar(tuerca).

test(una_pocion_gastada_ya_no_cura, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    aplicar_efecto(gastar_objeto(e(bandido_torpe, 1), pocion, 1)),
    vida_de(e(bandido_torpe, 1), 3),
    elige(e(bandido_torpe, 1), A),
    A == atacar(tuerca).

test(un_objeto_agotado_no_cura, [nondet]) :-
    montado([bandido_torpe]),
    assertz(estado:lleva(e(bandido_torpe, 1), pocion, 0)),     % no deberia existir, pero la regla no se fia
    vida_de(e(bandido_torpe, 1), 3),
    elige(e(bandido_torpe, 1), A),
    A == atacar(tuerca).

test(la_rata_roba_si_hay_queso, [nondet]) :-
    montado([rata_quesera]),
    elige(e(rata_quesera, 1), A),
    A == robar_queso.

test(la_rata_ataca_si_no_hay_queso, [nondet]) :-
    montado([rata_quesera]),
    sin_queso,
    elige(e(rata_quesera, 1), A),
    A == atacar(tuerca).

test(solo_la_rata_roba, [nondet]) :-
    montado([bandido_torpe, moho_saltarin, bandido_montado]),
    forall(estado:instancia(E, _), ( elige(E, A), A \== robar_queso )).

test(el_bandido_montado_embiste_la_primera_vez, [nondet]) :-
    montado([bandido_montado]),
    elige(e(bandido_montado, 1), A),
    A == embestir(tuerca).

test(luego_el_bandido_montado_ataca, [nondet]) :-
    montado([bandido_montado]),
    aplicar_efecto(alterar(e(bandido_montado, 1), embistio, fijo)),
    elige(e(bandido_montado, 1), A),
    A == atacar(tuerca).

test(el_bandido_montado_sin_objetivo_no_embiste, [nondet]) :-
    montado([bandido_montado]),
    retractall(estado:combatiente(_, jugador)),
    elige(e(bandido_montado, 1), A),
    A == defender.

test(el_jefe_invoca_un_moho_si_no_tiene_ninguno, [nondet]) :-
    montado([gran_roquefort]),
    elige(e(gran_roquefort, 1), A),
    A == invocar_moho.

test(con_un_moho_vivo_el_jefe_ataca, [nondet]) :-
    montado([gran_roquefort, moho_saltarin]),
    elige(e(gran_roquefort, 1), A),
    A == atacar(tuerca).

test(si_cae_el_moho_el_jefe_invoca_otro, [nondet]) :-
    montado([gran_roquefort, moho_saltarin]),
    aplicar_efecto(dano(e(moho_saltarin, 1), 99)),
    elige(e(gran_roquefort, 1), A),
    A == invocar_moho.

test(el_jefe_invoca_como_mucho_dos_mohos, [nondet]) :-
    montado([gran_roquefort, moho_saltarin, moho_saltarin]),
    aplicar_efecto(dano(e(moho_saltarin, 1), 99)),
    aplicar_efecto(dano(e(moho_saltarin, 2), 99)),
    elige(e(gran_roquefort, 1), A),
    A == atacar(tuerca).

test(solo_el_jefe_invoca, [nondet]) :-
    montado([bandido_torpe, rata_quesera, bandido_montado]),
    forall(estado:instancia(E, _), ( elige(E, A), A \== invocar_moho )).

test(el_jefe_se_cura_con_poca_vida_y_esporas, [nondet]) :-
    montado([gran_roquefort]),
    vida_de(e(gran_roquefort, 1), 18),                 % el 30 % de 60
    elige(e(gran_roquefort, 1), A),
    A == curarse.

test(un_punto_mas_y_el_jefe_ya_no_esta_bajo, [nondet]) :-
    montado([gran_roquefort]),
    vida_de(e(gran_roquefort, 1), 19),
    elige(e(gran_roquefort, 1), A),
    A == invocar_moho.

test(curarse_gana_a_invocar, [nondet]) :-
    montado([gran_roquefort]),                         % sin moho: invocaria, pero esta bajo
    vida_de(e(gran_roquefort, 1), 10),
    elige(e(gran_roquefort, 1), A),
    A == curarse.

test(las_esporas_solo_valen_una_vez, [nondet]) :-
    montado([gran_roquefort]),
    vida_de(e(gran_roquefort, 1), 10),
    aplicar_efecto(gastar_objeto(e(gran_roquefort, 1), esporas, 1)),
    elige(e(gran_roquefort, 1), A),
    A == invocar_moho.

test(curarse_gana_a_robar, [nondet]) :-
    montado([rata_quesera]),
    aplicar_efecto(ganar_objeto(e(rata_quesera, 1), pocion, 1)),
    vida_de(e(rata_quesera, 1), 2),
    elige(e(rata_quesera, 1), A),
    A == curarse.

test(embestir_gana_a_atacar_y_robar_gana_a_atacar, [nondet]) :-
    montado([bandido_montado, rata_quesera]),
    elige(e(bandido_montado, 1), A1),
    elige(e(rata_quesera, 1), A2),
    A1 == embestir(tuerca),
    A2 == robar_queso.

test(cada_enemigo_tiene_exactamente_una_accion) :-
    montado([rata_quesera, bandido_torpe, moho_saltarin, bandido_montado, gran_roquefort]),
    forall(estado:instancia(E, _),
           (   findall(A, combate:accion_enemigo(E, A), As),
               As = [_]
           )).

test(el_nombre_de_las_acciones_es_cerrado) :-
    montado([rata_quesera, bandido_torpe, moho_saltarin, bandido_montado, gran_roquefort]),
    forall(estado:instancia(E, _),
           (   elige(E, A),
               (   atom(A), memberchk(A, [curarse, invocar_moho, robar_queso, defender])
               ;   compound(A), functor(A, F, 1), memberchk(F, [atacar, embestir])
               )
           )).

:- end_tests(prioridades_de_la_ia).

:- begin_tests(efectos_de_las_acciones).

test(curarse_gasta_el_objeto_y_cura, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)),
    vida_de(e(bandido_torpe, 1), 3),
    combate:efectos_accion(e(bandido_torpe, 1), curarse, Efs),
    Efs == [gastar_objeto(e(bandido_torpe, 1), pocion, 1), curar(e(bandido_torpe, 1), 10),
            mensaje(se_cura, [e(bandido_torpe, 1), 10])],
    aplicar_efectos(Efs),
    estado:vida(e(bandido_torpe, 1), V),
    V == 12,                                           % 3 + 10 no pasa del maximo
    \+ estado:lleva(e(bandido_torpe, 1), pocion, _).

test(las_esporas_curan_ocho, [nondet]) :-
    montado([gran_roquefort]),
    vida_de(e(gran_roquefort, 1), 10),
    combate:efectos_accion(e(gran_roquefort, 1), curarse, Efs),
    aplicar_efectos(Efs),
    estado:vida(e(gran_roquefort, 1), V),
    V == 18,
    \+ estado:lleva(e(gran_roquefort, 1), esporas, _).

test(curarse_sin_nada_que_usar_no_es_legal, [fail]) :-
    montado([bandido_torpe]),
    combate:efectos_accion(e(bandido_torpe, 1), curarse, _).

test(invocar_crea_un_moho_nuevo, [nondet]) :-
    montado([gran_roquefort]),
    combate:efectos_accion(e(gran_roquefort, 1), invocar_moho, Efs),
    Efs == [invocar(moho_saltarin), mensaje(invoca_moho, [e(gran_roquefort, 1)])],
    aplicar_efectos(Efs),
    estado:instancia(e(moho_saltarin, 1), moho_saltarin),
    estado:vida(e(moho_saltarin, 1), 10),
    estado:fila(e(moho_saltarin, 1), frente),
    estado:combatiente(e(moho_saltarin, 1), enemigo).

test(el_segundo_moho_es_el_numero_dos, [nondet]) :-
    montado([gran_roquefort]),
    aplicar_efectos([invocar(moho_saltarin), invocar(moho_saltarin)]),
    estado:instancia(e(moho_saltarin, 2), moho_saltarin).

test(el_moho_invocado_no_esta_en_la_cola_hasta_la_ronda_siguiente) :-
    montado([gran_roquefort]),
    combate:efectos_ronda(E1),
    aplicar_efectos(E1),
    aplicar_efecto(invocar(moho_saltarin)),
    estado:cola_turnos(C),
    \+ memberchk(e(moho_saltarin, 1), C).

test(el_moho_invocado_entra_en_el_orden_de_la_ronda_siguiente) :-
    montado([gran_roquefort]),
    aplicar_efecto(invocar(moho_saltarin)),
    combate:orden_turnos(Orden),
    memberchk(e(moho_saltarin, 1), Orden).

test(invocar_fuera_de_combate_no_vale, [setup(nueva_partida), fail]) :-
    aplicar_efecto(invocar(moho_saltarin)).

test(invocar_un_tipo_desconocido_no_vale, [fail]) :-
    montado([gran_roquefort]),
    aplicar_efecto(invocar(dragon)).

test(solo_el_jefe_puede_invocar_por_regla, [fail]) :-
    montado([bandido_torpe]),
    combate:efectos_accion(e(bandido_torpe, 1), invocar_moho, _).

test(robar_se_lleva_el_queso_mas_fresco, [nondet]) :-
    montado([rata_quesera]),
    aplicar_efecto(ganar_queso(brie, 5, 2)),           % un lote curado: el cheddar fresco va antes
    combate:efectos_accion(e(rata_quesera, 1), robar_queso, Efs),
    Efs == [gastar_queso(cheddar, 0, 1), contar(quesos_robados, 1), mensaje(roba_queso, [e(rata_quesera, 1)])].

test(robar_baja_la_despensa_en_uno, [nondet]) :-
    montado([rata_quesera]),
    economia:queso_total(Antes),
    combate:efectos_accion(e(rata_quesera, 1), robar_queso, Efs),
    aplicar_efectos(Efs),
    economia:queso_total(Despues),
    Despues =:= Antes - 1.

test(si_solo_queda_rancio_se_roba_el_rancio, [nondet]) :-
    montado([rata_quesera]),
    sin_queso,
    aplicar_efecto(ganar_queso(cheddar, 12, 1)),
    combate:efectos_accion(e(rata_quesera, 1), robar_queso, Efs),
    Efs = [gastar_queso(cheddar, 12, 1)|_].

test(robar_sin_queso_no_es_legal, [fail]) :-
    montado([rata_quesera]),
    sin_queso,
    combate:efectos_accion(e(rata_quesera, 1), robar_queso, _).

test(embestir_hace_dos_de_dano_extra, [nondet]) :-
    montado([bandido_montado]),
    combate:efectos_accion(e(bandido_montado, 1), embestir(tuerca), Efs),
    Efs = [dano(tuerca, D)|_],
    D == 7,                                            % 7 - 2 = 5 del golpe normal, mas 2 de embestida
    once(combate:dano(e(bandido_montado, 1), tuerca, Normal)),
    Normal == 5.

test(embestir_marca_que_ya_embistio, [nondet]) :-
    montado([bandido_montado]),
    combate:efectos_accion(e(bandido_montado, 1), embestir(tuerca), Efs),
    memberchk(alterar(e(bandido_montado, 1), embistio, fijo), Efs),
    aplicar_efectos(Efs),
    estado:alterado(e(bandido_montado, 1), embistio, fijo),
    \+ combate:efectos_accion(e(bandido_montado, 1), embestir(tuerca), _).

test(embestir_puede_derribar, [nondet]) :-
    montado([bandido_montado]),
    vida_de(tuerca, 3),
    combate:efectos_accion(e(bandido_montado, 1), embestir(tuerca), Efs),
    memberchk(mensaje(cae, [tuerca]), Efs).

test(embestir_a_quien_no_es_el_mas_debil_no_es_legal, [fail]) :-
    montado([bandido_montado]),
    combate:efectos_accion(e(bandido_montado, 1), embestir(baldomero), _).

test(la_marca_de_embestir_no_sobrevive_al_combate, [nondet]) :-
    montado([bandido_montado]),
    aplicar_efecto(alterar(e(bandido_montado, 1), embistio, fijo)),
    aplicar_efecto(terminar_combate),
    \+ estado:alterado(_, embistio, _).

test(los_objetos_de_los_enemigos_no_sobreviven_al_combate) :-
    montado([gran_roquefort]),
    estado:lleva(e(gran_roquefort, 1), esporas, 1),
    aplicar_efecto(terminar_combate),
    \+ estado:lleva(e(_, _), _, _).

test(el_jefe_nace_con_sus_esporas, [nondet]) :-
    montado([gran_roquefort, bandido_torpe]),
    estado:lleva(e(gran_roquefort, 1), esporas, 1),
    \+ estado:lleva(e(bandido_torpe, 1), _, _).

test(las_acciones_no_modifican_el_estado) :-
    montado([gran_roquefort, rata_quesera, bandido_montado]),
    foto_estado(Antes),
    forall(( member(E, [e(gran_roquefort, 1), e(rata_quesera, 1), e(bandido_montado, 1)]),
             member(A, [curarse, invocar_moho, robar_queso, embestir(tuerca), atacar(tuerca), defender]) ),
           ( combate:efectos_accion(E, A, _) -> true ; true )),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(efectos_de_las_acciones).

:- begin_tests(corte_y_gemela).

% Un surtido de escenarios: cada uno monta un estado de combate distinto.
escenario(1) :- montado([bandido_torpe]).
escenario(2) :- montado([rata_quesera, rata_quesera]).
escenario(3) :- montado([bandido_montado]).
escenario(4) :- montado([gran_roquefort]).
escenario(5) :- montado([gran_roquefort, moho_saltarin]).
escenario(6) :- montado([bandido_torpe]),
                aplicar_efecto(ganar_objeto(e(bandido_torpe, 1), pocion, 1)), vida_de(e(bandido_torpe, 1), 3).
escenario(7) :- montado([rata_quesera]), sin_queso.
escenario(8) :- montado([bandido_montado]), aplicar_efecto(alterar(e(bandido_montado, 1), embistio, fijo)).
escenario(9) :- montado([bandido_torpe]), aplicar_efecto(alterar(e(bandido_torpe, 1), aturdido, 1)).
escenario(10) :- montado([bandido_torpe]), retractall(estado:combatiente(_, jugador)).
escenario(11) :- montado([gran_roquefort]), vida_de(e(gran_roquefort, 1), 15).
escenario(12) :- montado([moho_saltarin, rata_quesera, bandido_montado, bandido_torpe, gran_roquefort]).
escenario(13) :- montado([gran_roquefort, moho_saltarin, moho_saltarin]),
                 aplicar_efecto(dano(e(moho_saltarin, 1), 99)), aplicar_efecto(dano(e(moho_saltarin, 2), 99)).
escenario(14) :- montado([rata_quesera]), aplicar_efecto(ganar_objeto(e(rata_quesera, 1), pocion, 1)),
                 vida_de(e(rata_quesera, 1), 2).
escenario(15) :- montado([bandido_torpe, bandido_montado]), aplicar_efecto(dano(baldomero, 99)),
                 aplicar_efecto(dano(tuerca, 99)).

test(la_gemela_sin_corte_da_la_misma_accion_en_15_escenarios) :-
    forall(( between(1, 15, N), escenario(N) ),
           forall(estado:instancia(E, _),
                  (   findall(A, combate:accion_enemigo(E, A), [A1]),
                      findall(A, combate:accion_enemigo_sin_corte(E, A), [A2]),
                      A1 == A2
                  ))).

test(la_gemela_tiene_una_sola_solucion_por_enemigo) :-
    forall(( between(1, 15, N), escenario(N) ),
           forall(estado:instancia(E, _),
                  (   findall(A, combate:accion_enemigo_sin_corte(E, A), As), As = [_] ))).

test(la_tabla_tiene_seis_reglas_con_numeros_distintos) :-
    findall(N, clause(combate:regla_ia(N, _, _), _), Ns),
    msort(Ns, S),
    S == [1, 2, 3, 4, 5, 6].

test(el_numero_de_la_regla_ganadora_es_la_prioridad_de_la_clausula, [nondet]) :-
    escenario(6),                                      % cura
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P1),
    P1 = regla(_, 1, _),
    escenario(4),                                      % invoca
    solve(combate:accion_enemigo(e(gran_roquefort, 1), _), P2),
    P2 = regla(_, 2, _),
    escenario(2),                                      % roba
    solve(combate:accion_enemigo(e(rata_quesera, 1), _), P3),
    P3 = regla(_, 3, _),
    escenario(3),                                      % embiste
    solve(combate:accion_enemigo(e(bandido_montado, 1), _), P4),
    P4 = regla(_, 4, _),
    escenario(1),                                      % ataca
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P5),
    P5 = regla(_, 5, _),
    escenario(10),                                     % comodin
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P6),
    P6 = hecho(accion_enemigo(_, defender)).      % el comodin es un hecho: sin cuerpo ni corte

test(solve_da_lo_mismo_que_ejecutar_con_el_enemigo_ligado) :-
    forall(( between(1, 15, N), escenario(N) ),
           forall(estado:instancia(E, _),
                  (   findall(A, combate:accion_enemigo(E, A), Directo),
                      findall(A, solve(combate:accion_enemigo(E, A), _), ConSolve),
                      Directo =@= ConSolve
                  ))).

test(solve_da_lo_mismo_que_ejecutar_con_el_enemigo_libre) :-
    forall(( between(1, 15, N), escenario(N) ),
           (   findall(E-A, combate:accion_enemigo(E, A), Directo),
               findall(E-A, solve(combate:accion_enemigo(E, A), _), ConSolve),
               Directo =@= ConSolve
           )).

test(el_corte_se_ve_en_la_prueba, [nondet]) :-
    escenario(1),
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P),
    explicar:prueba_a_lineas(P, Lineas),
    memberchk('[ok] accion_enemigo(e(bandido_torpe, 1), atacar(tuerca))   [clausula 5 + corte]', Lineas),
    memberchk('   [ok] corte   [corte: se descartaron las clausulas siguientes]', Lineas).

test(el_comodin_no_lleva_corte, [nondet]) :-
    escenario(10),
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), P),
    explicar:prueba_a_lineas(P, Lineas),
    memberchk('[ok] accion_enemigo(e(bandido_torpe, 1), defender)   [hecho]', Lineas),
    \+ ( member(L, Lineas), sub_atom(L, _, _, _, 'corte') ).

% --- La leccion de la Conferencia 4: el corte rojo y los modos ---
test(con_la_accion_ligada_el_corte_no_interviene_y_el_comodin_dice_si, [nondet]) :-
    escenario(1),                                      % puede atacar: la accion real es atacar
    combate:accion_enemigo(e(bandido_torpe, 1), defender).

test(la_gemela_declarativa_dice_no_a_lo_mismo, [fail]) :-
    escenario(1),
    combate:accion_enemigo_sin_corte(e(bandido_torpe, 1), defender).

test(con_la_accion_libre_las_dos_coinciden, [nondet]) :-
    escenario(1),
    combate:accion_enemigo(e(bandido_torpe, 1), A1),
    combate:accion_enemigo_sin_corte(e(bandido_torpe, 1), A2),
    A1 == A2.

test(a_igual_accion_ligada_la_gemela_acierta_en_cada_regla) :-
    forall(( between(1, 15, N), escenario(N) ),
           forall(estado:instancia(E, _),
                  (   combate:accion_enemigo_sin_corte(E, Real),
                      forall(member(Otra, [curarse, invocar_moho, robar_queso, defender]),
                             (   Otra == Real
                             ->  combate:accion_enemigo_sin_corte(E, Otra)
                             ;   \+ combate:accion_enemigo_sin_corte(E, Otra)
                             ))
                  ))).

test(la_ia_no_modifica_el_estado) :-
    escenario(12),
    foto_estado(Antes),
    forall(estado:instancia(E, _), ( combate:accion_enemigo(E, _) -> true ; true )),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(corte_y_gemela).

:- begin_tests(la_ia_en_el_bucle).

test(la_rata_roba_en_su_turno, [nondet]) :-
    empieza([rata_quesera], _),
    economia:queso_total(Antes),
    ordena(defender, _), ordena(defender, _), ordena(defender, Items),   % Baldomero, Pimentina, Tuerca
    memberchk(msg(roba_queso, [e(rata_quesera, 1)], _), Items),
    economia:queso_total(Despues),
    Despues =:= Antes - 1.

test(el_bandido_montado_embiste_una_vez_y_luego_ataca, [nondet]) :-
    empieza([bandido_montado], _),
    ordena(defender, _), ordena(defender, _), ordena(defender, Primera),   % hasta su turno
    memberchk(msg(embiste, [e(bandido_montado, 1), tuerca, 5], _), Primera),
    ordena(defender, _),                                                    % Rufino
    ordena(defender, _), ordena(defender, _), ordena(defender, Segunda),    % ronda 2 hasta su turno
    \+ memberchk(msg(embiste, _, _), Segunda),
    memberchk(msg(golpe, [e(bandido_montado, 1), _, _], _), Segunda).

test(el_jefe_invoca_en_su_primer_turno_y_el_moho_juega_en_la_ronda_siguiente, [nondet]) :-
    empieza([gran_roquefort], Inicio),
    ordena(defender, Items),                           % Baldomero; el jefe (17) invoca
    append(Inicio, Items, Todo),
    memberchk(msg(invoca_moho, [e(gran_roquefort, 1)], _), Todo),
    estado:instancia(e(moho_saltarin, 1), moho_saltarin),
    estado:cola_turnos(C1),
    \+ memberchk(e(moho_saltarin, 1), C1),             % todavia no esta en la cola de esta ronda
    defiende_todos([b, c, d]),                         % el resto de la ronda
    estado:cola_turnos(C2),
    memberchk(e(moho_saltarin, 1), C2).                % ya juega en la ronda 2

test(el_jefe_se_cura_una_sola_vez_en_el_combate, [nondet]) :-
    empieza([gran_roquefort], _),
    aplicar_efecto(dano(e(gran_roquefort, 1), 42)),    % le quedan 18
    ordena(defender, Items),                           % Baldomero; el jefe se cura
    memberchk(msg(se_cura, [e(gran_roquefort, 1), 8], _), Items),
    estado:vida(e(gran_roquefort, 1), V),
    V == 26,
    \+ estado:lleva(e(gran_roquefort, 1), esporas, _),
    aplicar_efecto(dano(e(gran_roquefort, 1), 8)),     % otra vez a 18
    defiende_todos([b, c, d, e]),                      % una ronda entera: ya no se cura
    estado:vida(e(gran_roquefort, 1), V2),
    V2 =< 18.

test(la_victoria_contra_el_jefe_pide_acabar_tambien_con_los_mohos, [nondet]) :-
    empieza([gran_roquefort], _),
    ordena(defender, _),                               % el jefe invoca un moho
    aplicar_efecto(dano(e(gran_roquefort, 1), 99)),    % cae el jefe
    estado:en_combate(_),                              % pero queda el moho: sigue el combate
    \+ combate:fin_combate(_).

test(un_combate_con_cada_tipo_acaba_sin_dejar_restos, [nondet]) :-
    empieza([rata_quesera, bandido_torpe, moho_saltarin, bandido_montado], _),
    jugar(120),
    (   estado:fin_partida(_) -> true
    ;   \+ estado:en_combate(_),
        \+ estado:instancia(_, _),
        \+ estado:lleva(e(_, _), _, _),
        \+ estado:alterado(_, embistio, _)
    ).

test(explicar_tras_un_turno_enemigo_dice_la_prioridad, [nondet]) :-
    empieza([bandido_torpe], _),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    pantalla(explicar, Texto),
    sub_atom(Texto, _, _, _, 'Eligió la regla de prioridad 5 de 6'),
    sub_atom(Texto, _, _, _, 'Por qué el Bandido Torpe hizo eso').

test(la_pantalla_explica_el_comodin_como_la_ultima_regla, [nondet]) :-
    montado([bandido_torpe]),
    retractall(estado:combatiente(_, jugador)),
    solve(combate:accion_enemigo(e(bandido_torpe, 1), _), Prueba),
    with_output_to(atom(Texto),
                   ui:mostrar(resultado([vista(prueba, accion_enemigo(e(bandido_torpe, 1)), Prueba)]))),
    sub_atom(Texto, _, _, _, 'Eligió la última regla (prioridad 6 de 6)').

test(explicar_tras_robar_la_rata_dice_prioridad_3, [nondet]) :-
    empieza([rata_quesera], _),
    ordena(defender, _), ordena(defender, _), ordena(defender, _),
    pantalla(explicar, Texto),
    sub_atom(Texto, _, _, _, 'Eligió la regla de prioridad 3 de 6'),
    sub_atom(Texto, _, _, _, 'accion_enemigo(e(rata_quesera, 1), robar_queso)').

test(las_pantallas_de_la_ia_no_ensenan_terminos_crudos, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    forall(member(Cmd, [pelear([rata_quesera, bandido_montado, bandido_torpe]), defender, defender, defender,
                        defender, defender, defender, defender, mirar, explicar]),
           (   pantalla(Cmd, Texto),
               \+ sub_atom(Texto, _, _, _, 'msg('),
               \+ sub_atom(Texto, _, _, _, 'error('),
               \+ sub_atom(Texto, _, _, _, '~w'),
               \+ sub_atom(Texto, _, _, _, '[msg')
           )).

test(si_el_comodin_no_se_puede_ejecutar_el_enemigo_pasa, [nondet]) :-
    montado([bandido_torpe]),
    aplicar_efecto(siguiente_ronda([e(bandido_torpe, 1)])),
    aplicar_efecto(alterar(e(bandido_torpe, 1), aturdido, 1)),
    juego:turno_enemigo(e(bandido_torpe, 1), Items),   % la IA dice defender, pero aturdido no puede
    memberchk(msg(pasa, [e(bandido_torpe, 1)], _), Items),
    estado:cola_turnos(C),
    C == [].

jugar(0) :- !.
jugar(N) :-
    (   ( \+ estado:en_combate(_) ; estado:fin_partida(_) )
    ->  true
    ;   (   member(Obj, [rata_quesera, bandido_torpe, moho_saltarin, bandido_montado]),
            ordena(atacar(Obj), I), \+ I = [error(_)|_]
        ->  true
        ;   ordena(defender, _)
        ),
        N1 is N - 1,
        jugar(N1)
    ).

:- end_tests(la_ia_en_el_bucle).
