// A stand-in for steamcmd, butler, BuildPatchTool and GOGGalaxyPipelineBuilder in the tests of publish.*: it records how it
// was called, prints a few lines, and exits as told. No test talks to a real store.
//   FA_FAKE_TOOL_RECORD     file the call is appended to: "call", one "arg: <text>" line per argument, one "env: NAME=value"
//                           line per variable named in FA_FAKE_TOOL_ENV (comma separated), "end"
//   FA_FAKE_TOOL_ECHO       name of a variable whose value is printed on stdout (to see that a secret is scrubbed from the log)
//   FA_FAKE_TOOL_PRINT_ARGS set (to anything): every argument is printed on stdout too
//   FA_FAKE_TOOL_EXIT       exit code (default 0)
//   FA_FAKE_TOOL_FAIL_CALL  the number of the call that exits with FA_FAKE_TOOL_FAIL_CODE (default 7) instead
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <sstream>
#include <string>

namespace {

std::string env(const char* name) {
    const char* v = std::getenv(name);
    return v ? v : "";
}

int calls_so_far(const std::string& record) {
    std::ifstream in(record);
    int n = 0;
    for (std::string line; std::getline(in, line);)
        if (line == "call") ++n;
    return n;
}

}  // namespace

int main(int argc, char** argv) {
    const std::string record = env("FA_FAKE_TOOL_RECORD");
    int call = 1;
    if (!record.empty()) {
        call = calls_so_far(record) + 1;
        std::ofstream out(record, std::ios::app);
        out << "call\n";
        for (int i = 1; i < argc; ++i) out << "arg: " << argv[i] << "\n";
        std::stringstream names(env("FA_FAKE_TOOL_ENV"));
        for (std::string name; std::getline(names, name, ',');) out << "env: " << name << "=" << env(name.c_str()) << "\n";
        out << "end\n";
    }
    std::printf("fake store tool: call %d with %d argument(s)\n", call, argc - 1);
    if (!env("FA_FAKE_TOOL_PRINT_ARGS").empty())
        for (int i = 1; i < argc; ++i) std::printf("argument %d: %s\n", i, argv[i]);
    if (const std::string echo = env("FA_FAKE_TOOL_ECHO"); !echo.empty()) std::printf("echo %s=%s\n", echo.c_str(), env(echo.c_str()).c_str());
    std::fprintf(stderr, "fake store tool: a line on stderr\n");
    std::fflush(stdout);
    if (const std::string failCall = env("FA_FAKE_TOOL_FAIL_CALL"); !failCall.empty() && std::atoi(failCall.c_str()) == call) {
        const std::string code = env("FA_FAKE_TOOL_FAIL_CODE");
        return code.empty() ? 7 : std::atoi(code.c_str());
    }
    const std::string exitCode = env("FA_FAKE_TOOL_EXIT");
    return exitCode.empty() ? 0 : std::atoi(exitCode.c_str());
}
