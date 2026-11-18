// FactorIA sky template (material kind "sky", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the skeleton M72.1 fills in. It
// will be the source of the sky program a custom sky material is made from (the background the 3D scene and the environment
// lighting see): sky.glsl's stages with the material's @block fa_user injected (a snippet defining void sky(in SkyInput i,
// inout SkySurface s)).
//
// Today it only declares the snippet contract of the kind. Nothing includes it and no program is made from it: sky.glsl and
// every built-in shader are unchanged, and a material with "kind": "sky" is refused until M72.1 lands.
//
// The structs have their own names (SkyInput, SkySurface), see quad_common.glsl. Every engine identifier starts with fa_.

@block fa_sky_types
struct SkyInput {               // read-only, per sky fragment
    vec3 dir;                   // view direction in world space, normalized
    vec3 sun_dir;               // direction towards the sun, normalized
};
struct SkySurface {             // what the sky draws
    vec3 color;                 // linear RGB radiance
};
@end
