// feedback/fixed.json: the gaps that engine releases fixed, kept by the engine developer (docs/design/FEEDBACK_SHARING.md,
// "feedback/fixed.json"). A game's open entry that matches a fix is closed with the version that fixed it.
//
//   {"format": "factoria.feedback-fixed/1",
//    "fixes": [{"category": "physics", "titles": ["No one-way platforms"], "fixedIn": "0.11.0", "note": "Collider2D.oneWay"}]}
//
// `factoria feedback fixed add|list` maintain the file. The file is embedded in the binary by the user-side sharing, so its
// format is exactly the one above: do not add keys.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

inline constexpr const char* kFeedbackFixedFormat = "factoria.feedback-fixed/1";
inline constexpr const char* kFeedbackFixedPath = "feedback/fixed.json";  // in the repository and, embedded, in the binary

struct FeedbackFix {
    std::string category;
    std::vector<std::string> titles;
    std::string fixedIn;
    std::string note;  // may be empty (then the key is left out)
};

// A document with no fixes.
Json create_empty_fixed_list();
// The fixes of a document; Error (JSON pointer, what is wrong, how to fix it) when the format or a field is wrong.
Result<std::vector<FeedbackFix>> parse_fixed_list(const Json& doc, std::string_view sourceName = "feedback/fixed.json");
Result<Json> load_fixed_list_file(const std::string& path);  // a missing file is an error that says how to create it

struct FixedAddResult {
    bool created = false;  // the file did not exist and was created by this call
    bool merged = false;   // folded into an existing fix (same category and version, one title in common)
    FeedbackFix fix;       // the stored fix
    int total = 0;         // fixes in the file afterwards
};
// Adds a fix to `path`, creating the file (with an empty list) when it does not exist. Validates the category (did you mean),
// at least one non-empty title and a version like "0.11.0". A fix with the same category and version that shares a title with
// this one (ignoring case) is extended with the new titles (and the note, when given) instead of being repeated.
Result<FixedAddResult> add_fixed_to_file(const std::string& path, const FeedbackFix& fix);

// `<repo>/feedback/fixed.json` for the checkout that contains `startDir`: the nearest parent that has both a .git and a
// feedback/ folder. Error (and how to name the file) when there is none.
Result<std::string> find_fixed_list_path(const std::string& startDir);

// ---------------------------------------------------------------------------------------------- the user side: close what is fixed

// The list embedded in this binary (an empty list when the build has none); validated with parse_fixed_list.
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
