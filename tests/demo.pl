% demo.pl (pruebas)
% T-40: la demostracion reproducible. (1) Las cinco escenas (economia, combate, ia, gallina, venda) existen,
% se montan sin error y dejan el estado que dicen; montarlas dos veces da lo mismo. (2) `demo.` las lista y
% una escena desconocida es un error amable que no toca la partida. (3) Los guiones de examples/ se leen
% y se pueden pasar enteros; sus transcripciones guardadas COINCIDEN, caracter a caracter, con lo que el
% juego produce ahora (si cambia una frase del narrador hay que volver a generar: examples/generar.pl).
% (4) Las pantallas clave de la exposicion llevan lo que se va a ensenar.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/demo -g "run_tests,halt" -t "halt(1)"

:- encoding(utf8).
% Los encuentros al llegar a una zona (docs/13, 5) se apagan: aqui un viaje es un viaje. Solo tests/encuentros los enciende.
:- create_prolog_flag(banda_encuentros, false, []).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/combate').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../examples/generar').

% pantalla(+Items, -Texto): lo que veria el jugador.
pantalla(Items, Texto) :-
    with_output_to(atom(Texto), ui:mostrar(resultado(Items))).

% sesion(+Terminos, -Texto): una sesion completa desde partida nueva.
sesion(Terminos, Texto) :- main:transcribir(Terminos, Texto).

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

% leer_utf8(+Ruta, -Texto): el archivo guardado, sin los retornos de carro (si git los hubiera puesto).
leer_utf8(Ruta, Texto) :-
    setup_call_cleanup(open(Ruta, read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs) ),
                       close(S)),
    exclude(==(0'\r), Cs, Sin),
    atom_codes(Texto, Sin).

ruta_de(Archivo, Ruta) :- atomic_list_concat(['examples/', Archivo], Ruta).

% foto(-Foto): el estado que importa, para ver que algo no lo toca.
foto(f(Zona, Dia, Compania, Vidas, Marcas)) :-
    estado:en_zona(Zona), estado:dia(Dia),
    findall(I, estado:en_compania(I), Compania),
    findall(I-V, estado:vida(I, V), Vidas),
    findall(M, estado:marca(M), Marcas).

:- begin_tests(las_escenas).

test(hay_cinco_escenas_en_orden) :-
    escenas_de_demo(L),
    findall(N, member(N-_, L), Ns),
    assertion(Ns == [economia, combate, ia, gallina, venda]).

test(todas_tienen_titulo_descripcion_y_sugerencias) :-
    forall(demo:escena(N, T, D, P, S),
           ( assertion(atom(N)), assertion(atom(T)), assertion(atom(D)),
             assertion(P \== []), assertion(S \== []) )).

test(cada_escena_se_monta_y_muestra_su_titulo_y_sugerencias) :-
    forall(demo:escena(N, T, _, _, S),
           (   nueva_partida,
               preparar_escena(N, Items),
               Items = [vista(escena, N, T, _, S)|_],
               pantalla(Items, Texto),
               assertion(contiene(Texto, '=== ESCENA:')),
               assertion(contiene(Texto, T)),
               assertion(contiene(Texto, 'Para probar:')),
               forall(member(Sug, S),
                      (   format(atom(Linea), '~W.', [Sug, [quoted(true), spacing(next_argument)]]),
                          assertion(contiene(Texto, Linea))
                      ))
           )).

test(las_sugerencias_de_cada_escena_se_ejecutan_sin_error) :-
    forall(demo:escena(N, _, _, _, S),
           (   append([demo(N)], S, Cmds0), append(Cmds0, [salir], Cmds),
               sesion(Cmds, Texto),
               assertion(\+ contiene(Texto, 'No entiendo')),
               assertion(\+ contiene(Texto, 'error('))
           )).

test(montar_una_escena_dos_veces_da_la_misma_pantalla) :-
    forall(member(N, [economia, combate, ia, gallina]),
           (   nueva_partida, preparar_escena(N, I1), pantalla(I1, T1),
               juego:ejecutar(inventario, _),
               preparar_escena(N, I2), pantalla(I2, T2),
               assertion(T1 == T2)
           )).

test(reiniciar_borra_lo_jugado_antes) :-
    nueva_partida,
    estado:aplicar_efectos([avanzar_dia, avanzar_dia]),
    preparar_escena(combate, _),
    estado:dia(D),
    assertion(D == 1), !.

:- end_tests(las_escenas).

:- begin_tests(el_estado_de_cada_escena).

test(economia_dia_12_con_queso_de_tres_edades) :-
    nueva_partida, preparar_escena(economia, _),
    estado:dia(D), assertion(D == 12),
    estado:en_zona(Z), assertion(Z == taberna),
    sesion([demo(economia), inventario, salir], T),
    assertion(contiene(T, '(fresco)')),
    assertion(contiene(T, '(curado)')),
    assertion(contiene(T, '(rancio)')), !.

test(economia_pagar_cuesta_y_los_quesos_maduran) :-
    sesion([demo(economia), pagar, ir(aldea), ir(bosque), inventario, salir], T),
    assertion(contiene(T, 'Sueldos pagados')),
    assertion(contiene(T, 'Despensa (día 14)')).

test(combate_baldomero_no_puede_con_el_montado_pero_si_con_el_torpe) :-
    nueva_partida, preparar_escena(combate, _),
    assertion(estado:en_combate(_)),
    estado:instancia(M, bandido_montado), estado:instancia(T, bandido_torpe),
    assertion(\+ combate:puede_atacar(baldomero, M)),
    assertion(combate:puede_atacar(baldomero, T)),
    assertion(estado:en_zona(camino_real)), !.

test(ia_un_solo_bandido_torpe_y_turno_de_baldomero) :-
    nueva_partida, preparar_escena(ia, _),
    findall(E, ( estado:instancia(E, _), compania:vivo(E) ), Es),
    length(Es, N), assertion(N == 1),
    estado:cola_turnos([A|_]), assertion(A == baldomero), !.

test(gallina_en_camino_real_sin_combate_y_con_baldomero_con_miedo) :-
    nueva_partida, preparar_escena(gallina, _),
    assertion(estado:en_zona(camino_real)),
    assertion(\+ estado:en_combate(_)),
    assertion(\+ estado:equipado(baldomero, venda_de_caballos)), !.

test(venda_equipa_a_baldomero_y_no_reinicia) :-
    nueva_partida, preparar_escena(gallina, _),
    estado:aplicar_efectos([avanzar_dia]),
    preparar_escena(venda, _),
    assertion(estado:equipado(baldomero, venda_de_caballos)),
    estado:dia(D), assertion(D == 2), !.

test(con_la_venda_la_gallina_se_acepta) :-
    sesion([demo(gallina), demo(venda), por_que_no(aceptar(gallina_noble)), aceptar(gallina_noble), salir], T),
    assertion(contiene(T, 'No falla nada')),
    assertion(contiene(T, 'Contrato aceptado')).

:- end_tests(el_estado_de_cada_escena).

:- begin_tests(el_comando_demo).

test(demo_lista_las_cinco_escenas) :-
    sesion([demo, salir], T),
    forall(member(N, [economia, combate, ia, gallina, venda]),
           ( format(atom(F), 'demo(~w).', [N]), assertion(contiene(T, F)) )).

test(demo_lista_no_toca_la_partida) :-
    nueva_partida, estado:aplicar_efectos([avanzar_dia]), foto(A),
    with_output_to(atom(_), main:procesar(demo, _)),
    foto(B),
    assertion(A =@= B).

test(escena_desconocida_da_un_error_amable_y_no_toca_nada) :-
    nueva_partida, estado:aplicar_efectos([avanzar_dia, avanzar_dia]),
    foto(Antes),
    preparar_escena(zzz, Items),
    assertion(Items == [error(escena_desconocida(zzz))]),
    foto(Despues),
    assertion(Antes =@= Despues),
    pantalla(Items, Texto),
    assertion(contiene(Texto, 'zzz')),
    assertion(\+ contiene(Texto, 'error(')).

test(demo_con_escena_desconocida_en_la_sesion_sigue_jugando) :-
    sesion([demo(zzz), mirar, salir], T),
    assertion(contiene(T, 'zzz')),
    assertion(contiene(T, 'Taberna del Cuajo Torcido')).

test(la_ayuda_menciona_demo) :-
    sesion([ayuda, salir], T),
    assertion(contiene(T, 'demo')).

test(demo_de_combate_deja_la_partida_en_combate) :-
    sesion([demo(combate), salir], T),
    assertion(contiene(T, 'Combate · ronda 1')).

:- end_tests(el_comando_demo).

:- begin_tests(los_guiones).

test(los_guiones_se_leen_y_acaban_en_salir) :-
    forall(member(F, ['demo-comandos.txt', 'campana-comandos.txt']),
           (   ruta_de(F, Ruta),
               leer_guion(Ruta, Ts),
               length(Ts, N), assertion(N > 20),
               last(Ts, U), assertion(U == salir),
               forall(member(T, Ts), assertion(callable(T)))
           )).

test(el_guion_de_la_demo_recorre_las_cinco_escenas) :-
    leer_guion('examples/demo-comandos.txt', Ts),
    findall(N, member(demo(N), Ts), Ns),
    assertion(Ns == [economia, combate, ia, gallina, venda]).

test(una_sesion_repetida_da_el_mismo_texto) :-
    leer_guion('examples/demo-comandos.txt', Ts),
    sesion(Ts, A), sesion(Ts, B),
    assertion(A == B).

test(la_sesion_empieza_por_la_bienvenida_y_termina_en_salir) :-
    leer_guion('examples/demo-comandos.txt', Ts),
    sesion(Ts, T),
    assertion(sub_atom(T, 0, _, _, '
=== BANDA CHAPUZA ===')),
    assertion(sub_atom(T, _, _, 0, 'Hasta la próxima, Banda Chapuza.\n')).

test(sin_salir_la_sesion_acaba_con_la_lista) :-
    sesion([mirar], T),
    assertion(contiene(T, '> mirar')).

test(cada_orden_se_escribe_tras_el_prompt) :-
    sesion([inventario, salir], T),
    assertion(contiene(T, '\n> inventario\n')),
    assertion(contiene(T, '\n> salir\n')).

:- end_tests(los_guiones).

:- begin_tests(lo_guardado_coincide).

test(todos_los_archivos_guardados_son_lo_que_el_juego_produce_ahora) :-
    findall(A, generado(A, _), As),
    length(As, N), assertion(N == 10),
    forall(generado(Archivo, Texto),
           (   ruta_de(Archivo, Ruta),
               leer_utf8(Ruta, Guardado),
               (   Guardado == Texto -> true
               ;   format(user_error, "~nDIFIERE ~w; vuelve a generar con examples/generar.pl~n", [Archivo]),
                   fail
               )
           )).

test(los_archivos_guardados_estan_en_utf8_sin_retorno_de_carro) :-
    forall(generado(Archivo, _),
           (   ruta_de(Archivo, Ruta),
               read_file_to_codes(Ruta, Bytes, [type(binary)]),
               assertion(\+ memberchk(0'\r, Bytes)),
               assertion(\+ mojibake(Bytes))
           )).

% "Ã" seguida de otro byte alto = una "á/é/ó..." codificada dos veces.
mojibake(Bytes) :- append(_, [0xC3, 0x83|_], Bytes).

test(los_archivos_de_explicaciones_existen_y_no_estan_vacios) :-
    findall(A, ( generado(A, _), sub_atom(A, 0, _, _, 'explicaciones/') ), As),
    length(As, N), assertion(N == 8),
    forall(member(A, As),
           ( ruta_de(A, Ruta), size_file(Ruta, Tam), assertion(Tam > 500) )).

:- end_tests(lo_guardado_coincide).

:- begin_tests(las_pantallas_clave).

test(la_demo_ensena_el_calculo_del_dano_y_el_corte) :-
    leer_utf8('examples/demo-salida.txt', T),
    assertion(contiene(T, '9 is max(1, 11-2+0)')),
    assertion(contiene(T, '[clausula 6 + corte]')),
    assertion(contiene(T, 'Las reglas de más prioridad no se aplicaron:')).

test(la_demo_ensena_el_miedo_a_los_caballos_en_los_dos_niveles) :-
    leer_utf8('examples/demo-salida.txt', T),
    assertion(contiene(T, 'teme(baldomero, caballo) y clase_de(e(bandido_montado, 1), caballo) son ciertos')),
    assertion(contiene(T, '[ok] rasgo(baldomero, teme_caballos)   [hecho]')),
    assertion(contiene(T, 'Nivel detallado')),
    assertion(contiene(T, 'Nivel resumido')).

test(la_campana_de_respaldo_se_gana) :-
    leer_utf8('examples/campana-salida.txt', T),
    assertion(contiene(T, 'Fin de la partida.')),
    assertion(contiene(T, 'Chapuza de toda la vida. Ganáis.')),
    assertion(\+ contiene(T, 'No entiendo')).

test(la_campana_no_ensena_terminos_crudos_de_pantalla) :-
    leer_utf8('examples/campana-salida.txt', T),
    assertion(\+ contiene(T, 'vista(')),
    assertion(\+ contiene(T, 'error(')).

test(la_explicacion_del_turno_enemigo_dice_que_gano_una_regla) :-
    leer_utf8('examples/explicaciones/04-turno-enemigo-resumido.txt', T),
    assertion(contiene(T, 'Eligió la regla de prioridad')),
    assertion(contiene(T, 'el corte descartó las demás')).

test(la_explicacion_con_venda_dice_que_no_falla_nada) :-
    leer_utf8('examples/explicaciones/08-gallina-con-la-venda.txt', T),
    assertion(contiene(T, 'No falla nada')).

test(el_detallado_es_mas_largo_que_el_resumido) :-
    forall(member(A-B, [ '02-por-que-no-el-montado-resumido'-'03-por-que-no-el-montado-detallado',
                         '04-turno-enemigo-resumido'-'05-turno-enemigo-detallado',
                         '06-gallina-resumido'-'07-gallina-detallado' ]),
           (   atomic_list_concat(['examples/explicaciones/', A, '.txt'], RA),
               atomic_list_concat(['examples/explicaciones/', B, '.txt'], RB),
               leer_utf8(RA, TA), leer_utf8(RB, TB),
               atom_length(TA, LA), atom_length(TB, LB),
               assertion(LB > LA)
           )).

:- end_tests(las_pantallas_clave).
