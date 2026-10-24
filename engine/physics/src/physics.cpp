// fa::Physics front-end: delegates to the 2D (Box2D) and 3D (custom) back-ends.
#include "fa/physics/physics.h"

#include "physics_internal.h"

namespace fa {

namespace detail {
WorldPose world_pose(const World& world, Entity e) {
    Mat4 m = world.world_matrix(e);
    WorldPose p;
    p.position = {m.at(3, 0), m.at(3, 1), m.at(3, 2)};
    auto col_len = [&](int c) {
        return std::sqrt(m.at(c, 0) * m.at(c, 0) + m.at(c, 1) * m.at(c, 1) + m.at(c, 2) * m.at(c, 2));
    };
    p.scale = {col_len(0), col_len(1), col_len(2)};
    p.rotZ = degrees(det::atan2(m.at(0, 1), m.at(0, 0)));
    for (int c = 0; c < 3; ++c) {
        const float l = p.scale[c];
        if (l > 1e-9f) p.axis[c] = {m.at(c, 0) / l, m.at(c, 1) / l, m.at(c, 2) / l};
    }
    return p;
}
}  // namespace detail

namespace detail {
bool entity_or_ancestor_is(const World& world, Entity e, Entity ignore) {
    if (ignore.is_null()) return false;
    for (int depth = 0; !e.is_null() && depth < 256; ++depth) {
        if (e == ignore) return true;
        e = world.parent(e);
    }
    return false;
}
}  // namespace detail

struct Physics::Impl {
    PhysicsSettings settings;
    detail::Physics2D p2d;
    detail::Physics3D p3d;
};

Physics::Physics() : impl_(std::make_unique<Impl>()) {}
Physics::~Physics() = default;

void Physics::init(const PhysicsSettings& settings) {
    impl_->settings = settings;
    if (impl_->settings.pixelsPerMeter <= 0.0f) impl_->settings.pixelsPerMeter = 100.0f;
    if (impl_->settings.subSteps < 1) impl_->settings.subSteps = 1;
    impl_->p2d.init(impl_->settings);
    impl_->p3d.init(impl_->settings);
}

void Physics::shutdown() {
    impl_->p2d.shutdown();
    impl_->p3d.reset();
}

void Physics::reset() {
    impl_->p2d.reset();
    impl_->p3d.reset();
}

void Physics::sync(World& world) {
    impl_->p2d.sync(world);
    impl_->p3d.sync(world);
    impl_->p3d.nav_update(world, true);
}

void Physics::step(World& world, float dt) {
    if (dt <= 0.0f) return;
    impl_->p2d.step(world, dt);
    impl_->p3d.step(world, dt);
    impl_->p3d.nav_update(world, true);
}

std::optional<RaycastHit> Physics::raycast2d(World& world, Vec2 from, Vec2 to, std::int32_t mask) {
    RaycastOptions o;
    o.mask = mask;
    return impl_->p2d.raycast(world, from, to, o);
}
std::optional<RaycastHit> Physics::raycast2d(World& world, Vec2 from, Vec2 to, const RaycastOptions& options) {
    return impl_->p2d.raycast(world, from, to, options);
}
std::vector<Entity> Physics::overlap_circle2d(World& world, Vec2 center, float radius, std::int32_t mask) {
    return impl_->p2d.overlap_circle(world, center, radius, mask);
}
std::vector<Entity> Physics::overlap_box2d(World& world, Rect box, std::int32_t mask) {
    return impl_->p2d.overlap_box(world, box, mask);
}
std::optional<RaycastHit> Physics::raycast3d(World& world, Vec3 origin, Vec3 dir, float maxDistance, std::int32_t mask) {
    RaycastOptions o;
    o.mask = mask;
    return impl_->p3d.raycast(world, origin, dir, maxDistance, o);
}
std::optional<RaycastHit> Physics::raycast3d(World& world, Vec3 origin, Vec3 dir, float maxDistance,
                                             const RaycastOptions& options) {
    return impl_->p3d.raycast(world, origin, dir, maxDistance, options);
}
std::vector<Entity> Physics::overlap_sphere3d(World& world, Vec3 center, float radius, std::int32_t mask) {
    return impl_->p3d.overlap_sphere(world, center, radius, mask);
}
std::optional<RaycastHit> Physics::shape_cast2d(World& world, const CastShape& shape, Vec2 from, Vec2 to,
                                                const RaycastOptions& options) {
    return impl_->p2d.shape_cast(world, shape, from, to, options);
}
std::optional<RaycastHit> Physics::shape_cast3d(World& world, const CastShape& shape, Vec3 from, Vec3 to,
                                                const RaycastOptions& options) {
    return impl_->p3d.shape_cast(world, shape, from, to, options);
}

std::optional<CharacterMoveResult> Physics::move_character(World& world, Entity e, Vec3 delta) {
    return impl_->p3d.move_character(world, e, delta);
}
std::vector<std::string> Physics::problems3d() const { return impl_->p3d.problems(); }
std::vector<StartOverlap> Physics::start_overlaps3d(World& world) {
    impl_->p3d.sync(world);
    return impl_->p3d.start_overlaps(world, false);
}

Result<std::vector<NavBakeStats>> Physics::nav_bake(World& world, const std::string& mesh) {
    impl_->p3d.sync(world);
    return impl_->p3d.nav_bake(world, mesh);
}
Result<NavPath> Physics::nav_find_path(World& world, Vec3 from, Vec3 to, const NavPathOptions& options) {
    return impl_->p3d.nav_find_path(world, from, to, options);
}
std::vector<NavCell> Physics::nav_cells(World& world, std::size_t maxCells) { return impl_->p3d.nav_cells(world, maxCells); }
std::vector<NavLinkDraw> Physics::nav_links(World& world) { return impl_->p3d.nav_links(world); }
Json Physics::nav_info(World& world) { return impl_->p3d.nav_info(world); }

void Physics::apply_impulse(World& world, Entity e, Vec3 impulse) {
    if (impl_->p2d.has_body(e)) impl_->p2d.apply_impulse(world, e, impulse);
    else if (impl_->p3d.has_body(e)) impl_->p3d.apply_impulse(world, e, impulse);
}
void Physics::apply_force(World& world, Entity e, Vec3 force) {
    if (impl_->p2d.has_body(e)) impl_->p2d.apply_force(world, e, force);
    else if (impl_->p3d.has_body(e)) impl_->p3d.apply_force(world, e, force);
}
void Physics::set_velocity(World& world, Entity e, Vec3 velocity) {
    if (impl_->p2d.has_body(e)) impl_->p2d.set_velocity(world, e, velocity);
    else if (impl_->p3d.has_body(e)) impl_->p3d.set_velocity(world, e, velocity);
}
bool Physics::is_grounded2d(World& world, Entity e, float tolerance) {
    return impl_->p2d.is_grounded(world, e, tolerance);
}

bool Physics::is_touching2d(World& world, Entity e, Vec2 direction, float tolerance) {
    return impl_->p2d.is_touching(world, e, direction, tolerance);
}
bool Physics::is_touching3d(World& world, Entity e, Vec3 direction, float tolerance) {
    return impl_->p3d.is_touching(world, e, direction, tolerance);
}
bool Physics::is_grounded(World& world, Entity e, float tolerance) {
    if (impl_->p2d.has_body(e)) return impl_->p2d.is_grounded(world, e, tolerance < 0.0f ? 2.0f : tolerance);
    if (impl_->p3d.has_body(e)) return impl_->p3d.is_touching(world, e, {0, -1, 0}, tolerance < 0.0f ? 0.05f : tolerance);
    return false;
}

Json Physics::debug_state(const World& world) const {
    Json out = Json::array();
    impl_->p2d.debug_state(world, out);
    impl_->p3d.debug_state(world, out);
    return out;
}

std::vector<Physics::DebugShape> Physics::debug_shapes(const World& world) const {
    std::vector<DebugShape> out;
    impl_->p2d.debug_shapes(world, out);
    impl_->p3d.debug_shapes(world, out);
    return out;
}

}  // namespace fa
