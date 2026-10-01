#!/usr/bin/env bash
# Verificador del catalogo de interfaz. Un verificador, dos llamadores (D-C32):
#   --diff  · lo invoca el hook. AVISA, no bloquea (D-C44).
#   sin arg · lo invoca el job `certificacion`. BLOQUEA.
#
# Ronda v0.2.0:
#   D-C40 · indice INVERSO: todo archivo bajo una raiz de componentes tiene ficha.
#           Antes se comprobaba que el catalogo estuviera en el diff, y eso se
#           cumplia con una linea en blanco, o escribiendo en una raiz no declarada,
#           o dejandolo al CI, que llama sin --diff y nunca lo corria.
#   D-C41 · los estados que eximen (`genesis`, `interfaz: no`) tienen condicion de
#           salida comprobable. Entrar era legitimo; no salir nunca, no.
#   H-VER-1/4 · sin archivo temporal de nombre fijo; anclado a la raiz del repo.

set -u
fallos=0; avisos=0
err()   { echo "  FALLA · $*"; fallos=$((fallos+1)); }
aviso() { echo "  aviso · $*"; avisos=$((avisos+1)); }
ok()    { echo "  ok    · $*"; }

RAIZ_ESTANDAR="${RAIZ_ESTANDAR:-.}"
CON_DIFF=0
[ "${1:-}" = "--diff" ] && CON_DIFF=1

echo "== catalogo de interfaz =="

# RAIZ_PROYECTO · ancla a un arbol de prueba (verificadores-estandar/casos.sh).
# Sin ella, se ancla al toplevel de git como siempre.
raiz_repo="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "${RAIZ_PROYECTO:-}" ]; then
  cd "$RAIZ_PROYECTO" || { echo "  FALLA · no se pudo anclar a RAIZ_PROYECTO=$RAIZ_PROYECTO"; exit 1; }
elif [ -n "$raiz_repo" ]; then
  cd "$raiz_repo" || { echo "  FALLA · no se pudo anclar a la raiz del repo"; exit 1; }
fi

campo()  { sed -n "s/^$1:[[:space:]]*//p" "$2" | head -1; }
bloque_anexo() { # $1 marcador, $2 archivo
  awk -v ini="$1:inicio" -v fin="$1:fin" '$0 ~ ini {f=1;next} $0 ~ fin {f=0} f' "$2" \
    | tr -d ' \t' | grep -v '^$'
}
# D-C46 · LISTA BLANCA. Se enumera lo permitido —el andamiaje— y todo lo demas es
# producto. La version anterior enumeraba trece extensiones de codigo y dejaba fuera
# .dart, .cs, .rs, .xml: el hueco no se cerraba, se mudaba al primer stack no listado.
# Andamiaje por defecto si el proyecto no lo declara: lo que aporta el estandar.
# El andamiaje por defecto es TODO lo que el estandar aporta. Se escribe completo aqui
# y el dia que exista el manifest de OPS-07 se deriva de el en vez de listarse.
# (Al estrenar esta lista faltaban ALMA-UPGRADE.md y RAIZ-DE-CONFIANZA.md, y el
#  verificador fallo sobre el arbol del propio estandar: la lista blanca tambien
#  necesita una fuente derivable, no memoria.)
ANDAMIAJE_RESPALDO='AGENTS.md CLAUDE.md METODOLOGIA.md INSTALACION.md CHANGELOG.md ALMA-UPGRADE.md RAIZ-DE-CONFIANZA.md .agents .github .githooks verificadores plantillas'
# Lo que es andamiaje en cualquier proyecto, venga o no del estandar.
ANDAMIAJE_EXTRA='.git .alma docs .gitignore .gitattributes README.md LICENSE'
# D-C48 · DERIVACION. Si el proyecto tiene manifest, el andamiaje que aporta el
# estandar se lee de el en vez de recordarse. Eso cierra el hueco que esta misma
# lista confesaba mas arriba: una lista escrita de memoria olvida lo que no se mira.
ANDAMIAJE_ESTANDAR="$ANDAMIAJE_RESPALDO"
if [ -f .alma/manifest.sha256 ]; then
  derivado="$(awk '{ $1=""; sub(/^[[:space:]]+/,""); print }' .alma/manifest.sha256 \
              | sed 's#/.*##' | grep -v '^$' | sort -u | tr '\n' ' ')"
  [ -n "$derivado" ] && ANDAMIAJE_ESTANDAR="$derivado"
fi
ANDAMIAJE_DEF="$ANDAMIAJE_ESTANDAR $ANDAMIAJE_EXTRA"
hay_producto() {
  lista="${1:-$ANDAMIAJE_DEF}"
  find . -mindepth 1 -not -path './.git' -not -path './.git/*' 2>/dev/null \
  | sed 's#^\./##' | while IFS= read -r p; do
      [ -z "$p" ] && continue
      case "$p" in proyecto-*.md) continue ;; esac
      es_andamiaje=0
      for a in $lista; do
        a="${a%/}"; a="${a%,}"
        case "$p" in "$a"|"$a"/*) es_andamiaje=1; break ;; esac
        case "$a" in proyecto-\*.md) case "$p" in proyecto-*.md) es_andamiaje=1; break ;; esac ;; esac
      done
      [ $es_andamiaje -eq 0 ] && [ -f "$p" ] && { echo "$p"; break; }
    done | head -1
}

# --- 0 · capa de proyecto y estados que eximen ------------------------------
PROY="$(ls proyecto-*.md 2>/dev/null | head -1 || true)"
MODO="$(cat .alma/modo-mision 2>/dev/null || echo '')"

if [ -z "$PROY" ]; then
  if [ -n "$(hay_producto)" ]; then
    err "no hay proyecto-<nombre>.md y el arbol YA tiene archivos que no son andamiaje."
    err "       'genesis' describe un arbol vacio: su condicion de salida se cumplio (D-C41)."
    echo "catalogo: $fallos FALLA(S)"; exit 1
  fi
  aviso "sin proyecto-<nombre>.md y sin codigo de producto: genesis legitimo"
  echo "catalogo: sin fallas ($avisos aviso/s)"; exit 0
fi
ANDAMIAJE="$(campo andamiaje "$PROY" | tr ',' ' ')"

# --- 0a · plantilla sin rellenar ---------------------------------------------
# El defecto medido el 2026-09-27: `plantillas/proyecto-EJEMPLO.md` traia
# `maqueta: /dev/catalogo` como ejemplo, WorldWeaver lo copio, nadie lo cambio, y la
# ruta no existia. No fue deriva: fue un valor plausible que nadie comprobaba.
# Un valor con `<` o `>` es la plantilla sin rellenar, y eso SI es comprobable con
# certeza mecanica. Cubre cualquier campo copiado, no solo el que se descubrio.
for c in andamiaje anexo interfaz componentes catalogo tokens tokens-base maqueta origen; do
  v="$(campo "$c" "$PROY")"
  case "$v" in
    *"<"*|*">"*) err "'$PROY': '$c' sigue con el marcador de la plantilla: '$v'" ;;
  esac
done
if [ "$MODO" = "genesis" ] && [ -n "$(hay_producto "$ANDAMIAJE")" ]; then
  err "modo 'genesis' declarado sobre un arbol con archivos fuera del andamiaje (D-C41/D-C46)."
fi

ANEXO="$(campo anexo "$PROY")"
[ -z "$ANEXO" ] && err "'$PROY' no declara 'anexo:' (nombre del anexo de stack, o 'ninguno')"
ARCH_ANEXO=""
if [ -n "$ANEXO" ] && [ "$ANEXO" != "ninguno" ]; then
  ARCH_ANEXO="$RAIZ_ESTANDAR/.agents/rules/anexos/$ANEXO.md"
  [ -f "$ARCH_ANEXO" ] || { err "el anexo declarado no existe: $ARCH_ANEXO"; ARCH_ANEXO=""; }
fi

raices_conocidas=""
if [ -n "$ARCH_ANEXO" ]; then
  raices_conocidas="$(bloque_anexo 'raices-componentes' "$ARCH_ANEXO")"
  # D-C41 · un anexo PRESENTE pero SIN bloque de raices es un tercer estado que exime,
  # y la version anterior lo dejaba pasar en silencio. 'ninguno' avisaba; un anexo que
  # existe y no declara raices —`anexos/android.md` lo esta a proposito— caia por esta
  # primera rama con la lista vacia y sin una linea que lo dijera. La comprobacion 0b
  # recorre esa lista: vacia, no recorre nada, y el control que diseno.md §3 justifica
  # —«una lista que escribe quien se beneficia de que sea corta no es un control»—
  # desaparecia sin ruido. Un verificador que calla donde no puede comprobar mide de
  # menos sin equivocarse en ninguna celda.
  if [ -z "$raices_conocidas" ]; then
    aviso "el anexo '$ANEXO' no declara bloque 'raices-componentes': no hay raices"
    aviso "        conocidas con que comparar, igual que con anexo 'ninguno'."
  fi
elif [ "$ANEXO" = "ninguno" ]; then
  aviso "anexo 'ninguno': no hay raices conocidas con que comparar. No se puede"
  aviso "        comprobar si falta declarar una raiz; queda a revision humana."
fi

INTERFAZ="$(campo interfaz "$PROY")"
case "$INTERFAZ" in
  no)
    # D-C41 · la salida temprana va DESPUES de comprobar raices conocidas.
    for r in $raices_conocidas; do
      [ -d "$r" ] && err "'interfaz: no' con la raiz de componentes '$r' presente en el arbol"
    done
    if [ $fallos -eq 0 ]; then
      ok "el proyecto declara que no tiene interfaz, y ninguna raiz conocida existe"
      echo "catalogo: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
    fi
    echo "catalogo: $fallos FALLA(S)"; exit 1 ;;
  si) : ;;
  "") err "'$PROY' no declara 'interfaz: si|no'. La ausencia no se interpreta."
      echo "catalogo: $fallos FALLA(S)"; exit 1 ;;
  *)  err "valor invalido de 'interfaz': '$INTERFAZ'"
      echo "catalogo: $fallos FALLA(S)"; exit 1 ;;
esac

DIRS_COMP="$(campo componentes "$PROY" | tr ',' ' ')"
ARCH_CAT="$(campo catalogo "$PROY")"
ARCH_TOK="$(campo tokens "$PROY")"
ARCH_TOK_BASE="$(campo tokens-base "$PROY")"
[ -z "$DIRS_COMP" ] && err "'$PROY' declara interfaz y no declara 'componentes:'"
[ -z "$ARCH_CAT" ]  && err "'$PROY' declara interfaz y no declara 'catalogo:'"
[ -z "$ARCH_TOK" ]  && err "'$PROY' declara interfaz y no declara 'tokens:'"

# ORIGEN · diseno.md §1: "una base adoptada con su version, o «desde cero»". Se exige
# y se enumera. Hasta el 2026-09-27 el campo se declaraba y NADIE lo leia, asi que
# escribirlo o no escribirlo daba el mismo resultado: la regla existia sin dientes,
# el mismo defecto que [V-6] corrigio una capa mas arriba.
ORIGEN="$(campo origen "$PROY")"
if [ -z "$ORIGEN" ]; then
  err "'$PROY' declara interfaz y no declara 'origen:' (base adoptada con su version, o 'desde cero')"
elif [ "$ORIGEN" != "desde cero" ]; then
  # Una base sin version no es una base adoptada: es un nombre.
  printf '%s\n' "$ORIGEN" | grep -qE '[^[:space:]]+[[:space:]]+v?[0-9]' \
    || err "'origen: $ORIGEN' nombra una base sin version. §1 exige la version, o 'desde cero'"
fi

# MAQUETA · se exige presente y sin marcador, y NO se comprueba que responda.
# Medido el 2026-09-27 sobre WorldWeaver: la ruta vive en el paquete adoptado
# (`alma-ui-laravel/routes/maqueta.php`) y la guarda de entorno esta en el provider,
# no dentro de la ruta. El `grep` que `anexos/laravel.md` prescribia daba rojo sobre
# una implementacion CORRECTA, y un chequeo que falla sobre codigo bueno es el que
# alguien desactiva. Queda declarativo, con su condicion de salida [D-C41]: se
# comprobara cuando exista una forma que distinga una maqueta propia de una que
# aporta la base, sin grepear `vendor/`.
MAQUETA="$(campo maqueta "$PROY")"
[ -z "$MAQUETA" ] && err "'$PROY' declara interfaz y no declara 'maqueta:' (ruta de desarrollo generada desde el catalogo)"

[ $fallos -gt 0 ] && { echo "catalogo: $fallos FALLA(S)"; exit 1; }

for d in $DIRS_COMP; do
  [ -d "$d" ] || err "raiz de componentes declarada que no existe: $d"
done
[ -f "$ARCH_CAT" ] || err "el archivo de catalogo no existe: $ARCH_CAT"
[ -f "$ARCH_TOK" ] || err "el archivo de tokens no existe: $ARCH_TOK"
if [ -n "$ARCH_TOK_BASE" ]; then
  [ -f "$ARCH_TOK_BASE" ] || err "tokens-base declarado que no existe: $ARCH_TOK_BASE"
fi
[ $fallos -gt 0 ] && { echo "catalogo: $fallos FALLA(S)"; exit 1; }

# --- 0b · raices conocidas del anexo no declaradas ---------------------------
# `Estado del proyecto` se calcula AQUI y no mas abajo: desde la ronda del 2026-09-23 la
# severidad del anexo sin raices depende de el. Se calcula una vez y la comprobacion 3 lo
# reutiliza. La ausencia se lee `en convergencia` [D-C45]: no declararse es no reclamar
# nada, y conformidad es lo que se reclama.
EST_PROY="$(sed -n 's/.*Estado del proyecto:[^`]*`\([a-z ]*\)`.*/\1/p' "$ARCH_CAT" | head -1)"
[ -z "$EST_PROY" ] && EST_PROY="en convergencia"

for r in $raices_conocidas; do
  if [ -d "$r" ]; then
    echo " $DIRS_COMP " | grep -q " $r " \
      || err "el anexo '$ANEXO' declara la raiz '$r', existe en el arbol y no esta en 'componentes:'"
  fi
done

# D-C41/D-C45 · un anexo sin raices deja 'componentes:' sin contraparte, y esa es una
# lista que escribe quien se beneficia de que sea corta (diseno.md §3). ENTRAR asi es
# legitimo —el anexo se deriva de la primera mision real del stack, no se inventa antes,
# y exigirlo por delante seria el error que D-C45 corrigio en el piso de diez roles—.
# RECLAMAR CONFORMIDAD asi, no: es un estado que exime sin condicion de salida
# comprobable [D-C41]. Misma maquina que el piso de roles: aviso mientras el catalogo
# este `en convergencia`, FALLA cuando se declare `conforme`.
if [ -z "$raices_conocidas" ] && [ "$EST_PROY" = "conforme" ]; then
  err "'conforme' declarado y el anexo '$ANEXO' no declara 'raices-componentes':"
  err "       nada comprueba si 'componentes:' omite una raiz. Llenar el anexo primero."
fi

# --- entradas del catalogo --------------------------------------------------
ids="$(grep -E '^## ' "$ARCH_CAT" | sed 's/^##[[:space:]]*//')"
[ -z "$ids" ] && err "el catalogo no tiene ninguna entrada"
bloque() { awk -v id="## $1" '$0==id{f=1;next} /^## /{f=0} f' "$ARCH_CAT"; }
val_de() { bloque "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1; }

# --- 1 · INDICE INVERSO · todo archivo bajo una raiz tiene ficha (D-C40) -----
fichados="$(for id in $ids; do val_de "$id" archivo; done | sed 's#^\./##' | sort -u)"
for d in $DIRS_COMP; do
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    f="${f#./}"
    printf '%s\n' "$fichados" | grep -qx "$f" \
      || err "sin ficha en el catalogo: $f"
  done <<EOF
$(find "$d" -type f -not -name '.*' 2>/dev/null)
EOF
done

# --- 4 · ficha completa ------------------------------------------------------
for id in $ids; do
  for c in rol estado no-usar-cuando excepciones archivo; do
    [ -z "$(val_de "$id" "$c")" ] && err "entrada '$id': falta el campo '$c'"
  done
  a="$(val_de "$id" archivo)"
  [ -n "$a" ] && [ ! -f "$a" ] && err "entrada '$id': el archivo declarado no existe ($a)"
done

# --- 2 · un solo vigente por rol --------------------------------------------
dups="$(for id in $ids; do
          [ "$(val_de "$id" estado)" = "vigente" ] && val_de "$id" rol
        done | sort | uniq -d)"
for r in $dups; do err "dos o mas entradas 'vigente' para el rol '$r'"; done

# --- 3 · cobertura de roles canonicos ---------------------------------------
# D-C45 · el piso de diez roles es condicion de SALIDA de `en convergencia`, no
# puerta de entrada. Exigirlo desde el primer commit obligaba a inventar componentes
# que el producto no usa, y era el punto donde un proyecto con historia abandonaba.
# La ausencia de 'Estado del proyecto' se lee como `en convergencia`: no declararse
# es no reclamar nada, y conformidad es lo que se reclama.
# EST_PROY se calcula junto a la comprobacion 0b, que desde 2026-09-23 tambien depende
# de el. Una sola lectura, dos consumidores.
DIS="$RAIZ_ESTANDAR/.agents/rules/diseno.md"
[ -f "$DIS" ] || DIS="$raiz_repo/.agents/rules/diseno.md"
faltan=0
if [ -f "$DIS" ]; then
  for r in $(bloque_anexo 'roles-canonicos' "$DIS"); do
    hay=0
    for id in $ids; do
      [ "$(val_de "$id" rol)" = "$r" ] && [ "$(val_de "$id" estado)" = "vigente" ] && hay=1
    done
    if [ $hay -eq 0 ]; then
      faltan=$((faltan+1))
      if [ "$EST_PROY" = "conforme" ]; then
        err "'conforme' declarado y el rol canonico '$r' no tiene entrada vigente"
      fi
    fi
  done
  [ $faltan -gt 0 ] && [ "$EST_PROY" != "conforme" ] \
    && aviso "convergencia: faltan $faltan rol(es) canonico(s) para poder declararse conforme"
else
  aviso "no se encontro diseno.md: no se pudo comprobar la cobertura de roles"
fi

# --- 5 · integridad de 'superado por' y deuda -------------------------------
superadas=0
for id in $ids; do
  e="$(val_de "$id" estado)"
  case "$e" in
    "superado por "*)
      superadas=$((superadas+1))
      destino="${e#superado por }"
      printf '%s\n' "$ids" | grep -qx "$destino" \
        || err "entrada '$id': 'superado por $destino' no existe en el catalogo"
      # D-C44 · el conteo de usos recorre el arbol: solo en modo completo.
      if [ $CON_DIFF -eq 0 ]; then
        a="$(val_de "$id" archivo)"; base="$(basename "${a%.*}")"
        usos="$(grep -rl "$base" . --exclude-dir=.git --exclude="$(basename "$ARCH_CAT")" 2>/dev/null \
                | grep -v "^\./$a$" | wc -l | tr -d ' ')"
        [ "$usos" -gt 0 ] && aviso "deuda: '$id' superada, $usos archivo(s) todavia la usan"
      fi
      ;;
    vigente|"en revision"|"en revisión") : ;;
    *) err "entrada '$id': estado invalido '$e'" ;;
  esac
done
[ "$superadas" -gt 0 ] && aviso "el proyecto esta EN CONVERGENCIA: $superadas entrada(s) superada(s)"

# --- 6 · literales de color fuera de tokens ---------------------------------
excluir_tok() {
  # Filtra lineas que pertenecen a archivos de tokens (marca y/o base).
  grep -v -F "$ARCH_TOK" | {
    if [ -n "$ARCH_TOK_BASE" ]; then grep -v -F "$ARCH_TOK_BASE"; else cat; fi
  }
}
for d in $DIRS_COMP; do
  lit="$(grep -rnE '#[0-9a-fA-F]{3,8}\b|rgba?\(' "$d" 2>/dev/null | excluir_tok | head -10)"
  if [ -n "$lit" ]; then
    err "valores de color literales fuera de los tokens en '$d':"
    printf '%s\n' "$lit" | sed 's/^/           /'
  fi
done

# --- 6b/6c/6d · tipografia y espaciado fuera de tokens (E.1) ---------------
# Quita var(...) no anidados para no acusar fallbacks ni calc dentro del token.
sin_var() { sed -E 's/var\([^)]*\)/var()/g'; }

for d in $DIRS_COMP; do
  # 6b · numero+unidad fuera de var(). Exentos: 0 desnudo (no matchea) y %.
  lit6b="$(grep -rnE '[0-9]+(\.[0-9]+)?(px|rem|em|ch|vh|vw|pt)\b' "$d" 2>/dev/null \
          | excluir_tok | while IFS= read -r linea; do
              cuerpo="${linea#*:}"
              cuerpo="${cuerpo#*:}"
              limpio="$(printf '%s\n' "$cuerpo" | sin_var)"
              printf '%s\n' "$limpio" | grep -qE '[0-9]+(\.[0-9]+)?(px|rem|em|ch|vh|vw|pt)\b' \
                && printf '%s\n' "$linea"
            done | head -10)"
  if [ -n "$lit6b" ]; then
    err "6b · numero+unidad fuera de var() en '$d':"
    printf '%s\n' "$lit6b" | sed 's/^/           /'
  fi

  # 6c · font-*/line-height/letter-spacing cuyo valor no es solo var(...)
  lit6c="$(grep -rnE '\b(font-[a-z-]+|line-height|letter-spacing)[[:space:]]*:' "$d" 2>/dev/null \
          | excluir_tok | while IFS= read -r linea; do
              val="$(printf '%s\n' "$linea" \
                    | sed -E 's/.*\b(font-[a-z-]+|line-height|letter-spacing)[[:space:]]*:[[:space:]]*//' \
                    | sed 's/[[:space:]]*!important//' | sed 's/[;"].*//' | sed 's/[[:space:]]*$//')"
              case "$val" in
                var\(*\)) continue ;;
                0|0%|[0-9]*%) continue ;;
                *) printf '%s\n' "$linea" ;;
              esac
            done | head -10)"
  if [ -n "$lit6c" ]; then
    err "6c · tipografia con valor no-var() en '$d':"
    printf '%s\n' "$lit6c" | sed 's/^/           /'
  fi

  # 6d · unidad pegada a interpolacion Blade: }}rem
  lit6d="$(grep -rnE '\}\}(px|rem|em|ch|vh|vw|pt)\b' "$d" 2>/dev/null | excluir_tok | head -10)"
  if [ -n "$lit6d" ]; then
    err "6d · unidad pegada a interpolacion Blade en '$d':"
    printf '%s\n' "$lit6d" | sed 's/^/           /'
  fi
done

# Union de archivos de tokens (base + marca). Marca gana en resolución de color.
ARCHIVOS_TOK="$ARCH_TOK"
[ -n "$ARCH_TOK_BASE" ] && ARCHIVOS_TOK="$ARCH_TOK_BASE $ARCH_TOK"

# --- 10 · tokens-base: toda propiedad de tokens: debe existir en la base (E.3) -
if [ -n "$ARCH_TOK_BASE" ]; then
  props_en() { grep -oE -- '--alma-[a-z0-9-]+[[:space:]]*:' "$1" 2>/dev/null | sed 's/[[:space:]]*://' | sort -u; }
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    grep -qE -- "${p}[[:space:]]*:" "$ARCH_TOK_BASE" \
      || err "tokens-base: '$p' esta en '$ARCH_TOK' y no existe en '$ARCH_TOK_BASE'"
  done <<EOF
$(props_en "$ARCH_TOK")
EOF
fi

# --- 9 · roles de token (E.2) · misma maquina que D-C45 ---------------------
faltan_tok=0
if [ -f "$DIS" ]; then
  union_tmp="$(mktemp)"
  # shellcheck disable=SC2086
  cat $ARCHIVOS_TOK >"$union_tmp" 2>/dev/null || true
  for r in $(bloque_anexo 'roles-tokens' "$DIS"); do
    if ! grep -qE -- "--alma-${r}[[:space:]]*:" "$union_tmp"; then
      faltan_tok=$((faltan_tok+1))
      if [ "$EST_PROY" = "conforme" ]; then
        err "'conforme' declarado y falta el rol de token '--alma-$r'"
      fi
    fi
  done
  rm -f "$union_tmp"
  [ $faltan_tok -gt 0 ] && [ "$EST_PROY" != "conforme" ] \
    && aviso "convergencia: faltan $faltan_tok rol(es) de token para poder declararse conforme"
else
  aviso "no se encontro diseno.md: no se pudo comprobar roles de token"
fi

# --- 11 · contraste por pares de rol, ambos temas (E.4) ---------------------
# Extrae --alma-*:valor de un archivo para un tema (light|dark) a un mapa.
mapa_tema() {
  # $1 archivo $2 light|dark $3 destino
  awk -v tema="$2" '
    BEGIN { t="light"; depth=0; en_dark=0 }
    /@media[[:space:]]*\([[:space:]]*prefers-color-scheme:[[:space:]]*dark/ {
      en_dark=1; dark_depth=0; next
    }
    {
      line=$0
      if (en_dark) {
        for (i=1;i<=length(line);i++) {
          c=substr(line,i,1)
          if (c=="{") dark_depth++
          if (c=="}") {
            dark_depth--
            if (dark_depth<=0) { en_dark=0 }
          }
        }
        cur="dark"
      } else {
        cur="light"
      }
      if (cur!=tema) next
      while (match(line, /--alma-[a-z0-9-]+[[:space:]]*:[[:space:]]*[^;]+/)) {
        decl=substr(line, RSTART, RLENGTH)
        sub(/[[:space:]]*:[[:space:]]*/, "=", decl)
        print decl
        line=substr(line, RSTART+RLENGTH)
      }
    }
  ' "$1" >>"$3"
}

contraste_awk='
function hexval(h,   i,c,v,n) {
  n = 0
  for (i=1; i<=length(h); i++) {
    c = tolower(substr(h,i,1))
    v = index("0123456789abcdef", c) - 1
    if (v < 0) return -1
    n = n * 16 + v
  }
  return n
}
function parsehex(s,   h) {
  sub(/^#/, "", s)
  h = tolower(s)
  if (length(h)==3) {
    R = hexval(substr(h,1,1) substr(h,1,1))
    G = hexval(substr(h,2,1) substr(h,2,1))
    B = hexval(substr(h,3,1) substr(h,3,1))
  } else if (length(h)==6 || length(h)==8) {
    R = hexval(substr(h,1,2)); G = hexval(substr(h,3,2)); B = hexval(substr(h,5,2))
  } else return 0
  if (R<0 || G<0 || B<0) return 0
  return 1
}
function lin(c,   s) {
  s = c/255
  return (s <= 0.03928) ? s/12.92 : ((s+0.055)/1.055)^2.4
}
function rel() {
  return 0.2126*lin(R) + 0.7152*lin(G) + 0.0722*lin(B)
}
function ratio(c1, c2,   L1,L2,t) {
  if (!parsehex(c1)) return -1
  L1 = rel()
  if (!parsehex(c2)) return -1
  L2 = rel()
  if (L1 < L2) { t=L1; L1=L2; L2=t }
  return (L1+0.05)/(L2+0.05)
}
BEGIN {
  while ((getline < mapa) > 0) {
    split($0, a, "=")
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[1])
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", a[2])
    m[a[1]] = a[2]
  }
  close(mapa)
}
function resolve(name,   v,n,guard) {
  v = m["--alma-" name]
  if (v=="") return ""
  guard=0
  while (guard++ < 12) {
    if (v ~ /^#/) return v
    if (v ~ /^var\(--alma-/) {
      n = v
      sub(/^var\(--alma-/, "", n)
      sub(/[^a-z0-9-].*$/, "", n)
      if (!(("--alma-" n) in m)) return ""
      v = m["--alma-" n]
      continue
    }
    return ""
  }
  return ""
}
{
  fg=$1; bg=$2; minr=$3+0; label=$4
  c1=resolve(fg); c2=resolve(bg)
  if (c1=="" || c2=="") { print "AVISO\t" label "\t" fg "/" bg; next }
  r=ratio(c1,c2)
  if (r < 0) { print "AVISO\t" label "\t" fg "/" bg; next }
  if (r+0 < minr) printf "FALLA\t%s\t%.2f < %.1f (%s sobre %s)\n", label, r, minr, c1, c2
  else printf "OK\t%s\t%.2f\n", label, r
}
'

medir_contraste_tema() {
  # $1 etiqueta tema  $2 archivo mapa
  local mapa="$2" tema_lbl="$1"
  local pares out
  out="$(mktemp)"
  pares=""
  for fg in color-texto color-texto-secundario color-peligro color-accion; do
    pares="${pares}${fg} color-fondo 4.5 ${tema_lbl}/${fg}-fondo
${fg} color-superficie 4.5 ${tema_lbl}/${fg}-superficie
"
  done
  if grep -q '^--alma-color-acento=' "$mapa" 2>/dev/null; then
    pares="${pares}color-acento color-fondo 4.5 ${tema_lbl}/acento-fondo
color-acento color-superficie 4.5 ${tema_lbl}/acento-superficie
"
  fi
  pares="${pares}color-sobre-accion color-accion 4.5 ${tema_lbl}/sobre-accion
color-borde-control color-fondo 3.0 ${tema_lbl}/borde-control-fondo
color-borde-control color-superficie 3.0 ${tema_lbl}/borde-control-superficie
"
  printf '%s' "$pares" | awk -v mapa="$mapa" "$contraste_awk" >"$out"
  while IFS=$'\t' read -r tipo resto; do
    [ -z "${tipo:-}" ] && continue
    case "$tipo" in
      FALLA) err "contraste $resto" ;;
      AVISO) aviso "contraste no resoluble: $resto" ;;
    esac
  done <"$out"
  rm -f "$out"
}

mapa_light="$(mktemp)"; mapa_dark="$(mktemp)"
: >"$mapa_light"; : >"$mapa_dark"
for f in $ARCHIVOS_TOK; do
  mapa_tema "$f" light "$mapa_light"
  mapa_tema "$f" dark  "$mapa_dark"
done
# Ultima definicion gana (marca despues de base): recompactar
compactar_mapa() {
  awk -F= '{ m[$1]=$2 } END { for (k in m) print k"="m[k] }' "$1" >"$1.compact" && mv "$1.compact" "$1"
}
compactar_mapa "$mapa_light"
compactar_mapa "$mapa_dark"
medir_contraste_tema "light" "$mapa_light"
# Solo mide dark si el mapa dark tiene algun color
if grep -q '^--alma-color-' "$mapa_dark" 2>/dev/null; then
  medir_contraste_tema "dark" "$mapa_dark"
fi
rm -f "$mapa_light" "$mapa_dark"

# --- 12 · outline: none|0 sin :focus-visible en el mismo archivo (E.4) ------
archivos_foco="$DIRS_COMP $ARCH_TOK"
[ -n "$ARCH_TOK_BASE" ] && archivos_foco="$archivos_foco $ARCH_TOK_BASE"
for ruta in $archivos_foco; do
  if [ -d "$ruta" ]; then
    lista="$(find "$ruta" -type f 2>/dev/null)"
  elif [ -f "$ruta" ]; then
    lista="$ruta"
  else
    continue
  fi
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if grep -qE 'outline[[:space:]]*:[[:space:]]*(none|0)\b' "$f" 2>/dev/null; then
      grep -q ':focus-visible' "$f" 2>/dev/null \
        || err "outline: none|0 sin :focus-visible en el mismo archivo: $f"
    fi
  done <<EOF
$lista
EOF
done

if [ $fallos -eq 0 ]; then
  echo "catalogo: sin fallas${avisos:+ ($avisos aviso/s)}"; exit 0
fi
echo "catalogo: $fallos FALLA(S)"
exit 1
