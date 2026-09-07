# migracion-estandar — el estándar subió de versión

Sin este workflow, propagar el estándar a mano produce exactamente la divergencia que
SAD-05 prohíbe. La migración es una misión, con su REQ y su cierre.

## Orden

1. **Anclar la versión nueva** al tag remoto firmado. No a una copia local: un
   checksum contra sí mismo no verifica nada.
2. **Diff contra la versión anclada** en la capa de proyecto. Qué cambió de verdad
   entre la que se tiene y la que se adopta.
3. **Reemplazar los archivos verbatim.** Todos. No se elige cuáles.
4. **Validar la capa de proyecto** contra la versión nueva: ¿alguna regla nueva
   contradice algo declarado en `proyecto-<nombre>.md`?
5. **Revisar las excepciones declaradas.** Cada una vuelve a justificarse o cae. Una
   excepción que nadie revisa deja de ser excepción y pasa a ser costumbre.
6. **Regenerar el manifest de checksums** desde el tag remoto.
7. **Actualizar el ancla de versión** en `proyecto-<nombre>.md` y cerrar la misión.

Este orden es la **fuente única**: `ALMA-UPGRADE.md` especifica el comando que lo
ejecuta y no vuelve a enunciarlo.

## Qué falla el cierre

- Un archivo verbatim modificado localmente.
- Una excepción sin revisar.
- El manifest regenerado desde una copia local en vez del tag remoto.
