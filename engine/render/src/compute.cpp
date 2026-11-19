// Compute materials at run time (fa/render/compute.h): storage buffers, a dispatch and the read back. The material's twin
// (custom_shader.cpp) carries the std430 layout the tooling made; this file only packs JSON into it and runs the program.
#include "fa/render/compute.h"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#include "fa/core/log.h"
#include "fa/core/strings.h"
#include "compute_internal.h"
#include "hdr_encode.h"
#include "render_features.h"
#include "render_internal.h"

namespace fa {

using render::MaterialAsset;
using render::MaterialBufferDef;
using render::MaterialBufferFieldDef;

struct Compute::State {
    struct Buf {
        int id = 0;
        std::string material, name;  // the compute material and the buffer of it this one was made for
        std::uint32_t stride = 0;
        std::vector<MaterialBufferFieldDef> fields;
        std::uint64_t count = 0, bytes = 0;
        sg_buffer buffer{};
        sg_view view{};
    };
    // The GPU objects of one storage image: the image, the view a compute shader writes and reads it through, and the view a
    // material samples it through (empty when the GPU cannot sample the format).
    struct ImgGpu {
        sg_image image{};
        sg_view storage{}, sampled{};
    };
    struct Img {
        int id = 0;
        std::string material, name;  // the compute material and the image of it this one was made for
        sg_pixel_format format = SG_PIXELFORMAT_RGBA8;
        bool readWrite = false;
        int width = 0, height = 0;
        std::uint64_t bytes = 0;
        ImgGpu gpu;
        // What a material's texture value "compute:<id>" resolves to: one object for the life of the image (a resize remakes the
        // GPU image under it), so a pointer taken for a frame stays valid for the frame.
        std::unique_ptr<render::TextureAsset> tex;
    };
    render::Gpu* gpu = nullptr;
    render::Assets* assets = nullptr;
    std::map<int, Buf> bufs;
    std::map<int, Img> imgs;
    // The texture objects of destroyed images, pointed at the white texture: a pointer an older frame kept never dangles. The
    // oldest go first once there are more than kMaxRetiredImageTextures.
    std::vector<std::unique_ptr<render::TextureAsset>> retired;
    int nextId = 1;
    int nextImageId = 1;
    std::uint64_t totalBytes = 0;
    std::uint64_t imageBytes = 0;
    std::uint64_t lastReadBytes =
        0;                     // the bytes the last read_image took from the GPU (Compute::last_read_image_bytes)
    int backendOverride = -1;  // tests: a render::FeatureBackend to answer as
    int loadOverride =
        0;  // tests: 1 = answer as a GPU that can imageLoad an r32f image only, 2 = one that cannot imageLoad any

    void destroy(Buf& b) {
        if (b.view.id) sg_destroy_view(b.view);
        if (b.buffer.id) sg_destroy_buffer(b.buffer);
        totalBytes -= std::min(totalBytes, b.bytes);
    }
    static void release(ImgGpu& g) {
        if (g.sampled.id) sg_destroy_view(g.sampled);
        if (g.storage.id) sg_destroy_view(g.storage);
        if (g.image.id) sg_destroy_image(g.image);
        g = ImgGpu{};
    }
    void destroy(Img& im, bool gpuAlive) {
        if (gpuAlive) release(im.gpu);
        imageBytes -= std::min(imageBytes, im.bytes);
        if (im.tex) {  // retire the texture object: whatever kept its pointer sees the white texture, not freed memory
            render::TextureAsset* white = assets ? assets->white() : nullptr;
            im.tex->image = white ? white->image : sg_image{};
            im.tex->view = white ? white->view : sg_view{};
            im.tex->width = im.tex->height = 1;
            im.tex->format = SG_PIXELFORMAT_RGBA8;
            im.tex->bytes = 0;
            im.tex->placeholder = true;
            retired.push_back(std::move(im.tex));
            if (retired.size() > kMaxRetiredImageTextures) retired.erase(retired.begin());
        }
    }
    static constexpr std::size_t kMaxRetiredImageTextures = 256;
};

namespace {

using State = Compute::State;

// A whole number of `n` in [lo, hi] (a JSON integer, never narrowed before this check).
bool whole_number(const Json& n, std::int64_t lo, std::int64_t hi, std::int64_t& out) {
    if (n.is_number_unsigned()) {
        const std::uint64_t u = n.get<std::uint64_t>();
        if (u > std::uint64_t(hi)) return false;
        out = std::int64_t(u);
    } else if (n.is_number_integer()) {
        out = n.get<std::int64_t>();
    } else if (n.is_number_float()) {  // a script's 3 may arrive as 3.0: a float with no fraction is a whole number too
        const double d = n.get<double>();
        if (!std::isfinite(d) || std::floor(d) != d || d < double(lo) || d > double(hi)) return false;
        out = std::int64_t(d);
    } else {
        return false;
    }
    return out >= lo && out <= hi;
}

std::string example_of(const MaterialBufferFieldDef& f) {
    if (f.components == 1) return f.isInt || f.isUint ? "3" : "0.5";
    std::string s = "[";
    for (int c = 0; c < f.components; ++c) s += std::string(c ? ", " : "") + "0.5";
    return s + "]";
}

// Writes one field value (a number, or an array of `components` numbers) into the element at `dst`.
Result<void> pack_field(const MaterialBufferFieldDef& f, const Json& v, std::uint8_t* dst, const std::string& pointer) {
    const std::string kind = f.isInt    ? "an integer from -2147483648 to 2147483647"
                             : f.isUint ? "an integer from 0 to 4294967295"
                                        : "a number";
    const std::string want =
        f.components == 1 ? kind : "an array of " + std::to_string(f.components) + " numbers like " + example_of(f);
    auto bad = [&] {
        return make_error(pointer + ": " + describe_json_value(v) + " is not " + want + " (the field is a " + f.type +
                              ")",
                          "Write the field as " + example_of(f) + ".");
    };
    if (f.components > 1 && (!v.is_array() || int(v.size()) != f.components)) return bad();
    for (int c = 0; c < f.components; ++c) {
        const Json& n = f.components == 1 ? v : v[std::size_t(c)];
        if (!n.is_number()) return bad();
        std::uint8_t* at = dst + f.offset + std::size_t(c) * 4;
        if (f.isInt) {
            std::int64_t i = 0;
            if (!whole_number(n, INT32_MIN, INT32_MAX, i)) return bad();
            const std::int32_t x = std::int32_t(i);
            std::memcpy(at, &x, 4);
        } else if (f.isUint) {
            std::int64_t i = 0;
            if (!whole_number(n, 0, std::int64_t(UINT32_MAX), i)) return bad();
            const std::uint32_t x = std::uint32_t(i);
            std::memcpy(at, &x, 4);
        } else {
            const float x = n.get<float>();
            std::memcpy(at, &x, 4);
        }
    }
    return {};
}

// `elements` (an array of {field: value}) packed from index 0 of `out` (which holds at least elements.size() * stride bytes).
Result<void> pack_elements(const State::Buf& b, const Json& elements, const std::string& pointer, std::uint8_t* out) {
    std::vector<std::string> names;
    for (const MaterialBufferFieldDef& f : b.fields) names.push_back(f.name);
    for (std::size_t i = 0; i < elements.size(); ++i) {
        const Json& e = elements[i];
        const std::string at = pointer + "/" + std::to_string(i);
        if (!e.is_object())
            return make_error(at + ": " + describe_json_value(e) + " is not an object",
                              "Each element is an object with the buffer's fields: " + join(names, ", ") + ".");
        for (auto it = e.begin(); it != e.end(); ++it) {
            const MaterialBufferFieldDef* f = nullptr;
            for (const MaterialBufferFieldDef& cand : b.fields)
                if (cand.name == it.key()) f = &cand;
            if (!f)
                return make_error(at + "/" + it.key() + ": the buffer '" + b.name + "' of '" + b.material +
                                      "' has no field '" + it.key() + "'",
                                  did_you_mean(it.key(), names));
            auto packed = pack_field(*f, it.value(), out + i * b.stride, at + "/" + it.key());
            if (!packed.ok()) return packed;
        }
    }
    return {};
}

Json unpack_element(const State::Buf& b, const std::uint8_t* src) {
    Json e = Json::object();
    for (const MaterialBufferFieldDef& f : b.fields) {
        Json values = Json::array();
        for (int c = 0; c < f.components; ++c) {
            const std::uint8_t* at = src + f.offset + std::size_t(c) * 4;
            if (f.isInt) {
                std::int32_t x;
                std::memcpy(&x, at, 4);
                values.push_back(x);
            } else if (f.isUint) {
                std::uint32_t x;
                std::memcpy(&x, at, 4);
                values.push_back(x);
            } else {
                float x;
                std::memcpy(&x, at, 4);
                values.push_back(compute_json_float(x));
            }
        }
        e[f.name] = f.components == 1 ? values[0] : values;
    }
    return e;
}

// The JSON numbers of `count` elements of `b` (every component of every field): the JSON of a call weighs about that many
// values, whatever the stride. Refused over kMaxComputeJsonValues, with the largest count that fits and how to go on.
Result<void> check_json_values(const State::Buf& b, std::uint64_t count, const char* what, const char* chunk) {
    std::uint64_t perElement = 0;
    for (const MaterialBufferFieldDef& f : b.fields) perElement += std::uint64_t(f.components);
    perElement = std::max<std::uint64_t>(perElement, 1);
    const std::uint64_t maxElements = kMaxComputeJsonValues / perElement;
    if (count <= maxElements) return {};
    return make_error(std::string(what) + ": " + std::to_string(count) + " elements of " + std::to_string(perElement) +
                          " numbers each (" + std::to_string(b.fields.size()) + " fields) are more than the " +
                          std::to_string(kMaxComputeJsonValues) + " numbers one call converts (at most " +
                          std::to_string(maxElements) + " elements for this buffer)",
                      std::string(chunk) + " in chunks of at most " + std::to_string(maxElements) +
                          " elements: each call takes `first` (the index to start at) and the number of elements.");
}

bool same_layout(const State::Buf& b, const MaterialBufferDef& def) {
    if (b.stride != def.stride || b.fields.size() != def.fields.size()) return false;
    for (std::size_t i = 0; i < b.fields.size(); ++i)
        if (b.fields[i].name != def.fields[i].name || b.fields[i].type != def.fields[i].type ||
            b.fields[i].offset != def.fields[i].offset)
            return false;
    return true;
}

// The material at `path` when it is a compute material that built.
Result<MaterialAsset*> compute_material(State& s, const std::string& path) {
    if (path.empty())
        return make_error("material: the path of a compute material is empty",
                          "Give the project-relative path, e.g. \"materials/boids.material.json\".");
    MaterialAsset* m = s.assets->material(path);
    if (!m->ok)
        return make_error("the compute material '" + path + "' cannot be used: " + m->error,
                          "Fix the material: `factoria validate` and the `shader.compile` command list what is wrong.");
    if (m->kind != MaterialKind::Compute)
        return make_error("the material '" + path + "' has kind \"" + material_kind_name(m->kind) +
                              "\", not \"compute\"",
                          "The compute.* commands run materials with \"kind\": \"compute\" (docs/SHADERS.md, \"Compute "
                          "materials\").");
    return m;
}

// Copies `data` into `dst` at `offset` through a staging buffer made for the purpose (an immutable buffer cannot be written from
// the CPU), so the rest of the storage buffer keeps what the GPU wrote there.
Result<void> upload(render::Gpu& gpu, sg_buffer dst, std::size_t offset, const std::vector<std::uint8_t>& data) {
    sg_buffer_desc sd{};
    sd.size = data.size();
    sd.usage.vertex_buffer = true;
    sd.usage.copy_src = true;
    sd.data = {data.data(), data.size()};
    sd.label = "compute upload";
    const sg_buffer staging = sg_make_buffer(&sd);
    if (sg_query_buffer_state(staging) != SG_RESOURCESTATE_VALID) {
        if (staging.id) sg_destroy_buffer(staging);
        return make_error("compute: the graphics driver could not make the upload buffer of " +
                              std::to_string(data.size()) + " bytes (the sokol log lines above have the reason)",
                          "Write fewer elements at a time, or free GPU memory.");
    }
    sg_copy_buffer_to_buffer_desc cd{};
    cd.src.buffer = staging;
    cd.dst.buffer = dst;
    cd.dst.offset = offset;
    cd.size = data.size();
    sg_copy_buffer_to_buffer(&cd);
    sg_destroy_buffer(staging);
    gpu.note_work();
    return {};
}

// ---- Storage images ----

const char* image_format_name(sg_pixel_format f) {
    switch (f) {
        case SG_PIXELFORMAT_RGBA16F: return "rgba16f";
        case SG_PIXELFORMAT_R32F: return "r32f";
        case SG_PIXELFORMAT_RGBA32F: return "rgba32f";
        default: return "rgba8";
    }
}

int image_channels(sg_pixel_format f) { return f == SG_PIXELFORMAT_R32F ? 1 : 4; }

// The storage formats this GPU can write from a shader (and read, when `readWrite`) and clear: the ones a material may declare.
std::string usable_image_formats(bool readWrite) {
    std::vector<std::string> ok;
    for (sg_pixel_format f :
         {SG_PIXELFORMAT_RGBA8, SG_PIXELFORMAT_RGBA16F, SG_PIXELFORMAT_R32F, SG_PIXELFORMAT_RGBA32F}) {
        const sg_pixelformat_info pf = sg_query_pixelformat(f);
        if (pf.write && (pf.read || !readWrite) && pf.render &&
            (!readWrite || render::storage_image_loadable(f, nullptr)))
            ok.push_back(image_format_name(f));
    }
    return ok.empty() ? std::string("none") : join(ok, ", ");
}

// The size a request asks (0 = the material's own), refused with the number it hit: the file's own size when none is given, the
// engine's cap and the GPU's largest 2D image.
Result<std::uint64_t> check_image_size(const std::string& what, sg_pixel_format format, int width, int height,
                                       std::uint64_t otherBytes) {
    if (width < 1 || height < 1)
        return make_error(what + ": " + std::to_string(width) + " x " + std::to_string(height) + " is not a size",
                          "Width and height are whole numbers of at least 1 (0 = the size the material declares).");
    const int gpuSide = std::max(1, sg_query_limits().max_image_size_2d);
    const int maxSide = std::min(kMaxComputeImageSide, gpuSide);
    if (width > maxSide || height > maxSide)
        return make_error(what + ": " + std::to_string(width) + " x " + std::to_string(height) +
                              " is larger than the " + std::to_string(maxSide) + " pixels a side may have" +
                              (gpuSide < kMaxComputeImageSide ? " on this graphics driver" : ""),
                          "Use an image of at most " + std::to_string(maxSide) + " x " + std::to_string(maxSide) +
                              "; for more detail, tile several images.");
    const std::uint64_t pixel = std::uint64_t(std::max(1, sg_query_pixelformat(format).bytes_per_pixel));
    const std::uint64_t bytes =
        std::uint64_t(width) * std::uint64_t(height) * pixel;  // <= 8192 * 8192 * 16: no overflow
    if (bytes > kMaxComputeImageBytes)
        return make_error(
            what + ": " + std::to_string(width) + " x " + std::to_string(height) + " pixels of " +
                std::to_string(pixel) + " bytes are " + std::to_string(bytes >> 20) + " MiB, more than the " +
                std::to_string(kMaxComputeImageBytes >> 20) + " MiB one image may hold",
            "Use a smaller image or a narrower format (rgba8 is 4 bytes a pixel, r32f 4, rgba16f 8, rgba32f 16).");
    const std::uint64_t others =
        std::min(otherBytes, kMaxComputeImageTotalBytes);  // the live images other than this one
    if (bytes > kMaxComputeImageTotalBytes - others)
        return make_error(what + ": this image would bring the live images to more than " +
                              std::to_string(kMaxComputeImageTotalBytes >> 20) + " MiB",
                          "Destroy the images you no longer use (compute.destroy_image).");
    return bytes;
}

// The image, its two views and a zero fill (a new GPU image holds undefined pixels; sokol cannot copy into a storage image, so
// the image is also a colour attachment and one clearing pass fills it). Nothing is left behind on an error.
Result<State::ImgGpu> make_image_gpu(render::Gpu& gpu, sg_pixel_format format, bool readWrite, int width, int height) {
    const sg_pixelformat_info pf = sg_query_pixelformat(format);
    if (!pf.write || (readWrite && !pf.read) || !pf.render)
        return make_error("image: the format " + std::string(image_format_name(format)) +
                              (readWrite ? " cannot be read and written" : " cannot be written") +
                              " by a compute shader on this graphics backend (storage image format not supported)",
                          "On this backend the formats that work are: " + usable_image_formats(readWrite) +
                              ". Change \"format\" of the image in the material file.");
    State::ImgGpu g;
    sg_image_desc id{};
    id.type = SG_IMAGETYPE_2D;
    id.width = width;
    id.height = height;
    id.num_mipmaps = 1;
    id.sample_count = 1;
    id.pixel_format = format;
    id.usage.storage_image = true;
    id.usage.color_attachment = true;  // the clearing pass below (usage.copy_dst is refused for a storage image)
    id.label = "compute image";
    g.image = sg_make_image(&id);
    if (sg_query_image_state(g.image) != SG_RESOURCESTATE_VALID) {
        if (g.image.id) sg_destroy_image(g.image);
        return make_error("compute: the graphics driver could not make a " + std::to_string(width) + " x " +
                              std::to_string(height) + " " + image_format_name(format) +
                              " storage image (the sokol log lines above have the reason)",
                          "Use a smaller image or another format, or free GPU memory.");
    }
    sg_view_desc vd{};
    vd.storage_image.image = g.image;
    vd.label = "compute image storage view";
    g.storage = sg_make_view(&vd);
    vd = sg_view_desc{};
    vd.color_attachment.image = g.image;
    vd.label = "compute image clear view";
    const sg_view clearView = sg_make_view(&vd);
    bool ok = sg_query_view_state(g.storage) == SG_RESOURCESTATE_VALID &&
              sg_query_view_state(clearView) == SG_RESOURCESTATE_VALID;
    if (ok && pf.sample &&
        pf.filter) {  // the shaders sample with a filtering sampler: a format that cannot filter is not shown
        vd = sg_view_desc{};
        vd.texture.image = g.image;
        vd.label = "compute image texture view";
        g.sampled = sg_make_view(&vd);
        ok = sg_query_view_state(g.sampled) == SG_RESOURCESTATE_VALID;
    }
    if (!ok) {
        if (clearView.id) sg_destroy_view(clearView);
        State::release(g);
        return make_error(
            "compute: the graphics driver could not make the views of the storage image",
            "This is a driver problem: update the graphics driver and report it with the sokol log lines above.");
    }
    render::PassDesc pass;
    pass.label = "compute image clear";
    pass.color = clearView;
    pass.format.color = format;
    pass.format.samples = 1;
    pass.colorLoad = SG_LOADACTION_CLEAR;
    pass.colorStore = SG_STOREACTION_STORE;
    pass.clearColor = sg_color{0.0f, 0.0f, 0.0f, 0.0f};
    render::Gpu::begin_pass(pass);
    render::Gpu::end_pass();
    sg_destroy_view(clearView);
    gpu.note_work();
    return g;
}

// Fills the texture object a material samples the image through from the image's current GPU objects.
void describe_image_texture(render::TextureAsset& t, const std::string& path, sg_pixel_format format, int width,
                            int height, std::uint64_t bytes, const State::ImgGpu& g) {
    t.path = path;
    // The pixels are what a shader wrote: not an sRGB-encoded file. rgba8 is shown as written (Raw, like any rgba8 file); the float
    // formats hold scene values that nothing converts (Scene).
    t.enc = format == SG_PIXELFORMAT_RGBA8 ? render::TexEncoding::Raw : render::TexEncoding::Scene;
    t.image = g.image;
    t.view = g.sampled;
    t.width = width;
    t.height = height;
    t.placeholder = false;
    t.format = format;
    t.bytes = std::size_t(bytes);
}

}  // namespace

namespace {
// What the GPU can do, or what a test's set_backend says another backend could.
render::FeatureEnv backend_env(const State& s) {
    render::FeatureEnv env = render::feature_env_from_sokol();
    if (s.backendOverride >= 0) {  // a test answers as another backend would
        env.backend = render::FeatureBackend(s.backendOverride);
        env.compute = env.backend == render::FeatureBackend::Gl || env.backend == render::FeatureBackend::D3d11 ||
                      env.backend == render::FeatureBackend::Metal;
    }
    return env;
}
}  // namespace

Compute::Compute() : s_(std::make_unique<State>()) {}
Compute::~Compute() { detach(); }

void Compute::attach(render::Gpu* gpu, render::Assets* assets) {
    s_->gpu = gpu;
    s_->assets = assets;
    if (assets) {
        State* st = s_.get();
        // The buffers of a mesh material (M72.4) need what compute needs; a test's set_backend answers for both.
        assets->set_storage_buffer_gate([st](std::string* backend, std::string* reason) {
            const render::FeatureEnv env = backend_env(*st);
            if (backend) *backend = render::feature_backend_label(env.backend);
            return render::feature_supported(env, render::find_feature("computeShaders"), reason);
        });
        assets->set_compute_image_resolver([st](const std::string& id, std::string* why) -> render::TextureAsset* {
            const std::string digits = id.substr(8);  // after "compute:"
            int n = 0;
            bool numeric = !digits.empty() && digits.size() <= 9;
            for (char c : digits) {
                numeric = numeric && c >= '0' && c <= '9';
                if (numeric) n = n * 10 + (c - '0');
            }
            auto it = numeric ? st->imgs.find(n) : st->imgs.end();
            if (it == st->imgs.end()) {
                if (why) *why = "'" + id + "' names no live compute image (it was destroyed, or never made)";
                return nullptr;
            }
            render::TextureAsset* t = it->second.tex.get();
            if (!t->view.id) {
                if (why)
                    *why = "'" + id + "' is a " + image_format_name(it->second.format) +
                           " image, and this graphics backend cannot filter that format when a material samples it "
                           "(use rgba8 or rgba16f for an image a material shows)";
                return nullptr;
            }
            return t;
        });
    }
}

Result<ComputeDrawAccess::Bound> ComputeDrawAccess::bind(Compute& c, int id, const MaterialBufferDef& def,
                                                         const std::string& material, const std::string& pointer) {
    const State& s = *c.s_;
    auto it = s.bufs.find(id);
    if (it == s.bufs.end())
        return make_error(
            pointer + ": no compute buffer " + std::to_string(id) + " (it was destroyed, or never made), so '" +
                material + "' cannot read '" + def.name + "'",
            "Give the id of a live buffer (compute.list_buffers lists them; compute.create_buffer makes one).");
    if (!same_layout(it->second, def))
        return make_error(
            pointer + ": buffer " + std::to_string(id) + " was made for '" + it->second.name + "' of '" +
                it->second.material + "' with another layout (stride " + std::to_string(it->second.stride) +
                ") than '" + def.name + "' of '" + material + "' (stride " + std::to_string(def.stride) + ")",
            "Make the buffer from a compute material that declares '" + def.name +
                "' with the same fields in the same order "
                "(compute.create_buffer), or make the fields of the mesh or sprite material match the buffer.");
    return Bound{it->second.view, it->second.count};
}

void ComputeTestAccess::set_backend(Compute& c, int backend) { c.s_->backendOverride = backend; }
void ComputeTestAccess::set_binding_limit(Compute& c, int limit) {
    if (c.s_->assets) c.s_->assets->set_storage_binding_limit_override(limit);
}
void ComputeTestAccess::set_load_override(Compute& c, int mode) { c.s_->loadOverride = mode; }

Json compute_json_float(float v) {
    if (!std::isfinite(v)) return Json(nullptr);
    char text[48];
    const auto written = std::to_chars(text, text + sizeof text, v, std::chars_format::general, 7);
    if (written.ec != std::errc()) return Json(double(v));
    // Parsed by the JSON library (no locale); std::from_chars of a float is missing from iOS 16 and older libc++.
    Json parsed = Json::parse(std::string(text, written.ptr), nullptr, false);
    return parsed.is_number() ? parsed : Json(double(v));
}

void Compute::detach() {
    if (!s_) return;
    const bool alive = s_->gpu && sg_isvalid();
    if (alive)
        for (auto& [id, b] : s_->bufs) s_->destroy(b);
    if (s_->assets) {
        s_->assets->set_compute_image_resolver(nullptr);
        s_->assets->set_storage_buffer_gate(nullptr);
    }
    for (auto& [id, im] : s_->imgs) s_->destroy(im, alive);
    s_->bufs.clear();
    s_->imgs.clear();
    s_->retired.clear();  // before the assets go: they point at the white texture
    s_->totalBytes = 0;
    s_->imageBytes = 0;
    s_->gpu = nullptr;
    s_->assets = nullptr;
}

bool Compute::available(std::string* why) const {
    State& s = *s_;
    if (!s.gpu || !s.assets || !sg_isvalid()) {
        if (why) *why = "compute: the renderer is not running (no graphics: graphics=false, or before init)";
        return false;
    }
    const render::FeatureEnv env = backend_env(s);
    std::string reason;
    if (render::feature_supported(env, render::find_feature("computeShaders"), &reason)) return true;
    if (why)
        *why = std::string("compute shaders are not available on the ") + render::feature_backend_label(env.backend) +
               " graphics backend: " + reason +
               ". Compute materials run on Windows (D3D11), macOS and iOS (Metal) and Linux (OpenGL 4.3 or newer), not "
               "on Android (GLES3), the web (WebGL2) or macOS OpenGL (4.1). Ask `render.supports` "
               "{\"feature\":\"computeShaders\"} first, and on this backend use the CPU path: do the work in a script "
               "(the "
               "data of a buffer in an array) or in a mesh, sprite or post material that computes it per pixel (a "
               "noise or "
               "height map is a function of the pixel position) (docs/shaders/SHADERS_COMPUTE.md, \"Where it runs\")";
    return false;
}

namespace {
Error refused(const std::string& why) {
    return make_error(why, "Check render.supports computeShaders before using compute.*.");
}
}  // namespace

Result<int> Compute::create_buffer(const std::string& material, const std::string& buffer, std::uint64_t count,
                                   const Json& initial) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    if (render::Gpu::in_pass())
        return make_error("compute.create_buffer: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    auto made = compute_material(s, material);
    if (!made.ok()) return made.error();
    const MaterialAsset& m = **made;

    const MaterialBufferDef* def = nullptr;
    std::vector<std::string> names;
    for (const MaterialBufferDef& b : m.buffers) {
        names.push_back(b.name);
        if (b.name == buffer) def = &b;
    }
    if (!def)
        return make_error("buffer: the material '" + material + "' has no buffer '" + buffer + "'",
                          names.empty() ? std::string("The material declares no buffers.")
                                        : did_you_mean(buffer, names));
    if (count < 1)
        return make_error("count: a buffer holds at least 1 element",
                          "Pass the number of elements the snippet indexes.");
    const std::uint64_t maxElements = kMaxComputeBufferBytes / def->stride;
    if (count > maxElements)
        return make_error("count: " + std::to_string(count) + " elements of " + std::to_string(def->stride) +
                              " bytes are more than the " + std::to_string(kMaxComputeBufferBytes >> 20) +
                              " MiB one buffer may hold (at most " + std::to_string(maxElements) + " elements)",
                          "Split the data into several buffers, or make the element smaller.");
    const std::uint64_t bytes = count * def->stride;  // <= kMaxComputeBufferBytes: no overflow
    if (int(s.bufs.size()) >= kMaxLiveComputeBuffers)
        return make_error(
            "compute: " + std::to_string(kMaxLiveComputeBuffers) + " buffers are alive already",
            "Destroy the ones you no longer use (compute.destroy_buffer); compute.list_buffers names them.");
    if (bytes > kMaxComputeTotalBytes - std::min(s.totalBytes, kMaxComputeTotalBytes))
        return make_error("compute: this buffer would bring the live buffers to more than " +
                              std::to_string(kMaxComputeTotalBytes >> 20) + " MiB",
                          "Destroy the buffers you no longer use (compute.destroy_buffer).");

    State::Buf b;
    b.material = m.path;
    b.name = def->name;
    b.stride = def->stride;
    b.fields = def->fields;
    b.count = count;
    b.bytes = bytes;
    if (!initial.is_null()) {
        if (!initial.is_array())
            return make_error("initial: " + describe_json_value(initial) + " is not an array",
                              "Pass an array of {field: value} objects, at most `count` of them.");
        if (initial.size() > count)
            return make_error("initial: " + std::to_string(initial.size()) + " elements do not fit in a buffer of " +
                                  std::to_string(count),
                              "Raise `count` or pass fewer elements.");
    }
    std::vector<std::uint8_t> data(std::size_t(bytes), 0);
    if (initial.is_array()) {
        auto packed = pack_elements(b, initial, "/initial", data.data());
        if (!packed.ok()) return packed.error();
    }

    sg_buffer_desc bd{};
    bd.size = std::size_t(bytes);
    bd.usage.storage_buffer = true;
    bd.usage.copy_dst = true;  // sokol: a copy_dst buffer has no initial data, it is filled by the copy below
    bd.label = "compute buffer";
    b.buffer = sg_make_buffer(&bd);
    if (sg_query_buffer_state(b.buffer) != SG_RESOURCESTATE_VALID) {
        if (b.buffer.id) sg_destroy_buffer(b.buffer);
        return make_error("compute: the graphics driver could not make a storage buffer of " + std::to_string(bytes) +
                              " bytes (the sokol log lines above have the reason)",
                          "Use a smaller buffer, or free GPU memory.");
    }
    auto filled =
        upload(*s.gpu, b.buffer, 0, data);  // zeros and `initial`: a new GPU buffer is not zeroed on every backend
    if (!filled.ok()) {
        sg_destroy_buffer(b.buffer);
        return filled.error();
    }
    sg_view_desc vd{};
    vd.storage_buffer.buffer = b.buffer;
    vd.label = "compute buffer view";
    b.view = sg_make_view(&vd);
    if (sg_query_view_state(b.view) != SG_RESOURCESTATE_VALID) {
        if (b.view.id) sg_destroy_view(b.view);
        sg_destroy_buffer(b.buffer);
        return make_error(
            "compute: the graphics driver could not make a view of the storage buffer",
            "This is a driver problem: update the graphics driver and report it with the sokol log lines above.");
    }
    b.id = s.nextId++;
    s.totalBytes += bytes;
    const int id = b.id;
    s.bufs.emplace(id, std::move(b));
    return id;
}

Result<void> Compute::write_buffer(int id, std::uint64_t first, const Json& elements) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    auto it = s.bufs.find(id);
    if (it == s.bufs.end())
        return make_error("buffer: no compute buffer " + std::to_string(id),
                          "compute.list_buffers lists the live buffers.");
    State::Buf& b = it->second;
    if (render::Gpu::in_pass())
        return make_error("compute.write_buffer: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    if (!elements.is_array())
        return make_error("elements: " + describe_json_value(elements) + " is not an array",
                          "Pass an array of {field: value} objects.");
    if (elements.empty()) return {};
    if (elements.size() > kMaxComputeJsonElements)
        return make_error("elements: " + std::to_string(elements.size()) + " elements in one call; at most " +
                              std::to_string(kMaxComputeJsonElements),
                          "Write the buffer in several calls.");
    if (auto fits = check_json_values(b, elements.size(), "elements", "Write the buffer"); !fits.ok()) return fits;
    if (first >= b.count || elements.size() > b.count - first)
        return make_error("first/elements: elements " + std::to_string(first) + ".." +
                              std::to_string(first + elements.size()) + " are outside the buffer of " +
                              std::to_string(b.count),
                          "Keep first + elements.size() within " + std::to_string(b.count) + ".");
    const std::uint64_t bytes = std::uint64_t(elements.size()) * b.stride;
    std::vector<std::uint8_t> data(std::size_t(bytes), 0);
    auto packed = pack_elements(b, elements, "/elements", data.data());
    if (!packed.ok()) return packed;

    auto uploaded = upload(*s.gpu, b.buffer, std::size_t(first * b.stride), data);
    if (!uploaded.ok()) return uploaded;
    return {};
}

std::uint64_t Compute::max_json_elements(int id) const {
    auto it = s_->bufs.find(id);
    if (it == s_->bufs.end()) return kMaxComputeJsonElements;
    std::uint64_t perElement = 0;
    for (const MaterialBufferFieldDef& f : it->second.fields) perElement += std::uint64_t(f.components);
    perElement = std::max<std::uint64_t>(perElement, 1);
    return std::min(kMaxComputeJsonElements, kMaxComputeJsonValues / perElement);
}

Result<Json> Compute::read_buffer(int id, std::uint64_t first, std::uint64_t count) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    auto it = s.bufs.find(id);
    if (it == s.bufs.end())
        return make_error("buffer: no compute buffer " + std::to_string(id),
                          "compute.list_buffers lists the live buffers.");
    const State::Buf& b = it->second;
    if (render::Gpu::in_pass())
        return make_error("compute.read_buffer: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    if (count > kMaxComputeJsonElements)
        return make_error("count: " + std::to_string(count) + " elements in one call; at most " +
                              std::to_string(kMaxComputeJsonElements),
                          "Read the buffer in several calls (first, count).");
    if (auto fits = check_json_values(b, count, "count", "Read the buffer"); !fits.ok()) return fits.error();
    if (first > b.count || count > b.count - first)
        return make_error("first/count: elements " + std::to_string(first) + ".." + std::to_string(first + count) +
                              " are outside the buffer of " + std::to_string(b.count),
                          "Keep first + count within " + std::to_string(b.count) + ".");
    if (count == 0) return Json::array();
    // A read back waits for the GPU, and on Metal the recorded work is only submitted by sg_commit (Renderer::capture does the
    // same). sg_commit is legal anywhere outside a pass, also between begin_frame and end_frame (the editor commits once per UI
    // frame); a call inside a pass was refused by in_pass() above, so no "inFrame" error exists. After the commit the draws of
    // the rest of the frame go on as usual: note_commit() only tells the renderer its transient buffers may restart.
    if (!s.gpu->committed()) {
        sg_commit();
        s.gpu->note_commit();
    }
    std::vector<std::uint8_t> raw;
    std::string error;
    if (!render::readback_buffer(b.buffer, std::size_t(first * b.stride), std::size_t(count * b.stride), raw, &error))
        return make_error("compute.read_buffer: " + error,
                          "This is a graphics driver problem on this backend; report it.");
    Json out = Json::array();
    for (std::uint64_t i = 0; i < count; ++i) out.push_back(unpack_element(b, raw.data() + std::size_t(i) * b.stride));
    return out;
}

Result<void> Compute::destroy_buffer(int id) {
    State& s = *s_;
    auto it = s.bufs.find(id);
    if (it == s.bufs.end())
        return make_error("buffer: no compute buffer " + std::to_string(id),
                          "compute.list_buffers lists the live buffers.");
    if (sg_isvalid()) s.destroy(it->second);
    s.bufs.erase(it);
    return {};
}

Result<void> Compute::dispatch(const ComputeDispatch& d) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    if (render::Gpu::in_pass())
        return make_error("compute.dispatch: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    auto made = compute_material(s, d.material);
    if (!made.ok()) return made.error();
    MaterialAsset& m = **made;

    for (int i = 0; i < 3; ++i)
        if (d.groups[i] < 1 || d.groups[i] > kMaxComputeGroups)
            return make_error("groups/" + std::to_string(i) + ": " + std::to_string(d.groups[i]) +
                                  " workgroups; each dimension takes 1 to " + std::to_string(kMaxComputeGroups),
                              "groups counts workgroups of " + std::to_string(m.workgroup[0]) + "x" +
                                  std::to_string(m.workgroup[1]) + "x" + std::to_string(m.workgroup[2]) +
                                  " threads: dispatch ceil(work / " + std::to_string(m.workgroup[0]) +
                                  ") for a one-dimensional job.");

    // The buffers: every one of the material, no other, each made for a buffer with the same layout.
    std::vector<std::string> declared;
    for (const MaterialBufferDef& def : m.buffers) declared.push_back(def.name);
    for (const auto& [name, id] : d.buffers)
        if (std::find(declared.begin(), declared.end(), name) == declared.end())
            return make_error("buffers/" + name + ": the material '" + m.path + "' has no buffer '" + name + "'",
                              declared.empty() ? std::string("The material declares no buffers.")
                                               : did_you_mean(name, declared));
    std::vector<const State::Buf*> bound;
    for (const MaterialBufferDef& def : m.buffers) {
        auto given = d.buffers.find(def.name);
        if (given == d.buffers.end())
            return make_error("buffers: the buffer '" + def.name + "' of '" + m.path + "' is not given",
                              "Pass a buffer id for every buffer of the material: " + join(declared, ", ") + ".");
        auto it = s.bufs.find(given->second);
        if (it == s.bufs.end())
            return make_error("buffers/" + def.name + ": no compute buffer " + std::to_string(given->second),
                              "compute.list_buffers lists the live buffers; compute.create_buffer makes one.");
        if (!same_layout(it->second, def))
            return make_error(
                "buffers/" + def.name + ": buffer " + std::to_string(given->second) + " was made for '" +
                    it->second.name + "' of '" + it->second.material + "', with another layout than '" + def.name +
                    "' of '" + m.path + "' has now",
                "Make the buffer for this material (compute.create_buffer), or destroy and make it again if the "
                "material's fields changed.");
        for (const State::Buf* other : bound)
            if (other == &it->second)
                return make_error(
                    "buffers/" + def.name + ": buffer " + std::to_string(given->second) +
                        " is bound to two buffers of the material",
                    "A storage buffer cannot be read and written through two bindings at once: use two buffers.");
        bound.push_back(&it->second);
    }

    // The storage images: the same rule (every one of the material, no other, each made with the format the material declares now).
    std::vector<std::string> declaredImages;
    for (const render::MaterialImageDef& def : m.images) declaredImages.push_back(def.name);
    for (const auto& [name, id] : d.images)
        if (std::find(declaredImages.begin(), declaredImages.end(), name) == declaredImages.end())
            return make_error("images/" + name + ": the material '" + m.path + "' has no image '" + name + "'",
                              declaredImages.empty() ? std::string("The material declares no images.")
                                                     : did_you_mean(name, declaredImages));
    std::vector<const State::Img*> boundImages;
    for (const render::MaterialImageDef& def : m.images) {
        auto given = d.images.find(def.name);
        if (given == d.images.end())
            return make_error("images: the image '" + def.name + "' of '" + m.path + "' is not given",
                              "Pass an image id for every image of the material: " + join(declaredImages, ", ") + ".");
        auto it = s.imgs.find(given->second);
        if (it == s.imgs.end())
            return make_error("images/" + def.name + ": no compute image " + std::to_string(given->second),
                              "compute.list_images lists the live images; compute.create_image makes one.");
        if (it->second.format != def.format)
            return make_error(
                "images/" + def.name + ": image " + std::to_string(given->second) + " was made for '" +
                    it->second.name + "' of '" + it->second.material + "' as " + image_format_name(it->second.format) +
                    ", but '" + def.name + "' of '" + m.path + "' is " + image_format_name(def.format) + " now",
                "Make the image for this material (compute.create_image), or destroy and make it again if "
                "the material's format changed.");
        for (const State::Img* other : boundImages)
            if (other == &it->second)
                return make_error("images/" + def.name + ": image " + std::to_string(given->second) +
                                      " is bound to two images of the material",
                                  "Two bindings of one image cannot be written at once: use two images.");
        boundImages.push_back(&it->second);
    }

    // The values: a param by number or array, a texture by path, nothing else.
    std::vector<std::string> valueNames;
    for (const render::MaterialParamDef& p : m.params) valueNames.push_back(p.name);
    for (const render::MaterialTextureDef& t : m.textures) valueNames.push_back(t.name);
    if (!d.params.is_null() && !d.params.is_object())
        return make_error("params: " + describe_json_value(d.params) + " is not an object",
                          "Pass {param: value}; a texture's value is its path.");
    if (d.params.is_object()) {
        for (auto it = d.params.begin(); it != d.params.end(); ++it) {
            const std::string at = "params/" + it.key();
            if (std::find(valueNames.begin(), valueNames.end(), it.key()) == valueNames.end())
                return make_error(at + ": the material '" + m.path + "' has no param or texture '" + it.key() + "'",
                                  valueNames.empty() ? std::string("The material declares no params or textures.")
                                                     : did_you_mean(it.key(), valueNames));
            const render::MaterialParamDef* p = nullptr;
            for (const render::MaterialParamDef& cand : m.params)
                if (cand.name == it.key()) p = &cand;
            if (!p) {
                if (!it.value().is_string())
                    return make_error(at + ": " + describe_json_value(it.value()) + " is not a texture path",
                                      "A texture is given by its project-relative path, e.g. \"assets/noise.png\".");
                continue;
            }
            bool good = p->components == 1 ? it.value().is_number()
                                           : it.value().is_array() && int(it.value().size()) == p->components;
            if (good && it.value().is_array())
                for (const Json& c : it.value()) good = good && c.is_number();
            if (!good)
                return make_error(at + ": " + describe_json_value(it.value()) + " is not " +
                                      (p->components == 1
                                           ? std::string("a number")
                                           : "an array of " + std::to_string(p->components) + " numbers"),
                                  "Give the param the type its material declares.");
        }
    }

    const render::MaterialProgram& prog = m.programs[render::kProgCompute];
    if (!prog.shader.id)
        return make_error("the compute material '" + m.path + "' has no program", "Compile it again (shader.compile).");
    float block[render::kMaxMaterialParams][4]{};
    render::pack_material_params(m, d.params.is_object() ? d.params : Json::object(), block);
    for (int slot = 0; slot < SG_MAX_UNIFORMBLOCK_BINDSLOTS; ++slot)
        if (prog.has_ub(slot) && (slot != 0 || prog.ubSize[slot] > sizeof(block)))
            return make_error("the shader of '" + m.path + "' declares a uniform block the engine does not know",
                              "Compile the material again with this factoria version.");

    const sg_pipeline pip = s.gpu->compute_pipeline(prog.shader);
    if (sg_query_pipeline_state(pip) != SG_RESOURCESTATE_VALID)
        return make_error("compute: the graphics driver rejected the program of '" + m.path + "'",
                          "The sokol log lines above have the driver message; this is a driver problem or a shader the "
                          "backend cannot run.");

    // Only the slots the program declares are bound (the compiler drops a buffer or texture the snippet never touches).
    sg_bindings bind{};
    for (std::size_t i = 0; i < m.buffers.size(); ++i)
        if ((prog.viewMask >> m.buffers[i].binding) & 1u) bind.views[m.buffers[i].binding] = bound[i]->view;
    for (std::size_t i = 0; i < m.images.size(); ++i)
        if ((prog.viewMask >> m.images[i].binding) & 1u) bind.views[m.images[i].binding] = boundImages[i]->gpu.storage;
    for (std::size_t i = 0; i < m.textures.size(); ++i) {
        const int viewSlot = int(m.buffers.size() + m.images.size() + i);
        render::TextureAsset* tex = render::material_texture(m, int(i), d.params, *s.assets);
        for (const State::Img* img :
             boundImages)  // sokol refuses one image as a storage image and a texture in one pass
            if (tex && tex == img->tex.get() && ((prog.viewMask >> viewSlot) & 1u))
                return make_error(
                    "params/" + m.textures[i].name + ": the texture is the compute image '" +
                        Compute::image_texture_id(img->id) + "', which this dispatch writes as a storage image",
                    "Sample another image (a second one the dispatch writes into next frame) or read this one with "
                    "imageLoad: declare it \"access\": \"readWrite\" and drop the texture.");
        if (!tex || !tex->gpu_view().id) tex = s.assets->white();
        if ((prog.viewMask >> viewSlot) & 1u) bind.views[viewSlot] = tex->gpu_view();
        if ((prog.samplerMask >> i) & 1u) bind.samplers[i] = s.gpu->sampler(m.textures[i].sampler);
    }

    render::Gpu::begin_compute_pass();
    sg_apply_pipeline(pip);
    sg_apply_bindings(&bind);
    if (prog.has_ub(0)) sg_apply_uniforms(0, sg_range{block, prog.ubSize[0]});
    sg_dispatch(int(d.groups[0]), int(d.groups[1]), int(d.groups[2]));
    render::Gpu::end_compute_pass();
    s.gpu->note_work();
    return {};
}

Json Compute::list() const {
    Json out = Json::array();
    for (const auto& [id, b] : s_->bufs)
        out.push_back(Json::object({{"id", id},
                                    {"material", b.material},
                                    {"buffer", b.name},
                                    {"count", b.count},
                                    {"stride", b.stride},
                                    {"bytes", b.bytes}}));
    return out;
}

std::string Compute::image_texture_id(int id) { return "compute:" + std::to_string(id); }

Result<int> Compute::create_image(const std::string& material, const std::string& image, int width, int height) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    if (render::Gpu::in_pass())
        return make_error("compute.create_image: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    auto made = compute_material(s, material);
    if (!made.ok()) return made.error();
    const MaterialAsset& m = **made;

    const render::MaterialImageDef* def = nullptr;
    std::vector<std::string> names;
    for (const render::MaterialImageDef& i : m.images) {
        names.push_back(i.name);
        if (i.name == image) def = &i;
    }
    if (!def)
        return make_error("image: the material '" + material + "' has no image '" + image + "'",
                          names.empty()
                              ? std::string("The material declares no images: add an \"images\" entry to its file "
                                            "(docs/shaders/SHADERS_COMPUTE.md, \"Storage images\").")
                              : did_you_mean(image, names));
    if (def->readWrite) {  // imageLoad of this format is a capability of the GPU, not of the format alone
        std::string limit;
        bool loadable = true;
        if (s.loadOverride == 1) {
            loadable = def->format == SG_PIXELFORMAT_R32F;
            limit = "this GPU can read and write one image only in r32f (simulated by a test)";
        } else if (s.loadOverride == 2) {
            loadable = false;
            limit = "this GPU cannot read an image in a shader (simulated by a test)";
        } else {
            loadable = render::storage_image_loadable(def->format, &limit);
        }
        if (!loadable)
            return make_error(
                "image: " + m.path + " /images/" + def->name +
                    "/access: \"readWrite\" (imageLoad and imageStore) of the format " +
                    image_format_name(def->format) + " does not work on this GPU: " + limit,
                std::string(def->format == SG_PIXELFORMAT_R32F ? ""
                                                               : "Use the format r32f for an image the shader reads "
                                                                 "and writes, or ") +
                    "split it into two images: write one and read the other as a texture, swapping them each frame "
                    "(docs/shaders/SHADERS_COMPUTE.md, \"Storage images\").");
    }
    if (width == 0) width = def->width;
    if (height == 0) height = def->height;
    if (int(s.imgs.size()) >= kMaxLiveComputeImages)
        return make_error(
            "compute: " + std::to_string(kMaxLiveComputeImages) + " images are alive already",
            "Destroy the ones you no longer use (compute.destroy_image); compute.list_images names them.");
    auto bytes = check_image_size("width/height", def->format, width, height, s.imageBytes);
    if (!bytes.ok()) return bytes.error();
    auto gpu = make_image_gpu(*s.gpu, def->format, def->readWrite, width, height);
    if (!gpu.ok()) return gpu.error();

    State::Img im;
    im.id = s.nextImageId++;
    im.material = m.path;
    im.name = def->name;
    im.format = def->format;
    im.readWrite = def->readWrite;
    im.width = width;
    im.height = height;
    im.bytes = *bytes;
    im.gpu = *gpu;
    im.tex = std::make_unique<render::TextureAsset>();
    describe_image_texture(*im.tex, image_texture_id(im.id), im.format, width, height, im.bytes, im.gpu);
    s.imageBytes += im.bytes;
    const int id = im.id;
    s.imgs.emplace(id, std::move(im));
    return id;
}

Result<void> Compute::resize_image(int id, int width, int height) {
    State& s = *s_;
    std::string why;
    if (!available(&why)) return refused(why);
    auto it = s.imgs.find(id);
    if (it == s.imgs.end())
        return make_error("image: no compute image " + std::to_string(id),
                          "compute.list_images lists the live images.");
    if (render::Gpu::in_pass())
        return make_error("compute.resize_image: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    State::Img& im = it->second;
    auto bytes =
        check_image_size("width/height", im.format, width, height, s.imageBytes - std::min(s.imageBytes, im.bytes));
    if (!bytes.ok()) return bytes.error();
    auto gpu = make_image_gpu(*s.gpu, im.format, im.readWrite, width, height);
    if (!gpu.ok()) return gpu.error();
    State::release(
        im.gpu);  // the old GPU image goes (sokol defers it past the draws already recorded); the texture object stays
    im.gpu = *gpu;
    s.imageBytes = s.imageBytes - std::min(s.imageBytes, im.bytes) + *bytes;
    im.bytes = *bytes;
    im.width = width;
    im.height = height;
    describe_image_texture(*im.tex, image_texture_id(im.id), im.format, width, height, im.bytes, im.gpu);
    return {};
}

std::uint64_t Compute::last_read_image_bytes() const { return s_->lastReadBytes; }

std::uint64_t Compute::max_json_pixels(int id) const {
    auto it = s_->imgs.find(id);
    if (it == s_->imgs.end()) return kMaxComputeJsonValues;
    return kMaxComputeJsonValues / std::uint64_t(image_channels(it->second.format));
}

Result<Json> Compute::read_image(int id, int x, int y, int width, int height) {
    State& s = *s_;
    s.lastReadBytes = 0;  // a read refused before it reaches the GPU leaves 0 (compute.h)
    std::string why;
    if (!available(&why)) return refused(why);
    auto it = s.imgs.find(id);
    if (it == s.imgs.end())
        return make_error("image: no compute image " + std::to_string(id),
                          "compute.list_images lists the live images.");
    const State::Img& im = it->second;
    if (render::Gpu::in_pass())
        return make_error("compute.read_image: a frame is being drawn",
                          "Call it from a script's update, not while rendering.");
    if (x < 0 || y < 0 || width < 0 || height < 0 || x >= im.width || y >= im.height)
        return make_error(
            "x/y/width/height: the rectangle " + std::to_string(x) + "," + std::to_string(y) + " " +
                std::to_string(width) + " x " + std::to_string(height) + " is not inside the " +
                std::to_string(im.width) + " x " + std::to_string(im.height) + " image",
            "x and y are pixels from the top left (0 .. size - 1); width and height 0 mean to the right and bottom "
            "edge.");
    if (width == 0) width = im.width - x;
    if (height == 0) height = im.height - y;
    if (width > im.width - x || height > im.height - y)
        return make_error("width/height: the rectangle " + std::to_string(x) + "," + std::to_string(y) + " " +
                              std::to_string(width) + " x " + std::to_string(height) + " goes past the " +
                              std::to_string(im.width) + " x " + std::to_string(im.height) + " image",
                          "Keep x + width within " + std::to_string(im.width) + " and y + height within " +
                              std::to_string(im.height) + ".");
    const int channels = image_channels(im.format);
    const std::uint64_t pixels = std::uint64_t(width) * std::uint64_t(height);  // each <= 8192: no overflow
    const std::uint64_t maxPixels = kMaxComputeJsonValues / std::uint64_t(channels);
    if (pixels > maxPixels)
        return make_error(
            "width/height: " + std::to_string(pixels) + " pixels of " + std::to_string(channels) +
                " numbers each are more than the " + std::to_string(kMaxComputeJsonValues) +
                " numbers one call converts (at most " + std::to_string(maxPixels) + " pixels)",
            "Read the image in rectangles of at most " + std::to_string(maxPixels) +
                " pixels (for example a few rows at a time): x, y, width and height choose the rectangle.");
    if (!s.gpu->committed()) {  // as read_buffer: Metal only submits the recorded work at sg_commit
        sg_commit();
        s.gpu->note_commit();
    }
    // Only the rectangle comes off the GPU (a region copy on every backend): reading a corner of a large image holds a corner.
    std::vector<std::uint8_t> raw;
    std::string error;
    if (!render::readback_storage_image(im.gpu.image, im.format, x, y, width, height, raw, &error))
        return make_error("compute.read_image: " + error,
                          "This is a graphics driver problem on this backend; report it.");
    const std::size_t pixelBytes = std::size_t(sg_query_pixelformat(im.format).bytes_per_pixel);
    if (raw.size() < pixelBytes * std::size_t(width) * std::size_t(height))
        return make_error("compute.read_image: the driver returned fewer bytes than the rectangle holds",
                          "This is a graphics driver problem on this backend; report it.");
    s.lastReadBytes = raw.size();
    Json data = Json::array();
    for (int row = 0; row < height; ++row) {
        const std::uint8_t* src = raw.data() + std::size_t(row) * std::size_t(width) * pixelBytes;
        for (int col = 0; col < width; ++col) {
            const std::uint8_t* px = src + std::size_t(col) * pixelBytes;
            for (int c = 0; c < channels; ++c) {
                switch (im.format) {
                    case SG_PIXELFORMAT_RGBA16F: {
                        std::uint16_t h;
                        std::memcpy(&h, px + std::size_t(c) * 2, 2);
                        data.push_back(compute_json_float(render::half_to_float(h)));
                        break;
                    }
                    case SG_PIXELFORMAT_R32F:
                    case SG_PIXELFORMAT_RGBA32F: {
                        float f;
                        std::memcpy(&f, px + std::size_t(c) * 4, 4);
                        data.push_back(compute_json_float(f));
                        break;
                    }
                    default: data.push_back(int(px[c])); break;
                }
            }
        }
    }
    return Json::object({{"x", x},
                         {"y", y},
                         {"width", width},
                         {"height", height},
                         {"format", image_format_name(im.format)},
                         {"channels", channels},
                         {"data", std::move(data)}});
}

Result<void> Compute::destroy_image(int id) {
    State& s = *s_;
    auto it = s.imgs.find(id);
    if (it == s.imgs.end())
        return make_error("image: no compute image " + std::to_string(id),
                          "compute.list_images lists the live images.");
    s.destroy(it->second, sg_isvalid());
    s.imgs.erase(it);
    return {};
}

Json Compute::list_images() const {
    Json out = Json::array();
    for (const auto& [id, im] : s_->imgs)
        out.push_back(Json::object({{"id", id},
                                    {"material", im.material},
                                    {"image", im.name},
                                    {"format", image_format_name(im.format)},
                                    {"access", im.readWrite ? "readWrite" : "write"},
                                    {"width", im.width},
                                    {"height", im.height},
                                    {"bytes", im.bytes},
                                    {"textureId", image_texture_id(im.id)}}));
    return out;
}

}  // namespace fa
