#include "renderer_env.h"

#include <algorithm>
#include <cstring>
#include <string>

#include "fa/core/log.h"

#include "shader_cache.h"
#include "gpu/sokol_shaders.h"
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

bool g_forceRgba8 = false;

bool usable(gpu::Device& device, gpu::PixelFormat f) {
    const gpu::PixelFormatCaps i = device.pixel_format_caps(f);
    return i.sample && i.filter && i.render;
}

bool valid(gpu::Device& device, gpu::Image i) { return i.id && device.state(i) == gpu::ResourceState::Valid; }
bool valid(gpu::Device& device, gpu::Sampler s) { return s.id && device.state(s) == gpu::ResourceState::Valid; }
bool valid(gpu::Device& device, gpu::View v) { return v.id && device.state(v) == gpu::ResourceState::Valid; }

gpu::Image make_cube(gpu::Device& device, int size, int mips, gpu::PixelFormat format, const char* label) {
    gpu::ImageDesc d;
    d.type = gpu::ImageType::Cube;
    d.usage.colorAttachment = true;
    d.width = size;
    d.height = size;
    d.numMipmaps = mips;
    d.pixelFormat = format;
    d.label = label;
    return device.make_image(d);  // the device applies the per-backend cube fixes (image_gl.cpp)
}

gpu::View texture_view(gpu::Device& device, gpu::Image image, const char* label) {
    gpu::ViewDesc v;
    v.texture.image = image;
    v.label = label;
    return device.make_view(v);
}

gpu::View face_view(gpu::Device& device, gpu::Image image, int mip, int face, const char* label) {
    gpu::ViewDesc v;
    v.colorAttachment.image = image;
    v.colorAttachment.mipLevel = mip;
    v.colorAttachment.slice = face;
    v.label = label;
    return device.make_view(v);
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

void Environment::force_rgba8_for_tests(bool force) { g_forceRgba8 = force; }

bool Environment::ready(Gpu& gpu) {
    if (state_ != 0) return state_ > 0;
    gpu::Device& device = gpu.device();
    device_ = &device;
    // The cube needs a format the GPU renders to and filters: the half-float one keeps the sky's brightness (a sun, an
    // HDR sky), RGBA8 is the fallback (GLES 3 without the half-float render extension).
    format_ = usable(device, gpu::PixelFormat::Rgba16F) && !g_forceRgba8
                  ? gpu::PixelFormat::Rgba16F
                  : (usable(device, gpu::PixelFormat::Rgba8) ? gpu::PixelFormat::Rgba8 : gpu::PixelFormat::None);
    bool ok = format_ != gpu::PixelFormat::None;
    if (ok) {
        shaders_[int(Prog::Copy)] =
            make_shader(device, gpu::generated_shader_desc(device, env_copy_shader_desc), "env_copy");
        shaders_[int(Prog::Prefilter)] =
            make_shader(device, gpu::generated_shader_desc(device, env_prefilter_shader_desc), "env_prefilter");
        shaders_[int(Prog::Sh)] = make_shader(device, gpu::generated_shader_desc(device, env_sh_shader_desc), "env_sh");
        for (gpu::Shader s : shaders_) ok = ok && device.state(s) == gpu::ResourceState::Valid;
    }
    if (ok) {
        gpu::SamplerDesc sd;
        sd.minFilter = gpu::Filter::Linear;
        sd.magFilter = gpu::Filter::Linear;
        sd.mipmapFilter = gpu::Filter::Linear;
        sd.wrapU = sd.wrapV = sd.wrapW = gpu::Wrap::ClampToEdge;
        sd.label = "env-sampler";
        if (!sampler_.id) sampler_ = device.make_sampler(sd);
        for (int i = 0; i < kEnvPyramid; ++i) {
            const int size = kEnvSize >> i;
            const std::string name = "env-s" + std::to_string(i);
            pyramid_[i] = make_cube(device, size, 1, format_, name.c_str());
            pyramidTex_[i] = texture_view(device, pyramid_[i], name.c_str());
            ok = ok && valid(device, pyramid_[i]) && valid(device, pyramidTex_[i]);
            for (int f = 0; f < 6; ++f) {
                pyramidAtt_[i][f] = face_view(device, pyramid_[i], 0, f, name.c_str());
                ok = ok && valid(device, pyramidAtt_[i][f]);
            }
        }
        pre_ = make_cube(device, kEnvSize, kEnvLevels + 1, format_, "env-prefiltered");  // + the SH mip
        preTex_ = texture_view(device, pre_, "env-prefiltered");
        ok = ok && valid(device, pre_) && valid(device, preTex_);
        for (int m = 0; m < kEnvLevels; ++m)
            for (int f = 0; f < 6; ++f) {
                preAtt_[m][f] = face_view(device, pre_, m, f, "env-prefiltered");
                ok = ok && valid(device, preAtt_[m][f]);
            }
        ok = ok && valid(device, sampler_);
        for (int f = 0; f < 6; ++f) {
            shAtt_[f] = face_view(device, pre_, kEnvShMip, f, "env-sh");
            ok = ok && valid(device, shAtt_[f]);
        }
    }
    if (ok) {
        for (int p = 0; p < int(Prog::Count); ++p) {
            gpu::PipelineDesc d;
            d.shader = shaders_[p];
            d.layout.attrs[ATTR_env_copy_pos].format = gpu::VertexFormat::Float2;  // `pos`, location 0 in every program
            d.depth.compare = gpu::CompareFunc::Always;
            d.depth.writeEnabled = false;
            d.depth.pixelFormat = gpu::PixelFormat::None;
            d.colors[0].pixelFormat = format_;
            d.sampleCount = 1;
            d.faceWinding = gpu::FaceWinding::Ccw;
            d.label = p == int(Prog::Copy) ? "env-copy" : p == int(Prog::Prefilter) ? "env-prefilter" : "env-sh";
            pipelines_[p] = device.make_pipeline(d);
            ok = ok && device.state(pipelines_[p]) == gpu::ResourceState::Valid;
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

gpu::Pipeline Environment::pipeline(Prog prog) { return pipelines_[int(prog)]; }

void Environment::draw(Gpu& gpu, Prog prog, gpu::View dst, gpu::View srcTex, int face, float roughness, float samples,
                       const char* label, int* drawCalls, bool lit) {
    gpu::PassDesc pd;
    pd.label = label;
    pd.color = dst;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& list = gpu.commands();
    list.begin_pass(pd);
    list.set_pipeline(pipeline(prog));
    gpu::Bindings b;
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_env_env_src] = srcTex;
    b.samplers[SMP_env_env_smp] = sampler_;
    list.set_bindings(b);
    const EnvFace f = env_face(face, gpu.is_gl());
    env_env_vs_params_t vu{};
    for (int i = 0; i < 3; ++i) {
        vu.fwd[i] = f.fwd[i];
        vu.right[i] = f.right[i];
        vu.up[i] = f.up[i];
    }
    list.set_uniforms(UB_env_env_vs_params, gpu::Range{&vu, sizeof(vu)});
    // `lit`: the pass writes a level the meshes read, so it applies the bake's gain (and the convolutions its limit); the pyramid
    // that the convolutions read is the sky as it is.
    env_env_params_t fu{};
    fu.p[0] = roughness;
    fu.p[1] = samples;
    fu.p[2] = prog == Prog::Copy ? 0.0f : active_.tapLimit;
    fu.p[3] = lit ? active_.gain : 1.0f;
    list.set_uniforms(UB_env_env_params, gpu::Range{&fu, sizeof(fu)});
    list.draw(0, 3, 1);
    list.end_pass();
    if (drawCalls) ++*drawCalls;
}

// Part A of a bake: the sky into S0 and the pyramid under it (6 + 18 passes).
void Environment::bake_sky(Gpu& gpu, const SkyDraw& sky, int* drawCalls) {
    const TargetFormat fmt{format_, gpu::PixelFormat::None, 1};
    // The sky itself: the material's program into the six faces of S0.
    gpu::CommandList& list = gpu.commands();
    for (int f = 0; f < 6; ++f) {
        gpu::PassDesc pd;
        pd.label = "env-sky";
        pd.color = pyramidAtt_[0][f];
        pd.format = fmt;
        pd.colorLoad = gpu::LoadAction::DontCare;
        pd.colorStore = gpu::StoreAction::Store;
        list.begin_pass(pd);
        float m[16];
        env_face_matrix(env_face(f, gpu.is_gl()), m);
        sky(m, fmt);  // records on the same list (Gpu::commands())
        list.end_pass();
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

// The spherical harmonics of the smallest pyramid image, into mip kEnvShMip of the prefiltered cube (env.glsl, fs_sh): the face +X
// holds the nine coefficients, the other five are zeroed (no texel of the mip is ever garbage). `roughness` carries "this is the
// data face" and `samples` "the cube is RGBA8" (the program's p.x and p.y).
void Environment::bake_sh(Gpu& gpu, int* drawCalls) {
    for (int f = 0; f < 6; ++f)
        draw(gpu, Prog::Sh, shAtt_[f], pyramidTex_[kEnvPyramid - 1], f, f == 0 ? 1.0f : 0.0f,
             format_ == gpu::PixelFormat::Rgba8 ? 1.0f : 0.0f, "env-sh", drawCalls, true);
}

void Environment::bake(Gpu& gpu, std::uint64_t key, const SkyDraw& sky, int* drawCalls) {
    baked_ = false;
    slice_ = 0;
    if (state_ <= 0) return;
    active_ = look_;
    bake_sky(gpu, sky, drawCalls);
    bake_levels(gpu, 0, kEnvLevels - 1, drawCalls);
    bake_sh(gpu, drawCalls);
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
    bake_sh(gpu, drawCalls);
    slice_ = 0;
    baked_ = true;
    key_ = pendingKey_;
}

void Environment::destroy_images() {
    if (!device_) return;
    gpu::Device& device = *device_;
    for (int i = 0; i < kEnvPyramid; ++i) {
        for (gpu::View& v : pyramidAtt_[i]) {
            if (v.id) device.destroy_view(v);
            v = {};
        }
        if (pyramidTex_[i].id) device.destroy_view(pyramidTex_[i]);
        pyramidTex_[i] = {};
        if (pyramid_[i].id) device.destroy_image(pyramid_[i]);
        pyramid_[i] = {};
    }
    for (auto& level : preAtt_)
        for (gpu::View& v : level) {
            if (v.id) device.destroy_view(v);
            v = {};
        }
    for (gpu::View& v : shAtt_) {
        if (v.id) device.destroy_view(v);
        v = {};
    }
    if (preTex_.id) device.destroy_view(preTex_);
    preTex_ = {};
    if (pre_.id) device.destroy_image(pre_);
    pre_ = {};
}

void Environment::release() {
    destroy_images();
    if (device_) {
        for (gpu::Pipeline& p : pipelines_) {
            if (p.id) device_->destroy_pipeline(p);
            p = {};
        }
        for (gpu::Shader& s : shaders_) {
            if (s.id) device_->destroy_shader(s);
            s = {};
        }
        if (sampler_.id) device_->destroy_sampler(sampler_);
        sampler_ = {};
    }
    state_ = 0;
    baked_ = false;
    key_ = 0;
    slice_ = 0;
    pendingKey_ = 0;
    tagKey_ = 0;
    look_ = active_ = Look{};
}

}  // namespace fa::render
