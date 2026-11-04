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
| `explicar.` | La prueba lógica, en árbol, de lo último que se hizo (`ir`, `descansar` o `pagar`). |
| `explicar(ir(aldea)).` | La prueba de esa acción: la guardada si es la última; si no, se resuelve ahora. |
| `salir.` | Termina la partida. |

Si la despensa se queda vacía, la partida termina por hambre. Contratos, combate y `por_que_no` aún no están implementados (ver `docs/03-funcionalidades-y-etapas.md`). Los acentos dependen de la consola de Windows (comprobación pendiente en la consola de la entrega).

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
& "C:\Program Files\pl\bin\swipl.exe" -q -s tests/spike_explicar -g "run_tests,halt" -t "halt(1)"
```

Cada punto es una prueba que pasa; el código de salida es 0 si todas pasan y 1 si alguna falla. Suites actuales (210 pruebas):

| Suite | Qué comprueba |
|---|---|
| `tests/mundo_estado.pl` (47) | Los datos del mundo (`src/mundo.pl`) y el estado y los efectos (`src/estado.pl`). |
| `tests/juego.pl` (70) | La compañía, la economía, los comandos (`juego:ejecutar/2`), la interfaz y sesiones completas por la entrada. |
| `tests/pagos.pl` (49) | El informe de la compañía y la huelga, el valor del queso, el inventario, los sueldos y `pagar`, el impago y el comando `explicar`. |
| `tests/explicar_juego.pl` (27) | El meta-intérprete sobre las **reglas reales** del juego (mismas respuestas y orden que la ejecución directa, en 10 estados distintos) y el árbol de texto. |
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
