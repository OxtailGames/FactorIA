// The skinning of the ray tracing scene (M79 P1k; docs/design/ARCHITECTURE_RT_SCENE.md, "Skinned meshes"): what the compute kernel
// engine/render/shaders/rt_skin.glsl reads and writes, and its twin on the CPU. A skinned mesh is drawn by the vertex shader with the
// Animator's palette (mesh_common.glsl, fa_skin_matrix); the acceleration structure must hold the same triangles, so the kernel does the
// same blend of the same four joints for every vertex and writes the positions the BLAS of that instance is built from.
#pragma once

#include <algorithm>
#include <cstdint>
#include <cstring>
#include <vector>

#include "fa/core/math.h"
#include "render_internal.h"

namespace fa::render {

// The slots of rt_skin.glsl (the sokol-shdc macros of its generated header have the same values: renderer_rt.cpp checks it at compile time).
inline constexpr int kRtSkinViewVertices = 0;    // readonly: MeshVertex of the part (13 floats, the position first)
inline constexpr int kRtSkinViewInfluences = 1;  // readonly: SkinVertex of the part (5 words: four joint bytes, four weights)
inline constexpr int kRtSkinViewPalette = 2;     // readonly: the palettes of the frame, kRtSkinPaletteRows vec4 rows each
inline constexpr int kRtSkinViewOut = 3;         // writeonly: three floats per vertex
inline constexpr int kRtSkinUniformParams = 0;   // int[4]: x = vertex count, y = first palette row
inline constexpr std::uint32_t kRtSkinGroupSize = 64;                       // threads per group (local_size_x of the kernel)
inline constexpr std::uint32_t kRtSkinPaletteRows = kMaxSkinJoints * 3;     // vec4 rows of one palette
inline constexpr std::uint32_t kRtSkinPaletteFloats = kRtSkinPaletteRows * 4;
// One dispatch has at most 65535 groups on every API: the most vertices one part can have to be skinned for the ray tracing scene.
inline constexpr std::uint32_t kRtSkinMaxPartVertices = 65535u * kRtSkinGroupSize;

// The palette as the kernel and the vertex shader read it (pack_palette in renderer_draw.cpp): joint j is rows 3j .. 3j+2, row r of its 3x4
// matrix holds m.at(c, r) in component c; the joints the palette does not have are the identity. Writes kRtSkinPaletteFloats floats.
inline void rt_skin_pack_palette(const std::vector<Mat4>& palette, float* out) {
    for (int j = 0; j < kMaxSkinJoints; ++j) {
        const Mat4 m = std::size_t(j) < palette.size() ? palette[std::size_t(j)] : Mat4::identity();
        for (int r = 0; r < 3; ++r)
            for (int c = 0; c < 4; ++c) out[(j * 3 + r) * 4 + c] = m.at(c, r);
    }
}

// The kernel's maths for one vertex, in the same order of operations (float adds of weight * row, then the dots): `rows` is a packed palette.
inline Vec3 rt_skin_position(const MeshVertex& v, const SkinVertex& s, const float* rows) {
    float r[3][4] = {};
    for (int i = 0; i < 4; ++i) {
        const int j = std::min<int>(s.joints[i], kMaxSkinJoints - 1);
        const float w = s.weights[i];
        for (int k = 0; k < 3; ++k)
            for (int c = 0; c < 4; ++c) r[k][c] += rows[(j * 3 + k) * 4 + c] * w;
    }
    const auto dot4 = [&](int k) { return r[k][0] * v.px + r[k][1] * v.py + r[k][2] * v.pz + r[k][3]; };
    return {dot4(0), dot4(1), dot4(2)};
}

}  // namespace fa::render
