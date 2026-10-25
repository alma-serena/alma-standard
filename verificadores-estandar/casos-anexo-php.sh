#!/usr/bin/env bash
# Casos del parser php: (D1). No viaja: vive en verificadores-estandar/.
set -u
cd "$(dirname "$0")/.."
EST="$PWD"
BASH_BIN="${BASH_BIN:-bash}"
fallos=0
ok=0

echo "== casos anexo-php.sh (D1) =="

TMP="$(mktemp -d "${TMPDIR:-/tmp}/alma-casos-php.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

escribir() {
  local raiz="$1" cuerpo="$2"
  mkdir -p "$raiz"
  printf '%s\n' "$cuerpo" >"$raiz/proyecto-caso.md"
}

correr() {
  local nombre="$1" esperado="$2" patron="${3:-}"
  local raiz="$TMP/$nombre"
  local salida codigo
  salida="$(RAIZ_PROYECTO="$raiz" "$BASH_BIN" "$EST/verificadores/anexo-php.sh" 2>&1)"
  codigo=$?
  if [ "$esperado" = "pasa" ]; then
    if [ "$codigo" -eq 0 ] && printf '%s\n' "$salida" | grep -qE "$patron"; then
      echo "  ok    · $nombre"
      ok=$((ok+1))
    else
      echo "  FALLA · $nombre: esperaba pasa matching /$patron/ (codigo=$codigo)"
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

escribir "$TMP/ausente" "$(printf '%s\n' 'anexo: ninguno' 'interfaz: no' 'tests: true')"
correr ausente pasa '^activar=no$'

escribir "$TMP/valido" "$(printf '%s\n' 'php: 8.3' 'anexo: laravel' 'tests: php artisan test')"
correr valido pasa '^activar=si$'
# version en la misma corrida
salida="$(RAIZ_PROYECTO="$TMP/valido" "$BASH_BIN" "$EST/verificadores/anexo-php.sh" 2>&1)"
if printf '%s\n' "$salida" | grep -q '^version=8.3$'; then
  echo "  ok    · valido-version"
  ok=$((ok+1))
else
  echo "  FALLA · valido-version: no emitio version=8.3"
  fallos=$((fallos+1))
fi

escribir "$TMP/invalido" "$(printf '%s\n' 'php: ocho' 'anexo: laravel')"
correr invalido falla "se espera N.N"

escribir "$TMP/invalido-major" "$(printf '%s\n' 'php: 8')"
correr invalido-major falla "se espera N.N"

# Consumidor sin php: (la forma de estandar / infra / hermes). Autocontenido:
# D6 contra los clones reales se mide en P1, no aqui — la CI del estandar
# no tiene esos repositorios.
escribir "$TMP/sin-php" "$(printf '%s\n' 'anexo: ninguno' 'interfaz: no' 'tests: bash bin/perfil.sh')"
correr sin-php pasa '^activar=no$'

# catalogo.sh no rechaza un campo que no conoce
mkdir -p "$TMP/catalogo-php"
printf '%s\n' \
  'andamiaje: AGENTS.md' \
  'anexo: ninguno' \
  'interfaz: no' \
  'php: 8.3' \
  >"$TMP/catalogo-php/proyecto-caso.md"
cat_out="$(RAIZ_PROYECTO="$TMP/catalogo-php" RAIZ_ESTANDAR="$EST" \
  "$BASH_BIN" "$EST/verificadores/catalogo.sh" 2>&1)" || true
cat_code=$?
if [ "$cat_code" -eq 0 ] && ! printf '%s\n' "$cat_out" | grep -qi "php:"; then
  echo "  ok    · catalogo-ignora-php"
  ok=$((ok+1))
else
  echo "  FALLA · catalogo-ignora-php: codigo=$cat_code"
  printf '%s\n' "$cat_out" | sed 's/^/           /' | head -15
  fallos=$((fallos+1))
fi

echo
if [ "$fallos" -gt 0 ]; then
  echo "casos-anexo-php: $fallos FALLA(S) / $ok ok"
  exit 1
fi
echo "casos-anexo-php: sin fallas ($ok ok)"
exit 0
