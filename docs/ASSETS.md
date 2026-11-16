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

**Pages**

- [Assets: making them without a provider](assets/ASSETS_GENERATE.md): House style, sprite sheets, sounds, materials and SVG pictures.
- [Assets: animations written as code](assets/ASSETS_ANIMATE_SVG.md): assets.animate_svg: SVG animations baked into sprite sheets.
- [Assets: checking, choosing and store art](assets/ASSETS_REVIEW.md): Sheets, contact sheets, candidates, art checks, reviews, the icon and store capsules.
- [Assets: bringing files in](assets/ASSETS_IMPORT.md): Import settings, importing files and the checks.

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
`assetPricing` ([AI_PROVIDERS.md](ai-providers/AI_PROVIDERS_AGENT.md#asset-providers)), refuses a call that would pass `limits.maxAssetCostUsd`
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
  An asset that `{"stale": true}` leaves alone is listed in `skipped` with `reason: "up to date..."` and `compared`: the
  inputs it hashed now (`{path, sha256}`, the same hash the recipe recorded) and the style-guide values it compared, so
  an "up to date" answer shows what it looked at: only the files in the recipe's `inputs`, not any file the command could read.
  `compared` lists at most 8 entries and `comparedCount` is how many there are in all. An asset whose inputs no longer exist is
  in `failed` with code `missing_input`, `missingInputs` (the first 8 paths) and `missingCount`.
  `assets.check_mix` takes the loop points of a sound from assets.json `import.loopStart`/`loopEnd` first (a `loopEnd` past the
  end of the file is the end) and from a WAV's `smpl` chunk only as a fallback; the engine plays only the assets.json points.
  There is no list of commands: any `assets.*` command that records a recipe works, and so do `anim3d.generate` and
  `anim3d.retarget` (a clip's inputs are its rig, plus the source clip and the source rig for a retarget: a re-fit of the rig
  makes the clips stale). An edit of a clip (`anim3d.set_keys` and the other editing commands) removes its recipe, so
  regenerate never overwrites a hand edit; the record says so in its notes. `assets.set_provenance` takes the kind `anim3d`.
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
