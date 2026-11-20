% simulador.pl
% El simulador de balance: juega partidas enteras SIN persona, con el mismo motor que la consola, y mide si el
% juego es ganable y con cuanto margen. Es una HERRAMIENTA (no forma parte del juego): sirve para ajustar los
% numeros de balance con datos en vez de a ojo.
%
% Dos tipos de jugador:
%   * una ruta guionizada (una lista de ordenes, con el combate automatico entre ellas): reproduce la ruta de una
%     persona y dice como acaba (la campana de examples/ es la ruta de referencia; ruta_separada/1 es la de un
%     jugador real que perdio el dia 6).
%   * un jugador ALEATORIO RAZONABLE (azar propio con semilla, sin random/1): en cada paso elige entre las ordenes
%     que de verdad se pueden dar, con pesos (aceptar, viajar y pagar pesan mas que descansar). Dice que fraccion
%     de las partidas razonables se ganan, en cuantos dias y con cuanto queso de sobra.
%
% Uso (desde la raiz del repositorio):
%   swipl -q -s herramientas/simulador -g "informe(200, 1)" -t halt      (200 partidas, semilla 1)

:- module(simulador, [episodio/4, informe/2, orden_con_plan/3, jugar_ruta/2, ruta_de_referencia/2, candidatas/1,
                      resumen_de/2, ruta_separada/1, resumir/2, fijar_azar/1]).
:- encoding(utf8).

:- use_module('../src/mundo').
:- use_module('../src/estado').
:- use_module('../src/compania').
:- use_module('../src/economia').
:- use_module('../src/combate').
:- use_module('../src/contratos').
:- use_module('../src/juego').
:- use_module('../src/main').

% ---------------------------------------------------------------------------
% Azar propio y reproducible (el mismo generador congruencial que el juego, pero independiente de su estado)
% ---------------------------------------------------------------------------
fijar_azar(S) :- nb_setval(sim_azar, S).

azar(N, K) :-
    nb_getval(sim_azar, S0),
    estado:siguiente_semilla(S0, S1),
    nb_setval(sim_azar, S1),
    K is S1 mod N.

% ---------------------------------------------------------------------------
% Las ordenes que se pueden dar ahora, con su peso. Una orden es candidata si el juego dice que se puede.
% ---------------------------------------------------------------------------
candidatas(Cs) :-
    once(estado:fase(Fase)),
    findall(P-Cmd, ( candidata(Fase, Cmd, P), valida(Cmd) ), Cs0),
    Cs0 \== [],
    sort(Cs0, Cs).

valida(Cmd) :-
    catch(( juego:objetivo_de_accion(Cmd, Meta), once(Meta) ), _, fail).

candidata(combate, atacar(T), 4) :- tipo_vivo(T).
candidata(combate, habilidad(T), 2) :- tipo_vivo(T).
candidata(combate, habilidad, 2).
candidata(combate, defender, 1).
candidata(F, ir(Z), 3) :- F \== combate, estado:en_zona(A), mundo:adyacente(A, Z).
candidata(F, aceptar(C), 3) :- F \== combate, contratos:contrato(C, _, _, _, _).
candidata(F, pagar, 2) :- F \== combate.
candidata(F, descansar, 1) :- F \== combate.
candidata(F, elegir(N), 6) :- F \== combate, between(1, 4, N).

tipo_vivo(T) :-
    setof(Tipo, E^( estado:instancia(E, Tipo), compania:vivo(E) ), Tipos),
    member(T, Tipos).

% elegir_orden(-Cmd): al azar entre las candidatas, segun su peso.
elegir_orden(Cmd) :-
    candidatas(Cs),
    Cs = [_|_],
    findall(P, member(P-_, Cs), Ps), sumlist(Ps, Total),
    azar(Total, K),
    escoger(Cs, K, Cmd).

escoger([P-Cmd|Resto], K, Elegida) :-
    (   K < P -> Elegida = Cmd ; K1 is K - P, escoger(Resto, K1, Elegida) ).

% ---------------------------------------------------------------------------
% Un episodio entero. La politica es:
%   azar            el jugador aleatorio razonable de arriba (el peor caso: vaga sin plan)
%   plan(Eps, Lote) un jugador con plan: paga, acepta hasta Lote contratos, va al sitio de un contrato abierto
%                   (por el camino mas corto), vuelve a cobrar; con un Eps % de las veces hace otra cosa al azar.
% ---------------------------------------------------------------------------
% episodio(+Politica, +Semilla, +MaxPasos, -Resumen)
episodio(Politica, Semilla, Max, Resumen) :-
    fijar_azar(Semilla),
    estado:nueva_partida,
    pasos(Politica, 0, Max, Resumen).

pasos(Pol, N, Max, Resumen) :-
    (   estado:fin_partida(_) -> resumen_de(N, Resumen)
    ;   N >= Max             -> resumen_de(N, Resumen)
    ;   orden_de(Pol, Cmd)   ->
        juego:ejecutar(Cmd, _),
        N1 is N + 1,
        pasos(Pol, N1, Max, Resumen)
    ;   resumen_de(N, Resumen)               % ninguna orden posible: se queda bloqueado
    ).

orden_de(azar, Cmd) :- !, elegir_orden(Cmd).
orden_de(plan(Eps, Lote), Cmd) :- orden_con_plan(Eps, Lote, Cmd).

% orden_con_plan(+Eps, +Lote, -Cmd): la siguiente orden de un jugador con plan.
orden_con_plan(Eps, Lote, Cmd) :-
    azar(100, K),
    (   K < Eps                      -> elegir_orden(Cmd)
    ;   orden_planificada(Lote, Cmd) -> true
    ;   elegir_orden(Cmd)
    ).

orden_planificada(_, Cmd) :-
    candidatas(Cs),
    (   once(estado:fase(combate))                       -> elegir_orden(Cmd)
    ;   findall(N, member(_-elegir(N), Cs), Ns), Ns = [_|_] -> nth_azar(Ns, N0), Cmd = elegir(N0)
    ),
    !.
orden_planificada(_, Cmd) :- candidatas(Cs), memberchk(_-pagar, Cs), !, Cmd = pagar.
orden_planificada(Lote, Cmd) :-
    contratos:contratos_activos(K), K < Lote,
    findall(C, ( contratos:contrato(C, _, _, _, _), valida(aceptar(C)) ), Aceptables),
    Aceptables = [_|_], !,
    nth_azar(Aceptables, C0), Cmd = aceptar(C0).
orden_planificada(_, ir(Paso)) :-
    estado:en_zona(Aqui),
    zonas_objetivo(Zs), Zs = [_|_],
    camino_a(Aqui, Zs, [Paso|_]),
    valida(ir(Paso)).

nth_azar(L, E) :- length(L, N), azar(N, I), nth0(I, L, E).

% Adonde ir: al sitio de un contrato abierto; si no hay, a la taberna (a cobrar y a aceptar) o, con tres
% contratos cumplidos, al castillo (el rey no ofrece el jefe sin visita).
zonas_objetivo(Zs) :-
    findall(Z, ( estado:contrato_activo(C), contratos:contrato(C, Z, _, _, _) ), Zs0),
    sort(Zs0, Zs1),
    (   Zs1 \== [] -> Zs = Zs1
    ;   contratos:contratos_cumplidos(N), N >= 3, \+ estado:visitada(castillo) -> Zs = [castillo]
    ;   Zs = [taberna]
    ).

% camino_a(+Desde, +Destinos, -Camino): el camino mas corto (anchura) sin incluir el punto de partida.
camino_a(Desde, Destinos, Camino) :-
    anchura([[Desde]], Destinos, [Desde], Rev), reverse(Rev, [_|Camino]).

anchura([[Z|Resto]|_], Destinos, _, [Z|Resto]) :- memberchk(Z, Destinos), !.
anchura([[Z|Resto]|Cola], Destinos, Vistos, Camino) :-
    findall([V,Z|Resto], ( mundo:adyacente(Z, V), \+ memberchk(V, Vistos) ), Nuevos),
    findall(V, member([V|_], Nuevos), Vs), append(Vistos, Vs, Vistos1),
    append(Cola, Nuevos, Cola1),
    anchura(Cola1, Destinos, Vistos1, Camino).

% resumen_de(+Pasos, -r(Fin, Dia, Queso, Pasos)): Fin = victoria | hambre | combate | sin_final
resumen_de(Pasos, r(Fin, Dia, Queso, Pasos)) :-
    once(estado:dia(Dia)),
    economia:queso_total(Queso),
    (   estado:fin_partida(F) -> clase_de_fin(F, Fin) ; Fin = sin_final ).

clase_de_fin(victoria(_), victoria) :- !.
clase_de_fin(derrota(derrota_hambre), hambre) :- !.
clase_de_fin(derrota(_), combate) :- !.
clase_de_fin(_, otro).

% ---------------------------------------------------------------------------
% Rutas guionizadas: las ordenes, con el combate jugado solo (atacar y, si no se puede, defender)
% ---------------------------------------------------------------------------
% jugar_ruta(+Ordenes, -Resumen): parte de una partida nueva; Resumen es el estado al terminar la lista.
jugar_ruta(Ordenes, Resumen) :-
    estado:nueva_partida,
    forall(member(Cmd, Ordenes), paso_de_ruta(Cmd)),
    length(Ordenes, N),
    resumen_de(N, Resumen).

paso_de_ruta(Cmd) :-
    (   estado:fin_partida(_) -> true
    ;   juego:ejecutar(Cmd, _), combatir_solo
    ).

combatir_solo :-
    (   estado:en_combate(_), \+ estado:fin_partida(_)
    ->  once(orden_de_combate(C)), juego:ejecutar(C, _), combatir_solo
    ;   true
    ).

orden_de_combate(atacar(T)) :- tipo_vivo(T), valida(atacar(T)), !.
orden_de_combate(defender).

% La ruta de un jugador real que perdio el dia 6: los contratos de la aldea UNO POR UNO.
ruta_separada([aceptar(gato_en_el_arbol), ir(aldea), elegir(trepar), ir(taberna),
               aceptar(ratas_del_granero), ir(aldea), ir(taberna), pagar, ir(camino_real)]).

% La ruta de referencia: la campana de examples/ (los cuatro contratos y el jefe). Devuelve su resumen.
ruta_de_referencia(Archivo, Resumen) :-
    main:leer_guion(Archivo, Terminos0),
    exclude(ajena_a_la_ruta, Terminos0, Terminos),
    estado:nueva_partida,
    forall(member(T, Terminos), ( estado:fin_partida(_) -> true ; juego:ejecutar(T, _) )),
    length(Terminos, N),
    resumen_de(N, Resumen).

ajena_a_la_ruta(T) :- memberchk(T, [salir, ayuda, explicar, compania, inventario, contratos, mirar]).
ajena_a_la_ruta(demo(_)).
ajena_a_la_ruta(explicar(_)).

% ---------------------------------------------------------------------------
% El informe: N partidas aleatorias razonables + las rutas de referencia
% ---------------------------------------------------------------------------
informe(N, Semilla) :-
    ruta_de_referencia('examples/campana-comandos.txt', RC),
    ruta_separada(Sep), jugar_ruta(Sep, RS),
    format("REF campana ~q~n", [RC]),
    format("REF separada ~q~n", [RS]),
    forall(member(Pol, [azar, plan(10, 1), plan(10, 2), plan(10, 3)]),
           (   findall(R, ( between(1, N, I), S is Semilla * 1000 + I, episodio(Pol, S, 400, R) ), Rs),
               format("POLITICA ~q~n", [Pol]),
               resumir(Rs, N) )).

resumir(Rs, N) :-
    cuantas(Rs, victoria, V), cuantas(Rs, hambre, H), cuantas(Rs, combate, C), cuantas(Rs, sin_final, X),
    format("PARTIDAS ~w victoria=~w hambre=~w combate=~w sin_final=~w~n", [N, V, H, C, X]),
    findall(D, member(r(victoria, D, _, _), Rs), Dias),
    findall(Q, member(r(victoria, _, Q, _), Rs), Quesos),
    (   Dias = [_|_]
    ->  msort(Dias, DS), msort(Quesos, QS), DS = [DMin|_], last(DS, DMax), QS = [QMin|_], last(QS, QMax),
        media(DS, DMed), media(QS, QMed),
        format("GANADAS dias min=~w media=~1f max=~w ; queso final min=~w media=~1f max=~w~n",
               [DMin, DMed, DMax, QMin, QMed, QMax])
    ;   format("GANADAS ninguna~n", [])
    ).

media(L, M) :- sumlist(L, S), length(L, N), N > 0, M is S / N.

cuantas(Rs, Fin, N) :- findall(x, member(r(Fin, _, _, _), Rs), L), length(L, N).
