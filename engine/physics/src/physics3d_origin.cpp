// Floating origin, 3D physics side: moves everything Physics3D keeps in world space by -offset, in the step World::rebase ran.
// The Transforms are already shifted. Nothing is woken, rebuilt or re-baked: velocities, sleeping state, pairs touching, the
// broad-phase tree and the navigation grids keep their state, only positions change (docs/BIG_WORLDS.md, "Floating origin").
#include <algorithm>
#include <vector>

#include "physics_internal.h"

namespace fa::detail {

void Physics3D::origin_shifted(World& world, Vec3 offset) {
    // Navigation signatures hash absolute positions, so a shift would look like an edit and re-bake every grid. What was
    // current before the shift is current after it: note it now (bodies and grids still hold the old positions) and store
    // the signatures of the shifted state afterwards.
    struct NavNote {
        std::uint64_t key;
        bool sigCurrent;
        std::vector<std::uint64_t> obstacles;  // entity bits whose applied pose signature was current
    };
    std::vector<NavNote> notes;
    for (auto& [key, n] : navs_) {
        NavNote note{key, n.baked && n.sig == nav_signature(n), {}};
        for (const Body& b : bodies_) {
            auto it = n.obstacleSig.find(b.e.bits());
            if (it != n.obstacleSig.end() && it->second == nav_obstacle_signature(b))
                note.obstacles.push_back(it->first);
        }
        notes.push_back(std::move(note));
    }

    for (Body& b : bodies_) {
        b.center -= offset;
        b.lastCenter -= offset;
        b.lastPos -= offset;
        if (!world.alive(b.e)) continue;
        // What sync compares the Transform with is the world position it reads now (a child's is composed from its shifted
        // root, which can differ in the last bit from the old value minus the offset); a static body is re-derived from it.
        const Vec3 wp = world.world_position(b.e);
        b.lastPos = wp;
        if (b.type == BodyType::Static) {
            b.center = wp + b.offset;
            b.lastCenter = b.center;
        }
    }
    bp_.shift(offset);
    for (WarmEntry& w : warm_)
        for (int i = 0; i < w.count && i < kMaxPts; ++i) w.pt[i].pos -= offset;
    for (auto& [key, j] : joints_) {
        (void)key;
        if (j.seqB != 0) continue;
        j.anchorB -= offset;  // a world point when the joint holds to the world
        if (j.conn.is_null())
            j.sigConnAnchor -= offset;  // (World::rebase shifted the component's connectedAnchor the same)
    }
    for (auto& [key, n] : navs_) {
        (void)key;
        n.position -= offset;
        if (world.alive(n.e)) n.position = world.world_position(n.e);
        if (n.baked) n.grid.shift(offset);
        for (NavState::Link& l : n.links) {
            l.from -= offset;
            l.to -= offset;
        }
    }
    for (const NavNote& note : notes) {
        NavState& n = navs_[note.key];
        if (note.sigCurrent) n.sig = nav_signature(n);
        for (const Body& b : bodies_) {
            if (std::find(note.obstacles.begin(), note.obstacles.end(), b.e.bits()) != note.obstacles.end())
                n.obstacleSig[b.e.bits()] = nav_obstacle_signature(b);
        }
    }
}

}  // namespace fa::detail
