# Music: MIDI, commands, checks and worked examples

Part of [Music](../MUSIC.md): MIDI, helpers, commands, checks, a worked example, the Music panel, an adaptive score, errors.

## MIDI

`music.import_midi {"path":"assets/music/tune.mid"}` (also `assets.import` of a `.mid` or `.midi`) reads a Standard MIDI File (format 0, 1 or 2, with its own parser; no
other program) and writes a `*.song.json` next to it (or `out`). The rules:

- Tempo, time signature and key signature come from the first such event; a later change is a warning and not applied (a song has one tempo and one meter).
- Every (MIDI track, channel, program) that plays notes becomes a song track. Channel 10 is a drum track whose General MIDI keys become the lanes of the built-in kit.
  Other tracks get the built-in instrument nearest to the program, or the SoundFont preset with that program when `soundfont` is given.
- Velocities are kept; the sustain pedal lengthens notes; controllers 7 and 10 set the track's volume and pan.
- `quantize` (`"off"` by default, or `"16"`, `"8t"`, `"32"`...) moves note starts and ends to a grid. Off keeps them to 1/48 of a quarter note, the finest step note text says.
- Markers and cue points become sections at the nearest bar line (`intro`, `loop` and `outro` prefixes set the kind); with none, the song is one `main` section.
- Repeated bars of a track become the same pattern. The result has `import` (tracks, notes, bars, sections, patterns) and `warnings`. The song's provenance records `origin: imported`
  with `license`, `author` and `sourceUrl`; a file that is not MIDI is the error `invalid_midi` with the byte offset.

`music.export_midi {"path":"assets/music/theme.song.json"}` writes `theme.mid` (format 1): a conductor track (tempo, meter, key, a marker per section) and one track per song
track, with its instrument name, General MIDI program, volume and pan. The sounded timeline is written: swing is in the times, `transpose` in the pitches, a section's
mutes are silent, muted tracks are left out. Mixer, effects and automation have no MIDI equivalent. A song without swing and with notes on the 1/48 grid imports back to the
same notes, times and velocities (a repeat becomes notes: the structure is the notes' bars, not the arrangement).

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
| `music.edit` | Applies `ops` in order and writes the song only if the result is valid. Ops: `set_song`, `set_mixer`, `add_track`, `set_track` (`name` renames the track and updates the sections; also `volume`, `pan`, `mute`, `solo`, `voices`, `effects`, `sends`), `remove_track`, `set_pattern`, `remove_pattern`, `add_section`, `set_section`, `remove_section`, `move_section`, `arrange`, `mute`, `set_layers`, `set_automation`. Their fields are in `factoria commands music.edit`. |
| `music.info` | Checks the document and says what it holds: structure, bars, seconds, notes, a summary per section (start bar and second, notes per bar and per track), the preview's state, and a **piano-roll picture** (`$image`: one colour per track, brighter is louder, drum lanes below, the sections on top). `fromBar`, `bars` and `width` choose the part drawn. |
| `music.check` | Runs the rules below. `render: true` adds the loudness. Returns `ok`, the findings and what to do. |
| `music.preview` | Renders the song to a stereo WAV (or `.ogg`) with the instruments and the mixer, and returns the measurements, `mix` (what each track, bus and the master did) and the spectrogram. `fromBar`/`bars`, `solo`/`mute`, `seed` and `sampleRate` (22050, 32000, 44100, 48000) are options. A song over 180 s needs a range. |
| `music.render` | The song for a game: the whole song as a WAV (or OGG) with its loop points (WAV `smpl` chunk and `import.loopStart`/`loopEnd`) and one stem file per layer, track or bus ("Rendering a song for a game"). Arguments `out`, `format`, `sampleRate`, `seed`, `loop`, `stems`, `overwrite`. Recipe and staleness like the preview; `assets.regenerate` rebuilds the group. |
| `music.import_midi` | A `.mid` file to a song document (`out`, `quantize`, `soundfont`, `loop`, `overwrite`, `license`, `author`, `sourceUrl`; "MIDI"). |
| `music.export_midi` | A song to a format-1 `.mid` (`out`, `overwrite`). |
| `music.notes` | The notes of one pitched pattern as a piano roll sees them: `{track, pattern}` gives a list sorted by start of `{pitch, name, tick, duration, velocity, accent, staccato}` (960 ticks per quarter note, from the start of the pattern; a chord is one note per pitch) and the pattern's `text`. A drum pattern gives its `grid` and `hits`. Read-only. |
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

## The Music panel

The editor's Music panel (View > Music, or a double click on a `*.song.json` in the Project panel) edits a song with a piano roll, a drum grid, the arrangement and a mixer, and plays it
with the same player a game uses. It has no format of its own: every edit that is kept is a command from this chapter (`music.edit`, `music.chord`, `music.arpeggio`, `music.bassline`,
`music.drums`, `music.mix`, `music.render`), one editor Undo step each, so a person and an AI can take turns on one file. See [EDITOR.md](../EDITOR.md), "Music panel", for the
controls. What matters for the document:

- **Notes are rewritten as text.** The roll edits notes, the document keeps note text. When you draw, move, resize or delete a note, the panel sends the pattern's notes as a list to
  `music.edit set_pattern` and the pattern is written again as note text: chord names and repeat groups of that pattern become the plain notes they play, and starts and ends round
  to 40 ticks (see "Notes as a list"). A pattern you never touch keeps its notation; so it is worth writing a progression with chord names, then editing the melody on the roll.
- **Edits do not bake.** The song file changes as you edit, the baked WAV and the stems next to it stay as they were until **Save + bake** (`music.render`). A running game hears the edits
  at once through hot reload ("Hot reload"); one that plays from stems keeps its stems until you bake.
- **Playing is the game's player.** Play uses the song's layers at the panel's intensity and `MusicTransport`, the clock the `MusicPlayer` uses, so Play section, Loop and the intensity
  slider are what `goToSection`, `loop` and `setIntensity` do in a game.
- **Several helpers, one place.** Insert chord, Arpeggio, Bass line and Generate (drums) run `music.chord`, `music.arpeggio`, `music.bassline` and `music.drums` and write what they return into
  the pattern that is open.

## An adaptive score, step by step

The Neon Swarm example plays `assets/music/score.song.json` (`examples/neon-swarm`, if you got it with `project.create {example: "neon-swarm"}`): a bassline and a pad that always play, a drum layer that comes in when a wave is on and an arpeggio when the
field is crowded. The song, made with the commands above:

```
music.create {"path":"assets/music/score.song.json","key":"A","mode":"minor","tempo":132,"style":"four_on_floor","progression":"Am F C G"}
music.edit {"path":"assets/music/score.song.json","ops":[
  {"op":"set_pattern","track":"bass","pattern":"drive","notes":"<four bars of eighths>"},
  {"op":"set_pattern","track":"drums","pattern":"drive","grid":{"kick":"<64 steps>","clap":"<64 steps>","hat":"<64 steps>","openhat":"<64 steps>"}},
  {"op":"remove_section","section":"loop"},
  {"op":"add_section","section":"calm","kind":"loop","repeat":2,"play":{"pad":"chords","bass":"line","drums":"groove","arp":"arp"}},
  {"op":"add_section","section":"battle","kind":"loop","repeat":2,"play":{"pad":"chords","bass":"drive","drums":"drive","arp":"arp"}},
  {"op":"set_layers","layers":{"base":["pad","bass"],"drive":{"tracks":["drums"],"intensity":0.3},"top":{"tracks":["arp"],"intensity":0.65}}}]}
```

`calm` and `battle` are two loop sections that differ in the bass (`line`: slow, `drive`: eighths) and the drums (`groove` and a busier `drive`), so a change of section is something you hear; the three layers
are what `intensity` fades in. Open the song in the Music panel to hear it: Play section on `battle`, then drag the intensity slider through 0.3 and 0.65 and watch the layer bars.

The scene has the player on an entity (`scenes/game.scene.json`), starting in `calm` with almost nothing playing:

```json
{ "id": "score", "components": { "MusicPlayer": {
    "song": "assets/music/score.song.json", "volume": 0.5, "intensity": 0.05, "startSection": "calm",
    "quantize": "bar", "layerQuantize": "beat", "layerFade": 1.0 } } }
```

and `scripts/game.js` drives it from the game's state:

```js
const music = world.find("score").music;
// intensity follows the danger (what is on the field or still to spawn, the hit points lost); only a move of 0.05 or more is sent
music.setIntensity(clamp01(0.3 + 0.5 * crowd + 0.2 * lost));
// a wave is a section change on the bar line, and the horn is a stinger on the beat that ducks the music
music.goToSection("battle", { quantize: "bar" });
music.playStinger({ clip: "assets/sfx/wave.wav", quantize: "beat", volume: 0.6, duck: 0.35 });
// the clear brings calm back; a hit is a stinger at once; dying fades the score out
music.goToSection("calm", { quantize: "bar" });
music.playStinger({ clip: "assets/sfx/hurt.wav", quantize: "none", volume: 0.7, duck: 0.5 });
music.stop({ fade: 0.8 });
```

The example's tests (`tests/neon.test.js`, "adaptive score") check that the song is in `calm` with only the base layer at the start, that more enemies on the field raise `requestedIntensity`
and fade the drum layer and then the arpeggio in (`appliedIntensity` and `status.stemGains`), that clearing the wave drops them again, that a wave queues a jump to `battle` (`pendingSection`,
`pendingAt`) that lands on a bar line, and the same back to `calm`, that the wave horn and a hit are stingers, and that dying stops the music. On the null device the mixer moves exactly the time
the game clock gives it, so the tests step frames and read the answer; they never wait for the clock.

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
instruments and the SoundFont wrapper. `song_preview.h` also has `render_song_asset` (the whole song, its loop region and the stems, with the sum error) and `song_stem_plan`; `midi.h` (`parse_midi`, `write_midi`)
and `song_midi.h` (`midi_to_song`, `song_to_midi`) are the MIDI side. The runtime player reads the same timeline and the `import.music` data of "Rendering a song for a game".
