# REQ-V35 — identidad visual comprobable en el estándar

| Campo | Valor |
|---|---|
| **ID** | REQ-V35 |
| **Descripción** | alma-standard publica v0.1.8 con las decisiones E.1–E.5 de la revisión de identidad visual 2026-09-30: el verificador deja de mirar solo color; cubre tipografía/espaciado, 17 roles de token, tokens-base, contraste AA en ambos temas, outline/focus-visible; la maqueta y el mapa §9 nombran lo que sigue siendo humano; `verificadores-estandar/casos.sh` (14 casos) entra a tests. |
| **Módulo** | alma-standard / diseño / verificadores |
| **Estado** | en curso |
| **Origen** | revisión identidad visual 2026-09-30 (ESP-006) §5 y §9 — vive fuera de este repo |
| **Diseño** | ESP-006 (enmienda pendiente v0.2; este REQ no la abre) |

## Fricción

`.agents/rules/diseno.md` §4 ya decía «cero literal de color, tipografía o espaciado».
`verificadores/catalogo.sh` solo miraba color. Medido sobre WorldWeaver: quince
literales de medida en ocho pantallas que el verde no veía. Sin roles de token, sin
capa de marca, sin contraste medido, el verde afirmaba menos de lo que la revisión
exige para v0.1.8.

## Criterio verificable

1. `bash verificadores-estandar/coherencia.sh` sin fallas.
2. `bash verificadores-estandar/casos.sh` sin fallas (14 casos: falla/pasa × 7
   comprobaciones nuevas).
3. `bash verificadores/catalogo.sh` sin fallas sobre el árbol del estándar.
4. CHANGELOG con V-35…V-39; `proyecto-estandar.md` tests incluye
   `verificadores-estandar/casos.sh`.
5. Sin merge a main, sin tag, sin PR en esta misión.
