// The CPU lightmap baker (M73.4): a deterministic path tracer that turns triangles, lights and a sky into the diffuse light each texel of a
// lightmap atlas receives, and into spherical harmonics for light probes. docs/design/ARCHITECTURE_BAKING.md has the algorithm and the rules.
//
// Plain data in, plain data out: the caller (the `lightmap.bake` command, a test) flattens its scene into a BakeScene (world-space triangles
// with the lightmap UV of each vertex, a material per triangle, the lights, the sky), and gets float RGB per atlas back. There is no
// renderer, no file format and no component here (module scene).
//
// Units: a texel value is the light a white (albedo 1) diffuse surface shows, so the runtime multiplies it by the albedo. A sky or an
// emissive surface of radiance L lights an open surface with L; a directional light of intensity I lights a surface that faces it with I
// (the same numbers as the realtime light loop, which has no 1/pi); a point or spot light keeps the realtime falloff by default.
//
// Determinism: the result depends on the scene and the settings only. The random numbers are a hash of (seed, atlas, texel, sample,
// bounce), never of the thread; the work is cut into chunks whose bounds depend on the counts; each texel writes its own slot. So
// 0 workers, 1 and 16 give the same bits, and since the maths is + - * / sqrt and fa::det trigonometry (built without contraction)
// the same bits on every platform too.
#pragma once

#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

#include "fa/core/math.h"
#include "fa/core/types.h"

namespace fa {

// What a triangle looks like to the light that reaches it (both faces alike).
struct BakeMaterial {
    Vec3 albedo{0.8f, 0.8f, 0.8f};  // linear reflectance of the diffuse surface, each channel 0..1
    Vec3 emissive{
        0, 0,
        0};  // radiance the surface sends out (any size, 0 = none); seen by the light of the others, not by itself
};

// A mesh in world space. Every mesh is geometry for shadows and bounces (unless castsShadow is false); the ones with an atlas are also
// lit into it.
struct BakeMesh {
    std::string name;             // for messages
    std::vector<Vec3> positions;  // world space
    std::vector<Vec3>
        normals;  // empty (flat triangles) or one unit normal per position (smooth, and the side that is lit)
    std::vector<Vec2>
        lightmapUv;  // one per position, 0..1 of the atlas (v = 0 is row 0 of the result); empty when atlas < 0
    std::vector<std::uint32_t> indices;    // three per triangle
    std::vector<std::uint32_t> materials;  // one per triangle (an index of BakeScene::materials); empty = material 0
    int atlas = 0;  // the index in BakeScene::atlases it is baked into, or -1 for none (shadows and bounces only)
    bool castsShadow = true;  // false: it neither blocks light nor bounces it
};

struct BakeAtlas {
    int width = 256, height = 256;  // texels
};

enum class BakeLightKind : std::int32_t {
    Directional,  // `direction` is where the light travels; `intensity` is what a surface facing it receives
    Point,        // `position`; `intensity` times the falloff is what a surface facing it receives
    Spot,         // a point light inside a cone: `direction` is the axis, `spotAngleDeg` the half angle
    Area          // a one-sided rectangle (width x height, facing `direction`) whose surface has radiance `intensity`
};
// What the light does to the lightmap.
enum class BakeLightMode : std::int32_t {
    Baked,         // its direct light and its bounces are baked
    IndirectOnly,  // mixed: the realtime renderer draws its direct light, the bake keeps only what it bounces off the surfaces
    Realtime  // left out of the bake
};
// How the strength falls with the distance (point and spot lights).
enum class BakeFalloff : std::int32_t {
    Engine,        // like the realtime light loop: (1 - (d / range)^2)^2 clamped to 0..1 (range must be > 0)
    InverseSquare  // 1 / d^2, cut off smoothly at `range` when range > 0
};

struct BakeLight {
    BakeLightKind kind = BakeLightKind::Directional;
    BakeLightMode mode = BakeLightMode::Baked;
    Vec3 color{1, 1, 1};       // linear, each channel >= 0
    float intensity = 1;       // >= 0
    Vec3 position{0, 0, 0};    // point, spot, area (the centre)
    Vec3 direction{0, -1, 0};  // directional, spot, area: need not be unit
    float range = 10;          // point, spot: the distance where the light ends (meters)
    BakeFalloff falloff = BakeFalloff::Engine;
    float spotAngleDeg = 30;  // spot: half angle of the cone, 0..89
    float spotInnerDeg =
        0;  // spot: half angle inside which the light is full; 0 = the realtime rule (a quarter of the way in)
    float softRadius = 0;         // point, spot: radius of the sphere the light comes from (meters): soft shadows
    float softAngleDeg = 0;       // directional: angular radius of the sun disc in degrees: soft shadows
    float width = 1, height = 1;  // area: size in meters
};

// An equirectangular float image of the sky (a Radiance .hdr read by the caller): u = 0.5 + atan2(z, x) / 2 pi, v = acos(y) / pi,
// row 0 up, linear RGB, three floats per pixel. When it has pixels it replaces the gradient.
struct BakeEquirect {
    int width = 0, height = 0;
    std::vector<float> rgb;
    float rotationDeg = 0;  // turns the image around +Y
};

// The light that comes from outside the scene: a constant, a gradient or an image. Radiance (not scaled by pi).
struct BakeSky {
    Vec3 zenith{0, 0, 0};   // straight up
    Vec3 horizon{0, 0, 0};  // at the horizon (a constant sky: all three equal)
    Vec3 ground{0, 0, 0};   // straight down
    float intensity = 1;    // multiplies the gradient and the image
    BakeEquirect image;
};

struct BakeScene {
    std::vector<BakeMesh> meshes;
    std::vector<BakeMaterial> materials;  // empty: every triangle uses one default grey (albedo 0.8, no emission)
    std::vector<BakeLight> lights;
    std::vector<BakeAtlas> atlases;
    BakeSky sky;
};

struct BakeSettings {
    int samples = 64;  // gather rays per texel (sky, emitters and bounces), 1..65536
    int bounces =
        2;  // times the light of the lights is reflected before it reaches a texel: 0 = direct light, sky and emitters only, 0..16
    int shadowSamples =
        4;  // shadow rays per light per texel (soft shadows: they are spread over the light's size), 1..1024
    std::uint32_t seed = 0;  // another seed is another (equally good) noise
    int dilatePasses = 4;    // texels of gutter filled around the baked pieces, 0..64
    int denoiseRadius = 2;   // edge-aware blur radius in texels, 0 = off, 0..8
    float denoiseSigma =
        0.3f;              // how different two neighbours may be (relative to the light) and still be blended, 0.01..10
    float rayEpsilon = 0;  // the offset of a ray from its surface (meters); 0 = the scene's size / 10000
    bool shIncludeDirect =
        true;  // sample_irradiance_sh: add the direct light of the Baked lights (a probe is not a lightmap texel)
    // Budgets: the bake refuses (with what to change) before it allocates or traces anything beyond them.
    int maxAtlasSize = 4096;                    // the largest width or height of an atlas (the texel density cap)
    std::uint64_t maxMemoryBytes = 1ull << 30;  // what the bake may allocate (an estimate with a margin)
    std::uint64_t maxRays =
        50000000000ull;  // an upper bound on the rays: texels x samples x (bounces + 1) x (lights + 1)
};

// Mask values of a baked atlas.
inline constexpr std::uint8_t kBakeEmpty = 0;    // no triangle covers the texel and no gutter reached it: rgb is 0
inline constexpr std::uint8_t kBakeBaked = 1;    // the centre of the texel is on a triangle: baked
inline constexpr std::uint8_t kBakeDilated = 2;  // copied from the baked texels around it (the gutter)

struct BakedAtlas {
    int width = 0, height = 0;
    std::vector<float> rgb;          // width * height * 3, row 0 first
    std::vector<std::uint8_t> mask;  // width * height: kBakeEmpty, kBakeBaked, kBakeDilated
    std::uint32_t bakedTexels = 0;
    std::uint32_t dilatedTexels = 0;
    std::uint32_t overlappedTexels =
        0;  // texels two triangles of the atlas cover (their UVs overlap: the first one wins)
};

struct BakeStats {
    std::uint64_t texels = 0;        // baked texels (all atlases)
    std::uint64_t rays = 0;          // rays traced, shadow rays included
    std::uint64_t triangles = 0;     // triangles of the scene
    std::uint64_t rayBudget = 0;     // the upper bound the budget check used
    std::uint64_t memoryBudget = 0;  // the memory estimate the budget check used
};

struct BakeResult {
    std::vector<BakedAtlas> atlases;
    BakeStats stats;
};

// Checks the scene and the settings: sizes, indices, finite numbers, UV range, light and sky values, and the budgets (memory, atlas size).
// Errors name the field with a JSON-pointer-like path ("/meshes/2/lightmapUv") and say what to change. Allocates nothing big.
Result<void> validate_bake(const BakeScene& scene, const BakeSettings& settings);

// Bakes the lightmaps. Progress goes to report_command_progress() ("lightmap bake: atlas 1/2, texels 2048/4096 (50%)") after each batch of
// texels; a cancelled command (command_cancelled(), checked inside every chunk) ends it with the error "cancelled" and no result.
Result<BakeResult> bake_lightmap(const BakeScene& scene, const BakeSettings& settings);

// Fills the empty texels next to filled ones (8 neighbours, their mean) `passes` times, each pass one texel further; the new texels get kBakeDilated.
// Returns how many it filled. rgb is width * height * 3, mask width * height.
std::size_t dilate_texels(int width, int height, std::vector<float>& rgb, std::vector<std::uint8_t>& mask, int passes);

// The atlas side (a power of two, 16..maxSize) that gives about `texelsPerMeter` on surfaces of `surfaceArea` square meters in total (the
// pieces of an atlas fill about two thirds of it). A helper for the caller that has to choose a size.
int suggest_atlas_size(double surfaceArea, double texelsPerMeter, int maxSize);

// A 64-bit hash of every size, mask byte and float bit of the result (the tests and the logs compare bakes with it).
std::uint64_t hash_bake_result(const BakeResult& result);

// ---- light probes -------------------------------------------------------------------------------------------------------------------

// The RADIANCE around a point as real spherical harmonics, bands 0..2 (nine coefficients; the first four are the L1 probe). Order:
// Y00, Y1-1 (y), Y10 (z), Y11 (x), Y2-2 (xy), Y2-1 (yz), Y20 (3z^2 - 1), Y21 (xz), Y22 (x^2 - y^2), with the usual constants.
struct ShL2 {
    Vec3 c[9]{};
};
// The diffuse light (in the units above: irradiance / pi) a surface with this normal receives from the probe: the radiance convolved with
// the clamped cosine (bands scaled 1, 2/3, 1/4). A constant sky of radiance L gives L for every normal.
Vec3 sh_irradiance(const ShL2& sh, Vec3 normal, int bands = 2);

// The nine real SH basis functions of the order above at a unit direction (`y[k]` multiplies `ShL2::c[k]`). The ONE definition of the basis:
// the sky's spherical harmonics (render: the diffuse ambient of a sky material, a physical sky or an HDRI; shaders/env.glsl, mesh_common.glsl
// fa_sh_eval) are computed and evaluated with the same constants, so a probe and the sky are interchangeable.
void sh_basis(Vec3 direction, float out[9]);

// The projection of a cube map onto ShL2, the CPU twin of the GPU pass that bakes the sky's SH (env.glsl, fs_sh): `rgb` holds the six faces
// (+X -X +Y -Y +Z -Z, the cube map specification's layout, row 0 at the top), each `size` x `size` texels of three floats, linear radiance.
// Every texel is weighted by its solid angle and the weights are normalised to the sphere's 4 pi, so a constant sky of radiance L gives
// c[0] = L * sqrt(4 pi) exactly and sh_irradiance() gives L for every normal.
ShL2 sh_project_cube(int size, const float* rgb);

// The spherical harmonics of the light around each point, from the same tracer as the lightmap: `samples` directions over the sphere, each
// traced with the bounces of `settings`; plus the direct light of the Baked lights when settings.shIncludeDirect. Progress and cancel as
// bake_lightmap. The scene's atlases are not used (a scene with meshes that have no atlas is fine).
Result<std::vector<ShL2>> sample_irradiance_sh(const BakeScene& scene, const std::vector<Vec3>& points,
                                               const BakeSettings& settings);

}  // namespace fa
