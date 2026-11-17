# Assets: animations written as code

[Assets](../ASSETS.md) > Assets: animations written as code

### Animations drawn with code: assets.animate_svg

For motion that follows rules (a coin that turns, a pulsing orb, a flame, a loader, rain, waves) an agent with no image
provider writes the animation as code and bakes it into a sprite sheet: `assets.animate_svg` draws every frame, lays the
frames out in a grid and writes the PNG plus its `sheet` entry of `assets.json` in one call, ready for a `Sprite` and a
`SpriteAnimator`. Two ways to say what each frame looks like:

- **`source`: a JavaScript module** of the project (by convention `art/<name>.anim.js`). Its default export draws one frame
  and returns the SVG text: `frame({t, frame, frames, fps, progress, params, rng}) => string`.
- **`svg`: one SVG with SMIL animation** (`<animate>`, `<set>`, `<animateTransform>`, `<animateMotion>`), the kind of
  animated SVG an AI writes when asked for one. It is sampled at every frame time. A project `.svg` file also works as
  `source`.

A worked example, a coin turning around its vertical axis. `art/coin_spin.anim.js`:

```js
// A coin turning around its vertical axis. `progress` runs 0..1 over the clip, so the last frame leads into the first.
export default function frame({ progress, params, rng }) {
  const turn = Math.cos(progress * Math.PI * 2);        // 1 = face on, 0 = edge on, -1 = the back
  const rx = Math.max(3, Math.abs(turn) * 34);          // the coin gets thin when it is edge on
  const fill = turn >= 0 ? params.face : params.back;
  const glint = turn > 0.6 ? `<ellipse cx="${50 - rx * 0.45}" cy="36" rx="${rx * 0.18}" ry="9" fill="#fff" opacity="0.55"/>` : "";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
    <ellipse cx="50" cy="50" rx="${rx}" ry="38" fill="${fill}" stroke="#7a5a12" stroke-width="4"/>
    ${glint}
  </svg>`;
}
```

```
assets.animate_svg {"path":"assets/art/coin_spin.png","source":"art/coin_spin.anim.js","frames":12,"fps":12,"frameWidth":64,"frameHeight":64,"padding":1,"params":{"face":"#f2c94c","back":"#b8902b"}}
```

The result has the sheet as an image (look at it, edit the module, call again with `overwrite: true`), the `layout`
(`columns`, `rows`, the cell size, `imageWidth` and `imageHeight`, the clips), the `sheet` entry that was recorded,
`warnings` and the `nextSteps` to play it. For SMIL: `assets.animate_svg {"path":"assets/art/loader.png","svg":"<svg ...>
<animateTransform attributeName=\"transform\" type=\"rotate\" from=\"0 50 50\" to=\"360 50 50\" dur=\"1s\"
repeatCount=\"indefinite\"/> ...</svg>","fps":12,"frameWidth":64}`: without `frames` the sheet takes one pass of the
animation (`cycleSeconds * fps` frames).

- **Frames.** `frames` frames at `fps`; frame `i` is drawn at `t = i / fps`. `frames` is required with a module; with SMIL
  it defaults to one pass of the animation. `loop` (default true) is how the clip repeats and how `progress` is read:
  `progress` is `frame / frames` for a looping clip (it reaches 1 only after the last frame, so the last frame leads into
  the first) and `frame / (frames - 1)` for `loop: false` (the last frame is the end pose).
- **What the module receives.** `t` (seconds), `frame` (from 0, inside the clip), `frames` (the clip's length), `fps`,
  `progress`, `params` (the `params` argument: colours, counts, amplitudes, so one module serves several sheets), `rng`,
  `seed`, `rngFor`, `clip`, `sheetFrame` (the index in the whole sheet), `width` and `height` (the cell in pixels).
  `rng()` is a random number in 0..1 seeded from `seed` and the frame (`rng.range(a, b)`, `rng.int(n)`, `rng.pick(list)`,
  `rng.chance(p)`, `rng.gauss()` too): each frame has its own stream. `rngFor(key)` gives the SAME stream on every frame
  for one key, for what must stay where it is (the sparkles of a gem: `const r = rngFor("sparkles")`, then draw the same
  `r()` positions and vary only their brightness with `progress`).
- **The sandbox.** The module runs in a QuickJS context of its own, thrown away after the call: the language only
  (`Math`, `JSON`, `Array`, `Map`...), no engine bindings, no DOM, no Node, no timers, no network or files. It may `import`
  other project files with a relative path (`import { disc } from "./lib/shapes.js"`); the imported files count as inputs of
  the recipe. `Math.random` is a seeded stream and `Date` is a fixed day moved to the frame's time, so the same module draws
  the same frames on every run and every machine. Loading the module and each frame have a time limit
  (`timeLimitMs`, 2000 by default) and the context has a memory limit of 128 MB. `console.log` output comes back in the
  result's `console`.
- **Errors teach.** A mistake in the module comes back as `art/coin_spin.anim.js:5:17: ReferenceError: nothing is not
  defined (while drawing frame 2 of 12, t = 0.1667 s)` followed by the source line and a caret; a frame that returns
  something that is not an SVG string, a missing default export, an import that leaves the project and an endless loop
  (named with the limit and the frame) each say what to change.
- **Rasterizing.** Every frame is rasterized as `assets.rasterize_svg` does it (same renderer, same support and same
  unsupported list: no text, filters, `<use>` or CSS classes), transparent, fitted inside the `frameWidth` x `frameHeight`
  cell (default 64 x 64; `frameHeight` defaults to `frameWidth`; at most 1024), aspect kept, centred. `style`,
  `styleStrength` and `seed` give the painterly look of `rasterize_svg` to every frame; the style's seed is the same for all
  frames, so the paper texture stays put while the drawing moves. `palette` (a list of `"#rrggbb"`, or the project path of an
  image whose colours are the palette, at most 256) snaps every pixel to those colours and keeps the alpha.
- **Layout.** The frames go row by row in a grid of `columns` (default `ceil(sqrt(frames))`). `padding` (pixels, default 0)
  is a transparent gutter around every cell, so filtered sprites do not pick up their neighbour: cell `i` starts at
  `x = padding + column * (frameWidth + 2 * padding)`, the same for y, and the PNG is `columns * (frameWidth + 2 * padding)`
  wide. The sheet may be up to 8192 px a side (a warning over 4096, which some phones cannot sample). The sheet entry records
  `padding` and `pivot` (`[x, y]` in 0..1 from the top-left, default the centre) beside `columns`, `rows`, `frameWidth`,
  `frameHeight` and `frames`.
- **Clips.** `clips: [{"name":"idle","frames":4,"fps":6},{"name":"run","frames":8,"fps":12,"loop":true,"pivot":[0.5,1]}]`
  makes several animations from one module, laid out one after another in one sheet. Give `frames` per clip, not at the top
  level. The module receives `clip` (the name) and `frame` counted from 0 inside that clip (a clip's own `params` are merged over
  the top-level ones), so it draws `idle` or `run`. Each clip becomes a clip of the sheet entry (`firstFrame`, `lastFrame`,
  `fps`, `loop`, `pivot`). Without `clips` the entry has one clip named like the file, which keeps `fps` and `loop`. Clips need a
  module: one SMIL SVG has one timeline.
- **SMIL.** Sampled: `<animate>`, `<set>`, `<animateTransform>` (`translate`, `scale`, `rotate`, `skewX`, `skewY`) and
  `<animateMotion>` (`path`, `<mpath>`, `values`/`from`/`to`/`by`, `rotate="auto"`), with `begin` (offsets, several values,
  `id.begin` and `id.end` sync-bases with an offset), `end`, `dur`, `repeatCount`, `repeatDur`, `fill="freeze"`, `values`,
  `keyTimes`, `keySplines`, `calcMode` (`linear`, `discrete`, `paced`, `spline`), `from`/`to`/`by`, `additive` and
  `accumulate`. Numbers, lengths, colours (in RGB) and any value that is the same text around numbers (path data of the same
  structure, `points`, `viewBox`) are interpolated; any other value changes at its key time. Not sampled, each a warning that
  names the element: event begins (`click`...), CSS animations, `<style>` rules and `restart`/`min`/`max`.
- **Colours of the effect: `ramp` and `rampAt`.** `ramp` is the effect's colours from dark to bright: a list of 2 to 32
  `"#rrggbb"`, or the project path of an image document (`*.image.json`) that declares `ramps` (the ramps of `image.palette`;
  `rampIndex` picks one, 0 is the first). The module receives `ramp` (the list) and `rampAt(u)`, the colour at `u` from 0
  (dark) to 1 (bright), blended between neighbours, as `"#rrggbb"`. A flame that draws `fill="${rampAt(0.85)}"` is recoloured
  as ice by baking again with another `ramp`, without touching the code:
  `assets.animate_svg {"path":"assets/art/flame.png","source":"art/flame.anim.js","frames":8,"fps":12,"ramp":["#0b1d3a","#2a6fd6","#bfeaff"],"overwrite":true}`.
  `rampAt` without a `ramp` is an error that says so, and a `ramp` the module never reads is a warning (the colours would
  have no effect). `rampMap: true` recolours the finished frames instead: the darkest pixel takes the first colour of the ramp,
  the brightest the last (by luminance, alpha kept). That is the way for a SMIL SVG (which has no code to read `ramp`; a
  `ramp` without `rampMap` is an error there) and for a module that draws in greys. The order of the passes is rasterize,
  `rampMap`, then `palette` snapping. The recipe records `ramp` (and `rampIndex`, `rampMap`), and an image document counts as an
  input, so `assets.regenerate` and `project.validate` see a changed ramp as a stale sheet.
- **Back, front and light layers.** An effect often goes behind the character, in front of it and glows. `layers` (module only)
  is a list from `back`, `front` and `light`, in any order. The module is called once per layer and frame with `layer` set to
  the name and returns the SVG of that layer (an empty `<svg/>` is a layer that is idle in that frame; a layer that draws
  nothing in any frame is a warning). Each layer is its own sheet next to `path`: `assets/art/hit.png` gives
  `hit_back.png`, `hit_front.png` and `hit_light.png`, each with its `sheet` entry (same `columns`, `rows`, cell size, `padding`,
  `pivot`, clips, frames and `fps`), so the layers stay in step when each plays on its own entity. Every layer of a frame
  draws from the same random stream, so a shape drawn in two layers lines up. Play them as three entities at the same place:
  `back` with a lower `Sprite.layer` than the character, `front` with a higher one and `light` with `Sprite.blend` set to
  `additive` (its colours add to what is under it: draw soft bright glows on it) and a `SpriteAnimator` with the same clip
  on each. The result's `layers` lists `{layer, path, use}`, `path` is the first layer's sheet, and the image is the layers
  stacked on a dark ground (the light added), so one look shows the whole effect. `ramp` and `rampMap` apply to every layer.
  A module with several layers that never names `layer` is a warning (every sheet would be the same drawing). The frames and
  sheets of all layers are held in memory together, at most 1024 MB: a larger bake is refused before anything is drawn (bake
  fewer layers per call, or smaller frames). All sheets are encoded before the first file is written, and if a write fails the
  sheets this call newly made are removed again (a sheet it replaced cannot be, and the error names it). Baking the same
  `path` again with fewer layers deletes the sheets of the earlier bake that this command made for that `path` (its recipe
  says so) together with their entries, and says so in a warning; a file of the same name made by anything else stays.
- **The prefab of the layers: `prefab`.** With `layers`, `"prefab": "prefabs/hit.prefab.json"` also writes the entities that
  play them together, so the effect is one call. The file is a parent entity (named after the file, "Hit"; `name` changes it)
  with one child per baked layer in the order Back, Front, Light. Each child has a `Transform` at the parent's origin, a
  `Sprite` on that layer's sheet and a `SpriteAnimator` on the sheet's first clip (the clip every layer shares, so they stay in
  step; with several `clips`, the result warns that the first one plays). The Light child has `"blend": "additive"`. `prefab` is
  the path, or an object `{path, name, tags, size, layers, pixelArt, overwrite}`: `size` is the `Sprite.size` in world units
  `[w, h]` (default one frame in pixels), `layers` the `Sprite.layer` of each layer (`{"back": 2, "front": 20, "light": 21}`;
  default -1, 1 and 2: put the character's layer between `back` and `front`), `tags` the parent's tags and `pixelArt` the
  filtering (default `false`: smooth). The result has `prefab` (`{path, name, clip, size, children: [{name, texture, layer,
  blend}]}`) and the next steps say how to spawn it (`feel.do({action: "spawn", prefab, offset, lifetime})` from a script,
  or `scene.spawn`; a clip with `loop: false` stays on its last frame, so spawn it with a `lifetime`). A prefab that already
  exists is never replaced unless the object has `overwrite: true`; the check happens before anything is drawn, because the
  prefab may hold changes made by hand and the command's own `overwrite` is about the sheets. The prefab is written after the
  sheets are recorded, with the same layout as `scene.save`. It is not part of the recipe: `assets.regenerate` remakes the
  sheets and leaves the prefab as it is. Without `layers` the command refuses `prefab` and says so (one sheet is one Sprite you
  place yourself).
- **Sheet sizes on a phone.** When `factoria.json` lists `android` or `ios` in `platforms`, a sheet whose width or height is
  not a multiple of 4 gets a warning: the export GPU-compresses textures on those platforms, which needs both sides to be
  multiples of 4, and ships any other as an uncompressed PNG (see "Multiples of 4" under the export's texture
  compression). The warning names the `padding` that fixes it (96 px frames with `padding: 1` in a 3 x 3 grid make 294 x 294;
  `padding: 2` gives 300 x 300) and the larger frame size that would also do. It is not said for a project that targets no
  phone, nor for a sheet whose import settings turn `compression` off or put it in an atlas.

- **Warnings.** Frames that draw nothing (the shapes sit outside the viewBox, or the module returned an empty drawing), shapes
  touching the edge of the cell (they may be cut off: draw smaller, enlarge the frame, or add `padding`), a loop whose last
  frame jumps from the first (a pop when it repeats) or repeats it (a stop for one frame), SMIL that is not sampled, features
  `rasterize_svg` does not draw. A frame that draws nothing is a warning, not an error: a blink may be empty on purpose.
- **Provenance.** By default the record is origin `generated`, `ai` true (the agent wrote the code, which counts for the
  store's AI-content disclosure); pass `ai: false`, `author` and `license` for art a person drew, and the record is origin
  `original`. It carries a `recipe`: the command, the arguments that make the same bytes again (paths project-relative,
  `seed` explicit) and the module with every file it imported, each with its SHA-256. Calling the command with the recipe's
  `args` (and `overwrite: true`) makes the identical sheet; the same module, arguments and seed always give the same bytes.

Playing the sheet: the result's `nextSteps` give the `Sprite` and `SpriteAnimator` settings for the whole sheet and for
each clip, and the call that checks it (`assets.preview_sheet`). The best way to play a clip is by name:
`SpriteAnimator {"clip": "run"}` on an entity whose `Sprite.texture` is the sheet, or `entity.spriteAnimator.play("run")`
from a script. The sheet's grid (`columns`, `rows`), `padding`, the clip's `fps`, `loop` and range all come from the
`sheet` entry; the numeric fields (`columns`, `rows`, `firstFrame`, `lastFrame`, `fps`, `loop`) still work, and when you
set one on the component it overrides the clip's value. A wrong clip name is an error that lists the clips of the sheet and
suggests the closest one (`project.validate` finds it in a scene or prefab too). `padding` is skipped by the animator by
itself whenever its `columns` and `rows` are the sheet's, so a sheet with a gutter needs no extra setting.
`pivot` of the sheet and of a clip is `[x, y]` in 0..1 counted from the TOP-left of the frame (as in the PNG); `Sprite.pivot`
counts from the BOTTOM-left, so the animator uses `[x, 1 - y]`. It does so only when the `Sprite` has no pivot of its own
(`Sprite.pivot` still `[0.5, 0.5]`) and `SpriteAnimator.sheetPivot` is true; a sprite that sets another pivot keeps it. The
sheet's pivot is applied when the sprite is drawn and measured, it is not written into `Sprite.pivot`.

The loop around it (draft, film at the game's size with `assets.contact_sheet`, look, refine) and three worked effects are in
[EFFECTS.md](../EFFECTS.md).
