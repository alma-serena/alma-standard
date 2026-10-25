#!/usr/bin/env bash
# Mensajes de commit: prohibidas las URLs de sesion de agente (I-01-H4).
# Los trailers de agente no se validan.
#
#   sesion.sh --archivo FILE   hook commit-msg
#   sesion.sh --rango A B      git log A..B (A exclusive, B inclusive)
#   sesion.sh                  CI: EVENT, BEFORE, AFTER, BASE_SHA, HEAD_SHA
set -u

# Host + ruta de sesion, y cabecera de trailer de sesion. No se valida el resto.
PAT='claude\.ai/code/session|[Cc]laude-[Ss]ession:'
CEROS='0000000000000000000000000000000000000000'

fallos=0

revisar_texto() {
  local origen="$1" texto="$2"
  if printf '%s\n' "$texto" | grep -qE "$PAT"; then
    echo "  FALLA · URL de sesion de agente en $origen"
    fallos=$((fallos+1))
  fi
}

revisar_hashes() {
  local h
  for h in "$@"; do
    [ -n "$h" ] || continue
    revisar_texto "commit $h" "$(git log -1 --format=%B "$h")"
  done
}

revisar_rango() {
  local a="$1" b="$2"
  if ! git rev-parse --verify "$b^{commit}" >/dev/null 2>&1; then
    echo "  FALLA · no se puede resolver el extremo posterior"
    fallos=$((fallos+1))
    return
  fi

  if [ -z "$a" ] || [ "$a" = "$CEROS" ]; then
    local base=""
    if git rev-parse --verify origin/HEAD >/dev/null 2>&1; then
      base="$(git rev-parse origin/HEAD)"
    elif git rev-parse --verify origin/main >/dev/null 2>&1; then
      base="$(git rev-parse origin/main)"
    fi
    if [ -n "$base" ]; then
      a="$base"
    else
      # sin base: los commits alcanzables desde b
      # shellcheck disable=SC2046
      revisar_hashes $(git rev-list "$b")
      return
    fi
  fi

  if ! git rev-parse --verify "$a^{commit}" >/dev/null 2>&1; then
    git fetch --no-tags origin "$a" >/dev/null 2>&1 || true
  fi
  if ! git rev-parse --verify "$a^{commit}" >/dev/null 2>&1; then
    echo "  FALLA · no se puede resolver el extremo anterior"
    fallos=$((fallos+1))
    return
  fi

  local hashes
  hashes="$(git rev-list "${a}..${b}")"
  if [ -z "$hashes" ]; then
    echo "  ok    · rango vacio: nada que revisar"
    return
  fi
  # shellcheck disable=SC2086
  revisar_hashes $hashes
}

echo "== mensajes de commit =="

if [ "${1:-}" = "--archivo" ]; then
  if [ -z "${2:-}" ] || [ ! -f "$2" ]; then
    echo "  FALLA · --archivo sin archivo de mensaje"
    echo "sesion: 1 FALLA(S)"; exit 1
  fi
  revisar_texto "el mensaje" "$(cat "$2")"
elif [ "${1:-}" = "--rango" ]; then
  if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
    echo "  FALLA · --rango pide dos extremos"
    echo "sesion: 1 FALLA(S)"; exit 1
  fi
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  FALLA · --rango fuera de un repositorio git"
    echo "sesion: 1 FALLA(S)"; exit 1
  fi
  revisar_rango "$2" "$3"
else
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "  FALLA · fuera de un repositorio git"
    echo "sesion: 1 FALLA(S)"; exit 1
  fi
  EVENT="${EVENT:-${GITHUB_EVENT_NAME:-}}"
  if [ "$EVENT" = "pull_request" ]; then
    revisar_rango "${BASE_SHA:-}" "${HEAD_SHA:-${GITHUB_SHA:-HEAD}}"
  else
    revisar_rango "${BEFORE:-${GITHUB_EVENT_BEFORE:-}}" "${AFTER:-${GITHUB_SHA:-HEAD}}"
  fi
fi

if [ "$fallos" -eq 0 ]; then
  echo "  ok    · sin URLs de sesion de agente"
  echo "sesion: sin fallas"; exit 0
fi
echo "sesion: $fallos FALLA(S)"
exit 1
