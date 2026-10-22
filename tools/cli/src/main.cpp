// `factoria`: the single developer binary. See docs/CLI.md.
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

#include "fa/cli/cli.h"

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#include <windows.h>

#include <cstdio>
#endif

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
#ifdef _WIN32
    // LF line endings as on the other platforms: in text mode `factoria docs read x > f`, `--json` output and the
    // `session` / `mcp` JSON lines would end every line with \r\n.
    _setmode(_fileno(stdout), _O_BINARY);
    // Double-clicked in Explorer (no shell shares our console, output not captured): open the editor instead of printing
    // help into a window that closes at once, and let the console go.
    // The console still flashes for a moment: FactorIA-Editor.exe (tools/cli/launcher) avoids it.
    DWORD pids[2];
    if (args.empty() && GetConsoleProcessList(pids, 2) == 1 &&
        GetFileType(GetStdHandle(STD_OUTPUT_HANDLE)) == FILE_TYPE_CHAR) {
        FreeConsole();
        args = {"editor"};
    }
#endif
    return fa::cli::cli_main(args, std::cout, std::cerr, std::cin);
}
