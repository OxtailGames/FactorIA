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
    Json
        params;  // {param: value}: its params (numbers, arrays) and textures (a texture path), like MeshRenderer.materialParams
    std::uint32_t groups[3] = {1, 1, 1};  // workgroups in x, y, z
};

// Deterministic limits (a result never depends on CPU speed): a request over one is refused with the number it hit.
constexpr int kMaxComputeBuffers = 64;                          // live buffers
constexpr std::uint64_t kMaxComputeBufferBytes = 256ull << 20;  // one buffer: 256 MiB
constexpr std::uint64_t kMaxComputeTotalBytes = 1024ull << 20;  // all live buffers: 1 GiB
constexpr std::uint32_t kMaxComputeGroups = 65535;              // workgroups per dimension (the D3D11 limit)
constexpr std::uint64_t kMaxComputeJsonElements = 1ull << 20;   // elements one write_buffer / read_buffer call converts

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
    Result<void> destroy_buffer(int id);
    // Runs the material once over its buffers (a compute pass; the call returns when the work is recorded, read_buffer waits).
    Result<void> dispatch(const ComputeDispatch& d);
    // The live buffers: [{id, material, buffer, count, stride, bytes}].
    Json list() const;

    // The renderer's: gives this object the graphics it works with (init), and takes it away destroying every buffer (shutdown).
    void attach(render::Gpu* gpu, render::Assets* assets);
    void detach();

    // Tests: answer available() as the render::FeatureBackend `backend` (an int; -1 = the real one) would, to reach the refusal
    // path of a backend without compute on a GPU that has it.
    void set_backend_for_test(int backend);

    struct State;

private:
    std::unique_ptr<State> s_;
};

}  // namespace fa
