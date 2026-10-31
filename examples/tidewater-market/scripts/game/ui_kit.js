// @ts-check
// Small pieces the panels of ui_hud.js are made of (engine-facing: it creates entities). Nothing here knows the game.
//   spawn helpers   panel / label / button / icon: one line each instead of a JSON blob per widget
//   Tooltips        a tooltip after the pointer rests on a registered widget; placed so it never leaves the screen
//   inside          is a screen point inside the rectangle of a widget?
//   toUnits         screen pixels (ui.rectOf, the pointer) -> UI units (sizes and positions of widgets), for the interface size option
// Colours are in COLORS so every panel looks the same; fonts are the default font at FONT sizes (ui.textScale scales them all).
import { world, ui } from "factoria";

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
};
export const FONT = { title: 20, body: 16, small: 14 };
/**
 * The panels are laid out for a 1280 x 720 screen, so the text size option stops growing their texts at this scale (maxTextScale);
 * a button that keeps its size also shrinks a label that still does not fit (autoShrink). A panel that has room for more passes its own cap.
 */
export const TEXT_CAP = 1.5;

// ---- Interface size ------------------------------------------------------------------------------------------------------------
// The "interface size" option is the engine's ui.scale: every size, offset, padding, spacing, margin and font below is written in
// UI units and the engine draws them ui.scale times as big, so no widget is registered or resized here. What is measured on the
// screen (ui.rectOf, the pointer, DESIGN) is in pixels; toUnits() turns such a length into the UI units a position takes.

/** A length in screen pixels as UI units at the current ui.scale (what Transform.position and Panel.size are written in). */
export function toUnits(px) {
  return px / ui.scale;
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
  return world.spawn(spec, parent ? { parent } : undefined);
}

/** A Text label in screen space. `position` only matters inside a layout "none" panel. */
export function label(id, parent, text, props = {}) {
  const { position = [0, 0, 0], ...rest } = props;
  const spec = {
    id,
    components: { Transform: { position }, Text: { text, fontSize: FONT.body, space: "screen", layer: LAYER.panel + 5, color: COLORS.text, maxTextScale: TEXT_CAP, ...rest } },
  };
  return world.spawn(spec, parent ? { parent } : undefined);
}

/** A text Button (the label may hold line breaks). */
export function button(id, parent, text, props = {}) {
  const { position = [0, 0, 0], ...rest } = props;
  const spec = {
    id,
    components: { Transform: { position }, Button: { text, size: [120, 30], fontSize: FONT.body, layer: LAYER.panel + 5, color: COLORS.button, autoShrink: true, minFontSize: 8, maxTextScale: TEXT_CAP, ...rest } },
  };
  return world.spawn(spec, parent ? { parent } : undefined);
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
  return world.spawn(spec, parent ? { parent } : undefined);
}

/** The Button fields (icon, iconRegion, iconSize) that draw an atlas frame inside a button, scaled into the box (its aspect ratio stays). */
export function buttonIcon(atlas, frameName, box) {
  const f = atlas.frames[frameName];
  const [, , w, h] = f.rect;
  const k = Math.min(box / w, box / h);
  return { icon: atlas.texture, iconRegion: f.rect, iconSize: [Math.round(w * k), Math.round(h * k)] };
}

/** Point the sprite of `entity` at another atlas frame, scaled into the box. */
export function setIcon(entity, atlas, frameName, box) {
  const f = atlas.frames[frameName];
  const [, , w, h] = f.rect;
  const k = Math.min(box / w, box / h);
  const s = entity.get("Sprite");
  s.region = f.rect;
  s.size = [Math.round(w * k), Math.round(h * k)];
}

export function setActive(entity, on) {
  if (entity.active !== on) entity.active = on;
}
