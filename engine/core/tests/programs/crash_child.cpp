// The program tests/test_crash.cpp runs: installs the crash reporter, logs a line, then dies the way its argument says.
//
//   fa_crash_child <report folder> <mode>
//   modes: clean | null-write | abort | uncaught | stack-overflow | invalid-parameter and pure-call (MSVC only)
//
// It dies on purpose: run it through ctest (the "core" test), not by hand. Its functions are exported (dllexport, or
// default visibility + -rdynamic) so the stack of the report names them even without symbol files (a mangled name still
// contains the function name).
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <stdexcept>
#include <string>

#include "fa/core/crash.h"
#include "fa/core/log.h"

#if defined(_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#if defined(_MSC_VER)
#include <crtdbg.h>
#endif
#define FA_CRASH_FUNCTION __declspec(dllexport) __declspec(noinline)
#else
#include <sys/resource.h>
#define FA_CRASH_FUNCTION __attribute__((visibility("default"), noinline))
#endif

namespace {

volatile int g_stop = 0;  // never set: keeps the compiler from proving the recursion endless

// No dialogs and no core files: a crashing child must end quickly on a CI machine nobody watches.
void no_crash_dialogs() {
#if defined(_WIN32)
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
#if defined(_MSC_VER)
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#ifdef _DEBUG
    for (int type : {_CRT_WARN, _CRT_ERROR, _CRT_ASSERT}) _CrtSetReportMode(type, 0);
#endif
#endif
#else
    const rlimit none{0, 0};
    setrlimit(RLIMIT_CORE, &none);
#endif
}

}  // namespace

FA_CRASH_FUNCTION void fa_crash_child_null_write() {
    volatile int* volatile target = nullptr;  // volatile twice: a visible null store is dropped or turned into a trap
    *target = 42;
}
FA_CRASH_FUNCTION void fa_crash_child_abort() { std::abort(); }
FA_CRASH_FUNCTION void fa_crash_child_uncaught() { throw std::runtime_error("boom from the crash test"); }
FA_CRASH_FUNCTION int fa_crash_child_recurse(int depth) {
    volatile char padding[1024];
    padding[0] = char(depth);
    if (g_stop) return depth;
    return fa_crash_child_recurse(depth + 1) + padding[0];
}
#ifdef _MSC_VER
// A bad argument to a CRT function runs the invalid-parameter handler.
FA_CRASH_FUNCTION void fa_crash_child_invalid_parameter() { strcpy_s(nullptr, 10, "x"); }

struct PureBase {
    PureBase() { run(); }
    virtual ~PureBase() = default;
    virtual void step() = 0;
    __declspec(noinline) void run() { step(); }  // a virtual call from the constructor: the slot still holds _purecall
};
struct PureDerived : PureBase {
    void step() override {}
};
FA_CRASH_FUNCTION void fa_crash_child_pure_call() { PureDerived derived; }
#endif

int main(int argc, char** argv) {
    if (argc != 3) {
        std::fprintf(stderr, "usage: fa_crash_child <report folder> <clean|null-write|abort|uncaught|stack-overflow>\n");
        return 2;
    }
    no_crash_dialogs();
    fa::CrashReporterOptions options;
    options.dir = argv[1];
    options.info = {"game: Crash Test 1.2.3"};
    if (auto installed = fa::install_crash_reporter(options); !installed.ok()) {
        std::fprintf(stderr, "%s\n", installed.error().to_string().c_str());
        return 3;
    }
    const std::string mode = argv[2];
    FA_INFO("crashtest", "about to crash: {}", mode);
    if (mode == "clean") return 0;
    if (mode == "null-write") fa_crash_child_null_write();
    else if (mode == "abort") fa_crash_child_abort();
    else if (mode == "uncaught") fa_crash_child_uncaught();
    else if (mode == "stack-overflow") return fa_crash_child_recurse(0);
#ifdef _MSC_VER
    else if (mode == "invalid-parameter") fa_crash_child_invalid_parameter();
    else if (mode == "pure-call") fa_crash_child_pure_call();
#endif
    else {
        std::fprintf(stderr, "unknown mode '%s'\n", mode.c_str());
        return 2;
    }
    return 4;  // not reached: the crash ended the process
}
