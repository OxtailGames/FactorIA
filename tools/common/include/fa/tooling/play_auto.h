// play.auto: the AI plays the game with nobody at the keyboard and reads the same report as for an editor play session
// (docs/DEBUGGING.md, "Let the game play itself"). The driver is fa/runtime/play_auto.h; this registers the command.
#pragma once

#include <string>

#include "fa/core/command.h"

namespace fa {

void register_play_auto_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
