// @ts-check
// A rope bridge: `planks` dynamic planks chained with hinge joints (Joint3D) between two fixed ends, hanging in a gentle
// curve under gravity. The script builds the planks when the scene starts (so a level only says where the bridge goes):
//
//   from, to   world positions of the two ends (the surface level at both ends, metres). Put them just past the edges
//              of the slabs (0.05 m or more): a plank that starts inside a static collider is pushed out of it, the
//              chain buckles and never settles, and the level plays differently on each platform (FB-0053).
//   planks     how many planks
//   width      across the bridge, metres;  sag: how far the middle hangs below the ends at the start, metres
//
// The first plank hangs from the world at `from`, the last at `to`; each other plank hinges on the one before. Planks are
// named "<entity id>_plank_<i>" and tagged "wood" (footsteps); each carries two rope posts so it reads as a bridge.
// The courier walks on the planks: it weighs on them (CharacterController3D.applyWeight) and never shoves them.
import { Behaviour, world } from "factoria";

export default class RopeBridge extends Behaviour {
  from = [0, 0, 0];
  to = [0, 0, -8];
  planks = 9;
  width = 2;
  thickness = 0.14;
  sag = 0.35;
  /** Mass of one plank, kg. */
  mass = 6;
  /** Plank model (a flat wooden board); empty: a coloured cube. */
  model = "";
  color = [0.55, 0.37, 0.2, 1];

  onStart() {
    const [fx, fy, fz] = this.from;
    const [tx, ty, tz] = this.to;
    const n = Math.max(2, this.planks | 0);
    const dx = tx - fx;
    const dz = tz - fz;
    const yaw = (Math.atan2(-dx, -dz) * 180) / Math.PI; // 0 = along -Z
    const horizontal = Math.hypot(dx, dz);
    /** Point of the curve at parameter t (0..1): a parabola sagging between the ends. */
    const curve = (t) => [fx + dx * t, fy + (ty - fy) * t - this.sag * 4 * t * (1 - t), fz + dz * t];
    /** @type {any[]} */
    this.pieces = [];
    for (let i = 0; i < n; i++) {
      const a = curve(i / n);
      const b = curve((i + 1) / n);
      const len = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
      const mid = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - this.thickness / 2, (a[2] + b[2]) / 2];
      // The plank's local -Z runs from a to b; pitch tilts it up or down along the slope.
      const pitch = (Math.atan2(b[1] - a[1], horizontal / n) * 180) / Math.PI;
      const plank = len * 0.94;
      const visual = this.model
        ? { MeshRenderer: { mesh: this.model } }
        : { MeshRenderer: { mesh: "cube", color: this.color, roughness: 0.85 } };
      const e = world.spawn(
        {
          id: `${this.entity.id}_plank_${i}`,
          tags: ["wood"],
          components: {
            Transform: { position: mid, rotation: [pitch, yaw, 0], scale: [this.width, this.thickness, plank] },
            ...visual,
            Collider3D: { shape: "box", friction: 0.8 },
            // Heavy damping: with the lighter 3 / 8 the chain swung differently whenever another entity was made before it (a
            // HUD icon), and the courier sometimes fell through on the rooftops_3 shortcut. Now it hangs still.
            RigidBody3D: { type: "dynamic", mass: this.mass, linearDamping: 8, angularDamping: 30 },
          },
          children: [-1, 1].flatMap((side, k) => [
            // A rope rail along the plank and a post at its middle, 0.8 m above the plank: sizes are given in metres and
            // divided by the plank's own scale (a child inherits it).
            {
              name: `rail_${k}`,
              components: {
                Transform: { position: [0.5 * side, 0.8 / this.thickness, 0], scale: [0.07 / this.width, 0.07 / this.thickness, 1] },
                MeshRenderer: { mesh: "cube", color: [0.85, 0.75, 0.5, 1], roughness: 0.9 },
              },
            },
            {
              name: `post_${k}`,
              components: {
                Transform: { position: [0.5 * side, 0.4 / this.thickness, 0], scale: [0.09 / this.width, 0.8 / this.thickness, 0.09 / plank] },
                MeshRenderer: { mesh: "cube", color: [0.4, 0.27, 0.15, 1], roughness: 0.9 },
              },
            },
          ]),
        },
        { position: mid },
      );
      this.pieces.push({ e, a, b });
    }
    // Hinges. Joint3D.anchor is in the plank's local (scaled) space, where the end towards the next plank is local z = -0.5.
    // Each plank carries the joint at its far end to the next one; the last one to the world. The first plank hangs from
    // a static anchor entity at the start (an entity holds one Joint3D, and each plank's is already used).
    for (let i = 0; i < n; i++) {
      const next = i < n - 1 ? this.pieces[i + 1].e.id : "";
      // An empty `connected` is the world; the field is left out then (the scene validator refuses an explicit "").
      const joint = { type: "hinge", axis: [1, 0, 0], anchor: [0, 0, -0.5], collideConnected: false };
      if (next) joint.connected = next;
      this.pieces[i].e.add("Joint3D", joint);
    }
    const first = this.pieces[0];
    this.startAnchor = world.spawn(
      {
        id: `${this.entity.id}_start`,
        components: {
          Transform: { position: first.a },
          RigidBody3D: { type: "static" },
          Collider3D: { shape: "box", size: [0.05, 0.05, 0.05], isTrigger: true },
        },
      },
      { position: first.a },
    );
    this.startAnchor.add("Joint3D", { type: "hinge", axis: [1, 0, 0], anchor: [0, 0, 0], connected: first.e.id, collideConnected: false });
  }
}
