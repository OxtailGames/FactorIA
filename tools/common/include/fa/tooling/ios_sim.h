// player.run_ios_sim: plays an input replay on the exported iOS player inside the iOS Simulator (docs/MOBILE.md, "Play a replay
// on the simulator"). `xcrun simctl` has no tap, key or rotate command, so the player itself takes the replay (the FA_INPUT_REPLAY
// environment variable) and the screen orientation (FA_ORIENTATION), which the command passes through `simctl launch`.
#pragma once

#include <string>

#include "fa/core/command.h"

namespace fa {

void register_ios_sim_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
