// The Engine Feedback panel's view of sharing (docs/ENGINE_FEEDBACK.md, "Sharing with the engine developer"): what the share
// column says, the share text as four fields with their limits, a suggested share text, which entries to queue, and the rows of
// the Send feedback window (which entries it lists, their text, what Send stores and queues).
// No UI and no network in here, so tests can drive it (tools/editor/tests/feedback_share_tests.cpp).
#pragma once

#include <optional>
#include <set>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/tooling/feedback.h"
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

// ------------------------------------------------------------------------------------------------ the Send feedback window

// The outbox as the window needs it, for one feedback file: the ids queued to go on their own, and the ids that wait for an answer
// (ask mode).
struct SendOutbox {
    std::set<std::string> queued, waiting;
};

// One entry of the Send feedback window.
struct SendRow {
    std::string id, category, severity;
    ShareFields fields;           // the text that leaves: sanitized, within the limits (when canSend)
    Json sent;                    // the entry as the server receives it (build_share_entry); null when !canSend
    std::vector<Removal> removed; // what the sanitizer took out of the text
    bool hasShare = false;        // the entry already carries a `share` that is used
    bool madeHere = false;        // the text was made from the entry's own text (suggest_share), nothing is stored yet
    bool reviewed = false;        // the entry is marked reviewed: the AI check is skipped
    bool resend = false;          // sent before and hit again since (it goes once more)
    bool leftOut = false;         // the person left it out last time (shown again, unchecked)
    bool waiting = false;         // in the outbox waiting for an answer (ask mode)
    bool canSend = false;         // false: shown unchecked and disabled, `problem` says why
    bool checked = false;         // the default state of its checkbox
    std::string problem;          // why it cannot go (not canSend)
    std::string note;             // something to tell: the saved share text was not usable, it was made from the entry...
};

// True for an entry the window may offer: open, not refused by the server or the sanitizer, and not sent yet (or sent and hit
// again since: fewer sends than min(occurrences, kMaxSharedOccurrences)).
bool entry_can_be_sent(const Json& entry);

// The rows of the entries that would be sent: open entries not already sent and not refused, in file order, leaving out those in
// the outbox on their way (Always mode queues an entry that has a `share` by itself). An entry with a `share` uses it (sanitized);
// one without gets a text made with suggest_share; a text that cannot be made within the limits makes a disabled row. Every
// usable row is checked, except those the person left out the last time.
std::vector<SendRow> plan_send(const Json& feedbackDoc, const SendOutbox& outbox, const EngineNames& engine, const ProjectNames& project);

// The row's text replaced by `text` (the AI review rewrote it): sanitized and checked again. False (the row is left as it was) when
// the new text is not usable; `problem` says why.
bool set_send_text(SendRow& row, const Json& entry, const ShareFields& text, const EngineNames& engine, const ProjectNames& project,
                   std::string& problem);

// What Send writes into an entry before queueing it, or nothing when the entry already holds exactly this text and the flag:
// the shown text when the entry has none or another one, and `reviewed` (true when the AI check passed or the entry already was).
std::optional<FeedbackShareEdit> share_edit_for_send(const Json& entry, const ShareFields& shown, bool reviewPassed);

struct SendChoice {
    std::string id;
    bool send = false;           // the checkbox
    ShareFields text;            // the row's text (used when send)
    bool reviewPassed = false;   // the AI review of this text passed
};
struct SendRowResult {
    std::string id;
    std::string status;   // queued | skipped | rejected | failed
    std::string message;  // why, for rejected and failed
};
struct SendApplied {
    std::vector<SendRowResult> rows;
    std::string error;    // nothing was done (sharing is off, the file cannot be read)
    ShareMode mode = ShareMode::Unset;
};
// Send: the checked rows get their text stored (share_edit_for_send), are queued (share_queue; in ask mode also confirmed, because
// pressing Send is the answer) and the unchecked ones are marked skipped (share_skip). It sends nothing: the caller flushes.
SendApplied apply_send(const ShareEnv& env, const std::string& feedbackFile, const std::string& projectDir, const EngineNames& engine,
                       const std::vector<SendChoice>& choices);

}  // namespace fa::editor

