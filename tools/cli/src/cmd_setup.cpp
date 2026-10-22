// setup: check this computer and install what an export needs (fa/tooling/setup.h)
#include <algorithm>
#include <iostream>
#include <memory>
#include <sstream>

#include "common.h"
#include "fa/core/strings.h"
#include "fa/tooling/setup.h"

#if defined(_WIN32)
#include <io.h>
#else
#include <unistd.h>
#endif

namespace fa::cli {

namespace {

const std::vector<std::string>& components() {
    static const std::vector<std::string> ids = {"android", "players", "cmake", "xcode", "appimage", "shaders", "vscode"};
    return ids;
}

// A person can answer the license question when stdin is a terminal (or when the embedder gave its own stream).
bool can_prompt(const Context& ctx) {
    if (&ctx.in != &std::cin) return true;
#if defined(_WIN32)
    return _isatty(_fileno(stdin)) != 0;
#else
    return isatty(fileno(stdin)) != 0;
#endif
}

std::string duration_text(double seconds) {
    std::ostringstream o;
    if (seconds >= 60) o << int(seconds) / 60 << "m " << int(seconds) % 60 << "s";
    else o.precision(1), o << std::fixed << seconds << "s";
    return o.str();
}

std::string size_text(std::uint64_t bytes) {
    std::ostringstream o;
    o.precision(bytes >= (1ull << 30) ? 1 : 0);
    o << std::fixed;
    if (bytes >= (1ull << 30)) o << double(bytes) / double(1ull << 30) << " GB";
    else if (bytes >= (1ull << 20)) o << double(bytes) / double(1ull << 20) << " MB";
    else o << double(bytes) / 1024.0 << " KB";
    return o.str();
}

void print_status_table(std::ostream& out, const SetupStatus& st) {
    out << "This computer: " << st.host << "   FactorIA home: " << st.home << "\n\n";
    std::size_t w = 0;
    for (const auto& c : st.components) w = std::max(w, c.id.size());
    for (const SetupComponent& c : st.components) {
        out << "  " << c.id << std::string(w - c.id.size() + 2, ' ') << c.state << std::string(c.state.size() < 11 ? 11 - c.state.size() : 1, ' ') << c.title;
        if (c.installSizeMb > 0 && c.state != "installed") out << "  (about " << c.installSizeMb << " MB to download)";
        out << "\n";
        const std::string pad(w + 4, ' ');
        if (!c.details.empty()) out << pad << c.details << "\n";
        for (const std::string& p : c.problems) out << pad << "- " << p << "\n";
    }
    std::vector<std::string> todo;
    for (const SetupComponent& c : st.components)
        if (c.canInstall && c.state != "installed" && c.state != "unsupported") todo.push_back(c.id);
    if (!todo.empty()) {
        out << "\nInstall what is missing: ";
        for (std::size_t i = 0; i < todo.size(); ++i) out << (i ? ", " : "") << "factoria setup " << todo[i];
        out << "\n";
    } else {
        out << "\nNothing to install here.\n";
    }
}

void print_report(std::ostream& out, const SetupResult& r) {
    const SetupReport& rep = r.report;
    out << rep.component << ": " << (rep.changed ? "done" : "nothing to do") << " in " << duration_text(rep.seconds) << "\n";
    for (const SetupStep& s : rep.steps) {
        out << "  " << s.outcome << "  " << s.title;
        if (!s.detail.empty()) out << ": " << s.detail;
        if (s.downloadedBytes) out << " (downloaded " << size_text(s.downloadedBytes) << ")";
        if (!s.path.empty() && s.detail.find(s.path) == std::string::npos) out << "\n      " << s.path;
        out << "\n";
    }
    for (const std::string& w : rep.warnings) out << "warning: " << w << "\n";
    if (!rep.nextSteps.empty()) out << "Next steps:\n";
    for (std::size_t i = 0; i < rep.nextSteps.size(); ++i) out << "  " << (i + 1) << ". " << rep.nextSteps[i] << "\n";
}

int run_install(Context& ctx, const std::string& component) {
    SetupInstallOptions o;
    o.component = component;
    o.acceptLicenses = ctx.args.has("accept-licenses");
    o.force = ctx.args.has("force");
    if (ctx.args.has("platforms")) o.platforms = split(ctx.args.str("platforms"), ',');
    const bool json = ctx.args.has("json");

    SetupContext sc;
    sc.cache = std::make_shared<SetupCache>();
    sc.progress = [&ctx](const std::string& line) { ctx.err << line << std::endl; };  // stdout carries the result only

    SetupResult r = setup_install(o, sc);
    if (!r.ok && r.code == "license_required" && !o.acceptLicenses && !json && can_prompt(ctx)) {
        const SetupStatus st = setup_status(sc, component, true);
        const SetupComponent* c = st.find(component);
        if (c && !c->licenses.empty()) {
            for (const SetupLicense& l : c->licenses) ctx.err << "\n" << l.title << " (" << l.id << ")\n\n" << l.text << "\n\n";
            ctx.err << "Installing the Android SDK means agreeing to the license above. Do you accept it? [y/N] " << std::flush;
            std::string answer;
            std::getline(ctx.in, answer);
            const std::string a = to_lower(trim(answer));
            if (a != "y" && a != "yes")
                return report_failure(ctx, "The Android SDK license was not accepted, so nothing was installed.", "Run 'factoria setup android' again when you want to install it.");
            o.acceptLicenses = true;
            r = setup_install(o, sc);
        }
    }
    if (!r.ok) {
        if (json) {
            Json err = Json::object({{"code", r.code}, {"message", r.error.message}, {"hint", r.error.hint}, {"steps", r.report.to_json()["steps"]}});
            print_json(ctx.out, Json::object({{"ok", false}, {"error", err}}));
            return 1;
        }
        if (r.code == "invalid_argument") throw UsageError(r.error.message, r.error.hint);
        for (const SetupStep& s : r.report.steps) ctx.err << "  " << s.outcome << "  " << s.title << (s.detail.empty() ? "" : ": " + s.detail) << "\n";
        std::string hint = r.error.hint;
        if (r.code == "license_required")
            hint = "Run it in a terminal to read and accept the license, or pass --accept-licenses after reading it ('factoria call setup.status \"{\\\"component\\\":\\\"android\\\"}\"' prints the text).";
        return report_failure(ctx, r.error.message, hint);
    }
    if (json) {
        print_json(ctx.out, r.report.to_json());
        return 0;
    }
    print_report(ctx.out, r);
    return 0;
}

}  // namespace

Command make_setup_command() {
    Command g;
    g.name = "setup";
    g.summary = "Check this computer for exporting and install what is missing (Android JDK + SDK, players, CMake, AppImage tools, the shader compiler).";
    g.usage = "";
    g.details =
        "'factoria setup' shows what an export needs and whether this computer has it. 'factoria setup <component>' installs it into\n"
        "~/.factoria ($FACTORIA_HOME) - nothing else on the computer changes except the machine settings (~/.factoria/export.json)\n"
        "that learn where the JDK and SDK are. Every download is checked against the checksum its publisher lists.\n"
        "  android  JDK 21 (Eclipse Temurin) + the Android SDK, so 'factoria export --platform android' builds an APK/AAB.\n"
        "           The SDK license is shown first and installed only after you accept it (or pass --accept-licenses).\n"
        "  players  the factoria_player of the other desktop OSes and the Android/iOS libraries, for this version of factoria.\n"
        "  cmake    CMake 3.24+ for the iOS export (macOS), unless one is found.\n"
        "  xcode    macOS: checks Xcode; 'setup xcode' opens its App Store page and says what to do next.\n"
        "  appimage Linux x86_64 (and WSL): appimagetool and the AppImage runtime, so 'factoria export --platform linux --format appimage'\n"
        "           also builds the game as one AppImage file.\n"
        "  shaders  sokol-shdc, the shader compiler of custom materials (*.material.json): the pinned build for this computer, checked\n"
        "           against a SHA-256. Not needed when $SOKOL_SHDC or a sokol-shdc next to factoria is found (downloads carry one).\n"
        "  vscode   the script debugger for VS Code (and Insiders, VSCodium, Cursor): copies the extension built into factoria to\n"
        "           ~/.vscode/extensions, so F5 in a project debugs its scripts (docs/DEBUGGING.md). Nothing is downloaded.";
    g.maxPositional = 1;
    g.flags = {{"json", "", "Machine-readable output."}};
    g.examples = {"factoria setup", "factoria setup android", "factoria setup android --accept-licenses", "factoria setup players",
                  "factoria setup --json"};
    g.run = [](Context& ctx) {
        if (!ctx.args.positional().empty())
            throw UsageError("Unknown setup component '" + ctx.args.pos(0) + "'.", fa::did_you_mean(ctx.args.pos(0), components()));
        SetupContext sc;
        sc.cache = std::make_shared<SetupCache>();
        const bool json = ctx.args.has("json");
        const SetupStatus st = setup_status(sc, {}, json);  // the license text is only worth a request for the machine-readable form
        if (json) {
            print_json(ctx.out, st.to_json());
            return 0;
        }
        print_status_table(ctx.out, st);
        return 0;
    };

    auto sub = [](const std::string& name, const std::string& summary, std::vector<FlagSpec> flags, std::vector<std::string> examples) {
        Command c;
        c.name = name;
        c.summary = summary;
        c.usage = "";
        c.flags = std::move(flags);
        c.flags.push_back({"json", "", "Machine-readable report."});
        c.examples = std::move(examples);
        c.run = [name](Context& ctx) { return run_install(ctx, name); };
        return c;
    };
    g.subs.push_back(sub("android", "Install the JDK and the Android SDK that APK/AAB exports build with.",
                         {{"accept-licenses", "", "You have read the Android SDK license and accept it (without it a terminal asks, anything else refuses)."},
                          {"force", "", "Install the JDK and the command-line tools again even when they are found."}},
                         {"factoria setup android", "factoria setup android --accept-licenses"}));
    g.subs.push_back(sub("players", "Download the factoria_player of the other desktop OSes and the mobile libraries for this version.",
                         {{"platforms", "LIST", "Comma-separated: windows, linux, macos, mobile, web (default: every desktop OS but this one, plus mobile when missing; web, the web export's player, only when asked for: every download has it next to factoria)."},
                          {"force", "", "Download again even when installed."}},
                         {"factoria setup players", "factoria setup players --platforms windows,linux"}));
    g.subs.push_back(sub("cmake", "Install CMake 3.24+ (for the iOS export) unless one is found.",
                         {{"force", "", "Install it into ~/.factoria even when a CMake is found (or this is not a Mac)."}}, {"factoria setup cmake"}));
    g.subs.push_back(sub("xcode", "macOS: check Xcode and open its App Store page when it is missing.", {}, {"factoria setup xcode"}));
    g.subs.push_back(sub("appimage", "Linux x86_64: install appimagetool and the AppImage runtime that --format appimage exports build with.",
                         {{"force", "", "Download them again even when installed."}}, {"factoria setup appimage"}));
    g.subs.push_back(sub("shaders", "Install the pinned sokol-shdc that custom materials are compiled with (not needed when a download of factoria carries it).",
                         {{"force", "", "Download it again even when one is found."}}, {"factoria setup shaders"}));
    g.subs.push_back(sub("vscode", "Install the FactorIA debugger extension into VS Code (and Insiders, VSCodium, Cursor).",
                         {{"force", "", "Copy it again even when this version is installed."}}, {"factoria setup vscode"}));
    return g;
}

}  // namespace fa::cli
