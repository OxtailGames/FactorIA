// Viewport panel: shows the engine's game target, the selection outline, picking (a click = point at something for the AI) and the
// transform gizmos (viewport_gizmo.cpp).
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/scene/bones2d.h"
#include "fa/scene/camera_mask.h"
#include "fa/scene/tilemap.h"
#include "ui_backend.h"

namespace fa::editor {

// An ImGui texture for a project image (cached; nullptr when the file cannot be loaded). Used for image thumbnails.
const TextureEntry* Editor::texture_for(const std::string& path) {
    auto it = textures_.find(path);
    if (it != textures_.end()) return it->second.failed ? nullptr : &it->second;
    TextureEntry t;
    auto img = load_image(path);
    if (!img || img->empty() || img->width > 8192 || img->height > 8192 ||
        !ui::make_texture(img->width, img->height, img->rgba.data(), t.image, t.view)) {
        t.failed = true;
    } else {
        t.w = img->width;
        t.h = img->height;
    }
    auto& slot = textures_[path] = t;
    return slot.failed ? nullptr : &slot;
}

Vec2 Editor::image_size_of(const std::string& path) {
    // 32 x 32 is what the renderer shows for a missing or unreadable texture. Re-read when the file changes on disk.
    const std::int64_t mtime = fs::modified_time(path);
    auto it = imageSizes_.find(path);
    if (it != imageSizes_.end() && it->second.mtime == mtime) return it->second.size;
    ImageSizeEntry entry;
    entry.mtime = mtime;
    auto img = load_image(path);
    if (img && !img->empty()) entry.size = Vec2{float(img->width), float(img->height)};
    imageSizes_[path] = entry;
    return entry.size;
}

bool Editor::primary_is_ortho() {
    bool ortho = true;
    if (!engine_) return true;
    world().each<Camera>([&](Entity, Camera& c) {
        if (c.primary && c.renderTarget.empty()) ortho = c.projection == Projection::Orthographic;
    });
    return ortho;
}

// What the engine's bounds code cannot know by itself: texture files and the renderer's text layout. With these the
// editor measures exactly what `entity.bounds()` measures in a script.
VisualMeasure Editor::visual_measure() {
    VisualMeasure m;
    m.textureSize = [this](const std::string& path) { return image_size_of(path); };
    m.textSize = [this](const Text& t) {
        Renderer* r = engine_ ? engine_->renderer() : nullptr;
        if (r && r->initialized()) return r->measure_text(t);
        return approx_text_size(t, 1.0f);
    };
    return m;
}

PickBounds Editor::bounds_of(Entity e) { return pick_bounds(world(), e, visual_measure()); }

namespace {
bool ray_box(Vec3 o, Vec3 d, Vec3 lo, Vec3 hi, float& tOut) {
    float t0 = 0, t1 = 1e30f;
    for (int i = 0; i < 3; ++i) {
        const float oi = axis_value(o, i), di = axis_value(d, i), l = axis_value(lo, i), h = axis_value(hi, i);
        if (std::fabs(di) < 1e-8f) {
            if (oi < l || oi > h) return false;
        } else {
            float a = (l - oi) / di, b = (h - oi) / di;
            if (a > b) std::swap(a, b);
            t0 = std::max(t0, a);
            t1 = std::min(t1, b);
            if (t0 > t1) return false;
        }
    }
    tOut = t0;
    return true;
}

}  // namespace

// The box of a MeshRenderer's mesh in its own space, for the selection outline: the real bounds of a procedural mesh, the
// unit cube (+-0.5) for the built-in shapes and models, which the editor treats as one unit box.
void Editor::mesh_local_box(Entity e, Vec3& lo, Vec3& hi) {
    lo = Vec3{-0.5f, -0.5f, -0.5f};
    hi = Vec3{0.5f, 0.5f, 0.5f};
    const MeshRenderer* mr = world().get<MeshRenderer>(e);
    if (!mr || !MeshStore::is_id(mr->mesh)) return;
    if (const MeshStore::Entry* m = world().meshes().find(mr->mesh)) {
        lo = m->data.bmin;
        hi = m->data.bmax;
    }
}

Entity Editor::pick_at(Vec2 design) {
    if (!engine_ || !engine_->renderer()) return kNullEntity;
    Renderer* r = engine_->renderer();
    World& w = world();
    auto all = w.entities();
    // The viewport shows the game's camera, so a click selects what that camera draws (Camera.showTags / hideTags): an entity it
    // hides is still in the Hierarchy. Screen-space items belong to the screen and are always pickable.
    const CameraMask mask = CameraMask::of(w, r->camera_at(design));
    if (!primary_is_ortho()) {
        Vec3 o, d;
        r->screen_ray(design, o, d);
        Entity best = kNullEntity;
        float bestT = 1e30f;
        for (Entity e : all) {
            if (!w.active_in_hierarchy(e) || !w.has<MeshRenderer>(e) || !mask.draws(w, e)) continue;
            Mat4 inv = w.world_matrix(e).inverse();
            Vec3 lo_ = inv.transform_point(o), ld = inv.transform_dir(d);
            float t;
            const MeshRenderer* mr = w.get<MeshRenderer>(e);
            if (MeshStore::is_id(mr->mesh) && w.meshes().find(mr->mesh)) {
                // A procedural mesh: its real triangles (the box first, as a quick reject), not a unit cube.
                const MeshStore::Entry* m = w.meshes().find(mr->mesh);
                const Vec3 pad{1e-4f, 1e-4f, 1e-4f};
                if (!ray_box(lo_, ld, m->data.bmin - pad, m->data.bmax + pad, t)) continue;
                const auto g = w.meshes().geometry(mr->mesh);
                if (g && ray_hits_mesh(*g, lo_, ld, t) && t < bestT) {
                    bestT = t;
                    best = e;
                }
                continue;
            }
            if (ray_box(lo_, ld, Vec3{-0.55f, -0.55f, -0.55f}, Vec3{0.55f, 0.55f, 0.55f}, t) && t < bestT) {
                bestT = t;
                best = e;
            }
        }
        return best;
    }
    const Vec3 wp = r->screen_to_world(design, 0.0f);
    const Vec2 designSize{float(r->target_width()), float(r->target_height())};
    const VisualMeasure measure = visual_measure();
    Entity best = kNullEntity;
    std::int64_t bestKey = -(std::int64_t(1) << 40);  // int64: `long` is 32-bit on Windows
    std::int64_t order = 0;
    for (Entity e : all) {
        ++order;
        if (!w.active_in_hierarchy(e)) continue;
        const PickBounds b = pick_bounds(w, e, measure);
        if (!b.valid || (!b.screenSpace && !mask.draws(w, e))) continue;
        int layer = 0;
        // World-space entities are tested at the world point under the cursor, screen-space ones at the design pixel.
        if (!pick_hit(w, e, b, b.screenSpace ? design : Vec2{wp.x, wp.y}, designSize, &layer)) continue;
        // Higher layer wins, then later in the scene; screen-space items (HUD) are drawn over the world, so they win over it.
        const std::int64_t key = std::int64_t(layer) * 1000000 + order + (b.screenSpace ? std::int64_t(100000000000) : 0);
        if (key > bestKey) {
            bestKey = key;
            best = e;
        }
    }
    return best;
}

void Editor::draw_viewport() {
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    // Status goes in the title (the ### id keeps docking/layout stable); an overlay would hide the game's HUD.
    static float lastScale = 1.0f;  // one viewport window; the scale is only known after Begin, so the title is a frame behind
    char title[96] = "Viewport###Viewport";
    if (Renderer* tr = engine_->renderer(); tr && tr->target_width() > 0)
        std::snprintf(title, sizeof title, "Viewport  -  %s  %dx%d  %.0f%%###Viewport",
                      play_ == PlayState::Edit ? "EDIT" : play_ == PlayState::Playing ? "PLAYING" : "PAUSED",
                      int(tr->target_width()), int(tr->target_height()), lastScale * 100.0f);
    if (vpFocusNext_) ImGui::SetNextWindowFocus();
    vpFocusNext_ = false;
    const bool open = ImGui::Begin(title, nullptr, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
    ImGui::PopStyleVar();
    if (!open) {
        vpHovered_ = vpFocused_ = false;
        ImGui::End();
        return;
    }
    vpFocused_ = ImGui::IsWindowFocused(ImGuiFocusedFlags_RootAndChildWindows);
    Renderer* r = engine_->renderer();
    if (!r || r->game_target_view_id() == 0 || r->target_width() <= 0) {
        ImGui::TextDisabled("No render target (graphics disabled).");
        vpHovered_ = false;
        ImGui::End();
        return;
    }
    const float tw = float(r->target_width()), th = float(r->target_height());
    const ImVec2 avail = ImGui::GetContentRegionAvail();
    const float scale = std::max(0.01f, std::min(avail.x / tw, avail.y / th));
    lastScale = scale;
    const ImVec2 sz(std::floor(tw * scale), std::floor(th * scale));
    const ImVec2 start = ImGui::GetCursorScreenPos();
    const ImVec2 imgMin(std::floor(start.x + (avail.x - sz.x) * 0.5f), std::floor(start.y + (avail.y - sz.y) * 0.5f));
    ImGui::SetCursorScreenPos(imgMin);
    // The renderer's offscreen target is stored bottom-up on GL backends; flip so the image is upright.
#if defined(SOKOL_GLCORE) || defined(SOKOL_GLES3)
    ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(r->game_target_view_id(), true))), sz, ImVec2(0, 1), ImVec2(1, 0));
#else
    ImGui::Image(ImTextureRef(ImTextureID(ui::texture_from_view(r->game_target_view_id(), true))), sz);
#endif
    ImGui::SetCursorScreenPos(imgMin);
    ImGui::InvisibleButton("##viewport_hit", sz,
                           ImGuiButtonFlags_MouseButtonLeft | ImGuiButtonFlags_MouseButtonRight | ImGuiButtonFlags_MouseButtonMiddle);
    vpImageMin_ = imgMin;
    vpImageSize_ = sz;
    const bool hovered = ImGui::IsItemHovered();
    vpHovered_ = hovered;
    { const ImVec2 m = ImGui::GetIO().MousePos; viewport_accept_drop(*r, Vec2{(m.x - imgMin.x) / sz.x * tw, (m.y - imgMin.y) / sz.y * th}); }
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImGuiIO& io = ImGui::GetIO();

    auto design_of = [&](ImVec2 m) { return Vec2{(m.x - imgMin.x) / sz.x * tw, (m.y - imgMin.y) / sz.y * th}; };
    auto to_vp = [&](Vec2 d) { return ImVec2(imgMin.x + d.x / tw * sz.x, imgMin.y + d.y / th * sz.y); };
    World& w = world();
    auto project = [&](Entity e, Vec3 local, bool screenSpace) {
        (void)screenSpace;  // only used for colliders, which are world-space
        Vec3 wp = w.world_matrix(e).transform_point(local);
        return to_vp(r->world_to_screen(wp));
    };
    // A point from pick_outlines(): world xy (at the entity's depth) or a design pixel.
    auto outline_pt = [&](Vec2 p, bool screenSpace, float z) {
        return screenSpace ? to_vp(p) : to_vp(r->world_to_screen(Vec3{p.x, p.y, z}));
    };

    // ---- interaction (edit / paused only; while playing, events go to the game). A click on a gizmo handle starts a drag (see
    // viewport_gizmo.cpp); a click anywhere else selects what is under the cursor: the selection is how the user points at
    // something for the AI.
    if (play_ != PlayState::Playing) {
        bool onHandle = false;
        if (bone_tools_active()) {  // a bone tool owns the clicks: no gizmo handles meanwhile
            gizmo_end_drag(false);
            gizmoShapes_.clear();
            gizmoHover_ = {};
            onHandle = bone_tools_frame(*r, imgMin, sz, hovered);
        } else {
            onHandle = gizmo_frame(*r, imgMin, sz, hovered);
        }
        if (hovered && !onHandle && !gizmoDrag_.active && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) select(pick_at(design_of(io.MousePos)));
        if (hovered && gizmoHover_) ImGui::SetItemTooltip("Drag to %s (hold Ctrl to snap, Esc cancels)", gizmo_mode_name(gizmoMode_));
        else if (hovered) ImGui::SetItemTooltip("Click: select (point at something for the AI)\nQ / W / E / R: select only, move, rotate, scale the selection");
    } else {
        gizmo_end_drag(false);
        gizmoShapes_.clear();
        if (vpFocused_) dl->AddRect(imgMin, ImVec2(imgMin.x + sz.x, imgMin.y + sz.y), IM_COL32(80, 220, 255, 255), 0, 0, 2.0f);
    }

    // ---- overlays
    dl->PushClipRect(imgMin, ImVec2(imgMin.x + sz.x, imgMin.y + sz.y), true);
    anim_update_onion(*r);
    anim_draw_onion(dl, *r);
    if (showColliders_) {
        w.each<Collider2D>([&](Entity e, Collider2D& c) {
            if (!w.active_in_hierarchy(e)) return;
            const ImU32 col = c.isTrigger ? IM_COL32(255, 200, 60, 150) : IM_COL32(80, 255, 120, 150);
            if (c.shape == ColliderShape::Circle) {
                ImVec2 a = project(e, Vec3{c.offset.x, c.offset.y, 0}, false);
                ImVec2 b = project(e, Vec3{c.offset.x + c.radius, c.offset.y, 0}, false);
                dl->AddCircle(a, std::max(2.0f, std::hypot(b.x - a.x, b.y - a.y)), col, 28, 1.0f);
            } else {
                const Vec2 h = c.size * 0.5f;
                ImVec2 p[4] = {project(e, Vec3{c.offset.x - h.x, c.offset.y - h.y, 0}, false), project(e, Vec3{c.offset.x + h.x, c.offset.y - h.y, 0}, false),
                               project(e, Vec3{c.offset.x + h.x, c.offset.y + h.y, 0}, false), project(e, Vec3{c.offset.x - h.x, c.offset.y + h.y, 0}, false)};
                dl->AddPolyline(p, 4, col, ImDrawFlags_Closed, 1.0f);
            }
        });
    }
    if (showNav_ && !primary_is_ortho()) {
        // Walkable cells of the NavMesh3D (docs/NAVIGATION.md). While the user drags something the previous cells are kept:
        // the mesh rebakes by itself when the colliders move and that is not wanted on every mouse move.
        if (!(io.MouseDown[0] && play_ != PlayState::Playing)) {
            if (play_ != PlayState::Playing) engine_->physics().sync(w);
            navCells_ = engine_->physics().nav_cells(w, 20000);
            navLinks_ = engine_->physics().nav_links(w);
        }
        for (const NavCell& c : navCells_) {
            const float h = c.size * 0.5f;
            const ImVec2 q[4] = {to_vp(r->world_to_screen(Vec3{c.center.x - h, c.center.y, c.center.z - h})),
                                 to_vp(r->world_to_screen(Vec3{c.center.x + h, c.center.y, c.center.z - h})),
                                 to_vp(r->world_to_screen(Vec3{c.center.x + h, c.center.y, c.center.z + h})),
                                 to_vp(r->world_to_screen(Vec3{c.center.x - h, c.center.y, c.center.z + h}))};
            dl->AddConvexPolyFilled(q, 4, c.blocked ? IM_COL32(255, 70, 60, 90)
                                           : c.moving ? IM_COL32(70, 170, 255, 110) : IM_COL32(60, 220, 120, 70));
        }
        // Off-mesh links (NavLink3D): a line from the start to the end, with an arrowhead at the end of a one-way one;
        // grey when an end is not on walkable ground.
        {
            for (const NavLinkDraw& l : navLinks_) {
                const ImVec2 a = to_vp(r->world_to_screen(l.from)), b = to_vp(r->world_to_screen(l.to));
                const ImU32 col = l.connected ? IM_COL32(255, 220, 70, 230) : IM_COL32(150, 150, 150, 200);
                dl->AddLine(a, b, col, 2.0f);
                dl->AddCircleFilled(a, 4.0f, col);
                dl->AddCircleFilled(b, 4.0f, col);
                if (!l.bidirectional) {
                    const float dx = b.x - a.x, dy = b.y - a.y, len = std::max(std::hypot(dx, dy), 1.0f);
                    const float ux = dx / len, uy = dy / len;
                    dl->AddTriangleFilled(b, ImVec2(b.x - 10 * ux + 5 * uy, b.y - 10 * uy - 5 * ux),
                                          ImVec2(b.x - 10 * ux - 5 * uy, b.y - 10 * uy + 5 * ux), col);
                }
            }
        }
    }
    Entity sel = selected();
    if (showOverlay_ && !sel.is_null()) {
        const ImU32 col = IM_COL32(255, 205, 60, 255);
        if (w.has<MeshRenderer>(sel) && !primary_is_ortho()) {
            ImVec2 c8[8];
            Vec3 lo, hi;
            mesh_local_box(sel, lo, hi);
            for (int i = 0; i < 8; ++i) c8[i] = project(sel, Vec3{(i & 1) ? hi.x : lo.x, (i & 2) ? hi.y : lo.y, (i & 4) ? hi.z : lo.z}, false);
            static const int edges[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
            for (auto& ed : edges) dl->AddLine(c8[ed[0]], c8[ed[1]], col, 2.0f);
        } else {
            // The engine's own footprint of the entity's visuals: one oriented box per visual (rotation and scale included),
            // and for a diamond also its tips. Screen-space (HUD) entities are outlined in design pixels.
            const PickBounds b = bounds_of(sel);
            const Vec2 designSize{tw, th};
            const float z = w.world_position(sel).z;
            for (const PickOutline& o : pick_outlines(w, sel, b, designSize)) {
                ImVec2 p[4], h[4];
                for (int i = 0; i < 4; ++i) {
                    p[i] = outline_pt(o.box[size_t(i)], o.screenSpace, z);
                    h[i] = outline_pt(o.hull[size_t(i)], o.screenSpace, z);
                }
                dl->AddPolyline(p, 4, col, ImDrawFlags_Closed, 2.0f);
                if (o.hasHull) dl->AddPolyline(h, 4, IM_COL32(255, 205, 60, 150), ImDrawFlags_Closed, 1.0f);
                for (auto& q : p) dl->AddRectFilled(ImVec2(q.x - 3, q.y - 3), ImVec2(q.x + 3, q.y + 3), col);
            }
            const Vec2 org = pick_origin(w, sel, b, designSize);
            ImVec2 o = outline_pt(org, b.screenSpace, z);
            dl->AddCircleFilled(o, 4.0f, IM_COL32(255, 80, 60, 255));
            dl->AddCircle(o, 4.5f, IM_COL32(0, 0, 0, 200));
        }
    }
    // Bones (Bone2D) of the selection: the selected entity's own bone and the ones below it, and the bones of its SpriteSkin. A thin
    // kite from each bone's origin to its tip, the selected bone in yellow (View > Bone tools draws and edits them).
    bone_.bonesDrawn = 0;
    if (showOverlay_ && !sel.is_null() && primary_is_ortho()) {  // the 2D view; a 3D camera does not show bones
        std::vector<Entity> bones;
        std::function<void(Entity)> collect = [&](Entity e) {
            if (w.has<Bone2D>(e) && std::find(bones.begin(), bones.end(), e) == bones.end()) bones.push_back(e);
            for (Entity c : w.children(e)) collect(c);
        };
        collect(sel);
        if (const SpriteSkin* skin = w.get<SpriteSkin>(sel))
            for (Entity b : skin_resolve_bones(w, sel, *skin).entities)
                if (!b.is_null() && std::find(bones.begin(), bones.end(), b) == bones.end()) bones.push_back(b);
        const float z = w.world_position(sel).z;
        for (Entity b : bones) {
            const ImU32 col = b == sel ? IM_COL32(255, 205, 60, 255) : IM_COL32(60, 220, 255, 220);
            const std::array<Vec2, 4> kite = bone_kite(bone_world_segment(w, b));
            ImVec2 p[4];
            for (int i = 0; i < 4; ++i) p[i] = outline_pt(kite[size_t(i)], false, z);
            dl->AddPolyline(p, 4, col, ImDrawFlags_Closed, 1.5f);
            dl->AddCircleFilled(p[0], 3.5f, col);
            ++bone_.bonesDrawn;
        }
    }
    bone_tools_draw(dl, *r, imgMin, sz);
    gizmo_draw(dl);
    anim_draw_record_frame(dl, imgMin, sz);
    dl->PopClipRect();

    ImGui::End();
}

}  // namespace fa::editor
