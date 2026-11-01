# REQ-V44 — alarma de push directo a main (MIS-015)

| Campo | Valor |
|---|---|
| **ID** | REQ-V44 |
| **Descripción** | Un workflow `.github/workflows/guardia-main.yml` falla y abre un issue si un push a `main` trae un commit que no viene de un PR mergeado. No bloquea el push. |
| **Módulo** | alma-standard / guardia-main |
| **Estado** | en curso |
| **Origen** | copiloto-microempresas: `main` sin protección (403 en cuenta personal · privado). Lista 2 · A15. |

## Fricción

La raíz de confianza exige que ninguna credencial ponga código en `main` por su cuenta.
En repo privado de cuenta personal GitHub no ofrece esa protección. El atajo existe y
hasta ahora no dejaba huella.

## Criterio verificable

1. Existe `.github/workflows/guardia-main.yml` con `on: push` a `main` y
   `permissions: contents: read, pull-requests: read, issues: write`.
2. Por cada commit del push consulta `repos/$REPO/commits/$SHA/pulls`. Si ninguno
   tiene `merged_at`, el job falla y abre un issue `Push directo a main: <sha> por <autor>`,
   o comenta en uno abierto con ese prefijo.
3. Un merge de PR (merge commit o squash) no dispara la alarma: la API
   asocia esos SHA con el PR mergeado. Medido en este repo sobre `45ad4c8` (squash,
   PR #20) y `522c47c` (merge commit, PR #19). Rebase merge no está verificado.
4. No se hace un push directo de prueba.

## AMEND REQ-V44

La API `commits/$SHA/pulls` puede tardar segundos en asociar el commit de un merge
recién hecho. Sin espera, la guardia abre un issue falso. Criterio añadido: 3
intentos, ~10 s entre ellos, antes de fallar. Rebase merge se apaga en el repo
(disponible en Free) en vez de afirmarlo sin medición.
