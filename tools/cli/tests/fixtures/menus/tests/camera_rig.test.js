import { test, expect, game } from "factoria:test";
import { camera, input, ui } from "factoria";

// The strategy camera (scripts/camera_rig.js) and the camera helpers it uses (camera.zoomAt, panBy, clampTo, setZoom).
// The scene is built here: a camera with the rig, a 2000 x 1200 map and a ScrollList with more rows than it shows.
function open(rig = {}) {
  game.loadJson({
    format: "factoria.scene/1",
    entities: [
      {
        id: "camera",
        components: {
          Transform: { position: [0, 0, 0] },
          Camera: { projection: "orthographic", orthoSize: 360 },
          Script: { path: "scripts/camera_rig.js", props: { boundsEntity: "map", startZoom: 1, edgeSize: 0, ...rig } },
        },
      },
      { id: "map", components: { Transform: { position: [0, 0, 0] }, Sprite: { size: [2000, 1200], color: "#335577" } } },
      {
        id: "list",
        components: { ScrollList: { size: [300, 200], anchor: [0.95, 0.1], pivot: [1, 0], spacing: 4 } },
        children: Array.from({ length: 20 }, (_, i) => ({ id: `row${i}`, components: { Text: { text: `Row ${i}`, fontSize: 24, space: "screen" } } })),
      },
    ],
  });
  game.step(2);
  return game.find("camera");
}

// camera.screenToWorld answers for the frame last drawn: step once after a change before asking
const world = (x, y) => {
  game.step(1);
  return camera.screenToWorld({ x, y });
};
const near = (a, b) => expect(a).toBeCloseTo(b, 3);

test("camera.zoomAt keeps the world point under the cursor at every zoom from 0.4 to 2.5", () => {
  open({ frozen: true });
  for (const [sx, sy] of [[100, 100], [640, 360], [900, 500], [10, 700]]) {
    for (const zoom of [0.4, 0.8, 1, 1.7, 2.5]) {
      camera.setZoom(1, game.find("camera"));
      game.find("camera").position = [30, -50, 0];
      const before = world(sx, sy);
      const now = camera.zoomAt({ x: sx, y: sy }, zoom);
      near(now, zoom);
      near(camera.zoomOf(), zoom);
      near(game.find("camera").get("Camera").orthoSize, camera.orthoSizeFor(zoom));
      const after = world(sx, sy);
      near(after.x, before.x);
      near(after.y, before.y);
    }
  }
});

test("camera.panBy moves the world with the pointer and clampTo keeps the view inside a rectangle", () => {
  const cam = open({ frozen: true });
  camera.setZoom(2);
  cam.position = [0, 0, 0];
  const grabbed = world(500, 300);
  camera.panBy({ x: 60, y: 40 });
  const moved = world(560, 340);
  near(moved.x, grabbed.x);
  near(moved.y, grabbed.y);
  cam.position = [5000, 5000, 0];
  camera.clampTo({ x: -1000, y: -600, w: 2000, h: 1200 });
  near(cam.position.x, 1000 - 640 / 2);
  near(cam.position.y, 600 - 360 / 2);
  camera.setZoom(0.2); // the 2000 x 1200 map is smaller than the view: centred
  camera.clampTo({ x: -1000, y: -600, w: 2000, h: 1200 }, { margin: 0 });
  near(cam.position.x, 0);
  near(cam.position.y, 0);
  expect(() => camera.zoomAt({ x: 0, y: 0 }, 0)).toThrow();
});

test("the wheel zooms the rig towards the cursor between zoomMin and zoomMax", () => {
  const cam = open();
  const rig = cam.behaviour;
  cam.position = [0, 0, 0];
  game.mouseMove({ x: 400, y: 250 });
  game.step(1);
  const before = world(400, 250);
  game.wheel(3);
  game.step(1);
  expect(rig.view.zoom).toBeGreaterThan(1);
  near(world(400, 250).x, before.x);
  near(world(400, 250).y, before.y);
  game.wheel(-60);
  game.step(1);
  near(rig.view.zoom, rig.zoomMin);
  game.wheel(90);
  game.step(1);
  near(rig.view.zoom, rig.zoomMax);
});

test("a wheel over a ScrollList scrolls the list and does not zoom", () => {
  const rig = open().behaviour;
  const r = ui.rectOf("list");
  game.mouseMove({ x: r.x + r.w / 2, y: r.y + r.h / 2 });
  game.step(2);
  const zoom = rig.view.zoom;
  game.wheel(3);
  game.step(1);
  expect(ui.wheelConsumed).toBe(true);
  near(rig.view.zoom, zoom);
  game.mouseMove({ x: 200, y: 200 }); // the same wheel over the bare map zooms
  game.step(2);
  game.wheel(3);
  game.step(1);
  expect(rig.view.zoom).toBeGreaterThan(zoom);
});

test("a drag pans the view, but not one that starts over the UI", () => {
  const cam = open();
  const rig = cam.behaviour;
  cam.position = [0, 0, 0];
  game.step(1);
  game.mouseMove({ x: 300, y: 300 });
  game.step(1);
  const grabbed = world(300, 300);
  game.mouseDown("middle");
  game.step(1);
  game.mouseMove({ x: 360, y: 340 });
  game.step(1);
  game.mouseUp("middle");
  game.step(1);
  near(world(360, 340).x, grabbed.x);
  near(world(360, 340).y, grabbed.y);

  const at = { x: cam.position.x, y: cam.position.y };
  const r = ui.rectOf("list");
  game.mouseMove({ x: r.x + 20, y: r.y + 20 });
  game.step(2);
  game.mouseDown("middle");
  game.step(1);
  game.mouseMove({ x: r.x - 100, y: r.y + 80 });
  game.step(2);
  game.mouseUp("middle");
  game.step(1);
  near(cam.position.x, at.x);
  near(cam.position.y, at.y);
  expect(rig.dragging).toBe(false);
});

test("the view never leaves the map: keys, edge scrolling and zooming out are all clamped", () => {
  const cam = open({ margin: 50, edgeSize: 8 });
  const rig = cam.behaviour;
  const inside = () => {
    const z = rig.view.zoom;
    const hw = 640 / z;
    const hh = 360 / z;
    const p = cam.position;
    const okX = hw * 2 > 2100 ? Math.abs(p.x) < 1e-3 : p.x - hw >= -1050 - 1e-3 && p.x + hw <= 1050 + 1e-3;
    const okY = hh * 2 > 1300 ? Math.abs(p.y) < 1e-3 : p.y - hh >= -650 - 1e-3 && p.y + hh <= 650 + 1e-3;
    return okX && okY;
  };
  game.press("camera_right");
  game.press("camera_up");
  game.step(300);
  game.release("camera_right");
  game.release("camera_up");
  expect(inside()).toBe(true);
  near(cam.position.x, 1050 - 640);
  near(cam.position.y, 650 - 360);
  game.mouseMove({ x: 1, y: 719 }); // the bottom-left corner scrolls left and down, and stops at the map
  game.step(400);
  expect(inside()).toBe(true);
  near(cam.position.x, -1050 + 640);
  near(cam.position.y, -650 + 360);
  game.mouseMove({ x: 640, y: 360 });
  game.wheel(-60); // zoomed out to 0.4 the whole map fits the screen: pinned to its centre
  game.step(2);
  expect(inside()).toBe(true);
  near(cam.position.x, 0);
  expect(input.mouse.wheel).toBe(0);
});

test("moveTo eases to a view and instantMoves jumps there", () => {
  const cam = open();
  const rig = cam.behaviour;
  rig.moveTo(300, 100, 1.5);
  game.step(5);
  expect(cam.position.x).toBeGreaterThan(0);
  expect(cam.position.x).toBeLessThan(300);
  game.step(60);
  near(cam.position.x, 300);
  near(cam.position.y, 100);
  near(rig.view.zoom, 1.5);
  rig.instantMoves = true;
  rig.moveTo(-200, 0, 1);
  near(cam.position.x, -200);
});
