// The descent: three strata of three floors, what comes after a shift (progression.js), the look and the music of each stratum.
import { test, describe, expect, game } from "factoria:test";
import { scene } from "factoria";
import { cleanBeforeEach, playGenerated, miner, enemyList, teleport } from "./helpers/world.js";
import { live } from "../scripts/game/mine_map.js";
import { run } from "../scripts/game/run_state.js";
import { STRATA, TOTAL_FLOORS, isBossFloor, stratumInfo } from "../scripts/game/generator.js";
import { plan, FLOORS_PER_STRATUM } from "../scripts/game/progression.js";
import { tilesetOf } from "../scripts/game/tiles.js";
import * as music from "../scripts/game/music.js";
import * as players from "../scripts/game/players.js";

const SECOND = 60;
const SHIFT = "scenes/shift.scene.json";
const RESULTS = "scenes/results.scene.json";

const lift = (stratum, floor) => ({ outcome: "lift", stratum, floor });

describe("the plan after a shift", () => {
  test("three strata of three floors; the boss floor is the last floor of the last stratum only", () => {
    expect(STRATA.length).toBe(3);
    expect(FLOORS_PER_STRATUM).toBe(3);
    expect(TOTAL_FLOORS).toBe(9);
    const bosses = [];
    for (let s = 0; s < 3; s++) for (let f = 1; f <= 3; f++) if (isBossFloor(s, f)) bosses.push([s, f]);
    expect(bosses).toEqual([[2, 3]]);
  });

  test("a lift goes to the next floor, and after the third floor to the first floor of the next stratum", () => {
    expect(plan(lift(0, 1))).toMatchObject({ kind: "next", stratum: 0, floor: 2, newStratum: false, boss: false });
    expect(plan(lift(0, 3))).toMatchObject({ kind: "next", stratum: 1, floor: 1, newStratum: true, boss: false });
    expect(plan(lift(1, 3))).toMatchObject({ kind: "next", stratum: 2, floor: 1, newStratum: true });
    expect(plan(lift(2, 2))).toMatchObject({ kind: "next", stratum: 2, floor: 3, newStratum: false, boss: true });
  });

  test("walking the plan from the first floor reaches the boss in 8 steps and then the victory", () => {
    let at = { stratum: 0, floor: 1 };
    const seen = [`${at.stratum}/${at.floor}`];
    for (let i = 0; i < 20; i++) {
      const p = plan({ outcome: "lift", ...at });
      if (p.kind === "victory") break;
      at = { stratum: p.stratum, floor: p.floor };
      seen.push(`${at.stratum}/${at.floor}`);
    }
    expect(seen).toEqual(["0/1", "0/2", "0/3", "1/1", "1/2", "1/3", "2/1", "2/2", "2/3"]);
    expect(plan(lift(2, 3))).toMatchObject({ kind: "victory", boss: true });
  });

  test("a shift in the dark or with everyone down plays the same floor again", () => {
    expect(plan({ outcome: "dark", stratum: 1, floor: 2 })).toMatchObject({ kind: "retry", stratum: 1, floor: 2, newStratum: false });
    expect(plan({ outcome: "allDown", stratum: 2, floor: 3 })).toMatchObject({ kind: "retry", stratum: 2, floor: 3, boss: true });
  });

  test("every stratum has a name key, an ambient colour, a tileset and a music file of its own", () => {
    expect(new Set(STRATA.map((s) => s.music)).size).toBe(3);
    expect(new Set(STRATA.map((s) => s.name)).size).toBe(3);
    expect(new Set([0, 1, 2].map(tilesetOf)).size).toBe(3);
    expect(new Set(STRATA.map((s) => s.ambient.join())).size).toBe(3);
    expect(stratumInfo(99)).toBe(STRATA[2]); // past the end uses the last
  });
});

describe("the look and the music of a stratum", () => {
  cleanBeforeEach();
  for (const [stratum, floor] of [[0, 1], [1, 2], [2, 1]]) {
    test(`stratum ${stratum}: its tileset, ambient light and track`, () => {
      playGenerated(stratum, floor, 1234, 1);
      const info = stratumInfo(stratum);
      expect(game.find("mine").get("Tilemap").tileset).toBe(tilesetOf(stratum));
      expect(game.world.settings.ambientLight).toEqual(info.ambient);
      expect(game.audioLog()).toContainPlayed(info.music, { bus: "music" });
      expect(music.current()).toBe(info.music);
      for (const other of STRATA) if (other !== info) expect(game.audioLog()).not.toContainPlayed(other.music);
    });
  }

  test("the same stratum plays the same track on every floor; the next stratum changes it", () => {
    playGenerated(0, 1);
    playGenerated(0, 2);
    const first = STRATA[0].music;
    expect(game.audioLog().filter((l) => l.music && l.path === first).length).toBe(2); // each scene load stopped it, each shift starts it
    expect(music.play(0)).toBe(false);
    playGenerated(1, 1);
    expect(music.current()).toBe(STRATA[1].music);
    expect(game.audioLog()).toContainPlayed(STRATA[1].music);
    expect(music.play(2)).toBe(true);
  });

  test("the HUD names the stratum the miners are in", () => {
    playGenerated(1, 2);
    expect(game.find("hud_stratum").get("Text").text).toBe("Crystal Caves");
    playGenerated(2, 1);
    expect(game.find("hud_stratum").get("Text").text).toBe("Magma Deep");
  });
});

/** Takes the single miner to the exit lift, ends the shift and waits for the results scene. */
function liftUp() {
  if (run.exitLocked) enemyList("king")[0].hit(999, { x: 0, y: 0 }, 0);
  const e = live.mine.exit;
  teleport(miner(), e.tx, e.ty);
  game.step(3);
  expect(run.lastShift.outcome).toBe("lift");
  game.step(2 * SECOND);
  expect(scene.current).toBe(RESULTS);
}

function nextFloor() {
  game.click("again");
  game.step(5);
  game.step(40);
  expect(scene.current).toBe(SHIFT);
  game.step(3);
}

describe("down the whole mine through the results screen", () => {
  cleanBeforeEach();
  test("nine floors: each results screen names the next stratum, the look follows, the boss floor is the ninth", () => {
    playGenerated(0, 1, 1234, 1);
    const visited = [];
    for (let i = 0; i < TOTAL_FLOORS; i++) {
      visited.push([run.stratum, run.floor]);
      expect(game.find("mine").get("Tilemap").tileset).toBe(tilesetOf(run.stratum));
      expect(live.mine.stratum).toBe(run.stratum);
      expect(live.mine.floor).toBe(run.floor);
      expect(live.mine.boss).toBe(isBossFloor(run.stratum, run.floor));
      if (i === TOTAL_FLOORS - 1) break;
      liftUp();
      const p = plan(run.lastShift);
      const next = game.find("results_next").get("Text").text;
      expect(next).toContain(stratumInfo(p.stratum).id === "topsoil" ? "Topsoil" : stratumInfo(p.stratum).id === "crystalCaves" ? "Crystal Caves" : "Magma Deep");
      if (p.boss) expect(next.toLowerCase()).toContain("king");
      nextFloor();
    }
    expect(visited).toEqual([[0, 1], [0, 2], [0, 3], [1, 1], [1, 2], [1, 3], [2, 1], [2, 2], [2, 3]]);
    expect(music.current()).toBe(STRATA[2].music);
  });

  test("the Mole King's lift ends the run: the results say victory and the button starts a new run", () => {
    playGenerated(2, 3, 1234, 1);
    expect(enemyList("king").length).toBe(1);
    liftUp();
    expect(game.find("results_title").get("Text").text).toBe("The Mole King is beaten!");
    expect(game.find("results_next").get("Text").text.length).toBeGreaterThan(0);
    nextFloor();
    expect(run.stratum).toBe(0);
    expect(run.floor).toBe(1);
    expect(run.shiftNumber).toBe(1);
    expect(game.find("mine").get("Tilemap").tileset).toBe(tilesetOf(0));
  });

  test("everyone down: the results say so, bank nothing, and the button plays the same floor again", () => {
    playGenerated(1, 2, 1234, 1);
    run.ore.gold = 3;
    const hash = live.mine.hash;
    players.setState(0, "down", "drowned");
    game.step(3);
    expect(run.lastShift.outcome).toBe("allDown");
    game.step(2 * SECOND);
    expect(scene.current).toBe(RESULTS);
    expect(game.find("results_title").get("Text").text).toBe("Everyone is down");
    expect(run.cash).toBe(0);
    nextFloor();
    expect([run.stratum, run.floor]).toEqual([1, 2]);
    expect(live.mine.hash).not.toBe(hash); // a new mine of the same floor
    expect(run.ore.gold).toBe(0);
  });

  test("leaving a shift for the title before the results delay passes does not open the results afterwards", () => {
    playGenerated(0, 1, 1234, 1);
    const e = live.mine.exit;
    teleport(miner(), e.tx, e.ty);
    game.step(3);
    expect(run.lastShift.outcome).toBe("lift");
    game.load("scenes/menu.scene.json");
    game.step(5 * SECOND);
    expect(scene.current).toBe("scenes/menu.scene.json");
  });
});
