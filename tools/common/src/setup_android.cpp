// `setup android`: a JDK and the Android SDK, ready for `factoria export --platform android`.
//
//   JDK 21      Eclipse Temurin from the Adoptium API  -> <home>/android/jdk
//   SDK         command-line tools from Google's repository -> <sdk>/cmdline-tools/<revision>: the pinned classic Java
//               sdkmanager (kSetupAndroidCmdlineTools), `latest` only when Google's list no longer has it. The license
//               agreement is recorded by us (only the one the user agreed to, only after they agreed), then sdkmanager installs
//               platform-tools, platforms;android-36, build-tools;35.0.0
// The SDK is the one the toolchain search already finds (Android Studio's, ANDROID_HOME...) except Unity Hub's, which
// belongs to Unity; otherwise <home>/android/sdk. What was installed is saved in the machine config so that
// find_android_toolchain uses it.
#include <algorithm>
#include <chrono>
#include <fstream>

#include "fa/core/fs.h"
#include "fa/core/json.h"
#include "fa/core/strings.h"
#include "setup_internal.h"
#include "util.h"

namespace fa::setup_detail {

namespace {

constexpr int kMinJdk = 17;

struct AndroidPlan {
    MachineExportConfig config;
    AndroidToolchain toolchain;
    bool jdkOk = false;              // a JDK 17+ is found (then toolchain.jdk is it)
    stdfs::path sdkDir;              // the SDK this setup works in
    bool sdkFound = false;           // sdkDir looks like an SDK now
    stdfs::path sdkmanager;          // "" when sdkDir has no command-line tools
    bool licensesAccepted = false;
    std::vector<std::string> missingPackages;  // sdkmanager package names that are not in sdkDir
};

std::vector<std::pair<const char*, stdfs::path>> required_packages() {
    return {{kSetupAndroidPlatformTools, stdfs::path("platform-tools")},
            {kSetupAndroidPlatform, stdfs::path("platforms") / "android-36"},
            {kSetupAndroidBuildTools, stdfs::path("build-tools") / "35.0.0"}};
}

Result<AndroidPlan> plan_android(const SetupContext& ctx) {
    AndroidPlan p;
    auto cfg = load_machine_export_config(ctx.config_path());
    if (!cfg.ok()) return cfg.error();
    p.config = *cfg;
    p.toolchain = find_android_toolchain(p.config, ctx.search());
    p.jdkOk = jdk_usable(p.toolchain.jdk);
    // Unity Hub's SDK belongs to Unity (its Editor owns its packages): never installed into.
    if (sdk_looks_ok(p.toolchain.sdk) && p.toolchain.sdkFrom != "Unity Hub") p.sdkDir = p.toolchain.sdk;
    else p.sdkDir = stdfs::path(ctx.home_dir()) / "android" / "sdk";
    p.sdkFound = sdk_looks_ok(p.sdkDir.string());
    p.sdkmanager = find_sdkmanager(p.sdkDir);
    p.licensesAccepted = sdk_license_accepted(p.sdkDir);
    for (const auto& [name, rel] : required_packages())
        if (!is_dir(p.sdkDir / rel)) p.missingPackages.push_back(name);
    return p;
}

std::string adoptium_os(const std::string& host) { return host == "macos" ? "mac" : host; }

stdfs::path find_java_home(const stdfs::path& root) {
    auto is_home = [](const stdfs::path& d) { return is_file(d / "bin" / "java") || is_file(d / "bin" / "java.exe"); };
    if (is_home(root)) return root;
    std::error_code ec;
    for (const auto& entry : stdfs::directory_iterator(root, ec)) {
        if (!entry.is_directory(ec)) continue;
        if (is_home(entry.path())) return entry.path();
        if (is_home(entry.path() / "Contents" / "Home")) return entry.path() / "Contents" / "Home";  // macOS .jdk bundle
    }
    return {};
}

std::string tail_lines(const std::string& text, int count) {
    std::vector<std::string> lines;
    for (const std::string& l : split(text, '\n')) {
        const std::string_view t = trim(l);
        if (!t.empty() && t.front() != '[') lines.emplace_back(t);
    }
    std::string out;
    for (std::size_t i = lines.size() > std::size_t(count) ? lines.size() - std::size_t(count) : 0; i < lines.size(); ++i)
        out += (out.empty() ? "" : "\n") + lines[i];
    return out;
}

// sdkmanager <args> with JAVA_HOME set; `forwardOutput` sends the progress lines (not the license text) to ctx.say.
Result<ProcessResult> run_sdkmanager(const SetupContext& ctx, const stdfs::path& sdkmanager, const stdfs::path& sdk,
                                     const std::string& jdk, std::vector<std::string> args, const std::string& stdinText,
                                     bool forwardOutput) {
    ProcessOptions po;
    po.argv = {sdkmanager.string(), "--sdk_root=" + sdk.string()};
    po.argv.insert(po.argv.end(), args.begin(), args.end());
    po.env["JAVA_HOME"] = jdk;
    // The pinned classic tools keep little in $ANDROID_USER_HOME (default ~/.android), but the Android CLI that revision 23+ and an
    // SDK found on the computer may have unpacks a ~250 MB copy of itself there. Keep it inside the FactorIA folder either way,
    // like everything else we install.
    po.env["ANDROID_USER_HOME"] = (stdfs::path(ctx.home_dir()) / "android" / "user").string();
    po.stdinText = stdinText;
    po.timeoutSeconds = 3600;
    if (forwardOutput) {
        auto forward = [&ctx](std::string_view line) {
            // sdkmanager redraws "[=====     ] 40% Downloading..." with carriage returns: keep the last piece, and only text.
            const std::size_t cr = line.rfind('\r');
            if (cr != std::string_view::npos) line = line.substr(cr + 1);
            const std::string_view t = trim(line);
            if (!t.empty() && t.front() != '[') ctx.say(std::string(t));
        };
        po.onStdoutLine = forward;
        po.onStderrLine = forward;
    }
    return ctx.run_process_with(po);
}

std::string yes_lines(int count) {
    std::string s;
    for (int i = 0; i < count; ++i) s += "y\n";
    return s;
}

std::string license_required_message() {
    return "The Android SDK license has not been accepted yet. Installing the Android SDK (command-line tools, platform-tools, platform 36, "
           "build-tools 35.0.0) means agreeing to the \"Android Software Development Kit License Agreement\" (license id " +
           std::string(kSetupAndroidLicenseId) + ").";
}

std::string license_required_hint() {
    return "Show the license text to the user (setup.status lists it under components[].licenses; it is also at "
           "https://developer.android.com/studio/terms) and run the install again with acceptLicenses set only after they agree "
           "(CLI: factoria setup android --accept-licenses). An AI must ask the user first.";
}

// The folder of cmdline-tools/ a package goes to: the part of its path after ';' ("cmdline-tools;22.0" -> "22.0", "...;latest" -> "latest").
std::string package_folder(const std::string& package) {
    const std::size_t semi = package.find(';');
    return semi == std::string::npos ? package : package.substr(semi + 1);
}

std::string describe_jdk_source(const AndroidToolchain& tc) {
    return "JDK " + std::to_string(tc.jdkMajor) + " (" + (tc.jdkFrom == "config" ? std::string("export.json") : tc.jdkFrom) + ") at " + tc.jdk;
}

}  // namespace

// ---- helpers shared with the status -------------------------------------------------------------------------------

bool jdk_usable(const std::string& dir) {
    if (dir.empty()) return false;
    const stdfs::path root(dir);
    const bool java = is_file(root / "bin" / "java") || is_file(root / "bin" / "java.exe");
    const bool javac = is_file(root / "bin" / "javac") || is_file(root / "bin" / "javac.exe");
    return java && javac && jdk_major_version(dir) >= kMinJdk;
}

bool sdk_looks_ok(const std::string& dir) {
    if (dir.empty()) return false;
    const stdfs::path root(dir);
    return is_dir(root / "platform-tools") || is_dir(root / "platforms") || is_dir(root / "licenses");
}

stdfs::path find_sdkmanager(const stdfs::path& sdk) {
    auto in_dir = [](const stdfs::path& bin) -> stdfs::path {
        if (is_file(bin / "sdkmanager.bat")) return bin / "sdkmanager.bat";
        if (is_file(bin / "sdkmanager")) return bin / "sdkmanager";
        return {};
    };
    const stdfs::path base = sdk / "cmdline-tools";
    // The revision FactorIA pins first (what `setup android` installs), then `latest`, then the newest of the others.
    if (auto pinned = in_dir(base / package_folder(kSetupAndroidCmdlineTools) / "bin"); !pinned.empty()) return pinned;
    if (auto latest = in_dir(base / "latest" / "bin"); !latest.empty()) return latest;
    std::vector<std::string> versions;
    std::error_code ec;
    for (const auto& entry : stdfs::directory_iterator(base, ec))
        if (entry.is_directory(ec)) versions.push_back(entry.path().filename().string());
    std::sort(versions.rbegin(), versions.rend());  // newest first
    for (const std::string& v : versions)
        if (auto found = in_dir(base / v / "bin"); !found.empty()) return found;
    return {};
}

bool sdk_license_accepted(const stdfs::path& sdk) {
    std::error_code ec;
    const stdfs::path file = sdk / "licenses" / kSetupAndroidLicenseId;
    return stdfs::is_regular_file(file, ec) && stdfs::file_size(file, ec) > 0;
}

std::optional<Fail> fetch_sdk_repository(const SetupContext& ctx, const stdfs::path& scratch, SdkRepositoryInfo& out) {
    const auto now = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
    std::string xml;
    if (ctx.cache) {
        std::lock_guard<std::mutex> lock(ctx.cache->mutex);
        if (!ctx.cache->repositoryXml.empty() && now - ctx.cache->fetchedAtSeconds < 600) xml = ctx.cache->repositoryXml;
    }
    if (xml.empty()) {
        if (auto f = fetch_text(ctx, kSdkRepositoryUrl, "the Android SDK package list", scratch, xml)) return f;
        if (ctx.cache) {
            std::lock_guard<std::mutex> lock(ctx.cache->mutex);
            ctx.cache->repositoryXml = xml;
            ctx.cache->fetchedAtSeconds = now;
        }
    }
    auto info = parse_sdk_repository(xml, ctx.host_os(), ctx.host_architecture());
    if (!info.ok()) return Fail{"failed", info.error()};
    out = std::move(*info);
    return std::nullopt;
}

// ---- status -------------------------------------------------------------------------------------------------------------

SetupComponent android_status(const SetupContext& ctx, bool fetchLicenses) {
    SetupComponent c;
    c.id = "android";
    c.title = "Android export (JDK + Android SDK)";
    c.canInstall = true;
    auto planned = plan_android(ctx);
    if (!planned.ok()) {
        c.state = "missing";
        c.problems.push_back(planned.error().message + (planned.error().hint.empty() ? "" : " " + planned.error().hint));
        c.details = "The machine settings could not be read, so the Android toolchain was not looked up.";
        return c;
    }
    const AndroidPlan& p = *planned;
    const AndroidToolchain& tc = p.toolchain;
    const bool sdkReady = p.sdkFound && p.sdkmanager.empty() == false;

    if (p.jdkOk) c.paths.emplace_back("jdk", tc.jdk);
    if (p.sdkFound) c.paths.emplace_back("sdk", p.sdkDir.string());
    if (!p.sdkmanager.empty()) c.paths.emplace_back("sdkmanager", p.sdkmanager.string());

    if (!p.jdkOk) c.problems.push_back("No JDK " + std::to_string(kMinJdk) + " or newer was found: the install downloads Eclipse Temurin " +
                                       std::to_string(kSetupJdkMajor) + ".");
    if (!p.sdkFound) c.problems.push_back("No Android SDK was found: the install sets one up in " + p.sdkDir.string() + ".");
    else if (p.sdkmanager.empty()) c.problems.push_back("The Android SDK at " + p.sdkDir.string() + " has no command-line tools (cmdline-tools): the install adds them.");
    if (!p.licensesAccepted) c.problems.push_back("The Android SDK license is not accepted yet (the user must agree to it before the install; its text is in `licenses`).");
    if (!p.missingPackages.empty() && (p.sdkFound || !p.licensesAccepted)) {
        std::string list;
        for (const std::string& m : p.missingPackages) list += (list.empty() ? "" : ", ") + m;
        c.problems.push_back("Missing from the Android SDK: " + list + (p.licensesAccepted ? " (Gradle downloads them on the first build, or the install does now)." : "."));
    }

    const bool complete = p.jdkOk && sdkReady && p.licensesAccepted && p.missingPackages.empty();
    c.state = complete ? "installed" : ((p.jdkOk || p.sdkFound) ? "partial" : "missing");
    std::string details;
    if (p.jdkOk) details += describe_jdk_source(tc) + ". ";
    if (p.sdkFound) details += "Android SDK at " + p.sdkDir.string() + (p.sdkDir == tc.sdk ? " (" + tc.sdkFrom + ")" : std::string()) + ". ";
    if (complete) details += "Licenses accepted; platform 36, build-tools 35.0.0 and platform-tools are there.";
    else details += "`setup.install android` fetches what is missing" + std::string(tc.sdkFrom == "Unity Hub" ? " (into " + p.sdkDir.string() + ": Unity Hub's SDK is left alone)" : "") + ".";
    c.details = details;

    int mb = 0;
    if (!p.jdkOk) mb += 200;
    if (p.sdkmanager.empty()) mb += 160;  // the pinned command-line tools (150 to 180 MB); nothing else is fetched on first use
    if (!p.missingPackages.empty()) mb += 140;
    c.installSizeMb = mb;

    if (!p.licensesAccepted && fetchLicenses) {
        std::error_code ec;
        const stdfs::path scratch = fs::make_temp_dir("fa_setup_status");
        SdkRepositoryInfo repo;
        if (auto f = fetch_sdk_repository(ctx, scratch, repo)) {
            c.problems.push_back("Could not fetch the license text from Google: " + f->error.message + " The license is also at https://developer.android.com/studio/terms.");
        } else {
            c.licenses.push_back(repo.license);
        }
        stdfs::remove_all(scratch, ec);
    }
    return c;
}

// ---- install -------------------------------------------------------------------------------------------------------------

SetupResult android_install(const SetupContext& ctx, const SetupInstallOptions& opt) {
    Installer in(ctx, "android");
    auto planned = plan_android(ctx);
    if (!planned.ok()) return in.fail("failed", planned.error());
    AndroidPlan plan = std::move(*planned);
    MachineExportConfig config = plan.config;
    const std::string home = ctx.home_dir();
    const std::string os = ctx.host_os();

    const bool needJdk = opt.force || !plan.jdkOk;
    const bool needCmdline = opt.force || plan.sdkmanager.empty();
    const bool needPackages = opt.force || !plan.missingPackages.empty();
    const bool needSdkWork = needCmdline || !plan.licensesAccepted || needPackages;

    // The license first: nothing is downloaded before the user has agreed.
    if (!plan.licensesAccepted && !opt.acceptLicenses && needSdkWork)
        return in.fail("license_required", make_error(license_required_message(), license_required_hint()));

    bool configChanged = false;
    std::string jdkDir = plan.jdkOk ? plan.toolchain.jdk : std::string();

    // ---- 1. the JDK ---------------------------------------------------------------------------------------------
    if (!needJdk) {
        SetupStep s;
        s.id = "jdk";
        s.title = "JDK";
        s.outcome = "skipped";
        s.detail = "already installed: " + describe_jdk_source(plan.toolchain);
        s.path = plan.toolchain.jdk;
        in.add_step(s);
    } else {
        StepTimer timer;
        const stdfs::path ownJdk = stdfs::path(home) / "android" / "jdk";
        const std::string url = "https://api.adoptium.net/v3/assets/latest/" + std::to_string(kSetupJdkMajor) + "/hotspot?os=" + adoptium_os(os) +
                                "&architecture=" + ctx.host_architecture() + "&image_type=jdk&vendor=eclipse";
        ctx.say("Looking up the newest Eclipse Temurin JDK " + std::to_string(kSetupJdkMajor) + "...");
        std::string text;
        if (auto f = fetch_text(ctx, url, "the Eclipse Temurin JDK listing", in.staging(), text)) return in.fail(*f);
        auto json = parse_json(text, url);
        if (!json.ok()) return in.fail("failed", make_error("Adoptium's answer is not JSON: " + json.error().message, "Try again later."));
        auto jdk = parse_adoptium_assets(*json);
        if (!jdk.ok()) return in.fail("failed", jdk.error());
        const stdfs::path archive = in.staging() / jdk->name;
        std::uint64_t bytes = 0;
        if (auto f = download_file(ctx, jdk->url, archive, "JDK " + jdk->version + " (Eclipse Temurin)", jdk->size, &bytes)) return in.fail(*f);
        if (auto f = verify_checksum(archive, "sha256", jdk->sha256, "the JDK")) return in.fail(*f);
        const stdfs::path unpacked = in.make_staging_subdir("jdk");
        if (auto f = extract_archive(ctx, archive, unpacked)) return in.fail(*f);
        std::error_code ec;
        stdfs::remove(archive, ec);  // 200 MB less on disk while the rest installs
        const stdfs::path javaHome = find_java_home(unpacked);
        if (javaHome.empty())
            return in.fail("failed", make_error("The JDK archive " + jdk->name + " has no bin/java inside.", "Run it again; if it keeps failing, install a JDK 17+ by hand (https://adoptium.net)."));
        if (auto f = replace_dir(javaHome, ownJdk)) return in.fail(*f);
        if (!jdk_usable(ownJdk.string()))
            return in.fail("failed", make_error("The JDK unpacked into " + ownJdk.string() + " is not usable (no bin/java and bin/javac, or Java older than " + std::to_string(kMinJdk) + ").",
                                                "Run it again, or install a JDK 17+ by hand (https://adoptium.net)."));
        jdkDir = ownJdk.string();
        if (config.androidJdk != jdkDir) config.androidJdk = jdkDir, configChanged = true;
        SetupStep s;
        s.id = "jdk";
        s.title = "JDK " + std::to_string(kSetupJdkMajor);
        s.outcome = "installed";
        s.detail = "Eclipse Temurin " + jdk->version;
        s.path = jdkDir;
        s.downloadedBytes = bytes;
        s.seconds = timer.seconds();
        in.add_step(s);
    }

    // ---- 2. the command-line tools ---------------------------------------------------------------------------------
    // The repository listing is needed for the tools and, when they are there already but the license is not, for the license text.
    SdkRepositoryInfo repo;
    bool haveRepo = false;
    auto ensure_repo = [&]() -> std::optional<Fail> {
        if (haveRepo) return std::nullopt;
        ctx.say("Looking up Google's Android SDK package list...");
        if (auto f = fetch_sdk_repository(ctx, in.staging(), repo)) return f;
        haveRepo = true;
        for (const std::string& w : repo.warnings) in.report.warnings.push_back(w);
        return std::nullopt;
    };
    stdfs::path sdkmanager = plan.sdkmanager;
    bool classicTools = false;  // the tools were installed from the pinned package in this run: sdkmanager --licenses is not needed
    if (!needCmdline) {
        SetupStep s;
        s.id = "cmdline-tools";
        s.title = "Android command-line tools";
        s.outcome = "skipped";
        s.detail = "already installed: " + sdkmanager.string();
        s.path = sdkmanager.string();
        in.add_step(s);
    } else {
        StepTimer timer;
        if (auto f = ensure_repo()) return in.fail(*f);
        const std::string fileName = repo.cmdlineTools.url.substr(repo.cmdlineTools.url.rfind('/') + 1);
        const stdfs::path archive = in.staging() / fileName;
        std::uint64_t bytes = 0;
        if (auto f = download_file(ctx, repo.cmdlineTools.url, archive, "Android command-line tools " + repo.cmdlineToolsRevision, repo.cmdlineTools.size, &bytes))
            return in.fail(*f);
        if (auto f = verify_checksum(archive, repo.cmdlineTools.checksumType, repo.cmdlineTools.checksum, "the Android command-line tools")) return in.fail(*f);
        const stdfs::path unpacked = in.make_staging_subdir("cmdline-tools");
        if (auto f = extract_archive(ctx, archive, unpacked)) return in.fail(*f);
        std::error_code ec;
        stdfs::remove(archive, ec);
        stdfs::path top = unpacked / "cmdline-tools";  // the zip holds one folder, cmdline-tools/
        if (!is_dir(top)) top = single_child_dir(unpacked);
        if (!is_dir(top / "bin"))
            return in.fail("failed", make_error("The Android command-line tools archive " + fileName + " has no cmdline-tools/bin inside.",
                                                "Google may have changed the archive; update FactorIA, or install Android Studio."));
        // The folder is named like the package (cmdline-tools/22.0, or latest for the fallback), as the SDK Manager lays it out.
        const stdfs::path dest = plan.sdkDir / "cmdline-tools" / package_folder(repo.cmdlineToolsPackage);
        if (auto f = replace_dir(top, dest)) return in.fail(*f);
        make_tree_executable(dest / "bin");
        sdkmanager = find_sdkmanager(plan.sdkDir);
        if (sdkmanager.empty())
            return in.fail("failed", make_error("The command-line tools were unpacked into " + dest.string() + " but there is no bin/sdkmanager in them.", "Update FactorIA."));
        classicTools = repo.cmdlineToolsPinned;
        SetupStep s;
        s.id = "cmdline-tools";
        s.title = "Android command-line tools";
        s.outcome = "installed";
        s.detail = "revision " + repo.cmdlineToolsRevision +
                   (repo.cmdlineToolsPinned ? " (the classic Java sdkmanager FactorIA pins)" : " (" + repo.cmdlineToolsPackage + ", Google's Android CLI: see the warning)");
        s.path = dest.string();
        s.downloadedBytes = bytes;
        s.seconds = timer.seconds();
        in.add_step(s);
    }

    // ---- 3. the license ------------------------------------------------------------------------------------------
    // The user agreed to one license, the text of which we showed (acceptLicenses). We record that one and nothing else: a line
    // with the hash of its text in licenses/android-sdk-license, which is what sdkmanager and Gradle look for. `sdkmanager
    // --licenses` would answer y to every license Google lists (previews, Google TV, GDK, MIPS system images...).
    if (plan.licensesAccepted) {
        SetupStep s;
        s.id = "licenses";
        s.title = "Android SDK license";
        s.outcome = "skipped";
        s.detail = "already accepted";
        s.path = (plan.sdkDir / "licenses").string();
        in.add_step(s);
    } else {
        StepTimer timer;
        if (auto f = ensure_repo()) return in.fail(*f);
        ctx.say("Recording the Android SDK license agreement (the user agreed)...");
        const std::string hash = sdk_license_hash(repo.license.text);
        const stdfs::path file = plan.sdkDir / "licenses" / kSetupAndroidLicenseId;
        // The file is empty or missing here (otherwise it counts as accepted). Google's tools write a line break, then the hash.
        if (!tooling_detail::write_file(file, "\n" + hash))
            return in.fail("failed", make_error("Cannot write " + file.string() + ".", "Check the free disk space and that the folder is writable."));
        SetupStep s;
        s.id = "licenses";
        s.title = "Android SDK license";
        s.outcome = "installed";
        s.detail = "recorded the agreement to \"" + repo.license.title + "\" (" + repo.license.id + ") and no other license";
        s.path = file.string();
        s.seconds = timer.seconds();
        in.add_step(s);
    }
    const bool installPackages = needPackages;

    // ---- 4. the packages -----------------------------------------------------------------------------------------
    if (!installPackages) {
        SetupStep s;
        s.id = "packages";
        s.title = "Android SDK packages";
        s.outcome = "skipped";
        s.detail = std::string("already installed: ") + kSetupAndroidPlatformTools + ", " + kSetupAndroidPlatform + ", " + kSetupAndroidBuildTools;
        s.path = plan.sdkDir.string();
        in.add_step(s);
    } else {
        StepTimer timer;
        std::string list;
        for (const auto& [name, rel] : required_packages()) list += std::string(name) + "\n";
        const stdfs::path packageFile = in.staging() / "packages.txt";
        if (!tooling_detail::write_file(packageFile, list))
            return in.fail("failed", make_error("Cannot write " + packageFile.string() + ".", "Check the free disk space."));
        ctx.say(std::string("Installing ") + kSetupAndroidPlatformTools + ", " + kSetupAndroidPlatform + " and " + kSetupAndroidBuildTools + " (sdkmanager)...");
        // The license of these packages is recorded (step 3). The pinned classic tools are given no answers: a prompt for any other
        // license ends without accepting what the user never saw. Other tools (an SDK that was found, the Android CLI of the
        // fallback) get `y` after the user's agreement, as they may still ask in their own way.
        const bool answerYes = opt.acceptLicenses && !classicTools;
        auto r = run_sdkmanager(ctx, sdkmanager, plan.sdkDir, jdkDir, {"--package_file=" + packageFile.string()},
                                answerYes ? yes_lines(50) : std::string(), true);
        if (!r.ok()) return in.fail("failed", r.error());
        if (r->cancelled || is_cancelled(ctx.cancel)) return in.fail("cancelled", make_error("The setup was cancelled."));
        const std::string output = r->stdoutText + "\n" + r->stderrText;
        if (r->exitCode != 0) {
            const std::string lower = to_lower(output);
            if (lower.find("license") != std::string::npos && lower.find("not accepted") != std::string::npos) {
                if (!opt.acceptLicenses) return in.fail("license_required", make_error(license_required_message(), license_required_hint()));
                // The user did agree and the agreement was recorded, yet sdkmanager asks for a license: it does not know our line.
                return in.fail("failed", make_error("sdkmanager does not accept the license agreement FactorIA recorded in " +
                                                        (plan.sdkDir / "licenses" / kSetupAndroidLicenseId).string() + ":\n" + tail_lines(output, 4),
                                                    "Run `" + sdkmanager.string() + " --licenses` yourself and answer y, or open Android Studio's SDK Manager."));
            }
            return in.fail("failed", make_error("sdkmanager failed to install the SDK packages (exit code " + std::to_string(r->exitCode) + ")" +
                                                    (tail_lines(output, 6).empty() ? "" : ":\n" + tail_lines(output, 6)),
                                                "Check the internet connection and the free disk space, then run it again."));
        }
        std::string missing;
        for (const auto& [name, rel] : required_packages())
            if (!is_dir(plan.sdkDir / rel)) missing += (missing.empty() ? "" : ", ") + std::string(name);
        if (!missing.empty())
            return in.fail("failed", make_error("sdkmanager finished but " + missing + " is not in " + plan.sdkDir.string() + ".",
                                                "Run it again, or run `" + sdkmanager.string() + " --list_installed` to see what is installed."));
        SetupStep s;
        s.id = "packages";
        s.title = "Android SDK packages";
        s.outcome = "installed";
        s.detail = std::string(kSetupAndroidPlatformTools) + ", " + kSetupAndroidPlatform + ", " + kSetupAndroidBuildTools;
        s.path = plan.sdkDir.string();
        s.seconds = timer.seconds();
        in.add_step(s);
    }

    // ---- 5. the machine config -----------------------------------------------------------------------------------
    // Only what had to be told: the JDK that was installed here, an SDK that is not the one found by itself.
    if (plan.sdkDir.string() != plan.toolchain.sdk && config.androidSdk != plan.sdkDir.string())
        config.androidSdk = plan.sdkDir.string(), configChanged = true;
    if (configChanged) {
        if (auto saved = save_machine_export_config(config, ctx.config_path()); !saved.ok()) return in.fail("failed", saved.error());
        SetupStep s;
        s.id = "config";
        s.title = "Machine settings";
        s.outcome = "installed";
        s.detail = "the JDK and SDK folders are saved in " + ctx.config_path() + ", where `factoria export` looks for them";
        s.path = ctx.config_path();
        in.add_step(s);
    }
    in.report.paths = {{"jdk", jdkDir}, {"sdk", plan.sdkDir.string()}, {"sdkmanager", sdkmanager.string()}, {"config", ctx.config_path()}};
    in.report.nextSteps.push_back("Export for Android: factoria export --platform android (the editor's Export window does the same). The first Gradle build downloads Gradle itself and takes a few minutes.");
    return in.finish();
}

}  // namespace fa::setup_detail
