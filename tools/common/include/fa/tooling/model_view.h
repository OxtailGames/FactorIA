// A software view of meshes (model.preview and the editor's Model panel): shaded or wireframe, from any side, no graphics device.
// Deterministic and cheap, so it runs in a headless session, a test and an editor frame alike.
//
// Back faces are drawn in a dark red so a triangle that faces the wrong way is visible at a glance. A mesh may carry a part to
// highlight (the part picked in the panel).
#pragma once

#include <string>
#include <vector>

#include "fa/core/image.h"
#include "fa/core/math.h"
#include "fa/scene/mesh_store.h"

namespace fa {

struct ModelViewItem {
    const MeshData* mesh = nullptr;
    Vec3 offset{};                  // added to every position
    bool flat = false;              // ignore the materials and colors: one colour, shaded
    Color flatColor{0.6f, 0.65f, 0.75f, 1};
    bool wire = true;               // take part in the wireframe overlay (the reference figure does not)
    std::string highlightPart;      // submeshes of this part are drawn in the accent colour ("" = none)
};

struct ModelViewOptions {
    int width = 384, height = 384;
    double yawDeg = 30;             // 0 looks at the front (+Z side) of the model, 90 from its +X side
    double pitchDeg = 20;           // above the horizon
    bool orthographic = false;
    bool shaded = true;
    bool wireframe = false;         // edges over the shading (or alone, with `shaded` false: hidden edges stay hidden)
    bool ground = true;             // a grid on y = 0
    int supersample = 2;            // 1 to 3: samples per pixel side
    Vec3 center{};                  // what the camera looks at and frames; radius <= 0 = frame the items
    double radius = 0;
    double zoom = 1;                // > 1 closer
    Color background{0.13f, 0.14f, 0.17f, 1};
};

struct ModelViewFrame {
    Vec3 center{};
    double radius = 1;
};
// The sphere around the items' bounds (offsets applied) that views frame; radius at least 0.05.
ModelViewFrame frame_model_items(const std::vector<ModelViewItem>& items);

// The camera render_model_view builds for `options` looking at (`center`, `radius`), at the size of the picture (width x height, no supersampling):
// what an overlay (bones, gizmos, handles drawn over the picture) projects with and what picking casts rays through. Pixels are the picture's, y down.
struct ModelViewCamera {
    Vec3 eye{}, right{}, up{}, forward{};
    bool orthographic = false;
    double focal = 1;       // pixels per unit at depth 1 (perspective) or per metre (orthographic)
    double cx = 0, cy = 0;  // the pixel the camera looks through
    // Where world point `p` falls: false when it is behind the camera. `depth` is the distance along `forward`.
    bool project(Vec3 p, double& sx, double& sy, double& depth) const;
    // The ray through pixel (sx, sy): its origin and unit direction.
    void ray(double sx, double sy, Vec3& origin, Vec3& direction) const;
};
ModelViewCamera model_view_camera(const ModelViewOptions& options, Vec3 center, double radius);

// The items seen from the camera of `options`. Always returns an image of options.width x options.height.
Image render_model_view(const std::vector<ModelViewItem>& items, const ModelViewOptions& options);

// A 1.8 m figure of simple parts, standing on y = 0, centred on x = z = 0, facing +Z: the scale reference beside a model.
const MeshData& model_reference_figure();

// Where the reference figure stands beside a model whose bounds are given: to the right (+X) of it with a gap, on the ground.
Vec3 reference_figure_offset(Vec3 modelMin, Vec3 modelMax);

}  // namespace fa
