// The engine developer's side of feedback sharing (docs/design/FEEDBACK_SHARING.md, "Developer side (CLI)"): the admin
// client of the feedback server, `feedback pull` with its classification and quarantine, ban / unban / delete / stats.
// The commands are in cmd_feedback_admin.cpp; everything here is testable without a network: the HTTP transport and the
// model that classifies are injected (FeedbackAdminEnv).
#pragma once

#include <functional>
#include <map>
#include <string>
#include <vector>

#include "args.h"
#include "fa/ai/config.h"
#include "fa/ai/http.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa::cli {

// One question to a model and its answer (the text). The system text is the instructions, the user text the data.
using FeedbackModel = std::function<Result<std::string>(const std::string& system, const std::string& user)>;

// What the commands reach the world through. The defaults are the real ones; tests replace the members.
struct FeedbackAdminEnv {
    ai::EnvLookup env = ai::system_env();  // HOME / APPDATA / FACTORIA_AI_CONFIG / API keys
    ai::HttpTransport transport;           // empty = ai::http_request
    FeedbackModel
        model;  // empty = the model of the "fast" role of the user's ai.json, or the orchestrator when it is off (make_ai_feedback_model)
    std::function<std::string()> today;  // "YYYY-MM-DD" (UTC); empty = the clock
};
FeedbackAdminEnv& feedback_admin_env();  // process-wide, used by the commands
std::string feedback_admin_today(const FeedbackAdminEnv& e);

// ---- feedback-admin.json ---------------------------------------------------------------------------------------------
// {endpoint, adminToken, cursor?}: written by tools/feedback-server/deploy.sh next to the user's ai.json; `pull` keeps the
// cursor in it. It holds a secret: never print adminToken.
struct FeedbackAdminConfig {
    std::string path;
    std::string endpoint;  // without a trailing slash
    std::string adminToken;
    std::string cursor;
};
std::string user_config_dir(const ai::EnvLookup& env);             // the folder of the user's ai.json
std::string feedback_admin_config_path(const ai::EnvLookup& env);  // <folder>/feedback-admin.json
std::string default_feedback_inbox(const ai::EnvLookup& env);      // <folder>/feedback-inbox
Result<FeedbackAdminConfig> load_feedback_admin_config(const std::string& path);
// Writes the cursor and keeps every other key of the file (owner-only permissions on Linux and macOS).
Result<void> save_feedback_admin_cursor(const std::string& path, const std::string& cursor);

// The nearest parent folder of `path` (itself included) that has a .git; "" when there is none.
std::string git_checkout_root(const std::string& path);

// ---- the admin client ------------------------------------------------------------------------------------------------
// One request to the server. A 2xx answer with {ok: true, ...} gives that object; everything else is an Error with a message
// that says what happened and a hint that says what to do (unreachable server, wrong token, banned, rate limit, a page
// that is not the server, the server's own {error: {code, message, hint}}).
Result<Json> feedback_admin_request(const FeedbackAdminConfig& cfg, const ai::HttpTransport& transport,
                                    const std::string& method, const std::string& path, const Json* body = nullptr);

// ---- classification --------------------------------------------------------------------------------------------------
struct ReportVerdict {
    std::string verdict;  // valid | doubtful | junk
    std::string reason;
};
// Judges `reports` (server report objects) in batches of `batchSize` with one model call each. Reports the model did not
// judge (or a failed batch) are missing from the result; `error` says why when a batch failed.
std::map<std::string, ReportVerdict> classify_reports(const FeedbackModel& model, const std::vector<Json>& reports,
                                                      std::string& error, std::size_t batchSize = 10);
// The cheap model for classification: the role "fast" of the user's ai.json. Error (what is missing and how to set it up)
// when the role is off or its provider has no key / is not installed.
Result<FeedbackModel> make_ai_feedback_model(const FeedbackAdminEnv& e);

// ---- pull ------------------------------------------------------------------------------------------------------------
enum class ClassifyMode { Auto, On, Off };
struct PullOptions {
    std::string out;           // inbox folder; empty = default_feedback_inbox
    bool outExplicit = false;  // --out was given: the inbox may be inside a git checkout
    ClassifyMode classify = ClassifyMode::Auto;
    // Ignore the saved cursor and read everything from the start. The server keeps a report that merges (the same gap reported
    // again) at its place in the arrival order and only raises its `occurrences`, so an incremental pull never sees the new
    // count: a full pull updates the occurrences of the entries already in the inbox (by shareId) and saves the final cursor.
    bool full = false;
    int pageSize = 500;
    int maxPages = 200;
};
struct PullSummary {
    std::string inbox;
    int pages = 0;
    int fetched = 0;  // reports the server sent
    int added = 0;    // new entries in an installation's file
    int updated = 0;  // known entries whose occurrences went up
    int known = 0;    // known and unchanged (also those in the archive and the quarantine)
    int invalid = 0;  // reports this version could not read (the reasons are in `warnings`)
    int valid = 0, doubtful = 0, junk = 0, unclassified = 0;
    // New reports whose claim of a missing feature fails the check (the engine has it): each is marked `suggestedRejection` in the
    // inbox. [{shareId, id, installKey, title, reason}]. Confirm with `feedback reject --suggested`, drop with `feedback keep`.
    Json suggestions = Json::array();
    // The efficiency entries of the whole inbox ranked by what fixing them would save across installations, each with its verdict
    // and a ready reason for `feedback reject` (rank_efficiency, fa/tooling/efficiency.h); [] when the inbox has none.
    Json efficiency = Json::array();
    int alreadyRejected = 0;     // reports the server already carries a rejection for (imported as rejected entries)
    std::string classification;  // what happened: "5 valid, 1 doubtful, 2 junk" or why it was skipped
    std::vector<std::string> installations;  // installKeys that got a file written
    std::vector<std::string> warnings;
    std::string cursor;  // the saved cursor
    Json to_json() const;
};
Result<PullSummary> feedback_pull(const PullOptions& options, const FeedbackAdminEnv& e);

// ---- quarantine ------------------------------------------------------------------------------------------------------
std::string quarantine_path(const std::string& inbox);
Json quarantine_list(const std::string& inbox);  // the quarantined items: {shareId, installKey, reason, date, entry}
// Moves one report back into its installation's file with a new id. Error when the shareId is not quarantined.
Result<Json> quarantine_restore(const std::string& inbox, const std::string& shareId, const std::string& today);
Result<int> quarantine_clear(const std::string& inbox);  // the number of items dropped

// ---- bans, delete, stats ---------------------------------------------------------------------------------------------
enum class KeyKind { Unknown, Install, Reporter };
// Decides what `key` is: "install:KEY" / "reporter:KEY", the shareId of a report in the inbox (its installation), a folder
// of the inbox (an installation). Anything else is ambiguous: an Error that says to pass --install or --reporter.
Result<std::pair<KeyKind, std::string>> resolve_ban_key(const std::string& key, KeyKind forced,
                                                        const std::string& inbox);
// Removes the entry with this shareId from the inbox (files and quarantine); the number removed.
int remove_local_report(const std::string& inbox, const std::string& shareId);

// ---- verdicts: reject / unreject / keep ------------------------------------------------------------------------------
// The engine developer (usually an AI) answers a pulled report: reject it with a reason the installation shows to its person, take
// that back, or keep it. Everything is non-interactive.
struct RejectItem {
    std::string shareId, reason;
};
// A reason as the server takes it: plain text, whitespace collapsed (sanitize_status_reason), 1 to kFeedbackReasonMax characters.
Result<std::string> checked_reject_reason(const std::string& text);
// A batch file: [{shareId, reason}, ...] or {"rejections": [...]}. `what` names the file in the errors.
Result<std::vector<RejectItem>> parse_reject_batch(const std::string& jsonText, const std::string& what);
// The inbox entries that carry a suggestedRejection and are still open: [{shareId, id, installKey, title, reason}].
Json inbox_suggestions(const std::string& inbox);
struct VerdictOutcome {
    std::vector<std::string> done;      // shareIds the server rejected / restored
    std::vector<std::string> notFound;  // shareIds the server does not have
    int localMarked = 0;                // entries of the inbox (and quarantined items) updated
    Json to_json(const std::string& doneName) const;
};
// Rejects on the server (batches of 50) and marks the entries in the inbox (status rejected, statusBy developer, the reason; a
// quarantined item gets its `rejection`). Entries the server could not find are left alone.
Result<VerdictOutcome> feedback_reject_reports(const FeedbackAdminConfig& cfg, const ai::HttpTransport& transport,
                                               const std::string& inbox, const std::vector<RejectItem>& items);
// Takes the rejection back on the server; the inbox entries are open again.
Result<VerdictOutcome> feedback_unreject_reports(const FeedbackAdminConfig& cfg, const ai::HttpTransport& transport,
                                                 const std::string& inbox, const std::vector<std::string>& shareIds);
// Drops the suggestedRejection of the inbox entries (keep them); the number of entries changed.
Result<int> feedback_keep_reports(const std::string& inbox, const std::vector<std::string>& shareIds);

// "the Entry id" text offered after `feedback update --status fixed-in-engine` on an inbox entry: the `fixed add` command
// that records the fix. "" for an entry that is not from the inbox.
std::string fixed_add_offer(const Json& entry);
// The `reject` command that tells the installation about an inbox entry closed as rejected. "" for an entry that is not from the inbox.
std::string reject_offer(const Json& entry);

// The `feedback` subcommands of this file: pull, quarantine, reject, unreject, keep, ban, unban, bans, delete, stats, fixed.
std::vector<Command> make_feedback_admin_commands();

}  // namespace fa::cli
