// shdc-slang: glsl430:metal_macos:metal_ios:metal_sim:hlsl5
// The base level of the Hi-Z pyramid (M75.2, engine/render/src/hiz.h, renderer_hiz.cpp): one thread per cell of a cells-across x cells-down
// grid reads the pixels of the depth and normal prepass image under its cell and writes (nearest, farthest) view depth into a storage
// buffer, row 0 = the top of the picture. A pixel that shows no mesh (a = 0) counts as "no depth" (3e38) in both, so a cell that is not
// covered in every pixel can hide nothing. The cells' pixel ranges overlap by one pixel at the edges (floor / ceil), which only makes the
// nearest smaller and the farthest bigger: never wrong in the safe direction. No GLES3 / WebGL2 version exists (compute shaders): the
// compile script gives this file its own dialect list, so the web and Android players do not carry it.
@module hiz

@cs cs
layout(local_size_x=8, local_size_y=8, local_size_z=1) in;
struct hiz_cell_item { vec2 v; };  // (nearest, farthest)
layout(binding=0) writeonly buffer hiz_cells_buf { hiz_cell_item data[]; } hiz_cells;
layout(binding=1) uniform texture2D prepass_tex;
layout(binding=0) uniform sampler prepass_smp;
@image_sample_type prepass_tex unfilterable_float
@sampler_type prepass_smp nonfiltering
layout(binding=0) uniform hiz_params {
    vec4 dims;      // x, y = the prepass image's size in pixels, z, w = the cells across and down
    vec4 flip;      // x = 1 when the image's row 0 is the bottom of the picture (OpenGL render targets), 0 otherwise
};

void main() {
    ivec2 cell = ivec2(gl_GlobalInvocationID.xy);
    ivec2 cells_n = ivec2(dims.zw);
    if (cell.x >= cells_n.x || cell.y >= cells_n.y) return;
    ivec2 size = ivec2(dims.xy);
    // The pixels under the cell, rounded outwards.
    ivec2 lo = (cell * size) / cells_n;
    ivec2 hi = ((cell + ivec2(1)) * size + cells_n - ivec2(1)) / cells_n;
    hi = min(hi, size);
    hi = min(hi, lo + ivec2(128));  // a bound for an absurd image size: never an endless loop
    float nearest = 3.0e38;
    float farthest = -1.0;
    for (int y = lo.y; y < hi.y; ++y) {
        int row = flip.x > 0.5 ? size.y - 1 - y : y;
        for (int x = lo.x; x < hi.x; ++x) {
            vec4 t = texelFetch(sampler2D(prepass_tex, prepass_smp), ivec2(x, row), 0);
            float d = t.a > 0.5 ? t.r : 3.0e38;
            nearest = min(nearest, d);
            farthest = max(farthest, d);
        }
    }
    if (farthest < 0.0) { nearest = 3.0e38; farthest = 3.0e38; }  // an empty range: shows no mesh
    hiz_cells.data[cell.y * cells_n.x + cell.x].v = vec2(nearest, farthest);
}
@end

@program hiz cs
