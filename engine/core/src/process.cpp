#include "fa/core/process.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>

namespace fa {

namespace fs = std::filesystem;

#ifdef _WIN32
static constexpr char kPathSep = ';';
#else
static constexpr char kPathSep = ':';
#endif

static bool is_executable_file(const fs::path& p) {
    std::error_code ec;
    if (!fs::is_regular_file(p, ec)) return false;
#ifdef _WIN32
    return true;
#else
    auto perms = fs::status(p, ec).permissions();
    return (perms & (fs::perms::owner_exec | fs::perms::group_exec | fs::perms::others_exec)) != fs::perms::none;
#endif
}

std::string which(std::string_view name) {
    if (name.empty()) return {};
    std::vector<std::string> exts{""};
#ifdef _WIN32
    {
        const char* pe = std::getenv("PATHEXT");
        std::string s = pe ? pe : ".COM;.EXE;.BAT;.CMD";
        exts.clear();
        std::size_t i = 0;
        while (i <= s.size()) {
            auto j = s.find(';', i);
            if (j == std::string::npos) j = s.size();
            if (j > i) exts.push_back(s.substr(i, j - i));
            i = j + 1;
        }
        exts.push_back("");
    }
#endif
    auto try_dir = [&](const fs::path& dir) -> std::string {
        for (const auto& e : exts) {
            fs::path p = dir / (std::string(name) + e);
            if (is_executable_file(p)) return p.string();
        }
        return {};
    };
    std::string n(name);
    if (n.find('/') != std::string::npos || n.find('\\') != std::string::npos) {
        for (const auto& e : exts) {
            fs::path p = n + e;
            if (is_executable_file(p)) return fs::absolute(p).string();
        }
        return {};
    }
    const char* pathEnv = std::getenv("PATH");
    if (!pathEnv) return {};
    std::string path = pathEnv;
    std::size_t i = 0;
    while (i <= path.size()) {
        auto j = path.find(kPathSep, i);
        if (j == std::string::npos) j = path.size();
        if (j > i) {
            auto r = try_dir(path.substr(i, j - i));
            if (!r.empty()) return r;
        }
        i = j + 1;
    }
    return {};
}

namespace {
char ascii_lower(char c) { return c >= 'A' && c <= 'Z' ? static_cast<char>(c - 'A' + 'a') : c; }
bool same_name(std::string_view a, std::string_view b, bool ci) {
    if (a.size() != b.size()) return false;
    for (std::size_t i = 0; i < a.size(); ++i)
        if (ci ? ascii_lower(a[i]) != ascii_lower(b[i]) : a[i] != b[i]) return false;
    return true;
}
}  // namespace

bool env_name_matches(std::string_view pattern, std::string_view name, bool caseInsensitive) {
    if (!pattern.empty() && pattern.back() == '*') {
        pattern.remove_suffix(1);
        return name.size() >= pattern.size() && same_name(pattern, name.substr(0, pattern.size()), caseInsensitive);
    }
    return same_name(pattern, name, caseInsensitive);
}

const std::vector<std::string>& base_child_env() {
    // Each name is here because a program started from a shell breaks or misbehaves without it, and none holds a secret.
    static const std::vector<std::string> names = {
        "PATH",  // finds the programs a hook or an agent runs
        "HOME",  // where tools keep their config and credentials (Claude Code finds its login and, on macOS, the keychain by it)
        "USER", "LOGNAME",        // who runs it (git, ssh, keychain tools)
        "SHELL",                  // what a tool starts for its own shell commands
        "TMPDIR", "TEMP", "TMP",  // the temporary folder (POSIX / Windows)
        "LANG", "LANGUAGE", "LC_*",  // locale: the encoding of the output
        "TERM", "TZ",
        "FACTORIA_AI_CONFIG", "FACTORIA_HOME", "FACTORIA_ENGINE_DIR",  // a `factoria` they run finds the same settings and engine
        "FACTORIA_CALLER", "FACTORIA_IN_HOOK",  // who is calling, and that hooks must not start hooks (no loop)
        "FACTORIA_CAPABILITIES", "FACTORIA_ROLE",  // what the role may do and its name: a `factoria` they run keeps the floor
        "FA_CACHE_DIR", "FA_LANGUAGE",          // the cache folder and the language of that `factoria`
#ifdef _WIN32
        "SystemRoot", "SystemDrive", "windir",  // Windows folders: nearly every program needs them (winsock fails without SystemRoot)
        "ComSpec", "PATHEXT",                   // cmd.exe, and which extensions make a file a program
        "USERPROFILE", "HOMEDRIVE", "HOMEPATH", "APPDATA", "LOCALAPPDATA", "ProgramData", "ALLUSERSPROFILE",  // profile folders
        "ProgramFiles*", "ProgramW6432", "CommonProgramFiles*", "CommonProgramW6432",  // installed programs (Node, Git, compilers)
        "USERNAME", "USERDOMAIN", "COMPUTERNAME",  // who and where
        "NUMBER_OF_PROCESSORS", "PROCESSOR_ARCHITECTURE", "OS",  // read by build tools and installers
        "=*",  // per-drive current directories ("=C:"), which cmd.exe and the C runtime keep
#endif
    };
    return names;
}

std::vector<std::string> child_env_allow(const std::vector<std::string>& extra) {
    std::vector<std::string> out = base_child_env();
    for (const std::string& e : extra)
        if (!e.empty() && std::find(out.begin(), out.end(), e) == out.end()) out.push_back(e);
    return out;
}

}  // namespace fa
