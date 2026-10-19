// What a screen must satisfy at any language and text size: every visible widget is inside the screen, every label is inside
// its widget, no text is wider than its box, and every layout panel is big enough for its children. Measured with
// `ui.measureText` (the real font, the same layout that is drawn) and `ui.state` (the rectangles the UI laid out).
import { game } from "factoria:test";
import { ui, fa } from "factoria";

const SCREEN = [1280, 720];

/** The size of one child of a layout panel: a widget from `ui.state`, a Text measured at the player's text size. */
function childSize(entity, rects) {
  if (rects.has(entity.id)) return rects.get(entity.id).slice(2);
  if (entity.has("Text")) {
    const t = entity.get("Text");
    if (!t.text) return [0, 0];
    const m = ui.measureText(t.text, { fontSize: t.fontSize, maxWidth: t.maxWidth || 0 });
    return [m.width, m.height];
  }
  return [0, 0];
}

/** Returns the list of problems on the screen as it is now (empty = fine). `where` names the screen in each message. */
export function screenProblems(where) {
  const problems = [];
  const widgets = fa.call("ui.state").widgets.filter((w) => w.visible);
  const rects = new Map(widgets.map((w) => [w.id, w.rect]));
  for (const w of widgets) {
    const [x, y, width, height] = w.rect;
    if (x < 0 || y < 0 || x + width > SCREEN[0] || y + height > SCREEN[1]) {
      problems.push(`${where}: "${w.id}" is outside the screen: ${w.rect.map(Math.round)}`);
    }
    const entity = game.find(w.id);
    if (!entity) continue;
    const kind = ["Button", "Toggle"].find((k) => entity.has(k));
    if (kind && w.text) {
      const fontSize = entity.get(kind).fontSize;
      const m = ui.measureText(w.text, { fontSize });
      const room = width - (kind === "Toggle" ? fontSize * ui.textScale * 1.2 : 0);
      if (m.width > room || m.height > height) {
        problems.push(`${where}: the label of "${w.id}" (${Math.round(m.width)} x ${Math.round(m.height)}) does not fit its ${Math.round(width)} x ${Math.round(height)} rectangle`);
      }
    }
    if (entity.has("Panel")) {
      const p = entity.get("Panel");
      if (p.layout !== "row" && p.layout !== "column") continue;
      const kids = entity.children.filter((c) => c.activeInHierarchy).map((c) => childSize(c, rects)).filter((s) => s[0] > 0 && s[1] > 0);
      if (!kids.length) continue;
      const { x: pl, y: pt, z: pr, w: pb } = p.padding; // (a vec4 field has x y z w; it cannot be indexed or destructured as an array)
      const row = p.layout === "row";
      const main = kids.reduce((sum, s) => sum + s[row ? 0 : 1], 0) + p.spacing * (kids.length - 1) + (row ? pl + pr : pt + pb);
      const cross = Math.max(...kids.map((s) => s[row ? 1 : 0])) + (row ? pt + pb : pl + pr);
      const needW = row ? main : cross;
      const needH = row ? cross : main;
      if (needW > width + 1 || needH > height + 1) {
        problems.push(`${where}: the content of "${w.id}" needs ${Math.round(needW)} x ${Math.round(needH)} but the panel is ${Math.round(width)} x ${Math.round(height)}`);
      }
    }
  }
  // Text: a word (or a line without spaces) wider than the box sticks out, and nothing is wider than the screen
  for (const e of game.world.entities()) {
    if (!e.has("Text") || !e.activeInHierarchy) continue;
    const t = e.get("Text");
    if (t.space !== "screen" || !t.text) continue;
    const m = ui.measureText(t.text, { fontSize: t.fontSize, maxWidth: t.maxWidth || 0 });
    const limit = t.maxWidth > 0 ? t.maxWidth : SCREEN[0] - 48;
    if (m.width > limit + 1) problems.push(`${where}: the text "${e.id}" is ${Math.round(m.width)} wide, more than ${Math.round(limit)}`);
  }
  return problems;
}
