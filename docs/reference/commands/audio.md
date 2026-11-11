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

## `audio.music` (modifies state)

Since 0.16.0.

Drive a MusicPlayer: play, stop, setIntensity, goToSection, playStinger or crossfadeTo.

The same calls as `entity.music` in a script, for trying the music while the game runs (game.step, then audio.music_state). `action` picks the call and the other fields are its arguments: play {song?, section?, intensity?} starts at once; stop {quantize?, fade?} fades out on the boundary; setIntensity {intensity, quantize?} moves the layers; goToSection {section, quantize?, fade?} jumps on the boundary with a crossfade; playStinger {clip | section, quantize?, volume?, tail?, bus?, duck?, duckAttack?, duckHold?, duckRelease?} plays a short piece over the music; crossfadeTo {song, section?, quantize?, bars?} changes song on the boundary (from its beginning unless `section` is given). `quantize` is none, beat, bar or section; without it the player's own settings apply. A change that waits for a boundary is queued in the mixer (audio.music_state shows `pending`, `pendingSong`, `pendingSection` and `pendingAt`); setIntensity, goToSection and crossfadeTo answer `change`: {frame, time, quantize}, the audio frame it lands on (null before the song plays or while it loads). Example: audio.music {"entity":"music","action":"goToSection","section":"battle","quantize":"bar"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | yes | Entity with the MusicPlayer (id or name). |
| `action` | string ["play","stop","setIntensity","goToSection","playStinger","crossfadeTo"] | yes | The call to make. |
| `song` | string | no | play, crossfadeTo: the song (*.song.json). play without it uses the player's own. |
| `section` | string | no | play, crossfadeTo: the section to start at. goToSection, playStinger: the section to go to or to play as a stinger. |
| `intensity` | number | no | play, setIntensity: 0..1. |
| `quantize` | string ["none","beat","bar","section"] | no | When the change lands. Default: the player's quantize (layerQuantize for setIntensity). |
| `fade` | number | no | stop, goToSection: seconds of the fade. Default 0.3 for stop, the player's transitionFade for goToSection. |
| `bars` | number | no | crossfadeTo: bars of the old song the crossfade lasts. Default: the player's crossfadeBars. |
| `clip` | string | no | playStinger: an audio clip to play on the boundary. |
| `volume` | number | no | playStinger: volume on top of the player's. Default 1. |
| `tail` | number | no | playStinger with a section: seconds of what rings after it ends. Default 1.5. |
| `bus` | string | no | playStinger with a clip: the bus (default the player's). |
| `duck` | number | no | playStinger: how much the music dips while it plays (0 = not at all). Default 0. |
| `duckAttack` | number | no | playStinger: seconds to dip. Default 0.05. |
| `duckHold` | number | no | playStinger: seconds the dip lasts; omitted: the length of the clip or section. |
| `duckRelease` | number | no | playStinger: seconds to come back. Default 0.5. |

## `audio.music_state`

Since 0.16.0.

What the MusicPlayer components are doing: song, section, bar, beat, layers and pending changes.

Without `entity`: every player, including one still fading out after a scene change, as {mixedFrames, players: [{entity, song, mode, ready, playing, ended, section, bar, beat, positionSeconds, tempo, intensity, appliedIntensity, requestedIntensity, volume, bus, stems, stemGains, pending, pendingSong, pendingSection, pendingAt, heads, error}]}. With `entity`: that player only (`exists: false` when it has none). `song` and `section` are what is audible now; `pendingSong`, `pendingSection` and `pendingAt` (the audio frame, as in the events' `frame`) say where the next queued section change or crossfade lands (null when none waits). `intensity` = `appliedIntensity` is the value the layers follow (it changes on the layerQuantize boundary), `requestedIntensity` the last one asked for (the component's). `stemGains` is the gain each layer has now (it follows the intensity with the layer fade); `pending` counts the quantized changes waiting for their beat; `heads` is more than 1 while a section jump or crossfade is under way; `mixedFrames` is the musical clock (the frames the mixer has mixed). `cache` and `cacheBytes` are the memory of the music (docs/MUSIC.md, "What the music costs in memory"). Example: audio.music_state {"entity":"music"}

`cache` lists the songs the music cache holds, {song, mode, bytes, streamed, underruns, stems: [{name, bytes, streamed}]}, and `cacheBytes` adds them up: this is the memory of the music (also `musicBytes` in game.state's audio and `musicMB` in perf.profile / perf.measure). A stem with `streamed: true` plays from its encoded ogg (in memory) through a small window of decoded chunks, so its `bytes` are that window plus the encoded file, not the whole song decoded; `streamed` of a song says any of its stems is, and `underruns` (per song, all its stems together) counts the blocks in which a window was not ready (that stem played silence).

| Argument | Type | Required | Description |
|---|---|---|---|
| `entity` | string | no | Only this entity (id or name); it needs a MusicPlayer. |

## `audio.snapshot` (modifies state)

Since 0.3.0.

Apply a named mixer snapshot from factoria.json, or list the snapshots.

A snapshot is a named set of bus settings (volume scale, low-pass, reverb, ducking) from factoria.json "audio"."snapshots". Applying one moves every bus to the snapshot's state over `fade` seconds (default: the snapshot's own "fade", 0.5 when it has none): a bus the snapshot does not list goes back to neutral, so a snapshot is the whole picture and a snapshot with no buses is the way back. The volumes the player set are not touched. Without `name` it lists the snapshots and the one applied last. An unknown name fails with a "did you mean". Example: audio.snapshot {"name":"underwater","fade":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | The snapshot to apply; omit to list them. |
| `fade` | number | no | Seconds the move takes; default the snapshot's own. |

