-- FactorIA feedback server: the engine developer's verdict on a report (docs/design/FEEDBACK_SHARING.md, "Verdicts").
-- A rejected report keeps the reason the developer wrote (plain text, at most 500 characters); the installation that
-- sent the report reads it (POST /v1/verdicts, only for its own reports) and shows it to the person. Nothing here
-- identifies anyone. verdict is NULL (no decision) or 'rejected'.
ALTER TABLE reports ADD COLUMN verdict TEXT CHECK (verdict IS NULL OR verdict = 'rejected');
ALTER TABLE reports ADD COLUMN verdict_reason TEXT;
ALTER TABLE reports ADD COLUMN verdict_at TEXT;   -- ISO 8601 UTC
