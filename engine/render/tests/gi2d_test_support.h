// What the 2D GI tests (gi2d_field_tests.cpp, gi2d_cascade_tests.cpp, origin_render_tests.cpp) say when their
// precondition, RGBA16F render targets that blend and filter, is missing on the GPU they run on.
#pragma once

#include <string>

#include "gi2d.h"
#include "gpu/device.h"

namespace fa::test {

// Empty when `device` has RGBA16F targets that render, blend and filter (render::Gi2dSystem::float_targets_ok).
// Otherwise what is missing, on which backend, and whether that backend may lack it (a case that skips) or never
// does (a bug to fix).
inline std::string gi2d_missing_targets(const gpu::Device& device) {
    if (render::Gi2dSystem::float_targets_ok(device)) return {};
    const gpu::PixelFormatCaps half = device.pixel_format_caps(gpu::PixelFormat::Rgba16F);
    const gpu::Backend api = device.backend();
    const bool mustHave = api == gpu::Backend::Gl || api == gpu::Backend::D3d11 || api == gpu::Backend::Metal;
    std::string what = std::string("the ") + gpu::backend_name(api) + " backend's RGBA16F format lacks:";
    if (!half.render) what += " render-target use;";
    if (!half.blend) what += " blending;";
    if (!half.filter) what += " linear filtering;";
    what += " the 2D global illumination field and cascades are RGBA16F targets that blend and filter, so ";
    what += mustHave ? "this backend must have them (a driver or CI machine without them is a bug to look at)"
                     : "this GPU (GLES3-class or headless) does not draw them and the case is skipped";
    return what;
}

}  // namespace fa::test
