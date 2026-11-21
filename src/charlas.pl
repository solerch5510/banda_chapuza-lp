% charlas.pl
% Hablar con los NPC (docs/12-npcs.md). Las zonas tienen gente, y la gente cuenta cosas.
%
% Una charla es una escena corta con opciones, como el evento del gato, pero SIN contrato: la abre
% `hablar(Npc)`, se resuelve con `elegir/1` y solo se puede hacer una vez. Cada opcion la hace un miembro de la
% Banda y da cosas pequenas (queso, moral) o INFORMACION (un fragmento de la historia del Gran Rancio, que
% apunta el diario). Los personajes no estan siempre: cada uno aparece entre dos dias.
%
% Todo son DATOS (presente/4, escena_de/2, opcion_charla/5, saber/1) y REGLAS puras que consultan el estado y
% devuelven efectos como datos; solo estado.pl los aplica. Los textos viven en narrador.pl.
% Estado: la marca charla_abierta(Npc) mientras esta a medias, charla_hecha(Npc) al resolverla y sabe(Marca)
% por cada fragmento averiguado.

:- module(charlas, [presente/4, escena_de/2, opcion_charla/5, saber/1, personaje_de_charla/1,
                    presentes/1, puede_hablar/1, charla_abierta/1, charla_hecha/1,
                    opciones_de/2, puede_elegir/2, resolver_opcion/3,
                    efectos_apertura/2, efectos_eleccion/3, saberes/1, sabe/1]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

% ---------------------------------------------------------------------------
% Los datos.
% presente(Npc, Zona, Desde, Hasta): donde esta y entre que dias (inclusive; 99 = todo el juego).
% ---------------------------------------------------------------------------
presente(mantecosa,        taberna,     1, 99).
presente(gruyere,          taberna,     1,  5).
presente(alcaldesa_nata,   aldea,       1, 99).
presente(ricota,           aldea,       1,  5).
presente(penicilio,        bosque,      1, 99).
presente(ganso_recaudador, camino_real, 1, 99).
presente(rey_brieto,       castillo,    1, 99).
presente(el_eco,           cuevas,      1, 99).

% escena_de(Npc, Escena): la escena que cuenta cada uno.
escena_de(mantecosa,        la_cuenta).
escena_de(gruyere,          la_carreta).
escena_de(alcaldesa_nata,   las_quejas).
escena_de(ricota,           la_oferta).
escena_de(penicilio,        el_hambre_del_moho).
escena_de(ganso_recaudador, el_peaje).
escena_de(rey_brieto,       la_audiencia).
escena_de(el_eco,           lo_que_repites).

% opcion_charla(Escena, Opcion, Quien, Condiciones, Efectos):
%   Quien la hace (tiene que estar en pie); Condiciones: en_pie(Id), queso_min(N);
%   Efectos: ganar_queso(N), perder_queso(N), moral(grupo|Id, N), saber(Marca).
opcion_charla(la_cuenta, jurar_honor, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(la_cuenta, invitar_al_caldo, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(moho_en_la_despensa)]).
opcion_charla(la_cuenta, mirar_los_desagues, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1), moral(rufino, -1)]).

opcion_charla(la_carreta, vengar_al_viajante, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, 1), saber(bandidos_a_caballo)]).
opcion_charla(la_carreta, consolar_con_una_balada, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).
opcion_charla(la_carreta, ayudarle_a_recoger, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(1)]).

opcion_charla(las_quejas, escuchar_la_lista, baldomero,
              [en_pie(baldomero)],
              [saber(vacas_azules)]).
opcion_charla(las_quejas, curar_las_vacas, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), ganar_queso(2)]).
opcion_charla(las_quejas, ojear_el_registro, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(la_oferta, cantar_el_anuncio, rufino,
              [en_pie(rufino)],
              [ganar_queso(1)]).
opcion_charla(la_oferta, regatear, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(2), moral(tuerca, -1)]).
opcion_charla(la_oferta, preguntar_por_los_precios, pimentina,
              [en_pie(pimentina)],
              [moral(pimentina, 1)]).

opcion_charla(el_hambre_del_moho, hablar_con_el_moho, pimentina,
              [en_pie(pimentina)],
              [saber(moho_con_hambre)]).
opcion_charla(el_hambre_del_moho, amenazar_con_fuego, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_hambre_del_moho, cantarle_al_moho, rufino,
              [en_pie(rufino)],
              [moral(rufino, 1), saber(moho_con_hambre)]).

opcion_charla(el_peaje, discutir_el_peaje, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(el_peaje, pagar_el_peaje, pimentina,
              [en_pie(pimentina), queso_min(1)],
              [perder_queso(1), saber(gremio_sin_peaje)]).
opcion_charla(el_peaje, esquivar_al_ganso, tuerca,
              [en_pie(tuerca)],
              [moral(tuerca, 1)]).

opcion_charla(la_audiencia, hacer_la_reverencia, baldomero,
              [en_pie(baldomero)],
              [moral(grupo, 1)]).
opcion_charla(la_audiencia, preguntar_por_la_despensa, pimentina,
              [en_pie(pimentina)],
              [saber(brieto_firmo)]).
opcion_charla(la_audiencia, registrar_los_bolsillos_reales, tuerca,
              [en_pie(tuerca)],
              [ganar_queso(2), moral(baldomero, -1)]).

opcion_charla(lo_que_repites, cantar_a_la_cueva, rufino,
              [en_pie(rufino)],
              [moral(grupo, 1)]).
opcion_charla(lo_que_repites, gritarle_al_eco, baldomero,
              [en_pie(baldomero)],
              [moral(baldomero, -1)]).
opcion_charla(lo_que_repites, susurrar_una_pregunta, tuerca,
              [en_pie(tuerca)],
              [saber(el_eco_habla_solo)]).

% saber(Marca): los fragmentos de historia, en el orden en que los ensena el diario.
saber(moho_en_la_despensa).
saber(moho_con_hambre).
saber(brieto_firmo).
saber(el_eco_habla_solo).
saber(gremio_sin_peaje).
saber(vacas_azules).
saber(bandidos_a_caballo).

% personaje_de_charla(?Npc): los que tienen escena.
personaje_de_charla(Npc) :-
    escena_de(Npc, _).

% ---------------------------------------------------------------------------
% Quien esta y se puede hablar.
% ---------------------------------------------------------------------------
% puede_hablar(?Npc): esta en esta zona hoy y no hay combate (la regla que explica `hablar`).
puede_hablar(Npc) :-
    \+ estado:en_combate(_),
    estado:en_zona(Zona),
    estado:dia(Dia),
    presente(Npc, Zona, Desde, Hasta),
    Dia >= Desde,
    Dia =< Hasta.

% presentes(-Lista): los que hay aqui hoy, en el orden del reparto.
presentes(Lista) :-
    findall(Npc, ( presente(Npc, _, _, _), puede_hablar(Npc) ), Lista).

charla_hecha(Npc) :-
    estado:marca(charla_hecha(Npc)).

% charla_abierta(?Npc): se empezo, no se ha resuelto y sigue aqui.
charla_abierta(Npc) :-
    estado:marca(charla_abierta(Npc)),
    puede_hablar(Npc).

% sabe(?Marca): ya se ha averiguado.
sabe(Marca) :-
    estado:marca(sabe(Marca)).

% saberes(-Marcas): lo averiguado, en el orden de saber/1.
saberes(Marcas) :-
    findall(M, ( saber(M), sabe(M) ), Marcas).

% ---------------------------------------------------------------------------
% Las opciones.
% ---------------------------------------------------------------------------
% opciones_de(+Npc, -Lista): opcion(N, Opcion, Quien, Disponible) en orden de definicion.
opciones_de(Npc, Lista) :-
    escena_de(Npc, Escena),
    findall(Opcion-Quien, opcion_charla(Escena, Opcion, Quien, _, _), Pares),
    numerar(Pares, 1, Escena, Lista).

numerar([], _, _, []).
numerar([Opcion-Quien|Resto], N, Escena, [opcion(N, Opcion, Quien, Disponible)|Lista]) :-
    (   cumple_opcion(Escena, Opcion) -> Disponible = si ; Disponible = no ),
    N1 is N + 1,
    numerar(Resto, N1, Escena, Lista).

% cumple_opcion(+Escena, +Opcion): quien la hace esta en pie y se cumplen sus condiciones.
cumple_opcion(Escena, Opcion) :-
    opcion_charla(Escena, Opcion, Quien, Condiciones, _),
    compania:activo(Quien),
    cumple_condiciones(Condiciones).

cumple_condiciones([]).
cumple_condiciones([C|Resto]) :-
    condicion_ok(C),
    cumple_condiciones(Resto).

condicion_ok(en_pie(Id))   :- compania:en_pie(Id).
condicion_ok(queso_min(N)) :- economia:hay_queso_para(N).

% puede_elegir(?Npc, ?Opcion): la regla que explica `elegir` en una charla: esta abierta y la opcion se puede.
puede_elegir(Npc, Opcion) :-
    charla_abierta(Npc),
    escena_de(Npc, Escena),
    cumple_opcion(Escena, Opcion).

% resolver_opcion(+Npc, +LoEscrito, -Opcion): un numero (la N-esima) o el nombre de la opcion.
resolver_opcion(Npc, Escrito, Opcion) :-
    opciones_de(Npc, Lista),
    (   integer(Escrito)
    ->  memberchk(opcion(Escrito, Opcion, _, _), Lista)
    ;   atom(Escrito),
        memberchk(opcion(_, Escrito, _, _), Lista),
        Opcion = Escrito
    ).

% ---------------------------------------------------------------------------
% Efectos (datos; los aplica estado).
% ---------------------------------------------------------------------------
% efectos_apertura(+Npc, -Efectos): la charla se abre; el personaje habla.
efectos_apertura(Npc, [marcar(charla_abierta(Npc)), mensaje(charla_abre, [Npc])]).

% efectos_eleccion(+Npc, +Opcion, -Efectos): lo que pasa al elegir; la charla queda hecha para siempre.
efectos_eleccion(Npc, Opcion, Efectos) :-
    escena_de(Npc, Escena),
    opcion_charla(Escena, Opcion, _, _, Efectos04),
    expandir_todos(Efectos04, Propios),
    findall(mensaje(saber_nuevo, [M]), ( member(saber(M), Efectos04), \+ sabe(M) ), Nuevos),
    append([[mensaje(charla_elige, [Npc, Opcion])], Propios, Nuevos,
            [desmarcar(charla_abierta(Npc)), marcar(charla_hecha(Npc))]], Efectos).

expandir_todos([], []).
expandir_todos([E|Es], Efectos) :-
    expandir(E, Efs1),
    expandir_todos(Es, Efs2),
    append(Efs1, Efs2, Efectos).

expandir(ganar_queso(N), [ganar_queso(cheddar, 0, N)]).
expandir(perder_queso(N), Efs) :-
    economia:efectos_perdida(N, Efs).
expandir(moral(grupo, N), Efs) :-
    findall(mod_moral(Id, N), compania:activo(Id), Efs).
expandir(moral(Id, N), [mod_moral(Id, N)]) :-
    Id \== grupo.
expandir(saber(M), [marcar(sabe(M))]).
