// @ts-check
// The results screen after a shift: how it ended, the ore by kind and its value, the time and the moles rescued. Two
// buttons: another shift (the same run, a new mine) or back to the title. The numbers are run.lastShift (run_state.js).
import { Behaviour, ui, world, scene, session } from "factoria";
import { run } from "./game/run_state.js";
import { ORES } from "./game/tiles.js";
import { clock } from "./game/hud.js";

export default class Results extends Behaviour {
  onStart() {
    const s = run.lastShift ?? { outcome: "lift", ore: {}, oreCount: 0, value: 0, banked: 0, time: 0, molesRescued: 0, molesTotal: 0, shiftNumber: 0 };
    const set = (id, args, key) => {
      const e = world.find(id);
      if (!e) throw new Error(`results: the scene has no entity '${id}' (see scenes/results.scene.json).`);
      e.set("Text", key ? { key, keyArgs: args } : { keyArgs: args });
    };
    set("results_title", { shift: s.shiftNumber }, s.outcome === "lift" ? "results.titleLift" : "results.titleDark");
    set("results_note", {}, s.outcome === "lift" ? "results.noteLift" : "results.noteDark");
    for (const o of ORES) set(`results_${o}`, { count: s.ore[o] ?? 0 });
    set("results_value", { value: s.value, banked: s.banked });
    set("results_time", { time: clock(s.time) });
    set("results_moles", { rescued: s.molesRescued, total: s.molesTotal });
    set("results_cash", { cash: run.cash });
    const target = scene.current;
    ui.on("click", "again", () => {
      if (scene.current !== target) return;
      session.nextScene = "scenes/shift.scene.json"; // the loading screen reads it, then starts the next shift
      scene.load("scenes/loading.scene.json");
    });
    ui.on("click", "to_title", () => {
      if (scene.current !== target) return;
      scene.load("scenes/menu.scene.json");
    });
  }
}
