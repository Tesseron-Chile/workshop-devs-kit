# 8. Review contra la SPEC

**Para qué:** que el review responda "¿esto hace lo que dijimos?" y no solo "¿compila y pasa?". Los tests verdes no prueban un criterio que ningún test cubre.

**Cómo**

1. El PR linkea el ticket y `workdocs/SPEC.md`, y su descripción cita por número los criterios de la SPEC que resuelve (`/workshop-devs:pr-tesseron` lo exige). Esa es la pregunta con la que se revisa: ¿qué criterios cubre este diff?
2. El review pasa la SPEC y el diff al agente, en una sesión nueva: "Revisa este PR contra workdocs/SPEC.md. Ignora estilo y naming. Lista solo la brecha entre la spec y el diff, con cita." Por ejemplo, con `claude -p` (técnica 7).
3. Aparte, un compañero que no escribió el código revisa los hunks de riesgo: secretos, auth, contratos, migraciones y todo lo que mueve dinero o toca auditoría. Deja al menos un comentario que cita la SPEC.
4. Cada hallazgo del agente se queda o se descarta con argumento de spec o de diff. Se confirma con un test que falla en el borde sospechado (técnica 4). Si el test lo confirma, se arregla en la misma rama; si no, se descarta.
5. Con los arreglos hechos y el CI verde, el humano hace el merge. El agente no. Si la rama no llega, el gap queda escrito en `workdocs/status.md`.

**Qué pedirle al revisor en un sistema bancario**

- Redondeo y escala de `BigDecimal`.
- Zona horaria y corte de día.
- Atomicidad: ¿la auditoría queda en la misma transacción?
- Código que no está en la SPEC (el diff que no está en la spec no entra).

**El caso del curso (MOD-7, Date a java.time)**

Los 19 tests pasaban y el PR parecía solo una migración. El review contra la SPEC marcó dos bugs en `totalDelDia`: el día se cortaba en UTC en vez de `America/Santiago`, y el rango quedaba cerrado arriba (`!isAfter`) cuando la SPEC pedía rango semiabierto. Los tests de caracterización no lo veían porque solo usaban transferencias de mediodía. Un test nuevo con 23:30 y 00:00:00 en Santiago falla y lo confirma. Si migras, agrega los casos borde antes.

**Errores típicos**

- Aceptar todos los hallazgos sin reproducirlos.
- Que el mismo agente que escribió el código sea el único que lo revisa.
- Frenar el PR por naming o estilo que la SPEC no menciona.
