// @ts-check
// Strategy-camera maths (pure). A view is { x, y, zoom }: the world point at the centre of the screen and the pixels per
// world unit. The engine camera is orthographic with orthoSize = half the visible height in world units, so
// orthoSize = designHeight / 2 / zoom (the rig writes it; scripts/game/camera_rig.js).

export const DESIGN = { width: 1280, height: 720 };

/** @typedef {{ x: number, y: number, zoom: number }} View */
/** @typedef {{ minX: number, maxX: number, minY: number, maxY: number }} Bounds */

export const ZOOM_MIN = 0.35;
export const ZOOM_MAX = 2.5;

export const clamp = (v, lo, hi) => (v < lo ? lo : v > hi ? hi : v);

/** orthoSize for a zoom. */
export function orthoSizeFor(zoom, screen = DESIGN) {
  return screen.height / 2 / zoom;
}

/** World position under a screen pixel (top-left origin, +Y down), for a view. @returns {[number, number]} */
export function screenToWorld(view, sx, sy, screen = DESIGN) {
  return [view.x + (sx - screen.width / 2) / view.zoom, view.y - (sy - screen.height / 2) / view.zoom];
}

/** Screen pixel of a world position, for a view. @returns {[number, number]} */
export function worldToScreen(view, wx, wy, screen = DESIGN) {
  return [(wx - view.x) * view.zoom + screen.width / 2, (view.y - wy) * view.zoom + screen.height / 2];
}

/**
 * Keep the screen centre inside the map rectangle grown by `margin` world units. When the whole (grown) map is smaller
 * than the screen along an axis, that axis is centred on the map.
 * @param {View} view @param {Bounds} bounds
 * @returns {View} a new view
 */
export function clampView(view, bounds, margin = 0, screen = DESIGN) {
  const halfW = screen.width / 2 / view.zoom;
  const halfH = screen.height / 2 / view.zoom;
  const minX = bounds.minX - margin + halfW;
  const maxX = bounds.maxX + margin - halfW;
  const minY = bounds.minY - margin + halfH;
  const maxY = bounds.maxY + margin - halfH;
  const x = minX > maxX ? (bounds.minX + bounds.maxX) / 2 : clamp(view.x, minX, maxX);
  const y = minY > maxY ? (bounds.minY + bounds.maxY) / 2 : clamp(view.y, minY, maxY);
  return { x, y, zoom: view.zoom };
}

/**
 * Change the zoom keeping the world point under the screen pixel (sx, sy) where it is (zoom towards the cursor).
 * The result is clamped to [ZOOM_MIN, ZOOM_MAX] but NOT to the bounds: call clampView after.
 * @param {View} view
 * @returns {View}
 */
export function zoomAt(view, newZoom, sx, sy, screen = DESIGN) {
  const zoom = clamp(newZoom, ZOOM_MIN, ZOOM_MAX);
  const [px, py] = screenToWorld(view, sx, sy, screen);
  return {
    x: px - (sx - screen.width / 2) / zoom,
    y: py + (sy - screen.height / 2) / zoom,
    zoom,
  };
}

/** One wheel notch is a 15 % zoom step (the wheel is signed: up = in). */
export function zoomStep(zoom, notches) {
  return clamp(zoom * Math.pow(1.15, notches), ZOOM_MIN, ZOOM_MAX);
}
