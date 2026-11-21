# Ampliar el mundo: valoración (contratos, enemigos, encuentros, zonas, reinos y eventos únicos)

*Propuesta del autor (20 de noviembre de 2026): más contratos, más enemigos, encuentros al moverse por ciertas zonas, más zonas con más tabernas (para no tener que deshacer diez nodos para recuperarse), poder pasar a otro reino pagando peaje y eventos únicos en algunas zonas. Este documento mide **cuánto cuesta cada cosa en este código**, qué riesgos tiene y en qué orden convendría hacerlas. No se ha programado nada de esto todavía.*

## 0. Estado (20 de noviembre de 2026)

- **Hecho:** los **sucesos de zona** (§4), con cinco sucesos (bosque, aldea, Camino Real, castillo y cuevas), y **contratos y enemigos nuevos** (§3): el peaje del ganso, el fantasma charlatán y la paz del moho; el ganso del peaje y la seta belicosa. El jefe exige ahora dos contratos concretos (la escolta y el peaje). Etiqueta `v1.0-rc2` marcada antes de empezar como punto de vuelta atrás.
- **Pendiente:** encuentros al moverse (§5), el paquete D de niveles y experiencia (§10) y, si el autor lo decide el 27 de noviembre, el paquete C (§6).

## 1. Resumen

**Se puede meter todo, pero no a la vez y no con el mismo riesgo.** Las seis ideas se agrupan en tres paquetes:

| Paquete | Qué incluye | Esfuerzo | Riesgo para lo ya entregable |
|---|---|---|---|
| **A. Contenido** | contratos nuevos, enemigos nuevos, eventos únicos de zona | ~2 días | **bajo**: casi todo son datos y textos |
| **B. Peligro** | encuentros al moverse por ciertas zonas | ~1 día | **medio**: toca el viaje y el equilibrio |
| **C. Mundo** | más zonas, refugios (tabernas/posadas), otro reino con peaje | ~4 días | **alto**: la taberna única está en el corazón del juego |

Hoy es 20 de noviembre; la congelación del código propuesta es el **4 de diciembre** y la entrega el **11**. A + B caben con holgura. C cabe, pero **consume casi todo el margen** y compite con lo que el autor tiene pendiente (ensayar la exposición, grabar la demo, preguntar al profesor el formato). Recomendación en el §8.

## 2. Qué hay hoy y por qué sale barato o caro

- **Contenido como datos:** contratos (`contrato/5`), enemigos (`enemigo/4`), charlas (`presente/4`, `opcion_charla/5`), botín (`botin/3`), pagos (una fórmula que se calcula sola). Añadir una fila y sus textos funciona, y los validadores avisan si falta algo.
- **Azar con semilla ya resuelto:** el botín demostró cómo tirar dados de forma reproducible (una regla pura devuelve la semilla nueva y los efectos). Los encuentros usarían lo mismo.
- **Una sola taberna, escrita a fuego:** la palabra `taberna` aparece 54 veces en `src/` (en reglas de verdad: la fase se deriva de `en_zona(taberna)`, `descansar`, `pagar`, el tablón, el cobro y la penalización por salir sin pagar), 232 en las pruebas y 2 en la web. Es lo que encarece el paquete C.
- **Mapa dibujado a mano en la web:** las posiciones de las seis zonas están fijas en `app.js`. Con más zonas hay que mandarlas desde el servidor.
- **Simulador y validadores:** miden cualquier cambio de equilibrio y comprueban el contenido. Sin ellos, ampliar sería a ciegas.

## 3. Contratos y enemigos nuevos (paquete A)

**Qué cuesta un contrato:** una fila en `contrato/5`, sus resoluciones y consecuencias, quién lo ofrece y cuándo aparece, su dificultad y el texto del tablón. El **pago sale solo** de la fórmula (días de ruta y enemigos). **Qué cuesta un enemigo:** `enemigo/4` (vida, ataque, defensa, fila), su nombre y, si debe comportarse distinto, su regla de IA (hoy son seis reglas por prioridad).

- **Ritmo realista:** dos contratos y dos enemigos con sus pruebas, medio día.
- **Efecto colateral que hay que decidir:** el jefe se desbloquea con **tres contratos cumplidos**. Con más contratos ese umbral deja de ser «casi todos»: conviene subirlo o exigir contratos concretos.
- **Cosas que ya funcionan sin tocar código:** el objetivo actual, el diario, el simulador (el jugador con plan acepta lo que haya) y el pago.

## 4. Eventos únicos de zona (paquete A)

**Idea:** una escena con opciones que se abre **sola la primera vez** que llegas a una zona (o cuando se cumple una condición): el puente roto que solo Tuerca puede cruzar, la fuente de suero que cura por un precio, el altar del moho que cuenta un fragmento del diario.

- **Cómo:** es el motor de las charlas con otra puerta de entrada: `suceso(Zona, Escena, Condiciones)` en lugar de un personaje. Reutiliza las opciones por miembro, los efectos, el diario y las marcas de «ya visto».
- **Esfuerzo:** un día entre motor, pruebas y los primeros 4–6 sucesos.
- **Riesgo:** bajo. La única decisión: abrirse al llegar (se nota más) o con un comando (menos intrusivo).

## 5. Encuentros al moverse (paquete B)

**Idea:** algunas zonas tienen una probabilidad de que, al llegar, aparezca un grupo de enemigos antes del trayecto normal.

- **Cómo:** una tabla `encuentro(Zona, Probabilidad, Grupo)`; al llegar se tira un dado con la semilla del juego (como el botín) y, si sale, empieza un combate con las reglas de siempre. Es una regla pura: `explicar` puede decir **por qué** salió ese encuentro.
- **Esfuerzo:** un día con pruebas y ajuste.
- **Riesgos y decisiones:**
  - ¿Se puede **huir**? Hoy no hay huida (y el jefe no se puede evitar). Lo simple es no añadirla; entonces los encuentros son un coste real y las zonas peligrosas se notan.
  - Si un encuentro cae con el queso a cero, **cuenta como un día más de ayuno**: hay que probarlo.
  - **Combate con el contrato de la zona:** si llegas con un contrato de esa zona y además sale un encuentro, hay dos combates seguidos; se resuelve con orden fijo (primero el encuentro).
  - Equilibrio: el botín compensa algo, y el simulador mide el efecto en las victorias.

## 6. Más zonas, refugios y reinos con peaje (paquete C)

### 6.1 El problema de «diez nodos de ida y diez de vuelta»

Con un solo punto de descanso, un mapa grande castiga más de lo que entretiene. Hay tres soluciones y se pueden combinar:

1. **Refugios en el camino:** posadas donde descansar y pagar sueldos (no necesariamente con tablón de contratos).
2. **Acampar:** un comando que cura **menos** que una posada, cuesta un día y queso, y se puede usar en cualquier sitio (con riesgo de encuentro si hay encuentros). Es **mucho más barato de programar** que cambiar el mapa y resuelve lo que preocupa al autor.
3. **Mapa compacto:** en vez de una cadena de diez nodos, pocas zonas bien conectadas (un reino vecino de 4–5 zonas), así que «lejos» son 3–4 días y no 10.

### 6.2 Qué obliga a cambiar tener varios refugios

La `taberna` deja de ser un lugar y pasa a ser un **tipo de lugar**: una tabla `refugio(Zona)`, y reglas que hoy dicen `en_zona(taberna)` pasan a decir `en_refugio`. Hay que decidir y cambiar:

- **Descansar** y **pagar sueldos:** en cualquier refugio (decisión: ¿los sueldos se deben en todos o solo en la taberna de origen?).
- **Tablón y cobro de contratos:** ¿cada taberna tiene el suyo? ¿se cobra en cualquiera? (lo más simple: se cobra en cualquier refugio con tablón).
- **Pago de contratos:** hoy cuenta los días desde «la taberna»; pasaría a contarlos desde el refugio más cercano.
- **Web:** posiciones del mapa que manda el servidor.
- **Pruebas:** 232 menciones de `taberna`. La mayoría son mecánicas si **se conserva `taberna` como el id de la taberna de origen** y solo se generaliza la regla de fase (`en_refugio`).

### 6.3 Reinos y peaje

- **Datos:** `reino(Zona, Reino)` y un peaje por cruzar de un reino a otro (`frontera/3` o derivado de las conexiones).
- **Reglas:** `puede_viajar/1` pide además poder pagar el peaje; `por_que_no(ir(...))` lo explica; el viaje gasta el queso del peaje.
- **Lo que ya existe y se reutiliza:** el aviso de gasto antes de viajar y el riesgo de hambre ya admiten un coste extra (`riesgo_de_gasto(Coste, …)`); el **ganso recaudador** ya está en el juego; y la marca `recomendada_por_clotilde` (de la escolta) podría dar un descuento.
- **Contenido nuevo que arrastra:** cada zona nueva pide descripción, enemigos, dos personajes (con su grupo A y B si se quiere mantener la regla de las charlas), contratos y, si se quiere, un evento único. Es **la parte cara en texto**.
- **Esfuerzo:** de 4 a 5 días contando refugios, peaje, mapa de la web, pruebas, simulador y el contenido de un reino vecino pequeño.
- **Riesgo:** alto, por tocar el núcleo. Se mitiga marcando una etiqueta antes de empezar (`v1.0-rc2`), haciendo cada paso como un commit que pasa toda la verificación y teniendo una **fecha de decisión** (véase §8).

## 7. Qué se vuelve más difícil de exponer

La exposición es de **Programación Declarativa**: lo que luce es que el juego explica sus reglas (`explicar`, `por_que_no`), que el contenido son datos y que hay un solo escritor de estado. Ampliar lo refuerza si las piezas nuevas siguen el mismo patrón (datos + reglas puras + efectos como datos) y lo **debilita** si se hace deprisa y se rompe lo entregable. Por eso no se propone tocar la taberna única sin un plan de vuelta atrás.

## 8. Orden recomendado y calendario

| Fechas | Qué | Condición |
|---|---|---|
| hoy – 22 nov | etiqueta `v1.0-rc2`; **eventos únicos de zona** y **contratos y enemigos nuevos** (paquete A) | ninguna |
| 23 – 26 nov | **encuentros al moverse** (paquete B), ajustados con el simulador | el paquete A en verde |
| 27 nov | **decisión de ir/no ir con el paquete C** | el autor confirma y lo anterior pasa la verificación |
| 28 nov – 2 dic | paquete C **compacto**: `acampar`, un reino vecino de 4–5 zonas con una posada y un peaje | solo si se decidió ir |
| 3 – 4 dic | congelación del código; documentación, ensayo, demo | siempre |

**Recomendación:** hacer A y B seguro (valor alto, riesgo bajo); en C, empezar por **`acampar`** (resuelve el problema de recuperarse sin tocar el mapa) y dejar el reino con peaje como una ampliación **compacta y opcional**, con el 27 de noviembre como fecha de decisión. Si no se llega, el documento y el diseño quedan como trabajo futuro, que también cuenta.

## 9. Decisiones que necesito del autor

1. **Recuperarse lejos de la taberna:** ¿`acampar`, posadas, o las dos cosas?
2. **Encuentros:** ¿se puede huir de ellos o no?
3. **Peaje:** ¿una cantidad fija de queso por cruzar, o que dependa de algo (el contrato de Clotilde, un sello)?
4. **Tamaño del reino vecino:** ¿cuatro o cinco zonas o menos? (más zonas = más texto)
5. **Fecha de congelación:** ¿se mantiene el 4 de diciembre o se mueve?

## 10. Paquete D: niveles, experiencia y dificultad por zona (valoración)

*Propuesta del autor (20 de noviembre de 2026): enemigos con un nivel por zona, de modo que haya que subir de nivel a los personajes para aumentar sus cifras y ganar alguna habilidad (niveles 3, 5, 10, 15 y 20); más dificultad para fomentar el farmeo; y que en los eventos se gane experiencia, según quién resuelva y en qué intento, en lugar de queso.*

### 10.1 Qué hay hoy y qué obligaría a cambiar

- **Cifras fijas como datos:** `mundo:personaje/7` guarda vida, ataque y defensa de cada miembro. Se leen en **unos 10 puntos de `src/`** (daño, defensa, vida máxima, fichas de la API, estado inicial). Con niveles, esas lecturas pasan por reglas derivadas (`ataque_de/2`, `defensa_de/2`, `vida_maxima_de/2`) que suman el crecimiento del nivel.
- **Una habilidad por miembro:** `habilidad_de/2` es una por personaje, y el comando `habilidad` usa «la del que actúa». Con varias habilidades hace falta elegir cuál (`habilidad(Nombre, Objetivo)`) y cambiar los botones de la web.
- **Los enemigos son una tabla** (`enemigo/4`): el nivel de una zona pediría o una tabla de niveles por zona y un escalado de cifras al empezar el combate, o enemigos distintos por zona.
- **Experiencia:** hoy no existe. Los eventos ya saben **quién** resuelve (`Quien`) y **en qué intento** (`intentos_hechos/2`), así que la regla «más experiencia cuanto antes se resuelva» cabe en `eventos.pl`.
- **Pruebas:** hay más de 150 apariciones de daños y ataques concretos en las pruebas. **Regla de oro del diseño: el nivel 1 debe ser exactamente las cifras de hoy**; solo se crece a partir del 2. Así lo que ya está verificado sigue valiendo.

### 10.2 Cómo sería, en datos

| Pieza | Dato o regla |
|---|---|
| Crecimiento por rol | `crecimiento(Rol, vida(+V), ataque(+A), defensa(+D))`: cada nivel suma esto a las cifras base |
| Curva de experiencia | `xp_para(Nivel, XP)`, por ejemplo 20 × nivel (se ajusta con el simulador) |
| Nivel de las zonas | `nivel_de_zona(Zona, N)`: los enemigos de esa zona escalan; la web avisa del **nivel recomendado** |
| Habilidades | `habilidad_en(Id, Nivel, Habilidad)`: 2 por miembro (niveles 3 y 5) para empezar |
| Experiencia por evento | `xp_por_intento(Intentos, XP)`: más cuanto antes se resuelve; la gana **quien** lo resolvió |
| Efectos | `ganar_xp(Id, N)` y la subida de nivel como efectos que aplica `estado.pl` |

### 10.3 Lo que cuesta y lo que arriesga

- **Mínimo útil (niveles 1 a 5):** crecimiento por rol, experiencia por combate, contrato y evento, nivel de zona con aviso, **dos habilidades por miembro** (niveles 3 y 5), ficha y cabecera de la web, simulador con política de «farmeo» y pruebas. **De 5 a 7 días**, con riesgo alto porque toca el cálculo del combate.
- **Los niveles 10, 15 y 20** solo tienen sentido con **mucho más juego**: hoy una partida dura de 7 a 14 días y daría para llegar al nivel 4 o 5. Se pueden dejar **definidos en los datos y sin contenido** (la curva existe, las habilidades no), para que la ampliación futura solo añada filas.
- **El farmeo necesita dos cosas que hoy no hay:** combates que se puedan repetir (los **encuentros al moverse**, §5, que dan experiencia y botín) y una economía que lo aguante: cada día cuesta 4 quesos de ración, así que farmear solo compensa si el botín y los contratos lo pagan. Hay que medirlo con el simulador, igual que se hizo con los pagos y el ayuno.
- **Las habilidades nuevas son contenido caro:** cada una pide su efecto, su texto, su prueba y su botón. Con 4 miembros, 2 habilidades cada uno son 8.
- **Cuidado con el muro:** si la zona nueva pide un nivel que el jugador no puede alcanzar sin farmear días y días, la partida se vuelve un trámite. El **nivel recomendado visible** y una subida de nivel rápida al principio lo suavizan.

### 10.4 Recomendación

Hacer **D mínimo (niveles 1 a 5)** después de los encuentros (§5), que son su base. **No combinarlo con el paquete C en la misma quincena**: son los dos grandes y juntos sobrepasan el margen hasta el 4 de diciembre. Si hay que elegir uno, D da más «sensación de juego» y reutiliza lo ya hecho (datos, simulador, efectos); C da más tamaño pero también más texto y más riesgo. La decisión es del autor el **27 de noviembre**.

### 10.5 Decisiones que necesito del autor

1. **Experiencia compartida o individual:** ¿gana cada miembro por lo que hace (quien resuelve un evento, quien da el golpe final) o todos por igual? (lo que el autor describe es **individual**).
2. **Qué sustituye al queso:** en los eventos, ¿las opciones que hoy dan queso pasan a dar experiencia, o la dan además?
3. **Hasta qué nivel con contenido real:** ¿5 (propuesta) o más?
4. **Qué habilidades:** ¿las propongo yo (8, con su texto) para que las corrijas?
5. **Prioridad:** ¿D antes que C, C antes que D, o solo uno de los dos?
