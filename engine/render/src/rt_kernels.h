// The engine's ray tracing kernels (M79, inline ray query only), one blob per backend: the DXIL (D3D12, cs_6_5) and the SPIR-V
// (Vulkan, SPV_KHR_ray_query) DXC made from engine/render/shaders/rt/<name>.hlsl, and the MSL text (Metal, MSL 2.4) of the .metal
// twin, which the renderer compiles at run time. The blobs are in the generated headers engine/render/src/shaders/rt/<name>.rt.h
// (tools/shaders/compile_rt_shaders.sh; docs/design/ARCHITECTURE_RENDERING_RAYTRACING_SHADERS.md). A new kernel adds its header here
// and one row to `all_rt_kernels()`.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string_view>

#include "shaders/rt/rt_ao.rt.h"
#include "shaders/rt/rt_bake.rt.h"
#include "shaders/rt/rt_probe.rt.h"
#include "shaders/rt/rt_reflect.rt.h"
#include "shaders/rt/rt_refract.rt.h"
#include "shaders/rt/rt_shadow.rt.h"
#include "shaders/rt/rt_shadow_pack.rt.h"

namespace fa::rt_kernels {

struct RtKernel {
    std::string_view name;                // "rt_probe": the file name, and the kernel function of the MSL
    std::span<const std::uint8_t> dxil;   // a DXBC container holding signed DXIL; entry point "main"
    std::span<const std::uint8_t> spirv;  // SPIR-V words (little endian bytes); entry point "main"
    std::string_view msl;                 // the Metal source text; the kernel function is `name`
    std::string_view dxcVersion;          // the DXC release that made the dxil and spirv blobs
    std::string_view hlslSha256;          // of the .hlsl they were made from
    std::string_view mslSha256;           // of the .metal the msl text is
};

inline std::span<const RtKernel> all_rt_kernels() {
    static const RtKernel kernels[] = {
        {"rt_probe", kRtProbeDxil, kRtProbeSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtProbeMsl), sizeof(kRtProbeMsl) - 1), kRtProbeDxcVersion,
         kRtProbeHlslSha256, kRtProbeMslSha256},
        {"rt_reflect", kRtReflectDxil, kRtReflectSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtReflectMsl), sizeof(kRtReflectMsl) - 1),
         kRtReflectDxcVersion, kRtReflectHlslSha256, kRtReflectMslSha256},
        {"rt_shadow", kRtShadowDxil, kRtShadowSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtShadowMsl), sizeof(kRtShadowMsl) - 1), kRtShadowDxcVersion,
         kRtShadowHlslSha256, kRtShadowMslSha256},
        {"rt_shadow_pack", kRtShadowPackDxil, kRtShadowPackSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtShadowPackMsl), sizeof(kRtShadowPackMsl) - 1),
         kRtShadowPackDxcVersion, kRtShadowPackHlslSha256, kRtShadowPackMslSha256},
        {"rt_ao", kRtAoDxil, kRtAoSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtAoMsl), sizeof(kRtAoMsl) - 1), kRtAoDxcVersion,
         kRtAoHlslSha256, kRtAoMslSha256},
        {"rt_bake", kRtBakeDxil, kRtBakeSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtBakeMsl), sizeof(kRtBakeMsl) - 1), kRtBakeDxcVersion,
         kRtBakeHlslSha256, kRtBakeMslSha256},
        {"rt_refract", kRtRefractDxil, kRtRefractSpirv,
         std::string_view(reinterpret_cast<const char*>(kRtRefractMsl), sizeof(kRtRefractMsl) - 1),
         kRtRefractDxcVersion, kRtRefractHlslSha256, kRtRefractMslSha256},
    };
    return kernels;
}

inline const RtKernel* find_rt_kernel(std::string_view name) {
    for (const RtKernel& k : all_rt_kernels())
        if (k.name == name) return &k;
    return nullptr;
}

}  // namespace fa::rt_kernels
