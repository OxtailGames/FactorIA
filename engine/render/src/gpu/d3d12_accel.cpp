// The platform-neutral half of the D3D12 backend's ray tracing (M79 P1d): see gpu/d3d12_accel.h.
#include "gpu/d3d12_accel.h"

#include <cstring>

namespace fa::gpu::d3d12 {

namespace {

constexpr int kMaxReportedProblems = 4;  // a build of 100k bad geometries names the first few, not 100k lines

void add(std::string& what, const std::string& problem) {
    if (!what.empty()) what += "; ";
    what += problem;
}

std::uint64_t round_up(std::uint64_t v) {
    const std::uint64_t most = ~std::uint64_t(0) - (kAccelAlignment - 1);
    if (v > most) return most;  // saturates (a size no device answers)
    return (v + kAccelAlignment - 1) / kAccelAlignment * kAccelAlignment;
}

std::uint32_t read_u32(const std::uint8_t* p) {
    return std::uint32_t(p[0]) | std::uint32_t(p[1]) << 8 | std::uint32_t(p[2]) << 16 | std::uint32_t(p[3]) << 24;
}

}  // namespace

std::string rt_tier_name(int tier) {
    switch (tier) {
        case kRtTierNone: return "none";
        case 10: return "1.0";
        case 11: return "1.1";
        case 12: return "1.2";
        default: return "tier " + std::to_string(tier);
    }
}

std::string shader_model_name(int shaderModel) {
    if (shaderModel <= 0) return "unknown";
    return std::to_string(shaderModel >> 4) + "." + std::to_string(shaderModel & 0xF);
}

bool rt_caps_trace(const RtCaps& caps) {
    return caps.tier >= kRtTier1_1 && caps.shaderModel >= kShaderModel6_5 && caps.interfaces;
}

bool apply_rt_caps(const RtCaps& caps, Features& features, Limits& limits, std::string& why) {
    const bool trace = rt_caps_trace(caps);
    features.rayQuery = trace;
    features.accelerationStructure = trace;
    features.rayTracingPipeline = caps.tier >= kRtTier1_0;
    features.bufferDeviceAddress = true;
    limits.maxAccelInstances = trace ? kMaxTlasInstances : 0;
    limits.maxAccelGeometries = trace ? kMaxBlasGeometries : 0;
    limits.maxAccelPrimitives = trace ? kMaxBlasPrimitives : 0;
    why.clear();
    if (trace) return true;
    const std::string adapter = caps.adapter.empty() ? std::string("(no name)") : caps.adapter;
    why = "the d3d12 device on '" + adapter + "' has DXR tier " + rt_tier_name(caps.tier) + " and shader model " +
          shader_model_name(caps.shaderModel) + ": inline ray query needs DXR tier 1.1 and shader model 6.5";
    if (caps.tier >= kRtTier1_1 && caps.shaderModel >= kShaderModel6_5)
        why += ", and this D3D12 runtime gave no ID3D12Device5 (update Windows)";
    else
        why += " (update the GPU driver, or run on a DirectX 12 Ultimate GPU; WARP, the software device, has tier 1.1 "
               "only in some Windows versions)";
    return false;
}

InstanceDesc to_instance_desc(const AccelInstance& instance, std::uint64_t blasAddress) {
    InstanceDesc d;
    std::memcpy(d.transform, instance.transform, sizeof d.transform);
    d.idAndMask = (instance.customIndex & 0xFFFFFFu) | std::uint32_t(instance.mask) << 24;
    std::uint32_t flags = 0;
    if (instance.cullDisable) flags |= kInstanceFlagCullDisable;
    if (instance.opaque) flags |= kInstanceFlagForceOpaque;
    d.contributionAndFlags = flags << 24;  // InstanceContributionToHitGroupIndex 0: there are no hit groups
    d.blas = blasAddress;
    return d;
}

std::uint32_t build_flags(const AccelBuildFlags& flags, AccelKind kind, bool update) {
    std::uint32_t f = 0;
    if (flags.allowUpdate) f |= kBuildFlagAllowUpdate;
    if (flags.allowCompaction && kind == AccelKind::Blas) f |= kBuildFlagAllowCompaction;
    if (flags.preferFastBuild)
        f |= kBuildFlagPreferFastBuild;
    else if (flags.preferFastTrace)
        f |= kBuildFlagPreferFastTrace;
    if (update) f |= kBuildFlagPerformUpdate;
    return f;
}

AccelSizes round_sizes(std::uint64_t resultDataMax, std::uint64_t scratch, std::uint64_t updateScratch,
                       bool allowUpdate) {
    AccelSizes s;
    s.structure = round_up(resultDataMax);
    s.buildScratch = round_up(scratch);
    s.updateScratch = allowUpdate ? round_up(updateScratch) : 0;
    return s;
}

std::string check_geometries(std::span<const AccelTriangles> geometries, const Limits& limits,
                             std::uint64_t& primitives) {
    std::string what;
    primitives = 0;
    if (geometries.empty()) {
        add(what, "no geometries: a BLAS needs at least one triangle geometry");
        return what;
    }
    if (limits.maxAccelGeometries > 0 && geometries.size() > limits.maxAccelGeometries)
        add(what, std::to_string(geometries.size()) + " geometries are more than this device's limit " +
                      std::to_string(limits.maxAccelGeometries) +
                      " (Limits::maxAccelGeometries): merge meshes into fewer geometries, or build several BLASes");
    int problems = 0;
    for (std::size_t i = 0; i < geometries.size(); ++i) {
        const AccelTriangles& g = geometries[i];
        primitives += g.primitive_count();
        if (problems >= kMaxReportedProblems) continue;
        const std::string n = "geometries[" + std::to_string(i) + "]";
        const std::size_t before = what.size();
        if (g.vertexFormat != VertexFormat::Float3)
            add(what,
                n + ".vertexFormat is not Float3: three 32-bit floats are the one position format every backend takes");
        if (g.vertexStride < 12 || g.vertexStride % 4 != 0)
            add(what, n + ".vertexStride " + std::to_string(g.vertexStride) +
                          " is not a multiple of 4 that is at least 12 (the size of a Float3 position)");
        if (g.indexBuffer.valid()) {
            if (g.indexType != IndexType::Uint16 && g.indexType != IndexType::Uint32)
                add(what, n + " has an index buffer but indexType is not Uint16 or Uint32");
            if (g.indexCount % 3 != 0)
                add(what, n + ".indexCount " + std::to_string(g.indexCount) + " is not a multiple of 3");
        } else {
            if (g.indexType == IndexType::Uint16 || g.indexType == IndexType::Uint32)
                add(what, n + " names an indexType but no index buffer");
            if (g.vertexCount % 3 != 0)
                add(what, n + ".vertexCount " + std::to_string(g.vertexCount) +
                              " is not a multiple of 3 (a triangle list without an index buffer)");
        }
        if (g.primitive_count() == 0) add(what, n + " has no triangles");
        if (what.size() != before) ++problems;
    }
    if (limits.maxAccelPrimitives > 0 && primitives > limits.maxAccelPrimitives)
        add(what, std::to_string(primitives) + " triangles are more than this device's limit " +
                      std::to_string(limits.maxAccelPrimitives) + " (Limits::maxAccelPrimitives)");
    return what;
}

std::string accel_storage_copy_error(const std::string& label) {
    return "buffer '" + label +
           "' holds acceleration structures (usage.accelStorage): D3D12 keeps it in the acceleration structure state, "
           "which no write, copy or read takes";
}

bool is_dxil_container(const void* data, std::size_t size) {
    // The container: "DXBC", a 16-byte digest, the version (2 + 2 bytes), the total size, the part count, then one
    // 32-bit offset per part; each part starts with its four-character code and its size.
    constexpr std::size_t kHeader = 32;
    if (!data || size < kHeader) return false;
    const auto* p = static_cast<const std::uint8_t*>(data);
    if (std::memcmp(p, "DXBC", 4) != 0) return false;
    const std::uint32_t parts = read_u32(p + 28);
    if (parts > (size - kHeader) / 4) return false;
    for (std::uint32_t i = 0; i < parts; ++i) {
        const std::uint32_t at = read_u32(p + kHeader + std::size_t(i) * 4);
        if (at > size || size - at < 8) return false;
        if (std::memcmp(p + at, "DXIL", 4) == 0) return true;
    }
    return false;
}

}  // namespace fa::gpu::d3d12
