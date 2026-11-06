-- FactorIA feedback server: efficiency entries (docs/design/FEEDBACK_SHARING.md, "Efficiency entries").
-- An efficiency entry is a report about time and tokens an engine gap cost, not a missing feature. Besides the usual text it
-- carries the measured numbers and the fix type, in engine terms only. kind is 'gap' (every report before this migration) or
-- 'efficiency'; fix_type is NULL for a gap and is the merge key next to category and title: an efficiency report only merges
-- with one of the same fix type. efficiency is the JSON text of the validated block (fixType, appliesTo, measured, saving,
-- expectedShare, spans, afterFix, candidate); the numbers are cumulative, a merge replaces them.
ALTER TABLE reports ADD COLUMN kind TEXT NOT NULL DEFAULT 'gap' CHECK (kind IN ('gap', 'efficiency'));
ALTER TABLE reports ADD COLUMN fix_type TEXT;
ALTER TABLE reports ADD COLUMN efficiency TEXT;
