# Balance de la economía del queso (con el simulador)

*Cómo se mide si el juego se puede ganar y con cuánto margen. Herramientas: `herramientas/simulador.pl` y `herramientas/barrido.ps1`. Pruebas: `tests/simulador.pl`.*

## Por qué un simulador

Una persona jugó una campaña y perdió el día 6 por hambre. Reconstruida su ruta, la economía resultó **muy justa** y el juego **no avisaba**. Las propuestas siguientes (pagar más por contrato, botín, una regla de hambre más justa) tocan números con muy poco margen: cambiarlos «a ojo» puede dejar el juego imposible o trivial. El simulador juega **partidas enteras sin persona, con el motor de verdad** (`juego:ejecutar/2`), y da cifras.

## Qué hace

- **Rutas guionizadas** (`jugar_ruta/2`): una lista de órdenes con el combate jugado solo (atacar; si no se puede, defender). Reproduce la campaña de `examples/` (la ruta de referencia) y la ruta de la partida perdida.
- **Jugador sin plan** (`azar`): en cada paso elige al azar, con pesos, entre las órdenes que el juego acepta de verdad. Es el peor caso: vaga sin objetivo.
- **Jugador con plan** (`plan(Ruido, Lote)`): paga los sueldos, acepta hasta `Lote` contratos, va al sitio de un contrato abierto por el camino más corto y vuelve a cobrar; con un `Ruido` % de las veces hace otra cosa al azar (un día perdido, un viaje de más…). Es una persona sensata que a veces se equivoca.
- **Azar propio y reproducible**: el mismo generador congruencial del juego pero con estado aparte, así que cada partida simulada se repite igual con la misma semilla y no toca la del juego.

```text
swipl -q -s herramientas/simulador -g "informe(200, 1)" -t halt
powershell -ExecutionPolicy Bypass -File herramientas/barrido.ps1 -Partidas 100
```

El barrido copia el juego a una carpeta temporal, cambia unos números del texto de `src/` y simula sobre la copia: **el repositorio no se toca**.

## Lo que se midió (el juego antes de cambiar los pagos)

Rutas de referencia:

| Ruta | Resultado |
|---|---|
| Campaña de `examples/` (4 contratos y el jefe, 40 órdenes) | Victoria el día 7 **con 0 quesos de sobra** |
| La de la partida perdida (contratos de la aldea por separado) | Día 6 con 3 quesos y sin cobrar lo suficiente: a un paso del hambre |

Jugadores simulados (200 partidas, semilla 7000+):

| Jugador | Victorias | Derrotas por hambre |
|---|---|---|
| Con plan, sin ningún error | **198 de 200** | 0 |
| Con plan, 5 % de pasos al azar | 162 | 36 |
| Con plan, 10 % de pasos al azar (100 partidas) | 78 | 21 |
| Con plan, 20 % de pasos al azar | 101 de 200 | 90 |
| Sin plan (azar con pesos) | **0** | 98 de 100 |

## Conclusión

**El juego se puede ganar, pero no tiene margen.** La ruta óptima gana casi siempre (el día 7 y con 0–2 quesos sobrantes), pero **cada día perdido cuesta 4 quesos** y la economía no los repone: con solo un 5 % de pasos errados se pierde una de cada cinco partidas. Quien vaga sin plan **no gana nunca**. Es una tensión legítima (el queso es la comida y la moneda), pero la curva de aprendizaje es una pared: o juntas los contratos y no pierdes ni un día, o pierdes.

## Variantes probadas

Con el jugador con plan y 10 % de ruido (100 partidas por variante; «sobrante» es la media de quesos al ganar):

| Variante | Victorias | Hambre | Sobrante |
|---|---|---|---|
| **Base** (9 / 7 / 14, 12 de inicio) | 78 | 21 | 0,2 |
| Pagos 12 / 12 / 18 | 83 | 14 | 4,3 |
| Pagos 12 / 12 / 16 | 83 | 14 | 4,2 |
| Pagos 14 / 12 / 20 (según distancia) | 91 | 9 | 10,3 |
| Inicio de 16 quesos | 83 | 15 | 1,9 |
| Pagos 12 / 12 / 18 + inicio de 16 | 89 | 10 | 6,7 |

(Pagos = ratas / gato / gallina; el jefe sigue en 40.)

Lectura:

- **Subir los pagos ayuda más que dar queso al principio**: da margen donde hace falta (después de cada viaje), y 12 / 12 / 18 pasa de 0,2 a 4,3 quesos sobrantes.
- Con **14 / 12 / 20** se pierde por hambre menos de una de cada diez partidas aun con ruido, pero **no desaparece**: sigue siendo un juego de gestión, no un paseo.
- **El pago mínimo de 12** que propuso el autor es coherente con los datos: ningún contrato debe pagar menos de lo que cuesta ir y volver (aldea: 2 días = 8 quesos) más una ración de margen.
- Los días hasta ganar apenas cambian (de 7,6 de media en la base a 7,7–8,0 en las variantes): ajustar la economía **no alarga la partida**.

## Aplicado: el pago se deriva de lo que cuesta el contrato

Cada día de viaje cuesta una ración entera (4 quesos), así que un número fijo por contrato era una apuesta a ciegas. Ahora (`contratos:pago_de/2`):

```text
pago = max(12, 6 + 3 × días de ruta + 1 × enemigos)
```

- **Días de ruta:** ir a la zona del contrato y volver a la taberna. Una escolta lleva además al destino (taberna → camino real → castillo → taberna = 4 días).
- **Enemigos:** a cuántos hay que vencer (`via_objetivo`); un evento cuenta 0.
- **Parámetros como datos** en `mundo:parametro/2` (`pago_base`, `pago_por_dia`, `pago_por_enemigo`, `pago_minimo`): se ajustan sin tocar reglas.
- **Resultado:** ratas 14, gato 12 (el mínimo), gallina 21; el jefe **sigue en 40** (ganarlo gana la partida, no hace falta fórmula). «A medias» paga la mitad.
- **Garantía** (probada en `tests/pago.pl`): ningún contrato paga menos que la ración de sus días de ruta, y los dos de la aldea juntos dejan más que el viaje y los sueldos.

Jugador con plan y 10 % de ruido, 250 partidas por variante (`herramientas/barrido.ps1`):

| Variante | Victorias | Hambre | Sobrante medio |
|---|---|---|---|
| Pagos antiguos fijos (9 / 7 / 14) | 193 (77 %) | 51 | 0,2 |
| Base 4 | 212 (85 %) | 33 | 4,1 |
| **Fórmula elegida (base 6)** | **215 (86 %)** | 31 | 5,7 |
| Base 8 | 219 (88 %) | 29 | 9,1 |
| 4 por día | 219 (88 %) | 29 | 9,3 |
| Fórmula elegida + inicio de 16 quesos | 221 (88 %) | 28 | 8,8 |

Sin errores del jugador, la fórmula gana **200 de 200** con 6,5 quesos de media al final (antes 198 de 200 con 0,1).

**Por qué base 6 y no más:** de 6 a 8 las victorias suben apenas dos puntos y el juego se vuelve más fácil sin ganar tensión. Las derrotas por hambre que quedan (un 12 %) no son de dinero: la regla de hambre se aplica **al llegar**, antes de que el jugador pueda aceptar el contrato que le habría pagado. Eso es lo siguiente.

## Aplicado: la regla de hambre más justa (el ayuno)

Antes, quedarse sin queso acababa la partida **en el acto**: al llegar a una zona, antes de que el jugador pudiera aceptar el contrato que le habría pagado, y aunque nadie hubiera pasado hambre todavía (bastaba con comerse la última ración). Era la causa del 12 % de derrotas por hambre que quedaba tras arreglar los pagos.

Ahora la Banda aguanta unos **días seguidos sin comer** (`mundo:parametro(dias_de_ayuno_max, 2)`):

- Un día en que alguien se queda sin ración suma uno al contador (`dias_de_ayuno`, un contador del estado); un día en que todos comen lo pone a cero.
- Se pierde por hambre (`economia:derrota_por_hambre/0`) cuando hay **cero queso, nada por cobrar y el contador ha llegado al límite**.
- Cobrar a tiempo salva: al llegar a la taberna el cobro se hace antes de comprobar el final.
- Sigue habiendo castigo: cada día sin comer baja la moral y la vida (nunca por debajo de 1), así que una Banda famélica pierde más combates.
- Los avisos se adaptan: `a_cero` («os quedáis sin queso») es un aviso suave y `hambre_mortal` solo sale cuando de verdad el siguiente día sin comer es el último.

Jugador con plan y 10 % de errores, 250 partidas por variante (`herramientas/barrido.ps1`):

| Días de ayuno | Victorias | Derrotas por hambre | Derrotas en combate |
|---|---|---|---|
| 0 (la regla antigua) | 215 (86 %) | 31 | 4 |
| 1 | 229 (92 %) | 15 | 6 |
| **2 (elegido)** | **229 (92 %)** | **10** | 11 |
| 3 | 231 (92 %) | 4 | 15 |
| 4 | 231 (92 %) | 3 | 16 |

Lectura: de 0 a 1 día se recuperan 14 partidas; de 1 a 2, las victorias no suben, pero las derrotas pasan de «hambre» a «combate» (la Banda hambrienta llega más débil); de 2 a 4 no hay ganancia y casi nadie pierde ya de hambre, lo que **quitaría el peso al queso**. Con dos días se puede ir a una zona, hacer el contrato y volver a cobrar (justo el viaje de la partida perdida), sin que la comida deje de importar.

## Qué sigue (en este orden, cada paso con el simulador)

1. ~~Pago según distancia y enemigos~~ (hecho).
2. ~~Regla de hambre más justa~~ (hecho).
3. **Botín tras el combate** (azar con semilla, reproducible). Ya existe `lleva_queso/1` para algunos enemigos; hay que medir cuánto añade.
4. **Hablar con NPC** (el contenido es lo caro).

## Límites de lo medido

- El jugador con plan es **una** estrategia sensata, no todas; sirve para comparar variantes entre sí, no para predecir cuánto gana una persona real.
- Las derrotas «en combate» (1–4 %) dependen de la IA y del azar del juego y no se han ajustado.
- Cuatro contratos dan poco material: un contrato nuevo (o los NPC de `hablar`) cambiaría estas cifras y habría que volver a medir.
