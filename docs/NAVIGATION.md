# Navigation: paths over 3D ground

Characters that chase, patrol or walk to a tapped point need a route over the level: around walls, up ramps, never up a
step they cannot climb. The engine bakes one from the colliders you already have. No extra tool, no third-party library.

## 1. Set it up

Add a `NavMesh3D` to an entity (usually an empty `navmesh` entity) and size it to cover the walkable level:

```json
{"id":"navmesh","components":{"Transform":{"position":[0,5,0]},"NavMesh3D":{"size":[60,12,60],"agentRadius":0.35,"agentHeight":1.8,"stepHeight":0.4,"maxSlope":45}}}
```

The box is centred on the entity's world position (`size` is in meters; scale and rotation are ignored). It is baked from
the **static** 3D colliders inside it: a `Collider3D` with no `RigidBody3D`, or with a static one. Triggers, dynamic and
kinematic bodies, characters and colliders with `navObstacle` are left out of the bake. The bake runs by itself when the
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

Result: `{found:true, points:[[x,y,z],...], length, complete, from, to, mesh}`. The points are few corners on the ground
(A* with deterministic tie-breaking, then string pulling); walking straight from one to the next stays on walkable cells.
`from`/`to` are the feet of the agent.

When there is no route the result is `found:false` and teaches (it is a result, not an exception):

- `start_off_mesh` / `goal_off_mesh`: the point is not on walkable ground. A point within `snap` meters (default
  `agentRadius` + 2 cells) of walkable ground is moved onto it; otherwise `nearest` and `nearestDistance` say where the
  nearest walkable point is, and `message` says if the point is outside the box.
- `disconnected`: the two are in different walkable areas (a wall, a drop, a step above `stepHeight`, a slope above
  `maxSlope`, a gap narrower than `2 * agentRadius`), or a moving obstacle blocks the way right now. Pass
  `{closest: true}` to walk to the reachable point nearest the goal instead (`complete:false`).

`radius` larger than the `agentRadius` the mesh was baked for is an **error** (not a result): a wider agent would be stuck
in cells that were only cleared for a thinner one. Bake for the bigger agent: add a second `NavMesh3D` (same size and
position) with the larger `agentRadius` and pass its id as `mesh`. With several meshes the query uses the first enabled one
that contains `from` and is wide enough.

## 3. Moving obstacles

A gate, a crate or a door that moves must not be baked into the ground. Mark its collider `navObstacle: true`: it is left
out of the static bake and blocks the cells it covers (plus `agentRadius`) each time it moves. Only the cells it left and
entered are re-marked, so it is cheap per frame. A closed gate then gives `disconnected` and an open one a path.

## 4. Checking the result

- `nav.info` lists each mesh with its bounds, bake state, stats and whether the colliders changed since the last bake
  (`staleSinceBake`, with `autoBake` off).
- `nav.bake` returns `{mesh, cellsX, cellsZ, cells, spans, walkableCells, regions, obstacles}`. There is no timing in it: two
  bakes of the same level give the same numbers, the same cells and the same paths on every run and machine.
  `regions` is the number of separate walkable areas; a level you expect to be connected with `regions` > 1 has a gap.
- Editor: **Window > Show navmesh** draws the walkable cells over the 3D viewport (green; red where a moving obstacle
  blocks). Cells missing next to walls are the `agentRadius` margin.

## 5. Limits

- The bake sees colliders, not meshes: a floor without a `Collider3D` is not ground. Triangle-mesh colliders work
  (static only), including multi-level ones.
- Dynamic bodies (crates you push) are not in the bake: use `navObstacle` for the ones that matter.
- Doors, one-way drops and jump links are not modelled. Plan: an off-mesh link list on `NavMesh3D`.
- Characters are not steered around each other; `nav.findPath` is a route, avoiding other agents is up to the game.
- The API is independent of the grid: a polygon mesh can replace it later without changing scripts.
