---
name: plan-worktree
description: Derive a team PLAN.md with a technical design (diseño técnico) per story and mount one git worktree per story or person. Use when writing PLAN.md, splitting stories, creating feat/<ticket-id>-story-<n> branches, opening Claude in a worktree, or the user says arma el plan / crea el worktree.
---

Lee `workdocs/SPEC.md` (aceptación y fuera de alcance) antes de partir stories.

El equipo tiene un `workdocs/PLAN.md`. Cada story cabe en un PR y la hace una persona (o un worker). El diseño técnico va dentro del plan: qué clases y paquetes toca, contratos y orden. No hay `DESIGN.md`.

1. Escribe el plan en Plan Mode. Cada story indica: criterio de la SPEC que cubre, archivos o paquetes que toca, y el test que la prueba. Dos stories que tocan el mismo archivo se ordenan o se fusionan: así no chocan en el merge.
2. Haz commit de `PLAN.md` a la rama base (`main`) y push. Si las ramas se parten antes, aparecen dos planes.
3. Con la rama base actualizada, crea un worktree por story. No codees el feature en este paso. Corre:

```
git pull origin main
git worktree add -b feat/<ticket-id>-story-<n> ../<equipo>-story-<n> main
cd ../<equipo>-story-<n>
git push -u origin feat/<ticket-id>-story-<n>
```

4. Reemplaza `<ticket-id>`, `<equipo>` y `<n>` con los valores de `PLAN.md`. Si la rama base del repo no es `main`, usa la que corresponda.
5. Cierra Claude Code y ábrelo de cero en ese directorio. No uses `claude -c`, `/resume` ni pegues el chat: el estado vive en git (SPEC, PLAN), no en la conversación.

Los commits siguen Conventional Commits. En un repo Maven multi-módulo, el primer build de cada worktree baja o reutiliza dependencias de `~/.m2`: corre `./mvnw -q test` una vez para confirmar que el worktree parte verde.
