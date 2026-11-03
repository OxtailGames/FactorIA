# Sound patches (`*.sfx.json`) and audio documents (`*.audio.json`)

FactorIA has its own sound design tool. A **sound patch** is a small JSON file that describes a sound the way a
synthesizer does: layers of oscillators, envelopes, filters and effects. The engine renders it **offline** to a WAV
(or OGG) that sits next to it. No provider, no key, no other program, no cost, and the same patch gives the same bytes
on every platform. A patch is something an AI can read, diff and edit; the WAV is what the game plays.

- Format identifier: `factoria.sfx/1`. Schema: `schemas/sfx.schema.json` (`factoria docs read schemas/sfx.schema.json`).
- Files: `assets/**/name.sfx.json`, rendered to `name.wav` (or any path with `sfx.render {out}`).
- Commands: `sfx.preset`, `sfx.info`, `sfx.render`, `sfx.bake` (below). `assets.synth_sound` keeps working and is now a
  preset rendered through the same synthesizer.
- To change a recording or a render instead of making a sound from nothing (trim, fade, pitch, EQ, reverb, a seamless loop),
  see "Audio documents" below.

The loop for a sound: **write the patch, `sfx.info` to check it, `sfx.render` to hear it** (the result has the numbers and a
picture of the sound), edit, render again. Start from a preset, not from nothing:

```
sfx.preset {"name":"coin","path":"assets/audio/coin.sfx.json"}     # writes the patch
sfx.render {"path":"assets/audio/coin.sfx.json"}                  # writes assets/audio/coin.wav, returns numbers and a picture
```

## A complete example

A short alarm: a square wave that steps through a chord, a filtered noise burst at the start, a little echo.

```json
{
  "format": "factoria.sfx/1",
  "doc": "Alarm: three-note rising arpeggio on a thin square wave, with a click of noise and a short echo.",
  "sampleRate": 44100,
  "length": 0.5,
  "tail": 0.3,
  "seed": 7,
  "layers": [
    {
      "name": "tone",
      "oscillators": [
        { "wave": "square", "duty": 0.25 },
        { "wave": "square", "duty": 0.25, "detune": 8, "gain": 0.6 }
      ],
      "pitch": { "note": "A4", "arpeggio": { "steps": [0, 4, 7], "rate": 12, "mode": "once" } },
      "amp": { "attack": 0.003, "decay": 0.3, "sustain": 0.4, "release": 0.12, "curve": 2 },
      "filter": { "mode": "lowpass", "cutoff": 1500, "resonance": 2, "env": { "amount": 2, "decay": 0.25, "sustain": 0 } }
    },
    {
      "name": "click",
      "length": 0.02,
      "gain": 0.5,
      "oscillators": [ { "wave": "noise", "color": "white" } ],
      "filter": { "mode": "highpass", "cutoff": 2500 },
      "amp": { "attack": 0, "decay": 0.02, "sustain": 0, "release": 0 }
    }
  ],
  "master": {
    "effects": [
      { "type": "delay", "time": 0.12, "feedback": 0.35, "tone": 3000, "mix": 0.3 },
      { "type": "reverb", "decay": 0.5, "mix": 0.15 }
    ],
    "normalize": { "mode": "lufs", "target": -18, "ceilingDb": -1 }
  }
}
```

## The format

Every key is optional unless it says required. Numbers have ranges; a value outside its range, a wrong type or a misspelled
key is an error that names the file, the JSON pointer (`/layers/1/filter/cutoff`), what is wrong and how to fix it, with a
"did you mean" for names. `sfx.info` lists **all** the problems of a patch in one call.

### The patch

| Key | Meaning |
|---|---|
| `format` (required) | Always `"factoria.sfx/1"`. |
| `doc` | What the sound is and when it plays. |
| `sampleRate` | 8000 to 96000, default 44100. |
| `length` | Seconds the note is held (0.001 to 30, default 0.5). Layers without their own `length` are held this long, then released. |
| `tail` | Extra seconds after `length` for releases, echoes and reverb to die away (default 0). `length + tail` is at most 30. The rendered file is `length + tail` long. |
| `seed` | Whole number, default 0. Picks the take of every noise. |
| `fadeOut` | Seconds at the very end that fade to silence so the sound never ends in a click (default 0.003, 0 turns it off). |
| `gain` | Linear gain of the mix of the layers before the master effects (default 1). |
| `layers` (required) | 1 to 16 layers. |
| `master` | `effects` (up to 8) applied to the mix of all layers, and `normalize`. |
| `macros` | Knobs by meaning (attack, brightness, weight, tail, pitch, grit, or your own). See "Macros". |
| `variations` | N takes of the sound that differ a little, for sounds that play often. See "Variations". |

### Layers

Layers play together. Each one has `name`, `start` (seconds from the start of the sound), `length` (seconds it is held before its
release; default: until the patch's `length`), `gain`, and:

- `oscillators` (required): 1 to 8, added together.
- `pitch`: the base pitch and how it moves.
- `amp`: the loudness envelope (default attack 0.002, sustain 1, release 0.01).
- `tremolo`: `{rate, depth}` a volume wobble.
- `filter`: `{mode, cutoff, resonance, keytrack, env}` on the layer.
- `effects`: up to 8, applied to this layer before it is mixed.

### Oscillators

| `wave` | What it is | Extra keys |
|---|---|---|
| `sine` | A pure tone. | |
| `square` | Hollow, chiptune. | `duty` 0.02 to 0.98 (0.5 plain; 0.25 or 0.125 thin and nasal). |
| `saw` | Bright, buzzy, rich in harmonics. | |
| `triangle` | Soft, flute-like. | |
| `noise` | Hiss, rain or rumble. Has no pitch. | `color`: `white` (bright), `pink` (rain-like), `brown` (deep rumble). |
| `table` | A wave you draw. | `table`: one cycle as 2 to 4096 numbers from -1 to 1, read with linear interpolation. |

Square and saw are band-limited (polyBLEP), so high notes do not alias; a triangle has so few harmonics that it hardly needs it, and a drawn table is read as it is (a sharp drawing aliases at high notes). While an oscillator is frequency-modulated its edges are not band-limited. Every oscillator also takes `ratio` (a multiple of
the layer's pitch: 2 is an octave up), `detune` (cents), `freq` (a fixed frequency in Hz that ignores the layer's pitch), `gain`
and `phase` (0 to 1). Noise ignores `ratio`, `detune`, `freq`, `phase` and `fm`.

- **`fm`**: frequency modulation. A modulator (`wave` sine/square/saw/triangle) at `ratio` times the oscillator's frequency (or a fixed `hz`)
  bends the oscillator's phase by `index` radians. Whole ratios sound harmonic, 1.4 or 3.5 bells and clangs. `indexEnv` is an envelope on
  the index, so a bell starts bright and goes mellow.
- **`ring`**: ring modulation. The oscillator is multiplied by a modulator at `ratio` or `hz`; `mix` 0 to 1.

### Pitch

`freq` in Hz or `note` (`"A4"`, `"C#3"`, `"Bb2"`; C4 is middle C, A4 is 440 Hz). Then any of:

- `sweep`: `{to | semitones, time, curve}` slides the pitch (`to` is a frequency in Hz, `semitones` a distance from the base). `curve` 1 is even, 3 jumps fast then settles (a laser zap).
- `env`: `{amount, attack, decay, sustain, release, curve}` an envelope that moves the pitch by `amount` semitones at its peak (the pitch drop of a kick).
- `vibrato`: `{rate, depth, delay}` rate in Hz, depth in cents, delay is a fade-in in seconds.
- `arpeggio`: `{steps, rate, mode}` semitone offsets stepped through `rate` times per second; `loop` repeats, `once` stays on the last.

### Envelopes

`{attack, decay, sustain, release, curve}`: seconds, seconds, a level from 0 to 1, seconds, and a shape. The note is held for the
layer's `length`, then the release starts. `curve` 1 is straight, 2 to 4 gives a punchy decay that falls fast first, below 1 the
opposite. A sound that dies away on its own wants `sustain` 0. Envelopes that move something (`pitch.env`, `filter.env`) also take `amount`.

### Filters

Layer filter: `{mode, cutoff, resonance, keytrack, env}`. `mode` is `lowpass` (muffles), `highpass` (thins) or `bandpass`; `cutoff` is in Hz;
`resonance` is Q (0.707 flat, 2 to 8 adds a whistle). `env.amount` is how many **octaves** the envelope opens the cutoff at its
peak: a wah or a laser's closing filter. The filter is a state-variable filter that stays stable and smooth while it moves.
`keytrack` (0 to 1, default 0) makes the cutoff follow the pitch when the patch is played at another note (`sfx.render` with `note`, an instrument of
a song): the cutoff is multiplied by the pitch ratio raised to `keytrack`, so 1 keeps a note as bright as the patch's own whatever its pitch and
0 keeps the cutoff where it is (a high note is then duller). The built-in instruments of songs (docs/MUSIC.md) use it.

### Effects

An effect is `{type, enabled?, ...}` in the `effects` of a layer or of `master`, applied in order. `enabled: false` turns it off
without deleting it.

| `type` | Keys | Notes |
|---|---|---|
| `filter` | `mode`, `cutoff`, `resonance`, `to` | Over the whole sound; `to` slides the cutoff there by the end. |
| `distortion` | `mode` soft/hard/fold, `drive` 1 to 100, `level`, `mix` | soft rounds peaks, hard clips, fold bends them back (metallic). |
| `bitcrush` | `bits` 1 to 16, `rate` Hz, `mix` | Lo-fi. `rate` holds samples; leave out to keep the patch's rate. |
| `delay` | `time`, `feedback` up to 0.95, `tone` (low-pass in the feedback, Hz), `mix` | `mix` is how loud the repeats are added to the dry sound, which always stays. |
| `reverb` | `decay` (RT60 seconds), `damping`, `size`, `preDelay`, `mix` | Freeverb-style. Give the patch a `tail` as long as the `decay`. `mix` is added to the dry sound. |

### Normalization

`master.normalize` is `{mode, target, ceilingDb}`:

- `lufs` (default, target -18): the gain is chosen so the integrated loudness (BS.1770 K-weighting, gated; the same measure as
  `assets.spectrogram` and `factoria validate`) reaches the target, but never so loud that the peak passes `ceilingDb` (default -1).
  Very short sounds can end up quieter than the target because of that ceiling.
- `peak`: the loudest sample reaches `target` dBFS (default -3).
- `none`: the level the layers add up to. Use it for instruments that other tools will level.

The output is clamped to -1..1; the WAV is 16-bit mono.

## Presets

`sfx.preset` lists the seventeen presets of `assets.synth_sound` as patches: `bark`, `growl`, `meow`, `screech`, `whoosh`, `explosion`,
`hit`, `coin`, `pickup`, `jump`, `powerup`, `laser`, `blip`, `click`, `error`, `splash`, `footstep`. They ship inside the binary.
`sfx.preset {"name":"laser"}` returns the exact JSON that renders; with `path` it writes it for you to edit.

## Commands

| Command | What it does |
|---|---|
| `sfx.preset {name?, path?, overwrite?}` | Lists the presets, returns one, or writes it to `path` (under `assets/`, ending in `.sfx.json`). |
| `sfx.info {path \| patch \| preset, seed?}` | Validates a patch and returns all its problems (pointer, message, fix) or its layers, effects, base pitch, whether its baked sound exists or is stale, and the loudness, peak and length it renders to. Writes nothing. |
| `sfx.render {path, out?, seed?, freq?, note?, length?, tail?, macros?, variant?, variants?, picture?, pictureOut?, width?, height?, overwrite?}` | Renders the patch to a mono 16-bit WAV (or Ogg Vorbis when `out` ends in `.ogg`). Returns `measurements` (`lufs`, `peakDb`, `seconds`, `centroidHz`, `riseSeconds`), `analysis` (the numbers of `assets.spectrogram` for the file as written) and the spectrogram picture (`$image`). |
| `sfx.bake {force?, dryRun?, macros?}` | Renders every patch of the project whose sound is missing or stale, and every variation of a patch that declares them. Leaves up-to-date sounds and files it did not make alone; lists patches with problems in `failed`. |
| `sfx.tweak {path, macros, absolute?, render?, seed?, picture?}` | Turns macros by meaning, writes them to the patch and renders again; returns the measurements before and after. |
| `sfx.edit {path, op, pointer, value?, index?, to?}` | Changes one field of a patch by JSON pointer: `set` a value, `remove` a field or array item, `add` an item to an array (at `index`, or the end) or `move` an array item to `to`. The patch is written only when the result still parses, so a mistake leaves the file as it was. The Sound panel's inspector runs it. |
| `sfx.family {from, names \| preset, out?, overwrite?, render?, picture?}` | Writes a set of interface sounds from one base patch and shows them in one picture. |

`seed`, `freq` / `note`, `length` and `tail` change one render without editing the patch: `seed` is added to the patch's seed
(another take of the noise), `freq` or `note` transposes the patch so its base pitch (the pitch of its first pitched layer)
becomes that, and `length` / `tail` replace the patch's. Oscillators with a fixed `freq` do not transpose.

### Baking, provenance and staleness

`sfx.render` writes the sound and records it in `assets.json`: provenance origin `original`, license CC0-1.0, and a **recipe**
(`sfx.render` with its arguments and the patch as an input with its SHA-256). That connects the sound to the rest of the
pipeline:

- `factoria validate` (and `project.validate`) warns when the patch changed after its sound was made; the hint is the `assets.regenerate`
  call that renders it again.
- `assets.regenerate` re-renders stale sounds from their recipes.
- `sfx.bake` renders every patch whose sound is missing or stale, so a project can be rebuilt after editing patches.

A WAV at the output path that `sfx.render` did not make is never replaced unless `overwrite` is true.

## Macros

A macro is a knob that moves several numbers of the patch at once, so a sound is changed by what it should be (brighter, longer)
and not by which cutoff to edit. The value goes from -1 to 1; 0 leaves the patch as written, so a patch without macros renders the
same bytes as before. The six built-in knobs work on any patch:

| Macro | Turned up | What it moves |
|---|---|---|
| `attack` | slower rise | every layer's `amp.attack` (each +0.25 doubles the attack time, each -0.25 halves it) |
| `brightness` | brighter | filter cutoffs, FM `index`, and an added treble stage (a lowpass when turned down, an exciter above 1.5 kHz when turned up) so a patch without filters changes too |
| `weight` | heavier, lower, with more low energy | transposes down (up to 5 semitones), lowers cutoffs and adds a low-frequency body |
| `tail` | longer | the patch `tail`, layer `amp.release` and reverb `decay` |
| `pitch` | higher | transposes up to one octave each way |
| `grit` | dirtier | adds soft distortion (turned up) or takes distortion and bitcrush away (turned down) |

Declare the starting position in the patch; a number, or an object with a strength and a doc:

```json
"macros": {
  "brightness": 0.2,
  "weight": { "value": 0, "strength": 1.5, "doc": "The thump of the hit." },
  "sparkle": { "value": 0, "doc": "More shimmer.",
               "binds": [ { "path": "/layers/1/gain", "min": 0.1, "max": 0.8 },
                          { "path": "/master/effects/0/mix", "min": 0.05, "max": 0.4, "curve": "exp" } ] }
}
```

`strength` (0 to 3) scales a built-in knob. A custom macro (any other name, lower case) must have `binds`: each bind sets the number
at the JSON pointer `path` to `min` at -1 and `max` at +1 (`curve` `linear` or `exp`); a bind that points at nothing is an
error. `sfx.render {macros: {brightness: 0.5}}` replaces the declared values for one render (kept in the recipe), and
`sfx.tweak` adds to them and writes the result into the patch. An unknown macro name is an error with a "did you mean".

`sfx.tweak {path, macros: {brightness: 0.2, tail: -0.3}}` is the loop for an AI: say what should change by meaning, read
`measurementsBefore` against `measurements` (`centroidHz` is the brightness, `riseSeconds` the time to reach 90% of the peak,
`seconds` the length) and the picture, and turn again.

## Variations

A sound that plays a hundred times a minute (a footstep, a hit) should not be the same file each time. Declare takes in the patch:

```json
"variations": { "count": 6, "seed": 1, "spread": { "pitch": 25, "length": 0.05, "gain": 1, "filter": 0.15, "noise": true } }
```

`count` is 2 to 64. Variant `n` draws its offsets from `seed` and `n` only, within `spread`: `pitch` cents (default 25), `length` as a
fraction of the sound (0.05), `gain` in dB (1), `filter` in octaves of cutoff (0.15) and `noise` (default true) to give it another
noise take. The same patch always draws the same variants.

- **Files.** `sfx.bake` (and `sfx.render {variants: true}`, which also returns one picture with a row per variant) writes
  `name_01.wav`, `name_02.wav` ... next to the patch (`name_001` from 100 variants). `sfx.render {variant: 3}` renders one. Each variant file
  has its own recipe, so a changed patch makes all of them stale together. `sfx.bake` writes `name.wav` too: the patch as written, without any
  spread.
- **In a scene.** `AudioSource.variants` (0 or 1 = one clip, 2 to 64) with `clip` `assets/audio/step.wav` plays `step_01.wav` to `step_NN.wav`, one
  per play, never the same twice in a row. The pick comes from a generator seeded from the world's random state, the entity and
  how many times it has played, so a seeded run picks the same variants, and gameplay random numbers are not used up.
- **In a script.** `audio.play("assets/audio/step.wav", {variants: 6})` picks with the world's seeded random numbers and avoids the last pick
  of that path; `audio.variantPath(path, n, count)` returns the file name of variant `n` (1-based).

## Families

`sfx.family {from, preset: "ui"}` makes the sounds of an interface from one base patch: `click`, `hover`, `confirm`, `cancel`, `error`,
`open`, `close`, `notify` (or `names: ["click", "confirm"]`). The patches are written to `out` (default: the base's path without
`.sfx.json` plus `_family`) as `click.sfx.json` ... and baked to `click.wav` ... with recipes.

Each member is a **copy** of the base with what its role changes, not a reference: it stands alone, and the base can be edited or deleted afterwards. The cost is
that editing the base does not change the members; run `sfx.family` again with `overwrite: true` to pass it on. What changes: the
length and tail, macro values added to the base's own (a hover is higher and brighter, an error lower, heavier and gritty), an
arpeggio (confirm up, cancel down, notify three notes) or a pitch slide (open up, close down, error down). Layer lengths are clamped to the
new length. Oscillators, filters, effects and variations are the base's, and the base's `master.normalize` goes to all of them,
so they share timbre and loudness; the result reports the loudness spread in LU. A base whose sound is shorter than the
members never reaches the loudness target through the peak ceiling: give it sustain.

Measurements are in every result: `lufs`, `peakDb`, `seconds`, `sampleRate`, and the character of the sound as `centroidHz` (the
spectral centroid, a brightness number) and `riseSeconds`. Families and variants return a contact sheet: one row per sound, a
waveform over a spectrogram, all on the same time scale so they compare at a glance.

## Determinism

The same patch and options give the same samples, bit for bit, on every platform and in Debug and Release. How:

- Rendering is done in `double` using only `+ - * / sqrt`, which IEEE 754 rounds identically everywhere. **No C library
  transcendentals**: sine, `exp2`, `log2` and `tanh` are the engine's own (`engine/audio/src/sfx_math.h`, polynomials accurate
  to about 1e-12). `sin`, `exp` and `pow` of glibc, Apple's libm and the MSVC runtime differ in the last bit, and a last-bit
  difference is audible in a hash.
- The engine builds with floating-point contraction off (`-ffp-contract=off`, `/fp:precise`), so `a*b+c` is never fused.
- Noise comes from splitmix64 seeded from the patch seed, the layer index and the oscillator index. There is no `rand()`.
- The loudness used to level the sound is measured in the same code, so the normalization gain is identical too.
- The WAV is 16-bit; the samples are rounded from 32-bit floats the same way everywhere.

The OGG path goes through the Vorbis encoder, which is deterministic for the same build of factoria but is not promised to be
the same across platforms; the WAV is the reference.

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
is decoded whole, not streamed.

### Commands

| Command | What it does |
|---|---|
| `audio.info {path?}` | Without arguments, the catalog of steps. With a `path` (or an inline `document`): validates the document and returns all its problems (pointer, message, fix), or its steps, the files it reads, whether its baked sound is fresh, missing or stale, and what it renders to. Writes nothing. |
| `audio.render {path, stopAfter?, seed?, compare?, picture?, pictureOut?, width?}` | Renders the chain without writing a sound. Returns `measurements` (`lufs`, `peakDb`, `seconds`, `centroidHz`, the `loop` points), the length and peak after each step and a picture (`$image`) of the source over the result. `stopAfter` stops at a step to hear the chain up to it. |
| `audio.bake {path?, force?, dryRun?, overwrite?}` | Bakes the document at `path`, or every document of the project whose sound is missing or stale. Leaves fresh sounds and files it did not make alone (`overwrite` replaces one). |
| `audio.create {path, source, steps?, seed?, output?, doc?, bake?, overwrite?}` | Writes a document (checked whole before it is written) and bakes it. |
| `audio.edit {path, op, ...}` | `op` is `add` (a `step` at `index`), `set` (`values` of step `index`; a null removes a field), `remove`, `move` (`index` to `to`) or `document` (`source`, `seed`, `output`). The result is checked whole before it is written, and the sound is baked again unless `bake` is false. |

### Baking, provenance and staleness

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

## The Sound panel

The editor's Sound panel (View > Sound, or a double click on a patch, an audio document or a recording in the Project panel) edits
the documents of this page: a waveform and a spectrogram of what the renderer makes, a knob for every macro, an inspector for every
field of the format (read from `schemas/sfx.schema.json`, so its tooltips are the descriptions above), presets, the variations side by
side with level-matched A/B listening, and the step chain of an audio document with draggable loop points. Each edit is one of the
commands above (`sfx.tweak`, `sfx.edit`, `sfx.preset`, `sfx.family`, `audio.edit`, `audio.create`) and one step of the editor's Undo; **Save + bake**
runs `sfx.render` or `audio.bake`. See [EDITOR.md](EDITOR.md), "Sound panel".

## For engine developers

The synthesizer is in `fa_audio` (`engine/audio/include/fa/audio/sfx.h`): `parse_sfx`, `load_sfx`, `render_sfx`, `stretch_sfx`,
`sfx_wav_bytes`, `sfx_presets`. It needs only `fa_core`, so the commands (in `tools/common`), the editor's Sound panel and the music
player (instruments are patches; notes are renders of them, possibly live while the game runs) call the same functions, and a
game ships `fa_audio` without the tooling modules. `SfxRenderOptions` carries what changes per render (seed, frequency, length,
velocity, normalization). `assets.synth_sound` renders a preset with `options.seed` and a pitch jitter of up to 10 percent from its seed.
