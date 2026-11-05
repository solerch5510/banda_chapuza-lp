% combate.pl
% Turnos, filas, calculo de dano e IA enemiga.
%
% Solo REGLAS puras: consultan el estado y deciden, pero nunca lo modifican (los efectos
% los aplica estado.pl). Por ahora, lo que hace falta para los rasgos del heroe:
%   - puede_atacar/2: la regla de la primera demostracion de explicar (el miedo de Baldomero);
%   - en_fila_alcanzable/2: las reglas de fila de las que depende;
%   - puede_habilidad/2: el rasgo hechizos_de_cocina de Pimentina.
% Y el orden de los turnos:
%   - iniciativa/2 y orden_turnos/1: quien actua primero en cada ronda;
%   - efectos_inicio/2 y efectos_ronda/1: los efectos que abren el combate y cada ronda.
% El resto del combate (dano, acciones, IA) llega en las tareas siguientes.

:- module(combate, [puede_atacar/2, en_fila_alcanzable/2, aturdido/1,
                    puede_habilidad/2, tipo_de/2, clase_de/2,
                    ataque_base/2, defensa_base/2, puede_actuar/1,
                    iniciativa/2, orden_turnos/1,
                    efectos_inicio/2, efectos_ronda/1]).
:- use_module(mundo).
:- use_module(estado).
:- use_module(compania).
:- use_module(economia).

% ---------------------------------------------------------------------------
% Identificadores de combatiente: un miembro es su atomo (baldomero); un enemigo es una
% instancia e(Tipo, N) (e(bandido_torpe, 1)). Los datos del catalogo son del TIPO.
% ---------------------------------------------------------------------------
% tipo_de(+Id, -Tipo): el tipo de un enemigo; un miembro es su propio "tipo".
tipo_de(Id, Tipo) :-
    (   nonvar(Id), Id = e(T, _) -> Tipo = T ; Tipo = Id ).

% clase_de(+Id, -Clase): la clase de criatura (roedor, humano, caballo...).
clase_de(Id, Clase) :-
    tipo_de(Id, Tipo),
    mundo:clase(Tipo, Clase).

% aturdido(+Id): un estado alterado (se escribe como derivado, nunca como estado/2).
aturdido(Id) :-
    estado:alterado(Id, aturdido, _).

% ---------------------------------------------------------------------------
% Atacar. Es la regla de la primera demostracion de explicar/por_que_no:
%   por_que_no(atacar(baldomero, bandido_montado)): Baldomero teme a los caballos.
% ---------------------------------------------------------------------------
puede_atacar(A, B) :-
    compania:vivo(A),
    compania:vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( compania:teme(A, Clase), clase_de(B, Clase) ).

% Los de retaguardia solo pueden ser atacados cuando el frente cae, salvo ataques a distancia.
en_fila_alcanzable(A, B) :-
    bando_contrario(A, B),
    (   estado:fila(B, frente)
    ;   \+ frente_con_vivos(B)
    ;   ataca_a_distancia(A)
    ).

bando_contrario(A, B) :-
    estado:combatiente(A, BandoA),
    estado:combatiente(B, BandoB),
    BandoA \== BandoB.

% frente_con_vivos(+B): el bando de B todavia tiene a alguien vivo en primera fila.
frente_con_vivos(B) :-
    estado:combatiente(B, Bando),
    estado:combatiente(F, Bando),
    estado:fila(F, frente),
    compania:vivo(F).

ataca_a_distancia(A) :-
    tipo_de(A, Tipo),
    mundo:alcance(Tipo, distancia).

% ---------------------------------------------------------------------------
% Atributos base (los del catalogo, sin rasgos ni moral; los efectivos llegan con el dano).
% ---------------------------------------------------------------------------
ataque_base(Id, A) :-
    mundo:personaje(Id, _, _, _, ataque(A), _, _).
ataque_base(Id, A) :-
    tipo_de(Id, Tipo),
    mundo:enemigo(Tipo, _, ataque(A), _).

defensa_base(Id, D) :-
    mundo:personaje(Id, _, _, _, _, defensa(D), _).
defensa_base(Id, D) :-
    tipo_de(Id, Tipo),
    mundo:enemigo(Tipo, _, _, defensa(D)).

% puede_actuar(+Id): esta vivo y no esta en huelga (un enemigo no tiene moral: nunca hace huelga).
puede_actuar(Id) :-
    compania:vivo(Id),
    \+ compania:esta_en_huelga(Id).

% ---------------------------------------------------------------------------
% Iniciativa: I = base + ataque - defensa + moral (la moral solo cuenta en los miembros).
% Los mas rapidos actuan antes: un guerrero fuerte y poco protegido llega primero.
% ---------------------------------------------------------------------------
iniciativa(Id, I) :-
    ataque_base(Id, A),
    defensa_base(Id, D),
    bono_iniciativa(Id, M),
    mundo:parametro(base_iniciativa, B),
    I is B + A - D + M.

bono_iniciativa(Id, M) :- compania:miembro(Id), compania:modificador_moral(Id, M).
bono_iniciativa(Id, 0) :- \+ compania:miembro(Id).

% orden_turnos(-Ids): los que pueden actuar, de mayor a menor iniciativa. Si empatan, el jugador
% actua primero y, entre iguales, manda el orden estandar de los identificadores: el orden es
% siempre el mismo para el mismo estado. (K = -I porque msort ordena de menor a mayor.)
orden_turnos(Ids) :-
    findall(K-P-Id,
            (   estado:combatiente(Id, Bando),
                puede_actuar(Id),
                iniciativa(Id, I),
                K is -I,
                prioridad_bando(Bando, P)
            ),
            Pares),
    msort(Pares, Ordenados),
    ids_de(Ordenados, Ids).

prioridad_bando(jugador, 0).
prioridad_bando(enemigo, 1).

ids_de([], []).
ids_de([_-_-Id|Pares], [Id|Ids]) :- ids_de(Pares, Ids).

% ---------------------------------------------------------------------------
% Efectos que abren el combate y cada ronda (se devuelven como datos; los aplica estado).
% ---------------------------------------------------------------------------
% efectos_inicio(+Grupo, -Efectos): empieza un combate contra Grupo (lista de tipos de enemigo).
% Falla si ya hay un combate o si el grupo esta vacio o tiene un tipo desconocido.
efectos_inicio(Grupo, [iniciar_combate(Grupo)]) :-
    \+ estado:en_combate(_),
    ground(Grupo), Grupo = [_|_],
    \+ ( member(Tipo, Grupo), \+ mundo:enemigo(Tipo, _, _, _) ).

% efectos_ronda(-Efectos): con la cola vacia empieza la ronda siguiente, con el orden recalculado
% (alguien puede haber caido o entrado en huelga).
efectos_ronda([siguiente_ronda(Orden)]) :-
    estado:en_combate(_),
    estado:cola_turnos([]),
    orden_turnos(Orden).

% ---------------------------------------------------------------------------
% Rasgo hechizos_de_cocina (Pimentina): "toda magia necesita queso". Cada hechizo gasta
% quesos de la despensa; sin queso suficiente no se puede lanzar.
% puede_habilidad(+Id, +Habilidad)
% ---------------------------------------------------------------------------
puede_habilidad(Id, Habilidad) :-
    mundo:rasgo(Id, hechizos_de_cocina),
    mundo:habilidad_de(Id, Habilidad),
    compania:vivo(Id),
    \+ aturdido(Id),
    mundo:coste_queso(Habilidad, Coste),
    economia:hay_queso_para(Coste).
