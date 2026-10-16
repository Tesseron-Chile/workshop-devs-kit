# 5. Agentes en paralelo

**Para qué:** avanzar varias stories independientes a la vez, sin perder control del merge.

**Cómo**

1. Parte de un plan con stories independientes (técnica 3). Sin eso, paralelizar solo multiplica los conflictos.
2. Un worker por story, cada uno en su worktree y con contexto limpio. Los hooks del plugin (técnica 6) mantienen los tests verdes antes de cada commit.
3. Los subagentes built-in sirven para leer sin editar: Explore (solo lectura, rápido) y Plan (investiga en plan mode).
4. Puedes pedir investigación en paralelo con subagentes separados por área. Corren en segundo plano mientras sigues trabajando y entregan su resultado como notificación. Por defecto pueden correr hasta 20 a la vez.
5. Subagentes propios: un `.md` con frontmatter (`name`, `description`, `tools`, `model`) en `.claude/agents/`.

**Reglas**

- El humano hace el merge. Cada worker abre su PR y para (`/workshop-devs:pr-tesseron`).
- Un worker que escribe archivos corre en un worktree desechable, nunca en tu checkout de trabajo.
- Mira el costo: más agentes consumen más tokens. Mide con `claude -p --output-format json` (campo `total_cost_usd`, una estimación del cliente).

**Errores típicos**

- Dos workers editando el mismo archivo.
- Revisar solo que los tests pasen y no contra la SPEC.
