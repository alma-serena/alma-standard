/**
 * Recolección de medidas en página (Playwright) y armado de hallazgos.
 */
import {
  componerSobre,
  ratioContraste,
  umbralContraste,
} from './contraste.mjs';

/**
 * Script que corre dentro de page.evaluate.
 * Devuelve candidatos crudos; el umbral WCAG se aplica en Node.
 */
export function recolectarEnPagina() {
  const ancho = window.innerWidth;

  function selectorDe(el) {
    if (!el || el === document.documentElement) return 'html';
    if (el.id) return `#${CSS.escape(el.id)}`;
    const tag = el.tagName.toLowerCase();
    const padre = el.parentElement;
    if (!padre) return tag;
    const mismos = [...padre.children].filter((c) => c.tagName === el.tagName);
    if (mismos.length === 1) return `${selectorDe(padre)} > ${tag}`;
    const idx = mismos.indexOf(el) + 1;
    return `${selectorDe(padre)} > ${tag}:nth-of-type(${idx})`;
  }

  function fondoEfectivo(el) {
    let cur = el;
    while (cur && cur !== document.documentElement) {
      const bg = getComputedStyle(cur).backgroundColor;
      const parsed = (() => {
        const m = bg.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
        if (!m) return null;
        return { r: +m[1], g: +m[2], b: +m[3], a: m[4] === undefined ? 1 : +m[4] };
      })();
      if (parsed && parsed.a > 0.01) {
        if (parsed.a >= 0.99) return parsed;
        // mezcla parcial: seguir buscando detrás
        let detrás = { r: 255, g: 255, b: 255, a: 1 };
        let p = cur.parentElement;
        while (p) {
          const pb = getComputedStyle(p).backgroundColor;
          const pm = pb.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
          if (pm) {
            const pa = pm[4] === undefined ? 1 : +pm[4];
            if (pa > 0.01) {
              detrás = { r: +pm[1], g: +pm[2], b: +pm[3], a: pa };
              if (pa >= 0.99) break;
            }
          }
          p = p.parentElement;
        }
        const inv = 1 - parsed.a;
        return {
          r: parsed.r * parsed.a + detrás.r * inv,
          g: parsed.g * parsed.a + detrás.g * inv,
          b: parsed.b * parsed.a + detrás.b * inv,
          a: 1,
        };
      }
      cur = cur.parentElement;
    }
    const bodyBg = getComputedStyle(document.body).backgroundColor;
    const m = bodyBg.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
    if (m && (m[4] === undefined || +m[4] > 0.01)) {
      return { r: +m[1], g: +m[2], b: +m[3], a: 1 };
    }
    return { r: 255, g: 255, b: 255, a: 1 };
  }

  const desborde = {
    hay: document.documentElement.scrollWidth > ancho + 1,
    scrollWidth: document.documentElement.scrollWidth,
    viewportWidth: ancho,
    elementos: [],
  };

  for (const el of document.body.querySelectorAll('*')) {
    const st = getComputedStyle(el);
    if (st.display === 'none' || st.visibility === 'hidden') continue;
    const rect = el.getBoundingClientRect();
    if (rect.width === 0 && rect.height === 0) continue;
    const overflowX = el.scrollWidth > el.clientWidth + 1;
    const sale = rect.right > ancho + 1 || rect.left < -1;
    if (overflowX || sale) {
      desborde.elementos.push({
        selector: selectorDe(el),
        scrollWidth: el.scrollWidth,
        clientWidth: el.clientWidth,
        right: Math.round(rect.right * 100) / 100,
        valor: Math.max(el.scrollWidth, Math.ceil(rect.right)),
      });
    }
  }

  const contrasteCandidatos = [];
  const nodosTexto = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  let nodo;
  while ((nodo = nodosTexto.nextNode())) {
    const t = nodo.textContent.replace(/\s+/g, ' ').trim();
    if (!t) continue;
    const el = nodo.parentElement;
    if (!el) continue;
    const st = getComputedStyle(el);
    if (st.display === 'none' || st.visibility === 'hidden' || st.opacity === '0') continue;
    if (!['inline', 'inline-block', 'block', 'list-item', 'flex', 'grid', 'table-cell'].includes(st.display)
      && st.display !== 'contents') {
      // seguir igual: muchos textos viven en spans
    }
    const color = st.color;
    const cm = color.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
    if (!cm) continue;
    const fg = { r: +cm[1], g: +cm[2], b: +cm[3], a: cm[4] === undefined ? 1 : +cm[4] };
    if (fg.a < 0.05) continue;
    const bg = fondoEfectivo(el);
    contrasteCandidatos.push({
      selector: selectorDe(el),
      tipo: 'texto',
      muestra: t.slice(0, 40),
      color: fg,
      fondo: bg,
      fontSizePx: parseFloat(st.fontSize) || 16,
      fontWeight: st.fontWeight,
    });
  }

  for (const el of document.body.querySelectorAll('button, [role="button"], input[type="submit"], input[type="button"]')) {
    const st = getComputedStyle(el);
    if (st.display === 'none' || st.visibility === 'hidden') continue;
    const cm = st.color.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
    if (!cm) continue;
    const fg = { r: +cm[1], g: +cm[2], b: +cm[3], a: cm[4] === undefined ? 1 : +cm[4] };
    contrasteCandidatos.push({
      selector: selectorDe(el),
      tipo: 'boton',
      muestra: (el.innerText || el.value || '').trim().slice(0, 40),
      color: fg,
      fondo: fondoEfectivo(el),
      fontSizePx: parseFloat(st.fontSize) || 16,
      fontWeight: st.fontWeight,
    });
  }

  const clic = [];
  const interactivos = document.body.querySelectorAll(
    'a[href], button, input, select, textarea, [role="button"], [role="link"], [onclick]',
  );
  for (const el of interactivos) {
    const st = getComputedStyle(el);
    if (st.display === 'none' || st.visibility === 'hidden' || st.pointerEvents === 'none') continue;
    const rect = el.getBoundingClientRect();
    if (rect.width === 0 && rect.height === 0) continue;
    const w = Math.round(rect.width * 100) / 100;
    const h = Math.round(rect.height * 100) / 100;
    if (w < 24 || h < 24) {
      clic.push({
        selector: selectorDe(el),
        ancho: w,
        alto: h,
        valor: Math.min(w, h),
      });
    }
  }

  return { desborde, contrasteCandidatos, clic };
}

/** Aplica umbrales WCAG a los candidatos crudos de la página. */
export function evaluarCandidatos(crudo) {
  const bajo = [];
  const vistos = new Set();
  for (const c of crudo.contrasteCandidatos || []) {
    const fg = componerSobre(c.color, c.fondo);
    const ratio = ratioContraste(fg, c.fondo);
    const umbral = umbralContraste(c.fontSizePx, c.fontWeight);
    const clave = `${c.selector}|${c.tipo}|${c.muestra}`;
    if (vistos.has(clave)) continue;
    vistos.add(clave);
    if (ratio < umbral) {
      bajo.push({
        selector: c.selector,
        tipo: c.tipo,
        muestra: c.muestra,
        ratio: Math.round(ratio * 100) / 100,
        umbral,
        fontSizePx: c.fontSizePx,
        valor: Math.round(ratio * 100) / 100,
      });
    }
  }

  // Deduplicar desborde por selector (quedarse con el mayor valor)
  const porSel = new Map();
  for (const e of crudo.desborde?.elementos || []) {
    const prev = porSel.get(e.selector);
    if (!prev || e.valor > prev.valor) porSel.set(e.selector, e);
  }

  return {
    desborde: {
      hay: Boolean(crudo.desborde?.hay) || porSel.size > 0,
      scrollWidth: crudo.desborde?.scrollWidth ?? null,
      viewportWidth: crudo.desborde?.viewportWidth ?? null,
      elementos: [...porSel.values()],
    },
    contraste: { bajo },
    clic: { pequenos: crudo.clic || [] },
  };
}

/**
 * Mide una página ya cargada en Playwright.
 * @param {import('playwright').Page} page
 */
export async function medirPagina(page) {
  const crudo = await page.evaluate(recolectarEnPagina);
  return evaluarCandidatos(crudo);
}

export { parseColor, ratioContraste, umbralContraste, esTextoGrande } from './contraste.mjs';
