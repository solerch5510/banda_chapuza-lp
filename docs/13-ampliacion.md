# Ampliar el mundo: valoración (contratos, enemigos, encuentros, zonas, reinos y eventos únicos)

*Propuesta del autor (20 de noviembre de 2026): más contratos, más enemigos, encuentros al moverse por ciertas zonas, más zonas con más tabernas (para no tener que deshacer diez nodos para recuperarse), poder pasar a otro reino pagando peaje y eventos únicos en algunas zonas. Este documento mide **cuánto cuesta cada cosa en este código**, qué riesgos tiene y en qué orden convendría hacerlas. No se ha programado nada de esto todavía.*

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
