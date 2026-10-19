// @ts-check
// Makes buttons, toggles and sliders as big as their label needs at the player's text size (ui.textScale). The engine
// scales the text but widgets keep their rectangles, so a label at 200 % would stick out of a 240 x 56 button.
// Call fitWidgets(root) when a screen starts, when the language changes and after the text size changes.
import { ui, i18n } from "factoria";

/** First size of each widget (by entity id), so fitting at 100 % again gives the design size back. */
const base = new Map();
const KINDS = ["Button", "Toggle", "Slider"];
/** Extra width a label needs next to its text: a toggle's box, a slider's track. */
const EXTRA = { Button: 0, Toggle: 0, Slider: 220 };

/** Arabic and Hebrew read right to left (the engine orders the letters, but `align` is explicit: it never follows the language). */
const RTL = new Set(["ar", "he", "fa", "ur"]);
export const isRtl = () => RTL.has(i18n.language.split("-")[0]);

/**
 * Resizes every Button, Toggle and Slider under `root` (an entity) to fit its label, never smaller than the design size,
 * and aligns the wrapped texts under it to the reading direction of the language (right for Arabic, left otherwise).
 */
export function fitWidgets(root) {
  const scale = ui.textScale;
  const align = isRtl() ? "right" : "left";
  for (const entity of descendants(root)) {
    if (entity.has("Text") && entity.get("Text").maxWidth > 0) entity.get("Text").align = align;
    const kind = KINDS.find((k) => entity.has(k));
    if (!kind || !entity.id) continue;
    const widget = entity.get(kind);
    const label = kind === "Button" ? widget.text : widget.label;
    const first = base.get(entity.id) ?? [widget.size.x, widget.size.y];
    base.set(entity.id, first);
    const m = ui.measureText(label, { fontSize: widget.fontSize });
    const box = kind === "Toggle" ? widget.fontSize * scale * 1.6 : 0;
    const w = Math.max(first[0], Math.ceil(m.width + 2 * 20 + box + EXTRA[kind]));
    const lines = label.split("\n").length; // a label with line breaks (the level select's name and result) needs a taller widget
    const h = Math.max(first[1], Math.ceil(widget.fontSize * scale * 1.3 * lines));
    widget.size = [w, h];
  }
}

function* descendants(entity) {
  yield entity;
  for (const child of entity.children) yield* descendants(child);
}

/**
 * Sizes a ScrollList so its panel (a column with `fit`) still fits the screen: the list takes the height the other children
 * leave, never more than `max` (its design height) and never less than `min`. Call it after the other texts are written
 * and after fitWidgets. `margin` is the space kept free above and below the panel.
 */
export function fitList(panel, list, { max = 440, min = 96, margin = 12 } = {}) {
  const p = panel.get("Panel");
  const kids = panel.children.filter((c) => c.active && c.id !== list.id);
  let used = p.padding.y + p.padding.w + p.spacing * kids.length; // the gaps include the one next to the list
  for (const kid of kids) used += contentHeight(kid);
  const size = list.get("ScrollList").size;
  list.get("ScrollList").size = [size.x, Math.max(min, Math.min(max, Math.floor(720 - 2 * margin - used)))];
}

/**
 * The height an entity takes in a column: a Text measured at the player's text size, a widget by its size, a layout panel
 * (row or column, nested as deep as you like) by its children. What the engine's `fit` panels will compute next frame.
 */
export function contentHeight(entity) {
  if (entity.has("Text")) {
    const t = entity.get("Text");
    return t.text ? ui.measureText(t.text, { fontSize: t.fontSize, maxWidth: t.maxWidth || 0 }).height : 0;
  }
  if (entity.has("Panel") && entity.get("Panel").layout !== "none") {
    const p = entity.get("Panel");
    const heights = entity.children.filter((c) => c.active).map(contentHeight);
    if (!heights.length) return 0;
    const inner = p.layout === "row" ? Math.max(...heights) : heights.reduce((a, b) => a + b, 0) + p.spacing * (heights.length - 1);
    return inner + p.padding.y + p.padding.w;
  }
  const kind = KINDS.find((k) => entity.has(k)) ?? (entity.has("ScrollList") ? "ScrollList" : null);
  return kind ? entity.get(kind).size.y : 0;
}
