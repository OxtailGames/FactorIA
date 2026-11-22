// Private: the 2D items that read the picture drawn so far in the camera (M74.4). Three things share one mechanism:
//
//   * Water2D and DistortionZone2D (built-in look): gather_water_fx() puts each into the world list as one quad that carries an Fx2D
//     (QuadList::set_effect); WaterFx::draw draws it from the copy.
//   * Water2D.material / DistortionZone2D.material: the same quad drawn by an ordinary sprite material (sprite_material_once), which gets the
//     fields as params and may call fa_scene_color() / fa_world_to_uv() (shaders/quad_common.glsl).
//   * Any other sprite material whose snippet calls fa_scene_color(): its program declares the view kMaterialSpriteSceneView (render_internal.h).
//
// The main pass (renderer_draw.cpp) keeps the picture: before each batch of the world group that reads it, the pass ends, the camera's
// rectangle of the game image is copied into a pooled image the size of that rectangle (WaterFx::copy), and the pass goes on from what it
// stored (colour, depth and stencil LOAD), exactly the way the transmission copy splits it (renderer_xmit.h). A batch of the same material
// is one batch, so a thousand sprites that read the picture cost one copy; every other reading batch costs one (the previous one drew, so
// the picture changed), at most kMaxSceneCopies per camera. A frame with no such batch plans no split, makes no copy and holds no image:
// bit-identical to a frame without the feature.
#pragma once

#include <cstdint>
#include <vector>

#include "render_internal.h"
#include "transient_targets.h"

namespace fa {
class World;
}

namespace fa::render {

struct Frame;

// The most copies of the picture one camera makes in one frame. A deterministic count (never time): the batches over it read the last copy.
constexpr int kMaxSceneCopies = 8;

// Puts the Water2D and DistortionZone2D entities the camera of `f` draws into f.world (nothing when the frame has no world). Called by
// Scene2D::gather on the thread that gathers (it may load a material).
void gather_water_fx(World& world, Frame& f);

// How many batches of `batches` read the picture drawn so far: the effect batches, and the batches of a sprite material whose program
// declares the scene view. Cheap (one pass over the batches); the main pass plans its splits with it.
int count_scene_readers(const std::vector<QuadBatch>& batches);
// True when `qb` reads the picture drawn so far.
bool reads_scene(const QuadBatch& qb);
// Where the main pass copies the picture: appends to `at` the index of every batch that starts a run of reading batches (a run is the reading
// batches that follow each other: they share one copy and do not see each other), at most kMaxSceneCopies of them. Returns how many runs
// there are in all: more than kMaxSceneCopies means the runs after the last copy read it (the caller says so once). Pure and deterministic.
int plan_scene_copies(const std::vector<QuadBatch>& batches, std::vector<std::uint32_t>& at);

// How the shaders find the copy: `scene` = (scale x, scale y, offset x, offset y) from a screen uv (0..1 over the render target, y down)
// to a position in the copy (0..1, y down); `worldUv` = the rows of the camera's view-projection already turned into screen uv.
// All pure arithmetic (no GPU): the camera's rectangle is (x, y) from the top-left, w x h pixels, of a target of targetW x targetH.
struct SceneMap {
    float scene[4]{};
    float worldUv[3][4]{};
};
SceneMap scene_map(const Mat4& viewProj, int x, int y, int w, int h, int targetW, int targetH);

class WaterFx {
public:
    WaterFx() = default;
    WaterFx(const WaterFx&) = delete;
    WaterFx& operator=(const WaterFx&) = delete;

    // True when the copy and effect shaders compiled (made on first use; one error line when they did not, and the effects are then not
    // drawn).
    bool ready();

    // Makes the shaders and the pipelines of a frame drawn into `gameFormat` (the main pass's format) ahead of the first draw: the start-up
    // warm-up of a scene that has a Water2D or a DistortionZone2D (renderer.cpp), so their first frame does not compile them. Does nothing
    // when the shaders failed. A scene without those components never calls it, and a pipeline for another format is made when it is drawn.
    void warm(Gpu& gpu, const TargetFormat& gameFormat);

    // How many pipelines are made so far (copy and effect ones, all formats): a test reads it to see that a draw finds its pipeline
    // already made.
    int pipeline_count() const { return int(copyPipelines_.size() + fxPipelines_.size()); }

    // Copies the camera's rectangle of `game` (its texture view, resolved when multisampled): (x, row, w, h) in image rows of the game
    // image. Must be called outside any pass. On success `handle` is the pooled image (give it back with TransientTargets::pool.release) and
    // `view` its texture view; false (nothing held) when the shader or the image could not be made.
    bool copy(TransientTargets& targets, Gpu& gpu, const Target& game, int x, int row, int w, int h,
              std::uint64_t& handle, sg_view& view);

    // What draw() needs of the camera and the frame.
    struct DrawEnv {
        sg_buffer vertices{};  // the frame's quad stream
        const Mat4* viewProj = nullptr;
        const SceneMap* map = nullptr;
        sg_view scene{};  // the copy
        float time = 0.0f;
        float targetInv[2]{};  // 1 / the size of the render target in pixels
        bool gl = false;       // render targets are bottom-up (OpenGL)
        bool depthTest = false;
        TargetFormat format;  // of the pass drawn in
    };
    // Draws the built-in effect `fx` as the one quad at `firstQuad` of the stream, inside a pass. False when it could not be drawn.
    bool draw(Gpu& gpu, const Fx2D& fx, std::uint32_t firstQuad, const DrawEnv& env);

    // Destroys the shaders and pipelines; call while the graphics context is open.
    void release();

private:
    struct PipelineEntry {
        TargetFormat format;
        bool depthTest;
        sg_pipeline pipeline;
    };
    sg_pipeline copy_pipeline(const TargetFormat& format);
    sg_pipeline fx_pipeline(const TargetFormat& format, bool depthTest);
    sg_shader copyShader_{}, fxShader_{};
    int state_ = 0;  // 0 = shaders not made yet, 1 = ready, -1 = failed (logged)
    std::vector<PipelineEntry> copyPipelines_, fxPipelines_;
};

}  // namespace fa::render
