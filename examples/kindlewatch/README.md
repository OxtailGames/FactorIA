# Kindlewatch

The M60 reference game of FactorIA: a small, complete 3D game whose every picture, model, character, sound and song was
made with the engine's own commands (M51-M59). No asset provider was called and no file was imported. It exists to
measure what a game-making AI reaches with those tools, against the reference games that used providers, and to record
every gap in `ENGINE_FEEDBACK.json` (21 entries).

You are the warden of a campfire in a forest clearing. Three nights, three waves of wolves. The fire burns down, wolves
bite it, and the only way to keep it alive is to carry logs from the piles to the flames while you swing your torch at
the pack. The third night brings the alpha: at half its health it howls and two more wolves answer from the forest.
Win: see the third dawn. Lose: the fire goes out, or the warden runs out of hearts.

- **Move**: W A S D / arrow keys, the left stick of a gamepad, or the on-screen stick of a phone (`TouchStick`).
- **Swing the torch**: Space or J, gamepad A, or the on-screen button (`TouchButton`).
- **Pause**: Escape or P, gamepad Start, or the pause button at the top right.
- Logs are picked up by walking up to a pile (3 at most) and fed to the fire by walking close to it (a log gives 20
  fuel; the fire refuses logs while it is nearly full). Dawn restocks the piles and gives a heart back.

```bash
factoria run examples/kindlewatch                           # play it
factoria validate --project examples/kindlewatch            # 0 errors, 0 warnings
factoria test examples/kindlewatch                          # 21 tests
factoria run examples/kindlewatch --headless --scene scenes/game.scene.json --frames 790 \
    --input examples/kindlewatch/replays/first_night.json --screenshot-at 789 --screenshot-pattern shot.png
factoria call --project examples/kindlewatch perf.measure   # draw calls, entities, memory
```

## How every asset was made

The recipe of each file (command, arguments, inputs, hashes) is in `assets.json` under `provenance.recipe`, and
`assets.regenerate {"stale":true}` rebuilds whatever is out of date. `tests/assets.test.js` fails if an asset has no
recipe of an engine command, if one is marked as made with AI or imported, if a picture, sound or model sits under
`assets/` without a record, or if a baked output is older than its document. The documents next to the outputs
(`*.image.json`, `*.model.json`, `*.rig.json`, `*.sfx.json`, `*.song.json`, `*.audio.json`, `anim/*.anim.json`) are the
sources. The commands were called with `factoria call` from small scripts that were kept out of the project.

| What | Files | Commands |
| --- | --- | --- |
| Pixel art: sky, interface icons (heart, log, sun), panel and bar pictures, the logo, the pine of the title | `assets/art/*.image.json` | `image.create` (one palette of 19 colours and four ramps), `image.draw`, `image.pixel`, `image.pixel.outline`, `image.layer.convert`, `image.bake`; the house style is in `assets.json` `style` |
| The flame of the title (4 frames, a `burn` clip) | `assets/art/flame.image.json` | `image.frame.add`, `image.frame.set`, `image.tag.set`: the bake writes the sprite sheet and the animation clip |
| The ground and dirt textures of the 3D scene | `assets/art/ground.image.json`, `dirt.image.json` | `image.tile.set` (wrap-around editing), `image.tile.check` (no visible seam) |
| The forest of the title (a 47-tile autotile set painted on a Tilemap) | `assets/art/forest.image.json`, `forest.terrains.json` | `image.tileset.build`, `image.tileset.check`, `image.tileset.rules` |
| The game icon | `assets/icon.png`, `icon_fg.png` | `assets.draw_icon` |
| Warden, wolf, alpha wolf, campfire, pine, rock, log pile, log | `assets/models/*.model.json` | `model.create` (primitives, a part name per body part), `model.game_ready` (origin, LODs, collider, prefab), `model.bake` |
| Skeleton and skin of the three characters | `assets/models/*.rig.json` | `rig.create` (templates `humanoid` and `quadruped`), `skin3d.*` (the torch is a rigid part of the hand), `rig.bake` |
| Clips: idle, walk, run, trot, gallop, hit | `anim/*.anim.json` | `anim3d.generate` (stride, cadence and ground speed come out of the generator) |
| Clips: the warden's torch swing, the wolf's bite | `anim/warden_attack`, `anim/*_bite` | `anim3d.create`, `anim3d.set_keys` (hand keyed), checked with `anim3d.preview` filmstrips |
| Sound effects: swing, hits, growls, bites, howls, log pick-up and feed, footsteps, fire crackle, the interface family | `assets/audio/*.sfx.json`, `assets/audio/ui/` | `sfx.preset`, `sfx.edit`, `sfx.family`, `sfx.render` (variants for the sounds heard often), `assets.regenerate` |
| Loops: fire, wind | `assets/audio/fire_loop.wav`, `wind_loop.wav` | `assets.generate_loop` |
| The distant howl | `assets/audio/distant_howl.audio.json` | `audio.create` (a chain of steps) |
| Music: title, night (sections intro / calm / hunt / outro; layers base, pulse, tension, voice), dawn, defeat | `assets/music/*.song.json` | `music.create`, `music.edit`, `music.check`, `music.render` (stems per layer, loop points) |

The 3D clips under `anim/` have a record in `assets.json` too. A clip `anim3d.generate` made and nobody edited has a recipe
(`assets.regenerate {"stale": true}` remakes it when its rig is fitted again); a clip keyed further by hand has a record
without a recipe, because regenerating would drop the keys. The assets test checks both.

## How it plays and sounds

- **Characters** are rigged models moved by a `CharacterController3D` and played by an `Animator`: the warden blends
  idle, walk, run, hit and attack; the wolves blend idle, trot and gallop by their speed and play bite and hit. Clip
  events (`warden_swing_hit` on the downswing, `wolf_bite_hit` as the jaws close, `warden_step` on the foot contacts)
  drive the damage and the footsteps, so the animation and the hit cannot drift apart.
- **The fire** is the clock and the light: the point light, the flames, the sparks and the `AudioSource` loop follow its
  fuel, and wolves slow down inside its light.
- **Dawn** warms the sky, the fog, the ambient light and the moon light through `world.settings`.
- **Music** is one `MusicPlayer` with a director script: the intensity follows the danger (wolves alive, low fuel, the
  alpha), the song moves between its `calm` and `hunt` sections on the bar, the alpha's howl is a ducking stinger, and
  the game crossfades into the dawn song and the defeat song.
- **Sounds**: one-shots are placed by `playAt` in `scripts/common.js` (attenuation and pan computed by hand, because
  `audio.play` has no position).
- **Menus** are the engine's menu kit (`project.add_menu_kit`: title, options, credits, pause, loading) plus the end
  panel of the game; the text is in `locales/en.json`.

## Tests

`tests/kindlewatch.test.js` (a gamepad bot in `tests/helpers/bot.js` plays like a person) covers the title to the game,
movement and animation, the walls, piles and feeding, a wolf biting the fire, two swings killing a wolf, a bite taking a
heart, the alpha's rage, dawn restocking and healing, losing by fire and by hearts and retrying, winning and going back
to the menu, pause, an end panel that arrives after its scene is gone, and a whole game won by the bot.
`tests/assets.test.js` checks the provenance and the freshness of every asset. `tests/recipe.test.js` is the menu kit's.
`replays/first_night.json` is an input replay (carry logs to the fire, swing the torch) recorded with `input.record`.
`tools/cli/tests/perf/kindlewatch.perf.json` holds the perf budget: 75 draw calls and 164 entities on the game scene.

## What these tools reached

Measured against the games that used providers, as honestly as one game allows:

- **Reached well**: sound effects (a few oscillators, noise and an envelope give a convincing swing, bite and footstep,
  and variants make repetition bearable); the music (a layered song with sections that the game steers reacts to play,
  which a generated loop cannot); the rigs (a humanoid and a quadruped are fitted, skinned and walking in a few calls,
  with ground speeds that match the movement code); the pixel-art tools (palette locking, outline and dither commands
  keep one look); and provenance (every file can be rebuilt).
- **Reached with effort**: low-poly models read well from a high camera but look like primitives; the wolves are
  recognised by silhouette and eyes. Hand-keyed clips (bite, torch swing) took trial and error on the axis signs.
  Pictures larger than a small icon (the logo, the sky) are the slowest to make by commands.
- **Not reached**: painterly art, faces, anything that wants a human hand. A provider still wins there.
- **Cost found**: the music player keeps hundreds of MB of audio in memory (see the feedback file).

The 21 gaps are in `ENGINE_FEEDBACK.json` (3 major, 12 minor, 6 nice-to-have). One of them blocked validation and is
fixed in the same change: the `assets.json` schema rejected the provenance that `model.game_ready` and `model.bake` write.

## Files

- `scenes/menu.scene.json` (title), `scenes/game.scene.json` (the clearing), `scenes/loading.scene.json`
- `scripts/`: `game.js` (nights, spawning, win and lose), `warden.js`, `wolf.js`, `fire.js`, `log_pile.js`, `hud.js`,
  `camera.js`, `music_director.js`, `common.js`; the menu kit (`main_menu.js`, `pause_menu.js`, `settings.js`, `ui/`)
- `prefabs/`: `wolf`, `alpha_wolf`, `puff`, `embers`; the model prefabs are in `assets/models/`
- `locales/en.json`, `anim/`, `assets/`, `replays/`, `tests/`
