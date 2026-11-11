#include "script_lint.h"

#include <algorithm>
#include <cctype>
#include <deque>
#include <map>
#include <set>

#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "js_scan.h"

namespace fa::tooling_detail {
namespace {

bool is_ident_start(char c) { return std::isalpha(static_cast<unsigned char>(c)) || c == '_' || c == '$'; }
bool is_ident_name(const std::string& s) {
    if (s.empty() || !is_ident_start(s[0])) return false;
    return std::all_of(s.begin(), s.end(), js_ident_char);
}

struct Cursor {
    const std::string& s;
    std::size_t i = 0;
    void blanks() {
        while (i < s.size() && std::isspace(static_cast<unsigned char>(s[i]))) ++i;
    }
    bool eat(char c) {
        blanks();
        if (i < s.size() && s[i] == c) { ++i; return true; }
        return false;
    }
    // An identifier or reserved word; start offset in `at`.
    bool ident(std::string& out, std::size_t* at = nullptr) {
        blanks();
        if (i >= s.size() || !is_ident_start(s[i])) return false;
        const std::size_t b = i;
        while (i < s.size() && js_ident_char(s[i])) ++i;
        out = s.substr(b, i - b);
        if (at) *at = b;
        return true;
    }
};

struct ImportedName {
    std::string module;
    std::string exported;  // "*" for `import * as ns`
    std::string local;
    std::size_t at = 0;  // offset of the exported name (of the `ns` for *)
};

struct ImportStatement {
    std::size_t begin = 0, end = 0;
};

// Every `import ... from "<module>"` of the file. `bare` finds the statements, `code` has the module name.
void parse_imports(const Masked& m, std::vector<ImportedName>& names, std::vector<ImportStatement>& spans) {
    const std::string& b = m.bare;
    for (std::size_t at = b.find("import"); at != std::string::npos; at = b.find("import", at + 6)) {
        if (at > 0 && (js_ident_char(b[at - 1]) || b[at - 1] == '.')) continue;
        if (at + 6 < b.size() && js_ident_char(b[at + 6])) continue;
        Cursor c{b, at + 6};
        c.blanks();
        if (c.i >= b.size() || b[c.i] == '(' || b[c.i] == '.' || b[c.i] == '"' || b[c.i] == '\'') continue;
        std::vector<ImportedName> found;
        bool ok = true;
        while (ok) {
            c.blanks();
            if (c.i >= b.size()) { ok = false; break; }
            if (b[c.i] == '*') {
                ++c.i;
                std::string as, local;
                std::size_t lat = 0;
                if (!c.ident(as) || as != "as" || !c.ident(local, &lat)) { ok = false; break; }
                found.push_back({"", "*", local, lat});
            } else if (b[c.i] == '{') {
                ++c.i;
                while (true) {
                    c.blanks();
                    if (c.i >= b.size()) { ok = false; break; }
                    if (b[c.i] == '}') { ++c.i; break; }
                    if (b[c.i] == ',') { ++c.i; continue; }
                    std::string name, as, local;
                    std::size_t nat = 0;
                    if (!c.ident(name, &nat)) { ok = false; break; }
                    local = name;
                    const std::size_t save = c.i;
                    if (c.ident(as) && as == "as") {
                        if (!c.ident(local)) { ok = false; break; }
                    } else {
                        c.i = save;
                    }
                    found.push_back({"", name, local, nat});
                }
            } else {
                std::string local;
                std::size_t lat = 0;
                if (!c.ident(local, &lat)) { ok = false; break; }
                found.push_back({"", "default", local, lat});
            }
            if (!ok) break;
            c.blanks();
            if (c.i < b.size() && b[c.i] == ',') { ++c.i; continue; }
            break;
        }
        if (!ok) continue;
        std::string from;
        if (!c.ident(from) || from != "from") continue;
        c.blanks();
        if (c.i >= b.size() || (b[c.i] != '"' && b[c.i] != '\'')) continue;
        const char q = m.code[c.i];
        const std::size_t close = m.code.find(q, c.i + 1);
        if (close == std::string::npos) continue;
        const std::string module = m.code.substr(c.i + 1, close - c.i - 1);
        for (ImportedName& n : found) {
            n.module = module;
            names.push_back(n);
        }
        spans.push_back({at, close + 1});
    }
}

// Names the file declares itself, so `world` that a parameter or a `const` shadows is not taken for the import. A scan by
// text cannot tell scopes apart: a name declared anywhere in the file is skipped everywhere.
std::set<std::string> declared_names(const std::string& b) {
    std::set<std::string> out;
    auto collect_until = [&](std::size_t from, char close) {
        // identifiers of a destructuring pattern or a parameter list, up to the matching bracket
        int depth = 1;
        std::size_t i = from;
        while (i < b.size() && depth > 0) {
            const char c = b[i];
            if (c == '(' || c == '{' || c == '[') ++depth;
            else if (c == ')' || c == '}' || c == ']') --depth;
            else if (is_ident_start(c) && (i == 0 || !js_ident_char(b[i - 1]))) {
                std::size_t e = i;
                while (e < b.size() && js_ident_char(b[e])) ++e;
                out.insert(b.substr(i, e - i));
                i = e;
                continue;
            }
            ++i;
        }
        (void)close;
    };
    for (const char* kw : {"const", "let", "var", "function", "class", "catch"}) {
        const std::size_t len = std::string_view(kw).size();
        for (std::size_t at = b.find(kw); at != std::string::npos; at = b.find(kw, at + len)) {
            if (at > 0 && js_ident_char(b[at - 1])) continue;
            if (at + len < b.size() && js_ident_char(b[at + len])) continue;
            Cursor c{b, at + len};
            c.blanks();
            if (c.i >= b.size()) continue;
            if (b[c.i] == '{' || b[c.i] == '[') {
                collect_until(c.i + 1, b[c.i] == '{' ? '}' : ']');
            } else if (b[c.i] == '(' && std::string_view(kw) == "catch") {
                collect_until(c.i + 1, ')');
            } else {
                std::string name;
                if (c.ident(name)) out.insert(name);
                if (std::string_view(kw) == "const" || std::string_view(kw) == "let" || std::string_view(kw) == "var") {
                    // More declarators of the same statement: `let a = 1, time = 2;` (commas at depth 0, up to the `;`).
                    int depth = 0;
                    for (std::size_t k = c.i; k < b.size() && k < c.i + 4000 && depth >= 0; ++k) {
                        const char ch = b[k];
                        if (ch == '(' || ch == '{' || ch == '[') ++depth;
                        else if (ch == ')' || ch == '}' || ch == ']') --depth;
                        else if (ch == ';' && depth == 0) break;
                        else if (ch == ',' && depth == 0) {
                            Cursor d{b, k + 1};
                            std::string more;
                            if (d.ident(more)) out.insert(more);
                        }
                    }
                }
                if (std::string_view(kw) == "function" || std::string_view(kw) == "class") {
                    c.blanks();
                    if (c.i < b.size() && b[c.i] == '(') collect_until(c.i + 1, ')');
                }
            }
        }
    }
    // Parameter lists of arrow functions and methods: `(a, b) =>`, `name(a, b) {`, and `a =>`.
    static const std::set<std::string> kControl = {"if", "for", "while", "switch", "catch", "with", "return"};
    for (std::size_t i = 0; i < b.size(); ++i) {
        if (b[i] != ')') continue;
        std::size_t j = i + 1;
        while (j < b.size() && std::isspace(static_cast<unsigned char>(b[j]))) ++j;
        const bool arrow = b.compare(j, 2, "=>") == 0;
        const bool body = j < b.size() && b[j] == '{';
        if (!arrow && !body) continue;
        int depth = 1;
        std::size_t k = i;
        while (k > 0 && depth > 0) {
            --k;
            if (b[k] == ')') ++depth;
            else if (b[k] == '(') --depth;
        }
        if (depth != 0) continue;
        if (body && !arrow) {
            std::size_t p = k;
            while (p > 0 && std::isspace(static_cast<unsigned char>(b[p - 1]))) --p;
            std::size_t e = p;
            while (p > 0 && js_ident_char(b[p - 1])) --p;
            if (p == e || kControl.count(b.substr(p, e - p))) continue;  // not a method or function head
        }
        collect_until(k + 1, ')');
    }
    for (std::size_t at = b.find("=>"); at != std::string::npos; at = b.find("=>", at + 2)) {
        std::size_t e = at;
        while (e > 0 && std::isspace(static_cast<unsigned char>(b[e - 1]))) --e;
        std::size_t s = e;
        while (s > 0 && js_ident_char(b[s - 1])) --s;
        if (s < e && is_ident_start(b[s])) out.insert(b.substr(s, e - s));
    }
    return out;
}

struct ApiIndex {
    // module -> export name -> item
    std::map<std::string, std::map<std::string, const Json*>> exports;
    // interface name -> member names ("" key present when the interface has an index signature or a member we cannot name)
    std::map<std::string, std::set<std::string>> interfaces;
};

ApiIndex index_api(const Json& manifest) {
    ApiIndex idx;
    if (!manifest.is_object() || !manifest.contains("modules")) return idx;
    for (const Json& mod : manifest["modules"]) {
        const std::string name = mod.value("name", "");
        if (!mod.contains("exports")) continue;
        for (const Json& e : mod["exports"]) {
            const std::string en = e.value("name", "");
            if (en.empty()) continue;
            idx.exports[name][en] = &e;
            const std::string kind = e.value("kind", "");
            if (kind != "interface" && kind != "class") continue;
            std::set<std::string>& names = idx.interfaces[en];
            for (const char* list : {"members", "statics"}) {
                if (!e.contains(list)) continue;
                for (const Json& mem : e[list]) {
                    const std::string mn = mem.value("name", "");
                    if (is_ident_name(mn)) names.insert(mn);
                    else names.insert("");
                }
            }
        }
    }
    return idx;
}

std::string trim(std::string s) {
    while (!s.empty() && std::isspace(static_cast<unsigned char>(s.back()))) s.pop_back();
    std::size_t b = 0;
    while (b < s.size() && std::isspace(static_cast<unsigned char>(s[b]))) ++b;
    return s.substr(b);
}

std::string at_text(const std::string& file, const std::string& text, std::size_t offset) {
    const SourcePos p = source_pos(text, offset);
    return file + ":" + std::to_string(p.line) + ":" + std::to_string(p.column);
}

bool object_builtin(const std::string& m) {
    static const std::set<std::string> kBuiltins = {"constructor", "toString", "toLocaleString", "valueOf", "hasOwnProperty",
                                                    "isPrototypeOf", "propertyIsEnumerable", "__proto__", "name", "length",
                                                    "prototype", "call", "apply", "bind"};
    return kBuiltins.count(m) != 0;
}

std::vector<std::string> keys_of(const std::set<std::string>& s) {
    std::vector<std::string> v;
    for (const std::string& k : s)
        if (!k.empty()) v.push_back(k);
    return v;
}

}  // namespace

ScriptLintResult lint_script(const std::string& file, const std::string& text, const Json& manifest) {
    ScriptLintResult out;
    if (text.empty() || text.size() > kMaxScanScriptBytes) return out;
    const ApiIndex api = index_api(manifest);
    if (api.exports.empty()) return out;
    const Masked m = mask_source(text);
    std::vector<ImportedName> imports;
    std::vector<ImportStatement> spans;
    parse_imports(m, imports, spans);
    const std::set<std::string> declared = declared_names(m.bare);
    auto in_import = [&](std::size_t at) {
        return std::any_of(spans.begin(), spans.end(), [&](const ImportStatement& s) { return at >= s.begin && at < s.end; });
    };
    // The locals bound to a constant of the engine API (`world`, `physics`): not entities.
    std::set<std::string> apiConsts;

    struct Target {
        std::string local, label;
        const std::set<std::string>* members = nullptr;
    };
    std::vector<Target> targets;
    std::deque<std::set<std::string>> owned;  // member lists built for `import * as ns` (stable addresses)
    const std::vector<std::string> componentNames = TypeRegistry::global().names();

    for (const ImportedName& imp : imports) {
        if (imp.module != "factoria" && imp.module != "factoria:test") continue;
        const auto modIt = api.exports.find(imp.module);
        if (modIt == api.exports.end()) continue;
        const auto& exports = modIt->second;
        if (imp.exported == "*" || imp.exported == "default") {  // the module builds both from the same object
            // `ns.member` on the whole module: member must be an export
            owned.emplace_back();
            std::set<std::string>& names = owned.back();
            for (const auto& [en, item] : exports) { (void)item; names.insert(en); }
            if (imp.module == "factoria")
                for (const std::string& c : componentNames) names.insert(c);
            if (!declared.count(imp.local)) targets.push_back({imp.local, "the \"" + imp.module + "\" module", &names});
            continue;
        }
        const auto item = exports.find(imp.exported);
        bool known = item != exports.end();
        if (!known && imp.module == "factoria") {
            known = imp.exported == "PluginsAPI" || TypeRegistry::global().find(imp.exported) != nullptr;
        }
        if (!known) {
            std::vector<std::string> names;
            for (const auto& [en, it] : exports) { (void)it; names.push_back(en); }
            out.errors.push_back({file, "", at_text(file, text, imp.at) + ": \"" + imp.module + "\" does not export '" + imp.exported + "'",
                                  did_you_mean(imp.exported, names) + " (every export: types/factoria.d.ts, or `factoria api`)"});
            continue;
        }
        if (item == exports.end()) continue;
        const std::string kind = item->second->value("kind", "");
        if (kind == "const") {
            apiConsts.insert(imp.local);
            const std::string type = trim(item->second->value("type", ""));
            const auto ifc = api.interfaces.find(type);
            if (ifc != api.interfaces.end() && !ifc->second.count("") && !declared.count(imp.local))
                targets.push_back({imp.local, imp.exported + " (" + type + ")", &ifc->second});
        } else if (kind == "class") {
            const auto ifc = api.interfaces.find(imp.exported);
            if (ifc != api.interfaces.end() && !ifc->second.count("") && !declared.count(imp.local))
                targets.push_back({imp.local, "class " + imp.exported, &ifc->second});
        }
    }

    // `local.member` where the engine says what the members are.
    for (const Target& t : targets) {
        const std::string& b = m.bare;
        for (std::size_t at = b.find(t.local); at != std::string::npos; at = b.find(t.local, at + t.local.size())) {
            if (at > 0 && (js_ident_char(b[at - 1]) || b[at - 1] == '.')) continue;
            std::size_t i = at + t.local.size();
            if (i < b.size() && js_ident_char(b[i])) continue;
            if (in_import(at)) continue;
            while (i < b.size() && std::isspace(static_cast<unsigned char>(b[i]))) ++i;
            if (i < b.size() && b[i] == '?' && i + 1 < b.size() && b[i + 1] == '.') ++i;
            if (i >= b.size() || b[i] != '.') continue;
            ++i;
            while (i < b.size() && std::isspace(static_cast<unsigned char>(b[i]))) ++i;
            if (i >= b.size() || !is_ident_start(b[i])) continue;
            std::size_t e = i;
            while (e < b.size() && js_ident_char(b[e])) ++e;
            const std::string member = b.substr(i, e - i);
            if (t.members->count(member) || object_builtin(member)) continue;
            out.errors.push_back({file, "", at_text(file, text, i) + ": '" + t.local + "." + member + "' does not exist: " + t.label +
                                                " has no member '" + member + "'",
                                  did_you_mean(member, keys_of(*t.members)) + " (the members: types/factoria.d.ts, or `factoria api`)"});
        }
    }

    // Literal component names: entity.get("Sprite"), add, has, remove.
    for (const char* method : {"get", "add", "has", "remove"}) {
        const std::string pat = std::string(".") + method;
        const std::string& b = m.bare;
        for (std::size_t at = b.find(pat); at != std::string::npos; at = b.find(pat, at + pat.size())) {
            std::size_t i = at + pat.size();
            if (i < b.size() && js_ident_char(b[i])) continue;
            while (i < b.size() && std::isspace(static_cast<unsigned char>(b[i]))) ++i;
            if (i >= b.size() || b[i] != '(') continue;
            ++i;
            while (i < b.size() && std::isspace(static_cast<unsigned char>(b[i]))) ++i;
            if (i >= b.size() || (b[i] != '"' && b[i] != '\'')) continue;
            const std::size_t qat = i;
            const std::size_t close = m.code.find(m.code[qat], qat + 1);
            if (close == std::string::npos) continue;
            const std::string name = m.code.substr(qat + 1, close - qat - 1);
            // The receiver: skip the engine's own objects (storage.get("Score")) and maps and caches.
            std::size_t rs = at;
            while (rs > 0 && (js_ident_char(b[rs - 1]) || b[rs - 1] == '.')) --rs;
            const std::string receiver = b.substr(rs, at - rs);
            const std::string root = receiver.substr(0, receiver.find('.'));
            if (apiConsts.count(root)) continue;
            std::string last = receiver.substr(receiver.rfind('.') == std::string::npos ? 0 : receiver.rfind('.') + 1);
            const std::string lastLower = to_lower(last);
            bool container = false;
            for (const char* w : {"map", "set", "cache", "store", "storage", "registry", "table", "dict", "memo", "index", "lookup",
                                  "list", "array", "params", "args", "options", "opts", "props", "data", "config", "settings", "state",
                                  "json", "obj", "object", "bag"})
                container = container || lastLower.find(w) != std::string::npos;
            if (container) continue;
            if (name.empty() || !is_ident_name(name)) continue;
            if (TypeRegistry::global().find(name)) continue;
            const TypeInfo* ci = TypeRegistry::global().find_ci(name);
            const bool pascal = std::isupper(static_cast<unsigned char>(name[0])) != 0;
            if (!ci && !pascal) continue;
            // `levels.get("Intro")`, `items.has("Gold")`: a plural name is a collection of things, not an entity. A name that is a
            // component in another case (`ci`) still warns.
            if (!ci && lastLower.size() > 2 && lastLower.back() == 's' && lastLower[lastLower.size() - 2] != 's')
                continue;
            std::string msg = at_text(file, text, qat) + ": ." + method + "(\"" + name + "\"): ";
            if (ci) {
                msg += "there is no component '" + name + "', and a component is found by its exact name; the one meant is '" + ci->name +
                       "' (if this is not an entity, ignore this warning)";
                out.warnings.push_back({file, "", msg, "Write ." + std::string(method) + "(\"" + ci->name + "\")."});
            } else {
                msg += "no component is called '" + name + "' (if this is not an entity, ignore this warning)";
                out.warnings.push_back({file, "", msg, did_you_mean(name, componentNames) + " (every component: `factoria api components`)"});
            }
        }
    }
    return out;
}

}  // namespace fa::tooling_detail
