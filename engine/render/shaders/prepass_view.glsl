// The debug view of the depth and normal prepass (Renderer::set_debug_view): draws what the prepass holds as a picture, over the game
// image of the frame. One full-screen triangle that reads the prepass image (mesh_common.glsl, prepass_fs: r = linear view depth in world
// units, gb = octahedral view-space normal, a = 1 where an opaque mesh was drawn) and writes
//   mode 1 (depth)    grey = 10 / (10 + depth): white next to the camera, darker the farther; black where nothing was drawn
//   mode 2 (normals)  the view-space normal as a colour, rgb = n * 0.5 + 0.5 (x right, y up, z toward the camera); black where nothing was drawn
// The values are written as they are: in a linear scene the final pass encodes them like any picture.
@module prepass_view

@vs vs
layout(binding=0) uniform prepass_view_vs_params {
    vec4 flip;      // x = 1 when render targets have their origin at the bottom (OpenGL), 0 otherwise
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
@image_sample_type tex unfilterable_float
@sampler_type smp nonfiltering
layout(binding=1) uniform prepass_view_fs_params {
    vec4 mode;      // x = 1 depth, 2 normals
};
in vec2 uv;
out vec4 frag_color;
void main() {
    vec4 t = textureLod(sampler2D(tex, smp), uv, 0.0);
    if (t.a < 0.5) {
        frag_color = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }
    if (mode.x < 1.5) {
        float g = 10.0 / (10.0 + max(t.r, 0.0));
        frag_color = vec4(g, g, g, 1.0);
        return;
    }
    // Octahedral decode: n = (e.x, e.y, 1 - |e.x| - |e.y|); where n.z < 0 the corner is folded back first.
    vec2 e = t.gb;
    vec3 n = vec3(e.x, e.y, 1.0 - abs(e.x) - abs(e.y));
    if (n.z < 0.0) {
        n.xy = (1.0 - abs(n.yx)) * vec2(e.x >= 0.0 ? 1.0 : -1.0, e.y >= 0.0 ? 1.0 : -1.0);
    }
    frag_color = vec4(normalize(n) * 0.5 + 0.5, 1.0);
}
@end

@program prepass_view vs fs
