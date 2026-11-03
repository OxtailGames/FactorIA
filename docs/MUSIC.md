# Music as data: song documents (`*.song.json`)

A **song document** describes a piece of music the way a score does: a tempo, a meter and a key, **tracks** (an instrument and
named **patterns** of notes each) and **sections** (intro, loop, outro, verse...) that say which pattern every track plays and
for how many repeats. The notes are compact text an AI can read, diff and edit (`C4:4 E4 G4 (Am7):2 r`), the drums are a step grid.
The engine **checks** the song against its key, the instruments' ranges and the loudness, and **renders a preview** offline to a
WAV with real instruments and a mixer. No provider, no key, no other program, no cost, and the same song gives the same bytes on every
platform.

- Format identifier: `factoria.song/1`. Schema: `schemas/song.schema.json` (`factoria docs read schemas/song.schema.json`).
- Files: `assets/**/name.song.json`. The preview is `name.preview.wav` next to it (or any `out` path).
- Commands: `music.create`, `music.edit`, `music.info`, `music.check`, `music.preview`, `music.mix`, and the helpers
  `music.instrument`, `music.chord`, `music.scale`, `music.arpeggio`, `music.bassline`, `music.drums` (all below).
- `project.validate` (and `assets validate`) reads every `*.song.json`: mistakes are errors with the file, the JSON pointer and,
  inside note text, the line and column; check findings (off-key notes, clashes) are warnings.
- What this is not: the in-game player. The *document*, its instruments ("Instruments"), its mixer ("The mixer"), its checks and the
  offline preview exist; the runtime that plays a song in a game (stems, loop points, transitions) is a later milestone that reads the
  same document. The tempo is one number for the whole song (no tempo changes yet).

The loop for a song: **`music.create` a starting point, `music.info` to see it (the result has a piano-roll picture), `music.edit`
the patterns and sections, `music.check` before listening, `music.preview` to render it**, edit, check again.

```
music.create  {"path":"assets/music/theme.song.json","key":"D","mode":"dorian","tempo":96,"style":"shuffle"}
music.edit    {"path":"assets/music/theme.song.json","ops":[{"op":"set_pattern","track":"bass","pattern":"line","notes":"D2:8 D2 A2 D2 | G1:8 G1 D2 G1"}]}
music.check   {"path":"assets/music/theme.song.json","render":true}
music.preview {"path":"assets/music/theme.song.json"}
```

## A complete example

This is the document `music.create` writes for the call above (a dorian progression `Dm G Dm Am`, shuffle drums), shortened to
the first bars of each part; the full run is under "A worked example".

```json
{
  "format": "factoria.song/1",
  "doc": "A starting point in D dorian: Dm G Dm Am over 4 bars, shuffle drums.",
  "tempo": 96.0,
  "meter": "4/4",
  "key": "D",
  "mode": "dorian",
  "tracks": {
    "pad": {
      "instrument": "pad",
      "volume": 0.7,
      "patterns": { "chords": "v80 (Dm@3):1 | (G@3) | (Dm@3) | (Am@3)" }
    },
    "bass": {
      "instrument": "bass",
      "volume": 0.9,
      "patterns": { "line": "v100 D2:4! A2 D2 A2 | G1! D2 G1 D2 | D2! A2 D2 A2 | A1! E2 A1 E2" }
    },
    "drums": {
      "instrument": "kit",
      "volume": 0.8,
      "patterns": {
        "groove": {
          "step": "8t",
          "grid": {
            "kick": "x.....x.....x.....x.....x.....x.....x.....x.....",
            "snare": "...x.....x.....x.....x.....x.....x.....x.....x..",
            "hat": "x.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.xx.x"
          }
        }
      }
    }
  },
  "sections": [
    { "name": "intro", "kind": "intro", "play": { "pad": "chords" } },
    { "name": "loop", "kind": "loop", "repeat": 2, "play": { "pad": "chords", "bass": "line", "drums": "groove" } },
    { "name": "outro", "kind": "outro", "play": { "pad": "chords", "bass": "line" } }
  ]
}
```

## The document

| Key | Type | Default | What it does |
|---|---|---|---|
| `format` | `"factoria.song/1"` | required | File format identifier. |
| `doc` | text | none | What the song is for and where the game plays it. |
| `tempo` | number 20 to 400 | 120 | Quarter notes per minute. One tempo for the whole song. |
| `meter` | text `"4/4"` | `"4/4"` | 1 to 16 beats of a half, quarter, eighth or sixteenth note: `3/4`, `6/8`, `5/4`... A "beat" below is the note value the meter counts. |
| `key` | note name | `"C"` | The tonic note only: `C`, `F#`, `Bb`. The scale goes in `mode` (`"key": "Am"` is an error that says so). |
| `mode` | scale name | `"major"` | `major`, `minor`, `dorian`, `phrygian`, `lydian`, `mixolydian`, `locrian`, `harmonic_minor`, `melodic_minor`, `pentatonic_major`, `pentatonic_minor`, `blues`, `whole_tone`, `chromatic` (`music.scale` lists them). `music.check` judges notes against key + mode. |
| `swing` | 0 to 1 | 0 | How far the off-beats are delayed toward a triplet feel (0 straight, 1 a full triplet). |
| `swingGrid` | 8 or 16 | 8 | Which off-beats swing: eighth notes or sixteenth notes. |
| `seed` | integer, 0 or more | 0 | Picks the take of random arpeggios and of the drum kit's round-robin hits. |
| `volume` | 0 to 1.5 | 0.8 | Master gain (before the master effects and the loudness normalization). |
| `mixer` | object | none | The buses and the master: shared effects, the limiter and the loudness target ("The mixer"). |
| `tracks` | object | required | Track name (1 to 32 letters, digits, `-`, `_`) to track. 1 to 32 tracks. |
| `sections` | list | required | The arrangement, in play order. 1 to 64 sections, at most 4096 bars in all. |
| `automation` | list | none | Master lanes (`volume`, `filter`). |

A **track**:

| Key | Default | What it does |
|---|---|---|
| `instrument` | required | A built-in instrument (`piano`, `pad`, `bass_acid`, `lead_saw`, `strings`, `chip_square`... `music.instrument` lists them), a drum kit (`kit`, `kit:electronic`, `kit:chiptune`), an sfx preset name, a project `*.sfx.json` path, or a SoundFont (`"assets/audio/x.sf2#Piano"` or `{"soundfont": ..., "preset": ...}`; "Instruments", "SoundFonts"). |
| `volume` | 1 | Linear gain of the fader, 0 to 2. |
| `pan` | 0 | -1 left to 1 right. |
| `mute` | false | Silences the track in every render (a section's `mute` silences it for one part only). |
| `solo` | false | When any track is `solo`, only the soloed tracks play. |
| `voices` | the instrument's | How many notes may sound at once, 0 to 64 (0: the instrument's own limit, listed by `music.instrument`). |
| `effects` | none | Insert effects of the track, up to 8, in order ("The mixer"). |
| `sends` | none | Bus name to how much of the track goes to that bus, 0 to 2 ("The mixer"). |
| `transpose` | 0 | Semitones (-48 to 48) added to every pitched note. |
| `swing` | the song's | Swing of this track, 0 to 1. |
| `range` | the instrument's | `["E1", "G4"]`: the notes the part should stay in (names or MIDI numbers). `music.check` flags notes outside it. |
| `kit` | none | Drum tracks only: lane name to a `*.sfx.json` that replaces that lane of the built-in kit (or adds a lane). |
| `patterns` | required | Pattern name (1 to 32 letters, digits, `-`, `_`; `rest` is reserved) to pattern. 1 to 64. |
| `automation` | none | Lanes: `volume`, `pan`, `filter`, `macro.<name>`. |

A **section**: `name` (unique), `kind` (`intro`, `loop`, `outro` or `section`; the default is `section`), `repeat` (1 to 64,
default 1), `bars` (1 to 256; default: the longest track of the section, and a shorter track repeats to fill it), `mute` (tracks
that stay silent here) and `play` (track name to what it plays here). The `kind` is a label today (`music.info` and the checks
use it); later milestones use `loop` for the loop point of a game.

What a track plays in a section is a list of patterns: `"a a b*2 rest"` (text) or `["a", {"pattern": "b", "repeat": 2},
{"rest": 1}]`. `b*2` plays pattern `b` twice, `rest` is a bar of silence, `rest*2` two bars. A track that has no entry in a
section is silent there.

## Writing notes

A pitched pattern is text, or `{"notes": "...", "bars": 2}` to pad a shorter text with silence to that many bars (a longer one is
an error). Tokens are separated by spaces and line breaks.

| Token | Meaning |
|---|---|
| `C4` `F#3` `Bb2` | A note: letter, optional `#` or `b`, octave (`C4` is middle C, MIDI 60). |
| `r` | A rest. |
| `[C4 E4 G4]` | A chord spelled in notes: they start together. |
| `(Am7)` `(Am7@3)` `(Cmaj7/G)` | A chord by name. `@3` is the octave of the root (default 3). The track's `transpose` applies to it like any note. |
| `\|` | A bar line. It must fall exactly on a bar, so a wrong count is found where it happens. |
| `{ C4 E4 }x2` | A group played 2 times (1 to 256). `*2` works too. |
| `&` | Another voice: what follows starts again at the start of the pattern. All voices must be the same length. |
| `v90` | On its own: the velocity (1 to 127) of the notes after it. Default 90. |

After a note, a chord or a rest: `:4` a duration, then marks. A duration is the note value after a colon: `:1` whole, `:2` half,
`:4` quarter, `:8` eighth, `:16`, `:32`, `:64`; `:4.` dotted, `:4..` double dotted, `:8t` triplet. **A duration sticks**: the
notes after it keep it until the next duration (the default is a quarter), so `C4:8 D4 E4 F4` is four eighths. Marks:

| Mark | Meaning |
|---|---|
| `!` | Accent: velocity +22. |
| `'` | Staccato: the note sounds for half its length. |
| `~` | Tie to the next token, which must be the same pitch: `C4:2~ C4:4` is one note of three quarters. |
| `v100` | Velocity of this one note. |

```
v90 A4:4 D5 F5:8 E5 D5:4 | B4:4 D5 E5 A4:4       two bars of 4/4: 4 quarters worth of notes, a bar line, 4 more
(Am@3):1 | (F@3) | (C@3) | (G@3)                  four whole-note chords
C4:8 E4 G4 E4 { C5:16 B4 }x4 r:2.                 repeats and a dotted rest
C4:2 E4 G4 & C3:1                                 two voices of one bar each
```

A **drum pattern** is `{"grid": {lane: steps}, "step": "16", "bars": 1}`. Each character of a lane is one step of the `step`
note value (`"4"`, `"8"`, `"16"` default, `"32"`, `"8t"`, `"16t"`): `x` a hit, `X` an accent, `o` a soft ghost note, `.` (or `-`,
`_`) a rest; spaces and `|` are ignored so you can group a bar: `"x... x... x... x..."`. Lanes of the kit: `kick`, `snare`, `clap`,
`rim`, `hat`, `openhat`, `hat_pedal`, `shaker`, `tambourine`, `tom_low`, `tom_mid`, `tom_high`, `ride`, `crash`, `cowbell`, plus any lane
the track's `kit` defines.
Every lane has the same number of steps (pad with `.`), and the grid is a whole number of bars, or `bars` pads it with silence.

A mistake names the place. For example, a bar that is one beat too long:

```
error: invalid_song: assets/music/forest.song.json: /tracks/lead/patterns/theme (line 1, column 26): the bar line comes 1 beat(s)
  into a bar, but a 4/4 bar has 4 beats. Nothing was written.
  hint: Add 3 beat(s) of rest or lengthen a note before it, or move the `|`.
```

## Swing and automation

`swing` delays the off-beats of the swing grid (`swingGrid`, eighth notes by default): 0 is straight, 1 is a full triplet feel. A
track's own `swing` replaces the song's. It moves every note and keeps the bar lengths.

An **automation lane** is `{"param": "volume", "points": [[0, 0.2], [16, 1]], "curve": "linear"}`: points are `[beat, value]` with
the beat counted in quarter notes from the start of the song, in time order; `curve` is `linear` (default), `step` (jumps at each
point) or `smooth`. Before the first point the lane holds the first value, after the last the last. Params:

| Param | Range | On a track | On the song |
|---|---|---|---|
| `volume` | 0 to 2 | multiplies the track's gain | multiplies the master gain |
| `pan` | -1 to 1 | moves the track | not available |
| `filter` | 40 to 20000 Hz | a low-pass cutoff | a low-pass cutoff |
| `macro.<name>` | -1 to 1 | the macro of the track's instrument patch, read when each note starts | not available |

Built-in macros are `attack`, `brightness`, `weight`, `tail`, `pitch`, `grit` (docs/SOUND.md "Macros"); a macro lane sets the
macro for the notes that start while it is there, in steps of 0.05.

## Instruments

A track's `instrument` is played **per note at the note's pitch**. `music.instrument` with no arguments lists everything below with its
family, a sentence on what it is for, its range and its polyphony; `music.instrument {"name":"pad_glass"}` shows the patch behind one.

- **Built-in pitched instruments**, 8 families, all synthesized from sound patches (docs/SOUND.md), no files:

  | Family | Instruments |
  |---|---|
  | `keys` | `keys`, `piano`, `epiano`, `clav`, `organ` |
  | `pluck` | `pluck`, `pluck_soft`, `pluck_bright`, `guitar`, `harp` |
  | `bass` | `bass`, `bass_sub`, `bass_pluck`, `bass_acid`, `bass_fm`, `bass_square` |
  | `lead` | `lead`, `lead_saw`, `lead_soft`, `lead_fm`, `lead_acid` |
  | `pad` | `pad`, `pad_glass`, `pad_dark`, `pad_sweep` |
  | `bell` | `bell`, `bell_glass`, `music_box`, `marimba`, `vibraphone` |
  | `ensemble` | `strings`, `strings_soft`, `brass`, `horns`, `choir`, `flute`, `clarinet`, `oboe` |
  | `chiptune` | `chiptune`, `chip_square`, `chip_pulse`, `chip_triangle`, `chip_wave`, `chip_noise` |

  Each has a range (the notes it sounds good in; `music.check` flags notes outside it, or outside the track's own `range`) and a
  polyphony (the notes that may sound at once: 1 for a flute or a chip voice, 16 for a pad). To change one, copy its patch with
  `music.instrument {"name":"pluck","path":"assets/audio/pluck.sfx.json"}`, edit a number and point the track at the copy.
- **An sfx preset** by name (`sfx.preset` lists them) or **your own patch**: a project path ending in `.sfx.json`. The patch is
  rendered at the pitch of each note (the patch's own note is C4) for as long as the note is held. A patch that is missing or
  invalid is an error that names the track and the file; the patch is an input of the preview's recipe.
- **A drum kit**: `kit` (acoustic), `kit:electronic` (808/909-flavoured) or `kit:chiptune` (8-bit). `music.instrument {"name":"kit:electronic"}`
  lists the lanes and the patch of each (`kit:electronic:kick`). The lanes are `kick`, `snare`, `clap`, `rim`, `hat`, `openhat`,
  `hat_pedal`, `shaker`, `tambourine`, `tom_low`, `tom_mid`, `tom_high`, `ride`, `crash`, `cowbell`. A track's `kit` replaces a lane with
  your own `*.sfx.json` patch (or adds a lane). A later `hat`, `hat_pedal` or `openhat` **chokes** an open hat that is still ringing, like
  a real hi-hat.
- **A SoundFont** (`.sf2`) file of the project ("SoundFonts").

How a note is played:

- **Level.** Every built-in instrument is calibrated so a C4 at velocity 100, held as a half note at 120 bpm, peaks about -12 dBFS, and
  tracks at volume 1 add up to a sensible level. A slow pad that is held longer swells louder than that; the drum lanes sit at levels of their own
  (a kick is louder than a hat). A project patch or an sfx preset is levelled the same way, from its own C4, so the track's `volume`
  means the same for every instrument.
- **Velocity.** The amplitude is `(velocity / 100) ^ 1.25`, so velocity 100 is the calibrated level and 50 is about -7.5 dB. Outside the
  chiptune voices and the drums a harder note is also brighter (the `brightness` macro follows the velocity). Accents (`!`) and `v` set the velocity;
  the `brightness` macro of a `macro.brightness` automation lane adds to it.
- **Pitch.** A note is the patch rendered at that pitch, with the filters following the pitch (`keytrack` in the patch,
  docs/SOUND.md), so a high note is as bright as a low one. The oscillators are band-limited: a high saw has no alias tones between its harmonics.
- **Polyphony and release.** A note sounds for its written length (`'` staccato makes it half) and then **releases** with the
  instrument's own release time. The notes of a track that ring together are limited to its `voices` (the instrument's polyphony by default):
  a ringing release counts as a voice, and when a new note needs one, the oldest one is cut with an 8 ms fade. The notes of one chord never cut
  each other (a chord with more notes than `voices` plays in full), and a key that is struck again while it still rings is cut and restarted. A track
  of a monophonic instrument (`flute`, the `chip_*` voices; `voices: 1` makes any other one) therefore never plays two notes at once.
- **Determinism.** The same song, seed and sample rate give the same samples on every platform.

## The mixer

The tracks, the buses and the master form the **mixer**, in the song document:

```json
{
  "volume": 0.8,
  "mixer": {
    "buses": {
      "hall": { "effects": [{ "type": "reverb", "decay": 2.2, "mix": 1 }], "volume": 0.9 },
      "echo": { "effects": [{ "type": "delay", "time": 0.375, "feedback": 0.35, "mix": 1 }] }
    },
    "master": {
      "effects": [{ "type": "eq", "bands": [{ "type": "highShelf", "freq": 9000, "gainDb": -1.5 }] }],
      "limiter": { "ceilingDb": -1, "release": 0.1 },
      "loudness": "style"
    }
  },
  "tracks": {
    "pad":  { "instrument": "pad_glass", "pan": -0.3, "sends": { "hall": 0.5 },
              "effects": [{ "type": "filter", "mode": "lowpass", "cutoff": 6000 }] },
    "lead": { "instrument": "lead_saw", "voices": 1, "pan": 0.2, "sends": { "hall": 0.25, "echo": 0.2 } },
    "kick": { "instrument": "kit", "solo": false, "mute": false, "patterns": {} }
  }
}
```

The signal runs: the notes of a track, then the track's `automation` filter lane, the track's **`effects`** (inserts, in order), the
**`volume`** fader (with its automation lane), **`pan`**, and from there to the **master** and, post-fader, to the buses the track
**`sends`** to (a level 0 to 2 per bus). A bus has its own `effects`, `volume`, `pan` and `mute`, returns **only the effect** (a reverb or delay
on a bus gives back just its wet sound, since the dry sound is the track itself, so the send level is the amount) and goes to the master. The master applies the song's `volume`, its automation lanes, its `effects`, a
20 ms fade at the very end, the **loudness normalization** and the **limiter**.

| Where | Key | What it does |
|---|---|---|
| track | `effects` | Up to 8 steps: `eq`, `filter`, `compressor`, `distortion`, `bitcrush`, `delay`, `reverb`, written like the steps of an audio document (`audio.info` lists the fields; docs/SOUND.md). `"enabled": false` skips one. |
| track | `sends` | `{"hall": 0.4}`: post-fader level into a bus declared in `mixer.buses`. A send to an unknown bus is an error with the close names. |
| track | `mute`, `solo` | Mute silences the track. If any track has `solo: true`, only the soloed tracks play. The `solo` and `mute` options of `music.preview` do the same for one render. |
| track | `pan` | -1 left to 1 right. A mono instrument is panned with a constant-power law (unity at the centre, the far channel falls to silence at the edge); a stereo source (a SoundFont) is balanced. |
| `mixer.buses.<name>` | `volume` (0 to 2), `pan`, `mute`, `effects` | A shared effect return. Up to 8 buses, named like tracks. |
| `mixer.master` | `effects` | Up to 8 steps on the whole mix, after the song `volume`. |
| `mixer.master` | `limiter` | `true` (default), `false`, or `{"ceilingDb": -24 to 0, "release": 0.005 to 2}`. A lookahead peak limiter: the render never goes above `ceilingDb` (default -1 dBFS). |
| `mixer.master` | `loudness` | `"style"` (default): the mix is brought to the music loudness of the project's style guide (`audio.loudnessLufs.music` in `assets.json`, docs/SOUND.md "Loudness") when it sets one; `"off"`: keep the level the tracks add up to; or a number of LUFS, -40 to -5. |

**Loudness normalization.** After the effects, the render measures the mix (integrated LUFS) and applies the gain that reaches the target, at
most +18 dB, taking the limiter into account: when the peaks are in the way, the gain is chosen so the limited mix lands on the target as closely as
it can. A song with no style target keeps the level its tracks add up to. The style guide's target is read at render time, so changing it changes the
next render but does not mark an existing preview stale. `music.check {"render": true, "targetLufs": -14}` replaces the style's target for that one
check (a `loudness` number in the mixer always wins over both).

**The tail.** The render is as long as the music plus the longest reverb or delay tail of any chain (at most 8 s), so a hall bus is not cut off.

`music.mix` renders in memory and returns, without writing a file, what the mix did: for every track its notes, peak, loudness, volume, pan,
effects and sends; for every bus its settings; for the master the final `lufs` and `peakDb`, the level **before the limiter**, the
`limiterReductionDb`, the `normalizeGainDb`, the `targetLufs` and where it came from. `music.preview` returns the same under `mix`. `music.check` with
`render: true` judges the mastered mix: a peak above -1 dBFS (or any clipping) with the limiter off, a limiter that pulls the level down by more than 3 dB
(info) or 6 dB (warning), a mix that is not within 3 LU of the target, and a mix below -35 LUFS (the rule is in "Checks").

**Changing the mix.** `music.edit` has the op `set_mixer` (`buses`: bus name to its fields, merged; a field set to `null` goes back to its
default, a bus set to `null` is removed together with the sends to it; `master`: the same for `effects`, `limiter`, `loudness`) and `set_track` takes
`mute`, `solo`, `voices`, `effects` and `sends`. Mistakes name the JSON pointer, say what is wrong and suggest the close name:

```
music.edit {"path":"assets/music/theme.song.json","ops":[
  {"op":"set_mixer","buses":{"hall":{"effects":[{"type":"reverb","decay":2.2,"mix":1}]}},"master":{"loudness":-16}},
  {"op":"set_track","track":"pad","sends":{"hall":0.5},"voices":8}]}
music.mix  {"path":"assets/music/theme.song.json"}
```

A typical mixing loop: `music.mix` to see which track is loudest (`peakDb`, `lufs`) and whether the limiter works hard (`limiterReductionDb`), lower the loud
tracks' `volume` with `set_track`, add a `reverb` bus and `sends` for depth, `music.mix` again, then `music.preview` to write the WAV.

## SoundFonts

A **SoundFont** (`.sf2`) is a file of recorded instruments. The engine includes none: the project brings the file as an asset (for example
`assets/audio/piano.sf2`), and the synthesis is [TinySoundFont](https://github.com/schellingb/TinySoundFont) (MIT, in the engine's notices),
built into the engine. Nothing else is required, and a game that uses no SoundFont never loads one. A track plays a preset:

```json
{ "instrument": "assets/audio/piano.sf2" }
{ "instrument": "assets/audio/piano.sf2#Grand Piano" }
{ "instrument": "assets/audio/piano.sf2#0:25" }
{ "instrument": { "soundfont": "assets/audio/piano.sf2", "preset": "Grand Piano" } }
{ "instrument": { "soundfont": "assets/audio/piano.sf2", "preset": 25, "bank": 0 } }
{ "instrument": { "soundfont": "assets/audio/gm.sf2", "drums": true } }
```

- The text form is `file.sf2`, `file.sf2#<preset name>` (an exact name first, then ignoring case) or `file.sf2#<bank>:<program>`; the first form
  plays the file's first preset. The object form has `soundfont`, `preset` (a name or a program number 0 to 127), `bank` (0 to 128, goes with a numeric
  `preset`) and `drums`.
- **Drums.** A preset in bank 128 (or `"drums": true`) is a percussion kit: the track takes a grid pattern and each lane plays its General MIDI key
  (`kick` 36, `snare` 38, `clap` 39, `rim` 37, `hat` 42, `openhat` 46, `hat_pedal` 44, `tambourine` 54, `tom_low` 45, `tom_mid` 47, `tom_high` 50, `ride` 51,
  `crash` 49, `shaker` 70, `cowbell` 56).
- **Which presets.** `music.instrument {"name":"assets/audio/piano.sf2"}` lists the presets of the file with their bank and program, and `music.instrument`
  with no arguments lists the `.sf2` files under `assets/`.
- **Level.** The preset's own C4 (a snare for a drum kit) at velocity 100 is brought to the same -12 dBFS as the synthesized instruments, so a SoundFont
  track mixes like any other; the velocity goes to the SoundFont as it is. The mixer (`effects`, `sends`, `pan`, `volume`, `voices`) applies to it as to
  any track; a SoundFont is stereo, so `pan` balances it.
- **Errors teach.** A file that is missing, is not a SoundFont, or has no such preset is an error naming the track, the file and (for a preset) the close
  names and the list of available ones. The path must be inside the project (no `..`, not absolute). `project.validate` checks that the file exists and
  is a SoundFont 2 file; it does not read the presets (a large font is slow to load), so a wrong preset shows up in `music.check` with `render` and in `music.preview`.
- The file is an input of the preview's recipe: change it and the preview is stale.
- The result is deterministic: TinySoundFont's math calls use the engine's own math, so the same file and notes give the same samples everywhere.

## Helpers

Each one returns **text you can paste**; with `path` it also writes it into a song as a pattern (the track is created when
missing) and, with `section`, plays it there. All accept `progression`: chord names (`Am F C G`, `Am7 | Fmaj7`) or Roman numerals
in the key (`i VI III VII`); `*2` holds a chord two bars.

| Command | What it gives |
|---|---|
| `music.chord {"name":"Dm7"}` | The notes, MIDI numbers, the intervals and how to write it in note text. With `progression` (and `key`, `mode`) it spells a whole progression; with no arguments it lists the chord qualities. |
| `music.scale {"mode":"dorian","key":"D"}` | The notes of a scale and the chords on its degrees with Roman numerals. Without `mode`, lists every scale. |
| `music.arpeggio` | A chord progression one note at a time: `direction` (up, down, updown, downup, random), `octaves` (1 to 4), `rate`, `triplet`. Default track `arp`, instrument `pluck`. |
| `music.bassline` | A bass from the progression: `style` `root`, `root_fifth` (default), `octave` or `walking`. Default track `bass`, instrument `bass`. |
| `music.drums` | A drum pattern in a style: `rock`, `four_on_floor`, `disco`, `hiphop`, `trap`, `dnb`, `breakbeat`, `funk`, `metal`, `ballad`, `reggae`, `march`, `shuffle`, `waltz`; `bars` and `fill` (a tom fill on the last beat). Default track `drums`, pattern `groove`. A 4/4 style fails in 3/4 and says so. |
| `music.instrument` | The instruments by family (range, polyphony), the drum kits and lanes, the sfx presets, the project's patches and SoundFonts. `name` shows the patch behind one instrument or lane, the lanes of a kit (`kit:electronic`), or the presets of a `.sf2` file. With `path` it copies a patch into the project. |

## Commands

| Command | What it does |
|---|---|
| `music.create` | Writes a complete, valid starting song: a pad, a bassline, drums and (unless `arpeggio` is false) an arpeggio over the progression, with intro, loop (twice) and outro. Fails with `exists` unless `overwrite`. Returns the summary and the piano roll. |
| `music.edit` | Applies `ops` in order and writes the song only if the result is valid. Ops: `set_song`, `set_mixer`, `add_track`, `set_track` (`name` renames the track and updates the sections; also `volume`, `pan`, `mute`, `solo`, `voices`, `effects`, `sends`), `remove_track`, `set_pattern`, `remove_pattern`, `add_section`, `set_section`, `remove_section`, `move_section`, `arrange`, `mute`, `set_automation`. Their fields are in `factoria commands music.edit`. |
| `music.info` | Checks the document and says what it holds: structure, bars, seconds, notes, a summary per section (start bar and second, notes per bar and per track), the preview's state, and a **piano-roll picture** (`$image`: one colour per track, brighter is louder, drum lanes below, the sections on top). `fromBar`, `bars` and `width` choose the part drawn. |
| `music.check` | Runs the rules below. `render: true` adds the loudness. Returns `ok`, the findings and what to do. |
| `music.preview` | Renders the song to a stereo WAV (or `.ogg`) with the instruments and the mixer, and returns the measurements, `mix` (what each track, bus and the master did) and the spectrogram. `fromBar`/`bars`, `solo`/`mute`, `seed` and `sampleRate` (22050, 32000, 44100, 48000) are options. A song over 180 s needs a range. |
| `music.mix` | The same render in memory, without a file: the level of every track, the buses and the master (peak, LUFS, limiter reduction, normalization gain). Same options as `music.preview` except the output. |

`music.create` and `music.info` return the piano-roll picture; `music.edit` and the helpers that take `path` return it only with
`"picture": true`, so a loop of edits does not fill the conversation with images. The preview is recorded in `assets.json` with provenance (`kind: music`) and a recipe
whose inputs are the song and every patch it read: `project.validate` warns when they changed after the preview was rendered, and
`assets.regenerate {"stale": true}` renders it again. A WAV that `music.preview` did not make is never overwritten without
`overwrite: true`.

## Checks

`music.check` is what you run before listening. A rule that finds the same thing many times reports it once with a `count`. Every
finding has the rule, a severity, the track, pattern, section, bar and position, the `pointer`, `line`, `column` and `token` of the
note text, and a hint.

| Rule | Severity | Finds |
|---|---|---|
| `off_key` | warning | A note whose pitch class is not in the song's key and mode. Short off-beat notes (an eighth or less) are passing tones and are skipped. |
| `range` | warning | A note outside the range of its instrument (the track's `range`, or the built-in instrument's own). |
| `clash` | warning | A minor second (or minor ninth) or a tritone sounding together on a strong beat between different tracks or voices. Notes of one chord written by name are skipped, so a dominant 7th written as `(G7)` is fine. |
| `mud` | warning | Two notes sounding together below C3 and up to 3 semitones apart: the low register turns to mud. |
| `structure` | warning | A track that never plays, a section with no notes; a pattern no section uses is info. |
| `loudness` | warning, error | Needs a render through the mixer (`render: true`): a peak above -1 dBFS with the master limiter off (an error above 0), a limiter pulling the level down by more than 3 dB (info) or 6 dB (warning), an integrated loudness more than 3 LU from the target or below -35 LUFS. The target is the mixer's `loudness` number, or the style guide's music loudness (`audio.loudnessLufs.music`) when the project has one; the `targetLufs` argument replaces the style's. |

`ok` is false for any warning or error. `project.validate` runs the song checks too (not the loudness): parse problems are errors,
findings are warnings (20 per song at most).

## A worked example

Every output below is a real run in a new project (`factoria new` with the `2d-empty` template). First, a song:

```
music.create {"path":"assets/music/forest.song.json","key":"D","mode":"dorian","tempo":96,"style":"shuffle","progression":"i IV i v"}
```

The result starts with `"progression": "Dm G Dm Am"`, `"bars": 16`, `"seconds": 40.0`, `"notes": 384`, `"structure": "intro (4 bars) > loop
(4 bars) x2 > outro (4 bars)"`, one entry per track (pad, bass, drums, arp) with its patterns, notes and the sections it plays in,
and the piano-roll picture. The document is the one under "A complete example", plus the `arp` track.

A melody, written with a mistake on purpose (the first bar has five beats):

```
music.edit {"path":"assets/music/forest.song.json","ops":[
  {"op":"add_track","track":"lead","instrument":"flute","volume":0.8,"range":["D4","A5"],
   "patterns":{"theme":"v90 A4:4 D5 F5:8 E5 D5:2 | C5:4 D5 E5 A4:2. r:4 | ..."}},
  {"op":"set_section","section":"loop","play":{"lead":"theme"}}]}
```
```
error: invalid_song: assets/music/forest.song.json: /tracks/lead/patterns/theme (line 1, column 26): the bar line comes 1 beat(s)
  into a bar, but a 4/4 bar has 4 beats. Nothing was written.
  hint: Add 3 beat(s) of rest or lengthen a note before it, or move the `|`.
```

The file is untouched. The corrected edit (`"theme": "v90 A4:4 D5 F5:8 E5 D5:4 | C5:4 D5 E5 A4:4 | A4:4 D5 F5:8 G5 A5:4 | G5:4 F5 E5 D5:4"`) writes it and answers
`"edits": ["added track lead (\"flute\")", "changed section loop: play"]` and the new summary (420 notes). Then the check:

```
music.check {"path":"assets/music/forest.song.json"}
```
```
"ok": false, "valid": true, "rulesRun": ["off_key","range","clash","mud","structure"], "errors": 0, "warnings": 2,
"issues": [
  {"rule": "clash", "severity": "warning", "track": "pad", "pattern": "chords", "section": "loop", "bar": 6, "position": "bar 6, beat 1",
   "message": "B3 (track `pad`, pattern `chords`) and C5 (track `lead`, pattern `theme`) sound together on a strong beat: a minor ninth",
   "hint": "Move one of them a step to a note that belongs to the chord, shorten it so it ends before the strong beat, or make it a passing tone on an off-beat.",
   "pointer": "/tracks/pad/patterns/chords", "line": 1, "column": 16, "token": "(G@3)", "count": 2},
  {"rule": "clash", ... "track": "lead", "pattern": "theme", "bar": 8, "position": "bar 8, beat 2", "pointer": "/tracks/lead/patterns/theme",
   "line": 1, "column": 74, "token": "F5", "count": 2}]
```

The C5 on the first beat of bar 2 of the theme leans on the G chord's B, and the F5 in bar 4 on the Am chord's E. Change those notes with
`set_pattern`:

```
music.edit {"path":"assets/music/forest.song.json","ops":[{"op":"set_pattern","track":"lead","pattern":"theme",
  "notes":"v90 A4:4 D5 F5:8 E5 D5:4 | B4:4 D5 E5 A4:4 | A4:4 D5 F5:8 G5 A5:4 | G5:4 E5 E5 D5:4"}]}
music.check {"path":"assets/music/forest.song.json","render":true}
```

The second check returns `"ok": true`, no issues, `"rulesRun"` now including `loudness`, and `"loudness": {"lufs": -17.1, "peakDb": -3.5}`.
Then `music.preview {"path":"assets/music/forest.song.json"}` writes `assets/music/forest.preview.wav` (40.0 s, stereo,
7.3 MB, 420 notes, -17.2 LUFS, peak -3.4 dBFS) with the spectrogram picture and records the recipe in `assets.json`.
`music.info` afterwards reports `"preview": {"path": "assets/music/forest.preview.wav", "exists": true, "madeByPreview": true,
"stale": false}` and a summary per section, for example the loop: start bar 5, 10 s per pass, 158 notes per pass (pad 12,
bass 16, drums 48, arp 64, lead 18). If you edit the song and do not render again, `stale` becomes true.

## Errors

Every error says where, what is wrong and how to fix it, with "did you mean" for names: an unknown mode (`"lydain"`: did you mean
`lydian`?), an unknown track in a section, an unknown pattern in an arrangement, an unknown drum lane, a key written as `"Am"`, a
note without an octave (`"A"`: write `A4`), a tie to a different pitch, a bar line in the wrong place, an unclosed `{`. A song with
mistakes returns one `invalid_song` error whose `data.issues` has every one of them (`pointer`, `message`, `hint`, `line`, `column`),
so you fix them all in one go. Nothing is ever written when the result would not be valid.

## For tools

`fa/audio/song.h` is the public header: `parse_song` (JSON to `SongDoc` with every issue), `expand_song` (the arrangement as one
sorted `SongTimeline` of timed note events, in ticks of 960 per quarter note, with swing applied), and the model. `song_check.h`,
`song_preview.h`, `song_theory.h`, `song_helpers.h`, `song_instruments.h` and `soundfont.h` hold the checks, the offline renderer (the
instruments and the mixer: `render_song` returns the clip, per-track and master statistics), chords and scales, the generators, the built-in
instruments and the SoundFont wrapper. Later music work (stems and loop points, the runtime player) reads the same timeline.
