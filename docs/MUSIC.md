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
  `music.instrument`, `music.chord`, `music.scale`, `music.arpeggio`, `music.bassline`, `music.drums` (all in [the commands page](music/MUSIC_COMMANDS.md)), and for a game
  `music.render` (the whole song, its loop points and its stems), `music.import_midi` and `music.export_midi`.
- `project.validate` (and `assets validate`) reads every `*.song.json`: mistakes are errors with the file, the JSON pointer and,
  inside note text, the line and column; check findings (off-key notes, clashes) are warnings.
- In a game the song is played by the `MusicPlayer` component (layers that follow an intensity, sections that change on the beat or the bar,
  stingers, crossfades between songs, beat events for scripts): "Playing a song in a game" in [the game page](music/MUSIC_GAME.md). It reads the same document, or the files
  `music.render` wrote. The tempo is one number for the whole song (no tempo changes yet).

The loop for a song: **`music.create` a starting point, `music.info` to see it (the result has a piano-roll picture), `music.edit`
the patterns and sections, `music.check` before listening, `music.preview` to render it**, edit, check again.

```
music.create  {"path":"assets/music/theme.song.json","key":"D","mode":"dorian","tempo":96,"style":"shuffle"}
music.edit    {"path":"assets/music/theme.song.json","ops":[{"op":"set_pattern","track":"bass","pattern":"line","notes":"D2:8 D2 A2 D2 | G1:8 G1 D2 G1"}]}
music.check   {"path":"assets/music/theme.song.json","render":true}
music.preview {"path":"assets/music/theme.song.json"}
```

## Pages

This page has the overview and a complete example. The rest is on three pages (`docs.read music-songs`, `music-game`, `music-commands`; a heading is found on its page by itself):

- [The song document](music/MUSIC_SONGS.md): the document, notes, swing, instruments, the mixer, SoundFonts, layers and stems.
- [Rendering and playing in a game](music/MUSIC_GAME.md): `music.render`, the `MusicPlayer` component, live and stems, memory, hot reload.
- [MIDI, commands and checks](music/MUSIC_COMMANDS.md): MIDI, helpers, commands, checks, worked examples, the Music panel, adaptive score, errors.

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
