// The Engine Feedback panel's view of sharing (docs/ENGINE_FEEDBACK.md, "Sharing with the engine developer"): what the share
// column says, the share text as four editable fields with their limits, a suggested share text, and which entries to queue.
// No UI and no network in here, so tests can drive it (tools/editor/tests/feedback_share_tests.cpp).
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/tooling/feedback_share.h"

namespace fa::editor {

enum class ShareKind { NotShared, Waiting, Sent, Rejected, Skipped };

struct ShareColumn {
    ShareKind kind = ShareKind::NotShared;
    std::string label;    // the word in the panel's share column
    std::string tooltip;  // why: the reason of a rejection or a skip, what waiting means...
};
// What the share column shows for a feedback entry: no `share` -> "-" (not shared: it stays on this computer); `share` with no
// `shared` -> "not shared"; shared.status pending -> "waiting", sent -> "sent", rejected -> "rejected" (reason), skipped -> "skipped".
ShareColumn share_column(const Json& entry);

// The four texts of `share`.
struct ShareFields {
    std::string title, missing, suggestion, workaround;
    static ShareFields from_entry(const Json& entry);  // empty fields when the entry has no `share`
    Json to_json() const;                              // {title, missing, suggestion?, workaround?}: empty optional ones left out
    bool empty() const { return title.empty() && missing.empty() && suggestion.empty() && workaround.empty(); }
    bool operator==(const ShareFields& o) const {
        return title == o.title && missing == o.missing && suggestion == o.suggestion && workaround == o.workaround;
    }
};

// Characters (not bytes) of a UTF-8 text, as the limits count them.
int text_chars(const std::string& text);

struct ShareLimit {
    const char* field;  // title | missing | suggestion | workaround
    int min, max;       // characters; min 0 = optional
};
const std::vector<ShareLimit>& share_limits();
// The field's text and the limit that applies to it.
const std::string& share_field_text(const ShareFields& fields, const std::string& field);
// "" when every field is within its limits (and the required ones are filled in); else the first problem, a sentence that says
// which field and what the limit is ("share.title is too short (at least 8 characters)").
std::string share_fields_problem(const ShareFields& fields);

struct ShareSuggestion {
    bool ok = false;
    ShareFields fields;               // the sanitized text, when ok
    std::vector<Removal> removed;     // what the sanitizer took out (names of the project, paths, quotes...)
    std::string reason;               // why there is no suggestion (not ok)
};
// A share text made from the entry's own `title`, `missing` and `suggestion` (the workaround is about the game's files and is
// left out), run through the sanitizer so the project's names, paths and quoted text come out. It is a starting point for the
// person to read and edit: it can still mention things only the person knows are the game's.
ShareSuggestion suggest_share(const Json& entry, const EngineNames& engine, const ProjectNames& project);

// The ids of the open entries the panel has to queue after a mode change: a `share` and no `shared` yet. An entry whose
// `shared` is skipped, rejected or sent is left alone (a "Don't send" stays a "Don't send").
std::vector<std::string> entries_to_queue(const Json& feedbackDoc);

}  // namespace fa::editor
