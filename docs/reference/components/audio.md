[Back to the index](../README.md)

# Components: Audio

## AudioListener

The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the first camera drawn is used (the primary camera with the lowest depth: player one's in a split screen).

| Field | Type | Default | Description |
|---|---|---|---|
| `volume` | float | `1.0` | Master volume multiplier for everything this listener hears. Range 0.0..4.0. |
| `zoom` | float | `1.0` | Scales how far positional sounds are heard: a spatial AudioSource is silent at `range * zoom` from the listener (gain = 1 - distance / (range * zoom), and the pan spans the same distance), so 2 doubles the reach and 0.5 halves it. A game with a zoomable 2D camera sets it from the camera's orthoSize each frame. When the camera is the listener (no AudioListener component) the zoom is 1. Range 0.01..100.0. (since 0.3.0) |

## AudioSource

Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.

| Field | Type | Default | Description |
|---|---|---|---|
| `clip` | asset (audio) | `""` | Project-relative path of the sound (.wav, .ogg, .mp3 or .qoa). |
| `variants` | int | `0` | Number of baked variants of `clip` (0 = just the clip). With 2 to 64 every play picks one of clip_01 ... clip_NN ("assets/sfx/step.wav" plays assets/sfx/step_03.wav; sfx.bake writes them for a sound patch with `variations`), at random but never the one that played last on this entity, and the same on every run with the same seed: it reads the world RNG without consuming it. Range 0..64. (since 0.16.0) |
| `volume` | float | `1.0` | Loudness multiplier, 0 (silent) to 1 (full). Range 0.0..1.0. |
| `pitch` | float | `1.0` | Playback speed multiplier; 2 = one octave higher and twice as fast. Range 0.05..8.0. |
| `loop` | bool | `false` | Restart the clip when it ends. |
| `playOnStart` | bool | `false` | Start playing when the entity spawns / the scene loads. |
| `playing` | bool | `false` | Runtime state: true while a voice is playing. Set true to play, false to stop. Runtime-only (not saved). |
| `spatial` | bool | `false` | true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI). |
| `range` | float | `800.0` | Spatial only: distance in world units where the volume reaches 0. Range 0.0..1000000.0. |
| `priority` | int | `128` | Voice stealing, 0..255 (default 128): when all 64 voices play, a new sound replaces the voice of the lowest priority, the quietest of those, if its own priority is higher, or the same and it is louder; otherwise the new sound does not play (and `playing` goes back to false). Raise it for sounds that must be heard (dialogue, alarms), lower it for ambient detail. Range 0..255. (not released yet, on main after 0.20.0) |

## MusicPlayer

Since 0.16.0.

Plays a song document (*.song.json, docs/MUSIC.md) as adaptive music. `intensity` (0..1) brings the song's layers in and out with smooth fades; goToSection, stingers and crossfades to another song wait for the next beat, bar or section end (`quantize`); beats, bars and sections reach scripts as events (music.beat, music.bar, music.section ...). `mode` picks how the song sounds: live (rendered from the document when the player starts, the same bytes as music.preview) or stems (the files music.render wrote, for phones). The musical clock is the mixer's sample count, so a headless run gives the same beats on every machine. Script API: entity.music (docs/SCRIPTING.md); docs/MUSIC.md, "Playing a song in a game".

| Field | Type | Default | Description |
|---|---|---|---|
| `song` | asset (music) | `""` | Project-relative path of the song document (*.song.json). Set it while playing to crossfade to the new song (crossfadeBars, quantize). |
| `mode` | enum: auto \| live \| stems | `"auto"` | How the song is played. live: the mixer renders the song's layers from the document when the player starts (no extra files, costs a few seconds of CPU once and the memory of the PCM). stems: plays the stem files music.render wrote (assets.json import.music), which start at once and cost no synthesis; it falls back to live, with a warning, when they are missing. auto: stems on phones and tablets that are not high-tier, on any low-tier device and on the web, live elsewhere (docs/MUSIC.md). |
| `volume` | float | `0.8` | Loudness of the player, 0 (silent) to 1 (full). Changes fade over 20 ms. Range 0.0..1.0. |
| `bus` | string | `"music"` | Mixer bus the music is summed into: "music" (default), "sfx", "ui" or a bus of the project (factoria.json audio.buses). Its volume, effects and ducking apply. |
| `intensity` | float | `0.0` | 0..1: how much of the song plays. Each layer of the song has a threshold (music.edit set_layers); a layer is silent below threshold - layerRange and full from its threshold. The first layer (threshold 0) always plays. Range 0.0..1.0. |
| `playOnStart` | bool | `true` | Start playing when the entity spawns / the scene loads. |
| `loop` | bool | `true` | true: stay in the song's loop section (the loop sections, repeats included) until a section change or stop; a song without a loop section restarts at its end. false: play through the outro to the end, then music.ended. |
| `startSection` | string | `""` | Name of the section to start at ("" = the beginning of the song). An unknown name logs an error that lists the song's sections and starts at the beginning. |
| `quantize` | enum: none \| beat \| bar \| section | `"bar"` | When a section change, stinger or crossfade lands unless the call says otherwise. none: at once. beat: on the next beat (a dotted quarter in 6/8, 9/8, 12/8). bar: on the next bar line. section: when the current section pass ends (the loop wrap counts as the end of the loop). |
| `layerQuantize` | enum: none \| beat \| bar \| section | `"none"` | When a change of `intensity` starts its layer fades. none: at once. |
| `layerFade` | float | `1.0` | Seconds a layer takes to fade in or out when intensity changes. Range 0.0..30.0. |
| `layerRange` | float | `0.25` | How far below its threshold a layer starts to fade in (0.25: a layer with threshold 0.5 begins at 0.25 and is full at 0.5). 0 switches layers at their thresholds. Range 0.0..1.0. |
| `transitionFade` | float | `0.05` | Seconds of the equal-power crossfade between the old and the new position at a section jump. Range 0.0..5.0. |
| `crossfadeBars` | float | `2.0` | Length of the crossfade to another song, in bars of the outgoing song (so it follows its tempo). Range 0.0..64.0. |
| `playing` | bool | `false` | Runtime state: true while the song plays (or waits for its first section to land). Set true to play, false to stop. Runtime-only (not saved). |
| `ready` | bool | `false` | Runtime state: the song is rendered or loaded. False while a live render is still working (play waits for it). Runtime-only (not saved). |
| `section` | string | `""` | Runtime state: name of the section being played ("" when stopped). Runtime-only (not saved). |
| `bar` | int | `0` | Runtime state: bar of the song being played, 1-based (0 when stopped). Runtime-only (not saved). |
| `beat` | int | `0` | Runtime state: beat of the bar, 1-based (0 when stopped). Runtime-only (not saved). |
| `tempo` | float | `0.0` | Runtime state: quarter notes per minute of the song being played (0 when stopped). Runtime-only (not saved). |
| `activeMode` | string | `""` | Runtime state: "live" or "stems", what `mode` resolved to for the song being played. Runtime-only (not saved). |

