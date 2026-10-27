// A fixed picture of the hall: open .factoria/screenshots/hall.png after changing the lighting or the models.
// (A test cannot read the pixels back; it proves the scene draws without errors, the picture is for the eyes.)
import { test, expect, game } from "factoria:test";
import { enter, stand } from "./helpers/lodge.js";

test("the hall by night can be photographed from the spawn", () => {
  enter("ground");
  stand(15, 21.6, 0);
  game.step(60); // the area name has faded in and out
  expect(() => game.screenshot(".factoria/screenshots/hall.png")).not.toThrow();
  expect(game.find("hud").behaviour.fadeAlpha).toBeLessThan(0.05); // the screen is not still black from the fade-in
});
