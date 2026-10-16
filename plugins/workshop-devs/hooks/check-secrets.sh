#!/usr/bin/env bash
# PreToolUse (Bash): bloquea `git commit` si el diff a commitear trae un secreto.
# Patrones simples a propósito: claves AWS, password=, llaves PEM. No reemplaza a un scanner real.
# Entrada: JSON del hook por stdin. Salida: exit 2 bloquea y el mensaje de stderr le llega a Claude.
# El mensaje dice qué se encontró y en qué archivo, nunca el valor.
set -u
. "$(dirname "$0")/lib.sh"
read_commit_event check-secrets

# `git commit -a` también commitea cambios sin stage: se revisa contra HEAD en ese caso.
if printf '%s' "$command" | grep -Eq 'commit[^|;&]*[[:space:]]-[a-zA-Z]*a'; then
  base="HEAD"
else
  base="--cached"
fi
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
git rev-parse --verify -q HEAD >/dev/null 2>&1 || base="--cached"

files="$(git diff $base --name-only -- . ':(exclude).claude/hooks' 2>/dev/null)"
[ -n "$files" ] || exit 0

hits=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  added="$(git diff $base -U0 -- "$f" | grep -E '^\+' | grep -Ev '^\+\+\+')"
  [ -n "$added" ] || continue
  if printf '%s\n' "$added" | grep -Eq 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}'; then
    hits="${hits}- clave de acceso AWS (AKIA/ASIA...) en $f\n"
  fi
  # password=valor. Se ignoran los valores que empiezan con $ (referencias como ${DB_PASSWORD}).
  if printf '%s\n' "$added" | grep -Eiq '(password|passwd|pwd)[[:space:]]*[=:][[:space:]]*["'\'']?[^[:space:]"'\''$][^[:space:]"'\'']{2,}'; then
    hits="${hits}- asignación de password (password=...) en $f\n"
  fi
  if printf '%s\n' "$added" | grep -Eq -- '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'; then
    hits="${hits}- llave privada PEM en $f\n"
  fi
done <<< "$files"

if [ -n "$hits" ]; then
  {
    echo "Commit bloqueado por workshop-devs (check-secrets): el diff a commitear parece traer un secreto."
    printf '%b' "$hits"
    echo "Saca el secreto del código (variable de entorno o gestor de secretos), quítalo del stage con git restore --staged <archivo> y vuelve a intentar. Si ya estuvo en algún archivo, rota la credencial."
  } >&2
  exit 2
fi
exit 0
