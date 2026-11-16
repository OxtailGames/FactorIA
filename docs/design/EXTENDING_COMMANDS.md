# Extending the engine: C++ commands (section B)

Part of [Creating tools and extending the engine](../EXTENDING.md), for engine developers (these pages are the engine's source docs: they are not embedded in the binary and `docs.read` does not serve them; read them in a checkout).

## B. C++ commands in the engine

A command is a named function from JSON to JSON, registered in `CommandRegistry` (`engine/core/include/fa/core/command.h`).

```cpp
CommandInfo info;
info.name = "area.verb_object";   // snake_case, "<area>.<verb_object>"
info.category = "area";           // grouping in docs and listings
info.readOnly = true;             // false when the command changes game or project state
info.summary = "One line, imperative.";
info.description = "What it does, caveats, and one example call.";
info.inputSchema = Json::parse(R"({ "type": "object", "properties": {}, "required": [] })");
registry.add(std::move(info), [](const Json& args) -> Json {
    // args are already validated and defaults are filled in.
    return Json::object({{"ok", true}});
});
```

- **Errors.** Throw `CommandError(code, message, hint, data)` (defined in `command.h`; `hint` and `data` are optional). `command.h` names the codes `not_found`, `invalid_argument`, `failed` and `unavailable`; use the one that fits. Any other exception becomes `failed`. The registry itself reports `unknown_command` (with a did-you-mean hint) and `invalid_arguments`.
- **Results.** `CommandRegistry::call` returns `CommandResult{ok, result, error}`. `error` is `{code, message, hint}`.
- **Replacement.** `add` replaces a command with the same name.
- **Hooks.** `CommandRegistry::set_interceptor` takes a `CommandInterceptor` (`command.h`) whose `before` can refuse a call or change its arguments and whose `after` sees the outcome. `register_ai_commands` installs the one that runs the user's `beforeCommand` / `afterCommand` hooks (docs/HOOKS.md), so every command, whoever calls it, can be hooked without code of its own.
- **Schema keywords** are the same as in section A of [EXTENDING.md](../EXTENDING.md#a-project-tools-toolsjs), and so is the rule that arguments are closed by default: `add` sets `additionalProperties: false` on every object schema that has `properties` and no `additionalProperties`, so declare every key the handler reads (a handler that reads an undeclared key never sees it). Open an object on purpose with `"additionalProperties": true` or a schema, and say why in the description. `tools/cli/tests/command_schema_test.cpp` fails when a command is open without being listed there.

### Where to register

| The command needs | Write it in | Register it from |
|---|---|---|
| The running game (scene, input, screenshots) or only the `World` | `engine/runtime/src/` (with a public header in `engine/runtime/include/fa/runtime/` if tests need it) | `register_builtin_commands` in `engine/runtime/src/commands.cpp` (declared in `engine_impl.h`) |
| A command only a developer tool uses and a game must not have (writes project files, imports assets, edits animations) | `tools/authoring/src/` (`fa_authoring`; tests in `tools/authoring/tests/`) | `register_<area>_commands(Engine&, Engine::Impl&)` called from `register_authoring_commands` in `tools/authoring/src/authoring.cpp` (declared in `authoring_internal.h`); a process gets it by calling `fa::authoring::install()` (docs/design/ARCHITECTURE.md, "Where a command goes") |
| Project tooling: validation, docs, files, feedback | `tools/common/src/` | `register_tooling_commands(registry, projectDir)` (`tooling.h`) |
| The built-in AI agent | `tools/ai/src/` | `register_ai_commands` (`commands.h`) |

### B.1 Full example: `scene.count_by_tag`

The command returns how many entities carry a tag. It is an exercise: the engine has no `scene.count_by_tag` (to list
the entities with a tag, use the existing `scene.list_entities` with its `tag` filter), and the files below
(`scene_commands.h`, `scene_commands.cpp`, `test_scene_commands.cpp`) do not exist either. It needs the `World`, so it
lives in the runtime, which owns the world. Three new files and one call.

Header, `engine/runtime/include/fa/runtime/scene_commands.h` (new file):

```cpp
#pragma once

#include "fa/core/command.h"
#include "fa/scene/world.h"

namespace fa {

// Registers scene.count_by_tag. Called from register_builtin_commands().
void register_scene_commands(CommandRegistry& registry, World& world);

}  // namespace fa
```

Source, `engine/runtime/src/scene_commands.cpp` (new file):

```cpp
#include "fa/runtime/scene_commands.h"

namespace fa {

void register_scene_commands(CommandRegistry& registry, World& world) {
    CommandInfo info;
    info.name = "scene.count_by_tag";
    info.category = "scene";
    info.readOnly = true;
    info.summary = "Count the entities that have a tag.";
    info.description =
        "Returns 0 when no entity has the tag. Example: {\"tag\":\"enemy\"} returns {\"count\":2}. "
        "Use scene.list_entities with the same tag to get the entities themselves.";
    info.inputSchema = Json::parse(R"({
        "type": "object",
        "properties": {
            "tag": {"type": "string", "description": "Tag to search for, for example \"enemy\"."}
        },
        "required": ["tag"],
        "additionalProperties": false
    })");

    registry.add(std::move(info), [&world](const Json& args) -> Json {
        const std::string tag = args.at("tag").get<std::string>();
        if (tag.empty())
            throw CommandError("invalid_argument", "The tag is empty.", "Pass a tag such as {\"tag\":\"enemy\"}.");
        return Json::object({{"count", world.find_by_tag(tag).size()}});
    });
}

}  // namespace fa
```

Call it from `register_builtin_commands` in `engine/runtime/src/commands.cpp`, where the registry is `I.commands` and the world is `I.world`. Add this line next to the other registrations:

```cpp
register_scene_commands(I.commands, I.world);
```

Test, `engine/runtime/tests/test_scene_commands.cpp` (new file). `fa_add_tests(runtime)` in `engine/runtime/CMakeLists.txt` builds every `tests/*.cpp` into `fa_test_runtime`:

```cpp
#include <doctest.h>

#include "fa/core/command.h"
#include "fa/runtime/scene_commands.h"
#include "fa/scene/world.h"

using namespace fa;

TEST_CASE("scene.count_by_tag counts the entities with a tag") {
    World world;
    world.info(world.create("Grunt", "enemy_1")).tags = {"enemy"};
    world.info(world.create("Coin", "coin_1")).tags = {"pickup"};

    CommandRegistry registry;
    register_scene_commands(registry, world);

    CommandResult found = registry.call("scene.count_by_tag", Json::object({{"tag", "enemy"}}));
    REQUIRE(found.ok);
    CHECK(found.result["count"] == 1);

    CommandResult none = registry.call("scene.count_by_tag", Json::object({{"tag", "boss"}}));
    REQUIRE(none.ok);
    CHECK(none.result["count"] == 0);

    CommandResult empty = registry.call("scene.count_by_tag", Json::object({{"tag", ""}}));
    CHECK_FALSE(empty.ok);
    CHECK(empty.error["code"] == "invalid_argument");
}
```

Build and run it:

```bash
cmake --build --preset linux-debug --target fa_test_runtime
ctest --preset linux-debug -R runtime --output-on-failure
```

After this change the command is available as MCP tool `scene_count_by_tag`, as `factoria call scene.count_by_tag
'{"tag":"enemy"}'`, in scripts as `fa.call("scene.count_by_tag", {tag: "enemy"})`, and to the built-in agent. Nothing
else needs to change.

