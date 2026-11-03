# Banda Chapuza — Documento de diseño

> Repositorio: `banda_chapuza-lp` · Lenguaje: Prolog (**SWI-Prolog 5.10.4**, la versión del curso) · Proyecto final de Programación Declarativa
>
> Estado: **borrador v0.2** — es el diseño previo a la implementación; puede cambiar durante el desarrollo.
>
> **Revisado el 2 de noviembre de 2026 tras `docs/06-revision-y-decisiones.md`.** Este documento es el canon: incorpora las decisiones aceptadas por el autor (D-01 a D-33) y deja abiertas solo las preguntas a la profesora (D-34 a D-38). Los cambios concretos están en el "Registro de cambios de la revisión" del final. Los documentos de detalle son `01` (lore), `02` (arquitectura del código), `03` (funcionalidades y etapas), `04` (guion y contratos), `05` (comedia y narración) y `06` (revisión y decisiones), todos en `docs/`.

---

## 1. Resumen

**Banda Chapuza** es un RPG ligero de texto, por turnos, de gestión de una compañía de mercenarios de saldo. El jugador acepta contratos absurdos, administra **queso** (que es a la vez moneda y comida), paga sueldos, cuida la moral y pelea por turnos. El tono es comedia absurda ("goofy").

La inspiración de la estructura es la de los juegos de gestión de compañías de mercenarios (contratos, sueldos, comida, moral, combate táctico), pero a escala reducida y en clave de humor.

**Idea central del proyecto:** el juego entero es un programa lógico. El mundo son **hechos**, las reglas del juego son **cláusulas**, y un **meta-intérprete** permite preguntar *por qué* una acción funcionó o falló. Esa explicación (el árbol de derivación) se muestra con la voz de un narrador sarcástico.

## 2. Objetivos

1. Demostrar programación declarativa (lógica) aplicada a un problema con muchas reglas interdependientes.
2. Que el *modo explicar* sea una característica visible y propia del proyecto, no un añadido.
3. Que el juego sea jugable de principio a fin (un recorrido completo con jefe final) y divertido.
4. Que el código se pueda leer como una especificación: las reglas del juego deben parecerse a las reglas dichas en español.

### Fuera de alcance (versión 1)

- Interfaz gráfica o web.
- Mapa en cuadrícula con movimiento táctico (el combate es por filas).
- Multijugador, sonido, animaciones.
- Generación procedural del mundo.
- Tienda, guardar y cargar partida, reclutas y comandos en palabras (`ir bosque`): documentados como extra (ver 2.1).

### 2.1 Alcance por niveles

Hay una sola persona y entre 50 y 62 horas, así que el contenido se divide en tres niveles. **Mínima** es lo que se compromete para el 11 de diciembre; **objetivo** se hace solo si el colchón de la semana 5 sigue intacto el viernes 27 de noviembre; **extra** queda documentado como ampliación futura y no forma parte de la entrega. Detalle completo en `docs/06-revision-y-decisiones.md` (§5.1).

| Elemento | Mínima | Objetivo | Extra |
|---|---|---|---|
| Contratos | **4**: `ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real` | 6: + `peaje_del_ganso`, `fantasma_charlatan` | 9 más |
| Enemigos | **5**: `rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort` | 7 | 12 |
| Frases del narrador | ≈ **70** | ≈ 120 | todo el banco |
| Comandos | **16**: `ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir` | + `nivel`, `arbol`, `usar`, `huir`, `comer`, `demo` | `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar` |
| Finales | **3**: `chapuza`, `derrota_combate`, `derrota_hambre` | 5: + `leyenda`, `quiebra` | 7 |
| Rasgos con regla | 2 (`teme_caballos`, `hechizos_de_cocina`) | 4 | — |
| Habilidades | 4 (una por personaje) | 5 | 6 |

El tiempo por semana se supone de 10 h (nivel de recorte "A"); si un viernes el desvío acumulado supera las 3 h se pasa al nivel "B" (emergencia). El calendario y el backlog están en `docs/03-funcionalidades-y-etapas.md`.

## 3. Premisa y tono

En los **Reinos Quesudos** las guerras se deciden por quién tiene el mejor queso. Nadie quiere contratar a la Banda Chapuza, así que hereda los contratos que ningún mercenario serio acepta: escoltar a una gallina noble, rescatar a un gato de un árbol, convencer a un fantasma de que se vaya de una casa donde solo quiere charlar.

El humor sale de tres fuentes:

- **Contratos y enemigos ridículos** con consecuencias reales en las reglas.
- **Rasgos de personaje que se contradicen** (un caballero que le teme a los caballos).
- **El narrador**, que comenta con ironía cada explicación del sistema.

## 4. La compañía

Cuatro miembros iniciales (el jugador puede reclutar más en la taberna solo en la versión extra). Cada uno tiene atributos base (`vida`, `ataque`, `defensa`, `sueldo`), una fila preferida y un **rasgo** que modifica las reglas. Los sueldos suman 5 quesos por pago (1 + 2 + 1 + 1). Tuerca combate en la fila de frente, para equilibrar las filas.

| Personaje | Rol | Rasgo | Efecto en las reglas |
|---|---|---|---|
| Sir Baldomero | Caballero | `teme_caballos` | No puede atacar enemigos montados (salvo con la `venda_de_caballos`, que le quita el miedo); recibe daño extra de ellos. |
| Madame Pimentina | Maga | `hechizos_de_cocina` | Sus hechizos curan o dañan solo si hay queso en la despensa. |
| Rufino | Bardo | `cobra_por_callar` | Su habilidad sube la moral, pero pide un pago extra para dejar de cantar (estado `cantando`). |
| Tuerca | Ladrón | `manos_largas` | Puede conseguir queso extra, pero baja la moral si lo descubren. |

En la versión mínima solo `teme_caballos` y `hechizos_de_cocina` tienen su regla completa; los de Rufino y Tuerca se implementan en el nivel objetivo, y su habilidad mínima es sencilla (daño, daño con queso, +1 de moral, +1 de queso). Cada personaje tiene **una** habilidad en la v1 (el comando es `habilidad(Objetivo)`).

**Moral:** entero de **0 a 10** por personaje, con valor inicial **6**. Niveles (provisionales): alta ≥ 8, normal 4–7, baja 2–3, crítica 0–1, con un modificador de ataque de +1 / 0 / −1 / −2. Un personaje está en **huelga** cuando su moral es **≤ 2** (regla derivada solo de la moral, `parametro(moral_huelga, 2)`), y entonces no combate.

> Los nombres y rasgos son provisionales; lo importante es que cada rasgo sea **una regla** que cambie el comportamiento del juego.

## 5. Mundo

Seis zonas conectadas como grafo. La **taberna** es la base: ahí se descansa, se cobran y firman contratos, y se pagan los sueldos. En la taberna no se puede combatir (`\+ permite_combate(taberna)`).

```
                 [Castillo Camembert]
                         |
 [Taberna del Cuajo] -- [Camino Real] -- [Cuevas del Roquefort]
        |                     |
 [Aldea Requesón] ------ [Bosque del Moho]
```

| Zona | Función |
|---|---|
| Taberna del Cuajo Torcido | Base: descansar, contratos, sueldos. |
| Aldea Requesón | Contratos pequeños. |
| Bosque del Moho | Combates de nivel bajo, queso silvestre (en la versión mínima solo es zona de paso). |
| Camino Real | Escoltas y emboscadas. |
| Castillo Camembert | Contrato importante (el rey). |
| Cuevas del Roquefort | Jefe final. |

Moverse entre zonas **consume un día**, lo que activa la economía (comida, sueldos, maduración del queso). No hay tienda en la versión 1: el equipo se consigue como recompensa de contratos.

## 6. Economía del queso

**El queso es la única moneda**: no existe otra, y por eso **no se compra ni se vende queso**. Cada unidad tiene `tipo` y `edad` en días. La partida empieza con **12 quesos cheddar** de edad 0 (con cuatro miembros y cuatro quesos de ración al día, cinco apenas alcanzan para algo más de un día).

**De dónde entra y adónde sale** (regla única, todos los demás documentos se ajustan a ella):

| Entra | Sale |
|---|---|
| Recompensa de contratos | Ración diaria (un queso por miembro) |
| Botín de enemigos | Sueldos (`pagar`) |
| Hallazgos: `rebuscar_bolsillos` de Tuerca, forrajeo en el bosque, eventos | Descansar (2 quesos) |
| | Habilidades que gastan queso (los hechizos de Pimentina, entre otras) |
| | Multas y pérdidas por consecuencias de contratos y eventos (robo de las ratas, peajes) |

En la extra, una tienda vendería **objetos** (no queso) a cambio de queso.

- **Maduración:** por cada día, la edad aumenta. Entre ciertos días el queso vale más; pasado un umbral se vuelve **rancio**.
- **Ración diaria:** cada miembro de la compañía come una unidad por día, automáticamente y en este orden: **fresco → curado → rancio**, de modo que el rancio se acumula en la despensa (lo aprovechan los hechizos, el jefe y la regla del hedor). El rancio reduce la moral si se come. Si no hay para todos, baja la moral y la vida (pero la vida de nadie baja de 1 por hambre). `comer(Tipo)` es una ración **extra voluntaria** con el efecto del tipo (por ejemplo, cura 2); la ración diaria solo alimenta.
- **Sueldos:** en la taberna el jugador ejecuta `pagar` (comando); `puede_pagar_sueldos/0` es una regla que `por_que_no` puede explicar. Si se sale de la taberna con sueldos pendientes, la moral de cada miembro baja 2. La moral baja puede llevar a la **huelga** (el personaje no combate). El cobro de las recompensas de los contratos cumplidos, en cambio, es automático al llegar a la taberna.
- **Pago en unidades:** sueldos, recompensas, multas y descanso se cuentan en unidades de queso; al gastar queso se usa primero el más rancio. El valor por tipo y estado (`valor_queso/3`, curado = valor + 2) es solo informativo y servirá para los precios de la tienda extra.
- **Queso rancio:** vale poco como moneda y reduce la moral si se come, pero algunos enemigos y hechizos lo aprovechan.
- **Derrota por hambre:** al empezar el día, si `queso_total = 0` y no hay nada por cobrar, la partida termina (`derrota_hambre`).

Valores (provisionales): edad 0–2 = fresco, 3–9 = curado (valor máximo), 10 o más = rancio.

## 7. Contratos

Un contrato es un hecho con: identificador, zona, objetivo, recompensa y condiciones.

```prolog
contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo),
         recompensa([quesos(14), queso(brie, 0, 1)]),
         [requiere(rasgo_no(teme_caballos))]).
```

- **Aridad 5** fija. `recompensa(Lista)` admite `quesos(N)`, `queso(Tipo, Edad, N)`, `objeto(Id)` y `descansos_gratis(N)`; `recompensa(quesos(N))` queda como abreviatura. Las recompensas van de 4 a 18 quesos (salvo el contrato del jefe) para que la economía cierre.
- **Objetivos** con vocabulario cerrado (`eliminar`, `derrotar`, `escoltar`, `evento`, ...). Una tabla `via_objetivo/2` los traduce a las dos vías de resolución, combate o evento. La versión mínima solo implementa `eliminar`, `derrotar`, `evento` y `escoltar`.
- **Datos y reglas de apoyo:** `resolucion/3` (datos), `resultado/3` (regla: éxito, a medias o fracaso), `condicion_cumple/1` y `aplicar_efectos/1`.
- **Aceptar:** `aceptar/1` funciona en la taberna (tablón) o en la zona del oferente; como máximo hay 3 contratos activos.
- **Rasgo y venda:** `rasgo_no(teme_caballos)` se evalúa contra todos los miembros activos que no ignoren el miedo; con la `venda_de_caballos` equipada (`equipado/2`) Baldomero deja de bloquear el contrato.

Ciclo: **ver contratos → aceptar → viajar → cumplir objetivo (combate o evento) → cobrar en la taberna**.

Las condiciones y las consecuencias (éxito, fracaso, a medias) son reglas, así que el sistema puede explicar por qué un contrato **no se puede aceptar** o **salió mal**.

## 8. Combate

Por turnos, con **dos filas** (frente y retaguardia) en lugar de cuadrícula.

- **Orden:** por iniciativa (atributo o valor derivado).
- **Acciones:** `atacar`, `defender`, `habilidad` (mínima); `usar objeto` y `huir` (objetivo). No se puede huir del jefe.
- **Reglas de fila:** los de retaguardia solo pueden ser atacados cuando el frente cae, salvo ataques a distancia.
- **Daño base:** `max(1, Ataque - Defensa)`, más modificadores por rasgos, moral y estados. Las habilidades usan una tabla de datos `efecto_habilidad/2` (daño fijo, curación, etc.).
- **Caídos:** el estado `caido` solo existe dentro del combate; al terminar, los caídos se levantan con 1 de vida. La derrota en combate (`derrota_combate`) es que todos queden caídos.
- **IA enemiga:** reglas ordenadas por prioridad. El primer caso aplicable decide la acción. En la versión mínima son las tres reglas del esquema más, como máximo, tres acciones especiales (`robar_queso`, `embestir`, `invocar_moho`), cada una con su cláusula y su gemela.
- **Escolta:** en el contrato de la gallina, Clotilde se modela en la versión mínima con un contador de golpes recibidos; como combatiente aliado temporal solo si hay colchón.

```prolog
% Ejemplo de IA por prioridad (esquema)
accion_enemigo(E, curarse)   :- vida_baja(E), tiene(E, pocion), !.
accion_enemigo(E, atacar(O)) :- objetivo_mas_debil(E, O), !.
accion_enemigo(E, defender)  :- true.
```

> En el combate el corte se usa de forma deliberada en la IA enemiga (hay una orden de prioridad que se quiere preservar). Así se muestra el corte con un uso sano y se documenta su efecto en el árbol de derivación. Cada regla con corte tiene una **gemela sin corte** (`regla_ia/3`) que sirve de oráculo en las pruebas y de material de exposición sobre el corte rojo.

## 9. Modelo de datos

### 9.1 Hechos estáticos (el mundo)

```prolog
zona(taberna, 'Taberna del Cuajo Torcido').
conexion(taberna, aldea).
conexion(aldea, bosque).
rasgo(baldomero, teme_caballos).
enemigo(bandido_torpe, vida(12), ataque(5), defensa(2)).
```

### 9.2 Hechos dinámicos (el estado)

```prolog
:- dynamic en_zona/1, dia/1, vida/2, moral/2, queso/3, contrato_activo/1.

en_zona(taberna).
dia(1).
vida(baldomero, 30).
moral(baldomero, 6).
queso(cheddar, 0, 12).   % queso(Tipo, Edad, Cantidad)
```

El estado se modifica con `assert`/`retract`, y **solo `estado.pl` escribe**. Las reglas del resto de módulos no modifican nada: devuelven **efectos como datos** y `estado:aplicar_efectos/1` los aplica. Se usa un único vocabulario de efectos (`dano/2`, `curar/2`, `mod_moral/2`, `ganar_queso/3`, `gastar_queso/3`, `envejecer_quesos`, `contrato_cobrar/1`, `marcar/1`, `contar/2`, `ganar_descansos/1`, `equipar/2`). Los predicados `actualizar_*` son auxiliares privados de `estado`, que así es el único punto de control.

### 9.3 Reglas (el juego)

```prolog
puede_atacar(A, B) :-
    vivo(A), vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( teme(A, Clase), clase(B, Clase) ).

% El miedo de Baldomero tiene en cuenta la venda
teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A).
ignora_miedo(P)  :- equipado(P, venda_de_caballos).

% La huelga se deriva solo de la moral
esta_en_huelga(P) :-
    miembro(P), moral(P, M),
    parametro(moral_huelga, Max), M =< Max.

dano(A, B, D) :-
    ataque(A, Atq), defensa(B, Def),
    modificador(A, B, M),
    D is max(1, Atq - Def + M).
```

Los estados (`aturdido`, `cantando`, `apestado`) son derivados sobre el hecho `alterado(Id, Estado, Turnos)`.

### 9.4 Nombres canónicos

Para que todos los documentos y el código usen lo mismo:

| Concepto | Nombre |
|---|---|
| Viaje | `conexion/2` (datos), `adyacente/2`, `puede_viajar/1` (la meta que se explica) |
| Habilidad y huelga | `puede_habilidad/2`, `esta_en_huelga/1` |
| Combate permitido | `permite_combate/1` (zona), `puede_combatir/1` (personaje) |
| Pertenencia | `miembro/1` (membresía), `activo/1` (vivo), `en_pie/1` (activo y sin huelga) |
| Objetos | `lleva/3` (inventario), `equipado/2` (puesto) |
| Contratos | `contrato_cerrado/2`, `contrato_cumplido/1`, `contratos_cumplidos/1` |
| Queso | `categoria_queso/2`, `queso_total/1` |
| Efectos | `estado:aplicar_efectos/1` |

## 10. Arquitectura

```
banda_chapuza-lp/
├─ README.md
├─ docs/
│  ├─ DISENO.md            ← este documento (canon)
│  └─ 01 … 06              ← lore, código, funcionalidades, guion, comedia y revisión
├─ src/
│  ├─ main.pl              ← punto de entrada, bucle del juego y meta-comandos (demo)
│  ├─ juego.pl             ← orquestación: valida el comando (parser) y lo ejecuta con ejecutar/2
│  ├─ estado.pl            ← estado dinámico: único módulo que escribe (assert/retract) y aplica efectos
│  ├─ mundo.pl             ← zonas, conexiones, hechos estáticos
│  ├─ compania.pl          ← personajes, rasgos, moral
│  ├─ economia.pl          ← queso, comida, sueldos, maduración
│  ├─ contratos.pl         ← contratos y sus reglas
│  ├─ combate.pl           ← turnos, filas, daño, IA enemiga
│  ├─ eventos.pl           ← eventos cómicos
│  ├─ explicar.pl          ← meta-intérprete, árbol de derivación y modo explicar
│  ├─ narrador.pl          ← frases del narrador
│  └─ ui.pl                ← entrada y salida por consola
├─ tests/                  ← pruebas con plunit (tests/todas.pl las reúne)
└─ examples/               ← partidas y explicaciones de ejemplo
```

Son **12 módulos**: los 10 del diseño original más `estado` y `juego`. El parser de comandos vive en `juego`/`ui` y el árbol de derivación en `explicar`; solo se separan en módulos propios (`parser`, `arbol`, `frases`) si el archivo crece mucho.

Principios de diseño:

- **Toda la lógica en módulos puros** (reglas y consultas) y **la entrada/salida aislada en `ui.pl`**, para que el núcleo declarativo se pueda probar y explicar.
- **Un único escritor:** solo `estado.pl` usa `assert`/`retract`. Las reglas devuelven efectos como datos.
- **Los comandos son términos** (`ir(aldea)`), validados por el parser y ejecutados por `juego:ejecutar/2`, que devuelve `resultado(Items)` sin imprimir. Así el núcleo se prueba sin consola. La fase del juego (exploración, taberna, combate, fin) decide qué comandos son válidos.
- **El narrador es puro:** recibe como argumentos el día, la semilla y los contadores; los contadores de rotación de frases viven en `estado.pl`.
- **Azar reproducible:** generador congruencial propio (`S1 is (S0*75+74) mod 65537`) con la semilla en `estado`, para que la demo sea idéntica en cada ejecución. No se usa `random_between/3` ni `random_member/2` (no existen en 5.10.4).

## 11. Modo explicar (meta-intérprete)

Es la característica central. Las reglas del juego se pueden ejecutar de dos maneras: directamente (rápido) o a través del meta-intérprete (devuelve la prueba).

### 11.1 Meta-intérprete (esquema)

```prolog
solve(true, true) :- !.
solve((A, B), (PA, PB)) :- !, solve(A, PA), solve(B, PB).
solve(\+ G, no(G)) :- !, \+ solve(G, _).
solve(G, hoja(G)) :- \+ predicado_del_juego(G), !, call(G).
solve(G, hecho(G)) :- clause(G, true).
solve(G, regla(G, P)) :- clause(G, Body), Body \== true, solve(Body, P).
```

Una **hoja** del árbol es todo predicado que no pertenezca a los módulos del juego (`modulo_juego/1`): los aritméticos y de comparación (`is`, `\=`, `<`) y también `member/2` o `append/3`, que no son `built_in`. Un predicado del juego es el que está definido en uno de esos módulos (con `predicate_property(G, dynamic)` o `predicate_property(G, number_of_clauses(_))`; en 5.10.4 `predicate_property(_, defined)` no devuelve éxito). Se necesita que los predicados del juego sean accesibles a `clause/2`.

**El corte se implementa de verdad:** el cuerpo de la cláusula se parte en `Pre` y `Post` alrededor de un `!` real, de modo que `solve/2` poda las mismas alternativas que la ejecución directa, y la prueba lleva un marcador `corte`. Esto se comprueba con un *spike* la primera semana (dos módulos, un dinámico, `clause/2` sobre importados y un `!` real). Si falla, el plan B es partir el cuerpo en dos predicados auxiliares o tratar el corte como hoja y excluir `accion_enemigo/2` de la prueba de equivalencia, documentándolo.

### 11.2 Comandos

Los comandos son términos Prolog. `explicar` y `por_que_no` reciben una acción y la traducen a un objetivo con `objetivo_de_accion/2`.

| Comando | Qué hace | Nivel |
|---|---|---|
| `explicar(Accion)` | Muestra la prueba de por qué la acción funcionó (o, de forma hipotética, funcionaría), con los valores de las variables. Se apoya en `ultima_prueba/2` para explicar lo que acaba de ocurrir, como un turno enemigo. | mínima |
| `por_que_no(Accion)` | Muestra el primer subobjetivo que falló, y si fue por una negación, qué hecho la impidió. | mínima |
| `arbol(Accion)` | Muestra el árbol de derivación en texto, con unificadores. La exportación a Graphviz `.dot` es extra. | objetivo |
| `nivel(resumido)` / `nivel(detallado)` | Controla cuánto se expande el árbol. | objetivo |

**Demostraciones centrales de la exposición** (se mantienen en la versión mínima):

1. `por_que_no(atacar(baldomero, bandido_montado))`: el rasgo `teme_caballos` bloquea el ataque.
2. `por_que_no(aceptar(gallina_noble))`: el contrato exige `rasgo_no(teme_caballos)` y Baldomero no lleva la venda.
3. `explicar` sobre un **turno enemigo**: muestra qué regla de la IA se aplicó y qué efecto tuvo el corte.

### 11.3 Ejemplo de salida

La salida del juego usa **símbolos ASCII** para las marcas del árbol (`[ok]`, `[no]`, `|-`, `\-`); el texto va en UTF-8. Esto evita los símbolos Unicode, que SWI-Prolog 5.10.4 degrada con la codificación por defecto.

```
> explicar(atacar(baldomero, bandido_torpe))
[ok] puede_atacar(baldomero, bandido_torpe)
  |- vivo(baldomero)              [hecho]
  |- vivo(bandido_torpe)          [hecho]
  |- en_fila_alcanzable(...)      [regla] -> frente contra frente
  |- no aturdido(baldomero)       [negacion: no hay hecho aturdido]
  \- no (teme(baldomero, C), clase(bandido_torpe, C))   [negacion]
[ok] dano(baldomero, bandido_torpe, D)     D = 9   (11 - 2)

Narrador: "Sir Baldomero golpea al bandido. Fue la primera vez en una semana que no le temblaron las rodillas."
```

```
> por_que_no(atacar(baldomero, bandido_montado))
[no] puede_atacar(baldomero, bandido_montado)
  \- falla: \+ ( teme(baldomero, caballo), clase(bandido_montado, caballo) )
     porque teme(baldomero, caballo) y clase(bandido_montado, caballo) son ciertos
     (rasgo teme_caballos y sin venda_de_caballos).

Narrador: "Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines."
```

```
> explicar(turno_enemigo(bandido_torpe))
[ok] accion_enemigo(bandido_torpe, atacar(pimentina))      [regla 2 de 3]
  |- [no] regla 1 (curarse): vida_baja(bandido_torpe) falla
  |- objetivo_mas_debil(bandido_torpe, pimentina)           [regla]
  \- corte (!): descarta la regla 3 (defender), que tambien era aplicable
```

(El tercer ejemplo es un esquema del formato; la salida final puede variar.)

### 11.4 Cómo se obtiene `por_que_no`

Boceto: se recorre el cuerpo de las cláusulas aplicables y se devuelve el primer subobjetivo que no se puede demostrar.

```prolog
por_que_no(G, falla(G, Sub)) :-
    clause(G, Body),
    primer_fallo(Body, Sub).

primer_fallo((A, B), F) :-
    (   solve(A, _) -> primer_fallo(B, F)
    ;   primer_fallo(A, F) ).
primer_fallo(A, A) :- \+ A = (_,_), \+ solve(A, _).
```

> Es un boceto: habrá que resolver casos como varias cláusulas aplicables (mostrar todas o solo la más cercana), negaciones anidadas y el corte. La versión final produce un diagnóstico con un núcleo reducido (`sin_clausula`, `fallo`, `neg_viola`, `builtin_falso`, `tras`), y `narrador:clave_de_diag/2` lo traduce a las claves de frase (`falla(Meta)`, `impide(Hecho)`).

## 12. Narrador

El narrador es una capa de presentación que asocia **una frase por regla o hecho relevante**:

```prolog
frase(teme(baldomero, caballo), 'Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.').
```

Si una regla no tiene frase, se usa una genérica. Las frases no afectan la lógica: son solo texto, para que el humor se pueda ampliar sin tocar el núcleo.

- **Un único almacén de texto:** `frase/3` (estático, con niveles y claves `falla`, `impide`, `suceso` y `texto(...)`), que guarda también diálogos, consejos y finales. Para la versión mínima los textos pueden quedar en línea mientras el código no dependa de dónde estén.
- **Puro:** recibe día, semilla y contadores; la rotación de variantes usa el generador propio. Las condiciones de los gags se evalúan en `juego` y se pasan al narrador como candidatos.
- **Nombres:** el narrador normaliza las instancias `e(Tipo, N)` al tipo y añade el número solo si hay varias del mismo tipo.
- **Voz:** "tú" para el jugador y "vosotros" solo cuando habla del grupo.
- La versión mínima lleva unas 70 frases (las 32 del núcleo más viaje, combate básico, hambre, sueldos, inicio y fin).

## 13. Interfaz de comandos

Versión 1: el jugador escribe comandos como términos Prolog terminados en punto: `ir(bosque).`, `atacar(bandido).`.

Versión 2 (si hay tiempo): comandos en palabras (`ir bosque`) separando la línea en átomos y convirtiéndola en término. Un analizador con DCG sería una extensión opcional, **no vista en el curso**, así que no es requisito.

Comandos de la versión mínima (16): `ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir`.

Nivel objetivo: `nivel`, `arbol`, `usar`, `huir`, `comer`, `demo`. Extra: `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar`.

`elegir/1` resuelve las decisiones de los eventos; `pagar` reparte los sueldos en la taberna. `demo` reproduce la partida de la exposición con semilla fija. Guardar y cargar partida no entran en la versión 1.

## 14. Relación con el curso

| Tema del curso | Dónde aparece en el proyecto |
|---|---|
| Programación declarativa vs. imperativa; hechos y listas (Conf. 1) | Todo el modelo del mundo; listas para compañía, inventario y filas. |
| Cláusulas definidas y unificación (Conf. 2) | Reglas del juego; unificación en consultas y en el meta-intérprete. |
| Resolución SLD y árbol de derivación (Conf. 3) | Modo explicar y exportación del árbol. |
| Corte y negación (Conf. 4) | IA enemiga con prioridades; `\+` en reglas de rasgos; análisis del efecto del corte en el árbol. |
| Aritmética (Conf. 5) | Daño, sueldos, maduración del queso, generador de números pseudoaleatorios. |
| Metaprogramación y BD (Conf. 6) | Meta-intérprete, `clause/2`, `assert`/`retract` aislados en `estado`, `findall`/`setof`. |

El proyecto no usa Haskell ni la programación funcional (Conf. 7–9); se mantiene todo en el paradigma lógico.

## 15. Plan de trabajo

El calendario por semanas, el reparto de horas, el backlog de tareas y el plan de recorte están en [`docs/03-funcionalidades-y-etapas.md`](03-funcionalidades-y-etapas.md), que es el documento maestro del plan. Hitos de referencia: la partida mínima completa y el colchón de la semana 5 se evalúan el viernes 27 de noviembre; la semana 6 se dedica a pruebas, balance, documentación y preparación de la exposición.

Fecha de entrega final: **11 de diciembre de 2026**.

## 16. Pruebas

- Pruebas unitarias con **plunit** (disponible en 5.10.4): reglas de daño, maduración del queso, condiciones de contratos. Se reúnen en `tests/todas.pl`.
- Pruebas del meta-intérprete: que `solve/2` y la ejecución directa den **todas las mismas soluciones y en el mismo orden** sobre un conjunto de objetivos, con un oráculo con/sin corte para la IA enemiga.
- Una partida de ejemplo en `examples/` que sirva de demo para la exposición.

Orden de ejecución previsto: `swipl -q -g run_tests -t halt tests/todas` (rutas relativas sin la extensión `.pl`; falta comprobar el código de salida al fallar y al pasar).

## 17. Riesgos y mitigación

| Riesgo | Mitigación |
|---|---|
| El meta-intérprete se complica con corte, negación y predicados predefinidos. | Escribir las reglas del juego evitando el corte salvo en la IA enemiga; hojas definidas por `modulo_juego/1`; spike del corte la primera semana con plan B. |
| Árboles de explicación demasiado grandes. | Niveles `resumido` y `detallado`; mostrar solo ramas relevantes en `por_que_no`. |
| El alcance crece (más contratos, más personajes). | Versión mínima de la sección 2.1 y recorte por niveles (A y B); lo demás es extra. |
| Versión de SWI-Prolog: solo hay la 5.10.4 y le faltan funciones modernas. | Se desarrolla y entrega con 5.10.4 usando solo su subconjunto (sin `foldl/4`, `sum_list/2`, `random_between/3`, `split_string/4` ni cadenas con comillas dobles); documentado en el README. Falta confirmar con la profesora que la evaluación usa la misma versión (D-35). |
| Símbolos y tildes en la consola de Windows. | Marcas del árbol en ASCII; texto en UTF-8 con `set_stream(user_output, encoding(utf8))`; comprobar las tildes en la consola de la entrega la semana 1. |
| El humor se queda corto. | Separar frases del narrador de la lógica para poder iterarlas al final. |

## 18. Decisiones pendientes

Las decisiones de diseño D-01 a D-33 están resueltas (ver el registro de cambios). Siguen abiertas las **preguntas a la profesora**, que se envían antes del 6 de noviembre:

| ID | Pregunta |
|---|---|
| D-34 | ¿Qué se entrega el 11 de diciembre (código, informe o ambos; formato y extensión) y por qué medio? |
| D-35 | ¿La evaluación usa SWI-Prolog 5.10.4? ¿Se pueden usar módulos, `library(plunit)` y las bibliotecas `lists`, `apply` y `aggregate`? ¿Se permite `assert`/`retract` para el estado de la partida? |
| D-36 | ¿La exposición es en vivo, de cuánto tiempo, y se espera una presentación con diapositivas? (Previsión: en vivo con semilla fija y plan B grabado.) |
| D-37 | ¿Cuál es la fecha prevista de la exposición presencial y puede adelantarse? |
| D-38 | ¿Se valoran las funciones fuera de las conferencias 1–6 (`format/3`, `read_term/2`, `msort/2`, `assoc`)? |

Quedan además comprobaciones técnicas que pueden mover alguna decisión: el spike del corte (D-06; si falla, plan B), las tildes en la consola de Windows (D-26), el código de salida de la orden de pruebas (D-31) y el paso al nivel de recorte "B" si un viernes el desvío supera las 3 h (D-01).

---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 a partir de `docs/06-revision-y-decisiones.md` (las referencias D-nn son decisiones de su sección 4 y X-nn contradicciones de su sección 2).

| Sección | Cambio | Motivo |
|---|---|---|
| Cabecera, 17 | SWI-Prolog 5.10.4 como versión de desarrollo y entrega; restricciones de funciones; ruta fuera del PATH documentada en el README | D-02, X-10, tabla 2.8 |
| 2, 2.1 | Nueva sección de alcance por niveles (4 contratos, 5 enemigos, ≈ 70 frases, 16 comandos, 3 finales); fuera de alcance amplía tienda, guardar/cargar y reclutas | D-01, D-21, D-32, X-50 |
| 4 | Moral 0–10 con inicio 6 y huelga con moral ≤ 2; sueldos 1+2+1+1; Tuerca en el frente; una habilidad por personaje; la venda anula el miedo de Baldomero | D-08, D-23, D-19, X-24, X-25, X-37 |
| 5 | Aldea sin tienda; taberna sin combate | D-10, X-33, X-14 |
| 6 | 12 cheddar iniciales; queso como única moneda (entradas y salidas); ración fresco → curado → rancio; `comer` como ración extra; `pagar` como comando con impago al salir; descanso de 2 quesos; pago en unidades; `derrota_hambre` | D-09, D-10, D-11, D-12, D-13, D-14, D-15, D-17, X-26, X-28, X-29, X-30, X-31, X-32, X-33 |
| 7 | Recompensa de la gallina de 14 quesos y 1 brie (ajuste del 2 de noviembre; antes 12), de las ratas 9 y del gato 7; `escoltar/2`; forma de `contrato/5`; nombres de datos y reglas; máximo 3 contratos activos | D-18, X-27, X-36 |
| 8 | Caídos solo en combate; IA mínima con tres acciones especiales y gemelas; sin huida del jefe; Clotilde con contador; tabla `efecto_habilidad/2` | D-17, D-24, D-29, D-33, X-38, X-42, X-43, X-44, X-45 |
| 9 | Dinámico con moral y 12 cheddar; solo `estado` escribe y las reglas devuelven efectos; `teme/2`, `ignora_miedo/1` y `esta_en_huelga/1`; nueva tabla de nombres canónicos | D-04, D-05, D-16, X-01, X-03, X-12 a X-20, §2.7 |
| 10 | 12 módulos: se añaden `estado` y `juego`; parser en `juego`/`ui` y árbol en `explicar`; comandos como términos; narrador puro y azar reproducible | D-03, D-07, D-25, X-01, X-02, X-06, X-09 |
| 11 | Meta-intérprete con hojas por `modulo_juego/1`, corte real y spike; `predicate_property` sin `defined`; demostraciones centrales de la exposición; ejemplo 11.3 en ASCII y con `D = 9 (11 - 2)`; `clave_de_diag/2` | D-06, D-26, X-04, X-11, X-21, X-57, O-2, O-6 |
| 12 | Narrador puro, `frase/3` como único almacén, normalización de `e(Tipo, N)` y voz "tú"/"vosotros" | D-25, D-27, X-06, X-07, X-19, X-54 |
| 13 | Comandos por nivel (16 mínimos); `elegir/1` y `pagar`; guardar/cargar fuera de la v1 | D-20, D-32, X-40 |
| 15 | El cronograma antiguo se sustituye por una referencia a `docs/03-funcionalidades-y-etapas.md` | X-05 |
| 16 | Equivalencia con todas las soluciones y oráculo con/sin corte; `tests/todas.pl` | D-31, X-08 |
| 18 | Se mantienen solo las preguntas a la profesora (D-34 a D-38) y comprobaciones técnicas | D-34 a D-38 |
