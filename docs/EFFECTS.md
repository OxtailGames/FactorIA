# Effects: the loop, and three worked examples

A hit, a pickup or a fire is made in a loop: draft it from what the art direction says, film it at the size the player sees,
LOOK, change one thing, film again. This guide is the loop and three effects made with it, written with the engine's own
commands: no effect is shipped in the engine for you to copy. The pieces are the ones in [ASSETS.md](ASSETS.md)
("Animations drawn with code": `assets.animate_svg` with `ramp` and `layers`) and [GAME_FEEL.md](GAME_FEEL.md) (shake, hit-stop,
flash, knockback, squash, and the same as data in clip events). Their numbers are examples to start from: change them for your
game.

## The loop

1. **Ask the style first.** The palette, the outline weight and the size things are drawn at are the art direction
   (`assets.json` `style`, the project's art notes). An effect uses 3 or 4 colours of that palette as a `ramp` (dark to bright),
   never colours of its own. The size is the size of the `Sprite` in the scene (not the size of the sheet's cells).
2. **Draft.** Write the module (`assets/src/anim/<name>.anim.js`: it returns the SVG of one frame from `progress`, `rampAt(u)`
   and `layer`) and bake it with `assets.animate_svg`, with `layers` when the effect passes behind and in front of something. Draw
   at 100 x 100 and think in the size it will be: a line thinner than 1 pixel at game size is not there.
3. **Film it at the game's size.** `assets.contact_sheet {"paths": [...], "allFrames": true, "sizes": [<pixels on screen>],
   "greyscale": true}` draws every frame of every sheet at that size over a light, a dark and the camera's background, plus
   greyscale (a temporary picture: look at it). `assets.preview_sheet {"path": ..., "onion": true}` shows the frames numbered
   with the pivot and warns about empty, cut or jumping frames. To see it in the running scene, `game.screenshot
   {"frames": 12, "everyFrames": 2, "region": [x, y, w, h], "zoom": 4}` films the game itself.
4. **Look, and judge with this list.**
   - *Readable at game size.* Can you tell what it is at the size of the sheet, on all three backgrounds? Strokes under 2 pixels
     and tiny parts vanish. In the greyscale row, do the parts keep their order of brightness? If two parts become the same grey
     the palette is doing the work alone.
   - *Anticipation.* Something that happens before the impact (a wind-up, the coin leaving, a flicker) tells the player it is
     coming. A hit with none looks like a bug; one that lasts more than about 0.15 s feels slow.
   - *Impact.* The biggest, brightest frame is the first or second one, not the fifth: the eye lands where the frame
     changes most. The game's part of the impact is `feel`: a hit-stop of 0.04 to 0.08 s, a shake, a flash.
   - *Recovery.* After the peak it grows less, thins and fades; the last frame is nearly empty and the sprite is destroyed
     (`lifetime`) a moment after it, so nothing is left behind. It leads into the idle pose without a pop.
   - *Palette.* 3 or 4 colours of the ramp, the brightest only for the contact. An effect brighter than the thing it hits hides it.
5. **Refine one thing, rebake, film again.** `overwrite: true` replaces the sheets; the warnings of the bake are part of the
   look (a shape touching the edge of the cell is cut off; a frame that draws nothing; a loop that jumps). Stop when each point of
   the list holds; a second pass over a good effect makes it worse.
6. **Put it in the scene and play it.** The sheets are sprites; the layers are three entities of one prefab (`prefab` on the
   `assets.animate_svg` call writes it). Where the
   effect is part of an attack, the timing lives in the animation clip as an event (below), so tuning it is editing data.

A paid image provider is not part of this: an effect that follows rules is code, free and deterministic. A painted frame by
frame effect is a provider's job (docs/ASSETS.md).

## Example 1: an impact (hit spark)

The contact of a sword. Three layers: the ring behind the target (`back`), shards in front (`front`) and a flash disc that is
added (`light`). `assets/src/anim/impact.anim.js`:

```js
// A hit: a flash disc, a shock ring and eight shards. Frame 0 is the contact (everything at its brightest and
// closest to the centre), the rest is the recovery: it grows, thins and fades.
export default function frame({ layer, progress, rngFor, rampAt }) {
  const out = (inner) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${inner}</svg>`;
  const ease = 1 - (1 - progress) ** 3;       // cubic out: a hard start, a long tail
  const fade = Math.max(0.1, 1 - progress);
  if (layer === "back") {                      // the shock ring, behind the target
    const r = 16 + ease * 30;
    return out(`<circle cx="50" cy="50" r="${r.toFixed(1)}" fill="none" stroke="${rampAt(0.75)}" stroke-width="${Math.max(1, 8 * (1 - progress)).toFixed(1)}" opacity="${fade.toFixed(2)}"/>`);
  }
  if (layer === "light") {                     // the flash of contact, added
    const r = 30 * (1 - progress * 0.6);
    return out(`<circle cx="50" cy="50" r="${r.toFixed(1)}" fill="${rampAt(1)}" opacity="${(0.9 * (1 - progress) ** 2).toFixed(2)}"/>`);
  }
  const rnd = rngFor("shards");                // front: shards that fly out along fixed angles
  let s = "";
  for (let i = 0; i < 8; i++) {
    const a = (i / 8) * Math.PI * 2 + rnd() * 0.5;
    const d = 8 + ease * (16 + rnd() * 10), len = 3 + (1 - progress) * 9;
    const x = 50 + Math.cos(a) * d, y = 50 + Math.sin(a) * d;
    s += `<line x1="${x.toFixed(1)}" y1="${y.toFixed(1)}" x2="${(x + Math.cos(a) * len).toFixed(1)}" y2="${(y + Math.sin(a) * len).toFixed(1)}" stroke="${rampAt(0.8)}" stroke-width="5" stroke-linecap="round" opacity="${fade.toFixed(2)}"/>`;
  }
  return out(s);
}
```

```
assets.animate_svg {"path":"assets/fx/impact.png","source":"assets/src/anim/impact.anim.js","frames":6,"fps":24,"loop":false,"frameWidth":64,"padding":2,"layers":["back","front","light"],"ramp":["#3a0d0d","#c2412b","#ff9a3c","#fff2c2"]}
assets.contact_sheet {"paths":["assets/fx/impact_back.png","assets/fx/impact_front.png"],"allFrames":true,"sizes":[48],"columns":6,"greyscale":true}
```

An illustration of what the first draft of this effect can show at 48 pixels, and what changes (this is the "look and refine" of the loop, not a polish pass): the
shards were 3 pixels thick and nearly gone on the light background (now 5); the ring was the same grey as the ground in the
greyscale row (its colour moved from `rampAt(0.5)` to `rampAt(0.75)` and it starts at a radius of 16 instead of 10, so frame 0
is a ring and not a dot); and the bake warned that shapes of the `front` layer touched the edge of the cell in frame 3 (the
reach of the shards went from 22 + 14 to 16 + 10). Frames at 24 fps: the contact is frame 0 (0 s), the recovery ends at 0.25 s.

Wire it. The prefab `prefabs/impact.prefab.json` is a parent with three child Sprites, each with `"SpriteAnimator": {"clip":
"impact"}` and its own sheet (`impact_back.png` at a `layer` below the character's, `impact_front.png` above it, `impact_light.png`
above that with `"blend": "additive"`): the result of the bake lists them in `layers` and `nextSteps`. The timing of the hit is
then an event of the attack clip, so anticipation, impact and recovery are data:

```
anim.add_event {"path":"anim/hero_attack.anim.json","t":0.18,"feel":[{"action":"hitStop","duration":0.06},{"action":"shake","amount":0.3},{"action":"spawn","prefab":"prefabs/impact.prefab.json","offset":[30,0,0],"local":true,"lifetime":0.3},{"action":"sound","path":"assets/sfx/hit.wav"}]}
```

`t` 0 to 0.18 is the wind-up of the clip (the anticipation: the arm goes back), the event fires on the contact frame, and what
the clip does after is the recovery. `local: true` puts the spark 30 pixels in front of a character that faces left too. The
target that is hit flashes in the script that deals the damage: `enemy.flash({ color: "#ffffff", duration: 0.1 })`
([GAME_FEEL.md](GAME_FEEL.md), "Worked example: a sword hit").

## Example 2: a pickup (coin sparkle)

Sky Hopper (`examples/sky-hopper`) plays this when the hero takes a coin. A pickup has no wind-up: the coin itself is the
anticipation (it is there, then it is not), so the budget goes to the impact and a clean recovery. The module is
`examples/sky-hopper/assets/src/anim/coin_sparkle.anim.js` (a ring that opens behind the hero, five four-point glints in front
and a soft glow added on top); the bake and the look:

```
assets.animate_svg {"path":"assets/fx/coin_sparkle.png","source":"assets/src/anim/coin_sparkle.anim.js","frames":8,"fps":16,"loop":false,"frameWidth":96,"padding":2,"layers":["back","front","light"],"ramp":["#5a3a05","#c98a14","#f2c94c","#fff6c8"]}
assets.contact_sheet {"paths":["assets/fx/coin_sparkle_back.png","assets/fx/coin_sparkle_front.png","assets/fx/coin_sparkle_light.png"],"allFrames":true,"sizes":[64],"columns":8}
```

An illustration of a first draft: a glow that started small and peaked in frame 4, glints too small to read at 64 pixels and a ring too pale on
the light background: the glow now starts at its biggest (the impact is frame 1), the glints are bigger and the ring is
thicker. Frames at 16 fps with 8 frames last 0.5 s. `padding: 2` and `frameWidth: 96` give a 300 x 300 sheet, a multiple of
4: `project.validate` warns about textures that cannot be GPU-compressed on a phone otherwise (a padding of 1 gave 294).

The game plays it with one call, at the place of the coin (the target-less form, so it does not depend on the coin being alive):

```js
import { feel } from "factoria";
feel.do({ action: "spawn", prefab: "prefabs/coin_sparkle.prefab.json", offset: [p.x, p.y, 0], lifetime: 0.55 });
```

`lifetime` is game time: 0.55 s is a little more than the clip, and then the entity is destroyed. The prefab is a parent with
the three layers as children: `Back` at `Sprite.layer` 2 (the hero's parts are 3 to 9), `Front` at 20, `Light` at 21 with
`"blend": "additive"`, all three with `"SpriteAnimator": {"clip": "coin_sparkle"}`. `assets.animate_svg` writes that file
itself: add `"prefab": {"path": "prefabs/coin_sparkle.prefab.json", "size": [72, 72], "layers": {"back": 2, "front": 20,
"light": 21}, "tags": ["fx"]}` to the bake above and the result is byte for byte the prefab of the example (the parent is
named "Coin Sparkle" from the file name). The call is refused, before baking anything, when the prefab already exists, so a
hand-edited one is not lost: pass `"overwrite": true` inside `prefab` to write it again. The same module recoloured for a
silver coin is the same call with another `ramp` and the sheets baked again.

## Example 3: a fire that loops

A torch flame is the opposite problem: no impact, only a loop that must not pop. `assets/src/anim/flame.anim.js` draws three
tongues whose sway and height are whole turns of `progress` (`progress` is `frame / frames` for a looping clip, so the last
frame leads into the first):

```js
export default function frame({ progress, rampAt }) {
  const turn = progress * Math.PI * 2;
  const sway = Math.sin(turn) * 3;
  const lick = (k, phase) => 1 + 0.12 * Math.sin(turn * k + phase);
  const tongue = (w, h, c, k, p) =>
    `<path d="M${50 - w} 90 C${50 - w} 60 ${50 + sway * 0.5} ${90 - h * lick(k, p)} ${50 + sway} ${90 - h * lick(k, p)} C${50 + sway * 0.4} ${60} ${50 + w} 60 ${50 + w} 90 Z" fill="${rampAt(c)}"/>`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">${tongue(24, 72, 0.25, 1, 0)}${tongue(16, 54, 0.6, 2, 1.3)}${tongue(8, 34, 0.95, 3, 2.1)}</svg>`;
}
```

```
assets.animate_svg {"path":"assets/fx/flame.png","source":"assets/src/anim/flame.anim.js","frames":8,"fps":12,"frameWidth":64,"padding":2,"pivot":[0.5,1],"ramp":["#4a1204","#d9480f","#ffa94d","#fff3bf"]}
assets.contact_sheet {"paths":["assets/fx/flame.png"],"allFrames":true,"sizes":[48],"greyscale":true}
assets.preview_sheet {"path":"assets/fx/flame.png","onion":true}
```

`pivot [0.5, 1]` keeps the base of the flame on the torch (the sheet pivot is from the top-left; the `Sprite.pivot` that goes with
it is `[0.5, 0]`). The checks of the loop for a fire: all three tongues stay distinct in the greyscale row (their ramp positions
0.25, 0.6 and 0.95 are far apart), no frame jumps (the onion skin of `preview_sheet` and its warning about a last frame that
repeats or jumps from the first), and the flame is readable at the size of the torch. Put it in the scene as a `Sprite` with
`"SpriteAnimator": {"clip": "flame"}` and `Sprite.blend` `alpha` (the default); add a `Light2D` or a bloom camera for the glow
([RENDERING.md](RENDERING.md)) instead of a halo drawn into the frames.

Colours are the part to change last: the same module, baked again with
`"ramp":["#0b1d3a","#2a6fd6","#8ec5ff","#eaf6ff"]` and `path` `assets/fx/flame_ice.png`, is an ice fire without touching the code.
For a module (or a SMIL SVG) that draws in greys, `rampMap: true` colours the finished frames instead.

## Checking an effect: effect documents and baked sheets

Two kinds of effect, two ways to look at the result.

- **An effect document** (`*.vfx.json`: emitters, lights, sounds and feel commands on one timeline, see [PARTICLES.md](PARTICLES.md)):
  `vfx.budget` counts what it costs (particles alive, overdraw, lights) and says what to change for a phone, `vfx.filmstrip` plays it
  and returns the frames as one picture, and `vfx.review` runs both and gives them to the art critic. Use it when the effect is many small
  random things or needs sound and feel at the same instant; "Reviewing an effect" in [PARTICLES.md](PARTICLES.md) has the arguments.
- **A baked sheet** (the drawn effect of this page, an `assets.animate_svg` sheet): `assets.contact_sheet` and `assets.preview_sheet`
  show the frames, and the art critic (`assets.review`, when a vision model is set up) takes the sheet like any picture.

None of these grades timing or readability for you: the judging list above is read by the one who looks at the picture. A drawn effect
can also be played from an effect document (a prefab spawned by a `feel.spawn` command part), so the two ways combine.
