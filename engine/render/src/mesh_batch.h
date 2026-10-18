// CPU side of the 3D pass, free of any GPU call so tests can look at it: frustum culling, instancing batches and the
// choice of the lights that fit the shader.
#pragma once

#include <vector>

#include "render_internal.h"

namespace fa::render {

// One MeshRenderer entity, gathered for this frame.
struct MeshItem {
    MeshAsset* mesh = nullptr;
    Mat4 model;
    const MeshRenderer* mr = nullptr;
    TextureAsset* tex = nullptr;        // MeshRenderer.texture (null = the glTF material's, or white)
    TextureAsset* normalTex = nullptr;  // MeshRenderer.normalMap (null = the glTF material's, or none)
    float dist = 0;                     // distance to the camera (blended meshes are drawn far to near)
    bool visible = true;                // inside the camera frustum: drawn in the main pass
    bool casts = false;                 // inside the light frustum and castShadows: drawn in the shadow pass
};

// True unless every corner of the box (bmin..bmax in model space, moved by `model`) lies outside the same plane of the
// clip volume of `viewProj`. Conservative: a box near a frustum corner may pass. `zeroToOne` = D3D/Metal depth range.
bool box_in_frustum(const Mat4& viewProj, bool zeroToOne, Vec3 bmin, Vec3 bmax, const Mat4& model);

// A run of items drawn with one instanced draw per mesh part. The model matrices of the visible items sit at
// mainMats[mainFirst .. +mainCount), those of the shadow casters at shadowMats[shadowFirst .. +shadowCount).
struct MeshBatch {
    std::size_t rep = 0;  // index in `items` of the first item (stands for the material of the whole batch)
    std::uint32_t mainFirst = 0, mainCount = 0, shadowFirst = 0, shadowCount = 0;
};

// Groups `items` (sorted in place by material when `sortByMaterial`, otherwise kept in order and only neighbours merge:
// blended meshes stay far-to-near).
void build_batches(std::vector<MeshItem>& items, bool sortByMaterial, std::vector<MeshBatch>& batches,
                   std::vector<Mat4>& mainMats, std::vector<Mat4>& shadowMats);

struct LightData {
    Vec4 pos, color, dir;
    int rank = 2;      // 0 = shadow-casting directional, 1 = directional, 2 = point/spot
    float score = 0;   // how relevant the light is to the camera (larger = keep first)
};

// Orders the lights by relevance (the shadow caster first, then directional lights, then point and spot lights by
// brightness over distance to the camera: `score`) and drops what exceeds `maxCount`. Returns how many were dropped.
int select_lights(std::vector<LightData>& lights, std::size_t maxCount);

}  // namespace fa::render
