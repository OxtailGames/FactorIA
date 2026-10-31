-- FactorIA feedback server: schema (docs/design/FEEDBACK_SHARING.md, "Server").
-- Nothing here can identify a person: installation and reporter keys are keyed hashes (HMAC with a server secret),
-- never the raw installation id, an IP address, a GitHub login or id, or a GitHub token.

-- One row per (installation, similar title). `seq` is the pull cursor order: it only grows and is never reused after a
-- delete (AUTOINCREMENT), so a cursor always returns the same page.
CREATE TABLE reports (
    seq            INTEGER PRIMARY KEY AUTOINCREMENT,
    share_id       TEXT NOT NULL UNIQUE,
    install_key    TEXT NOT NULL,
    reporter_key   TEXT,                       -- NULL when the report was anonymous
    received_at    TEXT NOT NULL,              -- ISO 8601 UTC
    occurrences    INTEGER NOT NULL DEFAULT 1, -- how many times this installation reported the same gap
    engine_version TEXT,
    platform       TEXT NOT NULL,
    category       TEXT NOT NULL,
    severity       TEXT NOT NULL,
    effort         TEXT,
    title          TEXT NOT NULL,
    title_norm     TEXT NOT NULL,              -- normalized title, used to merge similar reports
    missing        TEXT NOT NULL,
    suggestion     TEXT NOT NULL DEFAULT '',
    workaround     TEXT NOT NULL DEFAULT '',
    reporter_kind  TEXT,
    reviewed       INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX reports_install ON reports (install_key, seq);
CREATE INDEX reports_reporter ON reports (reporter_key);

-- Refused installations (kind 'install') and GitHub reporters (kind 'reporter').
CREATE TABLE bans (
    kind       TEXT NOT NULL CHECK (kind IN ('install', 'reporter')),
    key        TEXT NOT NULL,
    reason     TEXT NOT NULL,
    created_at TEXT NOT NULL,
    PRIMARY KEY (kind, key)
);

-- Rate-limit counters and daily statistics. Every row expires (a day for limits, a month for statistics) and is deleted
-- by the next write after that.
CREATE TABLE counters (
    key        TEXT PRIMARY KEY,
    count      INTEGER NOT NULL,
    expires_at INTEGER NOT NULL                -- epoch milliseconds
);
CREATE INDEX counters_expiry ON counters (expires_at);
