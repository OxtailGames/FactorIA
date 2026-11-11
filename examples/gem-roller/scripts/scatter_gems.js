// Gem placement shared by the game (scripts/game.js, at runtime) and the project tool project.scatter_gems (tools/scatter_gems.js):
// tools/ is not exported, so the game must not call the tool; both import this module instead.
import { world } from "factoria";

// mulberry32: small deterministic PRNG, so the same seed always gives the same layout.
function prng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

/** Places `count` gems on top of the platforms (entities tagged "platform"), deterministically from `seed`. Returns {placed, gems}. */
export function scatterGems({ count = 8, seed = 1, clear = false, height = 1.0, margin = 0.8 } = {}) {
  if (clear) for (const g of world.findByTag("gem")) g.destroy();
  const plats = world.findByTag("platform").filter((p) => p.has("Transform"));
  plats.sort((a, b) => (a.id < b.id ? -1 : a.id > b.id ? 1 : 0));
  if (plats.length === 0) throw new Error('No entities tagged "platform" in the world.');
  const rnd = prng(seed);
  const areas = plats.map((p) => Math.max(0.01, p.transform.scale.x * p.transform.scale.z));
  const total = areas.reduce((a, b) => a + b, 0);
  const out = [];
  for (let i = 0; i < count; i++) {
    let r = rnd() * total, k = 0;
    while (k < plats.length - 1 && r >= areas[k]) { r -= areas[k]; k++; }
    const pl = plats[k];
    const c = pl.worldPosition, s = pl.transform.scale;
    const hx = Math.max(0, s.x / 2 - margin), hz = Math.max(0, s.z / 2 - margin);
    const pos = [
      +(c.x + (rnd() * 2 - 1) * hx).toFixed(3),
      +(c.y + s.y / 2 + height).toFixed(3),
      +(c.z + (rnd() * 2 - 1) * hz).toFixed(3),
    ];
    const gem = world.spawn({
      id: `gem_${i + 1}`, // destroy() frees an id at once, so re-scattering after "clear" reuses gem_1, gem_2...
      name: "Gem",
      tags: ["gem"],
      components: {
        Transform: { position: pos, scale: [0.8, 0.8, 0.8] },
        MeshRenderer: { mesh: "assets/models/gem.glb", emissive: [0.05, 0.3, 0.4, 1], castShadows: true, material: "materials/gem.material.json" },
        RigidBody3D: { type: "static" },
        Collider3D: { shape: "sphere", radius: 0.7, isTrigger: true },
        Light: { type: "point", color: [0.4, 0.9, 1, 1], intensity: 1.5, range: 5 },
        Script: { path: "scripts/gem.js" },
      },
    });
    out.push({ id: gem.id, position: pos, platform: pl.id });
  }
  return { placed: out.length, gems: out };
}
