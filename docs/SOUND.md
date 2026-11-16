# Sound patches (`*.sfx.json`) and audio documents (`*.audio.json`)

FactorIA has its own sound design tool. A **sound patch** is a small JSON file that describes a sound the way a
synthesizer does: layers of oscillators, envelopes, filters and effects. The engine renders it **offline** to a WAV
(or OGG) that sits next to it. No provider, no key, no other program, no cost, and the same patch gives the same bytes
on every platform. A patch is something an AI can read, diff and edit; the WAV is what the game plays.

- Format identifier: `factoria.sfx/1`. Schema: `schemas/sfx.schema.json` (`factoria docs read schemas/sfx.schema.json`).
- Files: `assets/**/name.sfx.json`, rendered to `name.wav` (or any path with `sfx.render {out}`).
- Commands: `sfx.preset`, `sfx.info`, `sfx.render`, `sfx.bake` (in [the patch format](sound/SOUND_PATCHES.md)). `assets.synth_sound` keeps working and is now a
  preset rendered through the same synthesizer.
- To change a recording or a render instead of making a sound from nothing (trim, fade, pitch, EQ, reverb, a seamless loop),
  see "Audio documents" ([SOUND_DOCUMENTS.md](sound/SOUND_DOCUMENTS.md)).

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

## Pages

- [The patch format](sound/SOUND_PATCHES.md): the format (layers, oscillators, pitch, envelopes, filters, effects, normalization), presets, commands, macros, variations, families and determinism of a sound patch.
- [Audio documents](sound/SOUND_DOCUMENTS.md): `*.audio.json`, a non-destructive chain of steps over a sound: the steps, loops, commands, baking and a worked example.
- [A sound at a place](sound/SOUND_SPATIAL.md): rolloff, cones, Doppler, occlusion and headphones (HRTF).
- [Voices, the Sound panel, the audio callback](sound/SOUND_MIXER.md): voice stealing, the Sound panel and, for engine developers, the real-time audio callback.
