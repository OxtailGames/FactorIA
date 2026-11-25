// graphics.backend (M77-P9e2): which GPU backend draws the game, which one was asked for and where from, which ones
// this player has, whether another player fell back to this one; with a name, the choice for the next start, kept in
// the game's user settings (graphics_backend.json in fs::user_dir(), fa/runtime/gpu_backend_choice.h).
#include <string>
#include <vector>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "fa/runtime/internal/engine_impl.h"

namespace fa {

namespace {

Json parse_schema(const char* text) {
    auto r = parse_json(text, "command schema");
    FA_ASSERT(r.ok(), "invalid built-in command schema");
    return r.value();
}

// Backends a choice may name in this player: the ones it has, and on Linux and Android Vulkan, which the Vulkan player
// of the game draws with (the OpenGL player stores it for the next start of the game's launcher).
bool storable(GpuBackend b) {
    if (gpu_backend_available(b)) return true;
#if defined(__linux__)
    return b == GpuBackend::Vulkan;
#else
    return false;
#endif
}

Json available_names() {
    Json out = Json::array();
    for (const std::string& n : gpu_backend_names())
        if (auto b = parse_gpu_backend_name(n); b && gpu_backend_available(*b)) out.push_back(n);
    return out;
}

Json report(Engine::Impl& I) {
    Json out = Json::object();
    const bool drawing = I.renderer != nullptr;
    out["active"] = drawing ? std::string(gpu_backend_name(I.renderer->device_backend())) : std::string("none");
    if (drawing && I.renderer->device_backend() == GpuBackend::Default) out["active"] = "none";
    out["sokolBackend"] = Renderer::backend_name();
    out["requested"] = I.gpuChoice.asked.empty() ? std::string("auto") : I.gpuChoice.asked;
    out["source"] = I.gpuChoice.source.empty() ? std::string("default") : I.gpuChoice.source;
    out["auto"] = (I.gpuBackendAuto != GpuBackend::Default && gpu_backend_available(I.gpuBackendAuto))
                      ? std::string(gpu_backend_name(I.gpuBackendAuto))
                      : std::string(Renderer::backend_name());
    out["available"] = available_names();
    if (I.gpuChoice.fallbackFrom.empty()) {
        out["fallback"] = nullptr;
    } else {
        out["fallback"] = Json::object({{"from", I.gpuChoice.fallbackFrom}, {"reason", I.gpuChoice.fallbackReason}});
    }
    out["stored"] = I.gpuStoredBackend.empty() ? std::string("auto") : I.gpuStoredBackend;
    out["storedIn"] =
        I.gpuStoreInMemory ? std::string("memory") : fs::path_to_utf8(fs::user_dir() / kGpuBackendSettingFile);
    return out;
}

}  // namespace

void register_gpu_backend_commands(Engine& /*engine*/, Engine::Impl& I) {
    I.commands.add(
        {"graphics.backend",
         "Reads which GPU backend draws the game, or stores the one the next start draws with (\"takes effect at the "
         "next start\").",
         "With no argument it reads and changes nothing: {active, sokolBackend, requested, source, auto, available, "
         "fallback, stored, storedIn}. `active` is the backend the renderer draws with (\"none\" without graphics), "
         "`requested` the name asked for and `source` where it came from (\"EngineConfig\", \"FA_GPU_BACKEND\", "
         "\"user settings\", \"factoria.json\" or \"default\"), `auto` what auto draws with in this player, "
         "`available` the backends this player has, `fallback` {from, reason} when another player could not start "
         "its backend and started this one in its place (the Vulkan player of Linux and Android, which hands over to "
         "the OpenGL one), else null. With `name` it stores that choice for the next start in the game's user "
         "settings (`storedIn`: graphics_backend.json in the save folder, or memory in a run with in-memory storage) "
         "and returns the same report plus {changed, takesEffect: \"next start\"}; the backend in use does not "
         "change. \"auto\" forgets the choice. Example: graphics.backend {\"name\":\"gl\"}" FA_COMMAND_DETAILS
         "The order at start: EngineConfig.gpuBackend, the FA_GPU_BACKEND environment variable, the stored choice, "
         "factoria.json render.backend, auto. On Linux and Android an exported game ships two players: the Vulkan "
         "one starts first and runs the OpenGL one when the choice is gl or gles3 or when Vulkan cannot start "
         "(docs/RENDERING.md, \"Choosing the GPU backend\"); there `vulkan` may be stored from the OpenGL player "
         "too. Errors: `invalid_argument` for an unknown name (with a \"did you mean\"), a backend this platform "
         "cannot have, or an unknown argument; `io_error` when the save folder cannot be written. Nothing changes "
         "on an error.",
         parse_schema(R"({"type":"object","properties":{
               "name":{"type":"string","enum":["auto","gl","gles3","webgl2","d3d11","metal","d3d12","vulkan"],"description":"The backend the next start draws with; \"auto\" forgets the stored choice. Leave it out to read."}}})"),
         false, "game"},
        [&I](const Json& a) {
            if (!a.is_null() && !a.is_object())
                throw CommandError("invalid_argument", "graphics.backend: the arguments must be an object",
                                   "Pass {} to read, or {\"name\": \"gl\"} to store a choice.");
            std::vector<std::string> known = {"name"};
            if (a.is_object())
                for (auto it = a.begin(); it != a.end(); ++it)
                    if (it.key() != "name")
                        throw CommandError("invalid_argument",
                                           "graphics.backend: unknown argument '" + it.key() + "'. " +
                                               did_you_mean(it.key(), known),
                                           "The only argument is name.");
            if (!a.is_object() || !a.contains("name")) return report(I);
            if (!a["name"].is_string())
                throw CommandError("invalid_argument", "graphics.backend: /name must be a string",
                                   "Pass a backend name such as \"gl\" or \"vulkan\", or \"auto\".");
            const std::string name = a["name"].get<std::string>();
            std::vector<std::string> names = gpu_backend_names();
            names.insert(names.begin(), "auto");
            auto parsed = parse_gpu_backend_name(name);
            if (!parsed)
                throw CommandError("invalid_argument",
                                   "graphics.backend: unknown GPU backend \"" + name + "\". " +
                                       did_you_mean(name, names),
                                   "Use one of: " + join(names, ", ") + ".");
            if (!storable(*parsed)) {
                Json avail = available_names();
                std::vector<std::string> has;
                for (const Json& n : avail) has.push_back(n.get<std::string>());
                throw CommandError("invalid_argument",
                                   "graphics.backend: this platform has no " + name +
                                       " backend (this player has: auto, " + join(has, ", ") + ")",
                                   "Store one of those, or \"auto\". Nothing was changed.");
            }
            const std::string stored = *parsed == GpuBackend::Default ? std::string() : name;
            const bool changed = stored != I.gpuStoredBackend;
            if (changed && !I.gpuStoreInMemory) {
                if (auto w = write_gpu_backend_setting(fs::user_dir(), stored.empty() ? "auto" : stored); !w)
                    throw CommandError("io_error", w.error().message, w.error().hint);
            }
            I.gpuStoredBackend = stored;
            Json out = report(I);
            out["changed"] = changed;
            out["takesEffect"] = "next start";
            if (!gpu_backend_available(*parsed))
                out["note"] = "This player has no " + name +
                              " backend: the game's Vulkan player draws with it at the "
                              "next start (an export without the Vulkan player warns then and uses auto).";
            return out;
        });
    declare_command_capabilities(I.commands, {
                                                 // The choice is the game's own user setting, as storage.* writes.
                                                 {"graphics.backend", capability_sets::changes_state()},
                                             });
}

}  // namespace fa
