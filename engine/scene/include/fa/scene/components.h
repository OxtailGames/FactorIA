// Built-in components. Components are PLAIN DATA; behaviour lives in systems
// (fa_render, fa_physics, fa_audio, fa_script). Every field here is reflected
// in register_builtin_components() (components.cpp) with documentation — keep
// the doc strings there in sync when adding fields.
//
// JSON names: component = struct name ("Sprite"), field = camelCase member.
// Units: 2D world units are design-resolution pixels by default (a 2D camera
// with orthoSize 0 shows exactly the design resolution). 3D units are meters.
// Angles are degrees. Colors are linear 0..1 RGBA.
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

class TypeRegistry;

// ---------------------------------------------------------------- core ----
// Present on every entity (added by World::create). Not listed under
// "components" in scene JSON: its fields are the entity's top-level keys
// (id, name, tags, active).
struct EntityInfo {
    std::string id;                 // stable string id, unique per world ("player", "enemy_3")
    std::string name;               // display name (not unique)
    std::vector<std::string> tags;  // free-form labels: "enemy", "pickup"...
    bool active = true;             // inactive entities (and their children) are skipped by all systems
};

// Present on every entity (added by World::create).
struct Transform {
    Vec3 position{0, 0, 0};  // local position (relative to parent)
    Vec3 rotation{0, 0, 0};  // local euler degrees (pitch x, yaw y, roll z); 2D uses z
    Vec3 scale{1, 1, 1};     // local scale
};

// --------------------------------------------------------------- camera ---
enum class Projection : std::int32_t { Orthographic, Perspective };
struct Camera {
    Projection projection = Projection::Orthographic;
    float fov = 60.0f;          // perspective: vertical field of view (degrees)
    float orthoSize = 0.0f;     // orthographic: half of the visible height in world units; 0 = design height / 2 (pixel perfect)
    float nearPlane = 0.1f;     // perspective near clip (orthographic uses -1000)
    float farPlane = 1000.0f;   // far clip (orthographic uses +1000)
    Color clearColor{0.08f, 0.08f, 0.12f, 1.0f};
    bool clear = true;
    bool primary = true;        // the first active primary camera renders the game
    std::int32_t depth = 0;     // multiple cameras render in ascending depth order
    // Bloom post-process (glow around bright pixels), flat fields because reflection has no nested structs.
    // Applied by fa_render to the finished frame (screen-space items too unless bloomScreenSpace is false); off by default.
    bool bloom = false;
    float bloomThreshold = 0.7f;   // brightness (largest of r, g, b; 0..1) where the glow starts
    float bloomIntensity = 1.2f;   // strength of the added glow (0..10)
    float bloomRadius = 20.0f;     // glow size in design pixels (1..128)
    bool bloomScreenSpace = true;  // false: screen-space items (HUD) are drawn after the bloom, so they stay crisp
};

// ------------------------------------------------------------------- 2D ---
enum class RenderSpace : std::int32_t { World, Screen };
// Screen space = UI/HUD: position is in design-resolution pixels with (0,0) at
// the TOP-LEFT and +Y DOWN; drawn after the world, unaffected by cameras.
// `anchor` (screen space only) picks the screen point the position is relative
// to: (0,0) top-left (default), (1,0) top-right, (0.5,0.5) center, (1,1)
// bottom-right — so HUDs stay glued to screen edges on any aspect ratio.

// How a 2D item is composited: alpha (default), additive (glow/neon, fire,
// lasers), multiply (shadows, tinting).
enum class BlendMode : std::int32_t { Alpha, Additive, Multiply };

enum class Align : std::int32_t { Left, Center, Right };

struct Sprite {
    std::string texture;              // asset path; "" draws a solid quad of `color`
    Rect region{0, 0, 0, 0};          // source rect in texture pixels (top-left origin); 0 size = whole texture
    Vec2 size{0, 0};                  // size in world units; 0 = region/texture pixel size
    Vec2 pivot{0.5f, 0.5f};           // 0,0 = bottom-left, 1,1 = top-right
    Color color{1, 1, 1, 1};          // tint multiplied with the texture
    bool flipX = false;
    bool flipY = false;
    std::int32_t layer = 0;           // draw order: higher layers draw on top; ties sort by position.y (lower y on top) then creation
    RenderSpace space = RenderSpace::World;
    bool pixelArt = true;             // nearest-neighbour filtering when true, linear otherwise
    BlendMode blend = BlendMode::Alpha;
    Vec2 anchor{0, 0};                // screen space only: screen point the position is relative to (see above)
};

// Grid-based flipbook over a sprite sheet. Requires Sprite on the same entity;
// it overwrites Sprite.region every frame.
struct SpriteAnimator {
    std::int32_t columns = 1;         // sheet grid columns
    std::int32_t rows = 1;            // sheet grid rows
    std::int32_t firstFrame = 0;      // inclusive, row-major index into the grid
    std::int32_t lastFrame = 0;       // inclusive
    float fps = 10.0f;
    bool loop = true;
    bool playing = true;
    float time = 0.0f;                // runtime: elapsed time in the current clip (seconds)
    std::int32_t frame = 0;           // runtime: current frame index
};

enum class ShapeType : std::int32_t { Rectangle, Circle, Line, Triangle, Diamond };
// Untextured primitive for prototypes, UI panels and debug visuals.
struct Shape2D {
    ShapeType shape = ShapeType::Rectangle;
    Vec2 size{32, 32};                // rectangle/triangle/diamond: width,height; circle: diameter in x; line: end point offset
    Color color{1, 1, 1, 1};
    bool filled = true;
    float thickness = 2.0f;           // outline / line thickness in world units
    std::int32_t layer = 0;
    RenderSpace space = RenderSpace::World;
    Vec2 pivot{0.5f, 0.5f};           // rectangle/circle/triangle/diamond anchor within the shape's size box: 0,0 = bottom-left, 1,1 = top-right
    BlendMode blend = BlendMode::Alpha;
    Vec2 anchor{0, 0};                // screen space only: screen point the position is relative to
};

struct Text {
    std::string text = "Text";
    std::string font;                 // asset path to .ttf; "" = built-in font
    float fontSize = 24.0f;           // in world units (pixels for 2D)
    Color color{1, 1, 1, 1};
    Align align = Align::Left;
    Vec2 pivot{0.0f, 1.0f};           // anchor within the text box: 0,1 = top-left
    float maxWidth = 0.0f;            // > 0 wraps lines at this width
    std::int32_t layer = 100;
    RenderSpace space = RenderSpace::World;
    Vec2 anchor{0, 0};                // screen space only: screen point the position is relative to
};

// Grid of tiles drawn from a tileset texture. Tile index -1 = empty.
// Optional static collision is generated by fa_physics for solid tiles.
struct Tilemap {
    std::string tileset;              // asset path to the tileset texture
    Vec2 tileSize{16, 16};            // size of one tile in the tileset AND in the world (world units)
    std::int32_t columns = 0;         // tile columns in the tileset texture; 0 = derive from the texture width / tileSize.x
    std::int32_t width = 0;           // map width in tiles (flat tiles; rows define their own size, see tilemap_grid)
    std::int32_t height = 0;          // map height in tiles (flat tiles)
    Json tiles = Json::array();       // row-major tile indices, row 0 = TOP row; array of ints (width*height) or array of rows
    Json solidTiles = Json::array();  // tile indices that collide (empty = none collide)
    Color color{1, 1, 1, 1};
    std::int32_t layer = -10;
};

struct ParticleEmitter {
    bool emitting = true;
    float rate = 20.0f;               // particles per second
    std::int32_t burst = 0;           // particles emitted once when the emitter starts
    std::int32_t maxParticles = 500;
    float lifetime = 1.0f;            // seconds
    float lifetimeVariance = 0.2f;    // +- fraction of lifetime
    float speed = 100.0f;             // initial speed (world units/s)
    float speedVariance = 0.3f;       // +- fraction of speed
    float direction = 90.0f;          // emission direction in degrees (90 = up)
    float spread = 30.0f;             // cone half-angle in degrees
    Vec3 gravity{0, -200, 0};         // acceleration (world units/s^2)
    float startSize = 8.0f;
    float endSize = 0.0f;
    Color startColor{1, 1, 1, 1};
    Color endColor{1, 1, 1, 0};
    std::string texture;              // "" = soft round particle
    bool worldSpace = true;           // particles stay where emitted when the emitter moves
    bool is3D = false;                // emit in a 3D cone (camera-facing billboards)
    std::int32_t layer = 50;
    BlendMode blend = BlendMode::Alpha;
    bool autoDestroy = false;         // destroy the entity once it stopped emitting and all particles died (one-shot effects)
};

// ------------------------------------------------------------------- 3D ---
// mesh: "cube" | "sphere" | "plane" | "cylinder" | "capsule" | "cone" | "quad"
//       or an asset path to a .gltf/.glb file ("assets/models/ship.glb").
struct MeshRenderer {
    std::string mesh = "cube";
    std::string texture;              // base color texture ("" = none / glTF material)
    Color color{1, 1, 1, 1};          // base color (multiplied with texture)
    float metallic = 0.0f;
    float roughness = 0.6f;
    Color emissive{0, 0, 0, 1};
    bool unlit = false;               // ignore lighting
    bool castShadows = true;
    bool receiveShadows = true;
    Vec2 uvScale{1, 1};               // texture tiling
};

enum class LightType : std::int32_t { Directional, Point, Spot };
struct Light {
    LightType type = LightType::Directional;  // directional lights point along the entity's forward (-Z rotated)
    Color color{1, 1, 1, 1};
    float intensity = 1.0f;
    float range = 10.0f;              // point/spot attenuation distance (meters)
    float spotAngle = 30.0f;          // spot cone half-angle (degrees)
    bool castShadows = false;         // directional only for now
};

// ------------------------------------------------------------- physics ---
enum class BodyType : std::int32_t { Static, Dynamic, Kinematic };
enum class ColliderShape : std::int32_t { Box, Circle, Capsule };

struct RigidBody2D {
    BodyType type = BodyType::Dynamic;
    float gravityScale = 1.0f;
    float linearDamping = 0.0f;
    float angularDamping = 0.05f;
    bool fixedRotation = false;       // true for platformer characters
    bool bullet = false;              // continuous collision for fast objects
    Vec2 velocity{0, 0};              // world units/s; read/write — writes are applied before the next physics step
    float angularVelocity = 0.0f;     // degrees/s
};

struct Collider2D {
    ColliderShape shape = ColliderShape::Box;
    Vec2 size{32, 32};                // box: width,height; capsule: width,height (vertical)
    float radius = 16.0f;             // circle radius
    Vec2 offset{0, 0};                // local offset from the entity origin
    bool isTrigger = false;           // sensor: reports overlaps, no collision response
    float friction = 0.4f;
    float restitution = 0.0f;         // bounciness 0..1
    float density = 1.0f;
    std::int32_t layer = 0;           // collision layer 0..31 (this collider's category bit)
    std::int32_t mask = -1;           // bitmask of layers it collides with (-1 = all)
    bool oneWay = false;              // one-way platform: only blocks bodies coming from above (+Y side of the entity)
};

// Simple 3D physics (spheres and axis-aligned boxes, no rotation dynamics).
// Good for arcade 3D games; a full 3D solver is on the roadmap.
struct RigidBody3D {
    BodyType type = BodyType::Dynamic;
    float mass = 1.0f;
    float gravityScale = 1.0f;
    float linearDamping = 0.0f;
    Vec3 velocity{0, 0, 0};           // m/s, read/write
    Vec3 angularVelocity{0, 0, 0};    // deg/s around x,y,z, read/write; integrated into Transform.rotation
    bool rollWithMotion = true;       // sphere colliders spin to match their rolling motion while touching the ground
};

enum class ColliderShape3D : std::int32_t { Box, Sphere };
struct Collider3D {
    ColliderShape3D shape = ColliderShape3D::Box;
    Vec3 size{1, 1, 1};               // box extents (full size, axis-aligned, scaled by Transform.scale)
    float radius = 0.5f;              // sphere radius
    Vec3 offset{0, 0, 0};
    bool isTrigger = false;
    float friction = 0.4f;
    float restitution = 0.0f;
    std::int32_t layer = 0;
    std::int32_t mask = -1;
};

// ---------------------------------------------------------------- audio ---
struct AudioSource {
    std::string clip;                 // asset path (.wav, .ogg, .mp3)
    float volume = 1.0f;              // 0..1
    float pitch = 1.0f;               // playback rate multiplier
    bool loop = false;
    bool playOnStart = false;         // start when the entity is spawned / scene loads
    bool playing = false;             // runtime: true while a voice is playing; set true to play, false to stop
    bool spatial = false;             // pan/attenuate relative to the AudioListener
    float range = 800.0f;             // spatial: distance where volume reaches 0 (world units)
};

// The listener for spatial audio (usually on the camera). If none exists,
// the primary camera is used.
struct AudioListener {
    float volume = 1.0f;
};

// ------------------------------------------------------------- scripting ---
// JavaScript behaviour attached to the entity. `path` is an ES module whose
// default export is a class extending `Behaviour` (see docs/SCRIPTING.md).
// `props` are assigned onto the instance before onStart (scene-tunable values).
struct Script {
    std::string path;
    Json props = Json::object();
    bool enabled = true;
};

// --------------------------------------------------------------------------
// Scene-wide settings (stored in the scene file under "settings").
struct SceneSettings {
    Color ambientLight{0.25f, 0.25f, 0.3f, 1.0f};
    Vec2 gravity2D{0, -980};          // world units/s^2 (pixels for 2D)
    Vec3 gravity3D{0, -9.81f, 0};     // m/s^2
    Color fogColor{0.5f, 0.6f, 0.7f, 1.0f};
    float fogDensity = 0.0f;          // 0 = no fog
    Color skyColor{0.45f, 0.62f, 0.85f, 1.0f};    // 3D background gradient top (used when a perspective camera clears)
    Color horizonColor{0.8f, 0.85f, 0.9f, 1.0f};  // gradient bottom
    std::string music;                // asset path, looped background music ("" = none)
    float musicVolume = 0.6f;
};

// Registers every component above (plus SceneSettings as a reflected type)
// in the registry. Called once by World construction via ensure_builtin_components().
void register_builtin_components(TypeRegistry& registry);
void ensure_builtin_components();  // idempotent, registers into TypeRegistry::global()

}  // namespace fa
