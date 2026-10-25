// @ts-check
// The results screen after a shift: how it ended, the ore by kind and its value, the time and the moles rescued, and where the
// run goes next. The button takes the run there: the next floor (a deeper stratum after the third floor), the same floor again
// after a shift in the dark or with every miner down, or a new run after the Mole King. What comes next is decided by
// game/progression.js, nowhere else. The results also show the seed code of the mine just played, with a button that copies it. The numbers are run.lastShift (run_state.js).
import { Behaviour, ui, world, scene, i18n } from "factoria";
import { run } from "./game/run_state.js";
import { ORES } from "./game/tiles.js";
import { clock } from "./game/hud.js";
import { stratumInfo } from "./game/generator.js";
import { plan, go } from "./game/progression.js";
import * as codes from "./game/seed_code.js";
import * as clipboard from "./game/clipboard.js";

export default class Results extends Behaviour {
  onStart() {
    const s = run.lastShift ?? { outcome: "lift", stratum: run.stratum, floor: run.floor, ore: {}, oreCount: 0, value: 0, banked: 0, time: 0, molesRescued: 0, molesTotal: 0, shiftNumber: 0 };
    const next = plan(s);
    const set = (id, args, key) => {
      const e = world.find(id);
      if (!e) throw new Error(`results: the scene has no entity '${id}' (see scenes/results.scene.json).`);
      e.set("Text", key ? { key, keyArgs: args } : { keyArgs: args });
    };
    const kind = next.kind === "victory" ? "Victory" : s.outcome === "allDown" ? "AllDown" : s.outcome === "lift" ? "Lift" : "Dark";
    set("results_title", { shift: s.shiftNumber }, `results.title${kind}`);
    set("results_note", {}, `results.note${kind}`);
    for (const o of ORES) set(`results_${o}`, { count: s.ore[o] ?? 0 });
    set("results_value", { value: s.value, banked: s.banked });
    set("results_time", { time: clock(s.time) });
    set("results_moles", { rescued: s.molesRescued, total: s.molesTotal });
    set("results_cash", { cash: run.cash });
    const fillNext = () => {
      const e = /** @type {any} */ (world.find("results_next"));
      if (!e) throw new Error("results: the scene has no entity 'results_next' (see scenes/results.scene.json).");
      if (next.kind === "victory") {
        e.set("Text", { key: "results.victoryEnd", keyArgs: {} });
        return;
      }
      const key = next.kind === "retry" ? "results.retry" : next.boss ? "results.nextBoss" : "results.next";
      e.set("Text", { key, keyArgs: { stratum: i18n.t(stratumInfo(next.stratum).name), floor: next.floor } });
    };
    fillNext();
    i18n.on("change", fillNext);
    const button = /** @type {any} */ (world.find("again"));
    button.set("Button", { key: next.kind === "victory" ? "results.newRun" : next.kind === "retry" ? "results.retryFloor" : "results.nextFloor" });
    const code = codes.encode({ seed: s.seed ?? run.seed, stratum: s.stratum, floor: s.floor }); // the mine just played
    set("results_seed", { code });
    const target = scene.current;
    ui.on("click", "copy_code", () => {
      if (scene.current !== target) return;
      const done = clipboard.copy(code);
      /** @type {any} */ (world.find("results_message")).set("Text", { key: done.system ? "results.copied" : "results.copiedSession", keyArgs: { code } });
    });
    ui.on("click", "again", () => {
      if (scene.current !== target) return;
      go(next);
    });
    ui.on("click", "to_title", () => {
      if (scene.current !== target) return;
      scene.load("scenes/menu.scene.json");
    });
  }
}
