# 1. Contexto por capas

**Para qué:** que el agente parta cada sesión sabiendo las reglas del repo sin que las pegues en el chat.

**Cómo**

1. Un `CLAUDE.md` en la raíz del repo con lo que aplica a todo: stack, comandos (`./mvnw -q test`), convenciones y reglas que no se negocian (montos en `BigDecimal`, sin secretos, el humano hace el merge).
2. Un `CLAUDE.md` por módulo con las reglas de ese módulo. Claude Code carga los de subdirectorios cuando lee o edita un archivo de esa carpeta.
3. `@imports` para no duplicar: `@AGENTS.md`, `@docs/arquitectura.md`. Se resuelven relativos al archivo que los contiene, y un import puede importar otros hasta cuatro saltos.
4. Si el repo ya tiene un `AGENTS.md` para otras herramientas, impórtalo desde `CLAUDE.md` con `@AGENTS.md` y agrega debajo lo propio de Claude.
5. Reglas por tipo de archivo en `.claude/rules/` (un `.md` por tema).

**Plantilla mínima**

```
@AGENTS.md

## Claude Code
- Antes de codear lee workdocs/SPEC.md y la story en workdocs/PLAN.md.
- Tests: ./mvnw -q test
```

**Errores típicos**

- Un CLAUDE.md largo y vago. Lo específico y corto se sigue mejor.
- Instrucciones que se contradicen entre capas: revísalas de vez en cuando.
- Tratarlo como control. CLAUDE.md es contexto, no una garantía: lo que debe bloquearse va en un hook (técnica 6) o en permisos (técnica 9).

**Fuente:** code.claude.com/docs/en/memory
