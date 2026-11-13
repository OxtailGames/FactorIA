// Tool groups (fa/tooling/tool_groups.h): the group rules shared by the built-in agent and `factoria mcp --tools`.
#include <doctest.h>

#include <regex>
#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/tool_groups.h"

using namespace fa;

namespace {
CommandInfo info_of(const std::string& name, const std::string& category) {
    CommandInfo i;
    i.name = name;
    i.category = category;
    return i;
}
}  // namespace

TEST_CASE("tool groups: split_tool_groups trims, drops empty items and duplicates, keeps the order") {
    using V = std::vector<std::string>;
    CHECK(split_tool_groups("core, anim,,anim") == V{"core", "anim"});
    CHECK(split_tool_groups("  physics \t,\tassets.slice_sheet ,") == V{"physics", "assets.slice_sheet"});
    CHECK(split_tool_groups(",,  ,").empty());
    CHECK(split_tool_groups("").empty());
    CHECK(split_tool_groups("all") == V{"all"});
}

TEST_CASE("tool groups: a command is in 'all', in 'core' only when it is a core command, in its category or by its "
          "exact name") {
    const CommandInfo read = info_of("fs.read", "fs");
    const CommandInfo slice = info_of("assets.slice_sheet", "assets");
    CHECK(command_in_tool_group(read, "all"));
    CHECK(command_in_tool_group(slice, "all"));
    CHECK(command_in_tool_group(read, "core"));
    CHECK_FALSE(command_in_tool_group(slice, "core"));
    CHECK(command_in_tool_group(slice, "assets"));
    CHECK(command_in_tool_group(slice, "assets.slice_sheet"));
    CHECK_FALSE(command_in_tool_group(slice, "assets.slice"));  // a name, not a prefix
    CHECK_FALSE(command_in_tool_group(slice, "fs"));
    // A command of a core category that is not itself core stays out of "core".
    CHECK_FALSE(command_in_tool_group(info_of("fs.something_new", "fs"), "core"));
    CHECK(is_core_command("game.step"));
    CHECK_FALSE(is_core_command("assets.slice_sheet"));
    CHECK_FALSE(core_command_names().empty());
}

TEST_CASE("tool groups: the hint for a group that matches nothing suggests the category") {
    const CommandInfo a = info_of("physics.raycast", "physics");
    const CommandInfo b = info_of("assets.slice_sheet", "assets");
    const std::string hint = tool_group_hint("phyiscs", {&a, &b});
    CHECK(hint.find("physics") != std::string::npos);
}

// No number of core commands is written down where a test cannot see it: the help text of `factoria mcp --tools` computes it
// (tools/cli/tests/cli_test.cpp checks that), and a prose "<N> core commands" in the docs must be the real count.
TEST_CASE("tool groups: a count of core commands written in the docs or in the header is the real one") {
    const std::string real = std::to_string(core_command_names().size());
    const std::regex counted(R"((\d+) core (?:commands|tools))");
    for (const char* doc : {"docs/MCP.md", "docs/AI_PROVIDERS.md", "docs/ARCHITECTURE.md"}) {
        const auto text = bundled_read(doc);
        REQUIRE_MESSAGE(text.has_value(), doc);
        for (std::sregex_iterator it(text->begin(), text->end(), counted), end; it != end; ++it)
            CHECK_MESSAGE((*it)[1].str() == real,
                          doc << " says \"" << (*it)[0].str() << "\" but the core set has " << real << " commands");
    }
}
