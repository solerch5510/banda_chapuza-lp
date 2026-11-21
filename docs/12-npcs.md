# Hablar con los NPC (diseño)

*Diseño de la función y estado de lo hecho (§10). Lo caro es **escribir**, así que se decidió primero quién habla, cuándo y qué cuenta, y se programó el motor con un primer lote de 8 escenas.*

## 1. Qué es

Un comando nuevo, `hablar`, para que las zonas tengan gente. Cada zona tiene **al menos dos personajes** en cada momento, y **no son siempre los mismos**: hay un grupo hasta el día 5 y otro desde el día 6 (algunos se quedan todo el juego). Cada personaje ofrece una **escena corta con opciones**, como la del gato en el árbol, que da cosas pequeñas o **información desde su punto de vista**. Esa información, junta, cuenta la verdad del **Gran Rancio** (el príncipe Roque de Fort, curado hasta ser un queso azul con ideas propias, docs/01 §1.4).

## 2. Cómo se juega

```text
hablar.                  quién hay aquí hoy
hablar(mantecosa).       empieza su escena (si está aquí)
elegir(1).               una de las opciones, como en un evento
diario.                  lo que ya sabes del Gran Rancio, ordenado
```

- **Hablar no cuesta tiempo** ni queso: no pasa el día. Lo que cuesta, a veces, es una **opción** (pagar una ronda, un queso).
- Cada opción la hace **un miembro de la Banda** (Baldomero con honor, Pimentina con magia de cocina, Rufino con una balada, Tuerca con las manos largas), como en el evento del gato. Si ese miembro cae o está en huelga, la opción no está disponible, y `por_que_no` lo explica.
- Cada escena se resuelve **una sola vez**. Si vuelves, el personaje repite una frase corta («ya te lo he dicho»).
- Si te vas sin elegir, la escena queda abierta para la próxima vez.
- El **diario** apunta cada fragmento de historia que se averigua.

## 3. Los datos (para el que programe)

Reutiliza lo que ya hay: `opcion_evento/6` (quién, condiciones, efectos) y los efectos de `estado` (`ganar_queso`, `mod_moral`, `marcar`…). Lo nuevo son tres tablas:

| Tabla | Qué dice |
|---|---|
| `presente(Npc, Zona, DiaDesde, DiaHasta)` | dónde está y entre qué días (`99` = todo el juego) |
| `escena(Npc, Evento)` | qué escena cuenta |
| `saber(Marca, Texto)` | qué apunta el diario cuando se averigua |

Y una regla pura, `puede_hablar(Npc)`: está en esta zona hoy y no hay combate. Los efectos de elegir se aplican, como siempre, solo en `estado.pl`. Los textos (lo caro) van en `narrador.pl` y se comprueban con el banco de frases.

## 4. Regla de oro del balance

Hablar **no puede arreglar la economía**. Cada personaje da, como mucho, una de estas cosas, y nunca todas:

- hasta **2 quesos** (en total, en toda la partida, **como mucho 8**);
- **+1 de moral** a uno o a todos;
- un **objeto** pequeño (hace falta el comando `usar`, ver §8);
- una **pista** que no cambia números (un fragmento del diario).

Lo normal será lo último: la información es la recompensa. El simulador medirá a un jugador que **siempre habla y siempre elige lo que da queso**: no debe ganar mucho más que uno que nunca habla.

## 5. El reparto

Un personaje **fijo** por zona y uno que **rota**: A es del día 1 al 5; B, del 6 en adelante. Así en cualquier día hay dos en cada zona.

| Zona | Fijo (todo el juego) | Rota A (días 1–5) | Rota B (día 6 en adelante) |
|---|---|---|---|
| Taberna | **Doña Mantecosa**, la dueña | **Gruyère**, viajante sin carreta | **La Inspectora Cuajarón**, del Gremio |
| Aldea | **Alcaldesa Nata** | **Ricota**, tendero risueño | **Eustaquio**, el fantasma charlatán |
| Bosque | **Hermano Penicilio**, el ermitaño | **Seta chismosa** | **Aldeano perdido** (hace tres días que busca el camino) |
| Camino Real | **Ganso recaudador** | **Capitán Pecorino**, de ronda | **Lady Clotilde**, de vuelta del baile (si se la escoltó) o un **bandido arrepentido** |
| Castillo | **Rey Brieto IV** | **Lord Tapanarices**, cortesano | **La Reina viuda Nata Doble** |
| Cuevas | **El Eco** (repite lo que dices, con retraso) | **Rata exiliada**, la que escapó del granero y ahora hace de guía | **Murciélago azul**, que sabe más de lo que chilla |

Son **18 personajes con escena propia**: 6 fijos y 12 que rotan. Para empezar bastan los 6 fijos y el tramo A de la taberna y la aldea (**8 escenas**); el resto puede ir después.

## 6. El hilo de la historia (lo que cuentan, en orden de abajo arriba)

Cada uno sabe un trozo y lo cuenta **a su manera**, sin saber el todo. Sin las seis piezas no se entiende el final; con tres ya se intuye.

1. **Mantecosa:** el moho empezó «hace tres inviernos» en la despensa real, y ahora ya sale por los desagües de su taberna.
2. **Penicilio:** el moho **no es malo**: «tiene hambre». Viene de abajo, de las cuevas.
3. **Eustaquio:** el último príncipe de Roquefort **se retiró a madurar** y dijo que volvería cuando estuviera «en su punto».
4. **El Eco:** repite lo que se le dice, pero con otra voz: la de alguien que **lleva siglos hablando solo**.
5. **La Inspectora:** el Gremio **sabe** lo de las cuevas y lo ha ocultado para no hundir el precio del queso.
6. **El rey Brieto:** su despensa se pudre porque **él mismo** firmó el permiso para «afinar» el queso en las cuevas, sin leer la letra pequeña.

El diario junta las piezas con una frase por cada una y, con las seis, una última línea del narrador que explica al jefe como el cuento que es.

## 7. Dos escenas de ejemplo (para fijar el tono)

**Doña Mantecosa — «La cuenta»** *(taberna, todo el juego)*

> Doña Mantecosa seca una jarra con el mismo trapo con el que limpia la mesa. «El moho. Lo huelo desde hace tres inviernos, desde que el rey me compró queso para la despensa y lo devolvió "para afinarlo". Ahora sale por mis desagües. Yo no digo nada, pero la sopa ya no es de ayer: es de anteayer.»
>
> 1. **Baldomero:** jura por su honor que la Banda arreglará el asunto. *(+1 moral; Mantecosa: «el honor no paga la cuenta, pero queda bien».)*
> 2. **Pimentina:** invita a una ronda de caldo (cuesta 1 queso). *(Mantecosa suelta el dato del rey y regala una cataplasma de requesón.)*
> 3. **Tuerca:** se ofrece a «echar un vistazo» a los desagües. *(Encuentra 1 queso mohoso… pero la moral baja 1: Rufino ha tenido que olerlo.)*
>
> **Diario:** «El moho empezó hace tres inviernos en la despensa del rey.»

**Eustaquio — «La cena»** *(aldea, desde el día 6)*

> Un mayordomo translúcido se endereza la corbata inexistente. «Sirvo al príncipe Roque de Fort desde antes de que él supiera pronunciarlo. Un día me dijo: "Eustaquio, voy a madurar un poco." Eso fue hace trescientos años. Mi cena sigue sin llegar. ¿Querrían escuchar la historia completa? Dura tres días. Les haré una versión de tres minutos.»
>
> 1. **Rufino:** escucha entera la historia (y la convierte en balada). *(+1 moral a todos; el fantasma se emociona y suelta lo del príncipe.)*
> 2. **Baldomero:** exige que se vaya de la aldea por orden de la alcaldesa. *(Eustaquio se ofende y se calla: no hay fragmento.)*
> 3. **Pimentina:** le ofrece cena, por fin (cuesta 1 queso). *(El fantasma llora de gratitud y da el mapa de las cuevas: pista.)*
>
> **Diario:** «El último príncipe de Roquefort se retiró a "madurar un poco" y no ha vuelto.»

## 8. Cosas que quedan fuera (por ahora)

- **`usar`:** un comando para gastar objetos (poción, cataplasma). Hoy solo los enemigos los gastan, y un objeto que el jugador no puede usar no es un premio. Es una tarea aparte, pequeña, y encaja con esto.
- **Contratos nacidos de una charla** (el gato, pero empezado hablando): se pueden añadir sobre este mismo motor.
- **Reclutar** a alguien: el autor ya lo dejó como extra.

## 9. Cómo se comprobará

Pruebas en `tests/hablar.pl` (la regla `puede_hablar`, la presencia por día, cada opción, la escena que se resuelve una vez, `por_que_no`, el diario, la consola, la API y la web), mutantes, el simulador con un jugador que siempre habla y los ejemplos regenerados. Y una **prueba de contenido**: cada personaje tiene escena, cada escena tiene sus textos, cada fragmento del diario sale de una opción que existe (un validador, para que añadir contenido no se rompa en silencio).

## 10. Estado (20 de noviembre de 2026)

> **Actualización:** ya existe `usar(Objeto, Miembro)` (nota 44). Cantar el anuncio a Ricota da ahora **una poción** en vez de un queso, así que el objeto tiene dónde nacer y para qué servir.

**Hecho** (el autor eligió «motor + 8 escenas» y «sobre todo información»):

- El comando `hablar`, `hablar(Nombre)` y `diario`, la regla `puede_hablar/1`, las escenas con opciones y el diario (`src/charlas.pl`; los textos, en `narrador.pl`).
- **Las 8 escenas:** los 6 fijos (Mantecosa, Alcaldesa Nata, Penicilio, Ganso recaudador, Rey Brieto, el Eco) y los dos del tramo A de la taberna y la aldea (Gruyère y Ricota). Siete fragmentos de diario, cuatro de ellos del hilo del Gran Rancio (Mantecosa, Penicilio, el Eco y el rey) y tres de ambientación.
- **El validador de contenido** (`tests/hablar.pl`): cada personaje tiene escena, nombre y frase de apertura; cada opción, su texto y su frase de resultado; cada fragmento del diario sale de una opción; y el techo de queso (8 en total, 2 por opción) está comprobado.
- **Web:** botones «Hablar», la gente presente, la escena con sus opciones y el diario.

**Lo que midió el simulador** (200 partidas con 10 % de errores y 10 partidas sin errores): el jugador que habla con todos y siempre elige lo que más queso da acaba con **unos 4 quesos más** (10,5 frente a 6,3) y gana lo mismo o algo más (98 % frente a 96,5 %). Sin errores, +7,5 quesos de media, justo bajo el techo de 8. Las opciones de información son la recompensa real: el queso es la excepción.

**Pendiente:**

- Los 10 personajes que faltan (los rotativos del grupo B y los del grupo A de bosque, camino real, castillo y cuevas) y los dos fragmentos que cierran el hilo (Eustaquio y la Inspectora), con la frase final del diario cuando estén los seis.
- Más objetos que se puedan usar: hoy solo cura la poción; una cataplasma o un objeto de moral serían datos nuevos (`mundo:curacion/2` y la regla de `usar`).
- Añadir contenido ya no necesita tocar código: basta con filas en `presente/4`, `escena_de/2`, `opcion_charla/5`, `saber/1` y sus textos; el validador avisa si falta algo.
