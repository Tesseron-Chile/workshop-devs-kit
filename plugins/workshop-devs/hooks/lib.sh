#!/usr/bin/env bash
# Funciones comunes de los hooks de workshop-devs. Se usa con `source`.
# Leer el JSON del evento no exige jq: prueba jq, luego python3, luego node.

COMMIT_RE='(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'

# json_get <clave> <ruta.con.puntos>: lee un campo del JSON de $input. Devuelve 3 si no hay con qué leerlo.
json_get() {
  local path="$1"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$input" | jq -r ".${path} // empty" 2>/dev/null
  elif command -v python3 >/dev/null 2>&1; then
    printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    for k in sys.argv[1].split("."):
        d = d[k]
    print(d if isinstance(d, str) else "")
except Exception:
    pass' "$path" 2>/dev/null
  elif command -v node >/dev/null 2>&1; then
    printf '%s' "$input" | node -e '
let s = ""; process.stdin.on("data", c => s += c).on("end", () => {
  try { let d = JSON.parse(s); for (const k of process.argv[1].split(".")) d = d[k]; if (typeof d === "string") console.log(d) } catch {}
})' "$path" 2>/dev/null
  else
    return 3
  fi
}

# Lee el evento y deja `command` y `cwd`. Sale con 0 si no es un `git commit`.
read_commit_event() {
  hook_name="$1"
  input="$(cat)"
  # Filtro barato: si el evento ni nombra "commit", no hay nada que revisar ni que parsear.
  case "$input" in *commit*) ;; *) exit 0 ;; esac
  if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1 && ! command -v node >/dev/null 2>&1; then
    echo "AVISO workshop-devs ($hook_name): no hay jq, python3 ni node para leer el evento, así que este commit no se revisó." >&2
    exit 0
  fi
  command="$(json_get tool_input.command)"
  cwd="$(json_get cwd)"
  printf '%s' "$command" | grep -Eq "$COMMIT_RE" || exit 0
  cd "${cwd:-.}" 2>/dev/null || exit 0
}
