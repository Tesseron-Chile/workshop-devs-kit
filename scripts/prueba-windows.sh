#!/usr/bin/env bash
# Simula en Mac o Linux lo que Git for Windows le hace al kit. No reemplaza una prueba en un Windows real.
# Uso: scripts/prueba-windows.sh [rama]   (por defecto la rama actual; debe estar commiteada)
#   1. Clona con core.autocrlf=true, que es el default de Git for Windows, con y sin .gitattributes.
#   2. Comprueba que con .gitattributes los .sh quedan en LF y sin él quedan en CRLF (y bash falla).
#   3. Corre los hooks del clone con CRLF forzado contra un clone del lab, incluido el python3 falso de la
#      Microsoft Store y un cwd con ruta de Windows (con un cygpath falso).
set -u
KIT="$(cd "$(dirname "$0")/.." && pwd)"
REF="${1:-$(git -C "$KIT" rev-parse --abbrev-ref HEAD)}"
LAB="${LAB:-$HOME/dev/tesseron/workshop-devs-lab}"
FALLAS=0
T="$(mktemp -d)"

con_cr() { grep -c $'\r' "$1" 2>/dev/null; }
chequeo() { # chequeo <nombre> <ok 0/1>
  if [ "$2" = 1 ]; then echo "  OK     $1"; else echo "  FALLA  $1"; FALLAS=$((FALLAS+1)); fi
}

echo "== 1. Clone con core.autocrlf=true, con .gitattributes ($REF) =="
git -c core.autocrlf=true clone -q -b "$REF" "$KIT" "$T/con" || exit 1
for f in "$T"/con/plugins/workshop-devs/hooks/*.sh "$T"/con/scripts/*.sh; do
  [ "$(con_cr "$f")" = 0 ]; chequeo "LF en ${f#$T/con/}" $([ $? -eq 0 ] && echo 1 || echo 0)
done
echo '{"tool_name":"Bash","cwd":"/tmp","tool_input":{"command":"ls"}}' | "$T/con/plugins/workshop-devs/hooks/check-secrets.sh" 2>"$T/err"
chequeo "el hook corre sin errores de \\r (exit 0)" $([ $? -eq 0 ] && ! grep -q $'\r' "$T/err" && echo 1 || echo 0)

echo "== 2. El mismo clone sin .gitattributes: se reproduce el problema =="
git -c core.autocrlf=true clone -q -b "$REF" "$KIT" "$T/sin" || exit 1
( cd "$T/sin" && rm .gitattributes && git rm --cached -rq . && git reset -q --hard 2>/dev/null; git -c core.autocrlf=true checkout -q -f . 2>/dev/null; rm -rf plugins; git -c core.autocrlf=true checkout -q -- plugins )
n="$(con_cr "$T/sin/plugins/workshop-devs/hooks/check-secrets.sh")"
chequeo "sin .gitattributes los .sh quedan con CRLF ($n líneas)" $([ "${n:-0}" -gt 0 ] && echo 1 || echo 0)
echo '{}' | "$T/sin/plugins/workshop-devs/hooks/check-secrets.sh" 2>"$T/err2"; c=$?
echo "  (sin .gitattributes: exit $c; $(head -c 160 "$T/err2" | tr -d '\r' | head -1))"

echo "== 3. Hooks del clone con .gitattributes, incluidos python3 falso y cwd de Windows =="
"$T/con/scripts/prueba-hooks.sh" "$T/con/plugins/workshop-devs" lab "$LAB" completo || FALLAS=$((FALLAS+1))

rm -rf "$T"
echo "== Windows simulado: $FALLAS falla(s) =="
[ "$FALLAS" -eq 0 ]
