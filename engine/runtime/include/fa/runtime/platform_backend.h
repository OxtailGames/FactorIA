// Which platform backend an engine runs (docs/PLATFORM.md, "Which backend runs"): a store plugin's, the fake, or none.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "fa/runtime/plugins.h"
#include "fa/services/platform.h"

namespace fa {

struct BackendChoice {
    std::unique_ptr<PlatformBackend> backend;  // never null
    // One sentence on why this backend runs, for PlatformServices::set_backend ("the plugin 'steam' registered it").
    std::string why;
    // The line the engine logs at info level: why this backend runs ("no store backend on macos, using the fake
    // backend: purchases are not real (docs/PLATFORM.md)"). Empty when a plugin's backend was chosen without a doubt.
    std::string reason;
    // Mistakes in how the backend is chosen (several plugin backends and no "platform.backend"; a name that matches no
    // plugin): logged as warnings and listed in the startup problems.
    std::vector<std::string> warnings;
};

// Chooses the backend for `platform` ("windows", "macos", ...).
//   requested  EngineConfig::platformBackend: "" = automatic, "fake", "none", or the name of a plugin that has a backend.
//   fallback   EngineConfig::platformFallback: what runs when automatic finds no plugin backend: "fake" (development) or
//              "none" (exported games: they must never get free purchases from the fake).
//   catalog    its backend_for(platform) names the plugin when several offer a backend.
//   plugins    what install_plugins returned.
BackendChoice choose_platform_backend(const std::string& requested, const std::string& fallback, const PlatformCatalog& catalog,
                                      const PluginInstall& plugins, const std::string& platform);

}  // namespace fa
