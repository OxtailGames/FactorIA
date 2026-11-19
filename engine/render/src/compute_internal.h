// Private pieces of fa/render/compute.h that tests reach (never a public header: a game must not flip the backend).
#pragma once

#include "fa/core/json.h"
#include "fa/render/compute.h"

namespace fa {

// Tests: make Compute::available() answer as the render::FeatureBackend `backend` (an int; -1 = the real one) would, to reach
// the refusal path of a backend without compute on a GPU that has it.
struct ComputeTestAccess {
    static void set_backend(Compute& c, int backend);
};

// A float as JSON: 7 significant digits (arm64 and x86 differ in the last binary digit of what a shader computes), a NaN or
// infinity as null. Independent of the C locale (std::to_chars / std::from_chars).
Json compute_json_float(float v);

}  // namespace fa
