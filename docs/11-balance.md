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

Tres contratos más (peaje del ganso, fantasma charlatán, paz del moho) pagan por la fórmula (15, 12 y 22 quesos tras añadirles el ballestero y la curandera) y el jefe exige ahora dos concretos (la escolta y el peaje). Jugador con plan, 100 partidas:

| Jugador | Victorias | Días | Queso final |
|---|---|---|---|
| Sin errores | 95 % | 13 | 52 |
| 10 % de errores | 90 % | 14 de media (7 a 20) | 37 |

Lectura: el jugador que hace **todos** los contratos acaba con muchísimo queso (52) porque cada uno paga más de lo que cuesta; el que va **directo al jefe** (siete días) sigue en la economía ajustada de antes. Las derrotas de ahora (5 a 10 %) son **de combate**, no de hambre: el jugador simulado pelea con todo sin descansar ni usar pociones. Es lo que cabe esperar de contenido opcional bien pagado, y es **el punto de partida para el farmeo**: si se quiere que lo opcional sea obligatorio, hacen falta niveles y enemigos que lo exijan (`docs/13-ampliacion.md` §10).

## Con niveles y experiencia (paquete D)

*(22 de noviembre de 2026.)* La experiencia de un combate (la suma de lo que vale cada enemigo) **se reparte** entre los que siguen en pie; un evento da 15, 10 o 5 a quien lo resuelve según el intento. Los encuentros del bosque y del Camino Real salen de nivel 2 y los de las cuevas de nivel 3 (+3 de vida y +1 de ataque por nivel); los combates de contrato no cambian. Sesenta partidas por jugador, con encuentros:

| Jugador | Victorias | Nivel medio de la Banda al ganar (máximo visto) |
|---|---|---|
| Combate al azar con pesos | 20 de 60 (33 %) | 2,2 (4) |
| Atento, solo atacar, 10 % de errores | 49 (82 %) | 2,3 (4) |
| Atento, solo atacar, sin errores | 55 (92 %) | 2,4 (4) |
| «Listo», sin errores | 41 (68 %) | 2,4 (4) |

Lectura: con niveles **el juego queda algo más duro que antes** (91–98 % del jugador atento sin niveles), porque los encuentros de las cuevas suben más que la Banda. La Banda acaba la partida en el nivel 2 o 3, lejos del 5: el nivel 4 y el 5 son para quien **farmea**. Una primera prueba sin reparto (cada uno ganaba la experiencia entera) llevaba a toda la Banda al nivel 4 o 5 y el juego se volvía fácil (98 % de victorias del atento y 70 % del despistado): por eso se reparte. El «listo» pierde más que el que solo ataca porque gasta turnos en habilidades que no siempre convienen (la balada, rebuscar): elegir **cuándo** usar una habilidad también es parte del juego.

## Con el mapa del norte (paquete C reducido)

*(24 de noviembre de 2026, rama `paquete-c-mapa`.)* Tres zonas nuevas a 1, 2 y 3 días de la taberna, tres contratos más (ninguno obligatorio para el jefe) y encuentros de nivel 2 en el pantano y de nivel 3 en las minas. Mismo informe (`informe(200, 1)`, 200 partidas por jugador, misma semilla) en la rama de niveles sola y con el norte:

| Jugador (combate) | Sin el norte | Con el norte | Queso al ganar (media) |
|---|---|---|---|
| Atento, 10 % de errores, solo atacar | 161 (80,5 %) | 173 (86,5 %) | 44 → 32 |
| Atento, 10 % de errores, «listo» | 117 (58,5 %) | 123 (61,5 %) | 33 → 24 |
| Atento sin errores, solo atacar | 184 (92 %) | 189 (94,5 %) | 56 → 36 |
| Atento sin errores, «listo» | 132 (66 %) | 131 (65,5 %) | 45 → 28 |
| Con plan, combate al azar | 69 (34,5 %) | 87 (43,5 %) | 41 → 31 |
| Al azar | 1 | 2 | — |

Lectura: el norte **no rompe el equilibrio**. Gana algo más quien tiene plan (más contratos = más experiencia y más queso por cobrar), pero llega a la victoria con **menos queso de sobra** y, a veces, un día o dos más tarde: el norte está lejos y cada día de viaje es una ración. Las muertes por hambre suben un poco (de 2 a 6 de 200 en el atento con errores), que es justo lo que el autor quería que costara ir lejos. No hizo falta tocar ningún número.

## Con las habilidades aprendidas (nivel 2)

*(25 de noviembre de 2026, rama `paquete-habilidades`.)* En el nivel 2 cada miembro aprende una habilidad activa de una vez por combate: el golpe de escudo (aturde), la raclette derramada (4 a cada enemigo, 2 quesos), la nana de requesón (cura 4 a cada uno) y la puñalada trapera (sin defensa, el doble contra un aturdido). El «listo» las usa con criterio (la nana si alguien está por debajo de la mitad, la raclette con dos enemigos o más y 6 quesos o más, la puñalada contra un aturdido, el escudo al más peligroso); el combate al azar las tiene entre sus opciones. Mismo informe (`informe(200, 1)`), `main` contra la rama:

| Jugador (combate) | `main` | Con las habilidades | Queso al ganar (media) |
|---|---|---|---|
| Atento sin errores, solo atacar | 189 (94,5 %) | 189 (94,5 %) | 36,3 → 36,3 |
| Atento, 10 % de errores, solo atacar | 173 (86,5 %) | 168 (84 %) | 32,4 → 32,0 |
| Atento sin errores, «listo» | 131 (65,5 %) | 145 (72,5 %) | 27,9 → 25,3 |
| Atento, 10 % de errores, «listo» | 123 (61,5 %) | 142 (71 %) | 24,0 → 20,8 |
| Con plan, combate al azar (lote 2) | 87 (43,5 %) | 113 (56,5 %) | 30,8 → 29,0 |
| Con plan, combate al azar (lote 1 / 3) | 59 / 91 | 89 / 113 | — |
| Al azar | 2 | 4 | — |

Lectura: la primera fila es el **control**: quien no usa habilidades juega exactamente las mismas partidas, así que cualquier diferencia de las demás viene de las habilidades. Con errores, el que solo ataca pierde unas pocas más porque sus errores al azar ahora pueden caer en una habilidad (dentro del ruido). El «listo» gana entre 7 y 10 puntos y gasta algo más de queso (la raclette). Quien más gana es el jugador **sin criterio en el combate** (de 43,5 % a 56,5 %): tiene más opciones y las fuertes se gastan solas, así que pulsar al azar sale mejor que antes. Si se quiere que el juego no se ablande para el despistado, las palancas son el nivel en el que se aprenden (el 3 en lugar del 2) o la cura de la nana (3 en lugar de 4); no se ha tocado ningún número sin que lo decida el autor.

## Con grupos de 3 a 5 enemigos y enemigos con truco

*(22 de noviembre de 2026.)* Dos enemigos nuevos —la **seta curandera** (12 de vida, desde atrás, cura 5 al aliado más herido, prioridad 5 de su lista, por delante de atacar) y el **ballestero oxidado** (10 de vida, 6 de ataque, a distancia: llega a la retaguardia)— y encuentros de 3 a 5 enemigos; el peaje del ganso y la paz del moho los llevan también (ahora pagan 15 y 22).

El combate no tiene azar, así que cada grupo se mide con un solo combate a la Banda entera, de dos maneras: **solo atacar** (al primero de la lista) y **listo** (la habilidad de quien actúa y a la curandera, luego a los ballesteros y al montado, primero):

| Encuentro | Solo atacar | Listo |
|---|---|---|
| Bosque: 2 setas, curandera, 2 mohos | gana; Tuerca con 8 de 22 | gana; Tuerca con 4 |
| Bosque: seta, 2 ratas, 2 mohos | gana; Tuerca con 16 | gana; Tuerca con 7 |
| Bosque: 3 setas y curandera | gana; Tuerca con 12 | gana; Tuerca con 12 |
| Camino: 2 bandidos y ballestero | gana; Pimentina con 8 de 18 | igual |
| Camino: 2 bandidos, montado y ballestero | gana, **1 caído**; Pimentina con 3 | gana, 1 caído; Pimentina con 13 |
| Camino: 3 bandidos y 2 ballesteros | gana, **1 caído**; Pimentina con 1 | igual, Pimentina con 1 |
| Cuevas: 3 ratas y 2 mohos | gana; Tuerca con 16 | gana; Tuerca con 12 |
| Cuevas: 2 mohos, curandera, seta y rata | gana; Tuerca con 13 | gana; Tuerca con 6 |
| **Cuevas: montado, bandido, ballestero y curandera** | **pierde: caen los cuatro** | **gana, 1 caído** |

Antes, con los grupos de uno o dos enemigos, «solo atacar» ganaba todo sin que cayera nadie; ahora se pierde el más duro y de varias peleas salen heridos o caídos los de retaguardia. Las partidas simuladas lo confirman (100 por política, semilla 1, con encuentros):

| Jugador | Victorias | Queso final |
|---|---|---|
| Combate al azar con pesos (sin descansar) | 41 de 100 | 39,7 |
| Atento (solo atacar), con 10 % de errores, descansando si vuelve herido | 91 | 42,0 |
| Atento (listo), con 10 % de errores | 85 | 34,0 |
| Atento (solo atacar), sin errores | 98 | 52,9 |
| Atento (listo), sin errores | 95 | 46,3 |

Lectura honesta: **la pelea sola ya no se gana siempre pulsando `atacar`** (el grupo duro de las cuevas), y **el desgaste manda**: el jugador que no descansa en la taberna pierde más de la mitad de las veces (41 % de victorias, contra 91–98 % del que sí descansa). Pero quien descansa cuando toca sigue ganando casi siempre, incluso solo atacando: descansar cuesta dos quesos y un día, y el botín de los grupos grandes (los bandidos y ballesteros siempre sueltan queso) lo paga de sobra. Si se quisiera apretar más: subir la probabilidad de los encuentros, o que descansar cueste más; hacerlo con el paquete D (niveles y zonas por nivel, `docs/13` §10) es más sano. El «listo» no gana más que el «solo atacar» porque la curandera y el ballestero solo pesan en los grupos duros y sus habilidades gastan queso.

## Con los encuentros al llegar a una zona (con los grupos de antes: un solo enemigo o dos)

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
