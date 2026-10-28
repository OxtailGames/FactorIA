// Windows process runner: CreateProcessW with redirected pipes and a Job Object
// (kill-on-close) so cancellation terminates the whole process tree.
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include <cctype>
#include <chrono>
#include <cwchar>
#include <string>
#include <vector>

#include "fa/core/process.h"

namespace fa {

namespace {

std::wstring widen(const std::string& s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring w(static_cast<std::size_t>(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
    return w;
}

// Quote one argument following the MSVCRT/CommandLineToArgvW rules.
std::wstring quote_arg(const std::wstring& a) {
    if (!a.empty() && a.find_first_of(L" \t\n\v\"") == std::wstring::npos) return a;
    std::wstring out = L"\"";
    std::size_t backslashes = 0;
    for (wchar_t c : a) {
        if (c == L'\\') { ++backslashes; continue; }
        if (c == L'"') { out.append(backslashes * 2 + 1, L'\\'); out.push_back(L'"'); }
        else { out.append(backslashes, L'\\'); out.push_back(c); }
        backslashes = 0;
    }
    out.append(backslashes * 2, L'\\');
    out.push_back(L'"');
    return out;
}

struct LineSplitter {
    std::string buf;
    std::function<void(std::string_view)> cb;
    void feed(const char* data, std::size_t n) {
        buf.append(data, n);
        std::size_t start = 0;
        for (;;) {
            auto nl = buf.find('\n', start);
            if (nl == std::string::npos) break;
            std::size_t end = nl;
            if (end > start && buf[end - 1] == '\r') --end;
            if (cb) cb(std::string_view(buf).substr(start, end - start));
            start = nl + 1;
        }
        buf.erase(0, start);
    }
    void flush() {
        if (!buf.empty() && cb) cb(buf);
        buf.clear();
    }
};

double now_seconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

// .cmd / .bat files (npm shims such as claude.cmd) must be run through cmd.exe.
bool needs_cmd_shell(const std::string& path) {
    auto n = path.size();
    if (n < 4) return false;
    std::string ext = path.substr(n - 4);
    for (auto& c : ext) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return ext == ".cmd" || ext == ".bat";
}

// The child's standard input: NUL, or a temporary file holding `text` (deleted when the last handle closes), so there
// is no pipe to keep writing while stdout is read.
HANDLE open_stdin(const std::string& text, SECURITY_ATTRIBUTES& sa) {
    if (text.empty())
        return CreateFileW(L"NUL", GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, &sa, OPEN_EXISTING, 0, nullptr);
    wchar_t dir[MAX_PATH + 1], file[MAX_PATH + 1];
    if (!GetTempPathW(MAX_PATH + 1, dir) || !GetTempFileNameW(dir, L"fa", 0, file)) return INVALID_HANDLE_VALUE;
    HANDLE h = CreateFileW(file, GENERIC_READ | GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_DELETE, &sa, CREATE_ALWAYS,
                           FILE_ATTRIBUTE_TEMPORARY | FILE_FLAG_DELETE_ON_CLOSE, nullptr);
    if (h == INVALID_HANDLE_VALUE) return h;
    DWORD written = 0;
    if (!WriteFile(h, text.data(), static_cast<DWORD>(text.size()), &written, nullptr) || written != text.size() ||
        SetFilePointer(h, 0, nullptr, FILE_BEGIN) == INVALID_SET_FILE_POINTER) {
        CloseHandle(h);
        return INVALID_HANDLE_VALUE;
    }
    return h;
}

}  // namespace

Result<ProcessResult> run_process(const ProcessOptions& opt) {
    if (opt.argv.empty()) return make_error("run_process: empty argv", "Pass at least the executable name.");

    std::string exe = opt.argv[0];
    if (exe.find_first_of("/\\") == std::string::npos || !which(exe).empty()) {
        std::string found = which(exe);
        if (!found.empty()) exe = found;
    }
    const bool batch = needs_cmd_shell(exe);
    std::wstring cmdline = quote_arg(widen(exe));
    for (std::size_t i = 1; i < opt.argv.size(); ++i) {
        // cmd.exe cuts an argument at a line break, expands %VAR%, and runs what follows & | < > ^ once its quoting
        // gets out of step with the CRT's (\"): refuse such an argument instead of running something else.
        if (batch && opt.argv[i].find_first_of("\r\n%&|<>^") != std::string::npos)
            return make_error("Cannot pass argument " + std::to_string(i) + " to '" + exe +
                                  "': it is a .cmd/.bat file, and cmd.exe would change or run the line breaks or "
                                  "% & | < > ^ characters in it",
                              "Send text through standard input instead: leave {prompt} out of the provider's \"argv\" "
                              "in ai.json. Paths must not contain these characters.");
        cmdline += L' ';
        cmdline += quote_arg(widen(opt.argv[i]));
    }
    // /s: cmd.exe strips only the outer quotes, so a quoted script path and quoted arguments stay intact.
    if (batch) cmdline = L"cmd.exe /d /s /c \"" + cmdline + L"\"";

    // Environment block: inherited + overrides - unset.
    std::wstring envBlock;
    {
        LPWCH base = GetEnvironmentStringsW();
        std::vector<std::wstring> vars;
        for (LPWCH p = base; p && *p;) {
            std::wstring s = p;
            p += s.size() + 1;
            auto eq = s.find(L'=', 1);
            std::wstring key = s.substr(0, eq);
            bool drop = false;
            for (const auto& [k, v] : opt.env) drop = drop || (_wcsicmp(widen(k).c_str(), key.c_str()) == 0);
            for (const auto& u : opt.unsetEnv) drop = drop || (_wcsicmp(widen(u).c_str(), key.c_str()) == 0);
            if (!drop) vars.push_back(std::move(s));
        }
        if (base) FreeEnvironmentStringsW(base);
        for (const auto& [k, v] : opt.env) vars.push_back(widen(k) + L"=" + widen(v));
        for (const auto& v : vars) { envBlock += v; envBlock.push_back(L'\0'); }
        envBlock.push_back(L'\0');
    }

    SECURITY_ATTRIBUTES sa{sizeof sa, nullptr, TRUE};
    HANDLE in = open_stdin(opt.stdinText, sa);
    if (in == INVALID_HANDLE_VALUE && !opt.stdinText.empty())
        return make_error("Cannot write the standard input of '" + opt.argv[0] + "' to a temporary file (error " +
                              std::to_string(GetLastError()) + ")",
                          "Check that the TEMP directory exists and is writable.");
    HANDLE outR = nullptr, outW = nullptr, errR = nullptr, errW = nullptr;
    if (!CreatePipe(&outR, &outW, &sa, 0) || !CreatePipe(&errR, &errW, &sa, 0))
        return make_error("CreatePipe failed (error " + std::to_string(GetLastError()) + ")");
    SetHandleInformation(outR, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(errR, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW si{};
    si.cb = sizeof si;
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = in;
    si.hStdOutput = outW;
    si.hStdError = errW;
    PROCESS_INFORMATION pi{};
    std::wstring wcwd = widen(opt.workingDir);
    std::vector<wchar_t> cl(cmdline.begin(), cmdline.end());
    cl.push_back(L'\0');
    BOOL ok = CreateProcessW(nullptr, cl.data(), nullptr, nullptr, TRUE,
                             CREATE_UNICODE_ENVIRONMENT | CREATE_NO_WINDOW | CREATE_SUSPENDED, envBlock.data(),
                             wcwd.empty() ? nullptr : wcwd.c_str(), &si, &pi);
    DWORD createErr = GetLastError();
    CloseHandle(outW);
    CloseHandle(errW);
    if (in != INVALID_HANDLE_VALUE) CloseHandle(in);
    if (!ok) {
        CloseHandle(outR);
        CloseHandle(errR);
        return make_error("Cannot start '" + opt.argv[0] + "' (error " + std::to_string(createErr) + ")",
                          "Is it installed and on PATH? Check the working directory exists.");
    }

    HANDLE job = CreateJobObjectW(nullptr, nullptr);
    if (job) {
        JOBOBJECT_EXTENDED_LIMIT_INFORMATION info{};
        info.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
        SetInformationJobObject(job, JobObjectExtendedLimitInformation, &info, sizeof info);
        AssignProcessToJobObject(job, pi.hProcess);
    }
    ResumeThread(pi.hThread);
    CloseHandle(pi.hThread);
    if (opt.onStart) opt.onStart(static_cast<long long>(pi.dwProcessId));

    ProcessResult res;
    LineSplitter outLines{{}, opt.onStdoutLine};
    LineSplitter errLines{{}, opt.onStderrLine};
    const double start = now_seconds();
    bool terminated = false;
    bool outOpen = true, errOpen = true;
    char buf[8192];

    auto kill_tree = [&] {
        if (terminated) return;
        terminated = true;
        if (job) TerminateJobObject(job, 1);
        else TerminateProcess(pi.hProcess, 1);
    };
    auto pump = [&](HANDLE h, bool& open, bool isOut) {
        DWORD avail = 0;
        if (!PeekNamedPipe(h, nullptr, 0, nullptr, &avail, nullptr)) { open = false; return false; }
        if (avail == 0) return false;
        DWORD got = 0;
        if (!ReadFile(h, buf, static_cast<DWORD>(sizeof buf), &got, nullptr) || got == 0) { open = false; return false; }
        if (isOut) {
            if (opt.captureStdout && res.stdoutText.size() < opt.maxCapture) res.stdoutText.append(buf, got);
            if (opt.onStdoutChunk) opt.onStdoutChunk(std::string_view(buf, got));
            outLines.feed(buf, got);
        } else {
            if (res.stderrText.size() < opt.maxCapture) res.stderrText.append(buf, got);
            errLines.feed(buf, got);
        }
        return true;
    };

    while (outOpen || errOpen) {
        if (!terminated) {
            if (is_cancelled(opt.cancel)) { res.cancelled = true; kill_tree(); }
            else if (opt.timeoutSeconds > 0 && now_seconds() - start > opt.timeoutSeconds) {
                res.timedOut = true; kill_tree();
            }
        }
        bool any = false;
        if (outOpen) any = pump(outR, outOpen, true) || any;
        if (errOpen) any = pump(errR, errOpen, false) || any;
        if (!any) {
            if (WaitForSingleObject(pi.hProcess, 20) == WAIT_OBJECT_0) {
                // Drain what is left, then stop.
                while ((outOpen && pump(outR, outOpen, true)) || (errOpen && pump(errR, errOpen, false))) {}
                break;
            }
        }
    }
    outLines.flush();
    errLines.flush();
    WaitForSingleObject(pi.hProcess, terminated ? 2000 : INFINITE);
    DWORD code = 0;
    if (GetExitCodeProcess(pi.hProcess, &code) && code != STILL_ACTIVE) res.exitCode = static_cast<int>(code);
    if (terminated) res.exitCode = -1;
    CloseHandle(outR);
    CloseHandle(errR);
    CloseHandle(pi.hProcess);
    if (job) CloseHandle(job);
    return res;
}

}  // namespace fa
