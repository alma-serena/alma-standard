# INSTALACION.md — poner el estándar a funcionar en un proyecto

**Este archivo no viene de ALMA Dev v0.2.1** `[V-5]`. El documento maestro describe
qué es el estándar y qué obliga, y nunca describió cómo se instala. Seis hallazgos
de dos evaluadores independientes chocaron con ese hueco desde ángulos distintos: el
lector que abre `AGENTS.md` y no sabe de dónde sale el archivo que le mandan leer, y
el rol de CI que descubre que el hook de prevención está presente y **no corre**.

Se lee **una vez, al empezar**. No es material de misión.

## Antes de empezar: en qué estado está el estándar

`v0.1.0` está **sin publicar**: no hay repositorio remoto ni primer tag, y por tanto
**no hay manifest de checksums**. Dos consecuencias concretas, y conviene tenerlas
delante durante toda la instalación:

- La copia del paso 1 se hace **a mano**. `alma:upgrade` es el mecanismo previsto
  (`ALMA-UPGRADE.md`) y necesita el tag remoto para funcionar; hoy no existe.
- La comprobación de integridad del hook **avisa y no falla**: sin
  `.alma/manifest.sha256` no puede comparar nada. Que un archivo verbatim se edite
  localmente no lo detecta nadie hasta que exista el tag.

Nada de esto se disimula en el resto del documento. Cuando un paso no puede
verificarse todavía, lo dice.

## Los seis pasos

### 1 · Copiar el estándar verbatim

Al raíz del proyecto: `AGENTS.md`, `CLAUDE.md`, `METODOLOGIA.md`, `.agents/`,
`.githooks/`, `.github/workflows/`, `verificadores/`.

> **Si el proyecto ya tiene `AGENTS.md` o `CLAUDE.md`, se respaldan antes de copiar:**
> `AGENTS.md.previo`, `CLAUDE.md.previo`. La versión anterior de este paso copiaba
> encima, y en el primer recorrido real **sobrescribió las guías del proyecto sin
> avisar** — el conocimiento local del agente se perdía en silencio. Lo que valga de
> ese archivo se mueve a `proyecto-<nombre>.md`, que es el único sitio editable.

**Verbatim quiere decir verbatim.** Si algo de tu proyecto no encaja, no se edita el
estándar: se declara una excepción en `proyecto-<nombre>.md` con el formato de cuatro
partes (qué · por qué · qué lo compensa · cuándo se revisa). Editar un archivo
copiado produce exactamente la divergencia que SAD-05 existe para impedir, y el día
que haya manifest hará fallar el nivel 1 en cada commit.

`INSTALACION.md` y `plantillas/` **no** se copian: son material del estándar, no del
proyecto.

> **Sobre `verificadores/`:** `verificadores/catalogo.sh` y `verificadores/secretos.sh` verifican **tu** proyecto y
> por eso viajan. `verificadores/coherencia.sh` verifica el árbol del **estándar** —exige su
> `CHANGELOG.md`, sus referencias internas, su manifest— y **no es parte de tu DoD**: en
> un proyecto copiado va a fallar, y ese fallo no significa nada sobre tu instalación.

### 2 · Comprobar el puente `CLAUDE.md`

`CLAUDE.md` contiene un `@AGENTS.md` — un import, no un symlink. Existe porque Claude
Code no lee `AGENTS.md` por su cuenta y su modo de falla es cargar **cero
instrucciones en silencio, sin error**: inaceptable bajo SAD-07.

Cursor, Windsurf y Cline leen `AGENTS.md` nativamente y no necesitan el puente; el
archivo sobra sin estorbar. Antigravity: verificar en la instalación.

Si al copiar se convirtió en una copia del contenido en vez de un import, está roto.
El hook lo comprueba — cuando el hook corre, que es el paso siguiente.

### 3 · Activar el hook

**Si el proyecto todavía no es un repositorio git, lo es ahora:** `git config` responde
`fatal: not in a git directory` y sin repo no hay hook, ni commit, ni cierre. El
estándar no lo daba por dicho y había que inventarlo.

```
git init      # solo si aún no hay repositorio
git config core.hooksPath .githooks
```

**Sin este comando, `.githooks/pre-commit` no se ejecuta nunca.** Git solo corre
`.git/hooks/*` por defecto; un archivo dentro de `.githooks/` no se activa por estar
ahí. Tras un clon el nivel 1 de OPS-07 **no atrapa nada**: ni secretos, ni el puente
roto, ni el modo de misión ausente, ni la edición de un archivo verbatim.

> **Este es el paso que más fácil se salta y peor falla al saltarse.** No produce
> error: produce un proyecto donde el archivo del hook está presente, se ve en el
> árbol, y no hace nada. Comprobarlo es el primer ítem de la lista de más abajo.

Comprobación: `git config --get core.hooksPath` debe devolver `.githooks`. Si
devuelve vacío, el paso no está hecho.

### 4 · Crear `proyecto-<nombre>.md`

Se copia de `plantillas/proyecto-EJEMPLO.md` y se rellena. Es el **único archivo
editable** de la capa de proyecto (OPS-05): extiende el estándar, nunca lo
contradice, y quedan fuera de su alcance `.agents/rules/seguridad.md` y cualquier
reducción de la DoD.

**El inventario de secciones es la plantilla, y solo la plantilla.** Aquí no se repite:
un recuento en dos sitios se desincroniza, y el que se quedó corto fue este archivo —
omitía `interfaz:`, cuya ausencia hace fallar el primer commit. Rellena la plantilla
entera.

Dos advertencias sobre campos concretos, que no son inventario sino consecuencia:

- **Comandos ejecutables** — de ahí salen los comandos de cierre de toda misión. Deben
  funcionar copiados y pegados.
- **`interfaz: si|no`** — su ausencia **falla** en cada commit. No se interpreta el
  silencio.

**Sin este archivo el proyecto está en modo génesis** — legítimo y declarado, no un
error: el agente propone la estructura desde el estándar y el REQ se genera retroactivo
en el cierre.

> **Y tiene condición de salida, comprobable** `[D-C41]`. Génesis describe un árbol
> vacío. **En cuanto hay código de producto, `genesis` falla**: no es un «debería
> existir», es el modo que deja de ser válido. La versión anterior de este párrafo decía
> «debería», y «debería» no falla — quedarse sin `proyecto-<nombre>.md` eximía de
> identidad, stack, comandos, catálogo, rutas secretas y frontera de modo, todo a la vez.

### 5 · Declarar el modo de misión

```
mkdir -p .alma && echo "aplicacion" > .alma/modo-mision
```

Valores válidos, y solo estos cuatro: `aplicacion` · `paquete` · `genesis` ·
`estandar`. El hook los lee para tener una frontera contra la cual comparar el diff,
y **su ausencia o un valor inválido hacen fallar el commit** — no avisa: falla.

Se reescribe al abrir cada misión, no una sola vez en la instalación.

### 6 · Decidir dónde vive el REQ

`METODOLOGIA.md` deja la forma del REQ a la capa de proyecto: modelo con su
migración, o markdown. Ambas son legítimas y la elección es real.

**Punto de partida para un proyecto nuevo:** una carpeta `docs/req/` con un archivo
markdown por REQ. No exige base de datos, es diffeable, y viaja con el repositorio —
que es lo que hace falta para que el cierre pueda citarlo. Cuando el proyecto tenga
razones para moverlo a la base de datos, la decisión se declara en
`proyecto-<nombre>.md` y este párrafo deja de aplicar.

## Comprobación de la instalación

Se corre a mano, en el raíz del proyecto:

| Comprobar | Comando | Esperado |
|---|---|---|
| hook activo | `git config --get core.hooksPath` | `.githooks` |
| puente | `head -1 CLAUDE.md` | `@AGENTS.md` |
| capa de proyecto | `ls proyecto-*.md` | un archivo, o modo génesis declarado |
| modo de misión | `cat .alma/modo-mision` | uno de los cuatro valores |
| catálogo | `bash verificadores/catalogo.sh` | `sin fallas` — **crea antes el archivo de catálogo que declaraste en `catalogo:`, desde `plantillas/catalogo-EJEMPLO.md`**, o el paso 4 no está terminado |
| secretos | `bash verificadores/secretos.sh` | `sin fallas` |

## Lo que esta instalación NO garantiza

Escrito aquí para que nadie confunda «instalado» con «certificado»:

- **Nada de esta lista se comprueba solo.** No hay verificador de instalación: si el
  paso 3 se salta, el proyecto queda con el nivel 1 apagado y nada lo dice. Es un
  *fail-open* conocido y declarado, no un descuido de redacción `[D-C26]`.
- **El nivel 1 no certifica**, ni siquiera bien instalado. Lo dice el propio hook en
  su cabecera: atrapa el descuido; quien quiera evadirlo puede, y `--no-verify`
  existe. La certificación es el nivel 2 y vive fuera del repositorio.
- **Sin manifest no hay integridad verificable** de los archivos verbatim, hasta que
  exista el primer tag.
- **Y el CI no cubre el paso 3 mientras la plataforma no esté configurada.** El job
  `certificacion` corre sobre `push` a `main`: cuando barre, un secreto empujado **ya
  está en la rama**. La compensación real son los tres pasos de
  `RAIZ-DE-CONFIANZA.md` —remoto, `certificacion` como comprobación requerida, y push
  directo a `main` prohibido—. Hasta que estén, **saltarse el paso 3 cuesta seguridad,
  no velocidad**.

## Qué cambia cuando exista el primer tag

El paso 1 deja de hacerse a mano y pasa a ser `alma:upgrade`, que copia desde el tag
remoto y regenera `.alma/manifest.sha256`. A partir de ahí la comprobación de
integridad del hook tiene contra qué comparar, y `proyecto-<nombre>.md` puede anclar
una versión real en su sección **Ancla de versión** en lugar de `v0.0.0`.

El contrato de ese comando está en `ALMA-UPGRADE.md`.
