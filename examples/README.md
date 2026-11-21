# examples/

Guiones de comandos y sus transcripciones guardadas. Todo se **genera** con el propio juego (no hay nada escrito a mano), es **reproducible** (la partida arranca siempre con el mismo estado y el único azar, el botín de los combates, tira con la semilla del juego: la misma semilla da el mismo resultado) y está en UTF-8 con fin de línea LF.

| Archivo | Qué es |
|---|---|
| `demo-comandos.txt` | El guion de la demostración de la exposición (~13 min): las cinco escenas y los comandos de cada una. Un comando por línea; las líneas que empiezan por `%` son comentarios. |
| `demo-salida.txt` | Su transcripción: cada orden aparece tras `> ` y debajo lo que respondió el juego. |
| `campana-comandos.txt` | La **partida de respaldo** (plan B si algo falla en directo): la campaña entera por la vía cómoda, con los cuatro contratos y el jefe. |
| `campana-salida.txt` | Su transcripción (acaba en victoria). |
| `explicaciones/*.txt` | Las pantallas clave de `explicar` y `por_que_no`, una por archivo y en sus dos niveles (resumido y detallado): ataque explicado, el miedo de Baldomero, el turno enemigo con el corte, y la gallina noble con y sin venda. |
| `generar.pl` | Regenera todas las salidas a partir de los guiones. |

## Pasar un guion entero

Los comandos se leen de la entrada estándar, así que basta redirigirla (desde la raíz del repositorio; en Windows, con el ejecutable por su ruta completa):

```
swipl -q -s src/main -g main -t halt < examples/demo-comandos.txt
```

## Regenerar las salidas

```
swipl -q -s examples/generar -g generar -t halt
```

Hay que hacerlo cada vez que cambia una frase del narrador, un número de balance o un guion. `tests/demo.pl` compara lo guardado con lo que el juego produce ahora y falla si difieren: así nunca hay una transcripción vieja en el repositorio.
