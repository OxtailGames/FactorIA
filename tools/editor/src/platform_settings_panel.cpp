// The Platform settings window (File > Platform Settings..., the Export window's Settings... buttons): the game icon and what
// each platform's export needs besides the game: General, Windows, macOS, Linux, Android and iOS tabs. Edits go to a working
// copy; Save writes factoria.json with fa::save_export_settings (and this computer's ~/.factoria/export.json), Revert reads
// both again, and closing with unsaved changes asks. The logic is platform_settings.h; this file only draws it.
#include <algorithm>
#include <cfloat>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iterator>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace stdfs = std::filesystem;

namespace {

const ImVec4& kReady = kStatusReady;
const ImVec4& kFailed = kStatusFailed;
const ImVec4& kWarn = kStatusWarn;

// A tooltip that wraps (the default one grows as wide as its text).
void tip(const std::string& text) {
    if (text.empty()) return;
    if (ImGui::BeginItemTooltip()) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 32.0f);
        ImGui::TextUnformatted(text.c_str());
        ImGui::PopTextWrapPos();
        ImGui::EndTooltip();
    }
}

void wrapped(const ImVec4& color, const std::string& text) {
    ImGui::PushStyleColor(ImGuiCol_Text, color);
    ImGui::TextWrapped("%s", text.c_str());
    ImGui::PopStyleColor();
}

void note(const std::string& text) {
    ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
    ImGui::TextWrapped("%s", text.c_str());
    ImGui::PopStyleColor();
}

// A label column and a value column; every setting is one row, its tooltip on the label.
class Form {
public:
    explicit Form(const char* id) {
        open_ = ImGui::BeginTable(id, 2, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_NoSavedSettings);
        if (open_) {
            ImGui::TableSetupColumn("label", ImGuiTableColumnFlags_WidthFixed, ImGui::GetFontSize() * 11.5f);
            ImGui::TableSetupColumn("value", ImGuiTableColumnFlags_WidthStretch);
        }
    }
    ~Form() {
        if (open_) ImGui::EndTable();
    }
    Form(const Form&) = delete;
    Form& operator=(const Form&) = delete;

    void row(const char* label, const std::string& tooltip = {}) {
        ImGui::TableNextRow();
        ImGui::TableSetColumnIndex(0);
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted(label);
        tip(tooltip);
        ImGui::TableSetColumnIndex(1);
    }

private:
    bool open_ = false;
};

// What validation says about one field, under it.
void field_problems(const SettingsProblems& problems, const std::string& pointer) {
    if (const ExportSettingsIssue* e = problems.error_for(pointer)) wrapped(kFailed, e->message + (e->hint.empty() ? "" : " " + e->hint));
    else if (const ExportSettingsIssue* w = problems.warning_for(pointer)) wrapped(kWarn, w->message + (w->hint.empty() ? "" : " " + w->hint));
}

bool text_row(Form& form, const char* label, const std::string& tooltip, const char* id, std::string& value, const char* hint,
              const SettingsProblems& problems, const std::string& pointer, ImGuiInputTextFlags flags = 0) {
    form.row(label, tooltip);
    ImGui::SetNextItemWidth(-FLT_MIN);
    const bool changed = ImGui::InputTextWithHint(id, hint, &value, flags);
    tip(tooltip);
    field_problems(problems, pointer);
    return changed;
}

// ---- icons --------------------------------------------------------------------------------------------------------

// The picture in a square box over a checkerboard (so transparency shows); the box stays empty when there is no picture.
void preview_box(Editor& ed, const std::string& path, bool usable, bool dimmed, float box) {
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 p0 = ImGui::GetCursorScreenPos(), p1(p0.x + box, p0.y + box);
    dl->AddRectFilled(p0, p1, IM_COL32(64, 64, 70, 255));
    const float cell = 8.0f;
    for (int y = 0; y * cell < box; ++y)
        for (int x = 0; x * cell < box; ++x)
            if ((x + y) & 1) {
                const ImVec2 a(p0.x + float(x) * cell, p0.y + float(y) * cell);
                dl->AddRectFilled(a, ImVec2(std::min(a.x + cell, p1.x), std::min(a.y + cell, p1.y)), IM_COL32(88, 88, 96, 255));
            }
    const TextureEntry* t = usable ? ed.icon_preview(path) : nullptr;
    if (t && t->w > 0 && t->h > 0) {
        const float scale = std::min(box / float(t->w), box / float(t->h));
        const ImVec2 size(float(t->w) * scale, float(t->h) * scale);
        const ImVec2 a(p0.x + (box - size.x) * 0.5f, p0.y + (box - size.y) * 0.5f);
        dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(t->view, true))), a, ImVec2(a.x + size.x, a.y + size.y), ImVec2(0, 0),
                     ImVec2(1, 1), dimmed ? IM_COL32(255, 255, 255, 120) : IM_COL32_WHITE);
    } else {
        const char* text = "No image";
        const ImVec2 ts = ImGui::CalcTextSize(text);
        dl->AddText(ImVec2(p0.x + (box - ts.x) * 0.5f, p0.y + (box - ts.y) * 0.5f), IM_COL32(170, 170, 178, 255), text);
    }
    dl->AddRect(p0, p1, IM_COL32(120, 120, 130, 255));
    ImGui::Dummy(ImVec2(box, box));
}

// A picture setting: a preview, the path (typed or chosen), Choose... and Clear, and what is wrong with the file.
// `fallback` is the picture used while this one is empty (the game icon on a platform's tab): it is previewed dimmed.
void icon_field(Editor& ed, const char* id, std::string& path, const std::string& fallback, int recommended, const std::string& emptyNote,
                const SettingsProblems& problems, const std::string& pointer, const std::string& tooltip) {
    PlatformSettings& ps = ed.platformSettings_;
    ImGui::PushID(id);
    const float box = 96.0f;
    const ImGuiStyle& style = ImGui::GetStyle();
    const std::string own = clean_project_path(path);
    const std::string fall = clean_project_path(fallback);
    const bool usingFallback = own.empty() && !fall.empty();
    const std::string shown = own.empty() ? fall : own;
    const IconCheck& check = ed.iconChecks_.get(ps.project_dir(), shown, recommended, ed.time_);

    const float rightW = std::max(120.0f, ImGui::GetContentRegionAvail().x - box - style.ItemSpacing.x);
    ImGui::BeginGroup();
    preview_box(ed, shown, check.loaded, usingFallback, box);
    ImGui::EndGroup();
    ImGui::SameLine();
    ImGui::BeginGroup();
    const float buttonsW = ImGui::CalcTextSize("Choose...").x + ImGui::CalcTextSize("Clear").x + style.FramePadding.x * 4 + style.ItemSpacing.x;
    ImGui::SetNextItemWidth(std::max(80.0f, rightW - buttonsW - style.ItemSpacing.x));
    ImGui::InputTextWithHint("##path", "assets/icon.png", &path);
    tip(tooltip);
    ImGui::SameLine();
    if (ImGui::Button("Choose...")) {
        std::error_code ec;
        const stdfs::path assets = stdfs::path(ps.project_dir()) / "assets";
        const std::string start = stdfs::is_directory(assets, ec) ? assets.string() : ps.project_dir();
        const std::string picked = pick_file("Choose a square PNG or JPG image", start, "Images", {"png", "jpg", "jpeg"});
        if (!picked.empty()) {
            auto imported = import_icon_file(ps.project_dir(), picked);
            if (!imported.ok()) {
                ed.notify(imported.error().message + " " + imported.error().hint, 2);
            } else {
                path = imported->relPath;
                if (imported->copied) ed.notify(imported->note, 0);
            }
        }
    }
    ed.at_track(std::string("platform:choose:") + id);
    tip("Picks a PNG or JPG. A file outside the project is copied into its assets folder (icons must be inside the project; "
        "nothing is overwritten).");
    ImGui::SameLine();
    ImGui::BeginDisabled(path.empty());
    if (ImGui::Button("Clear")) path.clear();
    ImGui::EndDisabled();
    ed.at_track(std::string("platform:clear:") + id);

    if (own.empty()) {
        note(usingFallback ? "Uses the game icon (" + fall + ")." : emptyNote);
    } else if (check.loaded) {
        wrapped(kReady, std::to_string(check.size) + " x " + std::to_string(check.size) + " px");
    }
    if (!check.error.empty() && !usingFallback) wrapped(kFailed, check.error);
    if (usingFallback && !check.loaded && !check.error.empty()) wrapped(kFailed, "The game icon cannot be used: " + check.error);
    if (!usingFallback)
        for (const std::string& w : check.warnings) wrapped(kWarn, w);
    field_problems(problems, pointer);
    ImGui::EndGroup();
    ImGui::PopID();
}

// A list of strings (categories, permissions): one text box each with a remove button, and a menu of usual entries to add.
void string_list(Editor& ed, const char* id, std::vector<std::string>& list, const std::vector<SettingsChoice>& presets, const char* addLabel,
                 const SettingsProblems& problems, const std::string& pointerBase, float width) {
    ImGui::PushID(id);
    int remove = -1;
    for (size_t i = 0; i < list.size(); ++i) {
        ImGui::PushID(int(i));
        ImGui::SetNextItemWidth(width);
        ImGui::InputText("##item", &list[i]);
        ImGui::SameLine();
        if (ImGui::SmallButton("Remove")) remove = int(i);
        ImGui::PopID();
        field_problems(problems, pointerBase + "/" + std::to_string(i));
    }
    if (remove >= 0) list.erase(list.begin() + remove);
    ImGui::SetNextItemWidth(width);
    if (ImGui::BeginCombo("##add", addLabel)) {
        for (const SettingsChoice& c : presets) {
            if (std::find(list.begin(), list.end(), c.value) != list.end()) continue;
            if (ImGui::Selectable(c.label)) list.push_back(c.value);
            tip(c.note);
        }
        if (ImGui::Selectable("Another...")) list.emplace_back();
        ImGui::EndCombo();
    }
    ed.at_track(std::string("platform:add:") + id);
    ImGui::PopID();
}

// An "R, G, B" colour box that edits a "#RRGGBB" setting; typing the hex works too.
bool color_hex(const char* id, std::string& hex) {
    const Color c = icon_color_from_hex(hex, Color::white());
    float rgb[3] = {c.r, c.g, c.b};
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 12.0f);
    if (ImGui::ColorEdit3(id, rgb, ImGuiColorEditFlags_DisplayHex | ImGuiColorEditFlags_NoAlpha | ImGuiColorEditFlags_InputRGB)) {
        hex = rgb_hex(rgb[0], rgb[1], rgb[2]);
        return true;
    }
    return false;
}

// ---- tabs ---------------------------------------------------------------------------------------------------------

void general_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    ImGui::SeparatorText("Game icon");
    note("One square image (1024x1024 recommended, at least 512x512) becomes the icon of every platform: the .icns of a macOS app, "
         "the icon of the Windows exe and its window, the launcher icons of Android, the App Store icon of iOS and the PNG of a "
         "Linux build. A platform's own tab can use another picture.");
    Form form("##general_icon");
    form.row("Icon", "factoria.json: icon. The project-relative path of a square PNG or JPG. No icon at all means each platform's "
                     "default icon (and a warning when you export).");
    icon_field(ed, "icon", ps.project.icon, {}, kRecommendedIconSize, "No icon: each platform uses its default icon and the export warns.",
               problems, "/icon", "A square PNG or JPG inside the project, e.g. assets/icon.png");

    // Which platforms have an icon of their own.
    std::vector<std::string> own;
    if (!clean_project_path(ps.project.windows.icon).empty()) own.push_back("Windows");
    if (!clean_project_path(ps.project.macos.icon).empty()) own.push_back("macOS");
    if (!clean_project_path(ps.project.linux.icon).empty()) own.push_back("Linux");
    if (!clean_project_path(ps.project.android.icon).empty()) own.push_back("Android");
    if (!clean_project_path(ps.project.ios.icon).empty()) own.push_back("iOS");
    if (!own.empty()) {
        std::string list;
        for (const std::string& o : own) list += (list.empty() ? "" : ", ") + o;
        note("Platforms with an icon of their own: " + list + ".");
    }

    ImGui::SeparatorText("The game");
    Form info("##general_info");
    auto line = [&](const char* label, const std::string& value, const char* tooltip) {
        info.row(label, tooltip);
        ImGui::TextUnformatted(value.empty() ? "-" : value.c_str());
    };
    line("Name", ps.info.name, "factoria.json: name. The name of the app on every platform.");
    line("Id", ps.info.id, "factoria.json: id. The reverse-DNS identifier (com.example.mygame): Android's applicationId and iOS's bundle id.");
    line("Version", ps.info.version, "factoria.json: version. Android's versionName and, unless you set one, the numbers behind its versionCode.");
    line("Orientation", ps.info.orientation, "factoria.json: display.orientation. landscape, portrait or any (phones).");
    line("Design resolution", ps.info.width > 0 ? std::to_string(ps.info.width) + " x " + std::to_string(ps.info.height) : std::string(),
         "factoria.json: display.width and display.height.");
    note("These come from factoria.json and are not edited here: ask the AI Assistant (\"set the game version to 1.2.0\") or edit the file.");
}

void windows_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    note("The Windows export is a folder with the game's .exe. Its icon is baked into the .exe (16 to 256 px) and also shows on the game window.");
    Form form("##windows");
    form.row("Icon", "factoria.json: export.windows.icon. The icon of the .exe and of the game window. Empty: the game icon.");
    icon_field(ed, "windows-icon", ps.project.windows.icon, ps.project.icon, kRecommendedIconSize, "No icon: the .exe keeps the engine's default icon and the export warns.",
               problems, "/export/windows/icon", "A square PNG or JPG inside the project. Empty: the game icon (General tab).");
}

void macos_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    note("The macOS export is an .app. These fields end up in its Info.plist.");
    MacosExportSettings& m = ps.project.macos;
    Form form("##macos");
    form.row("Icon", "factoria.json: export.macos.icon. The icon of the .app (an .icns with 16 to 1024 px and the @2x sizes). Empty: the game icon.");
    icon_field(ed, "macos-icon", m.icon, ps.project.icon, kRecommendedIconSize, "No icon: the app has the generic icon and the export warns.",
               problems, "/export/macos/icon", "A square PNG or JPG inside the project. Empty: the game icon (General tab).");

    form.row("Category", "factoria.json: export.macos.category (LSApplicationCategoryType in Info.plist). The Mac App Store category of the app; "
                         "pick one of Apple's game categories or type another one.");
    {
        const SettingsChoice* known = find_choice(mac_game_categories(), m.category.empty() ? "public.app-category.games" : m.category);
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 14.0f);
        if (ImGui::BeginCombo("##category", known ? known->label : "Other")) {
            for (const SettingsChoice& c : mac_game_categories())
                if (ImGui::Selectable(c.label, known == &c)) m.category = c.value;
            ImGui::EndCombo();
        }
        ImGui::SameLine();
        ImGui::SetNextItemWidth(-FLT_MIN);
        ImGui::InputTextWithHint("##categorytext", "public.app-category.games", &m.category);
        field_problems(problems, "/export/macos/category");
    }
    text_row(form, "Minimum macOS", "factoria.json: export.macos.minimumSystemVersion (LSMinimumSystemVersion). The oldest macOS the app runs on, "
                                    "as major.minor. 11.0 is the lowest: the player needs macOS 11.",
             "##minmac", m.minimumSystemVersion, "11.0", problems, "/export/macos/minimumSystemVersion");
    text_row(form, "Copyright", "factoria.json: export.macos.copyright (NSHumanReadableCopyright). The notice shown in the app's About information. Empty: none.",
             "##copyright", m.copyright, "Copyright 2026 My Studio", problems, "/export/macos/copyright");
}

void linux_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    note("The Linux export is a folder with the game's executable, a PNG icon and a .desktop file for the application menu.");
    LinuxExportSettings& l = ps.project.linux;
    Form form("##linux");
    form.row("Icon", "factoria.json: export.linux.icon. The PNG of the build (256 px) and the window icon. Empty: the game icon.");
    icon_field(ed, "linux-icon", l.icon, ps.project.icon, kRecommendedIconSize, "No icon: the build has none and the export warns.",
               problems, "/export/linux/icon", "A square PNG or JPG inside the project. Empty: the game icon (General tab).");
    form.row("Categories", "factoria.json: export.linux.categories. The menu categories of the .desktop file (its Categories= line; the "
                           "entries are joined with ';'). Default: Game.");
    string_list(ed, "linux-categories", l.categories, linux_game_categories(), "Add a category...", problems, "/export/linux/categories",
                ImGui::GetFontSize() * 14.0f);
}

void android_this_computer(Editor& ed, PlatformSettings& ps);

void android_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    AndroidExportSettings& a = ps.project.android;
    note("The Android export builds an APK or an Android App Bundle from a Gradle project it writes.");

    ImGui::SeparatorText("Build");
    {
        Form form("##android_build");
        form.row("Format", "factoria.json: export.android.format. What the export produces: an APK, an AAB (Google Play bundle) or only the "
                           "Gradle project. The Export window's format menu changes this same setting.");
        const SettingsChoice* cur = find_choice(android_formats(), a.format);
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 16.0f);
        if (ImGui::BeginCombo("##format", cur ? cur->label : a.format.c_str())) {
            for (const SettingsChoice& c : android_formats()) {
                if (ImGui::Selectable(c.label, a.format == c.value)) a.format = c.value;
                tip(c.note);
            }
            ImGui::EndCombo();
        }
        ed.at_track("platform:android-format");
        if (cur) tip(cur->note);
        field_problems(problems, "/export/android/format");
        note(a.format == "gradle" ? "No JDK or Android SDK needed: nothing is built."
                                  : "Building needs a JDK 17+ and the Android SDK (see This computer, below). Release builds use the signing key below.");

        form.row("Version code", "factoria.json: export.android.versionCode. A whole number that must grow with every upload to Google Play. "
                                 "0: derived from the game's version (1.2.3 becomes 10203).");
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 8.0f);
        ImGui::InputInt("##versioncode", &a.versionCode, 0, 0);
        ImGui::SameLine();
        if (a.versionCode <= 0) ImGui::TextDisabled("0 = from the version (%s): %d", ps.info.version.c_str(), ps.derived_version_code());
        else ImGui::TextDisabled("(the game's version %s would give %d)", ps.info.version.c_str(), android_version_code_from(ps.info.version));
        field_problems(problems, "/export/android/versionCode");

        form.row("Minimum Android", "factoria.json: export.android.minSdk. The lowest Android API level the app installs on. 26 (Android 8.0) is "
                                    "the lowest; it must not be above the target.");
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 8.0f);
        ImGui::InputInt("##minsdk", &a.minSdk, 0, 0);
        field_problems(problems, "/export/android/minSdk");
        form.row("Target Android", "factoria.json: export.android.targetSdk (also the compileSdk). The Android API level the app is built and tested "
                                   "against. Default 36; Google Play asks for a recent one for new apps and updates.");
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 8.0f);
        ImGui::InputInt("##targetsdk", &a.targetSdk, 0, 0);
        field_problems(problems, "/export/android/targetSdk");
        form.row("Permissions", "factoria.json: export.android.permissions. Extra <uses-permission> entries for what the game's scripts or features "
                                "need (the engine itself needs none).");
        const std::vector<SettingsChoice> presets = {
            {"android.permission.INTERNET", "INTERNET", "Open network connections."},
            {"android.permission.ACCESS_NETWORK_STATE", "ACCESS_NETWORK_STATE", "Know whether the phone is online."},
            {"android.permission.VIBRATE", "VIBRATE", "Vibrate the phone."},
            {"android.permission.WAKE_LOCK", "WAKE_LOCK", "Keep the screen or CPU awake."},
        };
        string_list(ed, "android-permissions", a.permissions, presets, "Add a permission...", problems, "/export/android/permissions",
                    ImGui::GetFontSize() * 22.0f);
    }

    ImGui::SeparatorText("Icons");
    {
        Form form("##android_icons");
        form.row("Icon", "factoria.json: export.android.icon. The launcher icons (48 to 192 px, round and square) are generated from it unless the "
                         "adaptive icon below says otherwise. Empty: the game icon.");
        icon_field(ed, "android-icon", a.icon, ps.project.icon, kRecommendedIconSize, "No icon: the app has the default Android icon and the export warns.",
                   problems, "/export/android/icon", "A square PNG or JPG inside the project. Empty: the game icon (General tab).");
        form.row("Adaptive foreground", "factoria.json: export.android.adaptiveIcon.foreground. The 108dp foreground layer of the adaptive icon "
                                        "(Android 8+): a square PNG of the whole layer (432x432 recommended) on a transparent background; only its "
                                        "inner 66dp circle is sure to stay visible. Empty: the icon scaled into that safe zone.");
        icon_field(ed, "android-foreground", a.adaptiveIcon.foreground, {}, 432, "Empty: the icon above, scaled into the safe zone of the layer.",
                   problems, "/export/android/adaptiveIcon/foreground", "A square PNG of the whole 108dp layer, transparent around the picture.");
        form.row("Adaptive background", "factoria.json: export.android.adaptiveIcon.background. The layer behind the foreground: a colour, or an image "
                                        "(432x432 recommended) that fills it. Default: white.");
        std::string& bg = a.adaptiveIcon.background;
        const int mode = ed.platformBgMode_ >= 0 ? ed.platformBgMode_ : (bg.empty() || bg[0] == '#' ? 0 : 1);
        ImGui::SetNextItemWidth(ImGui::GetFontSize() * 7.0f);
        if (ImGui::BeginCombo("##bgmode", mode == 0 ? "Color" : "Image")) {
            if (ImGui::Selectable("Color", mode == 0) && mode != 0) {
                ed.platformBgMode_ = 0;
                bg = "#FFFFFF";
            }
            if (ImGui::Selectable("Image", mode == 1) && mode != 1) {
                ed.platformBgMode_ = 1;
                bg.clear();
            }
            ImGui::EndCombo();
        }
        ImGui::SameLine();
        if (mode == 0) color_hex("##bgcolor", bg);
        else ImGui::NewLine();
        if (mode == 1)
            icon_field(ed, "android-background", bg, {}, 432, "Choose an image, or switch to Color (the default is white).",
                       problems, "/export/android/adaptiveIcon/background", "A square picture that fills the whole 108dp layer.");
        field_problems(problems, "/export/android/adaptiveIcon/background");
        form.row("Themed icon", "factoria.json: export.android.adaptiveIcon.monochrome. Optional single-colour PNG with transparency (432x432 "
                                "recommended) that Android 13+ tints for themed icons. Empty: the icon is not themed.");
        icon_field(ed, "android-monochrome", a.adaptiveIcon.monochrome, {}, 432, "Optional: without it the icon keeps its own colours with themed icons on.",
                   problems, "/export/android/adaptiveIcon/monochrome", "A single-colour PNG with transparency.");
    }

    ImGui::SeparatorText("Signing (release builds)");
    {
        Form form("##android_signing");
        AndroidSigningSettings& sg = a.signing;
        form.row("Keystore", "factoria.json: export.android.signing.keystore. The keystore file (.keystore or .jks) that signs release builds: "
                             "project-relative, or absolute (keystores are better kept outside the repository).");
        const float buttonsW = ImGui::CalcTextSize("Choose...").x + ImGui::CalcTextSize("Create keystore...").x +
                               ImGui::GetStyle().FramePadding.x * 8 + ImGui::GetStyle().ItemSpacing.x * 3;
        ImGui::SetNextItemWidth(std::max(120.0f, ImGui::GetContentRegionAvail().x - buttonsW));
        ImGui::InputTextWithHint("##keystore", "keys/upload.keystore", &sg.keystore);
        ImGui::SameLine();
        if (ImGui::Button("Choose...##keystore")) {
            const std::string picked = pick_file("Choose the keystore", ps.project_dir(), "Keystores", {});
            if (!picked.empty()) sg.keystore = project_relative_or_absolute(ps.project_dir(), picked);
        }
        ed.at_track("platform:keystore-choose");
        ImGui::SameLine();
        if (ImGui::Button("Create keystore...")) {
            ed.keystoreForm_ = default_keystore_form(ps.project_dir());
            ed.keystoreError_.clear();
            ed.keystoreOpenRequest_ = true;
        }
        ed.at_track("platform:keystore-create");
        tip("Makes a new signing key with the JDK's keytool (Java must be found: see This computer, below).");
        field_problems(problems, "/export/android/signing/keystore");
        if (!clean_project_path(sg.keystore).empty()) {
            if (ps.keystore_exists()) wrapped(kReady, "Keystore found: " + ps.keystore_path());
            else wrapped(kWarn, "No file at " + ps.keystore_path() + " yet. Choose the keystore or create one.");
        }
        text_row(form, "Key alias", "factoria.json: export.android.signing.alias. The alias of the signing key inside the keystore (the -alias given "
                                    "to keytool), e.g. upload.",
                 "##alias", sg.alias, "upload", problems, "/export/android/signing/alias");
        form.row("Passwords", "Never stored in the project. They come from the FACTORIA_ANDROID_KEYSTORE_PASSWORD and FACTORIA_ANDROID_KEY_PASSWORD "
                              "environment variables, or from this computer's settings below.");
        const SecretStatus ks = ps.keystore_password_status(), ky = ps.key_password_status();
        ImGui::TextColored(ks.set ? kReady : kWarn, "Keystore password: %s", ks.text.c_str());
        ImGui::TextColored(ky.set ? kReady : kWarn, "Key password: %s", ky.text.c_str());
    }
    note("A release build without a keystore is signed with the debug key: fine for trying it on a phone, but Google Play rejects it. Debug builds always "
         "use the debug key. Keep the keystore and its password safe (losing them means you can never update the app on Google Play) and never commit "
         "the keystore to a public repository.");

    android_this_computer(ed, ps);
}

void android_this_computer(Editor& ed, PlatformSettings& ps) {
    ImGui::SeparatorText("This computer");
    note("Not part of the game: these are saved in " + ps.machine_path() + " and apply to every project on this computer.");
    MachineExportConfig& m = ps.machine;
    Form form("##android_machine");
    auto folder_row = [&](const char* label, const char* tooltip, const char* id, std::string& value, const char* hint, const char* pickTitle) {
        form.row(label, tooltip);
        const float buttonsW = ImGui::CalcTextSize("Choose...").x + ImGui::CalcTextSize("Clear").x + ImGui::GetStyle().FramePadding.x * 4 +
                               ImGui::GetStyle().ItemSpacing.x * 2;
        ImGui::SetNextItemWidth(std::max(120.0f, ImGui::GetContentRegionAvail().x - buttonsW));
        ImGui::InputTextWithHint((std::string("##") + id).c_str(), hint, &value);
        ImGui::SameLine();
        if (ImGui::Button((std::string("Choose...##") + id).c_str())) {
            const std::string picked = pick_folder(pickTitle, value.empty() ? home_dir() : value);
            if (!picked.empty()) value = picked;
        }
        ed.at_track(std::string("platform:choose:") + id);
        ImGui::SameLine();
        ImGui::BeginDisabled(value.empty());
        if (ImGui::Button((std::string("Clear##") + id).c_str())) value.clear();
        ImGui::EndDisabled();
        tip("Clear: look for it by itself.");
    };
    folder_row("JDK folder", "~/.factoria/export.json: android.jdk. The folder of a JDK 17 or newer (it holds bin/java). Empty: FactorIA looks at JAVA_HOME, "
                             "Android Studio's bundled JDK and Unity Hub's.",
               "jdk", m.androidJdk, "auto-detect", "Choose the JDK folder (it has bin/java)");
    folder_row("Android SDK folder", "~/.factoria/export.json: android.sdk. The folder of the Android SDK. Empty: FactorIA looks at ANDROID_HOME, the "
                                     "usual Android Studio folder and Unity Hub's.",
               "sdk", m.androidSdk, "auto-detect", "Choose the Android SDK folder");

    form.row("Found", "What an Android export would use now, with this computer's settings above (searching folders only: nothing is started).");
    const AndroidToolchain& tc = ps.toolchain();
    if (!tc.jdk.empty())
        ImGui::TextColored(kReady, "JDK %d: %s (%s)", tc.jdkMajor, tc.jdk.c_str(), tc.jdkFrom.c_str());
    if (!tc.sdk.empty())
        ImGui::TextColored(kReady, "Android SDK: %s (%s)", tc.sdk.c_str(), tc.sdkFrom.c_str());
    for (const std::string& p : tc.problems) wrapped(kFailed, p);
    for (const std::string& w : tc.warnings) wrapped(kWarn, w);
    if (tc.ok() && tc.warnings.empty()) ImGui::TextColored(kReady, "Ready to build.");
    if (ImGui::SmallButton("Check again")) (void)ps.toolchain(true);
    ed.at_track("platform:toolchain-refresh");
    tip("Looks at the folders again (after installing a JDK or the Android SDK).");

    form.row("Signing passwords", "~/.factoria/export.json: android.keystorePassword / android.keyPassword. The FACTORIA_ANDROID_KEYSTORE_PASSWORD and "
                                  "FACTORIA_ANDROID_KEY_PASSWORD environment variables win over them. Without a key password the keystore password is used.");
    ImGui::Checkbox("Remember them on this computer", &ps.rememberPasswords);
    ed.at_track("platform:remember");
    tip("Keeps the passwords in " + ps.machine_path() + ", in plain text, readable only by you. Untick it to remove them from the file (the environment "
        "variables still work). Never put them in the project.");
    ImGui::BeginDisabled(!ps.rememberPasswords);
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 14.0f);
    ImGui::InputTextWithHint("##kspw", "keystore password", &m.androidKeystorePassword, ImGuiInputTextFlags_Password);
    ImGui::SameLine();
    ImGui::SetNextItemWidth(ImGui::GetFontSize() * 14.0f);
    ImGui::InputTextWithHint("##keypw", "key password (optional)", &m.androidKeyPassword, ImGuiInputTextFlags_Password);
    ImGui::EndDisabled();
    for (const std::string& w : m.warnings) wrapped(kWarn, w);
}

void ios_tab(Editor& ed, PlatformSettings& ps, const SettingsProblems& problems) {
    note("The iOS export is an Xcode project and a build_ios.sh script; build it on a Mac with Xcode.");
    IosExportSettings& s = ps.project.ios;
    Form form("##ios");
    form.row("Icon", "factoria.json: export.ios.icon. The App Store icon (1024x1024, no transparency) is made from it. Empty: the game icon.");
    icon_field(ed, "ios-icon", s.icon, ps.project.icon, kRecommendedIconSize, "No icon: the app has the blank default icon and the export warns.",
               problems, "/export/ios/icon", "A square PNG or JPG inside the project. Empty: the game icon (General tab).");
    form.row("Icon background", "factoria.json: export.ios.iconBackground. The App Store rejects icons with transparency, so transparent pixels of the "
                                "icon take this colour. Default: white.");
    {
        std::string hex = s.iconBackground.empty() ? "#FFFFFF" : s.iconBackground;
        if (color_hex("##iconbg", hex)) s.iconBackground = hex;
        field_problems(problems, "/export/ios/iconBackground");
    }
    text_row(form, "Team ID", "factoria.json: export.ios.teamId. Your Apple developer Team ID (10 capital letters and digits, at developer.apple.com/account "
                              "under Membership details), used to sign device builds. Default: the FA_IOS_DEVELOPMENT_TEAM environment variable, which wins "
                              "when it is set.",
             "##team", s.teamId, "ABCDE12345 (empty: FA_IOS_DEVELOPMENT_TEAM)", problems, "/export/ios/teamId");
    const std::string buildHint = ps.info.version.empty() ? "the game's version" : ps.info.version + " (the game's version)";
    text_row(form, "Build number", "factoria.json: export.ios.buildNumber (CFBundleVersion). Up to three whole numbers separated by dots, e.g. 42 or 1.2.3; it "
                                   "must grow with every App Store upload of the same version. Empty: the game's version.",
             "##build", s.buildNumber, buildHint.c_str(), problems, "/export/ios/buildNumber");
}

// ---- the Create keystore popup ------------------------------------------------------------------------------------

void keystore_popup(Editor& ed) {
    PlatformSettings& ps = ed.platformSettings_;
    if (ed.keystoreOpenRequest_) {
        ImGui::OpenPopup("Create keystore##keystore");
        ed.keystoreOpenRequest_ = false;
        ed.keystoreOpen_ = true;
    }
    ImGui::SetNextWindowSize(ImVec2(ImGui::GetFontSize() * 40.0f, 0));
    if (!ImGui::BeginPopupModal("Create keystore##keystore", nullptr, ImGuiWindowFlags_NoSavedSettings)) return;
    if (!ed.keystoreOpen_) {  // the job finished and applied itself
        ImGui::CloseCurrentPopup();
        ImGui::EndPopup();
        return;
    }
    const bool busy = ed.keystoreJob_.running();
    KeystoreForm& f = ed.keystoreForm_;
    ImGui::PushTextWrapPos(0);
    note("Makes a new signing key with the JDK's keytool: one keystore file with one key, valid for about 27 years. Google Play wants the same key for "
         "every update of the app.");
    ImGui::BeginDisabled(busy);
    {
        Form form("##keystore_form");
        form.row("Keystore file", "Where to create it: project-relative (keys/upload.keystore) or absolute. Keystores are better kept outside the repository.");
        const float folderW = ImGui::CalcTextSize("Folder...").x + ImGui::GetStyle().FramePadding.x * 2 + ImGui::GetStyle().ItemSpacing.x;
        ImGui::SetNextItemWidth(ImGui::GetContentRegionAvail().x - folderW);
        ImGui::InputText("##kpath", &f.path);
        ImGui::SameLine();
        if (ImGui::Button("Folder...")) {
            const std::string picked = pick_folder("Create the keystore in", ps.project_dir());
            if (!picked.empty()) {
                const std::string name = stdfs::path(f.path).filename().string();
                f.path = project_relative_or_absolute(ps.project_dir(), (stdfs::path(picked) / (name.empty() ? "upload.keystore" : name)).string());
            }
        }
        ed.at_track("platform:keystore-folder");
        text_row(form, "Alias", "The name of the key inside the keystore. You give it to the build as signing.alias.", "##kalias", f.alias, "upload", {}, "");
        text_row(form, "Password", "At least 6 characters. It protects the keystore and the key (one password for both). Write it down: nobody can recover it.",
                 "##kpw", f.password, "", {}, "", ImGuiInputTextFlags_Password);
        text_row(form, "Repeat password", "The same password again.", "##kpw2", f.repeat, "", {}, "", ImGuiInputTextFlags_Password);
        text_row(form, "Your name or studio", "The name of the certificate (CN). Anyone can see it in the signed app.", "##kname", f.name,
                 "Jane Doe or My Studio", {}, "");
        text_row(form, "Organization", "Optional: the O of the certificate.", "##korg", f.organization, "optional", {}, "");
        text_row(form, "Country", "Optional: two letters, the C of the certificate (ES, US...).", "##kcountry", f.country, "optional", {}, "");
    }
    ImGui::Checkbox("Remember the password on this computer", &f.remember);
    tip("Fills in the signing passwords of This computer (saved in export.json when you press Save in the Platform settings window).");
    const std::string typed = clean_project_path(f.path);
    const bool insideProject = !typed.empty() && typed[0] != '/' && !(typed.size() >= 2 && typed[1] == ':');
    if (insideProject) {
        ImGui::Checkbox("Keep the keystore out of git (add it to .gitignore)", &f.gitignore);
        tip("Adds the keystore's path to the project's .gitignore when the project uses git.");
    }
    ImGui::EndDisabled();
    wrapped(kWarn, "Keep the keystore file and its password safe. If you lose them you can never publish an update of the app on Google Play. Never commit "
                   "the keystore to a public repository.");

    auto req = make_keystore_request(f, ps.project_dir(), ps.toolchain().jdk);
    if (!ed.keystoreError_.empty()) wrapped(kFailed, ed.keystoreError_);
    else if (!req.ok()) wrapped(kWarn, req.error().message);
    else if (busy) ImGui::TextUnformatted("Creating the keystore...");
    ImGui::BeginDisabled(busy || !req.ok());
    if (ImGui::Button("Create", ImVec2(120, 0)) && req.ok()) {
        ed.keystoreError_.clear();
        ed.keystoreRunning_ = *req;
        ed.keystoreRunningForm_ = f;
        ed.keystoreJob_.start(*req);
    }
    ImGui::EndDisabled();
    ed.at_track("platform:keystore-create-confirm");
    ImGui::SameLine();
    ImGui::BeginDisabled(busy);
    if (ImGui::Button("Cancel", ImVec2(120, 0)) || (!busy && ImGui::IsKeyPressed(ImGuiKey_Escape))) {
        f.password.clear();
        f.repeat.clear();
        ed.keystoreOpen_ = false;
        ImGui::CloseCurrentPopup();
    }
    ImGui::EndDisabled();
    ed.at_track("platform:keystore-cancel");
    ImGui::PopTextWrapPos();
    ImGui::EndPopup();
}

}  // namespace

// =====================================================================================================================

void Editor::open_platform_settings(SettingsTab tab) {
    if (!engine_) return;
    if (!platformSettings_.loaded() || platformSettings_.project_dir() != projectDir_ || !platformSettings_.dirty()) {
        platformSettings_.load(projectDir_);
        iconChecks_.clear();
        platformBgMode_ = -1;
        platformMessage_.clear();
        platformDiskChanged_ = false;
    }
    showPlatformSettings_ = true;
    platformFocus_ = true;
    platformTab_ = tab;
    platformTabSet_ = true;
}

void Editor::reset_platform_settings_state() {
    keystoreJob_.wait();
    (void)keystoreJob_.take_result();
    platformSettings_.clear();
    iconChecks_.clear();
    showPlatformSettings_ = false;
    platformCloseAsk_ = false;
    platformDiskChanged_ = false;
    keystoreOpen_ = false;
    keystoreOpenRequest_ = false;
    keystoreForm_ = KeystoreForm{};
    keystoreError_.clear();
    platformMessage_.clear();
    platformBgMode_ = -1;
}

void Editor::request_close_platform_settings() {
    if (platformSettings_.dirty()) platformCloseAsk_ = true;
    else showPlatformSettings_ = false;
}

void Editor::set_android_format(const std::string& format) {
    if (auto r = save_android_format(projectDir_, format); !r.ok()) {
        notify("Cannot change the Android format: " + r.error().message + " " + r.error().hint, 2);
        return;
    }
    platformSettings_.note_saved_android_format(format);
    exportChecked_ = -100;
}

const TextureEntry* Editor::icon_preview(const std::string& relPath) {
    const std::string rel = clean_project_path(relPath);
    if (rel.empty() || !uiUp_) return nullptr;
    IconPreview& p = iconPreviews_[rel];
    if (time_ - p.checkedAt >= 0.5) {  // the file may have been replaced (the AI makes icons too)
        p.checkedAt = time_;
        const stdfs::path full = stdfs::path(projectDir_) / rel;
        std::error_code ec;
        const auto t = stdfs::last_write_time(full, ec);
        const std::int64_t mtime = ec ? -1 : static_cast<std::int64_t>(t.time_since_epoch().count());
        if (mtime != p.mtime) {
            p.mtime = mtime;
            if (p.tex.view || p.tex.image) ui::destroy_texture(p.tex.image, p.tex.view);
            p.tex = TextureEntry{};
            p.tex.failed = true;
            if (mtime >= 0) {
                std::ifstream in(full, std::ios::binary);
                const std::vector<std::uint8_t> bytes((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
                auto img = decode_image(bytes.data(), bytes.size());
                if (img.ok() && !img->empty()) {
                    const int longSide = std::max(img->width, img->height);
                    Image small = longSide > 256 ? resize_image(*img, std::max(1, img->width * 256 / longSide), std::max(1, img->height * 256 / longSide))
                                                 : std::move(*img);
                    if (ui::make_texture(small.width, small.height, small.rgba.data(), p.tex.image, p.tex.view)) {
                        p.tex.w = small.width;
                        p.tex.h = small.height;
                        p.tex.failed = false;
                    }
                }
            }
        }
    }
    return p.tex.failed ? nullptr : &p.tex;
}

void Editor::poll_platform_settings() {
    // A keystore that was being created finished: use it (fills the signing settings), or say why it failed.
    if (auto done = keystoreJob_.take_result()) {
        const KeystoreRequest req = keystoreRunning_;
        const KeystoreForm form = keystoreRunningForm_;
        keystoreRunning_.password.clear();
        keystoreRunningForm_.password.clear();
        keystoreRunningForm_.repeat.clear();
        if (!done->ok()) {
            keystoreError_ = done->error().message + " " + done->error().hint;
        } else {
            keystoreError_.clear();
            PlatformSettings& ps = platformSettings_;
            const std::string setting = project_relative_or_absolute(ps.project_dir(), req.path);
            ps.project.android.signing.keystore = setting;
            ps.project.android.signing.alias = req.alias;
            std::string text = "Created the keystore " + req.path + ".";
            if (form.remember) {
                ps.rememberPasswords = true;
                ps.machine.androidKeystorePassword = req.password;
                ps.machine.androidKeyPassword.clear();  // one password: the key uses the keystore's
            }
            if (form.gitignore && setting.rfind("/", 0) != 0 && !(setting.size() > 1 && setting[1] == ':'))
                if (std::string ignored = add_to_gitignore(ps.project_dir(), setting); !ignored.empty()) text += " " + ignored;
            text += " Press Save to keep it in the settings, and back the file up.";
            notify(text, 0);
            keystoreForm_.password.clear();
            keystoreForm_.repeat.clear();
            keystoreOpen_ = false;
        }
    }
    if (!showPlatformSettings_) return;
    if (time_ - platformPolled_ < 0.5) return;
    platformPolled_ = time_;
    if (platformSettings_.project_file_changed()) {  // an AI or another tool wrote factoria.json
        if (!platformSettings_.project_dirty()) {
            platformSettings_.reload_project();
            iconChecks_.clear();
            platformDiskChanged_ = false;
            notify("factoria.json changed on disk: the platform settings were reloaded.", 0);
        } else {
            platformDiskChanged_ = true;
        }
    }
}

void Editor::draw_platform_settings_window() {
    if (!showPlatformSettings_ || !engine_) return;
    PlatformSettings& ps = platformSettings_;
    if (!ps.loaded()) {
        showPlatformSettings_ = false;
        return;
    }
    const ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowSize(ImVec2(860, 740), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowPos(ImVec2(vp->WorkPos.x + vp->WorkSize.x * 0.5f, vp->WorkPos.y + vp->WorkSize.y * 0.5f), ImGuiCond_Appearing,
                            ImVec2(0.5f, 0.5f));
    if (platformFocus_) {
        ImGui::SetNextWindowFocus();
        platformFocus_ = false;
    }
    bool open = true;
    const bool visible = ImGui::Begin("Platform settings###PlatformSettings", &open, ImGuiWindowFlags_NoDocking);
    if (!open) request_close_platform_settings();
    if (!visible) {
        ImGui::End();
        return;
    }
    ImGui::PushTextWrapPos(0);
    const SettingsProblems problems = ps.validate();

    note("What an export needs besides the game: its icon, and for each platform the fields of its app. They are saved in factoria.json (committed with "
         "the game) except This computer, which lives in your user folder. Hover a label to see what it changes.");

    // ---- what is wrong with the files as they are on disk
    if (!ps.fileError.empty()) wrapped(kFailed, ps.fileError);
    if (!ps.parseErrors.empty()) {
        wrapped(kFailed, "factoria.json has " + std::to_string(ps.parseErrors.size()) + " problem(s) in icon / export. The fields below show what could "
                         "be read; fix the file (or ask the AI) and this window reloads it:");
        for (const ExportSettingsIssue& e : ps.parseErrors) wrapped(kFailed, "- " + e.to_string());
    }
    for (const ExportSettingsIssue& w : ps.parseWarnings) wrapped(kWarn, "- " + w.to_string());
    if (!ps.machineError.empty()) wrapped(kFailed, ps.machineError);
    if (platformDiskChanged_) {
        wrapped(kWarn, "factoria.json changed on disk while you have unsaved edits here.");
        ImGui::SameLine();
        if (ImGui::SmallButton("Reload")) {
            ps.reload_project();
            iconChecks_.clear();
            platformDiskChanged_ = false;
        }
        at_track("platform:disk-reload");
        ImGui::SameLine();
        if (ImGui::SmallButton("Keep my edits")) platformDiskChanged_ = false;
    }

    // ---- tabs
    const float footerH = ImGui::GetFrameHeight() * 2.0f + ImGui::GetStyle().ItemSpacing.y * 4.0f + ImGui::GetStyle().WindowPadding.y;
    const SettingsTab wanted = platformTab_;  // the tab to select when it was asked for (open_platform_settings)
    const bool selectWanted = platformTabSet_;
    if (ImGui::BeginTabBar("##platformtabs")) {
        for (int i = 0; i < kSettingsTabCount; ++i) {
            const SettingsTab tab = static_cast<SettingsTab>(i);
            const bool select = selectWanted && wanted == tab;
            if (ImGui::BeginTabItem(settings_tab_label(tab), nullptr, select ? ImGuiTabItemFlags_SetSelected : 0)) {
                at_track(std::string("platform:tab:") + (i == 0 ? "general" : settings_tab_platform(tab)));
                platformTab_ = tab;
                if (ImGui::BeginChild("##tabbody", ImVec2(0, -footerH), ImGuiChildFlags_None)) {
                    switch (tab) {
                        case SettingsTab::General: general_tab(*this, ps, problems); break;
                        case SettingsTab::Windows: windows_tab(*this, ps, problems); break;
                        case SettingsTab::Macos: macos_tab(*this, ps, problems); break;
                        case SettingsTab::Linux: linux_tab(*this, ps, problems); break;
                        case SettingsTab::Android: android_tab(*this, ps, problems); break;
                        case SettingsTab::Ios: ios_tab(*this, ps, problems); break;
                    }
                }
                ImGui::EndChild();
                ImGui::EndTabItem();
            } else {
                at_track(std::string("platform:tab:") + (i == 0 ? "general" : settings_tab_platform(tab)));
            }
        }
        ImGui::EndTabBar();
    }
    platformTabSet_ = false;

    // ---- Save / Revert / Close
    ImGui::Separator();
    const bool dirty = ps.dirty();
    const bool bad = !problems.errors.empty();
    if (!platformMessage_.empty()) wrapped(kFailed, platformMessage_);
    else if (bad) ImGui::TextColored(kFailed, "%zu field(s) need fixing before you can save (marked in red).", problems.errors.size());
    else if (dirty) ImGui::TextColored(kWarn, "Unsaved changes");
    else ImGui::TextDisabled("Everything is saved.");
    ImGui::BeginDisabled(!dirty || bad);
    if (ImGui::Button("Save", ImVec2(110, 0))) {
        if (auto r = ps.save(); !r.ok()) {
            platformMessage_ = r.error().message + " " + r.error().hint;
        } else {
            platformMessage_.clear();
            iconChecks_.clear();
            platformBgMode_ = -1;
            exportChecked_ = -100;  // the Export window's rows read what was just saved
            notify("Platform settings saved.", 0);
        }
    }
    ImGui::EndDisabled();
    at_track("platform:save");
    tip("Writes the icon and export keys of factoria.json (nothing else in it changes) and this computer's settings.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!dirty);
    if (ImGui::Button("Revert", ImVec2(110, 0))) {
        ps.revert();
        iconChecks_.clear();
        platformBgMode_ = -1;
        platformMessage_.clear();
        platformDiskChanged_ = false;
    }
    ImGui::EndDisabled();
    at_track("platform:revert");
    tip("Forgets what you changed here and reads the settings from disk again.");
    ImGui::SameLine();
    if (ImGui::Button("Close", ImVec2(110, 0))) request_close_platform_settings();
    at_track("platform:close");

    // ---- popups (drawn at the window's level)
    keystore_popup(*this);
    if (platformCloseAsk_ && !ImGui::IsPopupOpen("Unsaved platform settings##close")) ImGui::OpenPopup("Unsaved platform settings##close");
    if (ImGui::BeginPopupModal("Unsaved platform settings##close", nullptr, ImGuiWindowFlags_AlwaysAutoResize | ImGuiWindowFlags_NoSavedSettings)) {
        ImGui::TextUnformatted("The platform settings have changes that are not saved.");
        if (ImGui::Button("Save and close", ImVec2(130, 0))) {
            if (auto r = ps.save(); r.ok()) {
                platformMessage_.clear();
                exportChecked_ = -100;
                showPlatformSettings_ = false;
            } else {
                platformMessage_ = r.error().message + " " + r.error().hint;
            }
            platformCloseAsk_ = false;
            ImGui::CloseCurrentPopup();
        }
        at_track("platform:close-save");
        ImGui::SameLine();
        if (ImGui::Button("Discard", ImVec2(110, 0))) {
            ps.revert();
            showPlatformSettings_ = false;
            platformCloseAsk_ = false;
            ImGui::CloseCurrentPopup();
        }
        at_track("platform:close-discard");
        ImGui::SameLine();
        if (ImGui::Button("Keep editing", ImVec2(110, 0)) || ImGui::IsKeyPressed(ImGuiKey_Escape)) {
            platformCloseAsk_ = false;
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    ImGui::PopTextWrapPos();
    ImGui::End();
}

}  // namespace fa::editor
