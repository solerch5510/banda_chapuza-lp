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
| `contratos.` | El tablón: los contratos a la vista con su zona, dificultad, premio y estado (`disponible`, `bloqueado`, `lejos`, `activo`, `por_cobrar` o `cumplido`). |
| `aceptar(Contrato).` | Acepta un contrato (en la taberna o donde lo ofrecen). Hasta 3 a la vez. Si no se puede, el contrato "os mira y decide que no". `explicar(aceptar(Contrato)).` enseña la prueba de por qué se pudo. |
| `elegir(Opcion).` | Elige una opción del evento abierto, por su número o por su nombre (p. ej. `elegir(trepar).` o `elegir(1).`). `mirar.` vuelve a enseñar las opciones. Un evento se abre al aceptar su contrato en su zona o al llegar a ella con el contrato activo. |
| `atacar(Objetivo).` | Solo en combate: golpea con el miembro al que le toca. El objetivo es un tipo (`bandido_torpe`) o una instancia (`e(bandido_torpe, 1)`). |
| `defender.` | Solo en combate: sube la defensa del miembro al que le toca hasta su próximo turno. |
| `habilidad(Objetivo).` / `habilidad.` | Solo en combate: la habilidad del miembro al que le toca. Baldomero: **Carga Heroica** (el golpe + 4). Pimentina: **Fondue Flamígera** (8 de daño que ignora la defensa; gasta 1 queso, el más rancio). Tuerca: **Rebuscar Bolsillos** (1 queso si el enemigo lo lleva; una vez por enemigo). Rufino: **Balada Inspiradora** (+1 de moral a toda la compañía; se escribe `habilidad.`, sin objetivo). |
| `explicar.` | La prueba lógica, en árbol, de lo último que se hizo (`ir`, `descansar`, `pagar`, `atacar`, `defender`, `habilidad` o la decisión de un enemigo). Tras el turno de un enemigo cuenta **por qué hizo eso** (la regla de su IA que ganó, con su corte) y **por qué no hizo otra cosa** (por qué no se aplicó ninguna regla de mayor prioridad). |
| `explicar(ir(aldea)).` | La prueba de esa acción: la guardada si es la última; si no, se resuelve ahora. |
| `por_que_no(Accion).` | **Por qué NO se puede** una acción: la regla que falla, lo que sí se cumplía antes y, si falla una negación (`\+`), el hecho que la impide. Ejemplos: `por_que_no(aceptar(gallina_noble)).` (el miedo de Baldomero a los caballos), `por_que_no(atacar(bandido_montado)).` en combate, `por_que_no(ir(castillo)).`, `por_que_no(descansar).` Si la acción sí se puede, lo dice. No cambia nada. |
| `nivel(resumido).` / `nivel(detallado).` | Cuánto detalle tienen `explicar` y `por_que_no`. **Resumido** (el de partida): el árbol plegado a lo esencial (`[+N nodos]`; un ataque cabe en 15 líneas) y solo la cláusula más cercana. **Detallado**: el árbol entero, todas las cláusulas aplicables y, si falla una negación, la prueba de por qué es cierto lo que niega (de dónde sale el miedo de Baldomero). |
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

En combate manda cada miembro en su turno (`mirar.` dice de quién es y cuánta vida tiene cada enemigo); los enemigos actúan solos, al ganar hay botín y moral, y los caídos se levantan con 1 de vida. `explicar.` justifica lo último que pasó, también las decisiones de los enemigos. **La escolta de Lady Clotilde:** al aceptar `gallina_noble` en el Camino Real, en cada ronda del combate el primer enemigo que actúa se ceba con ella (anota un golpe y no ataca a la Banda). Con 2 golpes o menos, éxito (14 quesos y un brie); con 3 o 4, a medias (la mitad); con 5 o más, fracaso (−3 quesos y −2 de moral; se puede reintentar). Cuanto antes acabes el combate, menos plumas pierde. Todavía no están implementados el narrador completo ni los finales de nivel Objetivo.

## Pruebas

Las pruebas usan `plunit`. Desde la raíz del repositorio (PowerShell), con el ejecutable por su ruta completa, cada suite se ejecuta por separado:

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/mundo_estado -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/juego -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/pagos -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/explicar_juego -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/narrador -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/combate -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/acciones -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/bucle -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/ia -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/contratos -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/cierre -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/eventos -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/campana -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/diagnosticos -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/habilidades -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/escolta -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/por_que_no -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/turno_enemigo -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/niveles -g "run_tests,halt" -t "halt(1)"
```

```
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/spike_explicar -g "run_tests,halt" -t "halt(1)"
```

Cada punto es una prueba que pasa; el código de salida es 0 si todas pasan y 1 si alguna falla. Suites actuales (1466 pruebas):

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
| `tests/niveles.pl` (63) | Los niveles `resumido`/`detallado` (comando `nivel`, el ajuste de sesión y cómo cambian `explicar`, `por_que_no` y la decisión de un enemigo) y `por_que_no` v2: varias cláusulas aplicables, la prueba de por qué es cierto lo que una negación niega y las negaciones anidadas (`\+ \+ X`). |
| `tests/turno_enemigo.pl` (55) | `explicar` tras el turno de un enemigo (demostración central 3): plegar el árbol a lo esencial, las reglas de mayor prioridad que no se aplicaron (calculadas al decidir con `por_que_no`) para cada una de las seis reglas de la IA, la pantalla, las frases del narrador y combates enteros explicados turno a turno. |
| `tests/por_que_no.pl` (81) | `por_que_no`, el segundo meta-intérprete: cada forma de diagnóstico con un módulo de juguete (`tests/spike/toy_diag.pl`), las dos demostraciones centrales (el miedo de Baldomero y la gallina noble), otras reglas del juego (viajar, descansar, pagar, huelga, aturdimiento, fila, hechizo), que las claves del narrador salgan igual que con los diagnósticos a mano, y el comando y su pantalla. |
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
├─ src/             código fuente (12 módulos)
├─ tests/           pruebas (plunit)
└─ examples/        partidas y explicaciones de ejemplo
```

Los 12 módulos de `src/`:

| Módulo | Función |
|---|---|
| `main.pl` | Punto de entrada y bucle principal del juego. |
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

## Contexto académico

Proyecto final individual de la asignatura **Programación Declarativa**. Aplica hechos y reglas, unificación, resolución SLD, corte y negación, aritmética, metaprogramación y base de datos dinámica de Prolog. Fecha de entrega: 11 de diciembre de 2026.

## Autor

[@solerch5510](https://github.com/solerch5510)
