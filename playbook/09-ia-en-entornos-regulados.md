# 9. IA en entornos regulados

**Para qué:** usar Claude Code en proyectos de banco con control explícito de qué puede leer, ejecutar y salir de la máquina.

**1. Proveedor en tu cuenta cloud.** Claude Code puede usar el modelo vía Amazon Bedrock en tu cuenta de AWS: `CLAUDE_CODE_USE_BEDROCK=1` y `AWS_REGION`, con las credenciales de la cadena estándar de AWS. Fija las versiones de modelo con `ANTHROPIC_DEFAULT_*_MODEL` antes de desplegar a un equipo. Qué retención de datos aplica es un tema contractual con AWS: no está en esta página, confírmalo con la documentación y el contrato de tu cuenta. (Google Vertex es la otra opción documentada.)

**2. Modos de permiso.** `default` pregunta en el primer uso de cada herramienta; `plan` solo explora; `acceptEdits` acepta ediciones; `dontAsk` deniega todo lo que pediría permiso (CI); `auto` usa un clasificador; `bypassPermissions` salta los prompts y solo es seguro dentro de un contenedor o máquina aislada. Se puede impedir `bypassPermissions` con `permissions.disableBypassPermissionsMode: "disable"`, sobre todo desde managed settings.

**3. Deny rules.** Las reglas se evalúan en orden deny, ask, allow, y la primera que coincide decide. `Read(./.env)` y similares bloquean las herramientas de archivos y comandos como `cat`, `head`, `tail` y `sed` sobre esa ruta. No cubren un script que abre archivos por su cuenta (Python o Node, por ejemplo). Plantilla: `templates/settings-deny.json`.

**4. Sandbox.** Es un límite del sistema operativo sobre los comandos de shell: macOS (Seatbelt), Linux y WSL2 (bubblewrap); en Windows nativo no aplica. Está apagado por defecto: se activa con `/sandbox` o `sandbox.enabled`. Por defecto la lectura es amplia (incluye `~/.aws` y `~/.ssh`), así que restríngela con `filesystem.denyRead`. No cubre las herramientas de archivos ni los hooks: por eso deny rules y sandbox se usan juntos.

**5. Managed settings.** Un administrador puede exigir el marketplace y el plugin en cada máquina (`extraKnownMarketplaces` y `enabledPlugins`), limitar de dónde se instalan plugins (`strictKnownMarketplaces`) y fijar las deny rules donde el usuario no las pueda sacar. Ejemplo: `templates/managed-settings.example.json`.

**6. Hooks como control** (técnica 6) para las reglas que no deben depender de que el modelo obedezca.

**7. On-premise.** Lo que la doc documenta: un marketplace en un directorio compartido (sin acceso a un host git), y un seed de plugins para contenedores y runners (`CLAUDE_CODE_PLUGIN_SEED_DIR`) que se instala sin clonar. No verificado: qué conexiones de salida necesita Claude Code en una red sin internet, y si el modelo puede servirse desde dentro de esa red. Confírmalo con la doc de red (`/network-config`) y con el equipo de redes antes de prometerlo.

**Fuentes:** code.claude.com/docs/en/permissions, /sandboxing, /amazon-bedrock, /plugins/org
