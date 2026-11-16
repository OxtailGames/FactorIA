// The JavaScript of the docs (docs/**/*.md, docs/design/ included; not docs/i18n, not the generated references):
// every ```js / ```javascript block parses and names only members the script typings have.
//
// - Parse: the block is compiled (not run) as an ES module in the engine's QuickJS. A block that is a piece of a script
//   (an object literal, `...` for what is left out, a `return` outside a function) is marked ```js fragment and is not
//   parsed; keep that marker rare. The API names of a fragment are still checked.
// - API names: `root.member` (and `root.member.member` while the member's declared type is an interface of the typings)
//   for every root the typings export as a const (`world`, `ui`, `input`, ...), a namespace (`tween`) or a class (static
//   members: `Vec2.zero`). Strings and comments are ignored (code inside `${...}` is checked); a root the block declares
//   itself (const/let/var/function/class, a parameter, a destructured name, an alias or an import from another module) is
//   skipped; a name imported from "factoria" or "factoria:test" is NOT a declaration, it is the root checked. A block that
//   imports from "factoria:test" or calls test()/expect()/describe() reads the roots of that module (its `game`).
//   It is a name check, not a type checker. What it does not see: the members of a returned value (`world.find(x).foo`),
//   a chain that continues on the next line, a regular-expression literal that holds a quote or `//`, a root used as a
//   property name written `root .x`, and a declaration that an earlier block of the same page made.
//   A block that shows a wrong name on purpose (a "this does not work" example) opens with ```js names-skip: it is parsed,
//   its API names are not checked. `...world.items` (a spread) is checked; `a.world.x` (a property) is not.
// The typings are the ones `factoria api --dts` writes, produced in memory by the engine that is running.
#include <doctest.h>

#include <algorithm>
#include <cctype>
#include <filesystem>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/runtime/engine.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/scaffold.h"
#include "fa_test_paths.h"
#include "quickjs.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Block {
    std::string file;  // below the checkout, '/'
    int line = 0;      // the line of the opening fence
    bool fragment = false;
    bool skipNames = false;  // ```js names-skip
    std::string code;
};

bool starts_with(const std::string& s, const std::string& p) { return s.rfind(p, 0) == 0; }

std::vector<std::string> split_lines(const std::string& text) {
    std::vector<std::string> lines;
    std::istringstream in(text);
    std::string l;
    while (std::getline(in, l)) {
        if (!l.empty() && l.back() == '\r') l.pop_back();
        lines.push_back(l);
    }
    return lines;
}

std::vector<Block> js_blocks_of(const std::string& rel, const std::string& text) {
    std::vector<Block> out;
    const std::vector<std::string> lines = split_lines(text);
    static const std::regex open(R"(^(\s*)(`{3,})\s*(js|javascript)(\s.*)?$)");
    for (size_t i = 0; i < lines.size(); ++i) {
        std::smatch m;
        if (!std::regex_match(lines[i], m, open)) continue;
        Block b;
        b.file = rel;
        b.line = int(i) + 1;
        const std::string info = m[4].str();
        b.fragment = std::regex_search(info, std::regex(R"(\bfragment\b)"));
        b.skipNames = std::regex_search(info, std::regex(R"(\bnames-skip\b)"));
        const size_t indent = m[1].str().size();
        const std::string fence = m[2].str();
        size_t j = i + 1;
        for (; j < lines.size(); ++j) {
            std::string t = lines[j];
            const size_t nb = t.find_first_not_of(" \t");
            if (nb != std::string::npos && t.compare(nb, fence.size(), fence) == 0 &&
                t.find_first_not_of('`', nb) == std::string::npos)
                break;
            b.code +=
                (t.size() >= indent && t.compare(0, indent, std::string(indent, ' ')) == 0 ? t.substr(indent) : t);
            b.code += '\n';
        }
        out.push_back(std::move(b));
        i = j;
    }
    return out;
}

std::vector<Block> all_blocks() {
    std::vector<Block> out;
    const stdfs::path root = stdfs::path(FA_REPO_ROOT);
    std::vector<stdfs::path> files;
    for (const auto& e : stdfs::recursive_directory_iterator(root / "docs"))
        if (e.is_regular_file() && e.path().extension() == ".md") files.push_back(e.path());
    std::sort(files.begin(), files.end());
    for (const stdfs::path& p : files) {
        const std::string rel = p.lexically_relative(root).generic_string();
        if (starts_with(rel, "docs/i18n/") || starts_with(rel, "docs/reference/") || rel == "docs/COMPONENTS.md")
            continue;
        for (Block& b : js_blocks_of(rel, testing::read_all(p))) out.push_back(std::move(b));
    }
    return out;
}

// ------------------------------------------------------------------------------------------------ the typings model
struct TypeInfo {
    std::map<std::string, std::string> members;  // name -> declared type when it is a plain identifier, else ""
    std::string base;
    bool indexed = false;  // `[name: string]: T`: any name is a member (plugins)
};

struct Typings {
    std::map<std::string, TypeInfo> types;         // interfaces and classes: instance members
    std::map<std::string, TypeInfo> statics;       // classes (static members) and namespaces
    std::map<std::string, std::string> roots;      // const name -> type name, module "factoria"
    std::map<std::string, std::string> testRoots;  // the same for module "factoria:test" (its `game` is another one)
};

bool word_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$'; }

// The identifier that starts at line[i] ("" when none); moves i past it.
std::string take_ident(const std::string& line, size_t& i) {
    const size_t start = i;
    if (i < line.size() && (std::isalpha(static_cast<unsigned char>(line[i])) || line[i] == '_' || line[i] == '$'))
        while (i < line.size() && word_char(line[i])) ++i;
    return line.substr(start, i - start);
}

void skip_spaces(const std::string& line, size_t& i) {
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) ++i;
}

// One member line of an interface, class or namespace body (4 spaces of indent): `name?: Type;`, `name(...): T;`,
// `static readonly name: T;`, `[key: string]: T;` (an index signature: any name is a member).
void add_member(TypeInfo& t, const std::string& line, bool wantStatic) {
    if (line.compare(0, 4, "    ") != 0 || line.size() < 5 || line[4] == ' ') return;
    size_t i = 4;
    if (line.compare(i, 9, "readonly ") == 0 && line.size() > i + 9 && line[i + 9] == '[') i += 9;
    if (line[i] == '[') {  // `[name: string]` is an index signature; `[Symbol.iterator]` is not
        size_t k = i + 1;
        if (!take_ident(line, k).empty() && k < line.size() && line[k] == ':') t.indexed = true;
        return;
    }
    bool isStatic = false;
    for (;;) {  // modifiers: a word followed by a space and another identifier
        size_t k = i;
        const std::string w = take_ident(line, k);
        if ((w == "static" || w == "readonly" || w == "get" || w == "set") && k < line.size() && line[k] == ' ') {
            size_t k2 = k;
            skip_spaces(line, k2);
            size_t k3 = k2;
            if (!take_ident(line, k3).empty()) {
                if (w == "static") isStatic = true;
                i = k2;
                continue;
            }
        }
        break;
    }
    const std::string name = take_ident(line, i);
    if (name.empty() || isStatic != wantStatic) return;
    if (i < line.size() && line[i] == '?') ++i;
    skip_spaces(line, i);
    if (i >= line.size() || (line[i] != ':' && line[i] != '(' && line[i] != '<')) return;
    std::string type;
    if (line[i] == ':') {  // `name: Type;` and nothing after the identifier
        ++i;
        skip_spaces(line, i);
        const std::string ty = take_ident(line, i);
        if (i >= line.size() || line[i] == ';') type = ty;
    }
    t.members[name] = type;
}

bool starts_with_at(const std::string& s, const char* p) { return s.rfind(p, 0) == 0; }

Typings parse_typings(const std::string& dts) {
    Typings ty;
    static const std::regex declType(R"(^  export (?:interface|class) ([\w$]+)(?: extends ([\w$]+))?[^{]*\{$)");
    static const std::regex declNs(R"(^  export namespace ([\w$]+) \{$)");
    static const std::regex declConst(R"(^  export const ([\w$]+): ([\w$]+);$)");
    static const std::regex declFn(R"(^  export function ([\w$]+)\()");
    std::string cur;
    bool inTest = false;
    enum { None, Type, Ns } mode = None;
    for (const std::string& line : split_lines(dts)) {
        std::smatch m;
        if (starts_with_at(line, "declare module ")) inTest = line.find("factoria:test") != std::string::npos;
        if (mode == None) {
            if (!starts_with_at(line, "  export ")) continue;  // the regexes below all start with it
            if (std::regex_match(line, m, declType)) {
                cur = m[1];
                mode = Type;
                ty.types[cur].base = m[2];
                ty.statics[cur];
            } else if (std::regex_match(line, m, declNs)) {
                cur = m[1];
                mode = Ns;
                ty.statics[cur];
            } else if (std::regex_match(line, m, declConst)) {
                (inTest ? ty.testRoots : ty.roots)[m[1]] = m[2];
            } else if (std::regex_search(line, m, declFn)) {
                ty.statics[m[1]];  // a function root: `didYouMean.` has no members to check
            }
        } else if (line == "  }") {
            mode = None;
        } else if (mode == Type) {
            add_member(ty.types[cur], line, false);
            add_member(ty.statics[cur], line, true);
        } else if (line.compare(0, 4, "    ") == 0) {  // namespace member: function / const / let name
            size_t i = 4;
            const std::string kw = take_ident(line, i);
            if (kw == "function" || kw == "const" || kw == "let") {
                skip_spaces(line, i);
                const std::string name = take_ident(line, i);
                if (!name.empty()) ty.statics[cur].members[name] = "";
            }
        }
    }
    return ty;
}

// Puts the global project root back when the scope ends, also when a REQUIRE throws.
struct ProjectRootGuard {
    stdfs::path saved = fs::project_root();
    ~ProjectRootGuard() { fs::set_project_root(saved); }
};

std::string typings_text() {
    std::string dts;
    testing::TempDir tmp;
    ProjectRootGuard guard;
    REQUIRE(create_project(tmp.str(), "2d-empty", {}).ok());
    fs::set_project_root(tmp.str());
    EngineConfig cfg;
    cfg.projectDir = tmp.str();
    cfg.graphics = false;
    cfg.headless = true;
    cfg.audioDevice = false;
    cfg.hotReload = false;
    cfg.memoryStorage = true;
    cfg.platformBackend = "fake";
    Engine engine;
    std::string err;
    const bool started = engine.init(cfg, nullptr, &err);
    REQUIRE_MESSAGE(started, err);
    dts = export_typescript(engine.scripts());
    engine.shutdown();
    return dts;
}

bool member_of(const Typings& ty, const std::string& type, const std::string& name, std::string* nextType) {
    for (std::string t = type; !t.empty();) {
        auto it = ty.types.find(t);
        if (it == ty.types.end()) return false;
        if (it->second.indexed) {
            nextType->clear();
            return true;
        }
        auto mem = it->second.members.find(name);
        if (mem != it->second.members.end()) {
            *nextType = mem->second;
            return true;
        }
        t = it->second.base;
    }
    return false;
}

// -------------------------------------------------------------------------------------------------------- the scan
// Blanks comments and the text of string literals in s[i..] (newlines kept), writing into out. Code inside `${...}` of a
// template literal stays. Stops at the `}` that closes a `${` when inBrace.
void strip_code(const std::string& s, std::string& out, size_t& i, bool inBrace);

void strip_template(const std::string& s, std::string& out, size_t& i) {  // s[i] is the opening backtick
    ++i;
    while (i < s.size() && s[i] != '`') {
        if (s[i] == '\\' && i + 1 < s.size()) {
            out[i++] = ' ';
            if (s[i] != '\n') out[i] = ' ';
            ++i;
        } else if (s[i] == '$' && i + 1 < s.size() && s[i + 1] == '{') {
            i += 2;
            strip_code(s, out, i, true);
        } else {
            if (s[i] != '\n') out[i] = ' ';
            ++i;
        }
    }
    if (i < s.size()) ++i;
}

void strip_code(const std::string& s, std::string& out, size_t& i, bool inBrace) {
    int depth = 0;
    while (i < s.size()) {
        const char c = s[i];
        if (c == '/' && i + 1 < s.size() && s[i + 1] == '/') {
            while (i < s.size() && s[i] != '\n') out[i++] = ' ';
        } else if (c == '/' && i + 1 < s.size() && s[i + 1] == '*') {
            const size_t end = s.find("*/", i + 2);
            const size_t stop = end == std::string::npos ? s.size() : end + 2;
            for (; i < stop; ++i)
                if (s[i] != '\n') out[i] = ' ';
        } else if (c == '`') {
            strip_template(s, out, i);
        } else if (c == '"' || c == '\'') {
            ++i;
            while (i < s.size() && s[i] != c && s[i] != '\n') {
                if (s[i] == '\\' && i + 1 < s.size()) out[i++] = ' ';
                out[i] = ' ';
                ++i;
            }
            if (i < s.size() && s[i] == c) ++i;
        } else if (c == '{') {
            ++depth;
            ++i;
        } else if (c == '}') {
            if (inBrace && depth == 0) {
                ++i;
                return;
            }
            --depth;
            ++i;
        } else {
            ++i;
        }
    }
}

// The code of a block with comments and the contents of string literals blanked out (newlines kept).
std::string strip_text(const std::string& s) {
    std::string out = s;
    size_t i = 0;
    strip_code(s, out, i, false);
    return out;
}

struct Tok {
    std::string text;
    size_t pos = 0;
    bool ident = false;
};

std::vector<Tok> tokenize(const std::string& code) {
    std::vector<Tok> toks;
    for (size_t i = 0; i < code.size();) {
        const char c = code[i];
        if (std::isspace(static_cast<unsigned char>(c))) {
            ++i;
        } else if (word_char(c)) {
            const size_t start = i;
            while (i < code.size() && word_char(code[i])) ++i;
            toks.push_back({code.substr(start, i - start), start, !std::isdigit(static_cast<unsigned char>(c))});
        } else if (c == '=' && i + 1 < code.size() && code[i + 1] == '>') {
            toks.push_back({"=>", i, false});
            i += 2;
        } else {
            toks.push_back({std::string(1, c), i, false});
            ++i;
        }
    }
    return toks;
}

bool is_open(const std::string& t) { return t == "(" || t == "[" || t == "{"; }
bool is_close(const std::string& t) { return t == ")" || t == "]" || t == "}"; }

// The names a binding or parameter list declares: toks[from, to). A key before `:` inside `{}` is not one, and neither is
// the value after a `=` (a default).
void collect_pattern(const std::vector<Tok>& toks, size_t from, size_t to, std::set<std::string>& names) {
    std::vector<std::string> stack;
    bool skip = false;
    size_t skipDepth = 0;
    for (size_t k = from; k < to; ++k) {
        const std::string& t = toks[k].text;
        if (is_open(t)) {
            stack.push_back(t);
        } else if (is_close(t)) {
            if (!stack.empty()) stack.pop_back();
            if (skip && stack.size() < skipDepth) skip = false;
        } else if (t == ",") {
            if (skip && stack.size() == skipDepth) skip = false;
        } else if (t == "=") {
            if (!skip) {
                skip = true;
                skipDepth = stack.size();
            }
        } else if (!skip && toks[k].ident) {
            const bool key = !stack.empty() && stack.back() == "{" && k + 1 < to && toks[k + 1].text == ":";
            if (!key) names.insert(t);
        }
    }
}

bool is_keyword_before_paren(const std::string& t) {
    static const std::set<std::string> kw = {"if",    "for",   "while", "switch", "with",   "return", "typeof",
                                             "await", "yield", "in",    "of",     "new",    "delete", "void",
                                             "throw", "else",  "case",  "do",     "import", "super",  "function"};
    return kw.count(t) > 0;
}

// A method declaration `name(a, b) { ... }` follows the start of a body, a member or a modifier: not `x = name(a) {`.
bool is_member_start(const std::string& prev) {
    static const std::set<std::string> ok = {"{", "}", ";", ",", "static", "async", "get", "set", "*"};
    return ok.count(prev) > 0;
}

// Names a block declares itself, from its code with strings and comments blanked.
std::set<std::string> declared_names(const std::string& code) {
    std::set<std::string> names;
    const std::vector<Tok> toks = tokenize(code);
    std::vector<size_t> match(toks.size(), size_t(-1));  // the closing bracket of each opening one
    {
        std::vector<size_t> st;
        for (size_t i = 0; i < toks.size(); ++i) {
            if (is_open(toks[i].text)) {
                st.push_back(i);
            } else if (is_close(toks[i].text) && !st.empty()) {
                match[st.back()] = i;
                st.pop_back();
            }
        }
    }
    auto params_at = [&](size_t open) {  // toks[open] is "("
        if (match[open] != size_t(-1)) collect_pattern(toks, open + 1, match[open], names);
    };
    std::map<size_t, size_t> openOf;  // closing bracket -> opening one
    for (size_t i = 0; i < toks.size(); ++i)
        if (match[i] != size_t(-1)) openOf[match[i]] = i;
    for (size_t i = 0; i < toks.size(); ++i) {
        const std::string& t = toks[i].text;
        const bool hasNext = i + 1 < toks.size();
        if ((t == "const" || t == "let" || t == "var") && hasNext) {
            const size_t j = i + 1;
            // `const a = 1, world = 2`: every declarator of the list, until a `;` or the end of the enclosing bracket
            size_t pos = j;
            for (bool more = true; more && pos < toks.size();) {
                more = false;
                size_t after = pos + 1;
                if (toks[pos].ident) {
                    names.insert(toks[pos].text);
                } else if ((toks[pos].text == "[" || toks[pos].text == "{") && match[pos] != size_t(-1)) {
                    collect_pattern(toks, pos, match[pos] + 1, names);
                    after = match[pos] + 1;
                } else {
                    break;
                }
                int depth = 0;
                for (size_t k = after; k < toks.size(); ++k) {
                    const std::string& u = toks[k].text;
                    if (is_open(u)) {
                        ++depth;
                    } else if (is_close(u)) {
                        if (--depth < 0) break;
                    } else if (depth == 0 &&
                               (u == ";" || u == "const" || u == "let" || u == "var" || u == "function" ||
                                u == "class" || u == "return" || u == "if" || u == "for" || u == "while")) {
                        break;
                    } else if (depth == 0 && u == "," && k + 1 < toks.size() &&
                               (toks[k + 1].ident || toks[k + 1].text == "[" || toks[k + 1].text == "{")) {
                        pos = k + 1;
                        more = true;
                        break;
                    }
                }
            }
        } else if ((t == "function" || t == "class") && hasNext) {
            size_t j = i + 1;
            if (toks[j].text == "*" && j + 1 < toks.size()) ++j;
            if (toks[j].ident && toks[j].text != "extends") names.insert(toks[j].text);
            if (t == "function") {
                while (j < toks.size() && toks[j].text != "(" && toks[j].text != "{" && toks[j].text != ";") ++j;
                if (j < toks.size() && toks[j].text == "(") params_at(j);
            }
        } else if (t == "catch" && hasNext && toks[i + 1].text == "(") {
            params_at(i + 1);
        } else if (t == "=>" && i > 0) {
            if (toks[i - 1].ident) {
                names.insert(toks[i - 1].text);  // x => ...
            } else if (toks[i - 1].text == ")") {
                auto it = openOf.find(i - 1);
                if (it != openOf.end()) params_at(it->second);  // (a, { b }) => ...
            }
        } else if (toks[i].ident && hasNext && toks[i + 1].text == "(" && !is_keyword_before_paren(t) &&
                   match[i + 1] != size_t(-1) && match[i + 1] + 1 < toks.size() && toks[match[i + 1] + 1].text == "{" &&
                   (i == 0 || is_member_start(toks[i - 1].text))) {
            params_at(i + 1);  // a method: name(a, b) { ... }
        }
    }
    return names;
}

// What the imports of a block say (read from the raw code: the module name is a string).
struct ImportInfo {
    std::set<std::string> declared;  // local names that are not a root of the typings
    bool fromTest = false;           // imports from "factoria:test"
};

ImportInfo read_imports(const std::string& code) {
    static const std::regex importRe(R"re(\bimport\s+((?:[\w$*, \t]|\{[^}]*\})*?)\s*from\s*["']([^"']+)["'])re");
    static const std::regex itemRe(R"(([\w$]+)(?:\s+as\s+([\w$]+))?)");
    ImportInfo info;
    for (auto it = std::sregex_iterator(code.begin(), code.end(), importRe); it != std::sregex_iterator(); ++it) {
        const std::string clause = (*it)[1], module = (*it)[2];
        const bool engine = module == "factoria" || module == "factoria:test";
        if (module == "factoria:test") info.fromTest = true;
        for (auto m = std::sregex_iterator(clause.begin(), clause.end(), itemRe); m != std::sregex_iterator(); ++m) {
            const std::string first = (*m)[1], alias = (*m)[2];
            if (first == "type") continue;
            if (!alias.empty()) {
                info.declared.insert(alias);  // `{ world as w }`, `* as fa`: w is not the root
            } else if (!engine && first != "as") {
                info.declared.insert(first);
            }
        }
        if (clause.find("* as") != std::string::npos && engine) {  // `import * as f from "factoria"`: f is a namespace
            const size_t at = clause.find("* as");
            size_t k = at + 4;
            skip_spaces(clause, k);
            info.declared.insert(take_ident(clause, k));
        }
    }
    return info;
}

std::string describe_candidates(const std::map<std::string, std::string>& members, const std::string& name) {
    std::vector<std::string> names;
    for (const auto& kv : members) names.push_back(kv.first);
    return did_you_mean(name, names);
}

std::string problem_line(const Block& b, int line, const std::string& what, const std::string& hint) {
    return "  " + b.file + ":" + std::to_string(line) + ": `" + what + "` is not in the script API" +
           (hint.empty() ? "" : " (" + hint + ")") + "\n";
}

// Problems of the API names of one block ("" when none).
std::string api_problems(const Typings& ty, const Block& b) {
    const std::string code = strip_text(b.code);
    const ImportInfo imports = read_imports(b.code);
    std::map<std::string, std::string> roots = ty.roots;
    if (b.skipNames) return "";
    std::set<std::string> declared = declared_names(code);
    declared.insert(imports.declared.begin(), imports.declared.end());
    const std::vector<Tok> toks = tokenize(code);
    // test()/expect()... of the test module; a function of the game that is called test( or it( is a declaration
    static const std::set<std::string> testFns = {"test", "it", "describe", "expect", "robust", "beforeEach"};
    bool testCode = imports.fromTest;
    for (size_t i = 0; i + 1 < toks.size() && !testCode; ++i)
        testCode = testFns.count(toks[i].text) && toks[i + 1].text == "(" && !declared.count(toks[i].text) &&
                   (i == 0 || toks[i - 1].text != ".");
    if (testCode)
        for (const auto& kv : ty.testRoots) roots[kv.first] = kv.second;
    std::string out;
    std::set<std::string> reported;
    for (size_t i = 0; i < toks.size(); ++i) {
        // `a.world` is a property; `...world.items` (three dots) is a spread of the root
        const bool spread = i >= 3 && toks[i - 1].text == "." && toks[i - 2].text == "." && toks[i - 3].text == ".";
        if (!toks[i].ident || (i > 0 && toks[i - 1].text == "." && !spread)) continue;
        const std::string& root = toks[i].text;
        if (declared.count(root)) continue;
        auto rt = roots.find(root);
        auto st = ty.statics.find(root);
        const bool isRoot = rt != roots.end();
        if (!isRoot && (st == ty.statics.end() || st->second.members.empty())) continue;
        // walk the chain `.a.b` (also `?.a`)
        std::string curType = isRoot ? rt->second : "";
        std::string path = root;
        size_t k = i + 1;
        bool first = true;
        while (k + 1 < toks.size() && (isRoot || first)) {
            size_t d = k;
            if (toks[d].text == "?" && d + 1 < toks.size() && toks[d + 1].text == ".") ++d;
            if (toks[d].text != "." || d + 1 >= toks.size() || !toks[d + 1].ident) break;
            // `..` or `...` is a spread, not a member access
            if (d > 0 && toks[d - 1].text == ".") break;
            const std::string& name = toks[d + 1].text;
            const int line = b.line + 1 + int(std::count(code.begin(), code.begin() + toks[i].pos, '\n'));
            std::string next;
            bool ok;
            std::string hint;
            if (isRoot) {
                ok = member_of(ty, curType, name, &next);
                if (!ok) {
                    auto it = ty.types.find(curType);
                    if (it != ty.types.end()) hint = describe_candidates(it->second.members, name);
                }
            } else {
                ok = st->second.members.count(name) > 0 || (ty.types.count(root) && name == "prototype");
                if (!ok) hint = describe_candidates(st->second.members, name);
            }
            if (!ok) {
                if (reported.insert(path + "." + name + "@" + std::to_string(line)).second)
                    out += problem_line(b, line, path + "." + name, hint);
                break;
            }
            path += "." + name;
            curType = next;
            k = d + 2;
            first = false;
            if (curType.empty()) break;
        }
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------- parsing
// QuickJS asks for every imported module while it compiles: each one is an empty module, only the syntax is checked.
JSModuleDef* empty_module(JSContext* ctx, const char* name, void*) {
    static const std::string src = "export {};";
    JSValue v = JS_Eval(ctx, src.c_str(), src.size(), name, JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(v)) return nullptr;
    auto* m = static_cast<JSModuleDef*>(JS_VALUE_GET_PTR(v));
    JS_FreeValue(ctx, v);
    return m;
}

std::string parse_problem(const Block& b) {
    JSRuntime* rt = JS_NewRuntime();
    JS_SetModuleLoaderFunc(rt, nullptr, &empty_module, nullptr);
    JSContext* ctx = JS_NewContext(rt);
    const std::string name = b.file + ":" + std::to_string(b.line);
    JSValue v =
        JS_Eval(ctx, b.code.c_str(), b.code.size(), name.c_str(), JS_EVAL_TYPE_MODULE | JS_EVAL_FLAG_COMPILE_ONLY);
    std::string text;
    if (JS_IsException(v)) {
        JSValue ex = JS_GetException(ctx);
        if (const char* s = JS_ToCString(ctx, ex)) {
            text = s;
            JS_FreeCString(ctx, s);
        }
        JS_FreeValue(ctx, ex);
    }
    JS_FreeValue(ctx, v);
    JS_FreeContext(ctx);
    JS_FreeRuntime(rt);
    return text;
}

}  // namespace

TEST_CASE("docs js: the scanner finds blocks, fragments and API names") {
    const auto blocks = js_blocks_of(
        "docs/X.md", "a\n```js\nworld.find(\"a\");\n```\n  ```js fragment\n  { a: 1 }\n  ```\n```json\n{}\n```\n");
    REQUIRE(blocks.size() == 2);
    CHECK(blocks[0].line == 2);
    CHECK_FALSE(blocks[0].fragment);
    CHECK(blocks[1].fragment);
    CHECK(blocks[1].code == "{ a: 1 }\n");
    CHECK(strip_text("a // x.y\nb(\"w.q\") /* z.z */").find('.') == std::string::npos);

    Typings ty;
    ty.roots["ui"] = "UIAPI";
    ty.types["UIAPI"].members["layout"] = "";
    ty.types["UIAPI"].members["inner"] = "Inner";
    ty.types["Inner"].members["deep"] = "";
    Block b;
    b.file = "docs/X.md";
    b.line = 10;
    b.code = "ui.layout(); ui.inner.deep; ui.layot(); ui.inner.deeep; const x = a.ui.nope;\n";
    const std::string p = api_problems(ty, b);
    CHECK(p.find("docs/X.md:11: `ui.layot` is not in the script API") != std::string::npos);
    CHECK(p.find("`ui.inner.deeep`") != std::string::npos);
    CHECK(p.find("nope") == std::string::npos);
    b.code = "const ui = {}; ui.anything;\n";
    CHECK(api_problems(ty, b).empty());
    // an import from "factoria" is the root itself: it is checked, not a declaration
    b.code = "import { ui } from \"factoria\";\nui.layot();\n";
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
    b.code = "import { ui as u } from \"factoria\";\nui.layot();\n";  // only the alias is local
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
    b.code = "import { ui } from \"./other.js\";\nui.layot();\n";
    CHECK(api_problems(ty, b).empty());
    // a call argument is not a declaration; a parameter, a destructuring and a loop variable are
    b.code = "foo(ui); ui.layot();\n";
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
    b.code = "function f(a, ui) { ui.layot(); }\n";
    CHECK(api_problems(ty, b).empty());
    b.code = "const g = ({ ui }) => ui.layot();\nfor (const [i, ui] of xs) ui.layot();\nconst [a, ui2] = y; ui2.q;\n";
    CHECK(api_problems(ty, b).empty());
    b.code = "const f = [...ui.layot];\n";  // a spread is not a property access
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
    b.code = "const a = 1, ui = {};\nui.layot();\n";  // a second declarator declares too
    CHECK(api_problems(ty, b).empty());
    b.code = "let a = f(1, 2), [b, ui] = y;\nui.layot();\n";
    CHECK(api_problems(ty, b).empty());
    b.code = "const a = 1;\nx = foo(ui) {\n};\nui.layot();\n";  // `foo(ui) {` after `=` is no method
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
    b.code = "class A {\n  run(ui) { ui.layot(); }\n}\n";  // a real method
    CHECK(api_problems(ty, b).empty());
    b.code = "import {\n  test,\n  game\n} from \"factoria:test\";\n";  // a multi-line import is read
    CHECK(read_imports(b.code).fromTest);
    ty.testRoots["game"] = "GameAPI";
    ty.types["GameAPI"].members["ok"] = "";
    b.code = "import {\n  test,\n  game\n} from \"factoria:test\";\ngame.nope();\n";
    CHECK(api_problems(ty, b).find("`game.nope`") != std::string::npos);
    b.code = "function test(x) { return x; }\ntest(1);\ngame.nope();\n";  // the game's own test(): not the test module
    CHECK(api_problems(ty, b).empty());
    b.code = "ui.layot();\n";
    b.skipNames = true;  // ```js names-skip
    CHECK(api_problems(ty, b).empty());
    b.skipNames = false;
    b.code = "const t = `a ${ui.layot()} b`;\n";  // code inside ${} is checked
    CHECK(api_problems(ty, b).find("`ui.layot`") != std::string::npos);
}

TEST_CASE("docs js: every js block of docs/ parses and uses only names of the script API") {
    const std::vector<Block> blocks = all_blocks();
    CHECK(blocks.size() > 100);  // the scan finds the blocks at all
    const Typings ty = parse_typings(typings_text());
    REQUIRE(ty.roots.count("world"));
    REQUIRE(ty.roots.count("ui"));
    REQUIRE(ty.statics.count("tween"));

    std::string syntax, names;
    for (const Block& b : blocks) {
        if (!b.fragment) {
            const std::string err = parse_problem(b);
            if (!err.empty()) syntax += "  " + b.file + ":" + std::to_string(b.line) + ": " + err + "\n";
        }
        names += api_problems(ty, b);
    }
    CHECK_MESSAGE(syntax.empty(),
                  "A js block of the docs does not parse. Fix the code; when the block is only a piece of a script "
                  "(an object literal, `...`, a `return`), open it with ```js fragment instead:\n"
                      << syntax);
    CHECK_MESSAGE(
        names.empty(),
        "A js block of the docs uses a name the script typings do not have (`factoria api --dts`). Fix the doc "
        "to the real API, never the API to the doc:\n"
            << names);
}
