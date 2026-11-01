// In-memory store: the storage interface (see store_d1.js for the production one) kept in plain Maps. Used by the
// tests; behaves like the D1 store, including cursor order (sequence numbers are never reused after a delete).
//
// Interface (all methods async):
//   getBans(list)                     [{kind, key}] -> [{kind, key, reason, createdAt}] of those that are banned
//   listBans()                        -> [{kind, key, reason, createdAt}]
//   addBan(ban)                       {kind, key, reason, createdAt}; replaces an existing ban of that key
//   removeBan(kind, key)              -> true when a ban was removed
//   purge({installKey?, reporterKey?})-> number of reports deleted
//   getCounters(keys, now)            -> {key: count} of the live counters (expiresAt > now)
//   listCounters(prefix, now)         -> [{key, count}] of the live counters whose key starts with prefix
//   listForMerge(installKey, limit)   -> [{shareId, category, titleNorm}], newest first
//   commit({inserts, bumps, counters, now})
//                                     inserts: full report objects; bumps: [{shareId, by}] occurrences;
//                                     counters: [{key, by, expiresAt}]; expired counters are dropped
//   listReports(afterSeq, limit)      -> reports with seq > afterSeq in seq order, each with its `seq`
//   deleteReport(shareId)             -> true when it existed
//   totals()                          -> {reports, installations, occurrences}

export class MemoryStore {
    constructor() {
        this.reports = new Map(); // shareId -> report
        this.bans = new Map(); // "kind:key" -> ban
        this.counters = new Map(); // key -> {count, expiresAt}
        this.nextSeq = 1;
    }

    async getBans(list) {
        return list.map((b) => this.bans.get(b.kind + ":" + b.key)).filter(Boolean).map((b) => ({ ...b }));
    }

    async listBans() {
        return [...this.bans.values()].map((b) => ({ ...b }));
    }

    async addBan(ban) {
        this.bans.set(ban.kind + ":" + ban.key, { ...ban });
    }

    async removeBan(kind, key) {
        return this.bans.delete(kind + ":" + key);
    }

    async purge({ installKey, reporterKey }) {
        let n = 0;
        for (const [id, r] of [...this.reports]) {
            if ((installKey && r.installKey === installKey) || (reporterKey && r.reporterKey === reporterKey)) {
                this.reports.delete(id);
                n++;
            }
        }
        return n;
    }

    async getCounters(keys, now) {
        const out = {};
        for (const k of keys) {
            const c = this.counters.get(k);
            out[k] = c && c.expiresAt > now ? c.count : 0;
        }
        return out;
    }

    async listCounters(prefix, now) {
        const out = [];
        for (const [key, c] of this.counters) if (key.startsWith(prefix) && c.expiresAt > now) out.push({ key, count: c.count });
        return out;
    }

    async listForMerge(installKey, limit) {
        const rows = [...this.reports.values()].filter((r) => r.installKey === installKey);
        rows.sort((a, b) => b.seq - a.seq);
        return rows.slice(0, limit).map((r) => ({ shareId: r.shareId, category: r.category, titleNorm: r.titleNorm }));
    }

    async commit({ inserts = [], bumps = [], counters = [], now }) {
        for (const r of inserts) {
            if (this.reports.has(r.shareId)) throw new Error("duplicate shareId " + r.shareId);
            this.reports.set(r.shareId, { ...r, seq: this.nextSeq++ });
        }
        for (const b of bumps) {
            const r = this.reports.get(b.shareId);
            if (r) r.occurrences += b.by;
        }
        for (const c of counters) {
            const cur = this.counters.get(c.key);
            this.counters.set(c.key, { count: (cur ? cur.count : 0) + c.by, expiresAt: c.expiresAt });
        }
        for (const [key, c] of [...this.counters]) if (c.expiresAt <= now) this.counters.delete(key);
    }

    async listReports(afterSeq, limit) {
        return [...this.reports.values()]
            .filter((r) => r.seq > afterSeq)
            .sort((a, b) => a.seq - b.seq)
            .slice(0, limit)
            .map((r) => ({ ...r }));
    }

    async deleteReport(shareId) {
        return this.reports.delete(shareId);
    }

    async totals() {
        const installs = new Set();
        let occurrences = 0;
        for (const r of this.reports.values()) {
            installs.add(r.installKey);
            occurrences += r.occurrences;
        }
        return { reports: this.reports.size, installations: installs.size, occurrences };
    }
}
