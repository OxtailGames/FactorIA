# Ray tracing (M79)

Ray tracing lets the renderer ask the scene questions that the shadow maps and the screen-space effects only approximate: "is there
something between this point and the light?", "what does this mirror reflect?", "how much of the sky does this corner see?". The GPU
answers with a **ray query** inside a compute shader, against **acceleration structures** it builds from the scene's meshes. It is off by
default, and free when off.

> **What exists today.** Milestone 79 brings ray tracing one piece at a time. This version has the **shared interface**: the
> settings below, the `raytracing` rows of `render.supports`, the command `render.ray_tracing`, and the acceleration structure calls of
> the GPU interface (`engine/render/src/gpu/`; docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md describes it, repository only, not in the binary).
> The Direct3D 12, Vulkan and Metal backends build acceleration structures and run inline ray queries on a GPU that has them (the table below).
> **One effect draws with rays so far: `shadows: "hard"`** (the sun's shadow, "Shadows", below). The other settings (`ao`, `reflections`,
> `translucency`, `gi`) change nothing in the picture yet, and `render.ray_tracing` says what is traced (`active`, with the reason). The
> sections below say what each part will do and mark what is planned.
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
| `shadows` | `off`, `hard`, `soft` | `off` | `off` = the shadow maps of the lighting. `hard` = one ray per pixel towards the sun, the shadow of the directional light that has `castShadows` (a sharp edge; "Shadows", below). `soft` = `raysPerPixel` rays towards points of the sun's disc, denoised (the edge softens with the distance to the caster; "Soft shadows", below). |
| `ao` | `true`, `false` | `false` | Ambient occlusion traced with rays, instead of the screen-space one. |
| `reflections` | `true`, `false` | `false` | Mirror and glossy reflections traced with rays, instead of the screen-space ones. |
| `translucency` | `true`, `false` | `false` | Light through glass and thin surfaces (refraction and coloured shadows). |
| `gi` | `off`, `probes`, `perPixel` | `off` | Global illumination. `off` = the engine's own (light probes and the ambient). `probes` = light probes updated with rays. `perPixel` = a bounce traced for every pixel (the most expensive). |
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
| `active` | whether an effect that draws with rays is on and the device traces: in this version `enabled` with `shadows` other than `off` on a device that can trace. It does not look at the scene: a scene with no directional light that casts shadows has nothing to trace (see "Shadows"). |
| `reason` | empty while `enabled` is false; otherwise what is traced, or why nothing is (the device's reason, or that no effect that draws with rays is on). |
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
for the shadow maps) and a device that traces rays (the table below); the other lights, point, spot and area, keep their shadow maps.

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

**Lights other than the sun.** Point, spot and area lights keep their raster shadow maps in every mode; the rays are for the directional light.

**Without ray tracing.** On a device that cannot trace rays (OpenGL, OpenGL ES 3, WebGL2, Direct3D 11, or a GPU or OS without ray queries)
the setting changes nothing: the renderer logs **one** message that names the reason (the same one for every effect) and draws the shadow maps,
the frame it would draw with ray tracing off. If the device traces but cannot make the kernel or the image (or a driver rejects the compute pipeline), one more message says so, the sun keeps the
shadow maps, and `render.ray_tracing` answers `active: false` with that reason.
`render.supports {"feature":"raytracing"}` tells you before you turn it on.

**Cost.** Off: nothing, no pass, no image, no kernel. On: one compute dispatch of one ray per pixel, one image, plus what the acceleration
structures cost (P1s: every frame's TLAS build). The `drawCalls` of the stats count the dispatch.

Ray traced shadows are deterministic: the same frame gives the same image (a hard shadow uses no random number; the soft one draws its points from
the frame serial and the pixel, never a clock).

## Where it will run

| backend | traces rays | what stands in the way today |
|---|---|---|
| Direct3D 12 (Windows) | on a GPU with DXR tier 1.1 and shader model 6.5, or a WARP (the software device) that has them, as the Windows 11 development PC's does (an older Windows' WARP has no tier 1.1): the backend builds acceleration structures and runs inline ray queries in compute shaders; the shadow kernel (`shadows: "hard"`) traces | an older GPU or driver: `render.supports` names the adapter, its DXR tier and its shader model |
| Vulkan (Windows, Linux, Android) | yes, on a GPU with `VK_KHR_acceleration_structure`, `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` and `bufferDeviceAddress` (the hard shadows trace) | a GPU or driver without them: `render.supports` names what this GPU lacks (Mesa's lavapipe, the CPU driver, has them from Mesa 24.1, and the engine's CI tests on Mesa 25.2's; MoltenVK on a Mac has none) |
| Metal (macOS 13+, iOS 16+) | **yes**, on a GPU with Metal ray tracing (`MTLDevice.supportsRaytracing` is true) | an older GPU, an older OS or the iOS simulator: `render.supports` names the GPU and the OS version and what Metal needs. The hard shadows (`shadows: "hard"`) trace; no other effect does yet |
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
shares one scaffold (docs/design/ARCHITECTURE_RT_EFFECTS.md, repository only): the hard shadows are the first effect on it.

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
