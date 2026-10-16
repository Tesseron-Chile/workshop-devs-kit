# Kit del workshop de devs (Tesseron)

Plugin de Claude Code con las skills y los hooks del curso, adaptados a Java/Maven y a repos en CodeCommit, más un playbook de una página por técnica. Este repo es a la vez el marketplace (`tesseron-devs`) y el plugin (`workshop-devs`).

Pedido P141, Día 3 (19-10-2026).

## Qué trae

| Componente | Detalle |
|---|---|
| Skills | `grill-me`, `plan-worktree`, `test-rojo` (incluye tests de caracterización para modernizar), `pr-tesseron` (CodeCommit y GitHub) |
| Hooks | `PreToolUse` sobre `Bash`: `check-secrets` (bloquea `git commit` con una clave AWS, `password=valor` o una llave PEM) y `check-tests-before-commit` (bloquea `git commit` si `./mvnw -q test` falla) |
| Playbook | `playbook/01` a `09`, una página por técnica |
| Plantillas | `templates/settings-deny.json` (deny rules para secretos) y `templates/managed-settings.example.json` (marketplace, plugin y deny rules exigidos por un administrador) |

Las skills quedan con el prefijo del plugin: `/workshop-devs:grill-me`, `/workshop-devs:plan-worktree`, `/workshop-devs:test-rojo`, `/workshop-devs:pr-tesseron`.

## Instalar

Requisitos: Claude Code, `git` y `jq` (los hooks leen el JSON del evento con `jq`).

Desde un directorio local (un clone de este repo):

```
claude plugin marketplace add /ruta/al/clone/workshop-devs-kit
claude plugin install workshop-devs@tesseron-devs
claude plugin list
```

Desde un host git (cuando el repo viva en el git de la consultora):

```
claude plugin marketplace add https://git.ejemplo.cl/herramientas/tesseron-devs-kit.git
claude plugin install workshop-devs@tesseron-devs
```

Dentro de una sesión, `/plugin marketplace add ...` hace lo mismo. Para actualizar: `claude plugin marketplace update tesseron-devs` y `claude plugin update workshop-devs@tesseron-devs`.

### Acceso a un marketplace privado

Según la doc, Claude Code corre `git` en la máquina de cada usuario sin prompts interactivos y usa las credenciales que esa máquina ya tenga (clave SSH cargada en `ssh-agent`, o un credential helper de git para HTTPS). No hay un campo para un token en `marketplace.json`.

CodeCommit como host del marketplace: **no verificado**. La doc lista GitHub, GitLab, Bitbucket, "otro host git", una URL a `marketplace.json` y un directorio compartido. No menciona CodeCommit ni las URLs `codecommit::`. En HTTPS con el credential helper de AWS (`git config credential.helper '!aws codecommit credential-helper $@'`) debería funcionar por la regla general de credenciales, pero hay que probarlo en un repo real de la consultora. La ruta segura hoy: clonar el repo y agregar el directorio con `marketplace add /ruta`.

### Que todo el equipo lo tenga

Dos caminos que documenta la doc:

1. En el repo de cada proyecto, `.claude/settings.json` con `extraKnownMarketplaces` y `enabledPlugins` (se aplica cuando el usuario confía en la carpeta). Se puede generar con `claude plugin marketplace add <fuente> --scope project`.
2. Un administrador, con managed settings (`extraKnownMarketplaces` y `enabledPlugins`). Ejemplo en `templates/managed-settings.example.json`.

### Deny rules: van aparte del plugin

Un plugin no puede llevar `permissions.deny`: de `settings` solo toman efecto `agent` y `subagentStatusLine`. Para bloquear la lectura de secretos copia `templates/settings-deny.json` al `.claude/settings.json` del proyecto, o ponlo en managed settings (ahí el usuario no lo puede sacar).

## Cómo se usan los hooks

Se activan solos al instalar el plugin. Para probarlos a mano:

```
jq -nc --arg d "$PWD" '{tool_name:"Bash",cwd:$d,tool_input:{command:"git commit -m x"}}' \
  | ~/.claude/plugins/.../hooks/check-secrets.sh; echo "exit=$?"
```

(Con el marketplace agregado desde un directorio local, los hooks quedan en `plugins/workshop-devs/hooks/` de ese directorio.) Exit 2 bloquea y el mensaje de stderr le llega a Claude.

## Desarrollo

```
claude plugin validate .
claude plugin validate plugins/workshop-devs
claude --plugin-dir plugins/workshop-devs
```

`version` está solo en `plugin.json`. Súbela en cada release: una instalación cacheada no recibe commits nuevos si la versión no cambia (para un marketplace agregado desde un directorio local no aplica, se lee en el lugar).

## Decisiones tomadas

1. **Un solo repo para marketplace y plugin.** `.claude-plugin/marketplace.json` en la raíz y el plugin en `plugins/workshop-devs/` (fuente relativa). Menos piezas para la consultora, y más adelante se pueden agregar plugins para PMs y QA en el mismo marketplace.
2. **Nombres:** marketplace `tesseron-devs`, plugin `workshop-devs`. Ninguno cae en los nombres reservados de la doc.
3. **`pr-tesseron` pasó a llamarse `pr-tesseron`.** El nombre original tenía la marca de Tesseron y el kit lo usa la consultora en sus proyectos. Pone CodeCommit primero y GitHub segundo, con el mismo contenido.
4. **Las skills quedan en español neutro, con tú.** Los nombres de las tres primeras se mantienen (`grill-me`, `plan-worktree`, `test-rojo`) para que calcen con las slides.
5. **`test-rojo` suma el caso de caracterización** (modernizar): tests verdes que congelan el comportamiento actual, en commit aparte, antes de migrar. Es el hilo del curso.
6. **`grill-me` pregunta por los bordes bancarios** (redondeo con `BigDecimal`, zona horaria y corte de día, atomicidad de la auditoría).
7. **Quité de las skills lo que era del lab** (referencias a M4, "stories del lab", `npm test`). Quedó `./mvnw -q test` y `-Dtest=` para iterar.
8. **`plan-worktree` ya no habla de copiar skills a `~/.claude/skills`.** Con el plugin instalado a nivel usuario las skills están disponibles en cada worktree. Eso es una inferencia mía, no lo verifiqué contra la doc.
9. **Hooks con `${CLAUDE_PLUGIN_ROOT}`**, scripts dentro del plugin (`hooks/`), `timeout: 300` en el de tests.
10. **Cambios a los hooks respecto del demo:** `check-secrets` ignora `password=${VAR}` (referencias a variables, comunes en `application.properties` de Spring) para no bloquear commits legítimos; `check-tests-before-commit` usa `mvn` si no hay wrapper pero sí `pom.xml`, y no hace nada fuera de un proyecto Maven; sin `jq` ambos bloquean solo si el JSON crudo parece un `git commit` y piden instalarlo.
11. **Deny rules como plantilla, no dentro del plugin**, por la limitación de arriba. Agregué a las del demo `*.jks`, `*.p12`, `*.keystore`, `~/.aws/**`, `~/.ssh/**` y `~/.m2/settings.xml` (donde Maven guarda credenciales de Nexus o Artifactory).
12. **Sin `agents/`, `commands/` ni MCP.** El contrato habla de "skills, hooks y comandos", pero las skills ya se invocan como comandos (`/workshop-devs:...`) y la doc recomienda `skills/` para plugins nuevos.
13. **Playbook:** cada página tiene Para qué, Cómo y Errores típicos, y solo afirma lo que dice la doc oficial. Lo no verificado está marcado (retención de datos en Bedrock, on-premise sin internet, CodeCommit como host).
14. **Sin push, sin repo remoto.** Todo vive en este directorio.
