// The menu kit of docs/MENUS.md as a command: project.add_menu_kit copies the parts of templates/menus/ a game asks for
// (main menu, options, pause, ...) into the game and merges their strings into the game's locales/<language>.json.
//
// templates/menus/kit.json lists the parts: each has the files it copies, the parts it needs and the top-level keys of the
// string tables it brings. The kit is not a project template (it has no factoria.json, `factoria new` does not list it).
#pragma once

#include <string>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

struct MenuKitOptions {
    std::string projectDir;
    std::vector<std::string> parts;  // empty = every part
    bool overwrite = false;          // replace a kit file the game has changed (string keys the game has are never replaced)
};

// {parts[], requiredBy{}, added[], unchanged[], overwritten[], skipped[{file,reason}], locales[{file,created,merged[],skipped[]}],
//  settings[], nextSteps[]}. Fails (with the list of parts) for an unknown part, and for a folder without factoria.json.
Result<Json> add_menu_kit(const MenuKitOptions& options);

// Names of the kit's parts, in kit order.
std::vector<std::string> menu_kit_parts();

void register_menu_kit_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
