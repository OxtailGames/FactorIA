// fa_tooling umbrella header: everything developer tools share.
#pragma once

#include "fa/core/command.h"
#include "fa/tooling/api_export.h"
#include "fa/tooling/asset_import.h"
#include "fa/tooling/audio_analysis.h"
#include "fa/tooling/bundle.h"
#include "fa/tooling/docs.h"
#include "fa/tooling/export.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/feedback.h"
#include "fa/tooling/icons.h"
#include "fa/tooling/mcp_config.h"
#include "fa/tooling/project_fs.h"
#include "fa/tooling/publish.h"
#include "fa/tooling/scaffold.h"
#include "fa/tooling/setup.h"
#include "fa/tooling/setup_parse.h"
#include "fa/tooling/translations.h"
#include "fa/tooling/validate.h"
#include "fa/runtime/engine.h"

namespace fa {

class Engine;

// Registers every tooling command for the project at `projectDir`:
// feedback.{report,list,update}, docs.{list,read,search,components,commands},
// fs.{list,read,write,edit,search,delete}, assets.{import,slice_sheet,analyze_audio}, project.validate, i18n.{export,import}, project.export,
// project.new_plugin, publish.{steam,itch,epic,gog}, setup.{status,install}.
void register_tooling_commands(CommandRegistry& registry, const std::string& projectDir);

// project.new_plugin: writes a native plugin from platforms/plugin/ and declares it in factoria.json (plugin_scaffold.cpp).
void register_plugin_commands(CommandRegistry& registry, const std::string& projectDir);

// platform.add_backend: sets a store backend plugin (Steamworks, Apple, Google Play) up in a game (platform_setup.cpp).
// `androidSearch` (tests): where the Google Play backend looks for the Android SDK instead of the usual folders; it must
// outlive the registry.
void register_platform_setup_commands(CommandRegistry& registry, const std::string& projectDir,
                                      const AndroidToolchainSearch* androidSearch = nullptr);

}  // namespace fa

namespace fa {

// ONE command set everywhere (`factoria mcp/call/session/test/ai run`, the editor): registers on engine.commands()
//   register_tooling_commands(...)  plus project.templates, project.create, and a project.validate bound to this
//   engine (script syntax via check_syntax, Script.props via check_props, misspelled hooks via check_hooks).
// project.test is a built-in engine command. Call it once after Engine::init; a second call replaces the commands.
void register_project_commands(Engine& engine, const std::string& projectDir);

// Validation options backed by `engine`'s script system (syntax, Script.props and hook-name checks). The engine must
// outlive them.
ValidateOptions engine_validate_options(Engine& engine);

}  // namespace fa
