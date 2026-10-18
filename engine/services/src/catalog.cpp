// The "platform" section of factoria.json: parsing with errors that teach, and lookups by id.
#include <algorithm>
#include <cmath>
#include <set>

#include "fa/core/strings.h"
#include "fa/services/platform.h"

namespace fa {

namespace {

const std::vector<std::string>& platform_names_list() {
    static const std::vector<std::string> names = {"windows", "macos", "linux", "ios", "android", "web"};
    return names;
}

bool valid_id(const std::string& s) {
    if (s.empty() || s.size() > 64) return false;
    return std::all_of(s.begin(), s.end(), [](unsigned char c) { return std::isalnum(c) || c == '_' || c == '.' || c == '-'; });
}

bool valid_backend_name(const std::string& s) {
    return !s.empty() && s.size() <= 64 && s[0] >= 'a' && s[0] <= 'z' &&
           std::all_of(s.begin(), s.end(), [](char c) { return (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_'; });
}

std::string in_quotes(const std::string& s) { return Json(s).dump(); }

std::string in_quotes_list(const std::vector<std::string>& items) {
    std::string out;
    for (std::size_t i = 0; i < items.size(); ++i) out += (i ? ", " : "") + in_quotes(items[i]);
    return out;
}

// ` (did you mean "x"?)` or nothing.
std::string suggestion(const std::string& input, const std::vector<std::string>& candidates) {
    const std::string best = closest_match(input, candidates);
    return best.empty() ? std::string() : " (did you mean " + in_quotes(best) + "?)";
}

// Reads one section into the catalog, collecting issues. Keeps the context (section name, pointers) in one place.
struct Parser {
    PlatformCatalogParse out;

    void issue(const std::string& pointer, std::string message, std::string hint, bool warning = false) {
        out.issues.push_back({pointer, std::move(message), std::move(hint), warning});
    }

    // Keys of `obj` that are not in `known`: warnings with a suggestion.
    void unknown_keys(const Json& obj, const std::string& pointer, const std::vector<std::string>& known) {
        for (auto it = obj.begin(); it != obj.end(); ++it)
            if (std::find(known.begin(), known.end(), it.key()) == known.end())
                issue(pointer + "/" + it.key(), "unknown key " + in_quotes(it.key()) + "; the keys here are " + in_quotes_list(known) +
                                                    suggestion(it.key(), known),
                      "Remove it, or fix the spelling (docs/PLATFORM.md, \"The catalog\").", true);
    }

    // A required, non-empty string.
    bool need_string(const Json& obj, const std::string& pointer, const char* key, std::string& dst, const std::string& example) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) {
            issue(pointer + "/" + key, std::string("missing ") + in_quotes(key), "Add it, e.g. \"" + std::string(key) + "\": " + example + ".");
            return false;
        }
        if (!it->is_string() || it->get<std::string>().empty()) {
            issue(pointer + "/" + key, std::string("expected a non-empty string, got ") + describe_json_value(*it),
                  "Write the " + std::string(key) + " as text, e.g. \"" + std::string(key) + "\": " + example + ".");
            return false;
        }
        dst = it->get<std::string>();
        return true;
    }

    void opt_string(const Json& obj, const std::string& pointer, const char* key, std::string& dst) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return;
        if (!it->is_string()) {
            issue(pointer + "/" + key, "expected a string, got " + describe_json_value(*it), "Write it as text.");
            return;
        }
        dst = it->get<std::string>();
    }

    void opt_bool(const Json& obj, const std::string& pointer, const char* key, bool& dst) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) return;
        if (!it->is_boolean()) {
            issue(pointer + "/" + key, "expected true or false, got " + describe_json_value(*it), "Use true or false.");
            return;
        }
        dst = it->get<bool>();
    }

    // An enum string; `dst` keeps its default when the key is absent. `required`: absent is an error.
    bool read_enum(const Json& obj, const std::string& pointer, const char* key, const std::vector<std::string>& values,
                   const std::string& what, std::string& dst, bool required) {
        auto it = obj.find(key);
        if (it == obj.end() || it->is_null()) {
            if (required)
                issue(pointer + "/" + key, std::string("missing ") + in_quotes(key) + "; use one of " + in_quotes_list(values),
                      "Add it, e.g. \"" + std::string(key) + "\": " + in_quotes(values[0]) + ".");
            return !required;
        }
        const std::string got = it->is_string() ? it->get<std::string>() : std::string();
        if (!it->is_string() || std::find(values.begin(), values.end(), got) == values.end()) {
            const std::string shown = it->is_string() ? in_quotes(got) : describe_json_value(*it);
            issue(pointer + "/" + key, shown + " is not " + what + "; use one of " + in_quotes_list(values) +
                                           (it->is_string() ? suggestion(got, values) : std::string()),
                  "Fix the value in factoria.json (docs/PLATFORM.md, \"The catalog\").");
            return false;
        }
        dst = got;
        return true;
    }

    // "ids": {"steam": "ACH_WIN"} - the store id for each backend.
    void read_ids(const Json& obj, const std::string& pointer, PlatformEntry& e) {
        auto it = obj.find("ids");
        if (it == obj.end() || it->is_null()) return;
        if (!it->is_object()) {
            issue(pointer + "/ids", "expected an object mapping backend names to store ids, got " + describe_json_value(*it),
                  "Example: \"ids\": {\"steam\": \"ACH_WIN_ONE_GAME\", \"apple\": \"com.studio.game.first_win\"}.");
            return;
        }
        for (auto ii = it->begin(); ii != it->end(); ++ii) {
            const std::string p = pointer + "/ids/" + ii.key();
            if (!valid_backend_name(ii.key())) {
                issue(p, in_quotes(ii.key()) + " is not a backend name; use the name the backend registers, lower-case letters, digits and "
                                            "underscores (\"steam\", \"apple\")",
                      "The keys of \"ids\" are backend names; the value is the id that store uses.");
                continue;
            }
            if (!ii->is_string() || ii->get<std::string>().empty()) {
                issue(p, "expected the store's id as a non-empty string, got " + describe_json_value(*ii),
                      "Example: \"" + ii.key() + "\": \"ACH_WIN_ONE_GAME\".");
                continue;
            }
            e.ids[ii.key()] = ii->get<std::string>();
        }
    }

    // id: required, valid, unique within the section. Returns false when the entry cannot be used.
    bool read_id(const Json& obj, const std::string& pointer, const std::string& noun, std::set<std::string>& seen,
                 std::map<std::string, std::string>& firstAt, PlatformEntry& e) {
        auto it = obj.find("id");
        if (it == obj.end() || it->is_null()) {
            issue(pointer + "/id", "missing \"id\"; every " + noun + " needs the unique id scripts use",
                  "Add one, e.g. \"id\": \"first_win\" (1-64 letters, digits, '_', '.' or '-').");
            return false;
        }
        if (!it->is_string() || !valid_id(it->get<std::string>())) {
            issue(pointer + "/id", describe_json_value(*it) + " is not a valid id; use 1-64 letters, digits, '_', '.' or '-'",
                  "Example: \"id\": \"first_win\". The id is what scripts pass to platform.*; the store's own id goes in \"ids\".");
            return false;
        }
        e.id = it->get<std::string>();
        if (!seen.insert(e.id).second) {
            issue(pointer + "/id", "the id " + in_quotes(e.id) + " is used twice (first at " + firstAt[e.id] + ")",
                  "Ids are unique within the section: rename one.");
            return false;
        }
        firstAt[e.id] = pointer + "/id";
        return true;
    }

    template <class T, class F>
    void read_section(const Json& root, const char* key, const std::string& noun, F&& readEntry, std::vector<T>& dst) {
        auto it = root.find(key);
        if (it == root.end() || it->is_null()) return;
        const std::string pointer = std::string("/platform/") + key;
        if (!it->is_array()) {
            issue(pointer, "expected an array of " + noun + "s, got " + describe_json_value(*it),
                  "Write a list: \"" + std::string(key) + "\": [{\"id\": \"...\"}].");
            return;
        }
        std::set<std::string> seen;
        std::map<std::string, std::string> firstAt;
        for (std::size_t i = 0; i < it->size(); ++i) {
            const Json& e = (*it)[i];
            const std::string p = pointer + "/" + std::to_string(i);
            if (!e.is_object()) {
                issue(p, "expected an object describing the " + noun + ", got " + describe_json_value(e),
                      "Example: {\"id\": \"...\"}.");
                continue;
            }
            T entry;
            const std::size_t before = out.issues.size();
            const bool idOk = read_id(e, p, noun, seen, firstAt, entry);
            readEntry(e, p, entry);
            bool failed = !idOk;
            for (std::size_t k = before; k < out.issues.size(); ++k) failed = failed || !out.issues[k].warning;
            if (!failed) dst.push_back(std::move(entry));
        }
    }

    void read_backend(const Json& root) {
        auto it = root.find("backend");
        if (it == root.end() || it->is_null()) return;
        const std::string pointer = "/platform/backend";
        const std::string hint = "Use \"auto\" (the default), the name of a plugin declared in \"plugins\" (\"steam\"), or an object per "
                                 "platform: {\"windows\": \"steam\", \"macos\": \"steam\", \"ios\": \"apple\"}.";
        auto name = [&](const Json& v, const std::string& p) -> std::optional<std::string> {
            if (!v.is_string() || !valid_backend_name(v.get<std::string>())) {
                issue(p, "expected \"auto\" or a plugin name, got " + describe_json_value(v), hint);
                return std::nullopt;
            }
            return v.get<std::string>() == "auto" ? std::string() : v.get<std::string>();
        };
        if (it->is_object()) {
            for (auto pi = it->begin(); pi != it->end(); ++pi) {
                const std::string p = pointer + "/" + pi.key();
                const auto& all = platform_names_list();
                if (std::find(all.begin(), all.end(), pi.key()) == all.end()) {
                    issue(p, in_quotes(pi.key()) + " is not a platform; use " + in_quotes_list(all) + suggestion(pi.key(), all), hint);
                    continue;
                }
                if (auto n = name(*pi, p)) {
                    out.catalog.backendByPlatform[pi.key()] = *n;
                    if (!n->empty()) out.catalog.backendRefs.push_back({p, *n});
                }
            }
        } else if (auto n = name(*it, pointer)) {
            out.catalog.backend = *n;
            if (!n->empty()) out.catalog.backendRefs.push_back({pointer, *n});
        }
    }
};

}  // namespace

const std::string& PlatformEntry::store_id(const std::string& backend) const {
    auto it = ids.find(backend);
    return it != ids.end() ? it->second : id;
}

std::string PlatformCatalog::backend_for(const std::string& platform) const {
    auto it = backendByPlatform.find(platform);
    return it != backendByPlatform.end() ? it->second : backend;
}

namespace {
template <class T>
const T* find_by_id(const std::vector<T>& v, const std::string& id) {
    auto it = std::find_if(v.begin(), v.end(), [&](const T& e) { return e.id == id; });
    return it == v.end() ? nullptr : &*it;
}
template <class T>
Json ids_of(const std::vector<T>& v) {
    Json a = Json::array();
    for (const T& e : v) a.push_back(e.id);
    return a;
}
}  // namespace

const PlatformAchievement* PlatformCatalog::find_achievement(const std::string& id) const { return find_by_id(achievements, id); }
const PlatformStat* PlatformCatalog::find_stat(const std::string& id) const { return find_by_id(stats, id); }
const PlatformLeaderboard* PlatformCatalog::find_leaderboard(const std::string& id) const { return find_by_id(leaderboards, id); }
const PlatformProduct* PlatformCatalog::find_product(const std::string& id) const { return find_by_id(products, id); }

Json PlatformCatalog::ids_json() const {
    return Json::object({{"achievements", ids_of(achievements)}, {"stats", ids_of(stats)}, {"leaderboards", ids_of(leaderboards)},
                         {"products", ids_of(products)}});
}

Error PlatformIssue::to_error() const {
    return make_error("factoria.json#" + pointer + ": " + message, hint);
}

bool PlatformCatalogParse::ok() const {
    return std::none_of(issues.begin(), issues.end(), [](const PlatformIssue& i) { return !i.warning; });
}

PlatformCatalogParse parse_platform_catalog(const Json& section) {
    Parser p;
    if (section.is_null()) return p.out;
    if (!section.is_object()) {
        p.issue("/platform", "expected an object like {\"achievements\": [...]}, got " + describe_json_value(section),
                "The section holds optional lists: achievements, stats, leaderboards, products, and \"backend\" (docs/PLATFORM.md).");
        return std::move(p.out);
    }
    p.unknown_keys(section, "/platform", {"backend", "achievements", "stats", "leaderboards", "products"});
    p.read_backend(section);

    p.read_section<PlatformAchievement>(
        section, "achievements", "achievement",
        [&](const Json& e, const std::string& ptr, PlatformAchievement& a) {
            p.unknown_keys(e, ptr, {"id", "name", "description", "hidden", "ids"});
            p.need_string(e, ptr, "name", a.name, "\"First win\"");
            p.opt_string(e, ptr, "description", a.description);
            p.opt_bool(e, ptr, "hidden", a.hidden);
            p.read_ids(e, ptr, a);
        },
        p.out.catalog.achievements);

    p.read_section<PlatformStat>(
        section, "stats", "stat",
        [&](const Json& e, const std::string& ptr, PlatformStat& s) {
            p.unknown_keys(e, ptr, {"id", "type", "ids"});
            p.read_enum(e, ptr, "type", {"int", "float"}, "a stat type", s.type, false);
            p.read_ids(e, ptr, s);
        },
        p.out.catalog.stats);

    p.read_section<PlatformLeaderboard>(
        section, "leaderboards", "leaderboard",
        [&](const Json& e, const std::string& ptr, PlatformLeaderboard& l) {
            p.unknown_keys(e, ptr, {"id", "name", "order", "ids"});
            p.need_string(e, ptr, "name", l.name, "\"High score\"");
            p.read_enum(e, ptr, "order", {"descending", "ascending"}, "a leaderboard order", l.order, false);
            p.read_ids(e, ptr, l);
        },
        p.out.catalog.leaderboards);

    p.read_section<PlatformProduct>(
        section, "products", "product",
        [&](const Json& e, const std::string& ptr, PlatformProduct& pr) {
            p.unknown_keys(e, ptr, {"id", "type", "title", "description", "price", "currency", "ids"});
            p.read_enum(e, ptr, "type", {"consumable", "nonConsumable", "subscription"}, "a product type", pr.type, true);
            p.need_string(e, ptr, "title", pr.title, "\"100 gems\"");
            p.opt_string(e, ptr, "description", pr.description);
            if (auto it = e.find("price"); it != e.end() && !it->is_null()) {
                if (!it->is_number() || !std::isfinite(it->get<double>()) || it->get<double>() < 0)
                    p.issue(ptr + "/price", "expected a number of at least 0, got " + describe_json_value(*it),
                            "The price is only used by the fake backend (real stores give their own), e.g. \"price\": 0.99.");
                else
                    pr.price = it->get<double>();
            }
            if (auto it = e.find("currency"); it != e.end() && !it->is_null()) {
                if (!it->is_string() || it->get<std::string>().empty())
                    p.issue(ptr + "/currency", "expected a currency code such as \"USD\", got " + describe_json_value(*it),
                            "Example: \"currency\": \"EUR\". The default is \"USD\".");
                else
                    pr.currency = it->get<std::string>();
            }
            p.read_ids(e, ptr, pr);
        },
        p.out.catalog.products);

    return std::move(p.out);
}

Result<PlatformCatalog> load_platform_catalog(const Json& section) {
    PlatformCatalogParse parsed = parse_platform_catalog(section);
    for (const PlatformIssue& i : parsed.issues)
        if (!i.warning) return i.to_error();
    return std::move(parsed.catalog);
}

}  // namespace fa
