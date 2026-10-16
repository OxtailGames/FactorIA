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

<!-- Filled by the importers work: assets.import, Aseprite, PSD, OBJ, FBX, sprite-sheet slicing. -->

## Checks

<!-- Filled by each part: what `factoria validate` reports about assets (size, alpha, weight, loudness). -->

- **Loudness** (every sound under `assets/` and every sound a scene or prefab names): a warning when the sample peak
  reaches 0 dBFS (within 0.1 dB: probably clipped), when the integrated loudness is above -9 LUFS (very loud) or below
  -35 LUFS (very quiet, or nothing audible), and when the sound effects (sounds of 10 seconds or less) differ by more than
  12 LU in how loud they play. The fix for most of them is `"normalize": true` in `defaults.audio`. `factoria validate`
  reuses the `analysis` records of `assets.json` while they are fresh and measures the other sounds on the spot; it
  never writes `assets.json` (run `assets.analyze_audio` to store the measurements, which makes validating fast).
  A sound that cannot be decoded is reported too.
