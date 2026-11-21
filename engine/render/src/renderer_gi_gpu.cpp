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
#include "shaders/probe.glsl.h"

namespace fa::render {

namespace {

bool valid_image(sg_image i) { return i.id && sg_query_image_state(i) == SG_RESOURCESTATE_VALID; }
bool valid_view(sg_view v) { return v.id && sg_query_view_state(v) == SG_RESOURCESTATE_VALID; }

}  // namespace

bool ProbeGpu::gi_ready() {
    if (giState_ != 0) return giState_ > 0;
    if (!ready()) return false;  // not remembered: ready() said why
    const sg_pixelformat_info half = sg_query_pixelformat(SG_PIXELFORMAT_RGBA16F);
    bool ok = format_ == SG_PIXELFORMAT_RGBA16F && half.render && half.blend && half.sample;
    if (ok) {
        const sg_backend backend = sg_query_backend();
        const struct {
            Prog prog;
            const sg_shader_desc* desc;
            const char* name;
        } programs[] = {{Prog::FaceGi, probe_face_gi_shader_desc(backend), "probe_face_gi"},
                        {Prog::GiDist, probe_gi_dist_shader_desc(backend), "probe_gi_dist"},
                        {Prog::GiDepth, probe_gi_depth_shader_desc(backend), "probe_gi_depth"},
                        {Prog::GiMeta, probe_gi_meta_shader_desc(backend), "probe_gi_meta"}};
        for (const auto& p : programs) {
            shaders_[int(p.prog)] = make_shader(p.desc, p.name);
            ok = ok && sg_query_shader_state(shaders_[int(p.prog)]) == SG_RESOURCESTATE_VALID;
        }
    }
    if (ok) {
        sg_sampler_desc sd{};
        sd.min_filter = SG_FILTER_NEAREST;
        sd.mag_filter = SG_FILTER_NEAREST;
        sd.mipmap_filter = SG_FILTER_NEAREST;
        sd.wrap_u = sd.wrap_v = sd.wrap_w = SG_WRAP_CLAMP_TO_EDGE;
        sd.label = "probe-nearest";
        nearest_ = sg_make_sampler(&sd);
        ok = nearest_.id && sg_query_sampler_state(nearest_) == SG_RESOURCESTATE_VALID;
    }
    if (ok) {
        const struct {
            Prog prog;
            sg_shader shader;
            bool blend;
        } pipes[] = {{Prog::FaceGi, shaders_[int(Prog::FaceGi)], false},
                     {Prog::GiDist, shaders_[int(Prog::GiDist)], false},
                     {Prog::GiDepth, shaders_[int(Prog::GiDepth)], true},
                     {Prog::GiMeta, shaders_[int(Prog::GiMeta)], true},
                     {Prog::ShBlend, shaders_[int(Prog::Sh)], true}};
        for (const auto& p : pipes) {
            sg_pipeline_desc d{};
            d.shader = p.shader;
            d.layout.attrs[ATTR_probe_face_pos].format = SG_VERTEXFORMAT_FLOAT2;
            d.depth.compare = SG_COMPAREFUNC_ALWAYS;
            d.depth.write_enabled = false;
            d.depth.pixel_format = SG_PIXELFORMAT_NONE;
            d.colors[0].pixel_format = format_;
            if (p.blend) {
                // The new value with the weight of the shader's alpha over the old one (the hysteresis); the alpha channel keeps what it was.
                d.colors[0].blend.enabled = true;
                d.colors[0].blend.src_factor_rgb = SG_BLENDFACTOR_SRC_ALPHA;
                d.colors[0].blend.dst_factor_rgb = SG_BLENDFACTOR_ONE_MINUS_SRC_ALPHA;
                d.colors[0].blend.src_factor_alpha = SG_BLENDFACTOR_ZERO;
                d.colors[0].blend.dst_factor_alpha = SG_BLENDFACTOR_ONE;
            }
            d.sample_count = 1;
            d.face_winding = SG_FACEWINDING_CCW;
            d.label = "probe-gi";
            pipelines_[int(p.prog)] = sg_make_pipeline(&d);
            ok = ok && sg_query_pipeline_state(pipelines_[int(p.prog)]) == SG_RESOURCESTATE_VALID;
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
    for (DistImage& d : dist_) {
        if (d.att.id) sg_destroy_view(d.att);
        if (d.tex.id) sg_destroy_view(d.tex);
        if (d.image.id) sg_destroy_image(d.image);
    }
    dist_.clear();
    if (nearest_.id) sg_destroy_sampler(nearest_);
    nearest_ = {};
    // The programs and pipelines of the GI are in the arrays release() empties; a failed gi_ready() leaves the half it made in them.
    for (Prog p : {Prog::FaceGi, Prog::GiDist, Prog::GiDepth, Prog::GiMeta, Prog::ShBlend}) {
        if (pipelines_[int(p)].id) sg_destroy_pipeline(pipelines_[int(p)]);
        pipelines_[int(p)] = {};
        if (p != Prog::ShBlend && shaders_[int(p)].id) sg_destroy_shader(shaders_[int(p)]);
        shaders_[int(p)] = {};
    }
    giState_ = 0;
}

bool ProbeGpu::dist_image(int index, int res) {
    if (index < 0 || index > 4096 || !gi_ready()) return false;
    if (std::size_t(index) >= dist_.size()) dist_.resize(std::size_t(index) + 1);
    DistImage& d = dist_[std::size_t(index)];
    if (d.size == res && valid_image(d.image)) return true;
    if (d.att.id) sg_destroy_view(d.att);
    if (d.tex.id) sg_destroy_view(d.tex);
    if (d.image.id) sg_destroy_image(d.image);
    d = DistImage{};
    sg_image_desc id{};
    id.usage.color_attachment = true;
    id.width = id.height = res;
    id.pixel_format = SG_PIXELFORMAT_RGBA16F;
    id.label = "probe-gi-distance";
    d.image = make_image(id);
    if (!valid_image(d.image)) {
        if (d.image.id) sg_destroy_image(d.image);
        d = DistImage{};
        return false;
    }
    sg_view_desc vd{};
    vd.texture.image = d.image;
    vd.label = "probe-gi-distance";
    d.tex = sg_make_view(&vd);
    sg_view_desc ad{};
    ad.color_attachment.image = d.image;
    ad.label = "probe-gi-distance";
    d.att = sg_make_view(&ad);
    if (!valid_view(d.tex) || !valid_view(d.att)) {
        if (d.att.id) sg_destroy_view(d.att);
        if (d.tex.id) sg_destroy_view(d.tex);
        sg_destroy_image(d.image);
        d = DistImage{};
        return false;
    }
    d.size = res;
    return true;
}

sg_view ProbeGpu::dist_view(int index) const {
    if (index < 0 || std::size_t(index) >= dist_.size()) return {};
    return dist_[std::size_t(index)].tex;
}

void ProbeGpu::gi_dist(Gpu& gpu, int index, sg_view front, sg_view back, float maxDistance, int* drawCalls) {
    if (index < 0 || std::size_t(index) >= dist_.size() || !dist_[std::size_t(index)].att.id) return;
    const DistImage& di = dist_[std::size_t(index)];
    PassDesc pd;
    pd.label = "probe-gi-distance";
    pd.color = di.att;
    pd.format = TargetFormat{SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(pipelines_[int(Prog::GiDist)]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_pre_front] = front;
    b.views[VIEW_probe_probe_pre_back] = back;
    b.samplers[SMP_probe_probe_nsmp] = nearest_;
    sg_apply_bindings(&b);
    probe_probe_gi_dist_params_t u{};
    u.d[0] = float(di.size);
    u.d[1] = isGl_ ? 1.0f : 0.0f;
    u.d[2] = maxDistance;
    sg_range r{&u, sizeof(u)};
    sg_apply_uniforms(UB_probe_probe_gi_dist_params, &r);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::face_gi(Gpu& gpu, int slot, int face, sg_view picture, sg_view dist, float maxDistance, int* drawCalls) {
    Scratch& s = scratch_[slot];
    const ProbeFace c = probe_face(face);
    PassDesc pd;
    pd.label = "probe-gi-face";
    pd.color = s.att[0][face];
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(pipelines_[int(Prog::FaceGi)]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_gcol] = picture;
    b.views[VIEW_probe_probe_gdist] =
        dist.id ? dist : picture;  // a slot must hold a view: the shader ignores it when g.x = 1
    b.samplers[SMP_probe_probe_nsmp] = nearest_;
    sg_apply_bindings(&b);
    const EnvFace f = env_face(face, isGl_);
    probe_probe_vs_params_t vu{};
    for (int i = 0; i < 3; ++i) {
        vu.fwd[i] = f.fwd[i];
        vu.right[i] = f.right[i];
        vu.up[i] = f.up[i];
    }
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_probe_probe_vs_params, &vr);
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
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_probe_probe_gi_face_params, &fr);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
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

}  // namespace fa::render
