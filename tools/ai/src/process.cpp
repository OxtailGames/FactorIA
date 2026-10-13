#include "fa/ai/process.h"

#include <cstdlib>
#include <filesystem>

namespace fa::ai {

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

}  // namespace fa::ai
