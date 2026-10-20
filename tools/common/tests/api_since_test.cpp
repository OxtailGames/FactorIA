// tools/common/api_since.json says which FactorIA version added each component, field and command; the generated
// reference (docs/COMPONENTS.md, `factoria api`, MCP) shows it. These tests keep the file complete and honest.
#include <doctest.h>

#include <filesystem>
#include <map>
#include <regex>
#include <set>

#include "fa/ai/commands.h"
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

const char* kFile = "tools/common/api_since.json";

Json read_since_file() {
    const std::string text = testing::read_all(stdfs::path(FA_REPO_ROOT) / kFile);
    Json j = Json::parse(text, nullptr, false);
    REQUIRE_MESSAGE(j.is_object(), kFile << " must be a JSON object {\"components\": {...}, \"commands\": {...}}.");
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
std::set<std::string> command_names() {
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
    std::set<std::string> out;
    for (const CommandInfo* c : engine.commands().list()) out.insert(c->name);
    engine.shutdown();
    fs::set_project_root(savedRoot);
    return out;
}

std::string missing_lines(const Json& file, const char* section, const std::set<std::string>& live) {
    std::string out;
    for (const std::string& n : live)
        if (!file.contains(section) || !file[section].contains(n)) out += std::string("    \"") + n + "\": \"unreleased\",\n";
    return out;
}

std::string stale_lines(const Json& file, const char* section, const std::set<std::string>& live) {
    std::string out;
    if (!file.contains(section)) return out;
    for (auto it = file[section].begin(); it != file[section].end(); ++it)
        if (!live.count(it.key())) out += std::string("    \"") + it.key() + "\"\n";
    return out;
}

}  // namespace

TEST_CASE("api_since: every component, field and command has an entry") {
    const Json file = read_since_file();
    const std::string comps = missing_lines(file, "components", component_names());
    const std::string cmds = missing_lines(file, "commands", command_names());
    CHECK_MESSAGE(comps.empty(), "Add these lines to \"components\" in " << kFile << " (a new thing is not in any release yet):\n"
                                                                          << comps);
    CHECK_MESSAGE(cmds.empty(), "Add these lines to \"commands\" in " << kFile << " (a new thing is not in any release yet):\n"
                                                                       << cmds);
}

TEST_CASE("api_since: no entry names something that no longer exists") {
    const Json file = read_since_file();
    const std::string comps = stale_lines(file, "components", component_names());
    const std::string cmds = stale_lines(file, "commands", command_names());
    CHECK_MESSAGE(comps.empty(), "Remove these entries from \"components\" in " << kFile << " (the component or field is gone):\n"
                                                                                << comps);
    CHECK_MESSAGE(cmds.empty(), "Remove these entries from \"commands\" in " << kFile << " (the command is gone):\n" << cmds);
}

TEST_CASE("api_since: values are \"unreleased\" or a version x.y.z") {
    const Json file = read_since_file();
    const std::regex version(R"(\d+\.\d+\.\d+)");
    for (const char* section : {"components", "commands"}) {
        const bool hasSection = file.contains(section) && file[section].is_object();
        REQUIRE_MESSAGE(hasSection, kFile << " needs a \"" << section << "\" object.");
        for (auto it = file[section].begin(); it != file[section].end(); ++it) {
            const bool ok = it->is_string() && (it->get<std::string>() == "unreleased" || std::regex_match(it->get<std::string>(), version));
            CHECK_MESSAGE(ok, kFile << ": \"" << section << "\" / \"" << it.key() << "\" must be \"unreleased\" or a version like \"0.1.6\", not "
                                    << it->dump() << ".");
        }
    }
}

TEST_CASE("api_since: nothing is unreleased once CHANGELOG.md has no Unreleased section") {
    const std::string changelog = testing::read_all(stdfs::path(FA_REPO_ROOT) / "CHANGELOG.md");
    REQUIRE_FALSE(changelog.empty());
    if (changelog.find("## Unreleased") != std::string::npos) return;  // on main after the last release: marks are right
    const Json file = read_since_file();
    std::string left;
    for (const char* section : {"components", "commands"})
        for (auto it = file[section].begin(); it != file[section].end(); ++it)
            if (it->is_string() && it->get<std::string>() == "unreleased") left += std::string("    ") + section + " / " + it.key() + "\n";
    CHECK_MESSAGE(left.empty(), "CHANGELOG.md has no \"## Unreleased\" section, so this is a release: a release renames \"## Unreleased\" to "
                                "\"## <version>\". Replace every \"unreleased\" in "
                                    << kFile << " with that version and regenerate docs/COMPONENTS.md (factoria api --md --out docs/COMPONENTS.md) and the typings of the examples (factoria api --dts --project examples/<name>). Still unreleased:\n"
                                    << left);
}
