/**
 * Contraste WCAG 2.x (relative luminance + ratio).
 * Sin dependencia de DOM: recibe colores ya resueltos.
 */

/** @param {number} canal 0–255 */
function canalLineal(canal) {
  const c = canal / 255;
  return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
}

/**
 * @param {{ r: number, g: number, b: number }} rgb
 * @returns {number}
 */
export function luminanciaRelativa(rgb) {
  const R = canalLineal(rgb.r);
  const G = canalLineal(rgb.g);
  const B = canalLineal(rgb.b);
  return 0.2126 * R + 0.7152 * G + 0.0722 * B;
}

/**
 * @param {{ r: number, g: number, b: number }} a
 * @param {{ r: number, g: number, b: number }} b
 * @returns {number} ratio ≥ 1
 */
export function ratioContraste(a, b) {
  const L1 = luminanciaRelativa(a);
  const L2 = luminanciaRelativa(b);
  const claro = Math.max(L1, L2);
  const oscuro = Math.min(L1, L2);
  return (claro + 0.05) / (oscuro + 0.05);
}

/**
 * Texto grande WCAG: ≥ 18pt (24px) o ≥ 14pt (18.66px) en negrita (≥ 700).
 * @param {number} fontSizePx
 * @param {number|string} fontWeight
 */
export function esTextoGrande(fontSizePx, fontWeight) {
  const peso = typeof fontWeight === 'string'
    ? (fontWeight === 'bold' ? 700 : parseInt(fontWeight, 10) || 400)
    : fontWeight;
  return fontSizePx >= 24 || (fontSizePx >= 18.66 && peso >= 700);
}

/**
 * Umbral mínimo AA: 4.5:1 normal, 3:1 grande.
 * @param {number} fontSizePx
 * @param {number|string} fontWeight
 */
export function umbralContraste(fontSizePx, fontWeight) {
  return esTextoGrande(fontSizePx, fontWeight) ? 3 : 4.5;
}

/**
 * Parsea `rgb()`, `rgba()` o `#rrggbb` / `#rgb`. Devuelve null si no puede.
 * @param {string} css
 * @returns {{ r: number, g: number, b: number, a: number } | null}
 */
export function parseColor(css) {
  if (!css || css === 'transparent') return { r: 0, g: 0, b: 0, a: 0 };
  const s = css.trim().toLowerCase();
  const hex = s.match(/^#([0-9a-f]{3}|[0-9a-f]{6})$/i);
  if (hex) {
    let h = hex[1];
    if (h.length === 3) h = h.split('').map((c) => c + c).join('');
    return {
      r: parseInt(h.slice(0, 2), 16),
      g: parseInt(h.slice(2, 4), 16),
      b: parseInt(h.slice(4, 6), 16),
      a: 1,
    };
  }
  const m = s.match(/^rgba?\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)(?:\s*,\s*([\d.]+))?\s*\)$/);
  if (m) {
    return {
      r: Number(m[1]),
      g: Number(m[2]),
      b: Number(m[3]),
      a: m[4] === undefined ? 1 : Number(m[4]),
    };
  }
  return null;
}

/**
 * Compone `fg` sobre `bg` si fg.a < 1 (alpha simple).
 * @param {{ r: number, g: number, b: number, a: number }} fg
 * @param {{ r: number, g: number, b: number, a?: number }} bg
 */
export function componerSobre(fg, bg) {
  const a = fg.a ?? 1;
  if (a >= 1) return { r: fg.r, g: fg.g, b: fg.b };
  const inv = 1 - a;
  return {
    r: fg.r * a + bg.r * inv,
    g: fg.g * a + bg.g * inv,
    b: fg.b * a + bg.b * inv,
  };
}
