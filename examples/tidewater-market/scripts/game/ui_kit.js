// @ts-check
// Small pieces the panels of ui_hud.js are made of (engine-facing: it creates entities). Nothing here knows the game.
//   spawn helpers   panel / label / button / rule / icon: one line each instead of a JSON blob per widget
//   Tooltips        a tooltip after the pointer rests on a registered widget; placed so it never leaves the screen
//   inside          is a screen point inside the rectangle of a widget?
//   setUiScale      the "UI scale" option: the engine has none (rotation and scale of UI entities are ignored, FB-0042), so the
//                   helpers scale the sizes, paddings and spacings they were given and remember them to scale again
// Colours are in COLORS so every panel looks the same; fonts are the default font at FONT sizes (ui.textScale scales them all).
import { world, ui } from "factoria";
import { DESIGN } from "./camera_math.js";

export const COLORS = {
  panel: [0.05, 0.07, 0.1, 0.92],
  button: [0.17, 0.21, 0.28, 1],
  buttonActive: [0.33, 0.52, 0.72, 1],
  buttonWarn: [0.45, 0.2, 0.18, 1],
  text: [0.92, 0.94, 0.97, 1],
  dim: [0.62, 0.68, 0.76, 1],
  gold: [1, 0.82, 0.38, 1],
  red: [1, 0.5, 0.45, 1],
  green: [0.55, 0.9, 0.55, 1],
  blue: [0.55, 0.78, 1, 1],
  rule: [1, 1, 1, 0.14],
};
export const FONT = { title: 20, body: 16, small: 14 };

// ---- UI scale ------------------------------------------------------------------------------------------------------------------

let uiScale = 1;
/** @type {{ entity: any, component: string, base: Record<string, any> }[]} what to scale again, with the sizes as the code gave them */
let tracked = [];

/** The scale the helpers apply now (1 = as written). */
export function currentUiScale() {
  return uiScale;
}

const mul = (list, k) => (Array.isArray(list) ? list.map((n) => Math.round(n * k * 100) / 100) : list);

function applyScaled(rec) {
  const c = rec.entity.get(rec.component);
  for (const [field, value] of Object.entries(rec.base)) c[field] = typeof value === "number" ? Math.round(value * uiScale * 100) / 100 : mul(value, uiScale);
}

/** Remember the sizes of `entity` so setUiScale can scale them again, and apply the scale now. */
function track(entity, component, base) {
  if (!Object.keys(base).length) return;
  const rec = { entity, component, base };
  tracked.push(rec);
  if (uiScale !== 1) applyScaled(rec);
}

/**
 * The UI scale option: every size, padding and spacing the helpers below were given is multiplied by `scale` (widgets grow, so do
 * hit targets). Text follows ui.textScale instead; the two are separate options. Called by settings.apply().
 */
export function setUiScale(scale) {
  uiScale = scale > 0 ? scale : 1;
  tracked = tracked.filter((r) => r.entity.alive);
  for (const rec of tracked) applyScaled(rec);
}

/** Layers: the map's own sprites are below 100, the bars at 200, panels 230, notices 240, the drag chip 280, the tooltip 300. */
export const LAYER = { bar: 200, panel: 230, notice: 240, drag: 280, tooltip: 300 };

/** @param {any} entity @returns {boolean} */
export function isActive(entity) {
  return !!entity && entity.activeInHierarchy !== false;
}

/** Is the screen point (x, y) inside the widget's rectangle? Hidden widgets have none. */
export function inside(entity, x, y) {
  if (!isActive(entity)) return false;
  const r = ui.rectOf(entity);
  return !!r && x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h;
}

/**
 * A Panel. layout "column" | "row" | "none"; fit = sized by its children. position is where `pivot` sits, measured from
 * `anchor` (screen fractions); +Y is down.
 * @param {string} id @param {any} parent entity, id, or null for the root of the scene
 * @param {Record<string, any>} [props] Panel fields, plus `position`
 */
export function panel(id, parent, props = {}) {
  const { position = [0, 0, 0], ...rest } = props;
  const spec = { id, components: { Transform: { position }, Panel: { color: COLORS.panel, layer: LAYER.panel, ...rest } } };
  const entity = world.spawn(spec, parent ? { parent } : undefined);
  const base = {};
  for (const field of ["size", "padding", "spacing"]) if (rest[field] !== undefined) base[field] = rest[field];
  track(entity, "Panel", base);
  return entity;
}

/** A Text label in screen space. `position` only matters inside a layout "none" panel. */
export function label(id, parent, text, props = {}) {
  const { position = [0, 0, 0], ...rest } = props;
  const spec = {
    id,
    components: { Transform: { position }, Text: { text, fontSize: FONT.body, space: "screen", layer: LAYER.panel + 5, color: COLORS.text, ...rest } },
  };
  const entity = world.spawn(spec, parent ? { parent } : undefined);
  if (rest.maxWidth) track(entity, "Text", { maxWidth: rest.maxWidth }); // the wrap width grows with the UI scale, like the boxes
  return entity;
}

/** A text Button (the label may hold line breaks). */
export function button(id, parent, text, props = {}) {
  const { position = [0, 0, 0], ...rest } = props;
  const spec = {
    id,
    components: { Transform: { position }, Button: { text, size: [120, 30], fontSize: FONT.body, layer: LAYER.panel + 5, color: COLORS.button, ...rest } },
  };
  const entity = world.spawn(spec, parent ? { parent } : undefined);
  track(entity, "Button", { size: rest.size || [120, 30] });
  return entity;
}

/** A thin line across a column, which also gives a fitted panel its minimum width. */
export function rule(id, parent, width, height = 2, color = COLORS.rule) {
  return panel(id, parent, { size: [width, height], color, layout: "none", padding: [0, 0, 0, 0] });
}

/** A sprite from the atlas, drawn in screen space and scaled to fit a box (its aspect ratio stays). */
export function icon(id, parent, atlas, frameName, box, props = {}) {
  const f = atlas.frames[frameName];
  const [, , w, h] = f.rect;
  const k = Math.min(box / w, box / h);
  const { position = [0, 0, 0], ...rest } = props;
  const size = [Math.round(w * k), Math.round(h * k)];
  const spec = {
    id,
    components: {
      Transform: { position },
      Sprite: { texture: atlas.texture, region: f.rect, size, space: "screen", layer: LAYER.panel + 5, pixelArt: false, ...rest },
    },
  };
  const entity = world.spawn(spec, parent ? { parent } : undefined);
  track(entity, "Sprite", { size: rest.size || size });
  return entity;
}

/** Point the sprite of `entity` at another atlas frame, scaled into the box. */
export function setIcon(entity, atlas, frameName, box) {
  const f = atlas.frames[frameName];
  const [, , w, h] = f.rect;
  const k = Math.min(box / w, box / h);
  const s = entity.get("Sprite");
  s.region = f.rect;
  const size = [Math.round(w * k), Math.round(h * k)];
  const rec = tracked.find((r) => r.entity.id === entity.id && r.component === "Sprite");
  if (rec) rec.base = { size };
  s.size = mul(size, uiScale);
}

export function setActive(entity, on) {
  if (entity.active !== on) entity.active = on;
}

/**
 * Tooltips for widgets. `add(target, content)`: content() runs every frame while the tooltip shows and returns
 * `{ title, lines: [{ text, color? }] }` (or null for "no tooltip now"), so a tooltip is always as fresh as the numbers it names.
 * The tooltip appears after `delay` seconds of the pointer resting on the target (moving less than `slop` pixels), goes
 * away with any bigger move, and is placed at the pointer, flipped to the other side near the screen's edges.
 * One Panel in a column holds a pool of Text lines (a line has one colour; there is no rich text, see ENGINE_FEEDBACK).
 */
export class Tooltips {
  /** @param {{ delay?: number, slop?: number, maxLines?: number, width?: number }} [options] */
  constructor(options = {}) {
    this.delay = options.delay ?? 0.4;
    this.slop = options.slop ?? 5;
    this.width = options.width ?? 300;
    const maxLines = options.maxLines ?? 8;
    this.root = panel("tooltip", null, {
      anchor: [0, 0], pivot: [0, 1], layout: "column", fit: true, spacing: 3, padding: [10, 8, 10, 8], align: "start",
      color: [0.03, 0.04, 0.07, 0.96], layer: LAYER.tooltip,
    });
    this.root.position = [-4000, -4000, 0];
    this.title = label("tooltip_title", this.root, "", { fontSize: FONT.title - 2, color: COLORS.gold, maxWidth: this.width, layer: LAYER.tooltip + 5 });
    this.lines = [];
    for (let i = 0; i < maxLines; i++) this.lines.push(label(`tooltip_line_${i}`, this.root, "", { fontSize: FONT.small + 1, maxWidth: this.width, layer: LAYER.tooltip + 5 }));
    /** @type {Array<{ target: any, content: () => any }>} */
    this.entries = [];
    /** @type {((x: number, y: number) => any) | null} */
    this.fallback = null;
    this.fallbackEntry = { target: null, content: () => (this.fallback ? this.fallback(this.last.x, this.last.y) : null) };
    this.current = null;
    this.rest = 0;
    this.last = { x: -1, y: -1 };
    this.visible = false;
    this.hide();
  }

  /** Register a tooltip for a widget (an entity). Registering the same entity again replaces it. */
  add(target, content) {
    const at = this.entries.findIndex((e) => e.target === target);
    if (at >= 0) this.entries[at].content = content;
    else this.entries.push({ target, content });
  }

  remove(target) {
    this.entries = this.entries.filter((e) => e.target !== target);
    if (this.current && this.current.target === target) this.current = null;
  }

  /** The registered entry whose widget is under a point (the last registered wins, so a panel's children beat the panel). */
  find(x, y) {
    for (let i = this.entries.length - 1; i >= 0; i--) {
      const e = this.entries[i];
      if (inside(e.target, x, y) && e.content()) return e;
    }
    // `fallback` is for what is not a widget (a building on the map): a function (x, y) -> content or null
    if (this.fallback && this.fallback(x, y)) return this.fallbackEntry;
    return null;
  }

  hide() {
    this.visible = false;
    this.root.position = [-4000, -4000, 0];
  }

  /** Call once per frame with the pointer position and the frame's real seconds. `blocked`: a drag is going on, show none. */
  update(dt, mouse, blocked = false) {
    const moved = Math.hypot(mouse.x - this.last.x, mouse.y - this.last.y) > this.slop;
    if (moved) this.last = { x: mouse.x, y: mouse.y };
    const hit = blocked ? null : this.find(mouse.x, mouse.y);
    if (moved || hit !== this.current) {
      if (this.visible) this.hide();
      this.rest = 0;
      this.current = hit;
    }
    if (!this.current) return;
    this.rest += dt;
    if (this.rest < this.delay) return;
    this.show(this.current.content(), mouse);
  }

  show(content, mouse) {
    if (!content) return this.hide();
    this.title.get("Text").text = content.title || "";
    setActive(this.title, !!content.title);
    this.lines.forEach((e, i) => {
      const line = content.lines && content.lines[i];
      setActive(e, !!line);
      if (line) {
        const t = e.get("Text");
        t.text = line.text;
        t.color = line.color || COLORS.text;
      }
    });
    ui.layout();
    const r = ui.rectOf(this.root);
    const w = r ? r.w : this.width;
    const h = r ? r.h : 60;
    this.root.position = placeTooltip(mouse, w, h);
    this.visible = true;
  }
}

/**
 * Where a w x h tooltip goes for a pointer: below-right of it (the panel's pivot is its top-left corner, so the position is
 * that corner); on the other side when it would cross the screen's right or bottom edge; never off the top or left.
 * @returns {number[]} the Transform position [x, y, 0]
 */
export function placeTooltip(mouse, w, h, screen = DESIGN, gap = 16) {
  let x = mouse.x + gap;
  let top = mouse.y + gap + 6;
  if (x + w > screen.width - 4) x = mouse.x - gap - w;
  if (top + h > screen.height - 4) top = mouse.y - gap - h;
  x = Math.max(4, Math.min(x, screen.width - w - 4));
  top = Math.max(4, top);
  return [x, top, 0];
}
