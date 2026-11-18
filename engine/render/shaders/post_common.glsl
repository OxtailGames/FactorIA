// FactorIA post-process template (material kind "post", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the skeleton M72.2
// fills in. It will be the source of the fullscreen program a custom post-process material is made from, one pass in the
// post-processing stack (post.glsl's fullscreen vertex stage and a fragment stage with the material's @block fa_user injected:
// a snippet defining void post(in PostInput i, inout PostSurface s), reading the colour, depth and normals of the stack).
//
// Today it only declares the snippet contract of the kind. Nothing includes it and no program is made from it: post.glsl and
// every built-in shader are unchanged, and a material with "kind": "post" is refused until M72.2 lands.
//
// The structs have their own names (PostInput, PostSurface), see quad_common.glsl. Every engine identifier starts with fa_.

@block fa_post_types
struct PostInput {              // read-only, per pixel
    vec2 uv;                    // 0..1, origin top left
    vec2 texel;                 // size of one pixel in uv units
};
struct PostSurface {            // what the pass writes
    vec4 color;                 // linear RGBA
};
@end
