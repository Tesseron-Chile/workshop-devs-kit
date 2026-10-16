#!/usr/bin/env bash
# Corre los dos hooks del plugin con eventos JSON reales sobre una copia de un repo.
# Uso: prueba-hooks.sh <dir-del-plugin> <lab|java> <dir-del-repo-origen> [completo|rapido]
# Cada caso imprime OK o FALLA. Sale con 1 si algún caso falla.
set -u
PLUGIN="$1"; TIPO="$2"; ORIGEN="$3"; MODO="${4:-completo}"
HOOKS="$PLUGIN/hooks"
FALLAS=0; SHIM=""

caso() { # caso <nombre> <exit esperado> <exit real> [texto esperado en stderr] [texto prohibido]
  local nombre="$1" esp="$2" real="$3" debe="${4:-}" noDebe="${5:-}" ok=1
  [ "$esp" = "$real" ] || ok=0
  [ -z "$debe" ] || grep -qF -- "$debe" "$ERR" || ok=0
  [ -z "$noDebe" ] || ! grep -qF -- "$noDebe" "$ERR" || ok=0
  if [ "$ok" = 1 ]; then echo "  OK     $nombre (exit $real)"; else echo "  FALLA  $nombre (esperado $esp, real $real)"; sed 's/^/         | /' "$ERR" | head -8; FALLAS=$((FALLAS+1)); fi
}

evento() { # evento <comando> -> JSON del hook, armado con python3 o node del host
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import json,sys; print(json.dumps({"tool_name":"Bash","cwd":sys.argv[2],"tool_input":{"command":sys.argv[1]}}))' "$1" "$WORK"
  else
    node -e 'console.log(JSON.stringify({tool_name:"Bash",cwd:process.argv[2],tool_input:{command:process.argv[1]}}))' "$1" "$WORK"
  fi
}

# path_sin <herramientas...>: un PATH con todo lo del PATH actual menos esas herramientas.
path_sin() {
  SHIM="$(mktemp -d)"
  local d f n x skip
  local IFS=:
  for d in $PATH; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
      n="$(basename "$f")"; skip=0
      for x in "$@"; do [ "$n" = "$x" ] && skip=1; done
      [ "$skip" = 1 ] || [ -e "$SHIM/$n" ] || ln -s "$f" "$SHIM/$n" 2>/dev/null
    done
  done
  echo "$SHIM"
}

correr() { # correr <hook> <comando-git> [PATH]
  local hook="$1" cmd="$2" p="${3:-$PATH}" ev
  ev="$(evento "$cmd")"
  printf '%s' "$ev" | PATH="$p" "$HOOKS/$hook" >/dev/null 2>"$ERR"
  return $?
}

preparar() { # copia limpia del repo con un commit inicial
  WORK="$(mktemp -d)"; ERR="$(mktemp)"
  if [ -d "$ORIGEN/.git" ]; then git clone -q "$ORIGEN" "$WORK" 2>/dev/null; else cp -R "$ORIGEN/." "$WORK"; fi
  cd "$WORK" || exit 1
  [ -d .git ] || git init -q -b main
  git config user.email prueba@example.com; git config user.name Prueba
  rm -rf target node_modules; git add -A >/dev/null 2>&1; git commit -qm base --no-verify >/dev/null 2>&1 || true
  [ "$TIPO" = lab ] && npm install --silent >/dev/null 2>&1
  return 0
}

poner_rojo() {
  if [ "$TIPO" = lab ]; then
    printf "import test from 'node:test'\nimport assert from 'node:assert'\ntest('rojo a proposito', () => assert.fail('rojo'))\n" > test/rojo.test.js
  else
    d=modules/transferencias/src/test/java/cl/bancoandino/transferencias
    printf 'package cl.bancoandino.transferencias;\nimport org.junit.jupiter.api.Test;\nimport static org.junit.jupiter.api.Assertions.fail;\nclass RojoTest { @Test void rojo() { fail("rojo a proposito"); } }\n' > $d/RojoTest.java
  fi
}
quitar_rojo() { rm -f test/rojo.test.js modules/transferencias/src/test/java/cl/bancoandino/transferencias/RojoTest.java; }

# ---------------------------------------------------------------------------------------------
echo "== Hooks sobre $TIPO ($MODO) =="
preparar
GIT_COMMIT='git commit -m "feat: prueba"'
SIN_JQ="$(path_sin jq)"
SIN_JQ_PY="$(path_sin jq python3)"
SIN_LECTOR="$(path_sin jq python3 node)"

# 'rapido' se salta los casos que repiten una suite larga (Maven) o ya cubiertos con jq.
if [ "$MODO" = completo ]; then
  correr check-tests-before-commit.sh "ls -la"; caso "tests: un comando que no es git commit pasa" 0 $?
  correr check-tests-before-commit.sh "$GIT_COMMIT"; caso "tests: commit con tests en verde pasa" 0 $?
fi

if [ "$TIPO" = lab ] && [ -f .claude/settings.json ]; then
  poner_rojo
  correr check-tests-before-commit.sh "$GIT_COMMIT"; caso "tests: con el hook del lab registrado el plugin no repite npm test" 0 $?
  echo '{"tool_name":"Bash","cwd":"'"$WORK"'","tool_input":{"command":"git commit -m x"}}' | node .claude/hooks/tests-antes-del-commit.mjs >/dev/null 2>"$ERR"
  caso "tests: el hook del lab bloquea el rojo" 2 $? "npm test falló"
  quitar_rojo
  mv .claude/settings.json "$ERR.settings"   # repo Node sin hook de proyecto
fi

poner_rojo
correr check-tests-before-commit.sh "$GIT_COMMIT"
caso "tests: commit con test rojo se bloquea" 2 $? "Commit bloqueado: los tests fallaron (código"
correr check-tests-before-commit.sh "$GIT_COMMIT" "$SIN_JQ"
caso "tests: sin jq (lee con python3) bloquea el rojo" 2 $? "los tests fallaron"
if [ "$TIPO" = lab ]; then
  correr check-tests-before-commit.sh "$GIT_COMMIT" "$SIN_JQ_PY"
  caso "tests: sin jq ni python3 (lee con node) bloquea el rojo" 2 $? "los tests fallaron"
fi
correr check-tests-before-commit.sh "$GIT_COMMIT" "$SIN_LECTOR"
caso "tests: sin jq, python3 ni node deja pasar con aviso" 0 $? "AVISO workshop-devs"
quitar_rojo

# --- secretos ---
AKIA="AKIA""ABCDEFGHIJKLMNOP"   # partido a propósito: el literal completo en este archivo dispara el hook
echo "aws_key = $AKIA" > config-prueba.txt
git add config-prueba.txt
correr check-secrets.sh "$GIT_COMMIT"
caso "secretos: clave AWS se bloquea y nombra el archivo" 2 $? "config-prueba.txt" "$AKIA"
correr check-secrets.sh "$GIT_COMMIT" "$SIN_JQ"
caso "secretos: sin jq (python3) bloquea" 2 $? "clave de acceso AWS"
[ "$TIPO" = lab ] && { correr check-secrets.sh "$GIT_COMMIT" "$SIN_JQ_PY"; caso "secretos: sin jq ni python3 (node) bloquea" 2 $? "clave de acceso AWS"; }
correr check-secrets.sh "$GIT_COMMIT" "$SIN_LECTOR"
caso "secretos: sin lector de JSON deja pasar con aviso" 0 $? "AVISO workshop-devs"
git rm -qf --cached config-prueba.txt; rm -f config-prueba.txt

printf 'db.password=hunter22xyz\n' > application-prueba.properties; git add application-prueba.properties
correr check-secrets.sh "$GIT_COMMIT"
caso "secretos: password=valor se bloquea sin imprimir el valor" 2 $? "application-prueba.properties" "hunter22xyz"
git rm -qf --cached application-prueba.properties; rm -f application-prueba.properties

printf 'db.password=${DB_PASSWORD}\n' > application-ref.properties; git add application-ref.properties
correr check-secrets.sh "$GIT_COMMIT"
caso "secretos: password=\${VAR} (referencia) pasa" 0 $?
git rm -qf --cached application-ref.properties; rm -f application-ref.properties

printf -- '-----BEGIN RSA PRIVATE KEY-----\nabc\n' > llave-prueba.pem; git add llave-prueba.pem
correr check-secrets.sh "$GIT_COMMIT"
caso "secretos: llave PEM se bloquea" 2 $? "llave-prueba.pem"
git rm -qf --cached llave-prueba.pem; rm -f llave-prueba.pem

correr check-secrets.sh "$GIT_COMMIT"; caso "secretos: diff limpio pasa" 0 $?

[ -n "${KEEP:-}" ] || rm -rf "$WORK" "$SHIM" "$SIN_JQ" "$SIN_JQ_PY" "$SIN_LECTOR" "$ERR" "$ERR.settings"
echo "== $TIPO: $FALLAS caso(s) con falla =="
[ "$FALLAS" -eq 0 ]
