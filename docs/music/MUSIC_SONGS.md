# Music: the song document

Part of [Music](../MUSIC.md): the document, notes, swing and automation, instruments, mixer, SoundFonts, layers and stems.

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
| `layers` | object | none | Groups of tracks for the stems of `music.render` ("Layers and stems"). |
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

**Notes as a list.** `music.notes` reads a pattern as the list a piano roll draws, and `set_pattern` accepts the same list in `notes`:

```
music.notes {"path":"assets/music/forest.song.json","track":"lead","pattern":"theme"}
music.edit {"path":"assets/music/forest.song.json","ops":[{"op":"set_pattern","track":"lead","pattern":"theme","bars":4,
  "notes":[{"pitch":"A4","tick":0,"duration":960},{"pitch":62,"tick":960,"duration":480,"velocity":100,"accent":true}]}]}
```

A note has `pitch` (a MIDI number or a name), `tick` and `duration` (ticks of 960 per quarter note) and optionally `velocity` (1 to 127), `accent` and `staccato`. The list is written
into the document **as note text**: the file stays what this chapter describes, nothing else is stored. Because of that, a pattern that goes through the list form is
**normalized**: chord names (`(Am7)`) and repeat groups (`{ ... }x4`) become the plain notes they play, and every start and end is rounded to the nearest 40 ticks (a 64th-note
triplet, the finest step the notation can say; `song_write_note_text` in `fa/audio/song.h`). Notes that start and end together are written as a chord `[C4 E4 G4]`, notes that overlap go in
voices (`&`), and a note longer than a written duration or crossing a bar line is tied. A pattern you write by hand and never send through the list keeps its notation: the Music panel only
rewrites a pattern when you edit its notes there. Drum patterns are not notes: they stay a `grid`.

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

## Layers and stems

A game that plays music in layers (calm, tension, combat) needs the song as separate files that start together and add up to the
whole. A **layer** names a group of tracks and how intense the game should be when it is on:

```json
"layers": {
  "base":   { "tracks": ["pad", "bass"], "intensity": 0, "doc": "always on" },
  "rhythm": ["drums"],
  "action": { "tracks": ["arp", "lead"], "intensity": 0.8 }
}
```

- A layer is a list of track names, or an object with `tracks`, `intensity` (0 to 1, the player intensity from which the layer plays; left out, the layers are spread evenly in the order written, the first at 0 and the last at 1) and `doc`.
- A track in two layers is an error. Tracks that no layer lists go to a layer named `other`, which `music.render` makes only when it is not empty.
- `music.edit` `set_layers {"layers": {"base": ["pad","bass"], "old": null}}` sets or removes layers; renaming or removing a track follows the layers.
- `music.info` lists the layers.
