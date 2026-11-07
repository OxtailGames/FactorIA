#include "phone_model.h"

#include <algorithm>

#include "fa/core/log.h"

namespace fa::editor {

bool PhoneSession::start(const ServeWebOptions& options) {
    bool expected = false;
    if (!busy_.compare_exchange_strong(expected, true)) return false;
    if (thread_.joinable()) thread_.join();  // the previous job is over (busy_ was false)
    thread_ = std::thread([this, options] { run(true, options); });
    return true;
}

bool PhoneSession::stop() {
    bool expected = false;
    if (!busy_.compare_exchange_strong(expected, true)) return false;
    if (thread_.joinable()) thread_.join();
    thread_ = std::thread([this] { run(false, ServeWebOptions{}); });
    return true;
}

void PhoneSession::run(bool wasStart, ServeWebOptions options) {
    Done done;
    done.wasStart = wasStart;
    if (wasStart) {
        auto r = web_server().start(options);
        done.ok = r.ok();
        if (!r.ok()) {
            done.error = r.error().message;
            done.hint = r.error().hint;
        }
    } else {
        web_server().stop();
        done.ok = true;
    }
    {
        std::lock_guard<std::mutex> lock(mu_);
        result_ = std::move(done);
    }
    busy_.store(false);
}

std::optional<PhoneSession::Done> PhoneSession::take_result() {
    std::lock_guard<std::mutex> lock(mu_);
    std::optional<Done> out = std::move(result_);
    result_.reset();
    return out;
}

void PhoneSession::wait() {
    if (thread_.joinable()) thread_.join();
}

std::string phone_state_line(const ServeWebStatus& st) {
    if (!st.running) return "Not running.";
    if (st.state == "exporting") return st.version == 0 ? "Exporting the web build... (the first time takes a few seconds)" : "Rebuilding after a change...";
    if (st.state == "failed") return "The last export failed: " + st.error;
    return "Ready. A changed script or asset rebuilds the game and the phone's page reloads by itself.";
}

const std::vector<std::string>& phone_help_lines() {
    static const std::vector<std::string> lines = {
        "The phone and this computer must be on the same Wi-Fi (or the phone on this computer's hotspot). Mobile data cannot reach this computer.",
        "A guest Wi-Fi, a hotel or office network often isolates devices from each other (\"AP isolation\", \"client isolation\"): the phone cannot "
        "see this computer there. Use your home network or the phone's hotspot.",
        "Windows: the first time, a firewall prompt asks whether this program may talk on the network. Tick Private networks and Allow. If you "
        "closed it, open Windows Security > Firewall & network protection > Allow an app through firewall and tick this program (FactorIA) for Private.",
        "macOS: the first time, a prompt asks \"Do you want the application to accept incoming network connections?\". Choose Allow. If you chose "
        "Deny, open System Settings > Network > Firewall > Options and allow it.",
        "A VPN on this computer or on the phone can hide the local network: turn it off while you test.",
        "Check the address on this computer first (Open on this computer): if that works but the phone's browser does not, it is the network or "
        "the firewall, not the game.",
        "The page is plain http, not https: the phone's browser may show \"not secure\". That is expected for a local test.",
    };
    return lines;
}

std::string phone_qr_url(const ServeWebStatus& st, size_t index) {
    if (st.lanUrls.empty()) return {};
    return st.lanUrls[std::min(index, st.lanUrls.size() - 1)];
}

}  // namespace fa::editor
