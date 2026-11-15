# 07 — Playtest guiado 1 (PT-1)

Primer recorrido completo de la partida mínima, jugado como lo haría una persona (por la consola, con las mismas pantallas que ve el jugador) y las tres rutas degeneradas del plan (docs/03 §9). Fecha: 15 de noviembre de 2026. Versión: commit anterior a T-36 más los ajustes que se describen aquí.

## 1. Método

- **Vía cómoda.** Los cuatro contratos en orden (ratas, gato, gallina, despensa real), `pagar` al volver a la taberna y, en cada combate, la habilidad de cada miembro contra el enemigo más fuerte (y `atacar` si no puede). Es una partida «de las buenas»: no es la más barata ni la más rápida.
- **Rutas degeneradas.** (a) no pagar nunca los sueldos; (b) ignorar la comida (descansar sin parar); (c) intentar cada contrato sin cumplir las condiciones.
- **Qué se mira.** Bloqueos, mensajes confusos o crudos, errores, duración, y si el jugador sabe en cada momento qué hacer.

## 2. Resultado de la vía cómoda

| Dato | Valor |
|---|---|
| Final | `victoria(chapuza)` |
| Días de partida | 7 |
| Comandos escritos | 48 (unos 15–20 minutos) |
| Queso al ganar | 0 (con `despensa_real` y `gallina_noble` por cobrar) |
| Vida al ganar | Baldomero 30/30, Pimentina 18/18, Rufino 20/20, Tuerca 4/22 |
| Pantallas con términos crudos o errores | 0 |
| Golpes a Clotilde | 2 (éxito) |

La partida se gana, no se bloquea y es **reproducible** (se juega dos veces y salen el mismo estado y las mismas pantallas).

## 3. Lo que chirriaba y qué se hizo

| # | Problema | Gravedad | Qué se hizo |
|---|---|---|---|
| 1 | Tras cada orden de combate **no se veía de quién era el turno ni cómo estaban los enemigos**: había que escribir `mirar.` entre orden y orden. | Alta | Cada orden de combate termina ahora con el estado (`Combate · ronda N · turno de X` y la vida de cada enemigo). No sale al ganar ni en un error. |
| 2 | **No se decía qué día era ni cuánta comida se gastaba** al viajar o descansar: la ración se comía en silencio. | Media | Mensaje nuevo al pasar el día: «Día N. … La ración de hoy: K quesos.» (3 variantes). |
| 3 | Las **variantes del narrador no rotaban**: cuatro cargas seguidas decían la misma frase, porque el contador era por mensaje *con argumentos* (cada enemigo reiniciaba la cuenta). | Media | El contador es ahora por grupo de frases: solo los mensajes cuyo argumento elige la frase (zona, tipo de enemigo, resultado) llevan el argumento en el grupo. |
| 4 | Un «no puedes» (aceptar, ir, descansar, pagar, atacar, habilidad) **no decía cómo averiguar por qué**. | Media | Cada rechazo termina con la pista `por_que_no(...)` adecuada. |
| 5 | El contrato que dice «os mira, mira a la Banda y decide que no» era gracioso pero **opaco** para un jugador nuevo. | Baja | Resuelto por la pista del punto 4. |

## 4. Rutas degeneradas

| Ruta | Qué pasa | Veredicto |
|---|---|---|
| (a) No pagar nunca | Cada salida de la taberna sin pagar baja la moral de todos; tras unas vueltas hay huelguistas, y de ir y venir sin ganar nada se acaba el queso: **fin por hambre**. | Correcto y sin pantallas raras |
| (b) Ignorar la comida | Descansar dos veces seguidas con 12 quesos los gasta (6 por día entre cama y ración): **fin por hambre** al segundo día, con el texto del final. Una orden más devuelve «La partida ha terminado.» | Correcto |
| (c) Contratos sin condiciones | Se rechazan con la pista; `por_que_no` explica el miedo de Baldomero (gallina) y que el rey no firma con desconocidos (despensa). Aceptar dos veces el mismo contrato se rechaza. | Correcto |

## 5. Observaciones de balance (para T-38, no se han tocado)

- **La vía cómoda gana con 0 quesos de margen.** Las habilidades gastan queso (la fondue cuesta 1 cada vez, ≈ 5 en la partida) y Tuerca rebusca +2; sin usarlas (solo `atacar`/`defender`, la campaña de `tests/campana.pl`) se gana con 2 quesos de sobra. Usar la magia a lo loco es tentador pero caro: **es el equilibrio que se quería**, aunque el margen es estrecho.
- **La escolta sale en éxito si se gana rápido** (2 golpes) y a medias si se pelea «a pelo» (3). Con habilidades sale en éxito.
- **El día 7 es muy constante.** La ruta mínima no deja mucho margen para equivocarse: un viaje de más cuesta 4 quesos.
- **Tuerca acaba con 4 de vida:** el jefe golpea al más débil. Es coherente con la IA, pero un jugador cómodo debería poder `descansar` antes del jefe (cuesta 2 quesos y un día).
- Habría que contrastarlo con una **segunda persona** (PT-2) antes de retocar números.

## 6. Pendiente

- PT-2 con otra persona (S6): claridad de `ayuda`, humor, dificultad.
- Decidir si se añade el mensaje de **huelga** («X se declara en huelga») y el de inicio de combate: hoy el juego no los emite.
- Revisar la **longitud** de la explicación de un ataque en el nivel detallado (58 líneas) si la demo la va a mostrar.
