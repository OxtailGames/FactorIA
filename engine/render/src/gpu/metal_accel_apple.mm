// Metal ray tracing inside the sokol device (metal_accel.h; docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, "Metal"): the
// MTLAccelerationStructure objects, their builds, refits, compaction and copies in an MTLAccelerationStructureCommandEncoder on
// sokol's command buffer, and the binding of a TLAS on sokol's compute encoder. The checks mirror RecordingDevice's (the strict
// reference of the seam), because Metal answers a bad descriptor with an assertion that ends the process.
#include "gpu/metal_accel.h"

#if defined(SOKOL_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include <algorithm>
#include <cmath>
#include <cstring>
#include <memory>
#include <mutex>
#include <unordered_map>
#include <vector>

#include "fa/core/log.h"
#include "sokol_gfx.h"

namespace fa::gpu {

namespace {

constexpr std::uint32_t kMaxCustomIndex = 0xFFFFFFu;
constexpr int kMaxReportedProblems = 4;
constexpr std::size_t kMaxFreeInstanceBuffers = 8;

std::string quoted(const std::string& s) { return "'" + s + "'"; }

void add(std::string& what, const std::string& problem) {
    if (!what.empty()) what += "; ";
    what += problem;
}

std::string geometry_name(std::size_t i) { return "geometries[" + std::to_string(i) + "]"; }

std::string os_version() {
    NSString* v = [[NSProcessInfo processInfo] operatingSystemVersionString];
    return v ? std::string([v UTF8String]) : std::string("this OS version");
}

std::string device_name(id<MTLDevice> dev) {
    if (!dev) return "no Metal device";
    NSString* n = dev.name;
    return n ? std::string([n UTF8String]) : std::string("this GPU");
}

const char* kind_label(AccelKind k) { return k == AccelKind::Tlas ? "TLAS " : "BLAS "; }

std::string accel_label(const std::string& label, AccelKind kind) { return std::string(kind_label(kind)) + quoted(label); }

// The instance buffers the TLAS builds read, kept for reuse once the command buffer that read them has completed (its
// completion handler runs on another thread, hence the lock and the shared pointer).
struct InstancePool {
    std::mutex mutex;
    std::vector<id<MTLBuffer>> free;
};

}  // namespace

struct MetalAccel::Impl {
    struct Entry {
        bool alive = false;
        std::uint16_t generation = 1;
        AccelKind kind = AccelKind::Blas;
        std::uint64_t size = 0;
        std::string label;
        id<MTLAccelerationStructure> as = nil;
        bool built = false;
        bool allowUpdate = false;
        bool allowCompaction = false;
        std::uint32_t geometries = 0;
        std::uint64_t primitives = 0;
        std::uint32_t instances = 0;
        // A TLAS: the BLASes its last build named, kept alive (and made resident for a trace) until it is built again.
        NSArray<id<MTLAccelerationStructure>>* primitives_array = nil;
    };
    struct BufferInfo {
        BufferUsage usage;
        std::size_t size = 0;
        std::string label;
    };

    Device& device;
    id<MTLDevice> mtl = nil;
    Limits lim{};
    std::vector<Entry> pool;
    std::vector<std::uint16_t> freeSlots;
    std::unordered_map<std::uint32_t, BufferInfo> buffers;
    std::shared_ptr<InstancePool> instances = std::make_shared<InstancePool>();
    // sokol's command queue, kept the first time a command buffer was asked for (every later one is from it): wait_idle
    // needs it when the sokol context is already gone. Nil until a build, a copy or a retire asked.
    mutable id<MTLCommandQueue> queue = nil;
    // bind_compute reports each of its two failures once per device (a dispatch per frame would fill the log); the
    // trace itself is skipped on every call.
    bool warnedNoEncoder = false;
    bool warnedInvalidStructure = false;

    Impl(Device& d, id<MTLDevice> m) : device(d), mtl(m) {
        lim.maxAccelInstances = 1u << 20;  // conservative: Metal documents no numbers
        lim.maxAccelGeometries = 4096;
        lim.maxAccelPrimitives = std::uint64_t(1) << 28;
    }

    // ---- the pool ------------------------------------------------------------------------------------------------
    static std::uint32_t make_id(std::uint16_t slot, std::uint16_t generation) {
        return (std::uint32_t(generation) << 16) | std::uint32_t(slot + 1);
    }
    Entry* find(AccelStructure h) {
        const std::uint32_t slot = h.id & 0xFFFFu;
        if (slot == 0 || slot > pool.size()) return nullptr;
        Entry& e = pool[slot - 1];
        return e.alive && e.generation == (h.id >> 16) ? &e : nullptr;
    }
    const Entry* find(AccelStructure h) const { return const_cast<Impl*>(this)->find(h); }
    std::string describe(AccelStructure h) const {
        if (!h.valid()) return "the invalid handle (no acceleration structure)";
        if (find(h)) return "a live acceleration structure";
        return "destroyed or never made (stale handle " + std::to_string(h.id) + ")";
    }

    // ---- checks ---------------------------------------------------------------------------------------------------
    // What the buffer `b` is for the checks: its entry when it was made with accel or storage usage, else why it is not.
    const BufferInfo* buffer_info(std::string& what, const std::string& name, Buffer b, const char* flagName,
                                  bool BufferUsage::*flag) const {
        if (!b.valid()) {
            add(what, name + " is the invalid handle (no buffer)");
            return nullptr;
        }
        if (device.state(b) != ResourceState::Valid) {
            add(what, name + " is a destroyed or failed buffer");
            return nullptr;
        }
        auto it = buffers.find(b.id);
        if (it == buffers.end() || !(it->second.usage.*flag)) {
            add(what, name + " " + (it == buffers.end() ? std::string() : quoted(it->second.label) + " ") +
                          "was not made with usage." + flagName);
            return nullptr;
        }
        return &it->second;
    }

    void check_geometries(std::string& what, std::span<const AccelTriangles> geometries, std::uint64_t& primitives) const {
        primitives = 0;
        if (geometries.empty()) {
            add(what, "no geometries: a BLAS needs at least one triangle geometry");
            return;
        }
        if (geometries.size() > lim.maxAccelGeometries)
            add(what, std::to_string(geometries.size()) + " geometries are more than this device's limit " +
                          std::to_string(lim.maxAccelGeometries) +
                          " (Limits::maxAccelGeometries): merge meshes into fewer geometries, or build several BLASes");
        int problems = 0;
        for (std::size_t i = 0; i < geometries.size(); ++i) {
            const AccelTriangles& g = geometries[i];
            primitives += g.primitive_count();
            if (problems >= kMaxReportedProblems) continue;
            const std::string n = geometry_name(i);
            const std::size_t before = what.size();
            if (g.vertexFormat != VertexFormat::Float3)
                add(what, n + ".vertexFormat is not Float3: three 32-bit floats are the one position format every "
                               "backend takes");
            if (g.vertexStride < 12 || g.vertexStride % 4 != 0)
                add(what, n + ".vertexStride " + std::to_string(g.vertexStride) +
                              " is not a multiple of 4 that is at least 12 (the size of a Float3 position)");
            if (g.vertexOffset % 4 != 0)
                add(what, n + ".vertexOffset " + std::to_string(g.vertexOffset) +
                              " is not a multiple of 4 (Metal reads positions at 4-byte aligned addresses)");
            if (g.indexBuffer.valid()) {
                if (g.indexType != IndexType::Uint16 && g.indexType != IndexType::Uint32) {
                    add(what, n + " has an index buffer but indexType is not Uint16 or Uint32");
                } else if (g.indexOffset % (g.indexType == IndexType::Uint16 ? 2u : 4u) != 0) {
                    add(what, n + ".indexOffset " + std::to_string(g.indexOffset) +
                                  " is not a multiple of the index size (Metal needs it)");
                }
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
        if (primitives > lim.maxAccelPrimitives)
            add(what, std::to_string(primitives) + " triangles are more than this device's limit " +
                          std::to_string(lim.maxAccelPrimitives) + " (Limits::maxAccelPrimitives)");
    }

    // ---- descriptors ----------------------------------------------------------------------------------------------
    static MTLAccelerationStructureUsage usage_of(const AccelBuildFlags& f) {
        MTLAccelerationStructureUsage u = MTLAccelerationStructureUsageNone;
        if (f.allowUpdate) u |= MTLAccelerationStructureUsageRefit;
        if (f.preferFastBuild) u |= MTLAccelerationStructureUsagePreferFastBuild;
        return u;
    }

    id<MTLBuffer> mtl_buffer(Buffer b) const { return (__bridge id<MTLBuffer>)device.native_buffer(b).buffer; }

    // The descriptor of a BLAS build; `withBuffers` false = the sizes query (no buffer is read there).
    MTLPrimitiveAccelerationStructureDescriptor* primitive_descriptor(std::span<const AccelTriangles> geometries,
                                                                      const AccelBuildFlags& flags,
                                                                      bool withBuffers) const {
        NSMutableArray<MTLAccelerationStructureGeometryDescriptor*>* list =
            [NSMutableArray arrayWithCapacity:geometries.size()];
        for (const AccelTriangles& g : geometries) {
            MTLAccelerationStructureTriangleGeometryDescriptor* t = [MTLAccelerationStructureTriangleGeometryDescriptor descriptor];
            t.triangleCount = NSUInteger(g.primitive_count());
            t.vertexFormat = MTLAttributeFormatFloat3;
            t.vertexStride = g.vertexStride;
            t.opaque = g.opaque;
            const bool indexed = g.indexBuffer.valid();
            if (indexed) t.indexType = g.indexType == IndexType::Uint16 ? MTLIndexTypeUInt16 : MTLIndexTypeUInt32;
            if (withBuffers) {
                t.vertexBuffer = mtl_buffer(g.vertexBuffer);
                t.vertexBufferOffset = g.vertexOffset;
                if (indexed) {
                    t.indexBuffer = mtl_buffer(g.indexBuffer);
                    t.indexBufferOffset = g.indexOffset;
                }
            }
            [list addObject:t];
        }
        MTLPrimitiveAccelerationStructureDescriptor* d = [MTLPrimitiveAccelerationStructureDescriptor descriptor];
        d.geometryDescriptors = list;
        d.usage = usage_of(flags);
        return d;
    }

    MTLInstanceAccelerationStructureDescriptor* instance_descriptor(std::uint32_t count, const AccelBuildFlags& flags) const {
        MTLInstanceAccelerationStructureDescriptor* d = [MTLInstanceAccelerationStructureDescriptor descriptor];
        d.instanceCount = count;
        d.instanceDescriptorType = MTLAccelerationStructureInstanceDescriptorTypeUserID;
        d.instanceDescriptorStride = sizeof(MTLAccelerationStructureUserIDInstanceDescriptor);
        d.usage = usage_of(flags);
        return d;
    }

    // An instance buffer of at least `bytes` (a free one, or a new one); give_back returns it when the command buffer ends.
    id<MTLBuffer> take_instance_buffer(std::size_t bytes) {
        {
            std::lock_guard<std::mutex> lock(instances->mutex);
            std::size_t best = instances->free.size();
            for (std::size_t i = 0; i < instances->free.size(); ++i)
                if (instances->free[i].length >= bytes &&
                    (best == instances->free.size() || instances->free[i].length < instances->free[best].length))
                    best = i;
            if (best != instances->free.size()) {
                id<MTLBuffer> b = instances->free[best];
                instances->free.erase(instances->free.begin() + std::ptrdiff_t(best));
                return b;
            }
        }
        std::size_t size = 4096;
        while (size < bytes) size *= 2;
        return [mtl newBufferWithLength:size options:MTLResourceStorageModeShared];
    }

    // sokol's current command buffer (made now when the frame has none: sokol_gfx waits there for the oldest frame in flight
    // to finish through its semaphore of frames in flight, as the next pass would: outside a frame this BLOCKS the calling thread
    // for up to one frame of GPU time (as long as a hung GPU takes). Nil only when the device lost its queue.
    id<MTLCommandBuffer> command_buffer() const {
        MetalNative* native = device.native_metal();
        id<MTLCommandBuffer> cb = native ? (__bridge id<MTLCommandBuffer>)native->current_command_buffer() : nil;
        if (cb && !queue) queue = cb.commandQueue;
        return cb;
    }

    // Lets go of an acceleration structure (and the BLASes a TLAS named) only once the GPU has finished the work recorded so
    // far. sokol acquires its command buffer WITHOUT retained references (commandBufferWithUnretainedReferences), so neither
    // the acceleration structure encoder nor useResource: keeps anything alive: a structure released here while frame N still
    // traces it would be freed under the GPU. The current command buffer completes after every earlier one on the queue, so
    // its completion handler (which owns the references until it has run) is a safe place. command_buffer() asks for one,
    // and outside a frame that can block on sokol's semaphore of frames in flight (see there); it
    // is nil only when the device lost its queue, and then nothing can complete and the references go at once.
    void retire(id<MTLAccelerationStructure> as, NSArray<id<MTLAccelerationStructure>>* array) {
        if (!as && !array) return;
        id<MTLCommandBuffer> cb = command_buffer();
        if (!cb) return;
        [cb addCompletedHandler:^(id<MTLCommandBuffer>) {
            (void)as;
            (void)array;
        }];
    }

    const char* flag_name(bool update) const { return update ? "updateScratch" : "buildScratch"; }

    // Whether `scratch` (usage accelScratch, a live buffer) holds `need` bytes at `offset`.
    void check_scratch(std::string& what, Buffer scratch, std::size_t offset, std::uint64_t need, bool update) const {
        const BufferInfo* s = buffer_info(what, "scratch", scratch, "accelScratch", &BufferUsage::accelScratch);
        if (!s) return;
        const std::uint64_t align = device.accel_scratch_alignment();
        if (align != 0 && offset % align != 0)
            add(what, "scratchOffset " + std::to_string(offset) + " is not a multiple of " + std::to_string(align) +
                          " (Device::accel_scratch_alignment())");
        if (offset > s->size || s->size - offset < need)
            add(what, "scratch buffer " + quoted(s->label) + " has " +
                          std::to_string(s->size > offset ? s->size - offset : 0) + " bytes from scratchOffset " +
                          std::to_string(offset) + ", but this " + (update ? "update" : "build") + " needs " +
                          std::to_string(need) + " (AccelSizes::" + flag_name(update) + ")");
    }
};

// ---------------------------------------------------------------------------------------------------------------------
MetalAccel::MetalAccel() = default;
MetalAccel::~MetalAccel() = default;

void MetalAccel::wait_idle() {
    // An empty command buffer queued behind every one committed so far on sokol's queue completes after them, so the
    // structures they trace are no longer in use. The queue is the one the first build saw: nil = this device never
    // encoded anything, nothing can be in flight. No call into sokol.
    if (!impl_->queue) return;
    id<MTLCommandBuffer> fence = [impl_->queue commandBuffer];
    if (!fence) return;
    fence.label = @"factoria: acceleration structures idle";
    [fence commit];
    [fence waitUntilCompleted];
}

bool MetalAccel::supported(const void* mtlDevice, std::string* why) {
    id<MTLDevice> dev = (__bridge id<MTLDevice>)mtlDevice;
    const std::string gpu = quoted(device_name(dev));
    auto no = [&](const std::string& reason) {
        if (why) *why = reason;
        return false;
    };
    if (!dev) return no("there is no Metal device to ask");
    if (@available(macOS 13.0, iOS 16.0, *)) {
        if (![dev supportsRaytracing])
            return no("the GPU " + gpu + " does not support Metal ray tracing (MTLDevice.supportsRaytracing is false on " +
                      os_version() + "; an Apple 6 GPU, an M1 or later, or an AMD or Intel Mac GPU of macOS 13 can)");
        return true;
    }
    return no("Metal ray queries need macOS 13 or iOS 16, and this is " + os_version() + " (GPU " + gpu + ")");
}

std::unique_ptr<MetalAccel> MetalAccel::create(Device& device, const void* mtlDevice) {
    if (!supported(mtlDevice, nullptr)) return nullptr;
    std::unique_ptr<MetalAccel> a(new MetalAccel());
    a->impl_ = std::make_unique<Impl>(device, (__bridge id<MTLDevice>)mtlDevice);
    return a;
}

Limits MetalAccel::limits() const { return impl_->lim; }

void MetalAccel::note_buffer(Buffer buffer, const BufferUsage& usage, std::size_t size, const char* label) {
    if (!buffer.valid()) return;
    if (!(usage.accelBuildInput || usage.accelStorage || usage.accelScratch || usage.storageBuffer)) return;
    impl_->buffers[buffer.id] = Impl::BufferInfo{usage, size, label ? label : ""};
}

void MetalAccel::forget_buffer(Buffer buffer) { impl_->buffers.erase(buffer.id); }

// ---- sizes ----------------------------------------------------------------------------------------------------------
Result<AccelSizes> MetalAccel::blas_sizes(std::span<const AccelTriangles> geometries, const AccelBuildFlags& flags) {
    @autoreleasepool {
        std::string what;
        std::uint64_t primitives = 0;
        impl_->check_geometries(what, geometries, primitives);
        if (!what.empty())
            return Error{"gpu: blas_sizes: " + what,
                         "give 1 to Limits::maxAccelGeometries triangle geometries (Float3 positions, a multiple of 3 "
                         "indices) with at most Limits::maxAccelPrimitives triangles in all"};
        MTLAccelerationStructureSizes s =
            [impl_->mtl accelerationStructureSizesWithDescriptor:impl_->primitive_descriptor(geometries, flags, false)];
        AccelSizes out;
        out.structure = s.accelerationStructureSize;
        out.buildScratch = s.buildScratchBufferSize;
        out.updateScratch = flags.allowUpdate ? s.refitScratchBufferSize : 0;
        return out;
    }
}

Result<AccelSizes> MetalAccel::tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags) {
    @autoreleasepool {
        std::string what;
        if (instanceCount == 0) add(what, "0 instances: skip the TLAS build when the scene has none");
        if (instanceCount > impl_->lim.maxAccelInstances)
            add(what, std::to_string(instanceCount) + " instances are more than this device's limit " +
                          std::to_string(impl_->lim.maxAccelInstances) +
                          " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
        if (!what.empty()) return Error{"gpu: tlas_sizes: " + what, "ask for 1 to Limits::maxAccelInstances instances"};
        MTLAccelerationStructureSizes s =
            [impl_->mtl accelerationStructureSizesWithDescriptor:impl_->instance_descriptor(instanceCount, flags)];
        AccelSizes out;
        out.structure = s.accelerationStructureSize;
        out.buildScratch = s.buildScratchBufferSize;
        out.updateScratch = flags.allowUpdate ? s.refitScratchBufferSize : 0;
        return out;
    }
}

// ---- the structures -------------------------------------------------------------------------------------------------
Result<AccelStructure> MetalAccel::make_accel_structure(const AccelStructureDesc& d) {
    @autoreleasepool {
        std::string what;
        if (d.size == 0) add(what, "AccelStructureDesc::size is 0: take it from blas_sizes() / tlas_sizes()");
        if (d.storage.valid())
            add(what, "AccelStructureDesc::storage is set, but Metal allocates an acceleration structure itself "
                      "(newAccelerationStructureWithSize:) and cannot place one inside a buffer");
        if (!what.empty())
            return Error{"gpu: make_accel_structure: " + what,
                         "size the structure from blas_sizes() / tlas_sizes() and leave storage and storageOffset empty "
                         "on Metal (check Device::backend() == Backend::Metal; D3D12 and Vulkan place a structure in a "
                         "buffer with usage.accelStorage)"};
        Impl& m = *impl_;
        std::uint16_t slot = 0;
        if (!m.freeSlots.empty()) {
            slot = m.freeSlots.back();
            m.freeSlots.pop_back();
        } else if (m.pool.size() < 0xFFFEu) {
            slot = std::uint16_t(m.pool.size());
            m.pool.emplace_back();
        } else {
            return Error{"gpu: make_accel_structure: the acceleration structure pool is full (65534)",
                         "destroy structures no longer traced (destroy_accel_structure), or merge meshes into fewer BLASes"};
        }
        id<MTLAccelerationStructure> as = [m.mtl newAccelerationStructureWithSize:NSUInteger(d.size)];
        if (!as) {
            m.freeSlots.push_back(slot);
            return Error{"gpu: make_accel_structure: Metal could not allocate " + std::to_string(d.size) +
                             " bytes for an acceleration structure (" + device_name(m.mtl) + ")",
                         "ask blas_sizes() / tlas_sizes() for fewer triangles or instances, or free GPU memory"};
        }
        if (d.label && *d.label) as.label = [NSString stringWithUTF8String:d.label];
        Impl::Entry& e = m.pool[slot];
        const std::uint16_t generation = e.generation;
        e = Impl::Entry{};
        e.generation = generation;
        e.alive = true;
        e.kind = d.kind;
        e.size = d.size;
        e.label = d.label ? d.label : "";
        e.as = as;
        return AccelStructure{Impl::make_id(slot, generation)};
    }
}

void MetalAccel::destroy_accel_structure(AccelStructure structure) {
    Impl& m = *impl_;
    Impl::Entry* e = m.find(structure);
    if (!e) return;
    const std::uint16_t slot = std::uint16_t((structure.id & 0xFFFFu) - 1);
    // The command buffers in flight may still read it (sokol's are unretained: nothing else keeps it alive), and the BLASes a
    // TLAS names that were destroyed earlier are kept by that TLAS only: both go once the GPU is done with the work so far.
    id<MTLAccelerationStructure> as = e->as;
    NSArray<id<MTLAccelerationStructure>>* array = e->primitives_array;
    e->as = nil;
    e->primitives_array = nil;
    m.retire(as, array);
    e->alive = false;
    e->generation = std::uint16_t(e->generation + 1 == 0 ? 1 : e->generation + 1);
    m.freeSlots.push_back(slot);
}

ResourceState MetalAccel::accel_structure_state(AccelStructure structure) const {
    return impl_->find(structure) ? ResourceState::Valid : ResourceState::Invalid;
}

// ---- builds ---------------------------------------------------------------------------------------------------------
Result<void> MetalAccel::build_blas(const BlasBuild& b) {
    @autoreleasepool {
        Impl& m = *impl_;
        std::string what;
        Impl::Entry* dst = m.find(b.dst);
        if (!dst)
            add(what, "dst is " + m.describe(b.dst));
        else if (dst->kind != AccelKind::Blas)
            add(what, "dst " + accel_label(dst->label, dst->kind) + " is a TLAS: build_blas writes a BLAS (build_tlas builds a TLAS)");
        std::uint64_t primitives = 0;
        m.check_geometries(what, b.geometries, primitives);
        int problems = 0;
        for (std::size_t i = 0; i < b.geometries.size() && problems < kMaxReportedProblems; ++i) {
            const AccelTriangles& g = b.geometries[i];
            const std::string n = geometry_name(i);
            const std::size_t before = what.size();
            if (const auto* vb = m.buffer_info(what, n + ".vertexBuffer", g.vertexBuffer, "accelBuildInput",
                                               &BufferUsage::accelBuildInput)) {
                const std::uint64_t need = g.vertexCount == 0 ? 0
                                                              : std::uint64_t(g.vertexOffset) +
                                                                    std::uint64_t(g.vertexCount - 1) * g.vertexStride + 12;
                if (need > vb->size)
                    add(what, n + " reads " + std::to_string(g.vertexCount) + " vertices up to byte " +
                                  std::to_string(need) + ", but vertex buffer " + quoted(vb->label) + " has " +
                                  std::to_string(vb->size) + " bytes");
            }
            if (g.indexBuffer.valid()) {
                if (const auto* ib = m.buffer_info(what, n + ".indexBuffer", g.indexBuffer, "accelBuildInput",
                                                   &BufferUsage::accelBuildInput)) {
                    const std::uint64_t width = g.indexType == IndexType::Uint16 ? 2 : 4;
                    const std::uint64_t need = std::uint64_t(g.indexOffset) + std::uint64_t(g.indexCount) * width;
                    if (need > ib->size)
                        add(what, n + " reads " + std::to_string(g.indexCount) + " indices up to byte " +
                                      std::to_string(need) + ", but index buffer " + quoted(ib->label) + " has " +
                                      std::to_string(ib->size) + " bytes");
                }
            }
            if (what.size() != before) ++problems;
        }
        AccelSizes need;
        bool sized = false;
        if (what.empty()) {
            MTLAccelerationStructureSizes s = [m.mtl
                accelerationStructureSizesWithDescriptor:m.primitive_descriptor(b.geometries, b.flags, false)];
            need.structure = s.accelerationStructureSize;
            need.buildScratch = s.buildScratchBufferSize;
            need.updateScratch = s.refitScratchBufferSize;
            sized = true;
            if (dst && dst->size < need.structure)
                add(what, "dst " + accel_label(dst->label, AccelKind::Blas) + " has " + std::to_string(dst->size) +
                              " bytes but these geometries need " + std::to_string(need.structure) +
                              " (AccelSizes::structure of blas_sizes with the same flags)");
        }
        Impl::Entry* src = nullptr;
        if (b.update) {
            const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
            src = m.find(srcHandle);
            if (!src) {
                add(what, "src is " + m.describe(srcHandle));
            } else if (src->kind != AccelKind::Blas) {
                add(what, "src " + accel_label(src->label, src->kind) + " is a TLAS: a BLAS refits from a BLAS");
            } else if (!src->built) {
                add(what, "update of " + accel_label(src->label, AccelKind::Blas) + ", which was never built");
            } else if (!src->allowUpdate) {
                add(what, "update of " + accel_label(src->label, AccelKind::Blas) +
                              ", which was built without flags.allowUpdate");
            } else if (src->geometries != b.geometries.size() || src->primitives != primitives) {
                add(what, "update with " + std::to_string(b.geometries.size()) + " geometries and " +
                              std::to_string(primitives) + " triangles, but " + accel_label(src->label, AccelKind::Blas) +
                              " was built with " + std::to_string(src->geometries) + " and " +
                              std::to_string(src->primitives) + ": a refit keeps the topology");
            }
            if (!b.flags.allowUpdate)
                add(what, "update with flags.allowUpdate false (pass the flags the BLAS was built with)");
        }
        if (sized)
            m.check_scratch(what, b.scratch, b.scratchOffset, b.update ? need.updateScratch : need.buildScratch, b.update);
        else
            (void)m.buffer_info(what, "scratch", b.scratch, "accelScratch", &BufferUsage::accelScratch);
        if (!what.empty())
            return Error{"gpu: build_blas: " + what,
                         "size the BLAS and the scratch buffer from blas_sizes() with the flags of the build, give every "
                         "geometry live buffers with usage.accelBuildInput, and refit only what was built with allowUpdate"};

        id<MTLCommandBuffer> cb = m.command_buffer();
        if (!cb)
            return Error{"gpu: build_blas: the Metal device has no command buffer to record into",
                         "the device lost its queue; recreate the renderer"};
        MTLPrimitiveAccelerationStructureDescriptor* desc = m.primitive_descriptor(b.geometries, b.flags, true);
        id<MTLAccelerationStructureCommandEncoder> enc = [cb accelerationStructureCommandEncoder];
        id<MTLBuffer> scratch = m.mtl_buffer(b.scratch);
        if (b.update) {
            const bool inPlace = src == dst;
            [enc refitAccelerationStructure:src->as
                                 descriptor:desc
                                destination:inPlace ? nil : dst->as
                              scratchBuffer:scratch
                        scratchBufferOffset:b.scratchOffset];
        } else {
            [enc buildAccelerationStructure:dst->as descriptor:desc scratchBuffer:scratch scratchBufferOffset:b.scratchOffset];
        }
        [enc endEncoding];
        dst->built = true;
        dst->allowUpdate = b.flags.allowUpdate;
        dst->allowCompaction = b.flags.allowCompaction;
        dst->geometries = std::uint32_t(b.geometries.size());
        dst->primitives = primitives;
        return {};
    }
}

Result<void> MetalAccel::build_tlas(const TlasBuild& b) {
    @autoreleasepool {
        Impl& m = *impl_;
        std::string what;
        Impl::Entry* dst = m.find(b.dst);
        if (!dst)
            add(what, "dst is " + m.describe(b.dst));
        else if (dst->kind != AccelKind::Tlas)
            add(what, "dst " + accel_label(dst->label, dst->kind) + " is a BLAS: build_tlas writes a TLAS (build_blas builds a BLAS)");
        const std::size_t n = b.instances.size();
        if (n == 0) add(what, "no instances: skip the TLAS build when the scene has none");
        if (n > m.lim.maxAccelInstances)
            add(what, std::to_string(n) + " instances are more than this device's limit " +
                          std::to_string(m.lim.maxAccelInstances) +
                          " (Limits::maxAccelInstances): trace fewer instances (render.rayTracing.maxInstances)");
        int problems = 0;
        for (std::size_t i = 0; i < n && problems < kMaxReportedProblems && n <= m.lim.maxAccelInstances; ++i) {
            const AccelInstance& in = b.instances[i];
            const std::string name = "instances[" + std::to_string(i) + "]";
            const std::size_t before = what.size();
            const Impl::Entry* blas = m.find(in.blas);
            if (!blas)
                add(what, name + ".blas is " + m.describe(in.blas) +
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
            if (what.size() != before) ++problems;
        }
        AccelSizes need;
        bool sized = false;
        if (n > 0 && n <= m.lim.maxAccelInstances) {
            MTLAccelerationStructureSizes s =
                [m.mtl accelerationStructureSizesWithDescriptor:m.instance_descriptor(std::uint32_t(n), b.flags)];
            need.structure = s.accelerationStructureSize;
            need.buildScratch = s.buildScratchBufferSize;
            need.updateScratch = s.refitScratchBufferSize;
            sized = true;
            if (dst && dst->size < need.structure)
                add(what, "dst " + accel_label(dst->label, AccelKind::Tlas) + " has " + std::to_string(dst->size) +
                              " bytes but " + std::to_string(n) + " instances need " + std::to_string(need.structure) +
                              " (AccelSizes::structure of tlas_sizes with the same flags)");
        }
        Impl::Entry* src = nullptr;
        if (b.update) {
            const AccelStructure srcHandle = b.src.valid() ? b.src : b.dst;
            src = m.find(srcHandle);
            if (!src) {
                add(what, "src is " + m.describe(srcHandle));
            } else if (src->kind != AccelKind::Tlas) {
                add(what, "src " + accel_label(src->label, src->kind) + " is a BLAS: a TLAS refits from a TLAS");
            } else if (!src->built) {
                add(what, "update of " + accel_label(src->label, AccelKind::Tlas) + ", which was never built");
            } else if (!src->allowUpdate) {
                add(what, "update of " + accel_label(src->label, AccelKind::Tlas) +
                              ", which was built without flags.allowUpdate");
            } else if (src->instances != n) {
                add(what, "update with " + std::to_string(n) + " instances, but " + accel_label(src->label, AccelKind::Tlas) +
                              " was built with " + std::to_string(src->instances) + ": a refit keeps the count");
            }
            if (!b.flags.allowUpdate)
                add(what, "update with flags.allowUpdate false (pass the flags the TLAS was built with)");
        }
        if (sized)
            m.check_scratch(what, b.scratch, b.scratchOffset, b.update ? need.updateScratch : need.buildScratch, b.update);
        else
            (void)m.buffer_info(what, "scratch", b.scratch, "accelScratch", &BufferUsage::accelScratch);
        if (!what.empty())
            return Error{"gpu: build_tlas: " + what,
                         "build every BLAS the instances name first (and keep it alive), size the TLAS and the scratch "
                         "buffer from tlas_sizes() with the flags of the build, and keep the instance count within "
                         "Limits::maxAccelInstances"};

        id<MTLCommandBuffer> cb = m.command_buffer();
        if (!cb)
            return Error{"gpu: build_tlas: the Metal device has no command buffer to record into",
                         "the device lost its queue; recreate the renderer"};
        // The instance descriptors: the transform goes from row-major 3x4 to Metal's column-major 4x3, customIndex is the
        // user id the kernel reads back, and the BLASes are named by their index in the array the descriptor holds.
        NSMutableArray<id<MTLAccelerationStructure>>* blases = [NSMutableArray array];
        std::unordered_map<std::uint32_t, std::uint32_t> blasIndex;
        const std::size_t bytes = n * sizeof(MTLAccelerationStructureUserIDInstanceDescriptor);
        id<MTLBuffer> instanceBuffer = m.take_instance_buffer(bytes);
        auto* out = static_cast<MTLAccelerationStructureUserIDInstanceDescriptor*>(instanceBuffer.contents);
        for (std::size_t i = 0; i < n; ++i) {
            const AccelInstance& in = b.instances[i];
            auto it = blasIndex.find(in.blas.id);
            if (it == blasIndex.end()) {
                it = blasIndex.emplace(in.blas.id, std::uint32_t(blases.count)).first;
                [blases addObject:m.find(in.blas)->as];
            }
            MTLAccelerationStructureUserIDInstanceDescriptor& o = out[i];
            std::memset(&o, 0, sizeof o);
            for (int c = 0; c < 4; ++c)
                o.transformationMatrix.columns[c] = MTLPackedFloat3Make(in.transform[c], in.transform[4 + c], in.transform[8 + c]);
            o.options = MTLAccelerationStructureInstanceOptionNone;
            if (in.opaque) o.options |= MTLAccelerationStructureInstanceOptionOpaque;
            if (in.cullDisable) o.options |= MTLAccelerationStructureInstanceOptionDisableTriangleCulling;
            o.mask = in.mask;
            o.intersectionFunctionTableOffset = 0;
            o.accelerationStructureIndex = it->second;
            o.userID = in.customIndex;
        }
        MTLInstanceAccelerationStructureDescriptor* desc = m.instance_descriptor(std::uint32_t(n), b.flags);
        desc.instanceDescriptorBuffer = instanceBuffer;
        desc.instanceDescriptorBufferOffset = 0;
        desc.instancedAccelerationStructures = blases;

        id<MTLAccelerationStructureCommandEncoder> enc = [cb accelerationStructureCommandEncoder];
        id<MTLBuffer> scratch = m.mtl_buffer(b.scratch);
        if (b.update) {
            const bool inPlace = src == dst;
            [enc refitAccelerationStructure:src->as
                                 descriptor:desc
                                destination:inPlace ? nil : dst->as
                              scratchBuffer:scratch
                        scratchBufferOffset:b.scratchOffset];
        } else {
            [enc buildAccelerationStructure:dst->as descriptor:desc scratchBuffer:scratch scratchBufferOffset:b.scratchOffset];
        }
        [enc endEncoding];
        // The instance buffer goes back to the pool once the GPU has read it.
        std::shared_ptr<InstancePool> pool = m.instances;
        [cb addCompletedHandler:^(id<MTLCommandBuffer>) {
            std::lock_guard<std::mutex> lock(pool->mutex);
            if (pool->free.size() < kMaxFreeInstanceBuffers) pool->free.push_back(instanceBuffer);
        }];
        dst->built = true;
        dst->allowUpdate = b.flags.allowUpdate;
        dst->instances = std::uint32_t(n);
        NSArray<id<MTLAccelerationStructure>>* previous = dst->primitives_array;
        dst->primitives_array = blases;
        m.retire(nil, previous);  // the previous trace of this TLAS may still be in flight
        return {};
    }
}

Result<void> MetalAccel::query_compacted_size(AccelStructure blas, Buffer dstBuffer, std::size_t dstOffset) {
    @autoreleasepool {
        Impl& m = *impl_;
        std::string what;
        Impl::Entry* a = m.find(blas);
        if (!a)
            add(what, "blas is " + m.describe(blas));
        else if (a->kind != AccelKind::Blas)
            add(what, accel_label(a->label, a->kind) + " is a TLAS: only a BLAS is compacted");
        else if (!a->built)
            add(what, accel_label(a->label, AccelKind::Blas) + " was never built");
        else if (!a->allowCompaction)
            add(what, accel_label(a->label, AccelKind::Blas) + " was built without flags.allowCompaction");
        if (const auto* d = m.buffer_info(what, "dst", dstBuffer, "storageBuffer", &BufferUsage::storageBuffer)) {
            if (dstOffset % 8 != 0) add(what, "dstOffset " + std::to_string(dstOffset) + " is not a multiple of 8");
            if (dstOffset > d->size || d->size - dstOffset < 8)
                add(what, "8 bytes at offset " + std::to_string(dstOffset) + " do not fit in buffer " + quoted(d->label) +
                              " (" + std::to_string(d->size) + " bytes)");
        }
        if (!what.empty())
            return Error{"gpu: query_compacted_size: " + what,
                         "build the BLAS with flags.allowCompaction, and give a storage buffer with 8 bytes free at an "
                         "8-byte aligned offset"};
        id<MTLCommandBuffer> cb = m.command_buffer();
        if (!cb)
            return Error{"gpu: query_compacted_size: the Metal device has no command buffer to record into",
                         "the device lost its queue; recreate the renderer"};
        id<MTLAccelerationStructureCommandEncoder> enc = [cb accelerationStructureCommandEncoder];
        // sizeDataType ULong: the size lands as one little-endian uint64, the seam's contract (the default is a uint32).
        [enc writeCompactedAccelerationStructureSize:a->as
                                            toBuffer:m.mtl_buffer(dstBuffer)
                                              offset:dstOffset
                                        sizeDataType:MTLDataTypeULong];
        [enc endEncoding];
        return {};
    }
}

Result<void> MetalAccel::copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode) {
    @autoreleasepool {
        Impl& m = *impl_;
        std::string what;
        Impl::Entry* a = m.find(src);
        Impl::Entry* d = m.find(dst);
        if (!a) add(what, "src is " + m.describe(src));
        if (!d) add(what, "dst is " + m.describe(dst));
        if (a && d) {
            if (a == d) add(what, "src and dst are the same structure");
            if (a->kind != d->kind)
                add(what, "src is a " + std::string(accel_kind_name(a->kind)) + " and dst a " + accel_kind_name(d->kind));
            if (!a->built) add(what, accel_label(a->label, a->kind) + " was never built");
            if (mode == AccelCopyMode::Compact) {
                if (!a->allowCompaction)
                    add(what, "Compact needs " + accel_label(a->label, a->kind) +
                                  " built with flags.allowCompaction (it was not)");
                if (d->size > a->size)
                    add(what, "Compact into " + accel_label(d->label, d->kind) + " of " + std::to_string(d->size) +
                                  " bytes, larger than the source's " + std::to_string(a->size) +
                                  ": make the target with the size query_compacted_size answered");
            } else if (d->size < a->size) {
                add(what, "Clone into " + accel_label(d->label, d->kind) + " of " + std::to_string(d->size) +
                              " bytes, smaller than the source's " + std::to_string(a->size));
            }
        }
        if (!what.empty())
            return Error{"gpu: copy_accel_structure: " + what,
                         "copy a built structure into one of the same kind: Compact into a smaller one made with the "
                         "queried size (source built with allowCompaction), Clone into one at least as large"};
        id<MTLCommandBuffer> cb = m.command_buffer();
        if (!cb)
            return Error{"gpu: copy_accel_structure: the Metal device has no command buffer to record into",
                         "the device lost its queue; recreate the renderer"};
        id<MTLAccelerationStructureCommandEncoder> enc = [cb accelerationStructureCommandEncoder];
        if (mode == AccelCopyMode::Compact)
            [enc copyAndCompactAccelerationStructure:a->as toAccelerationStructure:d->as];
        else
            [enc copyAccelerationStructure:a->as toAccelerationStructure:d->as];
        [enc endEncoding];
        d->built = true;
        d->allowUpdate = a->allowUpdate;
        d->allowCompaction = false;  // a compacted structure is not compacted again
        d->geometries = a->geometries;
        d->primitives = a->primitives;
        d->instances = a->instances;
        NSArray<id<MTLAccelerationStructure>>* previous = d->primitives_array;
        d->primitives_array = a->primitives_array;  // a cloned or compacted TLAS names the same BLASes
        m.retire(nil, previous);
        return {};
    }
}

// ---- tracing --------------------------------------------------------------------------------------------------------
std::string MetalAccel::check_compute_bindings(const Bindings& bindings, const MetalAccelSlots& slots,
                                               const char* shaderLabel) const {
    const Impl& m = *impl_;
    std::string what;
    const std::string shader = quoted(shaderLabel ? shaderLabel : "");
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        const std::string slot = "accelStructures[" + std::to_string(i) + "]";
        const AccelStructure h = bindings.accelStructures[i];
        if (!slots.declared[i]) {
            if (h.valid())
                add(what, slot + " is bound but shader " + shader + " declares no acceleration structure there");
            continue;
        }
        const Impl::Entry* e = m.find(h);
        if (!e)
            add(what, slot + " (shader " + shader + ") is " + m.describe(h));
        else if (e->kind != AccelKind::Tlas)
            add(what, slot + " is the BLAS " + quoted(e->label) +
                          ", but a ray query traces against a TLAS (build a TLAS over it and bind that)");
        else if (!e->built)
            add(what, slot + " is the TLAS " + quoted(e->label) +
                          ", which build_tlas has not built yet (record build_tlas before the dispatch that traces it)");
    }
    return what;
}

void MetalAccel::bind_compute(const Bindings& bindings, const MetalAccelSlots& slots) {
    Impl& m = *impl_;
    id<MTLComputeCommandEncoder> enc = (__bridge id<MTLComputeCommandEncoder>)sg_mtl_compute_command_encoder();
    if (!enc) {
        if (!m.warnedNoEncoder) {
            m.warnedNoEncoder = true;
            FA_ERROR("render",
                     "gpu: CommandList::set_bindings: shader '{}' has no compute encoder to bind its acceleration "
                     "structure to (sokol did not open one); the dispatch traces nothing (said once)",
                     slots.label);
        }
        return;
    }
    for (int i = 0; i < kMaxAccelStructureBindings; ++i) {
        if (!slots.declared[i]) continue;
        const Impl::Entry* e = m.find(bindings.accelStructures[i]);
        if (!e || !e->as) {
            if (!m.warnedInvalidStructure) {
                m.warnedInvalidStructure = true;
                FA_ERROR("render",
                         "gpu: CommandList::set_bindings: accelStructures[{}] of shader '{}' went invalid after the "
                         "bindings were checked; the dispatch traces nothing there (said once)",
                         i, slots.label);
            }
            continue;
        }
        [enc setAccelerationStructure:e->as atBufferIndex:slots.bufferIndex[i]];
        // Binding a TLAS does not make the BLASes it names (or itself) resident for the dispatch.
        [enc useResource:e->as usage:MTLResourceUsageRead];
        for (id<MTLAccelerationStructure> blas in e->primitives_array) [enc useResource:blas usage:MTLResourceUsageRead];
    }
}

}  // namespace fa::gpu

#endif  // SOKOL_METAL
