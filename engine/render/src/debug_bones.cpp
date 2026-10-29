// debug.bones(): the Bone2D entities drawn as kites (see fa/render/renderer.h, debug_draw_bones).
#include <algorithm>

#include "fa/render/renderer.h"
#include "fa/scene/bones2d.h"

namespace fa {

namespace {
int draw_bone(DebugDraw& draw, const World& world, Entity bone, Color color) {
    const BoneSegment seg = bone_world_segment(world, bone);
    const std::array<Vec2, 4> kite = bone_kite(seg);
    for (int i = 0; i < 4; ++i) {
        const Vec2 a = kite[std::size_t(i)], b = kite[std::size_t((i + 1) % 4)];
        draw.line({a.x, a.y, 0.0f}, {b.x, b.y, 0.0f}, color, 1.0f);
    }
    const float len = length(seg.tip - seg.origin);
    draw.circle(seg.origin, std::clamp(len * 0.08f, 1.5f, 6.0f), color, true);
    return 1;
}

int draw_subtree(DebugDraw& draw, const World& world, Entity e, Color color) {
    int n = world.has<Bone2D>(e) ? draw_bone(draw, world, e, color) : 0;
    for (Entity c : world.children(e)) n += draw_subtree(draw, world, c, color);
    return n;
}
}  // namespace

int debug_draw_bones(DebugDraw& draw, const World& world, Entity root, Color color) {
    if (!root.is_null()) return world.alive(root) ? draw_subtree(draw, world, root, color) : 0;
    int n = 0;
    for (Entity e : world.entities_with(&World::type_of<Bone2D>()))
        if (world.alive(e)) n += draw_bone(draw, world, e, color);
    return n;
}

}  // namespace fa
