// The Platform settings window's logic (platform_settings.h): the working copy and its validation, Save / Revert, factoria.json
// changing on disk, icon files and picking one, this computer's settings, the Android toolchain, and the keystore.
// GPU-free: a scaffolded project in a temporary folder, a machine config file there, and a stand-in keytool script.
#include <algorithm>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <thread>

#include "doctest.h"
#include "editor_internal.h"

using namespace fa;
using namespace fa::editor;
namespace stdfs = std::filesystem;

namespace {

std::string read_file_text(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

void write_file_text(const stdfs::path& p, const std::string& text) {
    stdfs::create_directories(p.parent_path());
    std::ofstream(p, std::ios::binary) << text;
}

// Another modification time, so a "file changed on disk" check sees a write even on a coarse file system clock.
void touch_later(const stdfs::path& p, int seconds = 5) {
    std::error_code ec;
    stdfs::last_write_time(p, stdfs::last_write_time(p, ec) + std::chrono::seconds(seconds), ec);
}

struct SettingsProject {
    stdfs::path root, dir, machine;
    explicit SettingsProject(const std::string& name) {
        root = fs::make_temp_dir("fa_editor_platform_" + name);
        ScaffoldOptions so;
        so.name = "Settings Test";
        so.id = "com.example.settingstest";
        auto r = create_project((root / "game").string(), "2d-empty", so);
        REQUIRE_MESSAGE(r.ok(), (r.ok() ? "" : r.error().to_string()));
        dir = stdfs::weakly_canonical(r->dir);
        machine = root / "home" / "export.json";
    }
    ~SettingsProject() {
        std::error_code ec;
        stdfs::remove_all(root, ec);
    }
    stdfs::path factoria() const { return dir / "factoria.json"; }
    PlatformSettings load() const {
        PlatformSettings ps;
        ps.env = [](const std::string&) { return std::string(); };  // no FACTORIA_ANDROID_* variables from the test machine
        ps.load(dir.string(), machine.string());
        return ps;
    }
    // A square picture of the given size inside the project (or anywhere: `path` is absolute).
    static void picture(const stdfs::path& path, int w, int h) {
        Image img;
        img.width = w;
        img.height = h;
        img.rgba.assign(size_t(w) * size_t(h) * 4, 200);
        stdfs::create_directories(path.parent_path());
        REQUIRE(save_png(img, path.string()).ok());
    }
};

bool has_pointer(const std::vector<ExportSettingsIssue>& list, const std::string& pointer) {
    return std::any_of(list.begin(), list.end(), [&](const ExportSettingsIssue& i) { return i.pointer == pointer; });
}

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("platform settings: one tab per platform after General, and the lists the combos offer") {
    CHECK(kSettingsTabCount == 6);
    CHECK(std::string(settings_tab_label(SettingsTab::General)) == "General");
    CHECK(std::string(settings_tab_label(SettingsTab::Macos)) == "macOS");
    CHECK(std::string(settings_tab_platform(SettingsTab::General)).empty());
    for (int i = 1; i < kSettingsTabCount; ++i) {
        const SettingsTab tab = static_cast<SettingsTab>(i);
        CHECK(normalize_export_platform(settings_tab_platform(tab)) == settings_tab_platform(tab));  // a name export_project knows
        CHECK(settings_tab_for_platform(settings_tab_platform(tab)) == tab);
    }
    CHECK(settings_tab_for_platform("Mac") == SettingsTab::Macos);
    CHECK(settings_tab_for_platform("win") == SettingsTab::Windows);
    CHECK_FALSE(settings_tab_for_platform("amiga").has_value());
    CHECK(settings_tab_for_platform("") == settings_tab_for_platform(normalize_export_platform("")));  // "" = this machine's

    std::vector<std::string> formats;
    for (const SettingsChoice& c : android_formats()) formats.push_back(c.value);
    CHECK(formats == std::vector<std::string>{"apk", "aab", "gradle"});
    for (const SettingsChoice& c : android_formats()) CHECK_FALSE(std::string(c.note).empty());
    CHECK(find_choice(mac_game_categories(), "public.app-category.games") != nullptr);
    CHECK(find_choice(mac_game_categories(), "public.app-category.puzzle-games") != nullptr);
    CHECK(find_choice(mac_game_categories(), "public.app-category.finance") == nullptr);
    for (const SettingsChoice& c : mac_game_categories()) CHECK(std::string(c.value).rfind("public.app-category.", 0) == 0);
    CHECK(find_choice(linux_game_categories(), "Game") != nullptr);
}

TEST_CASE("platform settings: small helpers") {
    CHECK(clean_project_path("  assets\\icons\\icon.png ") == "assets/icons/icon.png");
    CHECK(rgb_hex(1, 1, 1) == "#FFFFFF");
    CHECK(rgb_hex(0, 0, 0) == "#000000");
    CHECK(rgb_hex(1.0f, 0.5f, 0.0f) == "#FF8000");
    CHECK(rgb_hex(2, -1, 0.2f) == "#FF0033");  // out of range is clamped

    SettingsProject p("helpers");
    CHECK(project_relative_or_absolute(p.dir.string(), (p.dir / "keys" / "a.keystore").string()) == "keys/a.keystore");
    const std::string outside = (p.root / "elsewhere" / "a.keystore").generic_string();
    CHECK(project_relative_or_absolute(p.dir.string(), outside) == stdfs::weakly_canonical(outside).generic_string());
}

TEST_CASE("platform settings: a fresh load has nothing to save and shows the game's own keys") {
    SettingsProject p("load");
    PlatformSettings ps = p.load();
    CHECK(ps.loaded());
    CHECK(ps.fileError.empty());
    CHECK(ps.parseErrors.empty());
    CHECK(ps.machineError.empty());
    CHECK_FALSE(ps.dirty());
    CHECK(ps.info.name == "Settings Test");
    CHECK(ps.info.id == "com.example.settingstest");
    CHECK_FALSE(ps.info.version.empty());
    CHECK(ps.info.orientation == "landscape");
    CHECK(ps.info.width > 0);
    CHECK(ps.validate().errors.empty());
    CHECK(ps.project.android.format == "apk");
    CHECK(ps.machine_path() == p.machine.string());

    ps.clear();
    CHECK_FALSE(ps.loaded());
    CHECK_FALSE(ps.dirty());
}

TEST_CASE("platform settings: edits are dirty, Save writes factoria.json and nothing else, Revert forgets them") {
    SettingsProject p("save");
    const std::string before = read_file_text(p.factoria());
    PlatformSettings ps = p.load();
    ps.project.icon = "assets/icon.png";
    ps.project.android.minSdk = 28;
    ps.project.android.targetSdk = 35;
    ps.project.android.versionCode = 7;
    ps.project.android.format = "aab";
    ps.project.android.permissions = {"android.permission.VIBRATE"};
    ps.project.android.signing.keystore = "keys/upload.keystore";
    ps.project.android.signing.alias = "upload";
    ps.project.android.adaptiveIcon.background = "#202020";
    ps.project.macos.category = "public.app-category.puzzle-games";
    ps.project.macos.copyright = "Copyright 2026 Test";
    ps.project.linux.categories = {"Game", "ArcadeGame"};
    ps.project.ios.teamId = "ABCDE12345";
    ps.project.ios.iconBackground = "#102030";
    CHECK(ps.project_dirty());
    CHECK(ps.dirty());
    CHECK(read_file_text(p.factoria()) == before);  // editing writes nothing

    // Revert forgets all of it.
    PlatformSettings reverted = p.load();
    reverted.project = ps.project;
    REQUIRE(reverted.dirty());
    reverted.revert();
    CHECK_FALSE(reverted.dirty());
    CHECK(reverted.project.android.minSdk == 26);
    CHECK(reverted.project.icon.empty());

    REQUIRE(ps.validate().errors.empty());
    auto saved = ps.save();
    REQUIRE_MESSAGE(saved.ok(), (saved.ok() ? "" : saved.error().to_string()));
    CHECK_FALSE(ps.dirty());

    auto back = load_export_settings(p.dir.string());
    REQUIRE(back.ok());
    CHECK(back->icon == "assets/icon.png");
    CHECK(back->android.format == "aab");
    CHECK(back->android.minSdk == 28);
    CHECK(back->android.targetSdk == 35);
    CHECK(back->android.versionCode == 7);
    CHECK(back->android.permissions == std::vector<std::string>{"android.permission.VIBRATE"});
    CHECK(back->android.signing.keystore == "keys/upload.keystore");
    CHECK(back->android.signing.alias == "upload");
    CHECK(back->android.adaptiveIcon.background == "#202020");
    CHECK(back->macos.category == "public.app-category.puzzle-games");
    CHECK(back->macos.copyright == "Copyright 2026 Test");
    CHECK(back->linux.categories == std::vector<std::string>{"Game", "ArcadeGame"});
    CHECK(back->ios.teamId == "ABCDE12345");
    CHECK(back->ios.iconBackground == "#102030");

    // Everything else in the file is untouched.
    const std::string after = read_file_text(p.factoria());
    CHECK(after.find("\"name\": \"Settings Test\"") != std::string::npos);
    CHECK(after.find("\"id\": \"com.example.settingstest\"") != std::string::npos);
    auto json = parse_json(after, "factoria.json");
    REQUIRE(json.ok());
    CHECK((*json)["name"] == "Settings Test");

    // Setting everything back to its default removes the keys again.
    PlatformSettings again = p.load();
    again.project = PlatformSettings().project;
    again.project.projectVersion = ps.project.projectVersion;
    CHECK(again.project_dirty());
    REQUIRE(again.save().ok());
    auto cleared = parse_json(read_file_text(p.factoria()), "factoria.json");
    REQUIRE(cleared.ok());
    CHECK_FALSE(cleared->contains("icon"));
    CHECK_FALSE(cleared->contains("export"));
}

TEST_CASE("platform settings: an empty field that means its default is not an edit") {
    SettingsProject p("defaults");
    PlatformSettings ps = p.load();
    ps.project.macos.category.clear();                // empty = public.app-category.games
    ps.project.macos.minimumSystemVersion = "  ";     // blanks = 11.0
    ps.project.ios.iconBackground.clear();            // empty = #FFFFFF
    ps.project.android.adaptiveIcon.background = "";  // empty = #FFFFFF
    ps.project.linux.categories = {"Game", "", "  "}; // blank entries are dropped
    ps.project.android.permissions = {"", " "};
    CHECK_FALSE(ps.project_dirty());
    CHECK(ps.validate().errors.empty());
    const ProjectExportSettings eff = ps.effective_project();
    CHECK(eff.macos.category == "public.app-category.games");
    CHECK(eff.macos.minimumSystemVersion == "11.0");
    CHECK(eff.ios.iconBackground == "#FFFFFF");
    CHECK(eff.linux.categories == std::vector<std::string>{"Game"});

    ps.project.android.signing.alias = "  upload ";  // blanks around text are not part of it
    CHECK(ps.effective_project().android.signing.alias == "upload");
    CHECK(ps.project_dirty());
}

TEST_CASE("platform settings: wrong values are errors with the pointer of their field, and Save refuses them") {
    SettingsProject p("validate");
    PlatformSettings ps = p.load();
    ps.project.android.minSdk = 20;
    ps.project.android.targetSdk = 36;
    ps.project.macos.minimumSystemVersion = "10.15";
    ps.project.ios.teamId = "abc";
    ps.project.ios.iconBackground = "red";
    ps.project.icon = "/Users/me/icon.png";
    ps.project.windows.icon = "../icon.png";
    ps.project.linux.categories = {"Game;Other"};
    ps.project.android.permissions = {"VIBRATE"};
    ps.project.android.adaptiveIcon.background = "#12";
    ps.project.ios.buildNumber = "1.2.3.4";
    const SettingsProblems problems = ps.validate();
    for (const char* pointer : {"/export/android/minSdk", "/export/macos/minimumSystemVersion", "/export/ios/teamId", "/export/ios/iconBackground",
                                "/icon", "/export/windows/icon", "/export/linux/categories/0", "/export/android/permissions/0",
                                "/export/android/adaptiveIcon/background", "/export/ios/buildNumber"}) {
        const ExportSettingsIssue* e = problems.error_for(pointer);
        INFO(pointer);
        REQUIRE(e != nullptr);
        CHECK_FALSE(e->message.empty());
        CHECK_FALSE(e->hint.empty());  // every error says how to fix it
    }
    CHECK(problems.error_for("/export/android/targetSdk") == nullptr);

    const std::string before = read_file_text(p.factoria());
    auto r = ps.save();
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("Cannot save") != std::string::npos);
    CHECK_FALSE(r.error().hint.empty());
    CHECK(read_file_text(p.factoria()) == before);  // nothing was written
    CHECK(ps.dirty());

    // minSdk above targetSdk is caught like the export does.
    PlatformSettings order = p.load();
    order.project.android.minSdk = 34;
    order.project.android.targetSdk = 30;
    CHECK(order.validate().error_for("/export/android/minSdk") != nullptr);

    // A keystore without an alias (and the reverse) is a warning, shown next to the field.
    PlatformSettings sign = p.load();
    sign.project.android.signing.keystore = "keys/a.keystore";
    CHECK(sign.validate().errors.empty());
    CHECK(sign.validate().warning_for("/export/android/signing/alias") != nullptr);
    sign.project.android.signing.alias = "a";
    CHECK(sign.validate().warnings.empty());
}

TEST_CASE("platform settings: a hand-edited file opens with its errors listed, and an unreadable one cannot be saved over") {
    SettingsProject p("badfile");
    // Wrong value in the file: the window still opens, the error is listed with its pointer.
    {
        std::string json = read_file_text(p.factoria());
        const size_t brace = json.rfind('}');
        json.insert(brace, ",\n  \"export\": { \"android\": { \"minSdk\": \"old\" }, \"macoss\": {} }\n");
        write_file_text(p.factoria(), json);
    }
    PlatformSettings ps = p.load();
    CHECK(ps.fileError.empty());
    CHECK(has_pointer(ps.parseErrors, "/export/android/minSdk"));
    CHECK(has_pointer(ps.parseWarnings, "/export/macoss"));  // unknown key
    bool didYouMean = false;
    for (const auto& w : ps.parseWarnings) didYouMean = didYouMean || w.hint.find("macos") != std::string::npos;
    CHECK(didYouMean);
    CHECK(ps.project.android.minSdk == 26);  // the field that could not be read keeps its default

    // Not JSON at all.
    write_file_text(p.factoria(), "{ this is not json");
    PlatformSettings broken = p.load();
    CHECK_FALSE(broken.fileError.empty());
    CHECK(broken.loaded());
    broken.project.icon = "assets/icon.png";
    auto r = broken.save();
    REQUIRE_FALSE(r.ok());
    CHECK(r.error().message.find("factoria.json") != std::string::npos);
    CHECK(read_file_text(p.factoria()) == "{ this is not json");  // never written over
}

TEST_CASE("platform settings: factoria.json changing on disk is noticed") {
    SettingsProject p("disk");
    PlatformSettings ps = p.load();
    CHECK_FALSE(ps.project_file_changed());
    std::string json = read_file_text(p.factoria());
    const size_t brace = json.rfind('}');
    json.insert(brace, ",\n  \"icon\": \"assets/ai-made.png\"\n");
    write_file_text(p.factoria(), json);
    touch_later(p.factoria());
    CHECK(ps.project_file_changed());
    ps.project.android.minSdk = 30;  // an unsaved edit is untouched by noticing...
    CHECK(ps.project_file_changed());
    ps.reload_project();             // ...and gone when the file is read again
    CHECK_FALSE(ps.project_file_changed());
    CHECK(ps.project.icon == "assets/ai-made.png");
    CHECK(ps.project.android.minSdk == 26);
    CHECK_FALSE(ps.dirty());

    // Our own Save is not "a change on disk".
    ps.project.android.minSdk = 29;
    REQUIRE(ps.save().ok());
    CHECK_FALSE(ps.project_file_changed());
}

TEST_CASE("platform settings: the Export window's format follows into the working copy") {
    SettingsProject p("format");
    CHECK(save_android_format(p.dir.string(), "aab").ok());
    CHECK(load_export_settings(p.dir.string())->android.format == "aab");
    CHECK(save_android_format(p.dir.string(), "aab").ok());  // already so: nothing to write
    auto bad = save_android_format(p.dir.string(), "zip");
    REQUIRE_FALSE(bad.ok());
    CHECK_FALSE(bad.error().hint.empty());
    CHECK(save_android_format(p.dir.string(), "apk").ok());
    CHECK_FALSE(parse_json(read_file_text(p.factoria()), "f")->contains("export"));  // the default is not written

    // No pending edits: the whole copy is read again.
    PlatformSettings ps = p.load();
    REQUIRE(save_android_format(p.dir.string(), "gradle").ok());
    ps.note_saved_android_format("gradle");
    CHECK(ps.project.android.format == "gradle");
    CHECK_FALSE(ps.dirty());

    // Pending edits stay; only the format moves, and the file is not seen as changed behind our back.
    ps.project.android.minSdk = 31;
    REQUIRE(save_android_format(p.dir.string(), "aab").ok());
    ps.note_saved_android_format("aab");
    CHECK(ps.project.android.format == "aab");
    CHECK(ps.project.android.minSdk == 31);
    CHECK(ps.project_dirty());
    CHECK_FALSE(ps.project_file_changed());
    REQUIRE(ps.save().ok());
    auto back = load_export_settings(p.dir.string());
    CHECK(back->android.format == "aab");
    CHECK(back->android.minSdk == 31);
}

TEST_CASE("platform settings: this computer's settings are saved on their own, passwords only when remembered") {
    SettingsProject p("machine");
    PlatformSettings ps = p.load();
    CHECK_FALSE(ps.rememberPasswords);
    ps.machine.androidJdk = "/opt/jdk17";
    ps.machine.androidSdk = "/opt/sdk";
    CHECK(ps.machine_dirty());
    CHECK_FALSE(ps.project_dirty());
    const std::string before = read_file_text(p.factoria());
    REQUIRE(ps.save().ok());
    CHECK(read_file_text(p.factoria()) == before);  // only export.json was written
    CHECK_FALSE(ps.dirty());
    auto file = load_machine_export_config(p.machine.string());
    REQUIRE(file.ok());
    CHECK(file->androidJdk == "/opt/jdk17");
    CHECK(file->androidSdk == "/opt/sdk");

    // Passwords typed but not remembered are not written.
    ps.machine.androidKeystorePassword = "s3cret-store";
    ps.machine.androidKeyPassword = "s3cret-key";
    CHECK_FALSE(ps.machine_dirty());
    ps.rememberPasswords = true;
    CHECK(ps.machine_dirty());
    REQUIRE(ps.save().ok());
    CHECK_FALSE(ps.dirty());
    const std::string written = read_file_text(p.machine);
    CHECK(written.find("s3cret-store") != std::string::npos);
    PlatformSettings reread = p.load();
    CHECK(reread.rememberPasswords);  // a file with passwords loads as "remembered"
    CHECK(reread.machine.androidKeystorePassword == "s3cret-store");

    // Un-ticking Remember removes them from the file.
    reread.rememberPasswords = false;
    CHECK(reread.machine_dirty());
    REQUIRE(reread.save().ok());
    const std::string removed = read_file_text(p.machine);
    CHECK(removed.find("s3cret") == std::string::npos);
    CHECK(removed.find("/opt/jdk17") != std::string::npos);

    // An unreadable file is shown, and the window still works with defaults.
    write_file_text(p.machine, "[1, 2");
    PlatformSettings broken = p.load();
    CHECK_FALSE(broken.machineError.empty());
    CHECK_FALSE(broken.dirty());
}

TEST_CASE("platform settings: where each signing password comes from, never its value") {
    SettingsProject p("secrets");
    PlatformSettings ps = p.load();
    SecretStatus ks = ps.keystore_password_status();
    CHECK_FALSE(ks.set);
    CHECK(ks.text == "Not set");
    CHECK_FALSE(ps.key_password_status().set);

    ps.rememberPasswords = true;
    ps.machine.androidKeystorePassword = "hunter22";
    ks = ps.keystore_password_status();
    CHECK(ks.set);
    CHECK(ks.from == "export.json");
    CHECK(ks.text.find("this computer") != std::string::npos);
    CHECK(ks.text.find("hunter22") == std::string::npos);
    const SecretStatus ky = ps.key_password_status();  // no key password: the keystore's
    CHECK(ky.set);
    CHECK(ky.text.find("keystore password") != std::string::npos);

    // Not remembered: the typed password is not what an export would find.
    ps.rememberPasswords = false;
    CHECK_FALSE(ps.keystore_password_status().set);

    // The environment wins.
    ps.rememberPasswords = true;
    ps.env = [](const std::string& name) { return name == "FACTORIA_ANDROID_KEYSTORE_PASSWORD" ? std::string("from-env") : std::string(); };
    ks = ps.keystore_password_status();
    CHECK(ks.from == "FACTORIA_ANDROID_KEYSTORE_PASSWORD");
    CHECK(ks.text.find("FACTORIA_ANDROID_KEYSTORE_PASSWORD") != std::string::npos);
    CHECK(ks.text.find("from-env") == std::string::npos);
}

TEST_CASE("platform settings: the Android toolchain the working settings find") {
    SettingsProject p("toolchain");
    const stdfs::path jdk = p.root / "tools" / "jdk17", sdk = p.root / "tools" / "sdk";
    write_file_text(jdk / "bin" / "java", "");
    write_file_text(jdk / "bin" / "javac", "");
    write_file_text(jdk / "release", "JAVA_VERSION=\"17.0.9\"\n");
    stdfs::create_directories(sdk / "platform-tools");

    PlatformSettings ps = p.load();
    AndroidToolchainSearch search;
    search.env = [](const std::string&) { return std::string(); };
    ps.toolchainSearch = search;
    CHECK_FALSE(ps.toolchain().ok());  // nothing configured, nothing to look at
    CHECK_FALSE(ps.toolchain().problems.empty());

    ps.machine.androidJdk = jdk.string();
    ps.machine.androidSdk = sdk.string();
    const AndroidToolchain& tc = ps.toolchain();  // the settings changed: searched again by itself
    CHECK(tc.ok());
    CHECK(tc.jdk == jdk.string());
    CHECK(tc.jdkMajor == 17);
    CHECK(tc.jdkFrom == "config");
    CHECK(tc.sdk == sdk.string());

    ps.machine.androidJdk = (p.root / "nowhere").string();
    CHECK_FALSE(ps.toolchain().ok());  // a folder that is not a JDK is the problem
    ps.machine.androidJdk = jdk.string();
    CHECK(ps.toolchain().ok());
    stdfs::remove_all(sdk);
    CHECK(ps.toolchain().ok());          // cached: the folders are looked at again on request...
    CHECK_FALSE(ps.toolchain(true).ok());  // ...and the SDK is gone
}

TEST_CASE("platform settings: the keystore the signing setting names") {
    SettingsProject p("keystorepath");
    PlatformSettings ps = p.load();
    CHECK(ps.keystore_path().empty());
    CHECK_FALSE(ps.keystore_exists());
    ps.project.android.signing.keystore = "keys\\up.keystore";
    CHECK(ps.keystore_path() == (p.dir / "keys" / "up.keystore").generic_string());
    CHECK_FALSE(ps.keystore_exists());
    write_file_text(p.dir / "keys" / "up.keystore", "x");
    CHECK(ps.keystore_exists());
    const stdfs::path outside = p.root / "safe" / "up.keystore";
    write_file_text(outside, "x");
    ps.project.android.signing.keystore = outside.generic_string();
    CHECK(ps.keystore_path() == outside.lexically_normal().generic_string());
    CHECK(ps.keystore_exists());
}

TEST_CASE("platform settings: derived defaults are shown with the value the export will use") {
    SettingsProject p("derived");
    PlatformSettings ps = p.load();
    ps.project.projectVersion = "1.2.3";
    CHECK(ps.derived_version_code() == 10203);
    ps.project.android.versionCode = 42;
    CHECK(ps.derived_version_code() == 42);
}

// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("icons: a picture is checked for what an export would complain about") {
    SettingsProject p("icons");
    SettingsProject::picture(p.dir / "assets" / "good.png", 600, 600);
    SettingsProject::picture(p.dir / "assets" / "small.png", 300, 300);
    SettingsProject::picture(p.dir / "assets" / "wide.png", 700, 600);
    SettingsProject::picture(p.dir / "build" / "icon.png", 600, 600);
    write_file_text(p.dir / "assets" / "broken.png", "not a picture");

    IconCheck none = check_icon(p.dir.string(), "");
    CHECK_FALSE(none.set);
    CHECK_FALSE(none.loaded);

    IconCheck good = check_icon(p.dir.string(), "assets/good.png");
    CHECK(good.set);
    CHECK(good.loaded);
    CHECK(good.size == 600);
    CHECK(good.error.empty());
    CHECK(good.warnings.empty());

    IconCheck small = check_icon(p.dir.string(), "assets\\small.png");  // backslashes are fine
    CHECK(small.loaded);
    REQUIRE(small.warnings.size() == 1);
    CHECK(small.warnings[0].find("smaller than 512") != std::string::npos);
    CHECK(check_icon(p.dir.string(), "assets/small.png", 256).warnings.empty());  // the size that is recommended is a parameter

    IconCheck wide = check_icon(p.dir.string(), "assets/wide.png");
    CHECK(wide.loaded);
    CHECK(wide.size == 700);  // the square it is centered on
    REQUIRE(wide.warnings.size() == 1);
    CHECK(wide.warnings[0].find("not square") != std::string::npos);

    IconCheck missing = check_icon(p.dir.string(), "assets/gud.png");
    CHECK(missing.set);
    CHECK_FALSE(missing.loaded);
    CHECK(missing.error.find("does not exist") != std::string::npos);
    CHECK(missing.error.find("good.png") != std::string::npos);  // did you mean
    CHECK(missing.error.find("factoria.json#") == std::string::npos);  // no location noise in the window

    CHECK(check_icon(p.dir.string(), "assets/broken.png").error.find("cannot use") != std::string::npos);
    CHECK(check_icon(p.dir.string(), "/etc/hosts").error.find("not inside the project") != std::string::npos);
    CHECK(check_icon(p.dir.string(), "../x.png").error.find("not inside the project") != std::string::npos);

    // A folder the export does not ship: the window icon read from the shipped game would be missing.
    IconCheck unshipped = check_icon(p.dir.string(), "build/icon.png");
    CHECK(unshipped.loaded);
    REQUIRE(unshipped.warnings.size() == 1);
    CHECK(unshipped.warnings[0].find("does not ship") != std::string::npos);
}

TEST_CASE("icons: a check is repeated only when the file changed") {
    SettingsProject p("iconcache");
    const stdfs::path file = p.dir / "assets" / "icon.png";
    IconChecks checks;
    const IconCheck& first = checks.get(p.dir.string(), "assets/icon.png", 512, 0.0);
    CHECK_FALSE(first.loaded);  // not there yet
    SettingsProject::picture(file, 600, 600);
    CHECK_FALSE(checks.get(p.dir.string(), "assets/icon.png", 512, 0.1).loaded);  // too soon to look again
    const IconCheck& found = checks.get(p.dir.string(), "assets/icon.png", 512, 1.0);
    CHECK(found.loaded);
    CHECK(found.size == 600);
    SettingsProject::picture(file, 700, 700);  // replaced (the AI made another one)
    touch_later(file);
    CHECK(checks.get(p.dir.string(), "assets/icon.png", 512, 2.0).size == 700);
    CHECK(checks.get(p.dir.string(), "", 512, 2.0).set == false);
}

TEST_CASE("icons: choosing a file inside the project keeps its path, outside copies it into assets/") {
    SettingsProject p("import");
    SettingsProject::picture(p.dir / "art" / "logo.png", 512, 512);
    auto inside = import_icon_file(p.dir.string(), (p.dir / "art" / "logo.png").string());
    REQUIRE(inside.ok());
    CHECK(inside->relPath == "art/logo.png");
    CHECK_FALSE(inside->copied);
    CHECK(inside->note.empty());

    const stdfs::path outside = p.root / "downloads" / "icon.png";
    SettingsProject::picture(outside, 1024, 1024);
    auto copied = import_icon_file(p.dir.string(), outside.string());
    REQUIRE(copied.ok());
    CHECK(copied->relPath == "assets/icon.png");
    CHECK(copied->copied);
    CHECK(copied->note.find("assets/icon.png") != std::string::npos);
    CHECK(stdfs::exists(p.dir / "assets" / "icon.png"));
    CHECK(read_file_text(p.dir / "assets" / "icon.png") == read_file_text(outside));

    // The very same file again is reused, a different one with the same name gets another name: nothing is overwritten.
    auto same = import_icon_file(p.dir.string(), outside.string());
    REQUIRE(same.ok());
    CHECK(same->relPath == "assets/icon.png");
    CHECK_FALSE(same->copied);
    const stdfs::path other = p.root / "other" / "icon.png";
    SettingsProject::picture(other, 800, 800);
    auto renamed = import_icon_file(p.dir.string(), other.string());
    REQUIRE(renamed.ok());
    CHECK(renamed->relPath == "assets/icon-2.png");
    CHECK(renamed->copied);
    CHECK(read_file_text(p.dir / "assets" / "icon.png") == read_file_text(outside));

    // Not an image, or not a file.
    write_file_text(p.root / "downloads" / "notes.txt", "hello");
    auto text = import_icon_file(p.dir.string(), (p.root / "downloads" / "notes.txt").string());
    REQUIRE_FALSE(text.ok());
    CHECK(text.error().message.find("not a PNG or JPG") != std::string::npos);
    CHECK_FALSE(text.error().hint.empty());
    CHECK_FALSE(import_icon_file(p.dir.string(), (p.root / "downloads" / "gone.png").string()).ok());
    CHECK_FALSE(import_icon_file(p.dir.string(), "").ok());
}

// ---------------------------------------------------------------------------------------------------------------------

TEST_CASE("keystore: the certificate name escapes what is special in it") {
    KeystoreRequest r;
    r.name = "Jane Doe";
    CHECK(distinguished_name(r) == "CN=Jane Doe");
    r.name = "Doe, Jane";
    r.organization = "Games; Inc";
    r.country = "es";
    CHECK(distinguished_name(r) == "CN=Doe\\, Jane, O=Games\\; Inc, C=es");
    r.name = "A \"quoted\" + name";
    r.organization.clear();
    r.country.clear();
    CHECK(distinguished_name(r) == "CN=A \\\"quoted\\\" \\+ name");
}

TEST_CASE("keystore: every problem with a request says how to fix it") {
    SettingsProject p("keystorecheck");
    const stdfs::path jdk = p.root / "jdk";
#ifdef _WIN32
    write_file_text(jdk / "bin" / "keytool.exe", "");
#else
    write_file_text(jdk / "bin" / "keytool", "");
#endif
    KeystoreRequest ok;
    ok.jdk = jdk.string();
    ok.path = (p.root / "keys" / "up.keystore").string();
    ok.password = "secret1";
    ok.name = "Jane Doe";
    CHECK(check_keystore_request(ok).empty());

    auto bad = [&](auto change, const std::string& mention) {
        KeystoreRequest r = ok;
        change(r);
        const std::string why = check_keystore_request(r);
        INFO(mention);
        CHECK(why.find(mention) != std::string::npos);
    };
    bad([](KeystoreRequest& r) { r.jdk.clear(); }, "No JDK");
    bad([&](KeystoreRequest& r) { r.jdk = (p.root / "nojdk").string(); }, "keytool is not in");
    bad([](KeystoreRequest& r) { r.path.clear(); }, "Choose where");
    bad([](KeystoreRequest& r) { r.path = "keys/up.keystore"; }, "must be absolute");
    bad([](KeystoreRequest& r) { r.alias = "  "; }, "alias");
    bad([](KeystoreRequest& r) { r.password = "short"; }, "at least 6");
    bad([](KeystoreRequest& r) { r.name = ""; }, "name");
    bad([](KeystoreRequest& r) { r.country = "Spain"; }, "two-letter");
    write_file_text(p.root / "keys" / "taken.keystore", "x");
    bad([&](KeystoreRequest& r) { r.path = (p.root / "keys" / "taken.keystore").string(); }, "already exists");

    // From the form: the path is resolved against the project and the passwords must match.
    KeystoreForm form = default_keystore_form(p.dir.string());
    CHECK(form.path == "keys/upload.keystore");
    form.password = "secret1";
    form.repeat = "secret2";
    form.name = "Jane Doe";
    auto mismatch = make_keystore_request(form, p.dir.string(), jdk.string());
    REQUIRE_FALSE(mismatch.ok());
    CHECK(mismatch.error().message.find("different") != std::string::npos);
    form.repeat = "secret1";
    auto fine = make_keystore_request(form, p.dir.string(), jdk.string());
    REQUIRE_MESSAGE(fine.ok(), (fine.ok() ? "" : fine.error().message));
    CHECK(fine->path == (p.dir / "keys" / "upload.keystore").lexically_normal().generic_string());
    CHECK(fine->alias == "upload");
    write_file_text(p.dir / "keys" / "upload.keystore", "x");
    CHECK(default_keystore_form(p.dir.string()).path == "keys/upload-2.keystore");  // never offers an existing file
}

TEST_CASE("keystore: the password reaches keytool through its environment, never its command line") {
    SettingsProject p("keytoolcmd");
    const stdfs::path jdk = p.root / "jdk";
#ifdef _WIN32
    write_file_text(jdk / "bin" / "keytool.exe", "");
#else
    write_file_text(jdk / "bin" / "keytool", "");
#endif
    KeystoreRequest r;
    r.jdk = jdk.string();
    r.path = (p.root / "up.keystore").string();
    r.alias = "upload";
    r.password = "p4ssw0rd-xyz";
    r.name = "Jane Doe";
    r.organization = "My Studio";
    auto cmd = make_keytool_command(r);
    REQUIRE_MESSAGE(cmd.ok(), (cmd.ok() ? "" : cmd.error().message));
    const auto has = [&](const std::string& a) { return std::find(cmd->argv.begin(), cmd->argv.end(), a) != cmd->argv.end(); };
    CHECK(has("-genkeypair"));
    CHECK(has("-storepass:env"));
    CHECK(has("-keypass:env"));
    CHECK(has("RSA"));
    CHECK(has("2048"));
    CHECK(has("10000"));
    CHECK(has("CN=Jane Doe, O=My Studio"));
    CHECK(has(r.path));
    CHECK(has("upload"));
    for (const std::string& a : cmd->argv) CHECK(a.find("p4ssw0rd-xyz") == std::string::npos);  // not in the process list
    REQUIRE(cmd->env.count("FACTORIA_KEYSTORE_PASSWORD") == 1);
    CHECK(cmd->env["FACTORIA_KEYSTORE_PASSWORD"] == "p4ssw0rd-xyz");
    CHECK(cmd->env["FACTORIA_KEY_PASSWORD"] == "p4ssw0rd-xyz");
    // The variables the arguments name are the ones that hold the password.
    const auto at = [&](const std::string& flag) { return *(std::find(cmd->argv.begin(), cmd->argv.end(), flag) + 1); };
    CHECK(cmd->env.count(at("-storepass:env")) == 1);
    CHECK(cmd->env.count(at("-keypass:env")) == 1);

    r.password = "x";
    CHECK_FALSE(make_keytool_command(r).ok());
}

#ifndef _WIN32
namespace {

// A stand-in for the JDK's keytool: a shell script that creates the keystore from the arguments and checks the environment.
stdfs::path fake_jdk(const stdfs::path& root, bool succeed) {
    const stdfs::path jdk = root / (succeed ? "jdk-ok" : "jdk-bad");
    const stdfs::path script = jdk / "bin" / "keytool";
    write_file_text(script,
                    succeed ? "#!/bin/sh\n"
                              "while [ $# -gt 0 ]; do\n"
                              "  case \"$1\" in -keystore) ks=\"$2\"; shift;; -storepass:env) sp=\"$2\"; shift;; esac\n"
                              "  shift\n"
                              "done\n"
                              "eval \"pw=\\${$sp}\"\n"
                              "[ -n \"$pw\" ] || { echo 'keytool error: no password' >&2; exit 2; }\n"
                              "echo \"keystore $pw\" > \"$ks\"\n"
                            : "#!/bin/sh\necho 'keytool error: java.io.IOException: Keystore was tampered with' >&2\nexit 1\n");
    stdfs::permissions(script, stdfs::perms::owner_all, stdfs::perm_options::add);
    return jdk;
}

}  // namespace

TEST_CASE("keystore: creating one runs keytool, then the file exists and only its owner can read it") {
    SettingsProject p("keytoolrun");
    KeystoreRequest r;
    r.jdk = fake_jdk(p.root, true).string();
    r.path = (p.root / "keys" / "up.keystore").string();
    r.password = "secret1";
    r.name = "Jane Doe";
    auto done = create_keystore(r);
    REQUIRE_MESSAGE(done.ok(), (done.ok() ? "" : done.error().message));
    CHECK(read_file_text(r.path) == "keystore secret1\n");  // keytool saw the password in its environment
    const auto perms = stdfs::status(r.path).permissions();
    CHECK((perms & (stdfs::perms::group_all | stdfs::perms::others_all)) == stdfs::perms::none);

    // The same request again: the file exists now.
    auto again = create_keystore(r);
    REQUIRE_FALSE(again.ok());
    CHECK(again.error().message.find("already exists") != std::string::npos);

    // keytool failing: its own words, and no keystore.
    KeystoreRequest failing = r;
    failing.jdk = fake_jdk(p.root, false).string();
    failing.path = (p.root / "keys" / "other.keystore").string();
    auto failed = create_keystore(failing);
    REQUIRE_FALSE(failed.ok());
    CHECK(failed.error().message.find("tampered") != std::string::npos);
    CHECK(failed.error().message.find("exit code 1") != std::string::npos);
    CHECK_FALSE(failed.error().hint.empty());
    CHECK_FALSE(stdfs::exists(failing.path));
}

TEST_CASE("keystore: the job runs on a worker thread and hands its result over once") {
    SettingsProject p("keystorejob");
    KeystoreRequest r;
    r.jdk = fake_jdk(p.root, true).string();
    r.path = (p.root / "up.keystore").string();
    r.password = "secret1";
    r.name = "Jane Doe";
    KeystoreJob job;
    CHECK_FALSE(job.running());
    CHECK_FALSE(job.take_result().has_value());
    REQUIRE(job.start(r));
    std::optional<Result<void>> done;
    for (int i = 0; i < 1000 && !done; ++i) {
        done = job.take_result();
        if (!done) std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    REQUIRE(done.has_value());
    CHECK_MESSAGE(done->ok(), (done->ok() ? "" : done->error().message));
    CHECK_FALSE(job.running());
    CHECK_FALSE(job.take_result().has_value());  // once
    CHECK(stdfs::exists(r.path));
}
#endif

TEST_CASE("keystore: it is kept out of git when the project uses git") {
    SettingsProject p("gitignore");
    // No .gitignore and no .git: nothing is created.
    stdfs::remove(p.dir / ".gitignore");
    CHECK(add_to_gitignore(p.dir.string(), "keys/up.keystore").empty());
    CHECK_FALSE(stdfs::exists(p.dir / ".gitignore"));

    write_file_text(p.dir / ".gitignore", "build/\nnode_modules/");  // no trailing newline
    const std::string said = add_to_gitignore(p.dir.string(), "keys/up.keystore");
    CHECK(said.find("/keys/up.keystore") != std::string::npos);
    const std::string text = read_file_text(p.dir / ".gitignore");
    CHECK(text.find("build/\nnode_modules/\n") == 0);  // the old lines are intact, the new one starts on its own line
    CHECK(text.find("\n/keys/up.keystore\n") != std::string::npos);

    // Already covered: by the file, or by one of its folders.
    CHECK(add_to_gitignore(p.dir.string(), "keys/up.keystore").empty());
    CHECK(add_to_gitignore(p.dir.string(), "build/up.keystore").empty());
    write_file_text(p.dir / ".gitignore", "keys/\n");
    CHECK(add_to_gitignore(p.dir.string(), "keys/up.keystore").empty());
    // Outside the project there is nothing to ignore.
    CHECK(add_to_gitignore(p.dir.string(), "/home/me/up.keystore").empty());
    CHECK(add_to_gitignore(p.dir.string(), "../up.keystore").empty());

    // A project with .git but no .gitignore gets one.
    SettingsProject q("gitdir");
    stdfs::remove(q.dir / ".gitignore");
    stdfs::create_directories(q.dir / ".git");
    CHECK_FALSE(add_to_gitignore(q.dir.string(), "up.keystore").empty());
    CHECK(read_file_text(q.dir / ".gitignore").find("/up.keystore") != std::string::npos);
}
