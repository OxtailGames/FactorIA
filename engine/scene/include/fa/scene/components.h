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

enum class ShapeType : std::int32_t { Rectangle, Circle, Line, Triangle, Diamond, Polygon, Star };
// Untextured primitive for prototypes, UI panels and debug visuals.
struct Shape2D {
    ShapeType shape = ShapeType::Rectangle;
    Vec2 size{32, 32};                // rectangle/triangle/diamond/polygon/star: width,height; circle: diameter in x; line: end point offset
    Color color{1, 1, 1, 1};
    bool filled = true;
    float thickness = 2.0f;           // outline / line thickness in world units
    std::int32_t layer = 0;
    RenderSpace space = RenderSpace::World;
    Vec2 pivot{0.5f, 0.5f};           // every shape but line: anchor within the shape's size box: 0,0 = bottom-left, 1,1 = top-right
    BlendMode blend = BlendMode::Alpha;
    Vec2 anchor{0, 0};                // screen space only: screen point the position is relative to
    std::int32_t sides = 6;           // polygon: number of sides (3..64); vertices on the ellipse inscribed in the size box, first one up
    std::int32_t points = 5;          // star: number of tips (3..64); tips on the inscribed ellipse, first one up
    float innerRadius = 0.5f;         // star: radius of the notches between the tips as a fraction of the outer radius (0..1)
};

struct Text {
    std::string text = "Text";
    std::string key;                  // localization key ("menu.play"); "" = none. While set, the runtime overwrites `text` with the translation
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
    RenderSpace space = RenderSpace::World;  // screen: drawn in the HUD pass in design pixels (origin top-left); ignored when is3D
    Vec2 anchor{0, 0};                // screen space only: screen point the position is relative to
};

// -------------------------------------------------------------------- UI ---
// Game UI widgets. They live in SCREEN SPACE only: design pixels, origin top-left, +Y down. Position is the entity's
// Transform.position (relative to its parent, like every entity); `anchor` and `pivot` mean what they mean on Shape2D
// in screen space. ponytail: rotation and scale of UI entities are ignored by layout and hit-testing.
// Behaviour lives in fa_ui (layout, focus, input, events) and fa_render (drawing); the geometry both need is in
// scene/ui_rect.h. components.cpp registers them (category "UI") with ui_box_fields(), so the shared doc strings exist once.
enum class UiLayout : std::int32_t { None, Row, Column, Grid };
enum class UiAlign : std::int32_t { Start, Center, End };

// Geometry and background shared by every widget.
struct UiBox {
    Vec2 size{320, 240};                      // [w, h] in design pixels (each kind sets its own default)
    Vec2 pivot{0.5f, 0.5f};                   // 0,0 = bottom-left, 1,1 = top-right (like Shape2D)
    Vec2 anchor{0, 0};                        // screen point the position is relative to
    std::int32_t layer = 200;                 // draw order; labels draw at layer + 1, the focus ring at layer + 2
    Color color{0.16f, 0.18f, 0.24f, 0.92f};  // background tint, multiplied with `texture`
    std::string texture;                      // optional background image, drawn 9-slice with `slice`
    Vec4 slice{0, 0, 0, 0};                   // 9-slice borders in texture pixels [left, top, right, bottom]
};

// What Button, Toggle, Slider and TextField add to UiBox.
struct UiControl : UiBox {
    std::string font;                         // asset path to .ttf; "" = built-in font
    float fontSize = 24.0f;
    Color textColor{1, 1, 1, 1};
    Color accentColor{1.0f, 0.76f, 0.2f, 1.0f};  // focus ring, slider fill and knob, toggle check, caret
    std::string key;                          // localization key; "" = none. Replaces Button.text, Toggle.label, Slider.label or TextField.placeholder
    bool interactable = true;                 // false: drawn at half alpha, never hovered, focused or clicked
    bool autoFocus = false;                   // takes focus when nothing is focused
    bool focused = false;                     // runtime: has keyboard / gamepad focus
    bool hovered = false;                     // runtime: the pointer is over it
    bool pressed = false;                     // runtime: the pointer is held down on it
};

// Container that groups children and can lay them out in a row, a column or a grid.
struct Panel : UiBox {
    UiLayout layout = UiLayout::None;
    float spacing = 8.0f;
    Vec4 padding{16, 16, 16, 16};             // left, top, right, bottom
    std::int32_t columns = 2;                 // grid only
    UiAlign align = UiAlign::Center;          // cross axis
    UiAlign justify = UiAlign::Start;         // main axis
    bool fit = false;                         // size = content + padding, every frame
};

struct Button : UiControl {
    std::string text = "Button";
    Button() { size = {240, 56}; }
};

struct Toggle : UiControl {
    std::string label = "Toggle";
    bool value = false;
    Toggle() { size = {240, 40}; }
};

struct Slider : UiControl {
    std::string label;
    float value = 0.5f;
    float min = 0.0f;
    float max = 1.0f;
    float step = 0.1f;                        // keyboard / gamepad increment and snapping; 0 = continuous
    bool showValue = true;
    Slider() { size = {320, 40}; }
};

struct TextField : UiControl {
    std::string text;
    std::string placeholder;
    std::int32_t maxLength = 64;              // code points; 0 = unlimited
    bool caret = false;                       // runtime: the caret is in the visible half of its blink
    TextField() { size = {320, 48}; }
};

// Container whose children are stacked in a column, scrolled and clipped to its rectangle.
struct ScrollList : UiBox {
    float spacing = 8.0f;
    Vec4 padding{8, 8, 8, 8};
    float scroll = 0.0f;                      // runtime: pixels scrolled from the top
    float scrollSpeed = 40.0f;                // pixels per mouse-wheel notch
    ScrollList() { size = {320, 240}; }
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

// Simple 3D physics for arcade games: spheres and oriented boxes (they follow the entity's world rotation), automatic
// continuous collision. Dynamic boxes are rigid bodies: contacts apply torque (inertia tensor from size and mass), so
// they tip over, tumble and settle; lockRotation keeps a box upright. A sphere is an arcade rolling ball while
// rollWithMotion is on (the default); with it off the sphere is a rigid body too (contacts spin it, so it rolls).
struct RigidBody3D {
    BodyType type = BodyType::Dynamic;
    float mass = 1.0f;
    float gravityScale = 1.0f;
    float linearDamping = 0.0f;
    Vec3 velocity{0, 0, 0};           // m/s, read/write
    Vec3 angularVelocity{0, 0, 0};    // deg/s around x,y,z, read/write; integrated into Transform.rotation
    bool rollWithMotion = true;       // sphere colliders: arcade rolling (spin matches the motion); false = rigid sphere
    float rollingFriction = 0.02f;    // rollWithMotion spheres: rolling resistance instead of sliding friction (>= 0)
    float angularDamping = 0.0f;      // rotation drag (>= 0): angularVelocity decays by 1 / (1 + dt * damping) per step
    bool lockRotation = false;        // contacts never spin the body (characters, upright crates, sliding balls)
};

enum class ColliderShape3D : std::int32_t { Box, Sphere };
struct Collider3D {
    ColliderShape3D shape = ColliderShape3D::Box;
    Vec3 size{1, 1, 1};               // box extents (full size, in the entity's rotated frame, scaled by Transform.scale)
    float radius = 0.5f;              // sphere radius
    Vec3 offset{0, 0, 0};             // shape centre from the entity origin; rotated and scaled with the entity
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
