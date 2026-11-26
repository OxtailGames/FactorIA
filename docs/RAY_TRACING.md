# Ray tracing (M79)

Ray tracing lets the renderer ask the scene questions that the shadow maps and the screen-space effects only approximate: "is there
something between this point and the light?", "what does this mirror reflect?", "how much of the sky does this corner see?". The GPU
answers with a **ray query** inside a compute shader, against **acceleration structures** it builds from the scene's meshes. It is off by
default, and free when off.

> **What exists today.** Milestone 79 brings ray tracing one piece at a time. This version has the **shared interface**: the
> settings below, the `raytracing` rows of `render.supports`, the command `render.ray_tracing`, and the acceleration structure calls of
> the GPU interface (`engine/render/src/gpu/`; docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md describes it, repository only, not in the binary).
> The Direct3D 12, Vulkan and Metal backends build acceleration structures and run inline ray queries on a GPU that has them (the table below).
> **Five effects draw with rays so far: `shadows`** (the sun's shadow, hard or soft, "Shadows", below), **`ao`** (ambient
> occlusion, "Ambient occlusion", below), **`reflections`** (mirror and glossy reflections, "Reflections", below), **`translucency`**
> (refraction through glass and liquids, "Translucency", below) and **`gi` = `probes`** (the light probes of the `RealtimeGI` grids updated
> with rays, "Global illumination", below). `gi` = `perPixel` changes nothing in the picture yet, and `render.ray_tracing` says what is
> traced (`active`, with the reason). The sections below say what each part will do and mark what is planned.
>
> **The scene's acceleration structures (package P1s)** are built by the renderer on a device that can trace, when `enabled` is true and
> an effect is on ("Which objects are traced", below). Direct3D 12, Vulkan and Metal run them; the shadow kernel reads them.

## The settings

```json
{ "render": { "rayTracing": { "enabled": true, "shadows": "soft", "ao": true, "reflections": false,
                              "translucency": false, "gi": "off", "raysPerPixel": 1, "maxInstances": 65536 } } }
```

Every key is optional; a key you leave out keeps its default, and a project with no `render.rayTracing` (or with every key at its
default) writes nothing to `factoria.json`.

| key | values | default | meaning |
|---|---|---|---|
| `enabled` | `true`, `false` | `false` | The master switch. `false`: nothing below is read, no acceleration structure is made, no pass is added to the frame, no memory is held. |
| `shadows` | `off`, `hard`, `soft` | `off` | `off` = the shadow maps of the lighting. `hard` = one ray per pixel towards the sun, the shadow of the directional light that has `castShadows`, and of up to three point, spot and area lights (a sharp edge; "Shadows", below). `soft` = `raysPerPixel` rays towards points of the sun's disc, denoised (the edge softens with the distance to the caster; "Soft shadows", below). |
| `ao` | `true`, `false` | `false` | Ambient occlusion traced with rays, instead of the screen-space one ("Ambient occlusion", below). |
| `reflections` | `true`, `false` | `false` | Reflections traced with rays: a surface smoother than roughness 0.25 gets one mirror ray per pixel; one from 0.25 to 0.65 gets `raysPerPixel` rays spread by its roughness, denoised, and fades into the screen-space reflections and the probes towards 0.65 ("Reflections" below). Rougher surfaces keep the old reflections. |
| `translucency` | `true`, `false` | `false` | Refraction through glass and liquids traced with rays: a ray bent at every interface of the closed mesh, tinted by the volume, instead of the screen-space refraction ("Translucency", below). Coloured shadows are not made. |
| `gi` | `off`, `probes`, `perPixel` | `off` | Global illumination. `off` = the engine's own (light probes and the ambient). `probes` = the probes of the `RealtimeGI` grids updated with rays instead of raster captures ("Global illumination", below). `perPixel` = a bounce traced for every pixel (the most expensive; not made yet: it draws nothing). |
| `raysPerPixel` | whole number, 1 to 16 | `1` | Rays of each effect per pixel and frame; the denoiser makes up the rest. A value outside the range is **clamped**, not an error. |
| `maxInstances` | whole number, 1 to 1048576 | `65536` | The most instances the top-level acceleration structure holds; when a scene has more, the nearest to the camera come first. Clamped like `raysPerPixel`. |

Rays are asked for only when `enabled` is true **and** at least one effect is on (`shadows` other than `off`, `ao`, `reflections`,
`translucency`, or `gi` other than `off`). The master switch alone, or an effect with the switch off, asks for nothing.

A wrong key, name or type is an error that names the JSON pointer, what is wrong and a "did you mean":

```
factoria.json#/render/rayTracing/shadows: "sofft" is not a valid shadows mode  (Hint: Did you mean 'soft'?)
```

The settings are read from `factoria.json` at the start and changed while the game runs with the command `render.ray_tracing`.

## The command

`render.ray_tracing` reads or changes the same settings (no argument reads them; any key changes those and keeps the rest):

```
factoria call --no-graphics --project my_game render.ray_tracing '{"enabled":true,"shadows":"soft"}'
```

It returns the settings plus:

| field | meaning |
|---|---|
| `supported` | what `render.supports {"feature":"raytracing"}` answers on this device (false without a renderer, for example with `--no-graphics`). |
| `active` | whether an effect that draws with rays is on and the device traces: in this version `enabled` with `shadows` other than `off`, or `ao`, `reflections`, `translucency` or `gi` = `probes` on, on a device that can trace. It does not look at the scene: a scene with no directional light that casts shadows has nothing to trace (see "Shadows"). |
| `reason` | empty while `enabled` is false; otherwise what is traced, or why nothing is (the device's reason, or that no effect that draws with rays is on). |
| `localShadows` | `{cap, candidates, traced}`: the most point, spot and area lights traced per camera and frame (3), how many asked for a shadow in the last frame, and how many of them were traced (the rest keep their maps). 0 and 0 while `shadows` is `off` or nothing is active. |
| `giProbes` | `{active, reason, grids, probesPerFrame, budget}` for `gi` = `probes`: whether rays updated at least one probe in the last frame, why not when they did not (no `RealtimeGI` in the scene, no probe due, the device refused the kernel, no traced scene yet), the grids updated, the probes updated and the most the settings allow per frame. All zero and empty while `gi` is not `probes`. |
| `changed` | whether this call changed a setting. |

## Does this GPU trace rays? `render.supports`

Two rows of `render.supports` (the same answer as `Renderer::supports("raytracing")` in C++):

| row | true when | reason when false |
|---|---|---|
| `raytracing` | the device has **ray queries** and **acceleration structures** (Direct3D 12 with DXR 1.1, Vulkan with `VK_KHR_ray_query`, Metal on a GPU with ray tracing) and the engine's backend builds them | names the backend and what is missing: what the GPU, the driver or the OS lacks |
| `raytracingPipeline` | the GPU also has ray tracing **pipelines** and shader binding tables. **Reported only**: the engine traces with inline ray queries in compute shaders and never uses pipelines, so a GPU without them still traces | the same reason, or "no ray tracing pipelines" on a GPU with ray queries only |

Ask before you turn an effect on, and draw without it when the answer is false:

```js
const rt = fa.call("render.supports", { feature: "raytracing" });   // { feature, backend, supported, status }
if (!rt.supported) { /* keep the shadow maps and the screen-space effects */ }
```

## Shadows

`"shadows": "hard"` makes the shadow of the **directional light** with rays. It needs the light's `castShadows` on (the default is off, as
for the shadow maps) and a device that traces rays (the table below); the point, spot and area lights are traced too, three at most (below).

```
factoria call --no-graphics --project my_game render.ray_tracing '{"enabled":true,"shadows":"hard"}'
```

What the renderer does each frame, for the main camera:

1. The camera's prepass (depth and normals) is drawn as usual.
2. One compute pass, `rt-shadows`, casts **one ray per pixel** from the surface the pixel sees toward the sun and stops at the first
   triangle it finds. The ray starts a little in front of the surface (along the normal, more far away from the camera, so a distant
   pixel that covers more of the world does not shadow itself). It writes one image of the camera's size: the sun's visibility, 1 lit and 0 in shadow.
3. The lit pass reads that image instead of the cascaded shadow map for the sun. Where the image does not describe the pixel (the edge of a mesh, where the
   depth it stored differs from the depth being drawn, a sky pixel, a pixel of a **blended** (translucent) mesh or of a material with a **full shader**) the
   cascades answer, so a silhouette never shows a hole.

The cascaded shadow maps are still drawn: fog and light shafts, subsurface scattering and the local lights share the same atlas. So this
version does not save the cost of the cascades; it replaces what the sun's shadow looks like (no cascade seams, no map resolution) at the
cost of one ray per pixel and one image (RGBA32F, the size of the camera: 16 bytes a pixel, about 8.3 MB at 960 x 540).

What casts: every traced mesh whose `MeshRenderer.castShadows` is on (the scene's acceleration structures, "Which objects are traced"). A **blended**
(translucent) mesh casts a solid shadow, as it does in the shadow map. No caster loses its shadow ("Soft shadows", below).

### Soft shadows

`"shadows": "soft"` casts `raysPerPixel` rays (1 to 16) per pixel toward random points of the sun's disc, and a denoiser (a temporal accumulation
and a wavelet filter) makes the visibility smooth. The size of the disc is the scene setting `skySunSize` (the sun's angular diameter in degrees,
0.53 by default, the real sun, whatever the `skyModel`): the penumbra grows with the distance between the caster and the surface, so a real sun
gives a sharp shadow near the caster and a soft one far from it, and a bigger `skySunSize` gives a wider penumbra. Where a pixel is fully in the
shadow of the disc, the shadow is the hard one. The noise is deterministic: the same frame (same serial) gives the same image. The cost on top of
the hard shadow: `raysPerPixel` rays, a second image of the camera's size plus the denoiser's history images, and about eight small full-screen
passes. Hard shadows stay one ray and no denoiser.

**No caster loses its shadow.** The rays see the instances of the scene's acceleration structure. When a frame has a caster they cannot see or
test, the lit pass takes the darker of the ray traced shadow and the cascaded shadow map for the whole frame (the shadow maps are still drawn),
so that caster keeps its shadow; with none, the shadow is the ray traced one alone. The casters that count: terrain, impostors (a far tree drawn
as a card), meshes drawn from compute buffers, meshes left out by the instance cap, the skinning budget or a missing vertex buffer, meshes whose
acceleration structure is not built yet, and **cutouts** (alpha clip). A cutout is in the structure but the ray kernel cannot read its texture, so
its rays pass through it: its shadow is the cascade's, with the shadow map's resolution and edge, never a hole. The price of the rule is that in
such a frame the soft edge of every ray traced shadow is cut where the cascade is darker; to keep the full softness, avoid those casters or turn
their `castShadows` off.

**Point, spot and area lights.** With `shadows` on, the point, spot and area lights that have `castShadows` are traced too, **up to three per
camera and frame**: the most important ones (brightness, range and distance from the camera; a light keeps its slot while it stays among the
best, so the shadows do not flicker). The lights beyond the three keep their shadow maps, and a map no traced light needs is not drawn. In
`hard` every ray goes to the light's centre; in `soft` a point or spot light's rays spread over a cone as wide as the penumbra of its shadow
map (`shadowSoftness`) and an area light's rays go to points of its emitter, so its penumbra is the real one; a light with no softness is hard
in both. The result is denoised like the sun's. A caster the rays do not see (the list above) keeps its shadow from the map, as for the sun.
`render.ray_tracing` answers `localShadows` (`cap`, `candidates`, `traced`: the last frame) and its `reason` says it. A light with a full-shader
material, or a frame with a blended mesh, a decal, terrain, a transmissive or a subsurface draw still draws its maps (those draws read them), and so does
a traced light with `Light.volumetric` above 0 in a camera that draws the volumetric fog (the light shafts march through the maps); with the fog off or
`volumetric` 0 the map is skipped.
Design: docs/design/ARCHITECTURE_RT_SHADOWS.md (repository only, not in the binary).

**Without ray tracing.** On a device that cannot trace rays (OpenGL, OpenGL ES 3, WebGL2, Direct3D 11, or a GPU or OS without ray queries)
the setting changes nothing: the renderer logs **one** message that names the reason (the same one for every effect) and draws the shadow maps,
the frame it would draw with ray tracing off. If the device traces but cannot make the kernel or the image (or a driver rejects the compute pipeline), one more message says so, the sun keeps the
shadow maps, and `render.ray_tracing` answers `active: false` with that reason.
`render.supports {"feature":"raytracing"}` tells you before you turn it on.

**Cost.** Off: nothing, no pass, no image, no kernel. On: one compute dispatch of one ray per pixel, one image, plus what the acceleration
structures cost (P1s: every frame's TLAS build). The `drawCalls` of the stats count the dispatch.

Ray traced shadows are deterministic: the same frame gives the same image (a hard shadow uses no random number; the soft one draws its points from
the frame serial and the pixel, never a clock).

## Ambient occlusion

`"ao": true` darkens the creases, the contact between objects and the corners with rays instead of the screen-space effect (SSAO,
`PostProcess.ssaoEnabled`). It needs a device that traces rays (the table below) and works on the main camera, the one whose meshes are the
traced scene's.

```
factoria call --no-graphics --project my_game render.ray_tracing '{"enabled":true,"ao":true,"raysPerPixel":4}'
```

What the renderer does each frame:

1. From each pixel's surface, `raysPerPixel` rays (1 to 16) leave in a **cosine-weighted hemisphere** around its normal, each up to the occlusion
   radius, and stop at the first triangle they find. The pixel's visibility is the share of rays that got out: 1 open, 0 closed in.
2. The renderer's denoiser (temporal accumulation and an edge-aware filter) turns the noisy image into a clean one; one ray per pixel is enough for
   a still picture, more rays settle faster after a cut.
3. The picture is darkened where the occlusion is, after the opaque meshes and before glass, sprites, particles and the HUD, **exactly where the
   screen-space occlusion would darken it** and with the same strength: the radius and the intensity are the camera's
   `PostProcess.ssaoRadius` and `ssaoIntensity` when it has the effect on, else the component's defaults (0.5 m and 1). There is no second pair of
   controls: the same look with or without ray tracing. `PostProcess.ssaoQuality` is not used (the rays are `raysPerPixel`). The debug view `ao`
   shows the traced occlusion.

With `ao` on and a device that traces, the screen-space passes are not drawn. With `ao` on and a device that cannot trace, the log says why once
and the camera keeps its screen-space occlusion if it has one, and none otherwise. The same if the device traces but cannot make the kernel
(one message).

What occludes: opaque meshes and alpha-tested (cutout) ones. **A cutout occludes as a solid surface** in this version (the kernel does not read its
texture), so a leaf card or a fence darkens its whole triangle. Blended surfaces (glass, water) let the ambient light through.

Like the screen-space effect it multiplies the picture where it is drawn, so it darkens the direct light too, not only the ambient term. Off:
nothing, no pass, no image, no denoiser. On: one dispatch, one image and the denoiser's histories. The result is deterministic: the same frame
gives the same noise, and no clock or random number is read.

## Reflections

`"reflections": true` traces the reflection of the surfaces that are smooth enough to show one: a mirror ray for a sharp surface, a few rays
spread by the roughness for a glossy one. It needs a device that traces rays and a camera that draws the thin G-buffer (the prepass plus the
albedo, roughness and metalness images the engine makes for the screen-space effects; a device that cannot make them, or a frame that draws no
mesh, keeps the old reflections and the engine says so once).

```
factoria call --no-graphics --project my_game render.ray_tracing '{"enabled":true,"reflections":true,"raysPerPixel":4}'
```

What the renderer does each frame, for each camera that draws meshes:

1. One compute pass, `rt-reflections`, takes every pixel whose **roughness is under 0.65**. Under **0.25** it casts **one mirror ray** along the
   reflection of the view ray (the sharp path, as before). From 0.25 to 0.65 it casts **`raysPerPixel` rays** whose directions are drawn from the
   GGX distribution of the normals the camera sees (alpha = roughness squared), so the reflection is as blurred as the surface is rough; the
   draws are fixed by the pixel and the frame, so a frame renders the same twice. A pixel of the sky, a pixel with no G-buffer texel and a surface
   at 0.65 or rougher are not traced.
2. Where a ray ends on a mesh of the scene, the kernel shades that point: the sun (Lambert and GGX, with one shadow ray), the scene's ambient
   light, the environment's gradient seen by a mirror there, and the emission; an `unlit` mesh is its colour. A metal tints the reflection with
   its own colour. The rays of a pixel that hit are averaged; the rays that left the scene add nothing.
3. The glossy pixels are denoised, the sharp ones are not (a mirror has no noise, and a history would drag a reflection that moves differently
   from the surface). The denoiser keeps two signals of the camera, the radiance and the share of pixels whose rays hit, reprojects them to where
   the **reflected image** was (the point behind the mirror, not the surface), and filters only between pixels of a similar roughness.
4. The screen-space reflections' pass blends the result into the lit picture with the same Fresnel weight, so a reflection is as strong as
   the old one would have been. Where the traced reflection does not cover the pixel (the rays left the scene, or the roughness is between 0.5 and
   0.65, where the traced share fades out), the screen-space march runs for the rest and then what the lit pass drew (the probes and the
   environment); there is no seam at 0.25 or at 0.65. A camera with no screen-space reflections in its post stack still gets the pass, for the
   traced pixels only.

Everything else stays as it was: the sky, every pixel of roughness 0.65 or more, and the whole picture on a device that cannot trace.

Limits of this version, what a ray sees in a reflection: the **flat colour** of a material (no textures), a **faceted** normal (the mesh's
vertices are not available to the kernel), the **sun only** (no point or spot light, no second bounce, no fog), and a sky that is a material,
a physical sky or an HDRI appears as the plain gradient. A pixel whose rays only partly hit shows the hit colour at full weight (the share of
rays is not kept, only whether any hit), so a reflection's silhouette is a little harder than the exact one. A sharp ray that leaves the scene
now lets the screen-space march look for the reflection (before, the pixel kept the lit picture as it was).

**Cost.** Off: nothing, and no denoiser history. On: one compute dispatch (a ray per sharp pixel and `raysPerPixel` per glossy pixel, each with
three more rays at a hit: two parallel rays for the normal and one shadow ray), one image (RGBA32F, the camera's size), the denoiser's history
for two signals (four images each), plus the acceleration structures.

## Translucency

`"translucency": true` traces the light that goes **through** glass and liquids, instead of the screen-space refraction that bends the picture
behind them. It needs a device that traces rays and a camera that draws a transmissive mesh (a `MeshRenderer` with `transmission` above 0,
or a glTF part with `KHR_materials_transmission`); with no glass in view nothing is asked for.

```
factoria call --no-graphics --project my_game render.ray_tracing '{"enabled":true,"translucency":true}'
```

What the renderer does each frame, for a camera that draws glass:

1. One compute pass, `rt-translucency`, casts for every pixel one ray along the view ray as far as the opaque picture (the nearest surface of the
   scene that is not glass). If it meets a glass first, the ray is **bent by Snell's law** with the material's `ior` where it enters, goes through
   the **closed volume** and is bent again where it leaves (a total internal reflection stays inside), up to **six interfaces**. Inside, the light is
   tinted by **Beer-Lambert absorption** with `attenuationColor` and `attenuationDistance`; a surface with `thickness` 0 is a thin sheet that the ray
   passes straight through, unbent and untinted.
2. Where the ray ends on a surface, it takes that surface's colour from the picture the camera already drew, if the picture shows the same surface
   at the point (textures, lights and shadows included); otherwise the kernel shades the hit (the flat colour, the sun with one shadow ray, the
   ambient and the environment). A ray that leaves the scene sees the sky gradient.
3. A **rough** glass (`roughness` above 0) widens the bent ray into a cone, once, at the first interface: one sample per pixel and frame from a
   sequence that depends on the frame and the pixel only, so the same frame draws the same image. The glass's own shader averages a few neighbours
   (a box of up to 5 x 5 pixels, wider with the roughness): there is no denoiser for this effect.

Glass **casts a solid shadow** when `castShadows` is on (as the shadow map has always done) and a traced reflection sees glass as a solid surface
with its flat colour; the ambient occlusion ignores it. Coloured shadows are not made.

**Falls back, per pixel, to the screen-space refraction** (then the probes or the sky) where the kernel traced nothing: a device that cannot trace,
a pixel whose ray meets no glass, a camera that cannot make the refraction images, a mesh left out of the traced scene (terrain, impostors,
meshes over `maxInstances`, a mesh whose structure is not built yet). The engine warns once when the device refuses the kernel.

Limits of this version: the pixel shows the **nearest** glass surface along its ray (a second pane behind it is the screen-space blend over it);
two volumes inside one another are not nested; a shell thinner than 2 cm (the offset a ray starts at after an interface) is not refracted
correctly; where the ray meets an edge or a silhouette of the glass it passes unbent; a ray sees the flat colour, a faceted normal and the sun
only. **Cost:** off, nothing. On: one compute dispatch (a ray per pixel, and a few more per glass interface), one image (RGBA32F, the camera's
size) and the acceleration structures.

## Global illumination

`gi: "probes"` changes who updates the light probes of the scene's **`RealtimeGI`** grids (the grids that give indirect light and bounces to
everything lit; see the component's doc strings). Without it the engine captures six pictures of the scene from every probe with the
rasteriser; with it a compute shader with ray queries traces `raysPerProbe` rays from the probe (64 by default; 16 to 256 on the component) on
a sphere set that turns a little every update, shades what they hit with the sun, the emissive colours and the environment (a ray that leaves the
scene sees the sky), adds the light the grid's own probes already hold at the hit point (times the grid's `bounce`: the second, third... bounce
come from the following updates), and stores the result as the same nine spherical harmonics, depth moments and meta texel as before, blended
with the old value by the grid's `hysteresis`. The lit pass reads the grids as it always did, so nothing in your materials changes; what changes is
that an **emissive surface, a moving sun or a moved object** shows in the probes without any capture, and that the update cost is rays instead of
six scene renders.

```json
{ "render": { "rayTracing": { "enabled": true, "gi": "probes" } } }
```

- **Budget.** Each grid updates `rtProbesPerFrame` of its probes a frame (16 by default), the ones never updated first and then the ones updated
  longest ago; all grids together at most 64 probes a frame and at most the preset's `realtimeGiProbesPerFrame` (each frame starts one grid
  further, so many grids share the 64). A `raysPerProbe` or `rtProbesPerFrame` out of range is clamped. A grid of 400 probes at 16 a frame is complete after 25 frames, and `render.gi_grid`
  says it (`framesPerCycle`). The cost grows with probes x rays, never with the screen. (Probes near the camera are **not** updated first.)
- **Free when off.** With `enabled` or `gi` off, or no `RealtimeGI` in the scene, nothing is made: the frame is the raster one.
- **Fallbacks.** On a device that cannot trace rays, or when the device refuses the kernel, the grids keep updating with the raster captures
  and `render.ray_tracing` (`giProbes.reason`) says why. When the ray pass does not run (a refused kernel at once, or two frames in a
  row without a traced scene), the raster captures take over for 120 frames and the rays are tried again. A grid reports `updatedBy`: `"rays"` or `"captures"`.
- **What the rays see.** The traced scene of "Which objects are traced" (so no terrain, and a material's own shader is not evaluated); the
  meshes the main camera does not draw this frame are not in it.
- **Where it runs.** The Metal kernel is tested on a real GPU against a CPU ray caster; the D3D12 and Vulkan kernels are the same HLSL compiled
  by DXC and have not run on a device yet, and neither has their rule for which side of a triangle is its front (until it is measured they
  discard no probe inside a wall, which can leak light). docs/design/ARCHITECTURE_RT_GI.md (repository only) has the details.

## The path tracer

`render.pathTracer` is a **reference mode**: instead of the raster's lit colour, the main camera shows a progressive path trace of the same
scene, one random light path per pixel and frame, averaged over the frames while nothing changes. It is the picture to compare the raster
against ("is my lighting wrong, or only different from physics?"), and the way to get a clean image of a scene for a screenshot or a bug report.
It is **not a game mode**: one sample per pixel is noisy and a moving camera starts the image over every frame.

```
factoria call --no-graphics --project my_game render.path_tracer '{"enabled":true,"maxBounces":6}'
factoria call --project my_game render.pathtrace '{"samples":256,"path":"shots/reference.png"}'
```

It needs a device that traces rays (D3D12, Vulkan or Metal; `renderer.supports("raytracing")`), and asks for the scene's acceleration structures by
itself: `render.rayTracing.enabled` does not have to be on. Off (the default) it costs nothing.

```json
{ "render": { "pathTracer": { "enabled": true, "maxBounces": 4, "samplesPerFrame": 1, "maxSamples": 0,
                              "fireflyClamp": 0, "lights": true, "seed": 0 } } }
```

| key | values | default | meaning |
|---|---|---|---|
| `enabled` | `true`, `false` | `false` | The main camera shows the path traced colour. |
| `maxBounces` | 1 to 32 | `4` | The length of a path. 1 = direct light only (the sun and the lights, no bounce). More bounces add the light that bounces off walls, glass and mirrors; Russian roulette ends a dark path sooner. |
| `samplesPerFrame` | 1 to 64 | `1` | Paths per pixel each frame adds. More makes the picture converge in fewer frames at a slower frame rate. |
| `maxSamples` | 0 to 16777216 | `0` | The accumulation stops (and the GPU rests) after this many samples per pixel; `0` = never. |
| `fireflyClamp` | 0 or more | `0` | Clamps the brightness of one path to this value: fewer white dots, a little energy lost. `0` = off. |
| `lights` | `true`, `false` | `true` | Direct light from up to 8 point and spot lights of the frame. The sun is always sampled. |
| `seed` | 0 to 1073741824 | `0` | Changes the noise pattern. The same seed gives the same picture on the same device. |

A number outside its range is **clamped**; a wrong name or type is an error with the JSON pointer and a "did you mean", and nothing changes.

**What it draws.** The same BRDF as the raster (Lambert plus GGX), the sun with a shadow ray, up to 8 point and spot lights with one shadow ray each
(one of them per bounce, chosen at random), emission, the sky as the environment light plus the ambient, and **glass** that reflects and refracts (Fresnel,
Snell's law, the tint of `attenuationColor`). The pixels where the rays hit nothing keep the raster's sky, and a surface the raster draws and the rays
do not trace (terrain, impostors, meshes over `maxInstances`) stays as the raster drew it. The post stack and the tonemap apply to the result as to
the raster's picture.

**Progressive.** Every frame that nothing changes adds `samplesPerFrame` samples and the picture gets cleaner. It **starts over** when the camera
moves, the scene changes (an object moves, a light or material changes), a setting changes or the window is resized; `render.path_tracer` returns
`samples` so far, `resets` and `lastReset` (`start`, `image`, `camera`, `scene` or `settings`).

**`render.pathtrace`** renders the converged picture and writes it: `samples` (default 64), `scale` (the image size over the design size, 0.25 to 4),
`maxBounces`, `timeBudgetMs` (a safety net: stops early and returns `converged: false`) and `path`. It returns `{path, samples, converged, timeMs, device,
width, height, maxBounces}` and puts the settings and the render scale back as they were. On a device that cannot trace rays it fails with an error
that says to choose a backend that does, with `graphics.backend`. The same camera, scene, `seed` and `samples` give the same picture on a device. The
file is an **8-bit PNG, as the engine shows the picture (tonemapped)**: there is no EXR output yet.

**When to use which.**

| | raster (the default) | the other ray traced effects | the path tracer |
|---|---|---|---|
| for | playing, every device | the same game with better shadows, reflections, occlusion, glass | judging the lighting, reference screenshots |
| frame cost | the lowest | one dispatch per effect | many rays per pixel, and many frames for a clean picture |
| indirect light | the ambient and the probes | the effects' own | traced: bounces off every surface |
| textures, normal maps, custom materials | yes | partly | **no** |

Limits of this version: the rays see the `MeshRenderer`'s flat colour, roughness and metallic, **not its textures, normal maps or custom
materials**, so a textured scene looks flatter than the raster's, and a white-albedo scene looks brighter; the sun's shadow is hard (no penumbra from
`shadowSoftness`); an area light is a point light at its centre and only the 8 strongest point and spot lights are sampled; the ambient colour lights every
escaped ray equally, as a dome; the raster glass is drawn again over the path traced picture; `render.pathtrace` cannot run from inside a frame (a
script callback). On a wall seen almost edge on, the check that drops a path traced pixel behind a raster surface can keep the raster's pixel for a
thin line. The kernel is described in docs/design/ARCHITECTURE_RT_PATHTRACER.md (repository only, not in the binary).

## Where it will run

| backend | traces rays | what stands in the way today |
|---|---|---|
| Direct3D 12 (Windows) | on a GPU with DXR tier 1.1 and shader model 6.5, or a WARP (the software device) that has them, as the Windows 11 development PC's does (an older Windows' WARP has no tier 1.1): the backend builds acceleration structures and runs inline ray queries in compute shaders; the shadow kernel (`shadows: "hard"`) traces | an older GPU or driver: `render.supports` names the adapter, its DXR tier and its shader model |
| Vulkan (Windows, Linux, Android) | yes, on a GPU with `VK_KHR_acceleration_structure`, `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` and `bufferDeviceAddress` (the hard shadows trace) | a GPU or driver without them: `render.supports` names what this GPU lacks (Mesa's lavapipe, the CPU driver, lists them from Mesa 24.1 according to its release notes, and the engine's CI tests on Mesa 25.2's; MoltenVK on a Mac has none) |
| Metal (macOS 13+, iOS 16+) | **yes**, on a GPU with Metal ray tracing (`MTLDevice.supportsRaytracing` is true) | an older GPU, an older OS or the iOS simulator: `render.supports` names the GPU and the OS version and what Metal needs. The shadows (`shadows: "hard"`, `"soft"`), the ambient occlusion (`ao`), the reflections (`reflections`), the translucency and the GI probes (`gi: "probes"`) trace; `gi: "perPixel"` does not yet |
| Direct3D 11, OpenGL, OpenGL ES 3, WebGL2 | never | the API cannot trace rays; the answer says to use the d3d12 or vulkan backend (Windows, Linux, Android) or Metal on Apple |
| headless (`--no-graphics`) | no | there is no GPU |

Every effect has a fallback that does not need rays (the shadow maps, the screen-space occlusion and reflections, the light probes), so a
game that turns ray tracing on still looks right on a GPU that cannot do it; only the effects that need rays are missing.

## Which objects are traced, and the instance cap

When rays are asked for (see above) on a device that traces, the renderer builds one bottom-level structure per **submesh** of every mesh
the main camera draws (once per mesh asset, shared by all its instances, compacted a frame or two later, freed when the mesh goes) and
rebuilds the top-level structure every frame with one instance per drawn submesh. Meshes you draw with `MeshRenderer`, instanced
batches and the instances of a `Foliage` are traced, one level of detail per instance (the level the main camera sees). **Skinned meshes**
(an `Animator`) are traced in the pose they are drawn in: a compute pass skins each one into its own structure, which is refitted every frame
and rebuilt every 60 frames or when a bone jumps (the scene skins at most 4096 instances and 4194304 vertices a frame, the nearest to the
main camera first; the log says once what was left out and how to fix it). Not traced:

- **terrain** (`Terrain` nodes);
- **impostors**: while a far tree is drawn as a card it is left out (it casts no ray-traced shadow and is not in a reflection);
- the level of a LOD cross-fade that is fading out, and meshes drawn from compute buffers (a material with GPU buffers);
- meshes that are still loading (the placeholder).

**The cap.** The structure holds at most `render.rayTracing.maxInstances` instances (and no more than the GPU allows, which the log
names when it is the lower). One mesh with three submeshes is three instances. When the scene has more, the **nearest to the main
camera** are kept and the log says once how many were left out and which setting to raise; the ones left out cast no ray-traced shadow
and are in no reflection. Raise `maxInstances` (up to 1048576) or draw fewer objects.

A custom material (`material`) is not evaluated by the rays: they see the `MeshRenderer`'s colour, roughness and metallic. A cutout
(alpha clip) is traced as a cutout, never as a solid. A GPU that cannot trace rays logs one message with the reason and nothing is built.

## How the renderer will use it

The design (docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, repository only, not in the binary) is **inline ray query only**: a compute pass binds one top-level
acceleration structure (a **TLAS**: one instance of a bottom-level structure, a **BLAS**, per mesh in the scene, each with its transform)
and the compute shader of each effect casts its rays and shades the hit itself. There are no ray tracing pipelines, no shader binding
tables and no hit shaders, so one kernel runs unchanged on Direct3D 12, Vulkan and Metal.

The renderer builds one BLAS per submesh, rebuilds the TLAS every frame (capped by `maxInstances`, nearest first), and adds the
effects' compute passes to the frame graph only when `enabled` and an effect
are on. With the master switch off no acceleration structure exists and the frame graph has the same passes as before. Every effect
shares one scaffold (docs/design/ARCHITECTURE_RT_EFFECTS.md, repository only): the hard shadows are the first effect on it and the ambient occlusion the second. The GI probes have their own kernel and pass (docs/design/ARCHITECTURE_RT_GI.md, repository only).

## For engine developers

The calls the backends will implement (all optional: a device without `Features::accelerationStructure` refuses every one with a reason):

- `Device::blas_sizes`, `tlas_sizes`: the memory a structure and its builds need, before anything is made.
- `Device::make_accel_structure`, `destroy_accel_structure`, `accel_structure_state`.
- `CommandList::build_blas`, `build_tlas` (full builds and refits), `query_compacted_size`, `copy_accel_structure` (compaction and clone).
- `Bindings::accelStructures` binds a TLAS to a compute shader that declares it (`ShaderDesc::usesRayQuery`, `accelStructures`).
- The `RecordingDevice` made with `DeviceInit::recordingRayTracing` records every call and checks it (a TLAS over a destroyed BLAS, a
  scratch buffer that is too small, a refit of a structure built without `allowUpdate`, too many geometries, a BLAS bound where a ray
  query needs a TLAS), so the code that builds structures is tested without a GPU.

The full description, with the barrier rules, the sizes and the route Metal takes, is in docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md (repository only, not in the binary).

## The lightmap bake on the GPU (M79-P5b)

`lightmap.bake` with `device: "gpu"` (or `"auto"`) uses the same ray queries to trace the texels of a lightmap: a compute kernel (`rt_bake`)
over an acceleration structure of the bake's own scene. It is a fast preview, tolerance-bound against the CPU baker, and it needs a GPU
that traces rays (`render.supports("raytracing")`); see [Baking](rendering/RENDERING_LIGHTMAPS.md) and
docs/design/ARCHITECTURE_BAKING.md, repository only, not in the binary, "The GPU bake". It does not depend on the renderer's `render.rayTracing` settings.
