// @ts-check
// Game feel that the player may switch off (Options > Accessibility). Every screen shake and every particle burst goes
// through a function here, so one option gates each.
import { world } from "factoria";
import * as settings from "./settings.js";

/** The short camera shake of a death. Nothing when the player turned the shake off. */
export function deathShake() {
  if (!settings.load().shake) return;
  const camera = world.find("camera")?.behaviour;
  if (camera && typeof camera.shake === "function") camera.shake(0.3, 10);
}

/** The spark burst of a collected ember at `position`. Nothing with reduced effects. */
export function emberSpark(position) {
  if (settings.load().reducedEffects) return;
  world.spawnPrefab("prefabs/spark.prefab.json", { position: position.clone() });
}
