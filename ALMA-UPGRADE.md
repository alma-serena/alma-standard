# `alma:upgrade` — migrar de versión del estándar

Especificación del comando. La implementación es capa de proyecto: un comando del
framework, un script, o un ejecutable — lo que el stack ofrezca. **El contrato es el
estándar; el lenguaje no.**

## Por qué existe

Sin él, propagar el estándar a mano produce exactamente la divergencia que SAD-05
prohíbe. Y sin él el manifest de checksums no se puede regenerar, que es lo que hace
verificable el nivel 1 de OPS-07.

## Contrato

```
alma:upgrade --a <version> [--dry-run]
```

### Orden

**Los siete pasos están en `.agents/workflows/migracion-estandar.md` y no se repiten
aquí.** Enunciarlos dos veces es la divergencia que SAD-05 prohíbe, aplicada al propio
estándar: dos textos normativos que dicen lo mismo terminan diciendo cosas distintas.
El comando ejecuta ese orden. Lo que sigue son las **precisiones que el comando añade**,
numeradas contra los pasos del workflow.

**Paso 1 — resolver el tag remoto.** Nunca una copia local: un checksum calculado
contra sí mismo no verifica nada. **Sin red, el comando falla**; no cae a una copia en
caché.

**Paso 4 — cómo se detecta la contradicción.** «Detectar contradicción» no es
implementable si no se dice cómo, así que se define aquí: el comando extrae de
`proyecto-<nombre>.md` los bloques de **excepción declarada** —los únicos que pueden
contradecir— y comprueba, para cada uno, si la regla que excepciona **sigue existiendo**
en la versión nueva y **con el mismo identificador**. Tres salidas:

| Situación | Qué hace |
|---|---|
| la regla excepcionada ya no existe | la excepción es huérfana → **detiene** |
| la regla existe y cambió de contenido | **detiene** y muestra el diff de esa regla |
| la regla existe igual | sigue, y la excepción pasa al paso 5 |

Fuera de eso no hay detección automática de contradicción semántica, y el comando **no
finge** tenerla: lo que no cae en la tabla es criterio humano.

**Paso 5 — forma concreta de la revisión.** Cada excepción del paso 4 se presenta con
sus cuatro campos —qué, por qué, qué lo compensa, cuándo se revisa— y **exige una
respuesta explícita**: `mantener`, `retirar` o `modificar`. Sin respuesta para todas, el
comando no llega al paso 6.

### Qué hace fallar el comando

| Condición | Por qué |
|---|---|
| Un archivo verbatim modificado localmente | hay que resolverlo antes, no arrastrarlo |
| El tag remoto no resuelve | sin ancla externa no hay migración |
| Una regla nueva contradice la capa de proyecto | decisión humana, no automática |
| Una excepción sin revisar | el paso 5 no es opcional |

### `--dry-run`

Hace 1, 2, 4 y 5 e informa. No escribe nada. Es el modo por defecto recomendado antes
de una migración real.

## El manifest

`.alma/manifest.sha256`, formato `sha256sum` estándar para que cualquier máquina lo
verifique sin herramientas propias.

- Cubre **todos** los archivos verbatim del estándar.
- **No cubre** `proyecto-<nombre>.md`: es el único editable, y por eso no puede estar.
- Se genera **solo** desde el tag remoto.

> **Orden de arranque.** El manifest no puede existir antes de que `alma-standard`
> esté publicado con su primer tag. Hasta entonces el nivel 1 corre sin comprobación
> de integridad y lo dice en voz alta — que es la conducta correcta: avisar del hueco,
> no simular la comprobación.

## Lo que `alma:upgrade` NO hace

- **No hace push.** El ancla es acto humano.
- **No resuelve contradicciones.** Las detecta y se detiene.
- **No migra la capa de proyecto.** Esa la escribe el dueño.
