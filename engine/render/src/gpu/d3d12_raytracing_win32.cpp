// The D3D12 backend's ray tracing (M79 P1d, docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, "Direct3D 12"): DXR 1.1
// acceleration structures for inline RayQuery in compute shaders. The size queries and the structures are the
// device's (render thread); the builds, the compaction query and the copies are the command list's, which derives every
// barrier itself: acceleration structure buffers never leave D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE,
// so their order is kept by UAV barriers (accel_access). The platform-neutral half is gpu/d3d12_accel.cpp.
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "gpu/d3d12_device.h"

namespace fa::gpu::d3d12 {

// The neutral InstanceDesc is uploaded as it is: its layout must be the SDK's.
static_assert(sizeof(InstanceDesc) == sizeof(D3D12_RAYTRACING_INSTANCE_DESC), "the instance desc is 64 bytes");
static_assert(offsetof(D3D12_RAYTRACING_INSTANCE_DESC, AccelerationStructure) == offsetof(InstanceDesc, blas),
              "the BLAS address follows the transform and the two packed words");
// (Every SDK value is cast: the macros are int literals and the flags unscoped enums, which /W4 compares with a
// warning against the unsigned constants.)
static_assert(kAccelAlignment == std::uint64_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BYTE_ALIGNMENT),
              "the structure alignment");
static_assert(kInstanceDescAlignment == std::uint64_t(D3D12_RAYTRACING_INSTANCE_DESCS_BYTE_ALIGNMENT),
              "the instance alignment");
static_assert(kMaxTlasInstances == std::uint32_t(D3D12_RAYTRACING_MAX_INSTANCES_PER_TOP_LEVEL_ACCELERATION_STRUCTURE),
              "instances");
static_assert(kMaxBlasGeometries ==
                  std::uint32_t(D3D12_RAYTRACING_MAX_GEOMETRIES_PER_BOTTOM_LEVEL_ACCELERATION_STRUCTURE),
              "geometries");
static_assert(kMaxBlasPrimitives ==
                  std::uint64_t(D3D12_RAYTRACING_MAX_PRIMITIVES_PER_BOTTOM_LEVEL_ACCELERATION_STRUCTURE),
              "primitives");
static_assert(kBuildFlagAllowUpdate == std::uint32_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_ALLOW_UPDATE) &&
                  kBuildFlagAllowCompaction ==
                      std::uint32_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_ALLOW_COMPACTION) &&
                  kBuildFlagPreferFastTrace ==
                      std::uint32_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_TRACE) &&
                  kBuildFlagPreferFastBuild ==
                      std::uint32_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PREFER_FAST_BUILD) &&
                  kBuildFlagPerformUpdate ==
                      std::uint32_t(D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PERFORM_UPDATE),
              "the build flags");
static_assert(kInstanceFlagCullDisable == std::uint32_t(D3D12_RAYTRACING_INSTANCE_FLAG_TRIANGLE_CULL_DISABLE) &&
                  kInstanceFlagForceOpaque == std::uint32_t(D3D12_RAYTRACING_INSTANCE_FLAG_FORCE_OPAQUE),
              "the instance flags");

namespace {

constexpr int kMaxReportedProblems = 4;
constexpr std::uint32_t kMaxCustomIndex = 0xFFFFFFu;

void add(std::string& what, const std::string& problem) {
    if (!what.empty()) what += "; ";
    what += problem;
}

std::string quoted(const std::string& s) { return "'" + s + "'"; }

std::string label_or_default(const char* label) {
    return label && *label ? std::string(label) : std::string("(no label)");
}

// "BLAS 'rock'" / "TLAS 'scene'".
std::string accel_label(const std::string& label, AccelKind kind) {
    return std::string(kind == AccelKind::Tlas ? "TLAS " : "BLAS ") + quoted(label);
}

// Whether `size` bytes at `offset` fit in `capacity` bytes (no overflow).
bool fits(std::uint64_t offset, std::uint64_t size, std::uint64_t capacity) {
    return offset <= capacity && size <= capacity - offset;
}

D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS rt_flags(const AccelBuildFlags& flags, AccelKind kind,
                                                             bool update) {
    return D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS(build_flags(flags, kind, update));
}

// The geometry descs of a BLAS (the buffer addresses that are known: 0 for a buffer that is not live, which only a
// size query sees).
struct GeometryInputs {
    std::vector<D3D12_RAYTRACING_GEOMETRY_DESC> descs;
    D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS inputs{};
};

void fill_geometry(const AccelTriangles& g, D3D12_GPU_VIRTUAL_ADDRESS vertices, D3D12_GPU_VIRTUAL_ADDRESS indices,
                   D3D12_RAYTRACING_GEOMETRY_DESC& d) {
    d = {};
    d.Type = D3D12_RAYTRACING_GEOMETRY_TYPE_TRIANGLES;
    d.Flags = g.opaque ? D3D12_RAYTRACING_GEOMETRY_FLAG_OPAQUE : D3D12_RAYTRACING_GEOMETRY_FLAG_NONE;
    D3D12_RAYTRACING_GEOMETRY_TRIANGLES_DESC& t = d.Triangles;
    t.Transform3x4 = 0;
    t.VertexFormat = DXGI_FORMAT_R32G32B32_FLOAT;
    t.VertexCount = g.vertexCount;
    t.VertexBuffer.StartAddress = vertices ? vertices + g.vertexOffset : 0;
    t.VertexBuffer.StrideInBytes = g.vertexStride;
    if (g.indexBuffer.valid()) {
        t.IndexFormat = g.indexType == IndexType::Uint16 ? DXGI_FORMAT_R16_UINT : DXGI_FORMAT_R32_UINT;
        t.IndexCount = g.indexCount;
        t.IndexBuffer = indices ? indices + g.indexOffset : 0;
    } else {
        t.IndexFormat = DXGI_FORMAT_UNKNOWN;
        t.IndexCount = 0;
        t.IndexBuffer = 0;
    }
}

void finish_blas_inputs(GeometryInputs& g, D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS flags) {
    g.inputs.Type = D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_BOTTOM_LEVEL;
    g.inputs.Flags = flags;
    g.inputs.NumDescs = UINT(g.descs.size());
    g.inputs.DescsLayout = D3D12_ELEMENTS_LAYOUT_ARRAY;
    g.inputs.pGeometryDescs = g.descs.data();
}

D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS
tlas_inputs(std::uint32_t count, D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS flags,
            D3D12_GPU_VIRTUAL_ADDRESS instances) {
    D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS in{};
    in.Type = D3D12_RAYTRACING_ACCELERATION_STRUCTURE_TYPE_TOP_LEVEL;
    in.Flags = flags;
    in.NumDescs = count;
    in.DescsLayout = D3D12_ELEMENTS_LAYOUT_ARRAY;
    in.InstanceDescs = instances;
    return in;
}

const char* const kBlasFix =
    "size the BLAS and the scratch buffer from blas_sizes() with the flags of the build, give every geometry live "
    "buffers with usage.accelBuildInput, and refit only what was built with allowUpdate";
const char* const kTlasFix =
    "build every BLAS the instances name first (and keep it alive), size the TLAS and the scratch buffer from "
    "tlas_sizes() with the flags of the build, and keep the instance count within Limits::maxAccelInstances";

}  // namespace

// ---------------------------------------------------------------------------------------------------------------------
// The device: capabilities, sizes, structures
// ---------------------------------------------------------------------------------------------------------------------

bool D3d12Device::ray_tracing_status(std::string* why) const {
    const bool ok = features_.rayQuery && features_.accelerationStructure;
    if (why) *why = ok ? std::string() : rtWhy_;
    return ok;
}

Error D3d12Device::accel_unavailable(const char* call) const {
    Error e = accel_refusal(Backend::D3d12, call);
    if (!rtWhy_.empty()) e.message = std::string("gpu d3d12: ") + call + ": " + rtWhy_;
    return e;
}

AccelSizes D3d12Device::prebuild_sizes(const D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS& inputs,
                                       bool allowUpdate) {
    D3D12_RAYTRACING_ACCELERATION_STRUCTURE_PREBUILD_INFO info{};
    device5_->GetRaytracingAccelerationStructurePrebuildInfo(&inputs, &info);
    return round_sizes(info.ResultDataMaxSizeInBytes, info.ScratchDataSizeInBytes, info.UpdateScratchDataSizeInBytes,
                       allowUpdate);
}

Result<AccelSizes> D3d12Device::blas_sizes(std::span<const AccelTriangles> geometries, const AccelBuildFlags& flags) {
    if (!features_.accelerationStructure || !device5_) return accel_unavailable("Device::blas_sizes");
    std::uint64_t primitives = 0;
    const std::string what = check_geometries(geometries, limits_, primitives);
    if (!what.empty())
        return make_error("gpu d3d12: blas_sizes: " + what,
                          "give 1 to Limits::maxAccelGeometries triangle geometries (Float3 positions, a multiple of 3 "
                          "indices) with at most Limits::maxAccelPrimitives triangles in all");
    GeometryInputs g;
    g.descs.resize(geometries.size());
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        for (std::size_t i = 0; i < geometries.size(); ++i) {
            const BufferRecord* vb = buffers_.get(geometries[i].vertexBuffer.id);
            const BufferRecord* ib = buffers_.get(geometries[i].indexBuffer.id);
            const D3D12_GPU_VIRTUAL_ADDRESS v = vb && vb->tracked ? vb->tracked->resource->GetGPUVirtualAddress() : 0;
            const D3D12_GPU_VIRTUAL_ADDRESS x = ib && ib->tracked ? ib->tracked->resource->GetGPUVirtualAddress() : 0;
            fill_geometry(geometries[i], v, x, g.descs[i]);
        }
    }
    finish_blas_inputs(g, rt_flags(flags, AccelKind::Blas, false));
    return prebuild_sizes(g.inputs, flags.allowUpdate);
}

Result<AccelSizes> D3d12Device::tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags) {
    if (!features_.accelerationStructure || !device5_) return accel_unavailable("Device::tlas_sizes");
    std::string what;
    if (instanceCount == 0) add(what, "0 instances: skip the TLAS build when the scene has no instances");
    if (limits_.maxAccelInstances > 0 && instanceCount > limits_.maxAccelInstances)
        add(what, std::to_string(instanceCount) + " instances are more than this device's limit " +
                      std::to_string(limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    if (!what.empty())
        return make_error("gpu d3d12: tlas_sizes: " + what, "ask for 1 to Limits::maxAccelInstances instances");
    return prebuild_sizes(tlas_inputs(instanceCount, rt_flags(flags, AccelKind::Tlas, false), 0), flags.allowUpdate);
}

Result<AccelStructure> D3d12Device::make_accel_structure(const AccelStructureDesc& desc) {
    if (!features_.accelerationStructure || !device5_) return accel_unavailable("Device::make_accel_structure");
    const std::string label = label_or_default(desc.label);
    const std::string fix = "size the structure from blas_sizes() / tlas_sizes(), and place it in a live buffer with "
                            "usage.accelStorage (or leave storage empty)";
    AccelRecord rec;
    rec.kind = desc.kind;
    rec.size = desc.size;
    rec.offset = desc.storageOffset;
    rec.label = label;
    std::string what;
    if (desc.size == 0) add(what, "AccelStructureDesc::size is 0: take it from blas_sizes() / tlas_sizes()");
    if (desc.storage.valid()) {
        std::lock_guard<std::mutex> lock(resMutex_);
        const BufferRecord* b = buffers_.get(desc.storage.id);
        if (!b || !b->tracked) {
            add(what, "storage (buffer " + std::to_string(desc.storage.id) + ") is not a live buffer");
        } else {
            if (!b->usage.accelStorage)
                add(what, "storage buffer " + quoted(b->label) + " was not made with usage.accelStorage");
            if (desc.storageOffset % kAccelAlignment != 0)
                add(what, "storageOffset " + std::to_string(desc.storageOffset) + " is not a multiple of " +
                              std::to_string(kAccelAlignment) + " (Device::accel_alignment())");
            if (!fits(desc.storageOffset, desc.size, b->size))
                add(what, std::to_string(desc.size) + " bytes at offset " + std::to_string(desc.storageOffset) +
                              " do not fit in buffer " + quoted(b->label) + " (" + std::to_string(b->size) + " bytes)");
            if (what.empty()) rec.tracked = b->tracked;
        }
    } else if (desc.storageOffset != 0) {
        add(what, "storageOffset is set but storage is not");
    }
    if (!what.empty()) return make_error("gpu d3d12: make_accel_structure '" + label + "': " + what, fix);

    if (!rec.tracked) {
        // Memory of its own: a buffer in the acceleration structure state, which it never leaves.
        D3D12_RESOURCE_DESC d{};
        d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        d.Width = align_up(desc.size, kAccelAlignment);
        d.Height = 1;
        d.DepthOrArraySize = 1;
        d.MipLevels = 1;
        d.Format = DXGI_FORMAT_UNKNOWN;
        d.SampleDesc.Count = 1;
        d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        d.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
        Com<ID3D12Resource> r =
            make_committed(d, D3D12_HEAP_TYPE_DEFAULT, D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE,
                           "make_accel_structure", label.c_str());
        if (!r)
            return make_error("gpu d3d12: make_accel_structure '" + label + "': D3D12 could not make its " +
                                  std::to_string(d.Width) + " bytes (errors() has D3D12's reason)",
                              "free GPU memory, or make the structure smaller");
        auto t = std::make_shared<TrackedResource>();
        t->resource = std::move(r);
        t->states.assign(1, StateBits(D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE));
        t->buffer = true;
        t->accel = true;
        t->label = "acceleration structure " + quoted(label);
        rec.tracked = std::move(t);
    }
    rec.address = rec.tracked->resource->GetGPUVirtualAddress() + rec.offset;
    std::lock_guard<std::mutex> lock(resMutex_);
    const std::uint32_t id = accels_.add(std::move(rec));
    if (id == 0)
        return make_error("gpu d3d12: make_accel_structure '" + label + "': the acceleration structure pool is full (" +
                              std::to_string(accels_.capacity()) + ")",
                          "destroy structures no longer used, or raise DeviceInit::bufferPoolSize");
    return AccelStructure{id};
}

void D3d12Device::destroy_accel_structure(AccelStructure accel) {
    if (!accel.valid()) return;
    AccelRecord rec;
    {
        std::lock_guard<std::mutex> lock(resMutex_);
        if (!accels_.remove(accel.id, rec)) {
            report("gpu d3d12: destroy_accel_structure: acceleration structure " + std::to_string(accel.id) +
                   " names nothing (hint: it was destroyed already, or another device made it)");
            return;
        }
    }
    // The memory goes once the frames that may still use it are finished (a caller's storage buffer stays alive
    // with its own record).
    if (rec.tracked) {
        Deferred d;
        d.tracked = std::move(rec.tracked);
        defer(std::move(d));
    }
}

ResourceState D3d12Device::accel_structure_state(AccelStructure accel) const {
    std::lock_guard<std::mutex> lock(resMutex_);
    const AccelRecord* r = accels_.get(accel.id);
    if (!r) return ResourceState::Invalid;
    return r->tracked ? ResourceState::Valid : ResourceState::Failed;
}

// ---------------------------------------------------------------------------------------------------------------------
// The command list: builds, compaction, copies
// ---------------------------------------------------------------------------------------------------------------------

std::string D3d12CommandList::accel_list_problem() const {
    if (!open_ || !list_) return "the list is not recording (hint: take a new list with begin_commands() each frame)";
    if (nativeOpen_) return "a native section is open (hint: end_native() first)";
    if (passState_ != PassState::None)
        return "called inside a pass; it goes outside a pass (hint: end_pass() first, or record it before "
               "begin_pass())";
    if (kind_ == QueueKind::Transfer)
        return "called on a Transfer list, which takes copies, writes and markers only (hint: record it on a "
               "Graphics or Compute list)";
    if (!list4_)
        return "this list has no ID3D12GraphicsCommandList4 (hint: update Windows; Device::ray_tracing_status says "
               "what the device has)";
    return {};
}

void D3d12CommandList::accel_access(const std::shared_ptr<TrackedResource>& t, AccelAccess access) {
    if (!t) return;
    require(t, 0, D3D12_RESOURCE_STATE_RAYTRACING_ACCELERATION_STRUCTURE);  // no barrier: it never leaves that state
    AccelAccess& last = accelLast_[t.get()];
    const bool barrier = (access == AccelAccess::Write && last != AccelAccess::None) ||
                         (access == AccelAccess::Read && last == AccelAccess::Write);
    if (barrier) {
        D3D12_RESOURCE_BARRIER b{};
        b.Type = D3D12_RESOURCE_BARRIER_TYPE_UAV;
        b.UAV.pResource = t->resource.get();
        pending_.push_back(b);
    }
    last = access;
}

Result<void> D3d12CommandList::build_blas(const BlasBuild& b) {
    const std::string at = "gpu d3d12: CommandList::build_blas in list '" + label_ + "': ";
    if (!device_.features_.accelerationStructure) return device_.accel_unavailable("CommandList::build_blas");
    if (const std::string p = accel_list_problem(); !p.empty()) return make_error(at + p, "");
    std::uint64_t primitives = 0;
    std::string what = check_geometries(b.geometries, device_.limits_, primitives);
    std::vector<std::shared_ptr<TrackedResource>> inputs;
    GeometryInputs g;
    g.descs.resize(b.geometries.size());
    std::shared_ptr<TrackedResource> dstT, srcT, scratchT;
    D3D12_GPU_VIRTUAL_ADDRESS dstAddress = 0, srcAddress = 0, scratchAddress = 0;
    const D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS flags = rt_flags(b.flags, AccelKind::Blas, false);
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const D3d12Device::AccelRecord* dst = device_.accels_.get(b.dst.id);
        if (!dst || !dst->tracked)
            add(what, "dst (acceleration structure " + std::to_string(b.dst.id) + ") is not a live structure");
        else if (dst->kind != AccelKind::Blas)
            add(what, "dst " + accel_label(dst->label, dst->kind) +
                          " is a TLAS: build_blas writes a BLAS (build_tlas builds a TLAS)");
        int problems = 0;
        for (std::size_t i = 0; i < b.geometries.size() && problems < kMaxReportedProblems; ++i) {
            const AccelTriangles& geo = b.geometries[i];
            const std::string n = "geometries[" + std::to_string(i) + "]";
            const std::size_t before = what.size();
            D3D12_GPU_VIRTUAL_ADDRESS v = 0, x = 0;
            const D3d12Device::BufferRecord* vb = device_.buffers_.get(geo.vertexBuffer.id);
            if (!vb || !vb->tracked) {
                add(what,
                    n + ".vertexBuffer (buffer " + std::to_string(geo.vertexBuffer.id) + ") is not a live buffer");
            } else {
                if (!vb->usage.accelBuildInput)
                    add(what, n + ".vertexBuffer " + quoted(vb->label) + " was not made with usage.accelBuildInput");
                const std::uint64_t need =
                    geo.vertexCount == 0
                        ? 0
                        : std::uint64_t(geo.vertexOffset) + std::uint64_t(geo.vertexCount - 1) * geo.vertexStride + 12;
                if (need > vb->size)
                    add(what, n + " reads " + std::to_string(geo.vertexCount) + " vertices up to byte " +
                                  std::to_string(need) + ", but vertex buffer " + quoted(vb->label) + " has " +
                                  std::to_string(vb->size) + " bytes");
                if (geo.vertexOffset % 4 != 0)
                    add(what, n + ".vertexOffset " + std::to_string(geo.vertexOffset) +
                                  " is not a multiple of 4 (D3D12 reads positions at 4-byte aligned addresses)");
                v = vb->tracked->resource->GetGPUVirtualAddress();
                inputs.push_back(vb->tracked);
            }
            if (geo.indexBuffer.valid()) {
                const D3d12Device::BufferRecord* ib = device_.buffers_.get(geo.indexBuffer.id);
                if (!ib || !ib->tracked) {
                    add(what,
                        n + ".indexBuffer (buffer " + std::to_string(geo.indexBuffer.id) + ") is not a live buffer");
                } else {
                    if (!ib->usage.accelBuildInput)
                        add(what, n + ".indexBuffer " + quoted(ib->label) + " was not made with usage.accelBuildInput");
                    const std::uint64_t width = geo.indexType == IndexType::Uint16 ? 2 : 4;
                    const std::uint64_t need = std::uint64_t(geo.indexOffset) + std::uint64_t(geo.indexCount) * width;
                    if (need > ib->size)
                        add(what, n + " reads " + std::to_string(geo.indexCount) + " indices up to byte " +
                                      std::to_string(need) + ", but index buffer " + quoted(ib->label) + " has " +
                                      std::to_string(ib->size) + " bytes");
                    if (geo.indexOffset % width != 0)
                        add(what, n + ".indexOffset " + std::to_string(geo.indexOffset) + " is not a multiple of " +
                                      std::to_string(width) + " (the size of one index)");
                    x = ib->tracked->resource->GetGPUVirtualAddress();
                    inputs.push_back(ib->tracked);
                }
            }
            fill_geometry(geo, v, x, g.descs[i]);
            if (what.size() != before) ++problems;
        }
        if (what.empty()) {
            finish_blas_inputs(g, flags);
            const AccelSizes need = device_.prebuild_sizes(g.inputs, b.flags.allowUpdate);
            if (dst->size < need.structure)
                add(what, "dst " + accel_label(dst->label, AccelKind::Blas) + " has " + std::to_string(dst->size) +
                              " bytes but these geometries need " + std::to_string(need.structure) +
                              " (AccelSizes::structure of blas_sizes with the same flags)");
            dstT = dst->tracked;
            dstAddress = dst->address;
            if (b.update) {
                const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
                const D3d12Device::AccelRecord* src = device_.accels_.get(srcHandle.id);
                if (!src || !src->tracked)
                    add(what,
                        "src (acceleration structure " + std::to_string(srcHandle.id) + ") is not a live structure");
                else if (src->kind != AccelKind::Blas)
                    add(what, "src " + accel_label(src->label, src->kind) + " is a TLAS: a BLAS refits from a BLAS");
                else if (!src->built)
                    add(what, "update of " + accel_label(src->label, AccelKind::Blas) + ", which was never built");
                else if (!src->allowUpdate)
                    add(what, "update of " + accel_label(src->label, AccelKind::Blas) +
                                  ", which was built without flags.allowUpdate");
                else if (src->geometries != b.geometries.size() || src->primitives != primitives)
                    add(what, "update with " + std::to_string(b.geometries.size()) + " geometries and " +
                                  std::to_string(primitives) + " triangles, but " +
                                  accel_label(src->label, AccelKind::Blas) + " was built with " +
                                  std::to_string(src->geometries) + " and " + std::to_string(src->primitives) +
                                  ": a refit keeps the topology");
                else if (build_flags(src->flags, AccelKind::Blas, false) != std::uint32_t(flags))
                    add(what, "update of " + accel_label(src->label, AccelKind::Blas) +
                                  " with other flags than its build: D3D12 refits with the flags it was built with");
                if (!b.flags.allowUpdate)
                    add(what, "update with flags.allowUpdate false (pass the flags the BLAS was built with)");
                if (src && src->tracked) {
                    srcT = src->tracked;
                    srcAddress = src->address;
                }
            }
            const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
            const D3d12Device::BufferRecord* scratch = device_.buffers_.get(b.scratch.id);
            if (!scratch || !scratch->tracked) {
                add(what, "scratch (buffer " + std::to_string(b.scratch.id) + ") is not a live buffer");
            } else {
                if (!scratch->usage.accelScratch)
                    add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
                if (b.scratchOffset % kAccelAlignment != 0)
                    add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                                  std::to_string(kAccelAlignment) + " (Device::accel_scratch_alignment())");
                if (!fits(b.scratchOffset, scratchNeed, scratch->size))
                    add(what,
                        "scratch buffer " + quoted(scratch->label) + " has " +
                            std::to_string(scratch->size > b.scratchOffset ? scratch->size - b.scratchOffset : 0) +
                            " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                            (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                            " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
                scratchT = scratch->tracked;
                scratchAddress = scratch->tracked->resource->GetGPUVirtualAddress() + b.scratchOffset;
            }
        }
    }
    if (!what.empty()) return make_error(at + what, kBlasFix);

    // The barriers: the inputs in the build-input state, the scratch in the UAV state after the last build that used
    // it, the source and the destination after the commands of this list that touched them.
    for (const std::shared_ptr<TrackedResource>& t : inputs)
        require(t, 0, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE);
    uav_barrier_if_written(scratchT);
    require(scratchT, 0, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
    if (srcT && srcAddress != dstAddress) accel_access(srcT, AccelAccess::Read);
    accel_access(dstT, AccelAccess::Write);
    flush_barriers();
    D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC desc{};
    desc.DestAccelerationStructureData = dstAddress;
    desc.Inputs = g.inputs;
    if (b.update) {
        desc.Inputs.Flags |= D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PERFORM_UPDATE;
        desc.SourceAccelerationStructureData = srcAddress;
    }
    desc.ScratchAccelerationStructureData = scratchAddress;
    list4_->BuildRaytracingAccelerationStructure(&desc, 0, nullptr);
    empty_ = false;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        if (D3d12Device::AccelRecord* d = device_.accels_.get(b.dst.id)) {
            d->built = true;
            d->allowUpdate = b.flags.allowUpdate;
            d->allowCompaction = b.flags.allowCompaction;
            d->flags = b.flags;
            d->geometries = std::uint32_t(b.geometries.size());
            d->primitives = primitives;
            d->instances = 0;
        }
    }
    return {};
}

Result<void> D3d12CommandList::build_tlas(const TlasBuild& b) {
    const std::string at = "gpu d3d12: CommandList::build_tlas in list '" + label_ + "': ";
    if (!device_.features_.accelerationStructure) return device_.accel_unavailable("CommandList::build_tlas");
    if (const std::string p = accel_list_problem(); !p.empty()) return make_error(at + p, "");
    std::string what;
    const std::size_t n = b.instances.size();
    if (n == 0) add(what, "no instances: skip the TLAS build when the scene has none");
    if (device_.limits_.maxAccelInstances > 0 && n > device_.limits_.maxAccelInstances)
        add(what, std::to_string(n) + " instances are more than this device's limit " +
                      std::to_string(device_.limits_.maxAccelInstances) +
                      " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
    const auto count = std::uint32_t(std::min<std::size_t>(n, kMaxTlasInstances));
    const D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS flags = rt_flags(b.flags, AccelKind::Tlas, false);
    std::vector<InstanceDesc> descs;
    std::vector<std::shared_ptr<TrackedResource>> blases;
    std::shared_ptr<TrackedResource> dstT, srcT, scratchT;
    D3D12_GPU_VIRTUAL_ADDRESS dstAddress = 0, srcAddress = 0, scratchAddress = 0;
    if (what.empty()) {
        descs.resize(n);
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const D3d12Device::AccelRecord* dst = device_.accels_.get(b.dst.id);
        if (!dst || !dst->tracked)
            add(what, "dst (acceleration structure " + std::to_string(b.dst.id) + ") is not a live structure");
        else if (dst->kind != AccelKind::Tlas)
            add(what, "dst " + accel_label(dst->label, dst->kind) +
                          " is a BLAS: build_tlas writes a TLAS (build_blas builds a BLAS)");
        int problems = 0;
        for (std::size_t i = 0; i < n; ++i) {
            const AccelInstance& in = b.instances[i];
            const std::string name = "instances[" + std::to_string(i) + "]";
            const std::size_t before = what.size();
            const D3d12Device::AccelRecord* blas = device_.accels_.get(in.blas.id);
            std::uint64_t address = 0;
            if (problems < kMaxReportedProblems) {
                if (!blas || !blas->tracked)
                    add(what, name + ".blas (acceleration structure " + std::to_string(in.blas.id) +
                                  ") is not a live structure: destroy a BLAS only after the TLAS that names it is no "
                                  "longer built");
                else if (blas->kind != AccelKind::Blas)
                    add(what, name + ".blas is the " + accel_label(blas->label, blas->kind) +
                                  ": an instance names a BLAS (a TLAS cannot nest)");
                else if (!blas->built)
                    add(what, name + ".blas " + accel_label(blas->label, AccelKind::Blas) +
                                  " was never built: record build_blas before build_tlas");
                if (in.customIndex > kMaxCustomIndex)
                    add(what, name + ".customIndex " + std::to_string(in.customIndex) +
                                  " does not fit in 24 bits (at most " + std::to_string(kMaxCustomIndex) + ")");
                for (float v : in.transform)
                    if (!std::isfinite(v)) {
                        add(what, name + ".transform has a NaN or infinite value");
                        break;
                    }
                if (what.size() != before) ++problems;
            }
            if (blas && blas->tracked) {
                address = blas->address;
                if (std::find(blases.begin(), blases.end(), blas->tracked) == blases.end())
                    blases.push_back(blas->tracked);
            }
            descs[i] = to_instance_desc(in, address);
        }
        if (what.empty()) {
            const AccelSizes need = device_.prebuild_sizes(tlas_inputs(count, flags, 0), b.flags.allowUpdate);
            if (dst->size < need.structure)
                add(what, "dst " + accel_label(dst->label, AccelKind::Tlas) + " has " + std::to_string(dst->size) +
                              " bytes but " + std::to_string(n) + " instances need " + std::to_string(need.structure) +
                              " (AccelSizes::structure of tlas_sizes with the same flags)");
            dstT = dst->tracked;
            dstAddress = dst->address;
            if (b.update) {
                const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
                const D3d12Device::AccelRecord* src = device_.accels_.get(srcHandle.id);
                if (!src || !src->tracked)
                    add(what,
                        "src (acceleration structure " + std::to_string(srcHandle.id) + ") is not a live structure");
                else if (src->kind != AccelKind::Tlas)
                    add(what, "src " + accel_label(src->label, src->kind) + " is a BLAS: a TLAS refits from a TLAS");
                else if (!src->built)
                    add(what, "update of " + accel_label(src->label, AccelKind::Tlas) + ", which was never built");
                else if (!src->allowUpdate)
                    add(what, "update of " + accel_label(src->label, AccelKind::Tlas) +
                                  ", which was built without flags.allowUpdate");
                else if (src->instances != n)
                    add(what, "update with " + std::to_string(n) + " instances, but " +
                                  accel_label(src->label, AccelKind::Tlas) + " was built with " +
                                  std::to_string(src->instances) + ": a refit keeps the count");
                else if (build_flags(src->flags, AccelKind::Tlas, false) != std::uint32_t(flags))
                    add(what, "update of " + accel_label(src->label, AccelKind::Tlas) +
                                  " with other flags than its build: D3D12 refits with the flags it was built with");
                if (!b.flags.allowUpdate)
                    add(what, "update with flags.allowUpdate false (pass the flags the TLAS was built with)");
                if (src && src->tracked) {
                    srcT = src->tracked;
                    srcAddress = src->address;
                }
            }
            const std::uint64_t scratchNeed = b.update ? need.updateScratch : need.buildScratch;
            const D3d12Device::BufferRecord* scratch = device_.buffers_.get(b.scratch.id);
            if (!scratch || !scratch->tracked) {
                add(what, "scratch (buffer " + std::to_string(b.scratch.id) + ") is not a live buffer");
            } else {
                if (!scratch->usage.accelScratch)
                    add(what, "scratch buffer " + quoted(scratch->label) + " was not made with usage.accelScratch");
                if (b.scratchOffset % kAccelAlignment != 0)
                    add(what, "scratchOffset " + std::to_string(b.scratchOffset) + " is not a multiple of " +
                                  std::to_string(kAccelAlignment) + " (Device::accel_scratch_alignment())");
                if (!fits(b.scratchOffset, scratchNeed, scratch->size))
                    add(what,
                        "scratch buffer " + quoted(scratch->label) + " has " +
                            std::to_string(scratch->size > b.scratchOffset ? scratch->size - b.scratchOffset : 0) +
                            " bytes from scratchOffset " + std::to_string(b.scratchOffset) + ", but this " +
                            (b.update ? "update" : "build") + " needs " + std::to_string(scratchNeed) +
                            " (AccelSizes::" + (b.update ? "updateScratch" : "buildScratch") + ")");
                scratchT = scratch->tracked;
                scratchAddress = scratch->tracked->resource->GetGPUVirtualAddress() + b.scratchOffset;
            }
        }
    }
    if (!what.empty()) return make_error(at + what, kTlasFix);

    // The instances: copied into upload memory this list keeps until its frame is finished.
    const std::size_t bytes = descs.size() * sizeof(InstanceDesc);
    const UploadAlloc a = device_.upload(bytes, std::size_t(kInstanceDescAlignment), this);
    if (!a.ok())
        return make_error(at + "no upload memory for " + std::to_string(bytes) +
                              " bytes of instances (errors() has "
                              "D3D12's reason)",
                          "trace fewer instances, or free GPU memory");
    std::memcpy(a.cpu, descs.data(), bytes);

    // The barriers: every BLAS after the builds of this list that wrote it, the scratch after its last use, the source
    // and the destination after the commands that touched them (a dispatch that traced the TLAS: write after read).
    for (const std::shared_ptr<TrackedResource>& t : blases) accel_access(t, AccelAccess::Read);
    uav_barrier_if_written(scratchT);
    require(scratchT, 0, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
    if (srcT && srcAddress != dstAddress) accel_access(srcT, AccelAccess::Read);
    accel_access(dstT, AccelAccess::Write);
    flush_barriers();
    D3D12_BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC desc{};
    desc.DestAccelerationStructureData = dstAddress;
    desc.Inputs = tlas_inputs(count, flags, a.gpu);
    if (b.update) {
        desc.Inputs.Flags |= D3D12_RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAG_PERFORM_UPDATE;
        desc.SourceAccelerationStructureData = srcAddress;
    }
    desc.ScratchAccelerationStructureData = scratchAddress;
    list4_->BuildRaytracingAccelerationStructure(&desc, 0, nullptr);
    empty_ = false;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        if (D3d12Device::AccelRecord* d = device_.accels_.get(b.dst.id)) {
            d->built = true;
            d->allowUpdate = b.flags.allowUpdate;
            d->allowCompaction = false;
            d->flags = b.flags;
            d->geometries = 0;
            d->primitives = 0;
            d->instances = count;
        }
    }
    return {};
}

Result<void> D3d12CommandList::query_compacted_size(AccelStructure blas, Buffer dstBuffer, std::size_t dstOffset) {
    const std::string at = "gpu d3d12: CommandList::query_compacted_size in list '" + label_ + "': ";
    if (!device_.features_.accelerationStructure) return device_.accel_unavailable("CommandList::query_compacted_size");
    if (const std::string p = accel_list_problem(); !p.empty()) return make_error(at + p, "");
    std::string what;
    std::shared_ptr<TrackedResource> srcT, dstT;
    D3D12_GPU_VIRTUAL_ADDRESS srcAddress = 0, dstAddress = 0;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const D3d12Device::AccelRecord* a = device_.accels_.get(blas.id);
        if (!a || !a->tracked)
            add(what, "blas (acceleration structure " + std::to_string(blas.id) + ") is not a live structure");
        else if (a->kind != AccelKind::Blas)
            add(what, accel_label(a->label, a->kind) + " is a TLAS: only a BLAS is compacted");
        else if (!a->built)
            add(what, accel_label(a->label, AccelKind::Blas) + " was never built");
        else if (!a->allowCompaction)
            add(what, accel_label(a->label, AccelKind::Blas) + " was built without flags.allowCompaction");
        else {
            srcT = a->tracked;
            srcAddress = a->address;
        }
        const D3d12Device::BufferRecord* d = device_.buffers_.get(dstBuffer.id);
        if (!d || !d->tracked) {
            add(what, "dst (buffer " + std::to_string(dstBuffer.id) + ") is not a live buffer");
        } else {
            if (!d->usage.storageBuffer)
                add(what, "dst buffer " + quoted(d->label) + " was not made with usage.storageBuffer");
            if (dstOffset % kPostbuildInfoAlignment != 0)
                add(what, "dstOffset " + std::to_string(dstOffset) + " is not a multiple of 8");
            if (!fits(dstOffset, 8, d->size))
                add(what, "8 bytes at offset " + std::to_string(dstOffset) + " do not fit in buffer " +
                              quoted(d->label) + " (" + std::to_string(d->size) + " bytes)");
            dstT = d->tracked;
            dstAddress = d->tracked->resource->GetGPUVirtualAddress() + dstOffset;
        }
    }
    if (!what.empty())
        return make_error(at + what,
                          "build the BLAS with flags.allowCompaction, and give a storage buffer with 8 bytes free at "
                          "an 8-byte aligned offset");
    accel_access(srcT, AccelAccess::Read);  // after the build that wrote it
    uav_barrier_if_written(dstT);
    require(dstT, 0, D3D12_RESOURCE_STATE_UNORDERED_ACCESS);
    flush_barriers();
    D3D12_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_DESC info{};
    info.DestBuffer = dstAddress;
    info.InfoType = D3D12_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_COMPACTED_SIZE;
    list4_->EmitRaytracingAccelerationStructurePostbuildInfo(&info, 1, &srcAddress);
    empty_ = false;
    return {};
}

Result<void> D3d12CommandList::copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode) {
    const std::string at = "gpu d3d12: CommandList::copy_accel_structure in list '" + label_ + "': ";
    if (!device_.features_.accelerationStructure) return device_.accel_unavailable("CommandList::copy_accel_structure");
    if (const std::string p = accel_list_problem(); !p.empty()) return make_error(at + p, "");
    std::string what;
    std::shared_ptr<TrackedResource> srcT, dstT;
    D3D12_GPU_VIRTUAL_ADDRESS srcAddress = 0, dstAddress = 0;
    D3d12Device::AccelRecord from;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        const D3d12Device::AccelRecord* a = device_.accels_.get(src.id);
        const D3d12Device::AccelRecord* b = device_.accels_.get(dst.id);
        const bool aLive = a && a->tracked, bLive = b && b->tracked;
        if (!aLive) add(what, "src (acceleration structure " + std::to_string(src.id) + ") is not a live structure");
        if (!bLive) add(what, "dst (acceleration structure " + std::to_string(dst.id) + ") is not a live structure");
        if (aLive && bLive) {
            if (src.id == dst.id) add(what, "src and dst are the same structure " + accel_label(a->label, a->kind));
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
            srcT = a->tracked;
            dstT = b->tracked;
            srcAddress = a->address;
            dstAddress = b->address;
            from.flags = a->flags;
            from.allowUpdate = a->allowUpdate;
            from.geometries = a->geometries;
            from.primitives = a->primitives;
            from.instances = a->instances;
        }
    }
    if (!what.empty())
        return make_error(at + what,
                          "copy a built structure into one of the same kind: Compact into a smaller one made with the "
                          "queried size (source built with allowCompaction), Clone into one at least as large");
    accel_access(srcT, AccelAccess::Read);
    accel_access(dstT, AccelAccess::Write);
    flush_barriers();
    list4_->CopyRaytracingAccelerationStructure(dstAddress, srcAddress,
                                                mode == AccelCopyMode::Compact
                                                    ? D3D12_RAYTRACING_ACCELERATION_STRUCTURE_COPY_MODE_COMPACT
                                                    : D3D12_RAYTRACING_ACCELERATION_STRUCTURE_COPY_MODE_CLONE);
    empty_ = false;
    {
        std::lock_guard<std::mutex> lock(device_.resMutex_);
        if (D3d12Device::AccelRecord* d = device_.accels_.get(dst.id)) {
            d->built = true;
            d->allowUpdate = from.allowUpdate;
            d->allowCompaction = false;  // a compacted structure is not compacted again
            d->flags = from.flags;       // a refit of the copy passes the flags of the original build
            d->geometries = from.geometries;
            d->primitives = from.primitives;
            d->instances = from.instances;
        }
    }
    return {};
}

}  // namespace fa::gpu::d3d12
