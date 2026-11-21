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

## Qué sigue (en este orden, cada paso con el simulador)

1. ~~Pago según distancia y enemigos~~ (hecho, arriba).
2. **Botín tras el combate** (azar con semilla, reproducible). Ya existe `lleva_queso/1` para algunos enemigos; hay que medir cuánto añade.
3. **Regla de hambre más justa**: no perder si hay un contrato aceptable en la zona. Cambia las pruebas de la campaña y debería recoger buena parte de ese 12 %.

## Límites de lo medido

- El jugador con plan es **una** estrategia sensata, no todas; sirve para comparar variantes entre sí, no para predecir cuánto gana una persona real.
- Las derrotas «en combate» (1–4 %) dependen de la IA y del azar del juego y no se han ajustado.
- Cuatro contratos dan poco material: un contrato nuevo (o los NPC de `hablar`) cambiaría estas cifras y habría que volver a medir.
