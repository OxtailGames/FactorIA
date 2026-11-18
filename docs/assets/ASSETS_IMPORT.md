# Assets: bringing files in

[Assets](../ASSETS.md) > Assets: bringing files in

## Import settings

### Textures

```json
{"defaults": {"texture": {"compression": "auto"}},
 "assets": {"assets/ui/play.png": {"import": {"atlas": "ui"}},
            "assets/hero.png": {"import": {"compression": "none"}}}}
```

| Setting | Values | Default | What it does |
|---|---|---|---|
| `compression` | `auto`, `none`, `uastc`, `etc1s` | `auto` | GPU compression `factoria export` applies. `auto` is `uastc` in Android and iOS exports and `none` in desktop exports. |
| `atlas` | a group name, or `""` | `""` | `factoria export` packs every texture of the same group into one image. |

Both are import settings, so they follow the usual order: the texture's own `import`, then `defaults.texture`, then the
built-in value. A `compression` the export does not know is reported as an export warning and treated as `auto`.

**Compression.** The export turns a PNG into a KTX2 file (Basis Universal) with its whole mip chain, and the game
transcodes it at load time to a format the GPU samples directly, so it also stays small in video memory:

- `uastc`: near lossless, 1 byte per pixel in GPU memory (RGBA8 takes 4). Use it for everything, pixel art included.
- `etc1s`: much smaller files and the same GPU memory, with visible loss (banding, smeared edges). For big photographic
  backgrounds only, never for pixel art or UI.
- `none`: the PNG ships as it is.

The format is the first of ASTC 4x4, BC7, ETC2 that the GPU reports as sampleable, else RGBA8. In practice: ASTC on
phones, tablets and Apple Silicon Macs, BC7 on Windows and Linux desktop GPUs, ETC2 where a GLES3 device has nothing else
(every GLES3 device samples it; it keeps less colour detail, since a texel's red, green and blue share one brightness
offset). A texture never fails because of its format: when the GPU takes none of them, or
creating the compressed image fails, the engine transcodes to RGBA8, which is what the PNG would have been.
`FA_TEXTURE_FORMAT=astc|bc7|etc2|rgba8` forces one (for testing; a format the GPU does not sample falls through to the
next, and `rgba8` turns GPU compression off).

What to know:

- **Twin rule.** The export ships `assets/hero.png.ktx2` instead of `assets/hero.png`. Scenes, prefabs and scripts keep
  saying `assets/hero.png`: the engine loads the `.ktx2` next to that name when it exists (also in a project, so do not
  keep `.ktx2` files you did not export in `assets/`). `assets.json`'s `analysis` and `provenance` are not affected.
- **Disk versus video memory.** A KTX2 file holds every mip level at about 1 byte per pixel, so for tiny or flat-colour
  pixel art it can be larger on disk than the PNG (the 2d-platformer tileset: 1 KB as PNG, 6 KB as KTX2) while using 4 times
  less video memory (22 KB as RGBA8, 5.5 KB as BC7). Compression pays off for big textures; set `"compression": "none"`
  on small ones if you ship over a slow link.
- **Multiples of 4.** D3D11 and WebGPU only create a compressed texture whose width and height are multiples of 4, so a
  texture of any other size stays a PNG; the export says so in one warning that lists them. Atlas images are always sized
  to multiples of 4. Textures smaller than 4 pixels on a side stay PNG without a word.
- **Failures keep the game working.** A texture the encoder cannot read or write stays a PNG and the export warns
  (in the export's warnings); nothing aborts. The icon of the platform is never converted.
- **Cache.** Encoding is slow (seconds for a large texture), so every result is cached in
  `<project>/.factoria/export-cache/<platform>/` under a hash of the pixels and the codec settings; a second export of an
  unchanged game encodes nothing. Files no export used any more are deleted from it. The folder is not shipped; it is safe
  to delete.
- Editor and `factoria run` always load your PNGs: only exports compress.

**Atlases.** Textures with the same `atlas` group are packed into `assets/atlases/<group>.png` (a second page,
`<group>-2.png`, when one does not fit). Fewer, bigger textures mean fewer draw calls: sprites of one group are drawn in
one batch. The original PNGs are dropped from the export and the shipped `assets.json` gets, for each one,
`"packed": {"atlas": "assets/atlases/ui.png", "rect": [x, y, w, h]}`; the engine draws the sprite from that rectangle, so
scenes and scripts still name `assets/ui/play.png` and the sprite keeps the size of the original picture.

- Packed textures keep 2 pixels of padding that repeats their edge pixels, so bilinear filtering and mipmaps do not bleed
  neighbours into each other. Pages are at most 2048x2048 pixels in Android and iOS exports (what every GLES3 device
  samples) and 4096x4096 on desktop; a texture too large for a page ships on its own, with a warning.
- A group name needs letters or digits (it names the file); two groups that would write the same file are reported.
- The atlas image is compressed like any texture, by its own entry in `assets.json` (`assets/atlases/ui.png`), not by
  the entries of the textures inside it: with the `auto` default it is UASTC on mobile and a PNG on desktop. Give the
  page an entry in `assets.json` to change that.
- Only textures drawn by `Sprite` (with or without `region`), `SpriteAnimator`, `ParticleEmitter` and UI widgets can be
  packed. A `Tilemap` tileset or a `MeshRenderer` texture in a group would draw the whole atlas, so `factoria validate`
  warns.

**An atlas while developing.** The export's groups are enough when your Sprites can keep naming the source PNGs: you
write `texture: "assets/ui/play.png"`, the editor and `factoria run` draw that file, and only the export packs. Pack an
atlas yourself when the game needs to pick frames by name from one texture while you work: a map of thousands of tiles and
buildings drawn from one texture (`factoria run` batches by texture, so one atlas is a few draw calls and many PNGs
are thousands), frames that a script chooses by name or by a table (a road mask, a ship's heading), or pictures that
are an atlas to begin with. `assets.pack_atlas` does it:

```
factoria call assets.pack_atlas '{"folder":"assets/src/frames","out":"assets/atlas.png","table":"data/atlas.json"}'
```

- Every image under `folder` (subfolders too) is a frame named by its path without the extension (`ship/0.png` is
  `ship/0`). They are packed tallest first into the smallest square page up to `maxSize` (default 2048; 4096 on
  desktop), each with `padding` pixels (default 2) of its own edge repeated around it, like the export's groups.
- The table is JSON: `{"texture": "assets/atlas.png", "size": [w, h], "frames": {"ship/0": {"rect": [x, y, w, h],
  "pivot": [px, py]}}}`. `rect` is in texture pixels from the top-left, exactly `Sprite.region`; `pivot` is
  `Sprite.pivot`. A script imports the table (`import atlas from "../data/atlas.json"`) and sets
  `Sprite: {texture: atlas.texture, region: atlas.frames[name].rect, pivot: atlas.frames[name].pivot}`.
- Pivots come from `<folder>/pivots.json` (`{"ship/0": [0.5, 0.2]}`); a frame without one is `[0.5, 0.5]`. Keys of an
  existing table that are not `texture`, `size` or `frames` stay, so your own data (a road mask table) can live in it.
- Packing again keeps every frame whose size did not change where it was: a new picture adds one line to the table and
  scenes that copied a rect keep drawing the same frame. The page grows (existing frames never move) when the new ones do
  not fit; a frame whose picture has another size, or that no longer fits, is placed again and reported in `moved`. Nothing is
  written when the result would be the same bytes.
- Pack again whenever the folder changes, and commit the PNG and the table. Sprites that name the atlas ship it as it
  is; do not also put those pictures in an `atlas` group.

### Audio

Sounds are `.wav`, `.ogg`, `.mp3` and `.qoa` files. These settings go under `defaults.audio` (every sound) or under an
entry's `import` (one sound); the entry wins:

| Setting | Values | Default | What it does |
|---|---|---|---|
| `stream` | `auto`, `always`, `never` | `auto` | Decode the sound a little at a time while it plays instead of whole when it loads. |
| `normalize` | `true`, `false` | `false` | Play the sound at `targetLufs` so tracks and effects from different sources are equally loud. |
| `targetLufs` | -60 to 0 | `-16` | The loudness `normalize` aims at (integrated LUFS). Music and voice: -16. Effects: -18 to -12. |
| `loopStart`, `loopEnd` | seconds, 0 or more; `loopEnd` after `loopStart` | none | Where a looping sound wraps: from `loopEnd` playback jumps back to `loopStart`, so what comes before `loopStart` plays once. Without them the whole sound loops. A sound with loop points is decoded whole, never streamed. The `loop` step of an audio document writes them (docs/sound/SOUND_DOCUMENTS.md, "Audio documents"). |
| `convert` | `none`, `qoa` | `none` | Export setting: ship WAV files as QOA (about 5 times smaller, cheap to decode). |

```json
{
  "defaults": {"audio": {"normalize": true, "targetLufs": -16}},
  "assets": {
    "assets/music/theme.ogg": {"import": {"stream": "always"}},
    "assets/sfx/explosion.wav": {"import": {"convert": "qoa", "targetLufs": -12}}
  }
}
```

**Streaming.** A sound that is decoded whole costs 44.1 kHz stereo floats: a 3-minute track holds about 60 MB. A
streamed sound keeps only its encoded file, and every voice playing it decodes a few thousand frames at a time, so the
same track holds about 40 KB of decoded audio however long it is. `auto` streams the sounds longer than 10 seconds;
`always` and `never` decide by hand (`never` for a sound that must start with no decoding at all, `always` for a long
ambience). Looping restarts the decoder, pitch and fades work as for any other sound, and a streamed sound plays exactly
like the same sound decoded whole. It applies to `audio.play`, `audio.music`, `SceneSettings.music` and `AudioSource`.
`game.state` reports both under `audio`: `decodedBytes` (PCM held by loaded sounds, the buffers of the voices that stream and
the decoded music; `musicBytes` is the music alone, docs/MUSIC.md) and `streamedClips` (the loaded sounds that stream), so a
test can check that a long track really streams.

**Loudness.** FactorIA measures integrated loudness the way broadcasters do (ITU-R BS.1770-4 / EBU R128: K-weighted, in
400 ms blocks, gated at -70 LUFS and 10 LU below the average) and the sample peak in dBFS. A mono sound counts on both
sides, as it plays. With `normalize` on, the sound plays with the gain `targetLufs - measured loudness`, at most 24 dB
either way and never so high that its sample peak passes -1 dBFS (there is no limiter: a very quiet or very spiky sound
simply ends up quieter than the target). The gain applies on top of `volume` for `audio.play`, `audio.music`,
`SceneSettings.music` and `AudioSource`.

**The analysis cache.** The measurement lives in the sound's entry under `analysis` (`loudnessLufs`, `peakDb`,
`seconds`, plus `bytes` and `sha256` of the file it describes; do not edit it by hand). A record counts only while
`bytes` and `sha256` still describe the file, so editing a sound never leaves an old gain behind. Without a fresh record
the desktop engine measures the sound once when it loads it, keeps the value in memory and logs one line
(`measured 'assets/sfx/jump.wav': -21.3 LUFS ...`); that decodes the whole file, so for long tracks run the command
below once. Android and iOS never measure: a sound without a fresh record plays unchanged and a warning says so.

`assets.analyze_audio {"path": "assets/music/theme.ogg"}` measures one sound, or every sound of the project without
`path` (everything under `assets/` and every sound a scene or prefab names), stores the record with
`assets.json` and returns, for each file, `loudnessLufs`, `peakDb`, `seconds`, whether it `streams`, whether it
`normalize`s with the `gainDb` that gives, and `cached` when the record was still fresh. `factoria export` stores the
records of every shipped sound with `normalize` on, so an exported game never measures.

**Conversion to QOA.** With `convert: "qoa"` the export turns a WAV into a QOA file (a lossy format of 3.2 bits per
sample: about 5 times smaller than 16-bit WAV, and cheaper to decode than Ogg or MP3). Only WAV
files are converted; Ogg and MP3 are lossy already and ship as they are (a warning appears when an entry asks for it).
The converted file ships as the **twin** `<path>.qoa`, next to where the original would be: `assets/sfx/boom.wav` becomes
`assets/sfx/boom.wav.qoa`. Scenes and scripts keep naming `assets/sfx/boom.wav`: when that file is missing the engine
reads its twin, with the import settings of the original. The conversion is cached in
`.factoria/export-cache/<platform>/audio/` under the SHA-256 of the WAV, so only changed sounds are encoded again.
A WAV that QOA cannot hold (more than 8 channels) ships unchanged, with a warning in the export report. A `.qoa` file
also plays directly, and streams like any other long sound.

## Importing files

`assets.import` brings a file made elsewhere into the project and records where it came from. It reads files on this
machine (an absolute path, or a path relative to the project); to use something from the web, download it first and pass
the page it came from as `sourceUrl` so the credits keep it. The websites the AI looks at when it needs such a file
(and whether it may look anywhere else) are the user's choice: **AI > AI Settings...** in the editor, `assetSources` in `ai.json`
([AI_PROVIDERS.md](../AI_PROVIDERS.md), "Asset sources").

```
assets.import {"source":"C:/art/hero.aseprite","license":"CC-BY 4.0","author":"Ana Lopez"}
assets.import {"source":"C:/art/crate.obj","path":"assets/models/crate/","license":"CC0"}
assets.import {"source":"C:/music/tune.mid","license":"CC0"}
```

A `.mid` or `.midi` becomes a song document (`assets/music/tune.song.json`), not a copy of the file: `music.import_midi` has the same import with its options
(`quantize`, `soundfont`) and docs/MUSIC.md, "MIDI", has the rules.

| Argument | Meaning |
|---|---|
| `source` | The file. Required. |
| `path` | Where it lands: a path under `assets/` that ends in the extension the result has (a `.aseprite` becomes `.png`), or a folder ending in `/`. Default: `assets/<name>.<ext>`, with sounds in `assets/audio/`, fonts in `assets/fonts/` and models in `assets/models/`. Spaces and punctuation in the name become `_`. |
| `license`, `author` | Recorded in the provenance. Pass them for anything you did not make: the credits and the store disclosures read `assets.json`. |
| `sourceUrl` | The page the file came from. It replaces the local path in `provenance.source`. |
| `ai` | `true` when an AI made it. Left out when you do not know. |
| `columns` | Aseprite only: cells per row of the sheet. |
| `overwrite` | Replace files that already exist. Without it an existing file is an error that says so. |

The result lists the files written, the provenance recorded, importer details, warnings (what could not be carried over)
and next steps with the component settings to use. Each written file gets an `assets.json` entry with
`provenance: {origin: "imported", source, license, author, ai, date}`.

| Source | What lands in the project |
|---|---|
| `.png` `.jpg` `.tga` `.bmp` | Copied as they are (decoded once to check the engine can read it; the size is in `details`). |
| `.wav` `.ogg` `.mp3` | Copied into `assets/audio/`. |
| `.ttf` `.otf` | Copied into `assets/fonts/`. A game that shows Chinese, Japanese, Korean or Arabic ships such a font (see [TEXT.md](../TEXT.md)). |
| `.glb` `.gltf` | Copied into `assets/models/`, with the `.bin` buffers and images its `uri`s point at (the `.glb` carries its own data; only external files count), keeping their relative paths next to the model (`Textures/colormap.png` lands in `assets/models/Textures/`). Each copied file gets a provenance record. A missing buffer is an error, a missing image a warning. A file with the same name that is already there and identical is shared; a DIFFERENT image is kept, and the result warns (kits often ship different `colormap.png` files under one name), while a DIFFERENT buffer is an `exists` error (a model cannot load another one's geometry): import each kit into its own folder with `path` (`"assets/models/town/"`) or pass `overwrite`. `factoria validate` reports a model whose texture or buffer is missing. |
| `.aseprite` `.ase` | An image document (`<name>.image.json`) with the file's layers, cels, frames and tags, a cel PNG per layer and frame in `<name>.layers/`, and the sprite sheet baked from it with its `sheet` clips; `flat: true` makes only the PNG sheet (see Aseprite below). |
| `.psd` | A layered image document (`<name>.image.json`) with one PNG per layer in `<name>.layers/`, and the PNG baked from it (see PSD below). A file whose layers cannot be read imports its merged image as a PNG. |
| `.obj` (+ `.mtl`, textures) | A `.gltf` with its data embedded, plus the textures next to it. |
| `.fbx` | A `.glb`, converted by FBX2glTF or Blender (see below). |
| `.mpg` `.mpeg` | Copied into `assets/video/` after the engine opened it (it must be MPEG-1 video; the size, length and frame rate are in `details`). |
| `.cube` | Copied into `assets/luts/` after it was parsed (a 3D colour lookup table, 2 to 65 entries per side; a 1D table, a domain other than 0 to 1 or a wrong row count is an error with the line number; the size and title are in `details`). Set `PostProcess.colorGradingLut` to it (docs/RENDERING.md, "Colour grading with a LUT"). |
| `.mp4` `.m4v` `.mov` `.webm` `.mkv` `.avi` | An `.mpg` in `assets/video/`, converted by ffmpeg (see "Video" below). |

Not supported (the error says what to do instead): `.blend` (export glTF from Blender), `.webp` `.gif` `.psb`
(convert to PNG), `.svg` (`assets.rasterize_svg` makes the PNG), `.flac` `.m4a` `.aac` (convert to OGG or WAV), and SDF/MSDF font atlases.

Models do not have to be files: a script can build a mesh at run time with `mesh.create` and keep it as a `.glb` with
`mesh.save` (a plain `assets/models/` file after that; docs/SCRIPTING.md, "Procedural meshes"). `factoria validate` rejects a
`mesh:N` id written in a scene or prefab, because the mesh exists only in the running game.

### Aseprite

The file becomes an **image document** ([IMAGES.md](../IMAGES.md), "Frames and tags"): `<name>.image.json` with the layers
(visibility, opacity, blend mode: normal, multiply, screen, overlay, darken, lighten, color dodge, color burn, hard light,
soft light, difference, exclusion, hue, saturation, color, luminosity, add and subtract), the cels of every frame (a linked cel is
a `link`, a layer that does not change needs no cel), the frame durations and the tags with their direction and repeat count.
Each cel's picture is `<name>.layers/<layer>-<frame>.png`; groups are flattened into their layers. An indexed file keeps its
palette (an indexed document) when it has at most 81 distinct opaque colours; otherwise its layers are pixels layers and the
result says why. The sprite sheet is then BAKED from the document like any other image document: the frames in a grid, left to
right and top to bottom, `ceil(sqrt(cells))` columns wide by default (`columns` changes it), and the `sheet` entry in `assets.json`
records `columns, rows, frameWidth, frameHeight, frames` and one clip per tag (`name, firstFrame, lastFrame, fps, loop`).
A clip's `fps` is `1000 * frames / milliseconds` (the same for every frame when their durations match). A tag that plays in
reverse or ping-pong, repeats, or has frames of different durations gets extra cells at the end of the sheet that spell its
order out, so the clip plays as the file says with no `SpriteAnimator.mode`; `repeat: N` makes the clip non-looping. A file with
one frame and no tags is a document that bakes a plain PNG.

You then edit the animation with `image.pixel`, `image.draw`, `image.edit` and `image.paint` (`frame`) and `image.frame.*` /
`image.tag.*`; the PNG and its clips follow (and a change of the document makes the PNG stale, like any baked picture).
`flat: true` keeps the earlier import: one PNG sheet with the frames in order (no extra cells, no document); there a reverse or
ping-pong tag is a forward clip (set `SpriteAnimator.mode` to play it that way), a repeat count is ignored, and blend modes are
drawn as normal.

To play a clip, use the next steps of the result:

```json
{"Sprite": {"texture": "assets/hero.png"},
 "SpriteAnimator": {"columns": 4, "rows": 2, "firstFrame": 2, "lastFrame": 5, "fps": 12, "loop": true}}
```

Leave the Sprite's `region` and `size` empty: SpriteAnimator sets the region, and the frame size is the sprite size.

What is not carried over, with a warning each time: layers with the divide blend mode (drawn as normal), blend modes of a group, tilemap
layers, reference layers and layers with no pixels in any frame (left out), a tag that plays ping-pong in reverse (a document tag
plays ping-pong forward), and the z-index of cels. Slices and user data are ignored. A damaged file is an error that names
what is wrong ("frame 3 is cut short").
With `flat: true` the sheet has no extra cells: tags that play in reverse or ping-pong are forward clips, a repeat count is
ignored and blend modes other than normal are drawn as normal; each says so.

### PSD

A PSD (8 or 16 bit, RGB or grayscale) imports as a **layered image document** ([IMAGES.md](../IMAGES.md)): `assets/<name>.image.json`
with every layer as a `pixels` layer, one PNG per layer in `assets/<name>.layers/`, and `assets/<name>.png` baked from the document
(the path `assets.import` reports is that PNG, as before). Kept: layer names (the unicode name), position, opacity, visibility,
clipping, groups (as `group` layers) and these blend modes: normal, multiply, screen, overlay, darken, lighten, color dodge,
color burn, hard light, soft light, difference, exclusion, linear dodge (add), subtract, hue, saturation, color, luminosity. A layer
mask is baked into the layer's alpha (a disabled mask is ignored). Warned about and approximated: other blend modes (linear burn,
vivid and linear light...) and pass-through groups (image groups are isolated). Skipped with a warning: layers with no pixels
(adjustment layers, empty layers). Layer styles, vector masks, smart-object filters and the fill opacity are not read.

Edit the result with `image.layer.set`, `image.edit` and `image.paint`. If the layers cannot be read (a cut-short file, CMYK,
indexed or 32 bit colour) the merged image saved in the file becomes the PNG, with a warning that says why the layers were flattened
(for a damaged one: re-save it; for the mode: Image > Mode > RGB Color, 8 Bits/Channel). If that cannot be read either the error says
how to save it again (Maximize PSD Compatibility) or to export a PNG. Importing again needs `overwrite`, which replaces the document,
the layer PNGs and the PNG.

### OBJ

Vertices, texture coordinates, normals and faces are imported (polygons are triangulated as a fan, which is right for
convex polygons; negative indices work). Objects and groups (`o`, `g`) become separate meshes, and a change of material
(`usemtl`) a separate primitive of the mesh. A face without normals is flat shaded; a face without texture coordinates
gets none. Materials come from the `.mtl` next to the OBJ: `Kd` (color), `d` / `Tr` (opacity) and `map_Kd` (the base
color texture, found next to the `.mtl` or the OBJ and copied next to the glTF; formats other than PNG and JPEG are
converted to PNG). The result has `details` with the vertex and triangle counts and the bounds (`boundsMin`, `boundsMax`,
`size`) in the OBJ's own units; OBJ has no unit and the engine reads 1 as 1 meter, so scale the entity if the model is not
that size. Points and lines are skipped, and a missing `.mtl` or texture leaves the material with its color only: each
is a warning, not an error. Smoothing groups and the other material maps (bump, specular) are ignored.

### FBX

FBX is a closed format, so FactorIA converts it with a program that reads it. Neither ships with the engine:

- **FBX2glTF** (<https://github.com/godotengine/FBX2glTF/releases>): put it in `PATH` or set `FACTORIA_FBX2GLTF` to its
  path. Tried first.
- **Blender** (<https://www.blender.org/download/>): found in `PATH` or in its standard install folder; it runs in the
  background.

When neither is found the error says so and links both. The converted `.glb` has meshes and materials; skins and
animations are not used by the engine yet. Check scale and orientation with `game.screenshot`.

### Video

The engine plays one video format on every platform: MPEG-1 video with MP2 sound in an `.mpg` file (decoded on the CPU by
pl_mpeg; the `Video` component, `docs.components`). `assets.import` of an `.mp4`, `.m4v`, `.mov`, `.webm`,
`.mkv` or `.avi` converts it with **ffmpeg**, which does not ship with FactorIA: `factoria setup ffmpeg` installs one, and
the importer also finds `FACTORIA_FFMPEG`, the `publish.ffmpeg` entry of `export.json`, or an `ffmpeg` in `PATH`. Without
one the error says so and names the command.

The conversion keeps the first video track and the first audio track (if any), scales a picture wider than 1280 pixels
down to 1280 (the decoder runs on the CPU), and encodes at a fixed quality (`-q:v 4`, a keyframe every 30 frames); a frame rate MPEG-1 does not allow (such as 15) is retried at 30. The result lands in `assets/video/<name>.mpg`
(or the `path` you give) with a provenance record like any import. `details` holds `width`, `height`, `fps`, `duration`,
`hasAudio` and `converter`; the warnings say when the file has no sound (it plays silently) or is over 20 MB (it ships in
the game: shorten it or lower its size). An `.mpg` you made yourself is only checked and copied, so
`ffmpeg -i in.mp4 -c:v mpeg1video -c:a mp2 -f mpeg out.mpg` also works by hand.

```json
{"Video": {"path": "assets/video/logo.mpg", "size": [1280, 720], "anchor": [0.5, 0.5], "pivot": [0.5, 0.5], "fit": "contain"}}
```

A `Video` plays by itself (`autoplay`), follows the game clock and sends the game event `video.ended` when a video that
does not loop reaches its end; a studio intro that any button skips is in [MENUS.md](../MENUS.md).

### Effects drawn by the engine, baked: assets.bake_sheet

A glow made of three Shape2D with gradients, a burst of particles, a badge that pulses with a tween, an explosion a script
starts: drawn live they cost draw calls and CPU on every frame, and on a phone that adds up. `assets.bake_sheet` plays one
entity once, offline, and saves it as a sprite sheet; the game then draws ONE `Sprite` with a `SpriteAnimator`. It is
also the way to make animated art with the engine's own Shape2D (gradients, strokes, additive blending) instead of SVG.

```
assets.bake_sheet {"path":"assets/fx/burst.png","prefab":"prefabs/burst.prefab.json","frames":16,"fps":24,"warmup":0.5,"pivot":[0.5,0.5]}
assets.bake_sheet {"path":"assets/fx/boss.png","scene":"scenes/boss.scene.json","entity":"boss","fps":12,
  "clips":[{"name":"idle","frames":8},{"name":"die","call":"die","frames":24,"loop":false}]}
```

- **What is baked.** A prefab (`prefab`), or an entity of a scene with its children (`scene` + `entity`, the entity's id),
  alone in a private world, placed at the origin of the world whatever the scene says. Shape2D, Sprite, SpriteAnimator,
  Tint, tweens, ParticleEmitter and the entity's scripts run as in the game; nothing else is in the world (no lights: a `lit` sprite
  is drawn as in a world without lights). It needs a GPU: it draws offscreen with a transparent clear (Metal, Direct3D 11,
  OpenGL; a headless Linux needs Mesa's EGL). Without one the error is `no_gpu`.
- **Time.** The world is stepped at the project's fixed step with the world RNG seeded from `seed` (default 1), and a frame
  is captured every 1/`fps` seconds of simulated time (`fps` cannot exceed the fixed rate, 60 by default). Frame 0 is
  drawn after one step, so `onStart` has run, and after `warmup` seconds. The same prefab, seed and settings bake the
  same pixels on the same GPU; two different GPUs can differ by an edge pixel.
- **Clips.** `clips` is a list of `{name, call | event, args | data, frames, fps, loop, warmup}`. Each clip starts in a
  fresh world: `call` runs that method of the entity's behaviour (`this.explode(...args)`) after the warm-up, `event` sends
  a game event the scripts hear with `world.on`, `clip` plays a clip of the entity's Animator (see "Bake by clip name" below),
  and a clip with none of them just plays. Clips follow each other in the sheet and
  become the `clips` of its `sheet` entry (`firstFrame`, `lastFrame`, `fps`, `loop`). A method that does not exist is an
  error that names the prefab, suggests the nearest method and lists the behaviour's methods.
- **Bake by clip name.** A character built in parts (child Sprites, Bone2D bones, IK2D; docs/ANIMATION.md) is baked from the
  clips of its Animator, with no script: `clips: [{"name":"crawl","clip":"crawl"},{"name":"alert","clip":"alert"}]`. `clip` is a
  key of `Animator.clips` (a `*.anim.json` clip, or a glTF animation when the entity has a `model`). The clip plays from time 0
  with no cross-fade and the state machine is switched off, on the fixed clock, so the same clip gives the same frames every
  time. `frames` is the clip's duration times `fps`, rounded, when you do not give it (a clip that does not loop gets one more, so
  its last pose is shown; a looping clip ends one step short of its start), and `loop` is the clip's
  own when you do not give it; `fps` is the clip's `fps` or the command's. `clip` cannot be combined with `call` or `event`.
  An unknown clip is an error that lists the entity's clips with "did you mean"; an entity with no Animator says what to
  add. The recipe in the provenance keeps the `clips` as given, so `assets.regenerate` bakes the sheet again when a clip,
  a part or the prefab changes. Sky Hopper's crawler is made this way (`assets/crawler_sheet.png`).
- **Framing.** The scale is pixels per world unit (`scale`, default 1). The cell is the box that holds everything drawn in
  ANY frame, plus `margin` pixels (default 2), so a burst that grows is never cut, and the entity's origin is the same
  pixel in every frame: that pixel is the sheet's `pivot` (`[x, y]` from the TOP-LEFT of the frame). Give `pivot` to choose
  where the origin lands (a character's feet: `[0.5, 1]`, with room below the feet if the animation goes there). Give
  `frameWidth` and `frameHeight` for a fixed cell: without `scale` the animation is scaled to fit it; with `scale` it must
  fit, or the error says how big the cell has to be. `padding` (default 1) is the transparent border around each cell,
  recorded as `sheet.padding`. The bake draws on a canvas of up to 4096 pixels centred on the origin: an animation that reaches beyond it is cut, and a
  warning says so (lower `scale`).
- **Colour.** The colours are straight alpha (not premultiplied) and the edge pixels take the colour of the shape behind
  them, so a sprite scaled with filtering has no dark halo. An additive glow keeps its light: where it adds colour but no
  alpha, the brightest channel becomes the alpha. `background` puts a colour behind the frames (a sheet with a background is
  opaque); leave it out for a transparent sheet.
- **The result** is the sheet as an image, the layout (`frameWidth`, `frameHeight`, `columns`, `scale`, `pivot`), `warnings`
  (frames that are all identical: nothing moves; empty frames; a canvas that is too small) and `nextSteps`. `assets.json`
  gets the `sheet` entry and a provenance of origin `generated` with the prefab or scene as `source`; `ai` is true when that
  file or a texture it draws is recorded as AI-made (override with `ai`, and set `author` and `license`). The provenance
  holds the recipe (`provenance.recipe`): the arguments and the SHA-256 of the prefab or scene, its scripts, nested prefabs
  and textures, so `assets.regenerate` makes the sheet again after you edit the prefab and `factoria validate` says
  when it is stale.
- **Use it.** A `Sprite` with the texture and a `SpriteAnimator` with the columns, rows and fps from the result. The sheet's
  `pivot` counts from the top-left, but `Sprite.pivot` counts from the BOTTOM-LEFT (y up): to keep the baked origin where
  the entity was, set `Sprite.pivot` to `[x, 1 - y]`.
- **From the editor or MCP.** A process has one graphics device, so when this one already uses it (the editor, an MCP session
  with graphics) the bake runs in a child `factoria call` process of the same installation; from a terminal it just runs.
  `factoria call assets.bake_sheet` and a batch whose commands are all `perf.*` or `assets.bake_sheet` start no graphics of
  their own.

### Sprite sheets: assets.slice_sheet

SpriteAnimator plays a uniform grid of frames. `assets.slice_sheet` makes an image fit that, in two ways:

- **A grid you know.** `{"path":"assets/walk.png","columns":4,"rows":2,"fps":12}` (or `frameWidth` / `frameHeight`
  instead of columns / rows; `frames` when the last row is partly empty). The grid is checked against the image: a
  width that `columns` does not divide is an error that lists the values that fit, and a warning names frames that are
  completely empty (a sign the grid is wrong). The image is not touched; the layout is recorded as the `sheet` entry
  in `assets.json`.
- **Frames of different sizes separated by transparent gutters**, as AI-generated and downloaded sheets often are:
  `{"path":"assets/walk_raw.png","auto":true,"frames":8,"align":"bottom"}`. Every group of touching pixels is a sprite
  (sprites whose boxes overlap count as one, so a floating spark stays with its character), sprites are ordered by rows
  then columns, and repacked into a uniform grid whose cell is the largest sprite, each one centred (`align: "bottom"`
  stands characters on the same ground line). The new PNG is `out` (default `<name>_sheet.png`; the source is kept and
  its provenance is copied, with a note). `frames` is the number of sprites you expect: a different count is an
  error that lists what was found with their positions. `columns` chooses how many frames go in a row of the new sheet.

`background: "auto"` first makes a solid background transparent, in either mode: the four corners must be the same
opaque color (JPEG noise is tolerated), the background that touches them is cleared, and the same color inside a sprite
stays. The result has the SpriteAnimator fields (`spriteAnimator`) and the Sprite `texture` to use. Aseprite files need
no slicing: `assets.import` reads their frames and tags.

## Checks

`factoria validate` (`project.validate`) reads the asset files, fast, from their headers, and reports warnings (a game
with warnings still runs and exports):

- **Texture size.** A texture over 4096 px on a side: many mobile GPUs cannot sample it. Over 2048 px when
  `factoria.json` `platforms` lists `android` or `ios`: low-end phones struggle. The hint says to scale it or cut it into
  tiles.
- **Alpha.** A texture drawn by a `Sprite` whose four corners are the same opaque color is probably a background that
  should be transparent: the hint gives the `assets.slice_sheet` call that clears it. A texture that is fully transparent
  draws nothing. A flat one-color image is left alone (a placeholder rectangle).
- **Recipes.** A made asset whose recipe inputs changed since it was made (stale), and a recipe whose input no longer exists
  (see "Recipes: make an asset again"); the hint holds the `assets.regenerate` call.
- **Image documents.** A `*.image.json` that does not load is an error with the JSON pointer and the fix; one never baked, or
  whose PNG `assets.json` does not record as its bake, is a warning with the `image.bake` call ([IMAGES.md](../IMAGES.md)).
- **Model documents.** A `*.model.json` that does not load is an error per issue, each with its JSON pointer and the fix;
  one never baked, or whose `.glb` `assets.json` does not record as its bake, is a warning with the `model.bake` call
  ([MODELING.md](../MODELING.md)).
- **Weight.** One shipped file over 20 MB, with a hint by kind (convert audio to OGG, compress a texture). The total of
  the shipped files against the limit of each store the game targets: Google Play's 500 MB for the base module of an app
  (`android`), and for `ios` 200 MB, above which an iPhone asks the player before downloading over cellular data, and 4 GB,
  the App Store's limit for an uncompressed app. The total is before the export's texture compression and audio
  conversion, so a game just over a limit may fit once exported (`factoria export` reports the real size).
- **Loudness.** Every sound under `assets/` and every sound a scene or prefab names: a warning when the sample peak
  reaches 0 dBFS (within 0.1 dB: probably clipped), when the integrated loudness is above -9 LUFS (very loud) or below
  -35 LUFS (very quiet, or nothing audible), and when the sound effects (sounds of 10 seconds or less) differ by more than
  12 LU in how loud they play. The levels are those of the sound as it plays: a sound whose effective import has `"normalize": true` (set in `defaults.audio` or on the sound) is judged with its gain applied (peak and LUFS after the gain), so a project that set it has no loudness warning left. The fix for most of them is `"normalize": true` in `defaults.audio`. `factoria validate`
  reuses the `analysis` records of `assets.json` while they are fresh and measures the other sounds on the spot; it
  never writes `assets.json` (run `assets.analyze_audio` to store the measurements, which makes validating fast).
  A sound that cannot be decoded is reported too.
- **Model files.** An error (not a warning) when a `.gltf` or `.glb` under `assets/` names a texture or a `.bin` buffer by a relative `uri` and the file is not there: the model would draw untextured or fail to load. The uri is resolved against the model's folder and the message names the project path it reaches (or says it climbs out of the project folder); the hint suggests the uri that works when the file exists in the project (too many leading `..`, or the same file name elsewhere under `assets/`). `assets.import` copies those files.
- **Videos.** An error when a `Video` names a file under `assets/` that is not there, or when an `.mpg` the project uses cannot be
  played (not an MPEG file, or a different codec such as H.264 inside): the hint has the ffmpeg command that converts it.
- **Atlas groups.** A texture in an `atlas` group used by a component that cannot draw from an atlas (a `Tilemap`
  tileset, a `MeshRenderer` texture): the exported game would show the whole atlas image there. Remove the texture from
  the group, or use a copy of it.
- **House style.** When `assets.json` `style` sets a rule (see "House style"), a Sprite texture that clearly breaks it (the
  `fail` verdict of `assets.check_art`): `Breaks the style rule '<rule>' ...`, with the numbers and the fix. Files in `style.ignore`
  are skipped; rules that are not set are never checked.

The shipped files are the ones the export includes ([EXPORTING.md](../EXPORTING.md), "What is shipped").

`factoria export` warns, in the warnings of its result, about textures it could not compress (and ships them as PNG),
textures whose size is not a multiple of 4, textures too large for an atlas page and atlas groups it could not write.
None of them stops the export.
