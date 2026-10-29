[Back to the index](../README.md)

# Commands: assets

## `assets.analyze_audio` (modifies state)

Since 0.1.6.

Measure the loudness of a sound (or of every sound) and keep the result in assets.json.

Measures integrated loudness (LUFS, ITU-R BS.1770-4 / EBU R128) and sample peak (dBFS) of .wav, .ogg, .mp3 and .qoa files, and stores them under the sound's `analysis` in assets.json together with the size and SHA-256 of the file, so editing the sound later makes the record stale instead of wrong. Sounds with import "normalize": true play at `targetLufs` using that record; without one the desktop engine measures the sound when it loads it, and mobile builds cannot, so run this (or export, which stores it) before shipping. A sound whose record is still fresh is not measured again. Without `path` every sound under assets/ and every sound a scene or prefab names is analyzed. Returns {files: [{path, loudnessLufs, peakDb, seconds, streams, normalize, gainDb, cached, stored}], measured, cached, failed}: `streams` says whether the sound is decoded while it plays (import stream), `gainDb` is the gain normalize would apply (only when normalize is on). A sound that cannot be decoded is listed with `error` and `hint` when no path is given. Example: {"path": "assets/music/theme.ogg"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative sound file, e.g. assets/sfx/jump.wav. Omit to analyze every sound of the project. |

## `assets.animate_svg` (modifies state)

Since 0.6.0.

Draw an animation with code (a JS module that returns the SVG of each frame, or an SVG with SMIL) and bake it into a sprite sheet PNG plus its `sheet` entry, offline: no provider, no key.

Writes a sprite sheet at `path` (under assets/, ending in .png) and its `sheet` entry in assets.json in one call, from an animation you write as code. Two ways to draw it. (1) `source`: a project JavaScript module, e.g. "art/coin_spin.anim.js", whose default export is `frame({t, frame, frames, fps, progress, params, rng, seed, rngFor, clip, sheetFrame, width, height}) => string`, the SVG of that frame. t is the time in seconds (frame / fps); frame counts from 0 inside the clip and frames is the clip's length; progress runs 0..1 through the clip (frame / frames for a looping clip, so the last frame leads into the first; frame / (frames - 1) for loop false, so the last frame is the end pose); params is the `params` argument (a clip's own params are merged over it); rng() is a seeded random number in 0..1 for this frame (also rng.range(a, b), rng.int(n), rng.pick(list), rng.chance(p), rng.gauss()), different on every frame; rngFor(key) is a random stream that is the SAME on every frame for one key (a sparkle that stays where it is); clip is the clip name with `clips`. The module runs in a sandboxed QuickJS context: the language only (Math, JSON, Array...), no engine bindings, no DOM, no timers, no files; it may `import` other project files with a relative path ("./shapes.js"). Math.random is a seeded stream and Date a fixed day moved to the frame's time, so the same module always draws the same frames. Loading and each frame have a time limit (`timeLimitMs`, 2000 by default) and the context a memory limit. A mistake is reported with the module's file, line and column, the source line, and the frame being drawn; console.log output comes back in `console`. (2) `svg` (text) or `source` ending in .svg: one SVG with SMIL animation (<animate>, <set>, <animateTransform>, <animateMotion> with values, keyTimes, keySplines, begin, dur, repeatCount, fill="freeze", additive, accumulate and `id.begin` sync-bases), sampled at t = frame / fps. Without `frames` the sheet takes one pass of the animation (cycle seconds * fps frames). What is not sampled (event begins such as click, CSS animations, the rest of SMIL) is a warning that names the element. Every frame is rasterized exactly as assets.rasterize_svg does (nanosvg: paths, shapes, gradients, strokes, clipPath, mask, pattern; no text or filters) into a transparent `frameWidth` x `frameHeight` cell (default 64 x 64; the SVG is fitted inside, aspect kept, centred), then the painterly `style` / `styleStrength` is applied (the style's seed is `seed`, the same for every frame, so the paper texture stays put while the drawing moves) and the pixels are snapped to `palette` (a list of "#rrggbb" or an image of the project). The frames go row by row in a grid of `columns` (default ceil(sqrt(frames))) with a transparent gutter of `padding` pixels around every cell (cell i starts at x = padding + column * (frameWidth + 2 * padding)). `pivot` ([x, y] in 0..1 from the top-left, default the centre) is recorded in the sheet entry. `clips` makes several named clips from one module: [{name, frames, fps, loop, params, pivot}], laid out one after another in the sheet (do not also give `frames`); the module receives `clip` and draws that animation; each clip becomes a clip of the sheet entry with its fps and loop. Without `clips` the sheet entry has one clip named like the file, so fps and loop are kept. The result returns the sheet as an image, the layout (columns, rows, cell size, clips) and warnings: frames that draw nothing, shapes touching the edge of the cell, a loop whose last frame jumps from the first (or repeats it), SMIL not sampled. Provenance (origin generated, ai true: the calling agent wrote the code; pass ai: false with author and license for art a person drew) carries a recipe (this command, its arguments, the module and the files it imported with their SHA-256), so the sheet can be made again, byte for byte. Use this for motion that follows rules (spin, bob, pulse, sparkle, flame, waves, loaders); for an engine-drawn entity use assets.bake_sheet, for painted frame-by-frame art ask an image provider. Example: {"path":"assets/art/coin_spin.png","source":"art/coin_spin.anim.js","frames":8,"fps":10,"frameWidth":64,"frameHeight":64,"padding":1} with art/coin_spin.anim.js = "export default function frame({progress}) { const w = Math.abs(Math.cos(progress * Math.PI * 2)) * 40; return `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><ellipse cx='50' cy='50' rx='${w + 4}' ry='42' fill='#e8c66a' stroke='#8b6a1e' stroke-width='4'/></svg>`; }"

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the sheet, project-relative, under assets/ and ending in .png. |
| `source` | string | no | A project-relative JavaScript module whose default export draws one frame ("art/coin_spin.anim.js"), or an .svg file with SMIL animation. Give this or `svg`. |
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
| `style` | string ["none","watercolor","ink","inkwash","paper"] | no | Default none. The painterly look of assets.rasterize_svg applied to every frame (watercolor, ink, inkwash, paper). The same seed for all frames, so the texture does not boil. |
| `styleStrength` | number | no | How strong the `style` is, 0 to 1 (default 1). Ignored without a `style`. |
| `padding` | integer | no | Transparent pixels around every cell: 1 or 2 keeps filtered frames from bleeding into each other. Recorded in the sheet entry. Default 0. |
| `timeLimitMs` | integer | no | Milliseconds the module may take to load and, separately, to draw each frame; over it the call fails naming the frame. Default 2000. |
| `overwrite` | boolean | no | Replace the sheet when it already exists. Default false. |
| `ai` | boolean | no | Whether the code was written by an AI (the default, since the caller is an agent). Set false for art a person made; it then counts as original work in the AI disclosure. Default true. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the sheet for the provenance record. Default "CC0-1.0". |

## `assets.bake_sheet` (modifies state)

Since 0.6.0.

Bake an entity the engine draws (a prefab, or an entity of a scene) into a sprite sheet: Shape2D, tweens, particles and scripts play and are captured frame by frame.

Plays a prefab (`prefab`) or an entity of a scene with its children (`scene` + `entity`) alone in a private world and captures it into a PNG sprite sheet at `path` (under assets/, ending in .png), with its `sheet` entry, provenance and recipe in assets.json. Use it to turn something that costs many draw calls on a phone (a glow made of shapes, a particle burst, a tweened badge, a scripted explosion) into ONE sprite, to make an effect once and play it as a SpriteAnimator, or to draw animated art with the engine's own Shape2D (gradients, strokes) instead of SVG. The world is simulated at the project's fixed step with the world RNG seeded from `seed`, so the same prefab, seed and settings bake the same pixels on the same GPU (the pixels of two different GPUs can differ by an edge pixel); a frame is captured every 1/`fps` seconds of simulated time, `frames` frames per clip. SpriteAnimator, Tint, tweens, ParticleEmitter, Shape2D, Sprite and the entity's scripts all run as in the game; nothing else is in the world (no other entities and no lights: a `lit` sprite is drawn as in a world without lights). The entity is placed at the origin of the world, even when the scene puts it elsewhere. Frame 0 is drawn after one step (the entity's start() has run) and after `warmup` seconds. `clips` bakes several named clips from one entity, each in a fresh world: `[{"name":"explode","call":"explode","frames":24,"loop":false}, {"name":"idle","frames":8}]`; `call` runs that method of the entity's behaviour right after the warm-up (`args` are its arguments), `event` sends a game event instead (`data`); a clip with neither just plays. They follow each other in the sheet and become clips of its `sheet` entry (firstFrame, lastFrame, fps, loop). Framing: the pixels are drawn at `scale` pixels per world unit and cropped to everything drawn in ANY frame plus `margin`, so nothing is cut (a particle burst that grows is included) and the entity's origin is the same pixel in every frame: it is the `pivot` recorded in the sheet entry ([x, y] in 0..1 from the top-left of the frame). Give `pivot` to choose where the origin lands (a character's feet: [0.5, 1]); give `frameWidth` and `frameHeight` for a fixed cell: without `scale` the animation is scaled to fit it, with `scale` it must fit or the command fails and says how large the cell must be. The colours are straight alpha with the colour of the edge pixels bled outwards, so a sprite scaled with filtering has no dark halo; additive glows keep their light (their alpha is the brightest channel). `background` puts a colour behind the frames (default transparent). `padding` leaves transparent pixels around each cell (default 1; the sheet entry records it). Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL). A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the bake runs in a child `factoria call` process; from a terminal `factoria call assets.bake_sheet` works as is. A script that throws, a `call` that is not a method of the behaviour (with its methods and a suggestion) or a prefab that does not load fail with an error that names the prefab and the script. Provenance: origin generated, `ai` is true when the prefab, the scene or a texture it draws is recorded in assets.json as AI-made (pass `ai` to override, with `author` and `license`); the recipe holds the arguments and the SHA-256 of the prefab or scene, its scripts and textures, so assets.regenerate can make the sheet again and validate can tell when it is stale. Example: {"path":"assets/fx/burst.png","prefab":"prefabs/burst.prefab.json","frames":16,"fps":24,"warmup":0.5,"pivot":[0.5,0.5]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the PNG sheet, project-relative, under assets/ and ending in .png. |
| `prefab` | string | no | The prefab to bake, project-relative ("prefabs/burst.prefab.json"). Give this, or `scene` + `entity`. |
| `scene` | string | no | A scene file that holds the entity to bake. Needs `entity`. |
| `entity` | string | no | The id of the entity of `scene` to bake, with its children. |
| `frames` | integer | no | Frames per clip (all of them without `clips`). Default 12. |
| `fps` | number | no | Frames per second of simulated time (at most the project's fixed rate, 60 by default): a frame is captured every 1/fps seconds. Also the sheet's clip speed. Default 12. |
| `columns` | integer | no | Columns of the grid; 0 or absent = square-ish. |
| `frameWidth` | integer | no | Pixels of a cell. Absent = as wide as the animation needs. |
| `frameHeight` | integer | no | Pixels of a cell. Absent = as tall as the animation needs. |
| `scale` | number | no | Pixels per world unit (1 = the size the entity has in the world, 2 = twice as big). Absent: 1, or the scale that fits frameWidth x frameHeight when both are given. |
| `pivot` | array | no | [x, y] in 0..1 from the top-left of the frame: where the entity's origin lands in every frame ([0.5, 1] = middle of the bottom edge). Absent: where the animation puts it (the cell is the tight box of everything drawn). |
| `clips` | array | no | Named clips, each in a fresh world: {name, call?, args?, event?, data?, frames?, fps?, loop?, warmup?}. `call` is a method of the entity's behaviour, `event` a game event (world.on); both start the clip after the warm-up. They follow each other in the sheet. |
| `warmup` | number | no | Seconds of simulated time to play before the first frame (a particle system that should start full). A clip can set its own. Default 0. |
| `seed` | integer | no | Seeds the world RNG (scripts' rng, random particles): the same seed gives the same sheet. Default 1. |
| `background` | any | no | A colour behind the frames ("#rrggbb", "#rrggbbaa", a name or [r, g, b]). Default: transparent. |
| `padding` | integer | no | Transparent pixels around every cell (twice between two cells), recorded in the sheet entry. Default 1. |
| `margin` | integer | no | Empty pixels kept around the animation's outline. Default 2. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |
| `ai` | boolean | no | Override the AI disclosure. Default: true when the prefab/scene or a texture it draws is recorded as AI-made in assets.json. |
| `author` | string | no | Who gets the credit in the provenance record. |
| `license` | string | no | License of the sheet for the provenance record. Default "CC0-1.0". |

## `assets.convert_audio` (modifies state)

Since 0.3.0.

Convert a WAV in the project to Ogg Vorbis (smaller, streams well) and record where it came from.

Reads the WAV at `path` (8, 16, 24 or 32-bit PCM or float, mono or stereo) and writes an Ogg Vorbis file at `to` (default: the same name ending in .ogg), with the encoder of this engine (fixed block size, no stereo coupling: about 4 to 6 times smaller than 16-bit WAV at the default quality, less than libvorbis would reach). The sample rate and length are kept. The WAV stays; the provenance of the WAV is copied to the Ogg with a note. Use it for music and long ambience (a streamed .ogg keeps little in memory, docs/ASSETS.md); keep short effects as WAV. Example: {"path":"assets/audio/wind.wav","quality":0.6}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The WAV to convert, project-relative, under assets/. |
| `to` | string | no | Where to write the Ogg, under assets/ and ending in .ogg. Default: next to the WAV, same name. |
| `quality` | number | no | 0 to 1. Higher is bigger and closer to the WAV; 0.6 suits ambience, 0.8 music. Default 0.6. |
| `overwrite` | boolean | no | Replace the Ogg when it already exists. Default false. |

## `assets.disclosure`

Since 0.1.6.

Write the AI-generated content disclosure for store forms (Steam) from the provenance records.

Returns Markdown that answers the AI-generated content questions of Steam's content survey and similar forms: what was pre-generated with AI by category (art, sound effects, music, voice, 3D models) with counts, providers and models; that nothing is generated while the game runs; the terms recorded for each provider; and the art, sound and model files that still have no provenance record (fix those with assets.set_provenance first). `factoria export` writes the same text as AI_CONTENT_DISCLOSURE.md. Example: {}

## `assets.draw_capsules` (modifies state)

Since 0.2.0.

Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo.

Cover-crops `keyArt` (an image in the project, e.g. a screenshot taken with game.screenshot {scale}) around `focus` to every image size the `stores` ask for and writes store/capsules/<store>/<name>_<w>x<h>.png (folders are created, files replaced). Stores: steam, epic, gog, microsoft, googleplay, appstore, itch (default: all). The sizes are in one table (docs/EXPORTING.md#store-page-material, as of 2026-10); assets with the same size in one store are one file.
The `logo` is placed by the rule of each asset: capsules and covers get it centred (Microsoft: in the upper part, the bottom third is overlaid; Steam library capsule: low), heroes, page backgrounds and screenshots get none (Steam's library hero must have no text), and the logo-only assets (Steam library logo 1280x720, Epic logo 960x540) are a transparent PNG with just the logo. `logo` is {"image": "assets/logo.png"} (transparent PNG) or {"text": "My Game", font, fill, outline} (title drawn like assets.draw_icon draws text; fill default white, outline default a dark one, false = none). Without a logo the art is cut without one and the logo-only assets are skipped.
`safeArea` is the margin the logo keeps from the edges, as fractions of the image (default 0.05 on every side, and the bottom third on the Microsoft poster and box art, which the store overlays with text): a number, {left, top, right, bottom}, or {default, steam, ...} per store. The logo is cut to fit inside it and never leaves it. `logoAnchor` puts the logo somewhere else than the asset's rule does: center, top, bottom, left, right, topLeft, topRight, bottomLeft, bottomRight, or a point [x, y] of the safe area ([0, 0] its top-left corner, [1, 1] the bottom-right one). When the art already has the capsule's proportions (within 1%) the crop has nothing to choose, so a given `focus` moves the logo instead, by its distance from [0.5, 0.5] (0.2 of the width left of the middle moves it 0.3 of the width left), still inside the safe area.
`orientation` (landscape, default; or portrait) turns the phone and tablet screenshot sizes of Google Play and the App Store. Capsules are not the store screenshots: take those at the stores' sizes with `--render-scale` (a 1280x720 game at 1.5 gives 1920x1080).
Example: {"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `keyArt` | string | yes | The art to cut the capsules from: a project image path, 1920x1080 or bigger is best (a screenshot taken with --render-scale). |
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

Draws on the CPU (anti-aliased, identical everywhere, works headless): a background plus layers drawn in order. Writes the 1024x1024 icon at `path` (default: factoria.json `icon`, else assets/icon.png) and the Android adaptive-icon foreground (432x432, transparent; the 0..100 drawing box is scaled into the 66/108 safe zone, so nothing inside it is cropped) at `foreground` (default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png; false = skip). An icon or foreground path factoria.json does not name yet is added to it. Files are replaced; assets.json gets provenance origin "original", ai false.
Drawing space: x and y run 0..100 across the icon, origin top-left, y down; sizes and radii are in the same units (shapes may reach outside 0..100: the icon crops them). Layer types: rect {x,y,w,h} (x,y = top-left), roundRect {x,y,w,h,radius}, circle {x,y,radius} (x,y = centre), ellipse {x,y,rx,ry}, polygon {points:[[x,y],...]} and text {text,x,y,size,font}: x,y = centre of the text, size = em height, font = a project .ttf (default DejaVu Sans), one line, no shaping. Shapes take fill and/or outline (colours "#rrggbb"[aa] or names), fillBottom (vertical gradient from fill at the top of the icon to fillBottom at its bottom), outlineWidth (default 2), softness (feathers the edge: glows). Text takes fill. foreground: false on a layer keeps it out of the Android foreground (backdrops such as a ground or arch; the adaptive icon has its own background colour). Unknown keys and types are errors with suggestions.
Example: {"background":{"color":"#141428","shape":"rounded"},"layers":[{"type":"circle","x":50,"y":50,"radius":28,"fill":"#ffcc44","outline":"#ffffff"},{"type":"text","text":"K","x":50,"y":50,"size":34,"fill":"#141428"}]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `background` | object | yes | The icon's backdrop. |
| `layers` | array | yes | Drawn in order, later on top. Each has a `type` (rect, roundRect, circle, ellipse, polygon, text) and the fields listed in the command description. |
| `path` | string | no | PNG to write the icon to. Default: factoria.json `icon`, else assets/icon.png. |
| `foreground` | any | no | PNG for the Android adaptive-icon foreground, or false to skip it. Default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png. |

## `assets.generate_image` (modifies state)

Since 0.1.6.

Generate a PNG image with the image asset provider and record where it came from.

Calls the provider that ai.json assigns to "image" (assets.image; there is no default, so add one, or pass `provider` such as "fake" for an offline placeholder), writes a PNG of exactly width x height at `path` and records provenance (origin generated, ai true, provider, model, the full prompt, references, date, license note) in assets.json. The house style of assets.json is applied unless style is false: its `prompt` is appended to yours, its `references` are sent along with `references`, and its `palette` reduces the result to those colours. Returns the path, size, provenance and the image itself. Generation costs money with paid providers: check the first result before generating more. Example: {"prompt":"a red potion bottle, side view","path":"assets/items/potion.png","width":64,"height":64,"transparent":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | What to draw. Describe the subject and the view; the house style is added for you. |
| `width` | integer | no | Width of the PNG in pixels. The provider's picture is resized to it. Default 512. |
| `height` | integer | no | Height of the PNG in pixels. Default 512. |
| `transparent` | boolean | no | Ask for a transparent background (sprites, items, icons). Default false. |
| `references` | array | no | Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call. Default true. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_loop` (modifies state)

Since 0.3.0.

Make a seamless loop offline (a wind or fire bed, a clock, a drone or chord pad) as a WAV or Ogg: no provider, no key.

Synthesizes a mono loop at `path` (under assets/, .wav or .ogg) from `kind`, with no AI provider and no key. The same arguments and `seed` always give the same bytes. The end of the loop meets its start: filters run round the loop, gusts and hums have a whole number of cycles, and pops, ticks and notes wrap round the end. Records provenance in assets.json (origin original, ai false, license CC0).
kind "noise": a bed of `color` noise (white = hiss, pink = rain, brown = rumble and wind) low-passed at `cutoff` Hz and scaled by `level`; `gusts` (0 to 1) swells it slowly; `crackles` adds random pops per second (a fire); `tick` adds a tick-tock every that many seconds (a clock; make `seconds` a multiple of it and `level` 0 for the ticks alone); `hum` adds sines at those Hz (a cellar's mains hum).
kind "drone": `chords`, an array of chords of notes ("A3", "F#2", "Eb4", or Hz); each chord is a soft pad lasting `chordSeconds`, with the first note an octave down at `bass` level. A single chord is a drone. `arpeggio` {every, pattern, gain} plays music-box plucks over it: `pattern` holds chord indexes (null = a rest, past the chord's end = an octave up).
Wind: {"kind":"noise","color":"brown","cutoff":900,"gusts":0.6,"seconds":20}. Fire: {"kind":"noise","color":"brown","cutoff":600,"crackles":4}. Clock: {"kind":"noise","level":0,"tick":1,"seconds":4}. Score: {"kind":"drone","chords":[["D3","F3","A3"],["Bb2","D3","F3"]],"chordSeconds":6,"arpeggio":{"every":0.75,"pattern":[0,2,1,2],"gain":0.16}}. A WAV loops sample for sample; an Ogg loop is smaller and within the codec's noise at the seam (see assets.convert_audio).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the loop, project-relative, under assets/ and ending in .wav or .ogg, e.g. "assets/audio/wind.wav". |
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

Calls the provider that ai.json assigns to "model3d" (assets.model3d) and writes the glTF binary at `path` (.glb; the fake provider makes a small .gltf cube). Generating models takes minutes with real providers. The model is not textured or rigged; check it in the scene before building on it. Records provenance in assets.json. Example: {"prompt":"a low-poly wooden crate","path":"assets/models/crate.glb"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The object to make: shape, material, style. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_music` (modifies state)

Since 0.1.6.

Generate a music track with the music asset provider and record where it came from.

Calls the provider that ai.json assigns to "music" (assets.music) and writes the audio file at `path` (extension as for assets.generate_sound). Tracks are instrumental. Records provenance in assets.json. Tracks are not looped for you: ask for a loopable piece in the prompt and set `loop` on the AudioSource. Example: {"prompt":"calm forest theme, soft flute and strings","path":"assets/music/forest.mp3","seconds":60}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The music to make: mood, instruments, tempo. |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_sound` (modifies state)

Since 0.1.6.

Generate a sound effect with the sound asset provider and record where it came from.

Calls the provider that ai.json assigns to "sound" (assets.sound) and writes the audio file at `path`, whose extension must be the one the provider makes (.mp3 for elevenlabs, .wav for fake and asset-command). Records provenance in assets.json. Example: {"prompt":"short coin pickup chime","path":"assets/sfx/coin.mp3","seconds":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The sound to make, for example "heavy wooden door slam". |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_sprite_sheet` (modifies state)

Since 0.1.6.

Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator.

Like assets.generate_image, but the picture is a grid of `frames` animation frames of frameWidth x frameHeight, normalized to exactly columns * frameWidth by rows * frameHeight pixels (each side at most 4096). The layout is written to assets.json as the `sheet` of the file with one clip "default" (all frames, at `fps`), and the result shows the Sprite and SpriteAnimator components to use. Providers draw grids unevenly: look at the result and regenerate when frames wander. Example: {"prompt":"a knight walking right","path":"assets/knight_walk.png","frames":6,"columns":3,"frameWidth":64,"frameHeight":64,"fps":10}

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
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.generate_texture` (modifies state)

Since 0.4.0.

Make a material texture (paper, parchment, wood, planks, leather, fabric, stone, noise, gradient, vignette) offline: a seeded PNG, no provider and no key.

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
| `path` | string | yes | Where to write the PNG, project-relative, under assets/ and ending in .png, e.g. "assets/textures/paper.png". |
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

Calls the provider that ai.json assigns to "voice" (assets.voice) to speak `text` with `voice` (default: the voice in ai.json) and writes the audio file at `path`. Records provenance in assets.json (the text is the prompt). Needs a key in the environment: ELEVENLABS_API_KEY (elevenlabs) or OPENAI_API_KEY (openai); without a provider the error says what to add to ai.json. To test code that depends on voice lines without a provider or a key, pass `silent: true`: it writes a silent .wav as long as the line (about 0.06 s per character, or `seconds`) and records it as a placeholder, not AI. Example: {"text":"Welcome, traveller.","path":"assets/voice/welcome.mp3"}

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
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.import` (modifies state)

Since 0.1.6.

Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from.

Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance (origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. The importer is chosen by the extension:
- .png .jpg .tga .bmp, .wav .ogg .mp3 .qoa, .ttf .otf: copied as they are (images are checked to decode).
- .gltf and .glb: copied with the .bin buffers and images their uris point at, which must sit next to the model or below it (a missing buffer is an error, a missing image a warning). An identical file already there is shared; a DIFFERENT image with the same name is kept and the result warns (kits ship different Textures/colormap.png files: import each kit into its own folder with `path`, or pass overwrite), and a DIFFERENT buffer is an `exists` error. project.validate reports a model whose texture or buffer is missing.
- .aseprite .ase: becomes ONE PNG sprite sheet (frames in a grid, `columns` per row, default ceil(sqrt(frames))) and the `sheet` entry of assets.json: columns, rows, frameWidth, frameHeight, frames and a clip per tag (firstFrame, lastFrame, fps from the frame durations). Hidden layers are left out, layer and cel opacity apply, RGBA, grayscale and indexed colors work. Blend modes other than normal are drawn as normal, and ping-pong or reverse tags become forward clips (set SpriteAnimator.mode to play them that way); the result says so. The result lists the Sprite and SpriteAnimator settings that play it.
- .psd: the merged image becomes a PNG (layers are flattened).
- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the bounds so you can scale it.
- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither installed the error says where to get them.
- .mp4 .mov .webm .mkv .avi .m4v: converted to an MPEG-1 video with MP2 audio in an .mpg (the only video the engine plays, the same on every platform) by ffmpeg, at most 1280 px wide, quality 4, 30 fps when the frame rate is not one MPEG-1 has. ffmpeg is found through $FACTORIA_FFMPEG, PATH or the copy `factoria setup ffmpeg` installs; without it the error names that command. A source with no audio track gives a silent video (the result warns). The result has width, height, fps and duration and the Video component that plays it. An .mpg or .mpeg is checked to be MPEG-1 and copied.
Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/, videos in assets/video/ by default) or at `path`, which must be under assets/. An existing file is an error unless overwrite is true. Example: {"source":"C:/art/hero.aseprite","license":"CC0","author":"Ana"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first. |
| `path` | string | no | Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/, assets/fonts/ or assets/video/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX, .mpg for a video). |
| `license` | string | no | License or terms of the file, e.g. "CC0", "CC-BY 4.0", "bought from itch.io, single project". Recorded in assets.json. |
| `author` | string | no | Who made it. Recorded in assets.json for the credits. |
| `sourceUrl` | string | no | Where the file came from (a page URL). Recorded as the provenance source instead of the local path. |
| `ai` | boolean | no | Set true when AI made the content elsewhere (Steam's AI disclosure reads it). Leave out when unknown. |
| `columns` | integer | no | Aseprite only: frames per row of the sheet (default ceil(sqrt(frames))). |
| `overwrite` | boolean | no | Replace files that already exist. Default false. |

## `assets.list`

List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, other (by file name).

Example: assets.list {"folder":"assets","extension":".png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | no | Project-relative folder. Default "assets". |
| `extension` | string | no | Only files with this extension, e.g. .png |

## `assets.pack_atlas` (modifies state)

Since 0.3.0.

Pack a folder of images into one atlas PNG and write the frame table (rect and pivot per frame) that a Sprite's `region` reads.

Every image under `folder` (png, jpg, tga, bmp; subfolders too) is a frame named by its path without the extension ("ship/0.png" is "ship/0"). They are packed into the smallest square page up to maxSize (tallest first), each with `padding` pixels of its own edge repeated around it so bilinear filtering and mipmaps never bleed a neighbour (the same padding as the export's atlas groups). The page is written to `out`, and the table to `table` (default `out` with .json): {"texture":"assets/atlas.png","size":[w,h],"frames":{"ship/0":{"rect":[x,y,w,h],"pivot":[px,py]}}}. rect is in texture pixels from the top-left, exactly Sprite.region; pivot is Sprite.pivot (+Y up). Pivots come from `<folder>/pivots.json` ({"ship/0":[0.5,0.2]}); a frame without one is [0.5, 0.5]. Keys of an existing table other than texture, size and frames are kept, so your own data can live in the same file.
Packing again is stable: a frame whose size did not change keeps its rectangle (the page grows, never reshuffles), so a new picture changes the table by one line and a scene that copied a rect keeps drawing the same picture. Frames removed from the folder leave holes that new frames fill. Nothing is written when the result would be the same bytes. The result lists what was added, moved (changed size) and removed. Use this while developing, when many sprites must share one texture (a map of thousands of tiles, characters of one screen) and you want to pick frames by name; `factoria export` packs `atlas` groups by itself and Sprites keep naming the source PNGs (docs/ASSETS.md, "Atlases"). Example: {"folder":"assets/src/frames","out":"assets/atlas.png","table":"data/atlas.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | yes | Project-relative folder of images; each image (subfolders too) is one frame named by its path without the extension. An optional pivots.json inside gives pivots. |
| `out` | string | yes | Project-relative .png to write, e.g. "assets/atlas.png". Replaced if it exists. |
| `table` | string | no | Project-relative .json for the frame table. Default: out with the .json extension. |
| `maxSize` | integer | no | Largest side of the page in pixels. Default 2048 (what every phone samples); 4096 is fine on desktop. Frames that do not fit are an error. |
| `padding` | integer | no | Pixels of the frame's own edge repeated around each frame. Default 2. |

## `assets.preview_sheet`

Since 0.6.0.

Look at a sprite sheet the way the game plays it: a labelled grid of its frames (numbers, cell edges, pivot, optional onion skin) plus checks for empty, cut or jumping frames and a loop seam.

Cuts the frames of the sheet at `path` with the grid of its `sheet` entry in assets.json (columns, rows, frameWidth, frameHeight, padding, frames; or the grid you pass), and returns a picture: every frame in a tile with its number (f<n>), a cyan rectangle for the frame, a grey one for the padding gutter around it and a magenta cross for the pivot (the clip's pivot, else the sheet's, else the centre; [x, y] from the top-left). `clip` shows one clip of the sheet; without it all the clips (or all the frames). `onion: true` draws the previous frame in red and the next in blue under the current one. It also checks the frames and returns `warnings` for: frames that draw nothing, shapes touching the edge of the cell (cut off), a bounding box that jumps by more than 30% of the frame between consecutive frames, a looping clip whose last frame jumps from the first or repeats it, and a grid that does not match the image size. The checks are the same for a sheet from assets.animate_svg, assets.bake_sheet, assets.slice_sheet or an Aseprite import, or one drawn by hand. The picture is a temporary screenshot in .factoria/screenshots. A wrong `clip` fails listing the clips of the sheet with a "did you mean". Example: {"path":"assets/hero.png","clip":"walk","onion":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of the sprite sheet image. |
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

With `path`, the provenance record of that file (null when it has none). Without, every record in assets.json, how many are AI-made, and the art, sound and model files under assets/ that have no record yet. Example: {"path":"assets/hero.png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path under assets/. Omit to list every record. |

## `assets.rasterize_svg` (modifies state)

Since 0.4.0.

Turn an SVG (text or a project file) into a PNG at a given size, offline: art you write as vector shapes, no provider and no key.

Rasterizes an SVG to a PNG at `path` (under assets/, ending in .png) with no AI provider and no key, anti-aliased, on the CPU (no GPU, so it works headless and in CI). Pass the SVG text in `svg` or an .svg file of the project in `source`. This is how an agent without an image provider draws a subject (a crest, a portrait silhouette, an ornament, a map symbol): write the shapes as SVG, rasterize, look at the picture in the result, edit the SVG, repeat. The size is `width` x `height` (the SVG is fitted inside, aspect kept, centred; give one and the other follows the SVG's proportions); leave both out for the size the SVG declares. Supported: path (all commands), rect (with rx, ry), circle, ellipse, line, polyline, polygon, g, defs, linearGradient and radialGradient fills (stops, gradientTransform, gradientUnits; write gradient coordinates in percent, x2="100%", or with gradientUnits="userSpaceOnUse" and real coordinates: a bare 0..1 such as x2="1" is read as one pixel), fill, stroke, stroke-width, stroke-linecap, stroke-linejoin, stroke-miterlimit, stroke-dasharray, fill-rule, opacity, fill-opacity, stroke-opacity, transform, the style attribute, viewBox and preserveAspectRatio. Also supported: <clipPath> (clip-path="url(#id)" on a g or on a shape; children path, rect, circle, ellipse, polygon, polyline, line, with their transforms and clip-rule; clipPath transform; only clipPathUnits="userSpaceOnUse", the default, with real coordinates in the user space of the element that uses it), <mask> (mask="url(#id)"; the luminance of the mask's content times its alpha, white shows, black hides; maskUnits and the mask region are ignored, the mask covers the whole picture), and <pattern> fills (fill="url(#id)", also inherited from a g; patternUnits userSpaceOnUse or objectBoundingBox (the default), patternContentUnits, patternTransform, so line hatching is a pattern of one stroked line, rotated with patternTransform="rotate(45)"; the tile is not clipped to its width and height, no pattern viewBox or href chains; a pattern as `stroke` is not drawn). Clipped, masked and pattern shapes are rendered one layer each, so a picture with hundreds of them is slower. NOT supported (drawn as nothing, and named in `warnings`): text and tspan (convert letters to paths, or draw text in the engine with a Text entity), filters (blur, drop shadow), embedded images, <use>, markers and CSS classes in <style>. For a texture of a material (wood, paper, stone) use assets.generate_texture instead. Provenance is recorded in assets.json: by default as AI-made (origin generated, ai true, because the calling agent wrote the SVG, which counts for Steam's AI disclosure); pass ai: false for an SVG a person drew or licensed, with `author` and `license`. Example: {"path":"assets/art/crest.png","width":256,"svg":"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='M50 6 L90 22 V52 C90 76 70 90 50 96 C30 90 10 76 10 52 V22 Z' fill='#8b1e1e' stroke='#e8c66a' stroke-width='4'/><circle cx='50' cy='48' r='14' fill='#e8c66a'/></svg>"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the PNG, project-relative, under assets/ and ending in .png. |
| `svg` | string | no | The SVG document as text, starting with <svg ...>. Give this or `source`. |
| `source` | string | no | A project-relative .svg file, e.g. "assets/art/crest.svg". Give this or `svg`. |
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

The offline makers (assets.rasterize_svg, assets.draw_icon, assets.draw_capsules, assets.generate_texture, assets.synth_sound, assets.generate_loop, assets.pack_atlas, assets.slice_sheet) record in assets.json `provenance.recipe`: {command, args, inputs: [{path, sha256}]}, the command that made the asset, the arguments that make the same bytes again and the project files it read with their hashes. This command runs that recipe through the command registry (any assets.* command that writes a recipe works, there is no list) with `overwrite: true`, and reports per file what changed: "pixels changed", "bytes changed (same pixels)", "unchanged" or "created", the size and the `sheet` layout before and after. Give `path` for one asset, `all` for every asset with a recipe, or `stale` for those whose `inputs` no longer match the files (an SVG or other source file you edited). Assets that read the output of another (a sheet sliced from a picture made from an SVG) are made after it, and `stale` looks again at their inputs when their turn comes. `dryRun` lists what would run and which inputs changed, and changes nothing. What a person recorded in the provenance (license, author, notes) is kept; the recipe and the date are new. Several files made by one call (an icon and its foreground, a texture and its normal map, the capsules of a store) are made once. Provider-made assets (assets.generate_image...) have no recipe: they would cost money and give a different picture, so asking for one is an error that says so. `factoria validate` warns about a stale asset with this command in its hint. Example: {"stale":true} or {"path":"assets/art/coin.png"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the asset to make again (it must record a recipe). |
| `all` | boolean | no | Make every asset with a recipe again. |
| `stale` | boolean | no | Make again only the assets whose recipe inputs (the files they were made from) changed since. |
| `dryRun` | boolean | no | List what would run (command, arguments, which inputs changed) and change nothing. |

## `assets.set_provenance` (modifies state)

Since 0.1.6.

Record where an asset came from (hand-made, imported, or made with AI elsewhere).

Replaces the provenance record of an existing file in assets.json (the recipe that assets.regenerate runs, when the file has one, is kept). The generate commands write it for you; use this for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to true for origin generated, false otherwise). Example: {"path":"assets/music/theme.ogg","origin":"imported","ai":false,"license":"CC0","source":"https://example.com/theme","author":"A. Composer"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of an existing file under assets/. |
| `origin` | string ["generated","imported","original"] | yes | generated: made by an asset provider. imported: brought in from a file made elsewhere. original: made by hand for this game. |
| `ai` | boolean | no | Whether AI made the content. Default: true for origin generated, false otherwise. |
| `kind` | string ["image","sound","music","voice","model3d"] | no | What the asset is, so the disclosure can tell sound effects, music and voice apart. |
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

## `assets.slice_sheet` (modifies state)

Since 0.1.6.

Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them.

SpriteAnimator plays a uniform grid of frames (columns x rows, row-major from the top-left). Two ways to get one:
1. The image already is a grid: give columns/rows (or frameWidth/frameHeight). The grid is checked against the image size (a width that columns does not divide is an error that lists the columns that fit) and recorded as the `sheet` of the image in assets.json. Example: {"path":"assets/hero.png","columns":4,"rows":2,"fps":12}.
2. Frames separated by transparent gutters and of uneven sizes, as AI-generated and downloaded sheets often are: pass auto: true. Every group of touching pixels is a sprite (sprites whose boxes overlap are one frame), ordered by rows then columns, and repacked into a uniform grid of the largest sprite's size, each centred (align "bottom" stands characters on the same ground line). The new PNG is `out` (default <name>_sheet.png next to the image; the source is kept). `frames` is the number of sprites you expect: a different count is an error that lists what was found. Example: {"path":"assets/hero_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}.
background "auto" first makes a solid background transparent (the four corners must be the same opaque colour; the background that touches them is cleared, the same colour inside a sprite stays), also for a grid. The result has the `sheet`, the SpriteAnimator fields and the Sprite texture to use. Aseprite files need no slicing: assets.import reads their frames and tags.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative image (png, jpg, tga, bmp), e.g. "assets/hero.png". |
| `columns` | integer | no | Grid mode: frames per row (1 if neither columns nor frameWidth is given). With auto: frames per row of the new sheet (default: the most sprites found in one row). |
| `rows` | integer | no | Grid mode: number of rows (1 if neither rows nor frameHeight is given). |
| `frameWidth` | integer | no | Grid mode: width of a frame in pixels, instead of columns. |
| `frameHeight` | integer | no | Grid mode: height of a frame in pixels, instead of rows. |
| `frames` | integer | no | Grid mode: how many cells are used, row by row (default all; the last row may be partly empty). With auto: the number of sprites you expect (a different count is an error). |
| `fps` | number | no | Playback speed to put in the SpriteAnimator fields of the result (default 10). Not stored in assets.json. |
| `auto` | boolean | no | Find the frames (groups of touching pixels separated by transparent gutters) and repack them into a uniform grid. Default false. |
| `align` | string ["center","bottom"] | no | auto only: where a sprite sits in its cell. center (default), or bottom: centred horizontally with feet on the cell's bottom edge, for characters standing on the ground. |
| `background` | string ["none","auto"] | no | auto: first make the solid background (the four corners the same opaque colour) transparent. Default none. |
| `out` | string | no | PNG to write when the pixels change (auto, background) or when given: default <name>_sheet.png next to the image. An existing file is replaced; use the image's own path to change it in place. |

## `assets.subset_font` (modifies state)

Since 0.3.0.

Cut a font down to the characters of the locale tables plus Latin and punctuation (a CJK font from 17 MB to a few hundred KB), pinning a variable font's axes.

Reads the font `source` (an absolute path on this machine, or relative to the project) and writes `out` (under assets/) with only the glyphs for: every character of locales/<language>.json for the `locales` (default: factoria.json's localization.languages; the same characters the glyph check of `factoria validate` asks a font for), printable ASCII, Latin-1 (Spanish and French letters), the full-width forms, the CJK punctuation line breaking needs, and the characters of `keep`. The shaping tables (GSUB, GPOS, GDEF, kerning) and the name strings (the license) stay; hinting and glyph names are dropped. A variable font is pinned to one instance (`axes`, default {"wght":400}; its other axes go to their default), because the engine draws a variable font's default instance and a Thin default would draw hairlines. Runs HarfBuzz's subsetter: no Python or fontTools. The result has the sizes, the glyph and character counts, and `missing`: characters of the strings the source font does not have. Nothing is written when the result is the same bytes, so run it again whenever a string changes. Example: {"source":"C:/fonts/NotoSansSC[wght].ttf","locales":["zh-Hans"],"out":"assets/fonts/NotoSansSC-Regular-subset.ttf"}. Check the font's license allows modifying it (SIL OFL fonts do, but ask not to keep the Reserved Font Name; Noto has none) and keep its license file next to the result.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The font to cut: an absolute path on this machine, or a path relative to the project folder. A .ttf or .otf, static or variable. |
| `out` | string | yes | Project-relative .ttf or .otf under assets/ to write, e.g. "assets/fonts/NotoSansSC-Regular-subset.ttf". Replaced if it exists. |
| `locales` | array | no | Languages whose locales/<language>.json give the characters, e.g. ["zh-Hans"]. Default: every language of localization.languages in factoria.json. |
| `keep` | string | no | Extra characters to keep, written out: e.g. the characters a script builds names from, or a whole alphabet. |
| `axes` | object | no | Where to pin the variable font's axes, tag to value: {"wght":400}. Default {"wght":400}. An axis not listed goes to its default. |

## `assets.synth_sound` (modifies state)

Since 0.3.0.

Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.

Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no key. The same preset, seed and seconds always give the same bytes; another `seed` is another take of the same sound (pitch and timing move a little). Levelled to about -18 LUFS (peak under -1 dBFS), so no preset trips validate's loudness warning. Records provenance in assets.json (origin original, ai false, license CC0, the preset and the seed). Presets:
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
| `path` | string | yes | Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. "assets/audio/bark.wav". |
| `preset` | string ["bark","growl","meow","screech","whoosh","explosion","hit","coin","pickup","jump","powerup","laser","blip","click","error","splash","footstep"] | yes | The kind of sound to make. See the list in the command description. |
| `seed` | integer | no | Chooses the take: the same preset and seed always give the same file; change it for a variation (pitch and timing shift up to about 10 percent). Default 0. |
| `seconds` | number | no | Length in seconds. Default: the preset's own length. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |

