# Music: rendering and playing in a game

Part of [Music](../MUSIC.md): rendering a song for a game, the MusicPlayer component, live playing and stems, memory, hot reload.

## Rendering a song for a game

`music.render {"path":"assets/music/theme.song.json"}` renders the **whole song** to `theme.wav` (or `out`; `format` wav or ogg, `sampleRate`,
`seed`) and tells the game where it loops:

- **Loop.** The loop region is the song's `loop` sections, repeats included (the default song: its 8 bars from bar 5 are the loop, the intro plays
  once before it and the outro tail is folded onto the loop start, so the wrap has no seam). The points are written to the WAV's `smpl`
  chunk and to `assets.json` as `import.loopStart` and `import.loopEnd` in seconds, which the audio mixer honours; the exact frames (at 44100 Hz) are in the
  result (`loop.startFrame`, `loop.endFrame`, `loop.seamless`). A song with no `loop` section has no loop (`loop: null`), and `"loop": false` writes none.
- **Stems.** `stems` is `"layers"` (one file per layer; the default when the song has layers), `"tracks"` (one per track), `"buses"` (one per bus), `true` (layers, or tracks
  when there are none) or `false`. Each stem is rendered through the same buses and master as the mix, with the mix's gain, and has the same length and loop
  points, so the game starts them together and fades them by volume. A stem file is `<out without extension>.stem.<name>.<ext>`:
  `theme.stem.base.wav`, `theme.stem.rhythm.wav`...
- **Sum.** Stems carry the mix's gain and limiter gain and are not clamped, so the sum of all the stems equals the mix to within the 16-bit rounding (a few least
  significant bits; the result's `stemSum.errorDb` is below -80 dBFS) when the buses and the master are linear. A compressor, distortion or bitcrush on a bus or the
  master is not linear, so the sum is only approximate and `stemSum.exact` is false; the number says by how much.
- **Recipes.** The mix and every stem share one recipe whose inputs are the song, every `.sfx.json` and `.sf2` it reads and, when the master loudness is the style's, the
  style guide's music loudness (`recipe.context.styleMusicLufs`). Change any of them and `project.validate` warns and
  `assets.regenerate {"stale": true}` renders the whole group once. Running `music.render` again updates the entries in place, and deletes the stems of layers that no longer exist
  (reported as `removedStems`). A file that `music.render` did not make is never overwritten without `overwrite: true`.

The data the in-game player reads (it is in `assets.json`, under the asset's `import.music`):

```json
"assets/music/theme.wav": { "import": { "loopStart": 6.0, "loopEnd": 18.0, "music": {
  "role": "mix", "song": "assets/music/theme.song.json", "stemGrouping": "layers",
  "stems": [ { "name": "base", "path": "assets/music/theme.stem.base.wav", "kind": "layer", "intensity": 0, "tracks": ["pad","bass"], "buses": [] } ] } } },
"assets/music/theme.stem.base.wav": { "import": { "loopStart": 6.0, "loopEnd": 18.0, "music": {
  "role": "stem", "song": "assets/music/theme.song.json", "mix": "assets/music/theme.wav",
  "name": "base", "kind": "layer", "intensity": 0, "tracks": ["pad","bass"], "buses": [] } } }
```

`music.render` returns the same lists (`loop`, `stems`, `stemSum`) plus the measurements of the mix. Add `"stream": "auto" | "always" | "never"` to the mix's `music` block to choose
whether the stems stream ("Live and stems"); only `.ogg` stems (`format: "ogg"`) can.

## Playing a song in a game

A `MusicPlayer` component plays a song document as adaptive music. `scene.set_component {id, component: "MusicPlayer", fields: {song: "assets/music/theme.song.json"}}`
is the whole setup for music that starts with the scene; a script drives the rest with `entity.music` (docs/SCRIPTING.md) and tools with `audio.music_state` and
`audio.music`.

```json
{ "id": "theme", "components": { "MusicPlayer": {
    "song": "assets/music/theme.song.json", "mode": "auto", "bus": "music", "volume": 0.8,
    "intensity": 0, "quantize": "bar", "layerQuantize": "bar", "layerFade": 1.5 } } }
```

```js
const theme = world.find("theme").music;
theme.on("bar", (d) => { if (d.count % 4 === 0) spawnWave(); });   // d.frame is the audio frame, d.time seconds
theme.setIntensity(0.8);                                          // the layers fade in on the next bar line
theme.goToSection("boss", { quantize: "bar" });                   // jumps on the bar line with a short crossfade
theme.playStinger({ clip: "assets/sfx/hit.wav", quantize: "beat", duck: 0.5 });
theme.crossfadeTo("assets/music/calm.song.json", { quantize: "section", bars: 2 });
```

**Layers and intensity.** The song's layers ("Layers and stems") are the stems; each has a threshold, the layer's `intensity`. A layer is silent
below `threshold - layerRange`, full at its threshold and fades between (smoothstep); a layer at 0 always plays. A change of `intensity` takes effect
on the boundary of `layerQuantize` and each layer then fades over `layerFade` seconds. A song with no layers is one stem that always plays.
`entity.music.intensity` and `requestedIntensity` are the last value set (at once); `appliedIntensity` (and `status.intensity`) is the one the layers follow, which changes
on that boundary. The two differ in between: read `requestedIntensity` for what the script asked and `appliedIntensity` for what is audible.

**Sections.** The player knows the song's sections and the order of their passes (`sections`, `section`, `bar`, `beat` of the component and of
`entity.music`). `loop: true` stays in the song's loop sections (repeats included) until a section change or a stop; a song without a loop section
restarts at its end. `loop: false` plays through the outro to the end, then fires `music.ended` and `playing` becomes false. `startSection` is where it starts;
an unknown name logs an error that lists the song's sections and starts at the beginning (`goToSection` throws instead). `goToSection` jumps to the first pass of a section with an equal-power crossfade of
`transitionFade` seconds between where the music was and the new section. When the jump would land after the end of the loop (or of the song) it lands at the wrap.

**Quantize.** `none` is at once; `beat` is the next beat (a dotted quarter in 6/8, 9/8 and 12/8); `bar` the next bar line; `section` the end of the current
section pass. A request that arrives exactly on a boundary lands on it. A change that waits is queued in the mixer at an exact audio frame (`pending` in
`audio.music_state`); stopping waits too, but `playing` is false at once.

**Stingers.** `playStinger({clip})` plays an audio clip so that it starts on the boundary's audio frame, on the player's bus (or `bus`).
`playStinger({section})` plays a section of the song over the music with all its layers, then `tail` seconds of what rings after it.
`duck` (0..1) dips the music for the length of the clip or section (`duckHold` to say otherwise), over `duckAttack` seconds down and `duckRelease` seconds back.
A clip stinger is an ordinary voice: stopping the player does not stop it. It counts toward the 64 voices of the mixer with priority 192, above the default 128 of `audio.play` and `AudioSource`, so when all voices play it replaces a sound effect and is not replaced by one (docs/sound/SOUND_MIXER.md, "Voice stealing"); set `priority` 193..255 on an effect that must still win.

**Crossfades between songs.** Setting `MusicPlayer.song` while it plays, or `crossfadeTo(song)`, waits for the boundary of the song that plays, then the old song fades
out and the new one in over `crossfadeBars` bars **of the old song** (so the length follows its tempo); the new song keeps its own tempo. `crossfadeTo(song)` starts it at its
`section` or at its beginning, never at the component's `startSection` (that names a section of the first song, and the other song may not have it); setting the component's
`song` field starts it at `startSection`. `music.play(song)` is the hard start instead: what played is cut after a short fade. Both fail at once, with a hint, for a song file that does not exist.

**Where a change lands, and what waits.** `setIntensity`, `goToSection` and `crossfadeTo` return `{frame, time, quantize}`: the audio frame the change takes effect on (the
`frame` of the `section` or `crossfade` event it fires, and `time` = `frame` / the device rate) and the quantize it used. `frame` and `time` are `null` while nothing plays or the
song is still loading. The frame is worked out from the mixer's latest report: exact on the null device (headless runs and tests), which moves only with the game clock, and
within a few milliseconds with a sound device, which keeps playing between the report and the call. Until it lands, `status.pendingSong` and `status.pendingSection` (also
`audio.music_state`, and `entity.music.pendingSong` and `pendingSection`) name the song and section the next queued jump or crossfade goes to and `pendingAt` is its frame; all
three are `null` when nothing waits. A song asked for that the mixer does not have yet (still loading) shows its `pendingSong` with no `pendingAt`. While a crossfade is pending
`song` and `section` are still the audible ones, and the component's `song` field is already the new song. A player that is replaced by the next scene's one (a scene load) hands
the music it is playing over: the new player adopts it when it plays the same song, and **drops the changes the old one had queued** (a crossfade or section change that was
waiting for a bar line does not fire in the new scene). If the crossfade had already started, the new player adopts the song it was fading to. If the new scene wants another song,
it crossfades to it instead.

**Events.** A player sends game events: `music.ready` (`mode`), `music.beat` (`bar`, `beat`, `section`, `index`), `music.bar` (`bar`, `section`, `count`),
`music.section` (`section`, `pass`, `bar`), `music.loop` (`count`), `music.ended` (`stopped`), `music.stinger` (`kind`, `section`) and `music.crossfade`. Every
one carries `id` (the entity), `song`, `frame` (the audio frame it happened on) and `time` (`frame` / the device rate). `entity.music.on(name, fn)` listens to one
player; `world.on("music.beat", fn)` to all.

### Live and stems

`mode` says how the song becomes sound.

- **live**: when the player starts, the engine renders the song's layers from the document into memory (the same synthesis as `music.preview`; no extra files) and the
  audio thread only mixes those buffers. A song costs a few seconds of CPU once and about 10 MB of memory per minute per layer (16-bit stereo at 44100 Hz). A windowed
  game renders on a worker thread and starts the music when it is done (`ready` is false and `music.ready` has not come until then); a headless run (`factoria call`, tests)
  renders at once, so the music is there on the first frame. The renders are kept in a cache shared by the players (two players of one song render it once); when the cache passes
  128 MB the ones nothing plays are dropped, the least recently played first.
- **stems**: plays the stem files `music.render` wrote (`import.music` in `assets.json`, "Rendering a song for a game"). They start at once and cost no synthesis.
  A stem of 20 s or more that is an `.ogg` at 44100 Hz streams: the engine keeps its encoded file and a window of a few seconds of decoded audio, and the audio service thread
  fills the window ahead of the music (see "What the music costs in memory"); shorter stems, stems in another format and stems it cannot stream are decoded whole.
  Without stem files, or when a stem file is missing, the stems differ in length or are shorter than the song now is (it changed after `music.render`), the player renders live and logs a warning that says why.
- **auto** (default): stems whenever the song has stem files and they are current, on every device (a streamed stem costs a window, not 10 MB a minute, and there is nothing to render); live when it has none.
  The stems are current when the song file is the one `music.render` rendered them from: the mix entry records the song's sha256 (`provenance.recipe.inputs`) and `auto` compares it with the file when a player starts or fetches
  the song. A song edited since (even by a note that keeps its length) plays live, with one warning in the log ("run music.render"), and `activeMode` reads `live`; `music.render` makes the stems current again. `mode: "stems"` plays the files whatever the song says.
  Up to 0.22 a desktop rendered live even when stem files existed; set `mode: "live"` on the player to keep that. On a phone or tablet that is not high-tier, on any low-tier
  device and on the web (no worker thread to render on) a song without stem files still logs that auto would use stems there. `device_info()` (docs/MOBILE.md) and the
  `game.setDevice` override of a script (docs/SCRIPTING.md) still reach the choice. A player that is already running takes the new mode at its next beat
  (it crossfades to the other kind of render in the section that sounds); `mode: "stems"` or `"live"` is still the way to fix it in a scene.
- **Streaming rule and override.** `stream` in the `import.music` block of the song's mix entry (the one with `role: "mix"`; add it by hand, `music.render` keeps it when it renders again) says whether that song streams: `"auto"` (default: the stems of 20 s or more),
  `"always"` (every ogg stem, also a short one) or `"never"` (decode every stem whole). Another value logs a warning and is taken as `"auto"`. A stem that cannot stream (not `.ogg`, not 44100 Hz,
  more than 2 channels, unknown length, an undecodable tail) is decoded whole whatever the setting, and `"always"` logs why. Live mode never streams: it renders from the document.

Both are as loud as the song's master says. Stems carry the mix's gain, so the style guide's music loudness (`loudness: "style"`, "The mixer") is part of them; a live render
reads the same target (`audio.loudnessLufs.music` of the project's style guide in `assets.json`) when the master says `"style"`, so the two sound equally loud. A project with no
such target, `loudness: "off"` and a number behave the same in both. Everything else is the same bytes: the live render is the one `music.render` writes (the loop's tail folded onto its start, so the wrap is seamless; a song that ends with an
outro plays its tail out, or a 20 ms fade when more music follows the outro).

### What the music costs in memory

A stem decoded whole is 16-bit stereo at 44100 Hz: 176400 bytes per second, **10.1 MiB per minute per stem**. A streamed stem holds a window of 32 chunks of 8192 frames
(6 s of float stereo, 2 MiB), the decoder's scratch buffer and its encoded `.ogg` (typically well under 1 MiB a minute): about **2.5 to 3.5 MiB per stem, whatever its length**.
Every song played stays cached until the 128 MiB budget drops the ones nothing plays. All sizes here are binary (1 MiB = 1048576 bytes), as the `...MB` fields of `perf.measure`, `perf.profile` and the editor's Profiler panel.

| Song | Stems | One minute | Three minutes |
| --- | --- | --- | --- |
| one flat mix, whole (live, or stems under 20 s) | 1 | 10.1 MiB | 30.3 MiB |
| 4 layers, whole | 4 | 40.4 MiB | 121 MiB |
| 4 layers + mix stem, whole | 5 | 50.5 MiB | 152 MiB |
| 4 layers, streamed (stems) | 4 | about 10 to 14 MiB | about 10 to 14 MiB |
| 4 layers + mix stem, streamed | 5 | about 12 to 18 MiB | about 12 to 18 MiB |

(Sections are slices of the same stems, they add nothing.) Where to read it: `audio.music_state` has `cache` (per song: `song`, `mode`, `bytes`, `streamed`, `underruns`, and `stems` with each stem's `name`, `bytes` and `streamed`) and `cacheBytes`;
`game.state` has `audio.musicBytes`, `streamedSongs`, `musicUnderruns` and `musicUnderrunFrames`; `perf.profile` has `memory.*.musicMB` (the editor's Profiler panel shows it next to the audio total) and `perf.measure` the sample's `musicMB`, which are also part
of `audioDecodedMB`. A streamed stem counts its window, scratch and encoded bytes, not the whole song, and the number is constant for its life.
What `musicBytes` / `cacheBytes` count: the songs in the cache, the sources a player still plays after the cache let go of them (a song that changed on disk, until its crossfade ends) and the loads that finished but are not in the cache yet;
a load that is still decoding is not counted (its size is not known until it ends). `musicUnderruns` counts every streamed stem the cache ever took, also one that has left it. In `perf.measure`, `musicMB` is the largest value seen
after any frame; `audioDecodedMB` (clips, streaming buffers and music) is read every 8th frame and at the end, so a spike of a few frames in between can be missed.

How a streamed stem plays: the mixer reads only decoded chunks and never decodes, waits or allocates in its callback. Each time it publishes the music's state it also publishes, per stem, where it is
about to read (the playing position, the target of a queued section jump or crossfade, the loop's start). The **audio service thread** (one per audio device, started with it) reads that and decodes the
chunks 2.2 s ahead of each of those places, every 2 to 10 ms, so the music does not depend on the game thread: a long scene load, a breakpoint or a minimized window does not silence it. A section jump,
a loop wrap and a crossfade land on the same sample as with a whole song. The first chunks are decoded before the song plays, and the game decodes the target's first chunks before it sends a jump, stinger or
crossfade (if the service thread is decoding that stem at that moment, the game waits for the chunk it is on, a millisecond or so, never for the whole refill; so a jump with `quantize: "none"` never plays dry). That decode of two chunks per stem runs on the game thread: for Kindlewatch's night song (four stems) it took under 1 ms per jump on a laptop. The null device
(headless runs and tests) and the web decode a missing chunk on the spot in the mixer, so their output is the same on every machine. If a chunk is still missing when the real device needs it (a very slow disk or an overloaded machine), that stem plays silence for the frames it lacks (the music does not wait, so the other stems stay in time) and `underruns` / `musicUnderruns` / `musicUnderrunFrames` count it; it comes back in time once its chunks are decoded.

### Hot reload

While a game runs from the editor (or with `factoria run`), saving a `*.song.json` or a stem file of a song that plays from stems drops the renders of that song. Every
`MusicPlayer` that plays it fetches it again (in the background, as at the start) and crossfades to the new version at the next beat, in the section that is sounding; a section
the new version no longer has starts it at the beginning. The music editor's own edits do this too: the Music panel writes the song as you edit, so a running game hears the change.

### Time, determinism and the mixer

The musical clock is the mixer's frame counter, never the wall clock. The playhead moves `44100 / device rate` song frames per output frame; the beats, the quantized
changes and the events are placed at output frames computed from it, and the mix is split at each of those frames, so what lands where does not depend on the block
size, the threads or the machine. On the null device (headless runs, `game.step`, tests) the mixer advances exactly the time the game clock gives it, so a run puts the same
beat at the same `frame` every time (this is tested). On a sound device the clock follows the real audio position. Events reach scripts one game frame after they sound,
because the mixer queues them and `Audio::update` hands them over; `frame` and `time` say when they sounded.

The player is summed into its `bus` (default `music`): the bus volume, effects, ducking and snapshots apply, and `audio.stopAll()` stops the players with a 50 ms fade. The audio thread
allocates nothing for the player: the playheads, the queue of changes and the event ring are fixed-size.

### Lifetime

- `playOnStart` (default true) starts the player the first time the engine sees it; `playing = false` stops it with a 0.3 s fade; an inactive entity stops and does not restart by itself.
- A scene change fades the players of the old scene out over 0.5 s, unless the new scene has a player with the same song and `playOnStart`: that one takes over the music that
  plays, so the same song does not restart.
- A song that cannot be loaded (a file that is not a valid song, a render that fails) logs one error and shows it in `audio.music_state` (`error`); the player stays silent.

### Commands

| Command | What it does |
| --- | --- |
| `audio.music_state` | Every player (or one `entity`): song, mode, ready, playing, section, bar, beat, intensity and appliedIntensity (the one the layers follow: a change shows from its `layerQuantize` boundary on), requestedIntensity (the last one set), the gain of each layer, pending changes with `pendingSong`, `pendingSection` and `pendingAt`. Read-only. |
| `audio.music` | `action` play, stop, setIntensity, goToSection, playStinger or crossfadeTo with their arguments: the same calls as `entity.music`, to try the music while the game runs. `setIntensity`, `goToSection` and `crossfadeTo` also answer `change` (`{frame, time, quantize}`). |
