# Sound patches (`*.sfx.json`)

FactorIA has its own sound design tool. A **sound patch** is a small JSON file that describes a sound the way a
synthesizer does: layers of oscillators, envelopes, filters and effects. The engine renders it **offline** to a WAV
(or OGG) that sits next to it. No provider, no key, no other program, no cost, and the same patch gives the same bytes
on every platform. A patch is something an AI can read, diff and edit; the WAV is what the game plays.

- Format identifier: `factoria.sfx/1`. Schema: `schemas/sfx.schema.json` (`factoria docs read schemas/sfx.schema.json`).
- Files: `assets/**/name.sfx.json`, rendered to `name.wav` (or any path with `sfx.render {out}`).
- Commands: `sfx.preset`, `sfx.info`, `sfx.render`, `sfx.bake` (below). `assets.synth_sound` keeps working and is now a
  preset rendered through the same synthesizer.

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
| `macros` | Reserved for sound families (M55.2). Kept in the file, ignored by the renderer today. |

### Layers

Layers play together. Each one has `name`, `start` (seconds from the start of the sound), `length` (seconds it is held before its
release; default: until the patch's `length`), `gain`, and:

- `oscillators` (required): 1 to 8, added together.
- `pitch`: the base pitch and how it moves.
- `amp`: the loudness envelope (default attack 0.002, sustain 1, release 0.01).
- `tremolo`: `{rate, depth}` a volume wobble.
- `filter`: `{mode, cutoff, resonance, env}` on the layer.
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

Layer filter: `{mode, cutoff, resonance, env}`. `mode` is `lowpass` (muffles), `highpass` (thins) or `bandpass`; `cutoff` is in Hz;
`resonance` is Q (0.707 flat, 2 to 8 adds a whistle). `env.amount` is how many **octaves** the envelope opens the cutoff at its
peak: a wah or a laser's closing filter. The filter is a state-variable filter that stays stable and smooth while it moves.

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
| `sfx.render {path, out?, seed?, freq?, note?, length?, tail?, picture?, pictureOut?, width?, height?, overwrite?}` | Renders the patch to a mono 16-bit WAV (or Ogg Vorbis when `out` ends in `.ogg`). Returns `measurements` (`lufs`, `peakDb`, `seconds`), `analysis` (the numbers of `assets.spectrogram` for the file as written) and the spectrogram picture (`$image`). |
| `sfx.bake {force?, dryRun?}` | Renders every patch of the project whose sound is missing or stale. Leaves up-to-date sounds and files it did not make alone; lists patches with problems in `failed`. |

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

## For engine developers

The synthesizer is in `fa_audio` (`engine/audio/include/fa/audio/sfx.h`): `parse_sfx`, `load_sfx`, `render_sfx`, `stretch_sfx`,
`sfx_wav_bytes`, `sfx_presets`. It needs only `fa_core`, so the commands (in `tools/common`), the editor's Sound panel and the music
player (instruments are patches; notes are renders of them, possibly live while the game runs) call the same functions, and a
game ships `fa_audio` without the tooling modules. `SfxRenderOptions` carries what changes per render (seed, frequency, length,
velocity, normalization). `assets.synth_sound` renders a preset with `options.seed` and a pitch jitter of up to 10 percent from its seed.
