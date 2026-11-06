// The sparkle of a coin pickup, drawn as code (M62.3): a ring that opens behind the hero, four-point glints that fly out in
// front of it and a soft glow added on top. `progress` runs 0..1 over the clip (it does not loop). Every colour comes from
// `ramp` (dark to bright, `rampAt(u)`), so a silver coin only needs another ramp when the sheet is baked again.
//
// Timing is the part of the pickup the player feels: anticipation is the coin itself (it is the thing that disappears), the
// IMPACT is frame 1 (the glow is at its biggest and the glints are close to the centre: a bright burst the eye lands on)
// and the RECOVERY is the last frames (everything thins out and fades, so nothing is left to read as a bug).
export default function frame({ layer, progress, rngFor, rampAt }) {
  const ease = 1 - (1 - progress) * (1 - progress);   // quadOut: fast at the start, slow at the end
  const fade = Math.max(0.08, 1 - progress * progress); // stays up, then drops (not 0: an empty last frame is a warning)
  const open = (inner) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${inner}</svg>`;
  if (layer === "back") {
    // the ring: its stroke thins while it grows
    const r = 8 + ease * 34;
    const w = Math.max(1, 9 * (1 - progress));
    return open(`<circle cx="50" cy="50" r="${r.toFixed(2)}" fill="none" stroke="${rampAt(0.4)}" stroke-width="${w.toFixed(2)}" opacity="${fade.toFixed(2)}"/>`);
  }
  if (layer === "light") {
    // a soft glow: three discs of falling opacity, added to the picture under them
    const r = 26 + ease * 10;      // the glow is already big on frame 1: that is the impact
    const a = 0.8 * fade;
    return open([1, 0.66, 0.36].map((k, i) =>
      `<circle cx="50" cy="50" r="${(r * k).toFixed(2)}" fill="${rampAt(0.5 + i * 0.25)}" opacity="${(a * (0.35 + i * 0.3)).toFixed(2)}"/>`).join(""));
  }
  // front: glints at the same angles on every frame (rngFor gives the same stream on each), flying out and shrinking
  const r = rngFor("glints");
  let out = "";
  for (let i = 0; i < 5; i++) {
    const ang = r() * Math.PI * 2;
    const reach = 18 + r() * 14;
    const d = 6 + ease * reach * 1.6;
    const s = (1 - progress) * (7 + r() * 5) + 1.5;
    const x = 50 + Math.cos(ang) * d, y = 50 + Math.sin(ang) * d;
    // a four-point glint: two thin diamonds crossed
    out += `<path d="M${x} ${y - s * 2}L${x + s * 0.5} ${y}L${x} ${y + s * 2}L${x - s * 0.5} ${y}Z M${x - s * 2} ${y}L${x} ${y - s * 0.5}L${x + s * 2} ${y}L${x} ${y + s * 0.5}Z" fill="${rampAt(0.85 + (i % 2) * 0.15)}" opacity="${Math.min(1, fade * 1.3).toFixed(2)}"/>`;
  }
  return open(out);
}
