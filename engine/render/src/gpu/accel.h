// Private to fa_render: the ray tracing vocabulary of the GPU interface (M79 P0a;
// docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md). The calls that use it are in gpu/device.h (Device::blas_sizes,
// tlas_sizes, make_accel_structure, destroy_accel_structure, accel_structure_state; CommandList::build_blas,
// build_tlas, query_compacted_size, copy_accel_structure).
//
// The model (decision D1: inline ray query only):
//  * A BLAS holds the triangles of one mesh; a TLAS holds instances of BLASes, each with a transform. A compute shader
//    binds a TLAS (Bindings::accelStructures) and traces rays against it with an inline ray query. There are no
//    ray tracing pipelines, no shader binding tables and no hit shaders: shading happens in the compute shader that
//    traced the ray, so the same kernel runs on D3D12 (DXR 1.1 RayQuery), Vulkan (VK_KHR_ray_query) and Metal
//    (intersector<>).
//  * Sizes first: the sizes of an acceleration structure and of its scratch memory come from the device
//    (blas_sizes / tlas_sizes) before anything is made, so the caller makes the scratch buffer and the AS once and
//    reuses them every frame.
//  * Barriers are derived by the backend, like everywhere in gpu/ (docs/design/ARCHITECTURE_RENDERING_GPU.md,
//    "Barriers live inside the backends"); a caller never records one. What a backend must insert is listed at build_blas() in gpu/device.h.
//  * Every call is optional: a device whose Features::accelerationStructure is false refuses them all with a reason
//    (the package that brings the backend's support, or what the GPU lacks), and does nothing else.
#pragma once

#include <cstddef>
#include <cstdint>
#include <span>
#include <string>

#include "fa/core/types.h"
#include "gpu/types.h"

namespace fa::gpu {

// BLAS = the triangles of one mesh (built from vertex and index buffers); TLAS = instances of BLASes.
enum class AccelKind : std::uint8_t { Blas, Tlas };

const char* accel_kind_name(AccelKind kind);

// How an acceleration structure is built and what it may be used for later. The size queries and the build must get
// the same flags (a backend sizes memory for the flags it is told).
struct AccelBuildFlags {
    bool allowUpdate = false;      // build_blas / build_tlas may refit it later (`update` true): vertices move, the
                                   // topology and the counts stay; costs memory and trace speed
    bool preferFastTrace = true;   // spend build time on a tree that traces faster (static meshes)
    bool preferFastBuild = false;  // spend trace speed on a faster build (meshes rebuilt every frame); wins over
                                   // preferFastTrace when both are set
    bool allowCompaction = false;  // BLAS only: query_compacted_size / copy_accel_structure(Compact) may shrink it
};

// One triangle geometry of a BLAS: positions from a vertex buffer, optionally indexed.
struct AccelTriangles {
    Buffer vertexBuffer{};           // usage accelBuildInput
    std::size_t vertexOffset = 0;    // bytes from the start of the buffer to the first vertex's position
    std::uint32_t vertexStride = 0;  // bytes between two vertices (>= the size of the position)
    std::uint32_t vertexCount = 0;   // vertices from vertexOffset (the highest index + 1 when indexed)
    VertexFormat vertexFormat = VertexFormat::Float3;  // Float3 (and Float2, Short4N where the API has them)
    Buffer indexBuffer{};         // invalid = a triangle list over the vertices in order; else usage accelBuildInput
    std::size_t indexOffset = 0;  // bytes from the start of the index buffer
    IndexType indexType = IndexType::None;  // Uint16 or Uint32 with an index buffer; None without one
    std::uint32_t indexCount = 0;           // indices read (a multiple of 3); unused without an index buffer
    // True = no any-hit work: the first hit a ray query finds is committed by the hardware. False = every candidate
    // is reported to the shader, which commits it (alpha-tested leaves).
    bool opaque = true;

    // Triangles this geometry has (indexCount / 3, or vertexCount / 3 without an index buffer).
    std::uint64_t primitive_count() const { return std::uint64_t(indexBuffer.valid() ? indexCount : vertexCount) / 3; }
};

// The memory an acceleration structure and its builds need (Device::blas_sizes, tlas_sizes), in bytes. The sizes are
// the backend's own: a backend rounds each one up to what its API demands, so use them as they are.
struct AccelSizes {
    std::uint64_t structure = 0;      // the acceleration structure itself (AccelStructureDesc::size)
    std::uint64_t buildScratch = 0;   // scratch memory of a full build (a buffer with usage accelScratch)
    std::uint64_t updateScratch = 0;  // scratch memory of a refit (0 when the flags do not allowUpdate)
};

// Device::make_accel_structure: the object a build writes into. `size` comes from AccelSizes::structure of the sizes
// query for the geometry (or instance count) and flags it will be built with (or from the compacted size for the
// target of a compaction).
struct AccelStructureDesc {
    AccelKind kind = AccelKind::Blas;
    std::uint64_t size = 0;  // bytes, from AccelSizes::structure (never guessed)
    // Where it lives. Invalid = the device allocates the memory. A buffer with usage accelStorage lets the caller
    // sub-allocate (offset aligned to Device::accel_alignment()) and alias.
    Buffer storage{};
    std::size_t storageOffset = 0;
    const char* label = "";  // debug label: borrowed for the call
};

// One instance of a TLAS: a BLAS placed in the world.
struct AccelInstance {
    // Row-major 3x4 object-to-world transform (three rows of x, y, z, translation), as DXR and Vulkan lay it out.
    float transform[12] = {1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0};
    std::uint32_t customIndex = 0;  // 24 bits: what the shader reads back as the hit's instance custom index
    std::uint8_t mask = 0xFF;       // a ray hits the instance when (ray mask & instance mask) != 0
    bool opaque = false;            // treat every geometry of the BLAS as opaque, whatever its own flag
    bool cullDisable = false;       // do not cull back faces for this instance
    AccelStructure blas{};          // the BLAS: built, and alive until the TLAS build has run
};

// CommandList::build_blas: builds (or, with `update`, refits) a BLAS from triangle geometries.
struct BlasBuild {
    AccelStructure dst{};  // a Blas made with a size from blas_sizes of these geometries
    std::span<const AccelTriangles>
        geometries;                 // borrowed for the call; at least one, at most Limits::maxAccelGeometries
    AccelBuildFlags flags{};        // the flags of the size query
    bool update = false;            // refit `dst` from `src` (needs src built with allowUpdate)
    AccelStructure src{};           // update: the structure to refit; invalid or == dst = refit in place
    Buffer scratch{};               // usage accelScratch
    std::size_t scratchOffset = 0;  // aligned to Device::accel_scratch_alignment()
};

// CommandList::build_tlas: builds (or refits) a TLAS from instances. The instances are read during the call (the
// backend copies them into memory of its own), never kept.
struct TlasBuild {
    AccelStructure dst{};                      // a Tlas made with a size from tlas_sizes of this many instances
    std::span<const AccelInstance> instances;  // borrowed; at most Limits::maxAccelInstances
    AccelBuildFlags flags{};
    bool update = false;   // refit: same instance count, only transforms and masks may change
    AccelStructure src{};  // update: invalid or == dst = refit in place
    Buffer scratch{};
    std::size_t scratchOffset = 0;
};

// CommandList::copy_accel_structure: Compact = a BLAS built with allowCompaction into a smaller one of the size
// query_compacted_size answered; Clone = a copy of the same size.
enum class AccelCopyMode : std::uint8_t { Clone, Compact };

// Why `backend` does not trace rays (yet), as one sentence for an error or a supports() reason: GL, GLES3, WebGL2 and
// D3D11 cannot ("use the d3d12 or vulkan backend, or Metal on Apple"); D3D12 and Metal could, and name the package
// that brings it (P1d, P1m); Vulkan names the extensions and features a GPU needs; the RecordingDevice names what it
// was made with. A backend that does trace
// but whose GPU lacks the feature is a different reason (render_features.cpp says it).
std::string accel_unavailable_reason(Backend backend);
// The error a call without ray tracing answers: "gpu: <call>: <accel_unavailable_reason>" and a hint that names
// renderer.supports("raytracing").
Error accel_refusal(Backend backend, const char* call);

}  // namespace fa::gpu
