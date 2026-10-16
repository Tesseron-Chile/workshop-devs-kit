#!/usr/bin/env bash
# Prueba de instalación en máquina limpia del kit (plugin workshop-devs, marketplace tesseron-devs).
#
# Uso: scripts/prueba-limpia.sh [contenedor|java|github|sesion|todo]
#   contenedor  Node 22 + Claude Code (npm) con HOME vacío, en colima/Docker: marketplace add desde un
#               clone montado, plugin install, plugin list y los hooks sobre un clone del lab.
#   java        Los hooks sobre una copia del repo Java demo, en el host (el contenedor no trae JDK).
#   github      En el host, con CLAUDE_CONFIG_DIR temporal: marketplace add desde GitHub e install.
#   sesion      En el host, con el plugin instalado desde GitHub: sesión real corta con /workshop-devs:test-rojo.
#   todo        Las cuatro, en ese orden (por defecto).
#
# Variables: LAB (clone del lab), JAVA_DEMO (repo Java demo), REF (rama o tag del marketplace en GitHub,
# por defecto la rama actual), REPO_GH (por defecto Tesseron-Chile/workshop-devs-kit),
# SESION_CONFIG (perfil de Claude Code con login para la sesión real, por defecto ~/.claude-demo).
# Si colima no levanta, `contenedor` se reemplaza por `host-limpio`: lo mismo con HOME y CLAUDE_CONFIG_DIR temporales.
set -u
KIT="$(cd "$(dirname "$0")/.." && pwd)"
LAB="${LAB:-$HOME/dev/tesseron/workshop-devs-lab}"
JAVA_DEMO="${JAVA_DEMO:-$HOME/dev/tesseron/workshop-devs-demo-java}"
REPO_GH="${REPO_GH:-Tesseron-Chile/workshop-devs-kit}"
REF="${REF:-$(git -C "$KIT" rev-parse --abbrev-ref HEAD)}"
SESION_CONFIG="${SESION_CONFIG:-$HOME/.claude-demo}"
export PATH="/opt/homebrew/bin:$PATH"
FALLAS=0

paso() { echo; echo "### $*"; }
ok() { "$@"; local c=$?; [ $c -eq 0 ] || { echo "FALLA (exit $c): $*"; FALLAS=$((FALLAS+1)); }; return $c; }

contenedor() {
  paso "Contenedor limpio: node:22, HOME vacío, Claude Code instalado con npm"
  colima status >/dev/null 2>&1 || colima start --cpu 2 --memory 4 || { echo "colima no levanta: usa host-limpio"; return 1; }
  # Se prueba lo commiteado: el contenedor clona el repo montado, no ve cambios sin commit.
  git -C "$KIT" diff --quiet HEAD || echo "AVISO: hay cambios sin commit; el contenedor solo ve lo commiteado."
  # El clone va bajo $HOME porque colima solo comparte esa ruta con el contenedor.
  CLONES="$(mktemp -d "$HOME/.prueba-limpia.XXXXXX")"
  git clone -q -b "$REF" "$KIT" "$CLONES/kit" || { echo "no se pudo clonar $REF"; return 1; }
  ok docker run --rm -v "$CLONES/kit:/kit-src:ro" -v "$LAB:/lab-src:ro" node:22 bash -c '
    set -u
    git config --global --add safe.directory "*"
    export HOME=$(mktemp -d); cd "$HOME"
    echo "HOME=$HOME (vacío): $(ls -A $HOME | wc -l) archivos"
    echo "jq en el contenedor: $(command -v jq || echo no)"
    npm install -g @anthropic-ai/claude-code >/dev/null 2>&1; echo "claude $(claude --version)"
    git clone -q /kit-src /kit
    echo "--- claude plugin marketplace add /kit";  claude plugin marketplace add /kit || exit 1
    echo "--- claude plugin install workshop-devs@tesseron-devs"; claude plugin install workshop-devs@tesseron-devs || exit 1
    echo "--- claude plugin list"; claude plugin list || exit 1
    echo "--- skills instaladas"; ls $HOME/.claude/plugins/cache/*/workshop-devs/*/skills
    echo "--- claude plugin validate /kit";  claude plugin validate /kit || exit 1
    P=$(dirname $(dirname $(find $HOME/.claude/plugins/cache -name check-secrets.sh | head -1)))
    echo "plugin instalado en $P"
    git clone -q /lab-src /lab
    bash /kit/scripts/prueba-hooks.sh "$P" lab /lab completo'
  rm -rf "$CLONES"
}

java() {
  paso "Hooks sobre una copia del repo Java demo (host, mvnw)"
  ok "$KIT/scripts/prueba-hooks.sh" "$KIT/plugins/workshop-devs" java "$JAVA_DEMO" completo
}

host_config() { # crea un HOME y un CLAUDE_CONFIG_DIR temporales
  T="$(mktemp -d)"; export CLAUDE_CONFIG_DIR="$T/claude-config"; mkdir -p "$CLAUDE_CONFIG_DIR"
}

github() {
  paso "Host con CLAUDE_CONFIG_DIR temporal: marketplace desde GitHub ($REPO_GH, ref $REF)"
  host_config
  echo "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR"
  ok claude plugin marketplace add "$REPO_GH#$REF" || return 1
  ok claude plugin install workshop-devs@tesseron-devs || return 1
  ok claude plugin list
  echo "--- hooks del plugin instalado desde GitHub, sobre un clone del lab"
  P="$(dirname "$(dirname "$(find "$CLAUDE_CONFIG_DIR/plugins" -name check-secrets.sh | head -1)")")"
  L="$(mktemp -d)"; git clone -q "$LAB" "$L/lab"
  ok "$KIT/scripts/prueba-hooks.sh" "$P" lab "$L/lab" rapido
  GH_CONFIG_DIR_USED="$CLAUDE_CONFIG_DIR"
}

sesion() {
  paso "Sesión real corta: /workshop-devs:test-rojo sobre un clone del lab"
  [ -n "${GH_CONFIG_DIR_USED:-}" ] || github >/dev/null || return 1
  # La sesión necesita login, que en macOS va atado a la ruta del perfil: no se copia. Se usa el perfil con login
  # tal cual (SESION_CONFIG) y se carga con --plugin-dir la copia del plugin que `github` instaló desde GitHub.
  export CLAUDE_CONFIG_DIR="$SESION_CONFIG"
  PLUGIN_GH="$(dirname "$(dirname "$(find "$GH_CONFIG_DIR_USED/plugins" -name check-secrets.sh | head -1)")")"
  L="$(mktemp -d)"; git clone -q "$LAB" "$L/lab"; cd "$L/lab" || return 1
  echo "--- claude -p \"/workshop-devs:test-rojo criterio 2 de la SPEC\" (sonnet, max 12 turnos, solo en $L/lab)"
  ok claude -p "/workshop-devs:test-rojo Aplica a la story del criterio 2 de workdocs/SPEC.md. No escribas código de producto, no hagas commit." \
    --plugin-dir "$PLUGIN_GH" --model sonnet --max-turns 12 --permission-mode acceptEdits --output-format json < /dev/null > "$L/salida.json" 2> "$L/salida.err"
  python3 - "$L/salida.json" <<'PY'
import sys, json
txt = open(sys.argv[1]).read()
d = json.loads(txt.strip().splitlines()[-1]) if txt.strip() else {}
print("resultado:", str(d.get("result", ""))[:1200]); print("turnos:", d.get("num_turns"), "costo_usd:", d.get("total_cost_usd"))
PY
  head -c 600 "$L/salida.err"
  git -C "$L/lab" status --short
}

case "${1:-todo}" in
  contenedor) contenedor ;;
  java) java ;;
  github) github ;;
  sesion) sesion ;;
  todo) contenedor; java; github; sesion ;;
  *) echo "uso: $0 [contenedor|java|github|sesion|todo]"; exit 2 ;;
esac
echo; echo "== Prueba limpia: $FALLAS paso(s) con falla =="
[ "$FALLAS" -eq 0 ]
