# Assets: generate, import and ship

Art, sounds, music, voices and models get into a FactorIA game three ways, and every one of them is a command an AI can
call (MCP tool, `factoria call`, editor console):

1. **Generate** them with an asset provider (`assets.generate_image`, ...), configured like the LLM providers
   ([AI_PROVIDERS.md](AI_PROVIDERS.md)).
2. **Import** files made elsewhere (`assets.import`): Aseprite, PSD, OBJ, FBX...
3. **Write** them directly (`fs.write`), for files the engine already reads (PNG, JPG, WAV, OGG, MP3, glTF, TTF).

Whatever the way, `assets.json` at the project root records where each asset came from (provenance) and how the engine
and `factoria export` treat it (import settings).

## assets.json

The file is optional; the assets.* commands create and update it. Schema: `schemas/assets.schema.json`
(`factoria validate` checks it and warns about entries whose file no longer exists).

```json
{
  "format": "factoria.assets/1",
  "style": {"prompt": "16-bit pixel art, black outline", "palette": ["#1a1c2c", "#5d275d", "#b13e53", "#ef7d57"]},
  "defaults": {"texture": {"compression": "auto"}, "audio": {"normalize": true, "targetLufs": -16}},
  "assets": {
    "assets/hero.png": {
      "import": {"atlas": "characters"},
      "provenance": {"origin": "generated", "ai": true, "provider": "openai", "model": "gpt-image-1",
                     "prompt": "a knight, side view", "license": "...", "date": "2026-10-16"}
    },
    "assets/music/theme.ogg": {"import": {"stream": "always"}}
  }
}
```

- `assets` is keyed by the project-relative path. An entry has `import` (settings that override `defaults`),
  `provenance`, `sheet` (sprite-sheet layout) and `analysis` (measurements the tools cache; do not edit).
- `defaults` holds import settings per kind (`texture`, `audio`); each setting is listed below with its default.
- `style` is the house style of generated images.
- Exports ship the import settings and leave `provenance` and `style` at home.

## Generating assets

<!-- Filled by the asset-providers work: providers, ai.json "assets" section, commands, fake provider, style. -->

## Provenance and store disclosure

<!-- Filled by the asset-providers work: provenance records, assets.provenance, the AI-content disclosure of exports. -->

## Import settings

### Textures

<!-- Filled by the texture work: compression (KTX2 / Basis Universal), atlases. -->

### Audio

Sounds are `.wav`, `.ogg`, `.mp3` and `.qoa` files. These settings go under `defaults.audio` (every sound) or under an
entry's `import` (one sound); the entry wins:

| Setting | Values | Default | What it does |
|---|---|---|---|
| `stream` | `auto`, `always`, `never` | `auto` | Decode the sound a little at a time while it plays instead of whole when it loads. |
| `normalize` | `true`, `false` | `false` | Play the sound at `targetLufs` so tracks and effects from different sources are equally loud. |
| `targetLufs` | -60 to 0 | `-16` | The loudness `normalize` aims at (integrated LUFS). Music and voice: -16. Effects: -18 to -12. |
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
`game.state` reports both under `audio`: `decodedBytes` (PCM held by loaded sounds plus the buffers of the voices that
stream) and `streamedClips` (the loaded sounds that stream), so a test can check that a long track really streams.

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
the page it came from as `sourceUrl` so the credits keep it.

```
assets.import {"source":"C:/art/hero.aseprite","license":"CC-BY 4.0","author":"Ana Lopez"}
assets.import {"source":"C:/art/crate.obj","path":"assets/models/crate/","license":"CC0"}
```

| Argument | Meaning |
|---|---|
| `source` | The file. Required. |
| `path` | Where it lands: a path under `assets/` that ends in the extension the result has (a `.aseprite` becomes `.png`), or a folder ending in `/`. Default: `assets/<name>.<ext>`, with sounds in `assets/audio/`, fonts in `assets/fonts/` and models in `assets/models/`. Spaces and punctuation in the name become `_`. |
| `license`, `author` | Recorded in the provenance. Pass them for anything you did not make: the credits and the store disclosures read `assets.json`. |
| `sourceUrl` | The page the file came from. It replaces the local path in `provenance.source`. |
| `ai` | `true` when an AI made it. Left out when you do not know. |
| `columns` | Aseprite only: frames per row of the sheet. |
| `overwrite` | Replace files that already exist. Without it an existing file is an error that says so. |

The result lists the files written, the provenance recorded, importer details, warnings (what could not be carried over)
and next steps with the component settings to use. Each written file gets an `assets.json` entry with
`provenance: {origin: "imported", source, license, author, ai, date}`.

| Source | What lands in the project |
|---|---|
| `.png` `.jpg` `.tga` `.bmp` | Copied as they are (decoded once to check the engine can read it; the size is in `details`). |
| `.wav` `.ogg` `.mp3` | Copied into `assets/audio/`. |
| `.ttf` `.otf` | Copied into `assets/fonts/`. |
| `.glb` | Copied into `assets/models/`. |
| `.gltf` | Copied with the `.bin` buffers and images it refers to (relative paths, next to the model or below it). A missing buffer is an error, a missing image a warning. |
| `.aseprite` `.ase` | A PNG sprite sheet plus its `sheet` entry (see below). |
| `.psd` | A PNG of the merged image. |
| `.obj` (+ `.mtl`, textures) | A `.gltf` with its data embedded, plus the textures next to it. |
| `.fbx` | A `.glb`, converted by FBX2glTF or Blender (see below). |

Not supported (the error says what to do instead): `.blend` (export glTF from Blender), `.webp` `.gif` `.svg` `.psb`
(convert to PNG), `.flac` `.m4a` `.aac` (convert to OGG or WAV), video, and SDF/MSDF font atlases.

### Aseprite

Every frame is drawn with its visible layers (layer and cel opacity, linked cels, RGBA, grayscale and indexed color with
the palette and the transparent index) and laid out in a grid, left to right and top to bottom. By default the grid is
`ceil(sqrt(frames))` columns wide; `columns` changes it. The `sheet` entry in `assets.json` records
`columns, rows, frameWidth, frameHeight, frames` and one clip per Aseprite tag (`name, firstFrame, lastFrame, fps, loop`).
A clip's `fps` is the average of its frames' durations (`1000 * frames / milliseconds`, two decimals).

To play a clip, use the next steps of the result:

```json
{"Sprite": {"texture": "assets/hero.png"},
 "SpriteAnimator": {"columns": 4, "rows": 2, "firstFrame": 2, "lastFrame": 5, "fps": 12, "loop": true}}
```

Leave the Sprite's `region` and `size` empty: SpriteAnimator sets the region, and the frame size is the sprite size.

What is not carried over, with a warning each time: tags that play in reverse or ping-pong (the clip plays forward,
because `SpriteAnimator` only plays forward), layers with a blend mode other than normal (drawn as normal) and tilemap
layers. Slices and user data are ignored. A damaged file is an error that names what is wrong ("frame 3 is cut short").

### PSD

The merged image saved in the file (8 and 16 bit RGB) becomes a PNG, with a warning that the layers were
flattened. If it cannot be read the error says how to save it again (Maximize PSD Compatibility) or to export a PNG.
Export layers one by one from Photoshop (File > Export > Layers to Files) when you need them separately.

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
- **Weight.** One shipped file over 20 MB, with a hint by kind (convert audio to OGG, compress a texture). The total of
  the shipped files against the limit of each store the game targets: Google Play's 500 MB for the base module of an app
  (`android`), and for `ios` 200 MB, above which an iPhone asks the player before downloading over cellular data, and 4 GB,
  the App Store's limit for an uncompressed app. The total is before the export's texture compression and audio
  conversion, so a game just over a limit may fit once exported (`factoria export` reports the real size).
- **Loudness.** Every sound under `assets/` and every sound a scene or prefab names: a warning when the sample peak
  reaches 0 dBFS (within 0.1 dB: probably clipped), when the integrated loudness is above -9 LUFS (very loud) or below
  -35 LUFS (very quiet, or nothing audible), and when the sound effects (sounds of 10 seconds or less) differ by more than
  12 LU in how loud they play. The fix for most of them is `"normalize": true` in `defaults.audio`. `factoria validate`
  reuses the `analysis` records of `assets.json` while they are fresh and measures the other sounds on the spot; it
  never writes `assets.json` (run `assets.analyze_audio` to store the measurements, which makes validating fast).
  A sound that cannot be decoded is reported too.

The shipped files are the ones the export includes ([EXPORTING.md](EXPORTING.md), "What is shipped").

<!-- Filled by the texture work: the atlas-usage check. -->
