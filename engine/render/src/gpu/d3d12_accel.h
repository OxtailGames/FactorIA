// Private to fa_render: the platform-neutral half of the D3D12 backend's ray tracing (M79 P1d,
// docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, "Direct3D 12"). It compiles on every platform, so its tests run on
// every host: what the device's capabilities make of Features, Limits and the reason it gives, the bytes of a
// D3D12_RAYTRACING_INSTANCE_DESC, the build flags, the size rounding, the checks of a geometry list and the test that
// tells a DXIL container from a DXBC one. The D3D12 calls that use them are in d3d12_raytracing_win32.cpp.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>

#include "gpu/accel.h"
#include "gpu/types.h"

namespace fa::gpu::d3d12 {

// D3D12_RAYTRACING_TIER values (OPTIONS5.RaytracingTier).
inline constexpr int kRtTierNone = 0;
inline constexpr int kRtTier1_0 = 10;  // DXR 1.0: ray tracing pipelines only
inline constexpr int kRtTier1_1 = 11;  // DXR 1.1: inline RayQuery in any shader (what the engine uses)
// D3D_SHADER_MODEL_6_5: the first shader model with RayQuery (the kernels are cs_6_5).
inline constexpr int kShaderModel6_5 = 0x65;

// The API's own limits (D3D12_RAYTRACING_MAX_INSTANCES_PER_TOP_LEVEL_ACCELERATION_STRUCTURE,
// _MAX_GEOMETRIES_PER_BOTTOM_LEVEL_ACCELERATION_STRUCTURE, _MAX_PRIMITIVES_PER_BOTTOM_LEVEL_ACCELERATION_STRUCTURE).
inline constexpr std::uint32_t kMaxTlasInstances = 1u << 24;
inline constexpr std::uint32_t kMaxBlasGeometries = 1u << 24;
inline constexpr std::uint64_t kMaxBlasPrimitives = std::uint64_t(1) << 29;
// D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BYTE_ALIGNMENT: where a structure and a build's scratch memory start.
inline constexpr std::uint64_t kAccelAlignment = 256;
// D3D12_RAYTRACING_INSTANCE_DESCS_BYTE_ALIGNMENT and the alignment of a postbuild info's destination.
inline constexpr std::uint64_t kInstanceDescAlignment = 16;
inline constexpr std::uint64_t kPostbuildInfoAlignment = 8;

// What the device answered (d3d12_device_win32.cpp, init_caps).
struct RtCaps {
    int tier = kRtTierNone;   // OPTIONS5.RaytracingTier (kRtTierNone when the runtime has no OPTIONS5)
    int shaderModel = 0;      // the highest D3D_SHADER_MODEL the device takes (0x51 = 5.1, 0x65 = 6.5; 0 = unknown)
    bool interfaces = false;  // ID3D12Device5 was there (asked only at tier 1.1 and shader model 6.5)
    std::string adapter;      // the adapter's description, for the reason
};

// "none", "1.0", "1.1", "1.2" (an unknown value: "tier <n>").
std::string rt_tier_name(int tier);
// "6.5" for 0x65, "5.1" for 0x51, "unknown" for 0.
std::string shader_model_name(int shaderModel);
// Whether inline ray query runs with these capabilities (tier 1.1 or more, shader model 6.5 or more, the interfaces).
bool rt_caps_trace(const RtCaps& caps);
// Sets the ray tracing Features and Limits from `caps`: rayQuery and accelerationStructure when rt_caps_trace,
// rayTracingPipeline from tier 1.0 (reported, never used), bufferDeviceAddress always (every D3D12 buffer has a GPU
// virtual address), and the API's limits when it traces (0 otherwise). Returns rt_caps_trace; `why` gets the sentence
// Device::ray_tracing_status answers when it does not (the adapter, the tier and the shader model found, what is
// needed) and is cleared when it does.
bool apply_rt_caps(const RtCaps& caps, Features& features, Limits& limits, std::string& why);

// The 64 bytes of one D3D12_RAYTRACING_INSTANCE_DESC, as the GPU reads them: Transform[3][4], then InstanceID (bits 0
// to 23) and InstanceMask (24 to 31), then InstanceContributionToHitGroupIndex (0 to 23, always 0: no hit groups) and
// Flags (24 to 31), then the BLAS's GPU virtual address. d3d12_raytracing_win32.cpp checks the layout against the SDK's.
struct InstanceDesc {
    float transform[12]{};
    std::uint32_t idAndMask = 0;
    std::uint32_t contributionAndFlags = 0;
    std::uint64_t blas = 0;
};
static_assert(sizeof(InstanceDesc) == 64, "D3D12_RAYTRACING_INSTANCE_DESC is 64 bytes");

// D3D12_RAYTRACING_INSTANCE_FLAGS.
inline constexpr std::uint32_t kInstanceFlagCullDisable = 0x1;
inline constexpr std::uint32_t kInstanceFlagForceOpaque = 0x4;

// One instance as D3D12 takes it: the transform as it is (both are row-major 3x4), the custom index in 24 bits, the
// mask, FORCE_OPAQUE for `opaque` and TRIANGLE_CULL_DISABLE for `cullDisable`, and `blasAddress`.
InstanceDesc to_instance_desc(const AccelInstance& instance, std::uint64_t blasAddress);

// D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS.
inline constexpr std::uint32_t kBuildFlagAllowUpdate = 0x1;
inline constexpr std::uint32_t kBuildFlagAllowCompaction = 0x2;
inline constexpr std::uint32_t kBuildFlagPreferFastTrace = 0x4;
inline constexpr std::uint32_t kBuildFlagPreferFastBuild = 0x8;
inline constexpr std::uint32_t kBuildFlagPerformUpdate = 0x20;

// The flags of a size query (update false) or a build: ALLOW_UPDATE, ALLOW_COMPACTION (a BLAS only), PREFER_FAST_BUILD
// when preferFastBuild (it wins), else PREFER_FAST_TRACE when preferFastTrace, and PERFORM_UPDATE for a refit.
std::uint32_t build_flags(const AccelBuildFlags& flags, AccelKind kind, bool update);

// The sizes D3D12's prebuild info answered, each rounded up to kAccelAlignment; updateScratch is 0 when the flags do
// not allowUpdate.
AccelSizes round_sizes(std::uint64_t resultDataMax, std::uint64_t scratch, std::uint64_t updateScratch,
                       bool allowUpdate);

// The checks of a geometry list that need no buffer (the RecordingDevice's rules): at least one geometry, at most
// Limits::maxAccelGeometries, Float3 positions, a stride that is a multiple of 4 and at least 12, an index type with
// an index buffer and none without, a multiple of 3 indices (or vertices), triangles in every geometry and at most
// Limits::maxAccelPrimitives in all (the first few problems are named). "" when it is fine; `primitives` gets the
// triangle count either way.
std::string check_geometries(std::span<const AccelTriangles> geometries, const Limits& limits,
                             std::uint64_t& primitives);

// The error of a write, copy or read of a buffer made with usage.accelStorage (D3D12 keeps it in the acceleration
// structure state, which no copy may use): names `label`. kAccelStorageCopyHint says what to do instead.
std::string accel_storage_copy_error(const std::string& label);
inline constexpr const char* kAccelStorageCopyHint =
    "copy a structure with copy_accel_structure, and keep data the CPU writes or reads in another buffer";

// Whether `data` is a DXBC container (the "DXBC" magic) with a DXIL part: shader model 6 bytecode from DXC. A shader
// model 5 container has a SHEX or SHDR part instead. A container whose part table runs past `size` is not DXIL.
bool is_dxil_container(const void* data, std::size_t size);

}  // namespace fa::gpu::d3d12
