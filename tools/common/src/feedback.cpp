#include "fa/tooling/feedback.h"

#include <algorithm>
#include <cctype>
#include <cstdio>
#include <filesystem>
#include <map>
#include <set>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;
using tooling_detail::arg_string;

// ----------------------------------------------------------------- enums ----
const std::vector<std::string>& feedback_categories() {
    static const std::vector<std::string> v = {"rendering-2d", "rendering-3d", "physics", "audio", "input", "ui",
                                               "scripting", "scene", "assets", "animation", "tooling",
                                               "ai-integration", "docs", "platform", "performance", "networking",
                                               "other"};
    return v;
}
const std::vector<std::string>& feedback_severities() {
    static const std::vector<std::string> v = {"blocker", "major", "minor", "nice-to-have"};
    return v;
}
const std::vector<std::string>& feedback_statuses() {
    static const std::vector<std::string> v = {"open", "fixed-in-engine", "wont-fix", "duplicate"};
    return v;
}
int feedback_severity_weight(std::string_view s) {
    if (s == "blocker") return 8;
    if (s == "major") return 4;
    if (s == "minor") return 2;
    return 1;
}

static bool contains(const std::vector<std::string>& v, std::string_view s) {
    return std::find(v.begin(), v.end(), s) != v.end();
}

// ------------------------------------------------------------ similarity ----
namespace {

// Significant tokens of a title or suggestion: lower-case alphanumerics, plural "s" dropped, stop words and
// boilerplate ("Bug:", "Generated", "Project", "docs"...) removed, a few synonyms canonicalised ("stub" ~ "placeholder").
std::vector<std::string> title_tokens(std::string_view title) {
    static const std::set<std::string> stop = {
        "a",       "an",     "the",    "no",     "not",    "for",   "of",     "to",      "in",     "on",
        "and",     "or",     "is",     "are",    "was",    "be",    "it",     "its",     "this",   "that",
        "by",      "at",     "from",   "as",     "but",    "when",  "does",   "do",      "did",    "has",
        "have",    "missing", "lacks", "lack",   "support", "supports", "built", "with",  "cannot", "cant",
        "there",   "add",    "need",   "needs",  "without", "bug",  "bugs",   "silently", "actually", "still",
        "any",     "generated", "generate", "project", "new",  "ship",  "shipped", "doc",  "docs",  "md",
        "guide",   "ai",     "template", "tool",   "tooling", "wrong", "just",  "only",    "also",   "into"};
    static const std::map<std::string, std::string> synonyms = {
        {"stub", "placeholder"}, {"stubbed", "placeholder"}, {"fake", "placeholder"},    {"undocumented", "documented"},
        {"ignored", "nothing"},  {"suppressed", "nothing"},  {"unusable", "invalid"},    {"crash", "crashe"}};
    std::vector<std::string> out;
    std::string cur;
    auto flush = [&] {
        if (cur.empty()) return;
        if (cur.size() > 3 && cur.back() == 's' && cur[cur.size() - 2] != 's') cur.pop_back();
        if (auto syn = synonyms.find(cur); syn != synonyms.end()) cur = syn->second;
        if (!stop.count(cur)) out.push_back(cur);
        cur.clear();
    };
    for (char c : title) {
        unsigned char u = static_cast<unsigned char>(c);
        if (std::isalnum(u)) cur += static_cast<char>(std::tolower(u));
        else flush();
    }
    flush();
    return out;
}

struct SetStats {
    double jaccard = 0, overlap = 0;
    size_t minSize = 0;
};

SetStats set_stats(const std::vector<std::string>& a, const std::vector<std::string>& b) {
    std::set<std::string> sa(a.begin(), a.end()), sb(b.begin(), b.end());
    SetStats st;
    if (sa.empty() || sb.empty()) return st;
    size_t inter = 0;
    for (const auto& t : sa) inter += sb.count(t);
    st.jaccard = double(inter) / double(sa.size() + sb.size() - inter);
    st.minSize = std::min(sa.size(), sb.size());
    st.overlap = double(inter) / double(st.minSize);
    return st;
}

std::string category_family(const std::string& c) {
    auto dash = c.find('-');
    return dash == std::string::npos ? c : c.substr(0, dash);
}

}  // namespace

double feedback_title_similarity(std::string_view a, std::string_view b) {
    auto ta = title_tokens(a), tb = title_tokens(b);
    if (ta.empty() || tb.empty()) return to_lower(a) == to_lower(b) ? 1.0 : 0.0;
    SetStats st = set_stats(ta, tb);
    std::sort(ta.begin(), ta.end());
    std::sort(tb.begin(), tb.end());
    std::string ja, jb;
    for (const auto& t : ta) ja += t + " ";
    for (const auto& t : tb) jb += t + " ";
    size_t maxLen = std::max(ja.size(), jb.size());
    double edit = 1.0 - double(edit_distance(ja, jb)) / double(maxLen);
    // A short title fully contained in a longer one (>= 3 shared significant tokens) is the same gap, slightly damped.
    double contained = st.minSize >= 3 ? 0.85 * st.overlap : 0.0;
    return std::max({st.jaccard, edit, contained});
}

double feedback_entry_similarity(const Json& a, const Json& b) {
    double score = feedback_title_similarity(a.value("title", ""), b.value("title", ""));
    std::string ca = a.value("category", ""), cb = b.value("category", "");
    if (!ca.empty() && ca == cb) score += 0.10;
    else if (!ca.empty() && category_family(ca) == category_family(cb)) score += 0.05;
    auto sa = title_tokens(a.value("suggestion", "")), sb = title_tokens(b.value("suggestion", ""));
    if (sa.size() >= 3 && sb.size() >= 3) score += 0.10 * set_stats(sa, sb).jaccard;
    return std::min(1.0, score);
}

// ------------------------------------------------------------- documents ----
Json create_empty_feedback(std::string_view projectName, std::string_view engineVersion) {
    Json doc = Json::object();
    doc["format"] = kFeedbackFormat;
    doc["project"] = std::string(projectName);
    doc["engineVersion"] = engineVersion.empty() ? std::string(FA_ENGINE_VERSION) : std::string(engineVersion);
    doc["entries"] = Json::array();
    return doc;
}

Result<Json> load_feedback(const std::string& path) {
    auto text = tooling_detail::read_file(path);
    if (!text)
        return make_error("Cannot read " + path, "Create it with `factoria feedback init` or the feedback.report command.");
    return parse_json(*text, path);
}

Result<void> save_feedback(const std::string& path, const Json& doc) {
    std::string err;
    if (!tooling_detail::write_file(path, dump_json(doc), &err)) return make_error(err);
    return {};
}

std::vector<SchemaError> validate_feedback(const Json& doc) {
    std::vector<SchemaError> errors;
    Json schema = tooling_detail::load_schema("schemas/engine-feedback.schema.json");
    if (schema.is_null()) {
        errors.push_back({"", "engine-feedback schema is not bundled with this build", "Rebuild so schemas/ is embedded."});
        return errors;
    }
    errors = validate_json(schema, doc);
    if (doc.is_object() && doc.contains("entries") && doc["entries"].is_array()) {
        std::set<std::string> seen;
        int i = 0;
        for (const auto& e : doc["entries"]) {
            if (e.is_object() && e.contains("id") && e["id"].is_string()) {
                std::string id = e["id"].get<std::string>();
                if (!seen.insert(id).second)
                    errors.push_back({"/entries/" + std::to_string(i) + "/id", "duplicate id '" + id + "'",
                                      "Ids must be unique; renumber one of the entries."});
            }
            ++i;
        }
    }
    return errors;
}

// ------------------------------------------------------------------- add ----
namespace {

int max_entry_number(const Json& entries) {
    int best = 0;
    for (const auto& e : entries) {
        if (!e.is_object() || !e.contains("id") || !e["id"].is_string()) continue;
        const std::string id = e["id"].get<std::string>();
        if (id.rfind("FB-", 0) == 0) {
            try { best = std::max(best, std::stoi(id.substr(3))); } catch (...) {}
        }
    }
    return best;
}

std::string status_of(const Json& e) { return e.value("status", std::string("open")); }

std::string check_enum(const char* field, const std::string& value, const std::vector<std::string>& valid) {
    if (contains(valid, value)) return {};
    return std::string("Invalid ") + field + " '" + value + "'. " + did_you_mean(value, valid);
}

}  // namespace

Result<FeedbackAddResult> add_feedback_entry(Json& doc, const FeedbackInput& in) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array())
        return make_error("ENGINE_FEEDBACK.json has no \"entries\" array.",
                          "Start from create_empty_feedback() or run `factoria feedback init`.");
    if (std::string m = check_enum("category", in.category, feedback_categories()); !m.empty())
        return make_error(m, "Pick the closest engine area; use \"other\" if none fits.");
    if (std::string m = check_enum("severity", in.severity, feedback_severities()); !m.empty())
        return make_error(m, "blocker = could not build it; major = big workaround; minor = small; nice-to-have = convenience.");
    if (!in.effort.empty() && !contains({"small", "medium", "large"}, in.effort))
        return make_error("Invalid effort '" + in.effort + "'.", "Use small, medium or large (or omit it).");
    auto need = [](const std::string& v, const char* name) -> std::string {
        if (trim(v).size() < 3) return std::string("Field '") + name + "' is required (at least a few words).";
        return {};
    };
    for (auto [v, n] : {std::pair<const std::string&, const char*>{in.title, "title"}, {in.missing, "missing"},
                        {in.workaround, "workaround"}})
        if (std::string m = need(v, n); !m.empty())
            return make_error(m, "Say what the engine lacked (missing), the short name (title) and what you did instead (workaround).");

    Json& entries = doc["entries"];
    const std::string today = tooling_detail::today_utc();

    // Dedupe against open entries of the same category.
    Json* best = nullptr;
    double bestScore = 0.0;
    for (auto& e : entries) {
        if (!e.is_object() || status_of(e) != "open" || e.value("category", "") != in.category) continue;
        double s = feedback_title_similarity(e.value("title", ""), in.title);
        if (s >= 0.7 && s > bestScore) { best = &e; bestScore = s; }
    }
    FeedbackAddResult result;
    if (best) {
        Json& e = *best;
        int occ = e.value("occurrences", 1) + 1;
        e["occurrences"] = occ;
        if (!e.contains("notes") || !e["notes"].is_array()) e["notes"] = Json::array();
        e["notes"].push_back(today + ": " + in.workaround);
        if (feedback_severity_weight(in.severity) > feedback_severity_weight(e.value("severity", "minor")))
            e["severity"] = in.severity;
        if (!in.suggestion.empty() && (!e.contains("suggestion") || e["suggestion"].get<std::string>().size() < in.suggestion.size()))
            e["suggestion"] = in.suggestion;
        if (!in.workaroundFiles.empty()) {
            if (!e.contains("workaroundFiles") || !e["workaroundFiles"].is_array()) e["workaroundFiles"] = Json::array();
            for (const auto& f : in.workaroundFiles) {
                bool have = false;
                for (const auto& x : e["workaroundFiles"]) have = have || (x == f);
                if (!have) e["workaroundFiles"].push_back(f);
            }
        }
        result.id = e["id"].get<std::string>();
        result.merged = true;
        result.occurrences = occ;
        result.entry = e;
        return result;
    }

    char idbuf[16];
    std::snprintf(idbuf, sizeof idbuf, "FB-%04d", max_entry_number(entries) + 1);
    Json e = Json::object();
    e["id"] = idbuf;
    e["date"] = today;
    if (in.reporter.is_object() && !in.reporter.empty()) e["reporter"] = in.reporter;
    e["category"] = in.category;
    e["severity"] = in.severity;
    e["title"] = std::string(trim(in.title));
    e["missing"] = in.missing;
    e["workaround"] = in.workaround;
    if (!in.workaroundFiles.empty()) e["workaroundFiles"] = in.workaroundFiles;
    if (!in.suggestion.empty()) e["suggestion"] = in.suggestion;
    if (!in.effort.empty()) e["effort"] = in.effort;
    e["occurrences"] = 1;
    e["status"] = "open";
    entries.push_back(e);
    result.id = idbuf;
    result.entry = e;
    return result;
}

Result<FeedbackAddResult> add_feedback_entry_to_file(const std::string& path, const FeedbackInput& input,
                                                     std::string_view projectNameIfNew) {
    Json doc;
    if (stdfs::exists(path)) {
        auto loaded = load_feedback(path);
        if (!loaded.ok()) return loaded.error();
        doc = std::move(loaded.value());
    } else {
        std::string name(projectNameIfNew);
        if (name.empty()) name = stdfs::path(path).parent_path().filename().string();
        doc = create_empty_feedback(name);
    }
    auto r = add_feedback_entry(doc, input);
    if (!r.ok()) return r;
    if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    return r;
}

Json list_feedback(const Json& doc, const FeedbackFilter& f) {
    Json out = Json::array();
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return out;
    for (const auto& e : doc["entries"]) {
        if (!f.status.empty() && status_of(e) != f.status) continue;
        if (!f.category.empty() && e.value("category", "") != f.category) continue;
        if (!f.severity.empty() && e.value("severity", "") != f.severity) continue;
        out.push_back(e);
    }
    return out;
}

Result<Json> update_feedback_entry(Json& doc, std::string_view id, std::string_view status, std::string_view engineIssue) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array())
        return make_error("ENGINE_FEEDBACK.json has no \"entries\" array.");
    if (!status.empty() && !contains(feedback_statuses(), status))
        return make_error("Invalid status '" + std::string(status) + "'. " + did_you_mean(status, feedback_statuses()));
    std::vector<std::string> ids;
    for (auto& e : doc["entries"]) {
        std::string eid = e.value("id", "");
        ids.push_back(eid);
        if (eid != id) continue;
        if (!status.empty()) e["status"] = std::string(status);
        if (!engineIssue.empty()) e["engineIssue"] = std::string(engineIssue);
        return e;
    }
    return make_error("No feedback entry with id '" + std::string(id) + "'.", did_you_mean(id, ids));
}

// --------------------------------------------------------------- collect ----
namespace {

struct Item {
    std::string project;
    Json entry;
};
struct Cluster {
    std::string category;
    std::vector<Item> items;
};

void find_feedback_files(const stdfs::path& dir, int depth, std::vector<std::string>& out) {
    std::error_code ec;
    stdfs::path direct = dir / kFeedbackFileName;
    if (stdfs::is_regular_file(direct, ec)) {
        out.push_back(direct.string());
        return;
    }
    if (depth <= 0) return;
    std::vector<stdfs::path> subdirs;
    for (stdfs::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
        std::string n = it->path().filename().string();
        if (!it->is_directory(ec) || n.empty() || n[0] == '.' || n == "build" || n == "node_modules") continue;
        subdirs.push_back(it->path());
    }
    std::sort(subdirs.begin(), subdirs.end());
    for (const auto& d : subdirs) find_feedback_files(d, depth - 1, out);
}

const char* kSeverityOrder[] = {"nice-to-have", "minor", "major", "blocker"};

}  // namespace

Result<FeedbackReport> collect_feedback(const std::vector<std::string>& paths, const CollectOptions& opts) {
    std::vector<std::string> files;
    Json errors = Json::array();
    for (const auto& p : paths) {
        std::error_code ec;
        if (stdfs::is_directory(p, ec)) {
            size_t before = files.size();
            find_feedback_files(p, 4, files);
            if (files.size() == before)
                errors.push_back("No ENGINE_FEEDBACK.json found in " + p + " (searched 4 levels deep).");
        } else if (stdfs::is_regular_file(p, ec)) {
            files.push_back(p);
        } else {
            errors.push_back("Path does not exist: " + p);
        }
    }
    if (files.empty() && paths.empty())
        return make_error("No paths given.", "Pass project directories or ENGINE_FEEDBACK.json files.");

    std::vector<Cluster> clusters;
    Json sources = Json::array(), projects = Json::array();
    std::set<std::string> projectSet;
    int total = 0;
    for (const auto& f : files) {
        auto doc = load_feedback(f);
        if (!doc.ok()) {
            errors.push_back(f + ": " + doc.error().to_string());
            continue;
        }
        const Json& d = doc.value();
        if (!d.is_object() || !d.contains("entries") || !d["entries"].is_array()) {
            errors.push_back(f + ": no \"entries\" array");
            continue;
        }
        std::string project = d.value("project", stdfs::path(f).parent_path().filename().string());
        sources.push_back(f);
        if (projectSet.insert(project).second) projects.push_back(project);
        for (const auto& e : d["entries"]) {
            if (!e.is_object()) continue;
            std::string status = status_of(e);
            if (!opts.includeClosed && status != "open") continue;
            ++total;
            std::string cat = e.value("category", "other"), title = e.value("title", "");
            (void)title;
            Cluster* target = nullptr;
            double best = 0;
            for (auto& c : clusters) {
                for (const auto& it : c.items) {
                    double s = feedback_entry_similarity(it.entry, e);
                    if (s >= opts.similarity && s > best) { best = s; target = &c; }
                }
            }
            if (!target) {
                clusters.push_back({cat, {}});
                target = &clusters.back();
            }
            target->items.push_back({project, e});
        }
    }

    struct Ranked {
        Json j;
        long score;
        std::string title;
    };
    std::vector<Ranked> ranked;
    // A cluster may span categories (docs vs tooling reports of one gap): the most common one wins (ties: alphabetical).
    for (auto& c : clusters) {
        std::map<std::string, int> counts;
        for (const auto& it : c.items) ++counts[it.entry.value("category", "other")];
        int bestCount = 0;
        for (const auto& [name, n] : counts)
            if (n > bestCount) { bestCount = n; c.category = name; }
    }
    for (const auto& c : clusters) {
        long occ = 0;
        int maxW = 0;
        std::string sev = "nice-to-have";
        std::set<std::string> projs;
        Json entryRefs = Json::array(), samples = Json::array();
        std::string bestSuggestion;
        const Item* rep = &c.items.front();
        long repOcc = -1;
        std::set<std::string> sampleSeen;
        for (const auto& it : c.items) {
            long o = it.entry.value("occurrences", 1);
            occ += o;
            std::string s = it.entry.value("severity", "minor");
            if (feedback_severity_weight(s) > maxW) { maxW = feedback_severity_weight(s); sev = s; }
            projs.insert(it.project);
            entryRefs.push_back(Json::object({{"project", it.project}, {"id", it.entry.value("id", "")},
                                              {"severity", s}, {"status", status_of(it.entry)}, {"occurrences", o}}));
            if (o > repOcc) { repOcc = o; rep = &it; }
            std::string sug = it.entry.value("suggestion", "");
            if (sug.size() > bestSuggestion.size()) bestSuggestion = sug;
            std::string w = it.entry.value("workaround", "");
            if (!w.empty() && sampleSeen.insert(w).second && samples.size() < 3) samples.push_back(w);
        }
        Json j = Json::object();
        j["title"] = rep->entry.value("title", "");
        j["category"] = c.category;
        j["severity"] = sev;
        j["score"] = occ * maxW;
        j["totalOccurrences"] = occ;
        j["projects"] = Json(std::vector<std::string>(projs.begin(), projs.end()));
        j["entries"] = entryRefs;
        j["bestSuggestion"] = bestSuggestion;
        j["sampleWorkarounds"] = samples;
        ranked.push_back({std::move(j), occ * maxW, rep->entry.value("title", "")});
    }
    std::stable_sort(ranked.begin(), ranked.end(), [](const Ranked& a, const Ranked& b) {
        if (a.score != b.score) return a.score > b.score;
        return a.title < b.title;
    });
    Json outClusters = Json::array();
    int rank = 1;
    for (auto& r : ranked) {
        Json j = Json::object();
        j["rank"] = rank++;
        for (auto it = r.j.begin(); it != r.j.end(); ++it) j[it.key()] = it.value();
        outClusters.push_back(std::move(j));
    }
    FeedbackReport rep;
    rep.json = Json::object({{"sources", sources}, {"projects", projects}, {"totalEntries", total},
                             {"errors", errors}, {"clusters", outClusters}});
    (void)kSeverityOrder;
    return rep;
}

std::string FeedbackReport::markdown() const {
    std::ostringstream o;
    o << "# Engine feedback report\n\n";
    o << json.value("totalEntries", 0) << " entries from " << json["projects"].size() << " project(s), "
      << json["clusters"].size() << " distinct gap(s). Ranked by total occurrences x severity weight "
      << "(blocker 8, major 4, minor 2, nice-to-have 1).\n\n";
    if (!json["errors"].empty()) {
        o << "## Problems reading files\n\n";
        for (const auto& e : json["errors"]) o << "- " << e.get<std::string>() << "\n";
        o << "\n";
    }
    if (json["clusters"].empty()) o << "_No open feedback entries._\n";
    for (const auto& c : json["clusters"]) {
        o << "## " << c["rank"].get<int>() << ". " << c["title"].get<std::string>() << "\n\n";
        o << "- **Category:** " << c["category"].get<std::string>() << "\n";
        o << "- **Severity:** " << c["severity"].get<std::string>() << " (score " << c["score"].get<long>() << ")\n";
        o << "- **Total occurrences:** " << c["totalOccurrences"].get<long>() << "\n";
        o << "- **Projects affected:** ";
        bool first = true;
        for (const auto& p : c["projects"]) { o << (first ? "" : ", ") << p.get<std::string>(); first = false; }
        o << "\n- **Entries:** ";
        first = true;
        for (const auto& e : c["entries"]) {
            o << (first ? "" : ", ") << e["project"].get<std::string>() << "/" << e["id"].get<std::string>();
            first = false;
        }
        o << "\n";
        if (!c["bestSuggestion"].get<std::string>().empty())
            o << "- **Suggestion:** " << c["bestSuggestion"].get<std::string>() << "\n";
        if (!c["sampleWorkarounds"].empty()) {
            o << "- **Workarounds seen:**\n";
            for (const auto& w : c["sampleWorkarounds"]) o << "  - " << w.get<std::string>() << "\n";
        }
        o << "\n";
    }
    return o.str();
}

// -------------------------------------------------------------- commands ----
namespace {

std::string feedback_path_for(const std::string& projectDir) {
    std::string file = kFeedbackFileName;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("feedbackFile") && pj.value()["feedbackFile"].is_string())
            file = pj.value()["feedbackFile"].get<std::string>();
    }
    return (stdfs::path(projectDir) / file).string();
}

std::string project_name_for(const std::string& projectDir) {
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("name") && pj.value()["name"].is_string())
            return pj.value()["name"].get<std::string>();
    }
    std::error_code ec;
    return stdfs::weakly_canonical(projectDir, ec).filename().string();
}

Json enum_schema(const std::vector<std::string>& v, const char* desc) {
    return Json::object({{"type", "string"}, {"enum", v}, {"description", desc}});
}

}  // namespace

void register_feedback_commands(CommandRegistry& registry, const std::string& projectDir) {
    {
        CommandInfo info;
        info.name = "feedback.report";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.";
        info.description =
            "CALL THIS WHENEVER the engine lacked a feature or had a bug/limitation and you built a workaround or "
            "gave up on something, right when it happens (not at the end). Examples: a component field you expected "
            "does not exist; an error message did not say how to fix the problem; a documented API behaves "
            "differently; you had to emulate a feature in JavaScript; a command you wanted is missing.\n"
            "The entry is appended to the project's ENGINE_FEEDBACK.json, which engine developers aggregate to decide "
            "what to build next. Reporting a gap similar to an open one merges into it (occurrences + 1), so duplicates "
            "are harmless. Write 'title' as a short noun phrase (\"No one-way platforms\"), 'missing' as what you needed "
            "and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the "
            "concrete engine change that would remove the workaround.\n"
            "Example: {\"category\":\"physics\",\"severity\":\"major\",\"title\":\"No one-way platforms\","
            "\"missing\":\"Collider2D has no one-way option so the player cannot jump up through platforms.\","
            "\"workaround\":\"scripts/one_way.js disables the platform collider while the player moves upward.\","
            "\"workaroundFiles\":[\"scripts/one_way.js\"],\"suggestion\":\"Add Collider2D.oneWay (bool).\"}";
        Json props = Json::object();
        props["category"] = enum_schema(feedback_categories(), "Engine area of the gap.");
        props["severity"] = enum_schema(feedback_severities(),
            "blocker: could not build the feature at all; major: large/fragile workaround; minor: small workaround; nice-to-have: convenience.");
        props["title"] = Json::object({{"type", "string"}, {"description", "Short noun phrase naming the gap; reuse wording for the same gap."}});
        props["missing"] = Json::object({{"type", "string"}, {"description", "What the engine lacked or got wrong, and what you were trying to do."}});
        props["workaround"] = Json::object({{"type", "string"}, {"description", "What you did instead (or 'none: feature dropped')."}});
        props["workaroundFiles"] = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})},
                                                 {"description", "Project-relative files implementing the workaround."}});
        props["suggestion"] = Json::object({{"type", "string"}, {"description", "How the engine could fix it (field, command, API)."}});
        props["effort"] = enum_schema({"small", "medium", "large"}, "Your estimate of the engine-side effort to fix it.");
        props["reporter"] = Json::object({{"type", "object"},
            {"description", "Who is reporting. Defaults to {\"kind\":\"ai\"}; include your agent and model if you know them."},
            {"properties", Json::object({{"kind", enum_schema({"ai", "human"}, "ai or human.")},
                                         {"agent", Json::object({{"type", "string"}, {"description", "e.g. claude-code, codex."}})},
                                         {"model", Json::object({{"type", "string"}, {"description", "Model id."}})}})}});
        info.inputSchema = Json::object({{"type", "object"}, {"properties", props},
            {"required", Json::array({"category", "severity", "title", "missing", "workaround"})}});
        registry.add(info, [projectDir](const Json& args) {
            FeedbackInput in;
            in.category = arg_string(args, "category", true);
            in.severity = arg_string(args, "severity", true);
            in.title = arg_string(args, "title", true);
            in.missing = arg_string(args, "missing", true);
            in.workaround = arg_string(args, "workaround", true);
            in.suggestion = arg_string(args, "suggestion", false);
            in.effort = arg_string(args, "effort", false);
            if (args.contains("workaroundFiles") && args["workaroundFiles"].is_array())
                for (const auto& f : args["workaroundFiles"])
                    if (f.is_string()) in.workaroundFiles.push_back(f.get<std::string>());
            in.reporter = args.contains("reporter") && args["reporter"].is_object() ? args["reporter"] : Json::object({{"kind", "ai"}});
            std::string path = feedback_path_for(projectDir);
            auto r = add_feedback_entry_to_file(path, in, project_name_for(projectDir));
            if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
            Json out = Json::object();
            out["id"] = r->id;
            out["merged"] = r->merged;
            out["occurrences"] = r->occurrences;
            out["file"] = stdfs::path(path).filename().string();
            out["message"] = r->merged ? "Merged into existing entry " + r->id + " (now " + std::to_string(r->occurrences) +
                                             " occurrences). Thank you."
                                       : "Recorded as " + r->id + ". Thank you.";
            return out;
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.list";
        info.category = "feedback";
        info.readOnly = true;
        info.summary = "List the engine-feedback entries recorded for this project.";
        info.description = "Check this before reporting to see what is already recorded. Filters are optional. "
                           "Example: {\"status\":\"open\",\"category\":\"physics\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"status", enum_schema(feedback_statuses(), "Only entries with this status.")},
                                         {"category", enum_schema(feedback_categories(), "Only this category.")},
                                         {"severity", enum_schema(feedback_severities(), "Only this severity.")}})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            if (!stdfs::exists(path))
                return Json::object({{"entries", Json::array()}, {"count", 0}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            auto doc = load_feedback(path);
            if (!doc.ok()) throw CommandError("failed", doc.error().message, doc.error().hint);
            FeedbackFilter f{arg_string(args, "status", false), arg_string(args, "category", false), arg_string(args, "severity", false)};
            Json entries = list_feedback(doc.value(), f);
            return Json::object({{"count", entries.size()}, {"entries", entries}});
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.update";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Change the status of a feedback entry or link it to an engine issue.";
        info.description = "Engine developers use this when a gap is fixed (status fixed-in-engine), rejected (wont-fix) or "
                           "duplicated. Example: {\"id\":\"FB-0001\",\"status\":\"fixed-in-engine\",\"engineIssue\":\"#42\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"id", Json::object({{"type", "string"}, {"description", "Entry id, e.g. FB-0001."}})},
                                         {"status", enum_schema(feedback_statuses(), "New status.")},
                                         {"engineIssue", Json::object({{"type", "string"}, {"description", "Issue/PR link or id."}})}})},
            {"required", Json::array({"id"})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            auto doc = load_feedback(path);
            if (!doc.ok()) throw CommandError("not_found", doc.error().message, doc.error().hint);
            std::string status = arg_string(args, "status", false), issue = arg_string(args, "engineIssue", false);
            if (status.empty() && issue.empty())
                throw CommandError("invalid_argument", "Nothing to update.", "Pass status and/or engineIssue.");
            auto r = update_feedback_entry(doc.value(), arg_string(args, "id", true), status, issue);
            if (!r.ok()) throw CommandError("not_found", r.error().message, r.error().hint);
            if (auto s = save_feedback(path, doc.value()); !s.ok()) throw CommandError("failed", s.error().message);
            return r.value();
        });
    }
}

}  // namespace fa
