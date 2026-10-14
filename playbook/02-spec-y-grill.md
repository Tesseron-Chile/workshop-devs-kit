# 2. SPEC antes de codear, y grill

**Para qué:** que el equipo y el agente construyan lo mismo, y que el PR se pueda revisar contra algo escrito.

**Cómo**

1. Del ticket sale `workdocs/SPEC.md`: problema en una frase, alcance, criterios de aceptación observables y fuera de alcance. La SPEC va en git, no en el chat.
2. Antes de codear, haz el grill: `/workshop-devs:grill-me workdocs/SPEC.md`. La skill pregunta una cosa a la vez, ataca ambigüedad, alcance inflado y aceptación no testeable, y deja un diff.
3. El equipo revisa ese diff y lo commitea. Recién ahí se parte en stories.

**Qué buscar en el grill de un sistema bancario**

- Redondeo de montos (escala y `RoundingMode`).
- Corte de día y zona horaria (America/Santiago).
- Qué pasa con la auditoría si la operación falla a la mitad.
- Qué significa "sin cambios de comportamiento" en un criterio de migración.

**Regla de salida:** cada criterio debe poder convertirse en un test que falla. Si no puede, reescríbelo.

**Errores típicos**

- Pegar el ticket entero en la SPEC en vez de decidir qué entra.
- Un grill hablado que no deja diff: no queda constancia.
