// shdc-slang: glsl430:glsl300es:metal_macos:metal_ios:metal_sim:hlsl5:wgsl:spirv_vk
// FactorIA temporal-upscaler input preparation (M76-P5b, M78): one fragment pass at the render resolution that turns what the depth prepass wrote
// into what the MetalFX temporal scaler and the vendor SDKs (XeSS, DLSS, FSR) read. The vendor SDKs run on Metal, D3D11 and D3D12 (hlsl5) and
// Vulkan, whose texture space is top-down, so the uv below needs no flip. The GL and WebGPU dialects are compiled too so that the pass (and the
// provider hand-off tests with a fake provider) runs on every backend; no SDK reads its result on OpenGL, where the uv is not flipped.
//
//   in   tex_p  the prepass: r = the linear view depth in world units (a = 1 where a mesh was drawn, else 0)
//        tex_v  the velocity: rg = uvPrev - uvCurr (unjittered, y down), 1024 where no object wrote one (VelocityRef::kNone)
//   out  location 0 (R32F)  the depth in 0..1 (d / (d + 1): increasing with the distance, 1 for the sky and every pixel no mesh wrote)
//        location 1 (RG16F) the motion in UV units of the picture (y down), pointing from the pixel to where its surface was on the frame
//                           before: the velocity when an object wrote one, else the camera's own movement reprojected from the depth with the
//                           matrix `m`, as the temporal resolve does (taa_shared.glsl); the sentinel never reaches MetalFX. The caller sets
//                           MetalFX's motion scale to the render size (the unit of the image is the picture's width and height).
//
// Why not hand MetalFX the prepass as it is: its depth is in world units up to 60000 (the scalers read a 0..1 depth), and where no object wrote a
// velocity the image holds 1024, which a scaler would take for a motion of a thousand pictures.
@module upscale_mfx

@vs vs
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    uv = vec2(pos.x * 0.5 + 0.5, 0.5 - pos.y * 0.5);   // Metal: top-down
}
@end

@fs fs
layout(binding=0) uniform texture2D tex_p;
layout(binding=1) uniform texture2D tex_v;
layout(binding=0) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@image_sample_type tex_v unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=0) uniform mfx_params {
    vec4 s;     // xy = the picture's size in pixels, z = 1 when the velocity is bound, w = the sign of the motion (1, or -1 for a test)
    vec4 j;     // xy = the jitter of this frame in picture pixels, z = 1 when the camera reprojection is valid (no cut), w = 1 when the prepass is bound (else every pixel is sky)
    vec4 pa;    // the projection of the camera: P00, P11, P02, P12
    vec4 pb;    // P03, P13, P32, P33
    mat4 m;     // previous (unjittered) view-projection * inverse view: a view-space position of this frame -> the clip position it had on the frame before
};
in vec2 uv;
layout(location=0) out vec4 out_depth;
layout(location=1) out vec4 out_motion;

const float FAR = 60000.0;

void main() {
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    bool drawn = j.w > 0.5 && pre.a > 0.5;
    float depth = drawn ? pre.r : FAR;
    out_depth = vec4(drawn ? depth / (depth + 1.0) : 1.0, 0.0, 0.0, 1.0);

    vec2 mv = vec2(0.0);
    bool known = false;
    if (s.z > 0.5) {
        vec2 v = textureLod(sampler2D(tex_v, smp_pt), uv, 0.0).rg;
        // The test of VelocityRef::is_none: a NaN or a value from 512 up is "no object wrote here".
        known = abs(v.x) < 512.0 && abs(v.y) < 512.0;
        if (known) mv = v;
    }
    if (!known && j.z > 0.5) {
        vec2 sU = uv - j.xy / s.xy;                      // the unjittered position of this pixel's surface
        vec2 ndc = vec2(sU.x * 2.0 - 1.0, 1.0 - sU.y * 2.0);
        float z = -depth;
        float w = pb.z * z + pb.w;                       // clip w: -z for a perspective camera, 1 for an orthographic one
        vec3 vp = vec3((ndc.x * w - pa.z * z - pb.x) / pa.x, (ndc.y * w - pa.w * z - pb.y) / pa.y, z);
        vec4 pc = m * vec4(vp, 1.0);
        if (pc.w > 1e-4) mv = ((pc.xy / pc.w) - ndc) * vec2(0.5, -0.5);
    }
    out_motion = vec4(mv * s.w, 0.0, 0.0);
}
@end

@program mfx vs fs
