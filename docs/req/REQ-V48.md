# REQ-V48 — mapa de pantallas y flujos para el trabajo de interfaz

| Campo | Valor |
|---|---|
| **ID** | REQ-V48 |
| **Descripción** | En un proyecto con `interfaz: si`, el verificador falla en `certificacion` si una misión abierta declara pantallas y el proyecto no tiene un mapa en estado `ACEPTADO` con esos IDs vigentes, o si la copia del mapa no coincide con su hash declarado. Sin mapa (`mapa: pendiente`) el proyecto no puede declararse `conforme`. |
| **Módulo** | alma-standard / verificadores/mapa.sh · catalogo.sh · rules/diseno.md · workflows/instruccion.md · plantillas |
| **Estado** | abierto |
| **Origen** | Decisión de Nico del 2026-10-02 (camino C + D), transcrita aquí porque no constaba en el registro salvo estado/ESTADO.md (fila Alma, acción A7): «ALMA Dev suma un artefacto obligatorio, mapa de pantallas y flujos, aceptado antes de cualquier misión de interfaz». Confirmada por Nico el 2026-11-16 (redactada como REQ-V47; renumerada porque V-47 ya existía). Consumidores que la motivan: ESP-007 (aceptada sin mapa) y WorldWeaver (misiones de UI detenidas). |

## Fricción

Las especificaciones se aceptan con la interfaz como lista de nombres, y las misiones de UI
inventan pantallas, estados y caminos (ESP-005/experiencia.md §1: «quien entra ve CRUD»).

## Criterio verificable

1. Con `interfaz: si` y sin `mapa:`, el verificador falla. Caso en `verificadores-estandar/casos-mapa.sh`.
2. Con `mapa: pendiente`, aviso con nombre; con `conforme`, falla. Casos.
3. Mapa con `estado:` distinto de `ACEPTADO`, misión abierta con `pantallas:` → falla. Caso.
4. Misión con un ID inexistente o `retirada` → falla. Caso.
5. Copia de docs/mapa.md editada (hash distinto de `mapa-origen:`) → falla. Caso.
6. Mermaid fuera de la sintaxis permitida, pantalla sin traza, nodo que no es ID,
   pantalla inalcanzable o estado vacío sin `N/A — razón` → falla. Casos.
7. `.agents/rules/diseno.md` lista lo que el verde no afirma; ninguna comprobación depende del kit (línea C).
