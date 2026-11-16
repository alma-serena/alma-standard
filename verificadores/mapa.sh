#!/usr/bin/env bash
# Verificador del mapa de pantallas y flujos. Un verificador, dos llamadores (D-C32):
#   --esp <carpeta-ESP> · lo usa alma-serena (diseno.md al lado del mapa)
#   sin --esp           · lo llama catalogo.sh (modo producto, lee proyecto-*.md)
#   --diff              · hook: AVISA, no bloquea (D-C44)
#   sin --diff          · certificacion: BLOQUEA
#
# Sin temporales de nombre fijo; anclado a la raiz (H-VER-1/5). El mermaid se lee
# con expresiones regulares sobre la sintaxis permitida; cualquier otra linea
# dentro de un bloque mermaid es FALLA. Ninguna comprobacion depende del kit (linea C).
#
# Windows: copiar este script con `git show <ref>:verificadores/mapa.sh > mapa.sh`
# desde Git Bash (finales LF). Set-Content de PowerShell o una copia CRLF lo rompen.
# Guardia CRLF en una sola linea (el \r cae en el comentario final); un bloque if
# con copia CRLF falla por sintaxis antes de llegar al grep.

grep -Uq $'\r' "$0" && { echo "  FALLA · mapa.sh tiene finales CRLF. Copialo con: git show <ref>:verificadores/mapa.sh > mapa.sh (Git Bash, LF)."; exit 1; } #
set -u

fallos=0; avisos=0
CON_DIFF=0
ESP_DIR=""

err() {
  if [ "$CON_DIFF" -eq 1 ]; then
    echo "  aviso · $*"; avisos=$((avisos+1))
  else
    echo "  FALLA · $*"; fallos=$((fallos+1))
  fi
}
aviso() { echo "  aviso · $*"; avisos=$((avisos+1)); }
ok()    { echo "  ok    · $*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --diff) CON_DIFF=1; shift ;;
    --esp)
      [ $# -ge 2 ] || { echo "  FALLA · --esp requiere una carpeta"; exit 1; }
      ESP_DIR="$2"; shift 2 ;;
    -h|--help)
      cat <<'EOF'
Uso:
  bash verificadores/mapa.sh --esp <carpeta-ESP> [--diff]
  bash verificadores/mapa.sh [--diff]

  --esp   modo ESP: lee ESTADO.md, mapa.md, diseno.md (y experiencia.md si hay)
          en <carpeta-ESP>. Comprueba forma, mermaid, alcanzabilidad, traza y
          cobertura de AC.
  (sin)   modo producto: lee proyecto-*.md en la raiz del repo (o RAIZ_PROYECTO).
          Comprueba mapa:/mapa-origen:, hash sha256, misiones abiertas con
          pantallas:, y la forma del mapa (sin traza a AC).
  --diff  mismo analisis; FALLA se degrada a aviso y el exit es 0 (D-C44).
EOF
      exit 0 ;;
    *) echo "  FALLA · flag desconocido: $1 (usa --help)"; exit 1 ;;
  esac
done

echo "== mapa de pantallas y flujos =="

RAIZ_ESTANDAR="${RAIZ_ESTANDAR:-.}"
raiz_repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$ESP_DIR" ]; then
  if [ -n "${RAIZ_PROYECTO:-}" ]; then
    cd "$RAIZ_PROYECTO" || { echo "  FALLA · no se pudo anclar a RAIZ_PROYECTO=$RAIZ_PROYECTO"; exit 1; }
  elif [ -n "$raiz_repo" ]; then
    cd "$raiz_repo" || { echo "  FALLA · no se pudo anclar a la raiz del repo"; exit 1; }
  fi
fi

campo_bloque() { # $1 clave $2 archivo — lee "clave: valor" dentro del primer ``` ... ```
  awk -v k="$1" '
    /^```/ { if (++c==1) next; exit }
    c==1 && $0 ~ ("^" k ":") {
      sub(/^[^:]+:[[:space:]]*/, ""); print; exit
    }
  ' "$2"
}

campo_proy() { # $1 clave $2 archivo proyecto
  sed -n "s/^$1:[[:space:]]*//p" "$2" | head -1
}

hash_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

# Extrae bloques mermaid (contenido interior) a stdout, separados por ---BLOQUE---
bloques_mermaid() {
  awk '
    /^```mermaid[[:space:]]*$/ { f=1; next }
    f && /^```[[:space:]]*$/ { f=0; print "---BLOQUE---"; next }
    f { print }
  ' "$1"
}

# Valida sintaxis permitida. Escribe IDs hallados en $2 (archivo), nunca a stdout.
validar_mermaid() { # $1 etiqueta  $2 archivo-nodos  stdin=bloque
  local etiq="$1" out="$2" linea n=0 primera=1
  : >"$out"
  while IFS= read -r linea || [ -n "$linea" ]; do
    [ "$linea" = "---BLOQUE---" ] && break
    linea="${linea#"${linea%%[![:space:]]*}"}"
    linea="${linea%"${linea##*[![:space:]]}"}"
    [ -z "$linea" ] && continue
    n=$((n+1))
    if [ "$primera" -eq 1 ]; then
      case "$linea" in
        "flowchart TD"|"flowchart LR") primera=0; continue ;;
        *) err "$etiq: primera linea mermaid debe ser 'flowchart TD' o 'flowchart LR' (vio: $linea)"; return 1 ;;
      esac
    fi
    # Nodo: PANnn o PANnn["nombre"]. Se admiten mezclados en la misma arista.
    local ok_linea=0 a="" b=""
    local re_nodo='PAN[0-9]{2,}(\["[^"]*"\])?'
    if printf '%s\n' "$linea" | grep -qE '^PAN[0-9]{2,}\["[^"]*"\][[:space:]]*$'; then
      a="$(printf '%s\n' "$linea" | sed -E 's/^(PAN[0-9]{2,}).*/\1/')"; ok_linea=1
    elif printf '%s\n' "$linea" | grep -qE "^${re_nodo}[[:space:]]*-->\|\"[^\"]*\"\|[[:space:]]*${re_nodo}[[:space:]]*$"; then
      a="$(printf '%s\n' "$linea" | sed -E 's/^(PAN[0-9]{2,}).*/\1/')"
      b="$(printf '%s\n' "$linea" | sed -E 's/.*-->\|"[^"]*"\|[[:space:]]*(PAN[0-9]{2,}).*/\1/')"; ok_linea=1
    elif printf '%s\n' "$linea" | grep -qE "^${re_nodo}[[:space:]]*-->[[:space:]]*${re_nodo}[[:space:]]*$"; then
      a="$(printf '%s\n' "$linea" | sed -E 's/^(PAN[0-9]{2,}).*/\1/')"
      b="$(printf '%s\n' "$linea" | sed -E 's/.*-->[[:space:]]*(PAN[0-9]{2,}).*/\1/')"; ok_linea=1
    fi
    if [ "$ok_linea" -eq 1 ]; then
      [ -n "$a" ] && printf '%s\n' "$a" >>"$out"
      [ -n "$b" ] && printf '%s\n' "$b" >>"$out"
      continue
    fi
    err "$etiq: linea mermaid fuera de la sintaxis permitida: $linea"
  done
  [ "$n" -eq 0 ] && err "$etiq: bloque mermaid vacio"
}

# Extrae aristas "ORIG DEST" de un bloque mermaid (para alcanzabilidad)
aristas_mermaid() {
  local linea a b
  while IFS= read -r linea || [ -n "$linea" ]; do
    [ "$linea" = "---BLOQUE---" ] && break
    linea="${linea#"${linea%%[![:space:]]*}"}"
    linea="${linea%"${linea##*[![:space:]]}"}"
    [ -z "$linea" ] && continue
    case "$linea" in flowchart*) continue ;; esac
    a="$(printf '%s\n' "$linea" | sed -E 's/^(PAN[0-9]{2,}).*/\1/;t;d')"
    b="$(printf '%s\n' "$linea" | sed -E 's/.*-->(\|"[^"]*"\|[[:space:]]*)?(PAN[0-9]{2,}).*/\2/;t;d')"
    [ -n "$a" ] && [ -n "$b" ] && printf '%s %s\n' "$a" "$b"
  done
}

CAMPOS_PAN="vigencia actor proposito muestra pide acciones vacio carga error dominio comparte traza"

# Comprueba la forma de un mapa.md. $1 ruta. $2 con_traza (1|0).
# Variables de salida via archivos temporales: lista de PAN, vigentes, etc.
comprobar_forma() {
  local mapa="$1" con_traza="$2"
  local estado esp_v
  [ -f "$mapa" ] || { err "no existe el mapa: $mapa"; return 1; }

  estado="$(campo_bloque estado "$mapa")"
  case "$estado" in
    BORRADOR|EN_REVISION|ACEPTADO) ok "estado: $estado" ;;
    "") err "mapa sin campo 'estado:' en la cabecera" ;;
    *) err "estado invalido: '$estado' (BORRADOR|EN_REVISION|ACEPTADO)" ;;
  esac
  MAPA_ESTADO="$estado"

  esp_v="$(campo_bloque esp "$mapa")"
  [ -z "$esp_v" ] && err "mapa sin campo 'esp:' en la cabecera"
  [ -z "$(campo_bloque version "$mapa")" ] && err "mapa sin campo 'version:' en la cabecera"

  # Pantallas: ### PANnn
  local ids ids_u dup id
  ids="$(grep -E '^### PAN[0-9]{2,}' "$mapa" | sed -E 's/^### (PAN[0-9]{2,}).*/\1/' || true)"
  [ -z "$ids" ] && err "el mapa no declara ninguna pantalla PANnn"

  ids_u="$(printf '%s\n' "$ids" | sort -u)"
  dup="$(printf '%s\n' "$ids" | sort | uniq -d || true)"
  [ -n "$dup" ] && err "IDs de pantalla duplicados: $(printf '%s' "$dup" | tr '\n' ' ')"

  MAPA_IDS="$ids_u"
  MAPA_VIGENTES=""
  local bloque c val
  for id in $ids_u; do
    bloque="$(awk -v id="$id" '
      $0 ~ ("^### " id "([^0-9]|$)") {f=1; next}
      f && /^### / {exit}
      f {print}
    ' "$mapa")"
    for c in $CAMPOS_PAN; do
      val="$(printf '%s\n' "$bloque" | sed -n "s/^$c:[[:space:]]*//p" | head -1)"
      if [ -z "$val" ]; then
        # puede estar dentro de un fence
        val="$(printf '%s\n' "$bloque" | awk -v k="$c" '
          /^```/ {fence=!fence; next}
          fence && $0 ~ ("^" k ":") { sub(/^[^:]+:[[:space:]]*/,""); print; exit }
          !fence && $0 ~ ("^" k ":") { sub(/^[^:]+:[[:space:]]*/,""); print; exit }
        ')"
      fi
      [ -z "$val" ] && err "pantalla $id: falta el campo '$c'"
      case "$c" in
        vacio|carga|error)
          if [ -z "$val" ]; then
            err "pantalla $id: '$c' vacio (usa valor o 'N/A — razon')"
          elif [ "$val" = "N/A" ] || [ "$val" = "N/A —" ] || [ "$val" = "N/A-" ]; then
            err "pantalla $id: '$c' incompleto (exige 'N/A — razon')"
          fi
          # N/A — razon es valido; cualquier texto no vacio tambien
          ;;
        vigencia)
          case "$val" in
            vigente) MAPA_VIGENTES="$MAPA_VIGENTES $id" ;;
            retirada) : ;;
            *) err "pantalla $id: vigencia invalida '$val'" ;;
          esac
          ;;
        traza)
          if [ "$con_traza" -eq 1 ] && [ -z "$val" ]; then
            err "pantalla $id: sin traza"
          fi
          ;;
      esac
      eval "PAN_${id}_${c}=\"\$val\""
    done
    # reemplaza opcional
    local reemp
    reemp="$(printf '%s\n' "$bloque" | awk '
      /^```/ {fence=!fence; next}
      (fence || !fence) && /^reemplaza:/ { sub(/^reemplaza:[[:space:]]*/,""); print; exit }
    ')"
    if [ -n "$reemp" ]; then
      printf '%s\n' "$ids_u" | grep -qx "$reemp" \
        || err "pantalla $id: reemplaza: $reemp no existe"
    fi
  done

  # Flujos FLUnn + mermaid
  local flus flu nodos_all aristas_all
  flus="$(grep -E '^### FLU[0-9]{2,}' "$mapa" | sed -E 's/^### (FLU[0-9]{2,}).*/\1/' || true)"
  nodos_all=""
  aristas_all=""
  local tmp_mm
  tmp_mm="$(mktemp)"
  bloques_mermaid "$mapa" >"$tmp_mm"

  # Asociar cada bloque mermaid a contexto (flujo o navegacion) por orden:
  # todos los mermaid de flujos aparecen bajo ## Flujos; el de navegacion bajo ## Navegacion.
  # Validamos TODOS los bloques con la misma whitelist.
  local nbloque=0 fragmento nodos_f
  fragmento="$(mktemp)"
  nodos_f="$(mktemp)"
  : >"$fragmento"
  while IFS= read -r linea || [ -n "$linea" ]; do
    if [ "$linea" = "---BLOQUE---" ]; then
      nbloque=$((nbloque+1))
      local etiq="mermaid#$nbloque"
      validar_mermaid "$etiq" "$nodos_f" <"$fragmento"
      local id
      for id in $(sort -u "$nodos_f"); do
        printf '%s\n' "$ids_u" | grep -qx "$id" \
          || err "$etiq: nodo '$id' no es un ID de pantalla del mapa"
        nodos_all="$nodos_all $id"
      done
      aristas_all="$aristas_all
$(aristas_mermaid <"$fragmento")"
      : >"$fragmento"
      continue
    fi
    printf '%s\n' "$linea" >>"$fragmento"
  done <"$tmp_mm"
  rm -f "$tmp_mm" "$fragmento" "$nodos_f"

  # Navegacion: entrada + persistente (seccion, no el primer fence de cabecera).
  # Prefijo ASCII: evita fallar por la tilde en "Navegación" segun locale/awk.
  local entrada persistente
  entrada="$(awk '
    /^## Navegaci/ {nav=1}
    nav && /^```/ {f++; next}
    nav && f==1 && /^entrada:/ { sub(/^entrada:[[:space:]]*/,""); print; exit }
  ' "$mapa")"
  persistente="$(awk '
    /^## Navegaci/ {nav=1}
    nav && /^```/ {f++; next}
    nav && f==1 && /^persistente:/ { sub(/^persistente:[[:space:]]*/,""); print; exit }
  ' "$mapa")"
  [ -z "$entrada" ] && err "navegacion: falta 'entrada:'"
  if [ -n "$entrada" ]; then
    printf '%s\n' "$ids_u" | grep -qx "$entrada" \
      || err "navegacion: entrada '$entrada' no existe"
  fi

  # Alcanzabilidad desde entrada
  local alcanzados cola p a b
  alcanzados=" $entrada "
  for p in $(printf '%s\n' "$persistente" | tr ',' ' '); do
    p="$(printf '%s' "$p" | tr -d ' ')"
    [ -z "$p" ] && continue
    printf '%s\n' "$ids_u" | grep -qx "$p" || err "navegacion: persistente '$p' no existe"
    alcanzados="$alcanzados$p "
  done
  # BFS
  local cambio=1
  while [ "$cambio" -eq 1 ]; do
    cambio=0
    while read -r a b; do
      [ -z "${a:-}" ] && continue
      case "$alcanzados" in
        *" $a "*)
          case "$alcanzados" in
            *" $b "*) : ;;
            *) alcanzados="$alcanzados$b "; cambio=1 ;;
          esac
          ;;
      esac
    done <<EOF
$(printf '%s\n' "$aristas_all")
EOF
  done
  for id in $MAPA_VIGENTES; do
    case "$alcanzados" in
      *" $id "*) : ;;
      *) err "pantalla vigente $id inalcanzable desde entrada (ni flujo ni persistente)" ;;
    esac
  done

  [ -n "$flus" ] || aviso "mapa sin flujos FLUnn (permitido si la navegacion basta)"
}

# Traza y cobertura (solo modo ESP)
comprobar_traza_cobertura() {
  local mapa="$1" diseno="$2" exp="$3"
  [ -f "$diseno" ] || { err "no existe diseno.md en la ESP: $diseno"; return 1; }

  # IDs definidos en diseno: O n, AC n (y EX si experiencia)
  local defs
  defs="$(grep -oE '\b(O|AC)[0-9]+\b' "$diseno" | sort -u)"
  local defs_ex=""
  if [ -f "$exp" ]; then
    defs_ex="$(grep -oE '\bEX[0-9]+\b' "$exp" | sort -u)"
  fi

  local id traza tok cubiertos
  cubiertos=""
  for id in $MAPA_IDS; do
    traza="$(eval "printf '%s' \"\${PAN_${id}_traza:-}\"")"
    [ -z "$traza" ] && { err "pantalla $id: sin traza"; continue; }
    # tokens separados por coma
    local resto="$traza"
    resto="$(printf '%s' "$resto" | tr ',' ' ')"
    for tok in $resto; do
      tok="$(printf '%s' "$tok" | tr -d ' ')"
      [ -z "$tok" ] && continue
      case "$tok" in
        EX[0-9]*)
          if [ ! -f "$exp" ]; then
            err "pantalla $id: cita $tok pero no hay experiencia.md"
          elif ! printf '%s\n' "$defs_ex" | grep -qx "$tok"; then
            err "pantalla $id: $tok no esta definido en experiencia.md"
          fi
          ;;
        O[0-9]*|AC[0-9]*)
          if ! printf '%s\n' "$defs" | grep -qx "$tok"; then
            err "pantalla $id: $tok no existe en diseno.md"
          else
            cubiertos="$cubiertos $tok"
          fi
          ;;
        *) err "pantalla $id: token de traza invalido '$tok'" ;;
      esac
    done
  done

  # AC sin superficie (rangos ACa–ACb o ACa-ACb)
  local sin_sup
  sin_sup="$(awk '
    /^## AC sin superficie/ {f=1; next}
    f && /^## / {exit}
    f && /^```/ {g=!g; next}
    f && g {
      line=$0
      # AC10: razon  | AC40–AC62: razon | AC40-AC62
      while (match(line, /AC[0-9]+([–-]AC[0-9]+)?/)) {
        print substr(line, RSTART, RLENGTH)
        line=substr(line, RSTART+RLENGTH)
      }
    }
  ' "$mapa")"

  expandir_rango() {
    local s="$1" a b i
    if printf '%s\n' "$s" | grep -qE 'AC[0-9]+[–-]AC[0-9]+'; then
      a="$(printf '%s\n' "$s" | sed -E 's/^AC([0-9]+)[–-].*/\1/')"
      b="$(printf '%s\n' "$s" | sed -E 's/.*[–-]AC([0-9]+)$/\1/')"
      i="$a"
      while [ "$i" -le "$b" ]; do
        printf 'AC%s\n' "$i"
        i=$((i+1))
      done
    else
      printf '%s\n' "$s"
    fi
  }

  local cubiertos_ac="" x
  for x in $cubiertos; do
    case "$x" in AC*) cubiertos_ac="$cubiertos_ac $x" ;; esac
  done
  local r
  while IFS= read -r r; do
    [ -z "$r" ] && continue
    for x in $(expandir_rango "$r"); do
      cubiertos_ac="$cubiertos_ac $x"
    done
  done <<EOF
$sin_sup
EOF

  # Todo AC de diseno debe estar cubierto
  local ac
  for ac in $(printf '%s\n' "$defs" | grep '^AC' || true); do
    case " $cubiertos_ac " in
      *" $ac "*) : ;;
      *) err "AC $ac de diseno.md sin cobertura (ni traza ni 'AC sin superficie')" ;;
    esac
  done

  # aviso si experiencia repite inventario o flujo
  if [ -f "$exp" ]; then
    if grep -qE '^```mermaid' "$exp" || grep -qE '^### PAN[0-9]{2,}|^PAN[0-9]{2,}[[:space:]]*:' "$exp"; then
      aviso "experiencia.md parece repetir inventario o flujo (mermaid o PANnn)"
    fi
  fi
}

# --- modo ESP ---------------------------------------------------------------
if [ -n "$ESP_DIR" ]; then
  [ -d "$ESP_DIR" ] || { echo "  FALLA · --esp: no es carpeta: $ESP_DIR"; exit 1; }
  local_estado="$ESP_DIR/ESTADO.md"
  local_mapa="$ESP_DIR/mapa.md"
  local_diseno="$ESP_DIR/diseno.md"
  local_exp="$ESP_DIR/experiencia.md"

  interfaz_esp=""
  aceptada=0
  if [ -f "$local_estado" ]; then
    # Linea "Interfaz: si|no" o celda de tabla "| Interfaz | si |" / "| **INTERFAZ** | Si |"
    # Etiqueta sin distinguir mayúsculas; valor a minúsculas antes del case.
    interfaz_esp="$(grep -iE '^Interfaz:[[:space:]]*' "$local_estado" | head -1 \
      | sed -E 's/^[^:]+:[[:space:]]*//;s/[[:space:]]*$//')"
    if [ -z "$interfaz_esp" ]; then
      interfaz_esp="$(grep -iE '^\|[[:space:]]*\*{0,2}Interfaz\*{0,2}[[:space:]]*\|' "$local_estado" \
        | head -1 \
        | sed -E 's/^\|[^|]*\|[[:space:]]*//;s/[[:space:]]*\|.*//;s/\*//g;s/[[:space:]]*$//')"
    fi
    interfaz_esp="$(printf '%s' "$interfaz_esp" | tr '[:upper:]' '[:lower:]')"
    if grep -qiE '(Estado|estado).*(aceptad|ACEPTAD)' "$local_estado" \
       || grep -qiE '^Estado:[[:space:]]*aceptad' "$local_estado"; then
      aceptada=1
    fi
    # tambien: "Aceptada" como valor de tabla
    grep -qiE '\|[[:space:]]*Aceptada[[:space:]]*\|' "$local_estado" && aceptada=1
  else
    err "ESP sin ESTADO.md"
  fi

  case "$interfaz_esp" in
    si|sí)
      [ -f "$local_mapa" ] || err "Interfaz: si y no existe mapa.md"
      ;;
    no)
      ok "ESP declara Interfaz: no"
      if [ "$fallos" -eq 0 ]; then
        echo "mapa: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
      fi
      echo "mapa: $fallos FALLA(S)"; exit 1
      ;;
    "")
      if [ "$aceptada" -eq 1 ]; then
        aviso "legado sin declarar: ESTADO.md sin campo Interfaz: si|no"
      else
        err "ESTADO.md sin campo Interfaz: si|no (ESP no aceptada)"
      fi
      ;;
    *) err "Interfaz invalida en ESTADO.md: '$interfaz_esp'" ;;
  esac

  if [ -f "$local_mapa" ]; then
    MAPA_ESTADO=""; MAPA_IDS=""; MAPA_VIGENTES=""
    comprobar_forma "$local_mapa" 1
    comprobar_traza_cobertura "$local_mapa" "$local_diseno" "$local_exp"
  fi

  if [ "$fallos" -eq 0 ]; then
    echo "mapa: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
  fi
  echo "mapa: $fallos FALLA(S)"; exit 1
fi

# --- modo producto ----------------------------------------------------------
PROY="$(ls proyecto-*.md 2>/dev/null | head -1 || true)"
if [ -z "$PROY" ]; then
  aviso "sin proyecto-*.md: nada que comprobar en modo producto"
  echo "mapa: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
fi

INTERFAZ="$(campo_proy interfaz "$PROY")"
case "$INTERFAZ" in
  no)
    ok "proyecto declara interfaz: no"
    echo "mapa: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
    ;;
  si) : ;;
  "")
    # catalogo.sh ya falla por esto; aqui no duplicamos ruido si nos llaman solos
    err "'$PROY' no declara 'interfaz: si|no'"
    echo "mapa: $fallos FALLA(S)"; exit 1
    ;;
  *) err "valor invalido de interfaz: '$INTERFAZ'"; echo "mapa: $fallos FALLA(S)"; exit 1 ;;
esac

MAPA_CAMPO="$(campo_proy mapa "$PROY")"
MAPA_ORIGEN="$(campo_proy mapa-origen "$PROY")"

if [ -z "$MAPA_CAMPO" ]; then
  err "'$PROY' declara interfaz: si y no declara 'mapa:' (ruta, o 'pendiente')"
  echo "mapa: $fallos FALLA(S)"; exit 1
fi

# Estado del catalogo (conforme / en convergencia) para pendiente
EST_PROY="en convergencia"
ARCH_CAT="$(campo_proy catalogo "$PROY")"
if [ -n "$ARCH_CAT" ] && [ -f "$ARCH_CAT" ]; then
  EST_PROY="$(sed -n 's/.*Estado del proyecto:[^`]*`\([a-z ]*\)`.*/\1/p' "$ARCH_CAT" | head -1)"
  [ -z "$EST_PROY" ] && EST_PROY="en convergencia"
fi

if [ "$MAPA_CAMPO" = "pendiente" ]; then
  aviso "mapa: pendiente (nombre: $PROY)"
  if [ "$EST_PROY" = "conforme" ]; then
    err "'conforme' declarado con mapa: pendiente"
  fi
  # misiones con pantallas distintas de ninguna siguen fallando: no hay mapa ACEPTADO
  MAPA_ESTADO="PENDIENTE"
  MAPA_IDS=""
  MAPA_VIGENTES=""
else
  # marcador de plantilla
  case "$MAPA_CAMPO" in
    *"<"*|*">"*) err "'mapa:' sigue con el marcador de la plantilla: $MAPA_CAMPO" ;;
  esac
  [ -f "$MAPA_CAMPO" ] || err "mapa declarado que no existe: $MAPA_CAMPO"
  [ -z "$MAPA_ORIGEN" ] && err "'$PROY' declara mapa: $MAPA_CAMPO y no declara 'mapa-origen:'"

  # mapa-origen: alma-serena@<sha> · sha256 <hash>
  hash_decl="$(printf '%s\n' "$MAPA_ORIGEN" | sed -nE 's/.*sha256[[:space:]]+([0-9a-fA-F]{64}).*/\1/p')"
  if [ -z "$hash_decl" ]; then
    err "mapa-origen: forma invalida (espera 'alma-serena@<sha> · sha256 <hash>'): $MAPA_ORIGEN"
  elif [ -f "$MAPA_CAMPO" ]; then
    hash_real="$(hash_sha256 "$MAPA_CAMPO")"
    if [ "$hash_real" != "$hash_decl" ]; then
      err "hash del mapa distinto del declarado en mapa-origen: (archivo=$hash_real)"
    else
      ok "hash del mapa coincide con mapa-origen"
    fi
  fi

  if [ -f "$MAPA_CAMPO" ]; then
    MAPA_ESTADO=""; MAPA_IDS=""; MAPA_VIGENTES=""
    comprobar_forma "$MAPA_CAMPO" 0
  fi
fi

# Misiones abiertas con pantallas:
# docs/misiones/*.md — Estado no cerrado/hecha; pantallas: distinto de ninguna
if [ -d docs/misiones ]; then
  for m in docs/misiones/*.md; do
    [ -f "$m" ] || continue
    est="$(grep -E '^\*\*Estado:\*\*' "$m" | head -1 | sed -E 's/.*\*\*Estado:\*\*[[:space:]]*//;s/[[:space:]]*$//')"
    case "$est" in
      cerrada|hecha|cerrado|hecho|cancelada|cancelado) continue ;;
      "") continue ;;
    esac
    pants="$(grep -iE '^\*\*pantallas:\*\*|^pantallas:' "$m" | head -1 \
             | sed -E 's/^\*\*pantallas:\*\*[[:space:]]*//;s/^pantallas:[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$pants" ] && continue
    case "$pants" in
      ninguna|Ninguna|NINGUNA) continue ;;
    esac
    # exige mapa ACEPTADO
    if [ "${MAPA_ESTADO:-}" != "ACEPTADO" ]; then
      err "mision abierta $(basename "$m" .md) declara pantallas: $pants y el mapa no esta ACEPTADO (estado=${MAPA_ESTADO:-ausente})"
      continue
    fi
    for pid in $(printf '%s\n' "$pants" | tr ',' ' '); do
      pid="$(printf '%s' "$pid" | tr -d ' ')"
      [ -z "$pid" ] && continue
      if ! printf '%s\n' "$MAPA_IDS" | grep -qx "$pid"; then
        err "mision $(basename "$m" .md): pantalla $pid no existe en el mapa"
        continue
      fi
      case " $MAPA_VIGENTES " in
        *" $pid "*) : ;;
        *) err "mision $(basename "$m" .md): pantalla $pid no tiene vigencia: vigente" ;;
      esac
    done
  done
fi

if [ "$fallos" -eq 0 ]; then
  echo "mapa: sin fallas${avisos:+ ($avisos aviso/s)}"
  exit 0
fi
echo "mapa: $fallos FALLA(S)"
exit 1
