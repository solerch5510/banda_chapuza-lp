# banda_chapuza-lp

**Banda Chapuza** es un RPG ligero de texto en el que diriges una compañía de mercenarios de saldo: contratas misiones absurdas, gestionas quesos (la moneda y la comida a la vez), sueldos y moral, y peleas por turnos. Está escrito íntegramente en **Prolog** como proyecto final de Programación Declarativa: el estado del mundo son hechos, las reglas del juego son cláusulas y un meta-intérprete permite preguntar `explicar` o `por_que_no` para ver, con la voz de un narrador sarcástico, el árbol de derivación detrás de cada acción.

> Estado: en desarrollo. El diseño (canon) está en [docs/DISENO.md](docs/DISENO.md), revisado el 2 de noviembre de 2026.

## Características previstas

- Compañía de mercenarios con rasgos que modifican las reglas del juego.
- Economía del queso: es la única moneda; maduración, ración diaria, sueldos (`pagar`) y moral.
- Contratos con recompensa y consecuencias.
- Combate por turnos con filas (frente y retaguardia) y enemigos con IA por reglas.
- **Modo explicar:** `explicar(Accion)` y `por_que_no(Accion)` muestran la prueba SLD de cada acción (`arbol(Accion)` en el nivel objetivo).

## Alcance

| Nivel | Contenido |
|---|---|
| **Mínima** (compromiso de entrega) | 4 contratos, 5 enemigos, unas 70 frases del narrador, 16 comandos y 3 finales. Incluye las demostraciones centrales: `por_que_no(atacar(baldomero, bandido_montado))`, `por_que_no(aceptar(gallina_noble))` y `explicar` sobre un turno enemigo con corte. |
| **Objetivo** (si hay tiempo) | 6 contratos, 7 enemigos, unas 120 frases, comandos `nivel`, `arbol`, `usar`, `huir`, `comer` y `demo`, y 5 finales. |
| **Extra** (ampliación futura) | Resto de contratos y enemigos, tienda de objetos, `guardar`/`cargar`, reclutas y comandos en palabras. No forma parte de la entrega. |

## Requisitos

- [SWI-Prolog](https://www.swi-prolog.org/) **5.10.4** (la versión del curso). El código usa solo predicados disponibles en esa versión.

## Ejecución

En Windows, SWI-Prolog 5.10.4 suele instalarse en `C:\Program Files\pl\bin`, que no está en el `PATH`. Hay dos opciones:

- Llamar al ejecutable con la ruta completa, desde la raíz del repositorio (PowerShell):

  ```
  & "C:\Program Files\pl\bin\swipl.exe" -q -s src/main -g main -t halt
  ```

- O añadir `C:\Program Files\pl\bin` al `PATH` y escribir:

  ```
  swipl -q -s src/main -g main -t halt
  ```

Nota: en la 5.10.4 para Windows, una ruta relativa con extensión como último argumento (`swipl -q -s src/main.pl`) falla con "script_file does not exist". Funcionan `src/main` (sin extensión), la ruta absoluta o poner otra opción después, por ejemplo `-s src/main.pl -g halt`.

### Estado del juego

Se puede **recorrer el mapa, gestionar la compañía y pedir explicaciones**. Cada comando se escribe como un término de Prolog **terminado en punto**:

| Comando | Qué hace |
|---|---|
| `ayuda.` | Lista los comandos disponibles ahora. |
| `mirar.` | Describe la zona, las salidas, el día y el queso que queda. |
| `ir(aldea).` | Viaja a una zona conectada; cuesta un día (el queso madura y cada miembro come una unidad). Salir de la taberna sin haber pagado los sueldos baja la moral. |
| `descansar.` | Solo en la taberna: cuesta 2 quesos, cura a todos, +1 de moral y pasa un día. |
| `pagar.` | Solo en la taberna: paga los sueldos pendientes (5 quesos) empezando por los más rancios. Llegar a la taberna deja sueldos pendientes. |
| `compania.` | Los miembros: vida, ataque, defensa, moral, fila, sueldo, rasgo y estado (en pie, huelga o caído). |
| `inventario.` | La despensa lote a lote (con la edad y la categoría del queso) y los objetos. |
| `contratos.` | El tablón: los contratos a la vista con su zona, dificultad, premio y estado (`disponible`, `bloqueado`, `lejos`, `activo`, `por_cobrar` o `cumplido`) y, debajo de cada uno, su chiste. |
| `aceptar(Contrato).` | Acepta un contrato (en la taberna o donde lo ofrecen). Hasta 3 a la vez. Si no se puede, el contrato "os mira y decide que no". `explicar(aceptar(Contrato)).` enseña la prueba de por qué se pudo. |
| `elegir(Opcion).` | Elige una opción del evento abierto, por su número o por su nombre (p. ej. `elegir(trepar).` o `elegir(1).`). `mirar.` vuelve a enseñar las opciones. Un evento se abre al aceptar su contrato en su zona o al llegar a ella con el contrato activo. |
| `atacar(Objetivo).` | Solo en combate: golpea con el miembro al que le toca. El objetivo es un tipo (`bandido_torpe`) o una instancia (`e(bandido_torpe, 1)`). |
| `defender.` | Solo en combate: sube la defensa del miembro al que le toca hasta su próximo turno. |
| `habilidad(Objetivo).` / `habilidad.` | Solo en combate: la habilidad del miembro al que le toca. Baldomero: **Carga Heroica** (el golpe + 4). Pimentina: **Fondue Flamígera** (8 de daño que ignora la defensa; gasta 1 queso, el más rancio). Tuerca: **Rebuscar Bolsillos** (1 queso si el enemigo lo lleva; una vez por enemigo). Rufino: **Balada Inspiradora** (+1 de moral a toda la compañía; se escribe `habilidad.`, sin objetivo). |
| `explicar.` | La prueba lógica, en árbol, de lo último que se hizo (`ir`, `descansar`, `pagar`, `atacar`, `defender`, `habilidad` o la decisión de un enemigo). Tras el turno de un enemigo cuenta **por qué hizo eso** (la regla de su IA que ganó, con su corte) y **por qué no hizo otra cosa** (por qué no se aplicó ninguna regla de mayor prioridad). |
| `explicar(ir(aldea)).` | La prueba de esa acción: la guardada si es la última; si no, se resuelve ahora. |
| `por_que_no(Accion).` | **Por qué NO se puede** una acción: la regla que falla, lo que sí se cumplía antes y, si falla una negación (`\+`), el hecho que la impide. Ejemplos: `por_que_no(aceptar(gallina_noble)).` (el miedo de Baldomero a los caballos), `por_que_no(atacar(bandido_montado)).` en combate, `por_que_no(ir(castillo)).`, `por_que_no(descansar).` Si la acción sí se puede, lo dice. No cambia nada. |
| `nivel(resumido).` / `nivel(detallado).` | Cuánto detalle tienen `explicar` y `por_que_no`. **Resumido** (el de partida): el árbol plegado a lo esencial (`[+N nodos]`; un ataque cabe en 15 líneas) y solo la cláusula más cercana. **Detallado**: el árbol entero, todas las cláusulas aplicables y, si falla una negación, la prueba de por qué es cierto lo que niega (de dónde sale el miedo de Baldomero), más hasta tres notas del narrador sobre nodos del árbol (`  · …`). |
| `salir.` | Termina la partida. |

**La partida mínima ya se puede jugar de principio a fin.** Si la despensa se queda vacía y no hay nada por cobrar, la partida termina por hambre; si caen los cuatro miembros en un combate, termina en derrota; y si se derrota al Gran Roquefort, se gana con el final `chapuza`.

**Una ruta posible (unos 7 días):**

```
aceptar(ratas_del_granero).   aceptar(gato_en_el_arbol).
ir(aldea).                    % empieza el combate de las ratas; ganarlo con atacar(rata_quesera). y defender.
elegir(trepar).               % el evento del gato (da la venda de caballos)
ir(taberna).  pagar.          % se cobra solo; los sueldos, con pagar
ir(camino_real).              % ahora se puede aceptar a la gallina
aceptar(gallina_noble).       % empieza la escolta (2 bandidos torpes y el montado)
ir(castillo).  aceptar(despensa_real).
ir(camino_real).  ir(cuevas). % el Gran Roquefort
```

En combate manda cada miembro en su turno (tras cada orden se ve de quién es el siguiente turno y cuánta vida tiene cada enemigo; `mirar.` lo repite); los enemigos actúan solos, al ganar hay botín y moral, y los caídos se levantan con 1 de vida. `explicar.` justifica lo último que pasó, también las decisiones de los enemigos. **La escolta de Lady Clotilde:** al aceptar `gallina_noble` en el Camino Real, en cada ronda del combate el primer enemigo que actúa se ceba con ella (anota un golpe y no ataca a la Banda). Con 2 golpes o menos, éxito (14 quesos y un brie); con 3 o 4, a medias (la mitad); con 5 o más, fracaso (−3 quesos y −2 de moral; se puede reintentar). Cuanto antes acabes el combate, menos plumas pierde. Todavía no están implementados el narrador completo ni los finales de nivel Objetivo.

## Demostración

Para la exposición hay cinco **escenas** preparadas de antemano, para no depender de jugar desde cero. Se piden con un meta-comando (no es un comando del juego: es una ayuda para presentarlo):

```
demo.               lista las escenas
demo(economia).     el queso madura (min. 3:00)
demo(combate).      el miedo de Baldomero (min. 5:00)
demo(ia).           la IA enemiga y el corte (min. 9:30)
demo(gallina).      Lady Clotilde y el miedo a los caballos (min. 11:00)
demo(venda).        continuación: Baldomero con la venda de caballos
```

Cada escena parte de una partida nueva (salvo `venda`, que continúa la actual), así que es reproducible, y termina con una lista de comandos sugeridos para probar. En `examples/` están los guiones de comandos y sus **transcripciones guardadas** (ver [examples/README.md](examples/README.md)); para pasar la demostración entera de golpe:

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s src/main -g main -t halt < examples/demo-comandos.txt
```

## Frontend web (extra opcional)

El juego también se puede jugar desde un navegador: `src/servidor.pl` es un servidor HTTP mínimo (solo biblioteca estándar de SWI-Prolog) que no contiene reglas del juego; recibe la orden escrita, la pasa por el mismo `ejecutar/2` de siempre y devuelve JSON (`src/api.pl`).

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s src/servidor -g "servidor(8080)" -t halt
```

| Ruta | Qué hace |
|---|---|
| `GET /api/estado` | Estado completo: banda, despensa, zona, mapa, contratos, combate y **acciones** (cada una habilitada o con el motivo de por qué no). |
| `POST /api/orden` | Cuerpo `{"orden": "ir(aldea)."}`; devuelve `{orden, items, estado}`. También `GET /api/orden?orden=...`. |
| `POST /api/nueva` | Partida nueva. |
| `GET /api/escenas` | Las escenas de la demostración. |
| `GET /...` | Los archivos estáticos de `web/`. |

El árbol de `explicar` y `por_que_no` sale como lista plana de **nodos** con profundidad, estado (`ok`/`no`/`info`), tipo (`hecho`, `calculo`, `negacion`, `regla`, `corte`…) y pliegue, construidos a partir de las mismas líneas que enseña la consola. La consola sigue siendo la versión de referencia (y el plan B de la exposición).

## Pruebas

Las pruebas usan `plunit`. **Una sola orden** las corre todas (desde la raíz del repositorio, con el ejecutable por su ruta completa porque no está en el PATH):

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/todas -g "run_tests,halt" -t "halt(1)"
```

Cada suite corre en su propio proceso (así ninguna contagia a otra), se escribe una línea por suite y un resumen, y el **código de salida es 0 si todo pasa y 1 si algo falla** (en ese caso se enseña el final de lo que dijo la suite que falla). Para correr solo algunas: `-g "run_tests([combate, ia]),halt"`. Una suite concreta, sin el agregador:

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/combate -g "run_tests,halt" -t "halt(1)"
```

Suites actuales (1720 pruebas):

| Suite | Qué comprueba |
|---|---|
| `tests/mundo_estado.pl` (61) | Los datos del mundo y el bestiario (`src/mundo.pl`) y el estado y los efectos (`src/estado.pl`). |
| `tests/juego.pl` (70) | La compañía, la economía, los comandos (`juego:ejecutar/2`), la interfaz y sesiones completas por la entrada. |
| `tests/pagos.pl` (49) | El informe de la compañía y la huelga, el valor del queso, el inventario, los sueldos y `pagar`, el impago y el comando `explicar`. |
| `tests/explicar_juego.pl` (27) | El meta-intérprete sobre las **reglas reales** del juego (mismas respuestas y orden que la ejecución directa, en 10 estados distintos) y el árbol de texto. |
| `tests/combate.pl` (166) | Los rasgos del héroe (el miedo de Baldomero, `puede_atacar/2`, las reglas de fila, los hechizos de cocina de Pimentina), el estado de combate (niveles de moral, iniciativa, orden de turnos, `iniciar_combate`, rondas y turnos) y el daño (`dano/3` con moral, miedo, venda y defensa; `efectos_golpe/3`); y que el meta-intérprete lo explica igual que se ejecuta. |
| `tests/acciones.pl` (105) | Las acciones del jugador en combate: el efecto `alterar`, `efectos_accion/3`, el paso de los estados, los comandos `atacar` y `defender` (turno, objetivos, fases, errores sin efecto) y su prueba guardada para `explicar`. |
| `tests/bucle.pl` (73) | El combate de principio a fin: fin de combate (victoria y derrota), `terminar_combate` (los caídos se levantan con 1), el turno enemigo, el bucle de turnos y rondas, lo que ve el jugador y `explicar` tras un turno enemigo. |
| `tests/ia.pl` (75) | La IA enemiga: las seis reglas por prioridad con corte (`curarse`, `invocar_moho`, `robar_queso`, `embestir`, `atacar`, `defender`), cada acción como efectos, su gemela sin corte (el oráculo) en 15 escenarios, la lección del corte rojo y la IA dentro del bucle de combate. |
| `tests/contratos.pl` (143) | Los cuatro contratos de la versión mínima como datos, qué contratos se ven y cuáles se pueden aceptar (`puede_aceptar/1` y sus cinco condiciones), los efectos `contrato_aceptar` y `visitar`, los comandos `contratos` y `aceptar` y su prueba para `explicar`. |
| `tests/cierre.pl` (102) | Cómo acaba un contrato: `resultado/3` (éxito, a medias o fracaso según contadores y marcas), sus consecuencias, el cobro automático al llegar a la taberna, el combate que empieza al llegar a la zona de un contrato activo, y partidas completas de aceptar a cobrar. |
| `tests/eventos.pl` (110) | El motor mínimo de eventos y el comando `elegir`: cuándo se abre el evento del gato, sus opciones y cuáles están disponibles, los intentos, qué pasa al elegir cada una, cómo se resuelve el contrato con las marcas que dejan y la cadena gato → venda → gallina. |
| `tests/campana.pl` (39) | La partida mínima de principio a fin: los finales (`chapuza`, `derrota_combate`, `derrota_hambre`), la fase final, partidas completas escritas como una lista de comandos (se gana en 7 días y es reproducible) y que `pelear` ya no existe. |
| `tests/equivalencia.pl` (42) | **La prueba de equivalencia del meta-intérprete**: más de 20 objetivos del juego (compañía, economía, combate, contratos, fase, negación, `->`, aritmética, `findall`, `forall`) × 8 escenarios (inicio, hambre, huelga, combate con rasgos, con venda, el jefe, contratos en marcha, partida acabada): ejecutarlos directamente y con `solve/2` da las **mismas soluciones en el mismo orden**; el oráculo del corte (IA con corte = IA sin corte), la prueba de modo, los casos de error y que demostrar no cambia el estado. |
| `tests/todas.pl` | El agregador: corre todas las suites en procesos separados y devuelve 0 o 1. |
| `tests/api.pl` (70) | El adaptador JSON y el servidor: el árbol como nodos (profundidad, estado, tipo, pliegue), todos los items con su JSON, `ejecutar_orden/2` (errores como la consola, nunca falla), estado y acciones habilitadas ciertos y sin tocar la partida, **lo que cuenta la web es lo que cuenta la consola**, y el servidor HTTP real (GET, POST, UTF-8, estáticos, 404, rutas fuera de `web/`, cerrojo). |
| `tests/agregador.pl` (4) | Vigila a `tests/todas.pl`: una suite buena da verde, una que falla da código 1, **también si falla con `assertion/1`** (en 5.10.4 eso abre el depurador y el proceso sale con 0). |
| `tests/demo.pl` (35) | La demostración reproducible: las cinco escenas (se montan, dejan el estado que dicen y dan siempre la misma pantalla), `demo.` y la escena desconocida, los guiones de `examples/` y que **lo guardado coincide carácter a carácter con lo que el juego produce ahora** (si cambia una frase hay que regenerar). |
| `tests/playtest.pl` (45) | El primer playtest guiado convertido en pruebas: la partida completa por la vía cómoda (se gana, en pocos días y comandos, sin pantallas crudas ni errores y reproducible), las tres rutas degeneradas (no pagar, ignorar la comida, contratos sin condiciones) y los ajustes que salieron de él: el estado del combate tras cada orden, el día y la ración, las variantes que rotan de verdad y las pistas de `por_que_no`. |
| `tests/banco.pl` (56) | El banco de frases del narrador, sano como conjunto: tamaño, marcas `~w` y argumentos, textos sin repetir, claves con identificadores que existen (detecta erratas), cobertura de las reglas explicables y de los casos reales de `por_que_no` (con frase propia, no la genérica), rotación de las frases frecuentes, comentarios de nodo del nivel detallado y el chiste de cada contrato. |
| `tests/niveles.pl` (64) | Los niveles `resumido`/`detallado` (comando `nivel`, el ajuste de sesión y cómo cambian `explicar`, `por_que_no` y la decisión de un enemigo) y `por_que_no` v2: varias cláusulas aplicables, la prueba de por qué es cierto lo que una negación niega y las negaciones anidadas (`\+ \+ X`). |
| `tests/turno_enemigo.pl` (55) | `explicar` tras el turno de un enemigo (demostración central 3): plegar el árbol a lo esencial, las reglas de mayor prioridad que no se aplicaron (calculadas al decidir con `por_que_no`) para cada una de las seis reglas de la IA, la pantalla, las frases del narrador y combates enteros explicados turno a turno. |
| `tests/por_que_no.pl` (82) | `por_que_no`, el segundo meta-intérprete: cada forma de diagnóstico con un módulo de juguete (`tests/spike/toy_diag.pl`), las dos demostraciones centrales (el miedo de Baldomero y la gallina noble), otras reglas del juego (viajar, descansar, pagar, huelga, aturdimiento, fila, hechizo), que las claves del narrador salgan igual que con los diagnósticos a mano, y el comando y su pantalla. |
| `tests/escolta.pl` (41) | La escolta de Clotilde: la regla (un golpe por ronda al primer enemigo que actúa), el aviso, el turno enemigo con su prueba guardada y el `explicar` de la escolta, el resultado por umbrales (2 / 4 / 5), el fracaso con reintento y que los demás combates no cuentan golpes. |
| `tests/habilidades.pl` (82) | Las habilidades: la tabla de datos `efecto_habilidad/2`, las reglas `puede_habilidad/2` y `/3`, los efectos de la carga, la fondue, la balada y rebuscar, el comando `habilidad` (errores sin efecto, prueba guardada, `explicar`), las pantallas y combates enteros jugados con habilidades. |
| `tests/diagnosticos.pl` (63) | Del diagnóstico de `por_que_no` a la frase: `claves_de_diag/2` y `comentario_diag/4` con diagnósticos escritos a mano (`neg_viola`, `fallo`, `tras`, `ninguna`, `sin_clausula`, `builtin_falso`, `limite`), las claves del núcleo (huelga, aturdido, fila, hechizo, viaje, descanso, contrato, miedo a los caballos) y las frases de reserva. |
| `tests/narrador.pl` (44) | El narrador: el banco de frases, la clave más específica, la rotación de variantes, los niveles, los nombres con artículo, las frases genéricas y el comentario de `explicar`. |
| `tests/spike_explicar.pl` (17) | El meta-intérprete de `src/explicar.pl`, con dos módulos de juguete (`tests/spike/`). |

Se ejecutan en procesos distintos porque los módulos de juguete del spike exportan nombres (como `vida/2`) que chocarían con los de `estado`.

## Estructura

```
banda_chapuza-lp/
├─ README.md
├─ docs/            documentación de diseño
├─ src/             código fuente (15 módulos)
├─ tests/           pruebas (plunit)
└─ examples/        partidas y explicaciones de ejemplo
```

Los 15 módulos de `src/`:

| Módulo | Función |
|---|---|
| `main.pl` | Punto de entrada, bucle principal y el meta-comando `demo` (y la transcripción de sesiones para `examples/`). |
| `demo.pl` | Las escenas de la demostración (datos): estados del juego preparados para la exposición. |
| `juego.pl` | Orquestación de comandos: valida el comando y lo ejecuta con `ejecutar/2`. |
| `estado.pl` | Estado dinámico: único módulo que escribe en la base de datos y aplica efectos. |
| `mundo.pl` | Zonas, conexiones y hechos estáticos. |
| `compania.pl` | Personajes, rasgos y moral. |
| `economia.pl` | Queso, comida, sueldos y maduración. |
| `contratos.pl` | Contratos y sus reglas. |
| `combate.pl` | Turnos, filas, daño e IA enemiga. |
| `eventos.pl` | Eventos cómicos. |
| `explicar.pl` | Meta-intérprete, árbol de derivación y modo explicar. |
| `narrador.pl` | Frases del narrador. |
| `ui.pl` | Entrada y salida por consola (único módulo con E/S). |
| `api.pl` | Adaptador JSON (gemelo de `ui` para la web): estado, resultados, árbol de `explicar` como nodos y acciones habilitadas. No escribe nada. |
| `servidor.pl` | Servidor HTTP mínimo sobre `api.pl` (extra opcional): `/api/estado`, `/api/orden`, `/api/nueva`, `/api/escenas` y los archivos de `web/`. |

Documentos en `docs/`:

| Archivo | Contenido |
|---|---|
| [DISENO.md](docs/DISENO.md) | Documento de diseño (canon). |
| [01-lore-y-ambientacion.md](docs/01-lore-y-ambientacion.md) | Lore y ambientación. |
| [02-arquitectura-codigo.md](docs/02-arquitectura-codigo.md) | Arquitectura del código. |
| [03-funcionalidades-y-etapas.md](docs/03-funcionalidades-y-etapas.md) | Funcionalidades, calendario y etapas. |
| [04-guion-y-contratos.md](docs/04-guion-y-contratos.md) | Guion y contratos. |
| [05-comedia-y-narracion.md](docs/05-comedia-y-narracion.md) | Comedia y narración. |
| [06-revision-y-decisiones.md](docs/06-revision-y-decisiones.md) | Revisión de coherencia y decisiones. |
| [07-playtest-1.md](docs/07-playtest-1.md) | Primer playtest completo (PT-1): resultados, ajustes y observaciones de balance. |

## Contexto académico

Proyecto final individual de la asignatura **Programación Declarativa**. Aplica hechos y reglas, unificación, resolución SLD, corte y negación, aritmética, metaprogramación y base de datos dinámica de Prolog. Fecha de entrega: 11 de diciembre de 2026.

## Autor

[@solerch5510](https://github.com/solerch5510)
