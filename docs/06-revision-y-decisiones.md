# Banda Chapuza — Revisión de coherencia y decisiones abiertas

> Documento 06 de la fase de diseño. Revisa `DISENO.md` (canon) y los documentos 01 a 05, que se escribieron en paralelo. **No modifica ninguno**: reúne contradicciones, propuestas de cambio y decisiones para que el autor elija qué se aplica.
>
> Fecha de la revisión: lunes 2 de noviembre de 2026 (primer día de la semana 1 del calendario de 03). Entrega: viernes 11 de diciembre de 2026.
>
> Método: lectura completa de los seis documentos, contraste cruzado de identificadores, nombres de predicados, cifras y alcance, y recálculo de las tablas numéricas de 03, 04 y 05 (sumas de horas, tabla día a día de la economía, recuento del banco de frases). Las pruebas sobre SWI-Prolog se hicieron en este equipo (versión 5.10.4, 64 bits); lo no comprobado se lista en la sección 7. Las estimaciones de horas que aparecen aquí son **del revisor** (extrapoladas de las de 03), no medidas.
>
> Convención de gravedad: **bloqueante** = hay que resolverlo antes de escribir código de la semana 1, o invalida a la vez varios documentos; **importante** = hay que resolverlo antes de la semana en la que se implementa; **menor** = cosmético o con solución obvia.
>
> **Estado de las decisiones (2 de noviembre de 2026):** el autor aceptó como base **todas las recomendaciones** de este documento (columna "Recomendación" de la sección 4, y el recorte "Nivel A" de la sección 5, con 10 h/semana como supuesto de partida y paso al Nivel B si se acumula un desvío mayor de 3 h un viernes). Decidido además: se desarrolla con SWI-Prolog 5.10.4 (D-02). Confirmado además el ajuste de recompensas de la mínima tras el recálculo de la economía en 04 §9.2: `ratas_del_granero` 9, `gato_en_el_arbol` 7 y `gallina_noble` 14 + 1 brie (con 12 cheddar iniciales; revisión provisional hasta el balance de la semana 6). Las preguntas a la profesora (D-34 a D-38) siguen pendientes de enviar. Los documentos 01 a 05 y `DISENO.md` se alinean con estas decisiones; cada uno lleva al final un registro de cambios.

---

## 1. Resumen ejecutivo

1. **Estado general:** el diseño es rico, divertido y coherente en tono y en lo declarativo (reglas explicables, narrador separado de la lógica), pero los cinco documentos **no convergen** en arquitectura, nombres ni números. Hoy es 2 de noviembre: la semana 1 ya ha empezado sin decisiones cerradas (la sesión previa S0 de 03 no se ha hecho) y `src/` solo contiene 10 stubs vacíos.
2. **Problema 1, alcance:** 03 declara 58,5 h de tareas "Debe" (suma verificada). Lo que exigen 01, 02, 04 y 05 sobre ese mismo núcleo lo lleva a unas 65 h, y el contenido total diseñado equivale a 150-170 h, frente a 50-62 h disponibles. Hay que recortar ya (sección 5).
3. **Problema 2, arquitectura:** 02 (comandos como términos, `estado.pl` único escritor, efectos como datos, `juego:ejecutar/2`) choca con 03 (comandos como predicados, `actualizar_*` repartidos), 04 (`aplicar/1`) y 05 (narrador con estado propio). Hay **tres vocabularios de efectos distintos**.
4. **Problema 3, números de la economía:** moral 0-10 (01, 04) frente a 0-100 (02); queso inicial 12 (01, 04) frente a 5 (canon, 02); recompensa de `gallina_noble` 12 frente a 5; tres políticas de comida; `pagar` automático frente a explícito; `comer` sin definir; y **el queso es la única moneda pero 01 y 03 hablan de "comprar queso"** (X-33).
5. **Problema 4, nombres y claves:** al menos 12 predicados tienen nombres distintos o no existen en 02 (`puede_ir`/`puede_viajar`/`conectadas`, `huelga`, `lleva/2` frente a `lleva/3`, `puede_combatir/1` con dos significados, `queso_total/1` ausente...). Las claves `impide/falla` de 05 no corresponden al formato de diagnóstico de 02 (`neg_viola`, `tras`...).
6. **Problema 5, meta-intérprete y contratos:** 03 trata el corte como "hoja que triunfa" y 02 lo implementa de verdad (con el primero, la IA con corte rompería la prueba de equivalencia); `rasgo_no(teme_caballos)` tiene tres resoluciones; la escolta de la gallina exige un aliado NPC en combate que ni 02 ni 03 contemplan. Además, 02 usa `predicate_property(_, defined)`, que **no funciona** en el SWI-Prolog 5.10.4 instalado, y 05 usa `random_between/3` y `random_member/2`, que **no existen**.
7. **Hay que decidir primero (hoy y mañana):** D-01 dedicación real y nivel de recorte; (D-02, la versión, ya está decidida: SWI-Prolog 5.10.4, con cambios obligatorios en la tabla 2.8); D-03 a D-07 arquitectura (comandos, estado, efectos, corte, módulos); D-08 a D-10 números de la economía y papel del queso como moneda.
8. **Recomendación general:** aceptar la arquitectura de 02 simplificada (12 archivos), el calendario de 03 como maestro, los datos de 01/04 (moral 0-10, 12 quesos, recompensas escaladas) y el banco de 05 recortado; la versión mínima son 4 contratos, 5 enemigos y unas 70 frases, y todo lo demás pasa a "extra".

---

## 2. Contradicciones entre documentos

Los números `§` remiten a la sección del documento citado. Las "resoluciones" son propuestas; las decisiones que requieren al autor tienen su entrada D-xx en la sección 4.

### 2.1 Arquitectura y flujo

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-01 | bloqueante | 02 §1.1 (P1-P3), §2.1; 03 F-02, F-04, T-03, T-04, §12.4; 04 §10.4; 05 §5.4 y cambio 4 | 02: `estado.pl` es el **único** módulo con `assert/retract` y `ui.pl` el único con E/S; 14 módulos (10 + `estado`, `juego`, `parser`, `arbol`). 03: "`assert`/`retract` únicamente dentro de predicados `actualizar_*`" (en cualquier módulo), `ui.pl` "lee términos ... los despacha", T-03 pone `mirar/0` (que escribe en pantalla) en `mundo.pl`, y §12.4 habla de "los 10 módulos del canon". 04: `aplicar/1` "usa los predicados `actualizar_*` del documento 03". 05: el narrador declara `:- dynamic usos_frase/2` y `frase/3` y escribe con `actualizar_uso_frase/2`. | Adoptar 02: `estado` único escritor, `ui` única E/S. Los `actualizar_*` pasan a ser auxiliares privados de `estado` (02 §16 C5 ya lo dice). Reescribir los criterios F-02 y T-03/T-04 de 03; mover `mirar` a `juego`/`ui`; el estado de rotación del narrador (05) pasa a `estado.pl`. |
| X-02 | bloqueante | 03 F-03, F-04, F-12, §9, §10; 02 §3.12, §5.1, §7; README; stub `src/explicar.pl` | 03 trata los comandos como **predicados invocables** (`ir/1`, `contratos/0`, `compania/0`, `pagar/0`, `demo/0`, `explicar/1`, `por_que_no/1`, "dado ... cuando escribe `ir(aldea).` entonces `en_zona(aldea)` es cierto"). 02 los trata como **términos** validados por `parser` y ejecutados por `juego:ejecutar/2`, que devuelve `resultado(Items)` sin imprimir; `explicar`/`por_que_no` se traducen con `objetivo_de_accion/2`. El stub de `explicar.pl` y el README prometen "explicar/1, por_que_no/1, arbol/1". | Adoptar 02 (el núcleo se prueba sin consola). Los criterios de 03 se reescriben como "dado el comando `ir(aldea)` ejecutado con `juego:ejecutar/2`". El README y el stub dejan de prometer predicados `explicar/1`: son comandos. |
| X-03 | bloqueante | 02 §4.5; 04 §10.3 (`aplicar/1`), §5; 05 §6.2 (`aplicar_efecto/1`) | Tres vocabularios de efectos. 02: `dano/2`, `curar/2`, `mod_moral/2`, `ganar_queso/3`, `gastar_queso/3`, `envejecer_quesos`, `contrato_cobrar/1`... 04: `cobrar(todo)`, `cobrar(mitad)`, `perder_queso(N)`, `moral(grupo,N)`, `marcar(Flag)`, `mejora/3`, `descansos_gratis(N)`. 05: `quitar_queso(N)`, `dar_queso(T,E,N)`, `moral(Quien,D)`, `vida(Quien,D)`, `quitar_queso_mas_fresco/1`, `envejecer_lote_mas_curado/1`, `dar_objeto/1`, `quitar_estado/2`. | Un único vocabulario, el de 02 §4.5, ampliado con `marcar/1`, `contar/2`, `ganar_descansos/1`, `equipar/2`. Las formas de 04 y 05 se traducen una vez en un predicado `contratos:expandir/2` o `eventos:expandir/2` hacia ese vocabulario (por ejemplo `moral(grupo,N)` pasa a un `mod_moral/2` por miembro). Tabla de traducción en el anexo de la sección 2.7. |
| X-04 | bloqueante | 03 F-18, T-13, C-8, §10.3; 02 §6.5, R2 | 03: "el corte se trata como hoja que siempre triunfa" y las explicaciones corresponden a la primera solución (`once/1`). 02: implementa el corte real (se parte el cuerpo en `Pre`/`Post` con un `!` verdadero), añade el marcador `corte` a la prueba y lanza `corte_no_soportado` ante un `!` anidado. Con el tratamiento de 03, `solve(accion_enemigo(E,A), _)` devolvería alternativas que la ejecución directa poda, y la prueba de equivalencia con ≥ 20 objetivos (03 F-18, T-40) fallaría justo en la IA, que es la pieza del corte. | Adoptar 02 §6.5. Decidirlo con el spike de la semana 1 (T-07, 2 h). Plan B documentado en 02 R2: partir el cuerpo en dos predicados auxiliares. Si el spike falla, volver al criterio de 03 y **excluir** `accion_enemigo/2` de la equivalencia, documentándolo. |
| X-05 | importante | 02 §15.3; 03 §4, §6; 02 §16 C13; 03 C-1 | Calendarios distintos. 02 pone en S1 `mundo`, `estado`, `compania`, `economia` básica, `parser`, `ui`/`main` y `solve/2` **con equivalencia** (más de 10 h); 03 pone en S1 solo el spike de `solve/2`. 02 sitúa `por_que_no` en S3 y los contratos en S5 (después de "cerrar el núcleo" en S4); 03 los pone en S4 (`por_que_no` v1 y contratos) y exige partida mínima completa el 27 de noviembre. El backlog de 03 (T-01 a T-45) **no tiene tareas** para `estado:aplicar_efectos`, `juego`, `parser`, `objetivo_de_accion`, `ultima_prueba`, `pagar`, `elegir`, finales múltiples ni el registro de decisiones de la IA. | Usar el calendario de 03 como maestro y añadir al backlog las tareas ausentes (sección 5.3). El "orden de construcción" de 02 sirve como guía técnica dentro de cada semana. |
| X-06 | importante | 02 §2.1, §3.10, §4.2; 05 §5, §7.1, §3.3 | 02: `narrador` es de capa 0, **sin imports**, puro, con `comentario/3` que recibe `Semilla`. 05: el narrador lleva estado (`usos_frase/2`, `descanso_gag/2`, `ultimo_dia_gag/2`, `explicaciones_hoy/1`), sus condiciones de gags leen `en_zona/1`, `dia/1`, `estado/2`..., declara `frase/3` como `dynamic` (contra P3) y propone un archivo extra `frases.pl` (15º módulo). | El narrador sigue puro: recibe como argumentos el día, la semilla y los contadores; los contadores viven en `estado.pl` (hechos transitorios o `ajuste/2`). Las condiciones de gags se evalúan en `juego` (que sí ve el estado) y se pasan a `narrador` como lista de candidatos. `frase/3` es estático (`clause/2` funciona igual). `frases.pl` queda pospuesto: empezar en `narrador.pl` y separar solo si pasa de unas 300 líneas. |
| X-07 | menor | 01 §3; 02 §10.4; 04 §2.2, §6, §8.5, §10.2-10.4; 05 §7 | El texto visible se guarda en cuatro sitios: descripciones de zona (01/03, en `mundo`), `dialogo/3`, `consejo/3`, `texto_final/2` y textos de `evento_campana/5` (04), y `frase/3` (05). 04 §10.4 dice que "cada hecho de texto puede asociarse a una frase del narrador con `frase/2`", sin precisar cómo. | Un solo almacén de texto (`frase/3`, claves nuevas `texto(dialogo(Npc,Tema))`, `texto(final(Id))`, `texto(consejo(Id))`, `texto(zona(Id))`). Los datos de 04 conservan la lógica (quién, cuándo) y apuntan a la clave. Para la versión mínima, los textos pueden quedar inline mientras el código no dependa de dónde estén. |
| X-08 | importante | 02 §11.1, §11.4; 03 §8.1, F-32, F-18; 05 §7.6 | Archivo agregador `tests/run_all.pl` y orden `swipl -q -s tests/run_all.pl -g "run_tests,halt" -t "halt(1)"` (02) frente a `tests/todas.pl` y `swipl -q -g run_tests -t halt tests/todas.pl` (03, 05). Nombres de archivos de prueba distintos (02: `test_estado`, `test_arquitectura`...; 03 §12.4: `test_mundo`, `test_equivalencia`...). Equivalencia: 03 con `once(G)` y `once(solve(G,_))` (solo la primera solución); 02 con todas las soluciones y el mismo orden (`=@=`). | Adoptar `tests/todas.pl` y la orden de 03 (la que ya cita el README de 05); equivalencia de 02 (más fuerte). Comprobar el código de salida (sección 7). |
| X-09 | importante | 02 §1.2, §4.4, D6; 03 F-25, F-33, C-9; 05 §5.2 (E), §6.2 | 02: generador congruencial propio, sin `random/1`, para que la partida sea reproducible. 05: `random_between/3`, `random_member/2` y `set_random(seed(S))`. **En 5.10.4 `random_between/3` y `random_member/2` no existen** (comprobado). Además `set_random(seed(N))` no garantiza la misma secuencia entre versiones o máquinas, y la demo debe ser idéntica "byte a byte" (03 F-33) incluso meses después. | Adoptar el LCG de 02 (`S1 is (S0*75+74) mod 65537`) y que 05 elija con `tirada/4`. Cambiar 05 §5.2 (E) y §6.2. |
| X-10 | importante | 02 §13.1, §13.2, R4, D1; 03 C-7, T-01; 05 §7.5; DISENO §17 | Los documentos suponen que habrá que escribir al "subconjunto común" de 5.10.4 y 9.x, desarrollando en 9.x (02 §13.1, 03 C-7 "versión estable actual 9.x"). **En este equipo solo hay SWI-Prolog 5.10.4 (64 bits, en `C:\Program Files\pl\bin`, fuera del PATH)**, que es la versión del curso. Funciones que los documentos usan o descartan: 02 prohíbe `atomic_list_concat` (existe en 5.10.4, y 05 §7.5 la usa); 02 §6.4 usa `predicate_property(D:G, defined)` (**no devuelve éxito en 5.10.4**); 05 usa `random_between/3`, `random_member/2` (no existen); 02 acierta al evitar `foldl/4`, `sum_list/2`, `max_member/2`, `split_string/4`, `yall` y cadenas con comillas dobles (tampoco existen o son listas de códigos). 02 §11.1 y R4 dudan de que exista `plunit` (existe y detecta fallos). | **Decidido por el autor: se desarrolla con 5.10.4**, solo con su subconjunto. Los cambios obligatorios en 02-05 están en la tabla 2.8; las pruebas realizadas, en la sección 7. |
| X-11 | importante | DISENO §11.3; 02 §6.11, §13.2, R3, C11, D8; 05 §7.5, cambio 9 | DISENO y 05 muestran `✔ ✘ ├─ └─`, tildes, `¿`, `«»` y piden UTF-8 y `chcp 65001`. 02 propone **ASCII por defecto** con Unicode opcional. Comprobado en 5.10.4: `:- encoding(utf8).` funciona al cargar, pero la salida por defecto degrada los símbolos (`✔` sale como `\u2714`, `├─` como `+-`); con `set_stream(user_output, encoding(utf8))` salen bien al redirigir a un archivo (la consola de Windows puede requerir además `chcp 65001`, sin comprobar). La opción ASCII de 02 solo cubre símbolos, no las tildes y `« »` del banco de 05. | Salida ASCII por defecto para símbolos de árbol (`[ok]`, `[no]`, `\-`, `\|-`); `set_stream(user_output, encoding(utf8))` en `ui` para el texto; comprobar tildes en la consola de la entrega la semana 1 (sección 7); `ajuste(ascii, Bool)` para forzar. Actualizar DISENO §11.3 como "versión Unicode". |

### 2.2 Nombres, API y claves de frases

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-12 | importante | DISENO §9; 01 §8 ley 7; 02 §3.1, §3.3; 03 F-01, T-03; 05 §4.1-4.2 | Movimiento: `conexion/2` (canon), `adyacente/2` (02), `conectadas/2` (03, con criterio de aceptación sobre `conectadas(bosque, aldea)`), `puede_viajar/1` (02), `puede_ir/1` (claves F07 y X15, y `reglas_explicables` en 05), `ir/1` (comando y regla de 01). | Canon: `conexion/2` (datos), `adyacente/2` (simetría), `puede_viajar/1` (meta que se explica). Renombrar en 05 `puede_ir` a `puede_viajar`; cambiar el criterio F-01 de 03. |
| X-13 | importante | 01 §4.7, §8; 02 §3.3, §3.6; 05 §4.1-4.2 | Habilidad y huelga: `puede_habilidad/2` (01, 05) frente a `puede_usar_habilidad/2` (02); `huelga/1` (01 ley 4, 05, eventos) frente a `esta_en_huelga/1` (02). | Adoptar `puede_habilidad/2` (más corto, ya usado por 01 y 05) y `esta_en_huelga/1`; alias `huelga/1` solo si se necesita una clave de 05. Una sola decisión de nombres (anexo 2.7). |
| X-14 | importante | 01 §8 ley 6; 04 §3.17, §3.18; 05 §4.2 (F09); 02 §3.3 | `puede_combatir/1` tiene **dos significados**: 02, `puede_combatir(+Id)` = personaje vivo y no en huelga; 01, 04 y 05, `\+ puede_combatir(taberna)` = la zona permite combate. Mismo nombre y aridad: la regla de la taberna nunca sería falsa por la razón correcta y `por_que_no(atacar...)` mostraría el predicado equivocado. | Renombrar el de zona a `permite_combate/1` (`\+ permite_combate(taberna)`) y la clave de 05 `falla(permite_combate(taberna))`. |
| X-15 | importante | DISENO §9.3; 01 §10.9; 02 §4.2 (`alterado/3`), §12.2; 04 §3.2, §5; 05 §3.3, §6.3 | Estados: el canon y 02 escriben `\+ aturdido(A)`, pero el dato de 02 es `alterado(Id, Estado, Turnos)` y no define `aturdido/1`. 01, 04 y 05 usan `estado(rufino, cantando)` / `estado(P, E)`; 05 usa claves `impide(aturdido(P))`, `impide(cantando(rufino))`, `impide(huelga(P))`. `cantando` no caduca por turnos (dura hasta pagar el silencio), pero `alterado/3` lleva turnos restantes. | Definir derivados `aturdido/1`, `cantando/1`, `apestado/1` sobre `alterado/3` (con duración `fijo` para `cantando`), y que todas las reglas y claves usen esos derivados. Prohibir `estado/2` como nombre. |
| X-16 | importante | 01 §7.3; 02 §4.2, §8.5; 04 §10.1; 05 §6.3 | Objetos: `lleva/2` (01: `lleva(baldomero, venda_de_caballos)`) frente a `lleva/3` (02: `lleva(Id, Objeto, Cantidad)`, con `compania` como id del inventario común); `tiene_objeto/1` (04), `tiene/2` (canon/02, IA), `posee/1` y `lleva_alguien/1` (05). Sin unificar, `ignora_miedo/1` y `cumple(objeto(O))` no encuentran la venda. | `lleva(Id, Obj, N)` para el inventario; `equipado(Id, Obj)` para lo que lleva puesto un personaje; `ignora_miedo(P) :- equipado(P, venda_de_caballos)`. Eliminar `tiene_objeto/1`, `posee/1`, `lleva_alguien/1` o definirlos como alias. |
| X-17 | importante | 02 §3.3, §4.2; 04 §3.1, §10.1; 05 §6.3 | Pertenencia a la compañía: `en_compania(Id)` es dato de membresía (02), pero 05 lo define como "miembro **vivo** y presente"; 02 también tiene `miembro/1`; 04 usa `activo/1`, `miembro_activo/1` ("en la compañía y no `caido`") y `en_pie/1` ("no `caido` ni en `huelga`"). | Tres niveles, tres nombres: `miembro/1` (membresía), `activo/1` (miembro y vivo), `en_pie/1` (activo y no en huelga). `en_compania/1` queda como hecho de `estado` y 05 pasa a usar `activo/1`. |
| X-18 | importante | 02 §4.2 (`contrato_por_cobrar/2`, `contrato_cerrado/2`); 04 §3.1, §10.1; 05 §3.3, §4.2 (F10d) | Contrato cumplido: `contrato_cerrado(C, R)` (02), `cumplido/1`, `resultado_contrato/2`, `contratos_cumplidos/1` (04), `contrato_cumplido/1` y `contratos_cumplidos(N)` (05). Además la condición de 04 es `contratos_cumplidos_min(N)` y la clave de 05 es `falla(requiere(contratos_cumplidos(N)))`: `contratos_cumplidos/1` devuelve el recuento en 04, no una condición. | Hechos: `contrato_cerrado(C, Res)`. Derivados: `contrato_cumplido(C)` (res éxito o a medias), `contrato_exito(C)`, `contratos_cumplidos(N)`. Condición `contratos_cumplidos_min(N)` y clave de 05 `falla(requiere(contratos_cumplidos_min(N)))`. |
| X-19 | importante | 02 §4.2, §4.6, §8.1; 04 §8.3 (`accion_enemigo(gran_roquefort,...)`); 05 §4.1 (X20), §7.5 | Enemigos: 02 usa instancias `e(Tipo, N)`. 04 escribe la IA del jefe con el átomo (`accion_enemigo(gran_roquefort, ...)`). Las claves X20 de 05 son átomos (`accion_enemigo(rata_quesera, robar_queso)`) y `nombre_visible/2` (05) devuelve el id tal cual para lo desconocido, de modo que un `e(bandido_torpe,1)` se imprimiría crudo y sin artículo ni número. | El narrador normaliza `e(T,_)` a `T` al buscar la clave y al mostrar el nombre añade el número solo si hay varias instancias del mismo tipo ("el Bandido Torpe (2)"). El jefe se escribe con guarda `instancia(E, gran_roquefort)`, no con un átomo en el primer argumento. |
| X-20 | importante | 02 §3; 01 §4.7, §8; 04 §10.1; 05 §3.3, §6.3, §7.6 | Predicados que 01, 04 o 05 usan y **02 no define en su API**: `queso_total/1` (01, 04, 05), `puede_descansar/0`, `puede_pagar_sueldos/0`, `hay_queso_para/1`, `moral_media/1`, `contratos_cumplidos/1`, `en_pie/1`, `activo/1`, `ignora_miedo/1`, `modificador/3` (solo interno en 02 §8.4), `calidad_golpe/2`, `deuda_taberna/1`, `visitada/1`, `estado_queso/2` (05; equivale a `categoria_queso/2` de 02), `avanzar_dia/0` (05 lo trata como regla explicable, 02 como efecto y 04 como `pasar_dia`). `objetivo_de_accion/2` de 02 §6.2 no tiene entradas para `descansar` ni `pagar`. | Añadir al API de 02 §3 los que se mantengan (anexo 2.7). `estado_queso/2` desaparece a favor de `categoria_queso/2`. `avanzar_dia` no es una regla explicable: la clave `X16` pasa a `puede_viajar` o `puede_descansar`. Completar `objetivo_de_accion/2`. |
| X-21 | importante | 02 §6.9; 05 §7.2, §7.4 | 02 produce diagnósticos `sin_clausula/1`, `fallo/2`, `builtin_falso/1`, `neg_viola(G, Prueba)`, `tras(Prueba, Diag)`. 05 busca frases con claves `impide(Hecho)` y `falla(Meta)`. No hay traductor definido. Ejemplo: 04 define `rasgo_no(R)` como `\+ (activo(M), rasgo(M,R), \+ ignora_miedo(M))`, así que `neg_viola` contiene `rasgo(baldomero, teme_caballos)`, no `teme(baldomero, caballo)`, y la clave `impide(rasgo_no(teme_caballos))` (F10b) tampoco coincide. | Definir en `narrador` o `arbol` `clave_de_diag/2`: `neg_viola(X, P)` pasa a `impide(H)` con `H` el primer hecho de `P` que tenga frase; `fallo(G,_)` y `tras(_, D)` bajan hasta el punto de fallo y producen `falla(Meta)`. Escribirlo antes de T-15 (semana 2) y probarlo con las 6 claves del núcleo (F01, F02e, F05, F06, F07, F10). |
| X-22 | importante | 02 §4.2; 04 §2.3, §3.1, §5.1, §7, §10; 05 §5.4, §6 | Hechos dinámicos que otros documentos necesitan y 02 no declara: `visitada/1`, `marca/1` (banderas), `contador/2` (hechizos, silencios, rebuscados, ataques_a_caballo), `consejo_dado/1`, `descansos_gratis/1`, `reaparece/2` (contratos reintentables), `equipado/2`, `deuda_taberna/1`, ronda/invocaciones del jefe, `usos_frase/2`, `descanso_gag/2`, `ultimo_dia_gag/2`, `explicaciones_hoy/1`, `ultimo_suceso/1`, `ultimo_dia_evento/2` y `evento_ocurrido/1` (02 tiene `evento_visto/2`). | Ampliar `estado:persistente/1` (y su prueba) con la lista aprobada. Reducir: en la versión mínima solo hacen falta `visitada/1`, `marca/1`, `equipado/2`, `consejo_dado/1` y los contadores del narrador. |
| X-23 | menor | 01 §4.1, §6.1, §7.3; 02 §3.1, §4.1 | Forma de los datos: 02 propone `personaje/7`, `enemigo/4` (canon), `objeto/3` y `clase/2` (con la clase de ejemplo `muerto_viviente`). 01 añade fila, alcance, clase, `lleva_queso`, habilidades, y para objetos `efecto/2`, `bonus/3`, `racion/2`, `solo_para/2`, slots. 02 deja `ataca_a_distancia(A) :- ...` como "dato en mundo". | Añadir a `mundo`: `fila_preferida/2`, `alcance/2`, `clase/2`, `lleva_queso/1`, `habilidad_de/2`, `efecto_objeto/2`, `bonus/3`. Mantener `personaje/7` y `enemigo/4` del canon. |

### 2.3 Economía, moral y números

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-24 | bloqueante | 01 §4.1, §11.3; 02 §4.1, §4.2, §5.5; 03 F-09, F-10; 04 §1.2, §5, §9.1 | Escala de moral: 01 y 04, entero **0 a 10**, inicio 6, huelga si moral < 3; 02, **0 a 100** (`moral/2` con "0 =< M =< 100", `parametro(moral_huelga, 20)`, `mod_moral` acotado a 0-100). Los umbrales de 04 (≥ 4, ≥ 5, ≥ 6, ≥ 7), las condiciones `moral_media_min` y los finales dependen de la escala 0-10. 02 define niveles `alta/normal/baja/critica` sin cifras; 03 F-10 pide un modificador de daño por moral sin tabla. | Escala 0-10, inicio 6, huelga con moral ≤ 2 (`parametro(moral_huelga, 2)`, que equivale al "< 3" de 01/04). Corregir 02 §4.2, §4.5 y §5.5. Fijar niveles: alta ≥ 8, normal 4-7, baja 2-3, crítica 0-1 (provisional), y modificador de ataque +1/0/-1/-2. |
| X-25 | menor | 01 §11.3; 02 §3.3; 03 F-11; 04 §9.1; 05 F02e | Definición de huelga: 01, "se debe un sueldo **y** la moral baja de 3"; 02 y 04, solo moral; 03 F-11, "moral baja e impago". El texto F02e de 05 dice "ha cobrado", lo cual es falso si la moral cayó por hambre. | Huelga derivada solo de la moral (regla de 3 líneas, explicable). Texto F02e: "... y la moral de ~w está por los suelos". |
| X-26 | importante | DISENO §9.2; 01 §11.1; 02 §4.1; 03 F-09; 04 §2.1, §9.1 | Queso inicial: `queso(cheddar, 0, 5)` (canon, y el `inicio/1` de ejemplo de 02); 01 propone **12** porque con 4 miembros y 4 quesos diarios 5 alcanzan "poco más de un día"; 04 lo asume y construye sobre él el diálogo de Mantecosa ("Doce quesos, cuatro bocas") y la tabla del día 1. | 12 cheddar de edad 0 (cambio al canon aceptado). |
| X-27 | importante | DISENO §7 (`quesos(5)`); 01 §5 ("pagará 5 quesos"); 04 §3, §11.1 cambio 2 | Recompensa de `gallina_noble`: 5 (canon, 01) frente a 12 + 1 brie (04). Con 4 quesos de comida diarios y 2 días de viaje (8 quesos), 5 quesos son pérdida. 04 escala todas las recompensas a 5-18. | Aceptar la escala de 04 (cambio 2), siempre que se mantengan 12 quesos iniciales. Corregir DISENO §7 y 01 §5. |
| X-28 | importante | 01 §7.1; 02 §5.5, D3; 03 C-6; 04 §9.1, §9.4 punto 4 | Política de comida (qué queso se come en la ración diaria): 02, **fresco → curado → rancio al final**; 03 C-6 y 04, **el más viejo primero** (04 §9.4: "el rancio se come pronto y baja la moral (-2)"); 01 §7.1 solo dice que el **pago** va con el más rancio primero. Con "más viejo primero" casi nunca queda rancio en la despensa (se come antes de llegar a edad 10 si el stock es menor de unos 40), lo que vacía de contenido a la ley del Hedor, `fondue_flamigera` con rancio, `lanzar`, el bono +2 del jefe y la curación del moho. | Adoptar 02 (fresco primero), que es la que mantiene vivo el rancio; reescribir 04 §9.4 punto 4. La tabla numérica de 04 no cambia (cuenta unidades). Ver D-11. |
| X-29 | importante | DISENO §13; 01 §7.2; 02 §7.3, D4; 03 C-6; 04 §6.1; 05 §4.4 (E08, E09) | Comando `comer`: 03 lo degrada a "Podría" (el consumo es automático); 02 lo mantiene como "ración extra que sube moral y cura poco" con `puede_comer/2` y `efectos_comer/3`; 01 define **efectos por tipo** al comer (cura 2, +1/+2 moral, +2 ataque, +2 defensa) y 04/05 los usan (`v_pecorino_en_las_cuevas`, frases `come(P, Q, Estado)`). No está claro si la ración diaria también aplica el efecto del tipo. | `comer(Tipo)` = ración voluntaria extra con el efecto del tipo y nivel "Debería"; la ración diaria automática solo alimenta (con el penalizador por rancio). Ver D-12. |
| X-30 | importante | 02 §5.5 etapas 6-7; 03 F-10, T-12, §10.2; 04 §9.1, §9.4 punto 3, §11.1 cambio 12, T10; 05 §4.2 (X19, E18) | Sueldos: 02, **automáticos** al llegar a la taberna (etapa 7 del `ir`); 03, "se paga a cada personaje" al llegar y también una tarea `pagar/0` y una línea `pagar.` en la exposición; 04, `pagar` es **acción explícita y opcional** ("cada llegada sin pagar baja 2 la moral"); 05 tiene la clave `puede_pagar_sueldos` (X19) y la falla `hay_queso_para(sueldos)` (E18), que solo tienen sentido con un comando explícito. | `pagar` explícito en la taberna, con `puede_pagar_sueldos/0` explicable; el cobro de contratos sí es automático (04 T10). El impago se evalúa al **salir** de la taberna con sueldos pendientes (−2 moral por miembro). Ver D-14. |
| X-31 | menor | 01 §3.1, §5; 03 F-03; 04 §9.1, §7.2 (`t_mantecosa_cuenta`); 05 F08b, T02, cambio 7 | Descanso: 03 F-03, recupera vida y cuesta un día; 02, día + curación; 01, "cuesta queso"; 04, 1 día + **2 quesos** + toda la vida + 1 moral. Además 01, 04 y 05 mencionan una `deuda_taberna`/"cuenta de más de 5 quesos" que **ningún documento define** (cómo se genera). | Descansar cuesta 2 quesos (04); si no hay, falla `puede_descansar` y lo explica `por_que_no`. Descartar `deuda_taberna` y las frases F08b y T02 (05 cambio 7 ya lo permite). Ver D-15. |
| X-32 | importante | 01 §7.1, §7.3, §11.5; 02 §3.4; 03 F-08; 04 §9.1 | Unidades o valor: 01 propone pagar **por valor** (precios "en valor de queso", sueldos y compras con la suma de valores, más rancio primero); 04 usa **unidades** ("caso pesimista"); 02 no lo especifica (`efectos_sueldos` "gastar hasta cubrir"; `valor_despensa/1`); 03 pide que el valor "se vea" en F-08. Si todo se paga en unidades, el valor por estado (curado = valor + 2) **no interviene en ninguna decisión del jugador** salvo contratos que exijan estado y la demostración de `explicar`. | Unidades en v1 para sueldos y recompensas (la tabla de 04 queda válida); `valor_queso/3` se mantiene para la presentación y para precios de tienda en la versión extra. Ver D-13. |
| X-33 | importante | 01 §3.2 ("vender queso"), §5 (Ricota "compra queso curado barato", la tienda "compra quesos"), §7.2 (gouda: "Tienda, caravanas"), §7.3 ("precios en valor de queso"); 03 F-27 ("Comprar y vender queso"); 04 §11.1 cambio 8 (equipo solo por contratos, tienda opcional); 05 §4.4, §6 (eventos que dan y quitan queso) | **El queso es la única moneda y a la vez la comida, por lo que "comprar queso" no tiene sentido**: ¿con qué moneda? 01 hace que Ricota "compre queso curado barato" y "venda pan duro caro", sin que exista otra moneda; el gouda "de tienda" y F-27 repiten el problema. Las entradas y salidas de queso están repartidas y nunca se contabilizan juntas (tabla abajo). Si hubiera trueque entre tipos con una tasa fija se abriría una vía de arbitraje; la venta de objetos no existe en ningún documento. | Regla coherente propuesta (D-10): el queso **solo entra** por recompensa de contrato, botín, hallazgos (`rebuscar_bolsillos`, `recoger`, eventos) y **nunca se compra con otro bien**; la tienda (extra) vende **objetos no queseros** a cambio de queso (precio en unidades, pagando primero lo más rancio) y no existe "vender queso". En v1 no hay tienda (04 cambio 8). Ajustes: Ricota solo "recibe" el queso curado como objetivo del contrato `silvestre_para_ricota`; el gouda y similares aparecen como recompensa o hallazgo; F-27 se redacta como "tienda de objetos". |

**Entradas y salidas de queso según los documentos** (para X-33):

| Entra | Fuente | Sale | Fuente |
|---|---|---|---|
| Recompensa de contratos (7 a 40 quesos) | 04 §3, 01 §5.1 | Ración diaria (4 por día) | 02 §5.5, 04 §9.1 |
| Botín: +1 por enemigo con `lleva_queso` derrotado | 04 §9.1 (en 01 `lleva_queso` solo marca objetivos de `rebuscar_bolsillos`) | Sueldos (5 por pago) | 01 §4.1 |
| `rebuscar_bolsillos` (+1, +2 con ganzúa) | 01 §4.7 | Descansar (2) y banquete (6) | 04 §9.1 |
| `recoger/0` en el bosque (+1 silvestre por visita) | 04 §3.6 | Hechizos de Pimentina (1 cada uno), `silencio_pagado` (1-2) | 01 §4.7 |
| Eventos de Tuerca, ermitaño, "silencio vendido" | 04 §7.2, 05 §6 | Multas y pérdidas (−1 a −3) en consecuencias de contratos y eventos | 04 §3, 05 §6 |
| Premios de arcos (T1 +2) y de eventos de campaña | 04 §5.5, §7 | Robo de las ratas, ganso, peajes | 01 §6, 04 §3.8 |
| **Venta de queso u objetos** | 01 §3.2, 03 F-27 (sin definir) | **Compra de objetos** (precios en valor de queso) | 01 §7.3 (sin tienda en 04) |

La contabilidad de 04 §9.2 (suma verificada: 12 + 133 de cobros + 9 de botín − 100 de comida − 30 de sueldos − 12 de otros = 12) **no incluye** los eventos de 05 ni el forrajeo; el efecto neto de los 19 eventos aleatorios es de ±5 quesos en una partida y no desequilibra, pero conviene registrarlo.

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-34 | menor | 01 §7.1, §7.2; 03 F-08 | El criterio de 03 ("la rancia vale menos que ambas") es falso para `requeson` y `queso_silvestre`: su valor base es 1, y el rancio vale 1 (fresco = rancio). | Cambiar el criterio a "la rancia vale como máximo lo que la fresca" o poner el valor del rancio en 0 para tipos de base 1. |
| X-35 | menor | 04 §1.3, §3.6, §3.16, §9.2, §9.3 | Incoherencias internas: (a) `silvestre_para_ricota` exige 3 `queso_silvestre` y `recoger/0` da **uno por visita**, pero la ruta de 26 días visita el bosque **una sola vez** (día 10); (b) la ruta "completa (15 contratos)" de la tabla del día a día incluye 12 contratos + jefe = 13 (faltan `cena_de_eustaquio` y `pelea_de_taberna`); (c) "recomendada: 11 contratos (todo menos reconocimiento, cena y pelea)" son 12 contando el jefe; (d) T3 dice "tres contratos de pueblo" cuando `peaje_del_ganso` también está desde el día 1. Las sumas de la tabla (133, 9, 100, 30, 12) y los saldos diarios sí son correctos. | Dar 3 silvestres de una visita (`recoger` hasta 3 en un día) o aceptar 3 visitas en la ruta; corregir los recuentos de rutas y T3. |

### 2.4 Contratos y campaña

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-36 | importante | DISENO §7; 02 §3.5, §4.1; 03 F-12; 04 §3.1, §10.1, §11.2 | Forma de `contrato/5`: el canon tiene `escoltar(gallina_noble)` y `recompensa(quesos(5))`. 04 usa `escoltar(gallina_noble, castillo)` (otra aridad), objetivos nuevos (`eliminar/1`, `evento/1`, `escuchar/2`, `reunir/3`, `recuperar/1`, `derrotar/1`), `recompensa(Lista)` con `queso/3`, `objeto/1`, `descansos_gratis/1`, y 8 hechos auxiliares (`oferente/3`, `aparece/2`, `resolucion/3`, `consecuencia/3`, `enemigos_de/2`, `reintentable/2`, `prohibido/2`, `tipo_contrato/2`, `dificultad/2`). 02 define la **vía** con `via_objetivo/2` (solo `combate(Grupo)` o `evento(Id)`), `resultado/3` y `consecuencias/3`; 04 llama `resolucion/3` a sus datos, `cumple/1` a lo que 02 llama `condicion_cumple/1`, y `aplicar/1` a lo que 02 llama `aplicar_efectos/1`. | Mantener la aridad 5 del canon; `Objetivo` con el vocabulario cerrado de 04 y una tabla `via_objetivo/2` que lo traduzca (`eliminar` y `derrotar` a `combate`; `escuchar`, `reunir` y `recuperar` a `evento`, solo en la versión ampliada). Nombres: datos `resolucion/3`, regla `resultado/3`, condición `condicion_cumple/1`, efectos `aplicar_efectos/1`. Aceptar `recompensa(Lista)` y mantener `recompensa(quesos(N))` como abreviatura. |
| X-37 | importante | DISENO §7; 01 §5.1, §7.3 (venda); 03 C-3; 04 §3.9, §3.18, §10.1, §11.1 cambio 1, T5; 05 F10b y cambio 11; 02 §10.2, §11.2 | `rasgo_no(teme_caballos)` bloquea siempre el contrato con Baldomero en la compañía. Tres resoluciones: 03 C-3, "miembro designado" o "algún miembro disponible"; 04, se evalúa contra todos los miembros activos **que no ignoren el miedo** (la `venda_de_caballos`); 05 F10b supone que Baldomero presente impide escoltar. Además 04 es inconsistente: la condición "legible" menciona un enemigo de clase `caballo` en el contrato, pero la regla formal `cumple(rasgo_no(R))` **no mira enemigos**, y el tutorial T5 promete mostrar "`teme(baldomero, caballo)` y el enemigo `bandido_montado`", que esa regla no produce. 02 deriva `teme/2` solo del rasgo, sin la venda. | Adoptar 04 (la venda), y: (a) `teme(A, caballo) :- rasgo(A, teme_caballos), \+ ignora_miedo(A)` para que `puede_atacar` y `rasgo_no` usen la misma regla; (b) escribir la condición legible y T5 según lo que de verdad produce la regla (`rasgo(baldomero, teme_caballos)` y `\+ ignora_miedo(baldomero)`), o bien añadir el chequeo de `enemigos_de/2`. 03 C-3 queda sustituida. |
| X-38 | importante | 04 §3.9, §10.1; 02 §8.1, §8.4; 03 F-13 | La escolta de `gallina_noble` hace de Clotilde una "aliada pasiva con vida 10, defensa 0 que no actúa" y un "imán de golpes" para la IA enemiga. 02 solo modela combatientes `jugador` (miembros de la compañía, con catálogo en `personaje/7`) y `enemigo`; 03 no la menciona. Además el resultado depende de su vida final (≥ 6, 1-5, 0). | Modelar a Clotilde como combatiente temporal del bando jugador (`combatiente(clotilde, jugador)`, sin turno, con `vida_max` del contrato) o, en la versión mínima, simplificar: el contrato se resuelve por vida del grupo y un contador de golpes recibidos por Clotilde. +1,5 h (D-33). |
| X-39 | menor | 02 §3.5 (`resultado(+Id, +Contexto, -Res)`); 04 §3, §10.1 | Los resultados a medias de 04 dependen de datos de combate o de evento que no están en el estado: quesos robados por las ratas (≥ 4), vida de Clotilde, Rufino `cantando` durante el viaje, uso de `fondue_flamigera`, número de intentos del evento, número de muestras de la cata. 02 deja el `Contexto` sin definir. | Registrar los contadores necesarios como `contador/2` o `marca/1` durante el contrato y definir `Contexto` como esa lista. En la versión mínima, limitar los resultados "a medias" a dos condiciones medibles. |
| X-40 | importante | DISENO §13; 02 §5.2, §7.3, C8; 03 C-5, C-9; 04 §3, §11.1 cambio 5; 01 §7.2; 05 §4.3 (C19) | Comandos sin acuerdo. 04 añade `elegir/1`, `escuchar`, `catar`, `recoger`, `pagar`, `banquete`; 03 añade `demo`; 02 añade `guardar/1`, `cargar/1`, `reiniciar`, `nivel`, `arbol/2`. **Nadie define** `lanzar` (queso rancio, 01 §7.2 y 05 C19), `equipar`, `comprar`/`vender`, `ayuda(Tema)` ni cómo elegir entre `fondue_flamigera` y `raclette_curativa` (02 solo tiene `habilidad` y `habilidad(O)`). Las fases permitidas de 02 §5.2 no incluyen ninguno de los nuevos. | Conjunto mínimo (D-20): `elegir/1` y `pagar`; todo lo demás es opción de `elegir` o va a "extra". Un solo comando de habilidad con la forma `habilidad(Objetivo)` (una habilidad por personaje en la versión mínima). Actualizar la tabla de fases. |
| X-41 | menor | 01 §5.1; 04 §3.15; 05 F10c, F10d | `despensa_real`: 01 dice "haber hecho 3 contratos y tener `llave_mohosa` (extra)"; 04 deja la llave como variante dura (extra) y no la exige; la frase F10c de 05 (`falla(requiere(objeto(llave_mohosa)))`) asume que sí. F10d usa `contratos_cumplidos(N)` (ver X-18). | Renombrar las claves; F10c solo se activa en la variante dura. |

### 2.5 Combate y mundo

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-42 | importante | DISENO §8; 01 §6.2; 02 §6.12, §8.5-8.6; 03 F-16; 04 §8.3 | IA enemiga: 02 desarrolla la IA **genérica de tres reglas** (`curarse`, `atacar`, `defender`) con su gemela `regla_ia/3` y el registro "prioridad 2 de 3"; 01 define un **perfil por enemigo** (11 acciones: `robar_queso`, `contaminar`, `curar_aliado`, `cobrar_peaje`, `apuntar`, `embestir`, `esporas_curativas`, `invocar_moho`...); 04 añade para el jefe una cláusula `monologo`, modificadores propios, aura y arcos. Añadir los perfiles a `accion_enemigo/2` rompe la gemela, el oráculo de pruebas y la lectura "N de 3". Una tercera línea de 01 §6.2 (regla 3 del jefe) está mal redactada ("rancio o rancio en despensa"). | Versión mínima: `accion_enemigo/2` canon de tres reglas más **como máximo** tres acciones especiales (`robar_queso`, `embestir`, `invocar_moho`), cada una con su cláusula y su gemela. El resto de perfiles, el monólogo y el aura pasan a extra. |
| X-43 | importante | 01 §4.7, §10.4; 02 §3.6, §8.4; 04 §5, §8.3 | Habilidades: el daño del canon `max(1, Atq - Def + M)` no cubre `fondue_flamigera` (daño fijo 8, ignora defensa, +2 con rancio), ni `carga_heroica` (+4 y defensa -1 un turno), ni curaciones. 02 solo define `efectos_accion/3` y `puede_usar_habilidad/2` sin las fórmulas. Pimentina y Rufino tienen **dos** habilidades en 01 y 04, pero el comando solo admite `habilidad(O)`. | Añadir a `combate` una tabla `efecto_habilidad(Hab, Efectos)` de datos (como el resto) y, en la versión mínima, una habilidad por personaje. |
| X-44 | importante | 01 §10.9; 02 §5.3 vs §10.2, R11, D7; 03 F-26; 04 §8.5, §11.1 cambio 10; 05 C16, I03 | Caídos y derrota. 02 se contradice: §5.3 manda a `fin` si nadie puede combatir "fuera de combate", y §10.2 dice que fuera de combate se puede seguir viajando para evitar bloqueos. D7 propone desmayo hasta `descansar`. 04: tras el combate los caídos se levantan con 1 de vida y los finales miden `miembros_en_pie` al acabar. 03: derrota si "la compañía cae o se queda sin queso ni dinero que pagar". Ids de derrota: `fin_derrota(sin_miembros)`/`sin_queso` (05), `derrota_combate`/`derrota_hambre`/`derrota_plazo` (04). | Adoptar 04: `caido` solo existe dentro del combate; al terminar se levantan con 1 de vida; derrota en combate = todos caídos (`derrota_combate`); `derrota_hambre` = al empezar el día `queso_total = 0` y nada por cobrar. El hambre no baja la vida de nadie por debajo de 1. Un único conjunto de ids de derrota (los de 04) y 05 los adopta. Ver D-17. |
| X-45 | menor | 02 §7.3, §10.2; 03 F-15; 04 §3.15 | Huir del jefe: 02, "no se puede huir de un jefe"; 04, "se puede `huir`, el jefe se cura". | No se puede huir del jefe (más simple; 02). |
| X-46 | importante | 01 §7.3; 03 F-15, F-27; 04 §11.1 cambio 8; DISENO §8 (IA `tiene(E, pocion)`) | Consumibles (`pocion`, `cataplasma`, `pan_duro`, `suero_fermentado`, `tapones_de_cera`) se compran en tiendas (01). Si no hay tienda (03 F-27 "Podría", 04 cambio 8), **no tienen ninguna fuente** y `usar` (03 F-15) no tendría objetos que usar; la poción es canon de la IA enemiga. | Sin tienda, los consumibles se obtienen como recompensa o botín (p. ej. 1 `pocion` de recompensa en `ratas_del_granero`); `usar` queda en "Debería" y la poción como objeto de enemigo. |

### 2.6 Alcance y coherencia general

| ID | Grav. | Documentos y secciones | Qué dice cada uno | Resolución propuesta |
|---|---|---|---|---|
| X-47 | importante | 03 F-14, F-07, C-4 | F-14 (Debe) exige que "cada uno de los cuatro personajes" tenga una habilidad con un efecto distinto "que respeta su rasgo", pero los rasgos de Rufino y Tuerca (F-07) son "Debería" y C-4 los degrada. | F-14 mínimo: 4 habilidades sencillas (daño, daño con queso, +1 moral, +1 queso). La lógica completa de `cantando`/`silencio_pagado`/`manos_largas` queda en F-07. |
| X-48 | importante | 03 F-11, §13.2 punto 3; 01 §8 ley 4; 02 §3.3; 04 §9.5; 05 §4.2 (F02), §4.4 (E14-E16) | La huelga es "Debería" y la tercera cosa que se recorta, pero la usan los sueldos, la moral, las rutas degeneradas de 04, seis frases de 05 y `puede_combatir`. Sin huelga, el impago solo baja un número y los sueldos pierden mordiente. | Pasar F-11 a "Debe" (1 h): `esta_en_huelga/1` es una regla derivada y es una de las mejores demostraciones de `por_que_no`. |
| X-49 | importante | 03 F-17, §13.2 punto 10; 01 §6; 04 §8.1 | Bestiario: 03 pide ≥ 5 tipos y permite bajar a 3 + jefe (contradiciéndose); 01 diseña 12; 04 necesita, solo para el camino del jefe con todas sus ramas, `murcielago_azul`, `moho_saltarin` y `golem_de_queso_duro` además de los 4 enemigos de los contratos núcleo y el jefe: 8 tipos. | Mínimo 5 tipos (`rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort`) y sin ramas de entrada ni puerta interior (sección 5). |
| X-50 | bloqueante | 03 §2, §4, §6 (58,5 h); 01-05 en conjunto | La carga declarada de "Debe" (43 h de motor + 8 de F-32/F-33/F-34 = 51 h; 58,5 h con reserva, playtest y balance) no incluye `estado`/`juego`/`parser`, `pagar`, `elegir`, la mecánica del narrador (selección, rotación, nombres con artículo, tests de placeholders), la IA por tipo, los finales múltiples, la escolta con aliado ni la HUELGA como "Debe". Estimación del revisor: la versión que hoy piden los documentos sobre el mismo núcleo ronda las **65 h**, y el contenido completo de 01-05 **150-170 h** (sección 5). Disponible: 50-62 h (8-10 h/semana, 6 semanas más la sesión previa). | Aplicar el recorte de la sección 5 **antes** de empezar; confirmar la dedicación real (D-01). |
| X-51 | menor | 03 §8.3; 04 §1.3, §11.1 cambio 11 | Duración: 03, "12-25 días hasta el jefe, 15-30 minutos"; 04, "9-26 días; 15-60 minutos" según la ruta. | Aceptar el cambio 11 de 04 y medir en PT-1. |
| X-52 | menor | 04 §3.8, §7.1-7.2; 05 §6.3-6.4, §3.1 | Eventos duplicados: peaje del ganso (contrato, enemigo `cobrar_peaje`, `v_ganso_tasa` −2 queso, `ganso_peaje` −1 queso); visita de Pecorino (`v_pecorino_ronda` y `visita_de_pecorino`, más el gag `pecorino`); Tuerca encuentra queso (`t_tuerca_cuenta`, `tuerca_encuentra`, arco T1); ermitaño (`regalo_del_ermitano` y `paz_del_moho`); `trebol_hallado` (05) frente a la recompensa de `cena_de_eustaquio` (04); `charla_de_eustaquio` y `gato_caido` compiten con sus contratos. | Los eventos deterministas de 04 mandan; de los aleatorios de 05 se eliminan los que duplican (`ganso_peaje`, `visita_de_pecorino`, `trebol_hallado`, `charla_de_eustaquio`, `gato_caido`). |
| X-53 | menor | 01 §2.4; 04 §7.2 (`t_registro_sube`), §8.5 (puestos 12 y 31); 05 §3.2, I02b, cambio 10 | Puesto del Registro: 05, `47 - contratos_cumplidos` con mínimo 41; 04, sube un puesto cada 3 contratos y los finales dicen puesto 12 (leyenda) o 31 (chapuza); I02b de 05 dice "sube un puesto". | Puesto en partida: fórmula de 05; en el final, el puesto del texto del final (12, 31, etc.) sustituye al cálculo. Aceptar. |
| X-54 | menor | 01 §4; 05 §1.2, §4; 04 §2.1 | 05 fija "segunda persona del singular (tú)" para el jugador, pero sus propias frases usan "vosotros" (I02b "Lo habéis logrado", C18c "Os retiráis", F08b "Debéis ~w") y 04 usa "tenéis, entrad". | Regla: tú para el jugador y vosotros solo cuando el narrador habla del grupo. Revisar al convertir las frases. |
| X-55 | menor | 05 §4, §7.7 | El banco declara 253 frases (X = 46) pero las tablas contienen **254** (X tiene 47 filas); el núcleo mínimo de 32 frases (§8.4) sí suma 32. | Corregir el recuento. |
| X-56 | menor | 04 §1.2 (comentario "con corte o once/1"); 02 §1.3 | El comentario dice que el orden de las cláusulas de `acto/1` obliga a usar corte u `once/1`, que 02 prohíbe fuera de la IA. Pero las cinco cláusulas del boceto ya son **mutuamente excluyentes** (condiciones sobre `contratos_cumplidos(N)`, `contrato_activo(despensa_real)` y `en_zona(cuevas)`). | Borrar el comentario; no hace falta corte. |
| X-57 | menor | DISENO §11.3; 01 §11.11; 02 §6.3, §14; 03 F-13, F-19 | La demo del canon usa 11 − 5 = 6, pero `bandido_torpe` tiene defensa 2 (daño 9); 02 §6.3 escribe `defensa(bandido_torpe, 5)` y `6 is max(1, 11-5+0)` para ese enemigo, y 03 F-19 espera "D = 6". | No cambiar el contenido: cambiar el ejemplo de la demo a `D = 9 (11 − 2)` o escoger un enemigo con defensa 5. Los criterios aritméticos de 03 F-13 (11−5 = 6; 2−9 → 1) son pruebas unitarias y siguen valiendo. |

### 2.7 Anexo: nombres canónicos propuestos

| Concepto | Nombres encontrados | Propuesta |
|---|---|---|
| Viaje | `puede_viajar`, `puede_ir`, `conectadas`, `adyacente`, `ir` | `conexion/2`, `adyacente/2`, `puede_viajar/1` |
| Habilidad | `puede_habilidad`, `puede_usar_habilidad` | `puede_habilidad/2` |
| Huelga | `huelga`, `esta_en_huelga` | `esta_en_huelga/1` |
| Combate permitido en zona | `puede_combatir(taberna)` | `permite_combate/1` |
| Combate permitido a personaje | `puede_combatir(Id)` | `puede_combatir/1` |
| Estados | `aturdido`, `estado(P,E)`, `alterado/3` | `alterado/3` + derivados `aturdido/1`, `cantando/1`, `apestado/1` |
| Objetos | `lleva/2`, `lleva/3`, `tiene_objeto`, `posee` | `lleva/3` (inventario) y `equipado/2` |
| Miembros | `miembro`, `en_compania`, `activo`, `en_pie` | `miembro/1`, `activo/1`, `en_pie/1` |
| Contratos | `cumplido`, `contrato_cumplido`, `contrato_cerrado`, `resultado_contrato` | `contrato_cerrado/2` + derivados |
| Queso | `estado_queso`, `categoria_queso`, `queso_total` | `categoria_queso/2`, `queso_total/1` (añadir a 02) |
| Efectos | `aplicar_efecto(s)`, `aplicar`, `actualizar_*` | `estado:aplicar_efectos/1` |
| Condición de contrato | `cumple`, `condicion_cumple` | `condicion_cumple/1` |
| Datos de resolución | `resolucion/3`, `resultado/3` | datos `resolucion/3`, regla `resultado/3` |

Traducción de efectos (X-03): `perder_queso(N)` es `gastar_queso` del más rancio; `dar_queso(T,E,N)` es `ganar_queso(T,E,N)`; `moral(grupo,N)` es un `mod_moral(Id,N)` por miembro; `moral(P,N)` es `mod_moral(P,N)`; `vida(P,N)` es `dano`/`curar`; `cobrar(todo)` es `contrato_cobrar(C)`; `envejecer_lote_mas_curado(N)` es nuevo (`envejecer_lote/1`); `marcar(F)` es nuevo (`marcar/1`).

### 2.8 Cambios obligatorios por la decisión de usar SWI-Prolog 5.10.4

Decidido por el autor: se usa solo el subconjunto de 5.10.4. Lo siguiente deja de ser propuesta y es **obligatorio** al aplicar las resoluciones a los documentos (el resto de la sección 2 sigue siendo propuesta). Comprobado en este equipo que **no existen**: `foldl/4`, `sum_list/2` (existe `sumlist/2`), `max_member/2`, `sort/4`, `random_between/3`, `random_member/2`, `split_string/4`, `atom_string/2`, `read_term_from_atom/3` y las lambdas `yall` (`>>`); las comillas dobles producen listas de códigos; `predicate_property(_, defined)` no devuelve éxito.

| # | Documento y sección | Qué depende de algo inexistente o distinto | Sustitución recomendada |
|---|---|---|---|
| O-1 | 05 §5.2 (estrategia E), §6.2 (`evento_del_dia/2`) | `random_between(1, 100, R)`, `random_member(Id-Des, Posibles)` y `set_random(seed(S))`. Las dos primeras no existen. | Usar el LCG de 02 §4.4: `tirada(100, S0, R, S1)`, `R1 is R + 1`, `R1 =< P`; elegir con `length/2`, `tirada(N, S1, I, S2)` y `nth0(I, Posibles, Elegido)`. La semilla vive en `estado` (`semilla/1`, `fijar_semilla/1`). Borrar `set_random`. |
| O-2 | 02 §6.4 (`s_(pred, ...)`) | `predicate_property(D:G, defined)` no devuelve éxito en 5.10.4, así que el meta-intérprete nunca abriría un predicado del juego. | `( predicate_property(D:G, dynamic) ; predicate_property(D:G, number_of_clauses(_)) )`. Añadir una prueba que cubra un dinámico sin cláusulas (V-01). Actualizar 02 §13.2 (fila de `predicate_property`) y el riesgo R1. |
| O-3 | 02 §13.2 (filas `atomic_list_concat`, `sum_list`, `aggregate_all`, `plunit`) y R4 | Prohíbe `atomic_list_concat` (existe y funciona, y 05 §7.5 lo usa); duda de `plunit` (existe y detecta fallos); recomienda `sumlist/2` implícitamente. | Permitir `atomic_list_concat/3`, `aggregate_all/3`, `plunit`; para sumar, `sumlist/2` o una suma recursiva propia; quitar el "plan B sin plunit" de R4. |
| O-4 | 02 §13.2 (fila `foldl`, `max_member`) y cualquier uso futuro en 03-05 | `foldl/4-6`, `max_member/2`, `sort/4`, `sum_list/2` no existen. (Los cinco documentos hoy **no** las usan: solo las nombran como "evitar".) | Mantener la prohibición. Máximo: `msort/2` + `last/2` o cabeza de lista; ordenar por clave: `keysort/2` o `predsort/3`; recursión con acumulador. |
| O-5 | 02 §13.2 (fila de cadenas y `split_string`), 05 §7.5 (`contraer/2`, `sustituir/4`) | `split_string/4`, `atom_string/2`, `read_term_from_atom/3` no existen; las cadenas con comillas dobles son listas de códigos. | Texto siempre en átomos con comillas simples; para trocear, `atomic_list_concat/3` en modo separar (comprobar V-07) o `atom_codes/2` y recursión. Ningún documento usa comillas dobles ni `yall`: no hay nada que cambiar, pero dejarlo escrito como regla. |
| O-6 | DISENO §11.3; 02 §6.11; 05 §1.5, §4.1, §7.5 | `✔ ✘ ├─ └─` (y `«» ¿`) con la codificación por defecto salen degradados (`✔`, `+-`). | Versión ASCII por defecto de las marcas del árbol (`[ok]`, `[no]`, `\-`, `\|-`); en `ui:iniciar/0`, `set_stream(user_output, encoding(utf8))`; mantener `:- encoding(utf8).` en los archivos con texto visible. Comprobar la consola de Windows (`chcp 65001`) con V-06. |
| O-7 | 02 §13.1, R4, D1; 03 C-7, T-01, F-34; DISENO §17 | Todos prevén desarrollar en 9.x o dudan de la versión. | Texto único: "SWI-Prolog 5.10.4, versión del curso" en README, DISENO §17-18 y T-01; arranque con la ruta de instalación o un alias. |
| O-8 | 02 §13.2 (fila de `format/2,3` con `~p`, `~t~\|`), 05 §7.5 (`format(atom(_), ...)`) | Funcionan los básicos (`~w ~a ~d ~n`, `format(atom(_), ...)`); `~t~\|` y `~p` sin comprobar. | Usar solo `~w ~a ~d ~n ~q`; comprobar `~t~\|` antes de depender de él (V-07). |

Funciones que ya se han comprobado que sirven y no requieren cambio: `atomic_list_concat`, `format`, `with_output_to`, `clause/2`, `nth_clause/3`, `strip_module/3`, `meta_predicate`, `maplist/2..5`, `include/exclude/partition`, `predsort`, `msort`, `aggregate_all`, `setof/bagof` con `^`, `assoc`, `nb_setval` (02 no recomienda usar `nb_setval`), `random/1` y `random_permutation` (no se usan, por reproducibilidad).

---

## 3. Cambios propuestos al canon, consolidados

Origen: 01 §11 (12 propuestas, `01-n`), 02 §16 (C1-C15, `02-Cn`), 03 §15 (C-1 a C-10, `03-C-n`), 04 §11.1 (13 propuestas, `04-n`) y 05 §10 (13 propuestas, `05-n`). Total: 63 propuestas. "Coincide" = dos o más documentos proponen lo mismo; "choca" = proponen cosas incompatibles. Ninguno se ha aplicado a `DISENO.md`.

### 3.1 Arquitectura y módulos

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 02-C1, 05-3 | 02: añadir `estado`, `juego`, `parser`, `arbol`. 05: añadir `frases.pl`. | Se suman (15 módulos) | **Aceptar parcial**: `estado` y `juego` sí; `parser` (v1) se funde en `juego`/`ui`; `arbol` se funde en `explicar` (02 lo permite); `frases` pospuesto | 12 archivos bastan; cada módulo extra añade pruebas y capas |
| 02-C5, 02-C6, 05-4 | Hechos dinámicos nuevos; reglas devuelven efectos (datos); estado de presentación del narrador con `actualizar_*` | 02 y 05 chocan en dónde vive el estado del narrador (X-01, X-06) | **Aceptar 02-C5/C6**; **modificar 05-4**: contadores en `estado.pl` | Un único escritor; el narrador sigue puro |
| 03 §12.4 (implícito: 10 módulos y `actualizar_*`) | Mantener 10 módulos y `actualizar_*` repartidos | Choca con 02-C1/C5 | **Rechazar** | Contradice P3 |
| 04-4 | `aceptar/1` en taberna o en la zona del oferente; objetos clave entregados al momento; máximo 3 contratos activos | Compatible con 02 (`parametro(max_contratos, N)`) | **Aceptar** | Reduce viajes |

### 3.2 Meta-intérprete, explicación y narrador

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 02-C2 | Hoja = no es predicado de los módulos del juego (`modulo_juego/1`), en vez de `built_in` | Único | **Aceptar** | `member/2`, `append/3` no son `built_in`; hay que sustituir `predicate_property(_, defined)` (no funciona en 5.10.4) |
| 02-C3, 03-C-8 | 02: formato de prueba ampliado, corte real. 03: el corte es una hoja que triunfa, explicaciones de la primera solución | **Choca** (X-04) | **Aceptar 02-C3 con spike el día 1; rechazar 03-C-8** salvo fallo del spike | La IA con corte es parte de la tesis (Conf. 4) |
| 02-C4 | `diag/4` con `fallo`, `neg_viola`, `builtin_falso`... en vez de `primer_fallo/2` | Único | **Aceptar** con núcleo reducido (`sin_clausula`, `fallo`, `neg_viola`, `builtin_falso`, `tras`) | `limite` y "más cercana" pueden esperar |
| 02-C9 | `explicar` hipotético y retrospectivo (`ultima_prueba/2`) | Único | **Aceptar** | Sin ello "por qué funcionó" no se puede responder |
| 02-C10, 03 F-16 | Gemela sin corte como oráculo; documentar el corte rojo | Coincide en la IA con corte | **Aceptar** | Es material de exposición |
| 02-C12, 05-1, 05-2 | 02: variantes elegidas con semilla/día y `comentario_prueba/3`. 05: `frase/3` con niveles y claves `falla/impide/suceso/...` | Se solapan | **Aceptar 05-1/05-2** como especificación; 02-C12 queda como interfaz | 05 está mejor especificado |
| 05-5 | Regla `calidad_golpe/2` (flojo/normal/fuerte) | Único | **Aceptar** | Barata; da variedad al combate |
| 05-6 | `nombre/2` con artículo y nombres visibles de contratos | Único (faltan los 8 contratos de 04) | **Aceptar** ampliando | Necesario para las frases |
| 05-8 | Textos de eventos en el banco, `eventos.pl` solo con condiciones y efectos | Único | **Aceptar** | Un único almacén (X-07) |
| 05-13 | Frases que citan `ayuda.`, `explicar(...)`, `por_que_no(...)` acopladas a los comandos | Único | **Aceptar** | Acoplamiento controlado |
| 02-C11, 05-9 | 02: símbolos ASCII por defecto. 05: UTF-8 obligatorio y `chcp 65001` | **Choca** parcialmente (X-11) | **Aceptar ambos** con la regla: símbolos de árbol en ASCII por defecto, texto en UTF-8 con `set_stream` | Comprobado en 5.10.4 |

### 3.3 Comandos e interfaz

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 02-C8 | `atacar(O)`/`atacar(A,O)` normalizados; `salir`, `guardar/1`, `cargar/1`, `reiniciar`; `arbol(Acc, Formato)`; `nivel(resumido)`/`nivel(detallado)` separados | Único | **Aceptar** salvo `guardar`/`cargar` (posponer) | Resuelve la incoherencia §13/§11.2 |
| 03-C-5 | `usar` y `huir` pasan a "Debería"; `descansar` explícito como Debe | Único | **Aceptar** | Prioridad real |
| 03-C-6, 02-D4, 01 §7.2, 04 | `comer`: 03, automático y `comer/1` Podría; 02, ración extra; 01, efectos por tipo | **Choca** | **Aceptar 03-C-6 (ración automática)** y mantener `comer/1` como "Debería" con la semántica de 02 | X-29 |
| 03-C-9 | `demo` y forma de fijar la semilla | Único | **Aceptar** como meta-comandos de `main` | Demo reproducible |
| 04-5 | `elegir/1`, `escuchar`, `catar`, `recoger`, `pagar`, `banquete` (alternativa mínima: solo `elegir/1`) | Único | **Aceptar** `elegir/1` y `pagar`; **posponer** el resto | Cada comando extra cuesta código y pruebas |
| 04-12 | `pagar` explícito; impago −2 moral por llegada | Choca con 02 (automático) | **Aceptar** con impago evaluado al salir | X-30 |
| 02-C13, 03-C-1 | Adelantar `por_que_no` (S3) y cerrar el núcleo en S4 / calendario de 03 | Se solapan | **Aceptar 03-C-1** como maestro | Cubre S0-S6 completos |
| 03-C-2 | Separar `arbol/1` en texto (Debería) de Graphviz (Podría) | Único | **Aceptar** | Evita depender de Graphviz |

### 3.4 Economía y reglas del mundo

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 01-1 | 12 cheddar iniciales | Coincide con 04 §2.1, §9.1 | **Aceptar** | Con 5 la primera salida es un castigo |
| 01-2, 04-13 | Sueldos 1+2+1+1 = 5 por pago | Coinciden | **Aceptar** | Confirmado por la tabla de 04 |
| 01-3, 02-C7 | 01: moral 0-10, inicio 6, huelga < 3. 02: umbrales a `parametro/2` | **Choca** en la escala (02 usa 0-100) | **Aceptar 01-3 y 02-C7** con valores 0-10 | X-24 |
| 04-2 | Recompensas escaladas (gallina 12 + brie) | Complementa 01-1 | **Aceptar** | Sin ellas la economía no cierra |
| 01-4 | Umbral de rancio por tipo (extra) | 04 §Supuestos lo rechaza | **Rechazar** (posponer) | Más hechos sin ganancia jugable |
| 01-5 | Pago por valor | 04 lo acepta "parcialmente" | **Posponer** a la tienda extra | X-32; mantiene válida la tabla |
| 04-9 | Reloj narrativo (días 8, 14, 20, 26) y `dia_limite(35)` | Único (extra) | **Posponer** | No es necesario |
| 04-11 | Métricas de duración 9-26 días y 15-60 minutos | Corrige 03 §8.3 | **Aceptar** | Es lo que resulta de las rutas |
| 04-8 | Equipo como recompensa de contratos; tienda opcional | Compatible con 03 F-27 "Podría" y con X-33 | **Aceptar** | Sin tienda en v1 |
| 05-7 | Estado `deuda_taberna/1` | Único | **Rechazar** | X-31: nadie lo define |
| 05-10 | Puesto del Registro = 47 − contratos (mín. 41) | Choca levemente con 04 | **Aceptar** | X-53 |

### 3.5 Combate, rasgos y contratos

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 01-6 | Atributos `clase` y `alcance` | 02 §8.2 lo supone | **Aceptar** | La regla de filas lo necesita |
| 01-7 | Ley de la Taberna (sin combate) | 04 la usa | **Aceptar** renombrando a `permite_combate/1` | X-14 |
| 01-8, 01-9 | Estados `apestado` y `cantando`; detalle de `cobra_por_callar` | 04 los usa | **Aceptar `cantando`** (Debería); **posponer `apestado`** | `apestado` depende de `lanzar` |
| 01-10 | Tuerca en `frente` | Único | **Aceptar** | Equilibra filas |
| 01-11 | Ejemplo del canon usa defensa 5 | Único | **Aceptar** corrigiendo el ejemplo de DISENO §11.3 | X-57 |
| 01-12 | Quinto miembro `recluta_1` (extra) | Coincide con 03 F-28 "Podría" | **Posponer** | Fuera de alcance |
| 03-C-3, 04-1 | `rasgo_no`: 03, miembro designado o alguno disponible; 04, miembros activos sin `ignora_miedo` | **Chocan** | **Aceptar 04-1; rechazar 03-C-3** | X-37 |
| 03-C-4 | Solo los rasgos de Baldomero y Pimentina obligatorios | Coincide con 04 §4 | **Aceptar** | Alcance |
| 03-C-7 | Contratos 6, enemigos ≥ 5 + jefe, 9.x, guardar fuera, exposición en vivo | Parcialmente contra 02-C15 (guardar extra) y X-10 (versión) | **Aceptar** salvo versión (ahora 5.10.4) y contratos (4 + 2 condicionales) | Sección 5 |
| 04-3 | `recompensa(Lista)`, `Zona` = zona del objetivo, hechos auxiliares y tres resultados | Único | **Aceptar** con los nombres de X-36 | Hace implementables las consecuencias |
| 04-6, 04-7 | Regla `monologo` y modificadores del jefe; `lleva_queso` del jefe con T3 | Únicos (extra) | **Posponer** | X-42 |
| 04-10 | Los caídos se levantan con 1 de vida al acabar el combate | **Choca** con 02-D7 (desmayo) | **Aceptar** | X-44 |

### 3.6 Plan, pruebas y versión

| Cambios | Qué propone cada uno | Relación | Recomendación | Motivo |
|---|---|---|---|---|
| 02-C14 | Oráculo con/sin corte, propiedades con semilla, prueba de arquitectura, prueba de alias | Único | **Aceptar** el oráculo; **posponer** propiedades y arquitectura | El oráculo es lo que se exhibe |
| 02-C15, 03-C-7 | Guardar/cargar: 02, extra de S5-S6; 03, fuera de v1. Versión: subconjunto 5.10.4/9.x frente a 9.x | **Chocan** parcialmente | **Posponer guardar/cargar**; versión: **5.10.4** | D-02, D-32 |
| 03-C-10 | Orden estándar de pruebas y `tests/todas.pl` | Choca con `run_all.pl` de 02 (X-08) | **Aceptar** | Ya lo cita 05 |
| 05-3 (ver 3.1), 05-11, 05-12 | Dependencias entre documentos | Se resuelven con este documento | **Aceptar** (cumplido) | — |

---

## 4. Decisiones abiertas para el autor

Ordenadas por urgencia. D-01 a D-10 bloquean o condicionan el código de la semana 1; D-11 a D-22, las semanas 2-4; D-23 en adelante, el contenido y la entrega. "Impacto" indica qué documentos hay que tocar.

| ID | Pregunta | Opciones | Recomendación | Impacto |
|---|---|---|---|---|
| D-01 | ¿Cuántas horas semanales reales hay, y qué nivel de recorte se aplica? | A) 10 h/semana y recorte "Nivel A" (sección 5: ≈ 65 h). B) 8-9 h/semana y "Nivel B" (≈ 57 h). C) Mantener el alcance de los documentos (≈ 150 h; inviable). | Fijar hoy la dedicación; empezar con A y pasar a B el primer viernes con desvío > 3 h. | 03 (backlog y recorte), 04 (contratos), 05 (banco) |
| D-02 | **DECIDIDA por el autor:** versión de SWI-Prolog. | Se desarrolla y entrega con **SWI-Prolog 5.10.4** (la del curso), usando solo el subconjunto que funciona en ella. | No queda abierta. Obligatorio: aplicar la tabla 2.8 (sustituciones) y documentar en el README la versión, la ruta (`C:\Program Files\pl\bin`, fuera del PATH) y la orden de arranque. Solo queda pendiente confirmar con la profesora que la evaluación usa la misma versión (D-35). | 02 §13, 03 C-7 y T-01, 05 §5-7, README |
| D-03 | ¿Qué es un comando? | A) Término validado por un parser y ejecutado por `juego:ejecutar/2` (02). B) Predicado invocable con `call/1` (03). | A. | 02 intacto; reescribir criterios F-03, F-04, F-12 de 03; README |
| D-04 | ¿Quién escribe en la base de datos? | A) Solo `estado.pl` (02). B) Cualquier módulo con `actualizar_*` (03). | A, con `actualizar_*` como auxiliares privados. | 03 F-02, 05 §5, 04 §10.4 |
| D-05 | ¿Qué vocabulario de efectos se adopta? | A) El de 02 §4.5 ampliado. B) El de 04. C) El de 05. | A, con traductores de 04 y 05 (X-03). | 02 §4.5, 04 §10, 05 §6 |
| D-06 | ¿Cómo trata `solve/2` el corte? | A) Corte real (02 §6.5). B) Hoja que triunfa (03 C-8). | A, con spike el primer día; si falla, B y excluir la IA de la equivalencia. | 02, 03 F-18, T-13, T-40 |
| D-07 | ¿Cuántos módulos? | A) 12: los 10 del canon + `estado` + `juego`, con `parser` en `juego`/`ui` y `arbol` en `explicar`. B) 14-15 (02 + 05). C) 10 (03). | A. Separar `parser`/`arbol`/`frases` solo si el archivo crece mucho. | README, stubs de `src/` (crear `estado.pl` y `juego.pl`) |
| D-08 | ¿Escala de moral? | A) 0-10, inicio 6, huelga con moral ≤ 2 (01, 04). B) 0-100, huelga ≤ 20 (02). | A. | 02 §4.2, §5.5; 03 F-10 |
| D-09 | ¿Queso inicial y escala de recompensas? | A) 12 cheddar y recompensas de 04. B) 5 cheddar y recompensas del canon. C) 5 cheddar y ración de 1 queso por 2 miembros. | A. | DISENO §6-7, 02 `inicio/1`, 01 §5 |
| D-10 | ¿Qué papel tiene el queso como moneda, de dónde entra y adónde sale, y existe tienda? | A) **Regla recomendada**: el queso solo entra por recompensa, botín y hallazgos (Tuerca, forrajeo, eventos); solo sale por ración, sueldos, descanso, habilidades y multas; no se compra ni se vende queso; **en v1 no hay tienda** (equipo por contratos, 04 cambio 8); en la versión extra, la tienda vende solo **objetos no queseros** a cambio de queso (precio en unidades, pagando antes lo más rancio). B) Trueque entre tipos con tasa desfavorable (p. ej. 2 unidades de un tipo por 1 de otro, o 1 por 1 con comisión de 1) para impedir el arbitraje; sin comprar con otro bien. C) Moneda aparte (monedas): rompe la premisa. | A. Consecuencias: Ricota no "compra queso" (solo recibe los quesos curados del contrato); el gouda sale de recompensas; F-27 se reescribe como "tienda de objetos"; los consumibles se obtienen como recompensa o botín (X-46); `saldo` de la tabla de 04 sigue siendo válido. Si se quiere una pizca de mercado, B en la versión extra. | 01 §3.2, §5, §7.2-7.3; 03 F-27; 04 cambio 8; 05 (E06, E07) |
| D-11 | ¿Qué queso se come en la ración diaria? | A) Fresco → curado → rancio (02). B) El más viejo primero (03, 04). C) El jugador elige. | A, porque mantiene rancio en la despensa (lanzar, Hedor, jefe, moho). Reescribir 04 §9.4 punto 4. | 04 §9.4; 02 §5.5 |
| D-12 | ¿Qué significa `comer`? | A) Ración extra voluntaria con efecto del tipo (curado); la ración diaria solo alimenta. B) Cura simple de cheddar. C) Eliminar. | A, nivel "Debería"; v1 mínima: ración automática y `comer` con efecto "cura 2". | 02 §7.3; 01 §7.2; 05 E08-E09 |
| D-13 | ¿Se paga por unidades o por valor? | A) Unidades (04). B) Valor (01). | A en v1; el valor solo informa y se usará en la tienda extra. | 01 §7.1, 03 F-08 |
| D-14 | ¿`pagar` es automático o un comando? | A) Comando `pagar` en la taberna; impago al salir. B) Automático al llegar (02). | A: da `puede_pagar_sueldos` explicable (05 X19, E18) y es una buena demostración. | 02 §5.5; 03 T-12; 04 T10 |
| D-15 | ¿Cuánto cuesta descansar y existe `deuda_taberna`? | A) 2 quesos, sin deuda. B) Con deuda (hay que definir cómo se genera). | A. | 05 F08b y T02 (borrar); 04 `t_mantecosa_cuenta` |
| D-16 | ¿Se adopta la tabla de nombres canónicos? | A) Sí (2.7). B) Cada documento conserva los suyos y se traduce. | A: aplicar antes de escribir código. | 01, 02, 04, 05 (renombres) |
| D-17 | ¿Cómo funcionan caídos y derrota? | A) Caído solo en combate, se levanta con 1; ids de derrota de 04; `derrota_hambre` con queso 0 y nada por cobrar. B) Desmayo hasta `descansar` (02 D7). | A. | 02 §5.3, §10.2; 05 I03 |
| D-18 | ¿Forma de `contrato/5` y de sus objetivos? | A) Aridad 5 del canon, vocabulario de 04 y `via_objetivo/2` (X-36). B) Contrato simplificado solo con combate. | A, pero la versión mínima solo implementa `eliminar`, `derrotar`, `evento` y `escoltar`. | 02 §3.5, 04 §10 |
| D-19 | ¿Cómo se evalúa `rasgo_no(teme_caballos)`? | A) Miembros activos que no ignoren el miedo (venda) (04). B) Miembro designado (03). | A, con `teme/2` consciente de la venda y texto de T5 corregido. | 02 `teme/2`, 03 C-3, 04 T5, 05 F10b |
| D-20 | ¿Qué comandos nuevos entran? | A) Solo `elegir/1` y `pagar` (más `demo`). B) Todos los de 04. | A. | 02 §5.2, §7.3; 04 §3 |
| D-21 | ¿Qué contenido entra en la versión mínima? | Sección 5. | Nivel A; las cifras de la sección 5. | 01, 04, 05 (marcar extra) |
| D-22 | ¿La huelga pasa a "Debe"? | A) Sí. B) Se mantiene en "Debería" (03). | A (1 h). | 03 F-11, §13.2 |
| D-23 | ¿Cuántas habilidades hay por personaje y qué forma tiene el comando? | A) Una por personaje, `habilidad(Objetivo)`. B) Dos para Pimentina y Rufino, `habilidad(Id, Objetivo)`. | A en v1; B como extra. | 02 §7.3; 01 §10.4 |
| D-24 | ¿Cómo se estructura la IA por tipo? | A) Canon de 3 reglas + 3 acciones especiales. B) Perfil por enemigo (01). | A. | 02 §8.5; 01 §6.2 |
| D-25 | ¿Cómo se gestionan narrador, azar y estado de rotación? | A) Narrador puro; contadores en `estado`; LCG de 02; `frase/3`. B) Narrador con estado y `random_*` (05). | A. | 05 §5, §6; 02 §3.10 |
| D-26 | ¿Salida ASCII o Unicode? | A) ASCII para símbolos, UTF-8 para texto con `set_stream`. B) Unicode completo. | A; comprobar tildes en la consola de la entrega la semana 1. | DISENO §11.3, 02 R3, 05 cambio 9 |
| D-27 | ¿Dónde se guarda el texto visible? | A) Un solo almacén `frase/3`. B) Disperso. | A (puede esperar a la semana 4). | 04 §10, 05 §7 |
| D-28 | ¿Entran los eventos aleatorios? | A) No en la mínima; 5 en el objetivo, sin duplicar los de 04. B) Los 19. | A. | 03 F-25, 05 §6 |
| D-29 | ¿Se puede huir del jefe? | A) No. B) Sí, el jefe se cura. | A. | 04 §3.15, 02 §10.2 |
| D-30 | ¿Cuántos finales y cómo se mide el puesto del Registro? | A) 3 en la mínima (chapuza, derrota_combate, derrota_hambre), 5 en el objetivo. | A. | 04 §8.4; 05 I02 |
| D-31 | ¿Nombres de pruebas y de la orden? | A) `tests/todas.pl` y la orden de 03. B) `run_all.pl` (02). | A; comprobar código de salida. | 02 §11 |
| D-32 | ¿Guardar y cargar partida en v1? | A) No (03). B) Extra de S5-S6 (02). | A. | 02 §9; 03 C-7 |
| D-33 | ¿Cómo se modela a Clotilde en el combate? | A) Combatiente temporal pasivo. B) Contador de golpes recibidos. | B para la mínima, A si hay colchón. | 02 §8.1, 04 §3.9 |

**Preguntas para la profesora** (de 03 §9, T-02, a enviar **antes del 6 de noviembre**):

| ID | Pregunta | Recomendación y por qué |
|---|---|---|
| D-34 | ¿Qué se entrega el 11 de diciembre (código, informe o ambos; formato y extensión) y por qué medio (plataforma, correo, repositorio, `.zip`)? | Preguntarlo ya: condiciona T-43 (informe, 2 h) y T-45. |
| D-35 | Confirmar que la evaluación usa SWI-Prolog 5.10.4 (decidida, D-02). ¿Se pueden usar módulos (`:- module/2`), `library(plunit)` y las bibliotecas `lists`, `apply`, `aggregate`? ¿Se permite `assert/retract` para el estado de la partida? | Importantísima: el diseño entero usa módulos y `plunit` (disponible en 5.10.4), y `assert/retract` aislados en `estado`. |
| D-36 | ¿La exposición es en vivo, de cuánto tiempo, y se espera una presentación con diapositivas? | Recomendación: en vivo, con semilla fija y plan B grabado (03 C-7). |
| D-37 | ¿Cuál es la fecha prevista de la exposición presencial y puede adelantarse? | Condiciona la repetición de PT-3 y el plan B. |
| D-38 | Pregunta adicional del revisor: ¿se valoran las funciones fuera de las conferencias 1-6 (`format/3`, `read_term/2`, `msort/2`, `assoc`)? | Evitaría reescribir código innecesariamente. |

---

## 5. Recorte de alcance recomendado

### 5.1 Contenido: diseñado frente a versión mínima, objetivo y extra

"Mínima" = lo que se compromete (Debe). "Objetivo" = se hace solo si el colchón de S5 (3 h reservadas) está intacto el viernes 27 de noviembre. "Extra" = documentado como ampliación futura, **no** forma parte de la entrega.

| Elemento | Diseñado en 01-05 | Mínima | Objetivo | Extra |
|---|---|---|---|---|
| Zonas | 6 | 6 en datos; 5 con contenido (`bosque` solo de paso) | 6 | — |
| Miembros | 4 + reclutas | 4 | 4 | reclutas |
| Rasgos con regla | 4 | 2 (`teme_caballos`, `hechizos_de_cocina`) | 4 | — |
| Habilidades | 6 (Pimentina y Rufino con dos) | 4 (una por personaje) | 5 (`silencio_pagado`) | 6 |
| Contratos | 15 | **4**: `ratas_del_granero`, `gato_en_el_arbol`, `gallina_noble`, `despensa_real` | **6**: + `peaje_del_ganso`, `fantasma_charlatan` | 9: `silvestre_para_ricota`, `paz_del_moho`, `caballo_fugado`, `degustador_real`, `inspeccion_del_manual`, `reconocimiento_de_cuevas`, `correo_real_perdido`, `cena_de_eustaquio`, `pelea_de_taberna` |
| Enemigos | 12 | **5**: `rata_quesera`, `bandido_torpe`, `bandido_montado`, `moho_saltarin`, `gran_roquefort` | 7: + `ganso_recaudador`, `arquero_aburrido` | 12 |
| Acciones especiales de IA | 11 | 3 (`robar_queso`, `embestir`, `invocar_moho`) | 5 | 11 |
| Objetos | 20 | 2: `venda_de_caballos`, `pocion` | 5: + `cucharon_de_hierro`, `sello_real`, `estoque_de_parmesano` | 20 |
| Tipos de queso | 8 | 2: `cheddar`, `brie` | 4: + `queso_silvestre`, `roquefort` | 8 |
| Tienda | 3 vendedores | No | No | Tienda de objetos (D-10) |
| Estados | 6 | `huelga` (derivado), `caido`, `defendiendo` | + `cantando` | `apestado`, `alerta` |
| Jefe | 3 fases, monólogo, aura, arcos B3/R3/T3 | IA con las 4 reglas de 01 + invocación; sin fases ni entrada de cuevas ni puerta interior | Fase "apurado" y bonus por rancio | Monólogo, aura, arcos, `madurado` |
| Finales | 4 victorias + 3 derrotas | 3: `chapuza`, `derrota_combate`, `derrota_hambre` | 5: + `leyenda`, `quiebra` | 7 |
| Arcos personales | 12 momentos | 0 | 2 (B1 La Venda, R1) | 10 |
| Eventos de campaña (04) | 9 de viaje + 6 de taberna | 1 (`t_bienvenida`) | 3 | 15 |
| Pasos de tutorial | 12 | 6 (T1, T3, T4, T5, T7, T9) | 9 | 12 |
| Eventos aleatorios (05) | 19 | 0 | 5 (`rata_en_la_despensa`, `moho_en_la_despensa`, `tuerca_encuentra`, `mesa_coja`, `cumple_de_un_queso`) | 19 |
| Frases del banco | 254 + 37 coletillas + 23 de eventos | ≈ 70 (las 32 del núcleo de 05 §8.4 + las de viaje, combate básico, hambre, sueldos, inicio y fin) | ≈ 120 | todo |
| Gags | 12 | 0-1 (`caballo`) | 3 (`caballo`, `registro`, `silencio`) | 12 |
| Comandos | ≈ 24 | `ayuda`, `mirar`, `ir`, `descansar`, `contratos`, `aceptar`, `pagar`, `elegir`, `compania`, `inventario`, `atacar`, `defender`, `habilidad`, `explicar`, `por_que_no`, `salir` (16) | + `nivel`, `arbol`, `usar`, `huir`, `comer`, `demo` | `lanzar`, `equipar`, `guardar`, `cargar`, `reiniciar`... |
| Módulos | 15 | 12 | 12 | `parser`, `arbol`, `frases` por separado |
| Funciones de 02 | linter, registro de decisiones de la IA, pruebas de arquitectura y de propiedades, guardado, parser v2, `.dot`, árbol SLD real | `ultima_prueba` (para explicar el turno enemigo), oráculo con/sin corte, `solve`, `por_que_no` | niveles `resumido`/`detallado`, `arbol/1` en texto, linter mínimo | el resto |

### 5.2 Horas (estimaciones del revisor)

| Escenario | Horas | Comentario |
|---|---|---|
| Declarado en 03 (Debe, con reserva de 3 h, playtests y balance) | 58,5 (suma verificada) | Disponible: 50-62 h |
| **Nivel A**: mínima de la sección 5.1, sobre el núcleo de 03 | ≈ 65 | 58,5 + `estado`/`juego`/`parser` (+3,5), huelga a Debe (+1), `elegir/1` y 4 contratos con resolución (+3,5), narrador algo más grande (+1), IA y bestiario (+1), finales (+0,5) menos lo que se recorta de 03 |
| **Nivel B** (emergencia) | ≈ 57 | Nivel A menos: `gato_en_el_arbol` sustituido por `peaje_del_ganso` y sin `elegir/1` (la venda pasa a ser recompensa de `ratas_del_granero`) (−2), `por_que_no` v2 (−1,5), 50 frases (−1), PT-2 e informe más cortos (−1,5), una habilidad menos con efecto especial (−1), `demo/0` sencillo (−0,5) |
| Todo lo diseñado en 01-05 | 150-170 | 03 completo (≈ 77) + extras de 02 (≈ 18) + datos y mecánicas de 01 (≈ 21) + 04 completo (≈ 36) + 05 completo (≈ 13) |

Con **8 h/semana** (≈ 50 h) ni siquiera el Nivel B cabe sin sacrificar documentación; con **10 h/semana** (≈ 62 h) el Nivel A cabe solo si no se gasta el colchón.

### 5.3 Tareas que faltan en el backlog de 03 (a añadir)

| Tarea | h |
|---|---|
| `estado:aplicar_efectos/1` con ≈ 15 efectos y `con_transaccion/1` simple | 2 |
| `juego:ejecutar/2`, tabla de fases permitidas y `objetivo_de_accion/2` | 2 |
| `parser`/lectura de términos con errores de sintaxis (v1) | 1 |
| `pagar` explicable y regla de impago al salir | 1 |
| `elegir/1` y motor de evento mínimo (para `gato_en_el_arbol`) | 2,5 |
| Traductor de diagnósticos a claves del narrador (`clave_de_diag/2`) | 1 |
| Combatiente temporal o contador para Clotilde | 1,5 |
| Finales y condición de derrota por hambre | 1 |

### 5.4 Qué se mueve a "extra" y cómo se documenta

Todo lo de la columna "Extra" se conserva en los documentos 01, 04 y 05 como "contenido ampliable" (no se borra) y el README lo dice abiertamente. La selección de la versión mínima mantiene las dos demostraciones centrales de la exposición: `por_que_no(atacar(baldomero, bandido_montado))` y `por_que_no(aceptar(gallina_noble))`, más `explicar` sobre un turno enemigo con corte.

---

## 6. Siguientes pasos

1. **Hoy (2 de noviembre, ≈ 2 h):** (a) crear un alias o `PATH` para el ejecutable de 5.10.4 (decidida) y anotar la versión en el README; (b) spike R1 de 02: dos módulos, un predicado dinámico, `clause/2` sobre importados, `nth_clause/3` con referencia, if-then-else y un `!` real en el meta-intérprete (esto cierra D-06); (c) prueba de tildes y de `set_stream(user_output, encoding(utf8))` en la consola de la entrega; (d) enviar a la profesora las preguntas D-34 a D-38.
2. **Sesión de decisiones (≈ 1,5 h, antes del jueves 5):** resolver D-01 a D-10 y D-16 a D-22 con las recomendaciones de la sección 4.
3. **Aplicar las resoluciones a los documentos, en este orden:** (1) `DISENO.md` (canon): cambios aceptados de la sección 3, incluida la nueva regla del queso (D-10); (2) un anexo de nombres canónicos (la tabla 2.7), que fijará las claves de 05; (3) 02: moral 0-10, nombres, vocabulario de efectos único, `defined` por `number_of_clauses`, versión 5.10.4, tabla de fases, `objetivo_de_accion` completo; (4) 01: eliminar la compra de queso, `lleva/2`, tabla de atributos; (5) 04: formas de datos, tutorial T5, rutas, recuentos; (6) 05: claves a nombres canónicos, azar con LCG, `random_*` fuera, eventos duplicados fuera, narrador sin estado propio; (7) 03: criterios en términos de comandos, nuevo backlog (sección 5.3), recorte, versión. Los cambios de la tabla 2.8 (O-1 a O-8) se aplican en el mismo paso que la tabla de nombres, porque rompen código de 02 y 05. Máximo 3 h repartidas en la semana 1 (30 minutos por noche); lo que no se aplique queda marcado como "pendiente" en este documento.
4. **Arrancar el código (semana 1 de 03):** `mundo.pl` (hechos) → `estado.pl` (hechos dinámicos y efectos mínimos) → `compania.pl` → `juego.pl` + lectura de términos en `ui.pl` + `main.pl` (`ir`, `descansar`, `mirar`, `ayuda`, `salir`) → spike del meta-intérprete sobre una regla de economía → una prueba plunit y la orden única de pruebas. Etiqueta `v0.1-diseno` al cerrar los documentos.
5. **Control semanal:** cada viernes, comparar horas con la sección 5.2 y aplicar el siguiente recorte el mismo fin de semana (03 §13.2) si el desvío supera 3 h.

---

## 7. Verificaciones pendientes

### 7.1 Ya comprobado en este equipo (SWI-Prolog 5.10.4, 64 bits, `C:\Program Files\pl\bin`, no está en el PATH)

| Dato | Resultado | Afecta a |
|---|---|---|
| `library(plunit)` | Existe y detecta fallos | 02 §11.1 y R4 (ya no hace falta el plan B sin plunit) |
| `atomic_list_concat`, `format` (incl. `format(atom(_), ...)`), `with_output_to` | Funcionan | 05 §7.5 (permitido); 02 §13.2 (relajar la prohibición de `atomic_list_concat`) |
| `clause/2` sobre predicados estáticos y dinámicos | Funciona | 02 §6.4, §6.5 |
| `predicate_property/2` con `built_in`, `dynamic`, `number_of_clauses` | Funciona | 02 §6.4 |
| `predicate_property(_, defined)` | **No devuelve éxito** | 02 §6.4 (línea del `s_(pred,...)`): sustituir |
| `nth_clause/3`, `strip_module/3`, `meta_predicate` | Funcionan | 02 §6.4, §6.5 |
| `maplist/2..5` con predicados normales, `include/exclude/partition`, `predsort`, `msort`, `aggregate_all`, `setof/bagof` con `^`, `assoc`, `nb_setval` | Funcionan | 02 §13.2; 05 §7.5 |
| `random/1`, `random_permutation`, `set_random(seed(N))` | Funcionan | 02 §4.4 (decisión de no usarlos por reproducibilidad) |
| `foldl/4`, `sum_list/2` (sí `sumlist/2`), `max_member/2`, `sort/4`, `random_between/3`, `random_member/2`, `split_string/4`, `atom_string/2`, `read_term_from_atom/3`, lambdas `yall` (`>>`) | **No existen** | 05 §5.2 (E), §6.2: `random_between`, `random_member` hay que sustituirlos; 02 acertaba al evitar el resto |
| Cadenas entre comillas dobles | Son listas de códigos (`double_quotes=codes`) | 02 §13.2 (acierta) |
| `:- encoding(utf8).` | Funciona al cargar | 05 §7.5 |
| Salida de `✔ ✘ ├─` con la codificación por defecto | Se degrada (`\u2714`, `+-`) | 02 C11/R3; DISENO §11.3 |
| `set_stream(user_output, encoding(utf8))` | Salida correcta al redirigir a archivo | `ui.pl`; consola de Windows sin comprobar |

### 7.2 Pendiente de comprobar

| # | Qué | Dónde se afirma | Cómo comprobarlo |
|---|---|---|---|
| V-01 | `clause(M:G, B, Ref)` sobre predicados **importados** de otro módulo y dinámicos; `predicate_property(M:G, imported_from(D))` con exportados; `nth_clause(_, I, Ref)` con `Ref` ligada | 02 §6.4, §6.5, R1 | Spike del día 1 (dos módulos y un dinámico) |
| V-02 | El corte en la rama `then` de `( -> ; )` poda las alternativas de `regla/4` | 02 §6.5, R2 | Mismo spike, con prueba de equivalencia sobre `accion_enemigo` |
| V-03 | Opciones de plunit usadas: `setup/1`, `cleanup/1`, `fail`, `true(...)`, `throws(...)`, `forall(...)` | 02 §11.1 | Escribir una prueba de cada una |
| V-04 | Código de salida de `swipl -q -g run_tests -t halt tests/todas.pl` al fallar y al pasar | 03 F-32, §8.1, 05 §8.2 | Ejecutarlo con una prueba que falla; probar también la orden de 02 con `-s` |
| V-05 | Nombre del ejecutable (`swipl`, `swipl-win`, `plcon`, `pl`) y su arranque con rutas con espacios | 02 §5.1, README | Revisar `C:\Program Files\pl\bin` |
| V-06 | Tildes, `¿`, `«»` y `ñ` en la **consola** de Windows (entrada y salida), con y sin `chcp 65001` | 05 §7.5, 02 §7.2, §13.2 | Prueba de ida y vuelta con `read_term/2`; sin esto, el parser v2 queda descartado |
| V-07 | `upcase_atom/2`, `sub_atom/5`, `last/2`, `nth0/nth1`, `succ/2`, `between/3`, `numbervars/3`, `copy_term/2` | 02 §6, 05 §7.5 | Una consulta de cada una |
| V-08 | `read_term(user_input, T, [variable_names(V)])`, `prompt/2`, `read_line_to_codes/2` (¿devuelve −1 al final de la entrada?) | 02 §3.13, §7.1 | Prueba interactiva |
| V-09 | `set_random(seed(N))` da la misma secuencia entre ejecuciones; propiedades del LCG `S1 is (S0*75+74) mod 65537` (periodo, rango, sesgo con `mod N`) | 02 §4.4, 05 §5.2 | 20 líneas de prueba |
| V-10 | Aritmética: `/` entre enteros, `//`, `mod` con negativos | 02 §13.2 | Consultas rápidas |
| V-11 | Rendimiento y profundidad de pila de `solve/2` (límite 400) con una prueba real de combate | 02 §6.7 | Tras el primer combate |
| V-12 | Las citas de 02 al manual **5.6.59** (secciones sobre `clause/3`, `nth_clause/3`, `strip_module/3`, `export_list`, `->` y corte transparente) | 02 (varias secciones) | El manual no está en el repositorio: revisarlo; la versión instalada es 5.10.4 |
| V-13 | Qué conferencias 1-6 cubren y que el DCG no está en el curso | DISENO §13-14, 02 §14 | Confirmar con el temario o con la profesora (D-38) |
| V-14 | Que `plunit` en 5.10.4 acepta nombres de pruebas como cláusulas `test(nombre) :- ...` con las opciones previstas | 02 §11.1 | V-03 |

Comprobado por lectura y recálculo (no requiere SWI-Prolog): las sumas de 03 (43 h de motor, 9,5 h "Debería", 7,5 h "Podría", 58,5 h de backlog, 11 h de ◇, reparto semanal); la tabla de economía de 04 §9.2 (saldos diarios; 12 + 133 + 9 − 100 − 30 − 12 = 12) y los daños de §9.6; los recuentos del banco de 05 (excepto la fila X: 47 frente a 46) y el núcleo de 32 frases.
