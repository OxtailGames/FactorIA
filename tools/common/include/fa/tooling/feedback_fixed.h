// The list of engine gaps fixed in each release (feedback/fixed.json, embedded in the binary) and what a project does with
// it: every open local feedback entry that matches a fix is closed with the version that fixed it
// (docs/design/FEEDBACK_SHARING.md, "Fixed list"). The developer maintains the list with `factoria feedback fixed`.
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kFeedbackFixedFormat = "factoria.feedback-fixed/1";
inline constexpr const char* kFeedbackFixedPath = "feedback/fixed.json";

// Checks a fixed list document: format, and for each fix a category, one or more titles and `fixedIn`. Errors say where.
Result<void> validate_feedback_fixed(const Json& list);
// The list embedded in this binary (an empty list when the build has none).
Result<Json> embedded_feedback_fixed();

struct FixedClosed {
    std::string id;       // the local entry, FB-0003
    std::string fixedIn;  // the engine version
    std::string title;    // the entry's title
};
struct FixedCheckResult {
    int checked = 0;                  // open entries looked at
    std::vector<FixedClosed> closed;  // set to fixed-in-engine by this call
    Json to_json() const;
};

// Open entries of `feedbackPath` (and none of the archive) that match a fix of `list`: same category, or the same family
// (the part before the first "-"), and feedback_entry_similarity of the entry's `title` or `share.title` with one of the
// fix's titles at or above 0.7. A match becomes `fixed-in-engine`, engineIssue "FactorIA <fixedIn>", with the note "fixed
// in FactorIA <fixedIn>: check whether the workaround can go". It moves to the archive on the next feedback.archive.
Result<FixedCheckResult> check_fixed_feedback(const std::string& feedbackPath, const Json& list);
// Same with the embedded list. A missing file is not an error: nothing to check.
Result<FixedCheckResult> check_fixed_feedback_file(const std::string& feedbackPath);

// feedback.check_fixed, bound to the project's feedback file (called by register_feedback_share_commands).
void register_feedback_fixed_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
