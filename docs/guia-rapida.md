# Guía rápida de Banda Chapuza

*Una página para jugar en cinco minutos. El manual completo está en el [README](../README.md).*

## Qué haces

Diriges a **cuatro mercenarios incompetentes** (Sir Baldomero, Madame Pimentina, Rufino y Tuerca) que cobran en **queso**. El queso es la moneda **y** la comida, y se pone rancio con los días.

**Objetivo:** aceptar contratos, sobrevivir sin quedarte sin queso y derrotar al **Gran Roquefort** en las Cuevas del Roquefort. Si te quedas sin queso o caen los cuatro, pierdes.

## Cómo se juega

Escribes **órdenes terminadas en punto**, por ejemplo `contratos.` o `ir(aldea).`. En la web también puedes pulsar los botones de abajo. `ayuda.` lista lo que puedes hacer ahora y te da un consejo según dónde estés.

## Primeros pasos

Escribe esto, en orden (cada línea es una orden):

```text
contratos.
aceptar(ratas_del_granero).
aceptar(gato_en_el_arbol).
ir(aldea).
atacar(rata_quesera).
mirar.
explicar.
```

Qué ha pasado:

1. `contratos.` enseña el tablón: los contratos a la vista y si se pueden aceptar (`disponible`, `bloqueado`, `lejos`…).
2. `aceptar(...)` coge un contrato (hasta tres a la vez).
3. `ir(aldea).` viaja: **cuesta un día** (los quesos envejecen y la Banda come). Al llegar empieza el combate de las ratas.
4. `atacar(rata_quesera).` golpea con el miembro al que le toca; los enemigos responden solos. `mirar.` repite de quién es el turno y cómo están los enemigos.
5. `explicar.` te cuenta **por qué** pasó lo último, con el árbol de la prueba. Es la gracia del juego.

Sigue con `atacar(...)`, `defender.` y `habilidad(...)` hasta ganar el combate. Después hay un evento con opciones (`elegir(1).`) y vuelves a la taberna.

## Lo que importa en cada día

- **Queso:** `inventario.` enseña la despensa. Cada día come toda la Banda (cuatro raciones) y cada viaje es un día. El número de la cabecera (por ejemplo `12 · 3 días`) es el queso y para cuántos días de comida te llega; si se pone amarillo o rojo, ve a cobrar. Quedarte a cero no acaba la partida en el acto: la Banda aguanta **dos días seguidos sin comer** (con castigo de moral y vida). Pierdes si, sin queso y sin nada por cobrar, llegas al segundo; un día en que todos comen vuelve a ponerlo a cero. Cobrar a tiempo te salva.
- **Junta los contratos:** ir y volver a la aldea cuesta dos días (8 quesos) y sus dos contratos pagan 14 y 12. Cada contrato paga según lo que cuesta hacerlo (días de viaje y enemigos). Hacerlos en un solo viaje sale mucho más barato que uno por uno.
- **Objetivo:** el juego te dice qué toca ahora (por ejemplo «Objetivo: cumple Ratas del Granero en la Aldea Requesón») y qué te falta para el contrato final. Sale al mirar y cada vez que cambia; en la web está en la pestaña de contratos y de zona. Cuando aparece un contrato nuevo en el tablón (por ejemplo, el del jefe al visitar el castillo) se avisa.
- **Sucesos:** algunos lugares guardan una escena única (un pozo, un puente, una carreta…): se abre sola al llegar, o con `explorar.` si había algo en marcha. Se elige con `elegir(N).` como una charla; algunas opciones solo aparecen si ya sabéis algo del `diario.`.
- **Objetos:** `usar(pocion, tuerca).` gasta una poción y cura a ese miembro (hasta su vida máxima). Fuera de combate no pasa el tiempo; en combate gasta el turno de quien actúa. Las pociones llegan como recompensa de contrato o de alguna charla.
- **Gente:** `hablar.` enseña quién hay aquí hoy (algunos solo están los primeros días). `hablar(Nombre).` abre su escena: eliges con `elegir(1).` qué miembro de la Banda hace qué. Cuesta poco o nada y da pistas; `diario.` lista lo que ya sabéis del Gran Rancio.
- **Botín:** al ganar un combate, los bandidos sueltan siempre un queso y las ratas, a veces (una tirada con la semilla del juego: la misma partida da el mismo botín).
- **Sueldos:** al volver a la taberna hay sueldos por pagar (`pagar.`). Si sales sin pagar, baja la moral, y con la moral por los suelos alguien se pone en **huelga**.
- **Descansar** (`descansar.`, solo en la taberna) cura a todos pero cuesta queso.
- **Contratos:** los premios se cobran en la taberna. Algunos contratos están **bloqueados** por algo de la Banda (por ejemplo, a Baldomero le dan miedo los caballos).

## Cuando algo no se puede

No adivines: **pregunta por qué**.

- `por_que_no(aceptar(gallina_noble)).` cuenta qué regla falla y qué hecho lo impide.
- `por_que_no(atacar(baldomero, bandido_montado)).` en un combate con un bandido a caballo.
- `nivel(detallado).` enseña el árbol entero; `nivel(resumido).` lo pliega.

## Si te atascas

| Te pasa | Haz |
|---|---|
| No sabes qué escribir | `ayuda.` |
| «No entiendo…» | Falta el punto final o el paréntesis; `ayuda.` enseña la forma exacta |
| Un botón o un comando «no se puede» | `por_que_no(...)` con esa orden |
| Quieres ver una demostración preparada | `demo.` lista las escenas |
| Quieres empezar de cero | `salir.` y arrancar otra vez (en la web, Menú → Nueva partida) |

## Arrancar

```text
swipl -q -s src/main -g main -t halt
```

(en Windows, `C:\Program Files\pl\bin\swipl.exe`). La versión web: `swipl -q -s src/servidor -g "servidor(8080)" -t halt` y abrir `http://localhost:8080/`.
