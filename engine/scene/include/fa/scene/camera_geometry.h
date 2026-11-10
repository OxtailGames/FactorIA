// Where the cameras of a world are and what they see: the view and projection matrices, the viewport, the visible rectangle, and
// the questions a script or the UI asks of them (camera.worldToScreen, camera.screenToWorld, camera.at, input.mouse.world, a
// world-space Interactable). The maths lives here, not in the renderer, so a run with no renderer (--no-graphics, no GPU) answers
// exactly like one that draws: the renderer (fa_render) builds its CameraInfo on CameraGeometry, and the runtime keeps a CameraSet
// of its own when there is no renderer. Parallax layers follow the same camera (update_parallax), so their offset is part of the
// simulation too, not of drawing.
#pragma once

#include <cstddef>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/scene/world.h"

namespace fa {

// What a camera is drawn into.
struct CameraTarget {
    int width = 1280, height = 720;              // the logical (design) size of the target in pixels: what layouts and pointers count in
    int designWidth = 1280, designHeight = 720;  // the project's design resolution
    bool expand = false;                         // ScaleMode::Expand: the design height (or width) stays, the other axis grows with the aspect
    bool zeroToOne = false;                      // the depth range of proj / viewProj / invViewProj, for DRAWING: the backend's (D3D, Metal)
};

// One camera as the renderer draws it. Entity-less when the world has no camera (the default camera, centred on the origin).
struct CameraGeometry {
    Entity entity = kNullEntity;            // the Camera entity (null for the default camera of a world without one)
    int depth = 0;                          // Camera.depth
    // Camera.viewport after sanitizing: [x, y, w, h] as fractions of the target, top-left origin, +Y down. proj maps the
    // view onto THIS rectangle (its aspect is the rectangle's), so ndc -1..1 is the viewport, not the whole target.
    Rect viewport{0, 0, 1, 1};
    bool fullViewport() const { return viewport.x == 0.0f && viewport.y == 0.0f && viewport.w == 1.0f && viewport.h == 1.0f; }
    Mat4 view, proj, viewProj, invViewProj;  // for drawing: the depth range of CameraTarget::zeroToOne
    // The same matrices with the OpenGL depth range (-1..1) whatever the backend, which the queries below use: an answer does not
    // depend on the graphics API (nor on whether there is one).
    Mat4 queryViewProj, queryInvViewProj;
    Vec3 position{0, 0, 0};
    bool perspective = false;
    bool fromEntity = false;
    float fov = 60.0f;
    float halfH = 360.0f, halfW = 640.0f;   // orthographic half extents (world units)
    float pixelsPerUnit = 1.0f;             // ortho: target pixels per world unit
    Rect visible{};                         // orthographic view rectangle in world units
    Vec3 right{1, 0, 0}, up{0, 1, 0}, forward{0, 0, -1};

    // `target` is the size of the target in pixels (CameraTarget::width/height).
    Vec2 world_to_screen(Vec3 p, Vec2 target) const;
    void screen_ray(Vec2 screen, Vec2 target, Vec3& origin, Vec3& dir) const;
    Vec3 screen_to_world(Vec2 screen, Vec2 target, float depth) const;
};

// The viewport a camera is drawn with: a valid Camera.viewport as it is, an invalid one (a script can set any value live; the scene
// loader refuses it in a file) clamped into the screen, or the whole screen when it has no size. Logs the problem once (`warned`
// remembers the last one).
Rect sanitize_camera_viewport(const Rect& viewport, std::string& warned);

// The geometry of `camera` (a Camera entity; null = the default camera), seen into `target`. `viewSize` (pixels): the camera fills an
// image of that size whatever its viewport says (a CameraView / render target); `renderTarget` then also skips the Expand growth.
// `warnedViewport` is the caller's "bad viewport already logged" memory.
CameraGeometry camera_geometry(World& world, Entity camera, const CameraTarget& target, std::string& warnedViewport,
                               const Vec2* viewSize = nullptr, bool renderTarget = false);

// Picks, for a query, among `cameras` (the ones a frame draws, in draw order): `camera` when it is one of them; else (a
// `screenPoint` given, in target pixels) the topmost whose viewport contains the point; else the first. Null when `cameras` is empty.
template <class C>
const C* pick_camera(const std::vector<C>& cameras, Entity camera, const Vec2* screenPoint, Vec2 target) {
    if (cameras.empty()) return nullptr;
    if (camera)
        for (const C& c : cameras)
            if (c.entity == camera) return &c;
    if (screenPoint && cameras.size() > 1 && target.x > 0 && target.y > 0) {
        const float nx = screenPoint->x / target.x, ny = screenPoint->y / target.y;
        for (std::size_t i = cameras.size(); i-- > 0;) {
            const Rect& v = cameras[i].viewport;
            if (nx >= v.x && nx < v.x + v.w && ny >= v.y && ny < v.y + v.h) return &cameras[i];
        }
    }
    return &cameras.front();
}

// The cameras of a run with no renderer, answering like Renderer's (world_to_screen, screen_to_world, screen_ray, camera_at,
// cameras). Like the renderer's it is a snapshot: refresh() once per frame, at the end of the frame (Engine::render), so a script
// reading input.mouse.world during a frame sees the cameras as that frame began, with or without a renderer. Empty until the
// first refresh (the queries then use the default camera's identity matrices, as the renderer's do).
class CameraSet {
public:
    void refresh(World& world, const CameraTarget& size);
    const std::vector<CameraGeometry>& all() const { return cameras_; }
    Vec2 target() const { return {float(target_.width), float(target_.height)}; }

    Vec2 world_to_screen(Vec3 p, Entity camera = kNullEntity) const;
    void screen_ray(Vec2 s, Vec3& origin, Vec3& dir, Entity camera = kNullEntity) const;
    Vec3 screen_to_world(Vec2 s, float depth, Entity camera = kNullEntity) const;
    std::vector<Entity> cameras() const;  // the Camera entities, in draw order
    Entity camera_at(Vec2 screen) const;  // the topmost camera drawing at the point, else the first (null without cameras)

private:
    std::vector<CameraGeometry> cameras_;
    CameraTarget target_;
    std::string warnedViewport_;
    bool warnedCameras_ = false;
};

// Parallax layers follow the camera: Parallax.offset = camPos * (1 - factor). The offset a world keeps is the one for the FIRST
// camera, set once a frame with or without a renderer (entity.bounds() of a layer and the hash of the world read it). A renderer
// that draws several cameras (or a render target) calls it with each camera it draws so each shows the layers shifted for itself,
// and puts the first camera's offset back when the frame is gathered.
void update_parallax(World& world, Vec2 camPos);

}  // namespace fa
