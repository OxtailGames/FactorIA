// The analytics question (scripts/ui/analytics_consent.js): asked once, both answers are kept, it cannot be skipped with Back, and
// nothing is queued until the player said yes. The prompt is spawned from its prefab into whatever scene the test starts in, so
// this test passes in any game with the analyticsConsent part; a game without an "analytics" section in factoria.json has nothing
// to ask and the tests only check that. The fake network plays the server (docs/ANALYTICS.md), driven with a gamepad.
import { test, expect, game } from "factoria:test";
import { world, ui, storage, analytics } from "factoria";
import { MenuStack } from "../scripts/ui/menu_stack.js";
import { openAnalyticsConsent } from "../scripts/ui/analytics_consent.js";

const pad = game.gamepad(0);

// An empty store, then the question over a menu stack of its own. Returns the stack.
function open() {
  storage.clear();
  game.platform.reset();
  game.analytics.restart();
  world.find("analytics_consent")?.destroy(); // the panel of the test before
  game.step(1);
  const panel = world.spawnPrefab("prefabs/ui/analytics_consent.prefab.json");
  panel.id = "analytics_consent"; // MenuStack shows panels by id
  panel.active = false;
  const menus = new MenuStack(null);
  expect(openAnalyticsConsent(menus)).toBe(true);
  game.step(2);
  expect(menus.top).toBe("analytics_consent");
  return menus;
}

function press(id) {
  ui.focus(world.find(id)); // the menu under the question has widgets of its own: do not walk to the button
  pad.tap("A");
  game.step(2);
}

test("a game without analytics has nothing to ask", () => {
  if (analytics.configured) return;
  expect(openAnalyticsConsent(new MenuStack(null))).toBe(false);
  expect(analytics.consent()).toBe("unknown");
});

test("before the answer no event is kept; Allow lets them through", () => {
  if (!analytics.configured) return;
  const menus = open();
  expect(analytics.event("level_start", { level: 1 })).toBe(false);
  expect(game.analytics.queued().length).toBe(0);
  press("analytics_allow");
  expect(analytics.consent()).toBe("granted");
  expect(menus.top).toBe(null);
  expect(MenuStack.busy).toBe(false);
  expect(analytics.event("level_start", { level: 1 })).toBe(true);
  expect(game.analytics.queued().map((e) => e.name)).toEqual(["level_start"]);
});

test("No thanks is an answer too: nothing is kept and it is not asked again", () => {
  if (!analytics.configured) return;
  open();
  press("analytics_deny");
  expect(analytics.consent()).toBe("denied");
  expect(analytics.event("level_start")).toBe(false);
  expect(openAnalyticsConsent(new MenuStack(null))).toBe(false); // the next run
});

test("Back does not skip the question", () => {
  if (!analytics.configured) return;
  const menus = open();
  pad.tap("B");
  game.step(1);
  expect(menus.top).toBe("analytics_consent");
  expect(analytics.consent()).toBe("unknown");
  expect(MenuStack.busy).toBe(true);
  press("analytics_allow");
  expect(MenuStack.busy).toBe(false);
});
