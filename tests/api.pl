% api.pl (pruebas)
% F-1 (extra): el adaptador JSON y el servidor. (1) nodos_de_lineas/2 convierte las lineas de explicar y por_que_no
% en nodos con profundidad, estado y tipo. (2) Cada item del juego tiene su JSON y ninguno falla ni se escapa
% como termino crudo. (3) ejecutar_orden/2 se comporta como la consola (mismos errores, mismas escenas) y nunca
% falla. (4) El estado y las acciones habilitadas son ciertos y no tocan la partida. (5) Lo que cuenta la web es
% lo que cuenta la consola. (6) El servidor HTTP responde de verdad (GET, POST, estaticos, 404, rutas fuera de web/).
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/api -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library('http/json')).
:- use_module(library('http/http_header')).
:- use_module(library('http/http_open')).
:- use_module(library(socket)).
:- use_module(library('http/thread_httpd')).
:- use_module(library('http/http_dispatch')).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').
:- use_module('../src/servidor').

% ---------------------------------------------------------------------------
% Ayudantes
% ---------------------------------------------------------------------------
campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% orden(+Texto, -Respuesta): una orden por la API.
orden(Orden, R) :-
    (   atom(Orden) -> Texto = Orden ; format(atom(Texto), '~q', [Orden]) ),
    ejecutar_orden(Texto, R).

items_de(R, Is) :- campo(R, items, Is).
tipos_de(R, Ts) :- items_de(R, Is), findall(T, ( member(I, Is), campo(I, tipo, T) ), Ts).
item_de_tipo(R, Tipo, I) :- items_de(R, Is), member(I, Is), campo(I, tipo, Tipo), !.
estado_de(R, E) :- campo(R, estado, E).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% json_texto(+Json, -Atomo): el JSON tal cual se escribiria.
json_texto(Json, Atomo) :-
    with_output_to(atom(Atomo), json_write(current_output, Json, [width(0)])).

% nodos de un item: lista de t(Prof, Estado, Tipo, Texto)
nodos_de(Item, Ns) :-
    campo(Item, nodos, Nodos),
    findall(t(P, E, T, X),
            ( member(N, Nodos), campo(N, profundidad, P), campo(N, estado, E), campo(N, tipo, T), campo(N, texto, X) ),
            Ns).

foto(f(Zona, Dia, Compania, Vidas, Marcas, Quesos)) :-
    estado:en_zona(Zona), estado:dia(Dia),
    findall(I, estado:en_compania(I), Compania),
    findall(I-V, estado:vida(I, V), Vidas),
    findall(M, estado:marca(M), Marcas),
    findall(Q, estado:queso(Q, _, _), Quesos).

% lo que la consola imprimiria para una orden (misma ruta que main:procesar/2)
consola(Termino, Texto) :-
    with_output_to(atom(Texto), main:procesar(Termino, _)).

% ---------------------------------------------------------------------------
:- begin_tests(los_nodos).

test(una_prueba_con_sangria_de_tres) :-
    nodos_de_lineas(['[ok] a(1)   [clausula 2]',
                     '   [ok] b(1)   [hecho]',
                     '   [ok] 3 is 1+2   [builtin]',
                     '      [ok] c(2)   [hecho]'], Ns),
    findall(P, ( member(json(Cs), Ns), memberchk(profundidad=P, Cs) ), Ps),
    assertion(Ps == [0, 1, 1, 2]),
    findall(T, ( member(json(Cs), Ns), memberchk(tipo=T, Cs) ), Ts),
    assertion(Ts == [regla, hecho, calculo, hecho]).

test(la_clausula_y_el_corte_se_leen_de_la_marca) :-
    nodos_de_lineas(['[ok] x(1)   [clausula 5 + corte]'], [json(Cs)]),
    assertion(memberchk(clausula=5, Cs)),
    assertion(memberchk(corte= @(true), Cs)),
    assertion(memberchk(tipo=regla, Cs)).

test(sin_corte_ni_clausula_en_un_hecho) :-
    nodos_de_lineas(['[ok] x(1)   [hecho]'], [json(Cs)]),
    assertion(memberchk(clausula= @(null), Cs)),
    assertion(memberchk(corte= @(false), Cs)).

test(el_pliegue_del_resumido_son_los_plegados) :-
    nodos_de_lineas(['[ok] a   [clausula 1]   [+12 nodos]', '[ok] b   [hecho]   [+1 nodo]'], [json(A), json(B)]),
    assertion(memberchk(plegados=12, A)),
    assertion(memberchk(plegados=1, B)),
    assertion(memberchk(marca='clausula 1', A)).

test(los_tipos_de_marca) :-
    Casos = [ '[ok] a   [builtin]'-calculo,
              '[ok] a   [no demostrable]'-negacion,
              '[ok] corte   [corte: se descartaron las clausulas siguientes]'-corte,
              '[ok] a   [findall: 2 solucion(es)]'-agregado,
              '[ok] a   [forall: 3 caso(s)]'-agregado,
              '[ok] a   [rama then]'-condicional,
              '[no] a   [falso]'-calculo,
              '[no] a   [no hay ningun hecho ni clausula]'-sin_clausula,
              '[no] a   [se agoto la profundidad del diagnostico]'-limite,
              '[no] a   [2 clausulas aplicables y ninguna se cumple]'-regla ],
    forall(member(L-Esperado, Casos),
           (   nodos_de_lineas([L], [json(Cs)]),
               assertion(memberchk(tipo=Esperado, Cs))
           )).

test(el_estado_ok_no_o_info) :-
    nodos_de_lineas(['[ok] a   [hecho]', '[no] b', 'porque a y b son ciertos.'], Ns),
    findall(E, ( member(json(Cs), Ns), memberchk(estado=E, Cs) ), Es),
    assertion(Es == [ok, no, info]).

test(los_diagnosticos_con_prefijos_dan_profundidad) :-
    nodos_de_lineas(['[no] p(1)   [clausula 1]',
                     '  |- [ok] a(1)',
                     '  |- [ok] \\+ b(1)',
                     '  \\- [no] c(1)',
                     '        porque c(1) es cierto.'], Ns),
    findall(P-T, ( member(json(Cs), Ns), memberchk(profundidad=P, Cs), memberchk(tipo=T, Cs) ), Ps),
    assertion(Ps == [0-regla, 1-paso, 1-negacion, 1-paso, 2-comentario]).

test(una_negacion_sin_marca_se_reconoce_por_el_texto) :-
    nodos_de_lineas(['  |- [ok] \\+ esta_en_huelga(baldomero)'], [json(Cs)]),
    assertion(memberchk(tipo=negacion, Cs)),
    assertion(memberchk(texto='\\+ esta_en_huelga(baldomero)', Cs)).

test(sin_lineas_sin_nodos) :-
    nodos_de_lineas([], Ns), assertion(Ns == []).

:- end_tests(los_nodos).

% ---------------------------------------------------------------------------
:- begin_tests(nombres_legibles).

test(una_instancia_sale_con_su_nombre) :-
    api:legible('dano(baldomero, e(bandido_torpe, 1), 9)', L),
    assertion(L == 'dano(baldomero, Bandido Torpe, 9)').

test(la_segunda_instancia_lleva_numero) :-
    api:legible('x e(rata_quesera,2) y e(rata_quesera, 3)', L),
    assertion(L == 'x Rata Quesera #2 y Rata Quesera #3').

test(solo_se_cambia_e_aislada_no_el_final_de_una_palabra) :-
    api:legible('be(a, 1) vive(a, 1) se(x, 2)', L),
    assertion(L == 'be(a, 1) vive(a, 1) se(x, 2)').

test(lo_que_no_es_una_instancia_no_se_toca) :-
    forall(member(T, ['e(a, )', 'e(, 1)', 'e(a b, 1)', 'sin nada', '', 'e(x, 1', 'teme(baldomero, caballo)']),
           ( api:legible(T, L), assertion(L == T) )).

test(dentro_de_otro_termino) :-
    api:legible('tipo_de(e(bandido_montado, 1), bandido_montado)', L),
    assertion(L == 'tipo_de(Bandido Montado, bandido_montado)').

test(los_nodos_del_diagnostico_traen_el_nombre_legible_y_el_texto_original) :-
    orden('demo(combate)', _),
    orden('por_que_no(atacar(baldomero, bandido_montado))', R),
    item_de_tipo(R, diag, D), campo(D, nodos, Ns),
    findall(T-L, ( member(N, Ns), campo(N, texto, T), campo(N, legible, L) ), Ps),
    assertion(( member(T1-L1, Ps), contiene(T1, 'e(bandido_montado, 1)'), contiene(L1, 'Bandido Montado'),
                \+ contiene(L1, 'e(bandido_montado') )),
    campo(D, porque_legible, PL), assertion(contiene(PL, 'Bandido Montado')),
    campo(D, porque, P), assertion(contiene(P, 'e(bandido_montado, 1)')), !.

test(los_motivos_de_los_descartes_tambien) :-
    orden('demo(ia)', _), orden(defender, _), orden(defender, _), orden(defender, _),
    orden(explicar, R), item_de_tipo(R, decision, D), campo(D, descartes, Ds),
    forall(member(X, Ds), ( campo(X, motivo_legible, M), assertion(atom(M)), assertion(\+ contiene(M, 'e(bandido')) )).

test(un_descarte_con_instancias_en_su_motivo) :-
    api:descarte_json(resumido, descarte(1, curarse, builtin_falso(e(bandido_torpe, 1) = e(rata_quesera, 2))), J),
    campo(J, motivo, M), campo(J, motivo_legible, L),
    assertion(contiene(M, 'e(bandido_torpe, 1)')),
    assertion(L == 'Bandido Torpe=Rata Quesera #2 es falso').

:- end_tests(nombres_legibles).

% ---------------------------------------------------------------------------
:- begin_tests(los_items).

test(todos_los_tipos_de_item_tienen_json_y_ninguno_es_desconocido) :-
    nueva_partida,
    Ordenes = [mirar, inventario, compania, contratos, ayuda, demo, 'demo(combate)', explicar,
               'explicar(atacar(baldomero, bandido_torpe))', 'por_que_no(atacar(baldomero, bandido_montado))',
               'nivel(detallado)', atacar(bandido_torpe), defender],
    forall(member(O, Ordenes),
           (   orden(O, R),
               tipos_de(R, Ts),
               assertion(\+ memberchk(desconocido, Ts))
           )).

test(un_item_que_no_se_conoce_sale_como_desconocido) :-
    items_json([cosa_rara(1)], [J]),
    campo(J, tipo, T), campo(J, texto, X),
    assertion(T == desconocido), assertion(X == 'cosa_rara(1)').

test(un_mensaje_lleva_su_texto_de_narrador) :-
    nueva_partida,
    orden(nivel(detallado), R),
    item_de_tipo(R, msg, I), campo(I, texto, T),
    assertion(contiene(T, 'detallado')).

test(un_error_de_accion_valida_ofrece_por_que_no) :-
    nueva_partida, estado:aplicar_efectos([viajar(camino_real)]),
    orden('aceptar(despensa_real)', R),
    item_de_tipo(R, error, I),
    campo(I, por_que_no, Q), campo(I, texto, T),
    assertion(Q == 'aceptar(despensa_real)'),
    assertion(atom(T)).

test(cada_error_de_accion_valida_apunta_a_su_accion) :-
    Casos = [ no_puede_viajar(aldea)-ir(aldea), no_puede_descansar-descansar, no_puede_pagar-pagar,
              no_puede_aceptar(gallina_noble)-aceptar(gallina_noble),
              no_puede_atacar(baldomero, bandido_torpe)-atacar(baldomero, bandido_torpe),
              no_puede_defender(tuerca)-defender ],
    forall(member(Motivo-Accion, Casos),
           (   api:error_de_accion(Motivo, A), assertion(A == Accion) )),
    forall(member(Otro, [no_entiendo(x), fuera_de_fase(a, b), sintaxis, falta_argumento(ir(_)), nada_que_pagar]),
           assertion(\+ api:error_de_accion(Otro, _))).

test(un_comando_desconocido_no_ofrece_por_que_no) :-
    nueva_partida,
    orden('volar(castillo)', R),
    item_de_tipo(R, error, I),
    campo(I, por_que_no, Q), campo(I, motivo, M),
    assertion(Q == @(null)), assertion(M == no_entiendo).

test(la_zona_lleva_id_nombre_y_salidas) :-
    nueva_partida,
    orden(mirar, R), item_de_tipo(R, zona, Z),
    campo(Z, id, Id), campo(Z, nombre, N), campo(Z, salidas, Ss),
    assertion(Id == taberna), assertion(N == 'Taberna del Cuajo Torcido'),
    findall(S, ( member(X, Ss), campo(X, id, S) ), Ids),
    assertion(msort(Ids, [aldea, camino_real])).

test(la_prueba_tiene_nodos_y_comentario_del_narrador) :-
    nueva_partida, estado:aplicar_efectos([viajar(camino_real)]),
    orden('demo(combate)', _),
    orden('explicar(atacar(baldomero, bandido_torpe))', R),
    item_de_tipo(R, prueba, P),
    nodos_de(P, Ns), campo(P, narrador, C),
    assertion(Ns = [t(0, ok, regla, _)|_]),
    assertion(memberchk(t(_, ok, calculo, '9 is max(1, 11-2+0)'), Ns)),
    assertion(atom(C)).

test(el_diagnostico_baja_hasta_la_negacion_que_lo_impide) :-
    orden('demo(combate)', _),
    orden('por_que_no(atacar(baldomero, bandido_montado))', R),
    item_de_tipo(R, diag, D),
    nodos_de(D, Ns), campo(D, porque, Porque),
    assertion(Ns = [t(0, no, regla, _)|_]),
    assertion(( member(t(_, no, negacion, T), Ns), contiene(T, 'teme(baldomero, caballo)') )),
    assertion(contiene(Porque, 'Porque teme(baldomero, caballo)')).

test(el_nivel_detallado_da_mas_nodos_que_el_resumido) :-
    orden('demo(gallina)', _),
    orden('por_que_no(aceptar(gallina_noble))', R1),
    orden('nivel(detallado)', _),
    orden('por_que_no(aceptar(gallina_noble))', R2),
    item_de_tipo(R1, diag, D1), item_de_tipo(R2, diag, D2),
    nodos_de(D1, N1), nodos_de(D2, N2),
    length(N1, L1), length(N2, L2),
    assertion(L2 > L1),
    campo(D2, nivel, Nivel), assertion(Nivel == detallado).

test(el_resumido_pliega_con_plegados) :-
    orden('demo(combate)', _),
    orden('explicar(atacar(baldomero, bandido_torpe))', R),
    item_de_tipo(R, prueba, P), campo(P, nodos, Ns),
    assertion(( member(N, Ns), campo(N, plegados, K), K > 0 )).

:- end_tests(los_items).

% ---------------------------------------------------------------------------
:- begin_tests(la_decision_del_enemigo).

test(las_tres_formas_de_regla_ganadora) :-
    api:regla_ganadora(regla(accion_enemigo(e(x, 1), atacar(a)), 3, []), json(A)),
    assertion(memberchk(tipo=corte, A)), assertion(memberchk(prioridad=3, A)),
    api:regla_ganadora(hecho(accion_enemigo(e(x, 1), defender)), json(B)),
    memberchk(total=Total, B),
    assertion(Total == 6),
    assertion(memberchk(tipo=comodin, B)), assertion(memberchk(prioridad=Total, B)),
    api:regla_ganadora(regla(golpea_a_clotilde(e(x, 1)), 1, []), json(C)),
    assertion(memberchk(tipo=escolta, C)), assertion(memberchk(prioridad= @(null), C)).

preparar :-
    orden('demo(ia)', _), orden(defender, _), orden(defender, _), orden(defender, _),
    orden(explicar, R), item_de_tipo(R, decision, D),
    nb_setval(decision, D).

test(la_regla_ganadora_con_corte) :-
    preparar, nb_getval(decision, D),
    campo(D, regla, Reg), campo(D, accion, A),
    campo(Reg, tipo, T), campo(Reg, prioridad, P), campo(Reg, total, Tot),
    assertion(T == corte), assertion(P == 5), assertion(Tot == 6),
    campo(A, texto, Txt), campo(A, termino, Term),
    assertion(Txt == 'Atacar a Tuerca'), assertion(Term == 'atacar(tuerca)').

test(las_cuatro_reglas_de_mayor_prioridad_con_su_motivo) :-
    preparar, nb_getval(decision, D),
    campo(D, descartes, Ds),
    findall(P-Ti, ( member(X, Ds), campo(X, prioridad, P), campo(X, titulo, Ti) ), Ps),
    assertion(Ps == [1-'Curarse', 2-'Invocar moho', 3-'Robar queso', 4-'Embestir']),
    forall(member(X, Ds),
           (   campo(X, motivo, M), assertion(M \== ''),
               campo(X, nodos, Ns), assertion(Ns \== [])
           )),
    Ds = [Primero|_], campo(Primero, motivo, M1),
    assertion(contiene(M1, '12*100=<12*30')).

test(el_enemigo_se_nombra_sin_articulo) :-
    preparar, nb_getval(decision, D),
    campo(D, enemigo, N), assertion(N == 'Bandido Torpe').

test(la_prueba_ganadora_lleva_el_corte) :-
    preparar, nb_getval(decision, D),
    nodos_de(D, Ns),
    assertion(memberchk(t(_, ok, corte, corte), Ns)).

:- end_tests(la_decision_del_enemigo).

% ---------------------------------------------------------------------------
:- begin_tests(ejecutar_orden).

test(se_comporta_como_la_consola_con_los_errores) :-
    nueva_partida,
    forall(member(O-Motivo,
                  [ 'volar(castillo)'-no_entiendo, 'ir(X)'-falta_argumento, 'ir(castillo)'-no_puede_viajar,
                    'descansar.'-ok, 'jugar.'-no_entiendo ]),
           (   orden(O, R), tipos_de(R, Ts),
               (   Motivo == ok
               ->  assertion(\+ memberchk(error, Ts))
               ;   item_de_tipo(R, error, E), campo(E, motivo, M),
                   assertion(M == Motivo)
               )
           )).

test(el_punto_final_es_opcional) :-
    nueva_partida,
    orden('mirar.', R1), orden(mirar, R2),
    tipos_de(R1, T1), tipos_de(R2, T2),
    assertion(T1 == T2).

test(una_orden_vacia_o_con_sintaxis_rota_no_tumba_nada) :-
    nueva_partida,
    forall(member(O, ['', '   ', '.', 'ir(', ')))', 'ir(aldea', 'a b c', 'ir(aldea).ir(bosque)']),
           (   orden(O, R), items_de(R, Is),
               assertion(Is \== []),
               assertion(( estado_de(R, E), E \== @(null) ))
           )).

test(la_respuesta_siempre_trae_el_estado) :-
    nueva_partida,
    orden(mirar, R), estado_de(R, E),
    forall(member(K, [fase, dia, nivel, zona, mapa, banda, despensa, contratos, combate, fin, acciones]),
           assertion(campo(E, K, _))).

test(demo_sin_argumentos_lista_las_cinco_escenas) :-
    nueva_partida,
    orden(demo, R), item_de_tipo(R, escenas, I), campo(I, escenas, Es),
    findall(N, ( member(X, Es), campo(X, nombre, N) ), Ns),
    assertion(Ns == [economia, combate, ia, gallina, venda]).

test(demo_de_una_escena_la_monta) :-
    nueva_partida,
    orden('demo(combate)', R), tipos_de(R, Ts),
    assertion(memberchk(escena, Ts)),
    estado_de(R, E), campo(E, fase, F), assertion(F == combate),
    campo(E, combate, C), assertion(C \== @(null)).

test(demo_con_escena_desconocida_es_un_error) :-
    nueva_partida,
    orden('demo(zzz)', R),
    item_de_tipo(R, error, I), campo(I, motivo, M),
    assertion(M == escena_desconocida).

test(nunca_falla_ni_lanza_con_terminos_de_todo_tipo) :-
    nueva_partida,
    forall(member(O, ['1', '"cadena"', '[a,b]', 'f(X,Y)', '- 3', 'a:b:c', '\'\'', '0\'a', 'ir(1)', 'atacar(e(a,1))',
                      'habilidad(zzz)', 'elegir(99)', 'aceptar(nada)', 'explicar(zzz)', 'por_que_no(zzz)',
                      'por_que_no(ir(castillo))', 'nivel(raro)']),
           (   catch(orden(O, R), Ex, ( format(user_error, "LANZO ~q con ~q~n", [Ex, O]), fail )),
               assertion(nonvar(R))
           )).

test(la_orden_se_devuelve_tal_cual_en_la_respuesta) :-
    nueva_partida,
    orden('inventario', R), campo(R, orden, O),
    assertion(O == inventario).

:- end_tests(ejecutar_orden).

% ---------------------------------------------------------------------------
:- begin_tests(el_estado).

test(la_banda_son_cuatro_con_vida_y_moral) :-
    nueva_partida, estado_json(E), campo(E, banda, B),
    findall(Id, ( member(M, B), campo(M, id, Id) ), Ids),
    assertion(Ids == [baldomero, pimentina, rufino, tuerca]),
    forall(member(M, B),
           (   campo(M, vida, V), campo(M, vida_max, VM), campo(M, moral, Mo), campo(M, estado, Es),
               assertion(integer(V)), assertion(V =< VM), assertion(integer(Mo)), assertion(Es == en_pie)
           )),
    B = [Bal|_], campo(Bal, rasgo_texto, RT), assertion(RT == 'Teme caballos').

test(la_despensa_suma_lo_mismo_por_categoria_que_en_total) :-
    nueva_partida, estado_json(E), campo(E, despensa, D),
    campo(D, total, T), campo(D, categorias, json(Cats)),
    findall(N, member(_=N, Cats), Ns), sumlist(Ns, S),
    assertion(S =:= T),
    assertion(memberchk(fresco=_, Cats)), assertion(memberchk(curado=_, Cats)), assertion(memberchk(rancio=_, Cats)).

test(la_despensa_con_quesos_de_tres_edades) :-
    orden('demo(economia)', R), estado_de(R, E), campo(E, despensa, D), campo(D, categorias, json(Cats)),
    assertion(memberchk(fresco=12, Cats)), assertion(memberchk(curado=2, Cats)), assertion(memberchk(rancio=1, Cats)).

test(el_mapa_son_las_seis_zonas_y_sus_conexiones_reales) :-
    nueva_partida, estado_json(E), campo(E, mapa, json(M)),
    memberchk(zonas=Zs, M), memberchk(conexiones=Cx, M),
    length(Zs, NZ), assertion(NZ == 6),
    findall(A-B, member([A, B], Cx), Pares),
    findall(A-B, mundo:conexion(A, B), Reales),
    assertion(Pares == Reales),
    assertion(\+ memberchk(camino_real-aldea, Pares)),
    assertion(\+ memberchk(aldea-camino_real, Pares)).

test(los_contratos_visibles_con_sus_estados) :-
    nueva_partida, estado_json(E), campo(E, contratos, Cs),
    findall(Id-Es, ( member(C, Cs), campo(C, id, Id), campo(C, estado, Es) ), Ps),
    assertion(Ps = [ratas_del_granero-_, gato_en_el_arbol-_, gallina_noble-bloqueado]),
    forall(member(C, Cs), ( campo(C, nombre, N), campo(C, recompensa, R), assertion(atom(N)), assertion(atom(R)) )).

test(en_exploracion_sin_combate_ni_final) :-
    nueva_partida, estado_json(E),
    campo(E, fase, F), campo(E, combate, C), campo(E, fin, Fin),
    assertion(F == taberna), assertion(C == @(null)), assertion(Fin == @(null)).

test(en_combate_el_turno_y_los_enemigos) :-
    orden('demo(combate)', R), estado_de(R, E),
    campo(E, combate, C), campo(C, turno, T), campo(T, id, Id), campo(C, enemigos, Es),
    assertion(Id == baldomero),
    length(Es, N), assertion(N == 2),
    findall(Ti, ( member(X, Es), campo(X, tipo_enemigo, Ti) ), Tipos),
    assertion(msort(Tipos, [bandido_montado, bandido_torpe])),
    forall(member(X, Es), ( campo(X, vida, V), campo(X, vida_max, M), campo(X, fila, Fi), assertion(V =< M), assertion(memberchk(Fi, [frente, retaguardia])) )).

test(el_final_se_ve_en_el_estado) :-
    nueva_partida, estado:aplicar_efectos([fin(derrota(prueba))]),
    estado_json(E), campo(E, fase, F), campo(E, fin, Fin),
    assertion(F == fin), assertion(Fin \== @(null)).

test(pedir_el_estado_no_cambia_la_partida) :-
    orden('demo(combate)', _),
    foto(A), estado_json(_), acciones_json(_), foto(B),
    assertion(A =@= B).

test(el_estado_es_json_escribible_sin_listas_de_codigos) :-
    forall(member(Escena, [economia, combate, ia, gallina]),
           (   orden('demo'(Escena), _),
               estado_json(E), json_texto(E, T),
               assertion(\+ contiene(T, '"nombre":"e(')), assertion(\+ contiene(T, '"texto":"e(')),
               atom_length(T, L), assertion(L > 500)
           )).

:- end_tests(el_estado).

% ---------------------------------------------------------------------------
:- begin_tests(las_acciones).

acciones(Cmds) :-
    estado_json(E), campo(E, acciones, As),
    findall(C-(H-M), ( member(A, As), campo(A, comando, C), campo(A, habilitada, H), campo(A, motivo, M) ), Cmds).

test(en_la_taberna_con_queso_se_puede_descansar) :-
    nueva_partida,
    acciones(As),
    assertion(memberchk(descansar-(@(true)-_), As)),
    assertion(memberchk(mirar-(@(true)-_), As)).

test(solo_se_ofrece_ir_a_las_zonas_vecinas) :-
    nueva_partida,
    acciones(As),
    findall(C, ( member(C-_, As), C = 'ir(aldea)' ; member(C-_, As), C = 'ir(camino_real)' ), Vecinas),
    assertion(msort(Vecinas, ['ir(aldea)', 'ir(camino_real)'])),
    assertion(\+ memberchk('ir(castillo)'-_, As)).

test(fuera_de_la_taberna_descansar_esta_desactivado_y_dice_por_que) :-
    nueva_partida, estado:aplicar_efectos([viajar(camino_real)]),
    acciones(As),
    memberchk(descansar-(H-M), As),
    assertion(H == @(false)),
    assertion(M \== @(null)),
    estado_json(E), campo(E, acciones, Acs),
    member(A, Acs), campo(A, comando, descansar), campo(A, por_que_no, Q),
    assertion(Q == descansar), !.

test(una_accion_habilitada_no_tiene_motivo_ni_por_que_no) :-
    nueva_partida, estado_json(E), campo(E, acciones, As),
    forall(( member(A, As), campo(A, habilitada, @(true)) ),
           ( campo(A, motivo, M), campo(A, por_que_no, Q), assertion(M == @(null)), assertion(Q == @(null)) )).

test(una_accion_desactivada_siempre_dice_el_motivo) :-
    forall(member(Escena, [economia, combate, ia, gallina]),
           (   orden('demo'(Escena), _),
               estado_json(E), campo(E, acciones, As),
               forall(( member(A, As), campo(A, habilitada, @(false)) ),
                      ( campo(A, motivo, M), assertion(atom(M)), assertion(M \== '') ))
           )).

test(en_combate_baldomero_no_puede_atacar_al_montado_y_si_al_torpe) :-
    orden('demo(combate)', _),
    acciones(As),
    assertion(memberchk('atacar(bandido_torpe)'-(@(true)-_), As)),
    assertion(memberchk('atacar(bandido_montado)'-(@(false)-_), As)),
    assertion(memberchk(defender-(@(true)-_), As)),
    assertion(\+ memberchk('ir(aldea)'-_, As)).

test(en_combate_la_habilidad_se_ofrece_contra_cada_enemigo) :-
    orden('demo(combate)', _),
    acciones(As),
    findall(C, ( member(C-_, As), sub_atom(C, 0, _, _, 'habilidad') ), Hs),
    assertion(Hs \== []).

test(en_el_final_no_se_ofrece_nada) :-
    nueva_partida, estado:aplicar_efectos([fin(victoria)]),
    acciones_json(As), assertion(As == []).

test(las_acciones_ofrecidas_son_comandos_validos_de_verdad) :-
    forall(member(Escena, [economia, combate, ia, gallina]),
           (   orden('demo'(Escena), _),
               estado_json(E), campo(E, acciones, As),
               forall(( member(A, As), campo(A, comando, C) ),
                      (   texto_de_orden(C, T),
                          juego:validar_comando(T, V),
                          assertion(V = ok(_))
                      ))
           )).

:- end_tests(las_acciones).

% ---------------------------------------------------------------------------
% La campana entera por la API
% ---------------------------------------------------------------------------
:- begin_tests(la_campana_por_la_api).

test(la_partida_de_respaldo_se_juega_entera_sin_items_desconocidos_ni_errores) :-
    nueva_partida,
    main:leer_guion('examples/campana-comandos.txt', Terminos),
    findall(Tipos,
            (   member(T, Terminos),
                format(atom(Texto), '~q', [T]),
                orden(Texto, R),
                tipos_de(R, Tipos),
                estado_de(R, E), assertion(E \== @(null))
            ),
            Todos),
    append(Todos, Planos),
    assertion(\+ memberchk(desconocido, Planos)),
    assertion(\+ memberchk(error, Planos)),
    assertion(memberchk(combate, Planos)), assertion(memberchk(evento, Planos)),
    assertion(( memberchk(decision, Planos) ; memberchk(prueba, Planos) )),
    orden(mirar, Final), estado_de(Final, Est),
    campo(Est, fase, F), campo(Est, fin, Fin),
    assertion(F == fin), assertion(Fin \== @(null)),
    campo(Est, acciones, As), assertion(As == []).

:- end_tests(la_campana_por_la_api).

% ---------------------------------------------------------------------------
% Lo que cuenta la web es lo que cuenta la consola
% ---------------------------------------------------------------------------
:- begin_tests(web_y_consola).

test(cada_nodo_de_un_por_que_no_aparece_en_la_pantalla_de_la_consola) :-
    nueva_partida, estado:aplicar_efectos([viajar(camino_real)]),
    Orden = 'por_que_no(aceptar(gallina_noble))',
    orden(Orden, R), item_de_tipo(R, diag, D), nodos_de(D, Ns),
    nueva_partida, estado:aplicar_efectos([viajar(camino_real)]),
    consola(por_que_no(aceptar(gallina_noble)), Pantalla),
    forall(member(t(_, _, _, Texto), Ns),
           assertion(contiene(Pantalla, Texto))).

test(cada_nodo_de_un_explicar_aparece_en_la_pantalla_de_la_consola) :-
    orden('demo(combate)', _),
    orden('explicar(atacar(baldomero, bandido_torpe))', R), item_de_tipo(R, prueba, P), nodos_de(P, Ns),
    orden('demo(combate)', _),
    consola(explicar(atacar(baldomero, bandido_torpe)), Pantalla),
    forall(member(t(_, _, _, Texto), Ns), assertion(contiene(Pantalla, Texto))),
    campo(P, narrador, C), assertion(contiene(Pantalla, C)).

test(el_texto_de_un_mensaje_es_el_que_imprime_la_consola) :-
    nueva_partida,
    orden(descansar, R), items_de(R, Is),
    nueva_partida,
    consola(descansar, Pantalla),
    forall(( member(I, Is), campo(I, tipo, msg), campo(I, texto, T) ),
           assertion(contiene(Pantalla, T))).

test(la_decision_del_enemigo_coincide_con_la_consola) :-
    orden('demo(ia)', _), orden(defender, _), orden(defender, _), orden(defender, _),
    orden(explicar, R), item_de_tipo(R, decision, D),
    campo(D, descartes, Ds),
    orden('demo(ia)', _), orden(defender, _), orden(defender, _), orden(defender, _),
    consola(explicar, Pantalla),
    forall(member(X, Ds), ( campo(X, motivo, M), assertion(contiene(Pantalla, M)) )),
    campo(D, regla, Reg), campo(Reg, prioridad, P),
    format(atom(Frase), 'prioridad ~w de 6', [P]),
    assertion(contiene(Pantalla, Frase)).

:- end_tests(web_y_consola).

% ---------------------------------------------------------------------------
% El servidor HTTP, de verdad
% ---------------------------------------------------------------------------
puerto(18765).

url(Ruta, Url) :- puerto(P), atomic_list_concat(['http://localhost:', P, Ruta], Url).

obtener(Ruta, Json) :-
    url(Ruta, Url),
    setup_call_cleanup(http_open(Url, S, [status_code(_)]),
                       ( set_stream(S, encoding(utf8)), json_read(S, Json) ),
                       close(S)).

estado_http(Ruta, Codigo) :-
    url(Ruta, Url),
    setup_call_cleanup(http_open(Url, S, [status_code(Codigo), header(content_type, _)]),
                       read_stream_to_codes(S, _),
                       close(S)).

enviar(Ruta, Cuerpo, Json) :-
    url(Ruta, Url),
    atom_codes(Cuerpo, Codigos),
    setup_call_cleanup(http_open(Url, S, [post(codes('application/json', Codigos)), status_code(_)]),
                       ( set_stream(S, encoding(utf8)), json_read(S, Json) ),
                       close(S)).

:- dynamic dentro/1, solapes/1.

% entrar_y_salir(+N): dentro del cerrojo no puede haber nadie mas; si hay solape se anota.
entrar_y_salir(N) :-
    thread_get_message(adelante),
    servidor:con_cerrojo(dentro_del_cerrojo(N)).

dentro_del_cerrojo(N) :-
    assertz(dentro(N)),
    sleep(0.15),
    findall(X, dentro(X), Xs), length(Xs, K),
    (   K > 1 -> retract(solapes(S0)), S is S0 + 1, assertz(solapes(S)) ; true ),
    retract(dentro(N)).

% lo que hace cada hilo de la prueba de concurrencia: cinco peticiones seguidas
trabajo_http :-
    forall(between(1, 5, _),
           (   obtener('/api/orden?orden=mirar', J),
               campo(J, orden, mirar),
               item_de_tipo(J, zona, _)
           )).

:- begin_tests(la_web).

% la_web: el contenido de web/ es coherente (sin servidor)
leer_texto(Ruta, Texto) :-
    setup_call_cleanup(open(Ruta, read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs) ),
                       close(S)),
    atom_codes(Texto, Cs).

test(el_html_solo_referencia_archivos_que_existen) :-
    leer_texto('web/index.html', H),
    forall(member(Ref, ['estilos.css', 'app.css', 'app.js', 'favicon.svg']),
           (   assertion(contiene(H, Ref)),
               atomic_list_concat(['web/', Ref], R), assertion(exists_file(R))
           )).

test(el_html_declara_idioma_utf8_y_viewport) :-
    leer_texto('web/index.html', H),
    assertion(contiene(H, 'lang="es"')), assertion(contiene(H, 'charset="UTF-8"')),
    assertion(contiene(H, 'name="viewport"')).

test(el_javascript_pide_solo_las_rutas_de_la_api_que_existen) :-
    leer_texto('web/app.js', J),
    forall(member(Ruta, ['/api/orden', '/api/nueva', '/api/estado']), assertion(contiene(J, Ruta))),
    assertion(\+ contiene(J, 'fetch("http')).      % nada de servidores externos

test(la_web_no_carga_nada_de_fuera) :-
    forall(member(F, ['web/index.html', 'web/app.js', 'web/estilos.css', 'web/app.css']),
           (   leer_texto(F, T),
               assertion(\+ contiene(T, 'https://')), assertion(\+ contiene(T, '//cdn')),
               assertion(\+ contiene(T, 'googleapis'))
           )).

test(el_diseno_define_los_dos_temas_con_los_mismos_tokens) :-
    leer_texto('web/estilos.css', C),
    forall(member(Tok, ['--paper:', '--ink:', '--cheddar:', '--ok:', '--no:', '.game-frame.dark']), assertion(contiene(C, Tok))).

test(el_javascript_tiene_los_paneles_del_diseno) :-
    leer_texto('web/app.js', J),
    forall(member(Pieza, ['panelContratos', 'panelZona', 'panelExplicar', 'decisionHTML', 'arbolHTML', 'juegoMovil',
                          'pantallaInicio', 'pantallaFinal', 'accionesRapidas']),
           assertion(contiene(J, Pieza))).

test(el_panel_inferior_alterna_despensa_y_posiciones) :-
    leer_texto('web/app.js', J),
    forall(member(Pieza, ['panelInferior', 'formacionHTML', 'fichaHeroe', 'fichaEnemigo', 'inf:despensa', 'inf:posiciones', 'Posiciones']),
           assertion(contiene(J, Pieza))).

test(la_banda_y_los_enemigos_traen_la_fila_que_pinta_la_formacion) :-
    nueva_partida, estado_json(E0),
    campo(E0, banda, B),
    forall(member(M, B), ( campo(M, fila, F), assertion(memberchk(F, [frente, retaguardia])) )),
    orden('demo(combate)', R), estado_de(R, E1),
    campo(E1, combate, C), campo(C, enemigos, Es),
    forall(member(X, Es), ( campo(X, fila, Fx), assertion(memberchk(Fx, [frente, retaguardia])),
                            campo(X, id, Id), assertion(contiene(Id, 'e(')) )),
    campo(C, turno, T), campo(T, id, Turno), assertion(memberchk(Turno, [baldomero, pimentina, rufino, tuerca])).

:- end_tests(la_web).

:- begin_tests(el_servidor, [setup(arrancar), cleanup(parar_servidor)]).

arrancar :-
    puerto(P),
    estado:nueva_partida,
    http_server(http_dispatch, [port(P), workers(2)]).

parar_servidor :- puerto(P), servidor:parar(P).

test(el_estado_por_http) :-
    obtener('/api/estado', J),
    campo(J, fase, F), campo(J, banda, B),
    assertion(F == taberna), length(B, N), assertion(N == 4).

test(una_orden_por_get) :-
    obtener('/api/orden?orden=mirar', J),
    campo(J, orden, O), item_de_tipo(J, zona, Z), campo(Z, id, Id),
    assertion(O == mirar), assertion(Id == taberna).

test(una_orden_por_post_en_json) :-
    enviar('/api/orden', '{"orden": "ir(aldea)."}', J),
    estado_de(J, E), campo(E, zona, Z), campo(Z, id, Id),
    assertion(Id == aldea),
    obtener('/api/estado', J2), campo(J2, zona, Z2), campo(Z2, id, Id2),
    assertion(Id2 == aldea).

test(los_acentos_llegan_bien_en_utf8) :-
    obtener('/api/orden?orden=compania', J),
    item_de_tipo(J, compania, C), campo(C, miembros, [M|_]), campo(M, rol, R),
    assertion(R == caballero),
    obtener('/api/orden?orden=contratos', J2),
    item_de_tipo(J2, contratos, Cs), campo(Cs, contratos, L),
    member(X, L), campo(X, id, gato_en_el_arbol), campo(X, nombre, N),
    assertion(N == 'El Gato en el Árbol'), !.

test(la_respuesta_declara_utf8) :-
    url('/api/estado', Url),
    setup_call_cleanup(http_open(Url, S, [header(content_type, Tipo)]),
                       read_stream_to_codes(S, _),
                       close(S)),
    assertion(contiene(Tipo, 'application/json')),
    assertion(contiene(Tipo, 'UTF-8')).

test(una_orden_vacia_por_http_no_da_500) :-
    obtener('/api/orden', J),
    items_de(J, Is), assertion(Is \== []).

test(nueva_partida_reinicia) :-
    enviar('/api/nueva', '{}', J),
    item_de_tipo(J, zona, Z), campo(Z, id, Id),
    assertion(Id == taberna),
    obtener('/api/estado', J2), campo(J2, dia, D), assertion(D == 1).

test(un_post_y_otra_peticion_por_la_misma_conexion_no_dan_500) :-
    % regresion: /api/nueva no leia su cuerpo y esos bytes rompian la peticion siguiente de la MISMA conexion
    % (el navegador reutiliza conexiones). http_open abre una por peticion, asi que se habla por un socket.
    puerto(P),
    atom_codes(CRLF, [13, 10]),
    atomic_list_concat(['POST /api/nueva HTTP/1.1', 'Host: localhost', 'Content-Type: application/json',
                        'Content-Length: 2', '', '{}GET /api/estado HTTP/1.1', 'Host: localhost',
                        'Connection: close', '', ''], CRLF, Pet),
    tcp_socket(Socket),
    tcp_connect(Socket, localhost:P),
    tcp_open_socket(Socket, In, Out),
    format(Out, '~w', [Pet]), flush_output(Out),
    read_stream_to_codes(In, Cs), atom_codes(Resp, Cs),
    close(Out), close(In),
    atomic_list_concat(Partes, 'HTTP/1.1 200', Resp), length(Partes, N),
    assertion(N == 3),                                   % dos respuestas 200
    assertion(\+ contiene(Resp, '500 Internal')).

test(las_escenas_por_http) :-
    obtener('/api/escenas', J), campo(J, escenas, Es),
    length(Es, N), assertion(N == 5).

test(un_archivo_estatico_se_sirve) :-
    estado_http('/index.html', C1), estado_http('/', C2),
    assertion(C1 == 200), assertion(C2 == 200).

test(los_archivos_de_la_web_se_sirven_con_su_tipo) :-
    forall(member(A-Tipo, [ '/app.js'-'javascript', '/estilos.css'-'css', '/app.css'-'css', '/favicon.svg'-'svg', '/index.html'-'html' ]),
           (   url(A, Url),
               setup_call_cleanup(http_open(Url, S, [status_code(C), header(content_type, T)]),
                                  read_stream_to_codes(S, Cs), close(S)),
               assertion(C == 200), assertion(contiene(T, Tipo)),
               assertion(Cs \== [])
           )).

test(un_archivo_que_no_existe_da_404) :-
    estado_http('/no_existe.html', C), assertion(C == 404).

test(no_se_sale_de_web) :-
    estado_http('/..%2fsrc%2fapi.pl', C1), estado_http('/%2e%2e/src/api.pl', C2),
    assertion(C1 == 404), assertion(C2 == 404).

test(el_cerrojo_serializa_las_peticiones) :-
    retractall(dentro(_)), retractall(solapes(_)), assertz(solapes(0)),
    findall(Id, ( between(1, 4, N), thread_create(entrar_y_salir(N), Id, []) ), Ids),
    forall(member(Id, Ids), thread_send_message(Id, adelante)),     % todos a la vez, no uno tras otro
    forall(member(Id, Ids), ( thread_join(Id, Estado), assertion(Estado == true) )),
    solapes(S),
    assertion(S == 0).

test(varias_peticiones_a_la_vez_dan_respuestas_validas) :-
    findall(Id, ( between(1, 4, _), thread_create(trabajo_http, Id, []) ), Ids),
    forall(member(Id, Ids),
           ( thread_join(Id, Estado), assertion(Estado == true) )).

:- end_tests(el_servidor).
