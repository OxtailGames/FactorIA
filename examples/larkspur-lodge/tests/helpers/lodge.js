// Shared helpers of the Larkspur Lodge tests.
import { game } from "factoria:test";
import { camera } from "factoria";
import * as story from "../../scripts/story.js";
import * as items from "../../scripts/items.js";

export const porter = () => game.find("porter");
export const cam = () => game.find("camera");

/**
 * Loads an area scene (arriving at `spawn`) and lets it settle: the porter lands on the floor, the fade-in starts.
 * A new game starts with no story flags and no items (they live in `session`, which the tests share); `keepStory` keeps them.
 */
export function enter(area = "ground", spawn = "spawn_default", keepStory = false) {
  game.resetState();
  if (!keepStory) {
    story.reset();
    items.reset();
  }
  game.load(`scenes/${area}.scene.json`, { arrive: spawn });
  game.step(30);
}

/** Horizontal distance in metres between two entities' positions (or {x, z} points). */
export function distance(a, b) {
  const pa = a.position ?? a;
  const pb = b.position ?? b;
  return Math.hypot(pa.x - pb.x, pa.z - pb.z);
}

/** The screen position (design pixels) of a world point, as [x, y]. */
export function screenOf(point) {
  const s = camera.worldToScreen(point);
  return [s.x, s.y];
}

/** Puts the porter at a floor point (x, z) with no smoothing, faces him `yaw` degrees and snaps the camera behind him. */
export function stand(x, z, yaw = 0) {
  const p = porter();
  p.position = [x, 0.95, z];
  p.behaviour.faceYaw(yaw);
  cam().behaviour.snapBehind(yaw);
  game.step(5);
}
