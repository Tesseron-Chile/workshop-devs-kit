#!/usr/bin/env bash
# PreToolUse (Bash): bloquea `git commit` si los tests de Maven fallan.
# Usa `./mvnw -q test`; si no hay wrapper pero sí pom.xml y `mvn`, usa `mvn -q test`.
# Entrada: JSON del hook por stdin. Salida: exit 2 bloquea y el mensaje de stderr le llega a Claude.
set -u

input="$(cat)"
COMMIT_RE='(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'

if ! command -v jq >/dev/null 2>&1; then
  if printf '%s' "$input" | grep -Eq "git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit"; then
    echo "BLOQUEADO por workshop-devs: falta 'jq' en el PATH, así que no se puede revisar el commit. Instala jq y reintenta." >&2
    exit 2
  fi
  exit 0
fi

command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"

if ! printf '%s' "$command" | grep -Eq "$COMMIT_RE"; then
  exit 0
fi

cd "${cwd:-.}" || exit 0

if [ -x ./mvnw ]; then
  runner="./mvnw"
elif [ -f pom.xml ] && command -v mvn >/dev/null 2>&1; then
  runner="mvn"
else
  exit 0   # no es un proyecto Maven: no hay nada que correr
fi

log="$(mktemp)"
if "$runner" -q test >"$log" 2>&1; then
  rm -f "$log"
  exit 0
fi

{
  echo "BLOQUEADO por workshop-devs (check-tests-before-commit): '$runner -q test' falla."
  echo "Últimas líneas del resultado:"
  grep -E 'ERROR|FAIL|Tests run:' "$log" | head -15
  echo "Arregla los tests y vuelve a intentar el commit. Log completo: $log"
} >&2
exit 2
