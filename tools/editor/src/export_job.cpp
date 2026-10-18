// The Export window's logic (export_job.h): rows from fa::plan_export, exports with fa::export_project.
#include "export_job.h"

#include <chrono>
#include <filesystem>

namespace fa::editor {

namespace stdfs = std::filesystem;

const std::vector<ExportTarget>& export_targets() {
    static const std::vector<ExportTarget> targets = {
        {"windows", "Windows", false}, {"macos", "macOS", false},  {"linux", "Linux", false},
        {"android", "Android", true},  {"ios", "iOS", true},     {"web", "Web", false},
    };
    return targets;
}

const ExportTarget* find_export_target(const std::string& platform) {
    const std::string p = normalize_export_platform(platform);
    for (const ExportTarget& t : export_targets())
        if (p == t.platform) return &t;
    return nullptr;
}

std::string export_format_label(const std::string& format) {
    if (format == "apk") return "APK";
    if (format == "aab") return "AAB";
    if (format == "gradle") return "Gradle project";
    return "";
}

std::string export_target_note(const ExportTarget& target, const std::string& format) {
    const std::string p = target.platform;
    if (p == "android") {
        if (format == "aab") return "Builds a Google Play bundle (.aab) with Gradle, next to the Gradle project it writes.";
        if (format == "gradle") return "A Gradle project only: nothing is built (open it in Android Studio, or the next steps say how).";
        return "Builds the APK with Gradle (the first build downloads Gradle and the Android plugin), next to the Gradle project it writes.";
    }
    if (p == "ios") return "An Xcode project and build_ios.sh: build it on a Mac with Xcode afterwards (the next steps say how).";
    if (p == "web")
        return "A folder with index.html, the web player and game.pak, and a .zip of it to upload to itch.io as an HTML5 game. "
               "Serve the folder over http to try it (the next steps say how).";
    if (p == "macos") return "An .app with the game and its player, ready to run and share.";
    return "A folder with the game and its player, ready to run and share.";
}

std::string export_parent_dir(const std::string& projectDir, const ExportSettings& settings) {
    stdfs::path out = settings.outDir.empty() ? stdfs::path("build") / "export" : stdfs::path(settings.outDir);
    if (out.is_relative()) out = stdfs::path(projectDir) / out;
    return out.lexically_normal().generic_string();
}

ExportOptions export_options(const std::string& projectDir, const std::string& platform, const ExportSettings& settings) {
    ExportOptions o;
    o.projectDir = projectDir;
    o.platform = platform;
    o.outDir = export_parent_dir(projectDir, settings);
    o.release = settings.release;
    if (auto it = settings.players.find(normalize_export_platform(platform)); it != settings.players.end())
        o.playerBinary = it->second;
    return o;
}

bool export_needs_player(const std::string& platform) {
    const ExportTarget* t = find_export_target(platform);
    // The web player is a folder of two files, not "another OS's factoria_player": its row offers the download instead.
    return t && !t->mobile && std::string(t->platform) != "web" && normalize_export_platform(platform) != normalize_export_platform("");
}

ExportStatus check_export(const ExportOptions& options) {
    ExportStatus s;
    auto plan = plan_export(options);
    if (plan.ok()) {
        s.ready = true;
        s.plan = std::move(plan.value());
    } else {
        s.error = plan.error().message;
        s.hint = plan.error().hint;
    }
    return s;
}

ExportOutcome run_export(const ExportOptions& options) {
    ExportOutcome out;
    out.platform = normalize_export_platform(options.platform);
    if (out.platform.empty()) out.platform = options.platform;
    const auto t0 = std::chrono::steady_clock::now();
    auto r = export_project(options);
    out.seconds = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
    if (r.ok()) {
        out.ok = true;
        out.report = std::move(r.value());
    } else if (is_cancelled(options.cancel) && r.error().message.find("cancel") != std::string::npos) {
        out.cancelled = true;  // the flag was set and the export stopped because of it (its error says "cancelled")
        out.error = r.error().message;
        out.hint = r.error().hint;
    } else {
        out.error = r.error().message;
        out.hint = r.error().hint;
    }
    return out;
}

std::string export_error_text(const std::string& message) {
    return message.rfind("export: ", 0) == 0 ? message.substr(8) : message;
}

static std::string label_of(const std::string& platform) {
    const ExportTarget* t = find_export_target(platform);
    return t ? t->label : platform;
}

std::string export_summary(const ExportOutcome& outcome) {
    if (outcome.cancelled) return "Export for " + label_of(outcome.platform) + " cancelled";
    if (!outcome.ok) return "Export for " + label_of(outcome.platform) + " failed: " + export_error_text(outcome.error);
    const std::string format = export_format_label(outcome.report.format);
    std::string s = "Exported " + label_of(outcome.platform) + (format.empty() ? "" : " " + format) + " to " + outcome.report.outputDir;
    if (const size_t n = outcome.report.warnings.size()) s += " (" + std::to_string(n) + " warning" + (n == 1 ? ")" : "s)");
    return s;
}

std::string export_report_text(const ExportOutcome& outcome) {
    std::string t;
    if (outcome.cancelled) return "Export for " + label_of(outcome.platform) + " cancelled.\n";
    if (!outcome.ok) {
        t = "Export for " + label_of(outcome.platform) + " failed: " + export_error_text(outcome.error) + "\n";
        if (!outcome.hint.empty()) t += "How to fix it: " + outcome.hint + "\n";
        return t;
    }
    const ExportReport& r = outcome.report;
    t = "Export for " + label_of(outcome.platform) + "\nOutput folder: " + r.outputDir + "\n";
    if (!r.format.empty()) t += "Format: " + export_format_label(r.format) + "\n";
    if (!r.artifact.empty()) t += "Artifact: " + r.artifact + "\n";
    if (!r.mode.empty()) t += "Mode: " + r.mode + "\n";
    if (!r.warnings.empty()) {
        t += "Warnings:\n";
        for (const std::string& w : r.warnings) t += "- " + w + "\n";
    }
    if (!r.nextSteps.empty()) {
        t += "Next steps:\n";
        for (size_t i = 0; i < r.nextSteps.size(); ++i) t += std::to_string(i + 1) + ". " + r.nextSteps[i] + "\n";
    }
    return t;
}

bool ExportJob::start(ExportOptions options) {
    if (running_) return false;
    wait();  // the previous export's thread has finished: join it
    {
        std::lock_guard<std::mutex> lock(mu_);
        result_.reset();
    }
    {
        std::lock_guard<std::mutex> lock(mu_);
        lines_.clear();
    }
    cancel_.store(false);
    options.cancel = &cancel_;
    options.progress = [this, outer = std::move(options.progress)](const std::string& line) {
        add_line(line);
        if (outer) outer(line);
    };
    platform_ = normalize_export_platform(options.platform);
    running_ = true;
    thread_ = std::thread([this, o = std::move(options)] {
        ExportOutcome out = run_export(o);
        {
            std::lock_guard<std::mutex> lock(mu_);
            result_ = std::move(out);
        }
        running_ = false;  // after the result: take_result() sees both
    });
    return true;
}

void ExportJob::add_line(const std::string& raw) {
    size_t b = 0, e = raw.size();
    while (b < e && (raw[b] == ' ' || raw[b] == '\t')) ++b;
    while (e > b && (raw[e - 1] == '\r' || raw[e - 1] == '\n' || raw[e - 1] == ' ' || raw[e - 1] == '\t')) --e;
    if (b == e) return;
    std::lock_guard<std::mutex> lock(mu_);
    lines_.push_back(raw.substr(b, e - b));
    while (lines_.size() > kMaxLines) lines_.pop_front();
}

std::string ExportJob::progress_line() const {
    std::lock_guard<std::mutex> lock(mu_);
    return lines_.empty() ? std::string() : lines_.back();
}

std::vector<std::string> ExportJob::recent_lines() const {
    std::lock_guard<std::mutex> lock(mu_);
    return std::vector<std::string>(lines_.begin(), lines_.end());
}

std::optional<ExportOutcome> ExportJob::take_result() {
    if (running_) return std::nullopt;
    wait();
    std::lock_guard<std::mutex> lock(mu_);
    std::optional<ExportOutcome> r = std::move(result_);
    result_.reset();
    return r;
}

void ExportJob::wait() {
    if (thread_.joinable()) thread_.join();
}

}  // namespace fa::editor
