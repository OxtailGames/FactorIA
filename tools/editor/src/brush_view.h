// The camera of the viewport image and the ground under the mouse, shared by the viewport brush tools (terrain_tool.cpp,
// foliage_tool.cpp).
#pragma once

#include "fa/core/math.h"
#include "fa/render/renderer.h"
#include "fa/scene/world.h"
#include "imgui.h"

namespace fa::editor {

// Maps between the viewport image on screen (`imgMin`, `size` in ImGui pixels) and the renderer's design pixels.
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

// The ground of the Terrain `e` under the mouse (false: the ray misses it). A number of steps that depends on the terrain's own
// cells, never on the time (terrain_tool.cpp).
bool terrain_under_mouse(const World& w, Entity e, const ViewMap& map, ImVec2 mouse, Vec3& hit);

}  // namespace fa::editor
