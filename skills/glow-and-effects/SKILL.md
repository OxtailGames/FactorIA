---
name: glow-and-effects
description: Bloom, additive glow and one-shot particle bursts. Read when adding glow or effects.
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
