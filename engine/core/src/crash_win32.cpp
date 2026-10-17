// Windows crash handler: see fa/core/crash.h. An unhandled exception, abort() / std::terminate, an invalid CRT
// parameter or a pure virtual call writes <dir>/crash-<UTC>.txt (exception, stack, last log lines) and .dmp (minidump).
//
// The report is written by a helper thread while the crashed thread waits: after a stack overflow the crashed thread has
// no stack left to walk and write with, and the helper has a fresh one. The helper does not allocate in the parts that
// matter most (header, exception, log lines are written first); dbghelp (stack names, minidump) comes after them.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <dbghelp.h>
#include <signal.h>
#include <stdlib.h>

#include <cstdio>
#include <cstring>
#include <cwchar>
#include <exception>
#include <string>

#include "crash_internal.h"

#if defined(_M_X64) || defined(__x86_64__)
#define FA_CRASH_X64 1
#endif

namespace fa::crash_detail {
namespace {

constexpr DWORD kWaitMs = 30000;  // the helper thread has this long; then the process ends without a finished report

// Codes of the "exceptions" we make up for crashes that are not exceptions.
constexpr DWORD kCodeAbort = 0xE0FA0001;
constexpr DWORD kCodeInvalidParameter = 0xE0FA0002;
constexpr DWORD kCodePureCall = 0xE0FA0003;

wchar_t g_dir[kMaxDirLength + 1];
LONG g_busy = 0;
volatile DWORD g_writerThread = 0;

struct Job {
    EXCEPTION_POINTERS* pointers;
    DWORD threadId;  // the crashed thread
};

const char* exception_name(DWORD code) {
    switch (code) {
        case EXCEPTION_ACCESS_VIOLATION: return "access violation";
        case EXCEPTION_IN_PAGE_ERROR: return "in-page error (a memory-mapped file could not be read)";
        case EXCEPTION_STACK_OVERFLOW: return "stack overflow";
        case EXCEPTION_ILLEGAL_INSTRUCTION: return "illegal instruction";
        case EXCEPTION_PRIV_INSTRUCTION: return "privileged instruction";
        case EXCEPTION_INT_DIVIDE_BY_ZERO: return "integer division by zero";
        case EXCEPTION_INT_OVERFLOW: return "integer overflow";
        case EXCEPTION_FLT_DIVIDE_BY_ZERO: return "floating-point division by zero";
        case EXCEPTION_ARRAY_BOUNDS_EXCEEDED: return "array bounds exceeded";
        case EXCEPTION_DATATYPE_MISALIGNMENT: return "misaligned data access";
        case EXCEPTION_BREAKPOINT: return "breakpoint";
        case 0xE06D7363: return "uncaught C++ exception";
        case 0xC0000374: return "heap corruption";
        case 0xC0000409: return "fast fail (stack buffer overrun, __fastfail)";
        case kCodeAbort: return "abort() / std::terminate()";
        case kCodeInvalidParameter: return "invalid parameter passed to a C runtime function";
        case kCodePureCall: return "pure virtual function call";
    }
    return "unhandled exception";
}

DWORD64 program_counter(const CONTEXT& context) {
#ifdef FA_CRASH_X64
    return context.Rip;
#else
    (void)context;
    return 0;
#endif
}

void write_all(HANDLE file, const char* p, std::size_t n) {
    while (n > 0) {
        DWORD written = 0;
        if (!WriteFile(file, p, DWORD(n), &written, nullptr) || written == 0) return;
        p += written;
        n -= written;
    }
}

void flush(HANDLE file, LineBuf& b) {
    write_all(file, b.data, b.n);
    b.clear();
}

const char* base_name(const char* path) {
    const char* name = path;
    for (const char* p = path; *p; ++p)
        if (*p == '\\' || *p == '/') name = p + 1;
    return name;
}

// <dir>\crash-<stamp><extension> into `out`.
void report_path(wchar_t* out, std::size_t capacity, const Civil& when, const wchar_t* extension) {
    LineBuf stamp;
    stamp.stamp(when);
    std::size_t n = 0;
    auto put = [&](wchar_t c) {
        if (n + 1 < capacity) out[n++] = c;
    };
    for (const wchar_t* p = g_dir; *p; ++p) put(*p);
    for (const wchar_t* p = L"\\crash-"; *p; ++p) put(*p);
    for (std::size_t i = 0; i < stamp.n; ++i) put(wchar_t(stamp.data[i]));
    for (const wchar_t* p = extension; *p; ++p) put(*p);
    out[n] = L'\0';
}

// One stack frame: "#1  game.exe!fa::Foo::bar + 0x1c  (foo.cpp:42)  [0x00007ff7...]". Without symbols: "game.exe+0x1234".
void write_frame(HANDLE file, HANDLE process, int index, DWORD64 pc) {
    LineBuf b;
    b.str("#"); b.dec(index); b.str("  ");
    // A return address can be one past the end of the calling function: look the caller up by the byte before it.
    const DWORD64 lookup = index == 0 ? pc : pc - 1;

    alignas(SYMBOL_INFO) char symbolBuffer[sizeof(SYMBOL_INFO) + 255];
    SYMBOL_INFO* symbol = reinterpret_cast<SYMBOL_INFO*>(symbolBuffer);
    std::memset(symbol, 0, sizeof(SYMBOL_INFO));
    symbol->SizeOfStruct = sizeof(SYMBOL_INFO);
    symbol->MaxNameLen = 255;
    DWORD64 displacement = 0;
    const bool hasSymbol = SymFromAddr(process, lookup, &displacement, symbol) != FALSE;  // loads the module's symbols
    IMAGEHLP_MODULE64 module{};
    module.SizeOfStruct = sizeof module;
    const bool hasModule = SymGetModuleInfo64(process, lookup, &module) != FALSE;
    const char* moduleName = hasModule ? base_name(module.ImageName[0] ? module.ImageName : module.ModuleName) : "";

    // A PDB (or a COFF table) knows where each function ends. A module with only its exports does not: the nearest export
    // before the address is a hint, not the name of the function that holds it.
    if (hasSymbol && hasModule && module.SymType != SymExport) {
        b.str(moduleName); b.chr('!'); b.str(symbol->Name);
        b.str(" + "); b.hex(displacement + (pc - lookup));
    } else if (hasModule) {
        b.str(moduleName); b.str("+"); b.hex(pc - module.BaseOfImage);
        if (hasSymbol) {
            b.str(" (nearest export: "); b.str(symbol->Name); b.str(" + "); b.hex(displacement + (pc - lookup)); b.chr(')');
        }
    } else {
        b.str("(unknown module)");
    }
    IMAGEHLP_LINE64 line{};
    line.SizeOfStruct = sizeof line;
    DWORD lineDisplacement = 0;
    if (SymGetLineFromAddr64(process, lookup, &lineDisplacement, &line)) {
        b.str("  ("); b.str(base_name(line.FileName)); b.chr(':'); b.dec(line.LineNumber); b.chr(')');
    }
    b.str("  ["); b.hex(pc); b.str("]\n");
    flush(file, b);
}

void write_stack(HANDLE file, const Job& job) {
    HANDLE process = GetCurrentProcess();
    SymSetOptions(SYMOPT_DEFERRED_LOADS | SYMOPT_UNDNAME | SYMOPT_LOAD_LINES | SYMOPT_FAIL_CRITICAL_ERRORS |
                  SYMOPT_NO_PROMPTS);
    SymInitialize(process, nullptr, TRUE);  // false when somebody else did: the Sym* calls still work
#ifdef FA_CRASH_X64
    CONTEXT context = *job.pointers->ContextRecord;  // StackWalk64 changes it
    STACKFRAME64 frame{};
    frame.AddrPC.Offset = context.Rip;
    frame.AddrFrame.Offset = context.Rbp;
    frame.AddrStack.Offset = context.Rsp;
    frame.AddrPC.Mode = frame.AddrFrame.Mode = frame.AddrStack.Mode = AddrModeFlat;
    HANDLE thread = OpenThread(THREAD_GET_CONTEXT | THREAD_QUERY_INFORMATION, FALSE, job.threadId);
    int printed = 0, repeats = 0;
    DWORD64 last = 0;
    auto note_repeats = [&] {
        if (!repeats) return;
        LineBuf b;
        b.str("    (the same frame "); b.dec(repeats); b.str(" more times)\n");
        flush(file, b);
        repeats = 0;
    };
    for (int i = 0; i < kMaxWalk && printed < kMaxFrames; ++i) {
        if (!StackWalk64(IMAGE_FILE_MACHINE_AMD64, process, thread ? thread : GetCurrentThread(), &frame, &context, nullptr,
                         SymFunctionTableAccess64, SymGetModuleBase64, nullptr) || frame.AddrPC.Offset == 0)
            break;
        const DWORD64 pc = frame.AddrPC.Offset;
        if (i > 0 && pc == last) {  // a runaway recursion: say so once instead of filling the report with one line
            ++repeats;
            continue;
        }
        note_repeats();
        write_frame(file, process, i, pc);
        last = pc;
        ++printed;
    }
    note_repeats();
    if (thread) CloseHandle(thread);
#else
    write_frame(file, process, 0, program_counter(*job.pointers->ContextRecord));  // only this CPU's first frame
#endif
}

void write_text_report(const wchar_t* path, const Job& job, const Civil& when) {
    HANDLE file = CreateFileW(path, GENERIC_WRITE, FILE_SHARE_READ, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return;
    write_all(file, g_shared.header, std::strlen(g_shared.header));
    LineBuf b;
    const EXCEPTION_RECORD& record = *job.pointers->ExceptionRecord;
    b.str("time: "); b.iso_time(when);
    b.str("\npid: "); b.dec(GetCurrentProcessId()); b.str("  crashed thread: "); b.dec(job.threadId);
    b.str("\nexception: "); b.hex(record.ExceptionCode); b.str(" "); b.str(exception_name(record.ExceptionCode));
    if (record.ExceptionCode == EXCEPTION_ACCESS_VIOLATION && record.NumberParameters >= 2) {
        const ULONG_PTR kind = record.ExceptionInformation[0];
        b.str(kind == 0 ? ", read of " : kind == 1 ? ", write to " : ", execution of ");
        b.hex(record.ExceptionInformation[1]);
    }
    b.str("\nexception address: "); b.hex(reinterpret_cast<std::uintptr_t>(record.ExceptionAddress));
    if (g_shared.terminateMessage[0]) { b.chr('\n'); b.str(g_shared.terminateMessage); }
    b.str("\n\nlast log lines (oldest first):\n");
    flush(file, b);
    for_each_log_line([&](const char* line, std::size_t length) {
        write_all(file, line, length);
        write_all(file, "\n", 1);
    });
    b.str("\nstack (innermost first");
    if (record.ExceptionCode >= 0xE0FA0001 && record.ExceptionCode <= 0xE0FA0003)
        b.str("; the first lines are the crash handler itself");
    b.str("):\n");
    flush(file, b);
    write_stack(file, job);
    CloseHandle(file);
}

void write_minidump(const wchar_t* path, const Job& job) {
    HANDLE file = CreateFileW(path, GENERIC_READ | GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file == INVALID_HANDLE_VALUE) return;
    MINIDUMP_EXCEPTION_INFORMATION exception{};
    exception.ThreadId = job.threadId;
    exception.ExceptionPointers = job.pointers;
    exception.ClientPointers = FALSE;
    const MINIDUMP_TYPE type = MINIDUMP_TYPE(MiniDumpNormal | MiniDumpWithThreadInfo | MiniDumpWithUnloadedModules |
                                             MiniDumpWithIndirectlyReferencedMemory);
    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file, type, &exception, nullptr, nullptr);
    CloseHandle(file);
}

#ifdef _MSC_VER
// MSVC does not call std::terminate for an uncaught C++ exception: it reaches the filter as the exception it was raised
// as (code 0xE06D7363), the stack still where it was thrown. Raise it again inside a try block to learn its what().
void note_cpp_exception(const EXCEPTION_RECORD& record) {
    constexpr DWORD kCppException = 0xE06D7363;
    constexpr ULONG_PTR kMagicFirst = 0x19930520, kMagicLast = 0x19930522;
    if (record.ExceptionCode != kCppException || record.NumberParameters < 3 ||
        record.ExceptionInformation[0] < kMagicFirst ||
        record.ExceptionInformation[0] > kMagicLast)
        return;
    // Through a pointer: /EHsc assumes a call to an extern "C" function such as RaiseException cannot throw, and with
    // optimization drops the catch blocks around it.
    void(WINAPI * volatile raise)(DWORD, DWORD, DWORD, const ULONG_PTR*) = RaiseException;
    note_uncaught([&] { raise(record.ExceptionCode, record.ExceptionFlags, record.NumberParameters, record.ExceptionInformation); });
}
#else
void note_cpp_exception(const EXCEPTION_RECORD&) {}  // MinGW: libstdc++ calls std::terminate, crash.cpp keeps the what()
#endif

DWORD WINAPI writer_thread(LPVOID param) {
    g_writerThread = GetCurrentThreadId();
    const Job& job = *static_cast<const Job*>(param);
    FILETIME fileTime;
    GetSystemTimeAsFileTime(&fileTime);
    ULARGE_INTEGER ticks;
    ticks.LowPart = fileTime.dwLowDateTime;
    ticks.HighPart = fileTime.dwHighDateTime;
    const Civil when = civil_from_unix(std::int64_t(ticks.QuadPart / 10000000ULL) - 11644473600LL);

    note_cpp_exception(*job.pointers->ExceptionRecord);
    wchar_t path[1024];
    report_path(path, 1024, when, L".txt");
    write_text_report(path, job, when);

    // Tell whoever started the game from a terminal (nobody sees this when double-clicked).
    char utf8[2048];
    const int length = WideCharToMultiByte(CP_UTF8, 0, path, -1, utf8, int(sizeof utf8) - 1, nullptr, nullptr);
    HANDLE err = GetStdHandle(STD_ERROR_HANDLE);
    if (length > 0 && err && err != INVALID_HANDLE_VALUE) {
        LineBuf message;
        message.str("FactorIA: the game crashed, report: ");
        message.str(utf8);
        message.chr('\n');
        flush(err, message);
    }

    report_path(path, 1024, when, L".dmp");
    write_minidump(path, job);  // last: the biggest and the most likely to go wrong
    return 0;
}

// Writes the reports for `pointers` from a helper thread and waits for it.
void report(EXCEPTION_POINTERS* pointers) {
    Job job{pointers, GetCurrentThreadId()};
    HANDLE thread = CreateThread(nullptr, 1 << 20, writer_thread, &job, 0, nullptr);
    if (!thread) return;
    WaitForSingleObject(thread, kWaitMs);
    CloseHandle(thread);
}

// Entry of every crash path. Only the first crash reports; a crash inside the report itself, or a second crash while the
// first one is written, ends the process at once / after the first one is done.
bool begin_report() {
    if (GetCurrentThreadId() == g_writerThread) return false;
    if (InterlockedExchange(&g_busy, 1)) {
        Sleep(kWaitMs);
        return false;
    }
    return true;
}

LONG WINAPI on_exception(EXCEPTION_POINTERS* pointers) {
    if (begin_report()) report(pointers);
    return EXCEPTION_EXECUTE_HANDLER;  // the process ends: no "stopped working" dialog on top of our report
}

// A crash that is not an exception (abort, bad CRT parameter, pure call): make one up, with this thread's context.
void report_made_up(DWORD code) {
    if (!begin_report()) return;
    CONTEXT context;
    RtlCaptureContext(&context);
    EXCEPTION_RECORD record{};
    record.ExceptionCode = code;
    record.ExceptionFlags = EXCEPTION_NONCONTINUABLE;
    record.ExceptionAddress = reinterpret_cast<PVOID>(program_counter(context));
    EXCEPTION_POINTERS pointers{&record, &context};
    report(&pointers);
}

void on_abort(int) { report_made_up(kCodeAbort); }  // abort() ends the process itself when this returns

#ifdef _MSC_VER
void __cdecl on_invalid_parameter(const wchar_t*, const wchar_t*, const wchar_t*, unsigned int, uintptr_t) {
    report_made_up(kCodeInvalidParameter);
    TerminateProcess(GetCurrentProcess(), 3);  // as without the handler: a bad CRT call is fatal
}
void __cdecl on_pure_call() {
    report_made_up(kCodePureCall);
    TerminateProcess(GetCurrentProcess(), 3);
}
#endif

}  // namespace

bool platform_install(const std::filesystem::path& dir, std::string& error) {
    const std::wstring d = dir.wstring();
    if (!dir_length_ok(dir, d.size(), "characters", error)) return false;
    std::wmemcpy(g_dir, d.c_str(), d.size() + 1);

    static bool installed = false;
    if (installed) return true;
    SetUnhandledExceptionFilter(on_exception);
    ULONG guarantee = 64 * 1024;  // stack kept free for the filter after an overflow of THIS thread's stack
    SetThreadStackGuarantee(&guarantee);
    signal(SIGABRT, on_abort);
#ifdef _MSC_VER
    _set_invalid_parameter_handler(on_invalid_parameter);
    _set_purecall_handler(on_pure_call);
#endif
    installed = true;
    return true;
}

}  // namespace fa::crash_detail
