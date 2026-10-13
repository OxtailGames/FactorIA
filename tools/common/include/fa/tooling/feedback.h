// ENGINE_FEEDBACK.json: the loop through which game-making AIs tell engine
// developers what the engine lacked (spec: docs/ARCHITECTURE.md, schema:
// schemas/engine-feedback.schema.json).
//
//   add_feedback_entry   append an entry; a similar OPEN entry (same category,
//                        similar title) is merged instead (occurrences++, the
//                        new workaround goes to `notes`).
//   collect_feedback     aggregate many projects' files into a ranked roadmap
//                        report (similar titles grouped, ranked by
//                        occurrences x severity weight).
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
    bool merged = false;  // true when folded into an existing open entry
    int occurrences = 1;
    Json entry;  // the stored entry
};

// Title similarity in [0,1] used for dedupe/grouping (token overlap + edit distance).
double feedback_title_similarity(std::string_view a, std::string_view b);

// Modifies `doc` in place; validates the input (errors teach valid values).
Result<FeedbackAddResult> add_feedback_entry(Json& doc, const FeedbackInput& input);
// Load (or create) `path`, add, save.
Result<FeedbackAddResult> add_feedback_entry_to_file(const std::string& path, const FeedbackInput& input,
                                                     std::string_view projectNameIfNew = {});

struct FeedbackFilter {
    std::string status;    // "" = any
    std::string category;  // "" = any
    std::string severity;  // "" = any
};
Json list_feedback(const Json& doc, const FeedbackFilter& filter = {});  // array of entries

// Updates status and/or engineIssue of entry `id`. Returns the updated entry.
Result<Json> update_feedback_entry(Json& doc, std::string_view id, std::string_view status,
                                   std::string_view engineIssue);

struct FeedbackReport {
    Json json;                 // see collect_feedback
    std::string markdown() const;
};
struct CollectOptions {
    bool includeClosed = false;  // also aggregate fixed/wont-fix/duplicate entries
    double similarity = 0.7;     // title similarity threshold for grouping
};
// `paths`: ENGINE_FEEDBACK.json files, or directories (the file in the dir, or any
// ENGINE_FEEDBACK.json found below it). Report JSON:
// { sources[], projects[], totalEntries, errors[], clusters: [ { rank, title, category, severity, score,
//   totalOccurrences, projects[], entries[{project,id,severity,status}], bestSuggestion,
//   sampleWorkarounds[] } ] }
Result<FeedbackReport> collect_feedback(const std::vector<std::string>& paths, const CollectOptions& opts = {});

// Registers feedback.report, feedback.list, feedback.update bound to <projectDir>/ENGINE_FEEDBACK.json
// (or the project's `feedbackFile`).
void register_feedback_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
