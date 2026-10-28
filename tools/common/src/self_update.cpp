#include "fa/tooling/self_update.h"

#include <chrono>
#include <fstream>
#include <map>
#include <system_error>

#include "fa/core/build_info.h"

#if defined(_WIN32)
#include <windows.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#endif

namespace fa {
namespace stdfs = std::filesystem;

namespace {

stdfs::path find_executable_path() {
    std::error_code ec;
#if defined(_WIN32)
    wchar_t buf[MAX_PATH * 4];
    DWORD n = GetModuleFileNameW(nullptr, buf, DWORD(sizeof(buf) / sizeof(buf[0])));
    if (n > 0) return stdfs::path(std::wstring(buf, n));
#elif defined(__APPLE__)
    char buf[4096];
    uint32_t size = sizeof(buf);
    if (_NSGetExecutablePath(buf, &size) == 0) return stdfs::weakly_canonical(buf, ec);
#else
    stdfs::path p = stdfs::read_symlink("/proc/self/exe", ec);
    if (!ec) {
        std::string s = p.string();
        constexpr std::string_view deleted = " (deleted)";  // the file was replaced while we run
        if (s.size() > deleted.size() && s.compare(s.size() - deleted.size(), deleted.size(), deleted) == 0)
            s.resize(s.size() - deleted.size());
        return stdfs::path(s);
    }
#endif
    return {};
}

// Resolved while the process starts: before any update can have moved the file.
const bool kResolvedAtStart = (executable_path(), true);

std::mutex& extras_mutex() {
    static std::mutex m;
    return m;
}
std::map<std::string, std::function<Json()>>& extras() {
    static std::map<std::string, std::function<Json()>> m;
    return m;
}

}  // namespace

stdfs::path executable_path() {
    static const stdfs::path path = find_executable_path();
    return path;
}

std::string BuildId::label() const {
    if (empty()) return "an unidentified build";
    if (!comparable()) return version.empty() ? "an unidentified build" : version;
    if (version.empty()) return fingerprint;
    return version + " build " + fingerprint;
}

Json BuildId::to_json() const {
    Json j = Json::object();
    j["version"] = version;
    j["fingerprint"] = fingerprint;
    j["label"] = label();
    return j;
}

BuildId running_build_id() {
    (void)kResolvedAtStart;
    BuildId id;
    id.version = FA_ENGINE_VERSION;
    id.fingerprint = build_fingerprint();
    return id;
}

BuildId read_build_id(const stdfs::path& file) {
    std::ifstream in(file, std::ios::binary);
    if (!in) return {};
    constexpr std::size_t kBlock = 4u << 20;
    constexpr std::size_t kOverlap = 256;  // longer than any marker: one cut by a block boundary is whole in the next window
    BuildId id;
    std::string carry, block(kBlock, '\0');
    while (in) {
        in.read(block.data(), std::streamsize(kBlock));
        const std::size_t n = std::size_t(in.gcount());
        if (n == 0) break;
        std::string window = carry;
        window.append(block, 0, n);
        if (id.fingerprint.empty()) id.fingerprint = find_build_fingerprint(window);
        if (id.version.empty()) id.version = find_build_version(window);
        if (!id.fingerprint.empty() && !id.version.empty()) break;
        carry = window.size() > kOverlap ? window.substr(window.size() - kOverlap) : window;
    }
    return id;
}

FileStamp file_stamp(const stdfs::path& file) {
    FileStamp s;
    std::error_code ec;
    if (!stdfs::is_regular_file(file, ec)) return s;
    const auto size = stdfs::file_size(file, ec);
    if (ec) return s;
    const auto time = stdfs::last_write_time(file, ec);
    if (ec) return s;
    s.exists = true;
    s.size = size;
    s.mtime = std::int64_t(time.time_since_epoch().count());
    return s;
}

std::int64_t file_mtime_ms(const stdfs::path& file) {
    std::error_code ec;
    if (!stdfs::exists(file, ec)) return 0;
    const auto time = stdfs::last_write_time(file, ec);
    if (ec) return 0;
    // file_clock -> system_clock without clock_cast (not in every standard library yet).
    const auto sys = std::chrono::system_clock::now() + (time - stdfs::file_time_type::clock::now());
    return std::chrono::duration_cast<std::chrono::milliseconds>(sys.time_since_epoch()).count();
}

UpdateWatch::UpdateWatch(stdfs::path executable, BuildId running)
    : executable_(std::move(executable)), running_(running), onDisk_(running), examined_(file_stamp(executable_)) {}

UpdateCheck UpdateWatch::check(bool settled) {
    const FileStamp now = file_stamp(executable_);
    std::lock_guard<std::mutex> lock(mu_);
    if (now == examined_) {
        hasPending_ = false;
        return updated_ ? UpdateCheck::Updated : unidentified_ ? UpdateCheck::Unidentified : UpdateCheck::Unchanged;
    }
    if (!now.exists) {  // being replaced: the old file is renamed away before the new one is in place
        pending_ = now;
        hasPending_ = true;
        return UpdateCheck::Settling;
    }
    if (!settled && !(hasPending_ && pending_ == now)) {
        pending_ = now;
        hasPending_ = true;
        return UpdateCheck::Settling;
    }
    hasPending_ = false;
    examined_ = now;
    const BuildId id = read_build_id(executable_);
    updated_ = unidentified_ = false;
    if (!id.comparable() || !running_.comparable()) {
        unidentified_ = true;
        onDisk_ = id.empty() ? running_ : id;
        return UpdateCheck::Unidentified;
    }
    onDisk_ = id;
    if (id.fingerprint == running_.fingerprint) return UpdateCheck::Same;
    updated_ = true;
    return UpdateCheck::Updated;
}

bool UpdateWatch::updated() const {
    std::lock_guard<std::mutex> lock(mu_);
    return updated_;
}
BuildId UpdateWatch::running() const {
    std::lock_guard<std::mutex> lock(mu_);
    return running_;
}
BuildId UpdateWatch::on_disk() const {
    std::lock_guard<std::mutex> lock(mu_);
    return onDisk_;
}
FileStamp UpdateWatch::examined_stamp() const {
    std::lock_guard<std::mutex> lock(mu_);
    return examined_;
}

UpdateWatch& process_update_watch() {
    static UpdateWatch watch(executable_path(), running_build_id());
    return watch;
}

namespace {
// Created while the process starts: the stamp it compares with must be the one of the file that was started, not of whatever is
// there when something first asks.
[[maybe_unused]] const UpdateWatch& gStartWatch = process_update_watch();
}  // namespace

void set_update_status_extra(std::string key, std::function<Json()> provider) {
    std::lock_guard<std::mutex> lock(extras_mutex());
    if (provider) extras()[std::move(key)] = std::move(provider);
    else extras().erase(key);
}

Json update_status_json(UpdateWatch& watch) {
    const UpdateCheck c = watch.check(true);
    Json j = Json::object();
    j["running"] = watch.running().to_json();
    j["onDisk"] = watch.on_disk().to_json();
    const bool due = watch.updated();
    j["restartDue"] = due;
    j["state"] = due ? "updated_on_disk" : c == UpdateCheck::Unidentified ? "unidentified" : c == UpdateCheck::Settling ? "settling" : "current";
    j["executable"] = watch.executable().generic_string();
    std::string summary;
    if (due)
        summary = "FactorIA was updated on disk (" + watch.running().label() + " -> " + watch.on_disk().label() +
                  "); this process still runs the old code.";
    else if (c == UpdateCheck::Unidentified)
        summary = "The executable on disk changed but carries no build identity that can be compared with the running one "
                  "(a build outside git has none): nothing is assumed.";
    else if (c == UpdateCheck::Settling) summary = "The executable on disk is being written right now: ask again in a moment.";
    else summary = "The executable on disk is the build that runs (" + watch.running().label() + "); nothing to restart.";
    j["summary"] = summary;
    std::map<std::string, std::function<Json()>> copy;
    {
        std::lock_guard<std::mutex> lock(extras_mutex());
        copy = extras();
    }
    for (const auto& [key, provider] : copy) j[key] = provider();
    return j;
}

void register_update_commands(CommandRegistry& registry) {
    CommandInfo info;
    info.name = "engine.update_status";
    info.category = "engine";
    info.readOnly = true;
    info.summary = "Tell whether FactorIA was updated on disk while this process runs, and so whether a restart is due.";
    info.description =
        "Returns {running, onDisk, restartDue, state, executable, summary, ...}: `running` and `onDisk` are {version, "
        "fingerprint, label}: the build this process was started from and the one now in the `factoria` file it was started "
        "from (the build fingerprint written inside the file, not just its date). state: current | updated_on_disk | "
        "unidentified (the file changed but has no comparable identity) | settling (it is being written). When "
        "`restartDue`, what to do depends on the host: in the editor (`editor` is present) the user presses Restart in the "
        "notice; under `factoria mcp` (`mcp` is present) the server restarts itself between two calls on Linux and macOS and "
        "says so in the next tool result, on Windows the client must reconnect the factoria server (Claude Code: /mcp). "
        "`mcp.projectConfig` says whether the client was started with the .mcp.json now on disk. Details: "
        "docs_read {\"name\":\"mcp\"}. Example: {}.";
    info.inputSchema = Json::parse(R"({"type":"object","properties":{}})");
    registry.add(info, [](const Json&) { return update_status_json(process_update_watch()); });
}

}  // namespace fa
