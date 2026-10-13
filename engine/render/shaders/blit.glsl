// Full-screen triangle that copies the game target into the swapchain.
@module blit

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
in vec2 uv;
out vec4 frag_color;
void main() {
    vec4 c = texture(sampler2D(tex, smp), uv);
    frag_color = vec4(c.rgb, 1.0);
}
@end

@program blit vs fs
