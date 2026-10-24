// CharacterController3D: a kinematic capsule moved by collide-and-slide. The capsule is swept against every other solid
// collider (the same stepping + bisection as shape_cast3d), stops a skin short of what it hits and slides the rest of the
// move along the surface. Steps up to stepOffset are climbed by lifting the capsule, moving it forward and dropping it
// back; slopes steeper than slopeLimit behave like walls; going down the capsule is snapped back onto the ground.
#include <algorithm>
#include <cmath>

#include "physics_internal.h"

namespace fa::detail {

namespace {
constexpr int kSlideIterations = 5;
constexpr float kMinMove = 1e-5f;
constexpr float kGroundProbe = 0.04f;  // grounded when the ground is closer than skin + this (m)
}  // namespace

CharacterMoveResult Physics3D::move_character_body(World& world, Body& b, Vec3 delta) {
    CharacterMoveResult out;
    const float walk = det::cos(radians(b.slopeLimit));
    const float skin = b.skin;
    const std::size_t self = std::size_t(&b - bodies_.data());
    const Vec3 startCenter = b.center;

    struct Hit {
        float t = 1.0f;
        int body = -1;
        Vec3 normal{0, 1, 0};
    };
    auto blocks = [&](std::size_t k) {
        const Body& o = bodies_[k];
        return k != self && o.enabled && o.hasShape && !o.trigger && live(world, o.e) && filters_pass(b, o);
    };
    // Sweeps the capsule by `disp`; the earliest solid it touches (fraction t of the move, and its surface normal).
    auto cast = [&](Vec3 disp) {
        Hit h;
        if (length_sq(disp) < kMinMove * kMinMove) return h;
        for (std::size_t k = 0; k < bodies_.size(); ++k) {
            if (!blocks(k)) continue;
            float t = 0.0f;
            if (!sweep(b, disp, {}, bodies_[k], {}, t) || t >= h.t) continue;
            const Vec3 from = b.center;
            b.center = from + disp * t;
            const Contact c = collide(bodies_[k], b, 0.0f);  // normal: obstacle -> character
            b.center = from;
            h.t = t;
            h.body = int(k);
            h.normal = c.hit ? c.normal : -normalize(disp);
        }
        return h;
    };
    // Pushes the capsule out of whatever it overlaps (gameplay teleports, a moving platform, a dynamic body pushed in).
    auto depenetrate = [&]() {
        for (int pass = 0; pass < 4; ++pass) {
            bool moved = false;
            for (std::size_t k = 0; k < bodies_.size(); ++k) {
                if (!blocks(k)) continue;
                const Contact c = collide(bodies_[k], b, 0.0f);
                if (!c.hit || c.depth < 1e-4f) continue;
                b.center += c.normal * std::min(c.depth + 1e-4f, 0.5f);
                moved = true;
            }
            if (!moved) break;
        }
    };
    std::vector<char> pushed(bodies_.size(), 0);
    auto push = [&](const Hit& h, Vec3 motion) {  // a dynamic body in the way moves off at the character's speed
        Body& o = bodies_[std::size_t(h.body)];
        if (o.type != BodyType::Dynamic || o.jointed || b.pushStrength <= 0.0f || pushed[std::size_t(h.body)] ||
            h.normal.y > 0.7f)
            return;  // a jointed body (a seesaw, a plank) is held by its joint: shoving it would drag it off
        const float speed = std::max(-dot(motion, h.normal), 0.0f) / std::max(lastDt_, 1e-4f) * b.pushStrength;
        const float have = dot(o.vel, -h.normal);
        if (speed <= have) return;
        wake(o);
        o.vel += -h.normal * (speed - have);
        pushed[std::size_t(h.body)] = 1;
    };

    // Moves by `motion`, sliding along what it hits. canStep: a wall in the way may be a step to climb.
    auto slide = [&](Vec3 motion, bool canStep) {
        Vec3 remaining = motion;
        for (int iter = 0; iter < kSlideIterations && length(remaining) > kMinMove; ++iter) {
            const Hit h = cast(remaining);
            if (h.body < 0) {
                b.center += remaining;
                return;
            }
            b.center += remaining * h.t + h.normal * skin;
            push(h, remaining);
            Vec3 rest = remaining * (1.0f - h.t);
            const Vec3 n = h.normal;
            if (n.y >= walk) {  // walkable ground or slope: keep the horizontal travel, follow the surface
                const Vec3 flat{rest.x, 0.0f, rest.z};
                rest = flat - Vec3{0, 1, 0} * (dot(flat, n) / n.y);
            } else {
                if (n.y < -0.05f) out.hitCeiling = true;
                else out.hitWall = true;
                if (canStep && b.stepOffset > 1e-4f && n.y >= -0.05f) {
                    // Step up: lift, go forward, drop back; keep it only if it lands on walkable ground.
                    const Vec3 flat{rest.x, 0.0f, rest.z};
                    if (length(flat) > kMinMove) {
                        const Vec3 saved = b.center;
                        const Hit up = cast({0, b.stepOffset, 0});
                        const float rise = up.body < 0 ? b.stepOffset : std::max(b.stepOffset * up.t - skin, 0.0f);
                        bool ok = rise > 1e-3f;
                        if (ok) {
                            b.center.y += rise;
                            // The capsule stands a skin away from the step, so a frame's worth of travel would land it
                            // beside the edge: reach at least part of its radius so it ends up on the step.
                            const Vec3 reach = normalize(flat) * std::max(length(flat), 0.7f * b.radius);
                            const Hit fwd = cast(reach);
                            const Vec3 go = fwd.body < 0 ? reach : reach * std::max(fwd.t, 0.0f);
                            ok = length(go) > 2.0f * skin;
                            if (ok) {
                                b.center += go;
                                const float drop = rise + skin + 0.01f;
                                const Hit down = cast({0, -drop, 0});
                                ok = down.body >= 0 && down.normal.y >= walk;
                                if (ok) {
                                    b.center.y -= drop * down.t - skin;
                                    rest = length(go) >= length(flat) ? Vec3{} : flat - go;
                                    remaining = rest;
                                    continue;
                                }
                            }
                        }
                        b.center = saved;
                    }
                }
                rest = rest - n * dot(rest, n);
                if (n.y > 0.0f && rest.y > 0.0f) rest.y = 0.0f;  // a slope too steep to walk is not climbed
            }
            remaining = rest;
        }
    };
    auto probe_ground = [&](Hit& hit) {
        hit = cast({0, -(skin + kGroundProbe), 0});
        return hit.body >= 0 && hit.normal.y >= walk;
    };

    depenetrate();
    Hit ground;
    const bool wasGrounded = probe_ground(ground);
    const Vec3 flat{delta.x, 0.0f, delta.z};
    if (length(flat) > kMinMove) {
        // On a slope the walk follows the surface, so it keeps its horizontal speed up and down the ramp.
        Vec3 move = flat;
        if (wasGrounded && ground.normal.y < 0.999f) move = flat - Vec3{0, 1, 0} * (dot(flat, ground.normal) / ground.normal.y);
        slide(move, true);
    }
    if (delta.y > kMinMove) {
        slide({0, delta.y, 0}, false);
    } else {
        if (delta.y < -kMinMove) slide({0, delta.y, 0}, false);
        if (wasGrounded || delta.y < -kMinMove) {
            // Snap back down onto the ground after walking off a ramp or over a step's edge.
            const Hit down = cast({0, -(b.stepOffset + skin), 0});
            if (down.body >= 0 && down.normal.y >= walk) {
                const float drop = (b.stepOffset + skin) * down.t - skin;
                if (drop > 0.0f) b.center.y -= drop;
            }
        }
    }
    out.isGrounded = delta.y <= kMinMove && probe_ground(ground);
    if (out.isGrounded) {
        out.groundNormal = ground.normal;
        out.ground = bodies_[std::size_t(ground.body)].e;
    }
    b.support = out.ground;
    out.moved = b.center - startCenter;
    out.position = b.center - b.offset;
    // Hand the result to the world: the Transform now, riders on the capsule are carried by what it moved.
    if (out.moved != Vec3{}) {
        world.set_world_position(b.e, out.position);
        b.lastPos = world.world_position(b.e);
        b.lastCenter = b.center;
        b.pendingCarry += out.moved;
        b.moved = true;
    }
    if (CharacterController3D* c = world.get<CharacterController3D>(b.e)) {
        c->isGrounded = out.isGrounded;
        c->groundNormal = out.groundNormal;
    }
    return out;
}

std::optional<CharacterMoveResult> Physics3D::move_character(World& world, Entity e, Vec3 delta) {
    sync(world);
    auto it = index_.find(e.bits());
    if (it == index_.end() || !bodies_[it->second].character || !bodies_[it->second].enabled) return std::nullopt;
    if (!std::isfinite(delta.x + delta.y + delta.z)) return std::nullopt;
    return move_character_body(world, bodies_[it->second], delta);
}

}  // namespace fa::detail
