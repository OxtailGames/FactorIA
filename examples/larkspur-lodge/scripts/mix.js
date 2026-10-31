// @ts-check
// The mix around the voice: the `voiceover` bus (factoria.json "audio.buses") carries every spoken line; this module ducks the
// music and the sound effects while someone speaks, and gives the voice the sound of the room it is said in.
//
//   mix.setup()          music and sfx duck under voiceover (idempotent; the cut-scene player calls it)
//   mix.enter("cellar")  voiceover gets the reverb and low-pass of that room (data/cutscenes/rooms.json)
//   mix.leave()          voiceover is dry again
//   mix.state()          { room, duck: { music, sfx }, voiceover: { reverb, lowpass } } as the audio engine reports it
//
// Ducking is the engine's own (audio.bus(name).duck): it follows the loudness of the voiceover bus by itself, with the attack and
// release of rooms.json "duck", so a pause between two lines lets the music swell back a little and a line brings it down again.
import { audio } from "factoria";
import { rooms } from "./cutscene_data.js";

/** The buses that go quiet under a voice. */
const DUCKED = Object.freeze(["music", "sfx"]);
/** Seconds the reverb and the filter take to come in and go out, so the voice never steps. */
const FADE = 0.25;
let room = "";

/** Makes music and sfx duck under the voiceover bus. */
export function setup() {
  const d = rooms.duck;
  for (const name of DUCKED) audio.bus(name).duck("voiceover", d.amount, d.attack, d.release);
}

/** Gives the voiceover bus the reverb and low-pass of a room of data/cutscenes/rooms.json (an unknown room leaves it dry and says so). */
export function enter(name) {
  const r = rooms.rooms[name];
  if (!r) {
    console.error(`mix: there is no room '${name}' in data/cutscenes/rooms.json. Rooms: ${Object.keys(rooms.rooms).join(", ")}.`);
    leave();
    return;
  }
  room = name;
  const bus = audio.bus("voiceover");
  bus.reverb(r.reverb, { fade: FADE });
  bus.lowpass(r.lowpass > 0 ? r.lowpass : null, { fade: FADE });
}

/** The voiceover bus goes dry again. */
export function leave() {
  room = "";
  const bus = audio.bus("voiceover");
  bus.reverb(0, { fade: FADE });
  bus.lowpass(null, { fade: FADE });
}

/** What the audio engine reports for the buses this module sets. */
export function state() {
  const v = audio.bus("voiceover").state();
  return {
    room,
    duck: Object.fromEntries(DUCKED.map((n) => [n, audio.bus(n).state().duck])),
    voiceover: { reverb: v.reverb, lowpass: v.lowpass },
  };
}
