# Banda Chapuza: un RPG de texto en Prolog que explica sus propias reglas

**Informe del proyecto final de Programación Declarativa**

Autor: solerch5510 · Repositorio: <https://github.com/solerch5510/banda_chapuza-lp> · Lenguaje: SWI-Prolog 5.10.4 (la versión del curso) · Entrega: 11 de diciembre de 2026

> Este informe se escribe en Markdown para poder convertirlo después al formato que pida la asignatura (pendiente de confirmar). Todas las cifras y los fragmentos de código se han comprobado contra el repositorio; las salidas del juego son las guardadas en `examples/`, generadas por el propio programa.

---

## 1. Resumen

**Banda Chapuza** es un RPG ligero de texto. El jugador dirige una compañía de cuatro mercenarios incompetentes que cobran en queso: acepta contratos absurdos, gestiona la despensa (el queso es a la vez moneda y comida, y madura), paga sueldos, vigila la moral y pelea por turnos contra cinco tipos de enemigos hasta derrotar al Gran Roquefort.

La idea central es que **el juego entero es un programa lógico**: el mundo son hechos, las reglas son cláusulas y dos **meta-intérpretes** (programas Prolog que ejecutan programas Prolog) permiten preguntar, con la voz de un narrador sarcástico, **por qué** pasó algo (`explicar`) o **por qué no** se pudo hacer (`por_que_no`), mostrando el árbol de derivación de las propias reglas del juego. Esa pregunta no es un añadido: es el motivo de que el proyecto exista.

El resultado es un programa de unas 4 900 líneas en 15 módulos, con **27 suites de pruebas y 1 754 pruebas**, una demostración reproducible y, como extra, un frontend web que usa el mismo motor.

## 2. Introducción y objetivos

Un juego de gestión y combate tiene muchas reglas que dependen unas de otras: quién puede atacar a quién, qué contrato se puede aceptar, qué hace un enemigo en su turno. En un lenguaje imperativo esas reglas acaban esparcidas en condicionales; en Prolog pueden escribirse casi como se dicen en español, y además **se pueden interrogar**. Los objetivos fueron:

1. Aplicar de forma visible los contenidos de la asignatura (hechos y reglas, unificación, resolución SLD, negación como fallo, corte, aritmética, metaprogramación y base de datos dinámica) a un problema con muchas reglas interdependientes.
2. Que el **modo explicar** sea una característica propia y visible, con dos niveles de detalle.
3. Que el juego sea jugable de principio a fin (con jefe final) y gracioso.
4. Que el código se lea como una especificación y esté verificado con pruebas.

## 3. Diseño

### 3.1 Arquitectura

El código está dividido en módulos con una responsabilidad cada uno. La regla de dependencia más importante es que **las reglas del juego no conocen ni la consola ni el narrador**: solo `ui` (consola) y `api` (web) convierten resultados en texto o JSON.

| Módulo | Función | Líneas |
|---|---|---|
| `mundo.pl` | Datos estáticos: zonas, personajes, rasgos, enemigos, parámetros. | 190 |
| `estado.pl` | Estado dinámico. **Único módulo que escribe** en la base de datos. | 346 |
| `compania.pl`, `economia.pl`, `combate.pl`, `contratos.pl`, `eventos.pl` | Las reglas del juego. | 98 · 218 · 472 · 398 · 165 |
| `explicar.pl` | Los dos meta-intérpretes y su traducción a texto. | 576 |
| `juego.pl` | Los comandos: valida y ejecuta. | 695 |
| `narrador.pl` | Banco de unas 130 frases con claves y variantes. | 733 |
| `ui.pl`, `main.pl`, `demo.pl` | Consola, arranque y escenas de la demostración. | 201 · 95 · 63 |
| `api.pl`, `servidor.pl` | Adaptador JSON y servidor HTTP del frontend web (extra). | 573 · 126 |

### 3.2 Principios

- **Reglas puras, efectos como datos.** Una regla como `puede_atacar/2` solo mira el estado; lo que *cambia* se describe como una lista de efectos (`ganar_queso(...)`, `mod_moral(...)`) que `estado.pl` aplica dentro de una transacción. Por eso se puede explicar una acción *antes* de aplicarla y comprobar que el estado no se toca.
- **Los comandos son términos.** `ir(aldea)` o `atacar(bandido_torpe)` son términos de Prolog; `juego.pl` los valida y los ejecuta, y `ejecutar/2` **nunca falla**: un error de programación se convierte en un mensaje.
- **La fase se deriva**, no se guarda: `fase/1` se calcula a partir del estado (combate, taberna, exploración, fin).
- **Datos como programa.** Los contratos, las escenas de la demostración y las prioridades de la IA son hechos y cláusulas que el meta-intérprete puede abrir.
- **Sin cortes fuera de un sitio.** El único corte del código del juego está en la IA enemiga (§4.4), donde significa «la primera regla aplicable gana».

## 4. Lo declarativo en el proyecto

### 4.1 Hechos, reglas y aritmética

La regla que decide si alguien puede atacar es casi una frase:

```prolog
puede_atacar(A, B) :-
    compania:vivo(A),
    \+ compania:esta_en_huelga(A),             % quien esta en huelga no combate
    compania:vivo(B),
    en_fila_alcanzable(A, B),
    \+ aturdido(A),
    \+ ( compania:teme(A, Clase), clase_de(B, Clase) ).
```

«A puede atacar a B si A está vivo, no está en huelga, B está vivo, B es alcanzable por filas, A no está aturdido y A no teme a la clase de B.» El daño es aritmética sobre hechos:

```prolog
dano(A, B, D) :-
    ataque(A, Atq),
    defensa(B, Def),
    modificador(A, B, M),
    D is max(1, Atq - Def + M).
```

### 4.2 Unificación y recursión sobre listas

Las condiciones de un contrato son una lista de términos que se recorren con recursión, no con `forall/2`, precisamente para que el meta-intérprete pueda abrirlas y mostrar cuál falla:

```prolog
puede_aceptar(C) :-
    disponible(C),
    \+ contrato_cumplido(C),
    \+ estado:contrato_activo(C),
    contratos_activos(K),
    mundo:parametro(max_contratos, Max),
    K < Max,
    contrato(C, _, _, _, Condiciones),
    cumple_todas(Condiciones).
```

### 4.3 Negación como fallo

`\+` es lo que da pie a las dos demostraciones centrales. Baldomero **teme a los caballos**: `\+ ( teme(A, Clase), clase_de(B, Clase) )` falla cuando existe esa pareja, y `por_que_no` sabe que **el hecho que lo impide es la prueba de lo que `\+` niega** (§5).

### 4.4 El corte y la IA enemiga

Cada enemigo decide su acción con una lista de reglas por prioridad. El corte `!` implementa «la primera regla aplicable gana»:

```prolog
accion_enemigo(E, curarse)      :- vida_baja(E), tiene_curativo(E), !.
accion_enemigo(E, invocar_moho) :- debe_invocar_moho(E), !.
accion_enemigo(E, robar_queso)  :- puede_robar_queso(E), !.
accion_enemigo(E, embestir(O))  :- puede_embestir(E, O), !.
accion_enemigo(E, atacar(O))    :- objetivo_mas_debil(E, O), !.
accion_enemigo(_, defender).
```

Un corte cambia el significado del programa, así que cada regla tiene una **gemela sin corte**, `regla_ia/3` (con la prioridad como argumento), que sirve de **oráculo en las pruebas**: la IA con corte y la IA declarativa dan la misma acción única para cada enemigo. También hay una prueba de *modo*: la versión con corte solo es correcta con el modo `(+Enemigo, -Accion)`; con la acción ya ligada daría un resultado distinto al declarativo. El corte es el único que hay en el código del juego, y está localizado, comentado y vigilado.

### 4.5 Base de datos dinámica

El estado (vida, moral, quesos, zona, marcas) son hechos dinámicos que **solo `estado.pl` modifica**, mediante efectos aplicados en una transacción: si algo falla a mitad, el estado queda como estaba. Las pruebas comprueban que consultar, explicar y diagnosticar **no cambian** la partida.

### 4.6 Metaprogramación: dos meta-intérpretes

El módulo `explicar.pl` contiene dos meta-intérpretes sobre las reglas del juego.

**`solve/2` demuestra una meta y construye su prueba.** Distingue las formas de una meta (conjunción, disyunción, if-then-else, negación, `findall`, `forall`, predicados predefinidos, predicados del juego) y para cada una produce un nodo de la prueba:

```prolog
s_(neg, (\+ G), M, N, no(G)) :-
    \+ s(G, M, N, _).
```

Los predicados del juego se abren con `clause/3` y el **corte se trata de verdad** (no se ignora): en `H :- Pre, !, Post` se conserva la primera solución de `Pre`, se descartan las demás y las cláusulas restantes de `H`, y la prueba incluye el nodo `corte`:

```prolog
regla(D, G, N, Prueba) :-
    clause(D:G, Cuerpo, Ref),
    nth_clause(_, Indice, Ref),
    (   Cuerpo == true
    ->  Prueba = hecho(G)
    ;   dividir_corte(Cuerpo, Pre, Post)
    ->  s(Pre, D, N, PA),
        !,
        s(Post, D, N, PB),
        aplanar_y((PA, corte, PB), Hijos),
        Prueba = regla(G, Indice, Hijos)
    ;   s(Cuerpo, D, N, PC),
        aplanar_y(PC, Hijos),
        Prueba = regla(G, Indice, Hijos)
    ).
```

**`por_que_no/2` explica por qué una meta no tiene solución.** Recorre las cláusulas buscando el primer subobjetivo que falla y devuelve un diagnóstico: `sin_clausula`, `fallo` (hay cláusulas y todas fallan, con la más cercana primero), `builtin_falso`, `neg_viola` (una negación falla porque lo que niega **sí** se cumple, y se da su prueba), `neg_doble`, `tras` (la conjunción falla en el segundo término), `ninguna` (una disyunción) y `limite`.

La prueba y el diagnóstico se convierten en líneas de texto, en dos **niveles**: *resumido* (el árbol plegado a lo esencial, con `[+N nodos]`) y *detallado* (entero, todas las cláusulas y la prueba de por qué es cierto lo que una negación niega).

## 5. El modo explicar, con salidas reales

Las siguientes salidas están guardadas en `examples/` y las genera el propio juego (`examples/generar.pl`); una prueba comprueba que lo guardado coincide con lo que el programa produce hoy.

**Demostración 1: el miedo de Baldomero** (`por_que_no(atacar(baldomero, bandido_montado))`, nivel resumido). El diagnóstico baja hasta la negación y dice qué hecho la impide:

```
> por_que_no(atacar(baldomero, bandido_montado))
Por qué no se puede atacar(baldomero,bandido_montado):
[no] puede_atacar(baldomero, e(bandido_montado, 1))   [clausula 1]
  |- [ok] vivo(baldomero)
  |- [ok] \+ esta_en_huelga(baldomero)
  |- [ok] vivo(e(bandido_montado, 1))
  |- [ok] en_fila_alcanzable(baldomero, e(bandido_montado, 1))
  |- [ok] \+ aturdido(baldomero)
  \- [no] \+ (teme(baldomero, caballo), clase_de(e(bandido_montado, 1), caballo))
        porque teme(baldomero, caballo) y clase_de(e(bandido_montado, 1), caballo) son ciertos.
Narrador: Sir Baldomero ve el caballo, recuerda su infancia, y decide revisar sus calcetines.
```

**Demostración 2: por qué se pudo atacar, con el cálculo del daño** (`explicar(atacar(baldomero, bandido_torpe))`):

```
> explicar(atacar(baldomero, bandido_torpe))
Por qué se pudo atacar(baldomero,bandido_torpe):
[ok] puede_atacar(baldomero, e(bandido_torpe, 1))   [clausula 1]
   [ok] vivo(baldomero)   [clausula 1]   [+2 nodos]
   [ok] \+ esta_en_huelga(baldomero)   [no demostrable]
   [ok] vivo(e(bandido_torpe, 1))   [clausula 1]   [+2 nodos]
   [ok] en_fila_alcanzable(baldomero, e(bandido_torpe, 1))   [clausula 1]   [+5 nodos]
   [ok] \+ aturdido(baldomero)   [no demostrable]
   [ok] \+ (teme(baldomero, A), clase_de(e(bandido_torpe, 1), A))   [no demostrable]
[ok] dano(baldomero, e(bandido_torpe, 1), 9)   [clausula 1]
   [ok] ataque(baldomero, 11)   [clausula 1]   [+2 nodos]
   [ok] defensa(e(bandido_torpe, 1), 2)   [clausula 1]   [+9 nodos]
   [ok] modificador(baldomero, e(bandido_torpe, 1), 0)   [clausula 1]   [+17 nodos]
   [ok] 9 is max(1, 11-2+0)   [builtin]
Narrador: Sir Baldomero golpea al Bandido Torpe. Fue la primera vez en una semana que no le temblaron las rodillas.
```

**Demostración 3: la IA enemiga y el corte** (`explicar` tras el turno de un Bandido Torpe). Cuenta qué regla de su lista ganó y por qué no se aplicó ninguna de mayor prioridad:

```
> explicar
Por qué el Bandido Torpe hizo eso:
Eligió la regla de prioridad 5 de 6 (el corte descartó las demás).
[ok] accion_enemigo(e(bandido_torpe, 1), atacar(tuerca))   [clausula 5 + corte]
   [ok] objetivo_mas_debil(e(bandido_torpe, 1), tuerca)   [clausula 1]   [+39 nodos]
   [ok] corte   [corte: se descartaron las clausulas siguientes]
Las reglas de más prioridad no se aplicaron:
  prioridad 1 (curarse):
    \- [no] vida_baja(e(bandido_torpe, 1))
          |- [ok] vida(e(bandido_torpe, 1), 12)
          |- [ok] tipo_de(e(bandido_torpe, 1), bandido_torpe)
          |- [ok] enemigo(bandido_torpe, vida(12), ataque(5), defensa(2))
          |- [ok] parametro(umbral_vida_baja, 30)
          \- [no] 12*100=<12*30
                12*100=<12*30 es falso
  prioridad 2 (invocar_moho):
   ...
```

Con `nivel(detallado)` el mismo comando muestra cada una de esas negaciones desplegada hasta los hechos (véase `examples/explicaciones/05-turno-enemigo-detallado.txt`).

## 6. Pruebas y verificación

La verificación fue una parte principal del trabajo, no un final:

- **27 suites y 1 754 pruebas** (`plunit`), que se ejecutan con una sola orden (`tests/todas.pl`, un proceso por suite, código de salida 0 o 1) y que un clon limpio del repositorio pasa.
- **Pruebas de mutación hechas a mano.** Tras cada tarea se rompe el código a propósito (un mutante por cada decisión importante: una condición al revés, un `>=` por un `>`, un corte quitado) y se comprueba que alguna prueba falla. Un mutante que sobrevive indica una prueba que falta, y varias veces llevó a escribir una nueva; los pocos equivalentes (que no cambian el comportamiento) se anotaron como tales.
- **Pruebas de equivalencia del meta-intérprete.** Para 40 objetivos del juego en 8 escenarios (320 comparaciones, 971 soluciones), ejecutar la meta directamente y demostrarla con `solve/2` da **las mismas soluciones en el mismo orden**; es lo que garantiza que `explicar` no miente. Incluye negación, if-then-else, aritmética, `findall`, `forall` y la IA con corte.
- **Oráculos y arneses aleatorios.** La IA con corte contra su gemela declarativa (permanente, en las suites). Además, durante el desarrollo se usaron arneses que juegan miles de pasos al azar con entradas válidas, inválidas y raras (por ejemplo, 400 partidas de 40 pasos) y comprueban invariantes tras cada paso: un error no cambia el estado, la vida y la moral están siempre dentro de rango, la fase es coherente con los hechos y `ejecutar/2` nunca falla ni imprime. Esos arneses no forman parte del repositorio; lo permanente son las suites.
- **Playtest guiado (PT-1).** Una partida completa jugada como lo haría una persona: se gana el día 7 con 48 comandos y sin pantallas con términos crudos ni errores, y las tres rutas degeneradas (no pagar nunca, ignorar la comida, probar los contratos sin condiciones) terminan de forma razonable. El playtest produjo cuatro ajustes (estado del combate tras cada orden, mensaje del día con la ración, variantes que rotan de verdad y pistas de `por_que_no`).
- **Verificar al verificador.** Al escribir el agregador de pruebas se descubrió que un `assertion/1` fallido podía dar «todo en verde» (en SWI-Prolog 5.10.4 abre el depurador y, con la entrada cerrada, el proceso sale con código 0); se corrigió y se añadió una suite que lo vigila.

## 7. Extras

- **Demostración reproducible.** El meta-comando `demo` prepara cinco escenas (economía, combate, IA, gallina, venda) y `examples/` guarda los guiones, las transcripciones, una partida de respaldo completa y las pantallas clave de `explicar`.
- **Frontend web.** Un servidor HTTP mínimo (`servidor.pl`, solo biblioteca estándar) y un adaptador (`api.pl`) devuelven el estado y los resultados como JSON; el árbol de explicación sale como lista de nodos con profundidad y tipo. La interfaz (`web/`, HTML, CSS y JavaScript sin dependencias) implementa un diseño con dos temas (Pergamino y Cueva), versión móvil, selectores, eventos, despensa y crónica. **No contiene reglas del juego**: todo lo que enseña, incluido por qué un botón está desactivado, se lo pregunta al servidor con el mismo `por_que_no`.

## 8. Proceso de trabajo

El proyecto se hizo en tareas pequeñas y verificables (T-01 a T-42 más el extra del frontend), con cerca de **40 commits** desde el 31 de octubre y una regla: una tarea, sus pruebas, su nota de estudio y solo entonces el commit. Hubo tres lecciones que cambiaron el rumbo:

1. **Probar de verdad lo que se prueba.** Varias pruebas de regresión eran vacías hasta que se comprobó que *fallaban sin el arreglo* (la del cerrojo del servidor, la del cuerpo de un POST sin leer).
2. **El entorno miente.** Un segfault intermitente venía de `call_with_time_limit/2`; los saltos de línea cambiaban entre Windows y el repositorio (se arregló con `.gitattributes` y se verificó en un clon limpio).
3. **La documentación envejece en silencio**: se comprobó con un script que las cifras del README coinciden con las reales.

## 9. Limitaciones y trabajo futuro

- **Alcance.** Se cumplió el nivel mínimo (4 contratos, 5 enemigos, 17 comandos, 3 finales) y parte del objetivo (`nivel`, `demo` y más frases). No se hicieron `usar`, `huir`, `comer`, más contratos ni enemigos, tienda, `guardar`/`cargar` ni reclutas.
- **Balance.** La ruta cómoda gana el día 7 con **cero** quesos de margen: el juego es ganable pero ajustado, y un segundo playtest con otra persona queda como mejora.
- **Web.** Una partida por servidor, y la crónica vive en el navegador (se pierde al recargar).
- **Versión de SWI-Prolog.** Se usó solo lo disponible en la 5.10.4 (sin `yall`, `foldl/4` ni `sort/4`), lo que obligó a escribir ayudantes propios.
- **Trabajo futuro natural:** guardar y cargar partida, más contratos y enemigos, exportar el árbol a Graphviz y un ajuste fino del balance.

## 10. Conclusiones

Prolog encaja de forma casi natural con un juego de reglas: el mismo código que *ejecuta* la regla es el que se *interroga* para explicarla. Los dos meta-intérpretes (`solve/2`, que demuestra, y `por_que_no/2`, que diagnostica) se construyen sobre `clause/3` y tratan de verdad la negación y el corte, y la prueba de equivalencia con la ejecución directa da la confianza de que la explicación no miente. Lo aprendido de la asignatura aparece donde tiene que aparecer: la **negación como fallo** es lo que hace interesante `por_que_no`, el **corte** exige una versión declarativa de la que fiarse, la **base de datos dinámica** se encierra en un único módulo con transacciones y la **metaprogramación** convierte las reglas en datos que se pueden mostrar.

La parte menos esperada fue que verificar costó tanto como programar: las pruebas de mutación y las comprobaciones de que cada prueba de regresión falla sin su arreglo encontraron errores reales, incluido uno del propio agregador de pruebas.

## Anexo A. Cómo ejecutar

```
# el juego (consola)
swipl -q -s src/main -g main -t halt

# la demostración entera, de golpe
swipl -q -s src/main -g main -t halt < examples/demo-comandos.txt

# todas las pruebas (código de salida 0 si todo pasa)
swipl -q -s tests/todas -g "run_tests,halt" -t "halt(1)"

# el frontend web (http://localhost:8080/)
swipl -q -s src/servidor -g "servidor(8080)" -t halt
```

En Windows, `swipl` es `C:\Program Files\pl\bin\swipl.exe` (no está en el `PATH`).

## Anexo B. Documentación del repositorio

`README.md` (uso y manual del jugador), `docs/DISENO.md` (diseño de referencia), `docs/02-arquitectura-codigo.md` (arquitectura detallada), `docs/03-funcionalidades-y-etapas.md` (plan y backlog), `docs/07-playtest-1.md` (primer playtest) y `examples/README.md` (demostración y transcripciones).
