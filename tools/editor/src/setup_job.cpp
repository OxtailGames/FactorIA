// The Set Up This Computer window's logic: see setup_job.h.
#include "setup_job.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <exception>
#include <filesystem>

namespace fa::editor {

namespace {

std::string duration_text(double s) {
    char buf[32];
    if (s < 1.0) std::snprintf(buf, sizeof buf, "%.0f ms", s * 1000.0);
    else if (s < 60.0) std::snprintf(buf, sizeof buf, "%.1f s", s);
    else std::snprintf(buf, sizeof buf, "%dm %02ds", int(s / 60.0), int(std::fmod(s, 60.0)));
    return buf;
}

const char* os_label(const std::string& os) {
    if (os == "windows") return "Windows";
    if (os == "linux") return "Linux";
    if (os == "macos") return "macOS";
    return "";
}

const SetupComponent* find_component(const SetupStatus& status, const char* id) { return status.find(id); }

bool has_path(const SetupComponent& c, const std::string& key) {
    return std::any_of(c.paths.begin(), c.paths.end(), [&](const auto& p) { return p.first == key && !p.second.empty(); });
}

bool contains(const std::string& text, const char* what) { return text.find(what) != std::string::npos; }

std::string join_path(const std::string& home, const char* sub) {
    return home.empty() ? std::string(sub) : (std::filesystem::path(home) / sub).string();
}

std::string size_sentence(int mb) {
    const std::string size = setup_size_text(mb);
    return size.empty() ? std::string() : " Download: " + size + ".";
}

SetupAction android_action(const SetupComponent& c, const std::string& home, bool reinstall) {
    SetupAction a;
    a.component = "android";
    a.key = "android";
    a.force = reinstall;
    a.label = reinstall ? "Reinstall" : "Install Android build tools";
    a.tooltip = std::string(reinstall ? "Downloads everything again: " : "Downloads ") + "a JDK " + std::to_string(kSetupJdkMajor) +
                " (Eclipse Temurin) and the Android SDK (command-line tools, platform-tools, platform 36, build-tools 35.0.0) into " +
                join_path(home, "android") + "." + size_sentence(c.installSizeMb) +
                " You read and accept Google's Android SDK license first. Nothing else on the computer changes.";
    return a;
}

SetupAction players_action(const std::vector<std::string>& platforms, const std::string& home, bool reinstall, const std::string& label) {
    SetupAction a;
    a.component = "players";
    a.platforms = platforms;
    a.force = reinstall;
    a.label = label;
    a.key = "players";
    for (const std::string& p : platforms) a.key += "-" + p;
    a.tooltip = "Downloads the " + setup_what("players", platforms) +
                " of this FactorIA version from its GitHub release, checks them and keeps them in " + join_path(home, "players") +
                ". Exports use them without any other step.";
    return a;
}

SetupAction cmake_action(const SetupComponent& c, const std::string& home, bool reinstall) {
    SetupAction a;
    a.component = "cmake";
    a.key = "cmake";
    a.force = reinstall;
    a.label = reinstall ? "Reinstall" : "Install CMake";
    a.tooltip = std::string("Downloads CMake ") + kSetupCmakeVersion + " from Kitware into " + join_path(home, "tools/cmake") + "." +
                size_sentence(c.installSizeMb) + " The iOS export's build_ios.sh needs CMake " + kSetupCmakeMinimum + " or newer.";
    return a;
}

SetupAction xcode_action(const SetupComponent& c, bool short_label) {
    SetupAction a;
    a.component = "xcode";
    a.key = "xcode";
    const bool missing = c.state == "missing";
    a.label = missing ? (short_label ? "Open App Store" : "Open App Store (Xcode)") : (short_label ? "Show steps" : "Show Xcode steps");
    a.tooltip = missing ? "Xcode comes from the App Store and needs your Apple ID, so a program cannot install it: this opens its page and "
                          "lists the steps to finish."
                        : "Xcode is installed but not ready for iOS builds: lists what to do (some steps ask for your password, so FactorIA "
                          "does not run them).";
    return a;
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// Words

const char* setup_state_label(const std::string& state) {
    if (state == "installed") return "Installed";
    if (state == "partial") return "Partly installed";
    if (state == "missing") return "Not installed";
    if (state == "unsupported") return "Not needed here";
    return "Unknown";
}

std::string setup_size_text(int mb) {
    if (mb <= 0) return {};
    char buf[32];
    if (mb < 1000) {
        std::snprintf(buf, sizeof buf, "about %d MB", mb);
    } else {
        std::snprintf(buf, sizeof buf, "about %.1f GB", mb / 1000.0);
    }
    return buf;
}

std::string setup_what(const std::string& component, const std::vector<std::string>& platforms) {
    if (component == "android") return "Android build tools";
    if (component == "cmake") return "CMake";
    if (component == "xcode") return "Xcode";
    if (component != "players") return component;
    std::vector<std::string> desktops;
    bool mobile = false;
    for (const std::string& p : platforms) {
        if (p == "mobile") mobile = true;
        else if (*os_label(p)) desktops.push_back(os_label(p));
    }
    if (desktops.empty() && !mobile) return "players for the other platforms";
    std::string text;
    for (size_t i = 0; i < desktops.size(); ++i) text += (i == 0 ? "" : (i + 1 == desktops.size() ? " and " : ", ")) + desktops[i];
    if (!desktops.empty()) text += desktops.size() == 1 ? " player" : " players";
    if (mobile) text += std::string(text.empty() ? "" : " and ") + "mobile libraries";
    return text;
}

std::optional<int> parse_progress_percent(const std::string& line) {
    size_t end = line.size();
    while (end > 0 && (line[end - 1] == ' ' || line[end - 1] == '\t' || line[end - 1] == '\r' || line[end - 1] == '\n')) --end;
    if (end > 0 && line[end - 1] == ')') --end;
    if (end == 0 || line[end - 1] != '%') return std::nullopt;
    --end;
    size_t begin = end;
    while (begin > 0 && line[begin - 1] >= '0' && line[begin - 1] <= '9') --begin;
    if (begin == end || end - begin > 3) return std::nullopt;
    const int value = std::stoi(line.substr(begin, end - begin));
    return std::clamp(value, 0, 100);
}

// ---------------------------------------------------------------------------------------------------------------------
// What a button runs

SetupInstallOptions SetupAction::options(bool acceptLicenses) const {
    SetupInstallOptions o;
    o.component = component;
    o.acceptLicenses = acceptLicenses;
    o.platforms = platforms;
    o.force = force;
    return o;
}

std::optional<SetupAction> setup_action_for_component(const SetupComponent& c, const std::string& home) {
    if (c.state == "unsupported" || !c.canInstall) return std::nullopt;
    const bool installed = c.state == "installed";
    if (c.id == "android") {
        SetupAction a = android_action(c, home, installed);
        if (!installed) a.label = "Install";
        return a;
    }
    if (c.id == "players") {
        SetupAction a = players_action({}, home, installed, installed ? "Reinstall" : "Install");
        a.tooltip = std::string(installed ? "Downloads them again: " : "Downloads ") +
                    "the factoria_player of the other desktop systems and the Android/iOS libraries from this FactorIA version's GitHub release, "
                    "checks them and keeps them in " + join_path(home, "players") + "." + size_sentence(c.installSizeMb);
        return a;
    }
    if (c.id == "cmake") {
        SetupAction a = cmake_action(c, home, installed);
        if (!installed) a.label = "Install";
        return a;
    }
    if (c.id == "xcode") {
        if (installed) return std::nullopt;
        return xcode_action(c, true);
    }
    return std::nullopt;
}

std::vector<SetupAction> setup_actions_for_row(const std::string& platform, const ExportStatus& row, const SetupStatus& status) {
    std::vector<SetupAction> out;
    if (status.components.empty()) return out;
    const std::string& home = status.home;
    const SetupComponent* players = find_component(status, "players");
    const bool noPrebuilt = !row.ready && contains(row.error, "no prebuilt");
    auto mobile_missing = [&] { return players && players->canInstall && !has_path(*players, "mobile"); };

    if (platform == "android") {
        if (!row.ready) {
            const SetupComponent* android = find_component(status, "android");
            // The toolchain is what the export cannot find: a JDK 17+ and an Android SDK. (Licenses or packages that are only
            // missing do not stop an export from starting, so they are no reason for a button here.)
            if (android && android->canInstall && android->state != "installed" && !(has_path(*android, "jdk") && has_path(*android, "sdk")))
                out.push_back(android_action(*android, home, false));
            if (noPrebuilt && mobile_missing()) out.push_back(players_action({"mobile"}, home, false, "Download mobile libraries"));
        }
    } else if (platform == "windows" || platform == "linux" || platform == "macos") {
        if (!row.ready && export_needs_player(platform) && players && players->canInstall && !has_path(*players, "player-" + platform))
            out.push_back(players_action({platform}, home, false, std::string("Download ") + os_label(platform) + " player"));
    } else if (platform == "ios") {
        if (noPrebuilt && mobile_missing()) out.push_back(players_action({"mobile"}, home, false, "Download mobile libraries"));
        // build_ios.sh needs CMake and the Xcode project needs Xcode, ready export or not.
        if (const SetupComponent* cmake = find_component(status, "cmake"); cmake && cmake->canInstall && cmake->state == "missing") {
            out.push_back(cmake_action(*cmake, home, false));
            out.back().why = cmake->problems.empty() ? cmake->details : cmake->problems.front();
        }
        if (const SetupComponent* xcode = find_component(status, "xcode"); xcode && xcode->canInstall && xcode->state != "installed") {
            out.push_back(xcode_action(*xcode, false));
            out.back().why = xcode->details;
        }
    }
    return out;
}

// ---------------------------------------------------------------------------------------------------------------------
// One install

SetupOutcome run_setup(const SetupInstallOptions& options, const SetupContext& context) {
    SetupOutcome out;
    out.options = options;
    const auto started = std::chrono::steady_clock::now();
    try {
        SetupResult r = setup_install(options, context);
        out.ok = r.ok;
        out.report = std::move(r.report);
        out.code = r.code;
        out.error = r.error.message;
        out.hint = r.error.hint;
    } catch (const std::exception& e) {  // a bug must not take the editor down: report it like any failure
        out.ok = false;
        out.code = "failed";
        out.error = std::string("setup crashed: ") + e.what();
        out.hint = "Run `factoria setup " + options.component + "` in a terminal to see what happens, and report it.";
    }
    out.cancelled = !out.ok && out.code == "cancelled";
    out.licenseRequired = !out.ok && out.code == "license_required";
    out.seconds = out.report.seconds > 0 ? out.report.seconds : std::chrono::duration<double>(std::chrono::steady_clock::now() - started).count();
    return out;
}

std::string setup_summary(const SetupOutcome& o) {
    const std::string what = setup_what(o.options.component, o.options.platforms);
    if (o.cancelled) return "Set up " + what + " cancelled";
    if (o.licenseRequired) return "Accept the Android SDK license to install " + what;
    if (!o.ok) return "Set up " + what + " failed: " + o.error;
    if (o.options.component == "xcode") return o.report.nextSteps.empty() ? "Xcode is set up" : "Xcode: the next steps are in Set Up This Computer";
    const bool anyInstalled = std::any_of(o.report.steps.begin(), o.report.steps.end(), [](const SetupStep& s) { return s.outcome == "installed"; });
    if (!anyInstalled) return what + " was already set up";
    return "Installed " + what + " in " + duration_text(o.seconds);
}

std::string setup_report_text(const SetupOutcome& o) {
    std::string t = setup_summary(o) + "\n";
    if (!o.ok) {
        t += o.error + "\n";
        if (!o.hint.empty()) t += "How to fix it: " + o.hint + "\n";
        if (!o.code.empty()) t += "Code: " + o.code + "\n";
    }
    if (!o.report.steps.empty()) {
        t += "\nSteps:\n";
        for (const SetupStep& s : o.report.steps) {
            t += "- " + s.title + ": " + s.outcome;
            if (!s.detail.empty()) t += " (" + s.detail + ")";
            if (!s.path.empty()) t += " " + s.path;
            t += "\n";
        }
    }
    if (!o.report.paths.empty()) {
        t += "\nPaths:\n";
        for (const auto& p : o.report.paths) t += "- " + p.first + ": " + p.second + "\n";
    }
    if (!o.report.warnings.empty()) {
        t += "\nWarnings:\n";
        for (const std::string& w : o.report.warnings) t += "- " + w + "\n";
    }
    if (!o.report.nextSteps.empty()) {
        t += "\nNext steps:\n";
        for (size_t i = 0; i < o.report.nextSteps.size(); ++i) t += std::to_string(i + 1) + ". " + o.report.nextSteps[i] + "\n";
    }
    return t;
}

SetupJob::~SetupJob() {
    cancel();
    wait();
}

bool SetupJob::start(SetupInstallOptions options, SetupContext context) {
    if (running_) return false;
    wait();  // the previous install's thread has finished: join it
    {
        std::lock_guard<std::mutex> lock(mu_);
        result_.reset();
        lines_.clear();
        percent_ = -1;
        options_ = options;
    }
    cancel_.store(false);
    context.cancel = &cancel_;
    context.progress = [this, outer = std::move(context.progress)](const std::string& line) {
        add_line(line);
        if (outer) outer(line);
    };
    running_ = true;
    thread_ = std::thread([this, o = std::move(options), c = std::move(context)] {
        SetupOutcome out = run_setup(o, c);
        {
            std::lock_guard<std::mutex> lock(mu_);
            result_ = std::move(out);
        }
        running_ = false;
    });
    return true;
}

void SetupJob::add_line(const std::string& raw) {
    size_t b = 0, e = raw.size();
    while (b < e && (raw[b] == ' ' || raw[b] == '\t')) ++b;
    while (e > b && (raw[e - 1] == '\r' || raw[e - 1] == '\n' || raw[e - 1] == ' ' || raw[e - 1] == '\t')) --e;
    if (b == e) return;
    std::string line = raw.substr(b, e - b);
    const std::optional<int> percent = parse_progress_percent(line);
    std::lock_guard<std::mutex> lock(mu_);
    percent_ = percent ? *percent : -1;
    lines_.push_back(std::move(line));
    while (lines_.size() > kMaxLines) lines_.pop_front();
}

std::string SetupJob::progress_line() const {
    std::lock_guard<std::mutex> lock(mu_);
    return lines_.empty() ? std::string() : lines_.back();
}

double SetupJob::fraction() const {
    std::lock_guard<std::mutex> lock(mu_);
    return percent_ < 0 ? -1.0 : percent_ / 100.0;
}

std::vector<std::string> SetupJob::recent_lines() const {
    std::lock_guard<std::mutex> lock(mu_);
    return std::vector<std::string>(lines_.begin(), lines_.end());
}

SetupInstallOptions SetupJob::options() const {
    std::lock_guard<std::mutex> lock(mu_);
    return options_;
}

std::optional<SetupOutcome> SetupJob::take_result() {
    if (running_) return std::nullopt;
    wait();
    std::lock_guard<std::mutex> lock(mu_);
    std::optional<SetupOutcome> r = std::move(result_);
    result_.reset();
    return r;
}

void SetupJob::wait() {
    if (thread_.joinable()) thread_.join();
}

// ---------------------------------------------------------------------------------------------------------------------
// What the UI shows

bool SetupStatusCache::refresh(const SetupContext& context, double now) {
    if (job_.running()) return false;
    requestedAt_ = now;
    return job_.start([context] { return setup_status(context, "", false); });
}

bool SetupStatusCache::poll() {
    std::optional<SetupStatus> done = job_.take();
    if (!done) return false;
    status_ = std::move(*done);
    has_ = true;
    return true;
}

void SetupStatusCache::set(SetupStatus status, double now) {
    job_.wait();
    status_ = std::move(status);
    has_ = true;
    requestedAt_ = now;
}

bool SetupLicenseLoad::start(const SetupContext& context) {
    if (job_.running()) return false;
    licenses_.clear();
    error_.clear();
    state_ = State::Loading;
    return job_.start([context] { return setup_status(context, "android", true); });
}

bool SetupLicenseLoad::poll() {
    std::optional<SetupStatus> done = job_.take();
    if (!done) return false;
    const SetupComponent* android = done->find("android");
    licenses_.clear();
    error_.clear();
    if (!android) {
        state_ = State::Failed;
        error_ = "The Android component is not known by this FactorIA.";
    } else if (!android->licenses.empty()) {
        state_ = State::Ready;
        licenses_ = android->licenses;
    } else {
        // Not fetched (the licenses are accepted already) or not fetchable (the problem says why): only the second is a failure.
        const bool pending = std::any_of(android->problems.begin(), android->problems.end(),
                                         [](const std::string& p) { return contains(p, "license is not accepted yet"); });
        if (!pending) {
            state_ = State::NotNeeded;
        } else {
            state_ = State::Failed;
            for (const std::string& p : android->problems)
                if (contains(p, "Could not fetch the license")) error_ = p;
            if (error_.empty()) error_ = "The license text could not be fetched. It is also at https://developer.android.com/studio/terms.";
        }
    }
    return true;
}

void SetupLicenseLoad::reset() {
    job_.wait();
    state_ = State::Idle;
    licenses_.clear();
    error_.clear();
}

void SetupLicenseLoad::set(State state, std::vector<SetupLicense> licenses, std::string error) {
    job_.wait();
    state_ = state;
    licenses_ = std::move(licenses);
    error_ = std::move(error);
}

}  // namespace fa::editor
