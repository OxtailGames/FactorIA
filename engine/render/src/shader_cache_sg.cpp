// TRANSITIONAL (M77-P2..P5): make_shader for the call sites that still build sokol descs and hold sg_shader. It runs
// the same cache layer as the gpu::Device version (shader_cache.cpp) on the open sokol context. Goes away with the
// last sg_shader of the renderer (M77-P5).
#include "gpu/sg_bridge.h"
#include "shader_cache.h"

namespace fa::render {

sg_shader make_shader(const sg_shader_desc* desc, const char* label) {
    if (!desc) return sg_shader{};
    const gpu::ShaderDesc d = gpu::from_sg(*desc);
    const gpu::Shader made =
        make_shader_via(gpu::backend_from_sg(sg_query_backend()), d, label, [&](const gpu::ShaderDesc* prepared) {
            if (!prepared) return gpu::from_sg(sg_make_shader(desc));  // sokol's own desc, untouched
            const sg_shader_desc s = gpu::to_sg(*prepared);
            return gpu::from_sg(sg_make_shader(&s));
        });
    return gpu::to_sg(made);
}

}  // namespace fa::render
