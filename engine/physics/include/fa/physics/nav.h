// Navigation for 3D ground: results of Physics::nav_bake / nav_find_path (the `nav.bake` and `nav.find_path` commands,
// `nav.findPath` in scripts). docs/NAVIGATION.md is the guide.
//
// The NavMesh3D component marks a box of the level. It is baked from the STATIC colliders inside the box (no RigidBody3D,
// or a static one; triggers, Collider3D.navObstacle and Collider3D.navWalkable ones are left out) into a 2.5D grid of spans: every cell of
// NavMesh3D.cellSize holds the walkable surfaces in its column. A surface is walkable when it is not steeper than
// maxSlope, has agentHeight of free space above it and is at least agentRadius from a wall or a drop. Neighbouring
// cells connect when their surfaces differ by at most stepHeight. A polygon mesh can replace the grid later without
// changing this API: paths are lists of points on the walkable surface.
//
// Determinism: the bake and every search use fixed iteration orders and total tie-breaks, so the same colliders give
// the same cells and the same path on every run; nothing in a result depends on time.
#pragma once

#include <string>
#include <utility>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"
#include "fa/scene/world.h"

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
    int links = 0;                // NavLink3D joined to walkable cells on both ends
    int walkableBodies = 0;       // moving bodies (Collider3D.navWalkable) whose top surface is part of the mesh right now
    Json to_json() const;
};

struct NavPathOptions {
    float radius = -1.0f;   // agent radius of this query; < 0 = the mesh's. Larger than NavMesh3D.agentRadius is an error.
    float snap = -1.0f;     // how far (meters) a start or goal off the walkable cells is moved onto the nearest one; < 0 = default
    bool closest = false;   // goal unreachable: return the path to the reachable point nearest to it (complete = false)
    std::string mesh;       // id of the entity with the NavMesh3D to use; empty = the first enabled one that fits
};

// An off-mesh link (NavLink3D) a path takes: points[point] is where it starts, points[point + 1] where it ends.
struct NavPathLink {
    int point = 0;
    std::string entity;
};

struct NavPath {
    bool found = false;      // points holds a path
    bool complete = true;    // false: only a path to the reachable point nearest the goal (options.closest)
    std::vector<Vec3> points;  // from the start to the goal on the walkable surface; few corners (string pulled)
    std::vector<NavPathLink> links;  // the off-mesh links the path takes, in order
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
    bool moving = false;  // top surface of a walkable moving body (Collider3D.navWalkable)
    int region = 0;
};

// One NavLink3D, for debug drawing.
struct NavLinkDraw {
    Vec3 from, to;
    bool bidirectional = true;
    bool connected = true;  // both ends found walkable cells
    std::string entity;
};

// ---------------------------------------------------------------------------------------------------------------------
// Tile paths (`nav.find_tile_path`, `nav.findTilePath`): A* over the cells of a Tilemap or of a plain cost grid. Cells are
// (col, row), row 0 = the TOP row, the same as Tilemap. Same determinism as the 3D search: the open list breaks ties by
// (f, h, cell index), so one query gives one path on every run.

struct NavTileGrid {
    int width = 0, height = 0;
    std::vector<float> cost;   // width * height, row-major: the cost of ENTERING the cell (>= 0); < 0 = blocked
    Vec2 origin{0, 0};         // local position of the grid's top-left corner
    Vec2 cellSize{1, 1};       // cell (col, row) is centred at origin + ((col + 0.5) * cellSize.x, -(row + 0.5) * cellSize.y)
};

struct NavTileOptions {
    bool diagonals = false;          // 8 neighbours instead of 4; a diagonal step costs sqrt(2) times the cell entered, and
                                     // never cuts a corner: both cells it passes between must be open
    int maxNodes = 100000;           // cells the search may expand before it gives up (reason too_far)
    bool closest = false;            // goal unreachable: return the path to the reachable cell nearest to it (complete = false)
    bool allowBlockedGoal = false;   // a goal cell that is blocked can still be entered (at its cost, or 1 when blocked)
};

struct NavTilePath {
    bool found = false;
    bool complete = true;                      // false: only the path to the cell nearest the goal (options.closest)
    std::vector<std::pair<int, int>> cells;    // (col, row) from the start to the end, both included
    float cost = 0.0f;                         // summed entering costs along the path
    float length = 0.0f;                       // distance along the cell centres (grid local units)
    std::string reason;                        // when !found: start_off_map, goal_off_map, goal_blocked, blocked or too_far
    std::string message, hint;
};

NavTilePath nav_find_tile_path(const NavTileGrid& grid, int fromCol, int fromRow, int toCol, int toRow,
                               const NavTileOptions& options = {});

// The whole `nav.find_tile_path` command and `nav.findTilePath` call: `args` = {tilemap: entity id | grid: {width, height,
// cost, origin?, cellSize?}, from: [col,row], to: [col,row], costs?: {"<tile index>": cost | null}, diagonals?, maxNodes?,
// closest?, allowBlockedGoal?}. The result is {found, complete, cells: [[col,row]...], points: [[x,y]...], cost, length,
// reason?, message?, hint?}; points are WORLD positions for a tilemap (the entity's transform applied) and grid-local
// ones for a grid. A bad argument is an Error; "no route" is found:false.
Result<Json> nav_tile_query(World& world, const Json& args);

// A Tilemap as a cost grid: tiles in `solidTiles` are blocked, every other cell (empty ones included) costs 1, and `costs`
// ({"<tile index>": cost | null}, null or negative = blocked, key "-1" = empty cells) overrides either rule.
NavTileGrid nav_tile_grid_from_tilemap(const Tilemap& tm, const Json& costs);

}  // namespace fa
