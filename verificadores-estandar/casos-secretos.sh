#!/usr/bin/env bash
# Casos de secretos.sh en modo arbol (D7 / I-01-H1). No viaja.
set -u
cd "$(dirname "$0")/.."
EST="$PWD"
BASH_BIN="${BASH_BIN:-bash}"
fallos=0
ok=0
# Se arma en runtime para que ESTE archivo no dispare el barrido.
NOMBRE='API_KEY'
VALOR="$(printf 'x%.0s' {1..24})"
FAKE="${NOMBRE}=${VALOR}"

echo "== casos secretos.sh (D7) =="

TMP="$(mktemp -d "${TMPDIR:-/tmp}/alma-casos-sec.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.name 'Caso'
  git -C "$d" config user.email 'caso@example.test'
}

correr() {
  local nombre="$1" esperado="$2" patron="${3:-}"
  local d="$TMP/$nombre"
  local salida codigo
  salida="$(cd "$d" && "$BASH_BIN" "$EST/verificadores/secretos.sh" 2>&1)"
  codigo=$?
  if [ "$esperado" = "pasa" ]; then
    if [ "$codigo" -eq 0 ]; then
      echo "  ok    · $nombre"
      ok=$((ok+1))
    else
      echo "  FALLA · $nombre: esperaba pasa (codigo=$codigo)"
      printf '%s\n' "$salida" | sed 's/^/           /'
      fallos=$((fallos+1))
    fi
  else
    if [ "$codigo" -ne 0 ] && printf '%s\n' "$salida" | grep -qE "$patron"; then
      echo "  ok    · $nombre (falla: $patron)"
      ok=$((ok+1))
    else
      echo "  FALLA · $nombre: esperaba falla matching /$patron/ (codigo=$codigo)"
      printf '%s\n' "$salida" | sed 's/^/           /'
      fallos=$((fallos+1))
    fi
  fi
}

# 1 · .env ignorado con secreto falso → no dispara
repo "$TMP/ignorado"
printf '%s\n' '.env' >"$TMP/ignorado/.gitignore"
printf '%s\n' "$FAKE" >"$TMP/ignorado/.env"
printf '%s\n' 'ok' >"$TMP/ignorado/README.md"
git -C "$TMP/ignorado" add .gitignore README.md
git -C "$TMP/ignorado" commit -qm 'init'
correr ignorado pasa

# 2 · archivo rastreado con secreto falso → dispara
repo "$TMP/rastreado"
printf '%s\n' "$FAKE" >"$TMP/rastreado/config.txt"
git -C "$TMP/rastreado" add config.txt
git -C "$TMP/rastreado" commit -qm 'init'
correr rastreado falla 'config.txt'

# 3 · no rastreado y no ignorado → dispara
repo "$TMP/otros"
printf '%s\n' 'ok' >"$TMP/otros/README.md"
git -C "$TMP/otros" add README.md
git -C "$TMP/otros" commit -qm 'init'
printf '%s\n' "$FAKE" >"$TMP/otros/nuevo.txt"
correr otros falla 'nuevo.txt'

# 4 · lista vacia (repo minimo, nada que barrer con secreto)
repo "$TMP/vacio"
printf '%s\n' 'ok' >"$TMP/vacio/README.md"
git -C "$TMP/vacio" add README.md
git -C "$TMP/vacio" commit -qm 'init'
correr vacio pasa

# 5 · archivo borrado sin commitear: estaba en el indice, ya no esta en disco
repo "$TMP/borrado"
printf '%s\n' "$FAKE" >"$TMP/borrado/secreto.txt"
git -C "$TMP/borrado" add secreto.txt
git -C "$TMP/borrado" commit -qm 'init'
rm -f "$TMP/borrado/secreto.txt"
correr borrado pasa

# 6 · fuera de un repo git → FALLA
mkdir -p "$TMP/nongit"
correr nongit falla 'fuera de un repositorio git'

# 7 · ruta con # — el sed anterior tomaba # como delimitador
repo "$TMP/hash"
mkdir -p "$TMP/hash/dir#raro"
printf '%s\n' "$FAKE" >"$TMP/hash/dir#raro/x.txt"
git -C "$TMP/hash" add -- 'dir#raro/x.txt'
git -C "$TMP/hash" commit -qm 'init'
correr hash falla 'dir#raro/x.txt'

# 8 · ruta con & — el sed anterior interpretaba & como el match
repo "$TMP/amp"
printf '%s\n' "$FAKE" >"$TMP/amp/a&b.txt"
git -C "$TMP/amp" add -- 'a&b.txt'
git -C "$TMP/amp" commit -qm 'init'
correr amp falla 'a&b.txt'

echo
if [ "$fallos" -gt 0 ]; then
  echo "casos-secretos: $fallos FALLA(S) / $ok ok"
  exit 1
fi
echo "casos-secretos: sin fallas ($ok ok)"
exit 0
