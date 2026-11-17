#define DOCTEST_CONFIG_IMPLEMENT
#include <doctest.h>

#include <cctype>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <set>
#include <string>

// The test executables of fa_authoring and of every module above it (tooling, mcp, dap, ai, editor, cli) see the header of
// fa_authoring through their link dependencies and get its commands in every Engine; the runtime's own tests do not link it,
// so they test exactly what the player has (docs/design/ARCHITECTURE.md, "Repository layout").
#if defined(__has_include)
#if __has_include("fa/authoring/authoring.h")
#include "fa/authoring/authoring.h"
#define FA_TEST_HAS_AUTHORING 1
#endif
#endif

#if defined(_MSC_VER) && !defined(_DLL)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace {

std::string lower_ascii(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

// The file names of "--<option>=a.cpp,b.cpp" (lower case) added to `names`; false when the option is not given.
bool names_option(int argc, char** argv, const char* option, std::set<std::string>& names) {
    const std::string prefix = std::string("--") + option + "=";
    bool found = false;
    for (int i = 1; i < argc; ++i) {
        if (std::strncmp(argv[i], prefix.c_str(), prefix.size()) != 0) continue;
        found = true;
        const std::string rest = argv[i] + prefix.size();
        for (std::size_t from = 0; from <= rest.size();) {
            std::size_t comma = rest.find(',', from);
            if (comma == std::string::npos) comma = rest.size();
            if (comma > from) names.insert(lower_ascii(rest.substr(from, comma - from)));
            from = comma + 1;
        }
    }
    return found;
}

// A path as a doctest source-file filter that matches exactly that path: doctest splits a list at ',' and reads
// "\\" as one '\'.
std::string filter_of(const std::string& path) {
    std::string out;
    for (char c : path) {
        if (c == ',' || c == '\\') out += '\\';
        out += c;
    }
    return out;
}

// --fa-files=a.cpp,b.cpp runs only the test cases written in those files (found by file name, whatever the folder, the
// slashes or the case of the path the compiler saw); --fa-files-exclude=a.cpp,b.cpp runs all but those; both can be
// given. A test executable that CMake splits into several ctest entries (tools/common/CMakeLists.txt) uses them:
// doctest's own --source-file filters match the raw __FILE__ with only '*' and '?', so "*export_test.cpp" would also
// match "web_export_test.cpp", and __FILE__ has backslashes under MSBuild and slashes under Ninja. Two files of one
// executable with the same name are both taken.
void add_file_filters(doctest::Context& context, int argc, char** argv) {
    std::set<std::string> only, except;
    const bool hasOnly = names_option(argc, argv, "fa-files", only);
    names_option(argc, argv, "fa-files-exclude", except);
    if (!hasOnly && except.empty()) return;
    bool anyOnly = false;
    std::set<std::string> seen;
    for (const auto& tc : doctest::detail::getRegisteredTests()) {
        const std::string file = tc.m_file.c_str();
        if (!seen.insert(file).second) continue;
        const std::size_t slash = file.find_last_of("/\\");
        const std::string base = lower_ascii(slash == std::string::npos ? file : file.substr(slash + 1));
        if (only.count(base)) {
            context.addFilter("source-file", filter_of(file).c_str());
            anyOnly = true;
        }
        if (except.count(base)) context.addFilter("source-file-exclude", filter_of(file).c_str());
    }
    // --fa-files that names no file with a test case runs nothing (no filter at all would run everything).
    if (hasOnly && !anyOnly) context.addFilter("source-file", "fa:no source file has these names");
}

}  // namespace

int main(int argc, char** argv) {
#ifdef FA_TEST_HAS_AUTHORING
    fa::authoring::install();
#endif
    doctest::Context context(argc, argv);
    add_file_filters(context, argc, argv);
    int result = context.run();
#if defined(_MSC_VER) && !defined(_DLL)
    // Static MSVC runtime: returning from main tears the CRT down (heap locks, locale) while other threads still run,
    // and a thread that starts in that window (XInput starts some) runs doctest's thread_local std::ostringstream
    // constructors on the dead CRT and crashes. ExitProcess ends the other threads first and leaves the CRT intact.
    // The shipping exes have no thread_local with a constructor, so they do not need this.
    std::cout.flush();
    std::cerr.flush();
    std::fflush(nullptr);
    ExitProcess(static_cast<UINT>(result));
#else
    return result;
#endif
}
