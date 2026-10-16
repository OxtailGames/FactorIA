// The Platform settings window's logic (File > Platform Settings..., the Export window's Settings... buttons): a working copy
// of what an export needs besides the game (factoria.json's `icon` and `export`, and this computer's ~/.factoria/export.json),
// its validation, saving, the icon files it points at, the Android toolchain, and the keystore the editor can create.
//
// Everything here is plain logic over fa/tooling/export_settings.h, fa/tooling/icons.h and fa/core/process.h: no ImGui, no
// Editor, no window. platform_settings_panel.cpp only draws it, and tests call it directly. The editor never writes
// factoria.json its own way: Save is fa::save_export_settings (it patches `icon` and `export` and nothing else) and the
// validation is fa::parse_export_settings, the very code the export and `factoria validate` read the file with.
#pragma once

#include <cstdint>
#include <future>
#include <map>
#include <optional>
#include <string>
#include <vector>

#include "fa/core/process.h"
#include "fa/tooling/export_settings.h"
#include "fa/tooling/icons.h"

namespace fa::editor {

// ---------------------------------------------------------------------------------------------------------------------
// Tabs and the lists the combos offer

enum class SettingsTab { General, Windows, Macos, Linux, Android, Ios };
inline constexpr int kSettingsTabCount = 6;
const char* settings_tab_label(SettingsTab tab);     // "General", "Windows", "macOS", "Linux", "Android", "iOS"
const char* settings_tab_platform(SettingsTab tab);  // "" for General; else the export's platform name ("macos")
// The tab of an export platform ("win", "Mac" and "ios" work like in `factoria export`); nullopt for an unknown name.
std::optional<SettingsTab> settings_tab_for_platform(const std::string& platform);

struct SettingsChoice {
    const char* value;  // what factoria.json holds
    const char* label;  // what the combo shows
    const char* note;   // one line about it (the combo's tooltip)
};
const std::vector<SettingsChoice>& android_formats();      // apk, aab, gradle
const std::vector<SettingsChoice>& mac_game_categories();  // public.app-category.games and the *-games ones
const std::vector<SettingsChoice>& linux_game_categories();  // the freedesktop Game categories, for "Add"
const SettingsChoice* find_choice(const std::vector<SettingsChoice>& list, const std::string& value);  // nullptr when absent

// A path as factoria.json stores it: no blanks around it, forward slashes.
std::string clean_project_path(const std::string& path);
// "#RRGGBB" of a colour given as 0..1 floats (what ImGui's colour editors hold).
std::string rgb_hex(float r, float g, float b);
// A file chosen in a dialog as the setting that names it: the project-relative path when it is inside the project, else the
// absolute one (keystores are better kept outside the repository).
std::string project_relative_or_absolute(const std::string& projectDir, const std::string& path);

// ---------------------------------------------------------------------------------------------------------------------
// Icon files

// What reading one icon setting finds on disk (fa::load_icon_image): the picture is usable, or why not, and what is worth a
// warning (not square, small, in a folder that the export does not ship).
struct IconCheck {
    bool set = false;                   // a path is written
    bool loaded = false;                // the file was read and decoded
    int size = 0;                       // side of the square image that was read (the longer side of the picture)
    std::string error;                  // when set and not loaded: what is wrong and how to fix it
    std::vector<std::string> warnings;  // each "message hint"
};
// `relPath` is project-relative; `recommendedSize` is 512 for icons and 432 for the Android adaptive layers.
IconCheck check_icon(const std::string& projectDir, const std::string& relPath, int recommendedSize = kRecommendedIconSize);

// A picked image file as the project-relative path factoria.json stores. A file inside the project is used where it is. A
// file outside is copied into <project>/assets/ (icons must be inside the project; the export reads them from there): the
// name is kept, and a different file that already has it gets "-2", "-3"... so nothing is overwritten.
struct IconImport {
    std::string relPath;  // "assets/icon.png"
    bool copied = false;
    std::string note;     // "Copied icon.png into the project: assets/icon.png" when copied, else empty
};
Result<IconImport> import_icon_file(const std::string& projectDir, const std::string& picked);

// Checks icon files again only when their file changed (or after `maxAgeSeconds`): the window asks every frame.
class IconChecks {
public:
    const IconCheck& get(const std::string& projectDir, const std::string& relPath, int recommendedSize, double now);
    void clear() { entries_.clear(); }

private:
    struct Entry {
        std::string key;
        std::int64_t mtime = -2;
        double checkedAt = -1e9;
        IconCheck result;
    };
    std::map<std::string, Entry> entries_;
};

// ---------------------------------------------------------------------------------------------------------------------
// Keystore

// A signing key the editor creates with the JDK's keytool. One password is used for the keystore and for the key: a
// PKCS12 keystore (the default of JDK 9 and newer) has just one.
struct KeystoreRequest {
    std::string jdk;           // folder of the JDK that holds bin/keytool
    std::string path;          // absolute path of the keystore file to create
    std::string alias = "upload";
    std::string password;      // at least 6 characters (keytool's own minimum)
    std::string name;          // CN: you or your studio
    std::string organization;  // O, optional
    std::string country;       // C, two letters, optional
    int validityDays = 10000;  // about 27 years; Google Play asks for at least 25
};
// What the Create keystore... window holds while it is open.
struct KeystoreForm {
    std::string path;                // as typed: project-relative or absolute
    std::string alias = "upload";
    std::string password, repeat;
    std::string name, organization, country;
    bool remember = true;            // keep the password on this computer (export.json, written by Save)
    bool gitignore = true;           // keep the keystore out of git when it is inside the project
};
// keys/upload.keystore (keys/upload-2.keystore... when that file exists).
KeystoreForm default_keystore_form(const std::string& projectDir);
// The form as a request: the path made absolute against the project, the passwords compared, everything checked. The Error
// says what to fix.
Result<KeystoreRequest> make_keystore_request(const KeystoreForm& form, const std::string& projectDir, const std::string& jdk);
// The first thing wrong with the request, in words that say how to fix it; "" when it can run.
std::string check_keystore_request(const KeystoreRequest& request);
// "CN=Jane Doe, O=My Studio, C=ES" with the characters that are special in a distinguished name escaped.
std::string distinguished_name(const KeystoreRequest& request);
// What keytool is started with: the password is NEVER an argument (it would show in the process list): -storepass:env and
// -keypass:env name variables of the child's environment.
struct KeytoolCommand {
    std::vector<std::string> argv;
    std::map<std::string, std::string> env;
};
Result<KeytoolCommand> make_keytool_command(const KeystoreRequest& request);
// Runs it (blocks for about a second: call it from a worker). Errors quote what keytool said.
Result<void> create_keystore(const KeystoreRequest& request, const CancelFlag* cancel = nullptr);
// Keeps a file out of git: appends "/<relPath>" to <projectDir>/.gitignore when the project has a .gitignore or a .git folder
// and no line already says so. Returns what it did ("" = nothing to do).
std::string add_to_gitignore(const std::string& projectDir, const std::string& relPath);

// The keystore that Create keystore... runs on a worker thread; polled every frame.
class KeystoreJob {
public:
    bool start(KeystoreRequest request);  // false while one runs
    bool running() const;
    std::optional<Result<void>> take_result();  // once, when it finished
    KeystoreJob() = default;
    KeystoreJob(const KeystoreJob&) = delete;
    KeystoreJob& operator=(const KeystoreJob&) = delete;
    ~KeystoreJob() { wait(); }
    void wait();

private:
    std::future<Result<void>> future_;
};

// ---------------------------------------------------------------------------------------------------------------------
// The working copy

// One signing password as the window shows it: where it comes from, never its value.
struct SecretStatus {
    bool set = false;
    std::string from;  // "FACTORIA_ANDROID_KEYSTORE_PASSWORD" | "export.json" | "keystore password" | ""
    std::string text;  // "Set by the environment variable ...", "Saved on this computer", "Not set"
};

struct ProjectInfo {  // factoria.json's own settings: shown, not edited (the AI or the file change them)
    std::string name, id, version, orientation;
    int width = 0, height = 0;
};

struct SettingsProblems {
    std::vector<ExportSettingsIssue> errors;    // wrong values: Save is refused until they are fixed
    std::vector<ExportSettingsIssue> warnings;  // worth knowing
    const ExportSettingsIssue* error_for(const std::string& pointer) const;
    const ExportSettingsIssue* warning_for(const std::string& pointer) const;
};

class PlatformSettings {
public:
    // Reads factoria.json and the machine settings (`machineConfigPath` "" = machine_export_config_path()). Never fails:
    // what could not be read is in fileError / parseErrors / machineError and the fields keep their defaults.
    void load(const std::string& projectDir, const std::string& machineConfigPath = {});
    void clear();                 // no project: nothing to edit
    bool loaded() const { return !projectDir_.empty(); }
    const std::string& project_dir() const { return projectDir_; }
    const std::string& machine_path() const { return machinePath_; }

    // The working copy: the window edits these fields in place.
    ProjectExportSettings project;
    MachineExportConfig machine;
    bool rememberPasswords = false;  // the passwords are kept in export.json (off: both are removed on Save)

    // factoria.json's own keys, read-only.
    ProjectInfo info;
    // What was wrong when the file was read (a hand-edited file): shown at the top; the window still opens.
    std::string fileError;                          // not JSON / unreadable: nothing in the file can be saved
    std::vector<ExportSettingsIssue> parseErrors;   // wrong types or values in icon / export
    std::vector<ExportSettingsIssue> parseWarnings; // unknown keys...
    std::string machineError;                       // export.json could not be read

    // `project` with the fields that mean "the default" filled in (an empty category is the default one), paths with
    // forward slashes and no blanks: what Save writes and what validation checks.
    ProjectExportSettings effective_project() const;
    bool project_dirty() const;
    bool machine_dirty() const;
    bool dirty() const { return project_dirty() || machine_dirty(); }
    // The working copy checked with fa::parse_export_settings (pointers like "/export/android/minSdk").
    SettingsProblems validate() const;

    // Writes factoria.json (only when the project part changed) and export.json (only when the machine part changed), then
    // reads both back. Refused, with the reason, while validate() has errors or factoria.json cannot be read.
    Result<void> save();
    // Forgets every edit: reads both files again.
    void revert() { load(projectDir_, machinePath_); }

    // factoria.json changed on disk since it was read or saved here (an AI or an editor wrote it).
    bool project_file_changed() const;
    // Reads only the project part again (the machine edits stay).
    void reload_project();

    // The Android toolchain the working machine settings find (a folder search: no process runs). Cached; `refresh` forces a
    // new search (the folder of a JDK was just installed).
    const AndroidToolchain& toolchain(bool refresh = false);
    std::optional<AndroidToolchainSearch> toolchainSearch;  // tests: where to look instead of the usual folders
    ExportEnvLookup env = system_export_env();

    // The signing passwords as the export will find them (the working copy of this computer's file, the environment wins).
    SecretStatus keystore_password_status() const;
    SecretStatus key_password_status() const;
    // The keystore of the signing setting: the absolute path it names (project-relative paths resolved), and whether it exists.
    std::string keystore_path() const;
    bool keystore_exists() const;

    // The version code a build gets now (versionCode, or the one derived from the game's version).
    int derived_version_code() const { return effective_project().android_version_code(); }

    // The saved project settings (what an export reads now), for the Export window's format combo.
    const ProjectExportSettings& saved_project() const { return savedProject_; }
    // The Export window changed export.android.format on disk: the working copy follows (only that field when other edits
    // are pending).
    void note_saved_android_format(const std::string& format);

private:
    void read_project();
    std::int64_t project_file_mtime() const;

    std::string projectDir_, machinePath_;
    ProjectExportSettings savedProject_;
    MachineExportConfig savedMachine_;
    std::int64_t fileMtime_ = -1;
    std::optional<AndroidToolchain> toolchain_;
    std::string toolchainKey_;
};

// export.android.format on disk (factoria.json), changed alone through fa::save_export_settings: what the Export window's
// format combo does. An error (a broken file) is returned with its hint.
Result<void> save_android_format(const std::string& projectDir, const std::string& format);

}  // namespace fa::editor
