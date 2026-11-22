% mundo.pl
% Zonas, conexiones y hechos estaticos del mundo.
%
% Solo datos y reglas de consulta sobre ellos: este modulo no depende de ningun
% otro (es la capa mas baja) y nunca cambia. El estado que cambia vive en estado.pl.
% Los identificadores son los de docs/01-lore-y-ambientacion.md (seccion 10).

:- module(mundo, [zona/2, descripcion_zona/2, conexion/2, adyacente/2, distancia/3, zona_pacifica/1,
                  personaje/7, fila_preferida/2, alcance/2, rasgo/2,
                  habilidad_de/2, coste_queso/2,
                  enemigo/4, clase/2, lleva_queso/1, botin/3, numerar_grupo/2,
                  probabilidad_de_encuentro/2, encuentro/2,
                  xp_para/2, crecimiento/4, pasiva/4, xp_de/2, xp_por_intento/2, nivel_de_zona/2, escala_enemigo/2,
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

% distancia(+A, +B, -Dias): los dias de viaje del camino mas corto (cada paso entre zonas cuesta un dia).
% Se prueba con 0, 1, 2... pasos: el primero que llega es el mas corto.
distancia(A, B, Dias) :-
    between(0, 12, Dias),
    alcanzable_en(A, B, Dias),
    !.

alcanzable_en(A, A, 0).
alcanzable_en(A, B, N) :-
    N > 0, M is N - 1,
    adyacente(A, C),
    alcanzable_en(C, B, M).

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
fila_preferida(ganso_de_peaje,  frente).
fila_preferida(seta_belicosa,   frente).
fila_preferida(seta_curandera,  retaguardia).      % los dos nuevos pelean desde atras
fila_preferida(ballestero_oxidado, retaguardia).

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
alcance(ganso_de_peaje,  cuerpo).
alcance(seta_belicosa,   cuerpo).
alcance(seta_curandera,  cuerpo).
alcance(ballestero_oxidado, distancia).             % el unico enemigo que llega a Pimentina y a Rufino

% ---------------------------------------------------------------------------
% Bestiario (version minima, por orden de dificultad): enemigo(Tipo, vida(V), ataque(A), defensa(D)).
% En combate cada enemigo es una instancia e(Tipo, N). bandido_torpe es canon (12/5/2); el resto
% son una propuesta inicial que se ajustara en el balance.
% ---------------------------------------------------------------------------
enemigo(rata_quesera,    vida(8),  ataque(4),  defensa(0)).
enemigo(bandido_torpe,   vida(12), ataque(5),  defensa(2)).
enemigo(moho_saltarin,   vida(10), ataque(4),  defensa(0)).
enemigo(bandido_montado, vida(18), ataque(7),  defensa(3)).
enemigo(ganso_de_peaje,   vida(16), ataque(6),  defensa(2)).     % el que cobra el peaje del Camino Real
enemigo(seta_belicosa,   vida(14), ataque(5),  defensa(1)).     % las del bosque, con muy mal humor
enemigo(seta_curandera,  vida(12), ataque(3),  defensa(1)).     % cura al aliado mas herido: hay que ir a por ella
enemigo(ballestero_oxidado, vida(10), ataque(6), defensa(0)).   % dispara a distancia: llega a la retaguardia
enemigo(gran_roquefort,  vida(60), ataque(11), defensa(4)).     % el jefe final

% clase(Tipo, Clase): alimenta reglas como la de teme_caballos (un caballo asusta a Baldomero).
clase(rata_quesera,    roedor).
clase(bandido_torpe,   humano).
clase(moho_saltarin,   hongo).
clase(bandido_montado, caballo).
clase(gran_roquefort,  queso_vivo).
clase(ganso_de_peaje,  ave).
clase(seta_belicosa,   hongo).
clase(seta_curandera,  hongo).
clase(ballestero_oxidado, humano).

% curacion(Objeto, Vida): lo que cura un objeto cuando un enemigo lo usa (la IA se cura con el).
curacion(pocion,  10).
curacion(esporas,  8).

% lleva_inicial(Tipo, Objeto, N): lo que lleva encima un enemigo al empezar el combate.
lleva_inicial(gran_roquefort, esporas, 1).        % las esporas curativas del jefe: una vez

% lleva_queso(Tipo): lo que se le puede rebuscar de los bolsillos (la habilidad de Tuerca): siempre 1 queso.
lleva_queso(bandido_torpe).
lleva_queso(bandido_montado).

% botin(Tipo, Quesos, Probabilidad): al ganar un combate, cada enemigo de este tipo suelta Quesos cheddar frescos
% con esta probabilidad (en %, una tirada con la semilla del juego: reproducible). El queso entra por botin,
% nunca se compra. Los bandidos lo sueltan siempre; las ratas, a veces (docs/11-balance.md).
botin(bandido_torpe,   1, 100).
botin(bandido_montado, 1, 100).
botin(rata_quesera,    1,  60).
botin(ganso_de_peaje,  1, 100).        % el peaje que habia cobrado
botin(seta_belicosa,   1,  50).
botin(seta_curandera,  1,  50).
botin(ballestero_oxidado, 1, 100).

% Encuentros al llegar a una zona (docs/13-ampliacion.md, 5): probabilidad_de_encuentro(Zona, Porcentaje) y, de las
% encuentro(Zona, Grupo) de esa zona, un grupo que sale (el segundo dado elige cual). Las zonas sin probabilidad
% (la taberna, la aldea y el castillo) son tranquilas. Es una tabla: una zona nueva peligrosa son unas filas.
probabilidad_de_encuentro(bosque,      30).
probabilidad_de_encuentro(camino_real, 30).
probabilidad_de_encuentro(cuevas,      25).

encuentro(bosque,      [seta_belicosa, seta_belicosa, seta_curandera, moho_saltarin, moho_saltarin]).
encuentro(bosque,      [seta_belicosa, rata_quesera, rata_quesera, moho_saltarin, moho_saltarin]).
encuentro(bosque,      [seta_belicosa, seta_belicosa, seta_belicosa, seta_curandera]).
encuentro(camino_real, [bandido_torpe, bandido_torpe, ballestero_oxidado]).
encuentro(camino_real, [bandido_torpe, bandido_torpe, bandido_montado, ballestero_oxidado]).
encuentro(camino_real, [bandido_torpe, bandido_torpe, bandido_torpe, ballestero_oxidado, ballestero_oxidado]).
encuentro(cuevas,      [rata_quesera, rata_quesera, rata_quesera, moho_saltarin, moho_saltarin]).
encuentro(cuevas,      [moho_saltarin, moho_saltarin, seta_curandera, seta_belicosa, rata_quesera]).
encuentro(cuevas,      [bandido_montado, bandido_torpe, ballestero_oxidado, seta_curandera]).

% ---------------------------------------------------------------------------
% Niveles y experiencia (paquete D, docs/13-ampliacion.md §10). Regla de oro: el NIVEL 1 son exactamente las cifras de la
% ficha (personaje/7); solo se crece desde el 2, asi lo ya verificado sigue valiendo.
% ---------------------------------------------------------------------------
% xp_para(Nivel, XP): la experiencia TOTAL que hace falta para ese nivel: 5 * (N-1) * (N+2), es decir 0, 20, 50, 90, 140...
% La curva llega al 20, pero el contenido real (crecimiento con pasivas) acaba en parametro(nivel_maximo): el resto son
% datos para ampliar mas adelante sin tocar reglas.
xp_para(N, XP) :-
    between(1, 20, N),
    XP is 5 * (N - 1) * (N + 2).

% crecimiento(Rol, vida(V), ataque(A), defensa(D)): lo que suma cada nivel por encima del 1.
crecimiento(caballero, vida(3), ataque(1), defensa(0)).
crecimiento(maga,      vida(2), ataque(1), defensa(0)).
crecimiento(bardo,     vida(2), ataque(1), defensa(0)).
crecimiento(ladron,    vida(2), ataque(1), defensa(0)).

% pasiva(Id, Nivel, Nombre, Bono): una habilidad PASIVA que se gana al llegar al nivel; Bono = vida(N) | ataque(N) | defensa(N).
% Son pasivas a proposito: no cambian el comando `habilidad` ni los botones (docs/13 §10).
pasiva(baldomero, 3, escudo_de_corteza,   defensa(1)).
pasiva(baldomero, 5, brazo_de_parmesano,  ataque(2)).
pasiva(pimentina, 3, delantal_ignifugo,   vida(4)).
pasiva(pimentina, 5, cucharon_templado,   ataque(2)).
pasiva(rufino,    3, pulmones_de_tenor,   vida(4)).
pasiva(rufino,    5, laud_reforzado,      defensa(1)).
pasiva(tuerca,    3, pies_de_gato,        defensa(1)).
pasiva(tuerca,    5, punal_de_queso_duro, ataque(2)).

% xp_de(Tipo, XP): la experiencia que vale cada enemigo vencido (la ganan los que siguen en pie al ganar).
xp_de(rata_quesera,       3).
xp_de(moho_saltarin,      3).
xp_de(bandido_torpe,      5).
xp_de(seta_belicosa,      5).
xp_de(seta_curandera,     6).
xp_de(ballestero_oxidado, 6).
xp_de(ganso_de_peaje,     8).
xp_de(bandido_montado,   10).
xp_de(gran_roquefort,    40).

% xp_por_intento(Intento, XP): resolver un evento de contrato al primer intento vale mas (la gana quien lo resuelve).
xp_por_intento(1, 15).
xp_por_intento(2, 10).
xp_por_intento(3,  5).

% nivel_de_zona(Zona, Nivel): los enemigos de los ENCUENTROS de esa zona salen con ese nivel (los de contrato, no: son los
% del contrato). La web y `mirar` lo dan como nivel recomendado. Las zonas sin fila son de nivel 1.
nivel_de_zona(bosque,      2).
nivel_de_zona(camino_real, 2).
nivel_de_zona(cuevas,      3).

% escala_enemigo(vida(V), ataque(A)): lo que suma cada nivel de un enemigo por encima del 1.
escala_enemigo(vida(3), ataque(1)).

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
parametro(nivel_maximo,      5).    % hasta aqui hay contenido real (crecimiento y pasivas); la curva sigue hasta el 20
parametro(cura_de_seta,      5).    % vida que cura la seta curandera al aliado mas herido, cada turno
parametro(max_mohos,         2).    % mohos que el jefe puede invocar en un combate
parametro(dias_de_ayuno_max, 2).    % dias seguidos sin comer que aguanta la Banda antes de perder por hambre (docs/11)
parametro(pago_base,         6).    % quesos que paga todo contrato antes de sumar nada (balance, docs/11)
parametro(pago_por_dia,      3).    % ... mas esto por cada dia de viaje de la ruta del contrato
parametro(pago_por_enemigo,  1).    % ... mas esto por cada enemigo al que hay que vencer
parametro(pago_minimo,      12).    % ... y nunca menos de esto (ir, pagar a la Banda y curarse tiene que compensar)
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
