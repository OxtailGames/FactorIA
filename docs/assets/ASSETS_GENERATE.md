# Assets: making them without a provider

[Assets](../ASSETS.md) > Assets: making them without a provider

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
  [VECTOR.md](../VECTOR.md).
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
  `style` of `assets.json` (see "House style": outline width and colour, palette snapping), each returning a preview picture ([VECTOR.md](../VECTOR.md)).
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
