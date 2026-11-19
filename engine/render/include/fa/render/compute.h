// Compute materials at run time (docs/SHADERS.md, "Compute materials"): storage buffers on the GPU, a dispatch of a
// `"kind": "compute"` material over them, and a read back. Renderer::compute() is the one object; the `compute.*` commands
// (engine/runtime/src/compute_commands.cpp) and the scripts' fa.call("compute.dispatch", ...) are thin wrappers of it.
//
//   Compute& c = renderer.compute();
//   std::string why;
//   if (!c.available(&why)) ...                                      // GLES3, WebGL2, macOS GL 4.1: say why and stop
//   auto buf = c.create_buffer("materials/boids.material.json", "boids", 1000);     // a buffer of 1000 elements
//   c.dispatch({"materials/boids.material.json", {{"boids", *buf}}, Json{{"speed", 2.0}}, {16, 1, 1}});
//   auto data = c.read_buffer(*buf, 0, 1000);                         // [{"pos": [x, y], "vel": [x, y]}, ...]
//
// Everything here runs on the thread that owns the graphics context, outside a frame being drawn. Nothing is done silently: a
// backend without compute, a bad name or a range outside a buffer is an Error that says what to change.
#pragma once

#include <cstdint>
#include <map>
#include <memory>
#include <string>

#include "fa/core/json.h"
#include "fa/core/types.h"

namespace fa {

namespace render {
class Gpu;
class Assets;
}  // namespace render

// What one dispatch runs: the material, the buffers it reads and writes and its values. `groups` counts WORKGROUPS (the
// material's workgroupSize threads each), not threads: ceil(work / workgroupSize.x) for a one-dimensional job.
struct ComputeDispatch {
    std::string material;  // project-relative path of the compute material, e.g. "materials/boids.material.json"
    std::map<std::string, int>
        buffers;  // the material's buffer name -> an id from Compute::create_buffer (every buffer of the material)
    std::map<std::string, int>
        images;  // the material's storage image name -> an id from Compute::create_image (every image of the material)
    Json
        params;  // {param: value}: its params (numbers, arrays) and textures (a texture path), like MeshRenderer.materialParams
    std::uint32_t groups[3] = {1, 1, 1};  // workgroups in x, y, z
};

// Deterministic limits (a result never depends on CPU speed): a request over one is refused with the number it hit.
constexpr int kMaxLiveComputeBuffers = 64;                      // live buffers
constexpr std::uint64_t kMaxComputeBufferBytes = 256ull << 20;  // one buffer: 256 MiB
constexpr std::uint64_t kMaxComputeTotalBytes = 1024ull << 20;  // all live buffers: 1 GiB
constexpr std::uint32_t kMaxComputeGroups = 65535;              // workgroups per dimension (the D3D11 limit)
constexpr std::uint64_t kMaxComputeJsonElements = 1ull << 20;   // elements one write_buffer / read_buffer call converts
constexpr std::uint64_t kMaxComputeJsonValues =
    1ull << 22;  // numbers (elements x components of their fields) of one such call

// Storage images (the same rule: a request over a limit is refused with the number it hit). The GPU's own limits (the largest 2D
// image, the storage image bindings of a shader, the formats it can write) are asked of sokol and checked on top of these.
constexpr int kMaxLiveComputeImages = 32;                           // live images
constexpr int kMaxComputeImageSide = 8192;                          // width or height of one image
constexpr std::uint64_t kMaxComputeImageBytes = 256ull << 20;       // one image: 256 MiB
constexpr std::uint64_t kMaxComputeImageTotalBytes = 512ull << 20;  // all live images: 512 MiB

class Compute {
public:
    Compute();
    ~Compute();
    Compute(const Compute&) = delete;
    Compute& operator=(const Compute&) = delete;

    // True when this graphics backend runs compute shaders (the "computeShaders" row of Renderer::supports). False: `why`
    // names the backend and what to do instead; every other call then fails with that same message.
    bool available(std::string* why = nullptr) const;

    // A zero-filled storage buffer of `count` elements shaped like `buffer` of the compute material `material`; `initial` (an
    // array of {field: value} objects, at most `count`) fills the first elements. Returns its id (1, 2, ...).
    Result<int> create_buffer(const std::string& material, const std::string& buffer, std::uint64_t count,
                              const Json& initial = Json());
    // Overwrites `elements.size()` elements from index `first` with {field: value} objects (a field left out is written as 0).
    Result<void> write_buffer(int id, std::uint64_t first, const Json& elements);
    // The GPU's current contents of `count` elements from `first`, as an array of {field: value} objects (a vecN field is an
    // array, floats have 7 significant digits, a NaN or infinity is null). Submits the recorded work and waits for it.
    Result<Json> read_buffer(int id, std::uint64_t first, std::uint64_t count);
    // The most elements one read_buffer / write_buffer call converts for buffer `id` (both JSON caps; the element cap for an
    // unknown id).
    std::uint64_t max_json_elements(int id) const;
    Result<void> destroy_buffer(int id);
    // Runs the material once over its buffers (a compute pass; the call returns when the work is recorded, read_buffer waits).
    Result<void> dispatch(const ComputeDispatch& d);
    // The live buffers: [{id, material, buffer, count, stride, bytes}].
    Json list() const;

    // STORAGE IMAGES: 2D images a compute material writes (imageStore) and reads (imageLoad), then any material samples.
    // A zero-filled image shaped like `image` of the compute material `material` (format and access from its file); `width` and
    // `height` 0 = the size the material declares. Returns its id (1, 2, ...); its texture id for a Sprite, MeshRenderer or
    // materialParams value is image_texture_id(id) ("compute:<id>").
    Result<int> create_image(const std::string& material, const std::string& image, int width = 0, int height = 0);
    // Makes the image `width` x `height`: its contents are lost (zero) and the texture id stays the same.
    Result<void> resize_image(int id, int width, int height);
    // The GPU's current pixels of the rectangle (x, y, width, height) as {x, y, width, height, format, channels, data}: `data` is
    // row by row, pixel by pixel, channel by channel (rgba8: integers 0..255; the float formats: numbers with 7 significant digits,
    // a NaN or infinity is null). width/height 0 = to the right/bottom edge. At most kMaxComputeJsonValues numbers. Submits the
    // recorded work and waits for it.
    Result<Json> read_image(int id, int x, int y, int width, int height);
    // The bytes the last read_image that reached the GPU took from it: the rectangle's, not the image's (0 when that read failed;
    // a test reads it to see that a corner of a large image does not hold the whole image).
    std::uint64_t last_read_image_bytes() const;
    // The most pixels one read_image call converts for image `id` (the number cap over its channels).
    std::uint64_t max_json_pixels(int id) const;
    Result<void> destroy_image(int id);
    // "compute:<id>": what a material's texture value, Sprite.texture or MeshRenderer.texture names to show the image.
    static std::string image_texture_id(int id);
    // The live images: [{id, material, image, format, access, width, height, bytes, textureId}].
    Json list_images() const;

    // The renderer's: gives this object the graphics it works with (init), and takes it away destroying every buffer (shutdown).
    void attach(render::Gpu* gpu, render::Assets* assets);
    void detach();

    struct State;
    friend struct ComputeTestAccess;  // tests (src/compute_internal.h)

private:
    std::unique_ptr<State> s_;
};

}  // namespace fa
