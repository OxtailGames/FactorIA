// The Vulkan backend's acceleration structures (M79; ARCHITECTURE_RENDERING_RAYTRACING.md, "Vulkan"): sizes, structures,
// BLAS and TLAS builds and refits, compaction and copies through VK_KHR_acceleration_structure, with the barriers derived
// from each call's inputs. The checks mirror RecordingDevice's (recording_device.cpp), plus what Vulkan itself asks for
// (aligned vertex and index addresses, a refit that keeps the build's flags and geometries).
#include "gpu/vulkan_device.h"

#if defined(FA_VULKAN_BACKEND)

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace fa::gpu::vk {

namespace {

constexpr std::uint64_t kAccelAlign = 256;  // Device::accel_alignment(): where a structure starts in its buffer
constexpr std::uint32_t kMaxCustomIndex = 0xFFFFFFu;  // 24 bits
constexpr int kMaxReportedProblems = 8;               // per list of geometries or instances

constexpr VkPipelineStageFlags2 kBuildStage = VK_PIPELINE_STAGE_2_ACCELERATION_STRUCTURE_BUILD_BIT_KHR;
constexpr VkAccessFlags2 kAccelRead = VK_ACCESS_2_ACCELERATION_STRUCTURE_READ_BIT_KHR;
constexpr VkAccessFlags2 kAccelWrite = VK_ACCESS_2_ACCELERATION_STRUCTURE_WRITE_BIT_KHR;

void add(std::string& what, const std::string& problem) {
    if (!what.empty()) what += "; ";
    what += problem;
}

std::string quoted(const std::string& s) { return "'" + s + "'"; }

std::string label_text(const char* label) { return label && *label ? std::string(label) : std::string("(no label)"); }

std::string accel_label(const std::string& label, AccelKind kind) {
    return std::string(kind == AccelKind::Tlas ? "TLAS " : "BLAS ") + quoted(label);
}

std::string geometry_name(std::size_t i) { return "geometries[" + std::to_string(i) + "]"; }

const char* pass_text(PassState s) {
    switch (s) {
        case PassState::None: return "outside a pass";
        case PassState::Render: return "inside a render pass";
        case PassState::Compute: return "inside a compute pass";
    }
    return "?";
}

// The answer of every call on a device without ray tracing: the reason ray_tracing_status() gives (what the device
// lacks, and its name).
Error refusal(const VulkanDevice& device, const char* call) {
    std::string why;
    device.ray_tracing_status(&why);
    return Error{std::string("gpu vulkan: ") + call + ": " + why,
                 "check Device::features().accelerationStructure && rayQuery before building acceleration structures "
                 "(renderer.supports(\"raytracing\") says it with a reason), and draw without ray tracing when it is "
                 "false"};
}

VkBuildAccelerationStructureFlagsKHR vk_build_flags(const AccelBuildFlags& f, AccelKind kind) {
    VkBuildAccelerationStructureFlagsKHR v = 0;
    if (f.allowUpdate) v |= VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_KHR;
    if (f.allowCompaction && kind == AccelKind::Blas) v |= VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_COMPACTION_BIT_KHR;
    // preferFastBuild wins over preferFastTrace (Vulkan forbids both)
    if (f.preferFastBuild)
        v |= VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_BUILD_BIT_KHR;
    else if (f.preferFastTrace)
        v |= VK_BUILD_ACCELERATION_STRUCTURE_PREFER_FAST_TRACE_BIT_KHR;
    return v;
}

std::uint32_t index_width(IndexType t) { return t == IndexType::Uint16 ? 2u : 4u; }

// What a refit must keep of geometry `g` (besides its triangle count): its highest vertex, index type and opaque flag.
std::uint64_t geometry_shape(const AccelTriangles& g) {
    const std::uint64_t index = g.indexBuffer.valid() ? (g.indexType == IndexType::Uint16 ? 1u : 2u) : 0u;
    return std::uint64_t(g.vertexCount) << 8 | index << 1 | (g.opaque ? 1u : 0u);
}

// The Vulkan geometry of `g` at device addresses `vertex` and `index` (0 for a size query).
VkAccelerationStructureGeometryKHR triangles_geometry(const AccelTriangles& g, VkDeviceAddress vertex,
                                                      VkDeviceAddress index) {
    VkAccelerationStructureGeometryKHR out{};
    out.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR;
    out.geometryType = VK_GEOMETRY_TYPE_TRIANGLES_KHR;
    out.flags = g.opaque ? VkGeometryFlagsKHR(VK_GEOMETRY_OPAQUE_BIT_KHR) : VkGeometryFlagsKHR(0);
    VkAccelerationStructureGeometryTrianglesDataKHR t{};
    t.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_TRIANGLES_DATA_KHR;
    t.vertexFormat = VK_FORMAT_R32G32B32_SFLOAT;
    t.vertexData.deviceAddress = vertex;
    t.vertexStride = g.vertexStride;
    t.maxVertex = g.vertexCount > 0 ? g.vertexCount - 1 : 0;
    t.indexType = !g.indexBuffer.valid()             ? VK_INDEX_TYPE_NONE_KHR
                  : g.indexType == IndexType::Uint16 ? VK_INDEX_TYPE_UINT16
                                                     : VK_INDEX_TYPE_UINT32;
    t.indexData.deviceAddress = index;
    out.geometry.triangles = t;
    return out;
}

VkAccelerationStructureGeometryKHR instances_geometry(VkDeviceAddress instances) {
    VkAccelerationStructureGeometryKHR out{};
    out.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_KHR;
    out.geometryType = VK_GEOMETRY_TYPE_INSTANCES_KHR;
    VkAccelerationStructureGeometryInstancesDataKHR i{};
    i.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_GEOMETRY_INSTANCES_DATA_KHR;
    i.arrayOfPointers = VK_FALSE;
    i.data.deviceAddress = instances;
    out.geometry.instances = i;
    return out;
}

VkAccelerationStructureBuildGeometryInfoKHR build_info(AccelKind kind, VkBuildAccelerationStructureFlagsKHR flags,
                                                       const VkAccelerationStructureGeometryKHR* geometries,
                                                       std::uint32_t count) {
    VkAccelerationStructureBuildGeometryInfoKHR info{};
    info.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_GEOMETRY_INFO_KHR;
    info.type = kind == AccelKind::Tlas ? VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR
                                        : VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;
    info.flags = flags;
    info.mode = VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
    info.geometryCount = count;
    info.pGeometries = geometries;
    return info;
}

// The checks of a geometry list that need no buffer (sizes and builds); adds the problems to `what`.
void check_geometry_list(std::string& what, std::span<const AccelTriangles> geometries, const Limits& limits,
                         std::uint64_t& primitives) {
    primitives = 0;
    if (geometries.empty()) {
        add(what, "no geometries: a BLAS needs at least one triangle geometry");
        return;
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
        const std::string n = geometry_name(i);
        const std::size_t before = what.size();
        if (g.vertexFormat != VertexFormat::Float3)
            add(what,
                n + ".vertexFormat is not Float3: three 32-bit floats are the one position format every backend takes");
        if (g.vertexStride < 12 || g.vertexStride % 4 != 0)
            add(what, n + ".vertexStride " + std::to_string(g.vertexStride) +
                          " is not a multiple of 4 that is at least 12 (the size of a Float3 position)");
        if (g.vertexOffset % 4 != 0)
            add(what, n + ".vertexOffset " + std::to_string(g.vertexOffset) +
                          " is not a multiple of 4 (Vulkan reads positions at 4-byte aligned addresses)");
        if (g.indexBuffer.valid()) {
            if (g.indexType != IndexType::Uint16 && g.indexType != IndexType::Uint32)
                add(what, n + " has an index buffer but indexType is not Uint16 or Uint32");
            else if (g.indexOffset % index_width(g.indexType) != 0)
                add(what, n + ".indexOffset " + std::to_string(g.indexOffset) +
                              " is not a multiple of the index size " + std::to_string(index_width(g.indexType)));
            if (g.indexCount % 3 != 0)
                add(what, n + ".indexCount " + std::to_string(g.indexCount) + " is not a multiple of 3");
            if (g.vertexCount == 0) add(what, n + ".vertexCount is 0: an indexed geometry gives its highest index + 1");
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
}

// The resources one build or copy uses, each once with the stages and accesses of all its uses merged (a structure and
// its scratch may share a buffer).
class BuildUses {
public:
    void add(const std::shared_ptr<TrackedResource>& r, VkPipelineStageFlags2 stages, VkAccessFlags2 access) {
        if (!r) return;
        auto [it, fresh] = index_.try_emplace(r.get(), uses_.size());
        if (fresh) {
            uses_.push_back({r, stages, access});
        } else {
            uses_[it->second].stages |= stages;
            uses_[it->second].access |= access;
        }
    }
    void require_all(VulkanCommandList& list) const {
        for (const Use& u : uses_) list.require(u.res, 0, SubState{VK_IMAGE_LAYOUT_UNDEFINED, u.stages, u.access});
    }

private:
    struct Use {
        std::shared_ptr<TrackedResource> res;
        VkPipelineStageFlags2 stages = 0;
        VkAccessFlags2 access = 0;
    };
    std::vector<Use> uses_;
    std::unordered_map<TrackedResource*, std::size_t> index_;
};

}  // namespace

std::uint32_t fill_ray_tracing_caps(bool rayTracing, bool rayTracingPipeline,
                                    const VkPhysicalDeviceAccelerationStructurePropertiesKHR& props, Features& f,
                                    Limits& l) {
    f.rayQuery = rayTracing;
    f.accelerationStructure = rayTracing;
    f.bufferDeviceAddress = rayTracing;
    f.rayTracingPipeline = rayTracingPipeline;
    l.maxAccelInstances = rayTracing ? std::uint32_t(std::min<std::uint64_t>(props.maxInstanceCount, 0xFFFFFFFFu)) : 0u;
    l.maxAccelGeometries =
        rayTracing ? std::uint32_t(std::min<std::uint64_t>(props.maxGeometryCount, 0xFFFFFFFFu)) : 0u;
    l.maxAccelPrimitives = rayTracing ? props.maxPrimitiveCount : 0u;
    return rayTracing ? std::max<std::uint32_t>(std::uint32_t(kAccelAlign),
                                                props.minAccelerationStructureScratchOffsetAlignment)
                      : std::uint32_t(kAccelAlign);
}

// ---- the device's calls ---------------------------------------------------------------------------------------------

bool VulkanDevice::ray_tracing_status(std::string* why) const {
    if (!rayTracing_ && why) *why = rtWhy_;
    return rayTracing_;
}

AccelSizes VulkanDevice::build_sizes(const VkAccelerationStructureBuildGeometryInfoKHR& info,
                                     const std::uint32_t* maxPrimitives) const {
    VkAccelerationStructureBuildSizesInfoKHR s{};
    s.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR;
    fn_.vkGetAccelerationStructureBuildSizesKHR(device_, VK_ACCELERATION_STRUCTURE_BUILD_TYPE_DEVICE_KHR, &info,
                                                maxPrimitives, &s);
    AccelSizes out;
    out.structure = align_up(s.accelerationStructureSize, kAccelAlign);
    out.buildScratch = align_up(s.buildScratchSize, scratchAlign_);
    out.updateScratch = (info.flags & VK_BUILD_ACCELERATION_STRUCTURE_ALLOW_UPDATE_BIT_KHR) != 0
                            ? align_up(std::max<VkDeviceSize>(s.updateScratchSize, 1), scratchAlign_)
                            : 0;
    return out;
}

VkDeviceAddress VulkanDevice::buffer_address(VkBuffer buffer) const {
    VkBufferDeviceAddressInfo ai{};
    ai.sType = VK_STRUCTURE_TYPE_BUFFER_DEVICE_ADDRESS_INFO;
    ai.buffer = buffer;
    return fn_.vkGetBufferDeviceAddress(device_, &ai);
}

Result<AccelSizes> VulkanDevice::blas_sizes(std::span<const AccelTriangles> geometries, const AccelBuildFlags& flags) {
    if (!rayTracing_) return refusal(*this, "Device::blas_sizes");
    std::string what;
    std::uint64_t primitives = 0;
    check_geometry_list(what, geometries, limits_, primitives);
    if (!what.empty()) {
        const std::string fix = "give 1 to Limits::maxAccelGeometries triangle geometries (Float3 positions, a "
                                "multiple of 3 indices) with at most Limits::maxAccelPrimitives triangles in all";
        report("gpu vulkan: Device::blas_sizes: " + what + " (hint: " + fix + ")");
        return make_error("gpu vulkan: Device::blas_sizes: " + what, fix);
    }
    std::vector<VkAccelerationStructureGeometryKHR> geos;
    std::vector<std::uint32_t> counts;
    geos.reserve(geometries.size());
    counts.reserve(geometries.size());
    for (const AccelTriangles& g : geometries) {
        geos.push_back(triangles_geometry(g, 0, 0));
        counts.push_back(std::uint32_t(g.primitive_count()));
    }
    const auto info =
        build_info(AccelKind::Blas, vk_build_flags(flags, AccelKind::Blas), geos.data(), std::uint32_t(geos.size()));
    return build_sizes(info, counts.data());
}

Result<AccelSizes> VulkanDevice::tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags) {
    if (!rayTracing_) return refusal(*this, "Device::tlas_sizes");
    std::string what;
    if (instanceCount == 0) add(what, "0 instances: skip the TLAS build when the scene has no instances");
    if (limits_.maxAccelInstances > 0 && instanceCount > limits_.maxAccelInstances)
        add(what, std::to_string(instanceCount) + " instances are more than this device's limit " +
                      std::to_string(limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    if (!what.empty()) {
        const std::string fix = "ask for 1 to Limits::maxAccelInstances instances";
        report("gpu vulkan: Device::tlas_sizes: " + what + " (hint: " + fix + ")");
        return make_error("gpu vulkan: Device::tlas_sizes: " + what, fix);
    }
    const VkAccelerationStructureGeometryKHR geo = instances_geometry(0);
    const auto info = build_info(AccelKind::Tlas, vk_build_flags(flags, AccelKind::Tlas), &geo, 1);
    return build_sizes(info, &instanceCount);
}

Result<AccelStructure> VulkanDevice::make_accel_structure(const AccelStructureDesc& d) {
    if (!rayTracing_) return refusal(*this, "Device::make_accel_structure");
    const std::string label = label_text(d.label);
    const std::string at = "gpu vulkan: Device::make_accel_structure '" + label + "': ";
    const std::string fix = "size the structure from blas_sizes() / tlas_sizes(), and place it in a live buffer with "
                            "usage.accelStorage (or leave storage empty)";
    std::string what;
    AccelRecord rec;
    rec.kind = d.kind;
    rec.size = std::size_t(d.size);
    rec.label = label;
    if (d.size == 0) add(what, "AccelStructureDesc::size is 0: take it from blas_sizes() / tlas_sizes()");
    if (d.storage.valid()) {
        std::lock_guard<std::mutex> lock(resMutex_);
        const BufferRecord* b = buffers_.get(d.storage.id);
        if (!b || !b->tracked) {
            add(what, "storage is buffer " + std::to_string(d.storage.id) +
                          (b ? ", whose creation failed" : ", which names no live buffer"));
        } else {
            if (!b->usage.accelStorage)
                add(what, "storage buffer " + quoted(b->label) + " was not made with usage.accelStorage");
            if (d.storageOffset % kAccelAlign != 0)
                add(what, "storageOffset " + std::to_string(d.storageOffset) + " is not a multiple of " +
                              std::to_string(kAccelAlign) + " (Device::accel_alignment())");
            if (d.storageOffset > b->size || d.size > b->size - d.storageOffset)
                add(what, std::to_string(d.size) + " bytes at offset " + std::to_string(d.storageOffset) +
                              " do not fit in buffer " + quoted(b->label) + " (" + std::to_string(b->size) + " bytes)");
            rec.tracked = b->tracked;
        }
    } else if (d.storageOffset != 0) {
        add(what, "storageOffset is set but storage is not");
    }
    if (!what.empty()) {
        report(at + what + " (hint: " + fix + ")");
        return make_error(at + what, fix);
    }
    std::string error;
    if (!rec.tracked) {
        rec.tracked = make_raw_buffer(align_up(d.size, kAccelAlign),
                                      VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_STORAGE_BIT_KHR |
                                          VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT,
                                      MemoryUse::GpuOnly, false, label.c_str(), error);
        if (!rec.tracked) {
            report(at + "its storage: " + error);
            return make_error(at + "its storage: " + error, "free GPU memory, or make fewer or smaller structures");
        }
    }
    VkAccelerationStructureCreateInfoKHR ci{};
    ci.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_CREATE_INFO_KHR;
    ci.buffer = rec.tracked->buffer;
    ci.offset = d.storage.valid() ? VkDeviceSize(d.storageOffset) : 0;
    ci.size = d.size;
    ci.type = d.kind == AccelKind::Tlas ? VK_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL_KHR
                                        : VK_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL_KHR;
    const VkResult r = fn_.vkCreateAccelerationStructureKHR(device_, &ci, nullptr, &rec.handle);
    if (r != VK_SUCCESS) {
        rec.handle = VK_NULL_HANDLE;
        const std::string e = "vkCreateAccelerationStructureKHR failed with " + result_text(r);
        report(at + e);
        return make_error(at + e, "the validation layer (VulkanOptions::validation) says which field is wrong");
    }
    set_name(VK_OBJECT_TYPE_ACCELERATION_STRUCTURE_KHR, handle_bits(rec.handle), label.c_str());
    VkAccelerationStructureDeviceAddressInfoKHR ai{};
    ai.sType = VK_STRUCTURE_TYPE_ACCELERATION_STRUCTURE_DEVICE_ADDRESS_INFO_KHR;
    ai.accelerationStructure = rec.handle;
    rec.address = fn_.vkGetAccelerationStructureDeviceAddressKHR(device_, &ai);
    const VkAccelerationStructureKHR handle = rec.handle;
    std::unique_lock<std::mutex> lock(resMutex_);
    const std::uint32_t id = accels_.add(std::move(rec));
    if (id == 0) {
        const int capacity = accels_.capacity();
        lock.unlock();
        fn_.vkDestroyAccelerationStructureKHR(device_, handle, nullptr);  // never used by the GPU
        const std::string e = "the acceleration structure pool is full (" + std::to_string(capacity) + ")";
        const std::string poolFix = "destroy structures no longer used, or raise DeviceInit::bufferPoolSize";
        report(at + e + " (hint: " + poolFix + ")");
        return make_error(at + e, poolFix);
    }
    return AccelStructure{id};
}

void VulkanDevice::destroy_accel_structure(AccelStructure accel) {
    if (!accel.valid()) return;
    AccelRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!accels_.remove(accel.id, rec)) {
            report("gpu vulkan: destroy_accel_structure: acceleration structure " + std::to_string(accel.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
    }
    // Released once the frames that may trace it or build from it are done: the structure first, then its storage.
    Deferred d;
    d.accel = rec.handle;
    d.tracked = std::move(rec.tracked);
    defer(std::move(d));
    if (rec.instanceBuffer) {
        Deferred i;
        i.tracked = std::move(rec.instanceBuffer);
        defer(std::move(i));
    }
}

ResourceState VulkanDevice::accel_structure_state(AccelStructure accel) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const AccelRecord* r = accels_.get(accel.id);
    if (!r) return ResourceState::Invalid;
    return r->handle ? ResourceState::Valid : ResourceState::Failed;
}

// ---- the list's calls -----------------------------------------------------------------------------------------------

Error VulkanCommandList::reject(const char* what, const std::string& problem, const std::string& fix) {
    fail(what, problem + " (hint: " + fix + ")");
    return Error{std::string("gpu vulkan: CommandList::") + what + " in list '" + label_ + "': " + problem, fix};
}

std::string VulkanCommandList::accel_command_problem(std::string& fix) const {
    if (!open_ || !cmd_) {
        fix = "take a new list with begin_commands() each frame";
        return "the list is not recording (it was submitted)";
    }
    if (nativeOpen_) {
        fix = "end_native() first";
        return "a native section is open";
    }
    if (passState_ != PassState::None) {
        fix = "end_pass() first, or record it before begin_pass()";
        return std::string("called ") + pass_text(passState_) + "; it goes outside a pass";
    }
    if (queue_ == QueueKind::Transfer) {
        fix = "record acceleration structure commands on a QueueKind::Graphics or Compute list";
        return "the list runs on the transfer queue, which takes copies, writes and markers only";
    }
    return {};
}

Result<void> VulkanCommandList::build_blas(const BlasBuild& b) {
    const char* cmd = "build_blas";
    if (!device_.rayTracing_) return refusal(device_, "CommandList::build_blas");
    std::string fix;
    const std::string problem = accel_command_problem(fix);
    if (!problem.empty()) return reject(cmd, problem, fix);

    std::string what;
    std::uint64_t primitives = 0;
    check_geometry_list(what, b.geometries, device_.limits_, primitives);
    const std::size_t n = b.geometries.size();
    const VkBuildAccelerationStructureFlagsKHR flags = vk_build_flags(b.flags, AccelKind::Blas);
    BuildUses uses;
    std::vector<VkAccelerationStructureGeometryKHR> geos;
    std::vector<VkAccelerationStructureBuildRangeInfoKHR> ranges;
    std::vector<std::uint32_t> counts;
    std::vector<std::uint64_t> shapes;
    VkAccelerationStructureKHR dstHandle = VK_NULL_HANDLE, srcHandle = VK_NULL_HANDLE;
    VkDeviceAddress scratchAddress = 0;
    std::unique_lock<std::mutex> lock(device_.resMutex_);
    VulkanDevice::AccelRecord* dst = device_.accels_.get(b.dst.id);
    if (!dst || !dst->handle)
        add(what, "dst is acceleration structure " + std::to_string(b.dst.id) +
                      (dst ? ", whose creation failed" : ", which names no live structure"));
    else if (dst->kind != AccelKind::Blas)
        add(what, "dst " + accel_label(dst->label, dst->kind) +
                      " is a TLAS: build_blas writes a BLAS (build_tlas builds a TLAS)");
    int problems = 0;
    for (std::size_t i = 0; i < n && problems < kMaxReportedProblems; ++i) {
        const AccelTriangles& g = b.geometries[i];
        const std::string name = geometry_name(i);
        const std::size_t before = what.size();
        VkDeviceAddress vertex = 0, index = 0;
        const VulkanDevice::BufferRecord* vb = device_.buffers_.get(g.vertexBuffer.id);
        if (!vb || !vb->tracked) {
            add(what, name + ".vertexBuffer is buffer " + std::to_string(g.vertexBuffer.id) +
                          (vb ? ", whose creation failed" : ", which names no live buffer"));
        } else {
            if (!vb->usage.accelBuildInput)
                add(what, name + ".vertexBuffer " + quoted(vb->label) + " was not made with usage.accelBuildInput");
            const std::uint64_t need = g.vertexCount == 0 ? 0
                                                          : std::uint64_t(g.vertexOffset) +
                                                                std::uint64_t(g.vertexCount - 1) * g.vertexStride + 12;
            if (need > vb->size)
                add(what, name + " reads " + std::to_string(g.vertexCount) + " vertices up to byte " +
                              std::to_string(need) + ", but vertex buffer " + quoted(vb->label) + " has " +
                              std::to_string(vb->size) + " bytes");
            uses.add(vb->tracked, kBuildStage, VK_ACCESS_2_SHADER_READ_BIT);
            // Only a buffer made with usage.accelBuildInput has a device address (VUID-VkBufferDeviceAddressInfo-
            // buffer-02601); one without is reported above and the build never runs.
            if (vb->usage.accelBuildInput) vertex = device_.buffer_address(vb->tracked->buffer) + g.vertexOffset;
        }
        if (g.indexBuffer.valid()) {
            const VulkanDevice::BufferRecord* ib = device_.buffers_.get(g.indexBuffer.id);
            if (!ib || !ib->tracked) {
                add(what, name + ".indexBuffer is buffer " + std::to_string(g.indexBuffer.id) +
                              (ib ? ", whose creation failed" : ", which names no live buffer"));
            } else {
                if (!ib->usage.accelBuildInput)
                    add(what, name + ".indexBuffer " + quoted(ib->label) + " was not made with usage.accelBuildInput");
                const std::uint64_t need =
                    std::uint64_t(g.indexOffset) + std::uint64_t(g.indexCount) * index_width(g.indexType);
                if (need > ib->size)
                    add(what, name + " reads " + std::to_string(g.indexCount) + " indices up to byte " +
                                  std::to_string(need) + ", but index buffer " + quoted(ib->label) + " has " +
                                  std::to_string(ib->size) + " bytes");
                uses.add(ib->tracked, kBuildStage, VK_ACCESS_2_SHADER_READ_BIT);
                if (ib->usage.accelBuildInput) index = device_.buffer_address(ib->tracked->buffer) + g.indexOffset;
            }
        }
        geos.push_back(triangles_geometry(g, vertex, index));
        counts.push_back(std::uint32_t(std::min<std::uint64_t>(g.primitive_count(), 0xFFFFFFFFu)));
        shapes.push_back(geometry_shape(g));
        VkAccelerationStructureBuildRangeInfoKHR range{};
        range.primitiveCount = counts.back();
        ranges.push_back(range);
        if (what.size() != before) ++problems;
    }
    AccelSizes need;
    if (what.empty()) {
        need = device_.build_sizes(build_info(AccelKind::Blas, flags, geos.data(), std::uint32_t(n)), counts.data());
        if (dst->size < need.structure)
            add(what, "dst " + accel_label(dst->label, AccelKind::Blas) + " has " + std::to_string(dst->size) +
                          " bytes but these geometries need " + std::to_string(need.structure) +
                          " (AccelSizes::structure of blas_sizes with the same flags)");
    }
    if (b.update) {
        const AccelStructure srcId = b.src.valid() ? b.src : b.dst;
        const VulkanDevice::AccelRecord* src = device_.accels_.get(srcId.id);
        if (!src || !src->handle) {
            add(what, "src is acceleration structure " + std::to_string(srcId.id) +
                          (src ? ", whose creation failed" : ", which names no live structure"));
        } else if (src->kind != AccelKind::Blas) {
            add(what, "src " + accel_label(src->label, src->kind) + " is a TLAS: a BLAS refits from a BLAS");
        } else if (!src->built) {
            add(what, "update of " + accel_label(src->label, AccelKind::Blas) + ", which was never built");
        } else if (!src->allowUpdate) {
            add(what, "update of " + accel_label(src->label, AccelKind::Blas) +
                          ", which was built without flags.allowUpdate");
        } else if (src->primitiveCounts != counts || src->geometryShapes != shapes) {
            add(what, "update with " + std::to_string(n) + " geometries and " + std::to_string(primitives) +
                          " triangles that differ from what " + accel_label(src->label, AccelKind::Blas) +
                          " was built with (each geometry's triangle count, vertexCount, index type and opaque flag): "
                          "a refit keeps the topology and moves the vertices only");
        } else if (src->buildFlags != flags) {
            add(what, "update with other flags than " + accel_label(src->label, AccelKind::Blas) +
                          " was built with (pass the same AccelBuildFlags)");
        } else {
            srcHandle = src->handle;
            uses.add(src->tracked, kBuildStage, kAccelRead);
        }
        if (!b.flags.allowUpdate)
            add(what, "update with flags.allowUpdate false (pass the flags the BLAS was built with)");
    }
    const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
    const VulkanDevice::BufferRecord* scratch = device_.buffers_.get(b.scratch.id);
    if (!scratch || !scratch->tracked) {
        add(what, "scratch is buffer " + std::to_string(b.scratch.id) +
                      (scratch ? ", whose creation failed" : ", which names no live buffer"));
    } else {
        if (!scratch->usage.accelScratch)
            add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
        if (b.scratchOffset % device_.scratchAlign_ != 0)
            add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                          std::to_string(device_.scratchAlign_) + " (Device::accel_scratch_alignment())");
        if (b.scratchOffset > scratch->size || scratch->size - b.scratchOffset < scratchNeed)
            add(what, "scratch buffer " + quoted(scratch->label) + " has " +
                          std::to_string(scratch->size > b.scratchOffset ? scratch->size - b.scratchOffset : 0) +
                          " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                          (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                          " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
        uses.add(scratch->tracked, kBuildStage, kAccelRead | kAccelWrite);
        if (scratch->usage.accelScratch)  // no device address without it: reported above, the build never runs
            scratchAddress = device_.buffer_address(scratch->tracked->buffer) + b.scratchOffset;
    }
    if (!what.empty()) {
        lock.unlock();
        return reject(cmd, what,
                      "size the BLAS and the scratch buffer from blas_sizes() with the flags of the build, give every "
                      "geometry live buffers with usage.accelBuildInput, and refit only what was built with "
                      "allowUpdate, with the same flags and geometries");
    }
    dstHandle = dst->handle;
    uses.add(dst->tracked, kBuildStage, b.update && srcHandle == dstHandle ? kAccelRead | kAccelWrite : kAccelWrite);
    dst->built = true;
    dst->allowUpdate = b.flags.allowUpdate;
    dst->allowCompaction = b.flags.allowCompaction;
    dst->buildFlags = flags;
    dst->primitiveCounts = std::move(counts);
    dst->geometryShapes = std::move(shapes);
    lock.unlock();

    uses.require_all(*this);
    flush_barriers();
    VkAccelerationStructureBuildGeometryInfoKHR info =
        build_info(AccelKind::Blas, flags, geos.data(), std::uint32_t(n));
    info.mode =
        b.update ? VK_BUILD_ACCELERATION_STRUCTURE_MODE_UPDATE_KHR : VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
    info.srcAccelerationStructure = b.update ? srcHandle : VK_NULL_HANDLE;
    info.dstAccelerationStructure = dstHandle;
    info.scratchData.deviceAddress = scratchAddress;
    const VkAccelerationStructureBuildRangeInfoKHR* rangeList = ranges.data();
    device_.fn_.vkCmdBuildAccelerationStructuresKHR(cmd_, 1, &info, &rangeList);
    empty_ = false;
    return {};
}

Result<void> VulkanCommandList::build_tlas(const TlasBuild& b) {
    const char* cmd = "build_tlas";
    if (!device_.rayTracing_) return refusal(device_, "CommandList::build_tlas");
    std::string fix;
    const std::string problem = accel_command_problem(fix);
    if (!problem.empty()) return reject(cmd, problem, fix);

    std::string what;
    const std::size_t n = b.instances.size();
    const VkBuildAccelerationStructureFlagsKHR flags = vk_build_flags(b.flags, AccelKind::Tlas);
    if (n == 0) add(what, "no instances: skip the TLAS build when the scene has none");
    if (device_.limits_.maxAccelInstances > 0 && n > device_.limits_.maxAccelInstances)
        add(what, std::to_string(n) + " instances are more than this device's limit " +
                      std::to_string(device_.limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    const std::uint32_t count = std::uint32_t(std::min<std::size_t>(n, 0xFFFFFFFFu));
    BuildUses uses;
    std::vector<VkAccelerationStructureInstanceKHR> vkInstances(what.empty() ? n : 0);
    VkAccelerationStructureKHR srcHandle = VK_NULL_HANDLE;
    VkDeviceAddress scratchAddress = 0;
    std::unique_lock<std::mutex> lock(device_.resMutex_);
    VulkanDevice::AccelRecord* dst = device_.accels_.get(b.dst.id);
    if (!dst || !dst->handle)
        add(what, "dst is acceleration structure " + std::to_string(b.dst.id) +
                      (dst ? ", whose creation failed" : ", which names no live structure"));
    else if (dst->kind != AccelKind::Tlas)
        add(what, "dst " + accel_label(dst->label, dst->kind) +
                      " is a BLAS: build_tlas writes a TLAS (build_blas builds a BLAS)");
    int problems = 0;
    for (std::size_t i = 0; i < n && problems < kMaxReportedProblems; ++i) {
        const AccelInstance& in = b.instances[i];
        const std::string name = "instances[" + std::to_string(i) + "]";
        const std::size_t before = what.size();
        const VulkanDevice::AccelRecord* blas = device_.accels_.get(in.blas.id);
        if (!blas || !blas->handle)
            add(what, name + ".blas is acceleration structure " + std::to_string(in.blas.id) +
                          (blas ? ", whose creation failed" : ", which names no live structure") +
                          ": destroy a BLAS only after the TLAS that names it is no longer built");
        else if (blas->kind != AccelKind::Blas)
            add(what, name + ".blas is the " + accel_label(blas->label, blas->kind) +
                          ": an instance names a BLAS (a TLAS cannot nest)");
        else if (!blas->built)
            add(what, name + ".blas " + accel_label(blas->label, AccelKind::Blas) +
                          " was never built: record build_blas before build_tlas");
        if (in.customIndex > kMaxCustomIndex)
            add(what, name + ".customIndex " + std::to_string(in.customIndex) + " does not fit in 24 bits (at most " +
                          std::to_string(kMaxCustomIndex) + ")");
        for (float v : in.transform)
            if (!std::isfinite(v)) {
                add(what, name + ".transform has a NaN or infinite value");
                break;
            }
        if (what.size() != before) {
            ++problems;
            continue;
        }
        if (vkInstances.empty()) continue;
        // The BLAS is read by this build and, through the TLAS, by the traces after it: one barrier covers both
        // (a BLAS rebuilt or refit later is traced after the next build_tlas, which waits for it again).
        uses.add(blas->tracked, kBuildStage | VK_PIPELINE_STAGE_2_COMPUTE_SHADER_BIT, kAccelRead);
        VkAccelerationStructureInstanceKHR& v = vkInstances[i];
        std::memcpy(&v.transform, in.transform, sizeof(v.transform));
        v.instanceCustomIndex = in.customIndex & kMaxCustomIndex;
        v.mask = in.mask;
        v.instanceShaderBindingTableRecordOffset = 0;
        VkGeometryInstanceFlagsKHR f = 0;
        if (in.cullDisable) f |= VK_GEOMETRY_INSTANCE_TRIANGLE_FACING_CULL_DISABLE_BIT_KHR;
        if (in.opaque) f |= VK_GEOMETRY_INSTANCE_FORCE_OPAQUE_BIT_KHR;
        v.flags = f & 0xFFu;
        v.accelerationStructureReference = blas->address;
    }
    AccelSizes need;
    if (what.empty()) {
        const VkAccelerationStructureGeometryKHR geo = instances_geometry(0);
        need = device_.build_sizes(build_info(AccelKind::Tlas, flags, &geo, 1), &count);
        if (dst->size < need.structure)
            add(what, "dst " + accel_label(dst->label, AccelKind::Tlas) + " has " + std::to_string(dst->size) +
                          " bytes but " + std::to_string(n) + " instances need " + std::to_string(need.structure) +
                          " (AccelSizes::structure of tlas_sizes with the same flags)");
    }
    if (b.update) {
        const AccelStructure srcId = b.src.valid() ? b.src : b.dst;
        const VulkanDevice::AccelRecord* src = device_.accels_.get(srcId.id);
        if (!src || !src->handle) {
            add(what, "src is acceleration structure " + std::to_string(srcId.id) +
                          (src ? ", whose creation failed" : ", which names no live structure"));
        } else if (src->kind != AccelKind::Tlas) {
            add(what, "src " + accel_label(src->label, src->kind) + " is a BLAS: a TLAS refits from a TLAS");
        } else if (!src->built) {
            add(what, "update of " + accel_label(src->label, AccelKind::Tlas) + ", which was never built");
        } else if (!src->allowUpdate) {
            add(what, "update of " + accel_label(src->label, AccelKind::Tlas) +
                          ", which was built without flags.allowUpdate");
        } else if (src->instances != n) {
            add(what, "update with " + std::to_string(n) + " instances, but " +
                          accel_label(src->label, AccelKind::Tlas) + " was built with " +
                          std::to_string(src->instances) + ": a refit keeps the count");
        } else if (src->buildFlags != flags) {
            add(what, "update with other flags than " + accel_label(src->label, AccelKind::Tlas) +
                          " was built with (pass the same AccelBuildFlags)");
        } else {
            srcHandle = src->handle;
            uses.add(src->tracked, kBuildStage, kAccelRead);
        }
        if (!b.flags.allowUpdate)
            add(what, "update with flags.allowUpdate false (pass the flags the TLAS was built with)");
    }
    const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
    const VulkanDevice::BufferRecord* scratch = device_.buffers_.get(b.scratch.id);
    if (!scratch || !scratch->tracked) {
        add(what, "scratch is buffer " + std::to_string(b.scratch.id) +
                      (scratch ? ", whose creation failed" : ", which names no live buffer"));
    } else {
        if (!scratch->usage.accelScratch)
            add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
        if (b.scratchOffset % device_.scratchAlign_ != 0)
            add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                          std::to_string(device_.scratchAlign_) + " (Device::accel_scratch_alignment())");
        if (b.scratchOffset > scratch->size || scratch->size - b.scratchOffset < scratchNeed)
            add(what, "scratch buffer " + quoted(scratch->label) + " has " +
                          std::to_string(scratch->size > b.scratchOffset ? scratch->size - b.scratchOffset : 0) +
                          " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                          (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                          " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
        uses.add(scratch->tracked, kBuildStage, kAccelRead | kAccelWrite);
        if (scratch->usage.accelScratch)  // no device address without it: reported above, the build never runs
            scratchAddress = device_.buffer_address(scratch->tracked->buffer) + b.scratchOffset;
    }
    const std::string buildFix = "build every BLAS the instances name first (and keep it alive), size the TLAS and the "
                                 "scratch buffer from tlas_sizes() with the flags of the build, and keep the instance "
                                 "count within Limits::maxAccelInstances";
    if (!what.empty()) {
        lock.unlock();
        return reject(cmd, what, buildFix);
    }
    const VkAccelerationStructureKHR dstHandle = dst->handle;
    const std::shared_ptr<TrackedResource> dstTracked = dst->tracked;
    std::shared_ptr<TrackedResource> instanceBuffer = dst->instanceBuffer;
    const bool grow = dst->instanceCapacity < count;
    const std::string instanceLabel = dst->label + " instances";
    lock.unlock();

    // The instances go into the TLAS's own device-local buffer (grown here; the old one is released with the frame),
    // copied from the upload ring before the build. No device lock is held while buffers are made or deferred.
    std::uint32_t capacity = 0;
    if (grow) {
        capacity = std::uint32_t(std::min<std::uint64_t>(align_up(count, 64), 0xFFFFFFFFu));
        std::string error;
        instanceBuffer =
            device_.make_raw_buffer(VkDeviceSize(capacity) * sizeof(VkAccelerationStructureInstanceKHR),
                                    VK_BUFFER_USAGE_ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_BIT_KHR |
                                        VK_BUFFER_USAGE_SHADER_DEVICE_ADDRESS_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
                                    MemoryUse::GpuOnly, false, instanceLabel.c_str(), error);
        if (!instanceBuffer)
            return reject(cmd, "the buffer of " + std::to_string(count) + " instances: " + error,
                          "free GPU memory, or trace fewer instances");
    }
    const std::size_t bytes = n * sizeof(VkAccelerationStructureInstanceKHR);
    const UploadAlloc a = device_.upload(bytes, 16, this);
    if (!a.ok()) return reject(cmd, "no upload room for " + std::to_string(bytes) + " bytes of instances", buildFix);
    std::memcpy(a.cpu, vkInstances.data(), bytes);

    std::shared_ptr<TrackedResource> old;
    lock.lock();
    if (VulkanDevice::AccelRecord* d = device_.accels_.get(b.dst.id); d && d->handle == dstHandle) {
        if (grow) {
            old = std::move(d->instanceBuffer);
            d->instanceBuffer = instanceBuffer;
            d->instanceCapacity = capacity;
        }
        d->built = true;
        d->allowUpdate = b.flags.allowUpdate;
        d->allowCompaction = false;
        d->buildFlags = flags;
        d->instances = count;
    }
    lock.unlock();
    if (old) {  // the lists of earlier frames may still build from it
        VulkanDevice::Deferred def;
        def.tracked = std::move(old);
        device_.defer(std::move(def));
    }
    keep_until_done(instanceBuffer);  // alive while this list runs, even when the TLAS is destroyed or grows again

    require(instanceBuffer, 0, transfer_write_state(false));
    flush_barriers();
    VkBufferCopy c{};
    c.srcOffset = a.offset;
    c.dstOffset = 0;
    c.size = bytes;
    device_.fn_.vkCmdCopyBuffer(cmd_, a.buffer, instanceBuffer->buffer, 1, &c);
    uses.add(instanceBuffer, kBuildStage, VK_ACCESS_2_SHADER_READ_BIT);
    uses.add(dstTracked, kBuildStage, b.update && srcHandle == dstHandle ? kAccelRead | kAccelWrite : kAccelWrite);
    uses.require_all(*this);
    flush_barriers();
    const VkAccelerationStructureGeometryKHR geo = instances_geometry(device_.buffer_address(instanceBuffer->buffer));
    VkAccelerationStructureBuildGeometryInfoKHR info = build_info(AccelKind::Tlas, flags, &geo, 1);
    info.mode =
        b.update ? VK_BUILD_ACCELERATION_STRUCTURE_MODE_UPDATE_KHR : VK_BUILD_ACCELERATION_STRUCTURE_MODE_BUILD_KHR;
    info.srcAccelerationStructure = b.update ? srcHandle : VK_NULL_HANDLE;
    info.dstAccelerationStructure = dstHandle;
    info.scratchData.deviceAddress = scratchAddress;
    VkAccelerationStructureBuildRangeInfoKHR range{};
    range.primitiveCount = count;
    const VkAccelerationStructureBuildRangeInfoKHR* rangeList = &range;
    device_.fn_.vkCmdBuildAccelerationStructuresKHR(cmd_, 1, &info, &rangeList);
    empty_ = false;
    return {};
}

Result<void> VulkanCommandList::query_compacted_size(AccelStructure blas, Buffer dstBuffer, std::size_t dstOffset) {
    const char* cmd = "query_compacted_size";
    if (!device_.rayTracing_) return refusal(device_, "CommandList::query_compacted_size");
    std::string fix;
    const std::string problem = accel_command_problem(fix);
    if (!problem.empty()) return reject(cmd, problem, fix);

    std::string what;
    std::shared_ptr<TrackedResource> blasTracked, dstTracked;
    VkAccelerationStructureKHR handle = VK_NULL_HANDLE;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const VulkanDevice::AccelRecord* a = device_.accels_.get(blas.id);
        if (!a || !a->handle)
            add(what, "blas is acceleration structure " + std::to_string(blas.id) +
                          (a ? ", whose creation failed" : ", which names no live structure"));
        else if (a->kind != AccelKind::Blas)
            add(what, accel_label(a->label, a->kind) + " is a TLAS: only a BLAS is compacted");
        else if (!a->built)
            add(what, accel_label(a->label, AccelKind::Blas) + " was never built");
        else if (!a->allowCompaction)
            add(what, accel_label(a->label, AccelKind::Blas) + " was built without flags.allowCompaction");
        else {
            handle = a->handle;
            blasTracked = a->tracked;
        }
        const VulkanDevice::BufferRecord* d = device_.buffers_.get(dstBuffer.id);
        if (!d || !d->tracked) {
            add(what, "dst is buffer " + std::to_string(dstBuffer.id) +
                          (d ? ", whose creation failed" : ", which names no live buffer"));
        } else {
            if (!d->usage.storageBuffer)
                add(what, "dst buffer " + quoted(d->label) + " was not made with usage.storageBuffer");
            if (dstOffset % 8 != 0) add(what, "dstOffset " + std::to_string(dstOffset) + " is not a multiple of 8");
            if (dstOffset > d->size || d->size - dstOffset < 8)
                add(what, "8 bytes at offset " + std::to_string(dstOffset) + " do not fit in buffer " +
                              quoted(d->label) + " (" + std::to_string(d->size) + " bytes)");
            dstTracked = d->tracked;
        }
    }
    if (!what.empty())
        return reject(cmd, what,
                      "build the BLAS with flags.allowCompaction, and give a storage buffer with 8 bytes free at an "
                      "8-byte aligned offset");
    // One query of its own, released with the frame (compaction is rare: no pool to share).
    VkQueryPoolCreateInfo qi{};
    qi.sType = VK_STRUCTURE_TYPE_QUERY_POOL_CREATE_INFO;
    qi.queryType = VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR;
    qi.queryCount = 1;
    VkQueryPool pool = VK_NULL_HANDLE;
    const VkResult r = device_.fn_.vkCreateQueryPool(device_.device_, &qi, nullptr, &pool);
    if (r != VK_SUCCESS)
        return reject(cmd, "vkCreateQueryPool failed with " + result_text(r), "free memory and try again");
    VulkanDevice::Deferred d;
    d.queryPool = pool;
    device_.defer(std::move(d));

    require(blasTracked, 0, SubState{VK_IMAGE_LAYOUT_UNDEFINED, kBuildStage, kAccelRead});
    flush_barriers();
    device_.fn_.vkCmdResetQueryPool(cmd_, pool, 0, 1);
    device_.fn_.vkCmdWriteAccelerationStructuresPropertiesKHR(
        cmd_, 1, &handle, VK_QUERY_TYPE_ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR, pool, 0);
    // The copy of the result waits for the write (an execution dependency; WAIT_BIT waits for its availability).
    device_.fn_.vkCmdPipelineBarrier(cmd_, VK_PIPELINE_STAGE_ACCELERATION_STRUCTURE_BUILD_BIT_KHR,
                                     VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, nullptr, 0, nullptr, 0, nullptr);
    require(dstTracked, 0, transfer_write_state(false));
    flush_barriers();
    device_.fn_.vkCmdCopyQueryPoolResults(cmd_, pool, 0, 1, dstTracked->buffer, VkDeviceSize(dstOffset), 8,
                                          VK_QUERY_RESULT_64_BIT | VK_QUERY_RESULT_WAIT_BIT);
    empty_ = false;
    return {};
}

Result<void> VulkanCommandList::copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode) {
    const char* cmd = "copy_accel_structure";
    if (!device_.rayTracing_) return refusal(device_, "CommandList::copy_accel_structure");
    std::string fix;
    const std::string problem = accel_command_problem(fix);
    if (!problem.empty()) return reject(cmd, problem, fix);

    std::string what;
    BuildUses uses;
    VkAccelerationStructureKHR srcHandle = VK_NULL_HANDLE, dstHandle = VK_NULL_HANDLE;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const VulkanDevice::AccelRecord* a = device_.accels_.get(src.id);
        VulkanDevice::AccelRecord* b = device_.accels_.get(dst.id);
        if (!a || !a->handle)
            add(what, "src is acceleration structure " + std::to_string(src.id) +
                          (a ? ", whose creation failed" : ", which names no live structure"));
        if (!b || !b->handle)
            add(what, "dst is acceleration structure " + std::to_string(dst.id) +
                          (b ? ", whose creation failed" : ", which names no live structure"));
        if (a && b && a->handle && b->handle) {
            if (a == b) add(what, "src and dst are the same structure");
            if (a->kind != b->kind)
                add(what,
                    "src is a " + std::string(accel_kind_name(a->kind)) + " and dst a " + accel_kind_name(b->kind));
            if (!a->built) add(what, accel_label(a->label, a->kind) + " was never built");
            if (mode == AccelCopyMode::Compact) {
                if (!a->allowCompaction)
                    add(what, "Compact needs " + accel_label(a->label, a->kind) +
                                  " built with flags.allowCompaction (it was not)");
                if (b->size > a->size)
                    add(what, "Compact into " + accel_label(b->label, b->kind) + " of " + std::to_string(b->size) +
                                  " bytes, larger than the source's " + std::to_string(a->size) +
                                  ": make the target with the size query_compacted_size answered");
            } else if (b->size < a->size) {
                add(what, "Clone into " + accel_label(b->label, b->kind) + " of " + std::to_string(b->size) +
                              " bytes, smaller than the source's " + std::to_string(a->size));
            }
        }
        if (what.empty()) {
            srcHandle = a->handle;
            dstHandle = b->handle;
            uses.add(a->tracked, kBuildStage, kAccelRead);
            uses.add(b->tracked, kBuildStage, kAccelWrite);
            b->built = true;
            b->allowUpdate = a->allowUpdate;
            b->allowCompaction = false;  // a compacted structure is not compacted again
            b->buildFlags = a->buildFlags;
            b->primitiveCounts = a->primitiveCounts;
            b->geometryShapes = a->geometryShapes;
            b->instances = a->instances;
        }
    }
    if (!what.empty())
        return reject(cmd, what,
                      "copy a built structure into one of the same kind: Compact into a smaller one made with the "
                      "queried size (source built with allowCompaction), Clone into one at least as large");
    uses.require_all(*this);
    flush_barriers();
    VkCopyAccelerationStructureInfoKHR ci{};
    ci.sType = VK_STRUCTURE_TYPE_COPY_ACCELERATION_STRUCTURE_INFO_KHR;
    ci.src = srcHandle;
    ci.dst = dstHandle;
    ci.mode = mode == AccelCopyMode::Compact ? VK_COPY_ACCELERATION_STRUCTURE_MODE_COMPACT_KHR
                                             : VK_COPY_ACCELERATION_STRUCTURE_MODE_CLONE_KHR;
    device_.fn_.vkCmdCopyAccelerationStructureKHR(cmd_, &ci);
    empty_ = false;
    return {};
}

}  // namespace fa::gpu::vk

#endif  // FA_VULKAN_BACKEND
