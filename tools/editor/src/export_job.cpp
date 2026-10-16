// The Export window's logic (export_job.h): rows from fa::plan_export, exports with fa::export_project.
#include "export_job.h"

#include <chrono>
#include <filesystem>

namespace fa::editor {

namespace stdfs = std::filesystem;

const std::vector<ExportTarget>& export_targets() {
    static const std::vector<ExportTarget> targets = {
        {"windows", "Windows", false}, {"macos", "macOS", false},  {"linux", "Linux", false},
        {"android", "Android", true},  {"ios", "iOS", true},
    };
    return targets;
}

const ExportTarget* find_export_target(const std::string& platform) {
    const std::string p = normalize_export_platform(platform);
    for (const ExportTarget& t : export_targets())
        if (p == t.platform) return &t;
    return nullptr;
}

std::string export_target_note(const ExportTarget& target) {
    const std::string p = target.platform;
    if (p == "android") return "A Gradle project: build the APK from it afterwards (the next steps say how).";
    if (p == "ios") return "An Xcode project and build_ios.sh: build it on a Mac with Xcode afterwards (the next steps say how).";
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
    return t && !t->mobile && normalize_export_platform(platform) != normalize_export_platform("");
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
    if (!outcome.ok) return "Export for " + label_of(outcome.platform) + " failed: " + export_error_text(outcome.error);
    std::string s = "Exported " + label_of(outcome.platform) + " to " + outcome.report.outputDir;
    if (const size_t n = outcome.report.warnings.size()) s += " (" + std::to_string(n) + " warning" + (n == 1 ? ")" : "s)");
    return s;
}

std::string export_report_text(const ExportOutcome& outcome) {
    std::string t;
    if (!outcome.ok) {
        t = "Export for " + label_of(outcome.platform) + " failed: " + export_error_text(outcome.error) + "\n";
        if (!outcome.hint.empty()) t += "How to fix it: " + outcome.hint + "\n";
        return t;
    }
    const ExportReport& r = outcome.report;
    t = "Export for " + label_of(outcome.platform) + "\nOutput folder: " + r.outputDir + "\n";
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
