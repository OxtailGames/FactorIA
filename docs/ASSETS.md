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
(every GLES3 device samples it). A texture never fails because of its format: when the GPU takes none of them, or
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
- Only textures drawn by `Sprite` (with or without `region`), `SpriteAnimator` and `ParticleEmitter` can be packed. A
  `Tilemap` tileset or a `MeshRenderer` texture in a group would draw the whole atlas, so `factoria validate` warns.

### Audio

<!-- Filled by the audio work: streaming, loudness normalization, conversion. -->

## Importing files

<!-- Filled by the importers work: assets.import, Aseprite, PSD, OBJ, FBX, sprite-sheet slicing. -->

## Checks

<!-- Filled by each part: what `factoria validate` reports about assets (size, alpha, weight, loudness). -->

- Textures in an atlas group (`atlas` import setting) used by a component that cannot draw from an atlas (a `Tilemap`
  tileset, a `MeshRenderer` texture): `factoria validate` warns, because the exported game would show the whole atlas
  image there. Remove the texture from the group, or use a copy of it.
- `factoria export` warns, in the warnings of its result, about textures it could not compress (and ships them
  as PNG), textures whose size is not a multiple of 4, textures too large for an atlas page and atlas groups it could not
  write. None of them stops the export.
