#!/usr/bin/env bash
# Parser del runtime PHP — interruptor del anexo en certificacion (H-e / MIS-014).
# Formato de php:: ^[0-9]+\.[0-9]+$
#   php: valido     → activar=si (declara el proyecto).
#   php: invalido   → FALLA con mensaje, exit 1.
#   php: ausente + composer.json con require.php N.N → activar=si (MIS-014).
#   php: ausente, sin composer.json → activar=no, exit 0.
# Independiente de anexo: (ese campo sigue siendo el de stack / catalogo).
#
# RAIZ_PROYECTO ancla un arbol de prueba (verificadores-estandar/casos-anexo-php.sh).
set -u

if [ -n "${RAIZ_PROYECTO:-}" ]; then
  cd "$RAIZ_PROYECTO" || { echo "FALLA · no se pudo anclar a RAIZ_PROYECTO=$RAIZ_PROYECTO" >&2; exit 1; }
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
  cd "$(git rev-parse --show-toplevel)" || exit 1
fi

campo() { sed -n "s/^$1:[[:space:]]*//p" "$2" | head -1; }

# require.php → primer N.N. Corre antes de setup-php: solo sed/grep.
version_desde_composer() {
  local archivo="$1" raw
  [ -f "$archivo" ] || return 1
  raw="$(sed -n '/"require"[[:space:]]*:/,/}/p' "$archivo" | sed -n 's/.*"php"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$raw" ] || return 1
  printf '%s' "$raw" | grep -oE '[0-9]+\.[0-9]+' | head -1
}

emit() {
  printf '%s=%s\n' "$1" "$2"
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    printf '%s=%s\n' "$1" "$2" >> "$GITHUB_OUTPUT"
  fi
}

PROY="$(ls proyecto-*.md 2>/dev/null | head -1 || true)"
if [ -z "$PROY" ]; then
  emit activar no
  exit 0
fi

PHP="$(campo php "$PROY" | tr -d '[:space:]')"
EXT="$(campo php-extensiones "$PROY")"
EXT="$(printf '%s' "$EXT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [ -z "$PHP" ]; then
  if [ -f composer.json ]; then
    PHP="$(version_desde_composer composer.json || true)"
    if [ -z "$PHP" ]; then
      echo "FALLA: hay composer.json pero no se leyó una versión N.N de require.php." >&2
      echo "       Declara 'php: N.N' en proyecto-<nombre>.md o un require.php parseable." >&2
      exit 1
    fi
    if [ -z "$EXT" ]; then
      EXT="pdo_sqlite,sqlite3"
    fi
  else
    emit activar no
    exit 0
  fi
fi

if ! printf '%s' "$PHP" | grep -qE '^[0-9]+\.[0-9]+$'; then
  echo "FALLA: 'php:' tiene valor '$PHP'; se espera N.N (ej. 8.3)." >&2
  echo "       Ausente = el anexo no corre. Invalido = el job falla." >&2
  exit 1
fi

emit activar si
emit version "$PHP"
emit extensiones "$EXT"
exit 0
