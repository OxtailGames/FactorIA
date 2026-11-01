// Every command's input schema is closed or explicitly open (docs/ARCHITECTURE.md, "Commands (the tool system)"):
// CommandRegistry::add closes each object schema that declares `properties`, so an argument a handler reads but its schema
// does not declare cannot be added without the schema saying so. This test builds the REAL registry of a project (engine,
// tooling, ai and skills commands, as `factoria mcp` serves them) and holds it to that, so a new command with an undeclared
// argument, or one that opens itself without a reason, cannot slip in.
#include <doctest.h>

#include <filesystem>
#include <set>

#include "common.h"  // tools/cli/src: Session
#include "fa/ai/skills.h"
#include "fa/core/fs.h"
#include "fa/core/json_schema.h"
#include "fa/tooling/scaffold.h"

namespace stdfs = std::filesystem;
using namespace fa;

namespace {

// The commands whose ROOT schema is open (`additionalProperties` true or a schema): each takes open-ended keys on purpose.
// Adding a command here needs a reason (a comment next to its name); the default is a closed schema. The audit of M48.1 found
// none: every command declares its arguments.
const std::set<std::string>& open_root_commands() {
    static const std::set<std::string> names = {
        // (none)
    };
    return names;
}

void collect(const Json& schema, const std::string& where, std::vector<std::string>& unclosed, int depth = 0) {
    if (!schema.is_object() || depth > 32) return;
    auto props = schema.find("properties");
    if (props != schema.end() && props->is_object()) {
        if (!schema.contains("additionalProperties")) unclosed.push_back(where);
        for (auto it = props->begin(); it != props->end(); ++it) collect(it.value(), where + "/properties/" + it.key(), unclosed, depth + 1);
    }
    if (auto it = schema.find("items"); it != schema.end()) collect(*it, where + "/items", unclosed, depth + 1);
    if (auto it = schema.find("additionalProperties"); it != schema.end() && it->is_object()) collect(*it, where + "/additionalProperties", unclosed, depth + 1);
    for (const char* key : {"anyOf", "oneOf"})
        if (auto it = schema.find(key); it != schema.end() && it->is_array())
            for (std::size_t i = 0; i < it->size(); ++i) collect((*it)[i], where + "/" + key + "/" + std::to_string(i), unclosed, depth + 1);
    for (const char* key : {"$defs", "definitions"})
        if (auto it = schema.find(key); it != schema.end() && it->is_object())
            for (auto d = it->begin(); d != it->end(); ++d) collect(d.value(), where + "/" + key + "/" + d.key(), unclosed, depth + 1);
}

}  // namespace

TEST_CASE("command schemas: every command of the real registry is closed or explicitly open") {
    const stdfs::path oldRoot = fs::project_root();
    const stdfs::path root = fs::make_temp_dir("fa_command_schema");
    ScaffoldOptions opt;
    opt.writeTypings = false;
    const std::string dir = (root / "game").string();
    auto made = create_project(dir, "2d-empty", opt);
    REQUIRE_MESSAGE(made.ok(), made.error().to_string());
    {
        cli::SessionOptions so;
        so.gfx = cli::Gfx::None;
        auto session = cli::Session::open(dir, so);
        CommandRegistry& reg = session->registry();
        cli::register_cli_commands(reg, dir, &session->engine());  // the ai.* commands and project.create, as `factoria mcp` has them

        std::set<std::string> openRoots;
        std::size_t checked = 0;
        for (const CommandInfo* c : reg.list()) {
            ++checked;
            INFO(c->name);
            REQUIRE(c->inputSchema.is_object());
            const auto root_open = c->inputSchema.find("additionalProperties");
            REQUIRE_MESSAGE(root_open != c->inputSchema.end(),
                            c->name << ": the root of the input schema declares neither properties nor additionalProperties. List the "
                                       "arguments in `properties` (the schema is then closed), or say `additionalProperties: true`.");
            if (!(root_open->is_boolean() && !root_open->get<bool>())) openRoots.insert(c->name);
            std::vector<std::string> unclosed;
            collect(c->inputSchema, "", unclosed);
            for (const std::string& w : unclosed)
                FAIL_CHECK(c->name << ": the object schema at '" << w << "' was not closed by CommandRegistry::add");
        }
        CHECK(checked > 150);  // the real registry, not a stub
        for (const std::string& name : openRoots) CHECK_MESSAGE(open_root_commands().count(name), name << " has an open root schema that this test does not list. Declare its arguments, or list it here with the reason.");
        for (const std::string& name : open_root_commands()) CHECK_MESSAGE(openRoots.count(name), name << " is listed as open here but its schema is closed (or the command is gone): remove it from the list.");
    }
    fs::set_project_root(oldRoot);
    std::error_code ec;
    stdfs::remove_all(root, ec);
}
