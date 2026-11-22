#!/usr/bin/env bash
# Casos de mapa.sh (REQ-V48 / V-48). Criterios 1–6 + verde. No viaja.
set -u
cd "$(dirname "$0")/.."
EST="$PWD"
BASH_BIN="${BASH_BIN:-bash}"
fallos_casos=0
ok_casos=0

echo "== casos mapa.sh (V-48) =="

TMP="$(mktemp -d "${TMPDIR:-/tmp}/alma-casos-mapa.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

ok_uno() { echo "  ok    · $1"; ok_casos=$((ok_casos+1)); }
falla_uno() { echo "  FALLA · $1"; fallos_casos=$((fallos_casos+1)); }

correr_prod() {
  # $1 nombre  $2 esperado pasa|falla  $3 regex si falla  $4 raiz
  local nombre="$1" esperado="$2" patron="${3:-}" raiz="$4"
  local salida codigo
  salida="$(RAIZ_PROYECTO="$raiz" RAIZ_ESTANDAR="$EST" \
            "$BASH_BIN" "$EST/verificadores/mapa.sh" 2>&1)"
  codigo=$?
  if [ "$esperado" = "pasa" ]; then
    if [ "$codigo" -eq 0 ]; then
      ok_uno "$nombre (pasa)"
    else
      falla_uno "$nombre: esperaba pasa, codigo=$codigo"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -25
    fi
  else
    if [ "$codigo" -ne 0 ] && printf '%s\n' "$salida" | grep -qE "$patron"; then
      ok_uno "$nombre (falla: $patron)"
    else
      falla_uno "$nombre: esperaba falla /$patron/ (codigo=$codigo)"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -25
    fi
  fi
}

correr_esp() {
  local nombre="$1" esperado="$2" patron="${3:-}" esp="$4"
  local salida codigo
  salida="$("$BASH_BIN" "$EST/verificadores/mapa.sh" --esp "$esp" 2>&1)"
  codigo=$?
  if [ "$esperado" = "pasa" ]; then
    if [ "$codigo" -eq 0 ]; then
      ok_uno "$nombre (pasa)"
    else
      falla_uno "$nombre: esperaba pasa, codigo=$codigo"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -25
    fi
  else
    if [ "$codigo" -ne 0 ] && printf '%s\n' "$salida" | grep -qE "$patron"; then
      ok_uno "$nombre (falla: $patron)"
    else
      falla_uno "$nombre: esperaba falla /$patron/ (codigo=$codigo)"
      printf '%s\n' "$salida" | sed 's/^/           /' | head -25
    fi
  fi
}

hash_de() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" </dev/null | awk '{print $1}'
  else
    shasum -a 256 "$1" </dev/null | awk '{print $1}'
  fi
}

# --- fixture: mapa valido minimo --------------------------------------------
mapa_valido() {
  local dest="$1" estado="${2:-ACEPTADO}"
  cat >"$dest" <<EOF
# Mapa de juguete — ESP-999

\`\`\`
esp: ESP-999
version: 1
estado: $estado
aceptado-por: caso
aceptado-fecha: 2026-11-16
experiencia: no hay
\`\`\`

## Pantallas

### PAN01 · Entrar

\`\`\`
vigencia: vigente
actor: usuario
proposito: entrar
muestra: —
pide: —
acciones: continuar
vacio: N/A — no aplica
carga: spinner → espera
error: mensaje → reintentar
dominio: —
comparte: —
traza: O1, AC1
\`\`\`

### PAN02 · Lista

\`\`\`
vigencia: vigente
actor: usuario
proposito: listar
muestra: item.nombre
pide: —
acciones: abrir
vacio: vacio → crear
carga: spinner → espera
error: mensaje → reintentar
dominio: —
comparte: —
traza: AC2
\`\`\`

## Flujos

### FLU01 · entrar — actor: usuario — traza: O1

\`\`\`mermaid
flowchart LR
  PAN01["Entrar"] --> PAN02["Lista"]
\`\`\`

## Navegación

\`\`\`
entrada: PAN01
persistente: PAN02
\`\`\`

\`\`\`mermaid
flowchart TD
  PAN01["Entrar"] --> PAN02["Lista"]
\`\`\`

## AC sin superficie

\`\`\`
AC3: sin UI en v1
\`\`\`
EOF
}

diseno_juguete() {
  cat >"$1" <<'EOF'
# diseno juguete
## Objetivos
O1 entrar
## Criterios
AC1 login visible
AC2 lista visible
AC3 modelo sin UI
EOF
}

base_prod() {
  local raiz="$1"
  mkdir -p "$raiz/docs" "$raiz/docs/misiones"
  cat >"$raiz/proyecto-caso.md" <<'EOF'
# proyecto-caso.md
```
andamiaje: AGENTS.md, docs/
anexo: ninguno
interfaz: si
componentes: docs
catalogo: docs/catalogo.md
tokens: docs/tokens.css
maqueta: /dev/x
origen: desde cero
mapa: docs/mapa.md
mapa-origen: PLACEHOLDER
```
EOF
  cat >"$raiz/docs/catalogo.md" <<'EOF'
# Catalogo
Estado del proyecto: `en convergencia`
## x
rol: accion
estado: vigente
no-usar-cuando: —
excepciones: ninguna
archivo: docs/tokens.css
EOF
  echo ':root { --alma-color-fondo: #fff; }' >"$raiz/docs/tokens.css"
  # componentes: docs como raiz — el catalogo de casos de mapa no corre catalogo.sh
  mapa_valido "$raiz/docs/mapa.md" ACEPTADO
  local h
  h="$(hash_de "$raiz/docs/mapa.md")"
  sed -i "s|mapa-origen: PLACEHOLDER|mapa-origen: alma-serena@deadbeef · sha256 $h|" \
    "$raiz/proyecto-caso.md"
}

# ========== criterio 1: sin mapa: ==========
mkdir -p "$TMP/c1/docs"
cat >"$TMP/c1/proyecto-caso.md" <<'EOF'
# proyecto-caso.md
```
andamiaje: docs/
anexo: ninguno
interfaz: si
componentes: docs
catalogo: docs/catalogo.md
tokens: docs/tokens.css
maqueta: /dev/x
origen: desde cero
```
EOF
echo 'Estado del proyecto: `en convergencia`' >"$TMP/c1/docs/catalogo.md"
echo x >"$TMP/c1/docs/tokens.css"
correr_prod c1-sin-mapa falla "no declara 'mapa:" "$TMP/c1"

# ========== criterio 2: pendiente + conforme ==========
mkdir -p "$TMP/c2a/docs" "$TMP/c2b/docs"
cat >"$TMP/c2a/proyecto-caso.md" <<'EOF'
# p
```
andamiaje: docs/
anexo: ninguno
interfaz: si
componentes: docs
catalogo: docs/catalogo.md
tokens: docs/tokens.css
maqueta: /dev/x
origen: desde cero
mapa: pendiente
```
EOF
echo 'Estado del proyecto: `en convergencia`' >"$TMP/c2a/docs/catalogo.md"
echo x >"$TMP/c2a/docs/tokens.css"
correr_prod c2-pendiente-aviso pasa "" "$TMP/c2a"
# debe haber aviso
if RAIZ_PROYECTO="$TMP/c2a" RAIZ_ESTANDAR="$EST" \
   "$BASH_BIN" "$EST/verificadores/mapa.sh" 2>&1 | grep -q 'mapa: pendiente'; then
  ok_uno 'c2-pendiente-tiene-aviso'
else
  falla_uno 'c2-pendiente-tiene-aviso'
fi

cp -a "$TMP/c2a/." "$TMP/c2b/"
echo 'Estado del proyecto: `conforme`' >"$TMP/c2b/docs/catalogo.md"
correr_prod c2-pendiente-conforme falla "conforme.*pendiente|pendiente" "$TMP/c2b"

# ========== criterio 3: mapa no ACEPTADO + mision con pantallas ==========
base_prod "$TMP/c3"
mapa_valido "$TMP/c3/docs/mapa.md" BORRADOR
h="$(hash_de "$TMP/c3/docs/mapa.md")"
sed -i "s|sha256 [0-9a-fA-F]*|sha256 $h|" "$TMP/c3/proyecto-caso.md"
cat >"$TMP/c3/docs/misiones/M-UI.md" <<'EOF'
# M-UI
**Estado:** en_progreso
**pantallas:** PAN01
EOF
correr_prod c3-no-aceptado falla "no esta ACEPTADO|ACEPTADO" "$TMP/c3"

# ========== criterio 4: ID inexistente o retirada ==========
base_prod "$TMP/c4"
# marcar PAN02 como retirada y pedirla
mapa_valido "$TMP/c4/docs/mapa.md" ACEPTADO
sed -i '0,/vigencia: vigente/{s/vigencia: vigente/vigencia: vigente/}' "$TMP/c4/docs/mapa.md"
# Cambiar PAN02 a retirada
awk '
  /^### PAN02/ {p=1}
  p && /^vigencia:/ { sub(/vigente/,"retirada"); p=0 }
  {print}
' "$TMP/c4/docs/mapa.md" >"$TMP/c4/docs/mapa.md.tmp" && mv "$TMP/c4/docs/mapa.md.tmp" "$TMP/c4/docs/mapa.md"
h="$(hash_de "$TMP/c4/docs/mapa.md")"
sed -i "s|sha256 [0-9a-fA-F]*|sha256 $h|" "$TMP/c4/proyecto-caso.md"
cat >"$TMP/c4/docs/misiones/M-UI.md" <<'EOF'
# M-UI
**Estado:** en_progreso
**pantallas:** PAN02
EOF
correr_prod c4-retirada falla "retirada|no tiene vigencia" "$TMP/c4"

base_prod "$TMP/c4b"
cat >"$TMP/c4b/docs/misiones/M-UI.md" <<'EOF'
# M-UI
**Estado:** en_progreso
**pantallas:** PAN99
EOF
correr_prod c4-inexistente falla "PAN99|no existe" "$TMP/c4b"

# ========== criterio 5: hash distinto ==========
base_prod "$TMP/c5"
echo ' # tocado' >>"$TMP/c5/docs/mapa.md"
correr_prod c5-hash falla "hash" "$TMP/c5"

# ========== criterio 6: mermaid ilegal / sin traza / inalcanzable / vacio ==========
mkdir -p "$TMP/c6/esp"
diseno_juguete "$TMP/c6/esp/diseno.md"
cat >"$TMP/c6/esp/ESTADO.md" <<'EOF'
# ESTADO
Interfaz: si
Estado: aceptada
EOF
mapa_valido "$TMP/c6/esp/mapa.md" ACEPTADO
# mermaid ilegal
cat >>"$TMP/c6/esp/mapa.md" <<'EOF'

### FLU99 · malo

```mermaid
flowchart LR
  PAN01{"decidir"} --> PAN02["Lista"]
```
EOF
correr_esp c6-mermaid-ilegal falla "sintaxis permitida|fuera de la sintaxis" "$TMP/c6/esp"

# vacio vacio
mkdir -p "$TMP/c6b/esp"
diseno_juguete "$TMP/c6b/esp/diseno.md"
cat >"$TMP/c6b/esp/ESTADO.md" <<'EOF'
Interfaz: si
Estado: aceptada
EOF
mapa_valido "$TMP/c6b/esp/mapa.md" ACEPTADO
sed -i 's/^vacio: N\/A — no aplica$/vacio: /' "$TMP/c6b/esp/mapa.md"
# sed may leave "vacio: " which is empty value — or remove content
# Force empty after colon with nothing
perl -i -pe 's/^vacio: N\/A — no aplica$/vacio:/' "$TMP/c6b/esp/mapa.md" 2>/dev/null \
  || sed -i 's|vacio: N/A — no aplica|vacio:|' "$TMP/c6b/esp/mapa.md"
correr_esp c6-vacio-vacio falla "vacio|falta el campo" "$TMP/c6b/esp"

# pantalla inalcanzable
mkdir -p "$TMP/c6c/esp"
diseno_juguete "$TMP/c6c/esp/diseno.md"
cat >"$TMP/c6c/esp/ESTADO.md" <<'EOF'
Interfaz: si
Estado: aceptada
EOF
mapa_valido "$TMP/c6c/esp/mapa.md" ACEPTADO
# agregar PAN03 vigente sin conectar
cat >>"$TMP/c6c/esp/mapa.md" <<'EOF'

### PAN03 · Huérfana

```
vigencia: vigente
actor: usuario
proposito: nada
muestra: —
pide: —
acciones: —
vacio: N/A — x
carga: N/A — x
error: N/A — x
dominio: —
comparte: —
traza: AC3
```
EOF
# quitar AC3 de sin superficie porque ahora tiene traza — ok
correr_esp c6-inalcanzable falla "inalcanzable" "$TMP/c6c/esp"

# ========== verde: ESP + producto ==========
mkdir -p "$TMP/verde/esp"
diseno_juguete "$TMP/verde/esp/diseno.md"
cat >"$TMP/verde/esp/ESTADO.md" <<'EOF'
Interfaz: si
Estado: aceptada
EOF
mapa_valido "$TMP/verde/esp/mapa.md" ACEPTADO
correr_esp verde-esp pasa "" "$TMP/verde/esp"

base_prod "$TMP/verde/prod"
correr_prod verde-prod pasa "" "$TMP/verde/prod"

# CI sin stdin (MIS-983): el CI del buzon lanza bash sin descriptor de entrada valido;
# sha256sum fallaba ahi con "Bad file descriptor" y el hash salia vacio. El mismo
# mapa que pasa arriba debe seguir pasando con stdin cerrado.
salida_sin_stdin="$(RAIZ_PROYECTO="$TMP/verde/prod" RAIZ_ESTANDAR="$EST" \
                    "$BASH_BIN" "$EST/verificadores/mapa.sh" 2>&1 <&-)"
if [ $? -eq 0 ]; then
  ok_uno "verde-prod-stdin-cerrado (pasa)"
else
  falla_uno "verde-prod-stdin-cerrado: esperaba pasa con stdin cerrado"
  printf '%s\n' "$salida_sin_stdin" | sed 's/^/           /' | head -25
fi

# ========== verde: mermaid mixto (con/sin ["nombre"] en la misma arista) ==========
mkdir -p "$TMP/verde-mixto/esp"
diseno_juguete "$TMP/verde-mixto/esp/diseno.md"
cat >"$TMP/verde-mixto/esp/ESTADO.md" <<'EOF'
Interfaz: si
Estado: aceptada
EOF
cat >"$TMP/verde-mixto/esp/mapa.md" <<'EOF'
# Mapa de juguete — ESP-999

```
esp: ESP-999
version: 1
estado: ACEPTADO
aceptado-por: caso
aceptado-fecha: 2026-11-16
experiencia: no hay
```

## Pantallas

### PAN01 · Entrar

```
vigencia: vigente
actor: usuario
proposito: entrar
muestra: —
pide: —
acciones: continuar
vacio: N/A — no aplica
carga: spinner → espera
error: mensaje → reintentar
dominio: —
comparte: —
traza: O1, AC1
```

### PAN02 · Lista

```
vigencia: vigente
actor: usuario
proposito: listar
muestra: item.nombre
pide: —
acciones: abrir
vacio: vacio → crear
carga: spinner → espera
error: mensaje → reintentar
dominio: —
comparte: —
traza: AC2
```

## Flujos

### FLU01 · mixto — actor: usuario — traza: O1

```mermaid
flowchart LR
  PAN01["Entrar"] --> PAN02
  PAN02 --> PAN02["Lista"]
  PAN02 -->|"contrapropuesta: nueva version"| PAN02
  PAN02["Lista"] -->|"abrir: detalle"| PAN01
```

## Navegación

```
entrada: PAN01
persistente: PAN02
```

```mermaid
flowchart TD
  PAN01 --> PAN02["Lista"]
```

## AC sin superficie

```
AC3: sin UI en v1
```
EOF
correr_esp verde-mermaid-mixto pasa "" "$TMP/verde-mixto/esp"

# ========== verde: Interfaz en celda de tabla ==========
mkdir -p "$TMP/verde-tabla/esp"
diseno_juguete "$TMP/verde-tabla/esp/diseno.md"
cat >"$TMP/verde-tabla/esp/ESTADO.md" <<'EOF'
# ESTADO

| Campo | Valor |
|---|---|
| **Estado** | Aceptada |
| **Interfaz** | si |
EOF
mapa_valido "$TMP/verde-tabla/esp/mapa.md" ACEPTADO
correr_esp verde-interfaz-tabla pasa "" "$TMP/verde-tabla/esp"

# ========== verde: INTERFAZ mayúsculas en tabla + valor Si ==========
mkdir -p "$TMP/verde-interfaz-mayus/esp"
diseno_juguete "$TMP/verde-interfaz-mayus/esp/diseno.md"
cat >"$TMP/verde-interfaz-mayus/esp/ESTADO.md" <<'EOF'
# ESTADO

| Campo | Valor |
|---|---|
| **Estado** | Aceptada |
| **INTERFAZ** | Si |
EOF
mapa_valido "$TMP/verde-interfaz-mayus/esp/mapa.md" ACEPTADO
correr_esp verde-interfaz-mayus-tabla pasa "" "$TMP/verde-interfaz-mayus/esp"

# ========== verde: Interfaz: NO (ESP sin interfaz) ==========
mkdir -p "$TMP/verde-interfaz-no/esp"
cat >"$TMP/verde-interfaz-no/esp/ESTADO.md" <<'EOF'
Interfaz: NO
Estado: aceptada
EOF
correr_esp verde-interfaz-NO pasa "" "$TMP/verde-interfaz-no/esp"

# ========== rojo: copia CRLF del script ==========
CRLF_TMP="$(mktemp "${TMPDIR:-/tmp}/alma-mapa-crlf.XXXXXX")"
sed 's/$/\r/' "$EST/verificadores/mapa.sh" >"$CRLF_TMP"
codigo_crlf=0
salida_crlf="$("$BASH_BIN" "$CRLF_TMP" 2>&1)" || codigo_crlf=$?
if [ "$codigo_crlf" -eq 1 ] && printf '%s\n' "$salida_crlf" | grep -q 'CRLF'; then
  ok_uno 'rojo-crlf (falla: CRLF)'
else
  falla_uno "rojo-crlf: esperaba exit 1 y texto CRLF (codigo=$codigo_crlf)"
  printf '%s\n' "$salida_crlf" | sed 's/^/           /' | head -10
fi
rm -f "$CRLF_TMP"

# ========== rojo: mermaid mixto con nodo que no es ID ==========
mkdir -p "$TMP/rojo-mixto/esp"
diseno_juguete "$TMP/rojo-mixto/esp/diseno.md"
cat >"$TMP/rojo-mixto/esp/ESTADO.md" <<'EOF'
Interfaz: si
Estado: aceptada
EOF
mapa_valido "$TMP/rojo-mixto/esp/mapa.md" ACEPTADO
cat >>"$TMP/rojo-mixto/esp/mapa.md" <<'EOF'

### FLU99 · nodo ilegal

```mermaid
flowchart LR
  PAN01 --> Foo["no-id"]
```
EOF
correr_esp rojo-mermaid-mixto-noid falla "sintaxis permitida|fuera de la sintaxis" "$TMP/rojo-mixto/esp"

# via catalogo.sh (producto con mapa pendiente no conforme)
mkdir -p "$TMP/verde/cat/resources/views/components" "$TMP/verde/cat/docs" "$TMP/verde/cat/resources/css"
cat >"$TMP/verde/cat/proyecto-caso.md" <<'EOF'
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
mapa: pendiente
```
EOF
cat >"$TMP/verde/cat/docs/catalogo.md" <<'EOF'
# Catalogo
Estado del proyecto: `en convergencia`
## boton
rol: accion
estado: vigente
no-usar-cuando: no
excepciones: ninguna
archivo: resources/views/components/boton.blade.php
EOF
cat >"$TMP/verde/cat/resources/views/components/boton.blade.php" <<'EOF'
<button type="button" class="alma-accion"
  style="color: var(--alma-color-sobre-accion); background: var(--alma-color-accion);
         padding: var(--alma-espacio); border-radius: var(--alma-radio);
         font-family: var(--alma-fuente); font-size: var(--alma-tamano-cuerpo);
         border-width: var(--alma-borde-ancho);">
  Accion
</button>
EOF
cat >"$TMP/verde/cat/resources/css/tokens.css" <<'EOF'
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
salida="$(RAIZ_PROYECTO="$TMP/verde/cat" RAIZ_ESTANDAR="$EST" \
          "$BASH_BIN" "$EST/verificadores/catalogo.sh" 2>&1)" || true
if printf '%s\n' "$salida" | grep -q 'catalogo: sin fallas'; then
  ok_uno 'verde-via-catalogo (pasa)'
else
  falla_uno 'verde-via-catalogo'
  printf '%s\n' "$salida" | sed 's/^/           /' | head -30
fi

echo
if [ "$fallos_casos" -gt 0 ]; then
  echo "casos-mapa: $fallos_casos FALLA(S) / $ok_casos ok"
  exit 1
fi
echo "casos-mapa: sin fallas ($ok_casos ok)"
exit 0
