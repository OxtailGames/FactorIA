#include "renderer_sky_phys.h"

#include <cstdlib>
#include <cstring>
#include <string>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/sky_physical.glsl.h"

namespace fa::render {

namespace {

bool usable(gpu::Device& device, gpu::PixelFormat f) {
    const gpu::PixelFormatCaps i = device.pixel_format_caps(f);
    return i.sample && i.filter && i.render;
}
bool valid(gpu::Device& device, gpu::Image i) { return i.id && device.state(i) == gpu::ResourceState::Valid; }
bool valid(gpu::Device& device, gpu::View v) { return v.id && device.state(v) == gpu::ResourceState::Valid; }

gpu::Image make_table(gpu::Device& device, int w, int h, gpu::PixelFormat format, const char* label) {
    gpu::ImageDesc d;
    d.usage.colorAttachment = true;
    d.width = w;
    d.height = h;
    d.pixelFormat = format;
    d.label = label;
    return device.make_image(d);
}
gpu::View texture_view(gpu::Device& device, gpu::Image image, const char* label) {
    gpu::ViewDesc v;
    v.texture.image = image;
    v.label = label;
    return device.make_view(v);
}
gpu::View attachment_view(gpu::Device& device, gpu::Image image, const char* label) {
    gpu::ViewDesc v;
    v.colorAttachment.image = image;
    v.label = label;
    return device.make_view(v);
}
void destroy(gpu::Device& device, gpu::View& v) {
    if (v.id) device.destroy_view(v);
    v = {};
}
void destroy(gpu::Device& device, gpu::Image& i) {
    if (i.id) device.destroy_image(i);
    i = {};
}

}  // namespace

bool PhysicalSky::ready(Gpu& gpu) {
    if (state_ != 0) return state_ > 0;
    gpu::Device& device = gpu.device();
    device_ = &device;
    // The tables hold optical depths (up to about 20) and radiances: they need a float format that renders and filters.
    // FA_PHYSICAL_SKY=invalid is a test hook: the GPU "cannot" render the tables, as on a device without filterable RGBA16F.
    const char* hook = std::getenv("FA_PHYSICAL_SKY");
    const bool forcedOff = hook && std::string(hook) == "invalid";
    format_ =
        !forcedOff && usable(device, gpu::PixelFormat::Rgba16F) ? gpu::PixelFormat::Rgba16F : gpu::PixelFormat::None;
    bool ok = format_ != gpu::PixelFormat::None;
    if (ok) {
        shaders_[Transmittance] =
            make_shader(device, gpu::generated_shader_desc(skyphys_transmittance_shader_desc), "sky_transmittance");
        shaders_[MultiScatter] =
            make_shader(device, gpu::generated_shader_desc(skyphys_multiscatter_shader_desc), "sky_multiscatter");
        shaders_[SkyView] = make_shader(device, gpu::generated_shader_desc(skyphys_skyview_shader_desc), "sky_view");
        shaders_[Sky] = make_shader(device, gpu::generated_shader_desc(skyphys_sky_shader_desc), "sky_physical");
        for (gpu::Shader s : shaders_) ok = ok && device.state(s) == gpu::ResourceState::Valid;
    }
    if (ok) {
        gpu::SamplerDesc sd;
        sd.minFilter = gpu::Filter::Linear;
        sd.magFilter = gpu::Filter::Linear;
        sd.mipmapFilter = gpu::Filter::Nearest;
        sd.wrapU = sd.wrapV = gpu::Wrap::ClampToEdge;
        sd.label = "sky-tables";
        sampler_ = device.make_sampler(sd);
        trImage_ = make_table(device, kSkyTransmittanceW, kSkyTransmittanceH, format_, "sky-transmittance");
        msImage_ = make_table(device, kSkyMultiScatterSize, kSkyMultiScatterSize, format_, "sky-multiscatter");
        view_[0] = make_table(device, kSkyViewW, kSkyViewH, format_, "sky-view");
        view_[1] = make_table(device, kSkyViewW, kSkyViewH, format_, "sky-view-env");
        ok = ok && valid(device, trImage_) && valid(device, msImage_) && valid(device, view_[0]) &&
             valid(device, view_[1]);
        if (ok) {
            trTex_ = texture_view(device, trImage_, "sky-transmittance");
            trAtt_ = attachment_view(device, trImage_, "sky-transmittance");
            msTex_ = texture_view(device, msImage_, "sky-multiscatter");
            msAtt_ = attachment_view(device, msImage_, "sky-multiscatter");
            for (int i = 0; i < 2; ++i) {
                viewTex_[i] = texture_view(device, view_[i], "sky-view");
                viewAtt_[i] = attachment_view(device, view_[i], "sky-view");
                ok = ok && valid(device, viewTex_[i]) && valid(device, viewAtt_[i]);
            }
            ok = ok && valid(device, trTex_) && valid(device, trAtt_) && valid(device, msTex_) && valid(device, msAtt_);
        }
    }
    if (ok) {
        for (int p = 0; p < Sky; ++p) {
            gpu::PipelineDesc d;
            d.shader = shaders_[p];
            d.layout.attrs[0].format = gpu::VertexFormat::Float2;  // `pos`, location 0 in every program
            d.depth.compare = gpu::CompareFunc::Always;
            d.depth.writeEnabled = false;
            d.depth.pixelFormat = gpu::PixelFormat::None;
            d.colors[0].pixelFormat = format_;
            d.sampleCount = 1;
            d.faceWinding = gpu::FaceWinding::Ccw;
            d.label = p == Transmittance ? "sky-transmittance" : p == MultiScatter ? "sky-multiscatter" : "sky-view";
            lutPipelines_[p] = device.make_pipeline(d);
            ok = ok && device.state(lutPipelines_[p]) == gpu::ResourceState::Valid;
        }
    }
    if (!ok) {
        release();
        state_ = -1;
        FA_ERROR("render",
                 "SceneSettings.skyModel \"physical\" is not available on this graphics backend: the sky tables "
                 "(RGBA16F render targets that filter) or their shaders could not be made (see the sokol log lines "
                 "above), so the gradient sky is drawn. Hint: render.supports {{\"feature\": \"physicalSky\"}} tells "
                 "a script before it sets the model; update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

void PhysicalSky::pass(Gpu& gpu, Prog prog, gpu::View target, const char* label, const PhysicalSkyState& st,
                       int* drawCalls) {
    gpu::PassDesc pd;
    pd.label = label;
    pd.color = target;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;  // every texel is drawn
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(lutPipelines_[prog]);
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.samplers[SMP_skyphys_sky_smp] = sampler_;
    if (prog == MultiScatter) {
        b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
    } else if (prog == SkyView) {
        b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
        b.views[VIEW_skyphys_sky_ms_tex] = msTex_;
    }
    list.set_bindings(b);
    skyphys_sky_params_t fu{};
    const SkyShaderParams p = sky_shader_params(st, false);
    static_assert(sizeof(fu.q) == sizeof(p.v), "the shader's block and the CPU's packing are the same size");
    std::memcpy(fu.q, p.v, sizeof(fu.q));
    list.set_uniforms(UB_skyphys_sky_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

void PhysicalSky::update_air(Gpu& gpu, const PhysicalSkyState& st, int* drawCalls) {
    const std::uint64_t key = sky_air_key(st.s);
    if (airDrawn_ && airKey_ == key) return;
    pass(gpu, Transmittance, trAtt_, "sky-transmittance", st, drawCalls);
    pass(gpu, MultiScatter, msAtt_, "sky-multiscatter", st, drawCalls);
    airKey_ = key;
    airDrawn_ = true;
    ++airBuilds_;
    viewDrawn_[0] = viewDrawn_[1] = false;  // the views were drawn from the old air
}

void PhysicalSky::update(Gpu& gpu, int slot, const PhysicalSkyState& st, int* drawCalls) {
    if (state_ <= 0) return;
    slot &= 1;
    update_air(gpu, st, drawCalls);
    const std::uint64_t key = sky_view_key(st.s, st.sunDir[1]);
    if (viewDrawn_[slot] && viewKey_[slot] == key) return;
    pass(gpu, SkyView, viewAtt_[slot], slot ? "sky-view-env" : "sky-view", st, drawCalls);
    viewKey_[slot] = key;
    viewDrawn_[slot] = true;
    ++viewBuilds_[slot];
}

void PhysicalSky::draw(Gpu& gpu, int slot, const PhysicalSkyState& st, bool sunDisc, const float* invViewProj,
                       const float camPos[3], const TargetFormat* format) {
    if (state_ <= 0) return;
    slot &= 1;
    gpu::CommandList& list = gpu.commands();  // the pass being drawn is open on it
    list.set_pipeline(format ? gpu.sky_pipeline(*format, shaders_[Sky]) : gpu.sky_pipeline(shaders_[Sky]));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_skyphys_sky_tr_tex] = trTex_;
    b.views[VIEW_skyphys_sky_ms_tex] = msTex_;
    b.views[VIEW_skyphys_sky_sv_tex] = viewTex_[slot];
    b.samplers[SMP_skyphys_sky_smp] = sampler_;
    list.set_bindings(b);
    skyphys_sky_vs_params_t vu{};
    std::memcpy(vu.inv_view_proj, invViewProj, sizeof(vu.inv_view_proj));
    for (int i = 0; i < 3; ++i) vu.cam_pos[i] = camPos[i];
    list.set_uniforms(UB_skyphys_sky_vs_params, gpu::Range{&vu, sizeof(vu)});
    skyphys_sky_params_t fu{};
    const SkyShaderParams p = sky_shader_params(st, sunDisc);
    std::memcpy(fu.q, p.v, sizeof(fu.q));
    list.set_uniforms(UB_skyphys_sky_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
}

void PhysicalSky::release() {
    if (device_) {
        gpu::Device& device = *device_;
        for (gpu::Pipeline& p : lutPipelines_) {
            if (p.id) device.destroy_pipeline(p);
            p = {};
        }
        for (gpu::Shader& s : shaders_) {
            if (s.id) device.destroy_shader(s);
            s = {};
        }
        destroy(device, trAtt_);
        destroy(device, trTex_);
        destroy(device, trImage_);
        destroy(device, msAtt_);
        destroy(device, msTex_);
        destroy(device, msImage_);
        for (int i = 0; i < 2; ++i) {
            destroy(device, viewAtt_[i]);
            destroy(device, viewTex_[i]);
            destroy(device, view_[i]);
        }
        if (sampler_.id) device.destroy_sampler(sampler_);
        sampler_ = {};
    }
    for (int i = 0; i < 2; ++i) viewDrawn_[i] = false;
    airDrawn_ = false;
    state_ = 0;
}

}  // namespace fa::render
