% mundo.pl
% Zonas, conexiones y hechos estaticos del mundo.
%
% Solo datos y reglas de consulta sobre ellos: este modulo no depende de ningun
% otro (es la capa mas baja) y nunca cambia. El estado que cambia vive en estado.pl.
% Los identificadores son los de docs/01-lore-y-ambientacion.md (seccion 10).

:- module(mundo, [zona/2, descripcion_zona/2, conexion/2, adyacente/2, zona_pacifica/1,
                  personaje/7, fila_preferida/2, alcance/2, rasgo/2,
                  habilidad_de/2, coste_queso/2,
                  enemigo/4, clase/2, lleva_queso/1, numerar_grupo/2,
                  curacion/2, lleva_inicial/3,
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
% ... y la de cada tipo de enemigo (todos los de la version minima pelean en primera fila)
fila_preferida(rata_quesera,    frente).
fila_preferida(bandido_torpe,   frente).
fila_preferida(moho_saltarin,   frente).
fila_preferida(bandido_montado, frente).
fila_preferida(gran_roquefort,  frente).

rasgo(baldomero, teme_caballos).
rasgo(pimentina, hechizos_de_cocina).
rasgo(rufino,    cobra_por_callar).
rasgo(tuerca,    manos_largas).

% habilidad_de(Id, Habilidad): una habilidad por personaje en la version minima.
% (Por ahora solo se usa la de Pimentina; las demas se programan con las habilidades.)
habilidad_de(baldomero, carga_heroica).
habilidad_de(pimentina, fondue_flamigera).
habilidad_de(rufino,    balada_inspiradora).
habilidad_de(tuerca,    rebuscar_bolsillos).

% coste_queso(Habilidad, N): quesos que gasta lanzar un hechizo de cocina (rasgo hechizos_de_cocina).
coste_queso(fondue_flamigera, 1).

% alcance(Id, Alcance): cuerpo (solo alcanza a la primera fila) o distancia (llega tambien a la retaguardia).
alcance(baldomero, cuerpo).
alcance(pimentina, distancia).
alcance(rufino,    distancia).
alcance(tuerca,    cuerpo).
alcance(rata_quesera,    cuerpo).
alcance(bandido_torpe,   cuerpo).
alcance(moho_saltarin,   cuerpo).
alcance(bandido_montado, cuerpo).
alcance(gran_roquefort,  cuerpo).

% ---------------------------------------------------------------------------
% Bestiario (version minima, por orden de dificultad): enemigo(Tipo, vida(V), ataque(A), defensa(D)).
% En combate cada enemigo es una instancia e(Tipo, N). bandido_torpe es canon (12/5/2); el resto
% son una propuesta inicial que se ajustara en el balance.
% ---------------------------------------------------------------------------
enemigo(rata_quesera,    vida(8),  ataque(4),  defensa(0)).
enemigo(bandido_torpe,   vida(12), ataque(5),  defensa(2)).
enemigo(moho_saltarin,   vida(10), ataque(4),  defensa(0)).
enemigo(bandido_montado, vida(18), ataque(7),  defensa(3)).
enemigo(gran_roquefort,  vida(60), ataque(11), defensa(4)).     % el jefe final

% clase(Tipo, Clase): alimenta reglas como la de teme_caballos (un caballo asusta a Baldomero).
clase(rata_quesera,    roedor).
clase(bandido_torpe,   humano).
clase(moho_saltarin,   hongo).
clase(bandido_montado, caballo).
clase(gran_roquefort,  queso_vivo).

% curacion(Objeto, Vida): lo que cura un objeto cuando un enemigo lo usa (la IA se cura con el).
curacion(pocion,  10).
curacion(esporas,  8).

% lleva_inicial(Tipo, Objeto, N): lo que lleva encima un enemigo al empezar el combate.
lleva_inicial(gran_roquefort, esporas, 1).        % las esporas curativas del jefe: una vez

% lleva_queso(Tipo): suelta 1 queso de botin al caer (el queso entra por botin, nunca se compra).
lleva_queso(bandido_torpe).
lleva_queso(bandido_montado).

% numerar_grupo(+Tipos, -Ids): un grupo de enemigos [rata_quesera, rata_quesera, bandido_torpe]
% pasa a instancias numeradas por tipo: [e(rata_quesera,1), e(rata_quesera,2), e(bandido_torpe,1)].
numerar_grupo(Tipos, Ids) :-
    numerar_grupo(Tipos, [], Ids).

numerar_grupo([], _, []).
numerar_grupo([Tipo|Tipos], Vistos, [e(Tipo, N)|Ids]) :-
    findall(x, member(Tipo, Vistos), Anteriores),
    length(Anteriores, N0),
    N is N0 + 1,
    numerar_grupo(Tipos, [Tipo|Vistos], Ids).

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
parametro(base_iniciativa,  10).    % la iniciativa es esta base + ataque - defensa + modificador de moral
parametro(max_contratos,     3).    % contratos activos a la vez
parametro(moral_victoria,    1).    % moral que gana cada miembro al ganar un combate (provisional)
parametro(bono_defender,     2).    % defensa extra de quien esta defendiendo (provisional)
parametro(dano_miedo,        2).    % dano extra que recibe quien teme a la clase del atacante (lore 7)
parametro(umbral_vida_baja, 30).   % vida baja: 30 % o menos de la maxima (la IA se cura)
parametro(dano_embestida,    2).    % dano extra de la primera embestida del bandido montado
parametro(max_mohos,         2).    % mohos que el jefe puede invocar en un combate
parametro(penal_venda,       3).    % ataque que pierde Baldomero con la venda contra los caballos (lore 7)

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
