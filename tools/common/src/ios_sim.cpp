// player.run_ios_sim: install an iOS Simulator build of the player, start it with an input replay and an orientation, wait for
// "replay done", take a screenshot and stop it. Needs a Mac with Xcode (xcrun simctl); with dryRun it only returns the steps.
#include "fa/tooling/ios_sim.h"

#include <atomic>
#include <chrono>
#include <thread>

#include "fa/core/log.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/tooling/project_fs.h"
#include "plist_read.h"
#include "util.h"

namespace fa {
namespace {

namespace stdfs = std::filesystem;
using tooling_detail::arg_bool;
using tooling_detail::arg_int;
using tooling_detail::arg_string;

std::string generic(const stdfs::path& p) { return p.generic_string(); }

[[noreturn]] void fail(const std::string& what, const std::string& hint) { throw CommandError("failed", what, hint); }

// The simulator to use: `want` is a UDID or a name ("iPad Pro 13-inch (M5)", or a part of it); empty = a booted iPhone, else the
// first iPhone of the newest iOS runtime. Returns {udid, name}.
std::pair<std::string, std::string> pick_device(const Json& list, const std::string& want) {
    struct Dev {
        std::string udid, name, runtime;
        bool booted;
        std::vector<int> version;
    };
    std::vector<Dev> all;
    for (auto rt = list["devices"].begin(); rt != list["devices"].end(); ++rt) {
        const std::string key = rt.key();
        if (key.find(".iOS-") == std::string::npos) continue;
        std::vector<int> version;
        for (const std::string& part : split(key.substr(key.rfind(".iOS-") + 5), '-'))
            if (!part.empty() && std::isdigit(static_cast<unsigned char>(part[0]))) version.push_back(std::atoi(part.c_str()));
        for (const Json& d : *rt) {
            if (!d.value("isAvailable", true)) continue;
            all.push_back({d.value("udid", ""), d.value("name", ""), key, d.value("state", "") == "Booted", version});
        }
    }
    std::stable_sort(all.begin(), all.end(), [](const Dev& a, const Dev& b) { return a.version > b.version; });
    if (!want.empty()) {
        const std::string lw = to_lower(want);
        for (const Dev& d : all)
            if (d.udid == want || to_lower(d.name) == lw) return {d.udid, d.name};
        for (const Dev& d : all)
            if (to_lower(d.name).find(lw) != std::string::npos) return {d.udid, d.name};
        std::vector<std::string> names;
        for (const Dev& d : all) names.push_back(d.name);
        fail("No available iOS simulator matches '" + want + "'.",
             "Available: " + join(names, ", ") + ". Add one in Xcode (Settings > Components); `xcrun simctl list devices available` lists them.");
    }
    for (const Dev& d : all)
        if (d.booted && d.name.rfind("iPhone", 0) == 0) return {d.udid, d.name};
    for (const Dev& d : all)
        if (d.name.rfind("iPhone", 0) == 0) return {d.udid, d.name};
    fail("No iPhone simulator is installed.", "Add one in Xcode (Settings > Components), or name an iPad with \"device\".");
}

std::string simctl_fail_text(const ProcessResult& r) {
    std::string t = r.stderrText.empty() ? r.stdoutText : r.stderrText;
    return t.size() > 600 ? t.substr(0, 600) : t;
}

Json run_ios_sim(const std::string& projectDir, const Json& args) {
    const bool dryRun = arg_bool(args, "dryRun", false);
    const std::string appArg = arg_string(args, "app", true);
    const std::string orientation = arg_string(args, "orientation", false);
    if (!orientation.empty() && orientation != "portrait" && orientation != "landscape")
        throw CommandError("invalid_argument", "orientation must be \"portrait\" or \"landscape\", not '" + orientation + "'.",
                           did_you_mean(orientation, std::vector<std::string>{"portrait", "landscape"}));
    const long seconds = arg_int(args, "seconds", 90);
    if (seconds < 5 || seconds > 3600) throw CommandError("invalid_argument", "seconds must be between 5 and 3600.", "It is how long to wait for the replay to finish.");

    // The app: the Simulator build of the player (./build_ios.sh --simulator leaves build/.../Debug-iphonesimulator/factoria_player.app).
    stdfs::path app = stdfs::path(appArg).is_absolute() ? stdfs::path(appArg) : stdfs::path(projectDir) / appArg;
    if (!stdfs::is_directory(app) || app.extension() != ".app")
        fail("'" + generic(app) + "' is not an app bundle (a folder ending in .app).",
             "Build the iOS Simulator app first: `factoria export --platform ios`, then ./build_ios.sh --simulator in the export folder; the app is "
             "factoria_player.app under its build/ folder (a Debug-iphonesimulator folder).");
    std::string bundleId = arg_string(args, "bundleId", false);
    if (bundleId.empty()) {
        auto plist = tooling_detail::read_file(app / "Info.plist");
        auto parsed = plist ? tooling_detail::parse_xml_plist(*plist) : Result<Json>(make_error("no Info.plist"));
        if (parsed.ok() && parsed.value().is_object() && parsed.value().value("CFBundleIdentifier", "") != "")
            bundleId = parsed.value()["CFBundleIdentifier"].get<std::string>();
        else
            fail("Cannot read the bundle id from " + generic(app / "Info.plist") + ".", "Pass it as \"bundleId\" (the game's id in factoria.json).");
    }

    // The replay: the file the simulator's player reads from the Mac's disk (a simulator app sees the host's files).
    std::string replay;
    if (std::string in = arg_string(args, "input", false); !in.empty()) {
        stdfs::path p = stdfs::path(in).is_absolute() ? stdfs::path(in) : stdfs::path(projectDir) / in;
        if (!stdfs::is_regular_file(p) && !stdfs::is_regular_file(stdfs::current_path() / in))
            fail("The input replay '" + in + "' does not exist (looked in the project folder " + projectDir + " and the current folder).",
                 "Record one with the input.record command (docs/DEBUGGING.md) or `factoria run --record-input`.");
        if (!stdfs::is_regular_file(p)) p = stdfs::current_path() / in;
        replay = stdfs::weakly_canonical(p).generic_string();
    }
    std::string shot = arg_string(args, "screenshot", false);
    if (!shot.empty() && !stdfs::path(shot).is_absolute()) {
        auto r = resolve_project_path(projectDir, shot);
        if (!r) throw CommandError("invalid_argument", r.error().message, r.error().hint);
        shot = r->generic_string();
    }
    const std::string device = arg_string(args, "device", false);
    const double settle = std::max(0L, arg_int(args, "settleMilliseconds", 1500)) / 1000.0;

    Json report = Json::object();
    report["app"] = generic(app);
    report["bundleId"] = bundleId;
    report["input"] = replay.empty() ? Json(nullptr) : Json(replay);
    report["orientation"] = orientation.empty() ? Json(nullptr) : Json(orientation);

    auto list_steps = [&](const std::string& udid) {
        Json steps = Json::array();
        auto add = [&](std::initializer_list<std::string> argv, const std::string& env = {}) {
            std::string s = env;
            for (const std::string& a : argv) s += (s.empty() ? "" : " ") + a;
            steps.push_back(s);
        };
        std::string env;
        if (!replay.empty()) env += "SIMCTL_CHILD_FA_INPUT_REPLAY=" + replay;
        if (!orientation.empty()) env += std::string(env.empty() ? "" : " ") + "SIMCTL_CHILD_FA_ORIENTATION=" + orientation;
        add({"xcrun", "simctl", "boot", udid});
        add({"xcrun", "simctl", "bootstatus", udid, "-b"});
        add({"xcrun", "simctl", "install", udid, generic(app)});
        add({"xcrun", "simctl", "launch", "--terminate-running-process", "--console-pty", udid, bundleId}, env);
        if (!shot.empty()) add({"xcrun", "simctl", "io", udid, "screenshot", shot});
        add({"xcrun", "simctl", "terminate", udid, bundleId});
        return steps;
    };
    if (dryRun) {
        report["dryRun"] = true;
        report["device"] = device.empty() ? "<the booted iPhone, else the first iPhone of the newest iOS runtime>" : device;
        report["steps"] = list_steps(device.empty() ? "<udid>" : device);
        return report;
    }

#if !defined(__APPLE__)
    fail("player.run_ios_sim needs a Mac with Xcode: the iOS Simulator runs only there.",
         "Run it on macOS, or use dryRun to see the simctl commands. On Android the same check is `adb`-based (docs/MOBILE.md).");
#else
    auto simctl = [&](std::vector<std::string> argv, double timeout, const std::map<std::string, std::string>& env = {}) {
        ProcessOptions po;
        po.argv = {"xcrun", "simctl"};
        po.argv.insert(po.argv.end(), argv.begin(), argv.end());
        po.env = env;
        po.timeoutSeconds = timeout;
        auto r = run_process(po);
        if (!r.ok()) fail("Cannot run xcrun simctl: " + r.error().message, "Install Xcode and run `xcode-select --install`; `xcrun simctl help` must work.");
        return std::move(r.value());
    };
    ProcessResult listed = simctl({"list", "devices", "available", "-j"}, 60);
    Json devices = Json::parse(listed.stdoutText, nullptr, false);
    if (listed.exitCode != 0 || !devices.is_object() || !devices.contains("devices"))
        fail("`xcrun simctl list` failed: " + simctl_fail_text(listed), "Is Xcode installed and its license accepted (sudo xcodebuild -license accept)?");
    auto [udid, deviceName] = pick_device(devices, device);
    report["device"] = udid;
    report["deviceName"] = deviceName;

    if (ProcessResult b = simctl({"boot", udid}, 120); b.exitCode != 0 && b.stderrText.find("current state: Booted") == std::string::npos)
        fail("Cannot boot " + deviceName + ": " + simctl_fail_text(b), "Open Simulator once, or pick another \"device\".");
    if (ProcessResult b = simctl({"bootstatus", udid, "-b"}, 600); b.exitCode != 0)
        fail(deviceName + " did not finish booting: " + simctl_fail_text(b), "Try again, or erase it: xcrun simctl erase " + udid);
    if (ProcessResult i = simctl({"install", udid, generic(app)}, 300); i.exitCode != 0)
        fail("Cannot install the app on " + deviceName + ": " + simctl_fail_text(i),
             "The app must be built for the Simulator (./build_ios.sh --simulator), not for a device, and signed ad hoc (codesign --force --sign - <app>).");

    // Launch with the console: the player logs "player: replaying ..." and "player: replay done after N frames".
    std::map<std::string, std::string> env;
    if (!replay.empty()) env["SIMCTL_CHILD_FA_INPUT_REPLAY"] = replay;
    if (!orientation.empty()) env["SIMCTL_CHILD_FA_ORIENTATION"] = orientation;
    ProcessOptions launch;
    launch.argv = {"xcrun", "simctl", "launch", "--terminate-running-process", "--console-pty", udid, bundleId};
    launch.env = env;
    launch.timeoutSeconds = double(seconds);
    launch.captureStdout = false;
    std::atomic<bool> stop{false};
    launch.cancel = &stop;
    std::vector<std::string> console;
    std::vector<std::string> errors;
    int replayFrames = -1;
    bool marker = false, shotDone = shot.empty(), orientationAsked = false;
    auto on_line = [&](std::string_view line) {
        std::string l(line);
        console.push_back(l);
        if (l.find(" ERROR ") != std::string::npos || l.find("Cannot read the input replay") != std::string::npos) errors.push_back(l);
        if (l.find("screen orientation requested") != std::string::npos) orientationAsked = true;
        if (l.find("frames rendered") != std::string::npos) marker = true;
        if (auto at = l.find("replay done after "); at != std::string::npos) replayFrames = std::atoi(l.c_str() + at + 17);
        // Without a replay the check is "the game runs": the run marker (60 frames drawn) ends the wait.
        const bool done = replay.empty() ? marker : replayFrames >= 0;
        if (done && !stop.load()) {
            std::this_thread::sleep_for(std::chrono::duration<double>(settle));  // a few frames after the last input, and the turn of the screen
            if (!shot.empty()) {
                std::error_code ec;
                stdfs::create_directories(stdfs::path(shot).parent_path(), ec);
                ProcessResult s = simctl({"io", udid, "screenshot", "--type=png", shot}, 60);
                shotDone = s.exitCode == 0;
                if (!shotDone) errors.push_back("screenshot failed: " + simctl_fail_text(s));
            }
            stop = true;
        }
    };
    launch.onStdoutLine = on_line;
    launch.onStderrLine = on_line;
    auto ran = run_process(launch);
    simctl({"terminate", udid, bundleId}, 30);
    if (!ran.ok()) fail("Cannot start the app: " + ran.error().message, "xcrun simctl launch failed to start.");

    const bool finished = stop.load();
    report["replayFrames"] = replayFrames >= 0 ? Json(replayFrames) : Json(nullptr);
    report["finished"] = finished;
    report["orientationRequested"] = orientationAsked;
    if (!shot.empty() && shotDone) report["screenshot"] = shot;
    report["errors"] = errors;
    report["console"] = console.size() > 80 ? std::vector<std::string>(console.end() - 80, console.end()) : console;
    Json next = Json::array();
    if (!finished)
        next.push_back(ran->timedOut ? "The wait ended after " + std::to_string(seconds) + " s without " + (replay.empty() ? "the run marker" : "\"replay done\"") +
                                           ": look at `console`, raise \"seconds\" or check that the app is the player (not a crashed build)."
                                     : "The app ended before the replay did: look at `console` for the crash or the error.");
    if (!orientation.empty() && !orientationAsked)
        next.push_back("No \"screen orientation requested\" line: the app is an older player build without FA_ORIENTATION. Rebuild it from this checkout.");
    if (!orientation.empty() && orientationAsked)
        next.push_back("The turn is a request: iOS refuses an orientation the Info.plist does not allow (export.ios / display.orientation); `console` would show \"cannot turn the screen\".");
    if (!shot.empty() && shotDone) next.push_back("Look at the screenshot " + shot + " to see what the replay left on the screen.");
    report["nextSteps"] = next;
    if (!finished || !errors.empty()) {
        report["ok"] = false;
        std::string tail;  // a failed command returns no result, so the end of the console goes into the message
        for (std::size_t i = console.size() > 6 ? console.size() - 6 : 0; i < console.size(); ++i) tail += "\n  " + console[i];
        throw CommandError("failed", "The replay did not run to its end on " + deviceName + (errors.empty() ? "." : ": " + errors.front()) +
                                         (tail.empty() ? "" : " The end of the player's console:" + tail),
                           next.empty() ? "Run the same steps by hand (dryRun lists them)." : next[0].get<std::string>());
    }
    report["ok"] = true;
    return report;
#endif
}

}  // namespace

void register_ios_sim_commands(CommandRegistry& registry, const std::string& projectDir) {
    CommandInfo info;
    info.name = "player.run_ios_sim";
    info.category = "project";
    info.readOnly = false;
    info.summary = "Play an input replay on the iOS player in the iOS Simulator (an iPhone or an iPad), turn the screen and take a screenshot.";
    info.description =
        "Needs a Mac with Xcode. `xcrun simctl` can neither tap nor rotate, so the player takes both itself: this command boots a "
        "simulator, installs `app` (the Simulator build of the player, ./build_ios.sh --simulator in the iOS export folder), launches "
        "it with the environment variables FA_INPUT_REPLAY (the replay `input.record` writes, the one `factoria run --input` plays) "
        "and FA_ORIENTATION (portrait or landscape; iOS refuses an orientation the Info.plist does not allow), waits for the player's "
        "\"player: replay done after N frames\" line (without `input`: for its 60-frame run marker), waits `settleMilliseconds` more, "
        "writes a PNG of the simulator's screen when `screenshot` is given and terminates the app. The replay is applied by frame "
        "number to the window's frames at their real duration (not the fixed step of a headless run): presses and releases play as "
        "recorded, but a game that moves by dt may end up elsewhere than in the recording, so check what it leaves with the screenshot "
        "and the `console`. Returns {device, deviceName, bundleId, replayFrames, "
        "finished, orientationRequested, screenshot, errors[], console[] (the last 80 lines), nextSteps[], ok}; it is an error (with the end of the console in its message) when "
        "the replay does not end in `seconds` or the player logged an error. dryRun returns the simctl commands and runs nothing "
        "(any host). Example: {\"app\":\"build/export/my-game-ios/build/Debug-iphonesimulator/factoria_player.app\","
        "\"input\":\"replays/play.json\",\"device\":\"iPad Pro 13-inch\",\"orientation\":\"landscape\",\"screenshot\":\"build/ipad.png\"}.";
    info.inputSchema = Json::parse(R"({
      "type":"object","required":["app"],
      "properties":{
        "app":{"type":"string","description":"The player built for the iOS Simulator: a factoria_player.app folder (project-relative or absolute)."},
        "input":{"type":"string","description":"An input replay JSON ({\"frames\":{\"0\":{\"press\":[\"jump\"]}}}), project-relative, absolute or relative to the current folder. Without it the player just runs."},
        "orientation":{"type":"string","enum":["portrait","landscape"],"description":"Turn the screen to this orientation about a second after the start."},
        "device":{"type":"string","description":"The simulator: a UDID or a name or part of one (\"iPad Pro 13-inch\"). Default: a booted iPhone, else the first iPhone of the newest iOS runtime."},
        "bundleId":{"type":"string","description":"The app's bundle id. Default: read from the app's Info.plist."},
        "screenshot":{"type":"string","description":"Write a PNG of the simulator's screen here when the replay is done (project-relative, inside the project, or absolute)."},
        "seconds":{"type":"integer","minimum":5,"maximum":3600,"default":90,"description":"How long to wait for the replay to finish."},
        "settleMilliseconds":{"type":"integer","minimum":0,"default":1500,"description":"Wait this long after the last replay frame before the screenshot."},
        "dryRun":{"type":"boolean","default":false,"description":"Return the simctl commands and run nothing."}
      }})");
    registry.add(info, [projectDir](const Json& args) { return run_ios_sim(projectDir, args); });
}

}  // namespace fa
