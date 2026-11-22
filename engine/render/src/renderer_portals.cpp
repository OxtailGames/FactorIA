// Renderer::Impl, area and portal culling (M75.2; docs/BIG_WORLDS_LOD.md, "Areas and portals"): the OcclusionArea entities are rooms, the
// OcclusionPortal entities are the doors between them, and a mesh is drawn in the main pass only when a chain of open portals that the
// camera sees leads from its area to the camera's. The graph and the frustum narrowing are portal_graph.h; this file gathers the
// entities (their drawn matrices, so a floating-origin shift needs nothing), reports what is wrong with them and applies the answer.
// Shadow passes are not culled: only MeshItem::visible changes, like the CPU occluders.
#include <algorithm>
#include <cmath>
#include <limits>

#include "fa/core/strings.h"
#include "portal_graph.h"
#include "renderer_impl.h"

namespace fa {

namespace {
// Keys of warnedPortalEntities besides an unknown area id (which is the id itself).
constexpr std::int64_t kBadAreaId = std::numeric_limits<std::int64_t>::min();
constexpr std::int64_t kSameArea = std::numeric_limits<std::int64_t>::min() + 1;
}  // namespace

void Renderer::Impl::portal_cull_meshes(World& world, Frame& fr, std::vector<MeshItem>& meshes) {
    using namespace render;
    std::vector<PortalAreaBox> areas;
    world.each<OcclusionArea>([&](Entity e, OcclusionArea& a) {
        if (!entity_active_in_scope(world, fr.scopeRoot, e)) return;
        if (a.areaId < 1 || a.areaId > 65535) {
            if (warnedPortalEntities.insert({e.bits(), kBadAreaId}).second)
                FA_WARN("render",
                        "OcclusionArea.areaId is {} on '{}', but an area id must be 1..65535 (0 is \"outside every area\", "
                        "the id every mesh in no area has). Hint: give the room an id from 1 up; until then this area is "
                        "ignored.",
                        a.areaId, world.id_of(e));
            return;
        }
        areas.push_back(make_portal_area(a.areaId, world.drawn_matrix(e), a.size, e.bits()));
    });
    if (areas.empty()) return;  // every area is off or invalid: nothing is culled, nothing is counted
    std::vector<std::string> ids;
    {
        std::vector<std::int32_t> sorted;
        for (const PortalAreaBox& a : areas) sorted.push_back(a.id);
        std::sort(sorted.begin(), sorted.end());
        sorted.erase(std::unique(sorted.begin(), sorted.end()), sorted.end());
        for (std::int32_t id : sorted) ids.push_back(std::to_string(id));
    }
    auto exists = [&](std::int32_t id) {
        return id == 0 || std::any_of(areas.begin(), areas.end(), [&](const PortalAreaBox& a) { return a.id == id; });
    };
    std::vector<PortalBox> portals;
    world.each<OcclusionPortal>([&](Entity e, OcclusionPortal& p) {
        if (!entity_active_in_scope(world, fr.scopeRoot, e)) return;
        bool bad = false;
        for (const std::int32_t id : {p.areaA, p.areaB}) {
            if (exists(id)) continue;
            bad = true;
            if (warnedPortalEntities.insert({e.bits(), std::int64_t(id)}).second)
                FA_WARN("render",
                        "OcclusionPortal on '{}' names area {}, but no OcclusionArea has that areaId. {} Hint: set "
                        "OcclusionPortal.areaA/areaB to the areaId of an OcclusionArea (0 = outside every area); this portal "
                        "connects nothing until then.",
                        world.id_of(e), id, did_you_mean(std::to_string(id), ids));
        }
        if (p.areaA == p.areaB) {
            if (warnedPortalEntities.insert({e.bits(), kSameArea}).second)
                FA_WARN("render",
                        "OcclusionPortal on '{}' has areaA and areaB both {}: it connects an area to itself and does "
                        "nothing. Hint: set areaA and areaB to the two areas the opening joins (0 = outside).",
                        world.id_of(e), p.areaA);
            bad = true;
        }
        if (bad) return;
        PortalBox b;
        b.areaA = p.areaA;
        b.areaB = p.areaB;
        b.model = world.drawn_matrix(e);
        b.size = p.size;
        b.open = p.open;
        b.entity = e.bits();
        portals.push_back(b);
    });

    const std::int32_t start = portal_area_at(areas, fr.cam.position);
    const PortalWalk walk = portal_walk(portals, fr.cam.viewProj, start);
    stats.portalsVisited += walk.portalsVisited;
    if (walk.capped) return;  // the walk was cut short: draw everything rather than hide what may be seen
    int culled = 0;
    for (MeshItem& mi : meshes) {
        if (!mi.visible || mi.noCull) continue;
        const Vec3 centre = mi.model.transform_point((mi.bmin + mi.bmax) * 0.5f);
        const std::vector<std::int32_t> in = portal_areas_of_point(areas, centre);
        const bool seen = std::any_of(in.begin(), in.end(), [&](std::int32_t id) {
            return std::binary_search(walk.reached.begin(), walk.reached.end(), id);
        });
        if (!seen) {
            mi.visible = false;
            ++culled;
        }
    }
    stats.meshesCulledByArea += culled;
}

}  // namespace fa
