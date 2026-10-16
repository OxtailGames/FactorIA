// `setup xcode` (macOS): Xcode cannot be installed by a program (it comes from the App Store, needs the user's Apple ID and
// an administrator password to select it), so the status says what is missing and the install opens the App Store page
// and returns the steps the user takes. Nothing here runs sudo.
#include <algorithm>

#include "fa/core/strings.h"
#include "setup_internal.h"

namespace fa::setup_detail {

namespace {

constexpr const char* kXcodeStoreUrl = "macappstore://apps.apple.com/app/id497799835";
constexpr const char* kXcodeWebUrl = "https://apps.apple.com/app/xcode/id497799835";

struct XcodeFacts {
    std::string developerDir;    // `xcode-select -p`, "" when nothing is selected
    bool fullXcode = false;      // the selected developer folder is inside an Xcode*.app
    std::string installedApp;    // an Xcode*.app in /Applications, even when it is not the selected one
    std::string version;         // "Xcode 27.1" from `xcodebuild -version`, "" when it does not run
    bool licenseProblem = false; // xcodebuild asked for the license
    bool iphoneos = false;
    bool simulator = false;
};

struct Captured {
    bool ran = false;
    int exitCode = -1;
    std::string out;  // stdout + stderr
};

Captured capture(const SetupContext& ctx, std::vector<std::string> argv) {
    ProcessOptions po;
    po.argv = std::move(argv);
    po.timeoutSeconds = 60;
    Captured c;
    auto r = ctx.run_process_with(po);
    if (!r.ok()) return c;
    c.ran = true;
    c.exitCode = r->exitCode;
    c.out = r->stdoutText + "\n" + r->stderrText;
    return c;
}

std::string first_line_of(const std::string& text) {
    const std::string_view t = trim(text);
    return std::string(t.substr(0, t.find('\n')));
}

XcodeFacts look_at_xcode(const SetupContext& ctx) {
    XcodeFacts f;
    if (const Captured sel = capture(ctx, {"xcode-select", "-p"}); sel.ran && sel.exitCode == 0) f.developerDir = first_line_of(sel.out);
    f.fullXcode = f.developerDir.find(".app/Contents/Developer") != std::string::npos;
    std::error_code ec;
    for (const auto& entry : stdfs::directory_iterator(ctx.applicationsDir.empty() ? stdfs::path("/Applications") : stdfs::path(ctx.applicationsDir), ec)) {
        const std::string name = entry.path().filename().string();
        if (starts_with(name, "Xcode") && ends_with(name, ".app")) {
            f.installedApp = entry.path().string();
            if (name == "Xcode.app") break;
        }
    }
    if (!f.fullXcode) return f;
    const Captured ver = capture(ctx, {"xcodebuild", "-version"});
    if (ver.ran && ver.exitCode == 0) f.version = first_line_of(ver.out);
    else if (to_lower(ver.out).find("license") != std::string::npos) f.licenseProblem = true;
    if (f.version.empty()) return f;
    const Captured sdks = capture(ctx, {"xcodebuild", "-showsdks"});
    f.iphoneos = sdks.out.find("-sdk iphoneos") != std::string::npos;
    f.simulator = sdks.out.find("-sdk iphonesimulator") != std::string::npos;
    return f;
}

}  // namespace

SetupComponent xcode_status(const SetupContext& ctx) {
    SetupComponent c;
    c.id = "xcode";
    c.title = "Xcode (iOS export)";
    if (ctx.host_os() != "macos") {
        c.state = "unsupported";
        c.details = "iOS apps are built with Xcode on a Mac: nothing to set up on this computer.";
        return c;
    }
    c.canInstall = true;
    const XcodeFacts f = look_at_xcode(ctx);
    if (!f.developerDir.empty()) c.paths.emplace_back("developerDir", f.developerDir);
    if (f.fullXcode && !f.version.empty() && f.iphoneos && f.simulator) {
        c.state = "installed";
        c.details = f.version + " with the iOS and iOS Simulator platforms (developer folder " + f.developerDir + ").";
        return c;
    }
    if (!f.fullXcode) {
        if (!f.installedApp.empty()) {
            c.state = "partial";
            c.details = "Xcode is installed (" + f.installedApp + ") but the command-line tools point somewhere else" + (f.developerDir.empty() ? std::string(" (nothing selected).") : " (" + f.developerDir + ").");
            c.problems.push_back("Select Xcode with `sudo xcode-select -s " + f.installedApp + "/Contents/Developer` in Terminal (it asks for your password, so FactorIA does not run it).");
        } else {
            c.state = "missing";
            c.details = f.developerDir.empty() ? "Xcode is not installed." : "Only the Command Line Tools are installed (" + f.developerDir + "); building iOS apps needs the full Xcode.";
            c.problems.push_back("Install Xcode from the App Store (`setup.install xcode` opens its page), open it once, then run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.");
        }
        return c;
    }
    c.state = "partial";
    if (f.licenseProblem) {
        c.details = "Xcode is selected (" + f.developerDir + ") but its license is not accepted.";
        c.problems.push_back("Accept the license: open Xcode once, or run `sudo xcodebuild -license accept` in Terminal.");
    } else if (f.version.empty()) {
        c.details = "Xcode is selected (" + f.developerDir + ") but `xcodebuild -version` does not run.";
        c.problems.push_back("Open Xcode once so it finishes its setup, then check again.");
    } else {
        c.details = f.version + " is installed but its iOS " + std::string(f.iphoneos ? "Simulator " : "") + "platform is missing.";
        c.problems.push_back("Install the iOS platform: Xcode > Settings > Components, or `xcodebuild -downloadPlatform iOS` in Terminal (several GB).");
    }
    return c;
}

SetupResult xcode_install(const SetupContext& ctx, const SetupInstallOptions&) {
    Installer in(ctx, "xcode");
    if (ctx.host_os() != "macos")
        return in.fail("unsupported", make_error("Xcode only exists for macOS: iOS apps are built on a Mac.", "Export for iOS on a Mac, or use Android and the desktop platforms here."));
    const SetupComponent status = xcode_status(ctx);
    if (status.state == "installed") {
        SetupStep s;
        s.id = "xcode";
        s.title = "Xcode";
        s.outcome = "skipped";
        s.detail = "already installed: " + status.details;
        in.add_step(s);
        return in.finish();
    }
    SetupStep s;
    s.id = "xcode";
    s.title = "Xcode";
    s.outcome = "guidance";
    if (status.state == "missing") {
        ProcessOptions po;
        po.argv = {"open", kXcodeStoreUrl};
        po.timeoutSeconds = 30;
        auto r = ctx.run_process_with(po);
        if (r.ok() && r->exitCode == 0) {
            s.detail = "opened Xcode's page in the App Store";
            in.report.nextSteps.push_back("Click Get / Install in the App Store window that opened (Xcode is several GB: let it finish).");
        } else {
            s.detail = "could not open the App Store";
            in.report.warnings.push_back(std::string("Could not open the App Store page: open ") + kXcodeWebUrl + " yourself.");
            in.report.nextSteps.push_back(std::string("Install Xcode from the App Store: ") + kXcodeWebUrl);
        }
        in.report.nextSteps.push_back("Open Xcode once and accept its license and the extra components it offers (also Settings > Components > iOS).");
        in.report.nextSteps.push_back("Point the command-line tools at it (it asks for your password, so FactorIA does not run it): sudo xcode-select -s /Applications/Xcode.app/Contents/Developer");
    } else {
        s.detail = status.details;
        for (const std::string& p : status.problems) in.report.nextSteps.push_back(p);
    }
    in.report.nextSteps.push_back("Run `factoria setup` (or `factoria setup xcode`) again to check.");
    in.add_step(s);
    return in.finish();
}

}  // namespace fa::setup_detail
