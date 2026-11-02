# Banda Chapuza — Comedia y narración planificada

> Documento de diseño 05 · Fase de diseño · Complementa a [DISENO.md](DISENO.md) (canon, §11 y §12), [01-lore-y-ambientacion.md](01-lore-y-ambientacion.md) y [03-funcionalidades-y-etapas.md](03-funcionalidades-y-etapas.md).
>
> Estado: **borrador v0.2** (revisado el 2 de noviembre de 2026; v0.1 del 31 de octubre de 2026). Los números (umbrales, probabilidades, enfriamientos) son **provisionales** y se ajustarán en el balance de la semana 6. El código Prolog de este documento es un **boceto**: salvo que se indique lo contrario, no se ha ejecutado; los bocetos del narrador puro (secciones 5.4 y 7.4) y del generador de eventos (sección 6.2) se probaron con ejemplos mínimos en SWI-Prolog 5.10.4 el 2 de noviembre de 2026.
>
> **Revisado el 2 de noviembre de 2026 tras docs/06: alineado con las decisiones aceptadas.** Cambios principales: narrador puro, sin estado propio ni azar (D-25); selección de variantes con contadores que viven en `estado` y generador congruencial de 02 (se eliminan `random_between/3` y `random_member/2`, que no existen en 5.10.4); claves de frases alineadas con el formato de diagnóstico de 02 mediante `clave_de_diag/2`; símbolos ASCII en la salida (D-26); un solo almacén `frase/3` (D-27); eventos aleatorios recortados (D-28); sin tienda ni compra de queso (D-10) y sin `deuda_taberna` (D-15); `comer` y `pagar` explicables (D-12, D-14); nombres canónicos de 06 §2.7 (D-16); finales de la versión mínima (D-30). El detalle está en la sección "Registro de cambios de la revisión", al final.
>
> **Alcance de cada frase, gag y evento.** Las tablas llevan la columna **Alc**: `M` = versión **mínima** (se compromete), `O` = **objetivo** (solo si el colchón de S5 sigue intacto el viernes 27 de noviembre), `X` = **extra** (se conserva en el documento como contenido ampliable; no forma parte de la entrega). El recuento por script está en la sección 7.7.

## Cómo leer este documento

- Las secciones 1 a 3 son **guía creativa**: la voz del narrador, las técnicas de humor y los chistes recurrentes.
- La sección 4 es el **banco de frases** (los datos). La 5, la 6 y la 7 son su **mecánica**: cómo se elige una variante, qué eventos ocurren y cómo se escribe cada hecho en Prolog.
- Las secciones 8 y 9 son la **guía de edición** y las prohibiciones.
- La sección 10 lista los **cambios propuestos al canon**. Nada del canon se ha cambiado en silencio.
- Los identificadores (`baldomero`, `puede_atacar`, `camino_real`…) siguen el índice de la sección 10 del lore y los **nombres canónicos de `06-revision-y-decisiones.md` §2.7** (`puede_viajar/1`, `esta_en_huelga/1`, `permite_combate/1`, `categoria_queso/2`, `lleva/3`, `activo/1`…), que a su vez cuadran con la API de `02-arquitectura-codigo.md` §3. Si alguno se renombra de nuevo, solo hay que renombrar la **clave** de las frases afectadas: la prueba de claves válidas (sección 7.6) lo detecta.
- El **narrador es puro** (D-25): no tiene estado propio ni usa azar. Recibe como argumentos el día y los contadores que guarda `estado`, y devuelve el texto y, como datos, los efectos que `estado` debe aplicar (secciones 5 y 7).

---

## 1. Voz del narrador

### 1.1 Quién es

El narrador **no es un personaje del mundo**: ningún habitante de los Reinos Quesudos lo oye, lo nombra ni le responde (coherente con el lore §8, donde el narrador "no es una ley sino un recurso"). Habla como un **escribano que levanta acta** de lo que ocurre: seco, exacto y con un afecto por la Banda que jamás confesaría.

Tres adjetivos que resumen la voz: **seco, exacto, afectuoso a su pesar**.

| Rasgo | Cómo se nota |
|---|---|
| Seco | Frases cortas, presente de indicativo, sin exclamaciones salvo una cada diez frases como mucho. |
| Exacto | Cita el dato concreto (el daño, la regla, el nombre completo) y de ahí saca el chiste. |
| Afectuoso a su pesar | Se burla de la Banda como se burla uno de su propia familia: nunca la abandona, nunca la humilla de verdad. |
| Pedante con humildad | Usa vocabulario de cancillería ("consta", "a efectos legales", "se hace constar") pero se equivoca de importancia: levanta acta de un calcetín y pasa por alto una explosión. |

### 1.2 Actitud y registro

- **Dirección del sarcasmo.** Apunta *hacia arriba* (leyes, nobles, reglamentos, la mala suerte, el propio narrador) o *hacia los lados* (la Banda, que se lo ha ganado con cariño). **Nunca hacia abajo, contra quien juega.** Un error del jugador no es motivo de burla; el error de Sir Baldomero, sí.
- **Persona gramatical.** Tercera persona para los personajes; segunda persona del singular (tú) para el jugador, como fija el lore §4. El jugador es "jefe o jefa": las frases **no usan adjetivos con género** sobre él ("Bienvenido" se escribe "Te damos la bienvenida"). **Vosotros** solo aparece cuando el narrador habla del grupo entero ("Lo habéis logrado", "Os retiráis"), nunca para dirigirse al jugador (06 X-54); al convertir las frases se revisa que cada una cumpla esto.
- **Léxico.** Cancillería ligera en una de cada tres frases; vocabulario de queso (maduración, corteza, cava, suero) en **una de cada tres**, no en todas. Dos juegos de palabras con queso seguidos son uno de más.
- **Tiempo.** Presente. Las explicaciones describen la prueba que se acaba de mostrar, no un pasado lejano.
- **Voces ajenas.** Un personaje solo habla mediante una cita breve entre «comillas angulares» dentro de la frase del narrador, como máximo una cita por frase.

### 1.3 Qué sabe y qué finge no saber

| Lo que sabe (y usa) | Lo que finge no saber (y de lo que se sirve) |
|---|---|
| Todo el estado de la partida: queso, edades, moral, deudas. | Por qué el mundo funciona así: "el reglamento ya venía así". |
| El árbol de la prueba: qué regla se cumplió, qué hecho lo impidió. | Quién redactó el reglamento y si tiene sentido. |
| Los secretos de los personajes (el bocadillo de queso de Baldomero, que Rufino no sabe leer música). | Que sabe esos secretos: los suelta con cuentagotas, uno por callback, y siempre "dicen que". |
| Cuánto falta para que pase algo (un queso a punto de volverse rancio). | El futuro lejano: no hace spoilers ni da consejos tácticos. |
| La opinión que merece cada decisión del jugador. | Tener opinión: "el narrador no opina, solo constata". |

### 1.4 Reglas de oro

**Siempre**

1. **Primero la verdad, luego la broma.** La frase nunca contradice ni oculta lo que acaba de mostrar el árbol; añade el *porqué humano* de la prueba, no la repite.
2. **Un chiste por frase, y el remate al final.** La palabra que hace gracia va en la última posición de la frase.
3. **El blanco del chiste es la situación, la regla o el personaje**, no el jugador.
4. **Respeta las leyes cómicas del mundo** (lore §8): una frase puede *citar* una ley, nunca *violarla*.
5. **Los datos vienen del estado.** Si la frase muestra una cifra, esa cifra entra como variable (`~w`); no se escribe a mano.
6. **Nombres visibles** del lore (Sir Baldomero, Madame Pimentina…), no ids.
7. **Variedad de estructura.** Dos frases seguidas no pueden tener la misma forma ("X, pero Y"; "Fulano hace Z. Nadie sabe…").
8. **Si hay duda entre dos chistes, el más corto.**

**Nunca**

1. Explicar el chiste ni comentar el comentario.
2. Dar consejos tácticos ni anticipar eventos ("deberías usar una poción").
3. Mencionar Prolog, código, errores internos ni romper la cuarta pared más allá de "acta", "reglamento" y "expediente".
4. Escribir cifras de balance en el texto: si el valor cambia en la semana 6, la frase no debe mentir.
5. Referirse al mundo real: marcas, famosos, obras, política, actualidad.
6. Insultar, ridiculizar o regañar al jugador, ni siquiera en los errores de comando.
7. Repetir la misma frase dos veces seguidas (la rotación por contador de la sección 5 lo garantiza si hay al menos dos variantes).
8. Usar más de una cita, un signo de exclamación o un juego de palabras por frase.

### 1.5 Medidas para una terminal de 80 columnas

La salida del narrador debe leerse de un vistazo en una terminal de 80 columnas. Las frases del banco se ajustan automáticamente (`ui.pl` parte la línea por palabras); lo que importa es el **tamaño**. Los símbolos del árbol de `explicar` (`[ok]`, `[no]`, `\-`, `|-`) son ASCII (D-26); el texto del narrador conserva tildes, `¿` y `«»` gracias a UTF-8 (sección 7.5).

| Elemento | Límite |
|---|---|
| Ancho de línea | 76 columnas útiles (80 menos margen). |
| Prefijo del comentario de `explicar` | `Narrador: "` (11 caracteres); las líneas siguientes llevan 10 espacios de sangría. Quedan **68 caracteres en la primera línea y 70 en las siguientes**. |
| **Frase del banco** | **≤ 135 caracteres** (dos líneas), contando cada `~w` de nombre como 20 caracteres y cada `~w` de cifra como 3. Ideal: 60 a 110. |
| Comentario de nodo (`detallado`, nivel `D`) | ≤ 100 caracteres, para no romper la forma del árbol. |
| Coletilla de gag (sección 3) | ≤ 70 caracteres (una línea). |
| Frases de eventos, inicio y fin (se imprimen sin prefijo) | ≤ 210 caracteres (tres líneas). |
| Oraciones por frase | Máximo dos; cada una, de 22 palabras como mucho. |
| Salida total del narrador por comando | Máximo cuatro líneas en `explicar`/`por_que_no`: la frase principal más, como mucho, una coletilla. |

> Un comentario de `explicar` es un **cierre**, no un párrafo: si hace falta un tercer renglón, sobra un chiste.

### 1.6 Ejemplo de buen y mal uso de la frase

Para `por_que_no(atacar(baldomero, bandido_montado))`, el árbol ya dice que falla `\+ (teme(baldomero, caballo), clase(bandido_montado, caballo))`.

| | Frase | Por qué |
|---|---|---|
| Mal | `Narrador: "Baldomero no puede atacar porque le tiene miedo a los caballos."` | Repite la salida técnica; no hay chiste. |
| Mal | `Narrador: "¡Qué cobarde es Baldomero, jajaja!"` | Se burla con crueldad, exclama y se ríe de su propio chiste. |
| Bien | `Narrador: "Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines."` | Añade el porqué humano (la infancia), usa un remate concreto (los calcetines) y no repite nada. |

---

## 2. Técnicas de humor para un juego de texto

En un juego de texto el humor se escribe en poco espacio y se repite muchas veces: por eso se prefieren técnicas que funcionan en **una frase** o que **crecen con el estado de la partida**. Cada técnica lleva ejemplos del propio juego; las claves entre paréntesis remiten a frases del banco (sección 4).

### 2.1 Regla de tres
Dos elementos que establecen el patrón y un tercero que lo rompe. Funciona en listas cortas.
- "Doña Mantecosa cobra el alojamiento, la cena y el aire que usaste para quejarte de ambos."
- "El Registro de Compañías anota la fecha, el nombre de la banda y, en tiza de otro color, la errata." (`T06`, variante)

### 2.2 Anticlímax
Construir solemnidad y deshincharla en la última palabra.
- "Sir Baldomero levanta la espada, invoca a siete generaciones de antepasados y golpea un poco a la izquierda."
- "El Moho Saltarín se deshace en esporas y en disculpas, por ese orden." (`C15e`)

### 2.3 Literalismo
Aplicar una regla o una frase hecha al pie de la letra, con consecuencias absurdas.
- Ley de la Huelga Sagrada: los monstruos respetan el piquete y esperan fuera. (`E15a`)
- "Cobrar en promesas es el insulto máximo." (el reglamento lo dice; el narrador lo cumple). (`E11b`, `E18`)

### 2.4 Escalada
Repetir un elemento subiendo la apuesta cada vez. Es la técnica base de los chistes recurrentes (sección 3): se implementa con el contador de usos (sección 5).
- Los caballos: respeto, tos urgente, voz fina, bocadillo. (`R01a` a `R01d`)

### 2.5 Callback
Volver a un chiste anterior cuando el estado lo permite. Premia al jugador que se fija y da coherencia al mundo.
- El puesto 47 de 47 del Registro de Compañías, citado al empezar, tras cada contrato y al terminar. (`I01a`, `R07`, `I05`)
- El bocadillo de queso de Baldomero, insinuado al tercer o cuarto caballo. (`F01d`)

### 2.6 Contraste solemne / ridículo
Registro grave para un asunto trivial (o al revés).
- "Sir Baldomero levanta la mano, muy despacio, por honestidad." (`F10b`)
- "Resumen: días de camino y quesos en la bolsa. Cifras modestas, historia notable." (`I04`)

### 2.7 Voz de acta (burocratización de lo cotidiano)
Tratar lo absurdo con lenguaje de expediente: "consta", "a efectos legales", "queda registrado". Es la voz natural del narrador.
- "Comprobado en acta: Sir Baldomero sigue en pie. En esta compañía, eso no es un trámite menor." (`X07`)
- "Daño mínimo garantizado por ley." (`X08e`)

### 2.8 Lista con remate
Enumerar cosas serias o neutras y rematar con una que no encaja.
- "En el cuaderno de Tuerca: un guante, un botón, una promesa y, por equivocación, la bolsa de la alcaldesa."
- "Los lunes, Rufino canta; los martes, cobra; los miércoles, deja de cantar para cobrar más."

### 2.9 Personificación de reglas y objetos
Dar voluntad a lo inanimado: la despensa, la regla, el mapa.
- "La despensa vacía devuelve el eco con intereses." (`E11a`)
- "Los mapas son tercos y Doña Mantecosa no vende atajos." (`F07b`)

### 2.10 Lítote (decir menos)
Quitar importancia a algo enorme, o dársela a algo mínimo.
- "No ha sido la mejor idea de la semana, pero la semana tampoco ha sido buena."
- "Un punto de daño. Apenas lo nota, pero el reglamento exige que cuente." (`X08d`)

### 2.11 Error de categoría
Aplicar el vocabulario de un campo a otro: personas como platos, rencores como quesos, batallas como guisos.
- "Un rencor de diez días ya está rancio. No se tira: se lanza." (conecta con la Ley del Hedor)
- "Pimentina cree que el combate está poco hecho." (`R05b`)

### 2.12 Falsa neutralidad del narrador
Declarar imparcialidad mientras se toma partido sin disimulo.
- "El narrador no opina. Solo constata que el bardo cobra por callar y que, económicamente, tiene razón."
- "Eustaquio acaba por fin su historia… Nadie recuerda cuándo empezó." (`K08`)

### 2.13 Qué técnica para cada situación

| Situación | Técnicas recomendadas | Evitar |
|---|---|---|
| `por_que_no` (fallo explicado) | Literalismo, contraste solemne/ridículo, voz de acta | Burla directa al jugador |
| `explicar` de combate | Anticlímax, lítote, escalada (coletillas) | Describir el daño con más gracia que el propio número |
| Economía (queso, hambre, sueldos) | Error de categoría, regla de tres, personificación | Chistes sobre hambre real: aquí es hambre de dibujos animados |
| Viaje y descanso | Descripción con remate, callback de Doña Mantecosa | Acumular adjetivos |
| Errores de comando | Falsa neutralidad, lítote | Reñir. El error se corrige con una sonrisa |
| Inicio y fin | Contraste solemne/ridículo, callback del Registro | Spoilers del jefe |

---

## 3. Chistes recurrentes y callbacks (running gags)

Doce chistes recurrentes. Cada uno se activa por una **condición sobre el estado** (una regla, no una probabilidad) y se manifiesta como una **coletilla**: una línea corta (≤ 70 caracteres) que se añade al final del comentario principal. Cada coletilla es una frase del banco con clave `gag(Id)`; sus textos están en la tabla 3.2. La escalada se hace con el contador de usos (sección 5, estrategia D), que vive en `estado`.

**Alcance (D-21, 06 §5.1).** Versión **mínima: 0 gags** (el narrador no necesita coletillas; `caballo` es el primero que pasa a mínima si sobra tiempo en S5). **Objetivo: 3** (`caballo`, `registro`, `silencio`). **Extra: los 12.** La columna **Alc** de la tabla 3.1 lo marca. Un gag solo sale si el personaje o el comando que lo dispara existe en la versión que se entrega (por ejemplo, `reposicion` depende de `huir`, que es del objetivo, y `pecorino` de un contrato extra).

### 3.1 Los doce gags

| Id (`gag/1`) | De qué va | Se activa cuando… | Escalada | Descanso tras agotar | Alc |
|---|---|---|---|---|---|
| `caballo` | Baldomero y su miedo específico a los caballos. | Una prueba o un suceso menciona `teme(baldomero, caballo)` o aparece un enemigo de clase `caballo` con Baldomero en la compañía. | 4 pasos: respeto, tos, voz fina, bocadillo. | 4 días; al volver empieza en el paso 2. | O |
| `casualidad` | Baldomero llama "pura casualidad" a todo, bueno o malo. | El último golpe de Baldomero fue flojo o fuerte (daño ≤ 2 o ≥ 8), o falló. | 3 pasos. | 3 días. | X |
| `silencio` | Rufino y el precio de su silencio. | Se ha pagado `silencio_pagado` al menos una vez, o Rufino está `cantando`. | 3 pasos: tarifa, subida, cotización. | 5 días. | O |
| `yo_no_he_sido` | Tuerca "encuentra" queso y jura su inocencia. | `rebuscar_bolsillos` tuvo éxito o ha ocurrido el evento `tuerca_encuentra`. | 3 pasos. | 5 días. | X |
| `sazon` | Pimentina trata cada batalla como un guiso. | Pimentina usa una habilidad (o ataca). | 3 pasos. | 3 días. | X |
| `cuenta` | Doña Mantecosa lo cobra todo. | El jugador entra en la taberna (llegada, descanso, pago de sueldos). | 3 pasos. | 3 días. | X |
| `registro` | El puesto 47 de 47 y la errata. | Se cumple un contrato, o es el día de inicio o el final. | Sin escalada: depende del puesto. | Ninguno. | O |
| `maduracion` | La Ley de la Maduración aplicada a todo (rencores, chistes, facturas). | Un queso cambia de estado (`madura/2`) o se muestra un queso curado o rancio. | 3 pasos. | 4 días. | X |
| `cansancio` | El narrador se cansa de que le pregunten. | Se han ejecutado tres o más `explicar`/`por_que_no` en el mismo día. | 3 pasos. | Hasta el día siguiente. | X |
| `gran_rancio` | La cuenta atrás del Gran Rancio. | `dia(D)` con D ≥ 6 y el contrato `despensa_real` sin cumplir. | 3 pasos. | 2 días. | X |
| `pecorino` | El Capitán Pecorino no os necesita (hasta que os necesita). | Hay un encuentro o evento con `capitan_pecorino`. | 3 pasos: orgullo, respeto a regañadientes, petición de ayuda. | 6 días. | X |
| `reposicion` | "Un caballero jamás huye: se reposiciona." | Se ha ejecutado `huir` con Baldomero en la compañía. | 3 pasos. | 3 días. | X |

### 3.2 Las coletillas (frases `R`)

Formato: `Id` · `Niv` (A = ambos niveles, D = solo `detallado`) · `Alc` (O = objetivo: solo los gags `caballo`, `silencio` y `registro`; X = extra; ninguna es de la mínima) · clave · texto. El orden de las filas de un mismo gag es el orden de la escalada. Las coletillas nunca aparecen en el nivel `resumido` de `explicar` (sección 3.4).

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| R01a | D | O | `gag(caballo)` | Sir Baldomero asegura que solo respeta a los caballos. De lejos. |
| R01b | D | O | idem | Sir Baldomero informa de que tiene una tos importante y urgente. |
| R01c | D | O | idem | Sir Baldomero pregunta con voz fina: «¿Eso tenía cuatro patas?» |
| R01d | D | O | idem | Dicen que un caballo de feria se comió su bocadillo de queso. |
| R02a | D | X | `gag(casualidad)` | Pura casualidad, aclara Sir Baldomero. |
| R02b | D | X | idem | Sir Baldomero repite que fue pura casualidad. Ya van varias. |
| R02c | D | X | idem | La casualidad de Sir Baldomero ya tiene estadísticas propias. |
| R03a | D | O | `gag(silencio)` | Rufino llama a su tarifa de silencio «precio de temporada». |
| R03b | D | O | idem | Rufino ha subido el precio del silencio. Dice que es por el público. |
| R03c | D | O | idem | A este ritmo, el silencio de Rufino cotizará más que el parmesano. |
| R04a | D | X | `gag(yo_no_he_sido)` | Tuerca asegura que él no ha sido. Nadie había dicho nada. |
| R04b | D | X | idem | Tuerca insiste: no ha estado, no ha sido y no tiene bolsillos. |
| R04c | D | X | idem | El cuaderno de Tuerca ya tiene una columna titulada «devolveré». |
| R05a | D | X | `gag(sazon)` | Pimentina opina que a esta batalla le falta sal. |
| R05b | D | X | idem | Pimentina cree que el combate está poco hecho. |
| R05c | D | X | idem | Pimentina califica el ambiente de «guiso sin fondo». |
| R06a | D | X | `gag(cuenta)` | Doña Mantecosa añade el aire a la cuenta. |
| R06b | D | X | idem | La cuenta de Doña Mantecosa ya incluye la sombra. |
| R06c | D | X | idem | Doña Mantecosa cobra ya intereses por los intereses. |
| R07a | D | O | `gag(registro(47))` | La Banda Chapuza sigue en el puesto 47 de 47. La errata, también. |
| R07b | D | O | `gag(registro(N))` | La Banda sube al puesto ~w de 47. La errata no sube con ella. |
| R07c | D | O | idem | Puesto ~w de 47. La errata se queda como mascota. |
| R08a | D | X | `gag(maduracion)` | Ley de la Maduración: también los rencores mejoran con el tiempo. |
| R08b | D | X | idem | Y pasado cierto punto, los chistes empeoran. Tenlo en cuenta. |
| R08c | D | X | idem | Todo madura: el queso, el rencor y la factura de Doña Mantecosa. |
| R09a | D | X | `gag(cansancio(N))` | El narrador solicita un día libre. Se lo denegarán. |
| R09b | D | X | idem | El narrador empieza a sospechar que le gusta que se lo pregunten. |
| R09c | D | X | idem | Pregunta número ~w de hoy. El narrador piensa en cambiar de oficio. |
| R10a | D | X | `gag(gran_rancio(D))` | Mientras tanto, el moho avanza. Ya van ~w días de Gran Rancio. |
| R10b | D | X | idem | La despensa del rey pierde otra loncha de valor. |
| R10c | D | X | idem | El Gran Rancio no espera. El rey, que ya huele a sótano, tampoco. |
| R11a | D | X | `gag(pecorino)` | El Capitán Pecorino asegura que no os necesita. Mira hacia otro lado. |
| R11b | D | X | idem | Pecorino reconoce vuestro mérito con la boca pequeña. Muy pequeña. |
| R11c | D | X | idem | Pecorino ya ha pedido ayuda. Con la boca pequeña, pero la ha pedido. |
| R12a | D | X | `gag(reposicion)` | Sir Baldomero aclara: un caballero jamás huye. Se reposiciona. |
| R12b | D | X | idem | Otro reposicionamiento táctico. El mapa empieza a sospechar. |
| R12c | D | X | idem | La Banda lleva más camino reposicionándose que luchando. |

Nota sobre el gag `registro`: los puestos del Registro son un extra del lore (§2.4) sin efecto en las reglas. **Durante la partida** el puesto se calcula como `47 - contratos_cumplidos` (mínimo 41) y solo se usa para el texto; **en el final**, el puesto que dice el texto del final (12, 31…) sustituye al cálculo (06 X-53).

### 3.3 Condiciones de activación (boceto sin ejecutar)

Las condiciones son reglas sobre el estado; no hay azar. **No viven en el narrador** (que es puro y no ve el estado): se evalúan en `juego`, que sí lo ve, y el resultado de `ejecutar/2` incluye la lista de candidatos (`gags(Candidatos)`, pares `Id-Clave`, por ejemplo `registro-gag(registro(44))`) para que `ui` se la pase a `narrador:coletilla/5` (06 X-06). Los hechos que leen (`ultimo_suceso/1`, `explicaciones_hoy/1`, el contador de silencios pagados) son de `estado` (06 X-22) y se describen en la sección 5.4.

```prolog
% juego.pl (boceto sin ejecutar). Nombres canonicos de 06 2.7.
gag_candidato(caballo)      :- ( ultimo_suceso(menciona(teme(baldomero, caballo)))
                               ; enemigo_presente(E), clase(E, caballo) ),
                               activo(baldomero).
gag_candidato(casualidad)   :- ultimo_golpe(baldomero, D), ( D =< 2 ; D >= 8 ).
gag_candidato(silencio)     :- ( contador(silencios_pagados, N), N >= 1
                               ; cantando(rufino) ).
gag_candidato(yo_no_he_sido):- ultimo_suceso(S),
                               ( S = rebuscar(_, ok) ; S = evento(tuerca_encuentra) ).
gag_candidato(sazon)        :- ultimo_suceso(habilidad(pimentina, _)).
gag_candidato(cuenta)       :- en_zona(taberna).
gag_candidato(registro)     :- ( ultimo_suceso(contrato_cumplido(_))
                               ; ultimo_suceso(inicio) ; ultimo_suceso(fin(_)) ).
gag_candidato(maduracion)   :- ultimo_suceso(madura(_, _)).
gag_candidato(cansancio)    :- explicaciones_hoy(N), N >= 3.
gag_candidato(gran_rancio)  :- dia(D), D >= 6, \+ contrato_cumplido(despensa_real).
gag_candidato(pecorino)     :- ultimo_suceso(encuentro(capitan_pecorino)).
gag_candidato(reposicion)   :- ultimo_suceso(huida(_)), activo(baldomero).
```

### 3.4 Reglas de dosificación

Un chiste recurrente repetido sin control deja de ser un chiste. Reglas **deterministas** (sin azar, para que la demo sea idéntica byte a byte; las coletillas no usan el generador de la sección 6):

1. **Una coletilla por salida, como máximo**, y solo en el nivel `detallado` de `explicar` y `por_que_no`, o al final de un suceso. El nivel `resumido` no lleva coletillas (para respetar el límite de 15 líneas del criterio de aceptación).
2. **Cadencia 1 de cada 2:** si la salida anterior llevó coletilla, esta no. (Excepción: `cansancio`, que reacciona a la propia pregunta.)
3. **Prioridad entre candidatos:** gana el gag que lleva más días sin salir; a igualdad, el primero de la tabla 3.1.
4. **Escalada con tope.** Cada aparición avanza un paso. Al agotar los pasos, el gag **descansa** (columna "Descanso") y al volver empieza en el paso 2, para no repetir la presentación. El paso y el día de vuelta los guarda `estado`; el narrador los recibe como argumento y devuelve los efectos que los actualizan (sección 5.4).
5. **Sin gags en los errores de comando** (excepto `cansancio` en las explicaciones). El error se corrige sin chistes recurrentes.
6. **Un gag que depende de un personaje no sale si ese personaje no está en la compañía** (por ejemplo, `silencio` sin Rufino).

---
## 4. Banco de frases listo para usar

### 4.0 Cómo leer las tablas

Cada fila es una frase del banco. Se convierte de forma mecánica en un hecho `frase/3` (sección 7).

| Columna | Significado |
|---|---|
| **Id** | Identificador de la fila (categoría + número + letra de variante). Sirve para citar la frase en pruebas y en este documento. Las filas con el mismo número y distinta letra son **variantes** de la misma situación y se alternan en ese orden (sección 5). |
| **Niv** | `A` = vale para los niveles `resumido` y `detallado`; `R` = solo `resumido`; `D` = solo `detallado` (comentarios de nodo). |
| **Alc** | Alcance (06 §5.1): `M` = versión **mínima**, `O` = **objetivo** (si hay holgura el 27 de noviembre), `X` = **extra** (se conserva, no se implementa). Las filas `M` son las que se convierten en hechos `frase/3` primero (sección 8.5); las `X` no se borran. |
| **Clave** | El término al que se asocia la frase (sección 7.2). `idem` repite la clave de la fila anterior. `_` es una variable que no se muestra. Las claves usan los nombres canónicos de 06 §2.7 y el formato de diagnóstico de 02 §6.9 (sección 7.4). |
| **Texto** | La frase. Cada `~w` se rellena, de izquierda a derecha, con las variables **con nombre** de la clave, en el orden en que aparecen en ella. Si el texto necesita menos `~w` que variables, sobran las últimas; si necesita saltarse una, la clave la escribe `_`. |

Convenciones de redacción:
- Los nombres de **enemigos, zonas, objetos y quesos** se muestran **con artículo** ("la Rata Quesera", "el Camino Real", "el cheddar"); los de **personajes y personas**, sin él ("Sir Baldomero", "Doña Mantecosa"). Por eso el texto escribe "golpea a ~w" y nunca pone el artículo delante del `~w`; la preposición se contrae sola ("a el" pasa a "al", "de el" a "del"; sección 7.5).
- Los nombres de los **contratos** los pone `ui.pl`; las frases de contrato (categoría K) hablan del contrato sin nombrarlo, salvo las específicas, que usan una clave propia.
- **Un solo almacén de texto (D-27).** Los textos visibles de 04 (diálogos, consejos, finales) y las descripciones de zona de 01 no se copian en este banco, pero se guardan **como hechos `frase/3`** con las claves `texto(dialogo(Npc, Tema))`, `texto(consejo(Id))`, `texto(final(Id))` y `texto(zona(Id))` (sección 7.2). Los datos de 04 y 01 conservan la lógica (quién, cuándo) y apuntan a la clave. Esa conversión puede esperar a la semana 4 y **no se cuenta** en las cifras de 7.7.
- Las variables de las claves usan una letra mayúscula: `A` atacante, `B` objetivo, `E` enemigo, `P` personaje, `Z` zona, `Q` tipo de queso, `O` objeto, `D` número (daño o día), `N` número, `T` total.
- Las frases de esta sección son las que aparecen en pantalla; los conceptos entre «comillas angulares» son citas de personajes.
- Total: **254 frases** en las secciones 4.1 a 4.11 (recuento por script en 7.7; contiene las 3 filas nuevas X21, F16 y F17 y no las 2 retiradas F08b y T02). Las coletillas de gags (3.2) y los textos de eventos (sección 6) se cuentan aparte; todas usan el mismo formato.

### 4.1 Explicaciones de éxito (`explicar`)

Comentarios al final de una prueba (marcada `[ok]` en el árbol de la salida). La clave es la meta que se ha demostrado. Las metas son las de la API de 02 §3 con los nombres canónicos de 06 §2.7; si el árbol trae un enemigo como instancia `e(Tipo, N)`, el narrador lo casa con la clave que lleva el átomo `Tipo` (sección 7.4).

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| X01a | A | M | `puede_atacar(baldomero, E)` | Sir Baldomero golpea a ~w. Fue la primera vez en una semana que no le temblaron las rodillas. |
| X01b | A | O | idem | No hay caballos a la vista, así que Sir Baldomero ataca a ~w con una valentía recién estrenada. |
| X01c | A | O | idem | Sir Baldomero ataca a ~w y asegura que fue pura casualidad. El acta dice que cumplía todas las reglas. |
| X02a | A | O | `puede_atacar(pimentina, E)` | Madame Pimentina apunta con el cucharón a ~w. Nadie sabe si es un ataque o una degustación. |
| X02b | A | O | idem | Pimentina ataca a ~w desde la retaguardia, con la dignidad de quien jamás se mancha el delantal. |
| X03 | A | X | `puede_atacar(rufino, E)` | Rufino golpea a ~w y lo apunta en el cuaderno: «para la balada». Lo de rimar vendrá luego. |
| X04 | A | X | `puede_atacar(tuerca, E)` | Tuerca ataca a ~w por el flanco. Nadie lo ve llegar, y tampoco lo ven irse, que es lo importante. |
| X05a | A | M | `puede_atacar(A, E)` | Regla cumplida: ~w puede atacar a ~w. A veces las cosas salen como manda el reglamento. |
| X05b | A | O | idem | Ataque autorizado: ~w contra ~w. El reglamento da su visto bueno; el resto, que se las arregle. |
| X06a | A | X | `en_fila_alcanzable(A, B)` | Frente contra frente: ~w y ~w quedan a la distancia justa para arrepentirse. |
| X06b | A | X | idem | Ni filas ni excusas: ~w alcanza a ~w y el reglamento no encuentra objeciones. |
| X07 | D | X | `vivo(X)` | Comprobado en acta: ~w sigue en pie. En esta compañía, eso no es un trámite menor. |
| X08a | A | M | `dano(A, B, D)` | ~w golpea a ~w y le quita ~w de vida. Cuentas claras, modales mejorables. |
| X08b | A | O | idem | ~w deja a ~w sin ~w puntos de vida. Es matemática, no rencor. |
| X08c | A | X | idem | Parte de daños firmado por ~w: ~w pierde ~w de vida y no presenta alegaciones. |
| X08d | A | O | `dano(_, B, 1)` | Daño mínimo: un punto. ~w apenas lo nota, pero el reglamento exige que cuente. |
| X08e | A | X | idem | La ley garantiza al menos 1 de daño, y ~w lo recibe con la emoción de una carta de la alcaldía. |
| X09 | D | X | `modificador(A, _, M)` | Ajuste al daño de ~w: ~w. El ánimo, como el queso, también cuenta. |
| X10 | D | X | `modificador(baldomero, _, 2)` | Frente a un jinete, Sir Baldomero sufre daño extra. El de orgullo se cuenta aparte. |
| X11 | A | O | `ignora_miedo(baldomero)` | La Venda de Caballos obra el milagro: si no ve caballos, no hay miedo. Lógica impecable, salud dudosa. |
| X12a | A | M | `puede_habilidad(pimentina, _)` | Hay queso en la despensa, así que hay magia. La Ley del Cuajo saluda a Madame Pimentina. |
| X12b | A | X | idem | Un hechizo sin queso es una ensalada triste. Hoy hay queso, y Pimentina cocina con fuego. |
| X12c | A | X | idem | Pimentina lanza el hechizo. El queso se consume; la dignidad, no. |
| X13 | D | X | `queso_total(N)` | La despensa cuenta ~w quesos, incluidos algunos de procedencia discutible. |
| X14a | A | O | `puede_habilidad(rufino, balada_inspiradora)` | Rufino canta y la moral sube. Que el grupo quiera que pare es materia de otra regla. |
| X14b | A | X | `puede_habilidad(rufino, silencio_pagado)` | Silencio comprado y entregado. Rufino calla con la profesionalidad de quien cobra por ello. |
| X14c | A | O | `puede_habilidad(tuerca, rebuscar_bolsillos)` | Tuerca rebusca en un bolsillo ajeno. Según el acta, había queso; según Tuerca, oportunidades. |
| X14d | A | O | `puede_habilidad(baldomero, carga_heroica)` | Carga heroica autorizada. Sir Baldomero embiste sin que nadie le empuje, que conste. |
| X15a | A | M | `puede_viajar(Z)` | Hay camino hasta ~w, y tan pegajoso que cuesta un día entero. Ley de la Ruta Pegajosa. |
| X15b | A | O | idem | Las zonas están conectadas, así que se puede ir a ~w. Que se pueda no significa que convenga. |
| X16 | A | M | idem | Pasa un día. Los quesos envejecen, los sueldos se acumulan y los problemas maduran solos. |
| X17a | A | M | `puede_aceptar(_)` | Cumples todos los requisitos del contrato. Lo difícil será cumplir el contrato. |
| X17b | A | O | idem | Contrato aceptable. Nadie dijo que fuera buena idea; solo que es legal. |
| X18 | A | M | `puede_descansar` | Las camas del Cuajo Torcido aceptan clientes. Han visto cosas y siguen aceptando. |
| X19 | A | M | `puede_pagar_sueldos` | Hay queso para todos los sueldos. Que conste en acta, por si alguien lo duda dentro de una semana. |
| X20a | A | O | `accion_enemigo(rata_quesera, robar_queso)` | La Rata Quesera roba queso: la prioridad uno de su lista y, de hecho, la única. |
| X20b | A | X | `accion_enemigo(bandido_torpe, atacar(_))` | El Bandido Torpe elige al más débil. Torpe, sí; tonto, solo a ratos. |
| X20c | A | X | `accion_enemigo(moho_saltarin, contaminar)` | El Moho Saltarín hace madurar tu mejor queso y pide perdón. Con esporas, pero lo pide. |
| X20d | A | X | `accion_enemigo(seta_chismosa, curar_aliado)` | La Seta Chismosa cura a su aliado mientras cuenta un secreto que nadie había pedido. |
| X20e | A | X | `accion_enemigo(ganso_recaudador, cobrar_peaje)` | El Ganso Recaudador extiende un recibo antes del picotazo. Con sello y todo. |
| X20f | A | X | `accion_enemigo(arquero_aburrido, apuntar(_))` | El Arquero Aburrido apunta al que menos vida tiene. Mira el reloj, pero apunta. |
| X20g | A | X | `accion_enemigo(bandido_montado, embestir)` | El caballo embiste primero. El bandido le sigue, por cortesía. |
| X20h | A | X | `accion_enemigo(guardia_de_corteza, defender)` | El Guardia de Corteza se defiende, tal como indica la página cuatro de su manual. |
| X20i | A | X | `accion_enemigo(gran_roquefort, invocar_moho)` | El Gran Roquefort llama a su moho sin prisa. Lleva cuarenta años practicando la calma. |
| X20j | A | M | `accion_enemigo(_, curarse)` | El primer caso de la lista que aplica es curarse, y la regla no mira más. Eso se llama prioridad. |
| X20k | D | X | `accion_enemigo(_, _)` | Decide el primer caso que aplica; los demás esperan turno, como en la cola de Doña Mantecosa. |
| X21 | A | O | `puede_comer(P, Q)` | ~w puede comer ~w. Hay existencias y el reglamento no pone pegas. La ración diaria va aparte. |

Notas de la tabla 4.1:
- **Enemigos (06 X-19).** Las claves `X20*` usan el tipo (`rata_quesera`), pero el árbol trae instancias `e(rata_quesera, 1)`: el narrador las casa con la clave del tipo y, al mostrar el nombre, añade el número solo si hay varias instancias del mismo tipo ("el Bandido Torpe (2)"; sección 7.5). La clave del jefe, `accion_enemigo(gran_roquefort, invocar_moho)`, se casa igual; la guarda `instancia(E, gran_roquefort)` pertenece a la regla de la IA, no a la frase.
- **`avanzar_dia` ya no es una regla explicable** (06 X-20): el paso del día es un efecto, no una meta. La frase `X16` pasa a ser la tercera variante de `puede_viajar(Z)`.
- **`comer` y `pagar` son explicables** (06 D-12, D-14): `X21` y `F17` explican `puede_comer/2`; `X19`, `E18` y `E13` explican `puede_pagar_sueldos/0` y el comando `pagar`.
- **Pertenencia.** Donde 05 decía "en la compañía y vivo", ahora la meta es `activo/1`; "en pie" (activo y sin huelga) es `en_pie/1` (06 X-17).

### 4.2 Explicaciones de fallo (`por_que_no`)

La clave es `impide(Hecho)` si una negación `\+` falla porque se cumple `Hecho`, o `falla(Meta)` si un subobjetivo positivo no se puede demostrar. Estas frases responden "¿por qué no?" por **regla** y por **rasgo**.

**Correspondencia con el diagnóstico de 02 §6.9 (06 X-21).** El diagnóstico no habla de `impide` ni de `falla`, sino de `neg_viola(G, Prueba)`, `fallo(G, Candidatas)`, `tras(Prueba, Diag)`, `sin_clausula(G)` y `builtin_falso(G)`. El traductor `clave_de_diag/2` (sección 7.4) convierte cada diagnóstico en una lista de claves candidatas, de la causa más profunda a la raíz: de `neg_viola(_, Prueba)` salen `impide(H)` para cada hecho `H` de la prueba (en preorden, para que gane el más cercano a la causa), y de `fallo/2` y `sin_clausula/1` salen `falla(Meta)`. Por eso las claves de abajo nombran el **hecho que aparece en la prueba**, no la condición del contrato: la regla `rasgo_no(R)` se define como `\+ (activo(M), rasgo(M, R), \+ ignora_miedo(M))`, así que lo que impide es `rasgo(baldomero, teme_caballos)` (F10b), y el ataque falla por `teme(baldomero, caballo)` (F01).

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| F01a | A | M | `impide(teme(baldomero, caballo))` | Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines. |
| F01b | A | O | idem | Un caballo. Sir Baldomero dice que es una cuestión táctica; sus rodillas, que es una cuestión de rodillas. |
| F01c | A | O | idem | Ley del Pánico Específico: Sir Baldomero teme exactamente una cosa, y acaba de entrar en escena. |
| F01d | A | X | idem | El caballo le mira a los ojos. Sir Baldomero recuerda un bocadillo de queso y prefiere no hablar del tema. |
| F02a | A | O | `impide(esta_en_huelga(baldomero))` | Sir Baldomero está en huelga: el honor es innegociable, pero el ánimo también. |
| F02b | A | O | `impide(esta_en_huelga(pimentina))` | Madame Pimentina está en huelga. Dice que los fogones sin ánimo se quedan fríos. |
| F02c | A | X | `impide(esta_en_huelga(rufino))` | Rufino está en huelga y, por una vez, el silencio sale gratis. Aprovéchalo. |
| F02d | A | X | `impide(esta_en_huelga(tuerca))` | Tuerca está en huelga. Podría tomar prestado un poco de ánimo, pero un piquete es un piquete. |
| F02e | A | M | `impide(esta_en_huelga(P))` | Con la moral por los suelos nadie combate, y la de ~w anda en el sótano. Ley de la Huelga Sagrada. |
| F03a | A | M | `impide(aturdido(P))` | A ~w le dan vueltas la sala, el reglamento y el desayuno. Que ataque otro día. |
| F03b | A | X | idem | Aturdimiento en curso: ~w mira a todos con cara de tutorial. Hay que esperar. |
| F04 | A | X | `falla(vivo(X))` | Para atacar hay que seguir en pie, y ~w ha decidido tumbarse a reflexionar sobre sus decisiones. |
| F05a | A | M | `falla(en_fila_alcanzable(A, B))` | La retaguardia queda tras el frente: ~w no llega hasta ~w mientras alguien siga delante. |
| F05b | A | O | idem | La retaguardia espera su turno detrás. ~w no alcanza a ~w: las filas se toman muy en serio. |
| F06a | A | M | `falla(puede_habilidad(pimentina, _))` | Sin queso no hay hechizo. Madame Pimentina agita el cucharón y la despensa vacía le devuelve el eco. |
| F06b | A | O | idem | Ley del Cuajo: toda magia necesita queso. La despensa lo ha leído y ha decidido no colaborar. |
| F06c | A | X | idem | Pimentina murmura la fórmula, remueve el aire y no pasa nada. El aire, por lo visto, no es queso. |
| F07a | A | M | `falla(puede_viajar(Z))` | No hay camino de aquí a ~w. Hay un campo, un arroyo y una filosofía, pero camino, no. |
| F07b | A | O | idem | Entre aquí y ~w no hay conexión. Los mapas son tercos y Doña Mantecosa no vende atajos. |
| F07c | A | X | idem | Quieres ir a ~w, pero entre medias hay un mapa con opiniones propias. |
| F08a | A | M | `falla(puede_descansar)` | Aquí fuera no hay camas, solo suelo con ganas de serlo. Descansar se hace en la taberna. |
| F09a | A | M | `falla(permite_combate(taberna))` | Dentro del local no se pelea: se discute. Doña Mantecosa lleva la cuenta de ambas cosas. |
| F09b | A | O | idem | Sacar el arma en el Cuajo Torcido está penado con multa, y la multa se paga en queso. |
| F10a | A | M | `falla(puede_aceptar(_))` | Este contrato no se puede aceptar todavía. Los requisitos están a la vista, como una factura. |
| F10b | A | M | `impide(rasgo(baldomero, teme_caballos))` | Lady Clotilde exige escolta sin miedo a los caballos. Sir Baldomero levanta la mano, muy despacio, por honestidad. |
| F10c | A | X | `falla(requiere(objeto(llave_mohosa)))` | Para el contrato del rey hace falta la Llave Mohosa. La puerta de las Cuevas no acepta promesas de cobro. |
| F10d | A | X | `falla(requiere(contratos_cumplidos_min(N)))` | El rey pide ~w contratos cumplidos antes de fiarse. Con la Banda, hasta la fe necesita referencias. |
| F10e | A | X | `impide(contrato_activo(_))` | Ese contrato ya está firmado. La Ley del Contrato Escrito no admite doble firma ni por cariño. |
| F11 | A | X | `falla(lleva_queso(E))` | Tuerca rebusca en ~w y solo encuentra decepción. No todos los enemigos llevan queso; algunos solo llevan prisa. |
| F12 | A | X | `impide(cantando(rufino))` | Rufino ya está cantando y no parará de balde. El silencio cuesta un queso; la dignidad, más. |
| F13 | A | X | `falla(puede_habilidad(rufino, silencio_pagado))` | Rufino callaría por un queso, pero la despensa está vacía. Esta vez tendrá que cantar gratis. |
| F14 | A | X | `falla(lleva(compania, O, _))` | Buscas ~w en la mochila y encuentras migas. Las migas no curan. |
| F15 | A | X | `falla(en_zona(taberna))` | Eso solo se hace en la taberna, con techo, recibo y la mirada de Doña Mantecosa. |
| F16 | A | O | `falla(hay_queso_para(descanso))` | Descansar se paga en queso, y la despensa no llega. Las camas aceptan queso, no promesas. |
| F17 | A | O | `falla(puede_comer(P, Q))` | ~w busca ~w en la despensa y solo halla el hueco. Comer lo que no hay no figura en el reglamento. |

Notas de la tabla 4.2:
- **Descansar sin deuda (06 D-15, X-31).** Descansar cuesta queso (la cifra la fija 04) y, si no lo hay, falla `puede_descansar` por `hay_queso_para(descanso)`: lo explica `F16`. La frase `F08b` (deuda con Doña Mantecosa) **se retira**, porque `deuda_taberna/1` no existe en ningún documento ni se implementa.
- **Huelga en `atacar` (06 X-48).** `F02` supone que la meta de `atacar` incluye `puede_combatir(A)` (vivo y sin huelga, 02 §3.3), y por eso el diagnóstico llega a `esta_en_huelga(A)`; si 02 deja la huelga fuera de `puede_atacar/2`, la meta explicada de `atacar` debe seguir incluyéndola.
- **Objetos.** `lleva(compania, O, N)` es el inventario común (06 X-16); `equipado/2` es lo que lleva puesto un personaje, y `ignora_miedo(P) :- equipado(P, venda_de_caballos)`.
- **`F10c`** solo se activa en la variante dura de `despensa_real` (extra, 06 X-41); la versión normal solo exige contratos cumplidos (`F10d`).
- **Condiciones de contrato.** El traductor prueba `falla(condicion_cumple(C))` y, a continuación, `falla(C)`, de modo que `F10c` y `F10d` casan aunque el diagnóstico traiga la envoltura `condicion_cumple/1` (sección 7.4).

### 4.3 Combate

Sucesos del combate (no son pruebas del meta-intérprete: `juego:ejecutar/2` los devuelve como `msg(Clave, Args)` y `ui` los narra con la clave `suceso(...)`; la lógica no imprime ni llama al narrador). Reglas de alcance: **no se puede huir del jefe** (06 D-29), así que `C18` solo se produce ante enemigos normales; el estado `caido` existe solo dentro del combate y al terminar se levantan con 1 de vida (06 X-44), por lo que `C16` no anuncia derrotas de partida. El canon no tiene fallos aleatorios ni críticos: la **calidad del golpe** es una clasificación de presentación del daño ya calculado (`calidad_golpe/2`, sección 10): `flojo` si el daño es 2 o menos, `fuerte` si es 8 o más, `normal` en el resto (umbrales provisionales). El "fallo" es una acción que no produce efecto (`sin_efecto`).

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| C01a | A | M | `suceso(inicio_combate)` | Comienza el combate. Las armas se desenvainan, los nervios se desenrollan y alguien pregunta quién tenía el plan. |
| C01b | A | X | idem | Empieza la pelea. Por un momento todos recuerdan que se apuntaron a esto por dinero. |
| C01c | A | X | idem | Combate. Se acabó la teoría; ahora viene la parte en que las cosas se rompen. |
| C02a | A | M | `suceso(aparece(E))` | Aparece ~w. Ninguno de los dos esperaba compañía. |
| C02b | A | X | idem | ~w te corta el paso con la seguridad de quien no ha leído tu historial. |
| C02c | A | M | `suceso(aparece(gran_roquefort))` | Al fondo de las Cuevas, algo azul y enorme se mueve despacio. Tiene barba de moho y opiniones firmes. |
| C03a | A | M | `suceso(golpe(normal, A, B, D))` | Golpe de ~w a ~w: ~w puntos. Limpio, correcto y olvidable. |
| C03b | A | X | idem | ~w alcanza a ~w y le quita ~w. Un testigo toma nota; otro, distancia. |
| C03c | A | X | idem | ~w pega, ~w recibe y la cuenta baja ~w puntos. |
| C04a | A | O | `suceso(golpe(flojo, A, B, D))` | El golpe de ~w apenas despeina a ~w. Cuenta como ~w, que es lo mínimo. |
| C04b | A | X | idem | ~w hace cosquillas a ~w: ~w de daño. Lo mínimo, pero firmado. |
| C05a | A | O | `suceso(golpe(fuerte, A, B, D))` | ~w descarga un golpazo sobre ~w: ~w puntos. Hasta el reglamento se ha sobresaltado. |
| C05b | A | X | idem | ~w arrea a ~w ~w puntos. En esta compañía, eso es un acontecimiento. |
| C06a | A | X | `suceso(sin_efecto(A))` | ~w lo intenta, no funciona y mira al cielo buscando testigos. |
| C06b | A | X | idem | No ha pasado nada. ~w finge que era la estrategia desde el principio. |
| C07a | A | M | `suceso(carga_heroica(B))` | Sir Baldomero grita «¡Por mi honor!» y carga contra ~w. Hay más honor que puntería, pero llega. |
| C07b | A | X | idem | Carga heroica: Sir Baldomero baja la visera, cierra los ojos y avanza hacia ~w. Funciona. |
| C08 | A | M | `suceso(fondue(B))` | Madame Pimentina lanza una Fondue Flamígera contra ~w. Huele a cena y a problemas para el enemigo. |
| C09 | A | X | `suceso(raclette(P))` | La Raclette Curativa envuelve a ~w en un aroma reconfortante. Cura y da hambre. |
| C10a | A | M | `suceso(balada)` | Rufino entona la Balada Inspiradora. La moral sube; los oídos se despiden. |
| C10b | A | X | idem | Rufino canta. El grupo se anima, el enemigo se desanima y los pájaros emigran. |
| C11 | A | X | `suceso(silencio_pagado)` | Pagas un queso y Rufino por fin calla. El silencio más caro y más agradecido de la jornada. |
| C12a | A | M | `suceso(rebuscar(E, ok))` | Tuerca rebusca en los bolsillos de ~w y encuentra un queso. «Lo tomo prestado», dice. |
| C12b | A | O | `suceso(rebuscar(E, nada))` | Tuerca rebusca en ~w y no halla nada. Se queda con la dignidad, que no cotiza. |
| C13 | A | M | `suceso(defiende(P))` | ~w levanta la guardia, la ceja y la moral. En ese orden. |
| C14 | A | X | `suceso(usa(P, O))` | ~w usa ~w con la seguridad de quien ha leído la etiqueta, casi entera. |
| C15a | A | M | `suceso(derrotado(E))` | ~w cae al suelo, mira al cielo y reconsidera su carrera. |
| C15b | A | X | idem | ~w se rinde. Nadie le va a pedir que se disculpe, lo cual ya es mucho. |
| C15c | A | X | idem | ~w queda fuera de combate. Se levantará en un rato, pero con otra actitud. |
| C15d | A | O | `suceso(derrotado(rata_quesera))` | La Rata Quesera se tumba, cierra los ojos y espera. Esta vez es en serio. Ofendida, pero en serio. |
| C15e | A | X | `suceso(derrotado(moho_saltarin))` | El Moho Saltarín se deshace en esporas y en disculpas, por ese orden. |
| C15f | A | X | `suceso(derrotado(bandido_torpe))` | El Bandido Torpe huye gritando «¡Esto no ha pasado!». Ha pasado, y con testigos. |
| C15g | A | X | `suceso(derrotado(jinete_parmesano))` | El Jinete Parmesano cae del caballo anunciando su derrota con tono de decreto real. |
| C15h | A | X | `suceso(derrotado(guardia_de_corteza))` | El Guardia de Corteza se desmonta en piezas ordenadas. Por una vez, el manual no preveía esto. |
| C15i | A | X | `suceso(derrotado(golem_de_queso_duro))` | El Gólem de Queso Duro se parte en tres trozos y una gorra. Nadie sabrá de dónde sacó la gorra. |
| C16a | A | M | `suceso(cae(P))` | ~w cae y decide que es un buen momento para reflexionar tumbado. |
| C16b | A | X | idem | ~w se desploma con elegancia. La elegancia no cura, pero se agradece. |
| C17a | A | M | `suceso(combate_ganado)` | Victoria. Se recoge el botín, se cuenta el queso y se niega todo lo que haya salido mal. |
| C17b | A | X | idem | El combate acaba a vuestro favor. Es la clase de noticia que la Banda nunca sabe dónde guardar. |
| C17c | A | X | idem | Habéis ganado. Un par de testigos aplauden; el resto prefiere no mojarse. |
| C18a | A | X | `suceso(huida(ok))` | La Banda se retira a una velocidad que los manuales llaman «táctica». |
| C18b | A | X | idem | Retirada con honor. El honor se ha quedado atrás, pero ya vendrá a buscaros. |
| C18c | A | X | idem | Os retiráis en orden. El orden, como siempre, lo marca el miedo. |
| C18d | A | X | `suceso(huida(fallo))` | Intentáis huir, pero el enemigo corre más. Se ve que había entrenado. |
| C19a | A | X | `suceso(lanza_rancio(E))` | Lanzas queso rancio contra ~w. Nadie lo esperaba, y menos que apestara tanto. |
| C19b | A | X | idem | El queso rancio vuela, impacta y apesta. La Ley del Hedor se cumple con puntualidad. |
| C19c | A | X | `suceso(apestado(E))` | Hedor sobre ~w: ataca con menos ganas durante un par de turnos. |
| C19d | A | X | `suceso(moho_come_rancio)` | El Moho Saltarín se zampa el queso rancio y se cura. A cada cual, su festín. |
| C20 | A | X | `suceso(contamina(Q))` | El Moho Saltarín toca ~w y lo envejece de golpe. Pide perdón, con esporas. |

Notas de la tabla 4.3 (alcance, 06 §5.1 y D-23, D-24):
- **Habilidades.** La versión mínima tiene una por personaje: `carga_heroica` (`C07`), `fondue_flamigera` (`C08`), `balada_inspiradora` (`C10`) y `rebuscar_bolsillos` (`C12`). `silencio_pagado` (`C11`) entra en el objetivo y `raclette_curativa` (`C09`), en el extra.
- **Estados y comandos extra.** `lanzar` y el estado `apestado` (`C19`) son extra, como la acción especial `contaminar` del Moho Saltarín (`C20`); `usar` (`C14`) y `huir` (`C18`) son del objetivo.
- **IA.** Las acciones especiales de la mínima son `robar_queso`, `embestir` e `invocar_moho` (06 D-24); el resto de perfiles de enemigo son extra.

### 4.4 Economía: queso, hambre, sueldos y huelga

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| E01a | A | M | `categoria_queso(_, fresco)` | Queso fresco: tierno, ingenuo y sin opiniones todavía. |
| E01b | A | X | idem | Fresco. Vale lo que su valor base y huele a futuro prometedor. |
| E02a | A | M | `categoria_queso(_, curado)` | Curado: ya ha visto mundo, vale lo máximo y lo sabe. |
| E02b | A | X | idem | Queso curado: vale más que nunca y lo sabe. Es el mejor momento de su vida; trátalo con respeto. |
| E02c | A | X | idem | Pasada la juventud y antes de la decadencia, el queso alcanza su plenitud. Como los rencores, pero más rico. |
| E03a | A | M | `categoria_queso(_, rancio)` | Rancio: ya pasó su momento. Vale casi nada, pero apesta con una dignidad enorme. |
| E03b | A | X | idem | Queso rancio. Vale poco como pago, pero la Ley del Hedor le guarda un último oficio: proyectil. |
| E03c | A | X | idem | Pasado cierto punto, el queso ya no mejora: se vuelve filosófico. Y huele a eso. |
| E04a | A | O | `suceso(madura(Q, curado))` | Hoy ~w entra en la edad curada. Pimentina quiere montar una fiesta. |
| E04b | A | X | idem | ~w ha madurado hasta curado. Si fuera un rencor, ya sería peligrosísimo. |
| E05a | A | O | `suceso(madura(Q, rancio))` | Mala noticia: ~w ha pasado de curado a rancio. El momento llega para todos, quesos incluidos. |
| E05b | A | X | idem | Hoy ~w se pasa de rancio. No se tira: ahora vale como proyectil. |
| E06 | A | X | `valor_queso(_, rancio, _)` | Un queso rancio vale casi nada y nadie lo compra. El Gremio de Afinadores lo llama «reciclaje»; el resto, «un problema». |
| E07 | A | X | `suceso(paga_primero_rancio)` | Los sueldos se pagan con el queso más rancio primero. El Gremio lo llama reciclar; el mercenario, de otra manera. |
| E08a | A | M | `suceso(racion(P, _, rancio))` | A ~w le toca queso rancio en la ración y pierde moral. El estómago olvida; el gusto, no. |
| E08b | A | X | idem | ~w se traga el queso rancio de la ración con una dignidad que no estaba en el presupuesto. |
| E09a | A | O | `suceso(come(P, _, curado))` | ~w come queso curado y se siente mejor. Es la ley: lo bueno madura. |
| E09b | A | X | `suceso(come(P, brie, curado))` | Un brie curado: caro, orgulloso y bueno para la moral. ~w sonríe sin querer. |
| E09c | A | X | `suceso(come(P, camembert, curado))` | Camembert curado: ~w siente la grandeza del reino bajar por la garganta. |
| E09d | A | X | `suceso(come(P, parmesano, curado))` | ~w come parmesano curado y se siente a prueba de lanzas hasta el próximo combate. |
| E09e | A | X | `suceso(come(P, roquefort, curado))` | ~w prueba roquefort curado: mal educado, potente y bueno para el ataque. |
| E10a | A | M | `suceso(hambre(P))` | ~w no ha comido hoy. El estómago ha presentado una queja formal. |
| E10b | A | X | idem | ~w tiene hambre, y el hambre tiene opiniones sobre la moral y la vida. |
| E10c | A | X | idem | ~w se queda sin ración. Pierde moral y algo de vida; la hoja de reclamaciones no existe. |
| E11a | A | M | `queso_total(0)` | La despensa está vacía. Hasta el eco ha pedido la cuenta. |
| E11b | A | X | idem | Cero quesos. Y recuerda: cobrar en promesas es el insulto máximo, aunque ahora nos valdría. |
| E12a | A | X | `racion(pan_duro, _)` | Pan duro como ración: alimenta, pero baja la moral, porque no es queso y todos lo notan. |
| E12b | A | X | idem | El pan duro llena el estómago y vacía el ánimo. Un queso valdría más; el pan duro, dura más. |
| E13a | A | M | `suceso(sueldos_pagados(T))` | Sueldos pagados: ~w quesos. Doña Mantecosa asiente; los mercenarios también, y eso es raro. |
| E13b | A | X | idem | Se reparten ~w quesos entre la compañía. La moral suena a monedas. |
| E13c | A | X | idem | Todos cobran. Es la clase de día que nadie en la Banda sabía que existía. |
| E14a | A | M | `suceso(sueldo_impagado(P))` | ~w no ha cobrado. Su cara está aprendiendo el idioma de las facturas. |
| E14b | A | X | idem | A ~w le deben el sueldo y se le nota en cada gesto. La moral baja. |
| E14c | A | X | idem | ~w mira la bolsa vacía y luego te mira a ti. No hace falta que hable. |
| E15a | A | M | `suceso(entra_en_huelga(P))` | ~w se declara en huelga. Los monstruos lo respetan: el piquete es sagrado. |
| E15b | A | X | idem | ~w deja el arma en el suelo y cruza los brazos. Sin ánimo, no hay combate. |
| E16 | A | M | `suceso(sale_de_huelga(P))` | ~w vuelve al trabajo con la dignidad intacta y la moral, por fin, medianamente en pie. |
| E17 | A | X | `suceso(todos_comen)` | Todos comen. Un día sin quejas es tan raro que se anota en el diario. |
| E18 | A | M | `falla(hay_queso_para(sueldos))` | No alcanza para todos los sueldos. Al que se queda sin cobrar se le promete, que es el insulto máximo. |
| E19 | A | X | `suceso(inventario_vacio)` | Tu inventario está vacío salvo por polvo, migas y una pizca de esperanza. La esperanza no se come. |

Notas de la tabla 4.4 (decisiones de 06):
- **Reglas del queso (D-10, D-11, D-13).** El queso entra por recompensa, botín y hallazgos, y sale por ración, sueldos, descanso, habilidades y multas; **no se compra ni se vende** y no hay tienda en la versión entregada. Por eso `E06` y `E07` ya no hablan de vendedores, `E12` (pan duro, objeto de tienda) es extra y ninguna frase menciona precios de compra. La ración diaria come primero lo fresco (D-11); los **sueldos** se pagan con lo más rancio primero (`E07`). Pagar es por unidades; el valor de `valor_queso/3` solo informa (`E06`).
- **Ración frente a `comer` (D-12).** `E08` narra la ración diaria automática (clave `racion(P, Q, Estado)`, que solo alimenta y penaliza el rancio); `E09` narra el comando voluntario `comer`, con el efecto del tipo (cura en la mínima; moral, ataque o defensa según el tipo, en el objetivo). La meta explicable de `comer` es `puede_comer(P, Q)` (`X21`, `F17`).
- **Pagar (D-14).** Los sueldos se pagan con el comando `pagar`, explicable con `puede_pagar_sueldos/0` (`X19`, `E13`, `E18`). El impago (`E14`) se anuncia **al salir** de la taberna con sueldos pendientes. Si 02 permite el pago parcial, `E18` sigue valiendo; si el pago es todo o nada, `por_que_no(pagar)` basta con `hay_queso_para(sueldos)`.
- **Huelga (06 X-25).** La huelga se deriva solo de la moral (`esta_en_huelga/1`); por eso `E15` y `E16` y las frases `F02` hablan de ánimo y no de sueldo cobrado.
- **Hambre (06 X-44).** El hambre baja moral y vida pero nunca deja a nadie por debajo de 1 de vida; la derrota por hambre (`derrota_hambre`) se anuncia al empezar el día con la despensa vacía y nada por cobrar (sección 4.9).

### 4.5 Viaje

Las descripciones de llegada son de ambiente; se eligen **por día** (estrategia B de la sección 5) para que el mismo viaje no suene igual dos veces seguidas pero la demo sea reproducible.

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| V01a | A | M | `suceso(llegada(taberna))` | Llegas al Cuajo Torcido. Huele a sopa de ayer y a una promesa de pago que nadie ha visto cumplida. |
| V01b | A | X | idem | La puerta del Cuajo Torcido cuelga de una sola bisagra. Según Doña Mantecosa, le da carácter. |
| V02a | A | M | `suceso(llegada(aldea))` | Aldea Requesón: casitas blancas, leche tibia y vecinos preguntando cuándo se les paga. |
| V02b | A | X | idem | En la aldea todo es tan pacífico que el arma más peligrosa del pueblo es un rodillo. |
| V03 | A | M | `suceso(llegada(bosque))` | El Bosque del Moho te recibe con pelusilla. Hasta la sombra tiene moho; las setas opinan de tu forma de caminar. |
| V04a | A | M | `suceso(llegada(camino_real))` | Camino Real: un peaje cada cien pasos, corteza vieja pegada a las suelas y bandidos con más ambición que puntería. |
| V04b | A | X | idem | El Camino Real está empedrado con corteza de queso viejo. Se te pega a las botas y a la conversación. |
| V05 | A | M | `suceso(llegada(castillo))` | El Castillo Camembert se hunde un poquito cada año, pero los guardias saludan con una rigidez ejemplar. |
| V06 | A | M | `suceso(llegada(cuevas))` | Cuevas del Roquefort: aire de sótano, un goteo cada tres segundos y la sensación de que el suelo te mira. |
| V07a | A | M | `suceso(viaje(Z))` | Pones rumbo a ~w. El camino se te pega a las botas, como siempre. |
| V07b | A | X | idem | Viajas a ~w. Un día entero, porque así lo manda la Ley de la Ruta Pegajosa. |
| V07c | A | X | idem | En marcha hacia ~w. Un día de camino, una suela de menos. |
| V08a | A | M | `suceso(dia_nuevo(D))` | Día ~w. Los quesos maduran y las deudas también. |
| V08b | A | X | idem | Amanece el día ~w. Alguien tiene hambre y alguien más, una cuenta pendiente. |
| V08c | A | X | idem | Día ~w de la Banda Chapuza. El Registro de Compañías sigue donde estaba: abajo. |

### 4.6 Descanso

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| D01a | A | M | `suceso(descanso)` | La Banda duerme en camas que han visto cosas. Recuperan vida y algo de moral, y nadie pregunta por las manchas. |
| D01b | A | X | idem | Descansáis. La vela se consume, los ronquidos de Rufino riman y Doña Mantecosa cobra las camas con puntualidad. |
| D01c | A | X | idem | Una noche en el Cuajo Torcido: poco sueño, mucho ruido y el colchón de siempre. |
| D02 | A | X | `suceso(trebol_al_amanecer(P))` | Amanece y el Trébol de Cuatro Quesos le sube la moral a ~w. Huele sospechosamente a suerte. |

Descansar cuesta queso y un día (06 D-15) y no genera deuda: las frases de `D01` hablan del cobro, no de una cuenta pendiente. `D02` depende del objeto Trébol de Cuatro Quesos, que solo existe en el extra.

### 4.7 Taberna y Doña Mantecosa

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| T01a | A | X | `suceso(mantecosa(saludo))` | Doña Mantecosa te recibe tras la barra con la sonrisa de quien ya ha calculado lo que le debes. |
| T01b | A | X | idem | «Ah, la Banda», dice Doña Mantecosa. Lo dice como quien nombra una mancha. |
| T01c | A | X | idem | Doña Mantecosa levanta la vista, mira la puerta y luego tu bolsa. Por ese orden. |
| T03 | A | X | `suceso(mantecosa(contrato_firmado))` | Doña Mantecosa pone el sello: «Si lo rompéis, lo pagáis». La conversación termina ahí. |
| T04 | A | X | `suceso(mantecosa(cobro))` | Cobras la recompensa y Doña Mantecosa la mira de reojo, por si acaso se le pega algo. |
| T05 | A | X | `suceso(mantecosa(mesa))` | La mesa coja cojea, como siempre. Doña Mantecosa dice que le da carácter. |
| T06 | A | X | `suceso(registro_en_pared)` | En la pared, el Registro de Compañías. La Banda Chapuza está la última, con tiza de otro color y una errata. |
| T07 | A | X | `suceso(mantecosa(suero))` | Doña Mantecosa señala un barril de suero fermentado: no está en venta, pero el consejo que lo acompaña es gratis y nadie lo ha pedido. |

La frase `T02` (anotar quesos en la cuenta) **se retira** con `deuda_taberna/1` (06 D-15). Doña Mantecosa no vende nada en la versión entregada (06 D-10): `T07` queda como ambiente (extra).

### 4.8 Ayuda y errores de comando

El tono de los errores es el más amable de todo el banco: se corrige con una sonrisa, nunca con un reproche (regla de oro 6).

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| A01a | A | M | `suceso(ayuda)` | Comandos disponibles: los de siempre. Escríbelos con su punto final, que el reglamento es muy de puntos. |
| A01b | A | X | idem | Esto es la ayuda. Tiene más comandos de los que usarás y menos de los que necesitarías. |
| A02a | A | M | `suceso(comando_desconocido(C))` | No conozco el comando ~w. El narrador sabe muchas cosas, pero no esa. |
| A02b | A | X | idem | ~w no figura en el reglamento. Prueba con ayuda., que es corto y no muerde. |
| A02c | A | X | idem | Eso de ~w suena a idea, no a comando. Escribe ayuda. y verás los de verdad. |
| A03a | A | M | `suceso(error_sintaxis)` | Te falta el punto final. Una orden sin punto es un jefe que no sabe cuándo callarse. |
| A03b | A | X | idem | No he entendido eso. Recuerda: paréntesis cerrados y un punto al final, como en una factura. |
| A03c | A | X | idem | Esa orden tiene más huecos que un queso suizo. Cierra los paréntesis y acaba con punto. |
| A04 | A | X | `suceso(nombre_desconocido(X))` | ~w no existe en los Reinos Quesudos. Revisa que esté escrito tal como lo ves en la lista. |
| A05 | A | X | `suceso(sin_combate)` | Aquí no hay a quién atacar. Por ahora. |
| A06a | A | M | `suceso(salir)` | La Banda se despide. El narrador también, aunque nadie le había preguntado. |
| A06b | A | X | idem | Hasta la próxima. Los quesos seguirán madurando sin ti, que es lo que mejor se les da. |
| A07a | A | X | `suceso(nivel(resumido))` | Nivel resumido: solo lo esencial. Es más rápido y algo menos entretenido. |
| A07b | A | X | `suceso(nivel(detallado))` | Nivel detallado: se explica todo. Tú lo has pedido y nadie podrá decir que no se avisó. |
| A08a | A | X | `suceso(arbol(texto))` | Árbol de derivación impreso. Es un árbol genealógico con menos primos y más motivos. |
| A08b | A | X | `suceso(arbol(dot))` | Árbol exportado a un archivo. Nadie lo regará, pero se puede dibujar. |
| A09 | A | X | `suceso(ayuda_explicar)` | Pregunta «¿por qué?» con explicar(...). y «¿por qué no?» con por_que_no(...). Aquí se justifica todo, hasta lo injustificable. |

Comandos (06 D-20): la versión mínima tiene 16 (`ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir`); el objetivo añade `nivel`, `arbol`, `usar`, `huir`, `comer` y `demo` (`A07` y `A08a` son del objetivo; `A08b`, el volcado a `.dot`, es extra). Las frases de ayuda citan los comandos tal como los escribe el jugador, como términos con punto final (parser de la versión 1, 02 §3.11).

### 4.9 Inicio y fin de la partida

Se imprimen sin prefijo `Narrador:` (son narración, no comentario), por eso pueden llegar a 210 caracteres.

**Finales y ids (06 D-17, D-29, D-30, X-44, X-53).** Los ids de final son los de 04 §8.4: `chapuza`, `derrota_combate` y `derrota_hambre` en la versión **mínima**; `leyenda` y `quiebra` en el **objetivo** (`madurado` y `derrota_plazo` son extra). Los cuerpos de los finales (los textos de cierre de 04 §8.5, con el puesto del Registro que dicen: 12, 31…) se guardan como `texto(final(Id))` (sección 7.2) y no se reproducen aquí. Este banco aporta lo que rodea a esos cuerpos: `I02` es la escena del jefe al caer (`jefe_derrotado`, antes del texto del final elegido) e `I03a`/`I03b` son la línea de cierre del narrador en las derrotas; si 04 ya trae su propia línea de narrador en un cuerpo, se imprime solo una de las dos (ver pendientes en el registro de cambios). Los ids `fin_victoria`, `fin_derrota(sin_miembros)` y `fin_derrota(sin_queso)` de la v0.1 desaparecen.

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| I01a | A | M | `suceso(inicio)` | Año 412. En el Registro de Compañías, la Banda Chapuza ocupa el puesto 47 de 47. Hoy podría mejorar, o no. |
| I01b | A | X | idem | Los Reinos Quesudos huelen a queso y a problemas. Tú mandas una banda que huele a las dos cosas. |
| I01c | A | X | idem | Cuatro mercenarios, una cuenta sin pagar y ningún plan. Te damos la bienvenida, jefe o jefa, a la Banda Chapuza. |
| I02a | A | M | `suceso(jefe_derrotado)` | El Gran Roquefort suspira, se agrieta y murmura: «Quizá sí tenía prisa». El moho se retira y la despensa del rey respira. |
| I02b | A | X | idem | Lo habéis logrado. El moho retrocede, el rey toma nota y la Banda decide no preguntar cuándo le pagarán. La errata se queda. |
| I02c | A | X | idem | Victoria. Los Reinos Quesudos hablarán de esto, o del tema que el rey tenga a mano. |
| I03a | A | M | `suceso(fin(derrota_combate))` | La Banda Chapuza ha caído. Quedan las deudas, que es lo único que en esta compañía nunca desaparece. |
| I03b | A | M | `suceso(fin(derrota_hambre))` | Sin queso, sin sueldos y sin ganas. La Banda se disuelve, y Rufino ni siquiera canta, porque nadie le paga. |
| I04 | A | M | `suceso(resumen_final(D, N))` | Resumen: ~w días de camino y ~w quesos en la bolsa. Cifras modestas, historia notable. |
| I05 | A | X | `suceso(registro(N))` | El Registro de Compañías coloca a la Banda Chapuza en el puesto ~w de 47. La errata sigue allí. |

`I05` solo se usa **durante la partida** (por ejemplo, tras cumplir un contrato); al terminar, el puesto lo da el texto del final (06 X-53). Las líneas `I03` hablan de "deudas" y de "sueldos" como ambiente: no remiten a ningún estado de deuda (06 D-15).

### 4.10 Contratos

Las frases genéricas no nombran el contrato (lo imprime `ui.pl`). Las específicas usan el id de contrato del lore §10.11. Alcance de contratos (06 §5.1): la **mínima** tiene 4 (`ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real`); el **objetivo** añade `peaje_del_ganso` y `fantasma_charlatan`; el resto es extra. Las claves de los resultados son `contrato_cumplido` (éxito), `contrato_parcial` (a medias) y `contrato_fracasado`, que corresponden a `contrato_cerrado(C, Res)` y sus derivados (06 X-18). En la escolta de `gallina_noble` la versión mínima usa un contador de golpes recibidos por Clotilde (06 D-33), de modo que `K06` no cambia. `K05` (abandonar) y `K11` son extra: no hay comando de abandono en la mínima y `silvestre_para_ricota` es un contrato extra.

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| K01a | A | M | `suceso(contrato_aceptado)` | Contrato aceptado. La Ley del Contrato Escrito te obliga, aunque lo haya firmado una gallina. |
| K01b | A | X | idem | Queda firmado. Ya no hay marcha atrás, salvo con multa y tristeza. |
| K02a | A | M | `suceso(contrato_cumplido)` | Contrato cumplido. Hasta la Banda Chapuza acierta de vez en cuando; es cuestión de estadística. |
| K02b | A | X | idem | Resuelto. El cliente sonríe; el narrador también, aunque con reservas. |
| K03a | A | X | `suceso(contrato_parcial)` | Contrato a medias: objetivo cumplido, botín incompleto. Cobras lo que cabe en una sonrisa torcida. |
| K03b | A | X | idem | Sale regular. Se hizo lo pedido, pero a la manera de la Banda; la recompensa se paga con el mismo criterio. |
| K04a | A | O | `suceso(contrato_fracasado)` | El contrato fracasa. El cliente no cobra, tú no cobras y el único que gana es el pesimismo. |
| K04b | A | X | idem | Se ha torcido. No hay recompensa, pero sí una anécdota. Las anécdotas no se comen. |
| K05 | A | X | `suceso(abandona_contrato)` | Abandonas el contrato. La moral del grupo cae: romper lo firmado escuece más que una cuenta. |
| K06 | A | X | `suceso(contrato_cumplido(gallina_noble))` | Lady Clotilde llega al castillo entera y con todas las plumas, que era lo que había que lograr. |
| K07 | A | X | `suceso(contrato_cumplido(gato_en_el_arbol))` | El gato baja del árbol por su cuenta, sin hacer caso a nadie. El árbol, por fin, coopera. |
| K08 | A | X | `suceso(contrato_cumplido(fantasma_charlatan))` | Eustaquio acaba por fin su historia, entrega la Llave Mohosa y se desvanece satisfecho. Nadie recuerda cuándo empezó. |
| K09 | A | X | `suceso(contrato_cumplido(ratas_del_granero))` | El granero queda libre de ratas. Ellas aseguran que fue un malentendido y que volverán. |
| K10 | A | X | `suceso(contrato_cumplido(peaje_del_ganso))` | El ganso deja de cobrar peaje. Te entrega un recibo por las molestias. |
| K11 | A | X | `suceso(contrato_cumplido(silvestre_para_ricota))` | Ricota recibe sus quesos silvestres y los huele con respeto. Todo se arregla con una oferta, dice. |
| K12 | A | X | `suceso(sello_real_entregado)` | El rey Brieto te entrega el Sello Real con ambas manos, un temblor y un leve olor a despensa. |

### 4.11 Frases genéricas de reserva

Se usan cuando una regla, hecho o suceso no tiene frase propia (sección 7.5). Son deliberadamente neutras y cortas: si salen mucho, falta cobertura.

| Id | Niv | Alc | Clave | Texto |
|---|---|---|---|---|
| G01a | A | M | `generica(exito)` | Todo conforme al reglamento. En esta compañía, eso es una noticia. |
| G01b | A | X | idem | La regla se cumple y el narrador, sorprendido, lo deja constar. |
| G01c | A | X | idem | Demostrado. No hay más que añadir, y eso ya es raro. |
| G02a | A | M | `generica(fallo)` | No se cumple. El reglamento es así de terco y yo solo leo el acta. |
| G02b | A | X | idem | Falla, y ninguna excusa lo arregla. Las he oído todas. |
| G02c | A | X | idem | Esto no sale. La regla ha hablado. |
| G03 | D | M | `generica(hecho)` | Hecho comprobado. De los pocos que no han discutido con nadie. |
| G04a | D | M | `generica(negacion)` | No consta nada en contra. Y lo que no consta, no estorba. |
| G04b | D | M | `generica(impide)` | Algo lo impide, y esta vez está registrado. Eso es raro en esta compañía. |
| G05 | D | M | `generica(predefinido)` | Aritmética pura: aquí nadie discute, ni siquiera el narrador. |
| G06 | A | M | `generica(sin_prueba)` | No hay prueba que mostrar: eso no se puede demostrar. Prueba con por_que_no(...), que se le da mejor. |
| G07 | A | M | `generica(sin_fallo)` | No falla nada: la acción es perfectamente posible. Prueba con explicar(...) y verás por qué. |
| G08 | D | M | `generica(regla)` | Regla aplicada. Nadie ha preguntado por los detalles, y yo, de momento, tampoco. |

---
## 5. Cómo evitar la repetición sin aleatoriedad pura

### 5.1 Principios

1. **El narrador es puro (06 D-25).** `narrador.pl` es de capa 0, no importa nada, **no guarda estado** y **no usa azar**: es una función de la clave, del día y de unos contadores que recibe como argumento. Así, la misma secuencia de comandos produce siempre la misma salida (criterio de F-33: la demo es idéntica byte a byte). El único azar de todo el humor son los eventos de la sección 6, y usan el generador congruencial de 02 §4.4 con la semilla que guarda `estado`.
2. **Las variantes son hechos `frase/3` repetidos con la misma clave**, en el orden en que se escriben. El orden importa: la **primera variante es la mejor para la demo** (es la que verá el evaluador) y las siguientes pueden ser más extravagantes.
3. **Los contadores viven en `estado.pl`** (único escritor, 06 X-01, X-06). El narrador **devuelve efectos como datos** (`usar_frase(Grupo)`, `fijar_uso(Grupo, N)`, `descanso_gag(Gag, Vuelta)`, `visto_gag(Gag, Dia)`, `fijar_coletilla(Bool)`) y `estado:aplicar_efectos/1` los aplica; los contadores se reinician con `nueva_partida/0`. No existen predicados `actualizar_*` en el narrador y los contadores no influyen jamás en la lógica del juego: borrar todas las frases no cambia ningún resultado (criterio de aceptación de F-24).
4. **Nadie más que `ui` llama al narrador.** `juego:ejecutar/2` devuelve `msg(Clave, Args)`, `prueba(...)`, `diag(...)` y la lista de candidatos de gag; `ui` los pasa al narrador junto con una copia de los contadores (`estado:contadores_narrador/1`), imprime el texto y devuelve los efectos a `juego` para que los aplique `estado`.

### 5.2 Estrategias de selección

| Estrategia | Idea | Cuándo |
|---|---|---|
| **A. Rotación por contador** | Cada vez que se narra una clave, se usa la variante `usos mod N` y el contador sube en `estado`. Nunca repite dos veces seguidas si hay N ≥ 2. | Por defecto: comentarios de `explicar`, `por_que_no`, combate, economía, errores. |
| **B. Por día** | Variante `dia mod N`. No necesita contador. | Descripciones de ambiente: llegadas a una zona, día nuevo. |
| **C. Contexto en la clave** | La clave lleva el dato que distingue la situación (calidad del golpe, tipo de queso, personaje, enemigo concreto) y se elige la clave más específica. | Golpes (`flojo`/`normal`/`fuerte`), huelga por personaje, derrotas por enemigo. |
| **D. Escalada con tope y descanso** | Cada aparición avanza un paso; al agotar los pasos, descansa unos días y vuelve al paso 2. | Coletillas de los gags (sección 3). |
| **E. Azar con el LCG de 02** | `tirada(N, S0, R, S1)` (02 §4.4: `S1 is (S0*75+74) mod 65537`, `R is S1 mod N`) con la semilla de `estado`. **Sin** `random_between/3`, `random_member/2` ni `set_random/1` (los dos primeros no existen en 5.10.4 y la secuencia de `set_random` no es reproducible entre máquinas). | Solo los eventos (sección 6) y cualquier elección que no sea un contador. |

### 5.3 Qué estrategia para cada situación

| Situación | Estrategia | Motivo |
|---|---|---|
| Comentario de `explicar` / `por_que_no` | A + C | Varía entre preguntas repetidas y se ajusta a la regla. |
| Golpes y sucesos de combate | A + C | El mismo golpe no suena igual tres veces seguidas. |
| Llegada a zona y día nuevo | B | Cada día es distinto y no se acumula estado. |
| Errores de comando | A | El jugador novato se equivoca varias veces seguidas: que no lea lo mismo. |
| Coletillas de gags | D | Escalada con final. |
| Eventos | E | Variedad real, pero reproducible. |
| Inicio y fin de partida | A | Hay tres versiones para partidas repetidas. |

### 5.4 Bocetos en Prolog

Los bocetos de esta sección y de 7.4 se escribieron como un archivo de prueba y se ejecutaron en SWI-Prolog 5.10.4 (2 de noviembre de 2026) con un puñado de frases de ejemplo: devuelven lo que se describe. No sustituyen a las pruebas plunit de 7.6.

**Contrato del narrador.** `Ctx = ctx(Dia, Cs)`, donde `Cs` es una lista de contadores copiada de `estado` (`uso(Grupo)-N`, `descanso(Gag)-DiaDeVuelta`, `visto(Gag)-Dia`, `coletilla_previa-si`) o el átomo `fijo` (modo para pruebas, 5.6). Todo predicado devuelve el texto y la lista de efectos a aplicar.

**Estado de presentación en `estado.pl`** (persistente o transitorio según decida 02 §4.3; se reinicia con `nueva_partida/0`):

```prolog
% estado.pl (boceto sin ejecutar)
:- dynamic uso_frase/2.        % uso_frase(Grupo, N)
:- dynamic descanso_gag/2.     % descanso_gag(Gag, DiaDeVuelta)
:- dynamic visto_gag/2.        % visto_gag(Gag, Dia)
:- dynamic explicaciones/2.    % explicaciones(Dia, N): para el gag cansancio
:- dynamic coletilla_previa/1. % coletilla_previa(si|no)

% efectos que el narrador devuelve como datos
aplicar_efecto(usar_frase(G))      :- uso_frase_actual(G, U), U1 is U + 1, fijar_uso(G, U1).
aplicar_efecto(fijar_uso(G, N))    :- fijar_uso(G, N).
aplicar_efecto(descanso_gag(G, V)) :- retractall(descanso_gag(G, _)), assertz(descanso_gag(G, V)).
aplicar_efecto(visto_gag(G, D))    :- retractall(visto_gag(G, _)), assertz(visto_gag(G, D)).
aplicar_efecto(fijar_coletilla(B)) :- retractall(coletilla_previa(_)), assertz(coletilla_previa(B)).
aplicar_efecto(contar_explicacion(D)) :-       % lo emite ui tras cada explicar/por_que_no
    (   retract(explicaciones(D, N0)) -> true ; N0 = 0 ),
    N is N0 + 1, assertz(explicaciones(D, N)).
% fijar_uso/2 y uso_frase_actual/2 son auxiliares privados de estado.

contadores_narrador(Cs) :-
    findall(uso(G)-N, uso_frase(G, N), Us),
    findall(descanso(G)-V, descanso_gag(G, V), Ds),
    findall(visto(G)-D, visto_gag(G, D), Vs),
    ( coletilla_previa(si) -> Ps = [coletilla_previa-si] ; Ps = [] ),
    append([Us, Ds, Vs, Ps], Cs).
```

**Candidatos y casado de claves.** Las frases se llaman directamente (`frase/3` es un hecho estático del propio módulo); se queda con las de la **clave más específica** (menos variables libres) y conserva el orden del fichero. Una clave con el átomo de un tipo de enemigo casa con su instancia `e(Tipo, N)` (06 X-19):

```prolog
% narrador.pl (boceto; capa 0: sin imports, sin estado, sin azar)
variantes(Meta, Nivel, Grupo, Textos) :-
    findall(NV-G-T,
            (   frase(Clave, N, Plantilla),
                nivel_aplica(N, Nivel),
                term_variables(Clave, Vs), length(Vs, NV),   % antes de unificar
                clave_grupo(Clave, G),
                casa(Clave, Meta),                           % ¿aplica a esta meta?
                formatear(Plantilla, T)
            ),
            Ternas),
    Ternas = [_|_],
    keysort(Ternas, [NV0-G0-_ | _]),        % menos variables = más específica
    Grupo = G0,
    findall(T, member(NV0-G0-T, Ternas), Textos).

nivel_aplica(ambos, _).
nivel_aplica(N, N).

clave_grupo(Clave, Grupo) :-
    copy_term(Clave, Grupo),
    numbervars(Grupo, 0, _).

% casa(+Clave, +Meta): unifica salvo que la clave lleva el tipo y la meta la instancia
casa(C, M) :- var(C), !, C = M.
casa(C, e(T, _)) :- atomic(C), !, C == T.
casa(C, M) :- atomic(C), !, C == M.
casa(C, M) :- compound(M), C =.. [F|As], M =.. [F|Bs], maplist(casa, As, Bs).
```

Estrategia A (rotación por contador). El narrador no escribe: devuelve el efecto `usar_frase(Grupo)`:

```prolog
% narrador.pl (boceto)
comentario(Meta, Nivel, ctx(_Dia, Cs), Texto, Efectos) :-
    variantes(Meta, Nivel, Grupo, Textos),
    elegir(Cs, Grupo, Textos, Texto, Efectos).

elegir(fijo, _, [Texto|_], Texto, []) :- !.           % modo para pruebas (5.6)
elegir(Cs, Grupo, Textos, Texto, [usar_frase(Grupo)]) :-
    length(Textos, N), N > 0,
    usos(Grupo, Cs, U),
    I is U mod N,
    nth0(I, Textos, Texto).

usos(Grupo, Cs, U) :-
    (   memberchk(uso(Grupo)-U0, Cs) -> U = U0 ; U = 0 ).
```

Estrategia B (por día):

```prolog
% narrador.pl (boceto)
elegir_por_dia(Dia, Textos, Texto) :-
    length(Textos, N), N > 0,
    I is Dia mod N,
    nth0(I, Textos, Texto).
```

Estrategia D (escalada con tope y descanso). Al llegar al último paso el gag descansa y vuelve al paso 2 (índice 1). El número de días de descanso es dato (`descanso_dias/2`, columna "Descanso" de la tabla 3.1; `registro` no escala ni descansa):

```prolog
% narrador.pl (boceto)
descanso_dias(caballo, 4).   descanso_dias(casualidad, 3).
descanso_dias(silencio, 5).  descanso_dias(yo_no_he_sido, 5).
descanso_dias(registro, 0).
% ... uno por gag, según la columna "Descanso" de la tabla 3.1

en_descanso(Gag, Dia, Cs) :-
    memberchk(descanso(Gag)-Vuelta, Cs), Dia < Vuelta.

elegir_escalada(Gag, Grupo, Textos, ctx(D, Cs), Texto, Efectos) :-
    \+ en_descanso(Gag, D, Cs),
    length(Textos, N), N > 0,
    usos(Grupo, Cs, U),
    I is min(U, N - 1),
    nth0(I, Textos, Texto),
    U1 is U + 1,
    (   U1 >= N
    ->  descanso_dias(Gag, Dias), Vuelta is D + Dias,
        Efectos = [fijar_uso(Grupo, 1), descanso_gag(Gag, Vuelta), visto_gag(Gag, D)]
    ;   Efectos = [fijar_uso(Grupo, U1), visto_gag(Gag, D)]
    ).
```

Coletilla de la salida actual (cadencia y prioridad de la sección 3.4). Los candidatos los evalúa `juego` (3.3) y llegan como pares `Gag-Clave` (por ejemplo `registro-gag(registro(44))`):

```prolog
% narrador.pl (boceto)
coletilla(Nivel, Candidatos, ctx(D, Cs), Texto, Efectos) :-
    Nivel \== resumido,
    \+ memberchk(coletilla_previa-si, Cs),           % cadencia 1 de cada 2
    findall(Dia-(Gag-Clave),
            (   member(Gag-Clave, Candidatos),
                \+ en_descanso(Gag, D, Cs),
                (   memberchk(visto(Gag)-Dia, Cs) -> true ; Dia = 0 )
            ),
            Pares),
    Pares = [_|_],
    keysort(Pares, [_-(Gag-Clave) | _]),             % el que más tiempo lleva sin salir
    variantes(Clave, Nivel, Grupo, Textos),
    elegir_escalada(Gag, Grupo, Textos, ctx(D, Cs), Texto, Efectos0),
    Efectos = [fijar_coletilla(si) | Efectos0].
```

`keysort/2` es estable, así que a igualdad de días gana el primer candidato en el orden de la lista que arma `juego`, que es el de la tabla 3.1. Cuando una salida no lleva coletilla, `ui` añade el efecto `fijar_coletilla(no)`.

**Generador de azar** (solo eventos; es el de 02 §4.4, aquí repetido para tenerlo a mano):

```prolog
% estado.pl o eventos.pl (boceto; ver 02 4.4)
siguiente_semilla(S0, S1) :- S1 is (S0 * 75 + 74) mod 65537.
tirada(N, S0, R, S1) :-                 % R en 0..N-1
    siguiente_semilla(S0, S1),
    R is S1 mod N.
```

El sesgo de `mod N` y el periodo del generador están pendientes de comprobar (V-09 de 06 §7.2); para 100 o menos resultados distintos no afecta al humor.

### 5.5 Cómo se ve a lo largo de una partida

La clave `puede_atacar(baldomero, E)` tiene tres variantes. Cuatro `explicar` seguidos de un ataque de Baldomero producen:

| Uso | Variante | Frase (resumida) |
|---|---|---|
| 1.º | X01a | "…Fue la primera vez en una semana que no le temblaron las rodillas." |
| 2.º | X01b | "No hay caballos a la vista… valentía recién estrenada." |
| 3.º | X01c | "…asegura que fue pura casualidad." |
| 4.º | X01a | Vuelve a empezar, tres usos después. |

Con la versión mínima solo existe `X01a`: la rotación no hace nada (una sola variante) y el narrador repite la mejor frase, que es lo que ve la demo. Las variantes `b` y `c` se activan al pasar al objetivo.

### 5.6 Modo fijo para pruebas

Para que una prueba plunit no dependa del historial de usos, el contexto puede ser `ctx(Dia, fijo)`: `elegir/5` devuelve siempre la primera variante y **no devuelve efectos**. No hay modo global ni hecho `narrador_modo/1` (eso sería estado del narrador): el modo es un argumento. `nueva_partida/0` reinicia los contadores en `estado`.

---

## 6. Eventos cómicos aleatorios

Diecinueve eventos diseñados (veintitrés textos, porque cuatro tienen dos desenlaces según el estado). Son la funcionalidad **F-25** (prioridad "Debería", tarea T-34 ◇) y quedan así de alcance (06 D-28, §5.1):

| Versión | Eventos aleatorios | Cuáles |
|---|---|---|
| Mínima | **0** | Ninguno: el humor de la mínima no necesita azar. |
| Objetivo | **5** (6 textos) | `rata_en_la_despensa`, `moho_en_la_despensa`, `tuerca_encuentra` (2 desenlaces), `mesa_coja`, `cumple_de_un_queso`. |
| Extra | **19** (23 textos) | Los 19 de la tabla 6.4. |

**No se duplican los eventos de campaña de 04 (06 X-52).** Los eventos deterministas de 04 §7 mandan. Cinco eventos de este documento cuentan lo mismo que algo de 04 y llevan la marca `†` en la tabla 6.4: **si se activan los 19 en el extra, hay que desactivar el equivalente de 04 o dejarlos fuera**; nunca ocurren ambos. Son `ganso_peaje` (04: `v_ganso_tasa` y el contrato `peaje_del_ganso`), `visita_de_pecorino` (`v_pecorino_ronda`), `trebol_hallado` (recompensa de `cena_de_eustaquio`), `charla_de_eustaquio` y `gato_caido` (sus contratos). Además `regalo_del_ermitano` se parece a `paz_del_moho` y `tuerca_encuentra` a `t_tuerca_cuenta`; este último solo ocurre en la taberna, y `tuerca_encuentra` nunca sale allí (condición `\+ en_zona(taberna)`), así que ambos conviven; para `regalo_del_ermitano` hay que elegir uno de los dos si se activa el extra.

Los gags de la sección 3 **no dependen** de los eventos, salvo `yo_no_he_sido`, que también se activa con `rebuscar_bolsillos`.

### 6.1 Reglas generales

- Un evento puede ocurrir **al terminar de viajar o descansar** (después del efecto `avanzar_dia`, etapa 4 de 02 §5.5), a lo sumo **uno por día**.
- **Nunca en el día 1** ni durante un combate.
- Probabilidad base por día: **35 %** (provisional).
- Entre los eventos posibles (cuya condición es cierta y que no están en enfriamiento) se elige uno con el generador de 02 §4.4: `tirada(N, S, I, S1)` sobre la lista de posibles y `nth0/3`. La semilla es `semilla/1` de `estado`, y `juego` aplica `fijar_semilla(S1)` tras cada tirada (así la partida y la demo son reproducibles, F-25 y F-33; 06 O-1).
- Cada evento tiene un **desenlace** (`unico` o uno concreto), que se decide por **condición**, no por azar. El texto es una frase del banco con clave `evento(Id, Desenlace)`.
- Los efectos son términos del vocabulario de 02 §4.5 que `estado:aplicar_efectos/1` aplica (el único escritor); `eventos:expandir/2` traduce la forma abreviada de esta sección (6.2).
- **Ningún evento añade ni quita miembros** de forma permanente (reclutar es F-28, "Podría"). Los eventos afectan a queso, moral, vida, objetos y estados.
- Las cifras de los efectos son pequeñas (±1 o ±2) y provisionales. Si cambia un efecto, hay que revisar el texto que lo menciona ("un queso").

### 6.2 Selección y aplicación (boceto)

Cada par `evento_posible/2` + `efecto/3` + `enfriamiento/2` de esta sección es, en el código, un hecho `evento/3` de 02 §3.7 (`evento(Id, Condicion, Efectos)`) en `eventos.pl`; aquí se escriben por separado para leerlos mejor. El predicado `eventos:evento_del_dia/3` de 02 recibe la semilla y la devuelve avanzada, y `juego` aplica `fijar_semilla/1`. El boceto siguiente se ejecutó en SWI-Prolog 5.10.4 con tres eventos de ejemplo y devuelve `ninguno` o `Id-Desenlace` sin usar `random_between/3` ni `random_member/2`:

```prolog
% eventos.pl (boceto; elegir con el LCG de 02 4.4)
evento_del_dia(S0, Evento, S2) :-
    tirada(100, S0, R, S1),                          % R en 0..99
    probabilidad_evento(P),                          % por ejemplo, 35
    (   dia(D), D >= 2,
        R < P,
        findall(Id-X, ( evento_posible(Id, X), \+ en_enfriamiento(Id) ), Posibles),
        Posibles = [_|_]
    ->  length(Posibles, N),
        tirada(N, S1, I, S2),
        nth0(I, Posibles, Evento)
    ;   Evento = ninguno,
        S2 = S1
    ).

en_enfriamiento(Id) :-
    enfriamiento(Id, Dias),
    evento_visto(Id, U),                             % hecho de estado (02 4.2)
    dia(D),
    D - U < Dias.

efectos_evento(Id, Desenlace, Efectos) :-
    efecto(Id, Desenlace, Abreviados),
    findall(E, ( member(A, Abreviados), expandir(A, Es), member(E, Es) ), Efectos0),
    Efectos = [visto(Id) | Efectos0].               % visto/1 de 02 4.5 anota el dia
```

Traducción de la forma abreviada de esta sección al vocabulario de efectos de 02 §4.5 (06 X-03). `expandir/2` es un traductor de datos, sin `assert`; el único que escribe es `estado:aplicar_efectos/1`:

| Forma de 05 | Efectos de 02 |
|---|---|
| `quitar_queso(N)` | `gastar_queso(T, E, 1)` repetido `N` veces sobre el queso **más rancio** (mismo criterio que los sueldos) |
| `quitar_queso_mas_fresco(N)` | `gastar_queso(T, E, 1)` sobre el más fresco, `N` veces |
| `dar_queso(T, E, N)` | `ganar_queso(T, E, N)` |
| `moral(grupo, D)` | un `mod_moral(Id, D)` por cada miembro `activo` |
| `moral(Id, D)` | `mod_moral(Id, D)` |
| `vida(grupo, D)` / `vida(Id, D)` | `curar/2` o `dano/2` (según el signo) por miembro o para `Id`; nunca bajan a menos de 1 fuera de combate |
| `envejecer_lote_mas_curado(N)` | efecto nuevo `envejecer_lote(N)` (el lote más curado envejece `N`) |
| `dar_objeto(O)` | `ganar_objeto(compania, O, 1)` |
| `quitar_estado(Id, Est)` | `quitar_alteracion(Id, Est)` |

```prolog
% eventos.pl (boceto sin ejecutar)
expandir(dar_queso(T, E, N), [ganar_queso(T, E, N)]).
expandir(moral(grupo, D), Efectos) :-
    findall(mod_moral(Id, D), activo(Id), Efectos).
expandir(moral(Id, D), [mod_moral(Id, D)]) :- Id \== grupo.
expandir(quitar_estado(Id, Est), [quitar_alteracion(Id, Est)]).
expandir(dar_objeto(O), [ganar_objeto(compania, O, 1)]).
% ... quitar_queso/1 y quitar_queso_mas_fresco/1 miran la despensa;
%     vida/2 y envejecer_lote_mas_curado/1 siguen el mismo patron
```

### 6.3 Condiciones de activación (boceto sin ejecutar)

Los auxiliares son consultas puras sobre el estado con los nombres canónicos de 06 §2.7: `activo/1` (miembro de la compañía y vivo; sustituye al `en_compania/1` de la v0.1), `esta_en_huelga/1`, `lleva(compania, Objeto, N)` (sustituye a `lleva_alguien/1` y `posee/1`), `evento_visto(Id, Dia)` (sustituye a `evento_ocurrido/1` y `ultimo_dia_evento/2`), `categoria_queso/2` (sustituye a `estado_queso/2`) y `hay_queso/1` (hay alguna unidad en esa categoría). El alcance de cada evento (M/O/X) y la marca `†` de solapamiento con 04 están en la tabla 6.4.

```prolog
% eventos.pl (boceto sin ejecutar)
hay_queso(Cat) :- queso(_, Edad, Cant), Cant > 0, categoria_queso(Edad, Cat).

evento_posible(ganso_peaje, unico) :-
    en_zona(camino_real), \+ lleva(compania, sello_real, _),
    queso_total(Q), Q >= 1.
evento_posible(inspeccion_del_gremio, multa) :-
    \+ en_zona(taberna), \+ en_zona(cuevas), hay_queso(rancio).
evento_posible(inspeccion_del_gremio, sello) :-
    \+ en_zona(taberna), \+ en_zona(cuevas),
    hay_queso(curado), \+ hay_queso(rancio).
evento_posible(rata_en_la_despensa, unico) :-
    ( en_zona(aldea) ; en_zona(bosque) ), queso_total(Q), Q >= 3.
evento_posible(silencio_vendido, unico) :-
    en_zona(taberna), activo(rufino), \+ esta_en_huelga(rufino).
evento_posible(balada_espontanea, unico) :-
    \+ en_zona(taberna), activo(rufino), \+ esta_en_huelga(rufino),
    queso_total(Q), Q >= 1.
evento_posible(tuerca_encuentra, discreto) :-
    activo(tuerca), \+ esta_en_huelga(tuerca),
    \+ en_zona(taberna), \+ en_zona(aldea).
evento_posible(tuerca_encuentra, pillado) :-
    activo(tuerca), \+ esta_en_huelga(tuerca), en_zona(aldea).
evento_posible(pimentina_prueba_seta, unico) :-
    en_zona(bosque), activo(pimentina).
evento_posible(moho_en_la_despensa, unico) :-
    ( en_zona(bosque) ; en_zona(cuevas) ), hay_queso(curado).
evento_posible(mesa_coja, unico) :-
    en_zona(taberna), activo(baldomero), queso_total(Q), Q >= 1.
evento_posible(regalo_del_ermitano, unico) :-
    en_zona(bosque), dia(D), D >= 3, \+ evento_visto(regalo_del_ermitano, _).
evento_posible(visita_de_pecorino, sermon) :-
    ( en_zona(camino_real) ; en_zona(castillo) ), contratos_cumplidos(0).
evento_posible(visita_de_pecorino, saludo) :-
    ( en_zona(camino_real) ; en_zona(castillo) ),
    contratos_cumplidos(N), N >= 1.
evento_posible(seta_cotilla, unico) :-
    en_zona(bosque), activo(rufino).
evento_posible(trebol_hallado, unico) :-
    ( en_zona(bosque) ; en_zona(camino_real) ), dia(D), D >= 5,
    \+ lleva(compania, trebol_de_cuatro_quesos, _), \+ evento_visto(trebol_hallado, _).
evento_posible(lluvia_de_suero, unico) :-
    member(Z, [aldea, bosque, camino_real, castillo]), en_zona(Z).
evento_posible(caballo_de_feria, solo) :-
    en_zona(camino_real), activo(baldomero), \+ activo(rufino).
evento_posible(caballo_de_feria, con_rufino) :-
    en_zona(camino_real), activo(baldomero),
    activo(rufino), queso_total(Q), Q >= 1.
evento_posible(charla_de_eustaquio, unico) :-
    en_zona(aldea),
    \+ contrato_cumplido(fantasma_charlatan), \+ contrato_activo(fantasma_charlatan).
evento_posible(gato_caido, unico) :-
    en_zona(aldea), activo(baldomero), \+ evento_visto(gato_caido, _).
evento_posible(cumple_de_un_queso, unico) :-
    queso(_, Edad, C), C > 0, categoria_queso(Edad, curado),
    Antes is Edad - 1, categoria_queso(Antes, fresco).
evento_posible(rufino_afonico, unico) :-
    activo(rufino), cantando(rufino).
```

Efectos y enfriamientos (días entre dos apariciones del mismo evento; los de una sola vez por partida se controlan con `evento_visto/2`):

```prolog
% eventos.pl (boceto sin ejecutar; forma abreviada, ver expandir/2 en 6.2)
efecto(ganso_peaje,            unico,       [quitar_queso(1)]).
efecto(inspeccion_del_gremio,  multa,       [quitar_queso(1)]).
efecto(inspeccion_del_gremio,  sello,       [moral(grupo, 1)]).
efecto(rata_en_la_despensa,    unico,       [quitar_queso_mas_fresco(1)]).
efecto(silencio_vendido,       unico,       [dar_queso(cheddar, 0, 2)]).
efecto(balada_espontanea,      unico,       [moral(grupo, 1), quitar_queso(1)]).
efecto(tuerca_encuentra,       discreto,    [dar_queso(cheddar, 0, 1)]).
efecto(tuerca_encuentra,       pillado,     [dar_queso(cheddar, 0, 1), moral(grupo, -1)]).
efecto(pimentina_prueba_seta,  unico,       [vida(pimentina, -2), moral(grupo, 1)]).
efecto(moho_en_la_despensa,    unico,       [envejecer_lote_mas_curado(2)]).
efecto(mesa_coja,              unico,       [quitar_queso(1), moral(baldomero, -1)]).
efecto(regalo_del_ermitano,    unico,       [dar_queso(queso_silvestre, 0, 1)]).
efecto(visita_de_pecorino,     sermon,      [moral(grupo, -1)]).
efecto(visita_de_pecorino,     saludo,      [moral(grupo, 1)]).
efecto(seta_cotilla,           unico,       [moral(rufino, -1)]).
efecto(trebol_hallado,         unico,       [dar_objeto(trebol_de_cuatro_quesos)]).
efecto(lluvia_de_suero,        unico,       [vida(grupo, 1), moral(grupo, -1)]).
efecto(caballo_de_feria,       solo,        [moral(baldomero, -1)]).
efecto(caballo_de_feria,       con_rufino,  [moral(baldomero, -1), quitar_queso(1)]).
efecto(charla_de_eustaquio,    unico,       [moral(grupo, -1)]).
efecto(gato_caido,             unico,       [vida(baldomero, -1), moral(baldomero, 1)]).
efecto(cumple_de_un_queso,     unico,       [moral(grupo, 1)]).
efecto(rufino_afonico,         unico,       [quitar_estado(rufino, cantando), moral(grupo, 1)]).

enfriamiento(ganso_peaje, 3).          enfriamiento(inspeccion_del_gremio, 5).
enfriamiento(rata_en_la_despensa, 4).  enfriamiento(silencio_vendido, 4).
enfriamiento(balada_espontanea, 3).    enfriamiento(tuerca_encuentra, 5).
enfriamiento(pimentina_prueba_seta, 6).enfriamiento(moho_en_la_despensa, 3).
enfriamiento(mesa_coja, 4).            enfriamiento(visita_de_pecorino, 6).
enfriamiento(seta_cotilla, 6).         enfriamiento(lluvia_de_suero, 7).
enfriamiento(caballo_de_feria, 5).     enfriamiento(charla_de_eustaquio, 5).
enfriamiento(rufino_afonico, 5).       enfriamiento(cumple_de_un_queso, 1).
% regalo_del_ermitano, trebol_hallado y gato_caido: una sola vez (condicion evento_visto/2)
```

### 6.4 Textos y efectos

Clave de cada texto: `evento(Id, Desenlace)`. Se imprimen sin prefijo `Narrador:` (≤ 210 caracteres).

| Id | Alc | Evento / desenlace | Texto | Efecto | ¿Repetible? |
|---|---|---|---|---|---|
| EV01 | X† | `ganso_peaje` | Un Ganso Recaudador te corta el paso, te extiende un recibo y se queda con un queso. El recibo, hay que reconocerlo, es precioso. | Queso −1 | Sí, cada 3 días |
| EV02a | X | `inspeccion_del_gremio` / `multa` | Un inspector del Gremio de Afinadores olfatea tu despensa, alza la lupa y dicta una multa de olor: un queso. No cabe apelación; sí cabe asco. | Queso −1 | Sí, cada 5 días |
| EV02b | X | `inspeccion_del_gremio` / `sello` | El inspector del Gremio examina tu despensa con la lupa y estampa un sello de curado. Sonríe por primera vez en lo que va de carrera. | Moral del grupo +1 | Sí, cada 5 días |
| EV03 | O | `rata_en_la_despensa` | Una rata quesera se lleva un queso de la despensa sin despertar a nadie. Se ha llevado el más fresco; tiene criterio. | Queso −1 (el más fresco) | Sí, cada 4 días |
| EV04 | X | `silencio_vendido` | Un cliente de la taberna paga a Rufino unos quesos para que deje de afinar el laúd. Rufino acepta el trabajo con lágrimas en los ojos. | Queso +2 (cheddar fresco) | Sí, cada 4 días |
| EV05 | X | `balada_espontanea` | Rufino arranca una balada espontánea por el camino. El grupo se anima; los pájaros, no. Callarlo cuesta un queso. | Moral del grupo +1; queso −1 | Sí, cada 3 días |
| EV06a | O | `tuerca_encuentra` / `discreto` | Tuerca vuelve con un queso en la mano. Dice que lo ha encontrado. Nadie pregunta dónde, que es justo lo que él quería. | Queso +1 (cheddar fresco) | Sí, cada 5 días |
| EV06b | O | `tuerca_encuentra` / `pillado` | Tuerca vuelve con un queso. En la aldea varios vecinos sí preguntan de dónde lo ha sacado, y la Banda lo paga en reputación. | Queso +1; moral del grupo −1 | Sí, cada 5 días |
| EV07 | X | `pimentina_prueba_seta` | Pimentina prueba una seta del camino. Sabe a gloria y le deja la lengua morada. La seta tenía opiniones. | Vida de Pimentina −2; moral +1 | Sí, cada 6 días |
| EV08 | O | `moho_en_la_despensa` | El moho se cuela en la despensa y le echa unos días encima a tu queso más curado. Se disculpa en voz baja. | Lote más curado, edad +2 | Sí, cada 3 días |
| EV09 | O | `mesa_coja` | Sir Baldomero apoya el codo en la mesa coja. La mesa cede y Doña Mantecosa cobra un queso. El codo sale gratis. | Queso −1; moral de Baldomero −1 | Sí, cada 4 días |
| EV10 | X | `regalo_del_ermitano` | Hermano Penicilio sale de entre los hongos y te regala un queso silvestre. Dice que se lo ha dado el moho, que quiere caerte bien. | Queso silvestre +1 | No |
| EV11a | X† | `visita_de_pecorino` / `sermon` | El Capitán Pecorino da un sermón sobre disciplina. Dura lo que una guardia entera y no contiene una sola idea útil. | Moral del grupo −1 | Sí, cada 6 días |
| EV11b | X† | `visita_de_pecorino` / `saludo` | El Capitán Pecorino te saluda con un gesto casi imperceptible. En su idioma, eso es un abrazo. | Moral del grupo +1 | Sí, cada 6 días |
| EV12 | X | `seta_cotilla` | Una Seta Chismosa susurra que Rufino no sabe leer música. Rufino jura que sí. El resto de la Banda ya no lo tiene tan claro. | Moral de Rufino −1 | Sí, cada 6 días |
| EV13 | X† | `trebol_hallado` | Entre la hierba brilla un trébol de cuatro hojas con forma de queso. Nadie explica nada, y tampoco hace falta. | Objeto: Trébol de Cuatro Quesos | No |
| EV14 | X | `lluvia_de_suero` | Llueve suero lácteo. Huele raro, alimenta un poco y deja a todos con el ánimo pegajoso. | Vida del grupo +1; moral −1 | Sí, cada 7 días |
| EV15a | X | `caballo_de_feria` / `solo` | Un caballo de feria pasa trotando, inofensivo y feliz. Sir Baldomero se esconde detrás de un barril que no es lo bastante ancho. | Moral de Baldomero −1 | Sí, cada 5 días |
| EV15b | X | `caballo_de_feria` / `con_rufino` | Un caballo de feria pasa trotando. Sir Baldomero se esconde tras Rufino, que ya compone «La balada del escondite». Baldomero paga un queso para que no la cante. | Moral de Baldomero −1; queso −1 | Sí, cada 5 días |
| EV16 | X† | `charla_de_eustaquio` | Eustaquio, el fantasma charlatán, te cuenta cómo murió esperando su cena. Dura tres horas y tiene digresiones. | Moral del grupo −1 | Sí, cada 5 días, hasta cumplir el contrato |
| EV17 | X† | `gato_caido` | Un gato cae de un árbol justo sobre Sir Baldomero. Desde ahora es héroe de la aldea; el gato, también. | Vida de Baldomero −1; moral de Baldomero +1 | No |
| EV18 | O | `cumple_de_un_queso` | Un queso de la despensa entra hoy en su mejor edad. Pimentina propone brindar con él, que sería gastarlo. | Moral del grupo +1 | Sí (ocurre solo el día en que madura un lote) |
| EV19 | X | `rufino_afonico` | Rufino se queda sin voz por culpa de su propia balada. El grupo lo celebra en silencio, que es la única forma de celebrarlo. | Quita el estado `cantando`; moral del grupo +1 | Sí, cada 5 días |

Leyenda de **Alc**: `O` = los 5 eventos del objetivo (6 textos); `X` = extra; `X†` = extra que además **solapa con un evento de campaña de 04** (06 X-52) y no se activa a la vez que él. Los efectos netos de los eventos son de unos ±5 quesos por partida (06 §2.3) y no desequilibran la economía de 04 §9.2. Texto y efecto deben revisarse juntos si cambia una cifra (las frases dicen "un queso").

---

## 7. Formato técnico del banco de frases

### 7.1 El hecho `frase/3`

La forma exacta es

```prolog
frase(+Clave, +Nivel, +Plantilla)
```

- **`Clave`**: el término al que se asocia la frase (sección 7.2). Puede tener variables.
- **`Nivel`**: `resumido`, `detallado` o `ambos`. En las tablas, `R`, `D` y `A`.
- **`Plantilla`**: o bien un átomo con el texto completo, o bien un par `Formato-Args`, donde `Formato` es un átomo con marcas `~w` y `Args` es la lista de variables de la clave que rellenan esas marcas, **en orden**. Es la misma convención de las tablas del banco: las variables con nombre de la clave, de izquierda a derecha; `_` para las que no se muestran.

`frase/3` es un hecho **estático** (06 X-06, D-25): no es `dynamic`, ningún módulo hace `assert`/`retract` sobre él y el narrador lo llama directamente (no hace falta `clause/2`). Todo el texto visible, incluido el de 01 y 04, se guarda en este mismo almacén (D-27). El archivo es `narrador.pl`; si pasa de unas 300 líneas se separa en `frases.pl` (solo datos), no antes.

Declaraciones obligatorias del fichero de datos:

```prolog
% boceto sin ejecutar
:- encoding(utf8).
:- discontiguous frase/3.
% sin :- dynamic frase/3 (el narrador es puro; los contadores viven en estado)
```

Ejemplos reales (conversión directa de cuatro filas del banco):

```prolog
% boceto sin ejecutar
frase(puede_atacar(baldomero, E), ambos,
      'Sir Baldomero golpea a ~w. Fue la primera vez en una semana que no le temblaron las rodillas.'-[E]).

frase(impide(teme(baldomero, caballo)), ambos,
      'Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.').

frase(suceso(golpe(fuerte, A, B, D)), ambos,
      '~w descarga un golpazo sobre ~w: ~w puntos. Hasta el reglamento se ha sobresaltado.'-[A, B, D]).

frase(generica(exito), ambos,
      'Todo conforme al reglamento. En esta compañía, eso es una noticia.').
```

Compatibilidad con el canon (que muestra `frase/2` en §12): `frase(Clave, Texto) :- frase(Clave, ambos, Texto).` se puede añadir para consultas sencillas.

### 7.2 Formas de la clave

| Forma | Se usa cuando… | Ejemplo |
|---|---|---|
| `Meta` | `explicar` muestra un nodo demostrado (marcado `[ok]` en el árbol ASCII): el comentario va asociado a esa meta. | `puede_atacar(baldomero, E)` |
| `falla(Meta)` | `por_que_no` encuentra un subobjetivo positivo que no se puede demostrar (diagnósticos `fallo/2` y `sin_clausula/1`). | `falla(puede_viajar(Z))` |
| `impide(Hecho)` | `por_que_no` encuentra una negación `\+` que falla porque `Hecho` es cierto (diagnóstico `neg_viola/2`: `Hecho` sale de su prueba). | `impide(teme(baldomero, caballo))` |
| `suceso(Termino)` | El juego narra algo que no es una prueba (combate, viaje, economía, errores). | `suceso(golpe(normal, A, B, D))` |
| `evento(Id, Desenlace)` | Texto de un evento cómico (sección 6). | `evento(mesa_coja, unico)` |
| `gag(Id)` | Coletilla de un chiste recurrente (sección 3). | `gag(caballo)` |
| `generica(Tipo)` | Reserva cuando una clave no tiene frase (sección 7.5). | `generica(sin_prueba)` |
| `texto(Tipo)` | Texto visible que no es comentario (D-27): `texto(dialogo(Npc, Tema))`, `texto(consejo(Id))`, `texto(final(Id))`, `texto(zona(Id))`. Se guardan aquí y los datos de 01 y 04 apuntan a la clave. No se cuentan en 7.7. | `texto(final(chapuza))` |

Las variables de una clave se unifican con los argumentos reales de la meta. Una clave más específica (con menos variables libres) gana a otra más general. Un átomo de tipo de enemigo en la clave (`rata_quesera`) casa con la instancia `e(rata_quesera, 1)` de la meta (`casa/2`, sección 5.4).

### 7.3 Niveles `resumido` y `detallado`

Los niveles son los del comando `nivel(resumido ; detallado)` de `explicar`.

| Nivel | Qué muestra el narrador |
|---|---|
| `resumido` | **Una sola frase** de cierre: la de la meta raíz (o la primera meta del árbol con frase propia). Sin coletilla. Cabe en las 15 líneas del criterio de aceptación. |
| `detallado` | La frase de cierre, **hasta tres comentarios de nodo** colgados bajo las líneas del árbol (frases de nivel `D` o `A` de los nodos más específicos) y, si procede, **una coletilla**. |

Una frase marcada `D` (por ejemplo, `X07`, `X09`, `G03`) **solo** sale en el nivel detallado y debe ser corta (≤ 100 caracteres) porque se pega al árbol. Una frase `A` sirve para ambos niveles.

### 7.4 Algoritmo de selección y traductor de diagnósticos

**`explicar(Accion)` con prueba:**
1. Buscar frase para la meta raíz (clave `Meta`). Si no hay, recorrer el árbol en preorden y tomar la primera meta con frase propia (`meta_de_prueba/2`, abajo).
2. Si no hay ninguna en todo el árbol, usar `generica(exito)`.
3. En `detallado`, añadir hasta tres comentarios de nodo y una coletilla (sección 3.4).

**`por_que_no(Accion)` sin prueba (06 X-21):** el diagnóstico de 02 §6.9 se convierte en claves con `clave_de_diag/2`, que devuelve las claves candidatas **de la causa más profunda a la raíz**; se usa la primera que tenga frase.

| Diagnóstico (02 §6.9) | Claves que produce, en orden |
|---|---|
| `neg_viola(X, Prueba)` | `impide(H)` para cada `H` de la prueba de `X`, en preorden (el primer hecho o regla con frase gana; por eso `teme(baldomero, caballo)` y `rasgo(baldomero, teme_caballos)` tienen frase propia) |
| `fallo(G, [cl(_, _, punto(F, D)) \| _])` | las del diagnóstico anidado `D`, luego `falla(F)` (si `F` no es una negación) y, al final, `falla(G)` de la meta; solo se mira la candidata más cercana |
| `tras(_, D)` | las de `D` (el fallo está en el segundo conjuntivo) |
| `sin_clausula(G)` | `falla(G)` |
| `builtin_falso(_)`, `limite(_)` | ninguna (se salta a la clave `falla(...)` de la regla padre; por eso hay `falla(puede_habilidad(pimentina, _))` y no una frase para `Q >= N`) |

Si ninguna clave tiene frase: `generica(impide)` (si hubo `neg_viola`) o `generica(fallo)`. Una condición de contrato llega envuelta en `condicion_cumple(C)`: el traductor prueba `falla(condicion_cumple(C))` y luego `falla(C)`. Los objetivos llegan sin calificar con módulo (`strip_module/3` los pela).

```prolog
% narrador.pl (boceto; probado en 5.10.4 con diagnosticos de ejemplo)
claves_de_diag(neg_viola(_, Prueba), Cs) :-
    findall(impide(H), meta_de_prueba(Prueba, H), Cs).
claves_de_diag(tras(_, D), Cs) :-
    claves_de_diag(D, Cs).
claves_de_diag(sin_clausula(G0), Cs) :-
    strip_module(G0, _, G), claves_falla(G, Cs).
claves_de_diag(builtin_falso(_), []).
claves_de_diag(limite(_), []).
claves_de_diag(fallo(G0, [cl(_, _, punto(F, D)) | _]), Cs) :-
    strip_module(G0, _, G),
    claves_de_diag(D, Hondas),
    (   F = (\+ _) -> Propias = [] ; claves_falla(F, Propias) ),
    append(Hondas, Propias, Cs0),
    append(Cs0, [falla(G)], Cs).

claves_falla(condicion_cumple(C), [falla(condicion_cumple(C)), falla(C)]) :- !.
claves_falla(G, [falla(G)]).

% meta_de_prueba(+Prueba, -Meta): hechos y reglas de la prueba, en preorden
meta_de_prueba(hecho(G), G).
meta_de_prueba(regla(G, _, Hijos), M) :-
    (   M = G
    ;   member(H, Hijos), meta_de_prueba(H, M)
    ).

comentario_diag(Diag, Nivel, Ctx, Texto, Efectos) :-
    claves_de_diag(Diag, Claves),
    (   member(Clave, Claves),
        comentario(Clave, Nivel, Ctx, Texto, Efectos)    % la primera con frase
    ->  true
    ;   Diag = neg_viola(_, _)
    ->  comentario(generica(impide), Nivel, Ctx, Texto, Efectos)
    ;   comentario(generica(fallo), Nivel, Ctx, Texto, Efectos)
    ).
```

Con el diagnóstico de `por_que_no(atacar(baldomero, bandido_montado))` (una `fallo/2` cuyo punto es la negación `\+ (teme(...), clase(...))` y cuya prueba contiene `teme(baldomero, caballo)`), la lista es `[impide(teme(baldomero, caballo)), impide(rasgo(baldomero, teme_caballos)), ..., falla(puede_atacar(baldomero, e(bandido_montado, 1)))]` y gana `F01a`. Con `aceptar(gallina_noble)` y Baldomero en la compañía, la prueba de la negación de `rasgo_no` trae `rasgo(baldomero, teme_caballos)` y gana `F10b` (06 X-37). Estas dos y las claves `F02e`, `F05`, `F06` y `F07` son el conjunto de prueba de `clave_de_diag/2` (sección 7.6); hay que escribirlo **antes de T-15** (semana 2).

**Casos límite:**
- `explicar` sobre algo que no se puede demostrar: `generica(sin_prueba)`.
- `por_que_no` sobre algo demostrable: `generica(sin_fallo)`.
- **Sucesos** (`suceso(...)`, `evento(...)`): si no hay frase, **no se imprime nada** (es mejor el silencio que una frase genérica en medio de una narración). Con un indicador de depuración, se avisa con `[sin frase: Clave]`.

### 7.5 Frases genéricas de reserva y formato del texto

| Clave genérica | Cuándo sale |
|---|---|
| `generica(exito)` | `explicar` con prueba y ninguna frase específica. |
| `generica(fallo)` | `por_que_no` sin frase específica. |
| `generica(hecho)` | Nodo `[hecho]` sin frase (solo `detallado`). |
| `generica(regla)` | Nodo `[regla]` sin frase (solo `detallado`). |
| `generica(negacion)` | Nodo de negación que se cumple (`\+` verdadero) sin frase. |
| `generica(impide)` | Negación que falla sin frase propia. |
| `generica(predefinido)` | Nodo `[predefinido]` (aritmética) sin frase. |
| `generica(sin_prueba)` | `explicar` de una acción que no se puede demostrar. |
| `generica(sin_fallo)` | `por_que_no` de una acción demostrable. |

Cada genérica tiene al menos una variante (ver G01 a G08), neutra y corta: **si salen a menudo, falta cobertura**, y la prueba de cobertura lo señala.

**Nombres visibles y artículos.** Los `Args` pasan por `nombre_visible/2` antes de rellenar las marcas. Los nombres de enemigos, zonas, objetos y quesos llevan su artículo; los de personajes, no. Después, el texto pasa por `contraer/2` ("a el" → "al", "de el" → "del") y se pone en mayúscula la primera letra.

```prolog
% narrador.pl (boceto; formatear/2 y contraer/2 se ejecutaron en 5.10.4)
nombre(baldomero,      'Sir Baldomero').
nombre(rata_quesera,   'la Rata Quesera').
nombre(gran_roquefort, 'el Gran Roquefort').
nombre(camino_real,    'el Camino Real').
nombre(cuevas,         'las Cuevas del Roquefort').
nombre(cheddar,        'el cheddar').
nombre(pocion,         'la Poción de Suero Lácteo').

nombre_visible(Id, Texto) :-
    (   Id = e(Tipo, _) -> nombre_visible(Tipo, Texto)   % instancia de enemigo (06 X-19)
    ;   nombre(Id, T)   -> Texto = T
    ;   Texto = Id                                        % números y desconocidos pasan tal cual
    ).
% Con varias instancias del mismo tipo vivas ("el Bandido Torpe (2)"), juego pasa en Ctx la
% lista de tipos repetidos y la variante nombre_visible(+Id, +Repetidos, -Texto) añade ' (N)'.
% Esa variante es un boceto sin ejecutar.

formatear(Formato-Args, Texto) :- !,
    maplist(nombre_visible, Args, Visibles),
    format(atom(Crudo), Formato, Visibles),
    contraer(Crudo, Contraido),
    mayuscula_inicial(Contraido, Texto).
formatear(Texto0, Texto) :-
    mayuscula_inicial(Texto0, Texto).

contraer(Crudo, Texto) :-
    sustituir(Crudo, ' a el ', ' al ', T1),
    sustituir(T1,    ' de el ', ' del ', T2),
    sustituir(T2,    'A el ',   'Al ',   T3),
    sustituir(T3,    'De el ',  'Del ',  Texto).

sustituir(Entrada, De, A, Salida) :-
    atomic_list_concat(Partes, De, Entrada),
    atomic_list_concat(Partes, A, Salida).

mayuscula_inicial(T0, T) :-
    sub_atom(T0, 0, 1, _, P), upcase_atom(P, U),
    sub_atom(T0, 1, _, 0, Resto),
    atom_concat(U, Resto, T).
```

**Codificación y símbolos (D-26, O-6 de 06 §2.8).** Hay dos reglas separadas:
- **Símbolos del árbol en ASCII** (`[ok]`, `[no]`, `\-`, `|-`), no `✔ ✘ ├─ └─`: con la codificación por defecto de 5.10.4 esos símbolos salen degradados (el primero sale como `✔`, el segundo como `+-`). El narrador no emite ninguno; los pone `arbol`/`ui` (02 §6.11), con `ajuste(ascii, Bool)` para forzarlos.
- **Texto en UTF-8** (tildes, `¿`, `«»`). Los ficheros de frases se guardan en UTF-8 y empiezan por `:- encoding(utf8).`, y `ui:iniciar/0` ejecuta `set_stream(user_output, encoding(utf8))` (comprobado al redirigir a un archivo en 5.10.4). Falta comprobar la **consola de Windows** de la entrega, con y sin `chcp 65001` (V-06 de 06 §7.2) en la semana 1; hasta entonces es un riesgo. Plan B si V-06 falla: un traductor de presentación en `ui` (`a_ascii/2`: sin tildes, `« »` a comillas rectas) activado con `ajuste(ascii, true)`, sin tocar el banco.

Dentro de un átomo entre comillas simples no se usa el apóstrofo ni el carácter `~` (salvo `~w`). Todo el texto son átomos con comillas simples; nunca cadenas con comillas dobles, que en 5.10.4 son listas de códigos (06 O-5).

### 7.6 Pruebas y cobertura

Pruebas plunit del módulo del narrador (`tests/test_narrador.pl`, parte de `tests/todas.pl`; orden `swipl -q -g run_tests -t halt tests/todas.pl`, con el ejecutable de `C:\Program Files\pl\bin`, fuera del PATH; el código de salida al fallar está pendiente de comprobar, V-04 de 06 §7.2):

| Prueba | Qué comprueba |
|---|---|
| `placeholders_coinciden` | Para cada `frase/3`, el número de `~w` coincide con la longitud de `Args`, y `Args` son variables de la clave. |
| `claves_validas` | Todo identificador que aparezca en una clave (`baldomero`, `camino_real`, `rata_quesera`…) existe en el índice del lore (`id_valido/1`); detecta renombrados. |
| `claves_de_diag` | `clave_de_diag/2` produce la clave esperada para los diagnósticos de las 6 claves del núcleo (F01, F02e, F05, F06, F07, F10b), construidos a mano con el formato de 02 §6.9. |
| `longitud` | Cada texto, con `~w` de nombre = 20 y de cifra = 3, cabe en 135 caracteres (70 coletillas; 100 nivel `D`; 210 eventos, inicio y fin). |
| `sin_duplicados` | No hay dos textos idénticos. |
| `variantes_minimas` | Las claves de la lista `alta_frecuencia/1` (ataques, daño, fallos de habilidad, huelga, golpes) tienen al menos dos variantes **en el nivel objetivo**; la versión mínima puede tener una sola (aviso, no error). |
| `genericas_completas` | Existen todas las claves `generica/1` de la tabla 7.5. |
| `cobertura_reglas` | Cada predicado de `reglas_explicables/1` tiene frase de éxito o de fallo (ver tabla de cobertura). Aviso si baja del 70 %, error si baja del 50 %. |
| `logica_sin_texto` | Sustituye a `sin_frases_la_logica_no_cambia` (el banco ya no es `dynamic`, no se puede vaciar): `juego:ejecutar/2` devuelve solo `msg/2`, `prueba/2`, `diag/2` y datos (ningún átomo de texto del banco), y los módulos de reglas no importan `narrador` (solo `ui`). Criterio de F-24. |
| `rotacion_no_repite` | Dos narraciones seguidas de la misma clave con N ≥ 2 no devuelven el mismo texto: se llama a `comentario/5` con `ctx(1, [])`, se aplica el efecto `usar_frase(G)` a la lista de contadores a mano y se vuelve a llamar. Sin estado ni modo global. |
| `semilla_reproducible` | `evento_del_dia/3` con la misma semilla produce la misma secuencia de eventos en dos ejecuciones (V-09 de 06). |

Boceto de las pruebas centrales:

```prolog
% boceto sin ejecutar
:- begin_tests(narrador).

test(placeholders_coinciden) :-
    \+ ( frase(_, _, P),
         partes_plantilla(P, Formato, Args),
         contar_marcas(Formato, N),
         length(Args, M),
         N \== M ).

test(cobertura_reglas) :-
    reglas_explicables(Reglas),
    findall(R, ( member(R, Reglas), tiene_frase(R) ), Cubiertas),
    length(Reglas, Total), length(Cubiertas, Ok),
    Ok * 100 >= 70 * Total.

test(rotacion_no_repite) :-
    Meta = puede_atacar(baldomero, rata_quesera),
    comentario(Meta, resumido, ctx(1, []), T1, [usar_frase(G)]),
    comentario(Meta, resumido, ctx(1, [uso(G)-1]), T2, _),
    T1 \== T2.                                   % requiere al menos 2 variantes (objetivo)

test(clave_de_diag_f01) :-
    Diag = fallo(puede_atacar(baldomero, e(bandido_montado, 1)),
                 [cl(1, [], punto(\+ (teme(baldomero, C), clase(bandido_montado, C)),
                       neg_viola((teme(baldomero, C), clase(bandido_montado, C)),
                                 regla(teme(baldomero, caballo), 1,
                                       [hecho(rasgo(baldomero, teme_caballos))]))))]),
    claves_de_diag(Diag, [impide(teme(baldomero, caballo)) | _]).

:- end_tests(narrador).

tiene_frase(P/A) :-
    functor(Cabeza, P, A),
    (   frase(Cabeza, _, _)
    ;   frase(falla(Cabeza), _, _)
    ;   frase(impide(Cabeza), _, _)
    ),
    !.

reglas_explicables([ puede_atacar/2, dano/3, modificador/3, en_fila_alcanzable/2,
                     vivo/1, ignora_miedo/1, esta_en_huelga/1, aturdido/1, teme/2,
                     puede_combatir/1, permite_combate/1, puede_habilidad/2,
                     puede_viajar/1, puede_descansar/0, puede_aceptar/1,
                     puede_comer/2, categoria_queso/2, valor_queso/3,
                     accion_enemigo/2, puede_pagar_sueldos/0 ]).
```

La lista `reglas_explicables/1` ya no contiene `avanzar_dia/0` (no es una meta explicable, 06 X-20) y sí `puede_comer/2`, `permite_combate/1` y `puede_combatir/1` (que antes compartían nombre, 06 X-14).

**Cobertura mínima obligatoria.** Cada fila indica la regla o el hecho explicable y las frases del banco que lo cubren. La meta es que **todas** tengan frase propia y que el conjunto de `reglas_explicables/1` llegue al 70 % exigido en el apartado 8.3 de `03-funcionalidades-y-etapas.md`. La columna Alc dice a partir de qué versión está cubierta cada regla con frase propia; una regla sin frase en la mínima cae a la genérica (G01 a G08), que sí está en la mínima.

| Regla o hecho explicable | Éxito / fallo | Frases del banco | Alc |
|---|---|---|---|
| `puede_atacar/2` (cuatro miembros y caso general) | éxito | X01 a X05 | M (X01a, X05a) |
| `vivo/1`, `en_fila_alcanzable/2` | éxito y fallo | X06, X07, F04, F05 | M (F05a) |
| `dano/3`, `modificador/3`, `ignora_miedo/1` | éxito | X08 a X11 | M (X08a) |
| Rasgo `teme_caballos` (`teme/2` + `clase/2`) | fallo | F01, F10b | M (F01a, F10b) |
| `esta_en_huelga/1` | fallo | F02, E15, E16 | M (F02e, E15a, E16) |
| `aturdido/1` | fallo | F03 | M (F03a) |
| `puede_habilidad/2`, `queso_total/1` | éxito y fallo | X12 a X14, F06, F11 a F13 | M (X12a, F06a) |
| `puede_viajar/1` | éxito y fallo | X15, X16, F07, V07, V08 | M (X15a, X16, F07a, V07a, V08a) |
| `puede_descansar/0`, `permite_combate/1` | éxito y fallo | X18, F08, F09, F16, D01 | M (F09a, X18, F08a, D01a) |
| `puede_aceptar/1` y sus condiciones | éxito y fallo | X17, F10 | M (X17a, F10a, F10b) |
| `puede_comer/2` | éxito y fallo | X21, F17, E09 | O |
| Resolución de contratos | suceso | K01 a K12 | M (K01a, K02a); resto O/X |
| `categoria_queso/2`, `valor_queso/3`, maduración | éxito | E01 a E07 | M (E01a, E02a, E03a) |
| Ración, hambre | suceso | E08, E10, E11, E17 | M (E08a, E10a, E11a) |
| `puede_pagar_sueldos/0` y pago | éxito y fallo | X19, E13, E14, E18 | M (X19, E13a, E14a, E18) |
| `accion_enemigo/2` | éxito | X20 | M (X20j); específicas O/X |
| Usar objeto, huir | suceso y fallo | C14, F14, C18 | O/X |
| Inicio y fin de partida | suceso | I01 a I05 | M (I01a, I02a, I03a, I03b, I04) |
| Genéricas de reserva | reserva | G01 a G08 | M |

### 7.7 Resumen de cifras del banco

Recuento hecho **por script** sobre las tablas de este documento (columna Alc de cada fila; 2 de noviembre de 2026), no a ojo. "Mínima", "Objetivo" y "Extra" cuentan las filas con `M`, `O` y `X` respectivamente; el alcance acumulado del objetivo es mínima + objetivo.

| Categoría | Prefijo | Mínima | Objetivo | Extra | Filas |
|---|---|---|---|---|---|
| Explicaciones de éxito | X | 10 | 15 | 22 | 47 |
| Explicaciones de fallo | F | 10 | 10 | 15 | 35 |
| Combate | C | 12 | 4 | 33 | 49 |
| Economía | E | 11 | 3 | 26 | 40 |
| Viaje | V | 8 | 0 | 7 | 15 |
| Descanso | D | 1 | 0 | 3 | 4 |
| Taberna | T | 0 | 0 | 8 | 8 |
| Ayuda y errores | A | 4 | 0 | 13 | 17 |
| Inicio y fin | I | 5 | 0 | 5 | 10 |
| Contratos | K | 2 | 1 | 13 | 16 |
| Genéricas | G | 9 | 0 | 4 | 13 |
| **Total del banco (sección 4)** | | **72** | **33** | **149** | **254** |
| Coletillas de gags (sección 3.2) | R | 0 | 10 | 27 | 37 |
| Textos de eventos (sección 6.4) | EV | 0 | 6 | 17 (11 + 6 con `†`) | 23 |

**Cifras frente a 06 §5.1.**

| | Mínima | Objetivo (acumulado) | Todo lo diseñado |
|---|---|---|---|
| Frases del banco (sección 4) | **72** (≈ 70 de 06: las 32 del núcleo de 8.4 más viaje, combate básico, hambre, sueldos, inicio, fin, ayuda y contratos genéricos) | 105 | 254 |
| Con coletillas y textos de evento | 72 | **121** (≈ 120 de 06: 105 + 10 coletillas de 3 gags + 6 textos de 5 eventos) | 314 (254 + 37 + 23) |
| Gags | 0 | 3 | 12 |
| Eventos aleatorios | 0 | 5 | 19 (5 de ellos con `†`) |

Cambios de recuento respecto a la v0.1 (253 filas): se retiran `F08b` y `T02` (06 D-15) y se añaden `X21`, `F16` y `F17`, con lo que el banco pasa de 253 a **254** filas. El recuento por script de las tablas de la v0.1 daba 253 filas (X = 46), igual que lo declarado; **no se reproduce** la discrepancia de 254 y X = 47 que cita 06 X-55 (la fila extra de ese recuento puede ser la plantilla de conversión de 8.2, que repite `X04`). Los textos `texto(...)` de 01 y 04 (D-27) no están en estas cifras.

---

## 8. Guía de edición

### 8.1 Lista de verificación para aceptar un chiste

Los puntos 1 a 4 y 8 a 9 son **obligatorios**; del resto hay que cumplir al menos cinco.

1. **Claridad.** Se entiende a la primera lectura, sin conocer el resto del juego.
2. **Verdad.** No contradice el árbol, el estado ni los datos de la pantalla.
3. **Brevedad.** Cabe en 135 caracteres (con `~w` de nombre = 20) y tiene una sola idea.
4. **Coherencia con el lore.** Usa los nombres e ids del índice y respeta las leyes cómicas (lore §8).
5. **Estructura distinta** a la de las tres frases anteriores del mismo grupo (no otro "X, pero Y").
6. **Remate al final.** La palabra que hace gracia es la última.
7. **Sin cifras de balance** escritas a mano: los números van como `~w`.
8. **Sin referencias externas ni burlas a grupos reales** (sección 9).
9. **El sarcasmo no apunta al jugador.**
10. **Se lee bien en voz alta** y en 80 columnas.
11. **Neutral en género** respecto al jugador.
12. **Funciona sin haber visto otro chiste** (las coletillas son la única excepción).
13. **Las marcas `~w` coinciden** con las variables de la clave.

### 8.2 Cómo ampliar el banco sin tocar la lógica

1. Elegir la **clave** adecuada de la sección 7.2 y comprobar que los ids que contiene existen en el índice del lore.
2. Revisar si ya hay variantes para esa clave; la meta son **dos o tres** (más solo si la situación es muy frecuente).
3. Escribir la frase y pasar la lista de verificación 8.1.
4. Añadir el hecho `frase/3` **al final del bloque de su categoría** en el fichero de frases. No se crea ningún predicado nuevo, no se toca el módulo del narrador ni ninguna regla del juego.
5. Ejecutar `swipl -q -g run_tests -t halt tests/todas.pl` (con el ejecutable de 5.10.4 en `C:\Program Files\pl\bin`, fuera del PATH): las pruebas de placeholders, claves, longitud y duplicados detectan los errores comunes.
6. Jugar la situación una vez y leer la frase en la terminal.
7. Anotar en la columna **Alc** de este documento si la frase nueva es `M`, `O` o `X` y recontar con el script (sección 7.7).

Plantilla de conversión de una fila de la tabla a un hecho:

```
| X04 | A | `puede_atacar(tuerca, E)` | Tuerca ataca a ~w por el flanco. … |
```
```prolog
% boceto sin ejecutar
frase(puede_atacar(tuerca, E), ambos,
      'Tuerca ataca a ~w por el flanco. Nadie lo ve llegar, y tampoco lo ven irse, que es lo importante.'-[E]).
```

### 8.3 Si cambia una regla o un número

- **Se renombra un predicado:** cambiar la clave de sus frases; la prueba `claves_validas` y la de cobertura avisan.
- **Cambia un valor de balance:** como las frases no llevan cifras de balance, no pasa nada; los eventos sí mencionan "un queso" (sección 6): revisar su tabla.
- **Se elimina una funcionalidad** (por ejemplo, la huelga): sus frases se quedan sin uso; se borran en la misma tarea para que la cobertura no sea engañosa.

### 8.4 El núcleo mínimo: 32 frases, y la versión mínima completa: 72

Para cumplir F-24 (mínimo 30 frases propias) con margen, este es el núcleo que **no se recorta**:

`X01a`, `X05a`, `X08a`, `X12a`, `X15a`, `X16`, `X17a`, `F01a`, `F02e`, `F03a`, `F05a`, `F06a`, `F07a`, `F09a`, `F10a`, `F10b`, `E01a`, `E02a`, `E03a`, `E10a`, `E13a`, `E14a`, `E15a`, `G01a`, `G02a`, `G03`, `G04a`, `G04b`, `G05`, `G06`, `G07`, `G08`.

Con ellas, cualquier `explicar` o `por_que_no` sobre las reglas obligatorias tiene un comentario con gracia o, al menos, uno genérico.

**Versión mínima = 72 frases (06 D-21, §5.1).** El núcleo más 40 filas que cubren lo que 06 pide para ≈ 70: viaje, combate básico, hambre, sueldos, inicio y fin (y la ayuda y los contratos mínimos). Son las filas con `M` en la columna Alc:

| Grupo | Frases `M` añadidas al núcleo |
|---|---|
| Viaje (8) | `V01a`, `V02a`, `V03`, `V04a`, `V05`, `V06`, `V07a`, `V08a` |
| Combate básico (12) | `C01a`, `C02a`, `C02c`, `C03a`, `C07a`, `C08`, `C10a`, `C12a`, `C13`, `C15a`, `C16a`, `C17a` |
| Hambre, ración y descanso (4) | `E08a`, `E11a`, `D01a`, `F08a` |
| Sueldos y huelga (3) | `X19`, `E18`, `E16` |
| Inicio y fin (5) | `I01a`, `I02a`, `I03a`, `I03b`, `I04` |
| Ayuda y errores (4) | `A01a`, `A02a`, `A03a`, `A06a` |
| Contratos (2) | `K01a`, `K02a` |
| Explicaciones sueltas (2) | `X18`, `X20j` (el turno enemigo con corte, demostración central) |

**Nivel B (emergencia, 06 §5.2):** 50 frases = el núcleo de 32 más `V02a`, `V04a`, `V07a`, `V08a`, `C01a`, `C02a`, `C03a`, `C07a`, `C08`, `C15a`, `C17a`, `E08a`, `E11a`, `X19`, `E18`, `I01a`, `I03a`, `I03b`.

### 8.5 Plan de redacción por semana

Es una carga pequeña y repartida (el texto ya está escrito en este documento: se trata de convertir filas en hechos `frase/3`; la selección y los contadores son código de `narrador.pl` y `estado.pl`, ya contados en T-15 y en las tareas nuevas de 06 §5.3).

| Semana | Qué se convierte en hechos | Frases |
|---|---|---|
| S2 (9–13 nov) | Narrador mínimo (T-15) **precedido de `clave_de_diag/2`** (1 h, 06 §5.3): genéricas y las del primer `explicar` (economía y viaje). | `G01a`, `G02a`, `G03` a `G08`, `X15a`, `X16`, `E01a`, `E02a`, `E03a` |
| S3 (16–20 nov) | El ataque de la demo de DISENO §11.3 (con `D = 9`, 11 − 2, contra el `bandido_torpe`; 06 X-57). | `X01a`, `X05a`, `X08a`, `F01a` |
| S4 (23–27 nov) | `por_que_no` v1, contratos, `pagar` y descanso. | `F02e`, `F03a`, `F05a`, `F06a`, `F07a`, `F08a`, `F09a`, `F10a`, `F10b`, `X17a`, `X18`, `X12a`, `X19`, `E10a`, `E13a`, `E14a`, `E15a`, `E16`, `E18` |
| S5 (30 nov–4 dic) | T-30 (1,5 h): completar las 72 de la mínima (viaje, combate, hambre, inicio, fin, ayuda, contratos); pasar los textos de 01 y 04 a `texto(...)` (D-27); **solo si sobra holgura el 27 de noviembre**: las 33 del objetivo y los gags `caballo`, `registro` y `silencio`; los 5 eventos (T-34). | Mínima: 72. Objetivo: 105 (121 con coletillas y eventos) |
| S6 (7–11 dic) | Lectura en voz alta durante PT-2; recorte de lo que no hace gracia; ajuste de las variantes que ve la demo (la primera de cada grupo). | — |

### 8.6 Orden de recorte del humor

Alineado con el plan de recorte de `03-funcionalidades-y-etapas.md` §13.2 y con los niveles A y B de 06 §5. De primero a último:

1. Eventos cómicos (F-25): **ya están fuera de la mínima** (0); en el objetivo son 5 y se quitan los primeros si la holgura desaparece.
2. Todos los gags salvo `caballo`, `registro` y `silencio` (**ya fuera de la mínima y del objetivo**: solo están en el extra).
3. Terceras y cuartas variantes de cada grupo (las `b`, `c` y `d` son del objetivo o del extra).
4. Frases específicas por enemigo (`X20`, `C15d` a `C15i`) y por contrato (`K06` a `K11`); quedan las genéricas.
5. Coletillas (sección 3): el narrador sigue funcionando sin ellas.
6. Nivel B: de 72 a 50 frases (8.4).
7. **No se recorta nunca:** el núcleo de 32 frases (8.4) y las genéricas (G01 a G08).

---

## 9. Lo que no hacer

### 9.1 Humor que no encaja

| No | Por qué | En su lugar |
|---|---|---|
| Burlarse de grupos de personas reales (nacionalidades, religiones, cuerpos, condiciones, acentos). | Excluido por el lore §9.2. Pimentina puede ser refinada, pero no caricaturizada. | Burlarse de reglas, nobles inventados, oficios imaginarios o de la propia Banda. |
| Violencia gráfica o sangre. | Los combates son cómicos: los enemigos "caen", "huyen" o "se rinden". | Lo absurdo (el gólem pierde la gorra) en lugar de lo cruel. |
| Chistes escatológicos o de mal gusto explícito. | El hedor del queso rancio es el límite: huele, apesta, pega. | Sugerir el olor, no describirlo. |
| Humor a costa del jugador (por equivocarse, por perder, por usar mal un comando). | Contraría la regla de oro 6. | El error es del reglamento, del mapa o de la Banda. |
| Insistir en el hambre o la pobreza como algo triste. | Aquí el hambre es "de dibujos animados" y siempre tiene solución en queso. | Tratarla como un asunto burocrático (quejas formales, hojas de reclamaciones). |
| Palabrotas, insultos reales y sarcasmo agresivo. | Apto para todo público. | La ironía suave del narrador. |

### 9.2 Referencias externas

- **Nada del mundo real:** marcas, famosos, series, películas, juegos, videojuegos, canciones, políticos, noticias, memes.
- **Cuidado especial con los quesos:** hay sketches y canciones muy conocidos sobre tiendas de queso y quesos concretos. **No** se hacen guiños a ellos; los chistes salen de las reglas del propio juego.
- **No citar obras con derechos** ni parafrasear frases célebres. Las citas de los personajes («¡Por mi honor!») son suyas, no de otra obra.
- **Tampoco referencias a Prolog o a la asignatura** dentro de la narración: el narrador dice "reglamento", "acta" y "expediente"; los términos técnicos (`explicar`, `por_que_no`, cláusula) los pone la salida técnica, no el narrador.

### 9.3 Chistes que rompen las reglas del mundo

Una frase puede citar una ley; no puede violarla. Ejemplos de lo que **no** se puede escribir:

| Frase prohibida | Qué regla rompe |
|---|---|
| "Sir Baldomero ataca al caballo sin pensarlo." (sin venda) | Rasgo `teme_caballos` y regla `puede_atacar/2`. |
| "Pimentina lanza un hechizo con las manos vacías." | Ley del Cuajo: toda magia necesita queso. |
| "La Banda lucha un rato en la taberna." | Ley de la Taberna: dentro del local no se pelea. |
| "Viajas en un suspiro hasta el castillo." | Ley de la Ruta Pegajosa: moverse cuesta un día. |
| "Tiras el queso rancio a la basura y desaparece." | Ley del Hedor: el queso rancio no desaparece, se lanza. |
| "Los monstruos obligan a Rufino a pelear en huelga." | Ley de la Huelga Sagrada: nadie combate sin cobrar. |
| "Tu queso curado vale menos que el fresco." | Ley de la Maduración: el curado es el de máximo valor. |
| "Tienes tres quesos" cuando son dos. | La regla de oro 1 (la verdad antes que la broma); por eso los números van en `~w`. |
| "Compras queso en el mercado" o "vendes un queso curado por un buen precio". | Regla del queso (06 D-10): el queso no se compra ni se vende y no hay tienda; solo entra por recompensa, botín y hallazgos. |
| "Doña Mantecosa anota doce quesos en tu cuenta." | No existe la deuda de la taberna (06 D-15); además, las cifras van como `~w`. |
| Revelar al Gran Roquefort antes del final (nombre, cara o motivo). | Desinforma y estropea el hilo de la partida; solo aparece en `C02c`, `X20i` e `I02a`. |

### 9.4 Otras prohibiciones de estilo

- **Dos chistes del mismo tipo seguidos** (lore §9.2): si acaba de salir un juego de palabras con queso, la siguiente frase no lo es.
- **Frases que no aportan a una regla o a un texto de pantalla** (lore §9.2): un chiste suelto sin anclaje en el estado se queda fuera.
- **Exclamaciones en cadena, mayúsculas, emojis** y signos de risa.
- **Explicar el chiste**, o añadir "(es un chiste)" y similares.
- **Dar pistas tácticas o anunciar eventos** ("pronto aparecerá un jinete").
- **Hacer depender un chiste de un gag anterior** que el jugador puede no haber visto (solo las coletillas pueden).

---

## 10. Cambios propuestos al canon

Ninguno se ha aplicado todavía a `DISENO.md` (06 lo hará en el paso 1 de su sección 6); la columna **Estado tras 06** recoge qué decidió el autor. Los cambios 1, 2, 4 y 9 son los que afectan a la arquitectura; el resto son pequeñas ampliaciones. Ninguno altera una regla de juego del canon.

| N.º | Documento y sección | Propuesta | Motivo | Estado tras 06 |
|---|---|---|---|---|
| 1 | `DISENO.md` §12 (narrador) | Sustituir `frase/2` por `frase(Clave, Nivel, Plantilla)` (`frase/3`), con variantes como cláusulas repetidas y marcas `~w` con lista de argumentos. Se conserva `frase/2` como atajo de compatibilidad. | Soportar los niveles `resumido`/`detallado`, las variables y la rotación de variantes sin tocar la lógica. | **Aceptado** (06 §3.2, 05-1): `frase/3`, estático (X-06). |
| 2 | `DISENO.md` §12 y §11.4 | Ampliar las claves de las frases: `Meta`, `falla(Meta)`, `impide(Hecho)`, `suceso(T)`, `evento(Id, D)`, `gag(Id)`, `generica(T)`. El ejemplo del canon pasa a `impide(teme(baldomero, caballo))`. | El mismo hecho (`teme/2`) puede aparecer en un éxito o en un fallo, y el comentario de cada caso es distinto. | **Aceptado** (05-2). Se añaden `texto(T)` (D-27) y el traductor `clave_de_diag/2` (X-21). |
| 3 | `DISENO.md` §10 (arquitectura) | Añadir `src/frases.pl` con **solo datos** (los hechos `frase/3`), separado de `narrador.pl` (lógica de selección). Si no se acepta, los hechos van al final de `narrador.pl`. | Ampliar el humor sin tocar código (riesgo de §17: "el humor se queda corto"). | **Pospuesto** (06 §3.1, D-07): empezar en `narrador.pl`; separar `frases.pl` solo si pasa de unas 300 líneas. |
| 4 | `DISENO.md` §9.2 (estado dinámico) | Añadir estado **de presentación** del narrador: `usos_frase/2`, `descanso_gag/2`, `ultimo_dia_gag/2`, `explicaciones_hoy/1`, `salida_anterior_con_coletilla/0`, modificado solo en `actualizar_*` y reiniciado con la partida y con `demo/0`. | Evitar repetición sin azar; no afecta a ningún resultado de la lógica (prueba de F-24). | **Modificado** (06 §3.1, X-06, D-25): los contadores viven en `estado.pl` y el narrador devuelve efectos; no hay `actualizar_*` en el narrador. `salida_anterior_con_coletilla/0` pasa a `coletilla_previa/1`. |
| 5 | `01-lore` y `DISENO.md` §8 (combate) | Añadir la regla de **presentación** `calidad_golpe(Daño, Calidad)` (`flojo` si el daño es 2 o menos, `fuerte` si es 8 o más, `normal` en el resto; umbrales provisionales). | El canon no tiene críticos ni fallos aleatorios; así hay golpe flojo, normal y fuerte sin añadir mecánica. | **Aceptado** (05-5). |
| 6 | `01-lore` §10 | Añadir hechos `nombre/2` con artículo para enemigos, zonas, objetos y quesos, y **nombres visibles para los contratos** (el lore §10.11 solo da ids): `ratas_del_granero` ("Ratas del granero"), `gato_en_el_arbol` ("Gato en el árbol"), `silvestre_para_ricota` ("Silvestre para Ricota"), `fantasma_charlatan` ("El fantasma charlatán"), `gallina_noble` ("La gallina noble"), `peaje_del_ganso` ("El peaje del ganso"), `despensa_real` ("La despensa real"). | Las frases necesitan nombres con género y número correctos; los contratos comparten id con algunos NPC, por lo que su nombre se resuelve aparte (`nombre_contrato/2`). | **Aceptado** ampliando (05-6): faltan los 8 contratos de 04 y el tratamiento de `e(Tipo, N)` (X-19). |
| 7 | `01-lore` §5 (Mantecosa) | Hacer explícito el estado `deuda_taberna/1` (cuenta pendiente), mencionado en el lore pero ausente del canon. Lo usan `F08b` y `T02`. | Si no se implementa, simplemente se descartan esas dos frases y la rama de descanso rechazado por deuda. | **Rechazado** (05-7, D-15, X-31): ningún documento define `deuda_taberna/1`; se retiran `F08b` y `T02`. |
| 8 | `DISENO.md` §10 y `03-funcionalidades-y-etapas.md` F-25 | Los **textos de los eventos** viven en el banco (clave `evento/2`); `eventos.pl` solo contiene condiciones, efectos y enfriamientos. Un evento como máximo por día; no en el día 1; semilla fija. | Todo el texto en un único sitio y eventos reproducibles para la demo. | **Aceptado** (05-8, X-07); semilla con el LCG de 02, no `set_random` (D-25, O-1). |
| 9 | `DISENO.md` §17 (riesgos) y README | Añadir el requisito de **UTF-8**: `:- encoding(utf8).` en los ficheros con texto visible y nota en el README sobre la consola de Windows (`chcp 65001`). | Las tildes, `¿`, `«»` y los símbolos de §11.3 (`✔`, `✘`, `├─`) fallan con la codificación por defecto de algunas terminales. | **Aceptado y modificado** (05-9, D-26, O-6): símbolos de árbol en ASCII y texto en UTF-8 con `set_stream(user_output, encoding(utf8))`; consola de Windows por comprobar (V-06). |
| 10 | `01-lore` §2.4 | Fijar el puesto del Registro como `47 - contratos_cumplidos` (mínimo 41), solo para texto. | Dar contenido al callback del puesto 47 de 47 sin efectos en las reglas. | **Aceptado** (05-10, X-53): el puesto en el final lo da el texto del final. |
| 11 | `03-funcionalidades-y-etapas.md` C-3 | Las frases `F10b` asumen la lectura "Baldomero está en la compañía, por tanto no puede escoltar". Si C-3 cambia la semántica de `rasgo_no/1`, hay que revisar el texto de `F10b`. | Dependencia entre una decisión de contratos y una frase concreta. | **Resuelto** (D-19, X-37): se evalúa contra los miembros activos sin `ignora_miedo` (la venda); `F10b` usa `impide(rasgo(baldomero, teme_caballos))`. |
| 12 | `docs/02-arquitectura-codigo.md` y `docs/04-guion-y-contratos.md` | Pendientes de escribir en el momento de redactar este documento. Cuando existan, alinear las claves (nombres de predicados) y los nombres visibles; las frases de contrato (K) se ajustarán al guion. | Coherencia entre documentos. | **Cumplido**: 02 y 04 existen y 06 fija los nombres canónicos (§2.7); las claves están alineadas. |
| 13 | Comandos en el texto | Las frases `A02`, `A09`, `G06` y `G07` citan `ayuda.`, `explicar(...)` y `por_que_no(...)`. Si se renombran los comandos de `DISENO.md` §13, hay que editarlas. | Acoplamiento controlado entre texto y comandos. | **Aceptado** (05-13): D-20 mantiene los comandos como términos con punto final. |


---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 tras `docs/06-revision-y-decisiones.md`. Se parte de la v0.1 (31 de octubre de 2026). Solo cambia este documento; el contenido recortado no se borra, se marca `O` o `X` en la columna Alc.

| Qué cambió | Dónde | Motivo |
|---|---|---|
| Narrador puro: sin estado propio ni azar; recibe el día y una copia de los contadores y devuelve efectos como datos; se retiran `usos_frase/2`, `descanso_gag/2`, `ultimo_dia_gag/2` como hechos del narrador, `actualizar_*`, `reiniciar_narrador/0` y `narrador_modo/1` (el modo fijo es un argumento) | 5.1, 5.4, 5.6, 10 (cambio 4) | D-25, X-01, X-06 |
| Contadores de rotación, descanso de gags, `explicaciones` y `coletilla_previa` pasan a `estado.pl`, con efectos `usar_frase`, `fijar_uso`, `descanso_gag`, `visto_gag`, `fijar_coletilla`, `contar_explicacion` | 5.4 | D-25, X-22 |
| Condiciones de gags evaluadas en `juego` y pasadas como lista de candidatos | 3.3, 5.4 | X-06 |
| Se elimina todo uso de `random_between/3`, `random_member/2` y `set_random/1`; elección de eventos con el LCG de 02 (`tirada/4`) y semilla de `estado`; `evento_del_dia/3` devuelve la semilla | 5.2 (E), 6.1, 6.2 | D-25, X-09, O-1 |
| `frase/3` estático (sin `dynamic`); la prueba que vaciaba el banco se sustituye por `logica_sin_texto`; nuevas pruebas `claves_de_diag` y `semilla_reproducible` | 7.1, 7.6 | X-06, D-27 |
| Traductor `clave_de_diag/2` y `comentario_diag/5`: claves de 05 alineadas con el diagnóstico de 02 §6.9 (`neg_viola`, `fallo`, `tras`, `sin_clausula`, `builtin_falso`) | 4.2, 7.4 | X-21 |
| Claves: `puede_ir` a `puede_viajar`; `huelga/1` a `esta_en_huelga/1`; `puede_combatir(taberna)` a `permite_combate(taberna)`; `estado_queso/2` a `categoria_queso/2`; `tiene_objeto/1`, `posee/1`, `lleva_alguien/1` a `lleva(compania, O, N)`; `en_compania/1` a `activo/1`; `estado(P, E)` a `cantando/1`; `contratos_cumplidos/1` a `contratos_cumplidos_min/1` en la condición; `avanzar_dia` deja de ser regla explicable (X16 pasa a variante de `puede_viajar`) | 3.3, 4.1, 4.2, 4.4, 6.3, 7.6 | D-16, X-12, X-14, X-15, X-16, X-17, X-18, X-20 |
| `F10b` pasa a `impide(rasgo(baldomero, teme_caballos))` (lo que contiene la prueba de `rasgo_no`) | 4.2 | X-21, X-37, D-19 |
| `F02` y `E15`/`E16`: la huelga se deriva de la moral, no del sueldo cobrado; texto de `F02e` corregido | 4.2, 4.4 | X-25, X-48 |
| Instancias `e(Tipo, N)`: `casa/2` y nombre con número si hay varias | 4.1, 5.4, 7.5 | X-19 |
| Símbolos del árbol en ASCII; texto en UTF-8 con `set_stream`; plan B de transliteración si falla la consola de Windows | 1.5, 7.2, 7.5 | D-26, X-11, O-6 |
| Un solo almacén `frase/3`: nueva clave `texto(Tipo)` para diálogos, consejos, finales y zonas de 01 y 04 | 4.0, 7.2 | D-27, X-07 |
| Eventos aleatorios: 0 en la mínima, 5 en el objetivo (6 textos), 19 en el extra; los 5 que duplican a 04 llevan `X†`; efectos traducidos al vocabulario de 02 (`expandir/2`) | 6, 6.2, 6.4 | D-28, X-52, X-03 |
| Recorte del banco por script: 72 en la mínima (núcleo de 32 + 40), 105 en el objetivo (121 con coletillas y eventos), 254 en total; Nivel B de 50 | 4 (columna Alc), 7.7, 8.4, 8.5, 8.6 | D-21, 06 §5.1, §5.2 |
| Gags: 0 en la mínima, 3 (`caballo`, `registro`, `silencio`) en el objetivo, 12 en el extra | 3, 3.1, 3.2 | D-21, 06 §5.1 |
| Sin tienda ni compra de queso: `E06` y `E07` reescritas, `E12` (pan duro) y `T07` pasan a extra y sin venta, `T04` sin "cobrar la cuenta", ejemplos de `no hacer` | 4.4, 4.7, 9.3, 1.4 | D-10, X-33, X-46 |
| Se retiran `F08b` y `T02` y el estado `deuda_taberna/1`; se añade `F16` (`hay_queso_para(descanso)`); `D01b` y `D01c` sin "cuenta" | 4.2, 4.6, 4.7, 10 (cambio 7) | D-15, X-31 |
| `comer` y `pagar` explicables: `E08` pasa a `racion(P, Q, Estado)` y `E09` queda para el comando `comer`; nuevas `X21` y `F17` (`puede_comer/2`); `X19`, `E13` y `E18` ligadas al comando `pagar` y al impago al salir | 4.1, 4.2, 4.4 | D-12, D-14, X-29, X-30 |
| Finales con los ids de 04: `chapuza`, `derrota_combate`, `derrota_hambre` (mínima), `leyenda` y `quiebra` (objetivo); `I02` pasa a `jefe_derrotado`, `I03a`/`I03b` a `fin(derrota_*)`; `I02b` sin puesto del Registro; `I05` solo en partida | 4.9 | D-30, D-17, X-44, X-53 |
| Comandos: 16 en la mínima, `elegir/1` y `pagar` nuevos, huir del jefe prohibido, `lanzar` y `apestado` en el extra | 4.3, 4.8 | D-20, D-29, D-23, D-24 |
| Escolta de `gallina_noble` con contador de golpes en la mínima (sin cambio de frases) | 4.10 | D-33, X-38 |
| Regla de persona gramatical: tú para el jugador, vosotros solo para el grupo | 1.2 | X-54 |
| Estado de cada propuesta al canon (sección 10) | 10 | 06 §3 |
| Recuento: 253 a 254 filas (se retiran 2, se añaden 3); no se reproduce el 254 con X = 47 que cita 06 | 7.7 | X-55 |

**Pendiente o necesita decisión del autor**

- **Cuerpos de los finales y de las derrotas (D-27, D-30).** 04 trae sus propios textos de cierre y dos de las derrotas incluyen ya una línea del narrador; `I02`, `I03a` e `I03b` se imprimen antes o después, pero no los dos. Falta fijar con 04 qué línea manda en cada derrota.
- **`pagar` parcial.** `E18` y `X19` suponen que `puede_pagar_sueldos/0` exige queso para todos; si 02 permite el pago parcial, `E18` sigue valiendo, pero conviene confirmarlo al escribir `economia:efectos_sueldos/1`.
- **Eventos con `†`.** Los 19 en el extra incluyen 5 que repiten eventos de 04; hay que desactivar el equivalente de 04 si se activan (06 X-52 recomienda eliminarlos; aquí se conservan marcados para no perder el texto). `regalo_del_ermitano` también solapa con `paz_del_moho`.
- **Huelga en `atacar`.** `F02` exige que la meta de `atacar` incluya `puede_combatir(A)`; hay que verificarlo en 02 (§3.3, §6.2).
- **Consola de Windows (V-06) y comprobaciones de 06 §7.2** (V-04, V-07, V-09) siguen pendientes; los bocetos de 5.4, 6.2 y 7.4 solo se han probado con ejemplos pequeños.
- **Nombres con número** (`nombre_visible/3` con varias instancias) es un boceto sin ejecutar.
