# Capturas de interfaz (agentes)

Herramienta versionada para revisar pantallas con Playwright: captura a dos anchos
(1440 y 390), en claro y oscuro, página completa, y escribe un archivo de medidas
(`medidas.ejemplo.json` es la muestra versionada) con hallazgos de desborde,
contraste WCAG y tamaño de clic. **No hace clic ni envía formularios** — solo
navega (GET) y mide.

## Instalación

```bash
cd herramientas/capturas
npm install
npx playwright install chromium
```

No versionar `node_modules` ni los binarios del navegador.

## Uso

```bash
node capturar.mjs --base http://localhost:8787 --out ./salida \
  --routes /, /proyectos, /proyectos/alma, /misiones
```

Sesión (rutas con login) — **nunca credenciales en el repo**:

```bash
# Opción A: storageState exportado a mano / fuera del repo
node capturar.mjs --base URL --out DIR --routes /privada --storage /ruta/fuera/sesion.json

# Opción B: cookie de sesión (valor solo en la línea de comando / entorno local)
node capturar.mjs --base URL --out DIR --routes /privada --cookie nombre=valor
```

Código de salida distinto de cero **solo** si falla la corrida (browser, red, args).
Los hallazgos de medida no cambian el exit code.

## Salida

Por cada ruta × ancho × tema:

| Archivo | Contenido |
|---|---|
| `{ruta}-{ancho}-{tema}.png` | Captura `fullPage` |
| medidas.json (en la carpeta `--out`) | Una sola corrida con todas las rutas |

`ancho` es `1440` o `390`. `tema` es `claro` u `oscuro` (`prefers-color-scheme` emulado).

### Formato del archivo de medidas

La muestra versionada es `medidas.ejemplo.json`. Cada entrada de ruta × ancho × tema
incluye `archivo`, `viewport`, `tema`, `status`, `desborde` (hay / elementos con
selector y valor), `contraste.bajo` (selector, ratio, umbral, valor) y
`clic.pequenos` (selector, ancho, alto, valor).

Umbrales:

- **Desborde:** `documentElement.scrollWidth` > ancho del viewport, más elementos que se salen o hacen scroll horizontal.
- **Contraste:** textos y botones bajo 4,5:1 (3:1 si texto grande WCAG).
- **Clic:** enlaces/botones/inputs con ancho o alto &lt; 24 px.

Cada hallazgo lleva `selector` y `valor` medido.

## Pruebas

```bash
npm test
```

Carga `fixtures/pasa.html` (cero hallazgos) y `fixtures/falla.html` (desborde, contraste y clic bajo el umbral). También ejercita el cálculo de contraste en puro Node.

## Relación con otras misiones

La skill de autorrevisión y el usuario de prueba de WorldWeaver son misiones aparte.
Esta carpeta solo aporta la herramienta versionada.
