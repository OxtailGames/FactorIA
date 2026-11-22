// The foliage tool (View > Foliage tool): paint instances of the selected Foliage into the world, or erase them, with a brush in
// the viewport (docs/editor/EDITOR_FOLIAGE.md, "Foliage tool"). The brush (settings, stamps along the mouse path, ring, ray against
// the ground) is the shared one of brush.h and the ground is the Terrain the Foliage grows on (its ScatterRule.terrain, else the
// entity itself or its parent); this file adds the foliage's own: the foliage.paint arguments and the panel.
//
// A stroke is ONE undo step of the editor, however many frames it lasts, the same way the terrain tool's is:
//   - the stamps the mouse draws are collected and sent as `points` of foliage.paint. The first piece makes a step of the Foliage's
//     own history; every later piece carries `continueStroke` and joins it (the history keeps 64 steps: a call per frame would push
//     the user's real history out in seconds);
//   - on the release the editor pushes ONE command entry [foliage.redo] / [foliage.undo] on its undo stack (push_command_entry),
//     which marks the scene dirty like any edit. Ctrl+Z runs foliage.undo (the whole stroke goes back), Ctrl+Shift+Z foliage.redo;
//   - Esc during a stroke takes it back (foliage.undo of its step) and records nothing.
//
// What a piece costs: every foliage.paint call rewrites the WHOLE instances file (52 MB at 2,000,000 instances, 26 bytes an instance)
// and reads it first. So the pieces of a stroke are rate-limited (foliage_piece_interval: at most one per 0.2 s, one per twice the
// duration of the last call when that is longer): the stamps the mouse draws meanwhile wait, and go together in one call (up to 512
// points). The release sends what is left. A Foliage with a million instances therefore paints in a handful of file rewrites per
// second at most, never one per frame or one per stamp.
#include <algorithm>
#include <chrono>
#include <cmath>
#include <format>

#include "brush_view.h"
#include "editor_internal.h"
#include "fa/scene/foliage.h"
#include "fa/scene/terrain.h"
#include "imgui_internal.h"

namespace fa::editor {

namespace {

double round4(double v) { return std::round(v * 1e4) / 1e4; }

// The Terrain the Foliage `e` grows on, null when there is none: the rule's own `terrain`, else the entity itself, else its parent
// (the order foliage.scatter looks in).
Entity foliage_ground(const World& w, Entity e) {
    if (e.is_null() || !w.alive(e) || !w.has<Foliage>(e)) return Entity{};
    if (const ScatterRule* r = w.get<ScatterRule>(e); r && !r->terrain.is_null())
        return w.alive(r->terrain) && w.has<Terrain3D>(r->terrain) ? r->terrain : Entity{};
    if (w.has<Terrain3D>(e)) return e;
    const Entity p = w.parent(e);
    return !p.is_null() && w.has<Terrain3D>(p) ? p : Entity{};
}

std::string mesh_at(const Foliage& f, int index) {
    if (index < 0 || std::size_t(index) >= f.meshes.size() || !f.meshes[std::size_t(index)].is_string()) return {};
    return f.meshes[std::size_t(index)].get<std::string>();
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------- pure parts --
FoliageCall foliage_stroke_call(const FoliageUi& ui, const std::string& entityId, const std::vector<Vec2>& points,
                                bool continueStroke) {
    FoliageCall c;
    c.command = "foliage.paint";
    c.args = Json::object({{"entity", entityId}});
    Json pts = Json::array();
    for (const Vec2& p : points) pts.push_back(Json::array({round4(p.x), round4(p.y)}));
    c.args["points"] = pts;
    c.args["radius"] = round4(ui.strokeBrush.radius);
    const bool add = (ui.strokeMode == FoliageMode::Add) != ui.strokeInvert;
    c.args["mode"] = add ? "add" : "remove";
    if (add && !ui.strokeRuleDensity) c.args["density"] = round4(std::max(ui.strokeDensity, 1e-4f));
    if (!ui.strokeMesh.empty()) c.args["mesh"] = ui.strokeMesh;
    if (continueStroke) c.args["continueStroke"] = true;
    return c;
}

double foliage_piece_interval(double lastCostSeconds) {
    const double cost = std::isfinite(lastCostSeconds) ? std::max(lastCostSeconds, 0.0) : 0.0;
    return std::clamp(2.0 * cost, kFoliageMinPieceSeconds, kFoliageMaxPieceSeconds);
}

// ------------------------------------------------------------------------------------------------------------------ strokes --
bool Editor::foliage_tool_active() {
    if (!showFoliageTool_ || foliage_.mode == FoliageMode::Off || !engine_ || play_ != PlayState::Edit) return false;
    return !foliage_ground(world(), selected()).is_null();
}

bool Editor::foliage_stroke_active() const { return foliage_.stroke.active(); }

void Editor::foliage_stroke_begin(Entity e, Vec2 at) {
    FoliageUi& t = foliage_;
    const ImGuiIO& io = ImGui::GetIO();
    t.strokeEntity = world().id_of(e);
    t.strokeBrush = t.brush;
    t.strokeMode = t.mode;
    t.strokeInvert = io.KeyCtrl;
    t.strokeDensity = t.density;
    t.strokeRuleDensity = t.ruleDensity;
    const Foliage* f = world().get<Foliage>(e);
    t.strokeMesh = f ? mesh_at(*f, t.mesh) : std::string();
    t.started = false;
    t.failed = false;
    t.pieces = 0;
    t.historyId = t.historyStep = 0;
    t.lastPieceAt = -1e9;
    t.lastPieceCost = 0.0;
    t.error.clear();
    t.clearArmed = false;
    t.dirtyBefore = dirty_;
    t.stroke.begin(at, t.strokeBrush.radius, kFoliageStampsPerRadius);
}

// Sends what the stroke has not sent yet, in pieces of at most kMaxFoliagePaintPoints stamps. Not `final`: at most one piece, and
// only when foliage_piece_interval has passed since the last (the first piece of a stroke goes at once). `final` (the release):
// everything. Returns false when a command refused (the stroke is over then): the refusal is reported once, and a stroke that failed
// sends nothing more.
bool Editor::foliage_stroke_flush(bool final) {
    FoliageUi& t = foliage_;
    if (!t.stroke.active()) return true;
    if (t.failed) return false;
    while (t.stroke.pending() > 0) {
        if (!final && t.pieces > 0 && time_ - t.lastPieceAt < foliage_piece_interval(t.lastPieceCost)) return true;
        std::vector<Vec2> pts;
        t.stroke.take_pending(pts, kMaxFoliagePaintPoints);
        const FoliageCall call = foliage_stroke_call(t, t.strokeEntity, pts, t.started);
        const auto t0 = std::chrono::steady_clock::now();
        const CommandResult res = engine_->commands().call(call.command, call.args);
        t.lastPieceCost = std::chrono::duration<double>(std::chrono::steady_clock::now() - t0).count();
        t.lastPieceAt = time_;
        after_command(call.command, call.args, res);
        ++t.pieces;
        if (!res.ok) {
            t.failed = true;
            const std::string text = call.command + ": " + command_error_text(res.error);
            if (text != t.error) notify(text, 2);
            t.error = text;
            return false;
        }
        const Json& r = res.result;
        if (r.is_object() && r.contains("instances") && r["instances"].is_number_integer()) {
            t.instances = r["instances"].get<long long>();
            t.instancesOf = t.strokeEntity;
        }
        if (!t.started && r.is_object() &&
            r.contains("undo")) {  // the first piece that changed something made the step
            t.started = true;
            const auto number = [&](const char* key) -> std::uint64_t {
                return r.contains(key) && r[key].is_number_unsigned() ? r[key].get<std::uint64_t>() : 0;
            };
            t.historyId = number("historyId");
            t.historyStep = number("historyLost") + number("undoDepth");
            // A new edit clears the redo list of the Foliage's history, so the editor's redo rows of it can only fail: the list
            // goes now (an Esc would otherwise leave rows that redo a stroke nobody wants).
            redo_.clear();
            mark_dirty();  // the title shows the unsaved edit while the mouse is still down
        }
    }
    return true;
}

// The mouse went up (or the stroke must stop): what changed is one undo step of the editor.
void Editor::foliage_stroke_end() {
    FoliageUi& t = foliage_;
    if (!t.stroke.active()) return;
    foliage_stroke_flush(true);  // (a stroke that failed already reported it and sends nothing)
    const bool started = t.started;
    const std::string id = t.strokeEntity;
    const std::uint64_t historyId = t.historyId, step = t.historyStep;
    t.stroke.end();
    t.started = false;
    if (!started) return;
    ++t.strokes;
    const Json args = Json::object({{"entity", id}});
    UndoCommand fwd{"foliage.redo", args, "", step, historyId};
    UndoCommand back{"foliage.undo", args, "", step, historyId};
    push_command_entry("foliage:stroke:" + std::to_string(uiFrame_), {fwd}, {back});
}

// Esc: the stroke goes back (foliage.undo of the step it made) and nothing is recorded.
void Editor::foliage_stroke_cancel() {
    FoliageUi& t = foliage_;
    if (!t.stroke.active()) return;
    const bool started = t.started;
    const std::string id = t.strokeEntity;
    t.stroke.end();
    t.started = false;
    if (!started) return;
    const Json args = Json::object({{"entity", id}});
    const CommandResult res = engine_->commands().call("foliage.undo", args);
    after_command("foliage.undo", args, res);
    if (!res.ok) {
        notify("foliage.undo: " + command_error_text(res.error), 2);
        return;
    }
    if (res.result.is_object() && res.result.contains("instances") && res.result["instances"].is_number_integer()) {
        t.instances = res.result["instances"].get<long long>();
        t.instancesOf = id;
    }
    dirty_ = t.dirtyBefore;  // the file is what it was before the press: the title no longer shows an edit nobody made
    note_cells_edit();
}

// ---------------------------------------------------------------------------------------------------------------- viewport --
bool Editor::foliage_tool_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered) {
    FoliageUi& t = foliage_;
    if (!engine_ || r.target_width() <= 0) return false;
    World& w = world();
    ImGuiIO& io = ImGui::GetIO();
    const Entity e = selected();
    if (t.stroke.active() && (e.is_null() || w.id_of(e) != t.strokeEntity || play_ != PlayState::Edit))
        foliage_stroke_end();
    const Entity ground = foliage_ground(w, e);
    if (ground.is_null()) {
        t.hasHit = false;
        return false;
    }
    const ViewMap map{&r, imgMin, size};

    // Keys while the viewport has the keyboard: [ and ] the radius, Esc takes a stroke back.
    const bool keys = (vpHovered_ || vpFocused_) && !io.WantTextInput;
    if (keys) {
        const Terrain3D* tc = w.get<Terrain3D>(ground);
        const float maxR = std::min(0.5f * std::min(tc->size.x, tc->size.y), kBrushMaxRadius);
        const int up = ImGui::IsKeyPressed(ImGuiKey_RightBracket, true) ? 1 : 0;
        const int down = ImGui::IsKeyPressed(ImGuiKey_LeftBracket, true) ? 1 : 0;
        if (up || down) brush_step_radius(t.brush, up - down, maxR);
        if (ImGui::IsKeyPressed(ImGuiKey_Escape, false) && t.stroke.active()) {
            foliage_stroke_cancel();
            return true;
        }
    }

    // The ground under the mouse (while the mouse is down the stroke follows it even outside the image).
    Vec3 hit{};
    const bool over = hovered || t.stroke.active();
    t.hasHit = over && terrain_under_mouse(w, ground, map, io.MousePos, hit);
    if (t.hasHit) t.hit = hit;

    if (t.stroke.active()) {
        if (!io.MouseDown[0]) {
            foliage_stroke_end();
            return true;
        }
        if (t.hasHit) t.stroke.add(Vec2{hit.x, hit.z});
        if (!foliage_stroke_flush(false))
            foliage_stroke_end();
        else if (t.stroke.full() && t.stroke.pending() == 0)
            foliage_stroke_end();
        return true;
    }
    if (hovered && t.hasHit && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
        foliage_stroke_begin(e, Vec2{hit.x, hit.z});
        if (!foliage_stroke_flush(false)) foliage_stroke_end();
        return true;
    }
    return false;
}

void Editor::foliage_tool_draw(ImDrawList* dl, Renderer& r, ImVec2 imgMin, ImVec2 size) {
    FoliageUi& t = foliage_;
    t.ringSegments = 0;
    if (!engine_ || r.target_width() <= 0 || !t.hasHit || !foliage_tool_active()) return;
    World& w = world();
    const Entity ground = foliage_ground(w, selected());
    if (ground.is_null() || !(vpHovered_ || t.stroke.active())) return;
    const ViewMap map{&r, imgMin, size};
    const BrushSettings& b = t.stroke.active() ? t.strokeBrush : t.brush;
    const bool adding =
        t.stroke.active() ? ((t.strokeMode == FoliageMode::Add) != t.strokeInvert) : (t.mode == FoliageMode::Add);
    const ImU32 col = adding ? IM_COL32(120, 230, 110, 255) : IM_COL32(255, 110, 100, 255);
    const std::vector<Vec2> pts = brush_ring(Vec2{t.hit.x, t.hit.z}, b.radius, 64);
    std::vector<ImVec2> screen;
    screen.reserve(pts.size());
    for (const Vec2& p : pts) {
        float y = t.hit.y;
        (void)terrain_height_at(w, ground, p.x, p.y, y,
                                true);  // outside the grid the ring stays at the height of the hit
        screen.push_back(map.to_screen(Vec3{p.x, y + 0.02f, p.y}));
    }
    dl->AddPolyline(screen.data(), int(screen.size()), IM_COL32(0, 0, 0, 160), ImDrawFlags_Closed, 3.6f);
    dl->AddPolyline(screen.data(), int(screen.size()), col, ImDrawFlags_Closed, 1.6f);
    t.ringSegments = int(screen.size());
    dl->AddCircleFilled(map.to_screen(Vec3{t.hit.x, t.hit.y + 0.02f, t.hit.z}), 2.5f, col);
}

// ------------------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_foliage_tool_panel() {
    if (ImGuiWindow* insp = ImGui::FindWindowByName("Inspector"); insp && insp->DockId != 0)
        ImGui::SetNextWindowDockID(insp->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(340, 460), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Foliage tool", &showFoliageTool_)) {
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) {
        ImGui::TextDisabled("Stop the game to paint foliage: the brush changes the scene.");
        ImGui::End();
        return;
    }
    World& w = world();
    FoliageUi& t = foliage_;
    const Entity e = selected();
    const Foliage* fc = e.is_null() ? nullptr : w.get<Foliage>(e);
    if (!fc) {
        ImGui::TextWrapped("Select an entity with a Foliage component (a terrain with a Foliage on it works too). The "
                           "brush works in the "
                           "viewport on the ground of the selected Foliage.");
        ImGui::End();
        return;
    }
    const Entity ground = foliage_ground(w, e);
    ImGui::Text("Foliage: %s", w.info(e).name.c_str());
    ImGui::SetItemTooltip(
        "A click in the viewport that misses the terrain (sky, another object) does nothing: the Foliage "
        "stays selected and the tool stays on.");
    if (ground.is_null()) {
        ImGui::TextWrapped("This Foliage has no terrain to grow on: set ScatterRule.terrain to the entity with the "
                           "Terrain3D, or put the "
                           "Foliage on the terrain entity or under it.");
        at_track("foliage:noground");
        ImGui::End();
        return;
    }
    const Terrain3D* tc = w.get<Terrain3D>(ground);
    const float maxR = std::max(kBrushMinRadius, std::min(0.5f * std::min(tc->size.x, tc->size.y), kBrushMaxRadius));
    brush_clamp(t.brush, maxR);

    bool firstMode = true;
    auto mode_button = [&](const char* label, FoliageMode mode, const char* id, const char* tip) {
        const bool on = t.mode == mode;
        if (!firstMode) ImGui::SameLine();
        firstMode = false;
        if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
        if (ImGui::Button(label)) {
            foliage_stroke_end();
            terrain_stroke_end();  // one brush tool at a time
            terrain_.mode = TerrainMode::Off;
            t.mode = on ? FoliageMode::Off : mode;
            t.clearArmed = false;
        }
        if (on) ImGui::PopStyleColor();
        at_track(id);
        ImGui::SetItemTooltip("%s", tip);
    };
    mode_button(
        " Add ", FoliageMode::Add, "foliage:mode:add",
        "Paint new instances inside the brush, by the rules of the ScatterRule (slope, height, layers, spacing). Hold "
        "Ctrl while you paint to erase instead.");
    mode_button(" Remove ", FoliageMode::Remove, "foliage:mode:remove",
                "Erase the instances inside the brush. Hold Ctrl while you paint to add instead.");
    if (t.mode == FoliageMode::Off) {
        ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        ImGui::TextWrapped(
            "Pick a mode. While one is on the viewport gizmo is off (click the mode again to leave it).");
        ImGui::PopStyleColor();
    }

    if (t.mode != FoliageMode::Off) {
        ImGui::SeparatorText("Brush");
        ImGui::SetNextItemWidth(180);
        ImGui::SliderFloat("radius (m)", &t.brush.radius, kBrushMinRadius, maxR, "%.2f", ImGuiSliderFlags_Logarithmic);
        at_track("foliage:radius");
        ImGui::SetItemTooltip("[ and ] with the mouse over the viewport make it smaller and bigger");
        if (t.mode == FoliageMode::Add) {
            ImGui::Checkbox("density of the ScatterRule", &t.ruleDensity);
            at_track("foliage:ruledensity");
            ImGui::SetItemTooltip(
                "On: the brush plants as dense as the entity's ScatterRule (0.1 per square metre without one). "
                "Off: the density below.");
            ImGui::BeginDisabled(t.ruleDensity);
            ImGui::SetNextItemWidth(180);
            ImGui::SliderFloat("density (/m2)", &t.density, 0.01f, 20.0f, "%.2f", ImGuiSliderFlags_Logarithmic);
            at_track("foliage:density");
            ImGui::EndDisabled();
            ImGui::SetItemTooltip(
                "Instances per square metre. A brush never puts two instances closer than half the average "
                "gap, so painting the same spot twice does not stack them.");
        }
        // The mesh the brush is limited to (add: only that mesh is planted; remove: only that mesh is erased).
        const int meshCount = int(std::min<std::size_t>(fc->meshes.size(), 16));
        if (t.mesh >= meshCount) t.mesh = -1;
        const std::string current = t.mesh < 0 ? std::string("every mesh") : mesh_at(*fc, t.mesh);
        ImGui::SetNextItemWidth(220);
        if (ImGui::BeginCombo("mesh", current.empty() ? "?" : current.c_str())) {
            if (ImGui::Selectable("every mesh", t.mesh < 0)) t.mesh = -1;
            at_track("foliage:mesh:all");
            for (int i = 0; i < meshCount; ++i) {
                const std::string name = mesh_at(*fc, i);
                if (name.empty()) continue;
                ImGui::PushID(i);
                if (ImGui::Selectable(name.c_str(), t.mesh == i)) t.mesh = i;
                at_track("foliage:mesh:" + std::to_string(i));
                ImGui::PopID();
            }
            ImGui::EndCombo();
        }
        at_track("foliage:mesh");
        ImGui::SetItemTooltip("Limit the brush to one of Foliage.meshes: it plants or erases only that mesh");
    }

    ImGui::SeparatorText("Whole Foliage");
    const bool hasRule = w.has<ScatterRule>(e);
    ImGui::BeginDisabled(!hasRule);
    if (ImGui::Button("Scatter all")) {
        foliage_stroke_end();
        t.clearArmed = false;
        std::string error;
        const CommandResult res = edit_command("foliage:scatter:" + std::to_string(uiFrame_), "foliage.scatter",
                                               Json::object({{"entity", w.id_of(e)}}), &error);
        if (!res.ok) {
            t.error = "foliage.scatter: " + error;
            notify(t.error, 2);
        } else {
            t.error.clear();
            if (res.result.is_object() && res.result.contains("instances") &&
                res.result["instances"].is_number_integer()) {
                t.instances = res.result["instances"].get<long long>();
                t.instancesOf = w.id_of(e);
            }
        }
    }
    ImGui::EndDisabled();
    at_track("foliage:scatter", hasRule);
    ImGui::SetItemTooltip(
        hasRule ? "Fill the whole Foliage from its ScatterRule (replaces the instances there are; one undo step)"
                : "Needs a ScatterRule on this entity (the rules the brush follows too)");
    ImGui::SameLine();
    if (ImGui::Button(t.clearArmed ? "Click again to clear" : "Clear")) {
        if (!t.clearArmed) {
            t.clearArmed = true;  // a destroyed instance field is one undo step, but the history is 64 steps: ask first
        } else {
            t.clearArmed = false;
            foliage_stroke_end();
            std::string error;
            const CommandResult res = edit_command("foliage:clear:" + std::to_string(uiFrame_), "foliage.clear",
                                                   Json::object({{"entity", w.id_of(e)}}), &error);
            if (!res.ok) {
                t.error = "foliage.clear: " + error;
                notify(t.error, 2);
            } else {
                t.error.clear();
                if (res.result.is_object() && res.result.contains("instances") &&
                    res.result["instances"].is_number_integer()) {
                    t.instances = res.result["instances"].get<long long>();
                    t.instancesOf = w.id_of(e);
                }
            }
        }
    }
    at_track("foliage:clear");
    ImGui::SetItemTooltip(
        "Remove every instance of this Foliage (one undo step, Ctrl+Z brings them back). The first click arms "
        "the button, the second clears.");

    ImGui::SeparatorText("Foliage");
    if (!fc->instances.empty())
        ImGui::TextWrapped("File: %s", fc->instances.c_str());
    else
        ImGui::TextDisabled("No instances file yet: the first stroke or Scatter all writes one next to the scene.");
    if (t.instances >= 0 && t.instancesOf == w.id_of(e)) ImGui::Text("%lld instances", t.instances);
    at_track("foliage:status");
    ImGui::TextDisabled("Every stroke piece rewrites the whole file: a stroke sends a few pieces a second.");
    if (!t.error.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 0.45f, 0.4f, 1));
        ImGui::TextWrapped("%s", t.error.c_str());
        ImGui::PopStyleColor();
        at_track("foliage:error");
    }
    ImGui::End();
}

}  // namespace fa::editor
