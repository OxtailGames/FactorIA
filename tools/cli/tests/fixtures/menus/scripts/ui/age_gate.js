// @ts-check
// The age gate (prefabs/ui/age_gate.prefab.json): a neutral screen that asks for the birth YEAR, for a game whose
// factoria.json has platform.ads.audience "mixed" (children and adults play). It does not say which age matters, starts
// on no special year and lets the player decline. The answer goes to platform.ads.setUnderAge(), so the ad network treats a
// child as a child (no personalised ads, no consent sheet), and is kept in storage as a boolean: the birth year is not saved.
import { ui, world, storage, platform, game } from "factoria";
import { MenuStack } from "./menu_stack.js";

/** storage key of the saved answer: { underAge: boolean }. */
const KEY = "ageGate";
/** The highest age of consent in Europe (GDPR lets states pick 13 to 16). A year of birth alone is off by one, so the gate counts anyone born up to 16 years ago as a child. */
export const CONSENT_AGE = 16;

/** True when the player is a child by the birth year they gave, or declined to give one (declining counts as a child). */
export function isUnderAge(birthYear, year = game.today().year) {
  return birthYear === null || year - birthYear <= CONSENT_AGE;
}

/** The answer saved by an earlier run ({ underAge }), or null when the player has not answered. */
export function savedAge() {
  return storage.get(KEY, null);
}

/** Tells the ad network the answer the player gave in an earlier run. Does nothing when there is none. */
export function applySavedAge() {
  const saved = savedAge();
  if (saved) tell(saved.underAge === true);
}

/** Sends the answer to the ad network. A game without ads support, or a rejected call, still plays: ads just stay off. */
function tell(underAge) {
  platform.ads.setUnderAge(underAge).catch((e) => console.warn(`age gate: the ad network was not told: ${e.message}`));
}

/**
 * For a game with platform.ads.audience "mixed" (the main menu calls it only then), from the scene that opens first: opens the
 * gate over the menu when the player has not answered yet, otherwise tells the network the saved answer. `menus` is the
 * scene's MenuStack, `panel` the id of the gate's entity in the scene (prefabs/ui/age_gate.prefab.json). Returns true when
 * the gate is open. The player cannot close it with Back: an answer (or "I would rather not say") is needed.
 */
export function openAgeGate(menus, panel = "age_gate") {
  if (savedAge()) {
    applySavedAge();
    return false;
  }
  const field = world.find("birth_year");
  const slider = field.get("Slider");
  slider.max = game.today().year;
  slider.value = Math.min(slider.value, slider.max);
  const answer = (/** @type {number | null} */ birthYear) => {
    const underAge = isUnderAge(birthYear);
    storage.set(KEY, { underAge });
    tell(underAge);
    MenuStack.busy = false;
    menus.back();
  };
  // A click reaches the handler of every gate this scene opened; only the gate that is still there answers.
  ui.on("click", "age_continue", () => field.alive && answer(Math.round(slider.value)));
  ui.on("click", "age_skip", () => field.alive && answer(null));
  menus.show(panel);
  ui.focus(world.find("birth_year")); // a widget under the gate may hold the focus (a stack without a root panel does not move it)
  MenuStack.busy = true; // Escape / gamepad B must not skip the question
  return true;
}
