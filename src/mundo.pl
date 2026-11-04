% mundo.pl
% Zonas, conexiones y hechos estaticos del mundo.
%
% Solo datos y reglas de consulta sobre ellos: este modulo no depende de ningun
% otro (es la capa mas baja) y nunca cambia. El estado que cambia vive en estado.pl.
% Los identificadores son los de docs/01-lore-y-ambientacion.md (seccion 10).

:- module(mundo, [zona/2, descripcion_zona/2, conexion/2, adyacente/2, zona_pacifica/1,
                  personaje/7, fila_preferida/2, rasgo/2,
                  tipo_queso/2, parametro/2, inicio/1]).

% La declaracion de modulo va PRIMERO; el archivo tiene tildes, asi que se declara UTF-8 justo despues.
:- encoding(utf8).

% ---------------------------------------------------------------------------
% Zonas: zona(Id, NombreVisible)
% ---------------------------------------------------------------------------
zona(taberna,     'Taberna del Cuajo Torcido').
zona(aldea,       'Aldea Requesón').
zona(bosque,      'Bosque del Moho').
zona(camino_real, 'Camino Real').
zona(castillo,    'Castillo Camembert').
zona(cuevas,      'Cuevas del Roquefort').

% descripcion_zona(Id, Texto): lo que ve el jugador al llegar o al mirar.
descripcion_zona(taberna,
    'El Cuajo Torcido huele a sopa de ayer, a sudor de mercenario y a una promesa de pago que nadie ha visto cumplida. La puerta cuelga de una sola bisagra, que según Doña Mantecosa "le da carácter". Aquí se cobra, se firma y se duerme en camas que han visto cosas.').
descripcion_zona(aldea,
    'Casitas blancas y blandas, tan pacíficas que el arma más peligrosa del pueblo es un rodillo. Todo huele a leche tibia y a vecinos preguntándote cuándo les pagas. Aquí se cobran favores pequeños y se descubre que "gato en el árbol" es un género literario.').
descripcion_zona(bosque,
    'Un bosque donde hasta la sombra tiene pelusilla. Los troncos están forrados de moho verde y las setas opinan sobre tu forma de caminar. Al fondo, algo hace "plop" y prefieres no saber qué.').
descripcion_zona(camino_real,
    'Un camino empedrado con corteza de queso viejo que se pega a las botas, con un peaje cada cien pasos. Lo recorren carretas, gansos con permiso de cobro y bandidos con más ambición que puntería.').
descripcion_zona(castillo,
    'Una fortaleza blanca y cremosa que, según los lugareños, se hunde un poquito cada año. Los guardias de corteza saludan con una rigidez ejemplar y el rey recibe en una sala tan perfumada que los cortesanos van con la nariz tapada por educación.').
descripcion_zona(cuevas,
    'Cavernas azules y húmedas, con vetas de moho como mármol en mal estado. El aire sabe a sótano y a decisiones tomadas hace cuarenta años. Algo ahí abajo ha madurado demasiado.').

% ---------------------------------------------------------------------------
% Mapa: conexion(A, B) se escribe en UN solo sentido; adyacente/2 la hace simetrica.
%
%   taberna -- camino_real -- cuevas
%      |            |  \
%    aldea ------ bosque    (camino_real -- castillo)
% ---------------------------------------------------------------------------
conexion(taberna,     aldea).
conexion(taberna,     camino_real).
conexion(aldea,       bosque).
conexion(bosque,      camino_real).
conexion(camino_real, castillo).
conexion(camino_real, cuevas).

adyacente(A, B) :- conexion(A, B).
adyacente(A, B) :- conexion(B, A).

% Zonas donde la ley prohibe el combate (la consulta combate:permite_combate/1).
zona_pacifica(taberna).

% ---------------------------------------------------------------------------
% Compania: personaje(Id, Nombre, Rol, vida(V), ataque(A), defensa(D), sueldo(S))
% ---------------------------------------------------------------------------
personaje(baldomero, 'Sir Baldomero',    caballero, vida(30), ataque(11), defensa(3), sueldo(1)).
personaje(pimentina, 'Madame Pimentina', maga,      vida(18), ataque(6),  defensa(1), sueldo(2)).
personaje(rufino,    'Rufino',           bardo,     vida(20), ataque(4),  defensa(2), sueldo(1)).
personaje(tuerca,    'Tuerca',           ladron,    vida(22), ataque(7),  defensa(2), sueldo(1)).

fila_preferida(baldomero, frente).
fila_preferida(pimentina, retaguardia).
fila_preferida(rufino,    retaguardia).
fila_preferida(tuerca,    frente).

rasgo(baldomero, teme_caballos).
rasgo(pimentina, hechizos_de_cocina).
rasgo(rufino,    cobra_por_callar).
rasgo(tuerca,    manos_largas).

% ---------------------------------------------------------------------------
% Quesos que existen: tipo_queso(Tipo, ValorBase). El valor SOLO informa: sueldos,
% recompensas y multas se cuentan por unidades, no por valor.
% ---------------------------------------------------------------------------
tipo_queso(cheddar, 2).
tipo_queso(brie,    3).

% ---------------------------------------------------------------------------
% Constantes de balance: parametro(Nombre, Valor). Las reglas las leen de aqui,
% asi ningun numero "magico" queda escondido en el codigo.
% ---------------------------------------------------------------------------
parametro(edad_curado_min,   3).    % de 3 dias en adelante el queso esta curado
parametro(edad_rancio_min,  10).    % de 10 dias en adelante esta rancio
parametro(moral_inicial,     6).    % moral 0-10 (decision D-08)
parametro(moral_max,        10).
parametro(moral_huelga,      2).    % huelga si la moral es 2 o menos
parametro(racion_por_miembro, 1).   % quesos que come cada miembro al dia
parametro(coste_descanso,    2).    % quesos que cuesta descansar en la taberna (D-15)
parametro(moral_impago,      2).    % moral que pierde cada miembro si se sale sin pagar
parametro(moral_hambre,      1).    % moral que pierde quien se queda sin comer (provisional)
parametro(dano_hambre,       2).    % vida que pierde quien se queda sin comer; nunca baja de 1 (provisional)
parametro(moral_rancio,      2).    % moral que pierde quien come queso rancio (lore 7.1)

% ---------------------------------------------------------------------------
% Valores iniciales de la partida: inicio(Dato)
% ---------------------------------------------------------------------------
inicio(zona(taberna)).
inicio(dia(1)).
inicio(miembro(baldomero)).
inicio(miembro(pimentina)).
inicio(miembro(rufino)).
inicio(miembro(tuerca)).
inicio(queso(cheddar, 0, 12)).      % 12 cheddar de edad 0 (decision D-09)
inicio(semilla(12345)).
