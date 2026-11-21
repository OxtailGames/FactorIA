// The 2D global illumination field (M74-P3a; docs/design/ARCHITECTURE_RENDERING_GI2D.md, "2D GI field: what P3b reads"): per 2D camera
// job, a screen-aligned grid of "field texels" that covers the view plus a margin of GlobalIllumination2D.range, and three RGBA16F images
// of it: the emission, the occluders (albedo and occupancy) and the distance to the nearest occluder (jump flooding). The cascades of
// P3b read them; nothing here lights anything.
//
//   gi2d_settings   the scene's GlobalIllumination2D (the first enabled one, numbers clamped)
//   gi2d_geometry   the size, texel size and world rectangle of a camera's field (pure: no GPU, no World)
//   gi2d_gather     the CPU side: emitters and occluders of the field's rectangle as vertices in field texel coordinates
//   Gi2dSystem      the GPU side: shaders, pipelines, the persistent images of each field slot and the passes that fill them
//
// A frame without an enabled GlobalIllumination2D (or on a GPU without RGBA16F targets) declares no pass, makes no image and keeps no
// memory: the slots are freed at the start of the frame graph's run when no job asked for them (Gi2dSystem::free_unused).
#pragma once

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
inline constexpr int kGi2dMinSize = 8;
// Fields per frame (one per 2D camera job): the cameras after these get none.
inline constexpr int kGi2dMaxFields = 4;
// The most quads a field's emission pass or its occluder pass draws: what is over the limit is left out and counted.
inline constexpr int kGi2dMaxQuads = 60000;
// The memory of one field (three images of the field's size and the two a jump-flooding step reads and writes): never reached, as the
// size is capped (5 x 2048 x 2048 x 8 bytes), the check is there so that a change of the caps cannot allocate without a look.
inline constexpr std::uint64_t kGi2dMaxBytes = std::uint64_t(256) << 20;
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
    double originX = 0.0;       // world x of the left edge of texel column 0 (a multiple of `texel`)
    double originY = 0.0;       // world y of the lower edge of texel row 0 (a multiple of `texel`)
    bool capped =
        false;  // the area asked for was over kGi2dMaxSize texels a side: the texels are larger than resolutionScale says
    std::uint64_t bytes = 0;  // the field's memory (saturating)
    double world_w() const { return double(width) * texel; }
    double world_h() const { return double(height) * texel; }
};
// The field of a camera that sees `visible` (world units) with `pixelsPerUnit` physical pixels per world unit: the texel is
// 1 / (pixelsPerUnit * resolutionScale) world units (larger when the margin makes the area exceed kGi2dMaxSize texels), the size is
// ceil((visible + 2 * range) / texel) + 2 texels a side and the origin is the lower-left corner snapped DOWN to a multiple of the texel, so a
// camera that moves by less than a texel moves the field by 0 or by whole texels and nothing in it swims. The size depends on the view's
// size and the settings only, never on where the camera is. valid == false for a view without a size.
Gi2dGeometry gi2d_geometry(const Rect& visible, float pixelsPerUnit, const Gi2dSettings& s);

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
// A polygon that cannot be cut (fewer than 3 points, non-finite or a zero area) gives none; one with crossing edges gives what could be cut.
std::vector<std::uint32_t> gi2d_triangulate(const std::vector<Vec2>& pts);

// What the frame graph needs of one job's field (set by plan_job, read by the passes and by P3b).
struct Gi2dField;
struct Gi2dJobPlan {
    bool active = false;
    Gi2dField* field = nullptr;
    std::shared_ptr<Gi2dGather> gather;
    sg_view white{};  // a texture view the draws of a batch without a texture bind
    ResourceId emission, occluder,
        distance;  // imported: the images outlive the frame graph (P3b and the command read them)
};

// The images and numbers of one field slot. `valid` is true once the passes of a frame filled it.
struct Gi2dField {
    Target emission, occluder, distance;
    Gi2dGeometry geom;
    Gi2dSettings settings;
    std::string job;     // the job of the camera it was last drawn for ("camera:0")
    bool used = false;   // asked for in this frame (begin_frame clears it)
    bool valid = false;  // the passes ran: the images hold a finished field
    int passes = 0;      // the passes of the last frame (emission, occluders, seed, jump steps)
    Gi2dCounts stats;    // what the last gather found
};

class Gi2dSystem {
public:
    Gi2dSystem() = default;
    Gi2dSystem(const Gi2dSystem&) = delete;
    Gi2dSystem& operator=(const Gi2dSystem&) = delete;

    // Whether this GPU can draw the field: RGBA16F render targets that blend and filter (the rule of FeatureEnv::halfTargets).
    static bool float_targets_ok();

    // Start of a frame graph: no slot is asked for yet. `keep` (a capture that draws no 2D camera of the game): the slots stay as they were.
    void begin_frame(bool keep);
    // The slot `n` (0 .. kGi2dMaxFields - 1) for `g`: its three images, made (again) when the size changed. Null when the GPU cannot make
    // them (logged once). Marks the slot as used by this frame.
    Gi2dField* acquire(int n, const Gi2dGeometry& g);
    // Before the frame graph runs: frees the slots no job asked for (a frame without GI keeps no image) and counts the ones that were.
    void free_unused();
    // Destroys every image, shader and pipeline (the graphics context is still open).
    void release();
    // Destroys the images only (the render targets were resized).
    void free_images();

    // One field's passes, declared in `graph` in the order they run: emission, occluders, seed, then the jump-flooding steps, the last of
    // which writes the distance image. `name` is the job's name; the callbacks use `plan` (the field and the gather) and `gpu`; each pass adds
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
    enum class Prog { DrawAdd, DrawReplace, Seed, Jfa, Count };
    bool ready();
    sg_pipeline pipeline(Prog prog, const TargetFormat& format);

    // Teaching message of a GPU without float targets, logged once; returns the sentence (also for the command).
    static std::string unsupported_message(const std::string& backend);
    bool warned_unsupported = false, warned_dropped = false;

private:
    struct PipelineEntry {
        Prog prog;
        TargetFormat format;
        sg_pipeline pipeline;
    };
    std::array<std::unique_ptr<Gi2dField>, kGi2dMaxFields> slots_;
    sg_shader shaders_[3]{};  // draw, seed, jfa
    std::vector<PipelineEntry> pipelines_;
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    bool warnedTargets_ = false;
};

// Reads a field's image back as floats, texture row 0 first (the smallest world y), 4 floats per texel. False + `error` when the GPU
// cannot. The work recorded so far must have been committed by the caller.
bool gi2d_read(const Target& t, bool isGl, std::vector<float>& out, std::string* error);

}  // namespace fa::render
