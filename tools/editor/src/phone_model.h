// The "Play on Phone" window's logic (File > Play on Phone...): the web server of project.serve_web started and stopped on a helper
// thread (starting reads the web player to check it, stopping waits for a running export: neither belongs on the UI thread), the one
// line that says what the server is doing, and the checklist for a phone that cannot open the address.
//
// No ImGui and no Editor here: phone_panel.cpp draws it, the autotest and tests call it.
#pragma once

#include <atomic>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "fa/tooling/serve_web.h"

namespace fa::editor {

// Runs WebServer::start / stop (the process's web_server(), the one project.serve_web uses) on a helper thread, one job at a time.
class PhoneSession {
public:
    struct Done {
        bool wasStart = false;
        bool ok = false;
        std::string error, hint;  // not ok: why the server did not start
    };
    PhoneSession() = default;
    PhoneSession(const PhoneSession&) = delete;
    PhoneSession& operator=(const PhoneSession&) = delete;
    ~PhoneSession() { wait(); }

    bool busy() const { return busy_.load(); }
    bool start(const ServeWebOptions& options);  // false while a job runs
    bool stop();                                 // false while a job runs
    std::optional<Done>
    take_result();  // the finished job's result, once; nullopt while it runs or when none is waiting
    void wait();    // blocks until the running job is done (project switch, quit)

private:
    void run(bool wasStart, ServeWebOptions options);
    std::thread thread_;
    std::atomic<bool> busy_{false};
    std::mutex mu_;
    std::optional<Done> result_;
};

// "Exporting the web build...", "Ready: ...": the status in one line for the window (never empty for a running server).
std::string phone_state_line(const ServeWebStatus& status);
// What to check when the phone cannot open the address, one line each: the same Wi-Fi, the firewall prompt on Windows and macOS,
// guest networks that isolate devices, a VPN.
const std::vector<std::string>& phone_help_lines();
// The address the QR code shows: the `index`-th LAN address, or "" when this computer has none (the QR is not drawn then: a code of
// 127.0.0.1 would open the phone's own localhost).
std::string phone_qr_url(const ServeWebStatus& status, size_t index);

}  // namespace fa::editor
