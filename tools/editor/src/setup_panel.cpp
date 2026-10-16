// The Set Up This Computer window (File > Set Up This Computer..., the "Set up" buttons of the Export and Platform settings
// windows): what an export needs that is not part of FactorIA (the Android JDK + SDK, the players of other platforms, CMake,
// Xcode), with one button per component that installs it, and the Android SDK license dialog that comes first.
// The logic is setup_job.h (fa::setup_status, fa::setup_install on a worker thread); this file only draws it.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <filesystem>

#include "editor_internal.h"

namespace fa::editor {

namespace {

const ImVec4& kReady = kStatusReady;
const ImVec4& kFailed = kStatusFailed;
const ImVec4& kWarn = kStatusWarn;

// A tooltip that wraps (the default one grows as wide as its text).
void tip(const std::string& text) {
    if (text.empty()) return;
    if (ImGui::BeginItemTooltip()) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 32.0f);
        ImGui::TextUnformatted(text.c_str());
        ImGui::PopTextWrapPos();
        ImGui::EndTooltip();
    }
}

void wrapped(const ImVec4& color, const std::string& text) {
    ImGui::PushStyleColor(ImGuiCol_Text, color);
    ImGui::TextWrapped("%s", text.c_str());
    ImGui::PopStyleColor();
}

void note(const std::string& text) {
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("%s", text.c_str());
    ImGui::PopStyleColor();
}

const ImVec4& state_color(const std::string& state) {
    if (state == "installed") return kReady;
    if (state == "partial") return kWarn;
    if (state == "missing") return kFailed;
    return ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled);
}

// "jdk" -> "JDK": the key of a component's path, as a label.
std::string path_label(const std::string& key) {
    if (key == "jdk") return "JDK";
    if (key == "sdk") return "Android SDK";
    if (key == "sdkmanager") return "sdkmanager";
    if (key == "mobile") return "Mobile libraries";
    if (key == "cmake") return "CMake";
    if (key == "developerDir") return "Developer folder";
    if (key == "player-windows") return "Windows player";
    if (key == "player-linux") return "Linux player";
    if (key == "player-macos") return "macOS player";
    return key;
}

}  // namespace

// ---- the editor's side ----------------------------------------------------------------------------------------------

SetupContext Editor::make_setup_context() {
    SetupContext c = setupTestContext_ ? *setupTestContext_ : SetupContext{};
    c.cache = setupCache_;  // the license text and the install read the same Android listing
    return c;
}

void Editor::open_setup_window() {
    showSetup_ = true;
    setupFocus_ = true;
    if (!setupJob_.running() && !setupStatus_.refreshing()) setupStatus_.refresh(make_setup_context(), time_);
}

void Editor::request_setup(const SetupAction& action) {
    if (setupJob_.running()) {
        showSetup_ = true;
        setupFocus_ = true;
        notify("A setup is running: wait for it, or cancel it in Set Up This Computer.", 1);
        return;
    }
    setupPending_ = action;
    if (action.component == "android") {
        // The Android SDK license is Google's agreement with the user: it is shown, in full, before anything is downloaded.
        setupLicenseOpen_ = true;
        setupLicenseRequest_ = true;
        setupLicenseTick_ = false;
        if (setupLicense_.state() != SetupLicenseLoad::State::Ready) {
            setupLicense_.reset();
            setupLicense_.start(make_setup_context());
        }
        return;
    }
    start_setup_install(action, false);
}

void Editor::start_setup_install(const SetupAction& action, bool acceptLicenses) {
    setupPending_ = action;
    setupLast_.reset();
    setupScroll_ = 3;
    showSetup_ = true;  // the progress and the report are shown there
    setupFocus_ = true;
    if (!setupJob_.start(action.options(acceptLicenses), make_setup_context())) {
        notify("A setup is already running.", 1);
        return;
    }
    FA_INFO("editor", "setting up {}", setup_what(action.component, action.platforms));
}

void Editor::poll_setup() {
    setupStatus_.poll();

    // The license text arrived (or failed). Licenses that are accepted already need no dialog: the install just starts.
    if (setupLicense_.poll() && setupLicenseOpen_ && setupLicense_.state() == SetupLicenseLoad::State::NotNeeded) {
        setupLicenseOpen_ = false;
        setupLicense_.reset();
        start_setup_install(setupPending_, false);
    }

    if (auto done = setupJob_.take_result()) {
        const int level = done->ok ? (done->report.warnings.empty() ? 0 : 1) : (done->cancelled || done->licenseRequired ? 1 : 2);
        notify(setup_summary(*done), level);
        if (done->licenseRequired && done->options.component == "android") {
            // The install refused: the license was not accepted (it changed, or the status was stale). Ask again.
            setupLicenseOpen_ = true;
            setupLicenseRequest_ = true;
            setupLicenseTick_ = false;
            setupLicense_.reset();
            setupLicense_.start(make_setup_context());
        }
        const bool changed = done->ok && !done->report.steps.empty();
        setupLast_ = std::move(done);
        setupScroll_ = 3;
        showSetup_ = true;
        setupRefreshAgain_ = true;  // look at the computer again, as soon as no other look is in flight
        exportChecked_ = -100;      // the Export rows may be ready now
        if (changed && platformSettings_.loaded() && !platformSettings_.machine_dirty()) {
            platformSettings_.reload_machine();  // setup wrote the JDK and SDK it installed into export.json
            (void)platformSettings_.toolchain(true);
        }
    }

    // What the windows that show the status need: fresh while one of them is open, never while an install changes the folders.
    const bool wanted = showSetup_ || showExport_ || showPlatformSettings_;
    if (!setupJob_.running() && !setupStatus_.refreshing() && (setupRefreshAgain_ || (wanted && setupStatus_.stale(time_, 20.0)))) {
        setupRefreshAgain_ = false;
        setupStatus_.refresh(make_setup_context(), time_);
    }
}

void Editor::draw_setup_buttons(const std::string& platform, const char* idPrefix, bool explain) {
    if (!setupStatus_.has()) return;
    const ExportStatus* row = nullptr;
    const auto& targets = export_targets();
    for (size_t i = 0; i < targets.size() && i < exportStatus_.size(); ++i)
        if (platform == targets[i].platform) row = &exportStatus_[i];
    if (!row) return;
    const bool busy = setupJob_.running();
    const std::vector<SetupAction> actions = setup_actions_for_row(platform, *row, setupStatus_.status());
    if (explain && !row->ready && !actions.empty()) wrapped(kWarn, export_error_text(row->error));
    for (const SetupAction& a : actions) {
        ImGui::PushID(a.key.c_str());
        if (!a.why.empty()) note(a.why);
        ImGui::BeginDisabled(busy);
        if (ImGui::Button(a.label.c_str())) request_setup(a);
        ImGui::EndDisabled();
        at_track(std::string("setup:") + idPrefix + ":" + platform + ":" + a.key, !busy);
        tip(busy ? std::string("A setup is already running (Set Up This Computer shows it).") : a.tooltip);
        ImGui::PopID();
    }
}

// ---- the window -----------------------------------------------------------------------------------------------------

void Editor::draw_setup_window() {
    draw_setup_license_dialog();
    if (!showSetup_) return;
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(ImVec2(800, 700), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (setupFocus_) {
        ImGui::SetNextWindowFocus();
        setupFocus_ = false;
    }
    if (!ImGui::Begin("Set up this computer###Setup", &showSetup_, ImGuiWindowFlags_NoDocking)) {
        ImGui::End();
        return;
    }
    const bool busy = setupJob_.running();
    ImGui::PushTextWrapPos(0);
    const SetupStatus& status = setupStatus_.status();

    note("An export needs a few things that are not part of FactorIA: the Android build tools, the players of the other platforms, CMake and "
         "Xcode. Each button installs one of them. Everything goes into one folder of yours (no administrator password, no PATH, no "
         "registry), each download is checked against its publisher's checksum, and nothing is downloaded until you press a button.");
    if (setupStatus_.has()) {
        ImGui::AlignTextToFramePadding();
        ImGui::TextDisabled("Installed into");
        ImGui::SameLine();
        ImGui::TextUnformatted(status.home.c_str());
        std::error_code ec;
        const bool homeExists = std::filesystem::is_directory(utf8_path(status.home), ec);
        ImGui::SameLine();
        ImGui::BeginDisabled(!homeExists);
        if (ImGui::SmallButton((std::string("Show in ") + file_manager_name()).c_str()))
            if (std::string why = open_in_file_manager(status.home); !why.empty()) notify(why, 1);
        ImGui::EndDisabled();
        at_track("setup:show-folder", homeExists);
        tip(homeExists ? "Opens the folder in the file manager." : "Nothing is installed yet: the first install creates it.");
    }
    ImGui::SameLine();
    ImGui::BeginDisabled(busy || setupStatus_.refreshing());
    if (ImGui::SmallButton("Check again")) setupStatus_.refresh(make_setup_context(), time_);
    ImGui::EndDisabled();
    at_track("setup:refresh", !busy && !setupStatus_.refreshing());
    tip("Looks at this computer again (nothing is downloaded or changed).");
    if (setupStatus_.refreshing()) {
        ImGui::SameLine();
        ImGui::TextDisabled("Checking...");
    }

    // ---- one section per component
    if (!setupStatus_.has()) {
        ImGui::Spacing();
        ImGui::TextDisabled("Checking this computer...");
    }
    for (const SetupComponent& c : status.components) {
        ImGui::PushID(c.id.c_str());
        ImGui::SeparatorText(c.title.c_str());
        ImGui::TextColored(state_color(c.state), "%s", setup_state_label(c.state));
        const std::string size = setup_size_text(c.installSizeMb);
        if (!size.empty() && c.state != "installed") {
            ImGui::SameLine();
            ImGui::TextDisabled("  Download: %s", size.c_str());
        }
        ImGui::TextWrapped("%s", c.details.c_str());
        for (const auto& [key, value] : c.paths) {
            ImGui::TextDisabled("%s:", path_label(key).c_str());
            ImGui::SameLine();
            ImGui::TextUnformatted(value.c_str());
        }
        for (const std::string& p : c.problems) wrapped(kWarn, "- " + p);
        if (const std::optional<SetupAction> action = setup_action_for_component(c, status.home)) {
            ImGui::BeginDisabled(busy);
            if (ImGui::Button(action->label.c_str())) request_setup(*action);
            ImGui::EndDisabled();
            at_track("setup:install:" + c.id, !busy);
            tip(busy ? std::string("A setup is already running.") : action->tooltip);
        }
        ImGui::PopID();
    }
    ImGui::Spacing();
    ImGui::Separator();

    // ---- the install that runs, or the report of the last one
    if (setupScroll_ > 0) {
        // The report starts at the top of the window's view. Asked for a few frames: the window clamps the scroll to the
        // content height of the frame before, which does not hold the report yet.
        ImGui::SetScrollHereY(0.0f);
        --setupScroll_;
    }
    if (busy) {
        const SetupInstallOptions o = setupJob_.options();
        const int dots = int(std::fmod(time_ * 3.0, 4.0));
        const std::string what = setup_what(o.component, o.platforms);
        if (setupJob_.cancelling()) ImGui::Text("Cancelling the setup of %s%.*s", what.c_str(), dots, "...");
        else ImGui::Text("Setting up %s%.*s", what.c_str(), dots, "...");
        const double fraction = setupJob_.fraction();
        char overlay[16] = {};
        if (fraction >= 0.0) std::snprintf(overlay, sizeof overlay, "%d%%", int(fraction * 100.0 + 0.5));
        // A known percentage fills the bar; between downloads (unpacking, looking something up) it keeps moving.
        ImGui::ProgressBar(fraction >= 0.0 ? float(fraction) : float(-1.0 * ImGui::GetTime()), ImVec2(-FLT_MIN, 0), fraction >= 0.0 ? overlay : "working...");
        at_track("setup:progress");
        const std::string line = setupJob_.progress_line();
        if (!line.empty()) ImGui::TextWrapped("%s", line.c_str());
        ImGui::BeginDisabled(setupJob_.cancelling());
        if (ImGui::Button("Cancel")) setupJob_.cancel();
        ImGui::EndDisabled();
        at_track("setup:cancel", !setupJob_.cancelling());
        tip("Stops the download and leaves nothing half-installed: a setup that does not finish installs nothing.");
        const std::vector<std::string> lines = setupJob_.recent_lines();
        if (!lines.empty() && ImGui::TreeNodeEx("Log", ImGuiTreeNodeFlags_None)) {
            const float h = ImGui::GetTextLineHeightWithSpacing() * 10.0f;
            if (ImGui::BeginChild("##setuplog", ImVec2(0, h), ImGuiChildFlags_Borders)) {
                const bool atBottom = ImGui::GetScrollY() >= ImGui::GetScrollMaxY() - 4.0f;
                for (const std::string& l : lines) ImGui::TextUnformatted(l.c_str());
                if (atBottom) ImGui::SetScrollHereY(1.0f);
            }
            ImGui::EndChild();
            ImGui::TreePop();
        }
        at_track("setup:log");
    } else if (!setupLast_) {
        ImGui::TextDisabled("Press a button above to install it. Its report (what was installed, warnings, next steps) shows here.");
    } else {
        const SetupOutcome& o = *setupLast_;
        const std::string what = setup_what(o.options.component, o.options.platforms);
        if (o.ok) {
            ImGui::TextColored(kReady, "%s", setup_summary(o).c_str());
            for (const SetupStep& s : o.report.steps) {
                ImGui::BulletText("%s: %s%s%s", s.title.c_str(), s.outcome.c_str(), s.detail.empty() ? "" : " - ", s.detail.c_str());
            }
            for (const auto& [key, value] : o.report.paths) ImGui::TextDisabled("%s: %s", path_label(key).c_str(), value.c_str());
            for (const std::string& w : o.report.warnings) wrapped(kWarn, w);
            if (!o.report.nextSteps.empty()) {
                ImGui::Spacing();
                ImGui::TextUnformatted("Next steps");
                for (size_t i = 0; i < o.report.nextSteps.size(); ++i) ImGui::TextWrapped("%zu. %s", i + 1, o.report.nextSteps[i].c_str());
            }
        } else if (o.cancelled) {
            wrapped(kWarn, "Setup of " + what + " cancelled. Nothing was installed by it.");
        } else if (o.licenseRequired) {
            wrapped(kWarn, "The Android SDK license has to be accepted before anything is downloaded. Press Install again to read it.");
        } else {
            wrapped(kFailed, "Setup of " + what + " failed: " + o.error);
            if (!o.hint.empty()) note("How to fix it: " + o.hint);
            for (const SetupStep& s : o.report.steps)
                ImGui::BulletText("%s: %s%s%s", s.title.c_str(), s.outcome.c_str(), s.detail.empty() ? "" : " - ", s.detail.c_str());
        }
        ImGui::Spacing();
        if (ImGui::SmallButton("Copy report")) {
            ImGui::SetClipboardText(setup_report_text(o).c_str());
            notify("Setup report copied", 0);
        }
        at_track("setup:copy-report");
    }
    ImGui::PopTextWrapPos();
    ImGui::End();
}

// ---- the Android SDK license ----------------------------------------------------------------------------------------

void Editor::draw_setup_license_dialog() {
    constexpr const char* kPopup = "Android SDK license###SetupLicense";
    if (setupLicenseRequest_) {
        ImGui::OpenPopup(kPopup);
        setupLicenseRequest_ = false;
    }
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(ImVec2(780, 600), ImGuiCond_Appearing);
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (!ImGui::BeginPopupModal(kPopup, nullptr, ImGuiWindowFlags_NoSavedSettings)) return;
    if (!setupLicenseOpen_) {  // the license turned out not to be needed, or the install started
        ImGui::CloseCurrentPopup();
        ImGui::EndPopup();
        return;
    }
    using State = SetupLicenseLoad::State;
    const State state = setupLicense_.state();
    ImGui::PushTextWrapPos(0);
    note("Installing the Android build tools downloads Google's Android SDK, which comes with a license agreement between you and Google. "
         "Read it, and accept it to continue. FactorIA never accepts it for you, and nothing is downloaded before you do.");
    ImGui::Spacing();

    const float footerH = ImGui::GetFrameHeightWithSpacing() * 2 + ImGui::GetStyle().ItemSpacing.y * 3;
    if (state == State::Ready && !setupLicense_.licenses().empty()) {
        const SetupLicense& lic = setupLicense_.licenses().front();
        ImGui::TextUnformatted(lic.title.empty() ? "Android SDK license" : lic.title.c_str());
        // The full text in a box of its own, read-only, scrolling.
        if (ImGui::BeginChild("##licensetext", ImVec2(0, -footerH), ImGuiChildFlags_Borders)) {
            ImGui::PushTextWrapPos(0);
            size_t pos = 0;
            while (pos <= lic.text.size()) {
                size_t end = lic.text.find('\n', pos);
                if (end == std::string::npos) end = lic.text.size();
                std::string paragraph = lic.text.substr(pos, end - pos);
                while (!paragraph.empty() && paragraph.back() == '\r') paragraph.pop_back();
                if (paragraph.empty()) ImGui::Spacing();
                else ImGui::TextWrapped("%s", paragraph.c_str());
                if (end == lic.text.size()) break;
                pos = end + 1;
            }
            ImGui::PopTextWrapPos();
        }
        ImGui::EndChild();
        at_track("setup:license-text");
    } else if (state == State::Failed) {
        wrapped(kFailed, setupLicense_.error());
        if (ImGui::Button("Try again")) {
            setupLicense_.reset();
            setupLicense_.start(make_setup_context());
        }
        at_track("setup:license-retry");
        ImGui::Dummy(ImVec2(0, std::max(0.0f, ImGui::GetContentRegionAvail().y - footerH)));
    } else {
        const int dots = int(std::fmod(time_ * 3.0, 4.0));
        ImGui::Text("Loading license%.*s", dots + 1, "...");
        at_track("setup:license-loading");
        ImGui::Dummy(ImVec2(0, std::max(0.0f, ImGui::GetContentRegionAvail().y - footerH)));
    }

    const bool ready = state == State::Ready && !setupLicense_.licenses().empty();
    ImGui::BeginDisabled(!ready);
    ImGui::Checkbox("I have read the license above and I accept it", &setupLicenseTick_);
    ImGui::EndDisabled();
    at_track("setup:license-check", ready);
    ImGui::BeginDisabled(!(ready && setupLicenseTick_));
    if (ImGui::Button("I accept", ImVec2(120, 0))) {
        setupLicenseOpen_ = false;
        setupLicense_.reset();
        setupLicenseTick_ = false;
        start_setup_install(setupPending_, true);  // the user agreed: the only place acceptLicenses is true
    }
    ImGui::EndDisabled();
    at_track("setup:license-accept", ready && setupLicenseTick_);
    ImGui::SameLine();
    if (ImGui::Button("Decline", ImVec2(120, 0)) || ImGui::IsKeyPressed(ImGuiKey_Escape)) {
        setupLicenseOpen_ = false;
        setupLicense_.reset();
        setupLicenseTick_ = false;
        ImGui::CloseCurrentPopup();
        notify("The Android build tools were not installed: the license was declined.", 1);
    }
    at_track("setup:license-decline");
    ImGui::SameLine();
    ImGui::TextDisabled("Nothing is installed if you decline.");
    ImGui::PopTextWrapPos();
    ImGui::EndPopup();
}

}  // namespace fa::editor
