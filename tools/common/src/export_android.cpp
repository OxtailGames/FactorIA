// Android export: the Gradle project from platforms/android (templates, with its own Gradle wrapper), the icons, the
// game in app/src/main/assets and, in prebuilt mode, the ready-made libfactoria_player.so of each ABI (the modes are
// described in export_internal.h); then, unless the format is "gradle", the build of the APK or AAB with that wrapper.
//
//   plan_android    every decision and check before anything is written (format, icons, JDK + SDK, release signing)
//   export_android  writes the Gradle project
//   build_android   after FACTORIA_NOTICES.txt is in the project: runs Gradle, copies the result, writes the next steps
#include <algorithm>
#include <cctype>
#include <cstdio>
#include <deque>
#include <filesystem>
#include <fstream>

#include "export_internal.h"
#include "fa/core/process.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"

namespace fa::export_detail {

namespace {

std::string slug_of(const Project& p) {
    const std::string slug = slugify(p.name, '-');
    return slug.empty() ? "game" : slug;
}

std::string lower(std::string s) {
    for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    return s;
}

bool is_text_template(const stdfs::path& p) {
    std::string e = p.extension().string();
    return e == ".gradle" || e == ".properties" || e == ".xml" || e == ".kts" || e == ".txt" || e == ".md";
}

// A path or name as the value of a java.util.Properties file (gradle.properties, local.properties): `\`, `:`, `=`, `#`
// and `!` are escaped, and everything outside ASCII becomes \uXXXX (Gradle reads these files as ISO-8859-1, so a user
// name with an accent would otherwise come out wrong).
std::string properties_escape(const std::string& v) {
    std::string out;
    char buf[16];
    for (const char16_t u : utf8_to_utf16(v)) {
        switch (u) {
            case '\\': out += "\\\\"; break;
            case ':': out += "\\:"; break;
            case '=': out += "\\="; break;
            case '#': out += "\\#"; break;
            case '!': out += "\\!"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            case ' ': out += out.empty() ? "\\ " : " "; break;  // only a leading space needs it
            default:
                if (u < 0x80) {
                    out += static_cast<char>(u);
                } else {
                    std::snprintf(buf, sizeof buf, "\\u%04X", unsigned(u));
                    out += buf;
                }
        }
    }
    return out;
}

// The project-relative keystore of export.android.signing resolved against the game folder (absolute ones stay).
std::string resolve_keystore(const Project& p, const std::string& keystore) {
    if (keystore.empty()) return {};
    const stdfs::path k(keystore);
    return generic(k.is_absolute() ? k : (p.dir / k).lexically_normal());
}

// Where the Gradle build leaves its result, relative to the project, best candidate first.
std::vector<std::string> gradle_outputs(const AndroidPlan& a) {
    const std::string variant = a.release ? "release" : "debug";
    if (a.format == "aab") return {"app/build/outputs/bundle/" + variant + "/app-" + variant + ".aab"};
    if (a.release) return {"app/build/outputs/apk/release/app-release.apk", "app/build/outputs/apk/release/app-release-unsigned.apk"};
    return {"app/build/outputs/apk/debug/app-debug.apk"};
}

std::string gradle_task(const AndroidPlan& a) {
    return std::string(a.format == "aab" ? "bundle" : "assemble") + (a.release ? "Release" : "Debug");
}

bool is_windows_host() { return host_platform() == "windows"; }

// A path as a command line shows it: single quotes on POSIX, double quotes on Windows.
std::string quote_path(const std::string& s) { return is_windows_host() ? "\"" + s + "\"" : sh_quote(s); }

// The adb of the SDK's platform-tools when it is there, else the name (it may be on PATH).
std::string adb_command(const AndroidPlan& a) {
    if (!a.toolchain.sdk.empty()) {
        std::error_code ec;
        const stdfs::path adb = stdfs::path(a.toolchain.sdk) / "platform-tools" / (is_windows_host() ? "adb.exe" : "adb");
        if (stdfs::is_regular_file(adb, ec)) return quote_path(generic(adb));
    }
    return "adb";
}

std::string indent_lines(const std::vector<std::string>& lines) {
    std::string out;
    for (const std::string& l : lines) out += (out.empty() ? "    " : "\n    ") + l;
    return out;
}

bool is_file(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_regular_file(os_path(p), ec);
}

bool is_folder(const stdfs::path& p) {
    std::error_code ec;
    return stdfs::is_directory(os_path(p), ec);
}

// What the native plugins add to the Gradle project (docs/MOBILE.md, "Native plugins on Android").
struct PluginGradle {
    std::string projects;      // settings.gradle: the modules, one "\ninclude ..." + "\nproject(...)" pair each
    std::string dependencies;  // app/build.gradle: a dependencies block, or ""
    bool hasCode = false;      // Java / Kotlin sources or .aar / .jar files: the APK carries classes (android:hasCode)
};

// A plugin's Android build (<plugin folder>/android, see plugin_build) is a Gradle library module, copied to plugins/<name>
// and included in the build, or .aar / .jar files, copied to app/libs/<name> and added to the app's dependencies.
Result<PluginGradle> export_plugins(const Project& p, const stdfs::path& outRoot) {
    PluginGradle g;
    std::string deps;
    for (const Project::Plugin& plugin : p.plugins) {
        const std::string& name = plugin.name;
        const stdfs::path& from = plugin.build;
        const bool isModule = is_file(from / "build.gradle") || is_file(from / "build.gradle.kts");
        const stdfs::path to = isModule ? outRoot / "plugins" / name : outRoot / "app" / "libs" / name;
        const stdfs::path osFrom = os_path(from);
        std::error_code ec, copyEc;  // apart: the iterator's increment clears ec
        // File by file: std::filesystem::copy of a folder silently drops what lies past Windows' MAX_PATH.
        auto copy_to = [&](const stdfs::path& src, const stdfs::path& rel) {
            stdfs::create_directories(os_path((to / rel).parent_path()), copyEc);
            if (!copyEc) stdfs::copy_file(src, os_path(to / rel), stdfs::copy_options::overwrite_existing, copyEc);
        };
        if (isModule) {  // the whole module but for what building it leaves behind
            for (stdfs::recursive_directory_iterator it(osFrom, ec), end; !ec && !copyEc && it != end; it.increment(ec)) {
                const stdfs::path rel = it->path().lexically_relative(osFrom);
                const std::string top = rel.begin()->string();
                if (top == "build" || top == ".gradle" || top == ".cxx") it.disable_recursion_pending();
                else if (it->is_regular_file(ec)) copy_to(it->path(), rel);
            }
        } else {  // only the archives
            for (stdfs::directory_iterator it(osFrom, ec), end; !ec && !copyEc && it != end; it.increment(ec)) {
                const std::string ext = lower(it->path().extension().string());
                if ((ext == ".aar" || ext == ".jar") && it->is_regular_file(ec)) copy_to(it->path(), it->path().filename());
            }
        }
        if (ec || copyEc)
            return err("export: cannot copy the plugin '" + name + "' (" + generic(from) + ") to " + generic(to) + ": " + (copyEc ? copyEc : ec).message());
        if (isModule) {
            g.projects += "\ninclude ':plugin_" + name + "'\nproject(':plugin_" + name + "').projectDir = file('plugins/" + name + "')";
            deps += "\n    implementation project(':plugin_" + name + "')";
            g.hasCode = g.hasCode || is_folder(from / "src" / "main" / "java") || is_folder(from / "src" / "main" / "kotlin");
        } else {
            deps += "\n    implementation fileTree(dir: 'libs/" + name + "', include: ['*.aar', '*.jar'])";
            g.hasCode = true;
        }
    }
    if (!deps.empty()) g.dependencies = "\n\ndependencies {" + deps + "\n}";
    return g;
}

}  // namespace

// ---- plan ----------------------------------------------------------------------------------------------------

Result<AndroidPlan> plan_android(const ExportOptions& o, const Project& p, const stdfs::path& outRoot,
                                 std::vector<std::string>& warnings, bool decodeIcons) {
    AndroidPlan a;
    const AndroidExportSettings& s = p.settings.android;
    a.release = o.release;

    // ---- format ----
    a.format = o.format.empty() ? s.format : lower(o.format);
    if (!is_export_format(a.format))
        return err("export: unknown Android format '" + (o.format.empty() ? s.format : o.format) + "'", did_you_mean(a.format, export_formats()));
    if (a.format != "gradle") {
        const std::string name = slug_of(p) + (o.release ? "" : "-debug") + (a.format == "aab" ? ".aab" : ".apk");
        a.artifact = outRoot / name;
    }

    // ---- icons: decoded for an export; a dry run (the editor's Export window repeats it every few seconds) only checks
    // that the files exist, and decodes them when one is missing, for the teaching error of load_icon_image ----
    bool decode = decodeIcons;
    if (const std::string icon = p.settings.icon_for("android"); !icon.empty() && !decode) {
        std::error_code ec;
        const std::string background = s.adaptiveIcon.background.rfind('#', 0) == 0 ? std::string() : s.adaptiveIcon.background;
        for (const std::string& rel : {icon, s.adaptiveIcon.foreground, s.adaptiveIcon.monochrome, background})
            if (!rel.empty() && !stdfs::is_regular_file(p.dir / rel, ec)) decode = true;
    }
    if (const std::string icon = p.settings.icon_for("android"); !icon.empty() && decode) {
        const std::string pointer = s.icon.empty() ? "/icon" : "/export/android/icon";
        std::vector<ExportSettingsIssue> issues;
        auto img = load_icon_image(generic(p.dir), icon, pointer, &issues);
        if (!img.ok()) return err(img.error().message, img.error().hint);
        auto adaptive = load_adaptive_icon(generic(p.dir), s, &issues);
        if (!adaptive.ok()) return err(adaptive.error().message, adaptive.error().hint);
        for (const auto& w : issues) warnings.push_back(w.to_string());
        a.hasIcon = true;
        a.icon = std::move(*img);
        a.adaptive = std::move(*adaptive);
    }

    // ---- JDK and SDK: ~/.factoria/export.json, the environment, the usual folders ----
    const AndroidToolchainSearch search = o.androidSearch ? *o.androidSearch : default_android_toolchain_search();
    const ExportEnvLookup env = search.env ? search.env : system_export_env();
    const bool builds = a.format != "gradle";
    MachineExportConfig config;
    if (auto machine = load_machine_export_config(machine_export_config_path(env)); machine.ok()) {
        config = std::move(machine.value());
    } else if (builds) {
        return machine.error();
    } else {
        warnings.push_back("Ignoring the machine settings (they are not needed for the Gradle project): " + machine.error().to_string());
    }
    a.toolchain = find_android_toolchain(config, search);
    if (builds) {
        if (!a.toolchain.ok()) {
            std::string message = std::string("export: cannot build the Android ") + (a.format == "aab" ? "bundle" : "app") +
                                  " on this computer: ";
            for (std::size_t i = 0; i < a.toolchain.problems.size(); ++i) message += (i ? " " : "") + a.toolchain.problems[i];
            return err(message, "To write only the Gradle project (and build it elsewhere, e.g. in Android Studio), export with the format "
                                "gradle: factoria export --platform android --format gradle, or \"format\": \"gradle\" under "
                                "export.android in factoria.json.");
        }
        warnings.insert(warnings.end(), a.toolchain.warnings.begin(), a.toolchain.warnings.end());
    }

    // ---- release signing ----
    if (!s.signing.keystore.empty() && !s.signing.alias.empty()) {
        a.keystore = resolve_keystore(p, s.signing.keystore);
        a.alias = s.signing.alias;
    }
    if (o.release && builds) {
        if (!s.signing.keystore.empty()) {
            if (s.signing.alias.empty())
                return err("factoria.json#/export/android/signing/alias: missing, so the release build cannot be signed",
                           "Add \"alias\": \"<key alias>\" next to \"keystore\" (the name you gave the key in keytool -genkeypair -alias ...; "
                           "keytool -list -keystore <file> shows it).");
            std::error_code ec;
            if (!stdfs::is_regular_file(stdfs::path(a.keystore), ec))
                return err("factoria.json#/export/android/signing/keystore: the keystore '" + a.keystore + "' does not exist",
                           "Fix the path (project-relative or absolute), or create a keystore: the editor's Platform settings > Android > "
                           "Create keystore..., or keytool -genkeypair -v -keystore <file> -alias <alias> -keyalg RSA -keysize 2048 -validity 10000. "
                           "Keep it outside the repository and never lose it: Google Play cannot update an app signed with another key.");
            a.secrets = resolve_android_signing_secrets(config, env);
            if (a.secrets.keystorePassword.empty())
                return err("export: the password of the release keystore '" + a.keystore + "' is not set",
                           "Set the environment variable FACTORIA_ANDROID_KEYSTORE_PASSWORD (and FACTORIA_ANDROID_KEY_PASSWORD when the key has "
                           "its own password) before exporting, or save them on this computer in the editor (Platform settings > Android > This "
                           "computer > Remember on this computer), which writes " + machine_export_config_path(env) + ". Passwords are never "
                           "stored in the project or in the exported files; Gradle gets them as environment variables.");
            warnings.insert(warnings.end(), config.warnings.begin(), config.warnings.end());
        } else {
            warnings.push_back("This release build is signed with the debug key because export.android.signing has no keystore: fine to test on "
                               "a device, but Google Play rejects it. Create a keystore (the editor's Platform settings > Android > Create "
                               "keystore..., or keytool -genkeypair) and set export.android.signing.keystore and .alias in factoria.json");
        }
    }
    return a;
}

// ---- the Gradle project --------------------------------------------------------------------------------

Result<void> export_android(const Project& p, const MobileSetup& setup, const AndroidPlan& a, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    const AndroidExportSettings& s = p.settings.android;
    const std::string orient = p.orientation == "portrait" ? "sensorPortrait" : p.orientation == "any" ? "fullSensor" : "sensorLandscape";
    const int versionCode = s.versionCode > 0 ? s.versionCode : android_version_code_from(p.version);

    std::vector<std::string> permissions;
    for (const std::string& perm : s.permissions) permissions.push_back("<uses-permission android:name=\"" + xml_escape(perm) + "\" />");
    std::string signingProperties;
    if (!a.keystore.empty())
        signingProperties = "# Release signing (export.android.signing in factoria.json). The passwords are NOT stored here: set the environment\n"
                            "# variables FACTORIA_ANDROID_KEYSTORE_PASSWORD and FACTORIA_ANDROID_KEY_PASSWORD before running a release build.\n"
                            "factoria.signing.keystore=" + properties_escape(a.keystore) + "\n"
                            "factoria.signing.alias=" + properties_escape(a.alias) + "\n";

    auto plugins = export_plugins(p, outRoot);
    if (!plugins.ok()) return plugins.error();

    const std::vector<std::pair<std::string, std::string>> vars = {
        {"APPLICATION_ID", p.id},
        {"PROJECT_SLUG", slug_of(p)},
        {"APP_NAME_XML", xml_escape(p.name, true)},
        {"VERSION_NAME", safe_version_name(p.version)},
        {"VERSION_CODE", std::to_string(versionCode)},
        {"SCREEN_ORIENTATION", orient},
        {"ENGINE_ROOT", setup.prebuilt ? std::string() : generic(setup.engine)},
        {"MIN_SDK", std::to_string(s.minSdk)},
        {"TARGET_SDK", std::to_string(s.targetSdk)},  // compileSdk = targetSdk
        {"APP_ICON_ATTRS", a.hasIcon ? "\n        android:icon=\"@mipmap/ic_launcher\"\n        android:roundIcon=\"@mipmap/ic_launcher_round\"" : ""},
        {"USES_PERMISSIONS", indent_lines(permissions)},
        {"SIGNING_PROPERTIES", signingProperties},
        {"PLUGIN_PROJECTS", plugins->projects},
        {"PLUGIN_DEPENDENCIES", plugins->dependencies},
        {"HAS_CODE", plugins->hasCode ? "true" : "false"},
        // The prebuilt libraries are stripped already (and Gradle has no NDK to strip them with): say so instead of a warning.
        {"PACKAGING_OPTIONS", setup.prebuilt ? "\n\n    // The prebuilt engine libraries are stripped already.\n    packaging {\n        jniLibs {\n"
                                               "            keepDebugSymbols += ['**/*.so']\n        }\n    }" : ""},
    };
    auto templates = load_templates(setup, "android");
    if (!templates.ok()) return templates.error();
    for (const TemplateFile& t : *templates) {
        const stdfs::path to = outRoot / t.rel;
        if (is_text_template(t.rel)) {
            auto text = select_sections(t.data, !setup.prebuilt, t.rel);
            if (!text.ok()) return text.error();
            for (auto& [k, v] : vars) *text = replace_all(*text, "{{" + k + "}}", v);
            if (text->find("{{") != std::string::npos)
                return err("export: unreplaced placeholder in template " + t.rel, "this is an engine bug; report it");
            if (auto r = write_text(to, *text); !r.ok()) return r;
        } else if (t.rel == "gradlew") {
            // The wrapper script is written with LF line endings and the executable bit, even from a checkout that has CRLF.
            if (auto r = write_text(to, replace_all(t.data, "\r\n", "\n"), /*executable=*/true); !r.ok()) return r;
        } else if (auto r = write_text(to, t.data); !r.ok()) {
            return r;
        }
    }
    if (!a.toolchain.sdk.empty()) {  // for Android Studio; the export itself passes ANDROID_HOME to Gradle
        if (auto r = write_text(outRoot / "local.properties",
                                "# Generated by factoria export for this computer: do not commit it.\nsdk.dir=" +
                                    properties_escape(generic(stdfs::path(a.toolchain.sdk))) + "\n");
            !r.ok())
            return r;
    }
    if (a.hasIcon)
        if (auto r = write_android_icons(generic(outRoot / "app" / "src" / "main" / "res"), a.icon, a.adaptive); !r.ok())
            return err("export: cannot write the Android icons: " + r.error().message, r.error().hint);

    std::error_code ec;
    if (setup.prebuilt)
        for (const char* abi : kAndroidAbis) {
            const stdfs::path to = outRoot / "app" / "src" / "main" / "jniLibs" / abi / "libfactoria_player.so";
            stdfs::create_directories(os_path(to.parent_path()), ec);
            stdfs::copy_file(setup.libs / "jniLibs" / abi / "libfactoria_player.so", os_path(to), stdfs::copy_options::overwrite_existing, ec);
            if (ec) return err(std::string("export: cannot copy the prebuilt ") + abi + " player to " + generic(to) + ": " + ec.message());
        }
    stdfs::path assets = outRoot / "app" / "src" / "main" / "assets";
    if (auto r = copy_game(p, files, assets); !r.ok()) return r;
    std::string index;
    for (auto& f : files) index += f + "\n";
    if (auto r = write_text(assets / "assets_index.txt", index); !r.ok()) return r;
    report.format = a.format;
    return {};
}

// ---- the build ----------------------------------------------------------------------------------------------

namespace {

// Where Gradle's own words are: the text between "* What went wrong:" and the next "* ..." heading of its failure
// report; without one (a crash before Gradle's report), the last few lines of the build.
std::string gradle_failure_text(const std::deque<std::string>& tail) {
    std::size_t start = tail.size();
    for (std::size_t i = tail.size(); i-- > 0;)
        if (trim(tail[i]) == "* What went wrong:") {
            start = i + 1;
            break;
        }
    std::vector<std::string> block;
    if (start < tail.size()) {
        for (std::size_t i = start; i < tail.size(); ++i) {
            const std::string_view t = trim(tail[i]);
            if (t.rfind("* Try:", 0) == 0 || t.rfind("* Get more help", 0) == 0 || t.rfind("* Exception is:", 0) == 0 ||
                t.rfind("BUILD FAILED", 0) == 0)
                break;
            if (!t.empty()) block.emplace_back(t);
        }
    } else {
        for (std::size_t i = tail.size() > 12 ? tail.size() - 12 : 0; i < tail.size(); ++i)
            if (!trim(tail[i]).empty()) block.emplace_back(trim(tail[i]));
    }
    if (block.size() > 10) block.resize(10);
    std::string out;
    for (const std::string& l : block) out += (out.empty() ? "" : " ") + l;
    if (out.size() > 1500) out = out.substr(0, 1500) + "...";
    return out;
}

bool mentions(const std::string& lowerText, std::initializer_list<const char*> needles) {
    for (const char* n : needles)
        if (lowerText.find(n) != std::string::npos) return true;
    return false;
}

// The fix for the failures a first export meets most often, from what Gradle said; "" when it is none of them.
std::string gradle_failure_hint(const std::deque<std::string>& tail, const std::string& failure, const AndroidPlan& a) {
    std::string text = lower(failure);
    for (const std::string& l : tail) text += "\n" + lower(l);
    const std::string sdkTool = a.toolchain.sdk.empty() ? std::string("sdkmanager")
                                                        : generic(stdfs::path(a.toolchain.sdk) / "cmdline-tools" / "<revision>" / "bin" / "sdkmanager");
    if (mentions(text, {"licences have not been accepted", "licenses have not been accepted", "have not accepted the license",
                        "not accepted the licenses"}))
        return "The Android SDK licenses are not accepted yet, so Gradle cannot download the SDK package it needs (a platform or the build tools). Accept them once: "
               "factoria setup android (it shows the license and records it once you agree; the editor's Install Android build tools does the same), " +
               sdkTool + " --licenses (answer y), or Android Studio > Settings > Android SDK > SDK Tools, then export again.";
    if (mentions(text, {"unsupported class file major version", "unsupportedclassversionerror", "unsupported java", "incompatible java",
                        "requires java 17", "requires jdk 17", "could not determine java version", "invalid source release"}))
        return "The JDK '" + a.toolchain.jdk + "'" + (a.toolchain.jdkMajor > 0 ? " (Java " + std::to_string(a.toolchain.jdkMajor) + ")" : std::string()) +
               " does not suit this Gradle build: Android builds are tested with JDK 17 and 21 (too old and too new both fail). Choose "
               "another JDK in Platform settings > Android (This computer), \"android\": {\"jdk\": \"<folder>\"} in ~/.factoria/export.json, "
               "or JAVA_HOME.";
    // Source mode compiles the engine with the SDK's NDK and CMake; AGP does not always install them itself.
    if (mentions(text, {"[cxx1300]", "[cxx1101]", "[cxx1104]", "cmake '3.31.6' was not found", "ndk is not installed", "did not have a source.properties"}) ||
        (text.find("cmake") != std::string::npos && text.find("was not found in sdk") != std::string::npos))
        return "This export compiles the engine from source (mode: source), which needs NDK r27+ and CMake 3.31.6 in the Android SDK" +
               (a.toolchain.sdk.empty() ? std::string() : " '" + a.toolchain.sdk + "'") + ". Install them once: " + sdkTool +
               " \"ndk;27.2.12479018\" \"cmake;3.31.6\" (Android Studio > SDK Manager > SDK Tools > NDK (Side by side) and CMake), then export "
               "again. The FactorIA download exports with prebuilt players instead and needs neither.";
    if (mentions(text, {"sdk location not found", "no sdk directory", "android sdk is missing"}))
        return "Gradle could not use the Android SDK" + (a.toolchain.sdk.empty() ? std::string() : " '" + a.toolchain.sdk + "'") +
               ": check that the folder is a full SDK (platform-tools, platforms, licenses) in Platform settings > Android (This computer), "
               "\"android\": {\"sdk\": \"<folder>\"} in ~/.factoria/export.json, or ANDROID_HOME.";
    if (mentions(text, {"could not resolve", "could not get ", "could not download", "could not install gradle distribution", "unknownhostexception",
                        "connect timed out", "read timed out", "network is unreachable", "no route to host", "connection refused",
                        "sslhandshakeexception", "unable to tunnel through proxy", "failed to download", "could not transfer"}))
        return "Gradle could not download something. The first build needs the internet: it fetches Gradle itself (services.gradle.org), the "
               "Android Gradle plugin and the SDK platform (Google Maven, dl.google.com). Check the connection, the proxy or firewall, then "
               "export again; everything is cached after one successful build.";
    return {};
}

}  // namespace

Result<void> build_android(const ExportOptions& o, const Project& p, const MobileSetup& setup, const AndroidPlan& a,
                           const stdfs::path& outRoot, ExportReport& report, bool& keepOutput) {
    const std::string task = gradle_task(a);
    const std::string outputRel = gradle_outputs(a).front();
    const std::string wrapper = is_windows_host() ? "gradlew.bat" : "./gradlew";
    const std::string installPrereq = setup.prebuilt
        ? "Install the prerequisites once: a JDK 17+ and the Android SDK (Android Studio installs both) and give them to Gradle with JAVA_HOME and "
          "ANDROID_HOME (or open the folder in Android Studio). The engine is prebuilt (mode: prebuilt), so no NDK or CMake is needed"
        : "Install the prerequisites once: a JDK 17+ and the Android SDK (give them to Gradle with JAVA_HOME and ANDROID_HOME) with NDK r27+, CMake 3.31.6 "
          "and platform " + std::to_string(p.settings.android.targetSdk) + ": sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" \"platforms;android-" +
          std::to_string(p.settings.android.targetSdk) + "\" (Gradle also installs missing ones itself once the SDK licenses are accepted; mode: source, "
          "the engine is compiled from its checkout)";

    std::vector<std::string> steps;
    if (a.format == "gradle") {
        steps = {installPrereq,
                 "cd " + quote_path(generic(outRoot)),
                 wrapper + " " + task + (setup.prebuilt ? "   (nothing is compiled but the Java glue, so it is quick; the " + std::string(a.format == "aab" ? "bundle" : "APK") + " is "
                                                          : "   (first build compiles the whole engine; the file is ") + outputRel + ")",
                 "adb install -r " + outputRel +
                     (setup.prebuilt ? "  (the engine is " + generic(setup.libs / "jniLibs") + " copied to app/src/main/jniLibs)"
                                     : "  (the engine is located via factoria.engineDir in gradle.properties: " + generic(setup.engine) + ")")};
        if (o.release)
            steps.push_back("Release builds are signed with the keystore of export.android.signing (set FACTORIA_ANDROID_KEYSTORE_PASSWORD and "
                            "FACTORIA_ANDROID_KEY_PASSWORD first), or with the debug key when none is set; Google Play takes a bundle: " + wrapper +
                            " bundleRelease. See docs/MOBILE.md (Signing)");
        report.nextSteps.insert(report.nextSteps.begin(), steps.begin(), steps.end());
        return {};
    }

    // ---- run the project's own Gradle wrapper ----
    ProcessOptions po;
    if (is_windows_host()) po.argv = {"cmd.exe", "/c", "gradlew.bat", task, "--console=plain"};
    else po.argv = {generic(outRoot / "gradlew"), task, "--console=plain"};
    po.workingDir = generic(outRoot);
    po.env["JAVA_HOME"] = a.toolchain.jdk;
    po.env["ANDROID_HOME"] = a.toolchain.sdk;
    po.unsetEnv = {"ANDROID_SDK_ROOT"};  // the SDK found above is the one; the two variables must not disagree
    if (!a.keystore.empty() && o.release) {  // only as environment variables of this process: never in a file
        po.env["FACTORIA_ANDROID_KEYSTORE_PASSWORD"] = a.secrets.keystorePassword;
        po.env["FACTORIA_ANDROID_KEY_PASSWORD"] = a.secrets.keyPassword;
    }
    po.cancel = o.cancel;
    po.captureStdout = false;

    const stdfs::path logPath = outRoot / "build.log";
    std::ofstream log(logPath, std::ios::binary | std::ios::trunc);
    std::deque<std::string> tail;
    auto line = [&](std::string_view l) {
        // Gradle redraws its progress bars with a carriage return: keep what the terminal would end up showing.
        if (const std::size_t cr = l.rfind('\r'); cr != std::string_view::npos) l = l.substr(cr + 1);
        std::string s(l);
        if (log) log << s << '\n' << std::flush;
        tail.push_back(s);
        if (tail.size() > 400) tail.pop_front();
        if (o.progress) o.progress(s);
    };
    po.onStdoutLine = line;
    po.onStderrLine = line;
    const std::string startLine = std::string("Starting Gradle: ") + wrapper + " " + task + " (JDK " + a.toolchain.jdk + ", Android SDK " +
                                  a.toolchain.sdk + "). The first build downloads Gradle and the Android Gradle plugin" +
                                  (setup.prebuilt ? "" : " and compiles the engine for two ABIs") + ": it can take several minutes";
    line(startLine);

    keepOutput = true;  // from here on a failure leaves the Gradle project for the user to open
    auto run = run_process(po);
    const std::string kept = "The Gradle project stays in " + generic(outRoot) + ": open it in Android Studio, or run " + wrapper + " " + task +
                             " there.";
    if (!run.ok())
        return err("export: cannot start Gradle (" + generic(outRoot / "gradlew") + "): " + run.error().message + " " + kept,
                   run.error().hint.empty() ? "Check that the folder is writable and not mounted noexec." : run.error().hint);
    if (run->cancelled)
        return err("export: cancelled: the Android build was stopped. " + kept, "Export again to build it from where Gradle left off.");
    if (run->exitCode != 0) {
        const std::string failure = gradle_failure_text(tail);
        std::string hint = gradle_failure_hint(tail, failure, a);
        if (hint.empty())
            hint = "Read " + generic(logPath) + " (the whole Gradle output), or open the project in Android Studio to see the error in context; "
                   "adding --stacktrace to " + wrapper + " " + task + " shows more.";
        return err("export: the Gradle build failed (" + wrapper + " " + task + " exited with code " + std::to_string(run->exitCode) + "). What went wrong: " +
                       (failure.empty() ? "Gradle printed nothing" : failure) + " Full log: " + generic(logPath) + ". " + kept,
                   hint);
    }

    // ---- the result ----
    stdfs::path built;
    std::error_code ec;
    for (const std::string& rel : gradle_outputs(a))
        if (stdfs::is_regular_file(outRoot / rel, ec)) {
            built = outRoot / rel;
            break;
        }
    if (built.empty())
        return err("export: Gradle finished without errors but " + outputRel + " was not written. Full log: " + generic(logPath) + ". " + kept,
                   "Open the project in Android Studio and run the build there, or report this as an engine bug.");
    stdfs::copy_file(built, a.artifact, stdfs::copy_options::overwrite_existing, ec);
    if (ec) return err("export: cannot copy " + generic(built) + " to " + generic(a.artifact) + ": " + ec.message() + ". " + kept);
    keepOutput = false;
    if (built.filename().string().find("unsigned") != std::string::npos)
        report.warnings.push_back("The release app was built without a signature, so it cannot be installed or uploaded: sign it with apksigner, or set "
                                  "export.android.signing in factoria.json");
    report.artifact = generic(a.artifact);

    const std::string artifact = quote_path(generic(a.artifact));
    const std::string adb = adb_command(a);
    if (a.format == "apk") {
        steps.push_back("Install the app on a phone (USB debugging on) or a running emulator: " + adb + " install -r " + artifact);
        steps.push_back("Start it from the launcher; the log is " + adb + " logcat -s factoria");
        if (o.release)
            steps.push_back("Google Play takes an Android App Bundle, not an APK: factoria export --platform android --format aab --release");
    } else {
        steps.push_back(std::string("Upload ") + artifact + " to Google Play: Play Console > your app > Release > Create new release" +
                        (o.release && !a.keystore.empty() ? " (Play App Signing keeps the final key; this bundle is signed with your upload key)"
                                                          : " (Google Play only accepts a bundle signed with your own release key: this one is not)"));
        const std::string apks = quote_path(generic(outRoot / (slug_of(p) + ".apks")));
        steps.push_back("To try the bundle on a phone first, install bundletool (https://developer.android.com/tools/bundletool) and run: bundletool "
                        "build-apks --bundle=" + artifact + " --output=" + apks + " --connected-device" +
                        (o.release && !a.keystore.empty() ? " --ks=" + quote_path(a.keystore) + " --ks-key-alias=" + a.alias : std::string()) +
                        "; bundletool install-apks --apks=" + apks);
    }
    report.nextSteps.insert(report.nextSteps.begin(), steps.begin(), steps.end());
    return {};
}

}  // namespace fa::export_detail
