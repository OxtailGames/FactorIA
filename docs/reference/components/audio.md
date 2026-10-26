[Back to the index](../README.md)

# Components: Audio

## AudioListener

The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the first camera drawn is used (the primary camera with the lowest depth: player one's in a split screen).

| Field | Type | Default | Description |
|---|---|---|---|
| `volume` | float | `1.0` | Master volume multiplier for everything this listener hears. Range 0.0..4.0. |

## AudioSource

Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.

| Field | Type | Default | Description |
|---|---|---|---|
| `clip` | asset (audio) | `""` | Project-relative path of the sound (.wav, .ogg, .mp3 or .qoa). |
| `volume` | float | `1.0` | Loudness multiplier, 0 (silent) to 1 (full). Range 0.0..1.0. |
| `pitch` | float | `1.0` | Playback speed multiplier; 2 = one octave higher and twice as fast. Range 0.05..8.0. |
| `loop` | bool | `false` | Restart the clip when it ends. |
| `playOnStart` | bool | `false` | Start playing when the entity spawns / the scene loads. |
| `playing` | bool | `false` | Runtime state: true while a voice is playing. Set true to play, false to stop. Runtime-only (not saved). |
| `spatial` | bool | `false` | true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI). |
| `range` | float | `800.0` | Spatial only: distance in world units where the volume reaches 0. Range 0.0..1000000.0. |

