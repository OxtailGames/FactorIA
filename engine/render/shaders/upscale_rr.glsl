// shdc-slang: glsl430:glsl300es:metal_macos:metal_ios:metal_sim:hlsl5:wgsl:spirv_vk
// FactorIA guides of DLSS Ray Reconstruction (M78-P4c): one fragment pass at the render resolution that makes, from what the depth prepass
// wrote, the images the denoiser-upscaler reads next to the colour, the depth and the motion. The renderer is a forward renderer with no
// material G-buffer, so two of the guides are approximations (docs/UPSCALING_VENDORS.md, "DLSS Ray Reconstruction"):
//
//   in   tex_p  the prepass: r = the linear view depth in world units, gb = the octahedral view-space normal, a = 1 where a mesh was drawn
//   out  location 0 (RGBA16F)  xyz = the WORLD-space unit normal (the view-space normal turned by the camera's own axes: right, up and
//                              back = -forward), w = the roughness (a constant: the renderer has no per-pixel roughness).
//                              Where no mesh was drawn (the sky): the normal faces the camera.
//        location 1 (R32F)     the HARDWARE depth the camera's projection makes of the view distance: clip z / clip w of the unjittered
//                              projection (0..1 growing with the distance on the backends the vendor SDKs run on; 1 where no mesh was
//                              drawn). Ray Reconstruction rebuilds the view position from this depth and the projection it is told, so
//                              the two must agree; the prepass's d / (d + 1) that Super Resolution reads does not.
//   The diffuse and specular albedo are constants (the renderer has no per-pixel albedo): the caller clears their images.
//
// Like upscale_mfx.glsl the vendor SDKs run on Metal, D3D11/D3D12 and Vulkan, whose texture space is top-down, so the uv needs no flip.
@module upscale_rr

@vs vs
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    uv = vec2(pos.x * 0.5 + 0.5, 0.5 - pos.y * 0.5);
}
@end

@fs fs
layout(binding=0) uniform texture2D tex_p;
layout(binding=0) uniform sampler smp_pt;
@image_sample_type tex_p unfilterable_float
@sampler_type smp_pt nonfiltering
layout(binding=0) uniform rr_params {
    vec4 right;   // xyz = the camera's right axis in the world, w = the roughness of every pixel
    vec4 up;      // xyz = the camera's up axis in the world
    vec4 back;    // xyz = the axis the camera looks away from (-forward), w = 1 when the prepass is bound (else every pixel is sky)
    vec4 zrow;    // the projection's depth terms: P22, P23, P32, P33 (clip z = P22 * z + P23, clip w = P32 * z + P33, z the view-space z)
};
in vec2 uv;
layout(location=0) out vec4 out_normal_roughness;
layout(location=1) out vec4 out_depth;

// The view-space normal of the prepass (octahedral, see prepass_view.glsl).
vec3 oct_decode(vec2 e) {
    vec3 n = vec3(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) n.xy = (1.0 - abs(n.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    return normalize(n);
}

void main() {
    vec4 pre = textureLod(sampler2D(tex_p, smp_pt), uv, 0.0);
    bool drawn = back.w > 0.5 && pre.a > 0.5;
    vec3 n = drawn ? oct_decode(pre.gb) : vec3(0.0, 0.0, 1.0);
    vec3 world = normalize(right.xyz * n.x + up.xyz * n.y + back.xyz * n.z);
    out_normal_roughness = vec4(world, right.w);
    float z = -pre.r;  // the view-space z of the surface: the prepass stores the distance along the view axis
    float clipW = zrow.z * z + zrow.w;
    float hw = drawn && abs(clipW) > 1e-12 ? (zrow.x * z + zrow.y) / clipW : 1.0;
    out_depth = vec4(hw, 0.0, 0.0, 1.0);
}
@end

@program rr vs fs
