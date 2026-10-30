// Windows ChildProcess: CreateProcessW with three anonymous pipes and a Job Object (kill-on-close), polled with
// PeekNamedPipe so a read can time out.
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
#include <mutex>
#include <string>
#include <vector>

#include "fa/core/child_process.h"

namespace fa {

namespace {

std::wstring widen(const std::string& s) {
    if (s.empty()) return {};
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), nullptr, 0);
    std::wstring w(static_cast<std::size_t>(n), L'\0');
    MultiByteToWideChar(CP_UTF8, 0, s.data(), static_cast<int>(s.size()), w.data(), n);
    return w;
}

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

bool needs_cmd_shell(const std::string& path) {
    auto n = path.size();
    if (n < 4) return false;
    std::string ext = path.substr(n - 4);
    for (auto& c : ext) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return ext == ".cmd" || ext == ".bat";
}

double now_seconds() {
    using namespace std::chrono;
    return duration<double>(steady_clock::now().time_since_epoch()).count();
}

constexpr std::size_t kStderrTail = 8192;

}  // namespace

struct ChildProcess::Impl {
    HANDLE process = nullptr, job = nullptr;
    HANDLE inW = nullptr, outR = nullptr, errR = nullptr;
    std::string outBuf;
    mutable std::mutex errMu;
    std::string errTail;

    void add_stderr(const char* data, std::size_t n) {
        std::lock_guard<std::mutex> lk(errMu);
        errTail.append(data, n);
        if (errTail.size() > kStderrTail) errTail.erase(0, errTail.size() - kStderrTail);
    }
    void close_handle(HANDLE& h) {
        if (h) { CloseHandle(h); h = nullptr; }
    }
    // Bytes waiting in a pipe: >0 data, 0 nothing yet, -1 the pipe ended.
    static long avail(HANDLE h) {
        DWORD a = 0;
        if (!PeekNamedPipe(h, nullptr, 0, nullptr, &a, nullptr)) return -1;
        return static_cast<long>(a);
    }
};

ChildProcess::ChildProcess() : impl_(std::make_unique<Impl>()) {}

ChildProcess::~ChildProcess() {
    if (!impl_) return;
    impl_->close_handle(impl_->inW);  // a well-behaved server exits on end of input
    if (impl_->process) {
        if (WaitForSingleObject(impl_->process, 500) != WAIT_OBJECT_0) {
            if (impl_->job) TerminateJobObject(impl_->job, 1);
            else TerminateProcess(impl_->process, 1);
            WaitForSingleObject(impl_->process, 2000);
        }
    }
    impl_->close_handle(impl_->outR);
    impl_->close_handle(impl_->errR);
    impl_->close_handle(impl_->process);
    impl_->close_handle(impl_->job);  // kill-on-close takes anything the program left behind
}

Result<std::unique_ptr<ChildProcess>> ChildProcess::start(const ChildOptions& opt) {
    if (opt.argv.empty()) return make_error("ChildProcess: empty argv", "Pass at least the executable name.");

    std::string exe = opt.argv[0];
    std::string found = which(exe);
    if (!found.empty()) exe = found;
    const bool batch = needs_cmd_shell(exe);
    std::wstring cmdline = quote_arg(widen(exe));
    for (std::size_t i = 1; i < opt.argv.size(); ++i) {
        if (batch && opt.argv[i].find_first_of("\r\n%&|<>^") != std::string::npos)
            return make_error("Cannot pass argument " + std::to_string(i) + " to '" + exe +
                                  "': it is a .cmd/.bat file, and cmd.exe would change or run the line breaks or "
                                  "% & | < > ^ characters in it",
                              "Use a server program that is not a .cmd shim, or keep these characters out of the arguments.");
        cmdline += L' ';
        cmdline += quote_arg(widen(opt.argv[i]));
    }
    if (batch) cmdline = L"cmd.exe /d /s /c \"" + cmdline + L"\"";

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
    HANDLE inR = nullptr, inW = nullptr, outR = nullptr, outW = nullptr, errR = nullptr, errW = nullptr;
    if (!CreatePipe(&inR, &inW, &sa, 0) || !CreatePipe(&outR, &outW, &sa, 0) || !CreatePipe(&errR, &errW, &sa, 0))
        return make_error("CreatePipe failed (error " + std::to_string(GetLastError()) + ")");
    SetHandleInformation(inW, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(outR, HANDLE_FLAG_INHERIT, 0);
    SetHandleInformation(errR, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOW si{};
    si.cb = sizeof si;
    si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdInput = inR;
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
    CloseHandle(inR);
    CloseHandle(outW);
    CloseHandle(errW);
    if (!ok) {
        CloseHandle(inW);
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

    std::unique_ptr<ChildProcess> child(new ChildProcess());
    child->impl_->process = pi.hProcess;
    child->impl_->job = job;
    child->impl_->inW = inW;
    child->impl_->outR = outR;
    child->impl_->errR = errR;
    return child;
}

bool ChildProcess::write(std::string_view data) {
    auto& d = *impl_;
    if (!d.inW) return false;
    std::size_t off = 0;
    while (off < data.size()) {
        DWORD w = 0;
        if (!WriteFile(d.inW, data.data() + off, static_cast<DWORD>(data.size() - off), &w, nullptr) || w == 0) return false;
        off += w;
    }
    return true;
}

ChildProcess::Read ChildProcess::read_line(std::string& line, double timeoutSeconds, const CancelFlag* cancel) {
    auto& d = *impl_;
    const double start = now_seconds();
    char buf[8192];
    for (;;) {
        auto nl = d.outBuf.find('\n');
        if (nl != std::string::npos) {
            std::size_t end = nl;
            if (end > 0 && d.outBuf[end - 1] == '\r') --end;
            line.assign(d.outBuf, 0, end);
            d.outBuf.erase(0, nl + 1);
            return Read::Line;
        }
        if (!d.outR) {
            if (!d.outBuf.empty()) { line = std::move(d.outBuf); d.outBuf.clear(); return Read::Line; }
            // The output ended: the program is exiting. Give it a moment so running() agrees with Closed.
            if (d.process) WaitForSingleObject(d.process, 500);
            return Read::Closed;
        }
        if (is_cancelled(cancel)) return Read::Cancelled;
        if (timeoutSeconds > 0 && now_seconds() - start > timeoutSeconds) return Read::Timeout;
        bool any = false;
        if (d.errR) {
            long a = Impl::avail(d.errR);
            if (a < 0) d.close_handle(d.errR);
            else if (a > 0) {
                DWORD got = 0;
                if (ReadFile(d.errR, buf, static_cast<DWORD>(sizeof buf), &got, nullptr) && got > 0) {
                    d.add_stderr(buf, got);
                    any = true;
                } else d.close_handle(d.errR);
            }
        }
        long a = Impl::avail(d.outR);
        if (a < 0) { d.close_handle(d.outR); continue; }
        if (a > 0) {
            DWORD got = 0;
            if (ReadFile(d.outR, buf, static_cast<DWORD>(sizeof buf), &got, nullptr) && got > 0) {
                d.outBuf.append(buf, got);
                any = true;
            } else d.close_handle(d.outR);
        }
        if (!any) Sleep(5);
    }
}

bool ChildProcess::running() {
    auto& d = *impl_;
    return d.process && WaitForSingleObject(d.process, 0) == WAIT_TIMEOUT;
}

void ChildProcess::terminate() {
    auto& d = *impl_;
    if (!d.process) return;
    if (d.job) TerminateJobObject(d.job, 1);
    else TerminateProcess(d.process, 1);
    WaitForSingleObject(d.process, 2000);
}

std::string ChildProcess::stderr_tail() const {
    std::lock_guard<std::mutex> lk(impl_->errMu);
    return impl_->errTail;
}

}  // namespace fa
