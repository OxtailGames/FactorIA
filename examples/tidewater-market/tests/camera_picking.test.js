// The strategy camera and mouse picking: the cell under the mouse is the same at every zoom, the engine's own camera agrees with
// the one in scripts/game/camera_math.js, zooming keeps the point under the cursor, and the view never leaves the map.
import { test, expect, game } from "factoria:test";
import { camera } from "factoria";
import { cellToWorld, worldToCell, mapBounds } from "../scripts/game/iso.js";
import { clampView, zoomAt, zoomStep, screenToWorld, worldToScreen, orthoSizeFor, ZOOM_MIN, ZOOM_MAX } from "../scripts/game/camera_math.js";

function open() {
  game.load("scenes/game.scene.json", { testMap: true });
  game.step(2);
  return { ctl: game.find("controller").behaviour, rig: game.find("camera").behaviour };
}

test("iso maths: a cell and its world position round-trip, and the diamond is the pick area", () => {
  for (let r = 0; r < 12; r++) {
    for (let c = 0; c < 12; c++) {
      const [x, y] = cellToWorld(c, r);
      expect(worldToCell(x, y)).toEqual([c, r]);
      expect(worldToCell(x + 20, y)).toEqual([c, r]); // inside the 100 x 50 diamond
      expect(worldToCell(x, y + 11)).toEqual([c, r]);
      expect(worldToCell(x + 45, y)).toEqual([c, r]); // just inside the right corner
      expect(worldToCell(x + 55, y)).toEqual([c + 1, r - 1]); // just past it: the cell diagonally up-right
    }
  }
  // the cell diagonals: +c is down-right, +r is down-left
  const [x, y] = cellToWorld(5, 5);
  expect(worldToCell(x, y - 30)).toEqual([6, 6]); // straight down
  expect(worldToCell(x, y + 30)).toEqual([4, 4]); // straight up
  expect(worldToCell(x + 30, y - 15)).toEqual([6, 5]); // down-right
  expect(worldToCell(x - 30, y - 15)).toEqual([5, 6]); // down-left
});

test("camera maths: zooming towards a point keeps that point still", () => {
  const view = { x: 120, y: -400, zoom: 1 };
  for (const [sx, sy] of [[100, 100], [640, 360], [900, 500], [10, 700]]) {
    for (const z of [0.5, 0.8, 1.7, 2.5]) {
      const before = screenToWorld(view, sx, sy);
      const next = zoomAt(view, z, sx, sy);
      const after = screenToWorld(next, sx, sy);
      expect(after[0]).toBeCloseTo(before[0], 6);
      expect(after[1]).toBeCloseTo(before[1], 6);
      const back = worldToScreen(next, after[0], after[1]);
      expect(back[0]).toBeCloseTo(sx, 6);
      expect(back[1]).toBeCloseTo(sy, 6);
    }
  }
  expect(zoomAt(view, 100, 0, 0).zoom).toBe(ZOOM_MAX);
  expect(zoomAt(view, 0.0001, 0, 0).zoom).toBe(ZOOM_MIN);
  expect(zoomStep(1, 1)).toBeGreaterThan(1);
  expect(zoomStep(1, -1)).toBeLessThan(1);
  expect(orthoSizeFor(2)).toBe(180);
});

test("camera maths: the view is clamped to the map plus a margin, and centred when the map is smaller than the screen", () => {
  const b = { minX: -1000, maxX: 1000, minY: -600, maxY: 0 };
  const far = clampView({ x: 5000, y: 5000, zoom: 1 }, b, 100);
  expect(far.x).toBe(1100 - 640);
  expect(far.y).toBe(0 + 100 - 360);
  const low = clampView({ x: -5000, y: -5000, zoom: 1 }, b, 100);
  expect(low.x).toBe(-1100 + 640);
  expect(low.y).toBe(-700 + 360);
  // zoomed far out the map (2200 x 700 with margin) is smaller than the screen: pinned to its centre
  const out = clampView({ x: 300, y: 300, zoom: 0.2 }, b, 100);
  expect(out.x).toBe(0);
  expect(out.y).toBe(-300);
});

test("mouse picking: the hover cell is the cell under the mouse at every zoom, as the engine's camera sees it", () => {
  const { ctl, rig } = open();
  const [x0, y0] = cellToWorld(5, 4);
  for (const zoom of [0.4, 0.75, 1, 1.5, 2, 2.5]) {
    rig.setView(x0, y0, zoom);
    game.step(1);
    for (let dr = -1; dr <= 1; dr++) {
      for (let dc = -1; dc <= 1; dc++) {
        const c = 5 + dc;
        const r = 4 + dr;
        const [wx, wy] = cellToWorld(c, r);
        const [sx, sy] = rig.worldToScreen(wx, wy);
        game.mouseMove({ x: sx, y: sy });
        game.step(1);
        expect(ctl.hover).toEqual([c, r]);
        // the same answer from the engine's own camera (an independent check of camera_math.js)
        const w = camera.screenToWorld({ x: sx, y: sy });
        expect(worldToCell(w[0], w[1])).toEqual([c, r]);
        expect(Math.abs(w[0] - wx) < 1e-3 && Math.abs(w[1] - wy) < 1e-3).toBe(true);
        // the right corner of the diamond still belongs to the cell, just past it is the next one (when not under the HUD)
        const half = 50 * zoom;
        if (sx + half * 1.1 < 1000) {
          game.mouseMove({ x: sx + half * 0.9, y: sy });
          game.step(1);
          expect(ctl.hover).toEqual([c, r]);
          game.mouseMove({ x: sx + half * 1.1, y: sy });
          game.step(1);
          expect(ctl.hover).toEqual([c + 1, r - 1]);
        }
      }
    }
  }
});

test("the mouse over the HUD picks nothing on the map", () => {
  const { ctl, rig } = open();
  const [x0, y0] = cellToWorld(5, 4);
  rig.setView(x0, y0, 1);
  game.mouseMove({ x: 640, y: 360 });
  game.step(2);
  expect(ctl.hover).not.toBeNull();
  game.mouseMove({ x: 1100, y: 100 }); // the palette
  game.step(2);
  expect(ctl.hover).toBeNull();
  game.mouseMove({ x: 300, y: 20 }); // the top bar
  game.step(2);
  expect(ctl.hover).toBeNull();
  game.mouseMove({ x: 300, y: 705 }); // the status bar
  game.step(2);
  expect(ctl.hover).toBeNull();
});

test("the wheel zooms towards the cursor and the point under it stays put", () => {
  const { rig } = open();
  const [x0, y0] = cellToWorld(5, 4);
  rig.setView(x0, y0, 1);
  game.step(1);
  game.mouseMove({ x: 800, y: 250 });
  game.step(1);
  const before = camera.screenToWorld({ x: 800, y: 250 });
  game.wheel(3);
  game.step(1);
  expect(rig.view.zoom).toBeGreaterThan(1);
  expect(game.find("camera").get("Camera").orthoSize).toBeCloseTo(orthoSizeFor(rig.view.zoom), 4);
  const after = camera.screenToWorld({ x: 800, y: 250 });
  expect(after[0]).toBeCloseTo(before[0], 2);
  expect(after[1]).toBeCloseTo(before[1], 2);
  game.wheel(-40);
  game.step(1);
  expect(rig.view.zoom).toBe(ZOOM_MIN);
  game.wheel(60);
  game.step(1);
  expect(rig.view.zoom).toBe(ZOOM_MAX);
});

test("dragging with the right button moves the map under the cursor", () => {
  const { ctl, rig } = open();
  const [x0, y0] = cellToWorld(5, 4);
  rig.setView(x0, y0, 1);
  game.step(1);
  game.mouseMove({ x: 500, y: 300 });
  game.step(1);
  const grabbed = camera.screenToWorld({ x: 500, y: 300 });
  game.mouseDown("right");
  game.step(1);
  game.mouseMove({ x: 560, y: 340 });
  game.step(1);
  game.mouseMove({ x: 600, y: 350 });
  game.step(1);
  game.mouseUp("right");
  game.step(1);
  const now = camera.screenToWorld({ x: 600, y: 350 });
  expect(now[0]).toBeCloseTo(grabbed[0], 2);
  expect(now[1]).toBeCloseTo(grabbed[1], 2);
  expect(ctl.tool.kind).toBe("none");
});

test("the view never leaves the map: dragging, keys and zooming out are all clamped", () => {
  const { rig } = open();
  const b = mapBounds(12, 10);
  const m = rig.margin;
  rig.setView(0, 0, 1);
  game.step(1);
  game.press("pan_right");
  game.press("pan_up");
  game.step(240); // 4 seconds at 900 px/s is far more than the map is wide
  game.release("pan_right");
  game.release("pan_up");
  expect(rig.view.x).toBeCloseTo(b.maxX + m - 640 / rig.view.zoom, 3);
  expect(rig.view.y).toBeCloseTo(b.maxY + m - 360 / rig.view.zoom, 3);
  game.press("pan_left");
  game.press("pan_down");
  game.step(600);
  game.release("pan_left");
  game.release("pan_down");
  expect(rig.view.x).toBeCloseTo(b.minX - m + 640 / rig.view.zoom, 3);
  expect(rig.view.y).toBeCloseTo(b.minY - m + 360 / rig.view.zoom, 3);
  // zoomed far out the small map is centred and cannot be pushed off it
  game.wheel(-60);
  game.step(2);
  game.press("pan_right");
  game.step(60);
  game.release("pan_right");
  expect(rig.view.zoom).toBe(ZOOM_MIN);
  expect(rig.view.x).toBeCloseTo((b.minX + b.maxX) / 2, 3);
  // the engine's camera really is where the rig says
  expect(game.find("camera").position[0]).toBeCloseTo(rig.view.x, 3);
});

test("the screen edge scrolls the map once the mouse has moved, and not at all while the pointer is in the middle", () => {
  const { rig } = open();
  rig.setView(0, -150, 1);
  game.step(1);
  const x = rig.view.x;
  game.mouseMove({ x: 640, y: 360 });
  game.step(10);
  expect(rig.view.x).toBeCloseTo(x, 3);
  game.mouseMove({ x: 1, y: 360 });
  game.step(10);
  expect(rig.view.x).toBeLessThan(x);
});
