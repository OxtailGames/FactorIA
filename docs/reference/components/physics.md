[Back to the index](../README.md)

# Components: Physics

## CharacterController3D

Since 0.2.0.

A walking character: a kinematic capsule that moves and slides. Move it with physics.moveCharacter(entity, [dx, dy, dz]) (Unity-style: you add gravity and jumping to the move yourself, using isGrounded) or set `velocity`. It slides along walls and ceilings, climbs steps up to stepOffset, will not climb slopes steeper than slopeLimit (it slides down them), stays on the ground going down ramps, is carried by the kinematic platform it stands on (carriedByPlatforms), weighs on the dynamic body below it (applyWeight, mass: a seesaw tips) and pushes the free dynamic bodies it walks into (pushStrength). Other bodies treat it as a kinematic capsule. The entity origin is the capsule centre (plus `center`). Do not add RigidBody3D or Collider3D to the same entity.

| Field | Type | Default | Description |
|---|---|---|---|
| `radius` | float | `0.4` | Capsule radius in meters (scaled by Transform.scale). Range 0.01..100.0. |
| `height` | float | `1.8` | Capsule height in meters from tip to tip (never less than 2 * radius). Range 0.02..1000.0. |
| `center` | vec3 | `[0.0,0.0,0.0]` | Capsule centre [x, y, z] from the entity origin, in meters. |
| `stepOffset` | float | `0.3` | Highest step in meters the character walks up (and the distance it snaps down to stay on the ground). Range 0.0..10.0. |
| `slopeLimit` | float | `45.0` | Steepest slope in degrees the character can walk up; steeper surfaces count as walls. Range 0.0..89.0. |
| `skin` | float | `0.02` | Gap in meters kept between the capsule and the surfaces it touches; avoids jitter and tunnelling. Range 0.001..1.0. |
| `layer` | int | `0` | Collision category of the character, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers the character collides with. -1 = all layers. |
| `velocity` | vec3 | `[0.0,0.0,0.0]` | Velocity in meters/second [x, y, z]: when not zero the character moves by velocity * dt every physics step (no gravity is added). Use it or moveCharacter, not both for the same motion. |
| `carriedByPlatforms` | bool | `true` | When true (default) a kinematic RigidBody3D the character stands on carries it: every physics step it moves with the platform's displacement (velocity, or a teleport by script) and turns about the platform's centre with its angularVelocity (the character also yaws with it). Set false and it stays where it is, so a moving platform slides out from under it and the script must carry it. (since 0.3.0) |
| `applyWeight` | bool | `true` | When true (default) a character standing on a dynamic RigidBody3D presses on it with mass * gravity at its feet, every physics step: a seesaw tips towards the side it stands on, a bridge plank or a crate feels the load. Set false for a character that weighs nothing. (since 0.3.0) |
| `mass` | float | `70.0` | Weight in kilograms pressed on the dynamic body below when applyWeight is on (see applyWeight). Range 0.0..100000.0. (since 0.3.0) |
| `pushStrength` | float | `1.0` | How hard the character shoves the free dynamic bodies it walks into: 1 (default) gives them its own speed, 0.5 half of it, 0 none (they block it like a wall). A body held by a Joint3D (a seesaw on its pivot, a bridge plank, a door) is never shoved whatever the value. Range 0.0..10.0. (since 0.3.0) |
| `isGrounded` | bool | `false` | Runtime: true when the last move ended standing on walkable ground (slope up to slopeLimit). Read-only. Runtime-only (not saved). |
| `groundNormal` | vec3 | `[0.0,1.0,0.0]` | Runtime: the normal of the ground under the character after the last move (up when airborne). Read-only. Runtime-only (not saved). |

## Collider2D

Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. Colliders collide when each one's layer is included in the other's mask.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| circle \\| capsule | `"box"` | Shape type; uses size (box, capsule) or radius (circle). |
| `size` | vec2 | `[32.0,32.0]` | box/capsule: [width, height] in world units (capsule is vertical). |
| `radius` | float | `16.0` | circle: radius in world units. |
| `offset` | vec2 | `[0.0,0.0]` | Shape center offset [x, y] from the entity origin, in world units. |
| `enabled` | bool | `true` | false = the collider is switched off: raycasts and overlap queries pass through it, it makes no contacts or trigger events, but the component and its settings stay. Writable at run time (a door that opened stops blocking, closing it turns the collider back on). (since 0.3.0) |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = no bounce, 1 = perfectly elastic. Range 0.0..1.0. |
| `density` | float | `1.0` | Mass per area; mass = density * shape area. Range 0.0..10000.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i). |
| `oneWay` | bool | `false` | One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump up through it from below and pass sideways. |

## Collider3D

Collision shape for 3D physics: box, sphere, capsule, convex hull or triangle mesh. Boxes, capsules and meshes are ORIENTED: they follow the entity's world rotation (parents included), so a box rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale. A `mesh` collider is for level geometry and needs a static body (no RigidBody3D, or type static): a dynamic or kinematic body with one is reported as an error and ignored.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| sphere \\| capsule \\| convex \\| mesh | `"box"` | box: uses size. sphere: uses radius. capsule: uses radius and height, along the entity's local Y. convex: the convex hull of the vertices of `mesh` (any dynamic body, fast). mesh: the triangles of `mesh` (static level geometry only; concave shapes, ramps, terrain). |
| `size` | vec3 | `[1.0,1.0,1.0]` | box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale. |
| `radius` | float | `0.5` | sphere and capsule: radius in meters. |
| `height` | float | `2.0` | capsule: full height in meters from tip to tip along the entity's local Y (so the straight part is height - 2 * radius; never less than 2 * radius). Range 0.002..100000.0. (since 0.2.0) |
| `mesh` | string | `""` | convex / mesh shapes: a built-in primitive name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad", the same sizes as MeshRenderer) or a project-relative path to a .gltf/.glb model (every mesh node of the file, with its node transform), or the `id` ("mesh:3") of a procedural mesh made with mesh.create() (the collider is rebuilt whenever the mesh is updated). Use the same value as the MeshRenderer so the collider matches what is drawn. (since 0.2.0) |
| `offset` | vec3 | `[0.0,0.0,0.0]` | Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity (for convex and mesh: where the model's own origin sits). |
| `enabled` | bool | `true` | false = the collider is switched off: raycasts, shape casts and overlap queries pass through it, it makes no contacts or trigger events and the NavMesh bake leaves it out, but the component and its settings stay. Writable at run time (a door that opened stops blocking, closing it turns the collider back on). (since 0.3.0) |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = none, 1 = perfectly elastic. Range 0.0..1.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers. |
| `navObstacle` | bool | `false` | true = a NavMesh3D does not bake this collider into the ground (a crate, a gate, a door that moves): it blocks the navigation cells it covers, plus the agent's radius, wherever it is NOW, and the affected cells are marked again each time it moves, so nav.findPath goes around it. Use it on anything that moves or is removed during play; static level geometry needs nothing. (since 0.3.0) |
| `navWalkable` | bool | `false` | true = a NavMesh3D does not bake this collider either, but its TOP surface is walkable wherever it is NOW: put it on a kinematic body or a body held by a joint that characters stand on (a rope-bridge plank, a seesaw, a moving platform, a lift). The cells it covers are added to the navigation mesh and marked again each time it moves (only the cells it left and entered), and they join the ground around them within stepHeight, so nav.findPath crosses a bridge, rides a platform that is docked and says `disconnected` while it is away. The ground under it is blocked meanwhile. Surfaces steeper than maxSlope are not walkable. Wins over navObstacle when both are set. (since 0.3.0) |

## Joint2D

Since 0.2.0.

A Box2D joint on this entity's body: revolute (a hinge / pendulum / wheel axle), distance (a rope or spring of fixed length), prismatic (a slider along an axis) or weld (glue two bodies together). Both this entity and `connected` need a RigidBody2D (or a Collider2D, which makes a static body); leave `connected` empty to pin to the world. Lengths and anchors are world units (pixels), angles degrees; created when the entity is, destroyed with either body or when the component is removed. Changing type, connected, anchors, axis or collideConnected rebuilds the joint; limits, motor, spring and length apply live, so scripts can toggle a motor. Positive angle, motor speed and translation move THIS entity counter-clockwise / along +axis relative to `connected` (the axis is in the connected body's frame, the world's when empty). Reaction force, angle and translation are read-only runtime fields.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: revolute \\| distance \\| prismatic \\| weld | `"revolute"` | revolute: the bodies share the anchor point and may turn around it. distance: the anchors stay `length` apart (a spring when enableSpring). prismatic: the anchor slides along `axis` and the bodies cannot turn relative to each other. weld: the bodies stay rigidly together (soft with springHertz > 0). |
| `connected` | entity |  | Id of the other entity (it needs a body). Empty (leave it out, null or "") = the joint is fixed to the world and connectedAnchor is a world position. |
| `anchor` | vec2 | `[0.0,0.0]` | Joint point [x, y] in THIS entity's local space (scaled by Transform.scale), world units from its origin. |
| `connectedAnchor` | vec2 | `[0.0,0.0]` | Joint point [x, y] in the connected entity's local space; a world position when `connected` is empty. For a hinge both anchors name the same spot in the world when the joint is created. |
| `axis` | vec2 | `[1.0,0.0]` | Prismatic only: slide direction [x, y] in this entity's local space; normalised. [1, 0] slides along local x. |
| `collideConnected` | bool | `false` | true: the two joined bodies still collide with each other (default false). |
| `length` | float | `0.0` | Distance only: rest length in world units. 0 = the distance between the anchors when the joint is created. Range 0.0..1000000.0. |
| `enableLimit` | bool | `false` | Limit the motion: revolute angle, prismatic translation, or distance length (needs enableSpring to stretch). |
| `lowerLimit` | float | `0.0` | Lower limit: revolute degrees (between -178 and 178, 0 = the pose at creation), prismatic translation in world units (0 = anchors coincide), distance minimum length in world units. |
| `upperLimit` | float | `0.0` | Upper limit, same units as lowerLimit. |
| `enableMotor` | bool | `false` | Drive the joint at motorSpeed with at most maxMotorTorque. Revolute and prismatic; a distance joint motor works only with enableSpring. |
| `motorSpeed` | float | `0.0` | Target speed: revolute degrees per second (positive = counter-clockwise), prismatic / distance world units per second. |
| `maxMotorTorque` | float | `0.0` | Strongest push the motor may apply: a torque for a revolute joint, a force for prismatic and distance joints (the same units as physics.applyForce). 0 = the motor does nothing. Range 0.0..999999995904.0. |
| `enableSpring` | bool | `false` | Revolute, prismatic, distance: make the free motion springy, pulling towards the rest pose (angle 0, translation 0, `length`). |
| `springHertz` | float | `0.0` | Spring stiffness in cycles per second (about 1 = a slow bounce, 5 = stiff). Weld joints: 0 = rigid, above 0 = a soft weld (no enableSpring needed). Range 0.0..1000.0. |
| `dampingRatio` | float | `0.0` | Spring damping: 0 = bounces on, 1 = settles without overshoot. Range 0.0..100.0. |
| `reactionForce` | vec2 | `[0.0,0.0]` | Runtime: the force [x, y] the joint applied last step to hold the bodies (same units as physics.applyForce). Compare it with a limit to break a rope. Read-only. Runtime-only (not saved). |
| `reactionTorque` | float | `0.0` | Runtime: the torque the joint applied last step. Read-only. Runtime-only (not saved). |
| `angle` | float | `0.0` | Runtime: revolute and weld: the current joint angle in degrees (0 = the pose at creation). Read-only. Runtime-only (not saved). |
| `translation` | float | `0.0` | Runtime: prismatic: the current slide position; distance: the current length, in world units. Read-only. Runtime-only (not saved). |

## Joint3D

Since 0.2.0.

Joins this entity's RigidBody3D to another body or to the world: a hinge (door, pendulum, wheel), a ball joint (rope link, ragdoll shoulder) or a fixed joint (welds the two bodies). Solved together with the contacts. Put it on the body that swings; set `connected` to the other entity (empty = the world). A jointed dynamic body is always a rotating rigid body. Bodies joined together fall asleep together once the whole chain is at rest (a motor keeps its bodies awake), so a settled rope bridge costs nothing. A chain of three or more jointed bodies is solved with extra iterations, so planks of any width hang still without heavy damping. The joint holds the pose the bodies have when it is created (autoAnchor); hinge limits are angles relative to that pose.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: hinge \\| ball \\| fixed | `"hinge"` | hinge: rotation about `axis` only. ball: free rotation about the anchor point. fixed: no relative movement at all. |
| `connected` | entity |  | The other body's entity id. Empty (leave it out, null or "") = the world: the anchor point stays where it is. The entity needs a RigidBody3D (any type) or a Collider3D. |
| `anchor` | vec3 | `[0.0,0.0,0.0]` | Joint point [x, y, z] in THIS entity's local space (scaled and rotated with it): the pendulum's pivot, the door's hinge edge. |
| `connectedAnchor` | vec3 | `[0.0,0.0,0.0]` | Joint point in the connected entity's local space, or a world position when `connected` is empty. Ignored while autoAnchor is true. |
| `autoAnchor` | bool | `true` | true (default): connectedAnchor is computed from `anchor` when the joint is created, so the bodies stay joined exactly where they are. false: use connectedAnchor as given (the bodies are pulled together). |
| `axis` | vec3 | `[0.0,0.0,1.0]` | hinge: the rotation axis [x, y, z] in THIS entity's local space (normalized). |
| `useLimits` | bool | `false` | hinge: keep the angle between lowerLimit and upperLimit. |
| `lowerLimit` | float | `-45.0` | hinge: lowest angle in degrees, relative to the pose the joint was created in (0 there). Range -360.0..360.0. |
| `upperLimit` | float | `45.0` | hinge: highest angle in degrees (same reference). Range -360.0..360.0. |
| `useMotor` | bool | `false` | hinge: drive the joint at motorSpeed (a wheel, an opening door). |
| `motorSpeed` | float | `0.0` | hinge motor: target speed in degrees/second of this body relative to the connected one, about the axis. |
| `maxMotorTorque` | float | `10.0` | hinge motor: the most torque in newton-meters the motor may apply; a heavy or loaded body needs more. Range 0.0..1000000.0. |
| `collideConnected` | bool | `false` | false (default): the two joined bodies do not collide with each other. true: they do. |
| `damping` | float | `0.0` | Resistance to the two bodies turning relative to each other, per second: each physics sub-step the relative angular velocity (about the axis for a hinge, every axis for a ball joint) is divided by 1 + damping * dt. 0 (default) = free; 1 takes the swing out of a door in a few seconds; 2..5 stops a rope-bridge plank ringing. A chain of 3+ bodies already settles without it. Range 0.0..1000.0. (since 0.3.0) |
| `angle` | float | `0.0` | Runtime: the current hinge angle in degrees, relative to the creation pose. Read-only. Runtime-only (not saved). |
| `stalled` | bool | `false` | Runtime, read only: true while a motor (useMotor with a non-zero motorSpeed) cannot turn the joint: the relative speed stayed below a tenth of motorSpeed for a quarter of a second, e.g. a gate pushing against a wall, or a maxMotorTorque too low for the load. False when the hinge simply reached its limit. Scripts read it to open another way or raise the torque. Read-only. Runtime-only (not saved). (since 0.3.0) |

## NavLink3D

Since 0.3.0.

An off-mesh link of the NavMesh3D: a jump across a gap, a climb up a ladder, a drop off a ledge. The walkable cells do not join the two places, so this joins them: the link runs from this entity's world position to `end` (both are moved onto the nearest walkable cell). nav.findPath may take it, and its result lists where in `links` (the index of the point where the link starts and the link's entity), so a script makes the character jump or climb there; the next point is where it ends. See docs/NAVIGATION.md.

| Field | Type | Default | Description |
|---|---|---|---|
| `end` | vec3 | `[0.0,0.0,0.0]` | World position [x, y, z] where the link ends. The entity's own world position is where it starts. Both ends must be within the NavMesh3D box and near walkable ground (agentRadius + two cells horizontally, about stepHeight up and agentHeight down); a link whose end is not is ignored, and nav.info says so. |
| `bidirectional` | bool | `true` | true (default): the path may also go from `end` to the entity. false: one way only, from the entity to `end` (a drop, a jump that cannot be climbed back). |
| `cost` | float | `0.0` | Extra path length in meters added to the straight distance between the two ends. 0 = as long as the straight line; raise it so a path prefers walking around when that is not much longer. Range 0.0..1000.0. |

## NavMesh3D

Since 0.3.0.

A navigation mesh for path finding on 3D ground. It is baked from the STATIC colliders (no RigidBody3D, or a static one) inside a box around this entity, when the scene loads (autoBake) or with the nav.bake command: the box is cut into cells of cellSize; a cell is walkable where the ground is not steeper than maxSlope, has agentHeight of free space above it and lies at least agentRadius from a wall or a drop; neighbouring cells connect when their heights differ by at most stepHeight. Then nav.findPath(from, to) in scripts (the nav.find_path command) returns the points of a path over it. A collider with Collider3D.navObstacle is not baked: it blocks the cells it covers while it is there; one with Collider3D.navWalkable (a bridge, a lift) adds its top surface while it is there, and NavLink3D entities add off-mesh links. The mesh is deterministic: the same colliders always give the same cells. See docs/NAVIGATION.md.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec3 | `[40.0,10.0,40.0]` | Size [x, y, z] in meters of the baked box, centred on the entity's world position; rotation and scale are ignored. Cover the whole level: ground outside is not walkable and the box edge counts as a drop. y must reach from below the lowest floor to above the highest head. |
| `cellSize` | float | `0.25` | Width of one cell on the ground plane, meters. Smaller = finer paths, more memory and a slower bake (cells = x/cellSize * z/cellSize, at most 4 million). Walls thinner than half a cell can be missed. Range 0.05..10.0. |
| `cellHeight` | float | `0.05` | Heights are rounded to a multiple of this, meters; a path is up to half of it above or below the true surface. Keep it at most stepHeight / 4. Range 0.01..5.0. |
| `agentRadius` | float | `0.3` | Radius in meters of the walker the mesh is made for: walkable cells stay this far from walls and drops, so a body of that radius never touches them. findPath with a bigger radius is an error (bake another NavMesh3D for the bigger agent). Range 0.0..10.0. |
| `agentHeight` | float | `1.8` | Height in meters of the walker; ground with less free space above it (under a low ceiling or table) is not walkable. Range 0.1..50.0. |
| `stepHeight` | float | `0.4` | Highest step in meters the walker climbs; a higher ledge is a wall. Match CharacterController3D.stepOffset. Range 0.0..10.0. |
| `maxSlope` | float | `45.0` | Steepest walkable ground in degrees; steeper ground is a wall. Match CharacterController3D.slopeLimit. Range 0.0..89.0. |
| `autoBake` | bool | `true` | true (default): bake when the scene loads and again when a static collider is added, moved or removed. false: only the nav.bake command bakes (and a scene without a bake has no paths). |
| `enabled` | bool | `true` | false = nav.findPath ignores this mesh (and it is not baked). |
| `walkableCells` | int | `0` | Runtime: how many cells can be walked on after the last bake (read only). Read-only. Runtime-only (not saved). |
| `regions` | int | `0` | Runtime: how many separate walkable areas the last bake found; two points in different areas have no path (read only). Read-only. Runtime-only (not saved). |

## RigidBody2D

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

## RigidBody3D

Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a triangle-mesh collider is for static level geometry only). Pair it with a Collider3D; add a Joint3D to hinge it to the world or to another body. A capsule body with lockRotation is a simple physics character (for a controller that slides, climbs steps and checks slopes use CharacterController3D instead). Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider (continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles and settles on a face; set lockRotation for a character or an upright crate. A sphere is an arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body that stays nearly still for half a second falls asleep together with the bodies it touches (no cost, no events) and wakes when touched by something moving, when gameplay writes its position, rotation or velocity, applies a force, or when what it rests on goes away.

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

