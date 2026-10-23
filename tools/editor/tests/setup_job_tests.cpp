// The Set Up This Computer window's logic (setup_job.h): which setup fixes which export row, the install on a worker thread
// (progress, cancel, result), the cached status and the Android SDK license text. GPU-free and offline: every install runs
// against a fake world (a downloader that serves what the test registers and a process runner that plays tar, cmake and open)
// with a temporary FACTORIA_HOME, so nothing touches the network or the computer.
#include <algorithm>
#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <map>
#include <mutex>
#include <set>
#include <thread>

#include "doctest.h"
#include "fa/core/fs.h"
#include "fa/core/hash.h"
#include "fa/core/strings.h"
#include "fa/tooling/setup_parse.h"
#include "setup_job.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

constexpr const char* kLicenseText = "Terms and Conditions\n\nYou agree to the test license.";
constexpr const char* kCmakeBase = "https://github.com/Kitware/CMake/releases/download/v3.31.6/";
constexpr const char* kTagsUrl = "https://api.github.com/repos/OxtailGames/FactorIA/releases/tags/v0.1.3";

void put(const stdfs::path& p, const std::string& content = "x") {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << content;
}

std::string repo_xml() {
    const std::string content(500, 'T');
    return "<sdk:sdk-repository>\n<license id=\"android-sdk-license\" type=\"text\">" + std::string(kLicenseText) +
           "</license>\n<remotePackage path=\"cmdline-tools;latest\"><revision><major>23</major><minor>0</minor></revision><archives><archive><complete>"
           "<size>" + std::to_string(content.size()) + "</size><checksum type=\"sha1\">" + sha1_hex(content) +
           "</checksum><url>commandlinetools-mac_arm64-1_latest.zip</url></complete><host-os>macosx</host-os><host-arch>aarch64</host-arch>"
           "</archive></archives></remotePackage></sdk:sdk-repository>";
}

// A computer that is not this one: a temporary home, a downloader that serves what the test registers, a process runner that
// plays tar, `cmake --version` and `open`. Calls come from the worker thread, so what they record is guarded.
struct World {
    stdfs::path root, home, exeDir;
    std::map<std::string, std::string> served;  // url -> body
    std::set<std::string> blocked;               // urls whose download waits until it is cancelled
    std::mutex mu;
    std::vector<std::string> requested, ran;

    World() {
        root = fs::make_temp_dir("fa_editor_setup");
        home = root / "fhome";
        exeDir = root / "exe";
        stdfs::create_directories(exeDir);
    }
    ~World() {
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
    World(const World&) = delete;
    World& operator=(const World&) = delete;

    stdfs::path cmake_exe() const { return home / "tools" / "cmake" / "CMake.app" / "Contents" / "bin" / "cmake"; }
    stdfs::path sdk() const { return home / "android" / "sdk"; }

    void serve_cmake() {
        const std::string name = "cmake-3.31.6-macos-universal.tar.gz";
        const std::string content = "the cmake archive " + std::string(300, 'c');
        served[std::string(kCmakeBase) + "cmake-3.31.6-SHA-256.txt"] = std::string(64, 'e') + "  cmake-3.31.6-files-v1.json\n" + sha256_hex(content) + "  " + name + "\n";
        served[std::string(kCmakeBase) + name] = content;
    }

    SetupContext ctx(const std::string& host = "macos") {
        SetupContext c;
        c.env = [this](const std::string& n) {
            if (n == "HOME" || n == "USERPROFILE") return (root / "user").string();
            if (n == "FACTORIA_HOME") return home.string();
            return std::string();  // no PATH, no JAVA_HOME, no ANDROID_HOME: only the folders of this world
        };
        c.host = host;
        c.hostArch = "aarch64";
        c.engineVersion = "0.1.3";
        c.executableDir = exeDir.string();
        c.applicationsDir = (root / "apps").string();
        c.download = [this](const DownloadRequest& rq) { return download(rq); };
        c.run = [this](const ProcessOptions& o) { return run(o); };
        AndroidToolchainSearch s;
        s.env = c.env;  // never the Unity Hub or Android Studio of the computer running the tests
        s.jdk.push_back({(home / "android" / "jdk").string(), "FactorIA"});
        s.sdk.push_back({sdk().string(), "FactorIA"});
        c.toolchainSearch = s;
        return c;
    }

    DownloadResult download(const DownloadRequest& rq) {
        {
            std::lock_guard<std::mutex> lock(mu);
            requested.push_back(rq.url);
        }
        DownloadResult r;
        if (blocked.count(rq.url)) {
            if (rq.onBytes) rq.onBytes(1);
            for (int i = 0; i < 5000 && !is_cancelled(rq.cancel); ++i) std::this_thread::sleep_for(std::chrono::milliseconds(2));
            r.ok = false;
            r.cancelled = true;
            r.error = make_error("cancelled in the test");
            return r;
        }
        auto it = served.find(rq.url);
        if (it == served.end()) {
            r.ok = false;
            r.httpStatus = 404;
            r.error = make_error("not served in the test: " + rq.url, "test hint");
            return r;
        }
        put(rq.destination, it->second);
        if (rq.onBytes)
            for (std::uint64_t i = 1; i <= 100; ++i) rq.onBytes(it->second.size() * i / 100);
        return r;
    }

    Result<ProcessResult> run(const ProcessOptions& o) {
        {
            std::lock_guard<std::mutex> lock(mu);
            ran.push_back(o.argv.empty() ? std::string() : o.argv[0]);
        }
        if (o.argv.empty()) return make_error("no program in the test");
        const std::string exe = stdfs::path(o.argv[0]).filename().string();
        ProcessResult r;
        r.exitCode = 0;
        if (exe == "tar" || exe == "unzip") {
            std::string archive, dest;
            for (std::size_t i = 0; i + 1 < o.argv.size(); ++i) {
                if (o.argv[i] == "-xf" || o.argv[i] == "-xzf" || o.argv[i] == "-o") archive = o.argv[i + 1];
                if (o.argv[i] == "-C" || o.argv[i] == "-d") dest = o.argv[i + 1];
            }
            const std::string name = stdfs::path(archive).filename().string();
            if (name.rfind("cmake-", 0) != 0) return make_error("the test cannot unpack " + name);
            put(stdfs::path(dest) / name.substr(0, name.find(".tar.gz")) / "CMake.app" / "Contents" / "bin" / "cmake", "cmake");
            return r;
        }
        if (exe == "cmake") {
            if (stdfs::path(o.argv[0]) != cmake_exe()) return make_error("no cmake there in the test");
            r.stdoutText = "cmake version 3.31.6\n";
            return r;
        }
        if (exe == "open") return r;
        return make_error("the test world has no " + o.argv[0]);
    }
};

void wait_for(SetupJob& job, int seconds = 20) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(seconds);
    while (job.running() && std::chrono::steady_clock::now() < deadline) std::this_thread::sleep_for(std::chrono::milliseconds(2));
    REQUIRE_FALSE(job.running());
}

template <class T, class F>
void poll_until(T& what, F done, int seconds = 20) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(seconds);
    while (!done() && std::chrono::steady_clock::now() < deadline) {
        what.poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }
    what.poll();
}

SetupComponent component(const std::string& id, const std::string& state, bool canInstall = true,
                         std::vector<std::pair<std::string, std::string>> paths = {}) {
    SetupComponent c;
    c.id = id;
    c.title = id;
    c.state = state;
    c.canInstall = canInstall;
    c.paths = std::move(paths);
    return c;
}

// A Mac with nothing set up.
SetupStatus bare_status() {
    SetupStatus s;
    s.home = "/home/factoria";
    s.host = "macos-aarch64";
    s.components.push_back(component("android", "missing"));
    s.components.push_back(component("players", "missing"));
    s.components.push_back(component("cmake", "missing"));
    s.components.push_back(component("xcode", "missing"));
    s.components[1].installSizeMb = 60;
    s.components[2].installSizeMb = 75;
    s.components[2].problems = {"No CMake 3.24 or newer was found (PATH, Homebrew, /Applications/CMake.app)."};
    s.components[3].details = "Xcode is not installed.";
    return s;
}

SetupComponent& comp(SetupStatus& s, const std::string& id) {
    for (SetupComponent& c : s.components)
        if (c.id == id) return c;
    FAIL("no component " << id);
    return s.components.front();
}

ExportStatus not_ready(const std::string& error) {
    ExportStatus st;
    st.ready = false;
    st.error = error;
    st.hint = "a hint";
    return st;
}

ExportStatus ready_row() {
    ExportStatus st;
    st.ready = true;
    return st;
}

// A desktop platform that is not this machine's: its export needs a player built elsewhere.
std::string other_desktop() {
    for (const char* p : {"windows", "linux", "macos"})
        if (export_needs_player(p)) return p;
    return {};
}

std::string own_desktop() {
    for (const char* p : {"windows", "linux", "macos"})
        if (!export_needs_player(p)) return p;
    return {};
}

std::vector<std::string> keys(const std::vector<SetupAction>& actions) {
    std::vector<std::string> out;
    for (const SetupAction& a : actions) out.push_back(a.key);
    return out;
}

}  // namespace

TEST_CASE("setup words: states, sizes, what is installed") {
    CHECK(std::string(setup_state_label("installed")) == "Installed");
    CHECK(std::string(setup_state_label("partial")) == "Partly installed");
    CHECK(std::string(setup_state_label("missing")) == "Not installed");
    CHECK(std::string(setup_state_label("unsupported")) == "Not needed here");

    CHECK(setup_size_text(0).empty());
    CHECK(setup_size_text(75) == "about 75 MB");
    CHECK(setup_size_text(600) == "about 600 MB");
    CHECK(setup_size_text(1100) == "about 1.1 GB");

    CHECK(setup_what("android") == "Android build tools");
    CHECK(setup_what("cmake") == "CMake");
    CHECK(setup_what("xcode") == "Xcode");
    CHECK(setup_what("players", {"windows"}) == "Windows player");
    CHECK(setup_what("players", {"mobile"}) == "mobile libraries");
    CHECK(setup_what("players", {"windows", "linux"}) == "Windows and Linux players");
    CHECK(setup_what("players", {"web"}) == "web player");
    CHECK(setup_what("players", {"windows", "linux", "macos", "mobile"}) == "Windows, Linux and macOS players and mobile libraries");
    CHECK(setup_what("players") == "players for the other platforms");
}

TEST_CASE("setup progress: the percentage at the end of a line") {
    CHECK(parse_progress_percent("Downloading CMake 3.31.6: 31 MB of 75 MB (40%)") == 40);
    CHECK(parse_progress_percent("Downloading x: 75 MB of 75 MB (100%)") == 100);
    CHECK(parse_progress_percent("  12%  ") == 12);
    CHECK(parse_progress_percent("5%") == 5);
    CHECK(parse_progress_percent("Downloading CMake 3.31.6 (75 MB)...") == std::nullopt);
    CHECK(parse_progress_percent("40% of the way there") == std::nullopt);  // only a trailing percentage counts
    CHECK(parse_progress_percent("%") == std::nullopt);
    CHECK(parse_progress_percent("") == std::nullopt);
    CHECK(parse_progress_percent("Installing platform-tools, platform 36 and build-tools 35.0.0 (sdkmanager)...") == std::nullopt);
    CHECK(parse_progress_percent("a 1234% b 12345%") == std::nullopt);
}

TEST_CASE("setup action of a component: Install, Reinstall, Open App Store") {
    SetupStatus st = bare_status();
    auto android = setup_action_for_component(comp(st, "android"), st.home);
    REQUIRE(android);
    CHECK(android->label == "Install");
    CHECK_FALSE(android->force);
    CHECK(android->component == "android");
    CHECK(android->tooltip.find("license") != std::string::npos);
    CHECK(android->tooltip.find("/home/factoria") != std::string::npos);

    comp(st, "android").state = "installed";
    android = setup_action_for_component(comp(st, "android"), st.home);
    REQUIRE(android);
    CHECK(android->label == "Reinstall");
    CHECK(android->force);
    CHECK(android->options().force);
    CHECK_FALSE(android->options().acceptLicenses);  // the license is only ever accepted by the dialog
    CHECK(android->options(true).acceptLicenses);

    auto players = setup_action_for_component(comp(st, "players"), st.home);
    REQUIRE(players);
    CHECK(players->label == "Install");
    CHECK(players->platforms.empty());  // the default: every other desktop OS and the mobile libraries
    CHECK(players->tooltip.find("about 60 MB") != std::string::npos);

    auto cmake = setup_action_for_component(comp(st, "cmake"), st.home);
    REQUIRE(cmake);
    CHECK(cmake->label == "Install");
    CHECK(cmake->tooltip.find("3.31.6") != std::string::npos);

    auto xcode = setup_action_for_component(comp(st, "xcode"), st.home);
    REQUIRE(xcode);
    CHECK(xcode->label == "Open App Store");
    comp(st, "xcode").state = "partial";
    xcode = setup_action_for_component(comp(st, "xcode"), st.home);
    REQUIRE(xcode);
    CHECK(xcode->label == "Show steps");
    comp(st, "xcode").state = "installed";
    CHECK_FALSE(setup_action_for_component(comp(st, "xcode"), st.home));  // nothing to do

    comp(st, "cmake").state = "unsupported";
    comp(st, "cmake").canInstall = false;
    CHECK_FALSE(setup_action_for_component(comp(st, "cmake"), st.home));
}

TEST_CASE("setup action of an Export row: android needs its toolchain") {
    SetupStatus st = bare_status();
    const ExportStatus row = not_ready("export: cannot build the Android app on this computer: No JDK 17 or newer was found.");
    auto actions = setup_actions_for_row("android", row, st);
    REQUIRE(actions.size() == 1);
    CHECK(actions[0].label == "Install Android build tools");
    CHECK(actions[0].component == "android");
    CHECK(actions[0].key == "android");
    CHECK_FALSE(actions[0].force);

    CHECK(setup_actions_for_row("android", ready_row(), st).empty());  // ready: nothing to fix

    // A toolchain that is found (a JDK and an SDK) is not what stops this export: no button for something else.
    comp(st, "android").state = "partial";
    comp(st, "android").paths = {{"jdk", "/jdk"}, {"sdk", "/sdk"}};
    CHECK(setup_actions_for_row("android", not_ready("export: this game has no id"), st).empty());
    comp(st, "android").paths = {{"jdk", "/jdk"}};  // no SDK yet
    CHECK(keys(setup_actions_for_row("android", row, st)) == std::vector<std::string>{"android"});

    // Without prebuilt players (and no engine checkout) the mobile libraries are what is missing.
    const ExportStatus prebuilt = not_ready("export: cannot export for android: no prebuilt player (mobile/android not found) and no engine source checkout");
    comp(st, "android").paths = {{"jdk", "/jdk"}, {"sdk", "/sdk"}};
    actions = setup_actions_for_row("android", prebuilt, st);
    REQUIRE(actions.size() == 1);
    CHECK(actions[0].label == "Download mobile libraries");
    CHECK(actions[0].component == "players");
    CHECK(actions[0].platforms == std::vector<std::string>{"mobile"});
    CHECK(actions[0].key == "players-mobile");
    comp(st, "players").paths = {{"mobile", "/home/factoria/players/0.1.3/mobile"}};  // they are there already
    CHECK(setup_actions_for_row("android", prebuilt, st).empty());

    // Neither the toolchain nor the libraries: both, toolchain first.
    SetupStatus bare = bare_status();
    actions = setup_actions_for_row("android", not_ready(prebuilt.error + "; cannot build the Android app on this computer"), bare);
    CHECK(keys(actions) == std::vector<std::string>{"android", "players-mobile"});

    // An unsupported or absent component is never offered.
    comp(bare, "android").canInstall = false;
    CHECK(keys(setup_actions_for_row("android", row, bare)).empty());
    CHECK(setup_actions_for_row("android", row, SetupStatus{}).empty());
}

TEST_CASE("setup action of an Export row: another OS needs its player") {
    const std::string other = other_desktop();
    const std::string own = own_desktop();
    REQUIRE_FALSE(other.empty());
    REQUIRE_FALSE(own.empty());
    SetupStatus st = bare_status();
    const ExportStatus row = not_ready("export: cannot export for " + other + " without a player binary built for " + other);

    auto actions = setup_actions_for_row(other, row, st);
    REQUIRE(actions.size() == 1);
    const std::string os = other == "macos" ? "macOS" : (other == "windows" ? "Windows" : "Linux");
    CHECK(actions[0].label == "Download " + os + " player");
    CHECK(actions[0].component == "players");
    CHECK(actions[0].platforms == std::vector<std::string>{other});
    CHECK(actions[0].key == "players-" + other);
    CHECK(actions[0].options().platforms == std::vector<std::string>{other});

    CHECK(setup_actions_for_row(other, ready_row(), st).empty());  // a player was chosen (Choose player...): ready
    comp(st, "players").state = "partial";
    comp(st, "players").paths = {{"player-" + other, "/home/factoria/players/0.1.3/" + other + "/factoria_player"}};
    CHECK(setup_actions_for_row(other, row, st).empty());          // it is installed: the reason is another one
    comp(st, "players").paths = {{"player-" + own, "/somewhere"}};
    CHECK(keys(setup_actions_for_row(other, row, st)) == std::vector<std::string>{"players-" + other});

    // This machine's own platform has its player next to the editor: no download for it.
    CHECK(setup_actions_for_row(own, not_ready("export: factoria_player not found next to the factoria binary"), st).empty());
}

TEST_CASE("setup action of an Export row: a web row that cannot run offers the web player") {
    SetupStatus st = bare_status();
    auto actions = setup_actions_for_row("web", not_ready("export: no web player found"), st);
    REQUIRE(actions.size() == 1);
    CHECK(actions[0].label == "Download web player");
    CHECK(actions[0].component == "players");
    CHECK(actions[0].platforms == std::vector<std::string>{"web"});
    CHECK(setup_actions_for_row("web", ready_row(), st).empty());
}

TEST_CASE("setup action of an Export row: iOS shows CMake and Xcode even when the row is ready") {
    SetupStatus st = bare_status();
    auto actions = setup_actions_for_row("ios", ready_row(), st);
    REQUIRE(actions.size() == 2);
    CHECK(actions[0].label == "Install CMake");
    CHECK(actions[0].component == "cmake");
    CHECK(actions[0].why.find("No CMake") != std::string::npos);
    CHECK(actions[1].label == "Open App Store (Xcode)");
    CHECK(actions[1].component == "xcode");
    CHECK(actions[1].why == "Xcode is not installed.");

    comp(st, "cmake").state = "installed";
    comp(st, "xcode").state = "partial";
    actions = setup_actions_for_row("ios", ready_row(), st);
    REQUIRE(actions.size() == 1);
    CHECK(actions[0].label == "Show Xcode steps");

    comp(st, "xcode").state = "installed";
    CHECK(setup_actions_for_row("ios", ready_row(), st).empty());

    // Not ready for want of the libraries: they come first.
    SetupStatus bare = bare_status();
    actions = setup_actions_for_row("ios", not_ready("export: cannot export for ios: no prebuilt player (mobile/ios not found)"), bare);
    CHECK(keys(actions) == std::vector<std::string>{"players-mobile", "cmake", "xcode"});

    // Not a Mac: CMake and Xcode are not for this computer.
    SetupStatus linux_box = bare_status();
    comp(linux_box, "cmake").state = comp(linux_box, "xcode").state = "unsupported";
    comp(linux_box, "cmake").canInstall = comp(linux_box, "xcode").canInstall = false;
    CHECK(setup_actions_for_row("ios", ready_row(), linux_box).empty());

    // CMake and Xcode are only for iOS.
    CHECK(setup_actions_for_row("android", ready_row(), bare).empty());
    CHECK(setup_actions_for_row(own_desktop(), ready_row(), bare).empty());
}

TEST_CASE("setup job: an install runs on a worker with its progress, and finishes once") {
    World w;
    w.serve_cmake();
    SetupJob job;
    SetupInstallOptions opt;
    opt.component = "cmake";
    std::vector<std::string> outer;
    SetupContext ctx = w.ctx();
    std::mutex outerMu;
    ctx.progress = [&](const std::string& line) {  // the caller's own listener still gets every line
        std::lock_guard<std::mutex> lock(outerMu);
        outer.push_back(line);
    };
    CHECK_FALSE(job.take_result());  // nothing ran yet
    REQUIRE(job.start(opt, ctx));
    wait_for(job);
    auto done = job.take_result();
    REQUIRE(done);
    CHECK_MESSAGE(done->ok, done->error << " " << done->hint);
    CHECK_FALSE(done->cancelled);
    CHECK(done->options.component == "cmake");
    REQUIRE_FALSE(done->report.steps.empty());
    CHECK(done->report.steps.front().id == "cmake");
    CHECK(done->report.steps.front().outcome == "installed");
    CHECK(stdfs::exists(w.cmake_exe()));
    CHECK_FALSE(job.take_result());  // once

    const std::vector<std::string> lines = job.recent_lines();
    CHECK(std::any_of(lines.begin(), lines.end(), [](const std::string& l) { return l.find("Looking up the checksum") != std::string::npos; }));
    CHECK(std::any_of(lines.begin(), lines.end(), [](const std::string& l) { return l.find("Downloading CMake 3.31.6") != std::string::npos; }));
    {
        std::lock_guard<std::mutex> lock(outerMu);
        CHECK(outer.size() == lines.size());
    }
    CHECK(job.progress_line() == lines.back());
    CHECK(setup_summary(*done).rfind("Installed CMake in ", 0) == 0);
    const std::string text = setup_report_text(*done);
    CHECK(text.find("CMake 3.31.6: installed") != std::string::npos);
    CHECK(text.find("Next steps") != std::string::npos);

    // A second install finds it and says so; the lines start again.
    REQUIRE(job.start(opt, w.ctx()));
    wait_for(job);
    auto again = job.take_result();
    REQUIRE(again);
    CHECK(again->ok);
    CHECK(again->report.steps.front().outcome == "skipped");
    CHECK(setup_summary(*again) == "CMake was already set up");
}

TEST_CASE("setup job: lines are trimmed and capped, and a trailing percentage is the progress bar") {
    SetupJob job;
    CHECK(job.progress_line().empty());
    CHECK(job.fraction() == -1.0);
    job.add_line("   ");
    job.add_line("\r\n");
    CHECK(job.recent_lines().empty());
    job.add_line("  Downloading JDK 21 (190 MB)...  \r\n");
    CHECK(job.progress_line() == "Downloading JDK 21 (190 MB)...");
    CHECK(job.fraction() == -1.0);  // no percentage yet: a marquee
    job.add_line("Downloading JDK 21: 76 MB of 190 MB (40%)");
    CHECK(job.fraction() == doctest::Approx(0.40));
    job.add_line("Downloading JDK 21: 190 MB of 190 MB (100%)");
    CHECK(job.fraction() == doctest::Approx(1.0));
    job.add_line("Unpacking OpenJDK21U.tar.gz...");  // the next step has none
    CHECK(job.fraction() == -1.0);
    for (size_t i = 0; i < SetupJob::kMaxLines + 50; ++i) job.add_line("line " + std::to_string(i));
    const auto lines = job.recent_lines();
    CHECK(lines.size() == SetupJob::kMaxLines);
    CHECK(lines.back() == "line " + std::to_string(SetupJob::kMaxLines + 49));
    CHECK(lines.front() == "line 50");
}

TEST_CASE("setup job: Cancel stops the download and nothing is installed") {
    World w;
    const std::string name = "FactorIA-windows-x64.zip";
    w.served[kTagsUrl] = R"({"tag_name":"v0.1.3","assets":[{"name":")" + name +
                         R"(","size":1000,"browser_download_url":"https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/)" + name +
                         R"(","digest":null}]})";
    w.blocked.insert("https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/" + name);
    SetupJob job;
    SetupInstallOptions opt;
    opt.component = "players";
    opt.platforms = {"windows"};
    REQUIRE(job.start(opt, w.ctx()));
    CHECK_FALSE(job.start(opt, w.ctx()));  // one at a time
    CHECK(job.options().component == "players");
    // Wait until the download is under way.
    for (int i = 0; i < 5000 && job.progress_line().find("Downloading FactorIA") == std::string::npos; ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(2));
    REQUIRE(job.progress_line().find("Downloading FactorIA") != std::string::npos);
    CHECK(job.running());
    CHECK_FALSE(job.cancelling());
    job.cancel();
    CHECK((job.cancelling() || !job.running()));  // asked; the worker may already be done
    wait_for(job);
    CHECK_FALSE(job.cancelling());
    auto done = job.take_result();
    REQUIRE(done);
    CHECK_FALSE(done->ok);
    CHECK(done->cancelled);
    CHECK(done->code == "cancelled");
    CHECK_FALSE(done->licenseRequired);
    CHECK(setup_summary(*done) == "Set up Windows player cancelled");
    CHECK(installed_player(w.ctx(), "windows").empty());  // nothing half-installed

    // The next install starts with a clean slate (the cancel flag and the lines do not stay).
    w.blocked.clear();
    w.served.clear();
    REQUIRE(job.start(opt, w.ctx()));
    wait_for(job);
    auto next = job.take_result();
    REQUIRE(next);
    CHECK_FALSE(next->cancelled);  // it failed for another reason (nothing is served), but it was not cancelled
    CHECK(next->code != "cancelled");
}

TEST_CASE("setup job: a destructor cancels a running install instead of waiting for it") {
    World w;
    const std::string name = "FactorIA-windows-x64.zip";
    w.served[kTagsUrl] = R"({"tag_name":"v0.1.3","assets":[{"name":")" + name +
                         R"(","size":1000,"browser_download_url":"https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/)" + name +
                         R"(","digest":null}]})";
    w.blocked.insert("https://github.com/OxtailGames/FactorIA/releases/download/v0.1.3/" + name);
    const auto started = std::chrono::steady_clock::now();
    {
        SetupJob job;
        SetupInstallOptions opt;
        opt.component = "players";
        opt.platforms = {"windows"};
        REQUIRE(job.start(opt, w.ctx()));
        for (int i = 0; i < 5000 && job.progress_line().find("Downloading FactorIA") == std::string::npos; ++i)
            std::this_thread::sleep_for(std::chrono::milliseconds(2));
    }  // quitting the editor: the download is stopped
    CHECK(std::chrono::steady_clock::now() - started < std::chrono::seconds(8));
}

TEST_CASE("setup job: failures keep their code and say what to do") {
    World w;  // nothing is served: the release of this version is not there
    SetupJob job;
    SetupInstallOptions opt;
    opt.component = "players";
    opt.platforms = {"windows"};
    REQUIRE(job.start(opt, w.ctx()));
    wait_for(job);
    auto done = job.take_result();
    REQUIRE(done);
    CHECK_FALSE(done->ok);
    CHECK_FALSE(done->cancelled);
    CHECK(done->code == "no_release");
    CHECK(done->error.find("0.1.3") != std::string::npos);
    CHECK_FALSE(done->hint.empty());
    CHECK(setup_summary(*done).rfind("Set up Windows player failed: ", 0) == 0);
    const std::string text = setup_report_text(*done);
    CHECK(text.find("How to fix it: ") != std::string::npos);
    CHECK(text.find("Code: no_release") != std::string::npos);

    // An unknown component is the caller's mistake, said clearly.
    SetupInstallOptions bad;
    bad.component = "androd";
    const SetupOutcome o = run_setup(bad, w.ctx());
    CHECK_FALSE(o.ok);
    CHECK(o.code == "invalid_argument");
    CHECK(o.hint.find("android") != std::string::npos);  // did you mean
}

TEST_CASE("setup job: the Android install refuses until the license is accepted, before downloading anything") {
    World w;
    SetupInstallOptions opt;
    opt.component = "android";
    const SetupOutcome o = run_setup(opt, w.ctx());
    CHECK_FALSE(o.ok);
    CHECK(o.licenseRequired);
    CHECK_FALSE(o.cancelled);
    CHECK(o.code == "license_required");
    CHECK(setup_summary(o) == "Accept the Android SDK license to install Android build tools");
    std::lock_guard<std::mutex> lock(w.mu);
    CHECK(w.requested.empty());  // nothing was downloaded
}

TEST_CASE("setup status: every component, refreshed on a worker, downloading nothing") {
    World w;
    SetupStatusCache cache;
    CHECK_FALSE(cache.has());
    CHECK(cache.stale(100.0, 20.0));
    REQUIRE(cache.refresh(w.ctx(), 100.0));
    poll_until(cache, [&] { return cache.has(); });
    REQUIRE(cache.has());
    CHECK_FALSE(cache.refreshing());
    const SetupStatus& st = cache.status();
    CHECK(st.home == w.home.string());
    REQUIRE(st.components.size() == 8);  // android, players, cmake, xcode, the AppImage tools, sokol-shdc (no editor button for those two yet) the VS Code extension and ffmpeg
    REQUIRE(st.find("appimage") != nullptr);
    CHECK(st.find("android")->state == "missing");
    CHECK(st.find("players")->state == "missing");
    CHECK(st.find("cmake")->state == "missing");  // the fake world has no cmake
    CHECK(st.find("xcode")->state == "missing");
    CHECK(st.find("android")->canInstall);
    CHECK(st.find("android")->licenses.empty());  // the license text is not fetched by a status
    {
        std::lock_guard<std::mutex> lock(w.mu);
        CHECK(w.requested.empty());
    }
    CHECK_FALSE(cache.stale(110.0, 20.0));
    CHECK(cache.stale(130.0, 20.0));

    // After an install the next refresh sees it.
    w.serve_cmake();
    SetupInstallOptions opt;
    opt.component = "cmake";
    REQUIRE(run_setup(opt, w.ctx()).ok);
    REQUIRE(cache.refresh(w.ctx(), 140.0));
    poll_until(cache, [&] { return !cache.refreshing(); });
    CHECK(cache.status().find("cmake")->state == "installed");

    // The autotest and the tests can set the answer.
    SetupStatus fake = bare_status();
    cache.set(fake, 5000.0);
    CHECK(cache.status().home == "/home/factoria");
    CHECK_FALSE(cache.stale(5010.0, 20.0));
}

TEST_CASE("setup license: the text is loaded on a worker; accepted licenses need no dialog") {
    World w;
    SetupLicenseLoad load;
    CHECK(load.state() == SetupLicenseLoad::State::Idle);
    w.served[kSdkRepositoryUrl] = repo_xml();
    REQUIRE(load.start(w.ctx()));
    CHECK(load.loading());
    poll_until(load, [&] { return !load.loading(); });
    REQUIRE(load.state() == SetupLicenseLoad::State::Ready);
    REQUIRE(load.licenses().size() == 1);
    CHECK(load.licenses()[0].id == "android-sdk-license");
    CHECK(load.licenses()[0].text.find("You agree to the test license.") != std::string::npos);  // the full text
    load.reset();
    CHECK(load.state() == SetupLicenseLoad::State::Idle);
    CHECK(load.licenses().empty());

    // Google cannot be reached: the dialog says so and offers to try again.
    w.served.clear();
    REQUIRE(load.start(w.ctx()));
    poll_until(load, [&] { return !load.loading(); });
    CHECK(load.state() == SetupLicenseLoad::State::Failed);
    CHECK(load.error().find("Could not fetch the license") != std::string::npos);
    CHECK(load.licenses().empty());

    // The licenses are accepted already (Android Studio did it): nothing to show, the install just runs.
    put(w.sdk() / "licenses" / "android-sdk-license", "24333f8a63b6825ea9c5514f83c2829b004d1fee\n");
    REQUIRE(load.start(w.ctx()));
    poll_until(load, [&] { return !load.loading(); });
    CHECK(load.state() == SetupLicenseLoad::State::NotNeeded);
    CHECK(load.licenses().empty());

    load.set(SetupLicenseLoad::State::Ready, {SetupLicense{"android-sdk-license", "Title", "Text"}});
    CHECK(load.state() == SetupLicenseLoad::State::Ready);
    CHECK(load.licenses().front().title == "Title");
}
