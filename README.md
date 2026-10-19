# Kit del workshop de devs (Tesseron)

Plugin de Claude Code con las skills y los hooks del curso, para repos Maven y Node, más un playbook de una página por técnica. Este repo es a la vez el marketplace (`tesseron-devs`) y el plugin (`workshop-devs`).

Kit del Día 3 del curso (19-10-2026).

## LAB kit del lunes

Tres comandos, en cualquier terminal:

```
claude plugin marketplace add Tesseron-Chile/workshop-devs-kit
claude plugin install workshop-devs@tesseron-devs
claude plugin list
```

Para ver el hook bloquear un commit, en tu repo de grupo (el que salió del template):

1. Crea un test que falle a propósito, por ejemplo en `test/rojo.test.js`: `import test from 'node:test'; import assert from 'node:assert'; test('rojo', () => assert.fail('rojo'))`.
2. Pídele a Claude: «haz commit de todo con el mensaje "chore: prueba del hook"».
3. El commit no sale y Claude ve: «Commit bloqueado: los tests fallaron (código N). Arregla el test o el código, o pide ayuda si no sale.» Borra el test y el commit pasa.

Para el hook de secretos, agrega a un archivo una línea `password=hunter22xyz`, hazlo stage y pide el commit: el mensaje nombra el archivo y no imprime el valor.

## Windows

Claude Code en Windows corre los comandos con Git Bash, así que instala [Git for Windows](https://git-scm.com/download/win) antes que nada. Los hooks son scripts `bash` y corren con ese bash. `claude plugin marketplace add` y `install` usan el `git` de esa instalación.

- **Fin de línea.** Git for Windows trae `core.autocrlf=true`, que convierte los archivos a CRLF al clonar. Un `.sh` con CRLF falla con `$'\r': command not found` o `env: bash\r: No such file or directory`. El repo trae un `.gitattributes` que fuerza LF en los `.sh`, así que el clone de `marketplace add` los deja bien. Para comprobarlo, en Git Bash: `grep -c $'\r' ~/.claude/plugins/cache/tesseron-devs/workshop-devs/*/hooks/*.sh` debe dar `0` en cada archivo (`file <archivo>` dice "with CRLF line terminators" si no). Si da más de 0, corre `claude plugin marketplace update tesseron-devs` y reinstala; si persiste, clona con `git -c core.autocrlf=false clone ...` y usa el plan B (clone local).
- **`python3` de la Microsoft Store.** En Windows `python3` suele ser un alias de la tienda: está en el PATH pero no corre Python. Los hooks prueban cada lector (`jq`, `python3`, `node`) de verdad y usan el primero que funciona. Claude Code ya trae Node en el PATH de la sesión en la mayoría de las instalaciones. Si ninguno funciona, el hook deja pasar el commit y avisa por stderr.
- **Rutas.** El evento trae `cwd` como `C:\Users\...`; los hooks lo convierten con `cygpath -u` cuando existe.
- **Plan B del curso.** Si algo falla en un Windows, se muestra el hook desde un Mac.

Probado en Mac con simulación (clone con `core.autocrlf=true`, `python3` falso que sale con 9009, `cygpath` falso): `scripts/prueba-windows.sh`. Sin probar en un Windows real: la ejecución directa del `.sh` desde `hooks.json` en Git Bash, la ruta de `${CLAUDE_PLUGIN_ROOT}` con barras invertidas y el `cygpath` real.

## Qué trae

| Componente | Detalle |
|---|---|
| Skills | `grill-me`, `plan-worktree`, `test-rojo` (incluye tests de caracterización para modernizar), `pr-tesseron` (GitHub y CodeCommit). Detectan el stack: Maven (`./mvnw`) o Node (`npm test`) |
| Hooks | `PreToolUse` sobre `Bash`: `check-secrets` (bloquea `git commit` con una clave AWS, `password=valor` o una llave PEM) y `check-tests-before-commit` (bloquea `git commit` si fallan los tests: `./mvnw -q test` con `pom.xml`, `npm test` con `package.json`) |
| Playbook | `playbook/01` a `10`, una página por técnica |
| Plantillas | `templates/settings-deny.json` (deny rules para secretos) y `templates/managed-settings.example.json` (marketplace, plugin y deny rules exigidos por un administrador) |
| Pruebas | `scripts/prueba-limpia.sh` (instalación en máquina limpia) y `scripts/prueba-hooks.sh` (los hooks con eventos JSON reales) |

Las skills quedan con el prefijo del plugin: `/workshop-devs:grill-me`, `/workshop-devs:plan-worktree`, `/workshop-devs:test-rojo`, `/workshop-devs:pr-tesseron`.

### Hooks: sin `jq` obligatorio, y qué pasa en un repo del lab

Los hooks leen el JSON del evento con `jq`; si no está, con `python3`, y si tampoco, con `node`. Si no hay ninguno de los tres, dejan pasar el commit y avisan por stderr (no bloquean todo commit). Si no reconocen el stack, dejan pasar.

Los repos creados desde el template del lab ya traen un hook de proyecto (`.claude/hooks/tests-antes-del-commit.mjs`) que corre `npm test` antes de cada commit. Decisión: si el plugin ve ese hook registrado en `.claude/settings.json`, **no repite `npm test`** (el hook del proyecto ya lo hace, y los tests no corren dos veces). El hook de secretos del plugin sí corre siempre: se solapa con el del lab en claves AWS y llaves privadas, y suma `password=` y claves `ASIA`. Un repo Node sin ese hook de proyecto recibe `npm test` del plugin. Un repo con `package.json` sin script de test no corre nada.

## Instalar

Requisitos: Claude Code y `git`. Los hooks usan `jq`, `python3` o `node` (basta uno).

### Desde GitHub (camino principal)

```
claude plugin marketplace add Tesseron-Chile/workshop-devs-kit
claude plugin install workshop-devs@tesseron-devs
claude plugin list
```

Necesitas `git` y salida a GitHub. Si da error, prueba el plan B de abajo.

### Plan B: clone local o zip

```
git clone https://github.com/Tesseron-Chile/workshop-devs-kit.git      # o descarga el zip del repo y descomprímelo
claude plugin marketplace add /ruta/al/clone/workshop-devs-kit
claude plugin install workshop-devs@tesseron-devs
```

Dentro de una sesión, `/plugin marketplace add ...` hace lo mismo. Para actualizar: `claude plugin marketplace update tesseron-devs` y `claude plugin update workshop-devs@tesseron-devs`.

### Si el kit vive en un host git privado

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
printf '{"tool_name":"Bash","cwd":"%s","tool_input":{"command":"git commit -m x"}}' "$PWD" \
  | plugins/workshop-devs/hooks/check-secrets.sh; echo "exit=$?"
```

Exit 2 bloquea y el mensaje de stderr le llega a Claude. `scripts/prueba-hooks.sh <dir-del-plugin> <lab|java> <repo>` corre los casos completos (verde, rojo, secreto, con y sin `jq`).

## Desarrollo

```
claude plugin validate .
claude plugin validate plugins/workshop-devs
claude --plugin-dir plugins/workshop-devs
scripts/prueba-limpia.sh            # instalación en máquina limpia: contenedor (colima), Java, GitHub y sesión real
```

`version` está solo en `plugin.json`. Súbela en cada release: una instalación cacheada no recibe commits nuevos si la versión no cambia (para un marketplace agregado desde un directorio local no aplica, se lee en el lugar).

## Decisiones tomadas

1. **Un solo repo para marketplace y plugin.** `.claude-plugin/marketplace.json` en la raíz y el plugin en `plugins/workshop-devs/` (fuente relativa). Más adelante se pueden agregar plugins para PMs y QA en el mismo marketplace.
2. **Nombres:** marketplace `tesseron-devs`, plugin `workshop-devs`. Ninguno cae en los nombres reservados de la doc.
3. **Las skills salen de las del lab** (`.claude/skills/` de `workshop-devs-lab`, ajustadas en el Día 2) y se generalizan: detectan Maven o Node en vez de fijar `npm test`. La skill de PR se llama `pr-tesseron`, como en el curso, y mantiene la variante CodeCommit.
4. **Español neutro, con tú.** Los nombres de las skills calzan con las slides.
5. **`test-rojo` suma el caso de caracterización** (modernizar): tests verdes que congelan el comportamiento actual, en commit aparte, antes de migrar.
6. **`grill-me` pregunta por los bordes bancarios** (redondeo con `BigDecimal`, zona horaria y corte de día, atomicidad de la auditoría) cuando el sistema mueve dinero o fechas.
7. **Hooks con `${CLAUDE_PLUGIN_ROOT}`**, scripts dentro del plugin (`hooks/`), `timeout: 300` en `hooks.json` (aplica a ambos hooks).
8. **Hooks por stack, sin `jq` obligatorio, y sin doble `npm test` en repos del lab** (ver arriba).
9. **`check-secrets` ignora `password=${VAR}`** (referencias a variables, comunes en `application.properties` de Spring) y nombra el archivo sin imprimir el valor.
10. **Deny rules como plantilla, no dentro del plugin**: un plugin no puede llevar `permissions.deny`. Las plantillas suman `*.jks`, `*.p12`, `*.keystore`, `~/.aws/**`, `~/.ssh/**` y `~/.m2/settings.xml`.
11. **Sin `agents/`, `commands/` ni MCP.** Las skills ya se invocan como comandos (`/workshop-devs:...`) y la doc recomienda `skills/` para plugins nuevos.
12. **Playbook:** cada página tiene Para qué, Cómo y Errores típicos, contrastada con lo que se enseñó en los decks de los Días 1 a 3. Lo no verificado está marcado (retención de datos en Bedrock, on-premise sin internet, CodeCommit como host).
