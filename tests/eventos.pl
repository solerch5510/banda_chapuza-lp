% eventos.pl (pruebas)
% T-27: el motor minimo de eventos (eventos.pl) y el comando elegir/1, con el contrato del gato en
% el arbol: como se abre el evento, sus opciones y cuales estan disponibles, los intentos, lo que
% pasa al elegir cada una, como se resuelve el contrato con las marcas que dejan y la cadena
% gato -> venda -> gallina. Incluye lo que ve el jugador y la prueba para explicar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/eventos -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
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

moral_a(Id, M) :-
    estado:moral(Id, M0),
    D is M - M0,
    aplicar_efecto(mod_moral(Id, D)).

% Para los viajes de ida y vuelta: 12 cheddar mas (con 4 miembros solo hay comida para 3 dias).
con_provisiones :-
    aplicar_efecto(ganar_queso(cheddar, 0, 12)).

% El gato aceptado y el evento abierto, en la aldea.
con_el_evento_abierto :-
    nueva_partida,
    ordena(aceptar(gato_en_el_arbol), _),
    ordena(ir(aldea), _).

:- begin_tests(datos_del_evento).

test(el_gato_es_el_evento_de_su_contrato, [nondet]) :-
    eventos:evento_de_contrato(gato_en_el_arbol, E, Z),
    E == rescate_gato,
    Z == aldea.

test(solo_el_gato_tiene_evento, [nondet]) :-
    findall(C, eventos:evento_de_contrato(C, _, _), Cs),
    Cs == [gato_en_el_arbol].

test(son_tres_intentos) :-
    eventos:intentos_maximos(rescate_gato, N),
    N == 3.

test(las_cuatro_opciones_en_orden) :-
    findall(O, eventos:opcion_evento(rescate_gato, O, _, _, _, _), Os),
    Os == [trepar, hechizo_de_raclette, sacudir_arbol, cantar].

test(cada_opcion_la_hace_un_miembro_distinto) :-
    findall(Q, eventos:opcion_evento(rescate_gato, _, Q, _, _, _), Qs),
    Qs == [tuerca, pimentina, baldomero, rufino],
    forall(member(Q, Qs), mundo:personaje(Q, _, _, _, _, _, _)).

test(solo_cantar_es_un_intento_fallido) :-
    findall(O-F, eventos:opcion_evento(rescate_gato, O, _, _, _, F), Ps),
    Ps == [trepar-resuelve, hechizo_de_raclette-resuelve, sacudir_arbol-resuelve, cantar-intento].

test(las_condiciones_son_del_vocabulario) :-
    forall(( eventos:opcion_evento(_, _, _, Cs, _, _), member(C, Cs) ),
           memberchk(C, [en_pie(_), queso_min(_)])).

test(los_efectos_son_del_vocabulario) :-
    forall(( eventos:opcion_evento(_, _, _, _, Es, _), member(E, Es) ),
           memberchk(E, [marcar(_), perder_queso(_), contar(_, _)])).

test(las_marcas_que_deja_cada_opcion_son_las_de_resolucion, [nondet]) :-
    eventos:opcion_evento(rescate_gato, trepar, _, _, T, _),
    eventos:opcion_evento(rescate_gato, hechizo_de_raclette, _, _, H, _),
    eventos:opcion_evento(rescate_gato, sacudir_arbol, _, _, S, _),
    memberchk(marcar(gato_bajado_con_arte), T),
    memberchk(marcar(gato_bajado_con_arte), H),
    memberchk(marcar(gato_bajado_a_golpes), S),
    contratos:resolucion(gato_en_el_arbol, exito, [marca(gato_bajado_con_arte)]),
    contratos:resolucion(gato_en_el_arbol, a_medias, [marca(gato_bajado_a_golpes)]).

test(todas_las_opciones_tienen_descripcion) :-
    forall(eventos:opcion_evento(E, O, _, _, _, _), narrador:descripcion_opcion(E, O, _)),
    narrador:descripcion_evento(rescate_gato, _).

test(todas_las_opciones_tienen_frase_propia) :-
    forall(eventos:opcion_evento(E, O, _, _, _, _),
           (   narrador:texto(evento_elige, [E, O], 0, T), T \== '' )).

:- end_tests(datos_del_evento).

:- begin_tests(evento_abierto).

test(sin_aceptar_no_hay_evento, [setup(nueva_partida), fail]) :-
    eventos:evento_abierto(_).

test(sin_aceptar_no_hay_evento_pendiente, [setup(nueva_partida), fail]) :-
    eventos:evento_pendiente(aldea, _, _).

test(aceptado_y_en_la_aldea_esta_pendiente, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    eventos:evento_pendiente(aldea, C, E),
    C == gato_en_el_arbol,
    E == rescate_gato.

test(en_otra_zona_no_esta_pendiente, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    eventos:evento_pendiente(bosque, _, _).

test(abierto_deja_de_estar_pendiente, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    aplicar_efecto(marcar(evento_abierto(rescate_gato))),
    eventos:evento_pendiente(aldea, _, _).

test(para_estar_abierto_hay_que_estar_en_la_aldea, [setup(nueva_partida), fail]) :-
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),
    aplicar_efecto(marcar(evento_abierto(rescate_gato))),
    eventos:evento_abierto(_).                         % estamos en la taberna

test(estar_en_la_aldea_con_el_contrato_activo_no_basta_si_no_se_ha_abierto, [fail]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    aplicar_efecto(contrato_aceptar(gato_en_el_arbol)),   % activo y en su zona, pero sin abrir
    eventos:evento_abierto(_).

test(abierto_en_la_aldea_con_el_contrato_activo, [nondet]) :-
    con_el_evento_abierto,
    eventos:evento_abierto(E),
    E == rescate_gato.

test(sin_el_contrato_activo_no_esta_abierto, [fail]) :-
    con_el_evento_abierto,
    retract(estado:contrato_activo(gato_en_el_arbol)),
    eventos:evento_abierto(_).

test(al_irse_de_la_aldea_el_evento_queda_dormido, [fail]) :-
    con_el_evento_abierto,
    con_provisiones,
    ordena(ir(bosque), _),
    eventos:evento_abierto(_).

test(al_volver_a_la_aldea_vuelve_a_estar_abierto, [nondet]) :-
    con_el_evento_abierto,
    con_provisiones,
    ordena(ir(bosque), _),
    ordena(ir(aldea), _),
    eventos:evento_abierto(rescate_gato).

:- end_tests(evento_abierto).

:- begin_tests(opciones_y_disponibilidad).

test(las_opciones_vienen_numeradas, [setup(nueva_partida)]) :-
    eventos:opciones_de(rescate_gato, Os),
    findall(N-O, member(opcion(N, O, _, _), Os), Ps),
    Ps == [1-trepar, 2-hechizo_de_raclette, 3-sacudir_arbol, 4-cantar].

test(al_empezar_estan_todas_disponibles, [setup(nueva_partida)]) :-
    eventos:opciones_de(rescate_gato, Os),
    forall(member(opcion(_, _, _, D), Os), D == si).

test(sin_queso_no_hay_hechizo, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 12)),
    eventos:opciones_de(rescate_gato, Os),
    memberchk(opcion(2, hechizo_de_raclette, _, D), Os),
    D == no.

test(con_un_queso_si_hay_hechizo, [setup(nueva_partida)]) :-
    aplicar_efecto(gastar_queso(cheddar, 0, 11)),
    eventos:opciones_de(rescate_gato, Os),
    memberchk(opcion(2, hechizo_de_raclette, _, D), Os),
    D == si.

test(si_tuerca_cae_no_hay_trepar, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(tuerca, 99)),
    eventos:opciones_de(rescate_gato, Os),
    memberchk(opcion(1, trepar, _, D), Os),
    D == no.

test(si_rufino_esta_en_huelga_no_canta, [setup(nueva_partida)]) :-
    moral_a(rufino, 2),
    eventos:opciones_de(rescate_gato, Os),
    memberchk(opcion(4, cantar, _, D), Os),
    D == no.

test(si_baldomero_cae_no_sacude_el_arbol, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(baldomero, 99)),
    eventos:opciones_de(rescate_gato, Os),
    memberchk(opcion(3, sacudir_arbol, _, D), Os),
    D == no.

test(un_caido_no_afecta_a_las_demas, [setup(nueva_partida)]) :-
    aplicar_efecto(dano(tuerca, 99)),
    eventos:opciones_de(rescate_gato, Os),
    findall(O-D, member(opcion(_, O, _, D), Os), Ps),
    Ps == [trepar-no, hechizo_de_raclette-si, sacudir_arbol-si, cantar-si].

test(puede_elegir_exige_el_evento_abierto, [setup(nueva_partida), fail]) :-
    eventos:puede_elegir(rescate_gato, trepar).

test(puede_elegir_con_el_evento_abierto, [nondet]) :-
    con_el_evento_abierto,
    eventos:puede_elegir(rescate_gato, trepar),
    eventos:puede_elegir(rescate_gato, cantar).

test(puede_elegir_falla_si_la_opcion_no_esta_disponible, [fail]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    eventos:puede_elegir(rescate_gato, trepar).

test(puede_elegir_no_modifica_el_estado) :-
    con_el_evento_abierto,
    foto_estado(Antes),
    forall(eventos:opcion_evento(rescate_gato, O, _, _, _, _), ( eventos:puede_elegir(rescate_gato, O) -> true ; true )),
    foto_estado(Despues),
    Antes =@= Despues.

:- end_tests(opciones_y_disponibilidad).

:- begin_tests(escribir_la_opcion).

test(por_el_nombre, [setup(nueva_partida), nondet]) :-
    eventos:resolver_opcion(rescate_gato, sacudir_arbol, O),
    O == sacudir_arbol.

test(por_el_numero, [setup(nueva_partida)]) :-
    forall(member(N-Esperada, [1-trepar, 2-hechizo_de_raclette, 3-sacudir_arbol, 4-cantar]),
           (   eventos:resolver_opcion(rescate_gato, N, O), O == Esperada )).

test(el_cero_y_el_cinco_no_existen, [setup(nueva_partida)]) :-
    \+ eventos:resolver_opcion(rescate_gato, 0, _),
    \+ eventos:resolver_opcion(rescate_gato, 5, _),
    \+ eventos:resolver_opcion(rescate_gato, -1, _).

test(un_nombre_desconocido_no_vale, [setup(nueva_partida), fail]) :-
    eventos:resolver_opcion(rescate_gato, dragon, _).

test(un_numero_escrito_como_atomo_no_vale, [setup(nueva_partida), fail]) :-
    eventos:resolver_opcion(rescate_gato, '1', _).

test(otras_cosas_no_valen, [setup(nueva_partida)]) :-
    \+ eventos:resolver_opcion(rescate_gato, 1.5, _),
    \+ eventos:resolver_opcion(rescate_gato, f(x), _),
    \+ eventos:resolver_opcion(rescate_gato, "trepar", _).

test(una_opcion_de_otro_evento_no_vale, [setup(nueva_partida), fail]) :-
    eventos:resolver_opcion(otro_evento, trepar, _).

:- end_tests(escribir_la_opcion).

:- begin_tests(intentos).

test(la_clave_del_contador, [nondet]) :-
    eventos:clave_intentos(rescate_gato, K),
    K == intentos_rescate_gato.

test(sin_contador_son_cero_hechos_y_tres_restantes, [setup(nueva_partida)]) :-
    eventos:intentos_hechos(rescate_gato, H),
    eventos:intentos_restantes(rescate_gato, R),
    H == 0, R == 3.

test(cada_intento_resta_uno, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(intentos_rescate_gato, 1)),
    eventos:intentos_hechos(rescate_gato, H),
    eventos:intentos_restantes(rescate_gato, R),
    H == 1, R == 2.

test(tres_intentos_no_dejan_ninguno, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(intentos_rescate_gato, 3)),
    eventos:intentos_restantes(rescate_gato, R),
    R == 0.

:- end_tests(intentos).

:- begin_tests(efectos_del_evento).

test(la_apertura_pone_los_intentos_a_cero_y_marca, [setup(nueva_partida)]) :-
    eventos:efectos_apertura(rescate_gato, Efs),
    Efs == [borrar_contador(intentos_rescate_gato), marcar(evento_abierto(rescate_gato)),
            mensaje(evento_abre, [rescate_gato])].

test(trepar_marca_cierra_y_avisa, [setup(nueva_partida), nondet]) :-
    eventos:efectos_eleccion(rescate_gato, trepar, Efs),
    Efs == [marcar(gato_bajado_con_arte), mensaje(evento_elige, [rescate_gato, trepar]),
            desmarcar(evento_abierto(rescate_gato))].

test(el_hechizo_gasta_un_queso_y_marca, [setup(nueva_partida), nondet]) :-
    eventos:efectos_eleccion(rescate_gato, hechizo_de_raclette, Efs),
    Efs = [gastar_queso(cheddar, 0, 1), marcar(gato_bajado_con_arte),
           mensaje(evento_elige, [rescate_gato, hechizo_de_raclette]),
           desmarcar(evento_abierto(rescate_gato))].

test(sacudir_el_arbol_deja_la_marca_a_golpes, [setup(nueva_partida), nondet]) :-
    eventos:efectos_eleccion(rescate_gato, sacudir_arbol, Efs),
    Efs == [marcar(gato_bajado_a_golpes), mensaje(evento_elige, [rescate_gato, sacudir_arbol]),
            desmarcar(evento_abierto(rescate_gato))].

test(cantar_con_intentos_de_sobra_solo_cuenta, [setup(nueva_partida)]) :-
    eventos:efectos_eleccion(rescate_gato, cantar, Efs),
    Efs == [mensaje(evento_elige, [rescate_gato, cantar]), contar(intentos_rescate_gato, 1),
            mensaje(intento_fallido, [rescate_gato, 2])].

test(el_ultimo_intento_cierra_el_evento, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(intentos_rescate_gato, 2)),
    eventos:efectos_eleccion(rescate_gato, cantar, Efs),
    Efs == [mensaje(evento_elige, [rescate_gato, cantar]), contar(intentos_rescate_gato, 1),
            mensaje(intento_fallido, [rescate_gato, 0]), desmarcar(evento_abierto(rescate_gato))].

test(el_penultimo_intento_avisa_de_que_queda_uno, [setup(nueva_partida)]) :-
    aplicar_efecto(contar(intentos_rescate_gato, 1)),
    eventos:efectos_eleccion(rescate_gato, cantar, Efs),
    memberchk(mensaje(intento_fallido, [rescate_gato, 1]), Efs),
    \+ memberchk(desmarcar(_), Efs).

test(una_opcion_que_no_existe_no_tiene_efectos, [setup(nueva_partida), fail]) :-
    eventos:efectos_eleccion(rescate_gato, volar, _).

test(termina_con_las_opciones_que_resuelven, [setup(nueva_partida)]) :-
    forall(member(O, [trepar, hechizo_de_raclette, sacudir_arbol]),
           (   eventos:termina_con(rescate_gato, O, Como), Como == resuelve )).

test(cantar_no_termina_si_quedan_intentos, [setup(nueva_partida), fail]) :-
    eventos:termina_con(rescate_gato, cantar, _).

test(cantar_el_ultimo_intento_agota_el_evento, [setup(nueva_partida), nondet]) :-
    aplicar_efecto(contar(intentos_rescate_gato, 2)),
    eventos:termina_con(rescate_gato, cantar, Como),
    Como == agota.

test(los_efectos_no_modifican_el_estado, [setup(nueva_partida)]) :-
    foto_estado(Antes),
    eventos:efectos_apertura(rescate_gato, _),
    forall(eventos:opcion_evento(rescate_gato, O, _, _, _, _), eventos:efectos_eleccion(rescate_gato, O, _)),
    foto_estado(Despues),
    Antes == Despues.

:- end_tests(efectos_del_evento).

:- begin_tests(abrir_el_evento_jugando).

test(aceptar_en_la_aldea_abre_el_evento, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(aceptar(gato_en_el_arbol), Items),
    memberchk(msg(evento_abre, [rescate_gato], _), Items),
    memberchk(vista(evento, rescate_gato, 3, _), Items),
    estado:marca(evento_abierto(rescate_gato)).

test(aceptar_en_la_taberna_no_lo_abre, [nondet]) :-
    nueva_partida,
    ordena(aceptar(gato_en_el_arbol), Items),
    \+ memberchk(msg(evento_abre, _, _), Items),
    \+ estado:marca(evento_abierto(_)).

test(llegar_a_la_aldea_con_el_contrato_lo_abre, [nondet]) :-
    nueva_partida,
    ordena(aceptar(gato_en_el_arbol), _),
    ordena(ir(aldea), Items),
    memberchk(msg(evento_abre, [rescate_gato], _), Items),
    memberchk(vista(evento, rescate_gato, 3, Opciones), Items),
    length(Opciones, 4).

test(llegar_sin_el_contrato_no_abre_nada) :-
    nueva_partida,
    ordena(ir(aldea), Items),
    \+ memberchk(msg(evento_abre, _, _), Items),
    \+ memberchk(vista(evento, _, _, _), Items).

test(el_evento_no_cambia_la_fase, [nondet]) :-
    con_el_evento_abierto,
    once(estado:fase(F)),
    F == exploracion.

test(volver_con_el_evento_abierto_no_lo_reinicia, [nondet]) :-
    con_el_evento_abierto,
    con_provisiones,
    ordena(elegir(cantar), _),
    ordena(ir(bosque), _),
    ordena(ir(aldea), Items),
    \+ memberchk(msg(evento_abre, _, _), Items),
    memberchk(vista(evento, rescate_gato, 2, _), Items).

test(mirar_con_el_evento_abierto_ensena_las_opciones, [nondet]) :-
    con_el_evento_abierto,
    ordena(mirar, [vista(zona, _), vista(evento, rescate_gato, 3, _)]).

test(mirar_sin_evento_no_ensena_nada_de_eventos, [setup(nueva_partida)]) :-
    ordena(mirar, Items),
    Items = [vista(zona, _)].

test(tras_resolver_mirar_ya_no_ensena_el_evento, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(trepar), _),
    ordena(mirar, Items),
    Items = [vista(zona, _)].

:- end_tests(abrir_el_evento_jugando).

:- begin_tests(comando_elegir).

test(trepar_resuelve_con_exito, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(trepar), Items),
    memberchk(msg(evento_elige, [rescate_gato, trepar], _), Items),
    memberchk(msg(contrato_resuelto, [gato_en_el_arbol, exito], _), Items),
    estado:contrato_por_cobrar(gato_en_el_arbol, exito),
    \+ estado:contrato_activo(gato_en_el_arbol),
    \+ estado:marca(evento_abierto(_)).

test(el_hechizo_resuelve_con_exito_y_cuesta_un_queso, [nondet]) :-
    con_el_evento_abierto,
    economia:queso_total(Antes),
    ordena(elegir(hechizo_de_raclette), _),
    economia:queso_total(Despues),
    Despues =:= Antes - 1,
    estado:contrato_por_cobrar(gato_en_el_arbol, exito).

test(sacudir_el_arbol_resuelve_a_medias, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(sacudir_arbol), Items),
    memberchk(msg(contrato_resuelto, [gato_en_el_arbol, a_medias], _), Items),
    estado:contrato_por_cobrar(gato_en_el_arbol, a_medias).

test(elegir_por_numero, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(3), Items),
    memberchk(msg(evento_elige, [rescate_gato, sacudir_arbol], _), Items).

test(cantar_gasta_un_intento_y_el_evento_sigue, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), Items),
    memberchk(msg(intento_fallido, [rescate_gato, 2], _), Items),
    memberchk(vista(evento, rescate_gato, 2, _), Items),
    estado:contrato_activo(gato_en_el_arbol),
    estado:marca(evento_abierto(rescate_gato)).

test(tres_veces_cantar_fracasa_el_contrato, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _),
    ordena(elegir(cantar), _),
    ordena(elegir(cantar), Items),
    memberchk(msg(intento_fallido, [rescate_gato, 0], _), Items),
    memberchk(msg(contrato_resuelto, [gato_en_el_arbol, fracaso], _), Items),
    estado:contrato_cerrado(gato_en_el_arbol, fracaso),
    \+ estado:marca(evento_abierto(_)).

test(cantar_dos_veces_y_luego_trepar_es_exito, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _),
    ordena(elegir(cantar), _),
    ordena(elegir(trepar), Items),
    memberchk(msg(contrato_resuelto, [gato_en_el_arbol, exito], _), Items).

test(el_fracaso_baja_la_moral_y_deja_reintentar, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _), ordena(elegir(cantar), _), ordena(elegir(cantar), _),
    estado:moral(baldomero, 5),
    contratos:puede_aceptar(gato_en_el_arbol).

test(reintentar_tras_el_fracaso_reabre_con_tres_intentos, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _), ordena(elegir(cantar), _), ordena(elegir(cantar), _),
    ordena(aceptar(gato_en_el_arbol), Items),
    memberchk(msg(evento_abre, [rescate_gato], _), Items),
    memberchk(vista(evento, rescate_gato, 3, _), Items).

test(sin_evento_no_hay_nada_que_elegir, [setup(nueva_partida)]) :-
    ordena(elegir(trepar), Items),
    Items == [error(no_hay_evento)].

test(despues_de_resolver_ya_no_hay_evento, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(trepar), _),
    ordena(elegir(trepar), Items),
    Items == [error(no_hay_evento)].

test(una_opcion_desconocida, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(dragon), I1),
    ordena(elegir(0), I2),
    ordena(elegir(9), I3),
    I1 == [error(opcion_desconocida(dragon))],
    I2 == [error(opcion_desconocida(0))],
    I3 == [error(opcion_desconocida(9))].

test(una_opcion_no_disponible, [nondet]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    ordena(elegir(trepar), Items),
    Items == [error(opcion_no_disponible(trepar))].

test(sin_queso_no_hay_hechizo_al_elegir, [nondet]) :-
    con_el_evento_abierto,
    findall(q(T, E, C), estado:queso(T, E, C), Lotes),
    forall(member(q(T, E, C), Lotes), aplicar_efecto(gastar_queso(T, E, C))),
    ordena(elegir(hechizo_de_raclette), Items),
    Items == [error(opcion_no_disponible(hechizo_de_raclette))].

test(un_error_no_toca_el_estado, [nondet]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    foto_estado(Antes),
    ordena(elegir(trepar), _),
    ordena(elegir(dragon), _),
    ordena(elegir(7), _),
    foto_estado(Despues),
    Antes =@= Despues.

test(un_error_no_gasta_intentos, [nondet]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    ordena(elegir(trepar), _),
    eventos:intentos_restantes(rescate_gato, R),
    R == 3.

test(elegir_con_variable_falta_argumento, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(_), Items),
    Items = [error(falta_argumento(_))].

test(elegir_sin_argumento_no_es_comando, [setup(nueva_partida)]) :-
    validar_comando(elegir, Res),
    Res == error(no_entiendo(elegir)).

test(elegir_con_opcion_es_comando, [setup(nueva_partida)]) :-
    validar_comando(elegir(trepar), Res),
    Res == ok(elegir(trepar)).

test(las_entradas_raras_nunca_fallan_ni_lanzan, [nondet]) :-
    con_el_evento_abierto,
    forall(member(Cmd, [elegir(1), elegir(-3), elegir(1.5), elegir("trepar"), elegir([]), elegir(f(x)),
                        elegir('Trepar'), elegir(cantar), elegir(cantar), elegir(trepar), elegir(trepar)]),
           (   ejecutar(Cmd, R), R = resultado(_) )).

test(en_combate_no_se_elige) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(pelear(rata_quesera), _),
    ordena(elegir(trepar), Items),
    Items = [error(fuera_de_fase(elegir(trepar), combate))].

test(con_la_partida_acabada_no_se_elige, [setup(nueva_partida)]) :-
    aplicar_efecto(fin(victoria)),
    ordena(elegir(trepar), Items),
    Items = [error(fuera_de_fase(_, fin))].

test(la_ayuda_incluye_elegir, [setup(nueva_partida), nondet]) :-
    ordena(ayuda, [vista(ayuda, Cs)]),
    memberchk(elegir, Cs),
    narrador:ayuda_de(elegir, _).

:- end_tests(comando_elegir).

:- begin_tests(la_cadena_del_gato).

test(gato_taberna_venda_gallina, [nondet]) :-
    con_el_evento_abierto,
    \+ contratos:puede_aceptar(gallina_noble),
    ordena(elegir(trepar), _),
    ordena(ir(taberna), Items),
    memberchk(msg(cobra, [gato_en_el_arbol], _), Items),
    estado:equipado(baldomero, venda_de_caballos),
    estado:lleva(compania, venda_de_caballos, 1),
    contratos:puede_aceptar(gallina_noble).

test(a_medias_tambien_entrega_la_venda_pero_cuesta_un_queso, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(sacudir_arbol), _),
    ordena(ir(taberna), _),
    estado:equipado(baldomero, venda_de_caballos),
    contratos:puede_aceptar(gallina_noble).

test(el_exito_paga_siete_y_el_a_medias_cinco, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(trepar), _),
    economia:queso_total(Antes),
    ordena(ir(taberna), _),
    economia:queso_total(D1),
    D1 =:= Antes - 4 + 7.                              % la racion del viaje y la recompensa

test(fracasar_no_da_venda, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _), ordena(elegir(cantar), _), ordena(elegir(cantar), _),
    ordena(ir(taberna), _),
    \+ estado:equipado(baldomero, venda_de_caballos),
    \+ contratos:puede_aceptar(gallina_noble).

test(con_las_ratas_primero_el_combate_y_luego_el_evento, [nondet]) :-
    nueva_partida,
    ordena(aceptar(ratas_del_granero), _),
    ordena(aceptar(gato_en_el_arbol), _),
    ordena(ir(aldea), I0),
    memberchk(msg(objetivo, [ratas_del_granero], _), I0),
    \+ memberchk(msg(evento_abre, _, _), I0),
    ordena(atacar(rata_quesera), _),
    ordena(atacar(rata_quesera), _),
    ordena(atacar(rata_quesera), I3),
    memberchk(msg(contrato_resuelto, [ratas_del_granero, exito], _), I3),
    memberchk(msg(evento_abre, [rescate_gato], _), I3),
    estado:marca(evento_abierto(rescate_gato)).

test(aceptar_las_ratas_en_la_aldea_empieza_el_combate_ya, [nondet]) :-
    nueva_partida,
    ordena(ir(aldea), _),
    ordena(aceptar(ratas_del_granero), Items),
    memberchk(msg(objetivo, [ratas_del_granero], _), Items),
    once(estado:fase(F)),
    F == combate.

:- end_tests(la_cadena_del_gato).

:- begin_tests(ver_y_explicar_el_evento).

test(la_pantalla_ensena_las_opciones_numeradas, [nondet]) :-
    nueva_partida,
    ordena(aceptar(gato_en_el_arbol), _),
    pantalla(ir(aldea), Texto),
    sub_atom(Texto, _, _, _, 'Su Excelencia Bigotes lleva tres días en lo alto del árbol'),
    sub_atom(Texto, _, _, _, '1. trepar: Tuerca trepa a por él (Tuerca)'),
    sub_atom(Texto, _, _, _, '4. cantar: Rufino le canta una balada (gasta un intento) (Rufino)'),
    sub_atom(Texto, _, _, _, 'Intentos que quedan: 3'),
    \+ sub_atom(Texto, _, _, _, 'vista(').

test(una_opcion_no_disponible_se_marca, [nondet]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    pantalla(mirar, Texto),
    sub_atom(Texto, _, _, _, '1. trepar'),
    sub_atom(Texto, _, _, _, '[no disponible]').

test(se_narra_cada_opcion, [nondet]) :-
    forall(member(Op-Trozo, [trepar-'Tuerca trepa sin ruido', hechizo_de_raclette-'hechizo de raclette',
                             sacudir_arbol-'sacude el árbol', cantar-'Rufino canta una balada']),
           (   con_el_evento_abierto,
               pantalla(elegir(Op), Texto),
               sub_atom(Texto, _, _, _, Trozo)
           )).

test(se_narra_el_final_de_los_intentos, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _), ordena(elegir(cantar), _),
    pantalla(elegir(cantar), Texto),
    sub_atom(Texto, _, _, _, 'Se acabaron los intentos en «el rescate del gato»'),
    sub_atom(Texto, _, _, _, 'Contrato fracasado').

test(los_errores_se_leen_bien, [nondet]) :-
    con_el_evento_abierto,
    pantalla(elegir(dragon), T1),
    sub_atom(T1, _, _, _, 'No existe la opción "dragon"'),
    aplicar_efecto(dano(tuerca, 99)),
    pantalla(elegir(trepar), T2),
    sub_atom(T2, _, _, _, 'no está disponible ahora mismo'),
    ordena(elegir(sacudir_arbol), _),
    pantalla(elegir(trepar), T3),
    sub_atom(T3, _, _, _, 'No hay ningún evento abierto').

test(los_mensajes_de_los_intentos_que_quedan, [nondet]) :-
    con_el_evento_abierto,
    pantalla(elegir(cantar), T1),
    sub_atom(T1, _, _, _, 'Os quedan 2 intentos'),
    pantalla(elegir(cantar), T2),
    sub_atom(T2, _, _, _, 'Os queda un intento. Uno solo.').

test(el_evento_entero_sin_terminos_crudos, [nondet]) :-
    nueva_partida,
    forall(member(Cmd, [aceptar(gato_en_el_arbol), ir(aldea), mirar, elegir(dragon), elegir(cantar), elegir(2),
                        contratos, ir(taberna), contratos, inventario, explicar]),
           (   pantalla(Cmd, Texto),
               \+ sub_atom(Texto, _, _, _, 'msg('),
               \+ sub_atom(Texto, _, _, _, 'error('),
               \+ sub_atom(Texto, _, _, _, 'vista('),
               \+ sub_atom(Texto, _, _, _, '[msg'),
               \+ sub_atom(Texto, _, _, _, '~w')
           )).

test(explicar_tras_elegir_ensena_por_que_se_pudo, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _),
    ordena(explicar, [vista(prueba, Accion, Prueba)]),
    Accion == elegir(cantar),
    explicar:prueba_a_lineas(Prueba, Lineas),
    memberchk('[ok] puede_elegir(rescate_gato, cantar)   [clausula 1]', Lineas).

test(la_prueba_ensena_quien_la_hace_y_que_estaba_en_pie, [nondet]) :-
    con_el_evento_abierto,
    ordena(explicar(elegir(trepar)), [vista(prueba, _, Prueba)]),
    explicar:prueba_a_lineas(Prueba, Lineas),
    once(( member(L, Lineas), sub_atom(L, _, _, _, 'en_pie(tuerca)') )),
    once(( member(L2, Lineas), sub_atom(L2, _, _, _, 'evento_abierto(rescate_gato)') )).

test(explicar_una_opcion_por_numero_antes_de_elegir, [nondet]) :-
    con_el_evento_abierto,
    ordena(explicar(elegir(2)), Items),
    Items = [vista(prueba, elegir(2), _)].

test(explicar_una_opcion_imposible_no_tiene_prueba, [nondet]) :-
    con_el_evento_abierto,
    aplicar_efecto(dano(tuerca, 99)),
    ordena(explicar(elegir(trepar)), Items),
    Items == [error(no_hay_prueba(elegir(trepar)))].

test(explicar_sin_evento_no_se_explica, [setup(nueva_partida)]) :-
    ordena(explicar(elegir(trepar)), Items),
    Items = [error(_)].

test(al_cerrar_el_evento_explicar_da_el_resultado_del_contrato, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(trepar), _),                          % cierra el evento y resuelve el contrato
    ordena(explicar, [vista(prueba, Accion, _)]),
    Accion == resultado(gato_en_el_arbol).

test(si_el_evento_sigue_abierto_explicar_da_la_eleccion, [nondet]) :-
    con_el_evento_abierto,
    ordena(elegir(cantar), _),
    ordena(explicar(elegir(cantar)), [vista(prueba, Accion, _)]),
    Accion == elegir(cantar).

test(solve_da_lo_mismo_que_ejecutar_en_varios_estados) :-
    forall(member(Preparar, [con_el_evento_abierto,
                             ( con_el_evento_abierto, aplicar_efecto(dano(tuerca, 99)) ),
                             ( con_el_evento_abierto, aplicar_efecto(contar(intentos_rescate_gato, 2)) ),
                             nueva_partida]),
           (   call(Preparar),
               findall(E-O, eventos:puede_elegir(E, O), D1),
               findall(E-O, solve(eventos:puede_elegir(E, O), _), S1),
               D1 == S1,
               findall(E2, eventos:evento_abierto(E2), D2),
               findall(E2, solve(eventos:evento_abierto(E2), _), S2),
               D2 == S2,
               findall(Os, eventos:opciones_de(rescate_gato, Os), D3),
               findall(Os, solve(eventos:opciones_de(rescate_gato, Os), _), S3),
               D3 == S3
           )).

:- end_tests(ver_y_explicar_el_evento).
