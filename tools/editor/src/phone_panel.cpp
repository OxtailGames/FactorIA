// The Play on Phone window (File > Play on Phone...): starts the web server of project.serve_web for the Wi-Fi, shows its address
// as a QR code drawn by the engine (fa/tooling/qr.h) and says what to check when the phone cannot open it. What the phone's page logs
// comes back as log lines of category "phone" in the Console. The logic is phone_model.h; the server is fa/tooling/serve_web.h.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/tooling/qr.h"
#include "fa/tooling/serve_web.h"

namespace fa::editor {

void Editor::open_phone_window() {
    showPhone_ = true;
    phoneFocus_ = true;
}

void Editor::reset_phone_state() {
    // The server of the project that is closing stops on the helper thread (stopping waits for a running export: seconds), as soon as
    // a start still running has finished; poll_phone() does it and drops the results of the old project.
    phoneStopPending_ = true;
    phoneError_.clear();
    phoneHint_.clear();
    phoneQr_.reset();
    phoneQrUrl_.clear();
    phoneUrlIndex_ = 0;
    showPhone_ = false;
}

void Editor::poll_phone() {
    if (phoneStopPending_) {
        if (phone_.busy()) return;
        (void)phone_.take_result();  // the old project's start or stop: nobody is waiting for it
        if (phone_.stop()) phoneStopPending_ = false;
        return;
    }
    std::optional<PhoneSession::Done> done = phone_.take_result();
    if (!done) return;
    if (done->wasStart && !done->ok) {
        phoneError_ = done->error;
        phoneHint_ = done->hint;
        notify("Play on phone: " + done->error, 2);
    } else if (done->wasStart) {
        phoneError_.clear();
        phoneHint_.clear();
    }
}

namespace {

// Draws `qr` with a white quiet zone of 4 modules (the spec's minimum: a phone camera needs it) in a square of at most `maxPx`
// pixels, with whole pixels per module so no edge blurs. Returns the item's rectangle through the last item (a Dummy).
void draw_qr(const QrCode& qr, float maxPx) {
    constexpr int kQuiet = 4;
    const int modules = qr.size + 2 * kQuiet;
    const float px = std::max(2.0f, std::floor(maxPx / static_cast<float>(modules)));
    const float side = px * static_cast<float>(modules);
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    ImGui::Dummy(ImVec2(side, side));
    ImDrawList* dl = ImGui::GetWindowDrawList();
    dl->AddRectFilled(origin, ImVec2(origin.x + side, origin.y + side), IM_COL32(255, 255, 255, 255));
    const ImU32 ink = IM_COL32(0, 0, 0, 255);
    for (int y = 0; y < qr.size; ++y) {
        for (int x = 0; x < qr.size;) {  // a run of dark modules is one rectangle
            if (!qr.dark(x, y)) {
                ++x;
                continue;
            }
            int end = x;
            while (end < qr.size && qr.dark(end, y)) ++end;
            const float x0 = origin.x + px * static_cast<float>(x + kQuiet),
                        y0 = origin.y + px * static_cast<float>(y + kQuiet);
            dl->AddRectFilled(ImVec2(x0, y0), ImVec2(origin.x + px * static_cast<float>(end + kQuiet), y0 + px), ink);
            x = end;
        }
    }
}

}  // namespace

void Editor::draw_phone_window() {
    if (!showPhone_ || !engine_) return;
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(fit_work_area(ImVec2(620, 640)), ImGuiCond_FirstUseEver);  // a small screen scrolls it
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f),
                            ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (phoneFocus_) {
        ImGui::SetNextWindowFocus();
        phoneFocus_ = false;
    }
    if (!ImGui::Begin("Play on phone###PlayPhone", &showPhone_, ImGuiWindowFlags_NoDocking)) {
        ImGui::End();
        return;
    }
    const ServeWebStatus st =
        web_server().status();  // a few string copies under a mutex that no export or send ever holds
    const bool busy = phone_.busy();
    ImGui::PushTextWrapPos(0);
    ImGui::TextDisabled("Plays \"%s\" in the browser of a phone on the same Wi-Fi: the web build of the project, "
                        "served by this computer. "
                        "When a script or asset changes it is rebuilt and the phone's page reloads.",
                        projectName_.c_str());
    ImGui::Spacing();

    if (dirty_) {
        ImGui::TextColored(kStatusWarn, "The scene has unsaved changes: the phone gets the version on disk.");
        ImGui::SameLine();
        ImGui::BeginDisabled(play_ != PlayState::Edit);
        if (ImGui::SmallButton("Save scene")) save_scene_now();
        ImGui::EndDisabled();
    }

    if (!st.running) {
        ImGui::BeginDisabled(busy);
        if (ImGui::Button("Start")) {
            ServeWebOptions o;
            o.projectDir = projectDir_;
            o.lan = true;
            o.playerBinary = phonePlayer_;
            o.allowPlayerMismatch = phoneAllowMismatch_;
            phoneError_.clear();
            phoneHint_.clear();
            phone_.start(o);
        }
        at_track("phone:start", !busy);
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("Start a web server on this computer that devices on your Wi-Fi can reach. It stops with "
                              "the editor or with Stop.");
        if (busy) {
            ImGui::SameLine();
            ImGui::TextDisabled("Starting...");
        }
    } else {
        ImGui::BeginDisabled(busy);
        if (ImGui::Button("Stop")) phone_.stop();
        at_track("phone:stop", !busy);
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("Stop the server: open pages stop working. Nothing of the project is changed.");
        if (busy) {
            ImGui::SameLine();
            ImGui::TextDisabled("Stopping...");
        }
    }
    if (!phoneError_.empty()) {
        ImGui::TextColored(kStatusFailed, "%s", phoneError_.c_str());
        if (!phoneHint_.empty()) ImGui::TextUnformatted(phoneHint_.c_str());
        if (phoneHint_.find("setup players") !=
            std::string::npos) {  // the web player is not installed: the Set Up window installs it
            if (ImGui::Button("Open Set Up This Computer...")) open_setup_window();
            at_track("phone:setup");
            ImGui::SetItemTooltip(
                "Install the web player (and the other players) with one click, then press Start again.");
        }
    }
    ImGui::Spacing();

    if (st.running) {
        const ImVec4& color = st.state == "failed"      ? kStatusFailed
                              : st.state == "exporting" ? kStatusWarn
                                                        : kStatusReady;
        ImGui::TextColored(color, "%s", phone_state_line(st).c_str());
        at_track("phone:state");
        if (st.state == "failed" && !st.hint.empty()) ImGui::TextUnformatted(st.hint.c_str());
        for (const std::string& w : st.warnings) ImGui::TextColored(kStatusWarn, "%s", w.c_str());
        ImGui::Spacing();

        if (st.lanUrls.size() > 1) {
            phoneUrlIndex_ = std::min<int>(phoneUrlIndex_, static_cast<int>(st.lanUrls.size()) - 1);
            ImGui::SetNextItemWidth(std::min(ImGui::GetContentRegionAvail().x, 420.0f));
            if (ImGui::BeginCombo("##phoneaddr", st.lanUrls[static_cast<size_t>(phoneUrlIndex_)].c_str())) {
                for (int i = 0; i < static_cast<int>(st.lanUrls.size()); ++i)
                    if (ImGui::Selectable(st.lanUrls[static_cast<size_t>(i)].c_str(), i == phoneUrlIndex_))
                        phoneUrlIndex_ = i;
                ImGui::EndCombo();
            }
            at_track("phone:address");
            ImGui::SetItemTooltip(
                "This computer has several network addresses: pick the one of the Wi-Fi the phone is on.");
        }
        const std::string url = phone_qr_url(st, static_cast<size_t>(phoneUrlIndex_));
        if (url != phoneQrUrl_) {  // encoded once per address
            phoneQrUrl_ = url;
            phoneQr_.reset();
            if (!url.empty()) {
                auto qr = qr_encode(url, QrEcc::Medium);
                if (qr.ok()) phoneQr_ = std::move(*qr);
            }
        }
        if (phoneQr_) {
            draw_qr(*phoneQr_, 250.0f);
            at_track("phone:qr");
            ImGui::SetItemTooltip("Point the phone's camera at this code and open the link it shows.");
            ImGui::TextUnformatted(url.c_str());
            at_track("phone:url");
            if (ImGui::Button("Copy address")) ImGui::SetClipboardText(url.c_str());
            at_track("phone:copy");
            ImGui::SetItemTooltip("Copy the address to send it to the phone yourself (a chat message, e-mail).");
            ImGui::SameLine();
        } else {
            ImGui::TextColored(kStatusWarn, "No Wi-Fi address found on this computer, so there is no code to show.");
            at_track("phone:no-lan");
        }
        if (ImGui::Button("Open on this computer")) {
            if (std::string why = open_url(st.localUrl); !why.empty()) notify(why, 1);
        }
        at_track("phone:open");
        ImGui::SetItemTooltip("Open the same page in this computer's browser: if it works here but not on the phone, "
                              "the network or the firewall blocks the phone.");
        ImGui::Spacing();
        ImGui::TextDisabled(
            "Pages have asked for %llu files and sent %llu log lines (they appear in the Console, category \"phone\").",
            static_cast<unsigned long long>(st.requests), static_cast<unsigned long long>(st.phoneLogLines));
        at_track("phone:stats");
    }

    ImGui::Spacing();
    if (ImGui::CollapsingHeader("The phone cannot open it?", ImGuiTreeNodeFlags_DefaultOpen)) {
        at_track("phone:help");
        for (const std::string& line : phone_help_lines()) {
            ImGui::Bullet();
            ImGui::TextUnformatted(line.c_str());
        }
    }
    ImGui::PopTextWrapPos();
    ImGui::End();
}

}  // namespace fa::editor
