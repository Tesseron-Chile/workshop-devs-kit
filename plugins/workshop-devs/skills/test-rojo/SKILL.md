---
name: test-rojo
description: Write the acceptance test (or a characterization test for legacy code) before product code and run it until it fails on purpose. Use when starting a story, before implementing or migrating, recording evidence in status.md, or the user says test rojo / test de aceptación / test de caracterización.
---

Antes de tocar código de producto, lee el criterio de tu story en `workdocs/SPEC.md` y el diseño técnico en `workdocs/PLAN.md`.

## Qué comando corre los tests

Usa el que diga `AGENTS.md` o `CLAUDE.md`. Si no dice, detecta el stack:

| Señal en la raíz | Comando | Un solo test |
|---|---|---|
| `pom.xml` | `./mvnw -q test` (o `mvn -q test` sin wrapper) | `./mvnw -q test -Dtest=NombreDelTest` |
| `package.json` | `npm test` | `node --test test/<archivo>.test.js` (si el runner es `node:test`) |

Si no reconoces el stack, pregunta antes de inventar un comando.

## Feature nuevo: test de aceptación

1. Escribe un test por criterio de tu story, con el número del criterio en el nombre (por ejemplo «criterio 2: sin flags no aparece F-1003»). Usa el framework que ya tiene el repo (JUnit 5, MockMvc si cambia una API; `node:test` en el template Node).
2. Córrelo con el comando de arriba.
3. Confirma que falla, y que falla por la razón correcta (la aserción, no un error de compilación o de import). Si pasa, el test no prueba el criterio: endurece la aserción.
4. Pega el comando y el resultado en tu fila de `workdocs/status.md`, sección "Tests de aceptación". Edita solo tu fila, en tu rama.
5. Lanza un worker (subagente) acotado a la story o al test si el volumen lo justifica, y anota en la sección "Workers" la tarea y el resumen. Explore y Plan built-in cuentan.

## Modernizar o migrar: test de caracterización

Cuando el cambio es una migración (por ejemplo `javax` a `jakarta`, `Date` a `java.time`, subir de versión de Spring, de Java o pasar un módulo a TypeScript), el "test rojo" es distinto: primero congelas lo que el sistema hace hoy.

1. Escribe tests que llaman al código actual y asertan su salida real, bordes incluidos (montos exactos, 23:59:59 y 00:00:00, zona horaria). Deben pasar en verde contra el código sin tocar.
2. Haz commit de esos tests solos, antes de cualquier cambio de producción.
3. Migra. Si un test de caracterización se pone rojo, la migración cambió el comportamiento: decide si es un bug tuyo (arréglalo) o un cambio buscado (documéntalo en la SPEC).
4. Un test que solo pasa con el comportamiento nuevo no es de caracterización: va como test de aceptación.

## Reglas

- El diff que no está en la spec no entra, porque el PR se revisa contra `SPEC.md`.
- Deja credenciales y datos reales de clientes fuera de los fixtures.
- Si el test sigue rojo al cierre, escribe el trabajo que falta en `workdocs/status.md`. No hay merge con un test rojo.
