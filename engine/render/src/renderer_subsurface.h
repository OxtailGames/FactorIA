// The passes of the screen-space subsurface scattering (MeshRenderer.subsurface, M73.5); the maths they share with the shaders is in subsurface.h and
// docs/design/ARCHITECTURE_SUBSURFACE.md explains the design.
//
//   sss-draw    (the camera's own job, after its prepass; renderer_draw.cpp, Renderer::sss_draw_pass)  the meshes that scatter again, with the sss program
//               of the mesh shader: A = the diffuse light and the linear depth, B = the scatter radius per colour channel and the strength.
//   sss-blur-h  A + B -> H: the diffuse light blurred along x, depth aware.
//   sss-blur-v  H + A + B -> V: the change the scattering makes, strength * (blurred along y - the unblurred light), signed.
//   sss-add     V -> the camera's rectangle of the picture: the positive part added, the negative one subtracted (two draws, so the picture can be 8 bits).
//
// The last three are declared by SssFx::add_passes with the post stack, before the volumetric fog and the reflections. SssFx owns the shaders and
// pipelines of the blur and the add (made on first use, destroyed by release()); the sss program of the meshes lives in Gpu (sss_ready()).
#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "bloom.h"
#include "frame_graph.h"
#include "render_internal.h"
#include "subsurface.h"
#include "transient_targets.h"

namespace fa::render {

struct PostRect;

class SssFx {
public:
    SssFx() = default;
    SssFx(const SssFx&) = delete;
    SssFx& operator=(const SssFx&) = delete;

    enum class Prog { BlurH, BlurV, Add, Count };

    // Does this GPU render RGBA16F targets that it can also sample (the images hold light above 1 and signed changes)? The rule of the `half`
    // word of the feature rows (render_features.cpp), so render.supports("subsurface") and the renderer never disagree.
    static bool gpu_supported(gpu::Device& device);
    // The images of `plan`: A (light + depth, with a depth buffer: the sss-draw's), B (radius + strength), and the blur's H and V. All the size of the
    // camera's rectangle. `job` labels them.
    static TransientDesc light_desc(const SssPlan& plan, const std::string& job);   // A
    static TransientDesc params_desc(const SssPlan& plan, const std::string& job);  // B, H and V (same shape)
    // Can the camera's passes be drawn: the GPU supports it, the sss program and the three blur programs build and the images can be made (probed once
    // per size and given back to the pool). False (logged once) draws the meshes without scattering.
    bool can_draw(TransientTargets& targets, Gpu& gpu, const SssPlan& plan);

    // Declares sss-blur-h, sss-blur-v and sss-add: they read the images `a` and `b` of the sss-draw pass and change the camera's rectangle `rect` of the
    // picture (`game`, drawn into `dst`). Returns the number of passes declared (0: nothing to draw).
    int add_passes(FrameGraph& graph, TransientTargets& targets, Gpu& gpu, const SssPlan& plan, ResourceId a,
                   ResourceId b, const PostRect& rect, int picW, int picH, ResourceId game, const BloomTarget& dst,
                   int* drawCalls, const std::string& job);

    // Destroys the shaders and the pipelines; call while the graphics context is open.
    void release();
    // Forgets that creating the images failed (the game target was resized or recreated).
    void forget_targets();

    bool ready(Gpu& gpu, Prog prog);
    gpu::Pipeline pipeline(Gpu& gpu, Prog prog, const TargetFormat& format, bool subtract = false);

private:
    struct PipelineEntry {
        Prog prog;
        bool subtract;
        TargetFormat format;
        gpu::Pipeline pipeline;
    };
    gpu::Device* device_ = nullptr;  // what ready() made the shaders on: release() has no Gpu at hand
    gpu::Shader shaders_[int(Prog::Count)]{};
    int state_[int(Prog::Count)]{};  // 0 = not made yet, 1 = ready, -1 = failed (logged)
    std::vector<PipelineEntry> pipelines_;
    bool warnedTargets_ = false;
    bool warnedGpu_ = false;
    std::vector<std::uint64_t> failed_;  // sizes whose images could not be made
    std::vector<std::uint64_t> probed_;  // sizes whose images were made once: the pool is not probed again every frame
};

}  // namespace fa::render
