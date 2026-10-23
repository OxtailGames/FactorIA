#include "fa/scene/components.h"

#include <mutex>

#include "fa/core/reflect.h"

namespace fa {

namespace {

// The fields every UI widget shares (UiBox), registered once for each kind so their documentation exists in one place.
template <class T>
TypeBuilder<T>& ui_box_fields(TypeBuilder<T>& b) {
    return b
        .field("size", static_cast<Vec2 T::*>(&UiBox::size),
               "Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider "
               "320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180). A Panel "
               "with fit = true recomputes it every frame.")
        .field("pivot", static_cast<Vec2 T::*>(&UiBox::pivot),
               "Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, "
               "[1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] "
               "is still the visual top-left. Layout does not care about the pivot of its children.")
        .field("anchor", static_cast<Vec2 T::*>(&UiBox::anchor),
               "Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] "
               "top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. "
               "The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] "
               "and are placed by the Panel's layout.")
        .field("safeArea", static_cast<bool T::*>(&UiBox::safeArea),
               "Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, "
               "rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole "
               "screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps "
               "HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes "
               "nothing. Default false (true on TouchStick and TouchButton).")
        .field("layer", static_cast<std::int32_t T::*>(&UiBox::layer),
               "Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at "
               "layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, "
               "then the latest entity, under the pointer is the hovered widget.")
        .field("color", static_cast<Color T::*>(&UiBox::color),
               "Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones "
               "darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], \"#rrggbb\" or a name.")
        .asset_field("texture", static_cast<std::string T::*>(&UiBox::texture), "texture",
                     "Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour "
                     "sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`.")
        .field("slice", static_cast<Vec4 T::*>(&UiBox::slice),
               "9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture "
               "pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives "
               "panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than "
               "left + right (or top + bottom) the borders shrink proportionally.");
}

// maxTextScale of Text and of the UI widgets.
constexpr const char* kMaxTextScaleDoc =
    "> 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label "
    "does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only "
    "limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring "
    "(autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.";

// autoShrink and minFontSize of Text, Button, Toggle, Slider and TouchButton.
constexpr const char* kAutoShrinkDoc =
    "true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made "
    "smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, "
    "and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no "
    "script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): "
    "the size is never reduced.";
constexpr const char* kMinFontSizeDoc =
    "autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, "
    "capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.";

// UiControl fields: the label font, colours and interaction state of Button, Toggle, Slider and TextField.
template <class T>
TypeBuilder<T>& ui_control_fields(TypeBuilder<T>& b) {
    ui_box_fields(b);
    return b
        .asset_field("font", static_cast<std::string T::*>(&UiControl::font), "font",
                     "Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font).")
        .field("key", static_cast<std::string T::*>(&UiControl::key),
               "Localization key, e.g. \"menu.play\" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime "
               "writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder "
               "(never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the "
               "language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps "
               "the text written in the field and logs one warning.")
        .field("fontSize", static_cast<float T::*>(&UiControl::fontSize), "Label glyph height in design pixels.").range(1, 4096)
        .field("maxTextScale", static_cast<float T::*>(&UiControl::maxTextScale), kMaxTextScaleDoc).range(0, 3)
        .field("textColor", static_cast<Color T::*>(&UiControl::textColor), "Label colour.")
        .field("accentColor", static_cast<Color T::*>(&UiControl::accentColor),
               "Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret.")
        .field("interactable", static_cast<bool T::*>(&UiControl::interactable),
               "false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. "
               "A focused widget that becomes non-interactable loses focus.")
        .field("autoFocus", static_cast<bool T::*>(&UiControl::autoFocus),
               "Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first "
               "widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; "
               "HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget "
               "disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus "
               "widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order "
               "takes the focus instead, so the gamepad is never left with nothing focused.")
        .field("focused", static_cast<bool T::*>(&UiControl::focused),
               "Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with "
               "ui.focus(entity).").runtime_only().read_only()
        .field("hovered", static_cast<bool T::*>(&UiControl::hovered),
               "Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one.")
        .runtime_only().read_only()
        .field("pressed", static_cast<bool T::*>(&UiControl::pressed),
               "Runtime: the pointer is held down on this widget.").runtime_only().read_only();
}

// touchOnly of TouchStick and TouchButton.
constexpr const char* kTouchOnlyDoc =
    "true (default): drawn and listed as visible only while the last input came from a finger (input.lastDevice \"touch\"; "
    "a phone or tablet starts that way), so it hides when the player picks up a gamepad or a keyboard and comes back on "
    "the next touch. A finger landing on it always works. false: always drawn (desktop previews, screenshots, tests).";

// autoSize of Button, Toggle and Slider.
constexpr const char* kAutoSizeDoc =
    "true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) "
    "and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing "
    "`size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider "
    "label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize "
    "makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a "
    "big label sticks out of it (Button labels are clipped).";

}  // namespace

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
               "over a glowing world; leave it true to make a screen-space title or logo glow.")
        .enum_field("colorFilter", &Camera::colorFilter,
                    {"none", "greyscale", "highContrast", "protanopia", "deuteranopia", "tritanopia"},
                    "Accessibility colour filter, the LAST post-process pass: it is applied to the whole finished frame "
                    "(HUD included, after the bloom) on every graphics backend, so screenshots, factoria run --screenshot-at and "
                    "--record-video show it too. A game's options screen sets it from the player's choice (it is not saved "
                    "by itself). none (default): no pass, no cost. greyscale: Rec. 709 luminance in linear light. highContrast: "
                    "contrast stretched 1.8x around mid grey, clipped. protanopia, deuteranopia, tritanopia: a daltonize "
                    "correction for a player who lacks that cone: the loss is estimated with the Machado 2009 matrix (severity 1.0) "
                    "and the lost information is shifted into the channels the player still sees (Fidaner's method), so colours "
                    "that collapse together (red vs green) differ in brightness or in the remaining hue. To CHECK a game "
                    "without changing what the player sees, use the `simulate` option of game.screenshot / --screenshot-simulate "
                    "instead.");

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
               "[0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio.")
        .field("safeArea", &Sprite::safeArea,
               "Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, "
               "rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole "
               "screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps "
               "HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes "
               "nothing. Default false.")
        .field("slice", &Sprite::slice,
               "9-slice borders in texture pixels [left, top, right, bottom], measured inside `region` (or the whole texture). With "
               "a border set the four corners are drawn at their texture size (1 texture pixel = 1 world unit), the edges stretch "
               "along one axis and the centre along both, so one small frame gives a panel, bar or platform of any `size`. "
               "[0, 0, 0, 0] (default) stretches the whole region. Borders that do not fit in `size` shrink together. "
               "Works with atlas-packed textures, flipX / flipY and a lit sprite. Screen-space UI panels use the same slicing "
               "through Panel.texture and Panel.slice.")
        .field("lit", &Sprite::lit,
               "World space only. true: the sprite is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight "
               "(its colour is multiplied by ambient + the sum of the lights); false (default): drawn exactly as the texture "
               "says, whatever lights exist. At most 16 lights shade a frame (see Light2D).")
        .asset_field("normalMap", &Sprite::normalMap, "texture",
                     "Lit sprites only. Tangent-space normal map: RGB = (x, y, z) mapped from 0..1 to -1..1, +x to the right "
                     "and +y UP the picture (OpenGL / Unity convention), laid out exactly like `texture` and `region` (same size). "
                     "It turns with the sprite's rotation and flips. Empty (default) = a flat sprite lit only by distance. "
                     "Ignored unless `lit` is true.");

    r.add<Parallax>("Parallax",
                    "Shifts the drawing of this entity's world-space visuals (Sprite, Shape2D, Text, Tilemap) with the camera so "
                    "far layers slide slower than near ones. Offset = camera position * (1 - factor) per axis: factor 1 behaves "
                    "like any world object, 0 stays glued to the camera (a sky), 0.5 is half as fast (distant hills), above 1 "
                    "is a foreground. With the camera at (0, 0) the entity is exactly where its Transform says. Only the "
                    "drawing moves: Transform, physics and picking positions stay put, while entity.bounds() reports "
                    "where it is drawn. Deterministic: it depends only on the camera position.",
                    "2D")
        .field("factor", &Parallax::factor, "[x, y] fraction of the camera's movement this layer follows (0 = fixed on screen, 1 = a normal world object).")
        .field("repeatX", &Parallax::repeatX,
               "Sprite only. Tile the sprite endlessly left and right (at `repeatSize.x` spacing, or its own width) so a background "
               "strip never runs out. The copies are drawn only where the camera sees them.")
        .field("repeatY", &Parallax::repeatY, "Sprite only. Same as repeatX, up and down.")
        .field("repeatSize", &Parallax::repeatSize,
               "Distance between repeated copies in world units [x, y]. 0 = the sprite's own width / height. Use a smaller value "
               "to overlap soft edges, a larger one for gaps.")
        .field("offset", &Parallax::offset, "Runtime: the shift [x, y] currently applied to the drawing (written by the renderer every frame).")
        .runtime_only().read_only();

    r.add<Light2D>("Light2D",
                   "A light for lit 2D visuals: sprites and tilemaps with `lit` true. Their colour is multiplied by "
                   "SceneSettings.ambientLight plus the light of every Light2D (point: color * intensity * (1 - distance / radius)^falloff, "
                   "scaled by the normal map's angle to the light when the sprite has a normalMap; directional: even light from one "
                   "direction). Unlit visuals ignore lights, so existing games look the same. At most 16 lights shade a frame "
                   "(the same on every graphics backend): directional lights first, then the point lights nearest to the camera. "
                   "The light sits at the entity's position (Transform) and ignores layers.",
                   "2D")
        .enum_field("type", &Light2D::type, {"point", "directional"},
                    "point: a lamp at the entity's position that fades out at `radius`. directional: sun / moon, the same everywhere, "
                    "coming from the opposite of `direction`.")
        .field("color", &Light2D::color, "Light colour. Accepts [r,g,b,a], \"#rrggbb\" or a name (alpha is ignored).")
        .field("intensity", &Light2D::intensity, "Strength: multiplies color. 1 = full colour at the lamp; above 1 over-brightens.").range(0, 100)
        .field("radius", &Light2D::radius, "Point lights: distance in world units at which the light has faded to nothing.").range(0, 100000)
        .field("falloff", &Light2D::falloff, "Point lights: fade curve exponent. 1 = linear, 2 (default) = smooth, higher = a tight bright core.").range(0.01f, 16)
        .field("height", &Light2D::height,
               "Point lights: height above the drawing plane in world units. Only matters for normal-mapped sprites: a low lamp "
               "grazes the surface and shows relief, a high one lights it flatly.").range(0, 100000)
        .field("direction", &Light2D::direction, "Directional lights: degrees the light travels towards (0 = right, 90 = up, 270 = down).")
        .field("elevation", &Light2D::elevation, "Directional lights: angle above the drawing plane in degrees (90 = straight at the picture, 0 = along it).").range(0, 90);

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
        .enum_field("shape", &Shape2D::shape, {"rectangle", "circle", "line", "triangle", "diamond", "polygon", "star"},
                    "Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along "
                    "the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square "
                    "rotated 45 degrees when size is square; handy for gems, enemies and neon markers). polygon: a regular polygon "
                    "with `sides` sides whose vertices lie on the ellipse inscribed in the size box, first vertex pointing up "
                    "(hexagons, pentagons, octagons; many sides approach a circle). star: `points` tips on that ellipse, first tip "
                    "pointing up, with notches at `innerRadius` of the outer radius in between. Outlines (filled = false) of triangle, "
                    "diamond, polygon and star grow INWARD from the silhouette, like the rectangle's, so a thick outline never "
                    "pokes out of the size box.")
        .field("size", &Shape2D::size,
               "rectangle/triangle/diamond/polygon/star: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin.")
        .field("color", &Shape2D::color, "Fill or outline color.")
        .field("filled", &Shape2D::filled, "true = solid shape, false = outline only (lines are always drawn as strokes).")
        .field("thickness", &Shape2D::thickness, "Outline / line thickness in world units.").range(0, 10000)
        .field("layer", &Shape2D::layer, "Draw order. Higher layers draw on top.")
        .enum_field("space", &Shape2D::space, {"world", "screen"},
                    "world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down.")
        .field("pivot", &Shape2D::pivot,
               "Anchor point within the shape's size box for every shape but line: [0.5,0.5] = the box centre sits "
               "on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and "
               "scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a "
               "triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the "
               "bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle "
               "around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place.")
        .enum_field("blend", &Shape2D::blend, {"alpha", "additive", "multiply"},
                    "Compositing: alpha (normal), additive (glow/neon), multiply (darken).")
        .field("anchor", &Shape2D::anchor,
               "Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right).")
        .field("safeArea", &Shape2D::safeArea,
               "Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, "
               "rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole "
               "screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps "
               "HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes "
               "nothing. Default false.")
        .field("sides", &Shape2D::sides, "polygon only: number of sides (3 = triangle, 6 = hexagon, 8 = octagon).").range(3, 64)
        .field("points", &Shape2D::points, "star only: number of tips (5 = the classic star).").range(3, 64)
        .field("innerRadius", &Shape2D::innerRadius,
               "star only: radius of the notches between the tips as a fraction of the outer radius. 0.5 = classic star, "
               "near 1 = a fat spiky polygon, near 0 = thin needles.").range(0, 1)
        .field("lit", &Shape2D::lit,
               "World space only. true: the shape is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight "
               "(its colour is multiplied by ambient + the sum of the lights), like Sprite.lit, so a dark level can use shapes "
               "for platforms and hazards; every shape type, outlines and lines included, is flat (no normal map). false "
               "(default): drawn exactly in `color`, whatever lights exist. At most 16 lights shade a frame (see Light2D).");

    r.add<Text>("Text",
                "Draws a string with a TrueType font (or the built-in font). Works in world and screen space.",
                "2D")
        .field("text", &Text::text,
               "The string to draw. Use \\n for line breaks. While `key` is set the engine overwrites it with the translation of the "
               "current language every frame: edit the string table (locales/<language>.json), not this field.")
        .field("key", &Text::key,
               "Localization key, e.g. \"menu.play\" (docs/LOCALIZATION.md). Empty (default) = this Text is not translated. With a key, the "
               "runtime writes the string of that key in the current language (locales/<language>.json, falling back to the base "
               "language and then to localization.defaultLanguage) into `text` when a scene or prefab loads, every frame and "
               "when the language changes, so `text` is overwritten at run time. A key that no string table has keeps the "
               "text written here and logs one warning.")
        .asset_field("font", &Text::font, "font",
                     "Project-relative path of a .ttf font. Empty uses the built-in font, DejaVu Sans (Latin, Greek, "
                     "Cyrillic, Hebrew, Arabic); \"builtin:pixel\" is Press Start 2P. Characters the font has no glyph for draw as nothing "
                     "and log one warning per font: Chinese, Japanese and Korean need a .ttf that covers them (e.g. Noto "
                     "Sans SC, JP or KR). Keep this empty and list the extra fonts in factoria.json (localization.fallbackFonts, "
                     "localization.languageFonts) to cover every Text of the game (docs/TEXT.md).")
        .field("fontSize", &Text::fontSize, "Glyph height in world units (pixels in 2D).").range(1, 4096)
        .field("color", &Text::color, "Text color.")
        .enum_field("align", &Text::align, {"left", "center", "right", "start", "end"},
                    "Horizontal alignment of lines inside the text box. left / right are always the left / right edge, "
                    "even for right-to-left text. start / end follow the current language: start = left and end = right "
                    "in a left-to-right language, start = right and end = left in Arabic, Hebrew and the other right-to-left "
                    "languages (i18n.direction); use them for text that must read from its start side.")
        .field("pivot", &Text::pivot, "Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right.")
        .field("maxWidth", &Text::maxWidth, "If > 0, lines wrap at this width in world units. 0 = no wrapping. With autoShrink "
               "it is also the width the text must fit (a word longer than the box shrinks the font).").range(0, 100000)
        .field("maxHeight", &Text::maxHeight,
               "Box height in the same units as maxWidth that autoShrink fits the text into: a card title with maxWidth 200 and "
               "maxHeight 30 stays on one line at any text size by shrinking. 0 (default) = only the width counts. Nothing is "
               "clipped or wrapped by it; it only drives autoShrink and ui.overflowed(id).").range(0, 100000)
        .field("autoShrink", &Text::autoShrink, kAutoShrinkDoc)
        .field("minFontSize", &Text::minFontSize, kMinFontSizeDoc).range(1, 4096)
        .field("maxTextScale", &Text::maxTextScale, kMaxTextScaleDoc).range(0, 3)
        .field("layer", &Text::layer, "Draw order. Higher layers draw on top. Text defaults above sprites.")
        .enum_field("space", &Text::space, {"world", "screen"},
                    "world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down.")
        .field("anchor", &Text::anchor,
               "Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, "
               "[0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + "
               "position [-20, 20] = right-aligned 20px from the top-right corner.")
        .field("safeArea", &Text::safeArea,
               "Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, "
               "rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole "
               "screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps "
               "HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes "
               "nothing. Default false.");

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
               "Tile values, row-major with row 0 at the TOP: either a flat array of width*height integers (set width "
               "and height) or an array of rows (the size comes from the rows). -1 = empty. A value is the tileset index, "
               "optionally plus flags that mirror or turn that tile when drawn: 268435456 flips it left-right (flipX), "
               "536870912 top-bottom (flipY), 1073741824 mirrors it across the diagonal (transpose). The image is transposed "
               "first, then flipped in x, then in y; a 90 degree clockwise turn is transpose + flipX = 1342177280 + index, "
               "180 is flipX + flipY = 805306368 + index, 90 counter-clockwise is transpose + flipY = 1610612736 + index. "
               "scene.import_ascii legends write these for you: {\"tile\": 3, \"rotate\": 90, \"flipX\": true}.")
        .field("solidTiles", &Tilemap::solidTiles,
               "List of plain tile indices (no flip flags) that block movement; static colliders are generated for them. A "
               "flipped or rotated copy of a solid tile is still solid. Empty = nothing collides.")
        .field("color", &Tilemap::color, "Tint multiplied with the tileset.")
        .field("layer", &Tilemap::layer, "Draw order. Defaults below sprites (-10).")
        .field("lit", &Tilemap::lit,
               "true: the tiles are shaded by the Light2D entities and SceneSettings.ambientLight, like Sprite.lit. Default false.")
        .asset_field("normalMap", &Tilemap::normalMap, "texture",
                     "Lit tilemaps only. Normal map image laid out exactly like the tileset (same size, same tile positions); "
                     "flipped and rotated tiles turn their normals with them. Empty = flat tiles.");

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
               "burst > 0 and emitting = false for one-shot effects (explosions, pickups).")
        .enum_field("space", &ParticleEmitter::space, {"world", "screen"},
                    "world: affected by cameras. screen: HUD/UI effects (menu sparks, score bursts) in design pixels, origin "
                    "TOP-LEFT, +Y down, unaffected by cameras and drawn in the screen-space pass (so with Camera.bloomScreenSpace "
                    "= false they are not bloomed). direction, gravity and speed keep their world meaning on screen: 90 = up, "
                    "negative gravity y falls down the screen. Ignored (treated as world) when is3D is true.")
        .field("anchor", &ParticleEmitter::anchor,
               "Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0.5] "
               "center, [1,1] bottom-right).")
        .field("safeArea", &ParticleEmitter::safeArea,
               "Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, "
               "rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole "
               "screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps "
               "HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes "
               "nothing. Default false.");

    // --------------------------------------------------------------- 3D ---
    r.add<MeshRenderer>("MeshRenderer",
                        "Draws a 3D mesh with a PBR material (GGX highlights, sky reflections, normal maps; glTF materials are read). Needs a perspective Camera and (unless unlit) "
                        "a Light to be visible.",
                        "3D")
        .field("mesh", &MeshRenderer::mesh,
               "Built-in shape name (\"cube\", \"sphere\", \"plane\", \"cylinder\", \"capsule\", \"cone\", \"quad\") or a "
               "project-relative path to a .gltf/.glb model (e.g. \"assets/models/ship.glb\").")
        .asset_field("texture", &MeshRenderer::texture, "texture", "Base color texture. Empty = none (or the glTF material).")
        .asset_field("normalMap", &MeshRenderer::normalMap, "texture",
                     "Tangent-space normal map (glTF convention: +Y up, the usual blue-ish image) that adds small-scale relief "
                     "without more triangles. Empty = none (or the glTF material's normalTexture). Replaces the glTF one when set.")
        .field("normalScale", &MeshRenderer::normalScale, "How strong the normal map is: 0 = flat, 1 = as authored.").range(0, 4)
        .field("color", &MeshRenderer::color, "Base color, multiplied with the texture.")
        .field("metallic", &MeshRenderer::metallic,
               "0 = plastic/stone, 1 = metal. glTF models use their own metallic value and metallicRoughnessTexture instead.").range(0, 1)
        .field("roughness", &MeshRenderer::roughness,
               "0 = mirror-smooth, 1 = fully rough/matte. glTF models use their own roughness and metallicRoughnessTexture instead.").range(0, 1)
        .field("emissive", &MeshRenderer::emissive, "Light emitted by the surface regardless of lighting (glow). Black = none.")
        .field("unlit", &MeshRenderer::unlit, "true = ignore lighting and draw the flat base color.")
        .field("castShadows", &MeshRenderer::castShadows, "Cast shadows from shadow-casting lights.")
        .field("receiveShadows", &MeshRenderer::receiveShadows, "Receive shadows from shadow-casting lights.")
        .field("uvScale", &MeshRenderer::uvScale, "Texture tiling [u, v]; 2 repeats the texture twice.")
        .asset_field("material", &MeshRenderer::material, "material",
                     "Project-relative path of a custom material, a *.material.json file (e.g. \"materials/water.material.json\"), "
                     "or \"\" (default) for the standard PBR material. The material file names a GLSL snippet whose surface() "
                     "changes what the standard material computed (albedo, alpha, normal, emission...) and whose optional vertex() "
                     "moves the vertices, and declares its params, textures, lighting (pbr or unlit) and alphaMode (opaque, clip "
                     "or blend). The `material.info` command lists a material's params and textures; `shader.compile` compiles it "
                     "and reports errors with file:line. The material's alphaMode wins over color.a < 1; `unlit` true forces "
                     "unlit lighting. A material that does not compile draws magenta and logs why. Guide with worked examples: "
                     "docs/SHADERS.md (`factoria docs read shaders`).")
        .field("materialParams", &MeshRenderer::materialParams,
               "Per-entity overrides of the material's params and textures, as an object keyed by the name declared in the "
               "material file: numbers for float params, arrays for vectors and colors ([r, g, b, a]), project-relative paths "
               "for textures. Example: {\"glow\": [1, 0.2, 0, 1], \"mask\": \"textures/leaf.png\"}. Unnamed params keep the "
               "material's defaults. An entity without overrides batches with the others that share the material.");

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

    r.add<Animator>("Animator",
                    "Plays the skeletal animation clips of a skinned glTF model (the model of the MeshRenderer on the same "
                    "entity, or `model`): one clip at a time with cross-fades, clip events, and an optional small state "
                    "machine (`params`, `states`, `transitions`). It runs in the fixed step, so headless runs and replays "
                    "match. Scripts: entity.animator.play(\"Run\", 0.2), .set(\"speed\", 3), .stop(); events reach "
                    "world.on(name, ...).",
                    "3D")
        .field("model", &Animator::model,
               "Project-relative .gltf/.glb path with the skin and the clips. Empty = the `mesh` of the MeshRenderer on "
               "the same entity (usual case: leave it empty).")
        .field("clip", &Animator::clip,
               "Name of the glTF animation playing now (see entity.animator.clips). Assigning it at run time switches "
               "clips with a cross-fade of `fade` seconds. Empty = bind pose (the model as exported).")
        .field("speed", &Animator::speed, "Playback speed multiplier: 1 = authored speed, 2 = twice as fast, 0 = frozen.").range(0, 100)
        .field("loop", &Animator::loop,
               "true = start over when the clip ends. false = stop on the last pose and send the `anim.finished` event.")
        .field("playing", &Animator::playing, "Set false to pause, true to play.")
        .field("fade", &Animator::fade, "Cross-fade seconds used when `clip` is changed by assignment (play() takes its own).").range(0, 60)
        .field("params", &Animator::params,
               "State machine parameters and their start values, an object such as {\"speed\": 0, \"grounded\": true}. "
               "Numbers and booleans. Scripts change them with animator.set(name, value); transitions read them.")
        .field("states", &Animator::states,
               "State machine states, an object name -> {clip, loop (default true), speed (default 1), onEnter}. "
               "`onEnter` is the name of a game event sent when the state starts (world.on). Example: "
               "{\"idle\": {\"clip\": \"Idle\"}, \"run\": {\"clip\": \"Run\", \"onEnter\": \"started_running\"}}.")
        .field("transitions", &Animator::transitions,
               "State machine transitions, an array checked in order every step; the first that matches fires. Each: "
               "{from (a state, or \"*\"/omitted = any), to, when, fade (seconds, default 0.2), onFinish}. `when` is "
               "conditions joined by \"&&\": `speed > 0.1`, `grounded`, `!grounded`, `hp <= 0` (operators > >= < <= == !=). "
               "A parameter set with animator.trigger(name) is true for one step. onFinish: true fires when the current "
               "non-looping clip ended (alone or together with `when`).")
        .field("events", &Animator::events,
               "Clip events, an array of {clip, time, name}: when the clip's time passes `time` (seconds) the game event "
               "`name` is sent once per loop, with data {id, clip, time}; listen with world.on(name, fn). "
               "Example: [{\"clip\": \"Walk\", \"time\": 0.3, \"name\": \"footstep\"}].")
        .field("state", &Animator::state,
               "State machine: the state the animator is in (the start state when set in the scene; empty = the first "
               "state of `states`). Updated as transitions fire.")
        .field("time", &Animator::time, "Runtime state: seconds into the current clip. Assigning it seeks (no events fire).").runtime_only()
        .field("values", &Animator::values, "Runtime state: current value of every state machine parameter.").runtime_only();

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

    r.add<Joint2D>("Joint2D",
                   "A Box2D joint on this entity's body: revolute (a hinge / pendulum / wheel axle), distance (a rope or spring "
                   "of fixed length), prismatic (a slider along an axis) or weld (glue two bodies together). Both this entity "
                   "and `connected` need a RigidBody2D (or a Collider2D, which makes a static body); leave `connected` empty to "
                   "pin to the world. Lengths and anchors are world units (pixels), angles degrees; created when the entity "
                   "is, destroyed with either body or when the component is removed. Changing type, connected, anchors, axis or "
                   "collideConnected rebuilds the joint; limits, motor, spring and length apply live, so scripts can toggle a motor. "
                   "Positive angle, motor speed and translation move THIS entity counter-clockwise / along +axis relative to "
                   "`connected` (the axis is in the connected body's frame, the world's when empty). Reaction force, angle and translation are read-only runtime fields.",
                   "Physics")
        .enum_field("type", &Joint2D::type, {"revolute", "distance", "prismatic", "weld"},
                    "revolute: the bodies share the anchor point and may turn around it. distance: the anchors stay `length` apart "
                    "(a spring when enableSpring). prismatic: the anchor slides along `axis` and the bodies cannot turn relative "
                    "to each other. weld: the bodies stay rigidly together (soft with springHertz > 0).")
        .field("connected", &Joint2D::connected,
               "Id of the other entity (it needs a body). Empty (leave it out, null or \"\") = the joint is fixed to the world and connectedAnchor is a world position.")
        .field("anchor", &Joint2D::anchor, "Joint point [x, y] in THIS entity's local space (scaled by Transform.scale), world units from its origin.")
        .field("connectedAnchor", &Joint2D::connectedAnchor,
               "Joint point [x, y] in the connected entity's local space; a world position when `connected` is empty. For a hinge "
               "both anchors name the same spot in the world when the joint is created.")
        .field("axis", &Joint2D::axis, "Prismatic only: slide direction [x, y] in this entity's local space; normalised. [1, 0] slides along local x.")
        .field("collideConnected", &Joint2D::collideConnected, "true: the two joined bodies still collide with each other (default false).")
        .field("length", &Joint2D::length, "Distance only: rest length in world units. 0 = the distance between the anchors when the joint is created.").range(0, 1000000)
        .field("enableLimit", &Joint2D::enableLimit, "Limit the motion: revolute angle, prismatic translation, or distance length (needs enableSpring to stretch).")
        .field("lowerLimit", &Joint2D::lowerLimit,
               "Lower limit: revolute degrees (between -178 and 178, 0 = the pose at creation), prismatic translation in world units "
               "(0 = anchors coincide), distance minimum length in world units.")
        .field("upperLimit", &Joint2D::upperLimit, "Upper limit, same units as lowerLimit.")
        .field("enableMotor", &Joint2D::enableMotor,
               "Drive the joint at motorSpeed with at most maxMotorTorque. Revolute and prismatic; a distance joint motor works only with enableSpring.")
        .field("motorSpeed", &Joint2D::motorSpeed, "Target speed: revolute degrees per second (positive = counter-clockwise), prismatic / distance world units per second.")
        .field("maxMotorTorque", &Joint2D::maxMotorTorque,
               "Strongest push the motor may apply: a torque for a revolute joint, a force for prismatic and distance joints (the same units as "
               "physics.applyForce). 0 = the motor does nothing.").range(0, 1e12f)
        .field("enableSpring", &Joint2D::enableSpring,
               "Revolute, prismatic, distance: make the free motion springy, pulling towards the rest pose (angle 0, translation 0, `length`).")
        .field("springHertz", &Joint2D::springHertz,
               "Spring stiffness in cycles per second (about 1 = a slow bounce, 5 = stiff). Weld joints: 0 = rigid, above 0 = a soft weld "
               "(no enableSpring needed).").range(0, 1000)
        .field("dampingRatio", &Joint2D::dampingRatio, "Spring damping: 0 = bounces on, 1 = settles without overshoot.").range(0, 100)
        .field("reactionForce", &Joint2D::reactionForce,
               "Runtime: the force [x, y] the joint applied last step to hold the bodies (same units as physics.applyForce). Compare it with a limit to break a rope.")
        .runtime_only().read_only()
        .field("reactionTorque", &Joint2D::reactionTorque, "Runtime: the torque the joint applied last step.").runtime_only().read_only()
        .field("angle", &Joint2D::angle, "Runtime: revolute and weld: the current joint angle in degrees (0 = the pose at creation).")
        .runtime_only().read_only()
        .field("translation", &Joint2D::translation, "Runtime: prismatic: the current slide position; distance: the current length, in world units.")
        .runtime_only().read_only();

    r.add<RigidBody3D>("RigidBody3D",
                       "Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a "
                       "triangle-mesh collider is for static level geometry only). Pair it with a Collider3D; add a "
                       "Joint3D to hinge it to the world or to another body. A capsule body with lockRotation is a "
                       "simple physics character (for a controller that slides, climbs steps and checks slopes use "
                       "CharacterController3D instead). "
                       "Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider "
                       "(continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply "
                       "torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles "
                       "and settles on a face; set lockRotation for a character or an upright crate. A sphere is an "
                       "arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never "
                       "turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins "
                       "it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body "
                       "that stays nearly still for half a second falls asleep together with the bodies it touches (no "
                       "cost, no events) and wakes when touched by something moving, when gameplay writes its position, "
                       "rotation or velocity, applies a force, or when what it rests on goes away.",
                       "Physics")
        .enum_field("type", &RigidBody3D::type, {"static", "dynamic", "kinematic"},
                    "static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform.")
        .field("mass", &RigidBody3D::mass, "Mass in kilograms (affects collision responses between dynamic bodies).").range(0.0001f, 1000000)
        .field("gravityScale", &RigidBody3D::gravityScale, "Multiplier on world gravity.")
        .field("linearDamping", &RigidBody3D::linearDamping, "Air resistance; 0 = none.").range(0, 1000)
        .field("velocity", &RigidBody3D::velocity, "Linear velocity [x, y, z] in meters per second. Read/write.")
        .field("angularVelocity", &RigidBody3D::angularVelocity,
               "Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step. Read/write "
               "(writing it wakes a sleeping body). A box spinning about a non-principal axis keeps its angular "
               "momentum, so this vector wanders (precession) while it tumbles.")
        .field("rollWithMotion", &RigidBody3D::rollWithMotion,
               "Sphere colliders only. true (default, arcade ball): while it touches the ground the sphere is spun to "
               "match its rolling motion (sets angularVelocity from the horizontal velocity) and uses rolling "
               "resistance (rollingFriction) instead of sliding friction; contacts never turn it, so setting velocity "
               "every frame steers it exactly. false: the sphere is a rigid body (solid-sphere inertia 2/5 m r^2): "
               "friction at the contact point spins it, so on a slope it rolls (spin = speed / radius) and a glancing "
               "hit makes it spin; on flat ground it keeps rolling until angularDamping / linearDamping or an obstacle "
               "stops it. Add lockRotation for a ball that slides and is never spun by contacts.")
        .field("rollingFriction", &RigidBody3D::rollingFriction,
               "Rolling resistance of a dynamic sphere with rollWithMotion = true: friction cap = rollingFriction * normal "
               "force, replacing the sliding friction of its contacts, so on flat ground its speed decays by about "
               "rollingFriction * gravity per second (default 0.02 rolls about 23 m from 3 m/s; 0 never slows down). Ignored "
               "when rollWithMotion is false (then Collider3D.friction acts at the contact point of the rigid sphere) and "
               "for boxes.").range(0, 10)
        .field("angularDamping", &RigidBody3D::angularDamping,
               "Rotation drag of a dynamic body: angularVelocity is divided by (1 + dt * angularDamping) every step, so "
               "0 = a spinning body keeps spinning in the air, larger values slow it down faster.").range(0, 1000)
        .field("lockRotation", &RigidBody3D::lockRotation,
               "true = collisions and friction never turn this body (a dynamic box, or a sphere with rollWithMotion = "
               "false): it stays upright and slides, as boxes did before rotation dynamics. Use it for characters and "
               "upright crates. angularVelocity and Transform.rotation written by gameplay still turn it. A "
               "rollWithMotion sphere is never turned by contacts either way.");

    r.add<Collider3D>("Collider3D",
                      "Collision shape for 3D physics: box, sphere, capsule, convex hull or triangle mesh. Boxes, capsules "
                      "and meshes are ORIENTED: they follow the entity's world rotation (parents included), so a box "
                      "rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale. A `mesh` collider is "
                      "for level geometry and needs a static body (no RigidBody3D, or type static): a dynamic or "
                      "kinematic body with one is reported as an error and ignored.",
                      "Physics")
        .enum_field("shape", &Collider3D::shape, {"box", "sphere", "capsule", "convex", "mesh"},
                    "box: uses size. sphere: uses radius. capsule: uses radius and height, along the entity's local Y. "
                    "convex: the convex hull of the vertices of `mesh` (any dynamic body, fast). mesh: the triangles of "
                    "`mesh` (static level geometry only; concave shapes, ramps, terrain).")
        .field("size", &Collider3D::size,
               "box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale.")
        .field("radius", &Collider3D::radius, "sphere and capsule: radius in meters.")
        .field("height", &Collider3D::height,
               "capsule: full height in meters from tip to tip along the entity's local Y (so the straight part is "
               "height - 2 * radius; never less than 2 * radius).").range(0.002f, 100000)
        .field("mesh", &Collider3D::mesh,
               "convex / mesh shapes: a built-in primitive name (\"cube\", \"sphere\", \"plane\", \"cylinder\", "
               "\"capsule\", \"cone\", \"quad\", the same sizes as MeshRenderer) or a project-relative path to a "
               ".gltf/.glb model (every mesh node of the file, with its node transform). Use the same value as the "
               "MeshRenderer so the collider matches what is drawn.")
        .field("offset", &Collider3D::offset,
               "Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity (for convex and "
               "mesh: where the model's own origin sits).")
        .field("isTrigger", &Collider3D::isTrigger, "true = sensor: reports overlaps but does not block movement.")
        .field("friction", &Collider3D::friction, "Surface friction; 0 = ice, 1 = grippy.").range(0, 10)
        .field("restitution", &Collider3D::restitution, "Bounciness: 0 = none, 1 = perfectly elastic.").range(0, 1)
        .field("layer", &Collider3D::layer, "Collision category of this collider, 0..31.").range(0, 31)
        .field("mask", &Collider3D::mask, "Bitmask of layers this collider collides with. -1 = all layers.")
        .field("navObstacle", &Collider3D::navObstacle,
               "true = a NavMesh3D does not bake this collider into the ground (a crate, a gate, a door that moves): "
               "it blocks the navigation cells it covers, plus the agent's radius, wherever it is NOW, and the "
               "affected cells are marked again each time it moves, so nav.findPath goes around it. Use it on anything "
               "that moves or is removed during play; static level geometry needs nothing.");

    r.add<Joint3D>("Joint3D",
                   "Joins this entity's RigidBody3D to another body or to the world: a hinge (door, pendulum, wheel), a "
                   "ball joint (rope link, ragdoll shoulder) or a fixed joint (welds the two bodies). Solved together "
                   "with the contacts. Put it on the body that swings; set `connected` to the other entity (empty = the "
                   "world). A jointed dynamic body is always a rotating rigid body. Bodies joined together fall asleep "
                   "together once the whole chain is at rest (a motor keeps its bodies awake), so a settled rope bridge "
                   "costs nothing. A chain of three or more jointed bodies is solved with extra iterations, so planks "
                   "of any width hang still without heavy damping. The joint holds the pose the bodies have when it is "
                   "created (autoAnchor); hinge limits are angles relative to that pose.",
                   "Physics")
        .enum_field("type", &Joint3D::type, {"hinge", "ball", "fixed"},
                    "hinge: rotation about `axis` only. ball: free rotation about the anchor point. fixed: no relative "
                    "movement at all.")
        .field("connected", &Joint3D::connected,
               "The other body's entity id. Empty (leave it out, null or \"\") = the world: the anchor point stays "
               "where it is. The entity needs a RigidBody3D (any type) or a Collider3D.")
        .field("anchor", &Joint3D::anchor,
               "Joint point [x, y, z] in THIS entity's local space (scaled and rotated with it): the pendulum's pivot, "
               "the door's hinge edge.")
        .field("connectedAnchor", &Joint3D::connectedAnchor,
               "Joint point in the connected entity's local space, or a world position when `connected` is empty. "
               "Ignored while autoAnchor is true.")
        .field("autoAnchor", &Joint3D::autoAnchor,
               "true (default): connectedAnchor is computed from `anchor` when the joint is created, so the bodies stay "
               "joined exactly where they are. false: use connectedAnchor as given (the bodies are pulled together).")
        .field("axis", &Joint3D::axis, "hinge: the rotation axis [x, y, z] in THIS entity's local space (normalized).")
        .field("useLimits", &Joint3D::useLimits, "hinge: keep the angle between lowerLimit and upperLimit.")
        .field("lowerLimit", &Joint3D::lowerLimit,
               "hinge: lowest angle in degrees, relative to the pose the joint was created in (0 there).").range(-360, 360)
        .field("upperLimit", &Joint3D::upperLimit, "hinge: highest angle in degrees (same reference).").range(-360, 360)
        .field("useMotor", &Joint3D::useMotor, "hinge: drive the joint at motorSpeed (a wheel, an opening door).")
        .field("motorSpeed", &Joint3D::motorSpeed,
               "hinge motor: target speed in degrees/second of this body relative to the connected one, about the axis.")
        .field("maxMotorTorque", &Joint3D::maxMotorTorque,
               "hinge motor: the most torque in newton-meters the motor may apply; a heavy or loaded body needs more.")
        .range(0, 1000000)
        .field("collideConnected", &Joint3D::collideConnected,
               "false (default): the two joined bodies do not collide with each other. true: they do.")
        .field("damping", &Joint3D::damping,
               "Resistance to the two bodies turning relative to each other, per second: each physics sub-step the "
               "relative angular velocity (about the axis for a hinge, every axis for a ball joint) is divided by "
               "1 + damping * dt. 0 (default) = free; 1 takes the swing out of a door in a few seconds; 2..5 stops a "
               "rope-bridge plank ringing. A chain of 3+ bodies already settles without it.")
        .range(0, 1000)
        .field("angle", &Joint3D::angle, "Runtime: the current hinge angle in degrees, relative to the creation pose.")
        .runtime_only()
        .read_only()
        .field("stalled", &Joint3D::stalled,
               "Runtime, read only: true while a motor (useMotor with a non-zero motorSpeed) cannot turn the joint: the "
               "relative speed stayed below a tenth of motorSpeed for a quarter of a second, e.g. a gate pushing against "
               "a wall, or a maxMotorTorque too low for the load. False when the hinge simply reached its limit. "
               "Scripts read it to open another way or raise the torque.")
        .runtime_only()
        .read_only();

    r.add<CharacterController3D>("CharacterController3D",
                                 "A walking character: a kinematic capsule that moves and slides. Move it with "
                                 "physics.moveCharacter(entity, [dx, dy, dz]) (Unity-style: you add gravity and jumping to "
                                 "the move yourself, using isGrounded) or set `velocity`. It slides along walls and "
                                 "ceilings, climbs steps up to stepOffset, will not climb slopes steeper than slopeLimit "
                                 "(it slides down them), stays on the ground going down ramps, is carried by the kinematic "
                                 "platform it stands on (carriedByPlatforms), weighs on the dynamic body below it "
                                 "(applyWeight, mass: a seesaw tips) and pushes the free dynamic bodies it walks into "
                                 "(pushStrength). Other bodies treat it as a kinematic capsule. The entity origin is the capsule "
                                 "centre (plus `center`). Do not add RigidBody3D or Collider3D to the same entity.",
                                 "Physics")
        .field("radius", &CharacterController3D::radius, "Capsule radius in meters (scaled by Transform.scale).").range(0.01f, 100)
        .field("height", &CharacterController3D::height,
               "Capsule height in meters from tip to tip (never less than 2 * radius).").range(0.02f, 1000)
        .field("center", &CharacterController3D::center, "Capsule centre [x, y, z] from the entity origin, in meters.")
        .field("stepOffset", &CharacterController3D::stepOffset,
               "Highest step in meters the character walks up (and the distance it snaps down to stay on the ground).")
        .range(0, 10)
        .field("slopeLimit", &CharacterController3D::slopeLimit,
               "Steepest slope in degrees the character can walk up; steeper surfaces count as walls.").range(0, 89)
        .field("skin", &CharacterController3D::skin,
               "Gap in meters kept between the capsule and the surfaces it touches; avoids jitter and tunnelling.")
        .range(0.001f, 1)
        .field("layer", &CharacterController3D::layer, "Collision category of the character, 0..31.").range(0, 31)
        .field("mask", &CharacterController3D::mask, "Bitmask of layers the character collides with. -1 = all layers.")
        .field("velocity", &CharacterController3D::velocity,
               "Velocity in meters/second [x, y, z]: when not zero the character moves by velocity * dt every physics "
               "step (no gravity is added). Use it or moveCharacter, not both for the same motion.")
        .field("carriedByPlatforms", &CharacterController3D::carriedByPlatforms,
               "When true (default) a kinematic RigidBody3D the character stands on carries it: every physics step it moves "
               "with the platform's displacement (velocity, or a teleport by script) and turns about the platform's centre "
               "with its angularVelocity (the character also yaws with it). Set false and it stays where it is, so a "
               "moving platform slides out from under it and the script must carry it.")
        .field("applyWeight", &CharacterController3D::applyWeight,
               "When true (default) a character standing on a dynamic RigidBody3D presses on it with mass * gravity at "
               "its feet, every physics step: a seesaw tips towards the side it stands on, a bridge plank or a crate "
               "feels the load. Set false for a character that weighs nothing.")
        .field("mass", &CharacterController3D::mass,
               "Weight in kilograms pressed on the dynamic body below when applyWeight is on (see applyWeight).")
        .range(0, 100000)
        .field("pushStrength", &CharacterController3D::pushStrength,
               "How hard the character shoves the free dynamic bodies it walks into: 1 (default) gives them its own "
               "speed, 0.5 half of it, 0 none (they block it like a wall). A body held by a Joint3D (a seesaw on its "
               "pivot, a bridge plank, a door) is never shoved whatever the value.")
        .range(0, 10)
        .field("isGrounded", &CharacterController3D::isGrounded,
               "Runtime: true when the last move ended standing on walkable ground (slope up to slopeLimit).")
        .runtime_only()
        .read_only()
        .field("groundNormal", &CharacterController3D::groundNormal,
               "Runtime: the normal of the ground under the character after the last move (up when airborne).")
        .runtime_only()
        .read_only();

    r.add<NavMesh3D>("NavMesh3D",
                     "A navigation mesh for path finding on 3D ground. It is baked from the STATIC colliders (no "
                     "RigidBody3D, or a static one) inside a box around this entity, when the scene loads (autoBake) or "
                     "with the nav.bake command: the box is cut into cells of cellSize; a cell is walkable where the "
                     "ground is not steeper than maxSlope, has agentHeight of free space above it and lies at least "
                     "agentRadius from a wall or a drop; neighbouring cells connect when their heights differ by at most "
                     "stepHeight. Then nav.findPath(from, to) in scripts (the nav.find_path command) returns the "
                     "points of a path over it. A collider with Collider3D.navObstacle is not baked: it blocks the cells "
                     "it covers while it is there. The mesh is deterministic: the same colliders always give the same "
                     "cells. See docs/NAVIGATION.md.",
                     "Physics")
        .field("size", &NavMesh3D::size,
               "Size [x, y, z] in meters of the baked box, centred on the entity's world position; rotation and scale "
               "are ignored. Cover the whole level: ground outside is not walkable and the box edge counts as a drop. "
               "y must reach from below the lowest floor to above the highest head.")
        .field("cellSize", &NavMesh3D::cellSize,
               "Width of one cell on the ground plane, meters. Smaller = finer paths, more memory and a slower bake "
               "(cells = x/cellSize * z/cellSize, at most 4 million). Walls thinner than half a cell can be missed.")
        .range(0.05f, 10)
        .field("cellHeight", &NavMesh3D::cellHeight,
               "Heights are rounded to a multiple of this, meters; a path is up to half of it above or below the true "
               "surface. Keep it at most stepHeight / 4.").range(0.01f, 5)
        .field("agentRadius", &NavMesh3D::agentRadius,
               "Radius in meters of the walker the mesh is made for: walkable cells stay this far from walls and "
               "drops, so a body of that radius never touches them. findPath with a bigger radius is an error (bake "
               "another NavMesh3D for the bigger agent).").range(0, 10)
        .field("agentHeight", &NavMesh3D::agentHeight,
               "Height in meters of the walker; ground with less free space above it (under a low ceiling or table) is "
               "not walkable.").range(0.1f, 50)
        .field("stepHeight", &NavMesh3D::stepHeight,
               "Highest step in meters the walker climbs; a higher ledge is a wall. Match CharacterController3D.stepOffset.")
        .range(0, 10)
        .field("maxSlope", &NavMesh3D::maxSlope,
               "Steepest walkable ground in degrees; steeper ground is a wall. Match CharacterController3D.slopeLimit.")
        .range(0, 89)
        .field("autoBake", &NavMesh3D::autoBake,
               "true (default): bake when the scene loads and again when a static collider is added, moved or removed. "
               "false: only the nav.bake command bakes (and a scene without a bake has no paths).")
        .field("enabled", &NavMesh3D::enabled, "false = nav.findPath ignores this mesh (and it is not baked).")
        .field("walkableCells", &NavMesh3D::walkableCells,
               "Runtime: how many cells can be walked on after the last bake (read only).")
        .runtime_only()
        .read_only()
        .field("regions", &NavMesh3D::regions,
               "Runtime: how many separate walkable areas the last bake found; two points in different areas have no "
               "path (read only).")
        .runtime_only()
        .read_only();

    // ------------------------------------------------------------ Audio ---
    r.add<AudioSource>("AudioSource",
                       "Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` "
                       "from a script to trigger it.",
                       "Audio")
        .asset_field("clip", &AudioSource::clip, "audio", "Project-relative path of the sound (.wav, .ogg, .mp3 or .qoa).")
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

    // --------------------------------------------------------------- UI ---
    {
        auto panel = r.add<Panel>("Panel",
                  "Container widget: a background rectangle (solid or 9-slice) whose children are laid out in a row, a column or a "
                  "grid. Children are ordinary entities parented to it (Button, Toggle, Slider, TextField, Text, other "
                  "Panels...). Every UI widget is SCREEN SPACE only (design pixels, origin top-left, +Y down; no `space` "
                  "field); rotation and scale of UI entities are ignored by layout and hit-testing. Widgets draw above "
                  "the world and above HUD Text; events (ui.click, ui.change...) and focus are in docs/SCRIPTING.md.",
                  "UI");
        ui_box_fields(panel)
            .enum_field("layout", &Panel::layout, {"none", "row", "column", "grid"},
                        "How children are placed, every frame: none = they keep their own positions; row / column = one after "
                        "the other along that axis; grid = `columns` per row, every cell as large as the largest child. "
                        "Children are the active child entities that have a size (a widget, or a Text / Sprite / Shape2D in "
                        "screen space); the rest are skipped. A child's own position, anchor and pivot do not matter: layout "
                        "moves its Transform.position so it lands in its slot.")
            .field("spacing", &Panel::spacing, "Gap in design pixels between children (a grid uses it on both axes).").range(0, 10000)
            .field("padding", &Panel::padding, "Space [left, top, right, bottom] between the panel's edge and its children.")
            .field("columns", &Panel::columns, "Grid only: number of columns.").range(1, 64)
            .enum_field("align", &Panel::align, {"start", "center", "end"},
                        "Cross-axis alignment: horizontal in a column, vertical in a row, both axes inside a grid cell. start = "
                        "left / top, end = right / bottom (a panel with `direction` rtl, or auto in a right-to-left language, swaps left and "
                        "right: start = right).")
            .enum_field("justify", &Panel::justify, {"start", "center", "end"},
                        "Main-axis placement of the whole run of children inside the padded box: start = packed at the "
                        "left / top, center, end = packed at the right / bottom (with a right-to-left `direction`, start = the right edge). "
                        "A grid is placed as one block on both axes.")
            .enum_field("direction", &Panel::direction, {"ltr", "auto", "rtl"},
                        "Horizontal reading direction of the layout. ltr (default) = a row runs left to right and start means "
                        "left. rtl = the first child of a row is at the right, a grid fills its columns from the right and "
                        "align / justify `start` means the right edge. auto = ltr in a left-to-right language and rtl in Arabic, "
                        "Hebrew and the other right-to-left languages (i18n.direction): one menu that mirrors itself.")
            .field("fit", &Panel::fit,
                   "true: `size` is recomputed every frame as the content size + padding (needs layout row, column or grid); "
                   "the pivot then decides which point of the fitted box stays on the position.")
            .field("uniformSize", &Panel::uniformSize,
                   "true: every Button, Toggle and Slider with autoSize anywhere inside this panel (children, and the children "
                   "of the panels and lists inside it; active ones only) takes the size of the largest of them, width and "
                   "height separately, every layout. Widgets without autoSize keep their size and do not count. Use it for a "
                   "grid of level buttons as wide as the widest label.")
            .enum_field("fallbackLayout", &Panel::fallbackLayout, {"none", "row", "column", "grid"},
                        "Layout used instead of `layout` when the panel laid out with `layout` would not fit the screen "
                        "(none = never switch). The panel leaves the screen when its content size + padding, or the size of "
                        "the outermost fit Panel around it, is wider than the screen and `layout` is row or grid, or taller "
                        "and `layout` is column or grid. The deepest panels switch first, so a menu changes one level at a "
                        "time until it fits; the choice is made again every frame, so it follows the text size and the "
                        "language and goes back to `layout` when the texts shrink. Example: a column of two blocks with "
                        "fallbackLayout \"row\" stands them side by side at a big text size; a row of buttons with "
                        "fallbackLayout \"column\" stacks them. Scripts that must adapt read `usingFallback`.")
            .field("usingFallback", &Panel::usingFallback,
                   "Runtime: true while the panel is laid out with `fallbackLayout` instead of `layout`.")
            .runtime_only().read_only();
    }
    {
        auto button = r.add<Button>("Button",
                  "Clickable button with a text label. Activated by the mouse / a touch, or by ui_submit (Enter, Space, "
                  "gamepad A) while it has focus; the event is ui.click {id}. Focus rules and the other widgets: see Panel.",
                  "UI");
        ui_control_fields(button)
            .field("text", &Button::text,
                   "Label, centred on the button. `\n` starts a new line; every line is centred. Text longer than the button is "
                   "clipped to it: use `maxWidth` to wrap it, `autoSize` to grow the button or `autoShrink` to shrink the text.")
            .field("maxWidth", &Button::maxWidth,
                   "> 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = the label wraps only at `\n`. "
                   "With autoSize the button is at most maxWidth plus its margins wide and grows taller instead.").range(0, 100000)
            .field("autoSize", &Button::autoSize, kAutoSizeDoc)
            .field("autoShrink", &Button::autoShrink, kAutoShrinkDoc)
            .field("minFontSize", &Button::minFontSize, kMinFontSizeDoc).range(1, 4096);
    }
    {
        auto toggle = r.add<Toggle>("Toggle",
                  "Check box with a label: a square box at the left (a filled inner square in accentColor when on) and the "
                  "label to its right. Flips on click or ui_submit; the event is ui.change {id, value: bool}.",
                  "UI");
        ui_control_fields(toggle)
            .field("label", &Toggle::label, "Text to the right of the box.")
            .field("maxWidth", &Toggle::maxWidth,
                   "> 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the "
                   "toggle is at most maxWidth plus the box and margins wide and grows taller instead.").range(0, 100000)
            .field("autoSize", &Toggle::autoSize, kAutoSizeDoc)
            .field("autoShrink", &Toggle::autoShrink, kAutoShrinkDoc)
            .field("minFontSize", &Toggle::minFontSize, kMinFontSizeDoc).range(1, 4096)
            .field("value", &Toggle::value, "true = checked. Scripts may write it; no event is sent for a write.");
    }
    {
        auto slider = r.add<Slider>("Slider",
                  "Horizontal value slider: label in the left 35% (when not empty), the track in the next 50% (85% without a "
                  "label) with a fill and a knob in accentColor, the value in the last 15% (with labelAbove the label is above the track "
                  "and the track gets the 85%). Left / right (ui_left / ui_right, "
                  "d-pad, stick) change the value while focused; dragging the track with the mouse sets it. Event: "
                  "ui.change {id, value: number}.",
                  "UI");
        ui_control_fields(slider)
            .field("label", &Slider::label, "Text at the left (or above the track with labelAbove); empty gives the track the extra room.")
            .field("maxWidth", &Slider::maxWidth,
                   "> 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the "
                   "slider grows taller for the extra lines.").range(0, 100000)
            .field("labelAbove", &Slider::labelAbove,
                   "true: the label is drawn above the track on the slider's full width (wrapping at maxWidth or the width) and "
                   "the track, knob and value sit in a row of 28 px at the bottom, so a long label does not squeeze the track. "
                   "The slider needs a height of the label plus 28 px (autoSize adds it). false (default): the label is in "
                   "the left 35%.")
            .field("autoSize", &Slider::autoSize, kAutoSizeDoc)
            .field("autoShrink", &Slider::autoShrink, kAutoShrinkDoc)
            .field("minFontSize", &Slider::minFontSize, kMinFontSizeDoc).range(1, 4096)
            .field("value", &Slider::value,
                   "Current value, always within [min, max] and snapped to `step` by the UI. Scripts may write it; no event is "
                   "sent for a write.")
            .field("min", &Slider::min, "Smallest value.")
            .field("max", &Slider::max, "Largest value.")
            .field("step", &Slider::step,
                   "Keyboard / gamepad increment, and the grid the value is snapped to (also when dragging). 0 = continuous: "
                   "keys move (max - min) / 20 per press and dragging is not snapped.").range(0, 1000000)
            .field("showValue", &Slider::showValue,
                   "Draw the value at the right: \"60%\" when min is 0 and max is 1, else the number with up to 2 decimals.");
    }
    {
        auto field = r.add<TextField>("TextField",
                  "Single-line text input. While focused it appends the typed characters (Input text), Backspace removes "
                  "the last one (it repeats while held) and Enter submits. There is no caret movement: the caret stays at "
                  "the end. Events: ui.change {id, value} on every edit (one per frame), ui.submit {id, value} on Enter. "
                  "Left / right do nothing in a TextField and Space types a space (ui_submit is ignored).",
                  "UI");
        ui_control_fields(field)
            .field("text", &TextField::text, "The text, UTF-8. Scripts may write it; no event is sent for a write.")
            .field("placeholder", &TextField::placeholder, "Hint drawn at half alpha while `text` is empty.")
            .field("maxLength", &TextField::maxLength, "Longest text, in characters (code points). 0 = unlimited.").range(0, 1000000)
            .field("caret", &TextField::caret,
                   "Runtime: the caret is in the visible half of its blink (a 1 second cycle of the UI's own unscaled clock; it "
                   "restarts visible on every edit). Drawn only while focused.").runtime_only().read_only();
    }
    {
        auto list = r.add<ScrollList>("ScrollList",
                  "Scrolling container: its children are stacked in a column (aligned left, packed at the top) at "
                  "-scroll, and everything drawn by them and their descendants (widgets, Text, Sprite, Shape2D) is CLIPPED "
                  "to the list's rectangle. The mouse wheel over the list scrolls it (the innermost list under the pointer), "
                  "and focusing a widget inside scrolls just enough to show it.",
                  "UI");
        ui_box_fields(list)
            .field("spacing", &ScrollList::spacing, "Gap in design pixels between children.").range(0, 10000)
            .field("padding", &ScrollList::padding, "Space [left, top, right, bottom] between the list's edge and its children.")
            .field("scroll", &ScrollList::scroll,
                   "Runtime: pixels scrolled from the top. Scripts may write it; it is clamped to [0, content height - inner "
                   "height] every frame.").runtime_only()
            .field("scrollSpeed", &ScrollList::scrollSpeed, "Pixels scrolled per mouse-wheel notch.").range(0, 10000)
            .field("fill", &ScrollList::fill,
                   "true: when the parent is a Panel with layout column, `size.y` is set every frame to the height the other "
                   "children leave. In a Panel with `fit` that is the screen height (minus the safe-area insets) minus the "
                   "panel's padding, the gaps and the other children, so the panel ends exactly as tall as the screen at most "
                   "(never below 64 px; if the other children do not leave that, the panel is taller than the screen and "
                   "warns). In a Panel without fit it is the panel's own inner height minus the others. Several fill lists "
                   "share the room equally. Ignored when the parent is not a column Panel. `size.x` is yours.");
    }
    {
        auto stick = r.add<TouchStick>("TouchStick",
                  "On-screen analog stick for phones and tablets (docs/MOBILE.md): a disc in `color` with a knob that follows the "
                  "finger. A finger that lands on it moves a stick of the TOUCH PAD, a virtual gamepad the action bindings read "
                  "like a real one, so actions bound to GamepadLeftStickLeft/Right/Up/Down (or the right stick) work with no "
                  "change to the game; the default ui_* actions include the left stick, so it also walks menus. Full tilt is the "
                  "edge of the disc (half the shorter side); the pad deadzone (input.deadzone) applies like on a real stick. "
                  "That finger is the stick's until it lifts, even outside the disc: it is not in input.touches, the Touch "
                  "binding or the mouse. Several fingers work at once (a stick and buttons). Defaults: 200 x 200, inside the "
                  "safe area, shown only while the player uses touch (touchOnly).",
                  "UI");
        ui_box_fields(stick)
            .enum_field("stick", &TouchStick::stick, {"left", "right"}, "Which stick of the touch pad it moves.")
            .field("knobColor", &TouchStick::knobColor, "Colour of the knob, a disc 45% as wide as the stick.")
            .field("touchOnly", &TouchStick::touchOnly, kTouchOnlyDoc)
            .field("value", &TouchStick::value,
                   "Runtime: the finger's offset from the centre over the radius [x, y], length <= 1, +Y up; [0, 0] when no "
                   "finger holds it. Before the deadzone; read actions (input.vector) for the value the game should use.")
            .runtime_only().read_only()
            .field("pressed", &TouchStick::pressed, "Runtime: a finger holds the stick.").runtime_only().read_only()
            .field("shown", &TouchStick::shown, "Runtime: drawn this frame (see touchOnly).").runtime_only().read_only();
    }
    {
        auto button = r.add<TouchButton>("TouchButton",
                  "On-screen button for phones and tablets (docs/MOBILE.md): a disc in `color` (darker while held) with an "
                  "optional label. While a finger holds it, `button` of the TOUCH PAD is down, a virtual gamepad the action "
                  "bindings read like a real one: a TouchButton with button \"A\" fires every action bound to GamepadA, with no "
                  "change to the game. The finger is the button's until it lifts, even if it slides off, and it is not in "
                  "input.touches, the Touch binding or the mouse. Several fingers work at once. Defaults: 96 x 96, inside the "
                  "safe area, shown only while the player uses touch (touchOnly). It is not focusable and sends no ui events.",
                  "UI");
        ui_box_fields(button)
            .enum_field("button", &TouchButton::button,
                        {"A", "B", "X", "Y", "Start", "Back", "Guide", "DpadLeft", "DpadRight", "DpadUp", "DpadDown",
                         "LeftShoulder", "RightShoulder", "LeftThumb", "RightThumb"},
                        "The pad button it holds down: actions bound to \"Gamepad\" + this name (GamepadA, GamepadDpadUp...) "
                        "fire. Bind the game's actions to pad buttons in factoria.json input.actions to use them.")
            .field("text", &TouchButton::text, "Label centred on the button, e.g. \"A\" or \"Jump\". Empty (default) draws none.")
            .asset_field("font", &TouchButton::font, "font", "Font of the label: project path of a .ttf, empty = the built-in font.")
            .field("fontSize", &TouchButton::fontSize, "Label glyph height in design pixels.").range(1, 4096)
            .field("autoShrink", &TouchButton::autoShrink, kAutoShrinkDoc)
            .field("minFontSize", &TouchButton::minFontSize, kMinFontSizeDoc).range(1, 4096)
            .field("maxTextScale", &TouchButton::maxTextScale, kMaxTextScaleDoc).range(0, 3)
            .field("textColor", &TouchButton::textColor, "Label colour.")
            .field("touchOnly", &TouchButton::touchOnly, kTouchOnlyDoc)
            .field("pressed", &TouchButton::pressed, "Runtime: a finger holds the button.").runtime_only().read_only()
            .field("shown", &TouchButton::shown, "Runtime: drawn this frame (see touchOnly).").runtime_only().read_only();
    }
    {
        auto captions = r.add<Captions>("Captions",
                  "The subtitles of the game (docs/TEXT.md, \"Captions\"): draws the lines that `audio.play(path, { caption })` and "
                  "`ui.caption(text, seconds)` put on the caption list, the newest `maxLines` of them, at the bottom of this entity's "
                  "rectangle on a background that hugs the text. Text is drawn like Text: it follows ui.textScale, the localization "
                  "font chain and right-to-left languages. Put ONE per scene (or in a persistent HUD). Without any Captions entity "
                  "captions are still tracked (game.captions() in tests lists them) but nothing is drawn, and the log says so once. "
                  "An inactive Captions entity draws nothing either: that is how a \"Subtitles\" option turns them off. Defaults: "
                  "bottom centre of the safe area, 960 x 180, over a dark background.",
                  "UI");
        ui_box_fields(captions)
            .field("maxLines", &Captions::maxLines,
                   "How many captions show at once. When more are on the list the oldest are not drawn (they stay on the list "
                   "until their sound ends or their seconds run out).").range(1, 16)
            .field("padding", &Captions::padding, "Space [left, top, right, bottom] between the edge of the background and the text.")
            .asset_field("font", &Captions::font, "font", "Font of the captions: project path of a .ttf, empty = the built-in font (same values as Text.font).")
            .field("fontSize", &Captions::fontSize, "Glyph height in design pixels, before ui.textScale.").range(1, 4096)
            .field("textColor", &Captions::textColor, "Colour of the caption text.")
            .field("speakerColor", &Captions::speakerColor,
                   "Colour of the speaker's name, drawn before the line (\"Mara:\"). Captions without a speaker have no name.")
            .enum_field("align", &Captions::align, {"left", "center", "right", "start", "end"},
                        "Where the block of captions sits inside the rectangle's width, and how the lines align in it. Same values as "
                        "Text.align: start / end follow the language (start = right in Arabic or Hebrew).")
            .field("spacing", &Captions::spacing, "Gap in design pixels between two captions.").range(0, 1000)
            .field("lines", &Captions::lines,
                   "Runtime: what is drawn now, [{text, speaker}] oldest first, at most `maxLines`. Written by the engine every frame "
                   "from the caption list; do not edit it.")
            .runtime_only().read_only();
    }

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
        .field("ambientLight", &SceneSettings::ambientLight, "Base light added to all lit 3D surfaces so shadows are not pitch black. It is also the base light of lit 2D visuals "
               "(Sprite.lit, Tilemap.lit): a lit sprite shows its texture multiplied by this colour plus the Light2D lights. "
               "Raise it to [1, 1, 1] and the lit sprites look unlit.")
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
