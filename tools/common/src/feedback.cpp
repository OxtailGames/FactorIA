#include "fa/core/engine_version.h"
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
#include "fa/tooling/feedback_check.h"
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
const std::vector<std::string>& feedback_kinds() {
    static const std::vector<std::string> v = {"gap", "efficiency"};
    return v;
}
const std::vector<std::string>& feedback_statuses() {
    static const std::vector<std::string> v = {"open", "fixed-in-engine", "wont-fix", "duplicate", "rejected"};
    return v;
}
const std::vector<std::string>& feedback_status_authors() {
    static const std::vector<std::string> v = {"engine", "user", "developer"};
    return v;
}
std::string sanitize_status_reason(std::string_view reason) {
    std::string out;
    bool space = false;
    std::size_t chars = 0;
    for (std::size_t i = 0; i < reason.size() && chars < std::size_t(kFeedbackReasonMax); ++i) {
        const unsigned char c = static_cast<unsigned char>(reason[i]);
        if (c < 0x20 || c == 0x7F || c == ' ') {
            space = !out.empty();
            continue;
        }
        if (space) {
            out += ' ';
            ++chars;
            space = false;
            if (chars >= std::size_t(kFeedbackReasonMax)) break;
        }
        // a UTF-8 sequence is copied whole
        std::size_t len = c < 0x80 ? 1 : (c >> 5) == 0x6 ? 2 : (c >> 4) == 0xE ? 3 : (c >> 3) == 0x1E ? 4 : 1;
        len = std::min(len, reason.size() - i);
        out.append(reason.substr(i, len));
        i += len - 1;
        ++chars;
    }
    return out;
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

// A file or folder name as UTF-8 text (the JSON and the messages are UTF-8): string() on Windows is the ANSI code page, which turns
// a letter outside it into '?'.
std::string u8text(const stdfs::path& p) {
    const std::u8string u = p.u8string();
    return std::string(reinterpret_cast<const char*>(u.data()), u.size());
}

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

// The number the next new id gets at least (`nextId` of the document; 1 when it has none).
int next_id_of(const Json& doc) {
    if (!doc.is_object() || !doc.contains("nextId") || !doc["nextId"].is_number_integer()) return 1;
    return std::max(1, doc["nextId"].get<int>());
}

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

std::string kind_of(const Json& e) { return e.is_object() && e.contains("kind") && e["kind"].is_string() ? e["kind"].get<std::string>() : std::string("gap"); }

// The id the next new entry gets: after every id of both files, after `nextId` of both (ids of deleted entries are not given again).
std::string next_entry_id(const Json& doc, const Json* archive) {
    int top = max_entry_number(doc["entries"]);
    if (archive && archive->is_object() && archive->contains("entries") && (*archive)["entries"].is_array())
        top = std::max(top, max_entry_number((*archive)["entries"]));
    top = std::max({top, next_id_of(doc) - 1, archive ? next_id_of(*archive) - 1 : 0});
    char idbuf[16];
    std::snprintf(idbuf, sizeof idbuf, "FB-%04d", top + 1);
    return idbuf;
}

bool spans_overlap(const Json& a, const Json& b) {
    if (!a.is_object() || !b.is_object() || a.value("session", std::string()) != b.value("session", std::string())) return false;
    return a.value("fromStep", 0) <= b.value("toStep", 0) && a.value("toStep", 0) >= b.value("fromStep", 0);
}

int applies_rank(const std::string& a) { return a == "every-game" ? 3 : a == "genre" ? 2 : a == "feature" ? 1 : 0; }

constexpr std::size_t kEfficiencyMaxEvidence = 200;  // spans one entry keeps

// An efficiency entry: merged by fix into an open one (same fix type and category, similar title or suggestion) adding the measured numbers
// of the spans it did not count yet, else appended.
Result<FeedbackAddResult> add_efficiency_entry(Json& doc, const FeedbackInput& in, Json* archive, const Json& share,
                                               const std::string& shareProblem, const std::string& today) {
    const Json& eff = in.efficiency;
    auto bad = [](const std::string& what) {
        return make_error("An efficiency entry needs " + what + ".",
                          "File it through feedback.report with kind efficiency (or `factoria feedback add --kind efficiency`): the gate measures the evidence and fills these fields.");
    };
    if (!eff.is_object()) return bad("its efficiency fields");
    for (const char* key : {"waste", "fixType", "appliesTo"})
        if (!eff.contains(key) || !eff[key].is_string()) return bad(std::string("`") + key + "`");
    if (!contains(efficiency_fix_types(), eff["fixType"].get<std::string>()))
        return make_error("Invalid fixType '" + eff["fixType"].get<std::string>() + "'. " + did_you_mean(eff["fixType"].get<std::string>(), efficiency_fix_types()));
    for (const char* key : {"evidence", "spans"})
        if (!eff.contains(key) || !eff[key].is_array() || eff[key].empty()) return bad(std::string("`") + key + "` (at least one span)");
    for (const char* key : {"expectedSaving", "measured", "saving"})
        if (!eff.contains(key) || !eff[key].is_object()) return bad(std::string("`") + key + "`");
    const std::string fixType = eff["fixType"].get<std::string>();
    const double share_ = eff["expectedSaving"].value("share", 0.0);

    Json& entries = doc["entries"];
    Json* best = nullptr;
    double bestScore = 0.0;
    for (auto& e : entries) {
        if (!e.is_object() || status_of(e) != "open" || kind_of(e) != "efficiency" || e.value("category", "") != in.category ||
            e.value("fixType", "") != fixType)
            continue;
        double sim = feedback_title_similarity(e.value("title", ""), in.title);
        if (!in.suggestion.empty() && e.contains("suggestion") && e["suggestion"].is_string())
            sim = std::max(sim, feedback_title_similarity(e["suggestion"].get<std::string>(), in.suggestion));
        if (sim >= 0.7 && sim > bestScore) { best = &e; bestScore = sim; }
    }
    FeedbackAddResult result;
    if (best) {
        Json& e = *best;
        if (!e.contains("evidence") || !e["evidence"].is_array()) e["evidence"] = Json::array();
        EfficiencyMeasure newMeasured;
        int fresh = 0;
        for (const Json& span : eff["spans"]) {
            bool counted = false;
            for (const Json& have : e["evidence"]) counted = counted || spans_overlap(have, span);
            if (counted) continue;
            if (e["evidence"].size() >= kEfficiencyMaxEvidence)
                return make_error("Entry " + e.value("id", std::string()) + " already holds " + std::to_string(kEfficiencyMaxEvidence) + " evidence spans.",
                                  "That is plenty to rank it: stop adding spans to this entry.");
            e["evidence"].push_back(Json::object({{"session", span.value("session", std::string())}, {"fromStep", span.value("fromStep", 0)},
                                                  {"toStep", span.value("toStep", 0)}}));
            newMeasured += EfficiencyMeasure::from_json(span.contains("measured") ? span["measured"] : Json::object());
            ++fresh;
        }
        result.id = e["id"].get<std::string>();
        result.merged = true;
        if (fresh == 0) {
            // The same evidence again (a retry, a second retrospective of the same session): nothing is counted twice.
            result.alreadyCounted = true;
            result.occurrences = e.value("occurrences", 1);
            result.entry = e;
            result.shareProblem = shareProblem;
            return result;
        }
        EfficiencyMeasure measured = EfficiencyMeasure::from_json(e.contains("measured") ? e["measured"] : Json::object());
        measured += newMeasured;
        e["measured"] = measured.to_json();
        EfficiencyMeasure saving = EfficiencyMeasure::from_json(e.contains("saving") ? e["saving"] : Json::object());
        saving += scale_measure(newMeasured, share_);
        e["saving"] = saving.to_json();
        const int occ = e.value("occurrences", 1) + 1;
        e["occurrences"] = occ;
        if (!e.contains("notes") || !e["notes"].is_array()) e["notes"] = Json::array();
        e["notes"].push_back(today + ": " + eff["waste"].get<std::string>());
        if (!in.severity.empty() && feedback_severity_weight(in.severity) > feedback_severity_weight(e.value("severity", "minor"))) e["severity"] = in.severity;
        if (!in.suggestion.empty() && (!e.contains("suggestion") || e["suggestion"].get<std::string>().size() < in.suggestion.size()))
            e["suggestion"] = in.suggestion;
        if (applies_rank(eff["appliesTo"].get<std::string>()) > applies_rank(e.value("appliesTo", std::string())))
            e["appliesTo"] = eff["appliesTo"];
        if (eff.contains("everyStepTokens") && eff["everyStepTokens"].is_number_integer() &&
            eff["everyStepTokens"].get<long long>() > e.value("everyStepTokens", 0LL))
            e["everyStepTokens"] = eff["everyStepTokens"];
        if (share.is_object()) {
            auto size_of = [](const Json& j) { return j.value("title", std::string()).size() + j.value("missing", std::string()).size() +
                                                      j.value("suggestion", std::string()).size() + j.value("workaround", std::string()).size(); };
            if (!e.contains("share") || !e["share"].is_object() || size_of(share) >= size_of(e["share"])) {
                const bool changed = !e.contains("share") || e["share"] != share;
                e["share"] = share;
                if (changed && e.contains("shared") && e["shared"].is_object() && e["shared"].value("status", std::string()) != "sent") e.erase("shared");
            }
        }
        for (const char* key : {"pattern", "afterFix"})  // where it came from: kept from the first report that knew
            if ((!e.contains(key) || !e[key].is_string()) && eff.contains(key) && eff[key].is_string()) e[key] = eff[key];
        if (in.reviewed && *in.reviewed) e["reviewed"] = true;
        result.occurrences = occ;
        result.entry = e;
        result.shareProblem = shareProblem;
        return result;
    }

    Json e = Json::object();
    e["id"] = next_entry_id(doc, archive);
    e["date"] = today;
    e["kind"] = "efficiency";
    if (in.reporter.is_object() && !in.reporter.empty()) e["reporter"] = in.reporter;
    e["category"] = in.category;
    e["severity"] = in.severity.empty() ? std::string("minor") : in.severity;
    e["title"] = std::string(trim(in.title));
    e["missing"] = in.missing.empty() ? eff["waste"].get<std::string>() : in.missing;
    e["workaround"] = in.workaround.empty() ? std::string("none: the work went on with the waste (see evidence)") : in.workaround;
    if (!in.suggestion.empty()) e["suggestion"] = in.suggestion;
    if (!in.effort.empty()) e["effort"] = in.effort;
    for (const char* key : {"waste", "evidence", "fixType", "expectedSaving", "appliesTo", "measured", "saving", "whyNotCheaper", "searched",
                            "existingDoc", "everyStepTokens", "candidate", "pattern", "afterFix"})
        if (eff.contains(key) && !eff[key].is_null()) e[key] = eff[key];
    if (share.is_object()) e["share"] = share;
    if (in.reviewed) e["reviewed"] = *in.reviewed;
    e["occurrences"] = 1;
    e["status"] = "open";
    entries.push_back(e);
    result.id = e["id"].get<std::string>();
    result.entry = e;
    result.shareProblem = shareProblem;
    return result;
}

}  // namespace

namespace {

// An efficiency entry carries numbers the engine measured from the transcripts (and a share text derived from them): it may only come
// from file_efficiency_feedback, after check_efficiency_report. The public entry points refuse the kind.
Error efficiency_needs_the_gate() {
    return Error{"kind efficiency cannot be added with add_feedback_entry: an efficiency entry holds numbers the engine measured, and only the "
                 "efficiency gate (check_efficiency_report) writes them.",
                 "Use file_efficiency_feedback in code, or `feedback add --kind efficiency` / feedback.report with kind efficiency, which measure the "
                 "evidence spans from the session transcripts first."};
}

// add_feedback_entry without that refusal: file_efficiency_feedback calls it after the gate.
Result<FeedbackAddResult> add_entry_gated(Json& doc, const FeedbackInput& in, Json* archive);
Result<FeedbackAddResult> add_entry_to_file_gated(const std::string& path, const FeedbackInput& input, std::string_view projectNameIfNew);

}  // namespace

Result<FeedbackAddResult> add_feedback_entry(Json& doc, const FeedbackInput& in, Json* archive) {
    if (in.kind == "efficiency") return efficiency_needs_the_gate();
    return add_entry_gated(doc, in, archive);
}

namespace {
Result<FeedbackAddResult> add_entry_gated(Json& doc, const FeedbackInput& in, Json* archive) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array())
        return make_error("ENGINE_FEEDBACK.json has no \"entries\" array.",
                          "Start from create_empty_feedback() or run `factoria feedback init`.");
    if (!in.kind.empty() && !contains(feedback_kinds(), in.kind))
        return make_error("Invalid kind '" + in.kind + "'. " + did_you_mean(in.kind, feedback_kinds()),
                          "gap (the engine lacked something or got it wrong, the default) or efficiency (the same work in fewer steps, minutes or tokens).");
    const bool efficiency = in.kind == "efficiency";
    if (std::string m = check_enum("category", in.category, feedback_categories()); !m.empty())
        return make_error(m, "Pick the closest engine area; use \"other\" if none fits.");
    if (!(efficiency && in.severity.empty()))
        if (std::string m = check_enum("severity", in.severity, feedback_severities()); !m.empty())
            return make_error(m, "blocker = could not build it; major = big workaround; minor = small; nice-to-have = convenience.");
    if (!in.effort.empty() && !contains({"small", "medium", "large"}, in.effort))
        return make_error("Invalid effort '" + in.effort + "'.", "Use small, medium or large (or omit it).");
    auto need = [](const std::string& v, const char* name) -> std::string {
        if (trim(v).size() < 3) return std::string("Field '") + name + "' is required (at least a few words).";
        return {};
    };
    if (efficiency) {
        if (std::string m = need(in.title, "title"); !m.empty()) return make_error(m, "Name the waste as a short noun phrase (title).");
    } else {
        for (auto [v, n] : {std::pair<const std::string&, const char*>{in.title, "title"}, {in.missing, "missing"},
                            {in.workaround, "workaround"}})
            if (std::string m = need(v, n); !m.empty())
                return make_error(m, "Say what the engine lacked (missing), the short name (title) and what you did instead (workaround).");
    }

    Json& entries = doc["entries"];
    const std::string today = tooling_detail::today_utc();

    // The generic copy for sharing: a bad one is left out (the entry is still recorded) and the result says why.
    Json share;
    std::string shareProblem;
    if (!in.share.is_null()) {
        shareProblem = normalize_share(in.share, share);
        if (!shareProblem.empty()) share = Json();
    }

    if (efficiency) {
        // No generic copy given: the entry's own words are one (the title, the waste "in engine terms, nothing about the game" and the
        // fix), and the sanitizer removes anything of the game from them before they leave the machine, as for a gap. When they are too
        // short to share, the entry just stays local.
        if (in.share.is_null() && in.efficiency.is_object() && in.efficiency.contains("waste") && in.efficiency["waste"].is_string()) {
            Json derived = Json::object({{"title", std::string(trim(in.title))}, {"missing", in.efficiency["waste"].get<std::string>()}});
            if (!in.suggestion.empty()) derived["suggestion"] = in.suggestion;
            Json clean;
            if (normalize_share(derived, clean).empty()) share = clean;
        }
        return add_efficiency_entry(doc, in, archive, share, shareProblem, today);
    }

    // Dedupe against open entries of the same category (efficiency entries merge among themselves, by fix).
    Json* best = nullptr;
    double bestScore = 0.0;
    for (auto& e : entries) {
        if (!e.is_object() || status_of(e) != "open" || e.value("category", "") != in.category || kind_of(e) == "efficiency") continue;
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
            if (!e.is_object() || status_of(e) != "fixed-in-engine" || e.value("category", "") != in.category || kind_of(e) == "efficiency") continue;
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

    const std::string newId = next_entry_id(doc, archive);  // ids of deleted entries are not given again
    Json e = Json::object();
    e["id"] = newId;
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
    result.id = newId;
    result.entry = e;
    result.shareProblem = shareProblem;
    return result;
}
}  // namespace

Result<FeedbackAddResult> add_feedback_entry_to_file(const std::string& path, const FeedbackInput& input, std::string_view projectNameIfNew) {
    if (input.kind == "efficiency") return efficiency_needs_the_gate();
    return add_entry_to_file_gated(path, input, projectNameIfNew);
}

namespace {
Result<FeedbackAddResult> add_entry_to_file_gated(const std::string& path, const FeedbackInput& input, std::string_view projectNameIfNew) {
    Json doc;
    if (stdfs::exists(path)) {
        auto loaded = load_feedback(path);
        if (!loaded.ok()) return loaded.error();
        doc = std::move(loaded.value());
    } else {
        std::string name(projectNameIfNew);
        if (name.empty()) name = u8text(stdfs::path(path).parent_path().filename());
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
    auto r = add_entry_gated(doc, input, haveArchive ? &archive : nullptr);
    if (!r.ok()) return r;
    if (r->alreadyCounted) return r;  // nothing changed
    // The entry is in the file before it leaves the archive: a crash in between leaves it twice, never lost.
    if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    if (r->reopened)
        if (auto s = save_feedback(archivePath, archive); !s.ok()) return s.error();
    return r;
}
}  // namespace

EfficiencyFiling file_efficiency_feedback(const std::string& projectDir, const std::string& feedbackFile, FeedbackInput base, const Json& args,
                                          std::string_view projectNameIfNew, const EfficiencyOrigin& origin) {
    EfficiencyFiling out;
    EfficiencyInput in;
    if (auto r = efficiency_input_from_json(args, in)) {
        out.refusal = std::move(r);
        return out;
    }
    if (!base.category.empty()) in.category = base.category;
    if (!base.title.empty()) in.title = base.title;
    if (!base.suggestion.empty()) in.suggestion = base.suggestion;
    if (std::string m = check_enum("category", in.category, feedback_categories()); !m.empty()) {
        out.refusal = EfficiencyRefusal{"invalid_argument", "/category: " + m, "Pick the engine area the fix belongs to; use \"other\" if none fits."};
        return out;
    }
    if (trim(in.title).size() < 3) {
        out.refusal = EfficiencyRefusal{"invalid_argument", "/title is missing.", "Name the waste as a short noun phrase."};
        return out;
    }
    if (auto r = check_efficiency_report(projectDir, in, out.verdict)) {
        out.refusal = std::move(r);
        return out;
    }
    Json eff = Json::object();
    eff["waste"] = in.waste;
    Json evidence = Json::array(), spans = Json::array();
    for (std::size_t i = 0; i < out.verdict.evidence.size(); ++i) {
        const Json span = out.verdict.evidence[i].to_json();
        evidence.push_back(span);
        Json withNumbers = span;
        withNumbers["measured"] = out.verdict.spanMeasures[i].to_json();
        spans.push_back(std::move(withNumbers));
    }
    eff["evidence"] = std::move(evidence);
    eff["spans"] = std::move(spans);
    eff["fixType"] = in.fixType;
    eff["expectedSaving"] = Json::object({{"share", in.saveShare}, {"why", in.saveWhy}});
    eff["appliesTo"] = in.appliesTo;
    eff["measured"] = out.verdict.measured.to_json();
    eff["saving"] = out.verdict.saving.to_json();
    if (!in.whyNotCheaper.empty()) eff["whyNotCheaper"] = in.whyNotCheaper;
    if (!in.searched.empty()) eff["searched"] = in.searched;
    if (!out.verdict.existingDoc.empty()) eff["existingDoc"] = out.verdict.existingDoc;
    if (in.everyStepTokens > 0) eff["everyStepTokens"] = in.everyStepTokens;
    if (out.verdict.candidateOnly) eff["candidate"] = true;
    if (!origin.pattern.empty()) eff["pattern"] = origin.pattern;
    if (!origin.afterFix.empty()) eff["afterFix"] = origin.afterFix;
    base.kind = "efficiency";
    base.category = in.category;
    base.title = in.title;
    base.suggestion = in.suggestion;
    base.efficiency = std::move(eff);
    // A read-modify-write of a file that the editor, the CLI, an agent and a retrospective may write at once.
    FeedbackFileLock lock(share_env(), feedbackFile);
    if (!lock.held()) {
        out.refusal = EfficiencyRefusal{"failed", lock.error(), "Run the command again in a moment; the other program is only writing a small file."};
        return out;
    }
    auto added = add_entry_to_file_gated(feedbackFile, base, projectNameIfNew);
    if (!added.ok()) {
        out.refusal = EfficiencyRefusal{"invalid_argument", added.error().message, added.error().hint};
        return out;
    }
    out.added = std::move(added.value());
    return out;
}

std::string feedback_archive_path(const std::string& feedbackPath) {
    // Text only, so that the bytes of the path stay as the caller gave them (a round trip through string() changes them on Windows).
    const std::size_t slash = feedbackPath.find_last_of("/\\");
    const std::size_t nameAt = slash == std::string::npos ? 0 : slash + 1;
    if (feedbackPath.size() - nameAt > 5 && feedbackPath.compare(feedbackPath.size() - 5, 5, ".json") == 0)
        return feedbackPath.substr(0, feedbackPath.size() - 5) + ".archive.json";
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

Result<void> record_fix_check(const std::string& path, std::string_view id, const Json& check) {
    // A read-modify-write of the file a report, the editor or another retrospective may be writing: under the lock they take.
    FeedbackFileLock lock(share_env(), path);
    if (!lock.held()) return make_error(lock.error(), "Run the command again in a moment; the other program is only writing a small file.");
    const std::string archivePath = feedback_archive_path(path);
    for (const std::string& file : {path, archivePath}) {
        std::error_code ec;
        if (!stdfs::is_regular_file(file, ec)) continue;
        auto loaded = load_feedback(file);
        if (!loaded.ok()) return loaded.error();
        Json doc = std::move(loaded.value());
        if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array()) continue;
        for (Json& e : doc["entries"]) {
            if (!e.is_object() || e.value("id", std::string()) != id) continue;
            if (status_of(e) != "fixed-in-engine")
                return make_error("Entry " + std::string(id) + " is not fixed in the engine, so there is no fix to check.",
                                  "A fix check belongs to an entry with status fixed-in-engine (feedback update --status fixed-in-engine).");
            if (e.contains("fixCheck") && e["fixCheck"] == check) return {};  // nothing new: do not rewrite the file
            e["fixCheck"] = check;
            if (auto s = save_feedback(file, doc); !s.ok()) return s.error();
            return {};
        }
    }
    return make_error("No feedback entry with id '" + std::string(id) + "' in " + path + " or its archive.", "Check the id with feedback list.");
}

Json list_archived_feedback(const std::string& path, const FeedbackFilter& filter) {
    const std::string archivePath = feedback_archive_path(path);
    if (!stdfs::exists(archivePath)) return Json::array();
    auto a = load_feedback(archivePath);
    if (!a.ok()) return Json::array();
    return list_feedback(a.value(), filter);
}

Result<Json> set_feedback_share_file(const std::string& path, std::string_view id, const FeedbackShareEdit& edit) {
    auto loaded = load_feedback(path);
    if (!loaded.ok()) return loaded.error();
    Json doc = std::move(loaded.value());
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array())
        return make_error(path + " has no \"entries\" array.", "Start from `factoria feedback init`.");
    std::vector<std::string> ids;
    Json* entry = nullptr;
    for (auto& e : doc["entries"]) {
        ids.push_back(e.value("id", std::string()));
        if (ids.back() == id) entry = &e;
    }
    if (!entry)
        return make_error("No feedback entry '" + std::string(id) + "' in " + path + ". " + did_you_mean(std::string(id), ids),
                          "List the ids with feedback.list.");
    Json share;
    if (!edit.clearShare && !edit.share.is_null()) {
        if (std::string problem = normalize_share(edit.share, share); !problem.empty())
            return make_error("The share text of " + std::string(id) + " was not saved: " + problem + ".",
                              "Limits: title " + std::to_string(kShareTitleMin) + "-" + std::to_string(kShareTitleMax) + " characters, missing " +
                                  std::to_string(kShareMissingMin) + "-" + std::to_string(kShareMissingMax) + ", suggestion and workaround at most " +
                                  std::to_string(kShareSuggestionMax) + ".");
    }
    Json& e = *entry;
    bool textChanged = false;
    if (edit.clearShare) {
        textChanged = e.contains("share");
        e.erase("share");
    } else if (share.is_object()) {
        textChanged = !e.contains("share") || e["share"] != share;
        e["share"] = share;
    }
    if (textChanged && e.contains("shared") && e["shared"].is_object() && e["shared"].value("status", std::string()) != "sent")
        e.erase("shared");
    if (edit.reviewed) e["reviewed"] = *edit.reviewed;
    else if (textChanged) e["reviewed"] = false;
    if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    return e;
}

Result<Json> update_feedback_file(const std::string& path, std::string_view id, std::string_view status,
                                  std::string_view engineIssue, std::string_view note, std::string_view reason,
                                  std::string_view by) {
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
        auto r = update_feedback_entry(doc, id, status, engineIssue, reason, by);
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
    if (!has_id(archive)) return update_feedback_entry(doc, id, status, engineIssue, reason, by);  // the error lists the ids of the file
    auto r = update_feedback_entry(archive, id, status, engineIssue, reason, by);
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
        result = moved;
        if (auto s = save_feedback(path, doc); !s.ok()) return s.error();
    }
    if (auto s = save_feedback(archivePath, archive); !s.ok()) return s.error();
    return result;
}

bool feedback_entry_deletable(const Json& e, std::string* whyNot) {
    const std::string status = e.is_object() ? status_of(e) : "open";
    if (status != "open") return true;
    if (e.is_object() && e.contains("shared") && e["shared"].is_object()) {
        const std::string shared = e["shared"].value("status", std::string());
        if (shared == "rejected" || shared == "declined") return true;
    }
    if (whyNot)
        *whyNot = "Entry " + (e.is_object() ? e.value("id", std::string()) : std::string()) +
                  " is still open, so it is not deleted: an open entry is a question for the engine developers. Close it first "
                  "(feedback.update with status wont-fix, duplicate or rejected and a reason), then delete it.";
    return false;
}

Result<Json> delete_feedback_file(const std::string& path, std::string_view id, const std::function<Result<void>()>& beforeWrite) {
    auto loaded = load_feedback(path);
    if (!loaded.ok()) return loaded.error();
    Json doc = std::move(loaded.value());
    const std::string archivePath = feedback_archive_path(path);
    Json archive;
    bool haveArchive = false;
    if (stdfs::exists(archivePath)) {
        auto a = load_feedback(archivePath);
        if (!a.ok()) return a.error();
        archive = std::move(a.value());
        haveArchive = true;
    }
    std::vector<std::string> ids;
    auto find_in = [&](Json& d) -> std::ptrdiff_t {
        if (!d.is_object() || !d.contains("entries") || !d["entries"].is_array()) return -1;
        for (std::size_t i = 0; i < d["entries"].size(); ++i) {
            const std::string eid = d["entries"][i].value("id", std::string());
            ids.push_back(eid);
            if (eid == id) return std::ptrdiff_t(i);
        }
        return -1;
    };
    Json* where = &doc;
    std::ptrdiff_t at = find_in(doc);
    if (at < 0 && haveArchive) {
        where = &archive;
        at = find_in(archive);
    }
    if (at < 0)
        return make_error("No feedback entry '" + std::string(id) + "' in " + path + " or its archive. " + did_you_mean(std::string(id), ids),
                          "List the ids with feedback.list (includeArchive: true).");
    Json entry = (*where)["entries"][std::size_t(at)];
    std::string why;
    if (!feedback_entry_deletable(entry, &why))
        return make_error(why, "feedback.update { \"id\": \"" + std::string(id) + "\", \"status\": \"rejected\", \"statusReason\": \"...\" } closes it.");
    if (beforeWrite)
        if (auto pre = beforeWrite(); !pre.ok()) return pre.error();
    int number = 0;
    const std::string eid = entry.value("id", std::string());
    if (eid.rfind("FB-", 0) == 0) {
        try { number = std::stoi(eid.substr(3)); } catch (...) {}
    }
    (*where)["entries"].erase((*where)["entries"].begin() + at);
    // The number is not given again, whichever file holds the highest ones.
    (*where)["nextId"] = std::max(next_id_of(*where), number + 1);
    if (auto s = save_feedback(where == &doc ? path : archivePath, *where); !s.ok()) return s.error();
    return entry;
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

namespace {

// "FactorIA 0.17.0" -> "0.17.0": the engine version that fixed an entry, from its engineIssue. "" when the text names none.
std::string fixed_version_of(std::string_view engineIssue) {
    const std::string_view prefix = "FactorIA ";
    const std::size_t at = engineIssue.find(prefix);
    if (at == std::string_view::npos) return {};
    std::string v;
    for (std::size_t i = at + prefix.size(); i < engineIssue.size(); ++i) {
        const char c = engineIssue[i];
        if (std::isalnum(static_cast<unsigned char>(c)) || c == '.' || c == '+' || c == '_' || c == '-') v += c;
        else break;
    }
    while (!v.empty() && (v.back() == '.' || v.back() == '-')) v.pop_back();  // the full stop of a sentence
    return v.size() <= 32 && !v.empty() && std::isdigit(static_cast<unsigned char>(v[0])) ? v : std::string();
}

// What an efficiency entry cost PER SPAN before its fix: the pattern the next retrospectives compare against (the entry's numbers add up
// over its spans, so the average of one span is what one occurrence of the waste costs).
Json fix_baseline_of(const Json& e) {
    const int spans = e.contains("evidence") && e["evidence"].is_array() ? static_cast<int>(e["evidence"].size()) : 0;
    if (spans <= 0 || !e.contains("measured") || !e["measured"].is_object()) return Json();
    const EfficiencyMeasure m = EfficiencyMeasure::from_json(e["measured"]);
    auto per = [spans](double v) { return std::round(v / spans * 10.0) / 10.0; };
    return Json::object({{"spans", spans}, {"steps", per(m.steps)}, {"toolCalls", per(m.toolCalls)}, {"minutes", per(m.minutes)},
                         {"tokens", std::llround(static_cast<double>(m.tokens) / spans)},
                         {"costUsd", std::round(m.costUsd / spans * 10000.0) / 10000.0}, {"estimated", m.estimated}});
}

}  // namespace

Result<Json> update_feedback_entry(Json& doc, std::string_view id, std::string_view status, std::string_view engineIssue,
                                   std::string_view reason, std::string_view by) {
    if (!doc.is_object() || !doc.contains("entries") || !doc["entries"].is_array())
        return make_error("ENGINE_FEEDBACK.json has no \"entries\" array.");
    if (!status.empty() && !contains(feedback_statuses(), status))
        return make_error("Invalid status '" + std::string(status) + "'. " + did_you_mean(status, feedback_statuses()));
    if (!by.empty() && !contains(feedback_status_authors(), by))
        return make_error("Invalid statusBy '" + std::string(by) + "'. " + did_you_mean(by, feedback_status_authors()));
    const std::string cleanReason = sanitize_status_reason(reason);
    std::vector<std::string> ids;
    for (auto& e : doc["entries"]) {
        std::string eid = e.value("id", "");
        ids.push_back(eid);
        if (eid != id) continue;
        const std::string before = status_of(e);
        const std::string after = status.empty() ? before : std::string(status);
        if (after == "rejected" && cleanReason.empty() && !(before == "rejected" && !e.value("statusReason", std::string()).empty()))
            return make_error("Rejecting " + std::string(id) + " needs a reason: the person who filed it reads it in the editor.",
                              "Say why it is not a gap, for example \"Collider2D.oneWay exists (docs/reference/components/physics.md): use it, "
                              "and file a bug if it does not work\". Pass it as statusReason.");
        if (!cleanReason.empty() && after == "open")
            return make_error("A reason belongs to a closed entry, and " + std::string(id) + " is open.",
                              "Set a closed status (wont-fix, duplicate, rejected) together with the reason.");
        if (!status.empty()) e["status"] = std::string(status);
        if (!status.empty() && after != before) e.erase("suggestedRejection");  // decided: the suggestion is answered
        if (after == "open") {
            // The engine's own rejection is not repeated on an entry a person reopened.
            if (before == "rejected" && e.value("statusBy", std::string()) == "engine") e["claimCheck"] = "dismissed";
            e.erase("statusReason");
            e.erase("statusBy");
        } else if (!cleanReason.empty()) {
            e["statusReason"] = cleanReason;
            e["statusBy"] = by.empty() ? std::string("user") : std::string(by);
        } else if (after != before) {  // another status: the old reason explained the old one
            e.erase("statusReason");
            e.erase("statusBy");
        }
        if (!engineIssue.empty()) e["engineIssue"] = std::string(engineIssue);
        // An entry fixed in the engine records the version and the day (the game that closes it is the game that now uses that version),
        // and an efficiency entry what its waste cost before: ai.retrospective compares the same pattern after the fix against it.
        if (after == "open") {
            for (const char* key : {"fixedIn", "fixedAt", "fixBaseline", "fixCheck"}) e.erase(key);
        } else if (after == "fixed-in-engine") {
            const std::string version = fixed_version_of(e.value("engineIssue", std::string()));
            if (!version.empty()) {
                if (before != "fixed-in-engine" || e.value("fixedIn", std::string()) != version) {
                    e["fixedIn"] = version;
                    e["fixedAt"] = tooling_detail::today_utc();
                    e.erase("fixCheck");
                    if (kind_of(e) == "efficiency") {
                        if (Json base = fix_baseline_of(e); base.is_object()) e["fixBaseline"] = base;
                    }
                }
            }
        } else if (after != before) {
            for (const char* key : {"fixedIn", "fixedAt", "fixBaseline", "fixCheck"}) e.erase(key);
        }
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
    bool efficiency = false;  // a group of efficiency entries (ranked by saving, never mixed with gaps)
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
        std::string project = d.value("project", u8text(stdfs::path(f).parent_path().filename()));
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
            const bool isEfficiency = kind_of(e) == "efficiency";
            for (auto& c : clusters) {
                // Efficiency entries group with efficiency entries that ask for the same kind of fix, and never with gaps.
                if (c.efficiency != isEfficiency) continue;
                if (isEfficiency && c.items.front().entry.value("fixType", std::string()) != e.value("fixType", std::string())) continue;
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
                clusters.push_back({cat, {}, isEfficiency});
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
    std::vector<EfficiencyGroup> efficiencyGroups;
    for (const auto& c : clusters) {
        if (c.efficiency) {
            EfficiencyGroup g;
            g.category = c.category;
            g.fixType = c.items.front().entry.value("fixType", std::string());
            long repOcc = -1;
            int widest = -1;
            for (const auto& it : c.items) {
                const Json& e = it.entry;
                const long o = e.value("occurrences", 1);
                if (o > repOcc) { repOcc = o; g.title = e.value("title", std::string()); }
                if (const std::string sug = e.value("suggestion", std::string()); sug.size() > g.suggestion.size()) g.suggestion = sug;
                if (const int rank = applies_rank(e.value("appliesTo", std::string())); rank > widest) { widest = rank; g.appliesTo = e.value("appliesTo", std::string()); }
                EfficiencyVoice v;
                v.project = it.project;
                v.id = e.value("id", std::string());
                if (e.contains("remote") && e["remote"].is_object()) v.shareId = e["remote"].value("shareId", std::string());
                v.trust = entry_trust(e);
                v.occurrences = static_cast<int>(o);
                v.measured = EfficiencyMeasure::from_json(e.contains("measured") ? e["measured"] : Json());
                v.saving = EfficiencyMeasure::from_json(e.contains("saving") ? e["saving"] : Json());
                v.afterFix = e.value("afterFix", std::string());
                g.voices.push_back(std::move(v));
            }
            efficiencyGroups.push_back(std::move(g));
            continue;
        }
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
                             {"errors", errors}, {"clusters", outClusters}, {"efficiency", rank_efficiency(std::move(efficiencyGroups))}});
    (void)kSeverityOrder;
    return rep;
}

std::string FeedbackReport::markdown() const {
    std::ostringstream o;
    o << "# Engine feedback report\n\n";
    o << json.value("totalEntries", 0) << " entries from " << json["projects"].size() << " project(s), "
      << json["clusters"].size() << " distinct gap(s) (efficiency entries are ranked apart, below). Ranked by the sum over projects of severity weight x trust x "
      << "min(occurrences, 3) (blocker 8, major 4, minor 2, nice-to-have 1; trust 1, or 0.5 for an anonymous "
      << "installation).\n\n";
    if (!json["errors"].empty()) {
        o << "## Problems reading files\n\n";
        for (const auto& e : json["errors"]) o << "- " << e.get<std::string>() << "\n";
        o << "\n";
    }
    if (json["clusters"].empty() && !(json.contains("efficiency") && !json["efficiency"].empty())) o << "_No open feedback entries._\n";
    if (json.contains("efficiency") && json["efficiency"].is_array() && !json["efficiency"].empty()) {
        o << "## Efficiency: what the fixes would save\n\n";
        o << json["efficiency"].size() << " group(s) of efficiency entries (the work took more steps, minutes or tokens than a fix would need), "
          << "ranked by the total saving across installations: each installation counted once with its own entries added, an anonymous one "
          << "at half. `hours` is the larger of the minutes and of the dollars at $50 an hour.\n\n";
        for (const auto& g : json["efficiency"]) {
            const Json& t = g["total"];
            char nums[160];
            std::snprintf(nums, sizeof nums, "%.1f minutes, %llu tokens, $%.2f (%.1f hours)", t.value("minutes", 0.0),
                          static_cast<unsigned long long>(t.value("tokens", 0ULL)), t.value("costUsd", 0.0), t.value("hours", 0.0));
            o << "### E" << g["rank"].get<int>() << ". " << g["title"].get<std::string>() << "\n\n";
            o << "- **Verdict:** " << g["verdict"]["text"].get<std::string>() << "\n";
            o << "- **Fix:** " << g["fixType"].get<std::string>() << " (about " << g["fixCost"].value("hours", 0.0) << " hours of work"
              << (g["fixCost"].contains("usd") ? ", or $" + std::to_string(static_cast<long>(g["fixCost"].value("usd", 0.0))) : std::string())
              << "), applies to " << g["appliesTo"].get<std::string>() << ", category " << g["category"].get<std::string>() << "\n";
            o << "- **Total saving:** " << nums << " from " << g.value("installations", 0L) << " installation(s) ("
              << g.value("verifiedInstallations", 0L) << " verified), " << g.value("reports", 0L) << " report(s)\n";
            if (g.contains("afterFix")) {
                o << "- **Reported again after a fix:** engine ";
                bool firstV = true;
                for (const auto& v : g["afterFix"]) { o << (firstV ? "" : ", ") << v.get<std::string>(); firstV = false; }
                o << ": the pattern still costs\n";
            }
            if (g.contains("suggestion")) o << "- **Suggestion:** " << g["suggestion"].get<std::string>() << "\n";
            o << "- **Entries:**\n";
            for (const auto& e : g["entries"]) {
                o << "  - " << e["project"].get<std::string>() << "/" << e["id"].get<std::string>();
                if (e.contains("shareId")) o << " (" << e["shareId"].get<std::string>() << ")";
                o << ": " << e["saving"].value("minutes", 0.0) << " minutes, " << e["occurrences"].get<int>() << " report(s)\n";
                if (e.contains("rejectReason")) o << "    - reason for `feedback reject`: " << e["rejectReason"].get<std::string>() << "\n";
            }
            o << "\n";
        }
    }
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

std::string feedback_path_for(const std::string& projectDir) { return feedback_file_for_project(projectDir); }

}  // namespace

std::string feedback_file_for_project(const std::string& projectDir) {
    std::string file = kFeedbackFileName;
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("feedbackFile") && pj.value()["feedbackFile"].is_string())
            file = pj.value()["feedbackFile"].get<std::string>();
    }
    return (stdfs::path(projectDir) / file).string();
}

std::string feedback_project_name(const std::string& projectDir) {
    if (auto text = tooling_detail::read_file(stdfs::path(projectDir) / kProjectFileName)) {
        auto pj = parse_json(*text, kProjectFileName);
        if (pj.ok() && pj.value().is_object() && pj.value().contains("name") && pj.value()["name"].is_string())
            return pj.value()["name"].get<std::string>();
    }
    std::error_code ec;
    return u8text(stdfs::weakly_canonical(projectDir, ec).filename());
}

namespace {

std::string project_name_for(const std::string& projectDir) { return feedback_project_name(projectDir); }

Json enum_schema(const std::vector<std::string>& v, const char* desc) {
    return Json::object({{"type", "string"}, {"enum", v}, {"description", desc}});
}

}  // namespace

void register_feedback_commands(CommandRegistry& registry, const std::string& projectDir) {
    register_feedback_share_commands(registry, projectDir);
    register_feedback_check_commands(registry, projectDir);
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
            "are harmless. A gap the engine already fixed (archived, see feedback.archive) and that you report again reopens the archived entry as a possible regression.\n"
            "CHECK BEFORE YOU FILE: models often report as missing something the engine has (a component field, a command, a scripting "
            "member). Search first: docs.search for the thing, docs.components for the fields of the component you mean, or call "
            "feedback.check with your title/missing/suggestion. This command runs the same check and REFUSES a report whose missing "
            "thing exists, naming what exists and the page that documents it. If it exists but does not work as documented, file a BUG "
            "instead: say what you set, what you expected and what happened. A request for an extra option on an existing component "
            "is fine. The examples below are INVENTED to show the shape: do not copy or adapt them.\n"
            "Write 'title' as a short noun phrase (\"No fluid simulation\"), 'missing' as what you needed "
            "and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the "
            "concrete engine change that would remove the workaround.\n"
            "SHARE (optional, strongly recommended): `share` is the same gap written for the ENGINE DEVELOPER, who must never "
            "learn what the game is about. Write it in engine terms only: components, fields, commands and API names that "
            "exist (or that you propose), and NOTHING about the game: no game, character, level, scene, entity, asset or script "
            "names, no file names or paths, no quotes from the game, no story. {title (8-120 characters), missing (20-1500, at "
            "least 4 words), suggestion?, workaround? (the kind of workaround, without project details)}. Good (invented): {\"title\":\"No "
            "fluid simulation\",\"missing\":\"There is no liquid solver, so water cannot flow around bodies and fill a "
            "container.\",\"suggestion\":\"Add a particle-based Fluid2D component.\",\"workaround\":\"A script moves "
            "sprites to fake a water surface.\"}. Bad: \"The knight in Dungeon of Ash cannot jump through scripts/ledge.js "
            "platforms\" (names the game, a character and a file). Check the docs first (docs.search) so the gap is real and "
            "about the engine, then pass reviewed: true. An entry without `share` is never sent. Whether anything is sent is the "
            "USER's choice (mode always, ask or never): the result's `share` says what happened, and no command changes the "
            "mode, so do not try; if it says sharing is not set up, tell the user how to turn it on, once.\n"
            "Example (an invented gap, only to show the fields): {\"category\":\"physics\",\"severity\":\"major\",\"title\":\"No fluid simulation\","
            "\"missing\":\"There is no liquid solver, so water cannot flow around bodies and fill a container.\","
            "\"workaround\":\"scripts/water.js moves sprites to fake a water surface.\","
            "\"workaroundFiles\":[\"scripts/water.js\"],\"suggestion\":\"Add a particle-based Fluid2D component.\","
            "\"share\":{\"title\":\"No fluid simulation\",\"missing\":\"There is no liquid solver, so water cannot flow around "
            "bodies and fill a container.\",\"suggestion\":\"Add a particle-based Fluid2D component.\"},\"reviewed\":true}\n"
            "EFFICIENCY (kind \"efficiency\"): the engine did not lack anything, but the work took many more steps, minutes or tokens than "
            "a doc, an example or a command option could have made it (a system you understood only after forty steps, a doc read five "
            "times, ten calls where one with an extra option would do). File it only when it is MEASURED and worth its fix. Give: "
            "`waste` (what took the time, in engine terms), `evidence` ([{session, fromStep, toStep}]: the span of the transcripts in "
            ".factoria/ai/sessions where it happened; steps count from 1, one model call each; `ai.session_timeline` shows them), "
            "`fixType` (cheapest first: doc, guide, example, commandOption, newCommand, engineChange), `expectedSaving` ({share, why}: the "
            "share of the measured span the fix removes), `appliesTo` (every-game, genre, feature), `suggestion` (the fix itself), and "
            "category and title as for a gap. The ENGINE measures the span (steps, tool calls, minutes, tokens, cost; for Claude Code "
            "and Codex the tokens are estimated from bytes and the cost is unknown) and REFUSES, with the reason, a report with no "
            "evidence or a span that does not exist, a saving under the threshold of its fix type (docs/ENGINE_FEEDBACK.md, "
            "\"Efficiency feedback\": a doc or guide from 10 minutes or 100k tokens per game, a command option or command from 30 minutes "
            "or 500k tokens and every-game or genre, an engine change from 1 hour or $5 and only as a candidate), a fix that is not the "
            "cheapest that works (commandOption, newCommand and engineChange need `whyNotCheaper`), text loaded on every step "
            "(AGENTS.md, the system prompt) that costs more than it saves (`everyStepTokens`), a missing guide for a doc that docs.search "
            "finds with your own words (then it is a findability report: list the words you searched in `searched` and make the fix the "
            "doc's title and keywords), a lesson true only for this game (appliesTo this-game: it is a project fact, not engine "
            "feedback), and model, effort or limit settings (the user's, never filed). Entries of one fix merge and add their numbers. "
            "Example (invented): {\"kind\":\"efficiency\",\"category\":\"scripting\",\"title\":\"Boss fight phases\","
            "\"waste\":\"Making a boss that changes at health thresholds took 40 steps of wiring states and timers by hand.\","
            "\"evidence\":[{\"session\":\"20261014-153012-main\",\"fromStep\":12,\"toStep\":52}],\"fixType\":\"guide\","
            "\"expectedSaving\":{\"share\":0.7,\"why\":\"a guide gives the three calls that took the rest to find\"},"
            "\"appliesTo\":\"genre\",\"suggestion\":\"A boss fight topic guide: phases at health thresholds, attack timers.\"}";
        Json props = Json::object();
        props["category"] = enum_schema(feedback_categories(), "Engine area of the gap.");
        props["severity"] = enum_schema(feedback_severities(),
            "Required for a gap. blocker: could not build the feature at all; major: large/fragile workaround; minor: small workaround; nice-to-have: convenience. An efficiency entry may leave it out (minor).");
        props["title"] = Json::object({{"type", "string"}, {"description", "Short noun phrase naming the gap; reuse wording for the same gap."}});
        props["missing"] = Json::object({{"type", "string"}, {"description", "Required for a gap: what the engine lacked or got wrong, and what you were trying to do. An efficiency entry may leave it out (its `waste` is stored)."}});
        props["workaround"] = Json::object({{"type", "string"}, {"description", "Required for a gap: what you did instead (or 'none: feature dropped'). An efficiency entry may leave it out."}});
        props["workaroundFiles"] = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})},
                                                 {"description", "Project-relative files implementing the workaround."}});
        props["suggestion"] = Json::object({{"type", "string"}, {"description", "How the engine could fix it (field, command, API)."}});
        props["effort"] = enum_schema({"small", "medium", "large"}, "Your estimate of the engine-side effort to fix it.");
        props["share"] = Json::object({{"type", "object"},
            {"description", "The generic copy for the engine developer, in ENGINE TERMS ONLY: nothing about the game (no names, "
                            "story, characters, assets, file names, paths or quotes). {title, missing, suggestion?, workaround?}. "
                            "Without it the entry is never sent."},
            {"properties", Json::object({
                {"title", Json::object({{"type", "string"}, {"description", "8-120 characters: the gap as a noun phrase, e.g. \"No fluid simulation\" (an invented example)."}})},
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
        props["kind"] = enum_schema(feedback_kinds(),
            "gap (default): the engine lacked something or got it wrong. efficiency: the same work could have taken fewer steps, minutes or tokens (see the description).");
        props["waste"] = Json::object({{"type", "string"}, {"description", "kind efficiency: what took the time, in engine terms (nothing about the game)."}});
        props["evidence"] = Json::object({{"type", "array"},
            {"description", "kind efficiency: the spans of the session transcripts (.factoria/ai/sessions) where the waste happened. The engine measures them. Steps count from 1."},
            {"items", Json::object({{"type", "object"},
                {"properties", Json::object({
                    {"session", Json::object({{"type", "string"}, {"description", "The transcript's id: its file name in .factoria/ai/sessions without .jsonl."}})},
                    {"fromStep", Json::object({{"type", "integer"}, {"description", "First step of the span (1-based)."}})},
                    {"toStep", Json::object({{"type", "integer"}, {"description", "Last step of the span, inclusive."}})}})},
                {"required", Json::array({"session", "fromStep", "toStep"})}})}});
        props["fixType"] = enum_schema(efficiency_fix_types(),
            "kind efficiency: the fix, cheapest first. The cheapest one that removes the waste wins; commandOption, newCommand and engineChange need whyNotCheaper.");
        props["expectedSaving"] = Json::object({{"type", "object"},
            {"description", "kind efficiency: how much of the measured span the fix removes."},
            {"properties", Json::object({
                {"share", Json::object({{"type", "number"}, {"description", "0.01 to 1: the share of the measured steps, minutes and tokens that the fix removes (0.5 = half)."}})},
                {"why", Json::object({{"type", "string"}, {"description", "One line on why the fix removes that share."}})}})},
            {"required", Json::array({"share", "why"})}});
        props["appliesTo"] = enum_schema(efficiency_applies_to(),
            "kind efficiency: every-game (any game would hit it), genre (games of one kind), feature (one engine feature), this-game (refused: a project fact).");
        props["whyNotCheaper"] = Json::object({{"type", "string"},
            {"description", "kind efficiency, fixType commandOption, newCommand or engineChange: why a doc section, a topic guide and an example would not have removed the waste."}});
        props["searched"] = Json::object({{"type", "array"}, {"items", Json::object({{"type", "string"}})},
            {"description", "kind efficiency, a findability report: the words you gave docs.search that did not answer with the doc that exists."}});
        props["everyStepTokens"] = Json::object({{"type", "integer"},
            {"description", "kind efficiency: the tokens the fix adds to every step of every run (text in AGENTS.md or the system prompt). It must save more than it adds. Leave out for an on-demand guide."}});
        info.inputSchema = Json::object({{"type", "object"}, {"properties", props},
            {"required", Json::array({"category", "title"})}});
        registry.add(info, [projectDir, &registry](const Json& args) {
            if (const std::string kind = arg_string(args, "kind", false); !kind.empty() && !contains(feedback_kinds(), kind))
                throw CommandError("invalid_argument", "Invalid kind '" + kind + "'. " + did_you_mean(kind, feedback_kinds()),
                                   "gap (the engine lacked something or got it wrong) or efficiency (the same work in fewer steps, minutes or tokens).");
            if (arg_string(args, "kind", false) == "efficiency") {
                FeedbackInput base;
                base.category = arg_string(args, "category", true);
                base.title = arg_string(args, "title", true);
                base.suggestion = arg_string(args, "suggestion", false);
                base.severity = arg_string(args, "severity", false);
                base.missing = arg_string(args, "missing", false);
                base.workaround = arg_string(args, "workaround", false);
                base.effort = arg_string(args, "effort", false);
                base.reporter = args.contains("reporter") && args["reporter"].is_object() ? args["reporter"] : Json::object({{"kind", "ai"}});
                if (args.contains("share") && !args["share"].is_null()) base.share = args["share"];
                if (args.contains("reviewed") && args["reviewed"].is_boolean()) base.reviewed = args["reviewed"].get<bool>();
                const std::string path = feedback_path_for(projectDir);
                EfficiencyFiling f = file_efficiency_feedback(projectDir, path, base, args, project_name_for(projectDir));
                if (f.refusal) throw CommandError(f.refusal->code, f.refusal->message, f.refusal->hint);
                const FeedbackAddResult& r = f.added;
                Json out = Json::object();
                out["id"] = r.id;
                out["kind"] = "efficiency";
                out["merged"] = r.merged;
                out["alreadyCounted"] = r.alreadyCounted;
                out["occurrences"] = r.occurrences;
                out["file"] = u8text(stdfs::path(path).filename());
                out["measured"] = f.verdict.measured.to_json();
                out["saving"] = f.verdict.saving.to_json();
                if (f.verdict.measured.estimated)
                    out["note"] = "The tokens are estimated from bytes and the cost is not known: a CLI agent's transcript has no usage numbers.";
                if (!f.verdict.existingDoc.empty()) out["existingDoc"] = f.verdict.existingDoc;
                if (!r.shareProblem.empty()) {
                    out["share"] = Json::object({{"status", "invalid"},
                        {"message", "`share` was not stored: " + r.shareProblem + ". The entry is recorded without it and will not be shared."}});
                } else if (!r.alreadyCounted) {
                    // The share text of an efficiency entry is derived from the entry itself (its waste, cleaned like a gap), so it is
                    // offered for sharing whether or not the caller wrote one; a this-game entry has none and says nothing about sharing.
                    const bool shareGiven = args.contains("share") && !args["share"].is_null();
                    Json summary = share_report_summary(share_env(), path, projectDir, r.id, &registry, shareGiven);
                    if (!summary.is_null()) out["share"] = std::move(summary);
                }
                char numbers[160];
                std::snprintf(numbers, sizeof numbers, "about %.1f minutes and %llu tokens", f.verdict.saving.minutes,
                              static_cast<unsigned long long>(f.verdict.saving.tokens));
                out["message"] = r.alreadyCounted
                                     ? "Already counted: " + r.id + " holds this evidence, so nothing was added. Thank you."
                                 : r.merged ? "Merged into " + r.id + " (now " + std::to_string(r.occurrences) + " reports): the measured numbers were added. Thank you."
                                            : "Recorded " + r.id + ": the fix would save " + numbers + " per game, measured from the transcript. Thank you.";
                if (f.verdict.candidateOnly)
                    out["message"] = out["message"].get<std::string>() + " An engine change is only a candidate: it goes on the roadmap when the reports that ask for it add up to $" +
                                     std::to_string(int(kEfficiencyRoadmapUsd)) + " or " + std::to_string(int(kEfficiencyRoadmapHours)) + " hours across games.";
                return out;
            }
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
            // The engine already has what the report calls missing: refuse, and say what exists and where it is documented.
            ClaimInput claimIn{in.title, in.missing, in.suggestion};
            if (in.share.is_object()) {
                claimIn.missing += ". " + in.share.value("missing", std::string());
                claimIn.suggestion += ". " + in.share.value("suggestion", std::string());
            }
            const ClaimResult claim = check_feedback_claim(claimIn, &registry, 3);
            if (claim.refused()) throw CommandError("already_exists", claim.message(), claim.hint());
            // A read-modify-write of a file that the editor, the CLI and an agent's retrospective may write at once: under the lock
            // that file_efficiency_feedback takes too, and released before the sharing summary (which takes it again).
            Result<FeedbackAddResult> r = make_error("not filed");
            {
                FeedbackFileLock lock(share_env(), path);
                if (!lock.held())
                    throw CommandError("failed", lock.error(), "Run the command again in a moment; the other program is only writing a small file.");
                r = add_feedback_entry_to_file(path, in, project_name_for(projectDir));
            }
            if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
            Json out = Json::object();
            out["id"] = r->id;
            out["merged"] = r->merged;
            out["occurrences"] = r->occurrences;
            out["file"] = u8text(stdfs::path(path).filename());
            out["reopened"] = r->reopened;
            if (!claim.related.empty()) out["relatedDocs"] = claim.related;
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
            if (!claim.related.empty())
                out["message"] = out["message"].get<std::string>() + " Related documentation (relatedDocs): if it already covers the gap, "
                                 "set the entry aside with feedback.update status rejected and a reason.";
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
                                         {"kind", enum_schema(feedback_kinds(), "Only this kind: gap or efficiency.")},
                                         {"includeArchive", Json::object({{"type", "boolean"},
                                              {"description", "Also list the archived (closed) entries, marked archived: true."}})}})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            if (!stdfs::exists(path))
                return Json::object({{"entries", Json::array()}, {"count", 0}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            auto doc = load_feedback(path);
            if (!doc.ok()) throw CommandError("failed", doc.error().message, doc.error().hint);
            FeedbackFilter f{arg_string(args, "status", false), arg_string(args, "category", false), arg_string(args, "severity", false)};
            const std::string kind = arg_string(args, "kind", false);
            if (!kind.empty() && !contains(feedback_kinds(), kind))
                throw CommandError("invalid_argument", "Invalid kind '" + kind + "'. " + did_you_mean(kind, feedback_kinds()), "gap or efficiency.");
            auto of_kind = [&kind](Json list) {
                if (kind.empty()) return list;
                Json kept = Json::array();
                for (auto& e : list)
                    if (kind_of(e) == kind) kept.push_back(std::move(e));
                return kept;
            };
            Json entries = of_kind(list_feedback(doc.value(), f));
            const Json archived = list_archived_feedback(path);
            if (args.value("includeArchive", false)) {
                for (auto e : of_kind(list_archived_feedback(path, f))) {
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
        info.summary = "Change the status of a feedback entry (with a reason when it is rejected) or link it to an engine issue.";
        info.description = "Engine developers use this when a gap is fixed (status fixed-in-engine), will not be done (wont-fix) or "
                           "duplicated; the entry moves to the archive on the next feedback.archive (the editor runs it when it opens "
                           "the project). Status `rejected` means the entry claims a gap the engine does not have (the thing exists, or "
                           "it is not about the engine): it REQUIRES `statusReason`, a sentence the person reads in the editor (what "
                           "exists and where it is documented). A reason may also be given with wont-fix and duplicate. An archived "
                           "entry is found too, and set to open it moves back to the file (its reason is removed). Example: "
                           "{\"id\":\"FB-0001\",\"status\":\"fixed-in-engine\",\"engineIssue\":\"#42\"} or "
                           "{\"id\":\"FB-0002\",\"status\":\"rejected\",\"statusReason\":\"The field exists: see the Collider2D page of the reference.\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"id", Json::object({{"type", "string"}, {"description", "Entry id, e.g. FB-0001."}})},
                                         {"status", enum_schema(feedback_statuses(), "New status.")},
                                         {"statusReason", Json::object({{"type", "string"}, {"description",
                                              "Why (at most 500 characters, plain text). Required with status rejected; shown to the person in the editor."}})},
                                         {"engineIssue", Json::object({{"type", "string"}, {"description", "Issue/PR link or id."}})}})},
            {"required", Json::array({"id"})}});
        registry.add(info, [projectDir](const Json& args) {
            std::string path = feedback_path_for(projectDir);
            std::string status = arg_string(args, "status", false), issue = arg_string(args, "engineIssue", false);
            const std::string reason = arg_string(args, "statusReason", false);
            if (status.empty() && issue.empty() && reason.empty())
                throw CommandError("invalid_argument", "Nothing to update.", "Pass status, statusReason and/or engineIssue.");
            auto r = update_feedback_file(path, arg_string(args, "id", true), status, issue, {}, reason, "user");
            if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
            return r.value();
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.delete";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Delete a closed feedback entry (rejected, wont-fix, duplicate, fixed) from the file and its archive.";
        info.description =
            "Removes entry `id` from ENGINE_FEEDBACK.json or ENGINE_FEEDBACK.archive.json for good, and takes it out of the sharing "
            "outbox. Only a closed entry can go (any status but open), or an open one the engine developer refused (its `shared` says "
            "rejected or declined): an open entry is a question for the engine developers, so close it first with feedback.update. Its "
            "id is not given again. What was already sent to the engine developer stays with them. The editor's Feedback panel offers "
            "this with a confirmation. Example: {\"id\":\"FB-0004\"}";
        info.inputSchema = Json::object({{"type", "object"},
            {"properties", Json::object({{"id", Json::object({{"type", "string"}, {"description", "Entry id, e.g. FB-0004."}})}})},
            {"required", Json::array({"id"})}});
        registry.add(info, [projectDir](const Json& args) {
            const std::string path = feedback_path_for(projectDir);
            const std::string id = arg_string(args, "id", true);
            if (!stdfs::exists(path)) throw CommandError("not_found", "No ENGINE_FEEDBACK.json yet.", "Nothing to delete.");
            // The outbox is cleaned first, and the entry stays when that fails: a deleted entry must never stay sendable.
            auto r = delete_feedback_file(path, id, [&] { return share_discard(share_env(), path, {id}); });
            if (!r.ok()) throw CommandError("invalid_argument", r.error().message, r.error().hint);
            return Json::object({{"deleted", id}, {"title", r->value("title", std::string())},
                                 {"status", r->value("status", std::string("open"))}});
        });
    }
    {
        CommandInfo info;
        info.name = "feedback.archive";
        info.category = "feedback";
        info.readOnly = false;
        info.summary = "Move the closed feedback entries (fixed-in-engine, wont-fix, duplicate, rejected) to the archive file.";
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
                                 {"file", u8text(stdfs::path(path).filename())},
                                 {"archiveFile", u8text(stdfs::path(feedback_archive_path(path)).filename())}});
        });
    }
}

}  // namespace fa
