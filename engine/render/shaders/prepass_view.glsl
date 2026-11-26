// The debug view of the depth and normal prepass (Renderer::set_debug_view): draws what the prepass holds as a picture, over the game
// image of the frame. One full-screen triangle that reads the prepass image (mesh_common.glsl, prepass_fs: r = linear view depth in world
// units, gb = octahedral view-space normal, a = 1 where an opaque mesh was drawn) and writes
//   mode 1 (depth)    grey = 10 / (10 + depth): white next to the camera, darker the farther; black where nothing was drawn
//   mode 2 (normals)  the view-space normal as a colour, rgb = n * 0.5 + 0.5 (x right, y up, z toward the camera); black where nothing was drawn
//   mode 3 (motion)   reads the velocity image instead (M76, RG16F, rg = uvPrev - uvCurr, 1024 where no object wrote): the direction of the
//                     motion as a hue, its length as the brightness (black = still, full colour from 2.5% of the image per frame), mid grey
//                     where no object wrote a vector
//   mode 4 (raw)      TEST-ONLY (RendererTestAccess::read_velocity, renderer_draw.cpp kPrepassViewRaw): the velocity as floats, rg = the vector as it
//                     is, into an RGBA16F image a test reads back; no game or tool draws it
//   mode 5 (albedo)   reads the thin G-buffer's albedo image (M79-P0c, RGBA8, a = 1 where a mesh was drawn): its rgb; black where nothing was drawn
//   mode 6 (material) reads the G-buffer's material image: red = the roughness, green = the metalness; black where nothing was drawn
//   mode 7 (raw)      TEST-ONLY (RendererTestAccess::read_gbuffer): the four channels of a G-buffer image as they are, into an RGBA16F image
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
    vec4 mode;      // x = 1 depth, 2 normals, 3 motion vectors, 4 the raw floats, test-only (the image is the velocity's),
                    // 5 the G-buffer's albedo, 6 the G-buffer's roughness (red) and metalness (green), 7 the four channels as they are, test-only
};
in vec2 uv;
out vec4 frag_color;
void main() {
    vec4 t = textureLod(sampler2D(tex, smp), uv, 0.0);
    if (mode.x > 6.5) {  // mode 7 (test-only): the four channels as they are, into a float image
        frag_color = t;
        return;
    }
    if (mode.x > 4.5) {  // modes 5 and 6: the thin G-buffer (alpha 0: nothing was drawn, black)
        frag_color = t.a < 0.5 ? vec4(0.0, 0.0, 0.0, 1.0) : (mode.x < 5.5 ? vec4(t.rgb, 1.0) : vec4(t.r, t.g, 0.0, 1.0));
        return;
    }
    if (mode.x > 3.5) {  // mode 4 (test-only): the vector as it is, into a float image
        frag_color = vec4(t.rg, 0.0, 1.0);
        return;
    }
    if (mode.x > 2.5) {
        vec2 m = t.rg;
        // The sentinel (and anything not a motion: NaN too) is grey; the writer never leaves a real motion beyond 4 images.
        if (!(abs(m.x) < 512.0 && abs(m.y) < 512.0)) {
            frag_color = vec4(0.3, 0.3, 0.3, 1.0);
            return;
        }
        float len = length(m);
        float hue = atan(m.y, m.x) * 0.15915494 + 0.5;  // 0..1 around the circle
        vec3 rgb = clamp(abs(fract(hue + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
        frag_color = vec4(rgb * clamp(len * 40.0, 0.0, 1.0), 1.0);
        return;
    }
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
