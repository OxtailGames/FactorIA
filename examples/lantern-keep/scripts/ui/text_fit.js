// @ts-check
// Makes buttons, toggles and sliders as big as their label needs at the player's text size (ui.textScale). The engine
// scales the text but widgets keep their rectangles, so a label at 200 % would stick out of a 240 x 56 button.
// Call fitWidgets(root) when a screen starts, when the language changes and after the text size changes.
import { ui } from "factoria";

/** First size of each widget (by entity id), so fitting at 100 % again gives the design size back. */
const base = new Map();
const KINDS = ["Button", "Toggle", "Slider"];
/** Extra width a label needs next to its text: a toggle's box, a slider's track. */
const EXTRA = { Button: 0, Toggle: 0, Slider: 220 };

/** Resizes every Button, Toggle and Slider under `root` (an entity) to fit its label. Never smaller than the design size. */
export function fitWidgets(root) {
  const scale = ui.textScale;
  for (const entity of descendants(root)) {
    const kind = KINDS.find((k) => entity.has(k));
    if (!kind || !entity.id) continue;
    const widget = entity.get(kind);
    const label = kind === "Button" ? widget.text : widget.label;
    const first = base.get(entity.id) ?? [widget.size.x, widget.size.y];
    base.set(entity.id, first);
    const m = ui.measureText(label, { fontSize: widget.fontSize });
    const box = kind === "Toggle" ? widget.fontSize * scale * 1.6 : 0;
    const w = Math.max(first[0], Math.ceil(m.width + 2 * 20 + box + EXTRA[kind]));
    const h = Math.max(first[1], Math.ceil(widget.fontSize * scale * 1.3));
    widget.size = [w, h];
  }
}

function* descendants(entity) {
  yield entity;
  for (const child of entity.children) yield* descendants(child);
}
