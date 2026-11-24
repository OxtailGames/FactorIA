#include "render_internal.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <type_traits>
#include <utility>

#include "fa/core/log.h"

#include "light_clusters.h"
#include "shader_cache.h"

#include "gpu/sokol_shaders.h"
#include "shaders/bloom.glsl.h"
#include "shaders/colorfilter.glsl.h"
#include "shaders/exposure.glsl.h"
#include "shaders/prepass_view.glsl.h"
#include "shaders/quad_motion.glsl.h"
#include "shaders/post.glsl.h"
#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/sky.glsl.h"
#include "shaders/ssao.glsl.h"

namespace fa::render {

namespace {
gpu::Sampler make_sampler(gpu::Device& device, gpu::Filter minmag, gpu::Filter mip, gpu::Wrap wrap, const char* label) {
    gpu::SamplerDesc d{};
    d.minFilter = minmag;
    d.magFilter = minmag;
    d.mipmapFilter = mip;
    d.wrapU = wrap;
    d.wrapV = wrap;
    d.maxLod = (mip == gpu::Filter::Linear) ? 1000.0f : 0.25f;
    if (mip == gpu::Filter::Linear) d.maxAnisotropy = 4;
    d.label = label;
    return device.make_sampler(d);
}

// Vertex buffer 1: a 4x4 model matrix per instance in four consecutive attributes starting at `firstAttr`.
//
// `bufferInst` (a mesh material with "buffers", MeshExtras::bufferInst) draws the entity as N instances that read
// storage buffers, and its model matrix is a uniform (FA_BUFFER_INST). Instance vertex buffer 1 would hold one matrix,
// so a per-instance step would read past its end from the second instance on. So the four attributes stay in the layout
// (the generated program still declares them, and the attribute slots must be contiguous) but read the first 16 bytes
// of each vertex of the mesh's own buffer 0, which is always in range: any N, any backend. A step rate cannot do this,
// because sokol_gfx narrows it to an int8 on OpenGL. The shader never uses the values. Buffer 1 is not part of this
// layout at all (a draw that still binds it is fine: sokol_gfx ignores a slot the layout does not use).
//
// Buffer 0 then needs explicit offsets: sokol_gfx packs them itself only while every one of them is 0, and it would
// pack the four instance attributes into the vertex too. So the other attributes of buffer 0 get the offsets of a
// packed MeshVertex, in location order, whatever is still unset when this runs (a shadow pipeline sets its skin
// attributes after it: they are skipped here, they live in buffer 2). The instance attributes get the offsets 0, 4, 8
// and 12: the last one ends at byte 28, inside the smallest vertex, and the offset 4 keeps sokol_gfx from packing a
// pipeline whose buffer 0 holds nothing but the position.
void set_instance_layout(gpu::PipelineDesc& d, int firstAttr, bool bufferInst = false) {
    if (bufferInst) {
        for (int i = 0; i < 4; ++i) {
            d.layout.attrs[firstAttr + i].format = gpu::VertexFormat::Float4;
            d.layout.attrs[firstAttr + i].bufferIndex = 0;
            d.layout.attrs[firstAttr + i].offset = i * 4;
        }
        int offset = 0;
        for (int i = 0; i < gpu::kMaxVertexAttributes; ++i) {
            gpu::VertexAttr& a = d.layout.attrs[i];
            if (a.format == gpu::VertexFormat::Invalid) continue;  // not set yet (see above)
            if (a.bufferIndex != 0 || (i >= firstAttr && i < firstAttr + 4)) continue;
            a.offset = offset;
            offset += a.format == gpu::VertexFormat::Float4   ? 16
                      : a.format == gpu::VertexFormat::Float3 ? 12
                      : a.format == gpu::VertexFormat::Float2 ? 8
                                                              : 4;  // UBYTE4N, the vertex color
        }
        if (d.layout.buffers[0].stride == 0) d.layout.buffers[0].stride = offset;
        return;
    }
    d.layout.buffers[1].stride = kMeshInstanceBytes;
    d.layout.buffers[1].stepFunc = gpu::VertexStep::PerInstance;
    for (int i = 0; i < 4; ++i) {
        d.layout.attrs[firstAttr + i].format = gpu::VertexFormat::Float4;
        d.layout.attrs[firstAttr + i].bufferIndex = 1;
        d.layout.attrs[firstAttr + i].offset = i * 16;
    }
}
// Vertex buffer 2 of a skinned part: SkinVertex (joint indices as bytes, then four weights).
void set_skin_layout(gpu::PipelineDesc& d, int jointsAttr, int weightsAttr) {
    d.layout.buffers[2].stride = sizeof(SkinVertex);
    d.layout.attrs[jointsAttr].format = gpu::VertexFormat::
        Ubyte4N;  // normalized: the shaders multiply by 255 (an integer attribute would not be a float)
    d.layout.attrs[jointsAttr].bufferIndex = 2;
    d.layout.attrs[jointsAttr].offset = 0;
    d.layout.attrs[weightsAttr].format = gpu::VertexFormat::Float4;
    d.layout.attrs[weightsAttr].bufferIndex = 2;
    d.layout.attrs[weightsAttr].offset = 4;
}
// Vertex buffer 6 of a prepass program: the previous model matrix of every instance as three rows (mesh_common.glsl fa_prev_r0..2).
void set_prev_layout(gpu::PipelineDesc& d, int firstAttr) {
    d.layout.buffers[kPrevModelBuffer].stride = kPrevModelBytes;
    d.layout.buffers[kPrevModelBuffer].stepFunc = gpu::VertexStep::PerInstance;
    for (int i = 0; i < 3; ++i) {
        d.layout.attrs[firstAttr + i].format = gpu::VertexFormat::Float4;
        d.layout.attrs[firstAttr + i].bufferIndex = kPrevModelBuffer;
        d.layout.attrs[firstAttr + i].offset = i * 16;
    }
}
// Vertex buffers 3, 4 and 5 of a custom material's program (MeshExtras): the per-instance params, then uv1 and color1,
// at the attributes from `firstAttr` in that order (mesh_common.glsl fa_extra_attrs).
void set_extra_layout(gpu::PipelineDesc& d, int firstAttr, const MeshExtras& e) {
    int at = firstAttr;
    if (e.instanceVec4 > 0) {
        d.layout.buffers[kInstanceDataBuffer].stride = e.instanceVec4 * 16;
        d.layout.buffers[kInstanceDataBuffer].stepFunc = gpu::VertexStep::PerInstance;
        for (int i = 0; i < e.instanceVec4; ++i, ++at) {
            d.layout.attrs[at].format = gpu::VertexFormat::Float4;
            d.layout.attrs[at].bufferIndex = kInstanceDataBuffer;
            d.layout.attrs[at].offset = i * 16;
        }
    }
    if (e.uv1) {
        d.layout.buffers[kUv1Buffer].stride = 8;
        d.layout.attrs[at].format = gpu::VertexFormat::Float2;
        d.layout.attrs[at].bufferIndex = kUv1Buffer;
        ++at;
    }
    if (e.color1) {
        d.layout.buffers[kColor1Buffer].stride = 4;
        d.layout.attrs[at].format = gpu::VertexFormat::Ubyte4N;
        d.layout.attrs[at].bufferIndex = kColor1Buffer;
    }
}
}  // namespace

void Gpu::refresh_scene_format() {
    const SceneChain& c = sceneChain_[linear_ ? 1 : 0];
    if (c.count <= 0) return;  // no chain (nothing was queried yet): keep the format
    sceneFormat_ = c.formats[std::min(c.at, c.count - 1)];
}

bool Gpu::set_linear(bool on) {
    if (on == linear_) return false;
    const gpu::PixelFormat before = sceneFormat_;
    linear_ = on;
    refresh_scene_format();
    return sceneFormat_ != before;
}

bool Gpu::next_scene_format() {
    SceneChain& c = sceneChain_[linear_ ? 1 : 0];
    if (c.at + 1 >= c.count) return false;
    ++c.at;
    refresh_scene_format();
    return true;
}

void Gpu::set_scene_pick(int pick) {
    SceneChain& c = sceneChain_[linear_ ? 1 : 0];
    c.at = std::clamp(pick, 0, std::max(0, c.count - 1));
    refresh_scene_format();
}

gpu::PixelFormat pick_ldr_cut_format(gpu::PixelFormat display, bool hdrOutput, bool half, bool full) {
    const bool isFloat = display == gpu::PixelFormat::Rgba16F || display == gpu::PixelFormat::Rgba32F;
    if (!hdrOutput || isFloat) return display;
    return half ? gpu::PixelFormat::Rgba16F : full ? gpu::PixelFormat::Rgba32F : display;
}

gpu::PixelFormat Gpu::ldr_cut_format(bool hdrOutput) const {
    const gpu::PixelFormat display = display_pixel_format();
    if (!hdrOutput) return display;
    auto usable = [this](gpu::PixelFormat f) {
        const gpu::PixelFormatCaps i = caps(f);
        return i.render && i.sample && i.filter;
    };
    return pick_ldr_cut_format(display, hdrOutput, usable(gpu::PixelFormat::Rgba16F),
                               usable(gpu::PixelFormat::Rgba32F));
}

bool Gpu::scene_has_alpha() const { return sceneFormat_ != gpu::PixelFormat::Rg11B10F; }
bool Gpu::scene_is_float() const {
    return sceneFormat_ == gpu::PixelFormat::Rgba16F || sceneFormat_ == gpu::PixelFormat::Rg11B10F;
}

gpu::PixelFormat Gpu::texture_format(gpu::PixelFormat unorm) const {
    if (!linear_) return unorm;
    gpu::PixelFormat srgb = gpu::PixelFormat::None;
    switch (unorm) {
        case gpu::PixelFormat::Rgba8: srgb = gpu::PixelFormat::Srgb8A8; break;
        case gpu::PixelFormat::Bc7Rgba: srgb = gpu::PixelFormat::Bc7Srgba; break;
        case gpu::PixelFormat::Astc4x4Rgba: srgb = gpu::PixelFormat::Astc4x4Srgba; break;
        case gpu::PixelFormat::Etc2Rgba8: srgb = gpu::PixelFormat::Etc2Srgb8A8; break;
        default: break;
    }
    if (srgb == gpu::PixelFormat::None) return unorm;
    const gpu::PixelFormatCaps info = caps(srgb);
    return info.sample && info.filter ? srgb : unorm;
}

gpu::PixelFormatCaps Gpu::caps(gpu::PixelFormat f) const {
    return device_ ? device_->pixel_format_caps(f) : gpu::PixelFormatCaps{};
}

bool Gpu::shader_valid(gpu::Shader s) const {
    return s.id && device_ && device_->state(s) == gpu::ResourceState::Valid;
}

void Gpu::drop_shader(gpu::Shader& s) {
    if (s.id && device_) device_->destroy_shader(s);
    s = {};
}

template <class GeneratedShader>
gpu::Shader Gpu::make_builtin(GeneratedShader desc, const char* label) {
    static_assert(std::is_same_v<GeneratedShader, gpu::GeneratedShader>, "a generated header's desc function");
    return make_shader(*device_, gpu::generated_shader_desc(*device_, desc), label);
}

void Gpu::commit_frame() {
    FA_ASSERT(device_ && list_, "Gpu::commit_frame() before Gpu::init() or after shutdown()");
    device_->submit(*list_);
    device_->commit();
    list_ = &device_->begin_commands("frame");
}

Gpu::~Gpu() = default;

bool Gpu::init(int sampleCount, std::string* error, std::unique_ptr<gpu::Device> device) {
    sampleCount_ = std::max(1, sampleCount);
    if (device) {
        device_ = std::move(device);
    } else {
        // The device adopts the sokol context the renderer opened (Renderer::init): `init` of make_device is not read.
        auto made = gpu::make_device(gpu::built_sokol_backend());
        if (!made) {
            if (error) *error = "Failed to create the GPU device: " + made.error().to_string();
            return false;
        }
        device_ = std::move(made.value());
    }
    if (sampleCount_ > 1 && !device_->pixel_format_caps(gpu::PixelFormat::Rgba8).msaa) {
        FA_WARN("render", "MSAA is not supported by this device; falling back to sampleCount 1");
        sampleCount_ = 1;
    }
    list_ = &device_->begin_commands("frame");
    const gpu::Backend backend = device_->backend();
    isGl_ = backend == gpu::Backend::Gl || backend == gpu::Backend::Gles3 || backend == gpu::Backend::WebGl2;
    zeroToOne_ = !isGl_;
    const gpu::PixelFormatCaps r32 = caps(gpu::PixelFormat::R32F);
    // The same test as render.supports "float32Targets" (render_features.cpp), so the report and the shadows agree.
    const gpu::PixelFormatCaps rgba32 = caps(gpu::PixelFormat::Rgba32F);
    shadowsSupported_ = r32.render && r32.sample && rgba32.render && rgba32.sample;
    {
        const gpu::PixelFormatCaps half = caps(gpu::PixelFormat::Rgba16F);
        const gpu::PixelFormatCaps eight = caps(gpu::PixelFormat::Rgba8);
        const bool halfOk = half.render && half.blend && half.filter;
        const bool eightOk = eight.render && eight.blend && eight.filter;
        lightFormat_ = halfOk ? gpu::PixelFormat::Rgba16F : eightOk ? gpu::PixelFormat::Rgba8 : gpu::PixelFormat::None;
        if (const char* want = std::getenv("FA_LIGHT_FORMAT")) {
            const std::string w = want;
            if (w == "rgba8")
                lightFormat_ = eightOk ? gpu::PixelFormat::Rgba8 : gpu::PixelFormat::None;
            else if (w == "none")
                lightFormat_ = gpu::PixelFormat::None;
            else if (w == "rgba16f")
                lightFormat_ = halfOk ? gpu::PixelFormat::Rgba16F : lightFormat_;
        }
    }

    {
        // The format of the game target and of every pass that draws into it or reads it (bloom, colour filter), in the order
        // they are tried. Gamma scene (every project before M71): RGBA16F where the GPU renders to it with blending and filtering
        // (and multisampling when asked), so a colour above white (an emissive above 1, a bright additive sum) reaches bloom,
        // else RGBA8, which keeps the frame but clamps at white. Linear scene (SceneSettings.colorSpace "linear"): the same,
        // then R11G11B10 (a float target without alpha, half the memory of RGBA16F: GPUs that cannot render to RGBA16F, phones),
        // then SRGB8A8 (8 bits that hold linear light: the GPU encodes what is written and decodes what is read, so the darks keep
        // their precision and blending is done in linear light), then plain RGBA8 (the GPU has no sRGB target: banding in the darks).
        const gpu::PixelFormatCaps half = caps(gpu::PixelFormat::Rgba16F);
        const bool halfOk = half.render && half.blend && half.filter && (sampleCount_ <= 1 || half.msaa);
        // sokol-gfx reports no blend flag for RG11B10F on GL (the format blends there when it renders at all); D3D11 and Metal do.
        const gpu::PixelFormatCaps packed = caps(gpu::PixelFormat::Rg11B10F);
        const bool packedOk =
            packed.render && packed.filter && (packed.blend || isGl_) && (sampleCount_ <= 1 || packed.msaa);
        const gpu::PixelFormatCaps srgb = caps(gpu::PixelFormat::Srgb8A8);
        const bool srgbTarget = srgb.render && srgb.blend && srgb.filter && (sampleCount_ <= 1 || srgb.msaa);
        srgbTextures_ = srgb.sample && srgb.filter;
        const std::string want = std::getenv("FA_SCENE_FORMAT") ? std::getenv("FA_SCENE_FORMAT") : "";
        for (SceneChain& c : sceneChain_) c = SceneChain{};
        auto add = [](SceneChain& c, gpu::PixelFormat f) { c.formats[c.count++] = f; };
        if (halfOk && want != "rgba8" && want != "r11g11b10") add(sceneChain_[0], gpu::PixelFormat::Rgba16F);
        add(sceneChain_[0], gpu::PixelFormat::Rgba8);
        if (halfOk && want != "rgba8" && want != "r11g11b10") add(sceneChain_[1], gpu::PixelFormat::Rgba16F);
        if (packedOk && want != "rgba8") add(sceneChain_[1], gpu::PixelFormat::Rg11B10F);
        if (srgbTarget) add(sceneChain_[1], gpu::PixelFormat::Srgb8A8);
        add(sceneChain_[1], gpu::PixelFormat::Rgba8);
        refresh_scene_format();
    }

    quad_shader_ = make_builtin(quad_quad_shader_desc, "quad_quad");
    quadPlainShader_ = make_builtin(quad_quad_plain_shader_desc, "quad_quad_plain");
    // The mesh, shadow and sky programs are made on first use (builtin_shader): a 2D game never compiles them.
    blit_shader_ = make_builtin(blit_blit_shader_desc, "blit_blit");
    blitKeepShader_ = make_builtin(blit_blit_keep_shader_desc, "blit_blit_keep");
    for (gpu::Shader s : {quad_shader_, quadPlainShader_, blit_shader_, blitKeepShader_}) {
        if (!shader_valid(s)) {
            if (error) {
                *error = "Failed to create a built-in shader for the " +
                         std::string(backend == gpu::Backend::Gl ? "OpenGL" : "current") +
                         " backend (see the sokol log lines above). The GL driver may be older than 4.3: "
                         "with Mesa try LIBGL_ALWAYS_SOFTWARE=1.";
            }
            return false;
        }
    }

    samplers_[int(SamplerKind::Nearest)] =
        make_sampler(*device_, gpu::Filter::Nearest, gpu::Filter::Nearest, gpu::Wrap::ClampToEdge, "nearest");
    samplers_[int(SamplerKind::Linear)] =
        make_sampler(*device_, gpu::Filter::Linear, gpu::Filter::Linear, gpu::Wrap::ClampToEdge, "linear");
    samplers_[int(SamplerKind::LinearRepeat)] =
        make_sampler(*device_, gpu::Filter::Linear, gpu::Filter::Linear, gpu::Wrap::Repeat, "linear-repeat");
    samplers_[int(SamplerKind::NearestRepeat)] =
        make_sampler(*device_, gpu::Filter::Nearest, gpu::Filter::Nearest, gpu::Wrap::Repeat, "nearest-repeat");
    // Bilinear, clamped, no mipmaps and no anisotropy: post-processing fetches (explicit LOD 0).
    samplers_[int(SamplerKind::LinearClamp)] =
        make_sampler(*device_, gpu::Filter::Linear, gpu::Filter::Nearest, gpu::Wrap::ClampToEdge, "linear-clamp");

    // Static quad index buffer: (0,1,2, 0,2,3) per quad.
    std::vector<std::uint16_t> idx(std::size_t(kMaxQuadsPerDraw) * 6);
    for (int q = 0; q < kMaxQuadsPerDraw; ++q) {
        std::uint16_t b = std::uint16_t(q * 4);
        std::uint16_t* p = &idx[std::size_t(q) * 6];
        p[0] = b;
        p[1] = std::uint16_t(b + 1);
        p[2] = std::uint16_t(b + 2);
        p[3] = b;
        p[4] = std::uint16_t(b + 2);
        p[5] = std::uint16_t(b + 3);
    }
    gpu::BufferDesc ib{};
    ib.usage.indexBuffer = true;
    ib.size = idx.size() * sizeof(std::uint16_t);
    ib.data = {idx.data(), ib.size};
    ib.label = "quad-indices";
    quadIndices_ = device_->make_buffer(ib);

    const float tri[] = {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f};
    gpu::BufferDesc tb{};
    tb.usage.vertexBuffer = true;
    tb.size = sizeof(tri);
    tb.data = {tri, sizeof(tri)};
    tb.label = "fullscreen-triangle";
    fsTriangle_ = device_->make_buffer(tb);
    listening_ = device_->add_commit_listener(&Gpu::count_commit, this);
    return true;
}

void Gpu::shutdown() {
    if (!device_) return;  // never initialised, or shut down already
    if (listening_) device_->remove_commit_listener(&Gpu::count_commit, this);
    listening_ = false;
    warming_ = false;
    for (auto& [k, p] : pipelines_) device_->destroy_pipeline(p.pipeline);
    pipelines_.clear();
    for (auto& t : transient_) device_->destroy_buffer(t.buf);
    transient_.clear();
    transientUsed_ = 0;
    for (auto& l : lightImages_) {
        if (l.view.id) device_->destroy_view(l.view);
        if (l.image.id) device_->destroy_image(l.image);
    }
    lightImages_.clear();
    lightImagesUsed_ = 0;
    for (auto& l : paletteImages_) {
        if (l.view.id) device_->destroy_view(l.view);
        if (l.image.id) device_->destroy_image(l.image);
    }
    paletteImages_.clear();
    paletteImagesUsed_ = 0;
    for (auto& s : samplers_) {
        device_->destroy_sampler(s);
        s = {};
    }
    device_->destroy_buffer(quadIndices_);
    device_->destroy_buffer(fsTriangle_);
    if (pacerSrc_.id) device_->destroy_buffer(pacerSrc_);
    if (pacerDst_.id) device_->destroy_buffer(pacerDst_);
    pacerSrc_ = pacerDst_ = {};
    pacedFrame_ = pacerCopyFrame_ = 0;
    pacerFailed_ = false;
    for (gpu::Shader* s : {&quad_shader_, &quadPlainShader_, &mesh_shader_, &sky_shader_, &shadow_shader_,
                           &blit_shader_, &blitKeepShader_, &meshSkinShader_, &shadowSkinShader_, &meshLodShader_,
                           &meshSkinLodShader_, &prepassLodShader_, &prepassSkinLodShader_})
        drop_shader(*s);
    for (gpu::Shader& s : bloom_shaders_) {
        if (s.id) device_->destroy_shader(s);
        s = {};
    }
    bloomState_ = 0;
    if (colorfilter_shader_.id) device_->destroy_shader(colorfilter_shader_);
    colorfilter_shader_ = {};
    colorfilterState_ = 0;
    if (post_shader_.id) device_->destroy_shader(post_shader_);
    post_shader_ = {};
    postState_ = 0;
    for (gpu::Shader& s : exposure_shaders_) {
        if (s.id) device_->destroy_shader(s);
        s = {};
    }
    exposureState_ = 0;
    for (gpu::Shader& s : ssao_shaders_) {
        if (s.id) device_->destroy_shader(s);
        s = {};
    }
    ssaoState_ = 0;
    for (gpu::Shader* s :
         {&prepassShader_, &prepassSkinShader_, &prepassViewShader_, &quadVelShader_, &quadReactShader_}) {
        if (s->id) device_->destroy_shader(*s);
        *s = {};
    }
    prepassState_ = prepassViewState_ = quadMotionState_ = 0;
    for (gpu::Shader* s : {&sssShader_, &sssSkinShader_}) {
        if (s->id) device_->destroy_shader(*s);
        *s = {};
    }
    sssState_ = 0;
    if (light_shader_.id) device_->destroy_shader(light_shader_);
    light_shader_ = {};
    lightState_ = 0;
    // The frame's list goes back to the device before it is released (the sokol context stays: it is the renderer's).
    device_->submit(*list_);
    list_ = nullptr;
    device_.reset();
}

void Gpu::sweep_pipelines() {
    // Nothing else holds a pipeline (every caller asks Gpu on each draw), so one that no draw asked for during the last
    // pipelineIdleFrames_ frames can go; it is made again if it is ever asked for. See "The pipeline cache" in
    // render_internal.h.
    for (auto it = pipelines_.begin(); it != pipelines_.end();) {
        if (!it->second.warmed && pipelineTick_ - it->second.lastUsed > pipelineIdleFrames_) {
            device_->destroy_pipeline(it->second.pipeline);
            it = pipelines_.erase(it);
            ++pipelinesEvicted_;
        } else {
            ++it;
        }
    }
}

void Gpu::destroy_shader(gpu::Shader shader) {
    if (!device_) return;
    for (auto it = pipelines_.begin(); it != pipelines_.end();) {
        if (it->first.shader == shader.id) {
            device_->destroy_pipeline(it->second.pipeline);
            it = pipelines_.erase(it);
        } else {
            ++it;
        }
    }
    failedComputePipelines_.erase(shader.id);
    device_->destroy_shader(shader);
}

bool Gpu::in_pass() const { return list_ && list_->pass_state() != gpu::PassState::None; }

gpu::Pipeline Gpu::compute_pipeline(gpu::Shader shader) {
    PipelineKey key{0xF00u, shader.id};
    auto it = pipelines_.find(key);
    if (it != pipelines_.end()) {
        it->second.lastUsed = pipelineTick_;
        ++pipelineHits_;
        return it->second.pipeline;
    }
    if (failedComputePipelines_.count(shader.id)) return {};  // the driver refused this program already (logged once)
    gpu::PipelineDesc d{};
    d.compute = true;
    d.shader = shader;
    d.label = "compute";
    const gpu::Pipeline p = device_->make_pipeline(d);
    if (device_->state(p) != gpu::ResourceState::Valid) {
        FA_ERROR("render", "failed to create a compute pipeline (the sokol log lines above have the reason)");
        device_->destroy_pipeline(p);
        failedComputePipelines_.insert(shader.id);
        return {};
    }
    ++pipelinesMade_;
    pipelines_[key] = {p, pipelineTick_, warming_};
    return p;
}

gpu::Pipeline Gpu::find_or_make(PipelineKey key, const TargetFormat& format, const gpu::PipelineDesc& request) {
    // A pipeline applied in a pass must have the pass's formats and sample count: CommandList::set_pipeline checks it
    // (a debug assertion on sokol, an errors() entry on RecordingDevice).
    if (layoutProbe_) {  // a test reads the layout a getter built; nothing is made or cached
        probedLayout_ = request.layout;
        return {};
    }
    key.format = format;
    auto it = pipelines_.find(key);
    if (it != pipelines_.end()) {
        it->second.lastUsed = pipelineTick_;
        if (warming_) it->second.warmed = true;
        ++pipelineHits_;
        return it->second.pipeline;
    }
    const gpu::TargetFormat target = format;
    gpu::PipelineDesc desc = request;  // a copy only on a miss (the description is more than 1 KB)
    desc.colors[0].pixelFormat = target.color;
    if (target.color1 != gpu::PixelFormat::None) {
        desc.colorCount = 2;
        desc.colors[1].pixelFormat = target.color1;
    }
    desc.depth.pixelFormat = target.depth;
    desc.sampleCount = target.samples;
    // The offsets sokol_gfx would pack, given: the mesh layouts pack buffer 0 and give the instance buffer's, which a backend
    // that packs only while every offset is 0 (Vulkan, D3D12) would read as buffer 0 at offset 0.
    gpu::resolve_vertex_offsets(desc.layout);
    // A pipeline asked for before its lazily made shader exists (a caller that skipped the *_ready() check) is an engine
    // bug: report it and keep it out of the cache, so the one early call does not break the key for the whole process.
    if (!shader_valid(desc.shader)) {
        FA_ERROR("render", "pipeline '{}' was asked for before its shader was made; it is not drawn (engine bug)",
                 desc.label ? desc.label : "?");
        return {};
    }
    const gpu::Pipeline p = device_->make_pipeline(desc);
    if (device_->state(p) != gpu::ResourceState::Valid) {
        FA_ERROR("render", "failed to create pipeline '{}'", desc.label ? desc.label : "?");
    }
    ++pipelinesMade_;
    pipelines_[key] = {p, pipelineTick_, warming_};
    return p;
}

gpu::Pipeline Gpu::quad_pipeline(const TargetFormat& format, bool depthTest, bool lines, BlendMode blend, bool plain,
                                 bool opaque, gpu::Shader shader, int instanceVec4) {
    PipelineKey key{0x100u | (depthTest ? 1u : 0u) | (lines ? 2u : 0u) | (std::uint32_t(blend) << 2) |
                        (plain ? 0x10u : 0u) | (opaque ? 0x20u : 0u),
                    shader.id};
    gpu::PipelineDesc d{};
    d.shader = shader.id ? shader : (plain ? quadPlainShader_ : quad_shader_);
    d.layout.attrs[ATTR_quad_quad_position].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_quad_quad_texcoord0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_quad_quad_color0].format = gpu::VertexFormat::Ubyte4N;
    d.layout.attrs[ATTR_quad_quad_params0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_quad_quad_color2_0].format = gpu::VertexFormat::Ubyte4N;
    d.layout.attrs[ATTR_quad_quad_shape_half0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_quad_quad_shape_rs0].format = gpu::VertexFormat::Half2;
    if (instanceVec4 > 0) {
        // sokol computes the offsets of every attribute or of none: with the second buffer they are given, as Vertex2D
        // has them.
        static_assert(sizeof(Vertex2D) == 48, "the offsets below are those of Vertex2D");
        d.layout.attrs[ATTR_quad_quad_position].offset = 0;
        d.layout.attrs[ATTR_quad_quad_texcoord0].offset = 12;
        d.layout.attrs[ATTR_quad_quad_color0].offset = 20;
        d.layout.attrs[ATTR_quad_quad_params0].offset = 24;
        d.layout.attrs[ATTR_quad_quad_color2_0].offset = 32;
        d.layout.attrs[ATTR_quad_quad_shape_half0].offset = 36;
        d.layout.attrs[ATTR_quad_quad_shape_rs0].offset = 44;
        d.layout.buffers[0].stride = int(sizeof(Vertex2D));
        const int n = std::min(instanceVec4, kMaxInstanceVec4);
        d.layout.buffers[kQuadInstBuffer].stride = n * 16;
        for (int i = 0; i < n; ++i) {
            d.layout.attrs[kQuadInstAttr + i].format = gpu::VertexFormat::Float4;
            d.layout.attrs[kQuadInstAttr + i].bufferIndex = kQuadInstBuffer;
            d.layout.attrs[kQuadInstAttr + i].offset = i * 16;
        }
    }
    d.primitiveType = lines ? gpu::PrimitiveType::Lines : gpu::PrimitiveType::Triangles;
    d.indexType = lines ? gpu::IndexType::None : gpu::IndexType::Uint16;
    d.depth.compare = depthTest ? gpu::CompareFunc::LessEqual : gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.colors[0].blend.enabled = !opaque;
    switch (blend) {
        case BlendMode::Additive:  // dst + src.rgb * src.a  (glow: overlapping items accumulate light)
            d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
            d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
            d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
            d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
            break;
        case BlendMode::Multiply:  // dst * lerp(1, src.rgb, src.a)
            d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::DstColor;
            d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::Zero;  // shader emits mix(1, rgb, a) (mode + 8)
            d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
            d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
            break;
        case BlendMode::Alpha:
        default:
            d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
            d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::OneMinusSrcAlpha;
            d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
            d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::OneMinusSrcAlpha;
            break;
    }
    d.cullMode = gpu::CullMode::None;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = lines   ? "quad-lines"
              : plain ? (depthTest ? "quad-3d-plain" : "quad-2d-plain")
                      : (depthTest ? "quad-3d" : "quad-2d");
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::mesh_pipeline(const TargetFormat& format, bool blended, bool doubleSided, bool skinned,
                                 gpu::Shader shader, MeshExtras extras, bool glass, bool lod) {
    lod = lod && !shader.id;  // a custom material has no variant: its alphaMode "clip" program dithers
    PipelineKey key{0x200u | (blended ? 1u : 0u) | (doubleSided ? 2u : 0u) | (skinned ? 4u : 0u) | (glass ? 8u : 0u) |
                        (lod ? 0x10u : 0u),
                    shader.id};
    gpu::PipelineDesc d{};
    if (shader.id)
        d.shader = shader;
    else if (lod)
        d.shader = skinned ? builtin_shader(meshSkinLodShader_, mesh_mesh_skin_lod_shader_desc, "mesh_mesh_skin_lod")
                           : builtin_shader(meshLodShader_, mesh_mesh_lod_shader_desc, "mesh_mesh_lod");
    else
        d.shader = skinned ? builtin_shader(meshSkinShader_, mesh_mesh_skin_shader_desc, "mesh_mesh_skin")
                           : builtin_shader(mesh_shader_, mesh_mesh_shader_desc, "mesh_mesh");
    d.layout.attrs[ATTR_mesh_mesh_fa_position].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_mesh_fa_normal].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_mesh_fa_texcoord0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_mesh_mesh_fa_tangent].format = gpu::VertexFormat::Float4;
    d.layout.attrs[ATTR_mesh_mesh_fa_color].format =
        gpu::VertexFormat::Ubyte4N;  // vertex color, white without (MeshVertex::color)
    set_instance_layout(d, ATTR_mesh_mesh_fa_inst_m0, shader.id && extras.bufferInst);
    if (skinned) set_skin_layout(d, ATTR_mesh_mesh_skin_fa_joints, ATTR_mesh_mesh_skin_fa_weights);
    if (shader.id) {
        set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    } else if (!skinned) {
        // The engine's own program reads the lightmap UV (uv1, vertex buffer 4) of every mesh: the draw binds the lightmap UV or zeros.
        MeshExtras lm;
        lm.uv1 = true;
        set_extra_layout(d, kExtraAttrBase, lm);
    }
    d.indexType = gpu::IndexType::Uint32;
    d.depth.compare = gpu::CompareFunc::LessEqual;
    d.depth.writeEnabled = !blended;
    if (blended) {
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
        d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::OneMinusSrcAlpha;
        d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::OneMinusSrcAlpha;
    }
    // A blended mesh draws both faces (no depth write: the order inside it is the index order); a glass mesh (transmission) only the faces that
    // look at the camera unless it is double sided, because its back faces would refract the picture again over the front ones.
    d.cullMode = (doubleSided || (blended && !glass)) ? gpu::CullMode::None : gpu::CullMode::Back;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "mesh";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::full_pipeline(const TargetFormat& format, const MaterialPassState& state, bool skinned,
                                 gpu::Shader shader, MeshExtras extras) {
    PipelineKey key{0x1000u | (skinned ? 1u : 0u) | (unsigned(state.cull) << 1) | (state.depthTest ? 8u : 0u) |
                        (state.depthWrite ? 16u : 0u) | (unsigned(state.blend) << 5),
                    shader.id};
    gpu::PipelineDesc d{};
    d.shader = shader;
    d.layout.attrs[ATTR_mesh_mesh_fa_position].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_mesh_fa_normal].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_mesh_fa_texcoord0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_mesh_mesh_fa_tangent].format = gpu::VertexFormat::Float4;
    d.layout.attrs[ATTR_mesh_mesh_fa_color].format = gpu::VertexFormat::Ubyte4N;
    set_instance_layout(d, ATTR_mesh_mesh_fa_inst_m0, shader.id && extras.bufferInst);
    if (skinned) set_skin_layout(d, ATTR_mesh_mesh_skin_fa_joints, ATTR_mesh_mesh_skin_fa_weights);
    set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    d.indexType = gpu::IndexType::Uint32;
    d.depth.compare = state.depthTest ? gpu::CompareFunc::LessEqual : gpu::CompareFunc::Always;
    d.depth.writeEnabled = state.depthWrite;
    if (state.blend != 0) {
        d.colors[0].blend.enabled = true;
        switch (state.blend) {
            case 2:  // additive: dst + src.rgb * src.a
                d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
                d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
                d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
                d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
                break;
            case 3:  // multiply: dst * src.rgb
                d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::DstColor;
                d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::Zero;
                d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
                d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
                break;
            default:  // alpha
                d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::SrcAlpha;
                d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::OneMinusSrcAlpha;
                d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
                d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::OneMinusSrcAlpha;
                break;
        }
    }
    d.cullMode = state.cull == 0 ? gpu::CullMode::None : state.cull == 2 ? gpu::CullMode::Front : gpu::CullMode::Back;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "mesh-full";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::sky_pipeline(const TargetFormat& format, gpu::Shader shader) {
    PipelineKey key{0x300u, shader.id};
    gpu::PipelineDesc d{};
    d.shader = shader.id ? shader : builtin_shader(sky_shader_, sky_sky_shader_desc, "sky_sky");
    d.layout.attrs[ATTR_sky_sky_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "sky";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::shadow_pipeline(const TargetFormat& format, bool skinned, gpu::Shader shader, bool fullVertex,
                                   MeshExtras extras) {
    PipelineKey key{0x400u | (skinned ? 1u : 0u) | (fullVertex ? 2u : 0u), shader.id};
    gpu::PipelineDesc d{};
    d.shader = shader.id
                   ? shader
                   : (skinned ? builtin_shader(shadowSkinShader_, mesh_shadow_skin_shader_desc, "mesh_shadow_skin")
                              : builtin_shader(shadow_shader_, mesh_shadow_shader_desc, "mesh_shadow"));
    d.layout.attrs[ATTR_mesh_shadow_fa_position].format = gpu::VertexFormat::Float3;
    d.layout.buffers[0].stride = sizeof(MeshVertex);  // position is the first member of MeshVertex
    if (fullVertex) {  // offsets are the packed ones of MeshVertex: attributes of buffer 0 in location order
        const int first = skinned ? 7 : 5;
        d.layout.attrs[first].format = gpu::VertexFormat::Float3;       // normal
        d.layout.attrs[first + 1].format = gpu::VertexFormat::Float2;   // texcoord0
        d.layout.attrs[first + 2].format = gpu::VertexFormat::Float4;   // tangent
        d.layout.attrs[first + 3].format = gpu::VertexFormat::Ubyte4N;  // vertex color
    }
    set_instance_layout(d, ATTR_mesh_shadow_fa_inst_m0, shader.id && extras.bufferInst);
    if (skinned) set_skin_layout(d, ATTR_mesh_shadow_skin_fa_joints, ATTR_mesh_shadow_skin_fa_weights);
    if (shader.id && fullVertex) set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    d.indexType = gpu::IndexType::Uint32;
    d.depth.compare = gpu::CompareFunc::LessEqual;
    d.depth.writeEnabled = true;
    d.cullMode = gpu::CullMode::None;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "shadow";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::blit_pipeline(const TargetFormat& format) {
    PipelineKey key{0x500u};
    gpu::PipelineDesc d{};
    d.shader = blit_shader_;
    d.layout.attrs[ATTR_blit_blit_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "blit";
    return find_or_make(key, format, d);
}

bool Gpu::bloom_ready() {
    if (bloomState_ != 0) return bloomState_ > 0;
    bloom_shaders_[int(BloomStage::Bright)] = make_builtin(bloom_bright_shader_desc, "bloom_bright");
    bloom_shaders_[int(BloomStage::Down)] = make_builtin(bloom_down_shader_desc, "bloom_down");
    bloom_shaders_[int(BloomStage::Blur)] = make_builtin(bloom_blur_shader_desc, "bloom_blur");
    bloom_shaders_[int(BloomStage::Composite)] = make_builtin(bloom_composite_shader_desc, "bloom_composite");
    bool ok = true;
    for (gpu::Shader s : bloom_shaders_) ok = ok && shader_valid(s);
    if (!ok) {
        for (gpu::Shader& s : bloom_shaders_) {
            if (s.id) device_->destroy_shader(s);
            s = {};
        }
        bloomState_ = -1;
        FA_ERROR("render",
                 "PostProcess bloom is unavailable: the bloom shaders failed to compile for this graphics backend "
                 "(see the sokol log lines above). The game renders without bloom. Hint: update the graphics driver "
                 "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or switch PostProcess.bloomEnabled off.");
        return false;
    }
    bloomState_ = 1;
    return true;
}

gpu::Pipeline Gpu::blit_keep_pipeline(const TargetFormat& format) {
    PipelineKey key{0x900u};
    gpu::PipelineDesc d{};
    d.shader = blitKeepShader_;
    d.layout.attrs[ATTR_blit_blit_keep_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "blit-keep";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::bloom_pipeline(BloomStage stage, const TargetFormat& format) {
    PipelineKey key{0x600u | std::uint32_t(stage)};
    gpu::PipelineDesc d{};
    d.shader = bloom_shaders_[int(stage)];
    // All four programs share the vertex shader and therefore the same single `pos` attribute at location 0.
    d.layout.attrs[ATTR_bloom_bright_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    switch (stage) {
        case BloomStage::Composite:  // dst.rgb += src.rgb (intensity is applied in the shader); alpha stays
            d.colors[0].blend.enabled = true;
            d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
            d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
            d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
            d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
            d.label = "bloom-composite";
            break;
        case BloomStage::Bright: d.label = "bloom-bright"; break;
        case BloomStage::Down: d.label = "bloom-down"; break;
        default: d.label = "bloom-blur"; break;
    }
    return find_or_make(key, format, d);
}

bool Gpu::colorfilter_ready() {
    if (colorfilterState_ != 0) return colorfilterState_ > 0;
    colorfilter_shader_ = make_builtin(colorfilter_colorfilter_shader_desc, "colorfilter_colorfilter");
    if (!shader_valid(colorfilter_shader_)) {
        device_->destroy_shader(colorfilter_shader_);
        colorfilter_shader_ = {};
        colorfilterState_ = -1;
        FA_ERROR("render",
                 "PostProcess colorFilter is unavailable: the colour filter shader failed to compile for this graphics "
                 "backend (see the sokol log lines above). The game renders without the filter. Hint: update the "
                 "graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or switch PostProcess.colorFilterEnabled off.");
        return false;
    }
    colorfilterState_ = 1;
    return true;
}

gpu::Pipeline Gpu::colorfilter_pipeline(const TargetFormat& format) {
    if (!colorfilter_ready()) return {};
    PipelineKey key{0x700u};
    gpu::PipelineDesc d{};
    d.shader = colorfilter_shader_;
    d.layout.attrs[ATTR_colorfilter_colorfilter_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "colorfilter";
    return find_or_make(key, format, d);
}

bool Gpu::post_ready() {
    ++postReadyCalls_;
    if (postState_ != 0) return postState_ > 0;
    post_shader_ = make_builtin(post_post_shader_desc, "post_post");
    if (!shader_valid(post_shader_)) {
        device_->destroy_shader(post_shader_);
        post_shader_ = {};
        postState_ = -1;
        FA_ERROR("render",
                 "The post-processing pass (exposure, tonemap, colour filter) is unavailable: its shader failed to "
                 "compile for "
                 "this graphics backend (see the sokol log lines above). The game renders without it. Hint: update the "
                 "graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or remove the PostProcess component.");
        return false;
    }
    postState_ = 1;
    return true;
}

gpu::Pipeline Gpu::post_pipeline(const TargetFormat& format) {
    if (!post_ready()) return {};
    PipelineKey key{0xA00u};
    gpu::PipelineDesc d{};
    d.shader = post_shader_;
    d.layout.attrs[ATTR_post_post_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "post";
    return find_or_make(key, format, d);
}

gpu::PixelFormat Gpu::prepass_color_format() const {
    // The prepass image is only sampled with a nearest sampler (a depth is never blended or filtered), so it needs no more than render + sample.
    for (gpu::PixelFormat f : {gpu::PixelFormat::Rgba32F, gpu::PixelFormat::Rgba16F}) {
        const gpu::PixelFormatCaps info = caps(f);
        if (info.render && info.sample) return f;
    }
    return gpu::PixelFormat::None;
}

namespace {
// The slots a built-in program declares, as the twin of a custom one says them (MaterialProgram).
MaterialProgram program_slots(gpu::Shader shader, const gpu::ShaderDesc& desc) {
    MaterialProgram out;
    out.shader = shader;
    for (int i = 0; i < gpu::kMaxUniformBlocks; ++i) {
        if (desc.uniformBlocks[i].stage == gpu::ShaderStage::None) continue;
        out.ubMask |= 1u << i;
        out.ubSize[i] = desc.uniformBlocks[i].size;
    }
    for (int i = 0; i < gpu::kMaxViews; ++i)
        if (desc.views[i].texture.stage != gpu::ShaderStage::None) out.viewMask |= 1u << i;
    for (int i = 0; i < gpu::kMaxSamplers; ++i)
        if (desc.samplers[i].stage != gpu::ShaderStage::None) out.samplerMask |= 1u << i;
    return out;
}
}  // namespace

bool Gpu::velocity_ready() {
    if (!prepass_ready()) return false;
    const gpu::PixelFormatCaps info = caps(velocity_format());
    return info.render && info.sample;
}

bool Gpu::prepass_ready() {
    if (prepassState_ != 0) return prepassState_ > 0;
    prepassShader_ = make_builtin(mesh_prepass_shader_desc, "mesh_prepass");
    prepassSkinShader_ = make_builtin(mesh_prepass_skin_shader_desc, "mesh_prepass_skin");
    if (prepass_color_format() == gpu::PixelFormat::None || !shader_valid(prepassShader_) ||
        !shader_valid(prepassSkinShader_)) {
        for (gpu::Shader* s : {&prepassShader_, &prepassSkinShader_}) {
            if (s->id) device_->destroy_shader(*s);
            *s = {};
        }
        prepassState_ = -1;
        FA_ERROR(
            "render",
            "The depth and normal prepass is unavailable: the GPU cannot render to a float image or its shader failed "
            "to "
            "compile for this graphics backend (see the sokol log lines above). The effects that read the depth are "
            "skipped. Hint: update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    prepassProgram_[0] = program_slots(prepassShader_, gpu::generated_shader_desc(*device_, mesh_prepass_shader_desc));
    prepassProgram_[1] =
        program_slots(prepassSkinShader_, gpu::generated_shader_desc(*device_, mesh_prepass_skin_shader_desc));
    prepassState_ = 1;
    return true;
}

gpu::Pipeline Gpu::prepass_pipeline(const TargetFormat& format, bool doubleSided, bool skinned, gpu::Shader shader,
                                    MeshExtras extras, bool cullFront, bool lod) {
    if (!shader.id && !prepass_ready()) return {};
    lod = lod && !shader.id;  // a custom material has no variant: its alphaMode "clip" program dithers
    PipelineKey key{0xC00u | (doubleSided ? 2u : 0u) | (skinned ? 4u : 0u) | (cullFront ? 8u : 0u) | (lod ? 0x10u : 0u),
                    shader.id};
    gpu::PipelineDesc d{};
    if (shader.id)
        d.shader = shader;
    else if (lod)
        d.shader =
            skinned ? builtin_shader(prepassSkinLodShader_, mesh_prepass_skin_lod_shader_desc, "mesh_prepass_skin_lod")
                    : builtin_shader(prepassLodShader_, mesh_prepass_lod_shader_desc, "mesh_prepass_lod");
    else
        d.shader = skinned ? prepassSkinShader_ : prepassShader_;
    d.layout.attrs[ATTR_mesh_prepass_fa_position].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_prepass_fa_normal].format = gpu::VertexFormat::Float3;
    d.layout.attrs[ATTR_mesh_prepass_fa_texcoord0].format = gpu::VertexFormat::Float2;
    d.layout.attrs[ATTR_mesh_prepass_fa_tangent].format = gpu::VertexFormat::Float4;
    d.layout.attrs[ATTR_mesh_prepass_fa_color].format = gpu::VertexFormat::Ubyte4N;
    set_instance_layout(d, ATTR_mesh_prepass_fa_inst_m0, shader.id && extras.bufferInst);
    if (skinned) set_skin_layout(d, ATTR_mesh_prepass_skin_fa_joints, ATTR_mesh_prepass_skin_fa_weights);
    if (shader.id) set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    // The previous model matrix (M76): in the layout of every program that declares it, drawing with the velocity image or not (a vertex
    // layout must hold every attribute the vertex shader reads); the pass binds a buffer that has no use for it when nothing asks.
    if (const int prev = prepass_prev_attr(skinned, shader.id != 0, extras); prev >= 0) set_prev_layout(d, prev);
    d.indexType = gpu::IndexType::Uint32;
    d.depth.compare = gpu::CompareFunc::LessEqual;
    d.depth.writeEnabled = true;
    d.cullMode = cullFront ? gpu::CullMode::Front : (doubleSided ? gpu::CullMode::None : gpu::CullMode::Back);
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "prepass";
    return find_or_make(key, format, d);
}

// Since M73 the mesh fragment shader is about 100 KB of GLSL; a driver that compiles it at start (Mesa keeps the NIR of
// every linked program) costs a game that draws no mesh around 100 MB of peak memory. So the 3D programs are made the
// first time a pipeline asks for one: the renderer's warm-up asks only when the scene has a MeshRenderer. A program
// the driver rejects is reported once and kept (find_or_make then makes no pipeline from it) rather than retried.
template <class GeneratedShader>
gpu::Shader Gpu::builtin_shader(gpu::Shader& slot, GeneratedShader desc, const char* label) {
    if (slot.id || layoutProbe_) return slot;
    slot = make_builtin(desc, label);
    if (!shader_valid(slot)) {
        FA_ERROR("render",
                 "Failed to create the built-in shader '{}' for this backend (see the sokol log lines above): what it "
                 "draws is skipped. With Mesa an older GL than 4.3 may be the cause: try LIBGL_ALWAYS_SOFTWARE=1.",
                 label);
    }
    return slot;
}

bool Gpu::sss_ready() {
    if (sssState_ != 0) return sssState_ > 0;
    sssShader_ = make_builtin(mesh_mesh_sss_shader_desc, "mesh_mesh_sss");
    sssSkinShader_ = make_builtin(mesh_mesh_skin_sss_shader_desc, "mesh_mesh_skin_sss");
    const gpu::PixelFormatCaps fmt = caps(gpu::PixelFormat::Rgba16F);
    if (!fmt.render || !fmt.sample || !shader_valid(sssShader_) || !shader_valid(sssSkinShader_)) {
        for (gpu::Shader* s : {&sssShader_, &sssSkinShader_}) {
            if (s->id) device_->destroy_shader(*s);
            *s = {};
        }
        sssState_ = -1;
        FA_ERROR(
            "render",
            "Subsurface scattering is unavailable: the GPU cannot render to a half-float image or the shader of the "
            "scattering meshes failed to compile for this graphics backend (see the sokol log lines above). "
            "Meshes with MeshRenderer.subsurface draw without it. Hint: update the graphics driver (Mesa: try "
            "LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    sssProgram_[0] = program_slots(sssShader_, gpu::generated_shader_desc(*device_, mesh_mesh_sss_shader_desc));
    sssProgram_[1] =
        program_slots(sssSkinShader_, gpu::generated_shader_desc(*device_, mesh_mesh_skin_sss_shader_desc));
    sssState_ = 1;
    return true;
}

gpu::Pipeline Gpu::sss_pipeline(bool doubleSided, bool skinned) {
    if (!sss_ready()) return {};
    PipelineKey key{0xD80u | (doubleSided ? 2u : 0u) | (skinned ? 4u : 0u)};
    gpu::PipelineDesc d{};
    d.shader = skinned ? sssSkinShader_ : sssShader_;
    if (skinned) {
        d.layout.attrs[ATTR_mesh_mesh_skin_sss_fa_position].format = gpu::VertexFormat::Float3;
        d.layout.attrs[ATTR_mesh_mesh_skin_sss_fa_normal].format = gpu::VertexFormat::Float3;
        d.layout.attrs[ATTR_mesh_mesh_skin_sss_fa_texcoord0].format = gpu::VertexFormat::Float2;
        d.layout.attrs[ATTR_mesh_mesh_skin_sss_fa_tangent].format = gpu::VertexFormat::Float4;
        d.layout.attrs[ATTR_mesh_mesh_skin_sss_fa_color].format = gpu::VertexFormat::Ubyte4N;
        set_instance_layout(d, ATTR_mesh_mesh_skin_sss_fa_inst_m0, false);
        set_skin_layout(d, ATTR_mesh_mesh_skin_sss_fa_joints, ATTR_mesh_mesh_skin_sss_fa_weights);
    } else {
        d.layout.attrs[ATTR_mesh_mesh_sss_fa_position].format = gpu::VertexFormat::Float3;
        d.layout.attrs[ATTR_mesh_mesh_sss_fa_normal].format = gpu::VertexFormat::Float3;
        d.layout.attrs[ATTR_mesh_mesh_sss_fa_texcoord0].format = gpu::VertexFormat::Float2;
        d.layout.attrs[ATTR_mesh_mesh_sss_fa_tangent].format = gpu::VertexFormat::Float4;
        d.layout.attrs[ATTR_mesh_mesh_sss_fa_color].format = gpu::VertexFormat::Ubyte4N;
        set_instance_layout(d, ATTR_mesh_mesh_sss_fa_inst_m0, false);
        // Like the engine's own main program: the lightmap UV (vertex buffer 4), which the draw binds as zeros when the mesh has none.
        MeshExtras lm;
        lm.uv1 = true;
        set_extra_layout(d, kExtraAttrBase, lm);
    }
    d.indexType = gpu::IndexType::Uint32;
    d.depth.compare = gpu::CompareFunc::LessEqual;
    d.depth.writeEnabled = true;
    d.cullMode = doubleSided ? gpu::CullMode::None : gpu::CullMode::Back;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "mesh-sss";
    return find_or_make(key, sss_target_format(), d);
}

bool Gpu::prepass_view_ready() {
    if (prepassViewState_ != 0) return prepassViewState_ > 0;
    prepassViewShader_ = make_builtin(prepass_view_prepass_view_shader_desc, "prepass_view");
    if (!shader_valid(prepassViewShader_)) {
        device_->destroy_shader(prepassViewShader_);
        prepassViewShader_ = {};
        prepassViewState_ = -1;
        FA_ERROR("render",
                 "The prepass debug view is unavailable: its shader failed to compile for this graphics backend.");
        return false;
    }
    prepassViewState_ = 1;
    return true;
}

gpu::Pipeline Gpu::prepass_view_pipeline(const TargetFormat& format) {
    if (!prepass_view_ready()) return {};
    PipelineKey key{0xD00u};
    gpu::PipelineDesc d{};
    d.shader = prepassViewShader_;
    d.layout.attrs[ATTR_prepass_view_prepass_view_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "prepass-view";
    return find_or_make(key, format, d);
}

bool Gpu::reactive_ready() {
    const gpu::PixelFormatCaps info = caps(reactive_format());
    return info.render && info.sample && quad_motion_ready();
}

bool Gpu::quad_motion_ready() {
    if (quadMotionState_ != 0) return quadMotionState_ > 0;
    quadVelShader_ = make_builtin(quad_motion_quad_vel_shader_desc, "quad_vel");
    quadReactShader_ = make_builtin(quad_motion_quad_react_shader_desc, "quad_react");
    if (!shader_valid(quadVelShader_) || !shader_valid(quadReactShader_)) {
        for (gpu::Shader* s : {&quadVelShader_, &quadReactShader_}) {
            if (s->id) device_->destroy_shader(*s);
            *s = {};
        }
        quadMotionState_ = -1;
        FA_ERROR(
            "render",
            "The motion vectors and the reactive mask of sprites and particles are unavailable: their shader failed "
            "to compile for this graphics backend (temporal antialiasing then reprojects them from the depth).");
        return false;
    }
    quadMotionState_ = 1;
    return true;
}

gpu::Pipeline Gpu::quad_motion_pipeline(const TargetFormat& format, bool reactive) {
    if (!quad_motion_ready()) return {};
    PipelineKey key{0xD10u | (reactive ? 1u : 0u)};
    gpu::PipelineDesc d{};
    d.shader = reactive ? quadReactShader_ : quadVelShader_;
    // The offsets are Vertex2D's (sokol computes all of them or none): the first four attributes of the quad vertex, then the motion.
    static_assert(sizeof(Vertex2D) == 48, "the offsets below are those of Vertex2D");
    d.layout.buffers[0].stride = int(sizeof(Vertex2D));
    d.layout.attrs[ATTR_quad_motion_quad_vel_position] = {0, 0, gpu::VertexFormat::Float3};
    d.layout.attrs[ATTR_quad_motion_quad_vel_texcoord0] = {0, 12, gpu::VertexFormat::Float2};
    d.layout.attrs[ATTR_quad_motion_quad_vel_color0] = {0, 20, gpu::VertexFormat::Ubyte4N};
    d.layout.attrs[ATTR_quad_motion_quad_vel_params0] = {0, 24, gpu::VertexFormat::Float2};
    d.layout.buffers[kQuadMotionBuffer].stride = int(kQuadMotionStride);
    d.layout.attrs[ATTR_quad_motion_quad_vel_motion] = {kQuadMotionBuffer, 0, gpu::VertexFormat::Float4};
    d.primitiveType = gpu::PrimitiveType::Triangles;
    d.indexType = gpu::IndexType::Uint16;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    if (reactive) {  // the largest value wins: overlapping particles do not add up past what one of them asks
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.opRgb = gpu::BlendOp::Max;
        d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
        d.colors[0].blend.opAlpha = gpu::BlendOp::Max;
        d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
        d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
    }
    d.cullMode = gpu::CullMode::None;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = reactive ? "quad-reactive" : "quad-velocity";
    return find_or_make(key, format, d);
}

gpu::Pipeline Gpu::post_material_pipeline(const TargetFormat& format, gpu::Shader shader) {
    if (!shader.id) return {};
    PipelineKey key{0xF00u, shader.id};
    gpu::PipelineDesc d{};
    d.shader = shader;
    d.layout.attrs[0].format = gpu::VertexFormat::Float2;  // `pos` of post_common.glsl, location 0
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "post-material";
    return find_or_make(key, format, d);
}

bool Gpu::exposure_ready() {
    if (exposureState_ != 0) return exposureState_ > 0;
    exposure_shaders_[int(ExposureStage::Luma)] = make_builtin(exposure_luma_shader_desc, "exposure_luma");
    exposure_shaders_[int(ExposureStage::Adapt)] = make_builtin(exposure_adapt_shader_desc, "exposure_adapt");
    bool ok = true;
    for (gpu::Shader s : exposure_shaders_) ok = ok && shader_valid(s);
    if (!ok) {
        for (gpu::Shader& s : exposure_shaders_) {
            if (s.id) device_->destroy_shader(s);
            s = {};
        }
        exposureState_ = -1;
        FA_ERROR(
            "render",
            "The automatic exposure is unavailable: its shaders failed to compile for this graphics backend (see the "
            "sokol log lines above). The exposure stays at PostProcess.exposureEv. Hint: update the graphics driver "
            "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set exposureMode to manual.");
        return false;
    }
    exposureState_ = 1;
    return true;
}

gpu::Pipeline Gpu::exposure_pipeline(ExposureStage stage, const TargetFormat& format) {
    if (!exposure_ready()) return {};
    PipelineKey key{0xB00u | std::uint32_t(stage)};
    gpu::PipelineDesc d{};
    d.shader = exposure_shaders_[int(stage)];
    d.layout.attrs[ATTR_exposure_luma_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = stage == ExposureStage::Luma ? "exposure-luma" : "exposure-adapt";
    return find_or_make(key, format, d);
}

bool Gpu::ssao_ready() {
    if (ssaoState_ != 0) return ssaoState_ > 0;
    ssao_shaders_[0] = make_builtin(ssao_ao_shader_desc, "ssao_ao");
    ssao_shaders_[1] = make_builtin(ssao_blur_shader_desc, "ssao_blur");
    ssao_shaders_[2] = make_builtin(ssao_apply_shader_desc, "ssao_apply");
    bool ok = true;
    for (gpu::Shader s : ssao_shaders_) ok = ok && shader_valid(s);
    if (!ok) {
        for (gpu::Shader& s : ssao_shaders_) {
            if (s.id) device_->destroy_shader(s);
            s = {};
        }
        ssaoState_ = -1;
        FA_ERROR(
            "render",
            "The ambient occlusion is unavailable: its shaders failed to compile for this graphics backend (see the "
            "sokol log lines above). PostProcess.ssaoEnabled draws nothing. Hint: update the graphics driver "
            "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set ssaoEnabled to false.");
        return false;
    }
    ssaoState_ = 1;
    return true;
}

gpu::Pipeline Gpu::ssao_pipeline(SsaoStage stage, const TargetFormat& format) {
    if (!ssao_ready()) return {};
    PipelineKey key{0xE00u | std::uint32_t(stage)};
    gpu::PipelineDesc d{};
    d.shader = ssao_shaders_[stage == SsaoStage::View ? int(SsaoStage::Apply) : int(stage)];
    d.layout.attrs[ATTR_ssao_ao_pos].format = gpu::VertexFormat::Float2;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.faceWinding = gpu::FaceWinding::Ccw;
    switch (stage) {
        case SsaoStage::Apply:  // dst.rgb *= src.rgb (the occlusion); alpha stays
            d.colors[0].blend.enabled = true;
            d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::DstColor;
            d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::Zero;
            d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::Zero;
            d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
            d.label = "ssao-apply";
            break;
        case SsaoStage::View: d.label = "ssao-view"; break;
        case SsaoStage::Blur: d.label = "ssao-blur"; break;
        default: d.label = "ssao-ao"; break;
    }
    return find_or_make(key, format, d);
}

bool Gpu::light_ready() {
    if (lightState_ != 0) return lightState_ > 0;
    if (lightFormat_ == gpu::PixelFormat::None) {
        lightState_ = -1;
        return false;
    }
    light_shader_ = make_builtin(light_light_shader_desc, "light_light");
    if (!shader_valid(light_shader_)) {
        device_->destroy_shader(light_shader_);
        light_shader_ = {};
        lightState_ = -1;
        FA_ERROR("render",
                 "The 2D light buffer is unavailable: its shader failed to compile for this graphics backend (see the "
                 "sokol log lines above). Lit visuals are shaded per pixel by the first {} lights only. Hint: update "
                 "the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).",
                 kDirectLights2D);
        return false;
    }
    lightState_ = 1;
    return true;
}

gpu::Pipeline Gpu::light_pipeline(const TargetFormat& format) {
    PipelineKey key{0x800u};
    gpu::PipelineDesc d{};
    d.shader = light_shader_;
    d.layout.attrs[ATTR_light_light_corner] = {.bufferIndex = 0, .offset = 0, .format = gpu::VertexFormat::Float2};
    d.layout.attrs[ATTR_light_light_pos] = {.bufferIndex = 0, .offset = 8, .format = gpu::VertexFormat::Float4};
    d.layout.attrs[ATTR_light_light_color] = {.bufferIndex = 0, .offset = 24, .format = gpu::VertexFormat::Float4};
    d.layout.attrs[ATTR_light_light_shadow] = {.bufferIndex = 0, .offset = 40, .format = gpu::VertexFormat::Float4};
    d.layout.attrs[ATTR_light_light_cookie] = {.bufferIndex = 0, .offset = 56, .format = gpu::VertexFormat::Float4};
    d.layout.attrs[ATTR_light_light_cookie_xf_in] = {
        .bufferIndex = 0, .offset = 72, .format = gpu::VertexFormat::Float4};
    d.layout.buffers[0].stride = int(sizeof(LightVertex));
    d.indexType = gpu::IndexType::Uint16;
    d.depth.compare = gpu::CompareFunc::Always;
    d.depth.writeEnabled = false;
    d.colors[0].blend.enabled = true;  // dst + src: the lights add up
    d.colors[0].blend.srcFactorRgb = gpu::BlendFactor::One;
    d.colors[0].blend.dstFactorRgb = gpu::BlendFactor::One;
    d.colors[0].blend.srcFactorAlpha = gpu::BlendFactor::One;
    d.colors[0].blend.dstFactorAlpha = gpu::BlendFactor::One;
    d.cullMode = gpu::CullMode::None;
    d.faceWinding = gpu::FaceWinding::Ccw;
    d.label = "light-buffer";
    return find_or_make(key, format, d);
}

void Gpu::begin_transient_writes() {
    if (!device_ || device_->backend() != gpu::Backend::Metal) return;
    if (pacedFrame_ == frame_ + 1) return;  // once per sokol frame
    // In a pass the frame's command buffer exists already: sokol waited for the frame at its first pass.
    if (in_pass()) {
        pacedFrame_ = frame_ + 1;
        return;
    }
    if (pacerFailed_) return;
    if (!pacerSrc_.id) {
        const std::uint32_t zero = 0;
        gpu::BufferDesc s{};
        s.size = sizeof(zero);
        s.usage.copySrc = true;
        s.data = {&zero, sizeof(zero)};
        s.label = "transient-pacer-src";
        pacerSrc_ = device_->make_buffer(s);
        gpu::BufferDesc d{};
        d.size = sizeof(zero);
        d.usage.copyDst = true;
        d.label = "transient-pacer-dst";
        pacerDst_ = device_->make_buffer(d);
    }
    if (device_->state(pacerSrc_) != gpu::ResourceState::Valid ||
        device_->state(pacerDst_) != gpu::ResourceState::Valid) {
        // Tried once: a driver that refuses two 4-byte buffers is not asked again at every write, and nothing is left behind.
        if (pacerSrc_.id) device_->destroy_buffer(pacerSrc_);
        if (pacerDst_.id) device_->destroy_buffer(pacerDst_);
        pacerSrc_ = pacerDst_ = {};
        pacerFailed_ = true;
        FA_WARN("render",
                "The Metal frame pacer could not be created: a write-transient buffer may be overwritten while the GPU "
                "still reads it (wrong instances in a probe capture on a busy GPU). Hint: restart the program.");
        return;
    }
    gpu::BufferCopy c{};
    c.src = pacerSrc_;
    c.dst = pacerDst_;
    c.size = sizeof(std::uint32_t);
    list_->copy_buffer_to_buffer(c);
    pacedFrame_ = pacerCopyFrame_ = frame_ + 1;  // the copy opened the frame's command buffer (committed() says so)
}

gpu::Buffer Gpu::acquire_transient(std::size_t bytes) {
    begin_transient_writes();
    if (transientUsed_ >= transient_.size()) transient_.emplace_back();
    Transient& t = transient_[transientUsed_++];
    if (t.capacity < bytes || !t.buf.id) {
        if (t.buf.id) device_->destroy_buffer(t.buf);
        std::size_t cap = 256 * 1024;
        while (cap < bytes) cap *= 2;
        gpu::BufferDesc d{};
        d.size = cap;
        d.usage.vertexBuffer = true;
        d.usage.writeTransient = true;
        d.label = "transient-vertices";
        t.buf = device_->make_buffer(d);
        t.capacity = cap;
    }
    return t.buf;
}

void Gpu::trim_light_images(std::size_t keep) {
    for (std::size_t i = keep; i < lightImages_.size(); ++i) {
        if (lightImages_[i].view.id) device_->destroy_view(lightImages_[i].view);
        if (lightImages_[i].image.id) device_->destroy_image(lightImages_[i].image);
    }
    if (keep < lightImages_.size()) lightImages_.resize(keep);
}

Gpu::LightImage Gpu::fill_light_image(LightImg& l, int rows, const float* texels) {
    if (!l.image.id || l.rows != rows) {
        if (l.view.id) device_->destroy_view(l.view);
        if (l.image.id) device_->destroy_image(l.image);
        gpu::ImageDesc d{};
        d.usage.writeTransient = true;
        d.width = kLightTextureWidth;
        d.height = rows;
        d.pixelFormat = gpu::PixelFormat::Rgba32F;
        d.label = "light-data";
        l.image = device_->make_image(d);  // SokolDevice applies the per-backend fixes (native_finish_image)
        gpu::ViewDesc vd{};
        vd.texture.image = l.image;
        vd.label = "light-data";
        l.view = device_->make_view(vd);
        l.rows = rows;
    }
    gpu::ImageWrite w{};
    w.data = {texels, std::size_t(kLightTextureWidth) * std::size_t(rows) * 16};
    w.dst.image = l.image;
    list_->write_image(w);
    return {l.image, l.view};
}

Gpu::LightImage Gpu::write_light_image(int rows, const float* texels) {
    begin_transient_writes();
    if (lightImagesUsed_ >= lightImages_.size()) lightImages_.emplace_back();
    return fill_light_image(lightImages_[lightImagesUsed_++], rows, texels);
}

Gpu::LightImage Gpu::write_palette_image(int rows, const float* texels) {
    begin_transient_writes();
    if (paletteImagesUsed_ >= paletteImages_.size()) paletteImages_.emplace_back();
    return fill_light_image(paletteImages_[paletteImagesUsed_++], rows, texels);
}

}  // namespace fa::render
