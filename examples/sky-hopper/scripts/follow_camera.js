// @ts-check
// Follows `target`, clamped to level bounds (minX..maxX, minY..maxY in world pixels).
import { Behaviour, math, game } from "factoria";

export default class FollowCamera extends Behaviour {
  target = "player";
  smoothing = 8;
  minX = -1e9; maxX = 1e9; minY = -1e9; maxY = 1e9;
  viewW = 1280; viewH = 720;

  clampPos(x, y) {
    const hw = this.viewW / 2, hh = this.viewH / 2;
    const cx = this.maxX - this.minX <= this.viewW ? (this.minX + this.maxX) / 2 : math.clamp(x, this.minX + hw, this.maxX - hw);
    const cy = this.maxY - this.minY <= this.viewH ? (this.minY + this.maxY) / 2 : math.clamp(y, this.minY + hh, this.maxY - hh);
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
