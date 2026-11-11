// Efficiency feedback: where the work of an AI session went, measured from its transcript, and the gate that decides whether
// a report "this would have taken N fewer steps with X" is worth filing (docs/ENGINE_FEEDBACK.md, "Efficiency feedback").
//
//   read_efficiency_session   the steps of one transcript (.factoria/ai/sessions/<id>.jsonl): tool calls, times, tokens, cost
//   measure_span              the numbers of a span of steps: steps, tool calls, minutes, tokens, cost
//   check_efficiency_report   the report gate: a report is refused with a teaching reason unless it is measured, its fix is the
//                             cheapest one that removes the waste, and the saving reaches the threshold of that fix type
//   efficiency_thresholds     the one table of thresholds (the doc embeds it; a test compares them)
//
// Nothing in here reads the clock or the network, and nothing asks a model: the numbers come from the transcript alone, so the
// same transcript always gives the same numbers.
//
// What a "step" is, so that a span `fromStep..toStep` means the same to the AI that names it and to the engine that measures it:
//   - the built-in agent: one model call, i.e. one `assistant` line of the transcript (the same numbering as the `steps` of
//     `ai.session_timeline`'s `context`). Its tokens and cost are the call's own `usage` and `costUsd`.
//   - Claude Code, Codex and other CLI agents: one model turn, i.e. everything from the first `thinking`, `text` or `tool_start`
//     event after a `tool_end` (or the start) up to the last `tool_end` before the next such event. They write no token counts:
//     the tokens are estimated from the bytes of what the turn wrote and read (kBytesPerToken, as `ai.session_timeline` does),
//     the cost is not known (0), and `estimated` is true.
// The minutes of a span are the time from the end of the step before it to the end of its last step, tools and waiting included.
#pragma once

#include <cstdint>
#include <istream>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// ---- Transcripts --------------------------------------------------------------------------------------------------------
// One tool call of a step, as far as the transcript tells.
struct EfficiencyToolCall {
    std::string id;
    std::string name;            // the tool as the model called it ("scene_inspect", "tool_call", "Bash")
    std::string command;         // the engine command it ran ("scene.inspect"), or the tool name when it is not one
    std::string ref;             // what it acted on: a file, a doc topic, a search query, an entity ("" = unknown)
    std::string shell;           // a shell call's command line of a CLI agent, cut to 200 bytes ("" = not a shell call)
    std::string code;            // the error code of a failed call ("" = it did not fail, or no code was given)
    bool failed = false;
    std::int64_t ms = 0;         // how long the tool ran (0 = not recorded)
    std::uint64_t resultBytes = 0;  // the size of its result (the full size when the transcript says it, else of the stored text)
};

struct EfficiencyStep {
    int number = 0;              // 1-based
    std::int64_t endMs = 0;      // when the step ended (unix ms); a step without a time keeps the one before it
    std::uint64_t tokens = 0;    // processed by the step: input + cache + output (built-in), estimated from bytes (CLI)
    double costUsd = 0;
    std::vector<EfficiencyToolCall> calls;
};

struct EfficiencySession {
    std::string id;              // the file name without ".jsonl"
    std::string agent;           // "builtin" or "cli"
    bool hasTimes = false;
    bool estimated = false;      // tokens are estimated from bytes, cost unknown (a CLI agent)
    std::int64_t startMs = 0;    // the time of the first line (0 = none)
    std::vector<EfficiencyStep> steps;
    int skippedLines = 0;        // lines that were not JSON or too long to read
    bool truncated = false;      // the transcript was bigger than kEfficiencyMaxSteps steps / kEfficiencyMaxBytes bytes: the rest is ignored
};

inline constexpr int kEfficiencyMaxSteps = 20000;
inline constexpr std::uint64_t kEfficiencyMaxBytes = 64ull * 1024 * 1024;        // of one transcript read: a bigger file is refused
inline constexpr std::uint64_t kEfficiencyMaxTotalBytes = 256ull * 1024 * 1024;   // of all the transcripts one call reads (EfficiencyLoadBudget)
inline constexpr std::size_t kEfficiencyMaxLine = 8u * 1024 * 1024;         // a longer line is skipped

// The steps of the transcript `text` (JSON lines). Never fails: a line that is not JSON is skipped and counted.
EfficiencySession read_efficiency_session(const std::string& text, const std::string& id);
// The transcript of `claude -p --output-format stream-json --verbose` (scripts/agent-cost.sh): a step is one model message (one `message.id`,
// whatever number of lines it was streamed in), with the message's own token counts (input + cache + output; `estimated` stays false) and the
// tools it called; a Bash call of `factoria call X` has command X. Never fails: a line that is not JSON is skipped and counted.
EfficiencySession read_claude_stream_session(const std::string& text, const std::string& id);
// The same, read from a stream line by line: only one line (at most kEfficiencyMaxLine bytes) and one 64 KB chunk are held in memory, and
// at most kEfficiencyMaxBytes bytes are read (the rest sets `truncated`).
// `maxBytes` is kEfficiencyMaxBytes unless a test lowers it.
EfficiencySession read_efficiency_session(std::istream& in, const std::string& id, std::uint64_t maxBytes = kEfficiencyMaxBytes);
// How much a call that reads several transcripts may still read. Every load_efficiency_session given the budget takes the size of its file
// off it before opening it, and refuses a file that no longer fits.
struct EfficiencyLoadBudget {
    std::uint64_t total = kEfficiencyMaxTotalBytes;
    std::uint64_t bytesLeft = kEfficiencyMaxTotalBytes;
    std::uint64_t maxFile = kEfficiencyMaxBytes;  // the most one transcript may weigh; tests lower it instead of making a 65 MB file
    EfficiencyLoadBudget() = default;
    explicit EfficiencyLoadBudget(std::uint64_t totalBytes, std::uint64_t fileBytes = kEfficiencyMaxBytes)
        : total(totalBytes), bytesLeft(totalBytes), maxFile(fileBytes) {}
};
// The folder of a project's transcripts: <projectDir>/.factoria/ai/sessions
std::string efficiency_sessions_dir(const std::string& projectDir);
// The ids of the transcripts of a project, sorted.
std::vector<std::string> list_efficiency_sessions(const std::string& projectDir);
// Reads one transcript by id ("20261014-153012-main", with or without ".jsonl"). The error says which ids exist, or that the file is bigger
// than kEfficiencyMaxBytes or does not fit what is left of `budget` (nullptr = no total limit). All strings are UTF-8.
Result<EfficiencySession> load_efficiency_session(const std::string& projectDir, const std::string& session, EfficiencyLoadBudget* budget = nullptr);

// ---- Measuring ----------------------------------------------------------------------------------------------------------
struct EfficiencyMeasure {
    int steps = 0;
    int toolCalls = 0;
    double minutes = 0;          // 0.1 minute resolution
    std::uint64_t tokens = 0;
    double costUsd = 0;          // 4 decimals; 0 when unknown
    bool estimated = false;      // the tokens are estimated from bytes (CLI agent) and the cost is not known
    EfficiencyMeasure& operator+=(const EfficiencyMeasure& o);
    Json to_json() const;
    static EfficiencyMeasure from_json(const Json& j);
};

struct EfficiencySpan {
    std::string session;
    int fromStep = 0;
    int toStep = 0;
    Json to_json() const;
};

// The numbers of steps fromStep..toStep (1-based, inclusive) of `s`; both are clamped to the steps there are.
EfficiencyMeasure measure_span(const EfficiencySession& s, int fromStep, int toStep);
// The same scaled by `share` (0..1): the saving a fix is expected to bring.
EfficiencyMeasure scale_measure(const EfficiencyMeasure& m, double share);

// ---- The gate -----------------------------------------------------------------------------------------------------------
// Fix types, cheapest first: the cheapest one that removes the waste wins.
const std::vector<std::string>& efficiency_fix_types();    // doc, guide, example, commandOption, newCommand, engineChange
// Who the fix helps: every-game, genre, feature (one feature of the engine), this-game (not engine feedback: a project fact).
const std::vector<std::string>& efficiency_applies_to();

struct EfficiencyThreshold {
    std::string fixType;
    double minutes = 0;          // the saving per game, in minutes, that justifies the fix (0 = not a criterion)
    std::uint64_t tokens = 0;    // ... or in tokens
    double costUsd = 0;          // ... or in dollars
    bool widerThanFeature = false;  // appliesTo must be every-game or genre
    bool candidateOnly = false;     // the entry is only a candidate for triage: it goes on the roadmap when reports add up
    std::string cost;            // what the fix costs, in words
};
const std::vector<EfficiencyThreshold>& efficiency_thresholds();
// The table as Markdown, exactly as docs/ENGINE_FEEDBACK.md shows it (a test compares them).
std::string efficiency_threshold_table();
// An engine change goes on the roadmap only when the reports that ask for it add up to this much across games.
inline constexpr double kEfficiencyRoadmapUsd = 1000.0;
inline constexpr double kEfficiencyRoadmapHours = 20.0;

// What the AI says about the waste and the fix; the engine adds the numbers.
struct EfficiencyInput {
    std::string category, title, suggestion;  // of the report (the fix is part of it)
    std::string waste;                        // what took the time, in engine terms
    std::vector<EfficiencySpan> evidence;
    std::string fixType, appliesTo;
    double saveShare = 0;                     // the share of the measured span the fix removes 0.01 to 1
    std::string saveWhy;                      // one line of why
    std::string whyNotCheaper;                // required for commandOption, newCommand, engineChange
    std::vector<std::string> searched;        // for a findability report: the words that docs.search did not answer
    std::uint64_t everyStepTokens = 0;        // the tokens the fix adds to every step of every run (text loaded each time)
};

// What only the engine's own code knows about an entry (never the AI's arguments): the stable id of the waste pattern the retrospective
// found it from (`pattern`: "failure:scene.load:not_found", kept in the local file only), and the engine version in which a fix for
// the same pattern had been released when this report was made (`afterFix`: the report says "still costing after that fix").
struct EfficiencyOrigin {
    std::string pattern;
    std::string afterFix;
};

// A report that does not pass: `code` is a CommandError code, `message` says what is wrong (with the JSON pointer of the field),
// `hint` how to fix it or what to do instead.
struct EfficiencyRefusal {
    std::string code, message, hint;
};

// What the engine stores next to the AI's words.
struct EfficiencyVerdict {
    std::vector<EfficiencySpan> evidence;     // normalised (no ".jsonl", sorted as given)
    EfficiencyMeasure measured;               // the whole evidence
    std::vector<EfficiencyMeasure> spanMeasures;  // one per span of `evidence`, in the same order
    EfficiencyMeasure saving;                 // measured x saveShare
    std::string existingDoc;                  // findability: "docs/X.md:12 (Heading)" where the thing is documented
    bool candidateOnly = false;
};

// The gate. `projectDir` holds the transcripts. Returns the refusal, or fills `verdict`.
// Refuses, with the field and the way out: a fix type, share or applies-to that does not exist; no evidence, a session that does
// not exist, a step that is not in it, spans that overlap; a fix that is not the cheapest one that works (no `whyNotCheaper`);
// text loaded on every step that costs more than it saves; a "missing guide" for a doc that docs.search finds with the report's
// own words; a lesson that is only true for this game; model, effort or limit settings; a saving under the threshold of its fix.
std::optional<EfficiencyRefusal> check_efficiency_report(const std::string& projectDir, const EfficiencyInput& in,
                                                         EfficiencyVerdict& verdict);

// The input from the JSON of feedback.report / `feedback add --json`: {waste, evidence[], fixType, expectedSaving {share, why},
// appliesTo, whyNotCheaper?, searched?, everyStepTokens?} plus the report's category, title and suggestion. The refusal
// names the JSON pointer of the field that is wrong.
std::optional<EfficiencyRefusal> efficiency_input_from_json(const Json& args, EfficiencyInput& out);

// ---- Sharing and the developer's ranking ----------------------------------------------------------------------------------
// What an efficiency entry sends to the engine developer next to its sanitized `share` text (docs/ENGINE_FEEDBACK.md, "Sharing"):
// {fixType, appliesTo, measured, saving, expectedShare, spans, afterFix?, candidate?}. Numbers and words of the engine's own fixed lists
// only: the AI's `waste` text, the evidence (session ids, which carry the start time of a run) and the entry's other words never go; the
// text of the report is the sanitized `share` and nothing else. Null when the entry is not an efficiency entry, its fix type or
// applies-to is not one of the lists, or `appliesTo` is this-game (a project fact: it is not engine feedback and is not sent).
Json efficiency_share_block(const Json& entry);
// The same block read back from a server report (what `feedback pull` writes into the inbox entry): the numbers are clamped to what a
// transcript can hold. Null when it is not a usable block.
Json efficiency_clean_block(const Json& block);

// What a fix costs to make, in hours of work: the rough figure the ranking sets the saving against (docs/ENGINE_FEEDBACK.md, "Ranking").
// An engine change costs what the roadmap asks of the reports that want it (kEfficiencyRoadmapHours or kEfficiencyRoadmapUsd).
double efficiency_fix_cost_hours(const std::string& fixType);
// The exchange the ranking uses to put dollars and hours on one scale: the roadmap bar is $1000 or 20 hours, so an hour is $50.
inline constexpr double kEfficiencyUsdPerHour = kEfficiencyRoadmapUsd / kEfficiencyRoadmapHours;
// How much the numbers of an installation that is not signed in count: it cannot prove them (a verified one and a local project count 1).
inline constexpr double kEfficiencyAnonymousWeight = 0.5;

// One installation's (or project's) entry of a group of reports that ask for the same fix.
struct EfficiencyVoice {
    std::string project;     // the local project, or "install-<key>" of an installation in the inbox
    std::string id;          // FB-0003
    std::string shareId;     // r_8f3k2m for a pulled report ("" for a local entry): what `feedback reject` takes
    std::string trust;       // local | verified | anonymous
    int occurrences = 1;
    EfficiencyMeasure measured, saving;
    std::string afterFix;    // "" or the version of a fix the report says did not remove the waste
};
struct EfficiencyGroup {
    std::string title, category, fixType, appliesTo, suggestion;
    std::vector<EfficiencyVoice> voices;
};

// The ranking of groups: JSON array, most saved first, ties by cost, tokens, then title (the same inputs always give the same text).
// Each item: {rank, title, category, fixType, appliesTo, suggestion?, installations, verifiedInstallations, reports,
// total {steps, toolCalls, minutes, tokens, costUsd, estimated, hours}, perGame {minutes, tokens, costUsd}, fixCost {hours, usd?},
// verdict {code, text}, afterFix[]?, entries [{project, id, shareId?, trust, occurrences, saving, measured, rejectReason?}]}.
// `total` is the sum over installations of each one's saving (its own entries added: an installation counts once, whatever number of
// reports it sent), an anonymous installation weighted kEfficiencyAnonymousWeight; `hours` is the larger of its minutes and its dollars
// at kEfficiencyUsdPerHour. Minutes are rounded to 0.1, dollars to cents, hours to 0.1.
// verdict.code: doc-now (doc, guide, example: write it), command-worth-it / command-not-yet (commandOption, newCommand: the hours saved
// against the hours the fix costs), engine-roadmap / engine-below-threshold (engineChange: against the roadmap bar of $1000 or 20 hours).
// verdict.text is "doc now", "command: worth it", "command: not yet (H of the C hours it costs)", "engine change: below threshold (N of the
// $1000 / 20 hours it needs)" with N = "H hours" and "$D", or "engine change: reached the roadmap bar (...)".
// `rejectReason` (only on the entries of a group whose verdict is doc-now or engine-below-threshold: the two that mean "do not build
// this") is a ready reason for `factoria feedback reject` (plain text under 500 characters, it names only this entry's own numbers:
// the installation reads it and must learn nothing about others). The hours and dollars of a verdict text round DOWN, so a "not yet"
// never reads as if it had reached its bar.
Json rank_efficiency(std::vector<EfficiencyGroup> groups);

}  // namespace fa
