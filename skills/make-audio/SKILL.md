---
name: make-audio
description: Craft guide for sound effects, music, voice and mixing. Read before making any audio.
---

# Making the game's audio

You make all of the game's audio: sound effects, music, ambience and voice (assets_generate_sound, assets_generate_music,
assets_generate_voice, the synth and audio tools), and the audio buses and mixing (volumes per bus, ducking, music
that loops cleanly, no clipping). Listen with the analysis tools (loudness, peaks, duration, loop points) since you
cannot hear: check every clip against the audio tools and the game's audio log (audio_log). Keep one sonic identity
(instruments, mood, loudness between clips) and name and place files consistently under assets/. Record each asset's
source and license as the asset tools do.

## Testing sounds

`audio.play("assets/sfx/jump.wav")`. Assert it with
`expect(game.audioLog()).toContainPlayed("jump.wav")` (options `times`, `bus`, `source`; `game.clearAudioLog()`). A clip that
failed to load does not count. MCP `audio_log`. Guide sections 9.7 and 10.

## Composing music

Music is a song document, `assets/music/name.song.json` (docs/MUSIC.md, `factoria docs read MUSIC.md`): write it as data, check it,
then listen to the preview.

1. `music_create {path, key, mode, tempo, style, progression}` writes a complete starting song (pad, bass, drums, arpeggio; intro,
   loop, outro). Pick the key, mode and tempo for the mood first (`music_scale` lists the modes, `music_chord` spells chords).
2. `music_edit {path, ops}` changes it: `set_pattern` with note text (`C4:4 E4 G4`, `(Am7)` a chord, `|` a bar line, `r` a rest),
   `add_track`, `add_section`, `arrange`, `mute`, `set_automation`. A bar of the wrong length is an error that names the column.
   `music_arpeggio`, `music_bassline` and `music_drums` with `path` write a part into the song.
3. `music_check {path, render: true}` before every preview: notes out of key, outside an instrument's range, clashes on a strong
   beat, mud in the low register, tracks that never play, loudness. Fix the findings from the top.
4. `music_preview {path}` renders the WAV (offline, same bytes every time) and returns its loudness and a spectrogram;
   `music_info` draws the notes as a piano roll. The preview is for judging the music, not the in-game player.
