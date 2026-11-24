// The 2D painter of fa::render::UiPainter (the editor's Dear ImGui): textured, vertex-coloured triangles in pixels of a
// display, no depth. The vertex is {pos (float2), uv (float2), color (4 bytes, normalised)}, 20 bytes.
@module ui2d

@vs vs
layout(binding=0) uniform ui2d_vs_params {
    vec4 params;    // xy = the size of the display in the units of the vertex positions, z = the exponent that undoes an sRGB
                    // swapchain's encode of the vertex colour (1 for a linear target, 2.2 for an sRGB one), w unused
};
layout(location=0) in vec2 position;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;
out vec2 uv;
out vec4 color;
void main() {
    gl_Position = vec4(((position / params.xy) - vec2(0.5)) * vec2(2.0, -2.0), 0.5, 1.0);
    uv = texcoord0;
    color = vec4(pow(color0.xyz, vec3(params.z)), color0.w);
}
@end

@fs fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
in vec2 uv;
in vec4 color;
out vec4 frag_color;
void main() {
    frag_color = texture(sampler2D(tex, smp), uv) * color;
}
@end

@program ui2d vs fs
