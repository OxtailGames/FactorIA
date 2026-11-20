// The CPU side of the shadows of M73.2: how a frame's shadow maps are laid out in the one shadow atlas, and how the cascades of the
// directional light are cut and fitted. No GPU here: pure functions, tested by tests/shadow_cascades_tests.cpp, and used by
// Renderer::Impl::shadow_bounds (renderer_draw.cpp). docs/design/ARCHITECTURE_RENDERING_LIGHTING.md, "The shadow atlas".
#pragma once

#include <array>
#include <cstdint>
#include <vector>

#include "fa/core/math.h"

namespace fa::render {

// The cascades of the directional light (SceneSettings.shadowCascades is 1..4).
constexpr int kMaxShadowCascades = 4;

// ---------------------------------------------------------------------------
// The shadow atlas
// ---------------------------------------------------------------------------
// One 2D atlas holds every shadow map of a frame: the cascades of the sun today, the six faces of a point light and the map of a spot
// light with M73.2b. A map is a square tile of a power-of-two size. The layout is a buddy allocator over the atlas: tiles are placed
// biggest first, each in the free square that fits it best (smallest, then the topmost and leftmost), so equal inputs give the same
// layout and the used part of the atlas is a compact block at its top left corner.
struct ShadowTileRequest {
    int size = 0;      // texels per side wanted; rounded down to a power of two
    int minSize = 64;  // the least the map may be shrunk to when the atlas is full (a power of two)
    int priority = 0;  // lower = more important: shrunk and dropped last
};

struct ShadowTile {
    int x = 0, y = 0;  // texel of the top left corner (y counts from the top of the image)
    int size = 0;      // texels per side as placed (0 = dropped: it did not fit)
    bool placed() const { return size > 0; }
};

struct ShadowAtlasLayout {
    std::vector<ShadowTile> tiles;  // one per request, in the order of the requests
    int width = 0, height = 0;      // the used part of the atlas, each side a power of two (0 when nothing was placed)
    int shrunk = 0;                 // how many times a map was halved to make everything fit
    int dropped = 0;                // how many maps did not fit even at their minimum size
};

// The largest power of two <= v (0 for v < 1), and the smallest >= v.
int pow2_floor(int v);
int pow2_ceil(int v);

// Packs `requests` into an atlas of `maxSize` x `maxSize` texels (a power of two). When they do not all fit, the largest map is halved
// (the least important of equally large ones first) down to its minSize, and when none can shrink the least important map is dropped:
// a deterministic budget, so a result never depends on timing. `maxSize` below 64 is raised to 64.
ShadowAtlasLayout layout_shadow_atlas(int maxSize, const std::vector<ShadowTileRequest>& requests);

// ---------------------------------------------------------------------------
// Cascades
// ---------------------------------------------------------------------------
// The distances along the camera's forward axis where `count` cascades start and end between `nearD` and `farD`: the practical split
// scheme of Zhang et al., a blend by `lambda` (0..1) of even steps and logarithmic steps (log needs nearD > 0: with nearD <= 0, as an
// orthographic camera can have, the steps are even). Returns count + 1 values, the first nearD and the last farD; the rest of the
// array is farD.
std::array<float, kMaxShadowCascades + 1> cascade_splits(float nearD, float farD, int count, float lambda);

// Rounds v (> 0) up to a value with `bits` bits of mantissa: the same result for the float jitter of a number that did not really
// change, and never smaller than v.
float quantize_up(float v, int bits);

// The camera's frustum as the corners of its near and far planes (world space, in the same order) and their distances along the
// camera's forward axis. Perspective and orthographic cameras alike: a slice between two distances is a lerp between the planes.
struct CameraFrustum {
    Vec3 nearCorner[4], farCorner[4];
    Vec3 position{0, 0, 0}, forward{0, 0, -1};
    float nearDist = 0, farDist = 1;  // along `forward`
};

// The camera's inverse view-projection (the depth range of the backend: zeroToOne) -> its frustum.
CameraFrustum camera_frustum(const Mat4& invViewProj, bool zeroToOne, Vec3 position, Vec3 forward);

// The smallest sphere centred on the camera's axis that holds the slice of the frustum between the distances d0 and d1: the same
// centre distance and radius for every orientation of the camera, which is what keeps a cascade from changing size as the camera
// turns. centre = position + forward * centreDist.
struct SliceSphere {
    float centreDist = 0, radius = 0;
};
SliceSphere slice_sphere(const CameraFrustum& f, float d0, float d1);

// What one cascade draws with.
struct CascadeFit {
    Mat4 view;             // world -> light space (x right, y up, the light looks down -z)
    Mat4 viewProj;         // world -> clip space of the shadow pass (the depth range of the backend)
    Vec3 centre{0, 0, 0};  // the centre of the fitted sphere, its x and y snapped to a texel of the map
    float radius = 0;      // the sphere's radius: the map covers 2 * radius metres on a side
    float texel = 0;       // metres per texel
    float depthRange = 1;  // metres between the near and the far plane
};

// Fits the cascade for a sphere (`centre`, `radius`, as slice_sphere gave them in the world) seen from a light that shines along
// `lightDir` (the direction the light travels). The sphere's centre is moved to a whole texel of the map (in light space), so the
// shadow of a still object is the same texels whatever the camera does between those steps: no shimmer. `casterMin` is the smallest
// distance along `lightDir` of any shadow caster of the scene (the near plane goes back to it so a caster outside the sphere that
// still shades it is drawn); `tile` is the map's texels per side. Needs radius > 0 and tile >= 4.
CascadeFit fit_cascade(Vec3 centre, float radius, Vec3 lightDir, int tile, float casterMin, bool zeroToOne);

// The matrix that takes a world position to (u, v, depth) in the atlas texture: u and v in 0..1 over the whole atlas of
// `atlasW` x `atlasH` texels, depth 0..1 over the cascade's depth range, whatever the backend. `isGl`: the texture's v runs bottom up
// in a render target (OpenGL), top down elsewhere. The tile is in texels, y from the top.
Mat4 shadow_sample_matrix(const CascadeFit& fit, const ShadowTile& tile, int atlasW, int atlasH, bool zeroToOne,
                          bool isGl);

// The rectangle (umin, vmin, umax, vmax) a tile takes in the atlas texture's own coordinates (see shadow_sample_matrix).
Vec4 shadow_tile_rect(const ShadowTile& tile, int atlasW, int atlasH, bool isGl);

// The far end of the cascaded range when no shadow distance is set: the farthest corner of the casters' box from the camera
// (Euclidean, so it does not change when the camera turns) and a body's length more, because a shadow falls past its caster, rounded up
// to 3 bits of mantissa so a moving camera seldom changes it (and with it every split and every cascade's size).
float auto_shadow_far(Vec3 cameraPosition, Vec3 casterMin, Vec3 casterMax);

// The cascades of one frame: where they split and what each draws with.
struct CascadePlan {
    bool ok = false;  // false: the camera's range is empty, nothing to draw
    std::array<float, kMaxShadowCascades + 1> splits{};
    std::array<CascadeFit, kMaxShadowCascades> fits;
};

// Cuts the camera's view into tileSizes.size() cascades (the texels per side of each one's map, from the atlas layout) and fits them
// to a light that shines along `lightDir`. The range runs from the camera's near plane to `shadowDistance` (0: auto_shadow_far of the
// casters' world box `casterMin`..`casterMax`), never past the camera's far plane. `lambda` is shadowCascadeSplit, `blend` the share of
// a cascade that blends into the next. Everything that sets a cascade's size (the range, the splits, the radius) is the same for every
// orientation of the camera at one position; only the position of a cascade follows the camera.
CascadePlan plan_cascades(const CameraFrustum& cf, Vec3 casterMin, Vec3 casterMax, Vec3 lightDir, float shadowDistance,
                          float lambda, float blend, const std::vector<int>& tileSizes, bool zeroToOne);

}  // namespace fa::render
