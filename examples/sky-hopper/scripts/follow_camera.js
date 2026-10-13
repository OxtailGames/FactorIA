// @ts-check
// Follows `target`, clamped to the level. The level rectangle comes from the entity named by `bounds` (the level's
// Tilemap): entity.bounds() is the map size times tileSize, placed by its transform, so the camera limits cannot
// drift from the map. minX/maxX/minY/maxY (world pixels) are optional extra limits that narrow it further.
import { Behaviour, math } from "factoria";

let warnedBounds = false;

export default class FollowCamera extends Behaviour {
  target = "player";
  bounds = "";    // id of the Tilemap entity whose bounds() limit the camera; "" = only minX..maxY below
  smoothing = 8;
  minX = -1e9; maxX = 1e9; minY = -1e9; maxY = 1e9;
  viewW = 1280; viewH = 720;

  /** The rectangle the camera view must stay inside: the map bounds, narrowed by minX..maxY when those are set. */
  limits() {
    let { minX, maxX, minY, maxY } = this;
    if (this.bounds) {
      const area = this.world.find(this.bounds)?.bounds(); // { x, y, w, h }: bottom-left corner and size
      if (area) {
        minX = Math.max(minX, area.x);
        maxX = Math.min(maxX, area.x + area.w);
        minY = Math.max(minY, area.y);
        maxY = Math.min(maxY, area.y + area.h);
      } else if (!warnedBounds) {
        warnedBounds = true;
        console.warn(`FollowCamera: bounds "${this.bounds}" is not an entity with a Tilemap (or Sprite/Shape2D) in the world, so the map does not limit the camera. Set the camera's Script prop "bounds" to the id of the level's Tilemap entity.`);
      }
    }
    return { minX, maxX, minY, maxY };
  }

  clampPos(x, y) {
    const { minX, maxX, minY, maxY } = this.limits();
    const hw = this.viewW / 2, hh = this.viewH / 2;
    const cx = maxX - minX <= this.viewW ? (minX + maxX) / 2 : math.clamp(x, minX + hw, maxX - hw);
    const cy = maxY - minY <= this.viewH ? (minY + maxY) / 2 : math.clamp(y, minY + hh, maxY - hh);
    return [cx, cy];
  }

  onStart() {
    const t = this.world.find(this.target);
    if (!t) return;
    const [cx, cy] = this.clampPos(t.position.x, t.position.y);
    this.entity.position.x = cx;
    this.entity.position.y = cy;
  }

  onLateUpdate(dt) {
    const t = this.world.find(this.target);
    if (!t) return;
    const [cx, cy] = this.clampPos(t.position.x, t.position.y);
    const p = this.entity.position;
    p.x = math.damp(p.x, cx, this.smoothing, dt);
    p.y = math.damp(p.y, cy, this.smoothing, dt);
  }
}
