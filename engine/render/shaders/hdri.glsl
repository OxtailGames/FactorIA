// FactorIA HDRI sky (SceneSettings.environmentMap, M73-P3a-2): an equirectangular picture drawn as the background, and the same program
// drawn into the faces of a cube as the first step of the environment bake (renderer_env.h: the prefilter and the SH pass read
// that cube, so the picture lights and reflects in the meshes with no second bake). One full-screen triangle, the vertex stage of the
// engine's own sky (sky_common.glsl): a ray from the camera through the pixel.
//
// The picture is looked up by direction (fa::hdri_uv in include/fa/render/hdri.h is the same arithmetic on the CPU): the direction is
// turned by -rotation around the up axis, then u = atan(x, -z) / 2pi + 0.5 and v = 0.5 - asin(y) / pi, so looking along -Z shows the
// middle of the picture and +X is on its right. Row 0 of the image is v = 0 on every backend (sokol's texture origin is the same on all).
// The mip level is chosen here from the angle one pixel covers (never from the screen derivatives of the lookup, which jump at the seam
// where atan wraps), so the picture is filtered as a whole without sparkle, and the lookup repeats in u (the sampler) so the seam never
// shows. In a gamma scene (SceneSettings.colorSpace) the linear radiance is encoded as sRGB, as the sky and the bake of a sky material do.
@module hdri

@include color_space.glsl

@vs vs
layout(binding=0) uniform hdri_vs_params {
    mat4 inv_view_proj;
    vec4 cam_pos;
};
layout(location=0) in vec2 pos;
out vec3 ray_dir;
void main() {
    gl_Position = vec4(pos, 1.0, 1.0);
    vec4 far_pt = inv_view_proj * vec4(pos, 1.0, 1.0);
    ray_dir = far_pt.xyz / far_pt.w - cam_pos.xyz;
}
@end

@fs fs
@include_block color_space
layout(binding=0) uniform texture2D hdri_tex;
layout(binding=0) uniform sampler hdri_smp;
layout(binding=1) uniform hdri_fs_params {
    vec4 p;     // x = rotation (radians), y = brightness, z = 1 to encode the colour as sRGB (a gamma scene), w = width of the picture in texels
};
in vec3 ray_dir;
out vec4 frag_color;

void main() {
    vec3 d = normalize(ray_dir);
    float c = cos(p.x);
    float s = sin(p.x);
    vec3 r = vec3(d.x * c - d.z * s, d.y, d.x * s + d.z * c);
    // atan(0, 0) is undefined on some mobile GPUs: at the exact poles the direction has no azimuth, and any one will do.
    float az = (abs(r.x) + abs(r.z) > 1.0e-6) ? atan(r.x, -r.z) : 0.0;
    vec2 uv = vec2(az * 0.15915494 + 0.5, 0.5 - asin(clamp(r.y, -1.0, 1.0)) * 0.31830989);
    // Texels one pixel spans: its angle (the change of the unit direction across the pixel) times the texels per radian, which is the same
    // along a meridian and along the equator; along a parallel at latitude L the picture's rows are 1 / cos(L) times as wide in texels as
    // they are long, so the footprint is divided by cos(L) (kept above 0.05: at the poles the whole top row is one point) and the mip
    // follows the longer side. Without it the poles were read from a mip that is too sharp and shimmered.
    float footprint = length(fwidth(d)) * p.w * 0.15915494 / max(sqrt(max(1.0 - r.y * r.y, 0.0)), 0.05);
    float lod = max(log2(max(footprint, 1.0e-6)), 0.0);
    vec3 col = textureLod(sampler2D(hdri_tex, hdri_smp), uv, lod).rgb;
    if (p.z > 0.5) {
        col = fa_linear_to_srgb(col);
    }
    col *= p.y;
    // The scene's target may be RGBA16F (largest value 65504): the brightest channel is limited with the colour kept, never infinity.
    float m = max(max(col.r, col.g), col.b);
    if (m > 65000.0) {
        col *= 65000.0 / m;
    }
    frag_color = vec4(col, 1.0);
}
@end

@program hdri vs fs
