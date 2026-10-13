#include "render_internal.h"

#include <algorithm>
#include <cstring>

#include "fa/core/log.h"
#include "fa/platform/sokol_logging.h"

#include "shaders/blit.glsl.h"
#include "shaders/mesh.glsl.h"
#include "shaders/quad.glsl.h"
#include "shaders/shadow.glsl.h"
#include "shaders/sky.glsl.h"

namespace fa::render {

namespace {
constexpr sg_pixel_format kColorFormat = SG_PIXELFORMAT_RGBA8;
constexpr sg_pixel_format kDepthFormat = SG_PIXELFORMAT_DEPTH_STENCIL;

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
}  // namespace

bool Gpu::init(int sampleCount, std::string* error) {
    sampleCount_ = std::max(1, sampleCount);
    sg_backend backend = sg_query_backend();
    isGl_ = (backend == SG_BACKEND_GLCORE || backend == SG_BACKEND_GLES3);
    zeroToOne_ = !isGl_;
    sg_pixelformat_info r32 = sg_query_pixelformat(SG_PIXELFORMAT_R32F);
    shadowsSupported_ = r32.render && r32.sample;

    quad_shader_ = sg_make_shader(quad_quad_shader_desc(backend));
    mesh_shader_ = sg_make_shader(mesh_mesh_shader_desc(backend));
    sky_shader_ = sg_make_shader(sky_sky_shader_desc(backend));
    shadow_shader_ = sg_make_shader(shadow_shadow_shader_desc(backend));
    blit_shader_ = sg_make_shader(blit_blit_shader_desc(backend));
    for (sg_shader s : {quad_shader_, mesh_shader_, sky_shader_, shadow_shader_, blit_shader_}) {
        if (sg_query_shader_state(s) != SG_RESOURCESTATE_VALID) {
            if (error) {
                *error = "Failed to create a built-in shader for the " + std::string(backend == SG_BACKEND_GLCORE ? "OpenGL" : "current") +
                         " backend (see the sokol log lines above). The GL driver may be older than 4.3: "
                         "with Mesa try LIBGL_ALWAYS_SOFTWARE=1.";
            }
            return false;
        }
    }

    samplers_[int(SamplerKind::Nearest)] = make_sampler(SG_FILTER_NEAREST, SG_FILTER_NEAREST, SG_WRAP_CLAMP_TO_EDGE, "nearest");
    samplers_[int(SamplerKind::Linear)] = make_sampler(SG_FILTER_LINEAR, SG_FILTER_LINEAR, SG_WRAP_CLAMP_TO_EDGE, "linear");
    samplers_[int(SamplerKind::LinearRepeat)] = make_sampler(SG_FILTER_LINEAR, SG_FILTER_LINEAR, SG_WRAP_REPEAT, "linear-repeat");
    samplers_[int(SamplerKind::NearestRepeat)] = make_sampler(SG_FILTER_NEAREST, SG_FILTER_NEAREST, SG_WRAP_REPEAT, "nearest-repeat");

    // Static quad index buffer: (0,1,2, 0,2,3) per quad.
    std::vector<std::uint16_t> idx(std::size_t(kMaxQuadsPerDraw) * 6);
    for (int q = 0; q < kMaxQuadsPerDraw; ++q) {
        std::uint16_t b = std::uint16_t(q * 4);
        std::uint16_t* p = &idx[std::size_t(q) * 6];
        p[0] = b; p[1] = std::uint16_t(b + 1); p[2] = std::uint16_t(b + 2);
        p[3] = b; p[4] = std::uint16_t(b + 2); p[5] = std::uint16_t(b + 3);
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
    return true;
}

void Gpu::shutdown() {
    for (auto& [k, p] : pipelines_) sg_destroy_pipeline(p);
    pipelines_.clear();
    for (auto& t : transient_) sg_destroy_buffer(t.buf);
    transient_.clear();
    transientUsed_ = 0;
    for (auto& s : samplers_) { sg_destroy_sampler(s); s = {}; }
    sg_destroy_buffer(quadIndices_);
    sg_destroy_buffer(fsTriangle_);
    for (sg_shader* s : {&quad_shader_, &mesh_shader_, &sky_shader_, &shadow_shader_, &blit_shader_}) {
        sg_destroy_shader(*s);
        *s = {};
    }
}

sg_pipeline Gpu::find_or_make(PipelineKey key, const sg_pipeline_desc& desc) {
    auto it = pipelines_.find(key);
    if (it != pipelines_.end()) return it->second;
    sg_pipeline p = sg_make_pipeline(&desc);
    if (sg_query_pipeline_state(p) != SG_RESOURCESTATE_VALID) {
        FA_ERROR("render", "failed to create pipeline '{}'", desc.label ? desc.label : "?");
    }
    pipelines_[key] = p;
    return p;
}

sg_pipeline Gpu::quad_pipeline(bool depthTest, bool lines, BlendMode blend) {
    PipelineKey key{0x100u | (depthTest ? 1u : 0u) | (lines ? 2u : 0u) | (std::uint32_t(blend) << 2)};
    sg_pipeline_desc d{};
    d.shader = quad_shader_;
    d.layout.attrs[ATTR_quad_quad_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_quad_quad_texcoord0].format = SG_VERTEXFORMAT_FLOAT2;
    d.layout.attrs[ATTR_quad_quad_color0].format = SG_VERTEXFORMAT_UBYTE4N;
    d.layout.attrs[ATTR_quad_quad_params0].format = SG_VERTEXFORMAT_FLOAT2;
    d.primitive_type = lines ? SG_PRIMITIVETYPE_LINES : SG_PRIMITIVETYPE_TRIANGLES;
    d.index_type = lines ? SG_INDEXTYPE_NONE : SG_INDEXTYPE_UINT16;
    d.depth.pixel_format = kDepthFormat;
    d.depth.compare = depthTest ? SG_COMPAREFUNC_LESS_EQUAL : SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.colors[0].pixel_format = kColorFormat;
    d.colors[0].blend.enabled = true;
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
    d.sample_count = sampleCount_;
    d.label = lines ? "quad-lines" : (depthTest ? "quad-3d" : "quad-2d");
    return find_or_make(key, d);
}

sg_pipeline Gpu::mesh_pipeline(bool blended, bool doubleSided) {
    PipelineKey key{0x200u | (blended ? 1u : 0u) | (doubleSided ? 2u : 0u)};
    sg_pipeline_desc d{};
    d.shader = mesh_shader_;
    d.layout.attrs[ATTR_mesh_mesh_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_mesh_normal].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.attrs[ATTR_mesh_mesh_texcoord0].format = SG_VERTEXFORMAT_FLOAT2;
    d.index_type = SG_INDEXTYPE_UINT32;
    d.depth.pixel_format = kDepthFormat;
    d.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    d.depth.write_enabled = !blended;
    d.colors[0].pixel_format = kColorFormat;
    if (blended) {
        d.colors[0].blend.enabled = true;
        d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
        d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
        d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ONE;
        d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
    }
    d.cull_mode = (doubleSided || blended) ? SG_CULLMODE_NONE : SG_CULLMODE_BACK;
    d.face_winding = SG_FACEWINDING_CCW;
    d.sample_count = sampleCount_;
    d.label = "mesh";
    return find_or_make(key, d);
}

sg_pipeline Gpu::sky_pipeline() {
    PipelineKey key{0x300u};
    sg_pipeline_desc d{};
    d.shader = sky_shader_;
    d.layout.attrs[ATTR_sky_sky_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.pixel_format = kDepthFormat;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.colors[0].pixel_format = kColorFormat;
    d.sample_count = sampleCount_;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "sky";
    return find_or_make(key, d);
}

sg_pipeline Gpu::shadow_pipeline() {
    PipelineKey key{0x400u};
    sg_pipeline_desc d{};
    d.shader = shadow_shader_;
    d.layout.attrs[ATTR_shadow_shadow_position].format = SG_VERTEXFORMAT_FLOAT3;
    d.layout.buffers[0].stride = sizeof(MeshVertex);  // position is the first member of MeshVertex
    d.index_type = SG_INDEXTYPE_UINT32;
    d.depth.pixel_format = SG_PIXELFORMAT_DEPTH;
    d.depth.compare = SG_COMPAREFUNC_LESS_EQUAL;
    d.depth.write_enabled = true;
    d.colors[0].pixel_format = SG_PIXELFORMAT_R32F;
    d.cull_mode = SG_CULLMODE_NONE;
    d.face_winding = SG_FACEWINDING_CCW;
    d.sample_count = 1;
    d.label = "shadow";
    return find_or_make(key, d);
}

sg_pipeline Gpu::blit_pipeline(sg_pixel_format colorFormat, sg_pixel_format depthFormat, int sampleCount) {
    PipelineKey key{0x500u | (std::uint32_t(colorFormat) << 12) | (std::uint32_t(depthFormat) << 20) |
                    (std::uint32_t(sampleCount) << 28)};
    sg_pipeline_desc d{};
    d.shader = blit_shader_;
    d.layout.attrs[ATTR_blit_blit_pos].format = SG_VERTEXFORMAT_FLOAT2;
    d.depth.pixel_format = depthFormat;
    d.depth.compare = SG_COMPAREFUNC_ALWAYS;
    d.depth.write_enabled = false;
    d.colors[0].pixel_format = colorFormat;
    d.sample_count = sampleCount;
    d.face_winding = SG_FACEWINDING_CCW;
    d.label = "blit";
    return find_or_make(key, d);
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
