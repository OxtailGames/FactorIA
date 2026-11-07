// play.auto: the AI plays the game with nobody at the keyboard and reads the same report as for an editor play session
// (docs/DEBUGGING.md, "Let the game play itself"). The driver is fa/runtime/play_auto.h; this registers the command.
#pragma once

#include <string>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/core/process.h"

namespace fa {

void register_play_auto_commands(CommandRegistry& registry, const std::string& projectDir);

// The factoria command line tool, as a UTF-8 path: $FA_FACTORIA_EXE when set (it must name a file, else ""), this program when it
// is `factoria`, or the `factoria` next to it (the editor is `factoria editor`). "" when none is found.
std::string factoria_executable();

// play.auto run as a `factoria call` child process, whatever this process holds: it launches the child and waits, and touches no
// engine state, so it may run on any thread (the editor's AI agent threads call it, never the UI thread). `projectDir` is the open
// project's folder as the tooling carries it. `cancel` becoming true kills the child's process tree and the command fails with the
// code "cancelled" (a child that is killed writes no session). Throws CommandError; the child's own errors (a wrong argument, a
// project that does not start) come back with their code, message and hint.
Json play_auto_in_child(const std::string& projectDir, const Json& args, const CancelFlag* cancel);

}  // namespace fa
