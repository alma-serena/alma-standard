#!/usr/bin/env node
/**
 * Capturas + medidas de interfaz.
 *
 * Uso:
 *   node capturar.mjs --base URL --out DIR --routes /, /a, /b
 *   node capturar.mjs --base URL --out DIR --routes / --storage ./sesion.json
 *   node capturar.mjs --base URL --out DIR --routes / --cookie nombre=valor
 *
 * Solo GET/navegación. No hace clic ni envía formularios.
 * Código de salida ≠ 0 solo si la corrida falla (red, browser), no por hallazgos.
 */
import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';
import { medirPagina } from './lib/medidas.mjs';

const __dirname = dirname(fileURLToPath(import.meta.url));

const ANCHOS = [
  { nombre: '1440', width: 1440, height: 900 },
  { nombre: '390', width: 390, height: 844 },
];
const TEMAS = [
  { nombre: 'claro', colorScheme: 'light' },
  { nombre: 'oscuro', colorScheme: 'dark' },
];

function uso() {
  console.error(`Uso:
  node capturar.mjs --base <url> --out <dir> --routes <ruta>[,ruta...]
Opciones:
  --storage <archivo.json>   storageState de Playwright (sesión ya iniciada)
  --cookie <nombre=valor>    cookie de sesión (se puede repetir)
  --help`);
}

function parseArgs(argv) {
  const out = { base: null, outDir: null, routes: [], storage: null, cookies: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--help' || a === '-h') return { help: true };
    if (a === '--base') out.base = argv[++i];
    else if (a === '--out') out.outDir = argv[++i];
    else if (a === '--routes') {
      const raw = argv[++i] ?? '';
      out.routes.push(...raw.split(',').map((s) => s.trim()).filter(Boolean));
    }
    else if (a === '--storage') out.storage = argv[++i];
    else if (a === '--cookie') out.cookies.push(argv[++i]);
    else throw new Error(`Argumento desconocido: ${a}`);
  }
  return out;
}

function parseCookie(spec, baseUrl) {
  const eq = spec.indexOf('=');
  if (eq < 1) throw new Error(`Cookie inválida (use nombre=valor): ${spec}`);
  const name = spec.slice(0, eq);
  const value = spec.slice(eq + 1);
  const u = new URL(baseUrl);
  return {
    name,
    value,
    domain: u.hostname,
    path: '/',
  };
}

function slugRuta(ruta) {
  if (ruta === '/' || ruta === '') return 'inicio';
  return ruta.replace(/^\//, '').replace(/\//g, '__').replace(/[^a-zA-Z0-9._-]/g, '_');
}

async function main() {
  let args;
  try {
    args = parseArgs(process.argv.slice(2));
  } catch (e) {
    console.error(e.message);
    uso();
    process.exit(2);
  }
  if (args.help) {
    uso();
    process.exit(0);
  }
  if (!args.base || !args.outDir || args.routes.length === 0) {
    uso();
    process.exit(2);
  }

  const base = args.base.replace(/\/$/, '');
  const outDir = resolve(args.outDir);
  await mkdir(outDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const medidas = {
    base,
    generado: new Date().toISOString(),
    herramienta: 'alma-capturas',
    rutas: {},
  };

  try {
    for (const ruta of args.routes) {
      const path = ruta.startsWith('/') ? ruta : `/${ruta}`;
      const url = `${base}${path}`;
      const clave = path;
      medidas.rutas[clave] = {};

      for (const ancho of ANCHOS) {
        for (const tema of TEMAS) {
          const context = await browser.newContext({
            viewport: { width: ancho.width, height: ancho.height },
            deviceScaleFactor: 1,
            colorScheme: tema.colorScheme,
            ...(args.storage ? { storageState: resolve(args.storage) } : {}),
          });
          if (args.cookies.length) {
            await context.addCookies(args.cookies.map((c) => parseCookie(c, base)));
          }

          const page = await context.newPage();
          // Solo navegación GET. Sin clic ni submit.
          const resp = await page.goto(url, { waitUntil: 'networkidle', timeout: 60_000 });
          if (!resp) {
            throw new Error(`Sin respuesta: ${url}`);
          }
          // No fallar por 4xx/5xx de la app: igual se captura; sí fallar si crash del browser.

          const hallazgo = await medirPagina(page);
          const etiqueta = `${ancho.nombre}-${tema.nombre}`;
          const archivo = `${slugRuta(path)}-${etiqueta}.png`;
          const destino = join(outDir, archivo);
          await page.screenshot({ path: destino, fullPage: true });

          medidas.rutas[clave][etiqueta] = {
            archivo,
            viewport: { width: ancho.width, height: ancho.height },
            tema: tema.nombre,
            status: resp.status(),
            ...hallazgo,
          };

          await context.close();
          console.error(`ok  ${path}  ${etiqueta}  → ${archivo}`);
        }
      }
    }

    const medidasPath = join(outDir, 'medidas.json');
    await writeFile(medidasPath, `${JSON.stringify(medidas, null, 2)}\n`, 'utf8');
    console.error(`medidas → ${medidasPath}`);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err?.stack || err);
  process.exit(1);
});
