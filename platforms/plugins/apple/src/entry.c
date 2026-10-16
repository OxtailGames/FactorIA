/* The entry point of the plugin: FA_PLUGIN_INIT defines the exported `fa_plugin_init` (macOS dylib) or, with
 * -DFA_PLUGIN_STATIC, `fa_plugin_init_<name>` (iOS static library: several plugins live in one app). The work is Swift
 * (Plugin.swift, `fa_apple_init`): StoreKit 2 has no Objective-C API. CMakeLists.txt passes FA_PLUGIN_NAME. */
#include "fa_plugin.h"

extern int fa_apple_init(const FaPluginApi* api);

FA_PLUGIN_INIT(FA_PLUGIN_NAME) { return fa_apple_init(api); }
