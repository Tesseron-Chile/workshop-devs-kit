---
name: plan-worktree
description: Derive a team PLAN.md with a technical design (diseño técnico) per story and mount one git worktree per person. Use when writing PLAN.md, splitting stories, creating feat/<ticket-id>-story-<n> branches, opening Claude in a worktree, or the user says arma el plan / crea el worktree.
---

Lee `workdocs/SPEC.md` (aceptación y fuera de alcance) antes de partir stories.

El equipo tiene un `workdocs/PLAN.md`, uno solo por grupo (nadie sube "su parte"). Cada persona tiene una story, y cada story cabe en un PR. El diseño técnico va dentro del plan: qué toca, qué recibe y qué devuelve cada parte, contratos y orden. No hay `DESIGN.md`.

1. Escribe el plan en Plan Mode. Cada story indica: criterio de la SPEC que cubre, archivos o paquetes que toca y el test que la prueba. Dos stories que tocan el mismo archivo se ordenan o se fusionan: solo una story toca cada archivo compartido.
2. Haz commit de `PLAN.md` a la rama base (`main`) y push. Si las ramas se parten antes, aparecen dos planes. El plan va directo a la rama base, sin PR.
3. Con la rama base actualizada, crea un worktree por persona. No codees el feature en este paso. Corre:

```
git pull origin main
git worktree add -b feat/<ticket-id>-story-<n> ../<equipo>-story-<n> main
cd ../<equipo>-story-<n>
```

4. Reemplaza `<ticket-id>`, `<equipo>` y `<n>` con los valores de `PLAN.md`. Si la rama base del repo no es `main`, usa la que corresponda.
5. Cierra Claude Code y ábrelo de cero en ese directorio. No uses `claude -c`, `/resume` ni pegues el chat: el estado vive en git (SPEC, PLAN), no en la conversación. Pruébalo preguntando: «¿En qué story estoy y cuál es su criterio de aceptación?». Si la respuesta es vaga, falta algo en el markdown: corrígelo ahí, no en el prompt.

Un worktree toma los archivos versionados de la rama desde la que sale, incluidos `.claude/` y `AGENTS.md`: haz commit de lo que necesites antes de crearlo. Las skills de un plugin instalado no dependen del worktree.

Los commits siguen Conventional Commits. Antes de la primera story, corre los tests del repo una vez para confirmar que el worktree parte verde (`./mvnw -q test` en Maven, `npm test` en Node; el comando exacto está en `AGENTS.md` o `CLAUDE.md`).
