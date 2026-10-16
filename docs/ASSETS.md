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

Play a sound with an `AudioSource` (`clip`) or `audio.play(path)`; use a model as the `mesh` of a `MeshRenderer`.

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

<!-- Filled by the texture work: compression (KTX2 / Basis Universal), atlases. -->

### Audio

<!-- Filled by the audio work: streaming, loudness normalization, conversion. -->

## Importing files

<!-- Filled by the importers work: assets.import, Aseprite, PSD, OBJ, FBX, sprite-sheet slicing. -->

## Checks

<!-- Filled by each part: what `factoria validate` reports about assets (size, alpha, weight, loudness). -->
