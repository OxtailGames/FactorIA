// Full-screen triangle that copies the game target into the swapchain.
@module blit

@include color_space.glsl

@vs vs
layout(binding=0) uniform blit_vs_params {
    vec4 flip;      // x = 1 when the source render target has its origin at the bottom (OpenGL)
};
layout(location=0) in vec2 pos;
out vec2 uv;
void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    float v_top_down = 0.5 - pos.y * 0.5;
    float v_bottom_up = 0.5 + pos.y * 0.5;
    uv = vec2(pos.x * 0.5 + 0.5, mix(v_top_down, v_bottom_up, flip.x));
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform blit_fs_params {
    vec4 encode;    // x = 1: the source holds linear light and the copy is encoded to sRGB (SceneSettings.colorSpace "linear");
                    // y = 1: the source's colour is premultiplied by its alpha (the encode is done on the straight colour)
};
in vec2 uv;
out vec4 frag_color;
@include_block color_space
void main() {
    vec4 c = texture(sampler2D(tex, smp), uv);
    // M71-B1: the minimal encode of the scene for the display. The final pass with the tonemap replaces it (M71-B4).
    vec3 rgb = c.rgb;
    if (encode.x > 0.5) rgb = fa_linear_to_srgb(rgb);
    // Within white: what an 8-bit swapchain does by itself, and what keeps an HDR swapchain (EDR, docs/RENDERING.md, "HDR
    // output") showing the same picture until the HDR encode of M71 decides what goes above white.
    frag_color = vec4(clamp(rgb, 0.0, 1.0), 1.0);
}
@end

// The same copy with the source's alpha: the readback of a float game target into RGBA8 (alpha matters for a CameraView).
@fs fs_keep
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform blit_fs_params {
    vec4 encode;    // as in fs
};
in vec2 uv;
out vec4 frag_color;
@include_block color_space
void main() {
    vec4 c = texture(sampler2D(tex, smp), uv);
    if (encode.x > 0.5) {
        // Premultiplied (a world capture drawn on a transparent background): encode the straight colour, then multiply back.
        float a = encode.y > 0.5 ? max(c.a, 1e-5) : 1.0;
        c.rgb = fa_linear_to_srgb(c.rgb / a) * a;
    }
    frag_color = c;
}
@end

@program blit vs fs
@program blit_keep vs fs_keep
