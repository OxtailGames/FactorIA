[Back to the index](../README.md)

# Commands: audio

## `audio.bus` (modifies state)

Since 0.3.0.

Set a bus's volume and effects (low-pass, reverb, ducking), or read its state.

Buses are "sfx", "music", "ui", "master" (the master has no ducking) and the project's own (factoria.json "audio"."buses"). Every voice of a bus, and the buses declared under it, is summed into its own buffer; the effects run on that sum in this order: low-pass, reverb, volume, ducking. `volume` is the player's volume (what audio.setVolume sets); `lowpass` is a 12 dB per octave cutoff in Hz (0 or null = off); `reverb` is the wet mix 0..1 (0 = off); `duck` lowers the bus by `amount` (the fraction removed) while the bus `by` is louder than -40 dBFS, with `attack` and `release` time constants in seconds (63% of the way in that time; null = off). `fade` (seconds) makes volume, lowpass and reverb slide instead of jumping (a volume change always ramps over about 10 ms so it does not click). Only the keys you pass change; with just `bus` it returns the state. Returns volume, snapshotVolume, lowpass, reverb and duck. A bus with no effect does no effect work. Example: audio.bus {"bus":"music","lowpass":800,"fade":0.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `bus` | string | yes | The bus: sfx, music, ui, master or a bus of factoria.json audio.buses. |
| `volume` | number | no | The bus volume, 1 = as recorded. |
| `lowpass` | any | no | Low-pass cutoff in Hz; 0 or null = off. |
| `reverb` | number | no | Reverb wet mix; 0 = off. |
| `duck` | any | no | Ducking by another bus; null = off. |
| `fade` | number | no | Seconds volume, lowpass and reverb take to move. Default 0. |

## `audio.log`

List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.

Every play request is logged: audio.play and audio.music from scripts, AudioSource components and scene music (`music: true`; `layer` names the stem of audio.musicLayers), with `ok: false` when the clip failed to load. `frame`/`time` are the scene clock (time.frame / time.elapsed in scripts). Use it after game.step to check that a sound fired. `after` (a seq from a previous call) returns only newer entries; `path` keeps entries whose path equals it or ends with /<path>. Example: audio.log {"path":"jump.wav"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `path` | string | no | Only this clip: a project-relative path or a file name like "jump.wav". |
| `max` | integer | no | Return at most this many (the newest). Default 200. |

## `audio.snapshot` (modifies state)

Since 0.3.0.

Apply a named mixer snapshot from factoria.json, or list the snapshots.

A snapshot is a named set of bus settings (volume scale, low-pass, reverb, ducking) from factoria.json "audio"."snapshots". Applying one moves every bus to the snapshot's state over `fade` seconds (default: the snapshot's own "fade", 0.5 when it has none): a bus the snapshot does not list goes back to neutral, so a snapshot is the whole picture and a snapshot with no buses is the way back. The volumes the player set are not touched. Without `name` it lists the snapshots and the one applied last. An unknown name fails with a "did you mean". Example: audio.snapshot {"name":"underwater","fade":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | The snapshot to apply; omit to list them. |
| `fade` | number | no | Seconds the move takes; default the snapshot's own. |

