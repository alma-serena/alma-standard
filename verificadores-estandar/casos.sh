#!/usr/bin/env bash
# Casos de falla/pasa para las 7 comprobaciones nuevas de catalogo.sh (E.1–E.4).
# 14 casos. Sale 0 solo si todos se comportan como se espera.
# No viaja al consumidor: vive en verificadores-estandar/ [V-20].
set -u
cd "$(dirname "$0")/.."
EST="$PWD"
BASH_BIN="${BASH_BIN:-bash}"
fallos_casos=0
ok_casos=0

echo "== casos catalogo.sh (E.1–E.4) =="

TMP="$(mktemp -d "${TMPDIR:-/tmp}/alma-casos.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# --- base minima que pasa las 7 comprobaciones nuevas (y el resto) ----------
base_proyecto() {
  local raiz="$1"
  mkdir -p "$raiz/resources/views/components" "$raiz/docs" "$raiz/resources/css"
  cat >"$raiz/proyecto-caso.md" <<'EOF'
# proyecto-caso.md
```
andamiaje: AGENTS.md, CLAUDE.md, METODOLOGIA.md, .agents/, .githooks/, .github/, verificadores/, proyecto-*.md, .alma/, docs/
anexo: ninguno
interfaz: si
componentes: resources/views/components
catalogo: docs/catalogo.md
tokens: resources/css/tokens.css
maqueta: /dev/maqueta-caso
origen: desde cero
```
EOF
  cat >"$raiz/docs/catalogo.md" <<'EOF'
# Catalogo

Estado del proyecto: `en convergencia`

## boton

rol: accion
estado: vigente
no-usar-cuando: no es una accion primaria
excepciones: ninguna
archivo: resources/views/components/boton.blade.php
EOF
  cat >"$raiz/resources/views/components/boton.blade.php" <<'EOF'
<button type="button" class="alma-accion"
  style="color: var(--alma-color-sobre-accion); background: var(--alma-color-accion);
         padding: var(--alma-espacio); border-radius: var(--alma-radio);
         font-family: var(--alma-fuente); font-size: var(--alma-tamano-cuerpo);
         border-width: var(--alma-borde-ancho);">
  Accion
</button>
EOF
  cat >"$raiz/resources/css/tokens.css" <<'EOF'
:root {
  --alma-color-fondo: #ffffff;
  --alma-color-superficie: #f5f5f5;
  --alma-color-texto: #111111;
  --alma-color-texto-secundario: #333333;
  --alma-color-borde: #cccccc;
  --alma-color-borde-control: #666666;
  --alma-color-accion: #0055aa;
  --alma-color-sobre-accion: #ffffff;
  --alma-color-peligro: #990000;
  --alma-fuente: system-ui, sans-serif;
  --alma-fuente-display: Georgia, serif;
  --alma-fuente-dato: ui-monospace, monospace;
  --alma-tamano-cuerpo: 1rem;
  --alma-tamano-titulo: 1.5rem;
  --alma-espacio: 1rem;
  --alma-radio: 0.25rem;
  --alma-borde-ancho: 1px;
}
@media (prefers-color-scheme: dark) {
  :root {
    --alma-color-fondo: #111111;
    --alma-color-superficie: #1a1a1a;
    --alma-color-texto: #f5f5f5;
    --alma-color-texto-secundario: #cccccc;
    --alma-color-borde: #444444;
    --alma-color-borde-control: #999999;
    --alma-color-accion: #66aaff;
    --alma-color-sobre-accion: #111111;
    --alma-color-peligro: #ff8888;
  }
}
EOF
}

clonar() {
  local dest="$1"
  rm -rf "$dest"
  cp -a "$TMP/base" "$dest"
}

correr() {
  # $1 nombre  $2 esperado (pasa|falla)  $3 regex que debe aparecer si falla
  local nombre="$1" esperado="$2" patron="${3:-}"
  local raiz="$TMP/$nombre"
  local salida codigo
  salida="$(RAIZ_PROYECTO="$raiz" RAIZ_ESTANDAR="$EST" "$BASH_BIN" "$EST/verificadores/catalogo.sh" 2>&1)"
  codigo=$?
  if [ "$esperado" = "pasa" ]; then
    if [ "$codigo" -eq 0 ]; then
      echo "  ok    · $nombre (pasa)"
      ok_casos=$((ok_casos+1))
    else
      echo "  FALLA · $nombre: esperaba pasa, codigo=$codigo"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -20
      fallos_casos=$((fallos_casos+1))
    fi
  else
    if [ "$codigo" -ne 0 ] && printf '%s\n' "$salida" | grep -qE "$patron"; then
      echo "  ok    · $nombre (falla: $patron)"
      ok_casos=$((ok_casos+1))
    else
      echo "  FALLA · $nombre: esperaba falla matching /$patron/ (codigo=$codigo)"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -20
      fallos_casos=$((fallos_casos+1))
    fi
  fi
}

base_proyecto "$TMP/base"

# ===== 6b =====
clonar "$TMP/6b-falla"
printf '%s\n' '<div style="margin: 1rem;">x</div>' \
  >"$TMP/6b-falla/resources/views/components/boton.blade.php"
correr 6b-falla falla '6b'

clonar "$TMP/6b-pasa"
correr 6b-pasa pasa

# ===== 6c =====
clonar "$TMP/6c-falla"
printf '%s\n' '<div style="font-family: Arial, sans-serif;">x</div>' \
  >"$TMP/6c-falla/resources/views/components/boton.blade.php"
correr 6c-falla falla '6c'

clonar "$TMP/6c-pasa"
correr 6c-pasa pasa

# ===== 6d =====
clonar "$TMP/6d-falla"
printf '%s\n' '<div style="margin-inline-start: {{ $n * 1.25 }}rem;">x</div>' \
  >"$TMP/6d-falla/resources/views/components/boton.blade.php"
correr 6d-falla falla '6d'

clonar "$TMP/6d-pasa"
correr 6d-pasa pasa

# ===== roles-tokens (E.2) =====
clonar "$TMP/roles-falla"
# conforme + falta un rol
sed -i 's/en convergencia/conforme/' "$TMP/roles-falla/docs/catalogo.md"
# quitar --alma-borde-ancho
sed -i '/--alma-borde-ancho/d' "$TMP/roles-falla/resources/css/tokens.css"
correr roles-falla falla "rol de token '--alma-borde-ancho'|falta el rol de token"

clonar "$TMP/roles-pasa"
correr roles-pasa pasa

# ===== tokens-base (E.3) =====
clonar "$TMP/base-falla"
cp "$TMP/base-falla/resources/css/tokens.css" "$TMP/base-falla/resources/css/tokens-base.css"
# marca redefine un nombre que NO esta en la base
cat >"$TMP/base-falla/resources/css/tokens.css" <<'EOF'
@import './tokens-base.css';
:root {
  --alma-color-acento: #b8860b;
  --alma-fuente-display: 'Cinzel', serif;
}
EOF
# quitar color-acento y fuente-display de la base para forzar la falla en acento
sed -i '/--alma-color-acento/d' "$TMP/base-falla/resources/css/tokens-base.css"
# fuente-display SI esta en base (el de la plantilla); acento no
# Anadir tokens-base al proyecto
sed -i 's|tokens: resources/css/tokens.css|tokens: resources/css/tokens.css\ntokens-base: resources/css/tokens-base.css|' \
  "$TMP/base-falla/proyecto-caso.md"
correr base-falla falla 'tokens-base'

clonar "$TMP/base-pasa"
cp "$TMP/base-pasa/resources/css/tokens.css" "$TMP/base-pasa/resources/css/tokens-base.css"
cat >"$TMP/base-pasa/resources/css/tokens.css" <<'EOF'
@import './tokens-base.css';
:root {
  --alma-fuente-display: Georgia, serif;
}
EOF
sed -i 's|tokens: resources/css/tokens.css|tokens: resources/css/tokens.css\ntokens-base: resources/css/tokens-base.css|' \
  "$TMP/base-pasa/proyecto-caso.md"
correr base-pasa pasa

# ===== contraste (E.4) =====
clonar "$TMP/contraste-falla"
# texto gris claro sobre blanco: ratio ~1.6
sed -i 's/--alma-color-texto: #111111;/--alma-color-texto: #bbbbbb;/' \
  "$TMP/contraste-falla/resources/css/tokens.css"
correr contraste-falla falla 'contraste'

clonar "$TMP/contraste-pasa"
correr contraste-pasa pasa

# ===== outline / focus-visible (E.4) =====
clonar "$TMP/outline-falla"
printf '%s\n' '<button style="outline: none;">x</button>' \
  >"$TMP/outline-falla/resources/views/components/boton.blade.php"
correr outline-falla falla 'outline'

clonar "$TMP/outline-pasa"
printf '%s\n' '<style>button:focus-visible{outline:2px solid var(--alma-color-accion)} button{outline:none}</style>
<button type="button">x</button>' \
  >"$TMP/outline-pasa/resources/views/components/boton.blade.php"
# 6b acusaria 2px — mover el estilo a tokens (permitido) o usar var
printf '%s\n' '<style>
button { outline: none; }
button:focus-visible { outline-width: var(--alma-borde-ancho); outline-style: solid;
  outline-color: var(--alma-color-accion); }
</style>
<button type="button" style="font-family: var(--alma-fuente); font-size: var(--alma-tamano-cuerpo);">x</button>' \
  >"$TMP/outline-pasa/resources/views/components/boton.blade.php"
correr outline-pasa pasa

echo
if [ "$fallos_casos" -gt 0 ]; then
  echo "casos: $fallos_casos FALLA(S) / $ok_casos ok"
  exit 1
fi
echo "casos: sin fallas ($ok_casos ok)"
exit 0
