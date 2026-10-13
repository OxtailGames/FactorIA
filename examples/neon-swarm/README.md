# Neon Swarm

Twin-stick arena shooter. WASD move, mouse aim, Space / left click shoot.
Run: `factoria run .`   Tests: `factoria test`   Balance: `factoria call project.balance_report '{}' --scene scenes/game.scene.json --frames-before 250`
Scenes: title -> game -> gameover. High score persists with `storage`.

## The neon look

The glow is a camera setting, not artwork (no glow textures, no halo sprites):

- Every scene's primary `Camera` has `"bloom": true` (`bloomThreshold` 0.5, `bloomIntensity` 1.5, `bloomRadius` 26) over a
  very dark `clearColor`, so everything brighter than the threshold bleeds light into its surroundings.
- The player, the enemies, the bullets, the arena border and the title decorations are `Shape2D`s with bright colours
  and `"blend": "additive"`, so overlapping lights add up. Enemies and decorations are outlines (`filled: false`), the
  player and the bullets are solid. Explosions are `ParticleEmitter`s with `"blend": "additive"`.
- The HUD is not additive but bloom is applied to the whole finished frame, so the bright HUD text (white score, cyan
  best, yellow wave, the full cyan health pips) picks up a soft glow. That is accepted: it stays readable and matches the
  look. The dim help line and the empty health pips are close to the threshold or below it and barely glow.
- Scripts tint the shapes at runtime through `Shape2D.color` (hit flash to white, invulnerability blink through `a`).

Screenshots (`screenshots/`) come from the headless runner:

```
factoria run . --headless --scene scenes/title.scene.json --frames 60 --screenshot-at 59 --screenshot-pattern screenshots/title.png
factoria run . --headless --scene scenes/game.scene.json --frames 330 --input replays/aim.json --screenshot-at 329 --screenshot-pattern screenshots/gameplay.png
```
