# REQ-V40 — anexo Laravel en CI, corpus de secretos, URLs de sesión

| Campo | Valor |
|---|---|
| **ID** | REQ-V40 |
| **Descripción** | alma-standard publica v0.1.9: el workflow distribuido instala PHP y Composer cuando el proyecto declara `php:`; `verificadores/secretos.sh` deja de barrer archivos ignorados; los trailers de agente quedan permitidos y las URLs de sesión de agente, prohibidas con verificador. |
| **Módulo** | alma-standard / certificacion / verificadores |
| **Estado** | en curso |
| **Origen** | primer run de `certificacion` en copihuelpe (40210232087, `main` @ `362f213`) y hallazgos I-01-H1 / I-01-H4 de MIS-022 |

## Fricción

El workflow verbatim no instala PHP ni Composer ni declara `COMPOSER_AUTH`. Copihuelpe declara `tests: php artisan test` y `alma/auth` privado: la DoD muere en `vendor/autoload.php`. El piso pasa. Las 22 misiones anteriores nunca certificaron en CI.

`verificadores/secretos.sh` en modo árbol hace `grep` sobre el disco: un `.env` local ignorado pone rojo el cierre.

`AGENTS.md` exigía un único trailer; el editor inyecta otro. Nadie mira URLs de sesión.

## Criterio verificable

1. `php:` ausente → el anexo no corre. Válido (`N.N`) → corre. Inválido → FALLA.
2. `verificadores/secretos.sh` (árbol) no dispara por un `.env` ignorado; sí por un archivo rastreado o no ignorado.
3. Un mensaje con URL de sesión de agente falla; los trailers de agente pasan.
4. `bash verificadores-estandar/coherencia.sh` y los casos nuevos, sin fallas.
