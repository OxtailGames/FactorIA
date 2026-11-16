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
    std::uint32_t& slot = s.slots[e.index];
    if (slot != 0 && s.records[slot - 1].bits != e.bits()) {  // the slot's old entity died: forget its record
        s.records[slot - 1] = InterpRecord{};
        s.records[slot - 1].bits = e.bits();
        s.records[slot - 1].prev = s.records[slot - 1].last = cur;
        s.records[slot - 1].seen = s.stamp;
        return;
    }
    if (slot == 0) {  // appeared: nothing to blend from
        InterpRecord n;
        n.bits = e.bits();
        n.prev = n.last = cur;
        n.seen = s.stamp;
        s.records.push_back(n);
        slot = std::uint32_t(s.records.size());
        return;
    }
    InterpRecord& r = s.records[slot - 1];
    r.seen = s.stamp;
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
    const Vec3 d = b.rotation - a.rotation;
    if (same(a.rotation, b.rotation) || std::abs(d.x) > 180.0f || std::abs(d.y) > 180.0f || std::abs(d.z) > 180.0f)
        out.rotation = b.rotation;  // unchanged (kept bit for bit), or turned past half a turn in one step: no blend
    else if (a.rotation.x == b.rotation.x && a.rotation.y == b.rotation.y)
        out.rotation = Vec3{b.rotation.x, b.rotation.y, a.rotation.z + d.z * alpha};  // 2D: the angle itself
    else
        out.rotation = slerp(Quat::from_euler_deg(a.rotation), Quat::from_euler_deg(b.rotation), alpha).to_euler_deg();
    return out;
}

void InterpState::clear_poses() {
    if (poseCount == 0) return;
    for (InterpRecord& r : records) r.hasPose = false;
    poseCount = 0;
}

void InterpState::clear_scene() {
    records.clear();
    slots.clear();
    poseCount = 0;
}

static bool prepare(World& w, Walk& k) {
    InterpState& s = w.interp();
    const bool anyComponent = w.count<Interpolation>() > 0;
    if (!s.enabled && !anyComponent) {
        if (!s.records.empty()) s.clear_scene();
        return false;
    }
    if (s.slots.size() < w.index_bound()) s.slots.resize(w.index_bound(), 0);
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
    ++s.stamp;
    w.walk_transforms_readonly(&k, &visit);
    for (std::size_t i = 0; i < s.records.size();) {  // gone, or no longer interpolated: swap-remove
        if (s.records[i].seen == s.stamp) {
            ++i;
            continue;
        }
        const Entity dead = Entity::from_bits(s.records[i].bits);
        if (s.records[i].hasPose) --s.poseCount;
        if (dead.index < s.slots.size() && s.slots[dead.index] == i + 1) s.slots[dead.index] = 0;
        if (i + 1 != s.records.size()) {
            s.records[i] = s.records.back();
            s.slots[Entity::from_bits(s.records[i].bits).index] = std::uint32_t(i + 1);
        }
        s.records.pop_back();
    }
}

}  // namespace fa
