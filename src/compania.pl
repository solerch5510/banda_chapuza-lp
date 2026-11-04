% compania.pl
% Personajes de la compania, rasgos y moral.
%
% Solo reglas de CONSULTA sobre el estado: nunca modifican nada. Por ahora lo
% minimo que necesitan los comandos de exploracion (ir, descansar, mirar); los
% rasgos, el nivel de moral y el resto llegan con las tareas de la compania.

:- module(compania, [miembro/1, vivo/1, activo/1, esta_en_huelga/1, puede_viajar/1]).
:- use_module(mundo).
:- use_module(estado).

% miembro(?Id): pertenece a la compania (en el orden en que entro: el orden de pago).
miembro(Id) :- estado:en_compania(Id).

% vivo(?Id): tiene vida. Vale para personajes y, mas adelante, enemigos.
vivo(Id) :- estado:vida(Id, V), V > 0.

% activo(?Id): miembro y vivo.
activo(Id) :- miembro(Id), vivo(Id).

% esta_en_huelga(+Id): la huelga se deriva solo de la moral (moral =< umbral).
esta_en_huelga(Id) :-
    estado:moral(Id, M),
    mundo:parametro(moral_huelga, Umbral),
    M =< Umbral.

% puede_viajar(+Zona): es la regla que se explica en el comando ir(Zona).
% Hay que estar en una zona conectada con Zona y la partida no puede haber terminado.
% (No exige combatientes: asi nunca hay un bloqueo sin salida.)
puede_viajar(Zona) :-
    estado:en_zona(Actual),
    mundo:adyacente(Actual, Zona),
    \+ estado:fin_partida(_).
