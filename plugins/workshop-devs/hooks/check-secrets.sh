#!/usr/bin/env bash
# PreToolUse (Bash): bloquea `git commit` si el diff a commitear trae un secreto.
# Patrones simples a propósito: claves AWS, password=, llaves PEM. No reemplaza a un scanner real.
# Entrada: JSON del hook por stdin. Salida: exit 2 bloquea y el mensaje de stderr le llega a Claude.
set -u

input="$(cat)"
COMMIT_RE='(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'

if ! command -v jq >/dev/null 2>&1; then
  # Sin jq no se puede leer el comando con precisión: se bloquea solo si el JSON crudo parece un commit.
  if printf '%s' "$input" | grep -Eq "git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit"; then
    echo "BLOQUEADO por workshop-devs: falta 'jq' en el PATH, así que no se puede revisar el commit. Instala jq y reintenta." >&2
    exit 2
  fi
  exit 0
fi

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"

# Solo actúa sobre `git commit`.
if ! printf '%s' "$command" | grep -Eq "$COMMIT_RE"; then
  exit 0
fi

cd "${cwd:-.}" || exit 0

# `git commit -a` también commitea cambios sin stage: se revisa contra HEAD en ese caso.
if printf '%s' "$command" | grep -Eq 'commit[^|;&]*[[:space:]]-[a-zA-Z]*a'; then
  diff="$(git diff HEAD -- . ':(exclude).claude/hooks')"
else
  diff="$(git diff --cached -- . ':(exclude).claude/hooks')"
fi

added="$(printf '%s\n' "$diff" | grep -E '^\+' | grep -Ev '^\+\+\+')"

hits=""
if printf '%s\n' "$added" | grep -Eq 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}'; then
  hits="${hits}- clave de acceso AWS (AKIA/ASIA...)\n"
fi
# password=valor. Se ignoran los valores que empiezan con $ (referencias como ${DB_PASSWORD}).
if printf '%s\n' "$added" | grep -Eiq '(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*["'\'']?[^[:space:]"'\''$][^[:space:]"'\'']{2,}'; then
  hits="${hits}- asignación de password (password=...)\n"
fi
if printf '%s\n' "$added" | grep -Eq -- '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'; then
  hits="${hits}- llave privada PEM\n"
fi

if [ -n "$hits" ]; then
  {
    echo "BLOQUEADO por workshop-devs (check-secrets): el diff a commitear parece traer un secreto."
    printf '%b' "$hits"
    echo "Saca el secreto del código (variable de entorno o gestor de secretos), quítalo del stage y vuelve a intentar."
  } >&2
  exit 2
fi
exit 0
