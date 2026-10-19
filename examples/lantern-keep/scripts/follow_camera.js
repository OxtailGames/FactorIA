// @ts-check
// Follows the entity with id `target` on both axes and never shows anything outside the level, and shakes on request
// (effects.js deathShake() calls shake()).
// The level rectangle is the bounds() of the entity named by `bounds` (the level's Tilemap): the map size times
// tileSize, placed by its transform. Nothing here copies the map size, so the limits follow the map when you edit it.
import { Behaviour, game, math } from "factoria";

let warnedBounds = false;

export default class FollowCamera extends Behaviour {
  /** Id of the entity to follow. */
  target = "player";
  /** Id of the entity whose bounds() limit the camera (the level's Tilemap). "" = no limits. */
  bounds = "map";
  /** Higher = snappier. */
  smoothing = 8;

  /** The camera position that shows (x, y) as near the middle as the level allows. */
  clampPos(x, y) {
    const area = this.bounds ? this.world.find(this.bounds)?.bounds() : null; // { x, y, w, h }: bottom-left corner, size
    if (!area) {
      if (this.bounds && !warnedBounds) {
        warnedBounds = true;
        console.warn(`FollowCamera: no entity "${this.bounds}" with a Tilemap (or Sprite/Shape2D), so the level does not limit the camera. Set the "bounds" prop of this Script to the id of the level's Tilemap entity.`);
      }
      return [x, y];
    }
    // Half of the visible area in world units: the design size unless the Camera sets orthoSize.
    const ortho = this.entity.get("Camera").orthoSize;
    const screen = game.screenSize; // read every frame: it follows a change of the design or window size
    const halfH = ortho > 0 ? ortho : screen.y / 2;
    const halfW = (halfH * screen.x) / screen.y;
    // A level smaller than the view has nothing to scroll: centre on it.
    const cx = area.w <= 2 * halfW ? area.x + area.w / 2 : math.clamp(x, area.x + halfW, area.x + area.w - halfW);
    const cy = area.h <= 2 * halfH ? area.y + area.h / 2 : math.clamp(y, area.y + halfH, area.y + area.h - halfH);
    return [cx, cy];
  }

  /** Shakes the view for `duration` seconds, at most `magnitude` pixels off, fading out. Deterministic (no random numbers). */
  shake(duration, magnitude) {
    this.shakeTime = 0;
    this.shakeDuration = duration;
    this.shakeMagnitude = magnitude;
  }

  /** The offset the shake adds to the camera this frame. */
  shakeOffset() {
    if (this.shakeDuration <= 0 || this.shakeTime >= this.shakeDuration) return [0, 0];
    const fade = 1 - this.shakeTime / this.shakeDuration;
    return [Math.sin(this.shakeTime * 85) * this.shakeMagnitude * fade, Math.cos(this.shakeTime * 67) * this.shakeMagnitude * fade];
  }

  onStart() {
    this.shakeDuration = 0;
    this.shakeTime = 0;
    this.shakeMagnitude = 0;
    // Begin on the player instead of sweeping over from wherever the scene file left the camera.
    const t = this.world.find(this.target);
    if (!t) return;
    const [cx, cy] = this.clampPos(t.position.x, t.position.y);
    this.base = [cx, cy]; // where the camera is without the shake
    this.entity.position.x = cx;
    this.entity.position.y = cy;
  }

  onLateUpdate(dt) {
    const t = this.world.find(this.target);
    if (!t || !this.base) return;
    const [cx, cy] = this.clampPos(t.position.x, t.position.y);
    this.base[0] = math.damp(this.base[0], cx, this.smoothing, dt);
    this.base[1] = math.damp(this.base[1], cy, this.smoothing, dt);
    this.shakeTime += dt;
    const [sx, sy] = this.shakeOffset();
    this.entity.position.x = this.base[0] + sx;
    this.entity.position.y = this.base[1] + sy;
  }
}
