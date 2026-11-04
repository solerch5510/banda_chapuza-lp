% compania.pl
% Personajes de la compania, rasgos y moral.
%
% Solo reglas de CONSULTA sobre el estado: nunca modifican nada. Los rasgos con
% regla (teme_caballos...) y el nivel de moral llegan con el combate.

:- module(compania, [miembro/1, vivo/1, activo/1, en_pie/1, esta_en_huelga/1,
                     sueldo_de/2, puede_viajar/1, informe/1]).
:- use_module(mundo).
:- use_module(estado).

% miembro(?Id): pertenece a la compania (en el orden en que entro: el orden de pago).
miembro(Id) :- estado:en_compania(Id).

% vivo(?Id): tiene vida. Vale para personajes y, mas adelante, enemigos.
vivo(Id) :- estado:vida(Id, V), V > 0.

% activo(?Id): miembro y vivo.
activo(Id) :- miembro(Id), vivo(Id).

% en_pie(?Id): activo y no en huelga (los huelguistas no combaten).
en_pie(Id) :- activo(Id), \+ esta_en_huelga(Id).

% esta_en_huelga(+Id): la huelga se deriva solo de la moral (moral =< umbral).
esta_en_huelga(Id) :-
    estado:moral(Id, M),
    mundo:parametro(moral_huelga, Umbral),
    M =< Umbral.

% sueldo_de(+Id, -Sueldo): lo que cobra por cada pago, en quesos (unidades).
sueldo_de(Id, Sueldo) :-
    mundo:personaje(Id, _, _, _, _, _, sueldo(Sueldo)).

% puede_viajar(+Zona): es la regla que se explica en el comando ir(Zona).
% Hay que estar en una zona conectada con Zona y la partida no puede haber terminado.
% (No exige combatientes: asi nunca hay un bloqueo sin salida.)
puede_viajar(Zona) :-
    estado:en_zona(Actual),
    mundo:adyacente(Actual, Zona),
    \+ estado:fin_partida(_).

% informe(-Filas): una ficha por miembro, para el comando compania.
% Estado = caido (sin vida), huelga (moral baja) o en_pie.
informe(Filas) :-
    findall(Ficha, ( miembro(Id), ficha(Id, Ficha) ), Filas).

ficha(Id, miembro(Id, Nombre, Rol, Vida, VidaMax, Ataque, Defensa, Moral, Fila, Rasgo, Sueldo, Estado)) :-
    mundo:personaje(Id, Nombre, Rol, vida(VidaMax), ataque(Ataque), defensa(Defensa), sueldo(Sueldo)),
    estado:vida(Id, Vida),
    estado:moral(Id, Moral),
    estado:fila(Id, Fila),
    mundo:rasgo(Id, Rasgo),
    estado_de(Id, Estado).

estado_de(Id, Estado) :-
    (   \+ vivo(Id)         -> Estado = caido
    ;   esta_en_huelga(Id)  -> Estado = huelga
    ;   Estado = en_pie
    ).
