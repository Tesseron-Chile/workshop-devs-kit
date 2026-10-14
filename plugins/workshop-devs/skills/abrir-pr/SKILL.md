---
name: abrir-pr
description: Open a pull request that links the ticket and SPEC.md, without merging. Works on AWS CodeCommit (aws codecommit) and on GitHub (gh). Use when the story is ready for review, filling the PR body, running aws codecommit create-pull-request or gh pr create, or the user says abre el PR.
---

Abre un PR por story. El humano hace el merge. El agente abre el PR y para.

1. Arma el body con las secciones de `.github/pull_request_template.md` si el repo lo tiene. Si no, usa las secciones de los pasos 2 y 3.
2. Escribe en español Contexto, Tipo de cambio, Cambios y Notas de migración.
3. Escribe en inglés `For automated reviewers`: Scope, Contracts, Invariants to check, Known and accepted, Out of scope.
4. Agrega links al ticket (`tickets/<id>.md`) y a `workdocs/SPEC.md`. Sin esos dos links no hay PR.
5. Usa un título en Conventional Commits.

## Elige la vía según el remoto

Corre `git remote get-url origin`.

- Si contiene `codecommit` (`codecommit::<región>://<repo>` o `git-codecommit.<región>.amazonaws.com`): usa CodeCommit.
- Si no (por ejemplo `github.com`): usa GitHub.

### CodeCommit

CodeCommit no tiene draft y no lee `.github/pull_request_template.md`. Arma el body igual y pásalo como texto. Si el PR no está listo, prefija el título con `WIP:`.

```
aws codecommit create-pull-request \
  --title "WIP: <type>: <description>" \
  --description "$(cat /tmp/pr-body.md)" \
  --targets repositoryName=<repo>,sourceReference=<rama>,destinationReference=main
```

- `<repo>` es el último segmento de la URL del remoto.
- `<rama>` es la rama de la story: `feat/<ticket-id>-story-<n>`.
- Hacen falta credenciales AWS con permiso `codecommit:CreatePullRequest`. Si no están, deja el comando listo y avisa al humano. No intentes otra vía.

### GitHub

Guarda el body en `/tmp/pr-body.md` y corre:

```
gh pr create --draft --title "<type>: <description>" --body-file /tmp/pr-body.md
```

## Antes de irte

1. Mira el diff con el veto: secretos, auth, contratos y migraciones. Si algo de eso está, sácalo del PR ahora.
2. Pide la review de un compañero (quien no escribió el hunk) y la review del agente contra la SPEC.
3. No hagas merge, aunque el CI esté verde.
