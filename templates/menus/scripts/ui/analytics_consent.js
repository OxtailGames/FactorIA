// @ts-check
// The analytics question (prefabs/ui/analytics_consent.prefab.json), for a game whose factoria.json has an "analytics" section
// (docs/ANALYTICS.md): analytics.event() sends nothing until the player said yes, so the game asks once, on its first screen.
// Both answers are fine: "No thanks" is kept like "Allow" (analytics.setConsent in storage), the question does not come back, and
// the player can change the answer in Options (the "analytics_consent" switch, scripts/ui/options.js). Say what is collected in your
// privacy policy and edit the texts "analyticsConsent.what" in locales/*.json to match what your game sends (docs/LEGAL.md).
import { ui, world, analytics } from "factoria";
import { MenuStack } from "./menu_stack.js";

/**
 * From the scene that opens first (the main menu calls it only when analytics.configured): opens the question over the menu
 * when the player has not answered yet. `menus` is the scene's MenuStack, `panel` the id of the entity of the prefab in the scene.
 * Returns true when the question is open; false when the game has no analytics or the player already answered (the answer
 * of an earlier run, or the ad consent when factoria.json says "consentFromAds"). The player cannot close it with Back.
 */
export function openAnalyticsConsent(menus, panel = "analytics_consent") {
  if (!analytics.configured || analytics.consent() !== "unknown") return false;
  const allow = world.find("analytics_allow");
  const answer = (/** @type {boolean} */ yes) => {
    analytics.setConsent(yes);
    MenuStack.busy = false;
    menus.back();
  };
  // A click reaches the handler of every question this scene opened; only the one that is still there answers.
  ui.on("click", "analytics_allow", () => allow.alive && answer(true));
  ui.on("click", "analytics_deny", () => allow.alive && answer(false));
  menus.show(panel);
  ui.focus(allow); // a widget under the question may hold the focus
  MenuStack.busy = true; // Escape / gamepad B must not skip the question
  return true;
}
