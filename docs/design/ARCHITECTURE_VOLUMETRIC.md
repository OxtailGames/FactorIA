# FactorIA architecture: volumetric fog and light shafts (M73.5)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page); the lighting it builds on is
[ARCHITECTURE_RENDERING_LIGHTING.md](ARCHITECTURE_RENDERING_LIGHTING.md). The user-facing description is
[RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md), "Volumetric fog and light shafts".

## Volumetric fog

`SceneSettings.volumetricFog` and `Light.volumetric` . The code is
`src/renderer_volumetric.{h,cpp}` (the plan, the CPU twins of the shader's maths, the pipelines) and `shaders/volumetric.glsl` (module
`volumetric`: `fs_march` and `fs_apply` over the fullscreen vertex shader of the module).

- **Where it sits.** `plan_job` calls `make_vol_plan` (pure CPU: clamps the settings, picks the lights, lays them out as the shader's
  uniform arrays) for every perspective, non-studio camera that draws, before `plan_prepass`: an on plan sets `needsDepth`, so the camera has
  a prepass. After `plan_outline`, `VolumetricFx::can_draw` checks the GPU (RGBA16F render and sample), both programs and that the march image can be made (probed
  once per size through the transient pool, failures logged once per cause and remembered, at most 16 sizes); when it says no, the plan is reset
  to `VolPlan{}` and the camera keeps its analytic fog. `PostPlan` carries `vol` and `volImage`.
- **The passes.** `build_graph` declares `vol-march` in the camera's own job right after its prepass pass (reads the prepass, the shadow atlas
  resource when the job drew one, the light data texture; writes the transient RGBA16F image of `VolumetricFx::image_desc`: 1/2 or 1/4 of the
  camera's rectangle). It must be in the camera's job: the shadow atlas is one shared resource and a later job may overwrite it, so the march reads it
  before. `vol-apply` is declared in the post section of the last job for every camera with a plan, after `custom_slot(PostSlot::Main)` and before the
  reflections and the sun shafts, as a blend over the camera's rectangle of the picture (colour factors ONE / SRC_ALPHA, alpha ZERO / ONE: `picture * a + rgb`),
  so it needs no copy of the picture, and blended meshes, which are in the picture, are fogged by the depth of the opaque surface behind them.
- **No double fog.** The camera's analytic fogs are switched off when `vol.on`: `scene_uniforms` writes `fogDensity = 0` (the mesh shader's
  own fog) and the post plan sets `fogFx.fog = false`. The `PostProcess` sun shafts stay. A camera whose plan was reset draws its analytic fog.
- **The maths.** `sigma(y) = density * exp(-falloff * max(y - base, 0))`; the optical depth to a point on the ray is the closed form
  (`tau_at` in the shader, `vol_optical_depth` on the CPU: a level stretch or a hardly changing density uses the density at the middle of the
  stretch, where the difference of two integrals loses its digits), the transmittance `exp(-tau)`. Ambient and directional lights take `steps` samples along
  the ray; each point or spot light takes `samples` inside the part of the ray within its range. The phase is Henyey-Greenstein times 4 pi (1 = isotropic);
  the ambient term is `ambientLight * volumetricAmbient * albedo(fogColor)`. The jitter is interleaved gradient noise of the pixel of the march image
  (`vol_jitter`, with no frame term): no `rand`, no clock, no reprojection, so a still picture is bit-identical between frames.
- **Shadows.** The sun: a copy of the shadow block of the mesh shader (`mesh_fa_shadows_t`, the same uniform block, `fa_shadow_cfg[2] = 1`) so it reads the
  cascaded atlas with one tap; it applies to the light of slot 0 when it is the caster (`sunCasts`). Local lights: `vol_shadow_local` reads the
  light's record through `fa_light_texel` (the format of `shadow_common.glsl` / `light_data.glsl`) with one tap; the plan marks a light as
  shadowed when `shadowsDrawn` and its `shadow.casts`. The shader keeps its own light block (`vol_lights`: 4 directional + 16 local lights as uniform arrays) and
  reads only the shadow records of the light data texture, so it does not depend on how the mesh shader lays out the light list.
- **Bounds.** Loops have fixed tops (`kVolMaxSteps` 64, `kVolMaxSamples` 24, `kVolMaxDirectional` 4, `kVolMaxLocal` 16) with `break` on the count the
  uniform asks for (the loop test on GLES3/WebGL2 must be a constant). The quality table is `vol_quality`: low {divisor 4, 16 steps, 4 lights, 6
  samples}, medium {2, 32, 8, 10}, high {2, 48, 16, 16}; the light pick is `pick_volumetric_lights` (directional lights in table order, local by
  `score * volumetric` descending, stable on ties, cut to the quality, dropped ones counted, then back in table order). Precision: GLES3/WebGL2 fragment
  shaders are generated with `highp` for every declaration (`volumetric_tests.cpp` scans the generated source).
- **Cookie hook (M73.1, `p1b2`).** A cookie or IES profile multiplies the light in `local_atten` (the cone term) of the march; the plan's fourth vector
  per local light keeps the light's table index in `.x`, which is the key of its record in the light data texture, and `.z`/`.w` are free. The texel 3
  of that record reserves y/z for the cookie's atlas rect, which this pass does not read yet.
- **Stats.** `RenderStats::volumetricCameras`, `volumetricLights`, `volumetricLightsDropped`, summed per frame in `plan_job`; they are in `to_json`
  and in the text of `game.render_stats`. The profiler's pass names come from the frame graph (`<job>/vol-march`, `<job>/vol-apply`).
- **Tests.** `volumetric_tests.cpp`: the CPU parts (table, phase, jitter, optical depth against numeric integration, pick, plan) and the GPU parts (identity
  without the switch, ambient fog, a spot shaft, the sun through a gap, no double fog and the orthographic fallback, the quality limit and stats, a blended
  mesh); goldens `3d_volumetric_spot` and `3d_volumetric_sun_gap` (tolerance 0.01: the grain of the jitter).
