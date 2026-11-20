// The reflection probes' GPU side and the renderer's bookkeeping of them (M73-P3b; docs/design/ARCHITECTURE_PROBES.md says what is where and
// why; include/fa/render/probe.h is the CPU half: the octahedral map, the layout of a tile, the allocator, the scheduler, the files).
//
// ProbeGpu owns the programs (shaders/probe.glsl), the atlas image and the scratch cubes a capture is filtered through:
//
//   capture   the six faces of the scene as seen from the probe, each drawn by an ordinary view job of the frame graph (a 90 degree
//             camera into a square image), are copied by DIRECTION into the faces of the scratch cube S0 (face_to_cube)
//   pyramid   S1 .. S(P-1): each the bilinear down-sampling of the one before (the passes of the sky's pyramid, renderer_env.h)
//   filter    level 0 of the tile is S0 by direction, level k the GGX lobe of roughness k / (levels - 1) read from S_k, the SH row the
//             projection of the 16 x 16 image; every pass draws one rectangle of the atlas (the level with its border, or the nine SH texels)
//
// The scratch cubes belong to a SLOT (the scheduler's set of six face images: the faces of a time-sliced capture accumulate in S0 over
// several frames), and kProbeSlots + 1 exist: the last is the synchronous capture's (probe.bake, tests), which never disturbs a probe that
// is under way. The atlas is RGBA16F, or RGBA8 on a GPU that cannot render to half floats (documented in probe.h).
#pragma once

#include <cstdint>
#include <deque>
#include <map>
#include <string>
#include <vector>

#include "fa/render/gi.h"
#include "fa/render/probe.h"
#include "frame.h"
#include "render_internal.h"

namespace fa {
struct ImageF;
}

namespace fa::render {

inline constexpr int kGiScratchSlot = kProbeSlots + 1;  // the realtime GI's: one probe at a time is filtered through it
inline constexpr int kProbeScratchSlots =
    kProbeSlots + 2;                             // kProbeSlots is the synchronous capture's, the one after it the GI's
inline constexpr int kProbeSyncAtlasSize = 512;  // holds one 256 tile (388 x 259)

// What the plan of a realtime GI capture face tells the graph and gets back (JobPlan::gi, renderer_gi.cpp).
struct GiFacePlan {
    int distIndex = 0;          // the distance picture of the ProbeGpu this face's "gi-distance" pass draws
    float maxDistance = 30.0f;  // GiLayout::maxDistance
    bool drawn = false;  // out: the job declared the pass (the face had opaque meshes and the GPU made the prepass)
};

class ProbeGpu {
public:
    struct Atlas {
        sg_image image{};
        sg_view tex{};  // what a shader samples
        sg_view att{};  // what a pass draws into
        int size = 0;   // the width
        int height =
            0;  // the atlas is size x height: taller than wide while a RealtimeGI's band of blocks is in it (gi.h)
        bool valid() const { return image.id != 0; }
    };

    ProbeGpu() = default;
    ProbeGpu(const ProbeGpu&) = delete;
    ProbeGpu& operator=(const ProbeGpu&) = delete;

    // Makes the programs, pipelines and sampler on first use. False (logged once) when this GPU cannot.
    bool ready();
    sg_pixel_format format() const { return format_; }
    bool rgba8() const { return format_ == SG_PIXELFORMAT_RGBA8; }
    sg_sampler sampler() const { return sampler_; }
    // Tests only: the next ready() makes RGBA8 images (call before ready()).
    static void force_rgba8_for_tests(bool force);

    // A cleared atlas image of size x height (height 0: square). False when the GPU refuses it.
    bool make_atlas(Atlas& atlas, int size, const char* label, int height = 0);
    void destroy_atlas(Atlas& atlas);

    // The scratch cubes of `slot` for maps of `resolution` (made again when the resolution changes). False when the GPU refuses them.
    bool prepare_scratch(int slot, int resolution);
    // Frees the slot's scratch cubes (the synchronous capture's, once it is done).
    void release_slot(int slot) {
        if (slot >= 0 && slot < kProbeScratchSlots) destroy_scratch(scratch_[slot]);
    }

    // Copies the picture of capture face `face` (`picture`: an upright 2D view, row 0 = the top, as the face job drew it) into face `face` of
    // the slot's S0.
    void face_to_cube(Gpu& gpu, int slot, int face, sg_view picture, int* drawCalls);
    // The pyramid, the levels and the SH row of the tile, from the slot's S0. `gain` multiplies the light (ReflectionProbe.intensity).
    void filter(Gpu& gpu, Atlas& atlas, int slot, const ProbeTile& tile, float gain, int* drawCalls);
    // The sky's entry: levels from the lods of the environment cube, the SH row from its mip 5. `envRgba8`: the cube is RGBA8 (its SH is coded).
    void write_sky(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, sg_view envCube, sg_sampler envSampler, bool envRgba8,
                   int* drawCalls);
    // A baked probe: the page (the tile without its SH row) times `gain`, and the nine coefficients times `gain`.
    bool upload(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, const ImageF& page, const float sh[9][3], float gain,
                int* drawCalls);
    // The texels of a rectangle of the atlas as RGBA floats, top row of the rectangle first (RGBA16F only: the atlas as RGBA8 is read as
    // bytes / 255). The work recorded so far must be committed by the caller when the backend needs it (Metal): see Renderer::Impl.
    bool read_region_begin(Gpu& gpu, Atlas& atlas, int x, int y, int w, int h, sg_image& scratch, int* drawCalls);
    static bool read_region_end(sg_image scratch, int w, int h, bool rgba8, std::vector<float>& out,
                                std::string* error);

    // ---- the realtime GI (renderer_gi_gpu.cpp) ----
    // Makes the programs of the GI on first use. False (logged once) when this GPU cannot: it needs RGBA16F images it can blend into.
    bool gi_ready();
    // The distance picture `index` (res x res, RGBA16F: r = the distance of the first hit, g = 1 when it is a back face), made when missing.
    bool dist_image(int index, int res);
    sg_view dist_view(int index) const;
    // "gi-distance": the prepass images of one face (front faces, back faces) into the distance picture `index`.
    void gi_dist(Gpu& gpu, int index, sg_view front, sg_view back, float maxDistance, int* drawCalls);
    // The face of a GI capture into face `face` of the slot's S0: the colour by direction, the signed distance (negative: a back face) in alpha.
    // `dist` invalid: the face has no picture and every ray is maxDistance long.
    void face_gi(Gpu& gpu, int slot, int face, sg_view picture, sg_view dist, float maxDistance, int* drawCalls);
    // Block `block` of the band (gi.h) from the slot's S0: the SH row, the depth map and the meta texel, each blended into what the block holds
    // with weight `blend` (1 replaces it: a probe's first capture; 1 - hysteresis afterwards).
    void filter_gi(Gpu& gpu, Atlas& atlas, int slot, int block, int resolution, float blend, float maxDistance,
                   int* drawCalls);

    void release();

private:
    enum class Prog {
        Face,
        Down,
        OctCube,
        OctGgx,
        Sh,
        ShCube,
        Blit,
        Count,  // Count: the programs ready() makes
        FaceGi = Count,
        GiDist,
        GiDepth,
        GiMeta,
        ShBlend,
        All  // the ones gi_ready() makes (ShBlend: the Sh program that blends)
    };
    struct DistImage {
        sg_image image{};
        sg_view att{}, tex{};
        int size = 0;
    };
    void release_gi();
    int giState_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    sg_sampler nearest_{};
    std::vector<DistImage> dist_;
    struct Scratch {
        int resolution = 0, images = 0;
        sg_image image[kProbeMaxLevels]{};
        sg_view tex[kProbeMaxLevels]{};
        sg_view att[kProbeMaxLevels][6]{};
    };
    void destroy_scratch(Scratch& s);
    void pass_rect(Gpu& gpu, Atlas& atlas, Prog prog, int x, int y, int w, int h, sg_view source, sg_sampler sampler,
                   const float region[4], const float p[4], const float q[4], const float* blit, int* drawCalls);
    void pass_cube(Gpu& gpu, Prog prog, sg_view att, sg_view source, int face, const float camera[12], int* drawCalls);

    int state_ = 0;  // 0 = not made, 1 = ready, -1 = failed (logged)
    sg_pixel_format format_ = SG_PIXELFORMAT_NONE;
    sg_shader shaders_[int(Prog::All)]{};
    sg_pipeline pipelines_[int(Prog::All)]{};
    sg_sampler sampler_{};
    Scratch scratch_[kProbeScratchSlots];
    bool isGl_ = false;
};

// What the renderer keeps of one ReflectionProbe between frames.
struct ProbeEntry {
    Entity entity = kNullEntity;
    std::uint64_t id = 0;  // the allocator's and scheduler's id: the entity's bits
    bool realtime = false;
    ProbeUpdateKind update = ProbeUpdateKind::TimeSliced;
    int resolution = 0, importance = 0;
    ProbeTile tile,
        uploadedTile;   // uploadedTile: where a baked probe's page was last written (a moved tile is written again)
    float gain = 1.0f;  // ReflectionProbe.intensity
    std::string name;   // the entity's id in the scene, for the report
    bool placed = false;
    std::string state;    // "ready", "pending", "capturing", "noRoom", "noBake", "failed"
    std::string message;  // why a probe is "failed" or "noBake"
    std::uint64_t captures = 0;
    std::uint64_t lastFrame = 0;   // the renderer's probe frame of the last capture or upload (0 = never)
    std::uint64_t retryFrame = 0;  // a realtime probe that failed is tried again from this probe frame
    // Baked: the manifest the tile was last filled from.
    std::string bakedPath, bakedHash;
    std::uint64_t bakedSerial = 0;
    float uploadedGain = 0.0f;
    bool seen = false;  // listed this frame
};

// What the renderer keeps of one RealtimeGI component (renderer_gi.cpp).
struct GiGrid {
    Entity entity = kNullEntity;
    std::uint64_t id = 0;  // the entity's bits
    std::string name;      // the entity's id in the scene, for the report
    bool valid = false;    // the component passed gi_layout
    std::string error;     // why it did not
    GiLayout layout;
    int probesPerFrame = 1;            // RealtimeGI.probesPerFrame
    int base = -1;                     // the first block of the grid's run (-1: none)
    std::vector<std::uint64_t> last;   // per probe: the ordinal of its last capture (0 = never)
    std::vector<std::uint64_t> retry;  // per probe: the gi frame before which it is not tried again
    std::uint64_t serial = 0;          // captures of the grid since its layout changed
    int captured = 0;                  // probes captured at least once
    std::uint64_t cycles = 0;          // times every probe has been captured once more (serial / count)
    std::string state;                 // "updating", "ready", "invalid", "noRoom", "unsupported"
    std::string message;
    bool seen = false;
    int lastFrameCaptures = 0;  // probes captured in the last gi frame
    bool dirty = true;          // the record changed (the layout key or the readiness): P5d-2 writes it again
};

// The realtime GI of a renderer: every grid's state, the blocks of the band, this frame's capture jobs.
struct GiSystem {
    std::vector<Entity> wants;  // the active RealtimeGI components of this frame, in entity order
    std::map<std::uint64_t, GiGrid> grids;
    GiBlockAllocator blocks;
    const World* world = nullptr;
    std::uint64_t sceneGeneration = 0;
    std::uint64_t frame = 0;  // gi frames begun (a frame that has a grid)
    struct Job {
        std::uint64_t grid = 0;
        int probe = 0, face = 0, distIndex = 0;
        bool last = false;   // the sixth face of the capture: the block is filtered after it
        bool first = false;  // the probe's first capture: it replaces the block instead of blending into it
        sg_view picture{};
    };
    std::vector<Job> jobs;
    std::deque<GiFacePlan> plans;  // one per job: a JobPlan keeps a pointer
    std::deque<Frame> frames;      // a job keeps a reference to its Frame
    std::vector<int> perFrame;     // probes captured in each of the last frames (newest last, up to kHistory)
    static constexpr std::size_t kHistory = 64;
    std::uint64_t totalCaptures = 0;
    int drawCalls = 0;
    bool unsupported = false;  // gi_ready() said no (logged once)
};

// The probes of a renderer.
struct ProbeSystem {
    ProbeGpu gpu;
    ProbeGpu::Atlas atlas, syncAtlas;
    ProbeAtlasAllocator allocator;
    ProbeScheduler scheduler;
    std::map<std::uint64_t, ProbeEntry> entries;  // by id (the entity's bits): deterministic order
    const World* world = nullptr;                 // the world and scene generation the entries belong to
    std::uint64_t sceneGeneration = 0;
    std::uint64_t frame = 0;  // probe frames begun (a frame that has probes)
    int overLimit = 0;
    bool overLimitWarned = false;
    // The sky's entry (atlas entry 0).
    bool skyPlaced = false;
    ProbeTile skyTile;
    std::uint64_t skyKey = 0;
    std::uint64_t skyWrittenFrame = 0;
    // This frame's captures: one Frame per face job, kept until the frame graph ran (a job keeps a reference).
    std::deque<Frame> frames;  // a deque: a job keeps a reference to its Frame
    struct Job {
        std::uint64_t id = 0;
        int slot = 0, face = 0;
        bool last = false;
        std::uint64_t key = 0;  // view_image key of the face picture
        sg_view picture{};      // the face's image (upright), valid until the frame is done
    };
    std::vector<Job> jobs;
    int drawCalls = 0;  // passes of the probes since the renderer was made (reported)
    // What probes_plan decided for probes_finish: the baked probes to upload.
    std::vector<std::uint64_t> uploads;
    std::string skyState;  // "ready", "noSky" (the scene draws no sky material: the meshes keep the gradient), "failed"
    GiSystem gi;           // the RealtimeGI grids (they share the atlas)
};

}  // namespace fa::render
