// P5: rich presence text (localized, plural) and the data tokens.
import { test, describe, expect, game } from "factoria:test";
import { i18n } from "factoria";
import * as events from "../scripts/game/events.js";
import * as presence from "../scripts/game/presence.js";
import * as players from "../scripts/game/players.js";
import { freshOnline, shift } from "./helpers/online.js";

const shown = () => game.platform.state().fake.presence;

describe("presence", () => {
  freshOnline();

  test("describe: one miner and three miners use the plural", () => {
    expect(presence.describe({ kind: "shift", stratum: 0, floor: 2, players: 1 }).text).toBe("Digging in the Topsoil, floor 2 (1 miner)");
    expect(presence.describe({ kind: "shift", stratum: 1, floor: 3, players: 3 }).text).toBe("Digging in the Crystal Caves, floor 3 (3 miners)");
  });

  test("describe: boss, results, menu and boards", () => {
    expect(presence.describe({ kind: "boss", players: 2 }).text).toBe("Fighting the Mole King (2 miners)");
    expect(presence.describe({ kind: "results", shift: 4, outcome: "lift" }).text).toBe("Back on the lift after shift 4");
    expect(presence.describe({ kind: "results", shift: 4, outcome: "dark" }).text).toBe("Lost shift 4 down the mine");
    expect(presence.describe({ kind: "menu" }).text).toBe("In the main menu");
    expect(presence.describe({ kind: "boards" }).text).toBe("Looking at the boards");
  });

  test("the data carries the steam_display token and string values", () => {
    const d = presence.describe({ kind: "shift", stratum: 2, floor: 1, players: 4 }).data;
    expect(d).toEqual({ steam_display: "#Digging", stratum: "Magma Deep", floor: "1", miners: "4" });
    expect(presence.describe({ kind: "menu" }).data.steam_display).toBe("#Menu");
    expect(presence.describe({ kind: "boss", players: 1 }).data.steam_display).toBe("#Boss");
  });

  test("a shift sends its text to the store, the end of it sends the result", async () => {
    shift({ stratum: 1, floor: 2, players: 2, outcome: "lift" }, () => {
      expect(true).toBe(true);
    });
    await presence.idle();
    expect(shown().text).toBe("Back on the lift after shift 1");
    const texts = game.platform.calls().filter((c) => c.method === "presence.set").map((c) => c.args.text);
    expect(texts).toEqual(["Digging in the Crystal Caves, floor 2 (2 miners)", "Back on the lift after shift 1"]);
  });

  test("the boss fight changes the text; the same text is not sent twice", async () => {
    events.emit("shiftStarted", { seed: 1, stratum: 2, floor: 3, hash: "x", players: 1 });
    events.emit("bossStarted", {});
    events.emit("bossStarted", {});
    await presence.idle();
    const texts = game.platform.calls().filter((c) => c.method === "presence.set").map((c) => c.args.text);
    expect(texts).toEqual(["Digging in the Magma Deep, floor 3 (1 miner)", "Fighting the Mole King (1 miner)"]);
  });

  test("a miner joining changes the count", async () => {
    events.emit("shiftStarted", { seed: 1, stratum: 0, floor: 1, hash: "x", players: 1 });
    players.add({ device: { kind: "keys", scheme: "wasd" } });
    players.add({ device: { kind: "pad", index: 0 } });
    events.emit("playerAdded", {});
    await presence.idle();
    expect(shown().text).toContain(`(${players.count()} miners)`);
    expect(players.count()).toBeGreaterThan(1);
  });

  test("without the presence service nothing is sent and nothing throws", async () => {
    game.platform.set({ backend: "none" });
    presence.set({ kind: "menu" });
    await presence.idle();
    expect(game.platform.calls().length).toBe(0);
    game.platform.reset();
  });

  test("forget() makes the same text go again (a resume from sleep)", async () => {
    presence.set({ kind: "menu" });
    presence.forget();
    presence.set({ kind: "menu" });
    await presence.idle();
    expect(game.platform.calls().filter((c) => c.method === "presence.set").length).toBe(2);
    expect(i18n.language).toBe("en");
  });
});
