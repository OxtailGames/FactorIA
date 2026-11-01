#include "feedback_share_model.h"

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
    if (!entry.contains("share") || !entry["share"].is_object()) {
        c.label = "-";
        c.tooltip = "No share text: this entry stays on this computer. Write one in the detail below to share the gap with the engine developers.";
        return c;
    }
    const std::string status = shared_status(entry), reason = shared_reason(entry);
    if (status == "pending") {
        c.kind = ShareKind::Waiting;
        c.label = "waiting";
        c.tooltip = "In the outbox: it goes when the sharing mode allows it (Always: soon; Ask me each time: after you answer the review list).";
    } else if (status == "sent") {
        c.kind = ShareKind::Sent;
        c.label = "sent";
        c.tooltip = "The engine developers have this one.";
    } else if (status == "rejected") {
        c.kind = ShareKind::Rejected;
        c.label = "rejected";
        c.tooltip = reason.empty() ? "The sanitizer or the server refused this text." : reason;
    } else if (status == "skipped") {
        c.kind = ShareKind::Skipped;
        c.label = "skipped";
        c.tooltip = reason.empty() ? "Not sent: sharing is off or you chose Don't send." : reason;
    } else {
        c.label = "not shared";
        c.tooltip = "It has a share text and has not been queued yet. Choose how to share in File > Feedback Sharing.";
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

}  // namespace fa::editor
