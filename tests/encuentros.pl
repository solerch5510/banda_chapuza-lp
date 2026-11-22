% encuentros.pl (pruebas)
% Los encuentros al llegar a una zona (docs/13-ampliacion.md, 5): al llegar al bosque, al Camino Real o a las cuevas
% se tiran dos dados con la semilla del juego (como el botin): el primero dice si sale algo y el segundo cual de los
% grupos de la zona. Es azar reproducible: la misma semilla, el mismo susto.
%   (1) la tabla; (2) las reglas puras; (3) el viaje de verdad; (4) el contrato de la zona; (5) explicar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/encuentros -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).
% Esta es la unica suite que enciende los encuentros (cada prueba los enciende y los apaga).
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').

encender :- set_prolog_flag(banda_encuentros, true).
apagar   :- set_prolog_flag(banda_encuentros, false).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

orden(Cmd, Items) :- juego:ejecutar(Cmd, resultado(Items)).

% semilla_de(+Zona, +Que, -S): una semilla cuyos dos dados dan lo que se pide: sale(Indice) o nada
semilla_de(Zona, sale(I), S) :-
    mundo:probabilidad_de_encuentro(Zona, P),
    between(0, 3000, S),
    combate:tirar_encuentro(Zona, S, T, I, _), T < P, !.
semilla_de(Zona, nada, S) :-
    mundo:probabilidad_de_encuentro(Zona, P),
    between(0, 3000, S),
    combate:tirar_encuentro(Zona, S, T, _, _), T >= P, !.

% partida_en(+Zona, +Semilla): partida nueva, esa semilla y la Banda ya en la zona vecina desde la que se llega
partida(Semilla) :-
    nueva_partida,
    estado:aplicar_efectos([fijar_semilla(Semilla)]).

% a un enemigo vivo, el que sea
objetivo_vivo(T) :-
    estado:instancia(E, T), compania:vivo(E), !.

orden_de_turno(Cmd) :-
    estado:cola_turnos([A|_]),
    mundo:habilidad_de(A, H),
    objetivo_vivo(T),
    (   combate:objetivo_de_habilidad(H, ninguno)
    ->  Cmd = habilidad
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_habilidad(A, H, E)
    ->  Cmd = habilidad(T)
    ;   estado:instancia(E, T), compania:vivo(E), combate:puede_atacar(A, E)
    ->  Cmd = atacar(T)
    ;   Cmd = defender
    ).

% combatir_mientras(+Condicion, -Items): juega turnos mientras haya combate y la Condicion se cumpla
combatir_mientras(Cond, Todos) :-
    (   estado:en_combate(_), \+ estado:fin_partida(_), call(Cond)
    ->  once(orden_de_turno(Cmd)), orden(Cmd, Is),
        combatir_mientras(Cond, Resto), append(Is, Resto, Todos)
    ;   Todos = []
    ).

:- begin_tests(la_tabla).

test(las_zonas_con_encuentros_tienen_probabilidad_valida) :-
    forall(mundo:probabilidad_de_encuentro(Z, P),
           (   assertion(mundo:zona(Z, _)), assertion(integer(P)), assertion(P > 0), assertion(P < 100) )).

test(cada_zona_con_encuentros_tiene_probabilidad_y_al_reves) :-
    forall(mundo:encuentro(Z, _), assertion(mundo:probabilidad_de_encuentro(Z, _))),
    forall(mundo:probabilidad_de_encuentro(Z, _), assertion(mundo:encuentro(Z, _))).

test(cada_grupo_es_una_lista_de_enemigos_que_existen) :-
    forall(mundo:encuentro(_, G),
           (   assertion(G = [_|_]),
               forall(member(T, G), assertion(mundo:enemigo(T, _, _, _))) )).

test(el_jefe_no_sale_en_un_encuentro) :-
    assertion(\+ ( mundo:encuentro(_, G), memberchk(gran_roquefort, G) )).

test(los_enemigos_de_contrato_no_se_repiten_en_encuentros_de_su_zona) :-
    % el ganso es del contrato del Camino Real: un encuentro con el ganso confundiria con el contrato
    assertion(\+ ( mundo:encuentro(camino_real, G), memberchk(ganso_de_peaje, G) )).

test(la_taberna_y_las_zonas_pacificas_no_tienen_encuentros) :-
    forall(mundo:zona_pacifica(Z), assertion(\+ mundo:probabilidad_de_encuentro(Z, _))),
    assertion(\+ mundo:probabilidad_de_encuentro(aldea, _)),
    assertion(\+ mundo:probabilidad_de_encuentro(castillo, _)).

test(las_zonas_peligrosas_son_el_bosque_el_camino_y_las_cuevas) :-
    findall(Z, mundo:probabilidad_de_encuentro(Z, _), Zs0), msort(Zs0, Zs),
    assertion(Zs == [bosque, camino_real, cuevas]).

:- end_tests(la_tabla).

:- begin_tests(las_reglas_puras, [setup(encender), cleanup(apagar)]).

test(dos_dados_avanzan_la_semilla_dos_pasos) :-
    combate:tirar_encuentro(bosque, 77, T, I, S),
    estado:tirada(100, 77, T, S1),
    findall(G, mundo:encuentro(bosque, G), Gs), length(Gs, N),
    estado:tirada(N, S1, I, S).

test(sale_con_una_tirada_menor_que_la_probabilidad) :-
    mundo:probabilidad_de_encuentro(bosque, P), P1 is P - 1,
    combate:sale_encuentro(bosque, P1, 0, G),
    assertion(G == [seta_belicosa, seta_belicosa, seta_curandera, moho_saltarin, moho_saltarin]).

test(con_una_tirada_igual_a_la_probabilidad_no_sale) :-
    mundo:probabilidad_de_encuentro(bosque, P),
    assertion(\+ combate:sale_encuentro(bosque, P, 0, _)).

test(el_segundo_dado_elige_el_grupo) :-
    findall(G, combate:sale_encuentro(camino_real, 0, _, G), Gs),
    findall(G, mundo:encuentro(camino_real, G), Esperados),
    assertion(Gs == Esperados).

test(una_zona_tranquila_no_tira_ni_toca_la_semilla) :-
    assertion(\+ combate:tirar_encuentro(aldea, 123, _, _, _)),
    assertion(\+ combate:tirar_encuentro(taberna, 123, _, _, _)),
    assertion(\+ combate:tirar_encuentro(castillo, 123, _, _, _)).

test(con_el_interruptor_apagado_no_tira) :-
    apagar,
    assertion(\+ combate:tirar_encuentro(bosque, 5, _, _, _)),
    encender.

test(la_misma_semilla_da_el_mismo_encuentro) :-
    combate:tirar_encuentro(cuevas, 1234, T, I, S),
    combate:tirar_encuentro(cuevas, 1234, T2, I2, S2),
    assertion(T-I-S == T2-I2-S2).

test(el_indice_cae_siempre_dentro_de_los_grupos) :-
    forall(( mundo:probabilidad_de_encuentro(Z, _), between(0, 200, S) ),
           (   combate:tirar_encuentro(Z, S, T, I, _),
               assertion(integer(T)), assertion(T >= 0), assertion(T < 100),
               findall(G, mundo:encuentro(Z, G), Gs), length(Gs, N),
               assertion(I >= 0), assertion(I < N) )).

test(con_muchas_semillas_salen_todos_los_grupos_de_cada_zona) :-
    forall(mundo:probabilidad_de_encuentro(Z, _),
           (   findall(G, mundo:encuentro(Z, G), Gs),
               findall(G, ( between(0, 400, S), combate:tirar_encuentro(Z, S, T, I, _),
                            combate:sale_encuentro(Z, T, I, G) ), Vistos0),
               sort(Vistos0, Vistos), sort(Gs, Todos),
               assertion(Vistos == Todos) )).

test(la_frecuencia_se_parece_a_la_probabilidad) :-
    % de 0 a 4999 semillas, la parte que sale queda cerca de la probabilidad (+-6 puntos)
    forall(mundo:probabilidad_de_encuentro(Z, P),
           (   findall(x, ( between(0, 4999, S), combate:tirar_encuentro(Z, S, T, I, _),
                            combate:sale_encuentro(Z, T, I, _) ), Xs),
               length(Xs, N), Pct is N * 100 // 5000,
               assertion(abs(Pct - P) =< 6) )).

:- end_tests(las_reglas_puras).

:- begin_tests(el_viaje, [setup(encender), cleanup(apagar)]).

test(un_encuentro_empieza_un_combate_al_llegar) :-
    semilla_de(camino_real, sale(I), S), partida(S),
    findall(G, mundo:encuentro(camino_real, G), Gs), nth0(I, Gs, Grupo),
    orden(ir(camino_real), Items),
    assertion(estado:fase(combate)),
    assertion(memberchk(msg(encuentro, [camino_real], _), Items)),
    forall(member(T, Grupo), assertion(estado:instancia(_, T))),
    findall(Tp, estado:instancia(_, Tp), Tipos), msort(Tipos, TS), msort(Grupo, GS),
    assertion(TS == GS).

test(un_encuentro_no_es_un_contrato) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    orden(ir(camino_real), _),
    assertion(\+ estado:marca(combate_de(_))).

test(sin_encuentro_el_viaje_sigue_igual_y_la_semilla_avanza) :-
    semilla_de(camino_real, nada, S), partida(S),
    orden(ir(camino_real), Items),
    assertion(\+ estado:fase(combate)),
    assertion(\+ memberchk(msg(encuentro, _, _), Items)),
    combate:tirar_encuentro(camino_real, S, _, _, Esperada),
    estado:semilla(Hoy),
    Esperada1 is Esperada mod 65536,
    assertion(Hoy == Esperada1).

test(con_encuentro_la_semilla_tambien_avanza_dos_pasos) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    orden(ir(camino_real), _),
    combate:tirar_encuentro(camino_real, S, _, _, Esperada),
    estado:semilla(Hoy),
    Esperada1 is Esperada mod 65536,
    assertion(Hoy == Esperada1).

test(una_zona_tranquila_no_toca_la_semilla) :-
    partida(4242),
    orden(ir(aldea), _),
    estado:semilla(S), assertion(S == 4242).

test(el_mismo_viaje_con_la_misma_semilla_es_el_mismo_encuentro) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    orden(ir(camino_real), _), findall(T, estado:instancia(_, T), A),
    partida(S),
    orden(ir(camino_real), _), findall(T, estado:instancia(_, T), B),
    assertion(A == B).

test(apagado_el_interruptor_nunca_hay_encuentros) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    apagar,
    orden(ir(camino_real), _),
    assertion(\+ estado:fase(combate)),
    estado:semilla(Hoy), assertion(Hoy == S),
    encender.

test(ganar_un_encuentro_acaba_el_combate_y_sube_la_moral) :-
    semilla_de(camino_real, sale(0), S), partida(S),
    orden(ir(camino_real), _),
    estado:moral(baldomero, M0),
    combatir_mientras(true, Items),
    (   estado:fin_partida(_) -> true     % si la Banda cae, ya no hay mas que ver (no pasa con esta semilla)
    ;   assertion(\+ estado:en_combate(_)),
        assertion(memberchk(msg(victoria, [], _), Items)),
        estado:moral(baldomero, M1), assertion(M1 >= M0)
    ).

test(el_encuentro_gasta_el_dia_de_viaje_como_siempre) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    estado:dia(D0),
    orden(ir(camino_real), _),
    estado:dia(D1), assertion(D1 =:= D0 + 1).

test(no_hay_encuentro_con_la_partida_acabada) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    estado:aplicar_efectos([fin(victoria)]),
    juego:iniciar_encuentro(camino_real, Items),
    assertion(Items == []),
    assertion(\+ estado:en_combate(_)).

test(no_se_tira_dos_veces_con_un_combate_en_marcha) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    orden(ir(camino_real), _),
    estado:semilla(S1),
    juego:iniciar_encuentro(camino_real, Items),
    assertion(Items == []),
    estado:semilla(S2), assertion(S1 == S2).

:- end_tests(el_viaje).

:- begin_tests(con_un_contrato_en_la_zona, [setup(encender), cleanup(apagar)]).

test(el_encuentro_va_primero_y_el_objetivo_del_contrato_despues) :-
    semilla_de(camino_real, sale(0), S), partida(S),      % bandido torpe: se gana
    orden(aceptar(peaje_del_ganso), _),
    orden(ir(camino_real), _),
    assertion(\+ estado:marca(combate_de(_))),             % primero el encuentro
    assertion(\+ ( estado:instancia(_, ganso_de_peaje) )),
    combatir_mientras(\+ estado:marca(combate_de(_)), _),
    (   estado:fin_partida(_) -> true
    ;   assertion(estado:en_combate(_)),                   % ... y despues, el combate del contrato
        assertion(estado:marca(combate_de(peaje_del_ganso))),
        assertion(estado:instancia(_, ganso_de_peaje))
    ).

test(si_se_pierde_el_encuentro_no_hay_objetivo) :-
    semilla_de(camino_real, sale(_), S), partida(S),
    orden(aceptar(peaje_del_ganso), _),
    orden(ir(camino_real), _),
    estado:aplicar_efectos([fin(derrota(derrota_combate))]),
    assertion(estado:fase(fin)).

:- end_tests(con_un_contrato_en_la_zona).

:- begin_tests(explicar, [setup(encender), cleanup(apagar)]).

test(explicar_dice_por_que_salio_el_encuentro) :-
    semilla_de(bosque, sale(_), S), partida(S),
    estado:aplicar_efectos([viajar(aldea), visitar(aldea)]),
    orden(ir(bosque), _),
    orden(explicar, Items),
    assertion(memberchk(vista(prueba, encuentro(bosque), _), Items)).

test(la_prueba_nombra_la_regla_del_encuentro) :-
    semilla_de(bosque, sale(_), S), partida(S),
    estado:aplicar_efectos([viajar(aldea), visitar(aldea)]),
    orden(ir(bosque), _),
    estado:ultima_prueba(encuentro(bosque), Prueba),
    explicar:meta_de_prueba(Prueba, Meta),
    assertion(Meta = sale_encuentro(bosque, _, _, _)).

test(el_comentario_de_explicar_existe_para_la_regla) :-
    narrador:frase(sale_encuentro(bosque, 7, 0, [seta_belicosa]), _, _),
    !.

test(cada_zona_con_encuentros_tiene_su_frase_de_aviso) :-
    forall(mundo:probabilidad_de_encuentro(Z, _),
           (   narrador:frase(suceso(encuentro(Z)), _, Texto0),
               ( Texto0 = Texto-_ -> true ; Texto = Texto0 ),
               assertion(atom(Texto)) )).

:- end_tests(explicar).
