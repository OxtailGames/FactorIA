// Android export: the Gradle project from platforms/android (templates), the game in app/src/main/assets and, in prebuilt
// mode, the ready-made libfactoria_player.so of each ABI. The modes are described in export_internal.h.
#include <algorithm>
#include <cctype>
#include <filesystem>

#include "export_internal.h"

namespace fa::export_detail {

// ---- android -------------------------------------------------------------------------------------

namespace {

std::string version_code(const std::string& v) {
    long parts[3] = {0, 0, 0};
    int idx = 0;
    std::size_t i = 0;
    while (idx < 3 && i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) {
        long n = 0;
        while (i < v.size() && std::isdigit(static_cast<unsigned char>(v[i]))) n = std::min(n * 10 + (v[i++] - '0'), 99L);
        parts[idx++] = n;
        if (i < v.size() && v[i] == '.') ++i; else break;
    }
    long code = parts[0] * 10000 + parts[1] * 100 + parts[2];
    return std::to_string(code < 1 ? 1 : code);
}

bool is_text_template(const stdfs::path& p) {
    std::string e = p.extension().string();
    return e == ".gradle" || e == ".properties" || e == ".xml" || e == ".kts" || e == ".txt" || e == ".md";
}

}  // namespace

Result<void> export_android(const ExportOptions& o, const Project& p, const MobileSetup& setup, const stdfs::path& outRoot,
                            const std::vector<std::string>& files, ExportReport& report) {
    const std::string slug = slugify(p.name, '-').empty() ? "game" : slugify(p.name, '-');
    const std::string orient = p.orientation == "portrait" ? "sensorPortrait" : p.orientation == "any" ? "fullSensor" : "sensorLandscape";
    const std::vector<std::pair<std::string, std::string>> vars = {
        {"APPLICATION_ID", p.id},
        {"PROJECT_SLUG", slug},
        {"APP_NAME_XML", xml_escape(p.name, true)},
        {"VERSION_NAME", safe_version_name(p.version)},
        {"VERSION_CODE", version_code(p.version)},
        {"SCREEN_ORIENTATION", orient},
        {"ENGINE_ROOT", setup.prebuilt ? std::string() : generic(setup.engine)},
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
        } else if (auto r = write_text(to, t.data); !r.ok()) {
            return r;
        }
    }
    std::error_code ec;
    if (setup.prebuilt)
        for (const char* abi : kAndroidAbis) {
            const stdfs::path to = outRoot / "app" / "src" / "main" / "jniLibs" / abi / "libfactoria_player.so";
            stdfs::create_directories(to.parent_path(), ec);
            stdfs::copy_file(setup.libs / "jniLibs" / abi / "libfactoria_player.so", to, stdfs::copy_options::overwrite_existing, ec);
            if (ec) return err(std::string("export: cannot copy the prebuilt ") + abi + " player to " + generic(to) + ": " + ec.message());
        }
    stdfs::path assets = outRoot / "app" / "src" / "main" / "assets";
    if (auto r = copy_game(p, files, assets); !r.ok()) return r;
    std::string index;
    for (auto& f : files) index += f + "\n";
    if (auto r = write_text(assets / "assets_index.txt", index); !r.ok()) return r;

    const std::string task = o.release ? "assembleRelease" : "assembleDebug";
    const std::string apk = o.release ? "app/build/outputs/apk/release/app-release-unsigned.apk" : "app/build/outputs/apk/debug/app-debug.apk";
    const std::string wrapper = "Create the Gradle wrapper once (needs Gradle 8.7+ installed; Android Studio does this itself): gradle wrapper --gradle-version 8.7";
    report.nextSteps = {
        setup.prebuilt ? "Install the prerequisites once: JDK 17 and the Android SDK (set ANDROID_SDK_ROOT) with platform 34: sdkmanager "
                         "\"platforms;android-34\" \"build-tools;34.0.0\". The engine is prebuilt (mode: prebuilt), so no NDK or CMake is needed"
                       : "Install the prerequisites once: JDK 17, the Android SDK (set ANDROID_SDK_ROOT) with NDK r27+, CMake 3.31.6 and "
                         "platform 34: sdkmanager \"ndk;27.2.12479018\" \"cmake;3.31.6\" \"platforms;android-34\" \"build-tools;34.0.0\" "
                         "(mode: source, the engine is compiled from its checkout)",
        "cd '" + generic(outRoot) + "'",
        wrapper,
        "./gradlew " + task +
            (setup.prebuilt ? "   (nothing is compiled but the Java glue, so it is quick; the APK is " : "   (first build compiles the whole engine; the APK is ") +
            apk + ")",
        "adb install -r " + apk +
            (setup.prebuilt ? "  (the engine is " + generic(setup.libs / "jniLibs") + " copied to app/src/main/jniLibs)"
                            : "  (the engine is located via factoria.engineDir in gradle.properties: " + generic(setup.engine) + ")"),
    };
    if (o.release) report.nextSteps.push_back("Release builds must be signed: see docs/MOBILE.md (Signing) for the keystore setup, or use ./gradlew bundleRelease for Google Play");
    return {};
}

}  // namespace fa::export_detail
