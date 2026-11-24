// The sokol context's lifecycle (gpu/sokol_context.h) and the generated shader descs (gpu/sokol_shaders.h): the calls
// into sokol the renderer makes while no gpu::Device exists, kept with the sokol backend's files.
#include "gpu/sokol_context.h"

#include "fa/core/log.h"
#include "fa/core/types.h"
#include "fa/platform/app.h"
#include "gpu/device.h"
#include "gpu/sokol_device.h"
#include "gpu/sokol_shaders.h"

#if defined(__APPLE__)
#include <TargetConditionals.h>
#endif

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

EnvironmentDefaults environment_defaults_of(const GfxEnvironment& env) { return from_sg(env.get().defaults); }

namespace {

// The sokol backend this binary was built with, as the generated headers name its dialect.
sg_backend built_sg_backend() {
#if defined(SOKOL_GLCORE)
    return SG_BACKEND_GLCORE;
#elif defined(SOKOL_GLES3)
    return SG_BACKEND_GLES3;
#elif defined(SOKOL_D3D11)
    return SG_BACKEND_D3D11;
#elif defined(SOKOL_METAL) && defined(TARGET_OS_SIMULATOR) && TARGET_OS_SIMULATOR
    return SG_BACKEND_METAL_SIMULATOR;
#elif defined(SOKOL_METAL) && defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
    return SG_BACKEND_METAL_IOS;
#elif defined(SOKOL_METAL)
    return SG_BACKEND_METAL_MACOS;
#else
    return SG_BACKEND_DUMMY;
#endif
}

sg_backend dialect_of(const Device& device) {
    switch (device.backend()) {
        case Backend::Gl: return SG_BACKEND_GLCORE;
        case Backend::Gles3:
        case Backend::WebGl2: return SG_BACKEND_GLES3;
        case Backend::D3d11:
        case Backend::D3d12: return SG_BACKEND_D3D11;  // D3D12 compiles the same HLSL 5 (to DXBC SM 5.1)
        case Backend::Metal:
            switch (device.info().metalTarget) {
                case MetalTarget::MacOs: return SG_BACKEND_METAL_MACOS;
                case MetalTarget::Ios: return SG_BACKEND_METAL_IOS;
                case MetalTarget::Simulator: return SG_BACKEND_METAL_SIMULATOR;
                case MetalTarget::None: break;
            }
            return built_sg_backend();
        case Backend::Vulkan: return SG_BACKEND_VULKAN;
        case Backend::Recording: break;
    }
    return sg_isvalid() ? sg_query_backend() : built_sg_backend();
}

}  // namespace

ShaderDesc generated_shader_desc(const Device& device, GeneratedShader fn) {
    FA_ASSERT(fn, "gpu::generated_shader_desc: no desc function");
    const sg_shader_desc* d = fn(dialect_of(device));
    if (!d) {
        FA_ERROR("render", "a built-in shader has no {} code in this build (its generated header lacks the dialect)",
                 backend_name(device.backend()));
        return ShaderDesc{};
    }
    return from_sg(*d);
}

}  // namespace fa::gpu
