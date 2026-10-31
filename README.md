# banda_chapuza-lp

**Banda Chapuza** es un RPG ligero de texto en el que diriges una compañía de mercenarios de saldo: contratas misiones absurdas, gestionas quesos (la moneda y la comida a la vez), sueldos y moral, y peleas por turnos. Está escrito íntegramente en **Prolog** como proyecto final de Programación Declarativa: el estado del mundo son hechos, las reglas del juego son cláusulas y un meta-intérprete permite preguntar `explicar` o `por_que_no` para ver, con la voz de un narrador sarcástico, el árbol de derivación detrás de cada acción.

> Estado: en desarrollo. El diseño está en [docs/DISENO.md](docs/DISENO.md).

## Características previstas

- Compañía de mercenarios con rasgos que modifican las reglas del juego.
- Economía del queso: maduración, comida, sueldos y moral.
- Contratos con recompensa y consecuencias.
- Combate por turnos con filas (frente y retaguardia) y enemigos con IA por reglas.
- **Modo explicar:** `explicar/1`, `por_que_no/1` y `arbol/1` muestran la prueba SLD de cada acción.

## Requisitos

- [SWI-Prolog](https://www.swi-prolog.org/) (la versión exacta se fijará durante el desarrollo).

## Ejecución

Aún sin implementar. La idea es arrancar el juego desde la raíz del repositorio:

```
swipl src/main.pl
```

## Estructura

```
banda_chapuza-lp/
├─ docs/DISENO.md   documento de diseño
├─ src/             código fuente (mundo, compañía, economía, contratos, combate, eventos, explicar, narrador, ui)
├─ tests/           pruebas (plunit)
└─ examples/        partidas y explicaciones de ejemplo
```

## Contexto académico

Proyecto final individual de la asignatura **Programación Declarativa**. Aplica hechos y reglas, unificación, resolución SLD, corte y negación, aritmética, metaprogramación y base de datos dinámica de Prolog.

## Autor

[@solerch5510](https://github.com/solerch5510)
