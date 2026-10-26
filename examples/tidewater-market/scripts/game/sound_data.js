// @ts-check
// data/sounds.json (P6): every sound of the game by role, and the check that makes a mistake in it fail clearly. Pure: the
// problems have the shape of scripts/game/data.js ({ file, pointer, message, hint }); `project.validate_data` and
// tests/sounds.test.js run the check, and the game reads the table through soundData().
import soundsJson from "../../data/sounds.json";
import assetsJson from "../../assets.json";
import { rawTables, didYouMean } from "./data.js";

export const rawSoundTables = { sounds: soundsJson };

const FILE = "data/sounds.json";
/** The roles whose entries are { clip, volume }. */
const ROLES = ["ui", "ambience", "work", "walkers"];
/** The ambience beds (scripts/game/soundscape.js plays exactly these three). */
export const BEDS = ["sea", "market", "wind"];
/** UI sounds the game plays by name (scripts/game/sfx.js). */
export const UI_SOUNDS = ["click", "place", "demolish", "error", "notice", "filled", "card", "confirm"];

const isObject = (v) => !!v && typeof v === "object" && !Array.isArray(v);

/**
 * @param {typeof rawSoundTables} raw
 * @param {{ buildings: Record<string, any> }} [base] the building table (a work sound is named after a building)
 * @param {Record<string, any>} [known] the assets recorded in assets.json (a clip has to be in it, with its licence)
 * @returns {import("./data.js").Problem[]}
 */
export function validateSoundTables(raw, base = rawTables.buildings, known = assetsJson.assets) {
  /** @type {import("./data.js").Problem[]} */
  const problems = [];
  const add = (pointer, message, hint = "") => problems.push({ file: FILE, pointer, message, hint });
  const s = raw.sounds;
  const buildings = base.buildings || base;
  for (const role of ROLES) {
    if (!isObject(s[role])) {
      add(`/${role}`, `"${role}" must be an object of sounds`, `add "${role}": { ... } to ${FILE}`);
      continue;
    }
    for (const [name, entry] of Object.entries(s[role])) {
      const p = `/${role}/${name}`;
      if (name.startsWith("$")) continue;
      if (!isObject(entry) || typeof entry.clip !== "string") {
        add(p, "a sound needs a clip: the project path of an audio file", `for example { "clip": "assets/sfx/${name}.ogg", "volume": 0.5 }`);
        continue;
      }
      if (!known[entry.clip]) add(`${p}/clip`, `${entry.clip} is not in assets.json`, "import it with `factoria call assets.import` (source and licence are recorded), or fix the path");
      if (typeof entry.volume !== "number" || entry.volume < 0 || entry.volume > 1) add(`${p}/volume`, `volume must be a number from 0 to 1 (got ${JSON.stringify(entry.volume)})`);
      if (role === "work" && !buildings[name]) {
        const near = didYouMean(name, Object.keys(buildings));
        add(p, `'${name}' is not a building`, near ? `did you mean '${near}'?` : "a work sound is named after the building that makes it (data/buildings.json)");
      }
    }
  }
  for (const bed of BEDS) if (isObject(s.ambience) && !s.ambience[bed]) add(`/ambience/${bed}`, `the ambience bed '${bed}' is missing`, "the soundscape plays sea, market and wind");
  for (const name of UI_SOUNDS) if (isObject(s.ui) && !s.ui[name]) add(`/ui/${name}`, `the UI sound '${name}' is missing`, `the game plays: ${UI_SOUNDS.join(", ")}`);
  for (const field of ["work", "walkers", "ui", "cooldown"]) {
    if (!isObject(s.voices) || typeof s.voices[field] !== "number" || s.voices[field] < (field === "cooldown" ? 0 : 1)) add(`/voices/${field}`, `voices.${field} must be a number (the cap of voices, or seconds for the cooldown)`);
  }
  const total = isObject(s.voices) ? (s.voices.work || 0) + (s.voices.walkers || 0) + (s.voices.ui || 0) + BEDS.length : 0;
  if (total > 40) add("/voices", `the caps add up to ${total} voices, too close to the engine's 64`, "keep work + walkers + ui + 3 under 40");
  if (!isObject(s.mix)) add("/mix", "mix must be an object", "see the defaults in README, Sound, options and accessibility");
  else {
    for (const field of ["fullZoom", "farZoom", "margin", "seaSamples", "marketWeight", "walkerWeight", "houseWeight", "busyAt", "windFar", "windWinter", "ease", "every"]) {
      if (typeof s.mix[field] !== "number") add(`/mix/${field}`, `mix.${field} must be a number`);
    }
  }
  return problems;
}

/** The table the soundscape reads (checked when the game screen starts). */
export function soundData() {
  const problems = validateSoundTables(rawSoundTables);
  if (problems.length) {
    const lines = problems.map((p) => `${p.file} ${p.pointer}: ${p.message}${p.hint ? ` (${p.hint})` : ""}`);
    throw new Error(`${problems.length} problem(s) in data/sounds.json:\n  ${lines.join("\n  ")}`);
  }
  return soundsJson;
}
