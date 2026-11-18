#include "render_internal.h"

#include <algorithm>
#include <cstdlib>
#include <cstring>

#include "fa/core/log.h"
#include "fa/platform/sokol_logging.h"

#include "shader_cache.h"

#include "shaders/bloom.glsl.h"
#include "shaders/colorfilter.glsl.h"
#include "shaders/exposure.glsl.h"
#include "shaders/prepass_view.glsl.h"
#include "shaders/post.glsl.h"
#include "shaders/blit.glsl.h"
#include "shaders/light.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/sky.glsl.h"
#include "shaders/ssao.glsl.h"

namespace fa::render {

namespace {
sg_sampler make_sampler(sg_filter minmag, sg_filter mip, sg_wrap wrap, const char* label) {
    sg_sampler_desc d{};
    d.min_filter = minmag;
    d.mag_filter = minmag;
    d.mipmap_filter = mip;
    d.wrap_u = wrap;
    d.wrap_v = wrap;
    d.max_lod = (mip == SG_FILTER_LINEAR) ? 1000.0f : 0.25f;
    if (mip == SG_FILTER_LINEAR) d.max_anisotropy = 4;
    d.label = label;
    return sg_make_sampler(&d);
}

// Vertex buffer 1: a 4x4 model matrix per instance in four consecutive attributes starting at `firstAttr`.
void set_instance_layout(sg_pipeline_desc& d, int firstAttr) {
    d.layout.buffers[1].stride = kMeshInstanceBytes;
    d.layout.buffers[1].step_func = SG_VERTEXSTEP_PER_INSTANCE;
    for (int i = 0; i < 4; ++i) {
        d.layout.attrs[firstAttr + i].format = SG_VERTEXFORMAT_FLOAT4;
        d.layout.attrs[firstAttr + i].buffer_index = 1;
        d.layout.attrs[firstAttr + i].offset = i * 16;
    }
}
// Vertex buffer 2 of a skinned part: SkinVertex (joint indices as bytes, then four weights).
void set_skin_layout(sg_pipeline_desc& d, int jointsAttr, int weightsAttr) {
    d.layout.buffers[2].stride = sizeof(SkinVertex);
    d.layout.attrs[jointsAttr].format =
        SG_VERTEXFORMAT_UBYTE4N;  // normalized: the shaders multiply by 255 (an integer attribute would not be a float)
    d.layout.attrs[jointsAttr].buffer_index = 2;
    d.layout.attrs[jointsAttr].offset = 0;
    d.layout.attrs[weightsAttr].format = SG_VERTEXFORMAT_FLOAT4;
    d.layout.attrs[weightsAttr].buffer_index = 2;
    d.layout.attrs[weightsAttr].offset = 4;
}
// Vertex buffers 3, 4 and 5 of a custom material's program (MeshExtras): the per-instance params, then uv1 and color1, at the
// attributes from `firstAttr` in that order (mesh_common.glsl fa_extra_attrs).
void set_extra_layout(sg_pipeline_desc& d, int firstAttr, const MeshExtras& e) {
    int at = firstAttr;
    if (e.instanceVec4 > 0) {
        d.layout.buffers[kInstanceDataBuffer].stride = e.instanceVec4 * 16;
        d.layout.buffers[kInstanceDataBuffer].step_func = SG_VERTEXSTEP_PER_INSTANCE;
        for (int i = 0; i < e.instanceVec4; ++i, ++at) {
            d.layout.attrs[at].format = SG_VERTEXFORMAT_FLOAT4;
            d.layout.attrs[at].buffer_index = kInstanceDataBuffer;
            d.layout.attrs[at].offset = i * 16;
        }
    }
    if (e.uv1) {
        d.layout.buffers[kUv1Buffer].stride = 8;
        d.layout.attrs[at].format = SG_VERTEXFORMAT_FLOAT2;
        d.layout.attrs[at].buffer_index = kUv1Buffer;
        ++at;
    }
    if (e.color1) {
        d.layout.buffers[kColor1Buffer].stride = 4;
        d.layout.attrs[at].format = SG_VERTEXFORMAT_UBYTE4N;
        d.layout.attrs[at].buffer_index = kColor1Buffer;
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
    const sg_pixel_format before = sceneFormat_;
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

bool Gpu::scene_has_alpha() const { return sceneFormat_ != SG_PIXELFORMAT_RG11B10F; }
bool Gpu::scene_is_float() const {
    return sceneFormat_ == SG_PIXELFORMAT_RGBA16F || sceneFormat_ == SG_PIXELFORMAT_RG11B10F;
}

sg_pixel_format Gpu::texture_format(sg_pixel_format unorm) const {
    if (!linear_) return unorm;
    sg_pixel_format srgb = SG_PIXELFORMAT_NONE;
    switch (unorm) {
        case SG_PIXELFORMAT_RGBA8: srgb = SG_PIXELFORMAT_SRGB8A8; break;
        case SG_PIXELFORMAT_BC7_RGBA: srgb = SG_PIXELFORMAT_BC7_SRGBA; break;
        case SG_PIXELFORMAT_ASTC_4x4_RGBA: srgb = SG_PIXELFORMAT_ASTC_4x4_SRGBA; break;
        case SG_PIXELFORMAT_ETC2_RGBA8: srgb = SG_PIXELFORMAT_ETC2_SRGB8A8; break;
        default: break;
    }
    if (srgb == SG_PIXELFORMAT_NONE) return unorm;
    const sg_pixelformat_info info = sg_query_pixelformat(srgb);
    return info.sample && info.filter ? srgb : unorm;
}

bool Gpu::init(int sampleCount, std::string* error) {
    sampleCount_ = std::max(1, sampleCount);
    sg_backend backend = sg_query_backend();
    isGl_ = (backend == SG_BACKEND_GLCORE || backend == SG_BACKEND_GLES3);
    zeroToOne_ = !isGl_;
    sg_pixelformat_info r32 = sg_query_pixelformat(SG_PIXELFORMAT_R32F);
    shadowsSupported_ = r32.render && r32.sample;
    {
        const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
        const sg_pixelformat_info eight = sg_query_pixelformat(SG_PIXELFORMAT_RGBA8);
        const bool halfOk = half.render && half.blend && half.filter;
        const bool eightOk = eight.render && eight.blend && eight.filter;
        lightFormat_ = halfOk ? SG_PIXELFORMAT_RGBA16F : eightOk ? SG_PIXELFORMAT_RGBA8 : SG_PIXELFORMAT_NONE;
        if (const char* want = std::getenv("FA_LIGHT_FORMAT")) {
            const std::string w = want;
            if (w == "rgba8")
                lightFormat_ = eightOk ? SG_PIXELFORMAT_RGBA8 : SG_PIXELFORMAT_NONE;
            else if (w == "none")
                lightFormat_ = SG_PIXELFORMAT_NONE;
            else if (w == "rgba16f")
                lightFormat_ = halfOk ? SG_PIXELFORMAT_RGBA16F : lightFormat_;
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
        const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
        const bool halfOk = half.render && half.blend && half.filter && (sampleCount_ <= 1 || half.msaa);
        // sokol-gfx reports no blend flag for RG11B10F on GL (the format blends there when it renders at all); D3D11 and Metal do.
        const sg_pixelformat_info packed = sg_query_pixelformat(SG_PIXELFORMAT_RG11B10F);
        const bool packedOk =
            packed.render && packed.filter && (packed.blend || isGl_) && (sampleCount_ <= 1 || packed.msaa);
        const sg_pixelformat_info srgb = sg_query_pixelformat(SG_PIXELFORMAT_SRGB8A8);
        const bool srgbTarget = srgb.render && srgb.blend && srgb.filter && (sampleCount_ <= 1 || srgb.msaa);
        srgbTextures_ = srgb.sample && srgb.filter;
        const std::string want = std::getenv("FA_SCENE_FORMAT") ? std::getenv("FA_SCENE_FORMAT") : "";
        for (SceneChain& c : sceneChain_) c = SceneChain{};
        auto add = [](SceneChain& c, sg_pixel_format f) { c.formats[c.count++] = f; };
        if (halfOk && want != "rgba8" && want != "r11g11b10") add(sceneChain_[0], SG_PIXELFORMAT_RGBA16F);
        add(sceneChain_[0], SG_PIXELFORMAT_RGBA8);
        if (halfOk && want != "rgba8" && want != "r11g11b10") add(sceneChain_[1], SG_PIXELFORMAT_RGBA16F);
        if (packedOk && want != "rgba8") add(sceneChain_[1], SG_PIXELFORMAT_RG11B10F);
        if (srgbTarget) add(sceneChain_[1], SG_PIXELFORMAT_SRGB8A8);
        add(sceneChain_[1], SG_PIXELFORMAT_RGBA8);
        refresh_scene_format();
    }

    quad_shader_ = make_shader(quad_quad_shader_desc(backend), "quad_quad");
    quadPlainShader_ = make_shader(quad_quad_plain_shader_desc(backend), "quad_quad_plain");
    mesh_shader_ = make_shader(mesh_mesh_shader_desc(backend), "mesh_mesh");
    sky_shader_ = make_shader(sky_sky_shader_desc(backend), "sky_sky");
    shadow_shader_ = make_shader(mesh_shadow_shader_desc(backend), "mesh_shadow");
    blit_shader_ = make_shader(blit_blit_shader_desc(backend), "blit_blit");
    blitKeepShader_ = make_shader(blit_blit_keep_shader_desc(backend), "blit_blit_keep");
    meshSkinShader_ = make_shader(mesh_mesh_skin_shader_desc(backend), "mesh_mesh_skin");
    shadowSkinShader_ = make_shader(mesh_shadow_skin_shader_desc(backend), "mesh_shadow_skin");
    for (sg_shader s : {quad_shader_, quadPlainShader_, mesh_shader_, sky_shader_, shadow_shader_, blit_shader_,
                        blitKeepShader_, meshSkinShader_, shadowSkinShader_}) {
        if (sg_query_shader_state(s) != SG_RESOURCESTATE_VALID) {
            if (error) {
                *error = "Failed to create a built-in shader for the " +
                         std::string(backend == SG_BACKEND_GLCORE ? "OpenGL" : "current") +
                         " backend (see the sokol log lines above). The GL driver may be older than 4.3: "
                         "with Mesa try LIBGL_ALWAYS_SOFTWARE=1.";
            }
            return false;
        }
    }

    samplers_[int(SamplerKind::Nearest)] =
        make_sampler(SG_FILTER_NEAREST, SG_FILTER_NEAREST, SG_WRAP_CLAMP_TO_EDGE, "nearest");
    samplers_[int(SamplerKind::Linear)] =
        make_sampler(SG_FILTER_LINEAR, SG_FILTER_LINEAR, SG_WRAP_CLAMP_TO_EDGE, "linear");
    samplers_[int(SamplerKind::LinearRepeat)] =
        make_sampler(SG_FILTER_LINEAR, SG_FILTER_LINEAR, SG_WRAP_REPEAT, "linear-repeat");
    samplers_[int(SamplerKind::NearestRepeat)] =
        make_sampler(SG_FILTER_NEAREST, SG_FILTER_NEAREST, SG_WRAP_REPEAT, "nearest-repeat");
    // Bilinear, clamped, no mipmaps and no anisotropy: post-processing fetches (explicit LOD 0).
    samplers_[int(SamplerKind::LinearClamp)] =
        make_sampler(SG_FILTER_LINEAR, SG_FILTER_NEAREST, SG_WRAP_CLAMP_TO_EDGE, "linear-clamp");

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
    sg_buffer_desc ib{};
    ib.usage.index_buffer = true;
    ib.data = {idx.data(), idx.size() * sizeof(std::uint16_t)};
    ib.label = "quad-indices";
    quadIndices_ = sg_make_buffer(&ib);

    const float tri[] = {-1.0f, -1.0f, 3.0f, -1.0f, -1.0f, 3.0f};
    sg_buffer_desc tb{};
    tb.data = {tri, sizeof(tri)};
    tb.label = "fullscreen-triangle";
    fsTriangle_ = sg_make_buffer(&tb);
    listening_ = sg_add_commit_listener(sg_commit_listener{&Gpu::count_commit, this});
    return true;
}

void Gpu::shutdown() {
    if (listening_) sg_remove_commit_listener(sg_commit_listener{&Gpu::count_commit, this});
    listening_ = false;
    warming_ = false;
    for (auto& [k, p] : pipelines_) sg_destroy_pipeline(p.pipeline);
    pipelines_.clear();
    for (auto& t : transient_) sg_destroy_buffer(t.buf);
    transient_.clear();
    transientUsed_ = 0;
    for (auto& s : samplers_) {
        sg_destroy_sampler(s);
        s = {};
    }
    sg_destroy_buffer(quadIndices_);
    sg_destroy_buffer(fsTriangle_);
    for (sg_shader* s : {&quad_shader_, &quadPlainShader_, &mesh_shader_, &sky_shader_, &shadow_shader_, &blit_shader_,
                         &blitKeepShader_, &meshSkinShader_, &shadowSkinShader_}) {
        sg_destroy_shader(*s);
        *s = {};
    }
    for (sg_shader& s : bloom_shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    bloomState_ = 0;
    if (colorfilter_shader_.id) sg_destroy_shader(colorfilter_shader_);
    colorfilter_shader_ = {};
    colorfilterState_ = 0;
    if (post_shader_.id) sg_destroy_shader(post_shader_);
    post_shader_ = {};
    postState_ = 0;
    for (sg_shader& s : exposure_shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    exposureState_ = 0;
    for (sg_shader& s : ssao_shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    ssaoState_ = 0;
    for (sg_shader* s : {&prepassShader_, &prepassSkinShader_, &prepassViewShader_}) {
        if (s->id) sg_destroy_shader(*s);
        *s = {};
    }
    prepassState_ = prepassViewState_ = 0;
    if (light_shader_.id) sg_destroy_shader(light_shader_);
    light_shader_ = {};
    lightState_ = 0;
}

void Gpu::sweep_pipelines() {
    // Nothing else holds a pipeline (every caller asks Gpu on each draw), so one that no draw asked for during the last
    // pipelineIdleFrames_ frames can go; it is made again if it is ever asked for. See "The pipeline cache" in
    // render_internal.h.
    for (auto it = pipelines_.begin(); it != pipelines_.end();) {
        if (!it->second.warmed && pipelineTick_ - it->second.lastUsed > pipelineIdleFrames_) {
            sg_destroy_pipeline(it->second.pipeline);
            it = pipelines_.erase(it);
            ++pipelinesEvicted_;
        } else {
            ++it;
        }
    }
}

void Gpu::destroy_shader(sg_shader shader) {
    for (auto it = pipelines_.begin(); it != pipelines_.end();) {
        if (it->first.shader == shader.id) {
            sg_destroy_pipeline(it->second.pipeline);
            it = pipelines_.erase(it);
        } else {
            ++it;
        }
    }
    sg_destroy_shader(shader);
}

void Gpu::begin_pass(const PassDesc& pass) {
#ifndef NDEBUG
    FA_ASSERT(!inPass_, "Gpu::begin_pass: a pass is already open (end_pass it first)");
#endif
    const sg_pass p = pass.to_sg();
    sg_begin_pass(&p);
    inPass_ = true;
    passFormat_ = pass.format;
}

void Gpu::end_pass() {
    sg_end_pass();
    inPass_ = false;
}

sg_pipeline Gpu::find_or_make(PipelineKey key, const TargetFormat& format, const sg_pipeline_desc& request) {
#ifndef NDEBUG
    // A pipeline applied in a pass must have the pass's colour format, depth format and sample count. GL and D3D11
    // validation reject a mismatch; Metal accepts it and draws wrong, so check here, where every pipeline comes from.
    FA_ASSERT(!inPass_ || format == passFormat_,
              "a pipeline was fetched for another target format than the pass being drawn (PassDesc::format)");
#endif
    key.format = format;
    auto it = pipelines_.find(key);
    if (it != pipelines_.end()) {
        it->second.lastUsed = pipelineTick_;
        if (warming_) it->second.warmed = true;
        ++pipelineHits_;
        return it->second.pipeline;
    }
    sg_pipeline_desc desc = request;  // a copy only on a miss (the description is more than 1 KB)
    desc.colors[0].pixel_format = format.color;
    desc.depth.pixel_format = format.depth;
    desc.sample_count = format.samples;
    // A pipeline asked for before its lazily made shader exists (a caller that skipped the *_ready() check) is an engine
    // bug: report it and keep it out of the cache, so the one early call does not break the key for the whole process.
    if (sg_query_shader_state(desc.shader) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "pipeline '{}' was asked for before its shader was made; it is not drawn (engine bug)",
                 desc.label ? desc.label : "?");
        return {};
    }
    sg_pipeline p = sg_make_pipeline(&desc);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "failed to create pipeline '{}'", desc.label ? desc.label : "?");
    }
    ++pipelinesMade_;
    pipelines_[key] = {p, pipelineTick_, warming_};
    return p;
}

sg_pipeline Gpu::quad_pipeline(const TargetFormat& format, bool depthTest, bool lines, BlendMode blend, bool plain,
                               bool opaque) {
    PipelineKey key{0x100u | (depthTest ? 1u : 0u) | (lines ? 2u : 0u) | (std::uint32_t(blend) << 2) |
                    (plain ? 0x10u : 0u) | (opaque ? 0x20u : 0u)};
    sg_pipeline_desc d{};
    d.shader = plain ? quadPlainShader_ : quad_shader_;
    d.layout.attrs[ATTR_quad_quad_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_quad_quad_texcoord0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_quad_quad_color0].format = SG_VERTEXFORMAT_UBYTE4N;
    d.layout.attrs[ATTR_quad_quad_params0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_quad_quad_color2_0].format = SG_VERTEXFORMAT_UBYTE4N;
    d.layout.attrs[ATTR_quad_quad_shape_half0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_quad_quad_shape_rs0].format = SG_VERTEXFORMAT_HALF2;
    d.primitive_type = lines ? SG_PRIMITIVETYPE_LINES : SG_PRIMITIVETYPE_TRIANGLES;
    d.index_type = lines ? SG_INDEXTYPE_NONE : SG_INDEXTYPE_UINT16;
    d.depth.compare = depthTest ? SG_COMPAREFUNC_LESS_EQUAL : SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.colors[0].blend.enabled = !opaque;
    switch (blend) {
        case BlendMode::Additive:  // dst + src.rgb * src.a  (glow: overlapping items accumulate light)
            d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
            d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE;
            d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
            d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
            break;
        case BlendMode::Multiply:  // dst * lerp(1, src.rgb, src.a)
            d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_DST_COLOR;
            d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ZERO;  // shader emits mix(1, rgb, a) (mode + 8)
            d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
            d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
            break;
        case BlendMode::Alpha:
        default:
            d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
            d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
            d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
            d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
            break;
    }
    d.cull_mode = SG_CULLMODE_NONE;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = lines   ? "quad-lines"
              : plain ? (depthTest ? "quad-3d-plain" : "quad-2d-plain")
                      : (depthTest ? "quad-3d" : "quad-2d");
    return find_or_make(key, format, d);
}

sg_pipeline Gpu::mesh_pipeline(const TargetFormat& format, bool blended, bool doubleSided, bool skinned,
                               sg_shader shader, MeshExtras extras) {
    PipelineKey key{0x200u | (blended ? 1u : 0u) | (doubleSided ? 2u : 0u) | (skinned ? 4u : 0u), shader.id};
    sg_pipeline_desc d{};
    d.shader = shader.id ? shader : (skinned ? meshSkinShader_ : mesh_shader_);
    d.layout.attrs[ATTR_mesh_mesh_fa_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_mesh_fa_normal].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_mesh_fa_texcoord0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_mesh_mesh_fa_tangent].format = SG_VERTEXFORMAT_FLOAT4;
    d.layout.attrs[ATTR_mesh_mesh_fa_color].format =
        SG_VERTEXFORMAT_UBYTE4N;  // vertex color, white without (MeshVertex::color)
    set_instance_layout(d, ATTR_mesh_mesh_fa_inst_m0);
    if (skinned) set_skin_layout(d, ATTR_mesh_mesh_skin_fa_joints, ATTR_mesh_mesh_skin_fa_weights);
    if (shader.id) set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    d.index_type = SG_INDEXTYPE_UINT32;
    d.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    d.depth.write_enabled = !blended;
    if (blended) {
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
        d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    }
    d.cull_mode = (doubleSided || blended) ? SG_CULLMODE_NONE : SG_CULLMODE_BACK;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "mesh";
    return find_or_make(key, format, d);
}

sg_pipeline Gpu::sky_pipeline(const TargetFormat& format) {
    PipelineKey key{0x300u};
    sg_pipeline_desc d{};
    d.shader = sky_shader_;
    d.layout.attrs[ATTR_sky_sky_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "sky";
    return find_or_make(key, format, d);
}

sg_pipeline Gpu::shadow_pipeline(const TargetFormat& format, bool skinned, sg_shader shader, bool fullVertex,
                                 MeshExtras extras) {
    PipelineKey key{0x400u | (skinned ? 1u : 0u) | (fullVertex ? 2u : 0u), shader.id};
    sg_pipeline_desc d{};
    d.shader = shader.id ? shader : (skinned ? shadowSkinShader_ : shadow_shader_);
    d.layout.attrs[ATTR_mesh_shadow_fa_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.buffers[0].stride = sizeof(MeshVertex);  // position is the first member of MeshVertex
    if (fullVertex) {  // offsets are the packed ones of MeshVertex: attributes of buffer 0 in location order
        const int first = skinned ? 7 : 5;
        d.layout.attrs[first].format = SG_VERTEXFORMAT_FLOAT3;       // normal
        d.layout.attrs[first + 1].format = SG_VERTEXFORMAT_FLOAT2;   // texcoord0
        d.layout.attrs[first + 2].format = SG_VERTEXFORMAT_FLOAT4;   // tangent
        d.layout.attrs[first + 3].format = SG_VERTEXFORMAT_UBYTE4N;  // vertex color
    }
    set_instance_layout(d, ATTR_mesh_shadow_fa_inst_m0);
    if (skinned) set_skin_layout(d, ATTR_mesh_shadow_skin_fa_joints, ATTR_mesh_shadow_skin_fa_weights);
    if (shader.id && fullVertex) set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    d.index_type = SG_INDEXTYPE_UINT32;
    d.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    d.depth.write_enabled = true;
    d.cull_mode = SG_CULLMODE_NONE;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "shadow";
    return find_or_make(key, format, d);
}

sg_pipeline Gpu::blit_pipeline(const TargetFormat& format) {
    PipelineKey key{0x500u};
    sg_pipeline_desc d{};
    d.shader = blit_shader_;
    d.layout.attrs[ATTR_blit_blit_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "blit";
    return find_or_make(key, format, d);
}

bool Gpu::bloom_ready() {
    if (bloomState_ != 0) return bloomState_ > 0;
    sg_backend backend = sg_query_backend();
    bloom_shaders_[int(BloomStage::Bright)] = make_shader(bloom_bright_shader_desc(backend), "bloom_bright");
    bloom_shaders_[int(BloomStage::Down)] = make_shader(bloom_down_shader_desc(backend), "bloom_down");
    bloom_shaders_[int(BloomStage::Blur)] = make_shader(bloom_blur_shader_desc(backend), "bloom_blur");
    bloom_shaders_[int(BloomStage::Composite)] = make_shader(bloom_composite_shader_desc(backend), "bloom_composite");
    bool ok = true;
    for (sg_shader s : bloom_shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : bloom_shaders_) {
            if (s.id) sg_destroy_shader(s);
            s = {};
        }
        bloomState_ = -1;
        FA_ERROR("render",
                 "Camera.bloom is unavailable: the bloom shaders failed to compile for this graphics backend "
                 "(see the sokol log lines above). The game renders without bloom. Hint: update the graphics driver "
                 "(Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set Camera.bloom to false.");
        return false;
    }
    bloomState_ = 1;
    return true;
}

sg_pipeline Gpu::blit_keep_pipeline(const TargetFormat& format) {
    PipelineKey key{0x900u};
    sg_pipeline_desc d{};
    d.shader = blitKeepShader_;
    d.layout.attrs[ATTR_blit_blit_keep_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "blit-keep";
    return find_or_make(key, format, d);
}

sg_pipeline Gpu::bloom_pipeline(BloomStage stage, const TargetFormat& format) {
    PipelineKey key{0x600u | std::uint32_t(stage)};
    sg_pipeline_desc d{};
    d.shader = bloom_shaders_[int(stage)];
    // All four programs share the vertex shader and therefore the same single `pos` attribute at location 0.
    d.layout.attrs[ATTR_bloom_bright_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    switch (stage) {
        case BloomStage::Composite:  // dst.rgb += src.rgb (intensity is applied in the shader); alpha stays
            d.colors[0].blend.enabled = true;
            d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_ONE;
            d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE;
            d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
            d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
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
    colorfilter_shader_ =
        make_shader(colorfilter_colorfilter_shader_desc(sg_query_backend()), "colorfilter_colorfilter");
    if (sg_query_shader_state(colorfilter_shader_) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(colorfilter_shader_);
        colorfilter_shader_ = {};
        colorfilterState_ = -1;
        FA_ERROR("render",
                 "Camera.colorFilter is unavailable: the colour filter shader failed to compile for this graphics "
                 "backend (see the sokol log lines above). The game renders without the filter. Hint: update the "
                 "graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1) or set Camera.colorFilter to \"none\".");
        return false;
    }
    colorfilterState_ = 1;
    return true;
}

sg_pipeline Gpu::colorfilter_pipeline(const TargetFormat& format) {
    if (!colorfilter_ready()) return {};
    PipelineKey key{0x700u};
    sg_pipeline_desc d{};
    d.shader = colorfilter_shader_;
    d.layout.attrs[ATTR_colorfilter_colorfilter_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "colorfilter";
    return find_or_make(key, format, d);
}

bool Gpu::post_ready() {
    ++postReadyCalls_;
    if (postState_ != 0) return postState_ > 0;
    post_shader_ = make_shader(post_post_shader_desc(sg_query_backend()), "post_post");
    if (sg_query_shader_state(post_shader_) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(post_shader_);
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

sg_pipeline Gpu::post_pipeline(const TargetFormat& format) {
    if (!post_ready()) return {};
    PipelineKey key{0xA00u};
    sg_pipeline_desc d{};
    d.shader = post_shader_;
    d.layout.attrs[ATTR_post_post_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "post";
    return find_or_make(key, format, d);
}

sg_pixel_format Gpu::prepass_color_format() {
    // The prepass image is only sampled with a nearest sampler (a depth is never blended or filtered), so it needs no more than render + sample.
    for (sg_pixel_format f : {SG_PIXELFORMAT_RGBA32F, SG_PIXELFORMAT_RGBA16F}) {
        const sg_pixelformat_info info = sg_query_pixelformat(f);
        if (info.render && info.sample) return f;
    }
    return SG_PIXELFORMAT_NONE;
}

namespace {
// The slots a built-in program declares, as the twin of a custom one says them (MaterialProgram).
MaterialProgram program_slots(sg_shader shader, const sg_shader_desc* desc) {
    MaterialProgram out;
    out.shader = shader;
    for (int i = 0; i < SG_MAX_UNIFORMBLOCK_BINDSLOTS; ++i) {
        if (desc->uniform_blocks[i].stage == SG_SHADERSTAGE_NONE) continue;
        out.ubMask |= 1u << i;
        out.ubSize[i] = desc->uniform_blocks[i].size;
    }
    for (int i = 0; i < SG_MAX_VIEW_BINDSLOTS; ++i)
        if (desc->views[i].texture.stage != SG_SHADERSTAGE_NONE) out.viewMask |= 1u << i;
    for (int i = 0; i < SG_MAX_SAMPLER_BINDSLOTS; ++i)
        if (desc->samplers[i].stage != SG_SHADERSTAGE_NONE) out.samplerMask |= 1u << i;
    return out;
}
}  // namespace

bool Gpu::prepass_ready() {
    if (prepassState_ != 0) return prepassState_ > 0;
    const sg_backend backend = sg_query_backend();
    prepassShader_ = make_shader(mesh_prepass_shader_desc(backend), "mesh_prepass");
    prepassSkinShader_ = make_shader(mesh_prepass_skin_shader_desc(backend), "mesh_prepass_skin");
    if (prepass_color_format() == SG_PIXELFORMAT_NONE ||
        sg_query_shader_state(prepassShader_) != SG_RESOURCESTATE_VALID ||
        sg_query_shader_state(prepassSkinShader_) != SG_RESOURCESTATE_VALID) {
        for (sg_shader* s : {&prepassShader_, &prepassSkinShader_}) {
            if (s->id) sg_destroy_shader(*s);
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
    prepassProgram_[0] = program_slots(prepassShader_, mesh_prepass_shader_desc(backend));
    prepassProgram_[1] = program_slots(prepassSkinShader_, mesh_prepass_skin_shader_desc(backend));
    prepassState_ = 1;
    return true;
}

sg_pipeline Gpu::prepass_pipeline(const TargetFormat& format, bool doubleSided, bool skinned, sg_shader shader,
                                  MeshExtras extras) {
    if (!shader.id && !prepass_ready()) return {};
    PipelineKey key{0xC00u | (doubleSided ? 2u : 0u) | (skinned ? 4u : 0u), shader.id};
    sg_pipeline_desc d{};
    d.shader = shader.id ? shader : (skinned ? prepassSkinShader_ : prepassShader_);
    d.layout.attrs[ATTR_mesh_prepass_fa_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_prepass_fa_normal].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_prepass_fa_texcoord0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_mesh_prepass_fa_tangent].format = SG_VERTEXFORMAT_FLOAT4;
    d.layout.attrs[ATTR_mesh_prepass_fa_color].format = SG_VERTEXFORMAT_UBYTE4N;
    set_instance_layout(d, ATTR_mesh_prepass_fa_inst_m0);
    if (skinned) set_skin_layout(d, ATTR_mesh_prepass_skin_fa_joints, ATTR_mesh_prepass_skin_fa_weights);
    if (shader.id) set_extra_layout(d, skinned ? kExtraAttrBaseSkinned : kExtraAttrBase, extras);
    d.index_type = SG_INDEXTYPE_UINT32;
    d.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    d.depth.write_enabled = true;
    d.cull_mode = doubleSided ? SG_CULLMODE_NONE : SG_CULLMODE_BACK;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "prepass";
    return find_or_make(key, format, d);
}

bool Gpu::prepass_view_ready() {
    if (prepassViewState_ != 0) return prepassViewState_ > 0;
    prepassViewShader_ = make_shader(prepass_view_prepass_view_shader_desc(sg_query_backend()), "prepass_view");
    if (sg_query_shader_state(prepassViewShader_) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(prepassViewShader_);
        prepassViewShader_ = {};
        prepassViewState_ = -1;
        FA_ERROR("render",
                 "The prepass debug view is unavailable: its shader failed to compile for this graphics backend.");
        return false;
    }
    prepassViewState_ = 1;
    return true;
}

sg_pipeline Gpu::prepass_view_pipeline(const TargetFormat& format) {
    if (!prepass_view_ready()) return {};
    PipelineKey key{0xD00u};
    sg_pipeline_desc d{};
    d.shader = prepassViewShader_;
    d.layout.attrs[ATTR_prepass_view_prepass_view_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "prepass-view";
    return find_or_make(key, format, d);
}

bool Gpu::exposure_ready() {
    if (exposureState_ != 0) return exposureState_ > 0;
    exposure_shaders_[int(ExposureStage::Luma)] =
        make_shader(exposure_luma_shader_desc(sg_query_backend()), "exposure_luma");
    exposure_shaders_[int(ExposureStage::Adapt)] =
        make_shader(exposure_adapt_shader_desc(sg_query_backend()), "exposure_adapt");
    bool ok = true;
    for (sg_shader s : exposure_shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : exposure_shaders_) {
            if (s.id) sg_destroy_shader(s);
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

sg_pipeline Gpu::exposure_pipeline(ExposureStage stage, const TargetFormat& format) {
    if (!exposure_ready()) return {};
    PipelineKey key{0xB00u | std::uint32_t(stage)};
    sg_pipeline_desc d{};
    d.shader = exposure_shaders_[int(stage)];
    d.layout.attrs[ATTR_exposure_luma_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = stage == ExposureStage::Luma ? "exposure-luma" : "exposure-adapt";
    return find_or_make(key, format, d);
}

bool Gpu::ssao_ready() {
    if (ssaoState_ != 0) return ssaoState_ > 0;
    ssao_shaders_[0] = make_shader(ssao_ao_shader_desc(sg_query_backend()), "ssao_ao");
    ssao_shaders_[1] = make_shader(ssao_blur_shader_desc(sg_query_backend()), "ssao_blur");
    ssao_shaders_[2] = make_shader(ssao_apply_shader_desc(sg_query_backend()), "ssao_apply");
    bool ok = true;
    for (sg_shader s : ssao_shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    if (!ok) {
        for (sg_shader& s : ssao_shaders_) {
            if (s.id) sg_destroy_shader(s);
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

sg_pipeline Gpu::ssao_pipeline(SsaoStage stage, const TargetFormat& format) {
    if (!ssao_ready()) return {};
    PipelineKey key{0xE00u | std::uint32_t(stage)};
    sg_pipeline_desc d{};
    d.shader = ssao_shaders_[stage == SsaoStage::View ? int(SsaoStage::Apply) : int(stage)];
    d.layout.attrs[ATTR_ssao_ao_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.face_winding = SG_FACEWINDING_CCW;
    switch (stage) {
        case SsaoStage::Apply:  // dst.rgb *= src.rgb (the occlusion); alpha stays
            d.colors[0].blend.enabled = true;
            d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_DST_COLOR;
            d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ZERO;
            d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
            d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
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
    if (lightFormat_ == SG_PIXELFORMAT_NONE) {
        lightState_ = -1;
        return false;
    }
    light_shader_ = make_shader(light_light_shader_desc(sg_query_backend()), "light_light");
    if (sg_query_shader_state(light_shader_) != SG_RESOURCESTATE_VALID) {
        sg_destroy_shader(light_shader_);
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

sg_pipeline Gpu::light_pipeline(const TargetFormat& format) {
    PipelineKey key{0x800u};
    sg_pipeline_desc d{};
    d.shader = light_shader_;
    d.layout.attrs[ATTR_light_light_corner] = {.buffer_index = 0, .offset = 0, .format = SG_VERTEXFORMAT_FLOAT2};
    d.layout.attrs[ATTR_light_light_pos] = {.buffer_index = 0, .offset = 8, .format = SG_VERTEXFORMAT_FLOAT4};
    d.layout.attrs[ATTR_light_light_color] = {.buffer_index = 0, .offset = 24, .format = SG_VERTEXFORMAT_FLOAT4};
    d.layout.attrs[ATTR_light_light_shadow] = {.buffer_index = 0, .offset = 40, .format = SG_VERTEXFORMAT_FLOAT4};
    d.layout.buffers[0].stride = int(sizeof(LightVertex));
    d.index_type = SG_INDEXTYPE_UINT16;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.colors[0].blend.enabled = true;  // dst + src: the lights add up
    d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_ONE;
    d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE;
    d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
    d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
    d.cull_mode = SG_CULLMODE_NONE;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "light-buffer";
    return find_or_make(key, format, d);
}

sg_buffer Gpu::acquire_transient(std::size_t bytes) {
    if (transientUsed_ >= transient_.size()) transient_.emplace_back();
    Transient& t = transient_[transientUsed_++];
    if (t.capacity < bytes || !t.buf.id) {
        if (t.buf.id) sg_destroy_buffer(t.buf);
        std::size_t cap = 256 * 1024;
        while (cap < bytes) cap *= 2;
        sg_buffer_desc d{};
        d.size = cap;
        d.usage.vertex_buffer = true;
        d.usage.write_transient = true;
        d.label = "transient-vertices";
        t.buf = sg_make_buffer(&d);
        t.capacity = cap;
    }
    return t.buf;
}

}  // namespace fa::render
