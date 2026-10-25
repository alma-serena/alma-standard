#!/usr/bin/env bash
# Casos de sesion.sh (D8 / I-01-H4). No viaja.
# El patron se arma en runtime para que este archivo no lo contenga literal.
set -u
cd "$(dirname "$0")/.."
EST="$PWD"
BASH_BIN="${BASH_BIN:-bash}"
fallos=0
ok=0

HOST='claude.ai'
RUTA='code/session'
PRE='Claude'
SUF='Session:'
URL_MALA="https://${HOST}/${RUTA}/abc"
HDR_MALA="${PRE}-${SUF} https://example.invalid/x"

echo "== casos sesion.sh (D8) =="

TMP="$(mktemp -d "${TMPDIR:-/tmp}/alma-casos-ses.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q
  git -C "$d" config user.name 'Caso'
  git -C "$d" config user.email 'caso@example.test'
  git -C "$d" checkout -q -b main
}

ok_uno() { echo "  ok    · $1"; ok=$((ok+1)); }
falla_uno() { echo "  FALLA · $1"; fallos=$((fallos+1)); }

# --archivo: rechaza URL de sesion
printf '%s\n' "fix: algo" "$URL_MALA" >"$TMP/msg-url"
if ! "$BASH_BIN" "$EST/verificadores/sesion.sh" --archivo "$TMP/msg-url" >/dev/null 2>&1; then
  ok_uno 'archivo-url-rechaza'
else
  falla_uno 'archivo-url-rechaza: debia fallar'
fi

printf '%s\n' "fix: algo" "$HDR_MALA" >"$TMP/msg-hdr"
if ! "$BASH_BIN" "$EST/verificadores/sesion.sh" --archivo "$TMP/msg-hdr" >/dev/null 2>&1; then
  ok_uno 'archivo-cabecera-rechaza'
else
  falla_uno 'archivo-cabecera-rechaza: debia fallar'
fi

# --archivo: acepta trailers de agente (cualquier capitalizacion)
printf '%s\n' "V-1: cambio" "" "Co-authored-by: Cursor <cursoragent@cursor.com>" >"$TMP/msg-cursor"
if "$BASH_BIN" "$EST/verificadores/sesion.sh" --archivo "$TMP/msg-cursor" >/dev/null 2>&1; then
  ok_uno 'archivo-cursor-acepta'
else
  falla_uno 'archivo-cursor-acepta: debia pasar'
fi

printf '%s\n' "V-1: cambio" "" "Co-Authored-By: Composer <composer@cursor.com>" >"$TMP/msg-composer"
if "$BASH_BIN" "$EST/verificadores/sesion.sh" --archivo "$TMP/msg-composer" >/dev/null 2>&1; then
  ok_uno 'archivo-composer-acepta'
else
  falla_uno 'archivo-composer-acepta: debia pasar'
fi

# hook commit-msg: mismo script, modo archivo
printf '%s\n' "fix: algo" "$URL_MALA" >"$TMP/hook-mal"
if ! "$BASH_BIN" "$EST/.githooks/commit-msg" "$TMP/hook-mal" >/dev/null 2>&1; then
  ok_uno 'hook-rechaza'
else
  falla_uno 'hook-rechaza: debia fallar'
fi
printf '%s\n' "V-1: cambio" "" "Co-authored-by: Cursor <cursoragent@cursor.com>" >"$TMP/hook-bien"
if "$BASH_BIN" "$EST/.githooks/commit-msg" "$TMP/hook-bien" >/dev/null 2>&1; then
  ok_uno 'hook-acepta'
else
  falla_uno 'hook-acepta: debia pasar'
fi

# rango: commit limpio pasa, commit sucio falla
repo "$TMP/rango"
printf '%s\n' 'ok' >"$TMP/rango/a.txt"
git -C "$TMP/rango" add a.txt
git -C "$TMP/rango" commit -qm 'base limpia'
BASE="$(git -C "$TMP/rango" rev-parse HEAD)"
printf '%s\n' 'ok2' >"$TMP/rango/b.txt"
git -C "$TMP/rango" add b.txt
git -C "$TMP/rango" commit -qm 'segundo limpio'
HEADL="$(git -C "$TMP/rango" rev-parse HEAD)"
if (cd "$TMP/rango" && "$BASH_BIN" "$EST/verificadores/sesion.sh" --rango "$BASE" "$HEADL") >/dev/null 2>&1; then
  ok_uno 'rango-limpio'
else
  falla_uno 'rango-limpio: debia pasar'
fi

printf '%s\n' 'ok3' >"$TMP/rango/c.txt"
git -C "$TMP/rango" add c.txt
git -C "$TMP/rango" commit -qm "$(printf '%s\n' "tercero" "$URL_MALA")"
HEADS="$(git -C "$TMP/rango" rev-parse HEAD)"
if ! (cd "$TMP/rango" && "$BASH_BIN" "$EST/verificadores/sesion.sh" --rango "$BASE" "$HEADS") >/dev/null 2>&1; then
  ok_uno 'rango-sucio'
else
  falla_uno 'rango-sucio: debia fallar'
fi

# rama nueva con before en ceros: solo revisa commits nuevos
# (origin/main = la base; la rama suma un commit sucio → falla)
repo "$TMP/nueva"
printf '%s\n' 'ok' >"$TMP/nueva/a.txt"
git -C "$TMP/nueva" add a.txt
git -C "$TMP/nueva" commit -qm 'main limpia'
MAIN="$(git -C "$TMP/nueva" rev-parse HEAD)"
git -C "$TMP/nueva" update-ref refs/remotes/origin/main "$MAIN"
git -C "$TMP/nueva" checkout -q -b feature
printf '%s\n' 'x' >"$TMP/nueva/x.txt"
git -C "$TMP/nueva" add x.txt
git -C "$TMP/nueva" commit -qm "$(printf '%s\n' "feature" "$URL_MALA")"
FEAT="$(git -C "$TMP/nueva" rev-parse HEAD)"
CEROS='0000000000000000000000000000000000000000'
if ! (cd "$TMP/nueva" && EVENT=push BEFORE="$CEROS" AFTER="$FEAT" \
      "$BASH_BIN" "$EST/verificadores/sesion.sh") >/dev/null 2>&1; then
  ok_uno 'nueva-rama-sucia'
else
  falla_uno 'nueva-rama-sucia: debia fallar (commit nuevo sucio)'
fi

# misma base, commit nuevo limpio → pasa (el sucio no existe; main esta limpia)
repo "$TMP/nueva-ok"
printf '%s\n' 'ok' >"$TMP/nueva-ok/a.txt"
git -C "$TMP/nueva-ok" add a.txt
git -C "$TMP/nueva-ok" commit -qm 'main limpia'
MAIN2="$(git -C "$TMP/nueva-ok" rev-parse HEAD)"
git -C "$TMP/nueva-ok" update-ref refs/remotes/origin/main "$MAIN2"
git -C "$TMP/nueva-ok" checkout -q -b feature
printf '%s\n' 'x' >"$TMP/nueva-ok/x.txt"
git -C "$TMP/nueva-ok" add x.txt
git -C "$TMP/nueva-ok" commit -qm 'feature limpia'
FEAT2="$(git -C "$TMP/nueva-ok" rev-parse HEAD)"
if (cd "$TMP/nueva-ok" && EVENT=push BEFORE="$CEROS" AFTER="$FEAT2" \
    "$BASH_BIN" "$EST/verificadores/sesion.sh") >/dev/null 2>&1; then
  ok_uno 'nueva-rama-limpia'
else
  falla_uno 'nueva-rama-limpia: debia pasar'
fi

echo
if [ "$fallos" -gt 0 ]; then
  echo "casos-sesion: $fallos FALLA(S) / $ok ok"
  exit 1
fi
echo "casos-sesion: sin fallas ($ok ok)"
exit 0
