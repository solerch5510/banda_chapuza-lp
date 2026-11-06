% contratos.pl
% Contratos y las reglas que los gobiernan.
%
% Los contratos son DATOS (contrato/5, la forma del canon) y lo que se puede hacer con ellos son
% REGLAS puras que consultan el estado y nunca lo modifican. En esta etapa: el catalogo de la
% version minima (cuatro contratos), saber cuales hay a la vista, cuales se pueden aceptar y por
% que no (puede_aceptar/1 es la regla que explica el modo explicar).
% El resultado (exito, a medias, fracaso) y el cobro llegan despues.

:- module(contratos, [contrato/5, oferente/3, aparece/2, enemigos_de/2, resolucion/3,
                      via_objetivo/2, expandir_grupo/2,
                      visible/1, disponible/1, puede_aceptar/1, condicion_cumple/1,
                      contrato_cumplido/1, contrato_exito/1, contratos_cumplidos/1,
                      contratos_activos/1, estado_de_contrato/2, ficha/2]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).

% ---------------------------------------------------------------------------
% El catalogo (docs/04 §3). contrato(Id, Zona, Objetivo, recompensa(Lista), Condiciones):
% Zona es donde se cumple el objetivo; las condiciones son las de ACEPTAR.
% Recompensa: quesos(N) = N cheddar frescos, queso(Tipo, Edad, N), objeto(Id).
% ---------------------------------------------------------------------------
contrato(ratas_del_granero, aldea, eliminar([rata_quesera-2]),
         recompensa([quesos(9), objeto(pocion)]), []).
contrato(gato_en_el_arbol, aldea, evento(rescate_gato),
         recompensa([quesos(7), objeto(venda_de_caballos)]), []).
contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo),
         recompensa([quesos(14), queso(brie, 0, 1)]),
         [requiere(rasgo_no(teme_caballos))]).
contrato(despensa_real, cuevas, derrotar(gran_roquefort),
         recompensa([quesos(40)]),
         [requiere(contratos_cumplidos_min(3)), requiere(visita(castillo)),
          requiere(moral_media_min(4)), requiere(miembros_en_pie_min(3))]).

% oferente(Contrato, Npc, ZonaDelNpc): quien lo ofrece y donde esta.
oferente(ratas_del_granero, alcaldesa_nata, aldea).
oferente(gato_en_el_arbol,  alcaldesa_nata, aldea).
oferente(gallina_noble,     gallina_noble,  camino_real).
oferente(despensa_real,     rey_brieto,     castillo).

% aparece(Contrato, Condiciones): cuando se ve en el tablon (son del mismo vocabulario).
aparece(ratas_del_granero, []).
aparece(gato_en_el_arbol,  []).
aparece(gallina_noble,     []).                      % visible el dia 1, pero bloqueado sin la venda
aparece(despensa_real,     [requiere(visita(castillo))]).

% enemigos_de(Contrato, Grupo): los enemigos de los contratos cuyo objetivo es escoltar.
enemigos_de(gallina_noble, [bandido_torpe, bandido_torpe, bandido_montado]).

% resolucion(Contrato, Resultado, Condiciones): como se decide el resultado; se prueban en este
% orden. contador_max(C, N): el contador C no pasa de N; marca(M): consta la marca M.
% (La regla que las usa, resultado/3, llega con el cierre de los contratos.)
resolucion(ratas_del_granero, exito,    [contador_max(quesos_robados, 3)]).
resolucion(ratas_del_granero, a_medias, []).
resolucion(gato_en_el_arbol,  exito,    [marca(gato_bajado_con_arte)]).
resolucion(gato_en_el_arbol,  a_medias, [marca(gato_bajado_a_golpes)]).
resolucion(gato_en_el_arbol,  fracaso,  []).
resolucion(gallina_noble,     exito,    [contador_max(golpes_a_clotilde, 2)]).
resolucion(gallina_noble,     a_medias, [contador_max(golpes_a_clotilde, 4)]).
resolucion(gallina_noble,     fracaso,  []).
resolucion(despensa_real,     exito,    []).

% ---------------------------------------------------------------------------
% Como se cumple el objetivo: en un combate o en un evento (vocabulario cerrado de docs/04 §3.1).
% ---------------------------------------------------------------------------
via_objetivo(C, combate(Grupo)) :-
    contrato(C, _, eliminar(Pares), _, _),
    expandir_grupo(Pares, Grupo).
via_objetivo(C, combate([Tipo])) :-
    contrato(C, _, derrotar(Tipo), _, _).
via_objetivo(C, combate(Grupo)) :-
    contrato(C, _, escoltar(_, _), _, _),
    enemigos_de(C, Grupo).
via_objetivo(C, evento(E)) :-
    contrato(C, _, evento(E), _, _).

% expandir_grupo(+Pares, -Grupo): [rata_quesera-2, bandido_torpe-1] -> [rata_quesera, rata_quesera, bandido_torpe]
expandir_grupo([], []).
expandir_grupo([Tipo-N|Pares], Grupo) :-
    findall(Tipo, between(1, N, _), Repetidos),
    expandir_grupo(Pares, Resto),
    append(Repetidos, Resto, Grupo).

% ---------------------------------------------------------------------------
% Que contratos hay a la vista y cuales se pueden aceptar.
% ---------------------------------------------------------------------------
% visible(?C): ya aparece en el tablon (sus condiciones de aparicion se cumplen).
visible(C) :-
    contrato(C, _, _, _, _),
    aparece(C, Visibilidad),
    cumple_todas(Visibilidad).

% disponible(?C): se ve, y estas donde se puede aceptar: en la taberna (el tablon) o en la zona
% de quien lo ofrece.
disponible(C) :-
    visible(C),
    oferente(C, _, ZonaDelOferente),
    (   estado:en_zona(taberna)
    ;   estado:en_zona(ZonaDelOferente)
    ).

% puede_aceptar(+C): la regla que explica `aceptar`. Disponible, sin cumplir ni tener ya, con
% hueco entre los activos (maximo 3) y todas sus condiciones cumplidas.
puede_aceptar(C) :-
    disponible(C),
    \+ contrato_cumplido(C),
    \+ estado:contrato_activo(C),
    contratos_activos(K),
    mundo:parametro(max_contratos, Max),
    K < Max,
    contrato(C, _, _, _, Condiciones),
    cumple_todas(Condiciones).

% Las condiciones se recorren con recursion (no con forall/2), asi el meta-interprete las abre.
cumple_todas([]).
cumple_todas([requiere(X)|Resto]) :-
    condicion_cumple(X),
    cumple_todas(Resto).

% condicion_cumple(+Condicion): el vocabulario de condiciones (docs/04 §3.1).
% rasgo_no(R): ningun miembro activo tiene el rasgo R sin ignorar su efecto (la venda de caballos
% hace que Baldomero ignore el miedo). No mira a los enemigos del contrato.
condicion_cumple(rasgo_no(R)) :-
    \+ ( compania:activo(M), mundo:rasgo(M, R), \+ compania:ignora_miedo(M) ).
condicion_cumple(contratos_cumplidos_min(N)) :-
    contratos_cumplidos(K),
    K >= N.
condicion_cumple(moral_media_min(N)) :-
    compania:moral_media(M),
    M >= N.
condicion_cumple(visita(Z)) :-
    estado:visitada(Z).
condicion_cumple(miembros_en_pie_min(N)) :-
    findall(P, compania:en_pie(P), Ps),
    length(Ps, K),
    K >= N.

% ---------------------------------------------------------------------------
% Derivados del estado: cumplido = resuelto con exito o a medias, este o no cobrado.
% ---------------------------------------------------------------------------
contrato_cumplido(C) :-
    estado:contrato_por_cobrar(C, R),
    R \== fracaso.
contrato_cumplido(C) :-
    estado:contrato_cerrado(C, R),
    R \== fracaso.

contrato_exito(C) :-
    estado:contrato_por_cobrar(C, exito).
contrato_exito(C) :-
    estado:contrato_cerrado(C, exito).

contratos_cumplidos(N) :-
    findall(C, contrato_cumplido(C), Cs),
    length(Cs, N).

contratos_activos(N) :-
    findall(C, estado:contrato_activo(C), Cs),
    length(Cs, N).

% ---------------------------------------------------------------------------
% Para el tablon (comando contratos): el estado de cada contrato a la vista.
%   activo     ya lo tienes aceptado
%   cumplido   ya lo resolviste (bien o a medias)
%   disponible se puede aceptar ahora
%   lejos      habria que ir a donde esta quien lo ofrece
%   bloqueado  alguna condicion o el limite lo impiden
% ---------------------------------------------------------------------------
estado_de_contrato(C, Estado) :-
    visible(C),
    (   estado:contrato_activo(C)  ->  Estado = activo
    ;   contrato_cumplido(C)       ->  Estado = cumplido
    ;   puede_aceptar(C)           ->  Estado = disponible
    ;   \+ disponible(C)           ->  Estado = lejos
    ;   Estado = bloqueado
    ).

% ficha(?C, -Ficha): lo que el tablon enseña de cada contrato.
ficha(C, contrato(C, Zona, Dificultad, Recompensa, Estado)) :-
    estado_de_contrato(C, Estado),
    contrato(C, Zona, _, recompensa(Recompensa), _),
    dificultad(C, Dificultad).

dificultad(ratas_del_granero, 1).
dificultad(gato_en_el_arbol,  1).
dificultad(gallina_noble,     3).
dificultad(despensa_real,     5).
