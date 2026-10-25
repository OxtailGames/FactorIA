// Which platform backend an engine runs (docs/PLATFORM.md, "Which backend runs"): a store plugin's, the fake, or none.
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "fa/platform/http.h"
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
    // The backend that serves only the ads requests (an ads plugin such as admob), or null: the store backend then serves ads
    // if it offers them. Set only when the store backend is a real one: the fake serves ads itself in development runs.
    std::unique_ptr<PlatformBackend> adsBackend;
    // Why ads.* goes where it goes (for PlatformServices::set_ads_backend).
    std::string adsWhy;
    // Mistakes in how the backend is chosen (several plugin backends and no "platform.backend"; a name that matches no
    // plugin): logged as warnings and listed in the startup problems.
    std::vector<std::string> warnings;
};

// The backend that serves http.fetch with `client` (null = this platform's system client, make_system_http_client()). Not part of
// choose_platform_backend: any run that is not headless gets it, whatever store backend runs (docs/NETWORKING.md). It offers the
// "http" service only when the client can run on this computer.
std::unique_ptr<PlatformBackend> make_http_backend(std::unique_ptr<HttpClient> client = nullptr);

// Chooses the backend for `platform` ("windows", "macos", ...).
//   requested  EngineConfig::platformBackend: "" = automatic, "fake", "none", or the name of a plugin that has a backend.
//   fallback   EngineConfig::platformFallback: what runs when automatic finds no plugin backend: "fake" (development) or
//              "none" (exported games: they must never get free purchases from the fake).
//   catalog    its backend_for(platform) names the plugin when several offer a backend; its adsBackend names the ads plugin
//              when several offer one. A plugin whose only service is "ads" is an ads backend, chosen apart from the store's.
//   plugins    what install_plugins returned.
BackendChoice choose_platform_backend(const std::string& requested, const std::string& fallback, const PlatformCatalog& catalog,
                                      const PluginInstall& plugins, const std::string& platform);

}  // namespace fa
