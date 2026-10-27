// @ts-check
// Validator of the cut-scene data: data/cutscenes/*.cutscene.json (format larkspur.cutscene/1), rooms.json and voice.json. Pure: pass
// the parsed files in, get every problem back at once. project.validate_cutscenes (tools/validate_cutscenes.js) runs it on the
// project's files; tests/cutscene_data.test.js feeds it tests/fixtures/broken_cutscene.json.
//
// Every problem is { file, pointer, message, hint, didYouMean }: the file, the JSON pointer inside it, what is wrong, how to fix
// it, and the closest valid name ("" when there is none). scripts/cutscene.js documents the format.
import { didYouMean } from "factoria";
import { hasKey } from "./dialogue_check.js";
import { parseEffect } from "./conditions.js";

/** The kinds of step, with the fields each one needs (required) and may have (optional). */
export const STEPS = Object.freeze({
  fade: { required: ["to", "seconds"], optional: [] },
  camera: { required: ["pos", "look", "seconds"], optional: ["ease", "space"] },
  caption: { required: ["key", "seconds"], optional: ["voice", "speaker"] },
  card: { required: ["key", "seconds"], optional: [] },
  move: { required: ["actor", "to", "seconds"], optional: ["clip", "yaw"] },
  face: { required: ["actor", "toward"], optional: [] },
  anim: { required: ["actor", "clip"], optional: [] },
});
export const EASES = Object.freeze(["linear", "in", "out", "inOut"]);
export const ACTOR_KINDS = Object.freeze(["porter", "npc", "extra"]);
/** The clips a move step may name (the porter shows them by speed, a body plays the clip of its model). */
export const MOVE_CLIPS = Object.freeze(["walk", "run", "idle"]);
const SNAKE = /^[a-z][a-z0-9_]*$/;

/**
 * @typedef {{ file: string, pointer: string, message: string, hint: string, didYouMean: string }} Problem
 * @typedef {{ strings?: any, story?: any, cast?: any, rooms?: any, voice?: any, voiceScript?: any, areas?: string[], fileExists?: (path: string) => boolean }} Context
 */

const near = (word, list) => didYouMean(String(word), [...list]) ?? "";
const suggest = (word, list, label) => {
  const n = near(word, list);
  return n ? `Did you mean '${n}'?` : `${label}: ${[...list].join(", ")}.`;
};
const isNum = (v) => typeof v === "number" && Number.isFinite(v);
const isVec = (v, n) => Array.isArray(v) && v.length === n && v.every(isNum);

/**
 * Checks the cut-scenes.
 * @param {Record<string, any>} files file path -> parsed cut-scene (e.g. "data/cutscenes/intro.cutscene.json")
 * @param {Context} ctx strings (locales/en.json), story (data/story.json), cast (data/cast.json), rooms (rooms.json), voice (voice.json),
 *   voiceScript (voice_script.json), areas (area ids), fileExists (whether a project file exists; omit to skip that check)
 * @returns {Problem[]}
 */
export function validateCutscenes(files, ctx = {}) {
  /** @type {Problem[]} */
  const problems = [];
  const roomNames = Object.keys(ctx.rooms?.rooms ?? {});
  const characters = Object.keys(ctx.cast?.characters ?? {});
  const flagNames = Object.keys(ctx.story?.flags ?? {});
  const prefixes = Object.keys(ctx.story?.flagPrefixes ?? {});
  const scripted = new Set((ctx.voiceScript?.lines ?? []).map((l) => l.id));
  const registered = Object.keys(ctx.story?.cutscenes ?? {});
  const seen = new Map();

  for (const [file, c] of Object.entries(files)) {
    const report = (pointer, message, hint, didYou = "") => problems.push({ file, pointer, message, hint, didYouMean: didYou ?? "" });
    if (!c || typeof c !== "object" || Array.isArray(c)) {
      report("", "the file must be an object", 'Start it with { "format": "larkspur.cutscene/1", "id": "intro", "duration": 20, "room": "hall", "timeline": [ ... ] }.');
      continue;
    }
    if (c.format !== "larkspur.cutscene/1") report("/format", `format is ${JSON.stringify(c.format)}`, 'Set "format": "larkspur.cutscene/1".');
    if (typeof c.id !== "string" || !SNAKE.test(c.id)) report("/id", `the id is ${JSON.stringify(c.id)}`, "A cut-scene id is snake_case: lower-case letters, digits and underscores, starting with a letter.");
    else {
      const base = file.split("/").pop() ?? "";
      if (base !== `${c.id}.cutscene.json`) report("/id", `the id '${c.id}' does not match the file name '${base}'`, `Name the file ${c.id}.cutscene.json (or set "id" to '${base.replace(".cutscene.json", "")}').`);
      if (seen.has(c.id)) report("/id", `the id '${c.id}' is also used by ${seen.get(c.id)}`, "Cut-scene ids are unique.");
      else seen.set(c.id, file);
      if (ctx.story?.cutscenes && !registered.includes(c.id)) {
        report("/id", `the cut-scene '${c.id}' is not listed under "cutscenes" in data/story.json`, `Add it to CUTSCENES in assets/src/build_story.py and run it. ${suggest(c.id, registered, "Listed")}`, near(c.id, registered));
      }
    }
    if (!isNum(c.duration) || c.duration <= 0) report("/duration", `duration is ${JSON.stringify(c.duration)}`, "Give the length in seconds, e.g. 20; the player ends the cut-scene then.");
    if (!roomNames.includes(c.room)) report("/room", `the room is ${JSON.stringify(c.room)}, which is not in data/cutscenes/rooms.json`, suggest(String(c.room), roomNames, "Rooms"), near(String(c.room), roomNames));
    if (c.area !== undefined && ctx.areas && !ctx.areas.includes(c.area)) report("/area", `the area is ${JSON.stringify(c.area)}`, suggest(String(c.area), ctx.areas, "Areas"), near(String(c.area), ctx.areas));
    if (c.skippable !== undefined && typeof c.skippable !== "boolean") report("/skippable", `skippable is ${JSON.stringify(c.skippable)}`, "Use true or false (default true).");

    // The actors.
    const actors = c.actors && typeof c.actors === "object" && !Array.isArray(c.actors) ? c.actors : {};
    if (c.actors !== undefined && actors !== c.actors) report("/actors", "actors must be an object of name -> actor", 'Write "actors": { "porter": { "as": "porter" } }.');
    for (const [name, a] of Object.entries(actors)) {
      const at = `/actors/${name}`;
      if (!SNAKE.test(name)) report(at, `the actor name '${name}' is not snake_case`, "Use lower-case letters, digits and underscores.");
      if (!a || typeof a !== "object") {
        report(at, `the actor '${name}' must be an object`, `Write "${name}": { "as": "npc", "cast": "mara" }.`);
        continue;
      }
      if (!ACTOR_KINDS.includes(a.as)) report(`${at}/as`, `'${name}' is ${JSON.stringify(a.as)}`, suggest(String(a.as), ACTOR_KINDS, "Kinds"), near(String(a.as), ACTOR_KINDS));
      if (a.as !== "porter") {
        if (!characters.includes(a.cast)) report(`${at}/cast`, `'${name}' is the character ${JSON.stringify(a.cast)}, who is not in data/cast.json`, suggest(String(a.cast), characters, "Characters"), near(String(a.cast), characters));
        if (a.as === "extra" && !isVec(a.start, 2)) report(`${at}/start`, `the extra '${name}' has no start`, "An extra is made for the scene: give it start [x, z].");
      }
      if (a.start !== undefined && !(isVec(a.start, 2) || (a.as === "porter" && isVec(a.start, 3)))) report(`${at}/start`, `start is ${JSON.stringify(a.start)}`, a.as === "porter" ? "Write start [x, z, yaw]." : "Write start [x, z].");
      if (a.yaw !== undefined && !isNum(a.yaw)) report(`${at}/yaw`, `yaw is ${JSON.stringify(a.yaw)}`, "A yaw is degrees (0 looks down -Z).");
      if (a.keep !== undefined && typeof a.keep !== "boolean") report(`${at}/keep`, `keep is ${JSON.stringify(a.keep)}`, "Use true or false.");
    }
    const actorNames = Object.keys(actors);

    // The timeline.
    if (!Array.isArray(c.timeline) || c.timeline.length === 0) {
      report("/timeline", "the timeline is empty or not a list", 'Write "timeline": [ { "at": 0, "do": "fade", "to": 0, "seconds": 1 }, ... ].');
    } else {
      let last = 0;
      c.timeline.forEach((s, i) => {
        const at = `/timeline/${i}`;
        if (!s || typeof s !== "object") {
          report(at, "a step must be an object", 'Write { "at": 0, "do": "fade", "to": 0, "seconds": 1 }.');
          return;
        }
        if (!isNum(s.at) || s.at < 0) report(`${at}/at`, `at is ${JSON.stringify(s.at)}`, "Give the second the step starts, 0 or more.");
        else {
          if (s.at < last) report(`${at}/at`, `the step starts at ${s.at} s, before the one above it (${last} s)`, "Keep the timeline in time order.");
          last = Math.max(last, s.at);
          if (isNum(c.duration) && s.at > c.duration) report(`${at}/at`, `the step starts at ${s.at} s but the cut-scene lasts ${c.duration} s`, "Move it earlier or make the cut-scene longer.");
        }
        const spec = STEPS[s.do];
        if (!spec) {
          report(`${at}/do`, `the step does ${JSON.stringify(s.do)}`, suggest(String(s.do), Object.keys(STEPS), "Steps"), near(String(s.do), Object.keys(STEPS)));
          return;
        }
        for (const f of spec.required) if (s[f] === undefined) report(`${at}/${f}`, `the ${s.do} step has no '${f}'`, `A ${s.do} step needs ${spec.required.join(", ")}.`);
        for (const f of Object.keys(s)) {
          if (f === "at" || f === "do" || spec.required.includes(f) || spec.optional.includes(f)) continue;
          report(`${at}/${f}`, `the ${s.do} step has the unknown field '${f}'`, suggest(f, [...spec.required, ...spec.optional], "Fields"), near(f, [...spec.required, ...spec.optional]));
        }
        if (s.seconds !== undefined && (!isNum(s.seconds) || s.seconds < 0)) report(`${at}/seconds`, `seconds is ${JSON.stringify(s.seconds)}`, "Give a length in seconds, 0 or more.");
        else if (isNum(s.seconds) && isNum(s.at) && isNum(c.duration) && s.at + s.seconds > c.duration + 1e-6 && s.do !== "move" && s.do !== "camera") {
          report(`${at}/seconds`, `the ${s.do} step ends at ${(s.at + s.seconds).toFixed(2)} s, after the cut-scene (${c.duration} s)`, "Shorten it or make the cut-scene longer; the player cuts anything still running at the end.");
        }
        switch (s.do) {
          case "fade":
            if (s.to !== undefined && (!isNum(s.to) || s.to < 0 || s.to > 1)) report(`${at}/to`, `to is ${JSON.stringify(s.to)}`, "0 is clear, 1 is black.");
            break;
          case "camera":
            if (s.pos !== undefined && !isVec(s.pos, 3)) report(`${at}/pos`, `pos is ${JSON.stringify(s.pos)}`, "Write pos [x, y, z] in world metres.");
            if (s.look !== undefined && !isVec(s.look, 3)) report(`${at}/look`, `look is ${JSON.stringify(s.look)}`, "Write look [x, y, z]: the point the camera aims at.");
            if (s.ease !== undefined && !EASES.includes(s.ease)) report(`${at}/ease`, `ease is ${JSON.stringify(s.ease)}`, suggest(String(s.ease), EASES, "Eases"), near(String(s.ease), EASES));
            if (s.space !== undefined && s.space !== "world") report(`${at}/space`, `space is ${JSON.stringify(s.space)}`, 'Only "world" is known: the camera moves in world metres.');
            break;
          case "caption":
          case "card":
            if (typeof s.key === "string" && ctx.strings && !hasKey(ctx.strings, s.key)) report(`${at}/key`, `no string '${s.key}' in locales/en.json`, "Add it to locales/en.json (assets/src/build_cutscenes.py writes the cutscene.* strings).", "");
            if (s.speaker !== undefined && s.speaker !== "" && !characters.includes(s.speaker)) report(`${at}/speaker`, `the speaker is ${JSON.stringify(s.speaker)}, who is not in data/cast.json`, suggest(String(s.speaker), characters, "Characters"), near(String(s.speaker), characters));
            if (s.voice !== undefined) {
              if (typeof s.voice !== "string" || !SNAKE.test(s.voice)) report(`${at}/voice`, `the voice id is ${JSON.stringify(s.voice)}`, "A voice clip id is snake_case.");
              else if (ctx.voiceScript && !scripted.has(s.voice)) report(`${at}/voice`, `the voice '${s.voice}' is not in data/cutscenes/voice_script.json`, `Add the line to the voice script (assets/src/build_cutscenes.py). ${suggest(s.voice, [...scripted], "Lines")}`, near(s.voice, scripted));
            }
            break;
          case "move":
          case "face":
          case "anim": {
            if (s.actor !== undefined && !actorNames.includes(s.actor)) report(`${at}/actor`, `the actor is ${JSON.stringify(s.actor)}, who is not in this cut-scene's actors`, suggest(String(s.actor), actorNames, "Actors"), near(String(s.actor), actorNames));
            if (s.do === "face" && s.toward !== undefined && !actorNames.includes(s.toward)) report(`${at}/toward`, `toward is ${JSON.stringify(s.toward)}, who is not in this cut-scene's actors`, suggest(String(s.toward), actorNames, "Actors"), near(String(s.toward), actorNames));
            if (s.do === "move") {
              if (s.to !== undefined && !isVec(s.to, 2)) report(`${at}/to`, `to is ${JSON.stringify(s.to)}`, "Write to [x, z] in world metres.");
              if (s.clip !== undefined && !MOVE_CLIPS.includes(s.clip)) report(`${at}/clip`, `clip is ${JSON.stringify(s.clip)}`, suggest(String(s.clip), MOVE_CLIPS, "Clips"), near(String(s.clip), MOVE_CLIPS));
              if (s.yaw !== undefined && !isNum(s.yaw)) report(`${at}/yaw`, `yaw is ${JSON.stringify(s.yaw)}`, "A yaw is degrees (0 looks down -Z).");
            }
            if (s.do === "anim" && s.clip !== undefined && typeof s.clip !== "string") report(`${at}/clip`, `clip is ${JSON.stringify(s.clip)}`, 'Name a clip of the character\'s model, e.g. "emote-yes".');
            break;
          }
          default:
        }
      });
      // The cut-scene must end by itself: something has to be there up to `duration`.
      const busyUntil = Math.max(0, ...c.timeline.filter((s) => s && isNum(s.at)).map((s) => s.at + (isNum(s.seconds) ? s.seconds : 0)));
      if (isNum(c.duration) && c.duration - busyUntil > 8) {
        report("/duration", `nothing happens after ${busyUntil.toFixed(1)} s but the cut-scene lasts ${c.duration} s`, "A long empty tail looks like a freeze. Shorten the duration or add a step.");
      }
    }

    // The end state.
    if (c.end !== undefined) {
      if (!c.end || typeof c.end !== "object" || Array.isArray(c.end)) report("/end", "end must be an object", 'Write "end": { "fade": 1, "set": [{ "set": "intro_seen" }] }.');
      else {
        if (c.end.fade !== undefined && (!isNum(c.end.fade) || c.end.fade < 0 || c.end.fade > 1)) report("/end/fade", `fade is ${JSON.stringify(c.end.fade)}`, "0 is clear, 1 is black.");
        for (const k of Object.keys(c.end)) if (k !== "fade" && k !== "set") report(`/end/${k}`, `end has the unknown field '${k}'`, "Fields: fade, set.", near(k, ["fade", "set"]));
        (Array.isArray(c.end.set) ? c.end.set : []).forEach((fx, i) => {
          const e = parseEffect(fx);
          const p = `/end/set/${i}`;
          if (!e.ok) report(p, `end effect: ${e.message}`, e.hint);
          else if (e.kind !== "set" && e.kind !== "add") report(p, `an end effect may only set or add a flag, not '${e.kind}'`, 'Write { "set": "flag" } or { "add": "counter", "by": 1 }.');
          else if (!prefixes.some((x) => e.target.startsWith(x)) && ctx.story?.flags && !flagNames.includes(e.target)) report(p, `the end effect names the flag '${e.target}', which data/story.json does not declare`, suggest(e.target, flagNames, "Flags"), near(e.target, flagNames));
        });
        if (c.end.set !== undefined && !Array.isArray(c.end.set)) report("/end/set", "set must be a list of effects", 'Write "set": [{ "set": "intro_seen" }].');
      }
    }
  }

  // Every cut-scene the story names has a file.
  if (ctx.story?.cutscenes) {
    for (const id of registered) {
      if (!seen.has(id)) problems.push({ file: "data/story.json", pointer: `/cutscenes/${id}`, message: `the cut-scene '${id}' is listed but has no file`, hint: `Add data/cutscenes/${id}.cutscene.json (assets/src/build_cutscenes.py) and import it in scripts/cutscene_data.js.`, didYouMean: near(id, [...seen.keys()]) });
    }
  }

  // The voice manifest.
  const vf = "data/cutscenes/voice.json";
  const clips = ctx.voice?.clips ?? {};
  if (ctx.voice) {
    if (ctx.voice.format !== "larkspur.voice/1") problems.push({ file: vf, pointer: "/format", message: `format is ${JSON.stringify(ctx.voice.format)}`, hint: 'Set "format": "larkspur.voice/1".', didYouMean: "" });
    for (const [id, clip] of Object.entries(clips)) {
      const add = (pointer, message, hint, didYou = "") => problems.push({ file: vf, pointer, message, hint, didYouMean: didYou });
      if (ctx.voiceScript && !scripted.has(id)) add(`/clips/${id}`, `the clip '${id}' is not a line of the voice script`, suggest(id, [...scripted], "Lines"), near(id, scripted));
      if (!clip || typeof clip.path !== "string") add(`/clips/${id}/path`, `the clip '${id}' has no path`, 'Write { "path": "assets/voice/<id>.mp3", "seconds": 3.2 }.');
      else if (ctx.fileExists && !ctx.fileExists(clip.path)) add(`/clips/${id}/path`, `the file ${clip.path} does not exist`, "Make it with assets.generate_voice (the line is in data/cutscenes/voice_script.json) or remove the clip from the manifest.");
      if (!clip || !isNum(clip.seconds) || clip.seconds <= 0) add(`/clips/${id}/seconds`, `the clip '${id}' has seconds ${JSON.stringify(clip?.seconds)}`, "Give the length of the clip in seconds: the subtitle lasts as long.");
    }
  }
  // A caption whose clip is longer than its step would be cut off by the next line: warn through the same channel.
  for (const [file, c] of Object.entries(files)) {
    if (!c || !Array.isArray(c.timeline)) continue;
    c.timeline.forEach((s, i) => {
      const clip = s?.do === "caption" && s.voice ? clips[s.voice] : null;
      if (clip && isNum(clip.seconds) && isNum(s.seconds) && clip.seconds > s.seconds + 0.25) {
        problems.push({ file, pointer: `/timeline/${i}/seconds`, message: `the voice clip '${s.voice}' lasts ${clip.seconds} s but the step gives ${s.seconds} s`, hint: "The subtitle lasts as long as the clip: make room for it (the next step may start sooner than the voice ends).", didYouMean: "" });
      }
    });
  }
  return problems;
}

/** One line per problem: "file pointer: message. hint". */
export function describe(problems) {
  return problems.map((p) => `${p.file} ${p.pointer || "(file)"}: ${p.message}. ${p.hint}`).join("\n");
}
