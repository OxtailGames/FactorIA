// The plugin side of the platform API (private to fa_runtime): what a plugin registered with api->add_backend, the adapter
// that makes it a PlatformBackend, and the FaPluginApi functions that answer its requests (resolve, reject, emit).
#pragma once

#include <memory>
#include <string>
#include <vector>

#include "fa/runtime/fa_plugin.h"
#include "fa/services/platform.h"

namespace fa {

// A checked FaBackendDesc, copied (the plugin's strings may be temporaries).
struct PluginBackendSpec {
    const FaPluginApi* api = nullptr;  // the plugin's api: emit() routes events by it
    std::string plugin;
    std::string name;
    std::vector<std::string> services;
    void (*request)(FaRequest*, const char*, const char*, void*) = nullptr;
    void (*frame)(void*) = nullptr;
    void* user = nullptr;
};

// A backend for one engine that forwards requests to the plugin. Each request gets a FaRequest token, looked up in a
// process-wide table, so a plugin that answers late (the engine is gone) or twice does nothing.
std::unique_ptr<PlatformBackend> make_plugin_backend(const PluginBackendSpec& spec);

// The FaPluginApi members of ABI version 2.
void plugin_resolve(FaRequest* req, const char* resultJson);
void plugin_reject(FaRequest* req, const char* code, const char* message, const char* hint);
void plugin_emit(const FaPluginApi* api, const char* event, const char* dataJson);

}  // namespace fa
