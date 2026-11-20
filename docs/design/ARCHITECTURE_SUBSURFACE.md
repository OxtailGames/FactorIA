# FactorIA architecture: subsurface scattering (M73.5)

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page); the lighting it builds on is
[ARCHITECTURE_RENDERING_LIGHTING.md](ARCHITECTURE_RENDERING_LIGHTING.md) and the depth prepass it reads is described in
[ARCHITECTURE_RENDERING_POST.md](ARCHITECTURE_RENDERING_POST.md) and [ARCHITECTURE_SCREEN_EFFECTS.md](ARCHITECTURE_SCREEN_EFFECTS.md). The user-facing
description is [RENDERING_LIGHTING.md](../rendering/RENDERING_LIGHTING.md), "Subsurface scattering".

`MeshRenderer.subsurface` (strength 0..1), `subsurfaceRadius` (metres, the widest colour channel's) and `subsurfaceColor` (the spread of each colour channel,
relative to the radius) make skin, wax and marble. The scattering is screen-space: the diffuse light of the meshes that ask for it is drawn into an image of
its own, blurred in two separable depth-aware passes with a profile fitted for it, and the change the blur makes is added to the picture. Specular light,
reflections of the sky and emission are never in that image, so they stay sharp.

## Files

- `src/subsurface.{h,cpp}`: the CPU side, pure functions with no GPU (the tests of `subsurface_tests.cpp`): the profile (`kSssGauss`, `sss_kernel`,
  `sss_profile_2d`, `sss_profile_cdf`), the tap cells and weights (`kSssCell`, `sss_tap_weights`, `sss_tap_offset`, `sss_erf`), the pixel radius
  (`sss_radius_px`) and the plan of a camera (`SssPlan`, `make_sss_plan`).
- `shaders/subsurface.glsl` (module `subsurface`): `blur_h`, `blur_v` and `add` over a fullscreen vertex shader; the shader mirrors the CPU functions.
- `shaders/mesh_common.glsl`, `light_loop.glsl`: the `FA_SSS` variant of the mesh fragment shader (`fs_sss`, programs `mesh_sss` and `mesh_skin_sss`).
- `src/renderer_subsurface.{h,cpp}`: `SssFx`, the shaders and pipelines of the blur and the add, the probe of the images and the declaration of the three
  blur passes. `src/renderer_draw.cpp`: `sss_scatters`, the plan in `plan_job`, `Renderer::Impl::sss_draw_pass` and the `build_graph` declarations.
- `tools/shaders/fit_subsurface_profile.py`: our own fit of the table (pure Python, no dependencies); `kSssGauss` and the factor `kBurleyR90` of
  `subsurface.cpp` are its output.

## The profile

The light a surface scatters to the distance r from where it entered follows the normalized diffusion profile of Burley (2015),
`R(r) = (exp(-r/d) + exp(-r/(3d))) / (8 pi d r)`: a sharp core and a long red tail. A separable blur (one pass along x, one along y) cannot be R, so the 1D
kernel is a sum of four Gaussians fitted to the line integral of R, with the weights summing to 1 and the sigmas in units of the scatter radius, the distance
that holds 90% of the light of R (`d = 1 / 6.062229` for a radius of 1; `sss_profile_cdf(1) = 0.9`). The fit minimizes the squared error of the cumulative
distribution and is committed as a table, so the shader needs no data file. `subsurfaceRadius` is that 90% distance, per colour channel
(`subsurfaceRadius * subsurfaceColor`, each channel clamped 0..1), so a red radius wider than the blue one leaves the red tail that skin has.

The blur takes `2 * kSssTaps + 1 = 15` taps per pass. Tap k stands for the cell `[kSssCell[k-1], kSssCell[k]]` on each side of the centre (the centre tap for
`[-kSssCell[0], kSssCell[0]]`), in units of the widest channel's radius, and its weight is the mass of the four Gaussians in its cell (the difference of their
cumulative functions, an erf: `sss_erf`, Abramowitz and Stegun 7.1.26, error below 1.5e-7). Weights are therefore exact however small the radius: a radius under
a few pixels loses nothing, the taps that land on the same pixel add up. A channel whose radius is a fraction of the widest one divides the cell edges by that
fraction (clamped 0.02..1). The outermost edge is 2.2 radii (3.4 sigma of the widest Gaussian): what lies beyond is under 0.1% of the light and is lost,
and the weights of the taps that count are renormalised in the shader anyway.

## The passes

1. **`sss-draw`**, in the camera's own job right after its prepass. The opaque meshes with `subsurface > 0` are drawn again with the sss program of the mesh
   shader (the engine's own program: a mesh with a `material`, an unlit mesh or a mesh whose placement comes from GPU buffers does not scatter) into two images
   of the camera's rectangle, RGBA16F, with their own depth buffer (`Gpu::sss_target_format()`: two colour attachments, `TargetFormat.color1`):
   **A**: rgb = the DIFFUSE light toward the camera (`fa_indirect_diffuse` and the light loop with no specular and no sky reflection, the fog applied as a
   transmittance), a = the linear view depth of the fragment; **B**: rgb = the radius per channel in metres, a = the strength. Both are 0 where nothing
   scatters. The fragment compares its depth with the prepass (the screen texture, view 28, `abs(depth - prepass.r) < 0.02 + 0.01 * depth`), so only the
   surface the camera sees leaves light in A: a mesh behind another one, or behind a wall, writes nothing. No new fragment texture unit is used (the mesh shader has
   all 16): the sss variant shares the unit of the prepass with the contact shadows and takes one uniform block (`fa_sss_params`, binding 2).
2. **`sss-blur-h`**: A and B in, H out: the light blurred along x.
3. **`sss-blur-v`**: H, A and B in, V out: `strength * (blurred along y - A.rgb)`, signed. The picture already holds the unblurred diffuse light (the main pass drew
   it), so only the change needs adding, and a strength of 0.5 is half the way to the blurred light.
4. **`sss-add`**: V onto the camera's rectangle of the picture, as two draws of one pass: `max(V, 0)` with an additive blend, `max(-V, 0)` with a
   reverse-subtract blend. A signed source cannot go into an 8-bit or R11G11B10 target, hence two draws; each result is clamped to what the picture holds.

The last three are declared with the post stack, before the volumetric fog apply and the reflections (`SssFx::add_passes`), so blended meshes, fog and bloom see
the scattered light.

**Depth-aware.** A tap counts for a pixel only where A holds scattering light (a > 0) of a surface at about the same depth: `abs(t.a - depth) <= 0.01 + 2 * off`
(`off` = the tap's distance in metres, so a surface sloping about 63 degrees still counts, a depth jump does not). The light therefore never crosses a
silhouette and never reaches another object, scattering or not, and a pixel whose own depth is 0 takes nothing and gives nothing. The weights of the
accepted taps are renormalised per colour channel.

**Radius in pixels.** `radius_px = min(radius_m * focalPx / depth, kSssMaxRadiusPx)` with `focalPx = |proj[1][1]| * rectH / 2` (`SssPlan`); an orthographic
camera uses `focalPx` as pixels per world unit with no division. Below 0.3 px the pass returns the pixel unchanged.

## Plan, fallback and bounds

- **plan_job.** For every camera that draws and has a mesh with `sss_scatters` in a main batch, `make_sss_plan` and `SssFx::can_draw` run; an on plan sets
  `needsDepth` (the camera has a prepass: the visibility test reads it) and `scene_uniforms` carries the camera's view for the test. `PostPlan` carries
  `sss`, `sssLight` and `sssParams`. With no scattering mesh nothing is planned: no prepass, no pass, no pipeline, and the frame is bit for bit what it was.
- **Fallback.** `can_draw` is false (and the meshes draw with no scattering; the reason is logged once) when the GPU has no RGBA16F render targets that it can
  also sample (`SssFx::gpu_supported`, the `half` rule of the feature rows), when one of the four programs does not build, or when the images cannot be made for
  that size (probed once per size through the transient pool and remembered, at most 16 sizes). `render.supports("subsurface")` is the same rule plus the
  prepass (`half+depth`), so a game asks before it relies on it. GLES3 and WebGL2 run the passes in `highp` (the depth and the radius need it).
- **Bounds.** The loops have constant tops (7 taps on each side). The radius is clamped to `kSssMaxRadiusPx` = 40 px and `subsurfaceRadius` to
  `kSssMaxRadiusM` = 0.5 m; a non-finite or negative value counts as 0 (`subsurface_of` in `mesh_batch.h`). The cost is two fullscreen passes of 15 taps over the
  camera's rectangle plus one more draw of each scattering mesh, whatever the radius.
- **Batching.** `subsurface_of` returns {strength, radius, colour rgb}, all zero when the strength is 0, and is part of `material_key`, `order_key` and the
  per-instance shading data, so meshes with the same values share a draw and a radius or colour at strength 0 never splits a batch.
- **Stats.** `game.render_stats` reports `subsurfaceCameras` (cameras that scattered) and `subsurfaceDraws` (draw calls of the sss pass; the main pass draws the
  meshes too and counts them in `drawCalls`).

## Limits (stated, not hidden)

- **No MSAA in the images.** The sss images are single-sample: a pixel of the silhouette takes the scattering of the nearest sample, a small error at the edge
  of the shape. The picture itself keeps its MSAA.
- **What scatters.** Only opaque meshes of the engine's own program. A mesh with `MeshRenderer.material` (the custom lighting is the material's), an unlit mesh and
  a transparent mesh draw without scattering; blended meshes drawn over the skin do receive the change like the rest of the picture.
- **Order.** The fog is in A as a transmittance, the ambient occlusion of the SSAO is not (the main pass multiplies it into the picture, and the change is added
  after it); there is no temporal history, so a moving object does not smear.
- **A is the light of one surface.** It does not know what is behind a thin ear or finger: the scattering is of the surface, not through the object (transmission is
  M73.6).
- **A cap of 40 px.** A scatter radius that covers more pixels is clamped, so a mesh very close to the camera scatters less than its metres say.

## Tests

`engine/render/tests/subsurface_tests.cpp` (no GPU: the kernel integrates to 1, the fit against the diffusion profile, the weights of the taps and their
clamps, the pixel radius and its non-finite inputs, the plan, `subsurface_of`) and `subsurface_render_tests.cpp` (a wax sphere lit from one side bleeds into
its dark side and nothing outside the sphere changes, with a golden of our own, `3d_subsurface_wax`; bit for bit the plain picture when no mesh scatters, with
the other fields changed, with an unlit mesh and with only emission; no bleed of a red sphere 3 m behind into the sphere in front; the stats, a split screen of two
cameras, and MSAA). `sort_key_tests.cpp` checks that the values split batches.
