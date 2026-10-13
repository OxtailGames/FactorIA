// "Import ASCII level..." (File menu): a window around the engine command scene.import_ascii. Text boxes for the rows, the
// legend and the Tilemap fields, a target (a scene FILE, or the running scene), Preview (a dry run: writes nothing, shows the
// warnings, the row/column errors and how many objects it would place) and Import.
//
// File mode edits the scene file on disk and nothing else. When that file is the scene open in the editor, the editor reloads
// it afterwards so the viewport shows the result; unsaved edits are never dropped silently (the user chooses between saving
// first and an import that stays undoable with Ctrl+Z). Running-scene mode changes the world being edited like any other edit
// (one undo step); the editor may also write the scene file there (`save`), which the command refuses to anyone else while the
// running scene is only the project's default main scene (error unsafe_save).
#include <algorithm>
#include <cfloat>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr const char* kDefaultRows = "..........\n..........\n..........\n##########";
constexpr const char* kDefaultLegend = "{\"#\": 0}";

struct MonoScope {
    bool pushed = false;
    MonoScope() {
        if (ImFont* f = ui::mono_font()) {
            ImGui::PushFont(f);
            pushed = true;
        }
    }
    ~MonoScope() {
        if (pushed) ImGui::PopFont();
    }
};

// One text input for a scene file name plus a "..." button that lists the project's scenes.
void scene_input(Editor& ed, const char* id, const char* hint, std::string& value) {
    ImGui::PushID(id);
    const float btn = ImGui::GetFrameHeight() + 6;
    ImGui::SetNextItemWidth(-btn - ImGui::GetStyle().ItemSpacing.x);
    ImGui::InputTextWithHint("##v", hint, &value);
    ImGui::SameLine();
    if (ImGui::Button("...", ImVec2(btn, 0))) ImGui::OpenPopup("##scenes");
    ImGui::SetItemTooltip("Pick one of the project's scenes");
    if (ImGui::BeginPopup("##scenes")) {
        bool any = false;
        for (const std::string& f : ed.project_files()) {
            if (!asset_matches("scene", f)) continue;
            any = true;
            if (ImGui::Selectable(f.c_str(), f == value)) value = f;
        }
        if (!any) ImGui::TextDisabled("No scenes yet.");
        ImGui::EndPopup();
    }
    ImGui::PopID();
}

// "10 x 4 tiles", or what is ragged: the engine reports the exact row and column, this is only a hint while typing.
std::string rows_summary(const std::string& text, bool& ragged) {
    size_t rows = 0, minLen = SIZE_MAX, maxLen = 0, cur = 0;
    std::vector<size_t> lens;
    for (char c : text + "\n") {
        if (c == '\n') {
            lens.push_back(cur);
            cur = 0;
        } else if (c != '\r') {
            ++cur;
        }
    }
    while (!lens.empty() && lens.back() == 0) lens.pop_back();
    size_t first = 0;
    while (first < lens.size() && lens[first] == 0) ++first;
    for (size_t i = first; i < lens.size(); ++i) {
        ++rows;
        minLen = std::min(minLen, lens[i]);
        maxLen = std::max(maxLen, lens[i]);
    }
    ragged = rows > 0 && minLen != maxLen;
    if (rows == 0) return "no rows yet";
    if (ragged) return std::to_string(rows) + " rows, lengths " + std::to_string(minLen) + " to " + std::to_string(maxLen) + " (all rows must be the same length)";
    return std::to_string(maxLen) + " x " + std::to_string(rows) + " tiles";
}

void draw_result(Editor& ed, AsciiImportState& d) {
    const AsciiImportOutcome& r = d.result;
    ImGui::PushTextWrapPos(0.0f);
    if (r.ok) {
        ImGui::TextColored(ImVec4(0.5f, 0.9f, 0.55f, 1), "%s", d.resultIsPreview ? "Preview: valid, nothing was written." : "Imported.");
        ImGui::Text("%zu object%s %s, tilemap '%s' %d x %d tiles (%d not empty)%s.", r.spawned, r.spawned == 1 ? "" : "s",
                    d.resultIsPreview ? "would be placed" : "placed", r.tilemap.c_str(), r.width, r.height, r.tileCount,
                    r.removed ? (", replacing " + std::to_string(r.removed) + " from an earlier import").c_str() : "");
        if (!r.saved.empty()) ImGui::TextDisabled("Wrote %s (%zu entities)", r.saved.c_str(), r.entityCount);
        if (!r.spawnedLines.empty() && ImGui::TreeNode("##objects", "Objects (%zu)", r.spawnedLines.size())) {
            MonoScope mono;
            size_t shown = 0;
            for (const std::string& l : r.spawnedLines) {
                if (++shown > 40) {
                    ImGui::TextDisabled("... %zu more", r.spawnedLines.size() - 40);
                    break;
                }
                ImGui::TextUnformatted(l.c_str());
            }
            ImGui::TreePop();
        }
        for (const std::string& w : r.warnings) ImGui::TextColored(ImVec4(1, 0.8f, 0.35f, 1), "warning  %s", w.c_str());
        for (const std::string& n : r.notes) ImGui::TextDisabled("note  %s", n.c_str());
        if (!d.resultIsPreview && !r.path.empty() && r.path != ed.scene_path()) {
            if (ImGui::Button("Open this scene")) {
                if (ed.dirty()) ed.pendingScene_ = r.path;
                else ed.open_scene(r.path);
            }
            ImGui::SameLine();
            ImGui::TextDisabled("%s is not the scene open in the editor.", r.path.c_str());
        }
    } else {
        ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", r.message.c_str());
        if (!r.hint.empty()) ImGui::TextDisabled("%s", r.hint.c_str());
        ImGui::TextDisabled("Nothing was changed.");
    }
    ImGui::PopTextWrapPos();
}

}  // namespace

void Editor::open_ascii_import() {
    AsciiImportState& d = importDlg_;
    d.visible = true;
    if (!d.seeded) {
        d.seeded = true;
        d.form.rows = kDefaultRows;
        d.form.legend = kDefaultLegend;
        d.form.toFile = true;
        d.form.path = "scenes/level1.scene.json";
        d.form.from = scenePath_;
    }
    focus_window("Import ASCII level");
}

void Editor::load_ascii_level(const std::string& file) {
    AsciiImportState& d = importDlg_;
    auto loaded = load_ascii_form(file);
    if (!loaded.ok()) {
        d.loadError = loaded.error().to_string();
        return;
    }
    d.loadError.clear();
    AsciiImportForm f = *loaded;
    if (f.path.empty()) {  // keep the current target when the file does not name one
        f.path = d.form.path;
        f.from = d.form.from;
        f.toFile = d.form.toFile;
    }
    d.form = f;
    d.hasResult = false;
    notify("Loaded " + file);
}

bool Editor::ascii_import_touches_open_scene() const {
    const AsciiImportForm& f = importDlg_.form;
    return engine_ && f.toFile && !f.path.empty() && fs::normalize(f.path) == fs::normalize(scenePath_);
}

void Editor::do_ascii_preview() {
    AsciiImportState& d = importDlg_;
    AsciiImportForm f = d.form;
    if (!f.toFile) {
        // The command has no dry run for the running world. Check the map against the saved scene file instead: the same
        // rows, legend, prefabs and ids are validated, and nothing is written.
        f.toFile = true;
        f.path = scenePath_;
        f.from.clear();
        f.save = false;
    }
    d.result = run_ascii_import(engine_->commands(), f, true);
    d.hasResult = true;
    d.resultIsPreview = true;
}

void Editor::do_ascii_import() {
    AsciiImportState& d = importDlg_;
    d.hasResult = true;
    d.resultIsPreview = false;
    d.askUnsaved = false;
    if (!d.form.toFile) {
        if (play_ != PlayState::Edit) {
            d.result = AsciiImportOutcome{};
            d.result.message = "The game is running, so the running scene is temporary.";
            d.result.hint = "Stop the game first (the import would be discarded on Stop), or import into a scene file.";
            return;
        }
        // One undo step for the whole import; nothing is recorded when the command fails (it changes nothing then).
        Json before = save_scene(world());
        d.result = run_ascii_import(engine_->commands(), d.form, false);
        if (!d.result.ok) return;
        undo_.push_back(std::move(before));
        if (undo_.size() > 100) undo_.erase(undo_.begin());
        redo_.clear();
        lastEditKey_.clear();
        dirty_ = d.result.saved.empty();  // `save` wrote the scene file (the editor is allowed to), so it matches the disk
        notify("Imported " + std::to_string(d.result.spawned) + " object(s) into the running scene");
        return;
    }
    const bool touches = ascii_import_touches_open_scene();
    d.result = run_ascii_import(engine_->commands(), d.form, false);
    if (!d.result.ok) return;
    refresh_asset_lists();
    if (touches) {
        reload_scene_from_disk(true);  // the viewport shows the new level; Ctrl+Z returns to the scene as it was on screen
        select_id("");
        notify("Imported " + std::to_string(d.result.spawned) + " object(s) into " + d.result.path + " and reloaded it");
    } else {
        notify("Wrote " + d.result.path + " (" + std::to_string(d.result.spawned) + " object(s))");
    }
}

void Editor::draw_ascii_import_window() {
    AsciiImportState& d = importDlg_;
    if (!d.visible) return;
    ImGuiViewport* vp = ImGui::GetMainViewport();
    ImGui::SetNextWindowPos(ImVec2(vp->GetCenter().x, vp->WorkPos.y + 12), ImGuiCond_FirstUseEver, ImVec2(0.5f, 0.0f));
    ImGui::SetNextWindowSize(ImVec2(780, std::min(800.0f, vp->WorkSize.y - 50)), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Import ASCII level###asciiimport", &d.visible, ImGuiWindowFlags_NoSavedSettings)) {
        ImGui::End();
        return;
    }
    AsciiImportForm& f = d.form;
    ImGui::PushTextWrapPos(0.0f);
    ImGui::TextDisabled("Builds a Tilemap and the objects standing on it (coins, enemies, the player) from text: one character "
                        "per tile, row 0 is the TOP row. The legend maps each character to a tile index or a prefab. "
                        "This runs the command scene.import_ascii.");
    ImGui::PopTextWrapPos();

    // ---- load the arguments of an existing level file
    {
        const std::vector<std::string> levels = level_files(project_files());
        ImGui::SeparatorText("Arguments from a file");
        if (levels.empty()) {
            ImGui::TextDisabled("No levels/*.json files in this project. A level file holds the arguments of scene.import_ascii.");
        } else {
            if (d.levelFile.empty() || std::find(levels.begin(), levels.end(), d.levelFile) == levels.end()) d.levelFile = levels.front();
            ImGui::SetNextItemWidth(-90);
            if (ImGui::BeginCombo("##levelfile", d.levelFile.c_str())) {
                for (const std::string& l : levels)
                    if (ImGui::Selectable(l.c_str(), l == d.levelFile)) d.levelFile = l;
                ImGui::EndCombo();
            }
            ImGui::SameLine();
            if (ImGui::Button("Load", ImVec2(80, 0))) load_ascii_level(d.levelFile);
            at_track("import.load");
            ImGui::SetItemTooltip("Fill the boxes below from this file (rows, legend, tilemap, path, from and the other options)");
        }
        if (!d.loadError.empty()) {
            ImGui::PushTextWrapPos(0.0f);
            ImGui::TextColored(ImVec4(1, 0.45f, 0.4f, 1), "%s", d.loadError.c_str());
            ImGui::PopTextWrapPos();
        }
    }

    // ---- the boxes
    bool ragged = false;
    const std::string summary = rows_summary(f.rows, ragged);
    ImGui::SeparatorText("Rows");
    ImGui::SameLine();
    ImGui::TextColored(ragged ? ImVec4(1, 0.8f, 0.35f, 1) : ImVec4(0.6f, 0.65f, 0.75f, 1), "%s", summary.c_str());
    {
        MonoScope mono;
        ImGui::InputTextMultiline("##rows", &f.rows, ImVec2(-FLT_MIN, 90));
    }
    ImGui::SetItemTooltip("The map, one row per line and ONE CHARACTER PER TILE. Row 0 is the TOP row. '.' and ' ' are empty unless the legend says otherwise.");

    ImGui::SeparatorText("Legend (JSON)");
    {
        MonoScope mono;
        ImGui::InputTextMultiline("##legend", &f.legend, ImVec2(-FLT_MIN, 64));
    }
    ImGui::SetItemTooltip("Character -> tile index, or {\"tile\"?: n, \"prefab\"?: \"prefabs/x.prefab.json\", \"id\"?: \"player\", \"overrides\"?: {...}, \"offset\"?: [dx, dy]}");

    ImGui::SeparatorText("Tilemap fields (JSON, optional)");
    {
        MonoScope mono;
        ImGui::InputTextMultiline("##tilemap", &f.tilemap, ImVec2(-FLT_MIN, 44));
    }
    ImGui::SetItemTooltip("tileset, tileSize, columns, solidTiles, color, layer. The grid itself comes from the rows and the legend.");
    if (ImGui::TreeNode("##moreopts", "More options (JSON)")) {
        MonoScope mono;
        ImGui::InputTextMultiline("##options", &f.options, ImVec2(-FLT_MIN, 44));
        ImGui::SetItemTooltip("entity (the Tilemap's id, default \"tilemap\"), replace, position [x, y] and anchor (top-left, bottom-left, center)");
        ImGui::TreePop();
    }

    // ---- target
    ImGui::SeparatorText("Target");
    int target = f.toFile ? 0 : 1;
    if (ImGui::RadioButton("Scene file", &target, 0)) f.toFile = true;
    at_track("import.target_file");
    ImGui::SetItemTooltip("Edit a scene file on disk. The running game and this editor's world are not touched (unless it is the open scene: then it is reloaded).");
    ImGui::SameLine();
    if (ImGui::RadioButton("Running scene", &target, 1)) f.toFile = false;
    at_track("import.target_running");
    ImGui::SetItemTooltip("Change the scene you are editing right now, like any other edit (Ctrl+Z undoes it).");
    if (f.toFile) {
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("File");
        ImGui::SameLine(70);
        scene_input(*this, "path", "scenes/level1.scene.json", f.path);
        ImGui::AlignTextToFramePadding();
        ImGui::TextUnformatted("From");
        ImGui::SameLine(70);
        scene_input(*this, "from", "(optional) scene to start from, e.g. a base scene with the camera and HUD", f.from);
        ImGui::PushTextWrapPos(0.0f);
        if (ascii_import_touches_open_scene())
            ImGui::TextColored(ImVec4(1, 0.8f, 0.35f, 1), "This is the scene open in the editor: it is reloaded after the import%s.",
                               dirty_ ? " (you have unsaved changes: you will be asked)" : "");
        else if (f.path.empty())
            ImGui::TextDisabled("Type the scene file to write. It is created when it does not exist.");
        else
            ImGui::TextDisabled("Writes %s%s.", f.path.c_str(), f.from.empty() ? " (starts from that file, or an empty scene when it is new)" : ", starting from the scene above");
        ImGui::PopTextWrapPos();
    } else {
        ImGui::BeginDisabled(play_ != PlayState::Edit);
        ImGui::Checkbox("Also save the scene file", &f.save);
        ImGui::EndDisabled();
        ImGui::SetItemTooltip("Write %s right after the import. The editor may do this; other callers are refused (unsafe_save) while the running scene is only the default main scene.", scenePath_.c_str());
        ImGui::PushTextWrapPos(0.0f);
        if (play_ != PlayState::Edit)
            ImGui::TextColored(ImVec4(1, 0.8f, 0.35f, 1), "The game is running: stop it to import into the running scene.");
        else
            ImGui::TextDisabled("Changes the scene being edited (%s). Preview checks the map against the saved scene file.", scenePath_.c_str());
        ImGui::PopTextWrapPos();
    }

    // ---- actions
    ImGui::Spacing();
    if (ImGui::Button("Preview", ImVec2(110, 0))) do_ascii_preview();
    at_track("import.preview");
    ImGui::SetItemTooltip("Dry run: checks the rows, legend and prefabs and shows what would be placed. Writes nothing.");
    ImGui::SameLine();
    const bool canImport = f.toFile || play_ == PlayState::Edit;
    ImGui::BeginDisabled(!canImport);
    if (ImGui::Button("Import", ImVec2(110, 0))) {
        if (ascii_import_touches_open_scene() && dirty_) d.askUnsaved = true;
        else do_ascii_import();
    }
    at_track("import.import");
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Run scene.import_ascii for real.");

    // ---- result
    if (d.hasResult) {
        ImGui::Spacing();
        ImGui::BeginChild("##importresult", ImVec2(0, 0), ImGuiChildFlags_Borders);
        draw_result(*this, d);
        ImGui::EndChild();
    }

    // ---- unsaved changes in the scene that is about to be rebuilt
    if (d.askUnsaved) ImGui::OpenPopup("Unsaved changes##import");
    ImGui::SetNextWindowSizeConstraints(ImVec2(680, 0), ImVec2(680, FLT_MAX));
    if (ImGui::BeginPopupModal("Unsaved changes##import", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(0.0f);
        ImGui::Text("'%s' is the scene open in the editor and it has unsaved changes.", scenePath_.c_str());
        ImGui::TextDisabled("The import rebuilds that file from what is on disk, then the editor reloads it.");
        ImGui::PopTextWrapPos();
        ImGui::Spacing();
        if (f.from.empty()) {
            if (ImGui::Button("Save first, then import")) {
                if (save_scene_now()) do_ascii_import();
                else d.askUnsaved = false;
                ImGui::CloseCurrentPopup();
            }
            at_track("import.savefirst");
            ImGui::SetItemTooltip("Your edits go into the file first, so the import builds on them.");
            ImGui::SameLine();
        }
        if (ImGui::Button("Import, keep my edits undoable")) {
            do_ascii_import();
            ImGui::CloseCurrentPopup();
        }
        at_track("import.keep");
        ImGui::SetItemTooltip("The file is rebuilt from the disk version. Ctrl+Z brings back the scene as it is on screen now.");
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            d.askUnsaved = false;
            ImGui::CloseCurrentPopup();
        }
        ImGui::EndPopup();
    }
    ImGui::End();
}

}  // namespace fa::editor
