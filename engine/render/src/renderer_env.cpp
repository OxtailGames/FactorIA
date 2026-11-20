#include "renderer_env.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "shaders/env.glsl.h"

namespace fa::render {

namespace {

// The cube map specification's faces (+X -X +Y -Y +Z -Z): the direction the face looks along and the directions of
// increasing column (right) and of row 0 (up) as seen from inside the cube. Row 0 of the memory is the top of the face
// on every backend: the table of the OpenGL specification (s = (sc/|ma| + 1)/2, t = (tc/|ma| + 1)/2, t grows downwards)
// read as: +X sc = -z, tc = -y; -X sc = +z, tc = -y; +Y sc = +x, tc = +z; -Y sc = +x, tc = -z; +Z sc = +x, tc = -y; -Z
// sc = -x, tc = -y. Direct3D and Metal use the same layout.
struct FaceBasis {
    float fwd[3], right[3], up[3];
};
constexpr FaceBasis kFaces[6] = {
    {{1, 0, 0}, {0, 0, -1}, {0, 1, 0}},   // +X
    {{-1, 0, 0}, {0, 0, 1}, {0, 1, 0}},   // -X
    {{0, 1, 0}, {1, 0, 0}, {0, 0, -1}},   // +Y
    {{0, -1, 0}, {1, 0, 0}, {0, 0, 1}},   // -Y
    {{0, 0, 1}, {1, 0, 0}, {0, 1, 0}},    // +Z
    {{0, 0, -1}, {-1, 0, 0}, {0, 1, 0}},  // -Z
};

bool usable(sg_pixel_format f) {
    const sg_pixelformat_info i = sg_query_pixelformat(f);
    return i.sample && i.filter && i.render;
}

bool valid(sg_image i) { return i.id && sg_query_image_state(i) == SG_RESOURCESTATE_VALID; }
bool valid(sg_sampler s) { return s.id && sg_query_sampler_state(s) == SG_RESOURCESTATE_VALID; }
bool valid(sg_view v) { return v.id && sg_query_view_state(v) == SG_RESOURCESTATE_VALID; }

sg_image make_cube(int size, int mips, sg_pixel_format format, const char* label) {
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_CUBE;
    d.usage.color_attachment = true;
    d.width = size;
    d.height = size;
    d.num_mipmaps = mips;
    d.pixel_format = format;
    d.label = label;
    return make_cube_image(d);
}

sg_view texture_view(sg_image image, const char* label) {
    sg_view_desc v{};
    v.texture.image = image;
    v.label = label;
    return sg_make_view(&v);
}

sg_view face_view(sg_image image, int mip, int face, const char* label) {
    sg_view_desc v{};
    v.color_attachment.image = image;
    v.color_attachment.mip_level = mip;
    v.color_attachment.slice = face;
    v.label = label;
    return sg_make_view(&v);
}

}  // namespace

EnvFace env_face(int face, bool gl) {
    const FaceBasis& b = kFaces[std::clamp(face, 0, 5)];
    EnvFace f{};
    for (int i = 0; i < 3; ++i) {
        f.fwd[i] = b.fwd[i];
        f.right[i] = b.right[i];
        f.up[i] = gl ? -b.up[i] : b.up[i];
    }
    return f;
}

void env_face_matrix(const EnvFace& face, float out[16]) {
    for (int i = 0; i < 3; ++i) {
        out[i] = face.right[i];
        out[4 + i] = face.up[i];
        out[8 + i] = face.fwd[i];
        out[12 + i] = 0.0f;
    }
    out[3] = out[7] = out[11] = 0.0f;
    out[15] = 1.0f;
}

bool Environment::ready(Gpu&) {
    if (state_ != 0) return state_ > 0;
    // The cube needs a format the GPU renders to and filters: the half-float one keeps the sky's brightness (a sun, an
    // HDR sky), RGBA8 is the fallback (GLES 3 without the half-float render extension).
    format_ = usable(SG_PIXELFORMAT_RGBA16F)
                  ? SG_PIXELFORMAT_RGBA16F
                  : (usable(SG_PIXELFORMAT_RGBA8) ? SG_PIXELFORMAT_RGBA8 : SG_PIXELFORMAT_NONE);
    bool ok = format_ != SG_PIXELFORMAT_NONE;
    if (ok) {
        const sg_backend backend = sg_query_backend();
        shaders_[int(Prog::Copy)] = make_shader(env_copy_shader_desc(backend), "env_copy");
        shaders_[int(Prog::Prefilter)] = make_shader(env_prefilter_shader_desc(backend), "env_prefilter");
        shaders_[int(Prog::Irradiance)] = make_shader(env_irradiance_shader_desc(backend), "env_irradiance");
        for (sg_shader s : shaders_) ok = ok && sg_query_shader_state(s) == SG_RESOURCESTATE_VALID;
    }
    if (ok) {
        sg_sampler_desc sd{};
        sd.min_filter = SG_FILTER_LINEAR;
        sd.mag_filter = SG_FILTER_LINEAR;
        sd.mipmap_filter = SG_FILTER_LINEAR;
        sd.wrap_u = sd.wrap_v = sd.wrap_w = SG_WRAP_CLAMP_TO_EDGE;
        sd.label = "env-sampler";
        if (!sampler_.id) sampler_ = sg_make_sampler(&sd);  // blank_view() may have made it already: never leak it
        for (int i = 0; i < kEnvPyramid; ++i) {
            const int size = kEnvSize >> i;
            const std::string name = "env-s" + std::to_string(i);
            pyramid_[i] = make_cube(size, 1, format_, name.c_str());
            pyramidTex_[i] = texture_view(pyramid_[i], name.c_str());
            ok = ok && valid(pyramid_[i]) && valid(pyramidTex_[i]);
            for (int f = 0; f < 6; ++f) {
                pyramidAtt_[i][f] = face_view(pyramid_[i], 0, f, name.c_str());
                ok = ok && valid(pyramidAtt_[i][f]);
            }
        }
        pre_ = make_cube(kEnvSize, kEnvLevels, format_, "env-prefiltered");
        preTex_ = texture_view(pre_, "env-prefiltered");
        ok = ok && valid(pre_) && valid(preTex_);
        for (int m = 0; m < kEnvLevels; ++m)
            for (int f = 0; f < 6; ++f) {
                preAtt_[m][f] = face_view(pre_, m, f, "env-prefiltered");
                ok = ok && valid(preAtt_[m][f]);
            }
        irr_ = make_cube(kEnvIrrSize, 1, format_, "env-irradiance");
        irrTex_ = texture_view(irr_, "env-irradiance");
        ok = ok && valid(irr_) && valid(irrTex_) && valid(sampler_);
        for (int f = 0; f < 6; ++f) {
            irrAtt_[f] = face_view(irr_, 0, f, "env-irradiance");
            ok = ok && valid(irrAtt_[f]);
        }
    }
    if (ok) {
        for (int p = 0; p < int(Prog::Count); ++p) {
            sg_pipeline_desc d{};
            d.shader = shaders_[p];
            d.layout.attrs[ATTR_env_copy_pos].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
            d.depth.compare = SG_COMPAREFUNC_ALWAYS;
            d.depth.write_enabled = false;
            d.depth.pixel_format = SG_PIXELFORMAT_NONE;
            d.colors[0].pixel_format = format_;
            d.sample_count = 1;
            d.face_winding = SG_FACEWINDING_CCW;
            d.label = p == int(Prog::Copy)        ? "env-copy"
                      : p == int(Prog::Prefilter) ? "env-prefilter"
                                                  : "env-irradiance";
            pipelines_[p] = sg_make_pipeline(&d);
            ok = ok && sg_query_pipeline_state(pipelines_[p]) == SG_RESOURCESTATE_VALID;
        }
    }
    if (!ok) {
        release();
        state_ = -1;
        FA_ERROR("render", "The sky material cannot light the meshes: the environment cubemaps or their shaders could "
                           "not be made for this graphics "
                           "backend (see the sokol log lines above). The meshes keep lighting themselves from skyColor "
                           "and horizonColor. Hint: "
                           "update the graphics driver (Mesa: try LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

sg_pipeline Environment::pipeline(Prog prog) { return pipelines_[int(prog)]; }

sg_view Environment::blank_view(Gpu&) {
    if (blankTex_.id) return blankTex_;
    // 1x1 black faces: bound while no sky environment is used, so a program that declares the slot has a valid view.
    const std::uint8_t px[6 * 4] = {0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255};
    sg_image_desc d{};
    d.type = SG_IMAGETYPE_CUBE;
    d.width = 1;
    d.height = 1;
    d.pixel_format = SG_PIXELFORMAT_RGBA8;
    d.data.mip_levels[0] = {px, sizeof(px)};
    d.label = "env-blank";
    blank_ = make_cube_image(d);
    blankTex_ = texture_view(blank_, "env-blank");
    if (!sampler_.id) {
        sg_sampler_desc sd{};
        sd.min_filter = SG_FILTER_LINEAR;
        sd.mag_filter = SG_FILTER_LINEAR;
        sd.mipmap_filter = SG_FILTER_LINEAR;
        sd.wrap_u = sd.wrap_v = sd.wrap_w = SG_WRAP_CLAMP_TO_EDGE;
        sd.label = "env-sampler";
        sampler_ = sg_make_sampler(&sd);
    }
    return blankTex_;
}

void Environment::draw(Gpu& gpu, Prog prog, sg_view dst, sg_view srcTex, int face, float roughness, float samples,
                       const char* label, int* drawCalls, bool lit) {
    PassDesc pd;
    pd.label = label;
    pd.color = dst;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(pipeline(prog));
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_env_env_src] = srcTex;
    b.samplers[SMP_env_env_smp] = sampler_;
    sg_apply_bindings(&b);
    const EnvFace f = env_face(face, gpu.is_gl());
    env_env_vs_params_t vu{};
    for (int i = 0; i < 3; ++i) {
        vu.fwd[i] = f.fwd[i];
        vu.right[i] = f.right[i];
        vu.up[i] = f.up[i];
    }
    sg_range vr{&vu, sizeof(vu)};
    sg_apply_uniforms(UB_env_env_vs_params, &vr);
    // `lit`: the pass writes a level the meshes read, so it applies the bake's gain (and the convolutions its limit); the pyramid
    // that the convolutions read is the sky as it is.
    env_env_params_t fu{};
    fu.p[0] = roughness;
    fu.p[1] = samples;
    fu.p[2] = prog == Prog::Copy ? 0.0f : active_.tapLimit;
    fu.p[3] = lit ? active_.gain : 1.0f;
    sg_range fr{&fu, sizeof(fu)};
    sg_apply_uniforms(UB_env_env_params, &fr);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

// Part A of a bake: the sky into S0 and the pyramid under it (6 + 18 passes).
void Environment::bake_sky(Gpu& gpu, const SkyDraw& sky, int* drawCalls) {
    const TargetFormat fmt{format_, SG_PIXELFORMAT_NONE, 1};
    // The sky itself: the material's program into the six faces of S0.
    for (int f = 0; f < 6; ++f) {
        PassDesc pd;
        pd.label = "env-sky";
        pd.color = pyramidAtt_[0][f];
        pd.format = fmt;
        pd.colorLoad = SG_LOADACTION_DONTCARE;
        pd.colorStore = SG_STOREACTION_STORE;
        Gpu::begin_pass(pd);
        float m[16];
        env_face_matrix(env_face(f, gpu.is_gl()), m);
        sky(m, fmt);
        Gpu::end_pass();
        if (drawCalls) ++*drawCalls;
    }
    // The pyramid: each image is the bilinear down-sampling of the one before.
    for (int s = 1; s < kEnvPyramid; ++s)
        for (int f = 0; f < 6; ++f)
            draw(gpu, Prog::Copy, pyramidAtt_[s][f], pyramidTex_[s - 1], f, 0.0f, 0.0f, "env-down", drawCalls);
}

// Part B and C: the levels `first` .. `last` of the prefiltered cube (level 0 is the sky itself, level k the GGX lobe of
// roughness k / (levels - 1) read from the pyramid image of about the size of the level: it never reads the image it draws
// into).
void Environment::bake_levels(Gpu& gpu, int first, int last, int* drawCalls) {
    for (int m = first; m <= last; ++m) {
        if (m == 0) {
            for (int f = 0; f < 6; ++f)
                draw(gpu, Prog::Copy, preAtt_[0][f], pyramidTex_[0], f, 0.0f, 0.0f, "env-level0", drawCalls, true);
            continue;
        }
        const float roughness = float(m) / float(kEnvLevels - 1);
        const float samples = m <= 2 ? 32.0f : 64.0f;
        for (int f = 0; f < 6; ++f)
            draw(gpu, Prog::Prefilter, preAtt_[m][f], pyramidTex_[std::min(m, kEnvPyramid - 1)], f, roughness, samples,
                 "env-prefilter", drawCalls, true);
    }
}

// The irradiance: the cosine lobe of the smallest pyramid image.
void Environment::bake_irradiance(Gpu& gpu, int* drawCalls) {
    for (int f = 0; f < 6; ++f)
        draw(gpu, Prog::Irradiance, irrAtt_[f], pyramidTex_[kEnvPyramid - 1], f, 0.0f, 128.0f, "env-irradiance",
             drawCalls, true);
}

void Environment::bake(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls) {
    baked_ = false;
    slice_ = 0;
    if (state_ <= 0) return;
    active_ = look_;
    bake_sky(gpu, sky, drawCalls);
    bake_levels(gpu, 0, kEnvLevels - 1, drawCalls);
    bake_irradiance(gpu, drawCalls);
    baked_ = true;
    key_ = key;
}

void Environment::bake_slice(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls) {
    if (state_ <= 0) return;
    if (slice_ == 0) {  // a new sequence: the sky of this frame is what it bakes
        active_ = look_;
        bake_sky(gpu, sky, drawCalls);
        pendingKey_ = key;
        slice_ = 1;
        return;
    }
    if (slice_ == 1) {
        bake_levels(gpu, 0, 2, drawCalls);
        slice_ = 2;
        return;
    }
    bake_levels(gpu, 3, kEnvLevels - 1, drawCalls);
    bake_irradiance(gpu, drawCalls);
    slice_ = 0;
    baked_ = true;
    key_ = pendingKey_;
}

void Environment::destroy_images() {
    for (int i = 0; i < kEnvPyramid; ++i) {
        for (sg_view& v : pyramidAtt_[i]) {
            if (v.id) sg_destroy_view(v);
            v = {};
        }
        if (pyramidTex_[i].id) sg_destroy_view(pyramidTex_[i]);
        pyramidTex_[i] = {};
        if (pyramid_[i].id) sg_destroy_image(pyramid_[i]);
        pyramid_[i] = {};
    }
    for (auto& level : preAtt_)
        for (sg_view& v : level) {
            if (v.id) sg_destroy_view(v);
            v = {};
        }
    if (preTex_.id) sg_destroy_view(preTex_);
    preTex_ = {};
    if (pre_.id) sg_destroy_image(pre_);
    pre_ = {};
    for (sg_view& v : irrAtt_) {
        if (v.id) sg_destroy_view(v);
        v = {};
    }
    if (irrTex_.id) sg_destroy_view(irrTex_);
    irrTex_ = {};
    if (irr_.id) sg_destroy_image(irr_);
    irr_ = {};
}

void Environment::release() {
    destroy_images();
    for (sg_pipeline& p : pipelines_) {
        if (p.id) sg_destroy_pipeline(p);
        p = {};
    }
    for (sg_shader& s : shaders_) {
        if (s.id) sg_destroy_shader(s);
        s = {};
    }
    if (sampler_.id) sg_destroy_sampler(sampler_);
    sampler_ = {};
    if (blankTex_.id) sg_destroy_view(blankTex_);
    blankTex_ = {};
    if (blank_.id) sg_destroy_image(blank_);
    blank_ = {};
    state_ = 0;
    baked_ = false;
    key_ = 0;
    slice_ = 0;
    pendingKey_ = 0;
    tagKey_ = 0;
    look_ = active_ = Look{};
}

}  // namespace fa::render
