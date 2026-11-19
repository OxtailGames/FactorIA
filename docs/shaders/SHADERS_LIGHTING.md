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

Every function below can be called from `light()`, `ambient()` and `lighting()` of a `"custom"` material. `surface()` and
`vertex()` run before the lights are known (and in the shadow and depth passes), so calling one there is an error that says
where to call it, except the four that only read the sky (`fa_environment`, `fa_env_brdf`, `fa_sky_reflection`,
`fa_ambient_light`): `surface()` may call those (an `emission` that shows the sky, a clip mask). In the shadow and depth
passes they read the sky of the previous frame (black in the first one), see "The sky material lights the meshes". `lighting()` and its helpers
are also compiled in the shadow and depth programs, where the functions answer "no lights", so the snippet compiles; they
never run there.

A helper function of your own (one that is not `light()`, `ambient()`, `lighting()`, `surface()` or `vertex()`) is compiled
into the vertex stage too, and the vertex stage has none of these functions. If the helper calls `fa_light`, `fa_light_count`,
`fa_sky_light` or another one from the table, the compiler says the function is declared in the fragment stage only. Wrap
the helper in `#ifdef GL_FRAGMENT_SHADER ... #endif` (the hooks need no wrapper), or call it from a hook only.

| Function | What it gives |
|---|---|
| `fa_light_count()` | How many lights the engine selected for this frame, `0` to `32`. |
| `fa_light(n, i)` | The `LightSample` of light `n` (`0` to `fa_light_count() - 1`) at this fragment, as `light()` receives it: `direction`, `color` (colour times intensity times attenuation times shadow), `attenuation`, `shadow`, `distance`, `type` (0 directional, 1 point, 2 spot). A number out of range gives a sample that lights nothing (`color` and `attenuation` `0`, `shadow` `1`). |
| `fa_light_unshadowed(n, i)` | The same without the shadow map read: `shadow` is `1` and `color` has no shadow in it. Use it to rank or choose lights without paying for the shadow, or to apply the shadow your own way. |
| `fa_light_shadow(n, i)` | The shadow of light `n` at this fragment: `1` lit, `0` in shadow, a value between at the edge. Only light `0`, when it is the directional light that casts shadows and the mesh receives them, has a shadow map; every other light answers `1`. |
| `fa_sky_light(i, s)` | The sky reflection (image-based lighting) the engine adds to a `"pbr"` material, for this surface: from `s.albedo`, `s.metallic`, `s.roughness`, `s.normal` and `s.occlusion` and the direction to the camera. Add it to what you return, scaled or tinted as you like. |
| `fa_sky_reflection(n, v, f0, roughness)` | The same term from the parts: normal `n`, direction to the camera `v`, reflectance at normal incidence `f0` (`vec3`: `0.04` for a dielectric, the albedo for a metal) and `roughness`. |
| `fa_environment(direction, roughness)` | The color of the sky in a world direction, blurrier and flatter when `roughness` grows. With a sky material (below) it reads the sky that is seen. |
| `fa_ambient_light(n)` | The ambient light a diffuse surface facing the world direction `n` receives: `ambientLight`, or, with a sky material, the light of that sky from every direction (the cosine-weighted average). A `vec3`. |
| `fa_env_brdf(roughness, ndv)` | The scale and bias (a `vec2`) of `f0` of the split-sum environment BRDF, `ndv` being `dot(n, v)`. `fa_sky_reflection` is `fa_environment(reflect(-v, n), roughness) * (f0 * ab.x + ab.y)`. |

`fa_ambient` (a `vec4`, `.rgb` is `SceneSettings.ambientLight`) and `fa_camera_pos` are in scope too. Without a sky
material the sky is the gradient of `SceneSettings.skyColor` (top) and `horizonColor` (the horizon, and a darker copy below
it), which the engine's own meshes reflect too, so a custom material that adds `fa_sky_light(i, s)` reflects the same sky as
a `"pbr"` one; with one it is the sky of the material (next section). In a `"custom"` material that has no `lighting()` the sky reflection is off, as before; call `fa_sky_light()` from
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

## The sky material lights the meshes

A scene with a sky material (`SceneSettings.skyMaterial`, [sky materials](../SHADERS.md)) shows that sky and is also lit by
it: the engine bakes the sky the material draws into two small cube images, and every mesh of the camera reads them.

- **Reflection.** `fa_environment(direction, roughness)`, `fa_sky_reflection` and `fa_sky_light` (so every `"pbr"` mesh and
  every custom mesh that calls them) read a cube prefiltered per roughness (128 x 128 per face, 5 mips from mirror to rough).
  A metallic mirror ball under a sky of two colours shows each colour on the side that faces it.
- **Ambient.** `fa_ambient_light(n)`, which the engine adds as the ambient term of every `"pbr"` mesh and which a custom
  material reads in `ambient()` or `lighting()`, is the irradiance of that sky (an 8 x 8 cube, cosine-weighted and divided by
  pi, so a sky of one colour gives that colour). It **replaces** `SceneSettings.ambientLight` for the meshes the sky lights:
  the scene's own ambient is not added to it. `fa_ambient.rgb` keeps being `ambientLight`; write `fa_ambient_light(s.normal)`
  to use the sky's.
- **What is not changed.** Without a sky material the pixels and the draw calls are the same: no pass bakes anything and no
  environment image is made. A black 1 x 1 cube and its sampler are made at the first mesh draw (it fills the slot the mesh
  shaders declare), and every mesh draw binds them and every fragment tests one uniform: a bit more work, not none. A failed
  sky material (drawn as the built-in gradient) lights nothing either. Sprites, the
  `studio` lighting of a camera and the picture of a post material are not lit by it.

**When it is baked again.** The bake is one set of 60 small draws (6 of the sky itself, the rest the filtering). It runs at the
start of a frame in which any of these changed since the last bake: the material file or its shader (also on hot reload), a
param or a texture of it, `skyColor`, `horizonColor`, the sun **when `sky()` reads it** (`i.sun_dir` or `fa_sun`), or the
linear-colour setting. A sky that never changes is baked once. A sun that turns (a day cycle) bakes again in every frame in
which it moved, 60 passes each time, but only for a sky that reads it: a sky that does not is not baked again, so write a
sky that follows the sun only when you want its light to follow too.
A sky whose `sky()` reads `SkyInput.time` (or `fa_time`) is **animated**: it is baked again every `0.1` s of game time (the
engine clock, so a replay or a fixed step gives the same pictures, and a paused game does not bake), and the bake shows the sky
as it is at the start of that step, not at the current frame. The meshes follow it with a step of at most `0.1` s, the sky
you see follows it every frame.

The meshes that read the cubes in the frame in which they are baked see the new sky. The shadow and depth passes (and with them
the `surface()` of an `alphaMode` `"clip"` material that runs there) come before the bake: a `fa_environment()` or `fa_ambient_light()`
in `surface()` reads the cubes of the previous frame there, and black in the first frame of a sky. Use them in `light()`,
`ambient()` or `lighting()` for a result that is always current.

**What it costs.** Measured on Metal (Apple M-series, a small scene; the test "what one bake of the environment costs" in
`engine/render/tests/render3d_tests.cpp` prints the numbers): a frame that bakes takes about 2 to 3.5 ms longer than one that does
not (it varies with what else the machine does), of which about 0.3 to 0.6 ms is CPU time recording the 60 passes; a frame with a sky material that does not bake costs the same as
one without (0.3 to 0.6 ms for both there; the little work every mesh draw does without a sky is below what that
measures). A still sky pays the bake once; an animated one pays it every 6 frames at 60 fps (0.3 to 0.6 ms per frame on average),
as a spike of one frame. Metal has no GPU timer here, so these are frame times, not pass
times. The Direct3D 11 and OpenGL numbers are not measured yet. Your `sky()` runs on 6 x 128 x 128 pixels in a bake, on top of
the frame's own sky. The images (the two cubes and the four steps that filter them) take about 2 MB in half floats.

**One sky per frame.** There is one environment, shared by every camera and render target of the frame: the first job that
needs it decides which sky it holds, and a job whose sky inputs differ from that one (for example a render target with its own
`skyColor`) is lit by the built-in analytic sky, as it was before this existed.

**Other backends.** The faces are drawn with the cube map layout of the specification on every backend; OpenGL stores a render
target bottom-up, so its faces are drawn with the up axis negated. That is checked by reading the code and the specification
only: the test runs on Metal here, and the OpenGL, Direct3D 11 and WebGL 2 layouts have not been seen on a real device. The
images are RGBA16F where the GPU can draw to it and filter it (every desktop GPU, GLES 3 with `EXT_color_buffer_half_float`, WebGL 2
with `EXT_color_buffer_float` or `_half_float`), else RGBA8: the sky is then clamped to 0..1 (a sky brighter than white, or a
sun, loses its brightness in the reflection) and very dark gradients show bands. The sky you see is drawn directly, not from the
cubes, so it is the same on both.

## Errors

Every one is found before sokol-shdc starts, except a misspelled function name, which comes out of sokol-shdc (the message
names the material file and the JSON pointer, or the line of the snippet) and teaches the fix:

| Mistake | What the error says |
|---|---|
| `lighting()` in a material without `"lighting": "custom"` | Set it in the material file (`/lighting`), or rename the helper. |
| `lighting()` and `light()` (or `ambient()`) in one snippet | Remove the second: `lighting()` is the whole loop; where each part of the old one goes. |
| One of the functions above in a `"pbr"` or `"unlit"` material, or in `surface()` or `vertex()` | Set `"lighting": "custom"`, or call it in `light()`, `ambient()` or `lighting()`. |
| A misspelled name (`fa_sky_ligth`) | `did you mean fa_sky_light?` and the list of the functions. |
| A helper that calls one of the functions, compiled into the vertex stage | The function is declared in the fragment stage only: its signature, and `#ifdef GL_FRAGMENT_SHADER`. |
| Neither `light()` nor `lighting()` in a custom material | The signatures of both, and how to go back to `"pbr"`. |
