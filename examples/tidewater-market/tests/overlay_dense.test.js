// P7: the map overlays must read over a dense town. They used to be ground diamonds under the buildings (layer 3), so a town
// full of roofs hid them; they are drawn over the buildings and the walkers (LAYER.field), and the colour-blind safe pips sit on
// a dark plate above that.
import { test, expect, game } from "factoria:test";
import { townScene } from "./ui_helper.js";
import { LAYER } from "../scripts/game/map_view.js";
import * as settings from "../scripts/settings.js";

/** The active overlay diamonds of this frame as { layer, colour, size }. */
function shapes(ctl) {
  return ctl.view.pool
    .filter((e) => e.active)
    .map((e) => {
      const s = e.get("Shape2D");
      return { layer: s.layer, color: [...s.color], size: [...s.size], filled: s.filled };
    });
}

test("overlays: the field is drawn above the buildings, brighter for a higher value", () => {
  const { hud, ctl, ids, state } = townScene();
  hud.setOverlay("market");
  game.step(3);
  const field = shapes(ctl).filter((s) => s.layer === LAYER.field);
  expect(field.length).toBeGreaterThan(20);
  expect(LAYER.field).toBeGreaterThan(LAYER.object);
  expect(shapes(ctl).filter((s) => s.layer === LAYER.highlight && s.filled && s.color[3] < 0.5).length).toBe(0);
  // no pips without the option
  expect(shapes(ctl).filter((s) => s.layer === LAYER.fieldMark).length).toBe(0);
  // the brightness carries the value: the cell of the market is brighter than the edge of its reach
  const lum = (c) => c[0] + c[1] + c[2];
  const values = hud.overlayCache.values;
  const w = state.map.width;
  const cells = hud.overlayCache.cells.filter((i) => values[i] > 0);
  const strong = cells.reduce((a, b) => (values[b] > values[a] ? b : a));
  const weak = cells.reduce((a, b) => (values[b] < values[a] ? b : a));
  expect(values[strong]).toBeGreaterThan(values[weak]);
  expect(ids.market).toBeDefined();
  expect(w).toBeGreaterThan(0);
  // a level of the field's colour: brightness is monotonic in the value
  const tint = (v) => {
    const shade = 0.12 + 0.88 * v;
    return lum([1 * shade, 0.8 * shade, 0.25 * shade]);
  };
  expect(tint(values[strong])).toBeGreaterThan(tint(values[weak]));
  expect(lum(field[0].color)).toBeGreaterThan(0);
});

test("overlays: with safe colours every field cell also has a white pip on a dark plate, bigger for a higher value", () => {
  const { hud, ctl } = townScene();
  settings.preview({ safeColors: true });
  hud.setOverlay("market");
  game.step(3);
  const all = shapes(ctl);
  const tints = all.filter((s) => s.layer === LAYER.field);
  const plates = all.filter((s) => s.layer === LAYER.fieldPlate);
  const marks = all.filter((s) => s.layer === LAYER.fieldMark);
  expect(tints.length).toBeGreaterThan(20);
  expect(plates.length).toBe(tints.length);
  expect(marks.length).toBe(tints.length);
  // the plate is dark, the mark is white and smaller than its plate, and there are at least two sizes of mark
  for (const p of plates) expect(p.color[0] + p.color[1] + p.color[2]).toBeLessThan(0.5);
  for (const m of marks) expect(m.color[0] + m.color[1] + m.color[2]).toBeGreaterThan(2.9);
  expect(new Set(marks.map((m) => m.size[0].toFixed(1))).size).toBeGreaterThanOrEqual(2);
  // a pip is smaller than the cell and the plate under it is bigger than the pip
  for (let i = 0; i < marks.length; i++) expect(plates[i].size[0]).toBeGreaterThan(marks[i].size[0] - 0.01);
  settings.preview({ safeColors: false });
});
