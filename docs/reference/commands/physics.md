[Back to the index](../README.md)

# Commands: physics

## `nav.bake`

Not released yet (on main after 0.2.0).

Bake the NavMesh3D walkable grid from the static 3D colliders and return its stats.

A NavMesh3D component marks a box of the level. Baking voxelizes the static colliders inside it (no RigidBody3D or a static one; triggers, Collider3D.navObstacle and Collider3D.navWalkable colliders are left out; navWalkable ones are added as moving cells) into a grid of walkable cells: not steeper than maxSlope, agentHeight of room above, agentRadius from walls and drops, neighbours joined when they differ by at most stepHeight. It is baked by itself when the scene loads and when the colliders change (autoBake); call this to bake on demand, for example with autoBake off. mesh = id of the entity with the NavMesh3D; omitted = every enabled one. Result: a list of {mesh, cellsX, cellsZ, cells, spans, walkableCells, regions, obstacles, links, walkableBodies}; NavLink3D entities add off-mesh links; no timing, so the same level gives the same result. Example: nav.bake {"mesh":"navmesh"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `mesh` | string | no | Id of the entity with the NavMesh3D to bake; omitted = all enabled ones. |

## `nav.find_path`

Not released yet (on main after 0.2.0).

Find a walkable path between two 3D points on the baked NavMesh3D.

A* over the walkable grid, then string pulling: the result is few corner points from `from` to `to` on the walkable surface (meters). Result {found:true, points:[[x,y,z],...], length, complete, links?:[{point, entity}], from, to, mesh} or {found:false, reason, message, hint}: reason is start_off_mesh / goal_off_mesh (not on walkable ground; nearest and nearestDistance say where the nearest walkable point is) or disconnected (the two are in different walkable areas, a moving obstacle blocks the way, or a navWalkable platform is away). A start or goal within `snap` meters of walkable ground is moved onto it. closest=true returns a path to the reachable point nearest the goal (complete=false) instead of failing when disconnected. radius = agent radius of this query; larger than the NavMesh3D.agentRadius it was baked for is an error: bake for the bigger agent (a second NavMesh3D). mesh = id of the NavMesh3D entity; omitted = the first enabled one that contains `from`. Scripts: nav.findPath(from, to, {radius}). Example: nav.find_path {"from":[0,0,0],"to":[10,0,5]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | array | yes | Start point [x,y,z] in meters (the agent's feet). |
| `to` | array | yes | Goal point [x,y,z] in meters. |
| `radius` | number | no | Agent radius for this query; must not exceed NavMesh3D.agentRadius. Default: the mesh's. |
| `snap` | number | no | How far (meters) a start or goal off the walkable cells is moved onto the nearest one. Default: agentRadius + 2 cells. |
| `closest` | boolean | no | When the goal is unreachable, return a path to the reachable point nearest to it (complete=false). |
| `mesh` | string | no | Id of the entity with the NavMesh3D to use. Default: the first enabled one that contains `from`. |

## `nav.find_tile_path`

Not released yet (on main after 0.2.0).

Find a path over the cells of a Tilemap (or a plain cost grid) with A*.

Cells are (col, row), 0-based, row 0 = the top row. Pass `tilemap` (id of an entity with a Tilemap: tiles in solidTiles block, every other cell costs 1, `costs` {"<tile index>": cost | null} overrides per tile, null = blocked, key "-1" = empty cells) OR `grid` {width, height, cost: [..row-major..], origin?, cellSize?} (cost = the cost of entering a cell, >= 0; null or negative = blocked). Steps are 4-way; diagonals=true allows 8-way and a diagonal never cuts a corner (both cells it passes between must be open). The start cell is always allowed; a blocked goal fails with goal_blocked unless allowBlockedGoal=true (it is then entered at cost 1) or closest=true. closest=true returns the path to the reachable cell nearest the goal (complete=false) when the goal cannot be reached; maxNodes bounds the search (reason too_far). Result {found, complete, cells:[[col,row]..], points:[[x,y]..] (cell centres: WORLD positions for a tilemap, origin + (col+0.5, -(row+0.5)) * cellSize for a grid), cost, length} or {found:false, reason: start_off_map | goal_off_map | goal_blocked | blocked | too_far, message, hint}. Deterministic. Scripts: nav.findTilePath(map, from, to, opts); a script that asks many times on one map keeps it with nav.createGrid (the command is stateless: it reads the map you give it on every call). nav.flow_field is the one-to-many form. Example: nav.find_tile_path {"tilemap":"ground","from":[0,0],"to":[5,3],"diagonals":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `tilemap` | string | no | Id of the entity with the Tilemap. Give this or `grid`. |
| `grid` | object | no | A plain grid: {width, height, cost: [width*height numbers, row-major, row 0 = top; null or negative = blocked], origin?: [x,y] top-left corner, cellSize?: number \| [w,h]}. |
| `from` | array | yes | Start cell [col,row]. |
| `to` | array | yes | Goal cell [col,row]. |
| `costs` | object | no | Tilemap only: cost of entering a cell by tile index, {"3": 2.5, "7": null}; null or negative blocks, a solid tile listed here is walkable. |
| `diagonals` | boolean | no | Allow 8-way steps (no corner cutting). Default false. |
| `maxNodes` | integer | no | Most cells the search expands before it gives up (too_far). Default 100000. |
| `closest` | boolean | no | Goal unreachable: return the path to the nearest reachable cell (complete=false). |
| `allowBlockedGoal` | boolean | no | A blocked goal cell can still be entered (cost 1). |

## `nav.flow_field`

Not released yet (on main after 0.2.0).

Distance field over the cells of a Tilemap (or a plain cost grid) from one or more goal cells.

The cost of the cheapest route from every cell to the nearest goal, with the same rules as nav.find_tile_path (entering a cell costs its cost, 4-way or diagonals=true, no corner cutting, null or negative blocks). A blocked goal is entered at cost 1. Pass `tilemap` or `grid` like nav.find_tile_path, `goals` [[col,row],...] and optionally `from`. Result {width, height, distance: [width*height numbers, row-major, row 0 = top; null where no goal can be reached]} and, with `from`: {reachable, cost, next: [col,row] | null (the cell to walk to; null at a goal or when unreachable), path: [[col,row]...] (from `from` to the goal it reaches)}. Deterministic. Scripts: nav.flowField(grid, goals) keeps the field and answers field.stepToward(col, row) in O(1). Example: nav.flow_field {"tilemap":"ground","goals":[[9,4]],"from":[0,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `tilemap` | string | no | Id of the entity with the Tilemap. Give this or `grid`. |
| `grid` | object | no | A plain grid: {width, height, cost: [width*height numbers, row-major, row 0 = top; null or negative = blocked], origin?: [x,y], cellSize?: number \| [w,h]}. |
| `goals` | array | yes | Goal cells [[col,row],...]; at least one. |
| `from` | array | no | A cell to read the next step and the path for. |
| `costs` | object | no | Tilemap only: cost of entering a cell by tile index, {"3": 2.5, "7": null}; null or negative blocks. |
| `diagonals` | boolean | no | Allow 8-way steps (no corner cutting). Default false. |

## `nav.info`

Not released yet (on main after 0.2.0).

List the NavMesh3D components with their bounds, agent size, bake state and stats.

Use it to check that a level was baked and how much of it is walkable. Result: a list of {mesh, enabled, autoBake, baked, error?, boundsMin, boundsMax, cellSize, agentRadius, agentHeight, stepHeight, maxSlope, staleSinceBake, stats} (stats include links and walkableBodies). staleSinceBake is true when the colliders changed after the last bake of a mesh with autoBake off (call nav.bake).

## `physics.raycast`

Cast a ray against colliders (2D segment or 3D ray) and return the first hit.

2D: {from:[x,y], to:[x,y]}. 3D: {dimension:"3d", origin:[x,y,z], direction:[x,y,z], maxDistance}. Options, the same as physics.shape_cast and the script API physics.raycast(a, b, {mask, ignore, ignoreTriggers}): mask = collision layer bit mask (bit i = layer i, -1 = all layers); ignore = id (or name) of an entity whose colliders, and its children's, are skipped (usually the caster, so a ray starting at a body's edge does not hit the body itself); ignoreTriggers (default true) skips trigger colliders, false hits them too. A collider that contains the ray origin is always skipped. Result: {hit:false} or {hit:true, entity, point, normal, distance}. Example: physics.raycast {"from":[0,300],"to":[0,-300],"ignore":"player","ignoreTriggers":false}

| Argument | Type | Required | Description |
|---|---|---|---|
| `dimension` | string ["2d","3d"] | no |  Default "2d". |
| `from` | array | no | 2D start [x,y]. |
| `to` | array | no | 2D end [x,y]. |
| `origin` | array | no | 3D origin [x,y,z]. |
| `direction` | array | no | 3D direction. |
| `maxDistance` | number | no |  Default 1000. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

## `physics.raycast_all`

Not released yet (on main after 0.2.0).

Cast a ray against colliders (2D segment or 3D ray) and return EVERY hit, nearest first.

Same arguments and options as physics.raycast, plus maxHits (default 32, the nearest ones are kept). Use it to see everything between two points (what hides a character from the camera), or to click through colliders that only exist to be faded. A collider with enabled=false is never reported. Result: {count, hits:[{entity, point, normal, distance}]} sorted by distance. Example: physics.raycast_all {"dimension":"3d","origin":[0,2,0],"direction":[0,0,-1],"maxDistance":20,"maxHits":4}

| Argument | Type | Required | Description |
|---|---|---|---|
| `dimension` | string ["2d","3d"] | no |  Default "2d". |
| `from` | array | no | 2D start [x,y]. |
| `to` | array | no | 2D end [x,y]. |
| `origin` | array | no | 3D origin [x,y,z]. |
| `direction` | array | no | 3D direction. |
| `maxDistance` | number | no |  Default 1000. |
| `maxHits` | integer | no | At most this many hits (the nearest). Default 32. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

## `physics.shape_cast`

Sweep a circle, sphere or box from one point to another and return the first collider it touches.

Like physics.raycast, but the shape has size: use it to ask whether a character fits or how far a box can move before it hits something. 2 numbers in from/to = 2D, 3 numbers = 3D. shape: 2D {"shape":"circle","radius":8} or {"shape":"box","size":[16,24]}; 3D {"shape":"sphere","radius":0.5} or {"shape":"box","size":[1,2,1]} (2D pixels, 3D meters, full sizes). The shape is centred on the cast position and axis-aligned. Result: {hit:false} or {hit:true, entity, point, normal, distance}: distance is how far the CENTRE travels before contact, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped (like a ray starting inside one); a collider it only touches blocks the cast only if it moves towards it. Options as for physics.raycast: mask; ignore = id of an entity whose colliders (and its children's) are skipped, usually the caster; triggers are skipped unless ignoreTriggers=false. Example: physics.shape_cast {"shape":{"shape":"box","size":[32,48]},"from":[0,100],"to":[0,-300],"ignore":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `shape` | object | yes | 2D: {shape:"circle",radius} or {shape:"box",size:[w,h]}. 3D: {shape:"sphere",radius} or {shape:"box",size:[x,y,z]}. |
| `from` | array | yes | Start of the shape's centre, [x,y] (2D) or [x,y,z] (3D). |
| `to` | array | yes | End of the shape's centre, same dimension as from. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

