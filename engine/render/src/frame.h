// Per-frame CPU state shared by the gather passes (2D, particles, debug, 3D).
#pragma once

#include "render_internal.h"

namespace fa::render {

struct Frame {
    CameraInfo cam;
    int targetW = 0, targetH = 0;
    float dt = 0;
    QuadList world, screen, debugWorld, debugScreen;
    std::vector<Vertex2D> debugLines;  // GL line list (perspective cameras)
    RenderStats* stats = nullptr;
    Assets* assets = nullptr;
    Fonts* fonts = nullptr;
    bool white_used = false;
};

// Emits the 4 vertices of an axis-aligned local rectangle (y up) transformed by `m`.
// flipY: local y is negated first (screen space is y down).
struct QuadEmitter {
    QuadList& list;
    Mat4 m;
    bool flipY = false;
    std::uint32_t color = 0xFFFFFFFFu;
    float mode = 0, aux = 0;

    Vec3 xf(float x, float y, float z = 0) const { return m.transform_point({x, flipY ? -y : y, z}); }
    // Local rectangle [x0,x1] x [y0,y1] with uv rect (u0,v0 = top-left).
    void rect(float x0, float y0, float x1, float y1, float u0, float v0, float u1, float v1) const;
};

void update_animators(World& world, Frame& f);
void gather_2d(World& world, Frame& f);
void gather_particles(World& world, Frame& f);
void clear_particles();
void gather_debug(DebugDrawData& dd, Frame& f);

// Helpers
bool entity_active(const World& w, Entity e);
float matrix_scale_x(const Mat4& m);

}  // namespace fa::render
