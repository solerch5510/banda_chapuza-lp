% guia.pl (pruebas)
% La ayuda al jugador nuevo: la bienvenida, el consejo de `ayuda.` segun donde estes y la guia rapida
% (docs/guia-rapida.md). Lo importante es que lo que se le ensena a un jugador nuevo FUNCIONA: los comandos de la
% bienvenida y los de "Primeros pasos" de la guia se ejecutan de verdad y no dan errores.
%
% Ejecucion (desde la raiz del repositorio, sin extension en la ruta):
%   swipl -q -s tests/guia -g "run_tests,halt" -t "halt(1)" < /dev/null

:- encoding(utf8).

:- use_module(library(plunit)).
:- use_module(library(readutil)).
:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/narrador').
:- use_module('../src/juego').
:- use_module('../src/ui').
:- use_module('../src/main').
:- use_module('../src/api').

contiene(Texto, Fragmento) :- sub_atom(Texto, _, _, _, Fragmento), !.

leer_utf8(Ruta, Texto) :-
    setup_call_cleanup(open(Ruta, read, S, [type(binary)]),
                       ( set_stream(S, encoding(utf8)), read_stream_to_codes(S, Cs) ),
                       close(S)),
    exclude(==(0'\r), Cs, Sin),
    atom_codes(Texto, Sin).

campo(json(Cs), K, V) :- memberchk(K=V, Cs).

% ordenes_de_la_guia(-Terminos): las lineas del primer bloque de codigo despues de "## Primeros pasos"
ordenes_de_la_guia(Terminos) :-
    leer_utf8('docs/guia-rapida.md', T),
    sub_atom(T, I, _, _, '## Primeros pasos'), !,
    sub_atom(T, I, _, 0, Resto),
    sub_atom(Resto, A, _, _, '```text\n'), !,
    A1 is A + 8,
    sub_atom(Resto, A1, _, 0, Desde),
    sub_atom(Desde, B, _, _, '```'), !,
    sub_atom(Desde, 0, B, _, Bloque),
    atomic_list_concat(Lineas, '\n', Bloque),
    findall(Term, ( member(L, Lineas), L \== '', api:texto_de_orden(L, Term) ), Terminos).

:- begin_tests(la_bienvenida).

test(dice_el_objetivo_y_como_empezar) :-
    narrador:bienvenida(Ls),
    atomic_list_concat(Ls, '\n', T),
    assertion(contiene(T, '=== BANDA CHAPUZA ===')),
    assertion(contiene(T, 'Objetivo:')),
    assertion(contiene(T, 'Gran Roquefort')),
    assertion(contiene(T, 'contratos.')),
    assertion(contiene(T, 'aceptar(ratas_del_granero).')),
    assertion(contiene(T, 'ir(aldea).')),
    assertion(contiene(T, 'ayuda.')),
    assertion(contiene(T, 'por_que_no')).

test(la_consola_la_imprime_entera) :-
    nueva_partida,
    with_output_to(atom(T), ui:bienvenida),
    narrador:bienvenida(Ls),
    forall(member(L, Ls), assertion(contiene(T, L))).

test(los_primeros_pasos_de_la_bienvenida_funcionan_en_orden) :-
    main:transcribir([contratos, aceptar(ratas_del_granero), ir(aldea), salir], T),
    assertion(contiene(T, 'Contrato aceptado')),
    assertion(contiene(T, 'Combate')),
    assertion(\+ contiene(T, 'No entiendo')),
    assertion(\+ contiene(T, 'error(')).

:- end_tests(la_bienvenida).

:- begin_tests(el_consejo_de_ayuda).

test(cada_fase_tiene_su_consejo_distinto) :-
    findall(C, ( member(F, [exploracion, taberna, combate, fin]),
                 juego:comandos_disponibles(F, L), narrador:consejo_de_ayuda(L, C) ), Cs),
    assertion(length(Cs, 4)),
    sort(Cs, Unicos), length(Unicos, N), assertion(N == 4).

test(el_consejo_habla_de_lo_que_se_puede_hacer_alli) :-
    juego:comandos_disponibles(taberna, Lt), narrador:consejo_de_ayuda(Lt, T),
    assertion(contiene(T, 'taberna')), assertion(contiene(T, 'pagar.')),
    juego:comandos_disponibles(combate, Lc), narrador:consejo_de_ayuda(Lc, C),
    assertion(contiene(C, 'combate')), assertion(contiene(C, 'atacar(')),
    juego:comandos_disponibles(exploracion, Le), narrador:consejo_de_ayuda(Le, E),
    assertion(contiene(E, 'viaje')), assertion(\+ contiene(E, 'pagar.')),
    juego:comandos_disponibles(fin, Lf), narrador:consejo_de_ayuda(Lf, F),
    assertion(contiene(F, 'terminado')).

test(el_comando_ayuda_lo_enseña_en_la_consola) :-
    nueva_partida,
    main:transcribir([ayuda, salir], T),
    narrador:consejo_de_ayuda([ayuda, mirar, pagar], Consejo),
    assertion(contiene(T, Consejo)).

test(el_comando_ayuda_lo_lleva_en_el_json) :-
    nueva_partida,
    api:ejecutar_orden(ayuda, R), campo(R, items, Is),
    member(I, Is), campo(I, tipo, ayuda), !,
    campo(I, consejo, C), assertion(contiene(C, 'taberna')).

test(en_combate_el_consejo_del_json_habla_de_combate) :-
    nueva_partida,
    api:ejecutar_orden('demo(combate)', _),
    api:ejecutar_orden(ayuda, R), campo(R, items, Is),
    member(I, Is), campo(I, tipo, ayuda), !,
    campo(I, consejo, C), assertion(contiene(C, 'combate')).

:- end_tests(el_consejo_de_ayuda).

:- begin_tests(la_guia_rapida).

test(los_primeros_pasos_se_ejecutan_sin_errores) :-
    ordenes_de_la_guia(Ts),
    assertion(Ts \== []),
    append(Ts, [salir], Todas),
    main:transcribir(Todas, T),
    assertion(\+ contiene(T, 'No entiendo')),
    assertion(\+ contiene(T, 'error(')),
    assertion(contiene(T, 'Contrato aceptado')),
    assertion(contiene(T, 'Combate')),
    assertion(contiene(T, 'Por qué se pudo atacar')).

test(los_primeros_pasos_son_siete_ordenes_con_las_tres_de_la_bienvenida) :-
    ordenes_de_la_guia(Ts),
    length(Ts, N), assertion(N == 7),
    assertion(memberchk(contratos, Ts)),
    assertion(memberchk(aceptar(ratas_del_granero), Ts)),
    assertion(memberchk(ir(aldea), Ts)).

test(la_guia_cabe_en_una_pagina) :-
    leer_utf8('docs/guia-rapida.md', T),
    atomic_list_concat(Ls, '\n', T), length(Ls, N),
    assertion(N =< 90).

test(la_guia_cita_los_comandos_que_existen) :-
    leer_utf8('docs/guia-rapida.md', T),
    forall(member(C, ['ayuda.', 'contratos.', 'inventario.', 'pagar.', 'descansar.', 'mirar.', 'explicar.',
                      'por_que_no(', 'nivel(detallado).', 'nivel(resumido).', 'demo.', 'habilidad(', 'defender.']),
           assertion(contiene(T, C))).

test(el_readme_enlaza_la_guia) :-
    leer_utf8('README.md', T),
    assertion(contiene(T, 'docs/guia-rapida.md')).

:- end_tests(la_guia_rapida).

:- begin_tests(la_partida_nueva_de_la_web).

test(nueva_partida_trae_la_bienvenida_y_la_zona) :-
    api:nueva_partida_json(J),
    campo(J, bienvenida, Ls), narrador:bienvenida(Esperadas),
    assertion(Ls == Esperadas),
    campo(J, items, Is),
    assertion(( member(I, Is), campo(I, tipo, zona) )).

test(la_web_muestra_la_bienvenida_el_consejo_y_una_pista_de_inicio) :-
    leer_utf8('web/app.js', J),
    assertion(contiene(J, 'resp.bienvenida')),
    assertion(contiene(J, 'consejo')),
    assertion(contiene(J, 'Se juega escribiendo')).

:- end_tests(la_partida_nueva_de_la_web).
