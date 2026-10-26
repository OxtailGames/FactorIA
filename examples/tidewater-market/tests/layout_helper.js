// A layout check for tests that open a screen: the same three questions as `ui.check_layout` (docs/LOCALIZATION.md), asked of whatever
// the scripts have built and opened (panels the scene file does not have), so the language tests can reach every screen.
//   overflow    a Text or label that still does not fit its box (ui.overflowed: after autoSize, autoShrink and maxTextScale)
//   offscreen   a Text or widget that leaves the 1280 x 720 screen
//   overlap     two texts or labelled widgets that cover each other (neither the parent of the other)
import { world, ui, i18n } from "factoria";
import { game } from "factoria:test";

const SCREEN = { w: 1280, h: 720 };
const WIDGETS = ["Button", "Toggle", "Slider", "TextField"];

function ancestors(e) {
  const out = new Set();
  for (let p = e.parent; p; p = p.parent) out.add(p);
  return out;
}

/** The text a widget or Text shows, "" for one without. */
function shownText(e) {
  if (e.has("Text")) return e.get("Text").text ?? "";
  for (const w of WIDGETS) if (e.has(w)) return e.get(w).text ?? e.get(w).label ?? "";
  return "";
}

/** Every visible text and labelled widget of the scene, with its rectangle on screen. */
export function visibleItems() {
  const items = [];
  for (const e of world.entities()) {
    if (!e.activeInHierarchy) continue;
    const isText = e.has("Text") && e.get("Text").space !== "world";
    const isWidget = WIDGETS.some((w) => e.has(w));
    if (!isText && !isWidget) continue;
    const text = shownText(e);
    if (!text) continue;
    const rect = ui.rectOf(e);
    if (!rect || rect.w <= 0 || rect.h <= 0) continue;
    // a row of a ScrollList counts by the part the list shows; a row scrolled out of view counts for nothing
    let shown = rect;
    for (let p = e.parent; p; p = p.parent) {
      if (!p.has("ScrollList")) continue;
      const box = ui.rectOf(p);
      if (!box) continue;
      const x = Math.max(rect.x, box.x);
      const y = Math.max(rect.y, box.y);
      const x2 = Math.min(rect.x + rect.w, box.x + box.w);
      const y2 = Math.min(rect.y + rect.h, box.y + box.h);
      shown = x2 > x && y2 > y ? { x, y, w: x2 - x, h: y2 - y } : null;
      break;
    }
    if (!shown) continue;
    items.push({ e, id: e.id || e.name, text, rect: shown });
  }
  return items;
}

const within = (a, b) => a.x >= b.x - 0.5 && a.y >= b.y - 0.5 && a.x + a.w <= b.x + b.w + 0.5 && a.y + a.h <= b.y + b.h + 0.5;

/**
 * Everything that is wrong with the layout on screen now, as short lines ("overflow title: ...").
 * @param {{ ignore?: string[], only?: string }} [opts] ignore: ids (or id prefixes) that are not the subject of the test, e.g. "tooltip_"
 *   (a tooltip is transient); only: the id of the one panel to judge, for a modal screen with the game behind it
 */
export function layoutProblems({ ignore = [], only = "" } = {}) {
  ui.layout();
  const lines = [];
  const skipped = (i) => ignore.some((id) => i.id === id || i.id.startsWith(id));
  const root = only ? world.find(only) : null;
  const items = visibleItems().filter((i) => !skipped(i) && (!root || i.e === root || ancestors(i.e).has(root)));
  const screen = { x: 0, y: 0, w: SCREEN.w, h: SCREEN.h };
  for (const it of items) {
    const where = `${it.id} "${it.text.slice(0, 40)}" ${JSON.stringify(it.rect.x | 0)},${it.rect.y | 0} ${it.rect.w | 0}x${it.rect.h | 0}`;
    if (ui.overflowed(it.e)) lines.push(`overflow ${where}`);
    if (!within(it.rect, screen)) lines.push(`offscreen ${where}`);
  }
  for (let i = 0; i < items.length; i++) {
    const a = items[i];
    const up = ancestors(a.e);
    for (let j = i + 1; j < items.length; j++) {
      const b = items[j];
      const ra = a.rect;
      const rb = b.rect;
      if (!(ra.x < rb.x + rb.w - 1 && rb.x < ra.x + ra.w - 1 && ra.y < rb.y + rb.h - 1 && rb.y < ra.y + ra.h - 1)) continue;
      if (up.has(b.e) || ancestors(b.e).has(a.e)) continue;
      // RichView draws bold as the same text twice, one pixel apart: not an overlap
      if (a.text === b.text && Math.abs(ra.x - rb.x) <= 1.5 && Math.abs(ra.y - rb.y) <= 1.5) continue;
      lines.push(`overlap ${a.id} "${a.text.slice(0, 30)}" with ${b.id} "${b.text.slice(0, 30)}"`);
    }
  }
  return lines;
}

/** The languages of the game, in the order of factoria.json, and the longest one for the layout tests (fr: the longest strings). */
export const LANGUAGES = ["en", "es", "fr", "zh-Hans"];

/** Run `body` in `language` at `scale` text size, then put English and 100 % back (the run is shared by the next test). */
export function inLanguage(language, scale, body) {
  const before = { language: i18n.language, scale: ui.textScale };
  i18n.setLanguage(language);
  ui.textScale = scale;
  game.step(3);
  try {
    return body();
  } finally {
    i18n.setLanguage(before.language);
    ui.textScale = before.scale;
    game.step(2);
  }
}
