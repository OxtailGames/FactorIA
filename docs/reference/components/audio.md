[Back to the index](../README.md)

# Components: Audio

## AudioListener

The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the first camera drawn is used (the primary camera with the lowest depth: player one's in a split screen).

| Field | Type | Default | Description |
|---|---|---|---|
| `volume` | float | `1.0` | Master volume multiplier for everything this listener hears. Range 0.0..4.0. |
| `zoom` | float | `1.0` | Scales how far positional sounds are heard: a spatial AudioSource is silent at `range * zoom` from the listener (gain = 1 - distance / (range * zoom), and the pan spans the same distance), so 2 doubles the reach and 0.5 halves it. A game with a zoomable 2D camera sets it from the camera's orthoSize each frame. When the camera is the listener (no AudioListener component) the zoom is 1. Range 0.01..100.0. (since 0.3.0) |
| `spatialization` | enum: pan \| hrtf | `"pan"` | How spatial sounds are placed for the ears. pan (default): left/right pan and volume, for speakers. hrtf: a head model for headphones (time and level differences between the ears and the shadow of the head, from a parametric model with no recorded data; stereo clips are mixed to mono first). It needs this AudioListener entity (a 2D camera as the listener keeps pan) and a stereo output (a mono device and a surround one, 5.1 and more, keep pan). A change between pan and hrtf crossfades over 4 ms. See docs/sound/SOUND_SPATIAL.md, Headphones. (not released yet, on main after 0.29.1) |
| `headRadius` | float | `0.0875` | hrtf only: radius of the listener's head in world units (default 0.0875, a human head in meters; scale it with the world in a game that does not use meters). It sets the time difference between the ears (Woodworth: about 0.66 ms at 90 degrees for the default). A head smaller than 0.03 m or larger than 0.12 m at speedOfSound 343 (the ratio headRadius / speedOfSound is what counts) is clamped, with a warning that says how to fix it. Range 0.001..100000.0. (not released yet, on main after 0.29.1) |
| `speedOfSound` | float | `343.0` | Doppler only: the world units per second a sound travels at (default 343, meters per second in air). A 2D game in pixels sets it to the pixels per meter it uses times 343. The doppler shift of a source is its dopplerLevel as the exponent of the pitch ratio this speed gives. With hrtf it is also the speed the head model divides headRadius by to get the time between the ears. Range 1.0..10000000.0. (not released yet, on main after 0.29.1) |

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
| `range` | float | `800.0` | Spatial only: distance in world units where the volume reaches 0 (the sound is cut beyond it, whatever the rolloff). The AudioListener's zoom multiplies it. Range 0.0..1000000.0. |
| `rolloff` | enum: linear \| inverse \| exponential \| curve | `"linear"` | Spatial only: how the volume falls with the distance d from the listener (r = refDistance, k = rolloffFactor, d clamped to at least r). linear (default): 1 - k*(d-r)/(range-r), down to 0 at range; with the defaults it is 1 - d/range. inverse: r/(r + k*(d-r)), a loud close sound that fades slowly far away (like Web Audio and OpenAL). exponential: (d/r)^-k. inverse and exponential do not reach 0 by themselves: the sound is cut at `range`, so set `range` where they are already quiet. curve: the gain is `rolloffCurve` evaluated at d / range (0 = at the listener, 1 = at `range`). Same curves as audio.play({position, range, rolloff}). (since 0.23.0) |
| `refDistance` | float | `0.0` | Spatial only: the reference distance r in world units: up to it the sound is at full volume. 0 (default) = linear starts at 0 (the classic 1 - d/range), inverse and exponential use range / 20. A value at or above `range` is held just under it (99.9% of range), so linear drops to 0 right before `range`. Range 0.0..1000000.0. (since 0.23.0) |
| `rolloffFactor` | float | `1.0` | Spatial only: the curve parameter k (default 1): how fast the volume falls. For linear 1 reaches 0 at `range`, less leaves some volume there (cut at range anyway); for inverse and exponential higher = quieter far away. Range 0.0..100.0. (since 0.23.0) |
| `rolloffCurve` | json | `[]` | Spatial only, used when rolloff is "curve": the volume over the distance, as a curve of [position, gain] keys where position is the distance divided by `range` (0 = at the listener, 1 = at `range`, where the sound is cut anyway) and gain is 0 to 1: [[0, 1], [0.3, 0.8], [1, 0]]. Same form as ParticleEmitter.sizeCurve: {"keys": [...], "interp": "smooth"} eases between keys, at most 16 keys. [] (default) or a form that does not parse (the log says why) = the linear curve. refDistance and rolloffFactor do not apply to it. (not released yet, on main after 0.29.1) |
| `coneInnerAngle` | float | `360.0` | Spatial only: full angle in degrees of the cone around `coneAxis` where the sound is at full volume. 360 (default) = no cone, the sound is the same in every direction. The cone points where the entity faces (its rotation turns coneAxis), in 2D and 3D. Range 0.0..360.0. (not released yet, on main after 0.29.1) |
| `coneOuterAngle` | float | `360.0` | Spatial only: full angle in degrees of the outer cone: outside it the volume is multiplied by `coneOuterGain`; between the inner and the outer cone it blends linearly in the angle. 360 (default) with an inner angle below 360 blends all the way to straight behind. A value below coneInnerAngle is taken as coneInnerAngle. Range 0.0..360.0. (not released yet, on main after 0.29.1) |
| `coneOuterGain` | float | `0.0` | Spatial only: volume multiplier outside the outer cone, 0 (silent, default) to 1 (no effect). Range 0.0..1.0. (not released yet, on main after 0.29.1) |
| `coneAxis` | vec3 | `[0.0,0.0,-1.0]` | Spatial only: the direction the cone points in the entity's local space. Default (0, 0, -1) is forward in 3D (as lights and cameras); in a 2D game, where sprites face +X, use (1, 0, 0). A zero vector turns the cone off. (not released yet, on main after 0.29.1) |
| `dopplerLevel` | float | `0.0` | Spatial only: how much the pitch shifts with the speed the source and the listener approach or separate at (the AudioListener's speedOfSound). 0 (default) = off, 1 = the real shift, more exaggerates (it is the exponent of the real pitch ratio). The pitch factor is limited to 0.25..4 and glides over about 0.05 s. Velocities come from the change of each one's world position between frames (not from RigidBody), so scripted and animated movement shifts too; the first frame and a teleport give velocity 0. Range 0.0..10.0. (not released yet, on main after 0.29.1) |
| `occlusion` | bool | `false` | Spatial only: true = a physics ray from the listener to the source that hits a collider of `occlusionMask` muffles the sound (occlusionGain, occlusionLowpass). Default false. Each source is asked every 0.1 s, but at most 8 rays per frame go out in the whole game: with more sources than that the ones not asked yet come first, then the one asked longest ago, so none is left out for good. The change is smoothed over 0.1 s and the mixer ramps the volume and the low-pass to it (no click). (not released yet, on main after 0.29.1) |
| `occlusionMask` | int | `-1` | Spatial only: the physics layers (bitmask, -1 = all) whose colliders block the sound when `occlusion` is on. The source's own colliders, the listener's and triggers are ignored. (not released yet, on main after 0.29.1) |
| `occlusionGain` | float | `0.4` | Spatial only: volume multiplier while the path is blocked, 0 to 1 (default 0.4). Range 0.0..1.0. (not released yet, on main after 0.29.1) |
| `occlusionLowpass` | float | `1500.0` | Spatial only: low-pass cutoff in Hz while the path is blocked (default 1500; 20000 = no filtering): a wall makes a sound dull. The voice gets its own 12 dB/octave low-pass. Range 20.0..20000.0. (not released yet, on main after 0.29.1) |
| `priority` | int | `128` | Voice stealing, 0..255 (default 128): when all 64 voices play, a new sound replaces the voice of the lowest priority, the quietest of those, if its own priority is higher, or the same and it is louder; otherwise the new sound does not play (and `playing` goes back to false). Raise it for sounds that must be heard (dialogue, alarms), lower it for ambient detail. Range 0..255. (since 0.21.0) |

## MusicPlayer

Since 0.16.0.

Plays a song document (*.song.json, docs/MUSIC.md) as adaptive music. `intensity` (0..1) brings the song's layers in and out with smooth fades; goToSection, stingers and crossfades to another song wait for the next beat, bar or section end (`quantize`); beats, bars and sections reach scripts as events (music.beat, music.bar, music.section ...). `mode` picks how the song sounds: live (rendered from the document when the player starts, the same bytes as music.preview) or stems (the files music.render wrote, for phones). The musical clock is the mixer's sample count, so a headless run gives the same beats on every machine. Script API: entity.music (docs/SCRIPTING.md); docs/MUSIC.md, "Playing a song in a game".

| Field | Type | Default | Description |
|---|---|---|---|
| `song` | asset (music) | `""` | Project-relative path of the song document (*.song.json). Set it while playing to crossfade to the new song (crossfadeBars, quantize). |
| `mode` | enum: auto \| live \| stems | `"auto"` | How the song is played. live: the mixer renders the song's layers from the document when the player starts (no extra files, costs a few seconds of CPU once and the memory of the PCM). stems: plays the stem files music.render wrote (assets.json import.music), which start at once and cost no synthesis; long ogg stems stream from their encoded ogg in memory through a small window of decoded chunks instead of being decoded whole; it falls back to live, with a warning, when they are missing. auto: stems whenever the song has stem files and they are current, live when it has none or when the song was edited after music.render (live, with a warning, so the edit is heard; docs/MUSIC.md). |
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

