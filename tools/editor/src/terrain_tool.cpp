// The terrain tool (View > Terrain tool): sculpt, paint and cut holes in the Terrain of the selected entity with a brush in the
// viewport (docs/EDITOR.md, "Terrain tool"). The brush (settings, stamps along the mouse path, ring, ray against the ground) is the
// shared one of brush.h; this file adds the terrain's own: which command a stamp is sent to and the panel.
//
// A stroke is ONE undo step of the editor, however many frames it lasts:
//   - every frame the stamps the mouse added go to terrain.sculpt, terrain.paint or terrain.holes, so the terrain changes under
//     the brush as it moves. The first call changes the terrain and starts a new undo step of the Terrain's own history; every later
//     call of the stroke carries `continueStroke`, which adds its patches to that step instead of making one per call (the history
//     keeps 64 steps: a call per frame would push the user's real history out in a second);
//   - on the release the editor pushes ONE command entry [terrain.redo] / [terrain.undo] on its undo stack (push_command_entry),
//     which marks the scene dirty like any edit. Ctrl+Z runs terrain.undo (the whole stroke goes back, bit for bit), Ctrl+Shift+Z
//     terrain.redo. The terrain's data is not in the scene snapshots the other edits take, which is why it needs a command entry.
// Esc during a stroke takes it back and records nothing.
#include <algorithm>
#include <cmath>
#include <format>

#include "editor_internal.h"
#include "fa/scene/terrain.h"
#include "imgui_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr std::size_t kPiecePoints = 256;  // stamps of one command call
constexpr int kPiecesPerFrame = 8;         // calls of one frame: a jump of the mouse is applied over a few frames

// The side of the plane the mode edits in `h` (terrain_plane_side): the splat maps it has, else what terrain.paint would make.
int edited_plane_side(TerrainMode mode, const TerrainHeights& h) {
    int splatSide = 0;
    for (const TerrainSplat& m : h.splat)
        if (m.valid()) splatSide = m.size;
    return terrain_plane_side(mode, h.cells(), splatSide);
}

double round4(double v) { return std::round(v * 1e4) / 1e4; }

const char* sculpt_name(SculptTool t) {
    switch (t) {
        case SculptTool::Raise: return "raise";
        case SculptTool::Lower: return "lower";
        case SculptTool::Smooth: return "smooth";
        case SculptTool::Flatten: return "flatten";
    }
    return "raise";
}

// The file name of a layer's albedo, the way the Inspector lists it ("grass" for "assets/terrain/grass.png").
std::string layer_name(const Json& layer, int index) {
    std::string name = "Layer " + std::to_string(index);
    if (layer.is_object() && layer.contains("albedo") && layer["albedo"].is_string()) {
        const std::string path = layer["albedo"].get<std::string>();
        if (!path.empty()) {
            const std::size_t slash = path.find_last_of('/');
            std::string stem = path.substr(slash == std::string::npos ? 0 : slash + 1);
            const std::size_t dot = stem.find('.');
            if (dot != std::string::npos && dot > 0) stem.resize(dot);
            if (!stem.empty()) name += ": " + stem;
        }
    }
    return name;
}

struct ViewMap {
    Renderer* r = nullptr;
    ImVec2 imgMin{}, size{};
    Vec2 design(ImVec2 m) const {
        return Vec2{(m.x - imgMin.x) / size.x * float(r->target_width()),
                    (m.y - imgMin.y) / size.y * float(r->target_height())};
    }
    ImVec2 to_screen(Vec3 w) const {
        const Vec2 d = r->world_to_screen(w);
        return ImVec2(imgMin.x + d.x / float(r->target_width()) * size.x,
                      imgMin.y + d.y / float(r->target_height()) * size.y);
    }
};

// The ground of the Terrain `e` under the mouse: the camera's ray walked through the box the terrain fills, in a number of steps
// that depends on the terrain's own cells (never on the time), a quarter of a cell apart at most and never more than
// kMaxRaySteps. The heights, the matrices and the terrain's fields are read ONCE here (the store's lock and a matrix inverse per
// step were the cost of this function): a step is a bilinear sample of the grid.
constexpr int kMaxRaySteps = 4096;

bool terrain_under_mouse(const World& w, Entity e, const ViewMap& map, ImVec2 mouse, Vec3& hit) {
    const Terrain3D* t = w.get<Terrain3D>(e);
    if (!t || !(t->size.x > 0.0f) || !(t->size.y > 0.0f)) return false;
    std::string problem;
    const std::shared_ptr<TerrainHeights> h = w.terrain().heights(w, e, &problem);
    if (!h || !h->valid()) return false;
    Vec3 origin, dir;
    map.r->screen_ray(map.design(mouse), origin, dir);
    if (!std::isfinite(origin.x + origin.y + origin.z + dir.x + dir.y + dir.z)) return false;
    // The box of the terrain in the world: its local box through the entity's matrix.
    const Mat4 m = w.world_matrix(e);
    const Mat4 inv = m.inverse();
    const float groundY = m.translation().y;
    const float y0 = std::min(t->heightOffset, t->heightOffset + t->heightScale);
    const float y1 = std::max(t->heightOffset, t->heightOffset + t->heightScale);
    Vec3 lo{1e30f, 1e30f, 1e30f}, hi{-1e30f, -1e30f, -1e30f};
    for (int i = 0; i < 8; ++i) {
        const Vec3 p = m.transform_point(
            {(i & 1 ? 0.5f : -0.5f) * t->size.x, i & 2 ? y1 : y0, (i & 4 ? 0.5f : -0.5f) * t->size.y});
        lo = {std::min(lo.x, p.x), std::min(lo.y, p.y), std::min(lo.z, p.z)};
        hi = {std::max(hi.x, p.x), std::max(hi.y, p.y), std::max(hi.z, p.z)};
    }
    float t0 = 0.0f, t1 = 0.0f;
    if (!brush_ray_box(origin, dir, lo - Vec3{0.01f}, hi + Vec3{0.01f}, t0, t1)) return false;
    const float dirLen = std::max(length(dir), 1e-6f);
    const float cell = std::min(t->size.x, t->size.y) / float(std::max(h->cells(), 1));
    const int steps = int(std::clamp(std::ceil((t1 - t0) * dirLen / (cell * 0.25f)), 1.0f, float(kMaxRaySteps)));
    // The ground terrain_height_at answers (a hole has ground to aim at, so the ray ignores the cut cells), from the values read
    // above.
    return brush_ray_ground(
        origin, dir, t0, t1, steps,
        [&](float x, float z, float& y) {
            const Vec3 local = inv.transform_point({x, groundY, z});
            float ly = 0.0f, dx = 0.0f, dz = 0.0f;
            if (!terrain_local_sample(*h, *t, local.x, local.z, ly, dx, dz, true)) return false;
            y = m.transform_point({local.x, ly, local.z}).y;
            return true;
        },
        hit);
}

}  // namespace

// ------------------------------------------------------------------------------------------------------------- pure parts --
float terrain_max_radius(Vec2 size, int planeSide) {
    const float half = 0.5f * std::min(size.x, size.y);
    // 900 texels of the edited plane, under the 1024 the commands accept, so a brush of the largest radius is never refused.
    const float texels = planeSide > 0 ? 900.0f * std::min(size.x, size.y) / float(planeSide) : kBrushMaxRadius;
    float r = std::min({half, texels, kBrushMaxRadius});
    if (!(r >= kBrushMinRadius)) r = kBrushMinRadius;
    return r;
}

int terrain_plane_side(TerrainMode mode, int cells, int splatSide) {
    if (mode != TerrainMode::Paint)
        return cells;  // the heights have cells + 1 samples a side, the holes mask `cells` cells
    return splatSide > 0 ? splatSide : std::min(cells, 1024);  // terrain.paint makes its maps that big
}

TerrainCall terrain_stroke_call(const TerrainUi& ui, const std::string& entityId, const std::vector<Vec2>& points,
                                bool continueStroke) {
    TerrainCall c;
    c.args = Json::object({{"entity", entityId}});
    Json pts = Json::array();
    for (const Vec2& p : points) pts.push_back(Json::array({round4(p.x), round4(p.y)}));
    c.args["points"] = pts;
    c.args["radius"] = round4(ui.strokeBrush.radius);
    switch (ui.strokeMode) {
        case TerrainMode::Sculpt: {
            c.command = "terrain.sculpt";
            SculptTool tool = ui.strokeSculpt;
            if (ui.strokeInvert && tool == SculptTool::Raise)
                tool = SculptTool::Lower;
            else if (ui.strokeInvert && tool == SculptTool::Lower)
                tool = SculptTool::Raise;
            c.args["tool"] = sculpt_name(tool);
            c.args["strength"] = round4(ui.strokeBrush.strength);
            c.args["falloff"] = round4(ui.strokeBrush.falloff);
            if (tool == SculptTool::Raise || tool == SculptTool::Lower) c.args["amount"] = round4(ui.strokeAmount);
            if (tool == SculptTool::Flatten) c.args["height"] = round4(ui.strokeHeight);
            break;
        }
        case TerrainMode::Paint:
            c.command = "terrain.paint";
            c.args["layer"] = ui.strokeLayer;
            c.args["strength"] = round4(ui.strokeBrush.strength);
            c.args["falloff"] = round4(ui.strokeBrush.falloff);
            break;
        case TerrainMode::Holes:
            c.command = "terrain.holes";
            c.args["mode"] = (ui.strokeCut != ui.strokeInvert) ? "cut" : "fill";
            break;
        case TerrainMode::Off: break;
    }
    if (continueStroke) c.args["continueStroke"] = true;
    return c;
}

// ------------------------------------------------------------------------------------------------------------------ strokes --
bool Editor::terrain_tool_active() {
    if (!showTerrainTool_ || terrain_.mode == TerrainMode::Off || !engine_ || play_ != PlayState::Edit) return false;
    const Entity e = selected();
    return !e.is_null() && world().has<Terrain3D>(e);
}

bool Editor::has_unsaved_work() { return dirty() || has_unsaved_terrain(); }

bool Editor::has_unsaved_terrain() {
    if (!engine_) return false;
    for (Entity e : world().terrain().entities()) {
        const std::shared_ptr<TerrainHeights> h = world().terrain().find(e);
        if (h && h->any_unsaved()) return true;
    }
    return false;
}

void Editor::forget_unsaved_terrain() {
    if (!engine_) return;
    for (Entity e : world().terrain().entities())
        if (const std::shared_ptr<TerrainHeights> h = world().terrain().find(e)) {
            h->heightsUnsaved = h->holesUnsaved = false;
            h->splat[0].unsaved = h->splat[1].unsaved = false;
        }
}

bool Editor::terrain_stroke_active() const { return terrain_.stroke.active(); }

void Editor::terrain_stroke_begin(Entity e, Vec2 at) {
    TerrainUi& t = terrain_;
    const ImGuiIO& io = ImGui::GetIO();
    t.strokeEntity = world().id_of(e);
    t.strokeBrush = t.brush;
    t.strokeMode = t.mode;
    t.strokeSculpt = t.sculpt;
    t.strokeInvert = io.KeyCtrl;
    t.strokeCut = t.cut;
    t.strokeLayer = t.layer;
    t.strokeAmount = t.amount;
    // Flatten: every piece of the stroke flattens to one height (a piece without `height` would take the ground under ITS first
    // stamp, and the stroke would stair-step).
    t.strokeHeight = t.flattenHeight;
    if (t.flattenAuto) t.strokeHeight = t.hasHit ? t.hit.y : t.flattenHeight;
    t.started = false;
    t.failed = false;
    t.pieces = 0;
    t.error.clear();
    t.dirtyBefore = dirty_;
    t.unsavedBefore = {};
    if (const std::shared_ptr<TerrainHeights> h = world().terrain().find(e))
        t.unsavedBefore = {h->heightsUnsaved, h->holesUnsaved, h->splat[0].unsaved, h->splat[1].unsaved};
    t.stroke.begin(at, t.strokeBrush.radius);
}

// Sends what the stroke has not sent yet. Returns false when a command refused (the stroke is over then): the refusal is reported
// once, and a stroke that failed sends nothing more, not even at its end.
bool Editor::terrain_stroke_flush() {
    TerrainUi& t = terrain_;
    if (!t.stroke.active()) return true;
    if (t.failed) return false;
    for (int piece = 0; piece < kPiecesPerFrame && t.stroke.pending() > 0; ++piece) {
        std::vector<Vec2> pts;
        t.stroke.take_pending(pts, kPiecePoints);
        const TerrainCall call = terrain_stroke_call(t, t.strokeEntity, pts, t.started);
        const CommandResult res = engine_->commands().call(call.command, call.args);
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
        const bool changed = r.is_object() && (r.value("changedSamples", 0) > 0 || r.value("changedTexels", 0) > 0);
        if (changed && !t.started) {
            t.started = true;
            mark_dirty();  // the title shows the unsaved edit while the mouse is still down
        }
    }
    return true;
}

// The mouse went up (or the stroke must stop): what changed is one undo step of the editor.
void Editor::terrain_stroke_end() {
    TerrainUi& t = terrain_;
    if (!t.stroke.active()) return;
    terrain_stroke_flush();  // (a stroke that failed already reported it and sends nothing)
    const bool started = t.started;
    const std::string id = t.strokeEntity;
    t.stroke.end();
    t.started = false;
    if (!started) return;
    ++t.strokes;
    UndoCommand fwd{"terrain.redo", Json::object({{"entity", id}}), ""};
    UndoCommand back{"terrain.undo", Json::object({{"entity", id}}), ""};
    push_command_entry("terrain:stroke:" + std::to_string(uiFrame_), {fwd}, {back});
}

// Esc: the stroke goes back (terrain.undo of the step it made) and nothing is recorded.
void Editor::terrain_stroke_cancel() {
    TerrainUi& t = terrain_;
    if (!t.stroke.active()) return;
    const bool started = t.started;
    const std::string id = t.strokeEntity;
    t.stroke.end();
    t.started = false;
    if (!started) return;
    const Json args = Json::object({{"entity", id}});
    const CommandResult res = engine_->commands().call("terrain.undo", args);
    after_command("terrain.undo", args, res);
    if (!res.ok) {
        notify("terrain.undo: " + command_error_text(res.error), 2);
        return;
    }
    // The data is what it was before the press: so are the "unsaved" marks (the stroke set them), and the title no longer shows an
    // edit nobody made.
    dirty_ = t.dirtyBefore;
    const Entity e = world().find_by_id(id);
    if (const std::shared_ptr<TerrainHeights> h = e.is_null() ? nullptr : world().terrain().find(e)) {
        h->heightsUnsaved = t.unsavedBefore[0];
        h->holesUnsaved = t.unsavedBefore[1];
        h->splat[0].unsaved = t.unsavedBefore[2];
        h->splat[1].unsaved = t.unsavedBefore[3];
    }
    // The stroke told the cells panel its cell may be unsaved (mark_dirty): the data is back, so the cell is checked again against its
    // baseline and shows clean when nothing else changed it.
    note_cells_edit();
}

// ---------------------------------------------------------------------------------------------------------------- viewport --
bool Editor::terrain_tool_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered) {
    TerrainUi& t = terrain_;
    if (!engine_ || r.target_width() <= 0) return false;
    World& w = world();
    ImGuiIO& io = ImGui::GetIO();
    const Entity e = selected();
    if (t.stroke.active() && (e.is_null() || w.id_of(e) != t.strokeEntity || play_ != PlayState::Edit))
        terrain_stroke_end();
    if (e.is_null() || !w.has<Terrain3D>(e)) {
        t.hasHit = false;
        return false;
    }
    const ViewMap map{&r, imgMin, size};

    // Keys while the viewport has the keyboard: [ and ] the radius, Shift+[ and Shift+] the strength, Esc takes a stroke back.
    const bool keys = (vpHovered_ || vpFocused_) && !io.WantTextInput;
    if (keys) {
        const Terrain3D* tc = w.get<Terrain3D>(e);
        const std::shared_ptr<TerrainHeights> known = w.terrain().find(e);
        const float maxR = terrain_max_radius(tc->size, known ? edited_plane_side(t.mode, *known) : 1);
        auto steps = [&](ImGuiKey k) { return ImGui::IsKeyPressed(k, true) ? 1 : 0; };
        const int up = steps(ImGuiKey_RightBracket), down = steps(ImGuiKey_LeftBracket);
        if (up || down) {
            if (io.KeyShift)
                brush_step_strength(t.brush, up - down);
            else
                brush_step_radius(t.brush, up - down, maxR);
        }
        if (ImGui::IsKeyPressed(ImGuiKey_Escape, false) && t.stroke.active()) {
            terrain_stroke_cancel();
            return true;
        }
    }

    // The ground under the mouse (while the mouse is down the stroke follows it even outside the image).
    Vec3 hit{};
    const bool over = hovered || t.stroke.active();
    t.hasHit = over && terrain_under_mouse(w, e, map, io.MousePos, hit);
    if (t.hasHit) t.hit = hit;

    if (t.stroke.active()) {
        if (!io.MouseDown[0]) {
            terrain_stroke_end();
            return true;
        }
        if (t.hasHit) t.stroke.add(Vec2{hit.x, hit.z});
        if (!terrain_stroke_flush())
            terrain_stroke_end();
        else if (t.stroke.full() && t.stroke.pending() == 0)
            terrain_stroke_end();
        return true;
    }
    if (hovered && t.hasHit && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
        if (t.pickingHeight || io.KeyAlt) {  // the eyedropper: the ground's height becomes the flatten height
            t.flattenHeight = std::round(hit.y * 1000.0f) / 1000.0f;
            t.flattenAuto = false;
            t.pickingHeight = false;
            return true;
        }
        terrain_stroke_begin(e, Vec2{hit.x, hit.z});
        if (!terrain_stroke_flush()) terrain_stroke_end();
        return true;
    }
    return false;
}

void Editor::terrain_tool_draw(ImDrawList* dl, Renderer& r, ImVec2 imgMin, ImVec2 size) {
    TerrainUi& t = terrain_;
    t.ringSegments = 0;
    if (!engine_ || r.target_width() <= 0 || !t.hasHit || !terrain_tool_active()) return;
    World& w = world();
    const Entity e = selected();
    if (!(vpHovered_ || t.stroke.active())) return;
    const ViewMap map{&r, imgMin, size};
    const BrushSettings& b = t.stroke.active() ? t.strokeBrush : t.brush;
    ImU32 col = IM_COL32(255, 210, 70, 255);  // sculpt
    if (t.mode == TerrainMode::Paint) col = IM_COL32(90, 200, 255, 255);
    if (t.mode == TerrainMode::Holes) col = IM_COL32(255, 100, 100, 255);
    auto ring = [&](float radius, float width, ImU32 c) {
        const std::vector<Vec2> pts = brush_ring(Vec2{t.hit.x, t.hit.z}, radius, 64);
        std::vector<ImVec2> screen;
        screen.reserve(pts.size());
        for (const Vec2& p : pts) {
            float y = t.hit.y;
            (void)terrain_height_at(w, e, p.x, p.y, y,
                                    true);  // outside the grid the ring stays at the height of the hit
            screen.push_back(map.to_screen(Vec3{p.x, y + 0.02f, p.y}));
        }
        dl->AddPolyline(screen.data(), int(screen.size()), IM_COL32(0, 0, 0, 160), ImDrawFlags_Closed, width + 2.0f);
        dl->AddPolyline(screen.data(), int(screen.size()), c, ImDrawFlags_Closed, width);
        t.ringSegments = int(screen.size());
    };
    ring(b.radius, 1.6f, col);
    const float inner = brush_inner_radius(b);
    if (inner > 0.02f * b.radius && t.mode != TerrainMode::Holes) ring(inner, 1.0f, (col & 0x00FFFFFF) | 0x99000000);
    const ImVec2 c = map.to_screen(Vec3{t.hit.x, t.hit.y + 0.02f, t.hit.z});
    dl->AddCircleFilled(c, 2.5f, col);
}

// ------------------------------------------------------------------------------------------------------------------- panel --
void Editor::draw_terrain_tool_panel() {
    if (ImGuiWindow* insp = ImGui::FindWindowByName("Inspector"); insp && insp->DockId != 0)
        ImGui::SetNextWindowDockID(insp->DockId, ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(340, 520), ImGuiCond_FirstUseEver);
    if (!ImGui::Begin("Terrain tool", &showTerrainTool_)) {
        ImGui::End();
        return;
    }
    if (play_ != PlayState::Edit) {
        ImGui::TextDisabled("Stop the game to edit the terrain: the brush changes the scene.");
        ImGui::End();
        return;
    }
    World& w = world();
    TerrainUi& t = terrain_;
    const Entity e = selected();
    const Terrain3D* tc = e.is_null() ? nullptr : w.get<Terrain3D>(e);
    if (!tc) {
        ImGui::TextWrapped(
            "Select an entity with a Terrain3D component (terrain.create makes one). The brush works in the "
            "viewport on the selected terrain.");
        ImGui::End();
        return;
    }
    std::string problem;
    const std::shared_ptr<TerrainHeights> heights = w.terrain().heights(w, e, &problem);
    if (!heights) {
        ImGui::TextWrapped("The heights of '%s' cannot be used: %s", w.info(e).name.c_str(),
                           problem.empty() ? "no heightmap" : problem.c_str());
        ImGui::End();
        return;
    }
    const float maxR = terrain_max_radius(tc->size, edited_plane_side(t.mode, *heights));
    brush_clamp(t.brush, maxR);

    bool firstMode = true;
    auto mode_button = [&](const char* label, TerrainMode mode, const char* id, const char* tip) {
        const bool on = t.mode == mode;
        const float width = ImGui::CalcTextSize(label).x + ImGui::GetStyle().FramePadding.x * 2;
        const float right = ImGui::GetCursorScreenPos().x + ImGui::GetContentRegionAvail().x;
        if (!firstMode && ImGui::GetItemRectMax().x + ImGui::GetStyle().ItemSpacing.x + width <= right)
            ImGui::SameLine();
        firstMode = false;
        if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
        if (ImGui::Button(label)) {
            terrain_stroke_end();
            t.mode = on ? TerrainMode::Off : mode;
            t.pickingHeight = false;
        }
        if (on) ImGui::PopStyleColor();
        at_track(id);
        ImGui::SetItemTooltip("%s", tip);
    };
    ImGui::Text("Terrain: %s", w.info(e).name.c_str());
    ImGui::SetItemTooltip("A click in the viewport that misses the terrain (sky, another object) does nothing: the "
                          "terrain stays selected and the "
                          "tool stays on.");
    mode_button(" Sculpt ", TerrainMode::Sculpt, "terrain:mode:sculpt",
                "Raise, lower, smooth or flatten the heights with the brush");
    mode_button(" Paint ", TerrainMode::Paint, "terrain:mode:paint",
                "Paint one of the terrain's material layers (the splat maps)");
    mode_button(" Holes ", TerrainMode::Holes, "terrain:mode:holes", "Cut holes (caves, tunnels) or fill them again");
    if (t.mode == TerrainMode::Off) {
        ImGui::PushStyleColor(ImGuiCol_Text, ImGui::GetStyleColorVec4(ImGuiCol_TextDisabled));
        ImGui::TextWrapped(
            "Pick a mode. While one is on the viewport gizmo is off (click the mode again to leave it).");
        ImGui::PopStyleColor();
    }

    if (t.mode == TerrainMode::Sculpt) {
        ImGui::SeparatorText("Sculpt");
        bool first = true;
        auto tool_button = [&](const char* label, SculptTool tool, const char* id, const char* tip) {
            if (!first) ImGui::SameLine();
            first = false;
            const bool on = t.sculpt == tool;
            if (on) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
            if (ImGui::Button(label)) t.sculpt = tool;
            if (on) ImGui::PopStyleColor();
            at_track(id);
            ImGui::SetItemTooltip("%s", tip);
        };
        tool_button("Raise", SculptTool::Raise, "terrain:sculpt:raise", "Push the ground up (hold Ctrl to lower)");
        tool_button("Lower", SculptTool::Lower, "terrain:sculpt:lower", "Dig the ground down (hold Ctrl to raise)");
        tool_button("Smooth", SculptTool::Smooth, "terrain:sculpt:smooth", "Average the ground with its neighbours");
        tool_button("Flatten", SculptTool::Flatten, "terrain:sculpt:flatten", "Level the ground to one height");
        if (t.sculpt == SculptTool::Raise || t.sculpt == SculptTool::Lower) {
            ImGui::SetNextItemWidth(160);
            ImGui::DragFloat("amount (m)", &t.amount, 0.01f, 0.001f, 100.0f, "%.3f", ImGuiSliderFlags_Logarithmic);
            t.amount = std::clamp(t.amount, 0.001f, 100.0f);
            at_track("terrain:amount");
            ImGui::SetItemTooltip(
                "Metres one stamp changes the ground at the middle of the brush at full strength. Stamps are a "
                "quarter of the radius apart, so the ground under the brush gets several of them.");
        }
        if (t.sculpt == SculptTool::Flatten) {
            ImGui::Checkbox("height under the first click", &t.flattenAuto);
            at_track("terrain:flatten:auto");
            ImGui::SetItemTooltip(
                "On: a stroke levels the ground to the height it found where you pressed. Off: to the height below.");
            ImGui::BeginDisabled(t.flattenAuto);
            ImGui::SetNextItemWidth(120);
            ImGui::DragFloat("height (m)", &t.flattenHeight, 0.05f, -100000.0f, 100000.0f, "%.3f");
            at_track("terrain:flatten:height");
            ImGui::EndDisabled();
            if (t.pickingHeight) ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
            if (ImGui::Button(t.pickingHeight ? "Click the ground..." : "Pick from the terrain"))
                t.pickingHeight = !t.pickingHeight;
            if (t.pickingHeight) ImGui::PopStyleColor();
            at_track("terrain:flatten:pick");
            ImGui::SetItemTooltip(
                "Then click the ground in the viewport: its height becomes the flatten height (Alt+click does it "
                "without this button).");
        }
    }
    if (t.mode == TerrainMode::Paint) {
        ImGui::SeparatorText("Paint a layer");
        const Json& layers = tc->layers;
        if (!layers.is_array() || layers.empty()) {
            ImGui::TextWrapped(
                "This terrain has no layers. Add them to Terrain.layers in the Inspector: each one an albedo texture "
                "(at most 8). The brush paints the layer you pick here.");
        } else {
            const int n = int(std::min<std::size_t>(layers.size(), 8));
            t.layer = std::clamp(t.layer, 0, n - 1);
            for (int i = 0; i < n; ++i) {
                ImGui::PushID(i);
                const Json& layer = layers[std::size_t(i)];
                const float side = ImGui::GetFrameHeight();
                const TextureEntry* tex = nullptr;
                if (layer.is_object() && layer.contains("albedo") && layer["albedo"].is_string() &&
                    !layer["albedo"].get<std::string>().empty())
                    tex = texture_for(layer["albedo"].get<std::string>());
                const ImVec2 p0 = ImGui::GetCursorScreenPos();
                if (ImGui::Selectable("##layer", t.layer == i, 0, ImVec2(0, side))) t.layer = i;
                at_track("terrain:layer:" + std::to_string(i));
                ImDrawList* dl = ImGui::GetWindowDrawList();
                if (tex && tex->w > 0 && tex->h > 0)
                    dl->AddImage(ImTextureRef(ImTextureID(ui::texture_from_view(tex->view, true))), p0,
                                 ImVec2(p0.x + side, p0.y + side));
                else
                    dl->AddRectFilled(p0, ImVec2(p0.x + side, p0.y + side), IM_COL32(70, 70, 76, 255));
                dl->AddText(ImVec2(p0.x + side + 6, p0.y + (side - ImGui::GetFontSize()) * 0.5f),
                            ImGui::GetColorU32(ImGuiCol_Text), layer_name(layer, i).c_str());
                ImGui::PopID();
            }
        }
    }
    if (t.mode == TerrainMode::Holes) {
        ImGui::SeparatorText("Holes");
        if (ImGui::RadioButton("Cut", t.cut)) t.cut = true;
        at_track("terrain:holes:cut");
        ImGui::SameLine();
        if (ImGui::RadioButton("Fill", !t.cut)) t.cut = false;
        at_track("terrain:holes:fill");
        ImGui::SetItemTooltip(
            "Hold Ctrl while you paint to do the other one. A brush smaller than a cell can miss every cell.");
    }

    if (t.mode != TerrainMode::Off) {
        ImGui::SeparatorText("Brush");
        ImGui::SetNextItemWidth(180);
        ImGui::SliderFloat("radius (m)", &t.brush.radius, kBrushMinRadius, maxR, "%.2f", ImGuiSliderFlags_Logarithmic);
        at_track("terrain:radius");
        ImGui::SetItemTooltip("[ and ] with the mouse over the viewport make it smaller and bigger");
        if (t.mode != TerrainMode::Holes) {
            ImGui::SetNextItemWidth(180);
            ImGui::SliderFloat("strength", &t.brush.strength, 0.0f, 1.0f, "%.2f");
            at_track("terrain:strength");
            ImGui::SetItemTooltip(
                "How much of the effect a stamp applies. Shift+[ and Shift+] change it from the keyboard");
            ImGui::SetNextItemWidth(180);
            ImGui::SliderFloat("falloff", &t.brush.falloff, 0.0f, 1.0f, "%.2f");
            at_track("terrain:falloff");
            ImGui::SetItemTooltip(
                "The share of the radius the effect fades over: 1 from the middle to the edge, 0 a hard edge. "
                "The inner ring of the cursor is where the full effect ends.");
        }
        brush_clamp(t.brush, maxR);
    }

    ImGui::SeparatorText("Terrain");
    ImGui::Text("%d x %d samples, %zu edit%s to undo%s", heights->samples, heights->samples, heights->undo_depth(),
                heights->undo_depth() == 1 ? "" : "s",
                heights->any_unsaved() ? ", unsaved (Save writes the files)" : "");
    at_track("terrain:status");
    if (!t.error.empty()) {
        ImGui::PushStyleColor(ImGuiCol_Text, ImVec4(1.0f, 0.45f, 0.4f, 1));
        ImGui::TextWrapped("%s", t.error.c_str());
        ImGui::PopStyleColor();
        at_track("terrain:error");
    }
    ImGui::End();
}

}  // namespace fa::editor
