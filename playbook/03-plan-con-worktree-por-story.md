# 3. Plan con un worktree por story

**Para qué:** que varias personas (o varios agentes) trabajen a la vez sin pisarse y con PRs chicos.

**Cómo**

1. Con la SPEC lista, escribe `workdocs/PLAN.md` en Plan Mode: un solo plan por grupo, una story por persona y por PR. Cada story dice qué recibe y qué devuelve (contratos), qué archivos toca y el test que la prueba. No hay un `DESIGN.md` aparte.
2. Dos stories que tocan el mismo archivo se ordenan o se fusionan: por ejemplo, solo la story que arma el comando toca `cli.js`.
3. Commit del plan directo a la rama base (sin PR) y push, y recién ahí los worktrees: `/workshop-devs:plan-worktree`.

```
git worktree add -b feat/<ticket>-story-<n> ../<equipo>-story-<n> main
```

4. Abre Claude Code de cero en cada worktree (sin `claude -c` ni `/resume`) y pregunta: «¿En qué story estoy y cuál es su criterio de aceptación?». Si la respuesta es vaga, falta algo en `SPEC.md` o `PLAN.md`: se corrige ahí, no en el prompt. Un worktree es un checkout aparte del mismo repo, con su propia rama.
5. El equipo lleva `workdocs/status.md`: quién hace qué (Roles), el test de cada story (Tests de aceptación) y los workers. Cada persona edita solo su fila, en su rama, para no chocar al hacer merge.

**Detalles**

- `claude --worktree [nombre]` crea un worktree desde la CLI (aparece en `claude --help`).
- Un subagente puede correr en un worktree temporal con `isolation: worktree` en su frontmatter. Se borra solo si no hizo cambios.

**Errores típicos**

- Crear las ramas antes de commitear el plan: terminas con dos planes.
- Seguir la conversación con `/resume` en vez de partir limpio: el estado debe estar en git.
