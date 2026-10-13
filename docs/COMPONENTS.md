# Components reference

Generated from the engine's reflection data. In scene JSON a component is `"Name": { field: value, ... }` (omitted fields keep their defaults); in scripts use `entity.get("Name")`. Vectors accept `[x, y]` or `{x, y}`; colors accept `[r, g, b, a]` (0..1) or `"#rrggbb"`.

## Core

### EntityInfo

Identity of an entity; present on every entity. In scene files these fields are the entity's top-level keys (id, name, tags, active), not a component entry. Tags are handled by the scene serializer.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | string | `""` | Stable unique string id within the scene (e.g. "player"). Used to reference the entity from Entity fields, scripts (world.find) and tools. Auto-generated ("e1", "e2"...) if omitted. |
| `name` | string | `""` | Display name shown in the editor and logs. Not unique. |
| `active` | bool | `true` | If false the entity and all its children are skipped by rendering, physics, audio and scripts. |

### Transform

Position, rotation and scale of an entity relative to its parent. Present on every entity. 2D uses x/y of position and the z angle of rotation; 3D units are meters.

| Field | Type | Default | Description |
|---|---|---|---|
| `position` | vec3 | `[0.0,0.0,0.0]` | Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering of 3D content. Units: world units (design pixels in 2D, meters in 3D). |
| `rotation` | vec3 | `[0.0,0.0,0.0]` | Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in the order Y, X, Z. 2D games only use the z value (counter-clockwise). |
| `scale` | vec3 | `[1.0,1.0,1.0]` | Local scale [x, y, z]. 1 = original size; negative values mirror. |

## Camera

### Camera

Renders the scene to the screen. The active camera with primary=true and the lowest depth draws the game (only one camera renders for now; split-screen/overlay cameras are on the roadmap). 3D cameras look down their local -Z axis.

| Field | Type | Default | Description |
|---|---|---|---|
| `projection` | enum: orthographic \\| perspective | `"orthographic"` | orthographic: flat 2D view (no perspective). perspective: 3D view with depth. |
| `fov` | float | `60.0` | Perspective only: vertical field of view in degrees. Range 1.0..179.0. |
| `orthoSize` | float | `0.0` | Orthographic only: half of the visible height in world units. 0 = use the design resolution (pixel perfect: one world unit is one design pixel). Range 0.0..100000.0. |
| `nearPlane` | float | `0.1` | Perspective only: distance of the near clip plane in meters. Keep it as large as possible for depth precision. Range 0.001..100000.0. |
| `farPlane` | float | `1000.0` | Perspective only: distance of the far clip plane in meters. Range 0.01..1000000.0. |
| `clearColor` | color | `[0.08,0.08,0.12,1.0]` | Background color the camera clears to when clear is true. |
| `clear` | bool | `true` | Clear the target before drawing. Set false on overlay cameras that draw on top of another camera. |
| `primary` | bool | `true` | The first active primary camera renders the game. |
| `depth` | int | `0` | Picks the rendering camera when several are primary: the lowest depth wins (multi-camera rendering is on the roadmap). |

## 2D

### Sprite

Draws a textured (or solid color) quad. Use `region` to pick a frame from a sprite sheet. Draw order: higher `layer` on top; ties sort by position.y (lower y on top), then creation order.

| Field | Type | Default | Description |
|---|---|---|---|
| `texture` | asset (texture) | `""` | Project-relative path of the image (e.g. "assets/hero.png"). Empty draws a solid quad of `color`. |
| `region` | rect | `[0.0,0.0,0.0,0.0]` | Source rectangle [x, y, w, h] in texture pixels with the origin at the TOP-LEFT. A zero size means the whole texture. SpriteAnimator overwrites it every frame. |
| `size` | vec2 | `[0.0,0.0]` | Size [w, h] in world units. [0, 0] = use the region (or texture) size in pixels. |
| `pivot` | vec2 | `[0.5,0.5]` | Anchor inside the sprite: [0, 0] bottom-left, [0.5, 0.5] center, [1, 1] top-right. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Tint multiplied with the texture. Alpha makes it translucent. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `flipX` | bool | `false` | Mirror horizontally. |
| `flipY` | bool | `false` | Mirror vertically. |
| `layer` | int | `0` | Draw order. Higher layers draw on top of lower ones. Backgrounds use negative layers. |
| `space` | enum: world \\| screen | `"world"` | world: positioned in the game world and affected by cameras. screen: UI/HUD in design-resolution pixels with (0,0) at the TOP-LEFT and +Y DOWN; drawn after the world. |
| `pixelArt` | bool | `true` | true = nearest-neighbour filtering (crisp pixels), false = smooth linear filtering. |

### SpriteAnimator

Flipbook animation over a grid sprite sheet. Requires a Sprite on the same entity; it overwrites Sprite.region every frame. Frames are numbered row-major from the top-left.

| Field | Type | Default | Description |
|---|---|---|---|
| `columns` | int | `1` | Number of columns in the sprite sheet grid. Range 1.0..4096.0. |
| `rows` | int | `1` | Number of rows in the sprite sheet grid. Range 1.0..4096.0. |
| `firstFrame` | int | `0` | First frame of the clip (inclusive, row-major index). |
| `lastFrame` | int | `0` | Last frame of the clip (inclusive, row-major index). |
| `fps` | float | `10.0` | Playback speed in frames per second. Range 0.0..1000.0. |
| `loop` | bool | `true` | Restart from firstFrame after lastFrame. If false the animation stops on the last frame. |
| `playing` | bool | `true` | Set false to pause, true to play. |
| `time` | float | `0.0` | Runtime state: seconds elapsed in the current clip. Runtime-only (not saved). |
| `frame` | int | `0` | Runtime state: current frame index. Runtime-only (not saved). |

### Shape2D

Untextured 2D primitive for prototypes, UI panels and debug visuals.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: rectangle \\| circle \\| line \\| triangle | `"rectangle"` | Kind of primitive to draw. |
| `size` | vec2 | `[32.0,32.0]` | rectangle/triangle: [width, height]. circle: diameter in x. line: end point offset from the entity origin. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Fill or outline color. |
| `filled` | bool | `true` | true = solid shape, false = outline only (lines are always drawn as strokes). |
| `thickness` | float | `2.0` | Outline / line thickness in world units. Range 0.0..10000.0. |
| `layer` | int | `0` | Draw order. Higher layers draw on top. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down. |

### Text

Draws a string with a TrueType font (or the built-in font). Works in world and screen space.

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | string | `"Text"` | The string to draw. Use \n for line breaks. |
| `font` | asset (font) | `""` | Project-relative path of a .ttf font. Empty uses the built-in font. |
| `fontSize` | float | `24.0` | Glyph height in world units (pixels in 2D). Range 1.0..4096.0. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Text color. |
| `align` | enum: left \\| center \\| right | `"left"` | Horizontal alignment of lines inside the text box. |
| `pivot` | vec2 | `[0.0,1.0]` | Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right. |
| `maxWidth` | float | `0.0` | If > 0, lines wrap at this width in world units. 0 = no wrapping. Range 0.0..100000.0. |
| `layer` | int | `100` | Draw order. Higher layers draw on top. Text defaults above sprites. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down. |

### Tilemap

A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. Solid tiles can generate static 2D collision.

| Field | Type | Default | Description |
|---|---|---|---|
| `tileset` | asset (texture) | `""` | Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom). |
| `tileSize` | vec2 | `[16.0,16.0]` | Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units). |
| `columns` | int | `1` | Number of tile columns in the tileset texture (used to find a tile's source rectangle). Range 1.0..4096.0. |
| `width` | int | `0` | Map width in tiles. Range 0.0..65536.0. |
| `height` | int | `0` | Map height in tiles. Range 0.0..65536.0. |
| `tiles` | json | `[]` | Tile indices, row-major with row 0 at the TOP: either a flat array of width*height integers or an array of rows. -1 = empty. |
| `solidTiles` | json | `[]` | List of tile indices that block movement (static colliders are generated for them). Empty = nothing collides. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Tint multiplied with the tileset. |
| `layer` | int | `-10` | Draw order. Defaults below sprites (-10). |

### ParticleEmitter

Emits short-lived particles (smoke, sparks, explosions). Particles interpolate size and color over their lifetime.

| Field | Type | Default | Description |
|---|---|---|---|
| `emitting` | bool | `true` | Continuously emit while true. Set false to stop spawning (live particles finish). |
| `rate` | float | `20.0` | Particles emitted per second while emitting. Range 0.0..100000.0. |
| `burst` | int | `0` | Number of particles emitted once when the emitter starts (explosions). Range 0.0..100000.0. |
| `maxParticles` | int | `500` | Upper limit of simultaneously alive particles. Range 1.0..1000000.0. |
| `lifetime` | float | `1.0` | How long a particle lives, in seconds. Range 0.001..3600.0. |
| `lifetimeVariance` | float | `0.2` | Random +- fraction applied to lifetime (0.2 = +-20%). Range 0.0..1.0. |
| `speed` | float | `100.0` | Initial speed in world units per second. |
| `speedVariance` | float | `0.3` | Random +- fraction applied to speed. Range 0.0..1.0. |
| `direction` | float | `90.0` | 2D emission direction in degrees: 0 = right, 90 = up. |
| `spread` | float | `30.0` | Half-angle of the emission cone in degrees (180 = all directions). Range 0.0..180.0. |
| `gravity` | vec3 | `[0.0,-200.0,0.0]` | Constant acceleration [x, y, z] in world units/s^2 (default pulls down). |
| `startSize` | float | `8.0` | Particle size when born, in world units. |
| `endSize` | float | `0.0` | Particle size at the end of its life. |
| `startColor` | color | `[1.0,1.0,1.0,1.0]` | Particle color when born. |
| `endColor` | color | `[1.0,1.0,1.0,0.0]` | Particle color at the end of life (alpha 0 fades out). |
| `texture` | asset (texture) | `""` | Particle image. Empty uses a soft round particle. |
| `worldSpace` | bool | `true` | true = particles stay where they were emitted when the emitter moves; false = they follow the emitter. |
| `is3D` | bool | `false` | Emit in a 3D cone as camera-facing billboards instead of in the 2D plane. |
| `layer` | int | `50` | Draw order. Higher layers draw on top. |

## 3D

### MeshRenderer

Draws a 3D mesh with a simple PBR-style material. Needs a perspective Camera and (unless unlit) a Light to be visible.

| Field | Type | Default | Description |
|---|---|---|---|
| `mesh` | string | `"cube"` | Built-in shape name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad") or a project-relative path to a .gltf/.glb model (e.g. "assets/models/ship.glb"). |
| `texture` | asset (texture) | `""` | Base color texture. Empty = none (or the glTF material). |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Base color, multiplied with the texture. |
| `metallic` | float | `0.0` | 0 = plastic/stone, 1 = metal. Range 0.0..1.0. |
| `roughness` | float | `0.6` | 0 = mirror-smooth, 1 = fully rough/matte. Range 0.0..1.0. |
| `emissive` | color | `[0.0,0.0,0.0,1.0]` | Light emitted by the surface regardless of lighting (glow). Black = none. |
| `unlit` | bool | `false` | true = ignore lighting and draw the flat base color. |
| `castShadows` | bool | `true` | Cast shadows from shadow-casting lights. |
| `receiveShadows` | bool | `true` | Receive shadows from shadow-casting lights. |
| `uvScale` | vec2 | `[1.0,1.0]` | Texture tiling [u, v]; 2 repeats the texture twice. |

### Light

A light source for 3D meshes. A directional light shines along the entity's forward direction (-Z rotated by the Transform), point and spot lights shine from the entity's position.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: directional \\| point \\| spot | `"directional"` | directional: sun-like, infinite distance. point: radiates in all directions. spot: cone along forward. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Light color. |
| `intensity` | float | `1.0` | Brightness multiplier. Range 0.0..1000.0. |
| `range` | float | `10.0` | Point/spot only: distance in meters where the light fades to zero. Range 0.01..100000.0. |
| `spotAngle` | float | `30.0` | Spot only: cone half-angle in degrees. Range 1.0..89.0. |
| `castShadows` | bool | `false` | Cast shadows. Only supported on directional lights for now. |

## Physics

### RigidBody2D

Puts the entity under 2D physics (Box2D). Pair it with a Collider2D. Positions are simulated in world units; gravity comes from the scene settings (gravity2D).

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: static \\| dynamic \\| kinematic | `"dynamic"` | static: never moves (walls, floors). dynamic: moved by forces and collisions. kinematic: moved only by setting velocity or the Transform; pushes dynamic bodies but is not pushed back. |
| `gravityScale` | float | `1.0` | Multiplier on world gravity. 0 = floats, negative = falls upwards. |
| `linearDamping` | float | `0.0` | Air resistance for movement; 0 = none, higher slows faster. Range 0.0..1000.0. |
| `angularDamping` | float | `0.05` | Air resistance for spinning. Range 0.0..1000.0. |
| `fixedRotation` | bool | `false` | true = never rotates from collisions (platformer characters). |
| `bullet` | bool | `false` | true = continuous collision detection, for fast small objects that would tunnel through walls. |
| `velocity` | vec2 | `[0.0,0.0]` | Linear velocity [x, y] in world units per second. Read/write: writes apply before the next physics step. |
| `angularVelocity` | float | `0.0` | Spin in degrees per second (counter-clockwise positive). |

### Collider2D

Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. Colliders collide when each one's layer is included in the other's mask.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| circle \\| capsule | `"box"` | Shape type; uses size (box, capsule) or radius (circle). |
| `size` | vec2 | `[32.0,32.0]` | box/capsule: [width, height] in world units (capsule is vertical). |
| `radius` | float | `16.0` | circle: radius in world units. |
| `offset` | vec2 | `[0.0,0.0]` | Shape center offset [x, y] from the entity origin, in world units. |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = no bounce, 1 = perfectly elastic. Range 0.0..1.0. |
| `density` | float | `1.0` | Mass per area; mass = density * shape area. Range 0.0..10000.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i). |

### RigidBody3D

Simple 3D physics body for arcade games (spheres and axis-aligned boxes; no rotation dynamics). Pair it with a Collider3D. Gravity comes from scene settings (gravity3D).

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: static \\| dynamic \\| kinematic | `"dynamic"` | static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform. |
| `mass` | float | `1.0` | Mass in kilograms (affects collision responses between dynamic bodies). Range 0.0001..1000000.0. |
| `gravityScale` | float | `1.0` | Multiplier on world gravity. |
| `linearDamping` | float | `0.0` | Air resistance; 0 = none. Range 0.0..1000.0. |
| `velocity` | vec3 | `[0.0,0.0,0.0]` | Linear velocity [x, y, z] in meters per second. Read/write. |

### Collider3D

Collision shape for 3D physics (axis-aligned box or sphere). Scaled by the Transform scale.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| sphere | `"box"` | Shape type; uses size (box) or radius (sphere). |
| `size` | vec3 | `[1.0,1.0,1.0]` | box: full extents [x, y, z] in meters (axis-aligned, before Transform scale). |
| `radius` | float | `0.5` | sphere: radius in meters. |
| `offset` | vec3 | `[0.0,0.0,0.0]` | Shape center offset [x, y, z] from the entity origin. |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = none, 1 = perfectly elastic. Range 0.0..1.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers. |

## Audio

### AudioSource

Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.

| Field | Type | Default | Description |
|---|---|---|---|
| `clip` | asset (audio) | `""` | Project-relative path of the sound (.wav, .ogg or .mp3). |
| `volume` | float | `1.0` | Loudness multiplier, 0 (silent) to 1 (full). Range 0.0..1.0. |
| `pitch` | float | `1.0` | Playback speed multiplier; 2 = one octave higher and twice as fast. Range 0.05..8.0. |
| `loop` | bool | `false` | Restart the clip when it ends. |
| `playOnStart` | bool | `false` | Start playing when the entity spawns / the scene loads. |
| `playing` | bool | `false` | Runtime state: true while a voice is playing. Set true to play, false to stop. Runtime-only (not saved). |
| `spatial` | bool | `false` | true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI). |
| `range` | float | `800.0` | Spatial only: distance in world units where the volume reaches 0. Range 0.0..1000000.0. |

### AudioListener

The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the primary camera is used.

| Field | Type | Default | Description |
|---|---|---|---|
| `volume` | float | `1.0` | Master volume multiplier for everything this listener hears. Range 0.0..4.0. |

## Scripting

### Script

Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class extending Behaviour (see docs/SCRIPTING.md).

| Field | Type | Default | Description |
|---|---|---|---|
| `path` | asset (script) | `""` | Project-relative path of the script, e.g. "scripts/player.js". |
| `props` | json | `{}` | JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. Lets one script serve many entities with different settings. |
| `enabled` | bool | `true` | false = the script receives no callbacks. |

## Scene

### SceneSettings

Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.

| Field | Type | Default | Description |
|---|---|---|---|
| `ambientLight` | color | `[0.25,0.25,0.3,1.0]` | Base light added to all lit 3D surfaces so shadows are not pitch black. |
| `gravity2D` | vec2 | `[0.0,-980.0]` | 2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards). |
| `gravity3D` | vec3 | `[0.0,-9.81,0.0]` | 3D gravity [x, y, z] in m/s^2 (default 9.81 downwards). |
| `fogColor` | color | `[0.5,0.6,0.7,1.0]` | Color distant 3D objects fade to. |
| `fogDensity` | float | `0.0` | Fog thickness; 0 disables fog. Range 0.0..10.0. |
| `skyColor` | color | `[0.45,0.62,0.85,1.0]` | Top color of the 3D background gradient (used when a perspective camera clears). |
| `horizonColor` | color | `[0.8,0.85,0.9,1.0]` | Bottom color of the 3D background gradient. |
| `music` | asset (audio) | `""` | Looping background music asset path. Empty = none. |
| `musicVolume` | float | `0.6` | Volume of the background music, 0..1. Range 0.0..1.0. |


# Commands reference

Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a script function (`fa.call(name, args)`).

## ai

### `ai.providers`

List configured AI providers and roles, or diagnose which ones are usable (doctor).

action "list" (default) shows providers and the role mapping from ~/.factoria/ai.json. action "doctor" also checks for CLIs (claude, codex, ant) and API keys (never printed). Example: {"action":"doctor"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["list","doctor"] | no | list or doctor. Default "list". |

### `ai.run` (modifies state)

Run an AI agent on a task in the current project (blocks until it finishes).

Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers (claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in tool loop. Example: {"task":"Add a pause menu","role":"orchestrator","maxCostUsd":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `task` | string | yes | What the agent should do. |
| `role` | string ["orchestrator","worker","fast"] | no |  Default "orchestrator". |
| `provider` | string | no | Override the role's provider (e.g. claude-code, codex, openrouter). |
| `model` | string | no | Override the role's model. |
| `maxTurns` | integer | no |  |
| `maxCostUsd` | number | no |  |
| `stream` | boolean | no |  Default true. |

## api

### `api.commands`

Describe every registered command (name, summary, schema).

Example: api.commands {}

### `api.components`

Describe every component type: fields, kinds, defaults, docs.

Read this before writing scene JSON. Example: api.components {}

### `api.scripting`

Machine-readable JavaScript API (modules, classes, functions) for gameplay scripts.

Example: api.scripting {}

## assets

### `assets.list`

List project asset files with type and size.

Example: assets.list {"folder":"assets","extension":".png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | no | Project-relative folder. Default "assets". |
| `extension` | string | no | Only files with this extension, e.g. .png |

## docs

### `docs.commands`

Reference of every available command (tool) with arguments.

Lists the commands of this session, including project tools from tools/*.js.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

### `docs.components`

Reference of every component and field (types, defaults, docs).

Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

### `docs.list`

List the engine documentation available offline.

Start here. Returns name, title and size of each document; read one with docs.read. The document 'ai-guide' explains how to build games with FactorIA.

### `docs.read`

Read a documentation page (Markdown).

Example: {"name":"scripting"}. Long pages can be read in slices with startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components).

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Doc name ("scripting") or path ("docs/SCRIPTING.md"). |
| `startLine` | integer | no | First line to return (1-based). Default 1. |
| `maxLines` | integer | no | Maximum number of lines. Default 2000. |

### `docs.search`

Search the documentation by keywords.

Case-insensitive; every word counts, headings weigh more. Returns best sections with a snippet. Example: {"query":"input actions"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Keywords. |
| `limit` | integer | no | Max results. Default 8. |

## engine

### `engine.info`

Show engine version, platform, graphics backend and loop state.

Returns {engineVersion, platform, graphics, headless, frame, paused, fixedHz, components, commands}. Example: engine.info {}

## feedback

### `feedback.list`

List the engine-feedback entries recorded for this project.

Check this before reporting to see what is already recorded. Filters are optional. Example: {"status":"open","category":"physics"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | Only entries with this status. |
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | no | Only this category. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | no | Only this severity. |

### `feedback.report` (modifies state)

Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.

CALL THIS WHENEVER the engine lacked a feature or had a bug/limitation and you built a workaround or gave up on something, right when it happens (not at the end). Examples: a component field you expected does not exist; an error message did not say how to fix the problem; a documented API behaves differently; you had to emulate a feature in JavaScript; a command you wanted is missing.
The entry is appended to the project's ENGINE_FEEDBACK.json, which engine developers aggregate to decide what to build next. Reporting a gap similar to an open one merges into it (occurrences + 1), so duplicates are harmless. Write 'title' as a short noun phrase ("No one-way platforms"), 'missing' as what you needed and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the concrete engine change that would remove the workaround.
Example: {"category":"physics","severity":"major","title":"No one-way platforms","missing":"Collider2D has no one-way option so the player cannot jump up through platforms.","workaround":"scripts/one_way.js disables the platform collider while the player moves upward.","workaroundFiles":["scripts/one_way.js"],"suggestion":"Add Collider2D.oneWay (bool)."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | yes | Engine area of the gap. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | yes | blocker: could not build the feature at all; major: large/fragile workaround; minor: small workaround; nice-to-have: convenience. |
| `title` | string | yes | Short noun phrase naming the gap; reuse wording for the same gap. |
| `missing` | string | yes | What the engine lacked or got wrong, and what you were trying to do. |
| `workaround` | string | yes | What you did instead (or 'none: feature dropped'). |
| `workaroundFiles` | array | no | Project-relative files implementing the workaround. |
| `suggestion` | string | no | How the engine could fix it (field, command, API). |
| `effort` | string ["small","medium","large"] | no | Your estimate of the engine-side effort to fix it. |
| `reporter` | object | no | Who is reporting. Defaults to {"kind":"ai"}; include your agent and model if you know them. |

### `feedback.update` (modifies state)

Change the status of a feedback entry or link it to an engine issue.

Engine developers use this when a gap is fixed (status fixed-in-engine), rejected (wont-fix) or duplicated. Example: {"id":"FB-0001","status":"fixed-in-engine","engineIssue":"#42"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entry id, e.g. FB-0001. |
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | New status. |
| `engineIssue` | string | no | Issue/PR link or id. |

## fs

### `fs.delete` (modifies state)

Delete a file or folder from the project.

Folders need recursive=true. factoria.json and ENGINE_FEEDBACK.json cannot be deleted. Not undoable unless the project is under version control. Example: {"path":"scripts/old.js"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path. |
| `recursive` | boolean | no | Delete a folder and everything in it. Default false. |

### `fs.edit` (modifies state)

Replace exact text in a file (must match exactly once unless replaceAll).

Example: {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}. Fails if 'find' is not found or matches several places; include more surrounding text to make it unique.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `find` | string | yes | Exact text to find (whitespace-sensitive). |
| `replace` | string | yes | Replacement text (may be empty to delete). |
| `replaceAll` | boolean | no | Replace every occurrence. Default false. |

### `fs.list`

List files and folders in the project.

Project-relative. Hides .git and .factoria. Example: {"path":"scenes","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Folder to list (default: project root). |
| `recursive` | boolean | no | Descend into subfolders. Default false. |
| `glob` | string | no | Only paths matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum entries returned. Default 500. |

### `fs.read`

Read a text file (optionally a line range).

Example: {"path":"scripts/player.js","startLine":1,"endLine":80}. Binary files are refused. Set numbered=true to get line numbers for fs.edit planning.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `startLine` | integer | no | First line (1-based). Default 1. |
| `endLine` | integer | no | Last line, inclusive (default: end of file). Default 0. |
| `numbered` | boolean | no | Prefix every line with its number and a tab. Default false. |

### `fs.search`

Search text in project files (substring or regex).

Skips binary files and .factoria/.git. Example: {"query":"RigidBody2D","glob":"**/*.json"} or {"query":"onUpdate\\(","regex":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Text or regular expression (ECMAScript). |
| `regex` | boolean | no | Treat query as a regular expression. Default false. |
| `caseSensitive` | boolean | no | Case-sensitive match. Default false. |
| `path` | string | no | Folder to search (default: project root). |
| `glob` | string | no | Only files matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum matches returned. Default 100. |

### `fs.write` (modifies state)

Create or overwrite a text file (parent folders are created).

Example: {"path":"scripts/enemy.js","content":"export default class ..."}. For small changes to an existing file prefer fs.edit. .json files are checked for syntax and a warning is returned if invalid; run project.validate afterwards.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `content` | string | yes | Full new file content. |
| `overwrite` | boolean | no | Allow replacing an existing file. Default true. |

## game

### `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons.

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}. The input is applied now and seen by the next frame (game.step). Example: game.input {"press":["jump"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | Action name (with `down`). |
| `key` | string | no | Key or mouse button name (with `down`). |
| `down` | boolean | no | New state for action/key. Default true. |
| `press` | array | no |  |
| `release` | array | no |  |
| `mouse` | object | no | {position:[x,y] in design pixels, left/right/middle: bool}. |

### `game.logs`

Read recent log lines (engine, scripts, assets...).

Use `after` (a seq from a previous call) to fetch only new lines. Example: game.logs {"minLevel":"warn","max":50}

| Argument | Type | Required | Description |
|---|---|---|---|
| `minLevel` | string ["trace","debug","info","warn","error"] | no |  Default "info". |
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `max` | integer | no |  Default 100. |

### `game.pause` (modifies state)

Pause the simulation (frame() stops simulating; game.step still works).

Example: game.pause {}

### `game.resume` (modifies state)

Resume the simulation after game.pause.

Example: game.resume {}

### `game.screenshot`

Capture the game view as a PNG and show it.

Saves the last rendered frame (design resolution) and returns the path; clients display the image. Step the game first so the picture shows what you expect. Default path .factoria/screenshots/frame_<n>.png. Example: game.screenshot {"path":"shots/start.png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Output PNG (project-relative or absolute). |

### `game.state`

Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.

Filters: entities (ids), components (names to include), includeDefaults, maxEntities (default 200). Example: game.state {"entities":["player"],"components":["Transform","RigidBody2D"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entities` | array | no | Only these entity ids. |
| `components` | array | no | Only these components per entity. |
| `includeDefaults` | boolean | no |  Default false. |
| `maxEntities` | integer | no |  Default 200. |

### `game.step` (modifies state)

Advance the simulation by N fixed frames (deterministic) and return a state summary.

Each frame is exactly 1/fixedHz seconds. `press` holds actions/keys down and `release` lets go; they are applied BEFORE the first frame and stay in effect (a press without release stays held). To tap a button use game.step {"frames":1,"press":["jump"]} then game.step {"frames":1,"release":["jump"]}. Works while paused. Example: game.step {"frames":60,"press":["move_right"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | Number of frames. Default 1. |
| `press` | array | no | Actions/keys to press first. |
| `release` | array | no | Actions/keys to release first. |

## physics

### `physics.raycast`

Cast a ray against colliders (2D segment or 3D ray) and return the first hit.

2D: {from:[x,y], to:[x,y]}. 3D: {dimension:"3d", origin:[x,y,z], direction:[x,y,z], maxDistance}. Triggers are ignored. Example: physics.raycast {"from":[0,300],"to":[0,-300]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `dimension` | string ["2d","3d"] | no |  Default "2d". |
| `from` | array | no | 2D start [x,y]. |
| `to` | array | no | 2D end [x,y]. |
| `origin` | array | no | 3D origin [x,y,z]. |
| `direction` | array | no | 3D direction. |
| `maxDistance` | number | no |  Default 1000. |
| `mask` | integer | no | Collision layer mask. Default -1. |

## project

### `project.create` (modifies state)

Create a new game project from a template.

Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, scripts, a test, AGENTS.md and ENGINE_FEEDBACK.json. Afterwards start `factoria mcp --project <dir>` to work on it. Example: {"dir":"my-game","template":"2d-platformer","name":"My Game"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `dir` | string | yes | Target folder (created; must be empty or new). |
| `template` | string | no | 2d-empty, 2d-platformer or 3d-empty (see project.templates). Default "2d-empty". |
| `name` | string | no | Display name (default: folder name). |
| `id` | string | no | Reverse-DNS id, e.g. com.example.mygame. |

### `project.info`

Show the project settings, input actions, current scene, scenes and scripts.

Returns the parsed factoria.json plus {currentScene, scenes[], scripts[], prefabs[], sceneErrors}. Example: project.info {}

### `project.spawn_box` (modifies state)

Spawn a colored square at a position.

Example: {"x": 100, "y": 50, "size": 40}. Returns the new entity id.

| Argument | Type | Required | Description |
|---|---|---|---|
| `x` | number | no | World x (pixels, 0 = screen centre). Default 0. |
| `y` | number | no | World y (pixels, +Y up). Default 0. |
| `size` | number | no | Side length in pixels. Default 32. |

### `project.templates`

List the project templates `project.create` can start from.

Returns [{name, description, dimension}]. Example: {}.

### `project.test` (modifies state)

Run the project's JavaScript tests (tests/*.test.js) headless and return the report.

Tests run inside this engine instance and change the world; reload the scene afterwards (scene.reload). Example: project.test {"filter":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `filter` | string | no | Only run test cases whose name contains this. |
| `files` | array | no | Test files (default: tests/*.test.js). |

### `project.validate`

Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.

Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, message and a fix hint. Loads every scene into a temporary world, so it does not disturb a running game. Example: {}

## scene

### `scene.destroy` (modifies state)

Destroy an entity and its children.

Destruction is applied immediately when called outside a frame. Example: scene.destroy {"id":"coin_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.get_entity`

Get one entity with every component field (including defaults and runtime values).

Accepts the entity id or its name. Example: scene.get_entity {"id":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.list_entities`

List entities (id, name, tags, components) with optional filters.

Filters: name (substring, case-insensitive), tag (exact), component (name). limit defaults to 100. Use scene.get_entity for full data. Example: scene.list_entities {"tag":"enemy","limit":20}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Substring of the entity name or id. |
| `tag` | string | no | Only entities having this tag. |
| `component` | string | no | Only entities having this component, e.g. RigidBody2D. |
| `limit` | integer | no | Maximum entities returned. Default 100. |

### `scene.load` (modifies state)

Replace the running scene with a scene file.

Loads immediately (outside a frame) or at the end of the current frame. Load problems are returned in `messages`. Example: scene.load {"path":"scenes/level2.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path. |

### `scene.reload` (modifies state)

Reload the current scene from disk (discards runtime changes).

Resets the world to the saved scene file. Example: scene.reload {}

### `scene.remove_component` (modifies state)

Remove a component from an entity.

Transform and EntityInfo cannot be removed. Example: scene.remove_component {"id":"player","component":"Script"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes |  |
| `component` | string | yes |  |

### `scene.save` (modifies state)

Save the running world to a scene file (current scene path by default).

Writes canonical scene JSON (only non-default fields). Example: scene.save {"path":"scenes/snapshot.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative output path. Default: the current scene. |

### `scene.set_component` (modifies state)

Add a component to an entity (if missing) and set the given fields.

`fields` is a partial object; unspecified fields keep their value. Errors name the field and valid values. Example: scene.set_component {"id":"player","component":"Sprite","fields":{"color":"red"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |
| `component` | string | yes | Component name, e.g. Transform, Sprite, RigidBody2D. |
| `fields` | object | no | Field name -> value. |

### `scene.spawn` (modifies state)

Create an entity from entity JSON, or instantiate a prefab at a position.

Either pass entity JSON ({name, id?, tags?, components:{...}}) or {prefab, position?}. Optional parent id. Returns the created entity (with defaults) plus load messages. Example: scene.spawn {"name":"Coin","components":{"Transform":{"position":[100,50,0]},"Shape2D":{"shape":"circle","size":[20,20],"color":"gold"}}}  or  scene.spawn {"prefab":"prefabs/enemy.prefab.json","position":[300,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `prefab` | string | no | Project-relative prefab path to instantiate. |
| `position` | array | no | [x, y] or [x, y, z] world position (Transform.position). |
| `entity` | object | no | Entity JSON; alternatively put its fields (name, components...) at top level. |
| `parent` | string | no | Parent entity id. |
| `name` | string | no |  |
| `id` | string | no |  |
| `tags` | array | no |  |
| `components` | object | no | Component name -> field object. |

## script

### `script.errors`

List script errors (load/runtime) and scene load problems.

Clear them with a scene reload. Example: script.errors {}

### `script.eval` (modifies state)

Evaluate JavaScript in the running game context (REPL) and return the value.

The last expression is returned as JSON. Example: script.eval {"code":"world.find('player').get('Transform').position"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | JavaScript source. |


## Scripting API (TypeScript declarations)

```ts
// Generated by `factoria api --dts`. Do not edit; regenerate after adding components or changing the engine.
// Declares the "factoria" and "factoria:test" modules used by gameplay scripts, tools and tests.

/**
 * Gameplay scripting API: behaviours, entities, world, input, audio, physics, math.
 */
declare module "factoria" {
  /**
   * Anything accepted where a 2D vector is expected: vec2(), {x, y} or [x, y].
   */
  export type Vec2Like = Vec2 | { x: number; y: number } | readonly [number, number];

  /**
   * Anything accepted where a 3D vector is expected (z defaults to unchanged/0).
   */
  export type Vec3Like = Vec3 | Vec2 | { x: number; y: number; z?: number } | readonly number[];

  /**
   * A color: color(), {r,g,b,a}, [r,g,b,a] (0..1) or "#rrggbb".
   */
  export type ColorLike = Color | { r: number; g: number; b: number; a?: number } | readonly number[] | string;

  /**
   * A rectangle {x, y, w, h}.
   */
  export type RectLike = Rect | { x: number; y: number; w: number; h: number } | readonly number[];

  /**
   * An entity, its id string, or null.
   */
  export type EntityLike = Entity | string | null;

  /**
   * Plain JSON data (objects, arrays, numbers, strings, booleans, null).
   */
  export type Json = any;

  /**
   * 2D vector value. Views returned by component fields (e.g. body.velocity) are live: writing .x/.y writes into the engine.
   */
  export class Vec2 {
    constructor(x?: number, y?: number);
    x: number;
    y: number;
    /**
     * Sets both components (writes through on live views).
     */
    set(x: number, y: number): this;
    /**
     * Copies another vector into this one.
     */
    copy(v: Vec2Like): this;
    /**
     * Component-wise sum (new vector).
     */
    add(v: Vec2Like): Vec2;
    /**
     * Component-wise difference.
     */
    sub(v: Vec2Like): Vec2;
    /**
     * Multiply by a vector (component-wise) or a scalar.
     */
    mul(v: Vec2Like | number): Vec2;
    /**
     * Multiply by a scalar.
     */
    scale(s: number): Vec2;
    /**
     * Divide by a vector or a scalar.
     */
    div(v: Vec2Like | number): Vec2;
    /**
     * Dot product.
     */
    dot(v: Vec2Like): number;
    /**
     * 2D cross product (z of the 3D cross).
     */
    cross(v: Vec2Like): number;
    /**
     * Euclidean length.
     */
    length(): number;
    /**
     * Squared length.
     */
    lengthSq(): number;
    /**
     * Unit vector (zero stays zero).
     */
    normalized(): Vec2;
    /**
     * Distance to another point.
     */
    distance(v: Vec2Like): number;
    /**
     * Linear interpolation.
     */
    lerp(v: Vec2Like, t: number): Vec2;
    /**
     * Plain copy (detaches a live view).
     */
    clone(): Vec2;
    /**
     * Approximate equality.
     */
    equals(v: Vec2Like, eps?: number): boolean;
    /**
     * Angle in degrees (atan2(y, x)).
     */
    angle(): number;
    /**
     * Rotated counter-clockwise by degrees.
     */
    rotated(deg: number): Vec2;
    toArray(): [number, number];
    toJSON(): [number, number];
    /**
     * Unit vector pointing at the angle (degrees).
     */
    static fromAngle(deg: number): Vec2;
    static readonly zero: Vec2;
    static readonly one: Vec2;
  }

  /**
   * 3D vector value (live view when it comes from a component field).
   */
  export class Vec3 {
    constructor(x?: number, y?: number, z?: number);
    x: number;
    y: number;
    z: number;
    /**
     * x and y as a Vec2.
     */
    readonly xy: Vec2;
    set(x: number, y: number, z: number): this;
    copy(v: Vec3Like): this;
    add(v: Vec3Like): Vec3;
    sub(v: Vec3Like): Vec3;
    mul(v: Vec3Like | number): Vec3;
    scale(s: number): Vec3;
    div(v: Vec3Like | number): Vec3;
    dot(v: Vec3Like): number;
    cross(v: Vec3Like): Vec3;
    length(): number;
    lengthSq(): number;
    normalized(): Vec3;
    distance(v: Vec3Like): number;
    lerp(v: Vec3Like, t: number): Vec3;
    clone(): Vec3;
    equals(v: Vec3Like, eps?: number): boolean;
    toArray(): [number, number, number];
    toJSON(): [number, number, number];
    static readonly zero: Vec3;
    static readonly one: Vec3;
    static readonly up: Vec3;
  }

  /**
   * RGBA color, components 0..1.
   */
  export class Color {
    constructor(r?: number, g?: number, b?: number, a?: number);
    r: number;
    g: number;
    b: number;
    a: number;
    set(r: number, g: number, b: number, a?: number): this;
    copy(c: ColorLike): this;
    clone(): Color;
    withAlpha(a: number): Color;
    lerp(c: Color, t: number): Color;
    mul(c: Color | number): Color;
    equals(c: Color, eps?: number): boolean;
    toHex(): string;
    toArray(): [number, number, number, number];
    toJSON(): [number, number, number, number];
    /**
     * Parses "#rgb", "#rrggbb", "#rrggbbaa" or a color name.
     */
    static hex(s: string): Color;
    static readonly white: Color;
    static readonly black: Color;
    static readonly red: Color;
    static readonly green: Color;
    static readonly blue: Color;
    static readonly clear: Color;
  }

  /**
   * Axis-aligned rectangle; (x, y) is the minimum corner.
   */
  export interface Rect {
    x: number;
    y: number;
    w: number;
    h: number;
    contains(p: Vec2Like): boolean;
    toArray(): [number, number, number, number];
  }

  /**
   * Returned by this.after / this.every.
   */
  export interface TimerHandle {
    /**
     * Stops the timer.
     */
    cancel(): void;
    readonly active: boolean;
  }

  /**
   * Second argument of onCollisionEnter.
   */
  export interface CollisionInfo {
    /**
     * Contact point (Vec2 in 2D games).
     */
    point: Vec2 | Vec3;
    /**
     * Contact normal pointing from this entity toward the other.
     */
    normal: Vec2 | Vec3;
    /**
     * Approximate impact strength.
     */
    impulse: number;
  }

  /**
   * An entity handle. Properties read/write engine memory directly; using an entity after it was destroyed throws (check .alive).
   */
  export class Entity {
    /**
     * Stable unique id (assignable; keeps lookups consistent).
     */
    id: string;
    name: string;
    tags: string[];
    active: boolean;
    readonly activeInHierarchy: boolean;
    /**
     * False once the entity was destroyed.
     */
    readonly alive: boolean;
    /**
     * Transform view (position, rotation, scale).
     */
    readonly transform: Components["Transform"];
    /**
     * Shortcut for transform.position (live view; assignable with vec2/vec3/[x,y]).
     */
    position: Vec3;
    /**
     * World-space position (get/set).
     */
    worldPosition: Vec3;
    /**
     * Live view of a component, or null if the entity lacks it.
     */
    get<K extends keyof Components>(name: K): Components[K] | null;
    has(name: keyof Components): boolean;
    /**
     * Adds (or returns) a component and applies fields.
     */
    add<K extends keyof Components>(name: K, fields?: ComponentInit[K]): Components[K];
    /**
     * Patches component fields (adds the component if missing).
     */
    set<K extends keyof Components>(name: K, fields: ComponentInit[K]): Components[K];
    remove(name: keyof Components): boolean;
    /**
     * Names of the components on this entity.
     */
    components(): string[];
    /**
     * Destroys the entity (and children) at the end of the frame.
     */
    destroy(): void;
    readonly parent: Entity | null;
    readonly children: Entity[];
    setParent(parent: EntityLike, keepWorld?: boolean): void;
    hasTag(tag: string): boolean;
    addTag(tag: string): void;
    removeTag(tag: string): void;
    /**
     * The script instance attached to this entity.
     */
    readonly behaviour: Behaviour | null;
    /**
     * Calls behaviour[method](...args) if it exists.
     */
    send(method: string, ...args: any[]): any;
    /**
     * 2D physics: touching ground below.
     */
    isGrounded(): boolean;
    /**
     * Entity JSON as in scene files.
     */
    toJSON(): Json;
  }

  /**
   * Base class of gameplay scripts. Export a subclass as the default export of a module in scripts/ and attach it with the Script component. Class fields are defaults overridable from Script.props.
   */
  export class Behaviour {
    /**
     * The owning entity.
     */
    readonly entity: Entity;
    readonly world: WorldAPI;
    /**
     * false skips update callbacks.
     */
    enabled: boolean;
    /**
     * One-shot timer (scaled game time); cancelled automatically on destroy.
     */
    after(seconds: number, fn: () => void): TimerHandle;
    /**
     * Repeating timer.
     */
    every(seconds: number, fn: () => void): TimerHandle;
    /**
     * Subscribe to world events for this behaviour; returns unsubscribe.
     */
    on(name: string, fn: (data: any, source: Entity | null) => void): () => void;
    /**
     * Once, before the first update (props already applied).
     */
    onStart?(): void;
    /**
     * Every frame; dt in seconds scaled by time.scale.
     */
    onUpdate?(dt: number): void;
    /**
     * Every fixed step, before physics.
     */
    onFixedUpdate?(dt: number): void;
    /**
     * After all updates.
     */
    onLateUpdate?(dt: number): void;
    /**
     * Before the entity is removed.
     */
    onDestroy?(): void;
    onCollisionEnter?(other: Entity, info: CollisionInfo): void;
    onCollisionExit?(other: Entity): void;
    onTriggerEnter?(other: Entity): void;
    onTriggerExit?(other: Entity): void;
    /**
     * Any world.emit event.
     */
    onEvent?(name: string, data: any, source: Entity | null): void;
  }

  /**
   * Result of a raycast.
   */
  export interface RayHit<V = Vec2 | Vec3> {
    entity: Entity;
    point: V;
    normal: V;
    distance: number;
  }

  /**
   * Entity lookup, spawning and events.
   */
  export interface WorldAPI {
    /**
     * Finds by stable id first, then by name.
     */
    find(idOrName: string): Entity | null;
    findAll(name: string): Entity[];
    findByTag(tag: string): Entity[];
    /**
     * All alive entities in creation order.
     */
    entities(): Entity[];
    /**
     * Creates an entity from scene-file JSON ({ name, tags, components }).
     */
    spawn(entityJson: Json, opts?: { parent?: Entity }): Entity;
    /**
     * Instantiates a prefab file.
     */
    spawnPrefab(path: string, opts?: { position?: Vec3Like; rotation?: number | Vec3Like; scale?: number | Vec3Like; parent?: Entity; overrides?: Json }): Entity;
    /**
     * Queue a game event; delivered to onEvent and world.on listeners.
     */
    emit(name: string, data?: any, source?: Entity): void;
    /**
     * Subscribe to an event; returns unsubscribe.
     */
    on(name: string, fn: (data: any, source: Entity | null) => void): () => void;
    /**
     * Scene settings (gravity2D, ambientLight, ...).
     */
    readonly settings: Components["SceneSettings"];
    /**
     * Simulated seconds since the scene started.
     */
    readonly time: number;
    readonly frame: number;
  }

  /**
   * Mouse state (design-resolution pixels, top-left origin).
   */
  export interface MouseAPI {
    readonly position: Vec2;
    /**
     * Position in world coordinates through the main camera.
     */
    readonly world: Vec3;
    readonly delta: Vec2;
    readonly wheel: number;
    down(button?: "left" | "right" | "middle"): boolean;
    pressed(button?: "left" | "right" | "middle"): boolean;
    released(button?: "left" | "right" | "middle"): boolean;
  }

  export interface TouchInfo {
    id: number;
    position: Vec2;
    world: Vec3;
    pressed: boolean;
  }

  /**
   * Input through named actions (factoria.json input.actions) or raw keys.
   */
  export interface InputAPI {
    /**
     * Action held. Unknown actions throw with a suggestion.
     */
    down(action: string): boolean;
    /**
     * Went down this frame.
     */
    pressed(action: string): boolean;
    released(action: string): boolean;
    /**
     * -1..1 from two actions.
     */
    axis(negative: string, positive: string): number;
    /**
     * Normalized 2D vector from four actions (+Y up).
     */
    vector(left: string, right: string, down: string, up: string): Vec2;
    /**
     * Raw key by name ("Space", "A", "Escape"...).
     */
    keyDown(key: string): boolean;
    keyPressed(key: string): boolean;
    keyReleased(key: string): boolean;
    readonly mouse: MouseAPI;
    readonly touches: TouchInfo[];
  }

  export interface PlayOptions {
    volume?: number;
    pitch?: number;
    pan?: number;
    loop?: boolean;
    bus?: "sfx" | "music" | "ui";
  }

  /**
   * Sound playback.
   */
  export interface AudioAPI {
    /**
     * Plays a clip, returns a voice id.
     */
    play(path: string, opts?: PlayOptions): number;
    stop(voice: number): void;
    stopAll(): void;
    /**
     * Starts looping background music.
     */
    music(path: string, opts?: { volume?: number; fade?: number }): void;
    stopMusic(fade?: number): void;
    setVolume(bus: "master" | "sfx" | "music" | "ui", volume: number): void;
  }

  /**
   * Queries and direct body control.
   */
  export interface PhysicsAPI {
    /**
     * 3D raycast between two points (when given Vec3).
     */
    raycast(from: Vec3, to: Vec3, opts?: { mask?: number }): RayHit<Vec3> | null;
    /**
     * 2D raycast between two points (when given Vec2).
     */
    raycast(from: Vec2Like, to: Vec2Like, opts?: { mask?: number }): RayHit<Vec2> | null;
    raycast3d(origin: Vec3Like, dir: Vec3Like, maxDistance?: number, opts?: { mask?: number }): RayHit<Vec3> | null;
    overlapCircle(center: Vec2Like, radius: number, opts?: { mask?: number }): Entity[];
    overlapBox(rect: RectLike, opts?: { mask?: number }): Entity[];
    overlapSphere(center: Vec3Like, radius: number, opts?: { mask?: number }): Entity[];
    applyImpulse(entity: Entity, v: Vec3Like): void;
    applyForce(entity: Entity, v: Vec3Like): void;
    setVelocity(entity: Entity, v: Vec3Like): void;
  }

  /**
   * Game clock.
   */
  export interface TimeAPI {
    /**
     * Seconds of the current frame (scaled).
     */
    readonly dt: number;
    readonly fixedDt: number;
    /**
     * Simulated seconds since scene start.
     */
    readonly elapsed: number;
    readonly frame: number;
    /**
     * Time scale for gameplay; 0 pauses behaviours.
     */
    scale: number;
  }

  /**
   * Main camera helpers.
   */
  export interface CameraAPI {
    /**
     * The primary camera entity.
     */
    readonly main: Entity | null;
    worldToScreen(v: Vec3Like): Vec2;
    screenToWorld(v: Vec2Like, depth?: number): Vec3;
  }

  /**
   * Immediate-mode debug drawing (one frame).
   */
  export interface DebugAPI {
    line(a: Vec3Like, b: Vec3Like, color?: ColorLike): void;
    rect(x: number, y: number, w: number, h: number, color?: ColorLike): void;
    circle(center: Vec2Like, radius: number, color?: ColorLike): void;
    text(screenPos: Vec2Like, text: string, color?: ColorLike): void;
    box(center: Vec3Like, size: Vec3Like, color?: ColorLike): void;
    sphere(center: Vec3Like, radius: number, color?: ColorLike): void;
  }

  export interface SceneAPI {
    /**
     * Deferred to the end of the frame.
     */
    load(path: string): void;
    reload(): void;
    readonly current: string;
  }

  export interface GameAPI {
    quit(): void;
    /**
     * True while time.scale is 0.
     */
    paused: boolean;
    /**
     * factoria.json contents.
     */
    readonly project: Readonly<Json>;
    readonly screenSize: Vec2;
  }

  /**
   * Persistent JSON save data.
   */
  export interface StorageAPI {
    get<T = any>(key: string, fallback?: T): T;
    set(key: string, value: Json): void;
    remove(key: string): void;
    keys(): string[];
    clear(): void;
  }

  /**
   * Deterministic random numbers (seeded per run). Math.random is routed here too.
   */
  export interface RngAPI {
    /**
     * [0, 1).
     */
    float(): number;
    range(min: number, max: number): number;
    /**
     * Inclusive.
     */
    int(min: number, max: number): number;
    chance(p?: number): boolean;
    pick<T>(items: readonly T[]): T | undefined;
    shuffle<T>(items: readonly T[]): T[];
  }

  export interface MathAPI {
    clamp(v: number, min: number, max: number): number;
    lerp(a: number, b: number, t: number): number;
    inverseLerp(a: number, b: number, v: number): number;
    remap(v: number, a0: number, a1: number, b0: number, b1: number): number;
    /**
     * Frame-rate independent smoothing.
     */
    damp(current: number, target: number, smoothing: number, dt: number): number;
    moveTowards(current: number, target: number, maxDelta: number): number;
    approach(current: number, target: number, maxDelta: number): number;
    sign(v: number): number;
    degToRad(deg: number): number;
    radToDeg(rad: number): number;
    /**
     * Wraps to (-180, 180].
     */
    wrapAngle(deg: number): number;
  }

  export interface CommandInfoJS {
    name: string;
    summary: string;
    description: string;
    inputSchema: Json;
    readOnly: boolean;
    category: string;
  }

  /**
   * Engine commands (the same ones MCP exposes).
   */
  export interface FaAPI {
    /**
     * Runs a command; throws an Error with message and hint on failure.
     */
    call(name: string, args?: Json): any;
    commands(): CommandInfoJS[];
  }

  /**
   * The world.
   */
  export const world: WorldAPI;

  /**
   * Input.
   */
  export const input: InputAPI;

  /**
   * Audio.
   */
  export const audio: AudioAPI;

  /**
   * Physics.
   */
  export const physics: PhysicsAPI;

  /**
   * Game clock.
   */
  export const time: TimeAPI;

  /**
   * Camera helpers.
   */
  export const camera: CameraAPI;

  /**
   * Debug drawing.
   */
  export const debug: DebugAPI;

  /**
   * Scene control.
   */
  export const scene: SceneAPI;

  /**
   * Game control.
   */
  export const game: GameAPI;

  /**
   * Save data.
   */
  export const storage: StorageAPI;

  /**
   * Deterministic RNG.
   */
  export const rng: RngAPI;

  /**
   * Engine commands.
   */
  export const fa: FaAPI;

  /**
   * Math helpers.
   */
  export const math: MathAPI;

  /**
   * Creates a Vec2: vec2(1, 2), vec2([1, 2]), vec2({x, y}), vec2(3) = (3, 3).
   */
  export function vec2(x?: number | Vec2Like, y?: number): Vec2;

  /**
   * Creates a Vec3.
   */
  export function vec3(x?: number | Vec3Like, y?: number, z?: number): Vec3;

  /**
   * Creates a Color from components 0..1 or "#rrggbb".
   */
  export function color(r?: number | ColorLike, g?: number, b?: number, a?: number): Color;

  // ---- Components (generated from the engine's reflection registry) ----
  /**
   * Identity of an entity; present on every entity. In scene files these fields are the entity's top-level keys (id, name, tags, active), not a component entry. Tags are handled by the scene serializer.
   * 
   * Category: Core
   */
  export interface EntityInfoComponent {
    /**
     * Stable unique string id within the scene (e.g. "player"). Used to reference the entity from Entity fields, scripts (world.find) and tools. Auto-generated ("e1", "e2"...) if omitted.
     */
    id: string;
    /**
     * Display name shown in the editor and logs. Not unique.
     */
    name: string;
    /**
     * If false the entity and all its children are skipped by rendering, physics, audio and scripts.
     */
    active: boolean;
  }
  /**
   * Position, rotation and scale of an entity relative to its parent. Present on every entity. 2D uses x/y of position and the z angle of rotation; 3D units are meters.
   * 
   * Category: Core
   */
  export interface TransformComponent {
    /**
     * Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering of 3D content. Units: world units (design pixels in 2D, meters in 3D).
     */
    get position(): Vec3;
    set position(value: Vec3Like);
    /**
     * Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in the order Y, X, Z. 2D games only use the z value (counter-clockwise).
     */
    get rotation(): Vec3;
    set rotation(value: Vec3Like);
    /**
     * Local scale [x, y, z]. 1 = original size; negative values mirror.
     */
    get scale(): Vec3;
    set scale(value: Vec3Like);
  }
  /**
   * Renders the scene to the screen. The active camera with primary=true and the lowest depth draws the game (only one camera renders for now; split-screen/overlay cameras are on the roadmap). 3D cameras look down their local -Z axis.
   * 
   * Category: Camera
   */
  export interface CameraComponent {
    /**
     * orthographic: flat 2D view (no perspective). perspective: 3D view with depth.
     */
    projection: "orthographic" | "perspective";
    /**
     * Perspective only: vertical field of view in degrees.
     */
    fov: number;
    /**
     * Orthographic only: half of the visible height in world units. 0 = use the design resolution (pixel perfect: one world unit is one design pixel).
     */
    orthoSize: number;
    /**
     * Perspective only: distance of the near clip plane in meters. Keep it as large as possible for depth precision.
     */
    nearPlane: number;
    /**
     * Perspective only: distance of the far clip plane in meters.
     */
    farPlane: number;
    /**
     * Background color the camera clears to when clear is true.
     */
    get clearColor(): Color;
    set clearColor(value: ColorLike);
    /**
     * Clear the target before drawing. Set false on overlay cameras that draw on top of another camera.
     */
    clear: boolean;
    /**
     * The first active primary camera renders the game.
     */
    primary: boolean;
    /**
     * Picks the rendering camera when several are primary: the lowest depth wins (multi-camera rendering is on the roadmap).
     */
    depth: number;
  }
  /**
   * Draws a textured (or solid color) quad. Use `region` to pick a frame from a sprite sheet. Draw order: higher `layer` on top; ties sort by position.y (lower y on top), then creation order.
   * 
   * Category: 2D
   */
  export interface SpriteComponent {
    /**
     * Project-relative path of the image (e.g. "assets/hero.png"). Empty draws a solid quad of `color`. (asset path: texture)
     */
    texture: string;
    /**
     * Source rectangle [x, y, w, h] in texture pixels with the origin at the TOP-LEFT. A zero size means the whole texture. SpriteAnimator overwrites it every frame.
     */
    get region(): Rect;
    set region(value: RectLike);
    /**
     * Size [w, h] in world units. [0, 0] = use the region (or texture) size in pixels.
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Anchor inside the sprite: [0, 0] bottom-left, [0.5, 0.5] center, [1, 1] top-right.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Tint multiplied with the texture. Alpha makes it translucent. Accepts [r,g,b,a], "#rrggbb" or a name.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Mirror horizontally.
     */
    flipX: boolean;
    /**
     * Mirror vertically.
     */
    flipY: boolean;
    /**
     * Draw order. Higher layers draw on top of lower ones. Backgrounds use negative layers.
     */
    layer: number;
    /**
     * world: positioned in the game world and affected by cameras. screen: UI/HUD in design-resolution pixels with (0,0) at the TOP-LEFT and +Y DOWN; drawn after the world.
     */
    space: "world" | "screen";
    /**
     * true = nearest-neighbour filtering (crisp pixels), false = smooth linear filtering.
     */
    pixelArt: boolean;
  }
  /**
   * Flipbook animation over a grid sprite sheet. Requires a Sprite on the same entity; it overwrites Sprite.region every frame. Frames are numbered row-major from the top-left.
   * 
   * Category: 2D
   */
  export interface SpriteAnimatorComponent {
    /**
     * Number of columns in the sprite sheet grid.
     */
    columns: number;
    /**
     * Number of rows in the sprite sheet grid.
     */
    rows: number;
    /**
     * First frame of the clip (inclusive, row-major index).
     */
    firstFrame: number;
    /**
     * Last frame of the clip (inclusive, row-major index).
     */
    lastFrame: number;
    /**
     * Playback speed in frames per second.
     */
    fps: number;
    /**
     * Restart from firstFrame after lastFrame. If false the animation stops on the last frame.
     */
    loop: boolean;
    /**
     * Set false to pause, true to play.
     */
    playing: boolean;
    /**
     * Runtime state: seconds elapsed in the current clip.
     */
    time: number;
    /**
     * Runtime state: current frame index.
     */
    frame: number;
  }
  /**
   * Untextured 2D primitive for prototypes, UI panels and debug visuals.
   * 
   * Category: 2D
   */
  export interface Shape2DComponent {
    /**
     * Kind of primitive to draw.
     */
    shape: "rectangle" | "circle" | "line" | "triangle";
    /**
     * rectangle/triangle: [width, height]. circle: diameter in x. line: end point offset from the entity origin.
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Fill or outline color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * true = solid shape, false = outline only (lines are always drawn as strokes).
     */
    filled: boolean;
    /**
     * Outline / line thickness in world units.
     */
    thickness: number;
    /**
     * Draw order. Higher layers draw on top.
     */
    layer: number;
    /**
     * world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down.
     */
    space: "world" | "screen";
  }
  /**
   * Draws a string with a TrueType font (or the built-in font). Works in world and screen space.
   * 
   * Category: 2D
   */
  export interface TextComponent {
    /**
     * The string to draw. Use \n for line breaks.
     */
    text: string;
    /**
     * Project-relative path of a .ttf font. Empty uses the built-in font. (asset path: font)
     */
    font: string;
    /**
     * Glyph height in world units (pixels in 2D).
     */
    fontSize: number;
    /**
     * Text color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Horizontal alignment of lines inside the text box.
     */
    align: "left" | "center" | "right";
    /**
     * Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * If > 0, lines wrap at this width in world units. 0 = no wrapping.
     */
    maxWidth: number;
    /**
     * Draw order. Higher layers draw on top. Text defaults above sprites.
     */
    layer: number;
    /**
     * world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down.
     */
    space: "world" | "screen";
  }
  /**
   * A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. Solid tiles can generate static 2D collision.
   * 
   * Category: 2D
   */
  export interface TilemapComponent {
    /**
     * Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom). (asset path: texture)
     */
    tileset: string;
    /**
     * Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units).
     */
    get tileSize(): Vec2;
    set tileSize(value: Vec2Like);
    /**
     * Number of tile columns in the tileset texture (used to find a tile's source rectangle).
     */
    columns: number;
    /**
     * Map width in tiles.
     */
    width: number;
    /**
     * Map height in tiles.
     */
    height: number;
    /**
     * Tile indices, row-major with row 0 at the TOP: either a flat array of width*height integers or an array of rows. -1 = empty. Returns a plain-object COPY; assign a new value to write.
     */
    tiles: any;
    /**
     * List of tile indices that block movement (static colliders are generated for them). Empty = nothing collides. Returns a plain-object COPY; assign a new value to write.
     */
    solidTiles: any;
    /**
     * Tint multiplied with the tileset.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Draw order. Defaults below sprites (-10).
     */
    layer: number;
  }
  /**
   * Emits short-lived particles (smoke, sparks, explosions). Particles interpolate size and color over their lifetime.
   * 
   * Category: 2D
   */
  export interface ParticleEmitterComponent {
    /**
     * Continuously emit while true. Set false to stop spawning (live particles finish).
     */
    emitting: boolean;
    /**
     * Particles emitted per second while emitting.
     */
    rate: number;
    /**
     * Number of particles emitted once when the emitter starts (explosions).
     */
    burst: number;
    /**
     * Upper limit of simultaneously alive particles.
     */
    maxParticles: number;
    /**
     * How long a particle lives, in seconds.
     */
    lifetime: number;
    /**
     * Random +- fraction applied to lifetime (0.2 = +-20%).
     */
    lifetimeVariance: number;
    /**
     * Initial speed in world units per second.
     */
    speed: number;
    /**
     * Random +- fraction applied to speed.
     */
    speedVariance: number;
    /**
     * 2D emission direction in degrees: 0 = right, 90 = up.
     */
    direction: number;
    /**
     * Half-angle of the emission cone in degrees (180 = all directions).
     */
    spread: number;
    /**
     * Constant acceleration [x, y, z] in world units/s^2 (default pulls down).
     */
    get gravity(): Vec3;
    set gravity(value: Vec3Like);
    /**
     * Particle size when born, in world units.
     */
    startSize: number;
    /**
     * Particle size at the end of its life.
     */
    endSize: number;
    /**
     * Particle color when born.
     */
    get startColor(): Color;
    set startColor(value: ColorLike);
    /**
     * Particle color at the end of life (alpha 0 fades out).
     */
    get endColor(): Color;
    set endColor(value: ColorLike);
    /**
     * Particle image. Empty uses a soft round particle. (asset path: texture)
     */
    texture: string;
    /**
     * true = particles stay where they were emitted when the emitter moves; false = they follow the emitter.
     */
    worldSpace: boolean;
    /**
     * Emit in a 3D cone as camera-facing billboards instead of in the 2D plane.
     */
    is3D: boolean;
    /**
     * Draw order. Higher layers draw on top.
     */
    layer: number;
  }
  /**
   * Draws a 3D mesh with a simple PBR-style material. Needs a perspective Camera and (unless unlit) a Light to be visible.
   * 
   * Category: 3D
   */
  export interface MeshRendererComponent {
    /**
     * Built-in shape name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad") or a project-relative path to a .gltf/.glb model (e.g. "assets/models/ship.glb").
     */
    mesh: string;
    /**
     * Base color texture. Empty = none (or the glTF material). (asset path: texture)
     */
    texture: string;
    /**
     * Base color, multiplied with the texture.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * 0 = plastic/stone, 1 = metal.
     */
    metallic: number;
    /**
     * 0 = mirror-smooth, 1 = fully rough/matte.
     */
    roughness: number;
    /**
     * Light emitted by the surface regardless of lighting (glow). Black = none.
     */
    get emissive(): Color;
    set emissive(value: ColorLike);
    /**
     * true = ignore lighting and draw the flat base color.
     */
    unlit: boolean;
    /**
     * Cast shadows from shadow-casting lights.
     */
    castShadows: boolean;
    /**
     * Receive shadows from shadow-casting lights.
     */
    receiveShadows: boolean;
    /**
     * Texture tiling [u, v]; 2 repeats the texture twice.
     */
    get uvScale(): Vec2;
    set uvScale(value: Vec2Like);
  }
  /**
   * A light source for 3D meshes. A directional light shines along the entity's forward direction (-Z rotated by the Transform), point and spot lights shine from the entity's position.
   * 
   * Category: 3D
   */
  export interface LightComponent {
    /**
     * directional: sun-like, infinite distance. point: radiates in all directions. spot: cone along forward.
     */
    type: "directional" | "point" | "spot";
    /**
     * Light color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Brightness multiplier.
     */
    intensity: number;
    /**
     * Point/spot only: distance in meters where the light fades to zero.
     */
    range: number;
    /**
     * Spot only: cone half-angle in degrees.
     */
    spotAngle: number;
    /**
     * Cast shadows. Only supported on directional lights for now.
     */
    castShadows: boolean;
  }
  /**
   * Puts the entity under 2D physics (Box2D). Pair it with a Collider2D. Positions are simulated in world units; gravity comes from the scene settings (gravity2D).
   * 
   * Category: Physics
   */
  export interface RigidBody2DComponent {
    /**
     * static: never moves (walls, floors). dynamic: moved by forces and collisions. kinematic: moved only by setting velocity or the Transform; pushes dynamic bodies but is not pushed back.
     */
    type: "static" | "dynamic" | "kinematic";
    /**
     * Multiplier on world gravity. 0 = floats, negative = falls upwards.
     */
    gravityScale: number;
    /**
     * Air resistance for movement; 0 = none, higher slows faster.
     */
    linearDamping: number;
    /**
     * Air resistance for spinning.
     */
    angularDamping: number;
    /**
     * true = never rotates from collisions (platformer characters).
     */
    fixedRotation: boolean;
    /**
     * true = continuous collision detection, for fast small objects that would tunnel through walls.
     */
    bullet: boolean;
    /**
     * Linear velocity [x, y] in world units per second. Read/write: writes apply before the next physics step.
     */
    get velocity(): Vec2;
    set velocity(value: Vec2Like);
    /**
     * Spin in degrees per second (counter-clockwise positive).
     */
    angularVelocity: number;
  }
  /**
   * Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. Colliders collide when each one's layer is included in the other's mask.
   * 
   * Category: Physics
   */
  export interface Collider2DComponent {
    /**
     * Shape type; uses size (box, capsule) or radius (circle).
     */
    shape: "box" | "circle" | "capsule";
    /**
     * box/capsule: [width, height] in world units (capsule is vertical).
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * circle: radius in world units.
     */
    radius: number;
    /**
     * Shape center offset [x, y] from the entity origin, in world units.
     */
    get offset(): Vec2;
    set offset(value: Vec2Like);
    /**
     * true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement.
     */
    isTrigger: boolean;
    /**
     * Surface friction; 0 = ice, 1 = grippy.
     */
    friction: number;
    /**
     * Bounciness: 0 = no bounce, 1 = perfectly elastic.
     */
    restitution: number;
    /**
     * Mass per area; mass = density * shape area.
     */
    density: number;
    /**
     * Collision category of this collider, 0..31.
     */
    layer: number;
    /**
     * Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i).
     */
    mask: number;
  }
  /**
   * Simple 3D physics body for arcade games (spheres and axis-aligned boxes; no rotation dynamics). Pair it with a Collider3D. Gravity comes from scene settings (gravity3D).
   * 
   * Category: Physics
   */
  export interface RigidBody3DComponent {
    /**
     * static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform.
     */
    type: "static" | "dynamic" | "kinematic";
    /**
     * Mass in kilograms (affects collision responses between dynamic bodies).
     */
    mass: number;
    /**
     * Multiplier on world gravity.
     */
    gravityScale: number;
    /**
     * Air resistance; 0 = none.
     */
    linearDamping: number;
    /**
     * Linear velocity [x, y, z] in meters per second. Read/write.
     */
    get velocity(): Vec3;
    set velocity(value: Vec3Like);
  }
  /**
   * Collision shape for 3D physics (axis-aligned box or sphere). Scaled by the Transform scale.
   * 
   * Category: Physics
   */
  export interface Collider3DComponent {
    /**
     * Shape type; uses size (box) or radius (sphere).
     */
    shape: "box" | "sphere";
    /**
     * box: full extents [x, y, z] in meters (axis-aligned, before Transform scale).
     */
    get size(): Vec3;
    set size(value: Vec3Like);
    /**
     * sphere: radius in meters.
     */
    radius: number;
    /**
     * Shape center offset [x, y, z] from the entity origin.
     */
    get offset(): Vec3;
    set offset(value: Vec3Like);
    /**
     * true = sensor: reports overlaps but does not block movement.
     */
    isTrigger: boolean;
    /**
     * Surface friction; 0 = ice, 1 = grippy.
     */
    friction: number;
    /**
     * Bounciness: 0 = none, 1 = perfectly elastic.
     */
    restitution: number;
    /**
     * Collision category of this collider, 0..31.
     */
    layer: number;
    /**
     * Bitmask of layers this collider collides with. -1 = all layers.
     */
    mask: number;
  }
  /**
   * Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.
   * 
   * Category: Audio
   */
  export interface AudioSourceComponent {
    /**
     * Project-relative path of the sound (.wav, .ogg or .mp3). (asset path: audio)
     */
    clip: string;
    /**
     * Loudness multiplier, 0 (silent) to 1 (full).
     */
    volume: number;
    /**
     * Playback speed multiplier; 2 = one octave higher and twice as fast.
     */
    pitch: number;
    /**
     * Restart the clip when it ends.
     */
    loop: boolean;
    /**
     * Start playing when the entity spawns / the scene loads.
     */
    playOnStart: boolean;
    /**
     * Runtime state: true while a voice is playing. Set true to play, false to stop.
     */
    playing: boolean;
    /**
     * true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI).
     */
    spatial: boolean;
    /**
     * Spatial only: distance in world units where the volume reaches 0.
     */
    range: number;
  }
  /**
   * The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the primary camera is used.
   * 
   * Category: Audio
   */
  export interface AudioListenerComponent {
    /**
     * Master volume multiplier for everything this listener hears.
     */
    volume: number;
  }
  /**
   * Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class extending Behaviour (see docs/SCRIPTING.md).
   * 
   * Category: Scripting
   */
  export interface ScriptComponent {
    /**
     * Project-relative path of the script, e.g. "scripts/player.js". (asset path: script)
     */
    path: string;
    /**
     * JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. Lets one script serve many entities with different settings. Returns a plain-object COPY; assign a new value to write.
     */
    props: any;
    /**
     * false = the script receives no callbacks.
     */
    enabled: boolean;
  }
  /**
   * Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.
   * 
   * Category: Scene
   */
  export interface SceneSettingsComponent {
    /**
     * Base light added to all lit 3D surfaces so shadows are not pitch black.
     */
    get ambientLight(): Color;
    set ambientLight(value: ColorLike);
    /**
     * 2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards).
     */
    get gravity2D(): Vec2;
    set gravity2D(value: Vec2Like);
    /**
     * 3D gravity [x, y, z] in m/s^2 (default 9.81 downwards).
     */
    get gravity3D(): Vec3;
    set gravity3D(value: Vec3Like);
    /**
     * Color distant 3D objects fade to.
     */
    get fogColor(): Color;
    set fogColor(value: ColorLike);
    /**
     * Fog thickness; 0 disables fog.
     */
    fogDensity: number;
    /**
     * Top color of the 3D background gradient (used when a perspective camera clears).
     */
    get skyColor(): Color;
    set skyColor(value: ColorLike);
    /**
     * Bottom color of the 3D background gradient.
     */
    get horizonColor(): Color;
    set horizonColor(value: ColorLike);
    /**
     * Looping background music asset path. Empty = none. (asset path: audio)
     */
    music: string;
    /**
     * Volume of the background music, 0..1.
     */
    musicVolume: number;
  }
  /** Component views by name, as returned by entity.get(name). */
  export interface Components {
    EntityInfo: EntityInfoComponent;
    Transform: TransformComponent;
    Camera: CameraComponent;
    Sprite: SpriteComponent;
    SpriteAnimator: SpriteAnimatorComponent;
    Shape2D: Shape2DComponent;
    Text: TextComponent;
    Tilemap: TilemapComponent;
    ParticleEmitter: ParticleEmitterComponent;
    MeshRenderer: MeshRendererComponent;
    Light: LightComponent;
    RigidBody2D: RigidBody2DComponent;
    Collider2D: Collider2DComponent;
    RigidBody3D: RigidBody3DComponent;
    Collider3D: Collider3DComponent;
    AudioSource: AudioSourceComponent;
    AudioListener: AudioListenerComponent;
    Script: ScriptComponent;
    SceneSettings: SceneSettingsComponent;
  }
  /** Field objects accepted by entity.add(name, fields) / entity.set(name, fields) and world.spawn. */
  export interface ComponentInit {
    EntityInfo: { id?: string; name?: string; active?: boolean };
    Transform: { position?: Vec3Like; rotation?: Vec3Like; scale?: Vec3Like };
    Camera: { projection?: "orthographic" | "perspective"; fov?: number; orthoSize?: number; nearPlane?: number; farPlane?: number; clearColor?: ColorLike; clear?: boolean; primary?: boolean; depth?: number };
    Sprite: { texture?: string; region?: RectLike; size?: Vec2Like; pivot?: Vec2Like; color?: ColorLike; flipX?: boolean; flipY?: boolean; layer?: number; space?: "world" | "screen"; pixelArt?: boolean };
    SpriteAnimator: { columns?: number; rows?: number; firstFrame?: number; lastFrame?: number; fps?: number; loop?: boolean; playing?: boolean; time?: number; frame?: number };
    Shape2D: { shape?: "rectangle" | "circle" | "line" | "triangle"; size?: Vec2Like; color?: ColorLike; filled?: boolean; thickness?: number; layer?: number; space?: "world" | "screen" };
    Text: { text?: string; font?: string; fontSize?: number; color?: ColorLike; align?: "left" | "center" | "right"; pivot?: Vec2Like; maxWidth?: number; layer?: number; space?: "world" | "screen" };
    Tilemap: { tileset?: string; tileSize?: Vec2Like; columns?: number; width?: number; height?: number; tiles?: any; solidTiles?: any; color?: ColorLike; layer?: number };
    ParticleEmitter: { emitting?: boolean; rate?: number; burst?: number; maxParticles?: number; lifetime?: number; lifetimeVariance?: number; speed?: number; speedVariance?: number; direction?: number; spread?: number; gravity?: Vec3Like; startSize?: number; endSize?: number; startColor?: ColorLike; endColor?: ColorLike; texture?: string; worldSpace?: boolean; is3D?: boolean; layer?: number };
    MeshRenderer: { mesh?: string; texture?: string; color?: ColorLike; metallic?: number; roughness?: number; emissive?: ColorLike; unlit?: boolean; castShadows?: boolean; receiveShadows?: boolean; uvScale?: Vec2Like };
    Light: { type?: "directional" | "point" | "spot"; color?: ColorLike; intensity?: number; range?: number; spotAngle?: number; castShadows?: boolean };
    RigidBody2D: { type?: "static" | "dynamic" | "kinematic"; gravityScale?: number; linearDamping?: number; angularDamping?: number; fixedRotation?: boolean; bullet?: boolean; velocity?: Vec2Like; angularVelocity?: number };
    Collider2D: { shape?: "box" | "circle" | "capsule"; size?: Vec2Like; radius?: number; offset?: Vec2Like; isTrigger?: boolean; friction?: number; restitution?: number; density?: number; layer?: number; mask?: number };
    RigidBody3D: { type?: "static" | "dynamic" | "kinematic"; mass?: number; gravityScale?: number; linearDamping?: number; velocity?: Vec3Like };
    Collider3D: { shape?: "box" | "sphere"; size?: Vec3Like; radius?: number; offset?: Vec3Like; isTrigger?: boolean; friction?: number; restitution?: number; layer?: number; mask?: number };
    AudioSource: { clip?: string; volume?: number; pitch?: number; loop?: boolean; playOnStart?: boolean; playing?: boolean; spatial?: boolean; range?: number };
    AudioListener: { volume?: number };
    Script: { path?: string; props?: any; enabled?: boolean };
    SceneSettings: { ambientLight?: ColorLike; gravity2D?: Vec2Like; gravity3D?: Vec3Like; fogColor?: ColorLike; fogDensity?: number; skyColor?: ColorLike; horizonColor?: ColorLike; music?: string; musicVolume?: number };
  }
}

/**
 * Test API for tests/*.test.js, run headless by `factoria test`.
 */
declare module "factoria:test" {
  import type { Entity, WorldAPI, TimeAPI, Json, Vec2Like } from "factoria";
  /**
   * Matchers returned by expect().
   */
  export interface Expectation {
    /**
     * Strict equality (Object.is).
     */
    toBe(expected: unknown): void;
    /**
     * Deep equality (vectors compared by value).
     */
    toEqual(expected: unknown): void;
    toBeCloseTo(expected: number, digits?: number): void;
    toBeGreaterThan(n: number): void;
    toBeGreaterThanOrEqual(n: number): void;
    toBeLessThan(n: number): void;
    toBeLessThanOrEqual(n: number): void;
    toBeTruthy(): void;
    toBeFalsy(): void;
    toBeNull(): void;
    toBeUndefined(): void;
    toBeDefined(): void;
    toBeNaN(): void;
    toContain(item: unknown): void;
    toHaveLength(n: number): void;
    toMatch(pattern: string | RegExp): void;
    toBeInstanceOf(cls: Function): void;
    toThrow(expected?: string | RegExp | Function): void;
    /**
     * Negates the matcher.
     */
    readonly not: Expectation;
  }

  export interface TestFn {
    (name: string, fn: () => void | Promise<void>): void;
    skip(name: string, fn: () => void | Promise<void>): void;
  }

  export interface DescribeFn {
    (name: string, fn: () => void): void;
    skip(name: string, fn: () => void): void;
  }

  /**
   * Drives the running game from a test.
   */
  export interface TestGame {
    /**
     * Loads a scene immediately (reseeds the RNG).
     */
    load(path: string): void;
    /**
     * Simulates frames at the fixed rate.
     */
    step(frames?: number): void;
    /**
     * Holds an action down until release().
     */
    press(action: string): void;
    release(action: string): void;
    /**
     * Press for one frame, then release.
     */
    tap(action: string): void;
    keyDown(key: string): void;
    keyUp(key: string): void;
    mouseMove(screenPos: Vec2Like): void;
    click(screenPos: Vec2Like, button?: "left" | "right" | "middle"): void;
    find(idOrName: string): Entity | null;
    readonly world: WorldAPI;
    readonly time: TimeAPI;
    /**
     * Saves a PNG of the game (needs graphics).
     */
    screenshot(path: string): void;
    /**
     * JSON dump of the game state.
     */
    state(): Json;
  }

  /**
   * Declares a test.
   */
  export const test: TestFn;

  /**
   * Groups tests.
   */
  export const describe: DescribeFn;

  /**
   * Starts an assertion.
   */
  export function expect(value: unknown): Expectation;

  /**
   * Runs before each test of the enclosing describe().
   */
  export function beforeEach(fn: () => void): void;

  /**
   * Runs after each test of the enclosing describe().
   */
  export function afterEach(fn: () => void): void;

  /**
   * The game under test.
   */
  export const game: TestGame;

}


```
