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
| `bloom` | bool | `false` | Bloom (glow) post-process: bright pixels bleed light into their surroundings, the neon / laser / fire / explosion look. Works for 2D and 3D cameras, is applied to the whole finished frame (screen-space HUD included, unless bloomScreenSpace is false) and shows in screenshots. Combine with blend "additive" on Sprite, Shape2D or ParticleEmitter instead of hand-drawing blurred halo sprites. Off by default; costs a few extra render passes per frame (cheap on a GPU, about 5 ms at 1280x720 on the software renderer used for headless runs). Tune with bloomThreshold, bloomIntensity and bloomRadius; keep the HUD crisp with bloomScreenSpace. |
| `bloomThreshold` | float | `0.7` | Only used when bloom is true. Brightness (0..1, the largest of a pixel's r, g, b) at which glow starts: pixels at or below it do not glow, the glow ramps up linearly to full strength at 1 (white / fully saturated). Lower it (0.3-0.6) to make dim colors glow too; raise it (0.9+) so only the brightest pixels do (values above 0.99 behave like 0.99). Range 0.0..1.0. |
| `bloomIntensity` | float | `1.2` | Only used when bloom is true. Strength of the glow that is added back onto the frame: 0 = none, 1 = the blurred bright pixels are added once, 2 = twice (brighter, saturates sooner). Limited to 0..10. Range 0.0..10.0. |
| `bloomRadius` | float | `20.0` | Only used when bloom is true. How far the glow reaches, in design pixels (1280x720 by default): a gaussian blur whose visible halo fades out roughly this far from the bright pixels. Values below ~5 behave like 5 (the glow is computed at reduced resolution, and larger radii at even lower resolution, so wide glows are softer). Limited to 1..128. Range 1.0..128.0. |
| `bloomScreenSpace` | bool | `true` | Only used when bloom is true. true (default): the whole finished frame glows, screen-space items (Sprite, Shape2D, Text with space "screen", and debug text) included, so a bright neon title or HUD icon glows too. false: screen-space items are drawn AFTER the bloom, so the HUD (score, lives, menus) stays crisp and never glows while the world still does. Set it to false whenever the HUD has white or bright text over a glowing world; leave it true to make a screen-space title or logo glow. |

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
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing: alpha (normal), additive (glow, neon, fire, lasers; brightens), multiply (darkens/tints). |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to. [0,0] top-left (default), [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio. |

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
| `shape` | enum: rectangle \\| circle \\| line \\| triangle \\| diamond \\| polygon \\| star | `"rectangle"` | Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square rotated 45 degrees when size is square; handy for gems, enemies and neon markers). polygon: a regular polygon with `sides` sides whose vertices lie on the ellipse inscribed in the size box, first vertex pointing up (hexagons, pentagons, octagons; many sides approach a circle). star: `points` tips on that ellipse, first tip pointing up, with notches at `innerRadius` of the outer radius in between. Outlines (filled = false) of triangle, diamond, polygon and star grow INWARD from the silhouette, like the rectangle's, so a thick outline never pokes out of the size box. |
| `size` | vec2 | `[32.0,32.0]` | rectangle/triangle/diamond/polygon/star: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Fill or outline color. |
| `filled` | bool | `true` | true = solid shape, false = outline only (lines are always drawn as strokes). |
| `thickness` | float | `2.0` | Outline / line thickness in world units. Range 0.0..10000.0. |
| `layer` | int | `0` | Draw order. Higher layers draw on top. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down. |
| `pivot` | vec2 | `[0.5,0.5]` | Anchor point within the shape's size box for every shape but line: [0.5,0.5] = the box centre sits on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place. |
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing: alpha (normal), additive (glow/neon), multiply (darken). |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right). |
| `sides` | int | `6` | polygon only: number of sides (3 = triangle, 6 = hexagon, 8 = octagon). Range 3.0..64.0. |
| `points` | int | `5` | star only: number of tips (5 = the classic star). Range 3.0..64.0. |
| `innerRadius` | float | `0.5` | star only: radius of the notches between the tips as a fraction of the outer radius. 0.5 = classic star, near 1 = a fat spiky polygon, near 0 = thin needles. Range 0.0..1.0. |

### Text

Draws a string with a TrueType font (or the built-in font). Works in world and screen space.

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | string | `"Text"` | The string to draw. Use \n for line breaks. |
| `font` | asset (font) | `""` | Project-relative path of a .ttf font. Empty uses the built-in font, DejaVu Sans (Latin, Greek, Cyrillic); "builtin:pixel" is Press Start 2P. Characters the font has no glyph for draw as nothing and log one warning per font: Chinese, Japanese and Korean need a .ttf that covers them (e.g. Noto Sans SC, JP or KR). |
| `fontSize` | float | `24.0` | Glyph height in world units (pixels in 2D). Range 1.0..4096.0. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Text color. |
| `align` | enum: left \\| center \\| right | `"left"` | Horizontal alignment of lines inside the text box. |
| `pivot` | vec2 | `[0.0,1.0]` | Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right. |
| `maxWidth` | float | `0.0` | If > 0, lines wrap at this width in world units. 0 = no wrapping. Range 0.0..100000.0. |
| `layer` | int | `100` | Draw order. Higher layers draw on top. Text defaults above sprites. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + position [-20, 20] = right-aligned 20px from the top-right corner. |

### Tilemap

A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. Solid tiles can generate static 2D collision.

| Field | Type | Default | Description |
|---|---|---|---|
| `tileset` | asset (texture) | `""` | Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom). |
| `tileSize` | vec2 | `[16.0,16.0]` | Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units). |
| `columns` | int | `0` | Number of tile columns in the tileset texture (used to find a tile's source rectangle). Optional: 0 (the default) derives it from the tileset texture, as many whole tiles of tileSize.x as fit across its width. Set it only when the image has a different layout. Range 0.0..4096.0. |
| `width` | int | `0` | Map width in tiles, for a flat tiles array. Not needed when tiles is an array of rows (the rows define the size; drawing and collision both use it). Range 0.0..65536.0. |
| `height` | int | `0` | Map height in tiles, for a flat tiles array. Not needed when tiles is an array of rows. Range 0.0..65536.0. |
| `tiles` | json | `[]` | Tile indices, row-major with row 0 at the TOP: either a flat array of width*height integers (set width and height) or an array of rows (the size comes from the rows). -1 = empty. |
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
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing of particles: additive is ideal for sparks, fire, magic and neon effects. |
| `autoDestroy` | bool | `false` | Destroy the entity automatically once it is not emitting and all its particles died. Use with burst > 0 and emitting = false for one-shot effects (explosions, pickups). |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: HUD/UI effects (menu sparks, score bursts) in design pixels, origin TOP-LEFT, +Y down, unaffected by cameras and drawn in the screen-space pass (so with Camera.bloomScreenSpace = false they are not bloomed). direction, gravity and speed keep their world meaning on screen: 90 = up, negative gravity y falls down the screen. Ignored (treated as world) when is3D is true. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right). |

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
| `oneWay` | bool | `false` | One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump up through it from below and pass sideways. |

### RigidBody3D

Simple 3D physics body for arcade games (spheres and oriented boxes). Pair it with a Collider3D. Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider (continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles and settles on a face; set lockRotation for a character or an upright crate. A sphere is an arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body that stays nearly still for half a second falls asleep together with the bodies it touches (no cost, no events) and wakes when touched by something moving, when gameplay writes its position, rotation or velocity, applies a force, or when what it rests on goes away.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: static \\| dynamic \\| kinematic | `"dynamic"` | static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform. |
| `mass` | float | `1.0` | Mass in kilograms (affects collision responses between dynamic bodies). Range 0.0001..1000000.0. |
| `gravityScale` | float | `1.0` | Multiplier on world gravity. |
| `linearDamping` | float | `0.0` | Air resistance; 0 = none. Range 0.0..1000.0. |
| `velocity` | vec3 | `[0.0,0.0,0.0]` | Linear velocity [x, y, z] in meters per second. Read/write. |
| `angularVelocity` | vec3 | `[0.0,0.0,0.0]` | Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step. Read/write (writing it wakes a sleeping body). A box spinning about a non-principal axis keeps its angular momentum, so this vector wanders (precession) while it tumbles. |
| `rollWithMotion` | bool | `true` | Sphere colliders only. true (default, arcade ball): while it touches the ground the sphere is spun to match its rolling motion (sets angularVelocity from the horizontal velocity) and uses rolling resistance (rollingFriction) instead of sliding friction; contacts never turn it, so setting velocity every frame steers it exactly. false: the sphere is a rigid body (solid-sphere inertia 2/5 m r^2): friction at the contact point spins it, so on a slope it rolls (spin = speed / radius) and a glancing hit makes it spin; on flat ground it keeps rolling until angularDamping / linearDamping or an obstacle stops it. Add lockRotation for a ball that slides and is never spun by contacts. |
| `rollingFriction` | float | `0.02` | Rolling resistance of a dynamic sphere with rollWithMotion = true: friction cap = rollingFriction * normal force, replacing the sliding friction of its contacts, so on flat ground its speed decays by about rollingFriction * gravity per second (default 0.02 rolls about 23 m from 3 m/s; 0 never slows down). Ignored when rollWithMotion is false (then Collider3D.friction acts at the contact point of the rigid sphere) and for boxes. Range 0.0..10.0. |
| `angularDamping` | float | `0.0` | Rotation drag of a dynamic body: angularVelocity is divided by (1 + dt * angularDamping) every step, so 0 = a spinning body keeps spinning in the air, larger values slow it down faster. Range 0.0..1000.0. |
| `lockRotation` | bool | `false` | true = collisions and friction never turn this body (a dynamic box, or a sphere with rollWithMotion = false): it stays upright and slides, as boxes did before rotation dynamics. Use it for characters and upright crates. angularVelocity and Transform.rotation written by gameplay still turn it. A rollWithMotion sphere is never turned by contacts either way. |

### Collider3D

Collision shape for 3D physics (box or sphere). Boxes are ORIENTED: they follow the entity's world rotation (parents included), so a box rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| sphere | `"box"` | Shape type; uses size (box) or radius (sphere). |
| `size` | vec3 | `[1.0,1.0,1.0]` | box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale. |
| `radius` | float | `0.5` | sphere: radius in meters. |
| `offset` | vec3 | `[0.0,0.0,0.0]` | Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity. |
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

### `ai.models`

List the models each AI provider offers (the values for roles.<role>.model).

Asks the providers themselves, so newly released models show up: Claude Code through its CLI (aliases such as opus first, then full names; no model call, no usage), the Anthropic API and OpenAI-compatible APIs through GET /models. Codex and generic CLIs cannot list their models: their entry has an error. Without `provider` it lists every provider that ai.providers reports available; one provider's failure is in its own entry (error, hint) and does not fail the call. Returns {providers:[{name, models:[{id, name, description, resolved}], error?, hint?}]}: id is the value for roles.<role>.model, name the display name (empty when the provider gives none), description one line, resolved the model an alias stands for (empty for a full name). Example: {"provider":"claude-code"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `provider` | string | no | Only this provider (a name from ai.providers). Omit for every available one. |

### `ai.providers`

List configured AI providers and roles, or diagnose which ones are usable (doctor).

action "list" (default) shows providers and the role mapping from ~/.factoria/ai.json. action "doctor" also checks for CLIs (claude, codex, ant) and API keys (never printed). Example: {"action":"doctor"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["list","doctor"] | no | list or doctor. Default "list". |

### `ai.run` (modifies state)

Run an AI agent on a task in the current project (blocks until it finishes).

Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers (claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role "worker" or "fast" and a self-contained task; the result's finalText is the sub-agent's report. Example: {"task":"Add a pause menu","role":"orchestrator","maxCostUsd":2}

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

### `assets.import` (modifies state)

Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF...) into the project's assets/ folder and record where it came from.

Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance (origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. The importer is chosen by the extension:
- .png .jpg .tga .bmp, .wav .ogg .mp3, .ttf .otf, .glb: copied as they are (images are checked to decode).
- .gltf: copied with the .bin buffers and images it refers to, which must sit next to it or below it.
- .aseprite .ase: becomes ONE PNG sprite sheet (frames in a grid, `columns` per row, default ceil(sqrt(frames))) and the `sheet` entry of assets.json: columns, rows, frameWidth, frameHeight, frames and a clip per tag (firstFrame, lastFrame, fps from the frame durations). Hidden layers are left out, layer and cel opacity apply, RGBA, grayscale and indexed colors work. Blend modes other than normal are drawn as normal, and ping-pong or reverse tags become forward clips; the result says so. The result lists the Sprite and SpriteAnimator settings that play it.
- .psd: the merged image becomes a PNG (layers are flattened).
- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the bounds so you can scale it.
- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither installed the error says where to get them.
Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/ by default) or at `path`, which must be under assets/. An existing file is an error unless overwrite is true. Example: {"source":"C:/art/hero.aseprite","license":"CC0","author":"Ana"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first. |
| `path` | string | no | Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/ or assets/fonts/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX). |
| `license` | string | no | License or terms of the file, e.g. "CC0", "CC-BY 4.0", "bought from itch.io, single project". Recorded in assets.json. |
| `author` | string | no | Who made it. Recorded in assets.json for the credits. |
| `sourceUrl` | string | no | Where the file came from (a page URL). Recorded as the provenance source instead of the local path. |
| `ai` | boolean | no | Set true when AI made the content elsewhere (Steam's AI disclosure reads it). Leave out when unknown. |
| `columns` | integer | no | Aseprite only: frames per row of the sheet (default ceil(sqrt(frames))). |
| `overwrite` | boolean | no | Replace files that already exist. Default false. |

### `assets.list`

List project asset files with type and size.

Example: assets.list {"folder":"assets","extension":".png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | no | Project-relative folder. Default "assets". |
| `extension` | string | no | Only files with this extension, e.g. .png |

### `assets.slice_sheet` (modifies state)

Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them.

SpriteAnimator plays a uniform grid of frames (columns x rows, row-major from the top-left). Two ways to get one:
1. The image already is a grid: give columns/rows (or frameWidth/frameHeight). The grid is checked against the image size (a width that columns does not divide is an error that lists the columns that fit) and recorded as the `sheet` of the image in assets.json. Example: {"path":"assets/hero.png","columns":4,"rows":2,"fps":12}.
2. Frames separated by transparent gutters and of uneven sizes, as AI-generated and downloaded sheets often are: pass auto: true. Every group of touching pixels is a sprite (sprites whose boxes overlap are one frame), ordered by rows then columns, and repacked into a uniform grid of the largest sprite's size, each centred (align "bottom" stands characters on the same ground line). The new PNG is `out` (default <name>_sheet.png next to the image; the source is kept). `frames` is the number of sprites you expect: a different count is an error that lists what was found. Example: {"path":"assets/hero_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}.
background "auto" first makes a solid background transparent (the four corners must be the same opaque colour; the background that touches them is cleared, the same colour inside a sprite stays), also for a grid. The result has the `sheet`, the SpriteAnimator fields and the Sprite texture to use. Aseprite files need no slicing: assets.import reads their frames and tags.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative image (png, jpg, tga, bmp), e.g. "assets/hero.png". |
| `columns` | integer | no | Grid mode: frames per row (1 if neither columns nor frameWidth is given). With auto: frames per row of the new sheet (default: the most sprites found in one row). |
| `rows` | integer | no | Grid mode: number of rows (1 if neither rows nor frameHeight is given). |
| `frameWidth` | integer | no | Grid mode: width of a frame in pixels, instead of columns. |
| `frameHeight` | integer | no | Grid mode: height of a frame in pixels, instead of rows. |
| `frames` | integer | no | Grid mode: how many cells are used, row by row (default all; the last row may be partly empty). With auto: the number of sprites you expect (a different count is an error). |
| `fps` | number | no | Playback speed to put in the SpriteAnimator fields of the result (default 10). Not stored in assets.json. |
| `auto` | boolean | no | Find the frames (groups of touching pixels separated by transparent gutters) and repack them into a uniform grid. Default false. |
| `align` | string ["center","bottom"] | no | auto only: where a sprite sits in its cell. center (default), or bottom: centred horizontally with feet on the cell's bottom edge, for characters standing on the ground. |
| `background` | string ["none","auto"] | no | auto: first make the solid background (the four corners the same opaque colour) transparent. Default none. |
| `out` | string | no | PNG to write when the pixels change (auto, background) or when given: default <name>_sheet.png next to the image. An existing file is replaced; use the image's own path to change it in place. |

## audio

### `audio.log`

List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.

Every play request is logged: audio.play and audio.music from scripts, AudioSource components and scene music (`music: true`), with `ok: false` when the clip failed to load. `frame`/`time` are the scene clock (time.frame / time.elapsed in scripts). Use it after game.step to check that a sound fired. `after` (a seq from a previous call) returns only newer entries; `path` keeps entries whose path equals it or ends with /<path>. Example: audio.log {"path":"jump.wav"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `path` | string | no | Only this clip: a project-relative path or a file name like "jump.wav". |
| `max` | integer | no | Return at most this many (the newest). Default 200. |

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

Example: {"name":"scripting"}. Long pages can be read in slices with startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components, licenses).

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

Folders need recursive=true. factoria.json and ENGINE_FEEDBACK.json cannot be deleted. Not undoable unless the project is under version control. Inside .factoria/ (screenshots, saves, AI transcripts) only the scratch folder .factoria/tmp/ can be deleted, the same folder fs.write and scene.save may write to. Example: {"path":"scripts/old.js"} or {"path":".factoria/tmp","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path. |
| `recursive` | boolean | no | Delete a folder and everything in it. Default false. |

### `fs.edit` (modifies state)

Replace exact text in a file (must match exactly once unless replaceAll).

Example: {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}. Fails if 'find' is not found or matches several places; include more surrounding text to make it unique. Same write rule as fs.write (inside .factoria/ only .factoria/tmp/ may be edited).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `find` | string | yes | Exact text to find (whitespace-sensitive). |
| `replace` | string | yes | Replacement text (may be empty to delete). |
| `replaceAll` | boolean | no | Replace every occurrence. Default false. |

### `fs.list`

List files and folders in the project.

Project-relative. Hides the tools' folders (.factoria, version control) except the scratch folder .factoria/tmp. Example: {"path":"scenes","recursive":true}

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

Create or overwrite a file (text, or binary via base64; parent folders are created).

Example: {"path":"scripts/enemy.js","content":"export default class ..."}. For binary files such as PNG sprites pass encoding="base64" and the base64 of the bytes as content (e.g. {"path":"sprites/hero.png","encoding":"base64","content":"iVBORw0KGgo..."}). For small changes to an existing file prefer fs.edit. .json files are checked for syntax and a warning is returned if invalid; run project.validate afterwards. Writing into .factoria/ is refused except .factoria/tmp/, the scratch folder for throw-away files (the same rule as scene.save).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `content` | string | yes | Full new file content (base64 text when encoding=base64). |
| `encoding` | string ["utf8","base64"] | no | "utf8" writes content as text; "base64" decodes it and writes the bytes (images, audio). Default "utf8". |
| `overwrite` | boolean | no | Allow replacing an existing file. Default true. |

## game

### `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}, {"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}, {"touch":{"id":1,"position":[200,300],"down":true}}. gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. The input is applied now and seen by the next frame (game.step). Example: game.input {"press":["jump"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | Action name (with `down`). |
| `key` | string | no | Key or mouse button name (with `down`). |
| `down` | boolean | no | New state for action/key. Default true. |
| `press` | array | no |  |
| `release` | array | no |  |
| `mouse` | object | no | {position:[x,y] in design pixels, left/right/middle: bool}. |
| `gamepad` | any | no | {index?: 0..3, connected?: bool, buttons?: {A: true, DpadLeft: false...}, axes?: {LeftX: -1, RightTrigger: 0.5...}}, or an array of those for several pads. |
| `touch` | any | no | {id?: number (default 1), position?: [x,y] design pixels, down?: bool (default true)}, or an array of those for several fingers. |

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

Draws the game view as it is now (design resolution), saves it and returns the path; clients display the image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect. Default path .factoria/screenshots/frame_<n>.png. Example: game.screenshot {"path":"shots/start.png"}

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

### `physics.shape_cast`

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

## play

### `play.report`

What happened while the user played: perf, spikes, warnings/errors, their problem marks and screenshots.

Call it when the user says they played the game and saw problems (slow, ugly UI, bugs). Returns the session.json content (perf: avg/p95/max frame ms and frames over 16.7/33 ms; spikes: slowest frames with entity count and render stats; logs: warnings and errors; marks: frame, time, note and screenshot path, 1-based `n`), `replay` (the input file, absolute path) and `replayHow`. The result carries ONE picture ($image): the screenshot of mark `mark` (default 1); call again with mark 2, 3... to see the others. `session` defaults to the latest (see play.sessions). Example: play.report {"mark":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | Session folder name from play.sessions. Default: the latest. |
| `mark` | integer | no | Which mark's screenshot to attach as the picture. Default 1. |

### `play.sessions`

List the recent play sessions recorded by the editor (Play .. Stop), newest first.

Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the editor. Rows have a short summary: scene, duration, frame time p95/max, number of warnings/errors and the user's marks (notes). Call play.report {session} for the details and screenshots. Example: play.sessions {"max":5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `max` | integer | no | How many sessions to list. Default 10. |

## scene

### `prefab.save` (modifies state)

Save an entity of the running world, with its children, as a prefab file.

Writes {"format":"factoria.prefab/1","entity":{...}} in the canonical compact layout (the one scene.save and scene.format write), ready to commit and to instantiate with scene.spawn {"prefab":path}, a scene entity {"prefab":path} or a scene.import_ascii legend. `id` is the id (or name) of an entity of the running world; the whole tree below it is saved with every component's non-default serialized fields (runtime state such as velocities and animation time is not). A prefab describes the reusable thing, not this instance, so the file does NOT carry: the ids (every instantiation gets fresh ones; an id stays only where another entity of the saved tree points at it through an Entity field, so those references survive); the root's Transform.position (where the instance happens to stand: the spawn call, the scene entity or the legend places each new instance; children keep their positions relative to the root; rotation and scale are kept); tags starting with 'tilemap:' (scene.import_ascii adds them to the objects it places, and a prefab carrying one would be destroyed when that map is re-imported); Entity fields pointing at an entity outside the saved tree (they would dangle). An entity created from a prefab saves fully expanded (no `prefab` key). To keep the exact position, save the whole world with scene.save instead. `path` is project-relative (or absolute inside the project), must end in .prefab.json and normally lives in prefabs/. An existing file is NOT replaced unless `overwrite` is true. Returns {path, entity (id of the saved entity in the running world), children (number of saved descendants), overwritten, notes?}; `notes` lists what was left out of the file when something noteworthy was. Errors name the id with did-you-mean suggestions or the path rule with a corrected name. Example: prefab.save {"id":"enemy_3","path":"prefabs/enemy.prefab.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity to save; its children are saved with it. |
| `path` | string | yes | Project-relative output path ending in .prefab.json, e.g. prefabs/enemy.prefab.json. |
| `overwrite` | boolean | no | Replace the file when it already exists. Without it an existing file is an error. Default false. |

## project

### `project.create` (modifies state)

Create a new game project from a template.

Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, scripts, a test, AGENTS.md, ENGINE_FEEDBACK.json and the real types/factoria.d.ts. Afterwards start `factoria mcp --project <dir>` to work on it. Example: {"dir":"my-game","template":"2d-platformer","name":"My Game"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `dir` | string | yes | Target folder (created; must be empty or new). |
| `template` | string | no | 2d-empty, 2d-platformer or 3d-empty (see project.templates). Default "2d-empty". |
| `name` | string | no | Display name (default: folder name). |
| `id` | string | no | Reverse-DNS id, e.g. com.example.mygame. |

### `project.export` (modifies state)

Package the game for a platform: a desktop bundle, an Android APK/AAB, or an iOS project.

Validates the project (factoria.json, name, mainScene, reverse-DNS id, the icon and export settings) and writes a fresh <out>/<game-slug>-<platform>/ folder (deleted and recreated on every call, but only when it is empty or an export wrote it: every export leaves a .factoria-export file at its top, and any other existing folder of that name is an error that says how to proceed, never deleted; the project itself is not modified). linux/windows/macos: the game plus the factoria_player runtime found next to the running factoria binary, so exporting for another OS than this machine's fails with a hint. android: a complete Gradle project that is then BUILT with its own Gradle wrapper (needs a JDK 17+ and the Android SDK, found automatically; the first build downloads Gradle and the Android Gradle plugin, so it takes minutes and needs network): `format` "apk" (default) or "aab" (Google Play bundle) leaves <slug>[-debug].apk/.aab next to the project and reports it as `artifact`; "gradle" only writes the project and builds nothing. `release` builds the release variant (signed with export.android.signing, else with the debug key and a warning). ios: the game plus an Xcode/CMake project and build_ios.sh. Android and iOS have a mode, reported as `mode`: "prebuilt" (the engine is the ready-made player in the mobile/ folder next to the factoria binary of the FactorIA download: no engine source, and for Android no NDK or CMake) or "source" (the engine is compiled from a source checkout, chosen by $FACTORIA_ENGINE_DIR or when factoria runs from a development build); with no players and no checkout the error says what to do. A failed Gradle build is an error that quotes what went wrong and where the log is (<out>/<slug>-android/build.log); the Gradle project stays on disk. Every export also writes FACTORIA_NOTICES.txt, the licenses of the engine code inside the game, where it ships with it (`notices`). Returns {outputDir, mode (android/ios), format and artifact (android), notices, files[], nextSteps[], warnings[]}; nextSteps lists what to do next (e.g. the adb install command). dryRun: true runs every check and writes nothing (no Gradle either): it returns {platform, outputDir (the folder an export would replace), mode, format, artifact (the file a build would write) and toolchain (android: the JDK and SDK found and where from), player (desktop), warnings[]} or the error the export would give (e.g. no JDK installed). Details: docs_read {"name":"exporting"}. Examples: {"platform":"windows","release":true}, {"platform":"android","format":"aab","release":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platform` | string | no | linux, windows, macos, android or ios (aliases win, mac, osx also work). Default: the machine running factoria. |
| `out` | string | no | Parent folder of the export, relative to the project folder and inside it. Default: build/export. |
| `format` | string ["apk","aab","gradle"] | no | Android only (other platforms ignore it): apk (an installable app, the default unless export.android.format says otherwise), aab (the Google Play bundle) or gradle (only the Gradle project, nothing is built and no JDK or SDK is needed). apk and aab run Gradle and need a JDK 17+ and the Android SDK. |
| `release` | boolean | no | Android: build the release APK/AAB (signed with export.android.signing and the keystore passwords from FACTORIA_ANDROID_KEYSTORE_PASSWORD / FACTORIA_ANDROID_KEY_PASSWORD or ~/.factoria/export.json; without a keystore the debug key is used, with a warning). Other platforms: only changes the build commands in nextSteps (and the iOS script). Default false. |
| `dryRun` | boolean | no | Only check whether the export can run (project, player or mobile mode, output folder): returns the plan or the error, writes nothing. Default false. |

### `project.info`

Show the project settings, input actions, current scene, scenes and scripts.

Returns the parsed factoria.json plus {currentScene, scenes[], scripts[], prefabs[], sceneErrors}. Example: project.info {}

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

Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, message and a fix hint. Checks every *.scene.json and *.prefab.json of the project, wherever it is kept (scenes/, prefabs/, levels/...; folders starting with '.', node_modules and a top-level build/ are skipped, like scene.format). Loads every scene, and every prefab on its own, into a temporary world, so it does not disturb a running game; anything the loader refuses is an error with the JSON pointer, e.g. an unknown field or a value outside a field's range ("Field 'sides': value 200 is outside the allowed range 3..64"; the offending field keeps its default, nothing is clamped). Warns once per scene or prefab file that is not in the canonical layout (fix: scene.format), and reports a .json that a script imports and that is not valid JSON once, as that file with line and column. Example: {} Warns about Script.props keys that do not exist on the behaviour, and about behaviour methods that look like misspelled lifecycle hooks (update() or onupdate() instead of onUpdate()).

## scene

### `scene.destroy` (modifies state)

Destroy an entity and its children.

Destruction is applied immediately when called outside a frame. Example: scene.destroy {"id":"coin_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.format` (modifies state)

Rewrite scene and prefab files in the canonical compact layout, without loading them.

Parses every *.scene.json and *.prefab.json file and writes it back exactly as the engine writes scenes (2-space indent, short arrays of numbers and strings on one line, long ones wrapped at about 100 columns, a Tilemap's `tiles` one map row per line). Run it after editing scenes or prefabs by hand so diffs stay small and the maps stay readable. Only whitespace changes: values and key order are kept, and every file is read back and compared with the original data before it is written. Nothing is loaded into the running world, so nothing else changes (files that already have the canonical layout are not touched). `paths` lists files (names ending in .scene.json or .prefab.json) or folders (searched recursively), project-relative; default: the whole project, skipping folders that start with '.', node_modules and a top-level build/. With `check` true nothing is written: the files that are not canonical are listed (use it in CI or to review). A file that is not valid JSON is reported in `errors` with its file, line and column and skipped; the other files are still processed. Returns {formatted: [paths], unchanged: n, errors: [{file, line?, column?, message, hint?}], notes?}, or with `check`: {notCanonical: [paths], unchanged: n, errors, notes?}. With `check` and `strict` the command FAILS (error code not_canonical, the message lists the files, the hint says to run scene.format without `check`) when any file is not canonical: `factoria call` exits non-zero, so a CI step can gate on it. project.validate also warns once per non-canonical scene or prefab. Example: scene.format {"paths":["prefabs"],"check":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | no | Scene/prefab files or folders (recursive), project-relative. Default: every *.scene.json and *.prefab.json in the project. |
| `check` | boolean | no | true = write nothing, only list (notCanonical) the files whose layout differs from the canonical one. Default false. |
| `strict` | boolean | no | With check: fail with error code not_canonical when any file is not canonical, instead of only listing it. Ignored without check. Default false. |

### `scene.get_entity`

Get one entity with every component field (including defaults and runtime values).

Accepts the entity id or its name. Example: scene.get_entity {"id":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.import_ascii` (modifies state)

Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.

Author a tile level as text. `rows` is the map, one string per row, ONE CHARACTER PER TILE, row 0 = the TOP row (all rows the same length). `legend` maps each character to a tile index (integer) or to an object: {"tile"?: int, "prefab"?: "prefabs/x.prefab.json", "id"?: "player", "overrides"?: {component patches}, "offset"?: [dx, dy]}. '.' and ' ' are empty tiles unless the legend defines them. A glyph with a `tile` draws that tile; with a `prefab` it also spawns the prefab at the CENTRE of its cell (a glyph may have both; a prefab-only glyph leaves the tile empty). `overrides` patch the prefab's components per glyph; `offset` shifts the object (world units) from the cell centre. The tilemap is the entity `entity` (default "tilemap"): created when missing, updated when it exists; `tilemap` sets its Tilemap fields (tileset, tileSize, columns, solidTiles, color, layer; columns is optional: left at 0 it is derived from the tileset width / tileSize.x). Its position is the map's TOP-LEFT corner (+Y up, like Tilemap everywhere); pass `position` (+ `anchor`: top-left, bottom-left or center) to place it, e.g. anchor bottom-left at [0,0] puts the level's floor at y=0. Objects are ordinary top-level entities that save with the scene; ids are `id` from the legend (unique objects such as "player") or generated in row-major order as <prefab name>_<n> (coin_1, coin_2...); every object is tagged "tilemap:<entity>". With `replace` (default true) the objects of earlier imports into the same tilemap are destroyed first, so re-importing an edited map does not duplicate them. TWO WAYS TO USE IT. (1) With `path` it edits that scene FILE and nothing else: the file (or `from`, a base scene to start from; a missing `path` without `from` starts as an empty scene) is loaded into a scratch world, the map is imported into it and the result is written to `path` in the canonical layout of scene.save. The running world, audio, physics and scripts are not touched, so it is safe to call from a tool or a one-shot `factoria call` and the file can be rebuilt as often as needed. `dryRun` writes nothing and returns the scene JSON in `scene`. `edits` (file mode only) patches components of that scene's entities right after the map is imported and before the write, e.g. the camera and sky colour of a base scene: {"<entity id>": {"<Component>": {field: value}}}, each entry exactly scene.set_component (a missing component is added, only the given fields change, and a value outside a field's range is refused; Script.props is replaced as a whole unless the edit has "$merge": true next to its fields, e.g. {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}, which merges the given props into the current ones as an RFC 7386 JSON merge-patch: other props stay, null deletes one); a wrong entity, component or field fails the call naming it, with suggestions, and writes nothing. If the file has load errors the call fails instead of dropping them. (2) Without `path` it changes the RUNNING world (like scene.spawn); `save` then also writes the current scene file like scene.save, so it needs a scene you chose (--scene or scene.load): when the running scene is only the project's mainScene loaded by default, `save` is refused (error unsafe_save) instead of overwriting it. With `path`, `save` is ignored: the file is always written. Nothing is changed when an argument is wrong: errors name the row/column, the glyph, the legend and suggestions. Returns {tilemap, created, width, height, tileCount, spawned:[{id, prefab, glyph, cell:[col,row], position:[x,y]}], removed, tag, warnings, notes?, saved?} plus, with `path`, {path, from (the file it started from, null = empty scene), entityCount, dryRun, scene? (dryRun)}. Example: scene.import_ascii {"rows":["..........","...o..o...",".P......o.","##########"],"legend":{"#":0,"o":{"prefab":"prefabs/coin.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json","id":"player"}},"tilemap":{"tileset":"assets/tiles.png","tileSize":[32,32],"solidTiles":[0]},"anchor":"bottom-left","position":[0,0],"path":"scenes/level1.scene.json","from":"levels/base.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `rows` | array | yes | The map: one string per row, one character per tile, row 0 = TOP row, all rows the same length. |
| `legend` | object | yes | Glyph -> tile index (integer, -1 = empty) or {tile?: int, prefab?: 'prefabs/x.prefab.json', id?: 'player', overrides?: {Component: {fields}}, offset?: [dx, dy]}. '.' and ' ' mean empty unless defined here. |
| `tilemap` | object | no | Tilemap field values (tileset, tileSize, columns, solidTiles, color, layer) applied to the new or existing tilemap. The grid itself comes from rows/legend. |
| `entity` | string | no | Id of the tilemap entity: created if missing, updated if it exists. Default "tilemap". |
| `replace` | boolean | no | Destroy the objects spawned by earlier imports into this tilemap (tag tilemap:<entity>) first, so re-importing does not duplicate them. false keeps them. Default true. |
| `path` | string | no | File mode: project-relative scene file (e.g. scenes/level1.scene.json) to edit. It is loaded into a scratch world, the map is imported into it and it is written back; the running world is not touched. Does not exist yet (and no `from`): starts as an empty scene. Writable places only (not .factoria/ except .factoria/tmp/). |
| `from` | string | no | File mode (needs `path`): scene file to start from instead of `path`, e.g. a base scene with settings, camera and HUD but no map. `path` is then replaced by the result. Must exist. |
| `dryRun` | boolean | no | File mode (needs `path`): write nothing and return the resulting scene JSON in `scene`. Default false. |
| `edits` | object | no | File mode (needs `path`): {entity id: {Component: {field: value}}} applied to the scene after the map is imported and before it is written, each entry like scene.set_component (e.g. {"camera": {"Camera": {"clearColor": [0.5, 0.7, 0.9, 1]}}}). Add "$merge": true inside a component's entry to MERGE Script.props (RFC 7386: other props stay, null deletes a key) instead of replacing it: {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}. A wrong entity/component/field fails and nothing is written. |
| `save` | boolean | no | Running-world mode: also write the current scene file (like scene.save). Refused when the running scene is only the default mainScene (no --scene, no scene.load): pass `path` instead. Ignored when `path` is given. Default false. |
| `position` | array | no | [x, y] (or [x, y, z]) world position of the map's anchor point. Default: a new tilemap sits at [0,0] (its top-left corner); an existing one stays where it is. |
| `anchor` | string ["top-left","bottom-left","center"] | no | Which point of the map is placed at `position` (assumes an unrotated map). Default top-left, the Tilemap entity's own origin. |

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

Loads immediately (outside a frame) or at the end of the current frame. Like scene.reload it first re-reads script modules and factoria.json input actions that changed on disk and clears script errors. Load problems are returned in `messages`. Example: scene.load {"path":"scenes/level2.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path. |

### `scene.reload` (modifies state)

Reload the current scene from disk (discards runtime changes).

Resets the world to the saved scene file. Also re-reads what changed on disk: script modules (and the modules importing them), factoria.json input actions, fixedHz and deadzone; script errors are cleared. Example: scene.reload {}

### `scene.remove_component` (modifies state)

Remove a component from an entity.

Transform and EntityInfo cannot be removed. Example: scene.remove_component {"id":"player","component":"Script"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes |  |
| `component` | string | yes |  |

### `scene.save` (modifies state)

Save the running world to a scene file (current scene path by default).

Writes canonical scene JSON (only non-default fields, except settings.gravity2D and settings.gravity3D, which are always written so the file shows the gravity the level uses). Files inside .factoria/ belong to the engine and its tools: only the scratch folder .factoria/tmp/ may be written there (the same rule as fs.write and fs.delete). To change a scene FILE without touching the running world use scene.import_ascii with `path`. Example: scene.save {"path":"scenes/snapshot.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative output path. Default: the current scene. |

### `scene.set_component` (modifies state)

Add a component to an entity (if missing) and set the given fields.

`fields` is a partial object; unspecified fields keep their value. A value outside a field's range (see api.components) is refused, and a bad field changes nothing: errors name the field, the allowed values and the range. A field with free-form JSON content (Script.props) is REPLACED as a whole by default; with `merge` true `fields` is an RFC 7386 JSON merge-patch instead: an object for such a field is merged into the current one recursively (keys you do not mention stay, a null value deletes the key), and a null for any other field resets it to its default. Example: scene.set_component {"id":"player","component":"Sprite","fields":{"color":"red"}}; change one prop and keep the rest: scene.set_component {"id":"level","component":"Script","fields":{"props":{"levelIndex":3,"oldProp":null}},"merge":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |
| `component` | string | yes | Component name, e.g. Transform, Sprite, RigidBody2D. |
| `fields` | object | no | Field name -> value. |
| `merge` | boolean | no | true = read `fields` as an RFC 7386 JSON merge-patch: objects (Script.props) merge into the current value recursively, null deletes a key (or resets a plain field to its default). false = every given field is replaced as a whole. Default false. |

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

Cleared by scene.load, scene.reload and script.reload. Example: script.errors {}

### `script.eval` (modifies state)

Evaluate JavaScript in the running game context (REPL) and return the value.

The last expression is returned as JSON. Example: script.eval {"code":"world.find('player').get('Transform').position"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | JavaScript source. |

### `script.reload` (modifies state)

Re-import script modules edited on disk and restart the behaviours (the world is kept).

scene.load and scene.reload already re-import every module whose file changed (by modification time) and clear the script errors; use this to do the same without reloading the scene (entity state is kept, onStart runs again), or with `force` to re-import every module even if no file changed. Example: script.reload {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Re-import all modules, not only the changed ones. Default false. |

## setup

### `setup.install` (modifies state)

Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake (or open Xcode's App Store page).

Downloads and installs one component into $FACTORIA_HOME (default ~/.factoria) and returns {component, changed, steps[], paths, nextSteps[], warnings[], seconds}; every step says whether it was installed or skipped because it was already there. It downloads hundreds of megabytes (setup.status says how many: installSizeMb) and can take minutes: ask the user before calling it. `android`: JDK 21 (Eclipse Temurin) and the Android SDK command-line tools, platform-tools, platform 36 and build-tools 35.0.0 (the SDK found on this computer is reused, except Unity Hub's), saved in ~/.factoria/export.json so `project.export` finds them. It REFUSES with error code `license_required` until acceptLicenses is true: the Android SDK license is a legal agreement between the user and Google, so show the user the text from setup.status (components[].licenses[].text) and set acceptLicenses ONLY after they have read it and said yes; never set it on your own. `players`: the factoria_player of the other desktop OSes plus the prebuilt mobile libraries, for exports to other platforms without building anything; from the GitHub release of this factoria's version (a development build ahead of the last release fails with code `no_release`); platforms narrows it (windows, linux, macos, mobile). `cmake`: CMake 3.31 from Kitware (macOS only, for iOS exports) unless 3.24+ is found; force installs it anyway. `xcode` (macOS): cannot be installed by a program: it opens Xcode's App Store page and returns the steps the user must do (some need their password). Every download is checked against the publisher's checksum (error code `checksum_mismatch` installs nothing). Other error codes: network, cancelled, unsupported, invalid_argument, failed; the data of the error holds the steps done so far. Example: {"component":"android","acceptLicenses":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode"] | yes | What to install: android (JDK + Android SDK), players (other platforms' factoria_player + mobile libraries), cmake (iOS export), xcode (guidance only). |
| `acceptLicenses` | boolean | no | android: the user has read the Android SDK license (setup.status components[].licenses) and agreed to it. Without it the install refuses with license_required. Never set it without asking the user. Default false. |
| `platforms` | array | no | players: which players to install (default: every desktop OS but this one, plus the mobile libraries when this factoria has none next to it). |
| `force` | boolean | no | android, cmake, players: install again even when it is found (a JDK or CMake that is already there is used otherwise). Default false. |

### `setup.status`

Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode.

Returns {home, host, components[]}; each component is {id, title, state, details, paths, problems[], installSizeMb, licenses[], canInstall}. Components: `android` (JDK + Android SDK for APK/AAB exports), `players` (the factoria_player of the other desktop OSes and the prebuilt Android/iOS libraries, from the GitHub release of this factoria's version), `cmake` (3.24+, for the iOS export on a Mac) and `xcode` (macOS: status only, it cannot be installed by a program). state is installed | missing | partial | unsupported (nothing to do on this computer). problems[] says what is missing and how to fix it; `setup.install` fixes everything except Xcode. `licenses` (android only, only while the Android SDK license is not accepted yet) holds {id, title, text}: the full license the user must read and agree to before `setup.install` with acceptLicenses. The only network request is the fetch of that license text (fetchLicenses false skips it). Everything installed lives under `home` ($FACTORIA_HOME, default ~/.factoria). Details: docs_read {"name":"exporting"}. Example: {"component":"android"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode"] | no | Only this component (default: all of them). |
| `fetchLicenses` | boolean | no | Download the Android SDK license text when the license is not accepted yet (a network request). false = skip it (a polling UI). Default true. |


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
   * A gamepad button (Xbox layout: A bottom, B right, X left, Y top; LeftThumb/RightThumb are the stick clicks). Names are case-insensitive at run time.
   */
  export type GamepadButton = "A" | "B" | "X" | "Y" | "Start" | "Back" | "Guide" | "DpadLeft" | "DpadRight" | "DpadUp" | "DpadDown" | "LeftShoulder" | "RightShoulder" | "LeftThumb" | "RightThumb";

  /**
   * A gamepad axis: sticks run -1..1 with +Y up, triggers 0..1.
   */
  export type GamepadAxis = "LeftX" | "LeftY" | "RightX" | "RightY" | "LeftTrigger" | "RightTrigger";

  /**
   * Plain JSON data (objects, arrays, numbers, strings, booleans, null).
   */
  export type Json = any;

  /**
   * Shape swept by physics.shapeCast in 2D, centred on the cast position and axis-aligned. Sizes are full sizes in pixels, like Collider2D: { shape: "circle", radius: 8 } or { shape: "box", size: [16, 24] }.
   */
  export type CastShape2D = { shape: "circle"; radius: number } | { shape: "box"; size: Vec2Like };

  /**
   * Shape swept by physics.shapeCast in 3D, centred on the cast position and axis-aligned. Sizes are full sizes in meters, like Collider3D: { shape: "sphere", radius: 0.5 } or { shape: "box", size: [1, 2, 1] }.
   */
  export type CastShape3D = { shape: "sphere"; radius: number } | { shape: "box"; size: Vec3Like };

  /**
   * Options of world.spawn / world.spawnPrefab. rotation as a number = degrees around z. props are merged into Script.props.
   */
  export type SpawnOptions = { position?: Vec3Like; rotation?: number | Vec3Like; scale?: number | Vec3Like; parent?: Entity; props?: Record<string, any> };

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
   * Axis-aligned rectangle; (x, y) is the minimum corner (the bottom-left in the +Y-up world), w and h the size. Entity.bounds() returns one.
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
     * Destroys the entity (and children) at the end of the frame. It leaves physics at once: no collisions and no raycast or overlap hits from the call on.
     */
    destroy(): void;
    readonly parent: Entity | null;
    readonly children: Entity[];
    setParent(parent: EntityLike, keepWorld?: boolean): void;
    hasTag(tag: string): boolean;
    addTag(tag: string): void;
    removeTag(tag: string): void;
    /**
     * The script instance attached to this entity (constructed as soon as the entity is spawned or its scene loaded), or null. Its own fields are reachable: game.find("p").behaviour.hp.
     */
    readonly behaviour: (Behaviour & Record<string, any>) | null;
    /**
     * Calls behaviour[method](...args) if it exists.
     */
    send(method: string, ...args: any[]): any;
    /**
     * World-space axis-aligned rectangle { x, y, w, h } of this entity's 2D visual, or null. (x, y) is the minimum corner, i.e. the BOTTOM-LEFT in the +Y-up world: the same Rect convention as physics.overlapBox and debug.rect. Tilemap: its size as drawn (rows form or width x height) times tileSize, from the top-left corner at the entity position. Sprite and Shape2D: size and pivot (a circle is its bounding square, a line its stroked segment; the outline thickness of other shapes is ignored). Text: the laid-out box (approximate when headless, like ui.measureText). Scale and rotation are applied (the box around the rotated corners) and several visuals give their union. null when the entity has no world-space 2D visual: none at all, an empty Tilemap, or only screen-space ones (space: "screen"). Children are not included. Example: const map = world.find("map").bounds();
     */
    bounds(): Rect | null;
    /**
     * Touching ground below (2D pixels tolerance, default 2; 3D meters, default 0.05).
     */
    isGrounded(tolerance?: number): boolean;
    /**
     * Entity JSON as in scene files.
     */
    toJSON(): Json;
    /**
     * Solid contact against the body in `direction` (the obstacle lies that way): isTouching(vec2(1, 0)) = wall on the right, vec2(0, 1) = ceiling. Triggers never count.
     */
    isTouching(direction: Vec3Like, tolerance?: number): boolean;
    /**
     * Immediately spawns `count` particles at this entity's ParticleEmitter (works with emitting = false). No-op with a warning when there is no renderer (headless).
     */
    emitBurst(count?: number): void;
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
     * Default false. While time.scale is 0 (game.paused) the engine calls onUpdate and onLateUpdate only on behaviours whose runWhilePaused is true, with the REAL frame time as dt (time.dt is 0 then; time.unscaledDt is the real one). Set it as a class field (`runWhilePaused = true;`) on pause menus and anything else that must react while gameplay is frozen. onFixedUpdate never runs while paused. ui events and world.on listeners are delivered either way.
     */
    runWhilePaused: boolean;
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
     * Once, before the first update (props already applied). The instance exists (entity.behaviour) from the moment the entity is spawned or its scene is loaded; onStart runs on the next step.
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
     * Creates an entity from scene-file JSON ({ name, tags, components }). Vectors in component fields may be Vec2/Vec3, {x,y,z} objects or arrays (2D values get z = 0). The Script behaviour is constructed immediately (entity.behaviour), onStart runs before its first update.
     */
    spawn(entityJson: Json, opts?: SpawnOptions): Entity;
    /**
     * Instantiates a prefab file. `props` is merged into Script.props; `overrides` is entity JSON merged over the prefab (components deep-merge).
     */
    spawnPrefab(path: string, opts?: SpawnOptions & { overrides?: Json }): Entity;
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
   * One gamepad, from input.gamepad(index). Raw device state for local multiplayer; actions bound to Gamepad* names already match any pad.
   */
  export interface GamepadAPI {
    /**
     * A pad is plugged in at this index.
     */
    readonly connected: boolean;
    /**
     * Button held. Unknown names throw with a suggestion.
     */
    down(button: GamepadButton): boolean;
    /**
     * Went down this frame.
     */
    pressed(button: GamepadButton): boolean;
    /**
     * Went up this frame (also when the pad was unplugged).
     */
    released(button: GamepadButton): boolean;
    /**
     * Stick -1..1 (+Y up) or trigger 0..1 with the deadzone applied, the same value the action bindings use (sticks: radial deadzone, the rest rescaled to the full range).
     */
    axis(axis: GamepadAxis): number;
    /**
     * The axis as the device reported it, without the deadzone.
     */
    rawAxis(axis: GamepadAxis): number;
  }

  /**
   * Input through named actions (factoria.json input.actions), raw keys or gamepads.
   */
  export interface InputAPI {
    /**
     * Action held. For an analog binding (gamepad stick or trigger) it means value >= 0.5. Unknown actions throw with a suggestion.
     */
    down(action: string): boolean;
    /**
     * Went down this frame.
     */
    pressed(action: string): boolean;
    released(action: string): boolean;
    /**
     * 0..1 strength of an action: 0 or 1 for keys, mouse, touch and pad buttons; for gamepad half-axis and trigger bindings the push after the deadzone (the maximum over the action's bindings). Unknown actions throw with a suggestion.
     */
    value(action: string): number;
    /**
     * -1..1 from two actions: value(positive) - value(negative). Analog with a gamepad stick bound to the actions; keys give exactly -1, 0 or 1.
     */
    axis(negative: string, positive: string): number;
    /**
     * 2D vector from four actions (+Y up), normalized only when longer than 1: a half-tilted stick gives a short vector, two keys a unit diagonal.
     */
    vector(left: string, right: string, down: string, up: string): Vec2;
    /**
     * Pad 0..3 (default 0); a bad index throws.
     */
    gamepad(index?: number): GamepadAPI;
    /**
     * Deadzone of gamepad sticks (radial) and triggers, 0 up to 1 (not included); factoria.json input.deadzone sets the start value (default 0.2). Assign to offer calibration in an options menu.
     */
    deadzone: number;
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
   * Options of physics.raycast / raycast3d.
   */
  export interface RaycastOptions {
    /**
     * Layer mask the ray can hit (default all).
     */
    mask?: number;
    /**
     * Entity whose colliders (and its children's) are skipped; use the caster: { ignore: this.entity }.
     */
    ignore?: Entity | string;
    /**
     * Skip trigger colliders (default true); false hits them too.
     */
    ignoreTriggers?: boolean;
  }

  /**
   * Queries and direct body control. All vectors accept Vec2/Vec3, {x, y(, z)} objects and [x, y(, z)] arrays.
   */
  export interface PhysicsAPI {
    /**
     * 3D raycast between two points (when `from` has a z). A ray that starts inside a collider skips it. From a behaviour pass { ignore: this.entity }.
     */
    raycast(from: Vec3 | { x: number; y: number; z: number } | readonly [number, number, number], to: Vec3Like, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * 2D raycast between two points. A ray that starts inside a collider skips it. From a behaviour pass { ignore: this.entity } so it does not hit itself.
     */
    raycast(from: Vec2Like, to: Vec2Like, opts?: RaycastOptions): RayHit<Vec2> | null;
    /**
     * 3D raycast from an origin along a direction, at most maxDistance (default 1000) far.
     */
    raycast3d(origin: Vec3Like, dir: Vec3Like, maxDistance?: number, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * Sweeps a sphere or box from `from` to `to` (3D, when `from` has a z) and returns the first collider it touches: distance is how far the centre travels, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped, like a ray that starts inside one; a collider it only touches blocks the cast only if the shape moves towards it. Answers 'will this fit / how far can it go' for shapes where a ray is too thin. Same options as raycast; from a behaviour pass { ignore: this.entity }.
     */
    shapeCast(shape: CastShape3D, from: Vec3 | { x: number; y: number; z: number } | readonly [number, number, number], to: Vec3Like, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * Sweeps a circle or box from `from` to `to` (2D) and returns the first collider it touches: distance is how far the centre travels, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped, like a ray that starts inside one; a collider it only touches blocks the cast only if the shape moves towards it. Example: physics.shapeCast({ shape: "box", size: [16, 24] }, vec2(x, y), vec2(x, y - 40), { ignore: this.entity }). Throws an Error that explains the fix when the shape is wrong (misspelt name, "sphere" in 2D, missing size).
     */
    shapeCast(shape: CastShape2D, from: Vec2Like, to: Vec2Like, opts?: RaycastOptions): RayHit<Vec2> | null;
    /**
     * Entities whose 2D colliders (triggers included) overlap the circle.
     */
    overlapCircle(center: Vec2Like, radius: number, opts?: { mask?: number }): Entity[];
    /**
     * Entities whose 2D colliders (triggers included) overlap the rectangle.
     */
    overlapBox(rect: RectLike, opts?: { mask?: number }): Entity[];
    /**
     * Entities whose 3D colliders (triggers included) overlap the sphere.
     */
    overlapSphere(center: Vec3Like, radius: number, opts?: { mask?: number }): Entity[];
    /**
     * Instant change of momentum on a dynamic body (world units; 2D uses x, y).
     */
    applyImpulse(entity: Entity, v: Vec3Like): void;
    /**
     * Force applied to a dynamic body for the current step.
     */
    applyForce(entity: Entity, v: Vec3Like): void;
    /**
     * Sets a body's velocity (same as writing RigidBody.velocity).
     */
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
     * Simulated seconds since scene start (fixed steps run so far x fixedDt); not affected by time.scale.
     */
    readonly elapsed: number;
    readonly frame: number;
    /**
     * Time scale for gameplay (>= 0, default 1): scales onUpdate/onFixedUpdate dt, timers, physics steps, particles and sprite animators. 0 freezes all of them (game.paused): only behaviours with runWhilePaused = true keep updating, and the UI keeps working. Audio is not scaled.
     */
    scale: number;
    /**
     * Seconds of the current frame, NOT scaled by time.scale (the real frame time while paused): animate pause menus with it.
     */
    readonly unscaledDt: number;
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
    /**
     * Rect as { x, y, w, h } or [x, y, w, h].
     */
    rect(rect: RectLike, color?: ColorLike): void;
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
     * True while time.scale is 0. Setting it true sets time.scale to 0 (physics, particles, animators, timers and onUpdate stop; runWhilePaused behaviours and the UI keep running), false sets it back to 1.
     */
    paused: boolean;
    /**
     * factoria.json contents.
     */
    readonly project: Readonly<Json>;
    readonly screenSize: Vec2;
    /**
     * The third-party software inside the FactorIA runtime that every game ships (the parts whose full license texts `factoria export` writes to FACTORIA_NOTICES.txt next to the game), FactorIA first. Show it on a credits or licenses screen: e.g. game.notices().map((n) => `${n.name} (${n.license})`).
     */
    notices(): { name: string; url: string; license: string; usedFor: string }[];
  }

  /**
   * Persistent JSON save data (<user dir>/storage.json). Tests and `--storage memory` runs use a throw-away in-memory object instead.
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
    /**
     * Reseeds the deterministic world RNG (use from tools/tests for seed -> level determinism). The running game draws from this one RNG, so reseeding it changes the game's random sequence: a level generator should use rng.create(seed) instead.
     */
    seed(n: number): void;
    /**
     * Creates an independent, deterministic generator with the same methods as rng. It has its own state and never reads or changes the world RNG (or Math.random), so a tool can generate a level from a seed without disturbing the running game. Algorithm: mulberry32 (32-bit state, one step per draw). The algorithm and the draws each method consumes are STABLE across engine versions, so a stored seed keeps giving the same sequence. The seed is reduced to 32 bits (ToUint32: integer part, modulo 2^32); 0 is a valid seed. Throws for a non-number or non-finite seed. Example: const r = rng.create(7); r.int(1, 6).
     */
    create(seed: number): Rng;
  }

  /**
   * An independent seeded generator from rng.create(seed). Algorithm mulberry32, stable across engine versions: the same seed gives the same sequence on every platform. Every method draws a fixed number of 32-bit steps (float, range, int and chance: one per call; pick: one, none for an empty array; shuffle: items.length - 1), so a sequence does not depend on the arguments.
   */
  export interface Rng {
    /**
     * Next number in [0, 1): a 32-bit step divided by 2^32.
     */
    float(): number;
    /**
     * min + (max - min) * float(); in [min, max).
     */
    range(min: number, max: number): number;
    /**
     * Integer in [min, max], both inclusive (arguments are truncated to integers): min + floor(float() * (max - min + 1)). Returns min when max <= min (still one draw).
     */
    int(min: number, max: number): number;
    /**
     * True with probability p (default 0.5): float() < p.
     */
    chance(p?: number): boolean;
    /**
     * A random item (items[floor(float() * length)]), or undefined for an empty array.
     */
    pick<T>(items: readonly T[]): T | undefined;
    /**
     * A shuffled copy (Fisher-Yates from the end, j = floor(float() * (i + 1))); the input is not modified.
     */
    shuffle<T>(items: readonly T[]): T[];
    /**
     * Restarts this generator from seed n (same reduction as rng.create); the same as a new rng.create(n). Does not touch the world RNG.
     */
    seed(n: number): void;
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
     * Runs a command and returns its result. On failure it throws an Error with `code`, `hint` and, when the command reported structured details (for example a project tool's ToolError(message, hint, data)), `data`.
     */
    call(name: string, args?: Json): any;
    commands(): CommandInfoJS[];
  }

  /**
   * Throw from a tool's run() for an EXPECTED failure: the caller gets the message, the hint (how to fix) and optional structured data. Any other Error becomes a generic "failed" error.
   */
  export class ToolError extends Error {
    constructor(message: string, hint?: string, data?: Json);
    /**
     * How to fix it.
     */
    readonly hint: string;
    /**
     * Optional details (e.g. a report) delivered with the error.
     */
    readonly data?: Json;
  }

  /**
   * Particle helpers.
   */
  export interface ParticlesAPI {
    /**
     * Immediately spawns `count` particles at the entity's ParticleEmitter (works with emitting = false). No-op with a warning without a renderer.
     */
    burst(entity: Entity | string, count?: number): void;
  }

  /**
   * Text/UI helpers.
   */
  export interface UIAPI {
    /**
     * Size of `text` laid out like Text rendering (wraps at maxWidth > 0). Headless runs approximate 0.6 * fontSize per character (with a warning).
     */
    measureText(text: string, opts?: { fontSize?: number; font?: string; maxWidth?: number }): { width: number; height: number };
  }

  /**
   * Asset queries.
   */
  export interface AssetsAPI {
    /**
     * Pixel size of the texture file at the project-relative `path`, e.g. assets.textureSize("assets/hero.png"). This is the size a Sprite without `size` or `region` is drawn at and that entity.bounds() uses. A missing or unreadable file gives 32 x 32, the size of the missing-texture checker. Cached per file and modification time, so it is cheap to call every frame. Works headless (it reads the file, not the GPU texture). Throws for an empty or non-string path.
     */
    textureSize(path: string): { width: number; height: number };
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
   * Plain object that persists across scene loads for the whole run (score, lives, current level). Not saved to disk; reset for every test file. Module-level variables persist across scene loads too.
   */
  export const session: Record<string, any>;

  /**
   * Particle helpers.
   */
  export const particles: ParticlesAPI;

  /**
   * Text measurement.
   */
  export const ui: UIAPI;

  /**
   * Asset queries (texture size).
   */
  export const assets: AssetsAPI;

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
    /**
     * Bloom (glow) post-process: bright pixels bleed light into their surroundings, the neon / laser / fire / explosion look. Works for 2D and 3D cameras, is applied to the whole finished frame (screen-space HUD included, unless bloomScreenSpace is false) and shows in screenshots. Combine with blend "additive" on Sprite, Shape2D or ParticleEmitter instead of hand-drawing blurred halo sprites. Off by default; costs a few extra render passes per frame (cheap on a GPU, about 5 ms at 1280x720 on the software renderer used for headless runs). Tune with bloomThreshold, bloomIntensity and bloomRadius; keep the HUD crisp with bloomScreenSpace.
     */
    bloom: boolean;
    /**
     * Only used when bloom is true. Brightness (0..1, the largest of a pixel's r, g, b) at which glow starts: pixels at or below it do not glow, the glow ramps up linearly to full strength at 1 (white / fully saturated). Lower it (0.3-0.6) to make dim colors glow too; raise it (0.9+) so only the brightest pixels do (values above 0.99 behave like 0.99).
     */
    bloomThreshold: number;
    /**
     * Only used when bloom is true. Strength of the glow that is added back onto the frame: 0 = none, 1 = the blurred bright pixels are added once, 2 = twice (brighter, saturates sooner). Limited to 0..10.
     */
    bloomIntensity: number;
    /**
     * Only used when bloom is true. How far the glow reaches, in design pixels (1280x720 by default): a gaussian blur whose visible halo fades out roughly this far from the bright pixels. Values below ~5 behave like 5 (the glow is computed at reduced resolution, and larger radii at even lower resolution, so wide glows are softer). Limited to 1..128.
     */
    bloomRadius: number;
    /**
     * Only used when bloom is true. true (default): the whole finished frame glows, screen-space items (Sprite, Shape2D, Text with space "screen", and debug text) included, so a bright neon title or HUD icon glows too. false: screen-space items are drawn AFTER the bloom, so the HUD (score, lives, menus) stays crisp and never glows while the world still does. Set it to false whenever the HUD has white or bright text over a glowing world; leave it true to make a screen-space title or logo glow.
     */
    bloomScreenSpace: boolean;
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
    /**
     * Compositing: alpha (normal), additive (glow, neon, fire, lasers; brightens), multiply (darkens/tints).
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Screen space only: screen point the position is relative to. [0,0] top-left (default), [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio.
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
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
     * Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square rotated 45 degrees when size is square; handy for gems, enemies and neon markers). polygon: a regular polygon with `sides` sides whose vertices lie on the ellipse inscribed in the size box, first vertex pointing up (hexagons, pentagons, octagons; many sides approach a circle). star: `points` tips on that ellipse, first tip pointing up, with notches at `innerRadius` of the outer radius in between. Outlines (filled = false) of triangle, diamond, polygon and star grow INWARD from the silhouette, like the rectangle's, so a thick outline never pokes out of the size box.
     */
    shape: "rectangle" | "circle" | "line" | "triangle" | "diamond" | "polygon" | "star";
    /**
     * rectangle/triangle/diamond/polygon/star: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin.
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
    /**
     * Anchor point within the shape's size box for every shape but line: [0.5,0.5] = the box centre sits on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Compositing: alpha (normal), additive (glow/neon), multiply (darken).
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right).
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * polygon only: number of sides (3 = triangle, 6 = hexagon, 8 = octagon).
     */
    sides: number;
    /**
     * star only: number of tips (5 = the classic star).
     */
    points: number;
    /**
     * star only: radius of the notches between the tips as a fraction of the outer radius. 0.5 = classic star, near 1 = a fat spiky polygon, near 0 = thin needles.
     */
    innerRadius: number;
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
     * Project-relative path of a .ttf font. Empty uses the built-in font, DejaVu Sans (Latin, Greek, Cyrillic); "builtin:pixel" is Press Start 2P. Characters the font has no glyph for draw as nothing and log one warning per font: Chinese, Japanese and Korean need a .ttf that covers them (e.g. Noto Sans SC, JP or KR). (asset path: font)
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
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + position [-20, 20] = right-aligned 20px from the top-right corner.
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
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
     * Number of tile columns in the tileset texture (used to find a tile's source rectangle). Optional: 0 (the default) derives it from the tileset texture, as many whole tiles of tileSize.x as fit across its width. Set it only when the image has a different layout.
     */
    columns: number;
    /**
     * Map width in tiles, for a flat tiles array. Not needed when tiles is an array of rows (the rows define the size; drawing and collision both use it).
     */
    width: number;
    /**
     * Map height in tiles, for a flat tiles array. Not needed when tiles is an array of rows.
     */
    height: number;
    /**
     * Tile indices, row-major with row 0 at the TOP: either a flat array of width*height integers (set width and height) or an array of rows (the size comes from the rows). -1 = empty. Returns a plain-object COPY; assign a new value to write.
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
    /**
     * Compositing of particles: additive is ideal for sparks, fire, magic and neon effects.
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Destroy the entity automatically once it is not emitting and all its particles died. Use with burst > 0 and emitting = false for one-shot effects (explosions, pickups).
     */
    autoDestroy: boolean;
    /**
     * world: affected by cameras. screen: HUD/UI effects (menu sparks, score bursts) in design pixels, origin TOP-LEFT, +Y down, unaffected by cameras and drawn in the screen-space pass (so with Camera.bloomScreenSpace = false they are not bloomed). direction, gravity and speed keep their world meaning on screen: 90 = up, negative gravity y falls down the screen. Ignored (treated as world) when is3D is true.
     */
    space: "world" | "screen";
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right).
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
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
    /**
     * One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump up through it from below and pass sideways.
     */
    oneWay: boolean;
  }
  /**
   * Simple 3D physics body for arcade games (spheres and oriented boxes). Pair it with a Collider3D. Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider (continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles and settles on a face; set lockRotation for a character or an upright crate. A sphere is an arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body that stays nearly still for half a second falls asleep together with the bodies it touches (no cost, no events) and wakes when touched by something moving, when gameplay writes its position, rotation or velocity, applies a force, or when what it rests on goes away.
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
    /**
     * Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step. Read/write (writing it wakes a sleeping body). A box spinning about a non-principal axis keeps its angular momentum, so this vector wanders (precession) while it tumbles.
     */
    get angularVelocity(): Vec3;
    set angularVelocity(value: Vec3Like);
    /**
     * Sphere colliders only. true (default, arcade ball): while it touches the ground the sphere is spun to match its rolling motion (sets angularVelocity from the horizontal velocity) and uses rolling resistance (rollingFriction) instead of sliding friction; contacts never turn it, so setting velocity every frame steers it exactly. false: the sphere is a rigid body (solid-sphere inertia 2/5 m r^2): friction at the contact point spins it, so on a slope it rolls (spin = speed / radius) and a glancing hit makes it spin; on flat ground it keeps rolling until angularDamping / linearDamping or an obstacle stops it. Add lockRotation for a ball that slides and is never spun by contacts.
     */
    rollWithMotion: boolean;
    /**
     * Rolling resistance of a dynamic sphere with rollWithMotion = true: friction cap = rollingFriction * normal force, replacing the sliding friction of its contacts, so on flat ground its speed decays by about rollingFriction * gravity per second (default 0.02 rolls about 23 m from 3 m/s; 0 never slows down). Ignored when rollWithMotion is false (then Collider3D.friction acts at the contact point of the rigid sphere) and for boxes.
     */
    rollingFriction: number;
    /**
     * Rotation drag of a dynamic body: angularVelocity is divided by (1 + dt * angularDamping) every step, so 0 = a spinning body keeps spinning in the air, larger values slow it down faster.
     */
    angularDamping: number;
    /**
     * true = collisions and friction never turn this body (a dynamic box, or a sphere with rollWithMotion = false): it stays upright and slides, as boxes did before rotation dynamics. Use it for characters and upright crates. angularVelocity and Transform.rotation written by gameplay still turn it. A rollWithMotion sphere is never turned by contacts either way.
     */
    lockRotation: boolean;
  }
  /**
   * Collision shape for 3D physics (box or sphere). Boxes are ORIENTED: they follow the entity's world rotation (parents included), so a box rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale.
   * 
   * Category: Physics
   */
  export interface Collider3DComponent {
    /**
     * Shape type; uses size (box) or radius (sphere).
     */
    shape: "box" | "sphere";
    /**
     * box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale.
     */
    get size(): Vec3;
    set size(value: Vec3Like);
    /**
     * sphere: radius in meters.
     */
    radius: number;
    /**
     * Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity.
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
    Camera: { projection?: "orthographic" | "perspective"; fov?: number; orthoSize?: number; nearPlane?: number; farPlane?: number; clearColor?: ColorLike; clear?: boolean; primary?: boolean; depth?: number; bloom?: boolean; bloomThreshold?: number; bloomIntensity?: number; bloomRadius?: number; bloomScreenSpace?: boolean };
    Sprite: { texture?: string; region?: RectLike; size?: Vec2Like; pivot?: Vec2Like; color?: ColorLike; flipX?: boolean; flipY?: boolean; layer?: number; space?: "world" | "screen"; pixelArt?: boolean; blend?: "alpha" | "additive" | "multiply"; anchor?: Vec2Like };
    SpriteAnimator: { columns?: number; rows?: number; firstFrame?: number; lastFrame?: number; fps?: number; loop?: boolean; playing?: boolean; time?: number; frame?: number };
    Shape2D: { shape?: "rectangle" | "circle" | "line" | "triangle" | "diamond" | "polygon" | "star"; size?: Vec2Like; color?: ColorLike; filled?: boolean; thickness?: number; layer?: number; space?: "world" | "screen"; pivot?: Vec2Like; blend?: "alpha" | "additive" | "multiply"; anchor?: Vec2Like; sides?: number; points?: number; innerRadius?: number };
    Text: { text?: string; font?: string; fontSize?: number; color?: ColorLike; align?: "left" | "center" | "right"; pivot?: Vec2Like; maxWidth?: number; layer?: number; space?: "world" | "screen"; anchor?: Vec2Like };
    Tilemap: { tileset?: string; tileSize?: Vec2Like; columns?: number; width?: number; height?: number; tiles?: any; solidTiles?: any; color?: ColorLike; layer?: number };
    ParticleEmitter: { emitting?: boolean; rate?: number; burst?: number; maxParticles?: number; lifetime?: number; lifetimeVariance?: number; speed?: number; speedVariance?: number; direction?: number; spread?: number; gravity?: Vec3Like; startSize?: number; endSize?: number; startColor?: ColorLike; endColor?: ColorLike; texture?: string; worldSpace?: boolean; is3D?: boolean; layer?: number; blend?: "alpha" | "additive" | "multiply"; autoDestroy?: boolean; space?: "world" | "screen"; anchor?: Vec2Like };
    MeshRenderer: { mesh?: string; texture?: string; color?: ColorLike; metallic?: number; roughness?: number; emissive?: ColorLike; unlit?: boolean; castShadows?: boolean; receiveShadows?: boolean; uvScale?: Vec2Like };
    Light: { type?: "directional" | "point" | "spot"; color?: ColorLike; intensity?: number; range?: number; spotAngle?: number; castShadows?: boolean };
    RigidBody2D: { type?: "static" | "dynamic" | "kinematic"; gravityScale?: number; linearDamping?: number; angularDamping?: number; fixedRotation?: boolean; bullet?: boolean; velocity?: Vec2Like; angularVelocity?: number };
    Collider2D: { shape?: "box" | "circle" | "capsule"; size?: Vec2Like; radius?: number; offset?: Vec2Like; isTrigger?: boolean; friction?: number; restitution?: number; density?: number; layer?: number; mask?: number; oneWay?: boolean };
    RigidBody3D: { type?: "static" | "dynamic" | "kinematic"; mass?: number; gravityScale?: number; linearDamping?: number; velocity?: Vec3Like; angularVelocity?: Vec3Like; rollWithMotion?: boolean; rollingFriction?: number; angularDamping?: number; lockRotation?: boolean };
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
  import type { Entity, WorldAPI, TimeAPI, Json, Vec2Like, GamepadButton, GamepadAxis } from "factoria";
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
     * For expect(game.audioLog()): passes when a clip was played (path = project-relative path, file name like "jump.wav", or RegExp). times = exact count; plays whose clip failed to load do not count.
     */
    toContainPlayed(path: string | RegExp, options?: { times?: number; bus?: "sfx" | "music" | "ui"; source?: EntityLike }): void;
    /**
     * Same as toContainPlayed.
     */
    toHavePlayed(path: string | RegExp, options?: { times?: number; bus?: "sfx" | "music" | "ui"; source?: EntityLike }): void;
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
   * One entry of game.audioLog(): a play request from audio.play/audio.music, an AudioSource component or scene music.
   */
  export interface AudioPlay {
    /**
     * Increasing id.
     */
    readonly seq: number;
    /**
     * time.frame when the sound was requested.
     */
    readonly frame: number;
    /**
     * time.elapsed (seconds) when the sound was requested.
     */
    readonly time: number;
    /**
     * Project-relative clip path.
     */
    readonly path: string;
    readonly volume: number;
    readonly pitch: number;
    readonly pan: number;
    readonly bus: "sfx" | "music" | "ui";
    readonly loop: boolean;
    /**
     * Started with audio.music() or SceneSettings.music.
     */
    readonly music: boolean;
    /**
     * Id of the entity whose AudioSource played it; "" for scripts and music.
     */
    readonly source: string;
    /**
     * false when the clip could not be loaded (the error is in the log).
     */
    readonly ok: boolean;
  }

  /**
   * A gamepad driven by a test, from game.gamepad(index). Like keyDown/keyUp, press/release/axis act at once and the game sees them on the next step.
   */
  export interface TestGamepad {
    /**
     * Holds a button down until release(); connects the pad. Unknown names throw with a suggestion.
     */
    press(button: GamepadButton): void;
    release(button: GamepadButton): void;
    /**
     * Press, step one frame, release, step one frame (like game.tap).
     */
    tap(button: GamepadButton): void;
    /**
     * Sets a stick (-1..1, +Y up) or trigger (0..1) as the device would; it stays until set again. Bound actions see it after the deadzone, so axis("LeftX", -1) is a full push left.
     */
    axis(axis: GamepadAxis, value: number): void;
    /**
     * Plugs the pad in (input.gamepad(i).connected becomes true).
     */
    connect(): void;
    /**
     * Unplugs the pad; what it held is released.
     */
    disconnect(): void;
  }

  /**
   * Drives the running game from a test.
   */
  export interface TestGame {
    /**
     * Loads a scene immediately (reseeds the RNG). Behaviours are constructed right away (game.find(id).behaviour works); onStart runs on the first step().
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
    /**
     * Drives gamepad 0..3 (default 0); a bad index throws. Actions bound to Gamepad* names react like they do to a real pad.
     */
    gamepad(index?: number): TestGamepad;
    mouseMove(screenPos: Vec2Like): void;
    click(screenPos: Vec2Like, button?: "left" | "right" | "middle"): void;
    /**
     * Loads a scene given as JSON ({ format: "factoria.scene/1", entities: [...] }) instead of a file.
     */
    loadJson(scene: Json): void;
    /**
     * A finger down at screenPos for `frames` frames (input.touches[0].pressed on the first), then released. Like a finger on a device it also moves the mouse there and holds the left mouse button (see touchStart).
     */
    touch(screenPos: Vec2Like, frames?: number): void;
    /**
     * Finger down (stays down until touchEnd). The first finger also drives the mouse as on a device: the mouse moves to screenPos and the left button goes down (input.mouse.pressed("left") on the first frame), so a script that reads both the mouse and touches sees both. Other fingers do not touch the mouse.
     */
    touchStart(screenPos: Vec2Like, id?: number): void;
    /**
     * Moves a finger; the first finger drags the mouse with it.
     */
    touchMove(screenPos: Vec2Like, id?: number): void;
    /**
     * Lifts a finger; when it is the first finger, the left mouse button is released where it lifted.
     */
    touchEnd(id?: number): void;
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
    /**
     * Sounds played since the current test started (cleared before each test), oldest first. Assert with expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav").
     */
    audioLog(): AudioPlay[];
    /**
     * Empties the audio log (e.g. after setup, before the action under test).
     */
    clearAudioLog(): void;
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
