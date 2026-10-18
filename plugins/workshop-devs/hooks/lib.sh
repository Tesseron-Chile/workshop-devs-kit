#!/usr/bin/env bash
# Funciones comunes de los hooks de workshop-devs. Se usa con `source`.
# Leer el JSON del evento no exige jq: prueba jq, luego python3, luego node.

COMMIT_RE='(^|[;&|[:space:]])git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?commit([[:space:]]|$)'

# Un lector sirve solo si de verdad corre y entrega lo esperado. En Windows `python3` suele ser el alias de la
# Microsoft Store: existe en el PATH, pero sale con error y no imprime nada, así que `command -v` no alcanza.
reader_works() {
  case "$1" in
    jq)      [ "$(jq -n '1' 2>/dev/null)" = "1" ] ;;
    python3) [ "$(python3 -c 'print(1)' 2>/dev/null)" = "1" ] ;;
    node)    [ "$(node -e 'console.log(1)' 2>/dev/null)" = "1" ] ;;
    *) return 1 ;;
  esac
}

# Deja en READERS los lectores que funcionan, en orden de preferencia.
find_readers() {
  READERS=""
  local r
  for r in jq python3 node; do
    command -v "$r" >/dev/null 2>&1 && reader_works "$r" && READERS="$READERS $r"
  done
}

# json_get <ruta.con.puntos>: lee un campo del JSON de $input con el primer lector que funcione.
json_get() {
  local path="$1" r out
  for r in $READERS; do
    case "$r" in
      jq) out="$(printf '%s' "$input" | jq -r ".${path} // empty" 2>/dev/null)" ;;
      python3) out="$(printf '%s' "$input" | python3 -c '
import sys, json
d = json.load(sys.stdin)
for k in sys.argv[1].split("."):
    d = d[k]
print(d if isinstance(d, str) else "")' "$path" 2>/dev/null)" ;;
      node) out="$(printf '%s' "$input" | node -e '
let s = ""; process.stdin.on("data", c => s += c).on("end", () => {
  let d = JSON.parse(s); for (const k of process.argv[1].split(".")) d = d[k]; if (typeof d === "string") console.log(d)
})' "$path" 2>/dev/null)" ;;
    esac
    # Un lector que sale bien con el campo vacío es una respuesta ("no hay campo"); uno que falla pasa al siguiente.
    [ $? -eq 0 ] && { printf '%s' "$out"; return 0; }
  done
  return 3
}

# En Windows el evento trae rutas como C:\Users\...: Git Bash las entiende con cygpath.
unix_path() {
  case "$1" in
    [A-Za-z]:[\\/]*|*\\*) command -v cygpath >/dev/null 2>&1 && cygpath -u "$1" 2>/dev/null && return 0 ;;
  esac
  printf '%s' "$1"
}

# Lee el evento y deja `command` y `cwd`. Sale con 0 si no es un `git commit`.
read_commit_event() {
  hook_name="$1"
  input="$(cat)"
  # Filtro barato: si el evento ni nombra "commit", no hay nada que revisar ni que parsear.
  case "$input" in *commit*) ;; *) exit 0 ;; esac
  find_readers
  if [ -z "$READERS" ]; then
    echo "AVISO workshop-devs ($hook_name): ni jq, ni python3, ni node funcionan para leer el evento, así que este commit no se revisó." >&2
    exit 0
  fi
  command="$(json_get tool_input.command)" || { echo "AVISO workshop-devs ($hook_name): no se pudo leer el evento, este commit no se revisó." >&2; exit 0; }
  cwd="$(json_get cwd)"
  printf '%s' "$command" | grep -Eq "$COMMIT_RE" || exit 0
  if [ -n "$cwd" ]; then
    cd "$(unix_path "$cwd")" 2>/dev/null || { echo "AVISO workshop-devs ($hook_name): no se pudo entrar a '$cwd', este commit no se revisó." >&2; exit 0; }
  fi
}
