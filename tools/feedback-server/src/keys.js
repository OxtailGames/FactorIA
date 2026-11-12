// The keys the server derives (docs/design/FEEDBACK_SHARING.md, "Keys the server derives") and the credential a GitHub
// sign-in returns. Raw installation ids, IP addresses, GitHub ids and logins are only ever inputs to these functions.

import { base64url, base64urlDecode, hmac, safeEqual, utf8, utf8Decode } from "./util.js";

export const KEY_PATTERN = /^[A-Za-z0-9_-]{16}$/;

/** base64url(HMAC(secret, "install:" + installId))[0..16] */
export async function installKey(secret, installId) {
    return base64url(await hmac(secret, "install:" + installId)).slice(0, 16);
}

/** base64url(HMAC(secret, "github:" + githubUserId))[0..16] */
export async function reporterKey(secret, githubUserId) {
    return base64url(await hmac(secret, "github:" + githubUserId)).slice(0, 16);
}

/**
 * The address a rate-limit bucket is keyed on. An IPv4 address stays as it is, an IPv4-mapped IPv6 address
 * (::ffff:a.b.c.d) becomes that IPv4 address, and any other IPv6 address becomes its /64 prefix (the first four hextets,
 * "::" expanded, lower case), so one host cannot get fresh buckets by rotating through its own /64. Anything else is kept.
 * Malformed input is keyed as it is on purpose: Cloudflare sets the header, so a malformed value is not a client's choice and
 * it still gets a bucket of its own (rejecting it would only add a failure path).
 */
export function networkOf(ip) {
    let a = String(ip).trim().toLowerCase();
    const zone = a.indexOf("%");
    if (zone >= 0) a = a.slice(0, zone);
    if (!a.includes(":")) return a;
    let tail = null;
    const dot = a.lastIndexOf(".");
    if (dot >= 0) {
        const colon = a.lastIndexOf(":");
        const v4 = a.slice(colon + 1).split(".");
        if (v4.length !== 4 || v4.some((x) => !/^\d{1,3}$/.test(x) || Number(x) > 255)) return a;
        const n = v4.map(Number);
        tail = [((n[0] << 8) | n[1]).toString(16), ((n[2] << 8) | n[3]).toString(16)];
        a = a.slice(0, colon + 1) + "0:0";
    }
    const halves = a.split("::");
    if (halves.length > 2) return a;
    const head = halves[0] ? halves[0].split(":") : [];
    const rest = halves.length === 2 && halves[1] ? halves[1].split(":") : [];
    let groups;
    if (halves.length === 2) {
        if (head.length + rest.length > 7) return a;
        groups = [...head, ...new Array(8 - head.length - rest.length).fill("0"), ...rest];
    } else {
        groups = head;
    }
    if (groups.length !== 8 || groups.some((g) => !/^[0-9a-f]{1,4}$/.test(g))) return a;
    if (tail) groups.splice(6, 2, ...tail);
    const h = groups.map((g) => parseInt(g, 16));
    if (h.slice(0, 5).every((x) => x === 0) && h[5] === 0xffff) {
        return `${h[6] >> 8}.${h[6] & 255}.${h[7] >> 8}.${h[7] & 255}`;
    }
    return h.slice(0, 4).map((x) => x.toString(16)).join(":") + "::/64";
}

/** HMAC(secret, day + ":" + ip), only for rate-limit counters that expire after a day. */
export async function ipKey(secret, day, ip) {
    return base64url(await hmac(secret, day + ":" + ip));
}

/** base64url(json{v:1, r:reporterKey, iat}) + "." + base64url(HMAC(secret, payload)) */
export async function makeCredential(secret, reporter, iatSeconds) {
    const payload = base64url(utf8(JSON.stringify({ v: 1, r: reporter, iat: iatSeconds })));
    return payload + "." + base64url(await hmac(secret, payload));
}

/** The reporter key inside a credential, or null when it is malformed or its signature does not match. */
export async function checkCredential(secret, credential) {
    if (typeof credential !== "string" || credential.length > 512) return null;
    const parts = credential.split(".");
    if (parts.length !== 2 || !parts[0] || !parts[1]) return null;
    const expected = base64url(await hmac(secret, parts[0]));
    if (!(await safeEqual(expected, parts[1]))) return null;
    const bytes = base64urlDecode(parts[0]);
    if (!bytes) return null;
    let body;
    try {
        body = JSON.parse(utf8Decode(bytes));
    } catch {
        return null;
    }
    if (!body || body.v !== 1 || typeof body.r !== "string" || !KEY_PATTERN.test(body.r)) return null;
    return body.r;
}
