// Layout checks for the screens a script opens later (options, boards, credits...), which `ui.check_layout` does not see: it only
// looks at what a scene shows when it has settled. problems() reads `ui.state` (the rectangles and the `overflowed` flag the
// engine itself computes) and lists texts that overflow their box, leave the screen, overlap another text or widget, or stick out
// of the panel they sit in.
import { game } from "factoria:test";
import { ui, i18n, fa, world } from "factoria";

export const LANGUAGES = ["en", "ru", "th"];
export const W = 1280;
export const H = 720;

const LEAF = new Set(["Text", "Button", "Toggle", "Slider", "TextField"]);

/** Sets the language and the text size and lets the layout settle (a few frames: texts are written at the end of a frame). */
export function setup(language, scale) {
  i18n.setLanguage(language);
  ui.textScale = scale;
  game.step(3);
  ui.layout();
}

const inside = (r, o, slack = 1.5) => r[0] >= o[0] - slack && r[1] >= o[1] - slack && r[0] + r[2] <= o[0] + o[2] + slack && r[1] + r[3] <= o[1] + o[3] + slack;

/** The ScrollList ancestors of an entity (their rectangles clip what it draws). */
function lists(id, rects) {
  const out = [];
  let e = world.find(id)?.parent;
  while (e) {
    if (e.has("ScrollList") && rects.has(e.id)) out.push(rects.get(e.id));
    e = e.parent;
  }
  return out;
}

/** The nearest ancestor that is a Panel with a size of its own (not fit), or a ScrollList, or null. */
function box(id, rects) {
  let e = world.find(id)?.parent;
  while (e) {
    const rect = rects.get(e.id);
    if (rect && (e.has("ScrollList") || (e.has("Panel") && !e.get("Panel").fit))) return { id: e.id, rect, list: e.has("ScrollList") };
    e = e.parent;
  }
  return null;
}

/** The part of a rectangle a list does not clip (null: all of it is out of sight, scrolled away). */
function visible(rect, clips) {
  let [x, y, w, h] = rect;
  for (const c of clips) {
    const x0 = Math.max(x, c[0]), y0 = Math.max(y, c[1]);
    const x1 = Math.min(x + w, c[0] + c[2]), y1 = Math.min(y + h, c[1] + c[3]);
    if (x1 - x0 < 1 || y1 - y0 < 1) return null;
    [x, y, w, h] = [x0, y0, x1 - x0, y1 - y0];
  }
  return [x, y, w, h];
}

/**
 * What is wrong with the screen as it is now: an array of short strings (empty = clean).
 * A row a ScrollList scrolls (or clips) is judged by the part you can see; its width must still fit the list.
 * @param {{ignore?: string[], allowOverlap?: Array<[string, string]>}} [opts] ids to skip, and pairs that may overlap
 */
export function problems(opts = {}) {
  const ignore = new Set(opts.ignore ?? []);
  const state = fa.call("ui.state");
  const rects = new Map();
  for (const w of state.widgets) rects.set(w.id, w.rect);
  const leaves = state.widgets.filter((w) => LEAF.has(w.kind) && w.visible && !ignore.has(w.id) && w.rect[2] > 0 && w.rect[3] > 0);
  const out = [];
  const seen = [];
  for (const w of leaves) {
    const clips = lists(w.id, rects);
    const shown = visible(w.rect, clips);
    if (!shown) continue; // scrolled away: reachable by scrolling, nothing to judge
    if (w.overflowed) out.push(`${w.id} overflows its box`);
    if (!inside(shown, [0, 0, W, H])) out.push(`${w.id} leaves the screen ${w.rect.map(Math.round)}`);
    const b = box(w.id, rects);
    if (b) {
      const okay = b.list ? w.rect[0] >= b.rect[0] - 1.5 && w.rect[0] + w.rect[2] <= b.rect[0] + b.rect[2] + 1.5 : inside(w.rect, b.rect);
      if (!okay) out.push(`${w.id} sticks out of ${b.id} ${w.rect.map(Math.round)} / ${b.rect.map(Math.round)}`);
    }
    seen.push({ id: w.id, rect: shown });
  }
  const allowed = new Set((opts.allowOverlap ?? []).flatMap(([a, b]) => [`${a}|${b}`, `${b}|${a}`]));
  for (let i = 0; i < seen.length; i++) {
    for (let j = i + 1; j < seen.length; j++) {
      const a = seen[i], c = seen[j];
      if (allowed.has(`${a.id}|${c.id}`)) continue;
      const w = Math.min(a.rect[0] + a.rect[2], c.rect[0] + c.rect[2]) - Math.max(a.rect[0], c.rect[0]);
      const h = Math.min(a.rect[1] + a.rect[3], c.rect[1] + c.rect[3]) - Math.max(a.rect[1], c.rect[1]);
      if (w > 3 && h > 3) {
        const ea = world.find(a.id), ec = world.find(c.id);
        // a widget and its own label are one thing
        if (ea && ec && (ea.parent === ec || ec.parent === ea)) continue;
        out.push(`${a.id} overlaps ${c.id}`);
      }
    }
  }
  return out;
}
