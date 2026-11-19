// Private pieces of fa/render/compute.h that tests reach (never a public header: a game must not flip the backend).
#pragma once

#include "fa/core/json.h"
#include "fa/render/compute.h"
#include "render_internal.h"

namespace fa {

// Tests: make Compute::available() answer as the render::FeatureBackend `backend` (an int; -1 = the real one) would, to reach
// the refusal path of a backend without compute on a GPU that has it.
struct ComputeTestAccess {
    static void set_backend(Compute& c, int backend);
    // Make create_image answer as a GPU that can imageLoad an r32f storage image only (mode 1: a Metal Tier 1 or D3D11.0 GPU), or
    // none (mode 2); 0 = the real GPU.
    static void set_load_override(Compute& c, int mode);
};

// The mesh draw of a material with "buffers" (M72.4) reads compute buffers: what it needs of one, checked against the layout the
// material declares. Only the renderer's draw calls this, never a game.
struct ComputeDrawAccess {
    struct Bound {
        sg_view view{};
        std::uint64_t count = 0;  // elements
    };
    // The live compute buffer `id` for the buffer `def` of mesh material `material`; an Error that names `pointer` (a JSON pointer
    // into MeshRenderer, e.g. "/materialParams/positions") and says what to change when the id is not a live buffer or was made
    // with another layout (stride and fields) than `def`.
    static Result<Bound> bind(Compute& c, int id, const render::MaterialBufferDef& def, const std::string& material,
                              const std::string& pointer);
};

// A float as JSON: 7 significant digits (arm64 and x86 differ in the last binary digit of what a shader computes), a NaN or
// infinity as null. Independent of the C locale (std::to_chars / std::from_chars).
Json compute_json_float(float v);

}  // namespace fa
