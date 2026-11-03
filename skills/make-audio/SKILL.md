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
5. `music_instrument {}` lists the instruments by family (what each is for, its range, its voices); `music_instrument {name: "kit:electronic"}`
   lists a drum kit's lanes. A track's `instrument` is one of them, a project `.sfx.json` patch, or a SoundFont preset
   (`"assets/audio/x.sf2#Grand Piano"`; `music_instrument {name: "assets/audio/x.sf2"}` lists its presets). Pick one instrument per
   role and keep the kit the same across the game's songs.
6. Mix with `music_edit` `set_mixer` and the track fields: `volume` and `pan` per track, `effects` on a track (eq, filter, compressor,
   distortion, bitcrush, delay, reverb), `sends` to a shared `reverb` bus, `mute`/`solo` while you listen. The master brings the mix to
   the style's loudness and a limiter keeps it under the ceiling. `music_mix {path}` shows what every track, bus and the master did
   (peak, LUFS, limiter reduction) without writing a file, and `music_check {path, render: true}` judges that mastered loudness.
   Fix a muddy or buried track with its fader, a pan and an eq cut before touching the notes.
7. For a game, `music_render {path}` writes the whole song with its loop points and, when the song has `layers` (`music_edit` `set_layers`), one stem
   per layer (`theme.stem.base.wav`) that add up to the mix; the loop points are in `assets.json`, so `audio.music` loops the song and the stems line up.
   `music_import_midi {path}` (or `assets_import` of a `.mid`) turns a MIDI file into a song to edit; `music_export_midi {path}` writes one. A stale render is
   made again with `assets_regenerate {stale: true}`.
