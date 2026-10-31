// Validation of one report entry and the title normalization used to merge similar reports of an installation.
// The limits are the "Field limits" table of docs/design/FEEDBACK_SHARING.md.

import { didYouMean } from "./util.js";

export const CATEGORIES = [
    "rendering-2d", "rendering-3d", "physics", "audio", "input", "ui", "scripting", "scene", "assets", "animation",
    "tooling", "ai-integration", "docs", "platform", "performance", "networking", "other",
];
export const SEVERITIES = ["blocker", "major", "minor", "nice-to-have"];
export const EFFORTS = ["small", "medium", "large"];
export const REPORTER_KINDS = ["ai", "human"];
export const PLATFORMS = ["macos", "windows", "linux", "web", "other"];

export const LIMITS = {
    title: { min: 8, max: 120 },
    missing: { min: 20, max: 1500 },
    suggestion: { min: 0, max: 1500 },
    workaround: { min: 0, max: 1500 },
};

const LOCAL_ID = /^[A-Za-z0-9_.:-]{1,64}$/;
const CONTROL = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F-\u009F]/u;
const URL_LIKE = /(?:[a-z][a-z0-9+.-]*:\/\/|\bwww\.|\bmailto:|\b[a-z0-9-]+\.(?:com|net|org|io|dev|app|gg|xyz|info)\b)/iu;
const EMAIL = /[^\s@]+@[^\s@]+\.[^\s@]+/u;
const REPEAT = /(.)\1{8,}/su;

class Rejection extends Error {
    constructor(code, reason, hint) {
        super(reason);
        this.code = code;
        this.hint = hint;
    }
}

function codePoints(text) {
    return Array.from(text).length;
}

function checkEnum(entry, field, allowed, required) {
    const value = entry[field];
    if (value === undefined || value === null) {
        if (required) {
            throw new Rejection("invalid_field", `${field} is required`, `Set ${field} to one of: ${allowed.join(", ")}.`);
        }
        return null;
    }
    if (typeof value !== "string" || !allowed.includes(value)) {
        const guess = typeof value === "string" ? didYouMean(value, allowed) : null;
        throw new Rejection(
            "invalid_field",
            `${field} must be one of: ${allowed.join(", ")}`,
            guess ? `Did you mean "${guess}"?` : `Use one of the listed values for ${field}.`,
        );
    }
    return value;
}

function checkText(entry, field) {
    const { min, max } = LIMITS[field];
    let value = entry[field];
    if (value === undefined || value === null) {
        if (min > 0) throw new Rejection("invalid_field", `${field} is required`, `Send ${field} as a string of ${min} to ${max} characters.`);
        return "";
    }
    if (typeof value !== "string") {
        throw new Rejection("invalid_field", `${field} must be a string`, `Send ${field} as a string of ${min} to ${max} characters.`);
    }
    value = value.trim();
    if (value === "" && min === 0) return "";
    const length = codePoints(value);
    if (length < min) {
        throw new Rejection("too_short", `${field} needs at least ${min} characters`, `Describe the gap in more detail (${field}: ${min} to ${max} characters).`);
    }
    if (length > max) {
        throw new Rejection("too_long", `${field} has at most ${max} characters`, `Shorten ${field} to ${max} characters or fewer.`);
    }
    if (CONTROL.test(value) || (field === "title" && /[\r\n]/.test(value))) {
        throw new Rejection("not_text", `${field} contains control characters`, `Send ${field} as plain text${field === "title" ? " on one line" : ""}.`);
    }
    if (URL_LIKE.test(value) || EMAIL.test(value)) {
        throw new Rejection(
            "personal_data",
            `${field} contains a URL or an e-mail address`,
            "Describe the engine gap without links or addresses; they can identify a person or a game.",
        );
    }
    if (REPEAT.test(value)) {
        throw new Rejection("not_text", `${field} repeats a character more than 8 times`, `Write ${field} as normal sentences.`);
    }
    const compact = Array.from(value.replace(/\s/gu, ""));
    const letters = compact.filter((c) => /\p{L}/u.test(c)).length;
    if (compact.length === 0 || letters / compact.length < 0.6) {
        throw new Rejection("not_text", `${field} must be at least 60% letters`, `Write ${field} as a sentence in words, not as code or symbols.`);
    }
    if (field === "missing") {
        const words = value.split(/\s+/u).filter((w) => /\p{L}/u.test(w));
        if (words.length < 4) {
            throw new Rejection("not_text", "missing needs at least 4 words", "Say what the engine lacks and what you wanted to do, in a full sentence.");
        }
    }
    return value;
}

/**
 * Validate one entry. Returns {ok:true, entry} with the clean fields, or {ok:false, code, reason, hint}.
 * Fields that are not part of the contract are dropped.
 */
export function validateEntry(raw) {
    try {
        if (!raw || typeof raw !== "object" || Array.isArray(raw)) {
            throw new Rejection("invalid_field", "an entry must be an object", "Send each entry as {localId, category, severity, title, missing, ...}.");
        }
        if (typeof raw.localId !== "string" || !LOCAL_ID.test(raw.localId)) {
            throw new Rejection("invalid_field", "localId must be a string of 1 to 64 letters, digits or . _ : -", 'Use the id of the local entry, for example "FB-0003".');
        }
        const category = checkEnum(raw, "category", CATEGORIES, true);
        const severity = checkEnum(raw, "severity", SEVERITIES, true);
        const effort = checkEnum(raw, "effort", EFFORTS, false);
        const reporterKind = checkEnum(raw, "reporterKind", REPORTER_KINDS, false);
        if (raw.reviewed !== undefined && typeof raw.reviewed !== "boolean") {
            throw new Rejection("invalid_field", "reviewed must be true or false", "Send reviewed as a boolean, or leave it out.");
        }
        const title = checkText(raw, "title");
        const missing = checkText(raw, "missing");
        const suggestion = checkText(raw, "suggestion");
        const workaround = checkText(raw, "workaround");
        return {
            ok: true,
            entry: {
                localId: raw.localId, category, severity, effort, reporterKind, reviewed: raw.reviewed === true,
                title, missing, suggestion, workaround,
            },
        };
    } catch (e) {
        if (e instanceof Rejection) return { ok: false, code: e.code, reason: e.message, hint: e.hint };
        throw e;
    }
}

const FILLER = new Set([
    "a", "an", "the", "of", "for", "to", "in", "on", "at", "and", "or", "is", "are", "be", "there", "no", "not", "missing",
    "lack", "lacks", "support", "supports", "with", "without", "add", "need", "needs", "cannot", "cant", "can",
]);

function tokens(text, dropFiller) {
    return text
        .toLowerCase()
        .replace(/[^\p{L}\p{N}]+/gu, " ")
        .split(" ")
        .filter((t) => t && (!dropFiller || !FILLER.has(t)))
        .map((t) => (t.length > 3 && t.endsWith("s") && !t.endsWith("ss") ? t.slice(0, -1) : t));
}

/** Lower case, punctuation and filler words dropped, plural "s" removed: "No one-way platforms" -> "one way platform". */
export function normalizeTitle(title) {
    let t = tokens(title, true);
    if (t.length === 0) t = tokens(title, false);
    return t.join(" ");
}

/** Whether two normalized titles say the same thing: equal word sets, or at least 75% of the words shared. */
export function similarTitles(a, b) {
    if (a === b) return true;
    const sa = new Set(a.split(" ").filter(Boolean));
    const sb = new Set(b.split(" ").filter(Boolean));
    if (sa.size === 0 || sb.size === 0) return false;
    let shared = 0;
    for (const t of sa) if (sb.has(t)) shared++;
    return shared / (sa.size + sb.size - shared) >= 0.75;
}
