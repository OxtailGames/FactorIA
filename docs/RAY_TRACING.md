# Ray tracing (M79)

Ray tracing lets the renderer ask the scene questions that the shadow maps and the screen-space effects only approximate: "is there
something between this point and the light?", "what does this mirror reflect?", "how much of the sky does this corner see?". The GPU
answers with a **ray query** inside a compute shader, against **acceleration structures** it builds from the scene's meshes. It is off by
default, and free when off.

> **What exists today.** Milestone 79 brings ray tracing one piece at a time. This version has the **shared interface**: the
> settings below, the `raytracing` rows of `render.supports`, the command `render.ray_tracing`, and the acceleration structure calls of
> the GPU interface (`engine/render/src/gpu/`; docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md describes it, repository only, not in the binary).
> The Direct3D 12 backend builds acceleration structures on a GPU with DXR tier 1.1 (the table below). **No effect draws with rays yet**: turning the settings on changes nothing in the picture, and
> `render.ray_tracing` says so (`active` is false, with the reason). The sections below say what each part will do and mark what is
> planned.

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
| `shadows` | `off`, `hard`, `soft` | `off` | `off` = the shadow maps of the lighting. `hard` = one ray per light towards its centre (a sharp edge). `soft` = rays towards a point of the light's disc: the edge softens with the distance to the caster. |
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
| `active` | whether any effect is traced right now. **Always false in this version.** |
| `reason` | empty while `enabled` is false; otherwise why nothing is traced (the device's reason, or that this version has the interface only). |
| `changed` | whether this call changed a setting. |

## Does this GPU trace rays? `render.supports`

Two rows of `render.supports` (the same answer as `Renderer::supports("raytracing")` in C++):

| row | true when | reason when false |
|---|---|---|
| `raytracing` | the device has **ray queries** and **acceleration structures** (Direct3D 12 with DXR 1.1, Vulkan with `VK_KHR_ray_query`, Metal on a GPU with ray tracing) and the engine's backend builds them | names the backend and what is missing: the package that will bring it, or what the GPU lacks |
| `raytracingPipeline` | the GPU also has ray tracing **pipelines** and shader binding tables. **Reported only**: the engine traces with inline ray queries in compute shaders and never uses pipelines, so a GPU without them still traces | the same reason, or "no ray tracing pipelines" on a GPU with ray queries only |

Ask before you turn an effect on, and draw without it when the answer is false:

```js
const rt = fa.call("render.supports", { feature: "raytracing" });   // { feature, backend, supported, status }
if (!rt.supported) { /* keep the shadow maps and the screen-space effects */ }
```

## Where it will run

| backend | traces rays | what stands in the way today |
|---|---|---|
| Direct3D 12 (Windows) | on a GPU with DXR tier 1.1 and shader model 6.5, or a WARP (the software device) that has them, as the Windows 11 development PC's does (an older Windows' WARP has no tier 1.1): the backend builds acceleration structures and runs inline ray queries in compute shaders; no effect traces yet | an older GPU or driver: `render.supports` names the adapter, its DXR tier and its shader model |
| Vulkan (Windows, Linux, Android) | yes, on a GPU with `VK_KHR_acceleration_structure`, `VK_KHR_ray_query`, `VK_KHR_deferred_host_operations` and `bufferDeviceAddress` (no effect traces yet) | a GPU or driver without them: `render.supports` names what this GPU lacks (Mesa's lavapipe, the CPU driver, has them from Mesa 24.1, and the engine's CI tests on Mesa 25.2's; MoltenVK on a Mac has none) |
| Metal (macOS, iOS) | planned (Metal ray tracing, `intersector`) | not built yet: "package P1m of milestone 79" |
| Direct3D 11, OpenGL, OpenGL ES 3, WebGL2 | never | the API cannot trace rays; the answer says to use the d3d12 or vulkan backend (Windows, Linux, Android) or Metal on Apple |
| headless (`--no-graphics`) | no | there is no GPU |

Every effect has a fallback that does not need rays (the shadow maps, the screen-space occlusion and reflections, the light probes), so a
game that turns ray tracing on still looks right on a GPU that cannot do it; only the effects that need rays are missing.

## How the renderer will use it

The design (docs/design/ARCHITECTURE_RENDERING_RAYTRACING.md, repository only, not in the binary) is **inline ray query only**: a compute pass binds one top-level
acceleration structure (a **TLAS**: one instance of a bottom-level structure, a **BLAS**, per mesh in the scene, each with its transform)
and the compute shader of each effect casts its rays and shades the hit itself. There are no ray tracing pipelines, no shader binding
tables and no hit shaders, so one kernel runs unchanged on Direct3D 12, Vulkan and Metal.

The renderer will build one BLAS per mesh when the mesh loads, rebuild the TLAS when instances move or appear (instances are re-sorted
nearest-first and capped by `maxInstances`), and add the effects' compute passes to the frame graph only when `enabled` and an effect
are on. With the master switch off no acceleration structure exists and the frame graph has the same passes as before.

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
