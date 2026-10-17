#include <doctest.h>

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "fa/core/crash.h"
#include "fa/core/fs.h"
#include "fa/core/process.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#endif

using namespace fa;
namespace stdfs = std::filesystem;

namespace {

struct TempDir {
    stdfs::path path = fs::make_temp_dir("crash");
    ~TempDir() {
        std::error_code ec;
        stdfs::remove_all(path, ec);
    }
};

std::string read_file(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

void touch(const stdfs::path& p) { std::ofstream(p, std::ios::binary) << "x"; }

std::vector<std::string> names_in(const stdfs::path& dir) {
    std::vector<std::string> names;
    for (const auto& e : stdfs::directory_iterator(dir)) names.push_back(e.path().filename().string());
    std::sort(names.begin(), names.end());
    return names;
}

#ifdef _WIN32
// Wine maps the first page and handles stack overflow its own way, so the faults these tests cause do not happen there
// (the MinGW + Wine job of scripts/ci-local.sh): only real Windows can answer.
bool running_under_wine() {
    HMODULE ntdll = GetModuleHandleA("ntdll.dll");
    return ntdll && GetProcAddress(ntdll, "wine_get_version") != nullptr;
}
#endif

// Runs tests/programs/crash_child.cpp with `mode`, reporting into `dir`. The path comes from ctest (CMakeLists.txt).
bool run_child(const stdfs::path& dir, const std::string& mode, ProcessResult& out) {
    const char* child = std::getenv("FA_CRASH_CHILD");
    if (!child || !*child) {
        MESSAGE("FA_CRASH_CHILD is not set (the test runs the crash program ctest names): skipped. Run `ctest -R core`.");
        return false;
    }
#ifdef _WIN32
    if (running_under_wine()) {
        MESSAGE("running under Wine, where the faults of these tests do not happen: skipped");
        return false;
    }
#endif
    ProcessOptions po;
    po.argv = {child, dir.string(), mode};
    po.timeoutSeconds = 120;
    auto r = run_process(po);
    REQUIRE_MESSAGE(r.ok(), r.error().to_string());
    out = *r;
    return true;
}

// The one crash-*.txt of `dir`, after checking its name: crash-<UTC time>.txt, e.g. crash-20261017T143052Z.txt.
std::string only_report(const stdfs::path& dir, stdfs::path* path = nullptr) {
    std::vector<stdfs::path> reports;
    for (const auto& e : stdfs::directory_iterator(dir))
        if (e.path().extension() == ".txt") reports.push_back(e.path());
    REQUIRE_MESSAGE(reports.size() == 1, "expected one crash-*.txt in " << dir.string());
    const std::string name = reports[0].filename().string();
    CHECK(name.size() == std::string("crash-20261017T143052Z.txt").size());
    CHECK(name.rfind("crash-", 0) == 0);
    CHECK(name[14] == 'T');
    CHECK(name[21] == 'Z');
    if (path) *path = reports[0];
    return read_file(reports[0]);
}

// Crashes the child with `mode` and checks the report: who wrote it, the stack with `function`, the last log line.
void crash_and_read(const std::string& mode, const std::string& function, const std::string& exceptionText) {
    TempDir dir;
    ProcessResult r;
    if (!run_child(dir.path, mode, r)) return;
    INFO("child stderr: " << r.stderrText);
    CHECK(r.exitCode != 0);
    CHECK(r.stderrText.find("the game crashed, report: ") != std::string::npos);
    const std::string text = only_report(dir.path);
    INFO("report:\n" << text);
    CHECK(text.rfind("FactorIA crash report\nengine: " FA_ENGINE_VERSION, 0) == 0);
    CHECK(text.find("game: Crash Test 1.2.3\n") != std::string::npos);
    CHECK(text.find(exceptionText) != std::string::npos);
    CHECK(text.find("stack (innermost first") != std::string::npos);
    CHECK(text.find(function) != std::string::npos);
    CHECK(text.find("last log lines") != std::string::npos);
    CHECK(text.find("about to crash: " + mode) != std::string::npos);
#ifdef _WIN32
    stdfs::path dump = dir.path;
    for (const auto& e : stdfs::directory_iterator(dir.path))
        if (e.path().extension() == ".dmp") dump = e.path();
    REQUIRE_MESSAGE(dump != dir.path, "no .dmp next to the report");
    const std::string head = read_file(dump).substr(0, 4);
    CHECK(head == "MDMP");
    CHECK(stdfs::file_size(dump) > 4096);
#endif
}

#ifdef _WIN32
constexpr const char* kNullWrite = "access violation, write to 0x0";
constexpr const char* kAbort = "abort() / std::terminate()";
#else
constexpr const char* kNullWrite = "SIGSEGV";
constexpr const char* kAbort = "SIGABRT";
#endif

#ifdef __APPLE__
// macOS builds the stack from the frame pointers and may leave out the function the signal hit (only its callers are in
// the chain; not tried on a Mac yet): any frame of the program will do for these two.
constexpr const char* kNullWriteFrame = "fa_crash_child";
constexpr const char* kRecurseFrame = "fa_crash_child";
#else
constexpr const char* kNullWriteFrame = "fa_crash_child_null_write";
constexpr const char* kRecurseFrame = "fa_crash_child_recurse";
#endif

}  // namespace

TEST_CASE("crash reporter: a null write leaves a report with a stack") {
    crash_and_read("null-write", kNullWriteFrame, kNullWrite);
}

TEST_CASE("crash reporter: abort() leaves a report with a stack") {
    crash_and_read("abort", "fa_crash_child_abort", kAbort);
}

TEST_CASE("crash reporter: an uncaught exception says what was thrown") {
    crash_and_read("uncaught", "fa_crash_child_uncaught", "uncaught exception: boom from the crash test");
}

TEST_CASE("crash reporter: a stack overflow is reported too") {
    crash_and_read("stack-overflow", kRecurseFrame,
#ifdef _WIN32
                   "stack overflow"
#else
                   "signal: SIG"  // SIGSEGV on Linux, SIGSEGV or SIGBUS on macOS
#endif
    );
}

TEST_CASE("crash reporter: a normal exit leaves no report, and only the newest ones are kept") {
    TempDir dir;
    for (const char* stem : {"crash-20200101T000000Z", "crash-20200102T000000Z", "crash-20200103T000000Z",
                             "crash-20200104T000000Z", "crash-20200105T000000Z", "crash-20200106T000000Z",
                             "crash-20200107T000000Z"}) {
        touch(dir.path / (std::string(stem) + ".txt"));
        touch(dir.path / (std::string(stem) + ".dmp"));
    }
    touch(dir.path / "log.txt");  // not a report: stays
    ProcessResult r;
    if (!run_child(dir.path, "clean", r)) return;
    CHECK(r.exitCode == 0);
    const std::vector<std::string> expected = {"crash-20200103T000000Z.dmp", "crash-20200103T000000Z.txt",
                                               "crash-20200104T000000Z.dmp", "crash-20200104T000000Z.txt",
                                               "crash-20200105T000000Z.dmp", "crash-20200105T000000Z.txt",
                                               "crash-20200106T000000Z.dmp", "crash-20200106T000000Z.txt",
                                               "crash-20200107T000000Z.dmp", "crash-20200107T000000Z.txt", "log.txt"};
    CHECK(names_in(dir.path) == expected);
}

TEST_CASE("crash reporter: take_previous_crash_report hands out each report once") {
    TempDir dir;
    CHECK(take_previous_crash_report(dir.path).empty());  // nothing yet
    CHECK(take_previous_crash_report(dir.path / "missing").empty());
    touch(dir.path / "crash-20261001T100000Z.txt");
    touch(dir.path / "crash-20261002T100000Z.txt");
    touch(dir.path / "crash-20261002T100000Z.dmp");
    CHECK(take_previous_crash_report(dir.path) == dir.path / "crash-20261002T100000Z.txt");
    CHECK(take_previous_crash_report(dir.path).empty());  // told once
    touch(dir.path / "crash-20261003T100000Z.txt");
    CHECK(take_previous_crash_report(dir.path) == dir.path / "crash-20261003T100000Z.txt");
    CHECK(take_previous_crash_report(dir.path).empty());
}

TEST_CASE("crash reporter: install errors say what to do") {
    CrashReporterOptions options;
    auto none = install_crash_reporter(options);
    REQUIRE_FALSE(none.ok());
    CHECK_FALSE(none.error().hint.empty());

    TempDir dir;
    touch(dir.path / "file");  // a folder cannot be made below a file
    options.dir = dir.path / "file" / "crashes";
    auto blocked = install_crash_reporter(options);
    REQUIRE_FALSE(blocked.ok());
    CHECK(blocked.error().message.find("file") != std::string::npos);
    CHECK_FALSE(blocked.error().hint.empty());
}

#ifdef _MSC_VER
TEST_CASE("crash reporter: a bad argument to the C runtime is reported") {
    crash_and_read("invalid-parameter", "fa_crash_child",  // any frame of the program: the optimizer folds these two
                   "invalid parameter passed to a C runtime function");
}

TEST_CASE("crash reporter: a pure virtual call is reported") {
    crash_and_read("pure-call", "fa_crash_child", "pure virtual function call");
}
#endif
