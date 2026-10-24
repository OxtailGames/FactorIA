// @ts-check
// Subtitles for spoken lines and for hints: say("captions.welcome", { sound: "assets/sfx/hello.wav", speaker: "captions.guide" })
// plays the sound with its caption, say("captions.hint") shows a caption without a sound. Lines are string-table keys, so a caption
// that is on screen changes language with the game. The "captions" entity of the scene (a Captions component) draws them; the
// Subtitles option (settings.js) switches that entity off, the calls here stay the same.
import { audio, ui, i18n } from "factoria";

/**
 * @param {string} line  localization key of the line (locales/*.json)
 * @param {{ sound?: string, speaker?: string, seconds?: number }} [options]
 *   sound: clip to play (the caption lives as long as it plays); speaker: key of the speaker's name; seconds: how long the caption
 *   shows (default: the sound's length, or 3 seconds without a sound)
 */
export function say(line, { sound, speaker, seconds } = {}) {
  const who = speaker ? i18n.t(speaker) : undefined; // the name is written when the line starts
  if (sound) return audio.play(sound, { captionKey: line, speaker: who, captionSeconds: seconds });
  ui.caption("", seconds ?? 3, { key: line, speaker: who });
  return 0;
}
