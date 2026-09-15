#!/usr/bin/env bash
# DoD documental del estandar (SAD-08): no `composer test`, sino coherencia interna,
# completitud de referencias cruzadas y changelog al dia.
# Corre en el nivel 2 (CI) y tambien en local. Sin dependencias: bash + coreutils.
set -u
cd "$(dirname "$0")/.."
fallos=0
err() { echo "  FALLA · $*"; fallos=$((fallos+1)); }
ok()  { echo "  ok    · $*"; }

# Archivos de OTROS repos que el estandar cita como ejemplo. Se excluyen uno a uno y
# con nombre: aflojar la expresion regular esconderia roturas reales.
externos=" proyeccion.json log.jsonl model.py log.py composer.json package.json phpunit.xml .env "

echo "== 1 · referencias cruzadas resuelven a la RUTA citada =="
# H-CIS-4: antes se resolvia por basename, asi que una ruta rota pasaba si existia
# cualquier archivo con ese nombre en otro sitio. Ahora se resuelve la ruta real,
# relativa al archivo que la cita y a la raiz del estandar.
faltan=0
while IFS=: read -r origen ref; do
  [ -z "${ref:-}" ] && continue
  case "$ref" in
    *'<'*|proyecto-*.md) continue ;;                      # plantillas con marcador
  esac
  case "$externos" in *" $(basename "$ref") "*) continue ;; esac
  dir=$(dirname "$origen")
  if [ -e "$dir/$ref" ] || [ -e "./$ref" ]; then continue; fi
  err "referencia rota: '$ref' citada en $origen"
  faltan=$((faltan+1))
done <<< "$(grep -rnoE '`[.A-Za-z0-9_/-]+\.(md|sh|yml|json)`' --include='*.md' . \
            | sed 's/`//g' | awk -F: '{print $1":"$3}')"
[ "$faltan" -eq 0 ] && ok "todas las referencias resuelven a su ruta"

echo "== 1b · lo que viaja solo cita lo que viaja =="
# H-H12 · un archivo verbatim que cita una ruta fuera del conjunto verbatim le da al
# consumidor una instruccion imposible: el archivo citado no esta en su arbol. La
# seccion 1 no lo veia porque aqui, en el arbol del estandar, la ruta SI resuelve.
# Lo que vive solo en el repositorio del estandar se ENLAZA, no se cita por ruta.
verb="$(awk '/verbatim:inicio/{f=1;next} /verbatim:fin/{f=0} f' INSTALACION.md \
        | grep -v '^```' | tr -d ' \t' | grep -v '^$' || true)"
if [ -z "$verb" ]; then
  err "el bloque verbatim de INSTALACION.md esta vacio: no se pudo comprobar 1b"
else
  norm() { printf '%s\n' "$1" | awk -F/ '{n=0;for(i=1;i<=NF;i++){if($i==".."){if(n>0)n--}else if($i!="."&&$i!=""){a[++n]=$i}};s="";for(i=1;i<=n;i++)s=s (i>1?"/":"") a[i];print s}'; }
  viaja() { for e in $verb; do e="${e%/}"; case "$1" in "$e"|"$e"/*) return 0 ;; esac; done; return 1; }
  rotas=0
  # shellcheck disable=SC2086
  for f in $(git ls-files -- $verb | grep '\.md$'); do
    d="$(dirname "$f")"
    for r in $(grep -oE '`[.A-Za-z0-9_/-]+\.(md|sh|yml|json)`' "$f" | sed 's/`//g' | sort -u); do
      case "$r" in proyecto-*.md|*'<'*) continue ;; esac
      case "$externos" in *" $(basename "$r") "*) continue ;; esac
      res="$(norm "$d/$r")"; [ -e "$res" ] || res="$(norm "$r")"
      if ! viaja "$res"; then
        err "$f viaja y cita '$r', que NO viaja. Enlazalo en vez de citarlo por ruta"
        rotas=$((rotas+1))
      fi
    done
  done
  [ "$rotas" -eq 0 ] && ok "ningun archivo verbatim cita fuera del conjunto verbatim"
fi

echo "== 2 · el orden de lectura de AGENTS.md existe =="
for f in METODOLOGIA.md .agents/rules .agents/workflows; do
  [ -e "$f" ] && ok "$f" || err "AGENTS.md apunta a $f y no existe"
done

echo "== 3 · ningun archivo normativo cita un BORRADOR como si fuera norma =="
# H-CIS-3: antes esta seccion nunca llamaba a err — pasaba en verde hubiera o no
# coincidencias, que es exactamente el verificador nominal que el estandar prohibe.
borradores=$(grep -rl 'BORRADOR' --include='*.md' . 2>/dev/null | sed 's|^\./||' || true)
if [ -z "$borradores" ]; then
  ok "ningun borrador en el arbol"
else
  malos=0
  for b in $borradores; do
    citantes=$(grep -rl "$(basename "$b")" --include='*.md' . 2>/dev/null \
               | sed 's|^\./||' | grep -v "^$b$" | grep -v 'BORRADOR' || true)
    for c in $citantes; do
      grep -q 'BORRADOR' "$c" 2>/dev/null && continue   # borrador citando borrador: ok
      err "$c (normativo) cita a $b, que esta marcado BORRADOR"
      malos=$((malos+1))
    done
  done
  [ "$malos" -eq 0 ] && ok "$(echo "$borradores" | wc -l) borrador(es) declarado(s), ninguno citado como norma"
fi

echo "== 4 · el manifest se puede generar =="
# D-C48 · El arbol del estandar NO lleva manifest, y no es una carencia: un checksum
# calculado por quien puede editar los archivos no verifica nada (ALMA-UPGRADE.md).
# Lo produce el job `manifest` al publicarse el tag y vive como activo del release.
# Lo que si se comprueba aqui es que el generador corre y cubre algo.
if [ -f .alma/manifest.sha256 ]; then
  err ".alma/manifest.sha256 esta en el arbol. No debe estar (D-C48): el manifest se genera en el release, no se commitea"
elif [ ! -f verificadores-estandar/manifest.sh ]; then
  err "falta verificadores-estandar/manifest.sh: sin generador no hay manifest que publicar"
elif salida="$(bash verificadores-estandar/manifest.sh 2>&1)"; then
  ok "el generador corre y cubre $(printf '%s\n' "$salida" | wc -l | tr -d ' ') archivos verbatim"
else
  err "verificadores-estandar/manifest.sh fallo: $salida"
fi

echo "== 5 · CHANGELOG al dia =="
if [ -f CHANGELOG.md ]; then ok "CHANGELOG presente"
else err "falta CHANGELOG.md — SAD-08 lo exige: un cambio sin origen registrado no entra"; fi

echo
if [ "$fallos" -gt 0 ]; then echo "coherencia: $fallos FALLA(S)"; exit 1; fi
echo "coherencia: sin fallas"
