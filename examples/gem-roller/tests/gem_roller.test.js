import { test, expect, game } from "factoria:test";
import { fa } from "factoria";

const GEM = "assets/sfx/gem.wav";
const FALL = "assets/sfx/fall.wav";
const WIN = "assets/sfx/win.wav";
const LOSE = "assets/sfx/lose.wav";

function load() {
  game.load("scenes/main.scene.json");
  game.step(30); // let the ball land on the start platform
  return { ball: game.find("ball"), mgr: game.find("game").behaviour, cam: game.find("camera") };
}

// Put the ball somewhere by hand: the quickest way to reach a gem, a checkpoint or a platform.
function teleportOnto(ball, pos) {
  ball.position.x = pos.x; ball.position.y = pos.y; ball.position.z = pos.z;
  ball.get("RigidBody3D").velocity.y = 0;
}

test("ball moves forward (-Z) with input", () => {
  const { ball } = load();
  const z0 = ball.position.z;
  game.press("move_forward");
  game.step(30);
  game.release("move_forward");
  expect(ball.position.z).toBeLessThan(z0 - 1);
});

test("movement is relative to the camera yaw", () => {
  const { ball, cam } = load();
  // Orbit the camera with the real keys (Q / E) instead of poking its yaw: 90 deg/s, so one second.
  game.press("cam_right");
  game.step(60);
  game.release("cam_right");
  expect(cam.behaviour.yaw).toBeCloseTo(90, 0); // camera on the +X side looking toward -X
  const x0 = ball.position.x;
  game.press("move_forward");
  game.step(20);
  game.release("move_forward");
  expect(ball.position.x).toBeLessThan(x0 - 0.5);
});

test("ball reaches its top speed and stops almost at once", () => {
  const { ball } = load();
  const body = ball.get("RigidBody3D");
  game.press("move_forward");
  game.step(60);
  expect(-body.velocity.z).toBeCloseTo(8, 1); // Ball.maxSpeed, nothing (friction included) slows it
  game.release("move_forward");
  const z0 = ball.position.z;
  game.step(30);
  expect(Math.abs(body.velocity.z)).toBeLessThan(0.01);
  expect(z0 - ball.position.z).toBeLessThan(0.8); // 8 m/s at 30 m/s^2 stops in about 1 m
  expect(z0 - ball.position.z).toBeGreaterThan(0.3);
});

test("jump lifts the ball only while grounded", () => {
  const { ball } = load();
  const y0 = ball.position.y;
  let top = y0;
  game.press("jump"); game.step(1); game.release("jump");
  for (let i = 0; i < 90; i++) {
    if (i === 10) { game.press("jump"); game.step(1); game.release("jump"); } // in mid-air: no second jump
    game.step(1);
    top = Math.max(top, ball.position.y);
  }
  expect(top).toBeGreaterThan(y0 + 1.4);
  expect(top).toBeLessThan(y0 + 1.8); // one jump: 8 m/s up at 20 m/s^2 is 1.6 m
  expect(ball.position.y).toBeCloseTo(y0, 1); // and it landed again
});

test("the ball rolls: its spin follows the distance travelled", () => {
  const { ball } = load();
  const rot = ball.transform.rotation;
  expect(rot.x).toBe(0);
  game.step(30);
  expect(rot.x).toBe(0); // standing still, no spin
  const z0 = ball.position.z;
  game.press("move_forward");
  game.step(60);
  game.release("move_forward");
  const dist = z0 - ball.position.z;
  const rolled = -rot.x; // rolling toward -Z turns the ball about -X
  const expected = (dist / 0.5) * (180 / Math.PI); // arc length / radius, in degrees
  expect(dist).toBeGreaterThan(5);
  expect(Math.abs(rolled - expected)).toBeLessThan(expected * 0.05);
});

for (const id of ["mover_1", "mover_2"]) {
  test(`a kinematic platform carries the ball (${id})`, () => {
    const { ball } = load();
    const mover = game.find(id);
    teleportOnto(ball, { x: mover.position.x, y: mover.position.y + 1.1, z: mover.position.z });
    game.step(20); // land on it
    const off = { x: ball.position.x - mover.position.x, z: ball.position.z - mover.position.z };
    let drift = 0, lo = Infinity, hi = -Infinity;
    for (let i = 0; i < 36; i++) { // 6 s with no input: the ball never pushes itself
      game.step(10);
      const along = id === "mover_1" ? mover.position.x : mover.position.z;
      lo = Math.min(lo, along); hi = Math.max(hi, along);
      drift = Math.max(drift, Math.abs(ball.position.x - mover.position.x - off.x), Math.abs(ball.position.z - mover.position.z - off.z));
    }
    expect(hi - lo).toBeGreaterThan(2); // the platform really moved
    expect(drift).toBeLessThan(0.3); // and the ball stayed where it stood on it
    expect(ball.position.y).toBeGreaterThan(mover.position.y + 0.9);
  });
}

test("chase camera follows the ball", () => {
  const { ball, cam } = load();
  game.press("move_forward");
  game.step(20); // ~2 m, stays on the start platform
  game.release("move_forward");
  game.step(90);
  expect(Math.abs(cam.position.z - ball.position.z - 9)).toBeLessThan(1.5);
});

test("scatter_gems is deterministic and places gems on platforms", () => {
  load();
  const a = fa.call("project.scatter_gems", { count: 6, seed: 42, clear: true });
  game.step(1);
  const b = fa.call("project.scatter_gems", { count: 6, seed: 42, clear: true });
  const c = fa.call("project.scatter_gems", { count: 6, seed: 43, clear: true });
  expect(a.placed).toBe(6);
  expect(b.gems.map((g) => g.position)).toEqual(a.gems.map((g) => g.position));
  expect(c.gems.map((g) => g.position)).not.toEqual(a.gems.map((g) => g.position));
  for (const g of a.gems) {
    const plat = game.find(g.platform);
    const top = plat.position.y + plat.transform.scale.y / 2;
    expect(g.position[1]).toBeGreaterThan(top);
    expect(Math.abs(g.position[0] - plat.position.x)).toBeLessThan(plat.transform.scale.x / 2);
    expect(Math.abs(g.position[2] - plat.position.z)).toBeLessThan(plat.transform.scale.z / 2);
  }
});

test("scatter_gems reuses the ids of the gems it clears", () => {
  load();
  const ids = [1, 2, 3, 4, 5, 6].map((n) => `gem_${n}`);
  // Three scatters in a row, with no frame in between: every one gets gem_1 .. gem_6, never a renamed id.
  for (const seed of [1, 2, 3]) {
    const r = fa.call("project.scatter_gems", { count: 6, seed, clear: true });
    expect(r.gems.map((g) => g.id)).toEqual(ids);
  }
  const gems = game.world.findByTag("gem");
  expect(gems.map((g) => g.id).sort()).toEqual(ids);
  for (const id of ids) expect(game.find(id)).not.toBeNull();
});

test("picking up a gem increments the counter, plays the sound, sparkles and removes it", () => {
  const { ball, mgr } = load();
  expect(mgr.gems).toBe(0);
  expect(game.audioLog()).not.toContainPlayed(GEM);
  const gem = game.world.findByTag("gem")[0];
  const id = gem.id;
  const at = { x: gem.position.x, y: gem.position.y, z: gem.position.z };
  teleportOnto(ball, gem.position);
  game.step(3);
  expect(mgr.gems).toBe(1);
  expect(game.world.find(id)).toBeNull();
  expect(game.find("hud_gems").get("Text").text).toBe(`Gems 1/${mgr.total}`);
  expect(game.audioLog()).toContainPlayed(GEM, { times: 1, bus: "sfx" });
  // The burst is a one-shot emitter that removes itself when its last particle has died.
  const fx = game.world.findByTag("fx");
  expect(fx).toHaveLength(1);
  expect(fx[0].get("ParticleEmitter").autoDestroy).toBe(true);
  expect(Math.abs(fx[0].position.x - at.x)).toBeLessThan(0.3);
  game.step(90); // 1.5 s: longer than particle lifetime
  expect(game.world.findByTag("fx")).toHaveLength(0);
});

test("falling resets to the last checkpoint, costs time and plays the fall sound", () => {
  const { ball, mgr } = load();
  const t0 = mgr.timeLeft;
  // Roll off the back of the start platform and let the ball fall below killY.
  game.press("move_back");
  game.step(40);
  game.release("move_back");
  game.step(150);
  expect(game.find("ball").behaviour.falls).toBe(1);
  expect(ball.position.y).toBeGreaterThan(0);
  expect(Math.abs(ball.position.z - 2)).toBeLessThan(1); // start platform spawn
  expect(mgr.timeLeft).toBeLessThan(t0 - 5); // fallPenalty
  expect(mgr.timeLeft).toBeGreaterThan(t0 - 5 - 4); // plus the seconds that went by
  expect(game.audioLog()).toContainPlayed(FALL, { times: 1 });
  // touch checkpoint 1, then fall again: respawn there
  const cp = game.find("checkpoint_1");
  teleportOnto(ball, { x: cp.position.x, y: 1.2, z: cp.position.z });
  game.step(5);
  ball.position.y = -20;
  game.step(3);
  expect(Math.abs(ball.position.z - cp.position.z)).toBeLessThan(1);
  expect(game.audioLog()).toContainPlayed(FALL, { times: 2 });
});

test("timer counts down and, when it runs out, shows the lose screen and plays the lose sound", () => {
  const { ball, mgr } = load();
  const t0 = mgr.timeLeft;
  game.step(60);
  expect(mgr.timeLeft).toBeCloseTo(t0 - 1, 1);
  expect(game.find("hud_time").get("Text").text).toBe(`Time ${mgr.timeLeft.toFixed(1)}`);
  expect(game.audioLog()).not.toContainPlayed(LOSE);
  game.step(5400); // let the whole 90 s go by: stepping is cheap because tests do not draw
  expect(mgr.status).toBe("lost");
  expect(mgr.timeLeft).toBe(0);
  expect(game.find("hud_msg").get("Text").text).toBe("TIME'S UP");
  const overlay = game.find("overlay").get("Shape2D"); // the dimming overlay covers the whole screen
  expect(overlay.size.x).toBe(1280);
  expect(overlay.size.y).toBe(720);
  expect(overlay.color.a).toBeGreaterThan(0.5);
  expect(game.audioLog()).toContainPlayed(LOSE, { times: 1 });
  expect(game.audioLog()).not.toContainPlayed(WIN);
  // The ball is locked once the game is over.
  const z0 = ball.position.z;
  game.press("move_forward");
  game.step(30);
  game.release("move_forward");
  expect(Math.abs(ball.position.z - z0)).toBeLessThan(0.1);
});

test("collecting every gem wins, plays the win sound and stops the clock", () => {
  const { ball, mgr } = load();
  expect(game.audioLog()).not.toContainPlayed(WIN);
  for (const gem of game.world.findByTag("gem")) {
    teleportOnto(ball, gem.position);
    game.step(2);
  }
  expect(mgr.gems).toBe(mgr.total);
  expect(mgr.status).toBe("won");
  expect(game.find("hud_msg").get("Text").text).toBe("YOU WIN!");
  expect(game.audioLog()).toContainPlayed(GEM, { times: mgr.total });
  expect(game.audioLog()).toContainPlayed(WIN, { times: 1 });
  expect(game.audioLog()).not.toContainPlayed(LOSE);
  // A won game never turns into a lost one, however long it is left running.
  const left = mgr.timeLeft;
  game.step(5400);
  expect(mgr.status).toBe("won");
  expect(mgr.timeLeft).toBe(left);
  expect(game.audioLog()).not.toContainPlayed(LOSE);
});

test("restart key reloads the level", () => {
  const { ball, mgr } = load();
  teleportOnto(ball, game.world.findByTag("gem")[0].position);
  game.step(2);
  expect(mgr.gems).toBe(1);
  game.press("restart"); game.step(1); game.release("restart");
  game.step(2);
  const m2 = game.find("game").behaviour;
  expect(m2.gems).toBe(0);
  expect(m2.status).toBe("playing");
  expect(game.world.findByTag("gem")).toHaveLength(m2.total);
});

test("the HUD is pinned to the screen corners with anchor and pivot", () => {
  game.load("scenes/main.scene.json");
  // The behaviour exists right after game.load: the scene's props are already applied.
  expect(game.find("game").behaviour.timeLimit).toBe(90);
  const corner = (id, kind) => {
    const e = game.find(id);
    const c = e.get(kind);
    return { anchor: [c.anchor.x, c.anchor.y], pivot: [c.pivot.x, c.pivot.y], pos: [e.position.x, e.position.y] };
  };
  // Left panel and time hang from the top-left corner, right panel and gems from the top-right one.
  expect(corner("hud_panel_l", "Shape2D")).toEqual({ anchor: [0, 0], pivot: [0, 1], pos: [12, 12] });
  expect(corner("hud_panel_r", "Shape2D")).toEqual({ anchor: [1, 0], pivot: [1, 1], pos: [-12, 12] });
  expect(corner("hud_time", "Text")).toEqual({ anchor: [0, 0], pivot: [0, 1], pos: [28, 28] });
  expect(corner("hud_gems", "Text")).toEqual({ anchor: [1, 0], pivot: [1, 1], pos: [-28, 28] });
  // The message, its subtitle and the win/lose overlay are centred on the screen.
  for (const [id, kind] of [["hud_msg", "Text"], ["hud_sub", "Text"], ["overlay", "Shape2D"]]) {
    expect(corner(id, kind).anchor).toEqual([0.5, 0.5]);
    expect(corner(id, kind).pivot).toEqual([0.5, 0.5]);
  }
});

// Tests do not draw until something asks for a picture: a screenshot draws one frame, and the render stats in game.state()
// then say how many custom materials were drawn and which ones failed to build (drawn magenta instead).
test("the gems are drawn with the pulsing gem material, not the magenta error material", () => {
  load();
  game.step(2);
  const gem = game.world.findByTag("gem")[0];
  expect(gem.get("MeshRenderer").material).toBe("materials/gem.material.json");
  game.screenshot(".factoria/screenshots/gem-material.png");
  const stats = game.state().renderStats;
  expect(stats.meshes).toBeGreaterThan(0);
  const info = fa.call("material.info", { material: "materials/gem.material.json" });
  expect(info.params.map((p) => p.name).sort()).toEqual(["glow", "speed"]);
  if (info.compile.toolFound) {
    // The shader compiler is installed (CI always has it: docs/BUILDING.md): the material must build and draw.
    expect(stats.materialFallbacks).toEqual([]);
    expect(stats.materials).toBeGreaterThan(0);
  } else {
    // No sokol-shdc on this computer (`factoria setup shaders` installs it): the material cannot be built, so the engine
    // draws the gems magenta and says so. The game still plays; `factoria validate` warns that it could not compile it.
    expect(stats.materialFallbacks).toEqual(["materials/gem.material.json"]);
  }
});
