# REQ-V43 — setup PHP si hay composer.json (MIS-014)

| Campo | Valor |
|---|---|
| **ID** | REQ-V43 |
| **Descripción** | El anexo de runtime en `certificacion` también se enciende si existe `composer.json` con `require.php`, sin recortar el piso ni la DoD. Cache de `vendor/`. |
| **Módulo** | alma-standard / certificacion |
| **Estado** | en curso |
| **Origen** | copiloto-microempresas: `certificacion` rojo en `main` (DoD `php artisan test` sin vendor/). Lista 2 · A14. |

## Fricción

Copiloto (v0.1.5) no declara `php:` y su workflow copiado no trae el anexo V-40. La DoD muere en `vendor/autoload.php`. Un repo con `composer.json` debería instalar el runtime sin un campo extra.

## Criterio verificable

1. Sin `php:` y sin `composer.json` → el anexo no corre (repos de otro stack, igual que antes).
2. Sin `php:` y con `composer.json` / `require.php` `^8.3` → `activar=si`, `version=8.3`.
3. `php: 8.4` gana si también hay `composer.json`.
4. El workflow cachea `vendor/` y corre `composer install --no-interaction --prefer-dist`.
5. `bash verificadores-estandar/casos-anexo-php.sh` sin fallas.
