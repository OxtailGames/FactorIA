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
    Mat4 inv;           // model.inverse(), made once by make_portal_box
    bool valid = true;  // false: a degenerate (zero scale) box that holds nothing
};

PortalBox make_portal_box(std::int32_t areaA, std::int32_t areaB, const Mat4& model, Vec3 size, bool open,
                          std::uint64_t entity);

struct PortalWalk {
    std::vector<std::int32_t> reached;  // the area ids the camera can see, sorted, the start included
    int portalsVisited = 0;             // distinct portals the walk went through
    bool capped =
        false;  // the depth or step cap was reached (the caller then culls nothing: a cut walk would hide what is visible)
};

// Where a walk starts: every area whose box holds `p` (the camera), plus areaA and areaB of every OPEN portal whose box holds it
// (a camera in a doorway, in the gap a wall leaves between two rooms, is in both rooms). Sorted, distinct; {0} when there is none.
std::vector<std::int32_t> portal_start_areas(const std::vector<PortalAreaBox>& areas,
                                             const std::vector<PortalBox>& portals, Vec3 p);

// Whether a mesh (its model matrix and model-space bounds) is drawn when the walk reached `reached` (sorted ids). The mesh belongs to
// EVERY area whose box its world bounds touch, and also to area 0 unless its bounds lie wholly inside one area box; it is hidden only
// when none of its areas was reached. No allocation.
bool portal_mesh_seen(const std::vector<PortalAreaBox>& areas, const std::vector<std::int32_t>& reached,
                      const Mat4& model, Vec3 bmin, Vec3 bmax);

// Walks from every area of `startAreas` (each with the whole picture) through the open portals as seen with `viewProj`. A camera that sees nothing of a portal does not go through it.
PortalWalk portal_walk(const std::vector<PortalBox>& portals, const Mat4& viewProj,
                       const std::vector<std::int32_t>& startAreas);

}  // namespace fa::render
