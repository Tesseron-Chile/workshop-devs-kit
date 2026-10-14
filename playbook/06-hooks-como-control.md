# 6. Hooks como control

**Para qué:** lo que un CLAUDE.md pide por favor, un hook lo hace cumplir. Un hook corre código tuyo en un evento, y con exit 2 en `PreToolUse` bloquea la llamada y le pasa el mensaje de stderr a Claude.

**Qué trae este plugin** (`plugins/workshop-devs/hooks/hooks.json`, evento `PreToolUse`, matcher `Bash`)

| Hook | Bloquea cuando |
|---|---|
| `check-secrets.sh` | `git commit` con un diff que trae una clave AWS (AKIA/ASIA), `password=valor` o una llave PEM privada |
| `check-tests-before-commit.sh` | `git commit` y `./mvnw -q test` falla (usa `mvn` si no hay wrapper) |

Los scripts leen el JSON del evento por stdin (`tool_input.command`, `cwd`) y requieren `jq`. Se referencian con `${CLAUDE_PLUGIN_ROOT}`.

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
