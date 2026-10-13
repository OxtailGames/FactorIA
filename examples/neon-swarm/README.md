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
- The game scene's `Camera` has `"bloomScreenSpace": false`, so the screen-space HUD (white score, cyan best, yellow wave,
  the health pips) is drawn after the bloom and stays crisp while the arena glows. The title and game-over scenes keep the
  default (`true`), so their screen-space titles glow too.
- The chaser is a spinning `diamond` (a rhombus), the shooter and the player are triangles with `"pivot": [0.5, 0.3333]`
  (the triangle's centroid), so they spin and aim about their own centre instead of wobbling around the middle of their box.
- Scripts tint the shapes at runtime through `Shape2D.color` (hit flash to white, invulnerability blink through `a`).

Screenshots (`screenshots/`) come from the headless runner:

```
factoria run . --headless --scene scenes/title.scene.json --frames 60 --screenshot-at 59 --screenshot-pattern screenshots/title.png
factoria run . --headless --scene scenes/game.scene.json --frames 330 --input replays/aim.json --screenshot-at 329 --screenshot-pattern screenshots/gameplay.png
```
