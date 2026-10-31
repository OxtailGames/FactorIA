#include "fa/tooling/feedback_fixed.h"

#include <algorithm>
#include <cctype>
#include <filesystem>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/feedback.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

namespace {

std::string lower(std::string_view s) {
    std::string out(s);
    std::transform(out.begin(), out.end(), out.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return out;
}

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

// "0.11.0", "1.2.3", "0.11.0-rc1": digits, three dots-separated numbers, an optional suffix.
bool looks_like_version(std::string_view v) {
    int parts = 0;
    std::size_t i = 0;
    while (i < v.size()) {
        std::size_t start = i;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) ++i;
        if (i == start) return false;
        ++parts;
        if (i < v.size() && v[i] == '.' && parts < 3) {
            ++i;
            continue;
        }
        break;
    }
    if (parts != 3) return false;
    return i == v.size() || (v[i] == '-' && i + 1 < v.size());
}

Json fix_to_json(const FeedbackFix& f) {
    Json j = Json::object({{"category", f.category}, {"titles", f.titles}, {"fixedIn", f.fixedIn}});
    if (!f.note.empty()) j["note"] = f.note;
    return j;
}

}  // namespace

Json create_empty_fixed_list() {
    return Json::object({{"format", kFeedbackFixedFormat}, {"fixes", Json::array()}});
}

Result<std::vector<FeedbackFix>> parse_fixed_list(const Json& doc, std::string_view sourceName) {
    const std::string src(sourceName);
    if (!doc.is_object() || doc.value("format", std::string()) != kFeedbackFixedFormat)
        return make_error(src + ": \"format\" must be \"" + kFeedbackFixedFormat + "\".",
                          "Start from {\"format\": \"" + std::string(kFeedbackFixedFormat) + "\", \"fixes\": []} or let `factoria feedback fixed add` create the file.");
    if (!doc.contains("fixes") || !doc["fixes"].is_array())
        return make_error(src + "/fixes: must be an array of fixes.", "Use \"fixes\": [] for none.");
    std::vector<FeedbackFix> out;
    std::size_t index = 0;
    for (const auto& f : doc["fixes"]) {
        const std::string at = src + "/fixes/" + std::to_string(index++);
        if (!f.is_object()) return make_error(at + ": a fix must be an object.", "{\"category\", \"titles\", \"fixedIn\", \"note\"?}");
        FeedbackFix fix;
        fix.category = f.value("category", std::string());
        fix.fixedIn = f.value("fixedIn", std::string());
        fix.note = f.value("note", std::string());
        if (f.contains("titles") && f["titles"].is_array())
            for (const auto& t : f["titles"])
                if (t.is_string()) fix.titles.push_back(t.get<std::string>());
        const auto& cats = feedback_categories();
        if (std::find(cats.begin(), cats.end(), fix.category) == cats.end())
            return make_error(at + "/category: '" + fix.category + "' is not a feedback category.", did_you_mean(fix.category, cats));
        if (fix.titles.empty()) return make_error(at + "/titles: at least one title is needed.", "The titles are what open entries are matched against.");
        if (!looks_like_version(fix.fixedIn))
            return make_error(at + "/fixedIn: '" + fix.fixedIn + "' is not an engine version.", "Use the version that shipped the fix, like \"0.11.0\".");
        out.push_back(std::move(fix));
    }
    return out;
}

Result<Json> load_fixed_list_file(const std::string& path) {
    auto text = tooling_detail::read_file(path);
    if (!text) return make_error("Cannot read " + path, "Create it with `factoria feedback fixed add --category C --title T --version V`.");
    return parse_json(*text, path);
}

Result<FixedAddResult> add_fixed_to_file(const std::string& path, const FeedbackFix& in) {
    FeedbackFix fix = in;
    for (auto& t : fix.titles) t = std::string(trim(t));
    fix.titles.erase(std::remove_if(fix.titles.begin(), fix.titles.end(), [](const std::string& t) { return t.empty(); }), fix.titles.end());
    fix.fixedIn = std::string(trim(fix.fixedIn));
    fix.note = std::string(trim(fix.note));
    const auto& cats = feedback_categories();
    if (std::find(cats.begin(), cats.end(), fix.category) == cats.end())
        return make_error("'" + fix.category + "' is not a feedback category.", did_you_mean(fix.category, cats));
    if (fix.titles.empty()) return make_error("A fix needs at least one title.", "Pass --title \"No one-way platforms\" (repeat it for other wordings of the same gap).");
    if (!looks_like_version(fix.fixedIn))
        return make_error("'" + fix.fixedIn + "' is not an engine version.", "Pass the version that ships the fix, like --version 0.11.0.");

    FixedAddResult result;
    Json doc;
    std::error_code ec;
    if (stdfs::exists(path, ec)) {
        auto loaded = load_fixed_list_file(path);
        if (!loaded.ok()) return loaded.error();
        doc = *loaded;
        auto check = parse_fixed_list(doc, path);
        if (!check.ok()) return check.error();
    } else {
        doc = create_empty_fixed_list();
        result.created = true;
    }
    Json& fixes = doc["fixes"];
    Json* target = nullptr;
    for (auto& existing : fixes) {
        if (existing.value("category", std::string()) != fix.category || existing.value("fixedIn", std::string()) != fix.fixedIn) continue;
        for (const auto& t : existing["titles"])
            for (const auto& mine : fix.titles)
                if (t.is_string() && lower(t.get<std::string>()) == lower(mine)) target = &existing;
        if (target) break;
    }
    if (target) {
        result.merged = true;
        for (const auto& mine : fix.titles) {
            bool known = false;
            for (const auto& t : (*target)["titles"]) known = known || (t.is_string() && lower(t.get<std::string>()) == lower(mine));
            if (!known) (*target)["titles"].push_back(mine);
        }
        if (!fix.note.empty()) (*target)["note"] = fix.note;
        auto stored = parse_fixed_list(Json::object({{"format", kFeedbackFixedFormat}, {"fixes", Json::array({*target})}}), path);
        if (stored.ok()) result.fix = stored->front();
    } else {
        fixes.push_back(fix_to_json(fix));
        result.fix = fix;
    }
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err)) return make_error(err);
    result.total = static_cast<int>(fixes.size());
    return result;
}

Result<std::string> find_fixed_list_path(const std::string& startDir) {
    std::error_code ec;
    stdfs::path dir = stdfs::weakly_canonical(startDir, ec);
    if (ec) dir = stdfs::absolute(startDir);
    for (; !dir.empty(); dir = dir.parent_path()) {
        if (stdfs::exists(dir / ".git", ec) && stdfs::is_directory(dir / "feedback", ec)) return (dir / "feedback" / "fixed.json").string();
        if (dir == dir.parent_path()) break;
    }
    return make_error("Not inside the FactorIA repository: no parent folder of " + startDir + " has a .git and a feedback/ folder.",
                      "Run it inside the engine checkout, or name the file with --file PATH (normally <repo>/feedback/fixed.json).");
}

Result<Json> embedded_feedback_fixed() {
    auto text = bundled_read(kFeedbackFixedPath);
    if (!text) return create_empty_fixed_list();
    auto parsed = parse_json(*text, kFeedbackFixedPath);
    if (!parsed.ok()) return parsed.error();
    if (auto v = parse_fixed_list(parsed.value(), kFeedbackFixedPath); !v.ok()) return v.error();
    return parsed.value();
}

Json FixedCheckResult::to_json() const {
    Json arr = Json::array();
    for (const FixedClosed& c : closed) arr.push_back(Json::object({{"id", c.id}, {"fixedIn", c.fixedIn}, {"title", c.title}}));
    return Json::object({{"checked", checked}, {"closed", closed.size()}, {"entries", arr}});
}

Result<FixedCheckResult> check_fixed_feedback(const std::string& feedbackPath, const Json& list) {
    if (auto v = parse_fixed_list(list); !v.ok()) return v.error();
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

