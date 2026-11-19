Part of [SHADERS.md](../SHADERS.md): your own light loop and the sky light for mesh materials with `"lighting": "custom"`
(and the same helpers in [full shaders](SHADERS_FULL.md)). The material file, the params, the compiler and the cache are the
ones that page describes.

# Your own light loop and the sky light

`light()` ([Custom lighting](../SHADERS.md#custom-lighting)) shades one light at a time: the engine picks the lights, calls
you once for each and adds the results. When that is not enough (a toon that is lit by the brightest light only, a
loop that wraps the lights around the surface, a look that treats the shadow apart from the light), define
`lighting()` instead: **the whole light loop is yours**.

```glsl
vec3 lighting(in SurfaceInput i, in Surface s);   // the lit color of the surface: every light and the ambient and sky terms
```

`surface()` runs first, as always, and fills `s` (`s.normal` is the normalized world-space normal it left). Then the
engine calls `lighting()` once per fragment, **instead of** its light loop, of `light()` and of `ambient()`, and adds
`s.emission` and the fog to what you return. What stays the engine's: the choice of the lights and their order, the
attenuation, the shadow map, `s.emission`, the fog, `"clip"` and `"blend"`, instancing, skinning, and the depth and normal
prepass. What is yours: which lights count and how, the ambient term (the scene's `ambientLight` is `fa_ambient.rgb`) and the
sky.

Rules of the hook:

- `lighting()` needs `"lighting": "custom"` in the material file. A `lighting()` in any other material is an error that
  points at `/lighting`. A function called `lighting` whose parameters are not a `SurfaceInput` and a `Surface` is an
  ordinary helper, not the hook.
- It replaces `light()` and `ambient()`: a snippet that defines `lighting()` and one of them is refused (the engine would
  never call the second). A custom material needs `light()` or `lighting()`.
- It is a function of the fragment stage, run once per fragment. A texture read there needs
  `textureLod(sampler2D(t, t_smp), uv, 0.0)` (a gradient inside a loop is refused by HLSL); `factoria validate` compiles every
  platform, so it finds that.
- `lighting` is a reserved name for a param of a custom material, like `light` and `ambient`.

## The functions

Every function below can be called from `light()`, `ambient()` and `lighting()` of a `"custom"` material, and from nowhere
else: `surface()` and `vertex()` run before the lights are known (and in the shadow and depth passes), so calling one there
is an error that says where to call it. `lighting()` and its helpers are also compiled in the shadow and depth programs,
where the functions answer "no lights", so the snippet compiles; they never run there.

| Function | What it gives |
|---|---|
| `fa_light_count()` | How many lights the engine selected for this frame, `0` to `32`. |
| `fa_light(n, i)` | The `LightSample` of light `n` (`0` to `fa_light_count() - 1`) at this fragment, as `light()` receives it: `direction`, `color` (colour times intensity times attenuation times shadow), `attenuation`, `shadow`, `distance`, `type` (0 directional, 1 point, 2 spot). A number out of range gives a sample that lights nothing (`color` and `attenuation` `0`, `shadow` `1`). |
| `fa_light_unshadowed(n, i)` | The same without the shadow map read: `shadow` is `1` and `color` has no shadow in it. Use it to rank or choose lights without paying for the shadow, or to apply the shadow your own way. |
| `fa_light_shadow(n, i)` | The shadow of light `n` at this fragment: `1` lit, `0` in shadow, a value between at the edge. Only light `0`, when it is the directional light that casts shadows and the mesh receives them, has a shadow map; every other light answers `1`. |
| `fa_sky_light(i, s)` | The sky reflection (image-based lighting) the engine adds to a `"pbr"` material, for this surface: from `s.albedo`, `s.metallic`, `s.roughness`, `s.normal` and `s.occlusion` and the direction to the camera. Add it to what you return, scaled or tinted as you like. |
| `fa_sky_reflection(n, v, f0, roughness)` | The same term from the parts: normal `n`, direction to the camera `v`, reflectance at normal incidence `f0` (`vec3`: `0.04` for a dielectric, the albedo for a metal) and `roughness`. |
| `fa_environment(direction, roughness)` | The color of the sky in a world direction, blurrier and flatter when `roughness` grows. |
| `fa_env_brdf(roughness, ndv)` | The scale and bias (a `vec2`) of `f0` of the split-sum environment BRDF, `ndv` being `dot(n, v)`. `fa_sky_reflection` is `fa_environment(reflect(-v, n), roughness) * (f0 * ab.x + ab.y)`. |

`fa_ambient` (a `vec4`, `.rgb` is `SceneSettings.ambientLight`) and `fa_camera_pos` are in scope too. The sky is not a
cubemap: it is the gradient of `SceneSettings.skyColor` (top) and `horizonColor` (the horizon, and a darker copy below it),
which the engine's own meshes reflect too, so a custom material that adds `fa_sky_light(i, s)` reflects the same sky as a
`"pbr"` one. In a `"custom"` material that has no `lighting()` the sky reflection is off, as before; call `fa_sky_light()` from
`ambient()` (return it, or add it to the ambient colour) or from `light()` to turn it on, or from `lighting()`.

## Which lights, how many, in what order

The lights are chosen once per frame for every mesh (they are not per mesh), by `Light` entities that are active in the
scene. At most **32** reach the shader: `fa_light_count()` never returns more, and what does not fit is left out
(`stats.lightsDropped` counts it). The order is the engine's, and it is also the order of `light()`'s calls:

1. the directional light that casts the shadow (the first directional `Light` with `castShadows` of the scene), alone, in
   slot `0`;
2. the other directional lights, the brightest first (colour times intensity: the largest channel);
3. the point and spot lights, the most relevant first: the brightness, scaled by `range^2 / (range^2 + distance^2)` with
   the distance from the light to the camera (so a bright light near the camera beats a bright one far away).

Equal scores keep the order of the scene. With `Camera.lighting = studio` the camera's own three-light rig replaces the
scene's lights. A scene with no `Light` has `fa_light_count() == 0` and logs a warning once.

Light `0` is the only one with a shadow, and only when a directional light casts shadows (it is then light `0`) and the
`MeshRenderer` has `receiveShadows`: otherwise `fa_light_shadow(0, i)` is `1` too. A loop that wants "the sun" asks
`fa_light(0, i)` and checks `.type == 0`.

## Example: the brightest light only, as a toon, plus the sky

File `materials/brightest.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "A two-band toon lit by the brightest light only, with a touch of sky reflection.",
  "shader": "shaders/brightest.surface.glsl",
  "lighting": "custom",
  "params": {
    "dark": { "type": "float", "default": 0.35, "min": 0.0, "max": 1.0, "doc": "Brightness of the shaded band." },
    "skyAmount": { "type": "float", "default": 0.5, "min": 0.0, "max": 4.0, "doc": "How much of the sky reflection to add." }
  }
}
```

File `shaders/brightest.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 lighting(in SurfaceInput i, in Surface s) {
    int best = -1;
    float bestPower = 0.0;
    for (int n = 0; n < fa_light_count(); ++n) {
        LightSample l = fa_light_unshadowed(n, i);                 // no shadow map read while we only rank
        float power = dot(l.color, vec3(0.299, 0.587, 0.114));
        if (power > bestPower) { bestPower = power; best = n; }
    }
    vec3 lit = fa_ambient.rgb * s.albedo * s.occlusion;            // the ambient term, written by hand now
    if (best >= 0) {
        LightSample l = fa_light(best, i);                          // the shadow, for the one that counts
        float band = dot(s.normal, l.direction) > 0.5 ? 1.0 : dark;
        lit += s.albedo * l.color * band;
    }
    return lit + fa_sky_light(i, s) * skyAmount;                    // set s.metallic and s.roughness in surface() to shape it
}
```

The sky alone from `ambient()`, in a material that still shades with `light()`:

```glsl
vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return ambientColor * s.albedo * s.occlusion + fa_sky_light(i, s);
}
```

## Full shaders

A [full shader](SHADERS_FULL.md) has `fa_light_count()` and `fa_light(i, world_pos, geometric_normal, shadow_coord)` (its own
signature: a full shader has no `SurfaceInput`), and now also `fa_environment(direction, roughness)`, `fa_env_brdf(roughness,
ndv)` and `fa_sky_reflection(n, v, f0, roughness)`, the same three as above, with `fa_env_sky` and `fa_env_horizon` as the
sky they read. The order and the cap of the lights are the ones of the section above.

## Errors

Every one is found before sokol-shdc starts (the message names the material file and the JSON pointer, or the line of the
snippet) and teaches the fix:

| Mistake | What the error says |
|---|---|
| `lighting()` in a material without `"lighting": "custom"` | Set it in the material file (`/lighting`), or rename the helper. |
| `lighting()` and `light()` (or `ambient()`) in one snippet | Remove the second: `lighting()` is the whole loop; where each part of the old one goes. |
| One of the functions above in a `"pbr"` or `"unlit"` material, or in `surface()` or `vertex()` | Set `"lighting": "custom"`, or call it in `light()`, `ambient()` or `lighting()`. |
| A misspelled name (`fa_sky_ligth`) | `did you mean fa_sky_light?` and the list of the functions. |
| Neither `light()` nor `lighting()` in a custom material | The signatures of both, and how to go back to `"pbr"`. |
