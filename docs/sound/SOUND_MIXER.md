# Sound: voice stealing, the Sound panel and the audio callback, page 4 of 4

Part of [Sound patches and audio documents](../SOUND.md) (the entry page lists every page).

## Voice stealing

At most 64 voices play at once: sounds, `audio.music` and its layers, a video's sound, a `MusicPlayer`'s clip stingers (a
`MusicPlayer`'s song plays in a transport of its own and takes no voice). When all 64 play, a new sound replaces the
voice with the **lowest priority**, the **quietest** of those (ties: the one started first), if the new sound has a higher
priority, or the same priority and is louder. Otherwise the new sound does not play: `audio.play` returns 0, `stats()` counts it
in `voicesRejected` and the log names the clip once. How long a voice has played never decides. A replaced voice ends like a
stopped one: its `onEnded` is called and `take_ended_voices` reports it; `stats()` counts it in `voicesStolen`.

- **Priority**: 0..255, default 128: `audio.play(path, { priority })` in a script, `AudioSource.priority` in a scene, `PlayParams::priority`
  in C++. Raise it for dialogue, alarms and the sounds the player must hear; lower it for ambient detail. Music (`audio.music`,
  `musicLayers`) has a priority above 255, so no sound ever replaces it; a video's sound and a `MusicPlayer`'s clip stinger
  have 192 (above the default effects, below what a game raises on purpose).
- **Loudness**: the voice's own volume times its clip's normalization gain and the volumes and snapshot scales of its bus and
  the buses above it (the values the game set, not a measurement of the output). Music fading out to its end (`stopMusic`
  with a fade, a replaced track) counts as silent.

Up to 0.20 a full mixer replaced the oldest sound that did not loop (else the oldest that was not music) and a new sound always played.

## The Sound panel

The editor's Sound panel (View > Sound, or a double click on a patch, an audio document or a recording in the Project panel) edits
the documents of this page: a waveform and a spectrogram of what the renderer makes, a knob for every macro, an inspector for every
field of the format (read from `schemas/sfx.schema.json`, so its tooltips are the descriptions above), presets, the variations side by
side with level-matched A/B listening, and the step chain of an audio document with draggable loop points. Each edit is one of the
commands above (`sfx.tweak`, `sfx.edit`, `sfx.preset`, `sfx.family`, `audio.edit`, `audio.create`) and one step of the editor's Undo; **Save + bake**
runs `sfx.render` or `audio.bake`. See [EDITOR.md](../EDITOR.md), "Sound panel".

## For engine developers

The synthesizer is in `fa_audio` (`engine/audio/include/fa/audio/sfx.h`): `parse_sfx`, `load_sfx`, `render_sfx`, `stretch_sfx`,
`sfx_wav_bytes`, `sfx_presets`. It needs only `fa_core`, so the commands (in `tools/common`), the editor's Sound panel and the music
player (instruments are patches; notes are renders of them, possibly live while the game runs) call the same functions, and a
game ships `fa_audio` without the tooling modules. `SfxRenderOptions` carries what changes per render (seed, frequency, length,
velocity, normalization). `assets.synth_sound` renders a preset with `options.seed` and a pitch jitter of up to 10 percent from its seed.

### The audio callback

The device callback (`Mixer::render`, `engine/audio/src/audio_mixer.h`) takes no lock, allocates nothing and frees nothing. The
game thread and the callback share only bounded single-producer single-consumer queues (`audio_rings.h`) and a few atomics, and
each memory ordering is explained where it is used:

- **Commands, game to mixer.** Every `Audio` call that changes what plays becomes a command made on the game thread: a play or a
  stop, a voice's volume, pitch, pan, low-pass (occlusion) or bus, a bus volume, effect or ducking, a snapshot, a new bus table, a music transport
  change, the recorder. The commands of one call are committed together, so the mixer applies them in the same block. The ring
  holds 2048. When the callback falls behind, the rest wait on the game side in a staging queue of at most 8192; past that the
  oldest play or voice setting is dropped, then the oldest bus or music setting. Stops, removals, music starts, bus table swaps
  and the recorder are never dropped (they end or free something the game waits for). A dropped play ends its voice on the
  game side, so `onEnded` and `take_ended_voices` still report it. `stats()` counts `commandsDropped` (plays and voice settings)
  and `settingsDropped` (bus and music settings), and the log says it once.
  - **A dropped setting is not lost.** The game keeps its own copy of every voice, bus and `MusicPlayer` setting (what a query
    answers). When a command that set a voice's volume, pitch, pan or bus, or a bus's volume, effect, ducking or snapshot scale,
    or a player's volume, loop, layers, intensity or bus is dropped, that voice, bus or player is marked (a bus by its name, so
    a bus table swap while the queue waits does not make it resend another bus; a bus the swap removed is skipped), and once the
    staging queue is down to half (4096) its current state is sent again, so the mixer ends up where the game believes it is.
    A player whose entity is gone and that fades out gets the last values it was sent. A resent intensity uses the
    component's `layerQuantize` of that moment. What does not come back is an event that happened once: a dropped play (the
    voice ends), a section jump or a section stinger. **A resent state jumps**: it is applied at once, with no ramp, so a long
    fade that was dropped (a volume fade, a snapshot fade) becomes a step to its target, and a fade that was running when the
    stall began is not continued.
  - **Repeated Keep commands merge.** While more than 1024 commands wait, a pause, a reset of the bus effects, a stop of every
    sound or a retune of the playing music (`audio.music` again with the same track) replaces an earlier one still waiting (a
    game that calls `setPaused` or `audio.music` every frame during a long stall does not pile them up); `stats()` counts
    them in `commandsCoalesced`. It is a count of waiting commands, not a time. Bus table swaps do not merge (each is built
    from the one before), and a stop of one voice or a removal is never dropped or merged away: if more than 32768 commands
    that must stay are waiting, the log says so once and they are all kept.
- **Returns, mixer to game.** A ring of 4096: the commands the mixer applied, which the game frees with what they carried back
  (an old bus table, a removed music transport, the last reference to a clip), and the voices that ended. The mixer applies a
  command only while the returns have room for everything it can give back, so nothing is lost there; a command that does not
  fit waits for the next block.
- **Streamed voices.** A clip that streams (`"stream"` in assets.json, docs/ASSETS.md) keeps a ring of decoded frames: 12288
  frames (279 ms at 44.1 kHz) for a sound, one second when it plays as music (`play_music` and its layers). The first 4096
  frames are decoded on the game thread when the voice starts; after that the game hands a decode job (`fa::jobs`, `audio.stream`) every frame to each
  ring with room for at least 2048. A ring that runs dry is an **underrun**: the voice plays silence for the rest of the block
  and waits where it is (no frame is skipped), the callback never waits for the decoder, and `stats()` counts `underruns` (one per
  voice and block) and `underrunFrames`. Only a game thread that stalls for longer than a ring lasts underruns.
- **Streamed music.** A stem of a song that plays from stem files (docs/MUSIC.md, "Live and stems") streams when it is an `.ogg`
  of 20 s or more at 44.1 kHz (`import.music.stream` overrides). It keeps a window of 32 chunks of 8192 frames (6 s) in 32 slots with
  an atomic state each, shared by every head of the transport (the playing section, a section jump or a crossfade under way, a layer
  fading in). The callback only pins a chunk, reads it and unpins it; it never decodes, waits or allocates. Each time it publishes the
  transport's state it publishes, per stem (`MusicStemStream::publish_head`, relaxed atomics, no allocation), where that stem will read
  (the position and, for a queued jump or crossfade, its target and the loop's start). The **music service thread** (`Impl::MusicService`
  in audio.cpp, started by `init()` with a real device, joined by `shutdown()`) reads that every 2 ms while a chunk is missing and 10 ms
  otherwise, takes the stem's claim, turns the heads into the chunks to keep (4 urgent and 12 ahead per head) and decodes the missing ones;
  the farthest chunk is the one evicted. It needs neither the API lock nor a call of the game, so a game thread that stalls (a long scene
  load, a breakpoint, a minimized window) does not dry the music, only a service thread that cannot run does. A chunk is a decode from a seek in
  the ogg, exact to the sample. The first chunks are decoded on the thread that loads the song, and on the game thread when it plays or is told to
  jump (`music_prime`, which waits for the claim for the time of one chunk when the service thread is decoding the stem: the decoder gives the
  claim up between chunks when somebody waits for it, 500 ms safety net). A chunk still missing when the callback needs
  it plays silence for that stem and block and counts an **underrun** per stem and block (`musicUnderruns`, `musicUnderrunFrames`, also
  inside `underruns` / `underrunFrames`); the song's clock does not wait, so every other stem stays in time and the dry one comes back in time once its chunks are decoded. On the null device and the web the
  mixer decodes the missing chunk itself (there is no service thread), so a headless run is the same on every machine.
- **Music players.** Each `MusicPlayer` has its transport in the mixer (64 at most at once). The game reads the transport's
  state from a triple buffer (the newest whole copy) and its events from a ring of 2048 that the transport fills only as far as
  it has room: events are delayed, never dropped. `music_status` and the component's runtime fields are at most a block behind.
- **PCM voices and the recorder.** A video's sound and the editor's previews feed a ring of their own (four seconds); the
  recorder's ring is drained by the game every frame, and a recording the game does not drain for several seconds loses samples
  and says so in the log.

Every public `Audio` call holds the game side's mutex (recursive: a call may make another); the callback never needs it. What a
game reads (`isPlaying`, `activeVoices`, `take_ended_voices`, the `MusicPlayer` runtime fields, `stats()`) comes from the game
side's copy of the state, updated from the returns on each call and each frame, so the simulation never reads what the audio
thread is writing. With a device the engine calls `Audio::service()` every frame (`update()` does it while the game runs, and the
engine calls it while the game is paused) to commit the commands, start the refills and take back what the mixer returned.

On the null device (headless runs, tests, `--record-audio`) there is no other thread: a command is applied as it is sent, and
`advance_null_device` mixes on the calling thread with the same functions as the callback, so a recording is deterministic. There,
and on the web, where the callback runs on the browser's main thread, a streamed voice whose ring is dry is decoded by the mixer
itself before it plays.

Nothing the callback uses is made in it: the bus buffers (4096 frames; a bigger device block is mixed in pieces of 4096), the
ducking gains and the per-block flags are made with the bus table on the game thread and handed over with it; a reverb's delay
lines are made when it is switched on. Tests:

- `engine/audio/tests/test_audio_realtime.cpp` counts the heap allocations of the thread that mixes on the null device (a
  replaced global `operator new`, counting only inside an `AllocCounter::Scope`) over voices on several buses with a low-pass, a
  reverb, ducking, a streamed clip, a PCM voice and ended voices, and expects zero.
- `engine/audio/tests/test_audio_threads.cpp` drives the mixer as a device would (`AudioTestAccess`, `audio_testing.h`): the
  callback's allocations while commands of every kind arrive (zero), a callback that mixes while another thread holds the API
  mutex (it would hang if it took it), a stream starved into underruns that resumes, the rings on two threads, and four threads
  playing, changing and stopping voices while the callback mixes, and a stalled device (settings dropped from the full queue
  are sent again, for voices, buses by name across a table swap, a snapshot, `AudioSource` parameters and music players, and
  the mixer converges; repeated Keep commands merge and no stop is lost). These tests were checked with
  ThreadSanitizer (`-fsanitize=thread`) when they were written; no CI job runs it.
- `engine/audio/tests/test_music.cpp` loads a song on a job and plays intensity changes, a section jump, a stinger and a
  crossfade with a device thread, with no allocation in the callback. For streamed music it checks that a chunk decoded after
  a seek equals the one decoded in order, that streamed and whole stems play the same events on the same frames (jumps and loops),
  the bytes of a 4-layer song and the `import.music.stream` rule, that a dry window plays silence, is counted and recovers, that a
  manual-device callback through jumps, a stinger and a crossfade allocates nothing, that a jump with no quantize while the service
  holds the stem plays no dry block (`music_prime` waits for the claim), that the music keeps its window with no call of the game for
  longer than the look-ahead, and that the callback, the game and the music service thread run together on a streamed song.

The count covers `operator new` only, so a `malloc` inside the C decoders (stb_vorbis, minimp3, dr_wav, qoa) while the null
device or the web decodes a dry stream in the callback is not covered. The streamed-music tests use the manual device (the test
calls the music service's pass and the callback itself, or starts its thread), so how the real device's timing behaves on a slow disk is not tested, and the new
threaded test was not run under ThreadSanitizer.
