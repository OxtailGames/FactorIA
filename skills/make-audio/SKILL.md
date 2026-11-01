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
