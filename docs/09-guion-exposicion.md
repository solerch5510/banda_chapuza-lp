# Guion de la exposición de Banda Chapuza

Duración objetivo: **13 minutos** (margen hasta 15) con demostración en vivo. Lo que va en cita (`>`) es lo que **digo**; lo que va en bloque de código es lo que **tecleo**; «Se ve» es lo que debe aparecer (comprobado contra la versión 1.0, salidas en `examples/`). Los tiempos de habla son una estimación a 130 palabras por minuto; el ensayo con cronómetro (§6) los sustituye por los reales.

**La tesis, en una frase:** *el juego es un programa lógico que puede explicarse a sí mismo.*

---

## 1. Antes de salir (lista de comprobación)

- [ ] Equipo propio con **SWI-Prolog 5.10.4** (`C:\Program Files\pl\bin\swipl.exe`) y el repositorio clonado en la etiqueta de entrega; copia en memoria USB.
- [ ] **Tildes en la consola:** arrancar el juego y mirar `ayuda.`; si salen símbolos raros, ejecutar `chcp 65001` en esa consola antes de arrancar (o enseñar la versión web, que no depende de la consola).
- [ ] Letra grande y fondo claro en el terminal. Dos ventanas: el **juego** y el **editor** con `src/combate.pl`, `src/explicar.pl` y `src/mundo.pl` abiertos en las líneas de §3.
- [ ] Una segunda pestaña de terminal con la orden de las pruebas **ya escrita** (no la lanzo hasta el cierre).
- [ ] Probar `demo.` y `demo(combate).`; comprobar que `explicar.` y `por_que_no(...)` responden.
- [ ] Copia de seguridad a mano: abiertos `examples/demo-salida.txt` y `examples/explicaciones/` (plan B, §5).

Arranque: `swipl -q -s src/main -g main -t halt` desde la raíz del repositorio.

## 2. Cronograma

| Tiempo | Bloque | Duración prevista | Palabras habladas | Habla estimada |
|---|---|---|---|---|
| 0:00–1:00 | La idea | 1:00 | 104 | 0:48 |
| 1:00–3:00 | Hechos y reglas (editor) | 2:00 | 114 | 0:53 |
| 3:00–5:00 | Aritmética y base de datos dinámica (juego) | 2:00 | 86 | 0:40 |
| 5:00–7:30 | Demostración central 1: `explicar` y `por_que_no` | 2:30 | 100 | 0:46 |
| 7:30–9:30 | Metaprogramación (editor) | 2:00 | 137 | 1:03 |
| 9:30–11:00 | Demostración central 3: la IA y el corte | 1:30 | 109 | 0:50 |
| 11:00–12:00 | Demostración central 2: la gallina noble | 1:00 | 71 | 0:33 |
| 12:00–13:00 | Cierre | 1:00 | 119 | 0:55 |
| | **Total** | **13:00** | **840** | **6:28** |

El resto de cada bloque es teclear y mirar la pantalla. Si en el ensayo la habla estimada de un bloque supera su duración prevista, hay que acortar el texto o quitar un comando de ese bloque.

---

## 3. Guion, minuto a minuto

### 0:00 – 1:00 · La idea

> Banda Chapuza es un juego de rol de texto. Diriges una compañía de mercenarios incompetentes que cobran en queso: el queso es la moneda y también la comida, y además madura. Pero el juego no es lo importante.
>
> Lo importante es que está escrito entero en Prolog, y que **el juego es un programa lógico que puede explicarse a sí mismo**. El mundo son hechos, las reglas del juego son cláusulas, y puedo preguntarle: «¿por qué has hecho eso?» o «¿por qué no puedo hacer esto?». La respuesta no es un mensaje escrito a mano: sale del árbol de derivación de las propias reglas.

### 1:00 – 3:00 · Hechos y reglas (editor)

Abro `src/mundo.pl` (hechos: `personaje/7`, `rasgo/2`, `conexion/2`) y luego `src/combate.pl` en la línea 54.

> Esto son hechos: Sir Baldomero, caballero, treinta de vida, once de ataque. Y su rasgo: teme a los caballos.
>
> Y esta es la regla de quién puede atacar. Se lee casi como una frase: A puede atacar a B si A está vivo, no está en huelga, B está vivo, B es alcanzable por filas, A no está aturdido, y —esta línea es la importante— **no existe una clase a la que A tema y a la que B pertenezca**. Eso es negación como fallo.
>
> Y el daño es aritmética sobre hechos: ataque menos defensa más un modificador, con un mínimo de uno. Nada más. No hay un bloque de condicionales: hay una especificación.

Abro la línea 147 (`dano/3`).

### 3:00 – 5:00 · Aritmética y base de datos dinámica (juego)

```
demo(economia).
mirar.
inventario.
pagar.
ir(aldea).
ir(bosque).
inventario.
```

Se ve: día 12, **15 quesos** (12 frescos, 2 curados, 1 rancio); `pagar.` cuesta 5 quesos, **los más rancios primero**; cada viaje cuesta un día y una ración de 4; al final quedan 2 quesos y su edad ha subido.

> Estamos en el día doce, con queso fresco, curado y rancio. Pago los sueldos: se gastan primero los quesos más rancios. Viajo, y cada día los quesos envejecen y la banda come cuatro. Todo es aritmética y consultas.
>
> Fíjense en una cosa: **nada de esto se programa con asignaciones**. El estado es una base de datos dinámica, y solo un módulo, `estado.pl`, la modifica. Las reglas son puras: devuelven lo que *cambiaría*, como datos, y `estado.pl` lo aplica. Es el límite explícito entre estado y reglas.

### 5:00 – 7:30 · Demostración central 1: `explicar` y `por_que_no`

```
demo(combate).
explicar(atacar(baldomero, bandido_torpe)).
por_que_no(atacar(baldomero, bandido_montado)).
nivel(detallado).
por_que_no(atacar(baldomero, bandido_montado)).
nivel(resumido).
```

Se ve (primero): el árbol de `puede_atacar` con cada condición `[ok]` y, al final, `[ok] 9 is max(1, 11-2+0)  [builtin]`. Se ve (después): `[no] \+ (teme(baldomero, caballo), clase_de(e(bandido_montado, 1), caballo))` con «porque teme(baldomero, caballo) y clase_de(..., caballo) son ciertos». En detallado aparecen debajo `[ok] rasgo(baldomero, teme_caballos)  [hecho]` y `[ok] clase(bandido_montado, caballo)  [hecho]`.

> Primero pregunto por qué *pude* atacar al Bandido Torpe. Sale el árbol de la prueba: cada condición de la regla, en orden, y al final el cálculo: nueve es once menos dos más cero.
>
> Ahora lo interesante: Baldomero **no** puede atacar al Bandido Montado. Pregunto por qué no. El sistema recorre la regla, ve que todas las condiciones se cumplen salvo una, y esa es una negación. ¿Y por qué falla la negación? Porque lo que niega **sí** es cierto: Baldomero teme a los caballos y el bandido es un caballo. Con el nivel detallado baja hasta los hechos concretos.

### 7:30 – 9:30 · Metaprogramación (editor)

Abro `src/explicar.pl` en la línea 81 (`s_(neg, ...)`) y en la 123 (`regla/4`).

> Esto es lo que lo hace posible: un meta-intérprete, un programa Prolog que ejecuta programas Prolog. Para cada forma de objetivo, una cláusula: la conjunción, la disyunción, el si-entonces, **la negación** —aquí: la prueba de `\+ G` es que `G` no se pueda demostrar—, los predicados predefinidos, y los predicados del juego, que se abren con `clause/3`.
>
> Y aquí está el corte, **tratado de verdad**, no ignorado: se conserva la primera solución de lo anterior, se descartan las demás y las cláusulas siguientes, y la prueba lleva un nodo `corte`. Cada nodo de lo que han visto —`hecho`, `builtin`, `no demostrable`, `corte`— es un paso de resolución.
>
> ¿Cómo sé que no miente? Porque lo he comprobado: cuarenta objetivos del juego en ocho escenarios, ejecutados directamente y con el meta-intérprete, dan **las mismas soluciones en el mismo orden**.

### 9:30 – 11:00 · Demostración central 3: la IA y el corte

```
demo(ia).
defender.
defender.
defender.
explicar.
```

Se ve: «Eligió la regla de prioridad **5 de 6** (el corte descartó las demás)», `[clausula 5 + corte]`, y debajo las reglas de mayor prioridad con por qué no se aplicaron (por ejemplo `12*100=<12*30 es falso`).

Abro `src/combate.pl` en la línea 276 (`accion_enemigo/2`) y en la 284 (`regla_ia/3`).

> Cada enemigo decide con una lista de reglas por prioridad: curarse, invocar moho, robar queso, embestir, atacar al más débil, defender. El corte significa «la primera que se aplique gana».
>
> Tras el turno del enemigo, `explicar` cuenta por qué hizo eso: ganó la regla cinco, y las cuatro anteriores no se aplicaron, cada una con su motivo. Un corte cambia el significado del programa, así que cada regla tiene una **gemela sin corte**, esta de aquí, que usan las pruebas como oráculo.

**Si hay tiempo (≈ 1:30), cambio en vivo.** En `src/combate.pl` corto la última cláusula (`accion_enemigo(_, defender).`), la pego la primera **con el corte**, `accion_enemigo(_, defender) :- !.`, guardo, salgo con `salir.` y vuelvo a arrancar con `demo(ia).`, `defender.` ×3, `explicar.`

Se ve (ensayado): el Bandido Torpe se pone a la defensiva y `explicar` dice «Eligió la regla de prioridad **1 de 6**» y `[clausula 1 + corte]`.

> Si cambio el orden, cambia el comportamiento: ahora la regla de defender gana siempre. El orden de las cláusulas es parte de la especificación. Deshago el cambio.

Después restauro el archivo con `git checkout src/combate.pl`.

### 11:00 – 12:00 · Demostración central 2: la gallina noble

```
demo(gallina).
contratos.
por_que_no(aceptar(gallina_noble)).
demo(venda).
por_que_no(aceptar(gallina_noble)).
aceptar(gallina_noble).
```

Se ve: el contrato de Lady Clotilde en estado `[bloqueado]`; el diagnóstico baja hasta `\+ (activo(baldomero), rasgo(baldomero, teme_caballos), \+ ignora_miedo(baldomero))`; tras `demo(venda)` (Baldomero lleva la venda de caballos) la misma pregunta dice «No falla nada: la acción es perfectamente posible» y el contrato se acepta.

> Lady Clotilde exige una escolta sin miedo a los caballos. Pregunto por qué no puedo aceptarla, y baja por las reglas hasta la negación que lo impide: Baldomero está activo, tiene el rasgo de temer a los caballos y **no ignora su miedo**. Le pongo la venda de caballos, el premio de otro contrato, y la misma pregunta ya no falla: el contrato se acepta. Mismo mecanismo, de punta a punta.

### 12:00 – 13:00 · Cierre

En la segunda pestaña lanzo las pruebas (unos 20 segundos):

```
swipl -q -s tests/todas -g "run_tests,halt" -t "halt(1)"
```

Se ve: «40 suites en verde, 0 con fallos; 2294 pruebas declaradas» y «TODO EN VERDE».

> Para terminar: la verificación fue tan importante como el código. Veintiocho suites, más de mil setecientas pruebas, pruebas de mutación —rompo el código a propósito y compruebo que alguna prueba falla— y la prueba de equivalencia del meta-intérprete que les contaba.
>
> Y cada concepto del curso tiene su sitio: hechos y reglas en el combate, unificación en los resultados, resolución y retroceso en el árbol de derivación, negación como fallo en `por_que_no`, el corte en la IA, aritmética en el daño y el queso, metaprogramación en `explicar.pl` y base de datos dinámica aislada en `estado.pl`. No hay programación funcional, y lo digo abiertamente. Con más tiempo haría guardar y cargar, más contratos y un ajuste fino del balance. Gracias.

*Extra (si sobran minutos o preguntan por la interfaz):* `swipl -q -s src/servidor -g "servidor(8080)" -t halt` y abrir `http://localhost:8080/`: la misma partida en el navegador; el botón «¿por qué no?» de una acción desactivada llama al mismo `por_que_no`. La web no contiene ninguna regla.

---

## 4. La matriz de lo declarativo (para una diapositiva o para el final)

| Conferencia | Concepto | Dónde se ve |
|---|---|---|
| 1–2 | Hechos, cláusulas, unificación | `mundo.pl`; `puede_atacar/2`, `dano/3` |
| 3 | Resolución SLD, árbol de derivación, retroceso | `solve/2`; el árbol de `explicar` |
| 4 | **Negación como fallo** y **corte** | `por_que_no` (el miedo de Baldomero); `accion_enemigo/2` y su gemela sin corte |
| 5 | Aritmética | daño, sueldos, ración, maduración del queso |
| 6 | Metaprogramación y `clause/3` | `explicar.pl`: `solve/2` y `por_que_no/2` |
| 6 | Base de datos dinámica, módulos | `estado.pl` (único escritor); 16 módulos |

## 5. Plan B (qué hago si algo falla)

| Fallo | Respuesta |
|---|---|
| SWI-Prolog no arranca en el equipo de la sala | Uso mi equipo; si no, proyecto `examples/demo-salida.txt` (la transcripción completa de esta demo) y la grabación de la demo. |
| La partida se desvía o el estado queda raro | Escribo `demo(escena).` (reinicia a un estado preparado y conocido) y sigo desde el siguiente punto del guion. |
| `explicar` o `por_que_no` fallan en vivo | Abro `examples/explicaciones/` (una pantalla clave por archivo, en resumido y detallado) y explico el código en el editor. |
| Las tildes salen rotas | `chcp 65001` antes de arrancar, o la versión web. |
| Se acaba el tiempo | Recorto, por este orden: el cambio en vivo de la IA, el bloque de hechos (1:00–3:00) y la parte de aritmética. **Conservo las tres demostraciones centrales y el bloque de `solve/2`.** |
| No hay proyector con terminal legible | PDF con las salidas clave (las de `examples/explicaciones/`). |
| Algo falla en la partida y no sé por qué | Digo que es la demostración en vivo, abro la partida de respaldo `examples/campana-comandos.txt` y la ejecuto de golpe: `swipl -q -s src/main -g main -t halt < examples/campana-comandos.txt`. |

## 6. Ensayo con cronómetro (PT-3)

Ejecutar este guion **tal cual, dos veces**, con el cronómetro, y rellenar:

| Bloque | Previsto | Ensayo 1 | Ensayo 2 | Qué recortar si me paso |
|---|---|---|---|---|
| 0:00 La idea | 1:00 | | | |
| 1:00 Hechos y reglas | 2:00 | | | |
| 3:00 Aritmética y BD | 2:00 | | | |
| 5:00 Demostración 1 | 2:30 | | | |
| 7:30 Metaprogramación | 2:00 | | | |
| 9:30 IA y corte | 1:30 | | | |
| 11:00 Gallina | 1:00 | | | |
| 12:00 Cierre | 1:00 | | | |
| **Total** | **13:00** | | | |

Repetirlo **una semana antes** de la fecha de la exposición con la versión entregada. Además, **grabar la demo en vídeo** (la barra de juegos de Windows, `Win+G`, o OBS) como copia del plan B y guardarla en la memoria USB (no va al repositorio por tamaño).

## 7. Preguntas que pueden hacer y cómo responder

- **¿`assert`/`retract` no es impuro?** Sí. Se aísla en un único módulo, `estado.pl`, que es el único que escribe; todo lo demás son consultas puras que devuelven los efectos como datos. Es el límite explícito entre estado y reglas, y las pruebas comprueban que consultar, explicar o diagnosticar no cambia el estado.
- **¿El corte rompe lo declarativo?** Solo se usa en la IA enemiga, donde el orden de prioridad *es* la especificación; el resto usa `\+` y condiciones explícitas. Y cada regla tiene su gemela sin corte que sirve de oráculo en las pruebas. El meta-intérprete implementa el corte de verdad.
- **¿El meta-intérprete es completo?** Cubre el subconjunto que usa el juego (conjunción, disyunción, if-then-else, negación, `findall`, `forall`, predefinidos, hechos, reglas y corte); rechaza un corte anidado con `corte_no_soportado` y corta la recursión sin fin con `limite_profundidad`. Se prueba por equivalencia con la ejecución directa.
- **¿Cómo sabe que `explicar` no miente?** Prueba de equivalencia: 40 objetivos en 8 escenarios, 971 soluciones, mismas soluciones y mismo orden que ejecutar la meta.
- **¿Por qué los comandos son términos?** Para que el núcleo se pruebe sin consola: `juego:ejecutar/2` devuelve datos y solo `ui` (consola) y `api` (web) escriben.
- **¿Por qué SWI-Prolog 5.10.4?** Es la versión del curso; el proyecto usa solo su subconjunto (sin `yall`, `foldl/4`, `sort/4`...).
- **¿Cómo verificó las pruebas?** Con mutación a mano: rompo el código a propósito y compruebo que falla alguna prueba; los mutantes que sobreviven revelan pruebas que faltan. Y comprobé que cada prueba de regresión *falla sin su arreglo*.
- **¿Qué falta?** `usar`, `huir`, `comer`, más contratos y enemigos, guardar y cargar. El balance es ajustado (la ruta cómoda gana con cero quesos de margen) y un segundo playtest con otra persona quedó pendiente.
- **¿Y la interfaz web?** Un extra: un servidor HTTP mínimo y un adaptador JSON sobre el mismo motor; no tiene reglas.
