// The split screen option (Options > Video): with it off a leash keeps the miners together and one camera is drawn; with it on the
// miners may part and each group gets its own Camera entity with its own viewport (scripts/game/follow_camera.js draws the plan
// of scripts/game/camera_views.js).
import { test, describe, expect, game } from "factoria:test";
import { camera, storage, world } from "factoria";
import { playRows, miners, teleport } from "./helpers/world.js";
import { freshOnline } from "./helpers/online.js";
import * as views from "../scripts/game/camera_views.js";
import * as settings from "../scripts/settings.js";

const WIDE = ["B".repeat(80), "B.S" + ".".repeat(74) + "E.B", "B".repeat(80)];
const TALL = ["B".repeat(12), "B.S.......EB", ...Array.from({ length: 68 }, () => "B" + ".".repeat(10) + "B"), "B".repeat(12)];

function choose(patch) {
  const s = settings.load();
  Object.assign(s, patch);
  settings.save(s);
}

const near = (a, b, eps = 0.01) => Math.abs(a - b) <= eps;

describe("the split screen option", () => {
  freshOnline();

  test("it is off by default and then one camera covers the screen even when the miners are far apart", () => {
    expect(settings.load().splitScreen).toBe(false);
    expect(settings.splitScreenOn()).toBe(false);
    playRows(WIDE, { players: 2 });
    teleport(miners()[1], 70, 1);
    game.step(60);
    expect(views.current.mode).toBe("split"); // the plan is made either way...
    expect(camera.all.length).toBe(1); // ...but only drawn when the player chose it
    expect(world.find("camera").get("Camera").viewport).toEqual([0, 0, 1, 1]);
  });

  test("on: two far miners get two cameras, one per half, each showing its own miner", () => {
    choose({ splitScreen: true });
    playRows(WIDE, { players: 2 });
    teleport(miners()[1], 70, 1);
    game.step(90);
    const cams = camera.all;
    expect(cams.length).toBe(2);
    expect(cams[0].id).toBe(world.find("camera").id);
    const [left, right] = cams.map((c) => c.get("Camera").viewport);
    expect(near(left[0], 0) && near(left[1], 0) && left[2] < 0.5 && left[2] > 0.49 && near(left[3], 1)).toBe(true);
    expect(near(right[0] + right[2], 1) && right[0] > 0.5 && right[0] < 0.51 && near(right[3], 1)).toBe(true);
    // each miner is inside its own view and not in the other one
    const [m0, m1] = miners();
    const seen = (m, c, rect) => {
      const p = camera.worldToScreen(m.position, c);
      return p.x >= rect[0] * 1280 && p.x <= (rect[0] + rect[2]) * 1280 && p.y >= 0 && p.y <= 720;
    };
    expect(seen(m0, cams[0], left)).toBe(true);
    expect(seen(m1, cams[1], right)).toBe(true);
    expect(seen(m1, cams[0], left)).toBe(false);
    expect(seen(m0, cams[1], right)).toBe(false);
    // a click on a half belongs to that half's camera, and the world point under it is near that half's miner
    expect(camera.at([300, 360]).id).toBe(cams[0].id);
    expect(camera.at([1000, 360]).id).toBe(cams[1].id);
    expect(Math.abs(camera.screenToWorld([300, 360]).x - m0.position.x)).toBeLessThan(260);
    expect(Math.abs(camera.screenToWorld([1000, 360]).x - m1.position.x)).toBeLessThan(260);
  });

  test("the miners come together again: the extra camera goes away and the first one covers the screen", () => {
    choose({ splitScreen: true });
    playRows(WIDE, { players: 2 });
    teleport(miners()[1], 70, 1);
    game.step(60);
    expect(camera.all.length).toBe(2);
    teleport(miners()[1], 5, 1);
    game.step(90);
    expect(views.current.mode).toBe("shared");
    expect(camera.all.length).toBe(1);
    expect(world.find("camera").get("Camera").viewport).toEqual([0, 0, 1, 1]);
  });

  test("the leash is off with the option on and on with it off", () => {
    playRows(WIDE, { players: 2 });
    game.step(5);
    const a = miners()[0].position;
    const span = views.maxSpan().x;
    const from = { x: a.x + span - 10, y: a.y }, to = { x: a.x + span + 40, y: a.y };
    expect(views.limitMove(1, from, to)).toEqual(from); // off (default): refused, the miners stay within the largest view
    choose({ splitScreen: true });
    expect(views.limitMove(1, from, to)).toEqual(to); // on: the step is allowed, the screen will split instead
  });

  test("four miners in the four corners of a big mine get four quarter views", () => {
    choose({ splitScreen: true });
    const rows = ["B".repeat(80), ...Array.from({ length: 60 }, (_, i) => (i === 0 ? "B.S" + ".".repeat(74) + "E.B" : "B" + ".".repeat(78) + "B")), "B".repeat(80)];
    playRows(rows, { players: 4 });
    const [a, b, c, d] = miners();
    teleport(a, 3, 2);
    teleport(b, 75, 2);
    teleport(c, 3, 55);
    teleport(d, 75, 55);
    game.step(120);
    expect(camera.all.length).toBe(4);
    const rects = camera.all.map((e) => e.get("Camera").viewport);
    expect(rects.every((r) => r[2] > 0.49 && r[2] < 0.5 && r[3] > 0.49 && r[3] < 0.5)).toBe(true);
    // each quarter has a camera, and a click in each quarter picks a different camera
    const picked = [[320, 180], [960, 180], [320, 540], [960, 540]].map((p) => camera.at(p).id);
    expect(new Set(picked).size).toBe(4);
    // and each miner is seen by exactly one of the cameras (on the screen rectangle of that camera)
    for (const m of miners()) {
      const hits = camera.all.filter((e) => {
        const r = e.get("Camera").viewport;
        const p = camera.worldToScreen(m.position, e);
        return p.x >= r[0] * 1280 && p.x <= (r[0] + r[2]) * 1280 && p.y >= r[1] * 720 && p.y <= (r[1] + r[3]) * 720;
      });
      expect(hits.length).toBe(1);
    }
  });

  test("two far miners one above the other get a top half and a bottom half", () => {
    choose({ splitScreen: true });
    playRows(TALL, { players: 2 });
    teleport(miners()[1], 5, 60);
    game.step(90);
    const rects = camera.all.map((e) => e.get("Camera").viewport);
    expect(rects.length).toBe(2);
    expect(rects[0][3]).toBeLessThan(0.5);
    expect(rects[1][1]).toBeGreaterThan(0.5);
  });

  test("the cameras of the views are gone when the scene is left", () => {
    choose({ splitScreen: true });
    playRows(WIDE, { players: 2 });
    teleport(miners()[1], 70, 1);
    game.step(60);
    expect(camera.all.length).toBe(2);
    game.load("scenes/menu.scene.json");
    game.step(5);
    expect(camera.all.length).toBe(1);
    expect(views.current.mode).toBe("shared");
  });

  test("a view fits its miners: a cluster in a half-width view has the zoom its rectangle needs", () => {
    const planner = new views.ViewPlanner();
    const plan = planner.plan([{ id: 0, x: 0, y: 0 }, { id: 1, x: 150, y: 0 }, { id: 2, x: 3000, y: 0 }]);
    expect(plan.views.length).toBe(2);
    const v = plan.views[0];
    expect(v.aspect).toBeCloseTo(views.ASPECT / 2, 5);
    expect(v.ortho).toBeGreaterThanOrEqual(views.orthoFor([{ id: 0, x: 0, y: 0 }, { id: 1, x: 150, y: 0 }], views.MAX_ORTHO, v.aspect) - 1e-6);
    // 150 units across need (75 + margin) / aspect of half height in a half-width view: more than the full-width view would
    expect(v.ortho).toBeGreaterThanOrEqual(views.BASE_ORTHO);
    const g = views.gapped([0, 0, 0.5, 1]);
    expect(g[0]).toBe(0);
    expect(g[2]).toBeLessThan(0.5);
    const r = views.gapped([0.5, 0, 0.5, 1]);
    expect(r[0]).toBeGreaterThan(0.5);
    expect(r[0] + r[2]).toBeCloseTo(1, 9);
  });

  test("Options > Video has the toggle and it saves the choice", () => {
    game.load("scenes/menu.scene.json");
    game.step(5);
    game.click("options_button");
    game.step(3);
    game.click("tab_video");
    game.step(2);
    expect(game.find("split_screen").get("Toggle").value).toBe(false);
    game.click("split_screen");
    game.step(2);
    expect(storage.get("settings", {}).splitScreen).toBe(true);
    expect(settings.splitScreenOn()).toBe(true);
    game.click("split_screen");
    game.step(2);
    expect(storage.get("settings", {}).splitScreen).toBe(false);
    expect(settings.splitScreenOn()).toBe(false);
  });
});
