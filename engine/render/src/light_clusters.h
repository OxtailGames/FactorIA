// Clustered forward lighting, the CPU half (M73.1; docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "Clustered lights"). Free of any GPU
// call so tests can look at it: the view is cut into a grid of tiles (about 64 px) and exponential depth slices, every local light
// (a sphere of its range) is assigned to the clusters it can reach, and the lights and the lists are packed into the RGBA32F data
// texture the mesh fragment shader reads with texelFetch (shaders/light_data.glsl has the layout).
//
// The build is a deterministic job: the light ranges are independent per light, the lists are filled slice by slice (the clusters of a
// slice belong to that slice's chunk) with the lights in ascending index order, and the totals are joined in a fixed order, so the lists
// are the same bytes with 0, 1 or 16 job threads. Every limit is a count of lights, clusters or list entries, never a time.
#pragma once

#include <cstddef>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"
#include "local_shadows.h"
#include "mesh_batch.h"

namespace fa::render {

inline constexpr int kClusterTilePx = 64;     // the tiles of the grid are about this many pixels square
inline constexpr int kClusterSlices = 24;     // exponential depth slices between the camera's near and far planes
inline constexpr int kMaxClusters = 1 << 16;  // the tiles grow (doubling) until the grid has at most this many clusters
inline constexpr int kMaxLightsPerCluster =
    128;  // a cluster keeps its first 128 lights (ascending light index); the rest are dropped
inline constexpr std::size_t kMaxClusterIndices =
    std::size_t(1) << 19;  // list entries of a view; the last clusters lose lights past it
// The decals (M73.5b): at most this many per view, 32 per cluster and 131072 list entries in all (a cluster, then the view, keeps its first
// decals in ascending order; the rest are dropped). Counts, never times.
inline constexpr int kMaxDecals = 256;
inline constexpr int kMaxDecalsPerCluster = 32;
inline constexpr std::size_t kMaxDecalIndices = std::size_t(1) << 17;
inline constexpr int kDecalTexels = 7;  // texels of one decal in the decal region (shaders/light_data.glsl, fa_decals)
inline constexpr int kDecalHeaderTexels = 2;     // the region starts with two header texels
inline constexpr int kLightTextureWidth = 1024;  // texels per row of the data texture (shaders/light_data.glsl)
inline constexpr int kLightTexels = 4;           // texels of one light in the table

// The camera of a view as the clusters need it. `viewProj` is the matrix the vertex stage multiplies with (so the tile of a fragment
// is found with the same numbers on every backend, whatever its window or depth conventions); depths are distances along `forward`.
struct ClusterCamera {
    Mat4 viewProj;
    Vec3 position{0, 0, 0}, forward{0, 0, -1};
    float nearDepth = 0.1f,
          farDepth = 1000.0f;       // of the visible volume, along forward (> 0 after make_cluster_camera's clamping)
    int widthPx = 1, heightPx = 1;  // the viewport in pixels
};

// What the grid of a view is (the numbers the shader receives too).
struct ClusterGrid {
    int tilesX = 1, tilesY = 1, slices = kClusterSlices;
    float nearDepth = 0.1f;
    float slicesPerOctave = 1.0f;  // slices / log2(far / near)
    int clusters() const { return tilesX * tilesY * slices; }
};

// The grid for a view: tiles of kClusterTilePx (doubled while there would be more than kMaxClusters clusters), kClusterSlices slices
// from nearDepth to farDepth (clamped to a positive near and a far that is at least 1.5 times as far).
ClusterGrid make_cluster_grid(int widthPx, int heightPx, float nearDepth, float farDepth);

// The depth slice of a distance along forward (0 for anything nearer than near or NaN, the last for anything farther than far).
int cluster_slice(const ClusterGrid& grid, float depth);
// The tile (0 .. tiles - 1) of a normalized device coordinate (-1 .. 1). NaN gives 0.
int cluster_tile(float ndc, int tiles);
// The index of the cluster of a tile and a slice (slice-major, then row, then column: what the shader computes).
inline int cluster_index(const ClusterGrid& g, int tx, int ty, int slice) {
    return (slice * g.tilesY + ty) * g.tilesX + tx;
}

// A local light as a sphere: its position and range. radius <= 0, NaN or infinite: the light belongs to no cluster.
struct LightSphere {
    float x = 0, y = 0, z = 0, radius = 0;
};

// The clusters a sphere can reach, as inclusive ranges. False when it reaches none (behind the camera, beyond the far plane, outside
// the view or without a size). Conservative: every fragment the sphere lights is in a cluster of the range (a margin of two pixels and
// a relative margin in depth cover the rounding of the GPU).
struct ClusterRange {
    int x0 = 0, x1 = -1, y0 = 0, y1 = -1, s0 = 0, s1 = -1;
};
bool light_cluster_range(const ClusterCamera& cam, const ClusterGrid& grid, const LightSphere& sphere,
                         ClusterRange& out);

// A decal's box as the eight corners it has in the world (bit 0 of the index = local x, bit 1 = y, bit 2 = z, of the cube -0.5 .. 0.5).
struct DecalBox {
    Vec3 corners[8];
};
// The clusters a decal box can reach (the same margins and rules as light_cluster_range).
bool decal_cluster_range(const ClusterCamera& cam, const ClusterGrid& grid, const DecalBox& box, ClusterRange& out);

// The lists of a view: per cluster the first slot of its light indices and how many it has; `indices` holds the lists one after the
// other, each in ascending light index.
struct ClusterLists {
    ClusterGrid grid;
    std::vector<std::uint32_t> first;
    std::vector<std::uint32_t> count;
    std::vector<std::uint32_t> indices;
    int lightsAssigned = 0;          // lights that reach at least one cluster
    std::size_t clippedEntries = 0;  // list entries lost to kMaxLightsPerCluster or kMaxClusterIndices
    int clippedClusters = 0;         // clusters that lost entries
    std::size_t maxPerCluster = 0;   // the longest list kept
};

// Assigns the lights (`spheres[n]` is table light n; directional lights have radius 0 and are in every cluster without a list) to the
// clusters of `grid`. Deterministic for any number of job threads.
void build_light_clusters(const ClusterCamera& cam, const ClusterGrid& grid, const std::vector<LightSphere>& spheres,
                          ClusterLists& out);

// Assigns the decals (`boxes[n]` is decal n of the table, in drawing order) to the clusters of `grid`, with the limits of the decals
// (kMaxDecalsPerCluster, kMaxDecalIndices). Deterministic for any number of job threads. `lightsAssigned` of the result counts the decals
// that reach a cluster.
void build_decal_clusters(const ClusterCamera& cam, const ClusterGrid& grid, const std::vector<DecalBox>& boxes,
                          ClusterLists& out);

// A decal as the shader reads it: kDecalTexels RGBA32F texels.
struct DecalRecord {
    float rows[12]{};       // world -> box space (the cube -0.5 .. 0.5), three rows of xyz + translation w
    float albedoRect[4]{};  // u0, v0, u1, v1 of the albedo tile in the atlas (without its gutter); all 0 = no albedo
    float normalRect[4]{};  // the same for the normal map
    float tint[4]{1, 1, 1, 1};  // colour (in the scene's colour space) and alpha
    float opacity = 1.0f, normalStrength = 1.0f;
    float angleScale = 1.0f;  // 1 / max(cos(angleFade), 1e-3)
    float layers = 65535.0f;  // bit mask of the MeshRenderer.decalLayer values that receive it
};
// The decals of a view: their records in drawing order, their cluster lists and what the shader needs of the atlas.
struct DecalPack {
    std::vector<DecalRecord> records;
    ClusterLists lists;  // from build_decal_clusters, on the same grid as the lights' lists
    int atlasWidth = 1, atlasHeight = 1;
    int colorMode =
        0;  // 0 = gamma scene (the atlas holds raw bytes), 1 = linear scene, atlas RGBA8 (the albedo is sRGB: decode it),
            // 2 = the atlas is SRGB8A8 (the GPU decodes everything, the normal tiles are encoded back)
};

// The data texture of a view and the numbers the shader needs (fa_mesh_fs_params, fa_cl_*; all zero and info.x = -1 with no clusters).
struct ClusterUniforms {
    float vpx[4]{}, vpy[4]{}, vpw[4]{}, fwd[4]{}, grid[4]{}, info[4]{-1, 0, 0, 0};
    float decalBase = 0;  // first texel of the decal region (fa_counts.y); 0 = the view has no decals
};
struct LightTexture {
    int width = kLightTextureWidth;
    int height = 0;              // rows, a power of two (so the image is made again rarely)
    std::vector<float> texels;   // width * height RGBA32F texels
    std::size_t usedTexels = 0;  // texels that hold data
    ClusterUniforms uniforms;
    // The first texel of the shadow region of the point and spot lights (local_shadows.h), after the cluster lists; -1 = none. The
    // fragment shader finds it in fa_shadow_lcfg.x (shaders/shadow_common.glsl).
    long long shadowBase = -1;
};
// Packs the light table (`lights`, directional first: `directional` of them), and when `lists` is not null the cluster table and the
// lists after it, then (when `shadows` is not null and not empty) the shadow region of the local lights, then (when `decals` is not null)
// the decal region. `camera` supplies the matrix rows and the forward axis. Sets height to the rows needed (at least 1). `decals` (only
// with `lists`, on the same grid) adds the decal slots in z and w of each cluster texel; a view without decals has the same texels as
// before M73.5b (z and w of a cluster texel are 0).
void pack_light_texture(const std::vector<LightData>& lights, int directional, const ClusterCamera& camera,
                        const ClusterLists* lists, LightTexture& out,
                        const std::vector<LocalShadowRecord>* shadows = nullptr, const DecalPack* decals = nullptr);

// The rows (a power of two) a texture of `texels` texels needs.
int light_texture_rows(std::size_t texels);

}  // namespace fa::render
