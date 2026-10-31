#include "fa/tooling/user_config.h"

#include <cstdlib>
#include <filesystem>

namespace fa {

namespace fsys = std::filesystem;

UserConfigEnv system_user_config_env() {
    return [](const std::string& name) -> std::string {
        const char* v = std::getenv(name.c_str());
        return v ? v : "";
    };
}

std::string user_config_dir(const UserConfigEnv& env) {
    if (auto o = env("FACTORIA_AI_CONFIG"); !o.empty()) {
        const fsys::path parent = fsys::path(o).parent_path();
        return parent.empty() ? std::string(".") : parent.string();
    }
#ifdef _WIN32
    if (auto a = env("APPDATA"); !a.empty()) return (fsys::path(a) / "factoria").string();
    if (auto h = env("USERPROFILE"); !h.empty()) return (fsys::path(h) / ".factoria").string();
#else
    if (auto h = env("HOME"); !h.empty()) return (fsys::path(h) / ".factoria").string();
#endif
    return ".factoria";
}

}  // namespace fa
