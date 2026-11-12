// The check before filing (fa/tooling/feedback_check.h): does the engine already have what a report calls missing?
#include "fa/tooling/feedback_check.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <set>

#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/scene/components.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/feedback.h"
#include "util.h"

namespace fa {

namespace {

// ------------------------------------------------------------------------------------------------------------------ words

bool is_word_char(unsigned char c) { return (c < 0x80 && std::isalnum(c)) || c == '_'; }

std::string norm(std::string_view s) {
    std::string out;
    for (unsigned char c : s)
        if (c < 0x80 && std::isalnum(c)) out += char(std::tolower(c));
    return out;
}

std::string lower(std::string_view s) {
    std::string out(s);
    for (char& c : out) c = char(std::tolower(static_cast<unsigned char>(c)));
    return out;
}

struct Word {
    std::string raw;   // as written ("Collider2D.oneWay")
    std::string norm;  // lower case letters and digits only ("collider2doneway")
    bool dotted = false;
    bool clauseStart = false;  // after a full stop, comma, bracket...: a claim lead does not reach back over it
};

std::vector<Word> words_of(std::string_view text) {
    std::vector<Word> out;
    bool clause = true;
    const std::size_t n = text.size();
    std::size_t i = 0;
    while (i < n) {
        const unsigned char c = static_cast<unsigned char>(text[i]);
        if (!is_word_char(c)) {
            if (c == '.' || c == ',' || c == ';' || c == ':' || c == '!' || c == '?' || c == '(' || c == ')' || c == '[' ||
                c == ']' || c == '{' || c == '}' || c == '\n' || c == '\r')
                clause = true;
            ++i;
            continue;
        }
        std::size_t j = i;
        bool dotted = false;
        while (j < n) {
            const unsigned char d = static_cast<unsigned char>(text[j]);
            if (is_word_char(d)) {
                ++j;
            } else if (d == '.' && j + 1 < n && is_word_char(static_cast<unsigned char>(text[j + 1]))) {
                dotted = true;
                ++j;
            } else {
                break;
            }
        }
        Word w;
        w.raw = std::string(text.substr(i, j - i));
        w.norm = norm(w.raw);
        w.dotted = dotted;
        w.clauseStart = clause;
        clause = false;
        out.push_back(std::move(w));
        i = j;
    }
    return out;
}

bool in_list(const char* const* list, std::size_t n, const std::string& s) {
    for (std::size_t i = 0; i < n; ++i)
        if (s == list[i]) return true;
    return false;
}
#define IN_LIST(arr, s) in_list(arr, sizeof(arr) / sizeof(arr[0]), s)

// "no X", "missing X", "add X", "does not have X", ...: the words before a name that claim it is not there.
bool is_lead(const std::string& w) {
    static const char* const leads[] = {"no",      "missing", "lacks",    "lack",    "lacking",  "without", "add",
                                        "adding",  "introduce", "need",   "needs",   "needed",   "want",    "wants",
                                        "propose", "nonexistent", "absent", "wish",  "request",  "implement", "not",
                                        "expose",  "provide", "provides"};
    return IN_LIST(leads, w);
}

// Words that may stand between the lead and the name: "no (built-in) (way to) (set a) (new) ...".
bool is_filler(const std::string& w) {
    static const char* const fillers[] = {"a",      "an",      "the",     "new",      "extra",    "more",     "any",     "some",
                                          "per",    "own",     "proper",  "builtin",  "built",    "in",       "native",  "real",
                                          "true",   "dedicated", "first", "class",    "option",   "options",  "field",   "fields",
                                          "property", "properties", "flag", "setting", "settings", "parameter", "param",   "support",
                                          "supports", "supported", "have", "has",     "had",      "to",       "for",     "of",
                                          "on",     "way",     "ability", "feature",  "features", "bool",     "boolean", "api",
                                          "engine", "do",      "does",    "any",      "kind",     "sort",     "type",    "types",
                                          "good",   "nice",    "simple",  "easy",     "direct",   "official"};
    return IN_LIST(fillers, w);
}

// What may follow a component name in "No Tilemap component" without the claim being about something else.
bool is_generic_after(const std::string& w) {
    static const char* const generic[] = {"component", "components", "support", "supported", "system", "feature", "type", "node",
                                          "class",     "builtin",    "built",   "in",        "for",    "the",     "a",    "an",
                                          "engine",    "2d",         "3d",      "entity",    "available", "implemented", "option",
                                          "options",   "capability", "exist",   "exists",    "is",     "are",     "yet",  "at",
                                          "all",       "to",         "be",      "found",     "present"};
    return IN_LIST(generic, w);
}

// "X does not exist", "X is missing", right after the name.
bool existential_at(const std::vector<std::string>& rest, std::size_t p, std::size_t& used) {
    static const char* const phrases[] = {"doesnotexist", "doesntexist", "ismissing",  "isabsent",    "isnotavailable",
                                          "isntavailable", "notexist",   "isnotsupported", "isntsupported", "missing",
                                          "isnotdefined", "isnotexposed", "areabsent",    "aremissing",   "isnotthere",
                                          "doesnothave",  "doesnthave"};
    std::string joined;
    for (std::size_t k = 0; k < 4 && p + k < rest.size(); ++k) {
        joined += rest[p + k];
        for (const char* ph : phrases)
            if (joined == ph) {
                used = k + 1;
                return true;
            }
    }
    return false;
}

bool postfix_claim(const std::vector<Word>& w, std::size_t end) {
    std::vector<std::string> rest;
    for (std::size_t k = end; k < w.size() && rest.size() < 8; ++k) {
        if (k > end && w[k].clauseStart) break;
        rest.push_back(w[k].norm);
    }
    for (std::size_t p = 0; p < rest.size(); ++p) {
        if (is_generic_after(rest[p]) && p + 1 < rest.size()) continue;
        std::size_t used = 0;
        return existential_at(rest, p, used);
    }
    return false;
}

// The words after a component name up to the end of the clause are generic ("component", "support", "is missing").
bool remainder_generic(const std::vector<Word>& w, std::size_t end) {
    std::vector<std::string> rest;
    for (std::size_t k = end; k < w.size(); ++k) {
        if (w[k].clauseStart) break;
        rest.push_back(w[k].norm);
    }
    for (std::size_t p = 0; p < rest.size();) {
        std::size_t used = 0;
        if (existential_at(rest, p, used)) {
            p += used;
        } else if (is_generic_after(rest[p])) {
            ++p;
        } else {
            return false;
        }
    }
    return true;
}

bool lead_before(const std::vector<Word>& w, std::size_t at) {
    if (at == 0 || w[at].clauseStart) return false;
    std::size_t steps = 0;
    for (std::size_t k = at; k > 0 && steps < 7; --k, ++steps) {
        const Word& prev = w[k - 1];
        if (is_lead(prev.norm)) return true;
        if (!is_filler(prev.norm)) return false;
        if (prev.clauseStart) return false;
    }
    return false;
}

// The report says the thing exists but misbehaves: that is a bug report, not a request.
bool says_it_misbehaves(const std::string& lowerText) {
    static const char* const bugWords[] = {"ignored",    "no effect",   "not work",   "does not respect", "doesn't respect", "not respected",
                                           "not honor",  "not honour",  "broken",     " bug",             "crash",           "fails",
                                           "failing",    "wrong",       "incorrect",  "unexpected",       "even though",     "although",
                                           "even with",  "even when",   "does nothing", "nothing happens", "regression",    "i set",
                                           "i tried",    "when set",    "when i ",    "still ",           "stops working",   "not applied",
                                           "has no visible", "silently"};
    for (const char* b : bugWords)
        if (lowerText.find(b) != std::string::npos) return true;
    return false;
}

// ---------------------------------------------------------------------------------------------------------------- catalog

struct Member {
    std::string kind;    // field | script
    std::string owner;   // Collider2D
    std::string member;  // oneWay
    std::string doc;
};

struct Catalog {
    std::map<std::string, std::string> componentByNorm;                     // "collider2d" -> "Collider2D"
    std::map<std::string, std::string> componentDoc;                        // name -> doc
    std::map<std::string, std::set<std::string>> componentByStem;           // "collider" -> {"Collider2D"}
    std::map<std::string, std::vector<Member>> memberByNorm;                // "oneway" -> members
    std::map<std::string, Member> dotted;                                   // "collider2d.oneway" -> member
    std::map<std::string, std::pair<std::string, std::string>> commands;    // lower name -> {name, summary}
};

void add_member(Catalog& c, const std::string& kind, const std::string& owner, const std::string& member, const std::string& doc) {
    if (owner.empty() || member.empty() || member.find_first_of("[] :") != std::string::npos) return;
    const std::string key = lower(owner) + "." + lower(member);
    if (c.dotted.count(key)) {
        if (c.dotted[key].doc.empty() && !doc.empty()) {
            c.dotted[key].doc = doc;
            for (Member& m : c.memberByNorm[norm(member)])
                if (m.owner == owner && m.member == member) m.doc = doc;
        }
        return;
    }
    Member m{kind, owner, member, doc};
    c.dotted[key] = m;
    c.memberByNorm[norm(member)].push_back(m);
}

std::string strip_dimension(const std::string& n) {
    if (n.size() > 2 && (n.compare(n.size() - 2, 2, "2d") == 0 || n.compare(n.size() - 2, 2, "3d") == 0)) return n.substr(0, n.size() - 2);
    return n;
}

void add_component(Catalog& c, const std::string& name, const std::string& doc) {
    if (name.empty()) return;
    const std::string n = norm(name);
    if (!c.componentByNorm.count(n)) c.componentByNorm[n] = name;
    if (!doc.empty()) c.componentDoc[name] = doc;
    const std::string stem = strip_dimension(n);
    if (stem.size() >= 5) c.componentByStem[stem].insert(name);
}

Catalog build_catalog(const CommandRegistry* registry) {
    Catalog c;
    ensure_builtin_components();
    for (const TypeInfo* t : TypeRegistry::global().all()) {
        add_component(c, t->name, t->doc);
        for (const FieldInfo& f : t->fields) add_member(c, "field", t->name, f.name, f.doc);
    }
    if (registry)
        for (const CommandInfo* ci : registry->list()) c.commands[lower(ci->name)] = {ci->name, ci->summary};
    if (auto text = bundled_read(kApiSincePath)) {
        auto parsed = parse_json(*text, kApiSincePath);
        if (parsed.ok() && parsed->is_object()) {
            for (auto section = parsed->begin(); section != parsed->end(); ++section) {
                if (!section->is_object()) continue;
                const std::string kind = section.key();
                for (auto it = section->begin(); it != section->end(); ++it) {
                    const std::string key = it.key();
                    if (key.find(':') != std::string::npos) continue;  // test-only names
                    if (kind == "commands") {
                        if (!c.commands.count(lower(key))) c.commands[lower(key)] = {key, ""};
                    } else if (kind == "components") {
                        const std::size_t dot = key.find('.');
                        if (dot == std::string::npos) add_component(c, key, "");
                        else add_member(c, "field", key.substr(0, dot), key.substr(dot + 1), "");
                    } else if (kind == "script") {
                        const std::size_t dot = key.find('.');
                        if (dot != std::string::npos && key.find('.', dot + 1) == std::string::npos)
                            add_member(c, "script", key.substr(0, dot), key.substr(dot + 1), "");
                    }
                }
            }
        }
    }
    return c;
}

bool camel_case(const std::string& member) {
    for (std::size_t i = 1; i < member.size(); ++i)
        if (std::isupper(static_cast<unsigned char>(member[i])) && std::islower(static_cast<unsigned char>(member[i - 1]))) return true;
    return member.find('_') != std::string::npos;
}

// ---------------------------------------------------------------------------------------------------------------- the check

struct FieldText {
    const char* where;
    std::string text;
    std::vector<Word> words;
};

std::string singular(const std::string& n) {
    if (n.size() > 5 && n.back() == 's' && n[n.size() - 2] != 's') return n.substr(0, n.size() - 1);
    return n;
}

std::set<std::string> mentioned_components(const Catalog& c, const std::vector<FieldText>& fields) {
    std::set<std::string> out;
    for (const FieldText& f : fields)
        for (const Word& w : f.words) {
            std::string n = w.norm;
            if (w.dotted) {
                const std::size_t dot = w.raw.find('.');
                n = norm(w.raw.substr(0, dot));
            }
            for (const std::string& candidate : {n, singular(n)}) {
                if (auto it = c.componentByNorm.find(candidate); it != c.componentByNorm.end()) out.insert(it->second);
                if (auto it = c.componentByStem.find(candidate); it != c.componentByStem.end())
                    out.insert(it->second.begin(), it->second.end());
            }
        }
    return out;
}

void add_match(ClaimResult& r, ClaimMatch m) {
    for (const ClaimMatch& e : r.matches)
        if (e.name == m.name) return;
    r.matches.push_back(std::move(m));
}

bool path_is_about_feedback(const std::string& path) {
    static const char* const skip[] = {"docs/ENGINE_FEEDBACK.md", "docs/EXTENDING.md", "docs/ARCHITECTURE.md", "docs/design/",
                                       "docs/ROADMAP.md",         "CHANGELOG.md",      "docs/CLI.md"};
    for (const char* s : skip)
        if (path.rfind(s, 0) == 0) return true;
    return false;
}

// Where the engine documents `name` ("Collider2D.oneWay", "Tilemap", "scene.duplicate"): the section named like the component (or the
// command) when there is one, else the best hit that is not the TypeScript declarations or a page about feedback itself.
std::string locate_docs(const std::string& name) {
    const std::string type = name.substr(0, name.find('.'));
    auto plain = [](std::string h) {
        h.erase(std::remove(h.begin(), h.end(), '`'), h.end());
        return h;
    };
    auto describe = [](const DocHit& h) {
        return h.path + ":" + std::to_string(h.line) + (h.heading.empty() ? "" : " (" + h.heading + ")");
    };
    std::vector<DocHit> hits = search_docs(type, 30);
    if (type != name)
        for (DocHit& h : search_docs(name, 12)) hits.push_back(std::move(h));
    const DocHit* fallback = nullptr;
    for (const DocHit& h : hits) {
        if (path_is_about_feedback(h.path)) continue;
        const std::string heading = lower(plain(h.heading));
        if (heading.find("typescript") != std::string::npos) continue;
        if (heading == lower(type) || heading == lower(name) || heading.rfind(lower(name) + " ", 0) == 0) return describe(h);
        if (!fallback) fallback = &h;
    }
    return fallback ? describe(*fallback) : std::string();
}

}  // namespace

Json ClaimMatch::to_json() const {
    Json j = Json::object({{"kind", kind}, {"name", name}, {"phrase", phrase}, {"where", where}});
    if (!doc.empty()) j["doc"] = doc;
    if (!documentedIn.empty()) j["documentedIn"] = documentedIn;
    return j;
}

ClaimResult check_feedback_claim(const ClaimInput& input, const CommandRegistry* registry, int relatedMax) {
    ClaimResult result;
    std::vector<FieldText> fields;
    fields.push_back({"title", input.title, words_of(input.title)});
    fields.push_back({"missing", input.missing, words_of(input.missing)});
    fields.push_back({"suggestion", input.suggestion, words_of(input.suggestion)});

    if (relatedMax > 0) {
        std::set<std::string> seen;
        for (const DocHit& h : search_docs(input.title + " " + input.suggestion.substr(0, 80), 12)) {
            if (path_is_about_feedback(h.path) || lower(h.heading).find("typescript") != std::string::npos) continue;
            if (!seen.insert(h.path + "#" + h.heading).second) continue;
            result.related.push_back(Json::object({{"doc", h.doc}, {"path", h.path}, {"heading", h.heading}, {"line", h.line}}));
            if (int(result.related.size()) >= relatedMax) break;
        }
    }

    if (norm(input.title) == norm(kFeedbackExampleTitle)) {
        ClaimMatch m;
        m.kind = "example";
        m.name = kFeedbackExampleTitle;
        m.phrase = input.title;
        m.where = "title";
        m.doc = "This is the invented example of the documentation of feedback.report. It shows the shape of a report, not a gap "
                "anyone has.";
        result.matches.push_back(std::move(m));
        return result;
    }

    // A report that says the thing exists but misbehaves is a bug report: nothing to refuse.
    if (says_it_misbehaves(" " + lower(input.title + " . " + input.missing + " . " + input.suggestion))) return result;

    const Catalog cat = build_catalog(registry);
    const std::set<std::string> mentioned = mentioned_components(cat, fields);

    for (const FieldText& f : fields) {
        const std::vector<Word>& w = f.words;
        for (std::size_t i = 0; i < w.size(); ++i) {
            const bool claim = lead_before(w, i);

            // A dotted name: a command (scene.duplicate), or Type.member that exists.
            if (w[i].dotted) {
                if (!claim && !postfix_claim(w, i + 1)) continue;
                const std::string lc = lower(w[i].raw);
                if (auto cmd = cat.commands.find(lc); cmd != cat.commands.end()) {
                    ClaimMatch m;
                    m.kind = "command";
                    m.name = cmd->second.first;
                    m.phrase = w[i].raw;
                    m.where = f.where;
                    m.doc = cmd->second.second;
                    add_match(result, std::move(m));
                } else if (auto mem = cat.dotted.find(lc); mem != cat.dotted.end()) {
                    ClaimMatch m;
                    m.kind = mem->second.kind;
                    m.name = mem->second.owner + "." + mem->second.member;
                    m.phrase = w[i].raw;
                    m.where = f.where;
                    m.doc = mem->second.doc;
                    add_match(result, std::move(m));
                }
                continue;
            }

            // Words that spell a field ("one-way" = oneWay) or a component ("tilemap"); the longest run of words wins.
            for (std::size_t len = 3; len >= 1; --len) {
                if (i + len > w.size()) continue;
                bool crossesClause = false, anyDotted = false;
                std::string joined, phrase;
                for (std::size_t k = i; k < i + len; ++k) {
                    if (k > i && w[k].clauseStart) crossesClause = true;
                    if (w[k].dotted) anyDotted = true;
                    joined += w[k].norm;
                    phrase += (k > i ? " " : "") + w[k].raw;
                }
                if (crossesClause || anyDotted || joined.size() < 5) continue;
                const bool claimHere = claim || postfix_claim(w, i + len);
                if (!claimHere) continue;
                bool matched = false;
                for (const std::string& candidate : {joined, singular(joined)}) {
                    // A field of a component.
                    if (auto mem = cat.memberByNorm.find(candidate); mem != cat.memberByNorm.end()) {
                        std::vector<const Member*> owners;
                        bool distinctive = len >= 2;
                        for (const Member& m : mem->second) {
                            if (m.kind != "field") continue;
                            owners.push_back(&m);
                            if (camel_case(m.member)) distinctive = true;
                        }
                        std::vector<const Member*> chosen;
                        if (!mentioned.empty()) {
                            for (const Member* m : owners)
                                if (mentioned.count(m->owner)) chosen.push_back(m);
                        } else if (distinctive) {
                            chosen = owners;
                        }
                        if (!chosen.empty()) {
                            const Member& m = *chosen.front();
                            ClaimMatch cm;
                            cm.kind = "field";
                            cm.name = m.owner + "." + m.member;
                            cm.phrase = phrase;
                            cm.where = f.where;
                            cm.doc = m.doc;
                            add_match(result, std::move(cm));
                            matched = true;
                        }
                    }
                    // A component (exact name only, and only when nothing else is said about it).
                    if (!matched) {
                        if (auto comp = cat.componentByNorm.find(candidate); comp != cat.componentByNorm.end() &&
                                                                              remainder_generic(w, i + len)) {
                            ClaimMatch cm;
                            cm.kind = "component";
                            cm.name = comp->second;
                            cm.phrase = phrase;
                            cm.where = f.where;
                            if (auto d = cat.componentDoc.find(comp->second); d != cat.componentDoc.end()) cm.doc = d->second;
                            add_match(result, std::move(cm));
                            matched = true;
                        }
                    }
                    if (matched) break;
                }
                if (matched) {
                    i += len - 1;
                    break;
                }
            }
        }
    }

    for (ClaimMatch& m : result.matches) m.documentedIn = locate_docs(m.name);
    return result;
}

ClaimResult check_feedback_entry_claim(const Json& entry, const CommandRegistry* registry) {
    ClaimInput in;
    if (entry.is_object()) {
        in.title = entry.value("title", std::string());
        in.missing = entry.value("missing", std::string());
        in.suggestion = entry.value("suggestion", std::string());
    }
    return check_feedback_claim(in, registry, 0);
}

std::string ClaimResult::message() const {
    if (matches.empty()) return {};
    std::string out = matches.front().kind == "example" && matches.size() == 1
                          ? "Not filed: the title is the invented example from the documentation of feedback.report, not a gap you met."
                          : "Not filed: the engine already has what this report says is missing.";
    for (const ClaimMatch& m : matches) {
        if (m.kind == "example") {
            out += " " + m.doc;
            continue;
        }
        out += "\n  - \"" + m.phrase + "\" (" + m.where + ") is " + m.name + ", a " +
               (m.kind == "field" ? std::string("component field") : m.kind == "script" ? std::string("scripting API member") : m.kind) + ".";
        if (!m.doc.empty()) out += " Its doc string: \"" + m.doc + "\"";
        if (!m.documentedIn.empty()) out += " Documented in " + m.documentedIn + ".";
    }
    return out;
}

std::string ClaimResult::hint() const {
    if (matches.empty()) return {};
    if (matches.front().kind == "example" && matches.size() == 1)
        return "Describe the gap you actually met: what the engine lacked (missing), the short name (title), and what you did instead "
               "(workaround). Check the docs first (docs.search) so the gap is real.";
    const std::string name = matches.front().name;
    return "Read it (docs.search \"" + name + "\", docs.read, or `factoria call docs.search`) and use it. If it exists but does not "
           "work as documented, file it as a bug: say what you set, what you expected and what happened (for example \"" + name +
           " is ignored when ...\"). If the engine has it but you need MORE from it, name the new option (for example " +
           (name.find('.') != std::string::npos ? name.substr(0, name.find('.')) : name) +
           ".<newField>) and say why the existing ones are not enough.";
}

std::string ClaimResult::reason() const {
    if (matches.empty()) return {};
    if (matches.front().kind == "example" && matches.size() == 1)
        return "The title is the invented example of the feedback.report documentation, not a gap that was met.";
    std::string out = "The engine already has this:";
    for (const ClaimMatch& m : matches) {
        out += " \"" + m.phrase + "\" is " + m.name + (m.kind == "field" ? " (a component field)" : m.kind == "command" ? " (a command)" : "");
        if (!m.documentedIn.empty()) out += ", documented in " + m.documentedIn;
        out += ".";
    }
    out += " Use it; if it does not work as documented, file a bug that says what you tried.";
    return sanitize_status_reason(out);
}

Json ClaimResult::to_json() const {
    Json out = Json::object();
    out["exists"] = refused();
    Json ms = Json::array();
    for (const ClaimMatch& m : matches) ms.push_back(m.to_json());
    out["matches"] = std::move(ms);
    out["related"] = related;
    if (refused()) {
        out["message"] = message();
        out["hint"] = hint();
    } else {
        out["message"] = "Nothing in this report names something the engine already has. " +
                         std::string(related.empty() ? "" : "Related documentation is listed in `related`: read it before filing; if it already "
                                                            "covers the gap, do not file it.");
    }
    return out;
}

Result<std::vector<std::string>> reject_claimed_feedback_file(const std::string& path, const CommandRegistry* registry) {
    auto loaded = load_feedback(path);
    if (!loaded.ok()) return loaded.error();
    std::vector<std::pair<std::string, std::string>> caught;  // id, reason
    if (loaded->is_object() && loaded->contains("entries") && (*loaded)["entries"].is_array())
        for (const Json& e : (*loaded)["entries"]) {
            if (!e.is_object() || e.value("status", std::string("open")) != "open") continue;
            if (e.value("claimCheck", std::string()) == "dismissed") continue;
            ClaimResult r = check_feedback_entry_claim(e, registry);
            if (r.refused()) caught.emplace_back(e.value("id", std::string()), r.reason());
        }
    std::vector<std::string> ids;
    for (const auto& [id, reason] : caught) {
        auto u = update_feedback_file(path, id, "rejected", "", {}, reason, "engine");
        if (!u.ok()) return u.error();
        ids.push_back(id);
    }
    return ids;
}

void register_feedback_check_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "feedback.check";
    info.category = "feedback";
    info.readOnly = true;
    info.summary = "Check, before filing, whether the engine already has what a feedback report says is missing.";
    info.description =
        "feedback.report runs this check itself and refuses a report that calls missing something the engine has (a component, a "
        "field such as Collider2D.oneWay, a command, a scripting member): the answer names what exists, its doc string and the page "
        "that documents it. Call it first with the title, missing and suggestion you are about to file to find out. `exists: true` "
        "means do not file: read the docs; if it does not work as documented, file a BUG that says what you tried. `exists: false` "
        "lists `related` documentation to read before you decide. A request for an extra option on an existing component (the field "
        "is not there) passes. With `entries: true` it checks the OPEN entries already in this project's ENGINE_FEEDBACK.json instead, and with "
        "`reject: true` too it rejects the ones it catches (status rejected, statusBy engine, the reason says what exists); a person can "
        "reopen one and it is not rejected again. Example: {\"title\":\"No fluid simulation\",\"missing\":\"There is no liquid solver.\"}";
    Json props = Json::object();
    props["title"] = Json::object({{"type", "string"}, {"description", "The title you would file."}});
    props["missing"] = Json::object({{"type", "string"}, {"description", "What you say the engine lacks."}});
    props["suggestion"] = Json::object({{"type", "string"}, {"description", "The engine change you would propose."}});
    props["entries"] = Json::object({{"type", "boolean"}, {"description", "Check the open entries of this project's feedback file instead of a new report."}});
    props["reject"] = Json::object({{"type", "boolean"}, {"description", "With entries: reject the entries the check catches (statusBy engine)."}});
    info.inputSchema = Json::object({{"type", "object"}, {"properties", props}});
    registry.add(info, [&registry, projectDir](const Json& args) {
        if (args.value("entries", false)) {
            const std::string path = feedback_file_for_project(projectDir);
            auto loaded = load_feedback(path);
            if (!loaded.ok()) return Json::object({{"entries", Json::array()}, {"count", 0}, {"note", "No ENGINE_FEEDBACK.json yet."}});
            Json caught = Json::array();
            if (loaded->contains("entries") && (*loaded)["entries"].is_array())
                for (const Json& e : (*loaded)["entries"]) {
                    if (!e.is_object() || e.value("status", std::string("open")) != "open") continue;
                    ClaimResult r = check_feedback_entry_claim(e, &registry);
                    if (!r.refused()) continue;
                    Json j = r.to_json();
                    j["id"] = e.value("id", std::string());
                    caught.push_back(std::move(j));
                }
            Json out = Json::object({{"count", caught.size()}, {"entries", caught}});
            if (args.value("reject", false)) {
                require_capability(Capability::WriteProject, "feedback.check", "`reject` changes ENGINE_FEEDBACK.json");
                auto ids = reject_claimed_feedback_file(path, &registry);
                if (!ids.ok()) throw CommandError("failed", ids.error().message, ids.error().hint);
                out["rejected"] = *ids;
            }
            return out;
        }
        ClaimInput in;
        in.title = tooling_detail::arg_string(args, "title", true);
        if (in.title.empty()) throw CommandError("invalid_argument", "title is required (or pass entries: true).", "");
        in.missing = tooling_detail::arg_string(args, "missing", false);
        in.suggestion = tooling_detail::arg_string(args, "suggestion", false);
        return check_feedback_claim(in, &registry, 4).to_json();
    });
    // feedback.check only reads; `reject` changes ENGINE_FEEDBACK.json and requires writeProject in the handler.
    declare_command_capabilities(registry, {
        {"feedback.check", capability_sets::reads()}});
}

}  // namespace fa
