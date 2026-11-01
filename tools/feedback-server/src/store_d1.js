// Production store on Cloudflare D1. Same interface as store_memory.js (documented there). Schema:
// migrations/0001_init.sql. Queries are few and batched: the free plan allows 50 queries per Worker invocation.

const REPORT_COLUMNS =
    "seq, share_id, install_key, reporter_key, received_at, occurrences, engine_version, platform, category, severity, " +
    "effort, title, title_norm, missing, suggestion, workaround, reporter_kind, reviewed";

function toReport(row) {
    return {
        seq: row.seq,
        shareId: row.share_id,
        installKey: row.install_key,
        reporterKey: row.reporter_key,
        receivedAt: row.received_at,
        occurrences: row.occurrences,
        engineVersion: row.engine_version,
        platform: row.platform,
        category: row.category,
        severity: row.severity,
        effort: row.effort,
        title: row.title,
        titleNorm: row.title_norm,
        missing: row.missing,
        suggestion: row.suggestion,
        workaround: row.workaround,
        reporterKind: row.reporter_kind,
        reviewed: row.reviewed === 1,
    };
}

function toBan(row) {
    return { kind: row.kind, key: row.key, reason: row.reason, createdAt: row.created_at };
}

export class D1Store {
    constructor(db) {
        this.db = db;
    }

    async getBans(list) {
        if (list.length === 0) return [];
        const where = list.map(() => "(kind = ? AND key = ?)").join(" OR ");
        const args = list.flatMap((b) => [b.kind, b.key]);
        const { results } = await this.db.prepare(`SELECT kind, key, reason, created_at FROM bans WHERE ${where}`).bind(...args).all();
        return results.map(toBan);
    }

    async listBans() {
        const { results } = await this.db.prepare("SELECT kind, key, reason, created_at FROM bans ORDER BY created_at, key").all();
        return results.map(toBan);
    }

    async addBan(ban) {
        await this.db
            .prepare("INSERT OR REPLACE INTO bans (kind, key, reason, created_at) VALUES (?, ?, ?, ?)")
            .bind(ban.kind, ban.key, ban.reason, ban.createdAt)
            .run();
    }

    async removeBan(kind, key) {
        const res = await this.db.prepare("DELETE FROM bans WHERE kind = ? AND key = ?").bind(kind, key).run();
        return (res.meta?.changes ?? 0) > 0;
    }

    async purge({ installKey, reporterKey }) {
        let total = 0;
        if (installKey) {
            total += (await this.db.prepare("DELETE FROM reports WHERE install_key = ?").bind(installKey).run()).meta?.changes ?? 0;
        }
        if (reporterKey) {
            total += (await this.db.prepare("DELETE FROM reports WHERE reporter_key = ?").bind(reporterKey).run()).meta?.changes ?? 0;
        }
        return total;
    }

    async getCounters(keys, now) {
        const out = {};
        for (const k of keys) out[k] = 0;
        if (keys.length === 0) return out;
        const marks = keys.map(() => "?").join(",");
        const { results } = await this.db
            .prepare(`SELECT key, count FROM counters WHERE expires_at > ? AND key IN (${marks})`)
            .bind(now, ...keys)
            .all();
        for (const row of results) out[row.key] = row.count;
        return out;
    }

    async listCounters(prefix, now) {
        const escaped = prefix.replace(/[\\%_]/g, (c) => "\\" + c);
        const { results } = await this.db
            .prepare("SELECT key, count FROM counters WHERE expires_at > ? AND key LIKE ? ESCAPE '\\'")
            .bind(now, escaped + "%")
            .all();
        return results.map((r) => ({ key: r.key, count: r.count }));
    }

    async listForMerge(installKey, limit) {
        const { results } = await this.db
            .prepare("SELECT share_id, category, title_norm FROM reports WHERE install_key = ? ORDER BY seq DESC LIMIT ?")
            .bind(installKey, limit)
            .all();
        return results.map((r) => ({ shareId: r.share_id, category: r.category, titleNorm: r.title_norm }));
    }

    async commit({ inserts = [], bumps = [], counters = [], now }) {
        const db = this.db;
        const statements = [];
        for (const r of inserts) {
            statements.push(
                db
                    .prepare(
                        "INSERT INTO reports (share_id, install_key, reporter_key, received_at, occurrences, engine_version, " +
                            "platform, category, severity, effort, title, title_norm, missing, suggestion, workaround, " +
                            "reporter_kind, reviewed) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    )
                    .bind(
                        r.shareId, r.installKey, r.reporterKey, r.receivedAt, r.occurrences, r.engineVersion, r.platform,
                        r.category, r.severity, r.effort, r.title, r.titleNorm, r.missing, r.suggestion, r.workaround,
                        r.reporterKind, r.reviewed ? 1 : 0,
                    ),
            );
        }
        for (const b of bumps) {
            statements.push(db.prepare("UPDATE reports SET occurrences = occurrences + ? WHERE share_id = ?").bind(b.by, b.shareId));
        }
        for (const c of counters) {
            statements.push(
                db
                    .prepare(
                        "INSERT INTO counters (key, count, expires_at) VALUES (?, ?, ?) " +
                            "ON CONFLICT(key) DO UPDATE SET count = count + excluded.count",
                    )
                    .bind(c.key, c.by, c.expiresAt),
            );
        }
        statements.push(db.prepare("DELETE FROM counters WHERE expires_at <= ?").bind(now));
        await db.batch(statements);
    }

    async listReports(afterSeq, limit) {
        const { results } = await this.db
            .prepare(`SELECT ${REPORT_COLUMNS} FROM reports WHERE seq > ? ORDER BY seq LIMIT ?`)
            .bind(afterSeq, limit)
            .all();
        return results.map(toReport);
    }

    async deleteReport(shareId) {
        const res = await this.db.prepare("DELETE FROM reports WHERE share_id = ?").bind(shareId).run();
        return (res.meta?.changes ?? 0) > 0;
    }

    async totals() {
        const row = await this.db
            .prepare("SELECT COUNT(*) AS reports, COUNT(DISTINCT install_key) AS installations, COALESCE(SUM(occurrences), 0) AS occurrences FROM reports")
            .first();
        return { reports: row.reports, installations: row.installations, occurrences: row.occurrences };
    }
}
