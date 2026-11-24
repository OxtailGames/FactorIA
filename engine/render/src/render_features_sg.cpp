// TRANSITIONAL (M77-P2..P5): feature_env_from_sokol() for the code that reaches the GPU through sokol directly. It
// goes with the last caller; render_features.cpp asks a gpu::Device and does not include sokol_gfx.h.
#include "gpu/sg_bridge.h"
#include "render_features.h"
#include "sokol_gfx.h"

namespace fa::render {

FeatureEnv feature_env_from_sokol() {
    return feature_env_from_queries(
        gpu::backend_from_sg(sg_query_backend()), gpu::from_sg(sg_query_limits()), sg_query_features().compute,
        [](gpu::PixelFormat f) { return gpu::from_sg(sg_query_pixelformat(gpu::to_sg(f))); },
        sg_isvalid() ? sg_mtl_device() : nullptr);
}

}  // namespace fa::render
