#include "feedback_share_model.h"

#include <algorithm>

#include "fa/core/strings.h"

namespace fa::editor {

namespace {
std::string shared_status(const Json& entry) {
    if (!entry.contains("shared") || !entry["shared"].is_object()) return {};
    return entry["shared"].value("status", std::string());
}
std::string shared_reason(const Json& entry) {
    return entry.contains("shared") && entry["shared"].is_object() ? entry["shared"].value("reason", std::string()) : std::string();
}
std::string str_of(const Json& j, const char* key) {
    return j.is_object() && j.contains(key) && j[key].is_string() ? j[key].get<std::string>() : std::string();
}
}  // namespace

ShareColumn share_column(const Json& entry) {
    ShareColumn c;
    const std::string status = shared_status(entry), reason = shared_reason(entry);
    if (status == "pending") {
        c.kind = ShareKind::Waiting;
        c.label = "waiting";
        c.tooltip = "In the outbox: it goes when the sharing mode allows it (Always: soon; Ask me each time: after you press Send in Send feedback).";
    } else if (status == "sent") {
        c.kind = ShareKind::Sent;
        c.label = "sent";
        c.tooltip = "The engine developers have this one.";
    } else if (status == "rejected") {
        c.kind = ShareKind::Rejected;
        c.label = "rejected";
        c.tooltip = reason.empty() ? "The sanitizer or the server refused this text." : reason;
    } else if (status == "declined") {
        c.kind = ShareKind::Rejected;
        c.label = "declined";
        c.tooltip = "The engine developers rejected this report" + (reason.empty() ? std::string(".") : ": " + reason);
    } else if (status == "skipped") {
        c.kind = ShareKind::Skipped;
        c.label = "skipped";
        c.tooltip = reason.empty() ? "Not sent: sharing is off or it was left out of Send feedback. Send feedback offers it again, unchecked." : reason;
    } else {
        c.label = "not sent";
        c.tooltip = "Not sent yet. Send feedback lists it with the text that would leave this computer.";
    }
    return c;
}

ShareFields ShareFields::from_entry(const Json& entry) {
    ShareFields f;
    if (!entry.contains("share") || !entry["share"].is_object()) return f;
    const Json& s = entry["share"];
    f.title = str_of(s, "title");
    f.missing = str_of(s, "missing");
    f.suggestion = str_of(s, "suggestion");
    f.workaround = str_of(s, "workaround");
    return f;
}

Json ShareFields::to_json() const {
    Json j = Json::object({{"title", title}, {"missing", missing}});
    if (!suggestion.empty()) j["suggestion"] = suggestion;
    if (!workaround.empty()) j["workaround"] = workaround;
    return j;
}

int text_chars(const std::string& text) {
    int n = 0;
    for (unsigned char c : text)
        if ((c & 0xC0) != 0x80) ++n;
    return n;
}

const std::vector<ShareLimit>& share_limits() {
    static const std::vector<ShareLimit> limits = {{"title", kShareTitleMin, kShareTitleMax},
                                                   {"missing", kShareMissingMin, kShareMissingMax},
                                                   {"suggestion", 0, kShareSuggestionMax},
                                                   {"workaround", 0, kShareWorkaroundMax}};
    return limits;
}

const std::string& share_field_text(const ShareFields& f, const std::string& field) {
    if (field == "title") return f.title;
    if (field == "missing") return f.missing;
    if (field == "suggestion") return f.suggestion;
    return f.workaround;
}

std::string share_fields_problem(const ShareFields& fields) {
    for (const ShareLimit& l : share_limits()) {
        const std::string text(trim(share_field_text(fields, l.field)));
        const int n = text_chars(text);
        if (n > l.max) return std::string("share.") + l.field + " is too long (at most " + std::to_string(l.max) + " characters, it has " + std::to_string(n) + ")";
        if (n < l.min) {
            if (n == 0) return std::string("share.") + l.field + " is missing (at least " + std::to_string(l.min) + " characters)";
            return std::string("share.") + l.field + " is too short (at least " + std::to_string(l.min) + " characters, it has " + std::to_string(n) + ")";
        }
    }
    return {};
}

ShareSuggestion suggest_share(const Json& entry, const EngineNames& engine, const ProjectNames& project) {
    ShareSuggestion out;
    ShareFields raw;
    raw.title = std::string(trim(str_of(entry, "title")));
    raw.missing = std::string(trim(str_of(entry, "missing")));
    raw.suggestion = std::string(trim(str_of(entry, "suggestion")));
    if (raw.title.empty() || raw.missing.empty()) {
        out.reason = "the entry needs a title and a description of what is missing to make a share text from";
        return out;
    }
    const SanitizedShare clean = sanitize_share(raw.to_json(), engine, project);
    out.removed = clean.removed;
    if (!clean.ok) {
        out.reason = clean.reason();
        return out;
    }
    out.fields.title = clean.title;
    out.fields.missing = clean.missing;
    out.fields.suggestion = clean.suggestion;
    out.ok = true;
    return out;
}

std::vector<std::string> entries_to_queue(const Json& doc) {
    std::vector<std::string> ids;
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return ids;
    for (const Json& e : doc["entries"]) {
        if (!e.is_object() || e.value("status", std::string("open")) != "open") continue;
        if (!e.contains("share") || !e["share"].is_object() || e.contains("shared")) continue;
        ids.push_back(e.value("id", std::string()));
    }
    return ids;
}

// ------------------------------------------------------------------------------------------------ the Send feedback window

namespace {
// A candidate text sanitized, within the limits, and the entry as the server would receive it. False + `problem` otherwise.
bool finish_row(SendRow& row, const Json& entry, const ShareFields& text, const EngineNames& engine, const ProjectNames& project,
                std::string& problem) {
    ShareFields t;
    t.title = std::string(trim(text.title));
    t.missing = std::string(trim(text.missing));
    t.suggestion = std::string(trim(text.suggestion));
    t.workaround = std::string(trim(text.workaround));
    if (problem = share_fields_problem(t); !problem.empty()) return false;
    const SanitizedShare clean = sanitize_share(t.to_json(), engine, project);
    if (!clean.ok) {
        problem = clean.reason();
        return false;
    }
    ShareFields out;
    out.title = clean.title;
    out.missing = clean.missing;
    out.suggestion = clean.suggestion;
    out.workaround = clean.workaround;
    if (problem = share_fields_problem(out); !problem.empty()) return false;
    row.fields = out;
    row.removed = clean.removed;
    row.sent = build_share_entry(entry, clean);
    return true;
}
}  // namespace

bool entry_can_be_sent(const Json& e) {
    if (!e.is_object() || e.value("status", std::string("open")) != "open") return false;
    if (e.contains("shared") && e["shared"].is_object()) {
        const std::string st = e["shared"].value("status", std::string());
        if (st == "rejected") return false;
        if (st == "sent") return e["shared"].value("occurrences", 1) < std::min(e.value("occurrences", 1), kMaxSharedOccurrences);
    }
    return true;
}

std::vector<SendRow> plan_send(const Json& doc, const SendOutbox& outbox, const EngineNames& engine, const ProjectNames& project) {
    std::vector<SendRow> rows;
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return rows;
    for (const Json& e : doc["entries"]) {
        if (!entry_can_be_sent(e)) continue;
        const std::string id = e.value("id", std::string());
        const std::string status = shared_status(e);
        const bool waiting = outbox.waiting.count(id) > 0;
        if (status == "pending" && !waiting && outbox.queued.count(id) > 0) continue;  // already on its way
        SendRow row;
        row.id = id;
        row.category = e.value("category", std::string());
        row.severity = e.value("severity", std::string());
        row.reviewed = e.contains("reviewed") && e["reviewed"].is_boolean() && e["reviewed"].get<bool>();
        row.resend = status == "sent";
        row.leftOut = status == "skipped";
        row.waiting = waiting;
        row.hasShare = e.contains("share") && e["share"].is_object();

        std::string problem;
        bool ok = false;
        if (row.hasShare) {
            ok = finish_row(row, e, ShareFields::from_entry(e), engine, project, problem);
            if (!ok) row.note = "The saved share text cannot be sent (" + problem + ")";
        }
        if (!ok) {
            const ShareSuggestion sug = suggest_share(e, engine, project);
            if (sug.ok) {
                std::string again;
                ok = finish_row(row, e, sug.fields, engine, project, again);
                if (ok) {
                    row.hasShare = false;
                    row.madeHere = true;
                    row.note = row.note.empty() ? std::string() : row.note + "; this text was made from the entry instead.";
                } else {
                    problem = problem.empty() ? again : problem + "; and the text made from the entry: " + again;
                }
            } else {
                problem = problem.empty() ? sug.reason : problem + "; and no text can be made from the entry: " + sug.reason;
            }
        }
        row.canSend = ok;
        if (ok) {
            row.checked = !row.leftOut;
            if (row.leftOut && row.note.empty()) row.note = "You left it out last time.";
        } else {
            row.problem = problem;
            row.note.clear();
        }
        rows.push_back(std::move(row));
    }
    return rows;
}

bool set_send_text(SendRow& row, const Json& entry, const ShareFields& text, const EngineNames& engine, const ProjectNames& project,
                   std::string& problem) {
    SendRow next = row;
    if (!finish_row(next, entry, text, engine, project, problem)) return false;
    row = std::move(next);
    return true;
}

std::optional<FeedbackShareEdit> share_edit_for_send(const Json& entry, const ShareFields& shown, bool reviewPassed) {
    const bool hasStored = entry.contains("share") && entry["share"].is_object();
    const bool wasReviewed = entry.contains("reviewed") && entry["reviewed"].is_boolean() && entry["reviewed"].get<bool>();
    const bool reviewed = reviewPassed || wasReviewed;
    if (!hasStored || !(ShareFields::from_entry(entry) == shown)) {
        FeedbackShareEdit edit;
        edit.share = shown.to_json();
        edit.reviewed = reviewed;
        return edit;
    }
    if (reviewed && !wasReviewed) {
        FeedbackShareEdit edit;
        edit.reviewed = true;
        return edit;
    }
    return std::nullopt;
}

SendApplied apply_send(const ShareEnv& env, const std::string& file, const std::string& projectDir, const EngineNames& engine,
                       const std::vector<SendChoice>& choices) {
    SendApplied out;
    const ShareSettings settings = load_share_settings(env);
    const ShareMode mode = effective_share_mode(settings, projectDir);
    out.mode = mode;
    if (mode != ShareMode::Always && mode != ShareMode::Ask) {
        out.error = mode == ShareMode::Never ? "Sharing is off for this project (File > Feedback Settings turns it on): nothing was sent."
                                             : "Sharing is not set up yet: nothing was sent.";
        return out;
    }
    auto loaded = load_feedback(file);
    if (!loaded.ok()) {
        out.error = loaded.error().to_string();
        return out;
    }
    auto entry_of = [&](const std::string& id) -> Json {
        for (const Json& e : (*loaded)["entries"])
            if (e.is_object() && e.value("id", std::string()) == id) return e;
        return Json();
    };
    std::vector<std::string> toQueue, toSkip;
    for (const SendChoice& c : choices) {
        if (!c.send) {
            toSkip.push_back(c.id);
            continue;
        }
        const Json e = entry_of(c.id);
        if (e.is_null()) {
            out.rows.push_back({c.id, "failed", "the entry is not in the feedback file any more"});
            continue;
        }
        if (auto edit = share_edit_for_send(e, c.text, c.reviewPassed)) {
            if (auto r = set_feedback_share_file(file, c.id, *edit); !r) {
                out.rows.push_back({c.id, "failed", "the share text could not be stored: " + r.error().message});
                continue;
            }
        }
        toQueue.push_back(c.id);
    }
    if (!toQueue.empty()) {
        auto q = share_queue(env, file, projectDir, engine, toQueue);
        if (!q.ok()) {
            for (const std::string& id : toQueue) out.rows.push_back({id, "failed", q.error().message});
        } else {
            std::vector<std::string> keys;
            for (const std::string& id : toQueue) {
                SendRowResult r{id, "failed", "it was not queued"};
                for (const ShareEntryReport& rep : q->entries) {
                    if (rep.id != id) continue;
                    if (rep.status == "queued" || rep.status == "waiting") {
                        r.status = "queued";
                        r.message.clear();
                        keys.push_back(share_item_key(file, id));
                    } else if (rep.status == "rejected") {
                        r.status = "rejected";
                        r.message = rep.reason;
                    } else {
                        r.message = rep.reason.empty() ? rep.status : rep.reason;
                    }
                }
                out.rows.push_back(std::move(r));
            }
            // Pressing Send is the answer an item that waits needs (ask mode; under always, an item queued earlier or by an older version).
            if ((mode == ShareMode::Ask || mode == ShareMode::Always) && !keys.empty()) (void)share_confirm(env, keys);
        }
    }
    if (!toSkip.empty()) {
        share_skip(env, file, toSkip, "left out in Send feedback");
        for (const std::string& id : toSkip) out.rows.push_back({id, "skipped", {}});
    }
    return out;
}

}  // namespace fa::editor
