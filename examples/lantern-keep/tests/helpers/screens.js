// What a screen must satisfy at any language and text size: every visible widget is inside the screen, every label is inside
// its widget, no text is wider than its box, and every layout panel is big enough for its children. Measured with
// `ui.state` (the rectangles the UI laid out, widgets and screen-space Texts) and `ui.measureText` (the real font) for
// a label inside its button.
import { game } from "factoria:test";
import { ui, fa } from "factoria";

const SCREEN = [1280, 720];

/** The size of one child of a layout panel: its laid-out rectangle in `ui.state` (a widget or a screen-space Text). */
function childSize(entity, rects) {
  return rects.has(entity.id) ? rects.get(entity.id).slice(2) : [0, 0];
}

/** Returns the list of problems on the screen as it is now (empty = fine). `where` names the screen in each message. */
export function screenProblems(where) {
  const problems = [];
  const visible = fa.call("ui.state").widgets.filter((w) => w.visible);
  const widgets = visible.filter((w) => w.kind !== "Text");
  const rects = new Map(visible.filter((w) => w.kind !== "Text" || w.text).map((w) => [w.id, w.rect]));
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
      const layout = p.usingFallback ? p.fallbackLayout : p.layout; // the layout the panel really uses now
      if (layout !== "row" && layout !== "column") continue;
      const kids = entity.children.filter((c) => c.activeInHierarchy).map((c) => childSize(c, rects)).filter((s) => s[0] > 0 && s[1] > 0);
      if (!kids.length) continue;
      const [pl, pt, pr, pb] = p.padding; // left, top, right, bottom
      const row = layout === "row";
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
  for (const w of visible) {
    if (w.kind !== "Text" || !w.text) continue;
    const maxWidth = game.find(w.id)?.get("Text").maxWidth || 0;
    const limit = maxWidth > 0 ? maxWidth : SCREEN[0] - 48;
    if (w.rect[2] > limit + 1) problems.push(`${where}: the text "${w.id}" is ${Math.round(w.rect[2])} wide, more than ${Math.round(limit)}`);
  }
  return problems;
}
