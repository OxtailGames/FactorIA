// The retrospective: where the work of the AI runs of a project went, found mechanically from the transcripts and turned into
// efficiency feedback (docs/ENGINE_FEEDBACK.md, "Efficiency feedback"; docs/AI_PROVIDERS.md, "Retrospective").
//
//   find_retro_candidates   the mechanical pass. No model, no clock, no network: the same transcripts always give the same candidates
//                           with the same numbers. It looks for the usual waste: the same command failing with the same code, the
//                           same doc or file read again and again, tool results over a size budget, long loops on one system, many
//                           screenshots in a row, long waits on a tool, and workarounds that ENGINE_FEEDBACK already records.
//   run_retrospective       the pass over a project, then ONE call of the fast role that turns at most three candidates into entries.
//                           Every entry goes through the report gate (fa/tooling/efficiency.h) like one an AI files by hand, so the
//                           threshold table, the "cheapest fix" rule and the dedupe by fix apply. A lesson that is true only of this
//                           game becomes a project-fact proposal (savers.h propose_fact), written to AGENTS.md only when the user
//                           accepts it. The cost of the model call is returned and, in a run, added to the run.
//
// It runs on demand (ai.retrospective, `factoria ai retrospective`, the Feedback panel's button) and, when ai.json
// "savers.retrospective" is on, after a run that took retrospectiveSteps model calls or cost retrospectiveCostUsd
// (retrospective_due). It runs at most once per run and never inside another retrospective (RetrospectiveGuard).
#pragma once

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/ai/session.h"
#include "fa/core/json.h"
#include "fa/core/process.h"
#include "fa/core/types.h"
#include "fa/tooling/efficiency.h"

namespace fa::ai {

// What the mechanical pass looks for.
inline constexpr int kRetroMinFailures = 3;               // the same (command, error code) failing this many times in a session
inline constexpr int kRetroMinRepeats = 3;                // the same doc or file read this many times in a session
inline constexpr std::uint64_t kRetroBigResultBytes = 40u * 1024;  // a tool result over this (about 10k tokens) is "big"
inline constexpr int kRetroMinBigResults = 2;             // ... and this many of the same command make a candidate
inline constexpr int kRetroScreenshotStreak = 5;          // consecutive steps that take a screenshot
inline constexpr int kRetroLoopSteps = 12;                // steps of an edit-run-check loop on one or two systems
inline constexpr int kRetroLoopRepeats = 6;               // ... in which one command was called this many times
inline constexpr std::int64_t kRetroLongWaitMs = 60 * 1000;  // one tool call that kept the run waiting this long
inline constexpr std::int64_t kRetroLongWaitTotalMs = 5 * 60 * 1000;  // ... or calls of one command that add up to this
// What a retrospective reads and returns.
inline constexpr int kRetroMaxSessions = 40;              // transcripts read when none is named (the newest)
inline constexpr int kRetroMaxSessionsExamined = 200;     // file names looked at to find them
inline constexpr int kRetroMaxSpans = 8;                  // spans of evidence kept per candidate (the largest)
inline constexpr int kRetroMaxCandidates = 12;            // candidates returned
inline constexpr int kRetroModelCandidates = 8;           // candidates the model reads
inline constexpr int kRetroMaxEntries = 3;                // entries one retrospective files
inline constexpr int kRetroMaxFacts = 3;                  // project-fact proposals one retrospective makes

struct RetroCandidate {
    std::string id;           // stable: "failure:scene.load:not_found", "reread:docs.read:NAVIGATION.md", "screenshots", ...
    std::string pattern;      // failure, reread, big_result, screenshots, long_wait, loop, workaround
    std::string summary;      // one line with the numbers
    std::string command;      // the engine command or tool involved ("" = none)
    std::string ref;          // what it acted on, for reread ("" = none)
    std::string code;         // the error code, for failure
    std::string relatedEntry; // workaround: the ENGINE_FEEDBACK entry that records it
    int count = 0;            // how many times it happened (calls, results, steps)
    std::vector<EfficiencySpan> spans;  // the evidence, largest first, never overlapping within a session
    EfficiencyMeasure measured;         // all the spans
    double maxShare = 0;      // the largest share of `measured` a fix could remove, from the pattern (0.01 to 1); the model may say less
    EfficiencyMeasure potential;        // measured x maxShare
    std::string suggestedFix; // the cheapest fix type that usually removes this pattern
    std::string appliesTo;    // every-game, genre or feature: what it usually applies to
    bool projectOnly = false; // about the project's own files: a project fact, not engine feedback
    Json to_json() const;
};

// The candidates of `sessions` (read with load_efficiency_session): the ones whose potential saving reaches the lowest threshold of the
// table (a doc or guide: 10 minutes or 100k tokens), ranked by that saving, at most kRetroMaxCandidates. `feedbackEntries` (the
// "entries" of the project's ENGINE_FEEDBACK.json, or null) lets the pass recognise a workaround that is already recorded.
std::vector<RetroCandidate> find_retro_candidates(const std::vector<EfficiencySession>& sessions, const Json& feedbackEntries = Json());

struct RetrospectiveOptions {
    // The transcripts to read, by id (ai.session_timeline and `.factoria/ai/sessions` name them). Empty = the newest kRetroMaxSessions.
    std::vector<std::string> sessions;
    // Only transcripts that began at or after this UTC date or time ("2026-11-01" or "2026-11-01T09:30"). Empty = all.
    std::string since;
    // Only transcripts whose id starts with this (a run's own transcripts: its stamp). Empty = any.
    std::string idPrefix;
    // true: the mechanical pass only. No model is asked and nothing is filed.
    bool candidatesOnly = false;
    // The role whose model writes the entries (the fast role; the orchestrator when it is off).
    std::string role = kRoleFast;
    // Used instead of the real providers (tests).
    ProviderFactory providerFactory;
    ProviderRuntime runtime;
    const CancelFlag* cancel = nullptr;
    // Told what the model call used and cost (US dollars), once per call.
    std::function<void(const Usage&, double costUsd)> onUsage;
};

struct RetrospectiveResult {
    Json sessions = Json::array();     // [{id, agent, steps, minutes, tokens, costUsd, estimated}] of the transcripts read
    std::vector<RetroCandidate> candidates;
    int alreadyFiled = 0;              // candidates left out because an open efficiency entry already counts their evidence
    Json filed = Json::array();        // [{candidate, id, merged, alreadyCounted, title, fixType, saving, measured}]
    Json dropped = Json::array();      // [{candidate, code, reason}]: candidates the model gave up on or the gate refused, and why
    Json facts = Json::array();        // [{candidate, id, line}]: project-fact proposals
    Json model = Json();               // {role, provider, model} of the call, null when none was made
    Usage usage;
    double costUsd = 0;                // what the model call cost
    std::string note;                  // one sentence: what happened
    Json to_json() const;
};

// Runs the retrospective over `projectDir`. Errors teach: no such session (with the ids there are), a `since` that is not a date,
// a retrospective already running in this process (code "busy"). A model that cannot be asked (no key, role off) is not an error:
// the candidates come back, `model` is null and `note` says why. Never sends anything and never changes the sharing mode.
Result<RetrospectiveResult> run_retrospective(const AiConfig& cfg, const RetrospectiveOptions& options, const std::string& projectDir);

// The automatic run: true when savers.retrospective is on and a run of `steps` model calls that cost `costUsd` reaches one of the two
// thresholds.
bool retrospective_due(const Savers& savers, int steps, double costUsd);
// True while a retrospective runs on this thread: a run it starts must not start another.
bool retrospective_running_here();

}  // namespace fa::ai
