// Does the engine already have what a feedback report says it lacks? (docs/ENGINE_FEEDBACK.md, "The check before filing").
//
// A report that names a gap ("No one-way platforms", "Add Collider2D.oneWay") is checked against what the engine publishes:
// the reflected components and their fields, the commands, the scripting API (tools/common/api_since.json). When the thing the
// report calls missing exists, the report is refused with what exists, its doc string and where it is documented; the person
// (or AI) can then read the docs, or file a bug if it does not work as documented.
//
// The rule is conservative: a report is refused only when its own words tie the claim to an existing name:
//   - a claim lead ("no", "missing", "add", "lacks", "without", "needs", "does not have", ...) right before the words, or
//     "<name> does not exist / is missing" right after them;
//   - the words are an existing identifier (Collider2D.oneWay), or a field name written as words ("one-way" = oneWay) that
//     belongs to a component the report names, or that is distinctive on its own (two words, or camelCase);
//   - nothing in the report says the thing exists but misbehaves ("ignored", "no effect", "does not work", "I set ...").
// Asking for an extra option on an existing component (the field is not there) is never refused. When in doubt it accepts, and
// returns the related documentation instead (`related`).
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

// The title of the example in the docs of feedback.report: an invented gap, never to be filed as it is.
inline constexpr const char* kFeedbackExampleTitle = "No fluid simulation";

struct ClaimInput {
    std::string title, missing, suggestion;
};

struct ClaimMatch {
    std::string kind;          // field | component | command | script | example
    std::string name;          // the engine's name for it: "Collider2D.oneWay", "Tilemap", "scene.duplicate"
    std::string phrase;        // the words of the report that name it ("one-way")
    std::string where;         // title | missing | suggestion
    std::string doc;           // its doc string ("" when only the published name is known)
    std::string documentedIn;  // "docs/COMPONENTS.md:384 (Collider2D)", "" when no page was found
    Json to_json() const;
};

struct ClaimResult {
    std::vector<ClaimMatch> matches;  // empty = nothing in the report names something the engine has
    Json related = Json::array();     // related docs: [{doc, path, heading, line}] (filled when asked for)

    bool refused() const { return !matches.empty(); }
    // The teaching text of a refusal: what exists, its doc string, where it is documented, what to do if it does not work.
    std::string message() const;
    std::string hint() const;
    // The same on one line, at most kFeedbackReasonMax characters: what is stored as the `statusReason` of a rejected entry.
    std::string reason() const;
    // {exists, matches[], related[], message?, hint?}
    Json to_json() const;
};

// `registry` (optional): its commands are known too, with their summaries. `relatedMax`: how many related docs to return.
// Deterministic; reads the reflection registry, the bundled api_since.json and the embedded docs only.
ClaimResult check_feedback_claim(const ClaimInput& input, const CommandRegistry* registry = nullptr,
                                 int relatedMax = 0);

// The same for an entry of ENGINE_FEEDBACK.json (title, missing, suggestion).
ClaimResult check_feedback_entry_claim(const Json& entry, const CommandRegistry* registry = nullptr);

// Rejects the OPEN entries of the feedback file whose claim fails the check: status rejected, statusBy "engine", the reason being the
// teaching text (what exists, where it is documented). An entry whose claimCheck is "dismissed" (a person reopened it) is left
// alone. Returns the ids rejected.
Result<std::vector<std::string>> reject_claimed_feedback_file(const std::string& path,
                                                              const CommandRegistry* registry = nullptr);

// Registers feedback.check: the check on its own, for a report that is not filed yet or for the open entries of the project.
void register_feedback_check_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
