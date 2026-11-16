#include "fa/scene/interpolation.h"

#include <algorithm>

#include "fa/scene/world.h"

namespace fa {

namespace {

bool same(Vec3 a, Vec3 b) { return a.x == b.x && a.y == b.y && a.z == b.z; }
bool same(const Transform& a, const Transform& b) {
    return same(a.position, b.position) && same(a.rotation, b.rotation) && same(a.scale, b.scale);
}

// Does `e` take part: its Interpolation component, else the project default.
bool wanted(const World& w, Entity e, bool byDefault, bool anyComponent) {
    if (anyComponent)
        if (const Interpolation* c = w.get<Interpolation>(e)) {
            if (c->mode == InterpolationMode::On) return true;
            if (c->mode == InterpolationMode::Off) return false;
        }
    return byDefault;
}

struct Walk {
    World* world;
    InterpState* state;
    bool byDefault, anyComponent;
    // begin_step / update
    bool begin;
    bool stepped;
    float alpha;
};

void visit(void* p, Entity e, const Transform& cur) {
    Walk& k = *static_cast<Walk*>(p);
    if (!k.world->alive(e) || !wanted(*k.world, e, k.byDefault, k.anyComponent)) return;
    InterpState& s = *k.state;
    InterpRecord& r = s.records[e.index];
    if (!r.used || r.bits != e.bits()) {  // appeared: nothing to blend from
        r = InterpRecord{};
        r.used = true;
        r.bits = e.bits();
        r.prev = r.last = cur;
        r.seen = true;
        return;
    }
    r.seen = true;
    if (k.begin) {  // the pose now is where the step starts (a teleport or an outside write needs nothing special)
        r.prev = cur;
        return;
    }
    if (k.stepped) {
        if (r.teleport || (s.snapDistance > 0.0f && length(cur.position - r.prev.position) > s.snapDistance))
            r.prev = cur;
        r.teleport = false;
        r.last = cur;
    } else if (r.teleport || !same(r.last, cur)) {  // written since the last step ended: not the simulation's move
        r.prev = r.last = cur;
        r.teleport = false;
    }
    if (k.alpha < 1.0f && !same(r.prev, cur)) {
        r.pose = interp_blend(r.prev, cur, k.alpha);
        r.hasPose = true;
        ++s.poseCount;
    }
}

}  // namespace

Transform interp_blend(const Transform& a, const Transform& b, float alpha) {
    Transform out;
    out.position = lerp(a.position, b.position, alpha);
    out.scale = lerp(a.scale, b.scale, alpha);
    out.rotation =
        same(a.rotation, b.rotation)
            ? b.rotation
            : slerp(Quat::from_euler_deg(a.rotation), Quat::from_euler_deg(b.rotation), alpha).to_euler_deg();
    return out;
}

void InterpState::clear_poses() {
    if (poseCount == 0) return;
    for (InterpRecord& r : records) r.hasPose = false;
    poseCount = 0;
}

void InterpState::clear_scene() {
    records.clear();
    poseCount = 0;
}

static bool prepare(World& w, Walk& k) {
    InterpState& s = w.interp();
    const bool anyComponent = w.count<Interpolation>() > 0;
    if (!s.enabled && !anyComponent) {
        if (!s.records.empty()) s.clear_scene();
        return false;
    }
    if (s.records.size() < w.index_bound()) s.records.resize(w.index_bound());
    k = Walk{&w, &s, s.enabled, anyComponent, false, false, 1.0f};
    return true;
}

void interp_begin_step(World& w) {
    Walk k;
    if (!prepare(w, k)) return;
    k.begin = true;
    w.walk_transforms_readonly(&k, &visit);
}

void interp_update(World& w, double alpha, bool stepped) {
    Walk k;
    InterpState& s = w.interp();
    s.clear_poses();
    if (!prepare(w, k)) return;
    k.stepped = stepped;
    k.alpha = float(std::clamp(alpha, 0.0, 1.0));
    for (InterpRecord& r : s.records) r.seen = false;
    w.walk_transforms_readonly(&k, &visit);
    for (InterpRecord& r : s.records)
        if (r.used && !r.seen) r = InterpRecord{};  // gone, or no longer interpolated
}

}  // namespace fa
