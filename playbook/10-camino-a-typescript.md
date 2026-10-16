# 10. Camino a TypeScript

**Para qué:** portar un módulo chico de Java a TypeScript sin cambiar lo que el sistema responde. Es el mismo patrón de los tests de caracterización (técnica 4): primero se congela lo que hace el sistema, después se cambia la implementación.

**Cómo**

1. Elige un módulo acotado, por ejemplo un solo endpoint de consulta (`GET /api/v1/transferencias?cuenta=<numero>`). Crear y anular siguen en Java hasta que les toque.
2. Con el servicio Java corriendo, guarda sin editar sus respuestas reales (casos con datos, lista vacía, 404). Ese es el contrato.
3. Escribe los tests de contrato primero (técnica 4): mandan las mismas peticiones al endpoint Java y al de TypeScript, y comparan las respuestas. Si coinciden, hay paridad.
4. Porta con Node y Fastify hasta que el contrato pase. Una segunda suite puede comparar contra el Java en vivo los casos sin datos.
5. El PR se revisa contra la SPEC (técnica 8) como cualquier otro: la paridad es el criterio de aceptación.

**Qué suele costar**

| Diferencia | Java | En TypeScript |
|---|---|---|
| Monto | `BigDecimal` serializa `300.10` | Un `number` de JS daría `300.1`: el monto viaja como string con 2 decimales |
| Fecha | `Date` sale en hora de Santiago, con offset | `Intl.DateTimeFormat` con `America/Santiago` |
| Orden | `OrderByFechaDesc` | `sort` por la fecha UTC descendente |

**Errores típicos**

- Cambiar el formato "porque se ve mejor" dentro del port. El contrato congela el formato actual, y cambiarlo es una decisión de producto, no del port.
- Portar más de un módulo a la vez: la paridad deja de ser comprobable.

**Ejemplo:** `modernizacion/typescript/` del repo `workshop-devs-demo-java`.
