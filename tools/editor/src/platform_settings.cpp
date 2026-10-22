// The Platform settings window's logic (platform_settings.h): working copy, validation, saving, icon files, keystore.
#include "platform_settings.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iterator>
#include <sstream>

#include "fa/core/json.h"
#include "fa/runtime/project.h"
#include "fa/tooling/export.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

// =====================================================================================================================
// Tabs and the lists the combos offer

namespace {

struct TabInfo {
    const char* label;
    const char* platform;
};
constexpr TabInfo kTabs[kSettingsTabCount] = {{"General", ""},       {"Windows", "windows"}, {"macOS", "macos"},
                                              {"Linux", "linux"},     {"Android", "android"}, {"iOS", "ios"}};

}  // namespace

const char* settings_tab_label(SettingsTab tab) { return kTabs[static_cast<int>(tab)].label; }
const char* settings_tab_platform(SettingsTab tab) { return kTabs[static_cast<int>(tab)].platform; }

std::optional<SettingsTab> settings_tab_for_platform(const std::string& platform) {
    const std::string p = normalize_export_platform(platform);
    if (p.empty()) return std::nullopt;
    for (int i = 1; i < kSettingsTabCount; ++i)
        if (p == kTabs[i].platform) return static_cast<SettingsTab>(i);
    return std::nullopt;
}

const std::vector<SettingsChoice>& android_formats() {
    static const std::vector<SettingsChoice> list = {
        {"apk", "APK", "An .apk you can install on a phone with adb or by copying it (and share outside Google Play)."},
        {"aab", "AAB (Google Play bundle)", "An .aab, the file Google Play asks for when you publish."},
        {"gradle", "Gradle project only", "Only writes the Gradle project (open it in Android Studio); nothing is built, so no JDK or Android SDK is needed."},
    };
    return list;
}

const std::vector<SettingsChoice>& windows_formats() {
    static const std::vector<SettingsChoice> list = {
        {"folder", "Folder", "A folder with the game's .exe and files, ready to zip and share."},
        {"msix", "Folder + MSIX (Microsoft Store)", "Also writes <name>-windows.msix next to the folder: the package of the Microsoft Store, built on any computer."},
    };
    return list;
}

const std::vector<SettingsChoice>& mac_game_categories() {
    static const std::vector<SettingsChoice> list = {
        {"public.app-category.games", "Games", "The general games category."},
        {"public.app-category.action-games", "Action games", ""},
        {"public.app-category.adventure-games", "Adventure games", ""},
        {"public.app-category.arcade-games", "Arcade games", ""},
        {"public.app-category.board-games", "Board games", ""},
        {"public.app-category.card-games", "Card games", ""},
        {"public.app-category.casino-games", "Casino games", ""},
        {"public.app-category.dice-games", "Dice games", ""},
        {"public.app-category.educational-games", "Educational games", ""},
        {"public.app-category.family-games", "Family games", ""},
        {"public.app-category.kids-games", "Kids games", ""},
        {"public.app-category.music-games", "Music games", ""},
        {"public.app-category.puzzle-games", "Puzzle games", ""},
        {"public.app-category.racing-games", "Racing games", ""},
        {"public.app-category.role-playing-games", "Role-playing games", ""},
        {"public.app-category.simulation-games", "Simulation games", ""},
        {"public.app-category.sports-games", "Sports games", ""},
        {"public.app-category.strategy-games", "Strategy games", ""},
        {"public.app-category.trivia-games", "Trivia games", ""},
        {"public.app-category.word-games", "Word games", ""},
    };
    return list;
}

const std::vector<SettingsChoice>& linux_game_categories() {
    static const std::vector<SettingsChoice> list = {
        {"Game", "Game", "The main category of every game."},
        {"ActionGame", "ActionGame", ""},      {"AdventureGame", "AdventureGame", ""}, {"ArcadeGame", "ArcadeGame", ""},
        {"BoardGame", "BoardGame", ""},        {"BlocksGame", "BlocksGame", ""},       {"CardGame", "CardGame", ""},
        {"KidsGame", "KidsGame", ""},          {"LogicGame", "LogicGame", ""},         {"RolePlaying", "RolePlaying", ""},
        {"Shooter", "Shooter", ""},            {"Simulation", "Simulation", ""},       {"SportsGame", "SportsGame", ""},
        {"StrategyGame", "StrategyGame", ""},
    };
    return list;
}

const SettingsChoice* find_choice(const std::vector<SettingsChoice>& list, const std::string& value) {
    for (const SettingsChoice& c : list)
        if (value == c.value) return &c;
    return nullptr;
}

// =====================================================================================================================
// Small helpers

std::string clean_project_path(const std::string& path) {
    std::size_t a = 0, b = path.size();
    while (a < b && std::isspace(static_cast<unsigned char>(path[a]))) ++a;
    while (b > a && std::isspace(static_cast<unsigned char>(path[b - 1]))) --b;
    std::string s = path.substr(a, b - a);
    std::replace(s.begin(), s.end(), '\\', '/');  // the reader of factoria.json converts them too
    return s;
}

std::string rgb_hex(float r, float g, float b) {
    auto byte = [](float v) { return static_cast<int>(std::lround(std::clamp(v, 0.0f, 1.0f) * 255.0f)); };
    char buf[8];
    std::snprintf(buf, sizeof buf, "#%02X%02X%02X", byte(r), byte(g), byte(b));
    return buf;
}

std::string project_relative_or_absolute(const std::string& projectDir, const std::string& path) {
    std::error_code ec;
    const stdfs::path root = stdfs::weakly_canonical(stdfs::path(projectDir), ec);
    const stdfs::path full = stdfs::weakly_canonical(stdfs::path(path), ec);
    const stdfs::path rel = full.lexically_relative(root);
    if (!rel.empty() && !rel.is_absolute() && rel.generic_string().rfind("..", 0) != 0) return rel.generic_string();
    return full.generic_string();
}

namespace {

std::string trim(const std::string& s) {
    std::size_t a = 0, b = s.size();
    while (a < b && std::isspace(static_cast<unsigned char>(s[a]))) ++a;
    while (b > a && std::isspace(static_cast<unsigned char>(s[b - 1]))) --b;
    return s.substr(a, b - a);
}

std::string clean_path(std::string s) { return clean_project_path(s); }

bool is_absolute_text(const std::string& v) { return !v.empty() && (v[0] == '/' || (v.size() >= 2 && v[1] == ':')); }

std::int64_t mtime_of(const stdfs::path& p) {
    std::error_code ec;
    const auto t = stdfs::last_write_time(p, ec);
    return ec ? -1 : static_cast<std::int64_t>(t.time_since_epoch().count());
}

std::string read_all(const stdfs::path& p) {
    std::ifstream in(p, std::ios::binary);
    return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

bool same_settings(const ProjectExportSettings& a, const ProjectExportSettings& b) {
    return a.icon == b.icon && a.windows == b.windows && a.macos == b.macos && a.linux == b.linux && a.android == b.android &&
           a.ios == b.ios;
}

// The settings as the `icon` / `export` keys of a factoria.json, every set field written: parse_export_settings then checks
// the working copy exactly as it checks the file.
Json settings_json(const ProjectExportSettings& s) {
    Json root = Json::object();
    if (!s.icon.empty()) root["icon"] = s.icon;
    Json exp = Json::object();
    auto put = [](Json& o, const char* key, const std::string& v) {
        if (!v.empty()) o[key] = v;
    };
    {
        Json o = Json::object();
        put(o, "icon", s.windows.icon);
        o["format"] = s.windows.format;
        const WindowsMsixSettings& m = s.windows.msix;
        Json mx = Json::object();
        put(mx, "identityName", m.identityName);
        put(mx, "publisher", m.publisher);
        put(mx, "publisherDisplayName", m.publisherDisplayName);
        put(mx, "displayName", m.displayName);
        put(mx, "description", m.description);
        put(mx, "backgroundColor", m.backgroundColor);
        put(mx, "version", m.version);
        put(mx, "minVersion", m.minVersion);
        if (!m.languages.empty()) mx["languages"] = m.languages;
        o["msix"] = mx;
        exp["windows"] = o;
    }
    {
        Json o = Json::object();
        put(o, "icon", s.macos.icon);
        o["category"] = s.macos.category;
        o["minimumSystemVersion"] = s.macos.minimumSystemVersion;
        put(o, "copyright", s.macos.copyright);
        exp["macos"] = o;
    }
    {
        Json o = Json::object();
        put(o, "icon", s.linux.icon);
        o["categories"] = s.linux.categories;
        exp["linux"] = o;
    }
    {
        Json o = Json::object();
        const AndroidExportSettings& a = s.android;
        put(o, "icon", a.icon);
        o["format"] = a.format;
        Json ad = Json::object();
        put(ad, "foreground", a.adaptiveIcon.foreground);
        ad["background"] = a.adaptiveIcon.background;
        put(ad, "monochrome", a.adaptiveIcon.monochrome);
        o["adaptiveIcon"] = ad;
        if (a.versionCode > 0) o["versionCode"] = a.versionCode;
        o["minSdk"] = a.minSdk;
        o["targetSdk"] = a.targetSdk;
        o["permissions"] = a.permissions;
        Json sg = Json::object();
        put(sg, "keystore", a.signing.keystore);
        put(sg, "alias", a.signing.alias);
        if (!sg.empty()) o["signing"] = sg;
        exp["android"] = o;
    }
    {
        Json o = Json::object();
        put(o, "icon", s.ios.icon);
        o["iconBackground"] = s.ios.iconBackground;
        put(o, "teamId", s.ios.teamId);
        put(o, "buildNumber", s.ios.buildNumber);
        exp["ios"] = o;
    }
    root["export"] = exp;
    return root;
}

}  // namespace

// =====================================================================================================================
// Icon files

namespace {

// "factoria.json#/icon: the icon file 'x' does not exist" -> "the icon file 'x' does not exist"
std::string without_location(const std::string& message) {
    if (message.rfind("factoria.json", 0) != 0) return message;
    const std::size_t colon = message.find(": ");
    return colon == std::string::npos ? message : message.substr(colon + 2);
}

std::string join_hint(const std::string& message, const std::string& hint) { return hint.empty() ? message : message + " " + hint; }

// The folders an export leaves out (docs/EXPORTING.md, "What is shipped"): an icon there is not in the game that runs.
bool in_unshipped_folder(const std::string& rel) {
    const std::size_t slash = rel.find('/');
    if (slash == std::string::npos) return false;  // a file at the project root is shipped
    const std::string first = rel.substr(0, slash);
    return first == "build" || first == "tests" || first == "tools" || first == "types" || first == "node_modules" ||
           (!first.empty() && first[0] == '.');
}

}  // namespace

IconCheck check_icon(const std::string& projectDir, const std::string& relPath, int recommendedSize) {
    IconCheck c;
    const std::string rel = clean_path(relPath);
    if (rel.empty()) return c;
    c.set = true;
    if (is_absolute_text(rel) || rel == ".." || rel.rfind("../", 0) == 0 || rel.find("/../") != std::string::npos) {
        c.error = "'" + rel + "' is not inside the project. Choose the file again (it is copied into assets/) or write a path like \"assets/icon.png\".";
        return c;
    }
    std::vector<ExportSettingsIssue> warnings;
    auto img = load_icon_image(projectDir, rel, "/icon", &warnings, recommendedSize);
    if (!img.ok()) {
        c.error = join_hint(without_location(img.error().message), img.error().hint);
        return c;
    }
    c.loaded = true;
    c.size = img->width;
    for (const ExportSettingsIssue& w : warnings) c.warnings.push_back(join_hint(w.message, w.hint));
    if (in_unshipped_folder(rel))
        c.warnings.push_back("'" + rel + "' is in a folder the export does not ship, so the window icon of a Windows or Linux "
                             "build (read from the game's files) will be missing. Keep it in assets/.");
    return c;
}

Result<IconImport> import_icon_file(const std::string& projectDir, const std::string& picked) {
    std::error_code ec;
    const stdfs::path src(picked);
    if (picked.empty() || !stdfs::is_regular_file(src, ec))
        return make_error("The file '" + picked + "' does not exist or is not a file.", "Choose a PNG or JPG image.");
    std::string ext = src.extension().string();
    std::transform(ext.begin(), ext.end(), ext.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    if (ext != ".png" && ext != ".jpg" && ext != ".jpeg")
        return make_error("'" + src.filename().string() + "' is not a PNG or JPG image.",
                          "Icons are generated from one square PNG or JPG (1024x1024 recommended); export it from your image editor.");

    const stdfs::path root = stdfs::weakly_canonical(stdfs::path(projectDir), ec);
    const stdfs::path full = stdfs::weakly_canonical(src, ec);
    const stdfs::path rel = full.lexically_relative(root);
    IconImport out;
    if (!rel.empty() && rel.generic_string().rfind("..", 0) != 0 && !rel.is_absolute()) {  // inside the project: used where it is
        out.relPath = rel.generic_string();
        return out;
    }

    const stdfs::path assets = root / "assets";
    stdfs::create_directories(assets, ec);
    if (ec) return make_error("Cannot create " + assets.generic_string() + ": " + ec.message(), "Check that the project folder is writable.");
    const std::string stem = src.stem().string();
    const std::string bytes = read_all(src);
    for (int n = 1; n < 100; ++n) {
        const std::string name = stem + (n == 1 ? "" : "-" + std::to_string(n)) + src.extension().string();
        const stdfs::path target = assets / name;
        if (stdfs::exists(target, ec)) {
            if (read_all(target) != bytes) continue;  // a different file has this name: try the next
            out.relPath = "assets/" + name;           // the very same file is already there
            return out;
        }
        stdfs::copy_file(src, target, stdfs::copy_options::none, ec);
        if (ec) return make_error("Cannot copy '" + picked + "' into the project: " + ec.message(), "Check that the project's assets folder is writable.");
        out.relPath = "assets/" + name;
        out.copied = true;
        out.note = "Copied " + src.filename().string() + " into the project as " + out.relPath + " (icons must be inside the project).";
        return out;
    }
    return make_error("assets/ already has many different files called " + stem + "*" + src.extension().string() + ".",
                      "Rename the image and choose it again.");
}

const IconCheck& IconChecks::get(const std::string& projectDir, const std::string& relPath, int recommendedSize, double now) {
    const std::string rel = clean_path(relPath);
    const std::string key = rel + "|" + std::to_string(recommendedSize);
    Entry& e = entries_[key];
    if (e.key.empty() || now - e.checkedAt >= 0.5) {
        const std::int64_t mt = rel.empty() || is_absolute_text(rel) ? -1 : mtime_of(stdfs::path(projectDir) / rel);
        if (e.key.empty() || mt != e.mtime) {
            e.key = key;
            e.mtime = mt;
            e.result = check_icon(projectDir, rel, recommendedSize);
        }
        e.checkedAt = now;
    }
    return e.result;
}

// =====================================================================================================================
// Keystore

std::string distinguished_name(const KeystoreRequest& r) {
    auto esc = [](const std::string& v) {
        std::string o;
        for (char c : trim(v)) {
            if (c == ',' || c == '+' || c == '"' || c == '\\' || c == '<' || c == '>' || c == ';') o += '\\';
            o += c;
        }
        return o;
    };
    std::string dn = "CN=" + esc(r.name);
    if (!trim(r.organization).empty()) dn += ", O=" + esc(r.organization);
    if (!trim(r.country).empty()) dn += ", C=" + esc(r.country);
    return dn;
}

namespace {

stdfs::path keytool_path(const std::string& jdk) {
#ifdef _WIN32
    return stdfs::path(jdk) / "bin" / "keytool.exe";
#else
    return stdfs::path(jdk) / "bin" / "keytool";
#endif
}

}  // namespace

KeystoreForm default_keystore_form(const std::string& projectDir) {
    KeystoreForm f;
    std::error_code ec;
    f.path = "keys/upload.keystore";
    for (int n = 2; n < 100 && stdfs::exists(stdfs::path(projectDir) / f.path, ec); ++n) f.path = "keys/upload-" + std::to_string(n) + ".keystore";
    return f;
}

Result<KeystoreRequest> make_keystore_request(const KeystoreForm& f, const std::string& projectDir, const std::string& jdk) {
    KeystoreRequest r;
    r.jdk = jdk;
    const std::string rel = clean_project_path(f.path);
    if (!rel.empty()) r.path = (is_absolute_text(rel) ? stdfs::path(rel) : stdfs::path(projectDir) / rel).lexically_normal().generic_string();
    r.alias = f.alias;
    r.password = f.password;
    r.name = f.name;
    r.organization = f.organization;
    r.country = f.country;
    if (f.password != f.repeat) return make_error("The two passwords are different.", "Type the same password in both boxes.");
    if (std::string why = check_keystore_request(r); !why.empty()) return make_error(why);
    return r;
}

std::string check_keystore_request(const KeystoreRequest& r) {
    std::error_code ec;
    if (r.jdk.empty())
        return "No JDK was found: set the JDK folder under \"This computer\" first (keytool, which creates the keystore, is part of the JDK).";
    if (!stdfs::exists(keytool_path(r.jdk), ec))
        return "keytool is not in " + keytool_path(r.jdk).generic_string() + ": choose the folder of a JDK (it has bin/keytool) under \"This computer\".";
    if (trim(r.path).empty()) return "Choose where to save the keystore file.";
    if (!stdfs::path(r.path).is_absolute()) return "The keystore path must be absolute: " + r.path;
    if (stdfs::exists(r.path, ec))
        return "The file " + r.path + " already exists. Choose another name: this window never overwrites a keystore.";
    if (trim(r.alias).empty()) return "Enter an alias for the key (a name such as \"upload\").";
    if (r.password.size() < 6) return "The password needs at least 6 characters (a keytool rule).";
    if (trim(r.name).empty()) return "Enter your name or your studio's: it names the certificate (CN).";
    const std::string country = trim(r.country);
    if (!country.empty() && !(country.size() == 2 && std::isalpha(static_cast<unsigned char>(country[0])) &&
                              std::isalpha(static_cast<unsigned char>(country[1]))))
        return "The country is a two-letter code such as ES or US (or leave it empty).";
    if (r.validityDays < 1) return "The key must be valid for at least one day.";
    return {};
}

Result<KeytoolCommand> make_keytool_command(const KeystoreRequest& r) {
    if (std::string why = check_keystore_request(r); !why.empty()) return make_error(why);
    KeytoolCommand c;
    c.argv = {keytool_path(r.jdk).string(), "-genkeypair", "-v",
              "-keystore", r.path,
              "-alias", trim(r.alias),
              "-keyalg", "RSA", "-keysize", "2048",
              "-validity", std::to_string(r.validityDays),
              "-storetype", "PKCS12",
              "-storepass:env", "FACTORIA_KEYSTORE_PASSWORD",
              "-keypass:env", "FACTORIA_KEY_PASSWORD",
              "-dname", distinguished_name(r)};
    c.env["FACTORIA_KEYSTORE_PASSWORD"] = r.password;
    c.env["FACTORIA_KEY_PASSWORD"] = r.password;
    return c;
}

Result<void> create_keystore(const KeystoreRequest& r, const CancelFlag* cancel) {
    auto cmd = make_keytool_command(r);
    if (!cmd.ok()) return cmd.error();
    std::error_code ec;
    stdfs::create_directories(stdfs::path(r.path).parent_path(), ec);
    if (ec) return make_error("Cannot create the folder of the keystore: " + ec.message(), "Choose a folder you can write to.");
    ProcessOptions po;
    po.argv = cmd->argv;
    po.env = cmd->env;
    po.cancel = cancel;
    po.timeoutSeconds = 60;
    auto run = run_process(po);
    if (!run.ok()) return make_error("Cannot run keytool: " + run.error().message, "Check the JDK folder under \"This computer\".");
    if (run->exitCode != 0) {
        std::string said = trim(run->stderrText.empty() ? run->stdoutText : run->stderrText);
        if (said.size() > 600) said = said.substr(said.size() - 600);
        return make_error("keytool failed (exit code " + std::to_string(run->exitCode) + "): " + said,
                          "Check the name, alias and password; the keystore was not created.");
    }
    if (!stdfs::exists(r.path, ec)) return make_error("keytool finished but " + r.path + " does not exist.", "Run it again.");
    // The file holds a signing key: nobody but its owner needs to read it.
    stdfs::permissions(r.path, stdfs::perms::owner_read | stdfs::perms::owner_write, stdfs::perm_options::replace, ec);
    return {};
}

std::string add_to_gitignore(const std::string& projectDir, const std::string& relPathIn) {
    const std::string rel = clean_path(relPathIn);
    if (rel.empty() || is_absolute_text(rel) || rel.rfind("..", 0) == 0) return {};
    const stdfs::path root(projectDir);
    std::error_code ec;
    const stdfs::path ignore = root / ".gitignore";
    if (!stdfs::exists(ignore, ec) && !stdfs::exists(root / ".git", ec)) return {};
    std::string text = stdfs::exists(ignore, ec) ? read_all(ignore) : std::string();
    // A line that already covers it: the file, or one of its folders.
    std::vector<std::string> covers = {rel};
    for (std::size_t slash = rel.find('/'); slash != std::string::npos; slash = rel.find('/', slash + 1)) covers.push_back(rel.substr(0, slash));
    std::istringstream lines(text);
    for (std::string line; std::getline(lines, line);) {
        line = trim(line);
        for (const std::string& c : covers)
            if (line == c || line == c + "/" || line == "/" + c || line == "/" + c + "/") return {};
    }
    if (!text.empty() && text.back() != '\n') text += '\n';
    text += "# Android signing key (never commit it)\n/" + rel + "\n";
    std::ofstream out(ignore, std::ios::binary);
    out << text;
    return out ? "Added /" + rel + " to .gitignore." : std::string();
}

bool KeystoreJob::start(KeystoreRequest request) {
    if (running()) return false;
    wait();
    future_ = std::async(std::launch::async, [r = std::move(request)] { return create_keystore(r); });
    return true;
}

bool KeystoreJob::running() const {
    return future_.valid() && future_.wait_for(std::chrono::seconds(0)) != std::future_status::ready;
}

std::optional<Result<void>> KeystoreJob::take_result() {
    if (!future_.valid() || running()) return std::nullopt;
    return future_.get();
}

void KeystoreJob::wait() {
    if (future_.valid()) future_.wait();
}

// =====================================================================================================================
// The working copy

const ExportSettingsIssue* SettingsProblems::error_for(const std::string& pointer) const {
    for (const ExportSettingsIssue& i : errors)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

const ExportSettingsIssue* SettingsProblems::warning_for(const std::string& pointer) const {
    for (const ExportSettingsIssue& i : warnings)
        if (i.pointer == pointer) return &i;
    return nullptr;
}

void PlatformSettings::clear() {
    projectDir_.clear();
    machinePath_.clear();
    project = {};
    machine = {};
    rememberPasswords = false;
    info = {};
    fileError.clear();
    parseErrors.clear();
    parseWarnings.clear();
    machineError.clear();
    savedProject_ = {};
    savedMachine_ = {};
    fileMtime_ = -1;
    toolchain_.reset();
    toolchainKey_.clear();
}

std::int64_t PlatformSettings::project_file_mtime() const {
    return mtime_of(stdfs::path(projectDir_) / kProjectFileName);
}

void PlatformSettings::read_project() {
    fileError.clear();
    parseErrors.clear();
    parseWarnings.clear();
    info = {};
    project = {};
    savedProject_ = {};
    fileMtime_ = project_file_mtime();
    const stdfs::path path = stdfs::path(projectDir_) / kProjectFileName;
    std::error_code ec;
    if (!stdfs::is_regular_file(path, ec)) {
        fileError = "Cannot read " + path.generic_string() + ": run the editor on a folder that contains factoria.json.";
        return;
    }
    auto parsed = parse_json(read_all(path), path.generic_string());
    if (!parsed.ok()) {
        fileError = join_hint(parsed.error().message, parsed.error().hint);
        return;
    }
    if (!parsed->is_object()) {
        fileError = path.generic_string() + ": the project file must be a JSON object.";
        return;
    }
    ExportSettingsParse r = parse_export_settings(*parsed);
    project = r.settings;
    savedProject_ = r.settings;
    parseErrors = std::move(r.errors);
    parseWarnings = std::move(r.warnings);
    if (auto p = load_project(projectDir_); p.ok()) {
        info.name = p->name;
        info.id = p->id;
        info.version = p->version;
        info.orientation = p->orientation;
        info.width = p->width;
        info.height = p->height;
    }
}

void PlatformSettings::load(const std::string& projectDir, const std::string& machineConfigPath) {
    clear();
    projectDir_ = projectDir;
    machinePath_ = machineConfigPath.empty() ? machine_export_config_path(env) : machineConfigPath;
    read_project();
    read_machine();
}

void PlatformSettings::read_machine() {
    machineError.clear();
    auto m = load_machine_export_config(machinePath_);
    if (m.ok()) {
        machine = *m;
        savedMachine_ = *m;
    } else {
        machineError = join_hint(m.error().message, m.error().hint);
    }
    rememberPasswords = !machine.androidKeystorePassword.empty() || !machine.androidKeyPassword.empty();
    toolchain_.reset();
}

void PlatformSettings::reload_machine() {
    if (loaded()) read_machine();
}

ProjectExportSettings PlatformSettings::effective_project() const {
    ProjectExportSettings s = project;
    s.projectVersion = project.projectVersion.empty() ? savedProject_.projectVersion : project.projectVersion;
    const ProjectExportSettings def;
    s.icon = clean_path(s.icon);
    s.windows.icon = clean_path(s.windows.icon);
    s.macos.icon = clean_path(s.macos.icon);
    s.linux.icon = clean_path(s.linux.icon);
    s.android.icon = clean_path(s.android.icon);
    s.ios.icon = clean_path(s.ios.icon);

    s.macos.category = trim(s.macos.category);
    if (s.macos.category.empty()) s.macos.category = def.macos.category;
    s.macos.minimumSystemVersion = trim(s.macos.minimumSystemVersion);
    if (s.macos.minimumSystemVersion.empty()) s.macos.minimumSystemVersion = def.macos.minimumSystemVersion;
    s.macos.copyright = trim(s.macos.copyright);

    std::vector<std::string> cats;
    for (const std::string& c : s.linux.categories)
        if (!trim(c).empty()) cats.push_back(trim(c));
    s.linux.categories = std::move(cats);

    s.android.adaptiveIcon.foreground = clean_path(s.android.adaptiveIcon.foreground);
    s.android.adaptiveIcon.monochrome = clean_path(s.android.adaptiveIcon.monochrome);
    const std::string bg = clean_path(s.android.adaptiveIcon.background);
    s.android.adaptiveIcon.background = bg.empty() ? def.android.adaptiveIcon.background : bg;
    std::vector<std::string> perms;
    for (const std::string& p : s.android.permissions)
        if (!trim(p).empty()) perms.push_back(trim(p));
    s.android.permissions = std::move(perms);
    s.android.signing.keystore = clean_path(s.android.signing.keystore);
    s.android.signing.alias = trim(s.android.signing.alias);

    const std::string ib = trim(s.ios.iconBackground);
    s.ios.iconBackground = ib.empty() ? def.ios.iconBackground : ib;
    s.ios.teamId = trim(s.ios.teamId);
    s.ios.buildNumber = trim(s.ios.buildNumber);
    return s;
}

bool PlatformSettings::project_dirty() const { return loaded() && !same_settings(effective_project(), savedProject_); }

namespace {

// What Save writes of the machine part: the passwords only when they are to be remembered.
MachineExportConfig machine_to_save(const MachineExportConfig& m, bool remember) {
    MachineExportConfig out = m;
    out.androidSdk = trim(m.androidSdk);
    out.androidJdk = trim(m.androidJdk);
    if (!remember) {
        out.androidKeystorePassword.clear();
        out.androidKeyPassword.clear();
    }
    return out;
}

bool same_machine(const MachineExportConfig& a, const MachineExportConfig& b) {
    return a.androidSdk == b.androidSdk && a.androidJdk == b.androidJdk && a.androidKeystorePassword == b.androidKeystorePassword &&
           a.androidKeyPassword == b.androidKeyPassword;
}

}  // namespace

bool PlatformSettings::machine_dirty() const {
    return loaded() && !same_machine(machine_to_save(machine, rememberPasswords), savedMachine_);
}

SettingsProblems PlatformSettings::validate() const {
    SettingsProblems p;
    ExportSettingsParse r = parse_export_settings(settings_json(effective_project()));
    p.errors = std::move(r.errors);
    p.warnings = std::move(r.warnings);
    return p;
}

Result<void> PlatformSettings::save() {
    if (!loaded()) return make_error("There is no project to save the settings of.", "Open a project first.");
    const SettingsProblems problems = validate();
    if (!problems.errors.empty()) {
        const ExportSettingsIssue& first = problems.errors.front();
        return make_error("Cannot save: " + first.message + " (" + first.pointer + ").",
                          first.hint.empty() ? "Fix the fields marked in red first." : first.hint);
    }
    std::string failure, hint;
    auto fail = [&](const Error& e) {
        if (failure.empty()) {
            failure = e.message;
            hint = e.hint;
        }
    };
    if (project_dirty()) {
        if (!fileError.empty()) {
            fail(Error{"Cannot save the project settings: " + fileError, "Fix factoria.json first (or ask the AI), then press Revert."});
        } else if (auto r = save_export_settings(projectDir_, effective_project()); !r.ok()) {
            fail(r.error());
        } else {
            read_project();  // what is on disk now, defaults and all
        }
    }
    if (machine_dirty()) {
        const MachineExportConfig toSave = machine_to_save(machine, rememberPasswords);
        if (auto r = save_machine_export_config(toSave, machinePath_); !r.ok()) {
            fail(r.error());
        } else if (auto back = load_machine_export_config(machinePath_); back.ok()) {
            machine = *back;
            savedMachine_ = *back;
            machineError.clear();
            toolchain_.reset();
        }
    }
    if (!failure.empty()) return make_error(failure, hint);
    return {};
}

bool PlatformSettings::project_file_changed() const { return loaded() && project_file_mtime() != fileMtime_; }

void PlatformSettings::reload_project() {
    if (loaded()) read_project();
}

const AndroidToolchain& PlatformSettings::toolchain(bool refresh) {
    const std::string key = trim(machine.androidJdk) + "\n" + trim(machine.androidSdk);
    if (refresh || !toolchain_ || key != toolchainKey_) {
        MachineExportConfig m;
        m.androidJdk = trim(machine.androidJdk);
        m.androidSdk = trim(machine.androidSdk);
        toolchain_ = toolchainSearch ? find_android_toolchain(m, *toolchainSearch) : find_android_toolchain(m);
        toolchainKey_ = key;
    }
    return *toolchain_;
}

namespace {

SecretStatus describe_secret(const std::string& from, bool set, bool isKey) {
    SecretStatus s;
    s.set = set;
    s.from = from;
    if (!set) s.text = "Not set";
    else if (from.rfind("FACTORIA_", 0) == 0) s.text = "Set by the environment variable " + from + " (it wins over this computer's file)";
    else if (from == "export.json") s.text = "Saved on this computer";
    else s.text = isKey ? "Same as the keystore password" : "Set";
    return s;
}

}  // namespace

SecretStatus PlatformSettings::keystore_password_status() const {
    const AndroidSigningSecrets s = resolve_android_signing_secrets(machine_to_save(machine, rememberPasswords), env);
    return describe_secret(s.keystorePasswordFrom, !s.keystorePassword.empty(), false);
}

SecretStatus PlatformSettings::key_password_status() const {
    const AndroidSigningSecrets s = resolve_android_signing_secrets(machine_to_save(machine, rememberPasswords), env);
    return describe_secret(s.keyPasswordFrom, !s.keyPassword.empty(), true);
}

std::string PlatformSettings::keystore_path() const {
    const std::string k = clean_path(project.android.signing.keystore);
    if (k.empty()) return {};
    return (is_absolute_text(k) ? stdfs::path(k) : stdfs::path(projectDir_) / k).lexically_normal().generic_string();
}

bool PlatformSettings::keystore_exists() const {
    const std::string p = keystore_path();
    std::error_code ec;
    return !p.empty() && stdfs::is_regular_file(p, ec);
}

void PlatformSettings::note_saved_android_format(const std::string& format) {
    if (!loaded()) return;
    if (project_dirty()) {  // other edits are pending: only the format follows what was written
        project.android.format = format;
        savedProject_.android.format = format;
        fileMtime_ = project_file_mtime();
    } else {
        read_project();
    }
}

void PlatformSettings::note_saved_windows_format(const std::string& format) {
    if (!loaded()) return;
    if (project_dirty()) {
        project.windows.format = format;
        savedProject_.windows.format = format;
        fileMtime_ = project_file_mtime();
    } else {
        read_project();
    }
}

Result<void> save_windows_format(const std::string& projectDir, const std::string& format) {
    if (!find_choice(windows_formats(), format))
        return make_error("Unknown Windows format '" + format + "'.", "Use folder or msix.");
    auto s = load_export_settings(projectDir);
    if (!s.ok()) return s.error();
    if (s->windows.format == format) return {};
    s->windows.format = format;
    return save_export_settings(projectDir, *s);
}

Result<void> save_android_format(const std::string& projectDir, const std::string& format) {
    if (!find_choice(android_formats(), format))
        return make_error("Unknown Android format '" + format + "'.", "Use apk, aab or gradle.");
    auto s = load_export_settings(projectDir);
    if (!s.ok()) return s.error();
    if (s->android.format == format) return {};
    s->android.format = format;
    return save_export_settings(projectDir, *s);
}

}  // namespace fa::editor
