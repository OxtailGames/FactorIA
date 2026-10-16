// The Export window's logic (File > Export Game..., toolbar Export): the platforms it offers, the fa::ExportOptions a
// button builds, what each platform's row says before an export, and the export itself on a worker thread.
//
// Everything here is plain logic over fa/tooling/export.h: no ImGui, no Editor, no window. export_panel.cpp only draws
// it, and tests call it directly. The editor never packages a game its own way: a row is fa::plan_export (the checks
// export_project runs before it writes anything) and a button press is fa::export_project, the function behind
// `factoria export` and the project.export command.
#pragma once

#include <atomic>
#include <deque>
#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <vector>

#include "fa/tooling/export.h"

namespace fa::editor {

struct ExportTarget {
    const char* platform;  // fa::export_project's name: windows | macos | linux | android | ios
    const char* label;     // button text
    bool mobile;           // writes a Gradle / Xcode project that is built afterwards
};
// The buttons, in the order the window shows them.
const std::vector<ExportTarget>& export_targets();
const ExportTarget* find_export_target(const std::string& platform);
// What an export of this kind produces, in one line (shown under the platform's button). `format` is the project's
// export.android.format ("apk", "aab", "gradle"; "" = apk): Android's note says what the export builds.
std::string export_target_note(const ExportTarget& target, const std::string& format = "");
// "APK", "AAB" or "Gradle project" for an Android format; "" for anything else.
std::string export_format_label(const std::string& format);

// What the Export window lets the user choose.
struct ExportSettings {
    std::string outDir;   // parent folder of the export; relative = to the project; "" = <project>/build/export
    bool release = false; // changes the build commands in nextSteps and the iOS script
    std::map<std::string, std::string> players;  // desktop platform -> factoria_player built for it (another OS)
};
// The options a platform's button exports with.
ExportOptions export_options(const std::string& projectDir, const std::string& platform, const ExportSettings& settings);
// The folder exports go into: settings.outDir resolved against the project, or <project>/build/export.
std::string export_parent_dir(const std::string& projectDir, const ExportSettings& settings);
// A desktop platform other than this machine's: exporting it needs a factoria_player built there (Choose player...).
bool export_needs_player(const std::string& platform);

// A platform's row before exporting: ready (the folder an export replaces, the mode, the player) or why not.
struct ExportStatus {
    bool ready = false;
    ExportPlan plan;          // when ready
    std::string error, hint;  // when not: the teaching error export_project would return
};
ExportStatus check_export(const ExportOptions& options);

// One export's result, as the window shows it.
struct ExportOutcome {
    std::string platform;
    bool ok = false;
    ExportReport report;      // when ok: outputDir, mode, format, artifact, notices, files, nextSteps, warnings
    std::string error, hint;  // when not
    bool cancelled = false;   // the user pressed Cancel and the export stopped (the error just says "cancelled")
    double seconds = 0;
};
ExportOutcome run_export(const ExportOptions& options);
// One line for the toast and the log: "Exported macOS to <dir>" / "Export for Windows failed: <message>" /
// "Export for Android cancelled".
std::string export_summary(const ExportOutcome& outcome);
// The whole report as plain text (Copy report): output folder, format, artifact, mode, warnings, numbered next steps; or the
// error and hint.
std::string export_report_text(const ExportOutcome& outcome);
// An export error without the "export: " every message of export_project starts with.
std::string export_error_text(const std::string& message);

// Runs run_export on a worker thread, one export at a time: the UI thread starts it and polls it every frame, so a big
// game (or the macOS signature, or the Gradle build of an Android APK) never freezes the window. export_project touches no
// engine state, only files. While it runs, the lines of its long steps (ExportOptions::progress: the Gradle output) are kept
// for the window, and cancel() stops it (ExportOptions::cancel).
class ExportJob {
public:
    ExportJob() = default;
    ExportJob(const ExportJob&) = delete;
    ExportJob& operator=(const ExportJob&) = delete;
    ~ExportJob() { wait(); }

    bool start(ExportOptions options);              // false while an export runs
    bool running() const { return running_.load(); }
    void cancel() { cancel_.store(true); }          // asks the running export to stop; it fails with "cancelled"
    bool cancelling() const { return running() && cancel_.load(); }
    void add_line(const std::string& line);         // what ExportOptions::progress does: keeps one line (blank ones are dropped)
    std::string progress_line() const;              // the latest non-empty line of the running export ("" = none yet)
    std::vector<std::string> recent_lines() const;  // the last lines (at most kMaxLines), oldest first
    static constexpr size_t kMaxLines = 200;
    const std::string& platform() const { return platform_; }  // of the running or last export
    std::optional<ExportOutcome> take_result();     // the finished export's outcome, once; nullopt while it runs
    void wait();                                    // blocks until the running export is done (project switch, quit)

private:
    std::thread thread_;
    std::atomic<bool> running_{false};
    CancelFlag cancel_{false};
    mutable std::mutex mu_;
    std::optional<ExportOutcome> result_;
    std::deque<std::string> lines_;
    std::string platform_;
};

}  // namespace fa::editor
