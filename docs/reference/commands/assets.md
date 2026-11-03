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

Plays a prefab (`prefab`) or an entity of a scene with its children (`scene` + `entity`) alone in a private world and captures it into a PNG sprite sheet at `path` (under assets/, ending in .png), with its `sheet` entry, provenance and recipe in assets.json. Use it to turn something that costs many draw calls on a phone (a glow made of shapes, a particle burst, a tweened badge, a scripted explosion) into ONE sprite, to make an effect once and play it as a SpriteAnimator, or to draw animated art with the engine's own Shape2D (gradients, strokes) instead of SVG. The world is simulated at the project's fixed step with the world RNG seeded from `seed`, so the same prefab, seed and settings bake the same pixels on the same GPU (the pixels of two different GPUs can differ by an edge pixel); a frame is captured every 1/`fps` seconds of simulated time, `frames` frames per clip. SpriteAnimator, Tint, tweens, ParticleEmitter, Shape2D, Sprite and the entity's scripts all run as in the game; nothing else is in the world (no other entities and no lights: a `lit` sprite is drawn as in a world without lights). The entity is placed at the origin of the world, even when the scene puts it elsewhere. Frame 0 is drawn after one step (the entity's start() has run) and after `warmup` seconds. `clips` bakes several named clips from one entity, each in a fresh world: `[{"name":"explode","call":"explode","frames":24,"loop":false}, {"name":"idle","frames":8}]`; `call` runs that method of the entity's behaviour right after the warm-up (`args` are its arguments), `event` sends a game event instead (`data`); a clip with `clip` plays that clip of the entity's Animator (a key of Animator.clips, a `.anim.json` clip or a glTF animation) from time 0 with no cross-fade, switching the state machine off, and takes `frames` from the clip's duration times `fps` and `loop` from the clip when they are not given; a clip with none of them just plays. They follow each other in the sheet and become clips of its `sheet` entry (firstFrame, lastFrame, fps, loop). Framing: the pixels are drawn at `scale` pixels per world unit and cropped to everything drawn in ANY frame plus `margin`, so nothing is cut (a particle burst that grows is included) and the entity's origin is the same pixel in every frame: it is the `pivot` recorded in the sheet entry ([x, y] in 0..1 from the top-left of the frame). Give `pivot` to choose where the origin lands (a character's feet: [0.5, 1]); give `frameWidth` and `frameHeight` for a fixed cell: without `scale` the animation is scaled to fit it, with `scale` it must fit or the command fails and says how large the cell must be. The colours are straight alpha with the colour of the edge pixels bled outwards, so a sprite scaled with filtering has no dark halo; additive glows keep their light (their alpha is the brightest channel). `background` puts a colour behind the frames (default transparent). `padding` leaves transparent pixels around each cell (default 1; the sheet entry records it). Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL). A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the bake runs in a child `factoria call` process; from a terminal `factoria call assets.bake_sheet` works as is. A script that throws, a `call` that is not a method of the behaviour (with its methods and a suggestion) or a prefab that does not load fail with an error that names the prefab and the script. Provenance: origin generated, `ai` is true when the prefab, the scene or a texture it draws is recorded in assets.json as AI-made (pass `ai` to override, with `author` and `license`); the recipe holds the arguments and the SHA-256 of the prefab or scene, its scripts and textures, so assets.regenerate can make the sheet again and validate can tell when it is stale. Example: {"path":"assets/fx/burst.png","prefab":"prefabs/burst.prefab.json","frames":16,"fps":24,"warmup":0.5,"pivot":[0.5,0.5]}

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

## `assets.check_art`

Not released yet (on main after 0.14.1).

Check pictures against the house style and how they read in the game: palette fit, contrast over the real backgrounds, readability at phone and desktop size, halos on alpha edges, and set consistency; returns an annotated picture.

Measures one picture (`path`) or a set (`paths`, up to 12) and returns an annotated picture plus rules, each with `value`, `threshold`, `verdict` (ok, warn or fail) and, unless ok, a `hint` naming the command or setting that fixes it. Palette fit: the colour count, and when assets.json style.palette is set the distance of the colours to it and the share of pixels off the palette (strict with style.pixelArt). Contrast: the WCAG contrast ratio between the silhouette edge and each background the picture is drawn over: `backgrounds` (colours "#rrggbb" or project image paths) when given, else the clear colour and the large background sprites of the scenes that use the picture, else a light and a dark default; the result says which (`backgrounds.source`). Readability: the picture shrunk to the size it has on screen (`onScreenPx`, the longer side in screen pixels, when given; else derived from the scenes' Sprite size, scale and camera at a phone, 844x390, and a desktop, 1920x1080, screen): its size, how much of the silhouette survives and whether the outline is still a line. Halos and fringes: partly transparent edge pixels that are darker or lighter than the pixels they touch, and transparent pixels next to the shape that hold a foreign colour. Style rules set in assets.json style (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation) are judged too, with the same numbers as the `project.validate` warnings; rules the style does not set are not judged, and `style: false` skips them. With several paths it also compares the set: pixel density, pixel size, outline colour and thickness, and how many colours the pictures share. The picture has one row per asset: the picture itself, its value (greyscale), over each background and at each on-screen size. It is a temporary screenshot in .factoria/screenshots; measuring is cached in .factoria/art-cache. Thresholds and the rules are listed in docs/ASSETS.md ("Checking art: assets.check_art"). Example: {"path":"assets/hero.png","backgrounds":["#203040"],"onScreenPx":48}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the picture to check. Give this or `paths`. |
| `paths` | array | no | Several pictures to check one by one and as a set (pixel density, outline, palette spread). Give this or `path`. |
| `backgrounds` | array | no | What the picture is drawn over. Default: the camera clear colour and background sprites of the scenes that use it, else a light and a dark default. |
| `onScreenPx` | any | no | The longer side of the sprite on screen, in screen pixels: a number, or a list of up to 4. Default: derived from the scenes (Sprite size, scale, camera) at a phone and a desktop screen. |
| `style` | boolean | no | Judge the rules set in assets.json style (outline, lightDirection, texelsPerUnit, pixelArt, value, saturation, palette). False skips them. Default true. |

## `assets.check_mix`

Not released yet (on main after 0.14.1).

Measure every sound of the project together: loudness per bus, music masking effects, clicks, loop seams, clipping, true peak; each finding has a fix.

Listens for what a game's mix gets wrong. Measures the sounds of the project (the set assets.analyze_audio uses without `path`: everything under assets/ and every sound a scene or prefab names), or `paths`, as they play (with the gain import "normalize" applies). Each finding has `sound`, `rule`, `value`, `threshold`, `unit`, `verdict` (ok, warn, fail), a `message` and a `hint` that names the fix; ok findings are left out unless `includeOk` is true. Rules: loudness_target / loudness_spread (loudness of each sound against the target of its bus, or, with no target, against the median of the sounds of its bus: warn beyond 6 LU, fail beyond 12; the bus comes from AudioSource (sfx), SceneSettings.music and audio.music (music) and audio.play("path", {bus}) in scripts, with the parents of factoria.json audio.buses; a sound no scene or script plays with a literal path is on the "unknown bus"); music_masking (the octave bands where an effect has its main energy, against the loudest music there: warn when the music is as loud or louder, fail 6 dB louder); click_start and click_end (the first/last sample or a jump of the first/last step: warn above -40 dBFS, fail above -26); loop_seam_jump and loop_seam_slope (for sounds played looping: the step and the change of slope from the last sample to the first, as multiples of the sound's usual step and curvature); clipping (samples flattened at full scale, counted); true_peak (4x oversampled, as played: warn above -1 dBTP, fail above 0). Loudness targets: the `targets` argument ({"music": -16, "sfx": {"lufs": -14, "toleranceLu": 2}, "default": -16}), else style.audio.loudnessLufs and toleranceLu in assets.json, else the spread rule. Returns {verdict, summary, findings, sounds (one row of numbers per sound), targets, nextSteps}. Deterministic and read-only: it writes nothing (run assets.analyze_audio first to keep the loudness records, so later runs do not measure again). Example: {"targets":{"music":-16,"sfx":-14}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | no | Project-relative sound files to check. Omit for every sound of the project. |
| `targets` | object | no | Loudness targets in LUFS per bus: {"music": -16, "sfx": {"lufs": -14, "toleranceLu": 2}, "default": -16}. A number uses a tolerance of 3 LU. Omit to use style.audio in assets.json. |
| `includeOk` | boolean | no | Also list the checks that passed. Default false. |

## `assets.contact_sheet`

Not released yet (on main after 0.14.1).

Look at a set of images (or .glb models) side by side at their on-screen size, over light, dark and camera-colour backgrounds and in greyscale, labelled with their file names.

Draws one picture (returned to you as an image) with a column for each picture of `paths` (and for each of `sizes`) and a row for each background, so you can judge a set of assets the way the player meets them: small, on the real ground, in black and white. `backgrounds` default to a light colour, a dark colour and the clear colour of the first primary camera of the project's main scene (when it has one); the last row is the same pictures in greyscale over mid-grey (`greyscale: false` leaves it out). `sizes` are pixels of the longest side of each picture as the player sees it (Sprite.size on screen times the render scale): [32, 64] draws every picture twice, shrunk with averaging or grown with hard pixels; without `sizes` each picture is drawn at its native size (at most 512). PNG, JPG, BMP and TGA files are drawn as they are; a sprite sheet (one with a `sheet` entry in assets.json) shows its first frame, or all frames with `allFrames: true`. A .glb model is drawn as a thumbnail by the engine's renderer (a studio light, turned three quarters, transparent around it), which needs a graphics device (Metal, Direct3D 11 or OpenGL; without one the command fails with no_gpu, and you can leave the models out); a model in the real scene, with its lighting, is assets.preview_in_scene. Each column is labelled with the file name and its size in the font that comes with the engine. A line holds `columns` cells (default 8), then the sheet continues below. Nothing is written unless `path` is given: then the PNG is also saved there (an existing file is not replaced without `overwrite: true`). The same inputs give the same picture. Example: {"paths":["assets/hero.png","assets/slime.png"],"sizes":[32,64]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | yes | Project-relative paths of the pictures (PNG, JPG, BMP, TGA) and .glb models to show, in this order. A sprite sheet shows its first frame (see allFrames). |
| `backgrounds` | array | no | Colours ("#rrggbb", a name, or [r, g, b] in 0..1) to draw the pictures over, one row each. Default: a light one, a dark one and the clear colour of the main camera. |
| `sizes` | array | no | Longest side in pixels of each picture as the player sees it; one column per picture and size. Default: the native size of each picture. |
| `greyscale` | boolean | no | Add a last row with the pictures in greyscale over mid-grey, to judge their value structure. Default true. |
| `columns` | integer | no | Cells per line; more wrap to a new block of rows below. Default 8. |
| `allFrames` | boolean | no | A sprite sheet shows all its frames (a column each) instead of the first. Default false. |
| `path` | string | no | Also save the picture as a PNG at this project-relative path (ending in .png). Without it nothing is written. |
| `overwrite` | boolean | no | With `path`: replace the file when it exists. Default false. |

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
- .psd: the layers become an image document (<name>.image.json, one PNG per layer in <name>.layers/; names, opacity, visibility, blend modes, clipping, groups and layer masks are kept) and the PNG is baked from it; a file whose layers cannot be read imports its merged image as a PNG with a warning.
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

## `assets.preview_in_scene`

Not released yet (on main after 0.14.1).

See an asset inside a scene of the game: it is placed (a PNG as a Sprite, a .glb as a MeshRenderer) in a private run of the scene and captured at phone and desktop resolutions.

Starts the scene `scene` in a second, headless engine, steps `steps` frames (default 2) so its scripts start, puts a temporary entity with the asset in the world and captures the view once per resolution. The result is ONE image with the screens side by side, each labelled with its name and size, plus `screens` (each with its position in the picture and, for a 2D camera, whether the asset is in view). The scene file is never changed and the temporary entity exists only in that engine, so nothing needs cleaning up. Where: `at` [x, y(, z)] in world units; or `entity` (an id or name in the scene) with `placement` "beside" (default: to the right of it, using the size of its Sprite or Shape2D, 64 when it has none) or "replace" (at its position, the entity hidden for the picture); `offset` [x, y] moves it from there. Without either, the middle of the view: the camera's position for a 2D scene, a few meters in front of the camera for a 3D one. `center: true` also moves a 2D camera onto the asset (a script that moves the camera can undo it). How big: `size` is in world units like Sprite.size: a number is the longest side (the proportions of the picture are kept), [w, h] sets both; without it the sprite is drawn at its size in pixels. A .glb takes one number, its largest dimension in meters, or its own size. A sprite sheet is placed as its first frame (from its `sheet` entry). `resolutions` are "phone" (540x1170, upright), "tablet" (1024x768), "desktop" (1280x720) or "WxH"; default phone and desktop. The run uses the resolution as the design resolution of the game, so the world a camera shows follows the shape of the screen the way the game's scale mode does on a device: a camera with a fixed orthoSize shows the same height on both. Needs a GPU (Metal, Direct3D 11 or OpenGL; headless Linux needs Mesa's EGL); without one it fails with no_gpu. A process has one graphics device: when this one already uses it (the editor, an MCP session with graphics) the work runs in a child `factoria call` process. The same inputs give the same pixels on the same GPU. Example: {"path":"assets/slime.png","scene":"scenes/main.scene.json","entity":"player","size":48}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of the asset: a PNG/JPG (placed as a Sprite) or a .glb (placed as a MeshRenderer). |
| `scene` | string | yes | Project-relative path of the scene to place it in, e.g. scenes/main.scene.json. The file is read, never written. |
| `at` | array | no | World position [x, y] or [x, y, z] for the asset. Not with `entity`. |
| `entity` | string | no | Id (or name) of an entity of the scene: the asset goes next to it, or in its place (see `placement`). Not with `at`. |
| `placement` | string ["beside","replace"] | no | With `entity`: beside = to the right of the entity; replace = at its position, with the entity hidden in the picture. |
| `offset` | array | no | [x, y] in world units added to the position. |
| `size` | any | no | Sprite: a number (longest side) or [width, height], in world units like Sprite.size; default the size in pixels. Model: its largest dimension in meters; default its own size. |
| `resolutions` | array | no | "phone" (540x1170), "tablet" (1024x768), "desktop" (1280x720) or "WxH". Default ["phone", "desktop"]. |
| `steps` | integer | no | Frames the scene runs before the asset is placed. Default 2. |
| `center` | boolean | no | 2D scenes: move the camera onto the asset so it is in view at every resolution. Default false. |

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

## `assets.review`

Not released yet (on main after 0.14.1).

A cheap one-shot vision review of the pictures you made: a verdict and concrete fixes, grounded on assets.check_art and the style references.

The optional last look of the make, preview, check, fix loop (docs/AI_GUIDE.md 9.23, docs/ASSETS.md "Reviewing art"). It runs assets.check_art on the same pictures first, then sends a vision model the pictures, the annotated picture of the check, the check's numbers, the style rules of assets.json and the style `references` images, and asks what the numbers cannot tell: does it match the style, does it read, does it suit its use. Unlike the user-only art critics of ai.review, you can call it yourself while you work. It uses the model of the "fast" role of ai.json (the orchestrator when fast is off; the artist role is usually an image generator, not a viewer), so the model must accept pictures; with no provider, no key or a text-only model the error says what to set up (docs/AI_PROVIDERS.md) and you carry on with assets.check_art alone. One model call per review: call it once the check shows no `fail`, not after every edit. Result: {verdict: good | fix | redo (never `good` while the check has a fail), summary, fixes: [{what, where, command}], checkArt: {verdict, counts, assets, set}, role, provider, model, warnings, nextSteps}. A fix names a command or an assets.json setting; one that names something this engine does not have is listed in `warnings`. Nothing is written to the project. Example: {"paths":["assets/knight.png","assets/orc.png"],"focus":"do they look like the same game at 48 px?"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path of the picture to review. Give this or `paths`. |
| `paths` | array | no | Up to 4 pictures reviewed together, as a set. Give this or `path`. |
| `focus` | string | no | What you want judged ("does the outline match the references?", "is the coin readable on the dark floor?"). Optional. |

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

## `assets.spectrogram`

Not released yet (on main after 0.14.1).

See a sound: a picture of its waveform, spectrogram (log frequency) and loudness curve, with the clipped samples and the loop seam marked.

Decodes the sound at `path` (.wav, .ogg, .mp3, .qoa) and returns one picture, like assets.preview_sheet does for a sprite sheet: the waveform on top (mid, or each channel; red columns are samples at full scale), a spectrogram in the middle (short-time Fourier transform of the mid channel, 20 Hz to 20 kHz on a logarithmic axis, brighter = louder, with a dB scale) and the loudness curve at the bottom (momentary 400 ms in blue, short-term 3 s in orange, the integrated value dashed, the loudest momentary value marked). When the sound is played looping (an AudioSource with loop, SceneSettings.music, audio.music, or audio.play with loop: true; or `loop: true` here) magenta dashed lines mark the loop seam and the title gives its jump and slope. Axes are labelled with the engine's built-in font. The result carries the numbers: integratedLufs, truePeakDb (4x oversampled), samplePeakDb, momentaryMaxLufs, shortTermMaxLufs, seconds, clippedSamples (samples flattened at full scale), dominantBand (the loudest octave band) and loopSeam. It reuses the sound's fresh `analysis` record for the integrated loudness and writes nothing unless `out` is given. The picture is a temporary screenshot in .factoria/screenshots; with `out` the PNG is kept at that project path. Example: {"path":"assets/music/theme.ogg","width":1200}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative sound file, e.g. assets/sfx/jump.wav. |
| `width` | integer | no | Width of the picture in pixels. Default 1000. |
| `height` | integer | no | Height of the picture in pixels. Default 640. |
| `out` | string | no | Also keep the PNG at this project-relative path (must end in .png). Without it the picture is a temporary screenshot. |
| `loop` | boolean | no | Mark the loop seam. Default: whether the project plays the sound looping (scenes, prefabs and scripts). |
| `channels` | string ["mid","each"] | no | "mid": one waveform of the average of the channels; "each": one lane per channel of a stereo sound. Default "mid". |

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
| `path` | string | yes | Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. "assets/audio/bark.wav". |
| `preset` | string ["bark","growl","meow","screech","whoosh","explosion","hit","coin","pickup","jump","powerup","laser","blip","click","error","splash","footstep"] | yes | The kind of sound to make. See the list in the command description. |
| `seed` | integer | no | Chooses the take: the same preset and seed always give the same file; change it for a variation (the noise changes and the pitch shifts up to 10 percent). Default 0. |
| `seconds` | number | no | Length in seconds: the whole sound (envelopes, sweeps) is stretched to it. Default: the preset's own length. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |

## `audio.bake` (modifies state)

Not released yet (on main after 0.14.1).

Render audio documents to WAV/OGG files next to them (only the missing or stale ones unless forced), with their recipe in assets.json.

Without `path` this bakes every *.audio.json of the project whose sound is missing or out of date (its document or a file it reads changed: the recipe's hashes), like sfx.bake. With `path` it bakes that document. The sound goes to `output.path` of the document, else next to it as <name>.wav (or .ogg); assets.json records provenance (a CC0 license for synthesized sources; the license and author of the files it read otherwise) and the recipe, so assets.regenerate and project.validate know when it is stale. A `loop` step stores its points as the import settings loopStart/loopEnd of the output, which a looping AudioSource honours. A file that nothing baked is never replaced unless overwrite is true. `factoria export` bakes the stale documents first. Example: {} or {"path":"assets/audio/door.audio.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Bake only this document (project-relative, ending in .audio.json). Leave out for every document. |
| `force` | boolean | no | Bake documents that are fresh too. Default false. |
| `dryRun` | boolean | no | List what would be baked and why, and write nothing. Default false. |
| `overwrite` | boolean | no | Replace a file at the output that no audio document baked. Default false. |

## `audio.create` (modifies state)

Not released yet (on main after 0.14.1).

Write a new audio document (a source and a chain of steps) and bake it.

Writes `path` (*.audio.json under assets/) with the format, `source` (a project WAV/OGG/MP3, an .sfx.json patch or another .audio.json), the `steps` (list of step objects; audio.info {} lists the types and fields) and the optional `seed`, `output` ({format wav|ogg, channels source|mono, quality, path}) and `doc` note. The document is checked first: a mistake returns every issue and writes nothing. Then it is baked (unless bake is false) and the result holds the measurements. Example: {"path":"assets/audio/door.audio.json","source":"assets/raw/door.wav","steps":[{"type":"trim","auto":true},{"type":"fade","out":0.05},{"type":"normalize","target":-3}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The audio document, project-relative, under assets/, ending in .audio.json. |
| `source` | string | yes | The sound to start from: a project path ending in .wav/.ogg/.mp3/.qoa, .sfx.json or .audio.json. |
| `steps` | array | no | The chain, in order. Each step is {"type": ..., fields}. |
| `seed` | integer | no | Seed of the random steps. |
| `output` | object | no | {format: wav\|ogg, channels: source\|mono, quality: 0..1 (ogg), path: where to bake}. |
| `doc` | string | no | A note on what the sound is for. |
| `overwrite` | boolean | no | Replace the document when it exists (and the baked sound when nothing baked it). Default false. |
| `bake` | boolean | no | Bake the sound after writing. Default true. |

## `audio.edit` (modifies state)

Not released yet (on main after 0.14.1).

Add, change, remove or move one step of an audio document (or change its source, seed or output), then bake it.

`op` is one of: add (insert `step`, an object, at `index`, default the end), set (change the fields of step `index` with `values`; a null value removes a field), remove (delete step `index`), move (take step `index` to position `to`), document (change `source`, `seed` or `output`). The result document is checked as a whole before anything is written, so a bad value returns every issue with its JSON pointer and writes nothing; the file keeps the other steps as written. Then the sound is baked again (unless bake is false) and the measurements tell what the edit did. Example: {"path":"assets/audio/door.audio.json","op":"set","index":2,"values":{"target":-6}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The audio document, project-relative, under assets/, ending in .audio.json. |
| `op` | string ["add","set","remove","move","document"] | yes | What to do. |
| `index` | integer | no | The step to act on (add: where to insert it). |
| `step` | object | no | add: the new step, {"type": ..., fields}. |
| `values` | object | no | set: fields to change; null removes a field. |
| `to` | integer | no | move: the new position. |
| `source` | string | no | document: the new source. |
| `seed` | integer | no | document: the new seed. |
| `output` | object | no | document: the new output settings. |
| `bake` | boolean | no | Bake the sound after writing. Default true. |
| `picture` | boolean | no | Return the waveform/spectrogram picture after baking. Default false. |
| `overwrite` | boolean | no | Replace a sound that no audio document baked. Default false. |

## `audio.info`

Not released yet (on main after 0.14.1).

Check an audio document and say what its chain renders to; with no arguments, list the step types and their fields.

An audio document (`*.audio.json`, docs/SOUND.md "Audio documents") is a non-destructive chain over a sound: a WAV/OGG, an .sfx.json patch or another audio document, then steps (trim, fade, normalize, gain, pitch, stretch, speed, eq, compressor, reverb, delay, reverse, layer, loop, granular). With `path` (or an inline `document`) this checks it: a document with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and the fix; a valid one returns its steps, where it bakes to and whether that sound is fresh or stale, and (unless render is false) renders it in memory: seconds, loudness, peak, brightness (centroidHz), the loop points of a loop step and the length and peak after each step. With no argument it returns the catalog of step types with every field, its range, default and doc string. Example: {"path":"assets/audio/door.audio.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The audio document, project-relative, under assets/, ending in .audio.json. |
| `document` | object | no | The document itself, as JSON, to check before writing it to a file (format is filled in). |
| `seed` | integer | no | Render this take (replaces the document's seed). |
| `render` | boolean | no | Render the chain in memory for the measurements. Turn it off to only check it. Default true. |

## `audio.render`

Not released yet (on main after 0.14.1).

Render an audio document in memory: measurements, what each step did, and a waveform/spectrogram picture. Writes nothing.

Applies the chain of the document (`path`, or an inline `document`) and returns the measurements (seconds, integrated loudness in LUFS, peak in dBFS, centroidHz, loop points), the length and peak after every step, and a picture (`$image`): the source and the result, each as a waveform over a spectrogram with its numbers, on one time and level scale. `stopAfter` renders only steps 0..stopAfter to hear the chain up to a step; `seed` takes another take of the random steps. The same document and files always render the same samples. Example: {"path":"assets/audio/door.audio.json","stopAfter":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | The audio document, project-relative, under assets/, ending in .audio.json. |
| `document` | object | no | The document itself, as JSON, instead of `path`. |
| `seed` | integer | no | Replaces the document's seed for this render. |
| `stopAfter` | integer | no | Render only steps 0..stopAfter. |
| `compare` | boolean | no | Show the unprocessed source above the result in the picture. Default true. |
| `picture` | boolean | no | Return the picture (`$image`). Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |

## `image.bake` (modifies state)

Not released yet (on main after 0.14.1).

Draw a layered image document (*.image.json) into its PNG and return the picture.

Composites the layers of the image document at `path` (project-relative, ending in .image.json) on the CPU and writes the PNG next to it (hero.image.json -> hero.png, or the document's `output`). Bytes are deterministic: the same document and files give the same PNG. Records provenance and the recipe {command image.bake, args {path}, inputs: the document and every file it reads} in assets.json, so assets.regenerate remakes the PNG and `factoria validate` warns when the document or a source file changed since (stale). A picture with a provider layer, or built from AI-made files, is recorded as AI-made. The result has the picture as `$image`, its size and any warnings. A problem in the document is an error with the file, the JSON pointer and a fix. Format and layers: docs.read IMAGES. Example: {"path":"assets/art/hero.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. "assets/art/hero.image.json". |
| `onlyIfNeeded` | boolean | no | Skip the drawing when the PNG already matches the document and every file it reads (what the export does). Default false. |

## `image.create` (modifies state)

Not released yet (on main after 0.14.1).

Make a new layered image document (*.image.json) with a canvas size, a background and optional first layers, and bake its PNG.

Writes a new image document at `path` (project-relative, ends in .image.json) with a width x height canvas (1..4096), an optional `background` colour and optional `layers` (bottom first; docs.read IMAGES lists the kinds), then bakes the PNG next to it. Refuses to replace an existing file unless overwrite is true. The result has the picture as `$image`, the changed `region` {x,y,width,height} (the whole canvas for a new document) and next steps. Example: {"path":"assets/art/hero.image.json","width":64,"height":64,"background":"#00000000","layers":[{"kind":"fill","name":"sky","color":"#203040"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the document, project-relative, ending in .image.json. |
| `width` | integer | yes | Canvas width in pixels. |
| `height` | integer | yes | Canvas height in pixels. |
| `background` | any | no | A colour the canvas starts with: "#rrggbb", "#rrggbbaa", a CSS name or [r,g,b,a]. Without it the canvas starts transparent. |
| `layers` | array | no | The first layers, bottom first, each an object with `kind` (see docs.read IMAGES). Default none. |
| `description` | string | no | A sentence for people and AIs about the picture. |
| `palette` | any | no | For indexed (pixel-art) layers: "style" (the style palette of assets.json, the default for an indexed layer) or a list of colours, each "#rrggbb" or {"name", "color"}; at most 81. See docs.read IMAGES, "Pixel art". |
| `ramps` | array | no | Colour ramps for shading by index: lists of palette colours (index, name or "#rrggbb") from the darkest to the lightest, e.g. [["skin-dark","skin","skin-light"]]. |
| `overwrite` | boolean | no | Replace the document when it already exists. Default false. |
| `bake` | boolean | no | Also draw the PNG. Default true. |

## `image.draw` (modifies state)

Not released yet (on main after 0.14.1).

Draw pixel-exact shapes (lines, rectangles, ellipses, polygons, flood fills) onto an indexed pixel-art layer by palette colour.

Each shape of `shapes` is drawn in order on the indexed layer `layer` (see image.pixel for `layer`, `create`, coordinates and colours); no anti-aliasing: a pixel is either set or not. Shapes: line {points [[x,y],...] (a polyline), color, perfect?, closed?} (Bresenham; `perfect: true` removes the L-corners of a bending line so it is one pixel thick everywhere); rect {x, y, width, height, color?, fill?}; ellipse {x, y, width, height, color?, fill?} (inscribed in the box, midpoint algorithm, any odd or even size); polygon {points (>= 3), color?, fill?}; fill {at [x,y], color, connectivity? 4|8} (flood fill of the layer's pixels connected to `at` that hold the same colour or transparency; 4 does not leak through diagonal gaps). For rect, ellipse and polygon `color` is the outline and `fill` the inside: a colour, or true for `color`; give either or both (the fill is drawn first, so the outline stays). Result as image.pixel (`region`, `pixelsSet`, `$image` magnified with hard pixels). Example: {"path":"assets/art/hero.image.json","layer":"sprite","create":true,"shapes":[{"type":"ellipse","x":2,"y":2,"width":12,"height":12,"fill":"skin","color":"outline"},{"type":"line","points":[[2,14],[8,10],[14,14]],"color":"outline","perfect":true},{"type":"fill","at":[8,8],"color":"skin-light"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `layer` | any | yes | The indexed layer to draw on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create a blank indexed layer with it at the top. Default false. |
| `shapes` | array | yes | The shapes, drawn in order. |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.edit` (modifies state)

Not released yet (on main after 0.14.1).

Change the selected pixels of one layer of an image document: fill, recolor, move, transform (scale, rotate, flip), delete, copy or cut to a new layer.

Applies `action` to the pixels of `layer` inside the stored `selection` (made with image.select; "all" is the whole canvas). Actions: fill {color, opacity?}; recolor {hueShift degrees, saturation -1..1, value -1..1} or {from, to, tolerance?, keepShading?}; move {dx, dy, copy?} (whole pixels; the selection moves along unless moveSelection is false); transform {scale number or [sx,sy], rotate degrees clockwise, flipH, flipV, filter nearest|bilinear, pivot [x,y]} (the selected pixels are lifted, transformed around the pivot - default their middle - and put back; the default filter is nearest when the project's style guide says pixelArt, else bilinear); delete (the selected pixels become transparent); copy and cut {name?} (the selected pixels become a new pixels layer above `layer`; cut also clears them). POLICY FOR OTHER LAYER KINDS: a pixels layer's PNG is edited in place (an AI-generated image keeps that mark, the edit is added to its provenance). A shape, gradient, text or other non-pixel layer is first rasterized: it becomes a pixels layer (its masks, adjustments and effects are baked into the pixels, its blend, opacity and visibility stay) with a new PNG in <document>.layers/ and a warning says so. Groups and adjustment layers cannot be edited this way. A layer with masks keeps its box (the masks are in its own pixels), so pixels moved outside it are dropped (a warning counts them); other layers grow to hold what you move into the canvas. Result: the baked document plus `region` {x,y,width,height} of the changed pixels, `changed` and the picture as `$image`. Example: {"path":"assets/art/hero.image.json","selection":"cape","layer":"hero","action":{"type":"recolor","hueShift":120}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `selection` | string | yes | The stored selection to act on (image.select), or "all". |
| `layer` | any | yes | The layer to change: its name or an index path like "1/0". |
| `action` | object | yes | What to do. type: fill, recolor, move, transform, delete, copy, cut. See the command description for each action's fields. |
| `name` | string | no | copy / cut: the new layer's name (default: '<layer> copy' / '<layer> cut'). |
| `bake` | boolean | no | Bake the document to its PNG after the edit. Default true. |

## `image.export` (modifies state)

Not released yet (on main after 0.14.1).

Write the flattened picture of a document, or one layer or group of it, to a PNG, optionally scaled or trimmed.

Draws the document at `path` (or only `layer`, by name or index path, with its masks, adjustments and effects but at full opacity and normal blend; the offsets of the groups around it count) and writes a PNG to `out`. `scale` resizes (0.01..16) with `filter` nearest (pixel art) or bilinear; the default filter is nearest when assets.json style.pixelArt is true, else bilinear. `trim` crops to the pixels that show. The PNG is a plain copy, not baked from the document. Refuses to replace an existing file unless overwrite is true. Example: {"path":"assets/art/hero.image.json","out":"assets/art/hero-x2.png","scale":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document. |
| `out` | string | yes | The PNG to write, project-relative, ending in .png. |
| `scale` | number | no | Size factor of the result. Default 1. |
| `layer` | any | no | Export only this layer or group (name or index path) instead of the whole picture. |
| `trim` | boolean | no | Crop to the pixels that are not transparent. Default false. |
| `filter` | string ["nearest","bilinear"] | no | How scale resamples. Default: nearest for pixel-art projects, else bilinear. |
| `overwrite` | boolean | no | Replace `out` when it exists. Default false. |

## `image.info`

Not released yet (on main after 0.14.1).

Describe a layered image document: its layers as a tree with index paths, sizes, bake status, the files it reads and its stored selections.

Reads the document at `path` and returns {document, width, height, background, valid, problems?, palette?: {source, colors, ramps} (when it has one: image.palette lists it), layers: [{index, pointer, name, kind, visible, opacity, blend, x, y, size?, source?, masks?, adjustments?, effects?, children?}], inputs, bake: {state, path, reason}, selections, $image}. `index` is the index path other image.* commands take in `layer` ("1/0"); names work too. `bake.state` is fresh, missing, stale, unrecorded or broken. `$image` is the baked PNG when it exists. Read-only. Example: {"path":"assets/art/hero.image.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative. |

## `image.layer.add` (modifies state)

Not released yet (on main after 0.14.1).

Add a layer to an image document (at the top, or at an index, or inside a group) and bake the picture.

Adds the `layer` object (its `kind` and fields as docs.read IMAGES describes) to the document at `path`: on top of the root list by default, at `index` (0 = the bottom) of the list, or inside the group `parent`. A layer without `name` gets one from its kind ("fill", "fill 2"); names must be distinct because they address layers. The document is checked completely (a problem names the JSON pointer, nothing is written) and baked. The result has the picture as `$image`, the changed `region`, and `layer` {index, pointer, name, kind} of the new layer. Example: {"path":"assets/art/hero.image.json","layer":{"kind":"text","text":"Hi","size":16,"x":4,"y":4}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. |
| `layer` | object | yes | The layer: {kind, name?, visible?, opacity?, blend?, x?, y?, clip?, masks?, ...fields of its kind}. |
| `parent` | any | no | A group (name or index path) to add the layer into. Default: the top level. |
| `index` | integer | no | Position in the list, 0 = the bottom. Default: the top. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.convert` (modifies state)

Not released yet (on main after 0.14.1).

Turn a layer into an indexed pixel-art layer (quantized to the palette, optional dither) or an indexed layer back into a pixels layer.

`to: "indexed"`: the layer, drawn alone with its masks, adjustments and effects, is cropped to what it shows and each visible pixel takes its nearest palette colour (OKLab by default, `space: "rgb"` for stored values) with an optional `dither` (none, bayer2, bayer4, bayer8, floydSteinberg, atkinson; ordered patterns line up with the canvas) at `strength` 0..1; pixels at least `alphaThreshold` (default 0.5) opaque are kept, the others become transparent; a pixel that already has a palette colour keeps it, so pixels -> indexed -> pixels loses nothing. The palette is the document's, else `palette` (written into the document), else the style palette. A layer made from an AI-made picture marks the new layer `ai: true`. Masks, adjustments and effects are drawn into the pixels. `to: "pixels"`: the indexed layer is written as a PNG (in <document>.layers/) and becomes a pixels layer, so blur, edit and paint work on it. Both directions keep the layer's name, visibility, opacity, blend and clip, and place it where it was. Result: the baked document, `layer`, `colorsUsed`, `region`, warnings and `$image` magnified with hard pixels. Example: {"path":"assets/art/hero.image.json","layer":"painted","to":"indexed","dither":"bayer4"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
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

Not released yet (on main after 0.14.1).

Move a layer to another position in its list, or into another group (or back to the top level), and bake.

`index` is the layer's position in its list afterwards (0 = the bottom, so a higher index is drawn over more layers); without it the layer goes to the top of the list. `parent` moves it into that group (a name or index path; "" is the top level). The layer keeps its own x, y: moving it between groups with different offsets moves it on the canvas. A layer cannot move into its own children. The result has the picture as `$image` and the changed `region`. Example: {"path":"assets/art/hero.image.json","layer":"glow","index":0}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `index` | integer | no | Position afterwards, 0 = the bottom. Default: the top. |
| `parent` | any | no | Group to move into (name or index path), or "" for the top level. Default: stay in the same list. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.remove` (modifies state)

Not released yet (on main after 0.14.1).

Remove a layer (and the children of a group) from an image document and bake.

Deletes the layer addressed by name or index path. Its PNG stays on disk. Warns when the layer above was clipped to it. The result has the picture as `$image`, the changed `region` and `removed` {index, pointer, name, kind}. Example: {"path":"assets/art/hero.image.json","layer":"1/0"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.layer.set` (modifies state)

Not released yet (on main after 0.14.1).

Change fields of one layer (name, visible, opacity, blend, x, y, clip, masks, adjustments, effects, its kind's fields) and bake.

Merges `set` into the layer: a field you give replaces the old one (objects such as `gradient` merge key by key; arrays such as `masks` are replaced whole), null removes a field. The `kind` cannot change. The layer is addressed by name or index path; a wrong name gets a did-you-mean and the layer list. The document is checked completely before anything is written. The result has the picture as `$image` and the changed `region`. Example: {"path":"assets/art/hero.image.json","layer":"shadow","set":{"opacity":0.4,"blend":"multiply"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json, e.g. 'assets/art/hero.image.json'. |
| `layer` | any | yes | A layer: its name ('sky') or its index path ('1' is the second layer from the bottom, '1/0' the first child of the group at 1). Index paths count from the bottom, like the document. |
| `set` | object | yes | The fields to change, e.g. {"opacity":0.5,"visible":false}. null removes a field. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.paint` (modifies state)

Not released yet (on main after 0.14.1).

Paint round-brush strokes onto a pixels layer of an image document (deterministic stamping), creating the layer's PNG when asked.

Each stroke {points [[x,y],...], size, color, hardness?, opacity?, erase?, spacing?} stamps a round brush of diameter `size` along the polyline: one stamp at the first point, then one every `spacing` pixels (default a fifth of the size, at least 1) of arc length, and one at the last point. A pixel gets the largest coverage any stamp of the stroke gives it, so a stroke does not darken where it crosses itself; `opacity` then scales the whole stroke, `hardness` 1 is a hard edge (half a pixel anti-aliased) and lower values fade from hardness*radius to the edge. `erase: true` lowers the alpha instead of painting. Strokes apply in order and the same input always gives the same pixels (no randomness, no pressure). `layer` is a name or an index path; an unknown name with `create: true` makes a new empty pixels layer at the top of the document. A non-pixel layer is rasterized first, as in image.edit (a warning says so). `selection` limits the painting to a stored selection. Coordinates are canvas pixels; the layer grows to hold what is painted (a layer with masks keeps its box). Result: the baked document, `region`, `changed`, `stamps` and the picture as `$image`. Example: {"path":"assets/art/hero.image.json","layer":"paint","create":true,"strokes":[{"points":[[4,4],[40,20]],"size":3,"color":"#ff0000"}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `layer` | any | yes | The layer to paint on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create an empty pixels layer with it at the top. Default false. |
| `selection` | string | no | A stored selection (image.select) that limits where the strokes paint. |
| `strokes` | array | yes | The strokes, painted in order. |
| `bake` | boolean | no | Bake the document to its PNG after painting. Default true. |

## `image.palette` (modifies state)

Not released yet (on main after 0.14.1).

Show or change the palette and the colour ramps that indexed pixel-art layers of an image document are locked to.

Without `palette` and `ramps` it only reads: every colour with its index, the character that stands for it in the layers' rows, name, #rrggbb, how many pixels use it, its ramp, and the colour one step darker (`shade`) and lighter (`light`); the palette is the document's `palette`, or the style palette of assets.json when the document has none. With `palette` (a list of colours, each "#rrggbb" or {name, color}, at most 81, all different; or "style") and/or `ramps` (lists of palette colours from the darkest to the lightest, each colour in one ramp; null removes) it rewrites them and bakes. Pixels keep their INDEX, so replacing the palette recolours the layers: append colours to keep the old ones. Without a declared ramp a colour's shade is the palette colour with lower lightness nearest to it in OKLab. Example: {"path":"assets/art/hero.image.json","palette":["#1a1c2c",{"name":"skin","color":"#e0a070"},{"name":"skin-dark","color":"#b06a40"}],"ramps":[["skin-dark","skin"]]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `palette` | any | no | New palette: "style" or a list of colours, each "#rrggbb" or {"name", "color"}; null removes the document's palette (the style palette applies). Omit to only read. |
| `ramps` | any | no | New ramps: [[colour, colour, ...], ...] darkest first, colours by index, name or "#rrggbb"; null removes them. |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.pixel` (modifies state)

Not released yet (on main after 0.14.1).

Write exact pixels (a list, runs or a text stamp) onto an indexed pixel-art layer by palette colour; no anti-aliasing.

Draws on an INDEXED layer (kind "indexed": the pixels are palette indices; docs.read IMAGES, "Pixel art"). `layer` is its name or index path; an unknown name with `create: true` makes a new blank indexed layer (canvas-sized, on top). Coordinates are canvas pixels (the layer's own offset and its groups' are accounted for); pixels outside the layer are dropped and counted in a warning. Three forms, applied in this order: `pixels` [[x, y, colour], ...]; `runs` [[x, y, length, colour], ...] (horizontal, to the right); `stamp` {x, y, rows: ["..11..", ".1221."], clear?} (text rows in the document's own characters: '.' is transparent and leaves the pixel alone unless `clear` is true). A colour is a palette index, name or colour; a colour not in the palette is an error with the nearest one. {"step": -1} shades the pixel one step along its colour ramp (see image.palette). When the document has no `palette` yet, the style palette is copied into it. Result: the baked document, `region` {x,y,width,height} of the changed pixels, `pixelsSet`, `changed`, and `$image` = the picture magnified with hard pixels (`previewScale`, default as large as fits 512 pixels). Example: {"path":"assets/art/hero.image.json","layer":"sprite","create":true,"pixels":[[3,4,"skin"],[4,4,2]],"runs":[[2,6,5,"outline"]]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
| `layer` | any | yes | The indexed layer to draw on: its name or an index path like "1/0". |
| `create` | boolean | no | When no layer has that name, create a blank indexed layer with it at the top. Default false. |
| `pixels` | array | no | [[x, y, colour], ...]: single pixels. A palette colour: its index (3), its name ("skin"), its single index character ("3"), or a colour that IS in the palette ("#e0a070"). null, "." or "transparent" erases. {"step": -1} is one shade darker than what is in the pixel (+1 lighter); {"color": "skin", "step": 1} is the colour one step lighter than skin. A colour outside the palette is an error that names the nearest palette colour. |
| `runs` | array | no | [[x, y, length, colour], ...]: horizontal runs of one colour starting at (x, y) going right. |
| `stamp` | object | no | A little picture in text rows placed at (x, y). |
| `scale` | integer | no | Magnification of the preview picture (default: automatic). |
| `bake` | boolean | no | Also draw the PNG (default true). False only writes the document. Default true. |

## `image.save` (modifies state)

Not released yet (on main after 0.14.1).

Check an image document, write it to a *.image.json file and bake its PNG; nothing is written when the document has a problem.

Validates `document` (the layered image document as JSON: canvas width and height, background, layers bottom first; see docs.read IMAGES), writes it to `path` (project-relative, ending in .image.json) as canonical JSON and bakes the PNG like image.bake. A problem in the document is an error naming the JSON pointer (/layers/2/blend), what is wrong and how to fix it, and writes nothing. Example: {"path":"assets/art/sky.image.json","document":{"width":128,"height":128,"layers":[{"kind":"gradient","gradient":{"angle":0,"stops":[{"at":0,"color":"#102040"},{"at":1,"color":"#e08040"}]}},{"kind":"text","text":"Hi","size":32,"x":8,"y":8}]}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the document, project-relative, ending in .image.json. |
| `document` | object | yes | The image document: {"width", "height", "background"?, "output"?, "layers": [...]}. See docs.read IMAGES for the layer kinds. |
| `bake` | boolean | no | Also draw the PNG. False only checks and writes the document. Default true. |

## `image.select` (modifies state)

Not released yet (on main after 0.14.1).

Select part of an image document's canvas (by colour, alpha, rectangle, ellipse, polygon or a layer's shape) and store it by name for image.edit and image.paint.

Builds a selection: a coverage (0..255) per canvas pixel. `by` picks how: color (pixels within `tolerance` 0..255 of `color`, or of the pixel at `at`; `contiguous: true` only the connected area around `at`), alpha (pixels whose alpha is at least `threshold`), rect or ellipse (x, y, width, height; anti-aliased), polygon (`points` [[x,y],...]), layer (the layer's shape: its alpha after its masks and effects, soft edges kept) or all. color and alpha read the flattened picture, or only `layer` when it is given. `then` reshapes the new selection with steps in order: [{"grow":2},{"shrink":1},{"feather":1.5},{"invert":true}] (pixels; grow and shrink use a round brush and make a hard edge; feather is a blur of sigma pixels/2). `mode` combines the result with the stored selection of the same `name`: replace (default), add, subtract or intersect. Without `by`, `then` reshapes the stored selection; `clear: true` deletes it. PERSISTENCE: the selection is saved as a grey PNG of the canvas at .factoria/selections/<document path>/<name>.png (white = selected) and stays until replaced or cleared; later calls use it by name (the name "all" is the whole canvas without a file). Changing the canvas size makes old selections unusable (they say so). The result has `selected` (pixels), `coverage`, the bounding box as `region` {x,y,width,height} and the picture with the selection marked as `$image`. Example: {"path":"assets/art/hero.image.json","name":"cape","by":"color","at":[20,30],"contiguous":true,"tolerance":20,"then":[{"grow":1}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The image document, project-relative, ending in .image.json. |
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

## `sfx.bake` (modifies state)

Not released yet (on main after 0.14.1).

Render every sound patch of the project whose WAV is missing or out of date.

Finds every assets/**/*.sfx.json and renders the ones whose sound (the patch's path with .wav) does not exist, or was made by sfx.render from a patch that has changed since (the recipe's input hash differs: the same check project.validate does). Sounds that are up to date are left alone, a file at that path that sfx.render did not make is skipped and reported, and a patch with mistakes is listed in `failed` with its issues while the others are still baked. An existing recipe keeps its own arguments (seed, note, macros, an .ogg `out`). A patch with `variations` is baked with all its takes (name_01.wav ... each with a recipe of its own). `macros` replaces the macro values of every render in this call (it forces them and is kept in the recipes). No pictures are returned; use sfx.render for one patch. Example: {"dryRun":true} lists what would be rendered.

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Render every patch again, even when its sound is up to date. Default false. |
| `macros` | object | no | Macro values for every sound rendered by this call, e.g. {"weight": 0.4}. Forces the render and is kept in the recipes. |
| `dryRun` | boolean | no | List what would be rendered and why, and write nothing. Default false. |

## `sfx.family` (modifies state)

Not released yet (on main after 0.14.1).

Make a consistent set of interface sounds (click, hover, confirm, cancel, error, open, close, notify) from one base patch.

Writes one patch per sound into the `out` directory (default: the base's path without .sfx.json plus _family), each a COPY of the base patch `from` with what that role changes: its length and tail, macros (brighter for a hover, heavier and gritty for an error), an arpeggio (confirm goes up, cancel down) or a pitch slide (open up, close down). They share the base's oscillators, filters, effects and master.normalize, so they share timbre and loudness; being copies they stand alone (editing the base later does not change them; make the family again with overwrite: true). Names: click, hover, confirm, cancel, error, open, close, notify; `preset: "ui"` makes all eight. Unless `render` is false each is baked to name.wav with a recipe (so sfx.bake keeps them current). The result lists the measurements of each (lufs, peakDb, seconds, centroidHz), the spread of loudness in LU, and one picture with a row per sound. Example: {"from":"assets/audio/ui.sfx.json","preset":"ui"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | string | yes | The base patch, project-relative, ending in .sfx.json: the timbre every sound shares. |
| `names` | array | no | Which sounds to make: click, hover, confirm, cancel, error, open, close, notify. |
| `preset` | string | no | "ui": make all eight sounds. Give this or `names`. |
| `out` | string | no | Directory under assets/ for the patches (and their sounds). Default: the base's path without .sfx.json plus _family. |
| `overwrite` | boolean | no | Replace patches and sounds that exist. Default false. |
| `render` | boolean | no | Bake each sound to a WAV too (default); false writes only the patches and measures them in memory. Default true. |
| `picture` | boolean | no | Return the contact sheet (`$image`): one row per sound. Default true. |
| `pictureOut` | string | no | Also keep the sheet's PNG at this project path (ends in .png). |
| `width` | integer | no | Width of the picture in pixels (default 1000). |

## `sfx.info`

Not released yet (on main after 0.14.1).

Check a sound patch and say what it holds and how loud it renders, without writing anything.

Reads a sound patch from `path`, or takes it inline as `patch` (JSON) or by `preset` name, and checks it against the format (docs/SOUND.md). A patch with mistakes returns valid false and ALL its issues, each with the JSON pointer, what is wrong and how to fix it, so one call is enough to repair it. A valid patch returns its layers (oscillators, start, pitch), its effects, the base pitch (rootHz), its macros (the declared values) and variations (count and the files they bake to), whether its baked sound exists and is stale, and the loudness, peak, length, brightness (centroidHz) and attack (riseSeconds) it renders to (it is rendered in memory; nothing is written). Example: {"path":"assets/audio/coin.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | A sound patch file, project-relative, ending in .sfx.json. |
| `patch` | object | no | The patch itself, as JSON, to check before writing it to a file. |
| `preset` | string | no | The name of a preset (see sfx.preset). |
| `seed` | integer | no | Render this take for the measurements (default 0). |

## `sfx.preset` (modifies state)

Not released yet (on main after 0.14.1).

List the sound presets, return one as an editable patch, or write it to a *.sfx.json file.

The presets of assets.synth_sound (bark, growl, meow, screech, whoosh, explosion, hit, coin, pickup, jump, powerup, laser, blip, click, error, splash, footstep) are sound patches shipped in the engine. Without `name` this lists them. With `name` it returns the patch (the exact JSON that renders): read it to learn the format, or change it. With `name` and `path` it writes the patch to that *.sfx.json file under assets/ (an existing file is an error unless overwrite is true), ready for sfx.render. Example: {"name":"laser","path":"assets/audio/laser.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | The preset to return. Leave out to list them all. |
| `path` | string | no | Write the patch here: project-relative, under assets/, ending in .sfx.json. |
| `overwrite` | boolean | no | Replace the file when it exists. Default false. |

## `sfx.render` (modifies state)

Not released yet (on main after 0.14.1).

Render a sound patch (*.sfx.json) to a WAV or OGG next to it and see its spectrogram: the engine's own synthesizer, offline and deterministic.

Reads the sound patch at `path` (assets/.../name.sfx.json, format factoria.sfx/1: layers of oscillators with envelopes, pitch sweeps and arpeggios, filters, FM and ring modulation, distortion, bitcrush, delay and reverb; docs/SOUND.md and schemas/sfx.schema.json) and renders it to mono 16-bit WAV at `out` (default: the patch's path with .wav; a path ending in .ogg encodes Ogg Vorbis). No provider, no key, no other program: the same patch, `seed` and options give the same bytes on every platform. The sound is levelled to the patch's normalization (default -18 LUFS, peak under -1 dBFS). The file gets provenance and a recipe in assets.json whose input is the patch, so project.validate warns when the patch changed after the sound was made and assets.regenerate renders it again. A patch with mistakes fails with `invalid_patch` and every problem in data.issues (JSON pointer, what is wrong, how to fix it). The result has measurements (lufs, peakDb, seconds), the numbers of the file as written (`analysis`, from assets.spectrogram) and the picture (`$image`): waveform, spectrogram and loudness curve. Options that change one render without editing the patch: `seed` (another take of the noise), `freq` or `note` (transpose so the patch's base pitch becomes this), `length`, `tail`, and `macros` (meaning knobs from -1 to 1: attack, brightness, weight, tail, pitch, grit, plus the patch's own; they replace the values the patch declares). A patch that declares `variations` renders one take with `variant` (1-based; the file is name_NN.wav) or all of them with `variants: true`, which returns the measurements of each and one picture with a row per variant. The measurements also have centroidHz (the brightness) and riseSeconds (the attack). An existing file that sfx.render did not make is an `exists` error unless overwrite is true. Example: {"path":"assets/audio/coin.sfx.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The sound patch, project-relative, under assets/ and ending in .sfx.json, e.g. "assets/audio/coin.sfx.json". |
| `out` | string | no | Where to write the sound: .wav or .ogg under assets/. Default: the patch's path with .wav. |
| `seed` | integer | no | Added to the patch's seed: another take of every noise. The same seed always gives the same file. Default 0. |
| `freq` | number | no | Transpose the patch so its base pitch (the first pitched layer's pitch.freq) becomes this frequency in Hz. Fixed-frequency oscillators stay. |
| `note` | string | no | The same as freq as a note name: "C4" (middle C), "A4" (440 Hz), "C#3", "Bb2". |
| `length` | number | no | Seconds the sound is held, replacing the patch's `length` for this render. |
| `tail` | number | no | Seconds after the length for releases, echoes and reverb, replacing the patch's `tail`. |
| `macros` | object | no | Macro values for this render, e.g. {"brightness": 0.3, "tail": -0.5}: attack, brightness, weight, tail, pitch, grit or a macro the patch declares. Replaces the patch's declared value; kept in the recipe. |
| `variant` | integer | no | Render this variation (1-based) of a patch that declares `variations`; the default out is name_NN.wav. |
| `variants` | boolean | no | Render every variation of the patch to name_01.wav, name_02.wav... and return one picture with a row per variant. Takes neither `out` nor `variant`. Default false. |
| `picture` | boolean | no | Return the spectrogram picture (`$image`) of the sound. Turn it off when rendering many. Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). Default: a temporary screenshot. |
| `width` | integer | no | Width of the picture in pixels (default 1000). |
| `height` | integer | no | Height of the picture in pixels (default 640). |
| `overwrite` | boolean | no | Replace the sound when it exists and was not made by sfx.render (a sound made by it is always replaced). Default false. |

## `sfx.tweak` (modifies state)

Not released yet (on main after 0.14.1).

Turn a patch's macros by meaning (brighter, longer tail, heavier) and write the change back to the patch.

`macros` is {name: amount}: attack, brightness, weight, tail, pitch, grit (each from -1 to 1; 0 is the patch as written) or a macro the patch declares. Each amount is ADDED to the value the patch declares now (+0.2 brighter than it is), or is the new value when `absolute` is true; the result is clamped to -1..1 and written to the patch's `macros` (the file is rewritten with the same keys in the same order). Then the sound (and its variations) is rendered again and the result compares the measurements before and after: centroidHz rises with brightness, seconds with tail, riseSeconds with a slower attack. An unknown macro is an error with a 'did you mean'. Example: {"path":"assets/audio/coin.sfx.json","macros":{"brightness":0.2}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | The sound patch, project-relative, ending in .sfx.json. |
| `macros` | object | yes | Macro name to amount, e.g. {"brightness": 0.2, "tail": -0.3}. |
| `absolute` | boolean | no | Set the macros to these values instead of adding to the declared ones. Default false. |
| `render` | boolean | no | Render the sound again and compare the measurements. Turn it off to only edit the patch. Default true. |
| `seed` | integer | no | Seed of the renders (default 0). |
| `picture` | boolean | no | Return the spectrogram picture (`$image`). Default true. |
| `pictureOut` | string | no | Also keep the picture's PNG at this project path (ends in .png). |
| `width` | integer | no | Width of the picture in pixels. |
| `height` | integer | no | Height of the picture in pixels. |

## `vector.align` (modifies state)

Not released yet (on main after 0.14.1).

Align SVG elements to each other, the canvas or a key element.

Moves the picked elements (shapes or whole groups) so their bounds line up: horizontal left/center/right and/or vertical top/middle/bottom, relative to the selection's bounds, the canvas (the viewBox) or a key element that stays put. Elements are moved by their own transform attribute, so ids, groups and styles stay as they are; parent transforms are honoured. Returns a preview as `$image`. Example: {"source": "assets/art/ui.svg", "elements": ["a", "b", "c"], "vertical": "middle", "to": "key", "key": "a"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to move: SVG ids or selectors. A group moves as one piece (it is measured as the union of its shapes). Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `bounds` | string ["visual","geometry"] | no | What is measured: "visual" (default) includes half the stroke width, "geometry" only the outline of the shapes. |
| `horizontal` | string ["left","center","right"] | no | Align the left edges, the centres or the right edges. |
| `vertical` | string ["top","middle","bottom"] | no | Align the top edges, the middles or the bottom edges. |
| `to` | string ["selection","canvas","key"] | no | What to align to: the bounds of the selection (default with two or more elements), the canvas (default with one element) or the `key` element. |
| `key` | string | no | With to "key" (implied when given): the element the others align to; it does not move. |

## `vector.boolean` (modifies state)

Not released yet (on main after 0.14.1).

Union, subtract, intersect or exclude SVG shapes into one path.

Combines the picked shapes with a path boolean (Clipper2, integer-exact) and writes the result as ONE <path> whose curves are cubic Beziers again (the polygon the operation computes is refitted). The first shape keeps its id, style, transform and place in the drawing and takes the new outline; the others are removed (keepInputs: true keeps them). `union` merges all; `subtract` removes the later shapes from the first; `intersect` keeps what all cover; `exclude` keeps what an odd number of them cover. Transforms of the shapes and their groups are honoured: each shape is measured in the drawing space and the result is written back in the first shape's own space. fill-rule is read per shape. Returns a rasterized preview as `$image`. Example: {"source": "assets/art/badge.svg", "op": "subtract", "elements": ["disc", "hole"]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `op` | string ["union","subtract","intersect","exclude"] | yes | The path operation. |
| `keepInputs` | boolean | no | Keep the other shapes instead of removing them (the result still goes into the first). Default false. |

## `vector.distribute` (modifies state)

Not released yet (on main after 0.14.1).

Space SVG elements evenly along an axis.

Moves the picked elements along `axis` so the gaps between them (by: "gaps", default) or their centres (by: "centers") are equal; the first and the last stay put. With `spacing` the gap is fixed instead and the first element stays. Elements are ordered by position, and moved by their own transform attribute. Returns a preview as `$image`. Example: {"source": "assets/art/row.svg", "elements": ["i1", "i2", "i3", "i4"], "axis": "horizontal"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The elements to move: SVG ids or selectors. A group moves as one piece (it is measured as the union of its shapes). Selectors: #id, .class, tag, [attr=value], g > path, :nth-child(2), lists with commas. |
| `bounds` | string ["visual","geometry"] | no | What is measured: "visual" (default) includes half the stroke width, "geometry" only the outline of the shapes. |
| `axis` | string ["horizontal","vertical"] | yes | The direction to spread along. |
| `by` | string ["gaps","centers"] | no | Equal gaps between the elements' edges (default) or equal distance between their centres. |
| `spacing` | number | no | A fixed gap between neighbouring elements, in drawing units (negative overlaps). The first element stays; the rest follow. |

## `vector.info`

Not released yet (on main after 0.14.1).

List the shapes and groups of an SVG with ids, bounds and node counts.

Reads an SVG and lists its drawable elements: id, tag, bounds in the drawing space (viewBox units), node count, fill, stroke and transform, plus the canvas. Use it to find the ids the other vector.* commands take. Changes nothing. Example: {"source": "assets/art/badge.svg"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |

## `vector.offset` (modifies state)

Not released yet (on main after 0.14.1).

Grow or shrink SVG shapes by a distance (offset path, inset).

Offsets the outline of each picked shape by `distance` drawing units (positive grows, negative insets) with round, miter, bevel or square corners, and writes it back as a <path> (curves refitted as Beziers). Each shape keeps its id, style and transform; copy: true leaves the original and adds the offset shape after it (id <id>-offset). Holes grow the opposite way, as in any offset. Distances are in the drawing space (viewBox units), whatever the shape's transform. Returns a preview as `$image`. Example: {"source": "assets/art/badge.svg", "elements": ["disc"], "distance": -3, "join": "round", "copy": true}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | yes | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Selectors: #id, .class, tag, [attr=value], g > path, path:first-child, :nth-child(2), lists with commas. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `distance` | number | yes | How far to move the outline, in drawing units. Positive grows the shape, negative shrinks it. Not 0. |
| `join` | string ["round","miter","bevel","square"] | no | The corner shape of a grown outline: round (default), miter (sharp, up to miterLimit), bevel (cut) or square. |
| `miterLimit` | number | no | With join "miter": the longest miter, as a multiple of the distance, before the corner is squared off. Default 4. |
| `copy` | boolean | no | Add the offset shape after the original instead of replacing it. Default false. |

## `vector.repeat` (modifies state)

Not released yet (on main after 0.14.1).

Repeat an SVG element in a grid or around a circle.

Adds copies of one element (a shape or a group): mode "grid" lays out `columns` x `rows` with `spacing` between their bounds; mode "radial" puts `count` copies (the original included) around `center` (or `radius` away) over `sweep` degrees, turned to follow the circle unless orient is false. `rotation` turns each copy a little more than the last, about its own centre. Copies are placed with a transform attribute and get ids <id>-2, <id>-3... (ids inside a copied group get the same suffix); they follow the original in the drawing. Angles are in degrees, clockwise on screen, 0 pointing right. Returns a preview as `$image`. Example: {"source": "assets/art/flower.svg", "element": "petal", "mode": "radial", "count": 8, "center": [50, 50]}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
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

## `vector.simplify` (modifies state)

Not released yet (on main after 0.14.1).

Reduce the nodes of SVG paths within a tolerance.

Rewrites each picked shape (default: every shape) with fewer nodes: a path with curves is refitted from its outline as few cubic Beziers as `tolerance` allows, a path of straight lines loses the vertices within `tolerance` of the line between their neighbours. Corners stay corners. A shape that cannot lose nodes is left as it is (listed in `unchanged`), so a rect or circle is not turned into a path for nothing. Returns a preview as `$image`. Example: {"source": "assets/art/tree.svg", "tolerance": 0.4}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |

## `vector.smooth` (modifies state)

Not released yet (on main after 0.14.1).

Round the corners of SVG paths into smooth Bezier curves.

Gives every node that is not a sharp corner smooth handles, so a polygon or a rough hand-drawn path becomes a flowing curve through the same nodes. `smoothness` 0 keeps the segments straight, 1 is the usual round curve. Nodes that turn more than `cornerAngle` stay sharp. Applies to the picked shapes (default: every shape). Returns a preview as `$image`. Example: {"source": "assets/art/blob.svg", "elements": ["blob"], "smoothness": 0.8}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `tolerance` | number | no | The largest distance, in drawing units (viewBox units), between the result and the exact outline. Default: 1/4000 of the drawing's longer side (1/500 for vector.simplify). |
| `curves` | boolean | no | Return curves as cubic Beziers fitted to the result (the default). false keeps the polygon the operation computed. Default true. |
| `cornerAngle` | number | no | Degrees of direction change (1 to 89) above which a vertex stays a sharp corner instead of being smoothed into a curve. Default 28. |
| `smoothness` | number | no | 0 to 1: how round the curves are. Default 1. |

## `vector.stroke_to_path` (modifies state)

Not released yet (on main after 0.14.1).

Turn the stroke of SVG shapes into a filled outline path.

Converts the stroke of each picked shape (its stroke-width, linecap, linejoin, miterlimit, dasharray and dashoffset, read with inheritance, or the overrides given here) into a filled <path> outline, with SVG's own cap, join and dash rules. A shape with no fill becomes the outline (fill = its stroke colour, stroke none). A filled shape keeps its fill and id, and the outline is added after it with the id <id>-stroke. Stroke widths are in the shape's own space, so a scaled shape keeps its look. Returns a preview as `$image`. Example: {"source": "assets/art/logo.svg", "elements": ["swoosh"], "cap": "round"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
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

Not released yet (on main after 0.14.1).

Apply the project's style guide to an SVG: outline and palette.

Applies assets.json `style` to the SVG: `outline` puts the guide's outline colour and width (pixels of the SVG's declared size) as a stroke on every filled shape; `palette` snaps every fill, stroke and gradient stop colour to the nearest colour of the guide's palette. With neither argument it applies both, whichever the guide defines; one of them asked for alone applies only that one (outline: true = just the outline), and one switched off alone applies the other (outline: false = just the palette). Pass {"outline": {"width": 2, "color": "#101018"}} or {"palette": ["#101018", "#e8e0d0"]} to use values other than the guide's. Applies to the picked elements (default: the whole drawing). Returns a preview as `$image`. Example: {"source": "assets/art/crest.svg"}. Docs: docs.read VECTOR.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | no | A project-relative .svg file to edit (e.g. "assets/art/crest.svg"). It is rewritten in place, or to `out`. Give exactly one of `source`, `svg` and `document`. |
| `svg` | string | no | The SVG as text instead of a file. Nothing is written (unless `out`): the edited SVG comes back in the result's `svg`. |
| `document` | string | no | A project-relative *.image.json document whose svg layer to edit (see `layer`). Only the layer's SVG changes; the document is saved and baked like image.layer.set does. |
| `layer` | any | no | With `document`: the svg layer to edit, by name or index path ("1", "1/0"). Optional when the document has exactly one svg layer. An svg layer with `source` rewrites that .svg file. |
| `out` | string | no | Write the result to this project-relative .svg file instead of changing `source` (or, with `svg`, also write it). An existing file needs overwrite: true. |
| `overwrite` | boolean | no | Replace `out` when it already exists. Default false. |
| `dryRun` | boolean | no | Compute and preview the result without writing anything. Default false. |
| `previewSize` | integer | no | The longer side of the preview picture returned as `$image`, in pixels. Default 512. |
| `bake` | boolean | no | With `document`: also bake the document's PNG (like image.layer.set). Default true. |
| `elements` | any | no | The shapes to work on: an SVG id, a selector, or a list of them. A group stands for the shapes in it. Default: every shape in the drawing. |
| `outline` | any | no | true: the guide's outline. An object {"width", "color"}: that outline. false: none. Width is in pixels of the SVG's declared size. |
| `palette` | any | no | true: snap to the guide's palette. A list of colours: snap to those. false: leave colours. |

