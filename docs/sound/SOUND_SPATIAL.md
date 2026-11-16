# Sound: a sound at a place, page 3 of 4

Part of [Sound patches and audio documents](../SOUND.md) (the entry page lists every page).

## A sound at a place

`audio.play(path, { position: [x, y, z], range, rolloff })` plays a one-shot as if it came from a point of the world, with no
entity: it uses what an `AudioSource` with `spatial: true` uses. The volume falls from `volume` at the
listener to 0 at `range` world units (default 800, the `AudioSource.range` default; the listener's `zoom` stretches it; the curve is `rolloff`, below), and the pan follows
the side of the listener's right axis the point is on (a point at half the range to the right pans fully right). The listener is the first active
`AudioListener`, else the primary camera. A 2D game gives `[x, y]` (or `{x, y}`). With no listener the sound plays at
`volume` and `pan` as given; a sound at or beyond the range plays nothing and `audio.play` returns 0 (a sound inside the range
that is silent, for instance with a muted listener, still plays and returns an id, as `audio.play` does without a position).
A `caption` of a sound that returns 0 for being out of range is not shown, unless you give `captionSeconds`. `volume` is the sound's
own volume (multiplied by the attenuation), `pan` is replaced by the computed one; `variants`, `pitch`, `bus` and `priority` work as always.
Position, volume and pan are computed once, when the sound starts: it does not follow the entity that made it (only its doppler pitch and
its occlusion keep following the listener, below). For a source that
moves, or a looping sound at a place, use an `AudioSource` with `spatial: true` (and `loop: true`): `audio.play` with a `position` and
`loop: true` throws, because the attenuation would stay frozen at the value of the start (and a sound out of range then would never play).
In C++ it is `Audio::play_at(world, clip, params, position, range, rolloff, refDistance, rolloffFactor)`, or `play_at(world, clip, params, position, SpatialSound)` for every option (game thread only: it reads the World).

### Rolloff

`rolloff` (`audio.play`) and `AudioSource.rolloff` choose how the volume falls with the distance `d` from the listener. The
names follow Web Audio's `distanceModel` and OpenAL: `refDistance` (r) is the distance up to which the sound is at full volume and
`rolloffFactor` (k, default 1) is how steep the curve is. `d` is taken as at least `r`.

| `rolloff` | gain | notes |
| --- | --- | --- |
| `"linear"` (default) | `1 - k * (d - r) / (range - r)` | with the defaults (`r` 0, `k` 1) it is `1 - d/range`, what the engine always did |
| `"inverse"` | `r / (r + k * (d - r))` | loud when close, long quiet tail; at `d = 2r` and `k = 1` it is 1/2 |
| `"exponential"` | `(d / r) ^ -k` | `k = 1` is the same as inverse at `r`; higher `k` falls faster |
| `"curve"` | `rolloffCurve` at `d / range` | a curve you draw, below |

`refDistance` 0 (the default) means 0 for `linear` and `range / 20` for `inverse` and `exponential` (they need a reference above 0).
A `refDistance` at or above `range` is held at 99.9% of `range`: the sound stays at full volume up to there and `linear` then drops to 0 just
before `range`. `inverse` and `exponential` never reach 0 by themselves, so every curve is cut at `range` (0 beyond it): choose a `range` where the
chosen curve is already quiet. The listener's `zoom` stretches `range` and `refDistance` together. The mixer applies the value
to the sound's volume, so it multiplies with `volume`, the bus and the listener's own `volume`.

```js
audio.play("assets/sfx/bell.wav", { position: [40, 0, 0], range: 400, rolloff: "inverse", refDistance: 20 });
```

### The curve rolloff

`rolloff: "curve"` takes the gain from a curve you draw: `AudioSource.rolloffCurve` (or `rolloffCurve` of `audio.play`) is a list of
`[position, gain]` keys, where `position` is the distance divided by `range` (0 at the listener, 1 at `range`) and `gain` is 0 to 1. It
is the form of `ParticleEmitter.sizeCurve` (`{"keys": [...], "interp": "smooth"}` eases, at most 16 keys). An empty curve is the linear curve. A curve in `AudioSource.rolloffCurve` that does
not parse falls back to linear (the log says why); `audio.play` throws for it instead, with the same message. `refDistance` and `rolloffFactor` do not apply, and the sound is cut at `range` as for the others.

```js
audio.play("assets/sfx/siren.wav", { position: [40, 0, 0], range: 400, rolloff: "curve", rolloffCurve: [[0, 1], [0.3, 0.8], [1, 0]] });
```

### Cones

A source can be louder in front. `coneInnerAngle` and `coneOuterAngle` are full angles in degrees (as in OpenAL and Web Audio): inside the inner cone
the volume is untouched, outside the outer cone it is multiplied by `coneOuterGain`, and between them it blends linearly in the angle. The defaults
(360, 360, 0) are no cone. `AudioSource.coneAxis` is the direction the cone points in the entity's local space, turned by the entity's rotation:
the default (0, 0, -1) is forward in 3D (as lights and cameras), use (1, 0, 0) for a 2D sprite that faces right. `audio.play` has no entity, so it takes
the world `direction` (the same `coneInnerAngle`, `coneOuterAngle` and `coneOuterGain`); without a `direction` the sound is the same in every direction.
The cone multiplies with the rolloff, and an `AudioSource` follows it as it turns; `audio.play` works it out once, when the sound starts.

### Doppler

A moving source or listener shifts the pitch: it rises as they approach and falls as they separate. `AudioSource.dopplerLevel` turns it on
(0, the default, is off; 1 is the real shift; up to 10 exaggerates), and `AudioListener.speedOfSound` is the world units per second sound
travels at (default 343, meters per second in air; a 2D game in pixels sets it to its pixels per meter times 343, or lower for a more audible effect).

- **Velocities are measured, not read.** The velocity of a source and of the listener is the change of its world position between two frames
  divided by the frame's time, so animated, scripted and physics-driven movement all shift the pitch (`RigidBody` is not read). The first frame
  of a source gives velocity 0, and so does a jump of more than 4 speeds of sound per second (a teleport, a respawn, another listener): no pitch
  jump. A sound that is not spatial, or a scene with no listener and no camera, has no doppler.
- **The shift.** With `u` the direction from the listener to the source and `c` the speed of sound, the real ratio is
  `(c + listener velocity along u) / (c + source velocity along u)` (each speed along `u` is limited to 0.9 `c`). `dopplerLevel` is the exponent
  of that ratio (0.5 half the shift in octaves, 2 twice). The factor is limited to 0.25..4 (two octaves each way), follows its target with a
  time constant of 0.05 s so the pitch glides, and multiplies the voice's `pitch`. With `dopplerLevel` 0 the pitch is exactly the one without doppler.
- **`audio.play` at a position** takes `velocity` (world units per second, `[x, y, z]`, `{x, y}`) and `dopplerLevel`. The place of a one-shot
  does not move, so the `velocity` you give is used for the whole life of the sound, and the listener's velocity is the one measured in each frame.

```js
// a car that drives past at 40 units per second: the pitch drops as it goes by
audio.play("assets/sfx/engine.wav", { position: [200, 0, 0], velocity: [-40, 0, 0], dopplerLevel: 1, range: 600 });
```

### Occlusion

A wall between the listener and a source makes the sound quieter and duller. `AudioSource.occlusion` turns it on; the others say how.

| Field | Meaning | Default |
| --- | --- | --- |
| `occlusion` | cast a ray from the listener to the source | off |
| `occlusionMask` | the physics layers (bitmask) whose colliders block | -1 (all) |
| `occlusionGain` | volume multiplier while blocked | 0.4 |
| `occlusionLowpass` | low-pass cutoff in Hz while blocked (20000 = no filter) | 1500 |

`audio.play` with a `position` takes the same names (`occlusion`, `occlusionMask`, `occlusionGain`, `occlusionLowpass`).

- **The ray.** It goes from the listener to the source, in the physics world: the 2D colliders (`Collider2D`) and the 3D ones (`Collider3D`) are
  both checked, so it works in a 2D or a 3D game. It ignores triggers, the source's own entity (and its children) and the listener's. A foreign
  collider that the listener stands inside does not block (the ray starts inside it). A source that stands inside a foreign collider (a
  floor or a room volume that is not the source's own entity or its child) is blocked by it, so keep such volumes out of `occlusionMask`. The ray is a straight line, so it does not model sound that goes around a corner.
- **The budget.** Rays cost time, so they are spread over frames: at most 8 rays per frame in the whole game (`audio.play` at a position uses
  them too), and each source asks again every 0.1 s. A source that was never measured goes first, and its first answer applies at once (a sound
  that starts behind a wall starts muffled). With more sources than the budget serves (about 48 at 60 frames per second) each one is checked a
  little less often than every 0.1 s; nothing is skipped for good.
- **The result is smooth.** When the answer changes, the volume and the cutoff move to the new state over 0.1 s, so there is no click. The volume
  is multiplied by `occlusionGain` and the voice goes through its own low-pass (two one-pole stages, 12 dB per octave) that moves from open to
  `occlusionLowpass`. A voice that is not occluded, or whose `occlusionLowpass` is 20000, is not filtered at all and sounds exactly as before.
- It needs physics bodies (`sync` runs every fixed step); colliders created in the same frame may be seen one frame later. A game that
  runs without physics never occludes.

Recipe: a guard that can be heard through a door.

```json
{ "id": "guard", "components": {
    "Transform": { "position": [320, 0, 0] },
    "AudioSource": { "clip": "assets/sfx/humming.wav", "loop": true, "playOnStart": true, "spatial": true, "range": 600,
                     "occlusion": true, "occlusionMask": 1, "occlusionGain": 0.3, "occlusionLowpass": 800 } } }
```

Put the walls on layer 0 (mask 1 is layer 0) and the sound dulls behind them and opens when the door is gone (disable its collider).

### Headphones

`AudioListener.spatialization` is `"pan"` (the default: left/right pan and volume, made for speakers) or `"hrtf"`: a model of a head for
headphones, where a sound to the right reaches the right ear earlier and louder and the left ear a little later, quieter and duller. Nothing else
changes: distance gain, cones, doppler and occlusion apply as with `"pan"`.

```json
{ "id": "ears", "components": { "Transform": {}, "AudioListener": { "spatialization": "hrtf", "headRadius": 0.0875 } } }
```

The model is written for this engine and uses no recorded data (no measured HRIR sets, no library). Its structure is the one of the
spherical-head model of C. P. Brown and R. O. Duda, "A structural model for binaural sound synthesis", IEEE Transactions on Speech and Audio
Processing 6(5), 1998, with the time difference of Woodworth (1938):

- **Time.** Each ear delays the sound by a fractional delay (a delay line of the voice with cubic interpolation). With `a` the head radius, `c`
  the speed of sound and `beta` the angle of the source from the median plane (0 straight ahead or behind, 90 degrees at the ear), the
  difference between the ears is `(a / c) (beta + sin beta)`: about 0.66 ms at 90 degrees for the default head.
- **Shadow.** Each ear filters the sound with a one-pole, one-zero filter that is flat at low frequencies. At high ones it boosts the sound up to
  6 dB when the source is straight in front of that ear's axis and cuts it down to 20 dB when the head is in the way, so the far ear is duller. A
  sound at 90 degrees is also 3 dB quieter in the far ear at every frequency.
- **Smooth.** The delay moves at most 0.03 samples per frame (a pitch change of 3% while it moves, so a fast fly-by is not clean but never clicks)
  and the shadow and level follow their targets over about 8 ms, whatever the block size. A sound that starts at a place starts at the right
  time and level.
- **Head size.** `headRadius` is in world units: `headRadius / speedOfSound` is the head's size in seconds, 0.000255 s for a human one. In a
  world of meters leave the default; in a 2D game in pixels set `speedOfSound` as for doppler and `headRadius` to `speedOfSound * 0.000255`. A
  head outside 0.03 to 0.12 m at 343 m/s (a ratio of 0.0000875 to 0.00035 s) is clamped, with a warning once that says so. A source nearer than the head's radius
  is pulled to the middle in proportion to its distance, so a sound at the listener's own position is in the middle.

What it does not do. There is no measured pinna: no elevation cue (a sound above and below sound the same), and a sound in front and its
mirror behind differ only by the shadow (what real heads do, front/back confusion included). The head is a sphere: no torso, no room, no
reverb. One head for everybody, so it will not be as convincing as a measured one for every listener. It is for headphones: on speakers use `"pan"`.

When it applies:

- Only to **spatial** sounds heard by an `AudioListener` entity with `spatialization: "hrtf"` (sounds that are not spatial, music and the
  interface are not placed), on an output device with two or more channels. A 2D camera as the listener (no `AudioListener`) and a mono output keep the pan.
- A **stereo clip** is mixed to mono (the mean of its channels) and placed as one source, since each channel would need its own place; its stereo image is lost.
  Use a mono clip for a sound at a place.
- A sound played at a place (`audio.play({ position })`) follows the listener's head, like a source in the scene.
- Switching `spatialization` back to `"pan"` puts the playing voices back to the pan within a few milliseconds.

Cost: one cubic read, one filter and two gains for each ear of a spatial voice; the mixer keeps no lock and allocates nothing.

