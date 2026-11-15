// tools/common/api_since.json says which FactorIA version added each component, field and command; the generated
// reference (docs/COMPONENTS.md, `factoria api`, MCP) shows it. These tests keep the file complete and honest.
#include <doctest.h>

#include <algorithm>
#include <filesystem>
#include <map>
#include <regex>
#include <set>

#include "fa/ai/commands.h"
#include "fa/core/capability.h"
#include "fa/core/command.h"
#include "fa/core/deprecation.h"
#include "fa/core/engine_version.h"
#include "fa/core/fs.h"
#include "fa/core/reflect.h"
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

const std::string kFile = "tools/common/api_since.json";

Json read_since_file() {
    const std::string text = testing::read_all(stdfs::path(FA_REPO_ROOT) / kFile);
    Json j = Json::parse(text, nullptr, false);
    REQUIRE_MESSAGE(j.is_object(),
                    kFile << " must be a JSON object {\"components\": {...}, \"commands\": {...}, \"script\": {...}}.");
    return j;
}

std::set<std::string> component_names() {
    ensure_builtin_components();
    std::set<std::string> out;
    for (const Json& t : TypeRegistry::global().describe_all()) {
        const std::string name = t["name"].get<std::string>();
        out.insert(name);
        for (const Json& f : t["fields"]) out.insert(name + "." + f["name"].get<std::string>());
    }
    return out;
}

// The commands the factoria binary registers for a project (plugin commands such as steam.* are not loaded here).
template <class Fn>
void with_command_registry(Fn fn) {
    testing::TempDir tmp;
    const stdfs::path savedRoot = fs::project_root();
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
    register_project_commands(engine, tmp.str());
    ai::AiCommandOptions ao;
    const std::string dir = tmp.str();
    ao.projectDir = [dir]() { return dir; };
    ai::register_ai_commands(engine.commands(), ao);
    fn(engine);
    engine.shutdown();
    fs::set_project_root(savedRoot);
}

std::set<std::string> script_names() {
    std::set<std::string> out;
    with_command_registry([&](Engine& e) {
        for (const std::string& k : e.scripts().script_api_keys()) out.insert(k);
    });
    return out;
}

std::set<std::string> command_names() {
    std::set<std::string> out;
    with_command_registry([&](Engine& e) {
        for (const CommandInfo* c : e.commands().list()) out.insert(c->name);
    });
    return out;
}

std::string missing_lines(const Json& file, const char* section, const std::set<std::string>& live) {
    std::string out;
    for (const std::string& n : live)
        if (!file.contains(section) || !file[section].contains(n))
            out += std::string("    \"") + n + "\": \"unreleased\",\n";
    return out;
}

std::string stale_lines(const Json& file, const char* section, const std::set<std::string>& live) {
    std::string out;
    if (!file.contains(section)) return out;
    for (auto it = file[section].begin(); it != file[section].end(); ++it)
        if (!live.count(it.key())) out += std::string("    \"") + it.key() + "\"\n";
    return out;
}

// The problems of a "deprecated" section (docs/design/ARCHITECTURE.md, "Versions"), one sentence each, for the current version
// `current` ("0.30.0"): an entry that names nothing that exists, whose replacement does not exist or is deprecated itself, that
// has neither replacement nor reason, whose `since` is not a version, or that is two or more minor versions old (the API and the
// entry go away: that is the whole policy). Empty when the section is fine.
std::vector<std::string> deprecated_problems(const Json& section, const std::string& current,
                                             const std::map<std::string, std::set<std::string>>& live) {
    std::vector<std::string> out;
    const std::regex version(R"((\d+)\.(\d+)\.(\d+))");
    std::smatch cur;
    REQUIRE(std::regex_match(current, cur, version));
    const long curMajor = std::stol(cur[1]), curMinor = std::stol(cur[2]);
    for (const char* kind : {"components", "commands", "script"}) {
        if (!section.contains(kind)) continue;
        const std::set<std::string>& names = live.at(kind);
        for (auto it = section[kind].begin(); it != section[kind].end(); ++it) {
            const std::string where = std::string("deprecated / ") + kind + " / \"" + it.key() + "\"";
            const Json& e = it.value();
            if (!e.is_object()) {
                out.push_back(
                    where +
                    " must be {\"since\": \"0.30.0\", \"use\": \"<replacement or empty>\", \"note\": \"...\"}.");
                continue;
            }
            const std::string since = e.value("since", ""), use = e.value("use", ""), note = e.value("note", "");
            if (!names.count(it.key()))
                out.push_back(where + " names something that no longer exists: remove the entry.");
            if (!use.empty() && !names.count(use))
                out.push_back(where + ": \"use\" is \"" + use + "\", which does not exist in \"" + kind +
                              "\". Name the replacement exactly as its key.");
            if (!use.empty() && section[kind].contains(use))
                out.push_back(where + ": \"use\" is \"" + use +
                              "\", which is deprecated itself. Point at the final replacement.");
            if (use.empty() && note.empty())
                out.push_back(where + " has no replacement and no reason: say in \"note\" what to do instead or why "
                                      "nothing replaces it.");
            std::smatch m;
            if (since == "unreleased") continue;
            if (!std::regex_match(since, m, version)) {
                out.push_back(where + ": \"since\" must be \"unreleased\" or a version like \"0.30.0\", not " +
                              Json(since).dump() + ".");
                continue;
            }
            const long minors = (std::stol(m[1]) == curMajor) ? curMinor - std::stol(m[2]) : 1000;
            if (minors >= 2)
                out.push_back(where + " was deprecated in " + since + " and this is " + current +
                              ": two minor versions have passed. Remove the API (the " +
                              (std::string(kind) == "commands" ? "command"
                               : std::string(kind) == "script" ? "script export or member"
                                                               : "component or field") +
                              ") and this entry, and say so in CHANGELOG.md (docs/design/ARCHITECTURE.md, \"Versions\").");
        }
    }
    return out;
}

std::map<std::string, std::set<std::string>> live_names() {
    return {{"components", component_names()}, {"commands", command_names()}, {"script", script_names()}};
}

// Puts the file's own deprecated section back when a test that injected entries ends.
struct RestoreDeprecations {
    ~RestoreDeprecations() { install_deprecations(true); }
};

}  // namespace

TEST_CASE("api_since: every component, field and command has an entry") {
    const Json file = read_since_file();
    const std::string comps = missing_lines(file, "components", component_names());
    const std::string cmds = missing_lines(file, "commands", command_names());
    const std::string scripts = missing_lines(file, "script", script_names());
    CHECK_MESSAGE(scripts.empty(), "Add these lines to \"script\" in "
                                       << kFile
                                       << " (a new script export or member is not in any release yet; "
                                          "keys: the name of an export of the \"factoria\" module, \"Type.member\" for "
                                          "a member, \"test:\" in front for the "
                                          "\"factoria:test\" module):\n"
                                       << scripts);
    CHECK_MESSAGE(comps.empty(), "Add these lines to \"components\" in "
                                     << kFile << " (a new thing is not in any release yet):\n"
                                     << comps);
    CHECK_MESSAGE(cmds.empty(), "Add these lines to \"commands\" in " << kFile
                                                                      << " (a new thing is not in any release yet):\n"
                                                                      << cmds);
}

TEST_CASE("api_since: no entry names something that no longer exists") {
    const Json file = read_since_file();
    const std::string comps = stale_lines(file, "components", component_names());
    const std::string cmds = stale_lines(file, "commands", command_names());
    const std::string scripts = stale_lines(file, "script", script_names());
    CHECK_MESSAGE(scripts.empty(), "Remove these entries from \"script\" in "
                                       << kFile << " (the script export or member is gone):\n"
                                       << scripts);
    CHECK_MESSAGE(comps.empty(), "Remove these entries from \"components\" in "
                                     << kFile << " (the component or field is gone):\n"
                                     << comps);
    CHECK_MESSAGE(cmds.empty(), "Remove these entries from \"commands\" in " << kFile << " (the command is gone):\n"
                                                                             << cmds);
}

TEST_CASE("api_since: values are \"unreleased\" or a version x.y.z") {
    const Json file = read_since_file();
    const std::regex version(R"(\d+\.\d+\.\d+)");
    for (const char* section : {"components", "commands", "script"}) {
        const bool hasSection = file.contains(section) && file[section].is_object();
        REQUIRE_MESSAGE(hasSection, kFile << " needs a \"" << section << "\" object.");
        for (auto it = file[section].begin(); it != file[section].end(); ++it) {
            const bool ok = it->is_string() && (it->get<std::string>() == "unreleased" ||
                                                std::regex_match(it->get<std::string>(), version));
            CHECK_MESSAGE(ok, kFile << ": \"" << section << "\" / \"" << it.key()
                                    << "\" must be \"unreleased\" or a version like \"0.1.6\", not " << it->dump()
                                    << ".");
        }
    }
}

TEST_CASE("api_since: nothing is unreleased once CHANGELOG.md has no Unreleased section") {
    const std::string changelog = testing::read_all(stdfs::path(FA_REPO_ROOT) / "CHANGELOG.md");
    REQUIRE_FALSE(changelog.empty());
    if (changelog.find("## Unreleased") != std::string::npos)
        return;  // on main after the last release: marks are right
    const Json file = read_since_file();
    std::string left;
    for (const char* section : {"components", "commands", "script"})
        for (auto it = file[section].begin(); it != file[section].end(); ++it)
            if (it->is_string() && it->get<std::string>() == "unreleased")
                left += std::string("    ") + section + " / " + it.key() + "\n";
    CHECK_MESSAGE(
        left.empty(),
        "CHANGELOG.md has no \"## Unreleased\" section, so this is a release: a release renames \"## Unreleased\" to "
        "\"## <version>\". Replace every \"unreleased\" in "
            << kFile
            << " with that version and regenerate docs/COMPONENTS.md (its script part too) and docs/reference/ "
               "(factoria call docs.write_reference '{\"out\":\"docs\"}') and the typings of the examples (factoria "
               "api --dts --project examples/<name>). Still unreleased:\n"
            << left);
}

// docs/COMPONENTS.md and docs/reference/ are generated (docs.write_reference); the committed copies must be current.
TEST_CASE("api_reference: the committed docs/reference/ and docs/COMPONENTS.md match the generator") {
    std::vector<ApiReferencePage> pages;
    with_command_registry([&](Engine& e) { pages = export_api_reference(e.commands(), e.scripts()); });
    REQUIRE_FALSE(pages.empty());
    std::string differ;
    for (const ApiReferencePage& p : pages) {
        std::string have = testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / p.path);
        have.erase(std::remove(have.begin(), have.end(), '\r'), have.end());
        if (have != p.text) differ += "    docs/" + p.path + (have.empty() ? " (missing)" : "") + "\n";
    }
    // A committed page the generator no longer produces is stale too.
    std::set<std::string> expected;
    for (const ApiReferencePage& p : pages) expected.insert("docs/" + p.path);
    const stdfs::path refDir = stdfs::path(FA_REPO_ROOT) / "docs" / "reference";
    if (stdfs::exists(refDir))
        for (const auto& e : stdfs::recursive_directory_iterator(refDir))
            if (e.is_regular_file()) {
                const std::string rel =
                    "docs/" + stdfs::relative(e.path(), stdfs::path(FA_REPO_ROOT) / "docs").generic_string();
                if (!expected.count(rel)) differ += "    " + rel + " (no longer generated: delete it)\n";
            }
    CHECK_MESSAGE(
        differ.empty(),
        "These files do not match the engine's registries:\n"
            << differ
            << "Regenerate both the reference pages and COMPONENTS.md with (from the repository root, outside any "
               "game project, with the factoria you just built):\n    factoria call docs.write_reference "
               "'{\"out\":\"docs\"}'");
}

// The tools table of docs/AI_GUIDE.md section 4 is generated from the command registry (docs.write_reference).
TEST_CASE("ai_guide_tools_table: the committed table matches the registry and every category has a purpose") {
    std::string current;
    std::vector<std::string> noPurpose;
    std::string regenerated;
    with_command_registry([&](Engine& e) {
        noPurpose = ai_guide_categories_without_purpose(e.commands());
        current = testing::read_all(stdfs::path(FA_REPO_ROOT) / "docs" / "AI_GUIDE.md");
        current.erase(std::remove(current.begin(), current.end(), '\r'), current.end());
        regenerated = current;
        std::string err;
        CHECK_MESSAGE(splice_ai_guide_tools_table(regenerated, e.commands(), &err), err);
    });
    std::string cats;
    for (const std::string& c : noPurpose) cats += " " + c;
    CHECK_MESSAGE(noPurpose.empty(), "These command categories have no one-line purpose for the AI guide's tools table:"
                                         << cats
                                         << ". Add {\"<category>\", \"<what the commands do>\"} to kPurposes in "
                                            "tools/common/src/ai_guide_export.cpp.");
    CHECK_MESSAGE(
        current == regenerated,
        "The tools table in docs/AI_GUIDE.md section 4 does not match the command registry. Regenerate it (from the "
        "repository root, outside any game project, with the factoria you just built):\n"
        "    factoria call docs.write_reference '{\"out\":\"docs\"}'");
}

// docs.write_reference checks the AI_GUIDE.md markers BEFORE it writes anything: a guide without them (or no guide at all) is a
// warning in the result, never a failure after half of the pages are on disk.
TEST_CASE("docs.write_reference: an AI_GUIDE.md without markers or without a file is a warning, the pages are written, "
          "the guide is untouched") {
    with_command_registry([&](Engine& e) {
        {
            testing::TempDir out;
            testing::write_all(out.path / "AI_GUIDE.md", "# Guide\n\nNo generated block here.\n");
            auto r = e.commands().call("docs.write_reference", {{"out", out.path.generic_string()}});
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            REQUIRE(r.result.contains("warnings"));
            CHECK(r.result["warnings"][0].get<std::string>().find("AI_GUIDE.md") != std::string::npos);
            CHECK(testing::read_all(out.path / "AI_GUIDE.md") == "# Guide\n\nNo generated block here.\n");  // untouched
            CHECK(stdfs::exists(out.path / "COMPONENTS.md"));
            CHECK(stdfs::exists(out.path / "reference" / "README.md"));
            bool guideListed = false;
            for (const Json& w : r.result["written"]) guideListed = guideListed || w == "AI_GUIDE.md";
            CHECK_FALSE(guideListed);
        }
        {
            testing::TempDir out;  // no AI_GUIDE.md at all
            auto r = e.commands().call("docs.write_reference", {{"out", out.path.generic_string()}});
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            REQUIRE(r.result.contains("warnings"));
            CHECK(r.result["warnings"][0].get<std::string>().find("No AI_GUIDE.md") != std::string::npos);
            CHECK(stdfs::exists(out.path / "COMPONENTS.md"));
            CHECK_FALSE(stdfs::exists(out.path / "AI_GUIDE.md"));
        }
        {
            testing::TempDir out;  // markers present: the block is filled, no warning
            testing::write_all(out.path / "AI_GUIDE.md",
                               "# Guide\n\n<!-- generated: tools table, factoria call docs.write_reference "
                               "'{\"out\":\"docs\"}' -->\nold\n<!-- end generated -->\ntail\n");
            auto r = e.commands().call("docs.write_reference", {{"out", out.path.generic_string()}});
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            CHECK_FALSE(r.result.contains("warnings"));
            const std::string guide = testing::read_all(out.path / "AI_GUIDE.md");
            CHECK(guide.find("| Category | Tools") != std::string::npos);
            CHECK(guide.find("old\n") == std::string::npos);
            CHECK(guide.find("tail\n") != std::string::npos);
        }
    });
}

// A caller without WriteAnywhere (MCP, an agent) writes the reference only below the project folder, wherever the process was
// started from, never to an absolute folder: the folder is refused before any page is written. The command-line user names a
// folder relative to the working directory.
TEST_CASE("docs.write_reference: out stays inside the project for MCP and agents, the command line uses the working "
          "directory") {
    with_command_registry([&](Engine& e) {
        testing::TempDir out;
        testing::TempDir elsewhere;  // the working directory of the process: not the project
        struct Cwd {
            stdfs::path saved = stdfs::current_path();
            ~Cwd() {
                std::error_code ec;
                stdfs::current_path(saved, ec);
            }
        } restoreCwd;
        stdfs::current_path(elsewhere.path);
        const stdfs::path project = fs::project_root();
        {
            CommandCapabilityScope mcp(capability_sets::mcp());
            for (const std::string& bad :
                 {out.path.generic_string(), std::string("../docs-out"), std::string(".git/docs")}) {
                CAPTURE(bad);
                auto r = e.commands().call("docs.write_reference", {{"out", bad}});
                REQUIRE_FALSE(r.ok);
                CHECK(r.error["code"] == "invalid_argument");
                CHECK_FALSE(r.error["hint"].get<std::string>().empty());
            }
            CHECK_FALSE(stdfs::exists(out.path / "COMPONENTS.md"));
            auto r = e.commands().call("docs.write_reference", {{"out", "docs-mcp"}});
            REQUIRE_MESSAGE(r.ok, r.error.dump());
            CHECK(stdfs::exists(project / "docs-mcp" / "COMPONENTS.md"));
            CHECK_FALSE(stdfs::exists(elsewhere.path / "docs-mcp"));
        }
        auto r = e.commands().call("docs.write_reference", {{"out", "docs-cli"}});
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(stdfs::exists(elsewhere.path / "docs-cli" / "COMPONENTS.md"));
        CHECK_FALSE(stdfs::exists(project / "docs-cli"));
    });
}

// ---- deprecations (docs/design/ARCHITECTURE.md, "Versions"): the section ships empty until something is deprecated.
TEST_CASE("api_since: the deprecated section names things that exist, with a replacement that exists, and none is two "
          "minors old") {
    const Json file = read_since_file();
    const bool hasSection = file.contains("deprecated") && file["deprecated"].is_object();
    REQUIRE_MESSAGE(hasSection,
                    kFile << " needs a \"deprecated\" object: {\"commands\": {}, \"components\": {}, \"script\": {}}.");
    for (auto it = file["deprecated"].begin(); it != file["deprecated"].end(); ++it) {
        const bool known =
            (it.key() == "commands" || it.key() == "components" || it.key() == "script") && it->is_object();
        CHECK_MESSAGE(known, kFile << ": \"deprecated\" / \"" << it.key()
                                   << "\" is not one of the sections commands, components, script.");
    }
    std::string all;
    for (const std::string& p : deprecated_problems(file["deprecated"], FA_ENGINE_VERSION, live_names()))
        all += "    " + p + "\n";
    CHECK_MESSAGE(all.empty(), "Fix the \"deprecated\" section of " << kFile << ":\n" << all);
}

TEST_CASE("api_since: the deprecation check finds a stale entry, a missing replacement and two minors of age") {
    const std::map<std::string, std::set<std::string>> live = {
        {"components", {"Sprite", "Sprite.flipX", "Sprite.flipY"}},
        {"commands", {"a.old", "a.new"}},
        {"script", {"oldFn", "newFn"}}};
    auto problems = [&](const char* text, const char* version) {
        std::string all;
        for (const std::string& p : deprecated_problems(Json::parse(text), version, live)) all += p + "\n";
        return all;
    };
    CHECK(problems(R"({"commands": {"a.old": {"since": "0.30.0", "use": "a.new", "note": ""}}})", "0.30.0").empty());
    CHECK(problems(R"({"commands": {"a.old": {"since": "0.30.1", "use": "a.new", "note": ""}}})", "0.31.4")
              .empty());  // one minor
    CHECK(problems(R"({"script": {"oldFn": {"since": "unreleased", "use": "", "note": "Nothing replaces it."}}})",
                   "0.31.0")
              .empty());
    const std::string age =
        problems(R"({"commands": {"a.old": {"since": "0.30.0", "use": "a.new", "note": ""}}})", "0.32.0");
    CHECK(age.find("two minor versions have passed. Remove the API (the command) and this entry") != std::string::npos);
    CHECK(problems(R"({"commands": {"a.old": {"since": "0.30.0", "use": "a.new", "note": ""}}})", "1.0.0")
              .find("two minor") != std::string::npos);
    CHECK(problems(R"({"commands": {"gone": {"since": "0.30.0", "use": "a.new", "note": ""}}})", "0.30.0")
              .find("names something that no longer exists: remove the entry") != std::string::npos);
    CHECK(problems(R"({"components": {"Sprite.flipX": {"since": "0.30.0", "use": "Sprite.nothing", "note": ""}}})",
                   "0.30.0")
              .find("\"use\" is \"Sprite.nothing\", which does not exist") != std::string::npos);
    CHECK(problems(R"({"script": {"oldFn": {"since": "0.30.0", "use": "", "note": ""}}})", "0.30.0")
              .find("no replacement and no reason") != std::string::npos);
    CHECK(
        problems(
            R"({"commands": {"a.old": {"since": "0.30.0", "use": "a.new", "note": ""}, "a.new": {"since": "0.30.0", "use": "", "note": "x"}}})",
            "0.30.0")
            .find("deprecated itself") != std::string::npos);
    CHECK(problems(R"({"commands": {"a.old": {"since": "soon", "use": "a.new", "note": ""}}})", "0.30.0")
              .find("must be \"unreleased\" or a version") != std::string::npos);
}

TEST_CASE("api_since: a deprecated entry reaches the typings, the markdown, docs.components and docs.commands") {
    RestoreDeprecations restore;
    Deprecations::global().set(Json::parse(R"({
        "components": {"Sprite.flipX": {"since": "0.30.0", "use": "Sprite.flipY", "note": "Mirror with scale instead."},
                       "Collider2D": {"since": "0.30.0", "use": "", "note": "Nothing replaces it."}},
        "commands": {"game.step": {"since": "0.30.0", "use": "game.pause", "note": ""}},
        "script": {"didYouMean": {"since": "0.30.0", "use": "closest", "note": ""}}})"));
    with_command_registry([&](Engine& e) {
        // The typings: a JSDoc @deprecated tag on the script export and on the component field.
        const std::string dts = export_typescript(e.scripts());
        const size_t fn = dts.find("function didYouMean(");
        REQUIRE(fn != std::string::npos);
        const size_t tag = dts.rfind("@deprecated ", fn);
        REQUIRE(tag != std::string::npos);
        CHECK(dts.substr(tag, dts.find('\n', tag) - tag) == "@deprecated 0.30.0: use `closest`. Removed in 0.32.0.");
        CHECK(dts.find("@deprecated 0.30.0: use `Sprite.flipY`. Removed in 0.32.0. Mirror with scale instead.") !=
              std::string::npos);
        CHECK(dts.find("@deprecated 0.30.0: no replacement. Removed in 0.32.0. Nothing replaces it.") !=
              std::string::npos);
        // The JSON of the components and commands.
        bool foundField = false;
        for (const Json& t : export_components_json())
            if (t["name"] == "Sprite")
                for (const Json& f : t["fields"])
                    if (f["name"] == "flipX") {
                        foundField = true;
                        CHECK(f["deprecated"]["use"] == "Sprite.flipY");
                        CHECK(f["deprecated"]["removedIn"] == "0.32.0");
                        CHECK(f["deprecated"]["note"] == "Mirror with scale instead.");
                    }
        CHECK(foundField);
        // The Markdown: components, fields and commands, and the index.
        const std::string comps = export_components_markdown();
        CHECK(comps.find("**Deprecated since 0.30.0 - no replacement. Removed in 0.32.0. Nothing replaces it.**") !=
              std::string::npos);
        CHECK(comps.find(
                  "**Deprecated since 0.30.0 - use `Sprite.flipY`. Removed in 0.32.0. Mirror with scale instead.**") !=
              std::string::npos);
        CHECK(export_commands_markdown(e.commands())
                  .find("**Deprecated since 0.30.0 - use `game.pause`. Removed in 0.32.0.**") != std::string::npos);
        bool indexed = false;
        for (const ApiReferencePage& p : export_api_reference(e.commands(), e.scripts()))
            if (p.path == "reference/README.md") indexed = p.text.find("_Deprecated._") != std::string::npos;
        CHECK(indexed);
        // What an AI asks for: docs.commands and docs.components, JSON and Markdown.
        auto r = e.commands().call("docs.commands", {{"name", "game.step"}, {"format", "json"}});
        REQUIRE_MESSAGE(r.ok, r.error.dump());
        CHECK(r.result["commands"][0]["deprecated"]["use"] == "game.pause");
        CHECK(r.result["commands"][0]["deprecated"]["since"] == "0.30.0");
        r = e.commands().call("docs.commands", {{"name", "game.step"}});
        REQUIRE(r.ok);
        CHECK(r.result["markdown"].get<std::string>().find("Deprecated since 0.30.0 - use `game.pause`") !=
              std::string::npos);
        r = e.commands().call("docs.components", {{"name", "Sprite"}, {"format", "json"}});
        REQUIRE(r.ok);
        bool inFields = false;
        for (const Json& f : r.result["components"][0]["fields"])
            if (f["name"] == "flipX") inFields = f.contains("deprecated");
        CHECK(inFields);
        r = e.commands().call("docs.components", {{"name", "Collider2D"}, {"format", "json"}});
        REQUIRE(r.ok);
        CHECK(r.result["components"][0]["deprecated"]["note"] == "Nothing replaces it.");
    });
}

TEST_CASE("api_since: with no deprecated entries nothing is marked") {
    RestoreDeprecations restore;
    install_deprecations(true);
    CHECK(Deprecations::global().empty());
    CHECK(deprecation_json("commands", "game.step").is_null());
    with_command_registry([&](Engine& e) {
        CHECK(export_typescript(e.scripts()).find("@deprecated") == std::string::npos);
        CHECK(export_components_markdown().find("**Deprecated since") == std::string::npos);
    });
}
