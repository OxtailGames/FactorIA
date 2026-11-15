// Commands that a program adds to every Engine it creates, beyond the ones that ship inside a game.
//
// The engine's own commands (engine/runtime/src, the modules below it) are the RUNTIME set: an exported game's player has
// exactly them. The commands that only developer tools need (the ones that write project files, import assets, edit
// animations, ...) live in tools/authoring (fa_authoring), a library the player does not link. A program that wants them
// (the factoria CLI, the editor, the MCP/DAP/AI servers, the tests of those) calls `fa::authoring::install()` once at
// start-up; that registers an EXTENSION here, and every Engine::init after it runs the extension right after the
// built-in commands and the plugins' commands, before scripts start.
//
//   fa::register_command_extension("authoring", [](fa::Engine& engine) { /* engine.commands().add(...) */ });
//
// No static initializers: a static archive drops a translation unit nothing references, so the host calls install() by name.
// The list is process-wide and guarded by a mutex; engines on several threads read it safely.
#pragma once

#include <functional>
#include <string>
#include <string_view>
#include <vector>

namespace fa {

class Engine;

// What an extension does to an Engine: add commands to `engine.commands()` (the registry also holds the built-in ones, so
// a name that exists already is an error as for any command). Runs on the thread that calls Engine::init, after the
// built-in and plugin commands and before the scripts start. Must not call anything that needs the engine to be
// running (no frames, no scene load); `engine.runtime_impl()` (fa/runtime/internal/engine_impl.h, engine tools only)
// is the way to the engine's state.
using CommandExtensionFn = std::function<void(Engine& engine)>;

// Adds an extension to the process-wide list; the engines created from now on run it (an engine that exists already does
// not). `name` identifies it: registering a name that is in the list already does nothing (so install functions are
// idempotent) and returns false; true when it was added. Extensions run in the order they were registered.
bool register_command_extension(std::string_view name, CommandExtensionFn fn);

// The names of the registered extensions, in the order they run. For diagnostics and tests.
std::vector<std::string> command_extension_names();

// Runs every registered extension on `engine`, in order. Engine::init calls this; nothing else should.
void run_command_extensions(Engine& engine);

}  // namespace fa
