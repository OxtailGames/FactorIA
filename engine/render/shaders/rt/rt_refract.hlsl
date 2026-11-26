// Ray traced translucency (M79-P3b, docs/RAY_TRACING.md "Translucency"): the refraction through glass and liquids (MeshRenderer.transmission,
// KHR_materials_transmission) that the screen-space refraction of the transmissive meshes (renderer_xmit.h) cannot get right: what is behind the
// glass but off the screen, hidden by something in front of it, or seen through a second glass. The fourth effect on the shared ray traced effect
// pass (engine/render/src/rt_effect.h); it reads no G-buffer.
//
// HLSL is the source of the D3D12 (DXIL, cs_6_5) and the Vulkan (SPIR-V) kernels, rt_refract.metal is the Metal twin: the same algorithm.
// The bindings are the contract of every effect kernel (rt_shadow.hlsl lists them) plus the three of rt_hit.hlsli:
//
//   binding 0  g_tlas     acceleration structure                          (Metal: buffer(0))     declared by rt_hit.hlsli
//   binding 1  g_out      storage image, rgba32f                          (Metal: texture(0))
//   binding 2  g_params   constant buffer, RtEffectParams                 (Metal: buffer(1))
//   binding 3  g_prepass  Texture2D, the camera's prepass                 (Metal: texture(1))   t1
//   binding 4  g_records  StructuredBuffer of RtInstanceRecord            (Metal: buffer(8))   t2   declared by rt_hit.hlsli
//   binding 7  g_hit      constant buffer, RtHitParams                    (Metal: buffer(3))   b1   declared by rt_hit.hlsli
//
// The algorithm, for each pixel: a primary ray from the camera, up to the opaque surface the prepass has there, looks for the nearest refractive
// instance (mask kRtMaskRefractive, the glass the mesh pass draws at this pixel). Where it finds none the pixel is not traced (output 0). From
// the hit the ray follows the glass:
//   * a surface with a thickness above 0 is a closed volume: the ray enters it with Snell's law (1 / ior), travels inside losing light by
//     Beer-Lambert (exp(-ln(1 / attenuationColor) * distance / attenuationDistance), the distance being the real one), and leaves it with ior / 1;
//     a ray that cannot leave (total internal reflection) is reflected and goes on inside. A volume's second surface is whatever the ray meets
//     next: overlapping volumes are not nested (the ray leaves the one it is in at the first refractive surface it meets).
//   * a surface with no thickness is a thin sheet: the ray passes straight through (the two interfaces cancel), the light is not tinted.
//   * the ray ends on the first surface that is not refractive (shaded by rt_hit.hlsli), or leaves the scene (the environment's gradient),
//     or after kMaxSegments segments (the interfaces of one ray: 2 for a ball, 4 for two balls; then the environment in its direction).
// A roughness above 0 spreads the first refracted direction inside a cone (a deterministic sample from the frame's seed, one per pixel and
// frame); the glass's own shader filters the noise in screen space with a box of its roughness.
// The ray starts after each interface at the surface plus user0.x + user0.y * (the segment's length) along its new direction, so it never hits
// the surface it starts from (a shell thinner than that offset is not refracted correctly).
//
// user0 (RtEffectParams): x = the offset after an interface in metres, y = more of it per metre of the segment's length, z = the widest cone
// (tangent of the half angle, for roughness 1 and ior 1.5), w = the primary ray's TMax over the sky and the segments' TMax.
//
// Output (Rgba32F, the size of the prepass), where a is:
//    0   nothing traced here: the glass shader uses the screen-space refraction
//    1   rgb = the radiance the glass shows (the shaded hit or the environment, times the light that survived the volume)
//   < 0  the ray ended on a surface the opaque picture shows at the texel it projects to: rgb = the light that survived, a = -(1 + u + 4096 v)
//        with u and v the texel's position in 4096ths of the image (u + 4096 v is an integer below 2^24: exact in a float). The copy of the
//        refraction atlas (shaders/xmit.glsl) reads the picture there, so the refracted image keeps the textures, the lights and the fog of the
//        picture, and only what the screen cannot show is shaded here.
#include "rt_hit.hlsli"

[[vk::binding(1, 0)]] [[vk::image_format("rgba32f")]] RWTexture2D<float4> g_out : register(u0);

// BEGIN RtEffectParams
struct RtEffectParams {
    float4 camera;    // xyz: the camera's position (the renderer's space); w: 1 for an orthographic camera
    float4 lightDir;  // xyz: the unit vector from a surface toward the light; w: 0
    float4 image;     // xy: the size of the image in pixels; zw: 1 / size
    uint4 frame;      // x: the frame serial; y: the seed of the frame; z: rays per pixel; w: 0
    // The camera the prepass was drawn with (jittered). The world position of pixel (x, y), with ndc = (2 (x + 0.5) / w - 1, 1 - 2 (y + 0.5) / h)
    // and d the linear view depth: rayO0 + ndc.x rayOX + ndc.y rayOY + (rayD0 + ndc.x rayDX + ndc.y rayDY) d.
    float4 rayO0, rayOX, rayOY, rayD0, rayDX, rayDY;
    // The same for the unjittered camera (what history and reprojection use).
    float4 uRayO0, uRayOX, uRayOY, uRayD0, uRayDX, uRayDY;
    float4 viewRight, viewUp, viewBack;  // xyz: the camera's axes in the renderer's space; a view-space normal (x, y, z) is right x + up y + back z
    float4 viewProj0, viewProj1, viewProj2, viewProj3;  // the rows of the unjittered view-projection matrix
    float4 user0, user1;                                // the effect's own numbers
};
// END RtEffectParams
[[vk::binding(2, 0)]] ConstantBuffer<RtEffectParams> g_params : register(b0);
[[vk::binding(3, 0)]] Texture2D<float4> g_prepass : register(t1);

static const uint kMaxSegments = 6u;
static const float kInv24 = 1.0 / 16777216.0;
static const float kTwoPi = 6.28318530717958647692;

// PCG (O'Neill): integer only, so the sequence of draws is the same on every GPU and on the CPU.
uint pcg(uint v) {
    const uint s = v * 747796405u + 2891336453u;
    const uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
    return (w >> 22u) ^ w;
}

// A number in [0, 1) from the top 24 bits of a hash: exact in a float.
float unit(uint h) { return float(h >> 8u) * kInv24; }

[numthreads(8, 8, 1)]
void main(uint3 id : SV_DispatchThreadID) {
    if (id.x >= (uint)g_params.image.x || id.y >= (uint)g_params.image.y) return;
    const float4 pre = g_prepass.Load(int3(id.xy, 0));
    const float2 ndc = float2((float(id.x) + 0.5) * g_params.image.z * 2.0 - 1.0, 1.0 - (float(id.y) + 0.5) * g_params.image.w * 2.0);
    const float3 origin0 = g_params.rayO0.xyz + ndc.x * g_params.rayOX.xyz + ndc.y * g_params.rayOY.xyz;
    const float3 dirPerDepth = g_params.rayD0.xyz + ndc.x * g_params.rayDX.xyz + ndc.y * g_params.rayDY.xyz;
    const float dirLength = max(length(dirPerDepth), 1.0e-6);
    float3 dir = dirPerDepth / dirLength;
    // The glass is in front of the opaque surface of the prepass (the draw's depth test): the primary ray stops there.
    const float tmax = pre.a > 0.5 ? pre.r * dirLength : g_params.user0.w;
    RtSurface cur;
    if (!rt_trace_surface_mask(origin0, dir, 0.0, tmax, kRtMaskRefractive, cur)) {
        g_out[id.xy] = float4(0.0, 0.0, 0.0, 0.0);
        return;
    }
    uint state = pcg(id.x + pcg(id.y + pcg(g_params.frame.y)));
    float3 throughput = float3(1.0, 1.0, 1.0);
    float3 coefInside = float3(0.0, 0.0, 0.0);  // the extinction of the volume the ray is in, per metre
    bool inside = false;
    bool spread = false;
    float3 radiance = float3(0.0, 0.0, 0.0);
    bool ended = false;
    bool onSurface = false;
    float3 endPosition = float3(0.0, 0.0, 0.0);
    for (uint seg = 0; seg < kMaxSegments && !ended; ++seg) {
        if (inside) throughput *= exp(-coefInside * cur.t);
        const RtInstanceRecord r = g_records[cur.record];
        if ((r.flags & kRtFlagRefractive) == 0) {  // a surface that is shaded: the ray ends
            radiance = rt_shade_hit(cur, -dir);
            endPosition = cur.position;
            onSurface = true;
            ended = true;
        } else {
            const float ior = clamp(r.volume.x, 1.0, 3.0);
            float3 next = dir;
            if (r.volume.y > 0.0) {  // a closed volume: Snell's law
                if (!inside) {
                    const float3 rd = refract(dir, cur.normal, 1.0 / ior);
                    if (dot(rd, rd) > 0.5) next = normalize(rd);
                    inside = true;
                    const float3 att = clamp(r.attenuation.rgb, float3(0.0001, 0.0001, 0.0001), float3(1.0, 1.0, 1.0));
                    coefInside = r.volume.z > 0.0 ? -log(att) / r.volume.z : float3(0.0, 0.0, 0.0);
                } else {
                    const float3 rd = refract(dir, cur.normal, ior);
                    if (dot(rd, rd) > 0.5) {
                        next = normalize(rd);
                        inside = false;
                    } else {  // total internal reflection: the ray stays inside
                        next = reflect(dir, cur.normal);
                    }
                }
            }
            if (!spread) {  // the cone of a rough surface: once, at the first interface
                spread = true;
                const float rough = saturate(r.roughness);
                if (rough > 0.0) {
                    const float3 up = abs(next.y) < 0.9 ? float3(0.0, 1.0, 0.0) : float3(1.0, 0.0, 0.0);
                    const float3 t1 = normalize(cross(up, next));
                    const float3 t2 = cross(next, t1);
                    state = pcg(state);
                    const float u1 = unit(state);
                    state = pcg(state);
                    const float u2 = unit(state);
                    const float tanSpread = rough * g_params.user0.z * saturate(2.0 * ior - 2.0);
                    const float rr = sqrt(u1) * tanSpread;
                    const float phi = kTwoPi * u2;
                    next = normalize(next + (t1 * cos(phi) + t2 * sin(phi)) * rr);
                }
            }
            const float3 start = cur.position + next * (g_params.user0.x + g_params.user0.y * cur.t);
            dir = next;
            if (!rt_trace_surface_mask(start, dir, 0.0, g_params.user0.w, kRtMaskSurfaces, cur)) {
                radiance = rt_miss_color(dir);
                ended = true;
            }
        }
    }
    if (!ended) radiance = rt_miss_color(dir);  // the budget of segments is spent
    // Is the end of the ray a surface the opaque picture shows? Then the atlas copy reads the picture there.
    if (onSurface) {
        const float4 p4 = float4(endPosition, 1.0);
        const float w = dot(g_params.viewProj3, p4);
        if (w > 1.0e-4) {
            const float2 q = float2(dot(g_params.viewProj0, p4), dot(g_params.viewProj1, p4)) / w;
            const float2 uv = float2(q.x * 0.5 + 0.5, 0.5 - q.y * 0.5);
            if (uv.x >= 0.0 && uv.x < 1.0 && uv.y >= 0.0 && uv.y < 1.0) {
                const int2 texel = int2(uv * g_params.image.xy);
                const float4 there = g_prepass.Load(int3(texel, 0));
                const float depth = dot(endPosition - g_params.rayO0.xyz, -g_params.viewBack.xyz);
                if (there.a > 0.5 && abs(there.r - depth) <= 0.02 * depth + 0.05) {
                    const float u = min(floor(uv.x * 4096.0), 4095.0);
                    const float v = min(floor(uv.y * 4096.0), 4095.0);
                    g_out[id.xy] = float4(throughput, -(1.0 + u + 4096.0 * v));
                    return;
                }
            }
        }
    }
    g_out[id.xy] = float4(radiance * throughput, 1.0);
}
