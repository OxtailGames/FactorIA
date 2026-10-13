// API reference generated from the live registries: components (TypeRegistry)
// and commands (CommandRegistry). TypeScript .d.ts export will be added by the
// script module; these Markdown/JSON forms are what `factoria api` prints.
#pragma once

#include <string>

#include "fa/core/command.h"
#include "fa/core/json.h"

namespace fa {

Json export_components_json();  // TypeRegistry::global().describe_all() (built-ins registered first)
std::string export_components_markdown();
Json export_commands_json(const CommandRegistry& registry);  // registry.describe()
std::string export_commands_markdown(const CommandRegistry& registry);

// Registers "docs.components" and "docs.commands" (format: markdown | json). They live in the docs
// area so they never collide with the runtime's own api.* commands.
void register_api_export_commands(CommandRegistry& registry);

}  // namespace fa
