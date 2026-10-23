// Navigation for 3D ground: results of Physics::nav_bake / nav_find_path (the `nav.bake` and `nav.find_path` commands,
// `nav.findPath` in scripts). docs/NAVIGATION.md is the guide.
//
// The NavMesh3D component marks a box of the level. It is baked from the STATIC colliders inside the box (no RigidBody3D,
// or a static one; triggers and Collider3D.navObstacle ones are left out) into a 2.5D grid of spans: every cell of
// NavMesh3D.cellSize holds the walkable surfaces in its column. A surface is walkable when it is not steeper than
// maxSlope, has agentHeight of free space above it and is at least agentRadius from a wall or a drop. Neighbouring
// cells connect when their surfaces differ by at most stepHeight. A polygon mesh can replace the grid later without
// changing this API: paths are lists of points on the walkable surface.
//
// Determinism: the bake and every search use fixed iteration orders and total tie-breaks, so the same colliders give
// the same cells and the same path on every run; nothing in a result depends on time.
#pragma once

#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"

namespace fa {

// What one bake produced (the `nav.bake` result). No timing: the result is the same on every run.
struct NavBakeStats {
    std::string mesh;             // id of the entity with the NavMesh3D
    int cellsX = 0, cellsZ = 0;   // grid size
    int cells = 0;                // cellsX * cellsZ
    int spans = 0;                // walkable surfaces before erosion by the agent's radius
    int walkableCells = 0;        // surfaces the agent can stand on (after erosion)
    int regions = 0;              // separate walkable areas (no path between two of them)
    int obstacles = 0;            // moving obstacles (Collider3D.navObstacle) blocking cells right now
    Json to_json() const;
};

struct NavPathOptions {
    float radius = -1.0f;   // agent radius of this query; < 0 = the mesh's. Larger than NavMesh3D.agentRadius is an error.
    float snap = -1.0f;     // how far (meters) a start or goal off the walkable cells is moved onto the nearest one; < 0 = default
    bool closest = false;   // goal unreachable: return the path to the reachable point nearest to it (complete = false)
    std::string mesh;       // id of the entity with the NavMesh3D to use; empty = the first enabled one that fits
};

struct NavPath {
    bool found = false;      // points holds a path
    bool complete = true;    // false: only a path to the reachable point nearest the goal (options.closest)
    std::vector<Vec3> points;  // from the start to the goal on the walkable surface; few corners (string pulled)
    float length = 0.0f;     // meters along the points
    Vec3 from, to;           // the start and goal as snapped onto the walkable surface
    std::string mesh;        // id of the NavMesh3D entity used
    // When !found:
    std::string reason;      // no_navmesh, start_off_mesh, goal_off_mesh or disconnected
    std::string message;     // what is wrong, with numbers
    std::string hint;        // how to fix it
    Vec3 nearest;            // reason start/goal_off_mesh: the nearest walkable point
    float nearestDistance = -1.0f;
    Json to_json() const;
};

// One walkable cell of a mesh (debug draw in the editor).
struct NavCell {
    Vec3 center;          // on the walkable surface
    float size = 0.25f;   // cell width
    bool blocked = false; // covered by a moving obstacle right now
    int region = 0;
};

}  // namespace fa
