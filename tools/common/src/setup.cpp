// `factoria setup`: the public API (status, install, what the export asks for), the JSON of the reports and the commands
// "setup.status" / "setup.install". The installers are in setup_android.cpp, setup_players.cpp, setup_cmake.cpp,
// setup_xcode.cpp and setup_appimage.cpp; the shared mechanics in setup_core.cpp.
#include "fa/tooling/setup.h"

#include <algorithm>
#include <filesystem>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "setup_internal.h"
#include "util.h"

namespace fa {

namespace stdfs = std::filesystem;

std::string factoria_home(const ExportEnvLookup& env) {
    if (auto h = env("FACTORIA_HOME"); !h.empty()) return h;
#if defined(_WIN32)
    if (auto h = env("USERPROFILE"); !h.empty()) return (stdfs::path(h) / ".factoria").string();
#else
    if (auto h = env("HOME"); !h.empty()) return (stdfs::path(h) / ".factoria").string();
#endif
    return ".factoria";
}

namespace {

const std::vector<std::string>& component_ids() {
    static const std::vector<std::string> ids = {"android", "players", "cmake", "xcode", "appimage"};
    return ids;
}

Json paths_json(const std::vector<std::pair<std::string, std::string>>& paths) {
    Json o = Json::object();
    for (const auto& [k, v] : paths) o[k] = v;
    return o;
}

}  // namespace

// ---- JSON -------------------------------------------------------------------------------------------------------------

Json SetupComponent::to_json() const {
    Json j = Json::object();
    j["id"] = id;
    j["title"] = title;
    j["state"] = state;
    j["details"] = details;
    j["paths"] = paths_json(paths);
    j["problems"] = problems;
    j["installSizeMb"] = installSizeMb;
    Json lic = Json::array();
    for (const SetupLicense& l : licenses) lic.push_back(Json::object({{"id", l.id}, {"title", l.title}, {"text", l.text}}));
    j["licenses"] = lic;
    j["canInstall"] = canInstall;
    return j;
}

const SetupComponent* SetupStatus::find(const std::string& id) const {
    for (const SetupComponent& c : components)
        if (c.id == id) return &c;
    return nullptr;
}

Json SetupStatus::to_json() const {
    Json j = Json::object();
    j["home"] = home;
    j["host"] = host;
    Json arr = Json::array();
    for (const SetupComponent& c : components) arr.push_back(c.to_json());
    j["components"] = arr;
    return j;
}

Json SetupStep::to_json() const {
    Json j = Json::object();
    j["id"] = id;
    j["title"] = title;
    j["outcome"] = outcome;
    j["detail"] = detail;
    if (!path.empty()) j["path"] = path;
    if (downloadedBytes) j["downloadedBytes"] = downloadedBytes;
    j["seconds"] = seconds;
    return j;
}

Json SetupReport::to_json() const {
    Json j = Json::object();
    j["component"] = component;
    j["changed"] = changed;
    Json arr = Json::array();
    for (const SetupStep& s : steps) arr.push_back(s.to_json());
    j["steps"] = arr;
    j["paths"] = paths_json(paths);
    j["nextSteps"] = nextSteps;
    j["warnings"] = warnings;
    j["seconds"] = seconds;
    return j;
}

// ---- status / install -------------------------------------------------------------------------------------------------

SetupStatus setup_status(const SetupContext& ctx, const std::string& component, bool fetchLicenses) {
    SetupStatus st;
    st.home = ctx.home_dir();
    st.host = ctx.host_os() + "-" + ctx.host_architecture();
    for (const std::string& id : component_ids()) {
        if (!component.empty() && component != id) continue;
        if (id == "android") st.components.push_back(setup_detail::android_status(ctx, fetchLicenses));
        else if (id == "players") st.components.push_back(setup_detail::players_status(ctx));
        else if (id == "cmake") st.components.push_back(setup_detail::cmake_status(ctx));
        else if (id == "xcode") st.components.push_back(setup_detail::xcode_status(ctx));
        else st.components.push_back(setup_detail::appimage_status(ctx));
    }
    return st;
}

SetupResult setup_install(const SetupInstallOptions& options, const SetupContext& ctx) {
    if (is_cancelled(ctx.cancel)) {
        SetupResult r;
        r.report.component = options.component;
        r.code = "cancelled";
        r.error = make_error("The setup was cancelled before it started.");
        return r;
    }
    if (options.component == "android") return setup_detail::android_install(ctx, options);
    if (options.component == "players") return setup_detail::players_install(ctx, options);
    if (options.component == "cmake") return setup_detail::cmake_install(ctx, options);
    if (options.component == "xcode") return setup_detail::xcode_install(ctx, options);
    if (options.component == "appimage") return setup_detail::appimage_install(ctx, options);
    SetupResult r;
    r.report.component = options.component;
    r.code = "invalid_argument";
    r.error = make_error("Unknown setup component '" + options.component + "'.", did_you_mean(options.component, component_ids()));
    return r;
}

// ---- what the export asks for ---------------------------------------------------------------------------------------

std::string installed_player(const std::string& platform) { return installed_player(SetupContext{}, platform); }
std::string installed_player(const SetupContext& context, const std::string& platform) { return setup_detail::installed_player_path(context, platform); }
std::string installed_mobile_dir() { return installed_mobile_dir(SetupContext{}); }
std::string installed_mobile_dir(const SetupContext& context) { return setup_detail::installed_mobile_path(context); }
AppImageTools installed_appimage_tools(const SetupContext& context) { return setup_detail::installed_appimage_path(context); }
std::string find_cmake() { return find_cmake(SetupContext{}); }
std::string find_cmake(const SetupContext& context) { return setup_detail::find_cmake_path(context); }

// ---- commands --------------------------------------------------------------------------------------------------------

void register_setup_commands(CommandRegistry& registry) {
    // One listing of the Android SDK repository is shared by the calls of this process (the license text of the status,
    // then the install).
    auto cache = std::make_shared<SetupCache>();

    {
        CommandInfo info;
        info.name = "setup.status";
        info.category = "setup";
        info.readOnly = true;
        info.summary = "Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode, the AppImage tools.";
        info.description =
            "Returns {home, host, components[]}; each component is {id, title, state, details, paths, problems[], installSizeMb, "
            "licenses[], canInstall}. Components: `android` (JDK + Android SDK for APK/AAB exports), `players` (the factoria_player of "
            "the other desktop OSes and the prebuilt Android/iOS libraries, from the GitHub release of this factoria's version), "
            "`cmake` (3.24+, for the iOS export on a Mac), `xcode` (macOS: status only, it cannot be installed by a program) and `appimage` "
            "(appimagetool and the AppImage runtime, Linux x86_64 only: what `project.export` {platform: linux, format: appimage} builds an AppImage with). "
            "state is installed | missing | partial | unsupported (nothing to do on this computer). problems[] says what is missing and "
            "how to fix it; `setup.install` fixes everything except Xcode. `licenses` (android only, only while the Android SDK license "
            "is not accepted yet) holds {id, title, text}: the full license the user must read and agree to before `setup.install` "
            "with acceptLicenses. The only network request is the fetch of that license text (fetchLicenses false skips it). "
            "Everything installed lives under `home` ($FACTORIA_HOME, default ~/.factoria). Details: docs_read {\"name\":\"exporting\"}. "
            "Example: {\"component\":\"android\"}.";
        info.inputSchema = Json::parse(R"({
          "type":"object",
          "properties":{
            "component":{"type":"string","enum":["android","players","cmake","xcode","appimage"],"description":"Only this component (default: all of them)."},
            "fetchLicenses":{"type":"boolean","default":true,"description":"Download the Android SDK license text when the license is not accepted yet (a network request). false = skip it (a polling UI)."}
          }})");
        registry.add(info, [cache](const Json& args) {
            const std::string component = tooling_detail::arg_string(args, "component", false);
            if (!component.empty() && std::find(component_ids().begin(), component_ids().end(), component) == component_ids().end())
                throw CommandError("invalid_argument", "Unknown setup component '" + component + "'.", did_you_mean(component, component_ids()));
            SetupContext ctx;
            ctx.cache = cache;
            return setup_status(ctx, component, tooling_detail::arg_bool(args, "fetchLicenses", true)).to_json();
        });
    }

    {
        CommandInfo info;
        info.name = "setup.install";
        info.category = "setup";
        info.readOnly = false;
        info.summary = "Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake, the AppImage tools (or open Xcode's App Store page).";
        info.description =
            "Downloads and installs one component into $FACTORIA_HOME (default ~/.factoria) and returns {component, changed, steps[], "
            "paths, nextSteps[], warnings[], seconds}; every step says whether it was installed or skipped because it was already there. "
            "It downloads hundreds of megabytes (setup.status says how many: installSizeMb) and can take minutes: ask the user before "
            "calling it. `android`: JDK 21 (Eclipse Temurin) and the Android SDK command-line tools, platform-tools, platform 36 and "
            "build-tools 35.0.0 (the SDK found on this computer is reused, except Unity Hub's), saved in ~/.factoria/export.json so "
            "`project.export` finds them. It REFUSES with error code `license_required` until acceptLicenses is true: the Android SDK "
            "license is a legal agreement between the user and Google, so show the user the text from setup.status "
            "(components[].licenses[].text) and set acceptLicenses ONLY after they have read it and said yes; never set it on your own. "
            "`players`: the factoria_player of the other desktop OSes plus the prebuilt mobile libraries, for exports to other "
            "platforms without building anything; from the GitHub release of this factoria's version (a development build ahead of the "
            "last release fails with code `no_release`); platforms narrows it (windows, linux, macos, mobile). `cmake`: CMake 3.31 from "
            "Kitware (macOS only, for iOS exports) unless 3.24+ is found; force installs it anyway. `xcode` (macOS): cannot be "
            "installed by a program: it opens Xcode's App Store page and returns the steps the user must do (some need their password). "
            "`appimage` (Linux x86_64): appimagetool 1.9.1 and the AppImage runtime from github.com/AppImage, about 16 MB, into $FACTORIA_HOME/tools/appimage. "
            "Every download is checked against the publisher's checksum (error code `checksum_mismatch` installs nothing). Other error "
            "codes: network, cancelled, unsupported, invalid_argument, failed; the data of the error holds the steps done so far. "
            "Example: {\"component\":\"android\",\"acceptLicenses\":true}.";
        info.inputSchema = Json::parse(R"({
          "type":"object","required":["component"],
          "properties":{
            "component":{"type":"string","enum":["android","players","cmake","xcode","appimage"],"description":"What to install: android (JDK + Android SDK), players (other platforms' factoria_player + mobile libraries), cmake (iOS export), xcode (guidance only), appimage (appimagetool + runtime for the Linux AppImage export; Linux x86_64 only)."},
            "acceptLicenses":{"type":"boolean","default":false,"description":"android: the user has read the Android SDK license (setup.status components[].licenses) and agreed to it. Without it the install refuses with license_required. Never set it without asking the user."},
            "platforms":{"type":"array","items":{"type":"string","enum":["windows","linux","macos","mobile","web"]},"description":"players: which players to install (default: every desktop OS but this one, plus the mobile libraries when this factoria has none next to it). \"web\" installs the web export's player (factoria_player.js + .wasm); every download carries it next to factoria, so it is only fetched when asked for."},
            "force":{"type":"boolean","default":false,"description":"android, cmake, players: install again even when it is found (a JDK or CMake that is already there is used otherwise)."}
          }})");
        registry.add(info, [cache](const Json& args) {
            SetupInstallOptions o;
            o.component = tooling_detail::arg_string(args, "component", true);
            o.acceptLicenses = tooling_detail::arg_bool(args, "acceptLicenses", false);
            o.force = tooling_detail::arg_bool(args, "force", false);
            if (auto it = args.find("platforms"); it != args.end() && it->is_array())
                for (const Json& p : *it)
                    if (p.is_string()) o.platforms.push_back(p.get<std::string>());
            SetupContext ctx;
            ctx.cache = cache;
            ctx.progress = [](const std::string& line) { FA_INFO("setup", "{}", line); };
            SetupResult r = setup_install(o, ctx);
            if (!r.ok) throw CommandError(r.code, r.error.message, r.error.hint, Json::object({{"steps", r.report.to_json()["steps"]}}));
            return r.report.to_json();
        });
    }
}

}  // namespace fa
