// The `platform.*` commands (category "platform"): state, and the test hooks of the fake backend. `game.platform` in
// tests and MCP clients use these, so there is one implementation of every hook.
#pragma once

#include "fa/core/command.h"
#include "fa/services/platform.h"

namespace fa {

// Registers platform.state, platform.reset, platform.respond, platform.emit and platform.set_fake. `platform` must outlive
// the registry (the engine owns both).
void register_platform_commands(CommandRegistry& commands, PlatformServices& platform);

}  // namespace fa
