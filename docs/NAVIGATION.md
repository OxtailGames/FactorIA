# Navigation: paths over 3D ground, and over tile maps

(2D tile maps: see section 7, `nav.findTilePath`; everything before it is the 3D NavMesh.)

Characters that chase, patrol or walk to a tapped point need a route over the level: around walls, up ramps, never up a
step they cannot climb. The engine bakes one from the colliders you already have. No extra tool, no third-party library.

## 1. Set it up

Add a `NavMesh3D` to an entity (usually an empty `navmesh` entity) and size it to cover the walkable level:

```json
{"id":"navmesh","components":{"Transform":{"position":[0,5,0]},"NavMesh3D":{"size":[60,12,60],"agentRadius":0.35,"agentHeight":1.8,"stepHeight":0.4,"maxSlope":45}}}
```

The box is centred on the entity's world position (`size` is in meters; scale and rotation are ignored). It is baked from
the **static** 3D colliders inside it: a `Collider3D` with no `RigidBody3D`, or with a static one. Triggers, dynamic and
kinematic bodies, characters and colliders with `navObstacle` or `navWalkable` are left out of the bake. The bake runs by itself when the
scene loads and again whenever a static collider inside the box changes (`autoBake`, on by default); `nav.bake` does it on
demand.

| Field | Meaning |
|---|---|
| `size` | Bounds of the baked box, meters. Keep it as small as the level: the cost grows with `size.x * size.z / cellSize^2` (limit 4 million cells). |
| `cellSize` | Width of a grid cell (0.25 m). Smaller = finer paths through narrow gaps, slower bake. |
| `cellHeight` | Vertical resolution (0.05 m). |
| `agentRadius` | Walkable cells keep at least this far from walls and drops (0.3 m). |
| `agentHeight` | Ground with less free space above it is not walkable (1.8 m). |
| `stepHeight` | Neighbouring cells connect when their surfaces differ by at most this (0.4 m). |
| `maxSlope` | Surfaces steeper than this many degrees are not walkable (45). |
| `autoBake`, `enabled` | Rebake by itself / switch the mesh off. |
| `walkableCells`, `regions` | Read-only results of the last bake. |

How it works: a 2.5D grid. Every cell column holds the walkable surfaces in it (a bridge and the road under it are two).
A surface is kept when it is not steeper than `maxSlope`, has `agentHeight` of room above and is `agentRadius` from a wall
or a drop. Neighbours (8 directions, no cutting corners) connect when they differ by at most `stepHeight`. Paths keep
`agentRadius` from walls to within about half a cell.

## 2. Find a path

Scripts:

```js
import { Behaviour, nav, world } from "factoria";
export default class Guard extends Behaviour {
  onFixedUpdate(dt) {
    const p = nav.findPath(this.entity.position, world.find("player").position, { radius: 0.3 });
    if (!p.found) return;                 // p.reason / p.message / p.hint say why
    const next = p.points[1] ?? p.points[0];   // points[0] is where we stand; walk straight to the next corner
    // ... move towards `next` (physics.moveCharacter, or set the position)
  }
}
```

Commands (agents, tools): `nav.find_path {"from":[0,0,0],"to":[10,0,5],"radius":0.3}`, `nav.bake {"mesh":"navmesh"}` and
`nav.info`.

Result: `{found:true, points:[[x,y,z],...], links?, length, complete, from, to, mesh}`. The points are few corners on the ground
(A* with deterministic tie-breaking, then string pulling); walking straight from one to the next stays on walkable cells.
`from`/`to` are the feet of the agent.

When there is no route the result is `found:false` and teaches (it is a result, not an exception):

- `start_off_mesh` / `goal_off_mesh`: the point is not on walkable ground. A point within `snap` meters (default
  `agentRadius` + 2 cells) of walkable ground is moved onto it; otherwise `nearest` and `nearestDistance` say where the
  nearest walkable point is, and `message` says if the point is outside the box.
- `disconnected`: the two are in different walkable areas (a wall, a drop, a step above `stepHeight`, a slope above
  `maxSlope`, a gap narrower than `2 * agentRadius`), a moving obstacle blocks the way right now, a moving platform
  (`navWalkable`) is away, or the only link is one-way. Pass
  `{closest: true}` to walk to the reachable point nearest the goal instead (`complete:false`).

`radius` larger than the `agentRadius` the mesh was baked for is an **error** (not a result): a wider agent would be stuck
in cells that were only cleared for a thinner one. Bake for the bigger agent: add a second `NavMesh3D` (same size and
position) with the larger `agentRadius` and pass its id as `mesh`. With several meshes the query uses the first enabled one
that contains `from` and is wide enough.

## 3. Moving obstacles

A gate, a crate or a door that moves must not be baked into the ground. Mark its collider `navObstacle: true`: it is left
out of the static bake and blocks the cells it covers (plus `agentRadius`) each time it moves. Only the cells it left and
entered are re-marked, so it is cheap per frame. A closed gate then gives `disconnected` and an open one a path.

## 4. Off-mesh links: jumps, climbs and drops

Walkable cells never join two places that are a gap, a wall or a high ledge apart. A `NavLink3D` does: put it on an entity
at the place where the jump or climb starts, and set `end` to the world position where it ends.

```json
{"id":"jump_gap","components":{"Transform":{"position":[-5,0,0]},"NavLink3D":{"end":[5,0,0],"bidirectional":true,"cost":2}}}
```

| Field | Meaning |
|---|---|
| (entity position) | Where the link starts, in world space. |
| `end` | Where it ends, in world space. |
| `bidirectional` | `true` (default): usable both ways. `false`: only from the entity to `end` (a drop, a jump you cannot climb back). |
| `cost` | Extra path length in meters on top of the straight distance. Raise it so paths prefer walking when that is not much longer. |

Both ends are moved onto the nearest walkable cell (within `agentRadius` + 2 cells horizontally, about `stepHeight` up and
`agentHeight` down); a link with an end off the mesh is ignored and `nav.info` lists it with `connected: false`. Links are
resolved again by themselves when the entity moves, `end` changes or the entity is deactivated, with no rebake. The areas
a link joins count as one in `regions`, even when the link is one-way.

`nav.findPath` may take a link, and the result says where: `links: [{point, entity}]` (absent when the path takes none).
`points[point]` is where the link starts and `points[point + 1]` where it ends; walk to the first, then jump, climb or
teleport to the second yourself (the path does not draw the jump), and keep following the path from there:

```js
const p = nav.findPath(this.entity.position, goal);
const link = p.links?.find((l) => l.point === 0);   // the next step is a link
if (link) this.startJump(p.points[1]);              // play the jump to points[1]
```

A path is never straightened across a link: the corners before and after it are kept.

## 5. Walkable moving bodies

A rope-bridge plank, a seesaw, a lift or a moving platform is not static ground, but a character walks on it. Mark its
collider `navWalkable: true` (on a kinematic body, or a body held by a joint). It is left out of the static bake like
`navObstacle`, and instead:

- its **top surface** is added to the mesh as walkable cells wherever the body is now (surfaces steeper than `maxSlope`
  are not walkable);
- each time it moves, only the cells it left and entered are re-marked, and the erosion near them is redone, so a
  body that is at rest costs nothing and a moving one costs in proportion to the cells it touches;
- the cells join the ground and each other within `stepHeight`, and keep `agentRadius` from the edge of the body, so a
  plank must be about three cells wide (0.75 m with the defaults) to be walkable;
- the static ground under the body is blocked while it is there.

A platform that docks against two cliffs gives a path across; when it is away `nav.findPath` answers `disconnected`
(`message` mentions `navWalkable`). A lift, a bridge or a seesaw therefore needs no special code: query again when the
character may have to cross. `Collider3D.navWalkable` wins over `navObstacle` when both are set.

## 6. Checking the result

- `nav.info` lists each mesh with its bounds, bake state, stats, whether the colliders changed since the last bake
  (`staleSinceBake`, with `autoBake` off), its `links` (entity, ends, `connected`) and its `walkableBodies`.
- `nav.bake` returns `{mesh, cellsX, cellsZ, cells, spans, walkableCells, regions, obstacles, links, walkableBodies}`.
  There is no timing in it: two bakes of the same level give the same numbers, the same cells and the same paths on
  every run and machine. `regions` is the number of separate walkable areas (links count, walkable bodies do not, since
  they move); a level you expect to be connected with `regions` > 1 has a gap.
- Editor: **Window > Show navmesh** draws the walkable cells over the 3D viewport (green; red where a moving obstacle
  blocks; blue on a walkable moving body) and the off-mesh links as yellow lines (an arrowhead on a one-way one; grey when
  an end is off the mesh). Cells missing next to walls are the `agentRadius` margin.

## 7. Tile paths (2D grids)

`nav.findTilePath(map, from, to, opts)` is A* over the cells of a `Tilemap` (or of your own grid), for top-down and
platformer maps where the 3D NavMesh does not apply. It needs no bake: it reads the tiles at the moment of the call, so a
tile written with `entity.tilemap.setTile` is part of the next search.

```js
import { Behaviour, nav, world } from "factoria";
export default class Rat extends Behaviour {
  onStart() { this.ground = world.find("ground"); }
  chase(from, to) {                      // cells: { col, row } or [col, row], 0-based, row 0 = the TOP row
    const p = nav.findTilePath(this.ground, from, to, { diagonals: true, costs: { 7: 5, 9: Infinity } });
    if (!p.found) return null;           // p.reason / p.message / p.hint say why
    return p.points[1] ?? p.points[0];   // the world position of the next cell centre; points[0] is the start cell
  }
}
```

- `map`: an entity with a `Tilemap` (or its id), or a grid `{width, height, cost, origin?, cellSize?}`. For a grid, `cost` is
  a flat array of `width * height` numbers, row-major, row 0 = top: the cost of ENTERING that cell (1 = a normal step, 0 or more).
  `Infinity`, a negative number, `null` or `undefined` blocks it. Use a grid when the real map is not a Tilemap (the Tilemap
  is only the drawn copy of a map the game keeps in its own arrays).
- A Tilemap: tiles listed in `solidTiles` block, every other cell (empty ones too) costs 1. `opts.costs` changes that per tile
  index (flip flags ignored): `{7: 5}` makes tile 7 cost 5, `{9: Infinity}` blocks tile 9, `{3: 1}` makes a solid tile 3
  walkable, key `-1` is for empty cells. There is deliberately no per-cell JS callback (it would call the script engine for
  every cell and the `nav.find_tile_path` command could not take one): put the rules in `costs` or build the grid with them.
  For a changing rule, build the `cost` array yourself.
- 4-way by default. `diagonals: true` allows 8-way: a diagonal step costs sqrt(2) times the cell it enters and never cuts a
  corner: both cells it passes between (the two orthogonal neighbours) must be open.
- The start cell is always allowed. A blocked goal answers `goal_blocked` unless `allowBlockedGoal: true` (the path then
  ends ON it, entering at cost 1: chase something that stands on a wall) or `closest: true`.
- `closest: true`: when the goal cannot be reached, the result is the path to the reachable cell nearest the goal (straight
  distance), `found: true, complete: false` (a path of just the start cell when the start is already the nearest).
- `maxNodes` (default 100000) bounds the cells the search expands; past it the result is `too_far`.
- Result: `{found, complete, cells: [{col, row}], points: [Vec2], cost, length}`. `cells` are the path including start and end.
  `points` are the cell centres in the WORLD (the Tilemap entity's position, rotation and scale applied; the map's top-left
  corner is the entity's position, +Y up, as in the Tilemap docs). For a grid, a centre is `origin + ((col + 0.5) * cellW,
  -(row + 0.5) * cellH)` with `origin` default (0, 0) and `cellSize` default 1. `cost` sums the entering costs; `length` is
  the distance along the cell centres in the map's own units (`tileSize` for a Tilemap, `cellSize` for a grid, before the entity's scale).
- No route is a result, not an exception: `found: false` with `reason` (`start_off_map`, `goal_off_map`, `goal_blocked`,
  `blocked`, `too_far`), `message` and `hint`. A map that is not a Tilemap or a grid, or a malformed cell, throws.
- Deterministic: the open list breaks ties by (f, h, cell index), so the same map and query give the same path on every run.
- `nav.tileVersion(tilemap)` is a counter that goes up whenever the tiles of that Tilemap change, to tell that a path you
  kept is stale: `setTile` / `tilemap.set_tile`, and any write that replaces `tiles` (a script assigning `tilemap.tiles`,
  `scene.set_component`, an editor edit). A call hashes the tiles once, so ask when you need a decision,
  not for every cell; the count starts at 0 on every scene load. For your own grid, keep your own counter.

Command (agents, tools): `nav.find_tile_path {"tilemap":"ground","from":[0,1],"to":[3,1],"diagonals":true,"costs":{"7":5,"9":null}}`
or `{"grid":{"width":3,"height":2,"cost":[1,1,null,1,1,1]},"from":[0,0],"to":[2,1]}`; the result is the same object with
`cells` as `[col, row]` pairs and `points` as `[x, y]`, and `null` (not `Infinity`) blocks.

## 8. Limits of the 3D NavMesh

- The bake sees colliders, not meshes: a floor without a `Collider3D` is not ground. Triangle-mesh colliders work
  (static only), including multi-level ones.
- Dynamic bodies (crates you push) are not in the bake: use `navObstacle` for the ones that matter.
- A link is a straight hop between two cells; the path does not animate it, and a link end on a walkable moving body is
  not supported (ends are found on the baked ground).
- A walkable body has no ceiling check (a platform under a low roof is walkable), and a `navObstacle` that sits on one is
  blocked only after the obstacle itself moves.
- Characters are not steered around each other; `nav.findPath` is a route, avoiding other agents is up to the game.
- The API is independent of the grid: a polygon mesh can replace it later without changing scripts.
