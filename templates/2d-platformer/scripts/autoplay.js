// @ts-check
// The bot: how this game plays itself when `factoria call play.auto` (or the editor's automatic play) tests it.
// It runs the level from the left wall to the right one: hold move_right, jump when something blocks the way (and now and
// then for no reason, with the seeded bot.rng), and report the coins it picked up. Reaching the right end ends the run
// as "won". Only play.auto imports this file: an exported game does not ship it (docs/SCRIPTING.md, "The bot").
// Change the end condition when you change the level: it is the bounds() of the Tilemap, like the camera's limits.
import { game, world } from "factoria";

let coinsAtStart = -1;
let startedIn = "";
let lastX = 0;
let lastMoveTime = 0;

game.autoplay((bot) => {
  const player = world.find("player");
  if (!player) return { end: "lost", note: "The player entity is gone." };
  const coinsLeft = world.findByTag("coin").length;
  if (bot.scene !== startedIn || coinsAtStart < 0) {
    startedIn = bot.scene;
    coinsAtStart = coinsLeft;
    lastX = player.position.x;
    lastMoveTime = bot.time;
  }
  const score = coinsAtStart - coinsLeft;

  const area = world.find("map")?.bounds(); // { x, y, w, h }: the level rectangle
  if (area && player.position.x >= area.x + area.w - 3 * 32) return { end: "won", score, note: "Reached the right end of the level." };

  if (Math.abs(player.position.x - lastX) > 2) {
    lastX = player.position.x;
    lastMoveTime = bot.time;
  }
  const blocked = bot.time - lastMoveTime > 0.15; // pressing right without moving: a step or a wall in the way
  const jump = player.isGrounded() && (blocked || bot.rng.chance(0.02));
  return { actions: jump ? ["move_right", "jump"] : ["move_right"], score };
});
