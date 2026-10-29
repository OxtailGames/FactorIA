# Assets: generate, import and ship

Art, sounds, music, voices and models get into a FactorIA game three ways, and every one of them is a command an AI can
call (MCP tool, `factoria call`, editor console):

1. **Generate** them with an asset provider (`assets.generate_image`, ...), configured like the LLM providers
   ([AI_PROVIDERS.md](AI_PROVIDERS.md)).
2. **Import** files made elsewhere (`assets.import`): Aseprite, PSD, OBJ, FBX...
3. **Write** them directly (`fs.write`), for files the engine already reads (PNG, JPG, WAV, OGG, MP3, glTF, TTF).
4. **Make** them offline, with no provider and no key: `assets.generate_texture` (materials), `assets.rasterize_svg`
   (pictures written as SVG), `assets.synth_sound`, `assets.generate_loop`, `assets.draw_icon`.

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
a warning), `overwrite` and `author` (the credit in the provenance; default `factoria`).

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

Consistent art comes from saying the same things every time, so assets.json keeps them in `style`:

```json
"style": {
  "prompt": "16-bit pixel art, black outline, flat colours",
  "references": ["assets/style/hero.png"],
  "palette": ["#1a1c2c", "#5d275d", "#b13e53", "#ef7d57"]
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
  art and a poor one for painted art.
- `style: false` in a call skips all three for that call.

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

`preset` is `paper`, `parchment`, `wood`, `planks`, `leather`, `fabric`, `stone`, the noises `value`, `fbm` and `cellular`,
and `gradient`, `radial` and `vignette`. The command description lists what each one is and its default colours. The
size is `width` x `height` (up to 2048; the height defaults to the width; 512 when neither is given). Options:

| Field | What it does |
|---|---|
| `color`, `accent` | Recolour the material: the main colour and the second one (shadow, late wood, creases, joints, the far end of a gradient). |
| `scale` | Size of the features, 0.1 to 10 (1 is the preset's natural size for the picture). |
| `roughness` | 0 smooth and even to 1 worn and uneven. |
| `tileable` | The picture repeats with no seam at its edges (the materials and the noises; `gradient`, `radial` and `vignette` ignore it and say so in `warnings`). |
| `vignette` | Darkens the edge with a ragged border (a worn page); 0.5 by default on `parchment`. Not used when tileable. |
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

- **Size.** The SVG is fitted inside `width` x `height`, aspect kept and centred; with only one of them the other follows
  the SVG's proportions; with neither, the size the SVG declares. Up to 4096. `background` puts it over a colour
  (transparent by default).
- **Supported.** `path` (every command), `rect` (with `rx` and `ry`), `circle`, `ellipse`, `line`, `polyline`,
  `polygon`, `g`, `defs`, `linearGradient` and `radialGradient` fills, `fill`, `stroke`, `stroke-width`,
  `stroke-linecap`, `stroke-linejoin`, `stroke-miterlimit`, `stroke-dasharray`, `fill-rule`, `opacity`, `fill-opacity`,
  `stroke-opacity`, `transform`, the `style` attribute, `viewBox` and `preserveAspectRatio`.
- **Not supported.** `text` and `tspan` (turn letters into paths, or put a `Text` entity in the scene), filters (blur,
  drop shadow), masks, clip paths, embedded images, `<use>`, patterns, markers and CSS classes in `<style>`. They are
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
| `.ttf` `.otf` | Copied into `assets/fonts/`. A game that shows Chinese, Japanese, Korean or Arabic ships such a font (see [TEXT.md](TEXT.md)). |
| `.glb` `.gltf` | Copied into `assets/models/`, with the `.bin` buffers and images its `uri`s point at (the `.glb` carries its own data; only external files count), keeping their relative paths next to the model (`Textures/colormap.png` lands in `assets/models/Textures/`). Each copied file gets a provenance record. A missing buffer is an error, a missing image a warning. A file with the same name that is already there and identical is shared; a DIFFERENT image is kept, and the result warns (kits often ship different `colormap.png` files under one name), while a DIFFERENT buffer is an `exists` error (a model cannot load another one's geometry): import each kit into its own folder with `path` (`"assets/models/town/"`) or pass `overwrite`. `factoria validate` reports a model whose texture or buffer is missing. |
| `.aseprite` `.ase` | A PNG sprite sheet plus its `sheet` entry (see below). |
| `.psd` | A PNG of the merged image. |
| `.obj` (+ `.mtl`, textures) | A `.gltf` with its data embedded, plus the textures next to it. |
| `.fbx` | A `.glb`, converted by FBX2glTF or Blender (see below). |
| `.mpg` `.mpeg` | Copied into `assets/video/` after the engine opened it (it must be MPEG-1 video; the size, length and frame rate are in `details`). |
| `.mp4` `.m4v` `.mov` `.webm` `.mkv` `.avi` | An `.mpg` in `assets/video/`, converted by ffmpeg (see "Video" below). |

Not supported (the error says what to do instead): `.blend` (export glTF from Blender), `.webp` `.gif` `.psb`
(convert to PNG), `.svg` (`assets.rasterize_svg` makes the PNG), `.flac` `.m4a` `.aac` (convert to OGG or WAV), and SDF/MSDF font atlases.

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
  12 LU in how loud they play. The levels are those of the sound as it plays: a sound whose effective import has `"normalize": true` (set in `defaults.audio` or on the sound) is judged with its gain applied (peak and LUFS after the gain), so a project that set it has no loudness warning left. The fix for most of them is `"normalize": true` in `defaults.audio`. `factoria validate`
  reuses the `analysis` records of `assets.json` while they are fresh and measures the other sounds on the spot; it
  never writes `assets.json` (run `assets.analyze_audio` to store the measurements, which makes validating fast).
  A sound that cannot be decoded is reported too.
- **Model files.** An error (not a warning) when a `.gltf` or `.glb` under `assets/` names a texture or a `.bin` buffer by a relative `uri` and the file is not there: the model would draw untextured or fail to load. `assets.import` copies those files.
- **Videos.** An error when a `Video` names a file under `assets/` that is not there, or when an `.mpg` the project uses cannot be
  played (not an MPEG file, or a different codec such as H.264 inside): the hint has the ffmpeg command that converts it.
- **Atlas groups.** A texture in an `atlas` group used by a component that cannot draw from an atlas (a `Tilemap`
  tileset, a `MeshRenderer` texture): the exported game would show the whole atlas image there. Remove the texture from
  the group, or use a copy of it.

The shipped files are the ones the export includes ([EXPORTING.md](EXPORTING.md), "What is shipped").

`factoria export` warns, in the warnings of its result, about textures it could not compress (and ships them as PNG),
textures whose size is not a multiple of 4, textures too large for an atlas page and atlas groups it could not write.
None of them stops the export.
