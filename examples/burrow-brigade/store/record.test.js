// Records the input replays the store screenshots and the trailer are made from: four bots on four gamepads play a floor and
// every stick and button they press is written out in the format of `factoria run --input` (docs/AI_GUIDE.md 11.2).
// Not part of `factoria test` (it is outside tests/): `python3 store/make_store.py record` runs it and keeps the output.
// Each floor is saved with `fa.call("fs.write")` to .factoria/tmp/record_<name>.json as JSON: { name, frames, outcome, replay, marks }. `marks` lists frames worth a screenshot
// (an enemy next to a miner, ore picked, a torch put down, a mole freed), so the screenshots are chosen from what happened.
import { test, describe, game } from "factoria:test";
import { fa } from "factoria";
import { cleanBeforeEach } from "../tests/helpers/world.js";
import { botsForAll, MinerBot } from "../tests/helpers/bot.js";
import * as players from "../scripts/game/players.js";
import * as events from "../scripts/game/events.js";
import { run } from "../scripts/game/run_state.js";
import { live } from "../scripts/game/mine_map.js";
import { K } from "../scripts/game/tiles.js";

const FLOORS = [
  { name: "topsoil", frames: 3600 },
  { name: "crystal", frames: 3600 },
  { name: "magma", frames: 3600 },
  { name: "king", frames: 1700 },
];

let frame = 0;
/** Ore tiles a bot is already going for. */
const claimed = new Set();
let log = {};
let state = {};

/** A bot that also writes down what it presses, and (for a livelier clip) mines a few ore veins and puts a torch down on the way. */
class RecordingBot extends MinerBot {
  ores = 0;
  target = null;
  torchAt = 0;
  update(dt) {
    // the four leave the lift one after the other and each goes for its own ore, so they spread out in the picture
    if (frame < this.pad * 40) return this.release();
    const e = this.entity;
    if (e && live.map && run.inShift && this.player.state === "active") {
      const here = live.map.tileAt(e.position.x, e.position.y);
      // a torch: B for three frames, once, after a short walk
      if (this.torchAt === 0 && frame > 40 + this.pad * 25) {
        this.torchAt = frame;
        this.pushButton("B", true);
      } else if (this.torchAt && frame === this.torchAt + 3) this.pushButton("B", false);
      if (this.target && !isOre(live.map.kindAt(this.target.tx, this.target.ty))) {
        claimed.delete(`${this.target.tx},${this.target.ty}`);
        this.target = null;
        this.ores++;
      }
      if (!this.target && this.ores < 3) {
        this.target = nearestOre(here, 9);
        if (this.target) claimed.add(`${this.target.tx},${this.target.ty}`);
      }
      if (this.target) {
        const exit = live.mine.exit;
        live.mine.exit = this.target;
        try {
          super.update(dt);
        } finally {
          live.mine.exit = exit;
        }
        return;
      }
    }
    super.update(dt);
  }
  pushButton(name, down) {
    const pad = game.gamepad(this.pad);
    if (down) pad.press(name);
    else pad.release(name);
    log[frame] ??= [];
    log[frame].push({ index: this.pad, buttons: { [name]: down } });
  }
  apply(x, y, dig) {
    const wasDig = this.dig;
    super.apply(x, y, dig);
    if (this.pad < 0) return;
    const prev = state[this.pad] ?? { x: 0, y: 0, dig: false };
    const entry = {};
    if (Math.abs(x - prev.x) > 0.001 || Math.abs(y - prev.y) > 0.001) entry.axes = { LeftX: +x.toFixed(3), LeftY: +y.toFixed(3) };
    if (dig !== wasDig) entry.buttons = { A: dig };
    if (entry.axes || entry.buttons) {
      log[frame] ??= [];
      log[frame].push({ index: this.pad, ...entry });
    }
    state[this.pad] = { x, y, dig };
  }
}

function isOre(kind) {
  return kind === K.COPPER || kind === K.SILVER || kind === K.GOLD || kind === K.GEM;
}

/** The nearest ore tile within `r` tiles (straight distance), or null. */
function nearestOre(here, r) {
  let best = null, bd = Infinity;
  for (let ty = here.ty - r; ty <= here.ty + r; ty++)
    for (let tx = here.tx - r; tx <= here.tx + r; tx++) {
      if (!isOre(live.map.kindAt(tx, ty)) || claimed.has(`${tx},${ty}`)) continue;
      const d = Math.hypot(tx - here.tx, ty - here.ty);
      if (d < bd) { bd = d; best = { tx, ty }; }
    }
  return best;
}

describe("record the store replays", () => {
  cleanBeforeEach();
  for (const floor of FLOORS) {
    test(`record ${floor.name}`, () => {
      frame = 0;
      claimed.clear();
      log = {};
      state = {};
      game.load(`store/scenes/play_${floor.name}.scene.json`);
      for (let i = 0; i < 4; i++) game.gamepad(i).connect();
      /** @type {RecordingBot[]} */
      let bots = [];
      const marks = [];
      const note = (what, extra = {}) => marks.push({ frame, what, ...extra });
      let outcome = "timeout";
      for (; frame < floor.frames; frame++) {
        if (frame > 5 && !run.inShift) {
          outcome = run.lastShift ? run.lastShift.outcome : "none";
          break;
        }
        if (bots.length === 0 && players.count() > 0) {
          bots = players.all().map((p) => new RecordingBot(p.id));
          // startRun (the scene's set-up) cleared the bus, so listen only now
          events.on("orePicked", (d) => note("ore", { ore: d.ore }));
          events.on("torchPlaced", () => note("torch"));
          events.on("moleRescued", () => note("mole"));
          events.on("enemyHit", (d) => note("enemyHit", { enemy: d.kind }));
          events.on("enemyDefeated", (d) => note("enemyDefeated", { enemy: d.kind }));
        }
        for (const b of bots) b.update(1 / 60);
        if (frame > 30 && frame % 10 === 0 && live.mine) {
          // how far apart the miners are: a screenshot with all four in view is picked from these
          const ms = game.world.findByTag("miner");
          let spread = 0;
          for (const a of ms) for (const b of ms) spread = Math.max(spread, Math.hypot(a.position.x - b.position.x, a.position.y - b.position.y));
          note("spread", { spread: Math.round(spread), miners: ms.length });
          // an enemy next to a miner: a candidate for the fight screenshot
          const miners = game.world.findByTag("miner");
          for (const e of game.world.findByTag("enemy")) {
            const b = e.behaviour;
            if (!b || b.dead) continue;
            const ep = e.position;
            if (miners.some((m) => Math.hypot(m.position.x - ep.x, m.position.y - ep.y) < 40)) {
              note("enemyNear", { enemy: b.kind });
              break;
            }
          }
        }
        game.step(1);
      }
      const frames = {};
      frames["0"] = { gamepad: [0, 1, 2, 3].map((index) => ({ index, connected: true })) };
      for (const [f, list] of Object.entries(log)) {
        frames[f] = frames[f] ?? {};
        // one entry per pad and frame: its axes and its buttons together
        const byPad = {};
        for (const item of list) {
          const m = (byPad[item.index] ??= { index: item.index });
          if (item.axes) m.axes = item.axes;
          if (item.buttons) m.buttons = { ...(m.buttons ?? {}), ...item.buttons };
        }
        frames[f].gamepad = [...(frames[f].gamepad ?? []), ...Object.values(byPad)];
      }
      fa.call("fs.write", {
        path: `.factoria/tmp/record_${floor.name}.json`,
        content: JSON.stringify({ name: floor.name, frames: frame, outcome, replay: { frames }, marks }),
      });
    });
  }
});
