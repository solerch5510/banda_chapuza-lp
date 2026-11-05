% combate.pl
% Turnos, filas, calculo de dano e IA enemiga.
%
% Solo REGLAS puras: consultan el estado y deciden, pero nunca lo modifican (los efectos
% los aplica estado.pl). Por ahora, lo que hace falta para los rasgos del heroe:
%   - puede_atacar/2: la regla de la primera demostracion de explicar (el miedo de Baldomero);
%   - en_fila_alcanzable/2: las reglas de fila de las que depende;
%   - puede_habilidad/2: el rasgo hechizos_de_cocina de Pimentina.
% El resto del combate (iniciativa, dano, turnos, IA) llega en las tareas siguientes.

:- module(combate, [puede_atacar/2, en_fila_alcanzable/2, aturdido/1,
                    puede_habilidad/2, tipo_de/2, clase_de/2]).
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
