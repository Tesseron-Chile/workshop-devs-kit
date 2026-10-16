#!/usr/bin/env bash
# PreToolUse (Bash): bloquea `git commit` si los tests del proyecto fallan.
#   pom.xml      -> ./mvnw -q test (o mvn -q test si no hay wrapper)
#   package.json -> npm test
# Si no reconoce el stack, deja pasar. Si el repo ya trae el hook del lab
# (.claude/hooks/tests-antes-del-commit.mjs registrado en .claude/settings.json), no repite npm test.
# Entrada: JSON del hook por stdin. Salida: exit 2 bloquea y el mensaje de stderr le llega a Claude.
set -u
. "$(dirname "$0")/lib.sh"
read_commit_event check-tests-before-commit

fail() { # fail <comando> <código> <log>
  {
    echo "Commit bloqueado: los tests fallaron (código $2). Arregla el test o el código, o pide ayuda si no sale."
    echo "Comando: $1"
    echo "Últimas líneas del resultado:"
    tail -n 25 "$3"
  } >&2
  rm -f "$3"
  exit 2
}

run() { # run <comando...>
  local log; log="$(mktemp)"
  "$@" >"$log" 2>&1
  local code=$?
  [ "$code" -eq 0 ] && { rm -f "$log"; return 0; }
  fail "$*" "$code" "$log"
}

if [ -f pom.xml ]; then
  if [ -x ./mvnw ]; then run ./mvnw -q test
  elif command -v mvn >/dev/null 2>&1; then run mvn -q test
  else echo "AVISO workshop-devs: hay pom.xml pero no ./mvnw ni mvn, no se corrieron los tests." >&2
  fi
fi

if [ -f package.json ]; then
  if [ -f .claude/hooks/tests-antes-del-commit.mjs ] && grep -q 'tests-antes-del-commit' .claude/settings.json 2>/dev/null; then
    :   # el hook del proyecto ya corre npm test antes de este commit
  elif ! grep -q '"test"' package.json || grep -q 'no test specified' package.json; then
    :   # sin script de test: nada que correr
  elif command -v npm >/dev/null 2>&1; then
    run npm test
  else
    echo "AVISO workshop-devs: hay package.json pero no npm, no se corrieron los tests." >&2
  fi
fi
exit 0
