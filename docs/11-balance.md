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

## Lo que se midió (juego tal como está)

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

## Qué sigue (en este orden, cada paso con el simulador)

1. **Pago según distancia y enemigos** (mínimo 12): base + por día de ida y vuelta + por enemigo, con los parámetros como datos en `mundo`. Objetivo a medir: con el jugador con plan y 10 % de ruido, **al menos un 85–90 % de victorias** y de 3 a 10 quesos sobrantes.
2. **Botín tras el combate** (azar con semilla, reproducible). Ya existe `lleva_queso/1` para algunos enemigos; hay que medir cuánto añade.
3. **Regla de hambre más justa**: no perder si hay un contrato aceptable en la zona. Cambia las pruebas de la campaña.

## Límites de lo medido

- El jugador con plan es **una** estrategia sensata, no todas; sirve para comparar variantes entre sí, no para predecir cuánto gana una persona real.
- Las derrotas «en combate» (1–4 %) dependen de la IA y del azar del juego y no se han ajustado.
- Cuatro contratos dan poco material: un contrato nuevo (o los NPC de `hablar`) cambiaría estas cifras y habría que volver a medir.
