#include "fa/scene/components.h"

#include <mutex>

#include "fa/core/reflect.h"

namespace fa {

void register_builtin_components(TypeRegistry& r) {
    // ------------------------------------------------------------- Core ---
    r.add<EntityInfo>("EntityInfo",
                      "Identity of an entity; present on every entity. In scene files these fields are the entity's "
                      "top-level keys (id, name, tags, active), not a component entry. Tags are handled by "
                      "the scene serializer.",
                      "Core")
        .field("id", &EntityInfo::id,
               "Stable unique string id within the scene (e.g. \"player\"). Used to reference the entity from "
               "Entity fields, scripts (world.find) and tools. Auto-generated (\"e1\", \"e2\"...) if omitted.")
        .field("name", &EntityInfo::name, "Display name shown in the editor and logs. Not unique.")
        .field("active", &EntityInfo::active,
               "If false the entity and all its children are skipped by rendering, physics, audio and scripts.");

    r.add<Transform>("Transform",
                     "Position, rotation and scale of an entity relative to its parent. Present on every entity. "
                     "2D uses x/y of position and the z angle of rotation; 3D units are meters.",
                     "Core")
        .field("position", &Transform::position,
               "Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering "
               "of 3D content. Units: world units (design pixels in 2D, meters in 3D).")
        .field("rotation", &Transform::rotation,
               "Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in "
               "the order Y, X, Z. 2D games only use the z value (counter-clockwise).")
        .field("scale", &Transform::scale, "Local scale [x, y, z]. 1 = original size; negative values mirror.");

    // ----------------------------------------------------------- Camera ---
    r.add<Camera>("Camera",
                  "Renders the scene to the screen. The active camera with primary=true and the lowest depth draws the "
                  "game (only one camera renders for now; split-screen/overlay cameras are on the roadmap). 3D cameras "
                  "look down their local -Z axis.",
                  "Camera")
        .enum_field("projection", &Camera::projection, {"orthographic", "perspective"},
                    "orthographic: flat 2D view (no perspective). perspective: 3D view with depth.")
        .field("fov", &Camera::fov, "Perspective only: vertical field of view in degrees.").range(1, 179)
        .field("orthoSize", &Camera::orthoSize,
               "Orthographic only: half of the visible height in world units. 0 = use the design resolution "
               "(pixel perfect: one world unit is one design pixel).")
        .range(0, 100000)
        .field("nearPlane", &Camera::nearPlane,
               "Perspective only: distance of the near clip plane in meters. Keep it as large as possible for depth precision.")
        .range(0.001f, 100000)
        .field("farPlane", &Camera::farPlane, "Perspective only: distance of the far clip plane in meters.")
        .range(0.01f, 1000000)
        .field("clearColor", &Camera::clearColor, "Background color the camera clears to when clear is true.")
        .field("clear", &Camera::clear,
               "Clear the target before drawing. Set false on overlay cameras that draw on top of another camera.")
        .field("primary", &Camera::primary, "The first active primary camera renders the game.")
        .field("depth", &Camera::depth, "Picks the rendering camera when several are primary: the lowest depth wins (multi-camera rendering is on the roadmap).")
        .field("bloom", &Camera::bloom,
               "Bloom (glow) post-process: bright pixels bleed light into their surroundings, the neon / laser / fire / "
               "explosion look. Works for 2D and 3D cameras, is applied to the whole finished frame (screen-space HUD "
               "included, unless bloomScreenSpace is false) and shows in screenshots. Combine with blend \"additive\" on Sprite, Shape2D or "
               "ParticleEmitter instead of hand-drawing blurred halo sprites. Off by default; costs a few "
               "extra render passes per frame (cheap on a GPU, about 5 ms at 1280x720 on the software renderer used for headless runs). "
               "Tune with bloomThreshold, bloomIntensity and bloomRadius; keep the HUD crisp with bloomScreenSpace.")
        .field("bloomThreshold", &Camera::bloomThreshold,
               "Only used when bloom is true. Brightness (0..1, the largest of a pixel's r, g, b) at which glow starts: "
               "pixels at or below it do not glow, the glow ramps up linearly to full strength at 1 (white / fully "
               "saturated). Lower it (0.3-0.6) to make dim colors glow too; raise it (0.9+) so only the brightest "
               "pixels do (values above 0.99 behave like 0.99).")
        .range(0, 1)
        .field("bloomIntensity", &Camera::bloomIntensity,
               "Only used when bloom is true. Strength of the glow that is added back onto the frame: 0 = none, "
               "1 = the blurred bright pixels are added once, 2 = twice (brighter, saturates sooner). Limited to 0..10.")
        .range(0, 10)
        .field("bloomRadius", &Camera::bloomRadius,
               "Only used when bloom is true. How far the glow reaches, in design pixels (1280x720 by default): a gaussian blur "
               "whose visible halo fades out roughly this far from the bright pixels. Values below ~5 behave like 5 "
               "(the glow is computed at reduced resolution, and larger radii at even lower resolution, so wide "
               "glows are softer). Limited to 1..128.")
        .range(1, 128)
        .field("bloomScreenSpace", &Camera::bloomScreenSpace,
               "Only used when bloom is true. true (default): the whole finished frame glows, screen-space items "
               "(Sprite, Shape2D, Text with space \"screen\", and debug text) included, so a bright neon title or HUD "
               "icon glows too. false: screen-space items are drawn AFTER the bloom, so the HUD (score, lives, menus) stays "
               "crisp and never glows while the world still does. Set it to false whenever the HUD has white or bright text "
               "over a glowing world; leave it true to make a screen-space title or logo glow.");

    // --------------------------------------------------------------- 2D ---
    r.add<Sprite>("Sprite",
                  "Draws a textured (or solid color) quad. Use `region` to pick a frame from a sprite sheet. "
                  "Draw order: higher `layer` on top; ties sort by position.y (lower y on top), then creation order.",
                  "2D")
        .asset_field("texture", &Sprite::texture, "texture",
                     "Project-relative path of the image (e.g. \"assets/hero.png\"). Empty draws a solid quad of `color`.")
        .field("region", &Sprite::region,
               "Source rectangle [x, y, w, h] in texture pixels with the origin at the TOP-LEFT. A zero size "
               "means the whole texture. SpriteAnimator overwrites it every frame.")
        .field("size", &Sprite::size,
               "Size [w, h] in world units. [0, 0] = use the region (or texture) size in pixels.")
        .field("pivot", &Sprite::pivot, "Anchor inside the sprite: [0, 0] bottom-left, [0.5, 0.5] center, [1, 1] top-right.")
        .field("color", &Sprite::color, "Tint multiplied with the texture. Alpha makes it translucent. Accepts [r,g,b,a], \"#rrggbb\" or a name.")
        .field("flipX", &Sprite::flipX, "Mirror horizontally.")
        .field("flipY", &Sprite::flipY, "Mirror vertically.")
        .field("layer", &Sprite::layer, "Draw order. Higher layers draw on top of lower ones. Backgrounds use negative layers.")
        .enum_field("space", &Sprite::space, {"world", "screen"},
                    "world: positioned in the game world and affected by cameras. screen: UI/HUD in design-resolution "
                    "pixels with (0,0) at the TOP-LEFT and +Y DOWN; drawn after the world.")
        .field("pixelArt", &Sprite::pixelArt, "true = nearest-neighbour filtering (crisp pixels), false = smooth linear filtering.")
        .enum_field("blend", &Sprite::blend, {"alpha", "additive", "multiply"},
                    "Compositing: alpha (normal), additive (glow, neon, fire, lasers; brightens), multiply (darkens/tints).")
        .field("anchor", &Sprite::anchor,
               "Screen space only: screen point the position is relative to. [0,0] top-left (default), [1,0] top-right, "
               "[0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio.");

    r.add<SpriteAnimator>("SpriteAnimator",
                          "Flipbook animation over a grid sprite sheet. Requires a Sprite on the same entity; it "
                          "overwrites Sprite.region every frame. Frames are numbered row-major from the top-left.",
                          "2D")
        .field("columns", &SpriteAnimator::columns, "Number of columns in the sprite sheet grid.").range(1, 4096)
        .field("rows", &SpriteAnimator::rows, "Number of rows in the sprite sheet grid.").range(1, 4096)
        .field("firstFrame", &SpriteAnimator::firstFrame, "First frame of the clip (inclusive, row-major index).")
        .field("lastFrame", &SpriteAnimator::lastFrame, "Last frame of the clip (inclusive, row-major index).")
        .field("fps", &SpriteAnimator::fps, "Playback speed in frames per second.").range(0, 1000)
        .field("loop", &SpriteAnimator::loop, "Restart from firstFrame after lastFrame. If false the animation stops on the last frame.")
        .field("playing", &SpriteAnimator::playing, "Set false to pause, true to play.")
        .field("time", &SpriteAnimator::time, "Runtime state: seconds elapsed in the current clip.").runtime_only()
        .field("frame", &SpriteAnimator::frame, "Runtime state: current frame index.").runtime_only();

    r.add<Shape2D>("Shape2D",
                   "Untextured 2D primitive for prototypes, UI panels and debug visuals.",
                   "2D")
        .enum_field("shape", &Shape2D::shape, {"rectangle", "circle", "line", "triangle", "diamond"},
                    "Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along "
                    "the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square "
                    "rotated 45 degrees when size is square; handy for gems, enemies and neon markers).")
        .field("size", &Shape2D::size,
               "rectangle/triangle/diamond: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin.")
        .field("color", &Shape2D::color, "Fill or outline color.")
        .field("filled", &Shape2D::filled, "true = solid shape, false = outline only (lines are always drawn as strokes).")
        .field("thickness", &Shape2D::thickness, "Outline / line thickness in world units.").range(0, 10000)
        .field("layer", &Shape2D::layer, "Draw order. Higher layers draw on top.")
        .enum_field("space", &Shape2D::space, {"world", "screen"},
                    "world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down.")
        .field("pivot", &Shape2D::pivot,
               "Anchor point within the shape's size box for rectangle/circle/triangle/diamond: [0.5,0.5] = the box centre sits "
               "on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and "
               "scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a "
               "triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the "
               "bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle "
               "around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place.")
        .enum_field("blend", &Shape2D::blend, {"alpha", "additive", "multiply"},
                    "Compositing: alpha (normal), additive (glow/neon), multiply (darken).")
        .field("anchor", &Shape2D::anchor,
               "Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right).");

    r.add<Text>("Text",
                "Draws a string with a TrueType font (or the built-in font). Works in world and screen space.",
                "2D")
        .field("text", &Text::text, "The string to draw. Use \\n for line breaks.")
        .asset_field("font", &Text::font, "font", "Project-relative path of a .ttf font. Empty uses the built-in font.")
        .field("fontSize", &Text::fontSize, "Glyph height in world units (pixels in 2D).").range(1, 4096)
        .field("color", &Text::color, "Text color.")
        .enum_field("align", &Text::align, {"left", "center", "right"}, "Horizontal alignment of lines inside the text box.")
        .field("pivot", &Text::pivot, "Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right.")
        .field("maxWidth", &Text::maxWidth, "If > 0, lines wrap at this width in world units. 0 = no wrapping.").range(0, 100000)
        .field("layer", &Text::layer, "Draw order. Higher layers draw on top. Text defaults above sprites.")
        .enum_field("space", &Text::space, {"world", "screen"},
                    "world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down.")
        .field("anchor", &Text::anchor,
               "Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, "
               "[0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + "
               "position [-20, 20] = right-aligned 20px from the top-right corner.");

    r.add<Tilemap>("Tilemap",
                   "A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. "
                   "Solid tiles can generate static 2D collision.",
                   "2D")
        .asset_field("tileset", &Tilemap::tileset, "texture", "Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom).")
        .field("tileSize", &Tilemap::tileSize, "Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units).")
        .field("columns", &Tilemap::columns,
               "Number of tile columns in the tileset texture (used to find a tile's source rectangle). Optional: 0 (the "
               "default) derives it from the tileset texture, as many whole tiles of tileSize.x as fit across its width. "
               "Set it only when the image has a different layout.").range(0, 4096)
        .field("width", &Tilemap::width,
               "Map width in tiles, for a flat tiles array. Not needed when tiles is an array of rows (the rows define the "
               "size; drawing and collision both use it).").range(0, 65536)
        .field("height", &Tilemap::height,
               "Map height in tiles, for a flat tiles array. Not needed when tiles is an array of rows.").range(0, 65536)
        .field("tiles", &Tilemap::tiles,
               "Tile indices, row-major with row 0 at the TOP: either a flat array of width*height integers (set width "
               "and height) or an array of rows (the size comes from the rows). -1 = empty.")
        .field("solidTiles", &Tilemap::solidTiles,
               "List of tile indices that block movement (static colliders are generated for them). Empty = nothing collides.")
        .field("color", &Tilemap::color, "Tint multiplied with the tileset.")
        .field("layer", &Tilemap::layer, "Draw order. Defaults below sprites (-10).");

    r.add<ParticleEmitter>("ParticleEmitter",
                           "Emits short-lived particles (smoke, sparks, explosions). Particles interpolate size and color "
                           "over their lifetime.",
                           "2D")
        .field("emitting", &ParticleEmitter::emitting, "Continuously emit while true. Set false to stop spawning (live particles finish).")
        .field("rate", &ParticleEmitter::rate, "Particles emitted per second while emitting.").range(0, 100000)
        .field("burst", &ParticleEmitter::burst, "Number of particles emitted once when the emitter starts (explosions).").range(0, 100000)
        .field("maxParticles", &ParticleEmitter::maxParticles, "Upper limit of simultaneously alive particles.").range(1, 1000000)
        .field("lifetime", &ParticleEmitter::lifetime, "How long a particle lives, in seconds.").range(0.001f, 3600)
        .field("lifetimeVariance", &ParticleEmitter::lifetimeVariance, "Random +- fraction applied to lifetime (0.2 = +-20%).").range(0, 1)
        .field("speed", &ParticleEmitter::speed, "Initial speed in world units per second.")
        .field("speedVariance", &ParticleEmitter::speedVariance, "Random +- fraction applied to speed.").range(0, 1)
        .field("direction", &ParticleEmitter::direction, "2D emission direction in degrees: 0 = right, 90 = up.")
        .field("spread", &ParticleEmitter::spread, "Half-angle of the emission cone in degrees (180 = all directions).").range(0, 180)
        .field("gravity", &ParticleEmitter::gravity, "Constant acceleration [x, y, z] in world units/s^2 (default pulls down).")
        .field("startSize", &ParticleEmitter::startSize, "Particle size when born, in world units.")
        .field("endSize", &ParticleEmitter::endSize, "Particle size at the end of its life.")
        .field("startColor", &ParticleEmitter::startColor, "Particle color when born.")
        .field("endColor", &ParticleEmitter::endColor, "Particle color at the end of life (alpha 0 fades out).")
        .asset_field("texture", &ParticleEmitter::texture, "texture", "Particle image. Empty uses a soft round particle.")
        .field("worldSpace", &ParticleEmitter::worldSpace, "true = particles stay where they were emitted when the emitter moves; false = they follow the emitter.")
        .field("is3D", &ParticleEmitter::is3D, "Emit in a 3D cone as camera-facing billboards instead of in the 2D plane.")
        .field("layer", &ParticleEmitter::layer, "Draw order. Higher layers draw on top.")
        .enum_field("blend", &ParticleEmitter::blend, {"alpha", "additive", "multiply"},
                    "Compositing of particles: additive is ideal for sparks, fire, magic and neon effects.")
        .field("autoDestroy", &ParticleEmitter::autoDestroy,
               "Destroy the entity automatically once it is not emitting and all its particles died. Use with "
               "burst > 0 and emitting = false for one-shot effects (explosions, pickups).");

    // --------------------------------------------------------------- 3D ---
    r.add<MeshRenderer>("MeshRenderer",
                        "Draws a 3D mesh with a simple PBR-style material. Needs a perspective Camera and (unless unlit) "
                        "a Light to be visible.",
                        "3D")
        .field("mesh", &MeshRenderer::mesh,
               "Built-in shape name (\"cube\", \"sphere\", \"plane\", \"cylinder\", \"capsule\", \"cone\", \"quad\") or a "
               "project-relative path to a .gltf/.glb model (e.g. \"assets/models/ship.glb\").")
        .asset_field("texture", &MeshRenderer::texture, "texture", "Base color texture. Empty = none (or the glTF material).")
        .field("color", &MeshRenderer::color, "Base color, multiplied with the texture.")
        .field("metallic", &MeshRenderer::metallic, "0 = plastic/stone, 1 = metal.").range(0, 1)
        .field("roughness", &MeshRenderer::roughness, "0 = mirror-smooth, 1 = fully rough/matte.").range(0, 1)
        .field("emissive", &MeshRenderer::emissive, "Light emitted by the surface regardless of lighting (glow). Black = none.")
        .field("unlit", &MeshRenderer::unlit, "true = ignore lighting and draw the flat base color.")
        .field("castShadows", &MeshRenderer::castShadows, "Cast shadows from shadow-casting lights.")
        .field("receiveShadows", &MeshRenderer::receiveShadows, "Receive shadows from shadow-casting lights.")
        .field("uvScale", &MeshRenderer::uvScale, "Texture tiling [u, v]; 2 repeats the texture twice.");

    r.add<Light>("Light",
                 "A light source for 3D meshes. A directional light shines along the entity's forward direction (-Z "
                 "rotated by the Transform), point and spot lights shine from the entity's position.",
                 "3D")
        .enum_field("type", &Light::type, {"directional", "point", "spot"},
                    "directional: sun-like, infinite distance. point: radiates in all directions. spot: cone along forward.")
        .field("color", &Light::color, "Light color.")
        .field("intensity", &Light::intensity, "Brightness multiplier.").range(0, 1000)
        .field("range", &Light::range, "Point/spot only: distance in meters where the light fades to zero.").range(0.01f, 100000)
        .field("spotAngle", &Light::spotAngle, "Spot only: cone half-angle in degrees.").range(1, 89)
        .field("castShadows", &Light::castShadows, "Cast shadows. Only supported on directional lights for now.");

    // ---------------------------------------------------------- Physics ---
    r.add<RigidBody2D>("RigidBody2D",
                       "Puts the entity under 2D physics (Box2D). Pair it with a Collider2D. Positions are simulated in "
                       "world units; gravity comes from the scene settings (gravity2D).",
                       "Physics")
        .enum_field("type", &RigidBody2D::type, {"static", "dynamic", "kinematic"},
                    "static: never moves (walls, floors). dynamic: moved by forces and collisions. kinematic: moved only "
                    "by setting velocity or the Transform; pushes dynamic bodies but is not pushed back.")
        .field("gravityScale", &RigidBody2D::gravityScale, "Multiplier on world gravity. 0 = floats, negative = falls upwards.")
        .field("linearDamping", &RigidBody2D::linearDamping, "Air resistance for movement; 0 = none, higher slows faster.").range(0, 1000)
        .field("angularDamping", &RigidBody2D::angularDamping, "Air resistance for spinning.").range(0, 1000)
        .field("fixedRotation", &RigidBody2D::fixedRotation, "true = never rotates from collisions (platformer characters).")
        .field("bullet", &RigidBody2D::bullet, "true = continuous collision detection, for fast small objects that would tunnel through walls.")
        .field("velocity", &RigidBody2D::velocity, "Linear velocity [x, y] in world units per second. Read/write: writes apply before the next physics step.")
        .field("angularVelocity", &RigidBody2D::angularVelocity, "Spin in degrees per second (counter-clockwise positive).");

    r.add<Collider2D>("Collider2D",
                      "Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. "
                      "Colliders collide when each one's layer is included in the other's mask.",
                      "Physics")
        .enum_field("shape", &Collider2D::shape, {"box", "circle", "capsule"}, "Shape type; uses size (box, capsule) or radius (circle).")
        .field("size", &Collider2D::size, "box/capsule: [width, height] in world units (capsule is vertical).")
        .field("radius", &Collider2D::radius, "circle: radius in world units.")
        .field("offset", &Collider2D::offset, "Shape center offset [x, y] from the entity origin, in world units.")
        .field("isTrigger", &Collider2D::isTrigger, "true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement.")
        .field("friction", &Collider2D::friction, "Surface friction; 0 = ice, 1 = grippy.").range(0, 10)
        .field("restitution", &Collider2D::restitution, "Bounciness: 0 = no bounce, 1 = perfectly elastic.").range(0, 1)
        .field("density", &Collider2D::density, "Mass per area; mass = density * shape area.").range(0, 10000)
        .field("layer", &Collider2D::layer, "Collision category of this collider, 0..31.").range(0, 31)
        .field("mask", &Collider2D::mask, "Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i).")
        .field("oneWay", &Collider2D::oneWay,
               "One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump "
               "up through it from below and pass sideways.");

    r.add<RigidBody3D>("RigidBody3D",
                       "Simple 3D physics body for arcade games (spheres and axis-aligned boxes; no rotation dynamics). "
                       "Pair it with a Collider3D. Gravity comes from scene settings (gravity3D).",
                       "Physics")
        .enum_field("type", &RigidBody3D::type, {"static", "dynamic", "kinematic"},
                    "static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform.")
        .field("mass", &RigidBody3D::mass, "Mass in kilograms (affects collision responses between dynamic bodies).").range(0.0001f, 1000000)
        .field("gravityScale", &RigidBody3D::gravityScale, "Multiplier on world gravity.")
        .field("linearDamping", &RigidBody3D::linearDamping, "Air resistance; 0 = none.").range(0, 1000)
        .field("velocity", &RigidBody3D::velocity, "Linear velocity [x, y, z] in meters per second. Read/write.")
        .field("angularVelocity", &RigidBody3D::angularVelocity,
               "Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step.")
        .field("rollWithMotion", &RigidBody3D::rollWithMotion,
               "Sphere colliders only: spin the sphere to match its rolling motion while it touches the ground "
               "(sets angularVelocity from the horizontal velocity).");

    r.add<Collider3D>("Collider3D",
                      "Collision shape for 3D physics (axis-aligned box or sphere). Scaled by the Transform scale.",
                      "Physics")
        .enum_field("shape", &Collider3D::shape, {"box", "sphere"}, "Shape type; uses size (box) or radius (sphere).")
        .field("size", &Collider3D::size, "box: full extents [x, y, z] in meters (axis-aligned, before Transform scale).")
        .field("radius", &Collider3D::radius, "sphere: radius in meters.")
        .field("offset", &Collider3D::offset, "Shape center offset [x, y, z] from the entity origin.")
        .field("isTrigger", &Collider3D::isTrigger, "true = sensor: reports overlaps but does not block movement.")
        .field("friction", &Collider3D::friction, "Surface friction; 0 = ice, 1 = grippy.").range(0, 10)
        .field("restitution", &Collider3D::restitution, "Bounciness: 0 = none, 1 = perfectly elastic.").range(0, 1)
        .field("layer", &Collider3D::layer, "Collision category of this collider, 0..31.").range(0, 31)
        .field("mask", &Collider3D::mask, "Bitmask of layers this collider collides with. -1 = all layers.");

    // ------------------------------------------------------------ Audio ---
    r.add<AudioSource>("AudioSource",
                       "Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` "
                       "from a script to trigger it.",
                       "Audio")
        .asset_field("clip", &AudioSource::clip, "audio", "Project-relative path of the sound (.wav, .ogg or .mp3).")
        .field("volume", &AudioSource::volume, "Loudness multiplier, 0 (silent) to 1 (full).").range(0, 1)
        .field("pitch", &AudioSource::pitch, "Playback speed multiplier; 2 = one octave higher and twice as fast.").range(0.05f, 8)
        .field("loop", &AudioSource::loop, "Restart the clip when it ends.")
        .field("playOnStart", &AudioSource::playOnStart, "Start playing when the entity spawns / the scene loads.")
        .field("playing", &AudioSource::playing, "Runtime state: true while a voice is playing. Set true to play, false to stop.").runtime_only()
        .field("spatial", &AudioSource::spatial, "true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI).")
        .field("range", &AudioSource::range, "Spatial only: distance in world units where the volume reaches 0.").range(0, 1000000);

    r.add<AudioListener>("AudioListener",
                         "The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the primary camera is used.",
                         "Audio")
        .field("volume", &AudioListener::volume, "Master volume multiplier for everything this listener hears.").range(0, 4);

    // -------------------------------------------------------- Scripting ---
    r.add<Script>("Script",
                  "Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class "
                  "extending Behaviour (see docs/SCRIPTING.md).",
                  "Scripting")
        .asset_field("path", &Script::path, "script", "Project-relative path of the script, e.g. \"scripts/player.js\".")
        .field("props", &Script::props,
               "JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. "
               "Lets one script serve many entities with different settings.")
        .field("enabled", &Script::enabled, "false = the script receives no callbacks.");

    // ------------------------------------------------------------ Scene ---
    r.add<SceneSettings>("SceneSettings",
                         "Scene-wide settings stored under \"settings\" in the scene file: lighting, fog, gravity and background music.",
                         "Scene")
        .field("ambientLight", &SceneSettings::ambientLight, "Base light added to all lit 3D surfaces so shadows are not pitch black.")
        .field("gravity2D", &SceneSettings::gravity2D, "2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards).")
        .field("gravity3D", &SceneSettings::gravity3D, "3D gravity [x, y, z] in m/s^2 (default 9.81 downwards).")
        .field("fogColor", &SceneSettings::fogColor, "Color distant 3D objects fade to.")
        .field("fogDensity", &SceneSettings::fogDensity, "Fog thickness; 0 disables fog.").range(0, 10)
        .field("skyColor", &SceneSettings::skyColor, "Top color of the 3D background gradient (used when a perspective camera clears).")
        .field("horizonColor", &SceneSettings::horizonColor, "Bottom color of the 3D background gradient.")
        .asset_field("music", &SceneSettings::music, "audio", "Looping background music asset path. Empty = none.")
        .field("musicVolume", &SceneSettings::musicVolume, "Volume of the background music, 0..1.").range(0, 1);
}

void ensure_builtin_components() {
    static std::once_flag once;
    std::call_once(once, [] {
        TypeRegistry& reg = TypeRegistry::global();
        if (!reg.find("EntityInfo")) register_builtin_components(reg);
    });
}

}  // namespace fa
