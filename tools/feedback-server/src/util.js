// Small helpers shared by the server modules: base64url, HMAC (WebCrypto, the same in Workers and Node), constant-time
// comparison, JSON responses and the error shape {ok:false, error:{code, message, hint}}.

const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function base64url(bytes) {
    let bin = "";
    for (const b of bytes) bin += String.fromCharCode(b);
    return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function base64urlDecode(text) {
    if (typeof text !== "string" || !/^[A-Za-z0-9_-]*$/.test(text)) return null;
    try {
        const bin = atob(text.replace(/-/g, "+").replace(/_/g, "/"));
        const out = new Uint8Array(bin.length);
        for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
        return out;
    } catch {
        return null;
    }
}

export function utf8(text) {
    return encoder.encode(text);
}

export function utf8Decode(bytes) {
    return decoder.decode(bytes);
}

const keyCache = new Map();

async function hmacKey(secret) {
    let key = keyCache.get(secret);
    if (!key) {
        key = await crypto.subtle.importKey("raw", utf8(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
        if (keyCache.size > 8) keyCache.clear();
        keyCache.set(secret, key);
    }
    return key;
}

/** HMAC-SHA-256 of `message` under `secret`, as raw bytes. */
export async function hmac(secret, message) {
    const sig = await crypto.subtle.sign("HMAC", await hmacKey(secret), utf8(message));
    return new Uint8Array(sig);
}

/** Constant-time comparison of two strings: hashes both first so the length does not leak either. */
export async function safeEqual(a, b) {
    const [ha, hb] = await Promise.all([
        crypto.subtle.digest("SHA-256", utf8(String(a))),
        crypto.subtle.digest("SHA-256", utf8(String(b))),
    ]);
    const x = new Uint8Array(ha);
    const y = new Uint8Array(hb);
    let diff = 0;
    for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
    return diff === 0;
}

export class ApiError extends Error {
    constructor(status, code, message, hint, headers) {
        super(message);
        this.status = status;
        this.code = code;
        this.hint = hint;
        this.headers = headers || {};
    }
}

export function json(status, body, headers) {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...(headers || {}) },
    });
}

export function errorResponse(err) {
    return json(
        err.status,
        { ok: false, error: { code: err.code, message: err.message, hint: err.hint } },
        err.headers,
    );
}

/** Levenshtein distance, for "did you mean" on enum values. */
function distance(a, b) {
    const row = Array.from({ length: b.length + 1 }, (_, i) => i);
    for (let i = 1; i <= a.length; i++) {
        let prev = row[0];
        row[0] = i;
        for (let j = 1; j <= b.length; j++) {
            const tmp = row[j];
            row[j] = Math.min(row[j] + 1, row[j - 1] + 1, prev + (a[i - 1] === b[j - 1] ? 0 : 1));
            prev = tmp;
        }
    }
    return row[b.length];
}

/** The allowed value closest to `value`, or null when none is close. */
export function didYouMean(value, allowed) {
    const v = String(value).toLowerCase();
    let best = null;
    let bestDist = Infinity;
    for (const a of allowed) {
        const d = distance(v, a);
        if (d < bestDist) {
            best = a;
            bestDist = d;
        }
    }
    return best !== null && bestDist <= Math.max(2, Math.floor(best.length / 3)) ? best : null;
}

/** UTC day as YYYY-MM-DD. */
export function utcDay(ms) {
    return new Date(ms).toISOString().slice(0, 10);
}

/** Epoch ms of the next midnight UTC after `ms`. */
export function nextMidnight(ms) {
    const d = new Date(ms);
    return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + 1);
}
