// The names and numbers the docs state (docs/*.md and docs/<topic>/*.md, docs/design/ included; not docs/i18n, not the
// generated references docs/reference/ and docs/COMPONENTS.md) are the ones the engine has. A doc that names a command or a
// field that is not there sends an AI to a call that fails: fix the doc, never add API to make a doc pass.
//
// What is checked, and what is deliberately left alone (so a false positive stays rare):
// - Commands. An inline `code` span (outside fenced blocks) whose first word is a dotted lower-case name, `ns.name` (the word
//   ends the span or is followed by a space, `{`, `,` or `:`), and whose `ns` is the namespace of at least one registered
//   command (scene, project, assets...) must be a command of the registry the `factoria` binary builds for a project (the
//   same one api_since_test.cpp uses; plugin commands such as steam.* are not loaded, their namespace is unknown and so they
//   are ignored), or a script API key (`world.spawn`: some roots, like `audio`, are both). Not checked: a word followed by
//   `(`, `*`, `<`, `[` or `.` (a JS call, a wildcard, a placeholder, a longer path), a file name (last part `json`, `md`,
//   `js`...). Many dotted words are not commands (a settings key `style.prompt`, an event `music.ended`, a host name, a tool
//   of the game `project.spawn_wave`): a name counts only when the text says it is a command (arguments in braces, the word
//   "command" or "tool" next to it, `factoria call`) or when it is one edit from a real command of its namespace (a typo);
//   in a namespace that is also a script root (`game`, `ui`, `scene`) only the words around it count, not braces; a
//   `project.<x>` that is no command is a tool of the game. A name right after "no", "not", "never" or "without" ("there is
//   no `Text.italic`") is a statement that it does not exist, and is not checked. In fenced blocks only `factoria call
//   <name>` is read.
// - Components. A span that is exactly a PascalCase word is a component name when the registry has it. An unknown PascalCase
//   word is reported only when it names a component by its place ("the `Foo` component", "component `Foo`") or is one
//   edit from a real one (`Sprites`): any other PascalCase word (a JS class, a C++ type, a file format) is ignored.
// - Fields. A span that starts with `Comp.field` (Comp a real component, followed by end, space, `=`, `,`, `:` or `.`) must
//   name a field of Comp. `Comp.field` with an unknown Comp is checked only when Comp is one edit from a real one.
// - Numbers. A few figures a reader relies on (the size caps of MCP results and descriptions, the 60 KB page budget) are
//   read from the source constant that sets them and compared with the sentence that states them; see kFigures. A figure
//   that was measured on a version ("372 commands of the 0.19.0 engine") is a dated fact, not a claim, and is not checked.
// A report line names file:line, the name, what is close ("did you mean") and what to do.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <string>
#include <vector>

#include "fa/ai/commands.h"
#include "fa/core/command.h"
#include "fa/core/fs.h"
#include "fa/core/reflect.h"
#include "fa/core/strings.h"
#include "fa/runtime/engine.h"
#include "fa/scene/components.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/tooling.h"
#include "fa_test_paths.h"
#include "test_helpers.h"

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct Names {
    std::set<std::string> commands;
    std::set<std::string> namespaces;
    std::set<std::string> script;
    std::set<std::string> jsRoots;  // namespaces that are a command namespace and a script root (`scene`, `game`, `ui`)
    std::map<std::string, std::set<std::string>> components;  // name -> field names
};

Names collect_names() {
    Names n;
    ensure_builtin_components();
    for (const Json& t : TypeRegistry::global().describe_all()) {
        std::set<std::string>& fields = n.components[t["name"].get<std::string>()];
        for (const Json& f : t["fields"]) fields.insert(f["name"].get<std::string>());
    }
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
        register_project_commands(engine, tmp.str());
        ai::AiCommandOptions ao;
        const std::string dir = tmp.str();
        ao.projectDir = [dir]() { return dir; };
        ai::register_ai_commands(engine.commands(), ao);
        for (const CommandInfo* c : engine.commands().list()) {
            n.commands.insert(c->name);
            const size_t dot = c->name.find('.');
            if (dot != std::string::npos) n.namespaces.insert(c->name.substr(0, dot));
        }
        for (const std::string& k : engine.scripts().script_api_keys()) n.script.insert(k);
        const std::string dts = export_typescript(engine.scripts());
        static const std::regex root(R"(\n  export (?:const|namespace) ([A-Za-z_$][\w$]*))");
        for (auto it = std::sregex_iterator(dts.begin(), dts.end(), root); it != std::sregex_iterator(); ++it)
            if (n.namespaces.count((*it)[1].str())) n.jsRoots.insert((*it)[1].str());
        engine.shutdown();
    }
    fs::set_project_root(savedRoot);
    return n;
}

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

struct DocFile {
    std::string rel;  // below the checkout, '/'
    std::string text;
};

std::vector<DocFile> doc_files() {
    std::vector<DocFile> out;
    const stdfs::path root = stdfs::path(FA_REPO_ROOT);
    std::vector<stdfs::path> files;
    for (const auto& e : stdfs::recursive_directory_iterator(root / "docs"))
        if (e.is_regular_file() && e.path().extension() == ".md") files.push_back(e.path());
    std::sort(files.begin(), files.end());
    for (const stdfs::path& p : files) {
        const std::string rel = p.lexically_relative(root).generic_string();
        if (fa::starts_with(rel, "docs/i18n/") || fa::starts_with(rel, "docs/reference/") ||
            rel == "docs/COMPONENTS.md")
            continue;
        out.push_back({rel, testing::read_all(p)});
    }
    return out;
}

struct Span {
    std::string text;
    size_t end = 0;  // offset in the line after the closing backticks
};

// The inline code spans of one line (a run of N backticks closes at the next run of exactly N).
std::vector<Span> spans_of(const std::string& line) {
    std::vector<Span> out;
    size_t i = 0;
    while (i < line.size()) {
        if (line[i] != '`') {
            ++i;
            continue;
        }
        size_t j = i;
        while (j < line.size() && line[j] == '`') ++j;
        const size_t n = j - i;
        size_t k = j;
        bool closed = false;
        while (k < line.size()) {
            if (line[k] != '`') {
                ++k;
                continue;
            }
            size_t m = k;
            while (m < line.size() && line[m] == '`') ++m;
            if (m - k == n) {
                closed = true;
                break;
            }
            k = m;
        }
        if (!closed) break;
        std::string t = line.substr(j, k - j);
        const size_t a = t.find_first_not_of(' ');
        const size_t b = t.find_last_not_of(' ');
        t = a == std::string::npos ? "" : t.substr(a, b - a + 1);
        out.push_back({t, k + n});
        i = k + n;
    }
    return out;
}

bool is_file_extension(const std::string& s) {
    static const std::set<std::string> ext = {
        "json", "md",    "js",     "ts",    "mjs", "png",   "jpg",  "jpeg", "ogg", "wav",  "mp3",  "glb",
        "gltf", "obj",   "fbx",    "html",  "txt", "yml",   "yaml", "toml", "cpp", "h",    "hpp",  "cmake",
        "sh",   "ps1",   "svg",    "ttf",   "otf", "woff",  "zip",  "gz",   "tar", "apk",  "aab",  "ipa",
        "exe",  "dll",   "so",     "dylib", "xml", "plist", "wasm", "pak",  "csv", "glsl", "frag", "vert",
        "wgsl", "scene", "prefab", "anim",  "mat", "model", "ase",  "psd",  "kra", "mid",  "midi"};
    return ext.count(s) > 0;
}

std::vector<std::string> sorted(const std::set<std::string>& s) { return {s.begin(), s.end()}; }

std::string hint_for(const std::string& name, const std::set<std::string>& pool) {
    const std::vector<std::string> cands = sorted(pool);
    const std::string close = closest_match(name, cands);
    return close.empty() ? "" : " Did you mean `" + close + "`?";
}

struct Checker {
    const Names& names;
    std::set<std::string> componentNames;
    std::vector<std::string> problems;
    int checkedCommands = 0, checkedComponents = 0, checkedFields = 0;

    explicit Checker(const Names& n) : names(n) {
        for (const auto& [k, v] : n.components) componentNames.insert(k);
    }

    void report(const DocFile& f, int line, const std::string& what) {
        problems.push_back(f.rel + ":" + std::to_string(line) + ": " + what);
    }

    // The component a PascalCase word is one edit from (a typo or a renamed component), or "".
    std::string near_component(const std::string& w) const {
        if (w.size() < 6) return "";
        for (const std::string& c : componentNames)
            if (c != w && edit_distance(w, c) == 1) return c;
        return "";
    }

    bool claimed_near(const std::string& name) const {
        for (const std::string& c : names.commands)
            if (fa::starts_with(c, "project.") && edit_distance(name, c) <= 1) return true;
        return false;
    }

    // `claimed`: the text says it is a command (arguments in braces, "command"/"tool"/"factoria call" around it). A name in a
    // namespace that is also a script root (`game`, `ui`, `scene`) is JS until the text says otherwise.
    void check_command(const DocFile& f, int line, const std::string& name, bool claimed) {
        if (names.commands.count(name)) {
            ++checkedCommands;
            return;
        }
        const std::string ns = name.substr(0, name.find('.'));
        if (names.script.count(name)) return;
        if (ns == "project" && !claimed_near(name)) return;  // a tool of the game (project.<file>) unless a typo
        if (!claimed && names.jsRoots.count(ns)) return;
        std::set<std::string> pool;
        for (const std::string& c : names.commands)
            if (fa::starts_with(c, ns + ".")) pool.insert(c);
        if (!claimed) {  // a settings key, a JSON path, a host name: only a typo of a real command of its namespace counts
            bool nearMiss = false;
            for (const std::string& c : pool) nearMiss = nearMiss || edit_distance(name, c) <= 1;
            if (!nearMiss) return;
        }
        ++checkedCommands;
        report(f, line,
               "`" + name + "` is not a command (and not a script API name)." +
                   hint_for(name, pool.empty() ? names.commands : pool) +
                   " Fix the doc, not the API: use the real name (`factoria commands` lists them).");
    }

    void check_span(const DocFile& f, int line, const std::string& line_text, const Span& sp, size_t begin) {
        const std::string& t = sp.text;
        static const std::regex dotted(R"(^([a-z][a-z0-9]*)((?:\.[a-z][a-z0-9_]*)+))");
        static const std::regex pascal(R"(^[A-Z][A-Za-z0-9]*$)");
        static const std::regex compField(R"(^([A-Z][A-Za-z0-9]*)\.([a-z][A-Za-z0-9_]*))");
        static const std::regex negated(R"(\b(?:no|not|never|without)\s+$)");
        static const std::regex cmdAfter(R"(^\s+(?:commands?|tools?)\b)");
        static const std::regex cmdBefore(R"(\b(?:commands?|tools?|call)\s+$)");
        static const std::regex compAfter(R"(^\s+components?\b)");
        static const std::regex compBefore(R"(\bcomponents?\s+$)");
        std::smatch m;
        const std::string before = line_text.substr(0, begin), after = line_text.substr(sp.end);
        if (std::regex_search(before, negated)) return;  // "there is no `x.y`"
        if (std::regex_search(t, m, dotted)) {
            const std::string word = m[0].str();
            const std::string rest = t.substr(word.size());
            const std::string ns = m[1].str();
            const std::string lastPart = word.substr(word.rfind('.') + 1);
            const bool endsOk = rest.empty() || rest[0] == ' ' || rest[0] == '{' || rest[0] == ',' || rest[0] == ':';
            const bool claimed = (rest.find('{') != std::string::npos && !names.jsRoots.count(ns)) ||
                                 std::regex_search(after, cmdAfter) || std::regex_search(before, cmdBefore);
            if (endsOk && names.namespaces.count(ns) && !is_file_extension(lastPart))
                check_command(f, line, word, claimed);
            return;
        }
        if (std::regex_match(t, pascal)) {
            ++checkedComponents;
            if (componentNames.count(t)) return;
            const bool byPlace = std::regex_search(after, compAfter) || std::regex_search(before, compBefore);
            const std::string near = near_component(t);
            if (byPlace || !near.empty())
                report(f, line,
                       "`" + t + "` is not a component." + (near.empty() ? "" : " Did you mean `" + near + "`?") +
                           " Fix the doc, not the API (`factoria components` lists the components).");
            return;
        }
        if (std::regex_search(t, m, compField)) {
            const std::string comp = m[1].str(), field = m[2].str();
            const std::string rest = t.substr(m[0].str().size());
            const bool endsOk =
                rest.empty() || rest[0] == ' ' || rest[0] == '=' || rest[0] == ',' || rest[0] == ':' || rest[0] == '.';
            if (!endsOk || is_file_extension(field)) return;
            auto it = names.components.find(comp);
            if (it == names.components.end()) {
                const std::string near = near_component(comp);
                if (!near.empty())
                    report(f, line,
                           "`" + comp + "." + field + "`: `" + comp + "` is not a component. Did you mean `" + near +
                               "`? Fix the doc, not the API.");
                return;
            }
            ++checkedFields;
            if (it->second.count(field)) return;
            report(f, line,
                   "`" + comp + "." + field + "`: `" + comp + "` has no field `" + field + "`." +
                       hint_for(field, it->second) + " Fix the doc, not the API (its fields: `factoria components " +
                       comp + "`).");
        }
    }

    void check_file(const DocFile& f) {
        const std::vector<std::string> lines = split_lines(f.text);
        std::string fence;
        for (size_t i = 0; i < lines.size(); ++i) {
            const std::string& l = lines[i];
            const size_t nb = l.find_first_not_of(" \t");
            if (nb != std::string::npos && (l.compare(nb, 3, "```") == 0 || l.compare(nb, 3, "~~~") == 0)) {
                const std::string run = l.substr(nb, l.find_first_not_of(l[nb], nb) - nb);
                if (fence.empty())
                    fence = run;
                else if (run.size() >= fence.size() && l.find_first_not_of(" \t", nb + run.size()) == std::string::npos)
                    fence.clear();  // a closing fence may carry trailing spaces (CommonMark)
                continue;
            }
            if (!fence.empty()) {
                static const std::regex call(
                    R"(\bfactoria call (?:--[a-z-]+(?: \S+)? )*([a-z][a-z0-9]*\.[a-z][a-z0-9_.]*)\b)");
                std::smatch m;
                if (std::regex_search(l, m, call) && names.namespaces.count(m[1].str().substr(0, m[1].str().find('.'))))
                    check_command(f, int(i) + 1, m[1].str(), true);
                continue;
            }
            size_t offset = 0;
            for (const Span& sp : spans_of(l)) {
                const size_t begin = l.find('`', offset);
                check_span(f, int(i) + 1, l, sp, begin);
                offset = sp.end;
                // `factoria call x.y` inside a span
                static const std::regex call(R"(^factoria call ([a-z][a-z0-9]*\.[a-z][a-z0-9_]*)(?:\s|$))");
                std::smatch m;
                if (std::regex_search(sp.text, m, call) &&
                    names.namespaces.count(m[1].str().substr(0, m[1].str().find('.'))))
                    check_command(f, int(i) + 1, m[1].str(), true);
            }
        }
    }
};

std::string join_problems(const std::vector<std::string>& p, size_t cap = 400) {
    std::string out;
    for (size_t i = 0; i < p.size() && i < cap; ++i) out += "\n  " + p[i];
    if (p.size() > cap) out += "\n  ... and " + std::to_string(p.size() - cap) + " more";
    return out;
}

// ------------------------------------------------------------------------------------------------ stated figures
struct Figure {
    const char* doc;       // the doc that states it
    const char* docRegex;  // group 1: the number
    double docUnit;        // bytes in one of the doc's unit
    const char* source;    // the file that sets it
    const char* srcRegex;  // group 1: the number, group 2 (optional): a multiplier `* 1024`
    double srcUnit;        // bytes in one unit of group 1
    const char* what;
};

const Figure kFigures[] = {
    {"docs/MCP.md", R"(result\s+over\s+(\d+)\s+KiB\s+of\s+JSON)", 1024, "tools/mcp/include/fa/mcp/server.h",
     R"(kMcpResultCap = (\d+) \* 1024)", 1024, "the size an MCP result is cut at (kMcpResultCap)"},
    {"docs/design/ARCHITECTURE_COMMANDS.md", R"(description\s+stays\s+under\s+(\d+(?:\.\d+)?)\s+KB)", 1024,
     "tools/cli/tests/mcp_description_budget_test.cpp", R"(kBudget = (\d+);)", 1,
     "the description budget of mcp_description_budget_test.cpp"},
    {"docs/design/ARCHITECTURE.md", R"(each\s+page\s+stays\s+under\s+(\d+)\s+KB)", 1024,
     "tools/common/tests/docs_test_util.h", R"(kDocBudgetBytes = (\d+);)", 1, "the page budget of docs_test_util.h"},
    {"docs/design/BUILDING.md", R"(each\s+page\s+stays\s+under\s+(\d+)\s+KB)", 1024,
     "tools/common/tests/docs_test_util.h", R"(kDocBudgetBytes = (\d+);)", 1, "the page budget of docs_test_util.h"},
};

}  // namespace

TEST_CASE("docs names: the scanner reads commands, components and fields") {
    Names n;
    n.commands = {"scene.add_entity", "project.create"};
    n.namespaces = {"scene", "project"};
    n.components = {{"Sprite", {"color", "layer"}}, {"RigidBody2D", {"mass"}}};
    Checker c(n);
    const DocFile f{
        "docs/X.md",
        "Use `scene.add_entity` and `project.create {\"a\": 1}`; and `scene.add_entty`, `project.json`, "
        "`world.spawn(`, `scene.*`.\n"
        "The `Sprite` component, the `Sprites` and the `Foo` component; `Sprite.colour = 1`, `Sprite.layer`, "
        "`Vec2`, `Sprites.layer`.\n"
        "```sh\nfactoria call scene.nope {}\nfactoria call scene.add_entity\n```\n"
        "```sh\nx\n```  \nThen `scene.add_entiy` is read again.\n"};
    c.check_file(f);
    const std::string all = join_problems(c.problems);
    CHECK_MESSAGE(c.problems.size() == 7, all);
    // A closing fence with trailing spaces closes the block: the span after it is read.
    CHECK(all.find("docs/X.md:10: `scene.add_entiy`") != std::string::npos);
    CHECK(all.find("docs/X.md:1: `scene.add_entty` is not a command") != std::string::npos);
    CHECK(all.find("Did you mean `scene.add_entity`?") != std::string::npos);
    CHECK(all.find("`Sprites` is not a component") != std::string::npos);
    CHECK(all.find("`Foo` is not a component") != std::string::npos);
    CHECK(all.find("`Sprite` has no field `colour`") != std::string::npos);
    CHECK(all.find("`Sprites.layer`: `Sprites` is not a component") != std::string::npos);
    CHECK(all.find("docs/X.md:4: `scene.nope`") != std::string::npos);
}

TEST_CASE("docs names: every command, component and field a doc names exists") {
    const Names names = collect_names();
    REQUIRE(names.commands.size() > 100);
    REQUIRE(names.components.count("Sprite") == 1);
    Checker c(names);
    const std::vector<DocFile> docs = doc_files();
    REQUIRE(docs.size() > 40);
    for (const DocFile& f : docs) c.check_file(f);
    // The scan must see names: a regex that reads nothing would pass silently.
    CHECK(c.checkedCommands > 200);
    CHECK(c.checkedComponents > 100);
    CHECK(c.checkedFields > 20);
    CHECK_MESSAGE(c.problems.empty(), c.problems.size()
                                          << " name(s) in the docs do not exist; fix each doc (the API is right):"
                                          << join_problems(c.problems));
}

TEST_CASE("docs names: the figures a doc states come from the source that sets them") {
    const stdfs::path root = stdfs::path(FA_REPO_ROOT);
    std::vector<std::string> problems;
    for (const Figure& fig : kFigures) {
        const std::string doc = testing::read_all(root / fig.doc);
        const std::string src = testing::read_all(root / fig.source);
        std::smatch dm, sm;
        if (!std::regex_search(doc, dm, std::regex(fig.docRegex))) {
            problems.push_back(std::string(fig.doc) + ": the sentence matching /" + fig.docRegex +
                               "/ is gone or was reworded: update kFigures in tools/common/tests/docs_names_test.cpp.");
            continue;
        }
        if (!std::regex_search(src, sm, std::regex(fig.srcRegex))) {
            problems.push_back(std::string(fig.source) + ": searched this file for /" + fig.srcRegex + "/ (" +
                               fig.what + ") and found nothing: the constant moved or was renamed; update kFigures.");
            continue;
        }
        const double stated = std::stod(dm[1].str()) * fig.docUnit;
        const double real = std::stod(sm[1].str()) * fig.srcUnit;
        if (stated != real)
            problems.push_back(std::string(fig.doc) + " states " + dm[1].str() + " (" + std::to_string(long(stated)) +
                               " bytes) for " + fig.what + ", which is " + std::to_string(long(real)) + " bytes in " +
                               fig.source + ". Fix the doc.");
    }
    CHECK_MESSAGE(problems.empty(), join_problems(problems));
}
