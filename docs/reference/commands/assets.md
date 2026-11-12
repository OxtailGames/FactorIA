[Back to the index](../README.md)

# Commands: assets

## `assets.analyze_audio` (modifies state)

Since 0.1.6.

Measure the loudness of a sound (or of every sound) and keep the result in assets.json.

Capabilities: read, writeProject

Measures integrated loudness (LUFS, ITU-R BS.1770-4 / EBU R128) and sample peak (dBFS) of .wav, .ogg, .mp3 and .qoa files, and stores them under the sound's `analysis` in assets.json together with the size and SHA-256 of the file, so editing the sound later makes the record stale instead of wrong. Sounds with import "normalize": true play at `targetLufs` using that record; without one the desktop engine measures the sound when it loads it, and mobile builds cannot, so run this (or export, which stores it) before shipping. A sound whose record is still fresh is not measured again. Without `path` every sound under assets/ and every sound a scene or prefab names is analyzed. Returns {files: [{path, loudnessLufs, peakDb, seconds, streams, normalize, gainDb, cached, stored}], measured, cached, failed}: `streams` says whether the sound is decoded while it plays (import stream), `gainDb` is the gain normalize would apply (only when normalize is on). A sound that cannot be decoded is listed with `error` and `hint` when no path is given. Example: {"path": "assets/music/theme.ogg"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative sound file, e.g. assets/sfx/jump.wav. Omit to analyze every sound of the project. Path the command reads. |

## `assets.animate_svg` (modifies state)

Since 0.6.0.

Draw an animation with code (a JS module that returns the SVG of each frame, or an SVG with SMIL) and bake it into a sprite sheet PNG plus its `sheet` entry, offline: no provider, no key.

Capabilities: read, writeProject

Writes a sprite sheet at `path` (under assets/, ending in .png) and its `sheet` entry in assets.json in one call, from an animation you write as code. Two ways to draw it. (1) `source`: a project JavaScript module, e.g. "art/coin_spin.anim.js", whose default export is `frame({t, frame, frames, fps, progress, params, rng, seed, rngFor, clip, sheetFrame, width, height, ramp, rampAt, layer}) => string`, the SVG of that frame. t is the time in seconds (frame / fps); frame counts from 0 inside the clip and frames is the clip's length; progress runs 0..1 through the clip (frame / frames for a looping clip, so the last frame leads into the first; frame / (frames - 1) for loop false, so the last frame is the end pose); params is the `params` argument (a clip's own params are merged over it); rng() is a seeded random number in 0..1 for this frame (also rng.range(a, b), rng.int(n), rng.pick(list), rng.chance(p), rng.gauss()), different on every frame; rngFor(key) is a random stream that is the SAME on every frame for one key (a sparkle that stays where it is); clip is the clip name with `clips`.

The module runs in a sandboxed QuickJS context: the language only (Math, JSON, Array...), no engine bindings, no DOM, no timers, no files; it may `import` other project files with a relative path ("./shapes.js"). Math.random is a seeded stream and Date a fixed day moved to the frame's time, so the same module always draws the same frames. Loading and each frame have a time limit (`timeLimitMs`, 2000 by default) and the context a memory limit. A mistake is reported with the module's file, line and column, the source line, and the frame being drawn; console.log output comes back in `console`. (2) `svg` (text) or `source` ending in .svg: one SVG with SMIL animation (<animate>, <set>, <animateTransform>, <animateMotion> with values, keyTimes, keySplines, begin, dur, repeatCount, fill="freeze", additive, accumulate and `id.begin` sync-bases), sampled at t = frame / fps. Without `frames` the sheet takes one pass of the animation (cycle seconds * fps frames). What is not sampled (event begins such as click, CSS animations, the rest of SMIL) is a warning that names the element. Every frame is rasterized exactly as assets.rasterize_svg does (nanosvg: paths, shapes, gradients, strokes, clipPath, mask, pattern; no text or filters) into a transparent `frameWidth` x `frameHeight` cell (default 64 x 64; the SVG is fitted inside, aspect kept, centred), then the painterly `style` / `styleStrength` is applied (the style's seed is `seed`, the same for every frame, so the paper texture stays put while the drawing moves) and the pixels are snapped to `palette` (a list of "#rrggbb" or an image of the project). The frames go row by row in a grid of `columns` (default ceil(sqrt(frames))) with a transparent gutter of `padding` pixels around every cell (cell i starts at x = padding + column * (frameWidth + 2 * padding)). `pivot` ([x, y] in 0..1 from the top-left, default the centre) is recorded in the sheet entry. `clips` makes several named clips from one module: [{name, frames, fps, loop, params, pivot}], laid out one after another in the sheet (do not also give `frames`); the module receives `clip` and draws that animation; each clip becomes a clip of the sheet entry with its fps and loop. Without `clips` the sheet entry has one clip named like the file, so fps and loop are kept. RECOLOUR WITHOUT TOUCHING THE CODE: `ramp` is the effect's colours from dark to bright (a list of 2 to 32 "#rrggbb", or the path of an image document with `ramps` and `rampIndex`, the ramps of image.palette). A module receives them as `ramp` (the list) and `rampAt(u)`, the colour at u from 0 (dark) to 1 (bright), blended between neighbours, so `fill='${rampAt(0.8)}'` is recoloured by changing the `ramp` argument; a module that never names `ramp` gets a warning. `rampMap: true` instead recolours the finished frames by brightness (the darkest pixel takes the first colour, the brightest the last, alpha kept), which also works for a SMIL SVG and for a module that draws in greys. LAYERS: `layers` is a list from back, front and light (module only). Each layer is baked as its own sheet next to `path` (assets/art/hit.png gives hit_back.png, hit_front.png, hit_light.png), from one module that receives `layer` and returns the SVG of that layer (an empty <svg/> is a layer idle in that frame). The sheets have the same grid, frames, fps, clips, pivot and padding, so they stay in step when each plays on its own entity: `back` goes behind the character (a lower Sprite.layer), `front` in front of it (a higher one) and `light` is an additive pass (a Sprite with blend additive, its colours add to what is under it: draw soft bright glows). Every layer of a frame draws from the same random stream. The result lists the layers and returns them stacked on a dark ground. `prefab` (with `layers`) also writes the entities that play them together: a parent with one child per layer, each a Sprite on its sheet (back below, front above, light additive) and a SpriteAnimator on the sheet's first clip, so the effect is one call; see its description for the options, and it is never written over an existing prefab unless `prefab.overwrite` is true. A module that never reads `layer` gets a warning (every layer would be the same drawing). The layers of a call are held in memory together (their frames and sheets, at most 1024 MB): a bake over that is refused before drawing, so bake fewer layers per call. All sheets are encoded before the first is written; if a write fails, the sheets this call made are removed again. Sheets of an earlier bake of the same `path` with other layers (hit_light.png after baking only back and front) are deleted with their entries when this command made them. The result returns the sheet as an image, the layout (columns, rows, cell size, clips) and warnings: frames that draw nothing, shapes touching the edge of the cell, a loop whose last frame jumps from the first (or repeats it), SMIL not sampled, a sheet over 4096 px, and, when factoria.json lists android or ios, a sheet whose width or height is not a multiple of 4 (GPU compression needs it; the warning names the `padding` or the frame size that gives one). Provenance (origin generated, ai true: the calling agent wrote the code; pass ai: false with author and license for art a person drew) carries a recipe (this command, its arguments, the module and the files it imported with their SHA-256), so the sheet can be made again, byte for byte. Use this for motion that follows rules (spin, bob, pulse, sparkle, flame, waves, loaders); for an engine-drawn entity use assets.bake_sheet, for painted frame-by-frame art ask an image provider. Example: {"path":"assets/art/coin_spin.png","source":"art/coin_spin.anim.js","frames":8,"fps":10,"frameWidth":64,"frameHeight":64,"padding":1} with art/coin_spin.anim.js = "export default function frame({progress}) { const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 40; return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><ellipse cx='50' cy='50' rx='${w + 4}' ry='42' fill='#e8c66a' stroke='#8b6a1e' stroke-width='4'/></svg>`; }"

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the sheet, project-relative, under assets/ and ending in .png. With `layers` it is the base name: hit.png gives hit_back.png, hit_front.png and hit_light.png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `source` | string | no | A project-relative JavaScript module whose default export draws one frame ("art/coin_spin.anim.js"), or an .svg file with SMIL animation. Give this or `svg`. Path the command reads. |
| `svg` | string | no | One SVG with SMIL animation as text, sampled at every frame. Give this or `source`. |
| `frames` | integer | no | Number of frames. Required with a module; with SMIL the default is one pass of the animation. Not with `clips` (they give their own). |
| `fps` | number | no | Frames per second: t = frame / fps, and the fps of the sheet's clip. Default 12. |
| `loop` | boolean | no | Whether the clip repeats. Decides `progress` (frame / frames when true, frame / (frames - 1) when false) and the loop-jump warning. Default true. |
| `columns` | integer | no | Frames per row of the sheet. Default ceil(sqrt(frames)). |
| `frameWidth` | integer | no | Width of one frame in pixels; the SVG is fitted inside, aspect kept, centred. Default 64. |
| `frameHeight` | integer | no | Height of one frame in pixels. Default: frameWidth. |
| `params` | object | no | Passed to the module as `params` (colours, counts, amplitudes), so one module serves several sheets. |
| `seed` | integer | no | Seeds rng, Math.random and rngFor of the module, and the painterly style. The same seed always gives the same sheet. Default 0. |
| `clips` | array | no | Several named clips from one module, laid out one after another: [{name, frames, fps, loop, params, pivot}]. Module only. |
| `pivot` | array | no | [x, y] in 0..1 from the top-left of the frame: the point that stays still. Recorded in the sheet entry. Default [0.5, 0.5]. |
| `palette` | any | no | Snap every pixel to these colours: a list of "#rrggbb" strings, or the project-relative path of an image whose distinct opaque colours are the palette (at most 256). Alpha is kept. |
| `ramp` | any | no | The effect's colours from dark to bright: a list of 2 to 32 "#rrggbb" strings, or the project path of an image document (*.image.json) that declares `ramps` (pick one with rampIndex). A module reads them as `ramp` and `rampAt(u)`; with rampMap the frames are recoloured by brightness. Change it and bake again to recolour the effect. |
| `rampIndex` | integer | no | Which ramp of the image document named by `ramp` (0 is the first one image.palette lists). Only with a document. |
| `rampMap` | boolean | no | Recolour the finished frames by brightness with `ramp` (dark pixels take its first colour, bright ones its last; alpha kept). Needed for a SMIL SVG; a module may use rampAt instead. Default false. |
| `layers` | array | no | Bake one sheet per layer (back, front, light), module only: the module receives `layer`. The files are <path>_<layer>.png with the same grid, fps, clips and pivot. back is drawn behind the character, front in front of it, light is an additive glow. |
| `prefab` | any | no | Needs `layers`. Also write the prefab that plays the layers together: the path of a .prefab.json ("prefabs/coin_sparkle.prefab.json"), or an object {path, name, tags, size, layers, pixelArt, overwrite}. It is a parent entity (name: `name`, default made from the file name; `tags`) with one child per layer (Back, Front, Light), each a Sprite on that layer's sheet (`size` [w, h] in world units, default one frame in pixels; `layers` {back, front, light} are the Sprite.layer numbers, default -1, 1 and 2, so put the character's layer between back and front; `pixelArt` default false) with a SpriteAnimator on the sheet's first clip; the light child is blend additive. The prefab is written after the sheets. An existing prefab is never replaced unless the object has overwrite: true (the call fails before baking anything): it may hold changes made by hand, and the command's `overwrite` is about the sheets. The prefab is not part of the recipe: assets.regenerate remakes the sheets and leaves the prefab as it is. |
| `style` | string ["none","watercolor","ink","inkwash","paper"] | no | Default none. The painterly look of assets.rasterize_svg applied to every frame (watercolor, ink, inkwash, paper). The same seed for all frames, so the texture does not boil. |
| `styleStrength` | number | no | How strong the `style` is, 0 to 1 (default 1). Ignored without a `style`. |
| `padding` | integer | no | Transparent pixels around every cell: 1 or 2 keeps filtered frames from bleeding into each other. Recorded in the sheet entry. Default 0. |
| `timeLimitMs` | integer | no | Milliseconds the module may take to load and, separately, to draw each frame; over it the call fails naming the frame. Default 2000. |
| `overwrite` | boolean | no | Replace the sheet (every layer's sheet) when it already exists. It does not cover the prefab: see `prefab`. Default false. |
| `ai` | boolean | no | Whether the code was written by an AI (the default, since the caller is an agent). Set false for art a person made; it then counts as original work in the AI disclosure. Default true. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the sheet for the provenance record. Default "CC0-1.0". |

## `assets.bake_sheet` (modifies state)

Since 0.6.0.

Bake an entity the engine draws (a prefab, or an entity of a scene) into a sprite sheet: Shape2D, tweens, particles and scripts play and are captured frame by frame.

Capabilities: read, writeProject

Plays a prefab (`prefab`) or an entity of a scene with its children (`scene` + `entity`) alone in a private world and captures it into a PNG sprite sheet at `path` (under assets/, ending in .png), with its `sheet` entry, provenance and recipe in assets.json. Use it to turn something that costs many draw calls on a phone (a glow made of shapes, a particle burst, a tweened badge, a scripted explosion) into ONE sprite, to make an effect once and play it as a SpriteAnimator, or to draw animated art with the engine's own Shape2D (gradients, strokes) instead of SVG. The world is simulated at the project's fixed step with the world RNG seeded from `seed`, so the same prefab, seed and settings bake the same pixels on the same GPU (the pixels of two different GPUs can differ by an edge pixel); a frame is captured every 1/`fps` seconds of simulated time, `frames` frames per clip. Example: {"path":"assets/fx/burst.png","prefab":"prefabs/burst.prefab.json","frames":16,"fps":24,"warmup":0.5,"pivot":[0.5,0.5]}

SpriteAnimator, Tint, tweens, ParticleEmitter, Shape2D, Sprite and the entity's scripts all run as in the game; nothing else is in the world (no other entities and no lights: a `lit` sprite is drawn as in a world without lights). The entity is placed at the origin of the world, even when the scene puts it elsewhere. Frame 0 is drawn after one step (the entity's start() has run) and after `warmup` seconds. `clips` bakes several named clips from one entity, each in a fresh world: `[{"name":"explode","call":"explode","frames":24,"loop":false}, {"name":"idle","frames":8}]`; `call` runs that method of the entity's behaviour right after the warm-up (`args` are its arguments), `event` sends a game event instead (`data`); a clip with `clip` plays that clip of the entity's Animator (a key of Animator.clips, a `.anim.json` clip or a glTF animation) from time 0 with no cross-fade, switching the state machine off, and takes `frames` from the clip's duration times `fps` and `loop` from the clip when they are not given; a clip with none of them just plays. They follow each other in the sheet and become clips of its `sheet` entry (firstFrame, lastFrame, fps, loop). Framing: the pixels are drawn at `scale` pixels per world unit and cropped to everything drawn in ANY frame plus `margin`, so nothing is cut (a particle burst that grows is included) and the entity's origin is the same pixel in every frame: it is the `pivot` recorded in the sheet entry ([x, y] in 0..1 from the top-left of the frame). Give `pivot` to choose where the origin lands (a character's feet: [0.5, 1]); give `frameWidth` and `frameHeight` for a fixed cell: without `scale` the animation is scaled to fit it, with `scale` it must fit or the command fails and says how large the cell must be. The colours are straight alpha with the colour of the edge pixels bled outwards, so a sprite scaled with filtering has no dark halo; additive glows keep their light (their alpha is the brightest channel). `background` puts a colour behind the frames (default transparent). `padding` leaves transparent pixels around each cell (default 1; the sheet entry records it). Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL). A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the bake runs in a child `factoria call` process; from a terminal `factoria call assets.bake_sheet` works as is. A script that throws, a `call` that is not a method of the behaviour (with its methods and a suggestion) or a prefab that does not load fail with an error that names the prefab and the script. Provenance: origin generated, `ai` is true when the prefab, the scene or a texture it draws is recorded in assets.json as AI-made (pass `ai` to override, with `author` and `license`); the recipe holds the arguments and the SHA-256 of the prefab or scene, its scripts and textures, so assets.regenerate can make the sheet again and validate can tell when it is stale.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the PNG sheet, project-relative, under assets/ and ending in .png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `prefab` | string | no | The prefab to bake, project-relative ("prefabs/burst.prefab.json"). Give this, or `scene` + `entity`. Path the command reads. |
| `scene` | string | no | A scene file that holds the entity to bake. Needs `entity`. Path the command reads. |
| `entity` | string | no | The id of the entity of `scene` to bake, with its children. |
| `frames` | integer | no | Frames per clip (all of them without `clips`). Default 12. |
| `fps` | number | no | Frames per second of simulated time (at most the project's fixed rate, 60 by default): a frame is captured every 1/fps seconds. Also the sheet's clip speed. Default 12. |
| `columns` | integer | no | Columns of the grid; 0 or absent = square-ish. |
| `frameWidth` | integer | no | Pixels of a cell. Absent = as wide as the animation needs. |
| `frameHeight` | integer | no | Pixels of a cell. Absent = as tall as the animation needs. |
| `scale` | number | no | Pixels per world unit (1 = the size the entity has in the world, 2 = twice as big). Absent: 1, or the scale that fits frameWidth x frameHeight when both are given. |
| `pivot` | array | no | [x, y] in 0..1 from the top-left of the frame: where the entity's origin lands in every frame ([0.5, 1] = middle of the bottom edge). Absent: where the animation puts it (the cell is the tight box of everything drawn). |
| `clips` | array | no | Named clips, each in a fresh world: {name, clip?, call?, args?, event?, data?, frames?, fps?, loop?, warmup?}. `clip` is a clip of the entity's Animator, played from time 0 (frames default to its duration x fps, loop to the clip's); `call` is a method of the entity's behaviour, `event` a game event (world.on); `clip`, `call` and `event` are alternatives, and `call` and `event` start the clip after the warm-up. They follow each other in the sheet. |
| `warmup` | number | no | Seconds of simulated time to play before the first frame (a particle system that should start full). A clip can set its own. Default 0. |
| `seed` | integer | no | Seeds the world RNG (scripts' rng, random particles): the same seed gives the same sheet. Default 1. |
| `background` | any | no | A colour behind the frames ("#rrggbb", "#rrggbbaa", a name or [r, g, b]). Default: transparent. |
| `padding` | integer | no | Transparent pixels around every cell (twice between two cells), recorded in the sheet entry. Default 1. |
| `margin` | integer | no | Empty pixels kept around the animation's outline. Default 2. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |
| `ai` | boolean | no | Override the AI disclosure. Default: true when the prefab/scene or a texture it draws is recorded as AI-made in assets.json. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the sheet for the provenance record. Default "CC0-1.0". |

## `assets.check_art` (modifies state)

Since 0.16.0.

Check pictures against the house style and how they read in the game: palette fit, contrast over the real backgrounds, readability at phone and desktop size, halos on alpha edges, and set consistency; returns an annotated picture.

Capabilities: read, state

Measures one picture (`path`) or a set (`paths`, up to 12) and returns an annotated picture plus rules, each with `value`, `threshold`, `verdict` (ok, warn or fail) and, unless ok, a `hint` naming the command or setting that fixes it. Palette fit: the colour count, and when assets.json style.palette is set the distance of the colours to it and the share of pixels off the palette (strict with style.pixelArt). Contrast: the WCAG contrast ratio between the silhouette edge and each background the picture is drawn over: `backgrounds` (colours "#rrggbb" or project image paths) when given, else the clear colour and the large background sprites of the scenes that use the picture, else a light and a dark default; the result says which (`backgrounds.source`). Example: {"path":"assets/hero.png","backgrounds":["#203040"],"onScreenPx":48}.

Readability: the picture shrunk to the size it has on screen (`onScreenPx`, the longer side in screen pixels, when given; else derived from the scenes' Sprite size, scale and camera at a phone, 844x390, and a desktop, 1920x1080, screen): its size, how much of the silhouette survives and whether the outline is still a line. Halos and fringes: partly transparent edge pixels that are darker or lighter than the pixels they touch, and transparent pixels next to the shape that hold a foreign colour. Style rules set in assets.json style (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation) are judged too, with the same numbers as the `project.validate` warnings; rules the style does not set are not judged, and `style: false` skips them. With several paths it also compares the set: pixel density, pixel size, outline colour and thickness, and how many colours the pictures share. The picture has one row per asset: the picture itself, its value (greyscale), over each background and at each on-screen size. It is a temporary screenshot in .factoria/screenshots; measuring is cached in .factoria/art-cache. Thresholds and the rules are listed in docs/ASSETS.md ("Checking art: assets.check_art").

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the picture to check. Give this or `paths`. Path the command reads. |
| `paths` | array | no | Several pictures to check one by one and as a set (pixel density, outline, palette spread). Give this or `path`. |
| `backgrounds` | array | no | What the picture is drawn over. Default: the camera clear colour and background sprites of the scenes that use it, else a light and a dark default. |
| `onScreenPx` | any | no | The longer side of the sprite on screen, in screen pixels: a number, or a list of up to 4. Default: derived from the scenes (Sprite size, scale, camera) at a phone and a desktop screen. |
| `style` | boolean | no | Judge the rules set in assets.json style (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation, palette). False skips them. Default true. |

## `assets.check_mix` (modifies state)

Since 0.16.0.

Measure every sound of the project together: loudness per bus, music masking effects, clicks, loop seams, clipping, true peak; each finding has a fix.

Capabilities: read, state

Listens for what a game's mix gets wrong. Measures the sounds of the project (the set assets.analyze_audio uses without `path`: everything under assets/ and every sound a scene or prefab names), or `paths`, as they play (with the gain import "normalize" applies). Each finding has `sound`, `rule`, `value`, `threshold`, `unit`, `verdict` (ok, warn, fail), a `message` and a `hint` that names the fix; ok findings are left out unless `includeOk` is true. Example: {"targets":{"music":-16,"sfx":-14}}

Rules: loudness_target / loudness_spread (loudness of each sound against the target of its bus, or, with no target, against the median of the sounds of its bus: warn beyond 6 LU, fail beyond 12; the bus comes from AudioSource (sfx), SceneSettings.music and audio.music (music) and audio.play("path", {bus}) in scripts, with the parents of factoria.json audio.buses; a sound no scene or script plays with a literal path is on the "unknown bus"); music_masking (the octave bands where an effect has its main energy, against the loudest music there: warn when the music is as loud or louder, fail 6 dB louder); click_start and click_end (the first/last sample or a jump of the first/last step: warn above -40 dBFS, fail above -26); loop_seam_jump and loop_seam_slope (for sounds played looping: the step and the change of slope from the last sample to the first, as multiples of the sound's usual step and curvature; a .wav with loop points, as an audio document's `loop` step writes it, is judged across the join it plays, the crossfade, not across the file's ends); clipping (samples flattened at full scale, counted); true_peak (4x oversampled, as played: warn above -1 dBTP, fail above 0). Loudness targets: the `targets` argument ({"music": -16, "sfx": {"lufs": -14, "toleranceLu": 2}, "default": -16}), else style.audio.loudnessLufs and toleranceLu in assets.json, else the spread rule. A sound that is only an input of an audio document's recipe (a recording the document is baked from) and that no scene or script plays is not judged: it is listed in `skipped` with the reason, unless `paths` names it. Returns {verdict, summary, findings, sounds (one row of numbers per sound), skipped, targets, nextSteps}. Deterministic and read-only: it writes nothing (run assets.analyze_audio first to keep the loudness records, so later runs do not measure again).

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | no | Project-relative sound files to check. Omit for every sound of the project. |
| `targets` | object | no | Loudness targets in LUFS per bus: {"music": -16, "sfx": {"lufs": -14, "toleranceLu": 2}, "default": -16}. A number uses a tolerance of 3 LU. Omit to use style.audio in assets.json. |
| `includeOk` | boolean | no | Also list the checks that passed. Default false. |

## `assets.contact_sheet` (modifies state)

Since 0.16.0.

Look at a set of images (or .glb models) side by side at their on-screen size, over light, dark and camera-colour backgrounds and in greyscale, labelled with their file names.

Capabilities: read, state

Draws one picture (returned to you as an image) with a column for each picture of `paths` (and for each of `sizes`) and a row for each background, so you can judge a set of assets the way the player meets them: small, on the real ground, in black and white. `backgrounds` default to a light colour, a dark colour and the clear colour of the first primary camera of the project's main scene (when it has one); the last row is the same pictures in greyscale over mid-grey (`greyscale: false` leaves it out). `sizes` are pixels of the longest side of each picture as the player sees it (Sprite.size on screen times the render scale): [32, 64] draws every picture twice, shrunk with averaging or grown with hard pixels; without `sizes` each picture is drawn at its native size (at most 512). PNG, JPG, BMP and TGA files are drawn as they are; a sprite sheet (one with a `sheet` entry in assets.json) shows its first frame, or all frames with `allFrames: true`. Example: {"paths":["assets/hero.png","assets/slime.png"],"sizes":[32,64]}.

A .glb model is drawn as a thumbnail by the engine's renderer (a studio light, turned three quarters, transparent around it), which needs a graphics device (Metal, Direct3D 11 or OpenGL; without one the command fails with no_gpu, and you can leave the models out); a model in the real scene, with its lighting, is assets.preview_in_scene. Each column is labelled with the file name and its size in the font that comes with the engine. A line holds `columns` cells (default 8), then the sheet continues below. No project file is written unless `path` is given (the picture is otherwise a temporary screenshot in .factoria/screenshots): then the PNG is also saved there, which needs the writeProject capability (an existing file is not replaced without `overwrite: true`). The same inputs give the same picture.

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Project-relative paths of the pictures (PNG, JPG, BMP, TGA) and .glb models to show, in this order. A sprite sheet shows its first frame (see allFrames). |
| `backgrounds` | array | no | Colours ("#rrggbb", a name, or [r, g, b] in 0..1) to draw the pictures over, one row each. Default: a light one, a dark one and the clear colour of the main camera. |
| `sizes` | array | no | Longest side in pixels of each picture as the player sees it; one column per picture and size. Default: the native size of each picture. |
| `greyscale` | boolean | no | Add a last row with the pictures in greyscale over mid-grey, to judge their value structure. Default true. |
| `columns` | integer | no | Cells per line; more wrap to a new block of rows below. Default 8. |
| `allFrames` | boolean | no | A sprite sheet shows all its frames (a column each) instead of the first. Default false. |
| `path` | string | no | Also save the picture as a PNG at this path (ending in .png; project-relative, an absolute path only for the command-line user). Needs the writeProject capability. Without it only a temporary screenshot in .factoria/screenshots is made. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | With `path`: replace the file when it exists. Default false. |

## `assets.convert_audio` (modifies state)

Since 0.3.0.

Convert a WAV in the project to Ogg Vorbis (smaller, streams well) and record where it came from.

Capabilities: read, writeProject

Reads the WAV at `path` (8, 16, 24 or 32-bit PCM or float, mono or stereo) and writes an Ogg Vorbis file at `to` (default: the same name ending in .ogg), with the encoder of this engine (fixed block size, no stereo coupling: about 4 to 6 times smaller than 16-bit WAV at the default quality, less than libvorbis would reach). The sample rate and length are kept. The WAV stays; the provenance of the WAV is copied to the Ogg with a note. Use it for music and long ambience (a streamed .ogg keeps little in memory, docs/ASSETS.md); keep short effects as WAV. Example: {"path":"assets/audio/wind.wav","quality":0.6}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The WAV to convert, project-relative, under assets/. Path the command reads. |
| `to` | string | no | Where to write the Ogg, under assets/ and ending in .ogg. Default: next to the WAV, same name. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `quality` | number | no | 0 to 1. Higher is bigger and closer to the WAV; 0.6 suits ambience, 0.8 music. Default 0.6. |
| `overwrite` | boolean | no | Replace the Ogg when it already exists. Default false. |

## `assets.disclosure`

Since 0.1.6.

Write the AI-generated content disclosure for store forms (Steam) from the provenance records.

Capabilities: read

Returns Markdown that answers the AI-generated content questions of Steam's content survey and similar forms: what was pre-generated with AI by category (art, sound effects, music, voice, 3D models) with counts, providers and models; that nothing is generated while the game runs; the terms recorded for each provider; and the art, sound and model files that still have no provenance record (fix those with assets.set_provenance first). `factoria export` writes the same text as AI_CONTENT_DISCLOSURE.md. Example: {}

## `assets.draw_capsules` (modifies state)

Since 0.2.0.

Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo.

Capabilities: read, writeProject

Cover-crops `keyArt` (an image in the project, e.g. a screenshot taken with game.screenshot {scale}) around `focus` to every image size the `stores` ask for and writes store/capsules/<store>/<name>_<w>x<h>.png (folders are created, files replaced). Stores: steam, epic, gog, microsoft, googleplay, appstore, itch (default: all). The sizes are in one table (docs/EXPORTING.md#store-page-material, as of 2026-10); assets with the same size in one store are one file.
The `logo` is placed by the rule of each asset: capsules and covers get it centred (Microsoft: in the upper part, the bottom third is overlaid; Steam library capsule: low), heroes, page backgrounds and screenshots get none (Steam's library hero must have no text), and the logo-only assets (Steam library logo 1280x720, Epic logo 960x540) are a transparent PNG with just the logo. `logo` is {"image": "assets/logo.png"} (transparent PNG) or {"text": "My Game", font, fill, outline} (title drawn like assets.draw_icon draws text; fill default white, outline default a dark one, false = none).

Example: {"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}.

Without a logo the art is cut without one and the logo-only assets are skipped.
`safeArea` is the margin the logo keeps from the edges, as fractions of the image (default 0.05 on every side, and the bottom third on the Microsoft poster and box art, which the store overlays with text): a number, {left, top, right, bottom}, or {default, steam, ...} per store. The logo is cut to fit inside it and never leaves it. `logoAnchor` puts the logo somewhere else than the asset's rule does: center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight, or a point [x, y] of the safe area ([0, 0] its top-left corner, [1, 1] the bottom-right one). When the art already has the capsule's proportions (within 1%) the crop has nothing to choose, so a given `focus` moves the logo instead, by its distance from [0.5, 0.5] (0.2 of the width left of the middle moves it 0.3 of the width left), still inside the safe area.
`orientation` (landscape, default; or portrait) turns the phone and tablet screenshot sizes of Google Play and the App Store. Capsules are not the store screenshots: take those at the stores' sizes with `--render-scale` (a 1280x720 game at 1.5 gives 1920x1080).

| Argument | Type | Required | Description |
|---|---|---|---|
| `keyArt` | string | yes | The art to cut the capsules from: a project image path, 1920x1080 or bigger is best (a screenshot taken with --render-scale). Path the command reads. |
| `focus` | array | no | The point of the art that must stay in view when it is cropped, as fractions [x, y]. Default [0.5, 0.5]. |
| `logo` | object | no | The logo: give image or text. |
| `logoAnchor` | any | no | Where the logo sits in the safe area instead of the asset's own rule: a name or a point [x, y] (0..1; [0, 0] touches the top-left corner of the safe area). |
| `safeArea` | any | no | Margins the logo stays inside, as fractions of the image (0..0.45): a number for all sides, {left, top, right, bottom}, or per store {default, steam, epic, ...} each of those. Default 0.05, and the bottom third of the Microsoft poster and box art. |
| `stores` | array | no | Which stores. Default all. |
| `name` | string | no | File name prefix. Default: the project name. |
| `orientation` | string ["landscape","portrait"] | no | Phone and tablet screenshot sizes of Google Play and the App Store. Default landscape. |
| `overwrite` | boolean | no | Replace files that already exist. Default true. |

## `assets.draw_icon` (modifies state)

Since 0.2.0.

Draw the game's icon (1024x1024 PNG) and the Android adaptive-icon foreground from shapes and text, no image provider needed.

Capabilities: read, writeProject

Draws on the CPU (anti-aliased, identical everywhere, works headless): a background plus layers drawn in order. Writes the 1024x1024 icon at `path` (default: factoria.json `icon`, else assets/icon.png) and the Android adaptive-icon foreground (432x432, transparent; the 0..100 drawing box is scaled into the 66/108 safe zone, so nothing inside it is cropped) at `foreground` (default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png; false = skip). An icon or foreground path factoria.json does not name yet is added to it. Files are replaced; assets.json gets provenance origin "original", ai false.
Drawing space: x and y run 0..100 across the icon, origin top-left, y down; sizes and radii are in the same units (shapes may reach outside 0..100: the icon crops them).

Example: {"background":{"color":"#141428","shape":"rounded"},"layers":[{"type":"circle","x":50,"y":50,"radius":28,"fill":"#ffcc44","outline":"#ffffff"},{"type":"text","text":"K","x":50,"y":50,"size":34,"fill":"#141428"}]}.

Layer types: rect {x,y,w,h} (x,y = top-left), roundRect {x,y,w,h,radius}, circle {x,y,radius} (x,y = centre), ellipse {x,y,rx,ry}, polygon {points:[[x,y],...]} and text {text,x,y,size,font}: x,y = centre of the text, size = em height, font = a project .ttf (default DejaVu Sans), one line, no shaping. Shapes take fill and/or outline (colours "#rrggbb"[aa] or names), fillBottom (vertical gradient from fill at the top of the icon to fillBottom at its bottom), outlineWidth (default 2), softness (feathers the edge: glows). Text takes fill. foreground: false on a layer keeps it out of the Android foreground (backdrops such as a ground or arch; the adaptive icon has its own background colour). Unknown keys and types are errors with suggestions.

| Argument | Type | Required | Description |
|---|---|---|---|
| `background` | object | yes | The icon's backdrop. |
| `layers` | array | yes | Drawn in order, later on top. Each has a `type` (rect, roundRect, circle, ellipse, polygon, text) and the fields listed in the command description. |
| `path` | string | no | PNG to write the icon to. Default: factoria.json `icon`, else assets/icon.png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `foreground` | any | no | PNG for the Android adaptive-icon foreground, or false to skip it. Default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |

## `assets.generate_image` (modifies state)

Since 0.1.6.

Generate a PNG image with the image asset provider and record where it came from.

Capabilities: read, writeProject, network, process, spend

Calls the provider that ai.json assigns to "image" (assets.image; there is no default, so add one, or pass `provider` such as "fake" for an offline placeholder), writes a PNG of exactly width x height at `path` and records provenance (origin generated, ai true, provider, model, the full prompt, references, date, license note) in assets.json. The house style of assets.json is applied unless style is false: its `prompt` is appended to yours, its `references` are sent along with `references`, and its `palette` reduces the result to those colours. Returns the path, size, provenance and the image itself. Generation costs money with paid providers: check the first result before generating more. With `count` 2 to 4 it makes candidates and ONE review sheet: show it, ask for one number, call assets.pick; never pick for the person. COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

With `count` 2 to 4 it makes that many candidates for the slot `path` instead (files next to it named <name>.candidate-<n>.png, each with its own seed and provenance; the cost estimate and the approval cover all of them at once) and ONE review sheet that shows them numbered: show that sheet to the person, ask for one number and call assets.pick {slot, n}. Never pick for them. Example: {"prompt":"a red potion bottle, side view","path":"assets/items/potion.png","width":64,"height":64,"transparent":true} COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | What to draw. Describe the subject and the view; the house style is added for you. |
| `width` | integer | no | Width of the PNG in pixels. The provider's picture is resized to it. Default 512. |
| `height` | integer | no | Height of the PNG in pixels. Default 512. |
| `transparent` | boolean | no | Ask for a transparent background (sprites, items, icons). Default false. |
| `count` | integer | no | How many candidates to make for the slot `path` (1 to 4). 1 writes `path` itself. 2 to 4 write <name>.candidate-1.png... next to it (seeds seed, seed+1...; without `seed` they come from the prompt) and one review sheet; the person picks one with assets.pick, which moves it to `path`. With overwrite false, existing candidate files are refused; with overwrite true they are replaced, and the slot's earlier sheet can no longer be answered (assets.pick answers the newest). Default 1. |
| `references` | array | no | Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call. Default true. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_loop` (modifies state)

Since 0.3.0.

Make a seamless loop offline (a wind or fire bed, a clock, a drone or chord pad) as a WAV or Ogg: no provider, no key.

Capabilities: read, writeProject

Synthesizes a mono loop at `path` (under assets/, .wav or .ogg) from `kind`, with no AI provider and no key. The same arguments and `seed` always give the same bytes. The end of the loop meets its start: filters run round the loop, gusts and hums have a whole number of cycles, and pops, ticks and notes wrap round the end. Records provenance in assets.json (origin original, ai false, license CC0).
kind "noise": a bed of `color` noise (white = hiss, pink = rain, brown = rumble and wind) low-passed at `cutoff` Hz and scaled by `level`; `gusts` (0 to 1) swells it slowly; `crackles` adds random pops per second (a fire); `tick` adds a tick-tock every that many seconds (a clock; make `seconds` a multiple of it and `level` 0 for the ticks alone); `hum` adds sines at those Hz (a cellar's mains hum).
kind "drone": `chords`, an array of chords of notes ("A3", "F#2", "Eb4", or Hz); each chord is a soft pad lasting `chordSeconds`, with the first note an octave down at `bass` level. A single chord is a drone. `arpeggio` {every, pattern, gain} plays music-box plucks over it: `pattern` holds chord indexes (null = a rest, past the chord's end = an octave up).

Wind: {"kind":"noise","color":"brown","cutoff":900,"gusts":0.6,"seconds":20}. Fire: {"kind":"noise","color":"brown","cutoff":600,"crackles":4}. Clock: {"kind":"noise","level":0,"tick":1,"seconds":4}. Score: {"kind":"drone","chords":[["D3","F3","A3"],["Bb2","D3","F3"]],"chordSeconds":6,"arpeggio":{"every":0.75,"pattern":[0,2,1,2],"gain":0.16}}. A WAV loops sample for sample; an Ogg loop is smaller and within the codec's noise at the seam (see assets.convert_audio).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the loop, project-relative, under assets/ and ending in .wav or .ogg, e.g. "assets/audio/wind.wav". Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `kind` | string ["noise","drone"] | yes | noise: a bed (wind, fire, rain, a clock). drone: pads and chords (music, a mood). |
| `seconds` | number | no | Length of the loop (default 12). For a drone with chordSeconds, leave it out to get chords x chordSeconds. |
| `sampleRate` | integer | no | Sample rate in Hz. 22050 is plenty for ambience; the engine resamples. Default 22050. |
| `seed` | integer | no | Chooses the take: the same arguments and seed give the same file. Default 0. |
| `peak` | number | no | Loudest sample as a fraction of full scale. Default 0.6 (-4.4 dBFS). Default 0.6. |
| `quality` | number | no | Ogg only: quality of the encoding (more quality, bigger file). Default 0.6. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |
| `color` | string ["white","pink","brown"] | no | (Default brown.) noise: the colour of the noise. |
| `cutoff` | number | no | (Default 0.) noise: low-pass in Hz; 0 leaves the noise as it is. Lower is darker (wind 500-1500, fire 400-800). |
| `level` | number | no | (Default 1.) noise: volume of the bed relative to the pops, ticks and hum; 0 makes them the only sound. |
| `gusts` | number | no | (Default 0.) noise: depth of slow swells of the bed (0 steady, 1 deep gusts). |
| `crackles` | number | no | (Default 0.) noise: random pops per second (a fire: 3-6). |
| `tick` | number | no | (Default 0.) noise: seconds between the ticks of a clock (alternating tick and tock); 0 for none. |
| `hum` | array | no | noise: frequencies in Hz (or note names) of steady hum tones added to the bed. |
| `chords` | array | no | drone: chords, each an array of note names ("A3", "F#2") or Hz. The first note of a chord is also played an octave down. |
| `chordSeconds` | number | no | drone: seconds each chord lasts. Default: seconds divided by the number of chords. |
| `bass` | number | no | (Default 0.5.) drone: level of the low note under each chord. |
| `brightness` | number | no | (Default 0.3.) drone: level of the octave partial above each note (0 dull, 1 bright). |
| `underNote` | any | no | drone: one soft note held under the whole loop, whatever the chords do: a name such as "D1" or a frequency in Hz. |
| `underLevel` | number | no | (Default 0.5.) drone: level of `underNote`. |
| `arpeggio` | object | no | drone: music-box plucks over the chords. |

## `assets.generate_model` (modifies state)

Since 0.1.6.

Generate a 3D model with the model3d asset provider and record where it came from.

Capabilities: read, writeProject, network, process, spend

Calls the provider that ai.json assigns to "model3d" (assets.model3d) and writes the glTF binary at `path` (.glb; the fake provider makes a small .gltf cube). Generating models takes minutes with real providers. The model is not textured or rigged; check it in the scene before building on it. Records provenance in assets.json. Example: {"prompt":"a low-poly wooden crate","path":"assets/models/crate.glb"} COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The object to make: shape, material, style. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_music` (modifies state)

Since 0.1.6.

Generate a music track with the music asset provider and record where it came from.

Capabilities: read, writeProject, network, process, spend

Calls the provider that ai.json assigns to "music" (assets.music) and writes the audio file at `path` (extension as for assets.generate_sound). Tracks are instrumental. Records provenance in assets.json. Tracks are not looped for you: ask for a loopable piece in the prompt and set `loop` on the AudioSource. Example: {"prompt":"calm forest theme, soft flute and strings","path":"assets/music/forest.mp3","seconds":60} COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The music to make: mood, instruments, tempo. |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_sound` (modifies state)

Since 0.1.6.

Generate a sound effect with the sound asset provider and record where it came from.

Capabilities: read, writeProject, network, process, spend

Calls the provider that ai.json assigns to "sound" (assets.sound) and writes the audio file at `path`, whose extension must be the one the provider makes (.mp3 for elevenlabs, .wav for fake and asset-command). Records provenance in assets.json. Example: {"prompt":"short coin pickup chime","path":"assets/sfx/coin.mp3","seconds":1} COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The sound to make, for example "heavy wooden door slam". |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_sprite_sheet` (modifies state)

Since 0.1.6.

Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator.

Capabilities: read, writeProject, network, process, spend

Like assets.generate_image, but the picture is a grid of `frames` animation frames of frameWidth x frameHeight, normalized to exactly columns * frameWidth by rows * frameHeight pixels (each side at most 4096). The layout is written to assets.json as the `sheet` of the file with one clip "default" (all frames, at `fps`), and the result shows the Sprite and SpriteAnimator components to use. Providers draw grids unevenly: look at the result and regenerate when frames wander. Example: {"prompt":"a knight walking right","path":"assets/knight_walk.png","frames":6,"columns":3,"frameWidth":64,"frameHeight":64,"fps":10} COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | What the animation shows: the subject and what it does over the frames. |
| `frames` | integer | yes | Number of animation frames. |
| `columns` | integer | no | Frames per row. Default: the square root of frames, rounded up. |
| `frameWidth` | integer | yes | Width of one frame in pixels. |
| `frameHeight` | integer | yes | Height of one frame in pixels. |
| `fps` | number | no | Frames per second of the "default" clip. Default 8. |
| `transparent` | boolean | no | Ask for a transparent background (the usual choice for sprites). Default true. |
| `references` | array | no | Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call. Default true. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_texture` (modifies state)

Since 0.4.0.

Make a material texture (paper, parchment, wood, planks, leather, fabric, stone, noise, gradient, vignette) offline: a seeded PNG, no provider and no key.

Capabilities: read, writeProject

Paints a procedural texture at `path` (under assets/, ending in .png) with no AI provider and no key: free, offline and seeded (the same arguments give the same picture with the same build of factoria; another `seed` is another take of the material). Use it for backgrounds, desks, book covers and pages, floors, walls and surfaces when no image provider is configured (assets.generate_image would fail with no_provider), or when you want a flat material you can tune: `color` and `accent` recolour it, `scale` makes the features bigger or smaller, `roughness` goes from smooth and even (0) to worn and uneven (1), `tileable` makes the picture repeat with no seam, `normalMap` also writes a tangent-space normal map next to it (`<name>_n.png`, +Y up) for lit sprites and 3D materials. Textures are lit from the upper left, so grooves and bumps read. It makes surfaces, not drawings: for a picture of a subject (a portrait, an icon, an ornament) write an SVG and call assets.rasterize_svg. Records provenance in assets.json (origin original, ai false, license CC0, the arguments in the notes). Look at the picture in the result and adjust. Presets:


- paper: cream paper: fibres, mottling and a fine tooth (default colours #efe6d2 paper, #bba67f shadow tone).
- parchment: old parchment: warm stains, creases and (when not tileable) darkened edges (default colours #e1c98f skin, #8b5a2b stain).
- wood: wood grain: growth rings, streaks and pores along the width (default colours #b07a45 light wood, #4f2f17 late wood).
- planks: wooden planks (a floor or a desk top) with joints, gaps and a different grain in every board (default colours #a9743f wood, #3d2412 gaps and grain).
- leather: pebbled leather with creases, wear and a soft sheen (default colours #7a4a2a leather, #2a150a creases).
- fabric: woven cloth (plain weave): threads that go over and under, slubs and uneven tone (default colours #c4b490 thread, #6b5c3e shadows).
- linen: linen or bookcloth: a fine, even, low-contrast weave (finer and quieter than fabric) (default colours #d9cfb6 thread, #a99d82 shadows).
- stone: flagstone: blocks with joints, grain, cracks and speckles (default colours #9a968e stone, #4a4640 joints and cracks).
- value: value noise (smooth blobs) from `color` to `accent` (default colours #202020 to #f2f2f2).
- fbm: fractal noise (clouds; `roughness` adds octaves) from `color` to `accent` (default colours #202020 to #f2f2f2).
- cellular: cellular (Worley) noise: distance to the nearest point, from `color` (at a point) to `accent` (default colours #202020 to #f2f2f2).
- gradient: a linear gradient from `color` to `accent` along `angle` (the alphas of the colours are blended too) (default colours #f4ead5 to #8c6a42).
- radial: a radial gradient: `color` in the middle to `accent` at the corners (`scale` is the radius, 1 = the corners) (default colours #f4ead5 to #5a3d22).
- vignette: a transparent middle fading to `color` at the edges (an overlay for a scene: put it over a Sprite); `vignette` is its strongest alpha (default colours #000000).
Examples: {"path":"assets/textures/desk.png","preset":"planks","width":1280,"height":720,"seed":4} / {"path":"assets/textures/long_planks.png","preset":"planks","plankCount":7,"plankLength":0,"gapWidth":0.01} / {"path":"assets/textures/cover.png","preset":"leather","color":"#5b2a1a","accent":"#1d0d07","normalMap":true} / {"path":"assets/textures/page.png","preset":"parchment","width":640,"height":900,"vignette":0.6} / {"path":"assets/textures/floor.png","preset":"stone","tileable":true,"scale":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the PNG, project-relative, under assets/ and ending in .png, e.g. "assets/textures/paper.png". Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `preset` | string ["paper","parchment","wood","planks","leather","fabric","linen","stone","value","fbm","cellular","gradient","radial","vignette"] | yes | The material or pattern. See the list in the command description. |
| `width` | integer | no | Width in pixels (up to 2048; tile it for larger areas). Default 512. |
| `height` | integer | no | Height in pixels. Default: the width (512 when neither is given). |
| `seed` | integer | no | Chooses the take: the same arguments always give the same file; change it for another sample of the material. Default 0. |
| `color` | any | no | The main colour: "#rrggbb", "#rrggbbaa", a name like "white" or [r, g, b] in 0..1. Default: the preset's own (see the preset list). For vignette, the colour of the shade; for gradient, the start. |
| `accent` | any | no | The second colour (shadow, late wood, creases, joints, the far end of a gradient). Same formats as `color`. Default: the preset's own. |
| `scale` | number | no | Size of the features: 1 is the preset's natural size relative to the picture, 2 makes them twice as big, 0.5 half as big (more planks, finer weave, smaller pebbles). For radial and vignette it is the radius (1 reaches the corners); for gradient it stretches the ramp. Default 1. |
| `roughness` | number | no | 0 is smooth and even, 1 is worn and uneven (more stains, deeper creases, a rougher weave). For vignette: the softness of the edge; for cellular: how irregular the cells are. Default 0.5. |
| `tileable` | boolean | no | Make the picture repeat with no seam at its edges. The material presets and the noises can; gradient, radial and vignette have an edge by nature and ignore it (with a warning). Default false. |
| `vignette` | number | no | Darkens the edge with a narrow, irregular worn border (a thumbed page, a burnt corner) on any preset except gradient and radial; ignored when tileable. How strong: 0.5 for parchment by default, 0 for the others. How wide: `vignetteWidth`. For the vignette preset it is the alpha at the edge (default 0.85). |
| `vignetteWidth` | number | no | How wide the darkened edge is (see `vignette`), as a fraction of the picture's short side. Default 0.035: a narrow band whose inner edge is ragged, like wear. 0.1 is a visible frame; 0.17 gives the wide uniform frame that earlier versions drew. Ignored when no edge is darkened. |
| `angle` | number | no | gradient only: direction in degrees. 0 runs from the top to the bottom, 90 from the left to the right. Default 0. |
| `normalMap` | boolean | no | Also write the tangent-space normal map of the same relief as <path without .png>_n.png (+X right, +Y up the picture, the convention of Sprite.normalMap and glTF), with its own provenance record. Default false. |
| `normalStrength` | number | no | How deep the relief of the normal map is: 1 subtle, 3 clear, 10 deep. Default 3. |
| `plankCount` | integer | no | planks only: how many boards are stacked from the top to the bottom of the picture (each runs from left to right). Default: follows `scale` (6 at scale 1). |
| `plankLength` | number | no | planks only (default 1): the length of a board as a fraction of the picture's width. 0 makes every board run from side to side with no butt joint (a desk top); 1 (the default) gives each row one joint, 0.5 two boards per row, 0.25 four. Joints are staggered row by row. |
| `gapWidth` | number | no | planks only (default 0.015): the gap between boards as a fraction of a board's width (at least one pixel). 0.015 is a fine seam, 0.05 a wide gap. |
| `gapDarkness` | number | no | planks only (default 0.55): how dark the gaps are. 0 leaves them the colour of the wood (only the bevel shows), 1 makes them nearly as dark as `accent` allows. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_voice` (modifies state)

Since 0.1.6.

Generate spoken audio from text with the voice asset provider and record where it came from.

Capabilities: read, writeProject, network, process, spend

Calls the provider that ai.json assigns to "voice" (assets.voice) to speak `text` with `voice` (default: the voice in ai.json) and writes the audio file at `path`. Records provenance in assets.json (the text is the prompt). Needs a key in the environment: ELEVENLABS_API_KEY (elevenlabs) or OPENAI_API_KEY (openai); without a provider the error says what to add to ai.json. To test code that depends on voice lines without a provider or a key, pass `silent: true`: it writes a silent .wav as long as the line (about 0.06 s per character, or `seconds`) and records it as a placeholder, not AI. Example: {"text":"Welcome, traveller.","path":"assets/voice/welcome.mp3"} COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `text` | string | yes | The words to speak. |
| `silent` | boolean | no | Write a silent WAV of the line's length instead of calling a provider (no key needed). For tests of code that plays voice lines; `path` must end in .wav. Default false. |
| `seconds` | number | no | With silent: the length of the clip. Default: about 0.06 s per character of `text`, from 0.4 to 20 s. Ignored by providers. |
| `voice` | string | no | The provider's voice name or id (openai: alloy, verse...; elevenlabs: a voice id). Default: assets.voice.voice in ai.json. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; with the fake provider and local programs it is not needed. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.import` (modifies state)

Since 0.1.6.

Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from.

Capabilities: read, writeProject, process

Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance (origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. The importer is chosen by the extension:
- .png .jpg .tga .bmp, .wav .ogg .mp3 .qoa, .ttf .otf: copied as they are (images are checked to decode).
- .gltf and .glb: copied with the .bin buffers and images their uris point at, which must sit next to the model or below it (a missing buffer is an error, a missing image a warning). An identical file already there is shared; a DIFFERENT image with the same name is kept and the result warns (kits ship different Textures/colormap.png files: import each kit into its own folder with `path`, or pass overwrite), and a DIFFERENT buffer is an `exists` error. project.validate reports a model whose texture or buffer is missing.

Example: {"source":"C:/art/hero.aseprite","license":"CC0","author":"Ana"}.

- .aseprite .ase: becomes an image document (<name>.image.json, one PNG per layer and changing cel in <name>.layers/) and the sprite sheet is baked from it: layers (hidden ones kept hidden; groups are flattened, their visibility and opacity kept), cels (a cel the file links to an earlier frame is a `link`), frame durations, tags (name, range, direction, repeat count) and blend modes. An indexed file stays an INDEXED document with its palette when the colors fit (opaque, at most 81); otherwise the layers are pixels layers and the result says why. Tags become the clips of the baked sheet's `sheet` entry (frames in a grid, `columns` per row, default ceil(sqrt(cells)); a reverse, ping-pong or repeated tag gets extra cells so it plays that way), so a SpriteAnimator plays a tag by clip name. A file with one frame and no tags bakes a plain PNG. Edit the result with image.* (image.pixel, image.draw, image.edit and image.paint take a `frame`; image.frame.* and image.tag.* change the animation). Not kept: tilemap layers, reference layers, cel z-indexes, the blend mode of a group and the 'divide' blend mode (the result warns). Pass flat: true for the old result: ONE PNG sprite sheet and the `sheet` entry of assets.json (columns, rows, frameWidth, frameHeight, frames and a clip per tag, fps from the frame durations), no document and no layers; hidden layers are left out, blend modes other than normal are drawn as normal and ping-pong or reverse tags become forward clips (the result says so). The result lists the Sprite and SpriteAnimator settings that play the sheet.
- .psd: the layers become an image document (<name>.image.json, one PNG per layer in <name>.layers/; names, opacity, visibility, blend modes, clipping, groups and layer masks are kept) and the PNG is baked from it; a file whose layers cannot be read imports its merged image as a PNG with a warning.
- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the bounds so you can scale it.
- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither installed the error says where to get them.
- .mid .midi: becomes a song document (assets/music/<name>.song.json, or `path`): tracks, patterns, sections from markers, drums as grids (music.import_midi has the options `quantize` and `soundfont`; docs/MUSIC.md, "MIDI").
- .mp4 .mov .webm .mkv .avi .m4v: converted to an MPEG-1 video with MP2 audio in an .mpg (the only video the engine plays, the same on every platform) by ffmpeg, at most 1280 px wide, quality 4, 30 fps when the frame rate is not one MPEG-1 has. ffmpeg is found through $FACTORIA_FFMPEG, PATH or the copy `factoria setup ffmpeg` installs; without it the error names that command. A source with no audio track gives a silent video (the result warns). The result has width, height, fps and duration and the Video component that plays it. An .mpg or .mpeg is checked to be MPEG-1 and copied.
Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/, videos in assets/video/ by default) or at `path`, which must be under assets/. An existing file is an error unless overwrite is true.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first. Path the command reads. |
| `path` | string | no | Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/, assets/fonts/ or assets/video/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX, .mpg for a video). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `license` | string | no | License or terms of the file, e.g. "CC0", "CC-BY 4.0", "bought from itch.io, single project". Recorded in assets.json. |
| `author` | string | no | Who made it. Recorded in assets.json for the credits. |
| `sourceUrl` | string | no | Where the file came from (a page URL). Recorded as the provenance source instead of the local path. |
| `ai` | boolean | no | Set true when AI made the content elsewhere (Steam's AI disclosure reads it). Leave out when unknown. |
| `columns` | integer | no | Aseprite only: frames per row of the baked sprite sheet (default ceil(sqrt(frames))); recorded as `sheet.columns` of the document. |
| `flat` | boolean | no | Aseprite only: skip the image document and write ONE PNG sprite sheet with its `sheet` entry (the layers are flattened, a ping-pong or reverse tag becomes a forward clip). Default false. |
| `overwrite` | boolean | no | Replace files that already exist. Default false. |

## `assets.list`

List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, vfx, other (by file name).

Capabilities: read

Example: assets.list {"folder":"assets","extension":".png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | no | Project-relative folder. Default "assets". |
| `extension` | string | no | Only files with this extension, e.g. .png |

## `assets.pack_atlas` (modifies state)

Since 0.3.0.

Pack a folder of images into one atlas PNG and write the frame table (rect and pivot per frame) that a Sprite's `region` reads.

Capabilities: read, writeProject

Every image under `folder` (png, jpg, tga, bmp; subfolders too) is a frame named by its path without the extension ("ship/0.png" is "ship/0"). They are packed into the smallest square page up to maxSize (tallest first), each with `padding` pixels of its own edge repeated around it so bilinear filtering and mipmaps never bleed a neighbour (the same padding as the export's atlas groups). The page is written to `out`, and the table to `table` (default `out` with .json): {"texture":"assets/atlas.png","size":[w,h],"frames":{"ship/0":{"rect":[x,y,w,h],"pivot":[px,py]}}}. rect is in texture pixels from the top-left, exactly Sprite.region; pivot is Sprite.pivot (+Y up). Pivots come from `<folder>/pivots.json` ({"ship/0":[0.5,0.2]}); a frame without one is [0.5, 0.5]. Keys of an existing table other than texture, size and frames are kept, so your own data can live in the same file.

Example: {"folder":"assets/src/frames","out":"assets/atlas.png","table":"data/atlas.json"}.

Packing again is stable: a frame whose size did not change keeps its rectangle (the page grows, never reshuffles), so a new picture changes the table by one line and a scene that copied a rect keeps drawing the same picture. Frames removed from the folder leave holes that new frames fill. Nothing is written when the result would be the same bytes. The result lists what was added, moved (changed size) and removed. Use this while developing, when many sprites must share one texture (a map of thousands of tiles, characters of one screen) and you want to pick frames by name; `factoria export` packs `atlas` groups by itself and Sprites keep naming the source PNGs (docs/ASSETS.md, "Atlases").

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | yes | Project-relative folder of images; each image (subfolders too) is one frame named by its path without the extension. An optional pivots.json inside gives pivots. Path the command reads. |
| `out` | string | yes | Project-relative .png to write, e.g. "assets/atlas.png". Replaced if it exists. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `table` | string | no | Project-relative .json for the frame table. Default: out with the .json extension. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `maxSize` | integer | no | Largest side of the page in pixels. Default 2048 (what every phone samples); 4096 is fine on desktop. Frames that do not fit are an error. |
| `padding` | integer | no | Pixels of the frame's own edge repeated around each frame. Default 2. |

## `assets.pick` (modifies state)

Since 0.18.0.

Keep the candidate the person chose: it becomes the slot, the others are dropped.

Capabilities: read, writeProject

Answers the review sheet that assets.generate_image {count} made for `slot` (its newest one: a newer sheet for the same slot replaces the older ones, which are refused as superseded) with the number the PERSON chose: never pick for them; show the sheet and ask. Candidate `n` is moved to `slot` and the slot's entry in assets.json gets its provenance (prompt, provider, model, seed, plus `candidates`: the sheet, the number picked, how many there were and the estimated cost of the batch); the candidates' own entries are removed. The other candidates move to .factoria/assets/candidates/<sheet id>/, where review.cleanup deletes them after 7 days. An existing slot file needs overwrite (here or in the generate call) and is kept in the same folder. All or nothing: when a file cannot be moved (open in another program: code busy) nothing changes. Refused: a slot whose newest sheet was already answered (already_picked), and a candidate file that is no longer the picture on the sheet (superseded). The editor's Review window calls it with {sheet, n, slot}. Example: {"slot":"assets/items/potion.png","n":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `slot` | string | yes | The path the candidates were made for: the `path` given to assets.generate_image, project-relative under assets/. |
| `n` | integer | yes | The number printed on the thumbnail the person chose (1 is the first candidate). |
| `sheet` | string | no | The candidates sheet to answer ("sheet-0007", or its number). It must be the newest candidates sheet of `slot` (an older one is refused as superseded). Default: that newest sheet. |
| `note` | string | no | Why this one, in the person's words; kept in the sheet's manifest with the choice. |
| `overwrite` | boolean | no | Replace a file that already exists at `slot` (the old file is kept in the sheet's drop folder for 7 days). Not needed when the generate call had overwrite:true. Default false. |

## `assets.preload` (modifies state)

Since 0.19.0.

Read a list of asset files in the background, ready for their first use.

Capabilities: read, state

Starts a background load of the listed files: textures, models, fonts and sounds are decoded into the engine's caches (a .gltf brings its buffers and textures, a .prefab.json or .material.json what it names); any other file is read into memory. Answers at once with `loadId` and the status; it advances in the frames the game runs. A missing file is an error with "did you mean"; a folder is an error too. Example: assets.preload {"paths":["assets/boss.glb","sounds/boss_theme.ogg"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Project-relative files to read ahead. |

## `assets.preview_in_scene` (modifies state)

Since 0.16.0.

See an asset inside a scene of the game: it is placed (a PNG as a Sprite, a .glb as a MeshRenderer) in a private run of the scene and captured at phone and desktop resolutions.

Capabilities: read, state

Starts the scene `scene` in a second, headless engine, steps `steps` frames (default 2) so its scripts start, puts a temporary entity with the asset in the world and captures the view once per resolution. The result is ONE image with the screens side by side, each labelled with its name and size, plus `screens` (each with its position in the picture and, for a 2D camera, whether the asset is in view). The scene file is never changed and the temporary entity exists only in that engine, so nothing needs cleaning up. Where: `at` [x, y(, z)] in world units; or `entity` (an id or name in the scene) with `placement` "beside" (default: to the right of it, using the size of its Sprite or Shape2D, 64 when it has none) or "replace" (at its position, the entity hidden for the picture); `offset` [x, y] moves it from there. Without either, the middle of the view: the camera's position for a 2D scene, a few meters in front of the camera for a 3D one. Example: {"path":"assets/slime.png","scene":"scenes/main.scene.json","entity":"player","size":48}.

`center: true` also moves a 2D camera onto the asset (a script that moves the camera can undo it). How big: `size` is in world units like Sprite.size: a number is the longest side (the proportions of the picture are kept), [w, h] sets both; without it the sprite is drawn at its size in pixels. A .glb takes one number, its largest dimension in meters, or its own size. A sprite sheet is placed as its first frame (from its `sheet` entry). `resolutions` are "phone" (540x1170, upright), "tablet" (1024x768), "desktop" (1280x720) or "WxH"; default phone and desktop. The run uses the resolution as the design resolution of the game, so the world a camera shows follows the shape of the screen the way the game's scale mode does on a device: a camera with a fixed orthoSize shows the same height on both. Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL); without one it fails with no_gpu. A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the work runs in a child `factoria call` process. The same inputs give the same pixels on the same GPU.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of the asset: a PNG/JPG (placed as a Sprite) or a .glb (placed as a MeshRenderer). Path the command reads. |
| `scene` | string | yes | Project-relative path of the scene to place it in, e.g. scenes/main.scene.json. The file is read, never written. Path the command reads. |
| `at` | array | no | World position [x, y] or [x, y, z] for the asset. Not with `entity`. |
| `entity` | string | no | Id (or name) of an entity of the scene: the asset goes next to it, or in its place (see `placement`). Not with `at`. |
| `placement` | string ["beside","replace"] | no | With `entity`: beside = to the right of the entity; replace = at its position, with the entity hidden in the picture. |
| `offset` | array | no | [x, y] in world units added to the position. |
| `size` | any | no | Sprite: a number (longest side) or [width, height], in world units like Sprite.size; default the size in pixels. Model: its largest dimension in meters; default its own size. |
| `resolutions` | array | no | "phone" (540x1170), "tablet" (1024x768), "desktop" (1280x720) or "WxH". Default ["phone", "desktop"]. |
| `steps` | integer | no | Frames the scene runs before the asset is placed. Default 2. |
| `center` | boolean | no | 2D scenes: move the camera onto the asset so it is in view at every resolution. Default false. |

## `assets.preview_sheet` (modifies state)

Since 0.6.0.

Look at a sprite sheet the way the game plays it: a labelled grid of its frames (numbers, cell edges, pivot, optional onion skin) plus checks for empty, cut or jumping frames and a loop seam.

Capabilities: read, state

Cuts the frames of the sheet at `path` with the grid of its `sheet` entry in assets.json (columns, rows, frameWidth, frameHeight, padding, frames; or the grid you pass), and returns a picture: every frame in a tile with its number (f<n>), a cyan rectangle for the frame, a grey one for the padding gutter around it and a magenta cross for the pivot (the clip's pivot, else the sheet's, else the centre; [x, y] from the top-left). `clip` shows one clip of the sheet; without it all the clips (or all the frames). `onion: true` draws the previous frame in red and the next in blue under the current one. It also checks the frames and returns `warnings` for: frames that draw nothing, shapes touching the edge of the cell (cut off), a bounding box that jumps by more than 30% of the frame between consecutive frames, a looping clip whose last frame jumps from the first or repeats it, and a grid that does not match the image size. The checks are the same for a sheet from assets.animate_svg, assets.bake_sheet, assets.slice_sheet or an Aseprite import, or one drawn by hand. The picture is a temporary screenshot in .factoria/screenshots. A wrong `clip` fails listing the clips of the sheet with a "did you mean". Example: {"path":"assets/hero.png","clip":"walk","onion":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of the sprite sheet image. Path the command reads. |
| `clip` | string | no | Show only this clip of the sheet entry (its frames, loop seam and pivot). Default: all the clips, or all the frames. |
| `onion` | boolean | no | Draw the previous frame in red and the next one in blue under each frame (onion skin). Default false. |
| `scale` | integer | no | Magnification of each frame (whole numbers, nearest-neighbour). Default: enough for about 160 px per tile. |
| `tileColumns` | integer | no | Tiles per row of the picture. Default: the sheet's columns for the whole sheet, else the closest to a square. |
| `columns` | integer | no | The grid when the sheet has no `sheet` entry (or to override it): frames per row. |
| `rows` | integer | no | The grid when the sheet has no `sheet` entry (or to override it): rows. |
| `frameWidth` | integer | no | Width of one frame in pixels, when it is not recorded. Default: the image divided by the grid. |
| `frameHeight` | integer | no | Height of one frame in pixels, when it is not recorded. Default: the image divided by the grid. |
| `padding` | integer | no | Transparent gutter around each cell, in pixels (cell i starts at padding + column * (frameWidth + 2 * padding)). Default: the sheet entry's, else 0. |

## `assets.provenance`

Since 0.1.6.

Show where assets came from: the provenance record of one file, or all of them.

Capabilities: read

With `path`, the provenance record of that file (null when it has none). Without, every record in assets.json, how many are AI-made, and the art, sound and model files under assets/ that have no record yet. Example: {"path":"assets/hero.png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path under assets/. Omit to list every record. |

## `assets.rasterize_svg` (modifies state)

Since 0.4.0.

Turn an SVG (text or a project file) into a PNG at a given size, offline: art you write as vector shapes, no provider and no key.

Capabilities: read, writeProject

Rasterizes an SVG to a PNG at `path` (under assets/, ending in .png) with no AI provider and no key, anti-aliased, on the CPU (no GPU, so it works headless and in CI). Pass the SVG text in `svg` or an .svg file of the project in `source`. This is how an agent without an image provider draws a subject (a crest, a portrait silhouette, an ornament, a map symbol): write the shapes as SVG, rasterize, look at the picture in the result, edit the SVG, repeat. The size is `width` x `height` (the SVG is fitted inside, aspect kept, centred; give one and the other follows the SVG's proportions); leave both out for the size the SVG declares. Example: {"path":"assets/art/crest.png","width":256,"svg":"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='M50 6 L90 22 V52 C90 76 70 90 50 96 C30 90 10 76 10 52 V22 Z' fill='#8b1e1e' stroke='#e8c66a' stroke-width='4'/><circle cx='50' cy='48' r='14' fill='#e8c66a'/></svg>"}

Supported: path (all commands), rect (with rx, ry), circle, ellipse, line, polyline, polygon, g, defs, linearGradient and radialGradient fills (stops, gradientTransform, gradientUnits; write gradient coordinates in percent, x2="100%", or with gradientUnits="userSpaceOnUse" and real coordinates: a bare 0..1 such as x2="1" is read as one pixel), fill, stroke, stroke-width, stroke-linecap, stroke-linejoin, stroke-miterlimit, stroke-dasharray, fill-rule, opacity, fill-opacity, stroke-opacity, transform, the style attribute, viewBox and preserveAspectRatio. Also supported: <clipPath> (clip-path="url(#id)" on a g or on a shape; children path, rect, circle, ellipse, polygon, polyline, line, with their transforms and clip-rule; clipPath transform; only clipPathUnits="userSpaceOnUse", the default, with real coordinates in the user space of the element that uses it), <mask> (mask="url(#id)"; the luminance of the mask's content times its alpha, white shows, black hides; maskUnits and the mask region are ignored, the mask covers the whole picture), and <pattern> fills (fill="url(#id)", also inherited from a g; patternUnits userSpaceOnUse or objectBoundingBox (the default), patternContentUnits, patternTransform, so line hatching is a pattern of one stroked line, rotated with patternTransform="rotate(45)"; the tile is not clipped to its width and height, no pattern viewBox or href chains; a pattern as `stroke` is not drawn). Clipped, masked and pattern shapes are rendered one layer each, so a picture with hundreds of them is slower. NOT supported (drawn as nothing, and named in `warnings`): text and tspan (convert letters to paths, or draw text in the engine with a Text entity), filters (blur, drop shadow), embedded images, <use>, markers and CSS classes in <style>. For a texture of a material (wood, paper, stone) use assets.generate_texture instead. Provenance is recorded in assets.json: by default as AI-made (origin generated, ai true, because the calling agent wrote the SVG, which counts for Steam's AI disclosure); pass ai: false for an SVG a person drew or licensed, with `author` and `license`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the PNG, project-relative, under assets/ and ending in .png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG document as text, starting with <svg ...>. Give this or `source`. |
| `source` | string | no | A project-relative .svg file, e.g. "assets/art/crest.svg". Give this or `svg`. Path the command reads. |
| `width` | integer | no | Width in pixels. With only the height given, it follows the SVG's proportions. Default: the SVG's own size. |
| `height` | integer | no | Height in pixels. With only the width given, it follows the SVG's proportions. |
| `background` | any | no | A colour to put the picture over ("#rrggbb", "#rrggbbaa", a name or [r, g, b]). Default: transparent. |
| `style` | string ["none","watercolor","ink","inkwash","paper"] | no | Default none. A painterly look added to the pixels after rasterizing (nanosvg has no filters, so the effects are applied to the picture, seeded and deterministic, and cost no SVG size). "watercolor": edges wobble and soften, pigment pools darker along the borders of every shape, pale and strong blotches, paper granulation. "ink": a wobbling pen line (dark brown, thicker and thinner) along every border. "inkwash": both, with a little paper tooth: storybook ink and watercolour. "paper": only fine paper fibres and mottling, edges untouched. Draw flat fills with a few shapes: the style supplies the texture. The effects scale with the picture's size. |
| `styleStrength` | number | no | How strong the `style` is: 0 leaves the picture as drawn, 1 (the default) is the full effect, 0.5 is subtle. Ignored without a `style`. |
| `seed` | integer | no | Chooses the take of the `style` (where the blotches, wobble and grain fall): the same SVG, size, style and seed always give the same picture; change it for another take. Ignored without a `style`. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |
| `ai` | boolean | no | Whether the SVG was written by an AI (the default, since the caller is an agent). Set false for an SVG a person drew or a licensed one; it then counts as original work in the AI disclosure. Default true. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the picture for the provenance record. Default "CC0-1.0". |

## `assets.regenerate` (modifies state)

Since 0.6.0.

Make a made asset again from the recipe its provenance records, and say what changed.

Capabilities: read, writeProject

The offline makers (assets.rasterize_svg, assets.draw_icon, assets.draw_capsules, assets.generate_texture, assets.synth_sound, assets.generate_loop, assets.pack_atlas, assets.slice_sheet) record in assets.json `provenance.recipe`: {command, args, inputs: [{path, sha256}]}, the command that made the asset, the arguments that make the same bytes again and the project files it read with their hashes. This command runs that recipe through the command registry (any assets.* command that writes a recipe works, there is no list) with `overwrite: true`, and reports per file what changed: "pixels changed", "bytes changed (same pixels)", "unchanged" or "created", the size and the `sheet` layout before and after. Give `path` for one asset, `all` for every asset with a recipe, or `stale` for those whose `inputs` no longer match the files (an SVG or other source file you edited). Assets that read the output of another (a sheet sliced from a picture made from an SVG) are made after it, and `stale` looks again at their inputs when their turn comes. `dryRun` lists what would run and which inputs changed, and changes nothing. Example: {"stale":true} or {"path":"assets/art/coin.png"}.

What a person recorded in the provenance (license, author, notes) is kept; the recipe and the date are new. Several files made by one call (an icon and its foreground, a texture and its normal map, the capsules of a store) are made once. Provider-made assets (assets.generate_image...) have no recipe: they would cost money and give a different picture, so asking for one is an error that says so. `factoria validate` warns about a stale asset with this command in its hint.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the asset to make again (it must record a recipe). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `all` | boolean | no | Make every asset with a recipe again. |
| `stale` | boolean | no | Make again only the assets whose recipe inputs (the files they were made from) changed since. |
| `dryRun` | boolean | no | List what would run (command, arguments, which inputs changed) and change nothing. |

## `assets.review` (modifies state)

Since 0.16.0.

A cheap one-shot vision review of the pictures you made: a verdict and concrete fixes, grounded on assets.check_art and the style references.

Capabilities: read, network, process, spend

The optional last look of the make, preview, check, fix loop (docs/AI_GUIDE.md 9.23, docs/ASSETS.md "Reviewing art"). It runs assets.check_art on the same pictures first, then sends a vision model the pictures, the annotated picture of the check, the check's numbers, the style rules of assets.json and the style `references` images, and asks what the numbers cannot tell: does it match the style, does it read, does it suit its use. Unlike the user-only art critics of ai.review, you can call it yourself while you work. It uses the model of the "fast" role of ai.json (the orchestrator when fast is off; the artist role is usually an image generator, not a viewer), so the model must accept pictures; with no provider, no key or a text-only model the error says what to set up (docs/AI_PROVIDERS.md) and you carry on with assets.check_art alone. One model call per review: call it once the check shows no `fail`, not after every edit. Example: {"paths":["assets/knight.png","assets/orc.png"],"focus":"do they look like the same game at 48 px?"}

Result: {verdict: good | fix | redo (never `good` while the check has a fail), summary, fixes: [{what, where, command}], checkArt: {verdict, counts, assets, set}, role, provider, model, warnings, nextSteps}. A fix names a command or an assets.json setting; one that names something this engine does not have is listed in `warnings`. Nothing is written to the project.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the picture to review. Give this or `paths`. |
| `paths` | array | no | Up to 4 pictures reviewed together, as a set. Give this or `path`. |
| `focus` | string | no | What you want judged ("does the outline match the references?", "is the coin readable on the dark floor?"). Optional. |

## `assets.set_provenance` (modifies state)

Since 0.1.6.

Record where an asset came from (hand-made, imported, or made with AI elsewhere).

Capabilities: read, writeProject

Replaces the provenance record of an existing file in assets.json (the recipe that assets.regenerate runs, when the file has one, and its style `role`, unless you pass `role` "" or null, are kept). The generate commands write it for you; use this for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to true for origin generated, false otherwise). Example: {"path":"assets/music/theme.ogg","origin":"imported","ai":false,"license":"CC0","source":"https://example.com/theme","author":"A. Composer"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of an existing file under assets/ (or a 3D clip, *.anim.json, anywhere in the project). |
| `origin` | string ["generated","imported","original"] | yes | generated: made by an asset provider. imported: brought in from a file made elsewhere. original: made by hand for this game. |
| `ai` | boolean | no | Whether AI made the content. Default: true for origin generated, false otherwise. |
| `kind` | string ["image","sound","music","voice","model3d","anim3d"] | no | What the asset is, so the disclosure can tell sound effects, music and voice apart. anim3d: a 3D bone clip (*.anim.json), which the anim3d commands record themselves. |
| `provider` | string | no | Tool or provider that made it ("openai", "suno", "Aseprite"...). |
| `model` | string | no | Model that made it, for AI-made assets. |
| `prompt` | string | no | The prompt it was made from, for AI-made assets. |
| `references` | array | no | Reference images used. |
| `seed` | integer | no | Seed, when there was one. |
| `license` | string | no | License or terms ("CC0", "Purchased, standard license"...). |
| `author` | string | no | Person, studio or agent that made or chose the asset. |
| `source` | string | no | Where an imported asset came from: a URL or the original file. |
| `date` | string | no | YYYY-MM-DD. Default: today. |
| `notes` | string | no | Anything else, such as edits made by hand. |
| `role` | any ["ui","icon","effect","",null] | no | What the picture is for: the style checks leave out the rules that do not apply to it (ui and icon: texelsPerUnit, lightDirection; effect: also outline, value, saturation). Left out: the role the asset already has stays. "" or null takes the role back. docs.read ASSETS, "Scoping the style rules". |

## `assets.slice_sheet` (modifies state)

Since 0.1.6.

Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them.

Capabilities: read, writeProject

SpriteAnimator plays a uniform grid of frames (columns x rows, row-major from the top-left). Two ways to get one:
1. The image already is a grid: give columns/rows (or frameWidth/frameHeight). The grid is checked against the image size (a width that columns does not divide is an error that lists the columns that fit) and recorded as the `sheet` of the image in assets.json. Example: {"path":"assets/hero.png","columns":4,"rows":2,"fps":12}.
2. Frames separated by transparent gutters and of uneven sizes, as AI-generated and downloaded sheets often are: pass auto: true. Every group of touching pixels is a sprite (sprites whose boxes overlap are one frame), ordered by rows then columns, and repacked into a uniform grid of the largest sprite's size, each centred (align "bottom" stands characters on the same ground line). The new PNG is `out` (default <name>_sheet.png next to the image; the source is kept). `frames` is the number of sprites you expect: a different count is an error that lists what was found. Example: {"path":"assets/hero_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}.

background "auto" first makes a solid background transparent (the four corners must be the same opaque colour; the background that touches them is cleared, the same colour inside a sprite stays), also for a grid. The result has the `sheet`, the SpriteAnimator fields and the Sprite texture to use. Aseprite files need no slicing: assets.import reads their frames and tags.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative image (png, jpg, tga, bmp), e.g. "assets/hero.png". Path the command reads. |
| `columns` | integer | no | Grid mode: frames per row (1 if neither columns nor frameWidth is given). With auto: frames per row of the new sheet (default: the most sprites found in one row). |
| `rows` | integer | no | Grid mode: number of rows (1 if neither rows nor frameHeight is given). |
| `frameWidth` | integer | no | Grid mode: width of a frame in pixels, instead of columns. |
| `frameHeight` | integer | no | Grid mode: height of a frame in pixels, instead of rows. |
| `frames` | integer | no | Grid mode: how many cells are used, row by row (default all; the last row may be partly empty). With auto: the number of sprites you expect (a different count is an error). |
| `fps` | number | no | Playback speed to put in the SpriteAnimator fields of the result (default 10). Not stored in assets.json. |
| `auto` | boolean | no | Find the frames (groups of touching pixels separated by transparent gutters) and repack them into a uniform grid. Default false. |
| `align` | string ["center","bottom"] | no | auto only: where a sprite sits in its cell. center (default), or bottom: centred horizontally with feet on the cell's bottom edge, for characters standing on the ground. |
| `background` | string ["none","auto"] | no | auto: first make the solid background (the four corners the same opaque colour) transparent. Default none. |
| `out` | string | no | PNG to write when the pixels change (auto, background) or when given: default <name>_sheet.png next to the image. An existing file is replaced; use the image's own path to change it in place. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |

## `assets.spectrogram` (modifies state)

Since 0.16.0.

See a sound: a picture of its waveform, spectrogram (log frequency) and loudness curve, with the clipped samples and the loop seam marked.

Capabilities: read, state

Decodes the sound at `path` (.wav, .ogg, .mp3, .qoa) and returns one picture, like assets.preview_sheet does for a sprite sheet: the waveform on top (mid, or each channel; red columns are samples at full scale), a spectrogram in the middle (short-time Fourier transform of the mid channel, 20 Hz to 20 kHz on a logarithmic axis, brighter = louder, with a dB scale) and the loudness curve at the bottom (momentary 400 ms in blue, short-term 3 s in orange, the integrated value dashed, the loudest momentary value marked). When the sound is played looping (an AudioSource with loop, SceneSettings.music, audio.music, or audio.play with loop: true; or `loop: true` here) magenta dashed lines mark the loop seam and the title gives its jump and slope. Axes are labelled with the engine's built-in font. The result carries the numbers: integratedLufs, truePeakDb (4x oversampled), samplePeakDb, momentaryMaxLufs, shortTermMaxLufs, seconds, clippedSamples (samples flattened at full scale), dominantBand (the loudest octave band) and loopSeam. It reuses the sound's fresh `analysis` record for the integrated loudness and writes nothing unless `out` is given. The picture is a temporary screenshot in .factoria/screenshots; with `out` the PNG is kept at that project path. Example: {"path":"assets/music/theme.ogg","width":1200}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative sound file, e.g. assets/sfx/jump.wav. Path the command reads. |
| `width` | integer | no | Width of the picture in pixels. Default 1000. |
| `height` | integer | no | Height of the picture in pixels. Default 640. |
| `out` | string | no | Also keep the PNG at this project-relative path (must end in .png; needs the writeProject capability, never inside .git or .factoria). Without it the picture is a temporary screenshot. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `loop` | boolean | no | Mark the loop seam. Default: whether the project plays the sound looping (scenes, prefabs and scripts). |
| `channels` | string ["mid","each"] | no | "mid": one waveform of the average of the channels; "each": one lane per channel of a stereo sound. Default "mid". |

## `assets.subset_font` (modifies state)

Since 0.3.0.

Cut a font down to the characters of the locale tables plus Latin and punctuation (a CJK font from 17 MB to a few hundred KB), pinning a variable font's axes.

Capabilities: read, writeProject

Reads the font `source` (an absolute path on this machine, or relative to the project) and writes `out` (under assets/) with only the glyphs for: every character of locales/<language>.json for the `locales` (default: factoria.json's localization.languages; the same characters the glyph check of `factoria validate` asks a font for), printable ASCII, Latin-1 (Spanish and French letters), the full-width forms, the CJK punctuation line breaking needs, and the characters of `keep`. The shaping tables (GSUB, GPOS, GDEF, kerning) and the name strings (the license) stay; hinting and glyph names are dropped. A variable font is pinned to one instance (`axes`, default {"wght":400}; its other axes go to their default), because the engine draws a variable font's default instance and a Thin default would draw hairlines. Example: {"source":"C:/fonts/NotoSansSC[wght].ttf","locales":["zh-Hans"],"out":"assets/fonts/NotoSansSC-Regular-subset.ttf"}. Check the font's license allows modifying it (SIL OFL fonts do, but ask not to keep the Reserved Font Name; Noto has none) and keep its license file next to the result.

Runs HarfBuzz's subsetter: no Python or fontTools. The result has the sizes, the glyph and character counts, and `missing`: characters of the strings the source font does not have. Nothing is written when the result is the same bytes, so run it again whenever a string changes.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The font to cut: an absolute path on this machine, or a path relative to the project folder. A .ttf or .otf, static or variable. Path the command reads. |
| `out` | string | yes | Project-relative .ttf or .otf under assets/ to write, e.g. "assets/fonts/NotoSansSC-Regular-subset.ttf". Replaced if it exists. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `locales` | array | no | Languages whose locales/<language>.json give the characters, e.g. ["zh-Hans"]. Default: every language of localization.languages in factoria.json. |
| `keep` | string | no | Extra characters to keep, written out: e.g. the characters a script builds names from, or a whole alphabet. |
| `axes` | object | no | Where to pin the variable font's axes, tag to value: {"wght":400}. Default {"wght":400}. An axis not listed goes to its default. |

## `assets.synth_sound` (modifies state)

Since 0.3.0.

Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.

Capabilities: read, writeProject

Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no key. The presets are sound patches rendered by the engine's synthesizer: sfx.preset returns one as an editable *.sfx.json (docs/SOUND.md), so to change a sound instead of taking it as it is, write the patch, edit it and call sfx.render. The same preset, seed and seconds always give the same bytes; another `seed` is another take of the same sound (the noise changes and the pitch moves up to 10 percent). `seconds` stretches the whole sound. Levelled to about -18 LUFS (peak under -1 dBFS), so no preset trips validate's loudness warning. Records provenance in assets.json (origin original, ai false, license CC0, the preset and the seed). Presets:


- bark: a dog bark: two short rough barks.
- growl: a low growl: a rattling low saw with noise.
- meow: a cat meow: a rising then falling vowel-like tone.
- screech: a high rough screech.
- whoosh: air passing: noise swelling and fading.
- explosion: a blast: low rumble and a noise burst.
- hit: an impact: a short thump with a click.
- coin: a coin pickup: two bright notes.
- pickup: an item pickup: a quick rising blip.
- jump: a jump: a rising chirp.
- powerup: a power-up: a fast rising arpeggio-like sweep.
- laser: a laser shot: a quick falling zap.
- blip: a UI blip: a very short tone.
- click: a UI click: a tiny noise tick.
- error: a refusal buzz: two low square pulses.
- splash: water: a noisy plop that fades.
- footstep: a soft footstep on dirt.
Good for placeholders and simple effects; for richer sounds import a CC0 kit (docs/ASSETS.md) or use assets.generate_sound. Example: {"path":"assets/audio/dog_bark.wav","preset":"bark","seed":3}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. "assets/audio/bark.wav". Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `preset` | string ["bark","growl","meow","screech","whoosh","explosion","hit","coin","pickup","jump","powerup","laser","blip","click","error","splash","footstep"] | yes | The kind of sound to make. See the list in the command description. |
| `seed` | integer | no | Chooses the take: the same preset and seed always give the same file; change it for a variation (the noise changes and the pitch shifts up to 10 percent). Default 0. |
| `seconds` | number | no | Length in seconds: the whole sound (envelopes, sweeps) is stretched to it. Default: the preset's own length. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |

## `audio.bake` (modifies state)

Since 0.16.0.

Render audio documents to WAV/OGG files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.

Capabilities: read, writeProject

Without `path` this bakes every *.audio.json of the project whose sound is missing or out of date (its document or a file it reads changed: the recipe's hashes), like sfx.bake. With `path` it bakes that document. The sound goes to `output.path` of the document, else next to it as <name>.wav (or .ogg); assets.json records provenance (a CC0 license for synthesized sources; the license and author of the files it read otherwise) and the recipe, so assets.regenerate and project.validate know when it is stale. A `loop` step stores its points as the import settings loopStart/loopEnd of the output, which a looping AudioSource honours. A file that nothing baked is never replaced unless overwrite is true. `factoria export` bakes the stale documents first. Example: {} or {"path":"assets/audio/door.audio.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Bake only this document (project-relative, ending in .audio.json). Leave out for every document. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `force` | boolean | no | Bake documents that are fresh too. Default false. |
| `dryRun` | boolean | no | List what would be baked and why, and write nothing. Default false. |
| `overwrite` | boolean | no | Replace a file at the output that no audio document baked. Default false. |

## `audio.create` (modifies state)

Since 0.16.0.

Write a new audio document (a source and a chain of steps) and bake it.

Capabilities: read, writeProject

Writes `path` (*.audio.json under assets/) with the format, `source` (a project WAV/OGG/MP3, an .sfx.json patch or another .audio.json), the `steps` (list of step objects; audio.info {} lists the types and fields) and the optional `seed`, `output` ({format wav|ogg, channels source|mono, quality, path}) and `doc` note. The document is checked first: a mistake returns every issue and writes nothing. Then it is baked (unless bake is false) and the result holds the measurements. Example: {"path":"assets/audio/door.audio.json","source":"assets/raw/door.wav","steps":[{"type":"trim","auto":true},{"type":"fade","out":0.05},{"type":"normalize","target":-3}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The audio document, project-relative, under assets/, ending in .audio.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `source` | string | yes | The sound to start from: a project path ending in .wav/.ogg/.mp3/.qoa, .sfx.json or .audio.json. Path the command reads. |
| `steps` | array | no | The chain, in order. Each step is {"type": ..., fields}. |
| `seed` | integer | no | Seed of the random steps. |
| `output` | object | no | {format: wav\|ogg, channels: source\|mono, quality: 0..1 (ogg), path: where to bake}. |
| `doc` | string | no | A note on what the sound is for. |
| `overwrite` | boolean | no | Replace the document when it exists (and the baked sound when nothing baked it). Default false. |
| `bake` | boolean | no | Bake the sound after writing. Default true. |

## `audio.edit` (modifies state)

Since 0.16.0.

Add, change, remove or move one step of an audio document (or change its source, seed or output), then bake it.

Capabilities: read, writeProject

`op` is one of: add (insert `step`, an object, at `index`, default the end), set (change the fields of step `index` with `values`; a null value removes a field), remove (delete step `index`), move (take step `index` to position `to`), document (change `source`, `seed` or `output`). The result document is checked as a whole before anything is written, so a bad value returns every issue with its JSON pointer and writes nothing; the file keeps the other steps as written. Then the sound is baked again (unless bake is false) and the measurements tell what the edit did. Example: {"path":"assets/audio/door.audio.json","op":"set","index":2,"values":{"target":-6}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The audio document, project-relative, under assets/, ending in .audio.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `op` | string ["add","set","remove","move","document"] | yes | What to do. |
| `index` | integer | no | The step to act on (add: where to insert it). |
| `step` | object | no | add: the new step, {"type": ..., fields}. |
| `values` | object | no | set: fields to change; null removes a field. |
| `to` | integer | no | move: the new position. |
| `source` | string | no | document: the new source. Path the command reads. |
| `seed` | integer | no | document: the new seed. |
| `output` | object | no | document: the new output settings. |
| `bake` | boolean | no | Bake the sound after writing. Default true. |
| `picture` | boolean | no | Return the waveform/spectrogram picture after baking. Default false. |
| `overwrite` | boolean | no | Replace a sound that no audio document baked. Default false. |

## `audio.info`

Since 0.16.0.

Check an audio document and say what its chain renders to; with no arguments, list the step types and their fields.

Capabilities: read

An audio document (`*.audio.json`, docs/SOUND.md "Audio documents") is a non-destructive chain over a sound: a WAV/OGG, an .sfx.json patch or another audio document, then steps (trim, fade, normalize, gain, pitch, stretch, speed, eq, filter, compressor, distortion, bitcrush, reverb, delay, reverse, layer, loop, granular). With `path` (or an inline `document`) this checks it: a document with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and the fix; a valid one returns its steps, where it bakes to and whether that sound is fresh or stale, and (unless render is false) renders it in memory: seconds, loudness, peak, brightness (centroidHz), the loop points of a loop step and the length and peak after each step. With no argument it returns the catalog of step types with every field, its range, default and doc string. Example: {"path":"assets/audio/door.audio.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The audio document, project-relative, under assets/, ending in .audio.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, to check before writing it to a file (format is filled in). |
| `seed` | integer | no | Render this take (replaces the document's seed). |
| `render` | boolean | no | Render the chain in memory for the measurements. Turn it off to only check it. Default true. |

## `audio.render` (modifies state)

Since 0.16.0.

Render an audio document in memory: measurements, what each step did, and a waveform/spectrogram picture. Writes no sound.

Capabilities: read, state

Applies the chain of the document (`path`, or an inline `document`) and returns the measurements (seconds, integrated loudness in LUFS, peak in dBFS, centroidHz, loop points), the length and peak after every step, and a picture (`$image`): the source and the result, each as a waveform over a spectrogram with its numbers, on one time and level scale. `stopAfter` renders only steps 0..stopAfter to hear the chain up to a step; `seed` takes another take of the random steps. The same document and files always render the same samples. Example: {"path":"assets/audio/door.audio.json","stopAfter":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The audio document, project-relative, under assets/, ending in .audio.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, instead of `path`. |
| `seed` | integer | no | Replaces the document's seed for this render. |
| `stopAfter` | integer | no | Render only steps 0..stopAfter. |
| `compare` | boolean | no | Show the unprocessed source above the result in the picture. Default true. |
| `picture` | boolean | no | Return the picture (`$image`). Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png; needs the writeProject capability). Without it the picture is a temporary screenshot. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |

## `image.bake` (modifies state)

Since 0.16.0.

Draw a layered image document (*.image.json) into its PNG and return the picture.

Capabilities: read, writeProject

Composites the layers of the image document at `path` (project-relative, ending in .image.json) on the CPU and writes the PNG next to it (hero.image.json -> hero.png, or the document's `output`). Bytes are deterministic: the same document and files give the same PNG. Records provenance and the recipe {command image.bake, args {path}, inputs: the document and every file it reads} in assets.json, so assets.regenerate remakes the PNG and `factoria validate` warns when the document or a source file changed since (stale). A document with `frames` or `tags` bakes a SPRITE SHEET (the frames in a grid) and records its SpriteAnimator clips, one per tag, in the `sheet` entry of the PNG, returned as `sheet`. A picture with a provider layer, or built from AI-made files, is recorded as AI-made. The result has the picture as `$image`, its size and any warnings. A problem in the document is an error with the file, the JSON pointer and a fix. Format and layers: docs.read IMAGES. Example: {"path":"assets/art/hero.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. "assets/art/hero.image.json". Path the command reads. |
| `onlyIfNeeded` | boolean | no | Skip the drawing when the PNG already matches the document and every file it reads (what the export does). Default false. |

## `image.create` (modifies state)

Since 0.16.0.

Make a new layered image document (*.image.json) with a canvas size, a background and optional first layers, and bake its PNG.

Capabilities: read, writeProject

Writes a new image document at `path` (project-relative, ends in .image.json) with a width x height canvas (1..4096), an optional `background` colour and optional `layers` (bottom first; docs.read IMAGES lists the kinds), then bakes the PNG next to it. Refuses to replace an existing file unless overwrite is true. The result has the picture as `$image`, the changed `region` {x,y,width,height} (the whole canvas for a new document) and next steps. Example: {"path":"assets/art/hero.image.json","width":64,"height":64,"background":"#00000000","layers":[{"kind":"fill","name":"sky","color":"#203040"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | yes | Canvas width in pixels. |
| `height` | integer | yes | Canvas height in pixels. |
| `background` | any | no | A colour the canvas starts with: "#rrggbb", "#rrggbbaa", a CSS name or [r,g,b,a]. Without it the canvas starts transparent. |
| `layers` | array | no | The first layers, bottom first, each an object with `kind` (see docs.read IMAGES). Default none. |
| `description` | string | no | A sentence for people and AIs about the picture. |
| `palette` | any | no | For indexed (pixel-art) layers: "style" (the style palette of assets.json, the default for an indexed layer) or a list of colours, each "#rrggbb" or {"name", "color"}; at most 81. See docs.read IMAGES, "Pixel art". |
| `ramps` | array | no | Colour ramps for shading by index: lists of palette colours (index, name or "#rrggbb") from the darkest to the lightest, e.g. [["skin-dark","skin","skin-light"]]. |
| `output` | string | no | The PNG the document bakes to, project-relative, ending in .png (e.g. "assets/art/enemy.png" to replace an existing picture). Default: next to the document, its name with .image.json replaced by .png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the document when it already exists. Default false. |
| `bake` | boolean | no | Also draw the PNG. Default true. |

## `image.draw` (modifies state)

Since 0.16.0.

Draw pixel-exact shapes (lines, rectangles, ellipses, polygons, flood fills) onto an indexed pixel-art layer by palette colour.

Capabilities: read, writeProject

Each shape of `shapes` is drawn in order on the indexed layer `layer` (see image.pixel for `layer`, `create`, coordinates and colours); no anti-aliasing: a pixel is either set or not. Shapes: line {points [[x,y],...] (a polyline), color, perfect?, closed?} (Bresenham; `perfect: true` removes the L-corners of a bending line so it is one pixel thick everywhere); rect {x, y, width, height, color?, fill?}; ellipse {x, y, width, height, color?, fill?} (inscribed in the box, midpoint algorithm, any odd or even size); polygon {points (>= 3), color?, fill?}; fill {at [x,y], color, connectivity? 4|8} (flood fill of the layer's pixels connected to `at` that hold the same colour or transparency; 4 does not leak through diagonal gaps). For rect, ellipse and polygon `color` is the outline and `fill` the inside: a colour, or true for `color`; give either or both (the fill is drawn first, so the outline stays). Result as image.pixel (`region`, `pixelsSet`, `$image` magnified with hard pixels).

Example: {"path":"assets/art/hero.image.json","layer":"sprite","create":true,"shapes":[{"type":"ellipse","x":2,"y":2,"width":12,"height":12,"fill":"skin","color":"outline"},{"type":"line","points":[[2,14],[8,10],[14,14]],"color":"outline","perfect":true},{"type":"fill","at":[8,8],"color":"skin-light"}]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to draw on: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to draw on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create a blank indexed layer with it at the top. Default false. |
| `shapes` | array | yes | The shapes, drawn in order. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `frame` | integer | no | Which frame of an animated document to draw on (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.edit` (modifies state)

Since 0.16.0.

Change the selected pixels of one layer of an image document: fill, recolor, move, transform (scale, rotate, flip), delete, copy or cut to a new layer.

Capabilities: read, writeProject

Applies `action` to the pixels of `layer` inside the stored `selection` (made with image.select; "all" is the whole canvas). Actions: fill {color, opacity?}; recolor {hueShift degrees, saturation -1..1, value -1..1} or {from, to, tolerance?, keepShading?}; move {dx, dy, copy?} (whole pixels; the selection moves along unless moveSelection is false); transform {scale number or [sx,sy], rotate degrees clockwise, flipH, flipV, filter nearest|bilinear, pivot [x,y]} (the selected pixels are lifted, transformed around the pivot - default their middle - and put back; the default filter is nearest when the project's style guide says pixelArt, else bilinear); delete (the selected pixels become transparent); copy and cut {name?} (the selected pixels become a new pixels layer above `layer`; cut also clears them). POLICY FOR OTHER LAYER KINDS: a pixels layer's PNG is edited in place (an AI-generated image keeps that mark, the edit is added to its provenance).

A shape, gradient, text or other non-pixel layer is first rasterized: it becomes a pixels layer (its masks, adjustments and effects are baked into the pixels, its blend, opacity and visibility stay) with a new PNG in <document>.layers/ and a warning says so. Groups and adjustment layers cannot be edited this way. A layer with masks keeps its box (the masks are in its own pixels), so pixels moved outside it are dropped (a warning counts them); other layers grow to hold what you move into the canvas. Result: the baked document plus `region` {x,y,width,height} of the changed pixels, `changed` and the picture as `$image`. Example: {"path":"assets/art/hero.image.json","selection":"cape","layer":"hero","action":{"type":"recolor","hueShift":120}} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to edit: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `selection` | string | yes | The stored selection to act on (image.select), or "all". |
| `layer` | any | yes | The layer to change: its name or an index path like "1/0". |
| `action` | object | yes | What to do. type: fill, recolor, move, transform, delete, copy, cut. See the command description for each action's fields. |
| `name` | string | no | copy / cut: the new layer's name (default: '<layer> copy' / '<layer> cut'). |
| `bake` | boolean | no | Bake the document to its PNG after the edit. Default true. |
| `frame` | integer | no | Which frame of an animated document to edit (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.export` (modifies state)

Since 0.16.0.

Write the flattened picture of a document, or one layer or group of it, to a PNG, optionally scaled or trimmed.

Capabilities: read, writeProject

Draws the document at `path` (or only `layer`, by name or index path, with its masks, adjustments and effects but at full opacity and normal blend; the offsets of the groups around it count) and writes a PNG to `out`. `scale` resizes (0.01..16) with `filter` nearest (pixel art) or bilinear; the default filter is nearest when assets.json style.pixelArt is true, else bilinear. `trim` crops to the pixels that show. The PNG is a plain copy, not baked from the document. Refuses to replace an existing file unless overwrite is true. Example: {"path":"assets/art/hero.image.json","out":"assets/art/hero-x2.png","scale":2} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to export: the picture of that frame is written.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document. Path the command reads. |
| `out` | string | yes | The PNG to write, project-relative, ending in .png. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `scale` | number | no | Size factor of the result. Default 1. |
| `layer` | any | no | Export only this layer or group (name or index path) instead of the whole picture. |
| `trim` | boolean | no | Crop to the pixels that are not transparent. Default false. |
| `filter` | string ["nearest","bilinear"] | no | How scale resamples. Default: nearest for pixel-art projects, else bilinear. |
| `overwrite` | boolean | no | Replace `out` when it exists. Default false. |
| `frame` | integer | no | Which frame of an animated document to export (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |

## `image.frame.add` (modifies state)

Since 0.16.0.

Add frames to an image document (making it an animation), copying a frame or blank, and keep the tags in place.

Capabilities: read, writeProject

Inserts `count` frames at `at` (0..number of frames; default: at the end). Each new frame shows what frame `from` shows (default the frame before `at`, or frame 0 when `at` is 0), or nothing with `blank: true`, on every pixels and indexed layer; layers of other kinds are the same in every frame. A document with no `frames` is one frame, so the first call makes it an animation (it then bakes to a sprite sheet next to the document). `duration` is the new frames' time in milliseconds (default: the copied frame's, 100 for a new animation). Tags after `at` move along; a tag the new frames land inside grows. Draw on a frame with image.pixel / image.draw / image.edit / image.paint and `frame`. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","count":3} makes a 4-frame animation of the same picture.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `at` | integer | no | Where the new frames go (default: after the last frame). Existing frames from here on move up. |
| `from` | integer | no | The frame the new frames copy (default: the frame before `at`). |
| `blank` | boolean | no | The new frames show nothing on pixels and indexed layers. Not with `from`. Default false. |
| `count` | integer | no | How many frames to add. Default 1. |
| `duration` | integer | no | Milliseconds each new frame shows (default: the copied frame's). |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.frame.cel` (modifies state)

Since 0.16.0.

Make a layer show in one frame what it shows in another, or show nothing there.

Capabilities: read, writeProject

A pixels or indexed layer has a picture (cel) per frame. This sets the cel of `layer` in `frame`: `from` copies what the layer shows in that frame (the two frames share one file or one set of rows), `clear: true` shows nothing. Use it to reuse a pose (a walk cycle's legs) or hide a layer in some frames. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","layer":"legs","frame":4,"from":0}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | A pixels or indexed layer: its name or an index path like "1/0". |
| `frame` | integer | yes | The frame whose cel changes. |
| `from` | integer | no | Show what the layer shows in this frame. |
| `clear` | boolean | no | true: the layer shows nothing in `frame`. Not with `from`. |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.frame.move` (modifies state)

Since 0.16.0.

Move a frame to another place in the animation; tags follow their frames.

Capabilities: read, writeProject

Takes frame `frame` out and puts it back so that it is frame `to` (the frames in between shift by one), on every layer, with its duration. A tag keeps its frames; when the move leaves them not in one run, the tag covers the run from the first to the last and a warning says so. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","frame":3,"to":0}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `frame` | integer | yes | The frame to move. |
| `to` | integer | yes | The place it ends up at. |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.frame.remove` (modifies state)

Since 0.16.0.

Remove one frame of an animated image document; later frames and tags move down.

Capabilities: read, writeProject

Deletes frame `frame` from every layer and from `frames`. Tags after it move down; a tag that held the frame shrinks (a tag that was only that frame is removed, with a warning). The last frame cannot be removed; when one frame is left and there are no tags the document is a plain still image again. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","frame":2}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `frame` | integer | yes | The frame to remove (0 = the first). |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.frame.set` (modifies state)

Since 0.16.0.

Set how long frames show, in milliseconds.

Capabilities: read, writeProject

`frame` is one frame number, a range [first, last] (inclusive) or "all"; `duration` is the milliseconds each of them shows (1..60000). A clip of the baked sheet plays at one speed: tags whose frames have different durations get extra cells that spell the timing out (the bake warns when a duration cannot be kept exactly). Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","frame":"all","duration":80}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `frame` | any | yes | A frame number, a range [first, last] or "all". |
| `duration` | integer | yes | Milliseconds each of those frames shows (100 = 10 frames per second). |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.frame.sheet` (modifies state)

Since 0.16.0.

Choose how many frames the baked sprite sheet has per row.

Capabilities: read, writeProject

The bake of an animated document is a sprite sheet. `columns` sets the frames (cells) per row; null goes back to the automatic grid (about square). The cells are all the size of the canvas. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","columns":8}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `columns` | any | yes | Cells per row (1..1024), or null for the automatic grid. |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.generate_layer` (modifies state)

Since 0.16.0.

Generate a picture with the image provider and add it to an image document as a `provider` layer, optionally masked by a selection.

Capabilities: read, state, writeProject, network, process, spend

Draws `prompt` with the image provider and adds the picture as a `provider` layer: the whole canvas by default, or `size` {width,height} at `placement` ("center" when a size is given, "fill", or {x,y}). `selection` (a stored selection, "all", or an inline image.select object) masks the layer so it shows only there. The layer carries the provider's provenance and is recorded in assets.json; the baked picture counts as AI-made. `transparent` asks for a transparent background (sprites, props). In a document with a palette the result is reduced to it. Any image provider works (openai, fake, asset-command); without one the error says how to configure it (docs/AI_PROVIDERS.md) and the offline route with exact commands. The call is synchronous and costs what the provider charges for one image: `dryRun` shows what would be sent and the estimate. COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

 COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored. A provider layer is never regenerated by itself. Example: {"path":"assets/art/hero.image.json","prompt":"a brass key, side view","size":{"width":64,"height":64},"placement":{"x":10,"y":4},"transparent":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `prompt` | string | yes | What to draw. |
| `name` | string | no | Name of the new layer (distinct). Default: inpaint / generated, then numbered. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to images (a name from ai.providers, e.g. "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}); recorded in the layer's provenance. Others ignore it with a warning. |
| `references` | array | no | Project-relative images the result should follow, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references). false skips it for this call. Default true. |
| `quantize` | boolean | no | Reduce the picture to the document's palette. Default: true when the document has a palette (an indexed document), else false. |
| `dryRun` | boolean | no | Only check the call and return what would be sent and what it may cost. Sends nothing, writes nothing. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; the fake provider and local programs never need it. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |
| `bake` | boolean | no | Also draw the PNG of the document (default true). Default true. |
| `selection` | any | no | Show the layer only inside this selection: a stored name (image.select), "all", or an inline object with the arguments of image.select. |
| `selectionName` | string | no | Name an inline selection is stored under (default "inpaint"). |
| `size` | object | no | Size of the picture in pixels, {"width":..,"height":..} (8 to 4096). Default: the canvas. |
| `placement` | any | no | Where it goes: "fill" (the canvas), "center" (default with a size), or {"x":..,"y":..} for the top-left corner. |
| `transparent` | boolean | no | Ask for a transparent background. Default false. |

## `image.info`

Since 0.16.0.

Describe a layered image document: its layers as a tree with index paths, sizes, bake status, the files it reads and its stored selections.

Capabilities: read

Reads the document at `path` and returns {document, width, height, background, valid, problems?, palette?: {source, colors, ramps} (when it has one: image.palette lists it), layers: [{index, pointer, name, kind, visible, opacity, blend, x, y, size?, source?, masks?, adjustments?, effects?, children?}], inputs, bake: {state, path, reason}, selections, $image}. `index` is the index path other image.* commands take in `layer` ("1/0"); names work too. `bake.state` is fresh, missing, stale, unrecorded or broken. `$image` is the baked PNG when it exists. An animated document (docs.read IMAGES, "Frames and tags") also has `animation`: {frameCount, totalMs, frames: [{frame, duration, tags?}], tags, sheet (the cell grid and clips the bake will write), sheetWarnings?}; a layer with cels lists `celFrames`, the frames where it changes. Read-only. Example: {"path":"assets/art/hero.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative. Path the command reads. |

## `image.inpaint` (modifies state)

Since 0.16.0.

Repaint the selected part of an image document with the image provider and add the result as a masked `provider` layer.

Capabilities: read, state, writeProject, network, process, spend

Sends the picture of the document (its composite, or `layer` alone, at `frame`) and the selection as the mask to an image provider that can inpaint, and adds what it paints as a new `provider` layer over the whole canvas whose mask is the selection (with the selection's feather), so the rest of the picture is untouched and the layer can be hidden, moved or removed. `selection` is the name of a stored selection (image.select; "all" is the whole canvas) or an object with the arguments of image.select (stored as `selectionName`, default "inpaint"). COST: the result carries estimatedCostUsd (an estimate, not an invoice). A call estimated above limits.askAboveUsd returns {needsApproval:true, plan:{...}}: tell the user what, how many, which provider and the estimate, and ask; only when the user says yes, call again with approved:true. An AI must never set approved:true on its own.

The layer carries the provider's provenance (provider, model, prompt, seed, references, license) and is recorded in assets.json; the baked picture counts as AI-made. In a document with a palette the result is reduced to it (pixel_dominant_downscale: palette colours only, no blends). A picture smaller than 512 px is magnified by whole pixels before it is sent, and the answer is resized back. Providers that can inpaint: the built-in openai (OPENAI_API_KEY), fake (placeholder pattern, free, offline) and asset-command providers whose argv has {input} and {mask}. Without one the error says how to configure it (docs/AI_PROVIDERS.md) and the offline route with exact commands. The call is synchronous and costs what the provider charges for one image: `dryRun` shows what would be sent and the estimate. COST: the result carries estimatedCostUsd (an ESTIMATE from the provider's assetPricing, not an invoice; null when the price is unknown; 0 for the fake provider and local programs). Before the provider is called the call is checked against the project's limits.maxAssetCostUsd (per run, per day) and refused with a teaching error when it would pass one. A call estimated above limits.askAboveUsd (default $0.50), or small calls that add up above it since the user last said yes, is NOT made: it returns {needsApproval:true, plan:{...}}. Tell the user what will be made, how many, with which provider and the estimate, and ask. Only when the user says yes, call again with the same arguments and approved:true. An AI must never set approved:true on its own, and never raise a limit itself. In the editor the user answers a card (Approve, Approve all for this run, Cancel) and the call just continues; there the approved argument is ignored. A provider layer is never regenerated by itself: call this again for another try. Example: {"path":"assets/art/hero.image.json","selection":"sky","prompt":"a stormy sky with a red moon","seed":7}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `prompt` | string | yes | What to draw. |
| `name` | string | no | Name of the new layer (distinct). Default: inpaint / generated, then numbered. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to images (a name from ai.providers, e.g. "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}); recorded in the layer's provenance. Others ignore it with a warning. |
| `references` | array | no | Project-relative images the result should follow, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references). false skips it for this call. Default true. |
| `quantize` | boolean | no | Reduce the picture to the document's palette. Default: true when the document has a palette (an indexed document), else false. |
| `dryRun` | boolean | no | Only check the call and return what would be sent and what it may cost. Sends nothing, writes nothing. Default false. |
| `approved` | boolean | no | The USER said yes to this paid call, after a needsApproval answer showed them the plan and the estimate. Never set it unless the user approved this call in this conversation; the fake provider and local programs never need it. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |
| `bake` | boolean | no | Also draw the PNG of the document (default true). Default true. |
| `selection` | any | yes | The part to repaint: the name of a stored selection (image.select), "all", or an object with the arguments of image.select (by, x, y, width, height, color, ...). |
| `selectionName` | string | no | Name an inline selection is stored under (default "inpaint"). |
| `layer` | any | no | Send only this layer (name or index path) instead of the whole composite. |
| `frame` | integer | no | The frame of an animated document the picture is of (default 0). The new layer shows in every frame. |

## `image.layer.add` (modifies state)

Since 0.16.0.

Add a layer to an image document (at the top, or at an index, or inside a group) and bake the picture.

Capabilities: read, writeProject

Adds the `layer` object (its `kind` and fields as docs.read IMAGES describes) to the document at `path`: on top of the root list by default, at `index` (0 = the bottom) of the list, or inside the group `parent`. A layer without `name` gets one from its kind ("fill", "fill 2"); names must be distinct because they address layers. The document is checked completely (a problem names the JSON pointer, nothing is written) and baked. The result has the picture as `$image`, the changed `region`, and `layer` {index, pointer, name, kind} of the new layer. Example: {"path":"assets/art/hero.image.json","layer":{"kind":"text","text":"Hi","size":16,"x":4,"y":4}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | object | yes | The layer: {kind, name?, visible?, opacity?, blend?, x?, y?, clip?, masks?, ...fields of its kind}. |
| `parent` | any | no | A group (name or index path) to add the layer into. Default: the top level. |
| `index` | integer | no | Position in the list, 0 = the bottom. Default: the top. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.add_provider` (modifies state)

Since 0.16.0.

Add a PNG an image provider made to an image document as a `provider` layer, with its provenance and an optional mask from a stored selection.

Capabilities: read, writeProject

The second half of image.inpaint and image.generate_layer, and the way to put any provider picture into a document: `source` is a PNG of the project (already written, with its provenance in assets.json), `provenance` the record the layer carries (provider, model, prompt, seed, references, license, author, notes). `selection` (a stored selection, or "all") becomes a `pixels` mask of the layer, copied next to the PNG so later changes of the selection do not move it; the selection's feather is part of its coverage. The layer goes on top (or at `index` / inside the group `parent`) at (`x`, `y`). It never calls a provider. The document is checked completely and baked; the picture is AI-made from then on (docs.read IMAGES, "Baking"). Example: {"path":"assets/art/hero.image.json","source":"assets/art/hero.layers/sky.png","selection":"sky","provenance":{"provider":"openai","prompt":"a stormy sky"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `source` | string | yes | The PNG the provider made, project-relative. Path the command reads. |
| `provenance` | object | yes | How it was made: provider (required), model, prompt, seed, references, license, author, notes. |
| `name` | string | no | Layer name (distinct). Default: provider, provider 2, ... |
| `selection` | string | no | A stored selection (image.select) or "all": the layer shows only there. |
| `x` | integer | no | Canvas column of the layer's left edge (default 0). |
| `y` | integer | no | Canvas row of the layer's top edge (default 0). |
| `opacity` | number | no | Layer opacity (default 1). |
| `blend` | string | no | Blend mode (default normal). |
| `parent` | any | no | Group to put it in (name or index path). Default: the top level. |
| `index` | integer | no | Position in the list, 0 = the bottom. Default: the top. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.convert` (modifies state)

Since 0.16.0.

Turn a layer into an indexed pixel-art layer (quantized to the palette, optional dither) or an indexed layer back into a pixels layer.

Capabilities: read, writeProject

`to: "indexed"`: the layer, drawn alone with its masks, adjustments and effects, is cropped to what it shows and each visible pixel takes its nearest palette colour (OKLab by default, `space: "rgb"` for stored values) with an optional `dither` (none, bayer2, bayer4, bayer8, floydSteinberg, atkinson; ordered patterns line up with the canvas) at `strength` 0..1; pixels at least `alphaThreshold` (default 0.5) opaque are kept, the others become transparent; a pixel that already has a palette colour keeps it, so pixels -> indexed -> pixels loses nothing. The palette is the document's, else `palette` (written into the document), else the style palette. A layer made from an AI-made picture marks the new layer `ai: true`. Masks, adjustments and effects are drawn into the pixels. `to: "pixels"`: the indexed layer is written as a PNG (in <document>.layers/) and becomes a pixels layer, so blur, edit and paint work on it. Both directions keep the layer's name, visibility, opacity, blend and clip, and place it where it was. Result: the baked document, `layer`, `colorsUsed`, `region`, warnings and `$image` magnified with hard pixels. Example: {"path":"assets/art/hero.image.json","layer":"painted","to":"indexed","dither":"bayer4"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The layer to convert: its name or an index path like "1/0". |
| `to` | string ["indexed","pixels"] | yes | indexed: palette-locked pixel art. pixels: a PNG layer. |
| `palette` | any | no | to indexed: the palette to use when the document has none (a list of colours or "style"); it is written into the document. |
| `dither` | string ["none","bayer2","bayer4","bayer8","floydSteinberg","atkinson"] | no | to indexed: how colours between palette colours are mixed. Default "none". |
| `space` | string ["oklab","rgb"] | no | to indexed: how colour distance is measured. Default "oklab". |
| `strength` | number | no | to indexed: how strong the dither is. Default 1. |
| `alphaThreshold` | number | no | to indexed: pixels at least this opaque become palette colours, the rest transparent. Default 0.5. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.move` (modifies state)

Since 0.16.0.

Move a layer to another position in its list, or into another group (or back to the top level), and bake.

Capabilities: read, writeProject

`index` is the layer's position in its list afterwards (0 = the bottom, so a higher index is drawn over more layers); without it the layer goes to the top of the list. `parent` moves it into that group (a name or index path; "" is the top level). The layer keeps its own x, y: moving it between groups with different offsets moves it on the canvas. A layer cannot move into its own children. The result has the picture as `$image` and the changed `region`. Example: {"path":"assets/art/hero.image.json","layer":"glow","index":0}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `index` | integer | no | Position afterwards, 0 = the bottom. Default: the top. |
| `parent` | any | no | Group to move into (name or index path), or "" for the top level. Default: stay in the same list. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.remove` (modifies state)

Since 0.16.0.

Remove a layer (and the children of a group) from an image document and bake.

Capabilities: read, writeProject

Deletes the layer addressed by name or index path. Its PNG stays on disk. Warns when the layer above was clipped to it. The result has the picture as `$image`, the changed `region` and `removed` {index, pointer, name, kind}. Example: {"path":"assets/art/hero.image.json","layer":"1/0"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.set` (modifies state)

Since 0.16.0.

Change fields of one layer (name, visible, opacity, blend, x, y, clip, masks, adjustments, effects, its kind's fields) and bake.

Capabilities: read, writeProject

Merges `set` into the layer: a field you give replaces the old one (objects such as `gradient` merge key by key; arrays such as `masks` are replaced whole), null removes a field. The `kind` cannot change. The layer is addressed by name or index path; a wrong name gets a did-you-mean and the layer list. The document is checked completely before anything is written. The result has the picture as `$image` and the changed `region`. Example: {"path":"assets/art/hero.image.json","layer":"shadow","set":{"opacity":0.4,"blend":"multiply"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `set` | object | yes | The fields to change, e.g. {"opacity":0.5,"visible":false}. null removes a field. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.paint` (modifies state)

Since 0.16.0.

Paint round-brush strokes onto a pixels layer of an image document (deterministic stamping), creating the layer's PNG when asked.

Capabilities: read, writeProject

Each stroke {points [[x,y],...], size, color, hardness?, opacity?, erase?, spacing?} stamps a round brush of diameter `size` along the polyline: one stamp at the first point, then one every `spacing` pixels (default a fifth of the size, at least 1) of arc length, and one at the last point. A pixel gets the largest coverage any stamp of the stroke gives it, so a stroke does not darken where it crosses itself; `opacity` then scales the whole stroke, `hardness` 1 is a hard edge (half a pixel anti-aliased) and lower values fade from hardness*radius to the edge. `erase: true` lowers the alpha instead of painting. Strokes apply in order and the same input always gives the same pixels (no randomness, no pressure). `layer` is a name or an index path; an unknown name with `create: true` makes a new empty pixels layer at the top of the document. A non-pixel layer is rasterized first, as in image.edit (a warning says so). `selection` limits the painting to a stored selection. Coordinates are canvas pixels; the layer grows to hold what is painted (a layer with masks keeps its box). Result: the baked document, `region`, `changed`, `stamps` and the picture as `$image`.

Example: {"path":"assets/art/hero.image.json","layer":"paint","create":true,"strokes":[{"points":[[4,4],[40,20]],"size":3,"color":"#ff0000"}]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to paint on: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The layer to paint on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create an empty pixels layer with it at the top. Default false. |
| `selection` | string | no | A stored selection (image.select) that limits where the strokes paint. |
| `strokes` | array | yes | The strokes, painted in order. |
| `bake` | boolean | no | Bake the document to its PNG after painting. Default true. |
| `frame` | integer | no | Which frame of an animated document to paint on (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.palette` (modifies state)

Since 0.16.0.

Show or change the palette and the colour ramps that indexed pixel-art layers of an image document are locked to.

Capabilities: read, writeProject

Without `palette` and `ramps` it only reads: every colour with its index, the character that stands for it in the layers' rows, name, #rrggbb, how many pixels use it, its ramp, and the colour one step darker (`shade`) and lighter (`light`); the palette is the document's `palette`, or the style palette of assets.json when the document has none. With `palette` (a list of colours, each "#rrggbb" or {name, color}, at most 81, all different; or "style") and/or `ramps` (lists of palette colours from the darkest to the lightest, each colour in one ramp; null removes) it rewrites them and bakes. Pixels keep their INDEX, so replacing the palette recolours the layers: append colours to keep the old ones. Without a declared ramp a colour's shade is the palette colour with lower lightness nearest to it in OKLab. Example: {"path":"assets/art/hero.image.json","palette":["#1a1c2c",{"name":"skin","color":"#e0a070"},{"name":"skin-dark","color":"#b06a40"}],"ramps":[["skin-dark","skin"]]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `palette` | any | no | New palette: "style" or a list of colours, each "#rrggbb" or {"name", "color"}; null removes the document's palette (the style palette applies). Omit to only read. |
| `ramps` | any | no | New ramps: [[colour, colour, ...], ...] darkest first, colours by index, name or "#rrggbb"; null removes them. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.palette.move` (modifies state)

Since 0.16.0.

Move one colour of an image document's palette to another position; the pixels follow it, so the picture does not change.

Capabilities: read, writeProject

Reorders the palette of the document (the colours of its indexed layers, cels and tileset parts keep looking the same: the index characters of the rows are rewritten) and the ramps that name the colour. `from` and `to` are palette colours (index, name or #rrggbb); the colour ends at the position of `to` and the colours between shift by one. A document with no `palette` gets the style palette copied into it. Result: the baked document, the new `palette` report and `moved`. Example: {"path":"assets/art/hero.image.json","from":"skin","to":0}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `from` | any | yes | The colour to move: its index, name or #rrggbb. |
| `to` | any | yes | The colour whose position it takes (index, name or #rrggbb); an index is where it ends up. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.palette.remove` (modifies state)

Since 0.16.0.

Remove one colour from an image document's palette; its pixels become another colour or transparent.

Capabilities: read, writeProject

Takes the colour `index` (index, name or #rrggbb) out of the palette; the colours after it shift down and the rows of every indexed layer, cel and tileset part are rewritten to match, so the other pixels do not change. Pixels that used the removed colour take the colour `replaceWith`, or become transparent when it is left out (a warning counts them). Ramps lose the colour. The palette keeps at least one colour. Result: the baked document, the new `palette` report and `removed`. Example: {"path":"assets/art/hero.image.json","index":"skin-dark","replaceWith":"skin"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `index` | any | yes | The colour to remove: its index, name or #rrggbb. |
| `replaceWith` | any | no | The palette colour its pixels take (index, name or #rrggbb). Left out: they become transparent. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.pixel` (modifies state)

Since 0.16.0.

Write exact pixels (a list, runs or a text stamp) onto an indexed pixel-art layer by palette colour; no anti-aliasing.

Capabilities: read, writeProject

Draws on an INDEXED layer (kind "indexed": the pixels are palette indices; docs.read IMAGES, "Pixel art"). `layer` is its name or index path; an unknown name with `create: true` makes a new blank indexed layer (canvas-sized, on top). Coordinates are canvas pixels (the layer's own offset and its groups' are accounted for); pixels outside the layer are dropped and counted in a warning. Three forms, applied in this order: `pixels` [[x, y, colour], ...]; `runs` [[x, y, length, colour], ...] (horizontal, to the right); `stamp` {x, y, rows: ["..11..", ".1221."], clear?} (text rows in the document's own characters: '.' is transparent and leaves the pixel alone unless `clear` is true). A colour is a palette index, name or colour; a colour not in the palette is an error with the nearest one. {"step": -1} shades the pixel one step along its colour ramp (see image.palette). When the document has no `palette` yet, the style palette is copied into it. Result: the baked document, `region` {x,y,width,height} of the changed pixels, `pixelsSet`, `changed`, and `$image` = the picture magnified with hard pixels (`previewScale`, default as large as fits 512 pixels).

Example: {"path":"assets/art/hero.image.json","layer":"sprite","create":true,"pixels":[[3,4,"skin"],[4,4,2]],"runs":[[2,6,5,"outline"]]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to draw on: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to draw on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create a blank indexed layer with it at the top. Default false. |
| `pixels` | array | no | [[x, y, colour], ...]: single pixels. A palette colour: its index (3), its name ("skin"), its single index character ("3"), or a colour that IS in the palette ("#e0a070"). null, "." or "transparent" erases. {"step": -1} is one shade darker than what is in the pixel (+1 lighter); {"color": "skin", "step": 1} is the colour one step lighter than skin. A colour outside the palette is an error that names the nearest palette colour. |
| `runs` | array | no | [[x, y, length, colour], ...]: horizontal runs of one colour starting at (x, y) going right. |
| `stamp` | object | no | A little picture in text rows placed at (x, y). |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `frame` | integer | no | Which frame of an animated document to draw on (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.cleanup` (modifies state)

Since 0.16.0.

Clean an indexed layer: orphan pixels, doubles at line bends and uneven steps on nearly straight lines; reports what changed.

Capabilities: read, writeProject

Three passes (`passes`, default all, in this order). orphans: a pixel with no neighbour of its own colour takes the commonest opaque colour around it, or disappears when only transparency is around (`connectivity` 8 default counts diagonal neighbours, `holes` also fills single transparent holes inside colour). doubles: the corner pixel of a one-pixel line where it bends in an L (two pixels thick at the bend) is removed so the line is one pixel wide everywhere; the right-angled corners of shapes are left alone. jaggies: a one-pixel line that is nearly straight (never more than `tolerance` pixels, default 1, from the straight line between its ends) but has uneven steps (3,3,1,3) is redrawn evenly between its ends, when the pixels it needs are free. `keep` lists palette colours never touched (a one-pixel highlight on purpose). A single-pixel highlight or eye dot is an orphan to this command: name its colour in `keep`. Frames: `frame` or `frames`. Result: as image.pixel, plus per frame `orphans`, `doubles`, `jaggies` (pixels changed by each pass) and `changedPixels` ([x, y] on the canvas, the first 100).

 Example: {"path":"assets/art/hero.image.json","layer":"sprite","frames":"all","keep":["shine"]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `passes` | array | no | Which passes to run (default all three). |
| `holes` | boolean | no | orphans: also fill a single transparent pixel enclosed by colour. Default false. |
| `connectivity` | integer [4,8] | no | orphans: 8 counts a diagonal neighbour of the same colour as connected, 4 only edge neighbours. Default 8. |
| `tolerance` | number | no | jaggies: the most a line may stray from the straight line between its ends to be redrawn evenly. Default 1. |
| `keep` | array | no | Palette colours the clean-up never changes. |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.dither` (modifies state)

Since 0.16.0.

Fill a region of an indexed layer with a dithered blend of palette colours (Bayer or checker), constant or as a gradient along a direction.

Capabilities: read, writeProject

Writes into the region (`selection`, and/or `rect`, else the whole layer box; transparent pixels too unless `onlyFilled`) a blend of palette colours made of pixels of exactly those colours, arranged by an ordered pattern. `colors` are 2 or more palette colours (or `ramp`: any colour of a declared ramp uses the whole ramp). Either `level` 0..1, the share of the second colour (bayer2 has 5 steps, bayer4 17, bayer8 65; checker alternates the two between a quarter and three quarters), or `gradient` {from [x,y], to [x,y]} in canvas pixels: the first colour at `from`, the last at `to`, the colours between spaced evenly and dithered into each other (with `ramp` the gradient runs from the lightest colour to the darkest). The patterns line up with the canvas, not with the layer, so two layers dithered alike match. Frames: `frame` or `frames`.

 Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing. Example: {"path":"assets/art/sky.image.json","layer":"sky","colors":["sky-light","sky","sky-dark"],"gradient":{"from":[0,0],"to":[0,31]},"pattern":"bayer4"} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `colors` | array | no | Two or more palette colours (index, name, single character or #rrggbb in the palette). With `level` the first two are blended. |
| `ramp` | any | no | Any palette colour of a declared ramp: use that whole ramp as the colours (dark to light; a gradient runs light to dark). |
| `pattern` | string ["checker","bayer2","bayer4","bayer8"] | no | The ordered pattern that decides which pixels take the second colour. Default "bayer4". |
| `level` | number | no | A constant blend: the share of the second colour. Give this or `gradient`. |
| `gradient` | object | no | A blend along a direction: {from: [x, y], to: [x, y]} canvas pixels. Give this or `level`. |
| `onlyFilled` | boolean | no | Only change pixels that already have a colour (leave transparent ones transparent). Default false. |
| `rect` | object | no | Limit the region to a box {x, y, width, height} in canvas pixels (with `selection`, the part in both). |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.outline` (modifies state)

Since 0.16.0.

Outline an indexed pixel-art layer by palette colour: inside or outside, 4- or 8-connected, flat, darkest of the ramp, or selective (sel-out).

Capabilities: read, writeProject

Outlines the shape of an INDEXED layer (everything that is not transparent). `side`: "outer" (default) puts the outline on the transparent pixels next to the shape, "inner" on the shape's own edge pixels. `connectivity` 4 (default) is a thin outline whose corners stay open, 8 closes the corners. `mode`: "flat" paints `color` (the default when `color` is given); "darkest" (default without `color`) uses, for each outline pixel, the darkest colour of the ramp of the fill colour it touches (a colour in no declared ramp: the darkest palette colour derived from it, see image.palette); "selective" is sel-out: the outline pixel takes its fill colour `shade` steps darker (default 2) along the ramp, and on the side that faces the light `litShade` steps (default shade - 1), so the outline is lighter where the light hits. The light is `light` or style.lightDirection; without one every pixel is `shade` steps darker. With `selection` only outline pixels inside it are written (the shape is still read from the whole layer). Frames: `frame` or `frames`. Only indexed layers: pixel art is palette-exact; a pixels layer must be converted first.

 Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing. Example: {"path":"assets/art/hero.image.json","layer":"sprite","mode":"selective","light":"upper-left"} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `side` | string ["outer","inner"] | no | outer: on the transparent pixels around the shape. inner: on the shape's own edge pixels. Default "outer". |
| `mode` | string ["flat","darkest","selective"] | no | flat: one palette colour (`color`). darkest: the darkest of the ramp of the fill colour it touches. selective: sel-out, the fill colour a few steps darker, lighter on the lit side. Default flat with `color`, else darkest. |
| `color` | any | no | mode flat: the palette colour of the outline (index, name, single character or #rrggbb that is in the palette). |
| `connectivity` | integer [4,8] | no | 4: pixels touching by an edge count as next to the shape; 8: corners too (a thicker outline with closed corners). Default 4. |
| `shade` | integer | no | mode selective: steps darker than the fill colour (on the shadow side). Default 2. |
| `litShade` | integer | no | mode selective: steps darker on the side facing the light (default shade - 1, at least 1). |
| `light` | any | no | The direction TOWARDS the light: degrees counter-clockwise from the right (135 = upper-left, 90 = above), a name (upper-left, top, ...) or "style". Default: style.lightDirection of assets.json. |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.rotate` (modifies state)

Since 0.16.0.

Rotate the pixels of an indexed layer (or a selection) by any angle, RotSprite-style: no new colours, no blur.

Capabilities: read, writeProject

Rotates the visible pixels of the layer (or of the `selection`) `angle` degrees clockwise about `pivot` (canvas pixels; default the centre of those pixels) and draws them back; the layer's box grows to hold the result. A multiple of 90 degrees is an exact turn of the pixels. Otherwise `method` "rotsprite" (default) enlarges the picture 8 times with Scale2x (EPX) three times, rotates by nearest sample and takes the commonest colour of each 8x8 block back down, which keeps edges and thin lines far better than a plain nearest rotation ("nearest", fast and blocky); the pixels to rotate are at most 256 x 256 for rotsprite. Only palette colours appear. Frames: `frame` or `frames`.

 Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing. Example: {"path":"assets/art/hero.image.json","layer":"sword","angle":30,"pivot":[12,20]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `angle` | number | yes | Degrees, clockwise (negative: counter-clockwise). |
| `method` | string ["rotsprite","nearest"] | no | rotsprite: x8 with Scale2x, rotate, most-common-colour downscale. nearest: plain nearest-neighbour rotation. Default "rotsprite". |
| `pivot` | array | no | [x, y] canvas pixels the rotation turns about (the pixel (x, y) spans x to x + 1). Default: the centre of the pixels. |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.scale` (modifies state)

Since 0.16.0.

Scale the pixels of an indexed layer (or a selection) cleanly: whole factors repeat pixels, reductions take the commonest colour, scale2x/scale3x round corners; no blending.

Capabilities: read, writeProject

Scales the visible pixels of the layer (or of the `selection`) by `factor` (a number, or [horizontal, vertical]) or to `size` {width, height} (one of them keeps the proportions), around `pivot` (canvas pixels, default the centre of the pixels); the layer's box grows to hold the result. `method`: "nearest" repeats the pixel under each new pixel's centre (a whole factor makes exact blocks); "mode" gives each new pixel the commonest colour of the old pixels it covers (the clean way to shrink; opaque wins a tie); "scale2x" / "scale3x" are the EPX-style enlargers by exactly 2 / 3 that round off corners instead of copying them; "auto" (default) is nearest when enlarging and mode when shrinking. A non-integer enlargement works but repeats some rows and columns and not others, and a warning says so. Only palette colours appear. Frames: `frame` or `frames`.

 Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing. Example: {"path":"assets/art/hero.image.json","layer":"sprite","factor":2,"method":"scale2x"} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `factor` | any | no | A multiplier (2 doubles, 0.5 halves) or [horizontal, vertical]. Give this or `size`. |
| `size` | object | no | The new size {width, height} in pixels of the scaled pixels; give one to keep the proportions. Give this or `factor`. |
| `method` | string ["auto","nearest","mode","scale2x","scale3x"] | no | auto: nearest to enlarge, mode to shrink. scale2x / scale3x: exactly x2 / x3 with rounded corners. Default "auto". |
| `pivot` | array | no | [x, y] canvas pixels that stay in place. Default: the centre of the pixels. |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.pixel.shade` (modifies state)

Since 0.16.0.

Shade an indexed pixel-art shape from a light direction: shadow and highlight bands stepping along the colour ramps, optional dithered transition.

Capabilities: read, writeProject

Shades the shape (the non-transparent pixels of the layer, or of the `selection`) as if lit from `light`: along the light's axis, `shadowLevels` bands of `shadowWidth` pixels at the edge facing away from the light step the colour darker (the outermost the most, the inner bands one step less), and `highlightLevels` bands of `highlightWidth` pixels at the edge facing the light step it lighter. A step follows the colour's declared ramp, or the nearest darker / lighter palette colour (image.palette). Shadow wins where both reach a pixel. `dither` N makes the first N pixels of each band after the first a Bayer-ordered mix with the stronger band before it, so the transition is not a hard line. The light is `light` or style.lightDirection (an error teaches both when neither exists). Run it on a flat-coloured shape (a body, a ball, a hat): shading is relative to what is in the pixel, so shading twice shades twice. Frames: `frame` or `frames`.

 Result as image.pixel: the baked document, `region` {x,y,width,height} of the changed pixels (of the first frame), `changed`, `pixelsChanged`, `layer` and `$image` = the picture magnified with hard pixels (`previewScale`). Every pixel stays a palette colour: nothing is blended and there is no anti-aliasing. Example: {"path":"assets/art/hero.image.json","layer":"sprite","selection":"body","light":"upper-left","shadowWidth":2,"dither":1} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame to change: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | yes | The indexed layer to change: its name or an index path like "1/0". (A pixels layer: image.layer.convert it first, or image.to_pixel_art.) |
| `selection` | string | no | A stored selection (image.select): only its pixels (coverage 128 or more) may change. Default: the whole layer. |
| `frames` | any | no | Several frames at once: "all", a list [0, 2, 3] or {"from": 0, "to": 3}. The same change is made on each frame's cel; the result lists the pixels changed per frame (`perFrame`) and the picture shown is the first of them. Not with `frame`. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `light` | any | no | The direction TOWARDS the light: degrees counter-clockwise from the right (135 = upper-left, 90 = above), a name (upper-left, top, ...) or "style". Default: style.lightDirection of assets.json. |
| `shadowWidth` | integer | no | Pixels per shadow band, measured along the light's direction. Default 2. |
| `shadowLevels` | integer | no | Shadow bands (steps darker at the edge). 0 = no shadow. Default 1. |
| `highlightWidth` | integer | no | Pixels per highlight band. Default 1. |
| `highlightLevels` | integer | no | Highlight bands (steps lighter at the edge). 0 = no highlight. Default 1. |
| `dither` | integer | no | Pixels of Bayer-dithered transition at the inner edge of each band (at most the band width). 0 or false = hard bands; true = 1. Default 0. |
| `frame` | integer | no | Which frame of an animated document to change (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `image.resize` (modifies state)

Since 0.23.0.

Change the canvas size of an image document, moving or cropping every layer, frame and cel by an anchor, and bake.

Capabilities: read, writeProject

Sets the canvas to `width` x `height` (1..4096). `anchor` is the part of the old canvas that stays put (top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right; default center): with "top-left" a bigger canvas grows at the right and bottom, a smaller one is cropped there. An odd difference rounds down. Every top-level layer moves by the anchor's offset (groups take their children along). A fill, gradient or procedural layer with no size just covers the new size, unless it has `masks` (they are in the layer's own pixels): then it becomes a box of the old canvas size and moves, so its masks stay on the same pixels and it no longer covers the added area (a warning names it). Adjustment layers with masks move too. Pixels and picture layers keep their PNG; the text rows of indexed layers and cels are CUT to the new canvas (never padded: a big canvas costs nothing; over 64 MB of rows fails). Palette, ramps, frames, tags and sheet settings are kept; the bake takes the new cell size. `fill` (default transparent) paints the area a bigger canvas adds as a masked fill layer 'resize fill' at the bottom. Stored selections must be made again (a warning). One undo step. Example: {"path":"assets/art/heart.image.json","width":12,"height":12,"anchor":"top-left"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | yes | New canvas width in pixels. |
| `height` | integer | yes | New canvas height in pixels. |
| `anchor` | string ["top-left","top","top-right","left","center","right","bottom-left","bottom","bottom-right"] | no | The part of the old canvas that stays put; the canvas grows or is cropped on the opposite sides. Default "center". |
| `fill` | any | no | Colour of the area a bigger canvas adds: "#rrggbb", "#rrggbbaa", a CSS name or [r,g,b,a]. Default transparent. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.save` (modifies state)

Since 0.16.0.

Check an image document, write it to a *.image.json file and bake its PNG; nothing is written when the document has a problem.

Capabilities: read, writeProject

Validates `document` (the layered image document as JSON: canvas width and height, background, layers bottom first; see docs.read IMAGES), writes it to `path` (project-relative, ending in .image.json) as canonical JSON and bakes the PNG like image.bake (an animated document -- `frames`, `tags`, `cels` -- bakes a sprite sheet and its clips). A problem in the document is an error naming the JSON pointer (/layers/2/blend), what is wrong and how to fix it, and writes nothing. Example: {"path":"assets/art/sky.image.json","document":{"width":128,"height":128,"layers":[{"kind":"gradient","gradient":{"angle":0,"stops":[{"at":0,"color":"#102040"},{"at":1,"color":"#e08040"}]}},{"kind":"text","text":"Hi","size":32,"x":8,"y":8}]}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `document` | object | yes | The image document: {"width", "height", "background"?, "output"?, "layers": [...]}. See docs.read IMAGES for the layer kinds. |
| `bake` | boolean | no | Also draw the PNG. False only checks and writes the document. Default true. |

## `image.select` (modifies state)

Since 0.16.0.

Select part of an image document's canvas (by colour, alpha, rectangle, ellipse, polygon or a layer's shape) and store it by name for image.edit and image.paint.

Capabilities: read, writeProject

Builds a selection: a coverage (0..255) per canvas pixel. `by` picks how: color (pixels within `tolerance` 0..255 of `color`, or of the pixel at `at`; `contiguous: true` only the connected area around `at`), alpha (pixels whose alpha is at least `threshold`), rect or ellipse (x, y, width, height; anti-aliased), polygon (`points` [[x,y],...]), layer (the layer's shape: its alpha after its masks and effects, soft edges kept) or all. color and alpha read the flattened picture, or only `layer` when it is given. `then` reshapes the new selection with steps in order: [{"grow":2},{"shrink":1},{"feather":1.5},{"invert":true}] (pixels; grow and shrink use a round brush and make a hard edge; feather is a blur of sigma pixels/2). `mode` combines the result with the stored selection of the same `name`: replace (default), add, subtract or intersect. Without `by`, `then` reshapes the stored selection; `clear: true` deletes it.

PERSISTENCE: the selection is saved as a grey PNG of the canvas at .factoria/selections/<document path>/<name>.png (white = selected) and stays until replaced or cleared; later calls use it by name (the name "all" is the whole canvas without a file). Changing the canvas size makes old selections unusable (they say so). The result has `selected` (pixels), `coverage`, the bounding box as `region` {x,y,width,height} and the picture with the selection marked as `$image`. IN AN ANIMATION (frames, docs.read IMAGES "Frames and tags") color, alpha and layer selections read the picture of `frame` (default 0: the layer's cel for that frame, or the whole picture of that frame); the stored selection is one mask of the canvas per document and name, the same for every frame, so select on the frame you are working on. Example: {"path":"assets/art/hero.image.json","name":"cape","by":"color","at":[20,30],"contiguous":true,"tolerance":20,"then":[{"grow":1}]} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame the color, alpha and layer selections read: the selection reads the picture of that frame; the stored selection itself is the same for every frame.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command reads. |
| `name` | string | no | The selection's name (1-40 letters, digits, - or _). Reusing a name replaces it, or combines with it when mode is not replace. Default "selection". |
| `by` | string ["color","alpha","rect","ellipse","polygon","layer","all"] | no | How to select. Omit it to reshape the stored selection with `then`. |
| `mode` | string ["replace","add","subtract","intersect"] | no | How the new shape combines with the stored selection of the same name. Default "replace". |
| `then` | array | no | Steps applied to the new shape, in order: {"grow":px}, {"shrink":px}, {"feather":px}, {"invert":true}. |
| `clear` | boolean | no | Delete the stored selection `name`. Default false. |
| `color` | any | no | by color: the colour to select ("#rrggbb", a CSS name, [r,g,b,a]). |
| `at` | array | no | by color: [x, y] canvas pixel whose colour is taken when `color` is not given, and where a contiguous selection starts. |
| `tolerance` | number | no | by color: the largest difference of any channel (r, g, b, a; 0..255) that still matches. Default 16. |
| `contiguous` | boolean | no | by color: select only the connected area (4-neighbours) around `at`. Default false. |
| `threshold` | number | no | by alpha: the least alpha (0..255) that is selected. Default 1. |
| `layer` | any | no | by layer: the layer (name or index path). For color and alpha: read only this layer instead of the flattened picture. |
| `x` | number | no | rect / ellipse: left of the box, canvas pixels. |
| `y` | number | no | rect / ellipse: top of the box. |
| `width` | number | no | rect / ellipse: width of the box. |
| `height` | number | no | rect / ellipse: height of the box. |
| `points` | array | no | polygon: the corners [[x,y],...], at least three. |
| `frame` | integer | no | Which frame of an animated document the color, alpha and layer selections read (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |

## `image.tag.remove` (modifies state)

Since 0.16.0.

Remove a tag (and so its clip) from an image document.

Capabilities: read, writeProject

Deletes the tag `name`; the frames stay. The next bake drops its clip from the sheet entry. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","name":"walk"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `name` | string | yes | The tag to remove. |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.tag.set` (modifies state)

Since 0.16.0.

Name a run of frames (a tag); the bake makes a SpriteAnimator clip of it.

Capabilities: read, writeProject

Creates the tag `name`, or changes it when it exists (omitted fields keep their value): frames `from` to `to` (inclusive), played in `direction` (forward, reverse, pingpong), `repeat` times (0 = the clip loops; N plays N times and stops). The bake writes the clip into the sheet entry of assets.json under that name, so a game plays it with SpriteAnimator `clip` or entity.spriteAnimator.play(name) with no other step. SpriteAnimator plays contiguous cells at one speed, so a tag that is reverse, ping-pong, repeated or has frames of different durations gets extra cells after the frames that spell its order out (image.info shows the sheet with its cells and clips). Tags may overlap. A still image becomes a one-frame animation. Result: the baked document (a sprite sheet: `sheet` has the grid and the clips), `animation` {frameCount, totalMs, frames: [{frame, duration}], tags} and next steps; `removedFiles` lists the cel pictures (PNGs in `<document>.layers/`) that nothing read any more and were deleted in the same save; docs.read IMAGES, \"Frames and tags\". Example: {"path":"assets/art/hero.image.json","name":"walk","from":0,"to":3}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `name` | string | yes | The tag's name; also the clip name. Unique in the document. |
| `from` | integer | no | First frame (required for a new tag). |
| `to` | integer | no | Last frame, inclusive (required for a new tag). |
| `direction` | string ["forward","reverse","pingpong"] | no | Play order (default forward). pingpong goes to the end and back without repeating the end frames. |
| `repeat` | integer | no | How many times it plays; 0 (default) loops for ever. |
| `bake` | boolean | no | Also bake the document to its sprite sheet (default true). False only writes the document. Default true. |

## `image.tile.check`

Since 0.16.0.

Check that a picture (or each tile of a sheet) repeats without a visible seam, with a preview of 3 x 3 copies.

Capabilities: read

Compares the pixels that touch when a tile repeats: its right column against its own left column and its bottom row against its top row, for every tile that is not empty. The tile is `tileWidth` x `tileHeight`, else the document's `tile`, else the whole canvas. `tolerance` (0 to 255) is how far apart two touching pixels may look: by default 0 for pixel art (a palette or style.pixelArt) and else 1.5 x the mean difference of neighbouring pixels inside the tiles, so a soft texture is not failed for its own gradient. Returns {seamless, tolerance, problems: [{tile, column, row, axis, sides, columns, rows (canvas coordinates, with the runs of mismatching pixels), mismatched, worst, mean, message}]} (the first 40), and the preview as `$image` and in `preview` (.factoria/previews/<document>.tilecheck.png): the tile 3 x 3 with red lines on the mismatching seam pixels. Reads the document as it is; for an autotile set use image.tileset.check. Example: {"path":"assets/art/ground.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Path the command reads. |
| `tileWidth` | integer | no | One tile's width; must divide the picture. Default: the document's tile, else the whole canvas. |
| `tileHeight` | integer | no | One tile's height. Default as tileWidth. |
| `tolerance` | integer | no | The largest difference between two touching pixels that still counts as matching. Default: automatic (0 for pixel art). |
| `scale` | integer | no | Magnification of the preview. Default: fits about 768 pixels. |
| `tile` | integer | no | Which tile of a sheet the preview shows (row-major, 0-based). Default: the first with a problem. |

## `image.tile.set` (modifies state)

Since 0.16.0.

Turn tile mode (wrap-around editing) on or off for an image document.

Capabilities: read, writeProject

Sets the `tile` key of the document at `path`. With tile mode on, the drawing commands (image.pixel, image.draw, image.paint, the pixel helpers outline / shade / dither / cleanup, image.edit move) wrap around the edges of a tile: what leaves the right edge comes back in on the left, so the edges keep matching while you draw. A shape wraps inside the tile that holds its first point (a pixel, the start of a line or run, the corner of a rectangle, the `at` of a fill, the first point of a stroke). Without `width` and `height` the whole canvas is one tile; with them the canvas is a sheet of tiles of that size (they must divide the canvas). `enabled` false turns it off. image.edit transform and the helpers rotate and scale do not wrap (they warn). Returns the tile grid and the picture. Example: {"path":"assets/art/ground.image.json"} or {"path":"assets/art/sheet.image.json","width":16,"height":16}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `enabled` | boolean | no | False turns tile mode off (removes `tile` from the document). Default true. |
| `width` | integer | no | One tile's width in pixels; must divide the canvas width. Default: the canvas width. |
| `height` | integer | no | One tile's height in pixels; must divide the canvas height. Default: the canvas height. |
| `bake` | boolean | no | Also draw the PNG (default true). Default true. |

## `image.tileset.build` (modifies state)

Since 0.16.0.

Make an autotile tileset (16 or 47 tiles) from a few parts (inside, edge, corner), bake the sheet and write the Tilemap rules.

Capabilities: read, writeProject

Makes the image document `path` (or adds the layer to an existing one) with a `tileset` layer that builds the whole set from parts: each part is one tile picture, a PNG (`source`), text `rows` of the document's palette, or one flat `color`; a list gives variants. Minimal parts: inside, edge, corner (+ innerCorner for blob47, + edgeLeft for tiles that are not square); image.tileset.info draws each one. Modes: basic16 (4 neighbours) and blob47 (8 neighbours, the common 47-tile set). `variations` 1 to 8 makes several pictures of every tile (the other variations pick variants of the parts by `seed`, the same seed always gives the same sheet). The canvas becomes the sheet (columns x rows of tiles), `tile` is set to the tile size, the PNG is baked, and the rules file (default <document>.terrains.json: the Tilemap.terrains entry with the exact tile of every neighbour combination) is written and recorded in assets.json. Example: {"path":"assets/art/ground.image.json","mode":"blob47","tileWidth":16,"tileHeight":16,"palette":["#1e4a14","#2d5a1e","#4a8a2c"],"parts":{"inside":{"rows":[...16 rows...]},"edge":{"rows":[...]},"corner":{"rows":[...]},"innerCorner":{"rows":[...]}}}

Run it again to update: keys you give override, `parts` merge by name (null removes one), nothing else changes, and the files are rewritten in place; assets.regenerate {"stale":true} does the same after a part PNG changed. Returns the bake result plus tileset {layer, mode, layout}, rules {path}, terrain (the rule) and tilemap {tileset, tileSize, columns, terrains} (what to put in the Tilemap).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Created when it does not exist. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | string | no | The tileset layer's name. Found and updated, or added. Default "tileset". |
| `mode` | string ["basic16","blob47"] | no | basic16: 4 neighbours, 16 tiles. blob47: 8 neighbours, 47 tiles. Default "blob47". |
| `tileWidth` | integer | no | One tile's width in pixels (even). Required for a new layer; with only one of the sizes the tile is square. |
| `tileHeight` | integer | no | One tile's height in pixels (even). |
| `parts` | object | no | {partName: picture \| [pictures]}; a picture is {source}, {rows} or {color}, or a PNG path. Merged into the layer's parts by name; null removes a part. Names: inside, edge, corner, innerCorner, edgeBottom, edgeLeft, edgeRight, cornerNE, cornerSW, cornerSE, innerCornerNE, innerCornerSW, innerCornerSE. |
| `columns` | integer | no | Tiles per row of the sheet. Default 4 for basic16, 8 for blob47. |
| `variations` | integer | no | Pictures per tile; the others pick variants of the parts by seed. Default 1. |
| `seed` | integer | no | Picks the variants of the tiles (and is stored in the rules, so painting picks the same variations). Default 0. |
| `terrain` | string | no | The terrain's name in the rules (paint with tilemap.paint_terrain {terrain}). Default: the layer name. |
| `rules` | string | no | Where the rules file goes. Default: <document>.terrains.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `writeRules` | boolean | no | False writes no rules file. Default true. |
| `palette` | array | no | The document's palette (colours) when parts use `rows`. |
| `ramps` | array | no | The document's colour ramps. |
| `description` | string | no | The document's description. |
| `output` | string | no | The PNG the document bakes to. Default: next to the document. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the rules file when it exists and is not this layer's. Default false. |
| `bake` | boolean | no | Also draw the PNG (default true). Default true. |

## `image.tileset.check`

Since 0.16.0.

Check an autotile tileset: every part is one tile big, and every pair of tiles that can touch in a map fits.

Capabilities: read

Reads the tileset layer of the document at `path`, reports every part that is missing, unreadable or the wrong size (with its JSON pointer), then builds the sheet and compares the sides of the tiles that stand side by side in a map: tile A east of tile B needs A to have an east neighbour and B a west one (and for blob47 the cells around the pair to agree), and likewise north-south. It also checks the joins INSIDE each tile, where two quadrants cut from different parts meet (corner next to edge, edge next to inside, inner corner next to edge): the two parts must show the same pixels on both sides of the middle line, within the tolerance; `tolerance` as in image.tile.check (automatic by default: 0 for pixel art). Returns {seamless, problems: [{axis, a, b (tile, slot, neighbours, sheet position), mismatched, worst, message}]} (axis "horizontal" / "vertical" for a seam between tiles, "centreColumn" / "centreRow" for a join inside tile a, with `half`, `parts` and `runs`) and the sheet magnified with red marks on the failing sides and on the middle line of a tile that does not join as `$image` (.factoria/previews/<document>.tilesetcheck.png). Example: {"path":"assets/art/ground.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Path the command reads. |
| `layer` | string | no | The tileset layer. Default: the only one. |
| `tolerance` | integer | no | The largest difference between two touching pixels that still counts as matching. Default: automatic (0 for pixel art). |
| `scale` | integer | no | Magnification of the preview. Default: fits about 768 pixels. |

## `image.tileset.info`

Since 0.16.0.

Explain the parts of an autotile tileset and list its tiles (slot, neighbours, position in the sheet).

Capabilities: read

Describes what image.tileset.build is made of: for the mode (basic16 or blob47), each part with a small drawing, which are required for the tile shape, how the quadrants and flips make the set, and the table of slots with their neighbour masks. With `path` (and `layer`) also the layout of that tileset layer and every tile with its sheet position and neighbours. Example: {"mode":"blob47"} or {"path":"assets/art/ground.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Optional: describe its tileset layer. Path the command reads. |
| `layer` | string | no | The tileset layer. Default: the only one. |
| `mode` | string ["basic16","blob47"] | no | Without `path`: which set to describe. Default blob47. |
| `squareTile` | boolean | no | Without `path`: false for a tile that is not square (it also needs edgeLeft). Default true. |

## `image.tileset.rules` (modifies state)

Since 0.16.0.

Write the Tilemap autotile rules file of a tileset layer (the recipe command that keeps it current).

Capabilities: read, writeProject

Writes the rules file of the tileset layer: {"format":"factoria.terrains/1","terrains":[{name, mode, seed, tiles}]}, with the tile of every neighbour combination (variations as lists). image.tileset.build already does this; this command is what assets.json records as the recipe of the rules file, so assets.regenerate keeps it current when the document changes. Read by tilemap.set_terrains {id, path}. Refuses to replace a file that is not this layer's unless `overwrite`. Example: {"path":"assets/art/ground.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/ground.image.json'. Path the command reads. |
| `layer` | string | no | The tileset layer. Default: the only one. |
| `rules` | string | no | The rules file. Default: <document>.terrains.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace a file that is not this layer's rules. Default false. |

## `image.to_pixel_art` (modifies state)

Since 0.16.0.

Turn a painted, generated or imported picture (a layer or a PNG) into palette-exact pixel art: area-aware downscale, quantize, clean up, into an indexed layer.

Capabilities: read, writeProject

Takes `source` (a layer of the document of any kind: a pixels layer, a painted, generated or vector one, drawn alone with its masks and effects) or `png` (a PNG of the project), makes it `width` x `height` pixels (one keeps the proportions) or `pixelSize` source pixels per art pixel, and writes the result into the indexed layer `into` (created at the top, or replaced). `method`: "dominant" (default) turns every source pixel into its nearest palette colour (OKLab) first and gives each art pixel the commonest colour of the source pixels it covers, so edges stay crisp and no colour is a blend; "average" averages the covered area (a box filter with exact fractional edges, not bilinear) and then quantizes to the palette with the dither of image.layer.convert (`dither` none, bayer2/4/8, floydSteinberg, atkinson; `strength`; `space` oklab or rgb). Art pixels under `alphaThreshold` opaque (default 0.5) are transparent.

Then `orphans` (default true, but false with a `dither`, whose pixels would look stray) removes stray single pixels (image.pixel.cleanup) and `outline` (a palette colour, or "darkest" for the darkest of each fill colour's ramp) adds a 4-connected outer outline. The palette is the document's, else `palette` (written into the document), else the style palette. The art lands where the source's pixels were (a PNG: at 0, 0) unless `x` / `y` say otherwise. `frame` chooses the frame whose cel receives it. Result: as image.pixel plus `sourceSize`, `size`, `at`, `colorsUsed`, `orphansFixed`, `outlinePixels`. Example: {"path":"assets/art/hero.image.json","source":"painting","into":"sprite","width":32,"outline":"darkest"} Frames: in an animated document (docs.read IMAGES, "Frames and tags") `frame` (default 0) is the frame whose cel receives the pixel art: the layer's cel for that frame is changed and the other frames keep what they show; `onion` ghosts the neighbouring frames in the returned picture. A layer this command creates (`create: true`, or `image.edit` copy/cut) shows only in `frame` when you give it and in every frame when you do not. A cel picture the edit leaves unread is deleted in the same save and listed in `removedFiles`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `source` | any | no | The layer to convert: its name or an index path. Give this or `png`. |
| `png` | string | no | A PNG (or JPG, BMP, TGA) of the project to convert. Give this or `source`. Path the command reads. |
| `into` | string | yes | The name of the indexed layer that receives the pixel art: created at the top when it does not exist, replaced when it does. |
| `width` | integer | no | Width of the pixel art in pixels (alone: the height follows the proportions). |
| `height` | integer | no | Height of the pixel art in pixels. |
| `pixelSize` | integer | no | Source pixels per art pixel (4 turns 128 x 128 into 32 x 32). Instead of width / height. |
| `method` | string ["dominant","average"] | no | dominant: palette colour first, then the commonest in each area. average: area average, then quantize (with an optional dither). Default "dominant". |
| `palette` | any | no | The palette when the document has none (a list of colours or "style"); it is written into the document. |
| `dither` | string ["none","bayer2","bayer4","bayer8","floydSteinberg","atkinson"] | no | method average: how colours between palette colours are mixed. Default "none". |
| `strength` | number | no | method average: how strong the dither is. Default 1. |
| `space` | string ["oklab","rgb"] | no | method average: how colour distance is measured. Default "oklab". |
| `alphaThreshold` | number | no | Art pixels at least this opaque become palette colours, the rest transparent. Default 0.5. |
| `orphans` | boolean | no | Remove single stray pixels afterwards. Default true, false when `dither` is set (a dither is made of single pixels). |
| `outline` | any | no | Add an outer outline: a palette colour, or "darkest" (the darkest of the ramp of the colour it touches). |
| `x` | integer | no | Canvas column of the left edge of the result (default: where the source's pixels start; a PNG: 0). |
| `y` | integer | no | Canvas row of the top edge of the result. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |
| `frame` | integer | no | Which frame of an animated document whose cel receives the pixel art (0 = the first; default 0). A document with one frame has only frame 0. In a frame after the first the layer's cel is copied on write: the other frames keep what they show. |
| `onion` | any | no | Preview only: ghost the neighbouring frames, tinted, under the frame in the returned picture. true, or {"before":1,"after":1,"opacity":0.4,"beforeColor":"#ff4040","afterColor":"#4080ff","loop":false}. Frames before are tinted red, frames after blue; the second frame away is half as strong, the third a third. Does not change the document or the bake. |

## `model.bake` (modifies state)

Since 0.16.0.

Build model documents into .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.

Capabilities: read, writeProject

Without `path` this bakes every *.model.json of the project whose .glb is missing or out of date (its document or a file it reads changed: the recipe's hashes), like audio.bake. With `path` it bakes that document. The .glb goes to `output.path` of the document, else next to it as <name>.glb, written the way mesh.save writes a mesh (one primitive per part and material, the part name in the primitive's extras, vertex colours as COLOR_0); the same document gives the same bytes. assets.json records provenance (a CC0 license, or the licenses of the fonts and textures it read) and the recipe, so assets.regenerate and project.validate know when it is stale. A file that nothing baked is never replaced unless overwrite is true. `factoria export` bakes the stale documents first. Example: {} or {"path":"assets/models/door.model.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Bake only this document (project-relative, ending in .model.json). Leave out for every document. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `force` | boolean | no | Bake documents that are fresh too. Default false. |
| `dryRun` | boolean | no | List what would be baked and why, and write nothing. Default false. |
| `overwrite` | boolean | no | Replace a file at the output that no model document baked. Default false. |

## `model.bake_maps` (modifies state)

Since 0.16.0.

Bake a model's ambient occlusion, curvature and thickness maps in its UV atlas and measure them (nothing is written): the masks that texturing wear is built from. Returns the maps as pictures.

Capabilities: read, state

Measures the maps that `texturing` wear and `ao` use, so you can choose thresholds before changing the document. ao: 1 (white) is open, lower is occluded by the rest of the model (rays up to `distance`, `samples` per texel); curvature: 0.5 grey is flat, lighter is a convex edge, darker a concave corner (sharp edges turn the surface by at least `edgeAngle` degrees and give a band `edgeWidth` metres wide); thickness: how far the inside of the shell is from the opposite surface up to `thicknessDistance`, darker is thin. All three are CPU and deterministic. The defaults are the document's texturing.maps (else samples 16, distance 15% and thicknessDistance 50% of the model's diagonal, edgeAngle 20, edgeWidth 3% of the diagonal). The atlas is the document's `uv` section (a model with none is unwrapped for the measurement; nothing is written). `size` defaults to texturing.size, else the uv texture size. The result has each map's mean, min, max and coverage over the covered texels, the texels covered and the share claimed by two pieces, and one picture with the maps side by side. To keep the maps as pictures next to the model add them to texturing.maps.write; to paint with them add wear entries (model.texture). Example: {"path":"assets/models/crate.model.json","maps":["ao","curvature"],"size":512}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command reads. |
| `maps` | array | no | The maps to bake; default all three. |
| `size` | integer | no | Side of the atlas in texels (16..4096); default texturing.size, else the uv section's texture size. |
| `samples` | integer | no | Rays per texel for ao and thickness (4..256); default texturing.maps.samples or 16. |
| `distance` | number | no | Metres an occluder may be away; 0 = 15% of the model's diagonal. |
| `thicknessDistance` | number | no | Metres the thickness is measured up to; 0 = 50% of the diagonal. |
| `edgeAngle` | number | no | Degrees an edge must turn the surface to count as sharp (1..179). |
| `edgeWidth` | number | no | Metres wide the band along a sharp edge is; 0 = 3% of the diagonal. |
| `picture` | boolean | no | Return the maps as one picture ($image). Default true. |

## `model.check`

Since 0.16.0.

Measure a model document's mesh for faults an artist finds by eye: scale, origin, flipped or inconsistent triangles, open and non-manifold edges, degenerate triangles, platform budgets. Each finding says where, what and how to fix.

Capabilities: read

Builds the document in memory and checks the mesh the game gets (the evaluated mesh, with the `gameReady` origin and merge applied). Findings, errors first: `inside_out` (a closed piece whose triangles all face inward), `inconsistent_winding` (neighbouring triangles disagree on the side that is out), `non_manifold` (an edge of more than two triangles), then warnings: `flipped_normals`, `open_edges` (holes: the model is not a closed solid), `degenerate` (triangles with no area), `scale` (the height differs from `expectedHeight` by more than `tolerance`, or, with no expectation, the largest side is under 2 cm or over 100 m: probably authored in the wrong unit), `origin` (the model is far from its origin), `triangle_budget` and `draw_call_budget` (more triangles or submeshes than a platform's budget for one model; the same table model.game_ready reports, and a LOD of the document's gameReady that fits makes the triangle finding information). Example: {"path":"assets/models/door.model.json","expectedHeight":2.1,"platforms":["mobile"]}

Every finding has `message` (what is wrong, with the parts and bounds), `hint` (how to fix it), and for mesh faults `count`, `parts`, `bounds` and up to `samples` positions in model space. `ok` is false when there is an error. `platforms` limits the budgets checked (default all); `ignore` lists codes not to report (an open surface that is meant to be open: ["open_edges"]). With no `path` or `document` it returns the catalog of checks and budgets. Nothing is written.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The model document, project-relative, under assets/, ending in .model.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, instead of a file (format is filled in). |
| `expectedHeight` | number | no | The height (Y) the model should have in metres, e.g. 1.8 for a person, 0.75 for a table. 0 = no expectation. Default 0.0. |
| `tolerance` | number | no | A fraction of expectedHeight the height may differ by. Default 0.25. |
| `platforms` | array | no | Platforms whose triangle and draw call budgets to check: desktop, mobile, web. Default all. |
| `ignore` | array | no | Check codes not to report, e.g. ["open_edges"] for a surface that is meant to be open. |
| `samples` | number | no | Sample positions listed per finding. Default 6.0. |

## `model.create` (modifies state)

Since 0.16.0.

Write a new model document (a tree of primitives, modifiers, groups and transforms) and bake it to a .glb.

Capabilities: read, writeProject

Writes `path` (*.model.json under assets/) with the format, the `nodes` (a list of node objects; model.info {} lists the operations and fields; left out: one box named box_1 to start from), the optional `materials` ({name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}), `output` ({path: where the .glb goes}) and `doc` note. Nodes without an `id` get one (box_1, cylinder_2...), so model.edit can address them later. The document is checked first: a mistake returns every issue (JSON pointer, what is wrong, how to fix it) and writes nothing. Then it is baked (unless bake is false) and the result holds the measurements. Example: {"path":"assets/models/door.model.json","materials":{"wood":{"color":[0.55,0.35,0.2,1]},"brass":{"color":[0.8,0.65,0.3,1],"metallic":1}},"nodes":[{"op":"box","id":"panel","size":[1,2,0.08],"part":"door","material":"wood"},{"op":"sphere","id":"knob","radius":0.05,"position":[0.4,0,0.07],"part":"knob","material":"brass"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `nodes` | array | no | The tree, in order. Each node is {"op": ..., fields}; groups and modifiers hold `children`. |
| `materials` | object | no | Named materials the nodes refer to with `material`: {name: {color, texture, metallic, roughness, emissive, doubleSided, blend}}. |
| `uv` | object | no | The uv section: how the model gets its UVs ({method, layout, texelsPerUnit, ...}; docs/MODELING.md, "UVs"). model.uv changes it field by field. |
| `texturing` | object | no | The texturing section: bake a texture for the model ({size, ao, maps, wear, decals, ...}; docs/MODELING.md, "Texturing"). Needs a uv section with the atlas layout. model.texture changes it field by field. |
| `vertexColors` | object | no | The vertexColors section: low-poly colour without a texture ({palette, parts, flat, variation, ...}; docs/MODELING.md, "Texturing"). model.palette changes it. |
| `output` | object | no | {path: where to bake, under assets/, ending in .glb}. |
| `doc` | string | no | A note on what the model is for. |
| `overwrite` | boolean | no | Replace the document when it exists (and the .glb when nothing baked it). Default false. |
| `bake` | boolean | no | Bake the .glb after writing. Default true. |

## `model.decal` (modifies state)

Since 0.16.0.

Add, replace, remove or clear the decals of a model document: pictures (logos, stains, markings) projected on its surface and baked into the texture.

Capabilities: read, writeProject

A decal is an image of the project (assets.generate_texture output, or the baked png of an image document) projected along the opposite of its `normal` from `position` (model space, metres), `size` [w, h] metres, `rotation` degrees around the normal, `opacity`, `tint`, `depth` (how far from the plane through `position` the projection reaches, each way; 0 = the smaller side), `maxAngle` (surfaces turned more than this away from `normal` are left alone, default 75). `parts` restricts it to named parts and `faces` to the faces of a selection query (model.select tries one). Decals are composited in order into the layer "model: decals" of the texture; transparent pixels of the image stay transparent. `add` takes one decal or a list (a decal whose name exists replaces it; a missing name becomes decal1, decal2...); `remove` takes a name or a list; `clear` removes all. With none of them it only lists. Example: {"path":"assets/models/crate.model.json","add":{"name":"label","image":"assets/textures/label.png","position":[0,0.2,0.5],"normal":"front","size":[0.4,0.25]}}

Adding decals to a model with no texturing section creates one (and a uv unwrap when it has no uv section). The decals must name existing images and the whole document is checked first; nothing is written on a mistake. The report says how many texels each decal painted: 0 means it missed the surface.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `add` | any | no | A decal {name, image, position, size, normal, depth, rotation, opacity, tint, maxAngle, parts, faces} or a list of them. An existing name is replaced. |
| `remove` | any | no | The name of a decal to remove, or a list of names. |
| `clear` | boolean | no | Remove every decal. Default false. |
| `bake` | boolean | no | Bake the model and its texture again after a change. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |
| `picture` | boolean | no | Return the baked texture ($image). Default true. |

## `model.edit` (modifies state)

Since 0.16.0.

Add, change, remove or move one node of a model document by its id (or JSON pointer), or change its materials, output or note; then bake it.

Capabilities: read, writeProject

`op` is one of: add (insert `node`, an object, into the group or modifier `parent` at `index`, default the end of the top level; a node without an id gets one), set (change the fields of `target` with `values`; a null value removes a field, back to its default), remove (delete `target` and everything below it), move (take `target` to the group or modifier `parent`, or the top level, at `index`), document (change `materials`, `output`, `gameReady` or `doc`; `materials` replaces the whole table). `target` and `parent` are a node id (stable when the tree changes) or a JSON pointer such as /nodes/1/children/0. The result document is checked as a whole before anything is written, so a bad value returns every issue with its JSON pointer and writes nothing; the file keeps the other nodes as written. Then the .glb is baked again (unless bake is false) and the measurements tell what the edit did. Example: {"path":"assets/models/door.model.json","op":"set","target":"knob","values":{"radius":0.07}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `op` | string ["add","set","remove","move","document"] | yes | What to do. |
| `target` | string | no | set, remove, move: the node to act on, by id or JSON pointer. |
| `node` | object | no | add: the new node, {"op": ..., fields}. |
| `parent` | string | no | add, move: the group or modifier to put the node in, by id or JSON pointer. Left out: the top level. |
| `index` | integer | no | add, move: the position in the list the node goes into. Left out: the end. |
| `values` | object | no | set: fields to change; null removes a field. |
| `doc` | string | no | document: the new note. |
| `output` | object | no | document: the new output settings ({path}); null removes them. |
| `materials` | object | no | document: the new materials table; null removes it. |
| `uv` | any | no | document: the new uv section, whole; null removes it. model.uv changes single fields. |
| `texturing` | any | no | document: the new texturing section, whole; null removes it. model.texture changes single fields. |
| `vertexColors` | any | no | document: the new vertexColors section, whole; null removes it. model.palette changes it. |
| `gameReady` | object | no | document: the whole game-ready settings object (model.game_ready changes single settings); null removes it. |
| `bake` | boolean | no | Bake the .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |

## `model.game_ready` (modifies state)

Since 0.16.0.

Make a model document game-ready: origin, merged submeshes, LODs, a collider and a triangle budget report per platform; the settings live in the document.

Capabilities: read, writeProject

Reads or changes the `gameReady` settings of a model document (docs/MODELING.md, "Game-ready models"), then bakes. `origin`: keep, center, bottom or bottom_center (where the model's origin sits). `merge`: true joins submeshes with the same material (fewer draw calls) and welds identical vertices. `lods`: a list (at most 4) of {ratio (fraction of triangles to keep), triangles (at most that many), error (largest surface movement in metres), distance (metres from which the game draws it; automatic: the model's largest dimension times 4, 8, 16, 32)}; made with meshoptimizer, each submesh simplified with its border locked, so parts stay apart. `collider`: {shape: none, box, sphere, capsule, convex or decomposed (V-HACD), maxHulls, maxVertices, resolution, part, radius, height}. `platforms`: which budgets to check (desktop 100000 triangles / 16 draw calls, mobile 20000 / 8, web 40000 / 10). Each value you give replaces that setting as a whole (null removes it back to its default; `clear` removes them all). Example: {"path":"assets/models/tree.model.json","origin":"bottom_center","merge":true,"lods":[{"ratio":0.5},{"ratio":0.15}],"collider":{"shape":"convex"}}

`collider.part` fits the collider to the submeshes of that named part only (a pine's "trunk", so the canopy does not block; it works with `merge`; an unknown name lists the parts); `collider.radius` (sphere, capsule) and `collider.height` (capsule, total) are metres that replace the fitted value. The result is checked before anything is written, then the bake writes <name>.glb, <name>.lod1.glb..., <name>.collider.glb (or collider1.glb... for a decomposition) and <name>.prefab.json (a MeshRenderer with `lods` and a Collider3D; a decomposed collider is one static child collider per piece), all recorded in assets.json. With no setting given nothing is written and the result reports the triangles of every LOD against each platform, the collider's fit and the warnings.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `origin` | string ["keep","center","bottom","bottom_center"] | no | Where the model's origin sits. |
| `merge` | boolean | no | Join submeshes with the same material and weld identical vertices (left out: unchanged). |
| `lods` | array | no | LOD1.. as {ratio, triangles, error, distance}; replaces the list. |
| `collider` | object | no | {shape: none\|box\|sphere\|capsule\|convex\|decomposed, maxHulls, maxVertices, resolution, part, radius, height}. |
| `platforms` | array | no | Budgets to check: desktop, mobile, web. |
| `clear` | boolean | no | Remove every game-ready setting first. Default false. |
| `bake` | boolean | no | Bake after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |

## `model.import_clean` (modifies state)

Since 0.16.0.

Clean a generated or imported mesh (.glb, .gltf, .obj) into a game-ready model document: weld, drop floating bits, recentre, scale to a reference, decimate to a platform budget, optionally remesh, unwrap, and bake.

Capabilities: read, writeProject

Takes the mesh `source` (project-relative; assets.generate_model and assets.import put meshes there) and does, in order: `upAxis` (z-up exports are turned to y-up), weld (vertices at the same place with the same uv, colour and a similar normal become one, so seams stay), degenerate and repeated triangles removed, floating pieces removed (separate pieces whose size is under `minPieceSize`, default 2%, of the biggest piece's; the biggest is always kept, and the report lists what went), a consistent winding (neighbouring triangles agree and closed pieces face outward), scale (`height` in metres, `reference` = "human" (1.8 m) or a project model whose height to match, or `scale` factor; without one the size is kept, with a warning when it is not a size a game uses), `origin` (keep, center, bottom or bottom_center, the ground centre: the default), an optional remesh (`remesh: true` ... Example: {"source":"assets/models/robot.glb","height":1.8,"platform":"mobile"}

... the surface is rebuilt from a thickened distance field, so holes, non-manifold edges and self-intersections of AI meshes become one closed manifold surface; `remeshCells` along the longest side or `remeshVoxel` metres; texture coordinates cannot survive it, so base colour textures are sampled into vertex colours and the surface is unwrapped again; thin sheets become thin solids), and decimation to `triangles` or the `platform` budget (desktop 100000, mobile 20000, web 40000; meshoptimizer, keeping uvs, colours and part seams). `unwrap`: auto (default; unwrap with model_uv when the mesh has no uvs or was remeshed), always, never. A .obj goes through assets.import's converter first (the .gltf is written next to it and reused when it exists). Materials and textures of the source stay (embedded textures are written as project files). The result is a model document `<name>_clean.model.json` (or `out`) with a `mesh` node reading the cleaned mesh `<name>_clean.mesh.glb`, baked to `<name>_clean.glb`: modifiers, selections, uv and gameReady apply to it like to any model. The report teaches what was done: triangles and vertices before and after, vertices welded, pieces found and removed (size, place), triangles reoriented, non-manifold and open edges before and after, scale factor and its reason, the origin shift, remesh and decimation details, the fit to every platform's budget, and warnings.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The mesh to clean: a project-relative .glb, .gltf or .obj. Path the command reads. |
| `out` | string | no | The model document to write, under assets/, ending in .model.json. Default <source folder>/<name>_clean.model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the document, and a .glb that no model document baked. Default false. |
| `upAxis` | string ["y","z"] | no | Which axis is up in the source: y (glTF, the engine) or z (Blender and CAD exports; turned to y). Default "y". |
| `weldDistance` | number | no | Vertices closer than this many metres are one (when uv, colour and normal agree). 0 = a millionth of the model's size. Default 0.0. |
| `removeFloating` | boolean | no | Remove separate pieces smaller than `minPieceSize` of the biggest piece. Default true. |
| `minPieceSize` | number | no | A piece whose size is under this fraction of the biggest piece's is floating and removed (0..1). Default 0.02. |
| `origin` | string ["keep","center","bottom","bottom_center"] | no | Where the model's origin goes: keep, center, bottom, bottom_center (the ground centre). Default "bottom_center". |
| `height` | number | no | Scale so the model is this many metres tall (Y extent). Exclusive with reference and scale. |
| `reference` | string | no | Scale to the height of this model: "human" (1.8 m) or a project .model.json, .glb or .gltf. Exclusive with height and scale. Path the command reads. |
| `scale` | number | no | Multiply the size by this factor (0.01 for centimetres). Exclusive with height and reference. |
| `platform` | string ["desktop","mobile","web"] | no | The budget to decimate to: desktop, mobile or web (model.game_ready lists them). Default "desktop". |
| `triangles` | integer | no | Decimate to at most this many triangles instead of the platform budget. |
| `remesh` | boolean | no | Rebuild the surface through a signed distance field: closed, manifold, no self-intersection; loses texture coordinates. Default false. |
| `remeshCells` | integer | no | Remesh: cells along the longest side. Default 128. |
| `remeshVoxel` | number | no | Remesh: the cell size in metres instead of remeshCells (0 = use remeshCells). Default 0.0. |
| `unwrap` | string ["auto","always","never"] | no | Unwrap with xatlas into the document's uv section: auto (when the mesh has no uvs or was remeshed), always or never. Default "auto". |
| `texelsPerUnit` | number | no | Texels per metre of the unwrap (default the project's style guide, else 128). |
| `bake` | boolean | no | Bake the document to its .glb. Default true. |

## `model.info`

Since 0.16.0.

Check a model document and measure what it builds; with no arguments, list the operations (primitives, modifiers, group) and their fields.

Capabilities: read

A model document (`*.model.json`, docs/MODELING.md) is a 3D model written as a tree of operations: primitives (box, rounded_box, cylinder, cone, sphere, capsule, torus, grid, stairs, arch, pipe, text, lathe, sweep, loft), groups, modifiers that wrap their children and change the mesh they make (boolean, mirror, array, radial_array, bevel, subdivide, solidify, bend, twist, taper, noise, smooth, weld, shade), edits on a selection chosen by meaning (extrude_faces, inset_faces, loop_cut, bevel_edges, delete_faces, assign_faces: see model.select and the "selections" of the catalog), and a transform, a part name, a material and a vertex colour on any node. With `path` (or an inline `document`) this checks it: a document with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and the fix; a valid one returns the tree (pointer, op, id, part, material per node), where it bakes to and whether that .glb is fresh or stale, and (unless evaluate is false) builds it in memory: vertices, triangles, bounds and size in metres, whether the surface is closed, volume, and the triangles and bounds of every part. With no argument it returns the catalog of operations with every field, its range, default and doc string. Example: {"path":"assets/models/door.model.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The model document, project-relative, under assets/, ending in .model.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, to check before writing it to a file (format is filled in). |
| `evaluate` | boolean | no | Build the mesh in memory for the measurements. Turn it off to only check the document. Default true. |

## `model.palette` (modifies state)

Since 0.16.0.

Colour a model with a palette without a texture: the `vertexColors` section (style palette or your own colours, one colour or a gradient per part, flat low-poly faces); returns the palette swatches.

Capabilities: read, writeProject

The `vertexColors` section of a model document writes colours into the mesh while it is evaluated, so a low-poly model needs no texture. `palette` is "style" (the project's assets.json style.palette) or a list of colours; with a palette every colour snaps to the nearest one (`snap: false` turns that off). `color` is the colour of the parts with no entry; `parts` gives each part (by name, "" for nodes with no part) `color` (a colour or the index of a palette colour), or a `gradient` {axis, from, to, via, range} along a model axis, and its own `variation`. `flat: true` gives every triangle one colour (vertices are split: the faceted look); `variation` (0..0.5) changes each triangle's or vertex's brightness a little, deterministically from `seed`. Colours are "#rrggbb", "#rrggbbaa" or [r, g, b, a] from 0 to 1. Example: {"path":"assets/models/house.model.json","set":{"palette":"style","flat":true,"variation":0.05,"parts":{"roof":{"color":2},"wall":{"gradient":{"from":0,"to":1,"axis":"y"}}}}}

The colours multiply any the nodes already have, and go into the .glb as vertex colours (or into the texture when the document has a `texturing` section). A bake that used the style palette is stale when the style guide's palette changes. With `set` the fields are merged (a null removes one; `parts` merges part by part), `replace` puts `set` in place of the section, `clear` removes it; the document is checked as a whole first. The result has the section, the palette as hex, the report (triangles coloured, distinct colours, vertices before and after the split) and warnings (a part name the model does not have).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `set` | object | no | Fields of the vertexColors section to change: palette, snap, flat, variation, seed, color, parts. A null value removes a field; parts merges part by part (a null part is removed). |
| `replace` | boolean | no | Put `set` in place of the whole section instead of merging it. Default false. |
| `clear` | boolean | no | Remove the vertexColors section. Default false. |
| `bake` | boolean | no | Bake the .glb again after a change. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |
| `picture` | boolean | no | Return the palette swatches ($image) when there is a palette. Default true. |

## `model.preview` (modifies state)

Since 0.16.0.

Draw a model document from 4 to 8 sides (a turntable sheet, shaded and/or wireframe) beside a 1.8 m reference figure, with its triangle count and size; returns the PNG.

Capabilities: read, state

The way to SEE a model. It builds the document in memory and draws it with a software renderer (no graphics device, the same pixels on every machine): one picture with `views` sides evenly spaced around the model, starting at `yaw`, seen from `pitch` degrees above the horizon, each framed the same way so sizes compare across the sheet. A blue 1.8 m figure stands beside the model on the ground (turn it off with figure false) and a grid lies on y = 0 with the origin's axes brighter, so scale, how it stands and where its origin is can be read at once. The header gives the triangle count, the size in metres and the number of parts. A dark red surface is one seen from inside (a flipped triangle). `mode` is "shaded", "wireframe" (the triangle edges; hidden ones stay hidden) or "shaded_wireframe"; `part` draws one part in orange. It draws the mesh the game gets: with `gameReady` settings in the document, their origin and merge are applied. The picture is returned as $image in a temporary file; pass `out` (a project-relative .png) to keep it. Nothing in the project changes otherwise (a caller that may not write the project cannot use `out`). Example: {"path":"assets/models/crate.model.json","views":4,"mode":"shaded_wireframe"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The model document, project-relative, under assets/, ending in .model.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, instead of a file (format is filled in). |
| `views` | number | no | How many sides to draw, 4 to 8, evenly spaced around the model (a whole number). Default 6.0. |
| `yaw` | number | no | The angle of the first view in degrees: 0 looks at the model's +Z side, 90 at its +X side. Default 30.0. |
| `pitch` | number | no | Degrees above the horizon. Default 20.0. |
| `cell` | number | no | Pixels per side of each view. Default 320.0. |
| `mode` | string ["shaded","wireframe","shaded_wireframe"] | no | shaded draws surfaces, wireframe the triangle edges, shaded_wireframe both. Default "shaded". |
| `figure` | boolean | no | Draw the 1.8 m reference figure beside the model. Default true. |
| `ground` | boolean | no | Draw the grid on y = 0. Default true. |
| `part` | string | no | A part of the model to draw in orange. |
| `out` | string | no | Keep the picture as a PNG at this project-relative path (ending in .png; needs the writeProject capability, never inside .git or .factoria). Left out, it is a temporary file. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the file at `out` if it exists. Default false. |

## `model.select`

Since 0.16.0.

Try a selection of faces or edges chosen by meaning (normal direction, part, region, top/bottom, border, sharp, seam) on the mesh a node receives, and report what it matched.

Capabilities: read

The edit operations extrude_faces, inset_faces, bevel_edges, delete_faces and assign_faces take a selection written as a query, never as indices: {"by": "normal", "direction": "top"}, {"by": "part", "part": "lid"}, {"by": "box", "min": [...], "max": [...]}, combined with and / or / not / grow / shrink; edges: border (of a face selection), sharp (over an angle), between_parts, loop (round an axis at a height or ratio). This evaluates the document up to `node` and runs the query on the mesh that node receives (its merged children, or the mesh a primitive made; in the node's own space, before its transform), then answers: how many faces (or edges) matched out of how many, their total area (or length), their bounds and how many belong to each part. An empty selection returns a warning that says why (what the mesh spans, the parts that exist, how close the nearest face was). Without `faces` / `edges` the node's own selection is used, so model.select on an edit node tells what it will edit. Because a query is evaluated on every build, it keeps meaning the same faces when the model below changes. Example: {"path":"assets/models/crate.model.json","node":"body","faces":{"by":"normal","direction":"top"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The model document, project-relative, under assets/, ending in .model.json. Path the command reads. |
| `document` | object | no | The document itself, as JSON, instead of a file. |
| `node` | string | yes | The node whose mesh is selected on, by id or JSON pointer. |
| `faces` | object | no | A face query, e.g. {"by": "normal", "direction": "top"}. model.info {} lists them. |
| `edges` | object | no | An edge query, e.g. {"by": "sharp", "angle": 60}. |

## `model.texture` (modifies state)

Since 0.16.0.

Texture a model document: materials with tiling textures projected triplanar into the UV atlas, vertex colours, baked ambient occlusion and wear (worn edges, dirt in cavities) built from baked curvature and thickness, and decals; the result is a layered image document you can paint on. Returns the texture picture.

Capabilities: read, writeProject

The `texturing` section of a model document (docs/MODELING.md, "Texturing") makes the CPU bake the model's colour into its UV atlas (it needs a `uv` section with layout "atlas"; with none, {"method":"unwrap"} is added). Example: {"path":"assets/models/crate.model.json","set":{"size":1024,"ao":true,"wear":[{"mask":"edges","color":"#d9d2c0"},{"mask":"cavity","color":"#2a2018","amount":0.6}]}}

What goes into the picture: the colour of each material (a material with a `texture` is projected along the three axes and blended by the normal, `textureScale` metres per repeat, `textureOffset`, `sharpness`, `tint` on the material; the texture never goes through the model's uvs once the section exists), the vertex colours (`vertexColors` section: "bake" puts them in the picture, "keep" leaves them on the mesh), `ao` (ambient occlusion multiplied in: true or {strength, parts}), `wear` (a list of {mask: edges | cavity | ao | thickness, color, amount, width, threshold, noise, noiseScale, seed, upBias, parts}: worn paint on convex edges, dirt in concave corners, dust on top faces) and `decals` (see model.decal). `maps` sets how the occlusion, curvature and thickness are measured (samples, distance, thicknessDistance, edgeAngle, edgeWidth) and `write` lists the maps also kept as grey pictures next to the model. `size` 0 uses the uv section's texture size; `bleed` spreads the colours past each piece so mipmaps do not show the background. The bake writes the layers as pictures next to the .glb (<name>.base.png, .decals.png, .wear.png, .occlusion.png, .uv.png) and composes them in the image document <name>.texture.image.json (M52) whose baked picture is the .glb's base colour texture; the LOD .glbs of `gameReady` use the same picture. Open that document like any image (image.info, image.* commands) and paint on the layer "paint" or any layer of your own: a re-bake only rewrites the layers named "model: ..." and never touches yours. With `set` the fields are merged into the section (a null removes one; `maps` merges field by field, `wear` and `decals` are replaced as lists), `replace: true` puts `set` in place of the section, `clear: true` removes it. The document is checked as a whole and a mistake returns every issue with its JSON pointer and writes nothing. Then the model is baked (unless bake is false). With no `set` or `clear` it bakes only if something is out of date and reports. The result has the section with its defaults, `texture` (the image document, the picture, the layer pictures, the measurements: texels covered, overlap, each map's mean/min/max, each wear and decal's coverage, each part's mapping) and warnings, and a picture of the baked texture.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `set` | object | no | Fields of the texturing section to change: size, bleed, vertexColors, background, document, ao, maps, wear, decals. A null value removes a field; maps merges field by field; wear and decals are replaced whole (model.decal edits single decals). |
| `replace` | boolean | no | Put `set` in place of the whole section instead of merging it. Default false. |
| `clear` | boolean | no | Remove the texturing section. The layer pictures go with the next bake; the texture's image document and what you painted stay. Default false. |
| `bake` | boolean | no | Bake the model and its texture again after a change. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |
| `picture` | boolean | no | Return the baked texture ($image). Default true. |

## `model.uv` (modifies state)

Since 0.16.0.

Give a model document UVs (automatic unwrap, or box, cylinder, sphere and planar projections per part, packed into one texture at the style's texel density) and measure them; returns the UV layout picture.

Capabilities: read, writeProject

The `uv` section of a model document replaces the primitives' own uvs: `layout` "atlas" (default) packs every piece into one texture painted for this model, "tile" gives world-scale uvs that continue across the model and repeat. `method` is "unwrap" (xatlas cuts the surface into pieces and flattens each with little stretch; atlas default), or a projection: "box" (each face on the axis plane it looks at; tile default), "cylinder" and "sphere" (around `axis`), "planar" (along `axis`); `parts` overrides method, axis and texelsPerUnit per part name, so a wheel can be a cylinder and a body unwrapped. `texelsPerUnit` is texels per metre (default the project's assets.json style.texelsPerUnit, else 128); `textureSize` 0 picks the smallest power of two the pieces fit in, a fixed size the pieces do not fit lowers the density (a warning says so); `padding` empties texels around each piece; `seams` few, balanced or many; `rotate` lets the packer turn pieces. Example: {"path":"assets/models/crate.model.json","set":{"method":"unwrap","texelsPerUnit":256,"parts":{"wheel":{"method":"cylinder","axis":"x"}}}}

The same spec works on sdf organic shapes, whose default box uvs it replaces. With `set` the fields are merged into the section (a null value removes a field; `parts` merges part by part), `replace: true` puts `set` in place of the section, `clear: true` removes it; the document is checked as a whole and a mistake returns every issue with its JSON pointer and writes nothing. Then the .glb is baked again (unless bake is false). The result measures the uvs: texels per metre (mean, min, max, per part), stretch (1 = none, 2 = a texture drawn twice as long one way as the other), seams, mirrored triangles, how full the texture is, overlap and uvs outside 0..1, with warnings that say what to change; with no `set` or `clear` it only measures (a document with no uv section is measured on its primitives' own uvs). Unless picture is false it returns the layout (`$image`): the texture square with every triangle at its uvs, a colour per part, mirrored triangles red.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The model document, project-relative, under assets/, ending in .model.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `set` | object | no | Fields of the uv section to change: layout, method, axis, texelsPerUnit, textureSize, padding, seams, rotate, parts. A null value removes a field; parts merges part by part (a null part is removed). |
| `replace` | boolean | no | Put `set` in place of the whole section instead of merging it. Default false. |
| `clear` | boolean | no | Remove the uv section: the model keeps its primitives' own uvs. Default false. |
| `bake` | boolean | no | Bake the .glb again after a change. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no model document baked. Default false. |
| `picture` | boolean | no | Return the UV layout picture ($image). Default true. |

## `music.arpeggio` (modifies state)

Since 0.16.0.

Make an arpeggio over a chord progression as note text, and optionally put it in a song.

Capabilities: read, writeProject

Spells the chords of `progression` one note after another, in a direction (up, down, updown, downup, random), over 1 to 4 octaves, at a rate, with the first note of each beat accented. Returns the note text. With `path` it also writes the text as a pattern (default track "arp", pattern "arp", instrument pluck; created when missing), and with `section` adds it to what the track plays there; meter, key and mode come from the song. Example: {"progression":"Am F C G","direction":"updown","octaves":2,"path":"assets/music/theme.song.json","section":"loop"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Write the pattern into this song (a `path` under assets/ ending in .song.json): the track is created if it does not exist. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `track` | string | no | Track the pattern goes in (created with `instrument` when it does not exist). |
| `pattern` | string | no | Name of the pattern. |
| `section` | string | no | Also add the pattern to the end of what the track plays in this section, so it sounds. |
| `progression` | string | yes | Chord names or Roman numerals (in `key`/`mode`); *N holds a chord N bars. |
| `instrument` | string | no | Instrument of the track when it is created. Default pluck. |
| `key` | string | no | Key for Roman numerals. Default C, or the song's. |
| `mode` | string | no | Scale for Roman numerals. Default major, or the song's. |
| `meter` | string | no | Meter. Default 4/4, or the song's. |
| `direction` | string | no | up, down, updown, downup or random. Default up. |
| `octaves` | integer | no | Octaves the chord is stacked over, 1 to 4. Default 1. |
| `rate` | integer | no | Note value of a step: 4, 8, 16 or 32. Default 16. |
| `triplet` | boolean | no | Steps are triplets of the rate. Default false. |
| `octave` | integer | no | Octave of the chords' roots. Default 3. |
| `velocity` | integer | no | Note velocity 1 to 127. Default 90. |
| `accent` | boolean | no | Accent the first note of every beat. Default true. |
| `staccato` | boolean | no | Short notes. Default false. |
| `seed` | integer | no | Direction random: the same seed gives the same notes. |
| `picture` | boolean | no | Return the piano-roll picture (`$image`) of the song after the change. Default false. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |
| `bars` | integer | no | Number of bars shown (default: to the end). |

## `music.bassline` (modifies state)

Since 0.16.0.

Make a bassline over a chord progression as note text, and optionally put it in a song.

Capabilities: read, writeProject

A bass part from the progression: root (a note per beat on the root), root_fifth, octave (eighths jumping an octave) or walking (stepwise toward the next chord). Returns the note text. With `path` it writes it as a pattern (default track "bass", pattern "bass", instrument bass; created when missing) and, with `section`, plays it there. Example: {"progression":"i VI III VII","key":"A","mode":"minor","style":"walking"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Write the pattern into this song (a `path` under assets/ ending in .song.json): the track is created if it does not exist. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `track` | string | no | Track the pattern goes in (created with `instrument` when it does not exist). |
| `pattern` | string | no | Name of the pattern. |
| `section` | string | no | Also add the pattern to the end of what the track plays in this section, so it sounds. |
| `progression` | string | yes | Chord names or Roman numerals (in `key`/`mode`); *N holds a chord N bars. |
| `instrument` | string | no | Instrument of the track when it is created. Default bass. |
| `key` | string | no | Key for Roman numerals. Default C, or the song's. |
| `mode` | string | no | Scale for Roman numerals. Default major, or the song's. |
| `meter` | string | no | Meter. Default 4/4, or the song's. |
| `style` | string | no | root, root_fifth, octave or walking. Default root_fifth. |
| `octave` | integer | no | Octave of C for the bass. Default 2. |
| `rate` | integer | no | Note value: 4 or 8; 0 = the style's own. |
| `velocity` | integer | no | Note velocity 1 to 127. Default 100. |
| `picture` | boolean | no | Return the piano-roll picture (`$image`) of the song after the change. Default false. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |
| `bars` | integer | no | Number of bars shown (default: to the end). |

## `music.check` (modifies state)

Since 0.16.0.

Find what is wrong in a song before listening: notes outside the key or the instrument's range, clashes, mud, silent tracks, loudness.

Capabilities: read, state

Runs the music checks on a song (`path` or inline `song`). Rules: off_key (a note outside the song's key and mode that is not a passing tone), range (a note outside the instrument's range or the track's `range`), clash (a minor second or a tritone sounding together on a strong beat), mud (close low notes under C3), structure (a track that never plays, an empty section, an unused pattern) and loudness (the song is rendered with its mixer: with the master limiter off a clipping mix is an error and a peak over -1 dBFS a warning; a limiter that pulls the level down by more than 6 dB is a warning, more than 3 dB a note; a mix below -35 LUFS is a warning; an integrated loudness more than 3 LU from the target is a warning, unless the master `loudness` brings it there). Without `rules` every rule that needs no render runs; `render: true` adds loudness. The target is `targetLufs`, else style.audio.loudnessLufs.music of assets.json when the style guide says it. Every finding has the rule, severity, a message, a fix (`hint`), the track, pattern, section, bar and position, and for a note the pointer, line, column and token in the note text; equal findings are reported once with a `count`. `ok` is true when there is no error and no warning. A song with mistakes fails like music.info. Example: {"path":"assets/music/theme.song.json","render":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command reads. |
| `song` | object | no | The song itself, as JSON, to check before writing it to a file. |
| `rules` | array | no | Which rules to run (default: every rule that needs no render). Naming loudness renders the song. |
| `render` | boolean | no | Also run the loudness rule: render the song and measure it. Default false. |
| `targetLufs` | number | no | Integrated loudness the music should have (LUFS, -70 to 0). Default: style.audio.loudnessLufs.music of assets.json, if set. |

## `music.chord`

Since 0.16.0.

Spell a chord by name, or a chord progression in a key: notes, MIDI numbers and the note text to paste.

Capabilities: read

With `name` ("Am7", "Cmaj7/G", "F#dim", "Dsus4") it returns the chord's notes at `octave`, their MIDI numbers, the interval list and the two ways to write it in note text. With `progression` (names, or Roman numerals in `key` and `mode`, or those of the song at `path`) it returns every chord and `pad`, the progression as sustained chords. With no arguments it lists the chord qualities the notation knows. Example: {"progression":"i VI III VII","key":"A","mode":"minor"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | One chord: root, quality, optional /bass. Omit to list qualities. |
| `progression` | string | no | Chord names or Roman numerals; *N holds a chord N bars. |
| `path` | string | no | Read meter, key and mode from this song. Path the command reads. |
| `key` | string | no | Key for Roman numerals. Default C, or the song's. |
| `mode` | string | no | Scale for Roman numerals. Default major, or the song's. |
| `meter` | string | no | Meter such as "4/4". Default 4/4, or the song's. |
| `octave` | integer | no | Octave of the chord's root (C4 is middle C). Default 3. |

## `music.create` (modifies state)

Since 0.16.0.

Write a new song document: pad, bass, drums and an arpeggio over a chord progression, with intro, loop and outro.

Capabilities: read, writeProject

Makes a complete, valid starting song at `path` (assets/..., ending in .song.json): a pad playing the chords, a bassline, a drum groove in a style and (unless arpeggio is false) a plucked arpeggio; sections intro, loop (twice) and outro. It is a starting point to change with music.edit, not a finished piece. `progression` is chord names ("Am F C G") or Roman numerals in the key ("i VI III VII"; `*2` holds a chord two bars). Defaults: tempo from the drum style's usual range, 4/4, key A minor, progression "i VI III VII" (minor) or "I V vi IV" (major), style rock (waltz in 3/4), bass root_fifth. Fails with `exists` when the file is there unless overwrite is true. Returns the song's summary and a piano-roll picture (`$image`). Example: {"path":"assets/music/theme.song.json","key":"D","mode":"dorian","tempo":96,"style":"funk"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `picture` | boolean | no | Return the piano-roll picture (`$image`) of the new song. Default true. |
| `tempo` | number | no | Quarter notes per minute, 20 to 400. Default: the middle of the drum style's usual range. |
| `meter` | string | no | Meter such as "4/4", "3/4" or "6/8". Default 4/4. |
| `key` | string | no | Key, a note name such as "A", "F#" or "Bb". Default A. |
| `mode` | string | no | Scale: major, minor, dorian, phrygian, lydian, mixolydian, ... (music.scale lists them). Default minor. |
| `progression` | string | no | Chords by name ("Am F C G", "Am7 \| Fmaj7") or Roman numerals in the key ("i VI III VII"); *N holds a chord N bars. Default: the usual four chords of the mode. |
| `style` | string | no | Drum style (music.drums lists them): rock, funk, waltz, ... Default rock, or waltz in 3/4. |
| `bassStyle` | string | no | Bassline style: root, root_fifth, octave or walking. Default root_fifth. |
| `arpeggio` | boolean | no | Add a plucked arpeggio track. Default true. |
| `swing` | number | no | Swing from 0 (straight) to 1 (triplet feel). |
| `doc` | string | no | A sentence about the song, stored in the document. |
| `seed` | integer | no | The song's seed (the take of random hits and arpeggios). |
| `overwrite` | boolean | no | Replace the file when it exists. Default false. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |
| `bars` | integer | no | Number of bars shown (default: to the end). |

## `music.drums` (modifies state)

Since 0.16.0.

Make a drum pattern in a style (rock, funk, waltz, ...), and optionally put it in a song.

Capabilities: read, writeProject

Without `style` it lists the styles and the kit's lanes. With one it returns a drum pattern ({"grid": {lane: steps}, "step": "16"}) of `bars` bars, with a tom fill on the last beat if `fill` is set. With `path` it writes it as a pattern (default track "drums", pattern "groove", instrument kit; created when missing) and with `section` plays it there; the meter comes from the song. A style written for 4/4 fails in 3/4 and says so. Example: {"style":"funk","bars":2,"fill":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Write the pattern into this song (a `path` under assets/ ending in .song.json): the track is created if it does not exist. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `track` | string | no | Track the pattern goes in (created with `instrument` when it does not exist). |
| `pattern` | string | no | Name of the pattern. |
| `section` | string | no | Also add the pattern to the end of what the track plays in this section, so it sounds. |
| `style` | string | no | Style name. Omit to list the styles. |
| `bars` | integer | no | Bars in the pattern. Default 1. |
| `fill` | boolean | no | Make the last beat of the last bar a tom fill. Default false. |
| `meter` | string | no | Meter. Default 4/4, or the song's. |
| `picture` | boolean | no | Return the piano-roll picture (`$image`) of the song after the change. Default false. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |

## `music.edit` (modifies state)

Since 0.16.0.

Change a song document: tempo, tracks, patterns, sections, the arrangement, mutes and automation, checked before anything is written.

Capabilities: read, writeProject

Applies `ops` in order to the song at `path` and writes it, but only if the result is a valid song (otherwise it fails with `invalid_song`, every problem in data.issues, and the file is untouched). Example: {"path":"assets/music/theme.song.json","ops":[{"op":"set_pattern","track":"bass","pattern":"line","notes":"A2:8 A2 E3 A2 | G2:8 G2 D3 G2"},{"op":"mute","section":"intro","tracks":["drums"]}]}

Each op is an object with `op` and its fields: set_song {tempo, meter, key, mode, swing, swingGrid, seed, volume, doc} (null removes a field); add_track {track, instrument, volume, pan, mute, solo, voices, effects, sends, transpose, swing, range, kit, patterns, automation, play}; set_track {track, name (renames and updates the sections), instrument (a name, a .sfx.json, "x.sf2#Preset" or {soundfont, preset, bank}), volume, pan, mute, solo, voices, effects, sends, transpose, swing, range, kit, automation} (null removes); set_mixer {buses: {name: {volume, pan, mute, effects} | null}, master: {effects, limiter, loudness}} (docs/MUSIC.md "Mixer"; a bus merges field by field, null removes a bus or a field); set_layers {layers: {name: [tracks] | {tracks, intensity, doc} | null}} (the groups of tracks music.render writes as stems and a layered player brings in; docs/MUSIC.md "Layers"); remove_track {track} (and every mention in the sections); set_pattern {track, pattern, notes (note text, or a list of {pitch, tick, duration, velocity, accent, staccato} that is written as note text) | grid+step+bars, play}; remove_pattern {track, pattern} (and its uses in the sections); add_section {section, kind (intro, loop, outro, section), repeat, bars, mute, play, index}; set_section {section, name, kind, repeat, bars, mute, play} (play changes only the tracks named, null stops one); remove_section {section}; move_section {section, index}; arrange {section, track, entries} ("a a b*2 rest", a list, or null to stop the track in that section); mute {section, tracks, muted}; set_automation {track (omit for the whole song), param (volume, pan, filter, macro.<name>), points [[beat, value], ...], curve (linear, step, smooth)} (no points removes the lane). `play` in add_track and set_pattern is {section: entries} to place the pattern at once. Note text is in docs/MUSIC.md. Returns the song's summary and what each op did.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `ops` | array | yes | The operations, applied in order. |
| `picture` | boolean | no | Return the piano-roll picture (`$image`) of the song after the change. Default false. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |
| `bars` | integer | no | Number of bars shown (default: to the end). |

## `music.export_midi` (modifies state)

Since 0.16.0.

Write a song as a format-1 Standard MIDI File that a DAW or notation program opens.

Capabilities: read, writeProject

Writes the song at `path` as a Standard MIDI File (format 1, 960 ticks per quarter note) at `out` (default: the song's path with .mid). Track 1 holds the tempo, time signature, key signature (major or minor) and one marker per section ("kind:name"); then one track per song track with its name, instrument (Instrument Name and the General MIDI program), volume and pan controllers and its notes with the length they sound; drum tracks use channel 10 and the General MIDI percussion keys. The sounded timeline is written: swing is in the note times, `transpose` in the pitches, and muted tracks (or tracks not soloed) are left out. The mixer, effects, buses and automation are not part of a MIDI file. music.import_midi reads the file back as the same notes, timing and velocities. Example: {"path":"assets/music/theme.song.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json. Path the command reads. |
| `out` | string | no | The MIDI file to write: a project path ending in .mid. Default: the song's path with .mid. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the file when it exists. Default false. |

## `music.import_midi` (modifies state)

Since 0.16.0.

Turn a Standard MIDI File (.mid) into a song document: tracks, patterns, sections from markers, drums as grids.

Capabilities: read, writeProject

Reads the MIDI file `path` (absolute on this machine, or in the project) with the engine's own parser (format 0 and 1, running status, meta events, any number of tracks and channels; format 2 and SMPTE timing are errors) and writes a song document at `out` (default assets/music/<name>.song.json; assets.import does the same for a .mid). Every (track, channel, program) that plays notes becomes a song track: channel 10 is a drum track (General MIDI percussion keys become the lanes of the built-in kit, as a step grid with ghost / hit / accent velocities), the others take the built-in instrument nearest to the General MIDI program (an Instrument Name that names a built-in instrument wins; with `soundfont` the track plays that SoundFont's preset of the program). Velocities are kept, the sustain pedal lengthens notes, controllers 7 and 10 become the track's volume and pan. `quantize` ("off" keeps the written times to 1/48 of a quarter note; "16", "8t", "32"...) snaps starts and ends. Example: {"path":"C:/music/theme.mid","out":"assets/music/theme.song.json","quantize":"16"}

Markers become sections (a name starting with intro, loop or outro, or written "loop:name"); without markers the song is one section `main`, a loop when `loop` is true. Repeated bars of a track become one pattern played several times. Tempo, meter and key come from the first such event; a later change cannot be held by a song and is listed in `warnings`. Errors name the byte offset in the file. The result is the song summary (as music.info) plus `import` (what was read) and `warnings`; `license`, `author` and `sourceUrl` go to the song's provenance in assets.json. An existing song is an `exists` error unless overwrite is true.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The MIDI file: an absolute path on this machine, or relative to the project. Ends in .mid or .midi. Path the command reads. |
| `out` | string | no | The song to write: under assets/, ending in .song.json. Default: assets/music/<name>.song.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `quantize` | string | no | "off" (default) or a note value to snap starts and ends to: "4", "8", "16", "32", "64", "8t", "16t"... |
| `soundfont` | string | no | A SoundFont (.sf2) under assets/: pitched tracks play its preset with their General MIDI program and drums its drum kit. |
| `loop` | boolean | no | A file with no markers: make its one section the song's loop (default: an ordinary section). Default false. |
| `overwrite` | boolean | no | Replace the song when it exists. Default false. |
| `license` | string | no | License of the MIDI file ("CC0", "CC-BY 4.0"), for the credits. |
| `author` | string | no | Who made the MIDI file. |
| `sourceUrl` | string | no | The page the file came from, for the credits. |

## `music.info` (modifies state)

Since 0.16.0.

Check a song document and say what it holds: structure, bars, seconds, a summary per section, and a piano-roll picture.

Capabilities: read, state

Reads a song (`*.song.json`, format factoria.song/1, docs/MUSIC.md and schemas/song.schema.json) from `path`, or takes it inline as `song`, and checks it. A song with mistakes fails with `invalid_song` and EVERY problem in data.issues (JSON pointer, line and column inside note text, what is wrong and how to fix it), so one call is enough to repair it. A valid song returns tempo, meter, key, mode, swing, the length in bars and seconds, the structure ("intro (4 bars) > loop (8 bars) x2 > outro (4 bars)"), each track (instrument, patterns and their bars, notes played, the range they cover, the sections they play in) and each section (kind, bars, repeats, what every track plays, where it starts in bars and seconds, notes per bar and per track), and where its preview WAV is and whether it is stale. Unless `picture` is false it also returns a piano roll (`$image`): the sections on top, one colour per track, brighter = louder, drum lanes below; `fromBar` and `bars` zoom on a part. Example: {"path":"assets/music/theme.song.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command reads. |
| `song` | object | no | The song itself, as JSON, to check before writing it to a file (format is filled in). |
| `picture` | boolean | no | Return the piano-roll picture (`$image`). Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png; needs the writeProject capability). Default: a temporary screenshot. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `fromBar` | integer | no | First bar shown in the picture (default 1). |
| `bars` | integer | no | Number of bars shown (default: to the end). |

## `music.instrument` (modifies state)

Since 0.16.0.

List the built-in song instruments (by family), the drum kits and lanes, sfx presets and project SoundFonts, show the patch behind an instrument, or list a SoundFont's presets.

Capabilities: read, writeProject

Without `name` it lists what a track's `instrument` can be: the built-in pitched instruments (with family, note range and polyphony), the drum kits (acoustic "kit", "kit:electronic", "kit:chiptune") and their lanes ("kit:kick"), the sfx presets, the .sfx.json patches and the .sf2 SoundFonts in the project. With `name` set to a .sf2 path under assets/ it lists that SoundFont's presets (name, bank, program) so a track can name one. With `name` set to a built-in it returns that instrument's patch (the JSON of a .sfx.json, docs/SOUND.md; a bare lane name like "kick" works) and, with `path`, writes it to a .sfx.json under assets/ so you can change the numbers and point a track at the copy. A pitched patch is played once per note, re-pitched to the note. Example: {"name":"pluck","path":"assets/audio/my_pluck.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | A built-in instrument ("pluck"), a drum lane ("kit:kick", "kit:electronic:kick" or "kick") or a project .sf2 ("assets/audio/piano.sf2": lists its presets). Omit to list them all. |
| `path` | string | no | Write the patch here (a .sfx.json under assets/). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the file at `path` when it exists. Default false. |

## `music.mix` (modifies state)

Since 0.16.0.

Render a song in memory and report the mix: each track's level, the buses and what the master's loudness normalization and limiter did.

Capabilities: read, state

Renders the song (`path`, or inline `song`) like music.preview but writes no file, and returns the mix: for every track its notes, peak (dBFS) and loudness (LUFS) as heard in the mix, volume, pan, effects and sends; the buses (volume, pan, effects); and the master: the loudness and peak before the loudness gain and the limiter, the gain the normalization added, the target loudness (`mixer.master.loudness`: "style" is the project's style.audio.loudnessLufs.music, a number is LUFS, "off" leaves the level), whether the limiter is on and how many dB it pulled down at most. Use it to balance the tracks (a track 10 LU above the others covers them), to see whether the limiter is squashing a hot mix, and before music.edit set_track / set_mixer. `fromBar`, `bars`, `solo`, `mute`, `seed` and `sampleRate` work as in music.preview. Example: {"path":"assets/music/theme.song.json","bars":8}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The song, project-relative, under assets/ and ending in .song.json. Path the command reads. |
| `song` | object | no | The song document inline (a song not saved yet); `path` or `song`. |
| `fromBar` | integer | no | First bar rendered, counted from 1 (default 1). |
| `bars` | integer | no | Number of bars rendered from `fromBar` (default: to the end). |
| `solo` | array | no | Render only these tracks. |
| `mute` | array | no | Leave these tracks out. |
| `seed` | integer | no | Added to the song's seed. Default 0. |
| `sampleRate` | integer [22050,32000,44100,48000] | no | Sample rate of the render (22050 is faster). Default 44100. |

## `music.notes`

Since 0.16.0.

List the notes of one pitched pattern of a song (pitch, tick, duration, velocity), or the hits of a drum pattern, as a piano roll sees them.

Capabilities: read

Reads the pattern `pattern` of `track` in the song at `path` and returns its notes sorted by start: `pitch` (MIDI, 60 is C4), `name`, `tick` and `duration` (960 ticks per quarter note, from the start of the pattern), `velocity`, `accent` and `staccato`; a chord is one note per pitch. `text` is the note text as written. The list goes back through music.edit set_pattern with `notes` as a list (changing, adding or removing notes), which writes it as note text again. A drum pattern returns its `grid` and `hits`. Example: {"path":"assets/music/theme.song.json","track":"bass","pattern":"line"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command reads. |
| `track` | string | yes | The track. |
| `pattern` | string | yes | The pattern of that track. |

## `music.preview` (modifies state)

Since 0.16.0.

Render a song to a stereo WAV or OGG next to it (offline, deterministic) and see its spectrogram.

Capabilities: read, writeProject

Renders the song at `path` with the preview voices: every note of the arrangement is played by its track's instrument at the note's pitch (a built-in instrument, a preset, or your own .sfx.json patch), with the track's volume, pan, swing and automation lanes and the song's master lanes. The result is a stereo 16-bit WAV at `out` (default: the song's path with .preview.wav; a path ending in .ogg encodes Ogg Vorbis). No provider, no key, no other program: the same song, options and seed give the same bytes on every platform. The file gets provenance and a recipe in assets.json whose inputs are the song and every patch it read, so project.validate warns when they changed after the preview was made and assets.regenerate renders it again. `fromBar` and `bars` render a part, `solo` and `mute` choose tracks, `seed` is another take of the instruments' noise, `sampleRate` 22050, 32000, 44100 (default) or 48000. A song longer than 180 s needs a range. An existing file that music.preview did not make is an `exists` error unless overwrite is true. Example: {"path":"assets/music/theme.song.json","fromBar":5,"bars":4,"solo":["lead"]}

The result has the measurements (lufs, peakDb), the numbers of the file as written (`analysis`) and the spectrogram picture (`$image`). The song's mixer applies: track effects and sends, the buses, the master limiter and the loudness normalization to the style's music loudness; `mix` in the result says what each did (music.mix gives the same without writing a file).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json, e.g. "assets/music/theme.song.json". Path the command reads. |
| `out` | string | no | Where to write the sound: .wav or .ogg under assets/. Default: the song's path with .preview.wav. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `fromBar` | integer | no | First bar rendered, counted from 1 (default 1). Notes that start earlier are not played. |
| `bars` | integer | no | Number of bars rendered from `fromBar` (default: to the end). |
| `solo` | array | no | Render only these tracks. |
| `mute` | array | no | Leave these tracks out. |
| `seed` | integer | no | Added to the song's seed: another take of the instruments' noise. The same seed always gives the same file. Default 0. |
| `sampleRate` | integer [22050,32000,44100,48000] | no | Sample rate of the file. Default 44100. |
| `overwrite` | boolean | no | Replace the file when it exists and was not made by music.preview (one made by it is always replaced). Default false. |
| `picture` | boolean | no | Return the spectrogram picture (`$image`) of the preview. Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `height` | integer | no | Height of the picture in pixels (default 640). |

## `music.render` (modifies state)

Since 0.16.0.

Render a whole song (intro, loop, outro) to a game-ready WAV or OGG with sample-exact loop points, and optionally one stem per layer.

Capabilities: read, writeProject

Renders the song at `path` as music.preview does (same voices, mixer, loudness normalization and limiter) but as an ASSET: the whole song, with the loop points of its `loop` sections. The loop is seamless: the tail of the loop's last bar (reverb, release) is folded onto its first bar, so a looping AudioSource plays `loopStart`..`loopEnd` with no click. The points are the bar boundaries of the loop sections, exact frames, written as `import.loopStart` / `loopEnd` (seconds) in assets.json, which the engine honours, and, for a WAV, in the standard `smpl` chunk; an OGG keeps them in assets.json only. `out` (default: the song's path with .wav) or `format` "wav" / "ogg" choose the file. `stems`: "layers" renders one file per layer of the song's `layers` (the tracks left out form the layer `other`), "tracks" one per track, "buses" the dry tracks and each bus's return; true means "layers". Example: {"path":"assets/music/theme.song.json","stems":"layers"}

A stem is named <out without extension>.stem.<name>.<ext>, has the same length, sample rate and loop points as the mix, and passes through the same buses and master: the stems carry the mix's loudness gain and limiter gain, so their SUM is the mix to within float rounding (below -80 dBFS) when the buses and the master hold only linear effects; a compressor, distortion or bitcrush there acts on the sum and the result's stemSum says by how much the sum differs. Add them with gain 1 and clip nothing: a stem can pass 0 dBFS when the others cancel it. Every written file gets provenance and the same recipe in assets.json (inputs: the song, every .sfx.json patch and SoundFont it reads; context: the style guide's music loudness when the song's master loudness is "style"), so project.validate warns when any of them changed and assets.regenerate makes the files again; running music.render again updates them in place (a stem of a layer you removed is deleted). `import.music` of each entry says what it is: {role: "mix", song, stemGrouping, stems: [{name, path, kind, intensity, tracks, buses}]} or {role: "stem", song, mix, name, kind, intensity, tracks, buses}; intensity (0..1) is when a layered player brings the stem in. `sampleRate` 22050, 32000, 44100 (default, exact loop frames in the engine) or 48000; `seed` another take of the instruments' noise; `loop` false renders the song once with no loop points. An existing file that music.render did not make is an `exists` error unless overwrite is true.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The song, project-relative, under assets/ and ending in .song.json. Path the command reads. |
| `out` | string | no | Where to write the mix: .wav or .ogg under assets/. Default: the song's path with .wav (or .ogg when `format` says so). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `format` | string ["wav","ogg"] | no | File format when `out` is not given. wav is lossless and holds the loop points in a smpl chunk; ogg is smaller. |
| `sampleRate` | integer [22050,32000,44100,48000] | no | Sample rate of the files. Default 44100. |
| `seed` | integer | no | Added to the song's seed: another take of the instruments' noise. Default 0. |
| `loop` | boolean | no | Find the song's loop sections, fold their tail onto the start and write the loop points. False: render once, no points. Default true. |
| `stems` | any | no | One file per stem: "layers" (the song's `layers`), "tracks" or "buses"; true = "layers"; false or absent: only the mix. |
| `overwrite` | boolean | no | Replace files that exist and were not made by music.render (the ones it made are always replaced). Default false. |

## `music.scale`

Since 0.16.0.

Say which notes a scale or mode has and the chords built on its degrees (with Roman numerals).

Capabilities: read

With `key` and `mode` returns the scale's notes, intervals, and the triads and seventh chords on every degree labelled with Roman numerals (the same names a progression accepts). With no arguments it lists every scale the notation knows. Example: {"key":"D","mode":"dorian"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `key` | string | no | Tonic, a note name such as "A" or "Bb". Default C. |
| `mode` | string | no | Scale name: major, minor, dorian, ... Default major. |

## `rig.bake` (modifies state)

Since 0.16.0.

Fit rig documents to their models and write the skinned .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.

Capabilities: read, writeProject

Without `path` this bakes every *.rig.json of the project whose .glb is missing or out of date (the rig document, its model document or a file they read changed: the recipe's hashes), like model.bake. With `path` it bakes that document. The .glb is the model's mesh exactly as model.bake writes it plus one glTF skin: a node per bone named like the bone (translation = head minus the parent's head, extras {role, and index and side when the bone has them}), inverseBindMatrices that make the rest pose draw the model unchanged, and JOINTS_0 / WEIGHTS_0 with up to four normalised influences per vertex, computed from the document's `skin` section (automatic heat-diffusion weights, rigid parts, and the edits skin3d.* wrote; deterministic). The origin follows the model's gameReady.origin; a textured model uses the picture its own bake made (bake the model first). The same inputs give the same bytes. assets.json records provenance and the recipe, so assets.regenerate and project.validate know when it is stale. A file that nothing baked is never replaced unless overwrite is true. `mergeParts` joins parts that share a material (fewer draw calls). Example: {} or {"path":"assets/models/hero.rig.json"}

`mergeParts` welds the skinned parts that share a material into one submesh after the fit (a rigged character of 8 parts with 2 materials then draws in 2 calls per pass instead of 8): only the index list is regrouped, so the weights, joints and bind pose are the same and a posed frame looks the same; the result lists `submeshesBefore` and `submeshes`, and the part names of a merged submesh are joined with "+". The choice is kept in the recipe, so a later bake or `factoria export` repeats it. `factoria export` bakes the stale documents first.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Bake only this document (project-relative, ending in .rig.json). Leave out for every document. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `force` | boolean | no | Bake documents that are fresh too. Default false. |
| `dryRun` | boolean | no | List what would be baked and why, and write nothing. Default false. |
| `overwrite` | boolean | no | Replace a file at the output that no rig document baked. Default false. |
| `mergeParts` | boolean | no | Weld the skinned parts that share a material into one submesh (fewer draw calls). Left out: what the last bake of the document used (false the first time); the choice is kept in the recipe. |

## `rig.create` (modifies state)

Since 0.16.0.

Write a rig document for a model: a skeleton template (humanoid, quadruped, bird, tail, chain, generic) fitted to the model by its parts and landmarks, and bake it to a skinned .glb.

Capabilities: read, writeProject

Writes `path` (*.rig.json under assets/) that names the model document (`model`) and a `template`, with the template's `options` (rig.templates lists them: spine, neck and tail bone counts, toes, pose, segments, axis), optional `parts` ({bone: [model parts]}: which parts decide where a bone is, when their names do not say) and `landmarks` ({bone: [x,y,z], "<bone>.tail": [x,y,z]}: explicit joint positions in the model's space). The template is fitted to the model before anything is written (a fit that cannot be made fails and writes nothing): the answer lists every bone with its head and tail, whether each came from a part, the geometry or an estimate, which parts each bone follows, the parts nobody used and the warnings (a landmark that could not be found says what to name or give). A `generic` rig gets one bone per part of the model under `root`; edit the bones in the file. Example: {"path":"assets/models/hero.rig.json","model":"assets/models/hero.model.json","template":"humanoid","options":{"spine":4}}

Unless bake is false it is baked: <name>.rig.glb next to the document is the model with a glTF skin (joints named like the bones, rest pose = the model's pose); its vertices are bound to the bones with automatic skin weights (heat diffusion by default, rigid per part for a generic rig; the document's `skin` section and the skin3d.* commands change them, docs/RIGGING.md). The model must be a model document (*.model.json).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `model` | string | yes | The model document to fit, project-relative, ending in .model.json. Path the command reads. |
| `template` | string ["humanoid","quadruped","bird","tail","chain","generic"] | yes | The skeleton template. |
| `options` | object | no | The template's options, e.g. {"spine":4,"tail":3} (rig.templates {} lists them); the rest keep their defaults. |
| `parts` | object | no | {bone: part name or list of part names}: the model parts that decide where a bone is. Normally the fit recognises parts by their names. |
| `landmarks` | object | no | {bone or "bone.tail": [x,y,z]}: explicit joint positions in the model's space; they win over everything the fit finds. |
| `strict` | boolean | no | Make a landmark that could only be estimated from proportions an error instead of a warning (default false). |
| `output` | object | no | {path: where to bake, under assets/, ending in .glb}. Default: <name>.rig.glb next to the document. |
| `skin` | object | no | The document's `skin` section: {method: auto\|heat\|voxel\|rigid, maxInfluences, smooth, maxHops, locality, parts: {part: {method, bone}}, edits}. Left out: automatic weights. skin3d.* edits it afterwards (docs/RIGGING.md). |
| `doc` | string | no | A note on what the rig is for. |
| `overwrite` | boolean | no | Replace the document when it exists (and the .glb when nothing baked it). Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |

## `rig.fit` (modifies state)

Since 0.16.0.

Change what a rig document tells the fit (parts, landmarks, options, symmetry, strict), fit the template to the model again and show what it matched; then bake.

Capabilities: read, writeProject

Reads `path` (*.rig.json), applies the changes you give, checks the document as a whole and fits the template to the model with the changes (a bad bone or part name, or a fit that cannot be made, fails with the issues, their JSON pointers and a "did you mean", and writes nothing), writes it and answers with the fit: each bone's head and tail and where it came from (override, part, geometry, proportion = estimate), the parts each bone follows (`matched`), the bones that follow no part, the parts no bone used and the warnings. `parts` and `landmarks` are merged key by key: a value sets that bone, null removes it, null as the whole value removes them all. Use `parts` when a part's name does not say which bone it is ({"arm_l": ["sleeve_left"]}), `landmarks` when a joint is somewhere the fit cannot know ({"head": [0, 1.62, 0.03], "head.tail": [0, 1.9, 0.03]}); `strict` makes every estimated joint an error so nothing is silently guessed. With nothing to change this only shows the fit. dryRun shows the fit the changes would give without writing. Unless bake is false the skinned .glb is baked again after a change. Example: {"path":"assets/models/hero.rig.json","landmarks":{"neck":[0,1.55,0]},"strict":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `parts` | any | no | {bone: part name or list of part names}; a null value removes that bone's entry, null removes all of them. |
| `landmarks` | any | no | {bone or "bone.tail": [x,y,z]}; a null value removes that landmark, null removes all of them. |
| `options` | any | no | The template's options to change (rig.templates {} lists them); null as a value returns one to its default. |
| `symmetryX` | any | no | The x of the symmetry plane left and right bones mirror about. Null: the centre of the model's bounds. |
| `strict` | boolean | no | Make estimated landmarks errors: true or false, left as it is when not given. |
| `skin` | any | no | Fields of the document's `skin` section to set ({method, maxInfluences, smooth, maxHops, locality, parts, edits}); a field given replaces that field, null removes it. skin3d.* edits the weights one operation at a time. |
| `dryRun` | boolean | no | Fit with the changes but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |

## `rig.info`

Since 0.16.0.

Check a rig document and fit it to its model without writing anything: every issue with its fix, the bones, where each joint came from and what the fit noticed.

Capabilities: read

Reads `path` (*.rig.json). A document with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and the fix (a bone or part name that does not exist gets a "did you mean"). A valid one returns where it bakes to and whether that .glb is fresh or stale, and (unless fit is false) the fit: for each bone its head and tail in the model's space and where they came from (override = the document's landmarks, part = a model part named for the bone, geometry = measured from the mesh, proportion = an ESTIMATE from the template's default proportions), which model parts each bone follows (`matched`), the parts no bone looked at (`unusedParts`) and the warnings. A fit that cannot be made returns state failed with the reason. Example: {"path":"assets/models/hero.rig.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command reads. |
| `fit` | boolean | no | Fit the template to the model for the report (evaluates the model). Default true. |

## `rig.templates`

Since 0.16.0.

List the skeleton templates (humanoid, quadruped, bird, tail, chain, generic) with their options and the words in part names they recognise; with `name`, the bones of one.

Capabilities: read

A rig document (`*.rig.json`, docs/RIGGING.md) fits a skeleton template to a model. Every template names its bones the same way, `<role>[_<index>][_<side>]` (root, spine_1, neck, head, clavicle_l, arm_upper_l, arm_lower_l, hand_l, thigh_l, shin_l, foot_l, toe_l, tail_1...), and the (role, index, side) triple is what retargeting between templates maps. With no argument this returns the catalog: for each template what it is for, the pose it assumes, its options (spine, neck, tail, toes, pose, segments, axis) with range and default, and the words in a model part name that tell the fit which bone it is ("arm_l", "left leg", "head"...). With `name` (and optionally `options`) it returns the bones that template has for those options, in order (parents first): name, role, index, side, parent, leaf, and the landmark names a rig document's `landmarks` may use ("<bone>" for a joint, "<bone>.tail" for the end of a leaf bone). Example: {"name":"quadruped","options":{"tail":6}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | The template: humanoid, quadruped, bird, tail, chain or generic. Leave out for the catalog. |
| `options` | object | no | The template's options (rig.templates {} lists them), to see the bones they give. |

## `sfx.bake` (modifies state)

Since 0.16.0.

Render every sound patch of the project whose WAV is missing or out of date.

Capabilities: read, writeProject

Finds every assets/**/*.sfx.json and renders the ones whose sound (the patch's path with .wav) does not exist, or was made by sfx.render from a patch that has changed since (the recipe's input hash differs: the same check project.validate does). Sounds that are up to date are left alone, a file at that path that sfx.render did not make is skipped and reported, and a patch with mistakes is listed in `failed` with its issues while the others are still baked. An existing recipe keeps its own arguments (seed, note, macros, an .ogg `out`). A patch with `variations` is baked with all its takes (name_01.wav ... each with a recipe of its own). `macros` replaces the macro values of every render in this call (it forces them and is kept in the recipes). `path` (one patch or a list) bakes only those patches, with the same rules (stale or missing only, `force` renders them anyway). No pictures are returned; use sfx.render for one patch. Example: {"dryRun":true} lists what would be rendered.

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Render every patch again, even when its sound is up to date. Default false. |
| `path` | any | no | Bake only this patch (assets/audio/jump.sfx.json) or this list of patches, not every patch of the project. Path the command reads. |
| `macros` | object | no | Macro values for every sound rendered by this call, e.g. {"weight": 0.4}. Forces the render and is kept in the recipes. |
| `dryRun` | boolean | no | List what would be rendered and why, and write nothing. Default false. |

## `sfx.edit` (modifies state)

Since 0.16.0.

Change one field of a sound patch by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid patch.

Capabilities: read, writeProject

Edits `*.sfx.json` the way a hand edit would, but checked: the patch is parsed again after the change and, when it would be invalid, nothing is written and the error lists the issues with their pointers. op `set` writes `value` at `pointer` (an existing object's field, new or old); `remove` deletes the field or array element at `pointer`; `add` inserts `value` into the array at `pointer` (at `index`, default the end); `move` takes element `index` of the array at `pointer` to place `to`. Nothing is rendered: call sfx.render or sfx.bake afterwards. Example: {"path":"assets/audio/coin.sfx.json","op":"set","pointer":"/oscillators/0/wave","value":"square"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The sound patch, project-relative, ending in .sfx.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `op` | string ["set","remove","add","move"] | yes | What to do. |
| `pointer` | string | yes | JSON pointer into the patch, e.g. /oscillators/0/wave or /effects. |
| `value` | any | no | The new value (set) or the element to insert (add). Any JSON. |
| `index` | integer | no | add: where to insert; move: the element to move. |
| `to` | integer | no | move: the element's new place. |

## `sfx.family` (modifies state)

Since 0.16.0.

Make a consistent set of interface sounds (click, hover, confirm, cancel, error, open, close, notify) from one base patch.

Capabilities: read, writeProject

Writes one patch per sound into the `out` directory (default: the base's path without .sfx.json plus _family), each a COPY of the base patch `from` with what that role changes: its length and tail, macros (brighter for a hover, heavier and gritty for an error), an arpeggio (confirm goes up, cancel down) or a pitch slide (open up, close down). They share the base's oscillators, filters, effects and master.normalize, so they share timbre and loudness; being copies they stand alone (editing the base later does not change them; make the family again with overwrite: true). Names: click, hover, confirm, cancel, error, open, close, notify; `preset: "ui"` makes all eight. Unless `render` is false each is baked to name.wav with a recipe (so sfx.bake keeps them current). The result lists the measurements of each (lufs, peakDb, seconds, centroidHz), the spread of loudness in LU, and one picture with a row per sound. Example: {"from":"assets/audio/ui.sfx.json","preset":"ui"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | string | yes | The base patch, project-relative, ending in .sfx.json: the timbre every sound shares. Path the command reads. |
| `names` | array | no | Which sounds to make: click, hover, confirm, cancel, error, open, close, notify. |
| `preset` | string | no | "ui": make all eight sounds. Give this or `names`. |
| `out` | string | no | Directory under assets/ for the patches (and their sounds). Default: the base's path without .sfx.json plus _family. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace patches and sounds that exist. Default false. |
| `render` | boolean | no | Bake each sound to a WAV too (default); false writes only the patches and measures them in memory. Default true. |
| `picture` | boolean | no | Return the contact sheet (`$image`): one row per sound. Default true. |
| `pictureOut` | string | no | Also keep the sheet's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |

## `sfx.info`

Since 0.16.0.

Check a sound patch and say what it holds and how loud it renders, without writing anything.

Capabilities: read

Reads a sound patch from `path`, or takes it inline as `patch` (JSON) or by `preset` name, and checks it against the format (docs/SOUND.md). A patch with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and how to fix it, so one call is enough to repair it. A valid patch returns its layers (oscillators, start, pitch), its effects, the base pitch (rootHz), its macros (the declared values) and variations (count and the files they bake to), whether its baked sound exists and is stale, and the loudness, peak, length, brightness (centroidHz) and attack (riseSeconds) it renders to (it is rendered in memory; nothing is written). Example: {"path":"assets/audio/coin.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | A sound patch file, project-relative, ending in .sfx.json. Path the command reads. |
| `patch` | object | no | The patch itself, as JSON, to check before writing it to a file. |
| `preset` | string | no | The name of a preset (see sfx.preset). |
| `seed` | integer | no | Render this take for the measurements (default 0). |

## `sfx.preset` (modifies state)

Since 0.16.0.

List the sound presets, return one as an editable patch, or write it to a *.sfx.json file.

Capabilities: read, writeProject

The presets of assets.synth_sound (bark, growl, meow, screech, whoosh, explosion, hit, coin, pickup, jump, powerup, laser, blip, click, error, splash, footstep) are sound patches shipped in the engine. Without `name` this lists them. With `name` it returns the patch (the exact JSON that renders): read it to learn the format, or change it. With `name` and `path` it writes the patch to that *.sfx.json file under assets/ (an existing file is an error unless overwrite is true), ready for sfx.render. Example: {"name":"laser","path":"assets/audio/laser.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | The preset to return. Leave out to list them all. |
| `path` | string | no | Write the patch here: project-relative, under assets/, ending in .sfx.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the file when it exists. Default false. |

## `sfx.render` (modifies state)

Since 0.16.0.

Render a sound patch (*.sfx.json) to a WAV or OGG next to it and see its spectrogram: the engine's own synthesizer, offline and deterministic.

Capabilities: read, writeProject

Reads the sound patch at `path` (assets/.../name.sfx.json, format factoria.sfx/1: layers of oscillators with envelopes, pitch sweeps and arpeggios, filters, FM and ring modulation, distortion, bitcrush, delay and reverb; docs/SOUND.md and schemas/sfx.schema.json) and renders it to mono 16-bit WAV at `out` (default: the patch's path with .wav; a path ending in .ogg encodes Ogg Vorbis). No provider, no key, no other program: the same patch, `seed` and options give the same bytes on every platform. The sound is levelled to the patch's normalization (default -18 LUFS, peak under -1 dBFS). The file gets provenance and a recipe in assets.json whose input is the patch, so project.validate warns when the patch changed after the sound was made and assets.regenerate renders it again. A patch with mistakes fails with `invalid_patch` and every problem in data.issues (JSON pointer, what is wrong, how to fix it). The result has measurements (lufs, peakDb, seconds), the numbers of the file as written (`analysis`, from assets.spectrogram) and the picture (`$image`): waveform, spectrogram and loudness curve. Example: {"path":"assets/audio/coin.sfx.json"}

Options that change one render without editing the patch: `seed` (another take of the noise), `freq` or `note` (transpose so the patch's base pitch becomes this), `length`, `tail`, and `macros` (meaning knobs from -1 to 1: attack, brightness, weight, tail, pitch, grit, plus the patch's own; they replace the values the patch declares). A patch that declares `variations` renders one take with `variant` (1-based; the file is name_NN.wav) or all of them with `variants: true`, which returns the measurements of each and one picture with a row per variant. The measurements also have centroidHz (the brightness) and riseSeconds (the attack). An existing file that sfx.render did not make is an `exists` error unless overwrite is true.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The sound patch, project-relative, under assets/ and ending in .sfx.json, e.g. "assets/audio/coin.sfx.json". Path the command reads. |
| `out` | string | no | Where to write the sound: .wav or .ogg under assets/. Default: the patch's path with .wav. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `seed` | integer | no | Added to the patch's seed: another take of every noise. The same seed always gives the same file. Default 0. |
| `freq` | number | no | Transpose the patch so its base pitch (the first pitched layer's pitch.freq) becomes this frequency in Hz. Fixed-frequency oscillators stay. |
| `note` | string | no | The same as freq as a note name: "C4" (middle C), "A4" (440 Hz), "C#3", "Bb2". |
| `length` | number | no | Seconds the sound is held, replacing the patch's `length` for this render. |
| `tail` | number | no | Seconds after the length for releases, echoes and reverb, replacing the patch's `tail`. |
| `macros` | object | no | Macro values for this render, e.g. {"brightness": 0.3, "tail": -0.5}: attack, brightness, weight, tail, pitch, grit or a macro the patch declares. Replaces the patch's declared value; kept in the recipe. |
| `variant` | integer | no | Render this variation (1-based) of a patch that declares `variations`; the default out is name_NN.wav. |
| `variants` | boolean | no | Render every variation of the patch to name_01.wav, name_02.wav... and return one picture with a row per variant. Takes neither `out` nor `variant`. Default false. |
| `picture` | boolean | no | Return the spectrogram picture (`$image`) of the sound. Turn it off when rendering many. Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Default: a temporary screenshot. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `height` | integer | no | Height of the picture in pixels (default 640). |
| `overwrite` | boolean | no | Replace the sound when it exists and was not made by sfx.render (a sound made by it is always replaced). Default false. |

## `sfx.tweak` (modifies state)

Since 0.16.0.

Turn a patch's macros by meaning (brighter, longer tail, heavier) and write the change back to the patch.

Capabilities: read, writeProject

`macros` is {name: amount}: attack, brightness, weight, tail, pitch, grit (each from -1 to 1; 0 is the patch as written) or a macro the patch declares. Each amount is ADDED to the value the patch declares now (+0.2 brighter than it is), or is the new value when `absolute` is true; the result is clamped to -1..1 and written to the patch's `macros` (the file is rewritten with the same keys in the same order). Then the sound (and its variations) is rendered again and the result compares the measurements before and after: centroidHz rises with brightness, seconds with tail, riseSeconds with a slower attack. An unknown macro is an error with a 'did you mean'. Example: {"path":"assets/audio/coin.sfx.json","macros":{"brightness":0.2}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The sound patch, project-relative, ending in .sfx.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `macros` | object | yes | Macro name to amount, e.g. {"brightness": 0.2, "tail": -0.3}. |
| `absolute` | boolean | no | Set the macros to these values instead of adding to the declared ones. Default false. |
| `render` | boolean | no | Render the sound again and compare the measurements. Turn it off to only edit the patch. Default true. |
| `seed` | integer | no | Seed of the renders (default 0). |
| `picture` | boolean | no | Return the spectrogram picture (`$image`). Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `width` | integer | no | Width of the picture in pixels. |
| `height` | integer | no | Height of the picture in pixels. |

## `skin3d.add` (modifies state)

Since 0.16.0.

Add weight to a bone (or take it away with a negative amount) on the vertices of a part or a selection.

Capabilities: read, writeProject

Adds `amount` (-1 to 1) to the weight of `bone` on each vertex, then normalises (a vertex keeps at most the document's `maxInfluences` strongest bones, the others are dropped). A positive amount makes the bone pull the vertices harder, a negative one releases them from it. Example: {"path":"assets/models/hero.rig.json","bone":"spine_2","amount":0.3,"select":{"by":"box","min":[-0.3,1.2,-0.2],"max":[0.3,1.4,0.2]}}. The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `bone` | string | yes | The bone whose weight changes. |
| `amount` | number | yes | Added to the bone's weight, -1 to 1. |

## `skin3d.auto` (modifies state)

Since 0.16.0.

Choose how the weights are computed (auto, heat, voxel, rigid), for the whole rig or one part, and their settings; recompute and bake.

Capabilities: read, writeProject

Changes the `skin` section of a rig document. `method`: auto (heat diffusion; a generic rig, whose bones were placed on parts, is rigid per part), heat (bone heat diffusion on the surface: smooth weights that follow the shape; works on the meshes the engine makes, SDF creatures included), voxel (distance along a voxelised copy of the surface: needs no manifold mesh; what a part falls back to when the heat solve cannot converge) or rigid (the whole part follows ONE bone: robot style). With `part` the method is that part's only (`bone` is the bone it follows: rigid = the one bone, heat and voxel = the bone the part is centred on; without `method` and `bone` the part's override is removed). Settings: `maxInfluences` (1 to 4 bones per vertex), `smooth` (passes over the automatic weights, 0 to 8), `maxHops` (a vertex never follows bones further than this many bones from its strongest, 1 to 8) and `locality` (heat: higher hugs each bone, 0.05 to 20). `clearEdits` also removes every edit. Nothing is written if a part or bone is wrong. Examples: {"path":"assets/models/robot.rig.json","part":"claw","method":"rigid","bone":"arm_lower_l"}, {"path":"assets/models/hero.rig.json","smooth":3,"locality":1.5}.

The weights are computed before anything is written (a bad part or bone fails and writes nothing), the .glb is baked again unless bake is false, and the answer has the `quality` of the weights.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `method` | string ["auto","heat","voxel","rigid"] | no | The method: for every part, or for `part` when given. |
| `part` | string | no | A model part to give its own method (and bone). Without `method` and `bone` its override is removed. |
| `bone` | string | no | With `part`: the bone the part follows (rigid) or is centred on (heat, voxel). |
| `maxInfluences` | integer | no | Bones per vertex, 1 to 4. |
| `smooth` | integer | no | Smoothing passes over the automatic weights, 0 to 8. |
| `maxHops` | integer | no | A vertex does not follow bones further than this many bones from its strongest one, 1 to 8. |
| `locality` | number | no | Heat diffusion: higher = weights hug each bone (shorter blends), lower = longer blends. 0.05 to 20 (default 1). |
| `clearEdits` | boolean | no | Also remove every edit (skin.edits). Default false. |
| `dryRun` | boolean | no | Compute the weights with the change and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |

## `skin3d.clear` (modifies state)

Since 0.16.0.

Remove one edit (by index) or all the edits from a rig document's skin, recompute and bake.

Capabilities: read, writeProject

Removes `index` (as skin3d.info and the answer of an edit command number them) or, without it, every entry of `skin.edits`; the automatic weights and the per-part methods stay. The weights are recomputed and the .glb is baked again unless bake is false. Example: {"path":"assets/models/hero.rig.json","index":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `index` | integer | no | The edit to remove (0 is the first); left out: every edit. |
| `dryRun` | boolean | no | Report without writing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |

## `skin3d.info`

Since 0.16.0.

Show a rig document's skin: the method, its settings and edits, the bones with the parts they follow, and the quality of the weights it gives.

Capabilities: read

Reads `path` (*.rig.json), fits the rig and computes the weights of its `skin` section. Returns the effective settings (`skin`: method, maxInfluences, smooth, maxHops, locality and the per-part overrides), the `edits` with their index (skin3d.clear removes one), the `bones` with their parent and the model parts each follows, the `quality` of the weights and the state of the baked .glb. `quality` counts vertices without weight (`unweighted`: they follow the nearest bone), the most influences any vertex has, `farBlends` (vertices blending bones more than `maxHops` apart in the hierarchy), the vertices led by each bone (`boneVertices`; `idleBones` lead none), the method used per part, the heat solver's pieces and the `warnings` (each says what to change). Nothing is written. Example: {"path":"assets/models/hero.rig.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command reads. |

## `skin3d.limit` (modifies state)

Since 0.16.0.

Keep at most N influences per vertex (1 to 4) on a part or a selection, strongest first, and normalise.

Capabilities: read, writeProject

Keeps the `max` strongest bones of each vertex (1 to 4, default 4) and renormalises. max 1 makes the selection rigid per vertex. Example: {"path":"assets/models/hero.rig.json","max":2,"part":"hand_l"}. The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `max` | integer | no | Influences kept per vertex, 1 to 4 (default 4). |

## `skin3d.mirror` (modifies state)

Since 0.16.0.

Copy the weights of one side of the character to the other (_l to _r or the other way), pairing each vertex with its mirror image.

Capabilities: read, writeProject

Copies the weights from the side `from` ("l" = the character's left, +X; "r" = right) to the opposite side: each vertex is paired with the vertex nearest to its mirror image across the symmetry plane (`symmetryX` of the rig document, else the centre of the model's bounds), preferring one of the mirrored part, and takes its weights with every bone swapped for its opposite (arm_upper_l <-> arm_upper_r; bones on the centre line keep themselves). Vertices with no partner within a tolerance are left as they were and counted in `quality.mirrorUnmatched`. Use it after hand-editing one arm. Example: {"path":"assets/models/hero.rig.json","from":"l"}.

 The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `from` | string ["l","r"] | yes | The side whose weights are copied to the other: l (+X) or r (-X). |

## `skin3d.normalize` (modifies state)

Since 0.16.0.

Drop negligible influences and make each vertex's weights sum to 1, on a part or a selection.

Capabilities: read, writeProject

Removes the influences under `threshold` (0 to 0.5, default 0.01) and rescales what is left to sum to 1. A vertex whose weights are all under the threshold keeps its strongest bone. Example: {"path":"assets/models/hero.rig.json","threshold":0.05}. The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `threshold` | number | no | Influences under this weight are dropped, 0 to 0.5 (default 0.01). |

## `skin3d.preview` (modifies state)

Since 0.16.0.

Draw the skin weights of a rig: a heat map of one bone or one colour per bone, and optionally the model bent at a bone to see how the skin deforms; returns the PNG.

Capabilities: read, state

The way to SEE the weights. It fits the rig, computes the weights of the document's `skin` section (edits included) and draws the model with the software renderer of model.preview (no graphics device, the same pixels everywhere), from `views` sides. With `bone` (mode "heat"): the weights of that bone as a heat map, blue 0 to red 1, so a blend that is too long, too short or on the wrong limb is visible. Without it (mode "bones"): each vertex has the weighted mix of its bones' colours, with a legend of the bones. `pose` ({"arm_lower_l":60} or [{bone, degrees, axis:[x,y,z]}]) bends bones about the axis perpendicular to the bone (a knee or an elbow; `axis` overrides it), taking their children along, and adds a second row with the model deformed by linear blend skinning the way the .glb would deform it: creases, stretched triangles and parts left behind are what a bad skin looks like. The answer has the weights' `quality` and, for one bone, how many vertices it has weight on. The picture is returned as $image in a temporary file; pass `out` (a project-relative .png; needs the writeProject capability) to keep it. Nothing in the project changes otherwise. Example: {"path":"assets/models/hero.rig.json","bone":"arm_lower_l","pose":{"arm_lower_l":70}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command reads. |
| `bone` | string | no | Draw the weights of this bone as a heat map. |
| `mode` | string ["heat","bones"] | no | heat (needs `bone`; the default with it) or bones (one colour per bone; the default without). |
| `pose` | any | no | Bones to bend: {bone: degrees} or a list of {bone, degrees, axis}. Adds a row with the deformed model. |
| `views` | integer | no | How many sides to draw, 1 to 6 (default 3). |
| `yaw` | number | no | The angle of the first view in degrees: 0 looks at the model's +Z side (default 20). |
| `pitch` | number | no | Degrees above the horizon (default 12). |
| `cell` | number | no | Pixels per side of each view (default 280). |
| `out` | string | no | Keep the picture as a PNG at this project-relative path (ending in .png; never inside .git or .factoria). Left out, it is a temporary file. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace the file at `out` if it exists. Default false. |

## `skin3d.set` (modifies state)

Since 0.16.0.

Give a bone an exact weight on the vertices of a part or a selection; the other bones share the rest.

Capabilities: read, writeProject

Sets the weight of `bone` to `weight` (0 to 1; default 1: the vertices follow only that bone) and scales the other influences of each vertex to share what is left in their proportions. A vertex whose only influence was the bone keeps it at 1. Use it to pin a hand to its bone, a sleeve to an arm or free a vertex from a bone (weight 0). The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing. Example: {"path":"assets/models/hero.rig.json","bone":"hand_l","weight":1,"part":"glove_l"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `bone` | string | yes | The bone whose weight is set. |
| `weight` | number | no | The weight it gets, 0 to 1 (default 1). |

## `skin3d.smooth` (modifies state)

Since 0.16.0.

Smooth the weights over the surface on the vertices of a part or a selection, to soften a crease at a joint.

Capabilities: read, writeProject

Moves the weights of each vertex towards the average of the vertices that share an edge with it (welded by position, so seams do not break it): `iterations` passes of `strength` (0 to 1). The neighbours outside the selection take part, so the border blends in. Example: {"path":"assets/models/hero.rig.json","part":"arm_lower_l","iterations":3}. The vertices it works on are those of `part` and of the faces `select` matches (both given: the vertices in both; neither: every vertex); `select` is a face query of the model document (model.select_info). The edit is appended to the rig document's `skin.edits` (applied in order after the automatic weights, so it survives a re-bake), the weights are computed with it before anything is written (a bone or part that does not exist fails with a "did you mean" and writes nothing), and unless bake is false the skinned .glb is baked again. The answer has the edit, its `index`, how many vertices it changed (`verticesChanged`) and the `quality` of the weights (vertices without weight, most influences, blends across far bones, bones that lead no vertex, warnings). dryRun reports without writing.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The rig document, project-relative, under assets/, ending in .rig.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `part` | any | no | The model part (or list of parts) the edit works on. Combined with `select`: the vertices in both. Left out with no `select`: every vertex. |
| `select` | object | no | A face query of the model document ({"by":"box","min":[x,y,z],"max":[x,y,z]}; model.select_info lists them: box, sphere, halfspace, part, normal, and, or, not...): the edit works on the vertices of the faces it matches. |
| `dryRun` | boolean | no | Compute the weights with the edit and report, but write nothing. Default false. |
| `bake` | boolean | no | Bake the skinned .glb after writing. Default true. |
| `overwrite` | boolean | no | Replace a .glb that no rig document baked. Default false. |
| `iterations` | integer | no | Passes, 1 to 50 (default 1). |
| `strength` | number | no | How far each pass moves a vertex to its neighbours' average, 0 to 1 (default 0.5). |

## `style.ignore` (modifies state)

Since 0.23.0.

Skip style rules for a file, folder or glob (all rules, or only the rules you name); recorded in assets.json style.ignore.

Capabilities: read, writeProject

Adds {path, rules} to `style.ignore` of assets.json, so the style checks (assets.check_art, project.validate) do not judge those rules for the asset. `path` is a project-relative file, a folder ending in a slash ("assets/ui/") or a glob ("assets/fx/**"). `rules` names the rules to skip: outline (outline.color, outline.width), value (value.min, value.max), saturation, lightDirection, texelsPerUnit, pixelArt (pixelArt.edges, pixelArt.colours), palette (palette.offShare); without `rules` every rule is skipped for the path (the old plain-path entry). Naming only the rules that do not fit keeps the others checking, so a real problem is not hidden. assets.check_art still checks a file you name, and lists what it left out under `styleSkipped` with the reason. To skip by kind of asset instead, give it a role: style.set_role or assets.set_provenance `role`. `remove: true` takes an entry (or, with `rules`, those rules of it) back. Example: {"path":"assets/art/flame.png","rules":["texelsPerUnit","lightDirection"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file, folder ending in a slash, or glob (* and ? stay inside a folder, ** crosses folders). |
| `rules` | array | no | Rules to skip: outline, outline.color, outline.width, value, value.min, value.max, saturation, saturation.min, saturation.max, lightDirection, texelsPerUnit, pixelArt, pixelArt.edges, pixelArt.colours, palette, palette.offShare. Omit for every rule. |
| `remove` | boolean | no | Take the entry back (with `rules`: only those rules). Default false. |

## `style.set_role` (modifies state)

Since 0.23.0.

Give every asset that matches a path or glob a role (ui, icon, effect); the style rules that do not apply to the role are turned off for them.

Capabilities: read, writeProject

Writes `style.roles[path] = role` in assets.json. A role names what the picture is for, so the style checks leave out the rules that do not apply to it: ui and icon turn off texelsPerUnit and lightDirection (an interface picture is not on a mesh and is shaded as drawn); effect (a flame, a spark: lit by itself) also turns off outline, value and saturation. The rules that are not turned off keep checking. A role set in an asset's provenance (assets.set_provenance `role`) wins over a glob. assets.check_art lists every skipped rule under `styleSkipped` with the role and where it came from. `remove: true` deletes the glob; a role in an asset's provenance is taken back with assets.set_provenance `role` "". Example: {"path":"assets/ui/**","role":"ui"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file, folder ending in a slash, or glob ("assets/ui/**"). |
| `role` | string ["ui","icon","effect"] | no | What the pictures are for. Required unless `remove`. |
| `remove` | boolean | no | Delete the role of this path. Default false. |

## `vector.add` (modifies state)

Since 0.16.0.

Add a path, rectangle, ellipse or line to an SVG.

Capabilities: read, writeProject

Inserts one new element into an SVG file, SVG text or an svg layer of an image document, at the end of the drawing or of `parent` (or in front of `before`). kind "path" takes `d` (SVG path data); "rect" takes x, y, width, height and cornerRadius and writes a <rect>; "ellipse" takes center, rx and ry (a circle when ry is left out) and writes an <ellipse> or <circle>; "line" takes from and to. Coordinates are in the DRAWING space (the viewBox) by default and are converted into the parent's own space; space "local" (or a `transform`) means the element's own numbers. Style with fill, stroke, strokeWidth, opacity and attributes (same as vector.shape). Open paths and lines get a stroke and no fill by default. Returns the new element's id, its bounds in the drawing and a preview as `$image`. Example: {"source": "assets/art/badge.svg", "kind": "rect", "x": 10, "y": 10, "width": 40, "height": 20, "cornerRadius": 4, "fill": "#d94f4f"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `id` | string | no | The id of the new element (default: the kind, "star", "blob"..., or the next free "star-2"). An id the SVG already uses is an error. |
| `parent` | string | no | An id or selector of ONE group (<g>) to put the element in, at its end. Default: the top level. Coordinates are the parent's own, so a translated or scaled group moves and scales the shape. |
| `before` | string | no | An id or selector of ONE element: the new one goes in front of it in the drawing order (behind it on the picture), in the same group. |
| `transform` | string | no | A transform attribute for the new element, e.g. "rotate(15 50 50)". |
| `fill` | string | no | A CSS fill colour or "none". Default: a blue for closed shapes, none for open curves. |
| `stroke` | string | no | A CSS stroke colour. Default: none for closed shapes, a dark slate for open curves. |
| `strokeWidth` | number | no | Stroke width in the parent's units (default 1% of the drawing's longer side for open curves). |
| `opacity` | number | no | 0 to 1. |
| `attributes` | object | no | Any other attributes of the new element: {"class": "body", "stroke-linejoin": "round"}. |
| `kind` | string ["path","rect","ellipse","line"] | yes | What to add. |
| `space` | string ["drawing","local"] | no | drawing (default): the numbers are in the drawing space and are converted into the parent's. local: the element's own numbers. |
| `d` | string | no | path: the SVG path data. |
| `x` | number | no | rect: the left edge. |
| `y` | number | no | rect: the top edge. |
| `width` | number | no | rect: the width (above 0). |
| `height` | number | no | rect: the height (above 0). |
| `cornerRadius` | number | no | rect: the radius of the rounded corners. |
| `center` | array | no | ellipse: the middle [x, y]. |
| `rx` | number | no | ellipse: the horizontal radius. |
| `ry` | number | no | ellipse: the vertical radius. Default: rx (a circle). |
| `from` | array | no | line: the start [x, y]. |
| `to` | array | no | line: the end [x, y]. |

## `vector.align` (modifies state)

Since 0.16.0.

Align SVG elements to each other, the canvas or a key element.

Capabilities: read, writeProject

Moves the picked elements (shapes or whole groups) so their bounds line up: horizontal left/center/right and/or vertical top/middle/bottom, relative to the selection's bounds, the canvas (the viewBox) or a key element that stays put. Elements are moved by their own transform attribute, so ids, groups and styles stay as they are; parent transforms are honoured. Returns a preview as `$image`. Example: {"source": "assets/art/ui.svg", "elements": ["a", "b", "c"], "vertical": "middle", "to": "key", "key": "a"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to move: SVG ids or selectors. A group moves as one piece (it is measured as the union of its shapes). Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `bounds` | string ["visual","geometry"] | no | What is measured: "visual" (default) includes half the stroke width, "geometry" only the outline of the shapes. |
| `horizontal` | string ["left","center","right"] | no | Align the left edges, the centres or the right edges. |
| `vertical` | string ["top","middle","bottom"] | no | Align the top edges, the middles or the bottom edges. |
| `to` | string ["selection","canvas","key"] | no | What to align to: the bounds of the selection (default with two or more elements), the canvas (default with one element) or the `key` element. |
| `key` | string | no | With to "key" (implied when given): the element the others align to; it does not move. |

## `vector.assign_ids` (modifies state)

Since 0.16.0.

Give every drawn element without an id one.

Capabilities: read, writeProject

Names the shapes and groups that have no id (path, path-2, g, g-2...) so the other vector.* commands can pick them by id; picked `elements` limit it (with what is inside them). Returns the new ids with the selector each one had before. Example: {"source": "assets/art/traced.svg"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |

## `vector.blob` (modifies state)

Since 0.16.0.

Add a smooth organic shape or curve through or around a few points.

Capabilities: read, writeProject

Inserts a smooth closed blob (or, with closed: false, an open curve) built from a few [x, y] points. fit "through" (default): the curve passes through every point as a cardinal spline, `tension` 0 (straight lines) to 1.5, 0.5 is the usual smooth curve. fit "around": the points are a control polygon, a uniform B-spline that stays inside it and never touches it, always smooth. A closed blob needs 3 points, an open curve 2 and gets a stroke and no fill by default. Same placement arguments as vector.shape. Returns the new element and a preview as `$image`. Example: {"source": "assets/art/cloud.svg", "points": [[20,60],[35,35],[60,30],[80,50],[70,75],[40,80]], "tension": 0.6, "fill": "#e8eef7"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `id` | string | no | The id of the new element (default: the kind, "star", "blob"..., or the next free "star-2"). An id the SVG already uses is an error. |
| `parent` | string | no | An id or selector of ONE group (<g>) to put the element in, at its end. Default: the top level. Coordinates are the parent's own, so a translated or scaled group moves and scales the shape. |
| `before` | string | no | An id or selector of ONE element: the new one goes in front of it in the drawing order (behind it on the picture), in the same group. |
| `transform` | string | no | A transform attribute for the new element, e.g. "rotate(15 50 50)". |
| `fill` | string | no | A CSS fill colour or "none". Default: a blue for closed shapes, none for open curves. |
| `stroke` | string | no | A CSS stroke colour. Default: none for closed shapes, a dark slate for open curves. |
| `strokeWidth` | number | no | Stroke width in the parent's units (default 1% of the drawing's longer side for open curves). |
| `opacity` | number | no | 0 to 1. |
| `attributes` | object | no | Any other attributes of the new element: {"class": "body", "stroke-linejoin": "round"}. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `points` | array | yes | The points the curve goes through or around, in order (3 or more when closed, 2 or more when open). |
| `closed` | boolean | no | A closed blob (default) or an open curve. Default true. |
| `fit` | string ["through","around"] | no | through: the curve passes through the points (default). around: the points are a control polygon the curve stays inside of. |
| `tension` | number | no | With fit "through": 0 straight lines, 0.5 smooth (default), up to 1.5 loose and overshooting. |

## `vector.boolean` (modifies state)

Since 0.16.0.

Union, subtract, intersect or exclude SVG shapes into one path.

Capabilities: read, writeProject

Combines the picked shapes with a path boolean (Clipper2, integer-exact) and writes the result as ONE <path> whose curves are cubic Beziers again (the polygon the operation computes is refitted). The first shape keeps its id, style, transform and place in the drawing and takes the new outline; the others are removed (keepInputs: true keeps them). `union` merges all; `subtract` removes the later shapes from the first; `intersect` keeps what all cover; `exclude` keeps what an odd number of them cover. Transforms of the shapes and their groups are honoured: each shape is measured in the drawing space and the result is written back in the first shape's own space. fill-rule is read per shape. Returns a rasterized preview as `$image`. Example: {"source": "assets/art/badge.svg", "op": "subtract", "elements": ["disc", "hole"]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `op` | string ["union","subtract","intersect","exclude"] | yes | The path operation. |
| `keepInputs` | boolean | no | Keep the other shapes instead of removing them (the result still goes into the first). Default false. |

## `vector.delete` (modifies state)

Since 0.16.0.

Delete SVG elements.

Capabilities: read, writeProject

Removes the picked shapes or groups (a group takes everything in it). The rest of the drawing is not touched. Returns the removed refs and a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["hole"]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |

## `vector.distribute` (modifies state)

Since 0.16.0.

Space SVG elements evenly along an axis.

Capabilities: read, writeProject

Moves the picked elements along `axis` so the gaps between them (by: "gaps", default) or their centres (by: "centers") are equal; the first and the last stay put. With `spacing` the gap is fixed instead and the first element stays. Elements are ordered by position, and moved by their own transform attribute. Returns a preview as `$image`. Example: {"source": "assets/art/row.svg", "elements": ["i1", "i2", "i3", "i4"], "axis": "horizontal"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to move: SVG ids or selectors. A group moves as one piece (it is measured as the union of its shapes). Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `bounds` | string ["visual","geometry"] | no | What is measured: "visual" (default) includes half the stroke width, "geometry" only the outline of the shapes. |
| `axis` | string ["horizontal","vertical"] | yes | The direction to spread along. |
| `by` | string ["gaps","centers"] | no | Equal gaps between the elements' edges (default) or equal distance between their centres. |
| `spacing` | number | no | A fixed gap between neighbouring elements, in drawing units (negative overlaps). The first element stays; the rest follow. |

## `vector.duplicate` (modifies state)

Since 0.16.0.

Copy SVG elements right after the originals.

Capabilities: read, writeProject

Inserts a copy of each picked element (shape or group, with everything in it) right after it, with new ids (<id>-copy, <id>-copy-2...). `offset` [dx, dy] moves the copies in the drawing space. Returns the pairs {from, to} and a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["star"], "offset": [12, 12]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `offset` | array | no | Move the copies by [dx, dy] in the drawing space. |

## `vector.group` (modifies state)

Since 0.16.0.

Wrap SVG elements in a new group.

Capabilities: read, writeProject

Puts the picked elements (all in the same group) into a new <g>, which takes the place of the topmost one; their order, ids and transforms stay. `id` names the group (default group, group-2...). Returns the group and a preview as `$image`. Example: {"source": "assets/art/face.svg", "elements": ["eye-l", "eye-r"], "id": "eyes"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `id` | string | no | The id of the new group. |

## `vector.info`

Since 0.16.0.

List the shapes and groups of an SVG with ids, bounds and node counts.

Capabilities: read

Reads an SVG and lists its drawable elements: id, tag, bounds in the drawing space (viewBox units), node count, fill, stroke and transform, plus the canvas. Use it to find the ids the other vector.* commands take. Changes nothing. Example: {"source": "assets/art/badge.svg"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command reads. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command reads. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |

## `vector.mirror` (modifies state)

Since 0.16.0.

Mirror shapes across a vertical or horizontal axis and weld the halves, or add the mirrored copy.

Capabilities: read, writeProject

For each picked shape, reflects it across the line x = at (axis "vertical") or y = at (axis "horizontal"). weld: true (default) unions the shape with its reflection into ONE path that keeps the shape's id and style, so you draw half a face, a wing or a vase and get the whole; points within `snap` of the axis are put on it first, so the halves meet without a hairline. weld: false adds the mirrored copy after the original instead (id <id>-mirror) with the exact curves. `at` is a number (the coordinate of the axis in the drawing), "canvas" (the drawing's middle line, default) or "start" / "end" (the shape's own left or top / right or bottom edge). Open lines cannot be welded and get a copy. Transforms are honoured. Returns a preview as `$image`. Example: {"source": "assets/art/face.svg", "elements": ["half"], "axis": "vertical", "at": 50}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `axis` | string ["vertical","horizontal"] | yes | vertical: the mirror line is vertical, left and right swap. horizontal: top and bottom swap. |
| `at` | any | no | Where the mirror line is: a number (x for a vertical axis, y for a horizontal one, in the drawing), "canvas" (default), "start" or "end" (the shape's own edge). |
| `weld` | boolean | no | Union the shape with its reflection into one path (default). false adds the reflection as a copy. Default true. |
| `snap` | number | no | Points this close to the axis are put on it before welding, in drawing units. Default: twice the tolerance. |

## `vector.nodes` (modifies state)

Since 0.16.0.

Edit the nodes of a path: move anchors and handles, insert, delete, convert, break, join, close, append.

Capabilities: read, writeProject

Applies a list of node operations, in order, to ONE shape (a rect or circle becomes a <path> with the same outline; the id, style and transform stay). Nodes are numbered from 0 in the order of the path data, per subpath (`subpath`, default 0). Points are in the drawing space by default (space "local" for the path's own numbers). Example: {"source": "assets/art/leaf.svg", "element": "leaf", "ops": [{"op": "move", "node": 1, "to": [40, 50]}, {"op": "convert", "node": 2, "to": "smooth"}]}. Docs: docs.read VECTOR.

Ops: {"op": "move", "node": n, "to": [x, y]} or "by": [dx, dy] (the handles go with it unless handles: false); {"op": "handle", "node": n, "which": "in"|"out", "to": [x, y], "link": "auto"|"none"|"angle"|"mirror"} (auto: a smooth node keeps its handles on one line, a symmetric one mirrors them; a handle moved onto its node is removed); {"op": "insert", "segment": s, "t": 0.5} or "at": [x, y] near the path (the curve keeps its shape); {"op": "delete", "node": n, "keepShape": true}; {"op": "convert", "node": n, "to": "corner"|"smooth"|"symmetric"}; {"op": "break", "node": n} (open a closed subpath there, or split an open one); {"op": "join", "node": a, "otherNode": b, "other": subpath, "connect": "merge"|"line"} (two ends); {"op": "close"}; {"op": "reverse"}; {"op": "append", "at": [x, y], "out": [x, y], "end": "end"|"start"} (continue an open path; subpath = the number of subpaths starts a new one). A shape drawn by vector.shape with parametric: true stops being parametric. Returns the new node count and bounds and a preview as `$image`.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `element` | string | yes | The shape to edit: an SVG id or a selector that matches exactly one element. |
| `ops` | array | yes | The node operations, applied in order. Each is an object with an `op` (move, handle, insert, delete, convert, break, join, close, reverse, append) and its arguments. |
| `space` | string ["drawing","local"] | no | drawing (default): points in the ops are in the drawing space. local: the path's own coordinates. |

## `vector.offset` (modifies state)

Since 0.16.0.

Grow or shrink SVG shapes by a distance (offset path, inset).

Capabilities: read, writeProject

Offsets the outline of each picked shape by `distance` drawing units (positive grows, negative insets) with round, miter, bevel or square corners, and writes it back as a <path> (curves refitted as Beziers). Each shape keeps its id, style and transform; copy: true leaves the original and adds the offset shape after it (id <id>-offset). Holes grow the opposite way, as in any offset. Distances are in the drawing space (viewBox units), whatever the shape's transform. Returns a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["disc"], "distance": -3, "join": "round", "copy": true}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `distance` | number | yes | How far to move the outline, in drawing units. Positive grows the shape, negative shrinks it. Not 0. |
| `join` | string ["round","miter","bevel","square"] | no | The corner shape of a grown outline: round (default), miter (sharp, up to miterLimit), bevel (cut) or square. |
| `miterLimit` | number | no | With join "miter": the longest miter, as a multiple of the distance, before the corner is squared off. Default 4. |
| `copy` | boolean | no | Add the offset shape after the original instead of replacing it. Default false. |

## `vector.reorder` (modifies state)

Since 0.16.0.

Change the drawing order of SVG elements or move them into another group.

Capabilities: read, writeProject

`to` changes the order inside the group: "front" (drawn last, on top), "back", "forward" or "backward" by one place. `parent` (a group id, or "root") and/or `before` (an element id) move the elements there: into the group at its end, or in front of that element; the elements keep their look (the transforms of the old and new group are compensated). Ids stay. Returns the elements and a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["star"], "to": "front"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `to` | string ["front","back","forward","backward"] | no | Change the order inside the group. |
| `parent` | string | no | A group id or selector, or "root": move the elements into it (at its end unless `before`). |
| `before` | string | no | An element id or selector: the elements go in front of it (behind it in the picture), in its group. |

## `vector.repeat` (modifies state)

Since 0.16.0.

Repeat an SVG element in a grid or around a circle.

Capabilities: read, writeProject

Adds copies of one element (a shape or a group): mode "grid" lays out `columns` x `rows` with `spacing` between their bounds; mode "radial" puts `count` copies (the original included) around `center` (or `radius` away) over `sweep` degrees, turned to follow the circle unless orient is false. `rotation` turns each copy a little more than the last, about its own centre. Copies are placed with a transform attribute and get ids <id>-2, <id>-3... (ids inside a copied group get the same suffix); they follow the original in the drawing. Angles are in degrees, clockwise on screen, 0 pointing right. Returns a preview as `$image`. Example: {"source": "assets/art/flower.svg", "element": "petal", "mode": "radial", "count": 8, "center": [50, 50]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `element` | string | yes | The element to repeat: an SVG id or a selector that matches exactly one element (a shape or a group). |
| `mode` | string ["grid","radial"] | yes | grid: columns x rows. radial: copies around a centre. |
| `columns` | integer | no | Grid: copies per row, the original included. Default 1. |
| `rows` | integer | no | Grid: number of rows, the original included. Default 1. |
| `spacing` | any | no | Grid: the gap between neighbouring copies' bounds, a number or [x, y], in drawing units. Default 0 (touching). |
| `count` | integer | no | Radial: how many elements in total, the original included. |
| `center` | array | no | Radial: the point [x, y] the copies turn around, in drawing units. |
| `radius` | number | no | Radial, without `center`: the circle's radius; the centre is put that far below the element. |
| `sweep` | number | no | Radial: the angle the copies cover, 1 to 360 degrees. Default 360. |
| `orient` | boolean | no | Radial: turn each copy to follow the circle (default). false keeps every copy upright. Default true. |
| `rotation` | number | no | Degrees each copy turns more than the previous one, about its own centre. Default 0. |
| `bounds` | string ["visual","geometry"] | no | What a copy's size is measured with: "visual" (default) includes the stroke. |

## `vector.set` (modifies state)

Since 0.16.0.

Set the style, visibility, lock, id or attributes of SVG elements.

Capabilities: read, writeProject

Sets presentation properties on the picked elements (shapes or groups): fill, stroke (a CSS colour, "none" or url(#gradient)), strokeWidth, opacity, fillOpacity, strokeOpacity, fillRule, lineCap, lineJoin, miterLimit, dashes ([] = solid); hidden (display="none", which every renderer honours) and locked (data-locked="true", which the Vector panel honours); `id` renames ONE element and updates the href and url(#...) that point to it; `attributes` sets any other attribute (null removes it). A null value removes the property, so the element takes it from its group again. A property the element already writes in its style attribute is changed there. Returns the elements and what was set, and a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["disc"], "fill": "#d94f4f", "stroke": "#101018", "strokeWidth": 2}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `fill` | any | no | A CSS fill colour, "none" or url(#id); null removes it. |
| `stroke` | any | no | A CSS stroke colour, "none" or url(#id); null removes it. |
| `strokeWidth` | any | no | Stroke width in the element's units; null removes it. |
| `opacity` | any | no | 0 to 1; null removes it. |
| `fillOpacity` | any | no | 0 to 1; null removes it. |
| `strokeOpacity` | any | no | 0 to 1; null removes it. |
| `fillRule` | any ["nonzero","evenodd",null] | no | How overlapping subpaths fill; null removes it. |
| `lineCap` | any ["butt","round","square",null] | no | The ends of open lines; null removes it. |
| `lineJoin` | any ["miter","round","bevel",null] | no | The corners of lines; null removes it. |
| `miterLimit` | any | no | The longest miter before a corner is bevelled; null removes it. |
| `dashes` | any | no | Dash pattern lengths; [] or null makes the stroke solid. |
| `hidden` | boolean | no | true hides the elements (display="none"); false shows them. |
| `locked` | boolean | no | true marks the elements locked (data-locked="true") so the Vector panel does not pick or move them; false unlocks them. |
| `id` | string | no | Rename: the new id (one element only). |
| `attributes` | object | no | Other attributes to set: {"class": "body", "clip-path": null}. |

## `vector.set_path` (modifies state)

Since 0.16.0.

Replace the path data of a shape.

Capabilities: read, writeProject

Sets the outline of ONE shape to the path data `d`: a rect or circle becomes a <path>; the id, style and transform stay. `space` "local" (default) means `d` is written in the shape's own coordinates, "drawing" that it is in the drawing space (converted through the shape's transforms). A shape drawn by vector.shape with parametric: true stops being parametric. Returns the node count, the bounds and a preview as `$image`. Example: {"source": "assets/art/leaf.svg", "element": "leaf", "d": "M10 10 L90 10 L50 80 Z"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `element` | string | yes | The shape: an SVG id or a selector that matches exactly one element. |
| `d` | string | yes | The new SVG path data. |
| `space` | string ["local","drawing"] | no | local (default): the shape's own coordinates. drawing: the drawing space. |

## `vector.shade` (modifies state)

Since 0.16.0.

Add a shadow band and a highlight band to shapes from the light direction.

Capabilities: read, writeProject

For each picked shape builds a shadow band (the part of the shape on the side away from the light: the shape minus itself pushed toward the light by `depth`) and a highlight band (on the light side, `highlightDepth` wide), as two new paths right after the shape (ids <id>-shadow, <id>-highlight) with the shape's transform, so they stay inside it. Colours: if the project's style palette (assets.json style.palette) has the fill, the next darker and lighter palette colours (its ramp when one is declared); otherwise the fill shifted in OKLab by `strength`; `shadowColour` / `highlightColour` override. `light` is the direction TOWARDS the light in degrees counter-clockwise from +x (90 from above, 135 upper-left) or a name; default: the style guide's lightDirection, else 135. Shapes need a solid fill (or explicit colours). Returns the bands and the light used, plus a preview as `$image`. Example: {"source": "assets/art/orb.svg", "elements": ["orb"], "light": "upper-left", "depth": 6}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `light` | any | no | The direction TOWARDS the light: degrees counter-clockwise from +x (right) with y up, so 90 is from above and 135 from the upper left; or a name ("upper-left", "top"...); or "style". Default: the style guide's lightDirection, else 135. |
| `depth` | number | no | The width of the shadow band in drawing units. Default 10% of the shape's smaller side. |
| `highlightDepth` | number | no | The width of the highlight band. Default 60% of the shadow's. |
| `shadow` | boolean | no | Build the shadow band. Default true. |
| `highlight` | boolean | no | Build the highlight band. Default true. |
| `shadowColour` | string | no | The shadow's colour. Default: derived from the fill. |
| `highlightColour` | string | no | The highlight's colour. Default: derived from the fill. |
| `strength` | number | no | How much lighter or darker the derived colours are, in OKLab lightness 0.01 to 0.6. Default 0.12. |
| `shadowOpacity` | number | no | 0 to 1. Default 1. |
| `highlightOpacity` | number | no | 0 to 1. Default 1. |

## `vector.shape` (modifies state)

Since 0.16.0.

Add a star, gear, rounded polygon, arrow, speech bubble or ribbon to an SVG.

Capabilities: read, writeProject

Inserts a new element with exact geometry (the shapes AIs draw badly by hand) into an SVG file, SVG text or an svg layer of an image document, at the end of the drawing or of `parent`, with the `id`, `fill`, `stroke` and `transform` you give. kind "star" (points, innerRatio, roundness), "gear" (teeth, depth, toothWidth, hole), "polygon" (sides, cornerRadius: a rounded regular polygon), "arrow" (from, to, shaftWidth, headLength, headWidth, curve: straight or bent), "bubble" (width, height, cornerRadius, tailTo: a speech bubble whose tail points at the speaker) and "ribbon" (a banner with folded ends, a group of five paths). Curves are cubic Beziers. Sizes and positions are in the parent's coordinates (the viewBox for the top level); anything left out defaults to a good size in the middle of the drawing, so {"kind": "star"} works. Returns the new element, its bounds in the drawing and a preview as `$image`. With `replace` the shape is redrawn in an existing element, and with parametric: true the arguments are kept on it (data-fa-shape, data-fa-args). Example: {"source": "assets/art/badge.svg", "kind": "gear", "teeth": 12, "center": [50, 50], "radius": 30, "fill": "#c0c4cc"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `id` | string | no | The id of the new element (default: the kind, "star", "blob"..., or the next free "star-2"). An id the SVG already uses is an error. |
| `parent` | string | no | An id or selector of ONE group (<g>) to put the element in, at its end. Default: the top level. Coordinates are the parent's own, so a translated or scaled group moves and scales the shape. |
| `before` | string | no | An id or selector of ONE element: the new one goes in front of it in the drawing order (behind it on the picture), in the same group. |
| `transform` | string | no | A transform attribute for the new element, e.g. "rotate(15 50 50)". |
| `fill` | string | no | A CSS fill colour or "none". Default: a blue for closed shapes, none for open curves. |
| `stroke` | string | no | A CSS stroke colour. Default: none for closed shapes, a dark slate for open curves. |
| `strokeWidth` | number | no | Stroke width in the parent's units (default 1% of the drawing's longer side for open curves). |
| `opacity` | number | no | 0 to 1. |
| `attributes` | object | no | Any other attributes of the new element: {"class": "body", "stroke-linejoin": "round"}. |
| `kind` | string ["star","gear","polygon","arrow","bubble","ribbon"] | yes | The shape to build. star: points, innerRatio, roundness. gear: teeth, depth, toothWidth, hole. polygon: sides, cornerRadius. arrow: from, to, shaftWidth, headLength, headWidth, curve. bubble: width, height, cornerRadius, tailTo, tailWidth. ribbon: width, height, extent, drop, notch, foldFill. |
| `center` | array | no | The middle of the shape [x, y] in the parent's coordinates (star, gear, polygon, bubble, ribbon). Default: the middle of the drawing. |
| `radius` | number | no | star, gear, polygon: the radius to the tips (star, gear) or corners (polygon). Default: 40% of the drawing's shorter side. |
| `rotation` | number | no | star, gear, polygon: degrees clockwise on screen; where the first tip, tooth or corner points. Default -90 (up). |
| `points` | integer | no | star: the number of tips, 3 to 128. Default 5. |
| `innerRatio` | number | no | star: the radius of the valleys as a fraction of `radius` (0.02 to 0.98). Default 0.5. |
| `roundness` | number | no | star: 0 sharp corners to 1 as round as the edges allow. Default 0. |
| `teeth` | integer | no | gear: the number of teeth, 3 to 128. Default 8. |
| `depth` | number | no | gear: the height of a tooth as a fraction of `radius` (0.02 to 0.6). Default 0.2. |
| `toothWidth` | number | no | gear: the width of a tooth at its tip as a fraction of the distance between two teeth (0.1 to 0.9). Default 0.5. |
| `hole` | number | no | gear: the radius of the centre hole as a fraction of `radius` (0 for none). Default 0.3. |
| `sides` | integer | no | polygon: the number of sides, 3 to 128. Default 6. |
| `cornerRadius` | number | no | polygon, bubble: the radius of the rounded corners, in the parent's units. polygon default 0; bubble default a quarter of the smaller side. |
| `from` | array | no | arrow: where the shaft starts [x, y]. |
| `to` | array | no | arrow: the tip of the head [x, y]. |
| `shaftWidth` | number | no | arrow: the thickness of the shaft. Default 12% of the length. |
| `headLength` | number | no | arrow: how far the head reaches back from the tip. Default 2.5 shaft widths. |
| `headWidth` | number | no | arrow: the width of the head. Default 2.2 shaft widths. |
| `curve` | number | no | arrow: the bend, -0.5 to 0.5 (the sagitta as a fraction of the length; 0.5 is a half circle); positive bends to the right of from -> to. Default 0. |
| `width` | number | no | bubble: the width of the box; ribbon: the width of the front band. |
| `height` | number | no | bubble: the height of the box; ribbon: the height of the front band. |
| `tail` | boolean | no | bubble: false for a box without a tail (default true). |
| `tailTo` | array | no | bubble: the tip of the tail [x, y], outside the box; the tail grows from the side nearest to it. Default: below the lower left. |
| `tailWidth` | number | no | bubble: the width of the tail where it leaves the box. Default 30% of the smaller side. |
| `tailRoundness` | number | no | bubble: 0 sharp tip to 1 round. Default 0.5. |
| `extent` | number | no | ribbon: how far each tail sticks out past the band. Default 20% of the width. |
| `drop` | number | no | ribbon: how much lower the tails sit than the band, also the size of the folds. Default 35% of the height. |
| `notch` | number | no | ribbon: the depth of the V cut in the tail ends; 0 for straight ends. |
| `foldFill` | string | no | ribbon: the colour of the folds (the tails are a step lighter). Default: darker shades of `fill`. |
| `replace` | string | no | Redraw an existing shape (an id or selector of ONE path, rect, circle...) instead of adding one: its outline becomes the new shape, written in the element's own coordinates; its id, style and transform stay. Not with id, parent, before, transform, fill, stroke, strokeWidth, opacity or attributes. Not for a ribbon. |
| `parametric` | boolean | no | true writes data-fa-shape (the kind) and data-fa-args (its arguments as JSON) on the element, so an editor can show them as parameters and call vector.shape again with `replace`. Any command that changes the outline of such an element removes both. Not for a ribbon. Default false. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |

## `vector.simplify` (modifies state)

Since 0.16.0.

Reduce the nodes of SVG paths within a tolerance.

Capabilities: read, writeProject

Rewrites each picked shape (default: every shape) with fewer nodes: a path with curves is refitted from its outline as few cubic Beziers as `tolerance` allows, a path of straight lines loses the vertices within `tolerance` of the line between their neighbours. Corners stay corners. A shape that cannot lose nodes is left as it is (listed in `unchanged`), so a rect or circle is not turned into a path for nothing. Returns a preview as `$image`. Example: {"source": "assets/art/tree.svg", "tolerance": 0.4}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |

## `vector.smooth` (modifies state)

Since 0.16.0.

Round the corners of SVG paths into smooth Bezier curves.

Capabilities: read, writeProject

Gives every node that is not a sharp corner smooth handles, so a polygon or a rough hand-drawn path becomes a flowing curve through the same nodes. `smoothness` 0 keeps the segments straight, 1 is the usual round curve. Nodes that turn more than `cornerAngle` stay sharp. Applies to the picked shapes (default: every shape). Returns a preview as `$image`. Example: {"source": "assets/art/blob.svg", "elements": ["blob"], "smoothness": 0.8}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `smoothness` | number | no | 0 to 1: how round the curves are. Default 1. |

## `vector.stroke_to_path` (modifies state)

Since 0.16.0.

Turn the stroke of SVG shapes into a filled outline path.

Capabilities: read, writeProject

Converts the stroke of each picked shape (its stroke-width, linecap, linejoin, miterlimit, dasharray and dashoffset, read with inheritance, or the overrides given here) into a filled <path> outline, with SVG's own cap, join and dash rules. A shape with no fill becomes the outline (fill = its stroke colour, stroke none). A filled shape keeps its fill and id, and the outline is added after it with the id <id>-stroke. Stroke widths are in the shape's own space, so a scaled shape keeps its look. Returns a preview as `$image`. Example: {"source": "assets/art/logo.svg", "elements": ["swoosh"], "cap": "round"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `width` | number | no | Stroke width to use instead of the shape's stroke-width, in the shape's own units. |
| `cap` | string ["butt","round","square"] | no | Line caps of open paths. Default: the shape's stroke-linecap. |
| `join` | string ["miter","round","bevel"] | no | Corner joins. Default: the shape's stroke-linejoin. |
| `miterLimit` | number | no | Miter limit (a miter longer than this times the width becomes a bevel). Default: stroke-miterlimit, else 4. |
| `dashes` | array | no | Dash pattern: on, off, on, off... lengths in the shape's units. [] makes the stroke solid. Default: the shape's stroke-dasharray. |
| `dashOffset` | number | no | Where in the dash pattern the line starts. Default: the shape's stroke-dashoffset. |
| `color` | string | no | A CSS colour to use for shapes that have no stroke (the outline's fill). Shapes with a stroke keep its colour. |

## `vector.style` (modifies state)

Since 0.16.0.

Apply the project's style guide to an SVG: outline and palette.

Capabilities: read, writeProject

Applies assets.json `style` to the SVG: `outline` puts the guide's outline colour and width (pixels of the SVG's declared size) as a stroke on every filled shape; `palette` snaps every fill, stroke and gradient stop colour to the nearest colour of the guide's palette. With neither argument it applies both, whichever the guide defines; one of them asked for alone applies only that one (outline: true = just the outline), and one switched off alone applies the other (outline: false = just the palette). Pass {"outline": {"width": 2, "color": "#101018"}} or {"palette": ["#101018", "#e8e0d0"]} to use values other than the guide's. Applies to the picked elements (default: the whole drawing). Returns a preview as `$image`. Example: {"source": "assets/art/crest.svg"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `outline` | any | no | true: the guide's outline. An object {"width", "color"}: that outline. false: none. Width is in pixels of the SVG's declared size. |
| `palette` | any | no | true: snap to the guide's palette. A list of colours: snap to those. false: leave colours. |

## `vector.text_to_path` (modifies state)

Since 0.16.0.

Turn text into path outlines with the engine's fonts, so it needs no font.

Capabilities: read, writeProject

Outlines text with the engine's own font stack (HarfBuzz shaping: kerning, ligatures, Arabic and other joining scripts, right-to-left; DejaVu Sans, the built-in families or a project .ttf / .otf) and inserts it as ONE <path> (fill-rule nonzero), so the picture does not depend on a font being installed. Give `text` (new outlines at `at`, with `size` the em height, `anchor` start / middle / end, `letterSpacing`, `lineSpacing`; \n starts a line) or `elements` (ids of <text> elements of the drawing, which become paths with their own id, fill, class and transform; position, font-size and text-anchor are read from them; pass `font` since families cannot be looked up by name). Characters no font has are left out with a warning. Returns the element, `advance` (the width of the widest line, in the parent's units), `glyphs` and a preview as `$image`. Example: {"source": "assets/art/title.svg", "text": "LEVEL 3", "font": "builtin:display", "size": 24, "at": [50, 40], "anchor": "middle"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `id` | string | no | The id of the new element (default: the kind, "star", "blob"..., or the next free "star-2"). An id the SVG already uses is an error. |
| `parent` | string | no | An id or selector of ONE group (<g>) to put the element in, at its end. Default: the top level. Coordinates are the parent's own, so a translated or scaled group moves and scales the shape. |
| `before` | string | no | An id or selector of ONE element: the new one goes in front of it in the drawing order (behind it on the picture), in the same group. |
| `transform` | string | no | A transform attribute for the new element, e.g. "rotate(15 50 50)". |
| `fill` | string | no | A CSS fill colour or "none". Default: a blue for closed shapes, none for open curves. |
| `stroke` | string | no | A CSS stroke colour. Default: none for closed shapes, a dark slate for open curves. |
| `strokeWidth` | number | no | Stroke width in the parent's units (default 1% of the drawing's longer side for open curves). |
| `opacity` | number | no | 0 to 1. |
| `attributes` | object | no | Any other attributes of the new element: {"class": "body", "stroke-linejoin": "round"}. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `text` | string | no | The text to outline (UTF-8). A newline starts a new line. |
| `font` | string | no | "" / "builtin" (DejaVu Sans, the default), "builtin:serif", "builtin:hand", "builtin:display", "builtin:blackletter", "builtin:pixel", or a project-relative .ttf / .otf. The built-in DejaVu Sans fills in characters the font lacks. |
| `size` | number | no | The em height in the parent's units (the font size). Default 20% of the drawing's shorter side. |
| `at` | array | no | The start (see `anchor`) of the first baseline [x, y] in the parent's coordinates. Default: the middle of the drawing, centred. |
| `anchor` | string ["start","middle","end"] | no | Which point of each line sits at `at`: its start (default when `at` is given), middle (default without `at`) or end. |
| `letterSpacing` | number | no | Extra space after each letter, in ems. Default 0. |
| `lineSpacing` | number | no | A multiplier of the font's line height for several lines. Default 1. |

## `vector.to_rig` (modifies state)

Since 0.16.0.

Turn an SVG whose named groups are the parts of a character into part pictures, joints and a Bone2D prefab that animates in parts.

Capabilities: read, writeProject

Reads a project SVG and makes a character that animates in parts, with no other step. Every group with an id is a PART (a group nested in a group is a child part; ids an editor makes up, like g123, do not count; `parts` names the groups yourself). Each part is drawn alone (its own shapes only, with the transforms and styles of its groups), trimmed, padded and packed into ONE atlas picture (`layout: "atlas"`, default; "files" writes a picture per part). The prefab (default prefabs/<name>.prefab.json) has an entity per part, named by its id, in the hierarchy of the drawing, with a Sprite (region, size, pivot, layer from the SVG order, pixelArt from the style), a Transform at the joint and a Bone2D (length to the farthest child joint). Rotating a part (Transform.rotation.z, in a clip) turns it, and its children, about its joint. Example: {"source": "assets/art/hero.svg", "pixelsPerUnit": 4}. Docs: docs.read VECTOR (Characters in parts).

JOINTS: a shape with the id <part>-pivot (or <part>_pivot) anywhere in the SVG marks the joint by its centre (it is not drawn); else `pivots` {part: [x, y]} in the drawing; else the `data-pivot="x y"` attribute of the group; else the overlap with the nearest ancestor part that has a picture (its centre, moved to the nearer end of a long part such as an arm); else the top centre of the part. The result says which one was used (`pivotFrom`). HIERARCHY: nesting in the SVG, then the `data-parent` attribute and `parents` {part: parent, "" = root}, then names (`naming`): arm_lower_l hangs from arm_upper_l, and when one of root/body/torso/trunk/hips/pelvis/chest is left with no parent the other parentless parts hang from it. `data-min-angle` / `data-max-angle` on a group set Bone2D.minAngle / maxAngle. Running it again UPDATES the prefab in place: the entities keep their names and everything you added (an Animator, colliders, other children); only Transform.position, Sprite and Bone2D.length are rewritten, new parts are added, and parts that left the SVG are reported (with the clips that name them; `prune: true` removes them). Result: `parts` (parent, pivot, pivotFrom, bone length, region), the atlas, `restPose` {matches, maxDifference, differingPixels} from composing the prefab's sprites and comparing them with the SVG drawn whole, a side-by-side `$image` (SVG left, rig right with a cross at each joint) and `warnings`. The pictures get a provenance recipe in assets.json, so assets.regenerate and `factoria validate` find the rig stale when the SVG changes. SVG y points down, the engine's up: the prefab's y is flipped, and the rig's origin is the bottom centre of the drawing (`origin`).

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The project-relative .svg whose groups are the parts, e.g. "assets/art/hero.svg". Path the command reads. |
| `out` | string | no | The prefab to write or update, project-relative, ending in .prefab.json. Default prefabs/<name of the svg>.prefab.json. An existing prefab is updated in place (it needs overwrite: true only when none of its entities draws this rig's pictures). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `atlas` | string | no | layout "atlas": the atlas picture, under assets/, ending in .png (default assets/art/<name>_parts.png). layout "files": the folder of the part pictures (default assets/art/<name>_parts). Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layout` | string ["atlas","files"] | no | atlas: one picture and a Sprite.region per part (one texture, fewer draw calls). files: one picture per part. Default "atlas". |
| `scale` | number | no | Pixels per drawing unit (viewBox unit) the parts are drawn at. Default: the size the SVG declares over its viewBox (usually 1). More pixels = sharper parts. |
| `pixelsPerUnit` | number | no | Texture pixels per world unit: the sprite and bone sizes are pixels / pixelsPerUnit. Default: the style's texelsPerUnit (assets.json), else `scale`, so one drawing unit is one world unit. |
| `parts` | any | no | The groups (or shapes) that are parts: an SVG id, a selector or a list of them. Default: every group with an id (and every shape with an id that is outside all of them). A part nested in another is its child. |
| `pivots` | object | no | Joints by part id, [x, y] in the drawing (viewBox units): {"arm_upper_l": [120, 80]}. They win over markers and guesses. |
| `parents` | object | no | Parent by part id, overriding the nesting and the names: {"hand_l": "arm_lower_l"}. "" makes the part a child of the rig's root. |
| `naming` | boolean | no | Use the names to complete the hierarchy: X_lower_Y under X_upper_Y, and a lone root/body/torso/trunk/hips/pelvis/chest as the parent of the other parts that have none. Default true. |
| `padding` | integer | no | Transparent pixels around each part so filtering does not bleed into the neighbour. Default 2 (1 for pixel art). |
| `origin` | any | no | Where the rig's root sits in the drawing: "bottom-center" (default, the feet), "center", "top-left" or a point [x, y] in the drawing. |
| `layer` | integer | no | Sprite.layer of the back-most part; the others follow the order of the SVG (+1 each). Default 0. |
| `name` | string | no | The name of the prefab's root entity (a prefab that exists keeps its own). Default: the name of the svg. |
| `prune` | boolean | no | Remove the entities of parts that are not in the SVG any more (they draw this rig's pictures). Default false: they stay and a warning lists them. Default false. |
| `pixelArt` | boolean | no | Sprite.pixelArt of the parts (nearest-neighbour filtering). Default: the style's pixelArt, else false. Default false. |
| `overwrite` | boolean | no | Replace pictures not made by this command, and merge into a prefab that does not use this rig's pictures. Default false. |
| `dryRun` | boolean | no | Compute everything and return the picture and the report; write nothing. Default false. |
| `previewSize` | integer | no | The longer side of each half of the side-by-side picture. Default 512. |
| `ai` | boolean | no | Whether the SVG was written by an AI (the default); false for one a person drew, for the provenance. Default true. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the pictures for the provenance record. Default CC0-1.0. |

## `vector.transform` (modifies state)

Since 0.16.0.

Move, scale, rotate or flip SVG elements in the drawing space.

Capabilities: read, writeProject

Applies a transform of the DRAWING space to the picked elements (shapes or whole groups) by writing their transform attribute, so ids, groups, styles and the nodes stay exactly as they are; parent transforms are honoured. Give any of translate [dx, dy], scale (a number or [sx, sy]), rotate (degrees, clockwise on screen), flip ("horizontal", "vertical" or "both") and matrix [a, b, c, d, e, f]; scale, rotate and flip turn about `about` ([x, y] or "center", the middle of the picked elements; default center). Order: matrix, flip, scale, rotate, then translate. Returns the transform and the bounds after it, and a preview as `$image`. Example: {"source": "assets/art/ui.svg", "elements": ["icon"], "rotate": 15, "translate": [10, 0]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `translate` | array | no | Move by [dx, dy] in the drawing space. |
| `scale` | any | no | A factor, or [sx, sy]. |
| `rotate` | number | no | Degrees, clockwise on screen. |
| `flip` | string ["horizontal","vertical","both"] | no | Mirror about `about`: horizontal swaps left and right. |
| `matrix` | array | no | A drawing-space matrix [a, b, c, d, e, f] (SVG matrix(a b c d e f)). |
| `about` | any | no | The point scale, rotate and flip turn about: [x, y] or "center" (default). |

## `vector.ungroup` (modifies state)

Since 0.16.0.

Dissolve SVG groups, keeping what is in them where it was.

Capabilities: read, writeProject

Moves the children of each picked <g> out into the group's parent, at the group's place, and removes the group. The group's transform is folded into each child's, and the style it set (fill, stroke, stroke-width...) is written on the children that do not set it. A group with clip-path, mask or filter is refused (it would change the picture). Returns the children and a preview as `$image`. Example: {"source": "assets/art/face.svg", "elements": ["eyes"]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `preview` | boolean | no | false skips the preview picture (`$image`): a live drag asks for the result many times a second and draws it itself. Default true. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to work on: an SVG id, a selector, or a list of them. A group is one element. Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |

## `vfx.create` (modifies state)

Since 0.17.0.

Write a new effect document (*.vfx.json) with one burst emitter, as a starting point to edit.

Capabilities: read, writeProject

Writes `path` (under assets/, ending in .vfx.json; format factoria.vfx/1, docs/PARTICLES.md "Effect documents") with one emitter part that bursts 16 soft dots, so there is something to see and edit. An existing file is an error unless `overwrite` is true. Change it with vfx.edit, play it with vfx.play, list its problems with vfx.check. The editor's Particle panel (View > Particles) edits the same file. Example: {"path":"assets/vfx/hit.vfx.json","doc":"A hit: sparks."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The effect document, project-relative, under assets/ and ending in .vfx.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `doc` | string | no | The file's `doc` text: what the effect is and where the game plays it. |
| `overwrite` | boolean | no | Replace the file when it exists. Default false. |

## `vfx.edit` (modifies state)

Since 0.17.0.

Change one field of an effect document by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid effect.

Capabilities: read, writeProject

Edits `*.vfx.json` the way a hand edit would, but checked: the document is parsed again after the change (the same checks as vfx.check, without the files a sound names) and, when it would be invalid, nothing is written and the error lists the problems with their pointers. op `set` writes `value` at `pointer` (a field of an existing object, new or old); `remove` deletes the field or array element at `pointer`; `add` inserts `value` into the array at `pointer` (at `index`, default the end); `move` takes element `index` of the array at `pointer` to place `to`. The result has the effect's duration, its part count and the parser's warnings. Examples: {"path":"assets/vfx/hit.vfx.json","op":"set","pointer":"/parts/0/emitter/burst","value":24} and {"path":"assets/vfx/hit.vfx.json","op":"add","pointer":"/parts","value":{"type":"light","duration":0.1,"light":{"radius":80}}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The effect document, project-relative, ending in .vfx.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `op` | string ["set","remove","add","move"] | yes | What to do. |
| `pointer` | string | yes | JSON pointer into the document, e.g. /parts/0/emitter/burst or /parts. |
| `value` | any | no | The new value (set) or the element to insert (add). Any JSON. |
| `index` | integer | no | add: where to insert; move: the element to move. |
| `to` | integer | no | move: the element's new place. |

