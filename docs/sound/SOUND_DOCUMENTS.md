# Sound: audio documents, page 2 of 4

Part of [Sound patches and audio documents](../SOUND.md) (the entry page lists every page).

## Audio documents (`*.audio.json`)

A sound patch makes a sound from nothing. An **audio document** works on a sound that already exists: a CC0 recording you
imported, a render of a patch, or another audio document. It is a chain of steps (trim, fade, pitch, EQ, reverb, loop and so
on) that the engine applies **offline** and writes next to the document as a WAV or OGG. The source is never touched, so the
chain stays editable: change a step, bake again. Same as a patch, the same document and the same source files give the same
samples, bit for bit, on every platform.

- Format identifier: `factoria.audio/1`. Schema: `schemas/audio.schema.json` (`factoria docs read schemas/audio.schema.json`).
- Files: `assets/**/name.audio.json`, baked to `name.wav` (or `name.ogg`, or the path in `output.path`).
- Commands: `audio.info`, `audio.render`, `audio.bake`, `audio.create`, `audio.edit` (below).

```json
{
  "format": "factoria.audio/1",
  "doc": "A heavier hit for the boss door.",
  "source": "assets/audio/hit.sfx.json",
  "steps": [
    { "type": "pitch", "semitones": -5 },
    { "type": "eq", "bands": [{ "type": "lowShelf", "freq": 120, "gainDb": 4 }] },
    { "type": "reverb", "mix": 0.2 },
    { "type": "normalize", "target": -14 }
  ]
}
```

| Field | Meaning |
|---|---|
| `source` | A project path: `.wav`, `.ogg`, `.mp3`, `.qoa`, an `.sfx.json` patch or another `.audio.json`. An object `{path, seed?, note?}` picks the take (`seed`) and transposes a patch so its root pitch is `note`. A document that layers itself, directly or through others, is an error. |
| `seed` | Picks the take of every random step (`granular`, an `.sfx.json` source). |
| `output` | `{format: wav \| ogg, channels: source \| mono, quality, path}`. `path` overrides where bake writes; it is required when the default path (the document's name with `.wav`) would be the source itself. |
| `steps` | Up to 64 steps, applied in order. Every step takes `enabled: false` to skip it and `doc` to say why it is there. |

A sound can be at most 120 seconds long at any point of the chain.

### The steps

`audio.info {}` returns this catalog with every field, its range and its default.

| Step | What it does | Fields |
|---|---|---|
| `trim` | Cuts the sound to a part: from `start` to `end` (or `length` after `start`), in seconds. | `start`, `end`, `length`, `auto`, `thresholdDb`, `padding` |
| `fade` | Fades the start in and/or the end out over `in` / `out` seconds. | `in`, `out`, `curve` |
| `normalize` | Sets the level: `mode` peak makes the loudest sample reach `target` dBFS (default -1); `mode` lufs makes the integrated loudness (BS.1770, the measure assets.check_mix uses) reach `target` LUFS (default -16) but never lets the peak pass `ceilingDb`. | `mode`, `target`, `ceilingDb` |
| `gain` | Multiplies the level by `db` decibels (negative is quieter). | `db` |
| `pitch` | Moves the pitch by `semitones` and keeps the duration (a time stretch and a resample, both written for this engine). | `semitones` |
| `stretch` | Changes the duration and keeps the pitch (WSOLA). | `factor`, `seconds` |
| `speed` | Plays the sound `factor` times as fast, so pitch and duration move together like a tape (2: half as long, an octave up). | `factor` |
| `eq` | An equalizer: low and high shelves, peaking bands and 12 dB/octave low-pass and high-pass filters (RBJ biquads). | `bands` |
| `filter` | A resonant low-pass, high-pass or band-pass (the synth's state-variable filter, 12 dB/octave); `to` slides the cutoff over the whole sound, `mix` blends it with the dry sound. | `mode`, `cutoff`, `resonance`, `to`, `mix` |
| `compressor` | Reduces the dynamic range: above `thresholdDb` the level rises only 1 dB for every `ratio` dB. | `thresholdDb`, `ratio`, `attack`, `release`, `kneeDb`, `makeupDb` |
| `distortion` | Waveshaping: `drive` into a `soft`, `hard` or `fold` curve, `level` after it, `mix` with the dry sound. | `mode`, `drive`, `level`, `mix` |
| `bitcrush` | Lo-fi: `bits` per sample, held at a lower `rate`, `mix` with the dry sound. | `bits`, `rate`, `mix` |
| `reverb` | Adds a room: the synth's reverb (eight damped combs and four all-passes). | `mix`, `decay`, `damping`, `size`, `preDelay`, `tail` |
| `delay` | An echo: the synth's feedback delay. | `time`, `feedback`, `mix`, `tone`, `tail` |
| `reverse` | Plays the sound backwards (a reverse cymbal, a suck-in before a hit). | (none) |
| `layer` | Mixes another sound over this one: `source` is a WAV/OGG, an .sfx.json patch or another .audio.json. | `source`, `offset`, `gainDb`, `semitones`, `seed`, `note` |
| `loop` | Makes the sound loop without a seam. | `start`, `end`, `crossfade`, `curve` |
| `granular` | Replaces the sound by a texture made of tiny grains of it (a rain from a click, a swarm from a vowel): each grain is `grainSize` seconds of the sound, Hann-windowed, and `density` grains start per second. | `length`, `grainSize`, `density`, `jitter`, `pitchSpread`, `scan`, `start`, `end`, `seed` |

The effect steps (`eq`, `filter`, `compressor`, `distortion`, `bitcrush`, `delay`, `reverb`) are also the effects of a song's mixer: a track, a bus
or the master of a `*.song.json` takes the same steps with the same fields (docs/MUSIC.md "The mixer").

`pitch` and `stretch` are WSOLA time stretching plus a windowed-sinc resampler, written for the engine. `reverb` and `delay` are the
synth's effects, so a patch and a document with the same settings sound the same. `normalize` with `mode: lufs` uses the
same BS.1770 measure as `assets.check_mix`.

### Loops

The `loop` step makes a loop without a seam: the last `crossfade` seconds of the body are mixed under its first ones, so the wave
carries on when playback wraps. The loop points are written to the baked file's import settings in `assets.json`
(`loopStart` and `loopEnd`, in seconds; docs/ASSETS.md), and a WAV also gets a `smpl` chunk with them. `AudioSource`, `audio.play` and
`audio.music` with loop on wrap inside those points: whatever comes before `loopStart` plays once as an intro. Only `gain` and
`normalize` may follow a `loop` step, because anything else would change the samples around the seam. A sound with loop points
is decoded whole, not streamed. `assets.check_mix` judges `loop_seam_slope` and `loop_seam_jump` of such a sound across those loop
points (the crossfade), not across the file's ends. It takes the points from assets.json (`import.loopStart`/`loopEnd`, a
`loopEnd` past the end of the file counts as the end, as the engine plays it) first and from the `smpl` chunk only as a fallback;
the engine itself never reads `smpl`, so a WAV that has the chunk but no import loop points is judged by its chunk while the
game plays it whole. It does not judge a recording that is only an input of an audio document's
recipe (it lists it under `skipped`).

A song gets its loop points the same way: `music.render` writes the `smpl` chunk and `import.loopStart`/`loopEnd` for the song's loop sections, and one stem file per layer with the same
points (docs/MUSIC.md, "Rendering a song for a game").

The `MusicPlayer` component plays a song document in a game: its layers by intensity, sections and stingers on the beat or the bar, crossfades between songs, and beat events for
scripts. It is summed into a bus (`music` by default) of this mixer (docs/MUSIC.md, "Playing a song in a game").

### Commands

| Command | What it does |
|---|---|
| `audio.info {path?}` | Without arguments, the catalog of steps. With a `path` (or an inline `document`): validates the document and returns all its problems (pointer, message, fix), or its steps, the files it reads, whether its baked sound is fresh, missing or stale, and what it renders to. Writes nothing. |
| `audio.render {path, stopAfter?, seed?, compare?, picture?, pictureOut?, width?}` | Renders the chain without writing a sound. Returns `measurements` (`lufs`, `peakDb`, `seconds`, `centroidHz`, the `loop` points), the length and peak after each step and a picture (`$image`) of the source over the result. `stopAfter` stops at a step to hear the chain up to it. |
| `audio.bake {path?, force?, dryRun?, overwrite?}` | Bakes the document at `path`, or every document of the project whose sound is missing or stale. Leaves fresh sounds and files it did not make alone (`overwrite` replaces one). |
| `audio.create {path, source, steps?, seed?, output?, doc?, bake?, overwrite?}` | Writes a document (checked whole before it is written) and bakes it. |
| `audio.edit {path, op, ...}` | `op` is `add` (a `step` at `index`), `set` (`values` of step `index`; a null removes a field), `remove`, `move` (`index` to `to`) or `document` (`source`, `seed`, `output`). The result is checked whole before it is written, and the sound is baked again unless `bake` is false. |

### Baking, provenance and staleness of an audio document

Baking records the sound in `assets.json` like an image document does: provenance origin `original` (the license of the input
files when they say one, CC0-1.0 otherwise; an AI-made input keeps the `ai` flag) and a **recipe**, `audio.bake`, whose inputs
are the document and **every file it read**: the source, the patches and the documents it layers. Edit any of them and:

- `factoria validate` (and `project.validate`) warns that the sound is stale, with the `assets.regenerate` call that rebuilds it;
- `audio.bake` and `assets.regenerate` rebuild it;
- `factoria export` bakes every missing or stale audio document before it packs the game.

A file at the output path that `audio.bake` did not make is never replaced unless `overwrite` is true.

### A worked example

These are the real results (trimmed) of a project with the `hit` preset written by `sfx.preset {"name":"hit","path":"assets/audio/hit.sfx.json"}`.

```
audio.create {"path":"assets/audio/thud.audio.json","source":"assets/audio/hit.sfx.json","doc":"A heavier hit for the boss door.",
  "steps":[{"type":"pitch","semitones":-7},{"type":"eq","bands":[{"type":"lowShelf","freq":120,"gainDb":4}]},
           {"type":"reverb","mix":0.2},{"type":"normalize","target":-14}]}
-> output assets/audio/thud.wav, measurements {seconds 1.68, lufs -28.0, peakDb -14.0, centroidHz 227.0}
   stepResults: pitch 0.18 s peak -6.5 | eq 0.18 s peak -4.5 | reverb 1.68 s peak -4.5 | normalize 1.68 s peak -14.0
   recipe: audio.bake, inputs thud.audio.json and hit.sfx.json
```

The reverb makes the hit 1.5 seconds longer, and the numbers say what each step did. Too much pitch drop; take it back to five semitones:

```
audio.edit {"path":"assets/audio/thud.audio.json","op":"set","index":0,"values":{"semitones":-5}}
-> measurements {seconds 1.68, lufs -27.6, peakDb -14.0, centroidHz 257.0}   (brighter, as the centroid says)

audio.info {"path":"assets/audio/thud.audio.json"}
-> valid true, bake {state "fresh", "'assets/audio/thud.wav' matches the document and the files it reads."}
```

Changing the patch the document reads makes the sound stale, without touching the document:

```
factoria validate
-> warning: assets.json#/assets/assets~1audio~1thud.wav/provenance/recipe: 'assets/audio/thud.wav' is stale:
   'assets/audio/hit.sfx.json' has changed since it was made by audio.bake. (hint: Make it again with: factoria call assets.regenerate ...)

audio.bake {}
-> baked ["assets/audio/thud.wav"]
```

And a loop from the `whoosh` preset (trim the silence, make the seam, set the level):

```
audio.create {"path":"assets/audio/wind_loop.audio.json","source":"assets/audio/wind.sfx.json",
  "steps":[{"type":"trim","auto":true},{"type":"loop","crossfade":0.1},{"type":"normalize","target":-18}]}
-> stepResults: trim 0.585 s | loop 0.485 s | normalize 0.485 s (peak -18.0)
   measurements.loop {startSeconds 0.0, endSeconds 0.4853}; assets.json import: loopStart 0.0, loopEnd 0.485306
audio.render {"path":"assets/audio/wind_loop.audio.json","stopAfter":0}
-> the chain up to the trim: 0.585 s, before the seam
```

