// @ts-check
// A gamepad unplugged during a shift. Put this Script on one entity of the shift scene. While every player's pad is plugged in it
// does nothing. When the pad of a player disappears the game PAUSES and a screen says "Reconnect the controller for P2". Then:
//  - the pad comes back (same slot): the game goes on;
//  - on any other free controller (a pad that nobody uses and that is plugged in) A hands that player's miner to it, and on the
//    keyboard Enter does, when no player uses the keyboard. This is also how a pad that came back in another slot rejoins: a
//    system gives an unplugged pad's slot to whichever pad turns up next, and the engine has no way to say which pad is which;
//  - another player drops the missing one with Y on their pad or Backspace on their keyboard: that miner leaves the mine.
// The pause is the same `game.paused` the pause menu uses; this script keeps running meanwhile (runWhilePaused) and only unpauses
// what it paused itself. Events: `controllerLost`, `controllerRestored`.
import { Behaviour, world, input, game } from "factoria";
import * as players from "./players.js";
import * as events from "./events.js";
import { run } from "./run_state.js";

export default class PadWatch extends Behaviour {
  runWhilePaused = true;

  onStart() {
    /** @type {number | null} */
    this.waitingFor = null; // the player id the screen is about
    this.owns = false; // this script paused the game
    this.ui = [];
    this.known = new Set(); // players already announced with controllerLost
  }

  onDestroy() {
    this.hideScreen();
    if (this.owns && game.paused) game.paused = false;
  }

  /** The players whose pad is not plugged in. */
  missing() {
    return players.all().filter((p) => p.device.kind === "pad" && !input.gamepad(p.device.index).connected);
  }

  onUpdate() {
    if (!run.inShift) return;
    const missing = this.missing();
    if (missing.length === 0) {
      if (this.waitingFor !== null) this.resume("reconnected", this.waitingFor);
      return;
    }
    for (const p of missing) {
      if (!this.known.has(p.id)) {
        this.known.add(p.id);
        events.emit("controllerLost", { player: p });
      }
    }
    if (!game.paused) {
      this.owns = true;
      game.paused = true;
    }
    const first = missing[0];
    if (this.waitingFor !== first.id) {
      this.waitingFor = first.id;
      this.showScreen(first);
      return; // the frame that shows the screen does not also read presses
    }
    this.choose(first);
  }

  /** Reads the presses of the other devices while the screen is up. */
  choose(first) {
    const padUsed = (i) => players.all().some((p) => p.id !== first.id && p.device.kind === "pad" && p.device.index === i);
    const keyboardUsed = players.all().some((p) => p.id !== first.id && p.device.kind !== "pad");
    // a free controller takes the miner
    for (let i = 0; i < players.MAX_PLAYERS; i++) {
      if (padUsed(i)) continue;
      const pad = input.gamepad(i);
      if (pad.connected && pad.pressed("A")) {
        players.setDevice(first.id, { kind: "pad", index: i });
        return this.resume("handedOver", first.id);
      }
    }
    if (!keyboardUsed && input.keyPressed("Enter")) {
      players.setDevice(first.id, { kind: "keys", scheme: "keyboard" });
      return this.resume("handedOver", first.id);
    }
    // another player drops the missing one
    for (const p of players.all()) {
      if (p.id === first.id) continue;
      const d = p.device;
      const drop = d.kind === "pad" ? input.gamepad(d.index).pressed("Y") : input.keyPressed("Backspace");
      if (drop) {
        this.dropPlayer(first.id);
        return this.resume("dropped", first.id);
      }
    }
  }

  /** Takes the player and its miner out of the mine. */
  dropPlayer(id) {
    for (const m of world.findByTag("miner")) if (m.behaviour && m.behaviour.playerId === id) m.destroy();
    players.remove(id);
  }

  resume(how, id) {
    this.waitingFor = null;
    this.known.delete(id);
    this.hideScreen();
    const player = players.get(id) ?? { id };
    events.emit("controllerRestored", { player, how });
    if (this.missing().length > 0) return; // another pad is still out: onUpdate shows its screen next frame
    if (this.owns) game.paused = false;
    this.owns = false;
  }

  showScreen(p) {
    this.hideScreen();
    const text = (key, y, size, color) =>
      world.spawn({
        components: {
          Transform: { position: [0, y, 0] },
          Text: { text: key, key, keyArgs: { player: p.name }, fontSize: size, space: "screen", anchor: [0.5, 0.5], pivot: [0.5, 0.5], align: "center", layer: 410, color },
        },
      });
    this.ui = [
      world.spawn({ components: { Transform: { position: [0, 0, 0] }, Shape2D: { shape: "rectangle", size: [4000, 2400], color: [0, 0, 0, 0.78], space: "screen", anchor: [0.5, 0.5], layer: 400 } } }),
      text("pads.lost", -60, 44, [p.color[0], p.color[1], p.color[2], 1]),
      text("pads.handOver", 20, 26, [1, 1, 1, 1]),
      text("pads.drop", 64, 26, [1, 1, 1, 1]),
    ];
  }

  hideScreen() {
    for (const e of this.ui) if (e.alive) e.destroy();
    this.ui = [];
  }
}
