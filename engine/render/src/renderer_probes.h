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
#include <map>
#include <string>
#include <vector>

#include "fa/render/probe.h"
#include "frame.h"
#include "render_internal.h"

namespace fa::render {

inline constexpr int kProbeScratchSlots = kProbeSlots + 1;  // the last one belongs to the synchronous capture
inline constexpr int kProbeSyncAtlasSize = 512;             // holds one 256 tile (388 x 259)

class ProbeGpu {
public:
    struct Atlas {
        sg_image image{};
        sg_view tex{};  // what a shader samples
        sg_view att{};  // what a pass draws into
        int size = 0;
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

    // A cleared square atlas image. False when the GPU refuses it.
    bool make_atlas(Atlas& atlas, int size, const char* label);
    void destroy_atlas(Atlas& atlas);

    // The scratch cubes of `slot` for maps of `resolution` (made again when the resolution changes). False when the GPU refuses them.
    bool prepare_scratch(int slot, int resolution);

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
    static bool read_region_end(sg_image scratch, int w, int h, bool rgba8, std::vector<float>& out, std::string* error);

    void release();

private:
    enum class Prog { Face, Down, OctCube, OctGgx, Sh, ShCube, Blit, Count };
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
    sg_shader shaders_[int(Prog::Count)]{};
    sg_pipeline pipelines_[int(Prog::Count)]{};
    sg_sampler sampler_{};
    Scratch scratch_[kProbeScratchSlots];
    bool isGl_ = false;
};

// What the renderer keeps of one ReflectionProbe between frames.
struct ProbeEntry {
    Entity entity = kNullEntity;
    std::uint64_t id = 0;  // the allocator's and scheduler's id: the entity's bits
    bool realtime = false;
    int resolution = 0, importance = 0;
    ProbeTile tile;
    bool placed = false;
    std::string state;       // "ready", "pending", "capturing", "noRoom", "noBake", "failed", "overLimit"
    std::string message;     // why a probe is "failed" or "noBake"
    std::uint64_t captures = 0;
    std::uint64_t lastFrame = 0;  // the renderer's probe frame of the last capture or upload (0 = never)
    // Baked: the manifest the tile was last filled from.
    std::string bakedPath, bakedHash;
    std::uint64_t bakedSerial = 0;
    float uploadedGain = 0.0f;
    bool seen = false;  // listed this frame
};

// The probes of a renderer.
struct ProbeSystem {
    ProbeGpu gpu;
    ProbeGpu::Atlas atlas, syncAtlas;
    ProbeAtlasAllocator allocator;
    ProbeScheduler scheduler;
    std::map<std::uint64_t, ProbeEntry> entries;  // by id (the entity's bits): deterministic order
    std::uint64_t frame = 0;                      // probe frames begun (a frame that has probes)
    int overLimit = 0;
    bool overLimitWarned = false;
    // The sky's entry (atlas entry 0).
    bool skyPlaced = false;
    ProbeTile skyTile;
    std::uint64_t skyKey = 0;
    std::uint64_t skyWrittenFrame = 0;
    // This frame's captures: one Frame per face job, kept until the frame graph ran (a job keeps a reference).
    std::vector<Frame> frames;
    struct Job {
        std::uint64_t id = 0;
        int slot = 0, face = 0;
        bool last = false;
        std::uint64_t key = 0;  // view_image key of the face picture
    };
    std::vector<Job> jobs;
    int drawCalls = 0;  // passes of the probes since the renderer was made (reported)
};

}  // namespace fa::render
