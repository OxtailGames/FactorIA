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
#include <functional>
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
    // area: the direction of `height` (the rectangle's own up, projected onto its plane); width runs along cross(direction, up). (0, 0, 0) = any
    // (a square or round light does not care; a long one needs it). Must be finite.
    Vec3 up{0, 0, 0};
};

// An equirectangular float image of the sky (a Radiance .hdr read by the caller): u = 0.5 + atan2(z, x) / 2 pi, v = acos(y) / pi,
// row 0 up, linear RGB, three floats per pixel. When it has pixels it replaces the gradient.
struct BakeEquirect {
    int width = 0, height = 0;
    std::vector<float> rgb;
    float rotationDeg = 0;  // turns the image around +Y (degrees, finite)
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
        0.3f;  // how different two neighbours may be (relative to the light) and still be blended, 0.01..10
    float rayEpsilon =
        0;  // the offset of a ray from its surface (meters); 0 = automatic: the scene's size / 10000, but never more than 1 cm
    // (kMaxAutoRayEpsilon), and the lightmap bake lowers that to 1/20 of a texel (a 1 km scene with 16 texels per meter gets 3 mm) but
    // never below 1/50 of what the cap left (size / 500000, or 0.2 mm when the 1 cm cap applied). A value you set is used as it is.
    bool shIncludeDirect =
        true;  // sample_irradiance_sh: add the direct light of the Baked lights (a probe is not a lightmap texel)
    // sample_probes: a probe is invalid (inside geometry) when more than this fraction of its rays first hit a BACK face (0..1).
    float probeBackfaceTolerance = 0.25f;
    // Budgets: the bake refuses (with what to change) before it allocates or traces anything beyond them.
    int maxAtlasSize = 4096;                    // the largest width or height of an atlas (the texel density cap)
    std::uint64_t maxMemoryBytes = 1ull << 30;  // what the bake may allocate (an estimate with a margin)
    // An upper bound on the rays: texels x samples x (bounces + 1) x (lights + 1). The default is a safety net, not a time budget: one core
    // traces very roughly 2-10 million rays per second in a scene of a few thousand triangles (less with more triangles), the job pool
    // multiplies that by its workers. So 1e9 rays are minutes, the default 5e10 are hours: lower it to give a bake a time limit.
    std::uint64_t maxRays = 50000000000ull;
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

// The phases of a bake, in order (the atlas ones repeat for every atlas).
enum class BakePhase : std::int32_t {
    Prepare,    // validating, flattening the scene, building the BVH
    Rasterize,  // which triangle covers which texel of an atlas
    Trace,      // the rays of the texels
    Denoise,    // the edge-aware blur
    Dilate,     // the gutter
    Probes      // the light probes (sample_probes): `done` of `total` probes
};
// A progress report: `done` of `total` units of the phase (texels for Trace and Denoise, atlases for Rasterize and Dilate, 0 / 0 for Prepare);
// `atlas` of `atlasCount` is 1-based (0 for Prepare); `rays` counts the rays traced so far, over every atlas.
struct BakeProgress {
    BakePhase phase = BakePhase::Prepare;
    int atlas = 0, atlasCount = 0;
    std::uint64_t done = 0, total = 0;
    std::uint64_t rays = 0;
};
// Called on the thread that runs the bake, at the start of every phase and after each batch of texels (about 40 per atlas): it must be fast.
using BakeProgressFn = std::function<void(const BakeProgress&)>;

// ---- a device that traces the texels (the GPU bake) ---------------------------------------------------------------------------------

// A light as the tracer sees it: the BakeLight of the scene made ready (colour times intensity, unit vectors, the cosines of the spot's cone).
// Only the lights the bake keeps (mode Baked or IndirectOnly) are listed.
struct BakeTraceLight {
    BakeLightKind kind = BakeLightKind::Directional;
    bool direct = false;  // lights the texels (mode Baked)
    bool bounce = true;   // lights the surfaces the paths hit
    BakeFalloff falloff = BakeFalloff::Engine;
    Vec3 color{};        // colour * intensity
    Vec3 position{};     // point, spot, area (the centre)
    Vec3 direction{};    // unit: directional, spot, area
    Vec3 right{}, up{};  // area: the rectangle's axes (unit)
    float range = 0;
    float cosOuter = 0, cosInner = 0;  // spot (cosInner 0 = the realtime rule)
    float softRadius = 0;              // point, spot
    float tanSoft = 0;                 // directional: tan of the sun's angular radius, 0 = a hard sun
    float width = 1, height = 1;       // area
};

// The flattened scene the bake traces in, as bake_lightmap prepared it: the triangles that cast a shadow (every mesh in order, the ones with
// castsShadow = false and the degenerate triangles left out) with what a ray that hits one needs, the lights, the sky and the numbers of the
// settings. Valid for the call of BakeTexelTracer::begin only: a tracer copies what it keeps.
struct BakeTraceScene {
    std::vector<Vec3> casterCorners;  // three per caster triangle, world space
    std::vector<Vec3>
        casterNormal;  // the unit face normal of each caster (either side: the tracer turns it toward the ray)
    std::vector<Vec3> casterAlbedo;  // the material of each caster
    std::vector<Vec3> casterEmissive;
    std::vector<BakeTraceLight> lights;
    const BakeSky* sky = nullptr;
    float eps = 0;  // the offset of a ray from its surface (meters), as the CPU baker uses it
    int samples = 64, bounces = 2, shadowSamples = 4;
};

// One texel to trace: where it is, the normal its light is gathered around, the face normal it is offset along, and its index in the atlas
// (the random numbers are a hash of the atlas key and this index, as in the CPU baker).
struct BakeTraceTexel {
    Vec3 position, shadingNormal, faceNormal;
    std::uint32_t index = 0;
};

// Called by a tracer after each batch of texels it finished (`done` of `texels.size()`); false = stop (the bake was cancelled): the tracer
// returns an error and its output is dropped. The callback reports the progress and looks at the cancel flag.
using BakeTraceProgressFn = std::function<bool(std::uint64_t done)>;

// A device that traces the light of the texels in place of the CPU path tracer (bake_lightmap's `tracer`; the GPU lightmap bake,
// fa/render/lightmap_gpu_bake.h). The rest of the bake (rasterizing the atlases, the denoise, the gutter) stays the CPU's. A tracer is used
// from one thread, the one that calls bake_lightmap.
class BakeTexelTracer {
public:
    virtual ~BakeTexelTracer() = default;
    // Called once, after the scene is flattened and the budgets are checked: build whatever the device needs. An error ends the bake with it.
    virtual Result<void> begin(const BakeTraceScene& scene) = 0;
    // The value of every texel of one atlas: `rgb` gets 3 floats per entry of `texels`, the direct light of its Baked lights plus the mean of
    // the gather rays, the number the CPU path computes for it (up to the device's rounding). `atlasKey` is the key of the atlas (the CPU baker's
    // hash of seed and atlas number): a texel's random numbers come from combine(atlasKey, texel.index).
    virtual Result<void> trace_atlas(std::uint64_t atlasKey, const std::vector<BakeTraceTexel>& texels,
                                     const BakeTraceProgressFn& progress, std::vector<float>& rgb) = 0;
};

// Bakes the lightmaps. Progress goes to report_command_progress() ("lightmap bake: atlas 1/2, texels 2048/4096 (50%)") after each batch of
// texels, and to `progress` when given; a cancelled command (command_cancelled()) ends it with the error "cancelled" and no result. Cancel is
// looked at in every phase: while the BVH is built (once per tree node), while the atlases are rasterized (every 256 triangles), inside every
// chunk of rays, and while the gutter is filled (every row).
//
// With a `tracer` the texels are traced by it instead of the CPU path tracer (the result is then close to the CPU's, not the same bits);
// everything else, the validation, the budgets, the progress phases, the cancel and the denoise and the gutter, is the same. `BakeStats::rays`
// is then the upper bound of the budget check (the device does not count).
Result<BakeResult> bake_lightmap(const BakeScene& scene, const BakeSettings& settings,
                                 const BakeProgressFn& progress = {}, BakeTexelTracer* tracer = nullptr);

// Fills the empty texels next to filled ones (8 neighbours, their mean) `passes` times, each pass one texel further; the new texels get kBakeDilated.
// Returns how many it filled. rgb is width * height * 3, mask width * height.
// Looks at command_cancel_flag() once per row: a cancelled call returns early (the caller sees the flag and discards the result).
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

// One baked light probe. `valid` is false when more than settings.probeBackfaceTolerance of its rays first hit a back face: the point is inside
// a closed mesh (a wall, a prop) and sees nothing useful; its `sh` is then all zeros. `backFraction` is that fraction.
struct ProbeSample {
    ShL2 sh;
    float backFraction = 0;
    bool valid = true;
};
// sample_irradiance_sh plus the validity of each probe, and `progress` (phase Probes, done/total probes) after every batch. Same seeds, same
// bytes on any thread count.
Result<std::vector<ProbeSample>> sample_probes(const BakeScene& scene, const std::vector<Vec3>& points,
                                               const BakeSettings& settings, const BakeProgressFn& progress = {});

}  // namespace fa
