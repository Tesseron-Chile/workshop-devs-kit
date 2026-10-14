# 7. Headless (`claude -p`) en scripts y CI

**Para qué:** usar a Claude como una herramienta más de la línea de comandos: revisar un diff, auditar código, resumir un log.

**Lo básico**

```
git diff main...HEAD | claude -p "Revisa este diff contra workdocs/SPEC.md. Lista solo bugs reales, con archivo y línea."
```

| Flag | Para qué |
|---|---|
| `-p` | Una sola corrida, imprime y termina. Sale con código 0 si todo fue bien |
| `--output-format json` | JSON con `result` y metadatos, incluido `total_cost_usd` |
| `--json-schema` | Salida con forma fija, en el campo `structured_output` |
| `--allowedTools` | Herramientas que corren sin pedir permiso. Para auditoría, solo lectura |
| `--permission-mode` | `dontAsk` deniega todo lo que pediría permiso (útil en CI) |
| `--bare` | Arranque sin hooks, skills ni plugins del host. La doc lo recomienda para scripts y CI |

**En CI**

- Con `--bare` no se lee la sesión de tu cuenta: define las credenciales por variables de entorno. Con Bedrock usa `CLAUDE_CODE_USE_BEDROCK=1` y `AWS_REGION`; las credenciales de proveedores cloud se siguen leyendo.
- Sin `--bare`, un `claude -p` corre los hooks de `.claude/settings.json` del repo aunque nadie haya aceptado el diálogo de confianza.
- Para cargar este plugin en una corrida `--bare`, pásalo con `--plugin-dir`.
- Un pipeline de CodeCommit puede obtener el diff con `aws codecommit get-differences` o con git, y publicar el resultado con `aws codecommit post-comment-for-pull-request`.

**Errores típicos**

- Dar `Bash` completo a una corrida desatendida. Lista los comandos exactos, por ejemplo `Bash(git diff *)`.
- Tratar el review automático como veredicto: es una entrada para el humano que decide.

**Fuente:** code.claude.com/docs/en/headless
