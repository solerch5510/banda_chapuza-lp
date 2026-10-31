# Banda Chapuza — Documento de diseño

> Repositorio: `banda_chapuza-lp` · Lenguaje: Prolog (SWI-Prolog) · Proyecto final de Programación Declarativa
>
> Estado: **borrador v0.1** — es el diseño previo a la implementación; puede cambiar durante el desarrollo.

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

## 3. Premisa y tono

En los **Reinos Quesudos** las guerras se deciden por quién tiene el mejor queso. Nadie quiere contratar a la Banda Chapuza, así que hereda los contratos que ningún mercenario serio acepta: escoltar a una gallina noble, rescatar a un gato de un árbol, convencer a un fantasma de que se vaya de una casa donde solo quiere charlar.

El humor sale de tres fuentes:

- **Contratos y enemigos ridículos** con consecuencias reales en las reglas.
- **Rasgos de personaje que se contradicen** (un caballero que le teme a los caballos).
- **El narrador**, que comenta con ironía cada explicación del sistema.

## 4. La compañía

Cuatro miembros iniciales (el jugador puede reclutar más en la taberna si el tiempo lo permite). Cada uno tiene atributos base (`vida`, `ataque`, `defensa`, `sueldo`), una fila preferida y un **rasgo** que modifica las reglas.

| Personaje | Rol | Rasgo | Efecto en las reglas |
|---|---|---|---|
| Sir Baldomero | Caballero | `teme_caballos` | No puede atacar enemigos montados; recibe daño extra de ellos. |
| Madame Pimentina | Maga | `hechizos_de_cocina` | Sus hechizos curan o dañan solo si hay queso en la despensa. |
| Rufino | Bardo | `cobra_por_callar` | Su habilidad sube la moral, pero pide un pago extra para dejar de cantar. |
| Tuerca | Ladrón | `manos_largas` | Puede conseguir queso extra, pero baja la moral si lo descubren. |

> Los nombres y rasgos son provisionales; lo importante es que cada rasgo sea **una regla** que cambie el comportamiento del juego.

## 5. Mundo

Seis zonas conectadas como grafo. La **taberna** es la base: ahí se descansa, se cobran y firman contratos, y se pagan los sueldos.

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
| Aldea Requesón | Contratos pequeños y tienda. |
| Bosque del Moho | Combates de nivel bajo, queso silvestre. |
| Camino Real | Escoltas y emboscadas. |
| Castillo Camembert | Contrato importante (el rey). |
| Cuevas del Roquefort | Jefe final. |

Moverse entre zonas **consume un día**, lo que activa la economía (comida, sueldos, maduración del queso).

## 6. Economía del queso

El queso es moneda, comida y a veces arma. Cada unidad tiene `tipo` y `edad` en días.

- **Maduración:** por cada día, la edad aumenta. Entre ciertos días el queso vale más; pasado un umbral se vuelve **rancio**.
- **Comida:** cada miembro de la compañía come una unidad por día. Si falta, baja la moral y la vida.
- **Sueldos:** al llegar a la taberna se paga a cada personaje. Si no se paga, la moral cae y puede haber **huelga** (el personaje no combate).
- **Queso rancio:** vale poco como moneda y reduce la moral si se come, pero algunos enemigos y hechizos lo aprovechan.

Valores (provisionales): edad 0–2 = fresco, 3–9 = curado (valor máximo), 10 o más = rancio.

## 7. Contratos

Un contrato es un hecho con: identificador, zona, objetivo, recompensa y condiciones.

```prolog
contrato(gallina_noble, camino_real, escoltar(gallina_noble), recompensa(quesos(5)), [requiere(rasgo_no(teme_caballos))]).
```

Ciclo: **ver contratos → aceptar → viajar → cumplir objetivo (combate o evento) → cobrar en la taberna**.

Las condiciones y las consecuencias (éxito, fracaso, a medias) son reglas, así que el sistema puede explicar por qué un contrato **no se puede aceptar** o **salió mal**.

## 8. Combate

Por turnos, con **dos filas** (frente y retaguardia) en lugar de cuadrícula.

- **Orden:** por iniciativa (atributo o valor derivado).
- **Acciones:** `atacar`, `defender`, `habilidad`, `usar objeto`, `huir`.
- **Reglas de fila:** los de retaguardia solo pueden ser atacados cuando el frente cae, salvo ataques a distancia.
- **Daño base:** `max(1, Ataque - Defensa)`, más modificadores por rasgos, moral y estados.
- **IA enemiga:** reglas ordenadas por prioridad. El primer caso aplicable decide la acción.

```prolog
% Ejemplo de IA por prioridad (esquema)
accion_enemigo(E, curarse)   :- vida_baja(E), tiene(E, pocion), !.
accion_enemigo(E, atacar(O)) :- objetivo_mas_debil(E, O), !.
accion_enemigo(E, defender)  :- true.
```

> En el combate el corte se usa de forma deliberada en la IA enemiga (hay una orden de prioridad que se quiere preservar). Así se muestra el corte con un uso sano y se documenta su efecto en el árbol de derivación.

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
queso(cheddar, 0, 5).   % queso(Tipo, Edad, Cantidad)
```

El estado se modifica con `assert`/`retract`. Cada cambio pasa por predicados `actualizar_*` para que sea un único punto de control.

### 9.3 Reglas (el juego)

```prolog
puede_atacar(A, B) :-
    vivo(A), vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( teme(A, Clase), clase(B, Clase) ).

dano(A, B, D) :-
    ataque(A, Atq), defensa(B, Def),
    modificador(A, B, M),
    D is max(1, Atq - Def + M).
```

## 10. Arquitectura

```
banda_chapuza-lp/
├─ README.md
├─ docs/
│  └─ DISENO.md            ← este documento
├─ src/
│  ├─ main.pl              ← punto de entrada y bucle del juego
│  ├─ mundo.pl             ← zonas, conexiones, hechos estáticos
│  ├─ compania.pl          ← personajes, rasgos, moral
│  ├─ economia.pl          ← queso, comida, sueldos, maduración
│  ├─ contratos.pl         ← contratos y sus reglas
│  ├─ combate.pl           ← turnos, filas, daño, IA enemiga
│  ├─ eventos.pl           ← eventos cómicos aleatorios
│  ├─ explicar.pl          ← meta-intérprete y modo explicar
│  ├─ narrador.pl          ← frases del narrador
│  └─ ui.pl                ← entrada y salida por consola
├─ tests/                  ← pruebas con plunit
└─ examples/               ← partidas y explicaciones de ejemplo
```

Principio de diseño: **toda la lógica en módulos puros** (reglas y consultas) y **la entrada/salida aislada en `ui.pl`**, para que el núcleo declarativo se pueda probar y explicar.

## 11. Modo explicar (meta-intérprete)

Es la característica central. Las reglas del juego se pueden ejecutar de dos maneras: directamente (rápido) o a través del meta-intérprete (devuelve la prueba).

### 11.1 Meta-intérprete (esquema)

```prolog
solve(true, true) :- !.
solve((A, B), (PA, PB)) :- !, solve(A, PA), solve(B, PB).
solve(\+ G, no(G)) :- !, \+ solve(G, _).
solve(G, builtin(G)) :- predicate_property(G, built_in), !, call(G).
solve(G, hecho(G)) :- clause(G, true).
solve(G, regla(G, P)) :- clause(G, Body), Body \== true, solve(Body, P).
```

Los predicados predefinidos (`is`, `\=`, `<`, etc.) se tratan como hojas del árbol. Se necesita que los predicados del juego sean accesibles a `clause/2`.

### 11.2 Comandos

| Comando | Qué hace |
|---|---|
| `explicar(Accion)` | Muestra la prueba de por qué la acción funcionó, con los valores de las variables. |
| `por_que_no(Accion)` | Muestra el primer subobjetivo que falló, y si fue por una negación, qué hecho la impidió. |
| `arbol(Accion)` | Exporta el árbol de derivación (Graphviz `.dot` o texto) con unificadores. |
| `nivel(resumido ; detallado)` | Controla cuánto se expande el árbol. |

### 11.3 Ejemplo de salida

```
> explicar(atacar(baldomero, bandido))
✔ puede_atacar(baldomero, bandido)
  ├─ vivo(baldomero)              [hecho]
  ├─ vivo(bandido)                [hecho]
  ├─ en_fila_alcanzable(...)      [regla] → frente contra frente
  ├─ no aturdido(baldomero)       [negación: no hay hecho aturdido]
  └─ no (teme(baldomero, C), clase(bandido, C))   [negación]
✔ dano(baldomero, bandido, D)     D = 6   (11 − 5)

Narrador: "Sir Baldomero golpea al bandido. Fue la primera vez en una semana que no le temblaron las rodillas."
```

```
> por_que_no(atacar(baldomero, bandido_montado))
✘ puede_atacar(baldomero, bandido_montado)
  └─ falla: \+ ( teme(baldomero, caballo), clase(bandido_montado, caballo) )
     porque teme(baldomero, caballo) y clase(bandido_montado, caballo) son ciertos.

Narrador: "Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines."
```

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

> Es un boceto: habrá que resolver casos como varias cláusulas aplicables (mostrar todas o solo la más cercana), negaciones anidadas y el corte.

## 12. Narrador

El narrador es una capa de presentación que asocia **una frase por regla o hecho relevante**:

```prolog
frase(teme(baldomero, caballo), 'Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.').
```

Si una regla no tiene frase, se usa una genérica. Las frases no afectan la lógica: son solo texto, para que el humor se pueda ampliar sin tocar el núcleo.

## 13. Interfaz de comandos

Versión 1: el jugador escribe comandos como términos Prolog terminados en punto: `ir(bosque).`, `atacar(bandido).`.

Versión 2 (si hay tiempo): comandos en palabras (`ir bosque`) separando la línea en átomos y convirtiéndola en término. Un analizador con DCG sería una extensión opcional, **no vista en el curso**, así que no es requisito.

Comandos previstos: `ayuda`, `mirar`, `ir`, `contratos`, `aceptar`, `compania`, `inventario`, `comer`, `descansar`, `atacar`, `defender`, `habilidad`, `usar`, `huir`, `explicar`, `por_que_no`, `arbol`.

## 14. Relación con el curso

| Tema del curso | Dónde aparece en el proyecto |
|---|---|
| Programación declarativa vs. imperativa; hechos y listas (Conf. 1) | Todo el modelo del mundo; listas para compañía, inventario y filas. |
| Cláusulas definidas y unificación (Conf. 2) | Reglas del juego; unificación en consultas y en el meta-intérprete. |
| Resolución SLD y árbol de derivación (Conf. 3) | Modo explicar y exportación del árbol. |
| Corte y negación (Conf. 4) | IA enemiga con prioridades; `\+` en reglas de rasgos; análisis del efecto del corte en el árbol. |
| Aritmética (Conf. 5) | Daño, sueldos, maduración del queso. |
| Metaprogramación y BD (Conf. 6) | Meta-intérprete, `clause/2`, `assert`/`retract`, `findall`/`setof`. |

El proyecto no usa Haskell ni la programación funcional (Conf. 7–9); se mantiene todo en el paradigma lógico.

## 15. Plan de trabajo

| Semanas | Entregable |
|---|---|
| 1–2 | Mundo, movimiento por zonas, inventario, economía básica (día, comida) y meta-intérprete base con `explicar`. |
| 3–4 | Compañía y rasgos, combate por turnos con filas, IA enemiga. |
| 5 | Contratos, economía completa del queso, eventos cómicos, `por_que_no` y exportación del árbol. |
| 6 | Pruebas, balance, README, documentación y preparación de la exposición. |

Fecha de entrega final: **11 de diciembre**.

## 16. Pruebas

- Pruebas unitarias con **plunit**: reglas de daño, maduración del queso, condiciones de contratos.
- Pruebas del meta-intérprete: que `solve/2` y la ejecución directa den los mismos resultados sobre un conjunto de objetivos.
- Una partida de ejemplo en `examples/` que sirva de demo para la exposición.

## 17. Riesgos y mitigación

| Riesgo | Mitigación |
|---|---|
| El meta-intérprete se complica con corte, negación y predicados predefinidos. | Escribir las reglas del juego evitando el corte salvo en la IA enemiga; tratar los predefinidos como hojas. |
| Árboles de explicación demasiado grandes. | Niveles `resumido` y `detallado`; mostrar solo ramas relevantes en `por_que_no`. |
| El alcance crece (más contratos, más personajes). | Cerrar la versión mínima en la semana 4 y dejar el resto como extras. |
| Versión de SWI-Prolog distinta a la del curso (5.10.4). | Decidir la versión desde el inicio y documentarla en el README; evitar características muy recientes. |
| El humor se queda corto. | Separar frases del narrador de la lógica para poder iterarlas al final. |

## 18. Decisiones pendientes

- Versión exacta de SWI-Prolog a usar.
- Si el estado se guarda en disco (`guardar`/`cargar`) en la versión 1.
- Número final de contratos y enemigos.
- Si la exposición se hace con partida en vivo o con partida grabada y explicaciones preparadas.
