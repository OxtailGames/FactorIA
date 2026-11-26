// The per-instance record of the ray tracing scene (M79 P1s). The twin of engine/render/src/rt_records.h: the renderer writes one record
// for every instance of the TLAS into a StructuredBuffer<RtInstanceRecord>. The customIndex of a TLAS instance is its position in that
// buffer: a kernel that hit instance `i` with an inline ray query reads records[q.CommittedInstanceID()] (the HLSL RayQuery call that
// returns the 24-bit InstanceID the TLAS was built with). Keep the two files in step: a test compares the field names and the size
// (96 bytes, std430: every member is a 4-byte scalar or a float4 on a 16-byte boundary).
//
// Metal kernels declare the same struct in their own source (the .metal files are written by hand).
#ifndef FA_RT_RECORDS_HLSLI
#define FA_RT_RECORDS_HLSLI

// RtInstanceRecord::flags
static const uint kRtFlagOpaque = 1u << 0;
static const uint kRtFlagCutout = 1u << 1;
static const uint kRtFlagTwoSided = 1u << 2;
static const uint kRtFlagBlended = 1u << 3;
static const uint kRtFlagUnlit = 1u << 4;
static const uint kRtFlagFoliage = 1u << 5;
static const uint kRtFlagCastsShadow = 1u << 6;
static const uint kRtFlagCustomMaterial = 1u << 7;
static const uint kRtFlagSkinned = 1u << 8;

// The instance mask bits of the TLAS (the ray's InstanceInclusionMask).
static const uint kRtMaskOpaque = 0x01;
static const uint kRtMaskCutout = 0x02;
static const uint kRtMaskBlended = 0x04;
static const uint kRtMaskCastsShadow = 0x08;
static const uint kRtMaskFoliage = 0x10;
static const uint kRtMaskEmissive = 0x20;
static const uint kRtMaskSurfaces = 0x07;

struct RtInstanceRecord {
    float4 objectToWorldRow0;  // object-to-world, row-major 3x4: x axis, y axis, z axis, translation of each row
    float4 objectToWorldRow1;
    float4 objectToWorldRow2;
    float4 albedo;    // rgb: base colour (scene colour space), a: opacity
    float4 emissive;  // rgb: emission, w: 0 (reserved)
    float roughness;
    float metalness;
    uint flags;  // kRtFlag*
    uint blasId;
};  // 96 bytes

#endif
