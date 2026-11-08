% contratos.pl
% Contratos y las reglas que los gobiernan.
%
% Los contratos son DATOS (contrato/5, la forma del canon) y lo que se puede hacer con ellos son
% REGLAS puras que consultan el estado y nunca lo modifican. En esta etapa: el catalogo de la
% version minima (cuatro contratos), saber cuales hay a la vista, cuales se pueden aceptar y por
% que no (puede_aceptar/1 es la regla que explica el modo explicar).
% Y como acaban: el resultado (exito, a medias o fracaso) con resultado/3, sus consecuencias y el
% cobro de la recompensa, que es automatico al llegar a la taberna.

:- module(contratos, [contrato/5, oferente/3, aparece/2, enemigos_de/2, resolucion/3,
                      via_objetivo/2, expandir_grupo/2,
                      visible/1, disponible/1, puede_aceptar/1, condicion_cumple/1,
                      contrato_cumplido/1, contrato_exito/1, contratos_cumplidos/1,
                      contratos_activos/1, estado_de_contrato/2, ficha/2,
                      consecuencia/3, contadores_de/2, contexto/1, resultado/3,
                      objetivo_pendiente/3, efectos_inicio_objetivo/2,
                      efectos_resolucion/3, efectos_cobro/1, efectos_cobro_de/3,
                      orden_finales/1, final/2, final_de_la_partida/1]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

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
%   por_cobrar resuelto, a la espera de cobrar al llegar a la taberna
%   cumplido   ya lo resolviste y lo cobraste (bien o a medias)
%   disponible se puede aceptar ahora
%   lejos      habria que ir a donde esta quien lo ofrece
%   bloqueado  alguna condicion o el limite lo impiden
% ---------------------------------------------------------------------------
estado_de_contrato(C, Estado) :-
    visible(C),
    (   estado:contrato_activo(C)  ->  Estado = activo
    ;   estado:contrato_por_cobrar(C, _) -> Estado = por_cobrar
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


% ---------------------------------------------------------------------------
% Como acaba un contrato. Tres pasos:
%   1. el objetivo EMPIEZA (al llegar a su zona con el contrato activo: un combate);
%   2. se RESUELVE (resultado/3 decide exito, a medias o fracaso con los contadores y marcas);
%      las consecuencias inmediatas (moral, marcas, quesos perdidos) se aplican en el acto;
%   3. se COBRA al llegar a la taberna (la recompensa y los objetos que se equipan solos).
% Todo son reglas puras: devuelven listas de efectos y no tocan el estado.
% ---------------------------------------------------------------------------

% consecuencia(Contrato, Resultado, Efectos04): que pasa con cada resultado (docs/04 §3).
%   cobrar(todo|mitad|quesos(N)|objetos), moral(grupo|Id, N), marcar(F), perder_queso(N), equipar(Id, O)
consecuencia(ratas_del_granero, exito,    [cobrar(todo), moral(grupo, 1)]).
consecuencia(ratas_del_granero, a_medias, [cobrar(quesos(5)), cobrar(objetos)]).
consecuencia(gato_en_el_arbol,  exito,    [cobrar(todo), moral(grupo, 1), equipar(baldomero, venda_de_caballos)]).
consecuencia(gato_en_el_arbol,  a_medias, [cobrar(quesos(5)), cobrar(objetos), perder_queso(1),
                                           equipar(baldomero, venda_de_caballos)]).
consecuencia(gato_en_el_arbol,  fracaso,  [moral(grupo, -1)]).
consecuencia(gallina_noble,     exito,    [cobrar(todo), moral(grupo, 1), marcar(recomendada_por_clotilde)]).
consecuencia(gallina_noble,     a_medias, [cobrar(mitad), marcar(recomendada_por_clotilde)]).
consecuencia(gallina_noble,     fracaso,  [perder_queso(3), moral(grupo, -2)]).
consecuencia(despensa_real,     exito,    [cobrar(todo), victoria]).    % ganar el jefe es ganar la partida

% --- los finales de victoria (docs/04 §8.4) ---
% orden_finales(Ids): se evaluan en este orden y gana el primero cuyas condiciones se cumplen.
% La version minima solo tiene chapuza, el final por defecto (sin condiciones).
orden_finales([chapuza]).
final(chapuza, []).

% final_de_la_partida(-Id): el final que toca con el estado de ahora.
final_de_la_partida(Id) :-
    orden_finales(Ids),
    primer_final(Ids, Id).

primer_final([Id|_], Id) :-
    final(Id, Condiciones),
    cumple_todas(Condiciones).
primer_final([Id|Resto], Final) :-
    final(Id, Condiciones),
    \+ cumple_todas(Condiciones),
    primer_final(Resto, Final).

% contadores_de(Contrato, Claves): los contadores que cuenta su objetivo (se ponen a cero al empezar).
contadores_de(ratas_del_granero, [quesos_robados]).
contadores_de(gallina_noble,     [golpes_a_clotilde]).

% --- el resultado ---
% contexto(-Ctx): lo registrado durante el contrato, como lista de contador(Clave, N) y marca(M).
contexto(Ctx) :-
    findall(contador(K, V), estado:contador(K, V), Contadores),
    findall(marca(M), estado:marca(M), Marcas),
    append(Contadores, Marcas, Ctx).

% resultado(+C, +Ctx, -Res): el PRIMER resultado de resolucion/3 cuyas condiciones se cumplen. Regla
% pura y sin corte: si el primero no se cumple, se mira el siguiente.
resultado(C, Ctx, Res) :-
    findall(R-Cs, resolucion(C, R, Cs), Lista),
    primero_que_cumple(Lista, Ctx, Res).

primero_que_cumple([R-Cs|_], Ctx, R) :-
    cumple_resolucion(Cs, Ctx).
primero_que_cumple([_-Cs|Resto], Ctx, R) :-
    \+ cumple_resolucion(Cs, Ctx),
    primero_que_cumple(Resto, Ctx, R).

cumple_resolucion([], _).
cumple_resolucion([Cond|Resto], Ctx) :-
    condicion_resolucion(Cond, Ctx),
    cumple_resolucion(Resto, Ctx).

% contador_max(K, N): el contador K (0 si no consta) no pasa de N. marca(M): consta la marca M.
condicion_resolucion(contador_max(K, N), Ctx) :-
    valor_contador(K, Ctx, V),
    V =< N.
condicion_resolucion(marca(M), Ctx) :-
    memberchk(marca(M), Ctx).

valor_contador(K, Ctx, V) :-
    (   memberchk(contador(K, V0), Ctx) -> V = V0 ; V = 0 ).

% --- empezar el objetivo ---
% objetivo_pendiente(+Zona, -C, -Grupo): un contrato activo cuyo objetivo es un combate en esta zona
% y que aun no ha empezado. (Si hay varios, el primero del catalogo.)
objetivo_pendiente(Zona, C, Grupo) :-
    contrato(C, Zona, _, _, _),
    estado:contrato_activo(C),
    \+ estado:marca(combate_de(C)),
    via_objetivo(C, combate(Grupo)).

% efectos_inicio_objetivo(+C, -Efectos): marca el combate como suyo y pone a cero sus contadores.
efectos_inicio_objetivo(C, Efectos) :-
    (   contadores_de(C, Claves) -> true ; Claves = [] ),
    findall(borrar_contador(K), member(K, Claves), Borrados),
    append(Borrados, [marcar(combate_de(C)), mensaje(objetivo, [C])], Efectos).

% --- resolver ---
% efectos_resolucion(+C, +Res, -Efectos): el contrato deja de estar activo, se quita la marca de su
% combate y se aplican ya las consecuencias que no son cobrar ni equipar.
efectos_resolucion(C, Res, Efectos) :-
    consecuencia(C, Res, Efectos04),
    inmediatos(Efectos04, Inmediatos),
    expandir_todos(C, Inmediatos, Traducidos),
    append([[contrato_resolver(C, Res), desmarcar(combate_de(C)), mensaje(contrato_resuelto, [C, Res])],
            Traducidos], Efectos).

% --- cobrar ---
% efectos_cobro(-Efectos): el cobro automatico de TODOS los contratos por cobrar, en orden de catalogo.
efectos_cobro(Efectos) :-
    findall(Efs,
            (   contrato(C, _, _, _, _),
                estado:contrato_por_cobrar(C, R),
                efectos_cobro_de(C, R, Efs)
            ),
            Listas),
    append(Listas, Efectos).

% efectos_cobro_de(+C, +Res, -Efectos): la recompensa y lo que se equipa, mas pasarlo a cerrado.
efectos_cobro_de(C, Res, Efectos) :-
    consecuencia(C, Res, Efectos04),
    diferidos(Efectos04, Diferidos),
    expandir_todos(C, Diferidos, Traducidos),
    append(Traducidos, [contrato_cobrar(C), mensaje(cobra, [C])], Efectos).

% Lo que se cobra (cobrar/1) o se entrega (equipar/2) espera a la taberna; lo demas es inmediato.
inmediatos([], []).
inmediatos([E|Es], Is) :-
    (   diferido(E) -> Is = Is1 ; Is = [E|Is1] ),
    inmediatos(Es, Is1).

diferidos([], []).
diferidos([E|Es], Ds) :-
    (   diferido(E) -> Ds = [E|Ds1] ; Ds = Ds1 ),
    diferidos(Es, Ds1).

diferido(cobrar(_)).
diferido(equipar(_, _)).

expandir_todos(_, [], []).
expandir_todos(C, [E|Es], Efectos) :-
    expandir(C, E, Efs1),
    expandir_todos(C, Es, Efs2),
    append(Efs1, Efs2, Efectos).

% expandir(+C, +Efecto04, -Efectos): traduce un termino de docs/04 a efectos de estado.
expandir(C, cobrar(todo),  Efs) :- premios_como_efectos(C, todo, Efs).
expandir(C, cobrar(mitad), Efs) :- premios_como_efectos(C, mitad, Efs).
expandir(_, cobrar(quesos(N)), [ganar_queso(cheddar, 0, N)]).
expandir(C, cobrar(objetos), Efs) :-
    contrato(C, _, _, recompensa(Premios), _),
    findall(ganar_objeto(compania, O, 1), member(objeto(O), Premios), Efs).
expandir(_, equipar(Id, O), [equipar(Id, O)]).
expandir(_, moral(grupo, N), Efs) :-
    findall(mod_moral(Id, N), compania:activo(Id), Efs).
expandir(_, moral(Id, N), [mod_moral(Id, N)]) :-
    Id \== grupo.
expandir(_, marcar(F), [marcar(F)]).
% victoria: la partida se gana con el final que corresponda al estado de ahora.
expandir(_, victoria, [fin(victoria(Final)), mensaje(final, [Final])]) :-
    final_de_la_partida(Final).
expandir(_, perder_queso(N), Efs) :-
    economia:efectos_perdida(N, Efs).

% premios_como_efectos(+C, +Modo, -Efectos): la recompensa entera (todo) o la mitad de los quesos (mitad).
premios_como_efectos(C, Modo, Efectos) :-
    contrato(C, _, _, recompensa(Premios), _),
    findall(E, ( member(P, Premios), premio_efecto(Modo, P, E) ), Efectos).

premio_efecto(todo, quesos(N), ganar_queso(cheddar, 0, N)).
premio_efecto(todo, queso(T, E, N), ganar_queso(T, E, N)).
premio_efecto(todo, objeto(O), ganar_objeto(compania, O, 1)).
premio_efecto(mitad, quesos(N), ganar_queso(cheddar, 0, M)) :-
    M is N // 2, M > 0.
premio_efecto(mitad, queso(T, E, N), ganar_queso(T, E, M)) :-
    M is N // 2, M > 0.
