# REQ-V49 — la base de interfaz se consume anclada

| Campo | Valor |
|---|---|
| **ID** | REQ-V49 |
| **Descripción** | En un proyecto con `interfaz: si` que adopta una base, el verificador exige `origen: <paquete> vX.Y.Z · <sha40>`, comprueba que el lockfile y lo instalado en `vendor/` correspondan a ese commit inmutable por fuente `git` (nunca `path`), y soporta los dos modos de tema (`@media (prefers-color-scheme: dark)` y `[data-tema="claro"]`) sobre la unión base+marca. |
| **Módulo** | alma-standard / verificadores/catalogo.sh · rules/diseno.md · rules/anexos/laravel.md · ALMA-UPGRADE.md · verificadores-estandar/casos.sh |
| **Estado** | abierto |
| **Origen** | Decisión de Nico del 2026-11-25 (21:19), dudas 1a, 2a y 3a del paquete «ancla de la base». Hecho medido en MIS-1165: consola y WorldWeaver instalaban `alma/ui-laravel` por Composer `path` y servían la rama viva del árbol de trabajo sin merge ni adopción. |

## Fricción

Con repositorios `path`, Composer ignora el `reference` del lockfile y sirve cualquier
cambio sin merge de la carpeta local de la base; con rangos `^0.2`, un `composer update`
general sube la base sin misión; y `test -L` no es fiable con junctions de Windows.

## Criterio verificable

1. **7:** con base, `origen:` sin etiqueta `vX.Y.Z` y SHA40 → falla; `tokens-base:` bajo
   `vendor/` con `origen: desde cero` → falla. Casos en `verificadores-estandar/casos.sh`.
2. **13:** en `composer.lock`, `source.type = git`, sin `dist.type = path`, `version` =
   etiqueta de `origen:` y `source.reference` = SHA de `origen:`. Anexo sin lockfile →
   aviso en convergencia, falla en `conforme`. Casos.
3. **14:** vendor/composer/installed.json con `installation-source = source`,
   `source.type = git` y `reference` = lock. Sin `vendor/` → aviso con nombre. Casos.
4. **15:** repositorio de tipo `path` en `composer.json` → falla con «cambia a vcs». Caso.
5. **11:** contraste medido en ambos temas para modo (a) `@media (prefers-color-scheme: dark)`
   y modo (b) `:root` atenuado + `[data-tema="claro"]`, decidido sobre la unión base+marca. Casos.
6. `.agents/rules/diseno.md` no nombra ninguna base concreta y lista en §9 lo que ninguna
   máquina comprueba (etiqueta publicada sobre `main` y coincidencia con lo servido).
