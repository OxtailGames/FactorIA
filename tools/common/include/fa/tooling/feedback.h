// ENGINE_FEEDBACK.json: the loop through which game-making AIs tell engine
// developers what the engine lacked (spec: docs/ARCHITECTURE.md, schema:
// schemas/engine-feedback.schema.json).
//
//   add_feedback_entry   append an entry; a similar OPEN entry (same category,
//                        similar title) is merged instead (occurrences++, the
//                        new workaround goes to `notes`).
//   archive_closed_feedback
//                        move the entries that are not open (fixed-in-engine, wont-fix,
//                        duplicate) to ENGINE_FEEDBACK.archive.json next to the file, so
//                        the file only holds what is still open. Ids stay unique across
//                        both files; a new report that matches an archived
//                        fixed-in-engine entry reopens it (a possible regression).
//   collect_feedback     aggregate many projects' files into a ranked roadmap
//                        report (similar titles grouped, ranked by
//                        severity weight x trust x min(occurrences, 3) per project).
#pragma once

#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/json_schema.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kFeedbackFormat = "factoria.feedback/1";

const std::vector<std::string>& feedback_categories();
const std::vector<std::string>& feedback_severities();  // blocker, major, minor, nice-to-have
const std::vector<std::string>& feedback_statuses();    // open, fixed-in-engine, wont-fix, duplicate
int feedback_severity_weight(std::string_view severity);  // blocker 8, major 4, minor 2, nice-to-have 1

// Fresh document with no entries.
Json create_empty_feedback(std::string_view projectName, std::string_view engineVersion = {});

Result<Json> load_feedback(const std::string& path);
Result<void> save_feedback(const std::string& path, const Json& doc);
// Schema validation plus semantic checks (unique ids). Empty = valid.
std::vector<SchemaError> validate_feedback(const Json& doc);

struct FeedbackInput {
    std::string category;  // required, one of feedback_categories()
    std::string severity;  // required, one of feedback_severities()
    std::string title;     // required
    std::string missing;   // required
    std::string workaround;  // required
    std::vector<std::string> workaroundFiles;
    std::string suggestion;
    std::string effort;  // "", "small", "medium", "large"
    Json reporter;       // null or {kind, agent, model}
};

struct FeedbackAddResult {
    std::string id;
    bool merged = false;  // true when folded into an existing open entry (or an archived fixed one, then `reopened`)
    bool reopened = false;  // true when the report matched an archived fixed-in-engine entry: it is open again, in the file
    int occurrences = 1;
    Json entry;  // the stored entry
};

// Title similarity in [0,1] used for dedupe/grouping (token overlap + edit distance).
double feedback_title_similarity(std::string_view a, std::string_view b);
// Similarity of two entries used by `collect` to group reports of the same gap across projects: title similarity on
// significant tokens (case, punctuation, plurals, "Bug:"/"Generated"-style prefixes and stop words ignored; a short
// title contained in a longer one counts), plus a bonus for the same category (or family: rendering-2d ~
// rendering-3d) and for similar suggestions. Deterministic. Entries are {title, category, suggestion}.
double feedback_entry_similarity(const Json& a, const Json& b);

// Modifies `doc` in place; validates the input (errors teach valid values). `archive` (optional) is the archive document of
// the same file: new ids continue after its ids, and a report matching an archived fixed-in-engine entry (same category,
// similar title, no open match) moves that entry back into `doc`, open, with occurrences + 1 and a note
// "reported again with engine X: regression?" (result.reopened).
Result<FeedbackAddResult> add_feedback_entry(Json& doc, const FeedbackInput& input, Json* archive = nullptr);
// Load (or create) `path` (and its archive, when there is one), add, save what changed.
Result<FeedbackAddResult> add_feedback_entry_to_file(const std::string& path, const FeedbackInput& input,
                                                     std::string_view projectNameIfNew = {});

struct FeedbackFilter {
    std::string status;    // "" = any
    std::string category;  // "" = any
    std::string severity;  // "" = any
};
Json list_feedback(const Json& doc, const FeedbackFilter& filter = {});  // array of entries

// "ENGINE_FEEDBACK.json" -> "ENGINE_FEEDBACK.archive.json": where the closed entries of a feedback file go.
std::string feedback_archive_path(const std::string& feedbackPath);

struct FeedbackArchiveResult {
    int moved = 0;                  // entries moved to the archive by this call
    std::vector<std::string> ids;   // their ids
    int open = 0;                   // entries left in the feedback file
    int archived = 0;               // entries in the archive afterwards
};
// Moves every entry whose status is not "open" from `doc` to `archive` (created by the caller, e.g. create_empty_feedback).
// An id already in the archive is not added twice. Idempotent.
FeedbackArchiveResult archive_closed_feedback(Json& doc, Json& archive);
// Same on files: reads `path` and its archive, writes the archive first, then `path`; nothing is written when no entry is
// closed. A missing `path` is an error that says how to create it.
Result<FeedbackArchiveResult> archive_closed_feedback_file(const std::string& path);

// Entries of the archive of `path` (empty array when there is none).
Json list_archived_feedback(const std::string& path, const FeedbackFilter& filter = {});

// Updates status, engineIssue and/or adds a note to entry `id` of the feedback file or, when it is not there, of its archive.
// An archived entry set to "open" moves back to the file. Returns the updated entry.
Result<Json> update_feedback_file(const std::string& path, std::string_view id, std::string_view status,
                                  std::string_view engineIssue, std::string_view note = {});

// Updates status and/or engineIssue of entry `id`. Returns the updated entry.
Result<Json> update_feedback_entry(Json& doc, std::string_view id, std::string_view status,
                                   std::string_view engineIssue);

struct FeedbackReport {
    Json json;                 // see collect_feedback
    std::string markdown() const;
};
struct CollectOptions {
    bool includeClosed = false;  // also aggregate fixed/wont-fix/duplicate entries (the archive file next to each file counts too)
    double similarity = 0.7;     // title similarity threshold for grouping
};
// `paths`: ENGINE_FEEDBACK.json files, or directories (the file in the dir, or any
// ENGINE_FEEDBACK.json found below it). Report JSON:
// { sources[], projects[], totalEntries, errors[], clusters: [ { rank, title, category, severity, score,
//   totalOccurrences, installations, verifiedInstallations, projects[],
//   entries[{project,id,severity,status,occurrences,trust,similarity}], bestSuggestion, sampleWorkarounds[] } ] }
// score = sum over the cluster's projects (a local project or one installation) of severity weight (the worst of its
// entries) x trust x min(occurrences, 3). trust is 1 for a local project and for an entry whose remote.trust is "verified",
// 0.5 for "anonymous" (entries pulled from the feedback server carry `remote`). installations = projects in the cluster,
// verifiedInstallations = those with a verified entry; totalOccurrences is the uncapped sum.
Result<FeedbackReport> collect_feedback(const std::vector<std::string>& paths, const CollectOptions& opts = {});

// Registers feedback.report, feedback.list, feedback.update, feedback.archive bound to <projectDir>/ENGINE_FEEDBACK.json
// (or the project's `feedbackFile`).
void register_feedback_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
