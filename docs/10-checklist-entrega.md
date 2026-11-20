# 10 — Lista de verificación de la entrega (T-44)

Estado a **20 de noviembre de 2026** (entrega: viernes 11 de diciembre). La lista sale de `docs/03-funcionalidades-y-etapas.md` §14. La parte que se puede comprobar con una orden está **automatizada** en `scripts/verificar-entrega.ps1`: clona lo *commiteado* en una carpeta temporal y lo comprueba; sale con código 0 si todo pasa.

```
powershell -ExecutionPolicy Bypass -File scripts/verificar-entrega.ps1
```

(`-Swipl "ruta\swipl.exe"` si no está en `C:\Program Files\pl\bin`.) **Repetirlo el 9, el 10 y el 11 de diciembre**, y antes de cada etiqueta.

Leyenda: ✅ comprobado (con el script o con la orden indicada) · ⏳ lo tiene que hacer el autor · 🔒 pide permiso explícito (se hace solo cuando el autor lo dice).

## 1. Candidata (`v1.0-rc1`)

| Ítem | Estado | Cómo |
|---|---|---|
| Clon limpio: `swipl -q -s src/main -g main -t halt` arranca con SWI-Prolog 5.10.4 | ✅ | script |
| `tests/todas` pasa con código 0 en el clon (27 suites, 1762 pruebas) | ✅ | script |
| Ninguna excepción en partida de victoria ni de derrota (`derrota_combate`, `derrota_hambre`) | ✅ | `tests/campana.pl` (las tres partidas) y `tests/api.pl` (la campaña entera por la API) |
| PT-3: guion ejecutado dos veces con cronómetro y tiempos anotados | ⏳ | `docs/09-guion-exposicion.md` §6 |
| Etiqueta `v1.0-rc1` creada y subida | ✅ | §4 (sobre `6f931d6`, 20 de noviembre) |

## 2. Cierre

| Ítem | Estado | Cómo |
|---|---|---|
| `assert`/`retract` solo en `src/estado.pl` | ✅ | script. *Había uno en `servidor.pl` (la carpeta `web/` guardada con `assertz` al cargar); se quitó: ahora se deduce con `module_property/2`.* |
| Ninguna función inexistente en 5.10.4 (`>>`, `foldl(`, `sum_list(`, `max_member(`, `random_between(`, `random_member(`, `split_string(`, `atom_string(`) | ✅ | script |
| README al día (versión, ruta, cómo jugar, cómo probar, `explicar`/`por_que_no` como comandos, qué es extra) | ✅ | T-41 |
| `docs/DISENO.md` refleja lo construido y no promete lo recortado | ✅ | T-41 (estado 1.0, `arbol` marcado como no implementado) |
| `examples/` con guion, salida y explicaciones; demo reproducible byte a byte | ✅ | script (regenera `examples/` y no cambia nada) |
| Informe listo | ✅ / ⏳ | `docs/08-informe.md` (Markdown). Falta **confirmar el formato** (D-34) y, si se quiere, **capturas de la web** en `docs/img/` |
| Guion ensayado con cronómetro (≤ 15 min); plan B grabado y probado; tres demostraciones ensayadas | ⏳ | guion hecho (T-43); **ensayo y vídeo los hace el autor** |
| Historial: mensajes en español, breves, sin coautorías ni atribuciones de herramientas; un solo autor | ✅ | script (39 commits, un autor) |
| Ningún archivo del repositorio menciona herramientas de IA | ✅ | script |
| Repositorio sin archivos sobrantes (`out/`, `saves/`, `*.qlf`, `*.bak`, `.zip`, `.log`) | ✅ | script |
| Copia de seguridad (`.zip` de la etiqueta + memoria USB) | ⏳ | §5 |

## 3. Entrega (11 de diciembre)

| Ítem | Estado | Cómo |
|---|---|---|
| Etiqueta `v1.0-entrega` creada sobre el commit final y subida | 🔒 | §4 |
| Entregable enviado por el medio acordado y confirmación guardada | ⏳ | depende de la respuesta a D-34 |
| Última comprobación desde el artefacto entregado (descargar y arrancar) | ⏳ | el script, sobre lo descargado |
| Fecha de la exposición confirmada y plan de repetir PT-3 una semana antes | ⏳ | preguntar a la profesora (D-37) |

## 4. Etiquetas propuestas

Una etiqueta se publica con `git push`, así que **se crean solo cuando el autor lo confirma**. El 20 de noviembre se crearon y subieron las cuatro primeras (los `v0.x` marcan los puntos de control del calendario, sobre el commit que los cumplió); `v1.0-entrega` queda para el 11 de diciembre:

| Etiqueta | Commit | Qué marca |
|---|---|---|
| `v0.1-diseno` ✅ | `432e1ec` | El diseño y los módulos base (2 de noviembre) |
| `v0.5-motor` ✅ | `77252df` | Motor, sueldos, inventario y modo explicar en árbol (semana 2) |
| `v0.9-jugable` ✅ | `8cc4633` | La partida mínima de principio a fin (T-28) |
| `v1.0-rc1` ✅ | `6f931d6` (el commit de T-44) | La candidata: todo hecho salvo ensayo y entrega |
| `v1.0-entrega` 🔒 | el commit final del 11 de diciembre | Lo entregado (inmutable) |

Para la etiqueta final, sobre el commit final y una vez el autor lo confirme:

```
git tag -a v1.0-entrega -m "Entrega del 11 de diciembre"
git push origin v1.0-entrega
```

## 5. Copia de seguridad

```
git archive --format=zip -o banda-chapuza-v1.0-entrega.zip v1.0-entrega
```

Guardar el `.zip` en la memoria USB junto con el vídeo de la demo (plan B) y comprobar que el clon de la etiqueta arranca en otro equipo.

## 6. Lo que queda pendiente del autor

1. **Preguntar a la profesora** (lo único que bloquea cosas): qué se entrega, formato y extensión del informe, medio de entrega (D-34), si la exposición es en vivo y con cuánto tiempo (D-36) y la fecha (D-37).
2. **Ensayar el guion dos veces con cronómetro** y anotar los tiempos (`docs/09-guion-exposicion.md` §6); **grabar la demo** en vídeo.
3. Probar `chcp 65001` en la consola real y ver si las tildes salen bien (o usar la versión web).
4. **T-38** (balance y segundo playtest con otra persona): sigue pendiente; la ruta cómoda gana con cero quesos de margen.
5. Decir cuándo crear `v1.0-entrega` (el 11 de diciembre, sobre el commit final).
