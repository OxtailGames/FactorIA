// Joint3D: hinge, ball and fixed joints solved with the same sequential impulses as the contacts. Each sub-step the joint
// is linearised at the current poses (prepare_joints), the impulses of the previous sub-step are re-applied (warm start)
// and solve_joints runs one Gauss-Seidel pass per iteration of the rigid-body solver. A position error is fed back as a
// velocity (Baumgarte, kBeta / h), so a pendulum neither drifts nor gains energy.
//
// Conventions: the angle of a hinge is the rotation of THIS body (the one with the Joint3D) relative to the connected
// one about the axis, measured from the pose at creation. Angular rows use wr = wA - wB; an angular impulse L acts as
// +L on A and -L on B.
#include <algorithm>
#include <cmath>
#include <format>

#include "fa/core/log.h"
#include "physics_internal.h"

namespace fa::detail {

namespace {
constexpr float kBeta = 0.2f;        // fraction of a position error removed per sub-step
constexpr float kMaxBias = 10.0f;    // fastest correction of a position error (m/s)

// A joint of a chain (three or more jointed dynamic bodies, see kChainIterations): its anchors are brought together by
// moving the bodies, not through the velocity.
template <class B>
bool in_chain(const B& a, const B* b) { return a.chainDrag > 0.0f || (b && b->chainDrag > 0.0f); }

Vec3 any_perpendicular(Vec3 a) {
    const Vec3 pick = std::fabs(a.x) < 0.6f ? Vec3{1, 0, 0} : (std::fabs(a.y) < 0.6f ? Vec3{0, 1, 0} : Vec3{0, 0, 1});
    return normalize(cross(a, pick));
}

float wrap_pi(float a) {
    a = std::fmod(a + kPi, kTau);
    if (a < 0.0f) a += kTau;
    return a - kPi;
}
}  // namespace

// An impulse at offset r from the body's centre, and a pure angular impulse.
void Physics3D::push_at(Body& b, Vec3 r, Vec3 impulse) {
    b.vel += impulse * b.invMass;
    b.angVel += inv_inertia_mul(b, cross(r, impulse)) * kRadToDeg;
}
void Physics3D::push_ang(Body& b, Vec3 L) { b.angVel += inv_inertia_mul(b, L) * kRadToDeg; }

// Joint state from the poses the bodies have now: the anchors in each body's local frame (relative to its centre), the
// hinge axis and a reference vector (angle 0), the relative rotation of a fixed joint.
void Physics3D::build_joint(JointState& j, const Body& a, const Body* b, const Joint3D& jt) {
    const Vec3 scaleA = a.localScale;
    const Vec3 originA = a.center - a.offset;
    const Vec3 anchorW = originA + frame_to_world(a.rot, jt.anchor * scaleA);
    j.anchorA = jt.anchor * scaleA - a.localOffset;
    if (b) {
        j.anchorB = jt.autoAnchor ? world_to_frame(b->rot, anchorW - b->center) : jt.connectedAnchor * b->localScale - b->localOffset;
    } else {
        j.anchorB = jt.autoAnchor ? anchorW : jt.connectedAnchor;
    }
    Vec3 axis = normalize(jt.axis);
    if (length_sq(axis) < 0.5f) axis = {0, 0, 1};
    j.axisA = axis;
    const Vec3 aw = frame_to_world(a.rot, axis);
    j.axisB = b ? world_to_frame(b->rot, aw) : aw;
    j.refA = any_perpendicular(axis);
    const Vec3 rw = frame_to_world(a.rot, j.refA);
    j.refB = b ? world_to_frame(b->rot, rw) : rw;
    for (int i = 0; i < 3; ++i) {
        const Vec3 bi = b ? b->rot[i] : kIdentityAxes[i];
        j.relCol[i] = world_to_frame(a.rot, bi);
    }
    j.angle = 0.0f;
    j.pImp = j.aImp = {};
    j.lowImp = j.upImp = j.motorImp = 0.0f;
}

void Physics3D::sync_joints(World& world, std::uint64_t stamp) {
    for (Entity e : world.entities()) {
        const Joint3D* jt = world.get<Joint3D>(e);
        if (!jt || world.pending_destroy(e)) continue;
        const std::uint64_t key = e.bits();
        JointState& j = joints_[key];
        const bool fresh = j.seen == 0 && j.seqA == 0;
        j.e = e;
        j.seen = stamp + 1;  // (stamp 0 would look unset)
        const std::string previousProblem = j.problem;
        j.problem.clear();
        j.active = false;
        auto ita = index_.find(key);
        if (ita == index_.end() || !bodies_[ita->second].enabled) {
            if (ita == index_.end())
                j.problem = std::format("entity '{}' has a Joint3D but no RigidBody3D. Add a RigidBody3D (and a Collider3D "
                                        "for its shape) to the entity that swings.", world.id_of(e));
            continue;
        }
        Body& a = bodies_[ita->second];
        const Body* b = nullptr;
        if (!jt->connected.is_null()) {
            if (jt->connected == e) {
                j.problem = std::format("entity '{}': Joint3D.connected is the entity itself. Name the OTHER body, or leave "
                                        "it empty to join the world.", world.id_of(e));
            } else if (!live(world, jt->connected)) {
                j.problem = std::format("entity '{}': Joint3D.connected names an entity that does not exist (any more). "
                                        "Set it to a living entity id, or empty for the world.", world.id_of(e));
            } else if (auto itb = index_.find(jt->connected.bits()); itb == index_.end()) {
                j.problem = std::format("entity '{}': the connected entity '{}' has no RigidBody3D or Collider3D, so there is "
                                        "no body to join. Add one, or leave Joint3D.connected empty to join the world.",
                                        world.id_of(e), world.id_of(jt->connected));
            } else {
                b = &bodies_[itb->second];
            }
        }
        if (j.problem.empty() && !a.hasShape)
            j.problem = std::format("entity '{}': a Joint3D needs a Collider3D on the same entity (its shape gives the body "
                                    "its inertia).", world.id_of(e));
        if (!j.problem.empty()) {
            if (j.problem != previousProblem) FA_ERROR("physics", "{}", j.problem);
            continue;
        }
        const bool changed = fresh || j.type != jt->type || j.conn != jt->connected || j.sigAnchor != jt->anchor ||
                             j.sigConnAnchor != jt->connectedAnchor || j.sigAxis != jt->axis ||
                             j.sigAuto != jt->autoAnchor || j.seqA != a.seq || j.seqB != (b ? b->seq : 0);
        j.seqA = a.seq;
        j.seqB = b ? b->seq : 0;
        // A motor, a limit or the damping edited by gameplay wakes the sleeping chain: it may have to move now.
        const float lower = radians(std::min(jt->lowerLimit, jt->upperLimit));
        const float upper = radians(std::max(jt->lowerLimit, jt->upperLimit));
        const float damping = std::max(jt->damping, 0.0f);
        if (!fresh && (j.useLimits != jt->useLimits || j.lower != lower || j.upper != upper || j.useMotor != jt->useMotor ||
                       j.motorSpeed != radians(jt->motorSpeed) || j.maxTorque != std::max(jt->maxMotorTorque, 0.0f) ||
                       j.damping != damping)) {
            wake(a);
            if (b) wake(bodies_[index_[jt->connected.bits()]]);
        }
        j.damping = damping;
        j.conn = jt->connected;
        j.type = jt->type;
        j.useLimits = jt->useLimits;
        j.lower = lower;
        j.upper = upper;
        j.useMotor = jt->useMotor;
        j.motorSpeed = radians(jt->motorSpeed);
        j.maxTorque = std::max(jt->maxMotorTorque, 0.0f);
        if (changed) {
            build_joint(j, a, b, *jt);
            j.sigAnchor = jt->anchor;
            j.sigConnAnchor = jt->connectedAnchor;
            j.sigAxis = jt->axis;
            j.sigAuto = jt->autoAnchor;
        }
        if (!jt->collideConnected && b) {
            a.noCollide.push_back(b->seq);
            bodies_[index_[jt->connected.bits()]].noCollide.push_back(a.seq);
        }
        j.active = true;
    }
    for (auto it = joints_.begin(); it != joints_.end();) {
        if (it->second.seen != stamp + 1) it = joints_.erase(it);
        else ++it;
    }
    // Solve order: by the owner body's creation sequence (which follows the scene's entity order and restarts at reset()),
    // never by entity bits, so a scene simulates the same whatever the World held before it.
    jointOrder_.clear();
    for (auto& [key, j] : joints_) jointOrder_.push_back(&j);
    std::sort(jointOrder_.begin(), jointOrder_.end(), [](const JointState* a, const JointState* b) {
        return a->seqA != b->seqA ? a->seqA < b->seqA : a->e.bits() < b->e.bits();
    });
}

// Hinge angle: rotation of A relative to B about the axis, continuous (unwrapped against the previous value).
static float hinge_angle(const Vec3* RA, const Vec3* RB, const Vec3& axisA, const Vec3& refA, const Vec3& refB, bool hasB,
                         float previous) {
    const Vec3 aw = frame_to_world(RA, axisA);
    const Vec3 ra = frame_to_world(RA, refA);
    Vec3 rb = hasB ? frame_to_world(RB, refB) : refB;
    rb = rb - aw * dot(rb, aw);
    if (length_sq(rb) < 1e-8f) return previous;
    const float theta = std::atan2(dot(cross(ra, rb), aw), dot(ra, rb));  // B relative to A
    const float raw = -theta;                                             // A relative to B
    return previous + wrap_pi(raw - previous);
}

// Position pass of the joint anchors: the bodies are moved and turned directly so the two anchors meet. The correction is
// never added to the velocities (Baumgarte pumped energy into a taut chain: a rope bridge never calmed down).
void Physics3D::correct_joints(float h) {
    constexpr int kPasses = 4;
    const std::size_t count = jointOrder_.size();
    for (int pass = 0; pass < kPasses; ++pass) {
        for (std::size_t oi = 0; oi < count; ++oi) {
            JointState& j = *jointOrder_[(pass & 1) ? count - 1 - oi : oi];
            if (!j.active) continue;
            auto ia = index_.find(j.e.bits());
            if (ia == index_.end()) continue;
            Body& A = bodies_[ia->second];
            Body* B = nullptr;
            if (j.seqB != 0) {
                auto ib = index_.find(j.conn.bits());
                if (ib == index_.end()) continue;
                B = &bodies_[ib->second];
            }
            if (!((A.type == BodyType::Dynamic && !A.asleep) || (B && B->type == BodyType::Dynamic && !B->asleep))) continue;
            if (!in_chain(A, B)) continue;
            const Vec3 rA = frame_to_world(A.rot, j.anchorA);
            const Vec3 rB = B ? frame_to_world(B->rot, j.anchorB) : Vec3{};
            Vec3 err = (B ? B->center + rB : j.anchorB) - (A.center + rA);
            const float el = length(err);
            if (el < 1e-6f) continue;
            const float cap = kMaxBias * h;  // never more than a bias-limited step
            Vec3 want = -err;
            if (el > cap) want = want * (cap / el);
            const float im = A.invMass + (B ? B->invMass : 0.0f);
            auto kmul = [&](Vec3 x) {
                Vec3 r = x * im + cross(inv_inertia_mul(A, cross(rA, x)), rA);
                if (B) r += cross(inv_inertia_mul(*B, cross(rB, x)), rB);
                return r;
            };
            const Vec3 c0 = kmul({1, 0, 0}), c1 = kmul({0, 1, 0}), c2 = kmul({0, 0, 1});
            const float det = dot(c0, cross(c1, c2));
            if (std::fabs(det) < 1e-12f) continue;
            const Vec3 k0 = cross(c1, c2) / det, k1 = cross(c2, c0) / det, k2 = cross(c0, c1) / det;
            const Vec3 P{dot(k0, want), dot(k1, want), dot(k2, want)};
            A.center -= P * A.invMass;
            turn_by(A, inv_inertia_mul(A, cross(rA, -P)));
            if (B) {
                B->center += P * B->invMass;
                turn_by(*B, inv_inertia_mul(*B, cross(rB, P)));
            }
        }
    }
}

bool Physics3D::prepare_joints(float h) {
    bool any = false;
    correct_joints(h);
    for (JointState* jp : jointOrder_) {
        JointState& j = *jp;
        if (!j.active) continue;
        auto ia = index_.find(j.e.bits());
        if (ia == index_.end()) { j.active = false; continue; }
        j.ia = ia->second;
        j.hasB = j.seqB != 0 && index_.count(j.conn.bits()) != 0;
        if (j.hasB) j.ib = index_[j.conn.bits()];
        if (j.seqB != 0 && !j.hasB) { j.active = false; continue; }
        Body& A = bodies_[j.ia];
        Body* B = j.hasB ? &bodies_[j.ib] : nullptr;
        if (A.invMass + (B ? B->invMass : 0.0f) <= 0.0f && !A.rotDyn && !(B && B->rotDyn)) { j.active = false; continue; }  // nothing can move
        // A chain at rest (asleep) costs nothing: its impulses wait for the bodies to wake.
        j.live = (A.type == BodyType::Dynamic && !A.asleep) || (B && B->type == BodyType::Dynamic && !B->asleep);
        if (!j.live) continue;
        const Vec3* RA = A.rot;
        const Vec3* RB = B ? B->rot : kIdentityAxes;
        j.rA = frame_to_world(RA, j.anchorA);
        j.rB = B ? frame_to_world(RB, j.anchorB) : Vec3{};
        if (in_chain(A, B)) {
            j.pBias = {};  // the error of a chain's joints was already removed by correct_joints, not through the velocity
        } else {
            const Vec3 pA = A.center + j.rA, pB = B ? B->center + j.rB : j.anchorB;
            Vec3 bias = (pB - pA) * (-kBeta / h);
            const float bl = length(bias);
            if (bl > kMaxBias) bias = bias * (kMaxBias / bl);
            j.pBias = bias;
        }
        const float im = A.invMass + (B ? B->invMass : 0.0f);
        auto kmul = [&](Vec3 x) {
            Vec3 r = x * im + cross(inv_inertia_mul(A, cross(j.rA, x)), j.rA);
            if (B) r += cross(inv_inertia_mul(*B, cross(j.rB, x)), j.rB);
            return r;
        };
        const Vec3 c0 = kmul({1, 0, 0}), c1 = kmul({0, 1, 0}), c2 = kmul({0, 0, 1});
        const float det = dot(c0, cross(c1, c2));
        if (std::fabs(det) < 1e-12f) { j.kinv[0] = j.kinv[1] = j.kinv[2] = {}; }
        else {
            j.kinv[0] = cross(c1, c2) / det;
            j.kinv[1] = cross(c2, c0) / det;
            j.kinv[2] = cross(c0, c1) / det;
        }
        auto ang_k = [&](Vec3 t) {
            float k = dot(t, inv_inertia_mul(A, t));
            if (B) k += dot(t, inv_inertia_mul(*B, t));
            return std::max(k, 1e-9f);
        };
        j.aw = frame_to_world(RA, j.axisA);
        if (j.type == JointType3D::Hinge) {
            const Vec3 bw = B ? frame_to_world(RB, j.axisB) : j.axisB;
            const Vec3 e = cross(j.aw, bw);
            j.t1 = any_perpendicular(j.aw);
            j.t2 = cross(j.aw, j.t1);
            j.fixBias = e;
            j.k1 = ang_k(j.t1);
            j.k2 = ang_k(j.t2);
            j.kAxis = ang_k(j.aw);
            j.angle = hinge_angle(RA, RB, j.axisA, j.refA, j.refB, B != nullptr, j.angle);
        } else if (j.type == JointType3D::Fixed) {
            Vec3 e{};
            for (int i = 0; i < 3; ++i) {
                const Vec3 desired = frame_to_world(RA, j.relCol[i]);
                e += cross(desired, B ? B->rot[i] : kIdentityAxes[i]) * 0.5f;
            }
            j.fixBias = e;
            j.k1 = ang_k({1, 0, 0});
            j.k2 = ang_k({0, 1, 0});
            j.kAxis = ang_k({0, 0, 1});
        }
        // Warm start.
        push_at(A, j.rA, -j.pImp);
        if (B) push_at(*B, j.rB, j.pImp);
        Vec3 L{};
        if (j.type == JointType3D::Hinge) L = j.t1 * j.aImp.x + j.t2 * j.aImp.y + j.aw * (j.lowImp + j.upImp + j.motorImp);
        else if (j.type == JointType3D::Fixed) L = j.aImp;
        push_ang(A, L);
        if (B) push_ang(*B, -L);
        // Damping: the relative turning loses a fraction per sub-step (an implicit step: stable for any value).
        if (j.damping > 0.0f && j.type != JointType3D::Fixed) {
            const float keep = 1.0f / (1.0f + h * j.damping);
            auto relw = [&]() { return (A.angVel - (B ? B->angVel : Vec3{})) * kDegToRad; };
            if (j.type == JointType3D::Hinge) {
                const Vec3 dir = j.aw;
                const float Ld = -dot(relw(), dir) * (1.0f - keep) / j.kAxis;
                push_ang(A, dir * Ld);
                if (B) push_ang(*B, dir * -Ld);
            } else {
                for (int i = 0; i < 3; ++i) {
                    Vec3 dir{};
                    dir[i] = 1.0f;
                    const float Ld = -relw()[i] * (1.0f - keep) / ang_k(dir);
                    push_ang(A, dir * Ld);
                    if (B) push_ang(*B, dir * -Ld);
                }
            }
        }
        any = true;
    }
    return any;
}

void Physics3D::solve_joints(float h, int iteration) {
    const std::size_t count = jointOrder_.size();
    for (std::size_t oi = 0; oi < count; ++oi) {
        // Sweeps alternate direction (symmetric Gauss-Seidel): a chain's news travels both ways in two iterations.
        JointState& j = *jointOrder_[(iteration & 1) ? count - 1 - oi : oi];
        if (!j.active || !j.live) continue;
        Body& A = bodies_[j.ia];
        Body* B = j.hasB ? &bodies_[j.ib] : nullptr;
        if (iteration >= std::max(A.iterations, B ? B->iterations : 0)) continue;  // this chain has had its iterations
        auto apply_ang = [&](Vec3 L) {  // +L on A, -L on B
            push_ang(A, L);
            if (B) push_ang(*B, -L);
        };
        auto wr = [&]() { return (A.angVel - (B ? B->angVel : Vec3{})) * kDegToRad; };
        // Point: the two anchors move together.
        {
            const Vec3 vA = A.vel + cross(A.angVel * kDegToRad, j.rA);
            const Vec3 vB = B ? B->vel + cross(B->angVel * kDegToRad, j.rB) : Vec3{};
            const Vec3 rhs = j.pBias - (vB - vA);
            const Vec3 P{dot(j.kinv[0], rhs), dot(j.kinv[1], rhs), dot(j.kinv[2], rhs)};
            j.pImp += P;
            push_at(A, j.rA, -P);
            if (B) push_at(*B, j.rB, P);
        }
        if (j.type == JointType3D::Hinge) {
            const float gain = kBeta / h;
            const Vec3 ts[2] = {j.t1, j.t2};
            const float ks[2] = {j.k1, j.k2};
            for (int i = 0; i < 2; ++i) {
                const float target = gain * dot(j.fixBias, ts[i]);
                const float L = (target - dot(wr(), ts[i])) / ks[i];
                (&j.aImp.x)[i] += L;
                apply_ang(ts[i] * L);
            }
            if (j.useMotor) {
                const float L = (j.motorSpeed - dot(wr(), j.aw)) / j.kAxis;
                const float cap = j.maxTorque * h;
                const float next = clamp(j.motorImp + L, -cap, cap);
                apply_ang(j.aw * (next - j.motorImp));
                j.motorImp = next;
            }
            if (j.useLimits) {
                const float lowErr = j.angle - j.lower, upErr = j.upper - j.angle;
                {
                    const float bound = lowErr > 0.0f ? -lowErr / h : -kBeta * lowErr / h;
                    const float L = (bound - dot(wr(), j.aw)) / j.kAxis;
                    const float next = std::max(j.lowImp + L, 0.0f);
                    apply_ang(j.aw * (next - j.lowImp));
                    j.lowImp = next;
                }
                {
                    const float bound = upErr > 0.0f ? upErr / h : kBeta * upErr / h;
                    const float L = (bound - dot(wr(), j.aw)) / j.kAxis;
                    const float next = std::min(j.upImp + L, 0.0f);
                    apply_ang(j.aw * (next - j.upImp));
                    j.upImp = next;
                }
            }
        } else if (j.type == JointType3D::Fixed) {
            const float gain = kBeta / h;
            for (int i = 0; i < 3; ++i) {
                const float k = (i == 0 ? j.k1 : (i == 1 ? j.k2 : j.kAxis));
                const float target = gain * j.fixBias[i];
                const float L = (target - wr()[i]) / k;
                j.aImp[i] += L;
                Vec3 axis{};
                axis[i] = L;
                apply_ang(axis);
            }
        }
    }
}

void Physics3D::finish_joints(World& world, float dt) {
    for (JointState* jp : jointOrder_) {
        JointState& j = *jp;
        if (!j.active || j.type != JointType3D::Hinge) continue;
        auto ia = index_.find(j.e.bits());
        if (ia == index_.end()) continue;
        const Body& A = bodies_[ia->second];
        auto ib = j.seqB != 0 ? index_.find(j.conn.bits()) : index_.end();
        const Body* B = ib != index_.end() ? &bodies_[ib->second] : nullptr;
        const Vec3* RB = B ? B->rot : kIdentityAxes;
        j.angle = hinge_angle(A.rot, RB, j.axisA, j.refA, j.refB, B != nullptr, j.angle);
        // Stalled: the motor pushes but the joint does not turn (a wall in the way, too little torque). A hinge that
        // reached its limit has arrived, it is not stalled. The sleeping chain keeps its last verdict (motors keep
        // their bodies awake, so this only happens when the motor was switched off).
        const float target = std::fabs(j.motorSpeed);
        if (j.live) {
            bool driving = j.useMotor && target > 1e-4f && j.maxTorque > 0.0f;
            if (driving && j.useLimits) {
                const float margin = 0.01f;
                if ((j.motorSpeed > 0.0f && j.angle >= j.upper - margin) || (j.motorSpeed < 0.0f && j.angle <= j.lower + margin))
                    driving = false;
            }
            const float speed = std::fabs(dot((A.angVel - (B ? B->angVel : Vec3{})) * kDegToRad, normalize(frame_to_world(A.rot, j.axisA))));
            if (driving && speed < 0.1f * target) j.stallTime += dt;
            else j.stallTime = 0.0f;
        } else if (!j.useMotor) {
            j.stallTime = 0.0f;
        }
        if (Joint3D* jt = world.get<Joint3D>(j.e)) {
            jt->angle = degrees(j.angle);
            jt->stalled = j.stallTime >= 0.25f;
        }
    }
}

}  // namespace fa::detail
