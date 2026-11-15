#include "fa/script/script_budget.h"

#include <cmath>
#include <string>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

namespace fa {

const char* script_platform_name() {
#if defined(__ANDROID__)
    return "android";
#elif defined(__APPLE__) && TARGET_OS_IPHONE
    return "ios";
#elif defined(__APPLE__)
    return "macos";
#elif defined(_WIN32)
    return "windows";
#elif defined(__EMSCRIPTEN__)
    return "web";
#else
    return "linux";
#endif
}

double resolve_per_platform_number(const Json& setting, std::string_view platform, double fallback) {
    auto number = [](const Json& v, double& out) {
        if (!v.is_number()) return false;
        const double d = v.get<double>();
        if (!std::isfinite(d)) return false;
        out = d;
        return true;
    };
    double out = fallback;
    if (number(setting, out)) return out;
    if (!setting.is_object()) return fallback;
    if (auto it = setting.find(std::string(platform)); it != setting.end() && number(*it, out)) return out;
    if (auto it = setting.find("default"); it != setting.end() && number(*it, out)) return out;
    return fallback;
}

}  // namespace fa
