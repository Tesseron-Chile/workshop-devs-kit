# 4. Test rojo primero (y tests de caracterización)

**Para qué:** que el test pruebe el criterio de verdad. Un test que nunca falló no demuestra nada.

**Feature nuevo**

1. Lee el criterio de tu story en la SPEC.
2. Escribe el test de aceptación (JUnit 5, MockMvc si hay API).
3. Córrelo: `./mvnw -q test -Dtest=MiTest`. Tiene que fallar, y por la aserción. Si pasa, reescríbelo.
4. Recién ahora escribe el código de producto hasta ponerlo en verde.

**Modernizar un sistema legacy**

El test rojo de una migración no existe todavía: el sistema ya funciona. Se invierte el orden.

1. Escribe tests de caracterización que congelan lo que el código hace hoy, bordes incluidos. Verdes contra el código sin tocar. Commit aparte.
2. Migra en pasos chicos (`javax` a `jakarta`, `Date` a `java.time`, records, `var`).
3. Si un test de caracterización se pone rojo, el comportamiento cambió. Decide: bug propio o cambio buscado (y entonces va a la SPEC).

**Trampa conocida:** los tests pueden seguir verdes con un bug que ningún test cubre, por ejemplo el corte de medianoche al pasar de `Date` a `LocalDate`. Por eso existe el review contra la SPEC (técnica 8) y el test del borde.

**Skill:** `/workshop-devs:test-rojo`.
