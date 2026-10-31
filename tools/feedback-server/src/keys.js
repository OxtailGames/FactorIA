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
