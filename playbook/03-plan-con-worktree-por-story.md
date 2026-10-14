# 3. Plan con un worktree por story

**Para qué:** que varias personas (o varios agentes) trabajen a la vez sin pisarse y con PRs chicos.

**Cómo**

1. Con la SPEC lista, escribe `workdocs/PLAN.md` en Plan Mode: una story por PR, con diseño técnico (qué toca, contratos, orden) y el test que la prueba. No hay un `DESIGN.md` aparte.
2. Dos stories que tocan el mismo archivo se ordenan o se fusionan.
3. Commit del plan a la rama base, y recién ahí los worktrees: `/workshop-devs:plan-worktree`.

```
git worktree add -b feat/<ticket>-story-<n> ../<equipo>-story-<n> main
```

4. Abre Claude Code de cero en cada worktree. Un worktree es un checkout aparte del mismo repo, con su propia rama.

**Detalles**

- `claude --worktree [nombre]` crea un worktree desde la CLI (aparece en `claude --help`).
- Un subagente puede correr en un worktree temporal con `isolation: worktree` en su frontmatter. Se borra solo si no hizo cambios.

**Errores típicos**

- Crear las ramas antes de commitear el plan: terminas con dos planes.
- Seguir la conversación con `/resume` en vez de partir limpio: el estado debe estar en git.
