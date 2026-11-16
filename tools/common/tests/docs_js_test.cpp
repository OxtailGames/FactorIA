// The JavaScript of the docs (docs/**/*.md, docs/design/ included; not docs/i18n, not the generated references):
// every ```js / ```javascript block parses and names only members the script typings have.
//
// - Parse: the block is compiled (not run) as an ES module in the engine's QuickJS. A block that is a piece of a script
//   (an object literal, `...` for what is left out, a `return` outside a function) is marked ```js fragment and is not
//   parsed; keep that marker rare. The API names of a fragment are still checked.
// - API names: `root.member` (and `root.member.member` while the member's declared type is an interface of the typings)
//   for every root the typings export as a const (`world`, `ui`, `input`, ...), a namespace (`tween`) or a class (static
//   members: `Vec2.zero`). Strings and comments are ignored; a root the block declares itself is skipped. It is a name
//   check, not a type checker.
// The typings are the ones `factoria api --dts` writes, produced in memory by the engine that is running.
#include <doctest.h>

#include <algorithm>
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

void add_member(TypeInfo& t, const std::string& line, bool wantStatic) {
    if (std::regex_search(line, std::regex(R"(^    (?:readonly\s+)?\[)"))) t.indexed = true;
    static const std::regex m(
        R"(^    (static\s+)?(?:readonly\s+|get\s+|set\s+)*([A-Za-z_$][\w$]*)\s*(\??)\s*([:(<])\s*([\w$]*)([^;]*))");
    std::smatch r;
    if (!std::regex_search(line, r, m)) return;
    const bool isStatic = r[1].matched;
    if (isStatic != wantStatic) return;
    std::string type;
    if (r[4] == ":" && r[6].str().empty()) type = r[5];  // `name: Type;` and nothing after the identifier
    t.members[r[2]] = type;
}

Typings parse_typings(const std::string& dts) {
    Typings ty;
    static const std::regex declType(R"(^  export (?:interface|class) ([\w$]+)(?: extends ([\w$]+))?[^{]*\{$)");
    static const std::regex declNs(R"(^  export namespace ([\w$]+) \{$)");
    static const std::regex declConst(R"(^  export const ([\w$]+): ([\w$]+);$)");
    static const std::regex declFn(R"(^  export function ([\w$]+)\()");
    static const std::regex nsMember(R"(^    (?:function|const|let) ([\w$]+))");
    std::string cur;
    bool inTest = false;
    enum { None, Type, Ns } mode = None;
    for (const std::string& line : split_lines(dts)) {
        std::smatch m;
        if (line.rfind("declare module ", 0) == 0) inTest = line.find("factoria:test") != std::string::npos;
        if (mode == None) {
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
        } else if (std::regex_search(line, m, nsMember)) {
            ty.statics[cur].members[m[1]] = "";
        }
    }
    return ty;
}

std::string typings_text() {
    std::string dts;
    testing::TempDir tmp;
    const stdfs::path savedRoot = fs::project_root();
    REQUIRE(create_project(tmp.str(), "2d-empty", {}).ok());
    fs::set_project_root(tmp.str());
    {
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
    }
    fs::set_project_root(savedRoot);
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
// The code of a block with comments and the contents of string literals blanked out (newlines kept).
std::string strip_text(const std::string& s) {
    std::string out = s;
    for (size_t i = 0; i < s.size();) {
        const char c = s[i];
        if (c == '/' && i + 1 < s.size() && s[i + 1] == '/') {
            while (i < s.size() && s[i] != '\n') out[i++] = ' ';
        } else if (c == '/' && i + 1 < s.size() && s[i + 1] == '*') {
            const size_t end = s.find("*/", i + 2);
            const size_t stop = end == std::string::npos ? s.size() : end + 2;
            for (; i < stop; ++i)
                if (s[i] != '\n') out[i] = ' ';
        } else if (c == '"' || c == '\'' || c == '`') {
            ++i;
            while (i < s.size() && s[i] != c && !(s[i] == '\n' && c != '`')) {
                if (s[i] == '\\' && i + 1 < s.size()) out[i++] = ' ';
                if (s[i] != '\n') out[i] = ' ';
                ++i;
            }
            if (i < s.size()) ++i;
        } else {
            ++i;
        }
    }
    return out;
}

bool declares(const std::string& code, const std::string& name) {
    const std::string n = std::regex_replace(name, std::regex(R"(\$)"), R"(\$)");
    return std::regex_search(code, std::regex("\\b(?:const|let|var|function|class)\\s+" + n + "\\b")) ||
           std::regex_search(code, std::regex("[(,]\\s*" + n + "\\s*[,)=]")) ||  // a parameter or a destructured name
           std::regex_search(code, std::regex("\\b" + n + "\\s*=>")) ||
           std::regex_search(code, std::regex("[{,]\\s*(?:[\\w$]+\\s*:\\s*)?" + n + "\\s*[,}]\\s*=")) ||
           std::regex_search(code, std::regex("\\bimport\\b[^;\\n]*\\b" + n + "\\b"));
}

bool ident_char(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '$'; }

std::string describe_candidates(const std::map<std::string, std::string>& members, const std::string& name) {
    std::vector<std::string> names;
    for (const auto& kv : members) names.push_back(kv.first);
    return did_you_mean(name, names);
}

// Problems of the API names of one block ("" when none).
std::string api_problems(const Typings& ty, const Block& b) {
    // A block that imports from "factoria:test", or is a test (test(...), expect(...)), reads that module's roots (its `game`) over the others.
    std::map<std::string, std::string> roots = ty.roots;
    static const std::regex testCode(R"(factoria:test|\b(?:test|it|describe|expect|robust|beforeEach)\()");
    if (std::regex_search(b.code, testCode))
        for (const auto& kv : ty.testRoots) roots[kv.first] = kv.second;
    const std::string code = strip_text(b.code);
    std::string out;
    std::set<std::string> reported;
    for (const auto& [root, type] : roots) {
        if (declares(code, root)) continue;
        size_t at = 0;
        while ((at = code.find(root, at)) != std::string::npos) {
            const size_t start = at;
            at += root.size();
            if (start > 0 && (ident_char(code[start - 1]) || code[start - 1] == '.')) continue;
            // `root?.a` is read like `root.a`
            size_t p = at;
            std::string curType = type;
            std::string path = root;
            while (p < code.size() && !curType.empty()) {
                if (code[p] == '?' && p + 1 < code.size() && code[p + 1] == '.') ++p;
                if (code[p] != '.') break;
                size_t q = p + 1;
                while (q < code.size() && ident_char(code[q])) ++q;
                const std::string name = code.substr(p + 1, q - p - 1);
                if (name.empty()) break;
                std::string next;
                if (!member_of(ty, curType, name, &next)) {
                    const int line = b.line + 1 + int(std::count(code.begin(), code.begin() + start, '\n'));
                    const std::string key = path + "." + name + "@" + std::to_string(line);
                    if (reported.insert(key).second) {
                        std::string hint;
                        auto it = ty.types.find(curType);
                        if (it != ty.types.end()) hint = describe_candidates(it->second.members, name);
                        out += "  " + b.file + ":" + std::to_string(line) + ": `" + path + "." + name +
                               "` is not in the script API";
                        out += hint.empty() ? "" : " (" + hint + ")";
                        out += "\n";
                    }
                    break;
                }
                path += "." + name;
                curType = next;
                p = q;
            }
        }
    }
    // Namespaces and classes: static members.
    static const std::regex staticRef(R"((^|[^\w$.])([A-Z_a-z$][\w$]*)\.([A-Za-z_$][\w$]*))");
    for (auto it = std::sregex_iterator(code.begin(), code.end(), staticRef); it != std::sregex_iterator(); ++it) {
        const std::string root = (*it)[2], name = (*it)[3];
        auto st = ty.statics.find(root);
        if (st == ty.statics.end() || roots.count(root) || declares(code, root)) continue;
        if (st->second.members.empty()) continue;  // a function or a class without static members
        if (st->second.members.count(name)) continue;
        if (ty.types.count(root) && name == "prototype") continue;
        const int line = b.line + 1 + int(std::count(code.begin(), code.begin() + it->position(2), '\n'));
        if (!reported.insert(root + "." + name + "@" + std::to_string(line)).second) continue;
        const std::string hint = describe_candidates(st->second.members, name);
        out += "  " + b.file + ":" + std::to_string(line) + ": `" + root + "." + name + "` is not in the script API";
        out += hint.empty() ? "" : " (" + hint + ")";
        out += "\n";
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------- parsing
// Every import resolves to an empty module: only the syntax of the block is checked.
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
