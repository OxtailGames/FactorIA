// beforeCommand / afterCommand hooks: programs or JavaScript modules that run around the commands of a CommandRegistry, for every
// caller (an MCP client, the CLI, the editor, a script, the built-in AI agent). They are the "hooks" entries of `extensions` that
// name those two events (hooks.h, docs/HOOKS.md). Installed by register_ai_commands on the registry it fills.
#pragma once

#include <functional>
#include <memory>
#include <string>

#include "fa/ai/config.h"
#include "fa/ai/extension_plan.h"
#include "fa/ai/hooks.h"
#include "fa/core/command.h"

namespace fa::ai {

struct CommandHooksOptions {
    // Where the hooks come from; the same two as register_ai_commands (AiCommandOptions::loadConfig / projectDir).
    std::function<Result<AiConfig>()> loadConfig;
    std::function<std::string()> projectDir;
    EnvLookup env;
    std::string trustPath;          // ai-trust.json; "" = next to the config file
    const CancelFlag* cancel = nullptr;
    // How often the configuration is read again, at most (seconds): a call after that much time sees an edited ai.json or
    // extensions file. 0 = on every call (tests).
    double refreshSeconds = 1.0;
    double defaultTimeoutSeconds = 0;  // hooks that name no "timeout" (0 = kDefaultHookTimeoutSeconds)
};

// Looks at the configuration and, when a hook is configured for the command being called, runs it. A registry whose configuration
// has no command hooks pays a pointer test and a clock read per call (no file is read more than once per refreshSeconds).
class CommandHooks {
public:
    explicit CommandHooks(CommandHooksOptions options);
    // The interceptor to give CommandRegistry::set_interceptor.
    std::shared_ptr<const CommandInterceptor> interceptor();
    // Reads the configuration now.
    void refresh();
    // The command hooks as last read.
    CommandHookConfig current() const;
    // Why the configuration could not be read ("" when fine); the hooks are off then.
    std::string configError() const;

private:
    struct State;
    std::shared_ptr<State> state_;
};

// Creates a CommandHooks for `registry` and installs it. Nothing is installed in a process started by a hook (the environment has
// FACTORIA_IN_HOOK=1): a factoria that a hook starts runs no hooks of its own, so they cannot call each other without end.
std::shared_ptr<CommandHooks> install_command_hooks(CommandRegistry& registry, CommandHooksOptions options);

// `ai.hooks`: every hooks entry (user and project) with its events, matchers, handlers, trust and problems, the handlers FactorIA's
// loop does not run, and the recent runs of every handler in this process.
Json hooks_report(const AiConfig& cfg, const ExtensionContext& ctx, std::string_view roleFilter, std::size_t recentRuns);

// `ai.hooks_test`: runs the configured handlers of `event` for `matchValue` (a tool name, a command name, a source) with `input`,
// and returns what they decided. The handlers really run: a hook that changes files will change them. For the engine's command
// events the entries of every role count; for the others, those of `role`.
Result<Json> test_hooks(const AiConfig& cfg, const ExtensionContext& ctx, HookEvent event, const std::string& matchValue, const Json& input,
                        const std::string& role, const CancelFlag* cancel);

}  // namespace fa::ai
