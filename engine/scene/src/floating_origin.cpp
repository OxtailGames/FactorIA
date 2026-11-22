// World::rebase and the arithmetic of the floating origin (fa/scene/floating_origin.h, docs/BIG_WORLDS_STREAMING.md "Floating origin").
#include "fa/scene/floating_origin.h"

#include <cmath>
#include <format>

#include "fa/scene/particle_store.h"
#include "fa/scene/world.h"

namespace fa {

bool follows_floating_origin(const World& world, Entity e) {
    if (world.has<Panel>(e) || world.has<Button>(e) || world.has<Toggle>(e) || world.has<Slider>(e) ||
        world.has<TextField>(e) || world.has<ScrollList>(e) || world.has<TouchStick>(e) || world.has<TouchButton>(e) ||
        world.has<Captions>(e) || world.has<Video>(e) || world.has<Chart>(e) || world.has<CameraView>(e))
        return false;
    if (const Sprite* s = world.get<Sprite>(e))
        if (s->space == RenderSpace::Screen) return false;
    if (const Shape2D* s = world.get<Shape2D>(e))
        if (s->space == RenderSpace::Screen) return false;
    if (const Text* s = world.get<Text>(e))
        if (s->space == RenderSpace::Screen) return false;
    if (const ParticleEmitter* s = world.get<ParticleEmitter>(e))
        if (particle_screen_space(*s)) return false;
    return true;
}

Vec3 snap_to_step(Vec3 v, double step) {
    auto snap = [step](float x) { return float(std::round(double(x) / step) * step); };
    return {snap(v.x), snap(v.y), snap(v.z)};
}

Vec3 auto_rebase_offset(Vec3 anchorLocal, double threshold, double step) {
    const bool far = std::fabs(double(anchorLocal.x)) > threshold || std::fabs(double(anchorLocal.y)) > threshold ||
                     std::fabs(double(anchorLocal.z)) > threshold;
    if (!far) return {};
    return snap_to_step(anchorLocal, step);
}

Result<void> check_rebase_offset(const DVec3& offset, double step, const std::string& pointer) {
    const double v[3] = {offset.x, offset.y, offset.z};
    const char* axis[3] = {"x", "y", "z"};
    for (int i = 0; i < 3; ++i) {
        if (!std::isfinite(v[i]))
            return Error{std::format("{}: the {} component is not a finite number.", pointer, axis[i]),
                         "Give three finite numbers, in metres."};
        const double steps = v[i] / step;
        if (steps != std::floor(steps))
            return Error{
                std::format(
                    "{}: {} on {} is not a whole multiple of the step {} (world.floatingOrigin.step). A shift by "
                    "anything else would round every position it moves and make the origin inexact.",
                    pointer, v[i], axis[i], step),
                std::format("Use {} (the nearest multiple), or change the step in factoria.json.",
                            std::round(steps) * step)};
        if (std::fabs(steps) > kMaxRebaseSteps)
            return Error{
                std::format(
                    "{}: {} on {} is {} steps of {}: a float cannot hold more than 16777216 steps exactly, so the "
                    "shift would lose precision.",
                    pointer, v[i], axis[i], std::fabs(steps), step),
                "Shift in several smaller rebases, or raise world.floatingOrigin.step."};
    }
    return {};
}

namespace {

// [x, y, z] arrays of a Json (LightProbeGroup.points): every one that has three numbers moves; anything else stays.
void shift_points(Json& points, Vec3 offset) {
    if (!points.is_array()) return;
    for (Json& p : points) {
        if (!p.is_array() || p.size() < 3 || !p[0].is_number() || !p[1].is_number() || !p[2].is_number()) continue;
        p[0] = p[0].get<double>() - double(offset.x);
        p[1] = p[1].get<double>() - double(offset.y);
        p[2] = p[2].get<double>() - double(offset.z);
    }
}

void shift_joint2d(Joint2D& j, Vec3 offset) {
    if (j.connected.is_null()) j.connectedAnchor -= Vec2{offset.x, offset.y};
}
void shift_joint3d(Joint3D& j, Vec3 offset) {
    if (j.connected.is_null()) j.connectedAnchor -= offset;
}

}  // namespace

Vec3 root_shift(const World& world, Entity root, Vec3 offset) {
    // A Parallax layer is drawn at position + camera * (1 - factor): it must move by O * factor so that (drawn - camera),
    // what the player sees, is the same after the camera moved by -O. z has no parallax.
    if (const Parallax* p = world.get<Parallax>(root))
        return {offset.x * p->factor.x, offset.y * p->factor.y, offset.z};
    return offset;
}

void place_loaded_entities(World& world, const std::vector<Entity>& entities, Vec3 delta, bool parented) {
    if (parented || (delta.x == 0.0f && delta.y == 0.0f && delta.z == 0.0f)) return;
    const Vec3 offset = -delta;  // the same arithmetic as World::rebase(offset): positions -= offset
    for (Entity e : entities) {
        if (!world.alive(e)) continue;
        if (world.parent(e).is_null() && follows_floating_origin(world, e)) {
            const Vec3 d = root_shift(world, e, offset);
            if (Transform* t = world.get<Transform>(e)) t->position -= d;
            if (Parallax* p = world.get<Parallax>(e))
                p->offset -= Vec2{offset.x * (1.0f - p->factor.x), offset.y * (1.0f - p->factor.y)};
        }
        if (Joint2D* j = world.get<Joint2D>(e)) shift_joint2d(*j, offset);
        if (Joint3D* j = world.get<Joint3D>(e)) shift_joint3d(*j, offset);
        if (NavLink3D* l = world.get<NavLink3D>(e)) l->end -= offset;
        if (LightProbeGroup* g = world.get<LightProbeGroup>(e)) shift_points(g->points, offset);
    }
}

void World::rebase(Vec3 offset) {
    if (offset.x == 0.0f && offset.y == 0.0f && offset.z == 0.0f) return;
    // 1. Every root entity that is a position of the world; the hierarchy carries the children (get<> invalidates the matrices).
    InterpState& ip = interp_;
    for (Entity r : roots()) {
        if (!follows_floating_origin(*this, r)) continue;
        const Vec3 d = root_shift(*this, r, offset);
        if (Transform* t = get<Transform>(r)) t->position -= d;
        if (r.index < ip.slots.size() && ip.slots[r.index] != 0) {
            InterpRecord& rec = ip.records[ip.slots[r.index] - 1];
            if (rec.bits == r.bits()) {  // the blend between the last two steps moves with the entity
                rec.prev.position -= d;
                rec.last.position -= d;
                rec.pose.position -= d;
            }
        }
        // The drawn shift of a parallax layer was computed for the old camera position: keep it consistent until the
        // renderer writes the next one (camera - O, so offset - O * (1 - factor)).
        if (Parallax* p = get<Parallax>(r))
            p->offset -= Vec2{offset.x * (1.0f - p->factor.x), offset.y * (1.0f - p->factor.y)};
    }
    // 2. World-space points components hold (they are not relative to an entity).
    each<Joint2D>([&](Entity, Joint2D& j) { shift_joint2d(j, offset); });
    each<Joint3D>([&](Entity, Joint3D& j) { shift_joint3d(j, offset); });
    each<NavLink3D>([&](Entity, NavLink3D& l) { l.end -= offset; });
    each<LightProbeGroup>([&](Entity, LightProbeGroup& g) { shift_points(g.points, offset); });
    // 3. What the world keeps between frames: particles, queued feel actions.
    particles_->shift(*this, offset);
    feel_.shift(offset);
    // 4. The origin: a sum of multiples of the step, exact in double.
    origin_ += to_dvec3(offset);
    ++rebaseCount_;
    const DVec3 shifted = to_dvec3(offset);
    for (const auto& [id, cb] : originObservers_) cb(shifted);
}

}  // namespace fa
