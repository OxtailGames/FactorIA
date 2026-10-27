// @ts-check
// The small language of the dialogue tables (data/dialogue/*.json) and of the chapters (data/story.json): conditions that read the
// story flags and the inventory, and effects that change them. Pure: nothing here touches the game, the caller passes an `env`.
//
// A condition is a string; a list of them means "all of them":
//   "vale_missing"            the flag is set (true, a number other than 0, a non-empty string)
//   "!vale_missing"           the flag is not set
//   "interviews>=3"           a number flag compared with a number: =  !=  >  >=  <  <=
//   "ending=dawn"             a string flag equals a word; "storm_over=true" a boolean
//   "item:guest_ledger"       the porter carries the item;   "!item:guest_ledger"  he does not
//
// An effect is an object with ONE of these keys:
//   { "set": "flag", "value": true }   sets a flag (value defaults to true; a number, a string or a boolean)
//   { "add": "flag", "by": 1 }         adds to a number flag (by defaults to 1)
//   { "give": "item" }  { "take": "item" }   puts an item in the inventory, or takes it out
//   { "cutscene": "id" }               asks the cut-scene player (scripts/cutscene.js) for a cut-scene
//   { "end": true }                    ends the conversation after this node
//
// env = { get(flag, fallback), hasItem(id) } for conditions; the runner's own env adds set/give/take/cutscene for effects.

/** Operators of a comparison, longest first. */
export const OPERATORS = Object.freeze([">=", "<=", "!=", "=", ">", "<"]);

/** The keys an effect may have as its main key. */
export const EFFECT_KEYS = Object.freeze(["set", "add", "give", "take", "cutscene", "end"]);

const FLAG = "[a-z][a-z0-9_.]*";
const CONDITION = new RegExp(`^(!)?(item:)?(${FLAG})(?:(>=|<=|!=|=|>|<)(.+))?$`);

/**
 * @typedef {{ negate: boolean, item: boolean, name: string, op: string, value: any }} Condition
 * @typedef {{ ok: true, cond: Condition } | { ok: false, message: string, hint: string }} ParsedCondition
 */

/** Parses one condition string. Never throws: a bad one gives { ok: false, message, hint }. */
export function parseCondition(text) {
  if (typeof text !== "string" || text.trim() === "") {
    return { ok: false, message: `a condition must be a non-empty string, not ${JSON.stringify(text)}`, hint: 'Write "flag_name", "!flag_name", "count>=2" or "item:item_id".' };
  }
  const m = CONDITION.exec(text.replace(/\s+/g, ""));
  if (!m) {
    return { ok: false, message: `'${text}' is not a condition`, hint: 'Write "flag_name", "!flag_name", "interviews>=3", "ending=dawn" or "item:guest_ledger" (lower-case names with digits, "_" and ".").' };
  }
  const [, bang, item, name, op, raw] = m;
  if (item && op) return { ok: false, message: `'${text}' compares an item`, hint: 'An item is only carried or not: write "item:id" or "!item:id".' };
  if (bang && op) return { ok: false, message: `'${text}' has both "!" and a comparison`, hint: `Use the opposite operator instead: "${name}!=${raw}".` };
  /** @type {any} */
  let value = undefined;
  if (op) {
    if (raw === "true") value = true;
    else if (raw === "false") value = false;
    else if (/^-?\d+(\.\d+)?$/.test(raw)) value = Number(raw);
    else value = raw;
    if ((op === ">" || op === ">=" || op === "<" || op === "<=") && typeof value !== "number") {
      return { ok: false, message: `'${text}' orders a value that is not a number`, hint: 'Only numbers can be compared with > >= < <=; use "=" or "!=" for words.' };
    }
  }
  return { ok: true, cond: { negate: !!bang, item: !!item, name, op: op ?? "", value } };
}

/** @param {Condition} cond @param {{ get(flag: string, fallback?: any): any, hasItem(id: string): boolean }} env */
export function evalCondition(cond, env) {
  if (cond.item) return env.hasItem(cond.name) !== cond.negate;
  const have = env.get(cond.name, false);
  if (!cond.op) return !!have !== cond.negate;
  const a = typeof cond.value === "number" ? Number(have || 0) : have;
  switch (cond.op) {
    case "=": return a === cond.value;
    case "!=": return a !== cond.value;
    case ">": return a > cond.value;
    case ">=": return a >= cond.value;
    case "<": return a < cond.value;
    case "<=": return a <= cond.value;
    default: return false;
  }
}

/** True when every condition string of `list` holds (an empty or missing list holds). A string that does not parse throws: the validator catches those first. */
export function holds(list, env) {
  for (const text of list ?? []) {
    const p = parseCondition(text);
    if (!p.ok) throw new Error(`condition '${text}': ${p.message}. ${p.hint}`);
    if (!evalCondition(p.cond, env)) return false;
  }
  return true;
}

/**
 * Looks at one effect object. Returns { ok: true, kind, target, value } or { ok: false, message, hint }.
 * `target` is the flag, item or cut-scene id; `value` the value to set or the amount to add.
 */
export function parseEffect(fx) {
  if (!fx || typeof fx !== "object" || Array.isArray(fx)) {
    return { ok: false, message: `an effect must be an object, not ${JSON.stringify(fx)}`, hint: `Use one of ${EFFECT_KEYS.map((k) => `"${k}"`).join(", ")}, e.g. { "set": "vale_missing" }.` };
  }
  const keys = Object.keys(fx).filter((k) => EFFECT_KEYS.includes(k));
  const unknown = Object.keys(fx).filter((k) => !EFFECT_KEYS.includes(k) && k !== "value" && k !== "by");
  if (keys.length !== 1) {
    return { ok: false, message: keys.length ? `an effect has several actions (${keys.join(", ")})` : `an effect names no action${unknown.length ? ` (unknown key '${unknown[0]}')` : ""}`, hint: `Put exactly one of ${EFFECT_KEYS.map((k) => `"${k}"`).join(", ")} in each effect object.` };
  }
  if (unknown.length) return { ok: false, message: `an effect has the unknown key '${unknown[0]}'`, hint: `Keys: ${[...EFFECT_KEYS, "value", "by"].join(", ")}.` };
  const kind = keys[0];
  if (kind === "end") return { ok: true, kind, target: "", value: true };
  const target = fx[kind];
  if (typeof target !== "string" || target === "") return { ok: false, message: `"${kind}" needs a name, not ${JSON.stringify(target)}`, hint: `Write { "${kind}": "name" }.` };
  if (kind === "add") {
    const by = fx.by ?? 1;
    if (typeof by !== "number") return { ok: false, message: `"by" must be a number, not ${JSON.stringify(by)}`, hint: 'Write { "add": "flag", "by": 1 }.' };
    return { ok: true, kind, target, value: by };
  }
  if (kind === "set") {
    const value = fx.value ?? true;
    if (!["boolean", "number", "string"].includes(typeof value)) return { ok: false, message: `"value" must be a boolean, a number or a string, not ${JSON.stringify(value)}`, hint: 'Write { "set": "flag", "value": 2 }.' };
    return { ok: true, kind, target, value };
  }
  return { ok: true, kind, target, value: true };
}
