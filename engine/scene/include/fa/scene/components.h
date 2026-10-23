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
#include <memory>
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
// Last post-process of the frame, see Camera::colorFilter.
enum class ColorFilter : std::int32_t { None, Greyscale, HighContrast, Protanopia, Deuteranopia, Tritanopia };
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
    // Accessibility filter over the whole finished frame (HUD included), after the bloom; a flat enum like the bloom fields.
    ColorFilter colorFilter = ColorFilter::None;
};

// ------------------------------------------------------------------- 2D ---
enum class RenderSpace : std::int32_t { World, Screen };
// Screen space = UI/HUD: position is in design-resolution pixels with (0,0) at
// the TOP-LEFT and +Y DOWN; drawn after the world, unaffected by cameras.
// `anchor` (screen space only) picks the screen point the position is relative
// to: (0,0) top-left (default), (1,0) top-right, (0.5,0.5) center, (1,1)
// bottom-right — so HUDs stay glued to screen edges on any aspect ratio.
// `safeArea` (screen space only) makes the anchor name a point of the SAFE area instead of the whole screen: the screen
// minus the notch, rounded corners and system bars of a phone (World::safe_insets, screen.safeArea in scripts).

// How a 2D item is composited: alpha (default), additive (glow/neon, fire,
// lasers), multiply (shadows, tinting).
enum class BlendMode : std::int32_t { Alpha, Additive, Multiply };

// Start / End are the left / right edge in a left-to-right language and the right / left edge in a right-to-left one.
enum class Align : std::int32_t { Left, Center, Right, Start, End };

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
    bool safeArea = false;              // screen space only: the anchor names a point of the safe area (see above)
    Vec4 slice{0, 0, 0, 0};           // 9-slice borders in texture pixels [left, top, right, bottom] (0 = stretch the whole region)
    bool lit = false;                 // world space only: shaded by Light2D entities and SceneSettings.ambientLight
    std::string normalMap;            // tangent-space normal map with the same layout as `texture` ("" = flat); needs lit
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
    bool safeArea = false;              // screen space only: the anchor names a point of the safe area (see above)
    std::int32_t sides = 6;           // polygon: number of sides (3..64); vertices on the ellipse inscribed in the size box, first one up
    std::int32_t points = 5;          // star: number of tips (3..64); tips on the inscribed ellipse, first one up
    float innerRadius = 0.5f;         // star: radius of the notches between the tips as a fraction of the outer radius (0..1)
    bool lit = false;                 // world space only: shaded by Light2D entities and SceneSettings.ambientLight
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
    bool safeArea = false;              // screen space only: the anchor names a point of the safe area (see above)
};

// Grid of tiles drawn from a tileset texture. Tile index -1 = empty.
// Optional static collision is generated by fa_physics for solid tiles.
struct Tilemap {
    std::string tileset;              // asset path to the tileset texture
    Vec2 tileSize{16, 16};            // size of one tile in the tileset AND in the world (world units)
    std::int32_t columns = 0;         // tile columns in the tileset texture; 0 = derive from the texture width / tileSize.x
    std::int32_t width = 0;           // map width in tiles (flat tiles; rows define their own size, see tilemap_grid)
    std::int32_t height = 0;          // map height in tiles (flat tiles)
    Json tiles = Json::array();       // row-major tile values, row 0 = TOP row; array of ints (width*height) or array of rows.
                                      // A value is the tile index plus optional flip/rotate flag bits (fa/scene/tilemap.h)
    Json solidTiles = Json::array();  // tile indices that collide (empty = none collide); flags are not part of them
    Color color{1, 1, 1, 1};
    std::int32_t layer = -10;
    bool lit = false;                 // shaded by Light2D entities and SceneSettings.ambientLight
    std::string normalMap;            // normal map image with the same layout as the tileset ("" = flat); needs lit
};

// Draws this entity's 2D visuals (Sprite, Shape2D, Text, Tilemap) shifted by a fraction of the camera's movement, so
// far layers slide slower than near ones. Offset = camera position * (1 - factor) per axis: factor 1 moves with the
// world as usual, 0 stays glued to the camera (sky), between 0 and 1 is behind the action, above 1 in front of it.
// With the camera at (0, 0) the entity is exactly where its Transform says. Only world-space visuals are shifted.
struct Parallax {
    Vec2 factor{0.5f, 0.5f};          // [x, y] fraction of the camera movement the layer follows
    bool repeatX = false;             // Sprite only: tile the sprite endlessly along world x so the background never ends
    bool repeatY = false;             // Sprite only: same along world y
    Vec2 repeatSize{0, 0};            // distance between repeats; 0 = the sprite's own size on that axis
    Vec2 offset{0, 0};                // runtime: the shift applied to the drawing this frame (written by the renderer)
};

// A light for lit 2D visuals (Sprite.lit, Tilemap.lit). Only lit visuals react to it; everything else is drawn as before.
enum class Light2DType : std::int32_t { Point, Directional };
struct Light2D {
    Light2DType type = Light2DType::Point;
    Color color{1, 1, 1, 1};
    float intensity = 1.0f;           // multiplies color; above 1 over-brightens
    float radius = 300.0f;            // point: distance in world units where the light has faded to nothing
    float falloff = 2.0f;             // point: how fast it fades: brightness = (1 - distance/radius)^falloff
    float height = 80.0f;             // point: height above the drawing plane in world units; lower = more grazing normal-map relief
    float direction = 270.0f;         // directional: degrees the light travels towards (0 = right, 90 = up, 270 = down)
    float elevation = 45.0f;          // directional: degrees above the drawing plane (90 = straight at the picture)
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
    bool safeArea = false;              // screen space only: the anchor names a point of the safe area (see above)
};

// -------------------------------------------------------------------- UI ---
// Game UI widgets. They live in SCREEN SPACE only: design pixels, origin top-left, +Y down. Position is the entity's
// Transform.position (relative to its parent, like every entity); `anchor` and `pivot` mean what they mean on Shape2D
// in screen space. ponytail: rotation and scale of UI entities are ignored by layout and hit-testing.
// Behaviour lives in fa_ui (layout, focus, input, events) and fa_render (drawing); the geometry both need is in
// scene/ui_rect.h. components.cpp registers them (category "UI") with ui_box_fields(), so the shared doc strings exist once.
enum class UiLayout : std::int32_t { None, Row, Column, Grid };
enum class UiAlign : std::int32_t { Start, Center, End };
// Panel.direction: Ltr = start is left; Rtl = start is right (rows run right to left); Auto = follows the current language.
enum class UiDirection : std::int32_t { Ltr, Auto, Rtl };

// Geometry and background shared by every widget.
struct UiBox {
    Vec2 size{320, 240};                      // [w, h] in design pixels (each kind sets its own default)
    Vec2 pivot{0.5f, 0.5f};                   // 0,0 = bottom-left, 1,1 = top-right (like Shape2D)
    Vec2 anchor{0, 0};                        // screen point the position is relative to
    bool safeArea = false;              // screen space only: the anchor names a point of the safe area (see above)
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
    UiDirection direction = UiDirection::Ltr; // horizontal reading direction of the layout
    bool fit = false;                         // size = content + padding, every frame
    bool uniformSize = false;                 // autoSize buttons / toggles / sliders inside share the largest size
    UiLayout fallbackLayout = UiLayout::None; // layout used instead of `layout` when that would not fit the screen
    bool usingFallback = false;               // runtime: laid out with fallbackLayout right now
};

struct Button : UiControl {
    std::string text = "Button";
    float maxWidth = 0.0f;                    // > 0 wraps the label at this width (design pixels); 0 = no wrap
    bool autoSize = false;                    // grow to fit the label (at least `size`), at the current ui.textScale
    Button() { size = {240, 56}; }
};

struct Toggle : UiControl {
    std::string label = "Toggle";
    bool value = false;
    bool autoSize = false;                    // grow to fit the label (at least `size`), at the current ui.textScale
    Toggle() { size = {240, 40}; }
};

struct Slider : UiControl {
    std::string label;
    float value = 0.5f;
    float min = 0.0f;
    float max = 1.0f;
    float step = 0.1f;                        // keyboard / gamepad increment and snapping; 0 = continuous
    bool showValue = true;
    bool autoSize = false;                    // grow to fit the label and value text (at least `size`), at the current ui.textScale
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
    bool fill = false;                        // inside a column Panel: take the height the other children leave
    ScrollList() { size = {320, 240}; }
};

// On-screen gamepad for phones and tablets: a stick and buttons that drive a virtual pad (Input's touch pad), so the
// actions bound to GamepadA, GamepadLeftStickRight... work on a touch screen without a change to the game. fa_ui hands
// their rectangles to Input and writes the runtime fields; fa_render draws them. Neither is focusable.
enum class TouchStickSide : std::int32_t { Left, Right };
// A pad button, in fa::GamepadButton order (fa_ui checks the count), so scene does not depend on fa_platform.
enum class PadButton : std::int32_t {
    A, B, X, Y, Start, Back, Guide, DpadLeft, DpadRight, DpadUp, DpadDown, LeftShoulder, RightShoulder, LeftThumb, RightThumb
};

struct TouchStick : UiBox {
    TouchStickSide stick = TouchStickSide::Left;
    Color knobColor{1, 1, 1, 0.6f};
    bool touchOnly = true;                    // drawn and active only while the player uses touch
    Vec2 value{0, 0};                         // runtime: the finger's offset, length <= 1, +Y up
    bool pressed = false;                     // runtime: a finger holds it
    bool shown = false;                       // runtime: drawn this frame
    TouchStick() {
        size = {200, 200};
        safeArea = true;
        color = {1, 1, 1, 0.2f};
    }
};

struct TouchButton : UiBox {
    PadButton button = PadButton::A;
    std::string text;                         // label; "" = none
    std::string font;
    float fontSize = 32.0f;
    Color textColor{1, 1, 1, 0.9f};
    bool touchOnly = true;
    bool pressed = false;                     // runtime: a finger holds it
    bool shown = false;                       // runtime: drawn this frame
    TouchButton() {
        size = {96, 96};
        safeArea = true;
        color = {1, 1, 1, 0.2f};
    }
};

// The subtitles of the game: shows the lines that audio.play(path, { caption }) and ui.caption(text, seconds) put on the
// caption list (fa/scene/captions.h). The box is the area the captions may use (placement like any widget: anchor, pivot,
// safeArea, layer); the block of lines sits at its bottom edge and its background hugs the lines.
struct Captions : UiBox {
    std::int32_t maxLines = 3;                // lines shown at once; a new line drops the oldest
    Vec4 padding{16, 8, 16, 8};               // left, top, right, bottom between the background edge and the text
    std::string font;                         // asset path to .ttf; "" = built-in font
    float fontSize = 28.0f;
    Color textColor{1, 1, 1, 1};
    Color speakerColor{1.0f, 0.82f, 0.35f, 1};
    Align align = Align::Center;
    float spacing = 4.0f;                     // gap between lines
    Json lines = Json::array();               // runtime: [{text, speaker}] drawn now, oldest first (written by the engine)
    Captions() {
        size = {960, 180};
        anchor = {0.5f, 1.0f};
        pivot = {0.5f, 0.0f};
        safeArea = true;
        color = {0, 0, 0, 0.7f};
    }
};

// ------------------------------------------------------------------- 3D ---
// mesh: "cube" | "sphere" | "plane" | "cylinder" | "capsule" | "cone" | "quad"
//       or an asset path to a .gltf/.glb file ("assets/models/ship.glb").
struct MeshRenderer {
    std::string mesh = "cube";
    std::string texture;              // base color texture ("" = none / glTF material)
    std::string normalMap;            // tangent-space normal map ("" = none / glTF normalTexture)
    float normalScale = 1.0f;         // strength of the normal map
    Color color{1, 1, 1, 1};          // base color (multiplied with texture)
    float metallic = 0.0f;
    float roughness = 0.6f;
    Color emissive{0, 0, 0, 1};
    bool unlit = false;               // ignore lighting
    bool castShadows = true;
    bool receiveShadows = true;
    Vec2 uvScale{1, 1};               // texture tiling
    std::string material;             // "" = the standard material; else a *.material.json (docs/SHADERS.md)
    Json materialParams = Json::object();  // per-entity overrides of the material's params and textures: {"glow": [1,0,0,1]}
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

struct SkeletonAsset;  // skeleton.h

// What the animation system (animation.h) keeps per Animator at run time. Never serialized; copying an Animator copies it.
struct AnimatorRuntime {
    std::shared_ptr<const SkeletonAsset> skeleton;
    std::string skeletonPath;        // the model `skeleton` was loaded from
    bool started = false;            // the first update ran (initial clip / state entered)
    bool warned = false;             // a problem was already logged (once per animator)
    std::string activeClip;          // clip the animator is playing (its `clip` field differing means a script changed it)
    int clipIndex = -1;
    float prevTime = -1.0f;          // time of the previous step, the start of the window of events to fire (-1: the clip just started)
    float lastTime = 0.0f;           // value `time` had after the last update (a different value means a script seeked)
    bool finished = false;           // a non-looping clip reached its end (transitions with onFinish)
    int fromIndex = -1;              // clip fading out (-1 = no fade running)
    float fromTime = 0.0f;
    bool fromLoop = true;
    float fadeElapsed = 0.0f, fadeDuration = 0.0f;
    std::vector<std::string> triggers;  // trigger() calls, true for one update
};

// Skeletal animation of a skinned glTF model, played by the animation system every fixed step (headless runs too).
struct Animator {
    std::string model;                // glTF to animate; "" = the `mesh` of the MeshRenderer on the same entity
    std::string clip;                 // clip playing now (glTF animation name); "" = bind pose
    float speed = 1.0f;               // playback speed multiplier (1 = authored speed, 0 = frozen)
    bool loop = true;
    bool playing = true;
    float fade = 0.2f;                // seconds of cross-fade when `clip` is changed by assignment
    Json params = Json::object();     // state machine: parameters and their start values {"speed": 0, "jump": false}
    Json states = Json::object();     // state machine: {"idle": {"clip": "Idle", "loop": true, "speed": 1, "onEnter": "event"}}
    Json transitions = Json::array(); // state machine: [{"from": "idle", "to": "run", "when": "speed > 0.1", "fade": 0.2}]
    Json events = Json::array();      // clip events: [{"clip": "Walk", "time": 0.3, "name": "footstep"}]
    std::string state;                // state machine: current state ("" = the first state of `states`)
    float time = 0.0f;                // runtime: seconds into the current clip (assignable: seek)
    Json values = Json::object();     // runtime: current value of every parameter
    // Runtime, not reflected. The renderer reads `palette`: one skinning matrix per joint of skin 0 (jointGlobal *
    // inverseBind, in the glTF's model space); empty while there is no skin. Written by update_animators (animation.h).
    std::vector<Mat4> palette;
    AnimatorRuntime rt;
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

// A Box2D joint between this entity's body and another one (or the world). Put it on the body entity; both entities need a
// RigidBody2D or Collider2D. Lengths and anchors are in world units (pixels), angles in degrees; gameplay never sees meters.
// Anchors are in the entity's local space and scaled with its Transform.scale, like Collider2D.offset. Revolute angles are
// measured from the relative angle of the two bodies when the joint was created (0 = the creation pose); prismatic
// translation is 0 where the two anchors coincide.
enum class JointType2D : std::int32_t { Revolute, Distance, Prismatic, Weld };
struct Joint2D {
    JointType2D type = JointType2D::Revolute;
    Entity connected = kNullEntity;   // the other body; empty = fixed to the world (connectedAnchor is then a world position)
    Vec2 anchor{0, 0};                // joint point in this entity's local space
    Vec2 connectedAnchor{0, 0};       // joint point in the connected entity's local space (a world position when `connected` is empty)
    Vec2 axis{1, 0};                  // prismatic: slide direction in this entity's local space (normalised by the engine)
    bool collideConnected = false;    // the two bodies still collide with each other
    float length = 0.0f;              // distance: rest length; 0 = the distance between the anchors when the joint is created
    bool enableLimit = false;
    float lowerLimit = 0.0f;          // revolute: degrees; prismatic: translation; distance: minimum length (world units)
    float upperLimit = 0.0f;          // revolute: degrees; prismatic: translation; distance: maximum length (world units)
    bool enableMotor = false;         // revolute and prismatic: drive towards motorSpeed; distance: needs enableSpring
    float motorSpeed = 0.0f;          // revolute: degrees/s; prismatic and distance: world units/s
    float maxMotorTorque = 0.0f;      // largest torque (revolute) or force (prismatic, distance) the motor may use
    bool enableSpring = false;        // revolute, prismatic, distance: soft constraint along the free axis
    float springHertz = 0.0f;         // spring stiffness in cycles per second; weld: 0 = rigid, above 0 = soft
    float dampingRatio = 0.0f;        // 0 = bounces forever, 1 = no overshoot
    Vec2 reactionForce{0, 0};         // runtime: force the joint applies to hold the bodies together
    float reactionTorque = 0.0f;      // runtime: torque the joint applies
    float angle = 0.0f;               // runtime: revolute and weld: current joint angle in degrees
    float translation = 0.0f;         // runtime: prismatic: slide position; distance: current length (world units)
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

// Box and Sphere are the primitive shapes; Capsule is a segment along the entity's local Y plus a radius; Convex is the
// convex hull of a mesh's vertices; Mesh is the mesh's triangles (static bodies only).
enum class ColliderShape3D : std::int32_t { Box, Sphere, Capsule, Convex, Mesh };
struct Collider3D {
    ColliderShape3D shape = ColliderShape3D::Box;
    Vec3 size{1, 1, 1};               // box extents (full size, in the entity's rotated frame, scaled by Transform.scale)
    float radius = 0.5f;              // sphere / capsule radius
    float height = 2.0f;              // capsule: full height tip to tip along the entity's local Y (>= 2 * radius)
    std::string mesh;                 // convex / mesh: primitive name or project-relative .gltf/.glb path
    Vec3 offset{0, 0, 0};             // shape centre from the entity origin; rotated and scaled with the entity
    bool isTrigger = false;
    float friction = 0.4f;
    float restitution = 0.0f;
    std::int32_t layer = 0;
    std::int32_t mask = -1;
    bool navObstacle = false;         // left out of the NavMesh3D bake; blocks the cells it covers while it is there
};

// Joins this entity's RigidBody3D to another body (or to the world). Solved with the 3D contacts. A jointed dynamic body
// is always a rotating rigid body (lockRotation and rollWithMotion are ignored), and never falls asleep.
enum class JointType3D : std::int32_t { Hinge, Ball, Fixed };
struct Joint3D {
    JointType3D type = JointType3D::Hinge;
    Entity connected;                 // the other body; empty = the world (a fixed point)
    Vec3 anchor{0, 0, 0};             // joint point in THIS entity's local space (scaled with it)
    Vec3 connectedAnchor{0, 0, 0};    // joint point in the connected entity's local space (the world, when `connected` is empty)
    bool autoAnchor = true;           // compute connectedAnchor so that the joint holds exactly where the bodies are
    Vec3 axis{0, 0, 1};               // hinge axis in this entity's local space
    bool useLimits = false;           // hinge: keep the angle within [lowerLimit, upperLimit]
    float lowerLimit = -45.0f;        // degrees, relative to the pose the joint was created in
    float upperLimit = 45.0f;
    bool useMotor = false;            // hinge: drive the angle at motorSpeed
    float motorSpeed = 0.0f;          // degrees/second of this body relative to the connected one, about the axis
    float maxMotorTorque = 10.0f;     // N*m the motor may apply
    bool collideConnected = false;    // false: the two joined bodies do not collide with each other
    float angle = 0.0f;               // runtime: current hinge angle in degrees (read only)
};

// Kinematic capsule that moves and slides: walks along floors, up steps and slopes, stops at walls, pushes dynamic
// bodies. Moved with physics.moveCharacter(entity, delta) or by `velocity`; the entity origin is the capsule centre
// (plus `center`). Do not add a RigidBody3D / Collider3D to the same entity.
struct CharacterController3D {
    float radius = 0.4f;              // capsule radius (scaled by Transform.scale)
    float height = 1.8f;              // capsule height tip to tip (>= 2 * radius)
    Vec3 center{0, 0, 0};             // capsule centre from the entity origin
    float stepOffset = 0.3f;          // highest step it climbs, meters
    float slopeLimit = 45.0f;         // steepest walkable slope, degrees
    float skin = 0.02f;               // gap kept to surfaces, meters
    std::int32_t layer = 0;
    std::int32_t mask = -1;
    Vec3 velocity{0, 0, 0};           // m/s: if not zero, the character moves by velocity * dt every physics step
    bool carriedByPlatforms = true;   // a kinematic body it stands on carries it (displacement and turn)
    bool applyWeight = true;          // press on the dynamic body below with mass * gravity (at its feet)
    float mass = 70.0f;               // kg, the weight applied when applyWeight is on
    float pushStrength = 1.0f;        // scale of the speed given to the free dynamic bodies it walks into (0 = none)
    bool isGrounded = false;          // runtime: standing on walkable ground after the last move (read only)
    Vec3 groundNormal{0, 1, 0};       // runtime: normal of that ground (read only)
};

// A navigation mesh baked from the static 3D colliders inside a box around the entity: walkable cells for path finding
// (physics.nav_bake / nav.find_path, scripts' nav.findPath). Walkable = flat enough (maxSlope), tall enough (agentHeight),
// at least agentRadius from walls and drops, connected to the next cell when the height step is at most stepHeight.
struct NavMesh3D {
    Vec3 size{40, 10, 40};            // bounds in meters, centred on the entity's world position (rotation and scale ignored)
    float cellSize = 0.25f;           // width of a cell on the ground plane, meters
    float cellHeight = 0.05f;         // heights are rounded to a multiple of this, meters
    float agentRadius = 0.3f;         // radius of the walker the mesh is baked for, meters
    float agentHeight = 1.8f;         // height of the walker, meters (the clearance a cell needs overhead)
    float stepHeight = 0.4f;          // highest step the walker climbs, meters
    float maxSlope = 45.0f;           // steepest walkable slope, degrees
    bool autoBake = true;             // bake when the scene loads and again when static colliders change
    bool enabled = true;              // false: ignored by nav.find_path
    std::int32_t walkableCells = 0;   // runtime: walkable cells after the last bake (read only)
    std::int32_t regions = 0;         // runtime: separate walkable areas after the last bake (read only)
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
