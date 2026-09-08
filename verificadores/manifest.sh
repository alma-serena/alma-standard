#!/usr/bin/env bash
# Genera el manifest de integridad del estandar y lo escribe a stdout.
#
# D-C48 · NI EL AGENTE LO ESCRIBE, NI VIVE EN EL ARBOL. Lo produce el job `manifest`
# al publicarse un tag, y se adjunta al release. La razon esta en ALMA-UPGRADE.md y
# es la misma que sostiene OPS-07 nivel 2: un checksum calculado por quien puede
# editar los archivos no verifica nada. Un proyecto NO lo regenera — lo descarga.
#
# Formato: `sha256sum` estandar, para que cualquier maquina lo verifique con
# `sha256sum -c` sin herramientas propias.
set -eu
cd "$(dirname "$0")/.."

# Fuente unica de que es verbatim: el bloque del paso 1 de INSTALACION.md.
rutas="$(awk '/verbatim:inicio/{f=1;next} /verbatim:fin/{f=0} f' INSTALACION.md \
        | grep -v '^```' | tr -d ' \t' | grep -v '^$' || true)"

if [ -z "$rutas" ]; then
  echo "manifest: el bloque verbatim de INSTALACION.md esta vacio o no existe" >&2
  exit 1
fi

for r in $rutas; do
  if [ ! -e "${r%/}" ]; then
    echo "manifest: la ruta declarada '$r' no existe en el arbol" >&2
    exit 1
  fi
done

# Solo lo versionado: lo que no esta en git no viaja, y por tanto no se cubre.
# shellcheck disable=SC2086
archivos="$(git ls-files -- $rutas | LC_ALL=C sort)"

if [ -z "$archivos" ]; then
  echo "manifest: las rutas declaradas no contienen archivos versionados" >&2
  exit 1
fi

printf '%s\n' "$archivos" | while IFS= read -r f; do
  sha256sum "$f"
done
