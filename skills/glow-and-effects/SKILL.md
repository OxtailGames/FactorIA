---
name: glow-and-effects
description: Bloom, additive glow, one-shot bursts and the loop for drawn effects (hit sparks, pickups, fires). Read when adding glow or effects.
---

# Glow and one-shot effects

## One-shot effects

a `ParticleEmitter` with `emitting: false`, `burst: 24`, `autoDestroy: true` and
`blend: "additive"` fires once and removes itself. `particles.burst(entity, n)` bursts an existing one.

## Neon glow

`"blend": "additive"` on bright Sprites/Shapes/particles plus `"bloom": true` on the primary `Camera`
(`bloomThreshold`, `bloomIntensity`, `bloomRadius`) over a dark `clearColor`. Never hand-draw blurred halo sprites.
`"bloomScreenSpace": false` keeps the HUD crisp. Spin a triangle with `pivot: [0.5, 0.3333]` (its centroid);
`Shape2D` also has `diamond`, `polygon` and `star`; `ParticleEmitter` takes `space: "screen"`. Guide section 9.20.

## An effect you draw: draft, film, look, refine

A spark, a ring or a fire that follows rules is code: `assets_animate_svg` with a `ramp` (3 or 4 colours of the style's palette,
dark to bright) and, when it passes behind and in front of something, `layers: ["back","front","light"]`. Then film it at the
size the player sees it, not the sheet's size: `assets_contact_sheet {"paths":[...],"allFrames":true,"sizes":[48],
"greyscale":true}` (and `assets_preview_sheet` with `onion`). LOOK, and judge: readable at that size on the light, dark and camera
backgrounds and in greyscale; anticipation before the contact; impact on frame 0 or 1 (the biggest, brightest frame, with the hit-stop,
shake and flash of `feel` on that frame, as a clip event); recovery that thins and fades to nothing; palette of 3 or 4 ramp colours.
Change one thing, bake again with `overwrite: true`, film again; read the bake's warnings (a cut edge, an empty frame) as part of the look.
Three worked examples with the real calls (an impact, a pickup, a fire loop): `docs_read {"name":"effects"}`. There is no effect library:
write the effect for this game's palette. The game feel calls (shake, hit-stop, flash, squash) are `docs_read {"name":"game-feel"}`.
