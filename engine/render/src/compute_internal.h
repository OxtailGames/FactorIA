// Private pieces of fa/render/compute.h that tests reach (never a public header: a game must not flip the backend).
#pragma once

#include "fa/core/json.h"
#include "fa/render/compute.h"

namespace fa {

// Tests: make Compute::available() answer as the render::FeatureBackend `backend` (an int; -1 = the real one) would, to reach
// the refusal path of a backend without compute on a GPU that has it.
struct ComputeTestAccess {
    static void set_backend(Compute& c, int backend);
    // Make create_image answer as a GPU that can imageLoad an r32f storage image only (mode 1: a Metal Tier 1 or D3D11.0 GPU), or
    // none (mode 2); 0 = the real GPU.
    static void set_load_override(Compute& c, int mode);
};

// A float as JSON: 7 significant digits (arm64 and x86 differ in the last binary digit of what a shader computes), a NaN or
// infinity as null. Independent of the C locale (std::to_chars / std::from_chars).
Json compute_json_float(float v);

}  // namespace fa
