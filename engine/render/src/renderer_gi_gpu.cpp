// The GPU half of the realtime GI (renderer_probes.h, ProbeGpu; docs/design/ARCHITECTURE_PROBES.md, "Realtime GI: the data side"): the
// distance picture of a capture face, the face with its distance in the scratch cube, and the three passes that blend a capture into the
// probe's block of the atlas (the SH row, the depth map, the meta texel). The programs are shaders/probe.glsl (gi_dist, face_gi, gi_depth,
// gi_meta and the blending variant of sh).
#include <algorithm>
#include <cstring>

#include "fa/core/log.h"
#include "renderer_env.h"
#include "renderer_probes.h"
#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
#include "shaders/probe.glsl.h"

namespace fa::render {

namespace {

bool valid_image(gpu::Device& device, gpu::Image i) { return i.id && device.state(i) == gpu::ResourceState::Valid; }
bool valid_view(gpu::Device& device, gpu::View v) { return v.id && device.state(v) == gpu::ResourceState::Valid; }

}  // namespace

bool ProbeGpu::gi_ready() {
    if (giState_ != 0) return giState_ > 0;
    if (state_ <= 0 || !gpu_) return false;  // ready(gpu) first, and it said why when it failed
    gpu::Device& device = gpu_->device();
    const gpu::PixelFormatCaps half = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
    bool ok = format_ == gpu::PixelFormat::Rgba16F && half.render && half.blend && half.sample;
    if (ok) {
        const struct {
            Prog prog;
            gpu::GeneratedShader desc;
            const char* name;
        } programs[] = {{Prog::FaceGi, probe_face_gi_shader_desc, "probe_face_gi"},
                        {Prog::GiDist, probe_gi_dist_shader_desc, "probe_gi_dist"},
                        {Prog::GiDepth, probe_gi_depth_shader_desc, "probe_gi_depth"},
                        {Prog::GiMeta, probe_gi_meta_shader_desc, "probe_gi_meta"}};
        for (const auto& p : programs) {
            shaders_[int(p.prog)] = make_shader(device, gpu::generated_shader_desc(device, p.desc), p.name);
            ok = ok && device.state(shaders_[int(p.prog)]) == gpu::ResourceState::Valid;
        }
    }
    if (ok) {
        gpu::SamplerDesc sd{};
        sd.minFilter = gpu::Filter::Nearest;
        sd.magFilter = gpu::Filter::Nearest;
        sd.mipmapFilter = gpu::Filter::Nearest;
        sd.wrapU = sd.wrapV = sd.wrapW = gpu::Wrap::ClampToEdge;
        sd.label = "probe-nearest";
        nearest_ = device.make_sampler(sd);
        ok = nearest_.id && device.state(nearest_) == gpu::ResourceState::Valid;
    }
    if (ok) {
        const struct {
            Prog prog;
            gpu::Shader shader;
            bool blend;
        } pipes[] = {
            {Prog::FaceGi, shaders_[int(Prog::FaceGi)], false},  {Prog::GiDist, shaders_[int(Prog::GiDist)], false},
            {Prog::GiDepth, shaders_[int(Prog::GiDepth)], true}, {Prog::GiMeta, shaders_[int(Prog::GiMeta)], true},
            {Prog::ShBlend, shaders_[int(Prog::Sh)], true},      {Prog::BlitBlend, shaders_[int(Prog::Blit)], true}};
        for (const auto& p : pipes) {
            gpu::PipelineDesc d{};
            d.shader = p.shader;
            d.layout.attrs[ATTR_probe_face_pos].format = gpu::VertexFormat::Float2;
            d.depth.compare = gpu::CompareFunc::Always;
            d.depth.writeEnabled = false;
            d.depth.pixelFormat = gpu::PixelFormat::None;
            d.colorCount = 1;
            d.colors[0].pixelFormat = format_;
            if (p.blend) {
                // The new value with the weight of the shader's alpha over the old one (the hysteresis); the alpha channel keeps what it was.
                d.colors[0].blend.enabled = true;
                d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
                d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::OneMinusSrcAlpha;
                d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
                d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
            }
            d.sampleCount = 1;
            d.faceWinding = gpu::FaceWinding::Ccw;
            d.label = "probe-gi";
            pipelines_[int(p.prog)] = device.make_pipeline(d);
            ok = ok && device.state(pipelines_[int(p.prog)]) == gpu::ResourceState::Valid;
        }
    }
    if (!ok) {
        release_gi();
        giState_ = -1;
        FA_ERROR("render", "The realtime GI cannot be drawn: this GPU cannot blend into RGBA16F images, or the GI "
                           "shaders failed to compile for this "
                           "graphics backend (see the sokol log lines above). RealtimeGI components are ignored. Hint: "
                           "update the graphics driver "
                           "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    giState_ = 1;
    return true;
}

void ProbeGpu::release_gi() {
    gpu::Device* device = gpu_ && gpu_->has_device() ? &gpu_->device() : nullptr;
    if (device) {
        for (DistImage& d : dist_) {
            if (d.att.id) device->destroy_view(d.att);
            if (d.tex.id) device->destroy_view(d.tex);
            if (d.image.id) device->destroy_image(d.image);
        }
        if (nearest_.id) device->destroy_sampler(nearest_);
    }
    dist_.clear();
    nearest_ = {};
    // The programs and pipelines of the GI are in the arrays release() empties; a failed gi_ready() leaves the half it made in them.
    for (Prog p : {Prog::FaceGi, Prog::GiDist, Prog::GiDepth, Prog::GiMeta, Prog::ShBlend, Prog::BlitBlend}) {
        if (device && pipelines_[int(p)].id) device->destroy_pipeline(pipelines_[int(p)]);
        pipelines_[int(p)] = {};
        if (device && p != Prog::ShBlend && p != Prog::BlitBlend && shaders_[int(p)].id)
            gpu_->destroy_shader(shaders_[int(p)]);
        shaders_[int(p)] = {};
    }
    giState_ = 0;
}

bool ProbeGpu::dist_image(int index, int res) {
    if (index < 0 || index > 4096 || !gi_ready()) return false;
    gpu::Device& device = gpu_->device();
    if (std::size_t(index) >= dist_.size()) dist_.resize(std::size_t(index) + 1);
    DistImage& d = dist_[std::size_t(index)];
    if (d.size == res && valid_image(device, d.image)) return true;
    if (d.att.id) device.destroy_view(d.att);
    if (d.tex.id) device.destroy_view(d.tex);
    if (d.image.id) device.destroy_image(d.image);
    d = DistImage{};
    gpu::ImageDesc id{};
    id.usage.colorAttachment = true;
    id.width = id.height = res;
    id.pixelFormat = gpu::PixelFormat::Rgba16F;
    id.label = "probe-gi-distance";
    d.image = device.make_image(id);
    if (!valid_image(device, d.image)) {
        if (d.image.id) device.destroy_image(d.image);
        d = DistImage{};
        return false;
    }
    gpu::ViewDesc vd{};
    vd.texture.image = d.image;
    vd.label = "probe-gi-distance";
    d.tex = device.make_view(vd);
    gpu::ViewDesc ad{};
    ad.colorAttachment.image = d.image;
    ad.label = "probe-gi-distance";
    d.att = device.make_view(ad);
    if (!valid_view(device, d.tex) || !valid_view(device, d.att)) {
        if (d.att.id) device.destroy_view(d.att);
        if (d.tex.id) device.destroy_view(d.tex);
        device.destroy_image(d.image);
        d = DistImage{};
        return false;
    }
    d.size = res;
    return true;
}

gpu::View ProbeGpu::dist_view(int index) const {
    if (index < 0 || std::size_t(index) >= dist_.size()) return {};
    return dist_[std::size_t(index)].tex;
}

void ProbeGpu::gi_dist(Gpu& gpu, int index, gpu::View front, gpu::View back, float maxDistance, int* drawCalls) {
    if (index < 0 || std::size_t(index) >= dist_.size() || !dist_[std::size_t(index)].att.id) return;
    const DistImage& di = dist_[std::size_t(index)];
    gpu::PassDesc pd;
    pd.label = "probe-gi-distance";
    pd.color = di.att;
    pd.format = gpu::TargetFormat{gpu::PixelFormat::Rgba16F, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    cmd.set_pipeline(pipelines_[int(Prog::GiDist)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_pre_front] = front;
    b.views[VIEW_probe_probe_pre_back] = back;
    b.samplers[SMP_probe_probe_nsmp] = nearest_;
    cmd.set_bindings(b);
    probe_probe_gi_dist_params_t u{};
    u.d[0] = float(di.size);
    u.d[1] = isGl_ ? 1.0f : 0.0f;
    u.d[2] = maxDistance;
    cmd.set_uniforms(UB_probe_probe_gi_dist_params, gpu::Range{&u, sizeof(u)});
    cmd.draw(0, 3, 1);
    cmd.end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::face_gi(Gpu& gpu, int slot, int face, gpu::View picture, gpu::View dist, float maxDistance,
                       int* drawCalls) {
    Scratch& s = scratch_[slot];
    const ProbeFace c = probe_face(face);
    gpu::PassDesc pd;
    pd.label = "probe-gi-face";
    pd.color = s.att[0][face];
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    cmd.set_pipeline(pipelines_[int(Prog::FaceGi)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_gcol] = picture;
    b.views[VIEW_probe_probe_gdist] =
        dist.id ? dist : picture;  // a slot must hold a view: the shader ignores it when g.x = 1
    b.samplers[SMP_probe_probe_nsmp] = nearest_;
    cmd.set_bindings(b);
    const EnvFace f = env_face(face, isGl_);
    probe_probe_vs_params_t vu{};
    for (int i = 0; i < 3; ++i) {
        vu.fwd[i] = f.fwd[i];
        vu.right[i] = f.right[i];
        vu.up[i] = f.up[i];
    }
    cmd.set_uniforms(UB_probe_probe_vs_params, gpu::Range{&vu, sizeof(vu)});
    probe_probe_gi_face_params_t fu{};
    fu.gcam_right[0] = c.right.x;
    fu.gcam_right[1] = c.right.y;
    fu.gcam_right[2] = c.right.z;
    fu.gcam_up[0] = c.up.x;
    fu.gcam_up[1] = c.up.y;
    fu.gcam_up[2] = c.up.z;
    fu.gcam_fwd[0] = c.fwd.x;
    fu.gcam_fwd[1] = c.fwd.y;
    fu.gcam_fwd[2] = c.fwd.z;
    fu.g[0] = dist.id ? 0.0f : 1.0f;
    fu.g[2] = maxDistance;
    cmd.set_uniforms(UB_probe_probe_gi_face_params, gpu::Range{&fu, sizeof(fu)});
    cmd.draw(0, 3, 1);
    cmd.end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::filter_gi(Gpu& gpu, Atlas& atlas, int slot, int block, int resolution, float blend, float maxDistance,
                         int* drawCalls) {
    Scratch& s = scratch_[slot];
    const int source = probe_sh_source(resolution);
    for (int i = 1; i <= source && i < s.images; ++i)
        for (int f = 0; f < 6; ++f) pass_cube(gpu, Prog::Down, s.att[i][f], s.tex[i - 1], f, nullptr, drawCalls);
    const GiTexel o = gi_block_origin(block);
    const float w = std::clamp(blend, 0.0f, 1.0f);
    // The SH row: the light that reaches the probe, as the projection of probe.h's SH row (no gain).
    {
        const float region[4] = {float(o.x), float(o.y + kGiShRow), 9.0f, 0.0f};
        const float p[4] = {0.0f, 0.0f, 0.0f, 1.0f}, q[4] = {0.0f, 0.0f, w, 0.0f};
        pass_rect(gpu, atlas, Prog::ShBlend, o.x, o.y + kGiShRow, kProbeShCoefficients, 1,
                  s.tex[std::min(source, s.images - 1)], sampler_, region, p, q, nullptr, drawCalls);
    }
    // The depth map with its border: 8 x 8 texels, each the mean of the distance and of its square over 4 x 4 directions.
    {
        const float region[4] = {float(o.x), float(o.y), float(kGiDepthTexels), float(kProbeBorder)};
        const float p[4] = {maxDistance, 0.0f, 0.0f, 0.0f}, q[4] = {0.0f, 0.0f, w, 0.0f};
        pass_rect(gpu, atlas, Prog::GiDepth, o.x, o.y, kGiBlockW, kGiBlockW, s.tex[0], nearest_, region, p, q, nullptr,
                  drawCalls);
    }
    // The meta texel: the fraction of back-face directions, 1 = captured.
    {
        const float region[4] = {}, p[4] = {}, q[4] = {0.0f, 0.0f, w, 0.0f};
        pass_rect(gpu, atlas, Prog::GiMeta, o.x + kGiMetaX, o.y + kGiShRow, 1, 1, s.tex[0], nearest_, region, p, q,
                  nullptr, drawCalls);
    }
}

void ProbeGpu::blit_gi(Gpu& gpu, Atlas& atlas, gpu::View band, const std::vector<int>& blocks, int* drawCalls) {
    if (!band.id || giState_ != 1 || blocks.empty()) return;
    // One pass for all the blocks (a pass for each block would load and store the whole atlas for each, on a tiled GPU): the
    // pipeline and the bindings are set once, each block is a viewport, a scissor, its source rectangle and one draw. The rectangles do not
    // overlap, so the result is the one of a pass a block.
    gpu::PassDesc pd;
    pd.label = "probe-atlas";
    pd.color = atlas.att;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::Load;  // the other tiles stay
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    cmd.set_pipeline(pipelines_[int(Prog::BlitBlend)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_cube] = band;
    b.samplers[SMP_probe_probe_smp] = sampler_;
    cmd.set_bindings(b);
    for (int block : blocks) {
        const GiTexel o = gi_block_origin(block);
        // The rectangle in MEMORY rows: OpenGL counts its window from the bottom (see pass_rect).
        cmd.set_viewport(o.x, o.y, kGiBlockW, kGiBlockH, !isGl_);
        cmd.set_scissor(o.x, o.y, kGiBlockW, kGiBlockH, !isGl_);
        probe_probe_blit_params_t u{};
        u.dst[0] = float(o.x);
        u.dst[1] = float(o.y);
        u.src[0] = float(o.x);
        u.src[1] = float(o.y - kProbeAtlasSize);
        u.src[2] = float(kGiBlockH);
        u.src[3] = 0.0f;
        cmd.set_uniforms(UB_probe_probe_blit_params, gpu::Range{&u, sizeof(u)});
        cmd.draw(0, 3, 1);
        if (drawCalls) ++*drawCalls;
    }
    cmd.end_pass();
}

}  // namespace fa::render
