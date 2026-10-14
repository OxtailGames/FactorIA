// `factoria`: the single developer binary. See docs/CLI.md.
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

#include "fa/cli/cli.h"

// The AI agents factoria starts (Claude Code, Codex) run `factoria mcp` and `factoria` commands. Put this binary's
// directory first on PATH so they find this very binary even when it was started by path and is not installed.
static void put_self_on_path(const char* argv0) {
    std::filesystem::path dir = std::filesystem::path(argv0).parent_path();
    if (dir.empty()) return;  // started through PATH already
#ifdef _WIN32
    constexpr char sep = ';';
#else
    constexpr char sep = ':';
#endif
    const char* old = std::getenv("PATH");
    std::string path = std::filesystem::absolute(dir).string() + sep + (old ? old : "");
#ifdef _WIN32
    _putenv_s("PATH", path.c_str());
#else
    setenv("PATH", path.c_str(), 1);
#endif
}

int main(int argc, char** argv) {
    if (argc > 0) put_self_on_path(argv[0]);
    std::vector<std::string> args(argv + 1, argv + argc);
    return fa::cli::cli_main(args, std::cout, std::cerr, std::cin);
}
