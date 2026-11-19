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
    render::Gpu* gpu = nullptr;
    render::Assets* assets = nullptr;
    std::map<int, Buf> bufs;
    int nextId = 1;
    std::uint64_t totalBytes = 0;
    int backendOverride = -1;  // tests: a render::FeatureBackend to answer as

    void destroy(Buf& b) {
        if (b.view.id) sg_destroy_view(b.view);
        if (b.buffer.id) sg_destroy_buffer(b.buffer);
        totalBytes -= std::min(totalBytes, b.bytes);
    }
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

}  // namespace

Compute::Compute() : s_(std::make_unique<State>()) {}
Compute::~Compute() { detach(); }

void Compute::attach(render::Gpu* gpu, render::Assets* assets) {
    s_->gpu = gpu;
    s_->assets = assets;
}

void ComputeTestAccess::set_backend(Compute& c, int backend) { c.s_->backendOverride = backend; }

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
    if (s_->gpu && sg_isvalid())
        for (auto& [id, b] : s_->bufs) s_->destroy(b);
    s_->bufs.clear();
    s_->totalBytes = 0;
    s_->gpu = nullptr;
    s_->assets = nullptr;
}

bool Compute::available(std::string* why) const {
    State& s = *s_;
    if (!s.gpu || !s.assets || !sg_isvalid()) {
        if (why) *why = "compute: the renderer is not running (no graphics: graphics=false, or before init)";
        return false;
    }
    render::FeatureEnv env = render::feature_env_from_sokol();
    if (s.backendOverride >= 0) {  // a test answers as another backend would
        env.backend = render::FeatureBackend(s.backendOverride);
        env.compute = env.backend == render::FeatureBackend::Gl || env.backend == render::FeatureBackend::D3d11 ||
                      env.backend == render::FeatureBackend::Metal;
    }
    std::string reason;
    if (render::feature_supported(env, render::find_feature("computeShaders"), &reason)) return true;
    if (why)
        *why =
            std::string("compute shaders are not available on the ") + render::feature_backend_label(env.backend) +
            " graphics backend: " + reason +
            ". Compute materials run on Windows (D3D11), macOS and iOS (Metal) and Linux (OpenGL 4.3 or newer), not "
            "on Android, the web or macOS OpenGL (4.1). Ask `render.supports` {\"feature\":\"computeShaders\"} first, "
            "and on this backend do the work in a script or in a mesh or sprite material";
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
    for (std::size_t i = 0; i < m.textures.size(); ++i) {
        const int viewSlot = int(m.buffers.size() + i);
        render::TextureAsset* tex = render::material_texture(m, int(i), d.params, *s.assets);
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

}  // namespace fa
