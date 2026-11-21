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

## Aplicado: el botín con probabilidad (el primer azar del juego)

Antes solo los bandidos soltaban un queso, siempre. Ahora hay una tabla de datos, `mundo:botin(Tipo, Quesos, Probabilidad)`: al ganar un combate, cada enemigo suelta sus quesos con esa probabilidad. Los bandidos, siempre (100 %); las ratas, el 60 % de las veces; el jefe y los mohos, nada.

- **Reproducible:** la tirada (de 0 a 99) usa la semilla del juego y su generador propio, nunca `random/1`. La misma semilla da el mismo botín, así que las partidas, los ejemplos y las pruebas siguen siendo exactos. Cada tirada avanza la semilla (`fijar_semilla`); si ningún enemigo tiene botín, la semilla no se toca.
- **Se nota:** si cae, «Botín: N quesos frescos»; si no cae nada de lo posible, «ni una corteza».
- **El simulador** reparte semillas distintas a cada partida simulada (antes todas tiraban con la misma).

Jugador con plan y 10 % de errores, 300 partidas por variante (`herramientas/barrido.ps1`):

| Botín de las ratas | Victorias | Sobrante medio |
|---|---|---|
| Ninguno (0 %) | 274 (91 %) | 5,6 |
| 30 % | 276 (92 %) | 6,0 |
| **60 % (elegido)** | **280 (93 %)** | **6,3** |
| 100 % | 285 (95 %) | 6,9 |
| 2 quesos al 60 % | 284 (95 %) | 7,1 |
| Ratas 60 % y bandidos al 70 % | 279 (93 %) | 5,6 |

Lectura: **el botín apenas mueve el equilibrio** (de 5,6 a 6,3 quesos de sobrante, +2 puntos de victorias) y no era su papel: tras arreglar los pagos y el hambre, la economía ya tiene margen. Lo que aporta es **variedad**: dos partidas iguales ya no acaban con el mismo queso, y una racha mala o buena se nota. Por eso el 60 % y una sola unidad: más sería regalar queso. Los **objetos** como botín (una poción, por ejemplo) quedan para cuando exista `usar`: hoy solo los enemigos los gastan, y un objeto que el jugador no puede usar no es un premio.

## Con los contratos nuevos (ampliación de contenido)

Tres contratos más (peaje del ganso, fantasma charlatán, paz del moho) pagan por la fórmula (14, 12 y 21 quesos) y el jefe exige ahora dos concretos (la escolta y el peaje). Jugador con plan, 100 partidas:

| Jugador | Victorias | Días | Queso final |
|---|---|---|---|
| Sin errores | 95 % | 13 | 52 |
| 10 % de errores | 90 % | 14 de media (7 a 20) | 37 |

Lectura: el jugador que hace **todos** los contratos acaba con muchísimo queso (52) porque cada uno paga más de lo que cuesta; el que va **directo al jefe** (siete días) sigue en la economía ajustada de antes. Las derrotas de ahora (5 a 10 %) son **de combate**, no de hambre: el jugador simulado pelea con todo sin descansar ni usar pociones. Es lo que cabe esperar de contenido opcional bien pagado, y es **el punto de partida para el farmeo**: si se quiere que lo opcional sea obligatorio, hacen falta niveles y enemigos que lo exijan (`docs/13-ampliacion.md` §10).

## Con los encuentros al llegar a una zona

Probabilidades de 30 % (bosque y Camino Real) y 25 % (cuevas), con 2 o 3 grupos por zona. Cien partidas por política, semilla 1; entre paréntesis, la prueba con 50 / 50 / 45 %:

| Jugador | Victorias sin encuentros | con encuentros | (50 / 50 / 45) | Queso final (sin → con) |
|---|---|---|---|---|
| plan, 10 % de errores, lote 1 | 82 | 93 | (94) | 29,4 → 28,1 |
| plan, 10 % de errores, lote 2 | 91 | 83 | (90) | 37,7 → 40,5 |
| plan, 10 % de errores, lote 3 | 93 | 95 | (94) | 39,9 → 40,3 |
| plan con charlas | 98 | 96 | (95) | 40,2 → 41,8 |
| azar razonable | 5 | 7 | (8) | 16,8 → 17,7 |

Lectura: **no cambia el equilibrio**. Las diferencias están dentro del ruido de cien partidas (unos cinco puntos): cada encuentro cuesta vida, pero el botín (los bandidos lo sueltan siempre) y la moral de la victoria lo compensan, y la Banda se cura en la taberna. Son **variedad con riesgo y premio**, no un freno. Si se quiere que obliguen a prepararse, el camino es el de `docs/13-ampliacion.md` §10: niveles y enemigos por zona. Con la partida actual, subir las probabilidades solo da más queso.

## Qué sigue (en este orden, cada paso con el simulador)

1. ~~Pago según distancia y enemigos~~ (hecho).
2. ~~Regla de hambre más justa~~ (hecho).
3. ~~Botín tras el combate~~ (hecho).
4. **Hablar con NPC** (el contenido es lo caro). Un comando `usar` para los objetos encaja con él.

## Límites de lo medido

- El jugador con plan es **una** estrategia sensata, no todas; sirve para comparar variantes entre sí, no para predecir cuánto gana una persona real.
- Las derrotas «en combate» (1–4 %) dependen de la IA y del azar del juego y no se han ajustado.
- Cuatro contratos dan poco material: un contrato nuevo (o los NPC de `hablar`) cambiaría estas cifras y habría que volver a medir.
