// @ts-check
// Shared numbers and helpers of Kindlewatch. The level is a clearing around the campfire at the origin, the ground is
// the XZ plane, +Y is up. The models face +Z, so the yaw that turns one to look along (dx, dz) is atan2(dx, dz).
import { world, audio } from "factoria";

export const DEG = 180 / Math.PI;
/** Half the side of the square clearing (the invisible walls stand a little outside it), metres. */
export const ARENA = 21;

/** Yaw in degrees that makes a +Z facing model look along the horizontal direction (dx, dz). */
export function yawOf(dx, dz) {
  return Math.atan2(dx, dz) * DEG;
}

/** The shortest signed angle from `from` to `to`, degrees in -180..180. */
export function angleDiff(from, to) {
  let d = (to - from) % 360;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return d;
}

/** `from` turned toward `to` by at most `step` degrees. */
export function turnToward(from, to, step) {
  const d = angleDiff(from, to);
  return Math.abs(d) <= step ? to : from + Math.sign(d) * step;
}

/** Horizontal distance between two entities (or positions). */
export function flatDistance(a, b) {
  const pa = a.position ?? a;
  const pb = b.position ?? b;
  return Math.hypot(pa.x - pb.x, pa.z - pb.z);
}

/** The behaviour of the entity with this id, or null when the scene has no such entity (it may be unloading). */
export function behaviourOf(id) {
  return world.find(id)?.behaviour ?? null;
}

/** Sets a Text's key arguments (the {placeholders} of its locale text). */
export function setArgs(entity, args) {
  if (entity) entity.get("Text").keyArgs = args;
}

/**
 * Plays a one-shot sound as if it came from a point of the clearing: quieter with the distance to the camera's ground
 * point and panned by the side (audio.play has no position; only an AudioSource has).
 */
export function playAt(path, point, options = {}) {
  const { range = 28, ...rest } = options;
  const ears = world.find("camera");
  const p = point.position ?? point;
  let volume = rest.volume ?? 1;
  let pan = 0;
  if (ears) {
    const e = ears.position;
    const d = Math.hypot(p.x - e.x, p.z - (e.z - 10));
    volume *= Math.max(0, 1 - d / range);
    pan = Math.max(-0.8, Math.min(0.8, (p.x - e.x) / 14));
  }
  if (volume <= 0.01) return 0;
  return audio.play(path, { bus: "sfx", ...rest, volume, pan });
}
