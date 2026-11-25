#include "fa/runtime/gpu_backend_choice.h"

#include "fa/core/strings.h"

namespace fa {

namespace {

Result<GpuBackend> parse_named(const std::string& value, const std::string& where) {
    if (auto b = parse_gpu_backend_name(value)) return *b;
    std::vector<std::string> names = gpu_backend_names();
    std::string list = "\"auto\"";
    for (const std::string& n : names) list += ", \"" + n + "\"";
    names.push_back("auto");
    std::string hint = did_you_mean(value, names);
    if (!hint.empty()) hint += " ";
    return make_error(where + ": unknown GPU backend \"" + value + "\"", hint + "Use one of " + list + ".");
}

}  // namespace

Result<GpuBackendChoice> choose_gpu_backend(const std::string& configValue, const char* envValue,
                                            const std::string& projectValue) {
    GpuBackendChoice c;
    std::string where;
    if (!configValue.empty()) {
        c.asked = configValue;
        c.source = "EngineConfig";
        where = "EngineConfig.gpuBackend";
    } else if (envValue && *envValue) {
        c.asked = envValue;
        c.source = "FA_GPU_BACKEND";
        where = "the FA_GPU_BACKEND environment variable";
    } else if (!projectValue.empty() && projectValue != "auto") {
        c.asked = projectValue;
        c.source = "factoria.json";
        where = "factoria.json /render/backend";
    } else {
        return c;
    }
    auto parsed = parse_named(c.asked, where);
    if (!parsed) return parsed.error();
    c.requested = parsed.value();
    if (!gpu_backend_available(parsed.value())) {
        std::string has;
        for (const std::string& n : gpu_backend_names())
            if (auto b = parse_gpu_backend_name(n); b && gpu_backend_available(*b))
                has += (has.empty() ? "" : ", ") + n;
        c.warnings.push_back(where + " asks for the " + c.asked +
                             " backend, which this platform or this build does not have (it has: " +
                             (has.empty() ? std::string("none") : has) + "); using auto.");
        return c;
    }
    c.backend = parsed.value();
    return c;
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
                                        bool windowed) {
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

}  // namespace fa
