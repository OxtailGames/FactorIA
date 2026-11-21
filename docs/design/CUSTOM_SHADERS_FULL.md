# Design: full shaders for mesh materials (M72.3, first half)

Status: **built** (M72, package P10). Continues [CUSTOM_SHADERS.md](CUSTOM_SHADERS.md), whose decision D1 chose the surface
snippet and left a full-GLSL escape hatch "if `ENGINE_FEEDBACK.json` asks for it". The author-facing page is
[docs/shaders/SHADERS_FULL.md](../shaders/SHADERS_FULL.md); this one records how it is built and why, for engine developers.

## What it is

A mesh material with `"mode": "full"` names a file that holds the vertex stage and the fragment stage, each with its own
`main`, and up to four **passes**, each with its own cull, depth and blend state. The material system around it is the one of
snippet materials: the same file format, params, textures, instanced params, `vertexAttributes`, inspector, hot reload,
twins, export, `shader.compile`, `material.info`, `factoria validate`. Only what is generated and what the renderer does with
the programs differ.

It is **not** a new `MaterialKind`. The kind stays `"mesh"` (the same `MeshRenderer.material` field, the same draw lists), so a
twin has no `kind` key and a twin made before M72 still loads. The full mode is a second *template* of the mesh kind.

## Decisions

| # | Question | Decision | Why |
|---|---|---|---|
| F1 | Kind or mode | A **mode** of `mesh`, not a kind. Twins add `"full": true`. | It shares the component, the draw lists, the editor and the batching; a kind would copy them. |
| F2 | What the author writes | One file with `@common`, `@vertex`, `@fragment`; each stage defines `void main()`. The engine renames it (`#define main fa_user_main`) and calls it from its own `main`, after the model matrix (instancing, skinning), the instanced params and the declared channels are set up. | The hard parts of the mesh shader (instance matrix, joint palette, extra attributes) stay the engine's even in a full shader, so an engine change does not break a game. The author gets **globals**, not a contract to re-implement. |
| F3 | Varyings | A `varying` keyword in the file, `out` in the vertex stage and `in` in the fragment stage (`#define varying out/in`). Both stages must declare the same list; the tooling checks it before the compiler. | sokol-shdc links the stages by order and name; a mismatch otherwise gives a driver or compiler error far from the cause. The limit is 12 vec4 slots (`kMaterialMaxVaryings`): GLES3 and WebGL2 guarantee only 15 varying vectors and the engine's three flat instance varyings take the other three, so 12 + 3 fits exactly (desktop GL and D3D11 give more, the limit is the same everywhere). |
| F4 | Passes and queue | Up to 4 passes, **drawn in array order for every part**, each with its own pipeline (cull, depth test, depth write, blend). No per-pass queue key. | A queue key per pass (an outline after the whole opaque queue, a glow after the transparent one) needs a draw list per key and a second sort. Array order covers the effects asked for (outline, x-ray, shell, decal) and keeps one draw record per part. |
| F5 | Opaque or blended | A material is **blended** (drawn in the far-to-near list with the other blended meshes) if **any** of its passes blends; all its passes draw there, in array order. | One draw list per material keeps the order of its own passes; splitting them would let another transparent mesh draw between two passes of one mesh. The renderer sets `alphaMode "blend"` for it. |
| F6 | Lights and shadows | The engine's light selection and the directional shadow map stay engine-owned. The template exposes them as helpers (`fa_light_count()`, `fa_light(i, ...)` returning the same `LightSample` as `light()`, `fa_shadow(...)`, `fa_apply_fog(...)`). | The author writes the loop and the shading; the engine still chooses which lights reach the mesh and keeps the shadow map, so the light budget, culling and the shadow cascade are not part of the contract. The same light functions and the sky light also exist for the snippet's `lighting()` (SHADERS_LIGHTING.md), and a full shader has `fa_environment`, `fa_env_brdf` and `fa_sky_reflection` (the block `fa_env_funcs` of `mesh_common.glsl`, included). Other names the included files define (`fa_light_sample`, `fa_light_sample_n`, `fa_shadow_pcf`, the `FA_SHADOW_*` macros, the cluster lookups) are internal: they are visible to the shader but not part of the contract and may change. |
| F7 | Shadow caster | `"shadow"`: `"depth"` (default: the engine's depth-only program, the mesh as the `MeshRenderer` has it), `"custom"` (pass 0 compiled again with `FA_SHADOW_PASS`; `fa_view_proj` is the light's matrix there), `"none"`. | Most full shaders do not change the silhouette, so the default costs nothing; `"custom"` lets a displacing or cutting shader cast its real shadow, and a hologram casts none. |
| F8 | SSAO and the prepass | `"prepass"` (default `true`): the engine's own `prepass`/`prepass_skin` programs draw the mesh, so the author's vertex stage is **not** seen; `false` keeps the material out of the depth and normal prepass, so SSAO, the depth fog and the other screen effects ignore it. | A custom prepass would need the author to write a third and fourth entry (depth and normal). The default sees the original mesh, which is right for shaders that shade or colour; the switch is for ones that must not occlude. A blended material is out of the prepass anyway (it holds opaque meshes only). |
| F9 | Skinning and instancing | Supported: every pass has a `_skin` program, and the instance matrix and the per-instance params are set up before the author's `main`. | A full shader that lost them would be unusable for characters and foliage. |
| F10 | Channels | Only `uv1` and `color1` (`vertexAttributes`) beyond the engine's layout, read as `vertex_uv1` and `vertex_color1`. A mesh without a declared channel is drawn with the error material (magenta) and logged once, as in P9. | The vertex layouts of the pipelines are fixed (16 attributes on GLES3/WebGL2: 9 or 11 of the mesh, 3 of the instance data, 2 channels). |
| F11 | Reserved names | The author may use only the `fa_`/`FA_` names the template documents (a list in `shaders_full.cpp`, checked against the template by `shader_template_test.cpp`); any other is an error with "did you mean". | The rest of the template is the engine's and may change; the rule is the one of snippets, with an allow-list. |

## The template

`engine/render/shaders/mesh_full_common.glsl` is included after `mesh_common.glsl` by the generated top file. It defines four
blocks: `fa_full_vs_head` (the attributes, `fa_model`, `fa_world_position`, `fa_world_direction`, `fa_shadow_coord`),
`fa_full_vs_tail` (the engine's `main`), `fa_full_fs_head` (the fragment resources, `fa_frag_color`, the light, shadow and fog
helpers) and `fa_full_fs_tail`. The fragment resources are **copies**, not includes, of the ones in `mesh_common.glsl`
(whose `fa_fs_surface` also declares the engine's own varyings), except the lights and the shadow lookup, which both templates
include from `light_data.glsl` and `shadow_common.glsl` (the full template keeps its own shadow texture names and the macros
`FA_SHADOW_TEX` / `FA_SHADOW_SMP` point the shared function at them); `shader_template_test.cpp` compares the uniform blocks so
the CPU structs that fill them cannot drift.

The material's blocks (`fa_material_vs` at vertex binding 4, `fa_material` at fragment binding 5) and the texture slots
(fragment views 6.. and samplers 2.., vertex views 10.. and samplers 6..) are the ones of snippet materials, so the
renderer's `material_inputs()` fills them with no special case. The compiler drops a uniform block a program does not read,
so the renderer applies a block only when the program's reflection declares it (the only difference from snippets, whose
programs all read theirs).

`mesh_common.glsl`'s own `fa_fs_surface` and `fa_vs` programs still compile (sokol-shdc compiles every block it includes);
they call `surface()`, so the generated file defines an empty one.

## The generator

`tools/common/src/shaders_full.cpp` splits the file at its section lines (in the comment-free text), checks it
(`precheck_full`: both sections, a `main` in each, `gl_Position` and `fa_frag_color` written, varyings, reserved names) and
builds the top file (`generate_full_shader`). The author's lines go in verbatim and `GeneratedShader::snippetLine` maps each
generated line back to its line in the file, so a compiler error reports `shaders/x.full.glsl:LINE` in whichever stage and
pass it was found, once.

Programs, named in the twin and in `GeneratedShader::programs` (`full_program_name`):

| Program | Content |
|---|---|
| `mesh`, `mesh_skin` | Pass 0, with `FA_PASS 0` and `FA_PASS_<NAME>`; `_skin` adds `FA_SKIN` (and the joint attributes). |
| `pass1`, `pass1_skin`, ... | Pass `i`, with its own macros. |
| `shadow`, `shadow_skin` | `"shadow": "custom"` only: pass 0 again with `FA_SHADOW_PASS`. The fragment tail writes the depth whatever the author wrote. |
| `prepass`, `prepass_skin` | Unless `"prepass": false`: the engine's own `prepass_vs`/`prepass_fs`, linked as programs of the material so the renderer finds them under the usual names. |

At most four passes: at most 12 programs (`kMaxMaterialPrograms` = `kProgCount` + 2 * 3). Pass `p >= 1` lives in slot
`kProgCount + 2 * (p - 1)` (+ 1 skinned) of `MaterialAsset::programs`; pass 0 uses the usual mesh slots.

The twin (`factoria.shader/1`) gets `full: true`, `shadow`, `prepass` and `passes: [{name, cull, depthTest, depthWrite, blend,
program, programSkin}]`. Its `"template"` is `mesh_full_template_hash()` (the hash of `mesh_common.glsl`, the shared light and shadow files plus
`mesh_full_common.glsl`, `FA_TEMPLATE_HASH_MESH_FULL` in `engine/render/CMakeLists.txt`), so a twin of another template
is refused with the usual message. The cache key of a compile includes `GeneratedShader::stateKey` (the passes as JSON): a pass's
cull is in no source line, but it must still miss the cache.

## The renderer

`build_material_checked` (`custom_shader.cpp`) reads the twin's passes and shadow mode into `MaterialAsset::passes` and
`shadow`/`prepass`, builds one `sg_shader` per program, and checks that a twin is a full one exactly when the material file
says so. `Gpu::full_pipeline` makes the pipeline of a pass, keyed by its state (cull, depth test, depth write, blend),
whether it is skinned, the vertex layout and the target format; the pipeline cache is the existing one.

`draw_meshes` draws every part once per pass, in array order, with that pass's pipeline; the batching is per material and
pass (a pass reuses the batch of its entities, so an instanced material is still one instanced draw per pass).
`MeshRenderer` batching, the extras of `vertexAttributes` and the per-instance params are the same code as for snippets.
`fa_time.yzw` of the vertex block carries the camera position for `FA_CAMERA`. The shadow pass skips a material with
`"shadow": "none"`, and uses the `shadow`/`shadow_skin` programs for `"custom"`; the prepass skips a material with `"prepass":
false`.

Pipelines are made the first time a frame draws them, not when the material loads (no warm-up). A pipeline is keyed by what
only a draw knows: the target format (a camera's HDR or LDR target, a render target, a cubemap face), whether the mesh is
skinned and the `vertexAttributes` extras of the mesh it meets. Building every combination at load would cost more than
the one or two a scene uses, and building only the likely one would still miss on the first frame of another camera. So the
first frame that draws a full material (or draws it into a new kind of target) is the one that pays for its pipelines, once;
the cache keeps them (it is keyed by the program, so a hot reload makes new ones). A game that cannot take that hitch draws the material once on a loading
screen.

A material that does not build, or whose mesh lacks a declared channel, is drawn with the error material and
`stats.materialFallbacks` lists it, as for snippets. Hot reload is the existing path: the editor or `factoria run` sees the
file change, the tooling recompiles it, and the renderer swaps all the programs of the material at once; a failed rebuild
keeps the last good one.

## Tests

- `tools/common/tests/shaders_test.cpp`, "full material": the file and every error with its JSON pointer and "did you mean",
  the checks without a compiler (each at its line), the generated top file and twin fields, `material.info`, and with the
  real sokol-shdc the compile to every dialect and the line mapping of an error in each stage.
- `shaders_fixtures_test.cpp`: the committed twins of `full_flat`, `full_outline`, `full_lights`, `full_chan`, `full_inst`,
  `full_alt` and `full_xray` (`FA_UPDATE_FIXTURES=1` rewrites them).
- `engine/render/tests/render3d_tests.cpp`, "full shaders: ...": headless readback of an unlit colour, a two-pass outline,
  per-pass cull and depth state, an own light loop over two lights, a missing channel falling back, instanced params and a
  texture in both stages with a custom shadow, a skinned glTF, and hot reload.
- `shaders_docs_test.cpp` compiles every example of SHADERS.md and shaders/SHADERS_FULL.md.

## Not done

- A draw-queue key per pass (a pass that draws after all the transparent meshes). Array order only.
- A custom prepass: the author's vertex stage is not seen by SSAO (it is by `"shadow": "custom"`).
- Choosing the lights or the shadow map from the shader; image-based lighting; the glTF's normal, metallic-roughness and
  occlusion textures (a full shader declares its own `textures`).
- Compute-like or tessellation stages, a vertex layout of the author's own, and full shaders for sprite, sky or post
  materials.
- Numbers on D3D11 (WARP) and llvmpipe: the render tests run on whichever backend the machine has (Metal on a Mac); CI
  measures the others.
