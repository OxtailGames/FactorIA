// The shockwave ring behind an explosion: a bright ring that grows and thins while a few sparks fly outwards. White, so the
// game tints it with the colour of the enemy that died (Sprite.color). Baked into assets/art/shockwave.png by
//   factoria call assets.animate_svg --project . '{"path":"assets/art/shockwave.png","source":"art/shockwave.anim.js",
//     "frameWidth":96,"frameHeight":96,"padding":2,"overwrite":true,"seed":7,"clips":[{"name":"pop","frames":8,"fps":24,"loop":false},
//     {"name":"boom","frames":12,"fps":20,"loop":false,"params":{"sparks":10}}]}'
// (tools/make_shockwave.sh runs exactly this). `progress` runs 0..1 over the clip and reaches 1 on the last frame (loop is false).
export default function frame({ progress, params, rngFor, clip }) {
  const sparks = params.sparks || 6;
  const radius = 8 + 36 * (1 - Math.pow(1 - progress, 2.2)); // fast out, slow in
  const thick = Math.max(0.6, 7 * (1 - progress));
  const alpha = Math.max(0.08, 1 - progress * progress).toFixed(3); // never fully gone: the last frame is the faint end of the ring
  let s = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'>`;
  s += `<circle cx='50' cy='50' r='${radius.toFixed(2)}' fill='none' stroke='#ffffff' stroke-width='${thick.toFixed(2)}' opacity='${alpha}'/>`;
  if (progress < 0.5) s += `<circle cx='50' cy='50' r='${(radius * 0.6).toFixed(2)}' fill='#ffffff' opacity='${(0.8 - progress * 1.6).toFixed(3)}'/>`;
  const rng = rngFor("sparks"); // the same stream on every frame: each spark keeps its own direction
  for (let i = 0; i < sparks; i++) {
    const a = rng() * Math.PI * 2;
    const reach = (0.7 + rng() * 0.3) * 46 * progress;
    const x = 50 + Math.cos(a) * reach, y = 50 + Math.sin(a) * reach;
    s += `<circle cx='${x.toFixed(2)}' cy='${y.toFixed(2)}' r='${Math.max(0.5, 2.4 * (1 - progress)).toFixed(2)}' fill='#ffffff' opacity='${alpha}'/>`;
  }
  return s + `</svg>`;
}
