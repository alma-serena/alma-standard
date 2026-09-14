# proyecto-estandar.md

> Único archivo editable de la capa de proyecto (OPS-05). El estándar es su propio
> primer consumidor: se somete a la misma DoD de nivel 2 que impone a los demás.

## Ancla de versión

Este repositorio **es** el estándar. No ancla a un tag externo.

## Identidad

`alma-standard` es la metodología ALMA Dev hecha andamiaje verificable. Su producto
son documentos normativos y los verificadores que los comprueban.

## Stack

No hay lenguaje ni framework: `bash` + coreutils, sin dependencias.

## Comandos ejecutables

```
setup:  git config core.hooksPath .githooks
correr: no aplica
tests:  bash verificadores-estandar/coherencia.sh
lint:   no existe
```

## Catálogo de interfaz

```
andamiaje: AGENTS.md, CLAUDE.md, METODOLOGIA.md, INSTALACION.md, CHANGELOG.md, ALMA-UPGRADE.md, RAIZ-DE-CONFIANZA.md, .agents/, .github/, .githooks/, verificadores/, verificadores-estandar/, plantillas/, .alma/, .gitattributes, proyecto-*.md
anexo: ninguno
interfaz: no
```

## Perímetro

```
rutas_secretas: .env
herramientas: git
```

## Excepciones declaradas

- ninguna

## Notas de dominio

**`verificadores-estandar/` no viaja, y esa es toda su razón de ser.** El bloque
`verbatim` del paso 1 de `INSTALACION.md` enumera `verificadores/`; este directorio
es hermano, no hijo, y `git ls-files -- verificadores` no alcanza al hermano —
como subdirectorio sí lo arrastraba. La pertenencia se deriva de dónde vive el
archivo, no de que alguien lo recuerde `[D-C46]`.
