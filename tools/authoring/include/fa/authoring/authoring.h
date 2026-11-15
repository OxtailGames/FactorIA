// fa_authoring: the commands of the developer tools (CLI, editor, MCP/DAP/AI servers) that an exported game does not need.
//
// WHERE A COMMAND GOES. engine/ ships inside every game: a command there is in the player, a game script can see it, and its
// code is in every download. A command that only an author uses (it writes project files, bakes or imports assets, edits
// animations or levels) lives in tools/authoring; the factoria CLI, the editor and the servers register it, the player does not.
// Engine::runtime_command_names() lists what the player has.
//
// HOW IT IS WIRED. install() adds one extension to the process-wide list of fa/runtime/command_extension.h; every
// Engine::init after it calls the extension, which registers the authoring commands (src/authoring.cpp lists the files). A
// program that creates engines calls install() once, before the first Engine::init:
//   - the mains of tools/ (factoria, fa_editor_autotest) do it;
//   - the test executables of every module at or above fa_authoring get it from cmake/doctest_main.cpp;
//   - the runtime's own tests do not (they test what the player has).
// Nothing registers itself from a static initializer: a static library drops a file nothing refers to.
#pragma once

namespace fa::authoring {

// Registers the authoring commands as a command extension (fa::register_command_extension, name "authoring"), so that every
// Engine initialised after this call has them. Idempotent and safe to call from several threads: a second call does nothing.
// An Engine that was initialised before the first call does not get the commands.
void install();

}  // namespace fa::authoring
