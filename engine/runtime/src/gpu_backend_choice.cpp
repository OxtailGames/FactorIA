#include "fa/runtime/gpu_backend_choice.h"

#include <cstdlib>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"

namespace fa {

namespace {

std::string names_list() {
    std::string list = "\"auto\"";
    for (const std::string& n : gpu_backend_names()) list += ", \"" + n + "\"";
    return list;
}

Result<GpuBackend> parse_named(const std::string& value, const std::string& where) {
    if (auto b = parse_gpu_backend_name(value)) return *b;
    std::vector<std::string> names = gpu_backend_names();
    names.push_back("auto");
    std::string hint = did_you_mean(value, names);
    if (!hint.empty()) hint += " ";
    return make_error(where + ": unknown GPU backend \"" + value + "\"", hint + "Use one of " + names_list() + ".");
}

std::string available_list() {
    std::string has;
    for (const std::string& n : gpu_backend_names())
        if (auto b = parse_gpu_backend_name(n); b && gpu_backend_available(*b)) has += (has.empty() ? "" : ", ") + n;
    return has.empty() ? std::string("none") : has;
}

}  // namespace

std::string gpu_window_path_reason(const std::string& backend, const std::string& why) {
    return std::string(kGpuWindowPathReason) + " (the " + backend + " backend cannot make its swapchain on it: " + why +
           ")";
}

bool is_gpu_window_path_reason(const std::string& reason) { return reason.rfind(kGpuWindowPathReason, 0) == 0; }

GpuBackendInputs make_gpu_backend_inputs(const std::string& configValue, bool readStored, GpuBackend autoBackend,
                                         const std::string& projectValue, std::string* storedWarning) {
    GpuBackendInputs in;
    in.config = configValue;
    in.env = std::getenv("FA_GPU_BACKEND");
    if (readStored) in.user = read_gpu_backend_setting(fs::user_dir(), storedWarning);
    in.project = projectValue;
    in.autoBackend = autoBackend;
    in.fallbackFrom = std::getenv(kGpuFallbackFromEnv);
    in.fallbackReason = std::getenv(kGpuFallbackReasonEnv);
    return in;
}

Result<GpuBackendChoice> choose_gpu_backend(const GpuBackendInputs& in) {
    GpuBackendChoice c;
    if (in.fallbackFrom && *in.fallbackFrom) {
        c.fallbackFrom = in.fallbackFrom;
        c.fallbackReason = in.fallbackReason ? in.fallbackReason : "";
    }
    std::string where;
    if (!in.config.empty()) {
        c.asked = in.config;
        c.source = "EngineConfig";
        where = "EngineConfig.gpuBackend";
    } else if (in.env && *in.env) {
        c.asked = in.env;
        c.source = "FA_GPU_BACKEND";
        where = "the FA_GPU_BACKEND environment variable";
    } else if (!in.user.empty() && parse_gpu_backend_name(in.user)) {
        c.asked = in.user;
        c.source = "user settings";
        where = std::string("the stored choice (") + kGpuBackendSettingFile + ", graphics.backend)";
    } else if (!in.project.empty() && in.project != "auto") {
        c.asked = in.project;
        c.source = "factoria.json";
        where = "factoria.json /render/backend";
    }
    if (!in.user.empty() && !parse_gpu_backend_name(in.user) && c.source != "EngineConfig" &&
        c.source != "FA_GPU_BACKEND") {
        auto bad = parse_named(in.user, std::string("the stored choice (") + kGpuBackendSettingFile + ")");
        c.warnings.push_back(bad.error().message + "; it is ignored. " + bad.error().hint +
                             " graphics.backend {\"name\": \"auto\"} forgets it.");
    }
    if (!c.asked.empty()) {
        auto parsed = parse_named(c.asked, where);
        if (!parsed) return parsed.error();
        c.requested = parsed.value();
        if (gpu_backend_available(parsed.value())) {
            c.backend = parsed.value();
        } else if (c.fallbackFrom.empty() || c.fallbackFrom != gpu_backend_name(parsed.value())) {
            c.warnings.push_back(where + " asks for the " + c.asked +
                                 " backend, which this platform or this build does not have (it has: " +
                                 available_list() + "); using auto.");
        }  // else the marker's warning below says it
    }
    // Auto in this binary: the Vulkan player draws with Vulkan, unless the marker says Vulkan already failed.
    if (c.backend == GpuBackend::Default && in.autoBackend != GpuBackend::Default &&
        gpu_backend_available(in.autoBackend) && c.fallbackFrom != gpu_backend_name(in.autoBackend))
        c.backend = in.autoBackend;
    if (!c.fallbackFrom.empty()) {
        const std::string drawsWith = c.backend == GpuBackend::Default ? std::string(Renderer::backend_name())
                                                                       : std::string(gpu_backend_name(c.backend));
        if (is_gpu_window_path_reason(c.fallbackReason)) {
            // Not a broken driver: the window of this platform cannot take that backend's swapchain yet. Nothing a driver
            // update or an install brings back, so the warning does not say so.
            c.warnings.push_back(
                "The " + c.fallbackFrom + " player started and handed this window over: " + c.fallbackReason +
                ". This player started in its place and draws with " + drawsWith + ". graphics.backend says the same.");
        } else {
            c.warnings.push_back("The " + c.fallbackFrom + " player could not start (" +
                                 (c.fallbackReason.empty() ? std::string("no reason given") : c.fallbackReason) +
                                 "), so this player started in its place and draws with " + drawsWith +
                                 ". graphics.backend says the same; a driver update or installing " + c.fallbackFrom +
                                 " brings it back.");
        }
    }
    return c;
}

Result<GpuBackendChoice> choose_gpu_backend(const std::string& configValue, const char* envValue,
                                            const std::string& projectValue) {
    GpuBackendInputs in;
    in.config = configValue;
    in.env = envValue;
    in.project = projectValue;
    return choose_gpu_backend(in);
}

std::string gpu_backend_fallback_warning(GpuBackend asked, const std::string& why, const std::string& used,
                                         bool windowed) {
    const std::string name = gpu_backend_name(asked);
    return "The " + name + " backend could not start (" + why + "); " +
           (windowed ? "the window" : "this headless run") + " draws with the " + used +
           " backend of this build instead (hint: fix what the error says, or set "
           "render.backend to \"auto\" in factoria.json, FA_GPU_BACKEND or EngineConfig.gpuBackend to stop asking "
           "for " +
           name + ").";
}

GpuBackendStartResult start_gpu_backend(GpuBackend asked, const GpuBackendStart& start, const std::string& defaultName,
                                        bool windowed, const GpuBackendFailed& failed) {
    GpuBackendStartResult r;
    r.used = asked;
    const std::string first = start ? start(asked) : std::string("no start function");
    if (first.empty()) {
        r.ok = true;
        return r;
    }
    if (gpu_backend_on_context(asked)) {  // the build's own backend: nothing to fall back to
        r.error = first;
        return r;
    }
    r.fallbackReason = first;
    // Before the in-process fallback: the host may take the process over (the Vulkan player starts the OpenGL player), and
    // then the fallback below never hides the failure. It returns when the host does nothing or could not.
    if (failed) failed(first);
    r.warning = gpu_backend_fallback_warning(asked, first, defaultName, windowed);
    r.used = GpuBackend::Default;
    const std::string second = start(GpuBackend::Default);
    if (second.empty()) {
        r.ok = true;
        return r;
    }
    r.error = std::string("the ") + gpu_backend_name(asked) + " backend failed (" + first + "), and so did the " +
              defaultName + " backend of this build (" + second + ")";
    return r;
}

std::string read_gpu_backend_setting(const std::filesystem::path& userDir, std::string* warning) {
    if (userDir.empty()) return {};
    const std::filesystem::path file = userDir / kGpuBackendSettingFile;
    std::error_code ec;
    if (!std::filesystem::is_regular_file(fs::os_path(file), ec)) return {};
    const std::string where = fs::path_to_utf8(file);
    auto text = fs::read_text(where);
    if (!text) {
        if (warning) *warning = where + ": cannot read the stored GPU backend (" + text.error().message + "); ignored.";
        return {};
    }
    Json j = Json::parse(text.value(), nullptr, false);
    if (!j.is_object() || !j.contains("backend") || !j["backend"].is_string()) {
        if (warning)
            *warning = where +
                       ": expected {\"backend\": \"<name>\"} (what graphics.backend {\"name\"} writes); the file is "
                       "ignored. Call graphics.backend {\"name\": \"auto\"} to remove it.";
        return {};
    }
    return j["backend"].get<std::string>();
}

Result<void> write_gpu_backend_setting(const std::filesystem::path& userDir, const std::string& name) {
    if (userDir.empty())
        return make_error("graphics.backend: this run has no save folder to store the choice in",
                          "Run the game from a project or an exported player (fs::user_dir()).");
    const std::filesystem::path file = userDir / kGpuBackendSettingFile;
    if (name == "auto") {
        std::error_code ec;
        std::filesystem::remove(fs::os_path(file), ec);
        if (ec)
            return make_error("graphics.backend: cannot remove " + fs::path_to_utf8(file) + ": " + ec.message(),
                              "Close any program that holds the file open and call graphics.backend again.");
        return {};
    }
    Json j = Json::object({{"backend", name}});
    if (auto w = fs::write_text(fs::path_to_utf8(file), j.dump(2) + "\n"); !w)
        return make_error("graphics.backend: cannot store the choice in " + fs::path_to_utf8(file) + ": " +
                              w.error().message,
                          "Check that the save folder can be written; the choice was not changed.");
    return {};
}

}  // namespace fa
