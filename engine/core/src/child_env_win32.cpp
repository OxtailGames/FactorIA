// The environment block of a child process on Windows (run_process and ChildProcess).
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <algorithm>
#include <string>
#include <vector>

#include "child_env.h"

namespace fa::detail {

namespace {

std::wstring widen_utf8(const std::string& s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring w(static_cast<std::size_t>(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
    return w;
}

std::string narrow_utf8(const std::wstring& w) {
    if (w.empty()) return {};
    int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()), nullptr, 0, nullptr, nullptr);
    std::string s(static_cast<std::size_t>(n), '\0');
    WideCharToMultiByte(CP_UTF8, 0, w.data(), static_cast<int>(w.size()), s.data(), n, nullptr, nullptr);
    return s;
}

// The name of "NAME=value". A name may itself start with '=' ("=C:=C:\dir": the current directory of drive C).
std::wstring name_of(const std::wstring& var) { return var.substr(0, var.find(L'=', 1)); }

}  // namespace

std::wstring build_environment_block(const std::optional<std::vector<std::string>>& inherit,
                                     const std::map<std::string, std::string>& env,
                                     const std::vector<std::string>& unsetEnv) {
    std::vector<std::wstring> vars;
    LPWCH base = GetEnvironmentStringsW();
    for (LPWCH p = base; p && *p;) {
        std::wstring s = p;
        p += s.size() + 1;
        if (child_env_keeps(inherit, env, unsetEnv, narrow_utf8(name_of(s)), true)) vars.push_back(std::move(s));
    }
    if (base) FreeEnvironmentStringsW(base);
    for (const auto& [k, v] : env) vars.push_back(widen_utf8(k) + L"=" + widen_utf8(v));
    // CreateProcess documents the order: alphabetical by name, case-insensitive Unicode, no locale.
    std::stable_sort(vars.begin(), vars.end(), [](const std::wstring& a, const std::wstring& b) {
        const std::wstring na = name_of(a), nb = name_of(b);
        return CompareStringOrdinal(na.c_str(), static_cast<int>(na.size()), nb.c_str(), static_cast<int>(nb.size()), TRUE) ==
               CSTR_LESS_THAN;
    });
    std::wstring block;
    for (const std::wstring& v : vars) {
        block += v;
        block.push_back(L'\0');
    }
    if (vars.empty()) block.push_back(L'\0');
    block.push_back(L'\0');
    return block;
}

}  // namespace fa::detail
