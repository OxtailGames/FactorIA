// The 2D global illumination field (M74-P3a; docs/design/ARCHITECTURE_RENDERING_GI2D.md, "2D GI field: what P3b reads"): per 2D camera
// job, a screen-aligned grid of "field texels" that covers the view plus a margin of GlobalIllumination2D.range, and three RGBA16F images
// of it: the emission, the occluders (albedo and occupancy) and the distance to the nearest occluder (jump flooding). M74-P3b adds the
// radiance cascades that read them (a second jump-flooding chain over the emission, one pass per cascade, merged top-down) and the
// irradiance image they make, which the lit 2D visuals sample (quad_common.glsl, "gi").
//
//   gi2d_cascade_plan  the quality's deterministic counts for a field (cascades, probe spacing, rays, steps) and the platform budget
//
//   gi2d_settings   the scene's GlobalIllumination2D (the first enabled one, numbers clamped)
//   gi2d_geometry   the size, texel size and world rectangle of a camera's field (pure: no GPU, no World)
//   gi2d_gather     the CPU side: emitters and occluders of the field's rectangle as vertices in field texel coordinates
//   Gi2dSystem      the GPU side: shaders, pipelines, the persistent images of each field slot and the passes that fill them
//
// A frame without an enabled GlobalIllumination2D (or on a GPU without RGBA16F targets) declares no pass and makes no image; the slots (the
// field's own images and the irradiance) are freed at the start of the frame graph's run when no job asked for them (Gi2dSystem::free_unused).
// The transient images of the passes (jump flooding, the cascades) live in the frame graph's TargetPool, which keeps a free target for a few
// frames (TargetPool maxIdleFrames, 4) before it destroys it: the memory of the last field is released a few frames after GI turns off.
#pragma once

#include <algorithm>
#include <array>
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/math.h"
#include "fa/scene/components.h"
#include "fa/scene/world.h"

#include "frame_graph.h"
#include "render_internal.h"
#include "transient_targets.h"

namespace fa::render {

struct Frame;

// The largest side of a field in texels. A seed's coordinates travel in RGBA16F, whose integers are exact up to 2048.
inline constexpr int kGi2dMaxSize = 2048;
// A field's sides are multiples of this (the largest probe spacing of any quality), so one cascade image holds a whole number of probes and
// the size does not change with every texel a zoom adds: a field only grows by one step at a time.
inline constexpr int kGi2dSizeStep = 32;
inline constexpr int kGi2dMinSize = kGi2dSizeStep;
// Fields per frame (one per 2D camera job): the cameras after these get none.
inline constexpr int kGi2dMaxFields = 4;
// The most quads a field's emission pass or its occluder pass draws: what is over the limit is left out and counted.
inline constexpr int kGi2dMaxQuads = 60000;
// The images of one field that are alive together at the most, counted in field-sized RGBA16F images: emission, occluders and distance (they
// stay), the jump-flooding images of a chain in flight (3), the emitter distance and two cascades.
inline constexpr int kGi2dFieldImages = 8;
// What a field may take on a desktop GPU (a 2048 x 2048 field with its irradiance images is just under it) and on a phone or a browser.
inline constexpr std::uint64_t kGi2dMaxBytes = std::uint64_t(320) << 20;
inline constexpr std::uint64_t kGi2dMaxBytesMobile = std::uint64_t(96) << 20;
// What the fields of ALL the 2D cameras of a frame may take together (each field is also checked against kGi2dMaxBytes on its own): a
// frame with four cameras of 300 MiB would otherwise ask for 1.2 GiB. A phone or a browser has one budget for all of them.
inline constexpr std::uint64_t kGi2dMaxTotalBytes = std::uint64_t(640) << 20;
inline constexpr std::uint64_t kGi2dMaxTotalBytesMobile = kGi2dMaxBytesMobile;
// The most a bounce can give back: `bounce` is capped here, and the albedo of a blocker at 1, so the light that circulates in a closed room
// (every ray ends on a wall, the history is last frame's irradiance) gets at most this factor each frame and the sum E / (1 - gain) is finite.
inline constexpr float kGi2dMaxBounceGain = 0.95f;
// The most point-in-triangle tests one gather spends on cutting ShadowCaster2D polygons (a count, never a time: the same on every machine),
// and the most corners one polygon has.
inline constexpr std::size_t kGi2dMaxTriangulateWork = 2000000;
inline constexpr std::size_t kGi2dMaxPolygonPoints = 512;
// The most cascades a field has (one pass each, spacing S0 * 2^i up to kGi2dSizeStep), and the most a phone or a browser pays for.
inline constexpr int kGi2dMaxCascades = 5;
inline constexpr int kGi2dMaxCascadesMobile = 4;
// What the distance image holds in `b` where the field has no occluder at all (and `a` is 0).
inline constexpr float kGi2dNoDistance = 65504.0f;

// GlobalIllumination2D after clamping; `on` is false without an enabled component.
struct Gi2dSettings {
    bool on = false;
    GI2DQuality quality = GI2DQuality::Medium;
    float intensity = 1.0f;
    float bounce = 0.5f;
    float range = 512.0f;
    float resolutionScale = 0.5f;
};
// The first enabled GlobalIllumination2D of the world, with every number inside its documented range (a NaN becomes the default).
Gi2dSettings gi2d_settings(World& world);

// Where a field is. Texel (i, j) is the world square [originX + i * texel, +texel] x [originY + j * texel, +texel]: row j = 0 is the
// SMALLEST world y on every backend.
struct Gi2dGeometry {
    bool valid = false;
    int width = 0, height = 0;  // field texels
    double texel = 1.0;         // world units per texel (a float's value)
    // World x of the left edge of texel column 0 and world y of the lower edge of texel row 0. Each is a multiple of `texel` once the
    // floating origin is added (World::origin()); in local coordinates it is that minus the origin.
    double originX = 0.0;
    double originY = 0.0;
    bool capped =
        false;  // the area asked for was over kGi2dMaxSize texels a side: the texels are larger than resolutionScale says
    std::uint64_t bytes =
        0;  // the field's memory: kGi2dFieldImages images of its size (saturating); the irradiance images come on top
    double world_w() const { return double(width) * texel; }
    double world_h() const { return double(height) * texel; }
};
// The field of a camera that sees `visible` (world units) with `pixelsPerUnit` physical pixels per world unit: the texel is
// 1 / (pixelsPerUnit * resolutionScale) world units (larger when the margin makes the area exceed kGi2dMaxSize texels), the size is
// ceil((visible + 2 * range) / texel) + 2 texels a side, rounded UP to a multiple of kGi2dSizeStep, and the origin is the lower-left corner snapped DOWN to a multiple of the texel, so a
// camera that moves by less than a texel moves the field by 0 or by whole texels and nothing in it swims. The size depends on the view's
// size and the settings only, never on where the camera is. valid == false for a view without a size.
// `originX/originY` (M75.4b, World::origin(): the floating origin in world units, 0 without one): the texel grid is fixed in ABSOLUTE
// space, so the origin of the field (local) is a multiple of the texel once the floating origin is added, and a rebase (every local position and
// the origin move by the same exact amount) moves the field by a whole number of texels, whatever the texel size.
Gi2dGeometry gi2d_geometry(const Rect& visible, float pixelsPerUnit, const Gi2dSettings& s, double originX = 0.0,
                           double originY = 0.0);

// What a GI quality means, as counts (M74-P3b; docs/rendering/RENDERING_2D_GI.md): the same on every machine, never a time.
//   spacing0   the probe spacing of cascade 0 in field texels; cascade i has spacing0 * 2^i and spacing^2 rays a probe, so each cascade has
//              four times the rays of the one below and a field-sized image whatever its spacing
//   cascades   how many (the plan uses fewer when the field is small: the last interval already covers its diagonal)
//   steps      the most sphere-tracing steps a ray takes
// Cascade i covers the distance (in texels from its probe) from end(i - 1) to end(i), end(i) = 2 * spacing0 * (4^(i + 1) - 1) / 3.
struct Gi2dQualityCounts {
    int spacing0, cascades, steps;
};
Gi2dQualityCounts gi2d_quality_counts(GI2DQuality q);
struct Gi2dCascadePlan {
    bool ok = false;   // false: the field is not valid or the plan is over the platform's budget (`why` says what)
    int spacing0 = 0;  // cascade 0's probe spacing in texels
    int cascades = 0;  // passes: one per cascade
    int steps = 0;     // sphere-tracing steps per ray at the most
    int rays0 = 0;     // rays per probe of cascade 0 (spacing0 squared)
    int gridW = 0, gridH = 0;           // cascade 0's probes (the irradiance image's size)
    double reach = 0.0;                 // texels: the end of the last interval
    std::uint64_t persistentBytes = 0;  // the three field images and the two irradiance images
    std::uint64_t totalBytes =
        0;            // persistent plus the images alive during the frame (kGi2dFieldImages field-sized ones)
    std::string why;  // a teaching sentence when !ok
    double interval_start(int i) const;
    double interval_end(int i) const;
};
// The cascade plan of a field for a quality. `mobile` picks the smaller budget (a phone or a browser). Pure: no GPU.
Gi2dCascadePlan gi2d_cascade_plan(GI2DQuality q, const Gi2dGeometry& g, bool mobile);
// The budget of all the fields of a frame: `usedBytes` is what the fields planned so far take (Gi2dCascadePlan::totalBytes), `plan` the next one.
// Empty when it fits, else a teaching sentence (the sum is made in 64 bits with saturation). Pure: no GPU.
std::string gi2d_total_budget_why(std::uint64_t usedBytes, const Gi2dCascadePlan& plan, bool mobile);

// One vertex of the gather: a position in field texel coordinates (0..width, 0..height), a texture coordinate (a disc: the offset from
// its centre in radii) and a colour (what the mode of the batch does with it: gi2d.glsl).
struct GiVertex {
    float x, y, u, v;
    float r, g, b, a;
};
// A run of vertices (triangles) drawn with one program state.
struct GiBatch {
    int mode =
        0;  // gi2d.glsl: 0 map emission, 1 solid, 2 disc, 3 alpha-shaped emission, 4 opaque textured, 5 alpha-tested
    TextureAsset* tex = nullptr;  // null: the batch samples nothing (modes 1 and 2)
    SamplerKind sampler = SamplerKind::Nearest;
    int fix = 0;             // TextureAsset::tex_fix
    float threshold = 0.0f;  // mode 5
    std::uint32_t first = 0, count = 0;
};
// The counts of what gi2d_gather found for one field.
struct Gi2dCounts {
    int emissiveSprites = 0, emissiveTiles = 0, lights = 0;          // emitters drawn (tiles: cells)
    int solidTiles = 0, boxes = 0, polygons = 0, spriteCasters = 0;  // occluders drawn
    int skippedCasters =
        0;  // a ShadowCaster2D that cannot be drawn: spriteAlpha without a Sprite, a polygon with fewer than 3 points
    int dropped = 0;  // quads left out over kGi2dMaxQuads
};
struct Gi2dGather : Gi2dCounts {
    std::vector<GiVertex> emitVerts, occVerts;
    std::vector<GiBatch> emitBatches, occBatches;
};
// The emitters and occluders that touch the field's rectangle, for the camera of `fr`. Sprites and tilemaps are read as the frame draws
// them (Camera.showTags / hideTags, Tint, drawn pose); a Sprite emits when its emissive colour is not black (lit or not, as on screen); a Light2D
// (point, any radius) is a disc of radius max(size, one texel).
void gi2d_gather(World& world, Frame& fr, const Gi2dGeometry& g, Gi2dGather& out);
// The triangles (indices into `pts`, 3 per triangle) of a simple polygon given as [x0, y0, x1, y1, ...], either winding, by ear clipping.
// A polygon that cannot be cut (fewer than 3 points, more than kGi2dMaxPolygonPoints, non-finite or a zero area) gives none; one with crossing
// edges gives what could be cut. `work` (optional) is what is left of the gather's budget of point-in-triangle tests: it is spent as the
// polygon is cut and the cutting stops (with what is cut so far) when it reaches 0; null: kGi2dMaxTriangulateWork for this polygon alone.
std::vector<std::uint32_t> gi2d_triangulate(const std::vector<Vec2>& pts, std::size_t* work = nullptr);

// What the frame graph needs of one job's field (set by plan_job, read by the passes and by P3b).
struct Gi2dField;
struct Gi2dJobPlan {
    bool active = false;
    Gi2dField* field = nullptr;
    std::shared_ptr<Gi2dGather> gather;
    gpu::View white{};  // a texture view the draws of a batch without a texture bind
    ResourceId emission, occluder,
        distance;  // imported: the images outlive the frame graph (P3b and the command read them)
    // The result of the cascades (cascadePasses > 0): the irradiance image the lit visuals of the job sample, and where the world is in it.
    ResourceId irradiance;
    gpu::View irradianceView{};  // the image written this frame (null without cascades)
    float xf[4] = {0, 0, 0, 0};  // image uv = world * xf.xy + xf.zw
    float intensity = 0.0f;      // GlobalIllumination2D.intensity
    int cascadePasses = 0;       // the passes of the cascades, the priming chain and the irradiance pass
};

// The images and numbers of one field slot. `valid` is true once the passes of a frame filled it.
struct Gi2dField {
    Target emission, occluder, distance;
    Target irradiance
        [2];  // the probes of cascade 0 as one image, written alternately (the one not written is last frame's)
    Gi2dCascadePlan cascade;
    int irrCur = 0;         // the index of the irradiance image written by the last frame that ran
    bool irrValid = false;  // irradiance[irrCur] holds a finished frame whose geometry is histTexel / histOrigin*
    double histTexel = 0.0, histOriginX = 0.0, histOriginY = 0.0;
    Gi2dGeometry geom;
    Gi2dSettings settings;
    std::string job;  // the job of the camera it was last drawn for ("camera:0")
    // The job the irradiance history was made for: another job taking the slot starts from the priming chain.
    std::string histJob;
    // The bits of the Camera entity of the last job drawn in this slot.
    std::uint64_t camera = 0;
    // The Camera entity the irradiance history was made for (with histJob).
    std::uint64_t histCamera = 0;
    bool used = false;    // asked for in this frame (begin_frame clears it)
    bool valid = false;   // the passes ran: the images hold a finished field
    int passes = 0;       // the passes of the last frame (emission, occluders, seed, jump steps, cascades, irradiance)
    bool primed = false;  // the last frame ran the priming chain (no history to bounce from)
    Gi2dCounts stats;     // what the last gather found
};

class Gi2dSystem {
public:
    Gi2dSystem() = default;
    Gi2dSystem(const Gi2dSystem&) = delete;
    Gi2dSystem& operator=(const Gi2dSystem&) = delete;

    // Whether this GPU can draw the field: RGBA16F render targets that blend and filter (the rule of FeatureEnv::halfTargets).
    static bool float_targets_ok(const gpu::Device& device);
    // The same on the device of Gpu::active() (TRANSITIONAL, M77: false when no Gpu is alive).
    static bool float_targets_ok();

    // Start of a frame graph: no slot is asked for yet. `keep` (a capture that draws no 2D camera of the game): the slots stay as they were.
    void begin_frame(bool keep);
    // The slot `n` (0 .. kGi2dMaxFields - 1) for `g`: its three images, made (again) when the size changed. Null when the GPU cannot make
    // them (logged once). Marks the slot as used by this frame.
    // Also makes the irradiance images of `cp` (the history of the bounce is dropped when any size changes).
    Gi2dField* acquire(gpu::Device& device, int n, const Gi2dGeometry& g, const Gi2dCascadePlan& cp);
    // The same on the device given before, or on Gpu::active_device() (TRANSITIONAL, M77: the callers not converted yet).
    Gi2dField* acquire(int n, const Gi2dGeometry& g, const Gi2dCascadePlan& cp);
    // Before the frame graph runs: frees the slots no job asked for (a frame without GI keeps no image) and counts the ones that were.
    void free_unused();
    // Destroys every image, shader and pipeline (the graphics context is still open).
    void release();
    // Destroys the images only (the render targets were resized).
    void free_images();
    // M75.4b, a rebase of the floating origin: every local world position moved by -(dx, dy), so the geometry and the history origin of
    // every field do too. The images are kept (the bounce keeps its history); the geometry of the next frame is snapped in absolute space
    // (gi2d_geometry), so the history shift it finds is the one of the camera alone.
    void shift(double dx, double dy);
    // How many rebases shift() has followed (a test reads it).
    std::uint64_t shifts() const { return shifts_; }

    // One field's passes, declared in `graph` in the order they run: emission, occluders, seed, then the jump-flooding steps, the last of
    // which writes the distance image; then the same chain over the emission, the cascades from the top down (a priming chain first when
    // the bounce has no history) and the irradiance image. `name` is the job's name; the callbacks use `plan` (the field and the gather) and `gpu`; each pass adds
    // one to *drawCalls per draw. Fills plan.emission / occluder / distance. Returns the number of passes declared (0: shaders or targets
    // the GPU cannot make; logged once).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, Gi2dJobPlan& plan, const std::string& name,
                   int* drawCalls);

    // The report of `render.gi2d_field`: whether GI is on and supported, and every field of the last frame (no GPU read).
    Json report(const std::string& backend) const;
    // The settings of the last job planned (`on` false when the scene has no enabled GlobalIllumination2D) and whether a frame asked for
    // fields at all: what the report says about the state of the feature.
    Gi2dSettings lastSettings;
    // The slot a field was drawn in whose job is `job` (null: none, or `job` is empty and none exists: the first valid one).
    Gi2dField* find(const std::string& job);
    Gi2dField* slot(int n) { return n >= 0 && n < kGi2dMaxFields ? slots_[std::size_t(n)].get() : nullptr; }
    int slot_count() const { return kGi2dMaxFields; }

    // The programs and their pipelines for a target format (made on first use; null when it cannot be made). Used by the passes.
    enum class Prog { DrawAdd, DrawReplace, Seed, Jfa, SeedEmit, Cascade, Irradiance, Count };
    bool ready(gpu::Device& device);
    gpu::Pipeline pipeline(Prog prog, const TargetFormat& format);

    // Teaching message of a GPU without float targets, logged once; returns the sentence (also for the command).
    static std::string unsupported_message(const std::string& backend);
    // The warnings already logged (each once per reason): `budgetWhys` holds the sentences of the budget warnings already said (several
    // cameras can fail for different reasons in one frame; a new reason, such as another quality, range or size, warns again).
    // reset_warnings runs when no job of a frame asked for GI (see note_gi_asked), and when the images are freed.
    bool warned_unsupported = false, warned_dropped = false;
    std::vector<std::string> budgetWhys;
    // True the first time `why` is seen since the last reset (the caller logs it); bounded, so reasons that keep changing cannot grow it.
    static constexpr std::size_t kMaxBudgetWhys = 16;
    // The sentence to add to the warning when the last stored reason filled the list (the later ones are not logged).
    static const char* budget_limit_note() {
        return " Further budget reasons are not logged until the GI images are freed.";
    }
    bool lastWasLimit = false;  // set by budget_warn_once when it stored the last reason that fits
    bool budget_warn_once(const std::string& why) {
        if (std::find(budgetWhys.begin(), budgetWhys.end(), why) != budgetWhys.end() ||
            budgetWhys.size() >= kMaxBudgetWhys)
            return false;
        budgetWhys.push_back(why);
        lastWasLimit = budgetWhys.size() == kMaxBudgetWhys;
        return true;
    }
    // A job of this frame has an enabled GlobalIllumination2D. begin_frame(false) resets the warnings when the frame before had none, so a
    // frame that mixes a job with GI and one without keeps its warnings.
    void note_gi_asked() { giAsked_ = true; }
    void reset_warnings() {
        warned_unsupported = warned_dropped = false;
        budgetWhys.clear();
        lastWasLimit = false;
    }

private:
    bool giAsked_ = false;
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    std::array<std::unique_ptr<Gi2dField>, kGi2dMaxFields> slots_;
    std::uint64_t shifts_ = 0;
    gpu::Shader shaders_[6]{};  // draw, seed, jfa, seed_emit, cascade, irradiance
    gpu::Device* device_ =
        nullptr;  // the device the images, shaders and pipelines were made on (set by acquire / ready)
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool warnedTargets_ = false;
};

// Reads a field's image back as floats, texture row 0 first (the smallest world y), 4 floats per texel. False + `error` when the GPU
// cannot. The work recorded so far must have been committed by the caller.
bool gi2d_read(const Target& t, bool isGl, std::vector<float>& out, std::string* error);

}  // namespace fa::render
