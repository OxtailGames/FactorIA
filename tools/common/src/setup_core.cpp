// The mechanics every installer of `factoria setup` uses: downloading with curl, checksums, unpacking, moving a folder
// into place, and the bookkeeping of one install.
#include <algorithm>
#include <atomic>
#include <cstdlib>
#include <format>
#include <thread>

#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "setup_internal.h"
#include "util.h"

#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

namespace fa {

namespace stdfs = std::filesystem;

namespace {

int process_id() {
#if defined(_WIN32)
    return _getpid();
#else
    return int(::getpid());
#endif
}

std::string url_host(const std::string& url) {
    const std::size_t at = url.find("://");
    if (at == std::string::npos) return url;
    const std::size_t end = url.find('/', at + 3);
    return url.substr(at + 3, end == std::string::npos ? std::string::npos : end - at - 3);
}

std::string first_line(const std::string& text) {
    const std::string_view t = trim(text);
    const std::size_t nl = t.find('\n');
    return std::string(t.substr(0, nl));
}

// The HTTP status of "curl: (22) The requested URL returned error: 404", or 0.
int http_status_of(const std::string& curlStderr) {
    const std::string marker = "returned error: ";
    const std::size_t at = curlStderr.find(marker);
    if (at == std::string::npos) return 0;
    return std::atoi(curlStderr.c_str() + at + marker.size());
}

Error curl_failure(int exitCode, const std::string& stderrText, const std::string& what, const std::string& url, int& httpStatus) {
    const std::string host = url_host(url);
    const std::string prefix = "Downloading " + what + " failed: ";
    const std::string network = "Check the internet connection (behind a proxy, set HTTPS_PROXY), then run it again; a download that was cut off starts over.";
    // An HTTP error status is in the text whatever the exit code is: curl 8 with --retry reports 56 where older versions say 22.
    httpStatus = http_status_of(stderrText);
    if (httpStatus != 0 || exitCode == 22) {
        std::string message = prefix + "the server answered HTTP " + (httpStatus ? std::to_string(httpStatus) : "an error") + " for " + url + ".";
        std::string hint = "Try again later.";
        if (httpStatus == 404) hint = "The file is not there (anymore). Update FactorIA, then run it again.";
        else if ((httpStatus == 403 || httpStatus == 429) && url.find("api.github.com") != std::string::npos)
            hint = "GitHub allows only 60 anonymous requests an hour per network address; try again later or from another network.";
        return make_error(message, hint);
    }
    switch (exitCode) {
        case 6: return make_error(prefix + "cannot resolve the address " + host + ".", network);
        case 7: return make_error(prefix + "cannot connect to " + host + ".", network);
        case 28: return make_error(prefix + "the connection to " + host + " timed out or stalled.", network);
        case 56:
        case 52:
        case 18: return make_error(prefix + "the connection to " + host + " broke off.", network);
        case 23: return make_error(prefix + "cannot write the file.", "Check the free disk space and that the folder is writable.");
        case 35: case 51: case 53: case 54: case 58: case 59: case 60: case 77: case 83: case 90: case 91:
            return make_error(prefix + "the secure connection to " + host + " failed (" + first_line(stderrText) + ").",
                              "Check the computer's date and time, and a proxy or antivirus that intercepts HTTPS.");
        default: break;
    }
    std::string detail = first_line(stderrText);
    return make_error(prefix + "curl exited with code " + std::to_string(exitCode) + (detail.empty() ? "." : ": " + detail), network);
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------
// curl
// ---------------------------------------------------------------------------------------------------------------

Downloader curl_downloader(ProcessRunner run) {
    if (!run) run = [](const ProcessOptions& o) { return fa::run_process(o); };
    return [run = std::move(run)](const DownloadRequest& rq) -> DownloadResult {
        DownloadResult out;
        auto fail = [&](Error e) {
            out.ok = false;
            out.error = std::move(e);
            return out;
        };
        const std::string what = rq.what.empty() ? rq.url : rq.what;
        std::string curl = which("curl");
#if defined(_WIN32)
        if (curl.empty()) {
            const char* root = std::getenv("SystemRoot");
            const stdfs::path candidate = stdfs::path(root ? root : "C:\\Windows") / "System32" / "curl.exe";
            std::error_code ec;
            if (stdfs::is_regular_file(candidate, ec)) curl = candidate.string();
        }
#endif
        if (curl.empty())
            return fail(make_error("Cannot download " + what + ": the 'curl' program was not found.",
                                   "curl comes with macOS, Windows 10 and later and most Linux systems; on Linux install it "
                                   "(sudo apt install curl, sudo dnf install curl)."));
        const stdfs::path dest(rq.destination);
        stdfs::path part = dest;
        part += ".part";
        std::error_code ec;
        stdfs::create_directories(dest.parent_path(), ec);
        stdfs::remove(part, ec);

        ProcessOptions po;
        po.argv = {curl, "-fL", "-sS", "--retry", "3", "--connect-timeout", "30", "--proto-redir", "=https",
                   "--speed-limit", "1024", "--speed-time", "60"};
        for (const std::string& h : rq.headers) {
            po.argv.push_back("-H");
            po.argv.push_back(h);
        }
        po.argv.insert(po.argv.end(), {"-o", part.string(), rq.url});
        po.captureStdout = false;
        po.cancel = rq.cancel;

        std::atomic<bool> done{false};
        std::thread poller;
        if (rq.onBytes) {
            poller = std::thread([&] {
                std::uint64_t last = ~std::uint64_t(0);
                while (!done.load()) {
                    std::error_code pec;
                    const std::uint64_t size = stdfs::file_size(part, pec);
                    if (!pec && size != last) {
                        last = size;
                        rq.onBytes(size);
                    }
                    for (int i = 0; i < 10 && !done.load(); ++i) std::this_thread::sleep_for(std::chrono::milliseconds(50));
                }
            });
        }
        auto r = run(po);
        done = true;
        if (poller.joinable()) poller.join();

        if (!r.ok()) {
            stdfs::remove(part, ec);
            return fail(make_error("Cannot download " + what + ": " + r.error().message, r.error().hint));
        }
        if (r->cancelled || is_cancelled(rq.cancel)) {
            stdfs::remove(part, ec);
            out.cancelled = true;
            return fail(make_error("Downloading " + what + " was cancelled.", "Run it again to start over."));
        }
        if (r->exitCode != 0) {
            stdfs::remove(part, ec);
            Error e = curl_failure(r->exitCode, r->stderrText, what, rq.url, out.httpStatus);
            return fail(std::move(e));
        }
        if (!stdfs::is_regular_file(part, ec))
            return fail(make_error("Downloading " + what + " finished but curl wrote no file at " + part.string() + ".",
                                   "Check that the folder is writable."));
        stdfs::remove(dest, ec);
        stdfs::rename(part, dest, ec);
        if (ec)
            return fail(make_error("Cannot move the downloaded file into place (" + dest.string() + "): " + ec.message(),
                                   "Check the free disk space and that the folder is writable."));
        return out;
    };
}

// ---------------------------------------------------------------------------------------------------------------
// SetupContext defaults
// ---------------------------------------------------------------------------------------------------------------

namespace {

std::string native_host() {
#if defined(_WIN32)
    return "windows";
#elif defined(__APPLE__)
    return "macos";
#else
    return "linux";
#endif
}

std::string native_arch() {
#if defined(__aarch64__) || defined(_M_ARM64)
    return "aarch64";
#else
    return "x64";
#endif
}

}  // namespace

std::string SetupContext::home_dir() const { return home.empty() ? factoria_home(env) : home; }
std::string SetupContext::host_os() const { return host.empty() ? native_host() : host; }
std::string SetupContext::host_architecture() const { return hostArch.empty() ? native_arch() : hostArch; }
std::string SetupContext::version() const {
    if (!engineVersion.empty()) return engineVersion;
#ifdef FA_ENGINE_VERSION
    return FA_ENGINE_VERSION;
#else
    return "0.0.0";
#endif
}
std::string SetupContext::config_path() const { return machineConfigPath.empty() ? machine_export_config_path(env) : machineConfigPath; }
AndroidToolchainSearch SetupContext::search() const {
    return toolchainSearch ? *toolchainSearch : default_android_toolchain_search(env);
}
DownloadResult SetupContext::fetch(const DownloadRequest& request) const {
    DownloadRequest rq = request;
    if (!rq.cancel) rq.cancel = cancel;
    return download ? download(rq) : curl_downloader(run)(rq);
}
Result<ProcessResult> SetupContext::run_process_with(const ProcessOptions& options) const {
    ProcessOptions po = options;
    if (!po.cancel) po.cancel = cancel;
    return run ? run(po) : fa::run_process(po);
}

}  // namespace fa

namespace fa::setup_detail {

std::string format_bytes(std::uint64_t bytes) {
    if (bytes >= (1ull << 30)) return std::format("{:.1f} GB", double(bytes) / double(1ull << 30));
    if (bytes >= (1ull << 20)) return std::format("{:.0f} MB", double(bytes) / double(1ull << 20));
    if (bytes >= 1024) return std::format("{:.0f} KB", double(bytes) / 1024.0);
    return std::to_string(bytes) + " bytes";
}

int megabytes(std::uint64_t bytes) { return int((bytes + (1ull << 20) - 1) >> 20); }

bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(p, ec);
}

bool is_dir(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(p, ec);
}

// ---- the install bookkeeping ---------------------------------------------------------------------------------------

Installer::Installer(const SetupContext& context, std::string component)
    : ctx(context), staging_(stdfs::path(context.home_dir()) / "staging" / component), start_(std::chrono::steady_clock::now()) {
    report.component = std::move(component);
}

Installer::~Installer() {
    if (!staged_) return;
    std::error_code ec;
    stdfs::remove_all(staging_, ec);
    stdfs::remove(staging_.parent_path(), ec);  // the staging folder itself, when nothing else is in it
}

stdfs::path Installer::staging() {
    if (!staged_) {
        std::error_code ec;
        stdfs::remove_all(staging_, ec);  // what a crashed run left behind
        stdfs::create_directories(staging_, ec);
        staged_ = true;
    }
    return staging_;
}

stdfs::path Installer::make_staging_subdir(const std::string& name) {
    const stdfs::path dir = staging() / name;
    std::error_code ec;
    stdfs::remove_all(dir, ec);
    stdfs::create_directories(dir, ec);
    return dir;
}

double Installer::elapsed() const { return std::chrono::duration<double>(std::chrono::steady_clock::now() - start_).count(); }

void Installer::add_step(SetupStep step) {
    if (step.outcome == "installed") report.changed = true;
    report.steps.push_back(std::move(step));
}

SetupResult Installer::fail(const Fail& f) { return fail(f.code, f.error); }

SetupResult Installer::fail(std::string code, Error error) {
    SetupResult r;
    r.ok = false;
    report.seconds = elapsed();
    r.report = std::move(report);
    r.code = std::move(code);
    r.error = std::move(error);
    return r;
}

SetupResult Installer::finish() {
    SetupResult r;
    r.ok = true;
    report.seconds = elapsed();
    r.report = std::move(report);
    return r;
}

// ---- network ---------------------------------------------------------------------------------------------------------

std::optional<Fail> download_file(const SetupContext& ctx, const std::string& url, const stdfs::path& destination,
                                  const std::string& what, std::uint64_t expectedBytes, std::uint64_t* bytes,
                                  const std::vector<std::string>& headers) {
    DownloadRequest rq;
    rq.url = url;
    rq.destination = destination.string();
    rq.headers = headers;
    rq.expectedBytes = expectedBytes;
    rq.what = what;
    ctx.say("Downloading " + what + (expectedBytes ? " (" + format_bytes(expectedBytes) + ")" : std::string()) + "...");
    auto lastBucket = std::make_shared<std::atomic<long>>(0);
    rq.onBytes = [&ctx, what, expectedBytes, lastBucket](std::uint64_t got) {
        const long bucket = expectedBytes ? long(got * 10 / expectedBytes) : long(got / (25ull << 20));
        long seen = lastBucket->load();
        if (bucket <= seen || !lastBucket->compare_exchange_strong(seen, bucket)) return;
        ctx.say("Downloading " + what + ": " + format_bytes(got) +
                (expectedBytes ? " of " + format_bytes(expectedBytes) + " (" + std::to_string(std::min<std::uint64_t>(100, got * 100 / expectedBytes)) + "%)" : std::string()));
    };
    const DownloadResult r = ctx.fetch(rq);
    if (!r.ok) return Fail{r.cancelled || is_cancelled(ctx.cancel) ? "cancelled" : "network", r.error};
    if (bytes) {
        std::error_code ec;
        *bytes = stdfs::file_size(destination, ec);
        if (ec) *bytes = 0;
    }
    return std::nullopt;
}

std::optional<Fail> fetch_text(const SetupContext& ctx, const std::string& url, const std::string& what, const stdfs::path& scratch,
                               std::string& out, int* httpStatus, const std::vector<std::string>& headers) {
    static std::atomic<int> counter{0};
    const stdfs::path file = scratch / ("fetch-" + std::to_string(process_id()) + "-" + std::to_string(++counter) + ".txt");
    DownloadRequest rq;
    rq.url = url;
    rq.destination = file.string();
    rq.headers = headers;
    rq.what = what;
    const DownloadResult r = ctx.fetch(rq);
    if (httpStatus) *httpStatus = r.httpStatus;
    if (!r.ok) return Fail{r.cancelled || is_cancelled(ctx.cancel) ? "cancelled" : "network", r.error};
    auto text = tooling_detail::read_file(file);
    std::error_code ec;
    stdfs::remove(file, ec);
    if (!text) return Fail{"failed", make_error("Cannot read what was downloaded for " + what + ".", "Check the free disk space and try again.")};
    out = std::move(*text);
    return std::nullopt;
}

std::optional<Fail> verify_checksum(const stdfs::path& file, const std::string& type, const std::string& expected, const std::string& what) {
    if (type != "sha1" && type != "sha256")
        return Fail{"failed", make_error("Unknown checksum type '" + type + "' for " + what + ".", "This is a bug in FactorIA; please report it.")};
    auto actual = type == "sha1" ? sha1_file_hex(file) : sha256_file_hex(file);
    if (!actual.ok()) return Fail{"failed", actual.error()};
    if (to_lower(*actual) != to_lower(expected))
        return Fail{"checksum_mismatch",
                    make_error("The download of " + what + " is damaged or was changed on the way: its " + type + " is " + *actual + " but the publisher lists " + expected + ".",
                               "Nothing was installed. Run it again; if it keeps failing, check for a proxy or antivirus that rewrites downloads.")};
    return std::nullopt;
}

// ---- files ----------------------------------------------------------------------------------------------------------

std::optional<Fail> extract_archive(const SetupContext& ctx, const stdfs::path& archive, const stdfs::path& destination) {
    std::error_code ec;
    stdfs::create_directories(destination, ec);
    const std::string name = to_lower(archive.filename().string());
    const bool zip = ends_with(name, ".zip");
    const bool tarball = ends_with(name, ".tar.gz") || ends_with(name, ".tgz");
    if (!zip && !tarball)
        return Fail{"failed", make_error("Cannot unpack " + archive.filename().string() + ": only .zip and .tar.gz archives are supported.", "This is a bug in FactorIA; please report it.")};
    const std::string os = ctx.host_os();
    ProcessOptions po;
    if (os == "linux") {
        if (zip) {
            const std::string unzip = which("unzip");
            if (unzip.empty())
                return Fail{"failed", make_error("Cannot unpack " + archive.filename().string() + ": the 'unzip' program is missing.",
                                                 "Install it (sudo apt install unzip, sudo dnf install unzip) and run the setup again.")};
            po.argv = {unzip, "-q", "-o", archive.string(), "-d", destination.string()};
        } else {
            po.argv = {"tar", "--no-same-owner", "-xzf", archive.string(), "-C", destination.string()};
        }
    } else if (os == "macos") {
        // bsdtar reads .zip and .tar.gz alike; the system one, not whatever tar a PATH has first.
        po.argv = {is_file("/usr/bin/tar") ? "/usr/bin/tar" : "tar", "-xf", archive.string(), "-C", destination.string()};
    } else {
        const char* root = std::getenv("SystemRoot");
        stdfs::path tar = stdfs::path(root ? root : "C:\\Windows") / "System32" / "tar.exe";
        po.argv = {is_file(tar) ? tar.string() : std::string("tar"), "-xf", archive.string(), "-C", destination.string()};
    }
    ctx.say("Unpacking " + archive.filename().string() + "...");
    auto r = ctx.run_process_with(po);
    if (!r.ok())
        return Fail{"failed", make_error("Cannot unpack " + archive.filename().string() + ": " + r.error().message,
                                         r.error().hint.empty() ? "Check that the archive tool of this system works." : r.error().hint)};
    if (r->cancelled || is_cancelled(ctx.cancel)) return Fail{"cancelled", make_error("Unpacking " + archive.filename().string() + " was cancelled.")};
    if (r->exitCode != 0) {
        std::string detail = first_line(r->stderrText);
        return Fail{"failed", make_error("Cannot unpack " + archive.filename().string() + ": " + po.argv[0] + " exited with code " + std::to_string(r->exitCode) +
                                             (detail.empty() ? "." : ": " + detail),
                                         "The download may be damaged, or the disk is full: run it again.")};
    }
    return std::nullopt;
}

std::optional<Fail> replace_dir(const stdfs::path& from, const stdfs::path& to) {
    static std::atomic<int> counter{0};
    std::error_code ec;
    stdfs::create_directories(to.parent_path(), ec);
    stdfs::path aside;
    if (stdfs::exists(to, ec)) {
        aside = to;
        aside += ".old-" + std::to_string(process_id()) + "-" + std::to_string(++counter);
        stdfs::rename(to, aside, ec);
        if (ec)
            return Fail{"failed", make_error("Cannot replace " + to.string() + ": " + ec.message(),
                                             "Close the programs that use files in that folder (a build, an editor) and run it again.")};
    }
    stdfs::rename(from, to, ec);
    if (ec) {
        const std::string message = ec.message();
        if (!aside.empty()) stdfs::rename(aside, to, ec);
        return Fail{"failed", make_error("Cannot move " + from.string() + " to " + to.string() + ": " + message,
                                         "Check the free disk space and that the folder is writable.")};
    }
    if (!aside.empty()) stdfs::remove_all(aside, ec);
    return std::nullopt;
}

stdfs::path single_child_dir(const stdfs::path& root) {
    std::error_code ec;
    stdfs::path only;
    int count = 0;
    for (const auto& entry : stdfs::directory_iterator(root, ec)) {
        ++count;
        only = entry.path();
    }
    if (count == 1 && is_dir(only)) return only;
    return root;
}

void make_executable(const stdfs::path& file) {
#if !defined(_WIN32)
    std::error_code ec;
    stdfs::permissions(file, stdfs::perms::owner_exec | stdfs::perms::group_exec | stdfs::perms::others_exec, stdfs::perm_options::add, ec);
#else
    (void)file;
#endif
}

void make_tree_executable(const stdfs::path& dir) {
    std::error_code ec;
    for (stdfs::recursive_directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec))
        if (it->is_regular_file(ec)) make_executable(it->path());
}

}  // namespace fa::setup_detail
