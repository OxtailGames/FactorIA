// The Set Up This Computer window's logic (File > Set Up This Computer..., the "Set up" buttons of the Export and Platform
// settings windows): which setup fixes which export row, one install on a worker thread with its progress, the license
// text of the Android SDK, and the cached status the UI shows.
//
// Everything here is plain logic over fa/tooling/setup.h: no ImGui, no Editor, no window. setup_panel.cpp only draws it, and
// tests call it directly with an injected fa::SetupContext (a fake downloader and process runner, a temporary home), so
// nothing here needs the network. The editor never installs anything its own way: a button press is fa::setup_install, the
// function behind `factoria setup` and the setup.install command.
#pragma once

#include <atomic>
#include <chrono>
#include <deque>
#include <future>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "export_job.h"
#include "fa/tooling/setup.h"

namespace fa::editor {

// ---------------------------------------------------------------------------------------------------------------------
// Words

// "installed" -> "Installed", "partial" -> "Partly installed", "missing" -> "Not installed", "unsupported" -> "Not needed here".
const char* setup_state_label(const std::string& state);
// "about 75 MB", "about 1.1 GB"; "" for nothing to download.
std::string setup_size_text(int mb);
// What a setup installs, in a few words: "Android build tools", "Windows player", "mobile libraries", "CMake", "Xcode".
std::string setup_what(const std::string& component, const std::vector<std::string>& platforms = {});
// The trailing percentage of a progress line ("Downloading CMake 3.31.6: 31 MB of 75 MB (40%)" -> 40; "... 40%" -> 40);
// nullopt when the line does not end in one.
std::optional<int> parse_progress_percent(const std::string& line);

// ---------------------------------------------------------------------------------------------------------------------
// What a button runs

struct SetupAction {
    std::string component;               // "android" | "players" | "cmake" | "xcode"
    std::vector<std::string> platforms;  // players: "windows" | "linux" | "macos" | "mobile" (empty = the default)
    bool force = false;                  // reinstall what is found
    std::string label;                   // the button: "Install Android build tools", "Download Windows player"...
    std::string tooltip;                 // what it does and how big it is
    std::string why;                     // a row's extra setup (CMake, Xcode): what is missing, shown above the button ("" = none)
    std::string key;                     // "android" | "players-windows" | "players-mobile" | "cmake" | "xcode": for widget ids
    SetupInstallOptions options(bool acceptLicenses = false) const;
};

// The button of a component in the Set Up This Computer window: "Install" / "Reinstall" / "Open App Store"; nullopt when
// there is nothing to do (unsupported here, Xcode already complete).
std::optional<SetupAction> setup_action_for_component(const SetupComponent& component, const std::string& home = {});

// The buttons of an Export window row (or the Platform settings tab of that platform): the setups that fix a row that is not
// ready. `platform` is fa::export_project's name (windows | macos | linux | android | ios).
//   android  the toolchain is missing (no JDK 17+ or no Android SDK found)      -> Install Android build tools
//            the export says there is no prebuilt player and the mobile libraries are missing -> Download mobile libraries
//   windows, linux, macos for another OS: no player of that OS installed        -> Download <OS> player
//   ios      no prebuilt player and no mobile libraries                          -> Download mobile libraries
//            CMake missing (even when the row is ready: build_ios.sh needs it)  -> Install CMake
//            Xcode missing or incomplete (even when ready)                       -> Open App Store (Xcode) / Show Xcode steps
// A row that is ready, or not ready for a reason a setup cannot fix (a missing id, a folder in the way), gets none of the
// first kinds. Empty while `status` has no components.
std::vector<SetupAction> setup_actions_for_row(const std::string& platform, const ExportStatus& row, const SetupStatus& status);

// ---------------------------------------------------------------------------------------------------------------------
// One install

// What an install did, as the window shows it.
struct SetupOutcome {
    SetupInstallOptions options;  // what was asked
    bool ok = false;
    bool cancelled = false;        // the user pressed Cancel and the install stopped
    bool licenseRequired = false;  // android: the license must be accepted first (the install did nothing)
    SetupReport report;            // always filled as far as the install got
    std::string code;              // when !ok: SetupResult::code
    std::string error, hint;       // when !ok
    double seconds = 0;
};
// Runs fa::setup_install and keeps what the window needs of its result (blocks: call it from a worker).
SetupOutcome run_setup(const SetupInstallOptions& options, const SetupContext& context);
// One line for the toast: "Installed Android build tools in 3m 10s" / "Set up Windows player failed: <message>" /
// "Set up CMake cancelled" / "CMake was already set up".
std::string setup_summary(const SetupOutcome& outcome);
// The whole report as plain text: the steps, the paths, the next steps and warnings; or the error and hint.
std::string setup_report_text(const SetupOutcome& outcome);

// Runs run_setup on a worker thread, one install at a time: the UI thread starts it and polls it every frame, so a download of
// hundreds of megabytes never freezes the window. The lines of its steps (SetupContext::progress, which can come from a
// helper thread) are kept for the window, and cancel() stops it (SetupContext::cancel; the download in flight is killed).
class SetupJob {
public:
    SetupJob() = default;
    SetupJob(const SetupJob&) = delete;
    SetupJob& operator=(const SetupJob&) = delete;
    ~SetupJob();  // cancels a running install and waits for it: quitting the editor never leaves curl behind

    // `context.progress` and `context.cancel` are replaced by the job's own (the caller's progress still gets every line).
    bool start(SetupInstallOptions options, SetupContext context);  // false while an install runs
    bool running() const { return running_.load(); }
    void cancel() { cancel_.store(true); }
    bool cancelling() const { return running() && cancel_.load(); }
    void add_line(const std::string& line);          // what SetupContext::progress does: keeps one line (blank ones are dropped)
    std::string progress_line() const;               // the latest line ("" = none yet)
    double fraction() const;                         // 0..1 from the latest line's percentage; -1 = this step has none (a marquee)
    std::vector<std::string> recent_lines() const;   // the last lines (at most kMaxLines), oldest first
    static constexpr size_t kMaxLines = 200;
    SetupInstallOptions options() const;             // of the running or last install
    std::optional<SetupOutcome> take_result();       // the finished install's outcome, once; nullopt while it runs
    void wait();                                     // blocks until the running install is done

private:
    std::thread thread_;
    std::atomic<bool> running_{false};
    CancelFlag cancel_{false};
    mutable std::mutex mu_;
    std::optional<SetupOutcome> result_;
    std::deque<std::string> lines_;
    int percent_ = -1;
    SetupInstallOptions options_;
};

// ---------------------------------------------------------------------------------------------------------------------
// What the UI shows

// Runs a function on a worker thread and hands its result to the UI thread, which polls every frame. One run at a time.
template <class T>
class Async {
public:
    Async() = default;
    Async(const Async&) = delete;
    Async& operator=(const Async&) = delete;
    ~Async() { wait(); }
    template <class F>
    bool start(F&& fn) {
        if (running_) return false;
        wait();
        running_ = true;
        future_ = std::async(std::launch::async, std::forward<F>(fn));
        return true;
    }
    bool running() const { return running_; }
    // The finished result, once; nullopt while it runs or when nothing was started.
    std::optional<T> take() {
        if (!running_ || future_.wait_for(std::chrono::seconds(0)) != std::future_status::ready) return std::nullopt;
        running_ = false;
        return future_.get();
    }
    void wait() {
        if (running_) {
            future_.wait();
            running_ = false;
            (void)future_.get();  // an untaken result is dropped
        }
    }

private:
    std::future<T> future_;
    bool running_ = false;
};

// The status of every component, refreshed on a worker thread (setup_status looks at folders and runs `cmake --version` and
// `xcodebuild -version`, which a frame cannot wait for) and never downloading anything. The UI asks every frame.
class SetupStatusCache {
public:
    // Starts a refresh unless one runs. `now` is the UI's clock: it dates the request for stale().
    bool refresh(const SetupContext& context, double now);
    bool refreshing() const { return job_.running(); }
    // Takes a finished refresh in. True when the status changed this call.
    bool poll();
    bool has() const { return has_; }
    const SetupStatus& status() const { return status_; }
    // Nothing yet, or the last request is older than `maxAge` seconds.
    bool stale(double now, double maxAge) const { return !has_ || now - requestedAt_ > maxAge; }
    // Tests and the autotest: use this status as the answer.
    void set(SetupStatus status, double now);
    void wait() { job_.wait(); }

private:
    Async<SetupStatus> job_;
    SetupStatus status_;
    bool has_ = false;
    double requestedAt_ = -1e9;
};

// The Android SDK license text, fetched on a worker thread when the dialog opens (it is the only network request of a status).
class SetupLicenseLoad {
public:
    enum class State {
        Idle,       // nothing asked
        Loading,    // "Loading license..."
        Ready,      // licenses holds the text to show
        NotNeeded,  // the licenses are accepted already: the install needs no agreement
        Failed,     // the text could not be fetched: error says why
    };
    bool start(const SetupContext& context);   // false while loading
    bool poll();                               // true when a result arrived this call
    void reset();                              // forget it (the dialog closed)
    State state() const { return state_; }
    bool loading() const { return state_ == State::Loading; }
    const std::vector<SetupLicense>& licenses() const { return licenses_; }
    const std::string& error() const { return error_; }
    void set(State state, std::vector<SetupLicense> licenses, std::string error = {});  // tests and the autotest
    void wait() { job_.wait(); }

private:
    Async<SetupStatus> job_;
    State state_ = State::Idle;
    std::vector<SetupLicense> licenses_;
    std::string error_;
};

}  // namespace fa::editor
