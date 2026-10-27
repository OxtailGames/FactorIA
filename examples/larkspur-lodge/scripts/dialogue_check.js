// @ts-check
// Validators of the story data: the dialogue tables (data/dialogue/*.json), the story registry (data/story.json: flags,
// chapters, endings, places) and the cast (data/cast.json). Pure: pass the parsed files in, get every problem back at once.
// project.validate_dialogue (tools/validate_dialogue.js) runs them on the project's files; tests/dialogue_data.test.js feeds
// them broken tables.
//
// Every problem is { file, pointer, message, hint, didYouMean }: the file, the JSON pointer inside it, what is wrong, how to fix
// it, and the closest valid name ("" when there is none).
import { didYouMean } from "factoria";
import { parseCondition, parseEffect } from "./conditions.js";
import { END } from "./dialogue_runner.js";

/** Speakers a line may have besides the characters of data/cast.json. */
export const EXTRA_SPEAKERS = Object.freeze(["porter", "narrator"]);

/** The bodies a character may have: the Kenney blocky characters that are spare in assets/models/characters. */
export const BODIES = Object.freeze(["a", "e", "f"]);

/**
 * @typedef {{ file: string, pointer: string, message: string, hint: string, didYouMean: string }} Problem
 * @typedef {{ strings?: any, story?: any, cast?: any, items?: any, doors?: string[], areas?: string[], cutscenes?: string[] }} Context
 */

function makeReporter(file, out) {
  return (pointer, message, hint, near = "") => out.push({ file, pointer, message, hint, didYouMean: near ?? "" });
}

/** True when the dotted `key` leads to a string (or a { text } object) in the locale tree. */
export function hasKey(strings, key) {
  let node = strings;
  for (const part of String(key).split(".")) {
    if (node === null || typeof node !== "object" || !(part in node)) return false;
    node = node[part];
  }
  return typeof node === "string" || (node !== null && typeof node === "object" && "text" in node);
}

const near = (word, list) => didYouMean(String(word), [...list]) ?? "";
const suggest = (word, list, label) => {
  const n = near(word, list);
  return n ? `Did you mean '${n}'?` : `${label}: ${[...list].join(", ")}.`;
};

/** Everything the conditions and effects may name, worked out once from the context. */
function vocabulary(ctx) {
  const flags = ctx.story?.flags ?? {};
  const prefixes = Object.keys(ctx.story?.flagPrefixes ?? {});
  return {
    flags,
    flagNames: Object.keys(flags),
    prefixes,
    items: Object.keys(ctx.items?.items ?? {}),
    speakers: [...Object.keys(ctx.cast?.characters ?? {}), ...EXTRA_SPEAKERS],
    /** The cut-scene ids that exist (ctx.cutscenes, else the registry of data/story.json); undefined skips the check. */
    cutscenes: ctx.cutscenes ?? (ctx.story?.cutscenes ? Object.keys(ctx.story.cutscenes) : undefined),
  };
}

/** Reports a flag name the registry (data/story.json) does not declare. A dotted prefix from `flagPrefixes` is allowed. */
function checkFlag(name, vocab, ctx, report, pointer, what) {
  const prefix = vocab.prefixes.find((p) => name.startsWith(p));
  if (prefix) {
    if (prefix === "open." && ctx.doors && !ctx.doors.includes(name.slice(prefix.length))) {
      report(pointer, `${what} names the flag '${name}', but no scene has a door '${name.slice(prefix.length)}'`, suggest(name.slice(prefix.length), ctx.doors, "Doors"), near(name.slice(prefix.length), ctx.doors));
    }
    return;
  }
  if (vocab.flagNames.includes(name)) return;
  report(pointer, `${what} names the flag '${name}', which data/story.json does not declare`, `${suggest(name, vocab.flagNames, "Flags")} If it is new, declare it under "flags" in data/story.json.`, near(name, vocab.flagNames));
}

function checkCondition(text, vocab, ctx, report, pointer, what) {
  const p = parseCondition(text);
  if (!p.ok) {
    report(pointer, `${what}: ${p.message}`, p.hint);
    return;
  }
  const c = p.cond;
  if (c.item) {
    if (!vocab.items.includes(c.name)) report(pointer, `${what} names the item '${c.name}', which is not in data/items.json`, suggest(c.name, vocab.items, "Items"), near(c.name, vocab.items));
    return;
  }
  checkFlag(c.name, vocab, ctx, report, pointer, what);
  const decl = vocab.flags[c.name];
  if (decl && c.op && typeof c.value !== decl.type && !(decl.type === "string" && typeof c.value === "string")) {
    report(pointer, `${what} compares the ${decl.type} flag '${c.name}' with ${JSON.stringify(c.value)}`, `Compare it with a ${decl.type}.`);
  }
}

function checkEffect(fx, vocab, ctx, report, pointer, what) {
  const e = parseEffect(fx);
  if (!e.ok) {
    report(pointer, `${what}: ${e.message}`, e.hint);
    return e;
  }
  switch (e.kind) {
    case "set":
    case "add": {
      checkFlag(e.target, vocab, ctx, report, pointer, what);
      const decl = vocab.flags[e.target];
      if (decl) {
        if (e.kind === "add" && decl.type !== "number") report(pointer, `${what} adds to '${e.target}', which data/story.json declares as ${decl.type}`, 'Only a flag declared with "type": "number" can be added to.');
        if (e.kind === "set" && typeof e.value !== decl.type) report(pointer, `${what} sets the ${decl.type} flag '${e.target}' to ${JSON.stringify(e.value)}`, `Set it to a ${decl.type}.`);
      }
      break;
    }
    case "give":
    case "take":
      if (!vocab.items.includes(e.target)) report(pointer, `${what} ${e.kind}s the item '${e.target}', which is not in data/items.json`, suggest(e.target, vocab.items, "Items"), near(e.target, vocab.items));
      break;
    case "cutscene":
      if (vocab.cutscenes && !vocab.cutscenes.includes(e.target)) report(pointer, `${what} starts the cut-scene '${e.target}', which data/story.json does not list under "cutscenes"`, suggest(e.target, vocab.cutscenes, "Cut-scenes"), near(e.target, vocab.cutscenes));
      break;
    default:
  }
  return e;
}

/**
 * Checks the dialogue tables.
 * @param {Record<string, any>} tables file path -> parsed table (e.g. "data/dialogue/ch1.json")
 * @param {Context} ctx strings (locales/en.json), story (data/story.json), cast (data/cast.json), items (data/items.json), doors
 *   (door entity ids of the scenes), cutscenes (cut-scene ids; omit to use the "cutscenes" of data/story.json)
 * @param {{ entries?: string[] }} [opts] entries: conversation ids that something outside the tables starts (the scenes' `dialogue`
 *   props); the cast's `talk` table is read from ctx.cast
 * @returns {Problem[]}
 */
export function validateDialogue(tables, ctx = {}, opts = {}) {
  /** @type {Problem[]} */
  const problems = [];
  const vocab = vocabulary(ctx);
  /** conversation id -> file, to catch duplicates */
  const owner = new Map();
  /** @type {{ file: string, id: string, conv: any }[]} */
  const all = [];

  for (const [file, table] of Object.entries(tables)) {
    const report = makeReporter(file, problems);
    if (!table || typeof table !== "object" || typeof table.conversations !== "object" || Array.isArray(table.conversations)) {
      report("", "the file must be an object with a 'conversations' object", 'Start it with { "format": "larkspur.dialogue/1", "conversations": { "ch1_mara": { "start": "dlg.ch1_mara.greet", "nodes": { ... } } } }');
      continue;
    }
    if (table.format !== "larkspur.dialogue/1") report("/format", `format is '${table.format}'`, 'Set "format": "larkspur.dialogue/1".');
    for (const [id, conv] of Object.entries(table.conversations)) {
      if (owner.has(id)) report(`/conversations/${id}`, `the conversation '${id}' is also defined in ${owner.get(id)}`, "Conversation ids are unique across data/dialogue/*.json: rename one.");
      else owner.set(id, file);
      all.push({ file, id, conv });
    }
  }

  for (const { file, id, conv } of all) {
    const report = makeReporter(file, problems);
    const at = `/conversations/${id}`;
    if (!/^[a-z][a-z0-9_]*$/.test(id)) report(at, `conversation id '${id}' is not snake_case`, "Use lower-case letters, digits and underscores, starting with a letter.");
    if (!conv || typeof conv !== "object" || typeof conv.nodes !== "object" || Array.isArray(conv.nodes) || typeof conv.start !== "string") {
      report(at, `conversation '${id}' needs a 'start' node id and a 'nodes' object`, `Write "${id}": { "start": "dlg.${id}.first", "nodes": { "dlg.${id}.first": { ... } } }.`);
      continue;
    }
    const nodes = conv.nodes;
    const nodeIds = Object.keys(nodes);
    if (!nodeIds.includes(conv.start)) report(`${at}/start`, `conversation '${id}' starts at '${conv.start}', which is not one of its nodes`, suggest(conv.start, nodeIds, "Nodes"), near(conv.start, nodeIds));
    const targetOk = (to, pointer, what) => {
      if (typeof to !== "string" || to === "") {
        report(pointer, `${what} has no target`, `Point it at a node id of this conversation, or at "${END}" to end the conversation.`);
        return false;
      }
      if (to !== END && !nodeIds.includes(to)) {
        report(pointer, `${what} leads to '${to}', which is not a node of '${id}'`, suggest(to, nodeIds, "Nodes"), near(to, nodeIds));
        return false;
      }
      return true;
    };
    /** node id -> the ids it leads to (for reachability) */
    const edges = new Map();

    for (const [nodeId, node] of Object.entries(nodes)) {
      const nat = `${at}/nodes/${nodeId.replace(/~/g, "~0").replace(/\//g, "~1")}`;
      const out = [];
      edges.set(nodeId, out);
      if (!node || typeof node !== "object" || Array.isArray(node)) {
        report(nat, `node '${nodeId}' is not an object`, 'A line is { "speaker": "mara", "next": "..." }, a route is { "route": [ { "to": "..." } ] }.');
        continue;
      }
      const prefix = `dlg.${id}.`;
      if (!nodeId.startsWith(prefix) || !/^[a-z][a-z0-9_]*$/.test(nodeId.slice(prefix.length))) {
        report(nat, `node id '${nodeId}' does not look like '${prefix}<name>'`, `A node id is the locale key of its text: "${prefix}greet" with the text under dlg.${id}.greet in locales/en.json (route nodes follow the same rule).`);
      }
      (node.effects ?? []).forEach((fx, i) => {
        const e = checkEffect(fx, vocab, ctx, report, `${nat}/effects/${i}`, `node '${nodeId}'`);
        if (e.ok && e.kind === "end" && node.route) report(`${nat}/effects/${i}`, `route node '${nodeId}' ends the conversation`, "Put the end effect on a line, a route shows nothing.");
        if (e.ok && e.kind === "end" && node.choices?.length) report(`${nat}/effects/${i}`, `node '${nodeId}' has choices and an end effect`, "End the conversation from a choice's effects, or drop the choices.");
      });
      if (node.route !== undefined) {
        // ROUTE
        if (!Array.isArray(node.route) || node.route.length === 0) {
          report(`${nat}/route`, `route node '${nodeId}' has no branches`, 'Write "route": [ { "if": ["flag"], "to": "dlg..." }, { "to": "dlg..." } ].');
          continue;
        }
        if (node.speaker || node.choices || node.next || node.text) report(nat, `route node '${nodeId}' also has line fields`, "A route shows nothing: remove speaker, choices, next and text, or make it a line.");
        node.route.forEach((r, i) => {
          const rat = `${nat}/route/${i}`;
          (r?.if ?? []).forEach((c, j) => checkCondition(c, vocab, ctx, report, `${rat}/if/${j}`, `route '${nodeId}'`));
          if (targetOk(r?.to, `${rat}/to`, `branch ${i} of route '${nodeId}'`) && r.to !== END) out.push(r.to);
        });
        const last = node.route[node.route.length - 1];
        if (last?.if?.length) report(`${nat}/route/${node.route.length - 1}`, `the last branch of route '${nodeId}' has a condition`, "End the route with a branch that has no 'if', so some branch always holds.");
        continue;
      }
      // LINE
      if (typeof node.speaker !== "string" || !vocab.speakers.includes(node.speaker)) {
        report(`${nat}/speaker`, `node '${nodeId}' has the speaker ${JSON.stringify(node.speaker)}, who is not in data/cast.json`, suggest(node.speaker, vocab.speakers, "Speakers"), near(node.speaker ?? "", vocab.speakers));
      }
      if (node.voice !== undefined && (typeof node.voice !== "string" || !/^[a-z][a-z0-9_]*$/.test(node.voice))) report(`${nat}/voice`, `node '${nodeId}' has the voice id ${JSON.stringify(node.voice)}`, "A voice clip id is snake_case (P4 plays it); leave it out when there is none.");
      if (ctx.strings && !hasKey(ctx.strings, nodeId)) report(nat, `the text of node '${nodeId}' is missing: no string '${nodeId}' in locales/en.json`, "Add the line to locales/en.json (and to every other language).");
      const hasChoices = Array.isArray(node.choices) && node.choices.length > 0;
      const ends = (node.effects ?? []).some((fx) => fx && fx.end === true);
      if (node.choices !== undefined && !hasChoices) report(`${nat}/choices`, `node '${nodeId}' has an empty 'choices' list`, "Remove it, or add at least one choice.");
      if (!hasChoices && node.next === undefined && !ends) report(nat, `node '${nodeId}' leads nowhere: no 'next', no 'choices' and no end effect`, `Add "next": "<node id>", or "next": "${END}" to end the conversation here.`);
      if (node.next !== undefined && targetOk(node.next, `${nat}/next`, `node '${nodeId}'`) && node.next !== END) out.push(node.next);
      if (hasChoices) {
        const seen = new Set();
        let unconditional = false;
        node.choices.forEach((c, i) => {
          const cat = `${nat}/choices/${i}`;
          if (!c || typeof c !== "object") {
            report(cat, `choice ${i} of '${nodeId}' is not an object`, '{ "id": "yes", "text": "dlg.x.y_c1", "next": "dlg.x.z" }');
            return;
          }
          if (typeof c.id !== "string" || !/^[a-z][a-z0-9_]*$/.test(c.id)) report(`${cat}/id`, `choice ${i} of '${nodeId}' has the id ${JSON.stringify(c.id)}`, "A choice id is snake_case and unique in the node: the story bot and the saves name choices by it.");
          else if (seen.has(c.id)) report(`${cat}/id`, `node '${nodeId}' has two choices with the id '${c.id}'`, "Choice ids are unique inside a node.");
          else seen.add(c.id);
          if (typeof c.text !== "string" || c.text === "") report(`${cat}/text`, `choice ${i} of '${nodeId}' has no text key`, `Add "text": "${nodeId}_c${i + 1}" and the string in locales/en.json.`);
          else if (ctx.strings && !hasKey(ctx.strings, c.text)) report(`${cat}/text`, `the text of choice '${c.id ?? i}' of '${nodeId}' is missing: no string '${c.text}' in locales/en.json`, "Add it to locales/en.json (and to every other language).");
          (c.if ?? []).forEach((cond, j) => checkCondition(cond, vocab, ctx, report, `${cat}/if/${j}`, `choice '${c.id ?? i}' of '${nodeId}'`));
          if (!(c.if?.length > 0)) unconditional = true;
          (c.effects ?? []).forEach((fx, j) => {
            const e = checkEffect(fx, vocab, ctx, report, `${cat}/effects/${j}`, `choice '${c.id ?? i}' of '${nodeId}'`);
            if (e.ok && e.kind === "end" && c.next !== undefined && c.next !== END) report(`${cat}/effects/${j}`, `choice '${c.id ?? i}' of '${nodeId}' ends the conversation and also leads to '${c.next}'`, `Drop the end effect or point "next" at "${END}".`);
          });
          const endsHere = (c.effects ?? []).some((fx) => fx && fx.end === true);
          if (c.next === undefined && !endsHere) report(`${cat}/next`, `choice '${c.id ?? i}' of '${nodeId}' has no target`, `Add "next": "<node id>", or "next": "${END}" to end the conversation.`);
          else if (c.next !== undefined && targetOk(c.next, `${cat}/next`, `choice '${c.id ?? i}' of '${nodeId}'`) && c.next !== END) out.push(c.next);
        });
        if (!unconditional && node.next === undefined) report(`${nat}/choices`, `every choice of '${nodeId}' has a condition and the node has no fallback 'next'`, 'Add a choice without "if", or a "next" the runner follows when all the choices are hidden.');
      }
    }

    // Reachability from the start node.
    if (nodeIds.includes(conv.start)) {
      const reached = new Set([conv.start]);
      const queue = [conv.start];
      while (queue.length) {
        for (const to of edges.get(queue.pop()) ?? []) {
          if (!reached.has(to) && nodeIds.includes(to)) {
            reached.add(to);
            queue.push(to);
          }
        }
      }
      for (const nodeId of nodeIds) {
        if (!reached.has(nodeId)) report(`${at}/nodes/${nodeId.replace(/~/g, "~0").replace(/\//g, "~1")}`, `node '${nodeId}' can never be reached from the start '${conv.start}'`, "Point a next, a choice or a route branch at it, or delete it (and its strings).");
      }
    }
  }

  // Conversations nobody starts, and the cast's talk table.
  const entries = new Set(opts.entries ?? []);
  const castFile = "data/cast.json";
  const castReport = makeReporter(castFile, problems);
  for (const [cid, ch] of Object.entries(ctx.cast?.characters ?? {})) {
    for (const [chapter, conv] of Object.entries(ch?.talk ?? {})) {
      if (!owner.has(conv)) castReport(`/characters/${cid}/talk/${chapter}`, `${cid} talks '${conv}' in chapter ${chapter}, but no table defines that conversation`, suggest(conv, [...owner.keys()], "Conversations"), near(conv, [...owner.keys()]));
      entries.add(conv);
    }
  }
  if (ctx.cast) {
    for (const { file, id } of all) {
      if (!entries.has(id)) makeReporter(file, problems)(`/conversations/${id}`, `the conversation '${id}' is never started: no character in data/cast.json talks it and no scene names it`, "Add it to a character's 'talk' table, or delete it.");
    }
  }
  return problems;
}

/**
 * Checks data/story.json: the flag registry, the chapters, the endings and the places the cast stands at.
 * @param {any} story
 * @param {Context} ctx strings, areas (the area ids of scripts/area.js), items
 * @returns {Problem[]}
 */
export function validateStory(story, ctx = {}) {
  /** @type {Problem[]} */
  const problems = [];
  const file = "data/story.json";
  const report = makeReporter(file, problems);
  if (!story || typeof story !== "object") {
    report("", "the file must be an object", 'Start it with { "format": "larkspur.story/1", "flags": {}, "flagPrefixes": {}, "chapters": [], "endings": {}, "places": {} }');
    return problems;
  }
  if (story.format !== "larkspur.story/1") report("/format", `format is '${story.format}'`, 'Set "format": "larkspur.story/1".');
  const vocab = vocabulary({ ...ctx, story });
  const flags = story.flags ?? {};
  for (const [name, decl] of Object.entries(flags)) {
    if (!/^[a-z][a-z0-9_]*$/.test(name)) report(`/flags/${name}`, `flag '${name}' is not snake_case`, "Declared flags use lower-case letters, digits and underscores; dotted names are prefixes (flagPrefixes).");
    if (!decl || !["boolean", "number", "string"].includes(decl.type)) report(`/flags/${name}/type`, `flag '${name}' has the type ${JSON.stringify(decl?.type)}`, 'Use "type": "boolean", "number" or "string".');
    if (!decl || typeof decl.doc !== "string" || decl.doc.length < 8) report(`/flags/${name}/doc`, `flag '${name}' has no doc string`, 'Say who sets it and who reads it: "doc": "Set by ch2_tobias when ...; read by ...".');
  }
  for (const [prefix, doc] of Object.entries(story.flagPrefixes ?? {})) {
    if (!/^[a-z][a-z0-9_]*\.$/.test(prefix)) report(`/flagPrefixes/${prefix}`, `prefix '${prefix}' must be a lower-case word ending with a dot`, 'Write "talked.": "doc".');
    if (typeof doc !== "string" || doc.length < 8) report(`/flagPrefixes/${prefix}`, `prefix '${prefix}' has no doc string`, "Say what the dotted flags mean.");
  }
  const chapters = story.chapters;
  if (!Array.isArray(chapters) || chapters.length === 0) report("/chapters", "the story has no chapters", 'Add "chapters": [ { "id": 1, "titleKey": "chapter.1.title", "introKey": "chapter.1.intro", "advance": ["vale_missing"] } ].');
  else {
    chapters.forEach((ch, i) => {
      const at = `/chapters/${i}`;
      if (ch?.id !== i + 1) report(`${at}/id`, `chapter ${i + 1} has the id ${JSON.stringify(ch?.id)}`, "Chapters are numbered 1, 2, 3 ... in order.");
      for (const field of ["titleKey", "introKey"]) {
        if (typeof ch?.[field] !== "string") report(`${at}/${field}`, `chapter ${i + 1} has no ${field}`, `Add "${field}": "chapter.${i + 1}.${field === "titleKey" ? "title" : "intro"}" and the string in locales/en.json.`);
        else if (ctx.strings && !hasKey(ctx.strings, ch[field])) report(`${at}/${field}`, `chapter ${i + 1}: no string '${ch[field]}' in locales/en.json`, "Add it to locales/en.json.");
      }
      const last = i === chapters.length - 1;
      if (last) {
        if (ch?.final !== true) report(`${at}/final`, `the last chapter (${i + 1}) is not marked final`, 'Add "final": true: the last chapter has no "advance", the story ends in a conversation.');
        if (ch?.advance !== undefined) report(`${at}/advance`, `the final chapter ${i + 1} has 'advance' conditions`, "Remove them: nothing follows the final chapter.");
      } else if (ch?.final) report(`${at}/final`, `chapter ${i + 1} is marked final but chapter ${i + 2} follows`, "Only the last chapter is final.");
      else if (!Array.isArray(ch?.advance) || ch.advance.length === 0) report(`${at}/advance`, `chapter ${i + 1} has no 'advance' conditions`, "List the conditions that end the chapter: [\"vale_missing\"].");
      else ch.advance.forEach((c, j) => checkCondition(c, vocab, ctx, report, `${at}/advance/${j}`, `chapter ${i + 1}`));
      (ch?.enter ?? []).forEach((fx, j) => checkEffect(fx, vocab, ctx, report, `${at}/enter/${j}`, `chapter ${i + 1}`));
      if (ch?.start !== undefined) {
        if (ctx.areas && !ctx.areas.includes(ch.start?.area)) report(`${at}/start/area`, `chapter ${i + 1} starts in the area ${JSON.stringify(ch.start?.area)}`, suggest(ch.start?.area ?? "", ctx.areas, "Areas"), near(ch.start?.area ?? "", ctx.areas));
        if (typeof ch.start?.spawn !== "string" || ch.start.spawn === "") report(`${at}/start/spawn`, `chapter ${i + 1} names no spawn`, 'Write "start": { "area": "ground", "spawn": "spawn_default" }: the id of a spawn entity of that area.');
      }
    });
  }
  const endings = story.endings ?? {};
  if (Object.keys(endings).length === 0) report("/endings", "the story has no endings", 'Add "endings": { "dawn": { "titleKey": "ending.dawn.title", "textKey": "ending.dawn.text" } }.');
  for (const [id, e] of Object.entries(endings)) {
    for (const field of ["titleKey", "textKey"]) {
      if (typeof e?.[field] !== "string") report(`/endings/${id}/${field}`, `ending '${id}' has no ${field}`, `Add "${field}": "ending.${id}.${field === "titleKey" ? "title" : "text"}".`);
      else if (ctx.strings && !hasKey(ctx.strings, e[field])) report(`/endings/${id}/${field}`, `ending '${id}': no string '${e[field]}' in locales/en.json`, "Add it to locales/en.json.");
    }
  }
  for (const [name, p] of Object.entries(story.places ?? {})) {
    const at = `/places/${name}`;
    if (ctx.areas && !ctx.areas.includes(p?.area)) report(`${at}/area`, `place '${name}' is in the area ${JSON.stringify(p?.area)}`, suggest(p?.area ?? "", ctx.areas, "Areas"), near(p?.area ?? "", ctx.areas));
    if (typeof p?.x !== "number" || typeof p?.z !== "number") report(at, `place '${name}' needs numbers x and z (metres)`, 'Write "hall_center": { "area": "ground", "x": 15, "z": 19.2, "yaw": 180 }.');
    if (typeof p?.yaw !== "number") report(`${at}/yaw`, `place '${name}' needs a yaw in degrees`, "yaw 0 faces -Z, 90 faces -X, 180 faces +Z, 270 faces +X.");
  }
  return problems;
}

/**
 * Checks data/cast.json against the story registry (places, chapters) and the locale strings.
 * @param {any} cast
 * @param {Context} ctx strings, story
 * @returns {Problem[]}
 */
export function validateCast(cast, ctx = {}) {
  /** @type {Problem[]} */
  const problems = [];
  const report = makeReporter("data/cast.json", problems);
  if (!cast || typeof cast !== "object" || typeof cast.characters !== "object") {
    report("", "the file must be an object with a 'characters' object", 'Start it with { "format": "larkspur.cast/1", "characters": { "mara": { ... } } }');
    return problems;
  }
  if (cast.format !== "larkspur.cast/1") report("/format", `format is '${cast.format}'`, 'Set "format": "larkspur.cast/1".');
  const places = Object.keys(ctx.story?.places ?? {});
  const chapterCount = ctx.story?.chapters?.length ?? 0;
  for (const [id, ch] of Object.entries(cast.characters)) {
    const at = `/characters/${id}`;
    if (!/^[a-z][a-z0-9_]*$/.test(id) || EXTRA_SPEAKERS.includes(id)) report(at, `character id '${id}' is not allowed`, `Use a snake_case name that is not ${EXTRA_SPEAKERS.join(" or ")}.`);
    if (typeof ch?.nameKey !== "string") report(`${at}/nameKey`, `character '${id}' has no nameKey`, `Add "nameKey": "cast.${id}.name" and the string.`);
    else if (ctx.strings && !hasKey(ctx.strings, ch.nameKey)) report(`${at}/nameKey`, `no string '${ch.nameKey}' in locales/en.json`, "Add the name to locales/en.json.");
    if (!BODIES.includes(ch?.body)) report(`${at}/body`, `character '${id}' has the body ${JSON.stringify(ch?.body)}`, suggest(ch?.body ?? "", BODIES, "Bodies"), near(ch?.body ?? "", BODIES));
    if (!Array.isArray(ch?.tint) || ch.tint.length !== 4 || ch.tint.some((v) => typeof v !== "number" || v < 0 || v > 1)) report(`${at}/tint`, `character '${id}' has the tint ${JSON.stringify(ch?.tint)}`, "A tint is [r, g, b, a] with numbers between 0 and 1.");
    for (const [chapter, place] of Object.entries(ch?.schedule ?? {})) {
      if (!/^[1-9]$/.test(chapter) || Number(chapter) > chapterCount) report(`${at}/schedule/${chapter}`, `'${chapter}' is not a chapter of the story`, `Chapters are 1 to ${chapterCount}.`);
      if (!places.includes(place)) report(`${at}/schedule/${chapter}`, `${id} stands at '${place}' in chapter ${chapter}, which is not in data/story.json places`, suggest(place, places, "Places"), near(place, places));
    }
    for (const chapter of Object.keys(ch?.talk ?? {})) {
      if (!(ch.schedule ?? {})[chapter]) report(`${at}/talk/${chapter}`, `${id} has a conversation in chapter ${chapter} but no place to stand at`, `Add "${chapter}" to ${id}'s schedule.`);
    }
  }
  return problems;
}

/** One line per problem: "file pointer: message. hint". */
export function describe(problems) {
  return problems.map((p) => `${p.file} ${p.pointer || "(file)"}: ${p.message}. ${p.hint}`).join("\n");
}
