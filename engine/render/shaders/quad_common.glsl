// FactorIA sprite template (material kind "sprite", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the skeleton M72.1 fills
// in. It will be the source of the 2D quad programs a custom sprite material is made from (Sprite, Shape2D, Tilemap, Text,
// particles, trails, UI images): the quad vertex and fragment stages of quad.glsl, with the material's @block fa_user injected
// like mesh_common.glsl does for meshes (a snippet defining void fragment(in QuadInput i, inout QuadSurface s) and,
// optionally, void vertex(...)).
//
// Today it only declares the snippet contract of the kind. Nothing includes it and no program is made from it: quad.glsl and
// every built-in shader are unchanged, and a material with "kind": "sprite" is refused until M72.1 lands.
//
// The structs have their own names (QuadInput, QuadSurface) so that a top file may include the template of one kind only and
// the contract of every kind can be read from its template (tools/common/src/shaders_generate.cpp, contract_structs).
// Every engine identifier starts with fa_ (FA_ for constants), as in mesh_common.glsl.

@block fa_quad_types
struct QuadInput {              // read-only, per fragment
    vec2 uv;                    // the quad's texture coordinates
    vec4 color;                 // the tint of the sprite, shape or glyph (vertex color)
    vec2 world_pos;             // world position of the fragment
};
struct QuadSurface {            // what the quad pipeline draws
    vec4 color;                 // straight (non-premultiplied) RGBA
};
@end
