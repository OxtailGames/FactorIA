#include "fa/tooling/feedback_fixed.h"

#include <algorithm>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/feedback.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

bool contains(const std::vector<std::string>& v, const std::string& s) { return std::find(v.begin(), v.end(), s) != v.end(); }

std::string family(const std::string& category) {
    const auto dash = category.find('-');
    return dash == std::string::npos ? category : category.substr(0, dash);
}

std::string feedback_file_for(const std::string& projectDir) {
    std::string file = kFeedbackFileName;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("feedbackFile") && pj.value()["feedbackFile"].is_string())
            file = pj.value()["feedbackFile"].get<std::string>();
    }
    return (stdfs::path(projectDir) / file).string();
}

}  // namespace

Result<void> validate_feedback_fixed(const Json& list) {
    const std::string where = kFeedbackFixedPath;
    if (!list.is_object()) return make_error(where + ": expected an object.", "Write {\"format\":\"factoria.feedback-fixed/1\",\"fixes\":[]}.");
    if (list.value("format", std::string()) != kFeedbackFixedFormat)
        return make_error(where + ": /format must be \"" + std::string(kFeedbackFixedFormat) + "\".");
    if (!list.contains("fixes") || !list["fixes"].is_array()) return make_error(where + ": /fixes must be an array.", "Use [] for none.");
    int i = 0;
    for (const Json& f : list["fixes"]) {
        const std::string at = where + ": /fixes/" + std::to_string(i++);
        if (!f.is_object()) return make_error(at + " must be an object.", "Write {\"category\":..., \"titles\":[...], \"fixedIn\":\"0.11.0\"}.");
        if (!contains(feedback_categories(), f.value("category", std::string())))
            return make_error(at + "/category is missing or not a feedback category.", did_you_mean(f.value("category", std::string()), feedback_categories()));
        if (!f.contains("titles") || !f["titles"].is_array() || f["titles"].empty())
            return make_error(at + "/titles must be a non-empty array of strings.", "List the titles under which the gap was reported.");
        for (const Json& t : f["titles"])
            if (!t.is_string() || trim(t.get<std::string>()).empty()) return make_error(at + "/titles must only hold non-empty strings.");
        if (f.value("fixedIn", std::string()).empty()) return make_error(at + "/fixedIn is missing.", "Name the engine version that fixed it, e.g. \"0.11.0\".");
    }
    return {};
}

Result<Json> embedded_feedback_fixed() {
    auto text = bundled_read(kFeedbackFixedPath);
    if (!text) return Json::parse(R"({"format":"factoria.feedback-fixed/1","fixes":[]})");
    auto parsed = parse_json(*text, kFeedbackFixedPath);
    if (!parsed.ok()) return parsed.error();
    if (auto v = validate_feedback_fixed(parsed.value()); !v.ok()) return v.error();
    return parsed.value();
}

Json FixedCheckResult::to_json() const {
    Json arr = Json::array();
    for (const FixedClosed& c : closed) arr.push_back(Json::object({{"id", c.id}, {"fixedIn", c.fixedIn}, {"title", c.title}}));
    return Json::object({{"checked", checked}, {"closed", closed.size()}, {"entries", arr}});
}

Result<FixedCheckResult> check_fixed_feedback(const std::string& feedbackPath, const Json& list) {
    if (auto v = validate_feedback_fixed(list); !v.ok()) return v.error();
    auto doc = load_feedback(feedbackPath);
    if (!doc.ok()) return doc.error();
    FixedCheckResult out;
    if (!doc->contains("entries") || !doc->at("entries").is_array()) return out;
    struct Match { std::string id, fixedIn, title, note; };
    std::vector<Match> matches;
    for (const Json& e : doc->at("entries")) {
        if (!e.is_object() || e.value("status", std::string("open")) != "open") continue;
        ++out.checked;
        const std::string category = e.value("category", std::string());
        std::vector<std::string> titles{e.value("title", std::string())};
        if (e.contains("share") && e["share"].is_object()) titles.push_back(e["share"].value("title", std::string()));
        for (const Json& fix : list["fixes"]) {
            const std::string fc = fix.value("category", std::string());
            if (category != fc && family(category) != family(fc)) continue;
            bool hit = false;
            for (const std::string& mine : titles) {
                if (mine.empty()) continue;
                for (const Json& t : fix["titles"])
                    hit = hit || feedback_entry_similarity(Json::object({{"title", mine}, {"category", category}}),
                                                           Json::object({{"title", t.get<std::string>()}, {"category", fc}})) >= 0.7;
            }
            if (!hit) continue;
            matches.push_back({e.value("id", std::string()), fix.value("fixedIn", std::string()), e.value("title", std::string()),
                               fix.value("note", std::string())});
            break;
        }
    }
    for (const Match& m : matches) {
        auto r = update_feedback_file(feedbackPath, m.id, "fixed-in-engine", "FactorIA " + m.fixedIn,
                                      "fixed in FactorIA " + m.fixedIn + ": check whether the workaround can go" +
                                          (m.note.empty() ? std::string() : " (" + m.note + ")"));
        if (!r.ok()) return r.error();
        out.closed.push_back({m.id, m.fixedIn, m.title});
    }
    return out;
}

Result<FixedCheckResult> check_fixed_feedback_file(const std::string& feedbackPath) {
    if (!stdfs::exists(feedbackPath)) return FixedCheckResult{};
    auto list = embedded_feedback_fixed();
    if (!list.ok()) return list.error();
    if (list->at("fixes").empty()) {
        FixedCheckResult none;
        return none;
    }
    return check_fixed_feedback(feedbackPath, list.value());
}

void register_feedback_fixed_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "feedback.check_fixed";
    info.category = "feedback";
    info.readOnly = false;
    info.summary = "Close the open feedback entries whose gap this engine version fixed.";
    info.description =
        "Every FactorIA release ships a list of the gaps it fixed (feedback/fixed.json, embedded). Each open entry of this project's "
        "ENGINE_FEEDBACK.json with the same category (or family) and a similar title (`title` or `share.title`, similarity 0.7) "
        "becomes fixed-in-engine with engineIssue \"FactorIA <version>\" and a note to check whether the workaround can go; "
        "feedback.archive then moves it to the archive. The editor runs this when it opens the project. Reporting the gap again "
        "reopens it as a possible regression. Safe to repeat. Example: {}";
    info.inputSchema = Json::object({{"type", "object"}, {"properties", Json::object()}});
    registry.add(info, [projectDir](const Json&) {
        const std::string file = feedback_file_for(projectDir);
        if (!stdfs::exists(file)) return Json::object({{"checked", 0}, {"closed", 0}, {"entries", Json::array()}, {"note", "No ENGINE_FEEDBACK.json yet."}});
        auto r = check_fixed_feedback_file(file);
        if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
        Json out = r->to_json();
        if (!r->closed.empty())
            out["note"] = "Closed entries move to ENGINE_FEEDBACK.archive.json with feedback.archive; check whether their workarounds can go.";
        return out;
    });
}

}  // namespace fa
