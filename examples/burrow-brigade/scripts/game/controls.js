// @ts-check
// Each player's own controls. A player (a seat, P1 to P4) has a binding list per action (left, right, up, down, dig, torch) for
// its keyboard and another for its gamepad; the device the player joined with decides which list counts. What the player
// rebound is saved (settings.playerBindings, by seat); what it did not rebind comes from the defaults below.
//
// Why this exists: the engine's actions (factoria.json) answer to ANY pad and the rebinding of `input.rebind` is global, while
// `input.gamepad(i)` only knows raw button names (docs: scripting, input; ENGINE_FEEDBACK FB-0006). So the game keeps the
// per-player action sets itself: a binding is a key name ("Space") or a gamepad name ("GamepadA", "GamepadLeftStickLeft",
// the same names `input.lastPressed()` returns, so the Options page can rebind with it) and is read from the right device here.
import { input } from "factoria";
import * as settings from "../settings.js";
import { KEY_SCHEMES } from "./players.js";

/** The actions of a miner, in the order the Options page lists them. */
export const ACTIONS = Object.freeze(["left", "right", "up", "down", "dig", "torch"]);

/** Second (third...) key of an action for a key scheme, besides the one in KEY_SCHEMES. */
const EXTRA_KEYS = { keyboard: { left: ["Left"], right: ["Right"], up: ["Up"], down: ["Down"], dig: ["J"], torch: ["E"] } };

/** Gamepad defaults: left stick or d-pad to walk, A or X to dig, B or Y for a torch. */
export const PAD_DEFAULTS = Object.freeze({
  left: ["GamepadLeftStickLeft", "GamepadDpadLeft"],
  right: ["GamepadLeftStickRight", "GamepadDpadRight"],
  up: ["GamepadLeftStickUp", "GamepadDpadUp"],
  down: ["GamepadLeftStickDown", "GamepadDpadDown"],
  dig: ["GamepadA", "GamepadX"],
  torch: ["GamepadB", "GamepadY"],
});

/** @typedef {"keys"|"pad"} Family */
/** @typedef {Record<string, string[]>} BindingSet */

/** The family of a device: a pad player uses gamepad names, every other one key names. */
export function familyOf(device) {
  return device.kind === "pad" ? "pad" : "keys";
}

/** The default bindings of a device (a fresh object). */
export function defaults(device) {
  if (device.kind === "pad") return Object.fromEntries(ACTIONS.map((a) => [a, [...PAD_DEFAULTS[a]]]));
  const scheme = device.kind === "keys" ? device.scheme : "keyboard";
  const base = KEY_SCHEMES[scheme] ?? KEY_SCHEMES.keyboard;
  const extra = EXTRA_KEYS[scheme] ?? {};
  return Object.fromEntries(ACTIONS.map((a) => [a, [base[a], ...(extra[a] ?? [])]]));
}

/** @type {Record<string, {keys?: BindingSet, pad?: BindingSet}> | null} */
let saved = null;

function load() {
  if (!saved) saved = JSON.parse(JSON.stringify(settings.load().playerBindings ?? {}));
  return saved;
}

/** Forgets what was read from storage (a test that wipes the storage, or a settings change from outside). */
export function reload() {
  saved = null;
  memo.clear();
}

function persist() {
  memo.clear();
  const s = settings.load();
  s.playerBindings = JSON.parse(JSON.stringify(load()));
  settings.save(s);
}

/** What the seat rebound for one family (an empty object when nothing). */
export function overrides(seat, family) {
  return load()[String(seat)]?.[family] ?? {};
}

/** The bindings in force for a seat and a family: its own where it rebound an action, the defaults of `device` elsewhere. */
export function bindingsFor(seat, family, device) {
  const base = defaults(family === "pad" ? { kind: "pad", index: 0 } : device.kind === "pad" ? { kind: "keys", scheme: "keyboard" } : device);
  return { ...base, ...JSON.parse(JSON.stringify(overrides(seat, family))) };
}

/** @type {Map<string, BindingSet>} */
const memo = new Map();

/** The bindings of a player (by its device). Read every frame, so the answer is kept until something is rebound. */
export function bindingsOf(player) {
  const d = player.device;
  const key = `${player.id}|${d.kind}|${d.kind === "keys" ? d.scheme : ""}`;
  let b = memo.get(key);
  if (!b) {
    b = bindingsFor(player.id, familyOf(d), d);
    memo.set(key, b);
  }
  return b;
}

/**
 * Makes `names` the bindings of an action for a seat and a family, and saves them. The same names are taken away from the
 * seat's other actions of that family, so one key never does two things. Names that do not belong to the family (a key name for
 * the pad list, a "Gamepad..." one for the keyboard list) are an error.
 * @param {number} seat
 * @param {Family} family
 * @param {string} action
 * @param {string[]} names
 */
export function rebind(seat, family, action, names) {
  if (!ACTIONS.includes(action)) throw new Error(`controls.rebind: unknown action '${action}'. The actions are ${ACTIONS.join(", ")}.`);
  for (const n of names) {
    const pad = n.startsWith("Gamepad");
    if (pad !== (family === "pad")) throw new Error(`controls.rebind: '${n}' is not a ${family === "pad" ? "gamepad" : "keyboard"} binding (the ${family} list takes ${family === "pad" ? "Gamepad* names like GamepadA" : "key names like Space"}).`);
    if (!pad) input.keyDown(n); // an unknown key name throws here, with the engine's "did you mean"
  }
  const all = load();
  const entry = (all[String(seat)] ??= {});
  const current = bindingsFor(seat, family, family === "pad" ? { kind: "pad", index: 0 } : { kind: "keys", scheme: "keyboard" });
  const set = (entry[family] ??= {});
  for (const a of ACTIONS) {
    if (a === action) continue;
    const kept = (set[a] ?? current[a]).filter((n) => !names.includes(n));
    if (kept.length !== (set[a] ?? current[a]).length) set[a] = kept;
  }
  set[action] = [...names];
  persist();
}

/** Back to the defaults for one seat (both families). */
export function reset(seat) {
  delete load()[String(seat)];
  persist();
}

/** Back to the defaults for everybody. */
export function resetAll() {
  saved = {};
  persist();
}

/** 0..1 for one gamepad binding name on one pad ("GamepadA", "GamepadLeftStickLeft", "GamepadDpadUp", "GamepadRightTrigger"). */
export function padValue(pad, name) {
  const n = name.slice("Gamepad".length);
  const stick = /^(Left|Right)Stick(Left|Right|Up|Down)$/.exec(n);
  if (stick) {
    const v = pad.axis(stick[1] + (stick[2] === "Left" || stick[2] === "Right" ? "X" : "Y"));
    return Math.max(0, stick[2] === "Left" || stick[2] === "Down" ? -v : v);
  }
  if (n === "LeftTrigger" || n === "RightTrigger") return pad.axis(n);
  return pad.down(n) ? 1 : 0;
}

/** The strongest value of a list of binding names, read from the keyboard or from gamepad `index`. */
export function valueOf(names, device) {
  let v = 0;
  if (device.kind === "pad") {
    const pad = input.gamepad(device.index);
    for (const n of names) v = Math.max(v, padValue(pad, n));
  } else {
    for (const n of names) if (input.keyDown(n)) v = 1;
  }
  return v;
}

/** What a player sees for an action: the binding names for its family, as buttons ("Space / J", "A / X"). */
export function label(seat, family, action, padIndex = 0) {
  const names = bindingsFor(seat, family, family === "pad" ? { kind: "pad", index: padIndex } : { kind: "keys", scheme: "keyboard" })[action];
  if (!names || names.length === 0) return "-";
  return names.map((n) => input.buttonName(n, padIndex)).join(" / ");
}

