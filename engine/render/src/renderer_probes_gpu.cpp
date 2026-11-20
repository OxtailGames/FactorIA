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

bool usable(sg_pixel_format f) {
    const sg_pixelformat_info i = sg_query_pixelformat(f);
    return i.sample && i.filter && i.render;
}
bool valid(sg_image i) { return i.id && sg_query_image_state(i) == SG_RESOURCESTATE_VALID; }
bool valid(sg_view v) { return v.id && sg_query_view_state(v) == SG_RESOURCESTATE_VALID; }

sg_view texture_view(sg_image image, const char* label) {
    sg_view_desc v{};
    v.texture.image = image;
    v.label = label;
    return sg_make_view(&v);
}
sg_view attachment_view(sg_image image, int slice, const char* label) {
    sg_view_desc v{};
    v.color_attachment.image = image;
    v.color_attachment.slice = slice;
    v.label = label;
    return sg_make_view(&v);
}

// A half float with its sign (render_internal.h float_to_half_bits is for values that are never negative).
std::uint16_t signed_half_bits(float f) {
    if (!std::isfinite(f)) return 0;
    return std::uint16_t((f < 0.0f ? 0x8000u : 0u) | float_to_half_bits(std::fabs(f)));
}

// A small immutable image with data and its texture view, for a baked page on its way into the atlas.
struct Upload {
    sg_image image{};
    sg_view view{};
    bool make(int w, int h, sg_pixel_format format, const void* data, std::size_t bytes, const char* label) {
        sg_image_desc d{};
        d.width = w;
        d.height = h;
        d.pixel_format = format;
        d.data.mip_levels[0] = {data, bytes};
        d.label = label;
        image = make_image(d);
        if (!valid(image)) return false;
        view = texture_view(image, label);
        return valid(view);
    }
    ~Upload() {
        if (view.id) sg_destroy_view(view);
        if (image.id) sg_destroy_image(image);
    }
};

}  // namespace

void ProbeGpu::force_rgba8_for_tests(bool force) { g_forceRgba8 = force; }

bool ProbeGpu::ready() {
    if (state_ != 0) return state_ > 0;
    format_ = usable(SG_PIXELFORMAT_RGBA16F) && !g_forceRgba8
                  ? SG_PIXELFORMAT_RGBA16F
                  : (usable(SG_PIXELFORMAT_RGBA8) ? SG_PIXELFORMAT_RGBA8 : SG_PIXELFORMAT_NONE);
    bool ok = format_ != SG_PIXELFORMAT_NONE;
    if (ok) {
        const sg_backend backend = sg_query_backend();
        isGl_ = backend == SG_BACKEND_GLCORE || backend == SG_BACKEND_GLES3;
        const sg_shader_desc* descs[int(Prog::Count)] = {
            probe_face_shader_desc(backend),    probe_down_shader_desc(backend),   probe_oct_cube_shader_desc(backend),
            probe_oct_ggx_shader_desc(backend), probe_sh_shader_desc(backend),     probe_sh_cube_shader_desc(backend),
            probe_blit_shader_desc(backend)};
        static const char* const names[int(Prog::Count)] = {"probe_face", "probe_down", "probe_oct_cube", "probe_oct_ggx",
                                                              "probe_sh",   "probe_sh_cube", "probe_blit"};
        for (int p = 0; p < int(Prog::Count); ++p) {
            shaders_[p] = make_shader(descs[p], names[p]);
            ok = ok && sg_query_shader_state(shaders_[p]) == SG_RESOURCESTATE_VALID;
        }
    }
    if (ok) {
        sg_sampler_desc sd{};
        sd.min_filter = SG_FILTER_LINEAR;
        sd.mag_filter = SG_FILTER_LINEAR;
        sd.mipmap_filter = SG_FILTER_LINEAR;
        sd.wrap_u = sd.wrap_v = sd.wrap_w = SG_WRAP_CLAMP_TO_EDGE;
        sd.label = "probe-sampler";
        sampler_ = sg_make_sampler(&sd);
        ok = sampler_.id && sg_query_sampler_state(sampler_) == SG_RESOURCESTATE_VALID;
    }
    if (ok) {
        for (int p = 0; p < int(Prog::Count); ++p) {
            sg_pipeline_desc d{};
            d.shader = shaders_[p];
            d.layout.attrs[ATTR_probe_face_pos].format = SG_VERTEXFORMAT_FLOAT2;  // `pos`, location 0 in every program
            d.depth.compare = SG_COMPAREFUNC_ALWAYS;
            d.depth.write_enabled = false;
            d.depth.pixel_format = SG_PIXELFORMAT_NONE;
            d.colors[0].pixel_format = format_;
            d.sample_count = 1;
            d.face_winding = SG_FACEWINDING_CCW;
            d.label = "probe";
            pipelines_[p] = sg_make_pipeline(&d);
            ok = ok && sg_query_pipeline_state(pipelines_[p]) == SG_RESOURCESTATE_VALID;
        }
    }
    if (!ok) {
        release();
        state_ = -1;
        FA_ERROR("render",
                 "Reflection probes cannot be drawn: their shaders or images could not be made for this graphics backend (see the "
                 "sokol log lines above). The scene keeps lighting itself from the sky. Hint: update the graphics driver (Mesa: try "
                 "LIBGL_ALWAYS_SOFTWARE=1).");
        return false;
    }
    state_ = 1;
    return true;
}

bool ProbeGpu::make_atlas(Atlas& a, int size, const char* label) {
    destroy_atlas(a);
    if (!ready()) return false;
    sg_image_desc d{};
    d.usage.color_attachment = true;
    d.width = size;
    d.height = size;
    d.pixel_format = format_;
    d.label = label;
    a.image = make_image(d);
    if (!valid(a.image)) {
        destroy_atlas(a);
        return false;
    }
    a.tex = texture_view(a.image, label);
    a.att = attachment_view(a.image, 0, label);
    a.size = size;
    if (!valid(a.tex) || !valid(a.att)) {
        destroy_atlas(a);
        return false;
    }
    // Black, so that no texel is ever garbage (a tile that is not written yet reads as 0).
    PassDesc pd;
    pd.label = "probe-atlas-clear";
    pd.color = a.att;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_CLEAR;
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    Gpu::end_pass();
    return true;
}

void ProbeGpu::destroy_atlas(Atlas& a) {
    if (a.att.id) sg_destroy_view(a.att);
    if (a.tex.id) sg_destroy_view(a.tex);
    if (a.image.id) sg_destroy_image(a.image);
    a = Atlas{};
}

void ProbeGpu::destroy_scratch(Scratch& s) {
    for (int i = 0; i < kProbeMaxLevels; ++i) {
        for (sg_view& v : s.att[i]) {
            if (v.id) sg_destroy_view(v);
            v = {};
        }
        if (s.tex[i].id) sg_destroy_view(s.tex[i]);
        s.tex[i] = {};
        if (s.image[i].id) sg_destroy_image(s.image[i]);
        s.image[i] = {};
    }
    s.resolution = s.images = 0;
}

bool ProbeGpu::prepare_scratch(int slot, int resolution) {
    if (!ready() || slot < 0 || slot >= kProbeScratchSlots) return false;
    Scratch& s = scratch_[slot];
    if (s.resolution == resolution) return true;
    destroy_scratch(s);
    const int images = std::max(probe_levels(resolution), probe_sh_source(resolution) + 1);
    bool ok = images <= kProbeMaxLevels;
    for (int i = 0; ok && i < images; ++i) {
        sg_image_desc d{};
        d.type = SG_IMAGETYPE_CUBE;
        d.usage.color_attachment = true;
        d.width = d.height = resolution >> i;
        d.num_mipmaps = 1;
        d.pixel_format = format_;
        d.label = "probe-scratch";
        s.image[i] = make_cube_image(d);
        s.tex[i] = texture_view(s.image[i], "probe-scratch");
        ok = valid(s.image[i]) && valid(s.tex[i]);
        for (int f = 0; ok && f < 6; ++f) {
            s.att[i][f] = attachment_view(s.image[i], f, "probe-scratch");
            ok = valid(s.att[i][f]);
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

void ProbeGpu::pass_cube(Gpu& gpu, Prog prog, sg_view att, sg_view source, int face, const float camera[12], int* drawCalls) {
    PassDesc pd;
    pd.label = prog == Prog::Face ? "probe-face" : "probe-down";
    pd.color = att;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;  // every pixel is drawn
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_pipeline(pipelines_[int(prog)]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_cube] = source;  // the same slot (0) as the 2D picture of the Face program
    b.samplers[SMP_probe_probe_smp] = sampler_;
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
    if (prog == Prog::Face) {
        probe_probe_face_params_t fu{};
        std::memcpy(fu.cam_right, camera, 3 * sizeof(float));
        std::memcpy(fu.cam_up, camera + 4, 3 * sizeof(float));
        std::memcpy(fu.cam_fwd, camera + 8, 3 * sizeof(float));
        sg_range fr{&fu, sizeof(fu)};
        sg_apply_uniforms(UB_probe_probe_face_params, &fr);
    }
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::pass_rect(Gpu& gpu, Atlas& atlas, Prog prog, int x, int y, int w, int h, sg_view source, sg_sampler sampler,
                         const float region[4], const float p[4], const float q[4], const float* blit, int* drawCalls) {
    PassDesc pd;
    pd.label = "probe-atlas";
    pd.color = atlas.att;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_LOAD;  // the other tiles stay
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    // The rectangle in MEMORY rows: OpenGL counts its window from the bottom, which is where a render target's row 0 is.
    sg_apply_viewport(x, y, w, h, !isGl_);
    sg_apply_scissor_rect(x, y, w, h, !isGl_);
    sg_apply_pipeline(pipelines_[int(prog)]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_cube] = source;  // a cube, or the 2D image of Blit: slot 0 either way
    b.samplers[SMP_probe_probe_smp] = sampler;
    sg_apply_bindings(&b);
    if (prog == Prog::Blit) {
        probe_probe_blit_params_t u{};
        u.dst[0] = float(x);
        u.dst[1] = float(y);
        std::memcpy(u.src, blit, 4 * sizeof(float));
        sg_range r{&u, sizeof(u)};
        sg_apply_uniforms(UB_probe_probe_blit_params, &r);
    } else {
        probe_probe_params_t u{};
        std::memcpy(u.region, region, 4 * sizeof(float));
        std::memcpy(u.p, p, 4 * sizeof(float));
        std::memcpy(u.q, q, 4 * sizeof(float));
        sg_range r{&u, sizeof(u)};
        sg_apply_uniforms(UB_probe_probe_params, &r);
    }
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
}

void ProbeGpu::face_to_cube(Gpu& gpu, int slot, int face, sg_view picture, int* drawCalls) {
    Scratch& s = scratch_[slot];
    const ProbeFace c = probe_face(face);
    const float camera[12] = {c.right.x, c.right.y, c.right.z, 0.0f, c.up.x,  c.up.y,  c.up.z,  0.0f,
                              c.fwd.x,   c.fwd.y,   c.fwd.z,   0.0f};
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
            pass_rect(gpu, atlas, Prog::OctCube, x, y, rect, rect, s.tex[0], sampler_, region, p, q, nullptr, drawCalls);
        } else {
            const float p[4] = {probe_level_roughness(lay.levels, k), k <= 2 ? 32.0f : 64.0f, 0.0f, gain};
            const float q[4] = {0.0f, rgba8, 0.0f, 0.0f};
            pass_rect(gpu, atlas, Prog::OctGgx, x, y, rect, rect, s.tex[k], sampler_, region, p, q, nullptr, drawCalls);
        }
    }
    const int shX = tile.x, shY = tile.y + lay.shY;
    const float region[4] = {float(shX), float(shY), 9.0f, 0.0f};
    const float p[4] = {0.0f, 0.0f, 0.0f, gain}, q[4] = {0.0f, rgba8, 0.0f, 0.0f};
    pass_rect(gpu, atlas, Prog::Sh, shX, shY, kProbeShCoefficients, 1, s.tex[probe_sh_source(tile.resolution)], sampler_, region, p,
              q, nullptr, drawCalls);
}

void ProbeGpu::write_sky(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, sg_view envCube, sg_sampler envSampler, bool envRgba8,
                         int* drawCalls) {
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
    pass_rect(gpu, atlas, Prog::ShCube, shX, shY, kProbeShCoefficients, 1, envCube, envSampler, region, p, q, nullptr, drawCalls);
}

bool ProbeGpu::upload(Gpu& gpu, Atlas& atlas, const ProbeTile& tile, const ImageF& page, const float sh[9][3], float gain,
                      int* drawCalls) {
    const int pw = probe_page_width(tile.resolution), ph = probe_page_height(tile.resolution);
    if (page.width != pw || page.height != ph || page.channels < 3 || page.data.size() < std::size_t(pw) * std::size_t(ph) * std::size_t(page.channels))
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
                shByte.push_back(std::uint8_t((c < 3 ? std::clamp(v * 0.25f, -1.0f, 1.0f) * 0.5f + 0.5f : 1.0f) * 255.0f + 0.5f));
            else
                shHalf.push_back(signed_half_bits(v));
        }
    Upload pageImage, shImage;
    if (!pageImage.make(pw, ph, format_, bytes ? static_cast<const void*>(byte.data()) : static_cast<const void*>(half.data()),
                        bytes ? byte.size() : half.size() * 2, "probe-page") ||
        !shImage.make(kProbeShCoefficients, 1, format_, bytes ? static_cast<const void*>(shByte.data()) : static_cast<const void*>(shHalf.data()),
                      bytes ? shByte.size() : shHalf.size() * 2, "probe-sh"))
        return false;
    const float none[4] = {};
    const float pageBlit[4] = {0.0f, 0.0f, float(ph), 0.0f};
    pass_rect(gpu, atlas, Prog::Blit, tile.x, tile.y, pw, ph, pageImage.view, sampler_, none, none, none, pageBlit, drawCalls);
    const float shBlit[4] = {0.0f, 0.0f, 1.0f, 0.0f};
    pass_rect(gpu, atlas, Prog::Blit, tile.x, tile.y + lay.shY, kProbeShCoefficients, 1, shImage.view, sampler_, none, none, none,
              shBlit, drawCalls);
    return true;
}

bool ProbeGpu::read_region_begin(Gpu& gpu, Atlas& atlas, int x, int y, int w, int h, sg_image& scratch, int* drawCalls) {
    scratch = {};
    sg_image_desc d{};
    d.usage.color_attachment = true;
    d.width = w;
    d.height = h;
    d.pixel_format = format_;
    d.label = "probe-read";
    scratch = make_image(d);
    sg_view att = valid(scratch) ? attachment_view(scratch, 0, "probe-read") : sg_view{};
    if (!valid(att)) {
        if (att.id) sg_destroy_view(att);
        if (scratch.id) sg_destroy_image(scratch);
        scratch = {};
        return false;
    }
    // A pass of its own into the scratch image (not the atlas): the same blit program, the other target.
    PassDesc pd;
    pd.label = "probe-read";
    pd.color = att;
    pd.format = TargetFormat{format_, SG_PIXELFORMAT_NONE, 1};
    pd.colorLoad = SG_LOADACTION_DONTCARE;
    pd.colorStore = SG_STOREACTION_STORE;
    Gpu::begin_pass(pd);
    sg_apply_viewport(0, 0, w, h, !isGl_);
    sg_apply_scissor_rect(0, 0, w, h, !isGl_);
    sg_apply_pipeline(pipelines_[int(Prog::Blit)]);
    sg_bindings b{};
    b.vertex_buffers[0] = gpu.fullscreen_triangle();
    b.views[VIEW_probe_probe_tex] = atlas.tex;
    b.samplers[SMP_probe_probe_smp] = sampler_;
    sg_apply_bindings(&b);
    probe_probe_blit_params_t u{};
    u.dst[0] = 0.0f;
    u.dst[1] = 0.0f;
    // OpenGL's read-back turns the rows over: the rows are written upside down so that the read-back's first row is the rectangle's first.
    u.src[0] = float(x);
    u.src[1] = float(y);
    u.src[2] = float(h);
    u.src[3] = isGl_ ? 1.0f : 0.0f;
    sg_range r{&u, sizeof(u)};
    sg_apply_uniforms(UB_probe_probe_blit_params, &r);
    sg_draw(0, 3, 1);
    Gpu::end_pass();
    if (drawCalls) ++*drawCalls;
    sg_destroy_view(att);
    return true;
}

bool ProbeGpu::read_region_end(sg_image scratch, int w, int h, bool rgba8, std::vector<float>& out, std::string* error) {
    bool ok;
    if (rgba8) {
        std::vector<std::uint8_t> bytes;
        ok = readback_rgba8(scratch, w, h, bytes, error);
        out.resize(bytes.size());
        for (std::size_t i = 0; ok && i < bytes.size(); ++i) out[i] = float(bytes[i]) / 255.0f;
    } else {
        ok = readback_rgba16f(scratch, w, h, out, error);
    }
    sg_destroy_image(scratch);
    return ok;
}

void ProbeGpu::release() {
    for (Scratch& s : scratch_) destroy_scratch(s);
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
    state_ = 0;
}

}  // namespace fa::render
