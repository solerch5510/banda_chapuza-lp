# Banda Chapuza — Guion, campaña y contratos

> Documento de diseño 04 · Fase de diseño · Complementa a [DISENO.md](DISENO.md) (canon), [01-lore-y-ambientacion.md](01-lore-y-ambientacion.md) (lore e índice de identificadores) y [03-funcionalidades-y-etapas.md](03-funcionalidades-y-etapas.md) (calendario y prioridades).
>
> Estado: **borrador v0.2, revisado** (borrador v0.1 del 31 de octubre de 2026). Todo lo marcado con **(extra)** es prescindible: se implementa solo si sobra tiempo. Todos los números son **provisionales** y se ajustan en la fase de balance (semana 6).
>
> **Revisado el 2 de noviembre de 2026 tras docs/06: alineado con las decisiones aceptadas.** Cambios principales: recorte "Nivel A" (mínima / objetivo / extra, sección "Niveles de alcance"), economía recalculada con un script (sección 9), comandos nuevos reducidos a `elegir/1`, `pagar` y `demo`, nombres canónicos de 06 §2.7 y vocabulario de efectos de 02 §4.5. El contenido recortado **no se ha borrado**: queda marcado como "contenido ampliable". El detalle está en el "Registro de cambios de la revisión", al final.
>
> Los bloques de Prolog de este documento son **bocetos sin ejecutar**: sirven para fijar la forma de los datos, no para copiar y pegar.

## Cómo leer este documento

- Los identificadores (`snake_case`, ASCII) son los del índice de la sección 10 del lore. Los ids nuevos que propongo están en la sección 11.3.
- Cada elemento lleva una marca de alcance: **(mínima)** = se compromete (prioridad "Debe"); **(objetivo)** = se hace solo si el colchón de la semana 5 está intacto el 27 de noviembre; **(extra)** = contenido ampliable, documentado pero **fuera de la entrega**. Un elemento sin marca pertenece al nivel de la sección o ficha que lo contiene.
- Todo lo que cambia el estado del juego se expresa como **condiciones** (hechos que deben cumplirse) y **efectos** (cambios de estado), para que el meta-intérprete pueda explicarlos con los comandos `explicar` y `por_que_no` (que son términos ejecutados por `juego:ejecutar/2`, no predicados invocables; D-03).
- Las cantidades de queso de recompensas, multas, botín y comida son **unidades**, no valor (D-13).

### Supuestos que adopto del lore (sección 11 del documento 01)

| Propuesta del lore | ¿La asumo? | Dónde pesa |
|---|---|---|
| 1. Provisión inicial de 12 `cheddar` frescos | Sí | Economía (sección 9) |
| 2. Sueldos 1+2+1+1 = 5 quesos por pago | Sí | Economía |
| 3. Moral entera de 0 a 10, inicio 6; `huelga` si la moral baja de 3 | Sí (D-08, X-25): la huelga es un derivado **solo de la moral** (`esta_en_huelga/1`: moral ≤ 2, `parametro(moral_huelga, 2)`), sin depender de sueldos debidos | Condiciones de contratos, arcos, finales |
| 4. Umbral de rancio por tipo | No (se mantiene 0–2 / 3–9 / 10+) | — |
| 5. Pago por valor | **No** (D-13): sueldos, recompensas y multas se pagan en *unidades*; el valor por tipo solo informa y se usará en la tienda extra (ver 9.1) | Economía |
| 6. `clase` y `alcance` | Sí | Enemigos de cada contrato |
| 7. Ley de la Taberna (sin combate en la base) | Sí, con el nombre `permite_combate/1` (X-14): `\+ permite_combate(taberna)` | `pelea_de_taberna` (extra) y demostración de `por_que_no` |
| 8–9. Estados `apestado`, `cantando` y detalle de `cobra_por_callar` | `cantando` (objetivo); `apestado` (extra). Ambos son derivados de `alterado/3` (X-15) | Escoltas, fantasma, jefe |
| 10. Tuerca en fila `frente` | Sí | Combates |

Supuestos de reglas que añado yo (ver 9.1): `descansar` cuesta 1 día y 2 quesos (D-15, sin `deuda_taberna`); cada hambre diaria cuesta −1 moral y −2 vida, **sin bajar nunca la vida de 1**; la ración diaria consume **fresco → curado → rancio** (D-11, no "lo más viejo primero"); el queso **no se compra ni se vende** (D-10).

### Niveles de alcance (06 §5.1, Nivel A)

"Mínima" = lo que se compromete. "Objetivo" = solo con el colchón de la semana 5 intacto el viernes 27 de noviembre. "Extra" = contenido ampliable (no se borra; no forma parte de la entrega). Resumen de lo que afecta a este documento:

| Elemento | Mínima | Objetivo | Extra |
|---|---|---|---|
| Contratos | **4**: `ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real` | **6**: + `peaje_del_ganso`, `fantasma_charlatan` | **9**: `silvestre_para_ricota`, `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna` |
| Tipos de objetivo de contrato | `eliminar`, `derrotar`, `evento`, `escoltar` (D-18) | + `escuchar` (como evento de 3 pasos) | `reunir`, `recuperar` |
| Enemigos | **5**: `rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort` | **7**: + `ganso_recaudador`, `arquero_aburrido` | 12: + `seta_chismosa`, `jinete_parmesano`, `guardia_de_corteza`, `murcielago_azul`, `golem_de_queso_duro` |
| Acciones especiales de IA | 3: `robar_queso`, `embestir`, `invocar_moho` | 5: + `cobrar_peaje`, `apuntar` | 11 |
| Objetos | 2: `venda_de_caballos`, `pocion` | 5: + `cucharon_de_hierro`, `sello_real`, `estoque_de_parmesano` | 20 |
| Estados | `huelga` (derivado), `caido` (solo en combate), `defendiendo` | + `cantando` | `apestado`, `alerta` |
| Jefe | IA de 4 reglas (esporas, invocar moho, objetivo "de frente" si hay rancio, atacar al más débil); sin fases, sin entrada de cuevas ni puerta interior; **no se puede huir** (D-29) | + fase "apurado", bonus +2 por rancio y vida −10 con `exito(fantasma_charlatan)` | Monólogo, aura, arcos B3/R3/T3, `llave_mohosa` y puerta interior, final `madurado` |
| Finales | **3**: `chapuza`, `derrota_combate`, `derrota_hambre` (D-30) | **5**: + `leyenda`, `quiebra` | 7: + `madurado`, `derrota_plazo` |
| Arcos personales | 0 | 2: B1 (La Venda), R1 (La balada del caballero) | 10 |
| Eventos de campaña (de las secciones 7.1 y 7.2) | 1: `t_bienvenida` | 3: + `v_primer_viaje`, `t_registro_sube` (propuesta) | 15 |
| Pasos de tutorial | 6: T1, T3, T4, T5, T7, T9 | 9: + T2, T8, T10 (propuesta) | 12 |
| Comandos nuevos de este documento | `elegir/1`, `pagar` (D-20) | + `demo` | `escuchar`, `catar`, `recoger` y `banquete` **no son comandos**: son opciones de `elegir/1` en las fichas (extra) |
| Rasgos con regla | `teme_caballos`, `hechizos_de_cocina` | + `cobra_por_callar`, `manos_largas` | — |

> Las fichas, tablas y bocetos de este documento marcan cada elemento con **(mínima)**, **(objetivo)** o **(extra)**.

---

## 1. Arco de la campaña

### 1.1 Resumen en una frase

La Banda Chapuza, la peor compañía del Registro, hereda contratos de pueblo, demuestra que "casi nunca rompe nada importante", acaba escoltando a una gallina hasta el Castillo, y el rey, con la despensa pudriéndose, la manda a las Cuevas del Roquefort a enfrentarse al `gran_roquefort`, un príncipe convertido en queso que solo quiere "madurar" el reino.

### 1.2 Estructura en actos

Los actos **no dependen del día**, sino del estado de la partida (contratos cumplidos y contrato del jefe). El narrador muestra un rótulo al cambiar de acto.

| Acto | Título | Se activa cuando | Zonas | Contratos típicos | Objetivo del jugador |
|---|---|---|---|---|---|
| I | Mala fama | Inicio hasta cumplir 3 contratos | `taberna`, `aldea` | `ratas_del_granero`, `gato_en_el_arbol` (mínima); `fantasma_charlatan` (objetivo) | Aprender comandos, cobrar los primeros quesos, conseguir la `venda_de_caballos` (y la `llave_mohosa`, extra). |
| II | Camino y corona | 3 o más contratos cumplidos y `despensa_real` sin aceptar | `camino_real`, `castillo`, `bosque` (extra) | `gallina_noble` (mínima); `peaje_del_ganso` (objetivo); `degustador_real`, `caballo_fugado`, `silvestre_para_ricota` (extra) | Ver el rasgo de Baldomero en acción, llegar al rey, equiparse. Es el tramo de economía más tensa. |
| III | El rancio | `despensa_real` aceptado (o 7 contratos cumplidos) | `castillo`, `camino_real`, `cuevas` | `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido` (extra) | Prepararse: equipo, queso, moral, cena. El Gran Rancio avanza (reloj narrativo, extra). En la mínima el acto III se reduce al trayecto con `despensa_real` aceptado. |
| IV | Las Cuevas | La Banda entra en `cuevas` con `despensa_real` activo | `cuevas` | `despensa_real` | Ruta de cuevas, puerta interior y combate contra `gran_roquefort`. |
| Epílogo | Final | Fin del combate final | — | — | Mínima: `chapuza` o una derrota (`derrota_combate`, `derrota_hambre`). Objetivo: + `leyenda` y `quiebra`. Extra: `madurado` y `derrota_plazo`. |

```prolog
% boceto sin ejecutar: el acto es una consecuencia del estado, no un contador
acto(4) :- contrato_activo(despensa_real), en_zona(cuevas).
acto(3) :- contrato_activo(despensa_real), \+ en_zona(cuevas).
acto(3) :- contratos_cumplidos(N), N >= 7, \+ contrato_activo(despensa_real).
acto(2) :- contratos_cumplidos(N), N >= 3, N < 7, \+ contrato_activo(despensa_real).
acto(1) :- contratos_cumplidos(N), N < 3, \+ contrato_activo(despensa_real).
% las cinco cláusulas son mutuamente excluyentes: no hace falta corte ni once/1 (X-56)
```

### 1.3 Duración jugable estimada

Estimación a mano (1,7 a 2 minutos reales por día de juego, contando lectura, 2–3 combates cada 4 días y consultas a `explicar`); se valida en el playtest PT-1. Los días son de juego (cada `ir/1` o `descansar/0` consume uno).

| Ruta | Contratos | Días hasta el jefe | Minutos reales | Quién la juega |
|---|---|---|---|---|
| **Mínima** (mínima) | 3 + jefe (4 contratos) | 9 | 15–20 | Demo, exposición, prueba de humo. Jefe con equipo básico (`venda_de_caballos`, `pocion`): arriesgada y con poco margen de queso (ver 9.2). |
| **Objetivo** (objetivo) | 5 + jefe (6 contratos) | 9 | 20–25 | Partida corta con más variedad y más margen de queso. |
| **Recomendada** (extra) | 11 + jefe (12 contratos: todo menos reconocimiento, cena y pelea de taberna) | 21 | 35–45 | Partida "normal" ampliada. El jefe llega con buen equipo. |
| **Ampliada** (extra) | 12 + jefe (13 de los 15 contratos; la cena y la pelea de taberna no se tabulan) | 26 | 45–60 | Quien quiere ver todo; mejores finales. |

Nota sobre las métricas del documento 03 (sección 8.3: "12–25 días hasta el jefe, 15–30 minutos"): se acepta el cambio 11.1-11 ("9–26 días; 15–60 minutos" según la ruta; 06 X-51). Se miden en el playtest PT-1. Los recuentos de contratos corrigen los de la versión anterior (06 X-35).

### 1.4 Cómo se enlaza con el jefe final

1. **Causa visible desde el día 1:** la despensa del rey se pudre ("Gran Rancio"). El rey solo contrata a la Banda cuando ya no le queda a quién llamar.
2. **Pistas escalonadas** (cada una es una marca, efecto `marcar/1`): Eustaquio ("mi príncipe se retiró a madurar un poco"; objetivo, contrato `fantasma_charlatan`). **(extra)**: `degustador_real` (el rancio "es un queso, no un moho"), Pimentina en el castillo (arco P1), el ermitaño Penicilio ("viene de abajo"). En la mínima el rey cuenta lo esencial en su oferta y no hay pistas.
3. **Fantasma y llave:** **(objetivo)** si se escuchó entero a Eustaquio (`exito(fantasma_charlatan)`), el `gran_roquefort` empieza con 10 de vida menos ("recuerda a su mayordomo"). **(extra)** la regla original del lore exige además la `llave_mohosa`, que abre la puerta interior de las Cuevas (sin llave, combate extra contra el `golem_de_queso_duro`).
4. **Puerta de entrada (mínima):** `despensa_real` solo es aceptable con 3 contratos cumplidos, audiencia en el castillo, moral media ≥ 4 y al menos 3 miembros en pie. Es la condición que más se usa en la demostración de `por_que_no`.
5. **Reloj narrativo (extra):** el Gran Rancio avanza en los días 8, 14, 20 y 26 (aviso del pregonero de la taberna, +1 de edad al lote más curado de la despensa). Se añade un `dia_limite(35)`: si se pasa sin aceptar `despensa_real`, derrota "La despensa se convierte en abono".

---

## 2. Apertura y tutorial integrado

### 2.1 Pantalla de inicio

```
==============================================================
            B A N D A   C H A P U Z A
      Compañía de Servicios Diversos Menores
              (puesto 47 de 47, con errata)
==============================================================
   Un juego de contratos absurdos, queso y mala suerte.
   Escribe  ayuda.  para ver los comandos.  (Con su punto final:
   aquí somos formales.)
==============================================================
```

**Texto de introducción (narrador, una sola pantalla):**

> Año 412 del Cuajo. En los Reinos Quesudos las guerras se pagan en queso y los mercenarios se ordenan en una pizarra. Arriba están los serios, con tiza brillante. Abajo del todo, con tiza de otro color y una errata, estáis vosotros.
>
> Tenéis doce quesos, cuatro bocas que alimentar y un jefe (tú, aunque Sir Baldomero opina que el jefe es él). Hoy empieza lo que vuestro contable llamaría "una racha".
>
> Entrad en la taberna. La puerta tiene una sola bisagra: es parte del carácter.

### 2.2 Primera escena: la Taberna del Cuajo Torcido

Se ejecuta al empezar, en el día 1, sin que el jugador escriba nada. Es el evento de campaña `t_bienvenida`, el **único** de la versión mínima (mínima). Cada línea del guion es un hecho `dialogo/3` o una frase de narrador.

| Orden | Habla | Texto | Función |
|---|---|---|---|
| 1 | Narrador | "El Cuajo Torcido huele a sopa de ayer, a sudor de mercenario y a una promesa de pago que nadie ha visto cumplida." | Ambiente (texto de zona del lore). |
| 2 | `mantecosa` | "La Banda Chapuza. Doce quesos, cuatro bocas y ninguna referencia. Sentaos, y no toquéis lo que no esté clavado." | Presenta el estado inicial. |
| 3 | `baldomero` | "Por mi honor, hoy es el día en que nuestra fama cambiará." | Presenta a Baldomero. |
| 4 | `rufino` | "Y si no cambia, va a la balada. Con rima." | Presenta a Rufino y el "va a la balada". |
| 5 | `pimentina` | "El queso es lo único aquí con fondo, querido." | Presenta a Pimentina. |
| 6 | `tuerca` | "Doce quesos. Los he contado. Dos veces." | Presenta a Tuerca y su rasgo. |
| 7 | `mantecosa` | "El tablón está ahí. Lo que está clavado es mío; lo que está clavado y firmado, también." | Introduce `contratos.` |
| 8 | Narrador | "[Consejo] Escribe `mirar.` para ver dónde estás. Los comandos son términos de Prolog y acaban en punto." | Primer consejo (T1). |

### 2.3 Tutorial integrado

Principios para no romper el tono:

1. **El consejo lo da un personaje o el narrador, y siempre lleva un chiste.** Nunca un cuadro de ayuda seco.
2. **Cada consejo sale una sola vez** (hecho `consejo_dado/1`, derivado de la marca que deja el efecto `marcar(consejo_dado(Id))`) y como máximo ocupa dos líneas. Se puede desactivar con `ajuste(consejos, no)` (la opción de menú se decide al implementar).
3. **El tutorial es el juego:** cada paso lo desencadena una acción real del jugador, nunca un menú aparte.
4. **El primer rechazo del sistema es una lección de `por_que_no`:** se diseña a propósito (el contrato `gallina_noble` está visible el día 1 pero bloqueado).

| Paso | Nivel | Qué hace el jugador (o qué ocurre) | Disparador | Texto / consejo | Comando enseñado |
|---|---|---|---|---|---|
| T1 | mínima | Primera pantalla de la taberna | inicio | "[Consejo] `mirar.` te dice dónde estás y a dónde puedes ir." | `mirar`, la sintaxis con punto |
| T2 | objetivo | Escribe `compania.` | primera vez | Baldomero: "Mirad mis cifras: ataque 11. Sí, vuestra merced puede aplaudir." | `compania` |
| T3 | mínima | Escribe `contratos.` | primera vez | Mantecosa (mínima): "Dos contratos de pueblo y uno que no es para vosotros... todavía." Se listan `ratas_del_granero`, `gato_en_el_arbol` y `gallina_noble [bloqueado]`. Versión del objetivo: "Tres contratos de pueblo, un peaje en el camino y uno que no es para vosotros... todavía." (se añaden `fantasma_charlatan` y `peaje_del_ganso`, X-35d). `despensa_real` no está en el tablón el día 1. | `contratos` |
| T4 | mínima | Intenta `aceptar(gallina_noble).` | rechazo del sistema | Narrador: "El contrato os mira, mira a Sir Baldomero y decide que no. Si quieres saber por qué, escribe `por_que_no(aceptar(gallina_noble)).`" | `aceptar`, anuncia `por_que_no` |
| T5 | mínima | Escribe `por_que_no(aceptar(gallina_noble)).` | primera vez | Se muestra la falla de `rasgo_no(teme_caballos)` tal como la produce la regla (D-19): existe un miembro activo con `rasgo(baldomero, teme_caballos)` y `\+ ignora_miedo(baldomero)` (no lleva la `venda_de_caballos`). La regla no mira los enemigos del contrato: el `bandido_montado` solo lo menciona el narrador. Narrador: "Sir Baldomero ve el caballo —de lejos, en un cartel— y decide revisar sus calcetines." | `por_que_no` |
| T6 | extra | Escribe `aceptar(ratas_del_granero).` | primera vez | Alcaldesa Nata (en forma de nota clavada): "Ratas. En el granero. Sed amables, tienen abogado." | `aceptar` |
| T7 | mínima | Escribe `ir(aldea).` | primera vez | Narrador: "Viajar cuesta un día: el camino se te pega a las botas. Hoy habéis comido cuatro quesos más." | `ir`, el paso del día, la comida |
| T8 | objetivo | Primer combate (`rata_quesera`) | inicio de combate | Baldomero: "¡A ellas!". Narrador: "[Consejo] Tu turno: `atacar(rata_quesera).`, `defender.` o `habilidad(...)`." | `atacar`, `defender`, `habilidad` |
| T9 | mínima | Fin del primer combate | victoria | Narrador: "Os preguntaréis por qué ha funcionado. Escribe `explicar(atacar(baldomero, rata_quesera)).` y lo sabréis. Opcional, como la higiene." | `explicar` |
| T10 | objetivo | Primera vuelta a la taberna con quesos cobrados | llegada | Mantecosa: "Los sueldos, jefe. Nadie combate sin cobrar: es ley." Narrador: "[Consejo] `pagar.` reparte los sueldos. Si salís sin pagar, la moral lo nota." Los contratos terminados se cobran solos al entrar; los sueldos, no (D-14). | `pagar` (el cobro es automático) |
| T11 | extra | Vida baja de algún miembro | vida < 50 % | Pimentina: "Esa herida necesita reposo y un poco de mantequilla." [Consejo] `descansar.` (solo en la taberna; cuesta 2 quesos). | `descansar` (`usar` es de objetivo) |
| T12 | extra | Primer enemigo de clase `caballo` | inicio de combate (solo si Baldomero **no** lleva la venda; con venda, el narrador dice que ataca con −3) | Narrador: "Si Sir Baldomero no ataca, no es por cobardía: es una regla. `por_que_no(atacar(baldomero, bandido_montado)).`" | `por_que_no` en combate |

```prolog
% boceto sin ejecutar
consejo(t4, aceptar_rechazado, 'Si quieres saber por que, escribe por_que_no(aceptar(gallina_noble)).').
% regla pura; `juego` emite el texto y el efecto marcar(consejo_dado(Id)) (D-04: solo estado.pl escribe)
consejo_pendiente(Id, T) :- consejo(Id, _, T), \+ consejo_dado(Id).
consejo_dado(Id) :- marca(consejo_dado(Id)).
```

---

## 3. Catálogo de contratos (15: 4 mínima, 2 más en el objetivo, 9 extra)

### 3.1 Convenciones

**Forma de datos (canon, DISENO §7):** `contrato(Id, Zona, Objetivo, recompensa(...), Condiciones)`, con la aridad 5 del canon (D-18, X-36). Extiendo dos cosas sin cambiar esa aridad (ver 11.2):

- `recompensa(Lista)` con elementos `quesos(N)` (N cheddar frescos), `queso(Tipo, Edad, N)`, `objeto(Id)` y `descansos_gratis(N)` (extra). La forma canónica `recompensa(quesos(N))` sigue siendo válida como abreviatura de `recompensa([quesos(N)])`.
- `Zona` es la **zona del objetivo**. Dónde se ofrece y cuándo aparece se guarda aparte (`oferente/3`, `aparece/2`).

**Vocabulario cerrado de `Objetivo`** y su traducción a la vía de 02 (`contratos:via_objetivo/2`, que devuelve `combate(Grupo)` o `evento(Id)`):

| Objetivo | Vía (`via_objetivo/2`) | Nivel |
|---|---|---|
| `eliminar(Pares)` | `combate(Grupo)`, con `Pares` expandido (`rata_quesera-2` son dos instancias) | mínima |
| `derrotar(Tipo)` | `combate([Tipo])` | mínima |
| `escoltar(Npc, Destino)` | `combate(Grupo)` con `enemigos_de/2` y el contador de golpes a Clotilde (D-33) | mínima |
| `evento(Id)` | `evento(Id)` | mínima |
| `escuchar(Npc, N)` | `evento(escuchar(Npc))` de N pasos (`elegir(escuchar)`) | objetivo |
| `reunir(Tipo, N, Estado)`, `recuperar(Objeto)` | `evento(...)` (el de `recuperar` dispara el combate de `enemigos_de/2`) | extra |

**Dónde se acepta:** `aceptar/1` funciona en la `taberna` (tablón) o en la zona donde está el oferente. **Dónde se cobra:** siempre en la `taberna` (canon) y **de forma automática** al entrar (etapa 6 de 02 §5.5); los sueldos, en cambio, no son automáticos: se pagan con el comando `pagar` (D-14). Los objetos clave (`sello_real`, `llave_mohosa`) los entrega el propio NPC al momento. **Límite:** como máximo 3 contratos activos a la vez (`parametro(max_contratos, 3)`).

**Resultados:** `exito`, `a_medias` y `fracaso`. Las consecuencias de cada uno son un hecho `consecuencia/3` (sección 10). Un contrato con la marca **reintentable** vuelve al tablón tras N días si se fracasa, para que el hilo principal nunca se bloquee. En la versión mínima los resultados "a medias" se limitan a condiciones medibles con contadores (X-39): `quesos_robados` (ratas) y `golpes_a_clotilde` (gallina); el del gato depende solo de la opción elegida.

**Combate perdido y fracaso (D-17, D-29).** `caido` solo existe dentro de un combate y los caídos se levantan con 1 de vida al terminar. Perder un combate (todos caídos) **no es un fracaso de contrato**: es la derrota `derrota_combate` y termina la partida. El fracaso de un contrato de combate solo se produce al `huir` (comando de objetivo); del jefe no se puede huir. Por eso en la mínima solo pueden fracasar `gato_en_el_arbol` (tres intentos) y `gallina_noble` (golpes a Clotilde).

**Vocabulario de condiciones** (todas se evalúan con `condicion_cumple/1`, que se puede explicar):

| Condición | Se lee así | Nivel |
|---|---|---|
| `rasgo_no(R)` | Ningún miembro activo tiene el rasgo `R` **sin ignorar su efecto**: `\+ ( activo(M), rasgo(M, R), \+ ignora_miedo(M) )`. Para `teme_caballos`, quien lleva la `venda_de_caballos` queda excluido (`ignora_miedo(P) :- equipado(P, venda_de_caballos)`). La regla no mira los enemigos del contrato (D-19). | mínima |
| `contratos_cumplidos_min(N)` | Hay al menos N contratos con resultado `exito` o `a_medias`, estén o no cobrados (`contrato_cumplido/1`). | mínima |
| `moral_media_min(N)` | La media de moral de los miembros activos es ≥ N. | mínima |
| `miembros_en_pie_min(N)` | Al menos N miembros están `en_pie/1` (activos y no en huelga). | mínima |
| `visita(Z)` | Se ha estado en la zona `Z` alguna vez (`visitada/1`). | mínima |
| `exito(C)` | El contrato `C` está cumplido solo con éxito (`contrato_exito/1`). | objetivo |
| `hecho(C)` | El contrato `C` está cumplido con cualquier resultado (`contrato_cumplido/1`). | extra |
| `objeto(O)` | La compañía lleva el objeto `O` (`lleva(compania, O, N)`, N > 0). | extra |
| `queso_min(N)` | La despensa tiene al menos N unidades (`queso_total/1`). | extra |
| `activo(P)` | `P` es miembro y está vivo (antes `miembro_activo(P)`). | extra |

**Formato de cada ficha:** zona, tipo, dificultad (1 a 5), quién lo ofrece, cuándo aparece, condiciones legibles, dato `contrato/5`, objetivo y enemigos/eventos, consecuencias, diálogo clave y chiste central. El nivel de alcance va en el título de la ficha.

---

### 3.2 `ratas_del_granero` — Ratas del Granero (tutorial) **(mínima)**

- **Zona / tipo / dificultad:** `aldea` · mínima · 1
- **Ofrece:** `alcaldesa_nata`. **Aparece:** desde el día 1.
- **Condiciones (legible):** ninguna. Es el contrato que el jugador siempre puede aceptar.
- **Objetivo:** echar a dos `rata_quesera` del granero de la aldea.
- **Dato:**
  ```prolog
  contrato(ratas_del_granero, aldea, eliminar([rata_quesera-2]),
           recompensa([quesos(9), objeto(pocion)]), []).
  ```
- **Enemigos / eventos:** 2 `rata_quesera` (8/4/0). IA: `robar_queso` si hay queso en la despensa; si no, `atacar` (primera acción especial de la mínima). Cada robo suma al contador `quesos_robados`. Un combate de una o dos rondas, pensado para enseñar `atacar`, `defender` y `habilidad`.
- **Recompensa (ajuste de la revisión):** 9 quesos (antes 7) y 1 `pocion` (06 X-46: sin tienda, el consumible llega como recompensa). El recálculo de la economía (9.2) mostró que con 7 + 5 + 12 la ruta mínima pasaba hambre el día 7 y llegaba al jefe sin queso; el ajuste es provisional hasta el balance de la semana 6.
- **Consecuencias:**
  - *Éxito* (ambas derrotadas y `quesos_robados` ≤ 3): cobra 9 y la `pocion`, moral del grupo +1.
  - *A medias* (derrotadas, pero `quesos_robados` ≥ 4): la alcaldesa descuenta "el queso que se han comido las ratas, que era mío": cobra 5 y la `pocion`.
  - *Fracaso* (solo con `huir`, comando de objetivo; un grupo caído es `derrota_combate`, D-17): se pierden 2 quesos, vuelve al tablón en 1 día (**reintentable**).
- **Diálogo clave:**
  - `alcaldesa_nata`: "Las ratas llevan en el granero desde antes de que se fundase la aldea. Dicen que tienen papeles."
  - `baldomero`: "Por mi honor, las desalojaremos con todo respeto."
  - `rata_quesera`: "(Se hace la muerta con cara de ofendida.)"
- **Chiste central:** las ratas presentan un contrato de alquiler por un queso al siglo y se hacen las muertas para cobrar el seguro.

### 3.3 `gato_en_el_arbol` — El Gato en el Árbol **(mínima)**

- **Zona / tipo / dificultad:** `aldea` · mínima · 1
- **Ofrece:** `alcaldesa_nata`. **Aparece:** desde el día 1.
- **Condiciones:** ninguna. Es la **llave de la cadena `gallina_noble`**: su recompensa es la `venda_de_caballos`.
- **Objetivo:** bajar a "Su Excelencia Bigotes" de un árbol que no coopera. Sin combate: es un evento con opciones (`elegir(Opcion)`, D-20), máximo 3 intentos. El evento se abre al estar en la zona del objetivo con el contrato activo y las opciones se listan al abrirse (motor de evento mínimo).
- **Dato:**
  ```prolog
  contrato(gato_en_el_arbol, aldea, evento(rescate_gato),
           recompensa([quesos(7), objeto(venda_de_caballos)]), []).
  reintentable(gato_en_el_arbol, 2).
  ```
- **Opciones del evento** (cada una usa un rasgo o miembro):

  | Opción | Quién | Condición | Resultado |
  |---|---|---|---|
  | `trepar` | `tuerca` | `en_pie(tuerca)` | Éxito. |
  | `hechizo_de_raclette` | `pimentina` | Gasta 1 queso (Ley del Cuajo) | Éxito: el gato baja atraído por el olor. |
  | `sacudir_arbol` | `baldomero` | — | A medias: el gato cae, el árbol también, sobre el pozo. |
  | `cantar` | `rufino` | — | El gato sube más alto; consume un intento. **(objetivo)** además deja a Rufino `cantando`. |
- **Consecuencias:**
  - *Éxito:* cobra 7 y la `venda_de_caballos`, moral +1. Los efectos incluyen `equipar(baldomero, venda_de_caballos)`: en la mínima la venda se equipa sola (no hay comando `equipar`) y es lo que hace que `ignora_miedo(baldomero)` sea cierto.
  - *A medias:* cobra 5 y la venda, pero la alcaldesa cobra por el pozo: −1 queso.
  - *Fracaso* (3 intentos sin éxito): el gato se muda a otro árbol; vuelve al tablón en 2 días (**reintentable**); moral −1 (los vecinos miran). Sin venda no se puede aceptar `gallina_noble`, por eso nunca se pierde del todo.
- **Diálogo clave:**
  - `alcaldesa_nata`: "Su Excelencia Bigotes lleva tres días arriba. Dice que desde allí se juzga mejor."
  - `tuerca`: "Yo subo. Las alturas me sientan bien. Ni he estado ni bajaré."
  - `pimentina`: "Querido, a los gatos se les baja con queso, no con honor."
- **Recompensa:** 7 quesos (antes 5), ajuste de la revisión por la economía de la ruta mínima (ver 3.2 y 9.2).
- **Chiste central:** el gato tiene título nobiliario, opiniones sobre el árbol y ninguna prisa.

### 3.4 `fantasma_charlatan` — El Fantasma Charlatán **(objetivo)**

- **Zona / tipo / dificultad:** `aldea` (Casa del Cuervo Gordo) · objetivo · 2
- **Ofrece:** `alcaldesa_nata`. **Aparece:** desde el día 1.
- **Condiciones (legible):** no aceptable si la moral media es menor de 4 ("ni escuchando se puede estar más triste").
- **Objetivo:** escuchar entero a Eustaquio (3 capítulos). No hay combate: el fantasma solo se va si se le escucha.
- **Dato:**
  ```prolog
  contrato(fantasma_charlatan, aldea, escuchar(fantasma_charlatan, 3),
           recompensa([quesos(8)]), [requiere(moral_media_min(4))]).
  % (extra) versión ampliada: recompensa([quesos(8), objeto(llave_mohosa)])
  ```
- **Mecánica:** `elegir(escuchar)` avanza un capítulo (`escuchar` ya no es un comando, D-20; la vía es `evento(escuchar(fantasma_charlatan))` de 3 pasos). Tras cada capítulo, la moral de cada miembro baja 1, salvo la de `rufino` ("lo apunto para la crónica"). No cuesta días de juego.
- **Consecuencias:**
  - *Éxito* (3 capítulos sin interrupciones): cobra 8, marca `escucho_a_eustaquio` (con ella el jefe empieza con 10 de vida menos, objetivo), moral de Rufino +2. **(extra)** recibe además la `llave_mohosa` en el acto y se habilita `cena_de_eustaquio`.
  - *A medias* (alguien está `cantando` o se interrumpe): el fantasma se va ofendido; cobra 4 y no deja la marca (ni la llave, extra).
  - *Fracaso* (el grupo abandona o la moral media baja de 2): la casa sigue embrujada; moral −2 (Ley del Contrato Escrito: abandonar cuesta moral); vuelve al tablón en 2 días (**reintentable**).
- **Diálogo clave:**
  - `fantasma_charlatan`: "¿Os cuento cómo morí? Es una historia corta. Empieza en el año 372 y no ha terminado."
  - `rufino`: "Esto va a la balada."
  - `fantasma_charlatan`: "...y entonces, con el segundo plato a medias, aparecieron los... perdón, ¿por dónde iba?"
- **Chiste central:** Eustaquio asusta casas solo para tener con quién hablar; la historia tiene tres capítulos y ninguno llega al final.

### 3.5 `cena_de_eustaquio` — La Cena de Eustaquio **(extra)**

- **Zona / tipo / dificultad:** `aldea` · extra · 1 (contenido ampliable)
- **Ofrece:** `fantasma_charlatan`. **Aparece:** si `exito(fantasma_charlatan)`.
- **Condiciones (legible):** no aceptable sin `activo(pimentina)` ni con menos de 3 quesos en la despensa (son los ingredientes).
- **Objetivo:** servirle por fin la cena que lleva cuarenta años esperando.
- **Dato:**
  ```prolog
  contrato(cena_de_eustaquio, aldea, evento(servir_cena),
           recompensa([quesos(5), objeto(trebol_de_cuatro_quesos)]),
           [requiere(exito(fantasma_charlatan)), requiere(activo(pimentina)), requiere(queso_min(3))]).
  ```
- **Mecánica:** `elegir(servir)` gasta 3 quesos (usa primero los más curados). Si solo hay queso rancio, el fantasma se queja del postre.
- **Consecuencias:**
  - *Éxito* (cena con queso fresco o curado): Eustaquio descansa en paz; cobra 5 y el `trebol_de_cuatro_quesos`; moral del grupo +2; marca `eustaquio_en_paz`.
  - *A medias* (solo queso rancio): "el postre está pasado"; cobra 2, sin trébol; Pimentina −1 de moral por la crítica.
  - *Fracaso:* no se llega a servir (no hay quesos): el contrato permanece activo.
- **Diálogo clave:**
  - `fantasma_charlatan`: "Mi cena. Después de cuarenta años. ¿Es... es gratinado?"
  - `pimentina`: "Querido, es una promesa gratinada."
- **Chiste central:** el postre llega con cuarenta años de retraso; el fantasma no se lo come, pero lo aprecia.

### 3.6 `silvestre_para_ricota` — Silvestre para Ricota **(extra)**

- **Zona / tipo / dificultad:** `bosque` (se recoge) y `aldea` (se entrega) · extra (contenido ampliable) · 2
- **Ofrece:** `ricota`. **Aparece:** desde el día 1.
- **Condiciones:** ninguna para aceptar. Para entregar, los 3 quesos deben estar **curados** (3 a 9 días).
- **Objetivo:** reunir 3 `queso_silvestre` en el bosque y entregarlos en la aldea, ya curados.
- **Dato:**
  ```prolog
  contrato(silvestre_para_ricota, bosque, reunir(queso_silvestre, 3, estado(curado)),
           recompensa([quesos(10), objeto(baston_de_queso_duro)]), []).
  ```
- **Mecánica:** `elegir(recoger)` en el bosque (ya no es un comando, D-20) da **hasta 3** `queso_silvestre` de edad 0 en una sola visita (corrige 06 X-35a: la ruta de 26 días visita el bosque una vez), y desencadena un encuentro (`seta_chismosa`, `moho_saltarin` o `bandido_torpe`). Los silvestres se guardan aparte de la despensa como objetivo del contrato (la ración consume primero lo fresco, D-11, y se los comería). Envejecen de forma normal. El `moho_saltarin` puede adelantarlo (+2 días al lote más curado): **aquí el enemigo ayuda**.
- **Consecuencias:**
  - *Éxito* (3 curados): cobra 10 y el `baston_de_queso_duro` (Pimentina).
  - *A medias* (entrega frescos): Ricota paga 5 y se queda con el bastón.
  - *Fracaso* (entrega ranciosos, edad 10 o más): Ricota huele el queso, se desmaya y no paga; moral −1.
- **Nota (D-10):** Ricota no "compra queso": los 3 silvestres curados son el objetivo del contrato y su pago es la recompensa. No hay compraventa de queso.
- **Diálogo clave:**
  - `ricota`: "Lo quiero con carácter, pero no con demasiado. Tres días de paciencia, ni uno menos."
  - `tuerca`: "Se puede acelerar. Hay moho en el bosque." (Lección de maduración y de moho aliado.)
- **Chiste central:** los mercenarios tienen que esperar tres días de paciencia, y no saben.

### 3.7 `paz_del_moho` — Paz para el Moho **(extra)**

- **Zona / tipo / dificultad:** `bosque` · extra (contenido ampliable) · 2
- **Ofrece:** `ermitano_penicilio`. **Aparece:** al visitar `bosque`.
- **Condiciones:** ninguna. Pero está prohibido usar `fondue_flamigera` durante el contrato.
- **Objetivo:** echar a dos `bandido_torpe` de su claro, **sin fuego** ("mis amigos son inflamables").
- **Dato:**
  ```prolog
  contrato(paz_del_moho, bosque, eliminar([bandido_torpe-2]),
           recompensa([quesos(9), objeto(salmuera)]), []).   % salmuera (extra): si no existe, +3 quesos
  prohibido(paz_del_moho, uso_habilidad(fondue_flamigera)).
  ```
- **Enemigos:** 2 `bandido_torpe` (12/5/2); huyen con menos de 4 de vida. Aparece un `moho_saltarin` si se usa fuego.
- **Consecuencias:**
  - *Éxito* (sin fuego): cobra 9 y la `salmuera`; Penicilio os cuenta su pista (sección 6.4).
  - *A medias* (una sola vez con fuego): cobra 4; aparece un `moho_saltarin` furioso; Penicilio se niega a hablar con Pimentina un tiempo.
  - *Fracaso* (huir): moral −1.
- **Diálogo clave:**
  - `ermitano_penicilio`: "Echadlos, pero con violencia húmeda. Nada de fuego. Mis amigos son inflamables."
  - `pimentina`: "Querido, ¿y si lo flambeo un poquito?" — `ermitano_penicilio`: "Si flameas, el moho se come tu receta."
- **Chiste central:** la violencia debe ser húmeda; la única maga de la compañía solo sabe hacer lo contrario.

### 3.8 `peaje_del_ganso` — El Peaje del Ganso **(objetivo)**

- **Zona / tipo / dificultad:** `camino_real` · objetivo · 2
- **Ofrece:** un carretero anónimo (tablón). **Aparece:** desde el día 1.
- **Condiciones:** ninguna. Si la compañía ya tiene el `sello_real` (objetivo: se entrega al aceptar `despensa_real`), el ganso "se cuadra" y el contrato se resuelve sin combate (sección "Consecuencias").
- **Objetivo:** poner fin a un peaje abusivo. Un ganso aduanero cobra por entrar al peaje.
- **Dato:**
  ```prolog
  contrato(peaje_del_ganso, camino_real, eliminar([ganso_recaudador-1, bandido_torpe-1]),
           recompensa([quesos(9), objeto(cucharon_de_hierro)]), []).
  ```
- **Enemigos:** 1 `ganso_recaudador` (16/6/2, `cobrar_peaje`, acción especial del objetivo) y 1 `bandido_torpe`. Ambos llevan queso (botín +2).
- **Consecuencias:**
  - *Éxito:* cobra 9 y el `cucharon_de_hierro`.
  - *A medias:* se paga el peaje (3 quesos) o se enseña el `sello_real`; el contrato se cierra "por vía administrativa": cobra 4, sin cucharón.
  - *Fracaso* (solo con `huir`): el ganso os cobra 3 quesos por la molestia y os da un recibo.
- **Diálogo clave:**
  - `ganso_recaudador`: "Honk. Son tres quesos. Tasa de picotazo incluida, recibo en el sobre."
  - `baldomero`: "¿Un ave? ¿Es ave o caballo?" — `tuerca`: "Ave, jefe. Ave."
- **Chiste central:** el ganso te da un recibo antes de picarte.

### 3.9 `gallina_noble` — Lady Clotilde Plumífera **(mínima)**

- **Zona / tipo / dificultad:** `camino_real` hacia `castillo` · mínima · 3
- **Ofrece:** `gallina_noble`. **Aparece:** desde el día 1 (bloqueado hasta tener la venda).
- **Condiciones (legible):** no aceptable mientras haya un miembro activo con el rasgo `teme_caballos` que no ignore el miedo (es decir, que no lleve la `venda_de_caballos`). La regla del canon `rasgo_no(teme_caballos)` se evalúa sobre los miembros, **no mira los enemigos del contrato** (D-19, 06 X-37): es una condición conservadora del contrato entero, aunque el `bandido_montado` sea el motivo narrativo (ver cambio 11.1-1).
- **Objetivo:** escoltar a Lady Clotilde desde el Camino Real hasta el Castillo Camembert, entera, para el Baile de la Cuajada.
- **Dato:**
  ```prolog
  contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo),
           recompensa([quesos(14), queso(brie, 0, 1)]),
           [requiere(rasgo_no(teme_caballos))]).
  enemigos_de(gallina_noble, [bandido_torpe, bandido_torpe, bandido_montado]).
  reintentable(gallina_noble, 3).      % sin él, un fracaso bloquearía despensa_real en la mínima
  ```
- **Enemigos / eventos:** dos `bandido_torpe` (emboscada en el Camino Real) y un `bandido_montado` (18/7/3, `embestir`: segunda acción especial de la mínima) en la puerta del castillo. **Clotilde no es combatiente (D-33, mínima):** es un contador. En cada ronda del combate de la escolta, el primer enemigo vivo en el orden de turnos dirige su acción contra Clotilde en lugar de contra la compañía: se anota un golpe (efecto `contar(golpes_a_clotilde, 1)`) y esa acción no daña a nadie. Con la `venda_de_caballos`, Baldomero puede atacar al montado con −3 de ataque. **(objetivo, si hay colchón)** Clotilde pasa a ser combatiente temporal pasivo del bando jugador (vida 10, defensa 0, sin turno), como proponía la versión anterior.
- **Consecuencias** (umbrales provisionales: un combate típico dura 2–4 rondas):
  - *Éxito* (`golpes_a_clotilde` ≤ 2): cobra 14 y 1 `brie`, moral +1, audiencia inmediata con el rey (marca `recomendada_por_clotilde`). **(objetivo)** además exige que Rufino no esté `cantando` durante el viaje.
  - *A medias* (3 o 4 golpes; **(objetivo)** o Rufino `cantando`): cobra 7; la audiencia es inmediata también.
  - *Fracaso* (5 o más golpes): Clotilde se retira indignada; llegan las cartas de la familia Plumífera: −3 quesos, moral −2. El contrato vuelve al tablón en 3 días (**reintentable**).
  - Recompensa: 14 quesos (antes 12), ajuste de la revisión por la economía de la ruta mínima (ver 3.2 y 9.2).
- **Diálogo clave:**
  - `gallina_noble`: "Soy una gallina de buena familia, no una gallina cualquiera. Exijo palanquín."
  - `baldomero` (al ver al montado): "Por mi honor, no estoy temblando: es la armadura."
  - `gallina_noble` (a Rufino): "Si canta, picoteo."
- **Chiste central:** el peligro no son los bandidos; es el protocolo de la gallina.

### 3.10 `caballo_fugado` — Gorgonzola Se Ha Escapado **(extra)**

- **Zona / tipo / dificultad:** `bosque` (el caballo) y `camino_real` (el capitán) · extra (contenido ampliable) · 3
- **Ofrece:** `capitan_pecorino`. **Aparece:** si `contratos_cumplidos_min(2)` y se visita `camino_real`.
- **Condiciones (legible):** no aceptable si hay un miembro activo con `teme_caballos` que no ignore el miedo (sin venda; el objetivo es un caballo) ni con menos de 2 contratos cumplidos ("confío en quien no rompe nada importante").
- **Objetivo:** calmar a Gorgonzola, el caballo de Pecorino, y devolverlo. Sin combate.
- **Dato:**
  ```prolog
  contrato(caballo_fugado, bosque, evento(calmar_caballo),
           recompensa([quesos(12), objeto(estoque_de_parmesano)]),
           [requiere(rasgo_no(teme_caballos)), requiere(contratos_cumplidos_min(2))]).
  ```
- **Opciones del evento** (3 intentos):

  | Opción | Quién | Resultado |
  |---|---|---|
  | `ofrecer_queso` | `pimentina` | Éxito si ofrece un queso curado o `camembert` (gasta 1). |
  | `nana` | `rufino` | Éxito (el caballo se duerme; Rufino queda `cantando`). |
  | `lazar` | `tuerca` | A medias: Gorgonzola vuelve, pero sin la silla. |
  | `acercarse` | `baldomero` | Falla: Gorgonzola se espanta y huye; consume un intento. |
- **Consecuencias:**
  - *Éxito:* cobra 12 y el `estoque_de_parmesano`; Pecorino mejora su trato: se activa `reconocimiento_de_cuevas`.
  - *A medias:* cobra 6, sin estoque.
  - *Fracaso* (3 intentos sin éxito): Pecorino: "Esperaba menos, y aun así me habéis decepcionado." Vuelve al tablón en 3 días (**reintentable**); sin pago.
- **Diálogo clave:**
  - `capitan_pecorino`: "Mi caballo, Gorgonzola, se ha escapado. No he dicho 'huido': ha escapado de mis expectativas."
  - `baldomero`: "Yo me ocupo. ¿Es muy grande? ¿Tiene... patas?"
- **Chiste central:** el caballo y el caballero se miran, y solo uno de los dos tiene complejos.

### 3.11 `correo_real_perdido` — El Correo Real Perdido **(extra)**

- **Zona / tipo / dificultad:** `camino_real` · extra (contenido ampliable) · 3
- **Ofrece:** tablón (cartero de la Corona). **Aparece:** si `contratos_cumplidos_min(2)`.
- **Condiciones:** ninguna más. Enseña la **retaguardia**: el arquero ataca a distancia.
- **Objetivo:** recuperar la saca del correo del rey, robada por un bandido con un arquero de apoyo.
- **Dato:**
  ```prolog
  contrato(correo_real_perdido, camino_real, recuperar(saca_del_correo),
           recompensa([quesos(12)]), [requiere(contratos_cumplidos_min(2))]).
  enemigos_de(correo_real_perdido, [bandido_torpe, arquero_aburrido]).
  ```
- **Enemigos:** `bandido_torpe` (frente) y `arquero_aburrido` (retaguardia, 11/7/1, `apuntar`: ataca a distancia al de menos vida). Objetivo `recuperar/1` (extra): su vía es un `evento` que dispara este combate.
- **Consecuencias:**
  - *Éxito:* saca intacta: cobra 12.
  - *A medias* (se usó `fondue_flamigera`: parte de las cartas se quema): cobra 6.
  - *Fracaso:* el bandido huye con la saca; sin pago.
- **Diálogo clave:**
  - `arquero_aburrido`: "Termino a las seis. Si queréis acabar antes, apuntad bien."
  - `rufino` (leyendo una carta): "'Querido rey: su reino huele fatal.' Firma el tercer cortesano. Respuesta preimpresa: 'Es el queso.'"
- **Chiste central:** la saca tiene 1.200 quejas por el olor, todas con la misma respuesta preimpresa.

### 3.12 `degustador_real` — El Degustador Real **(extra)**

- **Zona / tipo / dificultad:** `castillo` · extra (contenido ampliable) · 2
- **Ofrece:** `rey_brieto`. **Aparece:** si `visita(castillo)`.
- **Condiciones:** `activo(pimentina)`. Pimentina es la única con paladar certificado.
- **Objetivo:** catar hasta 4 muestras de la despensa real para encontrar de dónde viene el rancio. Sin combate.
- **Dato:**
  ```prolog
  contrato(degustador_real, castillo, evento(catar_despensa),
           recompensa([quesos(12)]), [requiere(activo(pimentina))]).
  ```
- **Mecánica:** `elegir(catar)` (ya no es un comando, D-20) prueba una muestra (la 1ª y 2ª están rancias; la 3ª es la pista). Cada muestra rancia baja 2 la moral del grupo (1 la de Pimentina). Se puede parar cuando se quiera.
- **Consecuencias:**
  - *Éxito* (3 muestras o más): cobra 12; marca `sabe_origen_rancio` ("viene de las Cuevas del Roquefort").
  - *A medias* (1–2 muestras): cobra 6; el rey acaba de oler solo el problema.
  - *Fracaso* (la moral media baja de 3 durante la cata): el rey se ofende; sin pago, la pista se pierde (se recupera con Penicilio o con el arco P1).
- **Diálogo clave:**
  - `rey_brieto`: "Es una reserva especial. De hace... varias semanas."
  - `pimentina`: "Querido, esto no es un queso; es una opinión."
  - `tuerca`: "Yo, si no me los comen, me los llevo."
- **Chiste central:** el rey presenta como "gran reserva" su despensa podrida y todos tienen que sonreír.

### 3.13 `inspeccion_del_manual` — Inspección del Manual **(extra)**

- **Zona / tipo / dificultad:** `castillo` · extra (contenido ampliable) · 4
- **Ofrece:** `rey_brieto`. **Aparece:** si `visita(castillo)`.
- **Condiciones (legible):** no aceptable con menos de 4 contratos cumplidos.
- **Objetivo:** despejar el ala del rey, bloqueada por guardias que obedecen a su manual.
- **Dato:**
  ```prolog
  contrato(inspeccion_del_manual, castillo,
           eliminar([guardia_de_corteza-2, arquero_aburrido-1]),
           recompensa([quesos(16), objeto(coraza_de_corteza)]),
           [requiere(contratos_cumplidos_min(4))]).
  ```
- **Enemigos:** 2 `guardia_de_corteza` (28/8/7, `defender` en el primer turno, luego `atacar`) y 1 `arquero_aburrido`. Contra defensa 7 el daño base es bajo: es el contrato que obliga a usar `fondue_flamigera` (daño fijo, ignora defensa) y el equipo ganado.
- **Salida pacífica:** `elegir(leer_el_manual)` con Rufino activo: los guardias se quedan leyendo y el contrato se cierra como *a medias* (8 quesos, sin coraza), pero sin combate.
- **Consecuencias:**
  - *Éxito (combate):* cobra 16 y la `coraza_de_corteza`.
  - *A medias (leer el manual):* cobra 8, sin coraza.
  - *Fracaso:* los guardias "archivan la queja": −2 quesos de multa.
- **Diálogo clave:**
  - `guardia_de_corteza`: "Artículo 14 bis: ante un intruso, se leerá en voz alta el artículo 14 bis."
  - `rufino`: "Lo leo yo. ¿Qué precio tiene el silencio de un guardia?"
- **Chiste central:** los guardias se detienen a leer el manual en pleno combate y el manual no contempla que sea un manual.

### 3.14 `reconocimiento_de_cuevas` — Consulta Externa en las Cuevas **(extra)**

- **Zona / tipo / dificultad:** `cuevas` · extra (contenido ampliable) · 4
- **Ofrece:** `capitan_pecorino`. **Aparece:** si `exito(caballo_fugado)`.
- **Condiciones (legible):** no aceptable sin haber cumplido `caballo_fugado` ni con la moral media por debajo de 5.
- **Objetivo:** explorar la entrada de las Cuevas y despejarla de murciélagos y moho, porque los caballos de las Lanzas Parmesanas se resbalan.
- **Dato:**
  ```prolog
  contrato(reconocimiento_de_cuevas, cuevas,
           eliminar([murcielago_azul-2, moho_saltarin-1]),
           recompensa([quesos(18), queso(roquefort, 3, 2), objeto(ganzua_de_oro)]),
           [requiere(hecho(caballo_fugado)), requiere(moral_media_min(5))]).
  ```
- **Enemigos:** 2 `murcielago_azul` (14/8/1, retaguardia, distancia) y 1 `moho_saltarin` (envejece +2 el lote más curado). Marca la ruta como despejada (`cuevas_despejadas`): evita el encuentro forzado al llegar al jefe.
- **Consecuencias:**
  - *Éxito:* cobra 18, 2 `roquefort` ya curados (edad 3) y la `ganzua_de_oro`.
  - *A medias* (el grupo huye una vez; `huir` es de objetivo): cobra 9, sin ganzúa.
  - *Fracaso:* sin pago; el moho avanza: −1 queso (se estropea una unidad).
- **Diálogo clave:**
  - `capitan_pecorino`: "Esto no es una petición de ayuda. Es una consulta externa."
  - `baldomero`: "Capitán, ¿y si cae un caballo?" — `capitan_pecorino`: "Entonces no habéis venido a ver nada."
- **Chiste central:** las Lanzas Parmesanas no piden ayuda; "consultan externamente", y la consulta paga mejor que sus sueldos.

### 3.15 `despensa_real` — La Despensa Real **(mínima)**

- **Zona / tipo / dificultad:** `cuevas` (se ofrece en `castillo`) · mínima · 5
- **Ofrece:** `rey_brieto`. **Aparece:** tras la audiencia en el castillo.
- **Condiciones (legible):** no aceptable si hay menos de 3 contratos cumplidos, no se ha visitado el castillo, la moral media es menor de 4 o hay menos de 3 miembros en pie (`en_pie/1`: activos y no en huelga). (**extra**: variante dura con `requiere(objeto(llave_mohosa))`; la frase F10c del banco de frases solo se activa en esa variante, 06 X-41.)
- **Objetivo:** derrotar al `gran_roquefort` en las Cuevas del Roquefort.
- **Dato:**
  ```prolog
  contrato(despensa_real, cuevas, derrotar(gran_roquefort),
           recompensa([quesos(40)]),
           [requiere(contratos_cumplidos_min(3)), requiere(visita(castillo)),
            requiere(moral_media_min(4)), requiere(miembros_en_pie_min(3))]).
  ```
- **Al aceptar:** **(objetivo)** el rey entrega el `sello_real` en el acto (el `ganso_recaudador` ya no ataca; **extra**: abre la armería del castillo). En la mínima no hay objeto.
- **Enemigos / eventos:** ver sección 8 (jefe final).
- **Consecuencias:** *Éxito* = victoria y uno de los finales de la sección 8 (los 40 quesos de la recompensa pertenecen al epílogo). *Fracaso* = derrota `derrota_combate` (todos caídos, D-17). **No se puede huir del jefe** (D-29, 06 X-45): el comando `huir` se rechaza en este combate y `por_que_no(huir)` lo explica.
- **Diálogo clave:**
  - `rey_brieto`: "Mis quesos se pudren. Necesito a alguien... disponible. Preferiblemente barato."
  - `capitan_pecorino` (al saber que los contrató a ellos): "Disponibles. Eso es lo que son."
- **Chiste central:** el rey contrata a los peores porque los buenos no cobran en promesas de cobro.

---

### 3.16 Tabla resumen de progresión

Ordenada por nivel de alcance. Las recompensas son las vigentes tras el recálculo de la economía (9.2); las marcadas con asterisco cambian respecto a la versión anterior (ratas 7→9, gato 5→7, gallina 12→14).

| # | Id | Nivel | Zona | Dif. | Aparece / condiciones | Recompensa | Días antes de poder hacerlo |
|---|---|---|---|---|---|---|---|
| 1 | `ratas_del_granero` | mínima | `aldea` | 1 | siempre | 9* cheddar + `pocion` | 2 |
| 2 | `gato_en_el_arbol` | mínima | `aldea` | 1 | siempre | 7* cheddar + `venda_de_caballos` | 2 |
| 3 | `gallina_noble` | mínima | `camino_real` | 3 | `rasgo_no(teme_caballos)` (venda) | 14* cheddar + 1 brie | 3 (necesita la venda del nº 2) |
| 4 | `despensa_real` | mínima | `cuevas` | 5 | 3 contratos, castillo, moral ≥ 4, 3 en pie | 40 cheddar (final) | 5 (audiencia) |
| 5 | `peaje_del_ganso` | objetivo | `camino_real` | 2 | siempre | 9 cheddar + `cucharon_de_hierro` | 2 |
| 6 | `fantasma_charlatan` | objetivo | `aldea` | 2 | moral media ≥ 4 | 8 cheddar (+ `llave_mohosa`, extra) | 2 |
| 7 | `degustador_real` | extra | `castillo` | 2 | `visita(castillo)`, Pimentina activa | 12 cheddar | 5 |
| 8 | `silvestre_para_ricota` | extra | `bosque`/`aldea` | 2 | siempre; entrega curada | 10 cheddar + `baston_de_queso_duro` | 5 |
| 9 | `paz_del_moho` | extra | `bosque` | 2 | `visita(bosque)`; sin fuego | 9 cheddar + `salmuera` | 4 |
| 10 | `caballo_fugado` | extra | `bosque` | 3 | 2 contratos + venda | 12 cheddar + `estoque_de_parmesano` | 4 |
| 11 | `correo_real_perdido` | extra | `camino_real` | 3 | 2 contratos | 12 cheddar | 4 |
| 12 | `inspeccion_del_manual` | extra | `castillo` | 4 | 4 contratos, `visita(castillo)` | 16 cheddar + `coraza_de_corteza` | 7 |
| 13 | `reconocimiento_de_cuevas` | extra | `cuevas` | 4 | `exito(caballo_fugado)`, moral ≥ 5 | 18 cheddar + 2 roquefort + `ganzua_de_oro` | 8 |
| 14 | `cena_de_eustaquio` | extra | `aldea` | 1 | `exito(fantasma_charlatan)`, 3 quesos | 5 cheddar + `trebol_de_cuatro_quesos` | 6 |
| 15 | `pelea_de_taberna` | extra | `taberna` | 1 | 3 contratos cumplidos | 4 cheddar + 2 descansos gratis | 6 |

La ficha de `pelea_de_taberna` está en la sección 3.17.

### 3.17 `pelea_de_taberna` — Dentro del Local Se Discute **(extra)**

- **Zona / tipo / dificultad:** `taberna` · extra (contenido ampliable) · 1
- **Ofrece:** `mantecosa`. **Aparece:** si `contratos_cumplidos_min(3)` (llegan los `hermanos_emmental`).
- **Condiciones (legible):** ninguna. La Ley de la Taberna prohíbe el combate: `\+ permite_combate(taberna)` (`permite_combate/1` es el predicado de zona; `puede_combatir/1` es el del personaje, X-14).
- **Objetivo:** mediar en una disputa de tres hermanos sobre quién ha perdido qué por qué agujero.
- **Dato:**
  ```prolog
  contrato(pelea_de_taberna, taberna, evento(discusion),
           recompensa([quesos(4), descansos_gratis(2)]), []).   % descansos_gratis(2) = efecto ganar_descansos(2)
  ```
- **Mecánica:** `elegir(discutir)` con `rufino` activo resuelve el contrato. `elegir(sopa)` con `pimentina` lo resuelve a medias ("cortó la discusión con un guiso"). Cualquier intento de `atacar` es rechazado con la Ley de la Taberna y es un buen momento para `por_que_no(atacar(...))`.
- **Consecuencias:**
  - *Éxito:* cobra 4 y 2 descansos gratis; moral +1.
  - *A medias:* cobra 2.
  - *Fracaso* (se intenta pelear): multa de 2 quesos "por daños que aún no han ocurrido".
- **Diálogo clave:**
  - `mantecosa`: "Aquí no se pelea: se discute. Y se discute pagando."
  - `rufino`: "Yo discuto, tú callas, él paga. ¿Cuánto cobro por callar?"
- **Chiste central:** los hermanos Emmental discuten sobre qué agujero se llevó el queso, y la respuesta es todos.

---

### 3.18 Contratos como demostraciones de `por_que_no/1`

| Intento | Falla por | Qué enseña |
|---|---|---|
| `aceptar(gallina_noble)` en el día 1 (mínima) | `rasgo_no(teme_caballos)`: `rasgo(baldomero, teme_caballos)` y `\+ ignora_miedo(baldomero)` (sin venda) | Negación como fallo y rasgos como reglas. Es el momento clave de la exposición. |
| `aceptar(despensa_real)` sin 3 contratos (mínima) | `contratos_cumplidos_min(3)` | Aritmética y `findall`/`length`. |
| `atacar(baldomero, bandido_montado)` sin venda (mínima; hace falta un estado de prueba, ver nota) | `puede_atacar/2`: `teme(baldomero, caballo)` por `rasgo(baldomero, teme_caballos)` y `\+ ignora_miedo(baldomero)` | La misma regla `teme/2` explica el contrato y el combate. |
| `aceptar(fantasma_charlatan)` con moral baja (objetivo) | `moral_media_min(4)` | Estado numérico en las condiciones. |
| `atacar(...)` en la taberna (objetivo) | `\+ permite_combate(taberna)` | Ley de la Taberna como negación. |
| `aceptar(reconocimiento_de_cuevas)` sin `caballo_fugado` (extra) | `hecho(caballo_fugado)` | Cadena de dependencias. |
| `descansar` sin 2 quesos (mínima) | `puede_descansar/0`: `queso_min(2)` | Falla de un recurso (D-15, sin deuda). |
| `huir` ante el jefe (mínima) | no se puede huir de un jefe (D-29) | Regla de combate explicada. |

> Nota: en una partida normal Baldomero ya lleva la venda cuando llega el `bandido_montado`, así que `por_que_no(atacar(baldomero, bandido_montado))` solo falla en un estado de prueba (la `demo` y las pruebas parten de un estado con la venda sin equipar). Con la venda, `explicar(atacar(baldomero, bandido_montado))` muestra por qué sí puede.

---

## 4. Contratos por nivel de alcance (hilo principal frente a secundarios)

### 4.1 Clasificación

| Nivel | Contratos | Por qué |
|---|---|---|
| **Mínima (4)** | `ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real` | Son justo los 3 contratos que exige `despensa_real` más el propio: combate básico, evento con opciones, escolta con el miedo de Baldomero y jefe. Es un recorrido jugable completo y mantiene las dos demostraciones centrales de `por_que_no`. |
| **Objetivo (+2 = 6)** | `peaje_del_ganso`, `fantasma_charlatan` | Enemigo aviar, diálogo y la ventaja contra el jefe (`exito(fantasma_charlatan)`). |
| **(extra) contenido ampliable (9)** | `silvestre_para_ricota`, `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna` | Dan equipo, queso, humor y variedad; no forman parte de la entrega. Orden de recorte entre los extra: `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna`. |

La obligatoriedad es solo la del jefe: sin `despensa_real` no hay fin de campaña. El equipo extra (bastón, estoque, coraza, ganzúa...) queda como "contenido ampliable" y es lo que haría el jefe "mucho más llevadero" en la versión ampliada; en la mínima el jefe se afronta con la `venda_de_caballos` y la `pocion`.

### 4.2 Dependencias duras y blandas

```
ratas_del_granero (M) ──┐
gato_en_el_arbol (M) ───┼─► (venda_de_caballos) ─► gallina_noble (M) ─┐ (audiencia inmediata)
fantasma_charlatan (O) ─┘   │                                          ├─► despensa_real (M)
peaje_del_ganso (O) ────────┘ (3 contratos cumplidos, dura)            │   [dura: 3 contratos + castillo + moral + 3 en pie]
                                                                       │
 M = mínima, O = objetivo. Blandas (extra, salvo la ventaja del fantasma): llave_mohosa (salta el gólem),
 estoque, coraza, bastón, cucharón, ganzúa; exito(fantasma) = -10 de vida al jefe (objetivo; con llave, extra)
```

| Dependencia | Tipo | Efecto |
|---|---|---|
| `gato_en_el_arbol` → `gallina_noble` | **Dura** (mínima) | Sin venda, Baldomero bloquea `gallina_noble` (`rasgo_no`). Por eso `gato_en_el_arbol` es **reintentable**, y `gallina_noble` también (si no, un fracaso bloquearía `despensa_real` en la mínima). |
| `caballo_fugado` → `reconocimiento_de_cuevas` | Dura (extra) | Pecorino solo contrata a quien trata bien a sus caballos. |
| `exito(fantasma_charlatan)` → `cena_de_eustaquio` | Dura (extra) | La cena es la continuación de la historia. |
| 3 contratos cumplidos → `despensa_real` | **Dura** (mínima) | Regla de `aceptar/1` (demostración de `por_que_no`). Cuenta el contrato resuelto aunque aún no esté cobrado. |
| `gallina_noble` (éxito o a medias) → audiencia inmediata | Blanda (mínima) | Sin ella, la audiencia espera 1 día de cola (un día de comida). |
| `llave_mohosa` → salto del gólem de la puerta interior | Blanda (extra) | Sin llave, hay un combate extra contra `golem_de_queso_duro`. |
| `exito(fantasma_charlatan)` → jefe con −10 de vida | Blanda (objetivo) | Regla extra del lore; con llave en la versión ampliada. |

### 4.3 Orden recomendado

**Ruta mínima** (9 días, tabla de 9.2): días 1–3, `ratas_del_granero` + `gato_en_el_arbol` en un viaje a la aldea y primer cobro; días 3–7, `gallina_noble` (emboscada, montado, audiencia en el castillo, aceptar `despensa_real`) y regreso a cobrar; días 8–9, salida hacia las cuevas y jefe. **Ruta objetivo:** igual, con `fantasma_charlatan` en la aldea y `peaje_del_ganso` en el camino. El resto de la tabla es contenido ampliable:

| Fase (ruta ampliada, extra) | Contratos | Motivo |
|---|---|---|
| 1. Día 1–3 | `ratas_del_granero` + `gato_en_el_arbol` + `fantasma_charlatan` (los tres a la vez en un viaje a la aldea) | Un viaje de 2 días, 3 contratos: la mejor relación queso/día de la campaña. Aprendizaje. |
| 2. Día 3–7 | `peaje_del_ganso` + `gallina_noble` (+ `degustador_real` ya en el castillo) | Dos contratos en el camino, uno en el castillo, un solo cobro en la taberna. |
| 3. Día 8–14 | `silvestre_para_ricota` + `paz_del_moho` + `caballo_fugado` en una sola salida al bosque | Equipo (bastón, estoque) y salmuera. Cuidado con la maduración del silvestre. |
| 4. Día 15–23 | `correo_real_perdido` + `inspeccion_del_manual` (camino y castillo); luego `reconocimiento_de_cuevas` | Coraza y ganzúa. Cuevas despejadas. |
| 5. Día 24–26 | Cena de despedida, descanso, `despensa_real` | Jefe. |

Regla de oro del diseño (se ve en la sección 9): **cada día de viaje cuesta 4 quesos de comida**, así que los contratos baratos y lejanos no compensan en solitario; hay que agruparlos por zona.

---

## 5. Arcos personales

**Nivel de alcance (06 §5.1):** la versión **mínima** no tiene arcos (0); el **objetivo** implementa 2 momentos (B1 y R1); los otros 10 son **(extra)**, contenido ampliable. Cada arco son 3 momentos. No suceden por tiempo fijo: cada uno tiene un **gatillo** (cuándo se evalúa) y unas **condiciones** de estado (moral, contratos, contadores, objetos). Si la condición no se cumple, el momento se pospone sin consecuencias. Todos son diálogos y cambios de estado: no requieren combate propio.

### 5.1 Contadores de estado necesarios

Los contadores se guardan en `contador/2` y se modifican con el efecto `contar(Clave, N)` (06 X-03, X-22). `contratos_cumplidos` y `contratos_exito` no son contadores: son recuentos derivados (`contratos_cumplidos(N)`, `contratos_exito(N)`).

| Contador | Se incrementa cuando | Lo usa | Nivel |
|---|---|---|---|
| `quesos_robados` | Una `rata_quesera` ejecuta `robar_queso` | Resultado de `ratas_del_granero` | mínima |
| `golpes_a_clotilde` | Cada ronda del combate de la escolta (D-33) | Resultado de `gallina_noble` | mínima |
| `silencios_pagados` | Se usa `silencio_pagado` (pagar a Rufino para que calle) | R2 | extra |
| `hechizos` | Pimentina lanza un hechizo (gasta queso) | P2 | extra |
| `rebuscados` | Tuerca usa `rebuscar_bolsillos` | T1 | extra |
| `ataques_a_caballo` | Baldomero acierta un ataque a un enemigo de clase `caballo` | B2 | extra |

### 5.2 Sir Baldomero (rasgo `teme_caballos`)

| Momento | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| **B1. La Venda** **(objetivo)** | Al cobrar `gato_en_el_arbol` (recibe la venda) | `objeto(venda_de_caballos)` y `activo(baldomero)` | Escena y moral de Baldomero +1. (El `equipar(baldomero, venda_de_caballos)` ya lo hace la consecuencia del contrato, también en la mínima.) | Baldomero: "Un pañuelo de dama. Por mi honor, lo luciré con orgullo." Narrador: "No es un pañuelo. Nadie se lo dirá." |
| **B2. El bocadillo** **(extra)** | Tras un combate | `cuenta_min(ataques_a_caballo, 1)` y lleva la venda | Moral de Baldomero +2; marca `baldomero_perdona` | Flashback: un caballo de feria, un bocadillo de queso, una mirada a los ojos. Baldomero: "No era rencor... era hambre. Lo entiendo ahora." |
| **B3. El juramento** **(extra)** | Al llegar a `cuevas` | `contrato_activo(despensa_real)` y moral de Baldomero ≥ 7 | Hasta el final del combate del jefe: modificador de ataque +1 en Baldomero | Baldomero: "Un caballero no huye. Se reposiciona... hacia delante." Si la moral es < 7, no hay efecto y el texto es: "Por mi honor... es la armadura." |

### 5.3 Madame Pimentina (rasgo `hechizos_de_cocina`)

| Momento | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| **P1. El reencuentro** **(extra)** | Al llegar a `castillo` por primera vez | Pimentina activa | Marca `sabe_origen_rancio`; moral de Pimentina +1 | Pimentina prueba la sopa del patio y suspira: "Esto no es moho, querido. Es un queso con ínfulas." |
| **P2. La receta olvidada** **(extra)** | Tras un combate | `cuenta_min(hechizos, 6)` | Mejora permanente: `fondue_flamigera` +1 de daño | "Una pizca de pimienta, una pizca de mala idea, y un poco de cucharón." |
| **P3. La cena de despedida** **(extra)** | Al estar en la `taberna` | `contrato_activo(despensa_real)` y `queso_min(8)`; el jugador elige `elegir(banquete)` (opción, no comando; fusiona con descansar) | Gasta 6 quesos; toda la compañía recupera la vida; moral del grupo +2 | Pimentina: "Nadie va a las cuevas con el estómago mal planchado. Sentaos." |

### 5.4 Rufino (rasgo `cobra_por_callar`)

| Momento | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| **R1. La balada del caballero** **(objetivo)** | Al empezar el primer combate con un enemigo de clase `caballo` | `activo(rufino)` y `activo(baldomero)` | Rufino pide 2 quesos por callar; si no se pagan, queda `cantando` y la moral de Baldomero baja 1 | Rufino: "¡Y entonces nuestro héroe, que temía a los caballos...!" Baldomero: "Os pago. No cantéis, por mi honor." |
| **R2. Cliente fiel** **(extra)** | Al llegar a la `taberna` | `cuenta_min(silencios_pagados, 5)` | Los 3 siguientes `silencio_pagado` no cuestan queso | Rufino: "Ya sois cliente de la casa. Os debo una balada. Mala, pero con descuento." |
| **R3. La balada completa** **(extra)** | Al empezar el combate contra `gran_roquefort` | `exito(fantasma_charlatan)`, Rufino en pie, moral media ≥ 6 | Se habilita `balada_completa` (una sola vez): el jefe pierde su acción durante 2 rondas ("se emociona") | Rufino: "Dicen que no sé terminar una balada. Escuchad el final." |

### 5.5 Tuerca (rasgo `manos_largas`)

| Momento | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| **T1. La libreta de botines** **(extra)** | Tras un combate | `cuenta_min(rebuscados, 3)` | Tuerca "devuelve" 2 quesos a la despensa; moral del grupo +1 | Tuerca: "He encontrado cosas. No son mías. No diré de quién son." |
| **T2. Devolver con intereses** **(extra)** | Al llegar a la `taberna` | Moral media ≥ 7 y día ≥ 10 | `ganar_descansos(1)` (Mantecosa descuenta una noche) | Tuerca: "No es robar: es devolver con ventaja. Doña Mantecosa me ha sonreído. No sé por qué." |
| **T3. El frasco** **(extra)** | Al empezar el combate contra `gran_roquefort` | T1 hecho y Tuerca en pie | El jefe pasa a `lleva_queso`: `rebuscar_bolsillos` le quita las `esporas_curativas` (no podrá curarse) | Tuerca: "Llevaba un frasco con la etiqueta 'para emergencias'. Ahora es mío." |

```prolog
% boceto sin ejecutar
% arco(Personaje, Paso, Gatillo, Condiciones, Efectos, Texto)
arco(pimentina, 2, tras_combate, [cuenta_min(hechizos, 6)],
     [marcar(mejora(fondue_flamigera, dano, 1)), marcar(pimentina_receta)],   % P2 (extra); combate:efecto_habilidad/2 lee la marca
     'Una pizca de pimienta, una pizca de mala idea, y un poco de cucharon.').
```

---

## 6. Diálogos de los NPC

**Nivel de alcance:** `mantecosa`, `alcaldesa_nata`, `gallina_noble` y `rey_brieto` (mínima); `fantasma_charlatan` y los enemigos `ganso_recaudador` y `arquero_aburrido` (objetivo); `ricota`, `ermitano_penicilio`, `capitan_pecorino` y `guardia_de_corteza` (extra, contenido ampliable). Las líneas son hechos `dialogo(Npc, Tema, Texto)` (sección 10); según 06 X-07 el texto puede quedar inline en la mínima y moverse al almacén único `frase/3` (clave `texto(dialogo(Npc, Tema))`) en la semana 4. Los temas son `saludo`, `oferta(Contrato)`, `rechazo(Condicion)` y `despedida`. El `rechazo` se elige según **la primera condición que falla**, de modo que el NPC "explica" el rechazo en su voz y coincide con lo que dice `por_que_no/1`.

### 6.1 `mantecosa` — Doña Mantecosa **(mínima)**

| Tema | Línea |
|---|---|
| Saludo | "Bienvenidos al Cuajo Torcido. La puerta se cierra sola: forma parte del servicio." |
| Oferta | "El tablón está ahí. Lo que no está clavado es cobrable. Lo que sí, también." |
| Rechazo (`descansar` sin 2 quesos; D-15, sin deuda) | "Dos quesos la noche, jefe. Las camas tienen principios y no fían." |
| Rechazo (no se pelea; `\+ permite_combate(taberna)`) | "Dentro del local no se pelea: se discute. Y se discute pagando." |
| Despedida | "Volved enteros. O, al menos, pagados." |

### 6.2 `ricota` — Ricota el Tendero **(extra)**

| Tema | Línea |
|---|---|
| Saludo | "¡Pasad, pasad! Todo tiene arreglo con una buena oferta." |
| Oferta (`silvestre_para_ricota`) | "Tres silvestres curados. Con carácter, pero con modales." |
| Rechazo (queso fresco) | "Esto es un recién nacido. Volved cuando tenga opiniones." |
| Rechazo (queso rancio) | "Esto no es queso, es un recuerdo." |
| Despedida | "¡Volved! Y traed el silvestre curado, que el pan duro no se come solo." |

### 6.3 `alcaldesa_nata` — Alcaldesa Nata **(mínima)**

| Tema | Línea |
|---|---|
| Saludo | "Ah, la Banda Chapuza. Anotada en mi lista de quejas, sección 'Otros'." |
| Oferta (mínima) | "Tengo dos problemas pequeños. Ninguno es grave. Los dos son urgentes." |
| Oferta (objetivo, con `fantasma_charlatan`) | "Tengo tres problemas pequeños. Ninguno es grave. Todos son urgentes." |
| Rechazo (moral baja; objetivo) | "Con esa cara, el fantasma os asusta a vosotros. Volved más animados." |
| Rechazo (contrato ya activo) | "Resolved primero lo que ya firmasteis. Soy de un solo problema a la vez." |
| Despedida | "Que os vaya bien. Y si no, ya me quejaré yo." |

### 6.4 `ermitano_penicilio` — Hermano Penicilio **(extra)**

| Tema | Línea |
|---|---|
| Saludo | "Shh. Escuchad: el moho está de buen humor." |
| Oferta (`paz_del_moho`) | "Echad a los bandidos. Sin fuego. Mis amigos son inflamables." |
| Rechazo (usó fuego) | "No. Vuestra aura huele a fondue." |
| Pista (extra) | "El Gran Rancio no viene del bosque. Viene de abajo. De muy abajo." |
| Despedida | "Que el moho os sea leve." |

### 6.5 `gallina_noble` — Lady Clotilde Plumífera **(mínima)**

| Tema | Línea |
|---|---|
| Saludo | "Buenos días. Hágame el favor de no mirarme el pico." |
| Oferta (`gallina_noble`) | "Me dirijo al Baile de la Cuajada. Llevadme entera y os picoteo... lo justo." |
| Rechazo (Baldomero temblando: `rasgo_no(teme_caballos)`) | "¿Ese caballero tiembla? Tengo un viaje delicado, no una excursión de sustos." |
| Rechazo (Rufino cantando; objetivo) | "Si vuelve a cantar, le pico. Es un aviso de cortesía." |
| Despedida | "Muy amables. Cuando escriba mis memorias, ocuparéis una nota al pie." |

### 6.6 `fantasma_charlatan` — Eustaquio **(objetivo)**

| Tema | Línea |
|---|---|
| Saludo | "¡Oh! ¡Visitas! Hacía... bueno, hace tiempo. ¿Os cuento cómo morí?" |
| Oferta (`fantasma_charlatan`) | "Solo os pido que me escuchéis. Hasta el final. Quedan tres capítulos." |
| Rechazo (se va a mitad) | "¿Ya os vais? Si apenas había llegado al segundo plato." |
| Éxito (objetivo) | "Gracias por escuchar. Me voy más ligero: ya no cuento solo." |
| Éxito (extra: entrega la llave) | "Gracias por escuchar. Os doy esta llave, que abre una puerta de las cuevas. Ya no la necesito: no tengo puertas." |
| Despedida | "Volved cuando queráis. Siempre estaré aquí. Es mi especialidad." |

### 6.7 `capitan_pecorino` — Capitán Pecorino Duro **(extra)**

| Tema | Línea |
|---|---|
| Saludo | "Banda Chapuza. Qué... inesperado. Siga su camino." |
| Oferta (`caballo_fugado`, `reconocimiento_de_cuevas`) | "Un asunto menor, que las Lanzas Parmesanas no pueden atender por... agenda." |
| Rechazo (pocos contratos) | "No contrato a quien aún no ha roto nada importante. Todavía." |
| Rechazo (`caballo_fugado` no cumplido) | "Antes demostrad que sabéis tratar a un caballo. O a un compañero de caballo." |
| Despedida | "Cumplid, y quizá os salude. Con la cabeza. Un poco." |

### 6.8 `rey_brieto` — Rey Brieto IV "el Mal Curado" **(mínima)**

| Tema | Línea |
|---|---|
| Saludo | "¡Ah, mercenarios! Perdón por el olor. Es el reino." |
| Oferta (`despensa_real`) | "Mi despensa se está pudriendo. Necesito a alguien... disponible." |
| Rechazo (pocos contratos) | "Aún no, queridos. Primero haced méritos. O llegad con más ánimo." |
| Rechazo (moral baja) | "Os veo muy poco curados. Volved cuando tengáis más cuerpo." |
| Despedida | "Id con el queso. O sin él. Pero id." |

### 6.9 Otros personajes con línea propia

Nivel: `ganso_recaudador` y `arquero_aburrido` (objetivo); `guardia_de_corteza` (extra).

| Quién | Línea |
|---|---|
| `ganso_recaudador` | "Honk. Son tres quesos. Tasa de picotazo incluida." |
| `guardia_de_corteza` | "Artículo 14 bis. Ante un intruso, se leerá el artículo 14 bis." |
| `arquero_aburrido` | "Termino a las seis. Apuntad bien." |
| `gran_roquefort` | Ver sección 8.2. |

---

## 7. Eventos de viaje y de taberna vinculados a la campaña

**Nivel de alcance (06 §5.1):** mínima, 1 evento (`t_bienvenida`); objetivo, 3 (+ `v_primer_viaje`, `t_registro_sube`, propuesta); el resto de las dos tablas es **(extra)**, contenido ampliable. Distintos de los eventos aleatorios genéricos (los cubre otro documento; 06 X-52: los eventos deterministas de este documento mandan sobre los aleatorios que los duplican). Estos son **deterministas**: tienen un gatillo y condiciones de estado, y ocurren una sola vez (`una_vez`), salvo los marcados como "periódico". Son hechos `evento_campana/5` (sección 10).

### 7.1 Eventos de viaje

| Id | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| `v_primer_viaje` **(objetivo)** | primer `ir/1` | `una_vez` | — (sale el consejo T7) | "El camino se pega a las botas. Ley de la Ruta Pegajosa: todo viaje dura un día." |
| `v_ganso_tasa` **(extra)** | llegar a `camino_real` | `una_vez`, `queso_min(15)`, sin `sello_real` | −2 quesos | "El Ganso Recaudador os tasa por 'riqueza visible'. Os da recibo. Tiene buena letra." |
| `v_pecorino_ronda` **(extra)** | llegar a `camino_real` | `una_vez`, `contratos_cumplidos_min(2)` | Aparece `caballo_fugado` en el tablón | "El Capitán Pecorino pasa de ronda. No os mira. Su caballo sí, con compasión." |
| `v_carta_de_clotilde` **(extra)** | llegar a `camino_real` | `una_vez`, `exito(gallina_noble)` | +1 queso (propina de la gallina) | "Una carta perfumada de Lady Clotilde: 'Habéis estado a la altura. Adjunto propina. No es costumbre.'" |
| `v_susurros_del_bosque` **(extra)** | primera llegada a `bosque` | `una_vez` | Aparece `paz_del_moho`; marca `penicilio_conocido` | "Las setas murmuran cuando pasáis. Una dice: 'Ahí vienen los del queso. Qué prisas'." |
| `v_gorgonzola` **(extra)** | llegar a `bosque` | `contrato_activo(caballo_fugado)` | Se activa el evento `calmar_caballo` | "Entre los árboles, un caballo mira con cara de haber leído vuestro expediente." |
| `v_eco_de_cuevas` **(extra)** | primera llegada a `cuevas` | `una_vez` | Si la moral media es < 5: moral −1 | "Vuestros pasos tardan en volver. Baldomero dice 'no tengo miedo' y la cueva se lo repite tres segundos después." |
| `v_pecorino_en_las_cuevas` **(extra)** | llegar a `cuevas` con `despensa_real` activo | `exito(caballo_fugado)` | +3 `parmesano` (si se comen, +2 de defensa en el siguiente combate) | "Pecorino aparece en la entrada con una bolsa. 'No es un regalo. Es un anticipo de una deuda que no existe.'" |
| `v_rancio_avanza` **(extra)** | pasar por el día 8, 14, 20 o 26 | periódico | +1 de edad al lote más curado de la despensa | "El pregonero anuncia que el Gran Rancio ya llega a la tercera planta del castillo. 'La cuarta, mañana, si hay suerte'." |

### 7.2 Eventos de taberna

| Id | Gatillo | Condiciones | Efecto | Texto |
|---|---|---|---|---|
| `t_bienvenida` **(mínima)** | inicio | `una_vez` | Escena de la sección 2.2 | — |
| `t_registro_sube` **(objetivo)** | llegar a `taberna` | cada 3 contratos cumplidos | Moral del grupo +1; el Registro sube de puesto (puesto en partida = `47 - contratos_cumplidos`, mínimo 41, fórmula de 05; 06 X-53) | "Doña Mantecosa borra la tiza con un trapo mojado y escribe vuestro nombre un poco más arriba. Con la misma errata." |
| `t_ensayo_de_rufino` **(extra)** | `descansar` | moral media < 5 y Rufino sin `silencio_pagado` | Se recupera solo la mitad de la vida (salvo `tapones_de_cera` o pagar 1 queso) | "Rufino ensaya 'La Balada del Queso Perdido' toda la noche. Nadie descansa. Nadie olvida la rima." |
| `t_tuerca_cuenta` **(extra)** | llegar a `taberna` | `una_vez`, `queso_min(20)` | Tuerca "encuentra" 2 quesos (+2) y la moral baja 1 (lo descubren) | "Tuerca cuenta los quesos dos veces y sonríe. Son dos más de los que había. Nadie pregunta. Pimentina frunce el ceño." |
| `t_hermanos_emmental` **(extra)** | llegar a `taberna` | `contratos_cumplidos_min(3)` | Aparece `pelea_de_taberna` | "Tres hermanos discuten quién perdió el queso por qué agujero. Doña Mantecosa os mira con intención." |
| `t_banquete` **(extra)** | llegar a `taberna` | `contrato_activo(despensa_real)`, `queso_min(8)` | Habilita la opción `elegir(banquete)` (arco P3) | "Pimentina hace sonar un cucharón: 'Nadie va a luchar con un queso al nivel de un lunes'." |

> **Eliminado: `t_mantecosa_cuenta`** (D-15). Dependía de una `deuda_taberna` ("cuenta de más de 5 quesos") que ningún documento define. Descansar cuesta 2 quesos; si no los hay falla `puede_descansar/0` y `por_que_no(descansar)` lo explica con la línea de Doña Mantecosa de la sección 6.1 ("Dos quesos la noche, jefe..."). El texto antiguo ("Con esa cuenta no se duerme") ya no existe.

---

## 8. Jefe final y finales

### 8.1 Secuencia del acto IV

1. **Llegada a las `cuevas`** (acto IV). **(mínima)** Sin eventos de campaña: se entra directamente a la cámara del jefe. **(extra)** Evento `v_eco_de_cuevas`; si Pecorino nos debe una, `v_pecorino_en_las_cuevas`.
2. **Entrada (extra).** Si no se ha hecho `reconocimiento_de_cuevas`, hay un encuentro forzado: 1 `murcielago_azul` + 1 `moho_saltarin`. Con `cuevas_despejadas`, se salta. En la mínima y el objetivo no existe este encuentro.
3. **Puerta interior (extra).** Con `llave_mohosa` se abre y se salta el gólem. Sin llave, combate contra el `golem_de_queso_duro` (40/10/6), que cada tercer turno `defender`. En la mínima y el objetivo no hay puerta interior.
4. **Cámara del Gran Roquefort.** **(objetivo)** se aplica la ventaja de `exito(fantasma_charlatan)` (−10 de vida del jefe). **(extra)** se disparan los gatillos de los arcos B3, R3 y T3.
5. **Diálogo previo** (ver 8.2) y combate. **Mínima:** una sola fase con la IA fija de 8.3. **Objetivo:** añade la fase "apurado". **Extra:** tres fases.
6. **Fin:** victoria o derrota y epílogo. **No se puede huir del jefe** (D-29).

### 8.2 Diálogos del jefe

**Antes del combate (mínima):**

> **Gran Roquefort:** "Pasad. No toquéis nada. ¿Tenéis prisa? La gente de hoy siempre tiene prisa."
> **Baldomero:** "Por orden del rey Brieto, vengo a pararos el moho."
> **Gran Roquefort:** "Yo no paro nada. Yo... afino."
> **Pimentina:** "Este queso está pasado de moda, querido."
> **Gran Roquefort:** "Todo mejora con el tiempo. Vosotros también. Os guardaré."

**Fase 2 (vida ≤ 30; objetivo):** "La prisa os ha contagiado. Qué lástima."

**Fase 3 (vida ≤ 10; extra):** "Cuarenta años madurando... y me interrumpís por una despensa."

**Victoria (mínima):** "Era... tan... curado..." (Se deshace en una nube azul.)

### 8.3 Estadísticas y mecánicas especiales

`gran_roquefort`: vida 60, ataque 11, defensa 4, fila `frente`, clase `queso_vivo`. **(objetivo)** con `exito(fantasma_charlatan)` empieza con vida 50. **(extra)** la regla original del lore exige además la `llave_mohosa`.

**IA (D-24, X-42).** La IA usa la prioridad del lore con el corte real del canon (06 X-04: `solve/2` implementa el corte; la gemela `accion_enemigo_sin_corte/2` sirve de oráculo). **Mínima:** las 4 reglas de 01 §6.2 más la invocación de moho; cada cláusula lleva su gemela. La cláusula `monologo`, los modificadores y el aura son propuestas **(extra)**. El jefe se identifica con una guarda `instancia(E, gran_roquefort)`, no con un átomo en el primer argumento (X-19: los enemigos son instancias `e(Tipo, N)`).

```prolog
% boceto sin ejecutar
% orden de prioridad: la primera cláusula que aplica decide

% --- MÍNIMA ---
accion_enemigo(E, esporas_curativas) :-                      % cura 8, una vez (el "curarse" del jefe)
    instancia(E, gran_roquefort),
    vida_baja(E), tiene(E, esporas), !.
accion_enemigo(E, invocar_moho) :-                           % máx. 2 veces
    instancia(E, gran_roquefort),
    \+ aliado_vivo(E, moho_saltarin),
    invocaciones(N), N < 2, !.
accion_enemigo(E, atacar(O)) :-                              % hay rancio en la despensa: va a por el de frente
    instancia(E, gran_roquefort),
    queso_rancio_en_despensa, frente(O), !.
accion_enemigo(E, atacar(O)) :-
    instancia(E, gran_roquefort),
    objetivo_mas_debil(E, O).

% --- OBJETIVO ---
% bonus +2 por rancio y fase "apurado" (vida <= 30)
modificador(E, _, 2) :- instancia(E, gran_roquefort), queso_rancio_en_despensa.
modificador(E, _, 1) :- instancia(E, gran_roquefort), vida(E, V), V =< 30.

% --- EXTRA ---
% cláusula monologo (iría la primera): cada 3ª ronda, salvo que Rufino esté cantando
accion_enemigo(E, monologo) :-
    instancia(E, gran_roquefort),
    ronda(R), R mod 3 =:= 0,
    \+ cantando(rufino), !.
modificador(E, _, 2) :-                                      % cantar en su ronda de monólogo le enfurece
    instancia(E, gran_roquefort), ronda(R), R mod 3 =:= 0, cantando(rufino).
% aura del rancio: al comenzar cada ronda envejece el mejor queso (efecto envejecer_lote(1))
al_inicio_de_ronda(E) :- instancia(E, gran_roquefort).
```

| Regla | Nivel | Efecto | Cómo se combate |
|---|---|---|---|
| `esporas_curativas` | mínima | Se cura 8 una vez al bajar a vida baja (≤ 25) | Concentrar daño en esa ronda; **(extra)** Tuerca puede quitárselas antes (arco T3) |
| `invocar_moho` | mínima | Invoca un `moho_saltarin` (hasta 2 veces) cuando no tiene ninguno vivo | Matar al moho rápido; **ojo**: lanzarle queso rancio lo cura 3 (`lanzar` es extra) |
| Objetivo "de frente" si hay rancio | mínima | Ataca al de frente (en vez de al más débil) si la despensa tiene queso rancio | Gastar el queso viejo antes del jefe |
| Bonus +2 por rancio | objetivo | Ataca con +2 si la despensa tiene queso rancio | Gastar el queso viejo antes del jefe |
| Fase "apurado" (vida ≤ 30) | objetivo | Ataque +1 y defensa −2 ("la prisa le sienta fatal") | Remata en esa fase; el daño sube |
| `monologo` | extra | Cada 3ª ronda pierde su acción, salvo que Rufino esté `cantando` (entonces se enfurece: +2 de ataque) | Mantener a Rufino callado en la 3ª, 6ª ronda; usar `silencio_pagado` |
| Aura del rancio | extra | Cada ronda envejece el lote más curado de la despensa | Pimentina gasta primero el más viejo; el queso rancio se puede lanzar a otros enemigos y potencia `fondue_flamigera` (+2) |

Con la ración **fresco → curado → rancio** (D-11), la despensa conserva rancio y estas reglas importan: ver 9.4. En la ruta ideal de las tablas de 9.2 la despensa del jefe llega sin rancio (los sueldos lo gastan antes), salvo que el jugador no pague o el `moho_saltarin` lo envejezca (+2 al lote más curado).

**Secuencia del combate:**

1. *Ronda 0:* diálogo previo. **(objetivo)** ventaja de `exito(fantasma_charlatan)`. **(extra)** se aplican los bonus de arcos y objetos (`parmesano`, `delantal_encantado`).
2. *Mínima, única fase:* el jefe invoca moho, se cura una vez y ataca. Objetivo: matar al moho, preparar el daño, tener el queso rancio fuera de la despensa.
3. *Objetivo, fase 2 (vida ≤ 30):* "apurado". Se arriesga más. Es la fase más peligrosa para Pimentina (defensa 1).
4. *Extra, fase 3 (vida ≤ 10):* diálogo y remate. Si se ha activado `balada_completa` y se cumplen las condiciones del final `madurado`, se ofrece `elegir(escuchar)` en vez de rematar.
5. *Fin:* se evalúa `final/2` (ver 8.4).

**Derrotas (D-17).** `caido` solo existe dentro del combate. Si todos los miembros quedan `caido` se produce `derrota_combate` (no hay retirada: del jefe no se huye, D-29). `derrota_hambre` no es de combate: se evalúa **al empezar el día**, si `queso_total = 0` y no hay nada por cobrar (ningún contrato `por_cobrar`); el hambre baja la moral y la vida pero nunca deja la vida por debajo de 1. Los textos están en 8.5. `derrota_plazo` es **(extra)**.

### 8.4 Reglas de los finales

Se evalúan en orden y se usa el primero que se cumpla (el estado es el de **al terminar el combate final**, antes de que los caídos se levanten; "en pie" = `en_pie/1`, activo y no en huelga). En la **mínima** solo existe `chapuza` como final de victoria:

```prolog
% boceto sin ejecutar
% MÍNIMA
orden_finales([chapuza]).
final(chapuza,  []).    % por defecto
% OBJETIVO: orden_finales([quiebra, leyenda, chapuza]).
final(quiebra,  [o([queso_total_max(4), moral_media_max(3), miembros_en_pie_max(2)])]).
final(leyenda,  [miembros_en_pie_min(4), contratos_exito_min(5), moral_media_min(6), queso_total_min(10)]).
% EXTRA: orden_finales([madurado, quiebra, leyenda, chapuza]); con los 15 contratos, leyenda pide contratos_exito_min(8)
final(madurado, [elegida(escuchar), exito(fantasma_charlatan), marcado(eustaquio_en_paz), activo(rufino)]).
```

Nota: con solo 5 contratos antes del jefe en el objetivo, `leyenda` no puede pedir los 8 éxitos del diseño original; se baja a 5 (todos). Con el catálogo completo vuelve a 8.

| Final | Nivel | Condiciones | Qué premia |
|---|---|---|---|
| **Chapuza de toda la vida** (`chapuza`) | mínima | Victoria sin cumplir ninguna de las otras | El camino normal |
| **Cuajados** (`derrota_combate`) | mínima | Todos los miembros `caido` en combate | — |
| **Sin ración** (`derrota_hambre`) | mínima | Al empezar el día, `queso_total = 0` y nada por cobrar | — |
| **Leyenda** (`leyenda`) | objetivo | 4 miembros en pie, 5 contratos con éxito (8 en la ampliada), moral media ≥ 6, queso ≥ 10 | La campaña bien llevada |
| **Victoria en quiebra** (`quiebra`) | objetivo | Queso ≤ 4, o moral media ≤ 3, o 2 o menos en pie | Ganar a duras penas |
| **El Gran Roquefort madura en paz** (`madurado`) | extra | Escuchar al jefe, Eustaquio en paz y Rufino activo | Quien cuidó el hilo del fantasma |
| **La despensa se vuelve abono** (`derrota_plazo`) | extra | Pasa el día 35 sin aceptar `despensa_real` (reloj narrativo) | — |

### 8.5 Textos de cierre

Niveles: `chapuza`, `derrota_combate` y `derrota_hambre` (mínima); `leyenda` y `quiebra` (objetivo); `madurado` y `derrota_plazo` (extra). **Puesto del Registro (06 X-53):** durante la partida el puesto sigue la fórmula de 05 (`47 - contratos_cumplidos`, mínimo 41); en el final, el puesto que dice el texto (12 en `leyenda`, 31 en `chapuza`) sustituye al cálculo.

**Final `leyenda` — "Leyenda del Queso Curado"** **(objetivo)**

> El Gran Roquefort se deshace en una nube azul y, por primera vez en cuarenta años, la cueva huele a sótano limpio. El rey Brieto os recibe con una ovación de cortesanos con la nariz tapada y os paga cuarenta quesos, de los buenos, en un solo plazo y a la vista de todos.
>
> El Registro de Compañías se actualiza con tiza nueva: la Banda Chapuza sube del puesto 47 al 12. La errata del nombre se queda; se ha convertido en marca registrada.
>
> Sir Baldomero cruza una plaza llena de caballos y solo se cambia de acera una vez. Rufino termina su balada. Pimentina abre un menú del día. Tuerca devuelve algo, sin que nadie le haya dicho qué.
>
> **Narrador:** "Os lo advertí: todo mejora con el tiempo. Salvo vosotros, que habéis mejorado con prisa."

**Final `chapuza` — "Chapuza de toda la vida"** **(mínima)**

> Ganáis. Más o menos. El Gran Roquefort cae, el moho retrocede y el rey os paga... en dos plazos: el primero, hoy; el segundo, "cuando la despensa se recupere", que es una forma de decir "nunca".
>
> El Registro os sube al puesto 31, con una nota a lápiz: "a confirmar". Baldomero jura que lo planeó todo. Rufino ya tiene la balada, con tres finales distintos, según el precio. Pimentina ha probado el moho y opina que le falta fondo.
>
> **Narrador:** "Un éxito rotundo, en el sentido de que rodó escaleras abajo y llegó."

**Final `quiebra` — "Victoria en quiebra"** **(objetivo)**

> El jefe cae. El reino se salva. La Banda, no. Entre sueldos atrasados, raciones perdidas y ánimos por el suelo, los números de Doña Mantecosa superan a la recompensa del rey, que además llega con retraso y en queso rancio.
>
> El Registro os tacha por "inactividad financiera". Rufino cobra por callar sobre lo ocurrido. Tuerca se queda con el resto. Baldomero acaba de guardia en un establo reformado, vigilado por un caballo que lo mira sin rencor.
>
> **Narrador:** "Salvar un reino no paga el alquiler. Tomad nota. Si os queda con qué."

**Final `madurado` — "El Gran Roquefort madura en paz"** **(extra)**

> Rufino canta, por fin, la balada entera. Roque de Fort escucha, en silencio, hasta el último verso. Cuando acaba, suspira como quien lleva cuarenta años conteniéndolo: "Mi mayordomo... ¿cenó bien?". Eustaquio, desde algún sitio, dice que sí.
>
> El Gran Roquefort acepta un retiro: una cava privada bajo el castillo, sin moho que contagiar y con visitas los domingos. El Gran Rancio se detiene. El rey paga el doble y firma un papel que no entiende.
>
> **Narrador:** "A veces el mejor golpe es esperar a que alguien acabe su frase."

**Derrotas** (D-17: `derrota_combate` y `derrota_hambre` son de la mínima; `derrota_plazo` es extra)

- `derrota_combate` **(mínima)** — "Cuajados": "El moho avanza. Una a una, las cuatro botas se quedan pegadas al suelo de la cueva. Doña Mantecosa añade vuestro nombre al tablón de incobrables. Narrador: 'Intentadlo de nuevo, esta vez con más queso y menos honor.'"
- `derrota_hambre` **(mínima)** — "Sin ración": "No quedan quesos, ni ánimo, ni puntos de apoyo. La Banda se disuelve entre bostezos. Narrador: 'Un mercenario sin queso es un caballero sin caballo. Con la salvedad de que Baldomero lo prefiere.'"
- `derrota_plazo` **(extra)** — "La despensa se vuelve abono": "El día 35, la despensa del rey se convierte en abono. Los cortesanos plantan rosales."

---

## 9. Curva de dificultad y economía

### 9.1 Supuestos numéricos

Recalculados el 2 de noviembre de 2026 con un script de simulación (fuera del repositorio) que aplica las reglas de abajo día a día, con la despensa guardada **por edades** para ver qué categoría se come y se paga en cada momento. El script reproduce exactamente los saldos de la versión anterior de la tabla (con las mismas reglas de entrada) antes de aplicar los cambios de la revisión.

| Concepto | Valor asumido | Fuente |
|---|---|---|
| Quesos iniciales | 12 `cheddar`, edad 0 | Lore 11.1, D-09 |
| Miembros | 4 | Canon |
| Orden al pasar el día | 1) maduración (+1 de edad a todo), 2) ración, 3) botín del combate, 4) al llegar a la taberna: cobro automático de contratos y, solo si el jugador escribe `pagar`, sueldos | 02 §5.5, D-14 |
| Ración | 1 queso por miembro y día (4 al día). Se come **fresco → curado → rancio**; dentro de cada categoría, el más viejo primero (supuesto de la revisión) | D-11, X-28, 02 §5.5 |
| Gastos (sueldos, descanso, multas) | Se paga con lo **más rancio primero** | Lore 7.1, X-03 (`perder_queso`) |
| Hambre | −1 moral y −2 vida por miembro sin comer; la vida **nunca baja de 1** | Doc. 03 F-09, D-17 |
| Comer rancio | −2 de moral a quien lo come | Supuesto anterior, conservado |
| Sueldos | 5 quesos por pago (1+2+1+1); comando `pagar` en la taberna. Si se sale con sueldos pendientes: −2 de moral por miembro | D-14, lore 11.2 |
| Huelga | Derivada solo de la moral: moral ≤ 2 | D-08, X-25 |
| Descansar | 1 día + 2 quesos; recupera toda la vida y +1 moral; sin `deuda_taberna` | D-15 |
| Banquete (arco P3, extra) | 6 quesos adicionales a un descanso | Sección 5.3 |
| Botín por combate | +1 `cheddar` fresco por cada enemigo con `lleva_queso` derrotado (`bandido_torpe`, `bandido_montado`, `ganso_recaudador`, `arquero_aburrido`) | Lore 6.1 |
| Moral | +1 por contrato con éxito; 0 a 10 | Supuesto |
| Compra y venta | Ninguna: el queso no se compra ni se vende y no hay tienda en la versión 1 | D-10, X-33 |
| Todas las cantidades | **unidades** de queso, no valor | D-13 |

**Nota sobre el pago por valor** (lore 11.5, propuesta 01-5): no se adopta (D-13, X-32). Un `cheddar` curado vale 4 y uno fresco 2, pero ninguna decisión del jugador depende de ello en la versión 1: sueldos, recompensas y multas se cuentan en unidades. El valor por tipo sirve para mostrar y para los precios de la tienda de objetos (extra), donde se pagaría antes lo más rancio.

**Ajuste de recompensas derivado del recálculo.** Con la versión anterior de las recompensas (`ratas_del_granero` 7, `gato_en_el_arbol` 5, `gallina_noble` 12 + `brie`), la **ruta mínima** (4 contratos) no cerraba: el día 6 quedaban 2 quesos para una ración de 4, dos miembros pasaban hambre el día 7 y se llegaba al jefe con 0 quesos. La causa es estructural: cada día cuesta 4 de comida, la escolta exige 6 desplazamientos después del primer cobro (24 quesos) y solo hay 4 contratos. Se ajustan a **9, 7 y 14 + `brie`** (+6 en total; ratas y gato además dan `pocion` y venda), con lo que la mínima llega al jefe con 4 quesos (9 si se omite un pago de sueldos). Es un ajuste **provisional** hasta el balance de la semana 6 y habrá que propagarlo a las fichas de 01 §5.1 (pendiente de decisión del autor).

### 9.2 Tablas día a día por ruta

Notación: *Cobros* = recompensas cobradas en la taberna; *Botín* = quesos conseguidos en combate; *Otros* = descanso (2 quesos) y banquete (6). *Saldo* = quesos en la despensa al final del día. *Despensa* = unidades frescas / curadas / ranciosas al final del día (ración fresco → curado → rancio, D-11). Solo se cobra y se pagan sueldos en los días en que el lugar es `taberna` y hay cifra en esas columnas. En todas las rutas ideales se acepta `despensa_real` en el castillo, donde ya se cuentan 3 contratos cumplidos aunque el último aún no se haya cobrado (`contrato_cumplido/1` mira `contrato_por_cobrar/2` y `contrato_cerrado/2`).

**Ruta mínima (mínima): 4 contratos, jefe el día 9** — saldo al jefe: **4** (9 si se omite el pago del día 7); sin hambre; nunca hay rancio.

| Día | Lugar | Cobros | Botín | Comida | Sueldos | Otros | Saldo | Despensa (fresco/curado/rancio) | Qué ocurre |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `taberna` | 0 | 0 | 0 | 0 | 0 | 12 | 12/0/0 | Escena inicial; acepta `ratas_del_granero` y `gato_en_el_arbol` |
| 2 | `aldea` | 0 | 0 | 4 | 0 | 0 | 8 | 8/0/0 | Ratas y gato resueltos |
| 3 | `taberna` | 16 | 0 | 4 | 5 | 0 | 15 | 15/0/0 | Cobra 9+7 (y la `pocion`); `pagar`; acepta `gallina_noble` (ya con la venda) |
| 4 | `camino_real` | 0 | 2 | 4 | 0 | 0 | 13 | 13/0/0 | Emboscada de 2 `bandido_torpe` (botín 2) |
| 5 | `castillo` | 0 | 1 | 4 | 0 | 0 | 10 | 10/0/0 | `bandido_montado` (botín 1); Clotilde entregada; audiencia; acepta `despensa_real` |
| 6 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 6 | 0/6/0 | Regreso (el punto más bajo de la ruta) |
| 7 | `taberna` | 15 | 0 | 4 | 5 | 0 | 12 | 12/0/0 | Cobra 14 + 1 `brie`; `pagar` |
| 8 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 8 | 8/0/0 | Salida hacia el jefe |
| 9 | `cuevas` | 0 | 0 | 4 | 0 | 0 | 4 | 4/0/0 | **Jefe** |
| **Total** | | **31** | **3** | **32** | **10** | **0** | | | 12 + 31 + 3 − 32 − 10 − 0 = 4 |

**Ruta objetivo (objetivo): 6 contratos, jefe el día 9** — saldo al jefe: **23**; sin hambre; el valle es de 16 el día 6.

| Día | Lugar | Cobros | Botín | Comida | Sueldos | Otros | Saldo | Despensa (fresco/curado/rancio) | Qué ocurre |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `taberna` | 0 | 0 | 0 | 0 | 0 | 12 | 12/0/0 | Escena inicial; acepta ratas, gato y fantasma |
| 2 | `aldea` | 0 | 0 | 4 | 0 | 0 | 8 | 8/0/0 | Ratas, gato y fantasma (3 capítulos) |
| 3 | `taberna` | 24 | 0 | 4 | 5 | 0 | 23 | 23/0/0 | Cobra 9+7+8; `pagar`; acepta `peaje_del_ganso` y `gallina_noble` |
| 4 | `camino_real` | 0 | 4 | 4 | 0 | 0 | 23 | 23/0/0 | Peaje (ganso y bandido) y emboscada (2 bandidos): botín 4 |
| 5 | `castillo` | 0 | 1 | 4 | 0 | 0 | 20 | 20/0/0 | `bandido_montado` (botín 1); audiencia; acepta `despensa_real` |
| 6 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 16 | 1/15/0 | Regreso (el punto más bajo) |
| 7 | `taberna` | 24 | 0 | 4 | 5 | 0 | 31 | 24/7/0 | Cobra 9 + 14 + 1 `brie`; `pagar` |
| 8 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 27 | 20/7/0 | Salida hacia el jefe |
| 9 | `cuevas` | 0 | 0 | 4 | 0 | 0 | 23 | 16/7/0 | **Jefe** |
| **Total** | | **48** | **5** | **32** | **10** | **0** | | | 12 + 48 + 5 − 32 − 10 − 0 = 23 |

**Ruta ampliada (extra, contenido ampliable): 13 de los 15 contratos, jefe el día 26** — saldo al jefe: **19**; sin hambre. No se tabulan `cena_de_eustaquio` ni `pelea_de_taberna` (la versión anterior hablaba de "15 contratos" por error: la ruta tabulada tenía 12 contratos y el jefe, 06 X-35b). Los 3 `queso_silvestre` del contrato de Ricota se guardan aparte y no cuentan en la despensa. No se ha simulado el reloj narrativo `v_rancio_avanza` (extra).

| Día | Lugar | Cobros | Botín | Comida | Sueldos | Otros | Saldo | Despensa (fresco/curado/rancio) | Qué ocurre |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `taberna` | 0 | 0 | 0 | 0 | 0 | 12 | 12/0/0 | Acepta ratas, gato y fantasma |
| 2 | `aldea` | 0 | 0 | 4 | 0 | 0 | 8 | 8/0/0 | Ratas, gato y fantasma (3 contratos) |
| 3 | `taberna` | 24 | 0 | 4 | 5 | 0 | 23 | 23/0/0 | Cobra 9+7+8; recibe la venda |
| 4 | `camino_real` | 0 | 4 | 4 | 0 | 0 | 23 | 23/0/0 | Peaje y emboscada (botín 4) |
| 5 | `castillo` | 0 | 1 | 4 | 0 | 0 | 20 | 20/0/0 | Gallina entregada; audiencia; degustador |
| 6 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 16 | 1/15/0 | Regreso (el punto más bajo temprano) |
| 7 | `taberna` | 36 | 0 | 4 | 5 | 0 | 43 | 36/7/0 | Cobra 9+15+12; cucharón |
| 8 | `taberna` | 0 | 0 | 4 | 0 | 2 | 37 | 32/5/0 | Descansa |
| 9 | `aldea` | 0 | 0 | 4 | 0 | 0 | 33 | 28/5/0 | Paso |
| 10 | `bosque` | 0 | 2 | 4 | 0 | 0 | 31 | 2/29/0 | Silvestre (hasta 3), paz del moho, caballo |
| 11 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 27 | 0/27/0 | Devuelve a Gorgonzola |
| 12 | `taberna` | 21 | 0 | 4 | 5 | 0 | 39 | 21/18/0 | Cobra 12+9; estoque, salmuera |
| 13 | `aldea` | 0 | 0 | 4 | 0 | 0 | 35 | 17/18/0 | Entrega silvestre curado (3 días) |
| 14 | `taberna` | 10 | 0 | 4 | 5 | 0 | 36 | 23/13/0 | Cobra silvestre; bastón |
| 15 | `camino_real` | 0 | 2 | 4 | 0 | 0 | 34 | 8/26/0 | Correo |
| 16 | `castillo` | 0 | 1 | 4 | 0 | 0 | 31 | 5/26/0 | Inspección del manual; acepta `despensa_real` |
| 17 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 27 | 0/14/13 | Regreso |
| 18 | `taberna` | 28 | 0 | 4 | 5 | 0 | 46 | 28/10/8 | Cobra 12+16; coraza |
| 19 | `taberna` | 0 | 0 | 4 | 0 | 2 | 40 | 24/10/6 | Descansa |
| 20 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 36 | 20/10/6 | Acepta el reconocimiento |
| 21 | `cuevas` | 0 | 0 | 4 | 0 | 0 | 32 | 0/26/6 | Reconocimiento |
| 22 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 28 | 0/18/10 | Regreso |
| 23 | `taberna` | 20 | 0 | 4 | 5 | 0 | 39 | 20/14/5 | Cobra 18+2 roquefort; ganzúa |
| 24 | `taberna` | 0 | 0 | 4 | 0 | 8 | 27 | 16/11/0 | Descansa y banquete (2+6) |
| 25 | `camino_real` | 0 | 0 | 4 | 0 | 0 | 23 | 12/11/0 | Salida hacia el jefe |
| 26 | `cuevas` | 0 | 0 | 4 | 0 | 0 | 19 | 0/19/0 | **Jefe** |
| **Total** | | **139** | **10** | **100** | **30** | **12** | | | 12 + 139 + 10 − 100 − 30 − 12 = 19 |

Cambios respecto a la tabla anterior: las recompensas de ratas, gato y gallina suben (+6), lo que eleva todos los saldos posteriores en 6 (el saldo final pasa de 12 a 19, con +1 de botín); el botín del día 4 pasa de 3 a 4 (peaje: ganso y bandido, 2; emboscada: 2 bandidos, 2); y la columna *Despensa* es nueva.

### 9.3 Otras rutas (misma lógica de cálculo)

| Ruta | Nivel | Días | Contratos | Saldo al llegar al jefe | Equipo | Valoración |
|---|---|---|---|---|---|---|
| Mínima (se paga siempre) | mínima | 9 | 3 + jefe | **4** | `venda_de_caballos`, `pocion` | Sin hambre, pero con margen de 2 quesos antes del día 7 y de 4 al llegar. Muy justa. |
| Mínima, sin pagar el día 7 | mínima | 9 | 3 + jefe | **9** | igual | Cuesta −2 de moral por miembro al salir; deja queso para los hechizos de Pimentina. |
| Mínima con descanso el día 8 (pagando) | mínima | 10 | 3 + jefe | 0 | igual | **Hambre**: dos miembros sin ración el día 10. No recomendable. |
| Mínima con descanso el día 8, sin pagar el día 7 | mínima | 10 | 3 + jefe | **3** | igual | Se llega curado pero casi sin queso. |
| Objetivo | objetivo | 9 | 5 + jefe | **23** | + `cucharon_de_hierro`, `sello_real` | Sobra margen: se puede descansar antes del jefe. |
| Objetivo con descanso el día 8 | objetivo | 10 | 5 + jefe | **17** | igual | Llegar curado cuesta 6 quesos (2 + 4 de la ración del día extra). |
| Recomendada (extra) | extra | 21 | 11 + jefe | **32** | + estoque, coraza, bastón, salmuera | El jefe es peleable con buen manejo. |
| Ampliada (extra) | extra | 26 | 12 + jefe | **19** | + ganzúa, trébol, 2 roquefort | Más equipo, más días de comida. |

### 9.4 Lo que enseña la economía

1. **Cada día cuesta algo más de 5 quesos** (4 de comida y 5 de sueldos cada 2 o 3 días; en la ruta ampliada, 130 en 26 días). La mayoría de los contratos rinden entre 7 y 18. Un contrato de 9 que cuesta 2 días de viaje (8 de comida) apenas compensa: hay que agrupar por zona. La ruta mínima lo ilustra: la aldea rinde 16 por dos días de viaje, pero la escolta de Clotilde obliga a 6 desplazamientos más (24 quesos) para cobrar 15.
2. **El valle del día 6** es el momento de máxima tensión sin gestión: **6 quesos** en la ruta mínima (la ración del día 7 son 4, así que solo hay 2 de margen; basta con que las ratas se lleven 3 para que un miembro se quede sin comer), 16 en la objetivo y en la ampliada. Un solo mal pago de sueldos o una pelea de más lo empuja a la huelga.
3. **Los sueldos son una trampa deliberada:** `pagar` es un comando opcional (D-14), pero cada salida de la taberna con sueldos pendientes baja 2 la moral de cada miembro; a la segunda salida seguida sin éxitos de por medio (moral 2) hay huelga y el combate se acaba. En la ruta mínima, omitir el pago del día 7 deja 5 quesos más en la despensa a costa de 2 de moral.
4. **El queso se pudre, y la ración fresco → curado → rancio (D-11) lo mantiene vivo.** Con "se come primero lo más viejo", el rancio no llegaba a existir (en la ruta ampliada, 0 unidades ranciosas durante toda la partida). Con la ración nueva se come primero lo fresco, así que las reservas viejas se acumulan: el lote cobrado el día 7 llega a rancio el día 17, cuando la despensa tiene **13 unidades ranciosas** (de 27). El rancio no se come mientras haya otra cosa, y los gastos se pagan con lo más rancio, así que el pago de sueldos del día 18 retira 5 y quedan 8, el descanso del día 19 retira 2 y quedan 6; el día 22 vuelve a haber 10; el día 23 los sueldos retiran 5 más y el descanso con banquete del día 24 agota el resto. Mientras duran, el rancio sirve para el bono +2 del jefe (objetivo), la curación del moho, `fondue_flamigera` con rancio y `lanzar` (extra). Consecuencia: el jugador que quiere evitar el bono del jefe debe gastar el viejo antes (sueldos, descanso); el que acapara paga el precio. En la ruta mínima no hay rancio (la edad máxima es 8); en la objetivo tampoco.
5. **Margen de error realista:** la tabla es la ruta ideal sin fallos. Un jugador típico pierde 15–25 quesos en la ruta ampliada (ratas que roban, moho que envejece, descansos de más, un contrato fallido). Con eso llega al jefe con 0–10 quesos y debe elegir: ¿cena de despedida (6) o fondue (1 por hechizo)? Es la decisión que se quiere. En la ruta mínima el margen es mucho menor (4 quesos al llegar): cualquier pérdida de más de 2 antes del día 7 se traduce en hambre, y la mínima admite como válvula omitir un pago de sueldos.

### 9.5 Rutas degeneradas (para la lista de pruebas del documento 03, sección 8.2)

| Ruta | Qué ocurre según estas reglas |
|---|---|
| Nunca pagar sueldos | Sin éxitos de por medio, moral 6 → 4 (1ª salida sin pagar) → 2 (2ª): huelga. Sin combate, no se llega al jefe. Termina en `derrota_hambre` cuando el queso es 0 y no hay nada por cobrar. |
| Ignorar la comida | −1 moral y −2 vida por miembro y día sin comer; la vida se queda en 1 (nunca `caido` por hambre), la moral cae hasta la huelga y, con queso 0 y nada por cobrar al empezar el día, `derrota_hambre`. |
| Aceptar contratos sin condiciones | `por_que_no` los explica. Es la ruta "pedagógica". |
| Ir al jefe el día 2 | `despensa_real` rechazada (3 contratos, castillo, moral); `por_que_no` muestra qué falta. |
| Intentar `huir` ante el jefe | Rechazado: no se puede huir de un jefe (D-29); `por_que_no(huir)` lo explica. |
| Hacerlo todo en el orden de la tabla | Mínima: final `chapuza`. Objetivo: final `leyenda` si se mantiene moral ≥ 6, 4 en pie y queso ≥ 10 al terminar. |

### 9.6 Curva de dificultad (combate)

Estimación a mano con el daño base `max(1, Atq − Def + M)` y los datos del lore; se recalcula con el motor real en la semana 6. Niveles: los combates de aldea, camino con `bandido_torpe` y `bandido_montado`, y el jefe son de la mínima; el ganso es del objetivo; bosque, castillo y cuevas con sus enemigos son **(extra)**.

| Tramo | Combates típicos | Daño del grupo por ronda (aprox.) | Rondas | Riesgo |
|---|---|---|---|---|
| Acto I (aldea) | 2 `rata_quesera` (8 vida) | B 11 + T 7 + P 6 = 24 | 1 | Casi nulo. Tutorial |
| Acto II (camino) | 2 `bandido_torpe` (12/2) + ganso (16/2) | B 9 + T 5 + P 8 (fondue) + R 2 = 24 | 1–2 | Bajo. `bandido_montado` (18/3): B con venda hace 5; el grupo hace ≈ 18 por ronda |
| Acto II (bosque) | `seta_chismosa` (curación), `moho_saltarin` | ≈ 20 | 2 | Bajo-medio: gestión de filas y maduración |
| Acto III (castillo) | 2 `guardia_de_corteza` (28/7), 1 `arquero_aburrido` | B 4 + T 1 + P 8 + R 1 = 14 (con estoque +4: 18) | 3–4 | **Medio-alto**: obliga a usar fondue y equipo |
| Acto III (cuevas) | 2 `murcielago_azul`, `golem_de_queso_duro` (40/6) | ≈ 15–19 | 3 | Medio-alto: retaguardia y rondas largas |
| Acto IV (jefe) | `gran_roquefort` (60/4) + moho | B 7 (11 con estoque) + P 8–10 + T 3 + R 1 = ≈ 20 | 4–5 | **Alto** (5/5): ≈ 9 de daño al grupo por ronda más moho; se esperan 1–2 miembros caídos |

El poder del grupo crece **solo con equipo** (no hay experiencia). En la mínima el equipo se reduce a la `venda_de_caballos` (día 3) y la `pocion`; el resto de la lista es el equipo del objetivo y del contenido ampliable: `venda_de_caballos` (día 3), `cucharon_de_hierro` (7), `estoque_de_parmesano` (12), `baston_de_queso_duro` (14), `coraza_de_corteza` (18), `ganzua_de_oro` (23). Cada contrato secundario es un escalón de equipo, por eso el jefe es mucho más llevadero con la ruta recomendada.

---

## 10. Formato de datos

Todo es **boceto sin ejecutar**. Los textos van en átomos entre comillas simples y sin apóstrofos (SWI-Prolog 5.10.4: nada de comillas dobles ni `yall`). Las condiciones son términos que interpreta `contratos:condicion_cumple/1`; los efectos, términos que se traducen **una sola vez** al vocabulario único de 02 §4.5 (D-05, X-03) y se aplican con `estado:aplicar_efectos/1`, para que el meta-intérprete pueda mostrar la prueba. Se usan los nombres canónicos de 06 §2.7 (D-16): `puede_aceptar/1`, `condicion_cumple/1`, `resolucion/3` (datos) y `resultado/3` (regla), `activo/1`, `en_pie/1`, `lleva/3`, `equipado/2`.

### 10.1 Contratos

```prolog
% contrato(Id, Zona, Objetivo, recompensa(Lista), Condiciones)       % forma del canon, aridad 5
contrato(gallina_noble, camino_real, escoltar(gallina_noble, castillo),
         recompensa([quesos(14), queso(brie, 0, 1)]),
         [requiere(rasgo_no(teme_caballos))]).

oferente(gallina_noble, gallina_noble, camino_real).     % oferente(Contrato, Npc, ZonaDelNpc)
aparece(gallina_noble, []).                              % aparece(Contrato, Condiciones de visibilidad)
tipo_contrato(gallina_noble, minima).                    % minima | objetivo | extra  (antes nucleo | secundario | extra)
dificultad(gallina_noble, 3).
enemigos_de(gallina_noble, [bandido_torpe, bandido_torpe, bandido_montado]).
reintentable(gallina_noble, 3).                          % dias hasta reaparecer tras un fracaso
reintentable(gato_en_el_arbol, 2).

% via_objetivo(+Contrato, -Via): cómo se cumple el objetivo (02 §3.5); vocabulario cerrado de 3.1
via_objetivo(C, combate(Grupo)) :- contrato(C, _, eliminar(Pares), _, _), expandir_grupo(Pares, Grupo).   % minima
via_objetivo(C, combate([Tipo])) :- contrato(C, _, derrotar(Tipo), _, _).                                 % minima
via_objetivo(C, combate(Grupo))  :- contrato(C, _, escoltar(_, _), _, _), enemigos_de(C, Grupo).          % minima
via_objetivo(C, evento(E))       :- contrato(C, _, evento(E), _, _).                                      % minima
via_objetivo(C, evento(escuchar(Npc))) :- contrato(C, _, escuchar(Npc, _), _, _).                         % objetivo
% reunir/3 y recuperar/1 (extra): evento(...), el segundo con el combate de enemigos_de/2

% resolucion(Contrato, Resultado, Condiciones): se prueban en este orden
resolucion(gallina_noble, exito,    [contador_max(golpes_a_clotilde, 2)]).    % objetivo: y \+ cantando(rufino)
resolucion(gallina_noble, a_medias, [contador_max(golpes_a_clotilde, 4)]).    % objetivo: o cantando(rufino)
resolucion(gallina_noble, fracaso,  []).

% resultado/3 (regla pura, sin corte): el primer resultado cuyas condiciones se cumplen
resultado(C, Contexto, Res) :-
    findall(R-Cs, resolucion(C, R, Cs), Lista),
    primero_que_cumple(Lista, Contexto, Res).
primero_que_cumple([R-Cs | _], Ctx, R) :- cumple_todas(Cs, Ctx).
primero_que_cumple([_-Cs | Resto], Ctx, R) :- \+ cumple_todas(Cs, Ctx), primero_que_cumple(Resto, Ctx, R).
% Contexto (X-39): los contadores registrados durante el contrato (contador/2); en la minima solo
% quesos_robados (ratas) y golpes_a_clotilde (gallina)

% consecuencia(Contrato, Resultado, Efectos04): se traducen a efectos de 02 con expandir/3 (10.5)
consecuencia(gallina_noble, exito,    [cobrar(todo), moral(grupo, 1), marcar(recomendada_por_clotilde)]).
consecuencia(gallina_noble, a_medias, [cobrar(mitad), marcar(recomendada_por_clotilde)]).
consecuencia(gallina_noble, fracaso,  [perder_queso(3), moral(grupo, -2)]).
consecuencia(gato_en_el_arbol, exito, [cobrar(todo), moral(grupo, 1), equipar(baldomero, venda_de_caballos)]).
```

**Condiciones y aceptación** (recursivas, para que el meta-intérprete las recorra sin `forall/2`; sin `once/1` ni corte, X-56):

```prolog
puede_aceptar(C) :-
    contrato(C, _, _, _, Conds), \+ contrato_cumplido(C), \+ contrato_activo(C),
    contratos_activos(K), parametro(max_contratos, M), K < M,
    cumple_todas(Conds).

cumple_todas([]).
cumple_todas([requiere(X) | R]) :- condicion_cumple(X), cumple_todas(R).

condicion_cumple(rasgo_no(R))                :- \+ ( activo(M), rasgo(M, R), \+ ignora_miedo(M) ).    % D-19
condicion_cumple(contratos_cumplidos_min(N)) :- contratos_cumplidos(K), K >= N.
condicion_cumple(moral_media_min(N))         :- moral_media(M), M >= N.
condicion_cumple(visita(Z))                  :- visitada(Z).
condicion_cumple(miembros_en_pie_min(N))     :- findall(P, en_pie(P), L), length(L, K), K >= N.
condicion_cumple(exito(C))                   :- contrato_exito(C).                                    % objetivo
condicion_cumple(hecho(C))                   :- contrato_cumplido(C).                                 % extra
condicion_cumple(activo(P))                  :- activo(P).                                            % extra
condicion_cumple(queso_min(N))               :- queso_total(Q), Q >= N.                               % extra
condicion_cumple(objeto(O))                  :- lleva(compania, O, K), K > 0.                         % extra

% derivados (X-18): cumplido = resuelto con exito o a_medias, este o no cobrado
contrato_cumplido(C)   :- contrato_por_cobrar(C, R), R \== fracaso.
contrato_cumplido(C)   :- contrato_cerrado(C, R), R \== fracaso.
contrato_exito(C)      :- contrato_por_cobrar(C, exito).
contrato_exito(C)      :- contrato_cerrado(C, exito).
contratos_cumplidos(N) :- findall(C, contrato_cumplido(C), L), length(L, N).

% el miedo a los caballos usa la misma regla para el contrato y para el combate (X-37, D-19)
ignora_miedo(P) :- equipado(P, venda_de_caballos).
teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A).
```

### 10.2 Diálogos

```prolog
% dialogo(Npc, Tema, Texto)    -- en la minima los textos pueden quedar inline; despues, almacen unico frase/3 (X-07, D-27)
dialogo(mantecosa,        saludo,   'Bienvenidos al Cuajo Torcido. La puerta se cierra sola: forma parte del servicio.').
dialogo(alcaldesa_nata,   oferta(ratas_del_granero), 'Las ratas llevan en el granero desde antes de que se fundase la aldea. Dicen que tienen papeles.').
dialogo(capitan_pecorino, rechazo(contratos_cumplidos_min(2)), 'No contrato a quien aun no ha roto nada importante. Todavia.').   % extra
dialogo(rey_brieto,       despedida, 'Id con el queso. O sin el. Pero id.').

% el rechazo usa la primera condición que falla (la misma que explica por_que_no)
rechazo_de(Npc, C, Texto) :-
    contrato(C, _, _, _, Conds), primera_que_falla(Conds, Cond),
    dialogo(Npc, rechazo(Cond), Texto).
```

### 10.3 Arcos, eventos, actos y finales

```prolog
% arco(Personaje, Paso, Gatillo, Condiciones, Efectos04, Texto)         % objetivo: B1 y R1; el resto, extra
arco(baldomero, 2, tras_combate, [cuenta_min(ataques_a_caballo, 1), objeto(venda_de_caballos)],
     [moral(baldomero, 2), marcar(baldomero_perdona)],
     'No era rencor... era hambre. Lo entiendo ahora.').

% evento_campana(Id, Gatillo, Condiciones, Efectos04, Texto)             % minima: t_bienvenida; el resto, objetivo/extra
evento_campana(v_ganso_tasa, al_llegar(camino_real),
               [una_vez, queso_min(15), \+ objeto(sello_real)],
               [perder_queso(2)],
               'El Ganso Recaudador os tasa por riqueza visible. Os da recibo. Tiene buena letra.').

% final(Id, Condiciones) y texto_final(Id, Lineas)   (8.4)
final(chapuza, []).                                                  % minima
final(leyenda, [miembros_en_pie_min(4), contratos_exito_min(5), moral_media_min(6), queso_total_min(10)]).   % objetivo
texto_final(leyenda, ['El Gran Roquefort se deshace en una nube azul...',
                      'La Banda Chapuza sube del puesto 47 al 12.']).
```

### 10.4 Convenciones

- Todos los `Id` son ASCII en `snake_case`; los textos, ASCII o UTF-8 sin comillas dobles.
- Los efectos nunca llaman a `assert`/`retract` directamente: se traducen con `expandir/3` y los aplica `estado:aplicar_efectos/1`, **único** módulo que escribe en la base de datos (D-04, X-01). Los `actualizar_*` del documento 03 son auxiliares privados de `estado`.
- Los comandos nuevos de este documento son solo `elegir(Opcion)`, `pagar` y `demo` (D-20). `escuchar`, `catar`, `recoger` y `banquete` son **opciones de `elegir/1`** que existen mientras haya un evento abierto (`juego:ejecutar/2` valida la fase y el evento). `pagar` solo es válido en la taberna y su meta explicable es `puede_pagar_sueldos/0`.
- Todos los comandos son términos que valida y ejecuta `juego:ejecutar/2` (D-03): `explicar(...)` y `por_que_no(...)` se traducen con `objetivo_de_accion/2`; no son predicados invocables.
- El texto visible de los datos de este documento puede asociarse al almacén único de frases (`frase/3`, claves `texto(dialogo(Npc, Tema))`, `texto(final(Id))`, `texto(consejo(Id))`) sin tocar la lógica (X-07, D-27; puede esperar a la semana 4).
- Cantidades de queso en **unidades** (D-13).

### 10.5 Traducción de efectos al vocabulario de 02 §4.5 (D-05, X-03)

Los datos de este documento usan términos de alto nivel (`Efectos04`); `contratos:expandir/3` (o `eventos:expandir/3`) los traduce, con el contrato `C` como contexto, a los efectos que sabe aplicar `estado:aplicar_efecto/1`:

| Término de este documento | Efecto(s) de 02 §4.5 | Nota |
|---|---|---|
| `cobrar(todo)` | `contrato_cobrar(C)` | Suma la recompensa completa: `ganar_queso(cheddar, 0, N)`, `ganar_queso(T, E, N)` y `ganar_objeto(compania, O, 1)`. |
| `cobrar(mitad)` | `contrato_cobrar(C, mitad)` | **Variante nueva** `contrato_cobrar/2` (a añadir a 02 §4.5): la mitad de los quesos, sin objetos. |
| `perder_queso(N)` | `gastar_queso(T, E, K)` por lote | Se toma del más rancio (gastos, 9.1). |
| `moral(grupo, N)` | un `mod_moral(Id, N)` por miembro activo | |
| `moral(Id, N)` | `mod_moral(Id, N)` | |
| `vida(Id, N)` | `dano(Id, -N)` / `curar(Id, N)` | |
| `marcar(F)` | `marcar(F)` | **Nuevo** (hecho dinámico `marca/1`). |
| `mejora(Hab, Atrib, N)` | `marcar(mejora(Hab, Atrib, N))` | `combate:efecto_habilidad/2` lee la marca (arco P2, extra). |
| `descansos_gratis(N)` | `ganar_descansos(N)` | **Nuevo** (extra). |
| `envejecer_lote_mas_curado(N)` | `envejecer_lote(N)` | **Nuevo** (extra: aura del jefe, `v_rancio_avanza`). |
| `equipar(Id, O)` | `equipar(Id, O)` | **Nuevo** (hecho `equipado/2`). |
| contadores (`quesos_robados`, `golpes_a_clotilde`...) | `contar(Clave, N)` | **Nuevo** (hecho `contador/2`). |
| `quesos(N)` en `recompensa` | `ganar_queso(cheddar, 0, N)` | |
| `queso(T, E, N)` en `recompensa` | `ganar_queso(T, E, N)` | |
| `objeto(O)` en `recompensa` | `ganar_objeto(compania, O, 1)` | |
| ciclo del contrato | `contrato_aceptar(C)`, `contrato_resolver(C, R)` | Ya en 02. |

```prolog
% contratos.pl (boceto sin ejecutar)
expandir(C, cobrar(todo),   [contrato_cobrar(C)]).
expandir(C, cobrar(mitad),  [contrato_cobrar(C, mitad)]).
expandir(_, moral(grupo, N), Efs) :- findall(mod_moral(P, N), activo(P), Efs).
expandir(_, moral(P, N),     [mod_moral(P, N)]) :- P \== grupo.
expandir(_, marcar(F),       [marcar(F)]).
expandir(_, perder_queso(N), Efs) :- lotes_mas_rancios(N, Lotes), findall(gastar_queso(T, E, K), member(q(T, E, K), Lotes), Efs).
```

---

## 11. Cambios propuestos al canon

Se proponen para decidir; tras la revisión de 06, la columna "Estado" dice qué se acepta. Se numeran por bloque (11.1: canon; 11.2: forma de datos; 11.3: identificadores nuevos). Ninguno se ha aplicado todavía a `DISENO.md` por este documento.

### 11.1 Respecto a DISENO.md, al lore y al documento 03

| Nº | Sección afectada | Propuesta | Motivo | Estado tras 06 |
|---|---|---|---|---|
| 1 | DISENO §7 (`rasgo_no(teme_caballos)`); doc. 03 C-3 | `rasgo_no(R)` se evalúa contra los miembros activos **que no lleven `ignora_miedo/1`**. La `venda_de_caballos` es la solución. Así `gallina_noble` es aceptable tras `gato_en_el_arbol`. | Evita un contrato imposible por diseño y convierte la condición en una demostración de `por_que_no`. Resuelve C-3 sin necesidad de elegir un "miembro designado". | **Aceptado** (D-19, X-37); 03 C-3 rechazado |
| 2 | DISENO §7 (ejemplo con `quesos(5)`); lore §5 ("pagará 5 quesos") | Escalar recompensas: la gallina pasa de 5 a 12 cheddar (+1 brie); el resto entre 5 y 18. | Con 4 bocas y 4 quesos de comida al día, un contrato de 5 quesos que cuesta 2 días de viaje (8 de comida) es una pérdida. | **Aceptado** (D-09, X-27); el recálculo de 9.2 lleva `gallina_noble` a 14 + brie, `ratas_del_granero` a 9 y `gato_en_el_arbol` a 7 (pendiente de confirmar) |
| 3 | DISENO §7 (forma de `contrato/5`); lore §5.1 | `recompensa(Lista)` además de `recompensa(quesos(N))`; `Zona` = zona del objetivo; hechos auxiliares `oferente/3`, `aparece/2`, `resolucion/3`, `consecuencia/3`; resultados `exito`, `a_medias`, `fracaso`. | Hace implementables las consecuencias con reglas explicables. | **Aceptado** con los nombres de X-36 (D-18) |
| 4 | DISENO §7 (ciclo "cobrar en la taberna"); lore §3.2 y §5 | `aceptar/1` funciona en la taberna o en la zona del oferente; los objetos clave (`sello_real`, `llave_mohosa`) se entregan en el acto; máximo 3 contratos activos. | Reduce viajes de ida y vuelta sin romper el canon. | **Aceptado** (04-4) |
| 5 | DISENO §13 (comandos) y doc. 03 F-04 | Añadir **`elegir(Opcion)`**, **`escuchar`**, **`catar`**, **`recoger`**, **`pagar`** y **`banquete`**. | Los contratos de evento necesitan entradas. | **Aceptado parcial** (D-20): solo `elegir/1`, `pagar` y `demo`; los demás son opciones de `elegir/1` (extra) |
| 6 | Lore §6.2 (IA del `gran_roquefort`) | Añadir al principio la regla `monologo` (cada 3ª ronda) y el `modificador` por rancio y por "apurado". | Hace que el rasgo de Rufino y la gestión de la maduración pesen en el jefe. | **Pospuesto** (extra); el bonus por rancio y "apurado" son objetivo |
| 7 | Lore §6.1 (`gran_roquefort` no lleva queso) | El arco T3 de Tuerca permite `lleva_queso(gran_roquefort)` solo en ese combate. | Da un uso tácito a `rebuscar_bolsillos` contra el jefe. | **Pospuesto** (extra) |
| 8 | Lore §7.3 (`pocion`, tienda de Ricota) y doc. 03 F-27 (tienda "Podría") | Los objetos equipables se obtienen como **recompensa de contratos**, no por compra. La tienda queda opcional. | Sin tienda, el equipo debe poder conseguirse igualmente. | **Aceptado** (D-10, X-33, X-46): el queso no se compra ni se vende; sin tienda en la v1 |
| 9 | Lore §1.4 (Gran Rancio) | Añadir el reloj narrativo `v_rancio_avanza` (días 8, 14, 20, 26) y `dia_limite(35)`. | Presión narrativa sin añadir mecánicas. | **Pospuesto** (extra) |
| 10 | Lore §10.9 (estado `caido`) | **Tras el combate, los caídos se levantan con 1 de vida** (nadie muere), y `miembros_en_pie` se calcula **al terminar el combate final**. | Hace coherentes los finales por "miembros vivos" con el tono sin violencia. | **Aceptado** (D-17, X-44) |
| 11 | Doc. 03 §8.3 ("12–25 días hasta el jefe; 15–30 minutos") | Cambiar a "9–26 días; 15–60 minutos" según la ruta. | Es lo que resulta de las rutas de la sección 9. | **Aceptado** (X-51) |
| 12 | DISENO §6 (sueldos) | `pagar` es una acción explícita al llegar a la taberna; impago = −2 moral por miembro. | Hace que la huelga sea una consecuencia de reglas y no un evento aleatorio. | **Aceptado** (D-14, X-30): comando `pagar`; el impago se evalúa **al salir** |
| 13 | Lore §4.1 (sueldos) y §11.2 | Sueldo total de 5 por pago. Se mantiene. | Confirmación (sin cambio). | Sin cambio |

### 11.2 Respecto a la forma de datos (resumen)

`contrato/5` conserva la aridad del canon. Se añaden `oferente/3`, `aparece/2`, `tipo_contrato/2` (valores `minima | objetivo | extra`), `dificultad/2`, `enemigos_de/2`, `reintentable/2`, `resolucion/3`, `consecuencia/3`, `prohibido/2`, `dialogo/3`, `arco/6`, `evento_campana/5`, `final/2`, `texto_final/2`, `acto/1`. Todos son hechos o reglas simples accesibles a `clause/2`. `via_objetivo/2` (02 §3.5) traduce el `Objetivo` a una vía. Los efectos se expresan con el vocabulario de 02 §4.5 (10.5).

### 11.3 Identificadores nuevos (para añadir al índice del lore, sección 10)

| Categoría | Ids |
|---|---|
| Contratos | `paz_del_moho`, `caballo_fugado`, `correo_real_perdido`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `cena_de_eustaquio`, `pelea_de_taberna` (todos extra) |
| Estados / marcas | `recomendada_por_clotilde`, `escucho_a_eustaquio`, `eustaquio_en_paz`, `sabe_origen_rancio`, `penicilio_conocido`, `cuevas_despejadas`, `baldomero_perdona`, `pimentina_receta` |
| Contadores | `quesos_robados`, `golpes_a_clotilde` (mínima); `hechizos`, `silencios_pagados`, `rebuscados`, `ataques_a_caballo` (extra) |
| Opciones de evento (`elegir/1`) | `trepar`, `hechizo_de_raclette`, `sacudir_arbol`, `cantar` (mínima); `escuchar` (objetivo); `ofrecer_queso`, `nana`, `lazar`, `acercarse`, `leer_el_manual`, `discutir`, `sopa`, `servir`, `catar`, `recoger`, `banquete` (extra) |
| Acciones | `monologo` (jefe), `balada_completa` (Rufino, una vez) (extra) |
| Efectos nuevos de 02 §4.5 | `marcar/1`, `contar/2`, `ganar_descansos/1`, `equipar/2`, `envejecer_lote/1`, `contrato_cobrar/2` |
| Predicados y hechos | `permite_combate/1`, `activo/1`, `en_pie/1`, `ignora_miedo/1`, `contrato_cumplido/1`, `contrato_exito/1`, `contratos_cumplidos/1`, `equipado/2`, `contador/2`, `marca/1`, `visitada/1` |
| Recompensas especiales | `descansos_gratis(N)` (extra) |
| Personajes sin ficha | Gorgonzola (caballo de Pecorino, solo en eventos), `hermanos_emmental` (ya en el índice, ahora con presencia en una escena) |
| Finales | `chapuza`, `derrota_combate`, `derrota_hambre` (mínima); `leyenda`, `quiebra` (objetivo); `madurado`, `derrota_plazo` (extra) |

### 11.4 Decisiones abiertas para el autor

Las cinco preguntas de la versión anterior quedan resueltas por las decisiones aceptadas de 06:

1. `elegir/1` como comando general para eventos: **sí** (D-20); `escuchar`, `catar`, `recoger` y `banquete` son sus opciones.
2. Economía: **recompensas escaladas** (D-09), con 12 cheddar iniciales.
3. Contratos extra: se aplica el recorte de 06 §5.1 (4 / 6 / 9). Orden de recorte entre los extra: `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna`.
4. Pago por valor: **no** en la v1 (D-13).
5. Final `madurado`: **extra** (D-30).

**Pendientes tras esta revisión** (necesitan decisión del autor o propagación a otros documentos):

1. Confirmar el ajuste de recompensas de la ruta mínima (`ratas_del_granero` 9, `gato_en_el_arbol` 7, `gallina_noble` 14 + brie; ver 9.1) y propagarlo a 01 §5.1 y al banco de frases de 05. Sin él, la mínima pasa hambre el día 7.
2. Confirmar los umbrales provisionales de Clotilde (éxito ≤ 2 golpes, a medias 3–4, fracaso 5 o más; un golpe por ronda de escolta) y que `gallina_noble` sea **reintentable** (3 días) para que un fracaso no bloquee `despensa_real` en la mínima.
3. Objetivo: `estoque_de_parmesano` figura entre los 5 objetos del objetivo, pero su contrato (`caballo_fugado`) es extra; decidir qué contrato del objetivo lo da, o quitarlo del nivel. Igual con el enemigo `arquero_aburrido` (sus contratos son extra; propuesta: refuerzo en la emboscada de `gallina_noble`).
4. Objetivo: la ventaja de −10 de vida del jefe se liga a `exito(fantasma_charlatan)` sin `llave_mohosa` (la llave es extra); confirmar.
5. Qué 3 eventos de campaña y qué 3 pasos de tutorial extra forman el objetivo (se proponen `v_primer_viaje`, `t_registro_sube`; T2, T8, T10).
6. `contrato_cobrar/2` (parte `mitad`) hay que añadirlo al vocabulario de 02 §4.5, y 02 debe aceptar que `contrato_cumplido/1` cuente los contratos "por cobrar".
7. La demostración `por_que_no(atacar(baldomero, bandido_montado))` necesita un estado de prueba sin venda equipada (en una partida normal Baldomero ya la lleva).

---

## Registro de cambios de la revisión

Revisión del 2 de noviembre de 2026 tras `docs/06-revision-y-decisiones.md`. Las referencias D-nn son decisiones aceptadas por el autor (06 §4); X-nn, contradicciones detectadas (06 §2); "§5.1", el recorte de alcance.

| Qué cambió | Dónde | Motivo |
|---|---|---|
| Nota inicial de revisión y estado v0.2 | Cabecera | 06 (estado de las decisiones) |
| Marcas **(mínima) / (objetivo) / (extra)** en fichas, tablas, tutorial, arcos, eventos y finales; contenido recortado conservado como "contenido ampliable"; tabla "Niveles de alcance" | Cabecera, 1.2, 2.3, 3, 4, 5, 6, 7, 8 | §5.1, D-21 |
| Contratos: 4 mínima (`ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real`), +2 objetivo (`peaje_del_ganso`, `fantasma_charlatan`), 9 extra; clasificación y tabla resumen reordenadas por nivel; ya no hay "núcleo/secundario" | 3, 3.16, 4 | §5.1, D-21 |
| Enemigos (5/7/12), objetos (2/5/20), acciones de IA (3/5/11), estados, jefe, finales (3/5/7), arcos (0/2/10), eventos (1/3/15), tutorial (6/9/12) | Niveles de alcance, 2.3, 5, 7, 8 | §5.1 |
| Recompensas escaladas conservadas y recalculadas: `ratas_del_granero` 7→9 (+`pocion`), `gato_en_el_arbol` 5→7, `gallina_noble` 12→14 + brie; saldos nuevos | 3.2, 3.3, 3.9, 3.16, 9 | D-09, X-27, X-46 |
| El queso no se compra ni se vende, sin tienda en v1; Ricota solo recibe el queso del contrato; Penicilio ya no "vende"; despedida de Ricota sin comercio; consumibles como recompensa | 3.6, 3.7, 6.2, 9.1 | D-10, X-33, X-46 |
| Ración diaria **fresco → curado → rancio** (antes "más viejo primero"); gastos con lo más rancio; §9.4 punto 4 reescrito | 9.1, 9.4 | D-11, X-28 |
| Tabla de economía recalculada con un script en tres rutas (mínima, objetivo, ampliada) más variantes, con columna de despensa por categorías; botín del día 4 corregido (3→4); recuentos de rutas corregidos (13 de 15, no 15; recomendada 12 con jefe) | 1.3, 9.2, 9.3 | D-11, X-35, §5.1 |
| Pago por unidades; el valor solo informa | Supuestos, 9.1 | D-13, X-32 |
| `pagar` como comando; impago evaluado **al salir** de la taberna; cobro de contratos automático; T10 reescrito | 2.3, 3.1, 9.1, 9.4, 10.4 | D-14, X-30 |
| Sin `deuda_taberna`: `t_mantecosa_cuenta` eliminado y rechazo de Mantecosa reescrito ("dos quesos la noche") | 6.1, 7.2 | D-15, X-31 |
| Nombres canónicos: `permite_combate/1`, `activo/1`, `en_pie/1`, `condicion_cumple/1`, `resolucion/3` y `resultado/3`, `lleva/3` y `equipado/2`, `contrato_cumplido/1`, `cantando/1`, `contratos_cumplidos_min`, `puede_aceptar/1`; `estado(rufino, cantando)` sustituido | 3.1, 3.17, 3.18, 8.3, 10 | D-16, X-12 a X-18 |
| Caídos solo en combate y se levantan con 1 de vida; derrota en combate = `derrota_combate`; `derrota_hambre` al empezar el día con queso 0 y nada por cobrar; el hambre no baja la vida de 1; "fracaso" de contrato solo por `huir` | 3.1, 3.2 a 3.15, 8.3, 8.4, 9.1, 9.5 | D-17, X-44 |
| `contrato/5` con aridad 5, objetivos cerrados (`eliminar`, `derrotar`, `escoltar/2`, `evento`; `escuchar` objetivo; `reunir`, `recuperar` extra) y `via_objetivo/2`; `escuchar` queda como evento de 3 pasos | 3.1, 10.1 | D-18, X-36 |
| `rasgo_no(teme_caballos)` evalúa miembros activos que no ignoren el miedo (venda); `teme/2` e `ignora_miedo/1` consistentes; T5, la condición legible de `gallina_noble` y la fila de 3.18 corregidas (la regla no mira enemigos) | 2.3, 3.1, 3.9, 3.18, 10.1 | D-19, X-37 |
| Comandos nuevos reducidos a `elegir/1`, `pagar` y `demo`; `escuchar`, `catar`, `recoger` y `banquete` pasan a opciones de `elegir/1` | 3.4, 3.6, 3.12, 5.3, 10.4 | D-20, X-40 |
| No se puede huir del jefe; `huir` rechazado y explicable | 3.15, 8.1, 8.3, 9.5 | D-29, X-45 |
| Finales: 3 en la mínima, 5 en el objetivo, 7 con extra; `leyenda` baja a 5 contratos con éxito en el objetivo; puesto del Registro según 05 en partida y según el texto en el final | 8.4, 8.5, 7.2 | D-30, X-53 |
| Clotilde como contador de golpes recibidos (`golpes_a_clotilde`) en la mínima; `gallina_noble` reintentable | 3.9, 5.1 | D-33, X-38, X-39 |
| IA del jefe: guarda `instancia/2`, 4 reglas en la mínima, resto objetivo/extra; comentario de corte de `acto/1` eliminado (cláusulas excluyentes) | 1.2, 8.3 | D-24, X-19, X-42, X-56 |
| Vocabulario de efectos alineado con 02 §4.5: tabla de traducción y `expandir/3`; `aplicar/1` y `actualizar_*` sustituidos por `estado:aplicar_efectos/1` | 10.3, 10.4, 10.5 | D-04, D-05, X-01, X-03 |
| `explicar` y `por_que_no` como comandos (términos), no predicados | Cómo leer, 10.4 | D-03, X-02 |
| Texto visible hacia el almacén único `frase/3` (puede esperar) | 10.2, 10.4 | D-27, X-07 |
| Cambios al canon (11.1) con columna de estado; decisiones abiertas reemplazadas por resueltas y pendientes | 11 | D-10, D-14, D-17, D-19, D-20, D-30 |
