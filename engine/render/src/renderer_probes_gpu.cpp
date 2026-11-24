// The GPU half of the reflection probes (renderer_probes.h): the passes that fill the atlas. shaders/probe.glsl documents each program.
#include <algorithm>
#include <cmath>
#include <cstring>
#include <string>

#include "fa/core/image_float.h"
#include "fa/core/log.h"
#include "renderer_env.h"
#include "renderer_probes.h"
#include "shader_cache.h"
#include "shaders/probe.glsl.h"

namespace fa::render {

namespace {

bool g_forceRgba8 = false;

bool usable(gpu::Device& device, gpu::PixelFormat f) {
    const gpu::PixelFormatCaps c = device.pixel_format_caps(f);
    return c.sample && c.filter && c.render;
}
bool valid(gpu::Device& device, gpu::Image i) { return i.id && device.state(i) == gpu::ResourceState::Valid; }
bool valid(gpu::Device& device, gpu::View v) { return v.id && device.state(v) == gpu::ResourceState::Valid; }

gpu::View texture_view(gpu::Device& device, gpu::Image image, const char* label) {
    gpu::ViewDesc v{};
    v.texture.image = image;
    v.label = label;
    return device.make_view(v);
}
gpu::View attachment_view(gpu::Device& device, gpu::Image image, int slice, const char* label) {
    gpu::ViewDesc v{};
    v.colorAttachment.image = image;
    v.colorAttachment.slice = slice;
    v.label = label;
    return device.make_view(v);
}

// A half float with its sign (render_internal.h float_to_half_bits is for values that are never negative).
std::uint16_t signed_half_bits(float f) {
    if (!std::isfinite(f)) return 0;
    return std::uint16_t((f < 0.0f ? 0x8000u : 0u) | float_to_half_bits(std::fabs(f)));
}

// A small immutable image with data and its texture view, for a baked page on its way into the atlas.
struct Upload {
    gpu::Device& device;
    gpu::Image image{};
    gpu::View view{};
    explicit Upload(gpu::Device& d) : device(d) {}
    Upload(const Upload&) = delete;
    Upload& operator=(const Upload&) = delete;
    bool make(int w, int h, gpu::PixelFormat format, const void* data, std::size_t bytes, const char* label) {
        gpu::ImageDesc d{};
        d.width = w;
        d.height = h;
        d.pixelFormat = format;
        d.data.mipLevels[0] = {data, bytes};
        d.label = label;
        image = device.make_image(d);
        if (!valid(device, image)) return false;
        view = texture_view(device, image, label);
        return valid(device, view);
    }
    ~Upload() {
        if (view.id) device.destroy_view(view);
        if (image.id) device.destroy_image(image);
    }
};

}  // namespace

void ProbeGpu::force_rgba8_for_tests(bool force) { g_forceRgba8 = force; }

bool ProbeGpu::ready(Gpu& gpu) {
    gpu_ = &gpu;
    if (state_ != 0) return state_ > 0;
    gpu::Device& device = gpu.device();
    format_ = usable(device, gpu::PixelFormat::Rgba16F) && !g_forceRgba8
                  ? gpu::PixelFormat::Rgba16F
                  : (usable(device, gpu::PixelFormat::Rgba8) ? gpu::PixelFormat::Rgba8 : gpu::PixelFormat::None);
    bool ok = format_ != gpu::PixelFormat::None;
    if (ok) {
        isGl_ = gpu.is_gl();
        const gpu::GeneratedShader descs[int(Prog::Count)] = {
            probe_face_shader_desc, probe_down_shader_desc,    probe_oct_cube_shader_desc, probe_oct_ggx_shader_desc,
            probe_sh_shader_desc,   probe_sh_cube_shader_desc, probe_blit_shader_desc};
        static const char* const names[int(Prog::Count)] = {
            "probe_face", "probe_down", "probe_oct_cube", "probe_oct_ggx", "probe_sh", "probe_sh_cube", "probe_blit"};
        for (int p = 0; p < int(Prog::Count); ++p) {
            shaders_[p] = make_shader(device, gpu::generated_shader_desc(descs[p]), names[p]);
            ok = ok && device.state(shaders_[p]) == gpu::ResourceState::Valid;
        }
    }
    if (ok) {
        gpu::SamplerDesc sd{};
        sd.minFilter = gpu::Filter::Linear;
        sd.magFilter = gpu::Filter::Linear;
        sd.mipmapFilter = gpu::Filter::Linear;
        sd.wrapU = sd.wrapV = sd.wrapW = gpu::Wrap::ClampToEdge;
        sd.label = "probe-sampler";
        sampler_ = device.make_sampler(sd);
        ok = sampler_.id && device.state(sampler_) == gpu::ResourceState::Valid;
    }
    if (ok) {
        for (int p = 0; p < int(Prog::Count); ++p) {
            gpu::PipelineDesc d{};
            d.shader = shaders_[p];
            d.layout.attrs[ATTR_probe_face_pos].format =
                gpu::VertexFormat::Float2;  // `pos`, location 0 in every program
            d.depth.compare = gpu::CompareFunc::Always;
            d.depth.writeEnabled = false;
            d.depth.pixelFormat = gpu::PixelFormat::None;
            d.colorCount = 1;
            d.colors[0].pixelFormat = format_;
            d.sampleCount = 1;
            d.faceWinding = gpu::FaceWinding::Ccw;
            d.label = "probe";
            pipelines_[p] = device.make_pipeline(d);
            ok = ok && device.state(pipelines_[p]) == gpu::ResourceState::Valid;
        }
    }
    if (!ok) {
        release();
        state_ = -1;
        FA_ERROR("render", "Reflection probes cannot be drawn: their shaders or images could not be made for this "
                           "graphics backend (see the "
                           "sokol log lines above). The scene keeps lighting itself from the sky. Hint: update the "
                           "graphics driver (Mesa: try "
                           "LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

bool ProbeGpu::make_atlas(Atlas& a, int size, const char* label, int height) {
    destroy_atlas(a);
    if (state_ <= 0 || !gpu_) return false;  // ready(gpu) first
    gpu::Device& device = gpu_->device();
    if (height <= 0) height = size;
    gpu::ImageDesc d{};
    d.usage.colorAttachment = true;
    d.width = size;
    d.height = height;
    d.pixelFormat = format_;
    d.label = label;
    a.image = device.make_image(d);
    if (!valid(device, a.image)) {
        destroy_atlas(a);
        return false;
    }
    a.tex = texture_view(device, a.image, label);
    a.att = attachment_view(device, a.image, 0, label);
    a.size = size;
    a.height = height;
    if (!valid(device, a.tex) || !valid(device, a.att)) {
        destroy_atlas(a);
        return false;
    }
    // Black, so that no texel is ever garbage (a tile that is not written yet reads as 0).
    gpu::PassDesc pd;
    pd.label = "probe-atlas-clear";
    pd.color = a.att;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::Clear;
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu_->commands();
    cmd.begin_pass(pd);
    cmd.end_pass();
    return true;
}

void ProbeGpu::destroy_atlas(Atlas& a) {
    if (gpu_ && gpu_->has_device()) {
        gpu::Device& device = gpu_->device();
        if (a.att.id) device.destroy_view(a.att);
        if (a.tex.id) device.destroy_view(a.tex);
        if (a.image.id) device.destroy_image(a.image);
    }
    a = Atlas{};
}

void ProbeGpu::destroy_scratch(Scratch& s) {
    gpu::Device* device = gpu_ && gpu_->has_device() ? &gpu_->device() : nullptr;
    for (int i = 0; i < kProbeMaxLevels; ++i) {
        for (gpu::View& v : s.att[i]) {
            if (v.id && device) device->destroy_view(v);
            v = {};
        }
        if (s.tex[i].id && device) device->destroy_view(s.tex[i]);
        s.tex[i] = {};
        if (s.image[i].id && device) device->destroy_image(s.image[i]);
        s.image[i] = {};
    }
    s.resolution = s.images = 0;
}

bool ProbeGpu::prepare_scratch(int slot, int resolution) {
    if (state_ <= 0 || !gpu_ || slot < 0 || slot >= kProbeScratchSlots) return false;  // ready(gpu) first
    gpu::Device& device = gpu_->device();
    Scratch& s = scratch_[slot];
    if (s.resolution == resolution) return true;
    destroy_scratch(s);
    const int images = std::max(probe_levels(resolution), probe_sh_source(resolution) + 1);
    bool ok = images <= kProbeMaxLevels;
    for (int i = 0; ok && i < images; ++i) {
        gpu::ImageDesc d{};
        d.type = gpu::ImageType::Cube;
        d.numSlices = 6;
        d.usage.colorAttachment = true;
        d.width = d.height = resolution >> i;
        d.numMipmaps = 1;
        d.pixelFormat = format_;
        d.label = "probe-scratch";
        s.image[i] = device.make_image(d);  // the cube fixes of render::make_cube_image are the device's
        s.tex[i] = texture_view(device, s.image[i], "probe-scratch");
        ok = valid(device, s.image[i]) && valid(device, s.tex[i]);
        for (int f = 0; ok && f < 6; ++f) {
            s.att[i][f] = attachment_view(device, s.image[i], f, "probe-scratch");
            ok = valid(device, s.att[i][f]);
        }
    }
    if (!ok) {
        destroy_scratch(s);
        return false;
    }
    s.resolution = resolution;
    s.images = images;
    return true;
}

void ProbeGpu::pass_cube(Gpu& gpu, Prog prog, gpu::View att, gpu::View source, int face, const float camera[12],
                         int* drawCalls) {
    gpu::PassDesc pd;
    pd.label = prog == Prog::Face ? "probe-face" : "probe-down";
    pd.color = att;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;  // every pixel is drawn
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    cmd.set_pipeline(pipelines_[int(prog)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_cube] = source;  // the same slot (0) as the 2D picture of the Face program
    b.samplers[SMP_probe_probe_smp] = sampler_;
    cmd.set_bindings(b);
    const EnvFace f = env_face(face, isGl_);
    probe_probe_vs_params_t vu{};
    for (int i = 0; i < 3; ++i) {
        vu.fwd[i] = f.fwd[i];
        vu.right[i] = f.right[i];
        vu.up[i] = f.up[i];
    }
    cmd.set_uniforms(UB_probe_probe_vs_params, gpu::Range{&vu, sizeof(vu)});
    if (prog == Prog::Face) {
        probe_probe_face_params_t fu{};
        std::memcpy(fu.cam_right, camera, 3 * sizeof(float));
        std::memcpy(fu.cam_up, camera + 4, 3 * sizeof(float));
        std::memcpy(fu.cam_fwd, camera + 8, 3 * sizeof(float));
        cmd.set_uniforms(UB_probe_probe_face_params, gpu::Range{&fu, sizeof(fu)});
    }
    cmd.draw(0, 3, 1);
    cmd.end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::pass_rect(Gpu& gpu, Atlas& atlas, Prog prog, int x, int y, int w, int h, gpu::View source,
                         gpu::Sampler sampler, const float region[4], const float p[4], const float q[4],
                         const float* blit, int* drawCalls) {
    gpu::PassDesc pd;
    pd.label = "probe-atlas";
    pd.color = atlas.att;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::Load;  // the other tiles stay
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    // The rectangle in MEMORY rows: OpenGL counts its window from the bottom, which is where a render target's row 0 is.
    cmd.set_viewport(x, y, w, h, !isGl_);
    cmd.set_scissor(x, y, w, h, !isGl_);
    cmd.set_pipeline(pipelines_[int(prog)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_cube] = source;  // a cube, or the 2D image of Blit: slot 0 either way
    b.samplers[SMP_probe_probe_smp] = sampler;
    cmd.set_bindings(b);
    if (prog == Prog::Blit) {
        probe_probe_blit_params_t u{};
        u.dst[0] = float(x);
        u.dst[1] = float(y);
        std::memcpy(u.src, blit, 4 * sizeof(float));
        cmd.set_uniforms(UB_probe_probe_blit_params, gpu::Range{&u, sizeof(u)});
    } else {
        probe_probe_params_t u{};
        std::memcpy(u.region, region, 4 * sizeof(float));
        std::memcpy(u.p, p, 4 * sizeof(float));
        std::memcpy(u.q, q, 4 * sizeof(float));
        cmd.set_uniforms(UB_probe_probe_params, gpu::Range{&u, sizeof(u)});
    }
    cmd.draw(0, 3, 1);
    cmd.end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::face_to_cube(Gpu& gpu, int slot, int face, gpu::bridged::View picture, int* drawCalls) {
    Scratch& s = scratch_[slot];
    const ProbeFace c = probe_face(face);
    const float camera[12] = {c.right.x, c.right.y, c.right.z, 0.0f,    c.up.x,  c.up.y,
                              c.up.z,    0.0f,      c.fwd.x,   c.fwd.y, c.fwd.z, 0.0f};
    pass_cube(gpu, Prog::Face, s.att[0][face], picture, face, camera, drawCalls);
}

void ProbeGpu::filter(Gpu& gpu, Atlas& atlas, int slot, const ProbeTile& tile, float gain, int* drawCalls) {
    Scratch& s = scratch_[slot];
    const ProbeLayout lay = probe_layout(tile.resolution);
    for (int i = 1; i < s.images; ++i)
        for (int f = 0; f < 6; ++f) pass_cube(gpu, Prog::Down, s.att[i][f], s.tex[i - 1], f, nullptr, drawCalls);
    const float rgba8 = this->rgba8() ? 1.0f : 0.0f;
    for (int k = 0; k < lay.levels; ++k) {
        const int x = tile.x + lay.levelX[k], y = tile.y + lay.levelY[k], size = lay.levelSize[k];
        const float region[4] = {float(x), float(y), float(size), float(kProbeBorder)};
        const int rect = size + 2 * kProbeBorder;
        if (k == 0) {
            const float p[4] = {0.0f, 0.0f, 0.0f, gain}, q[4] = {0.0f, rgba8, 0.0f, 0.0f};
            pass_rect(gpu, atlas, Prog::OctCube, x, y, rect, rect, s.tex[0], sampler_, region, p, q, nullptr,
                      drawCalls);
        } else {
            const float p[4] = {probe_level_roughness(lay.levels, k), k <= 2 ? 32.0f : 64.0f, 0.0f, gain};
            const float q[4] = {0.0f, rgba8, 0.0f, 0.0f};
            pass_rect(gpu, atlas, Prog::OctGgx, x, y, rect, rect, s.tex[k], sampler_, region, p, q, nullptr, drawCalls);
        }
    }
    const int shX = tile.x, shY = tile.y + lay.shY;
    const float region[4] = {float(shX), float(shY), 9.0f, 0.0f};
    const float p[4] = {0.0f, 0.0f, 0.0f, gain}, q[4] = {0.0f, rgba8, 0.0f, 0.0f};
    pass_rect(gpu, atlas, Prog::Sh, shX, shY, kProbeShCoefficients, 1, s.tex[probe_sh_source(tile.resolution)],
              sampler_, region, p, q, nullptr, drawCalls);
}

void ProbeGpu::write_sky(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, gpu::bridged::View envCube,
                         gpu::bridged::Sampler envSampler, bool envRgba8, int* drawCalls) {
    const ProbeLayout lay = probe_layout(tile.resolution);
    const float rgba8 = this->rgba8() ? 1.0f : 0.0f;
    for (int k = 0; k < lay.levels; ++k) {
        const int x = tile.x + lay.levelX[k], y = tile.y + lay.levelY[k], size = lay.levelSize[k];
        const float region[4] = {float(x), float(y), float(size), float(kProbeBorder)};
        const int rect = size + 2 * kProbeBorder;
        const float p[4] = {0.0f, 0.0f, 0.0f, 1.0f}, q[4] = {float(k), rgba8, 0.0f, 0.0f};  // lod k of the sky's cube
        pass_rect(gpu, atlas, Prog::OctCube, x, y, rect, rect, envCube, envSampler, region, p, q, nullptr, drawCalls);
    }
    const int shX = tile.x, shY = tile.y + lay.shY;
    const float region[4] = {float(shX), float(shY), 9.0f, 0.0f};
    const float p[4] = {float(kEnvShMip), 0.0f, 0.0f, 1.0f}, q[4] = {0.0f, rgba8, 0.0f, envRgba8 ? 1.0f : 0.0f};
    pass_rect(gpu, atlas, Prog::ShCube, shX, shY, kProbeShCoefficients, 1, envCube, envSampler, region, p, q, nullptr,
              drawCalls);
}

bool ProbeGpu::upload(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, const ImageF& page, const float sh[9][3],
                      float gain, int* drawCalls) {
    const int pw = probe_page_width(tile.resolution), ph = probe_page_height(tile.resolution);
    if (page.width != pw || page.height != ph || page.channels < 3 ||
        page.data.size() < std::size_t(pw) * std::size_t(ph) * std::size_t(page.channels))
        return false;
    const ProbeLayout lay = probe_layout(tile.resolution);
    const bool bytes = rgba8();
    std::vector<std::uint16_t> half;
    std::vector<std::uint8_t> byte;
    for (int y = 0; y < ph; ++y)
        for (int x = 0; x < pw; ++x) {
            const float* px = page.at(x, y);
            for (int c = 0; c < 4; ++c) {
                const float v = c < 3 ? px[c] * gain : 1.0f;
                if (bytes)
                    byte.push_back(std::uint8_t(std::clamp(v, 0.0f, 1.0f) * 255.0f + 0.5f));
                else
                    half.push_back(signed_half_bits(v));
            }
        }
    std::vector<std::uint16_t> shHalf;
    std::vector<std::uint8_t> shByte;
    for (int i = 0; i < kProbeShCoefficients; ++i)
        for (int c = 0; c < 4; ++c) {
            const float v = c < 3 ? sh[i][c] * gain : 1.0f;
            if (bytes)
                shByte.push_back(std::uint8_t(c < 3 ? std::clamp(v * 0.25f, -1.0f, 1.0f) * 127.0f + 128.5f
                                                    : 255.0f));  // 0 is exactly byte 128
            else
                shHalf.push_back(signed_half_bits(v));
        }
    Upload pageImage(gpu.device()), shImage(gpu.device());
    if (!pageImage.make(pw, ph, format_,
                        bytes ? static_cast<const void*>(byte.data()) : static_cast<const void*>(half.data()),
                        bytes ? byte.size() : half.size() * 2, "probe-page") ||
        !shImage.make(kProbeShCoefficients, 1, format_,
                      bytes ? static_cast<const void*>(shByte.data()) : static_cast<const void*>(shHalf.data()),
                      bytes ? shByte.size() : shHalf.size() * 2, "probe-sh"))
        return false;
    const float none[4] = {};
    const float pageBlit[4] = {0.0f, 0.0f, float(ph), 0.0f};
    pass_rect(gpu, atlas, Prog::Blit, tile.x, tile.y, pw, ph, pageImage.view, sampler_, none, none, none, pageBlit,
              drawCalls);
    const float shBlit[4] = {0.0f, 0.0f, 1.0f, 0.0f};
    pass_rect(gpu, atlas, Prog::Blit, tile.x, tile.y + lay.shY, kProbeShCoefficients, 1, shImage.view, sampler_, none,
              none, none, shBlit, drawCalls);
    return true;
}

bool ProbeGpu::read_region_begin(Gpu& gpu, Atlas& atlas, int x, int y, int w, int h, gpu::Image& scratch,
                                 int* drawCalls) {
    scratch = {};
    gpu::Device& device = gpu.device();
    gpu::ImageDesc d{};
    d.usage.colorAttachment = true;
    d.width = w;
    d.height = h;
    d.pixelFormat = format_;
    d.label = "probe-read";
    scratch = device.make_image(d);
    gpu::View att = valid(device, scratch) ? attachment_view(device, scratch, 0, "probe-read") : gpu::View{};
    if (!valid(device, att)) {
        if (att.id) device.destroy_view(att);
        if (scratch.id) device.destroy_image(scratch);
        scratch = {};
        return false;
    }
    // A pass of its own into the scratch image (not the atlas): the same blit program, the other target.
    gpu::PassDesc pd;
    pd.label = "probe-read";
    pd.color = att;
    pd.format = gpu::TargetFormat{format_, gpu::PixelFormat::None, 1};
    pd.colorLoad = gpu::LoadAction::DontCare;
    pd.colorStore = gpu::StoreAction::Store;
    gpu::CommandList& cmd = gpu.commands();
    cmd.begin_pass(pd);
    cmd.set_viewport(0, 0, w, h, !isGl_);
    cmd.set_scissor(0, 0, w, h, !isGl_);
    cmd.set_pipeline(pipelines_[int(Prog::Blit)]);
    gpu::Bindings b{};
    b.vertexBuffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_tex] = atlas.tex;
    b.samplers[SMP_probe_probe_smp] = sampler_;
    cmd.set_bindings(b);
    probe_probe_blit_params_t u{};
    u.dst[0] = 0.0f;
    u.dst[1] = 0.0f;
    // OpenGL's read-back turns the rows over: the rows are written upside down so that the read-back's first row is the rectangle's first.
    u.src[0] = float(x);
    u.src[1] = float(y);
    u.src[2] = float(h);
    u.src[3] = isGl_ ? 1.0f : 0.0f;
    cmd.set_uniforms(UB_probe_probe_blit_params, gpu::Range{&u, sizeof(u)});
    cmd.draw(0, 3, 1);
    cmd.end_pass();
    if (drawCalls) ++*drawCalls;
    device.destroy_view(att);
    return true;
}

bool ProbeGpu::read_region_end(gpu::Device& device, gpu::Image scratch, int w, int h, bool rgba8,
                               std::vector<float>& out, std::string* error) {
    bool ok;
    std::string why;
    if (rgba8) {
        std::vector<std::uint8_t> bytes;
        const Result<void> read = device.read_image_rgba8(scratch, w, h, bytes);
        ok = bool(read);
        if (!ok) why = read.error().message;
        out.resize(bytes.size());
        for (std::size_t i = 0; ok && i < bytes.size(); ++i) out[i] = float(bytes[i]) / 255.0f;
    } else {
        const Result<void> read = device.read_image_rgba16f(scratch, w, h, out);
        ok = bool(read);
        if (!ok) why = read.error().message;
    }
    if (!ok && error) *error = why;
    device.destroy_image(scratch);
    return ok;
}

void ProbeGpu::release() {
    release_gi();
    for (Scratch& s : scratch_) destroy_scratch(s);
    if (gpu_ && gpu_->has_device()) {
        gpu::Device& device = gpu_->device();
        for (gpu::Pipeline& p : pipelines_) {
            if (p.id) device.destroy_pipeline(p);
            p = {};
        }
        for (gpu::Shader& s : shaders_) {
            if (s.id) gpu_->destroy_shader(s);
            s = {};
        }
        if (sampler_.id) device.destroy_sampler(sampler_);
    }
    sampler_ = {};
    state_ = 0;
}

}  // namespace fa::render
