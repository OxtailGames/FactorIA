// Full-screen triangle that copies the game target into the swapchain, encoded for the window's output (hdr_encode.h has the same
// maths on the CPU and the table of the encodes; docs/RENDERING.md, "HDR output").
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
    vec4 encode;    // x = 1: the source holds linear light (SceneSettings.colorSpace "linear", no final pass): an sdr output encodes it
                    // to sRGB, an HDR output uses it as it is; 0: it holds sRGB-encoded display values (the final pass's picture,
                    // extended above 1 when it drew for an HDR output), which an HDR output decodes to linear light first;
                    // y = 1: the source's colour is premultiplied by its alpha (the encode is done on the straight colour)
    vec4 hdr;       // the output (fs only): x = 0 sdr, 1 scRGB, 2 HDR10 (PQ), 3 EDR extended linear sRGB; y = the brightest light
                    // written, in paper whites (the headroom when the final pass drew above white, else 1); z = paper white / 80
                    // nits (scRGB); w = paper white / 10000 nits (PQ)
};
in vec2 uv;
out vec4 frag_color;
@include_block color_space
// SMPTE ST 2084 (PQ), luminance over 10000 nits (0..1) -> the signal.
vec3 pq_encode(vec3 y) {
    const float m1 = 0.1593017578125;
    const float m2 = 78.84375;
    const float c1 = 0.8359375;
    const float c2 = 18.8515625;
    const float c3 = 18.6875;
    vec3 p = pow(clamp(y, 0.0, 1.0), vec3(m1));
    return pow((c1 + c2 * p) / (1.0 + c3 * p), vec3(m2));
}
void main() {
    vec4 c = texture(sampler2D(tex, smp), uv);
    vec3 rgb = c.rgb;
    if (hdr.x < 0.5) {
        // sdr: sRGB-encoded within white, what an 8-bit swapchain does by itself
        if (encode.x > 0.5) rgb = fa_linear_to_srgb(rgb);
        frag_color = vec4(clamp(rgb, 0.0, 1.0), 1.0);
    } else {
        // An HDR output: linear light, 1.0 = paper white, up to what the final pass may write (the HUD is within 1)
        vec3 l = encode.x > 0.5 ? rgb : fa_srgb_to_linear(rgb);
        l = clamp(l, 0.0, hdr.y);
        if (hdr.x < 1.5) {
            l *= hdr.z;  // scRGB: 1.0 = 80 nits
        } else if (hdr.x < 2.5) {
            // HDR10: Rec.709 -> Rec.2020 (BT.2087; GLSL matrices are column-major: each vec3 is a COLUMN), nits, PQ
            const mat3 to2020 = mat3(vec3(0.627403896, 0.069097289, 0.016391439), vec3(0.329283039, 0.919540395, 0.088013308),
                                     vec3(0.043313066, 0.011362316, 0.895595253));
            l = pq_encode((to2020 * l) * hdr.w);
        }
        // EDR (3): extended linear sRGB as it is, 1.0 = the screen's white
        frag_color = vec4(l, 1.0);
    }
}
@end

// The same copy with the source's alpha: the readback of a float game target into RGBA8 (alpha matters for a CameraView).
@fs fs_keep
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform blit_fs_params {
    vec4 encode;    // as in fs (the readback of a final pass picture, x = 0, copies its display values as they are)
    vec4 hdr;       // as in fs (not read here: the copy keeps the source's range)
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
