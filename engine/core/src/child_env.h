// The environment of a child process (process_*.cpp, child_process_*.cpp): which variables of this process it inherits.
#pragma once

#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/process.h"

namespace fa::detail {

// Windows compares variable names without regard to case, POSIX with it.
#ifdef _WIN32
inline constexpr bool kEnvNamesIgnoreCase = true;
#else
inline constexpr bool kEnvNamesIgnoreCase = false;
#endif

// Is the variable `name` of this process passed on to the child? Not when `env` sets it (the child gets that value instead) or
// `unsetEnv` removes it; otherwise yes, unless `inherit` is an allow-list that does not name it. `ci`: names ignore case.
inline bool child_env_keeps(const std::optional<std::vector<std::string>>& inherit,
                            const std::map<std::string, std::string>& env, const std::vector<std::string>& unsetEnv,
                            std::string_view name, bool ci) {
    auto same = [&](std::string_view a) {
        if (a.size() != name.size()) return false;
        for (std::size_t i = 0; i < a.size(); ++i) {
            char x = a[i], y = name[i];
            if (ci) {
                if (x >= 'A' && x <= 'Z') x = static_cast<char>(x - 'A' + 'a');
                if (y >= 'A' && y <= 'Z') y = static_cast<char>(y - 'A' + 'a');
            }
            if (x != y) return false;
        }
        return true;
    };
    for (const auto& kv : env)
        if (same(kv.first)) return false;
    for (const std::string& u : unsetEnv)
        if (same(u)) return false;
    if (!inherit) return true;
    for (const std::string& pattern : *inherit)
        if (env_name_matches(pattern, name, ci)) return true;
    return false;
}

#ifdef _WIN32
// The environment block CreateProcessW takes with CREATE_UNICODE_ENVIRONMENT: "NAME=value" strings, each ended by a NUL, sorted
// by name without regard to case, and one more NUL at the end (two in a row when there is no variable at all). Holds the
// variables of this process that child_env_keeps() passes on, then `env`. child_env_win32.cpp.
std::wstring build_environment_block(const std::optional<std::vector<std::string>>& inherit,
                                     const std::map<std::string, std::string>& env,
                                     const std::vector<std::string>& unsetEnv);
#endif

}  // namespace fa::detail
