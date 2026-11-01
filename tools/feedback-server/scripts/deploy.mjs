// The deploy, run by deploy.sh / deploy.ps1 after they have checked Node and installed wrangler from the lock file.
// Safe to run again: it only creates, applies and sets what is missing.
//
//   node scripts/deploy.mjs [--rotate-admin]
//
// Steps: wrangler login (if not logged in) -> D1 database (create if missing; its id goes into the untracked
// wrangler.local.toml) -> migrations -> deploy -> ADMIN_TOKEN and HMAC_SECRET (only when not set yet) ->
// feedback-admin.json next to the user's ai.json -> print the URL for FA_FEEDBACK_URL.

import { spawnSync } from "node:child_process";
import { randomBytes } from "node:crypto";
import { chmodSync, existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, posix, resolve, win32 } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

export const DB_NAME = "factoria-feedback";
const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");

// ---- pure helpers (tested in test/deploy.test.js) ------------------------------------------------------------

/** The first JSON array or object in wrangler's output (it prints banners around it), or null. */
export function extractJson(text) {
    for (const open of ["[", "{"]) {
        const start = text.indexOf(open);
        if (start < 0) continue;
        for (let end = text.lastIndexOf(open === "[" ? "]" : "}"); end > start; end = text.lastIndexOf(open === "[" ? "]" : "}", end - 1)) {
            try {
                return JSON.parse(text.slice(start, end + 1));
            } catch {
                // try a shorter slice
            }
        }
    }
    return null;
}

/** The id of the database called `name` in `wrangler d1 list --json` output, or null. */
export function findDatabaseId(listOutput, name = DB_NAME) {
    const list = extractJson(listOutput);
    if (!Array.isArray(list)) return null;
    const db = list.find((d) => d && d.name === name);
    return db ? db.uuid || db.id || db.database_id || null : null;
}

/** The database_id printed by `wrangler d1 create`, or null. */
export function parseCreatedId(createOutput) {
    const m = /database_id"?\s*[:=]\s*"([0-9a-fA-F-]{36})"/.exec(createOutput);
    return m ? m[1] : null;
}

/** Names of the secrets in `wrangler secret list --format json` output. */
export function secretNames(listOutput) {
    const list = extractJson(listOutput);
    return Array.isArray(list) ? list.map((s) => s && s.name).filter(Boolean) : [];
}

/** wrangler.toml with the placeholder database_id replaced by the real one. */
export function withDatabaseId(toml, id) {
    if (!/^database_id\s*=\s*".*"$/m.test(toml)) throw new Error("wrangler.toml has no database_id line to replace");
    return toml.replace(/^database_id\s*=\s*".*"$/m, `database_id = "${id}"`);
}

/** The https://<name>.<subdomain>.workers.dev URL wrangler deploy prints, or null. */
export function parseWorkerUrl(deployOutput) {
    const m = /https:\/\/[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.workers\.dev/.exec(deployOutput);
    return m ? m[0] : null;
}

/** True when wrangler deploy failed because the account has no workers.dev subdomain yet (a new account). */
export function needsWorkersSubdomain(output) {
    return /register a workers\.dev subdomain/i.test(output);
}

/**
 * Folder of the user-level config (where ai.json lives), the rule of fa::user_config_dir: the folder of
 * $FACTORIA_AI_CONFIG when set, else %APPDATA%\factoria (or %USERPROFILE%\.factoria) on Windows, ~/.factoria elsewhere.
 * The separators follow `platform`, not the host, so the rule can be tested for every OS anywhere.
 */
export function configDir(env = process.env, platform = process.platform, home = homedir()) {
    const path = platform === "win32" ? win32 : posix;
    if (env.FACTORIA_AI_CONFIG) return path.dirname(env.FACTORIA_AI_CONFIG);
    if (platform === "win32") return env.APPDATA ? path.join(env.APPDATA, "factoria") : path.join(home, ".factoria");
    return path.join(home, ".factoria");
}

/** The new content of feedback-admin.json: keeps unrelated keys (the pull cursor) and an existing token unless replaced. */
export function mergeAdminFile(existingText, endpoint, adminToken) {
    let current = {};
    try {
        const parsed = JSON.parse(existingText || "{}");
        if (parsed && typeof parsed === "object" && !Array.isArray(parsed)) current = parsed;
    } catch {
        // an unreadable file is replaced
    }
    const next = { ...current, endpoint };
    if (adminToken) next.adminToken = adminToken;
    return next;
}

// ---- wrangler ------------------------------------------------------------------------------------------------

const wranglerJs = join(root, "node_modules", "wrangler", "bin", "wrangler.js");
const localConfig = join(root, "wrangler.local.toml");

/**
 * Run wrangler. `capture` returns its stdout (also echoed); prompts still reach the terminal through stderr/stdin.
 * `captureErr` also returns stderr (echoed too), for errors the caller explains better than wrangler does.
 */
function wrangler(args, { capture = false, captureErr = false, input, allowFail = false } = {}) {
    const r = spawnSync(process.execPath, [wranglerJs, ...args], {
        cwd: root,
        encoding: "utf8",
        input,
        stdio: [input === undefined ? "inherit" : "pipe", capture ? "pipe" : "inherit", captureErr ? "pipe" : "inherit"],
        env: { ...process.env, WRANGLER_SEND_METRICS: process.env.WRANGLER_SEND_METRICS ?? "false" },
    });
    if (capture && r.stdout) process.stdout.write(r.stdout);
    if (captureErr && r.stderr) process.stderr.write(r.stderr);
    if (r.status !== 0 && !allowFail) {
        throw new Error(`wrangler ${args.slice(0, 3).join(" ")} failed (exit ${r.status}). Read its message above, fix it and run the deploy again.`);
    }
    return { status: r.status, stdout: r.stdout || "", stderr: r.stderr || "" };
}

function step(text) {
    console.log(`\n== ${text}`);
}

async function main() {
    const rotateAdmin = process.argv.includes("--rotate-admin");
    if (process.argv.includes("--help")) {
        console.log("Usage: deploy.sh [--rotate-admin]   (deploy.ps1 on Windows)\n  --rotate-admin  set a new ADMIN_TOKEN even if one exists");
        return;
    }
    if (!existsSync(wranglerJs)) throw new Error("wrangler is not installed. Run `npm ci` in tools/feedback-server (deploy.sh does it).");

    step("Cloudflare login");
    const who = wrangler(["whoami"], { capture: true, allowFail: true });
    if (who.status !== 0 || /not authenticated|not logged in/i.test(who.stdout)) {
        console.log("Not logged in: wrangler opens your browser to log in to Cloudflare.");
        wrangler(["login"]);
    }

    step(`D1 database ${DB_NAME}`);
    let dbId = findDatabaseId(wrangler(["d1", "list", "--json"], { capture: true }).stdout);
    if (dbId) {
        console.log(`Found (${dbId}).`);
    } else {
        const created = wrangler(["d1", "create", DB_NAME], { capture: true }).stdout;
        dbId = parseCreatedId(created) || findDatabaseId(wrangler(["d1", "list", "--json"], { capture: true }).stdout);
        if (!dbId) throw new Error(`Created the database but could not read its id. Run \`wrangler d1 list\`, put the id in wrangler.local.toml (a copy of wrangler.toml) and run the deploy again.`);
    }
    writeFileSync(localConfig, withDatabaseId(readFileSync(join(root, "wrangler.toml"), "utf8"), dbId));
    console.log("Wrote wrangler.local.toml (untracked) with the database id.");

    step("Migrations");
    // Piped stdin: wrangler takes the default answer (apply) instead of stopping at its "continue?" prompt.
    wrangler(["d1", "migrations", "apply", DB_NAME, "--remote", "-c", "wrangler.local.toml"], { input: "" });

    step("Deploy");
    const deployArgs = ["deploy", "-c", "wrangler.local.toml"];
    let deploy = wrangler(deployArgs, { capture: true, captureErr: true, allowFail: true });
    if (deploy.status !== 0 && needsWorkersSubdomain(deploy.stdout + deploy.stderr)) {
        // A new account has no workers.dev subdomain. wrangler registers one when it can ask (it answered "no" above
        // because its output was captured): run it attached to the terminal, then again captured to read the URL.
        console.log("\nThis Cloudflare account has no workers.dev subdomain yet (once per account). Answer yes and pick one:"
            + " it is part of the public URL (factoria-feedback.<subdomain>.workers.dev).");
        wrangler(deployArgs);
        deploy = wrangler(deployArgs, { capture: true, captureErr: true, allowFail: true });
    }
    if (deploy.status !== 0) {
        throw new Error(`wrangler deploy failed (exit ${deploy.status}). Read its message above, fix it and run the deploy again.`);
    }
    const deployed = deploy.stdout + deploy.stderr;
    const endpoint = parseWorkerUrl(deployed);
    if (!endpoint) throw new Error("The deploy worked but its URL was not in wrangler's output. Find it in the Cloudflare dashboard (Workers) and put it in feedback-admin.json and FA_FEEDBACK_URL by hand.");

    step("Secrets");
    const names = secretNames(wrangler(["secret", "list", "--format", "json", "-c", "wrangler.local.toml"], { capture: true, allowFail: true }).stdout);
    let newAdminToken = null;
    if (!names.includes("HMAC_SECRET")) {
        wrangler(["secret", "put", "HMAC_SECRET", "-c", "wrangler.local.toml"], { input: randomBytes(32).toString("base64url") + "\n" });
        console.log("HMAC_SECRET set (random; it never leaves Cloudflare. Do not rotate it: installation keys and credentials derive from it).");
    } else {
        console.log("HMAC_SECRET already set: kept.");
    }
    if (!names.includes("ADMIN_TOKEN") || rotateAdmin) {
        newAdminToken = randomBytes(32).toString("base64url");
        wrangler(["secret", "put", "ADMIN_TOKEN", "-c", "wrangler.local.toml"], { input: newAdminToken + "\n" });
        console.log("ADMIN_TOKEN set.");
    } else {
        console.log("ADMIN_TOKEN already set: kept (use --rotate-admin to replace it).");
    }

    step("feedback-admin.json");
    const adminFile = process.env.FEEDBACK_ADMIN_FILE || join(configDir(), "feedback-admin.json");
    mkdirSync(dirname(adminFile), { recursive: true });
    const existing = existsSync(adminFile) ? readFileSync(adminFile, "utf8") : "";
    const merged = mergeAdminFile(existing, endpoint, newAdminToken);
    writeFileSync(adminFile, JSON.stringify(merged, null, 2) + "\n");
    if (process.platform !== "win32") chmodSync(adminFile, 0o600);
    console.log(`Wrote ${adminFile}`);
    if (!merged.adminToken) {
        console.log("WARNING: ADMIN_TOKEN was set by an earlier deploy and this file has no adminToken. Run the deploy again with --rotate-admin to get a new one.");
    }

    step("Check");
    for (let attempt = 1; attempt <= 6; attempt++) {
        try {
            const res = await fetch(endpoint + "/");
            if (res.ok) {
                console.log(`${endpoint}/ answers ${res.status}.`);
                break;
            }
            console.log(`${endpoint}/ answers ${res.status}.`);
        } catch {
            if (attempt === 6) console.log("The URL does not answer yet (a new workers.dev address can take a minute); try it in the browser.");
        }
        await new Promise((r) => setTimeout(r, 5000));
    }

    console.log(`\nDone. Build the engine with the endpoint compiled in:\n  cmake -DFA_FEEDBACK_URL=${endpoint} ...\nand read reports with: factoria feedback pull`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
    main().catch((e) => {
        console.error(`\nDeploy stopped: ${e.message}`);
        process.exit(1);
    });
}
