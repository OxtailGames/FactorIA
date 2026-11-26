// The per-instance record of the ray tracing scene (M79 P1s; docs/design/ARCHITECTURE_RT_SCENE.md, "The record buffer"). The renderer
// writes one RtInstanceRecord for every instance of the TLAS into a storage buffer; a ray query kernel that hits instance `i` reads
// records[CommittedRayQueryInstanceCustomIndex()] (the TLAS instance's customIndex IS its position in the buffer). The HLSL kernels
// include the same layout from engine/render/shaders/rt/rt_records.hlsli, and the Metal ones declare the same struct; this header and
// that file change together (a test compares their field names and the sizes).
//
// The layout is std430-compatible: every member is a 4-byte scalar, the vectors are made of arrays of floats on this side and float4s on
// the shader side, and the 128 bytes keep every record 16-byte aligned. No field is ever packed into the padding of another.
#pragma once

#include <cstddef>
#include <cstdint>
#include <type_traits>

namespace fa::render {

// RtInstanceRecord::flags: what the surface of the instance is (one bit each).
inline constexpr std::uint32_t kRtFlagOpaque =
    1u << 0;  // the instance is forced opaque: a ray query commits the first hit, no alpha test
inline constexpr std::uint32_t kRtFlagCutout =
    1u << 1;  // alpha-tested (a custom material with alphaMode "clip"): the kernel tests the alpha itself
inline constexpr std::uint32_t kRtFlagTwoSided =
    1u << 2;  // back faces are hit too (the mesh or its material is double-sided)
inline constexpr std::uint32_t kRtFlagBlended =
    1u << 3;  // drawn with the blended or transmissive meshes (glass, water, particles-as-mesh)
inline constexpr std::uint32_t kRtFlagUnlit =
    1u << 4;  // MeshRenderer.unlit or a material with lighting "unlit": it is not lit by the scene
inline constexpr std::uint32_t kRtFlagFoliage = 1u << 5;      // an instance of a Foliage
inline constexpr std::uint32_t kRtFlagCastsShadow = 1u << 6;  // MeshRenderer.castShadows
inline constexpr std::uint32_t kRtFlagCustomMaterial =
    1u << 7;  // drawn with a material: albedo, roughness and metalness are the MeshRenderer's
              // constants, not what the material's shader makes of them
inline constexpr std::uint32_t kRtFlagSkinned =
    1u << 8;  // a skinned mesh: its BLAS is the instance's own, refitted every frame
inline constexpr std::uint32_t kRtFlagRefractive =
    1u << 9;  // a transmissive surface (glass, liquid; M79-P3b): the translucency kernel bends a ray at it (volume and attenuation below)

// The instance mask bits of the TLAS (AccelInstance::mask): a ray hits an instance when (ray mask & instance mask) != 0. Every instance
// has at least one of the first three. 0x80 is reserved for the effects of later packages: a kernel never sets or tests it.
inline constexpr std::uint8_t kRtMaskOpaque = 0x01;   // an opaque lit surface
inline constexpr std::uint8_t kRtMaskCutout = 0x02;   // an alpha-tested surface (the instance is not forced opaque)
inline constexpr std::uint8_t kRtMaskBlended = 0x04;  // a blended or transmissive surface
inline constexpr std::uint8_t kRtMaskCastsShadow =
    0x08;  // the surface casts shadows (MeshRenderer.castShadows): shadow rays use this bit
inline constexpr std::uint8_t kRtMaskFoliage = 0x10;   // an instance of a Foliage
inline constexpr std::uint8_t kRtMaskEmissive = 0x20;  // the surface emits light (emissive colour * strength above 0)
inline constexpr std::uint8_t kRtMaskRefractive =
    0x40;  // a transmissive surface a ray refracts through (M79-P3b: MeshRenderer.transmission above 0, drawn with the refraction); also 0x04
inline constexpr std::uint8_t kRtMaskReserved = 0x80;
// What a ray that wants "every visible surface" (reflections, GI) uses.
inline constexpr std::uint8_t kRtMaskSurfaces = kRtMaskOpaque | kRtMaskCutout | kRtMaskBlended;

// The most customIndex a TLAS instance can hold (24 bits): also the most instances the scene can hold.
inline constexpr std::uint32_t kRtMaxInstanceIndex = 0xFFFFFFu;

// One instance of the TLAS (one submesh of one drawn mesh), 128 bytes (96 before M79-P3b, which added `volume` and `attenuation`). Everything is in the renderer's space (the floating origin's: the
// positions of the frame, not the world's).
struct RtInstanceRecord {
    // Object-to-world, row-major 3x4: three rows of (x axis, y axis, z axis, translation) -- the same numbers as the TLAS instance.
    // A normal is transformed with the inverse transpose of the upper 3x3.
    float objectToWorld[12];
    float albedo
        [4];  // rgb: the base colour of the part as the draw uses it (MeshRenderer.color * the part's factor), in the scene's colour space; a: opacity
    float emissive[4];  // rgb: MeshRenderer.emissive * emissiveStrength, plus the model's own emission; w: 0, reserved
    float roughness;    // 0 to 1, the part's glTF value or MeshRenderer.roughness
    float metalness;    // 0 to 1
    std::uint32_t flags;  // kRtFlag*
    std::uint32_t
        blasId;  // the BLAS of the instance: one id per (mesh asset, submesh), the same for every instance of it, never reused
    // The transmission of the part as the draw uses it (the glTF material's values, replaced field by field by the MeshRenderer's; zeros and
    // ior 1.5 on a surface that is not kRtFlagRefractive).
    float volume[4];       // x: index of refraction (1 to 3), y: thickness in metres (0 = a thin sheet the ray passes straight through), z:
                           // attenuation distance in metres (0 = no tint), w: transmission (0 to 1)
    float attenuation[4];  // rgb: the colour the light has after the attenuation distance, in the scene's colour space; w: 0, reserved
};

static_assert(sizeof(RtInstanceRecord) == 128, "RtInstanceRecord is 128 bytes: rt_records.hlsli has the same layout");
static_assert(alignof(RtInstanceRecord) == 4);
static_assert(offsetof(RtInstanceRecord, objectToWorld) == 0);
static_assert(offsetof(RtInstanceRecord, albedo) == 48);
static_assert(offsetof(RtInstanceRecord, emissive) == 64);
static_assert(offsetof(RtInstanceRecord, roughness) == 80);
static_assert(offsetof(RtInstanceRecord, metalness) == 84);
static_assert(offsetof(RtInstanceRecord, flags) == 88);
static_assert(offsetof(RtInstanceRecord, blasId) == 92);
static_assert(offsetof(RtInstanceRecord, volume) == 96);
static_assert(offsetof(RtInstanceRecord, attenuation) == 112);
static_assert(std::is_standard_layout_v<RtInstanceRecord> && std::is_trivially_copyable_v<RtInstanceRecord>);

}  // namespace fa::render
