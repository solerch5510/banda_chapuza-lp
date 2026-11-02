# Banda Chapuza — Funcionalidades, etapas y entrega final

> Documento de planificación de producto de la fase de diseño. Complementa a [DISENO.md](DISENO.md), que sigue siendo la fuente de verdad: aquí no se cambia nada del canon en silencio; todo lo que se propone modificar está en la sección 15.
>
> **Revisado el 2 de noviembre de 2026 tras docs/06: alineado con las decisiones aceptadas** (D-01 a D-38 y contradicciones X-nn de [06-revision-y-decisiones.md](06-revision-y-decisiones.md)). Qué cambió y por qué: tabla final "Registro de cambios de la revisión". Lo recortado no se ha borrado: queda marcado **(extra)** u **(objetivo)**.
>
> Fecha de redacción original: sábado 31 de octubre de 2026 · Entrega final: **viernes 11 de diciembre de 2026** (semana 15 del curso) · Exposición presencial: inicio del siguiente semestre (o antes, si se solicita).
>
> Proyecto individual. Dedicación asumida (D-01): **10 horas semanales**, es decir, **62 h** en total (6 semanas × 10 h + las 2 h de la sesión previa S0, que no se hizo y se recupera en la semana 1). Alcance: recorte **"Nivel A"** (≈ 65 h declaradas: 62 h de tareas + 3 h de reserva); si el viernes hay un desvío acumulado mayor de 3 h se pasa al **Nivel B** (≈ 57 h). Se desarrolla con **SWI-Prolog 5.10.4**, la versión del curso (D-02).

---

## 1. Objetivo de entrega y criterio de éxito

### 1.1 Qué debe existir el 11 de diciembre

1. Un juego **jugable de principio a fin** desde `swipl src/main.pl` (SWI-Prolog 5.10.4, instalado en `C:\Program Files\pl\bin`, fuera del PATH: el README documenta el alias o la ruta completa): arrancar en la taberna, aceptar contratos, viajar (gastando días), gestionar queso, sueldos (`pagar`) y moral, combatir y llegar al jefe final de las Cuevas del Roquefort, con final de victoria (`chapuza`) y finales de derrota (`derrota_combate`, `derrota_hambre`).
2. El **modo explicar** funcionando sobre las reglas reales del juego (no sobre un ejemplo aparte): `explicar` y `por_que_no(Acción)` obligatorios, que son **comandos** del juego (términos ejecutados por `juego:ejecutar/2`, no predicados sueltos); `arbol` y `nivel` si el tiempo lo permite (objetivo).
3. Un **conjunto de pruebas** (plunit) que se ejecuta con un solo comando y pasa, incluida la prueba de que el meta-intérprete y la ejecución directa dan los mismos resultados (con y sin corte).
4. Una **partida de demostración reproducible** en `examples/` (semilla fija, generador propio) con su salida guardada.
5. Documentación: README actualizado (versión 5.10.4, ruta, orden de arranque, qué es "extra"), DISENO.md reflejando lo realmente construido, informe/memoria si el curso lo pide (ver sección 9) y guion de la exposición.
6. Etiqueta `v1.0-entrega` en el repositorio.

### 1.2 Criterio de éxito (lo que decide si el proyecto "vale")

El evaluador busca **conocimientos o aplicaciones de la programación declarativa**. Por tanto el proyecto tiene éxito si, en cinco minutos de demo, se ve que:

- **Las reglas del juego se leen como especificación** (p. ej. `puede_atacar/2` casi es la frase en español).
- **El programa puede justificar sus propias decisiones**: se pregunta *por qué* y la respuesta sale del árbol de derivación, no de mensajes escritos a mano. Las tres demostraciones centrales (D-21, 06 §5.4) son: `por_que_no(atacar(baldomero, bandido_montado))`, `por_que_no(aceptar(gallina_noble))` y `explicar` sobre un turno enemigo con corte.
- **Cada concepto del curso (conferencias 1–6) tiene un lugar concreto** donde se usa con intención (matriz de la sección 11).
- El juego **funciona sin fallos** durante la demo y es lo bastante divertido para que el humor no distraiga del contenido técnico.

Criterio mínimo ("si solo se logra esto, se aprueba la idea"): un recorrido jugable corto + `explicar` + `por_que_no` sobre reglas de combate y contratos + pruebas. Todo lo demás es mejora.

### 1.3 Alcance de la versión entregable (recorte Nivel A, 06 §5.1)

**Mínima** = lo que se compromete (Debe). **Objetivo** = solo si el viernes 27 de noviembre hay un adelanto de al menos 3 h sobre la tabla del calendario (06 lo condiciona a que el colchón de S5 siga intacto; ver 4.3). **Extra** = contenido ampliable que se conserva en los documentos 01, 04 y 05 pero **no forma parte de la entrega**; el README lo dice abiertamente.

| Elemento | Mínima (Debe) | Objetivo | Extra |
|---|---|---|---|
| Zonas | 6 en datos; 5 con contenido (`bosque` solo de paso) | 6 con contenido | — |
| Miembros | 4 | 4 | reclutas |
| Rasgos con regla | 2 (`teme_caballos`, `hechizos_de_cocina`) | 4 | — |
| Habilidades | 4 (una por personaje) | 5 (+ `silencio_pagado`) | 6 |
| Contratos | **4**: `ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real` | **6**: + `peaje_del_ganso`, `fantasma_charlatan` | 9: `silvestre_para_ricota`, `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna` |
| Enemigos | **5**: `rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort` | 7: + `ganso_recaudador`, `arquero_aburrido` | 12 |
| Acciones especiales de IA | 3 (`robar_queso`, `embestir`, `invocar_moho`) | 5 | 11 |
| Objetos | 2 (`venda_de_caballos`, `pocion`) | 5 (+ `cucharon_de_hierro`, `sello_real`, `estoque_de_parmesano`) | 20 |
| Tipos de queso | 2 (`cheddar`, `brie`) | 4 (+ `queso_silvestre`, `roquefort`) | 8 |
| Tienda | No | No | Tienda de objetos (D-10) |
| Estados | `huelga` (derivado), `caido`, `defendiendo` | + `cantando` | `apestado`, `alerta` |
| Jefe | IA con las 4 reglas de 01 + invocación; sin fases, sin entrada de cuevas ni puerta interior; no se puede huir de él | fase "apurado" y bonus por rancio | monólogo, aura, arcos, `madurado` |
| Finales | 3: `chapuza`, `derrota_combate`, `derrota_hambre` | 5: + `leyenda`, `quiebra` | 7 |
| Arcos personales | 0 | 2 (B1 La Venda, R1) | 10 |
| Eventos de campaña (04) | 1 (`t_bienvenida`) | 3 | 15 |
| Pasos de tutorial | 6 (T1, T3, T4, T5, T7, T9) | 9 | 12 |
| Eventos aleatorios (05) | 0 | 5 (`rata_en_la_despensa`, `moho_en_la_despensa`, `tuerca_encuentra`, `mesa_coja`, `cumple_de_un_queso`) | 19 |
| Frases del banco | ≈ 70 (las 32 del núcleo de 05 §8.4 + viaje, combate básico, hambre, sueldos, inicio y fin) | ≈ 120 | todo |
| Gags | 0–1 (`caballo`) | 3 (`caballo`, `registro`, `silencio`) | 12 |
| Comandos | 16: `ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir` (más el meta-comando `demo` de `main`, necesario para F-33) | + `nivel`, `arbol`, `usar`, `huir`, `comer` | `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar` |
| Módulos | 12 | 12 | `parser`, `arbol`, `frases` por separado |
| Funciones de 02 | `ultima_prueba/2` (para explicar el turno enemigo), oráculo con/sin corte, `solve/2`, `por_que_no` | niveles `resumido`/`detallado`, `arbol/1` en texto, linter mínimo | registro de decisiones de la IA, pruebas de arquitectura y de propiedades, guardado, parser v2, `.dot`, árbol SLD real |

**Reglas de economía que fijan las decisiones aceptadas** (D-08 a D-14): moral entera de 0 a 10, inicio 6; 12 `cheddar` iniciales; sueldos 1+2+1+1 = 5 quesos por pago, **en unidades**; recompensas escaladas (04); **el queso es la única moneda y a la vez la comida**: solo entra por recompensa de contrato, botín y hallazgos, y solo sale por ración, sueldos, descanso (2), habilidades y multas; **no se compra ni se vende queso y en la v1 no hay tienda**. La ración diaria es automática (fresco, luego curado, luego rancio).

---

## 2. Catálogo de funcionalidades

Prioridad: **D** = Debe (versión mínima, Nivel A), **O** = Objetivo (solo con adelanto, ver 1.3 y 4.3), **E** = Extra (documentado, no se entrega), **N** = No en esta versión. La columna *Esf.* es el esfuerzo estimado en horas, **incluidas las pruebas de esa funcionalidad**, y coincide con la suma de las tareas del backlog (sección 6) que llevan ese ID. Los comandos son **términos** validados por el parser y ejecutados por `juego:ejecutar/2` (D-03); solo `estado.pl` hace `assert/retract` (D-04).

| ID | Nombre | Descripción | Prio. | Esf. (h) | Depende de | Concepto declarativo (Conf.) |
|---|---|---|---|---|---|---|
| F-01 | Mundo y grafo de zonas | Seis zonas en datos (cinco con contenido; `bosque` solo de paso), `conexion/2`, `adyacente/2` simétrica, `puede_viajar/1` (la meta que se explica) y descripciones. `mirar` es un comando de `juego` (F-03). | D | 1 | — | Hechos y consultas (1); regla `adyacente/2` simétrica (2) |
| F-02 | Estado con único escritor | `estado.pl` es el **único** módulo con `assert/retract`; los demás devuelven efectos como datos (vocabulario de 02 §4.5, p. ej. `mod_moral/2`, `ganar_queso/3`, `gastar_queso/3`) que aplica `estado:aplicar_efectos/1` con `con_transaccion/1`; los `actualizar_*` son auxiliares privados; reinicio de partida; semilla del generador. | D | 2 | — | BD dinámica (6) |
| F-03 | Viajar, descansar y mirar | Comandos `ir(Zona)`, `descansar` y `mirar` ejecutados por `juego:ejecutar/2`. `ir` valida la conexión y consume un día (maduración y ración); `descansar` solo en la taberna cuesta 2 quesos y 1 día, cura toda la vida y da +1 moral (D-15); sin queso falla `puede_descansar` y lo explica `por_que_no`. | D | 1 | F-01, F-02, F-04 | Unificación y backtracking sobre `conexion/2` (2, 3); aritmética de días (5) |
| F-04 | Comandos, `juego` y bucle | `juego:ejecutar(+Cmd, -resultado(Items))` valida la fase (tabla de fases permitidas), resuelve, aplica efectos y **no imprime**; `objetivo_de_accion/2` traduce una acción a la meta que se explica. `ui.pl` es la única E/S: lee términos terminados en punto (parser v1 dentro de `juego`/`ui`), `ayuda`, `salir`, errores de sintaxis sin caída. `main.pl` arranca y expone los meta-comandos (`demo`). | D | 4 | F-02 | Separación núcleo puro / efectos (1); `=..`, `call/1` y metapredicados (6) |
| F-05 | Compañía e informes | Cuatro personajes con atributos y fila preferida; `compania/0` con listas; `miembro/1` (membresía), `activo/1` (vivo) y `en_pie/1` (activo y sin huelga). | D | 1 | F-02 | Listas (1); `findall/setof` (6) |
| F-06 | Rasgos como reglas (núcleo) | `teme_caballos` (Baldomero) y `hechizos_de_cocina` (Pimentina) como reglas: `teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A)` (con la `venda_de_caballos` equipada deja de temer, D-19) y `puede_atacar/2`, `dano/3`. | D | 2 | F-05, F-17 | Negación como fallo `\+` (4); cláusulas definidas (2) |
| F-07 | Rasgos adicionales | `cobra_por_callar` (Rufino, estado `cantando`, habilidad `silencio_pagado`) y `manos_largas` (Tuerca). | O | 2,5 | F-06, F-10 | Igual que F-06 |
| F-08 | Queso: tipo, edad y estado | `queso(Tipo, Edad, Cant)` con dos tipos (`cheddar`, `brie`); 12 `cheddar` de edad 0 al inicio (D-09); al pasar un día la edad sube; fresco 0–2, curado 3–9, rancio ≥ 10 (`categoria_queso/2`); `queso_total/1`; comando `inventario`; `valor_queso/3` solo informativo (D-13). No se compra ni se vende queso (D-10). | D | 1,5 | F-02 | Aritmética (5); BD dinámica (6) |
| F-09 | Comida diaria | Ración **automática**: cada miembro come una unidad por día en el orden fresco, curado, rancio (D-11); si falta, baja moral y vida (la vida nunca baja de 1 por hambre); el rancio comido penaliza la moral. | D | 1 | F-05, F-08, F-03 | Aritmética (5); `findall` (6) |
| F-10 | Sueldos, `pagar` y moral | Moral entera 0–10, inicio 6; sueldos 1+2+1+1 = 5 quesos, en unidades (D-13). `pagar` es un **comando** de la taberna con `puede_pagar_sueldos/0` explicable (D-14); el impago se evalúa al **salir** de la taberna con sueldos pendientes (−2 moral por miembro). La moral modifica el ataque: alta (≥ 8) +1, normal (4–7) 0, baja (2–3) −1, crítica (0–1) −2 (provisional). El cobro de los contratos sí es automático. | D | 2 | F-05, F-08, F-03 | Aritmética (5); reglas con condiciones (2) |
| F-11 | Huelga | `esta_en_huelga/1`: regla derivada **solo de la moral** (`moral ≤ 2`, `parametro(moral_huelga, 2)`); el personaje en huelga no combate (D-22, X-25). Pasa de "Debería" a **Debe**. | D | 1 | F-10 | Negación (4); regla derivada y explicable (2) |
| F-12 | Contratos | 4 contratos como hechos con la forma de 02/04 (`contrato/5` de aridad 5, `resolucion/3`, regla `resultado/3`, `condicion_cumple/1`, `aplicar_efectos/1`); `contratos/0`; `aceptar/1` en la taberna o en la zona del oferente, máximo 3 activos; cobro automático al volver a la taberna; resultados éxito / a medias / fracaso (solo dos condiciones medibles para "a medias"); la escolta de la gallina con un contador de golpes recibidos (D-33). | D | 5 | F-01, F-05, F-10, F-13 | Reglas con condiciones (2); `findall/setof` (6); condiciones evaluadas con metapredicados (6) |
| F-13 | Combate base | Turnos por iniciativa, dos filas, `atacar`, `defender`, daño `max(1, Atq−Def+Mod)`; "caído" solo existe dentro del combate y al terminar todos se levantan con 1 de vida (D-17); no se puede huir del jefe (D-29). | D | 5,5 | F-05, F-06, F-17 | Aritmética (5); listas y orden (1); negación en `puede_atacar` (4) |
| F-14 | Habilidades | Comando `habilidad(Objetivo)`, **una por personaje** (D-23): daño, daño con queso (el hechizo de Pimentina consume un queso), +1 moral, +1 queso; datos `efecto_habilidad/2` y regla `puede_habilidad/2`. La lógica completa de los rasgos de Rufino y Tuerca queda en F-07. | D | 1,5 | F-13, F-08 | Reglas con estado (2, 6) |
| F-15 | Usar objeto y huir | Comandos `usar` y `huir` (no se huye del jefe). Los consumibles se consiguen como recompensa o botín, sin tienda. | O | 2 | F-13 | Reglas (2) |
| F-16 | IA enemiga por prioridades | `accion_enemigo/2` con las tres reglas del canon (`curarse`, `atacar`, `defender`), orden de cláusulas y **corte deliberado**, más como máximo tres acciones especiales (`robar_queso`, `embestir`, `invocar_moho`) cada una con su cláusula y su gemela sin corte (`regla_ia/3`) que sirve de oráculo (D-24). El jefe usa las cuatro reglas de 01 más la invocación. | D | 2 | F-13, F-17 | Corte (4); orden de cláusulas y BPP-RC (3, 4) |
| F-17 | Bestiario y jefe final | **Cinco tipos** (incluido el jefe): `rata_quesera`, `bandido_torpe`, `bandido_montado` (clase `caballo`), `moho_saltarin` (aprovecha el queso rancio) y `gran_roquefort`. | D | 1 | — | Hechos (1) |
| F-18 | Meta-intérprete `solve/2` | Conjunción, negación, `->`/`;`, aritmética, predefinidos como hoja (hoja = no es predicado de los módulos del juego; se detecta con `predicate_property(M:G, dynamic)` o `number_of_clauses(_)`, porque `defined` no funciona en 5.10.4), hechos, reglas y **corte real** (cuerpo partido en `Pre`/`Post`, nodo `corte` en la prueba, `corte_no_soportado` ante un `!` anidado); diagnósticos mínimos `sin_clausula`, `fallo`, `neg_viola`, `builtin_falso`, `tras`. Decisión con el spike del primer día (D-06). | D | 4 | — (se prueba con F-01/F-08) | `clause/2`, metaprogramación (6); SLD (3); corte (4) |
| F-19 | `explicar` | Muestra la prueba con valores de variables y marcas ASCII (`[hecho]`, `[regla]`, `[negacion]`, `[predefinido]`, `[corte]`). Modo **hipotético** (`explicar(Acción)` sobre el estado actual) y **retrospectivo** (`explicar` sin argumento muestra `ultima_prueba/2`, incluido un turno enemigo). | D | 2,5 | F-18 | Árbol de derivación SLD (3); unificadores (2) |
| F-20 | `por_que_no` | Muestra el primer subobjetivo que falla y, si es una negación, el hecho que la impide; `clave_de_diag/2` traduce el diagnóstico (`neg_viola`, `fallo`, `tras`) a las claves `impide(...)`/`falla(...)` del narrador; v2 con varias cláusulas aplicables. | D | 4,5 | F-18, F-19 | Negación como fallo (4); SLD/fracaso (3) |
| F-21 | Niveles de detalle | `nivel(resumido)` y `nivel(detallado)` controlan la profundidad del árbol. | O | 1,5 | F-19 | Recorrido de términos (6) |
| F-22 | `arbol` en texto | Árbol indentado completo, con unificadores, listo para copiar en la memoria. | O | 1 | F-19 | Árbol SLD (3) |
| F-23 | Exportación Graphviz | `arbol` genera `out/arbol.dot`. | E | 1,5 | F-22 | Árbol SLD (3); `=..`, `functor/3` (6) |
| F-24 | Narrador | Módulo **puro** (sin estado propio): `frase/3` estático por regla, hecho o clave, frase genérica por defecto, variantes elegidas con la semilla, nombres con artículo; los contadores de rotación viven en `estado.pl`. Mínimo ≈ 70 frases (D-21). | D | 3,5 | F-19 | BD de hechos de presentación (1, 6) |
| F-25 | Eventos cómicos aleatorios | Cinco eventos al viajar/descansar, sin duplicar los deterministas de 04 (D-28), elegidos con el generador congruencial propio (`tirada/4`), semilla fija configurable. | O | 2 | F-03, F-08 | Reglas con condiciones (2); `findall` (6) |
| F-26 | Fin de partida | Victoria (`chapuza`) al vencer al jefe; derrota en combate (todos caídos, `derrota_combate`) y por hambre (`derrota_hambre`: al empezar el día `queso_total = 0` y nada por cobrar); ids de derrota de 04 (D-17, D-30). | D | 1,5 | F-12, F-13 | Reglas (2); negación (4) |
| F-27 | Tienda de objetos | La aldea vende **objetos no queseros** a cambio de queso (precio en unidades, pagando antes lo más rancio). No se compra ni se vende queso (D-10, X-33). | E | 2 | F-08 | Aritmética (5) |
| F-28 | Reclutar en la taberna | Añadir miembros a la compañía. | E | 2 | F-05 | BD dinámica (6) |
| F-29 | Guardar y cargar | Volcar y recargar los hechos dinámicos. **Fuera de la v1** (D-32). | E | 2 | F-02 | `listing`/`assert` (6) |
| F-30 | Comandos en palabras | Analizador DCG (`ir bosque`). | N | — | F-04 | No visto en el curso (canon §13) |
| F-31 | Interfaz gráfica/web, cuadrícula táctica, multijugador, sonido, generación procedural | Fuera de alcance (canon §2). | N | — | — | — |
| F-32 | Pruebas y playtests | plunit por módulo + prueba de equivalencia `solve/2` frente a ejecución directa (todas las soluciones, mismo orden, con y sin corte) + `tests/todas.pl` y un único comando; PT-1 y PT-2/balance. | D | 3,5 | todas | Verificación de la semántica (3, 6) |
| F-33 | Partida de demostración reproducible | `examples/` con guion de comandos, semilla, salida y explicaciones guardadas; meta-comando `demo` de `main`. | D | 1,5 | F-19, F-20, F-26 | — |
| F-34 | Documentación y entregables | README final, manual breve de jugador, DISENO.md al día, informe/memoria (si procede), guion de exposición, entorno (T-01) y preguntas a la profesora (T-02). | D | 7,5 | — | — |
| F-35 | Elecciones de evento | Comando `elegir(Opción)` y motor de evento mínimo (el de `gato_en_el_arbol`, que entrega la `venda_de_caballos`) (D-20). | D | 2 | F-12, F-04 | Reglas con estado (2); datos como programa (6) |
| F-36 | Comer (ración extra) | `comer(Tipo)`: ración voluntaria con el efecto del tipo (en la versión simple, cura 2); la ración diaria solo alimenta (D-12). | O | 0,5 | F-08, F-09 | Aritmética (5) |

**Resumen de horas** (suma verificada con un cálculo, sección 6): **Debe 62 h** = 49,5 h de motor (F-01 a F-26 y F-35) + 12,5 h de soporte (F-32 3,5; F-33 1,5; F-34 7,5). A eso se suman **3 h de reserva** que no pertenecen a ninguna funcionalidad: **65 h declaradas**. **Objetivo** ≈ 18 h (F-07, F-15, F-21, F-22, F-25, F-36 = 9,5 h, más ≈ 8,5 h de contenido de objetivo: contratos y enemigos extra ≈ 3, frases 120 y finales/arcos/eventos de campaña ≈ 5,5; estimaciones de este documento). **Extra** = F-23, F-27, F-28, F-29 (7,5 h) y toda la columna Extra de 1.3.

### Comandos de DISENO §13 y a qué funcionalidad pertenecen

Mínimos (16): `ayuda`, `salir` → F-04 · `mirar`, `ir`, `descansar` → F-03 · `compania` → F-05 · `inventario` → F-08 · `pagar` → F-10 · `contratos`, `aceptar` → F-12 · `elegir` → F-35 · `atacar`, `defender` → F-13 · `habilidad` → F-14 · `explicar`, `por_que_no` → F-19/F-20. Meta-comando de `main`: `demo` → F-33 (entra aunque la tabla de 06 §5.1 lo lista en "objetivo": F-33 es Debe y `demo` es un meta-comando, no un comando de juego).
Objetivo: `nivel` → F-21 · `arbol` → F-22 · `usar`, `huir` → F-15 · `comer` → F-36. Extra: `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar` (el reinicio existe como `estado:reiniciar/0` para pruebas y demo, F-02).

---

## 3. Criterios de aceptación de las funcionalidades "Debe"

Formato: *Dado … cuando … entonces …*. Un "comando ejecutado" significa `juego:ejecutar(Comando, Resultado)`, que devuelve `resultado(Items)` sin imprimir; así el núcleo se prueba sin consola. Los valores numéricos marcados como "provisional" se fijan en el balance (semana 6).

**F-01 Mundo**
- Dado el programa cargado, cuando se consulta `adyacente(bosque, aldea)` y `adyacente(aldea, bosque)`, entonces ambas son ciertas aunque solo exista un hecho `conexion/2`.
- Dado el jugador en la taberna, cuando se consulta `puede_viajar(aldea)` y `puede_viajar(castillo)` (no conectada), entonces la primera es cierta y la segunda falla.

**F-02 Estado**
- Dado un estado cualquiera, cuando se ejecuta `estado:reiniciar/0`, entonces el estado es idéntico al inicial (taberna, día 1, 12 `cheddar` de edad 0, vida y moral base, semilla inicial).
- Dado el código fuente, cuando se busca `assert`/`retract`/`retractall` fuera de `src/estado.pl`, entonces no aparece (se comprueba con `grep` en la lista de verificación).
- Dado un lote de efectos en el que uno falla a mitad (p. ej. gastar más queso del disponible), cuando se aplica con `con_transaccion/1`, entonces el estado queda como antes.

**F-03 Viajar, descansar y mirar**
- Dado el jugador en la taberna, cuando se ejecuta el comando `ir(aldea)`, entonces `en_zona(aldea)` es cierto y `dia` aumenta en 1.
- Dado el jugador en la taberna, cuando se ejecuta `ir(castillo)` (no conectada), entonces el estado no cambia y el resultado contiene un error que indica que no hay camino.
- Dado el jugador en la taberna, cuando se ejecuta `mirar`, entonces el resultado contiene el nombre de la zona, su descripción y las zonas adyacentes.
- Dado el jugador fuera de la taberna, cuando se ejecuta `descansar`, entonces se rechaza; en la taberna con al menos 2 quesos, se gastan 2 quesos, la vida llega al máximo, la moral sube 1 (sin pasar de 10) y el día avanza en 1.
- Dado el jugador en la taberna con menos de 2 quesos, cuando se ejecuta `descansar`, entonces se rechaza y `por_que_no(descansar)` indica que falla `puede_descansar` por falta de queso.

**F-04 Comandos, `juego` y bucle**
- Dado un comando mal formado (`ir bosque` sin punto, o `foo(.`), cuando se introduce en `ui`, entonces el juego informa del error y sigue vivo.
- Dado un comando desconocido, cuando se introduce, entonces se muestra una sugerencia basada en `ayuda`.
- Dado `salir.`, cuando se introduce, entonces el bucle termina sin error.
- Dado un comando válido pero fuera de su fase (p. ej. `atacar(...)` en la taberna), cuando se ejecuta, entonces el resultado es un error de fase y el estado no cambia.
- Dado `juego:ejecutar(ir(aldea), R)` llamado desde una prueba, cuando termina, entonces `R = resultado(Items)` y no se ha escrito nada en pantalla (`ui` es la única E/S).

**F-05 Compañía**
- Dado el inicio de partida, cuando se ejecuta `compania`, entonces aparecen 4 personajes con vida, ataque, defensa, sueldo, fila y rasgo.
- Dado un cambio de vida, cuando se vuelve a ejecutar `compania`, entonces la vida mostrada refleja el cambio.
- Dado un miembro con vida 0 dentro de un combate, cuando se consulta, entonces `miembro/1` es cierto, `activo/1` falso y `en_pie/1` falso.

**F-06 Rasgos (núcleo)**
- Dado Baldomero sin objetos y un enemigo de clase `caballo`, cuando se consulta `puede_atacar(baldomero, bandido_montado)`, entonces es falso; contra un enemigo de otra clase (`bandido_torpe`) es cierto.
- Dado Baldomero con `equipado(baldomero, venda_de_caballos)`, cuando se consulta `puede_atacar(baldomero, bandido_montado)`, entonces es cierto (`ignora_miedo/1`).
- Dado Baldomero atacado por un enemigo montado, cuando se calcula el daño recibido, entonces es mayor que el de un enemigo no montado con los mismos atributos.
- Dado queso en la despensa, cuando Pimentina usa un hechizo, entonces se consume queso y el efecto se aplica; sin queso, el hechizo no se puede lanzar.

**F-08 Queso**
- Dado el inicio de partida, cuando se consulta `queso_total(N)`, entonces `N = 12` (cheddar de edad 0).
- Dado queso de edad 2, cuando pasa un día, entonces su edad es 3 y `categoria_queso/2` da *curado*; de edad 9 pasa a 10 y *rancio*.
- Dado un queso curado y otro rancio del mismo tipo, cuando se calcula `valor_queso/3` (solo informativo), entonces el rancio vale como máximo lo que el fresco (X-34).
- Dado el código del juego, cuando se buscan reglas que compren o vendan queso, entonces no existen (D-10): el queso solo entra por recompensa, botín o hallazgo.

**F-09 Comida**
- Dado 4 miembros y 4 unidades de queso, cuando pasa un día, entonces quedan 0 unidades y la moral no baja.
- Dado 4 miembros y 2 unidades, cuando pasa un día, entonces dos miembros no comen y pierden moral y vida (valores provisionales: −1 moral, −2 vida; la vida no baja de 1).
- Dado 1 queso fresco, 1 curado y 1 rancio y 2 raciones, cuando pasa un día, entonces se comen el fresco y el curado y queda el rancio (D-11).

**F-10 Sueldos y moral**
- Dado queso suficiente (≥ 5) y el jugador en la taberna, cuando se ejecuta `pagar`, entonces se descuentan 5 unidades (primero las más rancias) y al salir la moral no baja.
- Dado queso insuficiente, cuando se ejecuta `pagar`, entonces se rechaza y `por_que_no(pagar)` indica que falla `puede_pagar_sueldos` por falta de queso.
- Dado que el jugador sale de la taberna con sueldos pendientes, cuando se ejecuta `ir/1`, entonces cada miembro pierde 2 de moral (mínimo 0).
- Dado un personaje con moral baja, cuando ataca, entonces su daño incluye el modificador por moral (documentado en el árbol de `dano/3`).

**F-11 Huelga**
- Dado un personaje con moral 2 o menos, cuando se consulta `esta_en_huelga/1`, entonces es cierto y `por_que_no(atacar(Personaje, Enemigo))` muestra que lo impide; con moral 3, no está en huelga.
- Dado que ningún dato de huelga se guarda, cuando se sube la moral por encima de 2, entonces el personaje deja de estar en huelga sin ninguna otra acción (es una regla derivada).

**F-12 Contratos**
- Dado el tablón, cuando se ejecuta `contratos`, entonces se listan los contratos disponibles con zona, objetivo y recompensa.
- Dado `gallina_noble` con Baldomero en la compañía y sin la venda, cuando se ejecuta `aceptar(gallina_noble)`, entonces se rechaza y `por_que_no(aceptar(gallina_noble))` indica que falla `rasgo_no(teme_caballos)` por `rasgo(baldomero, teme_caballos)` y la ausencia de `ignora_miedo(baldomero)`; con la venda equipada, se acepta (D-19).
- Dado un contrato aceptado y su objetivo cumplido, cuando se vuelve a la taberna, entonces se cobra la recompensa **sin comando adicional**; si se fracasó, no se cobra y las consecuencias se aplican según `resolucion/3`.
- Dado un contrato a medias (una de las dos condiciones medibles de "a medias"), cuando se cobra, entonces la recompensa es parcial y la razón queda disponible en `explicar`.
- Dados 3 contratos activos, cuando se intenta aceptar un cuarto, entonces se rechaza (`parametro(max_contratos, 3)`).
- Dado `despensa_real`, cuando hay menos de 3 contratos cumplidos, entonces `aceptar` se rechaza con `contratos_cumplidos_min(3)` como causa.
- Dada la escolta de `gallina_noble`, cuando Clotilde recibe golpes en el combate, entonces el contador de golpes decide el resultado (éxito, a medias o fracaso).

**F-13 Combate base**
- Dado un combate con cuatro miembros y dos enemigos, cuando comienza, entonces el orden de turnos sigue la iniciativa descendente y es estable (mismo orden en cada ejecución).
- Dado ataque 11 y defensa 5, cuando se calcula el daño, entonces es 6; dado ataque 2 y defensa 9, entonces es 1 (mínimo). (Pruebas unitarias de `dano/3`; el ejemplo de la demo usa `bandido_torpe`, defensa 2.)
- Dado un objetivo en retaguardia y el frente con vida, cuando un atacante cuerpo a cuerpo intenta golpearlo, entonces `puede_atacar/2` es falso; con el frente caído, es cierto.
- Dado un combate terminado, cuando acaba, entonces los caídos se levantan con 1 de vida, el estado (vida, queso, moral) queda coherente y se vuelve a la fase de exploración; si todos estaban caídos, la partida termina con `derrota_combate`.
- Dado el combate contra el jefe, cuando se ejecuta `huir` o equivalente, entonces no se permite.

**F-14 Habilidades**
- Dado cada uno de los cuatro personajes, cuando ejecuta `habilidad(Objetivo)`, entonces produce un efecto distinto definido en `efecto_habilidad/2` (daño; daño que gasta un queso; +1 moral; +1 queso).
- Dado un hechizo de cocina sin queso, cuando se consulta `puede_habilidad(pimentina, Objetivo)`, entonces es falso y `por_que_no` lo explica.

**F-16 IA enemiga**
- Dado un enemigo con vida baja y poción, cuando le toca, entonces se cura; sin poción ataca al objetivo más débil; en otro caso defiende.
- Dado cada una de las tres acciones especiales (`robar_queso`, `embestir`, `invocar_moho`), cuando se cumple su condición, entonces el enemigo correspondiente la elige antes que las tres reglas generales.
- Dado el código de `accion_enemigo/2`, cuando se altera el orden de las cláusulas, entonces cambia el comportamiento (se demuestra en una prueba y se enseña en la exposición).
- Dado el mismo estado, cuando se compara `accion_enemigo/2` (con corte) con su gemela sin corte, entonces la gemela devuelve las alternativas que el corte poda y la primera solución coincide (oráculo).

**F-17 Bestiario**
- Dado el bestiario, cuando se consulta, entonces hay 5 tipos (`rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort`), todos con vida, ataque, defensa y clase, uno de clase `caballo`.

**F-18 Meta-intérprete**
- Dado un conjunto de ≥ 20 objetivos del juego (éxito, fallo y con variables, incluidos `accion_enemigo/2` y una regla de otro módulo), cuando se evalúan con `findall(G, G, L)` y con `findall(G, solve(G, _), L2)`, entonces `L` y `L2` son variantes (`=@=`) elemento a elemento y en el mismo orden.
- Dado un objetivo con `\+`, aritmética, `->` y un predicado definido en otro módulo, cuando se pasa a `solve/2`, entonces no lanza excepción y el árbol contiene cada tipo de nodo (incluido `corte` para la IA).
- Dado un predicado dinámico sin cláusulas, cuando se pasa a `solve/2`, entonces falla sin lanzar excepción (cubre la sustitución de `predicate_property(_, defined)`).
- Dado un `!` anidado dentro de `\+` o `findall`, cuando se pasa a `solve/2`, entonces lanza `corte_no_soportado` (limitación documentada).
- Plan B (solo si el spike del primer día falla): el corte se trata como hoja que triunfa, las explicaciones corresponden a la primera solución y `accion_enemigo/2` queda **excluida** de la equivalencia, documentándolo.

**F-19 `explicar`**
- Dado `explicar(atacar(baldomero, bandido_torpe))`, cuando se ejecuta, entonces se muestra cada subobjetivo de `puede_atacar/2` con su marca (`[hecho]`, `[regla]`, `[negacion]`), el cálculo de `dano/3` con los valores (p. ej. `D = 9 (11 - 2)`; el ejemplo de la demo cambia del 6 del canon porque `bandido_torpe` tiene defensa 2, X-57) y una frase del narrador.
- Dado un turno enemigo recién resuelto, cuando se ejecuta `explicar` sin argumento, entonces se muestra la prueba guardada de `accion_enemigo/2` (guardada antes de aplicar los efectos), con el nodo `corte`.
- Dado un objetivo que no se puede demostrar, cuando se ejecuta `explicar`, entonces indica que no hay prueba y sugiere `por_que_no`.

**F-20 `por_que_no`**
- Dado `por_que_no(atacar(baldomero, bandido_montado))`, cuando se ejecuta, entonces muestra que falla `\+ (teme(baldomero, C), clase(bandido_montado, C))` y los hechos que lo causan: `rasgo(baldomero, teme_caballos)` (de donde sale `teme(baldomero, caballo)`), `clase(bandido_montado, caballo)` y la ausencia de `ignora_miedo(baldomero)`. **Demostración central 1.**
- Dado `por_que_no(aceptar(gallina_noble))` con Baldomero sin venda, cuando se ejecuta, entonces muestra que falla `rasgo_no(teme_caballos)` y por qué. **Demostración central 2.**
- Dado un objetivo con varias cláusulas aplicables, cuando se ejecuta, entonces muestra el primer fallo de cada cláusula o, en el nivel resumido, solo la más cercana (decisión de diseño documentada).
- Dado un objetivo que sí es demostrable, cuando se ejecuta, entonces responde que no hay fallo y remite a `explicar`.
- Dadas las seis claves del núcleo de 05 (F01, F02e, F05, F06, F07, F10), cuando se traducen los diagnósticos con `clave_de_diag/2`, entonces cada una produce la clave `impide(...)`/`falla(...)` esperada y el narrador encuentra su frase.

**F-24 Narrador**
- Dado una explicación que contiene un hecho o regla con frase asociada, cuando se muestra, entonces el narrador usa esa frase; si no la hay, usa una genérica; nunca falla ni altera la lógica (prueba: borrar todas las frases no cambia ningún resultado de juego).
- Dado `narrador.pl`, cuando se busca `assert`/`retract` o `:- dynamic`, entonces no aparece (los contadores de rotación viven en `estado.pl`).
- Dado un enemigo `e(bandido_torpe, 2)`, cuando se muestra su nombre con otro del mismo tipo, entonces sale con artículo y número ("el Bandido Torpe (2)"); si es el único, sin número.
- Dado el banco, cuando se cuentan las frases, entonces hay ≈ 70 y las claves de las 6 frases del núcleo de 05 existen.

**F-26 Fin de partida**
- Dado el jefe final derrotado, cuando termina el combate, entonces se muestra el final `chapuza` y el resumen (días, queso, bajas).
- Dado que todos los miembros están caídos, cuando se detecta, entonces se muestra `derrota_combate`.
- Dado el inicio de un día con `queso_total = 0` y nada por cobrar, cuando se detecta, entonces se muestra `derrota_hambre` con el motivo (explicable); el hambre nunca baja la vida de nadie de 1.

**F-32 Pruebas**
- Dado el repositorio recién clonado, cuando se ejecuta el comando de pruebas documentado (`swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl`), entonces todas pasan y el código de salida es 0; con una prueba que falla, el código de salida es 1. (Comprobado en 5.10.4 el 2 de noviembre: la forma `-g run_tests -t halt` devuelve 0 incluso cuando una prueba falla, por eso no se usa.)

**F-33 Demo reproducible**
- Dado `examples/` y la semilla fija, cuando se ejecuta la demo dos veces, entonces la salida es idéntica byte a byte (el generador es el congruencial propio de 02, no `random/1`).

**F-34 Documentación**
- Dado el README, cuando un compañero sin contexto lo sigue en una máquina limpia con SWI-Prolog 5.10.4 instalado, entonces consigue arrancar, jugar un turno y ejecutar `explicar` en menos de 10 minutos.
- Dado el README, cuando se lee, entonces dice la versión, la ruta de instalación (fuera del PATH), la orden de arranque y de pruebas, que `explicar`/`por_que_no` son comandos y qué contenido es "extra".

**F-35 Elecciones de evento**
- Dado `gato_en_el_arbol` aceptado y el jugador en su zona, cuando se abre el evento, entonces `elegir(Opción)` aplica los efectos de esa opción, cierra el evento y la recompensa incluye la `venda_de_caballos`.
- Dada una opción inexistente o `elegir` fuera de un evento, cuando se ejecuta, entonces se rechaza sin cambiar el estado.

---

## 4. Calendario real

Semanas de lunes a viernes. La semana del curso se calcula con la semana 15 = 7–11 de diciembre. Hoy es lunes 2 de noviembre, primer día de la semana 1: **la sesión previa S0 (sáb 31 oct – dom 1 nov) no se hizo**; sus tareas (T-01, T-02 y el spike) pasan a los dos primeros días de la semana 1 y sus 2 h se suman a esa semana.

### 4.1 Calendario y puntos de control

| Sem. | Fechas | Curso | Hito | Entregable del viernes | Punto de control (qué debe funcionar el viernes) |
|---|---|---|---|---|---|
| S0 (previa) | sáb 31 oct – dom 1 nov | — | **No realizada** | Sus tareas se hacen el lun 2 y mar 3 nov (dentro de S1) | — |
| S1 | lun 2 – vie 6 nov | 10 | Entorno, decisión del corte y esqueleto jugable de exploración | Alias a SWI-Prolog 5.10.4; preguntas enviadas a la profesora; **spike del meta-intérprete (cierra D-06)**; `mundo`, `estado` (único escritor), `juego:ejecutar/2`, `ui`/`main`, `ir`/`descansar`/`mirar`; documentos 01-05 y DISENO alineados; etiqueta `v0.1-diseno` | `swipl src/main.pl` carga sin errores; se recorre el mapa gastando días con comandos; el spike confirma (o descarta) el corte real; 1 prueba plunit pasa con la orden única (código de salida comprobado) |
| S2 | lun 9 – vie 13 nov | 11 | Economía y primer `explicar` | Compañía, queso con maduración, comida, moral 0–10, sueldos y `pagar`, huelga derivada, `solve/2` completo, `explicar` v1 | Se viaja varios días, el queso madura y se acaba; `pagar` y la huelga funcionan y son explicables; `explicar` justifica una regla de economía con valores; etiqueta `v0.5-motor` |
| S3 | lun 16 – vie 20 nov | 12 | Combate por turnos con rasgos | Narrador mínimo, bestiario (5 tipos), rasgos núcleo, turnos, daño, atacar/defender, filas, bucle de combate | Combate completo jugador–enemigos; Baldomero no puede atacar al montado; `explicar(atacar(baldomero, bandido_torpe))` produce la salida de DISENO §11.3 con `D = 9 (11 - 2)` |
| S4 | lun 23 – vie 27 nov | 13 | **Partida mínima de principio a fin** | IA enemiga con corte y 3 acciones especiales, 4 contratos con resolución y cobro, `elegir/1` (`gato_en_el_arbol` entrega la venda), finales, `clave_de_diag/2` | Aceptar `ratas_del_granero` y `gato_en_el_arbol` (venda) → `gallina_noble` → `despensa_real` → viajar → combatir → cobrar → jefe → ganar (`chapuza`) o perder (`derrota_combate`/`derrota_hambre`); etiqueta `v0.9-jugable`. **Decisión de Objetivo:** solo si hay ≥ 3 h de adelanto |
| S5 | lun 30 nov – vie 4 dic | 14 | Modo explicar completo y cierre del Debe | Habilidades, escolta de Clotilde, `por_que_no` v1 y v2, `explicar` de un turno enemigo (`ultima_prueba/2`), ≈ 70 frases, PT-1; la **reserva de 3 h** solo se gasta si hay desvío | Las **tres demostraciones centrales** funcionan; sin errores conocidos de prioridad alta; PT-1 hecho; **viernes 4 dic: congelación de funcionalidades** (a partir de aquí solo corrección de errores y documentación). **Se cierra el alcance "Debe".** |
| S6 | lun 7 – vie 11 dic | 15 | Pulido y entrega | Balance y PT-2, equivalencia ≥ 20 objetivos y `tests/todas.pl`, demo reproducible, README, informe, ensayo, etiqueta | Candidata a entrega el **mié 9 dic** (`v1.0-rc1`); versión final el **jue 10 dic**; entrega el **vie 11 dic** con `v1.0-entrega` |

Recordatorio: las preguntas a la profesora (sección 9, D-34 a D-38) deben enviarse **antes del viernes 6 de noviembre**; lo ideal es el lunes 2 o el martes 3.

### 4.2 Detalle por semana (reparto de horas)

Las horas de cada semana son la suma de las tareas del backlog (sección 6), verificada con un cálculo. La capacidad es de 10 h por semana (12 h en S1, que recupera las 2 h de S0).

| Sem. | Horas plan | Acum. plan | Capacidad acum. | Reparto |
|---|---|---|---|---|
| S1 | 12 | 12 | 12 | Entorno y preguntas 2 · Spike meta-intérprete 2 · Mundo 1 · Estado y efectos 2 · `juego:ejecutar/2` 2 · UI y lectura de términos 2 · `ir`/`descansar`/`mirar` 1 |
| S2 | 10 | 22 | 22 | Compañía 1 · Queso 1,5 · Comida 1 · Sueldos, moral y `pagar` 2 · Huelga 1 · `solve/2` completo 2 · `explicar` v1 1,5 |
| S3 | 10 | 32 | 32 | Narrador mínimo 1,5 · Bestiario 1 · Rasgos 2 · Turnos 1,5 · Daño 1 · Acciones y filas 2 · Bucle de combate 1 |
| S4 | 10,5 | 42,5 | 42 | IA enemiga 2 · Contratos (datos y `aceptar`) 2 · Resolución y cobro 2 · `elegir/1` 2 · Finales 1,5 · `clave_de_diag/2` 1 |
| S5 | 10 (+ 3 de reserva) | 52,5 (+ 3) | 52 | Habilidades 1,5 · Clotilde 1 · `por_que_no` v1 2 · `explicar` del turno enemigo 1 · `por_que_no` v2 1,5 · Frases 2 · PT-1 1 · **Reserva 3** |
| S6 | 9,5 | 62 | 62 | Balance y PT-2 1,5 · Equivalencia 1 · Demo 1,5 · README/manual 1,5 · Informe 2 · Guion y ensayo 1,5 · Checklist y entrega 0,5 |

### 4.3 Honestidad sobre la carga, colchón y paso al Nivel B

- **Declarado (Nivel A): 65 h** = 62 h de tareas Debe (T-01 a T-44) + 3 h de reserva (T-37).
- **Disponible: 62 h** = 6 semanas × 10 h + 2 h de S0 recuperadas. A 9 h/semana serían 56 h y a 8 h/semana, 50 h.
- **Déficit: 3 h**, exactamente la reserva. Dicho claramente: **el colchón real es cero** si se cumplen las 10 h semanales; la reserva de 3 h existe en la tabla pero no en el calendario, y solo se "financia" (a) con tareas que salgan por debajo de lo estimado o (b) aplicando por adelantado los recortes B-1 a B-3 (−4 h, sección 13.2). Las estimaciones del combate, las pruebas de la IA y las frases son las más comprimidas del plan (06 §5.2): son la fuente de riesgo.
- **Nivel B: ≈ 57,5 h** (54,5 de tareas + 3 de reserva). Con 8 h/semana (≈ 50 h) ni siquiera el Nivel B cabe sin sacrificar documentación.
- **Qué se recorta primero:** lo "Objetivo" y lo "Extra" nunca se empiezan salvo adelanto; después, los recortes B-1 a B-6 en el orden de la sección 13.2.

**Seguimiento semanal y criterios para pasar a Nivel B (D-01).** Cada viernes (6, 13, 20, 27 nov, 4 y 11 dic) se calcula el **desvío acumulado** = (horas planificadas de las tareas que según la tabla 4.2 debían estar terminadas ese viernes) − (horas planificadas de las tareas realmente terminadas). Reglas:

1. Si el desvío es **mayor de 3 h un viernes**, ese mismo fin de semana se pasa al **Nivel B** y se aplican los recortes B-1, B-2… de 13.2 hasta absorberlo; lo recortado se marca "(extra)" en el backlog y en el README.
2. Complemento (derivado de 06 §5.2): si la **dedicación medida** de las semanas 1 y 2 promedia menos de 9 h/semana, se pasa a Nivel B el viernes 13 de noviembre sin esperar al desvío.
3. Si el spike del primer día falla y hay que usar el Plan B del corte, el coste se anota como desvío (la IA sale de la equivalencia, F-18).
4. Si el viernes 27 de noviembre hay un **adelanto de ≥ 3 h**, se abre el Objetivo en este orden: `nivel` y `arbol` (F-21, F-22), rasgos adicionales (F-07), `comer` (F-36), `usar`/`huir` (F-15), eventos aleatorios (F-25), contratos y enemigos extra, más frases y finales.

---

## 5. Etapas del proyecto y dependencias

| Etapa | Fechas | Contenido | Termina cuando |
|---|---|---|---|
| E1 Diseño | hasta vie 6 nov (S0 no se hizo) | Documentos 01-06 alineados, DISENO.md, entorno y spike del corte, preguntas a la profesora | Decisiones cerradas, entorno listo y `v0.1-diseno` |
| E2 Núcleo | 2 – 20 nov (S1–S3) | Estado, `juego`, mundo, economía, `solve/2`, `explicar`, combate, rasgos | Combate explicable funcionando (punto de control S3) |
| E3 Contenido y reglas de campaña | 16 nov – 4 dic (S3–S5, solapada con E2) | 4 contratos, bestiario de 5, jefe, `elegir/1`, frases, finales | Punto de control S4 + congelación del 4 dic |
| E4 Pulido | 30 nov – 10 dic (S5–S6) | `por_que_no` v1/v2, balance, playtests, documentación | Candidata `v1.0-rc1` |
| E5 Entrega | 9 – 11 dic | Verificación, ensayo, etiqueta y entrega | `v1.0-entrega` entregada |

### Orden de dependencia

```
 E1 Diseño (documentos alineados + spike del corte, D-06)
    │
    ▼
 F-02 estado ──► F-04 juego/ui ──► F-01 mundo ──► F-03 viajar ──► F-08 queso ──► F-09 comida ──► F-10 sueldos/pagar ──► F-11 huelga
    │                 │
    │                 └──► F-05 compañía ──► F-06 rasgos ──► F-13 combate ──► F-16 IA enemiga
    │                                              ▲              │
    │                          F-17 bestiario ─────┘              ▼
    │                                                      F-12 contratos ──► F-35 elegir ──► F-26 fin de partida
    │
    └─► F-18 solve/2 ──► F-19 explicar ──► F-20 por_que_no (+ clave_de_diag) ──► (F-21, F-22 objetivo; F-23 extra)
                              │
                              └──► F-24 narrador
                                          └────────► F-33 demo ──► F-34 documentación final
```

### Qué se puede construir en paralelo

Una sola persona no programa dos cosas a la vez, pero sí **alterna trabajo de motor con trabajo de contenido de bajo coste** (30–40 minutos) y evita quedarse bloqueada:

- **Contenido que no depende del motor** (son solo hechos): descripciones de zonas, los 4 contratos (nombre, zona, objetivo, recompensa, condiciones), tabla de los 5 enemigos con clase y atributos, nombres y atributos de los personajes, frases del narrador (las 32 del núcleo de 05 §8.4 primero). Se pueden escribir desde la semana 1 como hechos en los archivos correspondientes. Ningún contenido "objetivo" ni "extra" se escribe antes de tiempo.
- **El narrador (F-24)** es independiente de la lógica y puro: puede crecer sin tocar el núcleo (canon §12); sus contadores viven en `estado.pl`.
- **Pruebas de reglas**: cada regla nueva nace con su prueba plunit; las pruebas de equivalencia se empiezan en cuanto exista `solve/2` (5 objetivos en S2) y se completan hasta ≥ 20 en S6.
- **Documentación incremental**: cada viernes, 15 minutos para actualizar README/DISENO con lo realmente hecho; el informe se alimenta de eso.
- **El meta-intérprete (F-18)** avanza mientras se construyen las reglas, porque se prueba contra el mundo y la economía desde la semana 1 (no hace falta esperar al combate). Es el camino crítico de lo que más pesa en la evaluación y su riesgo principal (el corte real) se despeja el primer día.

Lo que **no** se puede paralelizar: el combate necesita rasgos y bestiario; los contratos necesitan combate; `por_que_no` necesita `explicar` y `clave_de_diag/2`.

---

## 6. Backlog inicial priorizado

Tareas pequeñas (1–3 h), en el orden en que deberían hacerse. *Prio.* = D (Debe, versión mínima). La columna *Antes* da el número de la tarea en la versión anterior de este documento, o "nueva" con su origen. Los trabajos "Objetivo" y "Extra" están en las tablas que siguen. Las horas de cada tarea incluyen sus pruebas.

| ID | Tarea | Func. | Prio. | h | Sem. | Antes |
|---|---|---|---|---|---|---|
| T-01 | Alias o ruta a SWI-Prolog 5.10.4 (`C:\Program Files\pl\bin`, fuera del PATH), anotar versión y orden de arranque en el README, comprobar que `swipl src/main.pl` carga los stubs (V-05) | F-34 | D | 0,5 | S1 | T-01 |
| T-02 | Enviar las preguntas D-34 a D-38 a la profesora (antes del vie 6 nov); prueba de tildes y `set_stream(user_output, encoding(utf8))` en la consola de la entrega (V-06, V-08); revisar los documentos alineados y etiquetar `v0.1-diseno` | F-34 | D | 1,5 | S1 | T-02 |
| T-03 | Spike del meta-intérprete: dos módulos, predicado dinámico, `clause/2` sobre importados, `nth_clause/3`, `!` real en la rama `then` de `->` (cierra D-06; V-01, V-02; sustitución de `defined`, O-2) | F-18 | D | 2 | S1 | T-07 |
| T-04 | `mundo.pl`: zonas, `conexion/2`, `adyacente/2` simétrica, `puede_viajar/1`, descripciones | F-01 | D | 1 | S1 | T-03 |
| T-05 | `estado.pl` (crear el módulo): hechos dinámicos y `persistente/1`, único escritor, `reiniciar/0`, semilla | F-02 | D | 1 | S1 | T-04 |
| T-06 | `estado:aplicar_efectos/1` con los efectos necesarios hoy (los demás se añaden en la tarea que los usa) y `con_transaccion/1` simple | F-02 | D | 1 | S1 | nueva (06 §5.3) |
| T-07 | `juego.pl` (crear el módulo): `ejecutar/2`, tabla de fases permitidas y `objetivo_de_accion/2` | F-04 | D | 2 | S1 | nueva (06 §5.3) |
| T-08 | `ui.pl` y `main.pl`: bucle de lectura de términos, errores de sintaxis sin caída (parser v1), `ayuda`, `salir` | F-04 | D | 2 | S1 | T-06 + nueva (06 §5.3) |
| T-09 | Comandos `ir`, `descansar` (2 quesos) y `mirar` con sus pruebas | F-03 | D | 1 | S1 | T-05 |
| T-10 | `compania.pl`: 4 personajes con atributos y filas; `compania/0` con `findall`; `miembro/1`, `activo/1`, `en_pie/1` | F-05 | D | 1 | S2 | T-08 |
| T-11 | `economia.pl`: `queso/3` (12 cheddar), maduración diaria, `categoria_queso/2`, `queso_total/1`, `inventario`; `valor_queso/3` informativo | F-08 | D | 1,5 | S2 | T-09 + T-10 |
| T-12 | Ración diaria automática (fresco, curado, rancio) y hambre: baja moral y vida sin pasar de 1 | F-09 | D | 1 | S2 | T-11 |
| T-13 | Moral 0–10, sueldos en unidades, comando `pagar` explicable (`puede_pagar_sueldos/0`), impago al salir de la taberna | F-10 | D | 2 | S2 | T-12 + nueva (06 §5.3) |
| T-14 | Huelga derivada: `esta_en_huelga/1` (moral ≤ 2) | F-11 | D | 1 | S2 | T-36 (pasa de ◇ a Debe) |
| T-15 | `solve/2` completo: conjunción, negación, `->`/`;`, predefinidos, hechos, reglas, corte real, módulos, diagnósticos mínimos; primeros 5 casos de equivalencia | F-18 | D | 2 | S2 | T-13 |
| T-16 | `explicar` v1: formato en árbol con valores y marcas ASCII, probado con reglas de economía y viaje | F-19 | D | 1,5 | S2 | T-14 |
| T-17 | `narrador.pl` mínimo y puro: `frase/3` estático, frase genérica, variantes con la semilla, nombres con artículo, integración con `explicar` | F-24 | D | 1,5 | S3 | T-15 |
| T-18 | Bestiario v1: los 5 tipos con clase y atributos | F-17 | D | 1 | S3 | T-16 |
| T-19 | Rasgos núcleo: `teme_caballos` (con `ignora_miedo/1`) y `hechizos_de_cocina`; `puede_atacar/2` | F-06 | D | 2 | S3 | T-17 |
| T-20 | Estado de combate, iniciativa y orden de turnos | F-13 | D | 1,5 | S3 | T-18 |
| T-21 | `dano/3` con modificadores por rasgo y moral; aplicar daño | F-13 | D | 1 | S3 | T-19 |
| T-22 | Comandos `atacar` y `defender`; regla de fila alcanzable | F-13 | D | 2 | S3 | T-20 |
| T-23 | Bucle de combate, fin de combate (los caídos se levantan con 1) y conexión con `juego`/`ui` | F-13 | D | 1 | S3 | T-21 |
| T-24 | IA enemiga: `accion_enemigo/2` (tres reglas con corte) + `robar_queso`, `embestir`, `invocar_moho`, gemela sin corte y prueba del orden de cláusulas; IA del jefe | F-16 | D | 2 | S4 | T-23 |
| T-25 | Contratos (datos): 4 contratos con `resolucion/3` y condiciones (`rasgo_no`, `contratos_cumplidos_min`), `contratos`, `aceptar/1` | F-12 | D | 2 | S4 | T-24 |
| T-26 | Contratos: `resultado/3` (éxito / a medias / fracaso), consecuencias y cobro automático en la taberna | F-12 | D | 2 | S4 | T-25 |
| T-27 | `elegir/1` y motor de evento mínimo (`gato_en_el_arbol`, entrega la venda) | F-35 | D | 2 | S4 | nueva (06 §5.3) |
| T-28 | Finales (`chapuza`, `derrota_combate`, `derrota_hambre`) y condición de hambre; etiqueta `v0.9-jugable` | F-26 | D | 1,5 | S4 | T-27 + nueva (06 §5.3) |
| T-29 | `clave_de_diag/2`: traductor de diagnósticos a claves del narrador, probado con las 6 claves del núcleo | F-20 | D | 1 | S4 | nueva (06 §5.3, X-21) |
| T-30 | Habilidades: una por personaje con `efecto_habilidad/2` y `puede_habilidad/2`; el hechizo consume queso | F-14 | D | 1,5 | S5 | T-22 |
| T-31 | Escolta de Clotilde: contador de golpes recibidos que decide el resultado de `gallina_noble` | F-12 | D | 1 | S5 | nueva (06 §5.3, D-33) |
| T-32 | `por_que_no` v1: primer subobjetivo fallido y negación explicada; demostraciones centrales 1 y 2 | F-20 | D | 2 | S5 | T-26 |
| T-33 | `explicar` retrospectivo: `ultima_prueba/2` guardada antes de los efectos y explicación de un turno enemigo con corte (demostración central 3) | F-19 | D | 1 | S5 | nueva (06 §5.1, estimación de este documento) |
| T-34 | `por_que_no` v2: varias cláusulas aplicables, negaciones anidadas, modo resumido | F-20 | D | 1,5 | S5 | T-29 |
| T-35 | Banco de frases del narrador (≈ 70) y descripciones cómicas de zonas y contratos | F-24 | D | 2 | S5 | T-30 |
| T-36 | Playtest guiado 1 (sesión completa, vía cómoda) y lista de ajustes | F-32 | D | 1 | S5 | T-31 |
| T-37 | **Reserva de colchón (no financiada, ver 4.3):** corregir errores y terminar lo que se haya quedado a medias en S1–S4 | — | D | 3 | S5 | T-28 |
| T-38 | Balance numérico y playtest 2 (con otra persona) | F-32 | D | 1,5 | S6 | T-39 |
| T-39 | Prueba de equivalencia `solve/2` frente a ejecución directa (≥ 20 objetivos, todas las soluciones, con y sin corte) y `tests/todas.pl` con la orden única | F-32 | D | 1 | S6 | T-40 |
| T-40 | Partida de demostración reproducible en `examples/` (guion de comandos, semilla, salida, explicaciones) y meta-comando `demo` | F-33 | D | 1,5 | S6 | T-41 |
| T-41 | README final (versión, ruta, extras), manual breve de jugador y DISENO.md al día; el stub de `explicar.pl` y el README dejan de prometer `explicar/1` como predicado | F-34 | D | 1,5 | S6 | T-42 |
| T-42 | Informe/memoria (reutilizando DISENO.md y capturas de `explicar`), si procede | F-34 | D | 2 | S6 | T-43 |
| T-43 | Guion de exposición, ensayo cronometrado y copia grabada de la demo (plan B) | F-34 | D | 1,5 | S6 | T-44 |
| T-44 | Lista de verificación final, etiqueta `v1.0-rc1` / `v1.0-entrega` y entrega | F-34 | D | 0,5 | S6 | T-45 |

**Totales (verificados con un cálculo):** por semana S1 = 12 · S2 = 10 · S3 = 10 · S4 = 10,5 · S5 = 10 (+ 3 de reserva) · S6 = 9,5. **Tareas Debe = 62,0 h; con la reserva T-37 = 65,0 h** (Nivel A). Hasta el viernes 4 de diciembre se acumulan 52,5 h de tareas (55,5 con la reserva).

### Objetivo (solo con adelanto; ver 1.3 y 4.3)

Estimaciones de este documento (06 no las da). Orden de entrada: de arriba abajo.

| ID | Tarea | Func. | h | Antes |
|---|---|---|---|---|
| O-1 | `nivel(resumido)` y `nivel(detallado)` | F-21 | 1,5 | T-32 |
| O-2 | `arbol` en texto indentado | F-22 | 1 | T-33 |
| O-3 | Rasgos adicionales de Rufino (`cantando`, `silencio_pagado`) y Tuerca | F-07 | 2,5 | T-35 |
| O-4 | `comer(Tipo)` | F-36 | 0,5 | nueva (D-12) |
| O-5 | `usar` y `huir` (no del jefe) | F-15 | 2 | T-37 |
| O-6 | Cinco eventos aleatorios con semilla fija | F-25 | 2 | T-34 |
| O-7 | Contratos `peaje_del_ganso` y `fantasma_charlatan`, enemigos `ganso_recaudador` y `arquero_aburrido`, 2 acciones de IA más | F-12/F-17 | 3 | nueva |
| O-8 | Frases hasta ≈ 120, finales `leyenda` y `quiebra`, 2 arcos, 3 eventos de campaña, tutorial de 9 pasos | F-24/F-26 | 5,5 | nueva |

Total Objetivo ≈ 18 h; no cabe entero y no se espera que quepa.

### Extra (no se hace; se conserva en los documentos como contenido ampliable)

| Tarea | Func. | h | Antes |
|---|---|---|---|
| Exportación Graphviz del árbol | F-23 | 1,5 | T-38 |
| Tienda de objetos | F-27 | 2 | — |
| Reclutar en la taberna | F-28 | 2 | — |
| Guardar y cargar | F-29 | 2 | — |
| Resto de la columna Extra de 1.3 (9 contratos más, 12 enemigos, 20 objetos, etc.) | — | — | — |

---

## 7. Definición de "hecho"

### 7.1 Tarea

- El código carga sin avisos (`swipl src/main.pl` y las pruebas) con **SWI-Prolog 5.10.4**.
- Tiene al menos una prueba plunit (o, si es solo contenido, una comprobación manual anotada).
- Las reglas nuevas se pueden consultar con `explicar` o `por_que_no` cuando corresponda (es decir, son predicados accesibles a `clause/2`).
- Está confirmada (commit) con un mensaje en español, breve y sin trailers.
- No deja `assert`/`retract` fuera de `src/estado.pl`; los demás módulos devuelven efectos como datos.
- Usa solo funciones que existen en 5.10.4: nada de `yall` (`>>`), `foldl/4`, `sum_list/2` (existe `sumlist/2`), `max_member/2`, `sort/4`, `random_between/3`, `random_member/2`, `split_string/4`, `atom_string/2`; el texto va siempre en átomos con comillas simples.

### 7.2 Funcionalidad

- Cumple todos sus criterios de aceptación (sección 3) comprobados a mano o con prueba.
- Se puede jugar desde `swipl src/main.pl` sin cargas manuales.
- Tiene al menos una frase del narrador o genérica para sus reglas principales.
- Aparece reflejada en el README y, si cambió respecto al canon, en DISENO.md.
- Todas las pruebas existentes siguen pasando.

### 7.3 Entrega final

- Etiqueta `v1.0-entrega` sobre un commit en el que:
  - todas las funcionalidades "Debe" están hechas;
  - las pruebas pasan desde un clon limpio;
  - una partida completa (victoria) y una derrota se han jugado sin excepciones;
  - `examples/` contiene la demo reproducible y su salida;
  - el README explica instalación, versión de SWI-Prolog (5.10.4) y ruta, cómo jugar, cómo correr pruebas, cómo usar `explicar`/`por_que_no` y qué es contenido "extra";
  - la lista de verificación de la sección 14 está completa;
  - el entregable exigido por el curso (sección 9) está subido o enviado y confirmado.

---

## 8. Plan de pruebas y calidad

### 8.1 Pruebas de reglas (plunit)

Una por módulo, en `tests/`, con un archivo agregador `tests/todas.pl` (D-31):

- **Estado y mundo:** simetría de conexiones, `ir`/`descansar`/`mirar` por `juego:ejecutar/2`, día, reinicio, `con_transaccion/1`.
- **Economía:** maduración (bordes 2→3 y 9→10), orden de la ración (fresco, curado, rancio), comida con y sin suficiente queso, `pagar` suficiente e insuficiente, impago al salir, huelga (moral 2 y 3).
- **Combate:** daño (ejemplo 11−5=6, mínimo 1, demo 11−2=9), orden por iniciativa, reglas de fila, `puede_atacar/2` con y sin rasgo y con y sin venda, IA con orden de cláusulas y gemela sin corte.
- **Contratos:** condiciones que se cumplen y no (`rasgo_no`, `contratos_cumplidos_min`), resolución en sus tres resultados, `elegir/1`.
- **Narrador:** quitar las frases no cambia ningún resultado lógico; nombres con artículo y número; sin `assert`.
- **Meta-intérprete:** equivalencia directa/`solve/2` sobre ≥ 20 objetivos con todas las soluciones y mismo orden (`=@=`), incluyendo negación, aritmética, `->`, corte y predicados de varios módulos; dinámico sin cláusulas; `corte_no_soportado`; casos de error (objetivo no ejecutable) sin caída. `clave_de_diag/2` con las 6 claves del núcleo.

Archivos: `test_estado`, `test_mundo`, `test_economia`, `test_combate`, `test_contratos`, `test_explicar`, `test_narrador`, `test_equivalencia`. Las pruebas de arquitectura y de propiedades de 02 quedan para después (extra); la búsqueda de `assert`/`retract` se hace con `grep` en la lista de verificación.

**Comando único:** `swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl` (en la práctica, con la ruta o el alias de 5.10.4). Comprobado el 2 de noviembre de 2026 en 5.10.4: con todas las pruebas correctas el código de salida es 0 y con una prueba que falla es 1. La forma `-g run_tests -t halt` que figuraba antes devuelve 0 aunque falle una prueba, por eso se descarta. Quedan por comprobar las opciones de plunit usadas (V-03, V-14).

### 8.2 Partidas de prueba (playtests) guiadas

| Playtest | Cuándo | Quién | Guion | Qué se observa |
|---|---|---|---|---|
| PT-1 | vie 4 dic (S5) | El propio estudiante | Recorrido completo por la vía "cómoda" (los 4 contratos), sin ayuda de documentación | Bloqueos, mensajes confusos, errores, duración |
| PT-2 | lun 7 / mar 8 dic (S6) | Otra persona sin conocer el proyecto (compañero/a) | Se le da solo el README; se anota dónde duda | Claridad de comandos, `ayuda`, humor, dificultad |
| PT-3 | mié 9 dic (S6) | El propio estudiante con la candidata `v1.0-rc1` | Ejecuta el guion de la exposición tal cual, dos veces | Reproducibilidad y tiempos |

Además, tres rutas guiadas para detectar estrategias degeneradas: (a) no pagar nunca los sueldos, (b) ignorar la comida, (c) intentar cada contrato sin condiciones cumplidas (para ejercitar `por_que_no`).

### 8.3 Qué se mide

- Pruebas pasando / totales (objetivo 100 %).
- Excepciones no controladas durante una partida completa (objetivo 0).
- Duración de una partida completa: 15–60 minutos según la ruta; días de juego hasta el jefe: 9–26 (X-51, provisional; se mide en PT-1).
- Tamaño de las explicaciones: `explicar` en nivel resumido ≤ 15 líneas; tiempo de respuesta < 1 s. (V-11: profundidad de pila de `solve/2` con una prueba real de combate.)
- Cobertura de narrador: porcentaje de reglas "explicables" con frase propia (objetivo ≥ 70 %; el resto usa la genérica).
- Balance: queso final y bajas en PT-1/PT-2 (que ni todas las partidas se ganen ni ninguna).
- Errores abiertos de prioridad alta (objetivo 0 al congelar el viernes 4 dic y de nuevo el 10 dic).

---

## 9. Entregables del curso

**Todo lo que sigue es una suposición mía, salvo lo que ya está confirmado:** (confirmado) existe una entrega final el viernes 11 de diciembre de 2026 y una exposición presencial posterior; la idea ya fue aprobada; el proyecto usa SWI-Prolog 5.10.4 por decisión del autor (D-02). Se plantea qué probablemente se pide y se propone preguntarlo a la profesora **antes del viernes 6 de noviembre** (tarea T-02).

| Entregable | Estado | Plan si se confirma |
|---|---|---|
| Código fuente ejecutable (repositorio o archivo comprimido) | Suposición muy probable | Repositorio con etiqueta `v1.0-entrega`; si piden archivo, generar `.zip` desde la etiqueta |
| Documentación técnica (README + DISENO.md) | Suposición muy probable | Ya prevista (F-34) |
| Informe o memoria escrita (introducción, diseño, uso de lo declarativo, pruebas, conclusiones) | **Suposición** | T-42; se reutiliza DISENO.md; extensión a confirmar |
| Presentación (diapositivas) para la exposición | **Suposición** | Plan de la sección 10; se prepara solo si la piden o ayuda |
| Demostración ejecutable en vivo | **Suposición** (la exposición presencial lo sugiere) | Sección 10 |
| Evidencias de prueba (salidas, capturas) | **Suposición** | Se guardan en `examples/` |
| Manual de usuario | **Suposición** | Manual breve dentro del README o en `docs/` |

**Preguntas para la profesora** (D-34 a D-38):

1. (D-34) ¿Qué se entrega exactamente el 11 de diciembre: código, informe, o ambos? ¿Hay formato o extensión mínima? ¿Por qué medio se entrega (plataforma del curso, correo, enlace al repositorio)? ¿Se prefiere un `.zip`?
2. (D-35) ¿La evaluación usa SWI-Prolog 5.10.4, la versión del material del curso? ¿Se pueden usar módulos (`:- module/2`), `library(plunit)` y las bibliotecas `lists`, `apply` y `aggregate`? ¿Es válido usar `assert/retract` para el estado de la partida, aislado en un único módulo? Es la pregunta más importante: el diseño entero usa módulos y plunit.
3. (D-36) ¿La exposición es con demostración en vivo? ¿Cuánto tiempo, y se debe llevar presentación de diapositivas?
4. (D-37) ¿Cuál es la fecha prevista de la exposición presencial y puede adelantarse?
5. (D-38) ¿Se valoran las funciones fuera de las conferencias 1–6 (`format/3`, `read_term/2`, `msort/2`, `assoc`), o conviene limitarse a lo visto?

---

## 10. Plan de la exposición

### 10.1 Preparación

- Equipo propio con SWI-Prolog **5.10.4** instalado (`C:\Program Files\pl\bin`, con alias de arranque) y el repositorio clonado en la etiqueta `v1.0-entrega`; copia de seguridad en memoria USB.
- **Partida preparada:** `examples/` contiene el guion de comandos y una semilla fija (generador congruencial propio, no `random/1`), de modo que la demostración es determinista. El meta-comando `demo` deja el juego en un estado intermedio fijado (día ≈ 12, queso mezclado fresco/curado/rancio, Baldomero listo para combatir, `gallina_noble` aún sin aceptar y sin venda) para no depender de jugar desde cero; si hacen falta dos escenas (combate y tablón), `demo` acepta el nombre de la escena (se fija en T-40).
- Terminal con letra grande, fondo claro y dos ventanas: el juego y el editor con los archivos `.pl` abiertos. Árbol de pruebas en ASCII (`[ok]`, `[no]`); tildes con `set_stream(user_output, encoding(utf8))` (comprobar la consola en T-02).

### 10.2 Guion (≈ 13 minutos, margen hasta 15)

| Tiempo | Qué se muestra | Mensaje declarativo |
|---|---|---|
| 0:00–1:00 | Presentación del juego (premisa del queso, 20 segundos) y de la tesis: *el juego es un programa lógico que puede explicarse a sí mismo*. | Declarativo frente a imperativo (Conf. 1) |
| 1:00–3:00 | Editor: `mundo.pl` y `compania.pl` (hechos); regla `puede_atacar/2` y `dano/3` leídas en voz alta como frases. | Hechos y cláusulas definidas (Conf. 1, 2) |
| 3:00–5:00 | Juego: `mirar.`, `pagar.`, `ir(bosque).`, `inventario.` (el día avanza, el queso madura y uno pasa a rancio). | Aritmética (5) y BD dinámica aislada en `estado.pl` (6) |
| 5:00–7:30 | **Demostración central 1.** Combate: `explicar(atacar(baldomero, bandido_torpe)).` (`D = 9 (11 - 2)`). Luego contra el montado: `por_que_no(atacar(baldomero, bandido_montado)).` | Árbol SLD, negación como fallo (3, 4) |
| 7:30–9:30 | Editor: las cláusulas de `solve/2` y cómo cada nodo corresponde a un paso de resolución; mostrar un nodo `[predefinido]`, uno `[negacion]` y uno `[corte]`. Opcional: `nivel(detallado)` y `arbol` (objetivo). | Metaprogramación y `clause/2` (6); SLD (3) |
| 9:30–11:00 | **Demostración central 3.** IA enemiga: ver `accion_enemigo/2`, ejecutar `explicar` (sin argumento) tras un turno enemigo para ver la prueba guardada con el nodo `corte`, mostrar la gemela sin corte (las alternativas que se podan) y, si hay tiempo, cambiar el orden de dos cláusulas y repetir. | Corte y orden de cláusulas (4) |
| 11:00–12:00 | **Demostración central 2.** `por_que_no(aceptar(gallina_noble)).` indica `rasgo_no(teme_caballos)`; tras conseguir la venda (`gato_en_el_arbol`), se acepta. Final de la partida con una frase del narrador. | Reglas explicables de punta a punta |
| 12:00–13:00 | Cierre: matriz de la sección 11 (en una diapositiva), pruebas pasando (`run_tests`) y qué haría con más tiempo (el contenido "extra"). | Resumen y verificación |
| 13:00–15:00 | Preguntas. | Ver respuestas preparadas abajo |

### 10.3 Respuestas preparadas

- *¿`assert/retract` no es impuro?* Sí: se aísla en un único módulo, `estado.pl`, y todo lo demás son consultas puras que devuelven efectos como datos; es el límite explícito entre estado y reglas.
- *¿El corte rompe lo declarativo?* Solo se usa en la IA enemiga, donde el orden de prioridad es parte de la especificación; el resto usa `\+` y condiciones explícitas. El meta-intérprete implementa el corte de verdad y se prueba contra la gemela sin corte.
- *¿El meta-intérprete es completo?* Cubre el subconjunto que usa el juego (conjunción, negación, `->`, predefinidos, hechos, reglas y corte); lanza `corte_no_soportado` ante un `!` anidado; se prueba por equivalencia con la ejecución directa.
- *¿Por qué los comandos son términos?* Para que el núcleo se pruebe sin consola: `juego:ejecutar/2` devuelve datos y `ui` es la única que escribe.
- *¿Por qué SWI-Prolog 5.10.4?* Es la versión del curso; el proyecto usa solo su subconjunto (sin `yall`, `foldl/4`, `random_between/3`, etc.).

### 10.4 Plan B

| Fallo | Respuesta |
|---|---|
| SWI-Prolog no arranca o falla en el equipo de la sala | Usar el equipo propio; si no es posible, proyectar la copia grabada de la demo (vídeo o transcript en `examples/`) |
| La partida se desvía o el estado queda incoherente | El meta-comando `demo` reinicia el estado preparado y se continúa desde el siguiente punto del guion |
| `explicar` o `por_que_no` fallan en vivo | Mostrar la salida guardada en `examples/explicaciones/` y explicar el código en el editor |
| Se acaba el tiempo | Acortar primero la presentación y el bloque de hechos (1:00–3:00) y el cambio de orden de cláusulas; **conservar las tres demostraciones centrales** y el bloque de `solve/2` |
| No hay proyector con terminal legible | Diapositivas o PDF con las salidas clave ya impresas |
| Las tildes o los símbolos salen rotos en la consola de la sala | La salida ASCII por defecto no depende de la codificación; `ajuste(ascii, true)` fuerza los símbolos de árbol en ASCII |

La exposición puede ocurrir meses después de la entrega: la etiqueta `v1.0-entrega` es inmutable, el README fija la versión de SWI-Prolog y el plan B no depende de internet. Una semana antes de la fecha se repite PT-3 (el guion completo) con la etiqueta.

---

## 11. Matriz de lo declarativo (conferencias 1–6)

| Conferencia | Concepto | Dónde se demuestra en el proyecto | Cómo se ve en la exposición |
|---|---|---|---|
| 1 | Declarativo frente a imperativo; qué frente a cómo | Todo el modelo: el mundo son hechos y las reglas del juego son cláusulas (`puede_atacar/2`, `dano/3`, `esta_en_huelga/1`) | Lectura de la regla como frase |
| 1 | Sintaxis, hechos, listas | `zona/2`, `conexion/2`, compañía, inventario y filas como listas; `member/2`, `length/2`, `msort/2`, `sumlist/2` | Editor + `compania.` |
| 2 | Cláusulas definidas | Reglas de contratos, rasgos, economía | Regla de contrato leída en voz alta |
| 2 | Unificación | Consultas con variables (`conexion(X, bosque)`); resultados de `dano/3`; unificadores mostrados por `explicar` | `D = 9` en la explicación |
| 3 | Resolución SLD y árbol de derivación | Meta-intérprete `solve/2`, `explicar`, `por_que_no`; `arbol` (objetivo) | Árbol de una acción |
| 3 | Búsqueda con retroceso (BPP-RC) y orden de cláusulas | IA enemiga ordenada por prioridad y su gemela sin corte; `por_que_no` recorre cláusulas alternativas | Cambio de orden y efecto |
| 4 | Corte | `accion_enemigo/2`; `solve/2` lo implementa de verdad (nodo `corte`) y la prueba de equivalencia lo contrasta con la gemela sin corte | `explicar` de un turno enemigo |
| 4 | Negación como fallo (`\+`) | `puede_atacar/2` (`\+ aturdido`, `\+ (teme, clase)`), `rasgo_no/1`; `por_que_no` explica el hecho que bloquea | `por_que_no` de Baldomero y de `gallina_noble` |
| 5 | Aritmética (`is`, comparaciones) | Daño, sueldos, comida, maduración, valor informativo del queso y generador congruencial propio (`S1 is (S0*75+74) mod 65537`) | Queso rancio al avanzar el día |
| 6 | Clasificación y construcción de términos (`callable`, `functor`, `=..`) | `solve/2` descompone objetivos; `juego:ejecutar/2` y `objetivo_de_accion/2` descomponen comandos; `arbol`/`.dot` construyen nodos (objetivo/extra) | Código de `solve/2` |
| 6 | Metaprogramación (`clause/2`, `call/1`) | Meta-intérprete, `por_que_no` y comprobación de condiciones de contrato como metapredicados | Código de `solve/2` |
| 6 | BD dinámica (`assert`, `retract`) | Estado de la partida, aislado en `estado.pl` (único escritor) | Límite estado/reglas |
| 6 | `findall`, `bagof`, `setof`, `aggregate_all` | `compania/0`, `inventario`, `contratos`, orden de turnos | `inventario.` |
| 6 | Módulos | Arquitectura en 12 módulos con interfaz explícita (`src/*.pl`) | Estructura del repositorio |

**Lo que el proyecto no usa** (y se dice abiertamente): programación funcional (conferencias 7–9), tal como establece el canon (§14); tampoco DCG ni `random/1` (la partida debe ser reproducible).

---

## 12. Gestión del repositorio

### 12.1 Ramas

- `main`: siempre carga y pasa las pruebas.
- Una rama corta por funcionalidad o tarea: `feat/f-13-combate`, `feat/f-19-explicar`, `docs/memoria`, `fix/dano-minimo`. Se integran en `main` cuando se cumple la definición de "hecho" de la tarea; se eliminan después.
- Sin ramas de larga duración. Durante S5–S6 solo entran en `main` correcciones y documentación.

### 12.2 Mensajes de commit

- En español, breves (idealmente < 70 caracteres), en presente o con verbo de acción: *Añade*, *Corrige*, *Refactoriza*, *Documenta*.
- Opcional: prefijo con la funcionalidad (`F-13: …`).
- **Sin trailers de atribución ni de coautoría.** Cuerpo solo si hace falta explicar el porqué.
- Ejemplos: `Añade maduración diaria del queso` · `F-20: explica la negación que bloquea un ataque` · `Corrige daño mínimo cuando la defensa supera al ataque`.

### 12.3 Etiquetas

| Etiqueta | Cuándo | Significado |
|---|---|---|
| `v0.1-diseno` | vie 6 nov | Documentos de diseño alineados y cerrados |
| `v0.5-motor` | vie 13 nov | Economía y primer `explicar` |
| `v0.9-jugable` | vie 27 nov | Partida mínima completa de principio a fin |
| `v1.0-rc1` | mié 9 dic | Candidata a entrega (alcance "Debe" cerrado desde el 4 dic) |
| `v1.0-entrega` | jue 10 / vie 11 dic | Versión entregada (inmutable) |

### 12.4 Contenido de carpetas

- `src/`: código fuente de los **12 módulos**: los 10 del canon (`mundo`, `compania`, `economia`, `combate`, `contratos`, `eventos`, `explicar`, `narrador`, `ui`, `main`) más `estado.pl` y `juego.pl` (se crean en T-05 y T-07). `parser` vive dentro de `juego`/`ui` y `arbol` dentro de `explicar`.
- `tests/`: `todas.pl` (agregador), `test_estado.pl`, `test_mundo.pl`, `test_economia.pl`, `test_combate.pl`, `test_contratos.pl`, `test_explicar.pl`, `test_narrador.pl`, `test_equivalencia.pl`. Se reemplaza `.gitkeep` al añadir el primer archivo.
- `examples/`: `demo-comandos.txt` (guion), `demo-salida.txt` (salida esperada), `explicaciones/` (salidas de `explicar`/`por_que_no`), registro de partida de respaldo; `arbol-ejemplo.dot` solo si se hiciera F-23 (extra).
- `docs/`: `DISENO.md`, este documento, el informe/memoria (cuando se escriba), manual de jugador, guion de la exposición y `img/` para capturas. Los demás documentos de la fase de diseño viven aquí también.
- `out/` y `saves/` quedan fuera del control de versiones (ya están en `.gitignore`; `saves/` no se usa en la v1 porque guardar y cargar son extra).

---

## 13. Riesgos y plan de recorte

### 13.1 Riesgos principales

| Riesgo | Prob. | Impacto | Señal de alerta | Respuesta |
|---|---|---|---|---|
| Sobrecarga: 65 h declaradas frente a 62 disponibles (déficit de 3 h, colchón real cero) | Alta | Alto | Desvío > 3 h acumuladas un viernes | Pasar al Nivel B ese fin de semana (4.3 y 13.2) |
| El meta-intérprete choca con módulos, `findall`, corte real y predicados dinámicos | Alta | Alto | Al terminar el spike del lunes/martes de S1, `solve/2` no recorre una regla del mundo o el `!` no poda | Spike en S1 (T-03) que cierra D-06; Plan B documentado: corte como hoja que triunfa y la IA fuera de la equivalencia |
| Dedicación real inferior a 10 h/semana | Media | Alto | Media < 9 h en S1–S2 | Nivel B el vie 13 nov (4.3) |
| Las estimaciones comprimidas (combate 5,5 h, IA, frases) se quedan cortas | Media | Alto | Un viernes con desvío de 1,5–3 h | Reservar T-37; aplicar B-1 a B-3 antes de que crezca |
| El alcance crece (más contratos, rasgos, chistes) | Alta | Medio | Tareas fuera del backlog | Cerrar el Debe el 4 dic; cualquier idea nueva va a Objetivo o Extra |
| Árboles de explicación demasiado grandes | Media | Medio | `explicar` > 15 líneas en el nivel resumido | Nivel resumido (objetivo) o mostrar solo ramas relevantes |
| Una función no existe en 5.10.4 | Media | Medio | Error `existence_error` al cargar o probar | Lista de prohibidas en 7.1; `grep` en la lista de verificación; sustituciones de 06 §2.8 |
| Tildes o símbolos rotos en la consola de entrega | Media | Medio | Prueba de T-02 con salida degradada | Salida ASCII por defecto y `set_stream(user_output, encoding(utf8))`; si falla la entrada con tildes, el parser v2 queda descartado |
| Fallo en vivo durante la exposición | Media | Alto | — | Plan B de la sección 10.4 |
| Las exigencias del curso resultan distintas (p. ej. informe largo o 5.10.4 no aceptada) | Media | Medio | Respuesta de la profesora | T-42 se ajusta; el informe se alimenta de DISENO.md |
| El humor se queda corto | Media | Bajo | PT-2 sin risas | Separar narrador de la lógica; iterar frases en S5–S6 |

### 13.2 Plan de recorte (se recorta de arriba abajo)

**Nivel 0, siempre:** no se empieza nada de lo "Extra" (F-23, F-27, F-28, F-29 y la columna Extra de 1.3), ni de lo "Objetivo" salvo adelanto (4.3).

**Nivel B (D-01; ≈ −7,5 h, de 65 a ≈ 57,5 h).** Se aplica en este orden, hasta absorber el desvío; B-1 a B-3 (−4 h) bastan además para financiar la reserva de 3 h:

| Paso | Recorte | h | Tareas afectadas |
|---|---|---|---|
| B-1 | `por_que_no` v2 (queda v1; sin modo resumido ni varias cláusulas) | −1,5 | T-34 |
| B-2 | PT-2 e informe más cortos (PT-2 con balance mínimo; informe de 1 h reutilizando DISENO.md) | −1,5 | T-38 (−0,5), T-42 (−1) |
| B-3 | Banco de frases de ≈ 70 a ≈ 50 | −1 | T-35 |
| B-4 | Una habilidad menos con efecto especial (las demás se reducen a daño y curación sencillos) | −1 | T-30 |
| B-5 | `demo` sencillo (un solo estado fijado, sin escenas) | −0,5 | T-40 |
| B-6 | `gato_en_el_arbol` sustituido por `peaje_del_ganso` y sin `elegir/1`; la `venda_de_caballos` pasa a ser recompensa de `ratas_del_granero` (neto según 06 §5.2) | −2 | T-27 (y ajustes de T-25, T-28 y F-35 pasa a objetivo) |

**Más allá del Nivel B (emergencia, estimaciones de este documento).** Solo si tras el Nivel B sigue habiendo desvío:

1. La escolta de Clotilde (T-31): `gallina_noble` se resuelve solo por el combate (−1).
2. Frases de ≈ 50 a las 32 del núcleo de 05 §8.4 (−0,5).
3. Acciones especiales de IA: se queda el canon de tres reglas más `invocar_moho` para el jefe (−0,5).
4. Informe mínimo: DISENO.md más las salidas de `explicar` (−0,5).
5. Se simplifica la economía de sueldos (conservando comida y maduración) antes que cualquier parte del modo explicar.

**Mínimo irrenunciable** (no se recorta): F-01 a F-06, F-08, F-09 y F-10 en versión reducida, F-13, F-16, F-17, F-18, F-19, F-20, F-24 (frase genérica), F-26, F-32 (equivalencia) y F-33; y el soporte que los hace posibles, F-02 (único escritor) y F-04 (`juego:ejecutar/2`). Si ni siquiera esto cabe, se sacrifica primero la economía de sueldos (conservando comida y maduración) antes que cualquier parte del modo explicar.

---

## 14. Lista de verificación final

### Miércoles 9 de diciembre (candidata)
- [ ] Etiqueta `v1.0-rc1` creada.
- [ ] Clon limpio en otra carpeta: `swipl src/main.pl` arranca con SWI-Prolog 5.10.4.
- [ ] `swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl` pasa con código 0.
- [ ] PT-3 ejecutado (guion completo, dos veces) y tiempos anotados.
- [ ] Ninguna excepción en una partida de victoria ni en una de derrota (`derrota_combate` y `derrota_hambre`).

### Jueves 10 de diciembre (cierre)
- [ ] Búsqueda de `assert`/`retract` confirma que solo están en `src/estado.pl`.
- [ ] Búsqueda de funciones inexistentes en 5.10.4 (`>>`, `foldl(`, `sum_list(`, `max_member(`, `random_between(`, `random_member(`, `split_string(`, `atom_string(`) sin resultados.
- [ ] README: versión de SWI-Prolog (5.10.4), ruta de instalación y alias, instalación, cómo jugar, cómo correr pruebas, cómo usar `explicar`/`por_que_no` (son comandos) y qué contenido es "extra".
- [ ] DISENO.md refleja lo construido (sección 15 resuelta) y no promete lo recortado.
- [ ] `examples/` contiene guion, semilla, salida y explicaciones; la demo es byte a byte reproducible.
- [ ] Informe/memoria listo (si se pidió) con capturas actualizadas.
- [ ] Guion de exposición ensayado con cronómetro (≤ 15 min); plan B grabado y probado; las tres demostraciones centrales ensayadas.
- [ ] Revisión del historial: mensajes en español, breves, sin trailers de atribución ni coautoría.
- [ ] Repositorio sin archivos sobrantes (`out/`, `saves/`, `*.qlf`, copias).
- [ ] Copia de seguridad (`.zip` de la etiqueta + USB).

### Viernes 11 de diciembre (entrega)
- [ ] Etiqueta `v1.0-entrega` creada sobre el commit final y subida.
- [ ] Entregable enviado por el medio acordado (código, informe, enlace) y confirmación guardada.
- [ ] Una última comprobación desde el artefacto entregado (descargar y arrancar).
- [ ] Fecha de la exposición confirmada y plan de repetir PT-3 una semana antes.

---

## 15. Cambios propuestos al canon (DISENO.md)

Estado tras la revisión de docs/06 (2 de noviembre de 2026): el autor aceptó las recomendaciones; **ninguno se ha aplicado todavía a DISENO.md** salvo que se indique lo contrario en la documentación del repositorio. La columna "Resolución" dice cómo queda cada propuesta.

| ID | Sección del canon | Propuesta | Motivo | Resolución tras 06 |
|---|---|---|---|---|
| C-1 | §15 Plan de trabajo | Sustituir el plan de 6 semanas por el calendario de la sección 4 de este documento: meta-intérprete desde S1, `por_que_no` en S4 (no en S5), S5 como colchón. | El meta-intérprete es lo que más pesa en la evaluación y el mayor riesgo técnico; conviene probarlo pronto. | **Aceptada con ajustes** (06 §3.3, X-05, D-01): calendario de 03 como maestro; el meta-intérprete arranca en S1 (spike que cierra D-06) pero `por_que_no` v1 pasa a la primera mitad de S5 y S5 deja de ser colchón libre: el Nivel A llena S4 con contratos y `elegir/1`, y la reserva de 3 h no está financiada (4.3). |
| C-2 | §11.2 `arbol` | Separar `arbol/1` en texto (Debería) de la exportación Graphviz (Podría). | Evitar que una dependencia externa bloquee una característica que el README anuncia. | **Aceptada**: `arbol` en texto pasa a Objetivo (F-22); Graphviz a Extra (F-23). |
| C-3 | §7 Contratos | Aclarar la semántica de `rasgo_no(teme_caballos)`: contra el miembro designado o contra "algún miembro disponible". Decidir en T-24. | Evita un contrato imposible por diseño y convierte la condición en una buena demostración de `por_que_no`. | **Sustituida por D-19 / 04-1** (X-37): se evalúa contra todos los miembros activos que no ignoren el miedo (la `venda_de_caballos`); `teme(A, caballo)` consciente de la venda. |
| C-4 | §4 Compañía | Los cuatro personajes existen desde el inicio, pero solo los rasgos de Baldomero y Pimentina son obligatorios; `cobra_por_callar` y `manos_largas` pasan a "Debería". | Reducir el riesgo de alcance sin perder la idea de "rasgo = regla". | **Aceptada**; esos dos rasgos pasan a Objetivo (F-07). |
| C-5 | §13 Comandos | `usar` y `huir` pasan a "Debería"; `descansar` se explicita como funcionalidad Debe (F-03). | Ajustar la lista de comandos a la prioridad real. | **Aceptada**; `usar` y `huir` pasan a Objetivo (F-15); además `pagar` y `elegir` entran como comandos Debe (D-20). |
| C-6 | §6 Economía frente a §13 Comandos | Consumo automático al pasar el día (el más viejo primero) y `comer/1` como "Podría". | Resolver una incoherencia entre secciones. | **Aceptada con cambios** (D-11, D-12): ración automática pero en el orden **fresco, curado, rancio**; `comer(Tipo)` es una ración extra voluntaria con el efecto del tipo, en Objetivo (F-36). |
| C-7 | §18 Decisiones pendientes | Versión 9.x, guardar/cargar fuera de la v1, exposición en vivo con semilla fija y plan B, contratos 6, enemigos ≥ 5 + jefe. | Cerrar las decisiones que bloquean el calendario. | **Aceptada en parte**: versión **5.10.4** en lugar de 9.x (D-02); guardar/cargar fuera de la v1 (D-32); exposición en vivo con semilla fija y plan B, pendiente de confirmar (D-36); contratos **4** (+2 en Objetivo); enemigos **5 tipos incluido el jefe** (+2 en Objetivo). |
| C-8 | §11.1 / §11.4 Meta-intérprete | El corte se trata como hoja que siempre triunfa y las explicaciones corresponden a la primera solución (`once/1`). | El boceto no cubre el corte y la IA enemiga lo usa. | **Rechazada** (D-06, X-04): corte real (02 §6.5), decidido con el spike del primer día. Solo si el spike falla se vuelve a esta propuesta como Plan B, excluyendo la IA de la equivalencia. |
| C-9 | §13 Interfaz de comandos | Añadir `demo` y una forma de fijar la semilla aleatoria. | Hacer reproducible la exposición. | **Aceptada** como meta-comandos de `main`; la semilla usa el generador congruencial propio (`fijar_semilla/1` en `estado`), no `random/1`. |
| C-10 | §16 Pruebas | Añadir la orden estándar de pruebas (`swipl -q -g run_tests -t halt tests/todas.pl`) y el agregador `tests/todas.pl`. | Un único comando verificable para la entrega. | **Aceptada con corrección** (D-31, X-08): agregador `tests/todas.pl`, pero la orden pasa a `swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl`, porque comprobado en 5.10.4 la forma original devuelve código 0 aunque fallen pruebas. |

---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 tras docs/06. Todo lo recortado sigue en el documento marcado como "extra" u "objetivo".

| # | Qué cambió | Dónde | Motivo |
|---|---|---|---|
| 1 | Nota inicial de revisión; dedicación fijada en 10 h/semana (62 h) y recorte Nivel A (65 h declaradas) con paso al Nivel B | Cabecera, 4.3 | D-01, X-50 |
| 2 | Versión de SWI-Prolog 5.10.4 en objetivos, DoD, exposición y checklist; ruta y alias; lista de funciones inexistentes con grep final | 1.1, 7.1, 9, 10, 14 | D-02, 06 §2.8 (O-1 a O-8), X-10 |
| 3 | Los comandos pasan a ser términos ejecutados por `juego:ejecutar/2`; criterios de aceptación reescritos "dado el comando … ejecutado" | 2 (F-03, F-04), 3 | D-03, X-02 |
| 4 | `estado.pl` único escritor de `assert/retract`; `actualizar_*` privados; efectos como datos con `aplicar_efectos/1` y `con_transaccion/1`; narrador puro con contadores en `estado` | F-02, F-24, 3, 7.1, 14 | D-04, D-05, D-25, X-01, X-03, X-06 |
| 5 | Corte real en `solve/2` con spike el primer día; equivalencia con todas las soluciones y mismo orden; Plan B del corte; `predicate_property(_, defined)` sustituido | F-18, 3, 8.1, 13 | D-06, X-04, O-2 |
| 6 | 12 módulos (`estado` y `juego` nuevos; `parser` en `juego`/`ui`, `arbol` en `explicar`) | F-04, 12.4, 11 | D-07 |
| 7 | Moral 0–10 con inicio 6 y huelga con moral ≤ 2; niveles de moral y modificador de ataque | F-10, F-11, 3 | D-08, X-24 |
| 8 | 12 cheddar iniciales y recompensas escaladas de 04 | 1.3, F-08, 3 | D-09, X-26, X-27 |
| 9 | El queso como única moneda: sin compra ni venta de queso y sin tienda en la v1; F-27 pasa a "Tienda de objetos" en Extra; consumibles por recompensa o botín | 1.3, F-08, F-15, F-27 | D-10, X-33, X-46 |
| 10 | Ración diaria automática en el orden fresco, curado, rancio; `comer(Tipo)` como ración extra en Objetivo (F-36) | F-09, F-36, 15 (C-6) | D-11, D-12, X-28, X-29 |
| 11 | Sueldos en unidades; `valor_queso/3` solo informativo; criterio de F-08 corregido ("la rancia vale como máximo lo que la fresca") | F-08, F-10, 3 | D-13, X-32, X-34 |
| 12 | `pagar` como comando explicable (`puede_pagar_sueldos/0`) con impago evaluado al salir (−2 moral); descansar cuesta 2 quesos y no hay `deuda_taberna` | F-03, F-10, 3 | D-14, D-15, X-30, X-31 |
| 13 | Huelga pasa de "Debería" a Debe, derivada solo de la moral | F-11, backlog T-14, 13.2 | D-22, X-25, X-48 |
| 14 | Caídos solo en combate (se levantan con 1 de vida), ids de derrota de 04, `derrota_hambre`; no se huye del jefe; 3 finales en la mínima | F-13, F-26, 3 | D-17, D-29, D-30, X-44, X-45 |
| 15 | Contratos con la forma de 02/04 (`resolucion/3`, `resultado/3`, `condicion_cumple/1`, `aplicar_efectos/1`), 4 en la mínima, máximo 3 activos, cobro automático; escolta de Clotilde con contador de golpes | F-12, 3, 1.3 | D-18, D-33, X-36, X-38, X-39 |
| 16 | `rasgo_no(teme_caballos)` se evalúa con la venda (`teme/2` consciente de `ignora_miedo/1`); sustituye a C-3 | F-06, F-12, F-20, 15 | D-19, X-37 |
| 17 | Nuevas funcionalidades F-35 (`elegir/1`) y F-36 (`comer`); comandos mínimos: 16 más `demo` | 2 | D-20, X-40 |
| 18 | Una habilidad por personaje con `habilidad(Objetivo)`; F-14 mínimo con 4 efectos sencillos | F-14, F-07 | D-23, X-43, X-47 |
| 19 | IA con las tres reglas del canon más tres acciones especiales y gemela sin corte; bestiario de 5 tipos incluido el jefe | F-16, F-17, 3 | D-24, X-42, X-49 |
| 20 | `explicar` hipotético y retrospectivo (`ultima_prueba/2`); `clave_de_diag/2` y las 6 claves del núcleo; ejemplo de la demo con `D = 9 (11 - 2)` | F-19, F-20, 3 | X-21, X-57, 02-C9 |
| 21 | Salida ASCII por defecto para los símbolos de árbol, UTF-8 para el texto, prueba de tildes en T-02 | F-19, 10.1, 13 | D-26, X-11, O-6 |
| 22 | Azar con el generador congruencial propio (sin `random_between/3` ni `random_member/2`); eventos aleatorios a Objetivo (5, sin duplicados) | F-25, F-33, 11 | D-28, X-09, X-52, O-1 |
| 23 | Guardar y cargar fuera de la v1 (Extra); `saves/` sin uso | F-29, 12.4 | D-32 |
| 24 | Orden de pruebas `swipl -q -g "run_tests,halt" -t "halt(1)" tests/todas.pl` (la forma anterior devolvía 0 con fallos, comprobado en 5.10.4); archivos de prueba renombrados | F-32, 8.1, 14, 15 (C-10) | D-31, X-08, V-04 |
| 25 | Catálogo reclasificado (Debe / Objetivo / Extra) con horas iguales a las del backlog; resumen: 62 h Debe + 3 h de reserva | 2 | D-21, 06 §5.1 |
| 26 | Backlog rehecho: T-01 a T-44 (62 h) + T-37 reserva; tareas de 06 §5.3 añadidas (efectos, `juego`, parser, `pagar`, `elegir`, `clave_de_diag`, Clotilde, finales); tablas Objetivo (≈ 18 h) y Extra | 6 | 06 §5.3, D-01 |
| 27 | Calendario: S0 no realizada y fusionada con S1 (12 h); horas por semana 12 / 10 / 10 / 10,5 / 10 / 9,5; acumulados y capacidad; regla de seguimiento y criterios de paso a Nivel B | 4 | D-01, X-05 |
| 28 | Honestidad de la carga: 65 declaradas frente a 62 disponibles, colchón real cero, Nivel B ≈ 57,5 h | 4.3, 13 | D-01, X-50 |
| 29 | Plan de recorte rehecho: Nivel 0, escalones B-1 a B-6 con horas y recortes de emergencia | 13.2 | D-01, 06 §5.2 |
| 30 | Exposición: tres demostraciones centrales (`por_que_no` de Baldomero, `por_que_no(aceptar(gallina_noble))`, `explicar` de un turno enemigo con corte); plan B y respuestas actualizados | 1.2, 10 | D-21, 06 §5.4 |
| 31 | Preguntas a la profesora reemplazadas por D-34 a D-38, a enviar antes del 6 de noviembre | 9, T-02 | D-34 a D-38 |
| 32 | Matriz de conceptos: corte real, generador congruencial, 12 módulos, `aggregate_all`, `estado.pl` como límite impuro | 11 | D-06, D-07, X-09 |
| 33 | Gestión del repositorio: 12 módulos en `src/`, nuevos archivos de prueba, etiquetas con fechas nuevas (`v0.1-diseno` el 6 nov) | 12 | D-07, D-31 |
| 34 | Métricas de duración 9–26 días y 15–60 minutos | 8.3 | X-51 |
| 35 | Cambios al canon C-1 a C-10 resueltos con su decisión | 15 | 06 §3 |
