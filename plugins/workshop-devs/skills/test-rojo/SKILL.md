---
name: test-rojo
description: Write the acceptance test (or a characterization test for legacy code) before product code and run it until it fails on purpose. Use when starting a story, before implementing or migrating, recording evidence in status.md, or the user says test rojo / test de aceptación / test de caracterización.
---

Antes de tocar código de producto, lee el criterio de tu story en `workdocs/SPEC.md` y el diseño técnico en `workdocs/PLAN.md`.

## Feature nuevo: test de aceptación

1. Escribe el test que asserta el criterio de la story (JUnit 5; MockMvc si cambia la API).
2. Córrelo con el comando de tests del repo, el que dice `AGENTS.md` o `CLAUDE.md`. En Maven:

```
./mvnw -q test
./mvnw -q test -Dtest=NombreDelTest        # solo tu test, para iterar rápido
```

3. Confirma que falla, y que falla por la razón correcta (la aserción, no un error de compilación). Si pasa, el test no prueba el criterio: reescribe la aserción.
4. Pega el comando y el resultado en tu fila de `workdocs/status.md`, sección "Tests de aceptación", si el repo lo usa.

## Modernizar o migrar: test de caracterización

Cuando el cambio es una migración (por ejemplo `javax` a `jakarta`, `Date` a `java.time`, subir de versión de Spring o de Java), el "test rojo" es distinto: primero congelas lo que el sistema hace hoy.

1. Escribe tests que llaman al código actual y asertan su salida real, bordes incluidos (montos exactos, 23:59:59 y 00:00:00, zona horaria). Deben pasar en verde contra el código sin tocar.
2. Haz commit de esos tests solos, antes de cualquier cambio de producción.
3. Migra. Si un test de caracterización se pone rojo, la migración cambió el comportamiento: decide si es un bug tuyo (arréglalo) o un cambio buscado (documéntalo en la SPEC).
4. Un test que solo pasa con el comportamiento nuevo no es de caracterización: va como test de aceptación.

## Reglas

- Lanza un worker (subagente) acotado a la story o al test si el volumen lo justifica. Explore y Plan built-in sirven para leer código sin editarlo.
- El diff que no está en la spec no entra, porque el PR se revisa contra `SPEC.md`.
- Deja credenciales y datos reales de clientes fuera de los fixtures.
- Si el test sigue rojo al cierre, escribe el trabajo que falta en `workdocs/status.md`. No hay merge con un test rojo.
