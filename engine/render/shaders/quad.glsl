// The engine's 2D quad programs: sprites, tiles, text glyphs, shapes, particles, debug lines (the modes are described in
// quad_common.glsl). The template (quad_common.glsl) with the default snippet, an empty fragment(). A sprite material's
// generated top file has this very shape with its own fa_user block, so a material whose fragment() is empty draws exactly what
// the engine's own program draws.
@module quad

@block fa_user
void fragment(in QuadInput i, inout QuadSurface s) {}
@end

@include quad_common.glsl

@program quad vs fs
@program quad_plain vs fs_plain
