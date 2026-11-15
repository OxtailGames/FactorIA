#include "fa/script/script_budget.h"

#include <cmath>
#include <string>

namespace fa {

const char* script_platform_name() { return FA_PLATFORM_NAME; }

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
