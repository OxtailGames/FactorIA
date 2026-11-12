// API reference generated from the live registries: components (TypeRegistry)
// and commands (CommandRegistry). TypeScript .d.ts export will be added by the
// script module; these Markdown/JSON forms are what `factoria api` prints.
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/json.h"
#include "fa/script/script.h"

namespace fa {

// Which FactorIA version added each component ("Sprite"), field ("Sprite.slice"), command ("scene.spawn") and script
// export ("tween", "NavAPI", "NavAPI.findTilePath", "test:TestGame.setDate"; ScriptSystem::script_api_keys): the
// embedded tools/common/api_since.json. Values are "0.1.x" or "unreleased"; "" when there is no entry. section is
// "components", "commands" or "script". The unit test keeps the file complete (docs/ARCHITECTURE.md, conventions).
inline constexpr const char* kApiSincePath = "tools/common/api_since.json";
std::string api_since(std::string_view section, std::string_view key);
// "Since 0.1.3" or "Not released yet (on main after 0.1.6)".
std::string api_since_label(const std::string& since);
// The types/factoria.d.ts text with @since tags on components, fields and script exports added after 0.1.0.
std::string export_typescript(const ScriptSystem& scripts);

Json export_components_json();  // TypeRegistry::global().describe_all() (built-ins registered first)
std::string export_components_markdown();
Json export_commands_json(const CommandRegistry& registry);  // registry.describe()
std::string export_commands_markdown(const CommandRegistry& registry);
// The sentence that ends the description MCP sends for a command that has CommandInfo::details ("" without): where the rest is.
std::string command_details_pointer(const CommandInfo& info);

// The browsable reference: docs/COMPONENTS.md plus docs/reference/ (index, one page per component and command category).
// Paths are relative to the docs folder, forward slashes, sorted; the text is LF-only and platform independent.
// `docs.write_reference` writes them; the test api_reference keeps the committed copies current.
struct ApiReferencePage {
    std::string path;
    std::string text;
};
// `factoria api --md`: components, commands and the scripting API (TypeScript declarations) in one text.
std::string export_api_markdown(const CommandRegistry& registry, const ScriptSystem& scripts);
std::vector<ApiReferencePage> export_api_reference(const CommandRegistry& registry, const ScriptSystem& scripts);

// The tools table of docs/AI_GUIDE.md section 4: one row per command category (tool names, one-line purpose), between
// `<!-- generated: tools table ... -->` and `<!-- end generated -->`. splice_ai_guide_tools_table replaces that block of
// `guide` (false, with *error, when the markers are missing); docs.write_reference does it for <out>/AI_GUIDE.md.
// ai_guide_categories_without_purpose lists the categories the generator has no one-line purpose for (a test fails on any).
std::string export_ai_guide_tools_table(const CommandRegistry& registry);
bool splice_ai_guide_tools_table(std::string& guide, const CommandRegistry& registry, std::string* error);
std::vector<std::string> ai_guide_categories_without_purpose(const CommandRegistry& registry);

// Registers "docs.components" and "docs.commands" (format: markdown | json). They live in the docs
// area so they never collide with the runtime's own api.* commands.
void register_api_export_commands(CommandRegistry& registry);
// Registers "docs.write_reference" (needs the script system for the typings); register_project_commands calls it.
void register_api_reference_command(CommandRegistry& registry, const ScriptSystem& scripts);

}  // namespace fa
