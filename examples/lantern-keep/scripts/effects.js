// @ts-check
// Game feel that the player may want to switch off. Every screen shake goes through deathShake() so one option can
// gate it (the accessibility package adds that option here, and nowhere else).
import { world } from "factoria";

/** The short camera shake of a death. */
export function deathShake() {
  const camera = world.find("camera")?.behaviour;
  if (camera && typeof camera.shake === "function") camera.shake(0.3, 10);
}
