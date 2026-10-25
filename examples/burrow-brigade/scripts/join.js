// @ts-check
// The join screen between the title's Play and the shift (scenes/join.scene.json). Up to four players, each on its own device:
//   a gamepad:  A joins, B leaves, Start (the first player's) begins the shift;
//   the keyboard: Enter joins, Escape leaves, Enter (the first player's) begins the shift.
// With nobody joined, B or Escape goes back to the title. Everything is polled every frame, so a pad that is plugged in while this
// screen is open joins like any other: that is how a Steam Remote Play Together guest arrives (Steam shows a guest's controller to the
// game as one more gamepad), and a joined pad that is unplugged here leaves. One keyboard and three pads work, and so do four pads.
// The slot decides the colour and the name ("P1".."P4", players.js); the first player in the list is the host who starts the shift.
import { Behaviour, world, input, scene, session } from "factoria";
import * as players from "./game/players.js";

/** Seconds at the start in which presses are ignored: the press that clicked Play on the title must not also join. */
export const GRACE = 0.15;

export default class Join extends Behaviour {
  /** Scene the screen leads to, through the loading screen. */
  nextScene = "scenes/shift.scene.json";
  loadingScene = "scenes/loading.scene.json";
  titleScene = "scenes/menu.scene.json";

  onStart() {
    players.clear(); // coming here is a new group: nobody is in yet
    this.age = 0;
    this.left = false;
    this.shown = [];
    this.paint();
  }

  /** The player on a gamepad slot, or undefined. */
  onPad(i) {
    return players.all().find((p) => p.device.kind === "pad" && p.device.index === i);
  }

  /** The player on the keyboard, or undefined. */
  onKeyboard() {
    return players.all().find((p) => p.device.kind === "keys");
  }

  join(device) {
    if (players.count() >= players.MAX_PLAYERS) return null;
    return players.add({ device });
  }

  onUpdate(dt) {
    if (this.left) return;
    this.age += dt;
    if (this.age >= GRACE) this.poll();
    this.paint();
  }

  poll() {
    const host = () => players.all()[0];
    for (let i = 0; i < players.MAX_PLAYERS; i++) {
      const pad = input.gamepad(i);
      const mine = this.onPad(i);
      if (mine && !pad.connected) {
        players.remove(mine.id); // unplugged in the lobby: the slot is free again
        continue;
      }
      if (!pad.connected) continue;
      if (!mine) {
        if (pad.pressed("A")) this.join({ kind: "pad", index: i });
        else if (pad.pressed("B") && players.count() === 0) return this.toTitle();
      } else if (pad.pressed("B")) {
        players.remove(mine.id);
      } else if (pad.pressed("Start") && host() === mine) {
        return this.startShift();
      }
    }
    const kb = this.onKeyboard();
    if (input.keyPressed("Enter")) {
      if (!kb) this.join({ kind: "keys", scheme: "keyboard" });
      else if (host() === kb) return this.startShift();
    } else if (input.keyPressed("Escape")) {
      if (kb) players.remove(kb.id);
      else if (players.count() === 0) return this.toTitle();
    }
  }

  startShift() {
    if (players.count() === 0) return;
    this.left = true;
    session.nextScene = this.nextScene; // the loading screen reads it ahead of time, then loads it
    scene.load(this.loadingScene);
  }

  toTitle() {
    this.left = true;
    scene.load(this.titleScene);
  }

  /** Rewrites a slot's text only when it changed (the engine formats a translation again on every write). */
  paint() {
    const list = players.all();
    world.find("join_note").active = list.length === 0;
    for (let i = 0; i < players.MAX_PLAYERS; i++) {
      const p = list.find((q) => q.id === i);
      const state = p ? `${p.device.kind}:${p.device.kind === "pad" ? p.device.index : ""}:${p === list[0]}` : "";
      if (this.shown[i] === state) continue;
      this.shown[i] = state;
      const name = `P${i + 1}`;
      let key = "join.slotEmpty", args = { player: name };
      if (p) {
        const first = p === list[0];
        if (p.device.kind === "pad") {
          key = first ? "join.slotPadHost" : "join.slotPad";
          args = { player: name, pad: p.device.index + 1 };
        } else {
          key = first ? "join.slotKeyboardHost" : "join.slotKeyboard";
        }
      }
      world.find(`slot_${i}_text`).set("Text", { key, keyArgs: args });
      const c = p ? p.color : [0.3, 0.3, 0.3, 1];
      world.find(`slot_${i}_swatch`).set("Shape2D", { color: c });
      world.find(`slot_${i}_back`).set("Shape2D", { color: p ? [c[0] * 0.3, c[1] * 0.3, c[2] * 0.3, 0.7] : [0, 0, 0, 0.45] });
    }
  }
}
