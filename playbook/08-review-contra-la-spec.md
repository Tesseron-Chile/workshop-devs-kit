# 8. Review contra la SPEC

**Para qué:** que el review responda "¿esto hace lo que dijimos?" y no solo "¿compila y pasa?". Los tests verdes no prueban un criterio que ningún test cubre.

**Cómo**

1. El PR linkea el ticket y `workdocs/SPEC.md` (`/workshop-devs:pr-tesseron` lo exige).
2. El review pasa la SPEC y el diff al agente: "Revisa este diff contra la SPEC. Lista solo desviaciones y bugs reales, con archivo y línea." Por ejemplo, con `claude -p` (técnica 7).
3. Aparte, un compañero que no escribió el código revisa los hunks de riesgo: secretos, auth, contratos, migraciones y todo lo que mueve dinero o toca auditoría.
4. Cada hallazgo se confirma con un test que falla en el borde sospechado (técnica 4). Si el test lo confirma, se arregla; si no, se descarta.
5. El humano decide y hace el merge.

**Qué pedirle al revisor en un sistema bancario**

- Redondeo y escala de `BigDecimal`.
- Zona horaria y corte de día.
- Atomicidad: ¿la auditoría queda en la misma transacción?
- Código que no está en la SPEC (el diff que no está en la spec no entra).

**Errores típicos**

- Aceptar todos los hallazgos sin reproducirlos.
- Que el mismo agente que escribió el código sea el único que lo revisa.
