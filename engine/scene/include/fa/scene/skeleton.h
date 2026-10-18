// Skeleton data of a glTF file: the node hierarchy with rest poses, skins (joints + inverse bind matrices),
// animation clips and the per-vertex joints/weights of skinned meshes. GPU-free on purpose: tests, the animation
// system (animation.h) and the renderer all read the same plain data. Loading goes through fa::fs (so packed games
// work) and cgltf.
#pragma once

#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// A glTF node: parent index (-1 = scene root) and the rest pose it has without animation.
struct SkelNode {
    std::string name;
    int parent = -1;
    Vec3 translation{0, 0, 0};
    Quat rotation{};
    Vec3 scale{1, 1, 1};
};

// A skin: joints are node indices; inverseBind[i] belongs to joints[i] (identity when the file has none).
struct SkelSkin {
    std::string name;
    std::vector<int> joints;
    std::vector<Mat4> inverseBind;
};

enum class AnimPath : std::uint8_t { Translation, Rotation, Scale };
enum class AnimInterp : std::uint8_t { Linear, Step, CubicSpline };

// One animated property of one node. `values` holds 3 floats (translation, scale) or 4 (rotation x y z w) per key;
// CubicSpline stores (in tangent, value, out tangent) per key, i.e. three times as many.
struct AnimChannel {
    int node = -1;
    AnimPath path = AnimPath::Translation;
    AnimInterp interp = AnimInterp::Linear;
    std::vector<float> times;
    std::vector<float> values;
};

struct AnimClip {
    std::string name;
    float duration = 0.0f;  // the largest key time over all channels
    std::vector<AnimChannel> channels;
};

// JOINTS_0 / WEIGHTS_0 of one triangle primitive of a skinned mesh node. `node` and `primitive` (index in the mesh's
// primitive list) identify it the way the renderer's loader walks the file (nodes in order, then primitives), one entry
// per vertex in POSITION order. Joint indices index SkelSkin::joints of `skin`; weights are normalized to sum 1.
struct SkinVertices {
    int node = -1;
    int primitive = 0;
    int skin = 0;
    std::vector<std::array<std::uint16_t, 4>> joints;
    std::vector<std::array<float, 4>> weights;
};

struct SkeletonAsset {
    std::string path;
    std::vector<SkelNode> nodes;
    std::vector<int> order;  // node indices, every parent before its children
    std::vector<SkelSkin> skins;
    std::vector<AnimClip> clips;
    std::vector<SkinVertices> skinVertices;

    // Index of the clip called `name`, or -1.
    int find_clip(std::string_view name) const;
    std::vector<std::string> clip_names() const;
};

// Reads the skeleton data of a .gltf/.glb (project-relative path). The result is cached per path and file
// modification time, so every animator on the same model shares it.
Result<std::shared_ptr<const SkeletonAsset>> load_skeleton(std::string_view path);
// Same, from bytes already in memory (tests, generated data). The file may reference only embedded buffers.
Result<SkeletonAsset> parse_skeleton(const std::vector<std::uint8_t>& bytes, std::string_view pathForErrors);
void clear_skeleton_cache();

}  // namespace fa
