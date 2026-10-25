#!/usr/bin/env bash
# Parser del campo php: — interruptor del anexo de runtime en certificacion (H-e).
# Formato: ^[0-9]+\.[0-9]+$
#   ausente  → activar=no, exit 0. El anexo no corre.
#   invalido → FALLA con mensaje, exit 1.
#   valido   → activar=si, version, extensiones.
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
  emit activar no
  exit 0
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
