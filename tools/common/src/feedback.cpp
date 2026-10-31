#include "fa/tooling/feedback.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <map>
#include <set>
#include <sstream>

#include "fa/core/strings.h"
#include "fa/runtime/project.h"
#include "fa/tooling/feedback_share.h"
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
    size_t minSize = 0, shared = 0;
};

SetStats set_stats(const std::vector<std::string>& a, const std::vector<std::string>& b) {
    std::set<std::string> sa(a.begin(), a.end()), sb(b.begin(), b.end());
    SetStats st;
    if (sa.empty() || sb.empty()) return st;
    size_t inter = 0;
    for (const auto& t : sa) inter += sb.count(t);
    st.shared = inter;
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
    // A short title fully contained in a longer one (>= 4 shared significant tokens: three shared words such as "icon text button" are common to different gaps) is the same gap, slightly damped.
    double contained = st.shared >= 4 ? 0.85 * st.overlap : 0.0;
    return std::max({st.jaccard, edit, contained});
}

double feedback_entry_similarity(const Json& a, const Json& b) {
    double score = feedback_title_similarity(a.value("title", ""), b.value("title", ""));
    std::string ca = a.value("category", ""), cb = b.value("category", "");
    if (!ca.empty() && ca == cb) score += 0.10;
    else if (!ca.empty() && category_family(ca) == category_family(cb)) score += 0.05;
    auto sa = title_tokens(a.value("suggestion", "")), sb = title_tokens(b.value("suggestion", ""));
    if (sa.size() >= 3 && sb.size() >= 3) score += 0.10 * set_stats(sa, sb).jaccard;
    // What the report says is missing weighs in a little: two titles that share a few words but describe different
    // things differ here.
    auto ma = title_tokens(a.value("missing", "")), mb = title_tokens(b.value("missing", ""));
    if (ma.size() >= 3 && mb.size() >= 3) score += 0.10 * set_stats(ma, mb).jaccard;
    return std::min(1.0, score);
}

namespace {

// Whether `listed` (an entry's distinctFrom) names the other entry: by id for an entry of the same project, or as
// "<project>/<id>" for one of another project.
bool lists_distinct(const Json& listed, const std::string& otherProject, const std::string& otherId,
                    const std::string& ownProject) {
    if (!listed.is_object() || !listed.contains("distinctFrom") || !listed["distinctFrom"].is_array()) return false;
    for (const auto& d : listed["distinctFrom"]) {
        if (!d.is_string()) continue;
        const std::string v = d.get<std::string>();
        if (v == otherProject + "/" + otherId) return true;
        if (v == otherId && otherProject == ownProject) return true;
    }
    return false;
}

}  // namespace

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

// The `share` of a report: the object to store ({title, missing, suggestion?, workaround?}, trimmed) or the reason it cannot be.
std::string normalize_share(const Json& in, Json& out) {
    if (!in.is_object()) return "share must be an object {title, missing, suggestion?, workaround?}";
    out = Json::object();
    struct Spec { const char* key; bool required; int min, max; };
    const Spec specs[] = {{"title", true, kShareTitleMin, kShareTitleMax},
                          {"missing", true, kShareMissingMin, kShareMissingMax},
                          {"suggestion", false, 0, kShareSuggestionMax},
                          {"workaround", false, 0, kShareWorkaroundMax}};
    for (const Spec& sp : specs) {
        auto it = in.find(sp.key);
        if (it == in.end() || it->is_null()) {
            if (sp.required) return std::string("share.") + sp.key + " is missing";
            continue;
        }
        if (!it->is_string()) return std::string("share.") + sp.key + " must be a string";
        const std::string text(trim(it->get<std::string>()));
        std::size_t chars = 0;
        for (unsigned char c : text)
            if ((c & 0xC0) != 0x80) ++chars;
        if (chars > std::size_t(sp.max)) return std::string("share.") + sp.key + " is too long (at most " + std::to_string(sp.max) + " characters)";
        if (chars < std::size_t(sp.min)) return std::string("share.") + sp.key + " is too short (at least " + std::to_string(sp.min) + " characters)";
        if (!text.empty()) out[sp.key] = text;
    }
    return {};
}

}  // namespace

Result<FeedbackAddResult> add_feedback_entry(Json& doc, const FeedbackInput& in, Json* archive) {
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

    // The generic copy for sharing: a bad one is left out (the entry is still recorded) and the result says why.
    Json share;
    std::string shareProblem;
    if (!in.share.is_null()) {
        shareProblem = normalize_share(in.share, share);
        if (!shareProblem.empty()) share = Json();
    }

    // Dedupe against open entries of the same category.
    Json* best = nullptr;
    double bestScore = 0.0;
    for (auto& e : entries) {
        if (!e.is_object() || status_of(e) != "open" || e.value("category", "") != in.category) continue;
        double s = feedback_title_similarity(e.value("title", ""), in.title);
        if (s >= 0.7 && s > bestScore) { best = &e; bestScore = s; }
    }
    FeedbackAddResult result;
    // No open match: a gap that was reported, fixed in the engine and archived, and is reported again, is a possible
    // regression. The archived entry moves back (same id, open) instead of a second entry for the same gap.
    Json reopenedEntry;
    if (!best && archive && archive->is_object() && archive->contains("entries") && (*archive)["entries"].is_array()) {
        Json& archived = (*archive)["entries"];
        std::size_t bestAt = archived.size();
        for (std::size_t i = 0; i < archived.size(); ++i) {
            const Json& e = archived[i];
            if (!e.is_object() || status_of(e) != "fixed-in-engine" || e.value("category", "") != in.category) continue;
            double s = feedback_title_similarity(e.value("title", ""), in.title);
            if (s >= 0.7 && s > bestScore) { bestAt = i; bestScore = s; }
        }
        if (bestAt < archived.size()) {
            reopenedEntry = archived[bestAt];
            archived.erase(archived.begin() + std::ptrdiff_t(bestAt));
            reopenedEntry["status"] = "open";
            if (!reopenedEntry.contains("notes") || !reopenedEntry["notes"].is_array()) reopenedEntry["notes"] = Json::array();
            reopenedEntry["notes"].push_back(today + ": reported again with engine " + std::string(FA_ENGINE_VERSION) +
                                             ": regression?");
            entries.push_back(reopenedEntry);
            best = &entries[entries.size() - 1];
            result.reopened = true;
        }
    }
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
        if (share.is_object()) {
            // The longer share wins (it says more); equally long: the newest.
            auto size_of = [](const Json& j) { return j.value("title", std::string()).size() + j.value("missing", std::string()).size() +
                                                      j.value("suggestion", std::string()).size() + j.value("workaround", std::string()).size(); };
            if (!e.contains("share") || !e["share"].is_object() || size_of(share) >= size_of(e["share"])) {
                const bool changed = !e.contains("share") || e["share"] != share;
                e["share"] = share;
                // A different text has not been sent: it goes through the sanitizer and the outbox again.
                if (changed && e.contains("shared") && e["shared"].is_object() && e["shared"].value("status", std::string()) != "sent")
                    e.erase("shared");
            }
        }
        if (in.reviewed && *in.reviewed) e["reviewed"] = true;
        else if (in.reviewed && !e.contains("reviewed")) e["reviewed"] = false;
        result.id = e["id"].get<std::string>();
        result.merged = true;
        result.occurrences = occ;
        result.entry = e;
        result.shareProblem = shareProblem;
        return result;
    }

    char idbuf[16];
    int top = max_entry_number(entries);
    if (archive && archive->is_object() && archive->contains("entries") && (*archive)["entries"].is_array())
        top = std::max(top, max_entry_number((*archive)["entries"]));
    std::snprintf(idbuf, sizeof idbuf, "FB-%04d", top + 1);
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
    if (share.is_object()) e["share"] = share;
    if (in.reviewed) e["reviewed"] = *in.reviewed;
    e["occurrences"] = 1;
    e["status"] = "open";
    entries.push_back(e);
    result.id = idbuf;
    result.entry = e;
    result.shareProblem = shareProblem;
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
    const std::string archivePath = feedback_archive_path(path);
    Json archive;
    bool haveArchive = false;
    if (stdfs::exists(archivePath)) {
        auto loaded = load_feedback(archivePath);
        if (!loaded.ok()) return loaded.error();
        archive = std::move(loaded.value());
        haveArchive = true;
    }
    auto r = add_feedback_entry(doc, input, haveArchive ? &archive : nullptr);
    if (!r.ok()) return r;
    // The entry is in the file before it leaves the archive: a crash in between leaves it twice, never lost.
    if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    if (r->reopened)
        if (auto s = save_feedback(archivePath, archive); !s.ok()) return s.error();
    return r;
}

std::string feedback_archive_path(const std::string& feedbackPath) {
    const stdfs::path p(feedbackPath);
    if (p.extension() == ".json") return (p.parent_path() / (p.stem().string() + ".archive.json")).string();
    return feedbackPath + ".archive.json";
}

FeedbackArchiveResult archive_closed_feedback(Json& doc, Json& archive) {
    FeedbackArchiveResult out;
    if (!archive.is_object() || !archive.contains("entries") || !archive["entries"].is_array())
        archive["entries"] = Json::array();
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) return out;
    std::set<std::string> known;
    for (const auto& e : archive["entries"]) known.insert(e.value("id", ""));
    Json keep = Json::array();
    for (auto& e : doc["entries"]) {
        if (!e.is_object() || status_of(e) == "open") {
            keep.push_back(e);
            continue;
        }
        const std::string id = e.value("id", "");
        if (known.insert(id).second) archive["entries"].push_back(e);
        out.ids.push_back(id);
        ++out.moved;
    }
    doc["entries"] = std::move(keep);
    out.open = int(doc["entries"].size());
    out.archived = int(archive["entries"].size());
    return out;
}

Result<FeedbackArchiveResult> archive_closed_feedback_file(const std::string& path) {
    auto loaded = load_feedback(path);
    if (!loaded.ok()) return loaded.error();
    Json doc = std::move(loaded.value());
    const std::string archivePath = feedback_archive_path(path);
    Json archive;
    if (stdfs::exists(archivePath)) {
        auto a = load_feedback(archivePath);
        if (!a.ok()) return a.error();
        archive = std::move(a.value());
    } else {
        archive = create_empty_feedback(doc.is_object() ? doc.value("project", std::string()) : std::string(),
                                        doc.is_object() ? doc.value("engineVersion", std::string()) : std::string());
    }
    FeedbackArchiveResult r = archive_closed_feedback(doc, archive);
    if (r.moved == 0) return r;
    // Archive first: a crash between the two writes leaves an entry in both files (the next run drops the copy), never in none.
    if (auto s = save_feedback(archivePath, archive); !s.ok()) return s.error();
    if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    return r;
}

Json list_archived_feedback(const std::string& path, const FeedbackFilter& filter) {
    const std::string archivePath = feedback_archive_path(path);
    if (!stdfs::exists(archivePath)) return Json::array();
    auto a = load_feedback(archivePath);
    if (!a.ok()) return Json::array();
    return list_feedback(a.value(), filter);
}

Result<Json> update_feedback_file(const std::string& path, std::string_view id, std::string_view status,
                                  std::string_view engineIssue, std::string_view note) {
    auto loaded = load_feedback(path);
    if (!loaded.ok()) return loaded.error();
    Json doc = std::move(loaded.value());
    auto has_id = [&](const Json& d) {
        if (!d.is_object() || !d.contains("entries") || !d["entries"].is_array()) return false;
        for (const auto& e : d["entries"])
            if (e.value("id", "") == id) return true;
        return false;
    };
    auto add_note = [&](Json& d, Json& result) {
        if (note.empty()) return;
        for (auto& e : d["entries"]) {
            if (e.value("id", "") != id) continue;
            if (!e.contains("notes") || !e["notes"].is_array()) e["notes"] = Json::array();
            e["notes"].push_back(std::string(note));
            result = e;
        }
    };
    if (has_id(doc) || !stdfs::exists(feedback_archive_path(path))) {
        auto r = update_feedback_entry(doc, id, status, engineIssue);
        if (!r.ok()) return r;
        Json result = *r;
        add_note(doc, result);
        if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
        return result;
    }
    const std::string archivePath = feedback_archive_path(path);
    auto a = load_feedback(archivePath);
    if (!a.ok()) return a.error();
    Json archive = std::move(a.value());
    if (!has_id(archive)) return update_feedback_entry(doc, id, status, engineIssue);  // the error lists the ids of the file
    auto r = update_feedback_entry(archive, id, status, engineIssue);
    if (!r.ok()) return r;
    Json result = *r;
    add_note(archive, result);
    if (status == "open") {  // reopened by hand: back into the file
        Json moved;
        Json keep = Json::array();
        for (auto& e : archive["entries"]) {
            if (e.value("id", "") == id) moved = e; else keep.push_back(e);
        }
        archive["entries"] = std::move(keep);
        doc["entries"].push_back(moved);
        if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    }
    if (auto s = save_feedback(archivePath, archive); !s.ok()) return s.error();
    return result;
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
    double joinedScore = 1.0;  // similarity to the entry that pulled it into the group (1 for the first)
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

constexpr long kMaxOccurrencesPerProject = 3;
constexpr const char* kNotShared = "(not shared)";

// "local" for an entry written in a project, "verified" / "anonymous" for one pulled from the feedback server (remote.trust).
std::string entry_trust(const Json& e) {
    if (!e.is_object() || !e.contains("remote") || !e["remote"].is_object()) return "local";
    return e["remote"].value("trust", std::string("anonymous")) == "verified" ? "verified" : "anonymous";
}

// Scores are multiples of 0.5: a whole one is written as an integer.
Json score_json(double score) {
    if (score == std::floor(score)) return static_cast<long>(score);
    return std::round(score * 10.0) / 10.0;
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
        // The closed entries archived next to the file belong to the same project: they count where closed ones count.
        Json allEntries = d["entries"];
        if (const std::string archivePath = feedback_archive_path(f); archivePath != f && stdfs::is_regular_file(archivePath)) {
            auto archived = load_feedback(archivePath);
            if (!archived.ok())
                errors.push_back(archivePath + ": " + archived.error().to_string());
            else if (archived->is_object() && archived->contains("entries") && (*archived)["entries"].is_array())
                for (const auto& e : (*archived)["entries"]) allEntries.push_back(e);
        }
        for (const auto& e : allEntries) {
            if (!e.is_object()) continue;
            std::string status = status_of(e);
            if (!opts.includeClosed && status != "open") continue;
            ++total;
            std::string cat = e.value("category", "other"), title = e.value("title", "");
            (void)title;
            Cluster* target = nullptr;
            double best = 0;
            const std::string eid = e.value("id", "");
            for (auto& c : clusters) {
                // An entry never joins a group that holds one it (or that one) lists in distinctFrom.
                bool apart = false;
                for (const auto& it : c.items)
                    if (lists_distinct(e, it.project, it.entry.value("id", ""), project) ||
                        lists_distinct(it.entry, project, eid, it.project)) { apart = true; break; }
                if (apart) continue;
                for (const auto& it : c.items) {
                    double s = feedback_entry_similarity(it.entry, e);
                    if (s >= opts.similarity && s > best) { best = s; target = &c; }
                }
            }
            if (!target) {
                clusters.push_back({cat, {}});
                target = &clusters.back();
            }
            target->items.push_back({project, e, target->items.empty() ? 1.0 : best});
        }
    }

    struct Ranked {
        Json j;
        double score;
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
        // One voice per project (a local project or one installation): its worst severity, the occurrences of its entries
        // here (capped at kMaxOccurrencesPerProject so repeating a report cannot push a gap up) and its trust.
        struct Voice {
            int weight = 0;
            long occurrences = 0;
            double trust = 0;
            bool verified = false;
        };
        std::map<std::string, Voice> voices;
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
            const std::string trust = entry_trust(it.entry);
            Voice& v = voices[it.project];
            v.weight = std::max(v.weight, feedback_severity_weight(s));
            v.occurrences += o;
            v.trust = std::max(v.trust, trust == "anonymous" ? 0.5 : 1.0);
            v.verified = v.verified || trust == "verified";
            entryRefs.push_back(Json::object({{"project", it.project}, {"id", it.entry.value("id", "")},
                                              {"severity", s}, {"status", status_of(it.entry)}, {"occurrences", o},
                                              {"trust", trust},
                                              {"similarity", std::round(it.joinedScore * 100.0) / 100.0}}));
            if (o > repOcc) { repOcc = o; rep = &it; }
            std::string sug = it.entry.value("suggestion", "");
            if (sug.size() > bestSuggestion.size()) bestSuggestion = sug;
            std::string w = it.entry.value("workaround", "");
            if (!w.empty() && w != kNotShared && sampleSeen.insert(w).second && samples.size() < 3) samples.push_back(w);
        }
        double score = 0;
        long verifiedProjects = 0;
        Json projs = Json::array();
        for (const auto& [name, v] : voices) {
            score += v.weight * v.trust * static_cast<double>(std::min(v.occurrences, kMaxOccurrencesPerProject));
            if (v.verified) ++verifiedProjects;
            projs.push_back(name);
        }
        Json j = Json::object();
        j["title"] = rep->entry.value("title", "");
        j["category"] = c.category;
        j["severity"] = sev;
        j["score"] = score_json(score);
        j["totalOccurrences"] = occ;
        j["installations"] = static_cast<long>(voices.size());
        j["verifiedInstallations"] = verifiedProjects;
        j["projects"] = projs;
        j["entries"] = entryRefs;
        j["bestSuggestion"] = bestSuggestion;
        j["sampleWorkarounds"] = samples;
        ranked.push_back({std::move(j), score, rep->entry.value("title", "")});
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
      << json["clusters"].size() << " distinct gap(s). Ranked by the sum over projects of severity weight x trust x "
      << "min(occurrences, 3) (blocker 8, major 4, minor 2, nice-to-have 1; trust 1, or 0.5 for an anonymous "
      << "installation).\n\n";
    if (!json["errors"].empty()) {
        o << "## Problems reading files\n\n";
        for (const auto& e : json["errors"]) o << "- " << e.get<std::string>() << "\n";
        o << "\n";
    }
    if (json["clusters"].empty()) o << "_No open feedback entries._\n";
    for (const auto& c : json["clusters"]) {
        o << "## " << c["rank"].get<int>() << ". " << c["title"].get<std::string>() << "\n\n";
        o << "- **Category:** " << c["category"].get<std::string>() << "\n";
        {
            char buf[32];
            std::snprintf(buf, sizeof buf, "%g", c["score"].get<double>());
            o << "- **Severity:** " << c["severity"].get<std::string>() << " (score " << buf << ")\n";
        }
        o << "- **Installations:** " << c.value("installations", 0L) << " (" << c.value("verifiedInstallations", 0L)
          << " verified)\n";
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
        if (c["entries"].size() > 1) {
            o << "- **Merged (similarity to the group):** ";
            first = true;
            for (const auto& e : c["entries"]) {
                char buf[16];
                std::snprintf(buf, sizeof buf, "%.2f", e.value("similarity", 1.0));
                o << (first ? "" : ", ") << e["project"].get<std::string>() << "/" << e["id"].get<std::string>()
                  << " " << buf;
                first = false;
            }
            o << "\n";
        }
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
    register_feedback_share_commands(registry, projectDir);
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
            "are harmless. A gap the engine already fixed (archived, see feedback.archive) and that you report again reopens the archived entry as a possible regression. Write 'title' as a short noun phrase (\"No one-way platforms\"), 'missing' as what you needed "
            "and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the "
            "concrete engine change that would remove the workaround.\n"
            "SHARE (optional, strongly recommended): `share` is the same gap written for the ENGINE DEVELOPER, who must never "
            "learn what the game is about. Write it in engine terms only: components, fields, commands and API names that "
            "exist (or that you propose), and NOTHING about the game: no game, character, level, scene, entity, asset or script "
            "names, no file names or paths, no quotes from the game, no story. {title (8-120 characters), missing (20-1500, at "
            "least 4 words), suggestion?, workaround? (the kind of workaround, without project details)}. Good: {\"title\":\"No "
            "one-way platforms\",\"missing\":\"Collider2D has no one-way option, so a body cannot pass up through a platform "
            "and land on it.\",\"suggestion\":\"Add Collider2D.oneWay (bool).\",\"workaround\":\"A script disables the "
            "collider while the body moves up.\"}. Bad: \"The knight in Dungeon of Ash cannot jump through scripts/ledge.js "
            "platforms\" (names the game, a character and a file). Check the docs first (docs.search) so the gap is real and "
            "about the engine, then pass reviewed: true. An entry without `share` is never sent. Whether anything is sent is the "
            "USER's choice (mode always, ask or never): the result's `share` says what happened, and no command changes the "
            "mode, so do not try; if it says sharing is not set up, tell the user how to turn it on, once.\n"
            "Example: {\"category\":\"physics\",\"severity\":\"major\",\"title\":\"No one-way platforms\","
            "\"missing\":\"Collider2D has no one-way option so the player cannot jump up through platforms.\","
            "\"workaround\":\"scripts/one_way.js disables the platform collider while the player moves upward.\","
            "\"workaroundFiles\":[\"scripts/one_way.js\"],\"suggestion\":\"Add Collider2D.oneWay (bool).\","
            "\"share\":{\"title\":\"No one-way platforms\",\"missing\":\"Collider2D has no one-way option, so a body cannot "
            "pass up through a platform and land on it.\",\"suggestion\":\"Add Collider2D.oneWay (bool).\"},\"reviewed\":true}";
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
        props["share"] = Json::object({{"type", "object"},
            {"description", "The generic copy for the engine developer, in ENGINE TERMS ONLY: nothing about the game (no names, "
                            "story, characters, assets, file names, paths or quotes). {title, missing, suggestion?, workaround?}. "
                            "Without it the entry is never sent."},
            {"properties", Json::object({
                {"title", Json::object({{"type", "string"}, {"description", "8-120 characters: the gap as a noun phrase, e.g. \"No one-way platforms\"."}})},
                {"missing", Json::object({{"type", "string"}, {"description", "20-1500 characters, at least 4 words: what the engine lacks, naming components, fields or commands."}})},
                {"suggestion", Json::object({{"type", "string"}, {"description", "Up to 1500 characters: the engine change that would fix it."}})},
                {"workaround", Json::object({{"type", "string"}, {"description", "Up to 1500 characters: the kind of workaround, without project details."}})}})},
            {"required", Json::array({"title", "missing"})}});
        props["reviewed"] = Json::object({{"type", "boolean"},
            {"description", "true when you checked against the docs (docs.search, docs.components) that the gap is real and about the engine."}});
        props["reporter"] = Json::object({{"type", "object"},
            {"description", "Who is reporting. Defaults to {\"kind\":\"ai\"}; include your agent and model if you know them."},
            {"properties", Json::object({{"kind", enum_schema({"ai", "human"}, "ai or human.")},
                                         {"agent", Json::object({{"type", "string"}, {"description", "e.g. claude-code, codex."}})},
                                         {"model", Json::object({{"type", "string"}, {"description", "Model id."}})}})}});
        info.inputSchema = Json::object({{"type", "object"}, {"properties", props},
            {"required", Json::array({"category", "severity", "title", "missing", "workaround"})}});
        registry.add(info, [projectDir, &registry](const Json& args) {
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
            if (args.contains("share") && !args["share"].is_null()) in.share = args["share"];
            if (args.contains("reviewed") && args["reviewed"].is_boolean()) in.reviewed = args["reviewed"].get<bool>();
            std::string path = feedback_path_for(projectDir);
            auto r = add_feedback_entry_to_file(path, in, project_name_for(projectDir));
            if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
            Json out = Json::object();
            out["id"] = r->id;
            out["merged"] = r->merged;
            out["occurrences"] = r->occurrences;
            out["file"] = stdfs::path(path).filename().string();
            out["reopened"] = r->reopened;
            // Sharing never fails the report: whatever goes wrong is told in `share`.
            if (!r->shareProblem.empty()) {
                out["share"] = Json::object({{"status", "invalid"},
                    {"message", "`share` was not stored: " + r->shareProblem + ". The entry is recorded without it and will not be shared. "
                                "Report again with a corrected share (same title) to add it."}});
            } else if (args.contains("share") && !args["share"].is_null()) {
                Json summary = share_report_summary(share_env(), path, projectDir, r->id, &registry, true);
                if (!summary.is_null()) out["share"] = std::move(summary);
            }
            out["message"] = r->reopened ? "Reopened " + r->id + ": it was fixed in the engine and is reported again (a regression?). Thank you."
                             : r->merged ? "Merged into existing entry " + r->id + " (now " + std::to_string(r->occurrences) +
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
        info.description = "Check this before reporting to see what is already recorded. Filters are optional. The file only holds "
                           "what is still open (plus entries closed since the last feedback.archive): entries that are fixed, "
                           "rejected or duplicates live in the archive file next to it; pass includeArchive to list them too "
                           "(each marked \"archived\": true). Example: {\"status\":\"open\",\"category\":\"physics\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"status", enum_schema(feedback_statuses(), "Only entries with this status.")},
                                         {"category", enum_schema(feedback_categories(), "Only this category.")},
                                         {"severity", enum_schema(feedback_severities(), "Only this severity.")},
                                         {"includeArchive", Json::object({{"type", "boolean"},
                                              {"description", "Also list the archived (closed) entries, marked archived: true."}})}})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            if (!stdfs::exists(path))
                return Json::object({{"entries", Json::array()}, {"count", 0}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            auto doc = load_feedback(path);
            if (!doc.ok()) throw CommandError("failed", doc.error().message, doc.error().hint);
            FeedbackFilter f{arg_string(args, "status", false), arg_string(args, "category", false), arg_string(args, "severity", false)};
            Json entries = list_feedback(doc.value(), f);
            const Json archived = list_archived_feedback(path);
            if (args.value("includeArchive", false)) {
                for (auto e : list_archived_feedback(path, f)) {
                    e["archived"] = true;
                    entries.push_back(std::move(e));
                }
            }
            return Json::object({{"count", entries.size()}, {"entries", entries}, {"archivedCount", archived.size()}});
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.update";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Change the status of a feedback entry or link it to an engine issue.";
        info.description = "Engine developers use this when a gap is fixed (status fixed-in-engine), rejected (wont-fix) or "
                           "duplicated; the entry moves to the archive on the next feedback.archive (the editor runs it when it opens "
                           "the project). An archived entry is found too, and set to open it moves back to the file. Example: {\"id\":\"FB-0001\",\"status\":\"fixed-in-engine\",\"engineIssue\":\"#42\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"id", Json::object({{"type", "string"}, {"description", "Entry id, e.g. FB-0001."}})},
                                         {"status", enum_schema(feedback_statuses(), "New status.")},
                                         {"engineIssue", Json::object({{"type", "string"}, {"description", "Issue/PR link or id."}})}})},
            {"required", Json::array({"id"})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            std::string status = arg_string(args, "status", false), issue = arg_string(args, "engineIssue", false);
            if (status.empty() && issue.empty())
                throw CommandError("invalid_argument", "Nothing to update.", "Pass status and/or engineIssue.");
            auto r = update_feedback_file(path, arg_string(args, "id", true), status, issue);
            if (!r.ok()) throw CommandError("not_found", r.error().message, r.error().hint);
            return r.value();
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.archive";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Move the closed feedback entries (fixed-in-engine, wont-fix, duplicate) to the archive file.";
        info.description =
            "ENGINE_FEEDBACK.json should only hold what is still open: this moves every entry whose status is not open to "
            "ENGINE_FEEDBACK.archive.json next to it (same format). Ids stay unique across both files and keep counting up; "
            "a new report that matches an archived fixed-in-engine entry reopens it (feedback.report says reopened). "
            "The editor runs this when it opens the project. Safe to repeat: with nothing closed it changes nothing. "
            "feedback.list with includeArchive and `factoria feedback collect` still see the archived entries.";
        info.inputSchema = Json::object({{"type", "object"}, {"properties", Json::object()}});
        registry.add(info, [projectDir](const Json&) {
            std::string path = feedback_path_for(projectDir);
            if (!stdfs::exists(path))
                return Json::object({{"moved", 0}, {"ids", Json::array()}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            auto r = archive_closed_feedback_file(path);
            if (!r.ok()) throw CommandError("failed", r.error().message, r.error().hint);
            return Json::object({{"moved", r->moved}, {"ids", r->ids}, {"open", r->open}, {"archived", r->archived},
                                 {"file", stdfs::path(path).filename().string()},
                                 {"archiveFile", stdfs::path(feedback_archive_path(path)).filename().string()}});
        });
    }
}

}  // namespace fa
