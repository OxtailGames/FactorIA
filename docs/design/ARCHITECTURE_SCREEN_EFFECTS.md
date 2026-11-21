# Screen-space effects of the mesh shader

Part of the architecture documentation ([entry page](ARCHITECTURE.md)). The lighting of M73 is described in
[ARCHITECTURE_RENDERING_LIGHTING.md](ARCHITECTURE_RENDERING_LIGHTING.md); this page holds what the mesh fragment shader reads from the
frame's own screen, which is two things: the contact shadows and the opaque colour that glass refracts (M73.6b).

## The screen slot (view 28)

`fa_screen_tex` is view 28 of the mesh fragment shader (`kMeshFragmentViews`, `render_internal.h`; phases 1 and 2). It is read with
`texelFetch` through the nearest sampler 1, like the light data texture: an RGBA32F or RGBA16F prepass is an `unfilterable_float`
image, which the filtering sampler 10 cannot be paired with. A later reader that wants bilinear filtering (the opaque colour of
transmission, below) filters by hand.

What the slot holds depends on the phase of the draw (`bind_textures(..., shadowPass, opaquePhase)` in `renderer_draw.cpp`):

| Draw | View 28 |
|---|---|
| the opaque phase of the main pass, the frame has a contact shadow | the depth prepass of the frame (`ctx.screenView`): r = linear view depth, gb = octahedral normal, a = 1 on an opaque mesh, 0 on the sky |
| the blended phase of a frame with a visible transmissive draw | the refraction atlas (below): the opaque picture and its reduced copies, a colour image |
| every other draw (the shadow passes, the blended phase of any other frame, a frame with no contact shadow) | the white placeholder image: the unit is always bound, the program never reads it |

The prepass is the one the post-processing effects that need depth already draw (`PostPlan::prepass`, described under the depth outline in ARCHITECTURE_RENDERING_POST.md); a frame
with contact shadows and no other user of it draws it for them (`postPlan.needsDepth`), and the main pass lists it among its reads in
the frame graph. It is never multisampled and has the camera's pixel size (`ctx.camPx`), so a fragment of the main pass reads the
prepass at its own pixel. The prepass holds the opaque meshes only: no blended draw, so a blended mesh is not a caster; and the draws of
the blended phase (which includes the transmissive ones of M73.6b, whose slot holds the opaque colour) take no contact shadow.

## Contact shadows (M73.2c)

**Data.** `Light.contactShadowLength` (metres, clamped 0..10) becomes `LightData::contactLength` in `collect_lights`, but only when
`SceneSettings.contactShadows` is on. It lives in the light data texture (view 24), in the shadow region, which holds one texel per light
at `fa_shadow_lcfg.x - 1 + li` (`light_data.glsl`, "the shadow region"): x = the record of the light's shadow tiles or -1, y = the
contact length, zw free. The region is also written, with every x = -1, in a frame where a light asks for a contact shadow and none has a
shadow map. The length is NOT a member of the light's own texels: their number per light (the stride, 4 or 8) is the light table's
business (`fa_light_base(li)`), and the region is indexed by the light, not by its place in the table.

**Plan.** `plan_job` (`renderer_draw.cpp`) sets `wantContact` when a light of the frame has a length, asks for the prepass, and sets
`ctx.contactOn` only when the prepass is really drawn (a GPU that cannot sample the depth does not). When it is not, every length is
zeroed again, so the shader branch, the stat and the data agree. `stats.contactShadowLights` counts the lights with a length of a frame
with `contactOn`, summed over the frame's camera jobs (a light seen by two cameras counts twice). `render.supports` `contactShadows` needs `depth`, like the effects that read the prepass.

**Shader.** The block `fa_contact` of `light_loop.glsl` has one function, `fa_contact_shadow(li, world, gn, l, dist)`, called from
`fa_light_shadowed` (the engine's loop and `fa_light()` of a custom lighting) and from `fa_light_shadow` of the lighting API, each only
when `fa_ct_a.x` is above 0.5, a uniform: a draw without contact shadows (a blended mesh, `receiveShadows` off, a full-shader material,
a frame without the prepass, or a pass that runs before the main pass has set `ctx.screenView`: the shadow and prepass passes) pays one branch per light. The flag needs `ctx.screenView.id`, and the texel read is clamped to the size of the prepass. Inside, a light without a length returns at its texel fetch. The result
multiplies into the light's shadow term (`ls.shadow` and `ls.color`, so a snippet's `light()` sees it), so a light with no shadow map
has one too. A directional light's distance is passed as 1e9; a point or spot light's is its distance, and the ray never goes beyond 0.9 of
it; an area light is marched toward `ls.direction`, the point of its emitter its light comes from, over `ls.distance`.

The march: 12 steps, each at `(k + jitter) / 12` of the length, with `jitter` the interleaved gradient noise of the pixel
(`fa_shadow_noise()`: the same in every frame, so a still picture does not shimmer). A step is projected to the screen with the three rows
of the camera's view-projection matrix that the CPU hands over (`fa_ct_vpx`, `fa_ct_vpy`, `fa_ct_vpw`; no inverse matrix and no
window-convention guess, as the cluster lookup does), `fa_ct_a.y` flips the vertical for the backends whose texture rows run the other way
(D3D11, Metal against GL), and `fa_ct_a.zw` is the prepass size in pixels. The depth of the step along the camera's forward axis
(`fa_ct_fwd`) is compared with the prepass's linear depth: the ray is blocked when the step is behind the surface by more than a bias
(0.005 m plus 0.003 times the distance from the camera, about a pixel of the prepass) and less than a thickness (the bias plus half the
ray length; a thicker thing is taken for something the ray passes behind). The occlusion is `(1 - f^2)` along the ray (`f` 0..1), times
a smoothstep over the last 5% of the screen's edge (what hides the ray may be off screen), and the whole effect fades with the distance
from the camera (`kContactShadowFadeEnd` = 40 m, from 20 m on). A step that leaves the screen or the camera's front ends the march. The
ray starts at the point moved by the bias along the geometric normal.

**Off is free and exact.** With the master switch off, with no length or with the prepass not drawn, `fa_ct_a.x` is 0 in every draw, the
light texel's y is 0, and nothing in the frame differs from the frame of a build without the feature (a test compares the pixels). The
GLES3 / WebGL2 rules hold: highp floats, no constant arrays, loops with a constant bound.

**Limits** (user-facing text in `docs/rendering/RENDERING_LIGHTING.md`, "Contact shadows"): only what the camera sees casts; thin
objects let the light through; the transmissive and blended draws, full-shader materials and meshes with `receiveShadows` off have none.
M73.6b, which reads the opaque colour in this slot for the transmissive draws, must read it with `texelFetch` (any mip) and filter by hand.

Tests: `engine/render/tests/contact_shadow_render_tests.cpp` (a box on a floor under a grazing sun: on against off, off bit for bit, a
still picture, a longer ray, a point and an area light), `render3d_tests.cpp` (a custom `light()` receives it; the slot of a material's
program), `mesh_slots_tests.cpp` (the slot table), `light_clusters_tests.cpp` (the region's texels), `postprocess_resolve_tests.cpp`
(the feature row).

## Transmission and volume (M73.6b)

User page: [RENDERING_TRANSMISSION.md](../rendering/RENDERING_TRANSMISSION.md). Code: `renderer_xmit.{h,cpp}` (the atlas), `shaders/xmit.glsl` (the copy and
the reductions), `fa_transmission` in `shaders/brdf_layers.glsl` (the read), `plan_transmission` and the main pass in `renderer_draw.cpp`,
`material_cost.cpp` (the cost view).

**Which draws are transmissive.** `mesh_is_transmissive(mr, mesh, material)` (`render_scene.h`): the MeshRenderer's `transmission` or any part's layer is above 0
and the material is not a full shader. Such a mesh is also `mesh_is_blended`, so it goes to the blended phase and nowhere else; its pipeline is the blended one
with back faces culled (`glass`, unless `doubleSided`), because a blended pipeline culls nothing and the inner wall of a closed glass would refract over its front.

**The split.** `plan_transmission` runs once per camera after the visible draws are known: if one is transmissive (`stats.transmissiveMeshes` counts them) and
`Xmit::can_make` says the images exist, `ctx.xmit.want` is set; otherwise, or when `Xmit::build` fails, the shader mode `fa_tr_a.w` stays 2 (plain blend,
`transmissionPlain`). With `want`, the main pass is two passes over the same attachments: the opaque phase (sky, opaque meshes, ambient occlusion, fog), `end_pass`, `Xmit::build`, and a
continuation pass that LOADs colour, depth and stencil (`PassDesc.depthStore` / `stencilStore` keep the first pass's depth and stencil alive) and draws the
blended phase. A frame with no visible transmissive draw takes the old single pass, so it is bit-identical to a frame without the feature.

**The atlas.** `xmit_layout(w, h)` is pure arithmetic: level 0 at (0, 0), level 1 at (w, 0), levels 2.. stacked under level 1, at most `kXmitMaxLevels` (5), fewer for a
small picture. The picture is copied (resolving MSAA) into level 0's image, each level is a 4x4 smooth reduction of the one before, and one draw writes every level
into the atlas, in the colour format of the picture (so HDR values refract unclamped). Images come from `TransientTargets` and go back after the blended
draws (`Xmit::finish`).

**The read.** `fa_transmission` takes the surface point, moves it along `refract(-v, n, 1 / ior) * thickness` (only with thickness above 0), projects it back to the
screen, and reads the atlas with `texelFetch`: one bilinear tap in each of the two levels around `roughness * clamp(2 * ior - 2, 0, 1) * (levels - 1)`, blended by
hand (view 28 is unfilterable, there is no free texture unit). The Beer-Lambert attenuation `exp(-(-ln(attenuationColor) / attenuationDistance) * thickness)` tints
the result, and the specular reflection takes its share first: the transmitted part is `(1 - F) * transmission * (1 - metallic)`.

**One source of truth for the cost.** `material_cost_report` (`material_cost.cpp`) calls the same predicates as the renderer (`mesh_is_transmissive`,
`mesh_is_blended`, `xmit_layout`, `subsurface_of`), `Renderer::material_cost` loads the entity's mesh and material and adds the camera's size, and the command
`render.material_cost` and the editor's inspector show its JSON. The editor never computes a cost; its autotest compares what it shows with a fresh command call.
