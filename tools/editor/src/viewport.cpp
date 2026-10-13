// Viewport panel: shows the engine's game target, selection overlay, 2D picking and drag-to-move.
#include <algorithm>
#include <cmath>

#include "editor_internal.h"
#include "fa/scene/tilemap.h"
#include "ui_backend.h"

namespace fa::editor {

Vec2 Editor::image_size_of(const std::string& path) {
    auto it = imageSizes_.find(path);
    if (it != imageSizes_.end()) return it->second;
    Vec2 sz{32, 32};
    auto img = load_image(path);
    if (img && !img->empty()) sz = Vec2{float(img->width), float(img->height)};
    imageSizes_[path] = sz;
    return sz;
}

bool Editor::primary_is_ortho() {
    bool ortho = true;
    if (!engine_) return true;
    world().each<Camera>([&](Entity, Camera& c) {
        if (c.primary) ortho = c.projection == Projection::Orthographic;
    });
    return ortho;
}

PickBounds Editor::bounds_of(Entity e) {
    PickBounds b;
    World& w = world();
    b.valid = true;
    if (const Sprite* s = w.get<Sprite>(e)) {
        Vec2 size = s->size;
        if (size.x <= 0 || size.y <= 0) {
            if (s->region.w > 0 && s->region.h > 0) size = Vec2{s->region.w, s->region.h};
            else if (!s->texture.empty()) size = image_size_of(s->texture);
            else size = Vec2{32, 32};
        }
        b.half = size * 0.5f;
        b.center = Vec2{(0.5f - s->pivot.x) * size.x, (0.5f - s->pivot.y) * size.y};
        b.layer = s->layer;
        b.screenSpace = s->space == RenderSpace::Screen;
    } else if (const Shape2D* sh = w.get<Shape2D>(e)) {
        Vec2 size = sh->size;
        if (sh->shape == ShapeType::Circle) {
            b.half = Vec2{size.x * 0.5f, size.x * 0.5f};
        } else if (sh->shape == ShapeType::Line) {
            b.center = size * 0.5f;
            b.half = Vec2{std::max(std::fabs(size.x) * 0.5f, sh->thickness), std::max(std::fabs(size.y) * 0.5f, sh->thickness)};
        } else {
            b.half = Vec2{std::fabs(size.x) * 0.5f, std::fabs(size.y) * 0.5f};
        }
        b.layer = sh->layer;
        b.screenSpace = sh->space == RenderSpace::Screen;
    } else if (const Text* t = w.get<Text>(e)) {
        float tw = t->maxWidth > 0 ? t->maxWidth : float(t->text.size()) * t->fontSize * 0.55f;
        float th = t->fontSize * 1.2f;
        b.half = Vec2{tw * 0.5f, th * 0.5f};
        b.center = Vec2{(0.5f - t->pivot.x) * tw, (0.5f - t->pivot.y) * th};
        b.layer = t->layer;
        b.screenSpace = t->space == RenderSpace::Screen;
    } else if (const Tilemap* tm = w.get<Tilemap>(e)) {
        // Same size the renderer draws and physics collides with; the entity origin is the map's TOP-LEFT corner (+Y up).
        const TilemapSize size = tilemap_size(*tm);
        b.half = Vec2{size.width * tm->tileSize.x * 0.5f, size.height * tm->tileSize.y * 0.5f};
        b.center = Vec2{b.half.x, -b.half.y};
        b.layer = tm->layer;
        if (b.half.x <= 0 || b.half.y <= 0) b.half = Vec2{16, 16};
    } else if (const Collider2D* c = w.get<Collider2D>(e)) {
        b.center = c->offset;
        b.half = c->shape == ColliderShape::Circle ? Vec2{c->radius, c->radius} : c->size * 0.5f;
        b.layer = -1000;
    } else {
        b.half = Vec2{12, 12};
        b.layer = -2000;
    }
    return b;
}

namespace {
bool ray_box(Vec3 o, Vec3 d, Vec3 lo, Vec3 hi, float& tOut) {
    float t0 = 0, t1 = 1e30f;
    for (int i = 0; i < 3; ++i) {
        const float oi = (&o.x)[i], di = (&d.x)[i], l = (&lo.x)[i], h = (&hi.x)[i];
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

Entity Editor::pick_at(Vec2 design) {
    if (!engine_ || !engine_->renderer()) return kNullEntity;
    Renderer* r = engine_->renderer();
    World& w = world();
    auto all = w.entities();
    if (!primary_is_ortho()) {
        Vec3 o, d;
        r->screen_ray(design, o, d);
        Entity best = kNullEntity;
        float bestT = 1e30f;
        for (Entity e : all) {
            if (!w.active_in_hierarchy(e) || !w.has<MeshRenderer>(e)) continue;
            Mat4 inv = w.world_matrix(e).inverse();
            Vec3 lo_ = inv.transform_point(o), ld = inv.transform_dir(d);
            float t;
            if (ray_box(lo_, ld, Vec3{-0.55f, -0.55f, -0.55f}, Vec3{0.55f, 0.55f, 0.55f}, t) && t < bestT) {
                bestT = t;
                best = e;
            }
        }
        return best;
    }
    const Vec3 wp = r->screen_to_world(design, 0.0f);
    Entity best = kNullEntity;
    std::int64_t bestKey = -(std::int64_t(1) << 40);  // int64: `long` is 32-bit on Windows
    std::int64_t order = 0;
    for (Entity e : all) {
        ++order;
        if (!w.active_in_hierarchy(e)) continue;
        PickBounds b = bounds_of(e);
        if (!b.valid) continue;
        Vec2 local;
        if (b.screenSpace) {
            const Vec3 p = w.world_position(e);
            local = Vec2{design.x - p.x, design.y - p.y};
        } else {
            Vec3 lp = w.world_matrix(e).inverse().transform_point(Vec3{wp.x, wp.y, 0});
            local = Vec2{lp.x, lp.y};
        }
        if (std::fabs(local.x - b.center.x) > b.half.x || std::fabs(local.y - b.center.y) > b.half.y) continue;
        if (b.layer > -500 && b.layer <= -500) continue;
        std::int64_t key = std::int64_t(b.layer) * 1000000 + order + (b.screenSpace ? std::int64_t(100000000000) : 0);
        if (key > bestKey) {
            bestKey = key;
            best = e;
        }
    }
    return best;
}

void Editor::draw_viewport() {
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    const bool open = ImGui::Begin("Viewport", nullptr, ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoScrollWithMouse);
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
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImGuiIO& io = ImGui::GetIO();

    auto design_of = [&](ImVec2 m) { return Vec2{(m.x - imgMin.x) / sz.x * tw, (m.y - imgMin.y) / sz.y * th}; };
    auto to_vp = [&](Vec2 d) { return ImVec2(imgMin.x + d.x / tw * sz.x, imgMin.y + d.y / th * sz.y); };
    World& w = world();
    auto project = [&](Entity e, Vec3 local, bool screenSpace) {
        if (screenSpace) {
            Vec3 p = w.world_position(e);
            return to_vp(Vec2{p.x + local.x, p.y + local.y});
        }
        Vec3 wp = w.world_matrix(e).transform_point(local);
        return to_vp(r->world_to_screen(wp));
    };

    // ---- interaction (edit / paused only; while playing, events go to the game)
    if (play_ != PlayState::Playing) {
        if (hovered && ImGui::IsMouseClicked(ImGuiMouseButton_Left)) {
            Entity hit = pick_at(design_of(io.MousePos));
            select(hit);
            if (!hit.is_null() && primary_is_ortho() && !bounds_of(hit).screenSpace) {
                dragging_ = true;
                dragStartWorld_ = r->screen_to_world(design_of(io.MousePos), 0.0f);
                dragStartPos_ = w.world_position(hit);
            }
        }
        if (dragging_) {
            Entity sel = selected();
            if (!ImGui::IsMouseDown(ImGuiMouseButton_Left) || sel.is_null()) {
                dragging_ = false;
            } else if (ImGui::IsMouseDragging(ImGuiMouseButton_Left, 3.0f)) {
                Vec3 cur = r->screen_to_world(design_of(io.MousePos), 0.0f);
                Vec3 np = dragStartPos_ + Vec3{cur.x - dragStartWorld_.x, cur.y - dragStartWorld_.y, 0};
                if (io.KeyCtrl) { np.x = std::round(np.x / 8) * 8; np.y = std::round(np.y / 8) * 8; }
                begin_edit("drag:" + selectedId_);
                w.set_world_position(sel, np);
            }
        }
        if (hovered) ImGui::SetItemTooltip("Click: select   Drag: move (Ctrl snaps to 8)");
    } else {
        dragging_ = false;
        if (vpFocused_) dl->AddRect(imgMin, ImVec2(imgMin.x + sz.x, imgMin.y + sz.y), IM_COL32(80, 220, 255, 255), 0, 0, 2.0f);
    }

    // ---- overlays
    dl->PushClipRect(imgMin, ImVec2(imgMin.x + sz.x, imgMin.y + sz.y), true);
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
    Entity sel = selected();
    if (showOverlay_ && !sel.is_null()) {
        const ImU32 col = IM_COL32(255, 205, 60, 255);
        if (w.has<MeshRenderer>(sel) && !primary_is_ortho()) {
            ImVec2 c8[8];
            for (int i = 0; i < 8; ++i) c8[i] = project(sel, Vec3{(i & 1) ? .5f : -.5f, (i & 2) ? .5f : -.5f, (i & 4) ? .5f : -.5f}, false);
            static const int edges[12][2] = {{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {0, 4}, {1, 5}, {2, 6}, {3, 7}};
            for (auto& ed : edges) dl->AddLine(c8[ed[0]], c8[ed[1]], col, 2.0f);
        } else {
            PickBounds b = bounds_of(sel);
            ImVec2 p[4] = {project(sel, Vec3{b.center.x - b.half.x, b.center.y - b.half.y, 0}, b.screenSpace),
                           project(sel, Vec3{b.center.x + b.half.x, b.center.y - b.half.y, 0}, b.screenSpace),
                           project(sel, Vec3{b.center.x + b.half.x, b.center.y + b.half.y, 0}, b.screenSpace),
                           project(sel, Vec3{b.center.x - b.half.x, b.center.y + b.half.y, 0}, b.screenSpace)};
            dl->AddPolyline(p, 4, col, ImDrawFlags_Closed, 2.0f);
            for (auto& q : p) dl->AddRectFilled(ImVec2(q.x - 3, q.y - 3), ImVec2(q.x + 3, q.y + 3), col);
        }
        ImVec2 o = project(sel, Vec3{0, 0, 0}, w.has<Sprite>(sel) && w.get<Sprite>(sel)->space == RenderSpace::Screen);
        dl->AddCircleFilled(o, 4.0f, IM_COL32(255, 80, 60, 255));
        dl->AddCircle(o, 4.5f, IM_COL32(0, 0, 0, 200));
    }
    dl->PopClipRect();

    // ---- status chip
    char info[160];
    std::snprintf(info, sizeof info, "%s   %dx%d   %.0f%%", play_ == PlayState::Edit ? "EDIT" : play_ == PlayState::Playing ? "PLAYING" : "PAUSED",
                  int(tw), int(th), scale * 100.0f);
    const ImVec2 ts = ImGui::CalcTextSize(info);
    const ImVec2 p0(imgMin.x + 6, imgMin.y + 6);
    dl->AddRectFilled(p0, ImVec2(p0.x + ts.x + 12, p0.y + ts.y + 6), IM_COL32(0, 0, 0, 150), 3.0f);
    dl->AddText(ImVec2(p0.x + 6, p0.y + 3), IM_COL32(230, 235, 245, 255), info);
    ImGui::End();
}

}  // namespace fa::editor
