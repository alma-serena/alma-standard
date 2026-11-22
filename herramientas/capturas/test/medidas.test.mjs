import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { chromium } from 'playwright';
import {
  medirPagina,
  ratioContraste,
  umbralContraste,
  esTextoGrande,
  parseColor,
} from '../lib/medidas.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const fixture = (name) => pathToFileURL(join(root, 'fixtures', name)).href;

async function conPagina(htmlName, fn) {
  const browser = await chromium.launch({ headless: true });
  try {
    const page = await browser.newPage({
      viewport: { width: 800, height: 600 },
      colorScheme: 'light',
    });
    await page.goto(fixture(htmlName), { waitUntil: 'load' });
    return await fn(page);
  } finally {
    await browser.close();
  }
}

describe('contraste puro', () => {
  it('ratio negro/blanco es 21', () => {
    const negro = { r: 0, g: 0, b: 0 };
    const blanco = { r: 255, g: 255, b: 255 };
    assert.ok(Math.abs(ratioContraste(negro, blanco) - 21) < 0.01);
  });

  it('umbral 4.5 normal y 3 grande', () => {
    assert.equal(umbralContraste(16, 400), 4.5);
    assert.equal(umbralContraste(24, 400), 3);
    assert.equal(esTextoGrande(18.66, 700), true);
  });

  it('parseColor entiende hex y rgb', () => {
    assert.deepEqual(parseColor('#fff'), { r: 255, g: 255, b: 255, a: 1 });
    assert.deepEqual(parseColor('rgb(1, 2, 3)'), { r: 1, g: 2, b: 3, a: 1 });
  });
});

describe('medidas sobre fixtures', () => {
  it('pasa: sin desborde, sin contraste bajo, sin clic < 24', async () => {
    const m = await conPagina('pasa.html', medirPagina);
    assert.equal(m.desborde.hay, false);
    assert.equal(m.desborde.elementos.length, 0);
    assert.equal(m.contraste.bajo.length, 0);
    assert.equal(m.clic.pequenos.length, 0);
  });

  it('falla: desborde horizontal con elemento causante', async () => {
    const m = await conPagina('falla.html', medirPagina);
    assert.equal(m.desborde.hay, true);
    assert.ok(m.desborde.elementos.length >= 1);
    const banda = m.desborde.elementos.find((e) => e.selector.includes('banda-ancha'));
    assert.ok(banda, 'debe reportar #banda-ancha');
    assert.ok(banda.valor > 800);
  });

  it('falla: contraste bajo con selector y ratio', async () => {
    const m = await conPagina('falla.html', medirPagina);
    assert.ok(m.contraste.bajo.length >= 1);
    for (const h of m.contraste.bajo) {
      assert.ok(h.selector);
      assert.ok(typeof h.valor === 'number');
      assert.ok(h.valor < h.umbral);
    }
  });

  it('falla: objetivos de clic menores de 24 px', async () => {
    const m = await conPagina('falla.html', medirPagina);
    assert.ok(m.clic.pequenos.length >= 1);
    for (const h of m.clic.pequenos) {
      assert.ok(h.selector);
      assert.ok(h.valor < 24);
    }
  });
});
