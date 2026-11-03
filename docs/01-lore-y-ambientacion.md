# Banda Chapuza — Lore y ambientación

> Documento de diseño 01 · Fase de diseño · Complementa a [DISENO.md](DISENO.md), que sigue siendo el canon.
>
> **Revisado el 2 de noviembre de 2026 tras docs/06: alineado con las decisiones aceptadas.** Los cambios están listados al final, en "Registro de cambios de la revisión".
>
> Estado: **borrador v0.2** (2 de noviembre de 2026; v0.1 del 31 de octubre de 2026). Cada elemento de contenido (zona, enemigo, objeto, queso, estado, contrato) lleva una etiqueta de versión: **mínima** (se compromete; Debe), **objetivo** (solo si el colchón de la semana 5 está intacto el 27 de noviembre) o **(extra)** (ampliación futura, fuera de la entrega del 11 de diciembre). Lo marcado como objetivo o extra se conserva en el documento, no se borra. Todos los números son **provisionales** y se ajustarán en la fase de balance.

## Cómo leer este documento

- Las secciones 1 a 9 son narrativa y reglas del mundo, pensadas para inspirar las frases del narrador y los textos que ve el jugador.
- La sección 10 es el **índice de identificadores**: es el contrato entre este documento y el código. Si algo del texto contradice la sección 10, manda la sección 10.
- Los efectos de objetos, quesos y rasgos están escritos de forma que se traduzcan directamente a hechos y reglas de Prolog (ver columna "Regla"). Los nombres de predicados siguen la tabla de nombres canónicos de docs/06 §2.7 (por ejemplo `puede_viajar/1`, `esta_en_huelga/1`, `permite_combate/1`, `lleva/3` y `equipado/2`, `activo/1`).
- **Versión** (alcance de la entrega, docs/06 §5.1; no confundir con el `alcance` cuerpo/distancia de un ataque): *mínima* = 6 zonas en datos (5 con contenido), 4 miembros, 4 contratos, 5 enemigos, 2 objetos, 2 tipos de queso; *objetivo* = lo que se añade si hay colchón; *(extra)* = el resto del diseño.
- La sección 11 lista las propuestas de cambio al canon y el estado en que quedaron tras la revisión. Nada del canon se ha cambiado en silencio.

---

## 1. Premisa del mundo

### 1.1 Los Reinos Quesudos

Los **Reinos Quesudos** son un continente pequeño, húmedo y con un olor imposible de ignorar. Aquí todo gira alrededor del queso: se paga con queso, se come queso, se reza al queso en las fiestas y se declaran guerras por una cuestión de curación mal hecha. Un reino se mide por la calidad de su despensa; un noble, por la edad de su cava; y un insulto grave, por llamar "fresco" a alguien con más de cuarenta años.

El queso no es solo un alimento. Es **moneda** (se cuenta en quesos; en la v1 se paga siempre **por unidades**, y el valor según lo curado que esté solo informa y sirve de precio en la tienda extra), es **comida** (sin ración diaria, la gente se deprime y enferma) y es **combustible mágico** (la magia de cocina solo funciona con queso en la despensa). Y tiene una propiedad que hace al mundo impredecible: **madura**. Lo que hoy vale oro, dentro de diez días huele a calcetín de gigante.

> **Regla de la moneda (docs/06 D-10, X-33).** El queso es la **única moneda** y a la vez la comida, así que **no se compra ni se vende queso** (no hay con qué). El queso **entra** solo por recompensa de contrato, botín de combate y hallazgos (`rebuscar_bolsillos`, forrajeo en el bosque, eventos); y **sale** solo por la ración diaria, los sueldos, el descanso, las habilidades que lo gastan y las multas. En la v1 **no hay tienda**: el equipo llega como recompensa de contratos. La tienda de objetos no queseros (que se pagaría en queso, por unidades, gastando primero lo más rancio) es **(extra)**.

### 1.2 Por qué se pelean por el queso

Según la leyenda, hace mucho el mar era de leche. Un día cualquiera, la **Gran Cuajada** lo transformó en tierra firme: montañas de queso duro, valles de queso blando y un cielo que desde entonces huele a nata. De ahí nacieron los cuatro grandes reinos, cada uno convencido de haberse quedado con la mejor parte.

Las guerras tienen siempre el mismo motivo bajo capas de excusas:

1. **Las cuevas de afinado** (las únicas donde el queso madura "como Dios manda") son pocas y valiosísimas. Quien las controla, controla el mercado.
2. **El orgullo de cava**: cada reino afirma que su queso es el original y que el vecino es una "imitación con ínfulas".
3. **El Pacto del Suero**: desde hace cien años los reyes tienen prohibido ir personalmente a la guerra (la última vez, un rey se resbaló en su propio suero y firmó una paz por accidente). Por eso las batallas las libran **compañías de mercenarios con contrato escrito**. De ahí que existan los mercenarios, y de ahí que la Banda Chapuza pueda vivir de los restos.

### 1.3 Cronología corta (Años del Cuajo, a.C.)

| Año | Suceso |
|---|---|
| 0 | **La Gran Cuajada.** El Mar de Leche cuaja. Nacen la geografía y las primeras discusiones sobre quién se queda con el trozo mejor. |
| 1 a 300 | **Guerra de las Cortezas.** Trescientos años de pelea por las cuevas de afinado. Se firman y rompen 41 paces, ninguna con los pies secos. |
| 312 | **Pacto del Suero.** Los reyes dejan de ir a la guerra en persona; las batallas se subcontratan a compañías con contrato. Nace la profesión de mercenario. |
| 372 | **Caída del Principado de Roquefort.** El príncipe Roque de Fort se retira a las cuevas "a madurar un poco" y no vuelve a salir. La corte se dispersa. |
| 409 | **El Gran Rancio.** Un moho azul sale de las Cuevas del Roquefort y empieza a estropear despensas. Las reservas del rey Brieto IV pierden valor semana a semana. |
| 412 | **Hoy.** Se registra la Banda Chapuza en el Registro de Compañías (puesto 47 de 47). Día 1 de la partida. |

> Los números de año son decorativos: solo hace falta que `dia(1)` sea el primer día de la partida. El año 412 se usa, si acaso, en la introducción.

### 1.4 La amenaza de fondo

El **Gran Rancio** es el hilo que une la partida. Del Roquefort sale moho; el moho estropea el queso del rey; el rey no puede pagar a nadie serio porque su dinero se está pudriendo; y por eso, por primera vez en la historia, el rey acaba aceptando a la Banda Chapuza. La causa real se descubre al final: el príncipe Roque de Fort se ha "curado" tanto tiempo que se ha convertido en un queso azul gigante con ideas propias (ver `gran_roquefort`, sección 6).

---

## 2. Facciones

### 2.1 Reinos y poderes locales

| Facción | Qué es | Quiere | Relación con la Banda |
|---|---|---|---|
| **Corona de Camembert** (`corona_camembert`) | El reino principal. Capital: el Castillo Camembert. Rey: Brieto IV "el Mal Curado". | Detener el Gran Rancio antes de que su tesoro se convierta en abono. | Los contrata porque ninguna compañía seria acepta cobrar en "promesas de cobro". |
| **Mancomunidad de Requesón** (`mancomunidad_requeson`) | La aldea y sus alrededores. Pueblo pacífico de queseros blandos. | Que nadie los moleste, y que los contratos de ayuda se paguen a tiempo. | Clientes pequeños y fieles. Cuentan que la Banda "casi nunca rompe nada importante". |
| **Principado de Roquefort** (`principado_roquefort`) | Reino extinto. Quedan las cuevas, un mayordomo fantasma y mucho moho. | (Nada: sus ruinas quieren, sin saberlo, que alguien apague la luz.) | Es el destino final. |

### 2.2 Gremios

| Facción | Qué es | Efecto en el juego |
|---|---|---|
| **Gremio de Afinadores** (`gremio_afinadores`) | Los árbitros de la maduración. Ponen sellos de "fresco", "curado" y "rancio", y cobran por ello. Sus inspectores llevan una lupa y una opinión sobre todo. | Justifica que el estado del queso sea una regla oficial (edad -> estado). Origen de la `salmuera` **(extra)** (recompensa o botín, no se compra en la v1). |
| **Cofradía de los Ganchos del Camino** (`bandidos_del_camino`) | Bandidos del Camino Real, medio sindicados. Tienen tarifas y un lema ("Primero se roba, luego se pregunta"). | Fuente de enemigos de nivel bajo y medio. |
| **El Moho** (`el_moho`) | No es una facción: es un fenómeno. Pero actúa como una: se expande, se defiende y detesta la limpieza. | Fuente de enemigos fúngicos, bosque y cuevas. |

### 2.3 La competencia: los mercenarios "serios"

El **Registro de Compañías** es una pizarra enorme colgada en la Taberna del Cuajo Torcido. Las compañías serias están arriba, escritas con tiza brillante. La Banda Chapuza está abajo del todo, con tiza de otro color y una errata.

| Compañía | Cómo se presentan | Cómo son en realidad |
|---|---|---|
| **Lanzas Parmesanas** (`lanzas_parmesanas`) | Élite montada, cobran solo en parmesano curado, tienen uniforme. | Impecables y antipáticas. Su capitán, Pecorino Duro, desprecia a la Banda y la necesita más de lo que admite. |
| **Compañía del Gouda Dorado** (`compania_gouda_dorado`) **(extra)** | Caros, con contrato de cuarenta cláusulas. | Solo aceptan trabajo "con seguro de moho". Nunca aparecen en pantalla: se mencionan en el Registro. |
| **Hermanos Emmental** (`hermanos_emmental`) **(extra)** | Tres hermanos que juran ser leales. | Siempre pierden algo por los agujeros de sus bolsillos. Aparecen en chistes, no como combatientes. |

### 2.4 La Banda Chapuza

La **Banda Chapuza** (`banda_chapuza`) está registrada como "Compañía de Servicios Diversos Menores". No tiene sede propia; vive de fiado en la taberna. Hereda los contratos que nadie quiere: escoltar a una gallina noble, rescatar gatos, hablar con fantasmas. Su ventaja es que **nadie espera nada** de ella; su desventaja es que **tampoco nadie le paga a tiempo**.

**Puesto en el Registro (objetivo; docs/06 X-53).** Durante la partida el puesto es `max(41, 47 - contratos_cumplidos)`: cada contrato cumplido sube un puesto, con tope en el 41. En el final, el puesto que dice el propio texto del final (12 en `leyenda`, 31 en `chapuza`, etc.) sustituye al cálculo. No tiene consecuencias en las reglas.

---

## 3. Geografía y ambientación por zona

Seis zonas en grafo (canon). Moverse entre ellas consume **un día** (ver Ley de la Ruta Pegajosa, sección 8). Versión (docs/06 §5.1): las seis zonas existen **en los datos** (mínima); cinco tienen contenido y el `bosque` es solo de paso en la mínima (su contenido —queso silvestre, ermitaño, `seta_chismosa`— es objetivo/extra).

```
                 [castillo]
                     |
 [taberna] ----- [camino_real] ----- [cuevas]
     |                |
  [aldea] ------- [bosque]
```

Conexiones: `taberna-aldea`, `taberna-camino_real`, `aldea-bosque`, `bosque-camino_real`, `camino_real-castillo`, `camino_real-cuevas`.

### 3.1 Taberna del Cuajo Torcido (`taberna`) — mínima

**Texto para el jugador:** "El Cuajo Torcido huele a sopa de ayer, a sudor de mercenario y a una promesa de pago que nadie ha visto cumplida. La puerta cuelga de una sola bisagra, que según Doña Mantecosa 'le da carácter'. Aquí se cobra, se firma y se duerme en camas que han visto cosas."

- **Atmósfera:** cálida, desordenada, con luz de vela y deudas colgadas del techo. Zona segura.
- **Olores y sonidos:** caldo, pies, humo de leña; el crujido de una mesa coja; Rufino afinando a deshoras.
- **Habitantes:** `mantecosa` (dueña), clientes sin nombre, el Registro de Compañías en la pared.
- **Peligros:** ninguno físico. Peligro económico: los sueldos que se dejan sin pagar al salir.
- **Qué se puede hacer:** `descansar` (pasa un día, **cuesta 2 quesos**, recupera toda la vida y +1 de moral; si no hay 2 quesos, falla `puede_descansar` y `por_que_no` lo explica; no existe ninguna "cuenta" ni `deuda_taberna`), `contratos` y `aceptar` (ver el tablón y firmar), **cobrar recompensas** (automático al cumplir el contrato), **`pagar` sueldos** (comando explícito, 5 quesos por pago; si se sale de la taberna con sueldos pendientes, cada miembro pierde 2 de moral), y **reclutar** a un quinto miembro **(extra)**. En la v1 la taberna **no vende nada** (el `suero_fermentado` y el resto de objetos son recompensa; la tienda de objetos es **(extra)**). Por la Ley de la Taberna, **no se puede combatir aquí** (`\+ permite_combate(taberna)`).

### 3.2 Aldea Requesón (`aldea`) — mínima

**Texto para el jugador:** "Casitas blancas y blandas, tan pacíficas que el arma más peligrosa del pueblo es un rodillo. Todo huele a leche tibia y a vecinos preguntándote cuándo les pagas. Aquí se cobran favores pequeños y se descubre que 'gato en el árbol' es un género literario."

- **Atmósfera:** bucólica, ordenada, con un fondo de cotilleo constante.
- **Olores y sonidos:** leche, hierba, pan; campanas de vaca; el rodillo de alguien amasando una opinión.
- **Habitantes:** `alcaldesa_nata` (mínima), `fantasma_charlatan` (en la Casa del Cuervo Gordo, **contrato**; objetivo), `ricota` (tendero, **(extra)**: en la v1 solo es texto), aldeanos.
- **Peligros:** `rata_quesera` en los graneros. Poco más.
- **Qué se puede hacer:** **contratos pequeños** (canon: `ratas_del_granero`, `gato_en_el_arbol`), hablar con el fantasma (objetivo), ir al Bosque o volver a la Taberna. La **tienda de objetos** (pociones, cataplasmas, pan duro, equipo básico, pagados en queso por unidades) es **(extra)**; **no se compra ni se vende queso**.

### 3.3 Bosque del Moho (`bosque`) — mínima (en datos y solo de paso); contenido objetivo/extra

**Texto para el jugador:** "Un bosque donde hasta la sombra tiene pelusilla. Los troncos están forrados de moho verde y las setas opinan sobre tu forma de caminar. Al fondo, algo hace 'plop' y prefieres no saber qué."

- **Atmósfera:** húmeda, inquietante pero amable, como una película de terror para niños.
- **Olores y sonidos:** tierra mojada, champiñón, el 'plop' del moho; murmullo de esporas.
- **Habitantes:** `bandido_torpe` y `moho_saltarin` (mínima); `rata_quesera` (mínima); `ermitano_penicilio` y `seta_chismosa` **(extra)**.
- **Peligros:** combates de nivel bajo (canon). El moho puede **acelerar la maduración** de tu queso (ver `moho_saltarin`; ese efecto es **(extra)**).
- **Qué se puede hacer:** combatir y atajar hacia el Camino Real (mínima); hallar **queso silvestre** (canon; objetivo, como hallazgo o recompensa, no se compra) y hablar con el ermitaño **(extra)**.

### 3.4 Camino Real (`camino_real`) — mínima

**Texto para el jugador:** "Un camino empedrado con corteza de queso viejo que se pega a las botas, con un peaje cada cien pasos. Lo recorren carretas, gansos con permiso de cobro y bandidos con más ambición que puntería."

- **Atmósfera:** abierta, concurrida, tensa. Cruce de rutas; casi todo pasa por aquí.
- **Olores y sonidos:** polvo con regusto a cheddar, cascos, trompetas lejanas del castillo, el "cuac" de un recaudador.
- **Habitantes:** `gallina_noble` (cuando se escolta; mínima), bandidos varios (mínima), `ganso_recaudador` (objetivo), `capitan_pecorino` (de ronda; objetivo).
- **Peligros:** **emboscadas** y **escoltas** (canon). Aquí aparecen los enemigos montados: la pesadilla de Sir Baldomero.
- **Qué se puede hacer:** escoltar, combatir y, desde aquí, llegar al Castillo o a las Cuevas. Comprar objetos a los carros ambulantes es **(extra)** (tienda de objetos; el queso no se compra).

### 3.5 Castillo Camembert (`castillo`) — mínima

**Texto para el jugador:** "Una fortaleza blanca y cremosa que, según los lugareños, se hunde un poquito cada año. Los guardias de corteza saludan con una rigidez ejemplar y el rey recibe en una sala tan perfumada que los cortesanos van con la nariz tapada por educación."

- **Atmósfera:** solemne, perfumada, con una corte que sonríe con los dientes apretados.
- **Olores y sonidos:** cera, nata, almidón; trompetas, tacones, un rey que carraspea.
- **Habitantes:** `rey_brieto` (mínima), cortesanos sin nombre, `guardia_de_corteza` **(extra)**, `capitan_pecorino` ocasionalmente (objetivo).
- **Peligros:** guardias que obedecen a su manual, no a la lógica (**(extra)**). El peligro mayor es la etiqueta. En la v1 el único combate del camino al castillo es el `bandido_montado` de la puerta (contrato `gallina_noble`).
- **Qué se puede hacer:** aceptar el **contrato importante** (canon): `despensa_real` (mínima). Recibir `sello_real` (objetivo). La `coraza_de_corteza` ya no se compra en la armería: es recompensa de contrato **(extra)**.

### 3.6 Cuevas del Roquefort (`cuevas`) — mínima (solo la sala del jefe)

**Texto para el jugador:** "Cavernas azules y húmedas, con vetas de moho como mármol en mal estado. El aire sabe a sótano y a decisiones tomadas hace cuarenta años. Algo ahí abajo ha madurado demasiado."

- **Atmósfera:** opresiva y cómica a la vez; goteo, eco y sensación de que el suelo te mira.
- **Olores y sonidos:** moho intenso, piedra mojada; el eco de tus propios pasos con retraso; un 'plic' cada tres segundos.
- **Habitantes:** `moho_saltarin` (mínima; lo invoca el jefe), `gran_roquefort` (mínima), `murcielago_azul` y `golem_de_queso_duro` **(extra)**.
- **Peligros:** **jefe final** (canon). En la mínima no hay combates previos en la zona ni "puerta interior" (docs/06 §5.1): se entra y se afronta al jefe. La puerta interior que exige la `llave_mohosa`, y la sucesión de combates difíciles, son **(extra)**.
- **Qué se puede hacer:** enfrentarse al jefe (mínima; **no se puede huir de él**, D-29). Combatir en sucesión y encontrar queso azul curadísimo (hallazgo o botín, no se compra) son **(extra)**.

---

## 4. La compañía

Cuatro miembros iniciales (canon). El jugador es el **capitán o capitana sin nombre** de la Banda: los demás lo llaman "jefe/a", y Baldomero cree, sin fundamento, que el jefe de verdad es él. El narrador se dirige al jugador de tú (y de vosotros solo cuando habla del grupo, docs/06 X-54). Los cuatro miembros son **mínima**.

### 4.1 Resumen y atributos iniciales propuestos

Los atributos incluyen ya el equipo básico de partida; el equipo del apartado 7 es una mejora sobre estos valores. El `sueldo` es por cada pago en la taberna (comando `pagar`), en quesos y por unidades: 1 + 2 + 1 + 1 = **5 quesos por pago**. La **moral** es un entero de 0 a 10 que empieza en **6** (`parametro(moral_inicial, 6)`). Un miembro entra en **huelga** cuando su moral es **2 o menos** (`parametro(moral_huelga, 2)`); la huelga se deriva solo de la moral (ver sección 8, ley 4). El grupo empieza con **12 cheddar de edad 0** (`inicio/1`).

| Personaje | Rol | Rasgo (canon) | Vida | Ataque | Defensa | Sueldo | Fila preferida | Alcance | Rasgo con regla |
|---|---|---|---|---|---|---|---|---|---|
| `baldomero` | Caballero | `teme_caballos` | 30 | 11 | 3 | 1 | frente | cuerpo | mínima |
| `pimentina` | Maga | `hechizos_de_cocina` | 18 | 6 | 1 | 2 | retaguardia | distancia | mínima |
| `rufino` | Bardo | `cobra_por_callar` | 20 | 4 | 2 | 1 | retaguardia | distancia | objetivo |
| `tuerca` | Ladrón | `manos_largas` | 22 | 7 | 2 | 1 | frente | cuerpo | objetivo |

> En la mínima solo `teme_caballos` y `hechizos_de_cocina` tienen regla completa; los rasgos de Rufino y Tuerca se implementan en el objetivo, aunque sus habilidades sencillas (ver 4.7 y 10.4) sí están en la mínima. Datos en `mundo`: `personaje/7`, `fila_preferida/2`, `alcance/2`.

> El ataque 11 de Baldomero coincide con el ejemplo ilustrativo de DISENO.md §11.3 ("11 − 5").

### 4.2 Sir Baldomero de la Corteza Menor (`baldomero`)

- **Trasfondo:** hidalgo venido a menos, tercer hijo de una casa noble cuyo único castillo es un establo reformado. Entró en la caballería "por tradición familiar" y descubrió, el día de su investidura, que los caballos le dan pánico. El motivo oficial es misterioso. El narrador sabe que, de pequeño, un caballo de feria se comió su bocadillo de queso, lo miró a los ojos y lo olvidó para siempre.
- **Manías:** pulir su armadura (que siempre huele a establo), contar el árbol genealógico de personas que no conoce, y llamar "pura casualidad" a sus errores.
- **Forma de hablar:** solemne, anticuada y con exceso de "vos", "vuestra merced" y "por mi honor". Se le quiebra la voz cuando hay caballos.
- **Frases tipo:** "Por mi honor, no estoy temblando: es la armadura." / "Un caballero jamás huye. Se reposiciona." / "¿Eso... tenía cuatro patas?"
- **Habilidades:** `carga_heroica` (golpe poderoso al frente enemigo; mínima), ver sección 10.4.

### 4.3 Madame Pimentina Sazón (`pimentina`)

- **Trasfondo:** cocinera de la corte de Camembert, despedida por "interpretar con demasiada libertad" un guiso real: el guiso explotó, pero lo hizo con elegancia. Descubrió que su cocina tenía poder mágico y se hizo maga sin dejar de ser cocinera.
- **Manías:** probar todo (hasta lo que no es comestible), corregir la sazón de las batallas, y llamar a su varita "mi cucharón".
- **Forma de hablar:** dramática, refinada y con metáforas de cocina: "esto está crudo", "le falta fondo". Habla de la gente como si fueran platos.
- **Frases tipo:** "Un hechizo sin queso es una ensalada triste." / "Esa herida necesita reposo y un poco de mantequilla." / "Querido, el pánico en frío no tiene nada que ver con el pánico en caliente."
- **Habilidades:** `fondue_flamigera` (mínima) y `raclette_curativa` **(extra)**, que gastan queso (ver 4.7). En la mínima Pimentina tiene una sola habilidad (docs/06 D-23).

### 4.4 Rufino el Memorioso (`rufino`)

- **Trasfondo:** bardo que nunca ha terminado una balada completa porque siempre le pagan para que pare. Descubrió su verdadero negocio al comprobar que la gente paga más por su silencio que por su música. Cada actuación acaba en una negociación.
- **Manías:** rimar en mal momento, apuntar todo en un cuaderno ("para la crónica") y subir el precio del silencio según el humor del público.
- **Forma de hablar:** versos mal medidos, cantinelas, y la frase "esto va a la balada".
- **Frases tipo:** "Si me das un queso, me callo; si me das dos, me callo con mucho sentimiento." / "¡Y entonces nuestro héroe, que era un cobarde de buen corazón...!" / "Tengo una rima para esto, pero no te va a gustar."
- **Habilidades:** `balada_inspiradora` (mínima) y `silencio_pagado` (objetivo) (ver 4.7).

### 4.5 Tuerca (`tuerca`)

- **Trasfondo:** ladrón de edad indefinida y estatura que invita a subestimarlo. Roba por vocación, no por necesidad, y lleva una libreta con los botines que "devolverá algún día". Se unió a la Banda por tener "buena cobertura": nadie sospecha de un grupo tan malo.
- **Manías:** contar los quesos del grupo dos veces al día, mirar los bolsillos ajenos como quien lee carteles y hablar bajo aunque no haga falta.
- **Forma de hablar:** susurros, apodos, tratar todo como un trato. Dice "tomo prestado" y "encuentro" con cara de santo.
- **Frases tipo:** "Yo no he sido. Ni he estado. Ni tengo bolsillos." / "Ese queso estaba solo, y nadie debería estar solo." / "No es robar, es redistribuir con ventaja."
- **Habilidades:** `rebuscar_bolsillos` (mínima) (ver 4.7).

### 4.6 Relaciones

| Pareja | Relación |
|---|---|
| Baldomero y Pimentina | Él la admira ciegamente y la llama "señora de los fogones"; ella lo considera "un buen plato decorativo". Ella cocina su ración con más cariño; él no lo nota. |
| Baldomero y Rufino | Rufino ha escrito la "Balada del Caballero que Temía" y la canta cada vez que hay un caballo. Baldomero le paga para que no la cante, con orgullo y a regañadientes. |
| Baldomero y Tuerca | Tuerca le roba pequeñeces (un guante, un botón) y se las devuelve en el siguiente combate como si fuera un milagro. Baldomero cree en los milagros. |
| Pimentina y Rufino | Rivalidad artística: ella opina que lo suyo no es música, él que lo suyo no es magia. Se respetan en secreto. |
| Pimentina y Tuerca | Tuerca roba especias; ella lo sabe y deja los frascos a su alcance a propósito para que la pague con una buena sopa. |
| Rufino y Tuerca | Sociedad de silencios: Tuerca paga a Rufino para que no cante sus golpes; Rufino cobra a Tuerca por no cantarle a los guardias. Ambos creen que ganan. |

> **(extra)** Si ambos están en la compañía, estas relaciones pueden dar pequeños eventos de ±1 de moral (`afinidad(A, B, Valor)`). No son necesarios para el combate.

### 4.7 Cómo funcionan los rasgos en la historia (propuesta de detalle)

El canon define el efecto de cada rasgo en una frase. Esta es la lectura narrativa que propongo para que las reglas se vean claras en pantalla. Los nombres de predicados son los canónicos de docs/06 §2.7:

| Rasgo | Versión | Lectura en el mundo | Regla propuesta |
|---|---|---|---|
| `teme_caballos` | mínima | Baldomero no ataca a nada de clase `caballo` (salvo con la `venda_de_caballos`) y recibe +2 daño de ellos. | `teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A).` (la misma regla la usan `puede_atacar/2` y `rasgo_no/1`, D-19); `\+ (teme(A, C), clase(B, C))` en `puede_atacar/2`; `modificador(baldomero, E, 2)` si `clase(E, caballo)`; `ignora_miedo(P) :- equipado(P, venda_de_caballos).` |
| `hechizos_de_cocina` | mínima | Cada hechizo de Pimentina gasta **1 queso** de la despensa (cualquiera). Sin queso, la habilidad **falla**. | `puede_habilidad(pimentina, H) :- coste_queso(H, N), queso_total(Q), Q >= N.` |
| `cobra_por_callar` | objetivo | `balada_inspiradora` sube la moral del grupo +1. En el objetivo, además deja a Rufino `cantando` (el grupo ataca -1 por distracción) hasta que se paga `silencio_pagado` (1 queso). En la mínima solo hay el +1 de moral, sin `cantando`. | `cantando(rufino)` (derivado de `alterado(rufino, cantando, fijo)`, no caduca por turnos); `modificador(A, _, -1) :- cantando(rufino), activo(A).` |
| `manos_largas` | objetivo (la habilidad base `rebuscar_bolsillos` es mínima) | `rebuscar_bolsillos`: en un enemigo con `lleva_queso`, gana 1 queso. Si el enemigo está en estado `alerta` (**extra**), baja la moral del grupo -1. | `lleva_queso(E)` en `mundo`; `\+ alerta(E) -> ganar_queso(...) ; mod_moral(Id, -1)` (efectos de `estado:aplicar_efectos/1`). |

> Los estados `aturdido`, `cantando` y `apestado` se escriben siempre como predicados derivados de `alterado/3`, nunca como `estado(P, E)` (docs/06 X-15). Una "habilidad sencilla" por personaje en la mínima (X-47): daño (`carga_heroica`), daño que gasta queso (`fondue_flamigera`), +1 moral (`balada_inspiradora`) y +1 queso (`rebuscar_bolsillos`).

---

## 5. NPC importantes

Ocho NPC. Los que están marcados **(extra)** pueden quedar como texto sin interacción. La columna "Versión" indica cuándo entra cada uno (mínima / objetivo / extra). Ningún NPC compra ni vende queso (D-10): las "ofertas" son contratos, recompensas y, en la tienda extra, objetos no queseros.

| id | Versión | Nombre | Zona | Quién es | Qué quiere | Qué ofrece |
|---|---|---|---|---|---|---|
| `mantecosa` | mínima | Doña Mantecosa | `taberna` | Dueña del Cuajo Torcido. Viuda de tres tabernas y de un posadero. Cobra todo, perdona nada. | Que la Banda pague los sueldos de su gente antes de salir y no rompa muebles. | Descanso (cuesta 2 quesos; sin `deuda_taberna`: si no hay 2 quesos, simplemente no se puede), tablón de contratos. Si se sale sin pagar, la moral cae (ver 3.1). |
| `ricota` | **(extra)** | Ricota el Tendero | `aldea` | Comerciante risueño que cree que todo se arregla con una oferta. | Vender objetos baratos y recibir los quesos curados del contrato `silvestre_para_ricota`. **No compra ni vende queso.** | En la v1 solo aparece como texto. Con la tienda de objetos **(extra)**: `pocion`, `cataplasma_de_requeson`, `pan_duro`, `cucharon_de_hierro`, `baston_de_queso_duro`, `escudo_tapadera`, a cambio de queso por unidades. Su contrato `silvestre_para_ricota` (extra) le entrega los quesos silvestres. |
| `alcaldesa_nata` | mínima | Alcaldesa Nata | `aldea` | Máxima autoridad de la aldea; gobierna con la ayuda de una lista de quejas. | Que alguien resuelva sus problemas sin hacer más. | Contratos pequeños: `ratas_del_granero`, `gato_en_el_arbol` (mínima); `fantasma_charlatan` (objetivo). Como recompensa especial, la `venda_de_caballos`. |
| `ermitano_penicilio` | **(extra)** | Hermano Penicilio | `bosque` | Ex-afinador que se retiró al bosque a estudiar el moho y acabó amigo suyo. Habla con los hongos. | Que nadie queme su cabaña ni su moho. | Regala o intercambia por contrato `queso_silvestre` y `salmuera` **(extra)** (no los vende); información sobre el Gran Rancio ("viene de abajo"). |
| `gallina_noble` | mínima | Lady Clotilde Plumífera | `camino_real` | Gallina de alta cuna que viaja con modales y un ramillete de plumas. Muy culta y muy picajosa. | Llegar al Castillo para el Baile de la Cuajada sin que nadie la despluma. | Contrato canon `gallina_noble`: pagará 14 quesos y 1 `brie` si llega entera (7 si llega malherida). Si la matan, la familia manda cartas. En la mínima su vida se mide con un contador de golpes recibidos (D-33); como combatiente aliada pasiva es opcional. |
| `fantasma_charlatan` | objetivo | Eustaquio, el fantasma charlatán | `aldea` | Mayordomo del último príncipe de Roquefort. Murió esperando su cena. Ahora asusta casas... para tener con quien hablar. | Que alguien escuche su historia completa. | Contrato `fantasma_charlatan`. Si se le escucha (acción de diálogo sin combate), entrega la `llave_mohosa` y un mapa de las cuevas. |
| `capitan_pecorino` | objetivo | Capitán Pecorino Duro | `camino_real` / `castillo` | Jefe de las Lanzas Parmesanas. Todo lo que dice parece un sermón. | Que la Banda se vaya y que el rey lo contrate a él. Acabará pidiendo ayuda a regañadientes. | Rumores y avisos. Entrega el `estoque_de_parmesano` como recompensa de contrato, no lo vende (rival que reconoce el mérito, con la boca pequeña). |
| `rey_brieto` | mínima | Brieto IV "el Mal Curado" | `castillo` | Rey de Camembert. Amable, ingenuo y pegajoso. Su reinado coincide con el Gran Rancio. | Detener el moho de su despensa antes de que se entere el Gremio. | Contrato `despensa_real`, entrega `sello_real` (objetivo), paga una recompensa muy alta (40 quesos) si el jefe de las cuevas cae. |

### 5.1 Ganchos de contrato (sugerencia para el documento de contratos)

Este documento solo sugiere ids y encajes; el documento de contratos decide detalles. Siguiendo el canon (`contrato(gallina_noble, camino_real, ...)`), el id del contrato puede coincidir con el del NPC.

Las recompensas son las escaladas del documento 04 (D-09): con 12 cheddar iniciales y 4 de comida al día, las recompensas van de 4 a 40 quesos (en la mínima: 9, 7, 14 y 40; valores confirmados por el autor el 2 de noviembre de 2026 tras el recálculo de 04 §9.2). El queso de recompensa entra siempre como cheddar fresco salvo que se indique otro tipo.

| id contrato | Versión | Zona | Resumen | Quién lo da | Requisito de ejemplo | Recompensa |
|---|---|---|---|---|---|---|
| `ratas_del_granero` | mínima | `aldea` | Echar a las ratas queseras del granero. | `alcaldesa_nata` | Ninguno (tutorial). | 9 quesos y 1 `pocion` (X-46: sin tienda, la poción llega por recompensa). |
| `gato_en_el_arbol` | mínima | `aldea` | Bajar un gato de un árbol (el árbol no coopera). | `alcaldesa_nata` | Ninguno. | 7 quesos y la `venda_de_caballos`. |
| `gallina_noble` | mínima | `camino_real` | Escoltar a Lady Clotilde (canon). | `gallina_noble` | `rasgo_no(teme_caballos)` (canon): se evalúa contra los miembros activos que no ignoran el miedo (con la venda, Baldomero cumple; D-19). | 12 quesos y 1 `brie`. |
| `despensa_real` | mínima | `castillo` | Parar el Gran Rancio y derrotar al `gran_roquefort`. | `rey_brieto` | `contratos_cumplidos_min(3)` (y, en la variante dura **(extra)**, tener `llave_mohosa`). | 40 quesos. |
| `fantasma_charlatan` | objetivo | `aldea` | Convencer al fantasma de irse de la casa. | `alcaldesa_nata` | Ninguno (04 pide moral media >= 4). | 8 quesos y la `llave_mohosa`. |
| `peaje_del_ganso` | objetivo | `camino_real` | Poner fin al peaje abusivo de un ganso. | Carretero anónimo | Ninguno. | 9 quesos y el `cucharon_de_hierro`. |
| `silvestre_para_ricota` | **(extra)** | `bosque` | Traer 3 `queso_silvestre`. | `ricota` | Ninguno. | 10 quesos y el `baston_de_queso_duro`. |

Contratos **(extra)** definidos en el documento 04 y no detallados aquí: `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna`.

---

## 6. Bestiario

Doce enemigos diseñados, ordenados por dificultad; **cinco en la mínima** (`rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort`), siete en el objetivo (+ `ganso_recaudador`, `arquero_aburrido`) y los doce en la ampliación. Los atributos son una **propuesta inicial**; `bandido_torpe` es canon (12/5/2). El `lleva_queso` marca quién puede ser objetivo de `rebuscar_bolsillos` y quién suelta **1 queso de botín** al caer derrotado (el queso entra por botín, nunca se compra). La **clase** alimenta reglas como las del rasgo `teme_caballos`. En el código los combatientes enemigos son instancias `e(Tipo, N)`; la columna `id` es el `Tipo`.

### 6.1 Tabla resumen

| Versión | Nivel | id | Nombre | Vida | Ataque | Defensa | Fila | Alcance | Clase | Zona(s) | Lleva queso |
|---|---|---|---|---|---|---|---|---|---|---|---|
| mínima | 1 | `rata_quesera` | Rata Quesera | 8 | 4 | 0 | frente | cuerpo | `roedor` | `aldea`, `bosque` | no |
| mínima | 1 | `bandido_torpe` | Bandido Torpe | 12 | 5 | 2 | frente | cuerpo | `humano` | `bosque`, `camino_real` | sí |
| mínima | 1 | `moho_saltarin` | Moho Saltarín | 10 | 4 | 0 | frente | cuerpo | `hongo` | `bosque`, `cuevas` | no |
| (extra) | 2 | `seta_chismosa` | Seta Chismosa | 14 | 3 | 3 | retaguardia | distancia | `hongo` | `bosque` | no |
| objetivo | 2 | `ganso_recaudador` | Ganso Recaudador | 16 | 6 | 2 | frente | cuerpo | `ave` | `camino_real` | sí |
| objetivo | 2 | `arquero_aburrido` | Arquero Aburrido | 11 | 7 | 1 | retaguardia | distancia | `humano` | `camino_real`, `castillo` | sí |
| mínima | 3 | `bandido_montado` | Bandido Montado | 18 | 7 | 3 | frente | cuerpo | `caballo` | `camino_real` | sí |
| (extra) | 3 | `jinete_parmesano` | Jinete Parmesano | 24 | 9 | 5 | frente | cuerpo | `caballo` | `camino_real`, `castillo` | sí |
| (extra) | 3 | `guardia_de_corteza` | Guardia de Corteza | 28 | 8 | 7 | frente | cuerpo | `constructo` | `castillo` | no |
| (extra) | 4 | `murcielago_azul` | Murciélago Azul | 14 | 8 | 1 | retaguardia | distancia | `volador` | `cuevas` | no |
| (extra) | 4 | `golem_de_queso_duro` | Gólem de Queso Duro | 40 | 10 | 6 | frente | cuerpo | `constructo` | `cuevas` | no |
| mínima | Jefe | `gran_roquefort` | El Gran Roquefort | 60 | 11 | 4 | frente | cuerpo | `queso_vivo` | `cuevas` | no |

> Nota de balance: contra defensa alta, el daño base `max(1, Atq − Def + M)` baja mucho. Las habilidades de Pimentina (daño fijo, ignora defensa) y los objetos con bonificación de ataque son las herramientas para los combates de nivel 3-4 y el jefe.
>
> Datos en `mundo`: `enemigo/4` (canon), `clase/2`, `alcance/2`, `fila_preferida/2`, `lleva_queso/1`.

### 6.2 Fichas

**La IA enemiga (docs/06 D-24, X-42).** `accion_enemigo/2` es la IA **canon de tres reglas** (`curarse`, `atacar`, `defender`) más, en la mínima, **como máximo tres acciones especiales**, cada una con su cláusula y su gemela sin corte para el oráculo de pruebas: `robar_queso`, `embestir` e `invocar_moho`. Las otras cinco acciones listadas en 10.4 (`contaminar`, `curar_aliado`, `cobrar_peaje`, `apuntar`, `esporas_curativas`) y los perfiles por enemigo están descritos abajo como **(extra)** o **objetivo** y no se implementan en la mínima. En el objetivo se añaden dos (`cobrar_peaje`, `apuntar`; asignación propuesta aquí para los dos enemigos objetivo, hasta sumar cinco); `contaminar`, `curar_aliado` y `esporas_curativas` como acción propia quedan **(extra)**. Cuando una ficha dice "IA mínima", esa es la que se programa; la línea "perfil completo" se conserva como ampliación.

**1. Rata Quesera (`rata_quesera`) — mínima.** Roedor de linaje antiguo que cree tener derecho sobre toda la despensa. Rasgo cómico: se hace la muerta y vuelve a levantarse con cara de ofendida. IA mínima: si hay queso en el inventario del grupo, `robar_queso`; si no, `atacar`.

**2. Bandido Torpe (`bandido_torpe`, canon) — mínima.** Ladrón de camino con más entusiasmo que talento. Rasgo cómico: confunde "alto ahí" con "hola". IA mínima: la canon (`atacar` al más débil). Perfil completo: huye si queda con menos de 4 de vida **(extra)**.

**3. Moho Saltarín (`moho_saltarin`) — mínima.** Bola de moho que salta por puro placer. Rasgo cómico: se disculpa tras cada golpe, con esporas. IA mínima: la canon (`atacar`); es también el enemigo que invoca el jefe. Perfil completo **(extra)**: al golpear, `contaminar`, y **el lote de queso más curado de la despensa envejece +2 días** (determinista; efecto `envejecer_lote/1`); si se le lanza queso rancio (`lanzar`, extra), **se cura 3** (le encanta). `contaminar` si hay despensa; si no, `atacar`.

**4. Seta Chismosa (`seta_chismosa`) — (extra).** Hongo de retaguardia que lo sabe todo de todos. Rasgo cómico: cuenta secretos que no vienen a cuento ("Rufino en realidad no sabe leer música"). Efecto: las esporas curan a un aliado 4 de vida. IA: `curar_aliado` si algún aliado está bajo la mitad de vida; si no, `atacar`.

**5. Ganso Recaudador (`ganso_recaudador`) — objetivo.** Ave aduanera con licencia, sello y mala leche. Rasgo cómico: te da un recibo antes de picarte. IA: `cobrar_peaje` (si el grupo tiene `sello_real`, no ataca y se cuadra); si no, `atacar` al de frente.

**6. Arquero Aburrido (`arquero_aburrido`) — objetivo.** Arquero de segunda fila al servicio de quien pague. Rasgo cómico: dispara mirando el reloj. Ataca a distancia, así que puede golpear a retaguardia aunque el frente siga en pie. IA: `apuntar` al objetivo de menos vida.

**7. Bandido Montado (`bandido_montado`) — mínima.** Cualquier bandido que haya conseguido un caballo y un abrigo de héroe. Rasgo cómico: el caballo es mucho más seguro que él. Clase `caballo`: **Baldomero no puede atacarle y recibe +2 de daño** (salvo con la `venda_de_caballos`, que le permite atacarle con -3 de ataque). IA: `embestir` (daño +2 al primer turno); luego `atacar`.

**8. Jinete Parmesano (`jinete_parmesano`) — (extra).** Lancero de élite de las Lanzas Parmesanas; aparece cuando el capitán Pecorino quiere dejar clara su superioridad. Rasgo cómico: avisa de cada ataque como si fuera un decreto. Clase `caballo`. IA: `embestir`, luego `atacar`; `defender` si queda bajo un cuarto de vida y aún no ha usado esa acción.

**9. Guardia de Corteza (`guardia_de_corteza`) — (extra).** Armadura vacía hecha de corteza de queso duro que obedece solo a su manual. Rasgo cómico: se detiene a leer el manual en pleno combate. Defensa alta; siempre `defender` en el primer turno, después `atacar`.

**10. Murciélago Azul (`murcielago_azul`) — (extra).** Mamífero de las cuevas, azul por vivir entre moho. Rasgo cómico: chilla en cuatro tonos distintos, ninguno agradable. Ataca a distancia. IA: `apuntar` al de retaguardia; Rufino, que se siente muy aludido, queda `aturdido` (**extra**).

**11. Gólem de Queso Duro (`golem_de_queso_duro`) — (extra).** Construido con un parmesano de trescientos años, una receta secreta y mucho tiempo libre. Rasgo cómico: nadie sabe quién lo montó, ni por qué tiene una gorra. IA: `atacar` siempre al de frente; cada tercer turno `defender`.

**12. El Gran Roquefort (`gran_roquefort`) — mínima (jefe).** El príncipe Roque de Fort, que se retiró a madurar y se pasó cuarenta años. Ahora es un queso azul del tamaño de un carruaje, con barba de moho, opiniones firmes y un deseo noble: **"madurar" el reino entero**, convencido de que todo mejora con tiempo. Habla con dignidad y lentitud, como quien lleva décadas pensando una frase. Rasgos cómicos: se queja de que "la gente de hoy tiene prisa" y trata a los intrusos como visitas mal educadas. Sin fases, sin monólogo y sin aura en la mínima; **no se puede huir de él** (D-29). En las reglas de la IA se le identifica con una guarda `instancia(E, gran_roquefort)`, no con un átomo en el primer argumento (X-19).

IA por prioridad (esquema; usa el corte como en el canon, y cada regla tiene su gemela sin corte para el oráculo):
1. Si `vida_baja` y le quedan esporas (`curarse`): cura 8, una vez (la narración la llama "esporas curativas"; es la regla `curarse` del canon, no una acción especial más).
2. Si no hay `moho_saltarin` aliado vivo: `invocar_moho` (invoca 1 moho saltarín, máx. 2 veces).
3. Si hay queso rancio en la despensa del grupo: `atacar` al de frente con +2 (redacción corregida; antes decía "rancio o rancio en despensa"). **Objetivo** (el bonus por rancio, docs/06 §5.1).
4. Por defecto: `atacar` al más débil.

**Condición de victoria alternativa (extra):** si el grupo tiene `llave_mohosa` y escucha al fantasma antes, el Gran Roquefort pierde 10 de vida inicial ("recuerda a su mayordomo").

### 6.3 Progresión sugerida

| Tramo del recorrido | Enemigos habituales | Idea |
|---|---|---|
| Tutorial (aldea) — mínima | `rata_quesera` | Aprender atacar, defender y habilidad. |
| Primeras salidas (bosque) — mínima (solo `bandido_torpe`, `moho_saltarin`); `seta_chismosa` (extra) | `bandido_torpe`, `moho_saltarin`, `seta_chismosa` | Aprender filas y estados; la maduración forzada es (extra). |
| Camino (medio) — mínima (`bandido_montado`); objetivo (`ganso_recaudador`, `arquero_aburrido`) | `ganso_recaudador`, `arquero_aburrido`, `bandido_montado` | Ver el rasgo de Baldomero en acción; descubrir la retaguardia. |
| Castillo (alto) — (extra) | `guardia_de_corteza`, `jinete_parmesano` | Defensa alta, necesidad de equipo y de habilidades. |
| Cuevas (final) — mínima (solo el jefe); `murcielago_azul` y `golem_de_queso_duro` (extra) | `murcielago_azul`, `golem_de_queso_duro`, `gran_roquefort` | Combates largos, uso de todo lo aprendido. |

---

## 7. Quesos y objetos

### 7.1 Estados de maduración (canon)

Cada unidad de queso tiene `tipo` y `edad` en días (`queso(Tipo, Edad, N)`; la categoría la da `categoria_queso/2`, no existe `estado_queso/2`).

| Estado | Edad | Valor (informativo en la v1) | Si se come |
|---|---|---|---|
| `fresco` | 0 a 2 | `valor_base` | Alimenta. Sin extras. |
| `curado` | 3 a 9 | `valor_base + 2` (máximo) | Alimenta. Como **ración extra** (`comer(Tipo)`) añade el **efecto del tipo**. |
| `rancio` | 10 o más | **1** (casi nada; como máximo lo que vale el fresco, X-34) | Alimenta, pero la **moral baja 2** y se pierde el efecto. |

**Unidades, no valor (D-13).** En la v1 todo se paga y se cobra **por unidades**: un sueldo de 2 son 2 quesos cualesquiera, una recompensa de 12 son 12 cheddar. `valor_queso/3` existe para presentar la despensa y para fijar precios en la tienda extra, pero no interviene en ninguna decisión de pago.

**Qué queso se paga.** Los pagos (sueldos, multas, descanso, habilidades, y precios de la tienda extra) se hacen **con el queso más rancio primero** (el Gremio lo considera "una forma de reciclar").

**Qué queso se come (D-11).** La ración diaria automática consume **fresco → curado → rancio al final**, para que el rancio siga existiendo en la despensa (lanzar, Ley del Hedor, bonus del jefe, curación del moho). La ración diaria **solo alimenta** (con el penalizador de moral -2 si toca un rancio). El **efecto del tipo** solo se obtiene con `comer(Tipo)`, una ración voluntaria extra (nivel "Debería"; en la mínima, `comer` con efecto "cura 2").

### 7.2 Tipos de queso

Ningún tipo se compra ni se vende: la columna "Cómo entra" lista las únicas fuentes (recompensa, botín, hallazgo, inicio de partida).

| id | Versión | Nombre | Valor base | Cómo entra | Efecto al comer curado (`comer/1`) | Uso especial | Nota |
|---|---|---|---|---|---|---|---|
| `cheddar` | mínima | Cheddar | 2 | 12 de inicio; recompensas de contrato; botín | Cura 2 vida | La unidad del pago de contratos y de la ración. | `queso(cheddar, 0, 12)` al empezar (docs/06 D-09). |
| `brie` | mínima | Brie | 3 | Recompensa (`gallina_noble`: 1 brie); regalos del Castillo | +1 moral | Bonito, caro y orgulloso. | |
| `queso_silvestre` | objetivo | Queso Silvestre | 1 | Hallazgo en el bosque; evento | Cura 2 vida | Contrato `silvestre_para_ricota` (extra). | Sabor misterioso. |
| `roquefort` | objetivo | Roquefort | 3 | Cuevas, botín | +2 ataque hasta el fin del siguiente combate | Rancio: `lanzar` hace 6 de daño (extra). | Mal educado pero potente. |
| `requeson` | (extra) | Requesón | 1 | Hallazgo en la aldea; evento | Cura 1 vida | Ingrediente de `cataplasma_de_requeson`. | Blando y barato. |
| `gouda` | (extra) | Gouda | 3 | Recompensa de contrato, hallazgo en caravanas (evento); no se compra | Cura 3 vida | Alimento "de viaje". | Redondo y cómodo. |
| `camembert` | (extra) | Camembert | 4 | Castillo (regalo, recompensa) | +2 moral | Con camembert curado, los hechizos de Pimentina valen +2. | Símbolo del reino. |
| `parmesano` | (extra) | Parmesano | 5 | Lanzas Parmesanas, Castillo (recompensa, botín) | +2 defensa hasta el fin del siguiente combate | La moneda favorita de las compañías serias. | El más caro. |

Reglas de queso rancio (todos los tipos):
- **Lanzar** **(extra)**: cualquier queso rancio se puede arrojar a un enemigo: 3 de daño (6 si es `roquefort`) y deja `apestado` (ataque -2 durante 2 turnos). Excepciones: al `moho_saltarin` lo **cura** 3. El comando `lanzar` no entra en la v1 (docs/06 §5.1).
- **Ingrediente de Pimentina** (objetivo): con queso rancio, `fondue_flamigera` hace +2 de daño ("tiene más carácter").
- **Comer**: moral -2 (en la ración diaria o con `comer`).

### 7.3 Objetos (20)

Slots de equipo: `arma`, `cuerpo`, `accesorio`. Un personaje lleva como máximo un objeto por slot. `solo_para/2` indica restricciones.

**Dónde están los objetos (D-10, X-33, X-46).** El inventario común es `lleva(compania, Objeto, N)` (en general `lleva(Id, Objeto, Cantidad)`); lo que un personaje lleva puesto es `equipado(Id, Objeto)`. En la v1 **no hay tienda**: todo objeto llega como **recompensa de contrato** o **botín** (la columna "Cómo se obtiene"). La columna "Precio" solo se usa en la **tienda de objetos (extra)**: el precio es un número de **quesos por unidades** (se paga gastando primero lo más rancio), no un "valor de queso". Los objetos no queseros nunca se compran con otro bien ni se pueden vender. Datos: `efecto_objeto/2`, `bonus/3` en `mundo`.

#### Consumibles (7)

| id | Versión | Nombre | Cómo se obtiene | Precio (tienda extra) | Efecto jugable | Regla (esquema) |
|---|---|---|---|---|---|---|
| `pocion` | mínima | Poción de Suero Lácteo | Recompensa (1 en `ratas_del_granero`); botín | 5 | Cura 10 de vida a un aliado. Los enemigos con `tiene(E, pocion)` la usan en su IA (canon). | `efecto_objeto(pocion, curar(10)).` |
| `cataplasma_de_requeson` | (extra) | Cataplasma de Requesón | Recompensa; tienda (extra) | 3 | Cura 5 y quita `aturdido`. | `efecto_objeto(cataplasma_de_requeson, [curar(5), quitar(aturdido)]).` |
| `pan_duro` | (extra) | Pan Duro | Recompensa; tienda (extra) | 1 | Sustituye la ración de queso de **un** miembro por un día, pero su moral baja 1 ("no es queso"). | `racion(pan_duro, 1). efecto_objeto(pan_duro, mod_moral(-1)).` |
| `suero_fermentado` | (extra) | Suero Fermentado | Recompensa; tienda de la taberna (extra) | 4 | Hasta fin del combate: ataque +3, defensa -2 a un aliado. | `efecto_objeto(suero_fermentado, [mod(ataque,3), mod(defensa,-2)]).` |
| `tapones_de_cera` | (extra) | Tapones de Cera | Recompensa; tienda de la taberna (extra) | 3 | Durante un combate el grupo ignora el estado `cantando` de Rufino. | `efecto_objeto(tapones_de_cera, ignorar(cantando)).` |
| `salmuera` **(extra)** | (extra) | Salmuera | Recompensa (`paz_del_moho`); botín | 6 | El lote de queso elegido **no envejece** durante 3 días. | `efecto_objeto(salmuera, pausar_maduracion(3)).` |
| `cuajo_de_emergencia` **(extra)** | (extra) | Cuajo de Emergencia | Castillo (botín) | 15 | Revive a un caído con 1 de vida (los caídos solo existen dentro del combate, D-17). | `efecto_objeto(cuajo_de_emergencia, revivir(1)).` |

#### Equipables (11)

| id | Versión | Nombre | Slot | Quién | Cómo se obtiene | Precio (tienda extra) | Efecto jugable | Regla (esquema) |
|---|---|---|---|---|---|---|---|---|
| `cuchillo_de_untar` | (extra) | Cuchillo de Untar | `arma` | cualquiera | Recompensa; tienda de la taberna (extra) | 3 | Ataque +1. | `bonus(cuchillo_de_untar, ataque, 1).` |
| `cucharon_de_hierro` | objetivo | Cucharón de Hierro | `arma` | cualquiera | Recompensa de `peaje_del_ganso` | 6 | Ataque +2. | `bonus(cucharon_de_hierro, ataque, 2).` |
| `estoque_de_parmesano` | objetivo | Estoque de Parmesano | `arma` | cualquiera | Recompensa de `caballo_fugado` (extra) o de `capitan_pecorino` tras un contrato exitoso (no se vende) | 14 | Ataque +4. | `bonus(estoque_de_parmesano, ataque, 4).` |
| `baston_de_queso_duro` | (extra) | Bastón de Queso Duro | `arma` | `pimentina` | Recompensa de `silvestre_para_ricota` (extra) | 8 | Sus hechizos hacen/curan +2. | `bonus(baston_de_queso_duro, hechizo, 2).` |
| `laud_desafinado` | (extra) | Laúd Desafinado | `arma` | `rufino` | Recompensa; tienda de la taberna (extra) | 7 | `balada_inspiradora` da +2 moral en lugar de +1, pero `silencio_pagado` cuesta 2 quesos. | `bonus(laud_desafinado, balada, 1). coste_extra(laud_desafinado, silencio, 1).` |
| `ganzua_de_oro` | (extra) | Ganzúa de Oro | `arma` | `tuerca` | Recompensa de `reconocimiento_de_cuevas` (extra); Cuevas (botín) | 10 | `rebuscar_bolsillos` da 2 quesos en vez de 1. | `bonus(ganzua_de_oro, rebuscar, 1).` |
| `coraza_de_corteza` | (extra) | Coraza de Corteza | `cuerpo` | cualquiera | Recompensa de `inspeccion_del_manual` (extra) | 10 | Defensa +3. | `bonus(coraza_de_corteza, defensa, 3).` |
| `delantal_encantado` | (extra) | Delantal Encantado | `cuerpo` | `pimentina` | Castillo (recompensa, botín) | 9 | Defensa +1. El primer hechizo de cada combate no gasta queso. | `bonus(delantal_encantado, defensa, 1). primer_hechizo_gratis(delantal_encantado).` |
| `escudo_tapadera` | (extra) | Escudo Tapadera | `accesorio` | cualquiera | Recompensa; tienda de la aldea (extra) | 5 | Defensa +2. | `bonus(escudo_tapadera, defensa, 2).` |
| `venda_de_caballos` | mínima | Venda de Caballos | `accesorio` | `baldomero` | Recompensa de `gato_en_el_arbol` | (no se vende) | Baldomero **puede** atacar a la clase `caballo`, pero con ataque -3 contra ellos. | `ignora_miedo(baldomero) :- equipado(baldomero, venda_de_caballos). modificador(baldomero, E, -3) :- equipado(baldomero, venda_de_caballos), clase(E, caballo).` |
| `trebol_de_cuatro_quesos` | (extra) | Trébol de Cuatro Quesos | `accesorio` | cualquiera | Recompensa de `cena_de_eustaquio` (extra) | — | Al pasar cada día, la moral del portador +1 (máx. 10). | `al_amanecer(P) :- equipado(P, trebol_de_cuatro_quesos), mod_moral(P, 1).` |

#### Objetos clave (2)

| id | Versión | Nombre | Cómo se obtiene | Efecto jugable |
|---|---|---|---|---|
| `sello_real` | objetivo | Sello Real | `rey_brieto` (al aceptar `despensa_real`) | Prueba de que la Banda actúa por la Corona: `ganso_recaudador` no ataca ni cobra peaje. **(extra)**: abre la armería del castillo. |
| `llave_mohosa` | (extra) | Llave Mohosa | `fantasma_charlatan` (recompensa del contrato) | Abre la puerta interior de las Cuevas (la puerta interior es extra). Condición de la variante dura del contrato `despensa_real` (extra): `requiere(objeto(llave_mohosa))`; en la versión normal de ese contrato no se exige. |

---

## 8. Leyes cómicas del mundo

Cada ley es una regla que el narrador puede citar. Todas se pueden traducir a una cláusula. Los nombres son los canónicos de docs/06 §2.7. Versión: leyes 1, 2, 4, 5, 6 y 7 **mínima**; ley 3 **(extra)** (depende de `lanzar` y de `apestado`); ley 8 **(extra)** (no hay comando `abandonar` en la v1).

1. **Ley del Cuajo (la magia).** *"Toda magia necesita queso."* Los hechizos se alimentan de queso; sin despensa no hay hechizo. Pimentina es la única persona del continente con talento natural. Regla: `puede_habilidad(P, H) :- coste_queso(H, N), queso_total(Q), Q >= N.`
2. **Ley de la Maduración.** *"Todo mejora hasta el día 3 y empeora desde el día 10."* Aplica a quesos y, por analogía, a rencores, chistes y compromisos. Regla: `categoria_queso(Edad, Categoria)` según edad (7.1).
3. **Ley del Hedor (extra).** *"Lo que se pudre, apesta; y lo que apesta, pega."* El queso rancio nunca desaparece: se puede arrojar y deja `apestado` al objetivo. Regla: `efecto_lanzar(Tipo, rancio, [dano(3), estado(apestado)])`.
4. **Ley de la Huelga Sagrada.** *"Nadie combate con la moral por los suelos."* Un miembro cuya moral baja a 2 o menos (porque no se le paga, porque pasa hambre o porque el grupo ha tenido un mal día) entra en huelga y no combate. Ni los monstruos lo obligan: respetan el piquete y esperan fuera. La huelga se deriva **solo de la moral**. Regla: `esta_en_huelga(A) :- moral(A, M), parametro(moral_huelga, T), M =< T.` y `puede_atacar(A, _) :- \+ esta_en_huelga(A)` (y `puede_combatir(Id)`: miembro vivo y no en huelga).
5. **Ley del Pánico Específico.** *"Todo ser tiene miedo de exactamente una cosa, y está registrado."* Es la base de los rasgos tipo `teme_caballos`. Las leyes oficiales exigen que cada miedo tenga clase, y que el Gremio de Afinadores lo certifique. Regla: `teme(Quién, Clase)` (consciente de la `venda_de_caballos` a través de `ignora_miedo/1`).
6. **Ley de la Taberna.** *"Dentro del local no se pelea: se discute."* En `taberna` el combate está prohibido (por multa). Regla: `\+ permite_combate(taberna)`.
7. **Ley de la Ruta Pegajosa.** *"Todo viaje dura un día, porque el camino se te pega a las botas."* Los caminos están pavimentados con corteza de queso y siempre hay que despegarse algo. Explica por qué moverse entre zonas cuesta exactamente un día. Regla: `puede_viajar(Z) :- en_zona(Actual), adyacente(Actual, Z).` (la simetría de `conexion/2` la da `adyacente/2`); el comando `ir(Z)` valida esa regla y aplica el efecto de avanzar un día.
8. **Ley del Contrato Escrito (extra).** *"Lo firmado vale, aunque esté escrito en una corteza o lo firme una gallina."* Un contrato aceptado obliga; abandonarlo cuesta moral. Regla: `puede_abandonar(C) :- contrato_activo(C).`, con el efecto `mod_moral(Id, -2)` para cada miembro activo.

> La Ley del Contrato Escrito (8) es la más prescindible si hay que recortar; la 6 y la 7 son las más útiles para justificar reglas. El Narrador no es una ley sino un recurso: es la voz omnisciente y sarcástica que, en el modo explicar, comenta por qué pasó lo que pasó.

---

## 9. Glosario y tono

### 9.1 Glosario

| Término | Significado |
|---|---|
| **Queso / quesos** | Moneda, comida y munición. Se cuenta por unidades con `tipo` y `edad`. Es la única moneda: no se compra ni se vende queso. |
| **Despensa** | El conjunto de quesos de la compañía. |
| **Ración** | Un queso por miembro y día (consume fresco, luego curado, luego rancio). Un `pan_duro` **(extra)** puede sustituirla. |
| **Fresco / curado / rancio** | Estados de maduración (edad 0-2 / 3-9 / 10+). |
| **Afinar** | Dejar madurar el queso con cuidado. |
| **Gran Cuajada** | El mito fundacional: cuando el mar de leche se hizo tierra. |
| **Gran Rancio** | Plaga de moho que estropea las despensas del reino. |
| **Pacto del Suero** | Tratado que prohíbe a los reyes ir a la guerra y obliga a subcontratarla. |
| **Registro de Compañías** | Pizarra en la taberna con el ranking de mercenarios. |
| **Huelga** | Estado de un personaje con moral de 2 o menos: no combate. |
| **Caído** | Estado de un personaje con 0 de vida **dentro de un combate**; al acabar el combate se levanta con 1 de vida. |
| **Cobrar en queso** | Modalidad de pago estándar. "Cobrar en promesas" es el insulto máximo. |
| **Corteza** | Material de calles, armaduras y excusas. |
| **Narrador** | La voz sarcástica del modo explicar. |
| **Loncha** | Medida informal de distancia: "a dos lonchas de aquí". Solo decorativa. |
| **Frente / retaguardia** | Las dos filas del combate. |

### 9.2 Tono

**Sí:**
- Humor absurdo con lógica interna: lo ridículo funciona siguiendo reglas.
- Ironía suave del narrador, sobre todo al explicar reglas ("Sir Baldomero ve el caballo y decide revisar sus calcetines").
- Juegos de palabras con queso, maduración y cocina, pero sin abusar.
- Personajes que se contradicen (caballero miedoso, bardo que cobra por callar).
- Consecuencias jugables detrás de cada chiste.

**No:**
- Burlas a grupos de personas reales (nacionalidades, religiones, cuerpos, condiciones).
- Violencia gráfica: los combates son cómicos, los enemigos "caen" o "huyen".
- Humor que dependa de contexto del mundo real, actualidad o marcas.
- Chistes largos que no aporten a una regla o a un texto de pantalla.
- Cuatro chistes seguidos del mismo tipo: variar tono y ritmo.

Acentos y personajes: Pimentina puede usar un tono refinado, pero sin caricaturizar acentos ni nacionalidades.

---

## 10. Índice de identificadores

Todos los identificadores están en `snake_case`, ASCII, sin tildes ni espacios. El **nombre visible** es el que se muestra al jugador. Los ids no deben repetirse entre categorías, salvo los casos deliberados anotados (contrato = NPC, como en el canon con `gallina_noble`).

**Convenciones de esta revisión (docs/06 §2.7, D-16).** La columna **Versión** da el alcance de entrega: *mínima*, *objetivo* o *(extra)*. Los combatientes enemigos se escriben `e(Tipo, N)` y el narrador usa `Tipo`; el nombre visible añade el número solo si hay varias instancias del mismo tipo. Los estados se consultan siempre con los derivados `aturdido/1`, `cantando/1`, `apestado/1`, `esta_en_huelga/1`; nunca con `estado/2`.

### 10.1 Zonas (`zona/2`)

| id | Versión | Nombre visible |
|---|---|---|
| `taberna` | mínima | Taberna del Cuajo Torcido |
| `aldea` | mínima | Aldea Requesón |
| `bosque` | mínima (en datos; solo de paso) | Bosque del Moho |
| `camino_real` | mínima | Camino Real |
| `castillo` | mínima | Castillo Camembert |
| `cuevas` | mínima (solo la sala del jefe) | Cuevas del Roquefort |

Conexiones (`conexion/2`, datos; `adyacente/2` las hace bidireccionales; `puede_viajar/1` es la meta que se explica): `taberna-aldea`, `taberna-camino_real`, `aldea-bosque`, `bosque-camino_real`, `camino_real-castillo`, `camino_real-cuevas`.

### 10.2 Personajes de la compañía

| id | Versión | Nombre visible | Rasgo (id) | Rasgo con regla |
|---|---|---|---|---|
| `baldomero` | mínima | Sir Baldomero | `teme_caballos` | mínima |
| `pimentina` | mínima | Madame Pimentina | `hechizos_de_cocina` | mínima |
| `rufino` | mínima | Rufino | `cobra_por_callar` | objetivo |
| `tuerca` | mínima | Tuerca | `manos_largas` | objetivo |

Predicados de membresía: `miembro/1` (pertenece a la compañía), `activo/1` (miembro y vivo), `en_pie/1` (activo y no en huelga). `recluta_1` **(extra)**.

### 10.3 NPC

| id | Versión | Nombre visible |
|---|---|---|
| `mantecosa` | mínima | Doña Mantecosa |
| `ricota` | (extra) | Ricota el Tendero |
| `alcaldesa_nata` | mínima | Alcaldesa Nata |
| `ermitano_penicilio` | (extra) | Hermano Penicilio |
| `gallina_noble` | mínima | Lady Clotilde Plumífera |
| `fantasma_charlatan` | objetivo | Eustaquio, el fantasma charlatán |
| `capitan_pecorino` | objetivo | Capitán Pecorino Duro |
| `rey_brieto` | mínima | Rey Brieto IV "el Mal Curado" |

### 10.4 Habilidades y acciones

Acciones del jugador (canon): `atacar`, `defender`, `habilidad`, `usar`, `huir`. Comando de habilidad: `habilidad(Objetivo)` (una habilidad por personaje en la mínima, D-23); `habilidad(Id, Objetivo)` con dos habilidades para Pimentina y Rufino es **(extra)**. En la mínima `usar` y `huir` pasan a "Debería" (no se puede huir del jefe).

| id | Versión | Quién | Nombre visible | Efecto resumen |
|---|---|---|---|---|
| `carga_heroica` | mínima | `baldomero` | Carga Heroica | Daño +4 a un enemigo de frente; defensa propia -1 un turno. |
| `fondue_flamigera` | mínima | `pimentina` | Fondue Flamígera | Gasta 1 queso. Daño fijo 8, ignora defensa (+2 con queso rancio: objetivo). |
| `raclette_curativa` | (extra) | `pimentina` | Raclette Curativa | Gasta 1 queso. Cura 8 a un aliado. |
| `balada_inspiradora` | mínima | `rufino` | Balada Inspiradora | Moral del grupo +1 (cada miembro `mod_moral(Id, 1)`); en el objetivo Rufino además queda `cantando`. |
| `silencio_pagado` | objetivo | `rufino` | Silencio Pagado | Gasta 1 queso. Quita `cantando`. |
| `rebuscar_bolsillos` | mínima | `tuerca` | Rebuscar Bolsillos | Si el enemigo `lleva_queso`, gana 1 queso. |

Las fórmulas viven como datos en `combate`: `efecto_habilidad(Hab, Efectos)`; `habilidad_de(Id, Hab)` en `mundo`.

Acciones propias de enemigos (para `accion_enemigo/2`): el **canon de tres reglas** es `curarse`, `atacar`, `defender` (mínima). Acciones especiales: `robar_queso`, `embestir`, `invocar_moho` (mínima); `cobrar_peaje`, `apuntar` (objetivo); `contaminar`, `curar_aliado`, `esporas_curativas` (extra).

### 10.5 Enemigos

| id | Versión | Nombre visible | Clase |
|---|---|---|---|
| `rata_quesera` | mínima | Rata Quesera | `roedor` |
| `bandido_torpe` | mínima | Bandido Torpe | `humano` |
| `moho_saltarin` | mínima | Moho Saltarín | `hongo` |
| `seta_chismosa` | (extra) | Seta Chismosa | `hongo` |
| `ganso_recaudador` | objetivo | Ganso Recaudador | `ave` |
| `arquero_aburrido` | objetivo | Arquero Aburrido | `humano` |
| `bandido_montado` | mínima | Bandido Montado | `caballo` |
| `jinete_parmesano` | (extra) | Jinete Parmesano | `caballo` |
| `guardia_de_corteza` | (extra) | Guardia de Corteza | `constructo` |
| `murcielago_azul` | (extra) | Murciélago Azul | `volador` |
| `golem_de_queso_duro` | (extra) | Gólem de Queso Duro | `constructo` |
| `gran_roquefort` | mínima | El Gran Roquefort | `queso_vivo` |

### 10.6 Clases de criatura (`clase/2`, `teme/2`)

`humano`, `caballo`, `roedor`, `hongo`, `ave`, `volador`, `constructo`, `queso_vivo`. En la mínima se usan `roedor`, `humano`, `hongo`, `caballo` y `queso_vivo`; `ave`, `volador` y `constructo` entran con los enemigos objetivo o extra.

### 10.7 Tipos de queso

| id | Versión | Nombre visible |
|---|---|---|
| `cheddar` | mínima | Cheddar |
| `brie` | mínima | Brie |
| `queso_silvestre` | objetivo | Queso Silvestre |
| `roquefort` | objetivo | Roquefort |
| `requeson` | (extra) | Requesón |
| `gouda` | (extra) | Gouda |
| `camembert` | (extra) | Camembert |
| `parmesano` | (extra) | Parmesano |

Estados de maduración (`categoria_queso/2`): `fresco`, `curado`, `rancio`. Despensa: `queso(Tipo, Edad, N)` y `queso_total/1`.

### 10.8 Objetos

| id | Versión | Nombre visible | Categoría |
|---|---|---|---|
| `pocion` | mínima | Poción de Suero Lácteo | consumible |
| `cataplasma_de_requeson` | (extra) | Cataplasma de Requesón | consumible |
| `pan_duro` | (extra) | Pan Duro | consumible |
| `suero_fermentado` | (extra) | Suero Fermentado | consumible |
| `tapones_de_cera` | (extra) | Tapones de Cera | consumible |
| `salmuera` | (extra) | Salmuera (extra) | consumible |
| `cuajo_de_emergencia` | (extra) | Cuajo de Emergencia (extra) | consumible |
| `cuchillo_de_untar` | (extra) | Cuchillo de Untar | equipable (`arma`) |
| `cucharon_de_hierro` | objetivo | Cucharón de Hierro | equipable (`arma`) |
| `estoque_de_parmesano` | objetivo | Estoque de Parmesano | equipable (`arma`) |
| `baston_de_queso_duro` | (extra) | Bastón de Queso Duro | equipable (`arma`) |
| `laud_desafinado` | (extra) | Laúd Desafinado | equipable (`arma`) |
| `ganzua_de_oro` | (extra) | Ganzúa de Oro | equipable (`arma`) |
| `coraza_de_corteza` | (extra) | Coraza de Corteza | equipable (`cuerpo`) |
| `delantal_encantado` | (extra) | Delantal Encantado | equipable (`cuerpo`) |
| `escudo_tapadera` | (extra) | Escudo Tapadera | equipable (`accesorio`) |
| `venda_de_caballos` | mínima | Venda de Caballos | equipable (`accesorio`) |
| `trebol_de_cuatro_quesos` | (extra) | Trébol de Cuatro Quesos | equipable (`accesorio`) |
| `sello_real` | objetivo | Sello Real | clave |
| `llave_mohosa` | (extra) | Llave Mohosa | clave |

Slots: `arma`, `cuerpo`, `accesorio`. Inventario: `lleva(Id, Objeto, N)` (la compañía usa el id `compania`); puesto: `equipado(Id, Objeto)`.

### 10.9 Estados, filas y alcance

| Tipo | Valores |
|---|---|
| Estados (derivados de `alterado(Id, Estado, Turnos)`) | mínima: `huelga` (canon; derivado de la moral, predicado `esta_en_huelga/1`), `caido` (solo dentro del combate), `defendiendo`. Objetivo: `cantando` (duración `fijo`). Regla del canon `aturdido` (se escribe `aturdido/1`; en la mínima ninguna fuente lo aplica). Extra: `apestado`, `alerta` |
| Filas | `frente`, `retaguardia` |
| Alcance | `cuerpo`, `distancia` |

### 10.10 Facciones (decorativas)

| id | Nombre visible |
|---|---|
| `corona_camembert` | Corona de Camembert |
| `mancomunidad_requeson` | Mancomunidad de Requesón |
| `principado_roquefort` | Principado de Roquefort |
| `gremio_afinadores` | Gremio de Afinadores |
| `bandidos_del_camino` | Cofradía de los Ganchos del Camino |
| `el_moho` | El Moho |
| `lanzas_parmesanas` | Lanzas Parmesanas |
| `compania_gouda_dorado` | Compañía del Gouda Dorado (extra) |
| `hermanos_emmental` | Hermanos Emmental (extra) |
| `banda_chapuza` | Banda Chapuza |

### 10.11 Contratos

| id | Versión | Recompensa |
|---|---|---|
| `ratas_del_granero` | mínima | 9 quesos + 1 `pocion` |
| `gato_en_el_arbol` | mínima | 7 quesos + `venda_de_caballos` |
| `gallina_noble` (canon) | mínima | 14 quesos + 1 `brie` |
| `despensa_real` | mínima | 40 quesos |
| `fantasma_charlatan` | objetivo | 8 quesos + `llave_mohosa` |
| `peaje_del_ganso` | objetivo | 9 quesos + `cucharon_de_hierro` |
| `silvestre_para_ricota` | (extra) | 10 quesos + `baston_de_queso_duro` |

Otros contratos (extra), definidos en el documento 04: `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna`. Forma del dato: `contrato(Id, Zona, Objetivo, recompensa(Lista), Condiciones)` (aridad 5 del canon). Condiciones de este documento: `rasgo_no(teme_caballos)`, `contratos_cumplidos_min(N)`. Contratos cerrados: `contrato_cerrado(C, Resultado)`, derivados `contrato_cumplido/1`, `contrato_exito/1` y `contratos_cumplidos/1` (recuento).

### 10.12 Finales (D-30)

| id | Versión | Resumen |
|---|---|---|
| `chapuza` | mínima | Victoria justa: el jefe cae y la Banda sobrevive tarde, mal y con deudas (puesto 31 en el Registro). |
| `derrota_combate` | mínima | Todos los miembros caídos en un combate. |
| `derrota_hambre` | mínima | Al empezar el día, `queso_total = 0` y no hay nada por cobrar. |
| `leyenda` | objetivo | Victoria brillante (puesto 12 en el Registro). |
| `quiebra` | objetivo | Victoria en quiebra: se gana a duras penas (queso, moral o miembros en pie por los suelos). |
| `madurado` | (extra) | Final alternativo con el jefe (ver 04). |
| `derrota_plazo` | (extra) | La despensa del rey se convierte en abono (solo con reloj narrativo, pospuesto). |

El hambre nunca baja la vida de nadie por debajo de 1. Los ids de derrota son los del documento 04; los de 05 (`sin_miembros`, `sin_queso`) quedan descartados.

### 10.13 Predicados y parámetros que usa este documento (nombres canónicos)

Predicados de **datos** en `mundo` (estáticos): `zona/2`, `conexion/2`, `personaje/7`, `enemigo/4`, `clase/2`, `alcance/2`, `fila_preferida/2`, `lleva_queso/1`, `habilidad_de/2`, `efecto_objeto/2`, `bonus/3`, `coste_queso/2`, `contrato/5`.

Predicados **derivados / reglas explicables**: `adyacente/2`, `puede_viajar/1`, `puede_habilidad/2`, `esta_en_huelga/1`, `permite_combate/1`, `puede_combatir/1` (personaje vivo y no en huelga), `puede_atacar/2`, `puede_descansar/0`, `puede_pagar_sueldos/0`, `aturdido/1`, `cantando/1`, `apestado/1`, `teme/2`, `ignora_miedo/1`, `rasgo_no/1`, `miembro/1`, `activo/1`, `en_pie/1`, `categoria_queso/2`, `queso_total/1`, `contratos_cumplidos/1`.

**Parámetros** (valores fijados por la revisión; los nombres de `parametro/2` salvo `moral_huelga` son propuesta de este documento): `moral_inicial = 6`, `moral_huelga = 2` (huelga si moral <= 2), `moral_maxima = 10`, `queso_inicial = 12` (cheddar de edad 0, en `inicio/1`), `racion_por_miembro = 1`, `coste_descanso = 2`, sueldos 1/2/1/1 (5 por pago), impago al salir de la taberna = -2 de moral por miembro.

Queso fuera del código: nadie define `comprar_queso` ni `vender_queso`; no existe `deuda_taberna/1`.

---

## 11. Cambios propuestos al canon y estado tras la revisión

Origen de los estados: docs/06 §3 (consolidado) y §4 (decisiones D-nn aceptadas por el autor el 2 de noviembre de 2026). La aplicación de los cambios aceptados a DISENO.md se hace en la revisión de ese documento.

1. **Provisión inicial de queso insuficiente.** Con cuatro miembros comiendo una unidad por día, `queso(cheddar, 0, 5)` alcanza para poco más de un día, y la primera ida a la aldea ya cuesta un día más. Propuesta: empezar con **12 cheddar**. Motivo: que el primer contrato sea jugable y no un castigo. **Estado: ACEPTADO** (D-09, X-26). Además se aceptan las recompensas escaladas de 04 (la `gallina_noble` paga 14 quesos y 1 brie, no 5; X-27; el recálculo de 04 §9.2 subió después ratas a 9, gato a 7 y gallina a 14, confirmado el 2 de noviembre de 2026).
2. **Sueldos más bajos.** Sueldos de 1+2+1+1 = 5 quesos por pago; con las recompensas escaladas la economía cierra. **Estado: ACEPTADO** (01-2, 04-13). El pago es el comando explícito `pagar`, por unidades (D-14, D-13).
3. **Escala de moral 0 a 10, inicio 6.** Entero 0-10 y huelga con moral <= 2 (equivale al antiguo "< 3"). **Estado: ACEPTADO** (D-08, X-24). La huelga se deriva **solo de la moral**, ya no depende de "deber un sueldo" (X-25).
4. **Umbral de rancio por tipo (extra).** Se podría dar a cada tipo un `umbral_rancio/2` propio. **Estado: RECHAZADO / pospuesto**: se mantiene el canon único (0-2 fresco, 3-9 curado, 10+ rancio).
5. **Pago por valor, no por unidades.** **Estado: POSPUESTO** a la tienda extra (D-13, X-32): en la v1 todo se paga por unidades y el valor solo informa.
6. **Atributo `clase` para enemigos y `alcance` para todos.** **Estado: ACEPTADO** (X-23). Datos nuevos en `mundo`: `clase/2`, `alcance/2`, `fila_preferida/2`, `lleva_queso/1`.
7. **Ley de la Taberna: sin combate en la base.** **Estado: ACEPTADO**, renombrado a `\+ permite_combate(taberna)` para no chocar con `puede_combatir(Id)` (X-14).
8. **Estados nuevos.** `cantando`: **ACEPTADO** como objetivo (Debería); `apestado`: **POSPUESTO** (depende de `lanzar`). Ambos se escriben como derivados de `alterado/3` (X-15).
9. **Detalle del rasgo `cobra_por_callar`.** Concretado como el estado `cantando` hasta pagar `silencio_pagado`. **Estado: ACEPTADO** como objetivo; en la mínima `balada_inspiradora` solo da +1 de moral.
10. **Fila preferida de Tuerca y alcance.** `frente`, cuerpo a cuerpo. **Estado: ACEPTADO.**
11. **El ejemplo del canon usa un "bandido" genérico con defensa 5**, mientras que `bandido_torpe` tiene defensa 2. **Estado: ACEPTADO** (X-57): la demo del modo explicar usa `bandido_torpe` con daño 9 (11 − 2); `jinete_parmesano` (defensa 5) es **(extra)**, así que no sirve de enemigo de demostración en la mínima.
12. **Reclutar un quinto miembro (extra).** **Estado: POSPUESTO**; id `recluta_1` si se hace.

**Nuevas decisiones de la revisión que afectan a este documento** (no estaban en la lista original): el queso es la única moneda y no se compra ni se vende (D-10, X-33); no hay tienda en la v1 (04-8); descansar cuesta 2 quesos y no existe `deuda_taberna` (D-15, X-31); la ración diaria consume fresco → curado → rancio (D-11, X-28); `comer(Tipo)` es la ración voluntaria con efecto del tipo (D-12, X-29); caídos solo en combate y derrota por hambre (D-17, X-44); `rasgo_no(teme_caballos)` se evalúa con la venda (D-19, X-37); una habilidad por personaje en la mínima (D-23, X-43, X-47); IA enemiga de tres reglas más tres acciones especiales (D-24, X-42); no se huye del jefe (D-29, X-45); tres finales en la mínima (D-30); Clotilde con contador de golpes (D-33, X-38); tabla de nombres canónicos (D-16, X-12 a X-20); recorte de alcance mínima/objetivo/extra (D-21, X-49, X-50).

---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 tras docs/06. Solo se ha editado este documento.

| Qué cambió | Motivo |
|---|---|
| Nota de revisión al inicio, estado v0.2 y guía de lectura con las etiquetas mínima / objetivo / (extra) y los nombres canónicos. | D-21, D-16, 06 §5.1 |
| Nueva "Regla de la moneda" en 1.1: el queso es la única moneda, no se compra ni se vende, entradas y salidas del queso; en la v1 no hay tienda. | D-10, X-33 |
| 1.1 y 7.1: pago por unidades; el valor del queso solo informa (y fija precios de la tienda extra). | D-13, X-32 |
| 2.2: el Gremio ya no "vende" salmuera. | D-10, X-33 |
| 2.4: puesto del Registro `max(41, 47 - contratos_cumplidos)`; el puesto del texto del final lo sustituye. | X-53 |
| 3.1 Taberna: descansar cuesta 2 quesos (toda la vida, +1 moral), sin `deuda_taberna`; `pagar` explícito con impago al salir (-2 de moral por miembro); sin tienda; `permite_combate/1`. | D-15, X-31, D-14, X-30, D-10, X-14 |
| 3.2 a 3.6: etiqueta de versión por zona; Aldea sin tienda ni venta de queso; Bosque solo de paso; Castillo sin compra de coraza; Cuevas sin combates previos ni puerta interior; no se huye del jefe. | D-21, 06 §5.1, D-10, X-49, D-29, X-45 |
| 4.1: moral 0-10 (inicio 6, huelga con moral <= 2), 12 cheddar iniciales, sueldos por unidades; columna de versión del rasgo. | D-08, X-24, D-09, X-26, D-13 |
| 4.2 a 4.5 y 10.4: una habilidad por personaje en la mínima; `raclette_curativa` (extra), `silencio_pagado` (objetivo). | D-23, X-43, X-47 |
| 4.7: reglas con `teme/2` consciente de la venda, `ignora_miedo/1` con `equipado/2`, `cantando/1` derivado de `alterado/3`, `lleva_queso/1`. | D-19, X-37, X-15, X-16, D-16 |
| 5: tabla de NPC con versión; Mantecosa sin deuda; Ricota no compra ni vende queso (tienda extra); ermitaño no vende; Clotilde paga 14 + 1 brie (antes 12) y se mide con contador de golpes; Pecorino entrega el estoque como recompensa. | D-10, D-15, D-09, X-27, D-33, X-38 |
| 5.1: tabla de contratos con versión y recompensas escaladas (7, 5, 12, 40, 8, 9, 10; ajustadas después a 9, 7, 14 en ratas, gato y gallina); `rasgo_no` contra miembros que no ignoran el miedo; `despensa_real` con `contratos_cumplidos_min(3)` y llave solo en variante dura; 1 `pocion` de recompensa en `ratas_del_granero`. | D-09, D-19, X-37, X-41, X-46, D-21 |
| 6: bestiario con columna de versión (5 mínima, 2 objetivo, resto extra), botín de 1 queso para `lleva_queso`; IA mínima = canon de 3 reglas + `robar_queso`, `embestir`, `invocar_moho`; perfiles restantes marcados; regla 3 del jefe corregida; instancias `e(Tipo, N)`. | D-24, X-42, X-49, X-19, 06 §5.1 |
| 6.3: progresión marcada por versión. | 06 §5.1 |
| 7.1: ración diaria fresco → curado → rancio; el efecto del tipo solo con `comer(Tipo)`; categoría con `categoria_queso/2`; criterio del rancio "como máximo el valor del fresco". | D-11, X-28, D-12, X-29, X-20, X-34 |
| 7.2: tabla de quesos con versión (2 mínima, 2 objetivo, 4 extra) y "Cómo entra" sin compras; gouda como recompensa o hallazgo; `lanzar` y `apestado` marcados (extra). | D-10, X-33, 06 §5.1 |
| 7.3: objetos con versión (2 mínima, 3 objetivo, resto extra), "Cómo se obtiene" por recompensa o botín, precio solo para la tienda extra, `efecto_objeto/2`, `lleva/3` y `equipado/2`. | D-10, X-33, X-46, X-16, X-23, 04-8 |
| 8: leyes con nombres canónicos (`esta_en_huelga/1`, `permite_combate/1`, `puede_viajar/1`, `categoria_queso/2`); huelga derivada solo de la moral; leyes 3 y 8 marcadas (extra). | D-16, X-13, X-14, X-12, X-25 |
| 9.1: glosario (moneda única, ración, huelga por moral, caído). | D-10, D-11, X-25, D-17 |
| 10: versión en todas las tablas del índice; convenciones; nuevos 10.12 (finales), 10.13 (predicados y parámetros canónicos); contratos con recompensa. | D-16, D-21, D-30 |
| 11: estado de cada propuesta (aceptada / rechazada / pospuesta) y lista de decisiones nuevas. | 06 §3, §4 |
