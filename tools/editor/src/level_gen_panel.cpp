// Level generator window (View > Level generator): make a level from an example you drew, try other seeds, keep one.
// The sample is the selected entity's Tilemap or an ASCII level file; the window builds the arguments of `tilemap.generate`,
// runs the generator in small pieces (`tilemap.generate_start` / `generate_step`, about 4 ms a frame, so the window keeps
// drawing), shows the result as a plan of coloured cells and keeps it on request: Keep builds it in the open scene with
// `scene.import_ascii` (one undo step; spawn points, coins and enemies of the sample become entities), Save writes an ASCII level
// file `scene.ascii_edit` can edit. The model is level_gen_model.h; this file only draws it.
#include <algorithm>
#include <cmath>
#include <cstdio>

#include "editor_internal.h"

namespace fa::editor {

namespace {

constexpr double kFrameBudgetMs = 4.0;

ImU32 tile_colour(int tile, bool solid) {
    if (tile < 0) return IM_COL32(24, 26, 32, 255);
    // A hue per tile number, the golden-ratio step keeps neighbours apart; solid tiles are brighter.
    const float hue = std::fmod(0.07f + float(tile) * 0.618034f, 1.0f);
    float r, g, b;
    ImGui::ColorConvertHSVtoRGB(hue, solid ? 0.55f : 0.35f, solid ? 0.95f : 0.62f, r, g, b);
    return IM_COL32(int(r * 255), int(g * 255), int(b * 255), 255);
}

}  // namespace

LevelGenCaller Editor::level_gen_caller() {
    return [this](const std::string& name, const Json& args) {
        return engine_ ? engine_->commands().call(name, args) : CommandResult{};
    };
}

// The components of an entity as scene.get_entity reports them ({} when the entity does not exist).
static Json entity_components_of(Engine& engine, const std::string& id) {
    if (id.empty()) return Json::object();
    CommandResult r = engine.commands().call("scene.get_entity", Json::object({{"id", id}}));
    if (!r.ok || !r.result.contains("components") || !r.result["components"].is_object()) return Json::object();
    return r.result["components"];
}

static std::string command_error_message(const CommandResult& r) {
    if (r.error.is_object() && r.error.contains("message") && r.error["message"].is_string()) {
        std::string m = r.error["message"].get<std::string>();
        if (r.error.contains("hint") && r.error["hint"].is_string()) m += " " + r.error["hint"].get<std::string>();
        return m;
    }
    return "the command failed";
}

// The Tilemap fields a kept level copies from the sample: its entity's Tilemap, or the "tilemap" object of its level file.
static Json sample_tilemap_fields(Engine& engine, const LevelGenOptions& o) {
    if (o.sampleFile.empty()) {
        const Json comps = entity_components_of(engine, o.sampleEntity);
        return comps.contains("Tilemap") ? level_gen_tilemap_fields(comps["Tilemap"]) : Json::object();
    }
    CommandResult fr = engine.commands().call("fs.read", Json::object({{"path", o.sampleFile}}));
    if (!fr.ok || !fr.result.contains("content") || !fr.result["content"].is_string()) return Json::object();
    Result<Json> doc = parse_json(fr.result["content"].get<std::string>(), o.sampleFile);
    if (doc.ok() && doc.value().is_object() && doc.value().contains("tilemap")) return level_gen_tilemap_fields(doc.value()["tilemap"]);
    return Json::object();
}

void Editor::level_gen_refresh_sample() {
    if (!engine_) return;
    // A few times a second is enough: the selection changes rarely and get_entity builds JSON.
    if (selected_id() == levelGenSelId_ && uiFrame_ - levelGenSampleFrame_ < 30 && levelGenSampleFrame_ != 0) return;
    levelGenSelId_ = selected_id();
    levelGenSampleFrame_ = uiFrame_ ? uiFrame_ : 1;
    levelGenSelTilemap_ = entity_components_of(*engine_, levelGenSelId_).contains("Tilemap");
    levelGenSolid_.clear();
    if (levelGenOpt_.sampleFile.empty() && levelGenOpt_.sampleEntity.empty()) return;
    const Json fields = sample_tilemap_fields(*engine_, levelGenOpt_);
    if (fields.contains("solidTiles") && fields["solidTiles"].is_array())
        for (const Json& t : fields["solidTiles"])
            if (t.is_number_integer()) levelGenSolid_.push_back(t.get<int>());
}

void Editor::level_gen_keep() {
    levelGenMessage_.clear();
    levelGenMessageBad_ = false;
    const LevelGenPreview& p = levelGen_.preview();
    if (!p.valid || !engine_) return;
    const std::string name = level_gen_safe_name(levelGenKeepName_);
    if (name.empty()) {
        levelGenMessage_ = "Give the kept level an entity id made of letters, digits, _ or -.";
        levelGenMessageBad_ = true;
        return;
    }
    const Json fields = sample_tilemap_fields(*engine_, levelGenOpt_);
    double x = 0, y = 0;
    if (levelGenOpt_.sampleFile.empty()) {
        // To the right of the sample, level with it: both are visible in the viewport.
        const Json comps = entity_components_of(*engine_, levelGenOpt_.sampleEntity);
        if (comps.contains("Transform") && comps["Transform"].contains("position") && comps["Transform"]["position"].is_array() &&
            comps["Transform"]["position"].size() >= 2) {
            x = comps["Transform"]["position"][0].get<double>();
            y = comps["Transform"]["position"][1].get<double>();
        }
        if (comps.contains("Tilemap")) {
            const Json& tm = comps["Tilemap"];
            const Json ts = tm.value("tileSize", Json::array({16, 16}));
            const double tw = ts.is_array() && !ts.empty() && ts[0].is_number() ? ts[0].get<double>() : 16.0;
            x += (double(tm.value("width", 0)) + 2.0) * tw;
        }
    }
    std::string error;
    const CommandResult r = edit_command("levelgen:keep:" + std::to_string(uiFrame_), "scene.import_ascii",
                                         level_gen_keep_arguments(p, name, fields, x, y), &error);
    if (!r.ok) {
        levelGenMessage_ = "Keep failed: " + (error.empty() ? command_error_message(r) : error);
        levelGenMessageBad_ = true;
        return;
    }
    const int spawned = r.result.contains("spawned") && r.result["spawned"].is_array() ? int(r.result["spawned"].size()) : 0;
    levelGenMessage_ = "Kept as the entity '" + name + "' (seed " + std::to_string(p.seed) + ", " + std::to_string(spawned) +
                       " object(s) placed). Ctrl+Z takes it back; keeping again replaces it.";
    select_id(name);
    notify(levelGenMessage_);
}

void Editor::level_gen_save() {
    levelGenMessage_.clear();
    levelGenMessageBad_ = false;
    const LevelGenPreview& p = levelGen_.preview();
    if (!p.valid || !engine_) return;
    const std::string path = levelGenSavePath_;
    if (path.size() < 6 || path.compare(path.size() - 5, 5, ".json") != 0 || path.find("..") != std::string::npos || path.front() == '/' ||
        path.front() == '\\' || path.find(':') != std::string::npos) {
        levelGenMessage_ = "The level file must be a project-relative .json path, like levels/generated.json.";
        levelGenMessageBad_ = true;
        return;
    }
    levelGenSaveTarget_ = path;
    levelGenSaveContent_ = level_gen_file_text(p, level_gen_safe_name(levelGenKeepName_), sample_tilemap_fields(*engine_, levelGenOpt_));
    level_gen_write(false);
}

// Writes the level file Save asked about. Without `overwrite` an existing file is left alone and the "Replace" popup opens: Save must
// never replace factoria.json, a scene, assets.json or the sample itself on a click.
void Editor::level_gen_write(bool overwrite) {
    if (!engine_ || levelGenSaveTarget_.empty()) return;
    const std::string path = levelGenSaveTarget_;
    const LevelGenPreview& p = levelGen_.preview();
    const Json args = Json::object({{"path", path}, {"content", levelGenSaveContent_}, {"overwrite", overwrite}});
    const CommandResult r = engine_->commands().call("fs.write", args);
    if (!r.ok && !overwrite && r.error.is_object() && r.error.value("code", std::string()) == "exists") {
        levelGenReplaceOpen_ = true;
        return;
    }
    after_command("fs.write", args, r);   // the Project panel lists the new file
    if (!r.ok) {
        levelGenMessage_ = "Could not write " + path + ": " + command_error_message(r);
        levelGenMessageBad_ = true;
        return;
    }
    levelGenMessage_ = "Wrote " + path + " (seed " + std::to_string(p.seed) +
                       "). `factoria call scene.import_ascii @" + path + "` builds it, scene.ascii_edit edits it.";
    notify(levelGenMessage_);
}

void Editor::draw_level_gen_preview(float height) {
    const LevelGenPreview& p = levelGen_.preview();
    ImGui::BeginChild("##levelgenpreview", ImVec2(0, height), true, ImGuiWindowFlags_HorizontalScrollbar);
    if (!p.valid) {
        ImGui::TextDisabled("No level yet. Choose a sample and press Generate.");
        ImGui::EndChild();
        return;
    }
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    // At most ~40000 rectangles a frame: a big level is drawn with one rectangle for several cells.
    const int skip = std::max(1, int(std::ceil(std::sqrt(double(p.width) * double(p.height) / 40000.0))));
    const float cell = std::clamp(std::min(avail.x / float(p.width), avail.y / float(p.height)), 2.0f, 18.0f);
    const ImVec2 origin = ImGui::GetCursorScreenPos();
    ImDrawList* dl = ImGui::GetWindowDrawList();
    // The tiles the sample marks as solid are brighter (what blocks the player).
    const std::vector<int>& solid = levelGenSolid_;
    const float drawn = cell * float(skip);
    for (int row = 0; row < p.height; row += skip) {
        for (int col = 0; col < p.width; col += skip) {
            const LevelGenCell c = level_gen_cell(p, col, row);
            const bool isSolid = std::find(solid.begin(), solid.end(), c.tile) != solid.end();
            const ImVec2 a(origin.x + float(col) * cell, origin.y + float(row) * cell);
            const ImVec2 b(a.x + drawn, a.y + drawn);
            dl->AddRectFilled(a, b, tile_colour(c.tile, isSolid));
            if (c.marker) {
                dl->AddCircleFilled(ImVec2((a.x + b.x) * 0.5f, (a.y + b.y) * 0.5f), std::max(1.5f, drawn * 0.36f), IM_COL32(255, 214, 64, 255));
                if (drawn >= 9.0f) {
                    const char glyph[2] = {p.rows[std::size_t(row)][std::size_t(col)], 0};
                    dl->AddText(ImVec2(a.x + drawn * 0.28f, a.y + drawn * 0.08f), IM_COL32(20, 20, 20, 255), glyph);
                }
            }
        }
    }
    ImGui::Dummy(ImVec2(cell * float(p.width), cell * float(p.height)));
    at_track("levelgen:preview");
    if (ImGui::IsItemHovered()) {
        const ImVec2 m = ImGui::GetMousePos();
        const int col = int((m.x - origin.x) / cell), row = int((m.y - origin.y) / cell);
        if (col >= 0 && row >= 0 && col < p.width && row < p.height) {
            const LevelGenCell c = level_gen_cell(p, col, row);
            const char glyph = p.rows[std::size_t(row)][std::size_t(col)];
            ImGui::SetTooltip("cell (%d, %d)   glyph '%c'   %s%s", col, row, glyph == ' ' ? '_' : glyph,
                              c.tile < 0 ? "empty" : ("tile " + std::to_string(c.tile)).c_str(), c.marker ? "   marker (a prefab is placed here)" : "");
        }
    }
    ImGui::EndChild();
}

void Editor::draw_level_gen_panel() {
    first_floating_window(ImVec2(80, 40), ImVec2(640, 620));
    if (!ImGui::Begin("Level generator", &showLevelGen_)) {
        ImGui::End();
        // Collapsed or a hidden tab: nothing ticks the job, so it must not stay in the engine holding its solver memory.
        if (levelGen_.running()) levelGen_.cancel(level_gen_caller());
        return;
    }
    LevelGenOptions& o = levelGenOpt_;
    const LevelGenCaller call = level_gen_caller();
    const bool editing = play_ == PlayState::Edit;
    bool regenerate = false;   // Previous / Next / Random / a tried seed / a typed seed show their level at once

    // --- the sample
    ImGui::SeparatorText("Sample");
    level_gen_refresh_sample();
    const bool selHasTilemap = levelGenSelTilemap_;
    if (o.sampleFile.empty() && !o.sampleEntity.empty()) ImGui::Text("Learning from the Tilemap of '%s'.", o.sampleEntity.c_str());
    else if (!o.sampleFile.empty()) ImGui::Text("Learning from the level file '%s'.", o.sampleFile.c_str());
    else ImGui::TextDisabled("Nothing to learn from yet: select a drawn level (an entity with a Tilemap) or name a level file.");
    ImGui::BeginDisabled(!selHasTilemap);
    if (ImGui::Button("Use the selected Tilemap")) {
        o.sampleEntity = selected_id();
        o.sampleFile.clear();
        levelGen_.clear(level_gen_caller());
        levelGenSampleFrame_ = 0;   // read the sample's solid tiles now
    }
    ImGui::EndDisabled();
    at_track("levelgen:use-selected", selHasTilemap);
    ImGui::SetItemTooltip("%s", selHasTilemap ? "The generated level is made only of the patterns of this Tilemap (and its legend of tiles)."
                                              : "Select an entity with a Tilemap in the Hierarchy or the Viewport first.");
    ImGui::SameLine();
    ImGui::SetNextItemWidth(-1);
    if (ImGui::InputTextWithHint("##levelgenfile", "or a level file: levels/sample.json", &o.sampleFile)) {
        levelGen_.clear(call);
        levelGenSampleFrame_ = 0;
    }
    at_track("levelgen:file");
    ImGui::SetItemTooltip("A .json file in the format of scene.import_ascii: {\"rows\": [...], \"legend\": {...}}. With prefabs in the legend (spawn point,\n"
                          "coins, enemies) the generated level carries those markers too, and Keep places them.");

    // --- the options
    ImGui::SeparatorText("Level");
    int size[2] = {o.width, o.height};
    ImGui::SetNextItemWidth(150);
    if (ImGui::InputInt2("Size", size)) {
        o.width = std::clamp(size[0], 1, 2048);
        o.height = std::clamp(size[1], 1, 2048);
    }
    ImGui::SetItemTooltip("Width and height of the new level in cells (1..2048). A few dozen cells generate in a blink.");
    at_track("levelgen:size");
    ImGui::SameLine();
    int seed = int(std::min<std::int64_t>(o.seed, kLevelGenMaxSeed));
    ImGui::SetNextItemWidth(150);
    if (ImGui::InputInt("Seed", &seed, 1, 100, ImGuiInputTextFlags_EnterReturnsTrue)) {   // Enter or the +/- buttons, not every keystroke
        o.seed = std::clamp<std::int64_t>(seed, 0, kLevelGenMaxSeed);
        regenerate = true;
    }
    ImGui::SetItemTooltip("Picks the level: the same sample, seed and options give the same level on every computer.\nPress Enter or use the + / - buttons to generate it.");
    at_track("levelgen:seed");
    if (ImGui::Button("Previous seed")) {
        o.seed = o.seed > 0 ? o.seed - 1 : kLevelGenMaxSeed;
        regenerate = true;
    }
    at_track("levelgen:prev");
    fit_same_line("Next seed");
    if (ImGui::Button("Next seed")) {
        o.seed = o.seed < kLevelGenMaxSeed ? o.seed + 1 : 0;
        regenerate = true;
    }
    at_track("levelgen:next");
    ImGui::SetItemTooltip("Generate the level with the next seed");
    fit_same_line("Random seed");
    if (ImGui::Button("Random seed")) {
        // A new seed from the old one (a fixed mix, no clock): pressing it again walks a long, repeatable chain.
        o.seed = std::int64_t((std::uint64_t(o.seed) * 6364136223846793005ull + 1442695040888963407ull) >> 33) % (kLevelGenMaxSeed + 1);
        regenerate = true;
    }
    at_track("levelgen:random");
    ImGui::SetItemTooltip("Try a seed far from this one");
    ImGui::SetNextItemWidth(120);
    if (ImGui::BeginCombo("Model", o.model.c_str())) {
        for (const char* m : {"overlapping", "tiled"})
            if (ImGui::Selectable(m, o.model == m)) o.model = m;
        ImGui::EndCombo();
    }
    ImGui::SetItemTooltip("overlapping learns the n x n windows of the sample; tiled reads which tiles may touch from the autotile rules of the\n"
                          "sample's Tilemap (Tilemap.terrains).");
    if (o.model == "overlapping") {
        ImGui::SameLine();
        ImGui::SetNextItemWidth(90);
        ImGui::SliderInt("Window n", &o.n, 2, 5);
        ImGui::SetItemTooltip("Side of the pieces copied from the sample. Bigger n repeats larger shapes of the sample; smaller n mixes them more freely.");
        ImGui::SameLine();
        ImGui::SetNextItemWidth(60);
        if (ImGui::BeginCombo("Symmetry", std::to_string(o.symmetry).c_str())) {
            for (int sym : {1, 2, 4, 8})
                if (ImGui::Selectable(std::to_string(sym).c_str(), o.symmetry == sym)) o.symmetry = sym;
            ImGui::EndCombo();
        }
        ImGui::SetItemTooltip("1 as drawn, 2 adds mirror images, 4 adds turns, 8 both. Use 1 for anything with an up (platforms, stairs).");
    }
    ImGui::Checkbox("Wraps around its edges", &o.periodic);
    if (ImGui::CollapsingHeader("More options (JSON)")) {
        ImGui::TextDisabled("constraints, reachability, maxAttempts, maxWork... as in the command tilemap.generate; merged over the options above.");
        ImGui::InputTextMultiline("##levelgenextra", &o.extra, ImVec2(-FLT_MIN, ImGui::GetTextLineHeight() * 5.0f));
        at_track("levelgen:extra");
    }

    // --- run
    const bool running = levelGen_.running();
    if (running) {
        if (ImGui::Button("Cancel")) levelGen_.cancel(call);
        at_track("levelgen:cancel");
        ImGui::SameLine();
        ImGui::ProgressBar(float(levelGen_.progress()), ImVec2(-FLT_MIN, 0));
    } else {
        if (ImGui::Button("Generate")) regenerate = true;
        at_track("levelgen:generate");
        ImGui::SetItemTooltip("Generate a level with these options. Same options, same level.");
    }
    if (regenerate) levelGen_.start(o, call);
    // About 4 ms of this frame per generation step: the window and the viewport keep drawing.
    if (levelGen_.running()) {
        levelGen_.tick(call, kFrameBudgetMs);
        if (!levelGen_.running()) levelGenSampleFrame_ = 0;   // finished: refresh the solid tiles the preview colours with
    }

    if (levelGen_.state() == LevelGenSession::State::Failed) {
        ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", levelGen_.error().c_str());
        ImGui::PopStyleColor();
        if (!levelGen_.hint().empty()) ImGui::TextWrapped("%s", levelGen_.hint().c_str());
        at_track("levelgen:error");
    }

    // --- the result
    const LevelGenPreview& p = levelGen_.preview();
    if (p.valid) {
        ImGui::Text("Seed %lld: %d x %d cells, %d attempt(s), %d dead end(s), %lld units of work", static_cast<long long>(p.seed), p.width, p.height,
                    p.stats.value("attempts", 1), p.stats.value("contradictions", 0), static_cast<long long>(p.stats.value("work", 0LL)));
        at_track("levelgen:stats");
        for (const std::string& w : p.warnings) ImGui::TextDisabled("%s", w.c_str());
    }

    // --- the seeds tried
    if (!levelGen_.tries().empty()) {
        ImGui::TextDisabled("Tried:");
        const auto& tries = levelGen_.tries();
        int shown = 0;
        for (std::size_t i = tries.size(); i-- > 0 && shown < 8; ++shown) {
            const LevelGenTry& t = tries[i];
            char label[48];
            std::snprintf(label, sizeof(label), "%lld%s##try%zu", static_cast<long long>(t.seed), t.ok ? "" : " x", i);
            if (shown == 0) ImGui::SameLine();
            else fit_same_line(label);
            if (ImGui::SmallButton(label)) {
                o.seed = t.seed;
                levelGen_.start(o, call);
            }
            ImGui::SetItemTooltip("%s: %s. Click to generate this seed again.", t.ok ? "A level" : "No level", t.note.c_str());
        }
    }

    // --- keep
    ImGui::SeparatorText("Keep");
    ImGui::SetNextItemWidth(130);
    ImGui::InputText("Entity id", &levelGenKeepName_);
    at_track("levelgen:name");
    ImGui::SetItemTooltip("The Tilemap entity that Keep builds in the open scene. Keeping again replaces it and its objects.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!p.valid || !editing || running);
    if (ImGui::Button("Keep in the scene")) level_gen_keep();
    at_track("levelgen:keep", p.valid && editing && !running);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("%s", !editing ? "Stop the game first: Keep edits the open scene."
                                         : "Build this level in the open scene with scene.import_ascii: the Tilemap, and an entity for every\n"
                                           "spawn point, coin and enemy of the sample. One undo step.");
    ImGui::SetNextItemWidth(220);
    ImGui::InputText("Level file", &levelGenSavePath_);
    ImGui::SetItemTooltip("Project-relative path of the ASCII level file Save writes.");
    ImGui::SameLine();
    ImGui::BeginDisabled(!p.valid || running);
    if (ImGui::Button("Save level file")) level_gen_save();
    at_track("levelgen:save", p.valid && !running);
    ImGui::EndDisabled();
    ImGui::SetItemTooltip("Write the rows and legend as a level file: `factoria call scene.import_ascii @<file>` builds it, scene.ascii_edit edits it.");
    if (levelGenReplaceOpen_) {
        ImGui::OpenPopup("Replace level file?##levelgen");
        levelGenReplaceOpen_ = false;
    }
    ImGui::SetNextWindowPos(ImGui::GetMainViewport()->GetCenter(), ImGuiCond_Appearing, ImVec2(0.5f, 0.5f));
    if (ImGui::BeginPopupModal("Replace level file?##levelgen", nullptr, ImGuiWindowFlags_AlwaysAutoResize)) {
        ImGui::PushTextWrapPos(ImGui::GetFontSize() * 28.0f);
        ImGui::Text("Replace %s?", levelGenSaveTarget_.c_str());
        ImGui::TextWrapped("The file already exists; the level shown here would take its place.");
        if (levelGenSaveTarget_ == o.sampleFile)
            ImGui::TextColored(kStatusFailed, "It is the sample this window learns from: replacing it changes every level made from it.");
        ImGui::PopTextWrapPos();
        if (ImGui::Button("Replace")) {
            level_gen_write(true);
            ImGui::CloseCurrentPopup();
        }
        at_track("levelgen:replace");
        ImGui::SameLine();
        if (ImGui::Button("Cancel")) {
            levelGenMessage_ = "Kept the existing " + levelGenSaveTarget_ + "; nothing was written.";
            ImGui::CloseCurrentPopup();
        }
        at_track("levelgen:replace-cancel");
        ImGui::EndPopup();
    }
    if (!levelGenMessage_.empty()) {
        if (levelGenMessageBad_) ImGui::PushStyleColor(ImGuiCol_Text, kStatusFailed);
        ImGui::TextWrapped("%s", levelGenMessage_.c_str());
        if (levelGenMessageBad_) ImGui::PopStyleColor();
        at_track("levelgen:message");
    }

    // --- the preview takes what is left
    draw_level_gen_preview(std::max(100.0f, ImGui::GetContentRegionAvail().y - 4.0f));
    ImGui::End();
}

}  // namespace fa::editor
