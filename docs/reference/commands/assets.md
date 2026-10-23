[Back to the index](../README.md)

# Commands: assets

## `assets.analyze_audio` (modifies state)

Since 0.1.6.

Measure the loudness of a sound (or of every sound) and keep the result in assets.json.

Measures integrated loudness (LUFS, ITU-R BS.1770-4 / EBU R128) and sample peak (dBFS) of .wav, .ogg, .mp3 and .qoa files, and stores them under the sound's `analysis` in assets.json together with the size and SHA-256 of the file, so editing the sound later makes the record stale instead of wrong. Sounds with import "normalize": true play at `targetLufs` using that record; without one the desktop engine measures the sound when it loads it, and mobile builds cannot, so run this (or export, which stores it) before shipping. A sound whose record is still fresh is not measured again. Without `path` every sound under assets/ and every sound a scene or prefab names is analyzed. Returns {files: [{path, loudnessLufs, peakDb, seconds, streams, normalize, gainDb, cached, stored}], measured, cached, failed}: `streams` says whether the sound is decoded while it plays (import stream), `gainDb` is the gain normalize would apply (only when normalize is on). A sound that cannot be decoded is listed with `error` and `hint` when no path is given. Example: {"path": "assets/music/theme.ogg"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative sound file, e.g. assets/sfx/jump.wav. Omit to analyze every sound of the project. |

## `assets.disclosure`

Since 0.1.6.

Write the AI-generated content disclosure for store forms (Steam) from the provenance records.

Returns Markdown that answers the AI-generated content questions of Steam's content survey and similar forms: what was pre-generated with AI by category (art, sound effects, music, voice, 3D models) with counts, providers and models; that nothing is generated while the game runs; the terms recorded for each provider; and the art, sound and model files that still have no provenance record (fix those with assets.set_provenance first). `factoria export` writes the same text as AI_CONTENT_DISCLOSURE.md. Example: {}

## `assets.draw_capsules` (modifies state)

Since 0.2.0.

Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo.

Cover-crops `keyArt` (an image in the project, e.g. a screenshot taken with game.screenshot {scale}) around `focus` to every image size the `stores` ask for and writes store/capsules/<store>/<name>_<w>x<h>.png (folders are created, files replaced). Stores: steam, epic, gog, microsoft, googleplay, appstore, itch (default: all). The sizes are in one table (docs/EXPORTING.md#store-page-material, as of 2026-10); assets with the same size in one store are one file.
The `logo` is placed by the rule of each asset: capsules and covers get it centred (Microsoft: in the upper part, the bottom third is overlaid; Steam library capsule: low), heroes, page backgrounds and screenshots get none (Steam's library hero must have no text), and the logo-only assets (Steam library logo 1280x720, Epic logo 960x540) are a transparent PNG with just the logo. `logo` is {"image": "assets/logo.png"} (transparent PNG) or {"text": "My Game", font, fill, outline} (title drawn like assets.draw_icon draws text; fill default white, outline default a dark one, false = none). Without a logo the art is cut without one and the logo-only assets are skipped.
`orientation` (landscape, default; or portrait) turns the phone and tablet screenshot sizes of Google Play and the App Store. Capsules are not the store screenshots: take those at the stores' sizes with `--render-scale` (a 1280x720 game at 1.5 gives 1920x1080).
Example: {"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `keyArt` | string | yes | The art to cut the capsules from: a project image path, 1920x1080 or bigger is best (a screenshot taken with --render-scale). |
| `focus` | array | no | The point of the art that must stay in view when it is cropped, as fractions [x, y]. Default [0.5, 0.5]. |
| `logo` | object | no | The logo: give image or text. |
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

## `assets.generate_voice` (modifies state)

Since 0.1.6.

Generate spoken audio from text with the voice asset provider and record where it came from.

Calls the provider that ai.json assigns to "voice" (assets.voice) to speak `text` with `voice` (default: the voice in ai.json) and writes the audio file at `path`. Records provenance in assets.json (the text is the prompt). Example: {"text":"Welcome, traveller.","path":"assets/voice/welcome.mp3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `text` | string | yes | The words to speak. |
| `voice` | string | no | The provider's voice name or id (openai: alloy, verse...; elevenlabs: a voice id). Default: assets.voice.voice in ai.json. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

## `assets.import` (modifies state)

Since 0.1.6.

Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF...) into the project's assets/ folder and record where it came from.

Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance (origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. The importer is chosen by the extension:
- .png .jpg .tga .bmp, .wav .ogg .mp3 .qoa, .ttf .otf: copied as they are (images are checked to decode).
- .gltf and .glb: copied with the .bin buffers and images their uris point at, which must sit next to the model or below it (a missing buffer is an error, a missing image a warning). An identical file already there is shared; a DIFFERENT file with the same name is kept and the result warns (kits ship different Textures/colormap.png files: import each kit into its own folder with `path`, or pass overwrite). project.validate reports a model whose texture is missing.
- .aseprite .ase: becomes ONE PNG sprite sheet (frames in a grid, `columns` per row, default ceil(sqrt(frames))) and the `sheet` entry of assets.json: columns, rows, frameWidth, frameHeight, frames and a clip per tag (firstFrame, lastFrame, fps from the frame durations). Hidden layers are left out, layer and cel opacity apply, RGBA, grayscale and indexed colors work. Blend modes other than normal are drawn as normal, and ping-pong or reverse tags become forward clips; the result says so. The result lists the Sprite and SpriteAnimator settings that play it.
- .psd: the merged image becomes a PNG (layers are flattened).
- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the bounds so you can scale it.
- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither installed the error says where to get them.
Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/ by default) or at `path`, which must be under assets/. An existing file is an error unless overwrite is true. Example: {"source":"C:/art/hero.aseprite","license":"CC0","author":"Ana"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first. |
| `path` | string | no | Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/ or assets/fonts/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX). |
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

## `assets.provenance`

Since 0.1.6.

Show where assets came from: the provenance record of one file, or all of them.

With `path`, the provenance record of that file (null when it has none). Without, every record in assets.json, how many are AI-made, and the art, sound and model files under assets/ that have no record yet. Example: {"path":"assets/hero.png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path under assets/. Omit to list every record. |

## `assets.set_provenance` (modifies state)

Since 0.1.6.

Record where an asset came from (hand-made, imported, or made with AI elsewhere).

Replaces the provenance record of an existing file in assets.json. The generate commands write it for you; use this for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to true for origin generated, false otherwise). Example: {"path":"assets/music/theme.ogg","origin":"imported","ai":false,"license":"CC0","source":"https://example.com/theme","author":"A. Composer"}

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

## `assets.synth_sound` (modifies state)

Not released yet (on main after 0.2.0).

Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.

Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no key. The same preset, seed and seconds always give the same bytes; another `seed` is another take of the same sound (pitch and timing move a little). Peaks at -3 dBFS. Records provenance in assets.json (origin original, ai false, license CC0, the preset and the seed). Presets:
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

