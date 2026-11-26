# Rendering, the thin G-buffer (M79-P0c)

Part of [ARCHITECTURE.md](ARCHITECTURE.md) (rendering: [ARCHITECTURE_RENDERING.md](ARCHITECTURE_RENDERING.md); the depth and normal
prepass it follows: "Prepass" on [ARCHITECTURE_RENDERING_POST.md](ARCHITECTURE_RENDERING_POST.md); the velocity image next to it:
[ARCHITECTURE_RENDERING_TEMPORAL.md](ARCHITECTURE_RENDERING_TEMPORAL.md)). The engine stays a forward renderer: the main pass lights every
mesh as it draws it. The thin G-buffer is two small images of what the camera sees, the albedo and the material, that a few consumers read
(the guides of DLSS Ray Reconstruction today, the ray-traced passes of M79 next, two debug views). It is not a deferred renderer: nothing
lights from it.

## Decision D6: off costs nothing

The images exist only when something asks for them. With nothing asking, the frame is the frame without this feature, byte for byte:
the same passes in the same order, no extra target, no extra memory, no extra shader variant (the programs are built on the first request,
never at start), and the existing programs are the ones that were there. A test checks the pass list and the picture
(`engine/render/tests/gbuffer_tests.cpp`, "off - no pass in the frame graph and the same picture, bit for bit").

## What it holds

Two RGBA8 images of the size of the prepass (the render size of the camera's rectangle), cleared to zero each frame:

| Image | r | g | b | a |
|---|---|---|---|---|
| albedo (colour 0) | albedo red | albedo green | albedo blue | 1 where an opaque mesh was drawn, else 0 |
| material (colour 1) | roughness (0.05 to 1) | metalness (0 to 1) | 0 (spare) | 1 where an opaque mesh was drawn, else 0 |

The albedo is the surface's base colour in **linear** colour (the mesh renderer's colour times the base texture and the vertex colour),
clamped to 0..1. A metal's base colour is its albedo here too: the consumer derives what it needs (the Ray Reconstruction pass makes the
diffuse albedo `albedo * (1 - metalness)` and the specular albedo `mix(0.04, albedo, metalness)`). RGBA8 holds the 8-bit quantisation of
those values, which is below what a 0..1 material parameter needs, and every GPU the renderer runs on renders to it with two attachments
(`Gpu::gbuffer_format()`, `Gpu::gbuffer_target_format()` = `{Rgba8, Depth, samples 1, Rgba8}`). The alpha channel is the truth about coverage
(a pixel with alpha 0 holds "nothing drawn": the consumer uses its constants), exactly as the prepass image's alpha is.

## Why a separate pass

`fa::gpu` has two colour attachments per pass; the prepass already uses both (view depth and normal, motion vector). A third output
would have needed a wider interface on every backend (D3D12, Vulkan, the sokol ones). So the G-buffer is a pass of its own after the
prepass (`"gbuffer"`, `Renderer::Impl::gbuffer_pass` in `src/renderer_draw.cpp`): it draws the opaque batches again with the same
vertex stage, instances, skins and uniforms as the prepass, and a fragment stage that runs the **surface of the main pass**
(`fa_standard_surface` plus `surface()`), then writes the two images instead of lighting. The cost is one more draw per opaque batch at the
render size, paid only on a frame that asked.

The pass declares the prepass as a read and the two images as writes; it is a side-effect pass (never culled when its images are made). The
effects that read the images list it through the resources (`PostPlan::gbufferAlbedo`, `PostPlan::gbufferMaterial`, both `PrepassRef`).
Both are invalid when nothing asked or the frame made no G-buffer; a consumer then reads its constants.

## The request

Like the velocity image: a private renderer request, never a project setting.

- `PostPlan::request_gbuffer()` sets `needsGbuffer`. The requesters are the debug views `albedo` and `material`
  (`render.debug_view`, `Renderer::set_debug_view`), DLSS Ray Reconstruction while it is on (a perspective camera drawn through the
  temporal path, the machine's probe available, no earlier failure), and the test hook `RendererTestAccess::force_gbuffer`.
- `plan_prepass` turns a request into a prepass (the G-buffer needs it: the visibility test below reads it), tries to make the two
  transient images (and hands them straight back to the pool, so a GPU that refuses them is one logged error, not a failed pass) and
  sets `DrawContext::doGbuffer`. `Gpu::gbuffer_ready()` builds the programs on the first request and logs one teaching error when the GPU
  cannot render RGBA8 with two attachments or a shader does not compile on this backend.
- `build_graph` declares the pass after the prepass block and sets the two refs. Without `doGbuffer` nothing is declared.
- A camera that draws into a texture, a CameraView and a realtime GI capture never make one (like the prepass).

## What each kind of draw writes

| Draw | Program | Written |
|---|---|---|
| opaque mesh, alpha-tested mesh, LOD levels, instances, foliage, skinned mesh | `mesh_gbuffer`, `mesh_gbuffer_skin` (`@program gbuffer`, `gbuffer_skin` in `mesh.glsl`), fragment stage `gbuffer_fs` | the surface's albedo, roughness and metalness; the mesh's own base colour and the textures of its glTF parts |
| custom (M72) and layered (M73) material on a mesh renderer | the engine's own `gbuffer` program | **documented default**: the mesh renderer's own colour, roughness and metallic and the textures of its glTF parts. The material's `surface()` is not run |
| terrain nodes | `terrain_gbuffer` (`gbuffer_fs_plain`), built on the first terrain draw | the blended splat layers' albedo, roughness and metallic |
| impostor cards | `impostor_gbuffer` (`gbuffer_fs_plain`), built on the first impostor draw | the card's albedo, the impostor's roughness, metalness 0 |
| sprites, tiles, shapes, text (2D), blended and additive meshes, particles | none | nothing: alpha 0 (the consumer's constants) |
| a mesh the engine's program cannot place (GPU-placed buffers: `MeshBuffers` active) and a full-shader (M72) material with no prepass program | none | nothing: the clear value |

A custom material that runs its own `surface()` is the one case where the G-buffer does not hold what the main pass shows: a game that
wants its custom albedo in the G-buffer sets the mesh renderer's colour, roughness and metallic to the same values. The default keeps
the contract simple (the mesh programs of a material twin are not touched, so no twin has to be made again for this feature) and the
cutout, vertex displacement and cross-fade of such a material still apply, because they are in the prepass the G-buffer is tested
against.

### The visibility test

A mesh fragment that is not the surface the prepass kept at its pixel is dropped. The `gbuffer_fs` program (`FA_GBUFFER` and
`FA_GBUFFER_VIS` of `mesh_common.glsl`, `fa_prepass_fs_main`) reads the prepass image of the same pixel, bound at the screen texture slot
with the Nearest sampler of the shadow, and drops the fragment when the prepass wrote nothing there or its view depth differs by more
than `0.02 + 0.01 * depth`. That one test gives the alpha-tested holes (the prepass cut them), the LOD cross-fade dither (the prepass
used the same hash), occlusion culling and the meshes behind other meshes (only the front surface stays) without another depth buffer.
Terrain and impostors use `gbuffer_fs_plain`: no test (they are opaque by construction and their fragment stage has no room for another
texture).

## Consumers

- **DLSS Ray Reconstruction** (`Renderer::Impl::run_rr_guides`, `shaders/upscale_rr.glsl`): the roughness of the normal-and-roughness
  guide comes from the material image, and a second pass (`upscale-rr-albedo`, program `rr_albedo`) turns both images into the diffuse
  and the specular albedo guides. A pixel with alpha 0 (no mesh) and a frame with no G-buffer (the GPU refused, or its size is not the
  render size: a camera of a split screen) keep the constants of M78 (roughness 0.5, diffuse 0.5, specular 0.04). The tests of the vendor
  runtime (a fake Streamline) stay as they were; `RendererTestAccess::rr_guide_programs` builds both guide programs on any GPU.
- **Debug views** `albedo` and `material` (`prepass_view.glsl` modes 5 and 6): the albedo's rgb, and the material as red = roughness,
  green = metalness; black where nothing was drawn.
- **Screen-space reflections** do not read it: their look does not change (the SSR comment in `src/renderer_ssr.h` says so).

## Tests

`engine/render/tests/gbuffer_tests.cpp`, on the GPU of the test process (OpenGL, Metal, D3D11, Vulkan, D3D12 as the suite runs):

- the plan: the request is off by default, the format is `Rgba8` with a depth and a second `Rgba8` colour;
- off: no `gbuffer` pass, no readable image, and the same picture as with the request on, bit for bit; on: the pass comes after the prepass;
- known values: a white cube (roughness 0.3, metallic 0) and a red one (roughness 0.8, metallic 1) read back through
  `RendererTestAccess::read_gbuffer` (the images copied to RGBA16F by `kPrepassViewRaw4`, mode 7 of `prepass_view.glsl`), within 0.02;
  the sky between them has alpha 0;
- the debug views show the same values;
- an `alphaMode` clip material leaves its holes in both images, and writes the mesh renderer's own values (the documented default);
- a scene with no opaque mesh makes no G-buffer;
- the Ray Reconstruction guide programs (the albedo one included) build.

## Not done

Two things the P0c images do not do yet: blended and additive meshes write nothing (a ray-traced pass sees them as the sky); the
terrain and the impostors write the texture layers' values but not a normal (the normal is the prepass's). The ray-traced passes of M79 that
need more (the normal, the position) read the prepass next to these two images.
