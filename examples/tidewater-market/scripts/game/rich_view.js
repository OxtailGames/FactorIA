// @ts-check
// RichView: draws a block of rich text (richtext.js markup) as Text and Sprite entities at a screen position. One RichView is one
// block (a card body, an order line); `set` lays the markup out again and reuses its entities, so a panel that refreshes every
// second creates nothing after the first frame. Positions are screen design pixels, (x, y) is the top-left corner.
import { world, ui } from "factoria";
import { parseMarkup, layoutRich, colorOf } from "./richtext.js";

/** The pixel width of a string at a font size; the engine measures (approximately when headless), cached by size and string. */
const widthCache = new Map();
export function measureWidth(text, fontSize) {
  const key = `${fontSize}|${text}`;
  let w = widthCache.get(key);
  if (w === undefined) {
    w = text === "" ? 0 : ui.measureText(text, { fontSize, space: "screen" }).width;
    if (widthCache.size > 4000) widthCache.clear();
    widthCache.set(key, w);
  }
  return w;
}

export class RichView {
  /** @param {{ atlas: any, layer: number, parent?: any }} opts */
  constructor(opts) {
    this.atlas = opts.atlas;
    this.layer = opts.layer;
    this.parent = opts.parent || null;
    /** @type {any[]} */ this.texts = [];
    /** @type {any[]} */ this.icons = [];
    /** The last markup + box, so an unchanged block costs nothing. */
    this.key = "";
    /** What the last set() drew: { width, height, lines, items }. */
    this.last = { width: 0, height: 0, lines: 0, items: [] };
  }

  /**
   * Draw `markup` with its top-left corner at (x, y), wrapped at `maxWidth`.
   * @param {string} markup @param {{ x: number, y: number, maxWidth: number, fontSize?: number, lineHeight?: number }} box
   */
  set(markup, box) {
    const fontSize = box.fontSize || 20;
    const key = `${markup}|${box.x}|${box.y}|${box.maxWidth}|${fontSize}|${box.lineHeight || 0}`;
    if (key === this.key) return this.last;
    this.key = key;
    const { tokens } = parseMarkup(markup);
    const laid = layoutRich(tokens, { maxWidth: box.maxWidth, fontSize, measure: (s) => measureWidth(s, fontSize), lineHeight: box.lineHeight });
    let nt = 0;
    let ni = 0;
    for (const it of laid.items) {
      if (it.kind === "text") {
        // fake bold: the same word drawn twice, one pixel apart
        const passes = it.bold ? 2 : 1;
        for (let p = 0; p < passes; p++) {
          const e = this.textEntity(nt++);
          const t = e.get("Text");
          if (t.text !== it.text) t.text = it.text;
          t.fontSize = fontSize;
          t.color = colorOf(it.color) || [1, 1, 1, 1];
          e.position = [box.x + it.x + p, box.y + it.y, 0];
          e.active = true;
        }
      } else {
        const e = this.iconEntity(ni++);
        const frame = this.atlas.frames[`icon.${it.name}`];
        if (frame) e.get("Sprite").region = frame.rect;
        e.get("Sprite").size = [it.w, it.w];
        e.position = [box.x + it.x, box.y + it.y, 0];
        e.active = !!frame;
      }
    }
    for (let i = nt; i < this.texts.length; i++) this.texts[i].active = false;
    for (let i = ni; i < this.icons.length; i++) this.icons[i].active = false;
    this.last = { width: laid.width, height: laid.height, lines: laid.lines, items: laid.items };
    return this.last;
  }

  /** Hide the block. */
  clear() {
    this.key = "";
    for (const e of this.texts) e.active = false;
    for (const e of this.icons) e.active = false;
    this.last = { width: 0, height: 0, lines: 0, items: [] };
  }

  /** Remove every entity. */
  destroy() {
    for (const e of this.texts) e.destroy();
    for (const e of this.icons) e.destroy();
    this.texts = [];
    this.icons = [];
    this.key = "";
  }

  /** The strings drawn now, in order, without the bold duplicates (for tests). */
  drawnText() {
    return this.last.items.filter((i) => i.kind === "text").map((i) => i.text).join("");
  }

  textEntity(i) {
    if (!this.texts[i]) {
      this.texts[i] = world.spawn(
        { components: { Transform: { position: [0, 0, 0] }, Text: { text: "", fontSize: 20, space: "screen", anchor: [0, 0], pivot: [0, 1], layer: this.layer + 1 } } },
        this.parent ? { parent: this.parent } : undefined,
      );
    }
    return this.texts[i];
  }

  iconEntity(i) {
    if (!this.icons[i]) {
      this.icons[i] = world.spawn(
        {
          components: {
            Transform: { position: [0, 0, 0] },
            Sprite: { texture: this.atlas.texture, region: [0, 0, 1, 1], size: [20, 20], space: "screen", anchor: [0, 0], pivot: [0, 1], layer: this.layer + 1, pixelArt: false },
          },
        },
        this.parent ? { parent: this.parent } : undefined,
      );
    }
    return this.icons[i];
  }
}
