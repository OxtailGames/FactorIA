// Transform gizmos in the viewport: move (W), rotate (E), scale (R) the selected entity by dragging handles drawn with ImGui's
// draw list over the game image. The math (handle layout, hit testing, what a drag does) is in gizmo_model.h and works for
// orthographic 2D cameras, perspective 3D cameras and screen-space (HUD) entities alike. Nothing here edits the world directly:
// every change is a `scene.set_component` call on Transform through Editor::edit_command, the path the Inspector, the Console
// and the AI use, so undo (one step per drag), the scene file and the "lost on Stop" rule of the play modes come with it.
#include <algorithm>
#include <cmath>
#include <optional>

#include "editor_internal.h"
#include "ui_backend.h"

namespace fa::editor {

namespace {

constexpr float kHitPx = 7.0f;  // how close to a line the mouse has to be to grab it

float round4(float v) { return std::round(v * 10000.0f) / 10000.0f; }

Vec3 unit_axis(int i) {
    Vec3 a{};
    (&a.x)[i] = 1.0f;
    return a;
}

// Where things are on screen for one entity: the panel's mapping of world points and of the mouse onto the drag plane.
struct GizmoSpace {
    Renderer* r = nullptr;
    ImVec2 imgMin{0, 0}, size{1, 1};
    bool hud = false, threeD = false;
    Vec2 anchor{};
    float tw = 1, th = 1;

    Vec2 design_of(Vec2 m) const { return {(m.x - imgMin.x) / size.x * tw, (m.y - imgMin.y) / size.y * th}; }
    Vec2 to_panel(Vec2 d) const { return {imgMin.x + d.x / tw * size.x, imgMin.y + d.y / th * size.y}; }
    Vec2 project(Vec3 p) const {
        // A HUD entity's world matrix is already in design pixels (y down); only its anchor is added by the renderer.
        return to_panel(hud ? Vec2{p.x + anchor.x, p.y + anchor.y} : r->world_to_screen(p));
    }
    // The mouse on the plane through `pivot` that a free move slides in: z = const for 2D, parallel to the camera for 3D.
    std::optional<Vec3> on_plane(Vec2 mouse, Vec3 pivot) const {
        const Vec2 d = design_of(mouse);
        if (hud) return Vec3{d.x - anchor.x, d.y - anchor.y, pivot.z};
        if (!threeD) {
            Vec3 p = r->screen_to_world(d, pivot.z);
            p.z = pivot.z;
            return p;
        }
        Vec3 o, dir, o2, forward;
        r->screen_ray(d, o, dir);
        r->screen_ray(Vec2{tw * 0.5f, th * 0.5f}, o2, forward);
        Vec3 hit;
        if (!ray_plane(o, dir, pivot, forward, hit)) return std::nullopt;
        return hit;
    }
};

GizmoSpace make_space(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hud, bool threeD, Vec2 anchor) {
    GizmoSpace s;
    s.r = &r;
    s.imgMin = imgMin;
    s.size = size;
    s.hud = hud;
    s.threeD = threeD;
    s.anchor = anchor;
    s.tw = float(r.target_width());
    s.th = float(r.target_height());
    return s;
}

ImU32 axis_color(int axis, bool bright) {
    static const ImU32 normal[3] = {IM_COL32(225, 70, 70, 255), IM_COL32(90, 200, 90, 255), IM_COL32(90, 160, 255, 255)};
    static const ImU32 light[3] = {IM_COL32(255, 150, 150, 255), IM_COL32(160, 255, 160, 255), IM_COL32(150, 185, 255, 255)};
    if (axis < 0 || axis > 2) return bright ? IM_COL32(255, 235, 120, 255) : IM_COL32(235, 235, 235, 255);
    return bright ? light[axis] : normal[axis];
}

}  // namespace

void Editor::gizmo_toolbar_buttons() {
    struct Row { GizmoMode mode; const char* label; const char* id; const char* tip; };
    static const Row rows[] = {
        {GizmoMode::Select, " Select ", "toolbar:gizmo:select", "Select only: no handles in the viewport (Q)"},
        {GizmoMode::Move, " Move ", "toolbar:gizmo:move", "Move the selected entity by dragging its arrows or the centre square (W). Hold Ctrl to snap."},
        {GizmoMode::Rotate, " Rotate ", "toolbar:gizmo:rotate", "Rotate the selected entity by dragging a ring (E). Hold Ctrl to snap to 15 degrees."},
        {GizmoMode::Scale, " Scale ", "toolbar:gizmo:scale", "Scale the selected entity by dragging a handle or the centre box (R). Hold Ctrl to snap to 0.1."},
    };
    for (const Row& row : rows) {
        const bool on = gizmoMode_ == row.mode;
        if (on) {
            ImGui::PushStyleColor(ImGuiCol_Button, ImVec4(0.24f, 0.42f, 0.70f, 1));
            ImGui::PushStyleColor(ImGuiCol_ButtonHovered, ImVec4(0.30f, 0.50f, 0.78f, 1));
        }
        if (ImGui::Button(row.label)) {
            gizmo_end_drag(true);
            gizmoMode_ = row.mode;
        }
        if (on) ImGui::PopStyleColor(2);
        at_track(row.id);
        ImGui::SetItemTooltip("%s", row.tip);
        ImGui::SameLine();
    }
}

void Editor::gizmo_end_drag(bool cancel) {
    GizmoDrag& d = gizmoDrag_;
    if (!d.active) return;
    d.active = false;
    if (!cancel || !d.wrote || !engine_) return;
    // Esc: put the start value back and leave nothing behind, neither an undo step nor a dirty scene.
    const char* field = d.mode == GizmoMode::Move ? "position" : d.mode == GizmoMode::Rotate ? "rotation" : "scale";
    const Vec3 v = d.mode == GizmoMode::Move ? d.start.position : d.mode == GizmoMode::Rotate ? d.start.rotation : d.start.scale;
    if (lastEditKey_ == d.key) lastEditTime_ = time_;
    std::string err;
    edit_command(d.key, "scene.set_component",
                 field_edit_args(d.id, "Transform", field, Json::array({v.x, v.y, v.z})), &err);
    if (play_ == PlayState::Edit && !undo_.empty()) {
        undo_.pop_back();
        redo_ = std::move(d.redoBefore);
        dirty_ = d.dirtyBefore;
        lastEditKey_.clear();
    }
}

bool Editor::gizmo_frame(Renderer& r, ImVec2 imgMin, ImVec2 size, bool hovered) {
    gizmoShapes_.clear();
    gizmoHover_ = {};
    GizmoDrag& d = gizmoDrag_;
    ImGuiIO& io = ImGui::GetIO();
    World& w = world();
    const bool editing = play_ != PlayState::Playing;

    // Keys: Q select, W move, E rotate, R scale. Only with the viewport in use, no text box typing, no modifier held.
    if (editing && (vpHovered_ || vpFocused_) && !io.WantTextInput && !io.KeyCtrl && !io.KeyAlt && !io.KeySuper) {
        GizmoMode m = gizmoMode_;
        if (ImGui::IsKeyPressed(ImGuiKey_Q, false)) m = GizmoMode::Select;
        if (ImGui::IsKeyPressed(ImGuiKey_W, false)) m = GizmoMode::Move;
        if (ImGui::IsKeyPressed(ImGuiKey_E, false)) m = GizmoMode::Rotate;
        if (ImGui::IsKeyPressed(ImGuiKey_R, false)) m = GizmoMode::Scale;
        if (m != gizmoMode_) {
            gizmo_end_drag(true);
            gizmoMode_ = m;
        }
    }

    const Entity sel = selected();
    Transform* tr = sel.is_null() ? nullptr : w.get<Transform>(sel);
    if (!editing || gizmoMode_ == GizmoMode::Select || !tr || r.target_width() <= 0) {
        gizmo_end_drag(false);
        return false;
    }
    if (d.active && (d.id != w.id_of(sel) || d.mode != gizmoMode_)) gizmo_end_drag(false);

    const PickBounds b = bounds_of(sel);
    const Vec3 pivotW = w.world_position(sel);
    Vec2 anchor{};
    if (b.screenSpace) {
        const Vec2 o = pick_origin(w, sel, b, Vec2{float(r.target_width()), float(r.target_height())});
        anchor = {o.x - pivotW.x, o.y - pivotW.y};
    }
    const bool threeD = !b.screenSpace && !primary_is_ortho();
    const GizmoSpace space = make_space(r, imgMin, size, b.screenSpace, threeD, anchor);

    GizmoView view;
    view.project = [&space](Vec3 p) { return space.project(p); };
    view.threeD = threeD;
    GizmoFrame frame;
    frame.pivot = pivotW;
    const Mat4 wm = w.world_matrix(sel);
    for (int i = 0; i < 3; ++i) {
        const Vec3 a = wm.transform_dir(unit_axis(i));
        frame.local[i] = length(a) > 1e-6f ? normalize(a) : unit_axis(i);
    }
    gizmoShapes_ = gizmo_layout(gizmoMode_, view, frame);
    for (const GizmoShape& s : gizmoShapes_) at_track_at("gizmo:" + gizmo_handle_name(s.handle), gizmo_grab_point(s), true);

    const Vec2 mouse{io.MousePos.x, io.MousePos.y};
    if (!d.active && hovered) gizmoHover_ = gizmo_hit(gizmoShapes_, mouse, kHitPx);

    bool tookClick = false;
    if (!d.active && gizmoHover_ && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
        tookClick = true;
        d = GizmoDrag{};
        d.active = true;
        d.handle = gizmoHover_;
        d.mode = gizmoMode_;
        d.id = w.id_of(sel);
        d.key = "gizmo:" + d.id + ":" + gizmo_mode_name(gizmoMode_) + ":" + std::to_string(uiFrame_);
        d.mouseStart = mouse;
        d.start = *tr;
        d.pivot = pivotW;
        for (int i = 0; i < 3; ++i) d.local[i] = frame.local[i];
        const Entity par = w.parent(sel);
        d.hasParent = !par.is_null();
        d.parentWorld = d.hasParent ? w.world_matrix(par) : Mat4::identity();
        d.last = gizmoMode_ == GizmoMode::Move ? tr->position : gizmoMode_ == GizmoMode::Rotate ? tr->rotation : tr->scale;
        d.redoBefore = redo_;
        d.dirtyBefore = dirty_;
        if (d.handle.kind == GizmoKind::MovePlane) d.planeStart = space.on_plane(mouse, pivotW).value_or(pivotW);
        if (d.handle.kind == GizmoKind::RotateAxis) {
            const int i = d.handle.axis;
            d.angle.start(mouse_angle_deg(space.project(pivotW), mouse));
            d.sign = rotation_sign(view.project, pivotW, frame.local[(i + 1) % 3], frame.local[(i + 2) % 3]);
        }
    }

    if (d.active && !tookClick) {
        if (!io.MouseDown[0]) {
            gizmo_end_drag(false);
        } else if (ImGui::IsKeyPressed(ImGuiKey_Escape, false)) {
            gizmo_end_drag(true);
        } else {
            const bool snap = io.KeyCtrl;
            Vec3 value = d.last;
            const char* field = "position";
            const Vec2 p0 = space.project(d.pivot);
            if (d.mode == GizmoMode::Move) {
                Vec3 world = d.pivot;
                if (d.handle.kind == GizmoKind::MoveAxis) {
                    const Vec3 axis = unit_axis(d.handle.axis);
                    world = d.pivot + axis * axis_drag_distance(view.project, d.pivot, axis, d.mouseStart, mouse);
                } else if (auto now = space.on_plane(mouse, d.pivot)) {
                    world = d.pivot + (*now - d.planeStart);
                }
                if (snap) world = snap_move(d.pivot, world, threeD ? 0.25f : 1.0f);
                value = d.hasParent ? world_to_local_position(d.parentWorld, world) : world;
            } else if (d.mode == GizmoMode::Rotate) {
                field = "rotation";
                const float turn = d.sign * d.angle.update(mouse_angle_deg(p0, mouse));
                const int i = d.handle.axis;
                // Z is the roll itself: snap the value. Around x and y the euler value is not the turn, so snap the turn.
                value = rotate_local_euler(d.start.rotation, i, i == 2 ? turn : (snap ? snap_to(turn, 15.0f) : turn));
                if (snap && i == 2) value.z = snap_to(value.z, 15.0f);
            } else {
                field = "scale";
                const float step = snap ? 0.1f : 0.0f;
                value = d.start.scale;
                if (d.handle.kind == GizmoKind::ScaleAll) {
                    const float f = scale_uniform_factor(d.mouseStart, mouse, 80.0f);
                    value.x = scale_apply(value.x, f, step);
                    value.y = scale_apply(value.y, f, step);
                    if (threeD) value.z = scale_apply(value.z, f, step);
                } else {
                    const int i = d.handle.axis;
                    const Vec2 s = space.project(d.pivot + d.local[i] * 1.0f) ;
                    Vec2 dir{s.x - p0.x, s.y - p0.y};
                    const float l = std::sqrt(dir.x * dir.x + dir.y * dir.y);
                    if (l > 1e-6f) {
                        dir = {dir.x / l, dir.y / l};
                        (&value.x)[i] = scale_apply((&d.start.scale.x)[i], scale_axis_factor(p0, dir, d.mouseStart, mouse), step);
                    }
                }
            }
            value = {round4(value.x), round4(value.y), round4(value.z)};
            if (value.x != d.last.x || value.y != d.last.y || value.z != d.last.z) {
                if (lastEditKey_ == d.key) lastEditTime_ = time_;  // one drag, one undo step, however still the mouse is
                std::string err;
                CommandResult res = edit_command(d.key, "scene.set_component",
                                                 field_edit_args(d.id, "Transform", field, Json::array({value.x, value.y, value.z})), &err);
                if (lastEditKey_ == d.key) lastEditTime_ = time_;
                if (!res.ok) {
                    notify("Could not change " + std::string(field) + ": " + err, 2);
                    d.active = false;
                } else {
                    d.last = value;
                    d.wrote = true;
                }
            }
        }
    }
    return tookClick;
}

void Editor::gizmo_draw(ImDrawList* dl) {
    const GizmoDrag& d = gizmoDrag_;
    const GizmoHandle live = d.active ? d.handle : gizmoHover_;
    auto im = [](Vec2 p) { return ImVec2(p.x, p.y); };
    for (const GizmoShape& s : gizmoShapes_) {
        const bool bright = s.handle == live;
        const ImU32 col = axis_color(s.handle.axis, bright);
        const float thick = bright ? 4.0f : 3.0f;
        switch (s.type) {
            case GizmoShape::Type::Arm: {
                dl->AddLine(im(s.from), im(s.to), IM_COL32(0, 0, 0, 120), thick + 2.0f);
                dl->AddLine(im(s.from), im(s.to), col, thick);
                if (s.tipBox) {
                    dl->AddRectFilled(ImVec2(s.to.x - s.half, s.to.y - s.half), ImVec2(s.to.x + s.half, s.to.y + s.half), col);
                    dl->AddRect(ImVec2(s.to.x - s.half, s.to.y - s.half), ImVec2(s.to.x + s.half, s.to.y + s.half), IM_COL32(0, 0, 0, 200));
                } else {
                    const Vec2 n{-s.dir.y, s.dir.x};  // an arrow head at the tip
                    const ImVec2 tip(s.to.x + s.dir.x * 12, s.to.y + s.dir.y * 12);
                    dl->AddTriangleFilled(tip, ImVec2(s.to.x + n.x * 6, s.to.y + n.y * 6), ImVec2(s.to.x - n.x * 6, s.to.y - n.y * 6), col);
                }
                break;
            }
            case GizmoShape::Type::Centre: {
                const ImVec2 a(s.centre.x - s.half, s.centre.y - s.half), b(s.centre.x + s.half, s.centre.y + s.half);
                dl->AddRectFilled(a, b, bright ? IM_COL32(255, 235, 120, 200) : IM_COL32(235, 235, 235, 110));
                dl->AddRect(a, b, bright ? IM_COL32(255, 235, 120, 255) : IM_COL32(235, 235, 235, 255), 0, 0, 2.0f);
                break;
            }
            case GizmoShape::Type::Ring: {
                std::vector<ImVec2> pts;
                for (const Vec2& p : s.ring) pts.push_back(im(p));
                dl->AddPolyline(pts.data(), int(pts.size()), IM_COL32(0, 0, 0, 190), ImDrawFlags_Closed, thick + 3.0f);
                dl->AddPolyline(pts.data(), int(pts.size()), col, ImDrawFlags_Closed, thick);
                break;
            }
        }
    }
}

}  // namespace fa::editor
