// Private to fa_render: Metal ray tracing inside the sokol device (M79 P1m; docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md,
// "Metal"). SokolDevice on Metal owns one MetalAccel and forwards the acceleration structure calls of gpu/device.h to it; the
// implementation is metal_accel_apple.mm. sokol_gfx knows no acceleration structure, so everything here is the engine's own
// Metal work on sokol's MTLDevice and command buffer (the MetalFX precedent, metalfx_apple.mm).
//
// What lives where:
//  * The structures are MTLAccelerationStructure objects the device allocates (newAccelerationStructureWithSize:), kept in
//    a pool of this class and named by AccelStructure handles. They are not in a gpu::Buffer: AccelStructureDesc::storage is
//    refused on Metal.
//  * Builds, refits, compaction and clones are encoded in an MTLAccelerationStructureCommandEncoder on sokol's current
//    command buffer, outside any pass (sokol's blit encoder is finished first). One encoder per call: Metal orders encoders
//    of one command buffer through hazard tracking of the resources they use (sokol's buffers and the structures are
//    tracked), so a BLAS build, the TLAS build that reads it and the compute dispatch that traces it run in that order.
//  * The compute dispatch is sokol's own (a compute shader with the MSL kernel, its uniforms and storage image bound by
//    sokol); only the acceleration structure is bound here, on sokol's compute encoder right after sg_apply_bindings
//    (MetalAccel::bind_compute): setAccelerationStructure:atBufferIndex: for the TLAS and useResource: for it and for every
//    BLAS it names (a TLAS does not make them resident).
#pragma once

#include <cstdint>
#include <memory>
#include <span>
#include <string>

#include "gpu/device.h"

namespace fa::gpu {

// The buffer slots a compute shader declares its acceleration structures in (ShaderDesc::accelStructures), kept per
// pipeline by SokolDevice so set_bindings can bind them.
struct MetalAccelSlots {
    std::string label;  // the shader's label, for the errors of a bad binding
    bool declared[kMaxAccelStructureBindings]{};
    std::uint8_t bufferIndex[kMaxAccelStructureBindings]{};
};

class MetalAccel {
public:
    // Whether this MTLDevice (NativeDevice::device) and this OS can trace rays with the kernels the engine ships (MSL 2.4:
    // macOS 13 / iOS 16, MTLDevice.supportsRaytracing). False + a sentence that names the device and the OS in `why`.
    static bool supported(const void* mtlDevice, std::string* why);
    // The ray tracing of `device` (a SokolDevice on Metal); null when supported() is false.
    static std::unique_ptr<MetalAccel> create(Device& device, const void* mtlDevice);
    ~MetalAccel();
    MetalAccel(const MetalAccel&) = delete;
    MetalAccel& operator=(const MetalAccel&) = delete;

    // Waits until the GPU has finished every command buffer committed so far (an empty one queued behind them, on the
    // queue the first build used; nothing to wait for when it never built). SokolDevice calls it before the structures
    // are released: sokol's command buffers retain nothing, so freeing a structure a frame still traces would free it
    // under the GPU. The caller commits the open frame's buffer first (an enqueued, uncommitted buffer is ahead of the
    // empty one in the queue and would hold it back). Does not call sokol.
    void wait_idle();

    // The limits the device answers (Limits::maxAccel*).
    Limits limits() const;

    // What the checks need to know of a buffer the device made (SokolDevice::make_buffer / destroy_buffer call these: the
    // usage flags and the size are not kept by sokol_gfx).
    void note_buffer(Buffer buffer, const BufferUsage& usage, std::size_t size, const char* label);
    void forget_buffer(Buffer buffer);

    Result<AccelSizes> blas_sizes(std::span<const AccelTriangles> geometries, const AccelBuildFlags& flags);
    Result<AccelSizes> tlas_sizes(std::uint32_t instanceCount, const AccelBuildFlags& flags);
    Result<AccelStructure> make_accel_structure(const AccelStructureDesc& desc);
    void destroy_accel_structure(AccelStructure structure);
    ResourceState accel_structure_state(AccelStructure structure) const;

    // The calls of CommandList, outside a pass (SokolCommandList checks that).
    Result<void> build_blas(const BlasBuild& build);
    Result<void> build_tlas(const TlasBuild& build);
    Result<void> query_compacted_size(AccelStructure blas, Buffer dst, std::size_t dstOffset);
    Result<void> copy_accel_structure(AccelStructure src, AccelStructure dst, AccelCopyMode mode);

    // Whether the structures `bindings` binds in the slots `slots` declares are live, built TLASes ("" when they are; else
    // the error text, naming the slot).
    std::string check_compute_bindings(const Bindings& bindings, const MetalAccelSlots& slots,
                                       const char* shaderLabel) const;
    // Binds them on sokol's open compute encoder (after sg_apply_bindings): the TLAS at its buffer index and the residency
    // of the TLAS and of every BLAS it names. Needs check_compute_bindings() to have returned "".
    void bind_compute(const Bindings& bindings, const MetalAccelSlots& slots);

private:
    MetalAccel();
    struct Impl;
    std::unique_ptr<Impl> impl_;
};

}  // namespace fa::gpu
