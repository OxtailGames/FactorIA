// Area and portal culling (M75.2, docs/BIG_WORLDS_LOD.md, "Areas and portals"): which areas the camera sees through open portals.
// Pure CPU, no World and no GPU: Renderer::Impl::portal_cull_meshes (renderer_portals.cpp) gathers the OcclusionArea and
// OcclusionPortal entities into the plain structs below and applies the answer to the meshes.
//
// The walk is classic portal culling. The camera's area is the start with the whole picture (the NDC rectangle [-1,1]^2) as its view;
// every open portal that touches the current area, whose oriented box lies in the current rectangle, leads to its other area with the
// rectangle narrowed to the portal's own screen rectangle. A rectangle of the same apex is exactly a narrowed frustum. Everything is
// conservative: a portal box that crosses the camera's near plane is clipped at the plane and never narrows below what is visible, so
// the walk may reach an area that is really hidden, never the reverse.
//
// Guards, all deterministic (counts, never time): a cycle is never entered (an area already on the current path), a path longer than
// kPortalMaxDepth portals, or more than kPortalMaxSteps portal tests, ends the walk with `capped` (the caller draws everything), and an area is re-entered only with a rectangle that no earlier visit of it contained.
#pragma once

#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa::render {

inline constexpr int kPortalMaxDepth = 32;
inline constexpr int kPortalMaxSteps = 4096;

struct PortalAreaBox {
    std::int32_t id = 0;       // OcclusionArea.areaId (1..65535)
    Mat4 model;                // the drawn matrix of the entity
    Vec3 size{1, 1, 1};        // before the matrix's scale
    std::uint64_t entity = 0;  // tie-break of equal volumes
    Mat4 inv;                  // model.inverse(), made once by make_portal_area
    bool valid = true;         // false: a degenerate (zero scale) box that holds nothing
};

PortalAreaBox make_portal_area(std::int32_t id, const Mat4& model, Vec3 size, std::uint64_t entity);

struct PortalBox {
    std::int32_t areaA = 0, areaB = 0;
    Mat4 model;
    Vec3 size{1, 1, 1};
    bool open = true;
    std::uint64_t entity = 0;
};

struct PortalWalk {
    std::vector<std::int32_t> reached;  // the area ids the camera can see, sorted, the start included
    int portalsVisited = 0;             // distinct portals the walk went through
    bool capped = false;                // the depth or step cap was reached (the caller then culls nothing: a cut walk would hide what is visible)
};

// The area that holds `p`: the one of the smallest volume (then the lowest entity bits); 0 when none holds it.
std::int32_t portal_area_at(const std::vector<PortalAreaBox>& areas, Vec3 p);

// The areas whose oriented box holds `p` (sorted, distinct ids); {0} when none does.
std::vector<std::int32_t> portal_areas_of_point(const std::vector<PortalAreaBox>& areas, Vec3 p);

// Walks from `startArea` through the open portals as seen with `viewProj`. A camera that sees nothing of a portal does not go through it.
PortalWalk portal_walk(const std::vector<PortalBox>& portals, const Mat4& viewProj, std::int32_t startArea);

}  // namespace fa::render
