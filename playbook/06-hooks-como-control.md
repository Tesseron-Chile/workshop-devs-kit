# 6. Hooks como control

**Para qué:** lo que un CLAUDE.md pide por favor, un hook lo hace cumplir. Un hook corre código tuyo en un evento, y con exit 2 en `PreToolUse` bloquea la llamada y le pasa el mensaje de stderr a Claude.

**Qué trae este plugin** (`plugins/workshop-devs/hooks/hooks.json`, evento `PreToolUse`, matcher `Bash`)

| Hook | Bloquea cuando |
|---|---|
| `check-secrets.sh` | `git commit` con un diff que trae una clave AWS (AKIA/ASIA), `password=valor` o una llave PEM privada. El mensaje dice qué encontró y en qué archivo, sin imprimir el valor |
| `check-tests-before-commit.sh` | `git commit` y fallan los tests: `./mvnw -q test` (o `mvn -q test`) si hay `pom.xml`, `npm test` si hay `package.json`. Si no reconoce el stack, deja pasar |

El mensaje de bloqueo es el del curso: «Commit bloqueado: los tests fallaron (código N). Arregla el test o el código, o pide ayuda si no sale.»

Los scripts leen el JSON del evento por stdin (`tool_input.command`, `cwd`) con `jq`, o con `python3` o `node` si no hay `jq`. Si no hay ninguno de los tres, dejan pasar el commit con un aviso. Se referencian con `${CLAUDE_PLUGIN_ROOT}`.

**Hook del proyecto y hook del plugin.** Un repo creado desde el template del lab ya trae su propio hook (`.claude/hooks/tests-antes-del-commit.mjs`, registrado en `.claude/settings.json`) que corre `npm test` y revisa secretos. En ese repo el hook de tests del plugin lo detecta y no repite `npm test`; el de secretos sí corre, porque además revisa `password=` y claves ASIA.

**Probar un hook a mano**

```
echo '{"tool_name":"Bash","cwd":"'"$PWD"'","tool_input":{"command":"git commit -m x"}}' \
  | plugins/workshop-devs/hooks/check-secrets.sh; echo "exit=$?"
```

**Límites**

- Un hook que expira no bloquea la llamada, según la doc. Para el de tests, `hooks.json` fija `timeout: 300`.
- Los patrones de secretos son simples a propósito. No reemplazan a un scanner real en el pipeline.
- Para una regla de permitir o denegar dura, la doc recomienda el sistema de permisos antes que un hook (técnica 9).
- Un hook corre en tu máquina con tus permisos. Revisa el código de cualquier plugin antes de instalarlo.

**Fuente:** code.claude.com/docs/en/hooks
