// The sokol context's lifecycle (gpu/sokol_context.h) and the generated shader descs (gpu/sokol_shaders.h): the calls
// into sokol the renderer makes while no gpu::Device exists, kept with the sokol backend's files.
#include "gpu/sokol_context.h"

#include "fa/core/types.h"
#include "fa/platform/app.h"
#include "gpu/sokol_device.h"
#include "gpu/sokol_shaders.h"

namespace fa::gpu {

bool context_open() { return sg_isvalid(); }

bool open_context(const GfxEnvironment& env) {
    if (sg_isvalid()) return false;
    sg_desc sd = sokol_setup_desc(DeviceInit{});
    sd.environment = env.get();
    sg_setup(&sd);
    return sg_isvalid();
}

void close_context() {
    if (sg_isvalid()) sg_shutdown();
}

bool commit_context() {
    if (!sg_isvalid()) return false;
    sg_commit();
    return true;
}

Backend context_backend() { return sg_isvalid() ? backend_from_sg(sg_query_backend()) : Backend::Recording; }

NativeDevice context_native() { return sokol_native_device(); }

EnvironmentDefaults context_defaults() {
    if (!sg_isvalid()) return {};
    return from_sg(sg_query_desc().environment.defaults);
}

Swapchain swapchain_of(const GfxSwapchain& sc) { return from_sg(sc.get()); }

void begin_context_pass(const PassDesc& pass) {
    const sg_pass p = to_sg(pass);
    sg_begin_pass(&p);
}

void end_context_pass() { sg_end_pass(); }

ShaderDesc generated_shader_desc(GeneratedShader fn) {
    FA_ASSERT(fn, "gpu::generated_shader_desc: no desc function");
    const sg_shader_desc* d = fn(sg_query_backend());
    FA_ASSERT(d, "gpu::generated_shader_desc: the generated header has no desc for this backend");
    return from_sg(*d);
}

}  // namespace fa::gpu
