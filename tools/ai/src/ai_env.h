// The environment of the programs the AI starts (CLI agents, asset commands, stdio tool servers, hooks, version probes).
//
// They do not inherit the editor's whole environment: it holds signing passwords (FACTORIA_WINDOWS_PFX_PASSWORD,
// FACTORIA_APPLE_APP_PASSWORD, FACTORIA_ANDROID_*_PASSWORD...) and the API keys of every provider, and a program that follows a
// prompt (a hook, an agent's shell) could print them. Each gets fa::base_child_env() (PATH, HOME, locale, temp folders...) plus
// what it needs to work, plus what the user listed in "inheritEnv" of ai.json. docs/AI_PROVIDERS.md, "Environment of the programs".
#pragma once

#include <string>
#include <vector>

#include "fa/ai/config.h"
#include "fa/core/process.h"

namespace fa::ai {

// Names (or "PREFIX*" patterns) of the variables a program started for `cfg` inherits, as ProcessOptions::inheritEnv: the base
// list, the variables every CLI needs to reach the network and find its config (XDG_*, proxies, certificate files), those of its
// kind (Claude Code: CLAUDE_*, ANTHROPIC_*; Codex: CODEX_*, OPENAI_*), the provider's own API key variable and the user's lists
// (cfg.inheritEnv, cfg.inheritEnvGlobal). Never another provider's key and never FACTORIA_*_PASSWORD, unless listed.
std::vector<std::string> provider_inherit_env(const ProviderConfig& cfg);

// The same for a stdio tool server: the base list, proxies and certificates, `server.inheritEnv`.
std::vector<std::string> tool_server_inherit_env(const ResolvedToolServer& server);

// For a program that needs nothing of a provider (a version probe, `python --version`): the base list, proxies and certificates.
std::vector<std::string> plain_inherit_env();

}  // namespace fa::ai
