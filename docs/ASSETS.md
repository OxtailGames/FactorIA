# Assets: generate, import and ship

Art, sounds, music, voices and models get into a FactorIA game three ways, and every one of them is a command an AI can
call (MCP tool, `factoria call`, editor console):

1. **Generate** them with an asset provider (`assets.generate_image`, ...), configured like the LLM providers
   ([AI_PROVIDERS.md](AI_PROVIDERS.md)).
2. **Import** files made elsewhere (`assets.import`): Aseprite, PSD, OBJ, FBX...
3. **Write** them directly (`fs.write`), for files the engine already reads (PNG, JPG, WAV, OGG, MP3, glTF, TTF).
4. **Make** them offline, with no provider and no key: `assets.generate_texture` (materials), `assets.rasterize_svg`
   (pictures written as SVG), `assets.animate_svg` (animations written as code, baked into a sprite sheet),
   `assets.bake_sheet` (an entity the engine draws, baked into a sprite sheet), `assets.synth_sound`,
   `assets.generate_loop`, `assets.draw_icon`. Pictures made of layers (a gradient, a texture, an SVG, text and a
   provider's picture, with blend modes and masks) are written as a `*.image.json` document and baked to a PNG:
   [IMAGES.md](IMAGES.md).
   A 3D model (primitives, groups and transforms, with named parts and materials) is written as a `*.model.json`
   document and baked to a `.glb`: [MODELING.md](MODELING.md).

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
- `style` is the house style: how images are generated and the rules art is measured against (see "House style").
- Exports ship the import settings and leave `provenance` and `style` at home.

## Generating assets

An asset provider makes the file; the command writes it under `assets/` and records its provenance in `assets.json`.
Providers are configured once, in the user-level `ai.json` ([AI_PROVIDERS.md](AI_PROVIDERS.md), "Asset providers"): the
`assets` section says which provider makes each kind of asset.

```json
{"assets": {"image": {"provider": "openai"}, "sound": {"provider": "elevenlabs"}, "model3d": {"provider": "meshy"}}}
```

There is no default provider: generation costs money, so a kind that is not configured is an error that shows the JSON to
add. To try the whole flow offline and for free use the `fake` provider (`{"provider": "fake"}` in `ai.json`, or
`provider: "fake"` in a call). It makes small deterministic placeholders and is the provider tests should use.

| Command | Makes | Arguments |
|---|---|---|
| `assets.generate_image` | a PNG | `prompt`, `path`, `width` and `height` (default 512), `transparent`, `references`, `style` |
| `assets.generate_sprite_sheet` | a PNG grid of animation frames | `prompt`, `path`, `frames`, `columns`, `frameWidth`, `frameHeight`, `fps`, `transparent` (default true), `references`, `style` |
| `assets.generate_sound` | a sound effect | `prompt`, `path`, `seconds` |
| `assets.generate_music` | an instrumental music track | `prompt`, `path`, `seconds` |
| `assets.generate_voice` | speech | `text`, `path`, `voice` |
| `assets.generate_model` | a 3D model | `prompt`, `path` |

Every one also takes `provider` and `model` (use another one for this call), `seed` (providers that take none ignore it with
a warning), `overwrite` and `author` (the credit in the provenance; default `factoria`) and `approved` (see "What it costs").

**What it costs.** These calls bill money. Before the provider is called the command estimates the price from the provider's
`assetPricing` ([AI_PROVIDERS.md](AI_PROVIDERS.md#asset-providers)), refuses a call that would pass `limits.maxAssetCostUsd`
(`perRun`, `perDay`) and, above `limits.askAboveUsd` (default $0.50, counting the small calls since the user last said yes that
were not asked about), does not make it: in the editor the user answers a card
under the chat (Approve, Approve all for this run, Cancel); over MCP or the CLI the command returns
`{"needsApproval": true, "plan": {...}}` with what, how many, the provider and the estimate (in the editor `approved` is ignored: only the
user's click on the card counts). **Ask the user, and only after
they say yes call again with the same arguments and `approved: true`. Never set `approved: true` yourself and never raise a
limit.** The result carries `estimatedCostUsd` (an estimate, not an invoice; 0 for `fake` and local programs, `null` when the
price is unknown), `costIsEstimate: true` and `cost` (the basis, what the run and the day have spent). Details and the price
table (looked up 2026-11-06, several figures unverified): [AI_COSTS.md](AI_COSTS.md#asset-generation).

- `path` is project-relative and under `assets/`. Its extension has to be the one the provider makes: `.png` for images;
  `.mp3` for OpenAI speech and ElevenLabs; `.wav` for `fake` and `asset-command` audio; `.glb` for Meshy and
  `asset-command` models, `.gltf` for the `fake` cube. A wrong one is an error that names the right path, raised before
  anything is paid for.
- A path that exists is an error unless `overwrite` is true. The old file is not kept (use git).
- Images are resized to exactly `width` x `height`; providers draw at their own sizes.
- `assets.generate_image` and `assets.generate_sprite_sheet` return the picture itself (like `game.screenshot`), so an AI
  can look at it, and ask again with a better prompt and `overwrite: true`. Keep the `prompt` of what worked: the same
  prompt gives the same picture on `fake` and `asset-command`; real providers vary on every call.
- The result carries the `provenance` record that was written. Nothing is written when the provider fails.
- `seed` goes to providers that take one (`fake`, `asset-command` with `{seed}` in its `argv`). Others ignore it, and the
  result says so in `warnings`.
- Generated files are the game's files: commit them. The import settings of assets.json (compression, atlases, streaming)
  apply to them on export like to any other file.

### House style

Consistent art comes from saying the same things every time, so assets.json keeps them in `style`. The first three
settings steer the generation of images; the others are rules that `assets.check_art` and `factoria validate` measure
(M51):

```json
"style": {
  "prompt": "16-bit pixel art, black outline, flat colours",
  "references": ["assets/style/hero.png"],
  "palette": ["#1a1c2c", "#5d275d", "#b13e53", "#ef7d57"],
  "outline": {"color": "#1a1c2c", "width": 1},
  "lightDirection": "upper-left",
  "texelsPerUnit": 16,
  "pixelArt": true,
  "value": {"min": 0.1, "max": 0.95},
  "saturation": {"min": 0.3, "max": 0.9},
  "audio": {"loudnessLufs": {"music": -18, "sfx": -14, "ui": -20}, "toleranceLu": 3},
  "ignore": ["assets/ui/", "assets/fx/spark.png"]
}
```

- `prompt` is appended to the prompt of every image (`<your prompt>\n\nStyle: <style prompt>`). The provenance keeps the
  whole text that was sent.
- `references` are project-relative images sent with every image request, next to the `references` of the call. Only some
  providers accept reference images (OpenAI does, through its image-edit endpoint, as PNG, JPEG or WebP; `fake` pretends
  to); with the others the call still works, the result has a `warning`, and the provenance lists no references.
- `palette` locks the colours: after the picture is resized, every pixel takes the nearest colour of the palette (alpha is
  kept). It is a list of colours (`"#rrggbb"`, or a colour name), or the path of an image whose distinct colours are the
  palette (at most 256; more is an error that is raised before the provider is called). This is the right tool for pixel
  art and a poor one for painted art. It is also a rule: the share of pixels that are far from every palette colour.
- `style: false` in a call skips the prompt, the references and the palette lock for that call.
- `vector.style` applies `outline` and `palette` to an SVG you wrote (a stroke on every filled shape, colours snapped to the palette):
  [VECTOR.md](VECTOR.md).
- `outline` is `{"color", "width"}`: the colour of the line around a sprite's silhouette and its thickness in texture
  pixels (default 1, 0.5 to 64). `color` is required.
- `lightDirection` is where the light comes from, as a name (`right`, `upper-right`, `top`, `upper-left`, `left`,
  `lower-left`, `bottom`, `lower-right`; also `top-left`, `up`, `down` and so on) or as degrees **towards the light, counter-clockwise from the right**: 0 is right, 90 is
  top, 135 is upper-left, 180 is left, 270 is bottom. A name that is not one is an error with the closest name.
- `texelsPerUnit` is how many texture pixels a world unit holds (0.01 to 4096): a 16 x 16 sprite drawn 1 x 1 units
  large has 16. It is read from the scenes (Sprite size, the scale of the entity and its parents, a sheet frame or a
  region), so it only judges textures a Sprite draws.
- `pixelArt` is `true` when the art is pixel art: no soft edges (partly transparent pixels), few colours, and a palette
  that is matched strictly.
- `value` and `saturation` are `{"min", "max"}` in 0 to 1 (either end may be left out; min must not be above max).
  `value` is the HSV brightness of the darkest and the lightest pixels (the 1st and the 99th percentile of the visible
  pixels, so a stray pixel does not count); `saturation` is the mean HSV saturation of the visible pixels.
- `audio` is `{"loudnessLufs": {"<bus>": <LUFS>}, "toleranceLu"}`: the integrated loudness each mixer bus aims at (-70
  to 0) and how far a sound may be from it (0.5 to 24 LU, default 3); a bus named `default` covers the buses not listed.
  `assets.check_mix` is the reader that compares sounds with it.
- `ignore` is a list of project-relative files, and folders (end the path with `/`), that the style rules skip: UI,
  effects and art that is meant to differ. `assets.check_art` still measures them; it just does not judge them against
  the style rules, and `factoria validate` stays silent about them.

Only the rules you write are checked: a style without `outline` never complains about outlines. A mistake in `style` is
an error that names the JSON pointer and the fix (`/style/outline/width: style.outline.width is 90, outside 0.5 to 64`,
an unknown key comes with the closest known one). Every reader (the generation commands, `assets.check_art`,
`factoria validate`) parses `style` with the same code (`load_style_guide`, fa/tooling/style_guide.h), so they always agree.

`factoria validate` adds a warning for each rule that a texture drawn by a `Sprite` **clearly** breaks (the `fail` verdict
of `assets.check_art`, below), for example `assets/hero.png: Breaks the style rule 'texelsPerUnit' (assets.json style): The scenes
draw this texture at 32 texture pixels per world unit ...`. The warning names the rule and the numbers, and the hint names
the fix and `style.ignore`. A `warn` verdict is only in `assets.check_art`, so validate never nags about borderline
art. A rule that cannot be judged for a picture is skipped: no silhouette (an opaque tile), no clear light (a flat picture),
no scene drawing the texture (`texelsPerUnit`). The measurements of a picture do not depend on the style and are cached by the SHA-256 of the file in
`.factoria/art-cache/` (ignored by git; deleting it is safe), so validating a project measures each picture once.

### Sprite sheets

`assets.generate_sprite_sheet` asks for `frames` animation frames in a grid, normalizes the picture to exactly
`columns * frameWidth` x `rows * frameHeight` (each side at most 4096) and writes the layout to assets.json as the `sheet`
of the file, with one clip `default` over all frames at `fps`. The result shows what to put on an entity:

```json
{"Sprite": {"texture": "assets/knight_walk.png"},
 "SpriteAnimator": {"columns": 3, "rows": 2, "firstFrame": 0, "lastFrame": 5, "fps": 10}}
```

Providers draw grids unevenly (frames drift, the count is off by one): look at the picture and ask again. To cut a
sheet that already exists into frames, see "Importing files".

### Sounds, music, voice, models

`assets.generate_sound` takes `seconds` (ElevenLabs: 0.5 to 30; leave it out to let the model choose). `assets.generate_music`
makes instrumental tracks (`seconds` 3 to 600); ask for a loopable piece in the prompt and set `loop` on the
`AudioSource`. `assets.generate_voice` speaks `text` with `voice` (OpenAI: a voice name such as `alloy`; ElevenLabs: a
voice id; the default comes from `assets.voice.voice` in `ai.json`), and records the voice in the provenance notes so a
character can be given the same voice later. `assets.generate_model` makes an untextured mesh (Meshy takes minutes and
`timeoutSeconds` of its provider is how long to wait); look at it in the scene before building on it.

**Voice without a provider.** `assets.generate_voice` needs `ELEVENLABS_API_KEY` or `OPENAI_API_KEY` (`ai.providers` doctor
says which is set); without one it fails and names both keys. To test code that waits for a voice line (captions, ducking,
lip timing) pass `silent: true`: it writes a silent mono WAV with no provider, as long as the line (0.06 s per character, or
`seconds` for a fixed length) and records it as `origin: "original"`, `ai: false`. Replace the file with the real clip later;
the path and the length you put in your data stay valid if you give the same `seconds`.

Play a sound with an `AudioSource` (`clip`) or `audio.play(path)`; use a model as the `mesh` of a `MeshRenderer`.

### Loops and Ogg without a provider: assets.generate_loop, assets.convert_audio

`assets.generate_loop {path, kind, seconds, seed}` writes a seamless loop offline (same seed, same bytes). `kind: "noise"`
is an ambience bed (`color` white, pink or brown; `bass`, `gusts`, `hum`, `crackle`, `ticks` shape it: wind, a fire, a clock)
and `kind: "drone"` is a score: `chords` (note names such as `A3`, `F#2`, `Eb4`, or Hz) played in turn, each `chordSeconds`
long; `underNote` (for example `D1`, at `underLevel`) holds one soft note under the whole loop. The loop point is inaudible: filters run circularly and every periodic part fits a whole number of times in `seconds`.
A `.ogg` path writes Ogg Vorbis (`quality` 0 to 1). Set `loop` on the `AudioSource`. Keep the call as JSON in the project
(Larkspur Lodge: `assets/src/sound/*.json`) and rerun it with `factoria call assets.generate_loop @file.json`.

`assets.convert_audio {path, to}` converts a WAV to `.ogg` next to it (the WAV stays, with its provenance copied). The encoder
is the engine's own (no ffmpeg or oggenc needed): Vorbis I, long blocks only, mono or stereo, deterministic. The Ogg is much smaller than
the 16-bit WAV; the encoder is simple and not tuned for high-quality music.

### Hear what you made: assets.spectrogram and assets.check_mix

An AI cannot listen, so two read-only commands turn a sound into something it can look at and check. Both decode the sound
themselves (no external program), are deterministic, and reuse the sound's fresh `analysis` record for its integrated
loudness (they never write `assets.json`; run `assets.analyze_audio` once to keep the records).

`assets.spectrogram {"path": "assets/sfx/jump.wav"}` returns a picture like `assets.preview_sheet` does (a temporary
screenshot; `out` keeps the PNG at a project path; `width` 400 to 2400, `height` 280 to 1600). Top: the waveform (the mid
channel, or one lane per channel with `channels: "each"`), where red columns are samples at full scale. Middle: the
spectrogram, a short-time Fourier transform of the mid channel on a logarithmic axis from 20 Hz to 20 kHz, brighter =
louder, with the dB scale on the right (the range is in the result). Bottom: the loudness curve, momentary (400 ms, blue)
and short-term (3 s, orange), the integrated value dashed and the loudest momentary value marked. A sound the project plays
looping (an `AudioSource` with `loop`, `SceneSettings.music`, `audio.music`, `audio.play(path, {loop: true})`, or `loop: true`
in the call) gets the loop seam marked with magenta dashed lines and its numbers in the title. The result has
`integratedLufs`, `truePeakDb`, `samplePeakDb`, `momentaryMaxLufs`, `shortTermMaxLufs`, `clippedSamples`, `dominantBand`
(the loudest octave band) and `loopSeam`.

`assets.check_mix {}` measures every sound of the project together (the set `assets.analyze_audio` uses without `path`),
or `paths`, as the player hears them: with the gain import `normalize` applies. Every finding is
`{sound, rule, value, threshold, unit, verdict (ok | warn | fail), message, hint, bus?, detail?}`; the findings that pass
are left out unless `includeOk: true`. The result also has a `summary`, one row of numbers per sound and `nextSteps`.

| Rule | What it measures | warn / fail |
|---|---|---|
| `loudness_target` | Loudness as played against the target of the sound's bus. | beyond the tolerance / twice it |
| `loudness_spread` | With no target: distance from the median of the sounds of the same bus. | beyond 6 LU / 12 LU |
| `music_masking` | The octave bands where an effect has its main energy (within 6 dB of its loudest band) against the loudest music in those bands. `value` is how far the effect is over the music in its loudest band. | music as loud or louder in that band, or in half the main bands / music 6 dB louder |
| `click_start`, `click_end` | The first / last sample, or a jump of the first / last step far above the sound's usual step (dBFS). Not for looping sounds. | above -40 dBFS / above -26 dBFS |
| `loop_seam_jump`, `loop_seam_slope` | For looping sounds: the step from the last sample to the first, and the change of slope across it, as multiples of the sound's usual step and curvature. | 5 / 10, and 8 / 16 |
| `clipping` | Samples at full scale in runs of two or more (a flattened wave), counted. | any / 32 or 1 in 2000 |
| `true_peak` | The peak between samples (4 times oversampled), as played. | above -1 dBTP / above 0 |

Where the bus comes from: an `AudioSource` plays on `sfx`; `SceneSettings.music` and `audio.music("path")` in a script
play on `music` (looping); `audio.play("path", {bus, loop})` with a literal path plays on its `bus` (default `sfx`); a bus of
`factoria.json` `audio.buses` counts as the bus it is under. A sound that none of them names with a literal path is on the
"unknown bus": play it in one of those ways, so the check can place it. It is not told apart from music by its name or length.
Masking compares the long-term level of each octave band (31 Hz to 16 kHz) of the effect, over the part that is not
silent, with that of the music, both as played; it does not know the volumes a script gives the voices.

Loudness targets, in the order they are looked for: the `targets` argument (`{"music": -16, "sfx": {"lufs": -14,
"toleranceLu": 2}, "default": -16}`; a number uses a tolerance of 3 LU), then `style.audio.loudnessLufs` (one per
bus, `default` for the rest) and `style.audio.toleranceLu` in `assets.json`, then the spread rule. The hints are concrete: a `targetLufs` to
set under the sound's `import`, a fade length in samples, `assets.generate_loop` for a seamless loop, ducking the music
bus for a masked effect, a level to cut for a true peak.

### Sound effects without a provider or a kit: assets.synth_sound

Free CC0 kits (for example Kenney's audio packs) have impacts, interface sounds and jingles, brought in with
`assets.import` and the license `CC0`; they have no animals or creatures. For those, and for any placeholder or simple
effect, `assets.synth_sound` makes the sound offline: no provider, no key, no cost.

```
assets.synth_sound {"path":"assets/audio/dog_bark.wav","preset":"bark","seed":3}
```

`preset` is `bark`, `growl`, `meow`, `screech`, `whoosh`, `explosion`, `hit`, `coin`, `pickup`, `jump`, `powerup`, `laser`,
`blip`, `click`, `error`, `splash` or `footstep` (an unknown name is an error with a "did you mean"). The result is a mono
16-bit 44.1 kHz WAV levelled to about -18 LUFS (every preset: a square and a sine sound equally loud, the peak stays under
-1 dBFS, so `factoria validate` has no loudness warning for it), and the same `preset`, `seed` and `seconds` always give the same bytes; change
`seed` for another take (pitch and timing move a little). `seconds` (0.02 to 10) overrides the preset's length.
`overwrite` replaces an existing file. The provenance in `assets.json` is origin `original`, `ai` false, license CC0, with
the preset and the seed. These are synthesizer sounds: fine for a game's feedback, not a replacement for recorded or
composed audio.

Each preset is a sound patch (`*.sfx.json`, docs/SOUND.md) that ships in the engine: `sfx.preset {"name":"bark"}` returns it,
`sfx.preset {"name":"bark","path":"assets/audio/bark.sfx.json"}` writes it, and `sfx.render {"path":"assets/audio/bark.sfx.json"}`
renders your edited version (layers, envelopes, pitch sweeps, filters, FM, effects), with the loudness numbers and a spectrogram.
Use `assets.synth_sound` for a preset as it is, and a patch when you want to design the sound.

### Materials without a provider: assets.generate_texture

With no image provider (`assets.generate_image` fails with `no_provider`), `assets.generate_texture` paints a material
offline: no provider, no key, no cost. It makes surfaces, not drawings: backgrounds, desks, book covers and pages, floors,
walls. The same arguments give the same picture with the same build of factoria (change `seed` for another take); it is
not promised to be bit-identical between platforms.

```
assets.generate_texture {"path":"assets/textures/desk.png","preset":"planks","width":1280,"height":720,"seed":4}
assets.generate_texture {"path":"assets/textures/desk_top.png","preset":"planks","plankCount":7,"plankLength":0,"gapWidth":0.01}
assets.generate_texture {"path":"assets/textures/cover.png","preset":"leather","color":"#5b2a1a","accent":"#1d0d07","normalMap":true}
assets.generate_texture {"path":"assets/textures/page.png","preset":"parchment","width":640,"height":900,"vignette":0.6}
assets.generate_texture {"path":"assets/textures/floor.png","preset":"stone","tileable":true,"scale":2}
```

`preset` is `paper`, `parchment`, `wood`, `planks`, `leather`, `fabric`, `linen`, `stone`, the noises `value`, `fbm` and `cellular`,
and `gradient`, `radial` and `vignette`. The command description lists what each one is and its default colours. The
size is `width` x `height` (up to 2048; the height defaults to the width; 512 when neither is given). Options:

| Field | What it does |
|---|---|
| `color`, `accent` | Recolour the material: the main colour and the second one (shadow, late wood, creases, joints, the far end of a gradient). |
| `scale` | Size of the features, 0.1 to 10 (1 is the preset's natural size for the picture). |
| `roughness` | 0 smooth and even to 1 worn and uneven. |
| `tileable` | The picture repeats with no seam at its edges (the materials and the noises; `gradient`, `radial` and `vignette` ignore it and say so in `warnings`). |
| `vignette` | How strongly the edge is darkened (a worn page); 0.5 by default on `parchment`, 0 on the others. The border is narrow and irregular (see `vignetteWidth`). Not used when tileable. |
| `vignetteWidth` | How wide the darkened edge is, as a fraction of the picture's short side (0.005 to 0.5). The default 0.035 is a narrow worn edge whose inner border wanders in and out; 0.1 is a visible frame; 0.17 gives the wide uniform frame that earlier versions drew by default. Ignored (with a warning) when no edge is darkened. |
| `angle` | The direction of a `gradient` in degrees. |
| `normalMap`, `normalStrength` | Also write `<name>_n.png`, a tangent-space normal map of the same relief (+Y up, the convention of `Sprite.normalMap` and glTF). |
| `plankCount`, `plankLength`, `gapWidth`, `gapDarkness` | `planks` only (other presets ignore them and say so in `warnings`). `plankCount`: boards stacked from the top to the bottom of the picture (1 to 64; default follows `scale`, 6 at scale 1). `plankLength`: a board's length as a fraction of the width: `0` makes every board run from side to side with no butt joint (a desk top seen from above), `1` (the default) gives each row one staggered joint, `0.5` two boards per row, `0.25` four. `gapWidth`: the seam between boards as a fraction of a board's width (default 0.015, a fine seam; 0.05 is a wide gap). `gapDarkness`: 0 leaves the seam the colour of the wood, 1 makes it as dark as `accent` allows (default 0.55). |
| `overwrite` | Replace an existing file. |

The result has the `warnings`, the `nextSteps` (the `Sprite` to use, or `tileable` hints) and a preview of the picture:
look at it and call again with other `seed`, `scale` or `color`. The textures are lit from the upper left, so grooves and
bumps read. The provenance in `assets.json` is origin `original`, `ai` false, license CC0, with the arguments in the
notes; the normal map gets its own record. Smooth presets (`gradient`, `radial`, `paper`...) carry a little dither
against banding, so their PNGs are larger than a flat image.

### Pictures you write as SVG: assets.rasterize_svg

For a subject (a crest, a silhouette, an ornament, a map symbol) an agent with no image provider writes the shapes as SVG
and rasterizes them: `assets.rasterize_svg` takes the SVG text in `svg` or a project `.svg` file in `source` and writes
an anti-aliased PNG at `path` on the CPU (nanosvg, vendored in `external/nanosvg`, zlib license).

```
assets.rasterize_svg {"path":"assets/art/crest.png","width":256,"svg":"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='M50 6 L90 22 V52 C90 76 70 90 50 96 C30 90 10 76 10 52 V22 Z' fill='#8b1e1e' stroke='#e8c66a' stroke-width='4'/><circle cx='50' cy='48' r='14' fill='#e8c66a'/></svg>"}
```

- **Editing it afterwards.** The `vector.*` commands edit the SVG file (or an svg layer of an image document) instead of making you
  rewrite it: path booleans, offset and inset, stroke to outline, simplify and smooth, align, distribute, repeat and the
  `style` of `assets.json` (see "House style": outline width and colour, palette snapping), each returning a preview picture ([VECTOR.md](VECTOR.md)).
- **Size.** The SVG is fitted inside `width` x `height`, aspect kept and centred; with only one of them the other follows
  the SVG's proportions; with neither, the size the SVG declares. Up to 4096. `background` puts it over a colour
  (transparent by default).
- **Supported.** `path` (every command), `rect` (with `rx` and `ry`), `circle`, `ellipse`, `line`, `polyline`,
  `polygon`, `g`, `defs`, `linearGradient` and `radialGradient` fills, `fill`, `stroke`, `stroke-width`,
  `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, `fill-rule`, `opacity`, `fill-opacity`,
  `stroke-opacity`, `transform`, the `style` attribute, `viewBox` and `preserveAspectRatio`.
- **Clip, mask, pattern.** `clip-path="url(#id)"` on a `g` or on a shape, with a `<clipPath>` of `path`, `rect`,
  `circle`, `ellipse`, `polygon`, `polyline` or `line` children (their `transform`, `clip-rule` and the clipPath's own
  `transform` count). Only `clipPathUnits="userSpaceOnUse"` (the default): write real coordinates in the user space of
  the element that uses the clip, so a transform on that element moves the clip with it. `mask="url(#id)"`: the
  luminance of the mask's content times its alpha (white shows, black hides, a gradient fades); the mask region
  (`maskUnits`, `x`, `y`, `width`, `height`) is ignored and `maskContentUnits` is always user space. `fill="url(#id)"` on
  a `<pattern>` (also inherited from a `g`): `patternUnits` and `patternContentUnits` (`userSpaceOnUse` or
  `objectBoundingBox`, which is the default for `patternUnits`), `x`, `y`, `width`, `height` and `patternTransform`, so
  line hatching is a pattern of one stroked line, tilted with `patternTransform="rotate(45)"`. The pattern's tile is not
  clipped to its width and height; a pattern `viewBox` and `href` chains are ignored (warning for the viewBox); a pattern
  as `stroke` is not drawn (warning). Each clipped, masked or patterned shape is rendered as its own layer (consecutive
  shapes with the same clip share one), so hundreds of them slow the call down. The `engrave` style of the game that asked
  for this (hatching the darker side of each shape) is not built in: draw the hatching with a pattern.
- **Not supported.** `text` and `tspan` (turn letters into paths, or put a `Text` entity in the scene), filters (blur,
  drop shadow), embedded images, `<use>`, markers and CSS classes in `<style>`. They are
  drawn as nothing and named in `warnings`. For a hand-painted look do not simulate it with hundreds of shapes: use
  `style`.
- **Style.** `style` adds a painterly look to the pixels after rasterizing, seeded and deterministic (the same SVG,
  size, `style`, `styleStrength` and `seed` give the same picture; `seed` chooses the take), so the SVG stays small and
  flat. `watercolor`: wobbling, softened edges, pigment pooled darker along the border of every shape, pale and strong
  blotches and paper granulation. `ink`: a wobbling dark-brown pen line along every border, thicker and thinner.
  `inkwash`: both, with a little paper tooth (storybook ink and watercolour). `paper`: only paper fibres and mottling,
  edges untouched. `styleStrength` (0 to 1, default 1) scales the effect. The effects scale with the picture's size, are
  applied to the shapes (transparent space stays transparent) and run before `background`; for a paper sheet under the
  drawing make one with `assets.generate_texture`. Draw flat fills with a few shapes and let the style add the texture.
  ```
  assets.rasterize_svg {"path":"assets/art/hill.png","source":"assets/art/hill.svg","width":800,"style":"inkwash","seed":3}
  ```
- **Gradients.** Write the coordinates in percent (`x2="100%"`) or with `gradientUnits="userSpaceOnUse"` and real
  coordinates: nanosvg reads a bare `0` to `1` such as `x2="1"` as pixels.
- **Provenance.** By default the record is origin `generated`, `ai` true, because the agent that calls the command wrote
  the SVG (it counts for the store's AI-content disclosure). For an SVG a person drew or licensed pass `ai: false`, with
  `author` and `license`: the record is then origin `original`. Where the SVG came from is in `source`.

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
[EFFECTS.md](EFFECTS.md).

### Checking a sheet: assets.preview_sheet

`assets.preview_sheet {"path":"assets/art/coin_spin.png"}` draws the sheet as a labelled grid (a temporary picture, returned as
`$image`, that an AI can look at): the frame numbers (`f0`, `f1`...), the frame rectangle (cyan) and the cell edge (grey,
which differs from the frame when there is `padding`), and the pivot (a magenta cross). `clip` shows only that clip's frames
(an unknown name is an error with the clip list and the closest name); `onion: true` overlays the previous frame in red and the
next in blue at 40% so you can see how far things move between frames. The grid is the `sheet` entry of the texture, or the
arguments `columns`, `rows`, `frameWidth`, `frameHeight` and `padding` when the sheet has none (without either the error
`no_grid` says what to pass). `scale` and `tileColumns` set the size and the layout of the picture. It reads the sheet and writes
only the temporary picture, and its `warnings` are the checks: the grid does not match the image, more frames than the grid
holds, a clip outside the sheet, an empty frame, ink touching the edge of the cell, the drawing jumping between frames (the
centre of its ink moves by more than 30% of the frame) and a looping clip whose last frame jumps from the first or repeats it.
The result also has `frames` (for each shown frame: `empty` and the `bbox` of its ink in frame pixels) and `nextSteps`.
The Project panel plays the same clips (see [EDITOR.md](EDITOR.md)).

### Judging a set of assets: assets.contact_sheet

`assets.contact_sheet {"paths":["assets/hero.png","assets/slime.png"],"sizes":[32,64]}` draws the pictures side by side at the
size the player sees them, over a light background, a dark one and the clear colour of the first primary camera of the main
scene, plus a last row in greyscale (`greyscale: false` leaves it out). Each column is labelled with the file name and its size
in the font that comes with the engine. It is the way to see what disappears: an outline that vanishes when small, a shape that
merges with one background, two sprites with the same value in greyscale. The result is a picture returned as `$image` (like
`assets.preview_sheet`); nothing is written unless you pass `path`, and an existing file is then not replaced without
`overwrite: true`. The same inputs give the same picture (CPU only, except models).

- `sizes` are pixels of the longest side as the player sees it (Sprite.size on screen times the render scale); each picture is
  drawn once per size, shrunk with averaging or grown with hard pixels. Without `sizes` a picture is drawn at its native size
  (at most 512).
- `backgrounds` (1 to 6 colours, such as `"#3a7d44"`) replaces the default rows; the camera colour is then not added.
- `columns` (default 8) sets the cells per line; the picture grows downwards and is capped at 2048 pixels (a warning says so).
  More than 160 cells is an error.
- A PNG, JPG, BMP or TGA is drawn as it is. A sprite sheet (a `sheet` entry in assets.json) shows its first frame, or every
  frame with `allFrames: true`.
- A `.glb` is drawn as a thumbnail by the renderer (studio light, turned three quarters, transparent around it). That needs a
  graphics device: without one the command fails with `no_gpu`, and you can leave the models out. A model in the real scene,
  with its lighting, is `assets.preview_in_scene`.

The result has `warnings`, `nextSteps` (they name `assets.preview_in_scene`, `game.screenshot` and `assets.preview_sheet`) and
`backgrounds`, `rows`, `cells`, `picture` (width, height, scale) and `written` (with `path`).

### A new asset in a real scene: assets.preview_in_scene

`assets.preview_in_scene {"path":"assets/hero.png","scene":"scenes/level1.scene.json","at":[0,0]}` places a PNG as a `Sprite`
(or a `.glb` as a `MeshRenderer`) in a copy of the scene running in a second, headless engine, and returns screenshots at phone
(540x1170) and desktop (1280x720) resolutions, as one picture with the screens side by side and labelled (the MCP result
carries a single image). `resolutions` takes `"phone"`, `"tablet"` (1024x768), `"desktop"` or `"WxH"`, up to four. The scene
file is never changed and no temporary entity is left: the asset exists only in that second engine. It needs a renderer; headless
without a graphics device it fails with `no_gpu` and says to use `assets.contact_sheet` or `game.screenshot`.

- Position: `at` ([x, y] or [x, y, z]) or `entity` (an entity of the scene). With `entity`, `placement: "beside"` (default)
  puts the asset to the right of it (the gap is a rough estimate from the entity's `Sprite` or `Shape2D` size, else 64 units)
  and `"replace"` puts it at the entity's position with that entity hidden in the picture. `offset` ([x, y]) moves it from there.
  With neither, it goes to the middle of the view.
- `size`: for a sprite a number (longest side) or [width, height] in world units, default its size in pixels; for a model its
  largest dimension in meters, default its own size.
- `steps` (default 2) is how many frames the scene runs before the asset is placed, so scripts and spawners have started.
- `center: true` (2D scenes) moves the camera onto the asset so it is in view at every resolution; a camera script can move it
  back. Without it an asset outside the view is a warning that says where it would land.
- The size of the screens comes from the resolution you ask for, not from the project's design resolution.

The result has `asset`, `scene`, `screens`, `sceneFileChanged: false`, `warnings` and `nextSteps`.

### Choosing between candidates: review.sheet and review.pick

`review.sheet {"items":[{"image":"assets/hero_a.png","candidate":true},{"image":"assets/hero_b.png","candidate":true}],"label":"Which hero?"}`
puts N candidates on ONE picture, each in a cell with a big number (1..N, in the order of `items`), its label and one line of facts, so
a person answers with one number. The picture comes back as `$image` and is kept in the project: `.factoria/review/sheet-NNNN/` holds
`sheet.png`, `thumbs/NN.png` (each thumbnail alone) and `manifest.json`. The guide to the loop (make N, show one sheet, ask for one
number) is [AI_GUIDE.md](AI_GUIDE.md), section 9.32.

Each item has exactly one of these keys, plus `label` (default: the file name) and `candidate`:

| Key | What is drawn | The line of facts | GPU |
|---|---|---|---|
| `image` | the picture as it is (shrunk with averaging, grown by a whole factor with hard pixels) | size, colours (counted up to 1000), % clear | no |
| `vector` | the .svg rasterized like `assets.rasterize_svg` | size, shapes and colours (counted from the file's text) | no |
| `level` | `tilemap.generate` with these arguments (`seeds`: one thumbnail per seed); one square per cell, a letter on it when it is big enough | size, seed, tries | no |
| `scene` | the scene started and run for `steps` frames (default 2), then captured | entities, picture size | yes |
| `prefab` | spawned on a plain stage and framed: 2D from its visuals, 3D turned three quarters under a studio light | entities, size | yes |
| `vfx` | the middle picture of `vfx.filmstrip`, over a dark stage or the scene given as `stage` | peak particles, length | yes |

- A level's `sample` takes the forms of `tilemap.generate`: ASCII rows as an array of strings (with `legend` next to it), an object
  `{rows, legend?}`, one string with line breaks, the project path of a `.json` rows file, or the id or name of an ENTITY WITH A TILEMAP.
  Only the entity form needs a scene to look the entity up in: the project's main scene (`mainScene` in `factoria.json`), or the scene
  the item names with `sampleScene` (`{"level":{"sample":"town","size":[40,24]},"sampleScene":"scenes/town.scene.json","seeds":[1,2]}`).
  The scene is read, never changed, and the manifest keeps it as `spec.sampleScene`, so `tilemap.generate` afterwards sees the same
  entity. With neither a main scene nor `sampleScene` an entity sample is an error with the JSON pointer. `maxSeconds` of a level is
  not fixed by the sheet (the 1800 CPU seconds of `tilemap.generate` are only a safety net); `maxWork` is, at 20 million unless set.
- Items that need a GPU fail the whole command with `no_gpu` before any file is written, like `assets.preview_in_scene`; images, vector
  art and levels need none, and the same input gives the same thumbnails on every machine.
- Limits: 48 items (a level's `seeds` count one each), 12 columns, a thumbnail of 64 to 512 pixels (`thumbSize`; by default chosen
  from the number of items, about 1800 pixels wide) and a sheet of at most 8192 pixels a side and 16 million pixels. A level thumbnail
  is generated up to 1024 cells a side, with `maxWork` 20 million unless the item sets it. A request over a limit, a level with `into`,
  or `seed` together with `seeds` is refused first, with the JSON pointer of the item and what to change. Each picture is fitted into
  its thumbnail as soon as it is drawn and the original is dropped, a picture whose header announces more than 64 million pixels
  (PNG, JPG, BMP or TGA) is refused before it is decoded, so a sheet of 48 big pictures stays small.
- `candidate: true` is for files you made for the choice: it needs the right kind of file (`.png/.jpg/.bmp/.tga`, `.svg`,
  `.scene.json`, `.prefab.json` or `.vfx.json`, so `factoria.json` and `assets.json` can never be one), never the main scene, anything under
  `.factoria/` or `.git`, nor a file that another item shows or plays in as the `stage` of an effect. The request is refused with the
  pointer of the item, and `review.pick` checks every file again before it moves it (the manifest is a file anyone can edit), through
  the same project-path rules as the other commands (no absolute path, no `..`, no link that leads out of the project).
- `meta` is your own small object (at most 4096 bytes as JSON, for example `{"slot":"hero"}`): `review.sheet` stores it in the manifest
  and `review.pick`, `review.info` and `review.list` return it untouched.
- An item that cannot be drawn (a corrupt picture, a level the solver could not make in its attempts) is a red tile that
  `review.pick` refuses, with the reason in `warnings`; if no item can be drawn nothing is written.
- The manifest (`factoria.review/1`) records each item (`n`, `type`, `label`, `source`, `candidate`, `info`, `numbers`, `spec`, where its
  cell and picture are on the sheet), when the sheet was made (from the engine's clock), and `picked`: null until `review.pick`
  answers. `review.list` and `review.info` read it, and the files are plain JSON and PNG, so any tool can list the sheets and their history.

`review.pick {"sheet":"latest","n":2}` records the number the person chose (who picked, when, an optional `note`, and the item's
`spec`, so a picked level's seed is kept). With `drop` (default true) it MOVES the files of the other items that were marked
`candidate: true` to `.factoria/review/dropped/<sheet id>/<NN>_<file name>` (another folder below `.factoria/` with `dropDir` on the
sheet); the pick itself deletes nothing (`review.cleanup` deletes the dropped files 7 days later; `droppedDays: 0` keeps them), and the result and the manifest list each move (`from`, `to`), so moving a file back undoes it. The
picked item's file, files that are not marked, the main scene and files in `.git` are never moved, and `assets.json` is not edited
(the result warns when it still lists a moved file). It is all or nothing: if a move fails the ones already made are put back and the
manifest does not change; a leftover in the drop folder (`exists`) stops it before any move. The manifest is changed under a lock in
`.factoria/review/`, so the editor, the CLI and an agent can use sheets at the same time. A sheet can be picked once. A crash (a power cut) between the moves and the manifest write leaves the moved files in the drop folder
with the sheet still unanswered: pick again (a file that is already gone is reported, not an error), or move the files back by hand.
`dropDir` is a folder below `.factoria/`, not `.factoria/tmp`, not `.factoria/review` itself and not another sheet's folder.

**Housekeeping.** The files a pick moved are kept 7 days after the pick; `review.cleanup` (it also runs after every new `review.sheet`;
failures there are only warnings) then deletes them, marks them `expired` (or `gone` when they were moved back) in the manifest and
removes the empty folder. It only deletes the file `<dropDir>/<sheet id>/<NN>_<name>` that a pick recorded, never the chosen file, never
anything of a sheet nobody answered, and `droppedDays: 0` keeps them for ever. A sheet folder without a manifest (the process died while
it was made) is listed by `review.list` as an `orphan` and removed by `review.cleanup` once nothing in it changed for 60 minutes
(`orphanMinutes`). `dryRun: true` reports what would go and deletes nothing.

**Over MCP and the CLI nothing asks the person: `review.pick` must get the number THEY gave you.** Never choose for them: ask in the conversation, show the sheet,
wait for the number.

### Candidates for one asset: assets.generate_image count and assets.pick

`assets.generate_image {"prompt":"a red potion bottle","path":"assets/items/potion.png","width":64,"height":64,"count":3}` makes
three candidates for the slot `assets/items/potion.png` instead of the file itself, and one review sheet that shows them:

- The candidates are written next to the slot as `potion.candidate-1.png`, `potion.candidate-2.png`... (`count` is 1 to 4; 1 is the
  plain call that writes the slot). Each has its own seed (`seed`, `seed+1`...; without `seed` the first comes from the prompt, so the
  same prompt gives the same seeds) and its own provenance in `assets.json`, with `candidate: {slot, n, count}`.
- Everything that can be refused is refused before the provider is called: a `count` out of 1..4 (with the pointer `/count`), a slot
  that exists, or candidate files that exist (left by an earlier call), unless `overwrite` is true.
- The cost estimate, the limits and the approval cover all the candidates at once, before the first picture (docs/AI_COSTS.md,
  "Asset generation"): one question, one yes, for the batch. When the provider fails part way, the error lists the candidates that were
  written (kept, with their provenance), the estimated cost of those, and gives the rest of the estimate back; no sheet is made then.
- The sheet is an ordinary `review.sheet` (the section above): every item is `candidate: true`, its label is the seed, the sheet's label
  is the prompt, its `dropDir` is `.factoria/assets/candidates`, and its `meta` is
  `{"kind":"assetCandidates","slot":...,"command":"assets.generate_image","count":...,"candidates":[...],"overwrite":...,"estimatedCostUsd":...}`.
  The result carries the sheet id, the candidates, the cost, the sheet picture as `$image` and the next steps.

Show the sheet, ask the person for ONE number, then `assets.pick {"slot":"assets/items/potion.png","n":2}`:

- It answers the newest unanswered candidates sheet of that slot (or `sheet`, which must be a candidates sheet of the same slot), with
  `review.pick` itself: the same lock, the same file checks, the same all or nothing, the choice and `note` recorded in the manifest.
- Candidate 2 is moved to the slot. The slot's entry in `assets.json` gets that candidate's provenance (prompt, provider, model, seed)
  plus `candidates: {sheet, picked, count, estimatedCostUsd, costIsEstimate}`, and the candidates' own entries are removed.
- The other candidates move to `.factoria/assets/candidates/<sheet id>/NN_<name>`, where `review.cleanup` deletes them 7 days later,
  like the files of any picked sheet. A slot file that exists needs `overwrite` (in the generate call or the pick) and is kept there as
  `00_<name>` for the same 7 days.
- When a file cannot be moved (open in a viewer: code `busy`) or `assets.json` cannot be written, every move is put back and nothing
  changes. A sheet that was answered is refused with `already_picked` (make new candidates to choose again); a slot with no candidates
  sheet is `not_found`, with the slots that have one as suggestions.
- Until the pick the candidates are files under `assets/`, so an export would ship them: pick (or delete them) before exporting.

Never pick for the person. The editor's Review window answers these sheets with the same call, `assets.pick {"sheet":..., "n":..., "slot":...}`,
for every sheet whose `meta.kind` is `"assetCandidates"`.

### Checking art: assets.check_art

`assets.check_art {"path":"assets/hero.png"}` (or `{"paths":[...]}`, up to 12 pictures, checked one by one and as a set) looks
at a picture the way the game shows it and returns a temporary annotated picture (`$image`) plus numbers. It reads the
project and writes only the temporary picture (and the cache `.factoria/art-cache/`), and it is deterministic. Every rule in the
result has a `value`, a `threshold` (the limit of `ok`), usually a `failThreshold` (the limit of `warn`), a `verdict` (`ok`,
`warn` or `fail`), a `message` with the numbers of this picture and, unless `ok`, a `hint` that names a real command or setting.
The asset's verdict, the result's and the `counts` are the worst of their rules.

Arguments:

- `backgrounds`: what the picture is drawn over, a list of colours (`"#203040"`, a name, `[r, g, b]`) and project image
  paths (an image stands for its dark, middle and light parts). Without it: the clear colour and the large background sprites (covering at
  least half of the view, on a lower layer) of the scenes that draw the picture, else a light and a dark default.
  `assets[].backgrounds.source` says which: `explicit`, `scenes` or `default`.
- `onScreenPx`: the longer side of the sprite on screen, in screen pixels (a number or up to 4). Without it the size comes from
  the scenes (Sprite size, the scale of the entity and its parents, the camera's `orthoSize`) on two reference screens: a phone, 844 x 390
  points, and a desktop monitor, 1920 x 1080 (turned for a `portrait` project), with the design resolution of
  `factoria.json` `display` fitted inside (`fit`). A picture no scene draws is not judged for readability (a `note` says so).
- `style: false`: skip the rules of `style` (below).

The rules (default thresholds; `style` rules override only what they set):

| Rule | What it measures | ok | warn |
|---|---|---|---|
| `contrast` | per background: the WCAG contrast ratio of the silhouette edge pixels (over the background) | at least 3:1 | at least 1.5:1 |
| `readability.size` | per screen: the longer side of the sprite on screen | 16 px or more | 8 px or more |
| `readability.silhouette` | share of the silhouette still there after shrinking to the on-screen size | 85% | 60% |
| `readability.edge` | thickness of the outline line on screen (only when the picture has one) | 0.7 px | 0.4 px |
| `fringe.partial` | share of the partly transparent edge pixels that are darker or lighter than every opaque pixel they touch | at most 10% | at most 30% |
| `fringe.bleed` | share of the transparent pixels next to the shape that hold a far colour, for a picture drawn with a smooth filter | at most 20% (warn above) | |
| `outline.color` | share of the edge pixels near the colour of `style.outline` (RGB distance up to 48) | 80% | 50% |
| `outline.width` | median thickness of the outline against `style.outline.width` | within 1 px | within 2 px |
| `value.min`, `value.max` | the darkest and the lightest pixels against `style.value` | inside, or up to 0.05 beyond | up to 0.15 beyond |
| `saturation.min`, `saturation.max` | mean saturation against `style.saturation` | inside, or up to 0.05 beyond | up to 0.15 beyond |
| `lightDirection` | which way the shading gets brighter against `style.lightDirection` | within 45 degrees | within 90 degrees |
| `pixelArt.edges` | share of partly transparent pixels (`style.pixelArt`) | at most 1% | at most 5% |
| `pixelArt.colours` | distinct colours (`style.pixelArt`) | at most 64 | at most 256 |
| `palette.offShare` | share of pixels farther than 40 (2 for pixel art) from every colour of `style.palette` | at most 20% (0.1% pixel art) | at most 50% (2%) |
| `texelsPerUnit` | texture pixels per world unit, median of the scenes' uses, against `style.texelsPerUnit` | within 15% | within 35% |

Anything beyond the `warn` limit is `fail`. Style rules need the rule to be set in `style` (and `style.ignore` removes the
file); a rule the picture cannot answer is left out of the result (no silhouette, a light with no clear lean,
`texelsPerUnit` of a texture no scene draws). `fringe.bleed` does not mean the file is wrong:
a picture with black transparent pixels is normal, and it only shows as a dark line when the sprite is drawn with the smooth filter (set
`Sprite.pixelArt` true for pixel art). The edge pixels of a picture are those with alpha of at least 128 next to a pixel under 128. A sprite
sheet is measured in its cells, so the light does not mix frames.

With `paths` the result also has `set.rules`: `set.density` (the pixel density of the scenes' uses differs by more than 15%
between two pictures, warn above 50%), `set.pixelSize` (pixel art drawn with different pixel sizes), `set.outlineColour` and
`set.outlineWidth` (pictures with an outline that differ: the colour by more than 48, warn; the thickness by 1 px), and `set.paletteSpread` (the share of
pixels with a colour that no other picture has, within 24: ok up to 60%, warn up to 90%). Set rules are `warn` at most
(except density and the spread, which can be `fail`).

The picture has one row per asset, with numbered tiles listed in `assets[].tiles`: the picture on a checkerboard, its value
(greyscale on grey: is the shape readable without colour?), the picture over each background, and the picture at each
on-screen size (shrunk, then magnified by whole steps so you see what a player sees). The result has `assets[]` (`palette`
with the commonest colours, `measure`, `backgrounds`, `onScreen`, `scenes`, `rules`, `tiles`, `notes`), `set`, `style` (whether
rules were applied, and any `problems` found in `style`), `picture` and `nextSteps`. The rules are the very ones
`factoria validate` uses for the style, so a fix that clears one clears the other.

sky-hopper adopts it as the example: its `assets.json` `style` sets `texelsPerUnit` 1, `saturation` 0.3 to 0.9 and `ignore`s the two sheets that are baked at twice the size (`assets/crawler_sheet.png`,
`assets/parts_atlas.png`). Its art was not repainted, and `factoria validate` is clean.

### Reviewing art: assets.review

`assets.review {"path":"assets/hero.png","focus":"does the outline match the references?"}` (or `{"paths":[...]}`, up to 4 pictures
as a set) is the optional last look of the loop *make, preview, check, fix*: one call to a vision model, made by the AI that is
building the game (the user-only art critics of `ai.review` are a different, costlier thing). It is **grounded**: it first runs
`assets.check_art` on the same pictures, then sends the model the check's numbers (every rule with value, threshold, verdict and
hint), the `style` of `assets.json` as written, the `style.references` images (the first 3 that exist), the pictures (a file over
1 MB is shrunk to 1024 px on its long side) and the annotated picture of the check. The model is asked what numbers cannot say:
does it match the references and the style, does it read at its on-screen size, does it suit its use, are there artifacts.

Result: `verdict` (`good`, `fix` or `redo`; never `good` while the check has a `fail`), `summary`, `fixes` (each `{what, where,
command}`: the problem and the change, the picture and the part of it, and the command or `assets.json` setting to use), `checkArt`
(the check's verdict, counts, per-asset measures and rules), `role`, `provider`, `model`, `warnings` (a style reference that could
not be sent, a fix that names a command this engine does not have, a `good` overruled by the check) and `nextSteps`. It writes
nothing to the project.

It needs a model that accepts pictures. It uses the "fast" role of `ai.json` (the orchestrator when fast is off), because it is a
cheap one-shot question and the "artist" role is usually an image generator, not a viewer. API providers get the pictures as image
blocks (Anthropic) or `image_url` data URLs (OpenAI-compatible: OpenAI, Gemini, Ollama...); a CLI agent gets them inline or as
files in its empty work folder; a provider that only makes assets is refused. With no provider, no key or a text-only model it fails
with `no_model` or `review_failed` and a hint, and the loop goes on with `assets.check_art` alone. Call it once the check shows no
`fail`, not after every edit: each call is a paid request.

### The game icon without a provider: assets.draw_icon

A game made without an image provider still gets a real icon. `assets.draw_icon` draws one from a short description,
on the CPU (anti-aliased, the same bytes on every machine, no GPU, so it works headless and in CI), and writes the
1024x1024 icon plus the Android adaptive-icon foreground (432x432, transparent). They go where the export already looks:
`path` defaults to the `icon` of `factoria.json` (else `assets/icon.png`), `foreground` to
`export.android.adaptiveIcon.foreground` (else `assets/icon_fg.png`; `false` writes none). A path `factoria.json` does
not name yet is added to it. Provenance is recorded as `original`, not AI. Existing files are replaced, so change the
description and call again.

Drawing space: x and y run 0..100 across the icon, origin top-left, y down; every size and radius is in the same units
(shapes may reach past 0..100: the icon crops them). The foreground scales that 0..100 box into the 66/108 safe zone of the
adaptive layer, so nothing inside it is cut by a launcher mask. `background` is `color` (optional `colorBottom` for a
vertical gradient) and `shape`: `square` (the default: fills the canvas, what the stores want), `rounded`, `circle` or
`transparent`. `layers` are drawn in order:

| `type` | Fields |
|---|---|
| `rect` | `x`, `y` (top-left), `w`, `h` |
| `roundRect` | `x`, `y`, `w`, `h`, `radius` |
| `circle` | `x`, `y` (centre), `radius` |
| `ellipse` | `x`, `y` (centre), `rx`, `ry` |
| `polygon` | `points`: `[[x, y], ...]` |
| `text` | `text`, `x`, `y` (centre of the text), `size` (em height), `font` (a project `.ttf`; default DejaVu Sans), one line, no shaping |

Shapes take `fill` and/or `outline` (colours `"#rrggbb"`, `"#rrggbbaa"` or names), `fillBottom` (gradient from `fill`
at the top of the icon to this colour at the bottom), `outlineWidth` (default 2) and `softness` (feathers the edge: a
glow). Text takes `fill`. `"foreground": false` on a layer keeps it out of the Android foreground (a backdrop: the
adaptive icon has its own background colour, `export.android.adaptiveIcon.background`). Unknown keys and types are errors
with a JSON pointer and a suggestion.

```json
{"background": {"color": "#141428", "shape": "square"},
 "layers": [{"type": "circle", "x": 50, "y": 50, "radius": 30, "fill": "#ffcc44", "outline": "#ffffff"},
            {"type": "text", "text": "K", "x": 50, "y": 50, "size": 34, "fill": "#141428"}]}
```

Run it with `factoria call assets.draw_icon @tools/icon.json` (keep the JSON in the project) and look at the PNGs.
`examples/lantern-keep/tools/icon.json` draws a lantern this way.

### Store page images without a provider: assets.draw_capsules

`assets.draw_capsules` makes the images of the store pages (capsules, heroes, covers) from one piece of key art, at the size
each store asks for (the table is in [EXPORTING.md](EXPORTING.md#store-page-material), as of 2026-10). `keyArt` is an image
in the project, usually a screenshot taken natively large (`game.screenshot {scale: 1.5}`, or `factoria run --render-scale 1.5`).
It is cover-cropped around `focus` (`[x, y]`, fractions of the art; default the middle) and written to
`store/capsules/<store>/<name>_<w>x<h>.png` (`name` defaults to the project name; files are replaced; `overwrite: false`
keeps them). `stores` picks from `steam`, `epic`, `gog`, `microsoft`, `googleplay`, `appstore`, `itch` (default all).

The `logo` is `{"image": "assets/logo.png"}` (a PNG with a transparent background) or `{"text": "My Game", "font", "fill",
"outline"}`, the title drawn with the text rasterizer of `assets.draw_icon` (white with a dark outline by default;
`"outline": false` for none). Each asset has a rule for it: capsules and covers get it centred, Microsoft's posters and box art
in the upper part, heroes, page backgrounds and screenshots none, and Steam's library logo and Epic's logo are a transparent
PNG with only the logo (skipped when no logo is given). `orientation: "portrait"` turns the phone and tablet screenshot sizes
of Google Play and the App Store. The result lists every `written` file with its size.

```
factoria call assets.draw_capsules '{"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}'
```

## Recipes: make an asset again

The offline makers (`assets.rasterize_svg`, `assets.draw_icon`, `assets.draw_capsules`, `assets.generate_texture`,
`assets.synth_sound`, `assets.generate_loop`, `music.preview`, `music.render`, `assets.pack_atlas`, `assets.slice_sheet` and `image.bake`, which draws a
layered `*.image.json`, see [IMAGES.md](IMAGES.md), and `model.bake`, which builds a `*.model.json` into a `.glb`, see
[MODELING.md](MODELING.md)) write a `recipe` inside the
asset's `provenance`:

```json
"assets/art/coin.png": {"provenance": {"origin": "generated", "ai": true, "recipe": {
  "command": "assets.rasterize_svg",
  "args": {"path": "assets/art/coin.png", "source": "assets/art/coin.svg", "width": 128, "style": "paper", "seed": 0},
  "inputs": [{"path": "assets/art/coin.svg", "sha256": "9f2c..."}]}}}
```

`args` are the arguments that give the same bytes again: paths normalised and relative to the project, the seed written out
even when you left it at its default, a font named as the engine resolved it. `inputs` are the project files the command
read, each with the sha256 it had. Files that are only given inline (`svg` text, a built-in font) are inside `args`.
A recipe may also carry `context`: a setting that is not a file but changes the bytes. `music.preview` and `music.render` write
`context.styleMusicLufs` (the style guide's music loudness, or null) when the song's master loudness follows the style, and the asset is
stale when `style.audio.loudnessLufs.music` changes. `music.render` makes a group (the whole song and its stems) with one recipe; regenerating any
of them renders the group once (docs/MUSIC.md, "Rendering a song for a game").

- `assets.regenerate {"path": "assets/art/coin.png"}` runs the recipe again through the command registry with
  `overwrite: true` and reports per file `pixels changed`, `bytes changed (same pixels)`, `unchanged` or `created`, the
  size, and for sheets the layout before and after. `{"all": true}` does every asset with a recipe, `{"stale": true}` only
  those whose `inputs` no longer match (you edited the SVG), and `dryRun: true` lists what would run and changes nothing.
  There is no list of commands: any `assets.*` command that records a recipe works.
- An asset that reads another (a sheet sliced from a picture made from an SVG) is made after it, and `stale` looks again at
  its inputs when its turn comes, so the whole chain follows one edit. Several files made by one call (an icon and its
  foreground, a texture and its normal map, the capsules of a store) are made once. What a person recorded (license, author,
  notes) is kept; the recipe and the date are new.
- Provider-made assets (`assets.generate_image` and the other providers) have no recipe: they would cost money and give a
  different result. `assets.regenerate` on one is an error that says so.
- `assets.convert_audio` and the copy `assets.slice_sheet` writes with `out` do not inherit the recipe of their source: they
  describe another file. A sheet cut in place (no `out`) replaces its own source, so its recipe is removed (the source no
  longer exists to be read); a sheet cut with `out` from a source that has a provenance record records `assets.slice_sheet` with the source as input (a source with none gives a warning instead). `assets.pack_atlas`
  records the frames and `pivots.json` as inputs: a frame added to the folder later is not seen as a change, list it in
  `frames` and run the command again. `assets.set_provenance` keeps an existing recipe.
- `factoria validate` warns about a stale asset (`assets.json` pointer `/assets/<path>/provenance/recipe`, with the exact
  `factoria call assets.regenerate '{"path":"..."}'` in the hint) and about an input that no longer exists or cannot be
  read (restore it, or run the maker again with the new path).
- In the editor, the Project panel marks a stale made asset with a "stale" badge ("no src" when an input is gone), has a
  Regenerate button (the selected asset, else every stale one) and a Regenerate item in the right-click menu; when a
  source of a made asset is saved a banner offers Regenerate or Not now.

## Provenance and store disclosure

Every generated asset gets a `provenance` record in assets.json:

```json
"assets/hero.png": {"provenance": {
  "origin": "generated", "ai": true, "kind": "image", "provider": "openai", "model": "gpt-image-1",
  "prompt": "a knight, side view\n\nStyle: 16-bit pixel art", "references": ["assets/style/hero.png"],
  "license": "Output of the OpenAI API. Rights are set by OpenAI's terms: https://openai.com/policies/terms-of-use",
  "author": "factoria", "date": "2026-10-16"}}
```

`origin` is `generated` (an asset provider made it), `imported` (a file brought in) or `original` (made by hand); `ai` says
whether AI made the content; `kind` tells sound effects, music and voice apart; `license` is the provider's `license`
field in `ai.json`, or a note saying where its terms are (check them: commercial use often depends on your plan).

- `assets.provenance {"path": "assets/hero.png"}` shows one record; without `path` it lists all of them, how many are AI-made
  and the art, sound and model files under `assets/` that have no record yet.
- `assets.set_provenance` writes the record of a file the generate commands did not make: `{"path":
  "assets/music/theme.ogg", "origin": "imported", "ai": false, "license": "CC0", "source": "https://example.com/theme",
  "author": "A. Composer"}`. Use `ai: true` for a file made with AI elsewhere (a Suno track, a Midjourney picture). It
  replaces the whole record.
- The importers (`assets.import`) record their files the same way.

**Store disclosure.** Steam asks whether a game has AI-generated content, which part was made before release
("pre-generated") and which is made while the game runs ("live-generated"), and wants a description of both. Other stores
and platforms ask similar questions. `assets.disclosure` answers them from the records as Markdown: pre-generated content
by category (art and images, sound effects, music, voice, 3D models) with counts, providers and models; "live-generated:
none" (the engine generates nothing at run time; say so differently only if your own scripts call an AI service); the
terms recorded for each provider; and the art, sound and model files that have no record, which the answer cannot cover
until you record them with `assets.set_provenance`. `factoria export` writes the same text as `AI_CONTENT_DISCLOSURE.md` at
the top of the export folder whenever any asset has `ai: true`, and says so in `nextSteps`. It is for you to read and
paste into the store form, not part of the game; the store's current form is what counts.

The shipped `assets.json` does not carry provenance (exports keep the import settings only).

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
| `loopStart`, `loopEnd` | seconds, 0 or more; `loopEnd` after `loopStart` | none | Where a looping sound wraps: from `loopEnd` playback jumps back to `loopStart`, so what comes before `loopStart` plays once. Without them the whole sound loops. A sound with loop points is decoded whole, never streamed. The `loop` step of an audio document writes them (docs/SOUND.md, "Audio documents"). |
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
the page it came from as `sourceUrl` so the credits keep it. The websites the AI looks at when it needs such a file
(and whether it may look anywhere else) are the user's choice: **AI > AI Settings...** in the editor, `assetSources` in `ai.json`
([AI_PROVIDERS.md](AI_PROVIDERS.md), "Asset sources").

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
| `.ttf` `.otf` | Copied into `assets/fonts/`. A game that shows Chinese, Japanese, Korean or Arabic ships such a font (see [TEXT.md](TEXT.md)). |
| `.glb` `.gltf` | Copied into `assets/models/`, with the `.bin` buffers and images its `uri`s point at (the `.glb` carries its own data; only external files count), keeping their relative paths next to the model (`Textures/colormap.png` lands in `assets/models/Textures/`). Each copied file gets a provenance record. A missing buffer is an error, a missing image a warning. A file with the same name that is already there and identical is shared; a DIFFERENT image is kept, and the result warns (kits often ship different `colormap.png` files under one name), while a DIFFERENT buffer is an `exists` error (a model cannot load another one's geometry): import each kit into its own folder with `path` (`"assets/models/town/"`) or pass `overwrite`. `factoria validate` reports a model whose texture or buffer is missing. |
| `.aseprite` `.ase` | An image document (`<name>.image.json`) with the file's layers, cels, frames and tags, a cel PNG per layer and frame in `<name>.layers/`, and the sprite sheet baked from it with its `sheet` clips; `flat: true` makes only the PNG sheet (see Aseprite below). |
| `.psd` | A layered image document (`<name>.image.json`) with one PNG per layer in `<name>.layers/`, and the PNG baked from it (see PSD below). A file whose layers cannot be read imports its merged image as a PNG. |
| `.obj` (+ `.mtl`, textures) | A `.gltf` with its data embedded, plus the textures next to it. |
| `.fbx` | A `.glb`, converted by FBX2glTF or Blender (see below). |
| `.mpg` `.mpeg` | Copied into `assets/video/` after the engine opened it (it must be MPEG-1 video; the size, length and frame rate are in `details`). |
| `.mp4` `.m4v` `.mov` `.webm` `.mkv` `.avi` | An `.mpg` in `assets/video/`, converted by ffmpeg (see "Video" below). |

Not supported (the error says what to do instead): `.blend` (export glTF from Blender), `.webp` `.gif` `.psb`
(convert to PNG), `.svg` (`assets.rasterize_svg` makes the PNG), `.flac` `.m4a` `.aac` (convert to OGG or WAV), and SDF/MSDF font atlases.

Models do not have to be files: a script can build a mesh at run time with `mesh.create` and keep it as a `.glb` with
`mesh.save` (a plain `assets/models/` file after that; docs/SCRIPTING.md, "Procedural meshes"). `factoria validate` rejects a
`mesh:N` id written in a scene or prefab, because the mesh exists only in the running game.

### Aseprite

The file becomes an **image document** ([IMAGES.md](IMAGES.md), "Frames and tags"): `<name>.image.json` with the layers
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

A PSD (8 or 16 bit, RGB or grayscale) imports as a **layered image document** ([IMAGES.md](IMAGES.md)): `assets/<name>.image.json`
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
pl_mpeg; the `Video` component, [COMPONENTS.md](COMPONENTS.md)). `assets.import` of an `.mp4`, `.m4v`, `.mov`, `.webm`,
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
does not loop reaches its end; a studio intro that any button skips is in [MENUS.md](MENUS.md).

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
  whose PNG `assets.json` does not record as its bake, is a warning with the `image.bake` call ([IMAGES.md](IMAGES.md)).
- **Model documents.** A `*.model.json` that does not load is an error per issue, each with its JSON pointer and the fix;
  one never baked, or whose `.glb` `assets.json` does not record as its bake, is a warning with the `model.bake` call
  ([MODELING.md](MODELING.md)).
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

The shipped files are the ones the export includes ([EXPORTING.md](EXPORTING.md), "What is shipped").

`factoria export` warns, in the warnings of its result, about textures it could not compress (and ships them as PNG),
textures whose size is not a multiple of 4, textures too large for an atlas page and atlas groups it could not write.
None of them stops the export.
