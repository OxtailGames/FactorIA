#include "feedback_review.h"

#include <algorithm>
#include <cctype>
#include <set>
#include <sstream>

#include "fa/ai/text_model.h"
#include "fa/core/strings.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/feedback_share.h"
#include "util.h"

namespace fa::ai {

using namespace util;

namespace {

const char* kSystem =
    "You check one engine-feedback entry before it is shared with the developers of the FactorIA game engine. The entry was "
    "written while building a game; its `share` text is the same gap written for the engine developer, who must never learn what "
    "the game is about.\n"
    "Decide three things, using ONLY the engine reference you are given (command list and documentation excerpts):\n"
    "1. real: is the gap real? It is not real when the engine reference shows the thing exists or works as the entry wants.\n"
    "2. aboutEngine: is it about the engine (a component, field, command, API, tool or document of FactorIA)? It is not when it "
    "is a bug or wish of the game itself, of its content or of a third-party tool.\n"
    "3. notPossibleYet: is it really impossible today? It is possible already when an existing command, component field or API "
    "does what the entry asks for; name it in `use`.\n"
    "Then check the text: `share` must use engine terms only (names of components, fields, commands and APIs that exist or that "
    "the entry proposes) and nothing about the game: no game, character, level, scene, entity, asset or script names, no file names "
    "or paths, no quotes from the game, no story. title 8-120 characters, missing 20-1500 and at least 4 words, suggestion and "
    "workaround at most 1500. If it needs a rewrite to follow that, give the rewritten text in `share`; if it is fine, leave `share` "
    "null. Never invent engine names.\n"
    "Answer with ONE JSON object and nothing else:\n"
    "{\"real\":{\"ok\":true,\"why\":\"\"},\"aboutEngine\":{\"ok\":true,\"why\":\"\"},\"notPossibleYet\":{\"ok\":true,\"why\":\"\",\"use\":\"\"},"
    "\"share\":null,\"fix\":\"\"}\n"
    "`why` is one sentence, filled in when ok is false (or when it helps). `share` is {\"title\":..., \"missing\":..., "
    "\"suggestion\":..., \"workaround\":...} or null. `fix` says what the author should change when a check failed (empty on a pass).";

std::string field_of(const Json& share, const char* key) { return share.is_object() ? str(share, key) : std::string(); }

std::set<std::string> words_of(const std::string& text) {
    std::set<std::string> out;
    std::string cur;
    auto flush = [&] {
        if (cur.size() >= 4) out.insert(cur);
        cur.clear();
    };
    for (unsigned char c : text) {
        if (std::isalnum(c)) cur.push_back(static_cast<char>(std::tolower(c)));
        else flush();
    }
    flush();
    return out;
}

// The engine reference the model works from: every command name by area, the commands whose name or summary share words with
// the entry (with their summaries), and the documentation passages that match the entry.
std::string engine_reference(CommandRegistry& registry, const Json& entry, const Json& share) {
    const std::string text = field_of(share, "title") + " " + field_of(share, "missing") + " " + field_of(share, "suggestion") + " " +
                             str(entry, "title") + " " + str(entry, "missing") + " " + str(entry, "suggestion");
    const std::set<std::string> words = words_of(text);

    std::ostringstream out;
    std::map<std::string, std::vector<std::string>> byArea;
    std::vector<std::pair<int, const CommandInfo*>> scored;
    for (const CommandInfo* c : registry.list()) {
        if (c->name.rfind("ai.", 0) == 0 || c->name.rfind("feedback.", 0) == 0) continue;
        const std::size_t dot = c->name.find('.');
        byArea[dot == std::string::npos ? c->name : c->name.substr(0, dot)].push_back(dot == std::string::npos ? c->name : c->name.substr(dot + 1));
        int score = 0;
        for (const std::string& w : words_of(c->name + " " + c->summary))
            if (words.count(w)) ++score;
        if (score > 0) scored.emplace_back(score, c);
    }
    out << "## Commands of this engine, by area (name after the dot)\n";
    for (const auto& [area, names] : byArea) {
        out << area << ":";
        for (const std::string& n : names) out << " " << n;
        out << "\n";
    }
    std::stable_sort(scored.begin(), scored.end(), [](const auto& a, const auto& b) { return a.first > b.first; });
    if (!scored.empty()) out << "\n## Commands that look related\n";
    for (std::size_t i = 0; i < scored.size() && i < 12; ++i)
        out << "- " << scored[i].second->name << ": " << scored[i].second->summary << "\n";

    std::string query = field_of(share, "title");
    if (query.empty()) query = str(entry, "title");
    std::set<std::string> seen;
    std::ostringstream docs;
    for (const std::string& q : {query, field_of(share, "missing").substr(0, 160)}) {
        if (trim(q).empty()) continue;
        for (const DocHit& h : search_docs(q, 4)) {
            const std::string key = h.doc + ":" + std::to_string(h.line);
            if (!seen.insert(key).second) continue;
            docs << "- docs/" << h.path << " (" << h.heading << "): " << h.snippet << "\n";
        }
    }
    if (!docs.str().empty()) out << "\n## Documentation excerpts that match\n" << docs.str();
    return out.str();
}

std::string json_object_in(const std::string& text) {
    const std::size_t a = text.find('{'), b = text.rfind('}');
    if (a == std::string::npos || b == std::string::npos || b < a) return {};
    return text.substr(a, b - a + 1);
}

Json check_json(bool ok, const std::string& why) { return Json::object({{"ok", ok}, {"why", why}}); }

}  // namespace

Json review_feedback_entry(CommandRegistry& registry, const AiConfig& cfg, const AiCommandOptions& options,
                           const std::string& projectDir, const std::string& id) {
    const std::string path = feedback_file_for_project(projectDir);
    auto loaded = load_feedback(path);
    if (!loaded.ok()) throw CommandError("not_found", loaded.error().message, loaded.error().hint);
    const Json* entry = nullptr;
    std::vector<std::string> ids;
    for (const auto& e : (*loaded)["entries"]) {
        ids.push_back(str(e, "id"));
        if (ids.back() == id) entry = &e;
    }
    if (!entry)
        throw CommandError("not_found", "No feedback entry '" + id + "' in " + path + ". " + did_you_mean(id, ids),
                           "List the entries with feedback.list.");
    const Json* shareJson = child(*entry, "share");
    if (!shareJson || !shareJson->is_object())
        throw CommandError("no_share", "Entry " + id + " has no `share` text, so there is nothing to review.",
                           "Write it first: feedback.report with `share` (engine terms only), or the Share field of the Engine "
                           "Feedback panel. An entry without `share` is never sent.");
    const Json share = *shareJson;

    // The deterministic part: what the sanitizer would send. A text it refuses is a failed review whatever the model says.
    const EngineNames engine = collect_engine_names(&registry);
    const ProjectNames project = collect_project_names(projectDir);
    const SanitizedShare current = sanitize_share(share, engine, project);

    TextModelOptions mo;
    mo.role = kRoleFast;
    mo.providerFactory = options.providerFactory;
    mo.runtime = options.runtime;
    TextModelInfo modelInfo;
    auto model = make_text_model(cfg, mo, &modelInfo);
    if (!model.ok()) throw CommandError("no_model", model.error().message, model.error().hint);

    std::ostringstream user;
    user << "Engine version: " << share_env().version() << "\n\n" << engine_reference(registry, *entry, share) << "\n";
    user << "## The entry\ncategory: " << str(*entry, "category") << "\nseverity: " << str(*entry, "severity") << "\n";
    user << "The author's own words (about the game; do not copy names from them): title: " << str(*entry, "title")
         << "; missing: " << str(*entry, "missing") << "; suggestion: " << str(*entry, "suggestion") << "\n\n";
    user << "## The share text to check\n" << dump_pretty(share) << "\n";
    if (!current.ok) user << "\nThe automatic sanitizer refuses this text: " << current.reason() << "\n";
    else if (!current.removed.empty()) {
        user << "\nThe automatic sanitizer would cut these parts out (they look like names, paths or quotes from the game):";
        for (const Removal& r : current.removed) user << " [" << r.field << ": " << r.text << "]";
        user << "\nRewrite `share` without them if the text still says what is missing.\n";
    }
    auto answer = (*model)(kSystem, user.str());
    if (!answer.ok())
        throw CommandError("review_failed", "The " + modelInfo.role + " model did not answer: " + answer.error().message,
                           answer.error().hint.empty() ? "Check `factoria ai providers` for the role '" + modelInfo.role + "'." : answer.error().hint);
    const Json reply = parse(json_object_in(*answer));
    if (!reply.is_object())
        throw CommandError("review_failed", "The " + modelInfo.role + " model did not answer with the JSON object the review needs.",
                           "Run ai.review_feedback again, or pick a stronger model for the role (docs/AI_PROVIDERS.md).");

    auto verdict = [&](const char* key) {
        const Json* c = child(reply, key);
        const bool ok = c && c->is_object() ? flag(*c, "ok", false) : false;
        const std::string why = c && c->is_object() ? str(*c, "why") : std::string("the model gave no answer for this check");
        return std::make_pair(ok, why);
    };
    const auto [realOk, realWhy] = verdict("real");
    const auto [engineOk, engineWhy] = verdict("aboutEngine");
    auto [possibleOk, possibleWhy] = verdict("notPossibleYet");
    if (const Json* c = child(reply, "notPossibleYet"); !possibleOk && c && c->is_object() && !str(*c, "use").empty())
        possibleWhy += (possibleWhy.empty() ? "" : " ") + std::string("It can be done with ") + str(*c, "use") + ".";

    // A rewrite counts only when it passes the limits and the sanitizer; otherwise the original text stands (and is judged).
    Json finalShare = share;
    bool rewritten = false;
    std::string rewriteProblem;
    SanitizedShare finalSan = current;
    if (const Json* rw = child(reply, "share"); rw && rw->is_object() && *rw != share) {
        FeedbackShareEdit probe;
        probe.share = *rw;
        const SanitizedShare san = sanitize_share(*rw, engine, project);
        if (!san.ok) rewriteProblem = "The rewrite the model proposed is refused by the sanitizer: " + san.reason();
        else if (field_of(*rw, "title").size() < static_cast<std::size_t>(kShareTitleMin) ||
                 field_of(*rw, "title").size() > static_cast<std::size_t>(kShareTitleMax))
            rewriteProblem = "The rewrite the model proposed has a title outside " + std::to_string(kShareTitleMin) + "-" + std::to_string(kShareTitleMax) + " characters.";
        else {
            finalShare = *rw;
            finalSan = san;
            rewritten = true;
        }
    }

    Json reasons = Json::array();
    if (!realOk) reasons.push_back("Not a real gap: " + realWhy);
    if (!engineOk) reasons.push_back("Not about the engine: " + engineWhy);
    if (!possibleOk) reasons.push_back("Already possible: " + possibleWhy);
    if (!finalSan.ok) reasons.push_back("The sanitizer would not send this text: " + finalSan.reason());
    if (!rewriteProblem.empty()) reasons.push_back(rewriteProblem);
    const bool pass = realOk && engineOk && possibleOk && finalSan.ok;

    Json out = Json::object({{"id", id},
                             {"pass", pass},
                             {"role", modelInfo.role},
                             {"checks", Json::object({{"real", check_json(realOk, realWhy)},
                                                      {"aboutEngine", check_json(engineOk, engineWhy)},
                                                      {"notPossibleYet", check_json(possibleOk, possibleWhy)},
                                                      {"sanitizer", check_json(finalSan.ok, finalSan.reason())}})},
                             {"reasons", reasons},
                             {"rewritten", false},
                             {"reviewed", false},
                             {"share", share}});
    if (!pass) {
        std::string fix = str(reply, "fix");
        if (fix.empty())
            fix = !finalSan.ok ? "Rewrite the share text in engine terms only (component, field and command names), without names, paths or quotes from the game."
                  : !possibleOk ? "Use what the engine already has; report again only if it does not do what you need."
                                : "Do not share this entry: remove its `share` (the panel's Not shared, or feedback.report without it).";
        out["fix"] = fix;
        out["message"] = "The share text of " + id + " did not pass; it was not changed and stays unreviewed.";
        return out;
    }

    // Pass: store the rewrite (if any) and mark the entry reviewed. The mode is not touched and nothing is sent.
    FeedbackShareEdit edit;
    if (rewritten) edit.share = finalShare;
    edit.reviewed = true;
    auto saved = set_feedback_share_file(path, id, edit);
    if (!saved.ok()) throw CommandError("save_failed", saved.error().message, saved.error().hint);
    out["rewritten"] = rewritten;
    out["reviewed"] = true;
    out["share"] = finalShare;
    out["message"] = rewritten ? "Passed. The share text was rewritten in engine terms and the entry is marked reviewed."
                               : "Passed. The share text is fine as it is and the entry is marked reviewed.";
    out["note"] = "Nothing was sent. Whether and when entries leave this machine depends on the sharing mode, which only a person sets.";
    return out;
}

}  // namespace fa::ai
