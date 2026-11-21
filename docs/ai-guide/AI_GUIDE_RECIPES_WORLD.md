# AI guide: recipes for the world

Part of [AI guide](../AI_GUIDE.md): recipes 9.9 to 9.22: 3D scenes, save data, levels, particles, patrol AI, 3D cameras and physics, glow, sweeps, 2D water and glass.

### 9.9 3D scene with a light and fog

A camera, a sun and a floor (the `3d-empty` template has only the camera; add the rest):

```json
{
  "format": "factoria.scene/1",
  "settings": { "ambientLight": [0.3, 0.32, 0.38, 1], "skyColor": [0.45, 0.62, 0.85, 1] },
  "entities": [
    { "id": "camera", "components": {
        "Transform": { "position": [0, 3, 8], "rotation": [-15, 0, 0] },
        "Camera": { "projection": "perspective", "fov": 60, "primary": true } } },
    { "id": "sun", "components": {
        "Transform": { "position": [0, 10, 0], "rotation": [-50, -30, 0] },
        "Light": { "type": "directional", "intensity": 1.1, "castShadows": true } } },
    { "id": "floor", "components": {
        "Transform": { "position": [0, 0, 0], "scale": [20, 1, 20] },
        "MeshRenderer": { "mesh": "plane", "color": [0.35, 0.5, 0.35, 1] } } },
    { "id": "cube", "tags": ["spinner"], "components": {
        "Transform": { "position": [0, 1, 0] },
        "MeshRenderer": { "mesh": "cube", "color": [0.9, 0.45, 0.2, 1], "metallic": 0.1, "roughness": 0.5 } } }
  ]
}
```

- Shadows: a directional `Light` with `"castShadows": true` casts them. `MeshRenderer.castShadows` and `receiveShadows` (both default true) control each object.
- Fog: `settings.fogDensity` (0 = off) and `settings.fogColor` blend distant objects into the fog colour. `skyColor` and `horizonColor` paint the sky gradient behind a perspective camera.
- Lighting: `ambientLight` lights every surface evenly. Add point or spot lights with `type: "point"` or `"spot"` (no shadows yet).

Production 3D rendering (all automatic; there is nothing to switch on):

- **PBR materials.** `metallic` and `roughness` drive Cook-Torrance (GGX) lighting. Metal reflects the sky: the engine builds a small environment from `settings.skyColor` and `settings.horizonColor` (rougher surfaces see a blurrier sky), so a shiny sphere looks right with no environment asset. `ambientLight` still lights the diffuse side. Lighting happens in gamma space (colours are not linearised), as in older scenes. A scene with a cleared sky and a bright `skyColor` therefore gives plastic a faint sheen and metals a bright rim: lower `skyColor`/`horizonColor` for a dark scene.
- **Normal maps.** `MeshRenderer.normalMap` (a tangent-space map, glTF convention: +Y up, the usual blue-ish image) adds relief without triangles; `normalScale` (default 1) scales it, `uvScale` tiles it with the base texture. Primitives get their tangents from their UVs.
- **glTF materials.** A model's own `baseColorFactor`/texture, `metallicFactor`/`roughnessFactor`, `metallicRoughnessTexture`, `normalTexture`, `occlusionTexture`, `emissiveFactor`/`emissiveTexture` (and `KHR_materials_emissive_strength`) are all used, and so are the layers `KHR_materials_clearcoat`, `_sheen`, `_anisotropy`, `_specular` and `_ior` (the factors always; their textures are packed into the occlusion and metallic-roughness maps and what does not fit is a warning that names the file and the material: docs/rendering/RENDERING_LIGHTING.md, "The material layers"; `MeshRenderer.clearcoat`, `sheenColor`, `anisotropy`, `specular` and `ior` replace them when set). A glTF material's metallic and roughness replace `MeshRenderer.metallic`/`roughness` (those apply to primitives and to models without a material); `color` still tints the base color (of every material), `materialColors` (`{"Body": [0.2, 0.8, 0.7, 1]}`, keyed by the glTF material name) replaces the base color factor of ONE material so the others keep theirs (a typo in the name is a `factoria validate` error with a "did you mean"; built-in shapes ignore it), `emissive` adds to the glTF emission, and `normalMap` replaces the glTF normal map when set. Models without a TANGENT attribute get tangents generated from their UVs.
- **Many objects.** Meshes outside the camera frustum are not drawn. Meshes with the same `mesh`, textures and material values (`color`, `metallic`, `roughness`, `emissive`, `emissiveStrength`, `unlit`, `receiveShadows`, `uvScale`, `normalMap`, `normalScale`, `material`, `materialParams`, `materialColors`) are drawn with ONE instanced draw call per mesh part, however many there are: 10 000 identical cubes cost one draw. Give each its own `color` and they stop sharing, so for crowds vary the Transform, not the material. `play.report` shows `meshes` (drawn), `meshesCulled`, `meshBatches` (groups drawn with one instanced draw), `drawCalls`, `materials` (custom materials drawn) and `materialFallbacks` (materials that failed to build and are drawn magenta; the error log, `game.logs`, says why). In a test, `game.screenshot(path)` draws a frame and `game.state().renderStats` then has the same numbers ([SHADERS.md](../SHADERS.md)). Objects off screen still cast shadows into view while a shadow-casting light is on.
- **Lights.** Up to 1024 lights are used each frame (32 of them directional; each pixel reads only the lights whose `range` reaches it, so hundreds of small lights are fine). When a scene has more, the shadow-casting sun comes first, then the other directional lights, then point and spot lights by brightness over distance to the camera (the nearest and brightest are kept); `lightsDropped` in the stats says how many were left out. A light costs every pixel inside its `range`, so give every light the smallest `range` that looks right; lights whose range is outside the view cost nothing (`lightsCulled`).
- Custom shaders (full guide: `docs_read {"name":"shaders"}`, [SHADERS.md](../SHADERS.md); worked examples: `shaders-examples` (nine) and `shaders-sprites`): `MeshRenderer.material` names a `*.material.json` whose GLSL snippet changes the surface (and optionally moves vertices); `material_info` lists its params, `shader_compile` checks it, `materialParams` overrides params per entity. A material that does not compile draws magenta.
- Live textures: `MeshRenderer.texture`, `normalMap` and texture `materialParams` accept `"target:<name>"`, the picture of a `Camera` with `renderTarget: "<name>"` (a screen, a mirror, a book page whose `Interactable`s work through the mesh): section 9.30, [RENDERING.md](../RENDERING.md).
- **Procedural meshes.** Geometry built at run time (terrain, a deformed body, generated plants) without writing a file:
  `const m = mesh.create({ positions, indices, uvs?, normals?, submeshes? })`, then `MeshRenderer.mesh = m.id`; `m.update({ positions })`
  every frame is cheap (GPU buffers are reused), `m.destroy()` frees it, `m.save("assets/models/x.glb")` writes a `.glb` that loads back as
  a normal model. Missing normals and tangents are computed; glTF conventions (+Y up, counter-clockwise faces front, uv (0, 0) top-left).
  Bounds, culling, shadows, picking and the editor follow the real geometry; `Collider3D` shape `convex` or `mesh` takes the id too (a
  mesh collider rebuilds on every update: do not deform one each frame). The mesh belongs to the running scene and is released when a
  scene loads: after an `await`, compare `scene.generation`. `colors` (per vertex, rgb or rgba) multiply the material's base color like glTF `COLOR_0`; the pointer reaches a render target shown on a procedural mesh too.
  Commands for you (CLI, MCP, the editor; not in the exported game, where scripts use the `mesh` API above): `mesh.create`,
  `mesh.update`, `mesh.destroy`, `mesh.save`, `mesh.list`, `mesh.info`. Full guide: `docs_read {"name":"scripting"}`,
  "Procedural meshes".
- Not available yet: an environment map image for reflections, shadows from point and spot lights.

### 9.10 Save data

```js
import { Behaviour, storage } from "factoria";

export default class Scoreboard extends Behaviour {
  onStart() {
    this.best = storage.get("bestScore", 0); // fallback when nothing is saved yet
  }

  finish(score) {
    if (score > this.best) {
      this.best = score;
      storage.set("bestScore", score); // JSON-serializable values only
    }
  }
}
```

Save data is per user, across runs. Tests never touch it (section 10).

### 9.11 Changing levels

```js
import { Behaviour, scene } from "factoria";

export default class Goal extends Behaviour {
  onTriggerEnter(other) {
    if (other.hasTag("player")) scene.load("scenes/level2.scene.json"); // applied at the end of the frame
  }
}
```

A scene change drops every behaviour, timer and `world.on` listener of the old scene. Anything that must survive the change goes in `session` (section 9.15) or in `storage`.

A big level freezes the game for the frame `scene.load` reads it in. Load it in the background instead and keep a loading screen running: `const job = scene.load("scenes/level2.scene.json", props, { async: true })` returns a handle at once (`job.progress` 0..1 for a bar, `job.done`, `job.cancel()`, `job.promise`) and switches at the end of the frame the files are ready; `scene.preload(path)` and `assets.preload(paths)` only read ahead. The menu kit's `scripts/loading.js` is the recipe (section 9.24). Tests and headless runs take 4 files per frame, so they see the same frames on every machine; a windowed game takes what is ready within `runtime.loadBudgetMs` / `uploadBudgetMB`. Cost: nothing while no load runs; while one runs, an IO thread and worker jobs, and at most `loadBudgetMs` (default 4 ms) of each frame on the main thread (PERFORMANCE.md, "Background loading").

### 9.12 One-shot particle effects

A burst of sparks, a pickup pop or an explosion is a prefab with an emitter that does not emit continuously. The burst fires when the entity is created, even with `emitting: false`. `autoDestroy` removes the entity after the last particle dies. `"blend": "additive"` makes overlapping particles glow.

```json
{
  "format": "factoria.prefab/1",
  "entity": {
    "name": "Pop",
    "components": {
      "ParticleEmitter": {
        "emitting": false, "rate": 0, "burst": 24, "lifetime": 0.5,
        "speed": 260, "spread": 180, "direction": 90,
        "startSize": 10, "endSize": 0,
        "startColor": [1, 0.9, 0.3, 1], "endColor": [1, 0.4, 0.1, 0],
        "gravity": [0, -300, 0], "blend": "additive", "autoDestroy": true, "layer": 50
      }
    }
  }
}
```

```js
// Inside the pickup behaviour, when the player touches the coin:
world.spawnPrefab("prefabs/pop.prefab.json", { position: this.entity.position.clone() });
this.entity.destroy();
```

For smoke, fire, hit sparks that bounce, trails, an emitter that spawns another one (a sub-emitter) or pixel-art particles, see docs/PARTICLES.md (`docs_read {"name":"particles"}`): colour gradients and curves over a particle's life, flipbook sheets, emission shapes, turbulence, collision with a plane or a Tilemap, and the limits that keep a phone fast.

To burst an emitter that already exists, call `particles.burst(entity, 24)` or `entity.emitBurst(24)`; both work with `emitting: false`. They work without graphics (`--no-graphics`) too: the particles belong to the world and are born in the next simulation step. A continuous effect (fire, dust) keeps `emitting: true` and a `rate`. For HUD effects (a score pop, menu sparks) set `"space": "screen"` (and an `anchor`): the emitter is positioned in design pixels from the top-left, ignores the camera and is drawn in the HUD pass, so `PostProcess.bloomScreenSpace: false` keeps it crisp; `direction` and `gravity` mean the same as in the world (90 = up, negative `gravity` y falls).

**Effect documents: one call for a whole hit.** When a hit is sparks plus a flash plus a sound plus a camera shake, write ONE effect document instead of wiring each piece in every script. `assets/vfx/hit.vfx.json` bundles them on one timeline (`factoria.vfx/1`: `parts` of type `emitter`, `light`, `sound` and `command`, each with an `at` time in seconds), and the game plays it with `vfx.play("assets/vfx/hit.vfx.json", { position: enemy.position })`. The effect removes itself when it is over. `vfx.check {"path": "assets/vfx/hit.vfx.json"}` lists every problem with its JSON pointer; `vfx.list` shows what plays, so a test can step the game and see the parts happen at their frames. An entity with a `Vfx` component plays an effect from a scene (a torch glow). Check an effect before it ships: `vfx.budget` (particles alive and overdraw against the `phone` or `desktop` limits, with `vfx.edit` fixes; a 3D emitter's overdraw is projected through the scene's main camera), `vfx.filmstrip` (a picture of the effect over time; it steps the game; without `position` it plays at the middle of the view in 2D and 5 m in front of the main camera in 3D, and says so) and `vfx.review` (a vision model grades the strip against readability, timing, palette and overdraw and returns fixes; one model call, `no_model` without a vision model). Write your own effects: the engine ships none. The format, limits (16 parts, 64 effects at once), hot reload and determinism are in docs/PARTICLES.md, "Effect documents".

### 9.13 Coin pickup from the player

The coin reacts to the player's overlap through a trigger. The player tells the coin to collect itself:

```js fragment
// scripts/player.js (the player's onTriggerEnter)
onTriggerEnter(other) {
  if (other.hasTag("coin")) other.send("collect");
}
```

```js
// scripts/coin.js
import { Behaviour, session, world } from "factoria";

export default class Coin extends Behaviour {
  collect() {
    session.coins = (session.coins ?? 0) + 1;
    world.spawnPrefab("prefabs/pop.prefab.json", { position: this.entity.position.clone() });
    this.entity.destroy();
  }
}
```

The coin entity has `Collider2D` with `isTrigger: true`. `entity.send(method, ...args)` calls a method on another entity's behaviour, and does nothing if there is none.

### 9.14 Patrol AI: turn at walls and ledges

An enemy walks in `dir` and turns when a wall is in front of it (`isTouching`) or when nothing is under the next step (a short downward ray, `physics.raycast` with `ignore: this.entity` so it does not hit itself). The first two fixed steps are skipped, because bodies are created by the first physics step.

```js
// scripts/patrol.js
import { Behaviour, physics, vec2 } from "factoria";

export default class Patrol extends Behaviour {
  speed = 90;
  dir = -1;      // -1 = left, 1 = right
  halfW = 20;    // half the width of the body
  halfH = 20;    // half the height of the body
  ticks = 0;

  onFixedUpdate() {
    const body = this.entity.get("RigidBody2D");
    if (!body) return;
    if (this.ticks < 2) {          // bodies do not exist before the first physics step
      this.ticks += 1;
      body.velocity.x = this.dir * this.speed;
      return;
    }
    if (this.entity.isTouching([this.dir, 0])) this.dir = -this.dir;   // wall in front
    const p = this.entity.position;
    // Ledge probe: a short ray down from just ahead of the feet. No hit means nothing to stand on.
    const ahead = vec2(p.x + this.dir * (this.halfW + 4), p.y - this.halfH + 2);
    const ground = physics.raycast(ahead, vec2(ahead.x, ahead.y - 8), { ignore: this.entity });
    if (!ground) this.dir = -this.dir;
    body.velocity.x = this.dir * this.speed;
  }
}
```

Scene entity: `"RigidBody2D": {"type": "dynamic", "fixedRotation": true}`, `"Collider2D": {"shape": "box", "size": [40, 40], "friction": 0}`, and `"Script": {"path": "scripts/patrol.js", "props": {"speed": 90, "dir": -1}}`. Verified: an enemy walking left stopped and turned at a wall, and an enemy on a 160 px shelf turned at both edges.

### 9.15 Cross-scene state with `session`

`session` is a plain object that lives for the whole run. Use it for values that must survive a `scene.load`: score, coins, lives, the current level. It is not saved to disk (use `storage` for that).

```js
import { Behaviour, session } from "factoria";

export default class Hud extends Behaviour {
  onUpdate() {
    this.entity.get("Text").text = `Coins: ${session.coins ?? 0}`;
  }
}
```

Verified: `session.coins = 7`, then `scene.load` of another scene, still reads 7. Module-level variables survive a scene load too, but behaviours, timers and `world.on` listeners do not. Tests reset `session` for every test file.

### 9.16 Level data in JSON imports

Keep level layouts, tuning tables and text in `data/*.json` and import them from scripts or tests. Relative paths resolve from the importing file, so `scripts/x.js` imports `../data/levels.json`, and a test in `tests/` imports the same file with `../data/levels.json`:

```js
import levels from "../data/levels.json";   // the parsed file, as the default export
const { minX, maxX } = levels.bounds;
```

Hot reload covers JSON too. A syntax error is reported against the `.json` file, with its line and column (`data/levels.json:3:14: invalid JSON: ...`); `project_validate` lists it once as an error of that file, however many scripts import it, and does not add `Script.props` warnings for the scripts that could not load because of it. For a level that should look like an example you drew, call `tilemap.generate` (section 9.8). For levels that must be generated from parameters, write a project tool. For a tile level it composes ASCII `rows` and calls `scene.import_ascii` with `path` and `from` (section 9.8), which writes the scene file without touching the running game; for anything else it builds the scene and writes it with `fs.write` (see `docs_read {"name":"extending"}`, A.1). A generator that must give the same level for the same seed draws its random numbers from `rng.create(seed)`, not from `rng` and not from `rng.seed(seed)`: `rng.seed` reseeds the single world RNG the running game draws from (and a script cannot restore its state), while `rng.create` is an independent generator that never touches it:

```js
import { rng } from "factoria";

const r = rng.create(seed);   // mulberry32: the same seed gives the same sequence on every platform and engine version
const width = r.int(30, 60);  // inclusive; also r.float(), r.range(a, b), r.chance(p), r.pick(list), r.shuffle(list)
```

### 9.17 3D chase camera

The camera sits at the target plus an offset and follows it smoothly. Its rotation stays fixed, because there is no look-at: set `rotation` yourself. To face a direction `(dx, dz)` on the ground, use yaw `atan2(-dx, -dz)` in degrees.

```js
import { Behaviour, math, vec3 } from "factoria";

export default class ChaseCamera extends Behaviour {
  target = "ball";
  offset = [0, 4, 9];   // meters from the target; +Z is behind a camera that looks down -Z
  smoothing = 6;

  onLateUpdate(dt) {
    const t = this.world.find(this.target);
    if (!t) return;
    const want = t.worldPosition.add(vec3(this.offset));
    const p = this.entity.position;
    p.x = math.damp(p.x, want.x, this.smoothing, dt);
    p.y = math.damp(p.y, want.y, this.smoothing, dt);
    p.z = math.damp(p.z, want.z, this.smoothing, dt);
  }
}
```

Scene: the camera entity has `"Transform": {"position": [0, 4, 9], "rotation": [-20, 0, 0]}` (looking slightly down), `"Camera": {"projection": "perspective", "primary": true}`, and `"Script": {"path": "scripts/chase_camera.js", "props": {"target": "ball"}}`.

### 9.18 3D rolling ball and moving platforms

A sphere collider with `RigidBody3D` spins to match its rolling while it touches the ground: `rollWithMotion` (default true) derives the spin from its horizontal speed. Verified: a ball moved 5.96 m along X and its rotation turned by about -676 degrees about Z.

A rolling sphere is slowed by rolling resistance, not by sliding friction: `RigidBody3D.rollingFriction` (default 0.02) caps the friction impulse at `rollingFriction` times the normal impulse, so on flat ground its speed falls by about `rollingFriction * 9.81` m/s every second. A ball launched at 3 m/s rolls about 23 m before it stops, whatever `Collider3D.friction` says. With `"rollWithMotion": false` the sphere is a real rigid body instead (below). So a rolling ball you steer by setting `velocity` every frame keeps the speed you give it; raise `rollingFriction` (for example 0.3) for a heavy, grippy ball, or write the velocity toward zero yourself.

**Real rolling.** With `"rollWithMotion": false` a dynamic sphere is a rigid body like a box: friction at its contact point spins it (solid sphere, inertia 2/5 m r^2), so it rolls down a slope without slipping (a 30 degree slope gives 5/7 g sin = 3.5 m/s^2 and a spin of speed / radius; verified: 3.96 m and 10.5 rad/s in 1.5 s) and a glancing hit makes both spheres spin. It has no rolling resistance: on flat ground it keeps rolling until `angularDamping` / `linearDamping` (or an obstacle) stops it. Add `"lockRotation": true` for a ball that only slides (contacts never spin it and friction stops it within a second, which is what `rollWithMotion: false` meant before). Keep the default for a ball you steer by setting `velocity` every frame.

```js
// scripts/ball_control.js: push the ball with the move_* actions
import { Behaviour, input } from "factoria";

export default class BallControl extends Behaviour {
  speed = 6;

  onFixedUpdate() {
    const body = this.entity.get("RigidBody3D");
    body.velocity.x = input.axis("move_left", "move_right") * this.speed;
    body.velocity.z = -input.axis("move_back", "move_forward") * this.speed; // forward is -Z
  }
}
```

A **moving platform** is a `RigidBody3D` with `"type": "kinematic"` whose `velocity` the script sets. Bodies resting on top of it are carried along by its displacement, so a rider moves with the platform. Verified: over 30 frames the platform moved 1.49 m and the ball resting on it moved 1.48 m. A `CharacterController3D` standing on it is carried too (displacement, and the turn of a platform with `angularVelocity`, about the platform's centre) without any script code; set `"carriedByPlatforms": false` on the character for one that must not ride. Verified: a character stood 300 frames on a platform moving at 1 m/s and stayed within 5 cm of its place on it; with `carriedByPlatforms: false` it stayed where it was and the platform left.

```js
// scripts/mover.js: slides back and forth along X
import { Behaviour, time } from "factoria";

export default class Mover extends Behaviour {
  amplitude = 3;
  speed = 1.5;

  onStart() {
    this.body = this.entity.get("RigidBody3D");
  }

  onFixedUpdate() {
    this.body.velocity.x = Math.cos(time.elapsed * this.speed) * this.amplitude * this.speed;
  }
}
```

To make something spin without rolling, set `RigidBody3D.angularVelocity` (degrees per second about x, y, z) and `"rollWithMotion": false` with `"lockRotation": true` (a rigid sphere would roll on whatever it touches). Verified: `[0, 90, 0]` gave `rotation.y = 90` after one second. A box collider turns with the entity (a spinning kinematic bar pushes the bodies it meets); a sphere collider has no orientation, so for an arcade or locked sphere the spin is visual only. A dynamic box that is not `lockRotation`ed also spins by itself when it is hit or lands on an edge (below).

3D box colliders, fast bodies and sweeps:

- **Oriented boxes.** A `Collider3D` box takes the entity's world rotation (`Transform.rotation`, parents included), so a wall rotated 30 degrees about Y is a wall at 30 degrees, and a box turned 45 degrees blocks at its rotated edge, not at the corner of its axis-aligned bounding box. `offset` is rotated and scaled with the entity. Raycasts, `overlapSphere`, `isTouching`, events and the physics debug dump (`shapes[].rotation`, euler degrees) all use the turned shape. An unrotated box behaves exactly as before.
- **Dynamic boxes are rigid bodies.** Contacts and friction act at the contact points and apply torque (inertia from the box's size and mass, uniform density, rotating about the collider's centre). A box with its centre past a ledge edge tips over and falls, a box dropped on its corner falls onto a face and comes to rest (and falls asleep, see the next bullet), a stack of crates stays standing, and a sphere that hits a box near its top edge spins it. The orientation lives in the body; the engine writes it to `Transform.rotation` every step, and writing `Transform.rotation` yourself re-orients the body (it keeps its `angularVelocity`). `angularVelocity` is in degrees per second about the world axes; `RigidBody3D.angularDamping` slows a spin in the air (default 0). A box tumbling in the air precesses like a real one (a gyroscopic term keeps its angular momentum and energy: a fast spin about the intermediate axis of a plank flips over by itself); a cube or a sphere spins steadily.
- **Dynamic bodies sleep.** A dynamic 3D body whose fastest point (spin included) stays under 5 cm/s for half a second falls asleep together with every body touching it, so a stack of crates sleeps as one; in a pile of 64 or more bodies up to one in 64 may still creep (each slower than 30 cm/s) and the pile sleeps anyway. To help a pile settle, a slow rotating body (under 0.5 m/s) pressed against another dynamic body loses speed at 1/s, so a capsule rolling on a pile comes to rest; a body alone on the ground keeps its motion. A sleeping body costs no solver work and sends no collision events, and it stays exactly where it is. It wakes when an awake body or a moving kinematic platform touches it, when a script creates or teleports a static or kinematic body onto it, when a script writes its `Transform.position` or `Transform.rotation` (a teleport wakes the body and everything touching it, like 2D), its `RigidBody3D.velocity` or `angularVelocity`, when `applyImpulse`, `applyForce` or `setVelocity` is called on it, when the scene's gravity changes, and when what it rests on is destroyed, disabled, resized or moved away (a crate on a deleted platform falls). Scripts cannot read or set the sleep state; the `awake` flag of each body is in the `physics` part of the engine state dump, as in 2D.
- **Keep characters upright: `lockRotation`.** `"lockRotation": true` on a dynamic box makes collisions and friction never turn it: it stays upright, slides and stops as boxes did before rotation dynamics (cheaper too). `angularVelocity` and `Transform.rotation` written by gameplay still turn a locked box. Use it on a box-shaped player or enemy and on any crate that must not topple. It also stops contacts from spinning a sphere with `rollWithMotion` off. A sphere with `rollWithMotion` on (the default) is never turned by contacts: its spin follows its motion. Kinematic and static bodies are not affected by torque.
- **Limits of the rotation model.** Contacts are exact for box-box face contacts (the face is clipped against the other one and the best 4 points are kept, each remembered from one step to the next so the solver keeps the load at the right corner), a capsule lying on a surface or on another capsule has 2 points (one per end), one point for contacts between two crossing edges and for sphere contacts (a box standing on one of its edges, parallel to the face it touches, still gets two contact points and does not wobble along the edge). Boxes have no rolling resistance: a tumbling box loses energy at each impact on a face or an edge and settles, and `angularDamping` is the knob for drag. A spinning kinematic bar pushes bodies by its collider, not by its surface speed.
- **Fast bodies do not tunnel.** A body that would move relative to another body (static, kinematic or dynamic) by more than about half its smallest size in one physics sub-step (a 60 m/s bullet sphere, two spheres flying at each other, a fast kinematic wall) is swept in relative motion and stopped at the time of impact. The contacts are resolved there (stop, bounce, slide) and the rest of the sub-step continues with the new velocities, so a fast body that hits a ramp keeps sliding along it instead of losing the rest of its move. This is automatic. A turning box is swept through its own rotation within the sub-step too (a long thin rod spinning at 40 rad/s cannot swing through a thin wall, and after one end hits, the rest of the sub-step still catches the other end swinging in). Up to 32 impacts per sub-step are resolved this way; with more (a ball bouncing a thousand times a second between two walls a hand apart) the rest of the move waits for the next sub-step instead of being applied unswept, so the body can only fall slightly behind in time, never tunnel.
- **Shape casts.** The 3D shape cast sweeps a sphere or an axis-aligned box from one point to another and returns the first collider it touches (oriented boxes and spheres included), with the distance the centre travelled, the contact point and the surface normal. Colliders that already overlap the shape at the start are skipped, like a raycast that starts inside a collider; `mask`, `ignore` and `ignoreTriggers` work as for raycasts.

- **Collider shapes: capsule, convex, mesh.** `Collider3D.shape` also takes `capsule` (`radius`, `height` tip to tip, along the entity's local Y: the shape for a character or a rod), `convex` (the convex hull of the vertices of `mesh`, for a rock, a crate with chamfers or any dynamic prop) and `mesh` (the triangles of `mesh`, for terrain, ramps and level geometry). `mesh` is a primitive name or a project-relative .gltf/.glb path, usually the same as the entity's `MeshRenderer.mesh`; `Transform.scale` scales it. **A `mesh` collider must be static**: with a dynamic or kinematic `RigidBody3D` it is ignored and the engine logs one error saying so (use `convex`, or several boxes and capsules, for a moving body). Every shape collides with every other one, and works with raycasts, shape casts, `overlapSphere`, `isTouching`, fast-body sweeps, sleeping, events and the physics debug draw. Limits: a convex hull from a model with over 256 vertices is reduced to 256 extreme points, a dynamic capsule has the inertia of the solid capsule and a dynamic convex body that of its solid hull about the model origin (the products of inertia are ignored), and both rotate about their collider centre, a box lying on a mesh rests on its low corners, and a raycast that grazes a capsule or hull at under about 3 degrees can miss.
- **Joints.** Add `Joint3D` to an entity that has a `RigidBody3D` and a `Collider3D`: `"Joint3D": {"type": "hinge", "anchor": [0, 0.5, 0], "axis": [0, 0, 1]}` hangs it from a pivot at that point (in the entity's own axes) of the world; `connected` names another entity (it needs a body too) to hinge the two together (leave it out or write `""` for the world; both mean the same in scene files, scripts and `scene.set_component`), and `autoAnchor: true` then pins them where the anchor is now. `hinge` turns about `axis`, with `useLimits` (`lowerLimit`/`upperLimit` in degrees, measured from the pose the joint started in) and an optional motor (`useMotor`, `motorSpeed` degrees/s, `maxMotorTorque`); `ball` pins a point and leaves the rotation free (chains, ragdoll shoulders); `fixed` welds. The pair does not collide unless `collideConnected` is true. `Joint3D.angle` (read-only, degrees) is the hinge angle. A swinging body keeps its real pendulum period. `Joint3D.damping` (1/s, default 0) takes the swing out of the relative turning of the two bodies (a door that closes softly, a floppy limb). Bodies joined by joints sleep together once all of them are calm (a settled chain or bridge costs nothing and wakes when something touches it, a motor or a joint to a moving kinematic body keeps them awake), and groups of joined bodies are solved apart from each other, so one chain never disturbs another. `Joint3D.stalled` (read-only) turns true when a motor has been pushing for a quarter of a second without the joint turning (a gate against a wall, too little `maxMotorTorque`), so a script can react; a hinge that reached its limit is not stalled. A joint that cannot be built (no body, `connected` is itself or has no body) is reported once with how to fix it, and the body is not held. A scene simulates the same whatever ran in the process before it (earlier scenes, destroyed entities, reused entity slots): 3D bodies and joints are solved in the scene's entity order.
- **Character controller.** Put `CharacterController3D` on an entity (no `RigidBody3D`, no `Collider3D`: the controller is its own capsule) and move it from `onFixedUpdate`:

```js
import { Behaviour, physics, input, time, vec3 } from "factoria";

export default class Walker extends Behaviour {
  vy = 0;
  onFixedUpdate() {
    const dt = time.fixedDt;
    const walk = input.axis("move_left", "move_right") * 4, side = input.axis("move_up", "move_down") * 4;
    const r = physics.moveCharacter(this.entity, vec3(walk * dt, this.vy * dt, side * dt));
    if (r.isGrounded) this.vy = input.pressed("jump") ? 6 : -1;   // r.groundNormal, r.ground (entity), r.hitWall, r.hitCeiling
    else this.vy -= 9.81 * dt;
  }
}
```

  `radius`, `height`, `stepOffset` (highest step it climbs), `slopeLimit` (steepest slope it walks, degrees) and `skin` (small gap kept to surfaces) are fields of the component. It slides along walls instead of stopping, climbs steps up to `stepOffset`, treats slopes steeper than `slopeLimit` like walls, snaps down onto the ground when walking off a ramp, and pushes the free dynamic bodies it walks into (`pushStrength`, default 1 = it gives them its own speed, 0 = it does not push; a body held by a `Joint3D` is never pushed). It has no gravity of its own: keep a vertical speed in the script. Setting `CharacterController3D.velocity` (m/s) instead moves it every physics step without a script call. A kinematic platform it stands on carries it (`carriedByPlatforms`, default true; see the moving platform above). Standing on a dynamic body it weighs on it: with `applyWeight` (default true) every physics step presses `mass` kilograms times gravity on that body at the character's feet, so a seesaw tips towards the side it stands on and a plank of a bridge sags (`"applyWeight": false` for a character that weighs nothing).

  A seesaw is a dynamic plank on a hinge with the pivot at its centre; nothing else is needed for it to tip under the character:

  ```json
  "plank": { "components": {
    "Transform": { "position": [0, 1, 0] },
    "Collider3D": { "size": [4, 0.2, 1.5] },
    "RigidBody3D": { "type": "dynamic", "mass": 20 },
    "Joint3D": { "type": "hinge", "axis": [0, 0, 1], "useLimits": true, "lowerLimit": -20, "upperLimit": 20 }
  } }
  ```

  (`connected` left out = the world.) The plank turns about the z axis, stays on its pivot however the character pushes, and a character standing on its +x half takes the +x end down.

  **A rope bridge** is a row of dynamic planks hinged to each other, the first and the last hinged to the world. Nothing needs tuning: a chain of three or more jointed dynamic bodies gets extra solver iterations and a little drag by itself, so it hangs still and falls asleep within a few seconds (a body in a chain is about 1 m long and 5 to 10 kg; planks 1 m wide or more are the easy case). Build the planks in a script when the scene starts, so a level only says where the bridge goes:

  ```js
  import { Behaviour, world } from "factoria";

  export default class RopeBridge extends Behaviour {
    from = [0, 2, 0]; to = [12, 2, 0]; planks = 12; sag = 0.4;
    onStart() {
      const n = this.planks, [fx, fy, fz] = this.from, [tx, ty, tz] = this.to;
      // A parabola from one end to the other; plank i spans the points i/n and (i+1)/n of the curve.
      const at = (t) => [fx + (tx - fx) * t, fy + (ty - fy) * t - this.sag * 4 * t * (1 - t), fz + (tz - fz) * t];
      const planks = [];
      for (let i = 0; i < n; i++) {
        const a = at(i / n), b = at((i + 1) / n);
        const len = Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
        const tilt = (Math.atan2(b[1] - a[1], b[0] - a[0]) * 180) / Math.PI;
        const mid = [(a[0] + b[0]) / 2, (a[1] + b[1]) / 2 - 0.07, (a[2] + b[2]) / 2];
        planks.push(world.spawn({ id: `${this.entity.id}_plank_${i}`, components: {
          Transform: { position: mid, rotation: [0, 0, tilt] },
          Collider3D: { shape: "box", size: [len * 0.94, 0.14, 1.5], friction: 0.8 },
          RigidBody3D: { type: "dynamic", mass: 6 },
        } }, { position: mid }));
      }
      // The hinge of plank i sits at its far end and joins it to plank i + 1; the last one joins the world ("").
      planks.forEach((p, i) => p.add("Joint3D", { type: "hinge", axis: [0, 0, 1],
        anchor: [0.47 * Math.hypot(...at((i + 1) / n).map((v, k) => v - at(i / n)[k])), 0, 0],
        connected: i + 1 < n ? planks[i + 1].id : "" }));
      // The first plank hangs from a static post at the start.
      const post = world.spawn({ id: `${this.entity.id}_start`, components: {
        Transform: { position: at(0) }, RigidBody3D: { type: "static" },
        Collider3D: { shape: "box", size: [0.05, 0.05, 0.05], isTrigger: true } } }, { position: at(0) });
      post.add("Joint3D", { type: "hinge", axis: [0, 0, 1], connected: planks[0].id });
    }
  }
  ```

  Rules: put both ends just past the edges of the slabs (0.05 m or more): a plank that starts inside a static collider is reported (a warning in the log on the first step, naming both entities, the depth and the fix, and by `factoria validate` for scenes) and the chain buckles. The courier walking on it weighs on the planks (`CharacterController3D.applyWeight`) and never shoves them. For a limp rope or a heavier bridge add `damping` (try 2 to 10) to the planks' joints; do not raise the bodies' `linearDamping`, which also slows the fall. There is no `physics.make_chain3d` command: the recipe is about 25 lines and the engine settles the chain itself, so a command would only hide this code.

### 9.19 3D ground checks and raycasts

```js
import { Behaviour, physics, vec3 } from "factoria";

export default class GroundProbe extends Behaviour {
  onUpdate() {
    this.grounded = this.entity.isGrounded();   // 3D tolerance is 0.05 m by default
    // Distance to the floor below, ignoring this entity's own collider.
    const down = physics.raycast3d(this.entity.worldPosition, vec3(0, -1, 0), 5, { ignore: this.entity });
    this.height = down ? down.distance : Infinity;   // down = { entity, point, normal, distance } or null
  }
}
```

A collider that contains the ray origin is always skipped, so a ray that starts at the centre of a ball does not hit the ball. Use `ignore` when the ray starts outside the caster's own collider, for example just ahead of a body. The 3D `isTouching(direction)` works like the 2D one, for any direction.

### 9.20 Neon glow, exposure and tonemap: additive blend and the PostProcess stack

Glow is a camera setting, not artwork. Draw the bright things with `"blend": "additive"` (overlapping lights add up instead of covering each other), then add a `PostProcess` to the primary `Camera`'s entity and switch bloom on: every pixel brighter than `bloomThreshold` bleeds light into its surroundings. Do not hand-draw blurred halo sprites or stack translucent copies of a shape; they cost entities and never look as good. The `bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `colorFilter` fields that the `Camera` component had in older versions were removed in 0.33.0: a scene that still has them fails to load (the error names the file and the JSON pointer); use `PostProcess.bloomEnabled`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `colorFilterEnabled` + `colorFilterMode`. To keep the look of the old hard threshold, set `bloomKnee` to 0: the PostProcess default is 0.5 (a soft knee), the old Camera fields behaved like 0.

```json
{ "id": "camera", "components": {
    "Camera": { "projection": "orthographic", "clearColor": [0.02, 0.02, 0.05, 1] },
    "PostProcess": { "bloomEnabled": true, "bloomThreshold": 0.6, "bloomIntensity": 1.2, "bloomRadius": 20,
                     "bloomScreenSpace": false } } },
{ "id": "ship", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Shape2D": { "shape": "triangle", "size": [60, 60], "color": [0.1, 0.9, 1, 1], "pivot": [0.5, 0.3333],
                 "filled": false, "thickness": 4, "blend": "additive" } } }
```

- **Fields.** `bloomEnabled` turns it on (default off, so existing games are unchanged). `bloomThreshold` (0..20, default 0.7; 0..1 is the range of an ordinary scene) is the brightness where glow starts, measured as the largest of r, g and b, so a saturated colour such as `[1, 0, 0.8]` glows as much as white. Lower it to make dim colours glow, raise it so only the brightest things do. `bloomKnee` (0..1, default 0) softens the start: with 0 nothing at or below the threshold glows, with 1 colours a little below it already glow a little. `bloomIntensity` (0..10, default 1.2) is how much glow is added. `bloomRadius` (1..128 design pixels, default 20) is how far it reaches; radii below about 5 behave like 5. `bloomLensDirt` (a texture) with `bloomLensDirtIntensity` (0..10) shows smudges in the glow where the texture is bright.
- **Exposure and tonemap, the other half of the stack.** `exposureEnabled` with `exposureEv` (stops, each +1 doubles the light) brightens or darkens the whole picture before the tonemap; `exposureMode` `"auto"` follows the measured brightness of the frame (`exposureAdaptationSpeed` per second, kept between `exposureMinEv` and `exposureMaxEv`, plus `exposureEv`), needs a float render target (`render.supports {"feature":"floatTargets"}`) and is the same on every run for the same frames. `tonemapEnabled` with `tonemapMode` (`neutral`, `aces`, `agx`, `reinhard`, `none` = clip) brings light above white to the display; it matters when something draws above 1 (additive layers, `emissiveStrength`, a linear scene). Exposure, tonemap, the colour filter and the encode for the display are one pass. `PostProcess` on an entity WITHOUT a `Camera` is a volume (`shape` `box`, `circle`, `sphere` or `global`, `blendDistance`, `priority`, `weight`): the effects blend in as the camera enters it, e.g. a cave that darkens (`exposureEv` -1) or a hurt flash. Only the camera that draws first has its stack drawn today. `render.supports {"feature":"bloom"}` (or `exposure`, `tonemap`, `colorFilter`) says whether this build draws it.
- **Grading and lens effects, the same stack.** `colorGradingEnabled` (white balance `colorGradingTemperature`/`Tint`, `Lift`/`Gamma`/`Gain`, `Contrast`, `Saturation`, `HueShift`, and a `.cube` 3D LUT in `colorGradingLut` with `colorGradingLutContribution`), `vignetteEnabled`, `chromaticAberrationEnabled`, `lensDistortionEnabled` (the picture is black where the lens reads outside it: raise `lensDistortionScale`), `sharpenEnabled` and `filmGrainEnabled` (the same grain on every run of the same frames) are drawn in the final pass, in display space, and none of them clips above white. They cost one pass together (or none extra when exposure or tonemap is on). `assets.import` takes a `.cube` into `assets/luts/`. The `colorGradingCurve*` fields are stored but not drawn yet. docs/RENDERING.md, "The effects of the final pass".
- **Outline, pixelate, posterize.** Three more looks of the same final pass, in display space. `pixelateEnabled` + `pixelateSize` (blocks of that many design pixels, each showing its centre's colour) and `posterizeEnabled` + `posterizeLevels` (2..256 levels per channel, after the grading) cost no extra pass. `outlineEnabled` draws lines of `outlineWidth` design pixels in `outlineColor` (its alpha is the opacity): `outlineMode` `depth` (3D: where depth, found with `outlineDepthThreshold`, or the surface direction, `outlineNormalThreshold`, jumps; it turns the depth and normal prepass on, so only opaque meshes get lines) or `sprite` (2D: a line outside the border of sprites, tiles, shapes, text and particles, where their alpha reaches `outlineAlphaThreshold`; the 2D world is drawn once more into a coverage image while it is on). Both outline modes need ONE camera over the whole screen: with split screen or a camera `viewport` smaller than the screen the outline is skipped (one warning in `game.logs`), so do not promise it there. A width of 0 or a colour alpha of 0 draws nothing. `render.supports {"feature": "outline"}` says whether this GPU can. docs/RENDERING.md, "The outline".
- **Looks, and why the picture is what it is.** Start from a look instead of typing twenty fields: `postprocess.presets {}` lists `neutral`, `cinematic`, `retro`, `noir`, `dreamy`, `vivid` and `horror`, and `postprocess.apply_preset {"id": "camera", "preset": "cinematic"}` applies one (one undo step in the editor; without `"keep": true` it replaces the camera's whole stack with exactly the look, `neutral` clears it). A look can name an effect this GPU cannot draw (`render.supports` says `false` and why, e.g. `ssao` or `depthOfField` on a GPU that cannot sample the scene's depth): it is still applied and the answer lists it under `notDrawn`, so tell the user that part will not show here instead of promising it. To see what a camera really draws, and which entity or field sets each value (its own PostProcess or `volume:<id>`), call `postprocess.get {"id": "camera", "resolved": true}`; change one field with `postprocess.set {"id": "camera", "fields": {"bloomIntensity": 0.6}}`. In the editor, View > Post-processing shows the same stack with a "Stack off (A/B)" check to compare with the game drawn without it.
- **Dark background.** The glow is added on top of the picture, so it only shows on dark areas. Keep `clearColor` and backgrounds dark; a light background hides it.
- **Bright sources.** Sprites, shapes and particles that glow need a bright `color` (at or above the threshold). `ParticleEmitter` with `"blend": "additive"` plus bloom gives fire, sparks and explosions for free. In 3D, bright unlit meshes (`MeshRenderer.unlit`) and `emissive` surfaces glow the same way. `emissive` is a colour (0..1, an array with a channel over 1 is read as 0..255, so `[3, 2, 1]` is almost black); to glow brighter than white keep the colour at 0..1 and raise `MeshRenderer.emissiveStrength` (0..100, default 1): `"emissive": [1, 0.7, 0.3, 1], "emissiveStrength": 4` is an amber lamp four times brighter than white. The game is drawn into a float (HDR) target when the GPU can (`Renderer::hdr_scene()`; otherwise an 8-bit one, where everything clamps at white, also when the GPU refuses a float target with the requested multisampling), so the excess above white gives a bigger glow; the screen and screenshots stay 8-bit. A float target also changes the look of an existing game that already uses bloom: a specular highlight above 1 and an additive sum of several lights or particles now reach the bloom with their full strength, so the glow is bigger than it was in the 8-bit target, and it differs between a GPU that renders to RGBA16F and one that does not (that one keeps the old, clamped look). Compare a screenshot with `bloom` on before you keep `bloomIntensity` or `bloomThreshold` of a game made earlier; NaN and infinite pixels never glow. Meshes that differ only in `emissiveStrength` are not drawn in one batch, exactly like a different `emissive`.
- **HUD: crisp or glowing.** By default bloom is applied to the whole finished picture, screen-space items included, so white HUD text glows too. Set `"bloomScreenSpace": false` on the `PostProcess` (the recipe above does) to draw the screen-space items (Sprite, Shape2D and Text with `"space": "screen"`, and debug text) AFTER the bloom: the world glows and the HUD stays crisp, with translucent panels blending over the glow. Leave it `true` when a screen-space title or logo should glow, as on a title screen. Particles and tilemaps are world-space only, so they always glow. When exposure, a tonemap or (in a linear scene) a colour filter is on, the HUD is drawn over the finished picture in display colours: it is never exposed or tonemapped (white stays white) and never glows, whatever `bloomScreenSpace` says; the colour filter still covers it.
- **Shapes for neon.** `Shape2D` has `rectangle`, `circle`, `line`, `triangle`, `diamond` (a rhombus touching the middles of its `size` box; a square box gives a 45-degree square), `polygon` (`sides`) and `star` (`points`, `innerRadius`). Outlines (`filled: false`, `thickness`) read best under bloom. `pivot` is also the point a shape rotates around: a spinning `triangle` wobbles with the default pivot because the centre of its box is not its centre of mass, so give it `"pivot": [0.5, 0.3333]` (its centroid). The recipe above does.
- **Screenshots and tests.** The glow is part of the image (`factoria run --headless --screenshot-at`, MCP screenshots), and it is deterministic. Look at a screenshot after tuning; compare with `bloomEnabled: false` to see what it adds.
- **Animating it.** `this.entity.get("PostProcess").bloomIntensity = 1 + Math.sin(time.elapsed * 4) * 0.5;` pulses the glow from a script.
- **Cost.** A frame with no `PostProcess` adds no pass and no render target: the stack is free when it is off. Bloom reads the finished frame once, blurs a reduced-resolution copy and adds it back (4 to 7 extra passes, the number grows with the radius). Manual exposure, tonemap, colour filter and the display encode together are one full-screen pass; auto exposure adds two tiny ones (32x32 and 1x1). That is cheap on a GPU; the software renderer used for headless runs spends about 5 ms per drawn frame at 1280x720 on bloom. Headless tests and `factoria call` only draw when they take a screenshot, so the stack costs them nothing otherwise. `render.frame_graph` with `profileFrames` shows the time of each pass.

### 9.20.1 Colour-blind players: the colour filter and the colour-blind check

Roughly one player in twelve men and one in two hundred women cannot tell some colours apart, so a hazard that is only red against a green floor is invisible to them. Two separate tools:

- **Check it yourself (no change for the player).** `game_screenshot {"simulate":"deuteranopia"}` (also `protanopia`, `tritanopia`, `greyscale`), `game.screenshot(path, { simulate: "protanopia" })` in a test, or `factoria run --headless --screenshot-at 60 --screenshot-simulate deuteranopia`. The saved PNG shows what that viewer sees: look at it and ask whether every hazard, pickup, enemy and button is still found, by shape, outline, brightness or an icon, not only by hue. Take one normal screenshot and the `greyscale` one at least; add `deuteranopia` (the commonest) for red/green designs. The method: the pixels are taken as sRGB, decoded to linear light, multiplied by the Machado, Oliveira and Fernandes 2009 matrix of severity 1.0 (the cone is missing completely, the worst case) and encoded again; `greyscale` is Rec. 709 luminance in linear light. The check is done on the CPU on the saved file, so what the game draws is untouched.
- **Give it to the player.** The colour filter of the camera's `PostProcess` (`colorFilterEnabled: true`, `colorFilterMode`) is the last post-process of the frame (after bloom, HUD included), so screenshots, `--screenshot-at` and `--record-video` show it: `none` (default, no cost), `greyscale`, `highContrast` (contrast x1.8 around mid grey) and `protanopia`, `deuteranopia`, `tritanopia`, which are daltonize corrections for a player who lacks that cone: the loss is estimated with the same Machado matrix and the lost information is shifted into the channels the player still sees (Fidaner's method), so red and green end up differing in brightness and blue. The engine never saves the choice: put an option in the game's options screen that sets `colorFilterEnabled = true` and `colorFilterMode = "deuteranopia"` on the camera's `PostProcess` and keeps it in `storage` (the menu kit in [MENUS.md](../MENUS.md) has the button), and set it again in every scene, as every scene has its own camera.

Prefer designs that work without any filter (shapes, outlines, patterns); the filter is the safety net, the check is how you know.

### 9.21 Sweep a shape instead of a ray: will it fit, how far can it go

A ray is a line. When the thing that has to fit has a size (a character stepping into a gap, a crate being pushed, a dash, a placement preview), sweep its shape with `physics.shapeCast(shape, from, to, opts)`. It returns the same `{ entity, point, normal, distance } | null` as `raycast`; `distance` is how far the centre of the shape travels before it touches something.

```js
// scripts/dash.js: dash right as far as the player's own box fits, never into a wall (needs a "dash" input action).
import { Behaviour, input, physics, vec2 } from "factoria";

export default class Dash extends Behaviour {
  size = [28, 44];     // the same size as the player's Collider2D
  length = 120;

  onFixedUpdate() {
    if (!input.pressed("dash")) return;
    const p = this.entity.position;
    const from = vec2(p.x, p.y), to = vec2(p.x + this.length, p.y);
    // Skips the player's own collider (ignore) and anything it already overlaps at `from`.
    const hit = physics.shapeCast({ shape: "box", size: this.size }, from, to, { ignore: this.entity });
    const travel = hit ? hit.distance : this.length;     // hit.normal is the wall's surface normal
    this.entity.position = [p.x + travel, p.y];
  }
}
```

- **Shapes.** 2D: `{ shape: "circle", radius: 8 }` or `{ shape: "box", size: [w, h] }` (pixels). 3D (pass 3D `from`/`to`): `{ shape: "sphere", radius: 0.5 }` or `{ shape: "box", size: [x, y, z] }` (meters). Full sizes, like the colliders; the shape is centred on the cast position and never rotates. Sweep a capsule collider with a box or circle of similar size.
- **Where it stops.** At contact: in 2D, to a fraction of a pixel, so moving the centre by `distance` puts the shape against the surface, not into it.
- **Touching is not overlapping.** A body standing on the ground touches it: a cast down hits at once (`distance` about 0, `normal` up) and a cast up or sideways ignores the ground. A collider the shape is deeper inside than 1 cm (1 pixel at the default 100 pixels per meter) is skipped, as a ray starting inside a collider is. Put `ignore: this.entity` for the caster's own collider.
- **Not for** testing a spot (`from === to` returns `null`; use `overlapBox` / `overlapCircle`), ground checks (`isGrounded`) or walls (`isTouching`).
- From outside a script, the command `physics.shape_cast` does the same: `{"shape":{"shape":"box","size":[28,44]},"from":[0,100],"to":[120,100],"ignore":"player"}`.
- A wrong shape throws an Error that names the problem and shows an example, for instance `"sphere"` in a 2D cast (`"circle"` is the 2D name) or a misspelt `"circel"` (did you mean `circle`).

### 9.22 Water, heat haze and glass in 2D: the picture drawn so far

`Water2D` is a pool that refracts what is under its surface and mirrors what is above it; `DistortionZone2D` bends the picture inside a rectangle (heat over a brazier); a sprite material that calls `fa_scene_color(uv)` reads the picture too (frosted glass, a lens). Nothing is on until you add one, and a frame without one pays nothing.

```json
{ "id": "pool", "components": {
    "Transform": { "position": [640, 190, 0] },
    "Water2D": { "size": [760, 220], "tint": [0.08, 0.3, 0.42, 0.5], "reflection": 0.7, "refraction": 5, "waveAmplitude": 2.5, "waveLength": 70, "waveSpeed": 0.6 } } },
{ "id": "haze", "components": {
    "Transform": { "position": [1100, 470, 0] },
    "DistortionZone2D": { "size": [130, 170], "strength": 3 } } }
```

- **The top edge of the area is the surface**, so put the entity half the height under the line you want (a pool 220 high with its surface at y 300 is at y 190). The reflection only shows what is on screen: put the lanterns where the mirror image falls inside the picture.
- **Layers decide what is under the water.** `Water2D.layer` is 10 and `DistortionZone2D.layer` 20: sprites on lower layers are refracted and reflected, sprites on higher layers (the player in front of the pool, a log floating on it) are drawn over it untouched. Two readers one after the other share one copy of the picture and do not see each other; a sprite on a layer between them separates them.
- **Cost.** Each run of readers costs one copy of the camera's rectangle, at most 8 per camera and frame (the log says so once past that; `game.render_stats` has `sceneCopies`). `render.supports {"feature":"2dWater"}` is true on every backend.
- **Your own look.** `Water2D.material` / `DistortionZone2D.material` take a sprite material that reads `fa_scene_color(i.screen_uv + ...)` and `fa_world_to_uv(vec3(x, y, 0))`; the component's fields arrive as the params of the same names that the material declares. A material that does not build draws the area magenta (`materialFallbacks` names it). The waves follow the engine clock, so a replay shows the same water.
- Full reference: `docs.read rendering-2d-water`; the material API: `docs.read shaders-sprites`, "The scene colour". A scene to copy: `examples/lantern-keep/scenes/cellar_pool.scene.json` (if you got it with `project.create {example: "lantern-keep"}`).
