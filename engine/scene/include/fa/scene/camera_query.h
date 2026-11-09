// Which cameras a frame draws and where they put a world point on the screen, for code that has no renderer: the script
// natives (camera.main, camera.worldToScreen, ...) and the widgets in world space (Interactable) when the game runs without a GPU.
// The renderer (fa_render) answers the same questions with the real projection; the orthographic maths here is the same.
#pragma once

#include <cmath>
#include <vector>

#include "fa/core/det_math.h"
#include "fa/core/math.h"
#include "fa/scene/world.h"

namespace fa {

struct Camera;

// The cameras a frame draws, in draw order: every active camera with primary = true by ascending depth (equal depths keep
// the order of creation), at most 8 as the renderer draws. The first is "the" camera (camera.main).
std::vector<Entity> rendering_cameras(World& w);

// The viewport of `c` as the renderer clamps it: a finite rectangle inside [0, 1] (the whole screen when it is not usable).
Rect clamped_camera_viewport(const Camera& c);

// An orthographic camera seen from outside: world units to design pixels.
struct OrthoView {
    Entity camera;         // the camera, null when the scene has none (then the view is centred on the origin)
    Vec3 position{};       // the camera's world position AS DRAWN: a running camera shake (feel.h) is in it
    float roll = 0.0f;     // radians the view is turned about z by a running camera shake (0 without one; the camera's own rotation is not here)
    Vec2 center;           // the centre of the camera's rectangle, in design pixels
    float scale = 1.0f;    // design pixels per world unit
    Rect viewport{0, 0, 1, 1};

    // The conversions map to what the player SEES, so the shake (offset and roll) is in them; the entities' own positions stay the
    // true ones. A world point under a screen point is therefore where the scene says it is, shake or not.
    Vec2 to_screen(Vec3 p) const {
        const float c = det::cos(roll), s = det::sin(roll);
        const float dx = p.x - position.x, dy = p.y - position.y;
        // the view's axes are the world's turned by `roll`: view = R(-roll) * delta
        return {center.x + (dx * c + dy * s) * scale, center.y - (dy * c - dx * s) * scale};
    }
    Vec3 to_world(Vec2 s, float z = 0.0f) const {
        const float c = det::cos(roll), sn = det::sin(roll);
        const float vx = (s.x - center.x) / scale, vy = -(s.y - center.y) / scale;
        return {position.x + vx * c - vy * sn, position.y + vx * sn + vy * c, z};
    }
};

// The view `named` gives when it is a camera that is drawn; else (a `point` in design pixels given) the last camera whose
// viewport contains the point; else the first camera. `design` is the size of the game target in pixels.
OrthoView ortho_view(World& w, Vec2 design, Entity named, const Vec2* point);

// The camera that draws at `point` (design pixels): the last of rendering_cameras() whose viewport contains it, else the first
// (null without cameras).
Entity camera_containing(World& w, Vec2 design, Vec2 point);

}  // namespace fa
