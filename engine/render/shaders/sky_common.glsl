// FactorIA sky template (material kind "sky", docs/design/CUSTOM_SHADERS.md, "Kinds (M72)"): the source of the sky program, the
// engine's own (sky.glsl: the vertical gradient SceneSettings.skyColor / horizonColor, drawn as the background of a perspective
// camera) and every sky material's. Not compiled on its own: a top file defines the @block fa_user (the material's uniforms,
// textures and snippet: void sky(in SkyInput i, inout SkySurface s)), then `@include sky_common.glsl` and declares the program:
//   @program sky vs fs                 (sky.glsl does exactly this with an empty sky())
// A custom material's generated top file has this very shape with its own fa_user block, so a sky material whose sky() is empty
// draws exactly the pixels the engine's own sky program does.
//
// The engine names of this file (the vertex attribute `pos`, the varying `ray_dir`, the uniform block members, frag_color...) are
// not prefixed: they are the ones the renderer's C++ code binds by (the generated header's ATTR_/UB_ constants and
// sky_vs_params_t / sky_fs_params_t members), so a param or texture of a material must not take any of them (parse_material
// refuses them: tools/common/src/shaders_generate.cpp, template_globals reads this file and its @includes). What a snippet may use
// is the contract below and the fa_ names: fa_time, fa_scene_rgb().
//
// Bindings. Uniform blocks: vertex 0 sky_vs_params, fragment 1 sky_fs_params (+ 5 for the material's own block, fa_material).
// The engine binds no texture of its own, so a material's textures are views 0.. and samplers 0.. (kMaterialSkyFirstView of
// engine/render/src/render_internal.h). There is no vertex() hook: the sky is one full-screen triangle.
//
// What sky() receives. s.color holds what the engine would draw (the gradient of SceneSettings.skyColor and horizonColor, already in
// the scene's colour space): an empty sky() is the built-in look. The result is drawn opaque, as the background of the 3D scene.
// Only the background is made by the material: the ambient and reflection light of the scene (the image based lighting of the
// meshes) still follow SceneSettings.skyColor and horizonColor.

// The snippet contract (docs/SHADERS.md, "Sky materials").
@block fa_sky_types
struct SkyInput {               // read-only, per sky fragment
    vec3 dir;                   // view direction in world space, normalized (y = up)
    vec3 sun_dir;               // direction towards the sun, normalized: the scene's sun (the directional light of slot 0), (0, 1, 0) with none
    float time;                 // seconds of game time since the scene started (the same as fa_time.x)
};
struct SkySurface {             // what the sky draws
    vec3 color;                 // linear RGB radiance in the scene's colour space (arrives holding the engine's gradient)
};
@end

@include color_space.glsl

@vs vs
layout(binding=0) uniform sky_vs_params {
    mat4 inv_view_proj;
    vec4 cam_pos;
};
layout(location=0) in vec2 pos;
out vec3 ray_dir;
void main() {
    gl_Position = vec4(pos, 1.0, 1.0);
    vec4 far_pt = inv_view_proj * vec4(pos, 1.0, 1.0);
    ray_dir = far_pt.xyz / far_pt.w - cam_pos.xyz;
}
@end

@fs fs
layout(binding=1) uniform sky_fs_params {
    vec4 sky_color;
    vec4 horizon_color;
    vec4 fa_sun;                // xyz = unit vector towards the sun: the scene's directional light of slot 0 (the one that casts shadows,
                                // else the brightest), (0, 1, 0) with none
    vec4 fa_time;               // x = seconds of game time since the scene started (a snippet reads it; 0 for the engine's own program)
    vec4 fa_cspace;             // x = 1 in a linear scene (SceneSettings.colorSpace): fa_scene_rgb() converts sRGB colours to linear
};
in vec3 ray_dir;
out vec4 frag_color;

@include_block color_space
@include_block fa_sky_types

// What the snippet may call from sky(): an sRGB colour of the author (a param of type color) in the scene's colour space.
vec3 fa_scene_rgb(vec3 c) {
    if (fa_cspace.x > 0.5) c = fa_srgb_to_linear(c);
    return c;
}

@include_block fa_user

void main() {
    vec3 d = normalize(ray_dir);
    float h = clamp(d.y, 0.0, 1.0);
    float t = pow(h, 0.55);
    // The material's sky() (an empty one in the engine's own program) sees the engine's gradient and may replace it.
    SkyInput fa_in;
    fa_in.dir = d;
    fa_in.sun_dir = fa_sun.xyz;
    fa_in.time = fa_time.x;
    SkySurface fa_surf;
    fa_surf.color = mix(horizon_color.rgb, sky_color.rgb, t);
    sky(fa_in, fa_surf);
    frag_color = vec4(fa_surf.color, 1.0);
}
@end
