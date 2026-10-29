import { Behaviour, world, time } from "factoria";

// Swings the bones of the fifty skinned sprites and moves the IK targets. The IK sprites (every fifth) are left to IK2D.
export default class Swing extends Behaviour {
  onStart() {
    this.limbs = [];
    for (let i = 0; i < 50; i++) {
      const sprite = world.find(`s${i}`);
      const target = i % 5 === 0 ? world.find(`t${i}`) : null;
      this.limbs.push({
        i,
        b0: world.find(`s${i}_b0`),
        b1: world.find(`s${i}_b1`),
        target,
        home: target ? { x: target.position.x, y: target.position.y } : null,  // a copy: position is a live view
      });
      if (!sprite) throw new Error(`the scene has no sprite s${i}`);
    }
  }

  onUpdate() {
    const t = time.elapsed;
    for (const limb of this.limbs) {
      if (limb.target) {
        limb.target.position = [limb.home.x + 12 * Math.cos(t * 2 + limb.i), limb.home.y + 12 * Math.sin(t * 2 + limb.i), 0];
      } else {
        limb.b0.transform.rotation = [0, 0, 35 * Math.sin(t * 1.5 + limb.i * 0.3)];
        limb.b1.transform.rotation = [0, 0, -60 * Math.sin(t * 1.5 + limb.i * 0.3 + 1)];
      }
    }
  }
}
