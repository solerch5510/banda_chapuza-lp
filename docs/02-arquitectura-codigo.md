# Banda Chapuza — Arquitectura del código

> Documento 02 de la fase de diseño · Repositorio: `banda_chapuza-lp` · Lenguaje: Prolog (**SWI-Prolog 5.10.4**, la versión del curso)
>
> Estado: **borrador v0.2** (revisado el 2 de noviembre de 2026). Complementa a [DISENO.md](DISENO.md) (canon) y a `01-lore-y-ambientacion.md` (IDs concretos de zonas, personajes, enemigos y objetos). Entrega del proyecto: 11 de diciembre de 2026.

> **Revisado el 2 de noviembre de 2026 tras `docs/06`: alineado con las decisiones aceptadas** (D-03 a D-33; los cambios obligatorios por usar SWI-Prolog 5.10.4 de 06 §2.8; los nombres canónicos de 06 §2.7). Los cambios concretos están en la tabla "Registro de cambios de la revisión" al final. Resumen de lo que cambia respecto a v0.1:
>
> - **12 módulos** (los 10 del canon + `estado` + `juego`); el parser (v1) vive en `juego`/`ui` y la presentación del árbol dentro de `explicar`.
> - Un **comando es un término** validado y ejecutado por `juego:ejecutar/2`; **solo `estado.pl` escribe** en la base de datos.
> - **Un único vocabulario de efectos** (§4.5), con traductores de los formatos de 04 y 05.
> - `solve/2` implementa el **corte real**; la prueba de viabilidad (spike) ya está hecha y **funciona en 5.10.4** (§6.4-6.5).
> - Moral **0-10**, 12 quesos iniciales, `pagar` como comando, ración *fresco → curado → rancio*, caídos solo en combate.
> - Recorte "Nivel A" de 06 §5: lo demás sigue en el documento marcado **(extra)**.

## 0. Cómo leer este documento

- **Versión mínima (lo que se compromete).** 12 módulos; 16 comandos (`ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir`) más el meta-comando `demo` de `main`; 4 contratos, 5 enemigos, unas 70 frases; `solve/2` con corte real, `ultima_prueba/2`, `por_que_no/2`, el oráculo "IA con corte ≡ IA sin corte" y la prueba de equivalencia. Todo lo demás está marcado **(extra)** (o **(objetivo)** si solo entra con colchón, según 06 §5.1).
- **Las dos demostraciones centrales de la exposición** son `por_que_no(atacar(baldomero, bandido_montado))` y `por_que_no(aceptar(gallina_noble))`, más `explicar` sobre un turno enemigo con corte. Todo recorte se hace respetándolas (§6.9, §8.6, §14).
- **Estado de los fragmentos de código.** Cada bloque lleva una etiqueta: **"probado en 5.10.4"** (se cargó y ejecutó con SWI-Prolog 5.10.4 el 2 de noviembre de 2026, con scripts temporales fuera del repositorio) o **"boceto sin ejecutar"**. Los bloques probados son los críticos: meta-intérprete y `por_que_no` (§6), generador pseudoaleatorio (§4.4), efectos y transacción (§4.5), traductores de efectos (§4.5), ración, sueldos, impago y huelga (§5.5), lectura y validación de comandos (§7.1), `ejecutar/2` (§5.4) y selección de frases (§3.10). En los probados, la única diferencia con lo ejecutado es el recorte de datos de ejemplo.
- **`[verificar]`** marca cualquier dato sobre SWI-Prolog del que aún no hay certeza. Lo ya comprobado está en §13.
- **`(extra)`** marca lo prescindible; **`(objetivo)`** lo que entra solo si el colchón de la semana 5 está intacto el viernes 27 de noviembre.
- Los identificadores del código van en ASCII `snake_case` (`dano`, no `daño`). La prosa lleva tildes.
- Los IDs concretos de zonas, personajes, enemigos y objetos los define `01-lore-y-ambientacion.md`. Aquí solo se usan los ejemplos que ya están en `DISENO.md` (`taberna`, `baldomero`, `bandido_torpe`, `cheddar`, `gallina_noble`…).
- Los **nombres** de predicados siguen la tabla canónica de 06 §2.7 en todas las firmas y ejemplos (`puede_viajar/1`, `puede_habilidad/2`, `esta_en_huelga/1`, `permite_combate/1`, `alterado/3` + `aturdido/1`, `lleva/3` + `equipado/2`, `miembro/1`, `activo/1`, `en_pie/1`, `contrato_cerrado/2`, `categoria_queso/2`, `queso_total/1`, `condicion_cumple/1`, `aplicar_efectos/1`).

---


## 1. Principios

### 1.1 Los ocho principios

| # | Principio | Consecuencia concreta |
|---|---|---|
| P1 | **Lógica separada de entrada/salida.** | Solo `ui.pl` lee y escribe en consola o en archivos. Ningún otro módulo llama a `write/1`, `format/1,2`, `nl/0`, `read/1`, `open/3`. (`format(atom(A), ...)` para *construir* texto sí vale: no hace E/S real.) |
| P2 | **Módulos puros de reglas.** | Los módulos de reglas (`compania`, `economia`, `contratos`, `combate`, `eventos`) exportan *relaciones*: consultan hechos y devuelven términos. No escriben en la base de datos ni imprimen. |
| P3 | **Estado centralizado (D-04).** | Todos los `:- dynamic` viven en `estado.pl` y **solo ese módulo** llama a `assert*`/`retract*`. Los `actualizar_*` que mencionan 03 y 04 son **auxiliares privados de `estado`**, llamados desde `aplicar_efecto/1`: ningún otro módulo los ve ni los llama. El resto lee los hechos dinámicos como cualquier otro hecho. |
| P4 | **Calcular efectos / aplicar efectos.** | Una acción del juego se resuelve en dos fases: una *regla pura* devuelve una lista de **efectos** (datos) y `estado:aplicar_efectos/1` los ejecuta. Así la regla se puede explicar, probar y repetir sin tocar el estado. |
| P5 | **Reglas explicables.** | Las reglas del juego usan un subconjunto del lenguaje (§1.3) que el meta-intérprete sabe recorrer. Lo que el meta-intérprete no entiende se trata como hoja. |
| P6 | **Datos antes que código.** | Catálogos, parámetros de balance, prioridades de la IA enemiga y frases del narrador son *tablas de hechos*. Cambiar el balance o el humor no toca reglas. |
| P7 | **Modos y determinismo documentados.** | Cada predicado exportado declara modos (`+`, `-`, `?`) y determinismo (`det`, `semidet`, `nondet`). Las reglas no dependen del orden de las cláusulas, salvo la IA por prioridades (§6.12). |
| P8 | **Legible como especificación.** | Los nombres imitan el español hablado (`puede_atacar/2`, `esta_en_huelga/1`). El código de reglas debe poder leerse en voz alta (objetivo 4 de `DISENO.md`). |

### 1.2 Qué es declarativo y dónde se admiten efectos

| Zona | Qué contiene | ¿Declarativa? | Efectos permitidos |
|---|---|---|---|
| Hechos estáticos (`mundo`, catálogos) | Zonas, personajes base, enemigos, parámetros | Sí | Ninguno (se cargan con el programa) |
| Reglas (`compania`, `economia`, `contratos`, `combate`, `eventos`) | Consultas y cálculo de efectos | Sí | Ninguno |
| Meta-nivel (`explicar`) | Meta-intérprete, diagnósticos, conversión de pruebas a líneas de texto | Sí (programa sobre programas) | Ninguno; `explicar` solo *lee* cláusulas con `clause/2` |
| Narrador (`narrador`) | Frases (tabla de hechos estáticos `frase/3`) y selección de variantes | Sí, **puro** (D-25) | Ninguno: recibe como argumentos el nivel, el día, la semilla y los contadores de uso |
| Estado (`estado`) | `assert`/`retract` de hechos dinámicos; contadores del narrador | **No** (contenido) | **Único** módulo con escritura en la base de datos |
| Orquestación (`juego`) | Validación de comandos (parser v1), casos de uso: compone reglas + aplica efectos | Mixta | Solo llama a `estado:aplicar_efectos/1`; no hace E/S |
| E/S (`ui`, arranque de `main`) | Leer, escribir, archivos | **No** (contenido) | **Único** módulo con E/S |

Las tres excepciones controladas al paradigma lógico puro son, por tanto: la escritura en la base de datos (en `estado`), la E/S (en `ui`) y la semilla del generador pseudoaleatorio, que es un hecho dinámico más (§4.4) y se actualiza a través de `estado`. No se usan variables globales (`nb_setval`, `b_setval`) ni `random/1`: el azar es determinista y reproducible (§4.4).

### 1.3 Subconjunto del lenguaje permitido en las reglas

Se aplica a los módulos `compania`, `economia`, `contratos`, `combate`, `eventos` y a los hechos de `estado`/`mundo`.

| Categoría | Construcciones |
|---|---|
| **Permitido** | Hechos y reglas; conjunción `,`; disyunción `;`; negación `\+`; comparaciones y aritmética (`is`, `<`, `=<`, `=:=`, `max/2`, `min/2`, `mod`, `//`); unificación `=`, `\=`, `==`; `findall/3`; `forall/2`; `member/2`, `memberchk/2`, `append/3`, `length/2`, `nth0/3`, `nth1/3`, `msort/2`, `sort/2`, `between/3`, `last/2`; términos de datos y listas. |
| **Con cuidado** | `( Cond -> Then ; Else )` (el meta-intérprete lo soporta; preferible escribir dos cláusulas con condiciones excluyentes). `\+` solo sobre variables ya ligadas, salvo variables *locales* de la propia negación (§6.12). |
| **Solo en un sitio** | El corte `!` únicamente en las cláusulas de la IA enemiga (`combate:accion_enemigo/2`), siempre al nivel superior del cuerpo, un solo corte por cláusula. |
| **Prohibido** | `assert*`/`retract*` fuera de `estado`; `write`, `format/1,2`, `read`, `open`; `bagof/setof` con `^` (se usa `findall` + `sort`); `once/1` (esconde un corte); `call/N` con metas construidas con `=..` (salvo utilidades marcadas); `nb_setval/b_setval`; `var/1`, `nonvar/1` en reglas de dominio. **Además, por usar 5.10.4 (06 §2.8):** nada de `predicate_property(_, defined)`, `random_between/3`, `random_member/2`, `yall` (`>>`), `foldl/4`, `sum_list/2`, `max_member/2`, `sort/4`, `split_string/4`, `atom_string/2`, `read_term_from_atom/3` ni cadenas con comillas dobles (son listas de códigos): el texto va siempre en átomos con comillas simples. |

Un *linter* (`explicar:verificar_reglas/1`, §6.12) recorrería las cláusulas con `clause/2` y avisaría de violaciones. **(extra)**: en la versión mínima las reglas de estilo se revisan a mano.

---

## 2. Mapa de módulos y dependencias

### 2.1 Módulos y responsabilidades

**Decisión D-07: 12 módulos.** Los diez de `DISENO.md §10` más **dos nuevos**, `estado` y `juego`. El parser (versión 1) no es un módulo: la validación de comandos vive en `juego` y la lectura de términos en `ui`. La presentación del árbol (antes `arbol`) vive dentro de `explicar`. Las frases viven en `narrador`. Separar `parser`, `arbol` o `frases` en archivos propios es una opción **(extra)** que solo se toma si el archivo crece mucho (orientación: `explicar.pl` o `narrador.pl` por encima de ~300-400 líneas), sin cambiar nada más de la arquitectura.

| Módulo | Capa | ¿Canon? | Responsabilidad |
|---|---|---|---|
| `mundo` | Datos | sí | Hechos estáticos: zonas y conexiones, catálogo de personajes base, rasgos, enemigos, clases, objetos, tipos de queso, **parámetros de balance** (`parametro/2`) y valores iniciales (`inicio/1`). Sin reglas de juego, salvo la simetría de las conexiones. |
| `estado` | Datos | **nuevo** | Declaraciones `:- dynamic`; creación y reinicio del estado; `aplicar_efectos/1`; invariantes (vida ≥ 0, cantidad ≥ 0…); transacciones; contadores del narrador; `fase/1` derivada; generador pseudoaleatorio (`tirada/4`). Volcado y restauración para guardar/cargar **(extra)**. |
| `compania` | Reglas | sí | Quién es miembro / activo / en pie, atributos efectivos, rasgos (`teme/2`, `ignora_miedo/1`), nivel de moral y huelga. |
| `economia` | Reglas | sí | Queso: categoría por edad, despensa, `queso_total/1`; ración diaria (fresco → curado → rancio); sueldos (`puede_pagar_sueldos/0`), descanso (`puede_descansar/0`); efectos de comer. |
| `contratos` | Reglas | sí | Catálogo `contrato/5`; disponibilidad, condiciones, aceptación; resultado (éxito, fracaso, a medias) y consecuencias; cobro; traductor de los efectos de 04 (`expandir_contrato/3`). |
| `combate` | Reglas | sí | Combatientes, filas, iniciativa, `puede_atacar/2`, `dano/3`, resolución de acciones como efectos, IA enemiga por prioridades, `permite_combate/1`, fin de combate. |
| `eventos` | Reglas | sí | Evento de arranque de 04 (`elegir/1`, motor mínimo) y, **(objetivo)**, eventos aleatorios de 05; traductor de los efectos de 05 (`expandir_evento/2`). |
| `explicar` | Meta | sí | `solve/2,3` (meta-intérprete), `por_que_no/2`, `clave_de_diag/2` y la presentación del árbol (`prueba_a_lineas/2`, `diag_a_lineas/2`: texto ASCII, niveles). Produce **términos** (pruebas y diagnósticos) y **listas de líneas**, no E/S. Linter, `.dot` y árbol SLD real son **(extra)**. |
| `narrador` | Presentación pura | sí | Tabla `frase/3`, nombres visibles y selección de variantes a partir de una clave, un nivel y un contador de uso que le pasan. Sin E/S y **sin estado propio** (D-25). |
| `juego` | Control | **nuevo** | Validación de comandos (parser v1); casos de uso: `ejecutar/2` traduce cada comando en reglas + efectos; transiciones de fase; paso del día; avance de turnos de combate; condiciones de los gags (contexto para el narrador). Devuelve un `Resultado` (término), no imprime. |
| `ui` | E/S | sí | Único con E/S: leer términos, escribir líneas, mostrar un `Resultado` (con `narrador` y `explicar`), codificación de la consola, archivos (**extra**). |
| `main` | Arranque | sí | Punto de entrada y bucle principal; meta-comandos `salir` y `demo` (`reiniciar`, `guardar`, `cargar` son **extra**). |

**Justificación de los módulos nuevos**

- **`estado`**: P3 exige un único escritor. Sin él, los `dynamic` se repartirían entre `economia`, `compania`, `combate`… y cada uno haría `assert`; reiniciar y las transacciones serían imposibles de centralizar. `DISENO.md §9.2` ya pide "un único punto de control" con `actualizar_*`; este módulo es ese punto y los `actualizar_*` son sus auxiliares privados.
- **`juego`**: sin él, la orquestación (aplicar un comando, pasar el día, encadenar turnos) acabaría en `main` (mezclada con E/S, intestable) o dentro de las reglas (rompiendo P2). Es el *único* sitio donde se compone "regla pura → efectos → estado".
- **Sin `parser`**: 06 D-07. El parser v1 son ~20 líneas (§7.1) y se prueba sin consola porque `validar_comando/2` recibe un término ya leído. El parser v2 de palabras sueltas es **(extra)** y, si se hace, nace como `parser.pl`.
- **Sin `arbol`**: la conversión de pruebas a líneas de texto cabe en `explicar` (§6.11) y la exportación `.dot` es **(extra)**.

### 2.2 Dependencias (quién importa a quién)

`A → B` significa que `A` hace `:- use_module(B)`.

| Módulo | Importa |
|---|---|
| `mundo` | — |
| `narrador` | — |
| `explicar` | — (sin imports internos: accede por nombre a los módulos de juego con `clause/2` en tiempo de ejecución) |
| `estado` | `mundo` |
| `compania` | `mundo`, `estado` |
| `economia` | `mundo`, `estado`, `compania` |
| `contratos` | `mundo`, `estado`, `compania`, `economia` |
| `combate` | `mundo`, `estado`, `compania`, `economia` |
| `eventos` | `mundo`, `estado`, `compania`, `economia` |
| `juego` | `mundo`, `estado`, `compania`, `economia`, `contratos`, `combate`, `eventos`, `explicar` |
| `ui` | `narrador`, `explicar`, `estado` (solo lectura de contadores y ajustes) |
| `main` | `ui`, `juego`, `estado` |

```
                                   main
                    +---------------+---------------+
                    |               |               |
                    v               v               v
                   ui             juego           estado --> mundo
                +--+--+             |
                |  |  |             |
                v  v  v             +--> explicar     (meta-nivel; sin imports internos)
        narrador explicar estado    |
                                    +--> eventos ----+
                                    +--> combate ----+--> economia --> compania --> estado --> mundo
                                    +--> contratos --+
                                    +--> (y directamente: economia, compania, estado, mundo)
```

**Sin ciclos, por capas.** Un módulo solo importa de capas inferiores:

| Capa | Módulos |
|---|---|
| 0 | `mundo`, `narrador`, `explicar` |
| 1 | `estado` |
| 2 | `compania` |
| 3 | `economia` |
| 4 | `contratos`, `combate`, `eventos` |
| 5 | `juego`, `ui` |
| 6 | `main` |

Reglas derivadas que evitan ciclos en la práctica:

1. **`estado` no conoce las reglas.** No importa `compania` ni `combate`. Sus invariantes se limitan a lo que se puede decir con `mundo` (por ejemplo, `vida_max` de un personaje) y con aritmética.
2. **Las reglas no imprimen ni llaman a `juego`.** Si una regla "quiere decir algo", emite un efecto `mensaje(Clave, Args)` y `ui` lo traduce.
3. **Los efectos son datos**, así que un módulo de capa baja puede *pedir* algo a uno de capa alta sin importarlo (p. ej. `eventos` pide `iniciar_combate(Grupo)` y `juego` lo ejecuta).
4. **Prueba de arquitectura** (`tests/test_arquitectura.pl`, §11.5) **(extra)**: recorrería `predicate_property(M:H, imported_from(D))` de todos los exportados y comprobaría que cada arista respeta la tabla de capas.

### 2.3 Colisiones de nombres

Dos módulos que exportan el mismo `nombre/aridad` provocan error o aviso de importación. Regla: **cada nombre exportado es único en todo el proyecto**. Los predicados que operan sobre entidades de varios módulos (`vivo/1`, `ataque/2`, `defensa/2`, `vida/2`) viven en uno solo y se importan donde hagan falta. Consecuencia ya aplicada: los traductores de efectos se llaman `contratos:expandir_contrato/3` y `eventos:expandir_evento/2` (no ambos `expandir`), y el predicado de zona es `permite_combate/1` mientras que el de personaje es `puede_combatir/1` (06 X-14).

---

## 3. API pública por módulo

Convenciones: `+` entrada ligada, `-` salida, `?` indistinto. Determinismo: `det` (siempre una solución, sin dejar puntos de elección), `semidet` (0 o 1), `nondet` (0..n). Los nombres exactos pueden cambiar al implementar; la *forma* de la API es lo que se compromete. Los nombres siguen la tabla canónica de 06 §2.7.

### 3.1 `mundo` (hechos estáticos; todos `nondet` al consultarse)

| Predicado | Modo | Descripción |
|---|---|---|
| `zona/2` | `zona(?Id, ?Nombre)` | Zona y su nombre visible (`zona(taberna, 'Taberna del Cuajo Torcido')`). |
| `conexion/2` | `conexion(?A, ?B)` | Arista del mapa, escrita en un solo sentido (canon). |
| `adyacente/2` | `adyacente(?A, ?B)` | Simetría de `conexion/2`: `conexion(A,B) ; conexion(B,A)`. |
| `zona_pacifica/1` | `zona_pacifica(?Zona)` | Zonas donde la ley prohíbe el combate (`taberna`). Lo consulta `combate:permite_combate/1`. |
| `personaje/7` | `personaje(?Id, ?Nombre, ?Rol, ?vida(V), ?ataque(A), ?defensa(D), ?sueldo(S))` | Catálogo de personajes base. |
| `fila_preferida/2` | `fila_preferida(?Id, ?Fila)` | `frente` o `retaguardia`. |
| `rasgo/2` | `rasgo(?Id, ?Rasgo)` | Canon: `rasgo(baldomero, teme_caballos)`. |
| `habilidad_de/2` | `habilidad_de(?Id, ?Habilidad)` | Una habilidad por personaje en la versión mínima (D-23); dos para Pimentina y Rufino son **(extra)**. |
| `enemigo/4` | `enemigo(?Tipo, ?vida(V), ?ataque(A), ?defensa(D))` | Canon. |
| `clase/2` | `clase(?Tipo, ?Clase)` | Clase de un tipo de enemigo (`caballo`, `humano`…). |
| `alcance/2`, `lleva_queso/1` | `alcance(?Tipo, ?cuerpo_a_cuerpo \| distancia)`, `lleva_queso(?Tipo)` | Atributos de 01 (06 X-23): alimentan la regla de filas y el botín. |
| `objeto/3`, `efecto_objeto/2`, `bonus/3` | `objeto(?Id, ?Nombre, ?Efecto)` … | Objetos (mínima: `venda_de_caballos`, `pocion`). |
| `tipo_queso/2` | `tipo_queso(?Tipo, ?ValorBase)` | Quesos existentes y su valor base (el valor solo informa: se paga por unidades, D-13). Mínima: `cheddar`, `brie`. |
| `parametro/2` | `parametro(?Nombre, ?Valor)` | **Constantes de balance** (umbrales de edad, de moral, daños de hambre…). |
| `inicio/1` | `inicio(?Dato)` | Valores iniciales de partida (zona, día, compañía, quesos, semilla). |

### 3.2 `estado`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| (hechos dinámicos) | ver §4.2 | nondet | `en_zona/1`, `dia/1`, `vida/2`, `moral/2`, `queso/3`, `marca/1`, `contador/2`, `usos_frase/2`… exportados para *lectura*. |
| `nueva_partida/0` | — | det | `reiniciar_estado/0` + carga de `mundo:inicio/1` (§4.3). |
| `reiniciar_estado/0` | — | det | Borra todos los hechos dinámicos (§4.3). |
| `aplicar_efectos/1` | `+Efectos` | det | Aplica una lista de efectos en orden; ignora `mensaje/2`. Lanza excepción ante un efecto desconocido. |
| `aplicar_efecto/1` | `+Efecto` | det | Un efecto. Una cláusula por efecto (vocabulario en §4.5). Los `actualizar_*` privados viven detrás. |
| `con_transaccion/1` | `:Meta` | semidet | Ejecuta `Meta` con *instantánea*; si falla o lanza excepción, restaura el estado (§10). |
| `tirada/4`, `siguiente_semilla/2` | ver §4.4 | det | Generador pseudoaleatorio puro (probado). |
| `fase/1` | `?Fase` | semidet | `exploracion`, `combate`, `taberna`, `fin` (derivada, §5.2). |
| `vida_max/2` | `vida_max(+Id, -V)` | semidet | Tope de vida: del catálogo (`mundo:personaje/7`) o, para `e(Tipo,N)`, de `mundo:enemigo/4` vía `instancia/2`. |
| `volcar_estado/1`, `restaurar_estado/1` | — | det / semidet | **(extra)** Guardado y carga (§9). |

### 3.3 `compania`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `miembro/1` | `miembro(?Id)` | nondet | Membresía (`en_compania/1`). |
| `vivo/1` | `vivo(?Id)` | semidet | `vida(Id, V), V > 0` (vale para personajes y enemigos). |
| `activo/1` | `activo(?Id)` | nondet | `miembro(Id)` y `vivo(Id)`. |
| `en_pie/1` | `en_pie(?Id)` | nondet | `activo(Id)` y no en huelga. |
| `teme/2` | `teme(?Id, ?Clase)` | nondet | `teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A).` (D-19; probado). |
| `ignora_miedo/1` | `ignora_miedo(+Id)` | semidet | `equipado(Id, venda_de_caballos)`. |
| `nivel_moral/2` | `nivel_moral(+Id, -Nivel)` | semidet | Con moral 0-10: `alta` (≥ 8), `normal` (4-7), `baja` (2-3), `critica` (0-1), provisional. |
| `esta_en_huelga/1` | `esta_en_huelga(+Id)` | semidet | `moral(Id, M), parametro(moral_huelga, U), M =< U`, con `U = 2` (D-08). Derivada solo de la moral (06 X-25). |
| `puede_combatir/1` | `puede_combatir(+Id)` | semidet | Personaje vivo y no en huelga. (No confundir con `combate:permite_combate/1`, de zona.) |
| `moral_media/1` | `moral_media(-M)` | semidet | Media entera de la moral de los `activo/1`. |
| `modificador_moral/2` | `modificador_moral(+Id, -M)` | det | Modificador de ataque por nivel: alta +1, normal 0, baja −1, crítica −2 (provisional, 06 X-24). |
| `sueldo_de/2` | `sueldo_de(+Id, -S)` | semidet | Sueldo base (1+2+1+1 = 5 por pago). |
| `puede_viajar/1` | `puede_viajar(+Zona)` | semidet | `en_zona(A)`, `adyacente(A, Zona)` y la partida no ha terminado (no exige combatientes: evita bloqueos sin salida, §10.2). Meta explicable de `ir/1`. |

### 3.4 `economia`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `categoria_queso/2` | `categoria_queso(+Edad, -Cat)` | det | `fresco` (0–2), `curado` (3–9), `rancio` (≥ 10), umbrales desde `parametro/2`. |
| `queso_total/1` | `queso_total(-N)` | det | Unidades totales de la despensa. |
| `hay_queso_para/1` | `hay_queso_para(+N)` | semidet | `queso_total(T), T >= N`. |
| `despensa/1` | `despensa(-Lista)` | det | `[q(Tipo, Edad, Cant), ...]` en **orden de ración**: fresco → curado → rancio; dentro de cada categoría, el más viejo primero (D-11; probado). |
| `valor_queso/3`, `valor_despensa/1` | — | det | Solo para presentación: el pago es por unidades (D-13). |
| `total_sueldos/1`, `puede_pagar_sueldos/0` | `puede_pagar_sueldos` | semidet | Regla explicable de `pagar` (D-14): hay queso para cubrir los sueldos de los `activo/1`. |
| `puede_descansar/0` | — | semidet | En la taberna y `hay_queso_para(2)` (D-15). Regla explicable de `descansar`. |
| `efectos_racion/1` | `efectos_racion(-Efectos)` | det | Un queso por miembro activo (fresco → curado → rancio); sin queso: hambre; rancio: penalización de moral. |
| `efectos_sueldos/1` | `efectos_sueldos(-Efectos)` | det | Paga con lo **más rancio primero**; solo se llama si `puede_pagar_sueldos/0`. |
| `efectos_descanso/1` | `efectos_descanso(-Efectos)` | det | Gasta 2 quesos; cura a los activos; +1 de moral. |
| `puede_comer/2`, `efectos_comer/3` | `(+Id, +Tipo)` / `(+Id, +Tipo, -Efectos)` | semidet | `comer`: **ración extra voluntaria** con el efecto del tipo (v1: cura 2; D-12), nivel "Debería". |

### 3.5 `contratos`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `contrato/5` | `contrato(?Id, ?Zona, ?Objetivo, ?Recompensa, ?Condiciones)` | nondet | Catálogo, aridad 5 del canon (D-18). Vocabulario de objetivos de 04; en la mínima solo `eliminar`, `derrotar`, `evento`, `escoltar`. `recompensa(Lista)` con `recompensa(quesos(N))` como abreviatura. |
| `resolucion/3` | `resolucion(?Id, ?Res, ?Condiciones)` | nondet | Datos de 04: condiciones de cada resultado, probadas en orden. |
| `disponible/1` | `disponible(?Id)` | nondet | Contrato ofrecido en la zona actual y no tomado. |
| `puede_aceptar/1` | `puede_aceptar(+Id)` | semidet | Disponible y todas las condiciones se cumplen (máx. 3 activos). Es el objetivo que `por_que_no/1` explica. |
| `condicion_cumple/1` | `condicion_cumple(+Cond)` | semidet | Una condición (`requiere(rasgo_no(R))`…). Nombre de 02 (04 la llamaba `cumple/1`). |
| `via_objetivo/2` | `via_objetivo(+Id, -Via)` | semidet | Cómo se cumple: `combate(Grupo)` o `evento(Id)` (`eliminar` y `derrotar` → `combate`; `evento` y `escoltar` → `combate` con contador de golpes a Clotilde, §8.1). |
| `resultado/3` | `resultado(+Id, +Contexto, -Res)` | semidet | Regla: `exito`, `fracaso`, `a_medias`. `Contexto` = lista de `contador/2` y `marca/1` registrados durante el contrato (06 X-39); en la mínima, dos condiciones medibles. |
| `consecuencias/3` | `consecuencias(+Id, +Res, -Efectos)` | det | Efectos del cierre, ya traducidos al vocabulario de §4.5. |
| `contrato_cumplido/1`, `contrato_exito/1`, `contratos_cumplidos/1` | — | semidet / det | Derivados de `contrato_cerrado/2` (06 X-18). La condición es `contratos_cumplidos_min(N)`. |
| `efectos_cobro/1` | `efectos_cobro(-Efectos)` | det | Cobro **automático** de los contratos pendientes al llegar a la taberna. |
| `expandir_contrato/3` | `(+Contrato, +Efecto04, -Efectos)` | semidet | Traductor de los efectos de 04 (§4.5). |

### 3.6 `combate`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `permite_combate/1` | `permite_combate(+Zona)` | semidet | `\+ zona_pacifica(Zona)`. Se explica como `\+ permite_combate(taberna)`. |
| `efectos_inicio/2` | `efectos_inicio(+Grupo, -Efectos)` | det | Crea instancias de enemigos, filas, ronda 1, cola de turnos. |
| `orden_turnos/1` | `orden_turnos(-Ids)` | det | Vivos ordenados por iniciativa (desc.), desempate determinista. |
| `iniciativa/2` | `iniciativa(+Id, -I)` | det | Valor derivado (§8.3). |
| `ataque/2`, `defensa/2` | `ataque(+Id, -V)` | semidet | Atributo efectivo (base + rasgos + moral + estados). |
| `en_fila_alcanzable/2` | `(+A, +B)` | semidet | Reglas de fila (§8.2). |
| `puede_atacar/2` | `(+A, +B)` | semidet | Canon (`DISENO.md §9.3`). **Demostración 1** de la exposición. |
| `dano/3` | `dano(+A, +B, -D)` | semidet | `D is max(1, Atq - Def + M)`. |
| `efectos_accion/3` | `efectos_accion(+Actor, +Accion, -Efectos)` | semidet | Resuelve `atacar(O)`, `defender`, `habilidad(O)` (**objetivo**: `usar(Obj, O)`, `huir`). Falla si la acción no es legal. |
| `puede_habilidad/2` | `(+A, +O)` | semidet | Habilidad de `mundo:habilidad_de/2` legal (nombre canónico; antes `puede_usar_habilidad`). |
| `efecto_habilidad/2` | `efecto_habilidad(+Hab, -Efectos)` | det | Tabla de datos con las fórmulas de cada habilidad (06 X-43). |
| `accion_enemigo/2` | `accion_enemigo(+E, -Accion)` | det (con corte) | IA por prioridades: las 3 reglas del canon + **como máximo tres acciones especiales** (`robar_queso`, `embestir`, `invocar_moho`), cada una con su cláusula y su gemela (D-24). |
| `accion_enemigo_sin_corte/2` | `(+E, -Accion)` | det | Gemela declarativa, oráculo de la prueba de equivalencia (§6.12). |
| `puede_actuar/1` | `(+Id)` | semidet | Vivo y no en huelga. |
| `vida_baja/1`, `tiene/2`, `objetivo_mas_debil/2` | ver §8.5 | semidet | Auxiliares de la IA. |
| `fin_combate/1` | `fin_combate(-Res)` | semidet | `victoria` o `derrota` (todos los miembros caídos). |

### 3.7 `eventos`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `evento_campana/…` y `opcion_evento/3` | — | nondet | Motor mínimo para `gato_en_el_arbol` y `elegir/1` (04): una escena con opciones numeradas y efectos. |
| `expandir_evento/2` | `(+Efecto05, -Efectos)` | semidet | Traductor de los efectos de 05 (§4.5). |
| `evento/3`, `posible/1`, `evento_del_dia/3`, `efectos_evento/2` | — | nondet | **(objetivo)**: eventos aleatorios de 05 (5 en el objetivo, sin duplicar los de 04; D-28). `evento_del_dia(+S0, -Evento, -S1)` elige con `tirada/4` (nada de `random_*`). |

### 3.8 `explicar`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `solve/2` | `solve(:Meta, -Prueba)` | nondet | Mismas soluciones que `call(Meta)`, en el mismo orden, más el término de prueba. Corte real (§6.5). |
| `solve/3` | `solve(:Meta, -Prueba, +Opciones)` | nondet | Opciones: `limite(N)`; `muestra(K)`, `llamada(Bool)` son **(extra)** (§6.7). |
| `por_que_no/2` | `por_que_no(:Meta, -Diag)` | semidet | Falla si `Meta` es demostrable; si no, el diagnóstico (§6.9). |
| `clave_de_diag/2` | `clave_de_diag(+Diag, -Clave)` | semidet | Traduce un diagnóstico a la clave del narrador: `neg_viola(_, P)` → `impide(Hecho)`; `fallo`/`tras` → `falla(Meta)` (06 X-21). Se escribe antes de T-15. |
| `prueba_a_lineas/2`, `diag_a_lineas/2` | `(+Prueba, -Lineas)` | det | Árbol de texto ASCII (lista de átomos). Probado (§6.11). |
| `resumir/3` | `resumir(+Prueba, +Nivel, -Resumen)` | det | Poda según `resumido`/`detallado` **(objetivo)**. |
| `por_que_no_clausula/3` | `(:Meta, +I, -Diag)` | semidet | Como `por_que_no/2` para la cláusula `I` (descartes de la IA, §8.6) **(extra)**. |
| `verificar_reglas/1`, `prueba_a_dot/2`, `arbol_sld/3` | — | det | Linter, Graphviz y árbol SLD real: **(extra)**. |

### 3.9 Presentación del árbol (dentro de `explicar`)

Antes era el módulo `arbol`; por D-07 sus funciones puras (`prueba_a_lineas/2`, `diag_a_lineas/2`, `resumir/3`, `estadisticas/3`, `prueba_a_dot/2`, `diag_a_dot/2`) viven en `explicar.pl`. Si `explicar.pl` supera las ~400 líneas, se separan sin cambiar su API. Solo las dos primeras forman parte de la versión mínima.

### 3.10 `narrador`

Puro y sin estado propio (D-25). Las claves siguen la forma `frase(+Clave, +Nivel, +Plantilla)` de 05 §7 (`frase/3`, **estática**: `clause/2` funciona igual que con dinámicos).

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `frase/3` | `frase(?Clave, ?Nivel, ?Plantilla)` | nondet | Tabla de frases. Claves: `Meta`, `falla(Meta)`, `impide(Hecho)`, `suceso(T)`, `evento(Id, D)`, `gag(Id)`, `generica(T)`, y para el texto visible `texto(dialogo(Npc, Tema))`, `texto(final(Id))`, `texto(consejo(Id))`, `texto(zona(Id))` (06 X-07). |
| `nombre/2` | `nombre(+Id, -Texto)` | det | Nombre visible; normaliza `e(T, _)` a `T` (06 X-19); si no hay, el ID tal cual. |
| `comentario/4` | `comentario(+Clave, +Nivel, +Uso, -Texto)` | semidet | La plantilla de la clave más específica; la variante es `Uso mod N`. **`Uso` lo da `juego`** (contador en `estado`). Probado. |
| `comentario_prueba/4`, `comentario_diag/4` | `(+Prueba, +Nivel, +Uso, -Texto)` | det | Elige el nodo más relevante y delega en `comentario/4`; genérica si no hay frase. |

La rotación de variantes necesita un contador por grupo de clave: vive en `estado` como `usos_frase/2` y lo incrementa el efecto `uso_frase(Grupo)`. Las condiciones de los gags **(extra)** se evalúan en `juego` (que sí ve el estado) y se pasan al narrador como lista de candidatos. Si 05 llama `quitar_estado`, `descanso_gag` o `ultimo_dia_gag` a algo, en esta arquitectura es un `contador/2` o un efecto del §4.5.

```prolog
% narrador.pl -- probado en 5.10.4 (con :- encoding(utf8). tras la cabecera del modulo)
:- discontiguous frase/3.
:- encoding(utf8).

frase(suceso(llegada(taberna)), ambos, 'Mantecosa os recibe: «Los sueldos, jefe. Nadie combate sin cobrar».').
frase(suceso(llegada(Z)), ambos, 'Llegáis a ~w. Nadie sabe por qué.'-[Z]).
frase(suceso(llegada(Z)), ambos, 'Otra vez ~w. Huele a queso.'-[Z]).
frase(suceso(error(comando_desconocido)), ambos, 'Eso no es un comando. Ni siquiera es una excusa.').
% ...
nombre_visible(taberna, 'la Taberna del Cuajo Torcido').
nombre(e(T, _), N) :- nombre(T, N).      % normaliza instancias (06 X-19)
nombre(Id, N) :- Id \= e(_, _), ( nombre_visible(Id, N0) -> N = N0 ; N = Id ).

% comentario(+Clave, +Nivel, +Uso, -Texto): puro. Uso = veces que ya se narró este grupo.
comentario(Clave, Nivel, Uso, Texto) :-
    findall(NV-T,
            (   clause(frase(K, N, Plantilla), true),
                nivel_aplica(N, Nivel),
                term_variables(K, Vs), length(Vs, NV),
                K = Clave,
                formatear(Plantilla, T)
            ),
            Ternas),
    Ternas = [_|_],
    keysort(Ternas, [NV0-_|_]),
    findall(T, member(NV0-T, Ternas), Textos),
    length(Textos, L),
    I is Uso mod L,
    nth0(I, Textos, Texto).

nivel_aplica(ambos, _).
nivel_aplica(N, N).
formatear(Fmt-Args, T) :- !, format(atom(T), Fmt, Args).
formatear(T, T).
```

Para el texto probado, `comentario(suceso(llegada(taberna)), ambos, 0, T)` elige el hecho de **cero variables** (más específico) y `comentario(suceso(llegada(aldea)), ambos, U, T)` alterna entre las dos variantes según `U mod 2` (comprobado: `Llegáis a aldea…` / `Otra vez aldea…`). Las comillas `« »` y las tildes salen bien por tubería con `set_stream(user_output, encoding(utf8))`.

### 3.11 Parser (sin módulo propio)

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `juego:validar_comando/2` | `(+Termino, -Res)` | det | Versión 1: `Res = ok(Comando)` o `error(Motivo)`. Probado (§7.1). |
| `ui:leer_termino/2` | `(-Termino, -Nombres)` | det | Lee un término de la entrada y captura los errores de sintaxis. Probado. |
| `parser:parsear/2`, `normalizar/2` | — | det | **(extra)** Versión 2: palabras sueltas a términos (§7.2). Nacería como `parser.pl`. |

### 3.12 `juego`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `ejecutar/2` | `ejecutar(+Comando, -Resultado)` | det | Valida fase, resuelve, aplica efectos, devuelve el resultado (§5.3-5.4). **Nunca falla ni lanza** (probado: una versión sin red de seguridad fallaba con un comando sin cláusula). |
| `validar_comando/2` | `(+Termino, -Res)` | det | Ver §3.11. |
| `comandos_disponibles/2` | `(+Fase, -Comandos)` | det | Para `ayuda`. |
| `objetivo_de_accion/2` | `(+Accion, -Meta)` | semidet | Traduce una acción a la meta que se explica (§6.2), con entradas también para `descansar` y `pagar`. |
| `verificar_datos/1` | `(-Problemas)` | det | **(objetivo)** Comprueba al arrancar que todo ID referenciado existe. |

`Resultado` es `resultado(Items)` con `Items` lista de: `msg(Clave, Args, Uso)`, `vista(Tipo, Datos)`, `prueba(Meta, Prueba)`, `diag(Meta, Diag)`, `error(Motivo)`, `fase(Nueva)`, `salir`. `Uso` es el contador de rotación **antes** de incrementarlo, de modo que `ui` no escribe nada.

### 3.13 `ui` y `main`

| Predicado | Modo | Det. | Descripción |
|---|---|---|---|
| `ui:iniciar/0` | — | det | `set_stream(user_output, encoding(utf8))`, entrada UTF-8 y `prompt(_, '> ')` (probado). |
| `ui:leer_termino/2` | `(-Termino, -Nombres)` | det | Versión 1; captura errores de sintaxis. |
| `ui:escribir_lineas/1` | `(+Lineas)` | det | Imprime una lista de líneas. |
| `ui:mostrar/1` | `(+Resultado)` | det | Traduce `Resultado` a texto con `narrador` y `explicar`. |
| `ui:escribir_archivo/2`, `escribir_terminos/2`, `leer_terminos/2` | — | det | **(extra)** `.dot` y guardado. |
| `main:main/0` | — | det | Arranque y bucle (§5.1). Meta-comandos mínimos: `salir`, `demo`. |

---

## 4. Esquema de datos

### 4.1 Hechos estáticos

Las formas siguientes son las del canon (`DISENO.md §7 y §9.1`) más las propuestas para los datos que el canon no fija. Los valores son de ejemplo salvo los que fijan las decisiones de 06 (moral 0-10, 12 quesos, huelga ≤ 2); los catálogos reales vienen de `01-lore-y-ambientacion.md`.

```prolog
% --- mundo.pl (probado en 5.10.4 con estos datos de ejemplo) ---
zona(taberna, 'Taberna del Cuajo Torcido').          % zona(Id, Nombre)
conexion(taberna, aldea).                            % conexion(A, B), un solo sentido
adyacente(A, B) :- conexion(A, B).
adyacente(A, B) :- conexion(B, A).
zona_pacifica(taberna).                              % \+ permite_combate(taberna)

% personaje(Id, Nombre, Rol, vida(V), ataque(A), defensa(D), sueldo(S))
personaje(baldomero, 'Sir Baldomero', caballero, vida(30), ataque(8), defensa(4), sueldo(1)).
fila_preferida(baldomero, frente).
rasgo(baldomero, teme_caballos).                     % rasgo(Id, Rasgo)

enemigo(bandido_torpe, vida(12), ataque(5), defensa(2)).   % canon
clase(bandido_torpe, humano).                        % clase(TipoEnemigo, Clase)

tipo_queso(cheddar, 2).                              % tipo_queso(Tipo, ValorBase)
objeto(pocion, 'Pocion de suero', curar(10)).        % objeto(Id, Nombre, Efecto)

parametro(edad_curado_min, 3).                       % parametro(Nombre, Valor)
parametro(edad_rancio_min, 10).
parametro(moral_inicial, 6).                         % D-08: moral 0-10, inicio 6
parametro(moral_max, 10).
parametro(moral_huelga, 2).                          % huelga con moral =< 2 (equivale a "< 3")
parametro(coste_descanso, 2).                        % D-15
parametro(moral_impago, 2).                          % D-14: -2 por miembro al salir sin pagar

inicio(zona(taberna)).                               % inicio(Dato)
inicio(dia(1)).
inicio(miembro(baldomero)).
inicio(queso(cheddar, 0, 12)).                       % D-09: 12 cheddar de edad 0
inicio(semilla(12345)).
```

(`parametro/2` y `inicio/1` se agrupan por tema con `:- discontiguous` si se reparten en el archivo: en la prueba SWI avisó de cláusulas no contiguas cuando se añadieron al final.)

```prolog
% --- contratos.pl: el catalogo vive aqui (canon DISENO.md 7; forma de 04, D-18) (boceto sin ejecutar) ---
contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo),
         recompensa([quesos(14), queso(brie, 0, 1)]),
         [requiere(rasgo_no(teme_caballos))]).
% abreviatura aceptada: recompensa(quesos(N)) == recompensa([quesos(N)])
```

Convenciones sobre los datos:

- **`parametro/2` concentra el balance.** Ninguna regla lleva números "mágicos" salvo 0 y 1. Los umbrales de `DISENO.md §6` (0–2 fresco, 3–9 curado, ≥ 10 rancio) son `parametro(edad_curado_min, 3)` y `parametro(edad_rancio_min, 10)`.
- **Las reglas leen `parametro/2`**, de modo que en la prueba aparece el hecho `parametro(edad_rancio_min, 10)`: la explicación muestra *de dónde* sale el umbral.
- **Dos niveles de atributos**: los *base* son hechos estáticos (`personaje/7`, `enemigo/4`); los *efectivos* (`combate:ataque/2`, `combate:defensa/2`) son reglas que suman rasgos, moral y estados.
- **Queso: única moneda y comida, sin tienda en v1 (D-10).** El queso solo *entra* por recompensa de contrato, botín y hallazgos; solo *sale* por ración, sueldos, descanso, habilidades y multas. No hay compra ni venta de queso. La tienda de objetos (a cambio de queso, pagando antes lo más rancio) es **(extra)** y su diseño no afecta a ningún módulo mínimo.
- **Pago por unidades (D-13).** `valor_queso/3` existe para la presentación y la tienda extra; sueldos y recompensas cuentan unidades.

### 4.2 Hechos dinámicos (el estado)

Todos se declaran en `estado.pl`. Forma exacta de cada uno (**boceto sin ejecutar** el conjunto completo; el subconjunto marcado † está en el módulo `estado` probado):

```prolog
% --- estado.pl ---
% PERSISTENTES (en v1 solo se reinician; se guardarian con el guardado (extra))
:- dynamic en_zona/1.            % † en_zona(Zona)
:- dynamic dia/1.                % † dia(N), N entero >= 1
:- dynamic en_compania/1.        % † en_compania(PersonajeId); el orden de insercion = orden de pago
:- dynamic vida/2.               % † vida(Id, V), 0 =< V =< vida_max
:- dynamic moral/2.              % † moral(PersonajeId, M), 0 =< M =< 10   (D-08)
:- dynamic queso/3.              % † queso(Tipo, Edad, Cantidad), Cantidad > 0, (Tipo,Edad) unico
:- dynamic lleva/3.              % † lleva(Id, Objeto, Cantidad); Id = compania para el inventario comun
:- dynamic equipado/2.           % † equipado(Id, Objeto): lo que lleva puesto (venda_de_caballos)
:- dynamic marca/1.              % † marca(Bandera): sueldos_pagados, baldomero_perdona...
:- dynamic contador/2.           % † contador(Clave, N): hechizos, silencios, descansos_gratis, golpes_a_clotilde...
:- dynamic visitada/1.           % visitada(Zona)
:- dynamic consejo_dado/1.       % consejo_dado(Id)
:- dynamic contrato_activo/1.    % contrato_activo(ContratoId)                       (canon)
:- dynamic contrato_por_cobrar/2.% contrato_por_cobrar(ContratoId, Resultado)
:- dynamic contrato_cerrado/2.   % contrato_cerrado(ContratoId, Resultado)
:- dynamic evento_visto/2.       % evento_visto(EventoId, Dia)  (enfriamiento; objetivo)
:- dynamic semilla/1.            % † semilla(S), 0 =< S < 65536
:- dynamic usos_frase/2.         % † usos_frase(Grupo, N): rotacion de variantes del narrador (D-25)
:- dynamic ajuste/2.             % ajuste(Clave, Valor): nivel_explicacion, ascii
:- dynamic fin_partida/1.        % † fin_partida(victoria | derrota(Motivo))

% TRANSITORIOS (solo durante un combate o la sesion)
:- dynamic en_combate/1.         % † en_combate(Ronda)
:- dynamic combatiente/2.        % † combatiente(Id, jugador | enemigo)
:- dynamic instancia/2.          % † instancia(e(Tipo,N), Tipo)
:- dynamic fila/2.               % † fila(Id, frente | retaguardia)
:- dynamic cola_turnos/1.        % cola_turnos([Id, ...]) los que faltan por actuar en la ronda
:- dynamic alterado/3.           % † alterado(Id, Estado, TurnosRestantes): aturdido, defendiendo, cantando (turnos = fijo)
:- dynamic zona_previa/1.        % zona_previa(Zona): a donde se huye (huir es objetivo)
:- dynamic ultima_prueba/2.      % † ultima_prueba(Accion, Prueba)
:- dynamic registro_decision/6.  % (extra) registro_decision(Ronda, Actor, Accion, Indice, Prueba, Descartes)
```

Notas de modelado:

- **Los hechos de otros documentos tienen sitio aquí** (06 X-22): `visitada/1`, `marca/1`, `contador/2`, `equipado/2`, `consejo_dado/1`, y los contadores del narrador (`usos_frase/2`). `descansos_gratis/1` de 04 es `contador(descansos_gratis, N)`; `deuda_taberna/1` queda **descartado** (D-15). Los de los gags de 05 (`descanso_gag/2`, `ultimo_dia_gag/2`, `explicaciones_hoy/1`, `ultimo_suceso/1`) son **(extra)** y se guardarían como `contador/2`.
- **`vida/2` sirve para personajes y enemigos.** Un enemigo en combate se identifica con `e(Tipo, N)` (p. ej. `e(bandido_torpe, 2)`): es el único ID compuesto y permite descomponerlo por unificación, sin construir átomos. El narrador normaliza `e(T,_)` a `T` al buscar la clave y solo añade el número si hay varias instancias del mismo tipo (06 X-19).
- **Quesos**: una fila por `(Tipo, Edad)`. `ganar_queso/3` suma si ya existe; `gastar_queso/3` resta y borra la fila al llegar a 0. Al envejecer, todas las edades suben 1 a la vez, así que nunca se fusionan filas por el paso del tiempo.
- **Huelga, vivo, activo, en pie, rancio, fase** son *derivados* (reglas), no hechos: no pueden quedar inconsistentes con el resto. `en_compania/1` es solo membresía; `activo/1` y `en_pie/1` la refinan.
- **Estados con nombre propio** (06 X-15): el dato es `alterado(Id, Estado, Turnos)`, pero las reglas usan derivados: `aturdido(Id) :- alterado(Id, aturdido, _)`, `cantando/1`, `apestado/1` **(extra)**. Prohibido `estado/2` como nombre.
- **`ajuste/2`** guarda las opciones de sesión (nivel de explicación, salida ASCII forzada).
- **Sueldos pendientes**: no hay hecho `deuda`. La bandera `marca(sueldos_pagados)` se pone al empezar y al ejecutar `pagar`, y se quita al llegar a la taberna; salir de la taberna sin ella es el impago (§5.5).

### 4.3 Inicialización y reinicio

```prolog
% estado.pl (probado en 5.10.4 con el subconjunto †)
persistente(en_zona/1). persistente(dia/1). persistente(en_compania/1). persistente(vida/2).
persistente(moral/2).   persistente(queso/3). persistente(lleva/3).     persistente(equipado/2).
persistente(marca/1).   persistente(contador/2). persistente(usos_frase/2). persistente(semilla/1).
persistente(fin_partida/1).
transitorio(en_combate/1). transitorio(combatiente/2). transitorio(instancia/2).
transitorio(fila/2).       transitorio(alterado/3).    transitorio(ultima_prueba/2).

todo(N/A) :- persistente(N/A).
todo(N/A) :- transitorio(N/A).

reiniciar_estado :-
    forall(todo(N/A), ( functor(C, N, A), retractall(C) )).

nueva_partida :-
    reiniciar_estado,
    forall(mundo:inicio(D), cargar_inicio(D)),
    assertz(marca(sueldos_pagados)).          % al empezar no se debe nada

cargar_inicio(zona(Z))        :- assertz(en_zona(Z)).
cargar_inicio(dia(N))         :- assertz(dia(N)).
cargar_inicio(semilla(S))     :- assertz(semilla(S)).
cargar_inicio(queso(T, E, C)) :- assertz(queso(T, E, C)).
cargar_inicio(miembro(Id))    :-
    mundo:personaje(Id, _, _, vida(V), _, _, _),
    mundo:parametro(moral_inicial, M),
    mundo:fila_preferida(Id, F),
    assertz(en_compania(Id)), assertz(vida(Id, V)), assertz(moral(Id, M)), assertz(fila(Id, F)).
```

- La lista `persistente/1` + `transitorio/1` **es la única fuente de verdad** para reiniciar (y, **(extra)**, volcar y restaurar): añadir un hecho dinámico nuevo obliga a registrarlo ahí (una prueba lo comprueba: todo `dynamic` de `estado` aparece en una de las dos listas).
- Se usan `functor/3` y `retractall/1` (Conf. 6) para tratar los predicados como datos.
- `reiniciar` desde el juego = `estado:nueva_partida/0`; no hace falta reiniciar el intérprete. El comando `reiniciar` es **(extra)**.

### 4.4 Generador pseudoaleatorio determinista

El azar (eventos, desempates cómicos) no usa `random/1` ni `random_between/3` (este último no existe en 5.10.4): usa una semilla en el estado y una **función pura** de avance, de modo que una partida es reproducible byte a byte y una prueba de eventos es exacta (D-25; resuelve 06 O-1).

```prolog
% estado.pl (probado en 5.10.4)
% Generador congruencial x' = (75*x + 74) mod 65537.
siguiente_semilla(S0, S1) :- S1 is (S0 * 75 + 74) mod 65537.

% tirada(+N, +S0, -R, -S1): R en 0..N-1
tirada(N, S0, R, S1) :-
    siguiente_semilla(S0, S1),
    R is S1 mod N.
```

**Propiedades comprobadas** (V-09, 5.10.4): como `x' + 1 = 75 (x + 1) mod 65537` y 65537 es primo, el generador recorre **todo el rango 0..65535 en un ciclo de 65536 pasos** (periodo medido: 65536 desde la semilla 12345); nunca produce valores fuera de 0..65535. **El valor 65536 es un punto fijo degenerado** (`65536 → 65536`), por eso `fijar_semilla/1` normaliza con `mod 65536` (la v0.1 decía `mod 65537` y `0 =< S < 65537`: corregido). Reparto de `R is S1 mod N` sobre un ciclo completo: N=2: 32768/32768; N=4: 16384 por valor; N=10: 6553-6554 por valor; N=100: 655-656 por valor (sesgo ≤ 1 parte en 655). Secuencia desde 12345: 8431, 42566, … (`tirada(4, 12345, …)` da 3, 2, 0, 1, 0, 2, 3, 1, …). Los bits bajos no alternan. Basta para eventos y variantes de frases.

`eventos:evento_del_dia/3` **(objetivo)** recibe `S0`, devuelve `S1`, y `juego` aplica el efecto `fijar_semilla(S1)`. Para elegir de una lista: `length(L, K), tirada(K, S1, I, S2), nth0(I, L, Elegido)`. Para una probabilidad del P %: `tirada(100, S0, R, S1), R + 1 =< P`. Alternativa descartada: `random/1`/`set_random(seed(N))` (existen en 5.10.4 pero no garantizan la misma secuencia entre versiones o máquinas).

### 4.5 Vocabulario de efectos

Los efectos son términos; `estado:aplicar_efecto/1` tiene una cláusula por cada uno. Son la *única* forma en que las reglas modifican el estado (P4). **D-05: este es el único vocabulario**; los efectos de 04 y de 05 se traducen a él (tabla siguiente) con `contratos:expandir_contrato/3` y `eventos:expandir_evento/2`.

| Efecto | Significado | Comprobaciones en `estado` |
|---|---|---|
| `dano(Id, N)` | `vida(Id)` baja `N` | Mínimo 0 |
| `curar(Id, N)` | `vida(Id)` sube `N` | Máximo = vida del catálogo (`mundo:personaje/7`, o `mundo:enemigo/4` vía `instancia/2`) |
| `mod_moral(Id, D)` | Moral cambia `D` | Entre 0 y 10 (`parametro(moral_max, 10)`) |
| `ganar_queso(T, E, N)` / `gastar_queso(T, E, N)` | Despensa | `N > 0`; no baja de 0; `gastar` falla si no hay suficientes |
| `envejecer_quesos` | Todas las edades + 1 | — |
| `envejecer_lote(N)` | Envejece N unidades del lote más curado **(extra)** (de 05 `envejecer_lote_mas_curado`) | — |
| `ganar_objeto(Id, O, N)` / `gastar_objeto(Id, O, N)` | Inventario | No baja de 0 |
| `equipar(Id, O)` | `equipado(Id, O)` (p. ej. la venda) | — |
| `viajar(Zona)` | Cambia `en_zona/1` (guarda `zona_previa/1`) | `adyacente/2` |
| `avanzar_dia` | `dia(N)` → `dia(N+1)` | — |
| `alta(Id)` / `baja(Id)` | Entra o sale de la compañía | — |
| `contrato_aceptar(C)` / `contrato_resolver(C, R)` / `contrato_cobrar(C)` | Ciclo del contrato | Estados válidos |
| `iniciar_combate(Grupo)` | Crea instancias, filas, ronda 1 | Solo fuera de combate |
| `fila(Id, F)` / `alterar(Id, Est, T)` / `quitar_alteracion(Id, Est)` | Combate | — |
| `siguiente_turno` / `siguiente_ronda(Ids)` | Cola de turnos | — |
| `terminar_combate` | Limpia lo transitorio; los caídos se levantan con 1 de vida (D-17) | — |
| `marcar(F)` / `desmarcar(F)` | Banderas (`marca/1`) — **nuevo** (de 04) | — |
| `contar(C, N)` | `contador(C, V)` sube `N` — **nuevo** | — |
| `ganar_descansos(N)` | `contador(descansos_gratis, V)` sube `N` — **nuevo** (de 04) | — |
| `visitar(Z)` | `visitada(Z)` — **nuevo** | — |
| `fijar_semilla(S)` / `visto(Evento)` | Azar (normaliza `mod 65536`) y enfriamiento de eventos | — |
| `uso_frase(Grupo)` | `usos_frase(Grupo, N+1)`: rotación del narrador — **nuevo** (D-25) | — |
| `fin(Motivo)` | Marca el fin de la partida | — |
| `guardar_prueba(Acc, Prueba)` | `ultima_prueba/2` (§6.2) | — |
| `registrar_decision(R, Actor, Acc, I, Prueba, Desc)` | Registro de la IA **(extra)** (§8.6) | — |
| `mensaje(Clave, Args)` | **No toca el estado**: `juego` lo recoge para `ui` | — |

**Traducción de los efectos de 04 y 05** (06 X-03):

| Formato | Efecto original | Se traduce a |
|---|---|---|
| 04 | `cobrar(todo)` / `cobrar(mitad)` | `ganar_queso/3`, `ganar_objeto/3`… de la recompensa del contrato (la mitad entera) más `contrato_cobrar(C)` |
| 04 | `perder_queso(N)` | `gastar_queso/3` del más rancio primero |
| 04 | `moral(grupo, N)` / `moral(P, N)` | un `mod_moral(Id, N)` por miembro `activo/1` / `mod_moral(P, N)` |
| 04 | `marcar(F)`, `descansos_gratis(N)`, `mejora/3` | `marcar(F)`, `ganar_descansos(N)`, `equipar/2` |
| 05 | `quitar_queso(N)`, `quitar_queso_mas_fresco(N)` | `gastar_queso/3` (más rancio / más fresco primero) |
| 05 | `dar_queso(T, E, N)` | `ganar_queso(T, E, N)` |
| 05 | `moral(Quien, D)`, `vida(Quien, D)` | `mod_moral/2`; `curar/2` (D ≥ 0) o `dano/2` (D < 0) |
| 05 | `dar_objeto(O)`, `quitar_estado(Id, E)` | `ganar_objeto(compania, O, 1)`, `quitar_alteracion(Id, E)` |

```prolog
% estado.pl: efectos (probado en 5.10.4; ver tambien la nota sobre transaccion)
% ---- efectos ----
aplicar_efectos([]).
aplicar_efectos([E|Es]) :- aplicar_efecto(E), aplicar_efectos(Es).

aplicar_efecto(mensaje(_, _)).
aplicar_efecto(dano(Id, N)) :- N >= 0, vida(Id, V0), V1 is max(0, V0 - N), set_vida(Id, V1).
aplicar_efecto(curar(Id, N)) :- N >= 0, vida(Id, V0), tope_vida(Id, Max), V1 is min(Max, V0 + N), set_vida(Id, V1).
aplicar_efecto(mod_moral(Id, D)) :-
    moral(Id, M0), mundo:parametro(moral_max, Max), M1 is max(0, min(Max, M0 + D)),
    retractall(moral(Id, _)), assertz(moral(Id, M1)).
aplicar_efecto(ganar_queso(T, E, N)) :- N > 0,
    (   retract(queso(T, E, C0)) -> C1 is C0 + N ; C1 = N ),
    assertz(queso(T, E, C1)).
aplicar_efecto(gastar_queso(T, E, N)) :- N > 0, queso(T, E, C0), C0 >= N, retract(queso(T, E, C0)),
    C1 is C0 - N,
    (   C1 > 0 -> assertz(queso(T, E, C1)) ; true ).
aplicar_efecto(envejecer_quesos) :-
    findall(q(T, E, C), retract(queso(T, E, C)), L),
    forall(member(q(T, E, C), L), ( E1 is E + 1, assertz(queso(T, E1, C)) )).
aplicar_efecto(marcar(F)) :- ( marca(F) -> true ; assertz(marca(F)) ).
aplicar_efecto(desmarcar(F)) :- retractall(marca(F)).
aplicar_efecto(contar(C, N)) :-
    (   retract(contador(C, V0)) -> V1 is V0 + N ; V1 = N ),
    assertz(contador(C, V1)).
aplicar_efecto(ganar_objeto(Id, O, N)) :- N > 0, ( retract(lleva(Id, O, C0)) -> C1 is C0 + N ; C1 = N ), assertz(lleva(Id, O, C1)).
aplicar_efecto(gastar_objeto(Id, O, N)) :- N > 0, lleva(Id, O, C0), C0 >= N, retract(lleva(Id, O, C0)), C1 is C0 - N, ( C1 > 0 -> assertz(lleva(Id, O, C1)) ; true ).
aplicar_efecto(equipar(Id, O)) :- retractall(equipado(Id, O)), assertz(equipado(Id, O)).
aplicar_efecto(avanzar_dia) :- retract(dia(N)), N1 is N + 1, assertz(dia(N1)).
aplicar_efecto(viajar(Z)) :- en_zona(A), mundo:adyacente(A, Z),
    retractall(en_zona(_)), assertz(en_zona(Z)).
aplicar_efecto(fijar_semilla(S)) :- S1 is S mod 65536,
    retractall(semilla(_)), assertz(semilla(S1)).
aplicar_efecto(uso_frase(G)) :- aplicar_efecto_uso(G).
aplicar_efecto(guardar_prueba(A, P)) :- retractall(ultima_prueba(_, _)), assertz(ultima_prueba(A, P)).
aplicar_efecto(E) :- \+ efecto_conocido(E), throw(efecto_invalido(E)).

efecto_conocido(E) :- nonvar(E), functor(E, N, A), conocido(N/A).
conocido(mensaje/2). conocido(dano/2). conocido(curar/2). conocido(mod_moral/2).
conocido(ganar_queso/3). conocido(gastar_queso/3). conocido(envejecer_quesos/0).
conocido(marcar/1). conocido(ganar_objeto/3). conocido(gastar_objeto/3). conocido(desmarcar/1). conocido(contar/2). conocido(equipar/2).
conocido(avanzar_dia/0). conocido(viajar/1). conocido(fijar_semilla/1). conocido(guardar_prueba/2). conocido(uso_frase/1).

set_vida(Id, V) :- retractall(vida(Id, _)), assertz(vida(Id, V)).
tope_vida(Id, Max) :- mundo:personaje(Id, _, _, vida(Max), _, _, _).
tope_vida(e(T, N), Max) :- instancia(e(T, N), T), mundo:enemigo(T, vida(Max), _, _).

% ---- transaccion ----
:- meta_predicate con_transaccion(0).
con_transaccion(Meta) :-
    foto(F),
    (   catch(Meta, E, ( restaurar_foto(F), throw(E) ))
    ->  true
    ;   restaurar_foto(F), fail
    ).
foto(Hs) :- findall(H, ( todo(N/A), functor(H, N, A), call(H) ), Hs).
restaurar_foto(Hs) :- reiniciar_estado, forall(member(H, Hs), assertz(H)).

% efectos del narrador (contadores de rotacion)
aplicar_efecto_uso(Grupo) :-
    (   retract(usos_frase(Grupo, U0)) -> U1 is U0 + 1 ; U1 = 1 ),
    assertz(usos_frase(Grupo, U1)).
```

```prolog
% Traductores (probado en 5.10.4; en la prueba estaban en un solo modulo). Las tres primeras
% clausulas de cada familia viven en contratos:expandir_contrato/3 y las expandir_evento/2 en
% eventos (que reutiliza economia:despensa/1 y compania:activo/1). La receta de la recompensa
% (recompensa_de/2) se lee en realidad de contratos:contrato/5.
% expandir_contrato(+Contrato, +Efecto04, -EfectosCanon)
expandir_contrato(C, cobrar(todo), Es)   :- recompensa_de(C, R), expandir_recompensa(R, Es).
expandir_contrato(C, cobrar(mitad), Es)  :- recompensa_de(C, R), mitad(R, R2), expandir_recompensa(R2, Es).
expandir_contrato(_, perder_queso(N), Es) :- economia:despensa(D0), reverse(D0, D), gastar_rancio(N, D, Es).
expandir_contrato(_, moral(grupo, N), Es) :- findall(mod_moral(Id, N), compania:activo(Id), Es).
expandir_contrato(_, moral(P, N), [mod_moral(P, N)]) :- P \== grupo.
expandir_contrato(_, marcar(F), [marcar(F)]).
expandir_contrato(_, descansos_gratis(N), [contar(descansos_gratis, N)]).

expandir_recompensa([], []).
expandir_recompensa([R|Rs], Es) :- exp_r(R, E1), expandir_recompensa(Rs, E2), append(E1, E2, Es).
exp_r(quesos(N), Es) :- ( N > 0 -> Es = [ganar_queso(cheddar, 0, N)] ; Es = [] ).
exp_r(queso(T, E, N), Es) :- ( N > 0 -> Es = [ganar_queso(T, E, N)] ; Es = [] ).
exp_r(objeto(O), [ganar_objeto(compania, O, 1)]).
mitad([], []).
mitad([quesos(N)|R], [quesos(M)|R2]) :- M is N // 2, mitad(R, R2).
mitad([queso(T,E,N)|R], [queso(T,E,M)|R2]) :- M is N // 2, mitad(R, R2).

gastar_rancio(0, _, []).
gastar_rancio(N, [q(T, E, C)|D], [gastar_queso(T, E, U)|Es]) :- N > 0, U is min(N, C), N1 is N - U, gastar_rancio(N1, D, Es).

expandir_todos(_, [], []).
expandir_todos(C, [E|Es], Out) :- expandir_contrato(C, E, X), expandir_todos(C, Es, Y), append(X, Y, Out).

% 05
expandir_evento(quitar_queso(N), Es) :- expandir_contrato(-, perder_queso(N), Es).
expandir_evento(dar_queso(T, E, N), [ganar_queso(T, E, N)]).
expandir_evento(moral(Q, D), Es) :- expandir_contrato(-, moral(Q, D), Es).
expandir_evento(vida(Q, D), [dano(Q, N)]) :- D < 0, N is -D.
expandir_evento(vida(Q, D), [curar(Q, D)]) :- D >= 0.
```

Notas del traductor, descubiertas al probarlo: (1) una cantidad 0 (p. ej. la mitad de 1 brie) **no** genera `ganar_queso(_, _, 0)`, que `aplicar_efecto/1` rechazaría; (2) `perder_queso` lee la despensa **en el momento de expandir**, así que si va detrás de un `cobrar` en la misma lista se calcularía contra el estado viejo (P4 por etapas, §5.4): `consecuencias/3` expande y aplica **efecto a efecto** (o en etapas), no la lista entera de golpe.

**Invariantes y transacción.** `aplicar_efectos/1` es una conjunción secuencial; un efecto cuya precondición no se cumple falla o lanza `efecto_invalido(E)` (efecto desconocido). `con_transaccion/1` hace una foto de todos los hechos dinámicos y la restaura si la meta falla o lanza (probado: una lista con `gastar_queso` imposible no deja rastro del `ganar_queso` anterior).

### 4.6 Convenciones de identificadores

- **`snake_case` ASCII** en todos los átomos de datos y predicados: `bandido_torpe`, `camino_real`, `dano` (sin `ñ`), `retaguardia`. Los nombres visibles (con tildes y mayúsculas) son solo *datos de texto* entre comillas simples (`'Sir Baldomero'`).
- Un ID es un átomo, **salvo** las instancias de enemigo `e(Tipo, N)`.
- Constantes de dominio fijas: filas `frente`/`retaguardia`; bandos `jugador`/`enemigo`; resultados `exito`/`fracaso`/`a_medias`; categorías de queso `fresco`/`curado`/`rancio`; fases `exploracion`/`combate`/`taberna`/`fin`.
- Ids de derrota (los de 04, D-17): `derrota_combate`, `derrota_hambre` (y `derrota_plazo`, extra); finales mínimos: `chapuza`, `derrota_combate`, `derrota_hambre` (D-30).
- La lista concreta de IDs (zonas, personajes, enemigos, objetos, contratos, eventos) la fija `01-lore-y-ambientacion.md`; este documento no la repite. Un predicado de verificación (`juego:verificar_datos/1`, **objetivo**) comprobará al arrancar que todo ID referenciado existe (§10).

---

## 5. Ciclo de juego

### 5.1 Bucle principal

`main.pl` solo lee, delega y muestra. Todo lo demás es `juego:ejecutar/2` (D-03: un comando es un **término** validado por `juego:validar_comando/2` y ejecutado por `juego:ejecutar/2`; no es un predicado invocable).

```prolog
% main.pl (probado en 5.10.4; en la prueba `demo` aun no estaba implementado)
main :-
    ui:iniciar,
    estado:nueva_partida,
    bucle.

bucle :-
    ui:leer_termino(T, _),
    juego:validar_comando(T, Res),
    despachar(Res, Seguir),
    (   Seguir == salir -> true ; bucle ).

despachar(error(M), seguir) :- ui:mostrar(resultado([error(M)])).
despachar(ok(Cmd), Seguir) :-
    juego:ejecutar(Cmd, R),
    ui:mostrar(R),
    R = resultado(Items),
    (   memberchk(salir, Items) -> Seguir = salir ; Seguir = seguir ).
```

- El bucle es **recursivo por la cola** (sin `repeat`/`fail`), determinista y sin acumular elección.
- Arranque: SWI-Prolog 5.10.4 está en `C:\Program Files\pl\bin\swipl.exe` (**fuera del PATH**). Desde la raíz del repositorio, con ruta completa o un alias: `"C:\Program Files\pl\bin\swipl.exe" -q -s src/main.pl -g main -t halt` (**comprobado**; el fichero se pasa con `-s`: como argumento posicional tras `-g`/`-t` esta versión dio `source_sink does not exist`). Alternativa interactiva: `swipl -s src/main.pl` y escribir `?- main.`.
- No se usa `:- initialization(main).` dentro de `main.pl`: cargar el módulo desde las pruebas arrancaría el juego.
- Meta-comandos de `main` en la versión mínima: `salir` (y `end_of_file`, que equivale a salir) y `demo` (guion fijo con semilla fija para la exposición, D-20/03 C-9). `reiniciar`, `guardar(N)` y `cargar(N)` son **(extra)**.

### 5.2 Estados del juego (fases)

La fase **no se almacena: se deriva** del estado, con cláusulas mutuamente excluyentes y sin corte. No hay forma de dejar la fase inconsistente con los hechos.

```prolog
% estado.pl (probado en 5.10.4)
fase(fin)         :- fin_partida(_).
fase(combate)     :- \+ fin_partida(_), en_combate(_).
fase(taberna)     :- \+ fin_partida(_), \+ en_combate(_), en_zona(taberna).
fase(exploracion) :- \+ fin_partida(_), \+ en_combate(_), \+ en_zona(taberna).
```

Tabla de fases permitidas (D-20: los únicos comandos nuevos son `elegir/1`, `pagar` y `demo`). Los comandos **(objetivo)** — `nivel`, `arbol`, `usar`, `huir`, `comer` — y los **(extra)** — `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar` — se añaden a la fila que corresponda si entran.

| Fase | Comandos permitidos | Comandos no permitidos (error con explicación) |
|---|---|---|
| `exploracion` | `ayuda`, `mirar`, `ir`, `contratos`, `aceptar`, `elegir`, `compania`, `inventario`, `explicar`, `por_que_no`, `salir`, `demo` | `pagar`, `descansar`, `atacar`, `defender`, `habilidad` |
| `taberna` | Los de exploración **más** `descansar` y `pagar` | `atacar`… |
| `combate` | `atacar`, `defender`, `habilidad`, `elegir` (si el combate tiene una elección de evento), `mirar`, `compania`, `inventario`, `explicar`, `por_que_no`, `ayuda` | `ir`, `aceptar`, `pagar`, `descansar` |
| `fin` | `ayuda`, `explicar`, `por_que_no`, `salir` | el resto |

`juego:permitido(Fase, Cmd)` es una tabla de hechos (probado para exploración y taberna). Un comando fuera de fase no es una excepción: `ejecutar/2` devuelve `error(fuera_de_fase(Cmd, Fase))`. No se puede `huir` del jefe (D-29).

### 5.3 Transiciones

| Desde | Disparador | Hacia | Qué ocurre |
|---|---|---|---|
| (inicio) | `nueva_partida` | `taberna` | Estado inicial desde `mundo:inicio/1` (12 cheddar, moral 6). |
| `taberna` | `ir(Z)` | `exploracion` | Impago si no se pagó (§5.5) + viaje + paso del día. Puede saltar a `combate`. |
| `exploracion` | `ir(taberna)` | `taberna` | Viaje + día + **cobro automático de contratos**; los sueldos se pagan con el comando `pagar`. |
| `exploracion`/`taberna` | Llegar a una zona con contrato activo cuya vía es `combate(G)`; o un evento tipo emboscada | `combate` | `iniciar_combate(G)`. |
| `combate` | `fin_combate(victoria)` | `exploracion` o `taberna` | Resultado de contrato, botín, moral; **los caídos se levantan con 1 de vida**; fase según la zona. |
| `combate` | `fin_combate(derrota)` | `fin` | Todos los miembros caídos: `fin(derrota_combate)` (D-17). |
| cualquiera | Al empezar el día, `queso_total = 0` y nada por cobrar | `fin` | `fin(derrota_hambre)`. El hambre nunca baja la vida de nadie por debajo de 1. |
| cualquiera | Jefe final derrotado | `fin` | `fin(chapuza)` en la mínima (los demás finales son objetivo/extra, D-30). |
| `fin` | `salir` | — | `reiniciar` es **(extra)**. |

(`huir` es **objetivo**: `viajar(zona_previa)` más penalización de moral; contra el jefe no se permite.)

```
        nueva_partida
             |
             v
     +--- taberna <-------------------------------+
     |       |   ^                                |
     | ir(Z) |   | ir(taberna)  (cobro automatico)|
     |       v   |                                |
     |    exploracion                             |
     |       |                                    |
     |       | contrato / emboscada               |
     |       v                                    |
     +---> combate --- victoria ------------------+
              |
              | derrota_combate / derrota_hambre / jefe final
              v
             fin
```

### 5.4 Cómo se ejecuta un comando (`juego:ejecutar/2`)

Es el único punto donde se compone "regla pura → efectos → estado". Secuencia fija para todos los comandos:

1. **¿Permitido en esta fase?** (`permitido/2`). Si no, `error(fuera_de_fase(...))`.
2. **Completar el comando.** `atacar(O)` se convierte en `atacar(Actor, O)` con el actor al que le toca el turno; `O` ambiguo (`bandido_torpe`) se resuelve al primer enemigo vivo.
3. **Comprobar la precondición con una regla pura** (p. ej. `contratos:puede_aceptar(C)`, `combate:puede_atacar(A, B)`, `economia:puede_pagar_sueldos`). Si falla, el resultado incluye `diag(Meta, Diag)` calculado con `explicar:por_que_no/2` y se corta ahí: **cada "no se puede" viene con su explicación gratis**.
4. **Calcular efectos** con la regla pura (`contratos:consecuencias/3`, `combate:efectos_accion/3`…).
5. **Aplicar** dentro de `estado:con_transaccion/1`.
6. **Disparadores posteriores** (paso del día, fin de combate, turnos enemigos…), cada uno como *etapa* nueva (ver nota).
7. **Guardar `ultima_prueba/2`** con la prueba de la meta de la acción (resuelta antes de aplicar los efectos, §6.2).
8. **Devolver** `resultado(Items)`.

```prolog
% juego.pl (probado en 5.10.4: ir, pagar, por_que_no, impago y etapas; de descansar solo se ejercitó la rama de rechazo)
ejecutar(Cmd, Resultado) :-
    (   catch(ejecutar_(Cmd, R0), E, R0 = resultado([error(interno(E))]))
    ->  Resultado = R0
    ;   Resultado = resultado([error(sin_efecto(Cmd))])
    ).

ejecutar_(Cmd, resultado(Items)) :-
    fase(F), nombre_comando(Cmd, N),
    (   permitido(F, N)
    ->  ejecutar_en_fase(Cmd, Items)
    ;   Items = [error(fuera_de_fase(Cmd, F))]
    ).

ejecutar_en_fase(ir(Z), Items) :-
    (   compania:puede_viajar(Z)
    ->  salir_de_taberna(Z, I0),
        etapa([viajar(Z)], I1),
        pasar_dia(I2),
        llegada(Z, I3),
        append([I0, I1, I2, I3], Items)
    ;   explicar:por_que_no(compania:puede_viajar(Z), Diag),
        Items = [error(no_puede_viajar(Z)), diag(compania:puede_viajar(Z), Diag)]
    ).
```

```prolog
% juego.pl: pagar (probado) y descansar (rama de rechazo probada; la de exito, boceto)
ejecutar_en_fase(pagar, Items) :-
    (   economia:puede_pagar_sueldos
    ->  economia:efectos_sueldos(Es),
        etapa([marcar(sueldos_pagados)|Es], Items)
    ;   explicar:por_que_no(economia:puede_pagar_sueldos, Diag),
        Items = [error(no_puede_pagar), diag(economia:puede_pagar_sueldos, Diag)]
    ).
ejecutar_en_fase(descansar, Items) :-
    (   economia:puede_descansar
    ->  economia:efectos_descanso(Es), etapa(Es, I1), pasar_dia(I2), append(I1, I2, Items)
    ;   explicar:por_que_no(economia:puede_descansar, Diag),
        Items = [error(no_puede_descansar), diag(economia:puede_descansar, Diag)]
    ).
```

```prolog
% juego.pl: etapa/2 recoge los mensajes con su contador de rotacion y aplica TODO en una transaccion
etapa(Efectos, Mensajes) :-
    findall(msg(C, A, U), ( member(mensaje(C, A), Efectos), uso_de(C, U) ), Mensajes),
    findall(uso_frase(C), member(mensaje(C, _), Efectos), Usos),
    append(Efectos, Usos, Todos),
    estado:con_transaccion(estado:aplicar_efectos(Todos)).

uso_de(C, U) :- ( estado:usos_frase(C, U0) -> U = U0 ; U = 0 ).
```

> **Nota (P4 por etapas).** Si todos los efectos de una acción compuesta se calcularan de golpe contra el estado inicial, las etapas posteriores no verían los cambios de las anteriores (cobrar un contrato y luego pagar sueldos con ese queso, por ejemplo). Por eso las acciones compuestas se descomponen en **etapas**: *calcular → aplicar → calcular → aplicar…*. Dentro de una etapa, los efectos son independientes entre sí. Para consumir un recurso de forma secuencial *dentro* de una etapa (dar de comer a varios con la misma despensa), la regla recibe una *foto* de la despensa como lista y la va gastando con acumuladores (estilo Conf. 1–2); ver `economia:efectos_racion/1`.
>
> **Red de seguridad.** `ejecutar/2` envuelve todo en `catch/3` y, si `ejecutar_/2` simplemente *fallara* (comando válido pero sin cláusula en la fase), devuelve `error(sin_efecto(Cmd))`. En la prueba, sin esa rama, un comando validado pero no implementado hacía fallar el bucle y reintentar puntos de elección anteriores: por eso "nunca falla" es un contrato probado, no una intención.

### 5.5 Paso del tiempo (día)

Moverse (`ir`) y `descansar` consumen un día. `juego:pasar_dia/1` encadena estas etapas, en este orden:

```prolog
% juego.pl (probado en 5.10.4)
% impago: al SALIR de la taberna con los sueldos sin pagar (-2 de moral por miembro)
salir_de_taberna(_, Items) :-
    (   estado:en_zona(taberna), \+ estado:marca(sueldos_pagados)
    ->  mundo:parametro(moral_impago, P), D is -P,
        findall(mod_moral(Id, D), compania:activo(Id), Es),
        etapa([mensaje(impago, [])|Es], Items)
    ;   Items = []
    ).

pasar_dia(Items) :-
    etapa([envejecer_quesos], I1),
    economia:efectos_racion(Es), etapa(Es, I2),
    etapa([avanzar_dia], I3),
    append([I1, I2, I3], Items).

llegada(Z, Items) :-
    (   Z == taberna
    ->  etapa([desmarcar(sueldos_pagados), mensaje(llegada, [Z])], Items)
    ;   etapa([mensaje(llegada, [Z])], Items)
    ).
```

| Etapa | Quién calcula | Efectos | Efecto en economía / moral |
|---|---|---|---|
| 0. Impago | `juego` (`salir_de_taberna/2`) | `mod_moral(Id, -2)` por miembro activo | **Solo al salir de la taberna sin haber pagado** (D-14): −2 de moral por miembro (`parametro(moral_impago, 2)`). |
| 1. Maduración | `economia` | `envejecer_quesos` | Todas las edades + 1. Pasan de fresco → curado (edad 3) y curado → rancio (edad 10). |
| 2. Ración | `economia:efectos_racion/1` | Un `gastar_queso/3` por miembro activo; sin queso: `mod_moral` −1 y `dano` (nunca por debajo de 1 de vida); rancio: `mod_moral` −1 | **Política (D-11): fresco → curado → rancio**, y lo rancio solo cuando no queda otra cosa; dentro de cada categoría, el más viejo primero. Mantiene vivo el rancio en la despensa (Hedor, jefe, lanzar). |
| 3. Fecha | `juego` | `avanzar_dia` | `dia(N)` → `dia(N+1)`. |
| 4. Evento del día | `eventos:evento_del_dia/3` **(objetivo)** | Los del evento + `fijar_semilla(S1)` | Puede alterar moral, queso, o disparar un combate. |
| 5. Comprobación de fin | `juego` | `fin(Motivo)` si procede | `derrota_hambre`, `derrota_combate`, jefe derrotado. |

Se come **después** de madurar: el queso que se come hoy ya tiene la edad de hoy. Al llegar a la taberna, `llegada/2` quita la bandera `sueldos_pagados` y la compañía puede `pagar`. El **cobro de contratos** (`contratos:efectos_cobro/1`: `contrato_cobrar(C)` + `ganar_queso/3` por la recompensa de cada contrato en `contrato_por_cobrar/2`) es automático al llegar. Los **sueldos** ya no son automáticos (D-14):

| Comando | Quién calcula | Efectos |
|---|---|---|
| `pagar` | `economia:efectos_sueldos/1` si `economia:puede_pagar_sueldos` | `gastar_queso/3` hasta cubrir los sueldos (1+2+1+1 = 5), **con lo más rancio primero**, y `marcar(sueldos_pagados)`. Si no hay queso suficiente, `por_que_no(pagar)` lo explica (`hay_queso_para(5)`); no se paga a medias. |
| `descansar` | `economia:efectos_descanso/1` si `economia:puede_descansar` | Gasta **2 quesos** (D-15), cura toda la vida, +1 de moral y pasa un día. Sin `deuda_taberna`. |

**Comprobado en 5.10.4** (partida guionizada con dos miembros, 12 cheddar): `ir(aldea)` deja `cheddar` de edad 1 y 10 unidades; al llegar a la taberna con 8 quesos, `por_que_no(pagar)` responde "sí se puede" con la prueba; `pagar` gasta los sueldos (3 con los dos miembros de la prueba) y deja 5; tras dos salidas de la taberna sin pagar y varios días sin queso, la moral cae a 0 y `esta_en_huelga/1` es cierto. La variante del mensaje de llegada rota (`Llegáis a…` / `Otra vez…`) gracias a `usos_frase/2`.

**Moral.** Escala **0–10**, inicio 6, huelga con moral ≤ 2 (D-08). Se mueve solo mediante `mod_moral/2`. Las constantes son `parametro/2` (valores provisionales, a ajustar en la semana 6):

| Causa | Parámetro (signo) | Dónde se genera |
|---|---|---|
| Sin comida | `moral_hambre` (−) y `dano_hambre` | `economia:efectos_racion/1` |
| Comer rancio | `moral_rancio` (−) | `economia:efectos_racion/1`, `efectos_comer/3` |
| Sueldo impagado | `moral_impago` (−2 por miembro, al salir) | `juego:salir_de_taberna/2` |
| Contrato cumplido / fallado | `moral_exito`, `moral_fracaso` | `contratos:consecuencias/3` |
| Victoria / huida | `moral_victoria`, `moral_huida` | `combate` (efectos de fin) |
| Habilidad de Rufino / descubrimiento de Tuerca | Según el rasgo | `combate:efectos_accion/3` |

Umbrales: `nivel_moral/2` (`alta` ≥ 8, `normal` 4-7, `baja` 2-3, `crítica` 0-1; provisional) y `esta_en_huelga/1` (moral ≤ `parametro(moral_huelga, 2)`) son **reglas derivadas** de `moral/2`; `puede_combatir/1` excluye a los huelguistas.

---

## 6. Meta-intérprete y modo explicar (diseño detallado)

### 6.1 Qué hay que conseguir

`DISENO.md §11` fija cuatro comandos: `explicar`, `por_que_no`, `arbol`, `nivel`. En la versión mínima entran **`explicar` y `por_que_no`**; `nivel` y `arbol` (texto) son **(objetivo)** y el `.dot` es **(extra)**. De ahí salen estos requisitos para `explicar.pl`:

| Requisito | Decisión de diseño |
|---|---|
| `solve/2` da **las mismas respuestas, en el mismo orden**, que ejecutar directamente | El meta-intérprete sigue el control de Prolog: selección por la izquierda, cláusulas de arriba abajo, búsqueda en profundidad con retroceso (Conf. 3). **Probado**: prueba de equivalencia con 12 metas, incluida la IA con corte y reglas de prueba con corte, `if-then-else`, `forall` y `findall` (§11.4). |
| Explicar sin perder respuestas ni romper el estado | `solve` solo *lee* (`clause/2`), nunca asserta. Las reglas no escriben (P2). |
| Soportar conjunción, disyunción, negación, if-then-else, predefinidos, dinámicos, corte, recursión | §6.4–6.6. |
| Árboles manejables | Límite de profundidad de cómputo (probado); niveles `resumido`/`detallado` **(objetivo)**; muestra en `findall` (§6.7–6.8). |
| `por_que_no` | Diagnóstico estructurado distinto del de `solve` (§6.9). Es una de las dos demostraciones centrales. |
| Exportar | Texto en árbol ASCII dentro de `explicar` (§6.11, probado); `.dot` **(extra)**. |
| Mostrar unificadores | Opción `llamada(true)` y cálculo de sustitución **(extra)** (§6.10). |

### 6.2 Qué se explica: metas, no comandos

`explicar(Accion)` recibe un comando del jugador, pero el meta-intérprete resuelve **metas Prolog**. `juego:objetivo_de_accion/2` los relaciona (nombres canónicos de 06 §2.7; incluye ya `descansar` y `pagar`, que faltaban en v0.1):

| Acción | Meta explicada |
|---|---|
| `atacar(A, B)` | `(combate:puede_atacar(A, B), combate:dano(A, B, D))` (**demostración 1**: `por_que_no(atacar(baldomero, bandido_montado))`) |
| `aceptar(C)` | `contratos:puede_aceptar(C)` (**demostración 2**: `por_que_no(aceptar(gallina_noble))`) |
| `ir(Z)` | `compania:puede_viajar(Z)` |
| `pagar` | `economia:puede_pagar_sueldos` |
| `descansar` | `economia:puede_descansar` |
| `habilidad(A, O)` | `combate:puede_habilidad(A, O)` |
| `comer(Id, T)` **(objetivo)** | `economia:puede_comer(Id, T)` |
| (turno enemigo) | `combate:accion_enemigo(E, Accion)` — **demostración 3**: `explicar` tras un turno enemigo muestra la cláusula que decidió y el marcador `corte` |

```prolog
% juego.pl (probado en 5.10.4: ir, pagar, aceptar y atacar a traves de por_que_no; la de atacar solo a traves de explicar:por_que_no; el resto, boceto)
% ---- explicar / por_que_no: acciones -> metas ----
objetivo_de_accion(ir(Z), compania:puede_viajar(Z)).
objetivo_de_accion(pagar, economia:puede_pagar_sueldos).
objetivo_de_accion(descansar, economia:puede_descansar).
objetivo_de_accion(atacar(A, T), (combate:puede_atacar(A, B), combate:dano(A, B, _))) :- instancia_de(T, B).
objetivo_de_accion(aceptar(C), contratos:puede_aceptar(C)).

% un tipo de enemigo (bandido_montado) se resuelve a su primera instancia viva; una instancia e(T,N) se deja tal cual
instancia_de(e(T, N), e(T, N)) :- !.
instancia_de(T, E) :- ( estado:instancia(E, T), compania:vivo(E) -> true ; E = T ).
```

Dos usos distintos de la misma maquinaria:

1. **Ahora mismo** (hipotético): se resuelve la meta contra el estado actual. Sirve para `por_que_no` y para "¿qué pasaría si…?". Probado: `por_que_no(pagar)` con queso suficiente no produce diagnóstico y `juego` responde "sí se puede" con la prueba.
2. **Retrospectivo**: lo que acaba de ocurrir. El estado ya cambió (la vida bajó), así que `ejecutar/2` guarda la prueba **antes** de aplicar los efectos con el efecto `guardar_prueba(Accion, Prueba)` en `ultima_prueba(Accion, Prueba)`. `explicar` sin argumento, o con una acción que coincida con la última, muestra la guardada. Las pruebas llevan las variables ya ligadas (solo quedan las locales de un `findall` o de una negación, que se ven en la prueba como `_G123`), así que `assertz` las copia sin riesgo (el efecto `guardar_prueba/2` está en el vocabulario de `estado`; boceto sin ejercitar). Para un turno enemigo, lo que se guarda es la prueba de `accion_enemigo(E, Accion)` (§8.6): es lo que hace posible la demostración 3.

### 6.3 Formato del término de prueba

Extiende el esquema del canon (`hecho/1`, `regla/…`, `builtin/1`, `no/1`). La diferencia es que `regla` lleva el número de cláusula y una lista de hijos (§16).

```
Prueba ::= verdad                        % la meta true
         | hecho(G)                      % cláusula sin cuerpo (estática o dinámica)
         | regla(G, I, Hijos)            % cláusula número I de su predicado; Hijos = lista de Prueba
         | builtin(G)                    % hoja: predefinido o de biblioteca, ya ejecutado (G instanciado)
         | no(G)                         % \+ G: G no es demostrable (hipótesis del mundo cerrado)
         | si(PCond, PThen)              % rama "then" de (C -> T ; E)
         | sino(PElse)                   % rama "else": la condición no se cumplió
         | izq(P) | der(P)               % rama elegida de una disyunción
         | agregado(G, Total, Muestra)   % findall/3: Total soluciones; Muestra = primeras pruebas
         | todos(G, Casos)               % forall/2: pares Condicion-Accion
         | corte                         % marcador: aquí se ejecutó un '!' de la cláusula
         | llamada(G0, P)                % (opcional) G0 = copia de la meta ANTES de resolver
         | truncada(G)                   % la presentación omitió este subárbol
```

En `G` siempre aparece la meta **ya instanciada** (cuando `solve` termina, las variables llevan sus valores): por eso el árbol "muestra los valores de las variables" sin trabajo adicional.

`llamada/2` y `truncada/1` son **(extra)** (unificadores por nodo, §6.10; plegado de `resumir/3`, §6.8). El resto lo produce el meta-intérprete probado de §6.4-6.5.

Ejemplo **real** (ejecutado en 5.10.4 con la versión sin modificadores de moral del `dano/3` de la prueba: ataque 8 de Baldomero contra la defensa 2 del `bandido_torpe`, o sea 8 − 2 = 6; con la defensa 5 del ejemplo de `DISENO.md §11.3` el resultado sería 3). El ejemplo de la demo del canon (11 − 5 = 6) usa una defensa que `bandido_torpe` no tiene (06 X-57): conviene cambiar el ejemplo a "D = 9 (11 − 2)" o escoger un enemigo con defensa 5.

```prolog
?- solve(combate:dano(baldomero, e(bandido_torpe, 1), D), P).
D = 6,
P = regla(dano(baldomero, e(bandido_torpe, 1), 6), 1,
      [ regla(ataque(baldomero, 8), 1,
              [ regla(ataque_base(baldomero, 8), 1, [ hecho(personaje(baldomero, 'Sir Baldomero', caballero,
                                                              vida(30), ataque(8), defensa(4), sueldo(1))) ]) ]),
        regla(defensa(e(bandido_torpe, 1), 2), 1,
              [ regla(defensa_base(e(bandido_torpe, 1), 2), 2,
                      [ hecho(enemigo(bandido_torpe, vida(12), ataque(5), defensa(2))) ]) ]),
        builtin(6 is max(1, 8-2)) ]).
```


### 6.4 El meta-intérprete (**probado en 5.10.4**)

Parte del "vainilla" de la Conf. 6 (`metaV/1`) y del esquema de `DISENO.md §11.1`, con cuatro mejoras: (1) **solo se desciende por predicados de los módulos del juego**; (2) conoce módulos; (3) construye la prueba; (4) trata el corte. **Estado de la prueba de viabilidad (spike, D-06, V-01, V-02):** el código siguiente se cargó en SWI-Prolog 5.10.4 junto con cinco módulos de ejemplo (`mundo`, `estado`, `compania`, `combate`, una `economia` mínima) y una prueba con `if-then-else`, `forall`, `findall`, recursión, un predicado con corte y otro con corte anidado. **Resultado: el corte real funciona**; la decisión D-06 se confirma y el plan B (corte como hoja y excluir la IA de la equivalencia) **no hace falta**.

```prolog
% explicar.pl -- probado en 5.10.4 (la unica diferencia: se quitó el modulo de pruebas de modulo_juego/1)
:- module(explicar, [solve/2, solve/3, por_que_no/2, por_que_no_clausula/3,
                     prueba_a_lineas/2, diag_a_lineas/2, meta_de_prueba/2]).
:- meta_predicate solve(0, -), solve(0, -, +), por_que_no(0, -), por_que_no_clausula(0, +, -).

% Modulos por cuyas clausulas SI se desciende. Todo lo demas es hoja.
modulo_juego(estado).    modulo_juego(mundo).     modulo_juego(compania).
modulo_juego(economia).  modulo_juego(contratos). modulo_juego(combate).
modulo_juego(eventos).

solve(Meta, Prueba) :- solve(Meta, Prueba, []).

solve(Meta, Prueba, Opciones) :-
    strip_module(Meta, M, G),
    opcion(limite, Opciones, 400, Limite),
    s(G, M, Limite, Prueba).

opcion(K, Ops, Def, V) :-
    functor(T, K, 1), arg(1, T, V0),
    (   memberchk(T, Ops) -> V = V0 ; V = Def ).

% --- Profundidad de computo: dos clausulas excluyentes, sin corte ---
s(G, _, N, _) :- N =< 0, throw(limite_profundidad(G)).
s(G, M, N, P) :- N > 0, clasifica(G, T), s_(T, G, M, N, P).

clasifica(G, T) :-
    (   var(G)               -> throw(error(instantiation_error, solve/2))
    ;   G == true            -> T = verdad
    ;   G = (_, _)           -> T = conj
    ;   G = (_ ; _)          -> T = disy
    ;   G = (_ -> _)         -> T = si_solo
    ;   G = (\+ _)           -> T = neg
    ;   G == !               -> T = corte
    ;   G = findall(_,_,_)   -> T = findall
    ;   G = forall(_,_)      -> T = forall
    ;   G = (_ : _)          -> T = calificada
    ;   hoja_conocida(G)     -> T = hoja
    ;   T = pred
    ).

hoja_conocida(G) :- functor(G, N, A), hoja(N/A).
hoja(is/2).   hoja((<)/2).   hoja((>)/2).   hoja((=<)/2). hoja((>=)/2).
hoja((=:=)/2). hoja((=\=)/2). hoja((=)/2).  hoja((\=)/2). hoja((==)/2). hoja((\==)/2).
hoja(fail/0).
hoja(member/2). hoja(memberchk/2). hoja(append/3). hoja(length/2).
hoja(msort/2).  hoja(sort/2).      hoja(between/3). hoja(nth0/3). hoja(nth1/3). hoja(last/2).

s_(verdad, _, _, _, verdad).

s_(conj, (A, B), M, N, (PA, PB)) :-
    s(A, M, N, PA),
    s(B, M, N, PB).

s_(disy, (A ; B), M, N, P) :-
    (   nonvar(A), A = (C -> T)
    ->  (   s(C, M, N, PC)
        ->  s(T, M, N, PT), P = si(PC, PT)
        ;   s(B, M, N, PE), P = sino(PE)
        )
    ;   (   s(A, M, N, PA), P = izq(PA)
        ;   s(B, M, N, PB), P = der(PB)
        )
    ).

s_(si_solo, (C -> T), M, N, si(PC, PT)) :-
    (   s(C, M, N, PC) -> s(T, M, N, PT) ).

s_(neg, (\+ G), M, N, no(G)) :-
    \+ s(G, M, N, _).

s_(hoja, G, M, _, builtin(G)) :-
    call(M:G).

s_(calificada, (M2 : G), _, N, P) :-
    s(G, M2, N, P).

s_(corte, !, _, _, _) :-
    throw(corte_no_soportado).

s_(findall, findall(T, G, L), M, N, agregado(findall(T, G, L), Total, Muestra)) :-
    findall(T-P, s(G, M, N, P), Pares),
    separar_pares(Pares, L, Pruebas),
    length(Pruebas, Total),
    primeros(3, Pruebas, Muestra).

s_(forall, forall(C, A), M, N, todos(forall(C, A), Casos)) :-
    \+ ( s(C, M, N, _), \+ s(A, M, N, _) ),
    findall(PC-PA, ( s(C, M, N, PC), s(A, M, N, PA) ), Casos).

s_(pred, G, M, N, P) :-
    modulo_definicion(M, G, D),
    (   modulo_juego(D), definido(D, G)
    ->  N1 is N - 1,
        regla(D, G, N1, P)
    ;   call(M:G), P = builtin(G)
    ).

modulo_definicion(M, G, D) :-
    (   predicate_property(M:G, imported_from(D0)) -> D = D0 ; D = M ).

% 5.10.4: predicate_property(_, defined) no devuelve exito; se usan estas dos.
definido(D, G) :- predicate_property(D:G, dynamic).
definido(D, G) :- predicate_property(D:G, number_of_clauses(_)).

```

Notas sobre este código:

- **Por qué "solo módulos del juego" y no `predicate_property(G, built_in)`** (canon, §11.1). En SWI-Prolog `member/2`, `append/3`, `msort/2`… son de *biblioteca*, no `built_in`: con el esquema del canon el meta-intérprete bajaría hasta el código interno de `lists`. Con `modulo_juego/1` solo se abren los predicados propios del proyecto y todo lo demás es hoja. Se conserva la idea del canon (los predefinidos son hojas) con un criterio más robusto (§16). **Probado**: `member(1, [1,2,3])` aparece como `builtin(...)` y no se abre `lists`.
- **`predicate_property(_, defined)` no funciona en 5.10.4** (06 §2.8, O-2): devuelve fallo incluso para predicados definidos. Se sustituye por `definido/2`: `dynamic` **o** `number_of_clauses(_)`. **Probado**: un dinámico sin cláusulas (`alterado/3`) cuenta como definido (tiene `number_of_clauses(0)` y `dynamic`), de modo que su consulta falla limpiamente (mundo cerrado) y aparece `no(aturdido(baldomero))` en la prueba de `puede_atacar/2`.
- **Módulos.** `predicate_property(M:G, imported_from(D))` devuelve el módulo real de un predicado importado y `clause(D:G, ...)` funciona sobre estáticos y dinámicos (V-01 resuelto). `strip_module/3` y `meta_predicate` con `0` funcionan.
- **Variable libre como meta**: se lanza `instantiation_error` explícito (sin esa guarda, `G = (_, _)` ligaba la variable).
- **Orden de resolución y exactitud.** Las cláusulas `s_(conj…)` resuelven `A` antes que `B` y `clause/3` enumera en orden textual: coincide con la regla de selección por la izquierda y la de ordenación de cláusulas de Prolog (Conf. 3).
- **Recursión.** Una regla recursiva se explica sola: cada llamada recursiva produce un `regla(...)` anidado. La profundidad `N` decrece solo al descender por reglas (no por conjunciones). **Probado**: un predicado recursivo infinito lanza `limite_profundidad(_)`.
- **Hechos dinámicos.** `clause/2` funciona sobre `dynamic`; el hecho se devuelve como `hecho(vida(baldomero, 30))`. La prueba es una *foto del momento*.
- **Variables no ligadas en `findall`.** La prueba `agregado(findall(T, G, L), Total, Muestra)` conserva la plantilla `T` y el objetivo `G` con variables sin ligar (aparecen como `_G123`); la lista resultado `L` sí está instanciada.

### 6.5 Resolución de una regla y tratamiento del corte (**probado en 5.10.4**)

```prolog
% explicar.pl -- probado en 5.10.4
% --- Resolucion de una regla y corte real ---
regla(D, G, N, Prueba) :-
    clause(D:G, Cuerpo, Ref),
    nth_clause(_, Indice, Ref),
    (   Cuerpo == true
    ->  Prueba = hecho(G)
    ;   dividir_corte(Cuerpo, Pre, Post)
    ->  s(Pre, D, N, PA),
        !,
        s(Post, D, N, PB),
        aplanar_y((PA, corte, PB), Hijos),
        Prueba = regla(G, Indice, Hijos)
    ;   s(Cuerpo, D, N, PC),
        aplanar_y(PC, Hijos),
        Prueba = regla(G, Indice, Hijos)
    ).

dividir_corte(Cuerpo, Pre, Post) :-
    conj_lista(Cuerpo, Metas),
    append(Antes, [!|Despues], Metas),
    lista_conj(Antes, Pre),
    lista_conj(Despues, Post).

conj_lista(C, L) :-
    (   C == true -> L = []
    ;   nonvar(C), C = (A, B) -> conj_lista(A, LA), conj_lista(B, LB), append(LA, LB, L)
    ;   L = [C]
    ).
lista_conj([], true).
lista_conj([X], X).
lista_conj([X, Y|R], (X, C)) :- lista_conj([Y|R], C).

aplanar_y(P, L) :-
    (   nonvar(P), P = (A, B) -> aplanar_y(A, LA), aplanar_y(B, LB), append(LA, LB, L)
    ;   P == verdad           -> L = []
    ;   L = [P]
    ).

separar_pares([], [], []).
separar_pares([T-P|R], [T|Ts], [P|Ps]) :- separar_pares(R, Ts, Ps).
primeros(K, L, P) :-
    (   K > 0, L = [X|R] -> K1 is K - 1, P = [X|P1], primeros(K1, R, P1)
    ;   P = []
    ).

```

**Por qué esto implementa el corte.** En `H :- Pre, !, Post`, el corte (1) conserva la primera solución de `Pre`, (2) descarta las demás soluciones de `Pre` y (3) descarta las cláusulas restantes de `H`, pero **no** poda `Post` (Conf. 4). El `!` de `regla/4` está justo después de `clause/3` (que genera las cláusulas alternativas) y de `s(Pre…)` (que genera las soluciones alternativas de `Pre`), así que corta *exactamente* eso y deja viva a `Post`. El corte es transparente a `;/2` y `->/2` (ISO; manual del curso), de modo que un `!` en una rama `then` del `if-then-else` interno poda las alternativas de `regla/4`. **Verificado con casos de corte** (V-02): el test de equivalencia compara todas las soluciones y su orden entre la ejecución directa y `solve/2` para

- `cortado(X) :- member(X,[1,2,3]), X > 1, !.  cortado(9).` → ambas dan `[2]` y la prueba termina en `…, builtin(2>1), corte]`;
- `cortado2(X) :- member(X,[1,2,3]), !, member(_,[a,b]).` → ambas dan **dos** soluciones `[1,1]`: el corte poda `member/2` de `Pre` pero no `Post`;
- `combate:accion_enemigo(E, A)` con `E` libre y con `E` ligado (la cláusula 2 gana y descarta la 3) en un estado de combate.

Restricciones (las haría cumplir el linter, §6.12 **(extra)**; mientras tanto, a mano):

- Un solo `!` por cláusula y siempre en el **nivel superior del cuerpo** (no dentro de `;`, `->` ni `\+`). Es lo único que usa la IA enemiga. **Probado**: un `!` anidado (`anidado(X) :- ( X = 1, ! ; X = 2 )`) lanza `corte_no_soportado`.
- En la prueba aparece el marcador `corte`; así la presentación puede decir "a partir de aquí se descartaron las cláusulas siguientes" (probado: `[clausula 2 + corte]`).

**If-then-else.** Ya contemplado: la condición se resuelve una sola vez (`->` es local a la condición). Su prueba es `si(PCond, PThen)` o `sino(PElse)` (probado con `cond/2`).

**Negación (`\+`).** Es la negación como fracaso finito de la Conf. 4. La prueba `no(G)` solo dice "G no es demostrable". Reglas de uso seguro para que la lectura lógica sea la esperada:

1. `\+` va **después** de los objetivos que ligan sus variables (en `puede_atacar/2` del canon, `A` y `B` ya están ligados).
2. Las variables que solo aparecen dentro de la negación son *locales* y significan "no existe ninguno": `\+ ( teme(A, Clase), clase(B, Clase) )` ≡ ¬∃Clase. Es correcto (ejemplo `disjuntas/2` de la Conf. 4); lo que debe evitarse es negar con una variable compartida **sin ligar** (el ejemplo `not(p(X))` del curso).
3. En la prueba, `no(G)` conserva las variables locales sin ligar; el `por_que_no` es el que muestra *por qué* el hecho negado resultó cierto (§6.9).

**Predicados dinámicos.** Cuando un cuerpo consulta `vida(Id, V)`, `s_(pred…)` abre `estado:vida/2` con `clause/3` y devuelve `hecho(vida(Id, V))`. Si un predicado dinámico no tiene cláusulas, `clause/3` falla: es la hipótesis del mundo cerrado de la Conf. 4, igual que en ejecución directa.

### 6.6 Qué NO hace el meta-intérprete

| Caso | Tratamiento |
|---|---|
| `assert`/`retract`/E/S dentro de una regla | Prohibido por P2/P5; si aparece, `s_(pred…)` lo trata como hoja (se ejecuta) y el linter **(extra)** avisaría. |
| `bagof/setof/aggregate_all`, `call/N`, `once/1` | Fuera del subconjunto; hojas. |
| `!` anidado | Error `corte_no_soportado`. |
| Excepciones en las hojas | Se propagan tal cual; `ejecutar/2` las captura (§10). |
| Metas con variable libre como objetivo | `instantiation_error` como en Prolog. |

### 6.7 Límites y tamaño

Hay **dos límites distintos** que no deben confundirse:

| Límite | Para qué | Qué pasa al superarlo |
|---|---|---|
| **Profundidad de cómputo** (`limite(N)`, por defecto 400) | Protegerse de recursión infinita (Conf. 3: derivaciones infinitas, p. ej. cláusulas recursivas por la izquierda). | `throw(limite_profundidad(G))`: error de programación, no de juego. |
| **Profundidad de presentación** (nivel `resumido`/`detallado`) | No inundar la consola. | La prueba está completa; `explicar:resumir/3` **(objetivo)** la poda al mostrarla (§6.8). En la versión mínima `ui` muestra la prueba tal cual y recorta solo las líneas largas. |

Además, `findall/3` guarda solo las primeras 3 pruebas (`primeros(3, …)`, probado) y el total. Las opciones `muestra(K)` y `llamada(Bool)` de `solve/3` y `estadisticas/3` (contar nodos para avisar "la prueba tiene 812 nodos; usa `nivel(resumido)`") son **(extra)**.

### 6.8 Niveles `resumido` y `detallado` (objetivo)

Entra solo con colchón (06 §5.1: `nivel` y `arbol/1` en texto son "objetivo"). El nivel es un ajuste de sesión (`ajuste(nivel_explicacion, resumido)`); `nivel(detallado)` lo cambia. La poda es una **función pura** `explicar:resumir(+Prueba, +Nivel, -Resumen)` aplicada al mostrar: el mismo árbol sirve para ambos niveles. En la versión mínima la salida es única (la de §6.11, equivalente a `detallado` con las líneas largas recortadas) y el comentario del narrador distingue `resumido`/`detallado` solo por la clave `Nivel` de `frase/3`.

| Elemento | `resumido` | `detallado` |
|---|---|---|
| Raíz y sus hijos directos | Se muestran | Se muestran |
| Nietos y más profundos | Solo ramas *relevantes* (contienen `no`, `sino`, `corte`, o una operación `is`) | Todo, hasta profundidad 12 |
| Hijos `hecho(...)` consecutivos | Agrupados en una línea (`vivo(baldomero), vivo(bandido_torpe)`) | Uno por línea |
| Sub-reglas no relevantes | `regla(...)  [+N nodos]` plegada (`truncada/1`) | Expandidas |
| `builtin(X is Y)` | Se muestra con su fórmula y valor | Ídem |
| Listas largas (> 8 hijos) | `... y K más` | `... y K más` |

### 6.9 `por_que_no` (**probado en 5.10.4**)

Dos casos conviven:

- `solve` demuestra metas que **tienen** solución.
- `por_que_no/2` explica metas que **no** tienen: es un *segundo* meta-intérprete, que recorre las cláusulas del predicado y busca **el primer subobjetivo que falla**.

**Formato del diagnóstico**

```
Diag  ::= sin_clausula(G)                  % ninguna cláusula/hecho unifica con G (mundo cerrado)
        | fallo(G, Candidatas)             % hay cláusulas, todas fallan; mejor candidata primero
        | builtin_falso(G)                 % un predefinido ya instanciado resultó falso: 3 > 5
        | neg_viola(G, PruebaDeG)          % \+ G falla porque G SÍ es demostrable (se da la prueba)
        | tras(PruebaDeA, DiagB)           % (A, B): A tiene solución, pero B falla con ella
        | ninguna(DiagA, DiagB)            % (A ; B): ambas ramas fallan
        | limite(G)                        % se agotó la profundidad de diagnóstico
Candidatas ::= [cl(I, PruebasPrevias, Punto), ...]
Punto      ::= punto(SubobjetivoFallido, Diag)
```

El núcleo de la versión mínima es `sin_clausula`, `fallo`, `neg_viola`, `builtin_falso` y `tras`; `limite` y "la cláusula más cercana" son opcionales.

**Algoritmo**:

```prolog
% explicar.pl -- probado en 5.10.4
% =========================== por_que_no ===========================
por_que_no(Meta, Diag) :-
    strip_module(Meta, M, G),
    \+ s(G, M, 400, _),
    diag(G, M, 40, Diag).

por_que_no_clausula(Meta, I, Diag) :-
    strip_module(Meta, M, G),
    modulo_definicion(M, G, D),
    candidata(D, G, 40, I, Pre, Punto),
    Diag = fallo(G, [cl(I, Pre, Punto)]).

diag(G, M, N, Diag) :-
    (   N =< 0 -> Diag = limite(G)
    ;   clasifica(G, T), diag_(T, G, M, N, Diag) ).

diag_(conj, (A, B), M, N, Diag) :-
    (   s(A, M, N, PA)
    ->  diag(B, M, N, DB),
        Diag = tras(PA, DB)
    ;   diag(A, M, N, Diag)
    ).
diag_(neg, (\+ X), M, N, neg_viola(X, P)) :- s(X, M, N, P).
diag_(hoja, G, _, _, builtin_falso(G)).
diag_(calificada, (M2 : G), _, N, Diag) :- diag(G, M2, N, Diag).
diag_(disy, (A ; B), M, N, ninguna(DA, DB)) :- diag(A, M, N, DA), diag(B, M, N, DB).
diag_(pred, G, M, N, Diag) :-
    modulo_definicion(M, G, D),
    (   modulo_juego(D), definido(D, G)
    ->  findall(cl(I, Pre, Punto), candidata(D, G, N, I, Pre, Punto), C0),
        (   C0 == [] -> Diag = sin_clausula(G)
        ;   ordenar_por_cercania(C0, C), Diag = fallo(G, C) )
    ;   Diag = builtin_falso(G)
    ).

candidata(D, G, N, I, Pre, punto(Fallido, DiagSub)) :-
    clause(D:G, Cuerpo, Ref), nth_clause(_, I, Ref),
    conj_lista(Cuerpo, Metas),
    N1 is N - 1,
    prefijo_y_fallo(Metas, D, N1, Pre, Fallido, DiagSub).

prefijo_y_fallo([Meta|Resto], D, N, Pre, Fallido, DiagSub) :-
    (   Meta == !
    ->  prefijo_y_fallo(Resto, D, N, Pre, Fallido, DiagSub)
    ;   s(Meta, D, N, P)
    ->  Pre = [P|Pre1],
        prefijo_y_fallo(Resto, D, N, Pre1, Fallido, DiagSub)
    ;   Pre = [], Fallido = Meta,
        diag(Meta, D, N, DiagSub)
    ).

ordenar_por_cercania(C0, C) :-
    findall(K-Cl, ( member(Cl, C0), Cl = cl(_, Pre, _), length(Pre, L), K is -L ), Ks),
    msort(Ks, S),
    findall(Cl, member(_-Cl, S), C).
```

**Decisiones del algoritmo**

- **Varias cláusulas aplicables.** `fallo/2` lista **todas**; en nivel `resumido` solo se muestra la **más cercana**: la que satisfizo más subobjetivos antes de fallar (`ordenar_por_cercania/2`: se ordena por `length(PruebasPrevias)` descendente con `msort/2` sobre pares `Negativo-Clausula`). Probado: la causa raíz de `puede_viajar(camino_real)` desde la taberna baja hasta `sin_clausula(conexion(taberna, camino_real))` pasando por las dos cláusulas de `adyacente/2`.
- **Negaciones.** Si el subobjetivo fallido es `\+ X`, el diagnóstico es `neg_viola(X, PruebaDeX)`: se da la prueba de por qué `X` *sí* es cierto (es el "porque `teme(baldomero, caballo)` y `clase(bandido_montado, caballo)` son ciertos" del canon). Una negación doble se despliega recursivamente.
- **Primera solución de un generador.** Para `(A, B)` se informa del fallo de `B` con la **primera** solución de `A`; como la meta completa no tiene solución, B también fallará con las demás.
- **Recursión.** `diag/4` lleva su propio límite (40) y devuelve `limite(G)`.
- **Corte.** `prefijo_y_fallo/6` ignora los `!` al diagnosticar. Una cláusula anterior con corte que *sí* se habría aplicado hace que la meta sea demostrable, y entonces `por_que_no` falla (precondición `\+ s(...)`), que es el comportamiento correcto. Probado: `por_que_no` de una meta cierta falla.
- **Meta con variables.** `por_que_no(atacar(baldomero, X))` explica "no hay ningún X": el diagnóstico es el de la meta tal cual, con `X` libre.
- **`clave_de_diag/2`** (06 X-21) **boceto sin ejecutar**: baja por `tras` y `fallo` hasta el punto de fallo más profundo; si es `neg_viola(_, P)`, la clave es `impide(H)` con `H` el primer hecho de `P` que tenga frase en el banco (para `rasgo_no`, que se expande a `rasgo(baldomero, teme_caballos)` y `ignora_miedo/1`, hay que escribir en 05 la clave sobre el hecho que la regla realmente produce, 06 X-37); si es `fallo(G,_)`, `falla(G)`. Se escribe antes de T-15 y se prueba con las seis claves del núcleo.

**Salida real de las dos demostraciones centrales** (ejecutadas en 5.10.4 con los datos de ejemplo de la prueba: Baldomero sin venda; combate contra un `bandido_montado` en el frente; el resultado se escribe tal cual lo produce `ui:mostrar/1`; el recorte `...` lo hace la presentación a 72 caracteres; los nombres de variable de las reglas se pierden tras `clause/3`, por eso aparecen como `A`, `B`):

```
> por_que_no(atacar(baldomero, bandido_montado)).
[no] puede_atacar(baldomero, e(bandido_montado, 1))   [clausula 1]
  |- [ok] vivo(baldomero)
  |- [ok] vivo(e(bandido_montado, 1))
  |- [ok] en_fila_alcanzable(baldomero, e(bandido_montado, 1))
  |- [ok] \+ aturdido(baldomero)
  \- [no] \+ (teme(baldomero, caballo), clase_de(e(bandido_montado, 1), caballo))
        porque teme(baldomero, caballo) y clase_de(e(bandido_montado, 1), caballo) son ciertos.

> por_que_no(aceptar(gallina_noble)).
[no] puede_aceptar(gallina_noble)   [clausula 1]
  |- [ok] contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo...
  |- [ok] \+ contrato_aceptado(gallina_noble)
  |- [ok] activos_menos_de(3)
  \- [no] cumple_todas([requiere(rasgo_no(teme_caballos))])
        \- [no] condicion_cumple(rasgo_no(teme_caballos))
              \- [no] \+ (activo(baldomero), rasgo(baldomero, teme_caballos), \+ ignora_mie...
                    porque activo(baldomero), rasgo(baldomero, teme_caballos) y \+ ignora_miedo(baldomero) son ciertos.
```

Con la `venda_de_caballos` equipada (`equipar(baldomero, venda_de_caballos)`), `por_que_no(aceptar(gallina_noble))` responde que sí se puede y muestra la prueba (`condicion_cumple(rasgo_no(...))` con `no(...)` como hoja): D-19 comprobada. Lectura para la exposición: la regla `puede_atacar/2` falla porque la **negación** `\+ (teme(...), clase_de(...))` falla, y la razón es que el hecho negado **es cierto**; eso es la negación como fracaso (Conf. 4).

### 6.10 Mostrar los unificadores (extra)

> **(extra)**: no entra en la versión mínima. Lo que sí se ve ya en la prueba probada es la meta *ya instanciada* (`dano(baldomero, e(bandido_torpe, 1), 6)`), que es la "sustitución respuesta" de la meta raíz.

El canon pide "árbol con unificadores". Es la *sustitución respuesta computada* de la Conf. 3 (restricción de la sustitución computada a las variables del objetivo), calculada **por nodo**:

1. Con la opción `llamada(true)`, antes de resolver cada nodo `pred`, `solve` guarda `copy_term(G, G0)` (variables frescas, nunca unificadas) y envuelve el nodo en `llamada(G0, Nodo)`.
2. Al renderizar, `explicar:sustitucion(+G0, +G, -Pares)` recorre `G0` y `G` en paralelo: donde `G0` tiene una variable y `G` un valor, emite `Var/Valor`.
3. Para nombrar las variables se aplica `numbervars/3` (comprobado en 5.10.4) a `G0` y se imprime con `numbervars(true)` (nombres `A`, `B`, …). Los nombres de las variables del *código fuente* no se conservan tras `clause/2`; los de la meta escrita por el jugador sí, si `ui:leer_termino/2` los captura con `variable_names` en `read_term/2` (`DISENO.md` muestra `D = 6`).

```
[ok] dano(baldomero, bandido_torpe, D)      {D/6}
  \- builtin  6 is max(1, 8-2)
```

Es una aproximación honesta: muestra lo que cada subderivación *computó* (el resultado de ese subárbol), no los unificadores intermedios paso a paso (eso solo lo da el árbol SLD real, §6.13).

### 6.11 Presentación: árbol en texto ASCII (dentro de `explicar`) y Graphviz (extra)

Las funciones de presentación son **puras** (devuelven listas de átomos); `ui.pl` las escribe. Por D-07/D-26, las marcas del árbol son **ASCII por defecto**: `[ok]`, `[no]`, `|-`, `\-` (la v0.1 proponía `✔ ✘ ├─ └─` con Unicode opcional). El texto con tildes y `« »` se escribe en UTF-8 con `set_stream(user_output, encoding(utf8))` (§13). Motivo: `✔` sale como una secuencia de escape ASCII y `├─` como `+-` con la codificación por defecto de 5.10.4, y la consola de Windows puede degradarlos; `ajuste(ascii, Bool)` queda solo para forzar el modo si se añade un modo Unicode.

```prolog
% explicar.pl -- probado en 5.10.4 (prueba_a_lineas/2 para pruebas, diag_a_lineas/2 para por_que_no)
% =========================== presentacion (ASCII) ===========================
meta_de_prueba(hecho(G), G).
meta_de_prueba(regla(G, _, _), G).
meta_de_prueba(builtin(G), G).
meta_de_prueba(no(G), (\+ G)).
meta_de_prueba(verdad, true).
meta_de_prueba(si(PC, _), G) :- meta_de_prueba(PC, G).

% texto de una meta: \+ con parentesis, conjunciones con ", ", variables como A, B..., y recorte
txt(G, A) :-
    copy_term(G, G2), numbervars(G2, 0, _),
    t(G2, A0),
    (   atom_length(A0, Len), Len > 72
    ->  sub_atom(A0, 0, 69, _, Pre), atom_concat(Pre, '...', A)
    ;   A = A0
    ).
t((\+ G), A) :- !, t(G, T), ( nonvar(G), G = (_, _) -> format(atom(A), '\\+ (~w)', [T]) ; format(atom(A), '\\+ ~w', [T]) ).
t((X, Y), A) :- !, t(X, TX), t(Y, TY), format(atom(A), '~w, ~w', [TX, TY]).
t(G, A) :- format(atom(A), '~W', [G, [numbervars(true), quoted(false), spacing(next_argument)]]).

prueba_a_lineas(P, Lineas) :- pl(P, '', Lineas, []).

pl(izq(P), S, L0, L) :- !, pl(P, S, L0, L).
pl(der(P), S, L0, L) :- !, pl(P, S, L0, L).
pl(P, Sangria, [L|Ls0], Ls) :-
    etiqueta(P, Marca, G),
    txt(G, T),
    format(atom(L), '~w[ok] ~w   ~w', [Sangria, T, Marca]),
    hijos(P, Hs),
    atom_concat(Sangria, '   ', S2),
    hl(Hs, S2, Ls0, Ls).
hl([], _, L, L).
hl([H|T], S, L0, L) :- pl(H, S, L0, L1), hl(T, S, L1, L).

etiqueta(hecho(G), '[hecho]', G).
etiqueta(builtin(G), '[builtin]', G).
etiqueta(no(G), '[no demostrable]', (\+ G)).
etiqueta(corte, '[corte: se descartaron las clausulas siguientes]', corte).
etiqueta(verdad, '', true).
etiqueta(agregado(G, T, _), E, G) :- format(atom(E), '[findall: ~w solucion(es)]', [T]).
etiqueta(todos(G, Cs), E, G) :- length(Cs, N), format(atom(E), '[forall: ~w caso(s)]', [N]).
etiqueta(si(PC, _), '[rama then]', G) :- meta_de_prueba(PC, G).
etiqueta(sino(_), '[rama else]', else).
etiqueta(regla(G, I, Hs), E, G) :- ( memberchk(corte, Hs) -> C = ' + corte' ; C = '' ),
    format(atom(E), '[clausula ~w~w]', [I, C]).
hijos(regla(_, _, Hs), Hs).
hijos(hecho(_), []).
hijos(builtin(_), []).
hijos(no(_), []).
hijos(corte, []).
hijos(verdad, []).
hijos(agregado(_, _, M), Hs) :- findall(H, ( member(X, M), aplanar_y(X, L), member(H, L) ), Hs).
hijos(todos(_, Cs), Hs) :- findall(H, ( member(PC-PA, Cs), member(H, [PC, PA]) ), Hs).
hijos(si(_, PT), [PT]).
hijos(sino(PE), [PE]).

% --- por_que_no: de la causa mas externa a la raiz ---
diag_a_lineas(Diag, Lineas) :-
    cabecera(Diag, Cab),
    detalle(Diag, '  ', Resto),
    append(Cab, Resto, Lineas).

cabecera(fallo(G, [cl(I, _, _)|_]), [L]) :- txt(G, T), format(atom(L), '[no] ~w   [clausula ~w]', [T, I]).
cabecera(sin_clausula(G), [L]) :- txt(G, T), format(atom(L), '[no] ~w   [no hay ningun hecho ni clausula]', [T]).
cabecera(builtin_falso(G), [L]) :- txt(G, T), format(atom(L), '[no] ~w   [falso]', [T]).
cabecera(neg_viola(X, _), [L]) :- txt(\+ X, T), format(atom(L), '[no] ~w', [T]).
cabecera(tras(_, D), Ls) :- cabecera(D, Ls).

detalle(fallo(_, [cl(_, Pre, punto(F, D))|_]), S, Ls) :-
    findall(L, ( member(P, Pre), meta_de_prueba(P, PG), txt(PG, PT),
                 format(atom(L), '~w|- [ok] ~w', [S, PT]) ), Oks),
    txt(F, TF),
    format(atom(LF), '~w\\- [no] ~w', [S, TF]),
    atom_concat(S, '      ', S2),
    detalle(D, S2, Sub),
    append([Oks, [LF], Sub], Ls).
detalle(tras(_, D), S, Ls) :- detalle(D, S, Ls).
detalle(neg_viola(_, P), S, [L]) :-
    aplanar_y(P, Ps),
    findall(T, ( member(Q, Ps), meta_de_prueba(Q, QG), txt(QG, T) ), Ts),
    unir_y(Ts, Y),
    format(atom(L), '~wporque ~w son ciertos.', [S, Y]).
detalle(sin_clausula(G), S, [L]) :- txt(G, T), format(atom(L), '~wno hay ningun hecho ni clausula para ~w', [S, T]).
detalle(builtin_falso(G), S, [L]) :- txt(G, T), format(atom(L), '~w~w es falso', [S, T]).

unir_y([X], X).
unir_y([X, Y], R) :- format(atom(R), '~w y ~w', [X, Y]).
unir_y([X, Y, Z|T], R) :- unir_y([Y, Z|T], R1), format(atom(R), '~w, ~w', [X, R1]).
```

Salida real de `explicar` sobre un turno enemigo con corte (**demostración 3**; ejecutada en 5.10.4; `solve(combate:accion_enemigo(E, A), P)` con un `bandido_torpe` y a Baldomero en el frente; aquí se omiten, marcados con `...`, los nodos de `puede_atacar/2` a partir del tercer nivel):

```
> explicar.
[ok] accion_enemigo(e(bandido_torpe, 1), atacar(baldomero))   [clausula 2 + corte]
   [ok] objetivo_mas_debil(e(bandido_torpe, 1), baldomero)   [clausula 1]
      [ok] findall(A-B, (combatiente(B, jugador), puede_atacar(e(bandido_torpe, ...   [findall: 1 solucion(es)]
         [ok] combatiente(baldomero, jugador)   [hecho]
         [ok] puede_atacar(e(bandido_torpe, 1), baldomero)   [clausula 1]
         ...
      [ok] msort([30-baldomero], [30-baldomero])   [builtin]
   [ok] corte   [corte: se descartaron las clausulas siguientes]
```

La cláusula 1 (`curarse`) no se aplicó y la 3 (`defender`) quedó descartada por el corte: es la lección de la Conf. 4. "Por qué *no* se curó" (los descartes de las cláusulas anteriores) es el registro de decisiones **(extra)** de §8.6.

**Pendiente de comprobar (V-06):** que las tildes y `« »` se vean bien en la **consola** de la entrega, con y sin `chcp 65001`. Lo comprobado es la ida y vuelta por tuberías (entrada `ir('aldeá').` leída como átomo y salida UTF-8 correcta a un archivo/tubería).

#### Graphviz `.dot` (extra)

- **Graphviz**: `prueba_a_dot/2` devuelve un átomo con el contenido del `.dot`. Un contador (acumulador) numera los nodos sin `assert`.

```
digraph prueba {
  rankdir=TB;
  node [shape=box, fontname="Helvetica", fontsize=10];
  n1 [label="puede_atacar(baldomero, bandido_torpe)\n[regla 1]", color="#2b6cb0"];
  n2 [label="vivo(baldomero)\n[hecho]", color="#2f855a"];
  n3 [label="\\+ aturdido(baldomero)\n[no]", color="#c05621"];
  n1 -> n2;
  n1 -> n3;
}
```

Código de color: `hecho` verde, `regla` azul, `builtin` gris, `no` naranja, fallo rojo (`por_que_no`), `corte` con borde discontinuo. Hay que **escapar** `\` y `"` en las etiquetas. `ui:escribir_archivo('out/prueba.dot', Texto)` lo guarda (la carpeta `out/` ya está en `.gitignore`); renderizar es externo: `dot -Tpng out/prueba.dot -o out/prueba.png` (Graphviz no es requisito del juego). Para árboles enormes se limita a 200 nodos y se pliega el resto en un nodo `...`.

### 6.12 Cómo evitar que las reglas del juego dependan del corte

Reglas de estilo (P7) y mecanismos que las hacen cumplir:

| Técnica | Ejemplo |
|---|---|
| **Condiciones excluyentes explícitas** en lugar de "si no, la siguiente" | `efectos_muerte/3` con `D >= V` y `D < V` en dos cláusulas (en vez de `!`). `fase/1` (§5.2) también. |
| **Negación en la última cláusula** | `fase(exploracion) :- \+ en_combate(_), …`. |
| **Datos en vez de control** | Prioridades de IA como tabla `regla_ia(N, E, Accion)` y selección del mínimo `N` (abajo). |
| **Sin `once/1`**; el "primero" se obtiene con `findall` + `msort` + cabeza, o con datos deterministas | `objetivo_mas_debil/2`. |
| **Un predicado = una relación**: sin cláusula comodín que dependa de las anteriores | La tercera cláusula de la IA (`defender`) es el *único* comodín y está en el módulo marcado. |
| **Linter** `explicar:verificar_reglas/1` **(extra)** | Con `clause/2`, recorrería los módulos de reglas y avisaría de: `!` fuera de `combate:accion_enemigo/2`; `!` anidado o duplicado; `assert*/retract*/write/format` en cuerpos; `once/1`; `\+` sobre variables que no aparecen antes en el cuerpo. En la mínima: revisión a mano, y el meta-intérprete ya lanza `corte_no_soportado` ante un `!` anidado. |

**La IA como caso estudiado.** El canon usa el corte deliberadamente (Conf. 4, corte que establece prioridad):

```prolog
% combate.pl (probado en 5.10.4) -- version canon, con corte
accion_enemigo(E, curarse)   :- vida_baja(E), tiene(E, pocion), !.
accion_enemigo(E, atacar(O)) :- objetivo_mas_debil(E, O), !.
accion_enemigo(_, defender).                 % canon: ":- true"; equivalente

% Gemela DECLARATIVA (sin corte): el numero de regla es dato, y la ganadora es la de N minimo
regla_ia(1, E, curarse)   :- vida_baja(E), tiene(E, pocion).
regla_ia(2, E, atacar(O)) :- objetivo_mas_debil(E, O).
regla_ia(3, _, defender).

accion_enemigo_sin_corte(E, A) :-
    regla_ia(N, E, A),
    \+ ( regla_ia(M, E, _), M < N ).
```

Dos lecciones para la exposición, ambas de la Conf. 4:

1. **El corte de la IA es "rojo"**: la tercera cláusula no repite las condiciones negadas de las anteriores, así que es cierta aunque curarse o atacar fueran posibles. **La versión con corte solo es correcta en modo `(+E, -Accion)`**: con `Accion` ya ligada (`accion_enemigo(e, defender)`) el corte no interviene y responde "sí" (el mismo fallo de `min2/3` en la Conf. 4). La versión sin corte es correcta en todos los modos.
2. **El corte se ve en el árbol**: el nodo es `regla(accion_enemigo(E, atacar(O)), 2, [..., corte])`; la presentación escribe `[clausula 2 + corte]` y, al final, `[corte: se descartaron las clausulas siguientes]` (probado, §6.11).

**Probado en 5.10.4 (modo):** con un bandido que sí puede atacar, `combate:accion_enemigo(E, defender)` (acción ya ligada) **tiene éxito** con la versión con corte y **falla** con `accion_enemigo_sin_corte/2`. Con `E` ligado y `Accion` libre, `accion_enemigo/2` y `solve/2` dan lo mismo.

**Acciones especiales (D-24).** La versión mínima es el canon de tres reglas más **como máximo tres** acciones especiales (`robar_queso`, `embestir`, `invocar_moho`), cada una con **su cláusula en `accion_enemigo/2` y su gemela en `regla_ia/3`** (para no romper el oráculo ni la lectura "prioridad N de M"). Los perfiles por enemigo de 01 §6.2 (11 acciones), el monólogo y el aura del jefe son **(extra)**.

El juego usa la versión con corte (canon). La sin corte **no se ejecuta en producción**: es el oráculo de una prueba que compara ambas sobre todos los estados de un universo pequeño (§11). Si el corte real fallase, el plan B (D-06) sería tratar `!` como hoja y **excluir `accion_enemigo/2` de la equivalencia**; ya no es necesario.

### 6.13 Relación con el árbol de derivación SLD (Conf. 3) (extra: el árbol SLD real)

El árbol que produce `solve/2` **no es** el árbol SLD completo; es una vista del mismo:

| | Árbol de derivación SLD (Conf. 3) | Árbol de prueba de `solve/2` |
|---|---|---|
| Nodos | Objetivos (resolventes) `G0, G1, …` | Átomos demostrados |
| Aristas | Cláusula-variante usada y umg | Relación "cabeza → cuerpo" |
| Ramas | Triunfo, fracaso (`fail`) e infinitas | Una sola rama de triunfo (una refutación), vista como árbol Y |
| Qué muestra | Todo el espacio de búsqueda con el retroceso | Por qué *esta* respuesta es cierta |
| Control | Selección izquierda + orden textual + profundidad con retroceso | El mismo |

La equivalencia: una refutación SLD se puede leer como un árbol Y/O; el árbol de `solve/2` es su proyección Y (las ramas de fracaso desaparecen, salvo en `por_que_no`, que es la proyección de las ramas de fracaso).

**Árbol SLD real (extra).** Para mostrar el árbol de la Conf. 3 con un programa pequeño de ejemplo (`examples/`, no con todo el juego, que sería gigantesco), un tercer predicado en `explicar`:

```prolog
% explicar.pl (boceto sin ejecutar) -- (extra)
% Arbol ::= exito | fallo | limite | nodo(Resolvente, [arco(Clausula, Hijo), ...])
arbol_sld(Meta, Prof, Arbol) :-
    sld([Meta], Prof, Arbol).

sld([], _, exito).
sld([A|Resto], Prof, Arbol) :-
    (   Prof =< 0
    ->  Arbol = limite
    ;   P1 is Prof - 1,
        findall(arco(Id, Hijo),                   % findall copia: cada rama tiene su propia sustitucion
                (   paso(A, Resto, Id, Nuevo),
                    sld(Nuevo, P1, Hijo) ),
                Arcos),
        (   Arcos == []
        ->  Arbol = fallo
        ;   Arbol = nodo([A|Resto], Arcos)
        )
    ).

% Un paso de resolucion SLD: cada solucion de paso/4 es una rama del arbol
paso(A, Resto, builtin, Resto) :-                 % predefinido: se ejecuta, no se abre
    hoja_conocida(A),
    call(A).
paso(A, Resto, clausula(I), Nuevo) :-
    \+ hoja_conocida(A),
    clause(A, Cuerpo, Ref),                       % clause/3 ya da una VARIANTE (variables frescas)
    nth_clause(_, I, Ref),
    conj_lista(Cuerpo, Metas),                    % [] si el cuerpo es true
    append(Metas, Resto, Nuevo).                  % el resolvente: cuerpo + resto del objetivo
```

Correspondencia con los conceptos de la conferencia:

- **Regla de selección** (primer átomo de la lista = izquierda) y **regla de ordenación** (orden de `clause/3`): las de Prolog.
- **Variante de cláusula** y renombrado `A11, A12…`: `clause/3` ya entrega una variante con variables frescas; para imprimir al estilo del curso (`XA11`) se renombrarían en `explicar` con el nombre de la cláusula + contador (`numbervars` + sufijo).
- **Sustitución respuesta computada**: la de §6.10 sobre las variables de la meta inicial.
- **Efecto del corte**: en el `findall` de arcos, cuando la cláusula tomada tiene un `!` y su prefijo tiene éxito, se marcan como `podada(Id)` las cláusulas siguientes (ramas discontinuas en `.dot`). Es lo que muestra el ejemplo `el_menor/3` de la Conf. 4.
- **Búsqueda**: la expansión completa por `findall` equivale a un recorrido de todo el árbol (no solo la primera rama de éxito de BPP-RC); el límite `Prof` evita las ramas infinitas de la Conf. 3 (`p(f(X)) :- p(X)`).

Ruta de implementación: **primero** `solve/2` y `por_que_no/2` (núcleo, semanas 1–3); **después**, si sobra tiempo, `arbol_sld/3` (extra).

---

## 7. Parser de comandos

### 7.1 Versión 1: términos Prolog terminados en punto (**probado en 5.10.4**)

Es la versión que se entrega sí o sí (canon §13). **D-03/D-07: no hay módulo `parser`.** `ui:leer_termino/2` lee con `read_term(user_input, T, [variable_names(Nombres)])` y captura los errores de sintaxis; `juego:validar_comando/2` comprueba que el término es un comando conocido con su aridad. El comando es un **término**, no un predicado invocable: se ejecuta con `juego:ejecutar/2`.

```prolog
% ui.pl (probado en 5.10.4)
iniciar :-
    set_stream(user_output, encoding(utf8)),
    set_stream(user_input, encoding(utf8)),
    prompt(_, '> ').

leer_termino(Termino, Nombres) :-
    catch( read_term(user_input, Termino, [variable_names(Nombres)]),
           error(syntax_error(_), _),
           ( Termino = '$error_sintaxis', Nombres = [] ) ).
```

```prolog
% juego.pl (probado en 5.10.4)
% ---- parser v1: valida un termino ya leido ----
comando(ayuda, 0).    comando(mirar, 0).    comando(ir, 1).      comando(descansar, 0).
comando(contratos, 0). comando(aceptar, 1). comando(pagar, 0).    comando(elegir, 1).
comando(compania, 0). comando(inventario, 0). comando(atacar, 1). comando(defender, 0).
comando(habilidad, 1). comando(explicar, 0). comando(explicar, 1). comando(por_que_no, 1).
comando(salir, 0).    comando(demo, 0).

validar_comando(T, Res) :-
    (   var(T)                 -> Res = error(comando_vacio)
    ;   T == end_of_file       -> Res = ok(salir)
    ;   T == '$error_sintaxis' -> Res = error(sintaxis)
    ;   callable(T), functor(T, N, A), comando(N, A) -> Res = ok(T)
    ;   Res = error(no_entiendo(T))
    ).
```

Comprobado con entrada por tubería (`printf 'ir(aldea).\nir(aldeá).\nir(\nsalir.\n' | swipl -q -s src/main.pl -g main -t halt`):

- `ir(aldea).` se ejecuta; `ir(aldeá).` (tilde, UTF-8) se lee bien como átomo y `ejecutar` responde con el diagnóstico de `por_que_no` en vez de fallar.
- Un término mal formado (`ir(` sin cerrar) produce `error(sintaxis)` y el juego sigue. **Cuidado**: tras un error de sintaxis, `read_term/2` descarta lo que queda hasta el siguiente `.`, así que si el jugador olvida el punto la línea siguiente se pierde; la ayuda debe decir "termina cada comando con un punto".
- `end_of_file` (Ctrl-D / fin de entrada) se trata como `salir`. Una entrada que se acaba sin `salir.` termina el programa con código 0.
- Con entrada no interactiva el prompt `> ` no se muestra (solo con terminal); no afecta a la lógica.
- `callable/1` (Conf. 6) rechaza números y variables. `comando/2` es la tabla de §7.3 (`comando(ir, 1)`, `comando(atacar, 1)`, …).
- Los comandos de la versión mínima son 16 (más `demo`); `nivel/1`, `arbol/1,2`, `usar`, `huir` y `comer` son **(objetivo)** y se añaden a `comando/2` y a la tabla de fases si entran. `guardar/1`, `cargar/1`, `reiniciar`, `lanzar`, `equipar` son **(extra)**.

### 7.2 Versión 2: palabras sueltas a términos (extra)

> **(extra)** (06 §5.1: "parser v2"). No entra en la versión mínima ni en el objetivo. Si se hace, nace como módulo `parser.pl` (el único de los tres separables que tendría sentido) y queda condicionado a V-06 (tildes en la consola de la entrega). Lo siguiente es el diseño, **boceto sin ejecutar**.

Pipeline: `línea (códigos) → normalizar → tokens → quitar relleno → patrones → término`.

```prolog
% parser.pl (boceto sin ejecutar)
parsear(Codigos, Res) :-
    normalizar(Codigos, Tokens),
    (   Tokens == []
    ->  Res = error(linea_vacia)
    ;   quitar_relleno(Tokens, Palabras),
        (   comando_palabras(Palabras, Cmd)
        ->  Res = ok(Cmd)
        ;   Res = error(no_entiendo(Tokens))
        )
    ).

normalizar(Codigos, Tokens) :-
    maplist(a_minuscula_ascii, Codigos, Cs),
    trocear(Cs, Tokens).

% Separar por espacios y puntuacion, sin cortes: tres clausulas excluyentes
trocear(Cs, Ts) :-
    saltar_separadores(Cs, Cs1),
    (   Cs1 == [] -> Ts = []
    ;   palabra(Cs1, Pal, Resto),
        atom_codes(T, Pal),
        Ts = [T|Ts1],
        trocear(Resto, Ts1)
    ).
palabra([C|Cs], [C|P], R) :- \+ separador(C), palabra(Cs, P, R).
palabra([],     [],    []).
palabra([C|Cs], [],    [C|Cs]) :- separador(C).

% Tabla de acentos por codigo (evita caracteres no ASCII en el fuente)
a_minuscula_ascii(C, A) :- C >= 0'A, C =< 0'Z, A is C + 32.
a_minuscula_ascii(C, A) :- acento(C, A).
a_minuscula_ascii(C, C) :- C < 127, \+ ( C >= 0'A, C =< 0'Z ).
a_minuscula_ascii(C, C) :- C >= 127, \+ acento(C, _).

acento(225, 0'a).  acento(233, 0'e).  acento(237, 0'i).
acento(243, 0'o).  acento(250, 0'u).  acento(241, 0'n).  acento(252, 0'u).
```

Las cuatro cláusulas son mutuamente excluyentes (sin corte). Pendiente (V-06): qué códigos entrega la **consola** de Windows (CP850/CP1252/UTF-8) para las tildes (por tubería con UTF-8 funciona); si no son estos, los comandos con tilde no se reconocerán, pero los escritos sin tilde (`compania`) sí.

**Reconocimiento.** Tabla de verbos y patrones, y alias de entidades:

```prolog
% parser.pl (boceto sin ejecutar)
relleno(a). relleno(al). relleno(el). relleno(la). relleno(los). relleno(las).
relleno(de). relleno(del). relleno(un). relleno(una). relleno(con). relleno(en).

verbo(ir, ir).        verbo(ve, ir).       verbo(mover, ir).
verbo(atacar, atacar). verbo(pegar, atacar). verbo(golpear, atacar).
verbo([por, que, no], por_que_no).         % verbo de varias palabras
% ...

comando_palabras([ayuda],       ayuda).
comando_palabras([salir],       salir).
comando_palabras(Palabras, Cmd) :-
    verbo_y_resto(Palabras, Nombre, Resto),
    argumentos(Nombre, Resto, Cmd).

argumentos(ir,      Resto, ir(Z))        :- entidad(zona, Resto, Z).
argumentos(aceptar, Resto, aceptar(C))   :- entidad(contrato, Resto, C).
argumentos(atacar,  Resto, atacar(O))    :- entidad(objetivo, Resto, O).
argumentos(explicar, Resto, explicar(S)) :- comando_palabras(Resto, S).   % recursivo
argumentos(por_que_no, Resto, por_que_no(S)) :- comando_palabras(Resto, S).
argumentos(nivel,   [N], nivel(N))       :- member(N, [resumido, detallado]).

% Alias: los multipalabra se comparan ya sin relleno ("bosque del moho" -> [bosque, moho])
entidad(Tipo, Palabras, Id) :- alias(Tipo, Id, Palabras).
alias(zona, bosque, [bosque]).
alias(zona, bosque, [bosque, moho]).
```

- Los `alias/3` apuntan a IDs de `01-lore-y-ambientacion.md`. Para no acoplar `parser` con `mundo`, la **consistencia se comprueba con una prueba** (§11): todo alias referencia un ID existente.
- Es el mismo estilo del curso: recursión sobre listas y unificación (Conf. 1–2); no hace falta DCG. Una versión con DCG sería equivalente (la gramática `-->` es azúcar sintáctico que SWI traduce a listas diferencia) y queda como **(extra)**; el canon ya la declara opcional y fuera del curso.
- Números (`usar pocion 2`): `number_codes/2` dentro de `catch/3` (ISO) para decidir si un token es entero.
- `por que no aceptar gallina noble` → tokens `[por, que, no, aceptar, gallina, noble]` → `por_que_no(aceptar(gallina_noble))`.
- Un comando que el parser entiende sintácticamente pero que no tiene sentido (zona inexistente) lo detecta `juego`, no el parser.

### 7.3 Tabla de comandos y traducción

**Versión mínima = 16 comandos**, más `demo` (meta-comando de `main`). Nuevos respecto al canon (D-20): solo `elegir/1`, `pagar` y `demo`. Marcados **(objetivo)** o **(extra)** los demás.

| Comando (v1) | Frases de ejemplo (v2, extra) | Término resultante | Fases | Qué hace / regla implicada |
|---|---|---|---|---|
| `ayuda.` | `ayuda`, `ayuda ir` | `ayuda` | todas | Lista `comandos_disponibles/2`. (`ayuda(Tema)` es **extra**.) |
| `mirar.` | `mirar` | `mirar` | todas menos `fin` | Descripción de zona. |
| `ir(Z).` | `ir bosque`, `ve a la aldea` | `ir(bosque)` | `exploracion`, `taberna` | `compania:puede_viajar/1` + día; al salir de la taberna sin pagar, impago. |
| `contratos.` | `contratos` | `contratos` | `exploracion`, `taberna` | `contratos:disponible/1`. |
| `aceptar(C).` | `aceptar gallina noble` | `aceptar(gallina_noble)` | `exploracion`, `taberna` | `contratos:puede_aceptar/1`. **Demostración 2** de `por_que_no`. |
| `elegir(N).` | `elegir 1` | `elegir(1)` | `exploracion`, `taberna`, `combate` | **Nuevo (04).** Opción numerada de un evento (p. ej. `gato_en_el_arbol`). |
| `pagar.` | `pagar`, `pagar sueldos` | `pagar` | `taberna` | **Nuevo (D-14).** `economia:puede_pagar_sueldos/0` + `efectos_sueldos/1`. |
| `compania.` | `compania`, `equipo` | `compania` | todas | Atributos, moral, huelga. |
| `inventario.` | `inventario`, `queso` | `inventario` | todas | Despensa y objetos. |
| `descansar.` | `descansar`, `dormir` | `descansar` | `taberna` | Gasta 2 quesos; día + curación. |
| `atacar(O).` | `atacar bandido` | `atacar(bandido_torpe)` o `atacar(baldomero, e(bandido_torpe, 1))` | `combate` | `juego` lo completa con el actor del turno y resuelve un tipo a su primera instancia viva; `combate:efectos_accion/3`. **Demostración 1** con `por_que_no`. |
| `defender.` | `defender` | `defender` | `combate` | Efecto `alterar(Actor, defendiendo, 1)`. |
| `habilidad(O).` | `habilidad bandido` | `habilidad(O)` | `combate` | **Una habilidad por personaje (D-23)**; la forma `habilidad(Id, Objetivo)` y las dos habilidades de Pimentina y Rufino son **extra**. |
| `explicar.` / `explicar(Acc).` | `explicar`, `explicar atacar bandido` | `explicar` / `explicar(atacar(…))` | todas | Última prueba, o resolución de la meta. **Demostración 3** tras un turno enemigo. |
| `por_que_no(Acc).` | `por que no aceptar gallina noble` | `por_que_no(aceptar(gallina_noble))` | todas | `explicar:por_que_no/2`. |
| `salir.` | `salir` | `salir` | todas | Meta-comando de `main`. |
| `demo.` | `demo` | `demo` | `exploracion`, `taberna` | Meta-comando de `main`: partida guionizada con semilla fija (03 C-9). |
| `nivel(N).` · `arbol(Acc).` · `usar(Obj).` · `huir.` · `comer(T).` | — | — | — | **(objetivo).** `comer` = ración extra voluntaria con el efecto del tipo (v1: cura 2; D-12). |
| `arbol(Acc, dot)` · `lanzar` · `equipar` · `guardar(N).` · `cargar(N).` · `reiniciar.` · `ayuda(Tema)` | — | — | — | **(extra).** |

> **Nota de coherencia con el canon.** `DISENO.md` escribe `atacar(bandido).` como comando y `explicar(atacar(baldomero, bandido))` como explicación. Se interpreta así: el comando del jugador tiene un argumento (el objetivo); el actor lo pone `juego` según el turno; en `explicar`, `atacar(A, B)` y `atacar(B)` son equivalentes. Se registra en §16.
>
> **Nota (X-02).** `explicar/1` y `por_que_no/1` **no son predicados invocables**: son términos que `validar_comando/2` acepta y `ejecutar/2` traduce con `objetivo_de_accion/2`. El README y los criterios de aceptación de 03 se leen como "dado el comando `ir(aldea)` ejecutado con `juego:ejecutar/2`…".

---

## 8. Combate

### 8.1 Representación

Todo es estado dinámico transitorio (§4.2) más reglas puras en `combate`:

| Concepto | Representación |
|---|---|
| Combatientes | `combatiente(Id, Bando)`, `Bando ∈ {jugador, enemigo}`. Los del jugador son los miembros de la compañía; los enemigos son instancias `e(Tipo, N)` con `instancia(e(Tipo,N), Tipo)`. |
| Vida | `vida(Id, V)` (la misma relación para todos). |
| Filas | `fila(Id, frente)` / `fila(Id, retaguardia)`. Cada bando tiene sus dos filas. |
| Estados alterados | `alterado(Id, aturdido, T)`, `alterado(Id, defendiendo, 1)`; las reglas usan los derivados `aturdido/1`, `cantando/1` (06 X-15). |
| Caídos | **`caido` solo existe dentro del combate** (D-17): al terminar, los caídos se levantan con 1 de vida (`terminar_combate`). Derrota = todos los miembros caídos (`derrota_combate`). |
| Clotilde (escolta de `gallina_noble`) | **D-33 (versión mínima): contador de golpes recibidos.** No es un combatiente: el contrato se resuelve con la vida del grupo y un `contador(golpes_a_clotilde, N)` que el enemigo suma al elegir como objetivo a la escoltada (resultado `exito`/`a_medias`/`fracaso` por umbral del contador). Si hay colchón, **combatiente temporal pasivo** (`combatiente(clotilde, jugador)`, sin turno, `vida_max` del contrato; 06 X-38). |
| Ronda | `en_combate(Ronda)`; existe el hecho solo durante el combate. |
| Turnos pendientes | `cola_turnos([Id, ...])`, ordenada por iniciativa al empezar la ronda. |

### 8.2 Reglas de fila

"Los de retaguardia solo pueden ser atacados cuando el frente cae, salvo ataques a distancia" (canon):

```prolog
% combate.pl (probado en 5.10.4; ataca_a_distancia/1 aqui es un hecho de ejemplo)
en_fila_alcanzable(A, B) :-
    bando_contrario(A, B),
    (   fila(B, frente)
    ;   \+ frente_con_vivos(B)           % el frente del bando de B ha caido
    ;   ataca_a_distancia(A)
    ).

bando_contrario(A, B)    :- combatiente(A, X), combatiente(B, Y), X \== Y.
frente_con_vivos(B)      :- combatiente(B, Bando), combatiente(F, Bando), fila(F, frente), vivo(F).
ataca_a_distancia(pimentina).     % en el juego: alcance(Tipo, distancia) / rol, dato en mundo (06 X-23)
```

Una sola cláusula con disyunción: la prueba muestra con `izq/der` **cuál** de las tres razones permitió el ataque. `puede_atacar/2` (canon §9.3) la usa tal cual.

### 8.3 Iniciativa y orden

```prolog
iniciativa(Id, I) :-
    ataque(Id, A), defensa(Id, D), bono_iniciativa(Id, M),
    parametro(base_iniciativa, B),
    I is B + A - D + M.

bono_iniciativa(Id, M) :- miembro(Id),    modificador_moral(Id, M).
bono_iniciativa(Id, 0) :- \+ miembro(Id).

orden_turnos(Ids) :-
    findall(K-P-Id,
            ( combatiente(Id, Bando), puede_actuar(Id),
              iniciativa(Id, I), K is -I, prioridad_bando(Bando, P) ),
            Pares),
    msort(Pares, Ordenados),                 % estable y determinista; mayor iniciativa primero
    ids_de(Ordenados, Ids).

prioridad_bando(jugador, 0).    % a igualdad de iniciativa, el jugador actua primero
prioridad_bando(enemigo, 1).    % y luego desempata el orden estandar de los IDs
```

- La iniciativa es un **valor derivado** de atributos efectivos (permitido por el canon). Si `01-lore-y-ambientacion.md` o el balance introducen un atributo `velocidad`, basta cambiar `iniciativa/2` (§16, decisión abierta).
- `puede_actuar(Id) :- vivo(Id), \+ esta_en_huelga(Id)` (los enemigos nunca están en huelga).

### 8.4 Ronda y turnos

`juego` conduce el combate; las reglas solo calculan:

```
iniciar_combate(Grupo)  -> combate:efectos_inicio(Grupo, Efs) ; aplicar        % ronda 1, cola = orden_turnos
bucle de combate (juego:avanzar_combate/1):
   1. si combate:fin_combate(Res) -> cerrar (victoria / derrota / huida)       % etapa de cierre
   2. si cola vacia -> efecto siguiente_ronda(orden_turnos)                    % ronda + 1
   3. actor = cabeza de cola
        - estado alterado "aturdido": mensaje, pierde turno, siguiente_turno
        - bando jugador  -> DEVOLVER el control al jugador (espera comando)
        - bando enemigo  -> decidir (IA), efectos_accion, aplicar, siguiente_turno, volver a 1
```

Tras cada comando del jugador, `avanzar_combate/1` ejecuta **todos los turnos enemigos consecutivos** hasta el siguiente turno de un miembro. Así el resultado de un comando incluye lo que hizo el enemigo.

Resolución de una acción como efectos puros (P4):

```prolog
% combate.pl (boceto sin ejecutar)
efectos_accion(A, atacar(B), Efectos) :-
    puede_atacar(A, B),
    dano(A, B, D),
    efectos_muerte(B, D, Muerte),
    append([dano(B, D), mensaje(golpe, [A, B, D])], Muerte, Efectos).

efectos_muerte(B, D, [mensaje(muere, [B])]) :- vida(B, V), D >= V.
efectos_muerte(B, D, [])                    :- vida(B, V), D < V.

efectos_accion(A, defender, [alterar(A, defendiendo, 1), mensaje(defiende, [A])]) :-
    puede_actuar(A).
```

`dano/3` es la del canon (`D is max(1, Atq - Def + M)`), con `modificador/3` para rasgos, moral y estados (p. ej. `teme_caballos` suma daño recibido de un enemigo `caballo`; `defendiendo` aumenta la defensa).

### 8.5 IA enemiga por prioridades

Es `accion_enemigo/2` de §6.12 (canon, probada en 5.10.4), más como máximo tres acciones especiales con su gemela (D-24). La tabla de prioridades es corta y es *dato* en la gemela sin corte (`regla_ia/3`). Predicados auxiliares puros: `vida_baja/1` (vida ≤ `parametro(umbral_vida_baja)` % de la máxima, con aritmética entera), `tiene/2` (`lleva(Id, Obj, N), N > 0`), `objetivo_mas_debil/2` (de los alcanzables, el de menor vida; desempate por ID con `msort`). La acción elegida se convierte en efectos con `efectos_accion/3`, igual que las del jugador (una sola vía de resolución).

### 8.6 Explicar un turno enemigo (mínima) y registro de decisiones (extra)

**Versión mínima (protege la demostración 3).** Tras un turno enemigo, `explicar` puede responder **por qué hizo eso** aunque el estado ya haya cambiado, porque `juego` guarda la prueba de la decisión **antes** de aplicar los efectos (`ultima_prueba/2`). Como `combate` no puede importar `explicar`, lo hace `juego`:

```prolog
% juego.pl (probado en 5.10.4; usa etapa/2 de §5.4)
% ---- turno enemigo (version minima: ultima_prueba, sin registro de descartes) ----
turno_enemigo(E, Accion, Items) :-
    (   explicar:solve(combate:accion_enemigo(E, Accion), Prueba) -> true ),   % primera solucion = decision real
    combate:efectos_accion(E, Accion, Efectos),
    etapa([guardar_prueba(accion_enemigo(E), Prueba)|Efectos], Items).

prioridad(E, Indice, Total) :-
    estado:ultima_prueba(accion_enemigo(E), regla(_, Indice, _)),
    predicate_property(combate:accion_enemigo(_, _), number_of_clauses(Total)).
```

Probado: con un bandido que ataca a Baldomero, `turno_enemigo/3` devuelve `atacar(baldomero)`, aplica el daño (Baldomero pasa de 30 a 29 de vida), guarda `ultima_prueba(accion_enemigo(E), Prueba)` y `prioridad/3` da "prioridad 2 de 3" (`number_of_clauses(3)`); `prueba_a_lineas/2` sobre la prueba guardada produce la salida de §6.11 con `[clausula 2 + corte]`.

**Registro de decisiones con descartes (extra).** Lo que sigue es el diseño completo: responde también **por qué no hizo otra cosa** (las prioridades anteriores). Es **boceto sin ejecutar** y queda fuera de la versión mínima (06 §5.1: "registro de decisiones de la IA" es extra):

```prolog
% juego.pl (boceto sin ejecutar) -- (extra)
turno_enemigo(E, Efectos) :-
    combate:accion_enemigo(E, Accion),                       % decision real (con corte)
    explicar:solve(combate:accion_enemigo(E, Accion), Prueba),
    Prueba = regla(_, Indice, _),                            % cual cláusula decidio
    findall(descarte(J, Diag),
            (   between(1, Indice, J), J < Indice,
                explicar:por_que_no_clausula(combate:accion_enemigo(E, _), J, Diag) ),
            Descartes),
    ronda_actual(R),
    estado:aplicar_efectos([registrar_decision(R, E, Accion, Indice, Prueba, Descartes)]),
    combate:efectos_accion(E, Accion, Efectos).
```

- `registro_decision(Ronda, Actor, Accion, Indice, Prueba, Descartes)` contiene: la prueba de la cláusula que ganó, su número (la prioridad) y, para cada cláusula **anterior** (de mayor prioridad), el diagnóstico de por qué no se aplicó (`por_que_no_clausula/3`: igual que `por_que_no/2` pero restringido a la cláusula `J`).
- Se calcula **en el momento de la decisión** (barato: la IA tiene 3 reglas) y se descarta al terminar el combate (`terminar_combate`); solo se conserva el último combate en memoria.
- Las acciones del jugador se registran con el mecanismo general de `ultima_prueba/2` (§6.2).
- Salida típica de `explicar` tras un turno enemigo (el narrador comenta aparte):

```
> explicar
Turno del Bandido torpe (ronda 2): atacar(sir_baldomero)   [prioridad 2 de 3]
[ok] accion_enemigo(e(bandido_torpe,1), atacar(baldomero))     [clausula 2 + corte]
  \- [ok] objetivo_mas_debil(...)  -> baldomero (vida 9, la mas baja)
Descartada la prioridad 1 (curarse):
  [no] vida_baja(e(bandido_torpe,1))    vida 12 de 12: no es baja
```

(Los símbolos son ASCII, D-26. La primera línea con "prioridad 2 de 3" sí sale de `prioridad/3`; las líneas de "Descartada…" son el extra.)

### 8.7 Fin de combate

`fin_combate/1`: `victoria` si no quedan enemigos vivos; `derrota` si **todos los miembros están caídos** (D-17: `derrota_combate`; los huelguistas no cuentan como "en pie" pero no se caen); `huida` es resultado de la acción `huir` **(objetivo)** (que, si se acepta, ya aplica `viajar(zona_previa)`; no se puede huir del jefe, D-29). Al terminar con `victoria`, `terminar_combate` levanta a los caídos con 1 de vida. Los efectos de cierre (moral, botín, resolución de contrato vía `contratos:resultado/3`) los calculan `combate` y `contratos`; `juego` los aplica y vuelve la fase a `exploracion`/`taberna` (derivada).

---

## 9. Guardado y carga de partida (extra)

> **Decisión D-32: no hay guardar/cargar en la versión 1.** Esta sección queda como **diseño (extra)**, **boceto sin ejecutar**, por si sobrara tiempo después de la semana 6. Ningún módulo mínimo depende de ella; solo `estado:persistente/1` (que sí existe y se usa para reiniciar) la haría posible. La versión mínima solo conserva `con_transaccion/1`, que sí está probado (§4.5).

**Viabilidad: sí, como (extra).** El estado persistente es pequeño (unas decenas de hechos) y §4.3 ya tiene la lista `persistente/1`; guardar y cargar son una consecuencia casi gratis de ese diseño. Es la respuesta propuesta a la decisión pendiente de `DISENO.md §18`, ahora resuelta como "no en v1".

**Reparto de responsabilidades** (para no romper P1/P3):

| Quién | Qué |
|---|---|
| `estado` | Convertir el estado en una lista de términos (`volcar_estado/1`) y restaurarlo validando (`restaurar_estado/1`). Sin E/S. |
| `ui` | Escribir y leer esa lista en un archivo (`escribir_terminos/2`, `leer_terminos/2`). |
| `main` | Orquestar los meta-comandos `guardar(N)`, `cargar(N)`, `reiniciar`. |

**Formato del archivo** (`saves/NOMBRE.sav`; la carpeta `saves/` y `*.sav` ya están en `.gitignore`): un término por línea, legible a mano.

```
guardado(1).
hecho(en_zona(aldea)).
hecho(dia(7)).
hecho(vida(baldomero, 27)).
hecho(queso(cheddar, 3, 4)).
```

```prolog
% estado.pl (boceto sin ejecutar)
volcar_estado([guardado(1)|Hs]) :-
    findall(hecho(H),
            (   persistente(N/A), functor(H, N, A), call(H) ),
            Hs).

restaurar_estado([guardado(1)|Hs]) :-
    forall(member(hecho(H), Hs), hecho_valido(H)),   % se valida TODO antes de tocar el estado
    \+ en_combate(_),
    reiniciar_estado,
    forall(member(hecho(H), Hs), assertz(H)).

hecho_valido(H) :- callable(H), ground(H), functor(H, N, A), persistente(N/A).

% Transaccion: foto del estado completo (persistente + transitorio) para deshacer
:- meta_predicate con_transaccion(0).
con_transaccion(Meta) :-
    foto(Foto),
    (   catch(Meta, E, ( restaurar_foto(Foto), throw(E) ))
    ->  true
    ;   restaurar_foto(Foto), fail
    ).
```

**Seguridad e integridad**

- **Nunca se ejecuta el contenido del archivo**: se leen términos con `read_term/2` y solo se hace `assertz` de hechos cuyo `Nombre/Aridad` está en `persistente/1`. No se usa `consult/1`.
- **Nombre de archivo saneado**: solo letras minúsculas, dígitos y `_`; la ruta siempre es `saves/<nombre>.sav` (sin `..` ni separadores).
- **No se guarda ni se carga durante un combate** (el estado transitorio no se persiste): error `no_disponible_en_combate`.
- Versión de formato en `guardado(1)`; otra versión ⇒ error `version_incompatible`.
- Carga fallida (archivo inexistente, término mal formado, hecho inválido) deja el estado **intacto**: la validación precede a `reiniciar_estado`.

**Reinicio**: `reiniciar` = `estado:nueva_partida/0` (no hace falta reiniciar el intérprete). `con_transaccion/1` es además la red de seguridad de §10 (probado). Para crear `saves/` si falta: `exists_directory/1` y `make_directory/1` (sin comprobar).

---

## 10. Manejo de errores y casos límite

### 10.1 Política

| Tipo de problema | Ejemplo | Mecanismo | Resultado para el jugador |
|---|---|---|---|
| **Error del jugador** (esperable) | Comando mal escrito, fuera de fase, objetivo inexistente, precondición no cumplida | **Datos, no excepciones**: `Resultado` con `error(Motivo)` y, si procede, `diag(Meta, Diag)` | Mensaje claro; con `por_que_no` automático cuando hay una regla que lo explica |
| **Entrada inválida** | Error de sintaxis (v1), línea vacía, `end_of_file` | `catch/3` en `ui:leer_termino/2`; `error(...)` en el parser | El juego continúa |
| **Violación de invariante** | Efecto con `N <= 0`, ID desconocido, quitar más queso del existente | Efecto cuya precondición no se cumple: **falla** (p. ej. `gastar_queso` de más; probado) o, si el efecto no existe, `throw(efecto_invalido(Efecto))` desde `estado` | `con_transaccion/1` **deshace** todo (probado); `ejecutar/2` lo captura y responde `error(interno(…))` o `error(sin_efecto(Cmd))` |
| **Error de programación** | Meta mal formada, predicado sin definir, `limite_profundidad`, `corte_no_soportado` | Excepciones estándar; `unknown` se deja en `error` (no `fail`) | Captura en `ejecutar/2` y en `main`; se imprime resumen y el detalle si `ajuste(depurar, true)` |
| **Datos inconsistentes** | Contrato que apunta a una zona inexistente | `juego:verificar_datos/1` al arrancar | Aborta el arranque con la lista de problemas |

Principios: (1) **ninguna excepción cruza `main`**: el bucle nunca termina por un error de juego; (2) **un comando es atómico** (`con_transaccion/1`): o se aplica entero o no se aplica; (3) fallo de una regla ≠ error: "no se puede" es una respuesta y se explica.

La versión **probada** de `ejecutar/2` (con la rama de fallo, que la v0.1 no tenía) está en §5.4.

### 10.2 Casos límite previstos

| Caso | Comportamiento esperado |
|---|---|
| Comando en fase incorrecta | `error(fuera_de_fase(Cmd, Fase))`; `ayuda` lista lo permitido. |
| `ir` a zona no adyacente, inexistente o a la actual | `compania:puede_viajar/1` falla; `por_que_no` dice "no hay `conexion/2` entre X e Y". |
| `aceptar` un contrato ya activo, no disponible, o con condición no cumplida | Falla `puede_aceptar/1`; el diagnóstico señala la condición (p. ej. `requiere(rasgo_no(teme_caballos))` falla por `rasgo(baldomero, teme_caballos)`). |
| Demasiados contratos activos | Límite en `parametro(max_contratos, N)`; diagnóstico `builtin_falso(…)`. |
| Despensa vacía en la ración | Efectos de hambre (`mod_moral` −1, `dano` **sin bajar de 1 de vida**, D-17; probado); nunca cantidades negativas. Si además no hay nada por cobrar al empezar el día, `fin(derrota_hambre)`. |
| Todo el queso es rancio | Se come igualmente (último recurso, política fresco → curado → rancio) con penalización de moral (−1). |
| Edad justo en el umbral (3 y 10) | Cubierto por `categoria_queso/2` (pruebas de frontera, §11). |
| Sueldos superan la despensa | `pagar` **no** paga a medias: `puede_pagar_sueldos/0` falla y `por_que_no(pagar)` lo explica (`hay_queso_para(…)`); el jugador puede no pagar y sufrir el impago −2 al salir (D-14). Probado. |
| Salir de la taberna sin pagar | −2 de moral por miembro activo (`mod_moral`), una vez por salida; al llegar de nuevo se vuelve a deber. Al empezar la partida no se debe nada. Probado. |
| `descansar` sin 2 quesos | Falla `puede_descansar/0`; `por_que_no(descansar)` lo explica (D-15, sin `deuda_taberna`). |
| Cantidad de queso llega a 0 | Se **borra** la fila `queso/3` (invariante `Cantidad > 0`). |
| Atacar a un objetivo muerto, o no alcanzable por filas | `puede_atacar/2` falla; diagnóstico. |
| Un solo golpe mata y quedan turnos en la cola | La cola se filtra con `puede_actuar/1` al llegar el turno. |
| Miembro en huelga | `puede_combatir/1` falla; pierde el turno con mensaje. La huelga se deriva solo de la moral (≤ 2). La `derrota` es "todos caídos", no "todos en huelga" (D-17). |
| Toda la compañía en huelga | Fuera de combate se sigue pudiendo viajar y descansar: **no hay bloqueo sin salida** (`puede_viajar/1` no exige combatientes). En combate, la derrota es todos caídos. Los caídos solo existen dentro del combate y al terminar se levantan con 1 de vida (D-17). La prueba de propiedades que lo comprobaría es **(extra)** (§11.5). |
| `huir` del jefe final | `huir` es **(objetivo)**; con él, `combate:efectos_accion(_, huir, _)` falla y el diagnóstico es "no se puede huir de un jefe" (D-29). |
| `usar` un objeto que no se tiene | Falla la regla (`lleva/3` con `N > 0`). |
| Objetivo ambiguo (`bandido` con varias instancias) | `juego` elige el primer vivo en orden de ID; se avisa en el mensaje. |
| `explicar` sin acción previa | `error(sin_ultima_prueba)`; sugiere `explicar(Accion)`. |
| `por_que_no` de una meta que **sí** es demostrable | Se responde "sí se puede" y se muestra la prueba (`por_que_no/2` falla y `juego` lo interpreta). |
| Prueba enorme | Las líneas largas se recortan a 72 caracteres (probado); aviso con `explicar:estadisticas/3` y propuesta de `nivel(resumido)` son **(objetivo/extra)**. |
| `limite_profundidad` | Error de programación (recursión infinita); no se oculta. |
| Archivo de guardado corrupto o de otra versión · nombre con `/`, `..` o mayúsculas · `cargar` en combate | **(extra)**: no hay guardado en v1 (§9). |
| Comando válido pero sin cláusula en la fase | `ejecutar/2` devuelve `error(sin_efecto(Cmd))`; nunca falla (probado, §5.4). |
| Error de sintaxis en la entrada | `error(sintaxis)`; se pierde lo que queda hasta el siguiente `.` (probado, §7.1). |
| Doble `assertz` de una clave que debe ser única (`en_compania`, `ajuste`) | `estado` hace *upsert*: `retractall` de la clave antes de `assertz`. |
| Semilla fuera de rango | `fijar_semilla/1` la normaliza con `mod 65536` (el valor 65536 es un punto fijo degenerado del generador, §4.4). |
| Entrada vacía / solo espacios (v2, **extra**) | `error(linea_vacia)`; no se cuenta como turno. |
| Fin de la entrada estándar (Ctrl-D) | Tratado como `salir` (probado). |
| Tilde mal codificada (v2, **extra**) | No reconocida; el mensaje sugiere escribir sin tildes. En v1 una tilde dentro de un átomo se lee bien con la entrada en UTF-8 (probado por tubería). |

---

## 11. Estrategia de pruebas con plunit

### 11.1 Organización

```
tests/
├─ todas.pl              % carga todo y deja listo run_tests/0 (D-31; nombre de 03/05)
├─ fixtures.pl           % escenarios: escenario_basico/0, escenario_hambre/0, escenario_combate/0 ...
├─ test_estado.pl        test_compania.pl     test_economia.pl    test_contratos.pl
├─ test_combate.pl       test_explicar.pl     test_juego.pl       test_narrador.pl
├─ (extra) test_eventos.pl   test_guardado.pl   test_arquitectura.pl   test_parser.pl   test_propiedades.pl
```

(`test_arbol.pl` desaparece: la presentación está en `explicar`; sus pruebas van en `test_explicar.pl`.)

- Cada archivo: `:- use_module(library(plunit))`, importa el módulo bajo prueba por ruta relativa (`'../src/combate'`) y abre `:- begin_tests(nombre).`
- Cada prueba que toca el estado usa `setup(escenario_X)` y `cleanup(estado:reiniciar_estado)`. Los escenarios (`fixtures.pl`) son hechos y llamadas a `estado:aplicar_efectos/1`, nunca `assert` directo, para ejercitar el mismo camino que el juego.
- **Ejecución (D-31, comprobada en 5.10.4):** `"C:\Program Files\pl\bin\swipl.exe" -q -s tests/todas.pl -g "run_tests,halt" -t "halt(1)"`. Sale con código **0** si todo pasa y **1** si una prueba falla (comprobado con un archivo de prueba que pasa y otro que falla). Con `-g run_tests -t halt` el código es 0 aunque falle algo, así que no sirve para integración automática. El archivo se pasa con `-s`, no como argumento posicional.
- **`library(plunit)` existe en 5.10.4 y detecta fallos** (V-03, V-14). Opciones probadas: `setup/1`, `cleanup/1`, `fail`, `true(X == V)`, `throws(E)`, `forall(Gen)` (genera una prueba por valor: `@(forall_opt,[0])`…) y `nondet`. Las pruebas que dejan un punto de elección imprimen un aviso (`succeeded with choicepoint`); se silencia con `nondet` o con metas deterministas. Los casos se escriben como cláusulas `test(nombre) :- Meta.`.

### 11.2 Qué probar por módulo

| Módulo | Casos clave |
|---|---|
| `estado` | `aplicar_efecto/1`: `dano` no baja de 0; `curar` no pasa del máximo; `mod_moral` acota 0–10 (D-08); `gastar_queso` borra la fila al llegar a 0 y falla por falta; `envejecer_quesos` suma 1 a todas; `viajar` solo a adyacentes; efecto desconocido lanza excepción; `reiniciar_estado` deja todo vacío; **`fase/1` tiene exactamente una solución en cualquier estado**; todo `dynamic` de `estado` está en `persistente/1` o `transitorio/1`. |
| `mundo` | `adyacente/2` simétrica; todos los `inicio/1` son cargables. |
| `compania` | `teme/2` derivada del rasgo; `esta_en_huelga/1` en el umbral exacto; `nivel_moral/2` en fronteras; `puede_combatir/1` excluye huelga y muertos; `puede_viajar/1`. |
| `economia` | `categoria_queso/2` en 0, 2, 3, 9, 10, 11; `valor_queso/3` creciente hasta curado y bajo en rancio; maduración; ración diaria con despensa suficiente, justa y vacía; orden de consumo **fresco → curado → rancio, y dentro de cada categoría el más viejo primero** (probado con 4 quesos de edades 0, 1, 4 y 12); el hambre no baja de 1 de vida (probado); `puede_pagar_sueldos/0` con despensa suficiente e insuficiente; `pagar` con lo más rancio primero; impago al salir; `puede_descansar/0`; efectos de comer rancio. |
| `contratos` | `puede_aceptar/1` con y sin la condición `rasgo_no(teme_caballos)` (con/sin Baldomero); `disponible/1` solo en su zona; `resultado/3` y `consecuencias/3` para éxito, fracaso y a medias; cobro único (no cobra dos veces). |
| `combate` | `dano/3` mínimo 1; modificadores de rasgos (Baldomero vs enemigo `caballo`); `en_fila_alcanzable/2` (frente, frente caído, a distancia); `orden_turnos/1` (iniciativa y desempate estables); `efectos_accion/3` produce los efectos esperados y **no modifica el estado**; IA en cada rama de prioridad; **IA con corte ≡ IA sin corte** en un universo de estados (§11.4); `fin_combate/1`. |
| `eventos` | **(objetivo)**: con semilla fija el evento del día es siempre el mismo; `tirada/4` en rango y de periodo 65536 (probado); enfriamiento respetado; ningún evento deja valores fuera de rango. En la mínima solo el motor de `elegir/1`. |
| `explicar` | Ver §11.3 y §11.4. |
| `explicar` (presentación) | Líneas esperadas para una prueba pequeña (comparación exacta) en ASCII; las dos demostraciones centrales producen el texto de §6.9; `resumir/3` reduce el nodo count **(objetivo)**; `.dot` **(extra)**. |
| `narrador` | Todo `frase/3` tiene clave con forma válida y plantilla (`Fmt-Args` con tantos `~w` como argumentos); `comentario/4` devuelve siempre un texto (frase genérica si falta); con el mismo `Uso` devuelve la misma variante y con `Uso` consecutivos rota (probado: `Llegáis a…` / `Otra vez…`). El narrador no necesita `estado` para probarse. |
| `juego:validar_comando/2` (parser v1) | Términos válidos (cada `comando/2`) e inválidos (`baila`, `ir`, número, variable, `end_of_file`, `'$error_sintaxis'`). **(extra)** parser v2: tabla `caso(Linea, Esperado)` y "todo alias apunta a un ID existente". |
| `juego` | `verificar_datos/1` devuelve `[]` con los datos reales y detecta un ID roto en un caso preparado; `ejecutar/2` nunca falla ni lanza; fuera de fase ⇒ error; un `ir` completo cambia zona, día, quesos y deja el estado coherente; una transacción deshace tras una excepción forzada; `pagar` sin queso devuelve `diag`; salir de la taberna sin pagar baja la moral; **todo comando de `comando/2` tiene respuesta en cada fase** (nunca `sin_efecto` en la versión terminada). |
| `ui`/`main` | Poca lógica: prueba de humo del bucle leyendo una entrada guionizada desde un archivo/`with_output_to` (sin comprobar). |
| Arquitectura | §11.5. |

Ejemplos (los marcados † se ejecutaron en 5.10.4 con `plunit`; el resto, boceto sin ejecutar):

```prolog
:- begin_tests(economia).

test(frontera_fresco)  :- economia:categoria_queso(2, fresco).                    % †
test(frontera_curado)  :- economia:categoria_queso(3, curado), economia:categoria_queso(9, curado).   % †
test(frontera_rancio)  :- economia:categoria_queso(10, rancio).

test(inicio, [setup(estado:nueva_partida), cleanup(estado:reiniciar_estado)]) :-        % †
    estado:queso(cheddar, 0, 12).

test(transaccion_deshace, [setup(estado:nueva_partida), cleanup(estado:reiniciar_estado)]) :-   % †
    \+ estado:con_transaccion(estado:aplicar_efectos([ganar_queso(brie, 0, 1), gastar_queso(brie, 0, 5)])),
    \+ estado:queso(brie, _, _).

test(efecto_desconocido, [throws(efecto_invalido(_))]) :-                              % †
    estado:aplicar_efecto(foo).

test(maduracion, [setup(estado:nueva_partida), cleanup(estado:reiniciar_estado)]) :-
    estado:aplicar_efectos([envejecer_quesos]),
    estado:queso(cheddar, 1, 12).

test(sin_comida_baja_moral, [setup(escenario_sin_queso), cleanup(estado:reiniciar_estado)]) :-
    economia:efectos_racion(Es),
    memberchk(mod_moral(baldomero, D), Es),
    D < 0.

:- end_tests(economia).

:- begin_tests(combate).

test(dano_minimo, [setup(escenario_combate), cleanup(estado:reiniciar_estado)]) :-
    combate:dano(rufino, e(bandido_torpe, 1), D),      % ataque bajo contra defensa alta
    D >= 1.

test(baldomero_no_ataca_caballos, [setup(escenario_combate_montado), cleanup(estado:reiniciar_estado), fail]) :-
    combate:puede_atacar(baldomero, e(bandido_montado, 1)).

test(efectos_no_tocan_estado, [setup(escenario_combate), cleanup(estado:reiniciar_estado)]) :-
    foto_basica(Antes),
    combate:efectos_accion(baldomero, atacar(e(bandido_torpe, 1)), _),
    foto_basica(Despues),
    Antes == Despues.

foto_basica(L) :-         % vida/2, moral/2 y queso/3 (volcar_estado/1 es extra)
    findall(H, ( member(N/A, [vida/2, moral/2, queso/3]), functor(H, N, A), call(H) ), L).

:- end_tests(combate).
```

### 11.3 Pruebas del meta-intérprete y de `por_que_no`

| Prueba | Qué comprueba |
|---|---|
| **Equivalencia directa ↔ `solve/2`** (§11.4) | Mismas soluciones y mismo orden. |
| Estructura de la prueba | Para metas conocidas: raíz `regla(G, I, Hijos)`; `corte` presente en la cláusula esperada de la IA; `no(G)` para la negación; `si/sino` para un if-then-else de prueba. |
| Hojas | Predicados de lista (`member/2`, `append/3`) aparecen como `builtin(...)` y **no se abre** `lists`. |
| Límite | Un predicado recursivo infinito de prueba lanza `limite_profundidad(_)`. |
| Dinámicos | Un hecho dinámico aparece como `hecho(...)`; un dinámico vacío falla (mundo cerrado). |
| `por_que_no/2` ⇔ `\+ call(G)` | Para cada meta del conjunto: si `\+ call(G)` entonces `por_que_no(G, _)` tiene éxito; si `call(G)` tiene solución, `por_que_no` falla. |
| Causa raíz esperada | `puede_atacar(baldomero, e(bandido_montado,1))` ⇒ el diagnóstico contiene `neg_viola(_, _)` con `teme(baldomero, caballo)`; `aceptar(gallina_noble)` con Baldomero ⇒ condición `rasgo_no`. |
| Tamaño | `resumir(P, resumido, R)` produce menos nodos que `P`. |

### 11.4 Equivalencia entre ejecución directa y meta-intérprete

El corazón de la verificación (canon §16). Para un conjunto de metas `objetivo_equiv/1` y varios escenarios:

```prolog
% test_explicar.pl (boceto de la prueba; el mismo cálculo se ejecutó en 5.10.4 sobre estas 11 metas y las IAs de dos enemigos)
objetivo_equiv(compania:esta_en_huelga(_)).
objetivo_equiv(economia:categoria_queso(_, _)).         % con 'between' sobre edades en el escenario
objetivo_equiv(combate:orden_turnos(_)).
objetivo_equiv(combate:dano(_, _, _)).
objetivo_equiv(combate:puede_atacar(_, _)).
objetivo_equiv(combate:accion_enemigo(_, _)).           % con corte
objetivo_equiv(contratos:puede_aceptar(_)).
objetivo_equiv(estado:fase(_)).

mismas_soluciones(Meta) :-
    findall(Meta, call(Meta), Directas),
    findall(Meta, explicar:solve(Meta, _), ViaMeta),
    Directas =@= ViaMeta.                               % variantes: mismo orden, mismas instancias

test(equivalencia) :-
    forall(escenario(Esc),
           (   call(Esc),
               forall(objetivo_equiv(M), mismas_soluciones(M)),
               estado:reiniciar_estado )).

% Oraculo del corte: version con corte == version declarativa sin corte
test(ia_corte_igual_sin_corte) :-
    forall(( escenario(Esc), call(Esc), estado:combatiente(E, enemigo) ),
           (   combate:accion_enemigo(E, A1),
               combate:accion_enemigo_sin_corte(E, A2),
               A1 == A2 )).
```

Se pide además que el *orden* de las soluciones coincida (`=@=` sobre listas) y se repite sobre al menos tres escenarios (inicio, hambre, combate con rasgos). **Prueba de modo**: `accion_enemigo(E, defender)` con la acción ligada es el caso en que la versión con corte *difiere* de la declarativa (§6.12); se documenta con un test que lo evidencia (`fail`/`true` explícito) como lección de la Conf. 4.

**Probado en 5.10.4** (D-06, X-04): la prueba de equivalencia se ejecutó sobre `esta_en_huelga/1`, `teme/2`, `activo/1`, `nivel_moral/2`, `moral_media/1`, `fase/1`, `orden_turnos/1`, `dano/3`, `puede_atacar/2`, `en_fila_alcanzable/2` y `accion_enemigo/2` (con `E` libre y con cada enemigo), más `rec/1`, `cond/2`, `cortado/1`, `cortado2/1`, `con_lista/1` y `todos_ok/0` de un módulo de prueba. **Todas coinciden en soluciones y orden** (`=@=`), incluidas las que llevan corte (`cortado2/1` da dos soluciones, no seis). Como los cinco módulos de ejemplo eran pequeños, queda pendiente repetirlo (V-11) con los módulos reales y un combate completo.

### 11.5 Pruebas de arquitectura y de propiedades

- **(extra)** **Capas** (`test_arquitectura.pl`): recorre `current_module/1`, `module_property(M, exports(L))` o `predicate_property(M:H, imported_from(D))` (sin comprobar en 5.10.4); construye aristas y las compara con la tabla de §2.2; falla si hay una arista no permitida o un ciclo. También: nombres exportados únicos (§2.3).
- **(extra)** **Linter limpio**: `explicar:verificar_reglas(Avisos)` devuelve `[]`: sin `!` fuera de `accion_enemigo/2`, sin `assert/retract/write/format` en módulos de reglas.
- **(extra)** **Partidas aleatorias con semilla** (propiedades): `partida_aleatoria(Semilla, Pasos)` elige comandos válidos con `tirada/4`, los ejecuta con `juego:ejecutar/2` y tras cada paso comprueba invariantes: vidas en `[0, max]`, morales en `[0, 10]`, `queso/3` con `Cantidad > 0` y sin pares `(Tipo, Edad)` repetidos, `dia/1` único y no decreciente, `fase/1` con exactamente una solución, ningún `ejecutar/2` lanza o falla. Con semillas fijas (p. ej. 1..50) es reproducible; sirve también para detectar **bloqueos sin salida**.
- **(extra)** **Guardar/cargar**: `volcar → restaurar → volcar` es la identidad; un archivo con un hecho no persistente se rechaza sin alterar el estado.

### 11.6 Cobertura mínima para dar el núcleo por bueno

Semana 4 (cierre del núcleo, canon): `estado`, `economia`, `combate` (daño, filas, IA), `juego` y `explicar` (equivalencia con corte, hojas, límite, las dos demostraciones centrales de `por_que_no` y la de `explicar` sobre un turno enemigo), todos en verde. Las pruebas de arquitectura y de propiedades son **(extra)**. Semana 6: el resto y un recorrido completo automatizado (`partida_de_ejemplo` en `examples/`, que además sirve de demo).

---

## 12. Estilo de código

### 12.1 Nombres

| Elemento | Convención | Ejemplos |
|---|---|---|
| Átomos y predicados | `snake_case` ASCII, sin `ñ` ni tildes | `dano/3`, `camino_real`, `esta_en_huelga/1` |
| Consultas booleanas | `puede_…`, `es_…`, `esta_…`, `hay_…`, `tiene/2` | `puede_atacar/2`, `hay_queso/0` |
| Cálculo de efectos | `efectos_…` | `efectos_racion/1`, `efectos_accion/3` |
| Conversión | `a_…` / `X_a_Y` | `prueba_a_lineas/2` |
| Hechos de datos | Sustantivo en singular | `zona/2`, `rasgo/2`, `enemigo/4` |
| Variables | `CamelCase` significativo; `_` anónima; `_Nombre` si no se usa a propósito; listas en plural; acumuladores `Acc`/`Acc0`, `Acc1` | `Atacante`, `Objetivo`, `Miembros` |
| Orden de argumentos | Entradas primero, salidas al final; el "sujeto" (ID) primero | `dano(+Atacante, +Objetivo, -Dano)` |
| IDs | `snake_case`; instancias de enemigo `e(Tipo, N)` | `bandido_torpe`, `e(bandido_torpe, 2)` |
| Predicados auxiliares privados | No exportados; mismo prefijo semántico que el público; sin sufijos crípticos | `frente_con_vivos/1` |

### 12.2 Comentarios y documentación (estilo PlDoc)

- Cabecera de archivo: una línea con el nombre y otra con la descripción, **en ASCII sin tildes** (como las de los módulos ya creados en `src/`).
- Cada predicado exportado lleva un bloque PlDoc con modos y determinismo:

```prolog
%!  puede_atacar(+Atacante, +Objetivo) is semidet.
%
%   Cierto si Atacante puede atacar a Objetivo ahora mismo: ambos estan
%   vivos, el objetivo es alcanzable por filas, el atacante no esta
%   aturdido y no tiene miedo a la clase del objetivo.
%
%   @see en_fila_alcanzable/2
puede_atacar(A, B) :-
    vivo(A),
    vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( teme(A, Clase), clase(B, Clase) ).
```

- Modos: `+` entrada, `-` salida, `?` indistinto; determinismo: `is det`, `is semidet`, `is nondet`. PlDoc con `%!` es solo convención (comentarios inertes, sin comprobar que 5.10.4 los procese); en cualquier caso son comentarios inertes y el formato antiguo `%%` es equivalente en intención.
- Comentarios de intención, no de repetición del código. Cualquier **corte** lleva un comentario `% CORTE: motivo` (solo existe en la IA). Cualquier número de balance va a `parametro/2`, no al código.
- El humor y el texto visible van a `narrador.pl`; los comentarios del código son técnicos.

### 12.3 Formato

- Sangría de 4 espacios, sin tabuladores; líneas de hasta 100 caracteres.
- Cabeza y `:-` en la primera línea; **un objetivo por línea**, coma al final; punto en el último. Línea en blanco entre predicados distintos; cláusulas de un mismo predicado, contiguas.
- `if-then-else` y disyunciones con la disposición habitual (comprobada en todo el código probado de este documento):

```prolog
    (   Condicion
    ->  Entonces
    ;   Sino
    )
```

- Operadores locales con `:- op(...)` solo si mejoran la lectura de reglas (Conf. 5), declarados en la lista de exportación del módulo que los define (**extra**).
- No usar cadenas con comillas dobles (§13). Texto visible: átomos entre comillas simples.

### 12.4 Directivas y orden dentro del archivo

1. Comentario de cabecera.
2. `:- module(nombre, [exportados]).` — lista ordenada y comentada por grupos.
3. `:- use_module(library(lists), [append/3, member/2, nth0/3, nth1/3]).` — **importaciones explícitas** de biblioteca (evita colisiones y dependencias de autocarga).
4. `:- use_module(otro_modulo).` — solo módulos de capas inferiores (§2.2).
5. `:- dynamic …` — únicamente en `estado.pl`.
6. `:- meta_predicate …` si procede.
7. `:- discontiguous …` — solo para tablas de datos que se agrupan por tema (`narrador:frase/2`, `mundo:parametro/2`), nunca para reglas.
8. Código: primero lo exportado, después los auxiliares.

`:- style_check(-singleton)` y similares **no se usan**: los avisos de variables singleton detectan errores de tipeo.

---

## 13. Compatibilidad con SWI-Prolog

### 13.1 Versión (decidida, D-02/06 O-7)

Se desarrolla y entrega con **SWI-Prolog 5.10.4, la versión del curso** (64 bits, Windows). Ya no hay "subconjunto común con 9.x": el código usa solo lo que funciona en 5.10.4. La v0.1 sugería desarrollar en 9.x; esa opción queda descartada.

| Dato | Valor |
|---|---|
| Ejecutable | `C:\Program Files\pl\bin\swipl.exe` (también `swipl-win.exe`). **No está en el PATH**: se usa la ruta completa o un alias. |
| Arranque del juego (desde la raíz del repositorio) | `"C:\Program Files\pl\bin\swipl.exe" -q -s src/main.pl -g main -t halt` **(comprobado)**. El fichero va con `-s`; como argumento posicional después de `-g`/`-t` falló con `source_sink ... does not exist`. |
| Orden de las pruebas | `"C:\Program Files\pl\bin\swipl.exe" -q -s tests/todas.pl -g "run_tests,halt" -t "halt(1)"` **(comprobado)**: sale con código **0** si todas pasan y **1** si alguna falla (V-04). Con `-g run_tests -t halt` el código de salida es 0 aunque falle una prueba. |
| Pendiente de confirmar con la profesora | Que la evaluación usa la misma versión y que se permiten módulos, `plunit` y `assert/retract` aislados en `estado` (D-35). |

### 13.2 Comprobado en 5.10.4 el 2 de noviembre de 2026

| Característica | Veredicto | Notas |
|---|---|---|
| `library(plunit)` | **Funciona** | Existe y detecta fallos. Probadas opciones `setup/1`, `cleanup/1`, `fail`, `true(…)`, `throws(…)`, `forall(…)` y `nondet` (V-03, V-14); `begin_tests/end_tests`. Avisa "succeeded with choicepoint" si una prueba deja puntos de elección (se evita con `nondet` o cortando la meta). |
| `atomic_list_concat/2,3` | **Funciona** (también en modo separar: `atomic_list_concat(L, ',', 'a,b,c')` da `[a,b,c]`) | Permitido (la v0.1 lo prohibía). |
| `format/2,3`, `format(atom(_), …)`, `with_output_to/2` | **Funcionan** | Usar `~w ~a ~d ~n ~q ~W`; `~t~|` (columnas) **probado**: `format('~a~t~10|~a~n', [ab, cd])` alinea. `~W` con `numbervars(true)`, `quoted(false)` y `spacing(next_argument)` funciona. |
| `clause/2,3`, `nth_clause/3`, `strip_module/3`, `meta_predicate` | **Funcionan** | Sobre estáticos y dinámicos de otros módulos; `nth_clause(_, I, Ref)` con `Ref` ligada da el número de cláusula (V-01). `meta_predicate` con `0` funciona. |
| `predicate_property/2` | **Funciona** con `dynamic`, `number_of_clauses(_)`, `imported_from(_)`, `built_in` | **`predicate_property(_, defined)` NO funciona** (devuelve fallo siempre): usar `dynamic` o `number_of_clauses(_)` (un dinámico sin cláusulas tiene `number_of_clauses(0)`). |
| `maplist/2..5` con predicados normales, `include/exclude/partition`, `predsort`, `msort`, `aggregate_all`, `setof/bagof` con `^`, `assoc` | **Funcionan** | `msort/2` y `keysort/2` bastan para ordenar (sin `sort/4`). |
| `sumlist/2` | Existe | `sum_list/2` **no existe**. En el proyecto la suma se escribe a mano (`suma/3` con acumulador). |
| `foldl/4-6`, `max_member/2`, `sort/4`, `random_between/3`, `random_member/2`, `split_string/4`, `atom_string/2`, `read_term_from_atom/3`, `library(yall)` (`>>`) | **No existen** | Prohibidos. Azar: LCG propio (§4.4). Texto: átomos y `atomic_list_concat/3`. |
| Cadenas con `"…"` | **Son listas de códigos** (`double_quotes=codes`) | Texto visible siempre en átomos con comillas simples. |
| `:- encoding(utf8).` | **Funciona al cargar** | Debe ir **antes** de los caracteres no ASCII del archivo, pero **después** de `:- module(...)`, que tiene que ser el primer término: con la directiva delante, la 5.10.4 falla con "Undefined procedure: module/2" y "Domain error: `module_file' expected" (comprobado al escribir `src/mundo.pl`, 3 nov). Los comentarios de cabecera, en ASCII, no molestan. Sin la directiva el fuente se lee como Latin-1 y se rompe. |
| Salida de `✔ ✘ ├─` con la codificación por defecto | **Se degrada** | Por eso el árbol usa ASCII (§6.11). |
| `set_stream(user_output, encoding(utf8))` | **Funciona** | Salida UTF-8 correcta a tubería/archivo; **consola de Windows sin comprobar** (V-06). |
| `read_term/2` con `variable_names(Vs)`, `prompt/2` | **Funcionan** | Un error de sintaxis se captura con `catch/3` (`error(syntax_error(_), _)`); el resto de la cláusula se descarta (§7.1). Fin de entrada devuelve `end_of_file`. |
| `random/1`, `random_permutation`, `set_random(seed(N))` | Existen | **No se usan**: no garantizan la misma secuencia entre ejecuciones/versiones (reproducibilidad de la demo). |
| `succ/2`, `between/3`, `nth0/nth1`, `last/2`, `numbervars/3`, `copy_term/2`, `msort`, `upcase_atom/2`, `sub_atom/5` | **Funcionan** | `numbervars/3` + `~W` con `numbervars(true)` imprime las variables como `A`, `B`. |
| Aritmética | `7/2` da `3.5`; `7//2` da `3`; `-7 mod 3` da `2`; `-7 // 2` da `-3` | Usar `//` para división entera; porcentajes como `V * 100 =< M * P` (probado en `vida_baja/1`). Los enteros son suficientes para el LCG. |
| `->`, `;`, `\+`, corte transparente | **Seguros** | Probados en el meta-intérprete (§6). `*->` no se usa. |
| `clause/2,3` sobre estáticos | **Funciona** | No activar el flag `iso`. |
| Cláusulas no contiguas | **Aviso** | Los hechos de un mismo predicado deben ir juntos o declararse `:- discontiguous` (tablas de datos como `mundo:parametro/2`, `narrador:frase/3`). |
| Barra invertida en Prolog dentro de comandos de shell | **Cuidado al preparar scripts** | Al escribir `'\\+ ~w'` desde un shell hay que cuidar el escapado; en un archivo `.pl` `'\\+'` es el átomo `\+`. |
| Mensajes de error | **Con cuidado** | El texto cambia entre versiones; las pruebas no deben compararlo. |
| Límites de pila | **Con cuidado** | La 5.x tiene pilas por defecto más pequeñas; la profundidad de `solve` está limitada (400). Pendiente de medir con un combate real (V-11). |

### 13.3 Pendiente de comprobar (de 06 §7.2)

| # | Qué | Estado |
|---|---|---|
| V-06 | Tildes, `¿`, `« »` y `ñ` en la **consola** de Windows, con y sin `chcp 65001` | Pendiente (la tubería funciona). Sin esto, el parser v2 queda descartado. |
| V-08 (parcial) | `read_line_to_codes/2` y su valor al fin de entrada | No usado en la mínima (se lee con `read_term/2`); solo hace falta para el parser v2 (extra). |
| V-11 | Rendimiento y profundidad de `solve/2` con un combate real | Pendiente (tras el primer combate). |
| V-12 | Citas al manual 5.6.59 | El manual no está en el repositorio; la versión instalada es 5.10.4. Las citas de esta versión del documento se han sustituido por comprobaciones directas. |

---
## 14. Matriz de conceptos del curso

Lo que interesa al evaluador: dónde se *demuestra* cada tema de las conferencias 1–6 y cómo.

| Módulo | Conferencias | Cómo se demuestra |
|---|---|---|
| `mundo` | 1, 2, 6 | **Hechos** como base de datos relacional (relación extensional) y `adyacente/2` como relación **intencional** (Conf. 3: padre/abuelo). Consultas con variables = unificación. |
| `estado` | 6, 4, 2 | BD dinámica: `dynamic`, `assertz`, `retract`, `retractall`; `functor/3` para tratar predicados como datos; la **hipótesis del mundo cerrado** (Conf. 4) define qué es "falso" en el estado; módulos con exportación (Conf. 6). |
| `compania` | 1, 2, 4, 5 | Reglas con rasgos (`teme/2` derivada por unificación), **negación** en `puede_combatir/1`, umbrales aritméticos de moral, listas de miembros. |
| `economia` | 5, 1, 4, 6 | **Aritmética** de valor, edad y raciones (`is`, `mod`, `max`, `//`); recursión sobre listas con acumuladores (consumo secuencial de la despensa); cláusulas **excluyentes** en `categoria_queso/2`; `findall` para la despensa. |
| `contratos` | 2, 4, 6 | **Unificación de términos estructurados** (`escoltar(X)`, `requiere(rasgo_no(R))`); condiciones con **negación**; `findall`/`forall` sobre el catálogo; base de las explicaciones de "por qué no se puede aceptar". |
| `combate` | 4, 5, 1, 3 | **Corte** de prioridad en la IA frente a su gemela sin corte (cortes rojos/verdes, `min2/3` de la Conf. 4); negación en `puede_atacar/2`; aritmética de daño con `max/2`; listas de turnos y `msort/2`; el control de la IA ilustra el orden de cláusulas del árbol SLD (Conf. 3). |
| `eventos` | 5, 6, 2 | Generador congruencial con `mod` en `estado:tirada/4` (aritmética pura, sin `random`; periodo 65536 comprobado); `findall` de candidatos; unificación de condiciones. Eventos aleatorios **(objetivo)**. |
| `explicar` | **3**, **4**, **6**, 2 | Meta-intérprete "vainilla" con `clause/3`, `call/1`, `functor/3`; **regla de selección por la izquierda y orden de cláusulas** (Conf. 3); corte y negación en el intérprete; `por_que_no` como recorrido de las ramas de fracaso; (extra) **árbol SLD real** con variantes renombradas y sustitución respuesta computada; módulos y metapredicados. |
| `explicar` (presentación; antes `arbol`) | 3, 1, 6 | Representación de árboles como términos; recursión sobre estructuras; `numbervars`, `copy_term`; `format(atom(_), …)` para construir líneas. El árbol SLD real y `.dot` son **(extra)**. |
| `narrador` | 1, 2, 6 | Tabla de hechos `frase/3` consultada por **unificación** (clave más específica = menos variables); variantes por aritmética modular con un contador que le pasa `juego`. Puro. |
| `juego:validar_comando/2` (parser v1) | 1, 2, 4 | *Pattern matching* por unificación (`functor/3`, `callable/1`) y cláusulas excluyentes; manejo de errores con `catch/3`. El parser v2 de listas (extra) sería recursión sobre listas, sin DCG. |
| `juego` | 6, 4 | Composición de reglas y efectos; `findall`; `if-then-else`; transacción como control de estado. |
| `ui`, `main` | — (contraste) | El **único** sitio impuro: sirve para mostrar el contraste declarativo/imperativo (Conf. 1). El bucle es recursión por la cola. |
| Pruebas | 3, 6 | Equivalencia `call/1` ↔ `solve/2`; el oráculo "con corte ≡ sin corte" demuestra la tesis de la Conf. 4 (el corte es control, no lógica). |

**Guion de demostración sugerido para la exposición** (cada paso enseña un concepto):

| Paso | Comando | Concepto |
|---|---|---|
| 1 | `por_que_no(atacar(baldomero, bandido_montado)).` (**demostración 1**) | Negación como fracaso: la causa raíz es un `\+` que falla porque el hecho negado es cierto (Conf. 4). |
| 2 | `por_que_no(aceptar(gallina_noble)).` (**demostración 2**) | Mundo cerrado y reglas anidadas hasta la causa raíz (Conf. 4); con `venda_de_caballos`, la misma meta se demuestra. |
| 3 | Turno enemigo + `explicar.` (**demostración 3**) | Corte de prioridad visible en la prueba: `[clausula 2 + corte]` (Conf. 4). |
| 4 | Pruebas: `run_tests.` | Equivalencia `call/1` ↔ `solve/2` y oráculo "con corte ≡ sin corte". |
| 5 | `explicar(atacar(baldomero, bandido_torpe)).` | Prueba como árbol Y con valores de variables (Conf. 3); `explicar(…)` hipotético es **(objetivo)**. |
| 6 | (objetivo) `nivel(detallado).` y repetir; `arbol(…)` en texto | Granularidad del meta-intérprete (Conf. 6). |
| 7 | (extra) `arbol(…, dot)`; árbol SLD real de un programa pequeño con corte | Conf. 3 + 4 en una imagen. |

---

## 15. Riesgos técnicos y decisiones abiertas

### 15.1 Riesgos

| # | Riesgo | Prob. | Impacto | Estado y mitigación |
|---|---|---|---|---|
| R1 | **Módulos + `clause/2`**: el meta-intérprete depende de cómo SWI resuelve `clause(M:G, B)` con predicados importados y dinámicos. | ~~Media~~ **Baja** | Alto | **Resuelto por el spike (2 de noviembre)**: funciona en 5.10.4 con `imported_from/1`, `number_of_clauses/1` y `nth_clause/3`. Lo que no funcionaba (`predicate_property(_, defined)`) está sustituido (§6.4). Plan B (módulos en `user`) ya no hace falta. |
| R2 | Semántica del corte en `regla/4` (`!` en la rama `then`). | ~~Baja~~ **Resuelto** | Alto | **Comprobado** con casos de corte y con la IA (§6.5). El plan B (corte como hoja y excluir `accion_enemigo/2` de la equivalencia) queda solo como respaldo documentado. |
| R3 | **Encoding/Unicode en Windows** (tildes, `« »`). | Media | Medio | Árbol en ASCII; `set_stream(…, encoding(utf8))` + `:- encoding(utf8).`; tubería comprobada. **Falta la consola de la entrega (V-06)**, primera semana. |
| R4 | ~~Versión de SWI-Prolog y disponibilidad de `plunit`~~ | — | — | Cerrado: 5.10.4 decidida; `plunit` existe y detecta fallos. Solo queda confirmar con la profesora (D-35). |
| R5 | **Árboles enormes** (`findall` con muchas soluciones, recursión). | Media | Medio | Muestra en `findall` (3), niveles `resumido` **(objetivo)**; las líneas largas se recortan a 72 caracteres. |
| R6 | **Estado global y aislamiento de pruebas**. | Media | Medio | `reiniciar_estado/0` en `cleanup` de cada prueba; fixtures por efectos; un único escritor (P3). |
| R7 | **Efectos calculados contra estado viejo** (acciones compuestas, traductores). | Media | Medio | P4 por etapas (§5.4); `perder_queso` se expande al aplicarlo (§4.5). |
| R8 | **`por_que_no` incompleto** (negaciones anidadas, varias cláusulas, recursión). | Media | Medio | Alcance acotado: una causa raíz; casos complicados documentados. Las dos demostraciones centrales ya funcionan con datos de ejemplo. |
| R9 | **Alcance**: Nivel A ≈ 65 h frente a 50-62 h. | Alta | Alto | Recorte de 06 §5: 12 módulos, 16 comandos, 4 contratos, 5 enemigos; todo lo demás **(extra)**. Control semanal: pasar a Nivel B si el desvío supera 3 h un viernes. |
| R10 | La IA con corte es correcta **solo** en modo `(+,-)`. | Alta | Bajo | Documentado y probado (`accion_enemigo(E, defender)` ligado es cierto con corte y falso sin corte). |
| R11 | **Soft-lock** (nada que hacer: todos en huelga, sin queso). | Media | Medio | `puede_viajar/1` no exige combatientes; el hambre termina la partida (`derrota_hambre`); huelga derivada solo de la moral. |
| R12 | Árbol SLD real (extra) explosivo. | Alta | Bajo | **(extra)**, solo para programas pequeños de `examples/`. |
| R13 | **`ejecutar/2` que falla o lanza** con un comando validado sin implementación. | Media | Medio | Contrato "nunca falla" con red de seguridad (§5.4); prueba de que todo comando de `comando/2` tiene respuesta en cada fase. |
| R14 | **Barras invertidas** al generar o editar código desde scripts de shell (`\+` se convierte en `+`). | Media | Bajo | Editar los `.pl` con el editor, no con `sed`/`echo`. |

### 15.2 Decisiones abiertas → cerradas por 06

| # | Decisión | Estado |
|---|---|---|
| D1 | Versión de SWI-Prolog | **Cerrada (D-02): 5.10.4.** Falta confirmar con la profesora (D-35). |
| D2 | ¿Guardar/cargar en la versión 1? | **No (D-32).** El diseño de §9 queda como **(extra)**. |
| D3 | Política de comida diaria | **Fresco → curado → rancio (D-11).** |
| D4 | Significado del comando `comer` | **Ración extra voluntaria con el efecto del tipo (D-12)**; v1: cura 2; "Debería". |
| D5 | Iniciativa | Derivada (`10 + A − D + M`); cambiar si el lore añade `velocidad`. |
| D6 | Aleatoriedad | **LCG propio (D-25)**, reproducible. `random_*` no existen o no son reproducibles. |
| D7 | Vida 0 fuera de combate | **Cerrada (D-17):** `caido` solo existe dentro del combate; al terminar se levantan con 1 de vida; el hambre no baja de 1. |
| D8 | Salida con símbolos | **ASCII para símbolos, UTF-8 para el texto (D-26).** |
| D9 | Número de contratos, enemigos y eventos | Mínima: 4 contratos, 5 enemigos, 0 eventos aleatorios (D-21, D-28). |
| D10 | Exposición | En vivo con semilla fija y plan B grabado (D-36); `demo` como guion. |
| D11 | Calcular el registro de la IA | **(extra).** En la mínima solo `ultima_prueba/2` con la prueba de `accion_enemigo`. |
| D12 | Fusionar `arbol` en `explicar` | **Hecho (D-07).** |
| D13 | Comandos nuevos | **Solo `elegir/1`, `pagar` y `demo` (D-20).** |
| D14 | Modelo de Clotilde en el combate | **Contador de golpes recibidos** en la mínima (D-33 B); combatiente temporal pasivo si hay colchón. |

### 15.3 Orden de construcción sugerido (guía técnica; el calendario maestro es el de 03)

06 §6 fija el arranque; 06 §5.3 lista las tareas que faltaban en el backlog de 03 (`estado:aplicar_efectos`, `juego:ejecutar` y `objetivo_de_accion`, lectura de términos, `pagar`, `elegir/1`, `clave_de_diag/2`, Clotilde, finales). Dentro de cada semana de 03, el orden técnico es:

| Semana (03) | Entregable técnico | Corte "mínimo viable" |
|---|---|---|
| 1 (hoy 2 – 6 nov) | `mundo` (hechos) → `estado` (hechos dinámicos y efectos mínimos, `tirada/4`) → `compania` → `juego` + lectura de términos en `ui` + `main` (`ir`, `descansar`, `mirar`, `ayuda`, `salir`) → una prueba plunit y la orden única de pruebas. **El spike de `solve/2` ya está hecho** (§6.4): se traslada el código probado a `src/explicar.pl`. Comprobar la consola (V-06). | Un `ir` consume un día y se puede `por_que_no(ir(…))`. |
| 2 | `economia` (ración, `pagar`, descanso, impago), presentación del árbol en `explicar`, narrador mínimo (`comentario/4`), `clave_de_diag/2` | `explicar`/`por_que_no` sobre varias reglas con frases. |
| 3 | `combate`: filas, daño, iniciativa, `efectos_accion`; IA con corte y gemela; `ultima_prueba/2` | Combate completo contra un enemigo; demostración 1 y 3. |
| 4 | `contratos` (4), `elegir/1` y motor de evento mínimo, finales; **partida mínima completa el 27 de noviembre**; demostración 2 | Un recorrido completo hasta el jefe. |
| 5 | Colchón (3 h); **(objetivo)**: `nivel`, `arbol`, `usar`, `huir`, `comer`, 2 contratos más, eventos | Solo si el colchón está intacto. |
| 6 | Pruebas, balance (`parametro/2`), narrador, README, informe, exposición; `demo` | Partida de ejemplo en `examples/`. |

---

## 16. Cambios propuestos al canon (`DISENO.md`)

Ninguno se ha aplicado a `DISENO.md` desde este documento; 06 §3 los consolida y decide cuáles se aceptan. Estado tras la revisión: C1 **parcial** (solo `estado` y `juego`; `parser`/`arbol` fundidos), C2-C6 aceptados, C7 aceptado con valores 0-10, C8 aceptado salvo `guardar`/`cargar`, C9-C10 aceptados, C11 aceptado (ASCII para símbolos), C12 aceptado como interfaz, C13 sustituido por el calendario de 03, C14 aceptado solo el oráculo, C15 **rechazado** (guardar → extra; versión 5.10.4).

| # | Sección del canon | Cambio propuesto | Motivo |
|---|---|---|---|
| C1 | §10 Arquitectura | Añadir `estado.pl`, `juego.pl`, `parser.pl` y `arbol.pl` (con alternativa de fusionar `arbol` en `explicar`). | Cumplir P1–P4 sin mezclar E/S, orquestación y reglas; poder probar el parser y el estado sin consola (§2.1). |
| C2 | §11.1 Meta-intérprete | El criterio de "hoja" pasa de `predicate_property(G, built_in)` a "no es un predicado de los módulos del juego" (`modulo_juego/1`), manteniendo que los predefinidos son hojas. | `member/2`, `append/3`… son de biblioteca y no `built_in`: el criterio del canon descendería al código de `lists` (§6.4). |
| C3 | §11.1 Formato de prueba | `regla(G, P)` → `regla(G, I, Hijos)` (número de cláusula y lista de hijos); se añaden `si/2`, `sino/1`, `izq/1`, `der/1`, `agregado/3`, `todos/2`, `corte`, `llamada/2`, `truncada/1`; `no(G)` se mantiene. | Permitir explicar el corte, el `if-then-else`, `findall` y mostrar unificadores (§6.3). |
| C4 | §11.4 `por_que_no` | El boceto `primer_fallo/2` se sustituye por `diag/4` con un formato de diagnóstico (`fallo`, `neg_viola`, `builtin_falso`…) y `por_que_no_clausula/3`. | Resolver los casos que el propio canon deja abiertos: varias cláusulas, negaciones anidadas, corte (§6.9). |
| C5 | §9.2 Estado | Se añaden hechos dinámicos: `en_compania/1`, `lleva/3`, `contrato_por_cobrar/2`, `contrato_cerrado/2`, `evento_visto/2`, `semilla/1`, `ajuste/2`, `fin_partida/1` y los transitorios de combate. Los `actualizar_*` del canon pasan a ser predicados internos de `estado`, invocados desde `aplicar_efecto/1`. | El canon lista solo seis; la economía, el combate y los eventos necesitan más (§4.2). |
| C6 | §9.2 / P4 | Las reglas no modifican el estado: devuelven **efectos** (datos) que aplica `estado:aplicar_efectos/1`. | Permite explicar y probar una acción sin ejecutarla (§1.1 P4, §4.5). |
| C7 | §6 Economía y §4 | Los valores "provisionales" (umbrales de edad, moral) pasan a hechos `parametro/2` en `mundo`. | Un solo lugar para el balance; la prueba muestra el umbral (§4.1). |
| C8 | §13 Comandos | Normalizar `atacar(O)` (jugador) y `atacar(A, O)` (en `explicar`); añadir los meta-comandos `salir`, `guardar/1`, `cargar/1`, `reiniciar`; `arbol(Acc, Formato)`; `nivel(resumido)`/`nivel(detallado)` como dos formas, no una sola con `;`. | Eliminar la incoherencia entre §13 y §11.2; completar lo necesario para jugar (§7.3). |
| C9 | §11.2 `explicar` | Definir dos usos: *hipotético* (estado actual) y *retrospectivo* (prueba guardada antes de aplicar efectos en `ultima_prueba/2`). | Tras actuar, el estado ya cambió; sin esto "por qué funcionó" no se puede responder (§6.2). |
| C10 | §8 IA | Documentar que el corte es "rojo" y la versión con corte solo es correcta en modo `(+E, -Accion)`; añadir la gemela `accion_enemigo_sin_corte/2` como oráculo de pruebas (la tercera cláusula se escribe `accion_enemigo(_, defender).`, equivalente a `:- true`). | Convierte el uso del corte en material de exposición (Conf. 4) y lo hace verificable (§6.12). |
| C11 | §11.3 Salida | Los símbolos `✔ ✘ ├─` pasan a ser la opción Unicode; la salida por defecto puede ser ASCII. | Compatibilidad con consolas de Windows y con SWI-Prolog 5.x (§13). |
| C12 | §12 Narrador | Selección determinista de variantes de frase (según semilla/día) y `comentario_prueba/3` que elige el nodo más relevante; `frase/2` se mantiene. | Variedad cómica sin romper la reproducibilidad. |
| C13 | §15 Plan de trabajo | Adelantar `por_que_no` a la semana 3 y el cierre del núcleo a la semana 4 con las pruebas de §11.6; `estado` y `juego` en la semana 1–2. | Es la característica central y la más arriesgada; más margen para corregirla (§15.3). |
| C14 | §16 Pruebas | Añadir: oráculo con corte ≡ sin corte, pruebas de propiedades con semilla, prueba de arquitectura (capas), prueba de alias del parser. | Verificación de principios del diseño y no solo de reglas (§11). |
| C15 | §18 Decisiones pendientes | Proponer: guardar/cargar **sí** como (extra) de las semanas 5–6; versión de SWI: subconjunto común 5.10.4/9.x (§13.1). | Responder las dos primeras decisiones pendientes. |

---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 tras `docs/06-revision-y-decisiones.md` (el autor aceptó todas sus recomendaciones). "Probado" = ejecutado en SWI-Prolog 5.10.4 con scripts temporales fuera del repositorio.

| # | Qué cambió | Motivo |
|---|---|---|
| 1 | Nota inicial; versión de SWI-Prolog 5.10.4; etiquetas "probado en 5.10.4" / "boceto sin ejecutar" en cada bloque de código; definición de la versión mínima (12 módulos, 16 comandos) | D-02, D-21, 06 §5 |
| 2 | **12 módulos**: `parser` se funde en `juego`/`ui` (parser v1) y `arbol` en `explicar`; `frases` queda en `narrador`. Tabla de módulos, dependencias, capas, API y matriz del curso reescritas | D-07, X-01 |
| 3 | Comando = **término** validado por `juego:validar_comando/2` y ejecutado por `juego:ejecutar/2`; `explicar/1` y `por_que_no/1` no son predicados invocables | D-03, X-02 |
| 4 | **Solo `estado.pl` escribe** en la base de datos; los `actualizar_*` de 03 y 04 son auxiliares privados detrás de `aplicar_efecto/1`; contadores del narrador (`usos_frase/2`) en `estado`; narrador puro (`comentario/4` recibe el contador) | D-04, D-25, X-01, X-06 |
| 5 | **Vocabulario único de efectos** (§4.5) ampliado con `marcar/desmarcar`, `contar`, `ganar_descansos`, `visitar`, `equipar`, `uso_frase`, `envejecer_lote`, `ganar/gastar_objeto`; **traductores** de 04 y 05 (`contratos:expandir_contrato/3`, `eventos:expandir_evento/2`), probados | D-05, X-03 |
| 6 | `solve/2` con **corte real**: spike hecho y funciona; meta-intérprete, `por_que_no` y presentación reescritos con el código probado; plan B (corte como hoja) documentado como innecesario; equivalencia probada con 11 metas y las IAs | D-06, X-04, V-01, V-02 |
| 7 | Moral **0-10**, inicio 6, huelga ≤ 2 (derivada solo de la moral); niveles `alta/normal/baja/critica` con cifras provisionales | D-08, X-24, X-25 |
| 8 | 12 cheddar iniciales; queso única moneda, sin tienda en v1 (tienda de objetos = extra); pago por unidades | D-09, D-10, D-13, X-26, X-33 |
| 9 | Ración diaria **fresco → curado → rancio** (más viejo primero dentro de cada categoría), probada; el hambre nunca baja la vida de nadie de 1 | D-11, D-17, X-28 |
| 10 | `comer` = ración extra voluntaria con efecto del tipo (v1: cura 2), "Debería"; `pagar` como comando explicable con impago −2 al salir de la taberna (probado); `descansar` cuesta 2 quesos, sin `deuda_taberna` | D-12, D-14, D-15, X-29, X-30, X-31 |
| 11 | Nombres canónicos aplicados en firmas y ejemplos: `puede_viajar/1`, `puede_habilidad/2`, `esta_en_huelga/1`, `permite_combate/1` (zona) frente a `puede_combatir/1` (personaje), `alterado/3` + derivados, `lleva/3` + `equipado/2`, `miembro/activo/en_pie`, `contrato_cerrado/2` + derivados, `categoria_queso/2`, `queso_total/1`, `condicion_cumple/1`, `aplicar_efectos/1`; `teme/2` consciente de la venda | D-16, D-19, X-12 a X-20 |
| 12 | Contratos: aridad 5 del canon con vocabulario de 04 y `via_objetivo/2`; mínima `eliminar`, `derrotar`, `evento`, `escoltar`; Clotilde como contador de golpes (combatiente temporal si hay colchón) | D-18, D-33, X-36, X-38 |
| 13 | Caídos solo en combate (se levantan con 1 de vida); derrota = todos caídos (`derrota_combate`) o `derrota_hambre`; no se huye del jefe; ids de derrota de 04 | D-17, D-29, X-44, X-45 |
| 14 | Comandos nuevos: solo `elegir/1`, `pagar` y `demo`; tabla de fases y de comandos reescrita; una habilidad por personaje con `habilidad(Objetivo)` | D-20, D-23, X-40, X-43 |
| 15 | IA: canon de 3 reglas + como máximo 3 acciones especiales con su gemela; registro de decisiones con descartes pasa a **(extra)**; en la mínima, `ultima_prueba/2` y `prioridad/3` (probados) para la demostración 3 | D-24, X-42 |
| 16 | Generador LCG propio con propiedades medidas (periodo 65536, uniforme); la semilla se normaliza `mod 65536` (corrige el `mod 65537` anterior); `random_*` eliminados | D-25, X-09, O-1, V-09 |
| 17 | Texto visible en `frase/3` (estática) con claves `texto(…)`; `clave_de_diag/2` definido; `nombre/2` normaliza `e(T,_)`; símbolos ASCII (`[ok]`, `[no]`, `\-`, `\|-`) y UTF-8 solo para texto con `set_stream` | D-26, D-27, X-07, X-11, X-19, X-21, O-6 |
| 18 | §13 sustituida por lo comprobado en 5.10.4 (ruta, `plunit`, `atomic_list_concat`, `format`, `clause`, `nth_clause`, `strip_module`, `meta_predicate`, `maplist`, `encoding(utf8)`, comillas dobles = listas de códigos, lo que no existe); `predicate_property(_, defined)` → `number_of_clauses(_)`/`dynamic` | O-2 a O-5, O-7, O-8, X-10 |
| 19 | Pruebas: `tests/todas.pl` y orden con `-s … -g "run_tests,halt" -t "halt(1)"` (código de salida comprobado); equivalencia de 02 conservada; arquitectura, propiedades, linter, parser v2, `.dot`, árbol SLD real, niveles `resumido/detallado` marcados extra/objetivo | D-31, X-08, 06 §5.1 |
| 20 | Guardar/cargar (§9) pasa a **(extra)**, diseño conservado | D-32, 03 C-7 |
| 21 | Riesgos y decisiones (§15) actualizados (R1, R2, R4 resueltos; nuevos R13 y R14); orden de construcción alineado con 03; §16 con el estado de cada propuesta | D-01, X-05 |
| 22 | Hallazgos de las pruebas incorporados: `ejecutar/2` debe tener rama de fallo (si no, el bucle reintenta); `perder_queso` se expande en el momento de aplicar; cantidad 0 no genera `ganar_queso`; tras un error de sintaxis se pierde el resto hasta el siguiente `.`; en 5.10.4 el fichero va con `-s` | pruebas del 2 de noviembre |

**Pendiente de decisión del autor o de comprobación** (no se ha resuelto aquí): V-06 (tildes en la consola de la entrega), V-11 (rendimiento de `solve/2` con módulos reales), el reparto exacto de nombres de eventos de 05 en `eventos`, y las respuestas de la profesora (D-34 a D-38).
