#include "fa/tooling/feedback_fixed.h"

#include <algorithm>
#include <cctype>
#include <filesystem>

#include "fa/core/strings.h"
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

}  // namespace fa
